// @license
// Copyright (c) rljson
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

// Kubernetes cluster shared by every stage, with three node pools:
// - system: the add-ons, the gateway and the tools that serve all
//   namespaces
// - origin and custom: tainted side=<pool>:NoSchedule and labelled
//   side=<pool>, so only workloads that tolerate the taint and select the
//   label run there, each in the subnet of its pool
// Entra sign-in with Azure RBAC and no local accounts, OIDC issuer and
// workload identity, Azure CNI overlay with Cilium network policies, pull
// access to the registry, and the application routing add-on with the
// managed Gateway API. Needs the components container-registry and
// network deployed first.

@description('Azure region; defaults to the region of the resource group')
param location string = resourceGroup().location

@description('Who is technically responsible; set by deploy.js to the signed-in user')
param techResponsibility string

@description('Kubernetes version; empty takes the default of the region')
param kubernetesVersion string = ''

@description('Control plane tier: Free has no uptime SLA, Standard has one')
@allowed([
  'Free'
  'Standard'
])
param tier string = 'Free'

@description('VM size of the nodes of every pool')
param nodeSize string = 'Standard_D2s_v6'

@description('Number of nodes per pool')
param nodeCounts {
  system: int
  origin: int
  custom: int
}

@description('OS disk of a node in GB')
param osDiskSizeGB int = 64

@description('Address range of the pods; outside the VNet, Azure CNI overlay')
param podCidr string = '10.244.0.0/16'

@description('Address range of the Kubernetes services; outside the VNet')
param serviceCidr string = '10.0.0.0/16'

@description('Address of the cluster DNS, inside serviceCidr')
param dnsServiceIP string = '10.0.0.10'

@description('Object IDs of the Entra groups that get cluster admin rights; set by deploy.js')
param clusterAdminGroupIds array

var tags = {
  application: 'cars'
  environment: 'shared'
  techresponsibility: techResponsibility
}

// Built-in role definitions
var acrPullRoleId = '7f951dda-4ed3-4680-a7ca-43fe172d538d'
var networkContributorRoleId = '4d97b98b-1d4f-4787-a291-c67834d212e7'
var aksRbacClusterAdminRoleId = 'b1ff04bb-8a4e-4dc4-8eb5-8693973ce19b'

resource registry 'Microsoft.ContainerRegistry/registries@2023-07-01' existing = {
  name: 'crcars'
}

resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' existing = {
  name: 'vnet-cars'
}

// The identity of the control plane; it manages the load balancer and the
// public IP addresses in the subnets, so it needs rights on the VNet before
// the cluster is created
resource controlPlane 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'id-aks-cars'
  location: location
  tags: tags
}

resource networkContributor 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(vnet.id, controlPlane.id, networkContributorRoleId)
  scope: vnet
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', networkContributorRoleId)
    principalId: controlPlane.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

var commonPool = {
  vmSize: nodeSize
  osType: 'Linux'
  osDiskType: 'Managed'
  osDiskSizeGB: osDiskSizeGB
  tags: tags
}

resource cluster 'Microsoft.ContainerService/managedClusters@2026-04-01' = {
  name: 'aks-cars'
  location: location
  tags: tags
  dependsOn: [networkContributor]
  sku: {
    name: 'Base'
    tier: tier
  }
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${controlPlane.id}': {}
    }
  }
  properties: {
    kubernetesVersion: empty(kubernetesVersion) ? null : kubernetesVersion
    dnsPrefix: 'aks-cars'
    nodeResourceGroup: 'rg-cars-aks'
    disableLocalAccounts: true
    aadProfile: {
      managed: true
      enableAzureRBAC: true
    }
    oidcIssuerProfile: {
      enabled: true
    }
    securityProfile: {
      workloadIdentity: {
        enabled: true
      }
    }
    autoUpgradeProfile: {
      upgradeChannel: 'patch'
      nodeOSUpgradeChannel: 'NodeImage'
    }
    networkProfile: {
      networkPlugin: 'azure'
      networkPluginMode: 'overlay'
      networkDataplane: 'cilium'
      networkPolicy: 'cilium'
      podCidr: podCidr
      serviceCidr: serviceCidr
      dnsServiceIP: dnsServiceIP
      loadBalancerSku: 'standard'
    }
    ingressProfile: {
      gatewayAPI: {
        installation: 'Standard'
      }
      webAppRouting: {
        enabled: true
        gatewayAPIImplementations: {
          appRoutingIstio: {
            mode: 'Enabled'
          }
        }
        nginx: {
          defaultIngressControllerType: 'None'
        }
      }
    }
    agentPoolProfiles: [
      union(commonPool, {
        name: 'system'
        mode: 'System'
        count: nodeCounts.system
        vnetSubnetID: '${vnet.id}/subnets/snet-cars-system'
        nodeLabels: { pool: 'system' }
      })
      union(commonPool, {
        name: 'origin'
        mode: 'User'
        count: nodeCounts.origin
        vnetSubnetID: '${vnet.id}/subnets/snet-cars-origin'
        nodeLabels: { side: 'origin' }
        nodeTaints: ['side=origin:NoSchedule']
      })
      union(commonPool, {
        name: 'custom'
        mode: 'User'
        count: nodeCounts.custom
        vnetSubnetID: '${vnet.id}/subnets/snet-cars-custom'
        nodeLabels: { side: 'custom' }
        nodeTaints: ['side=custom:NoSchedule']
      })
    ]
  }
}

// The nodes pull images from the registry without a secret
resource acrPull 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(registry.id, cluster.id, acrPullRoleId)
  scope: registry
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', acrPullRoleId)
    principalId: cluster.properties.identityProfile.kubeletidentity.objectId
    principalType: 'ServicePrincipal'
  }
}

// The admin groups manage everything inside the cluster
resource clusterAdmins 'Microsoft.Authorization/roleAssignments@2022-04-01' = [
  for groupId in clusterAdminGroupIds: {
    name: guid(cluster.id, groupId, aksRbacClusterAdminRoleId)
    scope: cluster
    properties: {
      roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', aksRbacClusterAdminRoleId)
      principalId: groupId
      principalType: 'Group'
    }
  }
]

output clusterName string = cluster.name
output oidcIssuerUrl string = cluster.properties.oidcIssuerProfile.issuerURL

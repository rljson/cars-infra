// @license
// Copyright (c) rljson
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

// Kubernetes cluster of one environment: one system node, Entra sign-in
// with Azure RBAC, workload identity, and pull access to the registry.

@description('Environment the cluster belongs to, e.g. demo')
param environment string

@description('Azure region; defaults to the region of the resource group')
param location string = resourceGroup().location

@description('Who is technically responsible; set by deploy.sh to the signed-in user')
param techResponsibility string

@description('VM size of the system node')
param nodeSize string = 'Standard_D2s_v6'

@description('Number of nodes in the system pool')
@minValue(1)
param nodeCount int = 1

@description('OS disk of a node in GB')
param osDiskSizeGB int = 64

@description('Control plane tier: Free has no uptime SLA, Standard has one')
@allowed([
  'Free'
  'Standard'
])
param tier string = 'Free'

@description('Object IDs of the Entra groups that get cluster admin rights; set by deploy.sh')
param clusterAdminGroupIds array

var tags = {
  application: 'cars'
  environment: environment
  techresponsibility: techResponsibility
}

// Built-in role definitions
var acrPullRoleId = '7f951dda-4ed3-4680-a7ca-43fe172d538d'
var aksRbacClusterAdminRoleId = 'b1ff04bb-8a4e-4dc4-8eb5-8693973ce19b'

resource registry 'Microsoft.ContainerRegistry/registries@2023-07-01' existing = {
  name: 'crcars${environment}'
}

resource cluster 'Microsoft.ContainerService/managedClusters@2024-09-01' = {
  name: 'aks-cars-${environment}'
  location: location
  tags: tags
  sku: {
    name: 'Base'
    tier: tier
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    dnsPrefix: 'aks-cars-${environment}'
    nodeResourceGroup: 'rg-cars-${environment}-aks'
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
    }
    addonProfiles: {
      azureKeyvaultSecretsProvider: {
        enabled: true
      }
    }
    agentPoolProfiles: [
      {
        name: 'system'
        mode: 'System'
        count: nodeCount
        vmSize: nodeSize
        osType: 'Linux'
        osDiskType: 'Managed'
        osDiskSizeGB: osDiskSizeGB
        tags: tags
      }
    ]
  }
}

// The nodes pull images from the registry
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

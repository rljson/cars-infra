// @license
// Copyright (c) rljson
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

// Network of the cluster: a VNet with one subnet per node pool, system,
// origin and custom, each guarded by its own network security group.
// Azure CNI overlay gives the pods addresses outside the VNet, so the
// subnets hold the nodes only. Nodes of all pools must reach each other,
// so the groups allow the traffic inside the VNet; the separation of the
// sides inside the cluster is done by network policies.

@description('Azure region; defaults to the region of the resource group')
param location string = resourceGroup().location

@description('Who is technically responsible; set by deploy.js to the signed-in user')
param techResponsibility string

@description('Address space of the VNet, e.g. 10.10.0.0/16')
param addressPrefix string

@description('Address ranges of the node subnets, by pool')
param subnetPrefixes {
  system: string
  origin: string
  custom: string
}

var tags = {
  application: 'cars'
  environment: 'shared'
  techresponsibility: techResponsibility
}

var pools = [
  'system'
  'origin'
  'custom'
]

// The load balancer of the gateway sends web traffic from the internet
// to the nodes; the default rules allow the VNet and the load balancer
var allowWebInbound = {
  name: 'AllowWebInbound'
  properties: {
    priority: 100
    direction: 'Inbound'
    access: 'Allow'
    protocol: 'Tcp'
    sourceAddressPrefix: 'Internet'
    sourcePortRange: '*'
    destinationAddressPrefix: '*'
    destinationPortRanges: ['80', '443']
  }
}

resource nsgs 'Microsoft.Network/networkSecurityGroups@2024-05-01' = [
  for pool in pools: {
    name: 'nsg-cars-${pool}'
    location: location
    tags: union(tags, { pool: pool })
    properties: {
      securityRules: [allowWebInbound]
    }
  }
]

resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: 'vnet-cars'
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [addressPrefix]
    }
    subnets: [
      for (pool, i) in pools: {
        name: 'snet-cars-${pool}'
        properties: {
          addressPrefix: subnetPrefixes[pool]
          networkSecurityGroup: { id: nsgs[i].id }
        }
      }
    ]
  }
}

output vnetName string = vnet.name
output subnetIds object = {
  system: vnet.properties.subnets[0].id
  origin: vnet.properties.subnets[1].id
  custom: vnet.properties.subnets[2].id
}

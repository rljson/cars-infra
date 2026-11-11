// @license
// Copyright (c) rljson
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

// Network of one stage: a VNet with one subnet per side, origin and custom,
// each delegated to a Container Apps environment and guarded by its own
// network security group. Traffic between the two subnets is denied, except
// HTTPS from custom to origin.

@description('Stage the network belongs to: dev, stage or prod')
param stage string

@description('Azure region; defaults to the region of the resource group')
param location string = resourceGroup().location

@description('Who is technically responsible; set by deploy.js to the signed-in user')
param techResponsibility string

@description('Address space of the VNet, e.g. 10.10.0.0/16')
param addressPrefix string

@description('Address range of the origin subnet; at least /27, /23 recommended')
param originPrefix string

@description('Address range of the custom subnet; at least /27, /23 recommended')
param customPrefix string

var tags = {
  application: 'cars'
  environment: stage
  techresponsibility: techResponsibility
}

// Container Apps answers on 80 and 443 from the internet
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

resource nsgOrigin 'Microsoft.Network/networkSecurityGroups@2024-05-01' = {
  name: 'nsg-cars-origin-${stage}'
  location: location
  tags: tags
  properties: {
    securityRules: [
      allowWebInbound
      {
        name: 'AllowHttpsFromCustom'
        properties: {
          priority: 110
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: customPrefix
          sourcePortRange: '*'
          destinationAddressPrefix: originPrefix
          destinationPortRange: '443'
        }
      }
      {
        name: 'DenyFromCustom'
        properties: {
          priority: 200
          direction: 'Inbound'
          access: 'Deny'
          protocol: '*'
          sourceAddressPrefix: customPrefix
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '*'
        }
      }
      {
        name: 'DenyToCustom'
        properties: {
          priority: 200
          direction: 'Outbound'
          access: 'Deny'
          protocol: '*'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: customPrefix
          destinationPortRange: '*'
        }
      }
    ]
  }
}

resource nsgCustom 'Microsoft.Network/networkSecurityGroups@2024-05-01' = {
  name: 'nsg-cars-custom-${stage}'
  location: location
  tags: tags
  properties: {
    securityRules: [
      allowWebInbound
      {
        name: 'DenyFromOrigin'
        properties: {
          priority: 200
          direction: 'Inbound'
          access: 'Deny'
          protocol: '*'
          sourceAddressPrefix: originPrefix
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '*'
        }
      }
      {
        name: 'AllowHttpsToOrigin'
        properties: {
          priority: 100
          direction: 'Outbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: customPrefix
          sourcePortRange: '*'
          destinationAddressPrefix: originPrefix
          destinationPortRange: '443'
        }
      }
      {
        name: 'DenyToOrigin'
        properties: {
          priority: 200
          direction: 'Outbound'
          access: 'Deny'
          protocol: '*'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: originPrefix
          destinationPortRange: '*'
        }
      }
    ]
  }
}

var delegation = [
  {
    name: 'containerApps'
    properties: {
      serviceName: 'Microsoft.App/environments'
    }
  }
]

resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: 'vnet-cars-${stage}'
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [addressPrefix]
    }
    subnets: [
      {
        name: 'snet-cars-origin-${stage}'
        properties: {
          addressPrefix: originPrefix
          networkSecurityGroup: { id: nsgOrigin.id }
          delegations: delegation
        }
      }
      {
        name: 'snet-cars-custom-${stage}'
        properties: {
          addressPrefix: customPrefix
          networkSecurityGroup: { id: nsgCustom.id }
          delegations: delegation
        }
      }
    ]
  }
}

output vnetName string = vnet.name
output originSubnetId string = vnet.properties.subnets[0].id
output customSubnetId string = vnet.properties.subnets[1].id

// @license
// Copyright (c) rljson
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

// Container Apps environments of one stage: one per side, origin and custom,
// each in the subnet of its side and sending its logs to the Log Analytics
// workspace of the stage. Needs the components log-analytics and network
// deployed first.

@description('Stage the environments belong to: dev, stage or prod')
param stage string

@description('Azure region; defaults to the region of the resource group')
param location string = resourceGroup().location

@description('Who is technically responsible; set by deploy.js to the signed-in user')
param techResponsibility string

@description('The sides; each gets an environment in the subnet of its name')
param sides array = [
  'origin'
  'custom'
]

var tags = {
  application: 'cars'
  environment: stage
  techresponsibility: techResponsibility
}

resource workspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' existing = {
  name: 'log-cars-${stage}'
}

resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' existing = {
  name: 'vnet-cars-${stage}'
}

resource environments 'Microsoft.App/managedEnvironments@2024-03-01' = [
  for side in sides: {
    name: 'cae-cars-${side}-${stage}'
    location: location
    tags: union(tags, { side: side })
    properties: {
      workloadProfiles: [
        {
          name: 'Consumption'
          workloadProfileType: 'Consumption'
        }
      ]
      vnetConfiguration: {
        infrastructureSubnetId: '${vnet.id}/subnets/snet-cars-${side}-${stage}'
        internal: false
      }
      appLogsConfiguration: {
        destination: 'log-analytics'
        logAnalyticsConfiguration: {
          customerId: workspace.properties.customerId
          sharedKey: workspace.listKeys().primarySharedKey
        }
      }
      zoneRedundant: false
    }
  }
]

output environmentNames array = [for (side, i) in sides: environments[i].name]
output defaultDomains array = [for (side, i) in sides: environments[i].properties.defaultDomain]

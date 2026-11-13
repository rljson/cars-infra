// @license
// Copyright (c) rljson
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

// Stops the Kubernetes cluster every evening, so it does not run overnight.
// A Logic App calls the stop action of the cluster with its own managed
// identity, which may manage this one cluster and nothing else. Start the
// cluster by hand with `az aks start`. Needs the component aks deployed
// first.

@description('Azure region; defaults to the region of the resource group')
param location string = resourceGroup().location

@description('Who is technically responsible; set by deploy.js to the signed-in user')
param techResponsibility string

@description('Name of the cluster to stop')
param clusterName string = 'aks-cars'

@description('Hour of the daily stop, 0-23, in timeZone')
@minValue(0)
@maxValue(23)
param stopHour int = 20

@description('Windows time zone ID of stopHour')
param timeZone string = 'W. Europe Standard Time'

var tags = {
  application: 'cars'
  environment: 'shared'
  techresponsibility: techResponsibility
}

// Built-in role: Azure Kubernetes Service Contributor Role
var aksContributorRoleId = 'ed7f3fbd-7b88-4dd4-9017-9adb7ce333f8'

resource cluster 'Microsoft.ContainerService/managedClusters@2026-04-01' existing = {
  name: clusterName
}

resource stopCluster 'Microsoft.Logic/workflows@2019-05-01' = {
  name: 'logic-${clusterName}-stop'
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    state: 'Enabled'
    definition: {
      '$schema': 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
      contentVersion: '1.0.0.0'
      triggers: {
        daily: {
          type: 'Recurrence'
          recurrence: {
            frequency: 'Day'
            interval: 1
            timeZone: timeZone
            schedule: {
              hours: [
                stopHour
              ]
              minutes: [
                0
              ]
            }
          }
        }
      }
      actions: {
        stop: {
          type: 'Http'
          inputs: {
            method: 'POST'
            uri: '${az.environment().resourceManager}${substring(cluster.id, 1)}/stop?api-version=2026-04-01'
            authentication: {
              type: 'ManagedServiceIdentity'
              audience: az.environment().resourceManager
            }
          }
        }
      }
    }
  }
}

// The workflow may manage this cluster, and nothing else
resource stopRight 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(cluster.id, stopCluster.id, aksContributorRoleId)
  scope: cluster
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', aksContributorRoleId)
    principalId: stopCluster.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

output workflowName string = stopCluster.name

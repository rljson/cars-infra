// @license
// Copyright (c) rljson
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

// Stops the Kubernetes cluster of one environment every evening, so an
// idle cluster does not run overnight. Start it by hand with
// `az aks start`.

@description('Environment the schedule belongs to, e.g. demo')
param environment string

@description('Azure region; defaults to the region of the resource group')
param location string = resourceGroup().location

@description('Who is technically responsible; set by deploy.sh to the signed-in user')
param techResponsibility string

@description('Hour of the daily stop, 0-23, in timeZone')
@minValue(0)
@maxValue(23)
param stopHour int = 20

@description('Windows time zone ID of stopHour')
param timeZone string = 'W. Europe Standard Time'

var tags = {
  application: 'cars'
  environment: environment
  techresponsibility: techResponsibility
}

// Built-in role definition: Contributor, limited to the cluster below
var contributorRoleId = 'b24988ac-6180-42a0-ab88-20f7382dd24c'

resource cluster 'Microsoft.ContainerService/managedClusters@2024-09-01' existing = {
  name: 'aks-cars-${environment}'
}

resource stopCluster 'Microsoft.Logic/workflows@2019-05-01' = {
  name: 'logic-cars-${environment}-aks-stop'
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
            uri: '${az.environment().resourceManager}${substring(cluster.id, 1)}/stop?api-version=2024-09-01'
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

// The workflow may stop the cluster, and nothing else
resource stopRight 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(cluster.id, stopCluster.id, contributorRoleId)
  scope: cluster
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', contributorRoleId)
    principalId: stopCluster.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

output workflowName string = stopCluster.name

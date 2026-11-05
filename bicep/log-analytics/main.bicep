// @license
// Copyright (c) rljson
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

// Log Analytics workspace of one environment: the place where logs and
// metrics of the cars resources are collected.

@description('Environment the workspace belongs to, e.g. demo')
param environment string

@description('Azure region; defaults to the region of the resource group')
param location string = resourceGroup().location

@description('Who is technically responsible; set by deploy.sh to the signed-in user')
param techResponsibility string

@description('Days the logs are kept')
@minValue(30)
@maxValue(730)
param retentionInDays int = 30

@description('Daily ingestion cap in GB; ingestion stops for the day once reached')
param dailyQuotaGb string = '0.5'

var tags = {
  application: 'cars'
  environment: environment
  techresponsibility: techResponsibility
}

resource workspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: 'log-cars-${environment}'
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: retentionInDays
    workspaceCapping: {
      dailyQuotaGb: json(dailyQuotaGb)
    }
  }
}

output workspaceId string = workspace.id
output workspaceName string = workspace.name

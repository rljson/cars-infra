// @license
// Copyright (c) rljson
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

// Container registry of one environment: holds the images the container apps run.
// Images are built inside the registry with `az acr build`.

@description('Environment the registry belongs to, e.g. demo')
param environment string

@description('Azure region; defaults to the region of the resource group')
param location string = resourceGroup().location

@description('Who is technically responsible; set by deploy.sh to the signed-in user')
param techResponsibility string

@description('Registry tier')
@allowed([
  'Basic'
  'Standard'
  'Premium'
])
param sku string = 'Basic'

var tags = {
  application: 'cars'
  environment: environment
  techresponsibility: techResponsibility
}

// Registry names allow letters and digits only, so no dashes
resource registry 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: 'crcars${environment}'
  location: location
  tags: tags
  sku: {
    name: sku
  }
  properties: {
    adminUserEnabled: false
    publicNetworkAccess: 'Enabled'
  }
}

output registryName string = registry.name
output loginServer string = registry.properties.loginServer

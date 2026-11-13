// @license
// Copyright (c) rljson
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

// Public DNS zone of the host names, e.g. cars.example.com. The parent
// domain delegates the zone to Azure with NS records that name the
// servers in the output nameServers; the records inside the zone are
// added once the gateway of the cluster has its public IP address.

@description('Name of the zone, a subdomain of a domain the team owns')
param zoneName string

@description('Who is technically responsible; set by deploy.js to the signed-in user')
param techResponsibility string

var tags = {
  application: 'cars'
  environment: 'shared'
  techresponsibility: techResponsibility
}

// DNS zones are global, so they have no region
resource zone 'Microsoft.Network/dnsZones@2018-05-01' = {
  name: zoneName
  location: 'global'
  tags: tags
  properties: {
    zoneType: 'Public'
  }
}

output zoneName string = zone.name
output nameServers array = zone.properties.nameServers

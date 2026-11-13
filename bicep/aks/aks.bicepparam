// @license
// Copyright (c) rljson
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

using 'main.bicep'

param tier = 'Free'
param nodeSize = 'Standard_D2s_v6'
param nodeCounts = {
  system: 1
  origin: 1
  custom: 1
}

// deploy.js overrides these with the signed-in user and the object IDs
// of the groups cars-admins and cars-operators
param techResponsibility = ''
param clusterAdminGroupIds = []

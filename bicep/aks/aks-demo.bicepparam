// @license
// Copyright (c) rljson
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

using 'main.bicep'

param environment = 'demo'
param nodeSize = 'Standard_D2s_v6'
param nodeCount = 1
param osDiskSizeGB = 64
param tier = 'Free'

// deploy.sh overrides these: the signed-in user and the object IDs of the
// groups in CLUSTER_ADMIN_GROUPS
param techResponsibility = ''
param clusterAdminGroupIds = []

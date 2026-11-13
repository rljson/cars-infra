// @license
// Copyright (c) rljson
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

using 'main.bicep'

param clusterName = 'aks-cars'
param stopHour = 20
param timeZone = 'W. Europe Standard Time'

// deploy.js overrides this with the signed-in user
param techResponsibility = ''

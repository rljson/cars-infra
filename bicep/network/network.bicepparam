// @license
// Copyright (c) rljson
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

using 'main.bicep'

param addressPrefix = '10.10.0.0/16'
param subnetPrefixes = {
  system: '10.10.0.0/24'
  origin: '10.10.1.0/24'
  custom: '10.10.2.0/24'
}

// deploy.js overrides this with the signed-in user
param techResponsibility = ''

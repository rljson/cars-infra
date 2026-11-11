// @license
// Copyright (c) rljson
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

using 'main.bicep'

param stage = 'stage'
param addressPrefix = '10.20.0.0/16'
param originPrefix = '10.20.0.0/23'
param customPrefix = '10.20.2.0/23'

// deploy.js overrides this with the signed-in user
param techResponsibility = ''

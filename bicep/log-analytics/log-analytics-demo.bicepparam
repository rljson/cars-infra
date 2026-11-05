// @license
// Copyright (c) rljson
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

using 'main.bicep'

param environment = 'demo'
param retentionInDays = 30
param dailyQuotaGb = '0.5'

// deploy.sh overrides this with the signed-in user
param techResponsibility = ''

// @license
// Copyright (c) rljson
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

using 'main.bicep'

// The domain is not chosen yet; deploying dns fails until this names it,
// e.g. 'cars.example.com'
param zoneName = ''

// deploy.js overrides this with the signed-in user
param techResponsibility = ''

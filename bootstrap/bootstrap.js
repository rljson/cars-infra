#!/usr/bin/env node
// @license
// Copyright (c) rljson
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

// Prepares a stage once: registers the resource providers the components
// need and creates the resource group of the stage.
//
// Usage: node bootstrap/bootstrap.js <stage>

import {
  azOutput,
  azShow,
  LOCATION,
  PROVIDERS,
  requireStage,
  requireSubscription,
  resourceGroup,
  run,
  signedInUser,
} from '../lib/common.js';

await run(() => {
  const stage = requireStage(process.argv[2]);
  requireSubscription();

  for (const provider of PROVIDERS) {
    const state = azOutput([
      'provider',
      'show',
      '--namespace',
      provider,
      '--query',
      'registrationState',
      '-o',
      'tsv',
    ]);
    if (state === 'Registered') continue;
    console.log(`⌛️ Registering ${provider}`);
    azShow(['provider', 'register', '--namespace', provider, '--wait']);
    console.log(`✅ Registered ${provider}`);
  }

  const group = resourceGroup(stage);
  if (azOutput(['group', 'exists', '--name', group]) === 'true') {
    console.log(`✅ ${group} exists already, nothing to do`);
    return;
  }

  azShow([
    'group',
    'create',
    '--name',
    group,
    '--location',
    LOCATION,
    '--tags',
    'application=cars',
    `environment=${stage}`,
    `techresponsibility=${signedInUser()}`,
    '--output',
    'table',
  ]);
  console.log(`✅ Created ${group} in ${LOCATION}`);
});

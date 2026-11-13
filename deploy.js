#!/usr/bin/env node
// @license
// Copyright (c) rljson
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

// Deploys Bicep components into the resource group rg-cars. Shows the
// what-if of each component first and applies it only after a yes.
//
// Usage: node deploy.js <component|all> [--what-if | --yes]
//   all        every component, in the order of COMPONENTS
//   --what-if  show the changes, apply nothing
//   --yes      apply after the what-if without asking

import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { chdir } from 'node:process';
import { fileURLToPath } from 'node:url';

import {
  azOutput,
  azShow,
  CLUSTER_ADMIN_GROUPS,
  confirm,
  declaresParam,
  Fail,
  groupIds,
  paramsFile,
  parseDeployArgs,
  RESOURCE_GROUP,
  requireFile,
  requireSubscription,
  run,
  signedInUser,
} from './lib/common.js';

chdir(dirname(fileURLToPath(import.meta.url)));

await run(async () => {
  const { components, mode } = parseDeployArgs(process.argv.slice(2));

  for (const component of components) {
    requireFile(join('bicep', component, 'main.bicep'));
    requireFile(paramsFile(component));
  }

  requireSubscription();
  if (azOutput(['group', 'exists', '--name', RESOURCE_GROUP]) !== 'true') {
    throw new Fail(`${RESOURCE_GROUP} is missing. Run: node bootstrap/bootstrap.js`);
  }

  const user = signedInUser();

  for (const component of components) {
    const args = [
      '--resource-group',
      RESOURCE_GROUP,
      '--parameters',
      paramsFile(component),
      '--parameters',
      `techResponsibility=${user}`,
    ];

    // Components that grant cluster rights get the group object IDs
    const bicep = readFileSync(join('bicep', component, 'main.bicep'), 'utf8');
    if (declaresParam(bicep, 'clusterAdminGroupIds')) {
      const ids = JSON.stringify(groupIds(CLUSTER_ADMIN_GROUPS));
      args.push('--parameters', `clusterAdminGroupIds=${ids}`);
    }

    console.log(`\n🔎 What-if of ${component}`);
    azShow(['deployment', 'group', 'what-if', ...args]);
    if (mode === 'what-if') continue;

    if (mode === 'ask' && !(await confirm(`Apply ${component}?`))) {
      throw new Fail(`Stopped before ${component}; nothing of it was applied`);
    }

    const name = `${component}-${new Date().toISOString().replace(/\D/g, '').slice(0, 14)}`;
    azShow(['deployment', 'group', 'create', '--name', name, ...args, '--output', 'none']);
    console.log(`✅ Deployed ${component}`);
  }
});

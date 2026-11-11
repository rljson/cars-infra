#!/usr/bin/env node
// @license
// Copyright (c) rljson
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

// Deploys Bicep components into the resource group of a stage. Shows the
// what-if of each component first and applies it only after a yes.
//
// Usage: node deploy.js <component|all> <stage> [--what-if | --yes]
//   all        every component, in the order of COMPONENTS
//   --what-if  show the changes, apply nothing
//   --yes      apply after the what-if without asking

import { chdir } from 'node:process';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

import {
  azOutput,
  azShow,
  confirm,
  Fail,
  paramsFile,
  parseDeployArgs,
  requireFile,
  requireSubscription,
  resourceGroup,
  run,
  signedInUser,
} from './lib/common.js';

chdir(dirname(fileURLToPath(import.meta.url)));

await run(async () => {
  const { components, stage, mode } = parseDeployArgs(process.argv.slice(2));

  for (const component of components) {
    requireFile(join('bicep', component, 'main.bicep'));
    requireFile(paramsFile(component, stage));
  }

  requireSubscription();
  const group = resourceGroup(stage);
  if (azOutput(['group', 'exists', '--name', group]) !== 'true') {
    throw new Fail(`${group} is missing. Run: node bootstrap/bootstrap.js ${stage}`);
  }

  const user = signedInUser();

  for (const component of components) {
    const args = [
      '--resource-group',
      group,
      '--parameters',
      paramsFile(component, stage),
      '--parameters',
      `techResponsibility=${user}`,
    ];

    console.log(`\n🔎 What-if of ${component} in ${stage}`);
    azShow(['deployment', 'group', 'what-if', ...args]);
    if (mode === 'what-if') continue;

    if (mode === 'ask' && !(await confirm(`Apply ${component} to ${stage}?`))) {
      throw new Fail(`Stopped before ${component}; nothing of it was applied`);
    }

    const name = `${component}-${new Date().toISOString().replace(/\D/g, '').slice(0, 14)}`;
    azShow(['deployment', 'group', 'create', '--name', name, ...args, '--output', 'none']);
    console.log(`✅ Deployed ${component} to ${stage}`);
  }
});

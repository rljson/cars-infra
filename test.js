#!/usr/bin/env node
// @license
// Copyright (c) rljson
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

// The test of cars-infra: runs the unit tests of lib and builds every Bicep
// and parameter file. Run it before each commit.
//
//   node test.js

import { spawnSync } from 'node:child_process';
import { dirname, join } from 'node:path';
import { chdir } from 'node:process';
import { fileURLToPath } from 'node:url';

import { bicepFiles, COMPONENTS, paramsFile } from './lib/common.js';

chdir(dirname(fileURLToPath(import.meta.url)));

let failed = 0;

const unit = spawnSync(process.execPath, ['--test', 'lib/'], {
  stdio: 'inherit',
});
if (unit.status !== 0) {
  console.log('❌ Unit tests of lib');
  failed++;
}

const files = bicepFiles('bicep');
for (const component of COMPONENTS) {
  for (const file of [join('bicep', component, 'main.bicep'), paramsFile(component)]) {
    if (!files.includes(file)) {
      console.log(`❌ Missing ${file}`);
      failed++;
    }
  }
}

for (const file of files) {
  const args = file.endsWith('.bicepparam')
    ? ['bicep', 'build-params', '--file', file, '--stdout']
    : ['bicep', 'build', '--file', file, '--stdout'];
  const { status } = spawnSync('az', args, { stdio: ['ignore', 'ignore', 'inherit'] });
  console.log(`${status === 0 ? '✅' : '❌'} ${file}`);
  if (status !== 0) failed++;
}

if (!files.length) {
  console.log('❌ No Bicep files found');
  process.exit(1);
}
if (failed) {
  console.log(`❌ ${failed} checks failed`);
  process.exit(1);
}
console.log(`✅ Unit tests pass, all ${files.length} Bicep files build`);

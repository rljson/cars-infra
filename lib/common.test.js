// @license
// Copyright (c) rljson
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import assert from 'node:assert/strict';
import { mkdirSync, mkdtempSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { describe, it } from 'node:test';

import {
  bicepFiles,
  COMPONENTS,
  Fail,
  paramsFile,
  parseDeployArgs,
  requireStage,
  resourceGroup,
} from './common.js';

describe('requireStage()', () => {
  it('accepts dev, stage and prod', () => {
    for (const s of ['dev', 'stage', 'prod']) assert.equal(requireStage(s), s);
  });

  it('rejects a missing or unknown stage', () => {
    assert.throws(() => requireStage(undefined), Fail);
    assert.throws(() => requireStage('demo'), /Unknown stage 'demo'/);
  });
});

describe('resourceGroup() and paramsFile()', () => {
  it('name the group and the parameter file of a stage', () => {
    assert.equal(resourceGroup('dev'), 'rg-cars-dev');
    assert.equal(
      paramsFile('network', 'prod'),
      join('bicep', 'network', 'network-prod.bicepparam'),
    );
  });
});

describe('parseDeployArgs()', () => {
  it('reads a component, a stage and the mode', () => {
    assert.deepEqual(parseDeployArgs(['network', 'dev']), {
      components: ['network'],
      stage: 'dev',
      mode: 'ask',
    });
    assert.equal(parseDeployArgs(['network', 'dev', '--what-if']).mode, 'what-if');
    assert.equal(parseDeployArgs(['network', 'dev', '--yes']).mode, 'yes');
  });

  it('expands all into every component, in order', () => {
    assert.deepEqual(parseDeployArgs(['all', 'stage']).components, COMPONENTS);
  });

  it('rejects wrong input', () => {
    assert.throws(() => parseDeployArgs([]), /Usage/);
    assert.throws(() => parseDeployArgs(['nope', 'dev']), /Unknown component/);
    assert.throws(() => parseDeployArgs(['network', 'demo']), /Unknown stage/);
    assert.throws(() => parseDeployArgs(['network', 'dev', '-x']), /Unknown option/);
    assert.throws(() => parseDeployArgs(['network', 'dev', '--yes', 'x']), /Usage/);
  });
});

describe('bicepFiles()', () => {
  it('lists Bicep and parameter files below a folder, sorted', () => {
    const dir = mkdtempSync(join(tmpdir(), 'bicep-'));
    mkdirSync(join(dir, 'b'));
    writeFileSync(join(dir, 'b', 'main.bicep'), '');
    writeFileSync(join(dir, 'b', 'b-dev.bicepparam'), '');
    writeFileSync(join(dir, 'README.md'), '');
    assert.deepEqual(bicepFiles(dir), [
      join(dir, 'b', 'b-dev.bicepparam'),
      join(dir, 'b', 'main.bicep'),
    ]);
  });
});

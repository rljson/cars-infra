// @license
// Copyright (c) rljson
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

// Shared settings and checks of the scripts in this repo.

import { execFileSync, spawnSync } from 'node:child_process';
import { existsSync, readdirSync } from 'node:fs';
import { join } from 'node:path';
import { createInterface } from 'node:readline/promises';

export const SUBSCRIPTION = 'cars';
export const LOCATION = 'germanywestcentral';

/** The one resource group that holds every component */
export const RESOURCE_GROUP = 'rg-cars';

/** The components, in the order `deploy.js all` deploys them */
export const COMPONENTS = [
  'log-analytics',
  'container-registry',
  'network',
  'dns',
  'aks',
  'aks-schedule',
];

/** The resource providers the components need */
export const PROVIDERS = [
  'Microsoft.ContainerRegistry',
  'Microsoft.ContainerService',
  'Microsoft.Logic',
  'Microsoft.ManagedIdentity',
  'Microsoft.Network',
  'Microsoft.OperationalInsights',
];

/** The Entra groups that get admin rights inside the cluster */
export const CLUSTER_ADMIN_GROUPS = ['cars-admins', 'cars-operators'];

/** An error whose message is shown to the operator without a stack */
export class Fail extends Error {}

/**
 * The parameter file of a component, relative to the repo root
 * @param {string} component
 * @returns {string}
 */
export function paramsFile(component) {
  return join('bicep', component, `${component}.bicepparam`);
}

/**
 * Reads the arguments of deploy.js
 * @param {string[]} argv - the arguments after the script name
 * @returns {{ components: string[], mode: 'ask' | 'what-if' | 'yes' }}
 */
export function parseDeployArgs(argv) {
  const usage = 'Usage: node deploy.js <component|all> [--what-if | --yes]';
  const [component, option, ...rest] = argv;
  if (!component || rest.length) throw new Fail(usage);

  const modes = { undefined: 'ask', '--what-if': 'what-if', '--yes': 'yes' };
  const mode = modes[String(option)];
  if (!mode) throw new Fail(`Unknown option '${option}'. ${usage}`);

  const components = component === 'all' ? COMPONENTS : [component];
  for (const c of components) {
    if (!COMPONENTS.includes(c)) {
      throw new Fail(
        `Unknown component '${c}'. Known: ${COMPONENTS.join(', ')}, all`,
      );
    }
  }
  return { components, mode };
}

/**
 * Whether a Bicep file declares a parameter
 * @param {string} bicep - the content of a main.bicep
 * @param {string} name
 * @returns {boolean}
 */
export function declaresParam(bicep, name) {
  return new RegExp(`^param ${name}\\b`, 'm').test(bicep);
}

/**
 * Lists every Bicep and parameter file below a folder, sorted
 * @param {string} dir
 * @returns {string[]}
 */
export function bicepFiles(dir) {
  const files = [];
  for (const entry of readdirSync(dir, { withFileTypes: true })) {
    const path = join(dir, entry.name);
    if (entry.isDirectory()) files.push(...bicepFiles(path));
    else if (/\.bicep(param)?$/.test(entry.name)) files.push(path);
  }
  return files.sort();
}

/**
 * Runs the Azure CLI and returns its trimmed output
 * @param {string[]} args
 * @returns {string}
 */
export function azOutput(args) {
  return execFileSync('az', args, { encoding: 'utf8' }).trim();
}

/**
 * Runs the Azure CLI with its output on the console
 * @param {string[]} args
 */
export function azShow(args) {
  const { status } = spawnSync('az', args, { stdio: 'inherit' });
  if (status !== 0) throw new Fail(`az ${args[0]} ${args[1]} failed`);
}

/** Throws unless the Azure CLI is signed in and points at SUBSCRIPTION */
export function requireSubscription() {
  let current;
  try {
    current = azOutput(['account', 'show', '--query', 'name', '-o', 'tsv']);
  } catch {
    throw new Fail('Not signed in. Run: az login');
  }
  if (current !== SUBSCRIPTION) {
    throw new Fail(
      `Active subscription is '${current}'. ` +
        `Run: az account set --subscription ${SUBSCRIPTION}`,
    );
  }
}

/**
 * The object IDs of Entra groups, looked up by name so no ID is kept in git
 * @param {string[]} names
 * @returns {string[]}
 */
export function groupIds(names) {
  return names.map((name) => {
    try {
      return azOutput(['ad', 'group', 'show', '--group', name, '--query', 'id', '-o', 'tsv']);
    } catch {
      throw new Fail(`Entra group '${name}' not found`);
    }
  });
}

/** The user principal name of the signed-in user */
export function signedInUser() {
  return azOutput([
    'ad',
    'signed-in-user',
    'show',
    '--query',
    'userPrincipalName',
    '-o',
    'tsv',
  ]);
}

/**
 * Asks a yes/no question on the console
 * @param {string} question
 * @returns {Promise<boolean>} true for y or yes
 */
export async function confirm(question) {
  const rl = createInterface({ input: process.stdin, output: process.stdout });
  try {
    const answer = await rl.question(`${question} [y/N] `);
    return /^y(es)?$/i.test(answer.trim());
  } finally {
    rl.close();
  }
}

/**
 * Runs a script body and prints a Fail as one line
 * @param {() => Promise<void> | void} body
 */
export async function run(body) {
  try {
    await body();
  } catch (e) {
    if (e instanceof Fail) {
      console.error(`❌ ${e.message}`);
      process.exit(1);
    }
    throw e;
  }
}

/**
 * Throws unless the file exists
 * @param {string} path
 */
export function requireFile(path) {
  if (!existsSync(path)) throw new Fail(`Missing ${path}`);
}

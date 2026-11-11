<!--
@license
Copyright (c) rljson

Use of this source code is governed by terms that can be
found in the LICENSE file in the root of this package.
-->

# cars-infra

English | [Deutsch](README.de.md)

The Azure resources of the cars application, an example app built on
Rljson: Node.js scripts to bootstrap, deploy and test, and one Bicep
component per resource.

## Motivation

- Every Azure resource of cars is described in git, so each stage can be
  rebuilt from this repo alone
- Each deploy shows a what-if first and applies only after a yes
- What runs on these resources lives in
  [cars-deployment](https://github.com/rljson/cars-deployment), so a
  change to an image never touches the Azure resources

## Layout

| Path                     | Content                                                                     |
| ------------------------ | --------------------------------------------------------------------------- |
| `bootstrap/bootstrap.js` | Run once per stage: registers the resource providers, creates the group     |
| `deploy.js`              | Deploys one component or all of them into a stage                           |
| `test.js`                | Runs the unit tests of `lib` and builds every Bicep and parameter file      |
| `lib`                    | Settings and checks shared by the scripts, with their tests                 |
| `bicep`                  | One folder per component: `main.bicep` and `<component>-<stage>.bicepparam` |

There are three stages, `dev`, `stage` and `prod`, each in its own
resource group `rg-cars-<stage>` in Germany West Central. They share
nothing.

## Usage

Install [Node.js](https://nodejs.org) 22 or later, the
[Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) and
its Bicep CLI once:

```bash
az bicep install
```

Sign in with your own Entra account first; the operator needs the group
`cars-admins` or `cars-operators`.

```bash
az login
az account set --subscription cars
```

Prepare a stage once:

```bash
node bootstrap/bootstrap.js dev
```

Deploy all components of a stage in order; each shows its what-if first
and nothing changes before your yes:

```bash
node deploy.js all dev
```

Deploy one component, or only show the changes:

```bash
node deploy.js network dev
node deploy.js network dev --what-if
```

`--yes` applies after the what-if without asking, for runs without a
terminal. The scripts check the stage and the active subscription first.
Every resource gets the tag `techresponsibility` with the signed-in user.

## Test

Before each commit:

```bash
node test.js
```

## Limitations

- No CI yet: operators deploy by hand from their machine; the GitHub
  Actions workflows will call the same scripts
- No databases, storage or identities yet

## Status

| Component            | Resources per stage                                                                  | dev | stage | prod |
| -------------------- | ------------------------------------------------------------------------------------ | --- | ----- | ---- |
| `log-analytics`      | `log-cars-<stage>`                                                                   | yes | no    | no   |
| `container-registry` | `crcars<stage>`                                                                      | yes | no    | no   |
| `network`            | `vnet-cars-<stage>`, `snet-cars-<side>-<stage>`, `nsg-cars-<side>-<stage>`            | yes | no    | no   |
| `environment`        | `cae-cars-origin-<stage>`, `cae-cars-custom-<stage>`                                 | blocked | no    | no   |

The environments of `dev` failed: the subscription allows only one
Container Apps environment in Germany West Central; a higher quota is
needed.

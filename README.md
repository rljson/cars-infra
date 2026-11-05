<!--
@license
Copyright (c) rljson

Use of this source code is governed by terms that can be
found in the LICENSE file in the root of this package.
-->

# cars-infra

English | [Deutsch](README.de.md)

The Azure resources of the cars application, an example app built on
Rljson: a bootstrap script, a deploy script and one Bicep component per
resource.

## Motivation

- Every Azure resource of cars is described in git, so the environment can
  be rebuilt from this repo alone
- Each deploy shows a what-if first and applies only after a yes
- What runs inside the cluster lives in
  [cars-deployment](https://github.com/rljson/cars-deployment), so a
  change to an image never touches the Azure resources

## Layout

| Folder      | Content                                                                   |
| ----------- | ------------------------------------------------------------------------- |
| `bootstrap` | Run once per environment: creates the resource group                      |
| `bicep`     | One folder per component: `main.bicep` and `<component>-<env>.bicepparam` |

The only environment is `demo`, in the resource group `rg-cars-demo` in
West Europe.

## Usage

Sign in with your own Entra account first; the operator needs the group
`cars-admins` or `cars-operators`.

```bash
az login
az account set --subscription cars
```

The bootstrap script and `deploy.sh <component> <env>` follow with the
first components.

## Limitations

- No CI: operators deploy by hand from their machine
- One environment only, `demo`

## Status

Structure only; no Azure resource is described yet.

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
- What runs on these resources lives in
  [cars-deployment](https://github.com/rljson/cars-deployment), so a
  change to an image never touches the Azure resources

## Layout

| Folder      | Content                                                                   |
| ----------- | ------------------------------------------------------------------------- |
| `bootstrap` | Run once per environment: creates the resource group                      |
| `lib`       | Settings and checks shared by the scripts                                 |
| `bicep`     | One folder per component: `main.bicep` and `<component>-<env>.bicepparam` |
| `test.sh`   | Builds every Bicep and parameter file                                     |

No environment is deployed: `demo` was deleted together with its cluster.
The stages `dev`, `stage` and `prod` follow, in Germany West Central.

## Usage

Install the [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli)
and its Bicep CLI once:

```bash
az bicep install
```

Sign in with your own Entra account first; the operator needs the group
`cars-admins` or `cars-operators`.

```bash
az login
az account set --subscription cars
```

Create the resource group of an environment once:

```bash
bootstrap/bootstrap.sh demo
```

Deploy a component; the what-if is shown first and nothing changes before
your yes:

```bash
./deploy.sh <component> demo
```

Only show the changes:

```bash
./deploy.sh <component> demo --what-if
```

Both scripts check the environment and the active subscription first.
Every resource gets the tag `techresponsibility` with the signed-in user.

## Test

Build every Bicep and parameter file before each commit:

```bash
./test.sh
```

## Limitations

- No CI: operators deploy by hand from their machine
- No environment deployed until the stages `dev`, `stage` and `prod` exist

## Status

| Component            | Resource         | Deployed |
| -------------------- | ---------------- | -------- |
| `log-analytics`      | `log-cars-<env>` | no       |
| `container-registry` | `crcars<env>`    | no       |

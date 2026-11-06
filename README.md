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
| `lib`       | Settings and checks shared by the scripts                                 |
| `bicep`     | One folder per component: `main.bicep` and `<component>-<env>.bicepparam` |
| `test.sh`   | Builds every Bicep and parameter file                                     |

The only environment is `demo`, in the resource group `rg-cars-demo` in
Germany West Central.

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

## The cluster

The cluster stops every evening at 20:00 Berlin time, so it does not run
idle overnight. Start it by hand before you work, and stop it when you are
done; the start takes about five minutes:

```bash
az aks start -g rg-cars-demo -n aks-cars-demo
az aks stop -g rg-cars-demo -n aks-cars-demo
```

Sign in with `kubectl` through Entra; the cluster has no local accounts.
Install `kubectl` and `kubelogin` once, e.g. with
`brew install kubectl Azure/kubelogin/kubelogin`:

```bash
az aks get-credentials -g rg-cars-demo -n aks-cars-demo
kubelogin convert-kubeconfig -l azurecli
kubectl get nodes
```

## Test

Build every Bicep and parameter file before each commit:

```bash
./test.sh
```

## Limitations

- No CI: operators deploy by hand from their machine
- One environment only, `demo`
- `aks` and `aks-schedule` assign roles beyond AcrPull, so only members of
  `cars-admins` can deploy them

## Status

| Component            | Resource                   | Deployed to demo |
| -------------------- | -------------------------- | ---------------- |
| `log-analytics`      | `log-cars-demo`            | yes              |
| `container-registry` | `crcarsdemo`               | yes              |
| `aks`                | `aks-cars-demo`            | yes              |
| `aks-schedule`       | `logic-cars-demo-aks-stop` | yes              |

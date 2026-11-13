# Changelog

## Unreleased

- Deploy every component once into one resource group `rg-cars` instead
  of one per stage: `bootstrap.js` and `deploy.js` take no stage, each
  component has one parameter file `<component>.bicepparam`, and the
  resources are named without a stage (`log-cars`, `crcars`, `vnet-cars`)
- Add the component `aks`: the cluster `aks-cars` with the node pools
  `system`, `origin` and `custom`, the latter two tainted per side; Entra
  sign-in, workload identity, Azure CNI overlay with Cilium, pull access
  to `crcars`, and the application routing add-on with the managed
  Gateway API; `deploy.js` grants `cars-admins` and `cars-operators`
  admin rights in the cluster
- Add the component `aks-schedule`: a Logic App `logic-aks-cars-stop`
  stops `aks-cars` every day at 20:00 with the Azure Kubernetes Service
  Contributor Role on this cluster only; `bootstrap.js` registers
  `Microsoft.Logic`
- Add the component `dns`: a public DNS zone whose name is set in its
  parameter file; it comes last in `deploy.js all`
- `network` gets a subnet and NSG per node pool, `snet-cars-system`,
  `-origin` and `-custom`, without the delegation to Container Apps
- Remove the component `environment` and the provider `Microsoft.App`
- Replace `bootstrap.sh`, `deploy.sh`, `test.sh` and `lib/common.sh` by
  the Node.js scripts `bootstrap.js`, `deploy.js`, `test.js` and
  `lib/common.js` with unit tests; `deploy.js all` deploys every component
  in order, `--yes` applies without asking
- Replace the environment `demo` by the stages `dev`, `stage` and `prod`;
  the Bicep parameter `environment` is now `stage`
- Add the components `network` (VNet, a subnet and NSG per side) and
  `environment` (a Container Apps environment per side)
- `bootstrap.js` registers the resource providers, among them
  `Microsoft.App`
- Remove the components `aks` and `aks-schedule` and the cluster admin
  groups of `deploy.sh`; the environment `demo` is deleted
- Add a package manifest, so gg handles the repo as part of a ticket
- Call the Bicep layout a component layout in `index.jsonc`

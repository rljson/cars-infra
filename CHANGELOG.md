# Changelog

## Unreleased

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

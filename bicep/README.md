<!--
@license
Copyright (c) rljson

Use of this source code is governed by terms that can be
found in the LICENSE file in the root of this package.
-->

# bicep

One folder per component, one parameter file each:

```text
bicep/<component>/main.bicep
bicep/<component>/<component>.bicepparam
```

Every component deploys into the resource group `rg-cars` and serves all
stages. Every `main.bicep` declares `param techResponsibility string` and
sets the tags `application: cars`, `environment: shared` and
`techresponsibility` on each resource; `deploy.js` passes the signed-in
user. Each `.bicepparam` assigns `techResponsibility` the placeholder `''`,
which `deploy.js` overrides. A component that declares
`param clusterAdminGroupIds array` gets the object IDs of the groups
`cars-admins` and `cars-operators`.

`node test.js` builds every file; it is the test of this repo and runs
before each commit. `node deploy.js <component|all>` deploys with a
what-if first; `all` deploys the components in the order of this table.

| Component            | Resources                                                                  | Settings                                                                                                                                                                                                                                                         |
| -------------------- | -------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `log-analytics`      | Log Analytics workspace `log-cars`                                         | 30 days retention, daily cap 1 GB                                                                                                                                                                                                                                |
| `container-registry` | Container registry `crcars`                                                | Basic, admin user off; images built with `az acr build`                                                                                                                                                                                                          |
| `network`            | VNet `vnet-cars`, subnets `snet-cars-<pool>`, NSGs `nsg-cars-<pool>`       | 10.10.0.0/16; a /24 per node pool: system `.0`, origin `.1`, custom `.2`; web on 80 and 443 from the internet allowed, the VNet open inside, since the nodes of all pools must reach each other                                                                    |
| `dns`                | Public DNS zone, e.g. `cars.example.com`                                   | The zone name is set in `dns.bicepparam`; outputs the name servers for the NS records of the parent domain                                                                                                                                                       |
| `aks`                | Cluster `aks-cars`, identity `id-aks-cars`, node group `rg-cars-aks`       | Free tier; pools `system`, `origin`, `custom`, one `Standard_D2s_v6` node each, in the subnet of their name, `origin` and `custom` tainted `side=<pool>:NoSchedule` and labelled `side=<pool>`; Entra sign-in with Azure RBAC, no local accounts; OIDC issuer and workload identity; Azure CNI overlay with Cilium, pods 10.244.0.0/16, services 10.0.0.0/16; AcrPull on `crcars` for the nodes; application routing add-on with the managed Gateway API and Istio, no NGINX; needs `container-registry` and `network` |

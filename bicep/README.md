<!--
@license
Copyright (c) rljson

Use of this source code is governed by terms that can be
found in the LICENSE file in the root of this package.
-->

# bicep

One folder per component:

```text
bicep/<component>/main.bicep
bicep/<component>/<component>-demo.bicepparam
```

Every `main.bicep` declares `param techResponsibility string` and sets it
as the tag `techresponsibility` on each resource; `deploy.sh` passes the
signed-in user. Each `.bicepparam` assigns it the placeholder `''`, which
`deploy.sh` overrides.

`./test.sh` builds every file; it is the test of this repo and runs before
each commit. `deploy.sh <component> <env>` deploys a component with a
what-if first.

| Component            | Resource                                                          | Settings in demo                                                                                                                                                                                           |
| -------------------- | ----------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `log-analytics`      | Log Analytics workspace `log-cars-<env>`                          | 30 days retention, 0.5 GB daily cap                                                                                                                                                                        |
| `container-registry` | Container registry `crcars<env>`                                  | Basic, admin user off; images built with `az acr build`                                                                                                                                                    |
| `aks`                | Kubernetes cluster `aks-cars-<env>`, nodes in `rg-cars-<env>-aks` | 1 × `Standard_D2s_v6`, Free tier, CNI overlay with Cilium, Entra and Azure RBAC, no local accounts, workload identity, Key Vault provider; AcrPull for the nodes, cluster admin for `CLUSTER_ADMIN_GROUPS` |
| `aks-schedule`       | Logic App `logic-cars-<env>-aks-stop`                             | Stops the cluster daily at 20:00 Berlin time; may only stop that cluster                                                                                                                                   |

`deploy.sh` passes `clusterAdminGroupIds` to each component that declares
it: the object IDs of the Entra groups in `CLUSTER_ADMIN_GROUPS` of
`lib/common.sh`, looked up by name, so no ID is kept in git.

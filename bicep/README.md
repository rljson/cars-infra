<!--
@license
Copyright (c) rljson

Use of this source code is governed by terms that can be
found in the LICENSE file in the root of this package.
-->

# bicep

One folder per component, one parameter file per stage:

```text
bicep/<component>/main.bicep
bicep/<component>/<component>-<stage>.bicepparam
```

Every `main.bicep` declares `param stage string` and
`param techResponsibility string` and sets them as the tags `environment`
and `techresponsibility` on each resource; `deploy.js` passes the
signed-in user. Each `.bicepparam` assigns `techResponsibility` the
placeholder `''`, which `deploy.js` overrides.

`node test.js` builds every file; it is the test of this repo and runs
before each commit. `node deploy.js <component|all> <stage>` deploys with a
what-if first; `all` deploys the components in the order of this table.

| Component            | Resources                                                                    | Settings                                                                                                                         |
| -------------------- | ---------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------- |
| `log-analytics`      | Log Analytics workspace `log-cars-<stage>`                                   | 30 days retention; daily cap 0.5 GB in dev, 1 GB in stage and prod                                                               |
| `container-registry` | Container registry `crcars<stage>`                                           | Basic, admin user off; images built with `az acr build`                                                                          |
| `network`            | VNet `vnet-cars-<stage>`, subnets `snet-cars-<side>-<stage>`, NSGs `nsg-cars-<side>-<stage>` | 10.10/16 dev, 10.20/16 stage, 10.30/16 prod; origin `.0.0/23`, custom `.2.0/23`, delegated to Container Apps; web from the internet allowed, between the subnets only HTTPS from custom to origin |
| `environment`        | Container Apps environments `cae-cars-origin-<stage>`, `cae-cars-custom-<stage>` | Consumption workload profile, external, in the subnet of their side, logs to `log-cars-<stage>`; needs `log-analytics` and `network` |

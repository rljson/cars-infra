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

| Component            | Resource                                 | Settings in demo                                        |
| -------------------- | ---------------------------------------- | ------------------------------------------------------- |
| `log-analytics`      | Log Analytics workspace `log-cars-<env>` | 30 days retention, 0.5 GB daily cap                     |
| `container-registry` | Container registry `crcars<env>`         | Basic, admin user off; images built with `az acr build` |

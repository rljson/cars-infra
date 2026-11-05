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

`az bicep build` of every file is the test of this repo and runs before
each commit. `deploy.sh <component> <env>` deploys a component with a
what-if first.

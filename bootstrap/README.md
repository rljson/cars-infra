<!--
@license
Copyright (c) rljson

Use of this source code is governed by terms that can be
found in the LICENSE file in the root of this package.
-->

# bootstrap

Run once per stage, before any Bicep deploy:

```bash
node bootstrap/bootstrap.js dev
```

Registers the resource providers the components need, among them
`Microsoft.App` for Container Apps, and creates the resource group
`rg-cars-<stage>` in Germany West Central with the tags `application`,
`environment` and `techresponsibility`. Does nothing that is done already.

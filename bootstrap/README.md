<!--
@license
Copyright (c) rljson

Use of this source code is governed by terms that can be
found in the LICENSE file in the root of this package.
-->

# bootstrap

Run once per environment, before any Bicep deploy:

```bash
bootstrap/bootstrap.sh demo
```

Creates the resource group `rg-cars-<env>` in Germany West Central with the tags
`application`, `environment` and `techresponsibility`. Does nothing when
the group exists already.

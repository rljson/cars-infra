<!--
@license
Copyright (c) rljson

Use of this source code is governed by terms that can be
found in the LICENSE file in the root of this package.
-->

# bootstrap

Run once, before any Bicep deploy:

```bash
node bootstrap/bootstrap.js
```

Registers the resource providers the components need, among them
`Microsoft.ContainerService` for the cluster, and creates the resource
group `rg-cars` in Germany West Central with the tags `application`,
`environment: shared` and `techresponsibility`. Does nothing that is done
already.

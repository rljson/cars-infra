<!--
@license
Copyright (c) rljson

Use of this source code is governed by terms that can be
found in the LICENSE file in the root of this package.
-->

# cars-infra

[English](README.md) | Deutsch

Die Azure-Ressourcen der Cars-Anwendung, einer Beispiel-App auf Rljson: ein
Bootstrap-Skript, ein Deploy-Skript und eine Bicep-Komponente je Ressource.

## Motivation

- Jede Azure-Ressource von cars ist in Git beschrieben, so lässt sich die
  Umgebung allein aus diesem Repo neu aufbauen
- Jedes Deployment zeigt zuerst ein What-if und wird erst nach einem Ja
  angewendet
- Was auf diesen Ressourcen läuft, liegt in
  [cars-deployment](https://github.com/rljson/cars-deployment); so berührt
  eine Änderung an einem Image nie die Azure-Ressourcen

## Aufbau

| Ordner      | Inhalt                                                                    |
| ----------- | ------------------------------------------------------------------------- |
| `bootstrap` | Einmal je Umgebung ausgeführt: legt die Ressourcengruppe an               |
| `lib`       | Einstellungen und Prüfungen, die die Skripte teilen                       |
| `bicep`     | Ein Ordner je Komponente: `main.bicep` und `<component>-<env>.bicepparam` |
| `test.sh`   | Baut jede Bicep- und Parameterdatei                                       |

Keine Umgebung ist ausgerollt: `demo` wurde mit seinem Cluster gelöscht.
Die Stufen `dev`, `stage` und `prod` folgen, in Germany West Central.

## Verwendung

Einmal die [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli)
und ihre Bicep CLI installieren:

```bash
az bicep install
```

Zuerst mit dem eigenen Entra-Konto anmelden; der Betreiber braucht die
Gruppe `cars-admins` oder `cars-operators`.

```bash
az login
az account set --subscription cars
```

Die Ressourcengruppe einer Umgebung einmal anlegen:

```bash
bootstrap/bootstrap.sh demo
```

Eine Komponente ausrollen; zuerst erscheint das What-if, und vor deinem Ja
ändert sich nichts:

```bash
./deploy.sh <component> demo
```

Nur die Änderungen zeigen:

```bash
./deploy.sh <component> demo --what-if
```

Beide Skripte prüfen zuerst die Umgebung und das aktive Abonnement. Jede
Ressource bekommt den Tag `techresponsibility` mit dem angemeldeten
Benutzer.

## Test

Vor jedem Commit jede Bicep- und Parameterdatei bauen:

```bash
./test.sh
```

## Grenzen

- Keine CI: Betreiber rollen von Hand von ihrem Rechner aus
- Keine Umgebung ausgerollt, bis die Stufen `dev`, `stage` und `prod` bestehen

## Stand

| Komponente           | Ressource        | Ausgerollt |
| -------------------- | ---------------- | ---------- |
| `log-analytics`      | `log-cars-<env>` | nein       |
| `container-registry` | `crcars<env>`    | nein       |

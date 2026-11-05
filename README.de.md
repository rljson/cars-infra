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
- Was im Cluster läuft, liegt in
  [cars-deployment](https://github.com/rljson/cars-deployment); so berührt
  eine Änderung an einem Image nie die Azure-Ressourcen

## Aufbau

| Ordner      | Inhalt                                                                    |
| ----------- | ------------------------------------------------------------------------- |
| `bootstrap` | Einmal je Umgebung ausgeführt: legt die Ressourcengruppe an               |
| `bicep`     | Ein Ordner je Komponente: `main.bicep` und `<component>-<env>.bicepparam` |

Die einzige Umgebung ist `demo`, in der Ressourcengruppe `rg-cars-demo`
in West Europe.

## Verwendung

Zuerst mit dem eigenen Entra-Konto anmelden; der Betreiber braucht die
Gruppe `cars-admins` oder `cars-operators`.

```bash
az login
az account set --subscription cars
```

Das Bootstrap-Skript und `deploy.sh <component> <env>` folgen mit den
ersten Komponenten.

## Grenzen

- Keine CI: Betreiber rollen von Hand von ihrem Rechner aus
- Nur eine Umgebung, `demo`

## Stand

Nur die Struktur; noch ist keine Azure-Ressource beschrieben.

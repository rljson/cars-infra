<!--
@license
Copyright (c) rljson

Use of this source code is governed by terms that can be
found in the LICENSE file in the root of this package.
-->

# cars-infra

[English](README.md) | Deutsch

Die Azure-Ressourcen der cars-Anwendung, einer Beispiel-App auf Rljson:
Node.js-Skripte zum Vorbereiten, Ausrollen und Testen und eine
Bicep-Komponente je Ressource.

## Motivation

- Jede Azure-Ressource von cars ist in Git beschrieben, so lässt sich jede
  Stufe allein aus diesem Repo neu aufbauen
- Jedes Deployment zeigt zuerst ein What-if und wird erst nach einem Ja
  angewendet
- Was auf diesen Ressourcen läuft, liegt in
  [cars-deployment](https://github.com/rljson/cars-deployment); so berührt
  eine Änderung an einem Image nie die Azure-Ressourcen

## Aufbau

| Pfad                     | Inhalt                                                                         |
| ------------------------ | ------------------------------------------------------------------------------ |
| `bootstrap/bootstrap.js` | Einmal je Stufe: registriert die Ressourcenanbieter, legt die Gruppe an        |
| `deploy.js`              | Rollt eine Komponente oder alle in eine Stufe aus                              |
| `test.js`                | Führt die Unit-Tests von `lib` aus und baut jede Bicep- und Parameterdatei     |
| `lib`                    | Einstellungen und Prüfungen, die die Skripte teilen, mit ihren Tests           |
| `bicep`                  | Ein Ordner je Komponente: `main.bicep` und `<component>-<stage>.bicepparam`    |

Es gibt drei Stufen, `dev`, `stage` und `prod`, jede in ihrer eigenen
Ressourcengruppe `rg-cars-<stage>` in Germany West Central. Sie teilen
nichts.

## Verwendung

Einmal [Node.js](https://nodejs.org) 22 oder neuer, die
[Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) und
ihre Bicep CLI installieren:

```bash
az bicep install
```

Zuerst mit dem eigenen Entra-Konto anmelden; der Betreiber braucht die
Gruppe `cars-admins` oder `cars-operators`.

```bash
az login
az account set --subscription cars
```

Eine Stufe einmal vorbereiten:

```bash
node bootstrap/bootstrap.js dev
```

Alle Komponenten einer Stufe der Reihe nach ausrollen; jede zeigt zuerst
ihr What-if, und nichts ändert sich vor deinem Ja:

```bash
node deploy.js all dev
```

Eine Komponente ausrollen oder nur die Änderungen zeigen:

```bash
node deploy.js network dev
node deploy.js network dev --what-if
```

`--yes` wendet nach dem What-if ohne Rückfrage an, für Läufe ohne
Terminal. Die Skripte prüfen zuerst die Stufe und das aktive Abonnement.
Jede Ressource bekommt das Tag `techresponsibility` mit dem angemeldeten
Benutzer.

## Test

Vor jedem Commit:

```bash
node test.js
```

## Grenzen

- Noch keine CI: Betreiber rollen von Hand von ihrem Rechner aus; die
  GitHub-Actions-Workflows werden dieselben Skripte aufrufen
- Noch keine Datenbanken, kein Speicher und keine Identitäten

## Stand

| Komponente           | Ressourcen je Stufe                                                                  | dev  | stage | prod |
| -------------------- | ------------------------------------------------------------------------------------ | ---- | ----- | ---- |
| `log-analytics`      | `log-cars-<stage>`                                                                   | ja   | nein  | nein |
| `container-registry` | `crcars<stage>`                                                                      | ja   | nein  | nein |
| `network`            | `vnet-cars-<stage>`, `snet-cars-<side>-<stage>`, `nsg-cars-<side>-<stage>`            | ja   | nein  | nein |
| `environment`        | `cae-cars-origin-<stage>`, `cae-cars-custom-<stage>`                                 | blockiert | nein  | nein |

Die Umgebungen von `dev` scheiterten: das Abonnement erlaubt nur eine
Container-Apps-Umgebung in Germany West Central; ein höheres Kontingent
ist nötig.

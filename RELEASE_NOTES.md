# Bockis System-Tool v4.2.1

**Datum:** 2026-04-08  
**Autor:** Bockis

---

## Neue Funktionen

- **SmartRepair** (`Modules/Tools/SmartRepair.psm1`): Neues intelligentes Reparatur-Modul mit vollautomatischem Ablauf
  - SFC Auto-Repair (Systemdateiprüfung mit automatischer Korrektur)
  - DISM RestoreHealth (Online-Image-Reparatur)
  - CHKDSK Online-Scan (Dateisystemprüfung ohne Neustart)
  - Checks nach Sinnhaftigkeit geordnet — Neustart-Aufforderung erst am Ende
- **GitHub Sponsors**: FUNDING.yml hinzugefügt, Sponsors-Badge im README integriert
- **Release-Skript** (`Create-GitHubRelease.ps1`): Wiederverwendbares PowerShell-Skript zum automatisierten Erstellen von GitHub Releases per API

## Verbesserungen

- **UpdateManager** (`Modules/UpdateManager.psm1`): Textausgabe und Code-Formatierung verbessert, Catch-Blöcke vereinheitlicht
- **Update-Link**: Wird nun auf das öffentliche Release-Repo (`Bockis-Win_Gui`) umgeleitet statt auf das DEV-Repo
- **README**: Aktualisiert und um Sponsors-Abschnitt ergänzt
- **Veraltete Lib-Dateien** bereinigt (nicht mehr benötigte DLLs entfernt)

## Sicherheit

- **GitHub-Token vollständig entfernt**: Hardcodierter Token wurde aus `UpdateManager.psm1` und `DependencyChecker.psm1` entfernt
- **`.env`-System eingeführt**: Token wird nun über Umgebungsvariable `GITHUB_TOKEN` geladen (`.env`-Datei ist in `.gitignore` eingetragen und wird nie committed)
- **LICENSE**: Copyright-Jahr aktualisiert

## Enthaltene Commits seit v4.1.8

| Commit | Beschreibung |
|--------|-------------|
| `59405c9` | Update README.md |
| `e97cf31` | Verbesserung der Textausgabe und Anpassungen |
| `1b00c38` | Release: Version 4.1.9 |
| `f19750d` | Cleanup: veraltete Lib-Dateien entfernt |
| `bf8125d` | Refactor: SmartRepair - Checks neu geordnet, Neustart ans Ende |
| `4e18c62` | Feature: SmartRepair - SFC, DISM und CHKDSK integriert |
| `aed4e75` | Security: GitHub-Token entfernt, Update-Link angepasst |
| `f06a5b2` | Docs: GitHub Sponsors Badge ergänzt |
| `b0a4448` | Add: FUNDING.yml für GitHub Sponsors |
| `ce53287` | Update: Module aktualisiert, SmartRepair.psm1 hinzugefügt |
| `dcbe83d` | Add: GitHub Actions Workflow für Release-Sync |

---

## Installation

1. `Win_Gui_Module.ps1` mit PowerShell **als Administrator** starten
2. Oder via `Bockis System-Tool starten.bat`

## Systemvoraussetzungen

- Windows 10 / Windows 11 (64-Bit)
- PowerShell 5.1 oder höher
- Administratorrechte erforderlich

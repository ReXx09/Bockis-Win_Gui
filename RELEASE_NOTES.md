# Bockis System-Tool v4.2.1

**Datum:** 2026-04-09  
**Autor:** Bockis

---

## Neue Funktionen

- **Python-Dashboard: SVG-Icon-System** integriert für konsistente UI-Icons.
- **Schnellstart-Launcher**: Frei konfigurierbare Kacheln für Tools, Apps/Dienste und URLs.
- **Schnellstart als eigenes Menü**: Launcher aus dem Tools-Bereich in eine dedizierte Seite ausgelagert.
- **Launcher-Kategorien** mit Filter-Chips, Gruppierung und Kategorie-Hints im Editor.
- **Launcher-Icon-Picker**: Wählbare Logos/Icons für bessere visuelle Erkennbarkeit.
- **Zentraler Bearbeitungsmodus** für Schnellstart-Kacheln mit Lösch-`x` in der Kartenecke.

## Verbesserungen

- **Audio-Routing/Anzeige**: Mikrofone werden stabil als Anzeige-Geräte geführt und aktive Mikrofone konsistent markiert.
- **Theme-Setup**: Preset-Auswahl bleibt nach `Anwenden` erhalten.
- **Layout-Persistenz**: Migration alter Layout-Keys, dadurch deutlich weniger unerwartete Dashboard-Resets.
- **Launcher-Kompatibilität**: Browser-Fallback, wenn die neue Launcher-API auf einem noch alten Backend-Prozess fehlt.

## Sicherheit

- Keine zusätzlichen Sicherheitsänderungen gegenüber v4.2.0.

## Enthaltene Commits seit v4.2.0

| Commit | Beschreibung |
|--------|-------------|
| `707ebef` | feat(dashboard): add shared svg icon system |
| `78fc6cc` | fix(audio): mark active microphone as standard device |
| `a792361` | fix(dashboard): migrate legacy layout storage keys |
| `fe8ee62` | fix(audio): always render microphones as display-only |
| `c705c48` | fix(theme): preserve selected preset on apply |
| `396478d` | feat(tools): add configurable quick launch tiles |
| `f6daf44` | fix(launchers): fall back when backend route is unavailable |
| `52a2a6e` | feat(launchers): add icon picker and simplify cards |
| `9669381` | Add quickstart page categories |
| `f0b6360` | Refine quickstart edit mode |
| `512e9ec` | Bump version to 4.2.1 |

---

## Installation

1. `Win_Gui_Module.ps1` mit PowerShell **als Administrator** starten
2. Oder via `Bockis System-Tool starten.bat`

## Systemvoraussetzungen

- Windows 10 / Windows 11 (64-Bit)
- PowerShell 5.1 oder höher
- Administratorrechte erforderlich

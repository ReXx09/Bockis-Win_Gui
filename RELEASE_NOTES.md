# Bockis System-Tool v4.2.2

**Datum:** 2026-04-10  
**Autor:** Bockis

---

## Neue Funktionen

- **Python-Dashboard: SVG-Icon-System** integriert für konsistente UI-Icons.
- **Schnellstart-Launcher**: Frei konfigurierbare Kacheln für Tools, Apps/Dienste und URLs.
- **Schnellstart als eigenes Menü**: Launcher aus dem Tools-Bereich in eine dedizierte Seite ausgelagert.
- **Launcher-Kategorien** mit Filter-Chips, Gruppierung und Kategorie-Hints im Editor.
- **Launcher-Icon-Picker**: Wählbare Logos/Icons für bessere visuelle Erkennbarkeit.
- **Zentraler Bearbeitungsmodus** für Schnellstart-Kacheln mit Lösch-`x` in der Kartenecke.
- **Dashboard Tools-Menü komplett neu aufgebaut**: Kategorisierte Tool-Karten mit erweiterten Windows-11-Werkzeugen.
- **Audio-Favoriten pro Anwendung**: Bis zu 3 bevorzugte Ausgabegeräte je App mit One-Klick-Umschaltung.
- **Audio-Bearbeitungsmodus**: Erweiterte Steuerung (Standard setzen, Entfernen/Unhide, Zusatzinfos) gezielt nur im Edit-Modus.

## Verbesserungen

- **Audio-Routing/Anzeige**: Mikrofone können direkt als Standard gesetzt werden; aktive Eingänge/Ausgänge werden robuster erkannt.
- **Audio-Zuverlässigkeit**: Verbesserte Umschaltlogik mit Verifikation, Retry und In-Flight-Schutz gegen Doppelaktionen.
- **Audio-Übersicht**: Standard-Mikrofon wird zusätzlich in der eingeklappten Geräteansicht angezeigt.
- **Audio-UX**: Lautstärke-Slider bleiben dauerhaft sichtbar, während riskantere Aktionen im Edit-Modus bleiben.
- **Geräteverwaltung**: Geräte lassen sich pro Nutzer in der UI ausblenden und gezielt wiederherstellen.
- **Dashboard-Performance**: Polling/Refresh nach Seite und sichtbaren Widgets statt globalem Voll-Refresh.
- **Tool-Toggle-Reaktionszeit**: Sofortiger visueller Statuswechsel durch optimistisches UI-Update und bessere Backend-Synchronisierung.
- **Glass-/Transparenz-Effekt**: Deutlich stärkere und konsistentere Anwendung auf Buttons, Topbar, Navigation und Launcher.
- **Theme-Setup**: Preset-Auswahl bleibt nach `Anwenden` erhalten.
- **Layout-Persistenz**: Migration alter Layout-Keys, dadurch deutlich weniger unerwartete Dashboard-Resets.
- **Launcher-Kompatibilität**: Browser-Fallback, wenn die neue Launcher-API auf einem noch alten Backend-Prozess fehlt.

## Bugfixes

- **Tools-Ansicht**: Mehrere Layout-Fixes für stabile 2-Zeilen-Beschreibung und saubere Button/Description-Ausrichtung.
- **Toggle-Erkennung**: God Mode, Services und weitere System-Tools werden zuverlässiger als offen/geschlossen erkannt.
- **Routing/Deep-Links**: Dashboard-Seitenrouten wurden korrigiert.
- **Dependency-Checks**: Robusteres Python/Git-Handling inklusive Caching und weniger Fehltrigger.

## Sicherheit

- Keine zusätzlichen Sicherheitsänderungen gegenüber v4.2.0.

## Enthaltene Commits seit v4.2.1

| Commit | Beschreibung |
|--------|-------------|
| `fe0ef08` | Keep audio volume sliders visible outside edit mode |
| `9b58ea7` | Add audio edit mode for advanced controls and details |
| `7a80110` | Improve audio switching reliability and add per-app output favorites |
| `3ff7cd3` | Fix microphone default selection state and audio dedup |
| `be50fe6` | Show microphone entry in collapsed audio device list |
| `f9689f8` | Add hide/unhide audio devices with X button |
| `de5e589` | Enable setting default microphone in dashboard audio devices |
| `efc21f8` | Set Win-GUI to 4.2.2 and Dashboard to 1.0.1 |
| `63f4ad7` | Strengthen glass effect for hover buttons and launcher tiles |
| `030e526` | Scope dashboard refresh by page and visible widgets |
| `b207f31` | Fix 5s active-state delay for tool highlight |
| `bbed571` | Fix 20s active-state delay with optimistic update + cache invalidation |
| `808d49f` | Reduce dashboard lag with tool state caching and poll guard |
| `dd8ad3a` | Performance optimization: reduce PowerShell timeouts and add caching |
| `f6c9ed6` | Fix tool toggle detection and availability checks |
| `3e61111` | Fix God Mode toggle with Explorer window detection |
| `06d887c` | Fix Services toggle detection and close handling |
| `7d28a4f` | Tools fallback to legacy run endpoint when newer APIs are missing |
| `e35a41c` | Add open-state color and toggle open/close behavior for tools |
| `bbd7ce4` | Split tools page into per-category dashboard cards |
| `44ab0c0` | Add full categorized Win11 hidden tools set without duplicates |
| `ae9a9e0` | Rebuild tools menu into categorized tiles |

---

## Installation

1. `Win_Gui_Module.ps1` mit PowerShell **als Administrator** starten
2. Oder via `Bockis System-Tool starten.bat`

## Systemvoraussetzungen

- Windows 10 / Windows 11 (64-Bit)
- PowerShell 5.1 oder höher
- Administratorrechte erforderlich

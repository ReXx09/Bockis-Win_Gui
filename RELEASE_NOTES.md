# Bockis System-Tool v4.2.4

**Datum:** 2026-05-20  
**Autor:** Bockis

---

## Bugfixes

- **Browser öffnet sich nicht (Admin-Kontext)**: `Open-UrlInBrowser` nutzt jetzt `Shell.Application` des laufenden (nicht-erhöhten) Explorer-Prozesses als erste Methode — behebt die Chromium/Brave-Elevation-Barriere wenn die GUI mit Admin-Rechten läuft.
- **Add-ons starten nicht**: `.bat`- und `.cmd`-Dateien werden jetzt explizit über `cmd.exe /c` ausgeführt — zuverlässiger aus erhöhtem Kontext als die Shell-File-Association.
- **WPF-Fehler lautlos verschluckt**: `Add_Click`-Handler in Extension-Kacheln hat jetzt `try-catch` mit `Write-ToolLog`-Logging.
- **Settings-Dialog Duplikate**: Doppelte Eintrags-Optionen für Extension-Start im Legacy-Dialog entfernt.
- **Settings-Dialog Action-Buttons**: Direkte Funktionsaufrufe und korrekte Closure-Variablen-Erfassung.
- **Tray-Wiederherstellung**: Stabilität beim GUI-Wiederherstellen aus dem Tray verbessert.

## Neue Features

- **Extensions-System**: Vollständig neues System zur Verwaltung externer Erweiterungen (bockis-dashboard, multimonitor-profile-tool) — Start, Status und Einstellungen direkt aus der GUI.
- **ADB Link** in der Tool-Bibliothek unter `Coding / IT` hinzugefügt (direkter Download-Link).
- **DetectCommand-Mechanismus**: Tools ohne Winget-ID können jetzt über einen PATH-Befehl (`adb`, etc.) als installiert erkannt werden.

## Verbesserungen

- **Extension-Logging**: `Open-ExtensionEntryPoint` schreibt Start- und Fehler-Ereignisse in die Tool-Logs (`EXTENSION`-ToolName).
- **Settings-Modernisierung**: Aktualisierter Settings-Dialog mit modernem UI und direkter GUI-Integration.
- **Submodule**: `Data/Add-ons/bockis-dashboard` und `Data/Add-ons/multimonitor-profile-tool` als Git-Submodule registriert.
- **Set-ProjectVersion**: Pfadfehler `Tools\` → `#_Tools\` korrigiert.

## Enthaltene Commits seit v4.2.3

| Commit | Beschreibung |
|--------|-------------|
| `1c653ce` | bump: version 4.2.3 -> 4.2.4 |
| `f2d58e3` | fix: Browser-Start bei Admin-Kontext, Add-on-Start, ADB Link; Submodule |
| `d484afd` | Clean: Remove Duplicate Extension Startup Options from Legacy Settings Dialog |
| `eb1e20d` | Fix: Settings Modern Dialog Action Buttons - Direct Function Calls |
| `6f150ee` | Fix: Settings Action Button Closure Variable Capture |
| `d04c3a7` | Feature: Add Extensions System & Settings Modernization |
| `25a1759` | Fix tray restore stability and update GUI settings integration |

---

## Neue Funktionen

### Win GUI
- **DependencyChecker – kompakte Gruppenansicht**: Standardmäßig werden nur die Repo-Updates-Gruppe und Gruppen mit Handlungsbedarf angezeigt. Alle anderen Gruppen sind ausgeblendet und können per Toggle eingeblendet werden.
- **DependencyChecker – Transparenz-Label**: Zeigt „Geprüft: X Abhängigkeiten | Sichtbar: Y" — alle Abhängigkeiten werden immer vollständig geprüft, unabhängig von der Ansicht.
- **Git Pull – kombinierte Sicherheitsabfrage**: Branch, Quelle und Beta-Hinweis in einer einzigen Bestätigungsdialog zusammengefasst.
- **Git in Tool-Downloads**: Git ist jetzt direkt unter Coding / IT in der Tool-Bibliothek verlinkt, inklusive Schnellinstallation aus dem Dependency-Checker.

### Dashboard (v1.0.2)
- **SVG-Icon-System** integriert für konsistente UI-Icons.
- **Schnellstart-Launcher**: Frei konfigurierbare Kacheln für Tools, Apps/Dienste und URLs.
- **Schnellstart als eigenes Menü**: Launcher aus dem Tools-Bereich in eine dedizierte Seite ausgelagert.
- **Launcher-Kategorien** mit Filter-Chips, Gruppierung und Kategorie-Hints im Editor.
- **Launcher-Icon-Picker**: Wählbare Logos/Icons für bessere visuelle Erkennbarkeit.
- **Zentraler Bearbeitungsmodus** für Schnellstart-Kacheln mit Lösch-`x` in der Kartenecke.
- **Dashboard Tools-Menü komplett neu aufgebaut**: Kategorisierte Tool-Karten mit erweiterten Windows-11-Werkzeugen.
- **Audio-Favoriten pro Anwendung**: Bis zu 3 bevorzugte Ausgabegeräte je App mit One-Klick-Umschaltung.
- **Audio-Bearbeitungsmodus**: Erweiterte Steuerung (Standard setzen, Entfernen/Unhide, Zusatzinfos) gezielt nur im Edit-Modus.
- **Dashboard-weiter Speichern-Button**: Alle Seitenlayouts werden persistiert.
- **Abhängigkeitskarte**: Top-5-Auswahl per Nutzer, kompakt mit expandierbarem Toggle.
- **Kachelgrößen 1/4 und 1/8**: Neue kompakte Größenoptionen für Status-Karten.
- **Audio-Pegel-Bars**: Live-Eingangs- und Ausgangspegel pro Route und Programm.
- **Per-App Audio-Routing**: Pure-Python-COM-Implementierung mit Windows-Fallback-Steuerung.

## Verbesserungen

### Win GUI
- **DependencyChecker – Gruppenreihenfolge**: Repo-Updates steht immer an erster Stelle.
- **DependencyChecker – Git**: Winget-ID und ToolLibrary-Verlinkung für konsistente Installation.
- **DependencyChecker – farbige Abschnitte**: Gruppen werden farblich getrennt dargestellt.
- **DependencyChecker – Tabellenabstand**: Kompakteres Layout für bessere Übersicht.
- **Git-Update-Benachrichtigung**: Fetch-Prüfung, Banner und Nav-Dot-Indikator bei verfügbarem Update.

### Dashboard
- **Audio-Routing/Anzeige**: Mikrofone können direkt als Standard gesetzt werden; aktive Eingänge/Ausgänge werden robuster erkannt.
- **Audio-Zuverlässigkeit**: Verbesserte Umschaltlogik mit Verifikation, Retry und In-Flight-Schutz.
- **Audio-Übersicht**: Standard-Mikrofon wird zusätzlich in der eingeklappten Geräteansicht angezeigt.
- **Audio-UX**: Lautstärke-Slider dauerhaft sichtbar; riskantere Aktionen bleiben im Edit-Modus.
- **Geräteverwaltung**: Geräte lassen sich pro Nutzer ausblenden und gezielt wiederherstellen.
- **Dashboard-Performance**: Polling/Refresh nach Seite und sichtbaren Widgets statt globalem Voll-Refresh.
- **Tool-Toggle-Reaktionszeit**: Sofortiger visueller Statuswechsel durch optimistisches UI-Update.
- **Glass-/Transparenz-Effekt**: Stärkere und konsistentere Anwendung auf Buttons, Topbar, Navigation und Launcher.
- **Theme-Setup**: Preset-Auswahl bleibt nach `Anwenden` erhalten.
- **Layout-Persistenz**: Migration alter Layout-Keys, weniger unerwartete Dashboard-Resets.
- **Launcher-Kompatibilität**: Browser-Fallback bei älterer Backend-Version.
- **Audio Safe Mode**: Python-3.14-kompatibler Modus ohne riskante Geräteenumeration.
- **Log-Viewer**: HTML-Logs bevorzugt dargestellt mit strukturierten Filtern und Parsing.

## Bugfixes

- **Tools-Ansicht**: Layout-Fixes für stabile 2-Zeilen-Beschreibung und saubere Ausrichtung.
- **Toggle-Erkennung**: God Mode, Services und weitere System-Tools zuverlässiger als offen/geschlossen erkannt.
- **Routing/Deep-Links**: Dashboard-Seitenrouten korrigiert.
- **Dependency-Checks**: Robusteres Python/Git-Handling mit Caching und weniger Fehltriggern.
- **Winget-Exit-Code**: Kein Fehler mehr bei „kein Update verfügbar" (Exit Code 0).
- **Audio-Routing**: COM-Index-Fehler bei per-App-Routing behoben; WinRT-Initialisierung ergänzt.
- **Audio-Pegel**: Endpoint-Peak-Methode stabilisiert, Polling-Backoff verhindert Überlastung.

## Sicherheit

- Keine zusätzlichen Sicherheitsänderungen gegenüber v4.2.2.

## Enthaltene Commits seit v4.2.2

| Commit | Beschreibung |
|--------|-------------|
| `d13239b` | Bump version: alle Versionseintraege auf 4.2.3 aktualisiert |
| `e343aa4` | DependencyChecker: Git explizit mit Tool-Downloads Coding/IT verknuepfen |
| `eba04d9` | Git Pull: eine zusammengefuehrte Sicherheitsbestaetigung |
| `b12f71e` | DependencyChecker: zeige gepruefte vs sichtbare Abhaengigkeiten |
| `3f1176e` | DependencyChecker: reduzierte Gruppenansicht mit Repo-Fokus und Toggle |
| `eedd1d5` | Bump version: Win_Gui 4.2.3, Dashboard 1.0.2 |
| `659c97f` | Use full-width live layout for route items |
| `57b2839` | Remove redundant drag-handle icon from dashboard card headers |
| `017dbc7` | Use compact dropdown for tile size selection in card headers |
| `d6ed9cf` | Add true 1/8 tile size for compact status cards |
| `058441f` | Add true 1/4 tile size option for dashboard cards |
| `95a0ae5` | Disable risky device enumeration in safe mode |
| `ffcdfb5` | Add Python 3.14 audio safe mode |
| `0839049` | Serialize audio COM reads and add backend fault logging |
| `cd43719` | Harden audio meters by using endpoint peak per device |
| `7c4b12b` | Enrich SFC/MRT/CHKDSK/Defender logs with context |
| `0e8a0d3` | Enhance dashboard log viewer with structured parsing and filters |
| `a8842a3` | Add colorized HTML companion logs |
| `fe6d27e` | Add dashboard-wide save button and persist all page layouts |
| `40fe717` | Allow user-selected Top 5 dependencies with persistent picker |
| `f703826` | Compact dependency card: top 5 plus actionable with toggle |
| `8a6125c` | Group dependency table with colored sections |
| `80ad91d` | Compact dependency table spacing and sizing |
| `bdf616c` | Move dashboard dependency group above repo updates |
| `7635eee` | Add git update notification: fetch check, banner and nav dot indicator |
| `3a80b58` | Use Git instead of GitHub CLI in dependency hint for Git Pull |
| `d8936be` | Fix DependencyChecker handling for winget no-upgrade exit code |
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

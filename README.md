# Bockis System-Tool v4.2.6

Ein professionelles PowerShell-basiertes Systemwartungs-Tool mit moderner grafischer Benutzeroberfläche, WPF-Integration und umfassenden Diagnose- und Reparaturfunktionen für Windows 10/11.

[![PowerShell](https://img.shields.io/badge/PowerShell-5.1+-blue.svg)](https://github.com/PowerShell/PowerShell)
[![Windows](https://img.shields.io/badge/Windows-10%2F11-blue.svg)](https://www.microsoft.com/windows)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE.txt)
[![GitHub Sponsors](https://img.shields.io/github/sponsors/ReXx09?label=Sponsor&logo=GitHub)](https://github.com/sponsors/ReXx09)

## 🔑 Hauptfunktionen

### 🛡️ System & Sicherheit
- **MRT Quick Scan**: Schnelle Malware-Erkennung mit Microsoft Malicious Software Removal Tool
- **MRT Full Scan**: Vollständige Systemprüfung auf Schadsoftware
- **Windows Defender**: Integration der Windows-eigenen Antivirus-Software mit direktem Zugriff
- **Defender Offline-Scan**: Bootfähiger Malware-Scan vor dem Windows-Start
- **SFC Check**: System File Checker zur Reparatur beschädigter Windows-Dateien
- **Windows Update**: Automatische Suche und Installation verfügbarer System-Updates

### 🔧 SmartRepair (NEU in v4.2.2)
Vollautomatisches Reparaturmodul — führt alle Schritte in der sinnvollsten Reihenfolge aus:
- **SFC Auto-Repair**: Systemdateiprüfung mit automatischer Korrektur
- **DISM RestoreHealth**: Online-Image-Reparatur via Windows Update
- **CHKDSK Online-Scan**: Dateisystemprüfung ohne Neustart
- Neustart-Aufforderung erscheint erst am Ende (wenn wirklich nötig)

### 💽 Diagnose & Reparatur
- **Memory Diagnostic**: Überprüfung des Arbeitsspeichers auf Hardware-Fehler
- **CHKDSK**: Festplatten-Diagnose und -Reparatur mit interaktiver Laufwerksauswahl
- **DISM-Tools**: Windows-Image-Reparatur-Suite
  - **Check Health**: Schnelle Integritätsprüfung des Windows-Images
  - **Scan Health**: Detaillierte Analyse des Windows-Images
  - **Restore Health**: Automatische Reparatur beschädigter Windows-Komponenten

### 🌐 Netzwerk-Tools
- **Ping Test**: Umfassende Netzwerk-Konnektivitätstests zu verschiedenen Servern
- **Netzwerk zurücksetzen**: Neustart der Netzwerkadapter bei Verbindungsproblemen

### 🧹 Bereinigung
- **Disk Cleanup**: Windows-eigenes Tool zur Bereinigung temporärer Systemdateien
- **Custom-Cleanup**: Erweiterte Systemreinigung mit anpassbaren Bereinigungsoptionen

### 📊 Hardware-Monitor & System-Info
- **Echtzeit-Hardware-Überwachung** (LibreHardwareMonitor):
  - CPU-Auslastung, Temperatur und Taktfrequenz pro Kern
  - RAM-Nutzung, verfügbarer Speicher und Cache
  - GPU-Auslastung, Temperatur und Video-RAM
  - Festplatten-I/O und Temperatur
  - Mainboard-Sensoren und Lüftergeschwindigkeiten
- **Hardware-Info-Boxen**: Detaillierte Echtzeit-Informationen:
  - Prozessor-Spezifikationen (Kerne, Takt, Cache, Architektur)
  - Arbeitsspeicher-Module, Kapazität und Auslastung (DDR5 per-DIMM Temperaturen)
  - Grafikkarten-Details und Video-RAM
  - Festplatten-Status und Speicherplatz
  - Netzwerkadapter und IP-Konfiguration
  - Betriebssystem-Details und Uptime
- **Hardware-History-Datenbank**: Automatische Protokollierung aller Sensor-Werte
- **Statistik-Popup**: Vollständige Tabelle für CPU/GPU/RAM mit Schwellenwert-Farbkodierung

### 🔽 Tool-Downloads & Winget-Integration
- **50+ vordefinierte Tools**: Kategorisiert nach System/Browser/Gaming/Dev/Multimedia
- **Winget-Integration**: Automatische Installations-Status-Erkennung
- **Intelligentes Cache-System**: Reduziert Winget-Aufrufe (5-15 Min Cache)
- **Such-Funktion**: Filter nach Tool-Name, Kategorie oder Tags
- **Tool-Kategorien**:
  - System-Tools (7-Zip, CPU-Z, GPU-Z, OCCT, LibreHardwareMonitor, UniGetUI)
  - Browser (Brave, Firefox, Chrome, Vivaldi, Waterfox)
  - Kommunikation (Discord, Skype, WhatsApp, Zoom, Teams, Telegram)
  - Gaming (Steam, Epic Games, Battle.net, EA App, GOG Galaxy)
  - Multimedia (VLC, Audacity, OBS Studio, GIMP, Blender, Handbrake)
  - Office (LibreOffice, Apache OpenOffice)
  - Entwicklung (VS Code, Git, Python, Node.js, Docker)
  - Cloud Storage (Nextcloud Desktop, Dropbox, Google Drive)

### 🗄️ Erweiterte Funktionen
- **SQLite-Datenbank-Integration**: Automatische Protokollierung aller Tool-Ausführungen
  - DiagnosticResults-Tabelle: Tool-Name, Zeitstempel, Ergebnis, ExitCode, Details
  - HardwareHistory-Tabelle: Sensor-Werte über Zeit (CPU/GPU/RAM-Verlauf)
  - SystemSnapshots-Tabelle: Periodische System-Zustandsaufnahmen
- **Status-Indikatoren**: Visuelle Anzeige des letzten Ausführungsstatus für jeden Button
- **Scan-Historie**: Zeitstempel und Verlaufsverfolgung aller durchgeführten Systemscans
- **Collapsible Panels**: Aufklappbare Navigations-Menüs (System/Diagnose/Netzwerk/Bereinigung)
- **Custom Title Bar**: Borderless Window mit Drag-Support
- **F12-Shortcut**: PowerShell-Konsole ein-/ausblenden
- **Automatisches Fenster-Management**: Position und Größe werden gespeichert
- **Modulares Logging-System**: Zentrale Logs in `%LOCALAPPDATA%\BockisSystemTool\Logs`
- **Cloud-Sync-kompatibel**: Intelligente Fehlerbehandlung für Nextcloud/OneDrive
- **Einstellungs-Persistenz**: JSON-basierte Konfiguration mit ColorScheme-Support

## ⚙️ Systemvoraussetzungen

- Windows 10/11 (64-Bit)
- PowerShell 5.1 oder höher
- Administratorrechte
- Mindestens 4 GB RAM
- 100 MB freier Speicherplatz

## 📥 Installation

### Portable (empfohlen)
1. Neueste Version von [Releases](https://github.com/ReXx09/Bockis-Win_Gui/releases) herunterladen
2. ZIP in ein Verzeichnis entpacken
3. `Bockis System-Tool starten.bat` als Administrator ausführen

oder direkt:
```powershell
powershell.exe -ExecutionPolicy Bypass -File "Win_Gui_Module.ps1"
```

### ⚠️ Windows Defender Warnung (LibreHardwareMonitor-Treiber)

**Problem (nur LibreHWM < v0.9.4):** Ältere Versionen nutzen den WinRing0-Treiber, der von Defender als "VulnerableDriver" markiert wird.

**Lösung:** LibreHardwareMonitor **v0.9.4+** nutzt den modernen **PawnIO-Treiber**, der **keine Defender-Warnungen** mehr verursacht.

```powershell
winget upgrade LibreHardwareMonitor.LibreHardwareMonitor
```

Falls dennoch eine Warnung erscheint (manuell):
1. **Windows-Sicherheit** → **Viren- & Bedrohungsschutz** → **Einstellungen verwalten**
2. **Ausschlüsse** → **Ausschlüsse hinzufügen oder entfernen**
3. **Ordner hinzufügen** → Installationsordner auswählen

> **Hinweis:** LibreHardwareMonitor ist ein vertrauenswürdiges Open-Source-Projekt ([GitHub](https://github.com/LibreHardwareMonitor/LibreHardwareMonitor)) und wird von tausenden Projekten weltweit genutzt.

## 📂 Verzeichnisstruktur

```
Bockis-Win_Gui/
├── Win_Gui_Module.ps1               # Hauptskript (~15.000 LOC)
├── Bockis System-Tool starten.bat   # Startskript (als Administrator)
├── Create-GitHubRelease.ps1         # Release-Automatisierung
├── RELEASE_NOTES.md                 # Aktuelle Release Notes
├── config.json                      # Benutzer-Einstellungen (nicht im Repo)
├── README.md
├── LICENSE.txt
├── THIRD-PARTY-LICENSES.md
├── installer.iss                    # Inno Setup Installer
│
├── Modules/                         # PowerShell-Module
│   ├── Core/                        # Kern-Funktionalität
│   │   ├── Core.psm1               # Basis-Funktionen
│   │   ├── UI.psm1                 # UI-Hilfsfunktionen
│   │   ├── Settings.psm1           # Einstellungs-Verwaltung
│   │   ├── TextStyle.psm1          # Farb-/Style-System
│   │   ├── LogManager.psm1         # Zentrales Logging
│   │   ├── ProgressBarTools.psm1   # Fortschrittsanzeige
│   │   └── DependencyChecker.psm1  # DLL-Versions- und Update-Prüfung
│   │
│   ├── Tools/                       # Diagnose-/Reparatur-Tools
│   │   ├── SystemTools.psm1        # MRT, SFC, Memory Diagnostic
│   │   ├── SmartRepair.psm1        # Intelligente Auto-Reparatur (NEU)
│   │   ├── DISM-Tools.psm1         # DISM Check/Scan/Repair
│   │   ├── CHKDSKTools.psm1        # Festplatten-Checks
│   │   ├── NetworkTools.psm1       # Netzwerk-Diagnose/-Reparatur
│   │   ├── CleanupTools.psm1       # System-Bereinigung
│   │   ├── DefenderTools.psm1      # Windows Defender Integration
│   │   └── WindowsUpdateTools.psm1 # Update-Management
│   │
│   ├── Monitor/                     # Hardware-Überwachung
│   │   └── HardwareMonitorTools.psm1  # LibreHardwareMonitor-Integration
│   │
│   ├── ToolLibrary.psm1            # 50+ vordefinierte Tools
│   ├── ToolCache.psm1              # Winget-Cache-System
│   ├── DatabaseManager.psm1        # SQLite-Integration
│   ├── SystemInfo.psm1             # Systeminformationen
│   └── UpdateManager.psm1          # GitHub-Release-Update-Check
│
├── Lib/                             # Native Bibliotheken
│   ├── System.Data.SQLite.dll      # SQLite für .NET
│   ├── LibreHardwareMonitorLib.dll # Hardware-Monitoring (PawnIO ab v0.9.4)
│   ├── BlackSharp.Core.dll
│   ├── DiskInfoToolkit.dll
│   ├── RAMSPDToolkit-NDD.dll
│   ├── SQLite.cs
│   └── SQLiteAsync.cs
│
└── Data/                            # Laufzeitdaten (nicht im Repo)
    ├── Database/system_data.db     # SQLite-Datenbank
    ├── Logs/                       # Tool-Ausführungs-Logs
    └── Temp/                       # Temporäre Dateien
```

**Statistiken:**
- **Gesamt-LOC**: ~15.000 Zeilen Code
- **Aktive Module**: 18 PowerShell-Module
- **Exportierte Funktionen**: 80+
- **Vordefinierte Tools**: 50+

## 🚀 Benutzeranleitung

### Erster Start
1. **Automatische Rechte-Prüfung**: Das Tool prüft beim Start automatisch Administratorrechte
2. **Modul-Loading**: Alle erforderlichen Module werden mit Fortschrittsanzeige geladen
3. **Dependency-Check**: DLL-Versionen (LibreHWM, SQLite) werden geprüft
4. **Hardware-Initialisierung**: Die Echtzeit-Hardware-Überwachung startet automatisch
5. **GUI-Anzeige**: Die grafische Benutzeroberfläche öffnet sich

### Navigation
- **Collapsible Panels**: Aufklappbare Menüs links (System / Diagnose / Netzwerk / Bereinigung)
- **Info-Buttons**: ⓘ-Buttons mit detaillierten Erklärungen zu jedem Tool
- **Status-Indikatoren**: Farbige Punkte zeigen den letzten Ausführungsstatus
- **Ausgabe-Bereich**: Farbcodierte Live-Ausgabe aller Tool-Aktionen

### Hardware-Monitoring
- **CPU**: Auslastung, Temperatur, Taktfrequenz (CoreMin, PowerCores, VCore)
- **RAM**: Speichernutzung, freier Speicher, DDR5 DIMM-Temperaturen
- **GPU**: Grafikkarten-Auslastung, Temperatur, VRAM
- **Statistik-Popup**: Klick auf Hardware-Box → vollständige Sensor-Tabelle

### Keyboard-Shortcuts
| Shortcut | Funktion |
|----------|----------|
| `F12` | PowerShell-Konsole ein-/ausblenden |

## 🎨 ColorScheme-System

Benutzerdefinierte Farbschemata werden in `config.json` gespeichert:
```json
{
  "ColorScheme": {
    "Output": {
      "Colors": {
        "Background": "#1E1E1E",
        "Success": "#3DDC84",
        "Error": "#FF6B6B",
        "Warning": "#FFB74D",
        "Info": "#64B5F6"
      }
    }
  }
}
```

## ⚠️ Wichtige Hinweise

- **Administratorrechte erforderlich** für alle Systemoperationen
- **Tools nicht gleichzeitig ausführen** — parallele System-Scans vermeiden
- **Internetverbindung** für Windows Update, SmartRepair (DISM RestoreHealth) und Tool-Downloads
- **Neustart nach DISM / Memory Diagnostic** empfohlen
- **Log-Dateien** unter `%LOCALAPPDATA%\BockisSystemTool\Logs\` prüfen

## 📋 Changelog

### Version 4.2.6 (31. August 2026) — Aktuell
- 🔍 **Toolsuche behoben**: Die Trefferanzahl wird jetzt korrekt an die Suchstatusanzeige zurückgegeben — vorher zeigte ein einzelner Treffer fälschlich „Keine Ergebnisse“ an.
- ⚡ **Performance-Tweaks**: Neue Einstellungen für Transparenzeffekte, visuelle Effekte, Mausbeschleunigung und Windows Game Mode — mit Bestätigungsdialog und einmaliger Registry-Sicherung inkl. Wiederherstellung.
- 🔀 **Git Pull Status**: Die Dependency-Anzeige erkennt jetzt ungepushte lokale Commits und zeigt einen klaren Hinweis statt fälschlich „✓ Bereit“.

### Version 4.2.5 (25. August 2026)
- 🔄 **Git Pull**: Statusprüfung und Pull verwenden jetzt garantiert denselben lokalen Repository-Pfad.
- ♻️ **ToolLibrary-Reload**: Die Tool-Liste wird nach einem Pull beim Öffnen der Downloads-Ansicht neu geladen.
- 🎮 **Epic Games Launcher**: Als Anwendung mit Winget-Installation `EpicGames.EpicGamesLauncher` ergänzt.
- 🎵 **MediaHuman MP3 Converter**: Als Anwendung mit Winget-Installation `MediaHuman.MP3Converter` ergänzt.

### Version 4.2.4 (20. Mai 2026)
- ✨ **SmartRepair**: Neues intelligentes Auto-Reparaturmodul (SFC → DISM → CHKDSK in optimaler Reihenfolge)
- 🔐 **Security**: Hardcodierter GitHub-Token vollständig entfernt — Token-Verwaltung via `.env`-Datei
- 🔗 **Update-Link**: Wird nun auf das öffentliche Release-Repo umgeleitet
- 🤝 **GitHub Sponsors**: FUNDING.yml und Sponsors-Badge hinzugefügt
- 🚀 **Release-Automatisierung**: `Create-GitHubRelease.ps1` für automatisierte GitHub Releases
- 🧹 **Cleanup**: Veraltete Lib-Dateien und Hilfsdateien entfernt
- 📝 **UpdateManager**: Textausgabe verbessert, Code-Formatierung vereinheitlicht

### Version 4.1.9 (17. März 2026)
- 📝 **Textausgabe**: Verbesserungen der farbcodierten Ausgabe
- 🔧 **Anpassungen**: Allgemeine Code-Optimierungen

### Version 4.1.7 (18. Februar 2026)
- ✨ **Automatisches DLL-Update**: Integrierte Update-Funktion in DependencyChecker
- 🔍 **Versionserkennung**: Automatische Prüfung auf veraltete LibreHardwareMonitorLib.dll
- 📦 **NuGet-Integration**: Direkter Download von v0.9.5 bei Bedarf
- 🛡️ **Sicher**: Automatisches Backup vor DLL-Ersetzung

### Version 4.2.0-pre / 4.1.8 (23. März 2026)
- ✨ **CPU Stats**: CoreMin, PowerCores, VCore in der Statistik-Tabelle
- 🌡️ **DDR5 RAM-Temperaturen**: Per-DIMM Temperaturen via LibreHardwareMonitor
- 📊 **Statistik-Popup**: Schwellenwert-basierte Farbkodierung für CPU/GPU/RAM
- 🐛 **Debug-Fenster Fix**: Prozessbaum-Beendigung per `taskkill /T`

### Version 4.1.1 – 4.1.6 (Januar – Februar 2026)
- 🔧 **LibreHardwareMonitor Auto-Installation**: WinGet-Integration
- 🛡️ **PawnIO-Treiber**: Moderne Ring-0-Treiber-Unterstützung (v0.9.4+)
- 🔄 **Fallback-System**: Performance Counter-basierte Sensoren ohne LibreHWM
- 🔐 **Code-Signierung**: Self-Signed Zertifikat mit 5 Jahren Gültigkeit
- 🎯 **Icons**: Segoe MDL2 Assets Icons für alle Buttons

### Version 4.0 (November 2025)
- 🚀 **WPF-Integration**: ScrollViewer und WrapPanel für Tool-Downloads
- 🔽 **Tool-Download-System**: 50+ vordefinierte Tools mit Winget-Integration
- 🎯 **Intelligenter Cache**: ToolCache-System reduziert Winget-Aufrufe
- 📦 **Collapsible Panels**: Aufklappbare Navigation
- 🎨 **Borderless Window**: Custom Title Bar mit Drag-Support
- 🗄️ **HardwareHistory-Datenbank**: Automatische Speicherung aller Sensor-Werte

## 👥 Support & Mitwirkung

- **Issues**: [github.com/ReXx09/Bockis-Win_Gui/issues](https://github.com/ReXx09/Bockis-Win_Gui/issues)
- **Sponsor**: [github.com/sponsors/ReXx09](https://github.com/sponsors/ReXx09)

## 📄 Lizenz

Dieses Tool ist unter der MIT-Lizenz veröffentlicht. Siehe [LICENSE.txt](LICENSE.txt) für Details.
Drittanbieter-Lizenzen: [THIRD-PARTY-LICENSES.md](THIRD-PARTY-LICENSES.md)


## 🔍 FAQ

**Q: Warum meldet Windows Defender das Tool als Malware?**

A: Der Defender erkennt den Kernel-Treiber von LibreHardwareMonitor bei Versionen < v0.9.4 (WinRing0) als "VulnerableDriver" - dies ist ein bekannter False Positive. Ab v0.9.4 wird der modernere **PawnIO-Treiber** verwendet, der keine Warnungen mehr auslöst. Update empfohlen: `winget upgrade LibreHardwareMonitor.LibreHardwareMonitor`

**Q: Benötige ich Administratorrechte?**

A: Ja, alle System-Diagnose- und Reparatur-Tools erfordern erhöhte Rechte. Das Tool fordert diese automatisch beim Start an.

**Q: Werden meine Daten gesammelt?**

A: Nein. Alle Daten werden lokal in einer SQLite-Datenbank gespeichert. Der UpdateManager prüft anonym auf neue Versionen via GitHub API. Keine weiteren Datenübertragungen.

**Q: Kann ich eigene Tools hinzufügen?**

A: Ja, über `ToolLibrary.psm1` kann die `$script:toolLibrary`-Hashtable erweitert werden. Details in den Modul-Kommentaren.

**Q: Wo finde ich die Logs?**

A: Im `Data\Logs\`-Unterordner des Installationsverzeichnisses (z.B. `C:\Program Files\Bockis-Win_Gui\Data\Logs\`).

**Q: Funktioniert das Tool mit Nextcloud/OneDrive?**

A: Ja, das Tool hat spezielle Fehlerbehandlung für Cloud-Sync-Provider implementiert.



---



**Entwickelt von Bocki | v4.2.4 | Mai 2026**

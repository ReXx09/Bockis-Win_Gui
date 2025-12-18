# Bocki's Windows Tool-Kit v4.1

Ein professionelles PowerShell-basiertes Systemwartungs-Tool mit moderner grafischer Benutzeroberfläche, WPF-Integration, automatischem Update-System und umfassenden Diagnose-Funktionen für Windows-Systeme.

[![PowerShell](https://img.shields.io/badge/PowerShell-5.1+-blue.svg)](https://github.com/PowerShell/PowerShell)
[![Windows](https://img.shields.io/badge/Windows-10%2F11-blue.svg)](https://www.microsoft.com/windows)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE.txt)
[![Version](https://img.shields.io/badge/Version-4.1-brightgreen.svg)](https://github.com/ReXx09/Bockis-Win_Gui/releases)

## 🔑 Hauptfunktionen

Das Bockis System-Tool bietet eine umfassende Sammlung von Windows-Systemtools in einer benutzerfreundlichen grafischen Oberfläche:

### 🔄 Auto-Update-System (NEU in v4.1)
- **Automatische Update-Prüfung**: Verbindung zu GitHub Releases
- **Ein-Klick-Installation**: Download und Installation neuer Versionen
- **Integrierter Update-Button**: Direkt in der GUI verfügbar
- **Versionskontrolle**: Automatischer Versionsvergleich
- **Keine manuellen Downloads mehr**: Ab v4.1 vollautomatisch

### 📦 Tool-Download-Manager (NEU in v4.1)
- **50+ professionelle Tools**: Direkt aus der GUI installierbar
- **Winget-Integration**: Sichere Installation über Windows Package Manager
- **Kategorisierte Übersicht**:
  - System-Tools (Diagnose, Wartung, Optimierung)
  - Anwendungen (Browser, Office, Kommunikation)
  - Audio/TV (Media-Player, Streaming, Bearbeitung)
  - Coding/IT (IDEs, Editoren, Entwickler-Tools)
- **Such- und Filterfunktion**: Schnelles Finden gewünschter Tools
- **Tool-Cache**: Optimierte Ladezeiten durch intelligentes Caching
- **Installations-Status**: Live-Überwachung des Installationsfortschritts

### 🛡️ System & Sicherheit
- **MRT Quick Scan**: Schnelle Malware-Erkennung mit Microsoft Malicious Software Removal Tool
- **MRT Full Scan**: Vollständige Systemprüfung auf Schadsoftware
- **Windows Defender**: Integration der Windows-eigenen Antivirus-Software mit direktem Zugriff
- **Defender Offline-Scan**: Bootfähiger Malware-Scan vor dem Windows-Start
- **SFC Check**: System File Checker zur Reparatur beschädigter Windows-Dateien
- **Windows Update**: Automatische Suche und Installation verfügbarer System-Updates

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
  - Arbeitsspeicher-Module, Kapazität und Auslastung
  - Grafikkarten-Details und Video-RAM
  - Festplatten-Status und Speicherplatz
  - Netzwerkadapter und IP-Konfiguration
  - Betriebssystem-Details und Uptime
- **Hardware-History-Datenbank**: Automatische Protokollierung aller Sensor-Werte
- **Debug-Modi**: Erweiterte Diagnose-Informationen für CPU/GPU/RAM

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
- **WPF-ScrollViewer**: Moderne Kachel-Darstellung mit Smooth Scrolling
- **Installation per Klick**: Direkte Installation via Winget

### 🗄️ Erweiterte Funktionen
- **SQLite-Datenbank-Integration**: Automatische Protokollierung aller Tool-Ausführungen
  - DiagnosticResults-Tabelle: Tool-Name, Zeitstempel, Ergebnis, ExitCode, Details
  - HardwareHistory-Tabelle: Sensor-Werte über Zeit (CPU/GPU/RAM-Verlauf)
  - SystemSnapshots-Tabelle: Periodische System-Zustandsaufnahmen
- **Status-Indikatoren**: Visuelle Anzeige des letzten Ausführungsstatus für jeden Button
- **Scan-Historie**: Zeitstempel und Verlaufsverfolgung aller durchgeführten Systemscans
- **Erweiterte Benutzeroberfläche**: 
  - **Collapsible Panels**: Aufklappbare Navigations-Menüs (System/Diagnose/Netzwerk/Bereinigung)
  - **WPF-Integration**: Moderne UI-Komponenten (ScrollViewer, WrapPanel)
  - **Custom Title Bar**: Borderless Window mit Drag-Support
  - **Dunkles Theme**: Moderne UI ähnlich UniGetUI
  - **Tooltips**: Kontextuelle Hilfe für alle Buttons
  - **F12-Shortcut**: PowerShell-Konsole ein-/ausblenden
  - **Automatisches Fenster-Management**: Position und Größe werden gespeichert
- **Modulares Logging-System**: Zentrale Logs in `%LOCALAPPDATA%\BockisSystemTool\Logs`
- **Cloud-Sync-kompatibel**: Intelligente Fehlerbehandlung für Nextcloud/OneDrive
- **Einstellungs-Persistenz**: JSON-basierte Konfiguration mit ColorScheme-Support
- **UI-Skalierung**: Anpassbare Skalierung für verschiedene Bildschirmauflösungen

## ⚙️ Systemvoraussetzungen

- Windows 10/11
- PowerShell 5.1 oder höher
- Administratorrechte
- Mindestens 4 GB RAM
- 100 MB freier Speicherplatz

## 📥 Installation

### Methode 1: Windows Installer (Empfohlen) 🎯
Der einfachste und sicherste Weg für die meisten Nutzer:

1. **Download:** `BockisSystemTool-Setup-v4.1.exe` vom Release
2. **Ausführen:** Installer mit Administratorrechten starten
3. **Automatische Konfiguration:**
   - Erstellt Windows Defender-Ausnahmen
   - Registriert das Tool im System
   - Erstellt Start-Menü und Desktop-Verknüpfungen
   - Richtet Auto-Update ein
4. **Fertig:** Tool über Startmenü oder Desktop starten

**Vorteile:**
- ✅ Automatische Defender-Ausnahmen
- ✅ Saubere Deinstallation möglich
- ✅ Systemweite Installation
- ✅ Windows-Registrierung

### Methode 2: Portable/ZIP 📦
Für erfahrene Nutzer oder portable Installation:

1. **Download:** `Bockis-Win-Gui-v4.1.zip` vom Release
2. **Entpacken:** ZIP-Datei in ein Verzeichnis Ihrer Wahl
3. **Ausnahme hinzufügen:** (Wichtig!) Windows Defender-Ausnahme manuell erstellen
4. **Starten:** `Win_Gui_Module.ps1` mit Administratorrechten:

```powershell
powershell.exe -ExecutionPolicy Bypass -File "Win_Gui_Module.ps1"
```

**Vorteile:**
- ✅ Keine Installation nötig
- ✅ Portable (USB-Stick, Cloud)
- ✅ Mehrere Versionen parallel
- ✅ Volle Kontrolle

**Hinweis:** Bei der Portable-Version müssen Sie Windows Defender-Ausnahmen manuell erstellen. Siehe [DEFENDER-AUSNAHMEN.md](DEFENDER-AUSNAHMEN.md) für Details.

### ⚠️ Windows Defender Warnung

**Problem:** Windows Defender kann LibreHardwareMonitor als "VulnerableDriver:WinNT/Winring0" melden.

**Grund:** Dies ist ein **Fehlalarm (False Positive)**. Der Hardware-Monitoring-Treiber wird fälschlicherweise als Bedrohung erkannt, da er Low-Level-Hardware-Zugriff benötigt (für CPU/GPU-Temperaturen).

**Lösung:** 
- **Installer:** Fügt automatisch Defender-Ausnahmen hinzu ✅
- **Portable/ZIP:** Das Tool versucht beim ersten Start automatisch Ausnahmen hinzuzufügen
- **Manuell:** Falls erforderlich, siehe [DEFENDER-AUSNAHMEN.md](DEFENDER-AUSNAHMEN.md)

**Wichtig:** Ihr System bleibt vollständig geschützt - nur die Tool-Dateien werden als vertrauenswürdig markiert. Der Windows Defender bleibt aktiv!

**Hintergrund:** LibreHardwareMonitor ist ein vertrauenswürdiges Open-Source-Projekt ([GitHub](https://github.com/LibreHardwareMonitor/LibreHardwareMonitor)), das von tausenden Projekten weltweit genutzt wird.

## 📂 Verzeichnisstruktur

```
Bockis-Win_Gui-v4.0/
├── Win_Gui_Module.ps1           # Hauptskript (4485 Zeilen)
├── config.json                  # Benutzer-Einstellungen
├── README.md                    # Diese Datei
├── LICENSE.txt
├── THIRD-PARTY-LICENSES.md
├── Sign-AllScripts.ps1          # Code-Signierung
├── installer.iss                # Inno Setup Installer
│
├── Modules/                     # PowerShell-Module (~15.000 LOC)
│   ├── Core/                    # Kern-Funktionalität
│   │   ├── Core.psm1           # Basis-Funktionen, Symbol-System
│   │   ├── UI.psm1             # UI-Hilfsfunktionen
│   │   ├── Settings.psm1       # Einstellungs-Verwaltung (1584 LOC)
│   │   ├── TextStyle.psm1      # Farb-/Style-System
│   │   ├── LogManager.psm1     # Zentrales Logging mit Cloud-Sync-Support
│   │   └── ProgressBarTools.psm1
│   │
│   ├── Tools/                   # Diagnose-/Reparatur-Tools
│   │   ├── SystemTools.psm1    # MRT, SFC, Memory Diagnostic (1916 LOC)
│   │   ├── DISM-Tools.psm1     # DISM Check/Scan/Repair
│   │   ├── CHKDSKTools.psm1    # Festplatten-Checks
│   │   ├── NetworkTools.psm1   # Netzwerk-Diagnose/-Reparatur
│   │   ├── CleanupTools.psm1   # System-Bereinigung
│   │   ├── DefenderTools.psm1  # Windows Defender Integration
│   │   └── WindowsUpdateTools.psm1  # Update-Management (643 LOC)
│   │
│   ├── Monitor/                 # Hardware-Überwachung
│   │   └── HardwareMonitorTools.psm1  # LibreHardwareMonitor-Integration
│   │
│   ├── ToolLibrary.psm1        # Tool-Download-Verwaltung (1287 LOC)
│   ├── ToolCache.psm1          # Winget-Cache-System (454 LOC)
│   ├── DatabaseManager.psm1    # SQLite-Integration (236 LOC)
│   └── SystemInfo.psm1         # Systeminformationen
│
├── Lib/                         # Native Bibliotheken
│   ├── System.Data.SQLite.dll  # SQLite für .NET
│   ├── LibreHardwareMonitorLib.dll  # Hardware-Monitoring
│   ├── LibreHardwareMonitorLib.sys  # Kernel-Treiber
│   ├── SQLite.cs               # SQLite-Wrapper
│   └── SQLiteAsync.cs          # Async SQLite-Operationen
│
├── Logs/                        # Tool-Ausführungs-Logs
│   └── winget-validation-*.json
│
├── Tools/                       # Utility-Scripts
│   ├── FarbpaletteViewer.ps1   # ColorScheme-Viewer
│   └── Validate-WingetIds.ps1  # Winget-ID-Validator
│
└── _Archive/                    # Alte/Deprecated Dateien
    ├── HardwareInfo.psm1       # DEPRECATED
    ├── ColorScheme.psm1        # DEPRECATED
    ├── UI.psm1.bak
    └── README.md
```

**Statistiken:**
- **Gesamt-LOC**: ~15.000 Zeilen Code
- **Module**: 20 aktive PowerShell-Module
- **Funktionen**: 80+ exportierte Funktionen
- **Tool-Definitionen**: 50+ vordefinierte Tools

## 🚀 Benutzeranleitung

### Erster Start
1. **Automatische Rechte-Prüfung**: Das Tool prüft beim Start automatisch, ob Administratorrechte vorhanden sind
2. **Modul-Loading**: Alle erforderlichen Module werden mit Fortschrittsanzeige geladen
3. **Hardware-Initialisierung**: Die Echtzeit-Hardware-Überwachung startet automatisch
4. **GUI-Anzeige**: Die grafische Benutzeroberfläche öffnet sich mit allen verfügbaren Tools

### Navigation
- **Tab-System**: Die Hauptfunktionen sind in 4 kategorisierte Tabs unterteilt
- **Info-Buttons**: Jeder Tab hat einen Info-Button (ⓘ) mit detaillierten Erklärungen
- **Status-Indikatoren**: Kleine farbige Punkte zeigen den letzten Ausführungsstatus jedes Tools
- **Ausgabe-Bereich**: Der untere Bereich zeigt Live-Ausgaben und System-Informationen

### Tool-Ausführung
1. **Tool auswählen**: Klicken Sie auf den gewünschten Button
2. **Automatischer Tab-Wechsel**: Die GUI wechselt automatisch zum Ausgabe-Tab
3. **Live-Verfolgung**: Verfolgen Sie den Fortschritt in Echtzeit
4. **Status-Updates**: Die Fortschrittsleiste zeigt den aktuellen Status
5. **Ergebnis-Anzeige**: Detaillierte Ergebnisse werden in der Ausgabe angezeigt

### Hardware-Monitoring
- **CPU**: Zeigt Auslastung, Temperatur und Taktfrequenz
- **RAM**: Zeigt Speichernutzung und verfügbaren Speicher
- **GPU**: Zeigt Grafikkarten-Auslastung und Temperatur
- **Tooltips**: Bewegen Sie die Maus über die Hardware-Boxen für Details

### Erweiterte Funktionen
- **Scan-Historie**: Tooltips auf Status-Indikatoren zeigen Zeitstempel des letzten Scans
- **Datenbank**: Alle Aktivitäten werden automatisch protokolliert
- **Einstellungen**: Werden automatisch gespeichert und beim nächsten Start geladen
- **Fenster-Management**: Position und Größe werden automatisch gespeichert

## 🎯 Funktionsübersicht

### System & Sicherheit
- **Malware-Erkennung und -Entfernung**: MRT Quick/Full Scans
- **Windows Defender Integration**: Vollständige Antivirus-Kontrolle
- **Offline-Sicherheitsscans**: Bootfähige Malware-Erkennung
- **Systemdatei-Überprüfung**: SFC-basierte Integritätsprüfung
- **Automatische Update-Verwaltung**: Windows Update mit Fortschrittsanzeige

### Diagnose & Reparatur
- **Hardware-Diagnose**: Memory Diagnostic für RAM-Tests
- **Festplatten-Management**: CHKDSK mit Laufwerksauswahl
- **Windows-Image-Reparatur**: Komplette DISM-Suite
- **Systemdatei-Wiederherstellung**: Automatische Reparatur beschädigter Dateien

### Netzwerk-Tools
- **Umfassende Verbindungstests**: Multi-Server Ping-Tests
- **Netzwerk-Troubleshooting**: Adapter-Reset und Konfiguration
- **Verbindungsdiagnose**: Detaillierte Netzwerkanalyse

### Bereinigung & Optimierung
- **Intelligente Systemreinigung**: Windows Disk Cleanup Integration
- **Erweiterte Bereinigung**: Custom-Cleanup mit anpassbaren Optionen
- **Speicherplatz-Optimierung**: Freigabe ungenutzten Speichers

## 🎨 Benutzeroberfläche

### Design-Highlights
- **Modernes Dunkles Theme**: Ähnlich UniGetUI mit anpassbaren ColorSchemes
- **Borderless Window**: Custom Title Bar mit Drag-Support
- **Collapsible Navigation**: Aufklappbare Menü-Panels für kompakte Darstellung
- **WPF-Integration**: Moderne ScrollViewer und WrapPanel-Komponenten
- **Responsive Layout**: Automatische Anpassung an verschiedene Bildschirmgrößen
- **UI-Skalierung**: Konfigurierbare Skalierung (0.8x - 1.5x)

### Layout-Struktur
```
┌─────────────────────────────────────────────────────────┐
│ [Bocki's System-Tool 4.0]       [Console ►] [━] [□] [X] │ ← Custom Title Bar
├────────────┬────────────────────────────────────────────┤
│            │                                             │
│ ▼ System   │  ┌──────────────────────────────────────┐  │
│   • Sicher │  │ [Output RichTextBox]                 │  │
│   • Wartung│  │ Farbcodierte Ausgabe mit Symbolen    │  │
│            │  │ [√] [X] [!] [►] [+]                  │  │
│ ▼ Diagnose │  └──────────────────────────────────────┘  │
│   • DISM   │                                             │
│   • CHKDSK │  ┌─────┬─────┬─────┐                      │
│            │  │ CPU │ GPU │ RAM │  Hardware-Monitor     │
│ ▼ Netzwerk │  │ 45% │ 32% │ 8GB │  (Live-Update)        │
│   • Diagn. │  └─────┴─────┴─────┘                      │
│   • Repair │                                             │
│            │  ┌───────────────────────────────────────┐ │
│ ▼ Bereinig │  │ [Button Grid 3x3]                    │ │
│   • System │  │ [MRT] [SFC] [Defender]               │ │
│            │  │ [DISM] [CHKDSK] [WinUpdate]          │ │
│ ▼ Tools ▼  │  └───────────────────────────────────────┘ │
│   • Alle   │                                             │
│   • System │  ┌─ Tool-Downloads ────────────────────┐  │
│   • Browser│  │ [Search: _______]                   │  │
│   • Gaming │  │ ┌───────┬───────┬───────┐           │  │
│   • Dev    │  │ │ ╬ CPU-Z│ ╬ 7Zip│ ╬ VLC │ (WPF)    │  │
│   • Office │  │ │Install │Install │Inst. │ Kacheln  │  │
└────────────┴──│ └───────┴───────┴───────┘           │  │
               │ Smooth Scrolling mit WPF              │  │
               └───────────────────────────────────────┘  │
                                                           │
└──────────────────────────────────────────────────────────┘
```

### Interaktive Elemente
- **Status-Indikatoren**: Farbige Punkte (Grün/Rot/Gelb) für Tool-Status
- **Tooltips**: Kontext-Hilfe mit Zeitstempel der letzten Ausführung
- **Hover-Effekte**: Buttons ändern Farbe bei Maus-Over
- **Progress-Bar**: Integrierte Fortschrittsanzeige für langläufige Operationen
- **Rich-Text-Output**: Farbcodierte Ausgabe mit verschiedenen Styles
- **Keyboard-Shortcuts**: F12 für Console-Toggle

### ColorScheme-System
Das Tool unterstützt benutzerdefinierte Farbschemata via `config.json`:
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

## ⚠️ Wichtige Hinweise & Sicherheit

### Vor der Nutzung
- **Administratorrechte erforderlich**: Das Tool benötigt zwingend erhöhte Rechte für Systemoperationen
- **Systemwiederherstellungspunkt erstellen**: Wird vor kritischen Operationen automatisch erstellt
- **Offene Dokumente speichern**: Einige Tools erfordern möglicherweise einen Neustart
- **Antivirus-Software**: Temporäre Deaktivierung kann bei einigen Scans erforderlich sein

### Während der Nutzung
- **Tools nicht gleichzeitig ausführen**: Vermeiden Sie parallele System-Scans
- **Internetverbindung**: Erforderlich für Windows Update und Malware-Definitionen
- **Ausreichend Speicherplatz**: Mindestens 1 GB frei für temporäre Dateien
- **Geduld bei längeren Scans**: Vollständige Scans können mehrere Stunden dauern

### Nach der Nutzung
- **Log-Dateien prüfen**: Überprüfen Sie die Scan-Ergebnisse im `Logs/`-Verzeichnis
- **System-Neustart**: Bei DISM-Reparaturen oder Memory Diagnostic empfohlen
- **Backup aktualisieren**: Nach wichtigen Systemreparaturen

### Automatische Sicherheitsfeatures
- **Vollständige Protokollierung**: Alle Aktivitäten werden in SQLite-Datenbank gespeichert
- **Fehler-Recovery**: Automatische Wiederherstellung bei unterbrochenen Operationen
- **Status-Tracking**: Nachverfolgung aller durchgeführten Scans und Reparaturen
- **Sichere Beendigung**: Kontrolliertes Schließen aller Prozesse und Verbindungen

## 🛠️ Fehlerbehebung

Bei Problemen:
1. Stellen Sie sicher, dass Sie Administratorrechte haben
2. Überprüfen Sie die PowerShell-Version
3. Prüfen Sie die Ereignisanzeige auf Fehler
4. Kontaktieren Sie den Support

## 📋 Changelog

### Version 4.0 (28. November 2025) - Aktuell
- 🚀 **WPF-Integration**: Moderne UI-Komponenten (ScrollViewer, WrapPanel) für Tool-Downloads
- 🔽 **Tool-Download-System**: 50+ vordefinierte Tools mit Winget-Integration
- 🎯 **Intelligenter Cache**: ToolCache-System reduziert Winget-Aufrufe (5-15 Min)
- 📦 **Collapsible Panels**: Aufklappbare Navigation für kompakte Darstellung
- 🎨 **Borderless Window**: Custom Title Bar mit Drag-Support
- 🖱️ **Tool-Kacheln**: WPF-basierte Kachel-Darstellung mit Installations-Status
- 🔍 **Such-Funktion**: Filter für Tools nach Name, Kategorie oder Tags
- 🗄️ **HardwareHistory-Datenbank**: Automatische Speicherung aller Sensor-Werte
- 🐛 **Cloud-Sync-Kompatibilität**: Intelligente Fehlerbehandlung für Nextcloud/OneDrive
- ⚡ **Performance**: Lazy-Loading für Tool-Downloads, optimierte Module-Imports
- 📊 **Debug-Modi**: Erweiterte Hardware-Diagnose für CPU/GPU/RAM
- ⌨️ **F12-Shortcut**: PowerShell-Konsole ein-/ausblenden während der Laufzeit
- 🎛️ **UI-Skalierung**: Anpassbare Skalierung für verschiedene Bildschirmauflösungen
- 📝 **Modulares Logging**: Zentrale Logs in `%LOCALAPPDATA%\BockisSystemTool\Logs`
- 🔧 **Code-Refactoring**: Aufgeräumte Module-Struktur, 20 aktive Module

### Version 3.1
- 🎨 **Komplette UI-Überarbeitung**: Moderne, kategorisierte Tab-Navigation
- 📊 **Erweiterte Hardware-Überwachung**: Echtzeit-Monitoring von CPU, GPU, RAM
- 🗄️ **SQLite-Datenbank-Integration**: Vollständige Protokollierung aller Aktivitäten
- 🎯 **Status-Indikatoren**: Visuelle Anzeige des letzten Tool-Status mit Tooltips
- 🔧 **DISM-Tool-Suite**: Komplette Windows-Image-Reparatur-Funktionalität
- 🛡️ **Windows Defender Integration**: Direktzugriff auf alle Defender-Funktionen
- 🌐 **Erweiterte Netzwerk-Tools**: Umfassende Ping-Tests und Adapter-Reset
- 🧹 **Custom-Cleanup**: Anpassbare Systemreinigung mit erweiterten Optionen
- ⚡ **Performance-Optimierungen**: Verbesserte Modul-Ladezeiten
- 🔐 **Verbesserte Sicherheit**: Automatische Rechte-Prüfung und sichere Beendigung

### Version 3.0
- 🆕 **Neue grafische Benutzeroberfläche**: Vollständiger Rewrite der GUI
- 📱 **Hardware-Monitor hinzugefügt**: Erste Version der Hardware-Überwachung
- 🔧 **Verbesserte Systemdiagnose**: Erweiterte DISM- und CHKDSK-Integration
- 🌙 **Dark Mode implementiert**: Erste Implementierung verschiedener Themes

### Version 2.x
- 🏗️ **Modulare Architektur**: Aufbau der PowerShell-Modul-Struktur
- 🛠️ **Grundlegende System-Tools**: Implementierung der Core-Funktionalitäten

## 👥 Support

Bei Fragen oder Problemen:
- Erstellen Sie ein Issue
- Kontaktieren Sie den Support
- Konsultieren Sie die Dokumentation

## 📄 Lizenz

Dieses Tool ist unter der MIT-Lizenz veröffentlicht. Siehe [LICENSE.txt](LICENSE.txt) für Details.

### Drittanbieter-Lizenzen
Dieses Projekt verwendet verschiedene Drittanbieter-Bibliotheken. Details siehe [THIRD-PARTY-LICENSES.md](THIRD-PARTY-LICENSES.md).

## 🔧 Technische Details

### Architektur
- **Hauptskript**: `Win_Gui_Module.ps1` (4485 Zeilen)
- **Module**: 20 aktive PowerShell-Module (~15.000 LOC)
- **UI-Framework**: Windows Forms + WPF-Integration
- **Datenbank**: SQLite 3 via System.Data.SQLite.dll
- **Hardware-Monitoring**: LibreHardwareMonitor
- **Package-Manager**: Winget-Integration

### Performance-Optimierungen
- **Cache-System**: MemoryCache für Winget-Abfragen (5-15 Min TTL)
- **Lazy-Loading**: Tool-Downloads werden nur bei Bedarf geladen
- **Timer-basiert**: Hardware-Updates erfolgen asynchron (1s Intervall)
- **Assembly-Caching**: Einmalige Assembly-Ladung beim Start
- **Retry-Mechanismus**: Exponential backoff bei Datei-Zugriffs-Konflikten

### Bekannte Einschränkungen
- Einige Tools erfordern Neustart (Memory Diagnostic, CHKDSK)
- Hardware-Monitoring benötigt Kernel-Treiber (LibreHardwareMonitorLib.sys)
- Winget muss installiert sein für Tool-Download-Feature
- Windows Defender kann das Tool als "Trojan:Win32/Vigorf.A" melden (Fehlalarm)

## � Changelog

### Version 4.1 (18. Dezember 2025) - AKTUELL
**🎉 Hauptfeatures:**
- 🔄 **Auto-Update-System**: Automatische Update-Prüfung und Installation über GitHub Releases
- 📦 **Tool-Download-Manager**: 50+ Tools direkt aus der GUI installierbar via Winget
- 🏗️ **Modulare Architektur**: Vollständig refaktorierte Codebasis mit separaten Modulen
- 🎨 **UI-Verbesserungen**: Optimierte Button-Layouts und Positionierung
- ⚡ **Performance-Optimierungen**: Tool-Cache-System für schnellere Ladezeiten

**Neue Funktionen:**
- Integrierter "Update"-Button in der Hauptoberfläche
- GitHub API-Integration für Release-Management
- Automatischer Download und Installation von Updates
- Kategorisierte Tool-Bibliothek (System, Apps, Audio/TV, Coding)
- Such- und Filterfunktion für Tool-Downloads
- Verbesserte Progressbar mit detailliertem Status
- Tool-Installation-Tracking und Status-Anzeige

**Verbesserungen:**
- Button-Positionierung optimiert (Update-Button rechts neben Progressbar)
- Modulstruktur erweitert (ToolLibrary, ToolCache)
- Bessere Fehlerbehandlung bei Updates
- Optimierte Speicherverwaltung
- Verbesserte Code-Organisation

**Bugfixes:**
- Fensterpositionierung korrigiert
- Modul-Ladezeiten optimiert
- GUI-Rendering verbessert

**⚠️ Wichtig für Upgrade von v4.0:**
Dies ist das letzte manuelle Update! Nach Installation von v4.1 erfolgen alle zukünftigen Updates automatisch.

### Version 4.0 (November 2025)
**Hauptfeatures:**
- Vollständige UI-Überarbeitung mit moderner WPF-Integration
- LibreHardwareMonitor-Integration für detailliertes Hardware-Monitoring
- SQLite-Datenbank für Tool-Ausführungs-Logs
- Tool-Download-System Basis-Implementation
- Modulare Code-Architektur

**Neue Funktionen:**
- Echtzeit-Hardware-Überwachung (CPU, RAM, GPU)
- Status-Indikatoren für alle System-Tools
- Scan-Historie mit Zeitstempeln
- Erweiterte DISM-Tool-Suite
- Custom-Cleanup-Optionen
- Automatische Settings-Persistenz

### Version 3.1
- Tab-basierte Navigation
- Basis Hardware-Monitoring
- Erste Modul-Implementierungen
- SQLite-Integration

### Version 3.0
- Grafische Benutzeroberfläche
- Grundlegende System-Tools
- Windows Forms-basiert

## 🔍 FAQ

**Q: Warum meldet Windows Defender das Tool als Malware?**  
A: Dies ist ein Fehlalarm (False Positive). Das Tool verwendet Windows-APIs zur Fenstersteuerung, die manchmal von Malware missbraucht werden. Der Code ist vollständig transparent und Open Source.

**Q: Wie funktioniert das Auto-Update?**  
A: Das Tool prüft über die GitHub API auf neue Releases, lädt das ZIP-Asset herunter, entpackt es automatisch und startet die Anwendung neu. Keine manuelle Interaktion nötig!

**Q: Benötige ich Administratorrechte?**  
A: Ja, die meisten System-Diagnose- und Reparatur-Tools erfordern erhöhte Rechte. Das Tool fordert diese automatisch beim Start an.

**Q: Werden meine Daten gesammelt?**  
A: Nein. Alle Daten werden lokal in SQLite-Datenbank gespeichert. Es erfolgt keine Datenübertragung ins Internet (außer für Windows Update, GitHub-Updates und Tool-Downloads).

**Q: Kann ich eigene Tools hinzufügen?**  
A: Ja, über `ToolLibrary.psm1` können Sie die `$script:toolLibrary`-Hashtable erweitern.

**Q: Wo finde ich die Logs?**  
A: Logs werden in `%LOCALAPPDATA%\BockisSystemTool\Logs\` gespeichert.

**Q: Funktioniert das Tool mit Nextcloud/OneDrive?**  
A: Ja, das Tool hat spezielle Fehlerbehandlung für Cloud-Sync-Provider implementiert.

**Q: Warum sind manche Tools nicht verfügbar?**  
A: Einige Tools im Download-Manager benötigen Winget. Stellen Sie sicher, dass Windows Package Manager installiert ist.

## 🙏 Danksagungen

- **LibreHardwareMonitor** - Exzellente Hardware-Monitoring-Bibliothek
- **SQLite-NET** - Robuste Datenbank-Integration
- **PowerShell-Community** - Unzählige hilfreiche Ressourcen
- **Microsoft** - Winget Package Manager
- **GitHub** - Release-Management und Hosting
- **Alle Beta-Tester** - Wertvolles Feedback und Bug-Reports

## 🤝 Mitwirken

Beiträge sind willkommen! Bitte:
1. Forken Sie das Repository
2. Erstellen Sie einen Feature-Branch (`git checkout -b feature/AmazingFeature`)
3. Committen Sie Ihre Änderungen (`git commit -m 'Add some AmazingFeature'`)
4. Pushen Sie zum Branch (`git push origin feature/AmazingFeature`)
5. Öffnen Sie einen Pull Request

---

**Entwickelt mit ❤️ von Bocki**  
*Version 4.1 - Dezember 2025*
# Windows System-Tool GUI 3.1

Ein leistungsfähiges PowerShell-basiertes Verwaltungstool mit grafischer Benutzeroberfläche für Windows-Systeme.

## 🔑 Hauptfunktionen

Das Bockis System-Tool bietet eine umfassende Sammlung von Windows-Systemtools in einer benutzerfreundlichen grafischen Oberfläche:

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
- **Echtzeit-Hardware-Überwachung**:
  - CPU-Auslastung und Temperatur
  - RAM-Nutzung und verfügbarer Speicher
  - GPU-Status und -Auslastung
- **Hardware-Info-Tab**: Detaillierte Informationen über:
  - Prozessor-Spezifikationen (Kerne, Takt, Cache)
  - Arbeitsspeicher-Module und -Kapazität
  - Grafikkarten und Video-RAM
  - Festplatten und logische Laufwerke
  - Netzwerkadapter und IP-Konfiguration
  - Betriebssystem-Details
- **Status-Info**: Umfassende Systemstatusübersicht mit Live-Updates

### 🗄️ Erweiterte Funktionen
- **SQLite-Datenbank-Integration**: Automatische Protokollierung aller Tool-Ausführungen
- **Status-Indikatoren**: Visuelle Anzeige des letzten Ausführungsstatus für jeden Button
- **Scan-Historie**: Zeitstempel und Verlaufsverfolgung aller durchgeführten Systemscans
- **Erweiterte Benutzeroberfläche**: 
  - Kategorisierte Tab-Navigation
  - Farbkodierte Tool-Gruppen
  - Tooltips und Hilfetexte
  - Automatisches Fenster-Management

## ⚙️ Systemvoraussetzungen

- Windows 10/11
- PowerShell 5.1 oder höher
- Administratorrechte
- Mindestens 4 GB RAM
- 100 MB freier Speicherplatz

## 📥 Installation

1. Laden Sie das Tool herunter
2. Entpacken Sie die ZIP-Datei in ein Verzeichnis Ihrer Wahl
3. Starten Sie `Win_Gui_Module.ps1` mit Administratorrechten:

```powershell
powershell.exe -ExecutionPolicy Bypass -File "Win_Gui_Module.ps1"
```

## 📂 Verzeichnisstruktur

```
Bockis-Win_Gui/
├── Modules/
│   ├── Core/
│   │   ├── Core.psm1
│   │   ├── UI.psm1
│   │   ├── ProgressBarTools.psm1
│   │   └── Settings.psm1
│   ├── Monitor/
│   │   └── HardwareMonitorTools.psm1
│   ├── Tools/
│   │   ├── SystemTools.psm1
│   │   ├── DISM-Tools.psm1
│   │   ├── CHKDSKTools.psm1
│   │   ├── NetworkTools.psm1
│   │   ├── CleanupTools.psm1
│   │   ├── DefenderTools.psm1
│   │   └── WindowsUpdateTools.psm1
│   ├── DatabaseManager.psm1
│   ├── SystemInfo.psm1
│   ├── HardwareInfo.psm1
│   └── ToolLibrary.psm1
├── Lib/
│   ├── HidSharp.dll
│   ├── iCUESDK.x64_2019.dll
│   ├── LibHardwareMonitor.dll
│   ├── LibreHardwareMonitorLib.dll
│   ├── LibreHardwareMonitorLib.sys
│   └── System.Data.SQLite.dll
├── Win_Gui_Module.ps1
├── config.json
└── README.md
```

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

- Modernes, übersichtliches Design
- Hell-/Dunkel-Modus
- Tab-basierte Navigation
- Fortschrittsanzeige mit integriertem Status
- Detaillierte Statusmeldungen
- Echtzeit-Hardware-Überwachung

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

### Version 3.1 (Aktuell)
- 🎨 **Komplette UI-Überarbeitung**: Moderne, kategorisierte Tab-Navigation
- 📊 **Erweiterte Hardware-Überwachung**: Echtzeit-Monitoring von CPU, GPU, RAM
- 🗄️ **SQLite-Datenbank-Integration**: Vollständige Protokollierung aller Aktivitäten
- 🎯 **Status-Indikatoren**: Visuelle Anzeige des letzten Tool-Status mit Tooltips
- 🔧 **DISM-Tool-Suite**: Komplette Windows-Image-Reparatur-Funktionalität
- 🛡️ **Windows Defender Integration**: Direktzugriff auf alle Defender-Funktionen
- 🌐 **Erweiterte Netzwerk-Tools**: Umfassende Ping-Tests und Adapter-Reset
- 🧹 **Custom-Cleanup**: Anpassbare Systemreinigung mit erweiterten Optionen
- ⚡ **Performance-Optimierungen**: Verbesserte Modul-Ladezeiten und Speicherverwaltung
- 🔐 **Verbesserte Sicherheit**: Automatische Rechte-Prüfung und sichere Beendigung
- 📈 **Fortschrittsanzeige**: Detaillierte Status-Updates mit integrierter ProgressBar
- 💾 **Einstellungen-Persistenz**: Automatisches Speichern von Fensterposition und Konfiguration

### Version 3.0.0
- 🆕 **Neue grafische Benutzeroberfläche**: Vollständiger Rewrite der GUI
- 📱 **Hardware-Monitor hinzugefügt**: Erste Version der Hardware-Überwachung
- 🔧 **Verbesserte Systemdiagnose**: Erweiterte DISM- und CHKDSK-Integration
- 🌙 **Dark Mode implementiert**: Erste Implementierung verschiedener Themes
- 📊 **Basis-Protokollierung**: Grundlegende Log-Funktionalität

### Version 2.x
- 🏗️ **Modulare Architektur**: Aufbau der PowerShell-Modul-Struktur
- 🛠️ **Grundlegende System-Tools**: Implementierung der Core-Funktionalitäten
- 📝 **Erste GUI-Version**: Windows Forms-basierte Benutzeroberfläche

## 👥 Support

Bei Fragen oder Problemen:
- Erstellen Sie ein Issue
- Kontaktieren Sie den Support
- Konsultieren Sie die Dokumentation

## 📄 Lizenz

Dieses Tool ist unter der MIT-Lizenz veröffentlicht. Siehe [LICENSE.txt](LICENSE.txt) für Details.

### Drittanbieter-Lizenzen
Dieses Projekt verwendet verschiedene Drittanbieter-Bibliotheken. Details siehe [THIRD-PARTY-LICENSES.md](THIRD-PARTY-LICENSES.md).

**Wichtiger Hinweis:** Einige optionale Funktionen benötigen proprietäre Software:
- Corsair iCUE SDK (für Corsair-Hardware)
- HidSharp (für HID-Geräte)

Diese müssen separat installiert werden und sind nicht im Repository enthalten.

## 🙏 Danksagungen

- LibreHardwareMonitor für Hardware-Monitoring
- PowerShell-Community
- Alle Mitwirkenden und Tester

---

*Entwickelt von Bocki*
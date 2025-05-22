# Windows System-Tool GUI 3.1

Ein leistungsfähiges PowerShell-basiertes Verwaltungstool mit grafischer Benutzeroberfläche für Windows-Systeme.

## 🔑 Hauptfunktionen

### 🛡️ System & Sicherheit
- **MRT Quick Scan**: Schnelle Malware-Erkennung
- **MRT Full Scan**: Vollständige Systemprüfung
- **Windows Defender**: Direktzugriff auf Sicherheitseinstellungen
- **SFC Check**: Überprüfung der Windows-Systemdateien
- **Windows Update**: Update-Verwaltung

### 💽 Diagnose & Reparatur
- **Memory Diagnostic**: Arbeitsspeicher-Test
- **CHKDSK**: Festplattendiagnose
- **DISM-Tools**:
  - Check Health
  - Scan Health
  - Restore Health

### 🌐 Netzwerk-Tools
- **Ping Test**: Netzwerkverbindungsprüfung
- **Netzwerk zurücksetzen**: Behebung von Netzwerkproblemen

### 🧹 Bereinigung
- **Disk Cleanup**: Systembereinigung
- **Temporäre Dateien**: Verwaltung temporärer Dateien

### 📊 Hardware-Monitor
- Echtzeit-Überwachung von:
  - CPU (Auslastung & Temperatur)
  - RAM-Nutzung
  - GPU-Status
  - Mainboard-Sensoren

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

## 🎯 Funktionsübersicht

### System & Sicherheit
- Malware-Erkennung und -Entfernung
- Windows Defender Integration
- Systemdatei-Überprüfung
- Windows Update-Verwaltung

### Diagnose & Reparatur
- Arbeitsspeicher-Diagnose
- Festplatten-Überprüfung
- Windows-Image-Reparatur
- Systemdatei-Wiederherstellung

### Netzwerk-Tools
- Verbindungstest und -Diagnose
- Netzwerk-Reset-Funktionen
- Netzwerkadapter-Verwaltung

### Bereinigung
- Systemreinigung
- Temporäre Dateien-Verwaltung
- Cache-Bereinigung

### Hardware-Monitor
- CPU-Überwachung
- RAM-Auslastung
- GPU-Status
- Temperatur-Monitoring

## 🎨 Benutzeroberfläche

- Modernes, übersichtliches Design
- Hell-/Dunkel-Modus
- Tab-basierte Navigation
- Fortschrittsanzeige mit integriertem Status
- Detaillierte Statusmeldungen
- Echtzeit-Hardware-Überwachung

## ⚠️ Wichtige Hinweise

- Das Tool benötigt Administratorrechte
- Systemänderungen werden protokolliert
- Automatische Backups vor kritischen Operationen
- Wiederherstellungspunkte werden erstellt

## 🛠️ Fehlerbehebung

Bei Problemen:
1. Stellen Sie sicher, dass Sie Administratorrechte haben
2. Überprüfen Sie die PowerShell-Version
3. Prüfen Sie die Ereignisanzeige auf Fehler
4. Kontaktieren Sie den Support

## 📋 Changelog

### Version 3.1
- Verbesserte Benutzeroberfläche
- Optimierter Hardware-Monitor
- Erweiterte Systemdiagnose
- Verbesserte Schließroutine
- Bug-Fixes und Stabilitätsverbesserungen

### Version 3.0.0
- Neue Benutzeroberfläche
- Hardware-Monitor hinzugefügt
- Verbesserte Systemdiagnose
- Dark Mode implementiert

## 👥 Support

Bei Fragen oder Problemen:
- Erstellen Sie ein Issue
- Kontaktieren Sie den Support
- Konsultieren Sie die Dokumentation

## 📄 Lizenz

Dieses Tool ist unter der MIT-Lizenz veröffentlicht.

## 🙏 Danksagungen

- LibreHardwareMonitor für Hardware-Monitoring
- PowerShell-Community
- Alle Mitwirkenden und Tester

---

*Entwickelt von Bocki*
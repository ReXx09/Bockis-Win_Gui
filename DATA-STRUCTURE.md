# Datenstruktur der Bockis System-Tool GUI

## 📁 Zentrale Datenverwaltung

**Stand:** Version 4.1.1+  
**Änderung:** Alle Anwendungsdaten werden jetzt **zentral im Installationsverzeichnis** gespeichert.

---

## 🎯 Warum diese Änderung?

### **Vorher** ❌
- Daten verstreut über das gesamte System
- `%LOCALAPPDATA%\BockisSystemTool\` - Datenbank & Logs
- `%TEMP%\ToolDownloads\` - Tool-Downloads
- `%TEMP%\*` - Verschiedene temporäre Dateien
- **Problem:** Deinstallation hinterlässt Dateien

### **Jetzt** ✅
- **Alle Daten** in einem Ordner: `C:\Program Files\Bockis-Win_Gui\Data\`
- Einfache Deinstallation - nur ein Verzeichnis löschen
- Bessere Übersicht für den Benutzer
- Portablere Lösung

---

## 📂 Neue Ordnerstruktur

```
C:\Program Files\Bockis-Win_Gui\
│
├── Win_Gui_Module.ps1          # Hauptanwendung
├── Modules\                     # PowerShell-Module
├── Lib\                         # C#-Bibliotheken
├── IMG_0382.ico                 # Icon
├── Logo.bmp                     # Logo
├── config.json                  # Konfiguration
├── README.md                    # Dokumentation
│
└── Data\                        # ⭐ ALLE ANWENDUNGSDATEN HIER
    ├── Database\                # SQLite-Datenbank
    │   └── system_data.db       # Tool-Historie, Diagnosen
    │
    ├── Logs\                    # Alle Log-Dateien
    │   ├── BockisSystemTool.log # Haupt-Log
    │   ├── QuickMRT.log         # MRT Quick Scan Logs
    │   ├── FullMRT.log          # MRT Full Scan Logs
    │   └── SFCCheck.log         # SFC-Prüfungs-Logs
    │
    ├── ToolDownloads\           # Heruntergeladene Tools
    │   ├── SysinternalsSuite\
    │   ├── WinDirStat\
    │   └── ...                  # Weitere Tools
    │
    └── Temp\                    # Temporäre Dateien
        ├── cleanup_log.txt      # Bereinigungsprotokoll
        ├── skipped_files.txt    # Übersprungene Dateien
        ├── dism_*.json          # DISM-Ergebnisse
        ├── dism_*.log           # DISM-Logs
        ├── MpCmdRun.log         # Defender-Logs
        ├── mrt_*.log            # MRT-Backups
        ├── memory_diagnostic_marker.txt
        └── MRTTest\             # MRT-Test-Verzeichnis
```

---

## 🔄 Betroffene Module

### **DatabaseManager.psm1**
```powershell
# Vorher:
$dbPath = Join-Path $env:LOCALAPPDATA "BockisSystemTool\Database\system_data.db"

# Jetzt:
$dbPath = Join-Path $PSScriptRoot "..\Data\Database\system_data.db"
```

### **LogManager.psm1**
```powershell
# Vorher:
$script:logDirectory = Join-Path $env:LOCALAPPDATA "BockisSystemTool\Logs"

# Jetzt:
$script:logDirectory = Join-Path $PSScriptRoot "..\..\Data\Logs"
```

### **Settings.psm1**
```powershell
# Standard-Pfade zeigen jetzt alle auf Data-Ordner:
DatabasePath = Join-Path $PSScriptRoot "..\..\Data\Database"
LogPath      = Join-Path $PSScriptRoot "..\..\Data\Logs"
```

### **ToolLibrary.psm1**
```powershell
# Vorher:
[string]$DownloadPath = "$env:TEMP\ToolDownloads"

# Jetzt:
[string]$DownloadPath = (Join-Path $PSScriptRoot "..\Data\ToolDownloads")
```

### **SystemTools.psm1**
Alle temporären Dateien:
- MRT Backup-Logs → `Data\Temp\mrt_*.log`
- Memory Diagnostic Marker → `Data\Temp\memory_diagnostic_marker.txt`
- MRT Test-Verzeichnis → `Data\Temp\MRTTest\`

### **DISM-Tools.psm1**
```powershell
# DISM Logs & Ergebnisse:
$logPath    = Join-Path $PSScriptRoot "..\..\Data\Temp\dism_scan.log"
$resultPath = Join-Path $PSScriptRoot "..\..\Data\Temp\dism_scan_result.json"
```

### **CleanupTools.psm1**
```powershell
# Cleanup-Protokolle:
$logFilePath     = Join-Path $PSScriptRoot "..\..\Data\Temp\cleanup_log.txt"
$skippedFilePath = Join-Path $PSScriptRoot "..\..\Data\Temp\skipped_files.txt"
```

### **DefenderTools.psm1**
```powershell
# Defender-Logs:
$logPath = Join-Path $PSScriptRoot "..\..\Data\Temp\MpCmdRun.log"
```

---

## 🗑️ Deinstallation

### **Vorher** (kompliziert)
```pascal
[UninstallRun]
Filename: "powershell.exe"; 
Parameters: "-Command ""Remove-Item -Path '{localappdata}\BockisSystemTool' -Recurse -Force""";

Filename: "powershell.exe"; 
Parameters: "-Command ""Remove-Item -Path '$env:TEMP\BockisSystemTool*' -Recurse -Force""";
```

### **Jetzt** (einfach)
```pascal
[UninstallDelete]
Type: filesandordirs; Name: "{app}\Data"
```

**Das war's!** Der Deinstaller löscht einfach das Installations-Verzeichnis und **alles ist weg** ✨

---

## ⚙️ Migration von alten Versionen

Alte Versionen (< 4.1.1) haben Daten in:
- `%LOCALAPPDATA%\BockisSystemTool\`
- `%TEMP%\ToolDownloads\`

### Automatische Migration

Die neue Version **erkennt** diese alten Pfade **nicht automatisch**. 

**Empfehlung für Benutzer:**
1. Deinstalliere die alte Version
2. Lösche manuell (optional):
   - `%LOCALAPPDATA%\BockisSystemTool\`
   - `%TEMP%\ToolDownloads\`
3. Installiere die neue Version

Alle Daten werden dann frisch im neuen Verzeichnis angelegt.

---

## 🔒 Berechtigungen

Der `Data`-Ordner wird mit **users-modify** Berechtigungen erstellt:
```pascal
[Dirs]
Name: "{app}\Data"; Permissions: users-modify
```

Dies erlaubt der Anwendung:
- ✅ Datenbank schreiben
- ✅ Logs erstellen
- ✅ Tools herunterladen
- ✅ Temp-Dateien erstellen

**Auch ohne Admin-Rechte beim Ausführen** (für nicht-privilegierte Funktionen).

---

## 📊 Vorteile der neuen Struktur

| Vorteil | Beschreibung |
|---------|--------------|
| **🧹 Saubere Deinstallation** | Löscht garantiert **alle** Dateien |
| **📁 Übersichtlich** | Alle Daten an einem Ort |
| **🚚 Portabel** | Gesamter `Data`-Ordner kann gesichert/kopiert werden |
| **🔍 Transparent** | Benutzer sieht alle gespeicherten Daten |
| **🛡️ Datenschutz** | Keine versteckten Daten in AppData |
| **💾 Backup** | Ein Ordner = komplettes Backup |

---

## 🧪 Tests

Teste die neue Struktur mit:
```powershell
# 1. Prüfe ob Ordner existieren
Test-Path "C:\Program Files\Bockis-Win_Gui\Data\Database"
Test-Path "C:\Program Files\Bockis-Win_Gui\Data\Logs"
Test-Path "C:\Program Files\Bockis-Win_Gui\Data\ToolDownloads"
Test-Path "C:\Program Files\Bockis-Win_Gui\Data\Temp"

# 2. Starte die GUI und prüfe ob Logs erstellt werden
Get-ChildItem "C:\Program Files\Bockis-Win_Gui\Data\Logs"

# 3. Lade ein Tool herunter und prüfe ToolDownloads
Get-ChildItem "C:\Program Files\Bockis-Win_Gui\Data\ToolDownloads"

# 4. Prüfe Datenbank
Get-ChildItem "C:\Program Files\Bockis-Win_Gui\Data\Database"
```

---

## 📝 Changelog

### Version 4.1.1+
- ✅ Alle Datenpfade zentralisiert in `Data\` Ordner
- ✅ Deinstallation vereinfacht
- ✅ Keine verstreuten Dateien mehr im System
- ✅ Bessere Portabilität und Übersicht

---

**Autor:** Bockis  
**Datum:** 21. Januar 2026  
**Version:** 4.1.1+

# Bockis System-Tool: AI Coding Agent Instructions

## Project Overview

**Bockis System-Tool v4.1.2** ist ein umfassendes PowerShell-basiertes Windows-Systemwartungs-Tool mit moderner WPF-GUI (~15.000 LOC). Es kombiniert Diagnose-, Reparatur- und Überwachungsfunktionen in einer benutzerfreundlichen Oberfläche mit LibreHardwareMonitor-Integration, SQLite-Datenbank und Winget-Paketmanagement.

**Ziel**: Admin-freundliches Tool für Windows 10/11 Systemwartung, Malware-Scans, Hardware-Monitoring und Software-Installation.

## Architektur & Komponenten

### Einstiegspunkt und Initialisierung
- **[Win_Gui_Module.ps1](Win_Gui_Module.ps1)** (5424 LOC): Hauptskript - lädt Module, erstellt WPF-GUI, initialisiert Hardware-Monitoring
  - Admin-Rechte-Check mit Auto-Elevation
  - DPI-Awareness für Multi-Monitor-Unterstützung
  - Custom Title Bar mit Drag-Support (Borderless Window)
  - Collapsible Navigation Panels (System/Diagnose/Netzwerk/Cleanup)
  - RichTextBox mit StyleSystem für farbige Ausgaben

### Modulare Struktur (`Modules/`)

#### Core-Module (`Modules/Core/`)
- **[Settings.psm1](Modules/Core/Settings.psm1)** (1877 LOC): JSON-basierte Einstellungsverwaltung
  - ColorScheme-System mit Output/Console-Styles
  - Window-Position/Size-Persistenz
  - Cloud-Sync-kompatibel (Nextcloud/OneDrive-Error-Handling)
  - `Get-SystemToolSettings`, `Import-SystemToolSettings`, `Update-SystemToolUI`
  
- **[LogManager.psm1](Modules/Core/LogManager.psm1)**: Zentrales Logging-System
  - Logs nach `%LOCALAPPDATA%\BockisSystemTool\Logs`
  - Auto-Rotation und Cloud-Sync-Safe-Error-Handling
  
- **[UI.psm1](Modules/Core/UI.psm1)**: WPF-UI-Hilfsfunktionen
  - `New-ModernInfoButton`: Erstellt runde Info-Buttons
  - WPF-Integrationsfunktionen für ScrollViewer/WrapPanel
  
- **[TextStyle.psm1](Modules/Core/TextStyle.psm1)**: RichTextBox-Styling
  - `Set-OutputSelectionStyle`: Definiert Styles (BannerTitle, Success, Error, Warning, Info, Action)
  - Basiert auf ColorScheme aus [config.json](config.json)

#### Tool-Module (`Modules/Tools/`)
Alle Tool-Module folgen diesem Pattern:
```powershell
function Start-<ToolName> {
    param (
        [System.Windows.Forms.RichTextBox]$outputBox,
        [System.Windows.Forms.ProgressBar]$progressBar
    )
    # 1. Initialize-ProgressComponents für ProgressBar
    # 2. Write-ToolLog für strukturierte Ausgabe
    # 3. Save-DiagnosticToDatabase für Verlaufsspeicherung
}
```

**Wichtige Module:**
- **[SystemTools.psm1](Modules/Tools/SystemTools.psm1)** (1916 LOC): MRT Scans, SFC, Memory Diagnostic
- **[DISM-Tools.psm1](Modules/Tools/DISM-Tools.psm1)**: Check Health, Scan Health, Restore Health
- **[CHKDSKTools.psm1](Modules/Tools/CHKDSKTools.psm1)**: Interaktive Laufwerksauswahl mit Drive-Selection-Dialog
- **[DefenderTools.psm1](Modules/Tools/DefenderTools.psm1)**: Windows Defender Integration
- **[NetworkTools.psm1](Modules/Tools/NetworkTools.psm1)**: Ping-Tests, Adapter-Reset
- **[CleanupTools.psm1](Modules/Tools/CleanupTools.psm1)**: Disk Cleanup, Custom Cleanup mit UI-Automation
- **[WindowsUpdateTools.psm1](Modules/Tools/WindowsUpdateTools.psm1)** (643 LOC): Update-Management

#### Spezialmodule
- **[ToolLibrary.psm1](Modules/ToolLibrary.psm1)** (1623 LOC): 50+ vordefinierte Tools (Browser, Gaming, Dev, System)
  - Kategorien: `system`, `applications`, `audiotv`, `gaming`, `development`, `cloud`
  - `Get-AllTools`, `Get-ToolsByCategory`, `Install-ToolPackage`
  - WPF-ScrollViewer mit Tile-Layout für Tool-Darstellung
  
- **[ToolCache.psm1](Modules/ToolCache.psm1)** (454 LOC): Intelligentes Cache-System
  - `System.Runtime.Caching.MemoryCache` für Winget-Ergebnisse
  - 5-15 Min Cache-Ablaufzeit (reduziert Winget-Aufrufe massiv)
  - `Add-ToolToCache`, `Get-ToolFromCache`, `Remove-ToolFromCache`
  
- **[DatabaseManager.psm1](Modules/DatabaseManager.psm1)** (236 LOC): SQLite-Integration
  - DB-Pfad: `%LOCALAPPDATA%\BockisSystemTool\Database\system_data.db`
  - Tabellen: `DiagnosticResults`, `HardwareHistory`, `SystemSnapshots`
  - `Initialize-Database`, `Save-DiagnosticResult`, `Close-SystemDatabase`
  
- **[HardwareMonitorTools.psm1](Modules/Monitor/HardwareMonitorTools.psm1)**: LibreHardwareMonitor-Integration
  - Echtzeit-CPU/GPU/RAM/Disk-Monitoring
  - Sensor-Werte in Hardware-History-DB protokollieren

### Native Bibliotheken (`Lib/`)
- **System.Data.SQLite.dll**: SQLite für .NET
- **LibreHardwareMonitorLib.dll + .sys**: Hardware-Sensor-Zugriff (Kernel-Treiber)
- **SQLite.cs / SQLiteAsync.cs**: C#-Wrapper für Async-DB-Operationen

## Konventionen & Patterns

### Modul-Struktur
```powershell
# Imports am Anfang
Import-Module "$PSScriptRoot\..\Core\Core.psm1" -Force -Global

# Funktionen mit Verb-Noun-Naming
function Start-ToolAction { ... }
function Get-ToolData { ... }
function Set-ToolConfiguration { ... }

# Export am Ende
Export-ModuleMember -Function Start-ToolAction, Get-ToolData
```

### Logging-Pattern
```powershell
Write-ToolLog -ToolName "MyTool" `
              -Message "Aktion wird ausgeführt" `
              -OutputBox $outputBox `
              -Style 'Action' `  # BannerTitle|Success|Error|Warning|Info|Action
              -Level "Information" `  # Information|Warning|Error|Success
              -SaveToDatabase
```

### ProgressBar-Pattern
```powershell
Initialize-ProgressComponents -ProgressBar $progressBar -StatusLabel $statusLabel
Update-ProgressBar -ProgressBar $progressBar -PercentComplete 50 -Status "Verarbeite..."
Complete-ProgressBar -ProgressBar $progressBar
```

### Datenbankzugriff
```powershell
# Globale Connection: $script:dbConnection
if ($script:dbConnection) {
    Save-DiagnosticToDatabase -ToolName "MyTool" `
                               -Result "Erfolgreich" `
                               -ExitCode 0 `
                               -Details "Details hier"
}
```

### ColorScheme-System
- Styles werden in [config.json](config.json) unter `ColorScheme.Output.Styles` definiert
- Farben: Banner, Success, Warning, Error, Info, Accent, Divider, Muted
- Font-Modifier: SizeDelta (±Pixel), Style (Bold|Italic|Regular)

## Development Workflows

### Start der Anwendung
```powershell
# Mit Admin-Rechten (automatische Elevation im Skript)
powershell.exe -ExecutionPolicy Bypass -File "Win_Gui_Module.ps1"

# Oder via Batch (leer - muss noch implementiert werden)
"Bockis System-Tool starten.bat"
```

### Testing von Tool-Funktionen
```powershell
# Einzelnes Tool-Modul testen
Import-Module .\Modules\Tools\SystemTools.psm1 -Force
Start-QuickMRT -outputBox $null -progressBar $null  # Konsolen-Output
```

### Build & Release
```powershell
# Signierte Version erstellen (siehe BUILD-README.md)
.\Build-SignedInstaller.ps1 -EnableSignToolInISS -Verbose

# Nur Code signieren
.\Sign-AllScripts.ps1 -Verbose

# Inno Setup Installer: installer.iss (821 LOC)
# Output: BockisSystemTool-Setup.exe
```

### Debugging
- **F12**: PowerShell-Konsole im GUI ein/ausblenden (Toggle)
- Logs: `%LOCALAPPDATA%\BockisSystemTool\Logs\`
- SQLite-DB: `%LOCALAPPDATA%\BockisSystemTool\Database\system_data.db`
- `$VerbosePreference = 'Continue'` für detailliertes Logging

## Integration Points

### Winget-Integration
- Tool-Installation via `winget install <ID>`
- Cache-System reduziert API-Calls (5-15 Min Ablaufzeit)
- Validation-Logs: [Logs/winget-validation-*.json](Logs/)

### WPF-Integration
- `Add-Type -AssemblyName PresentationFramework` für XAML-Komponenten
- ScrollViewer mit WrapPanel für Tool-Tiles
- Collapsible Panels mit StackPanel-Visibility-Toggle

### SQLite-Integration
- ADO.NET mit `System.Data.SQLite.SQLiteConnection`
- Connection-String: `Data Source=$dbPath;Version=3;`
- **Wichtig**: Single Connection in `$script:dbConnection` (kein Array!)

### LibreHardwareMonitor
- Kernel-Treiber `.sys` erfordert Admin-Rechte
- False-Positive-Warnung: Windows Defender markiert `WinRing0` als "VulnerableDriver"
- Lösung: Defender-Ausnahme für Installationsordner (siehe [README.md](README.md) Zeile 115-132)

## Critical Details

### DPI-Awareness
- `SetProcessDPIAware()` aktiviert für 4K/8K-Unterstützung
- Windows AutoScale für automatische Skalierung
- Window-Position in `config.json` gespeichert

### Cloud-Sync-Kompatibilität
- Nextcloud/OneDrive können Locks verursachen
- LogManager verwendet `Try-Catch` mit Retry-Logic
- Settings-Modul hat `Test-Path` + Error-Suppression

### Code-Signierung
- Self-Signed-Zertifikat: `CN=Bocki Software, O=Bocki, C=DE`
- Timestamp-Server: `http://timestamp.digicert.com`
- `Set-AuthenticodeSignature` mit SHA256 + `-IncludeChain All`
- Gültig für 5 Jahre (siehe [BUILD-README.md](BUILD-README.md))

### Module-Import-Reihenfolge
1. Settings (für `Get-SystemToolSettings`)
2. LogManager (für `Write-ToolLog`)
3. UI/TextStyle (für RichTextBox-Styling)
4. ToolCache (vor ToolLibrary)
5. Tool-spezifische Module

## Häufige Aufgaben

### Neue Tool-Funktion hinzufügen
1. Erstelle Funktion in passendem `Modules/Tools/*.psm1`
2. Folge dem Pattern: `param($outputBox, $progressBar)`
3. Nutze `Write-ToolLog` für Ausgabe
4. Exportiere mit `Export-ModuleMember -Function`
5. Registriere in [Win_Gui_Module.ps1](Win_Gui_Module.ps1) als Button-Click-Handler

### Neues Tool zur Library hinzufügen
1. Öffne [Modules/ToolLibrary.psm1](Modules/ToolLibrary.psm1)
2. Finde passende Kategorie (`$script:toolLibrary['category']`)
3. Füge HashTable hinzu: `Name`, `Description`, `Version`, `DownloadUrl`, `Category`, `Tags`, `Winget`
4. Validiere Winget-ID: `.\Tools\Validate-WingetIds.ps1`

### Settings erweitern
1. Füge Default-Wert in `Get-DefaultColorScheme()` ein ([Settings.psm1](Modules/Core/Settings.psm1))
2. Update `Merge-SettingsHashtable` für verschachtelte Objekte
3. Nutze `Get-SystemToolSettings` zum Abrufen im Code

## Wichtige Dateien für Kontextverständnis

- **Hauptlogik**: [Win_Gui_Module.ps1](Win_Gui_Module.ps1) (Zeilen 1-500 für Initialisierung)
- **Einstellungen**: [Modules/Core/Settings.psm1](Modules/Core/Settings.psm1) + [config.json](config.json)
- **Tool-Definitionen**: [Modules/ToolLibrary.psm1](Modules/ToolLibrary.psm1) (Zeilen 1-300)
- **Datenbank-Schema**: [Modules/DatabaseManager.psm1](Modules/DatabaseManager.psm1) (Zeilen 40-70)
- **Build-Prozess**: [BUILD-README.md](BUILD-README.md)
- **Projektübersicht**: [README.md](README.md)

---

**Version**: 4.1.2 | **Letzte Aktualisierung**: 2026-02-09 | **Autor**: Bockis

# Win_Gui_Module.ps1 - Hauptskript für die PowerShell-GUI
# Autor: Bocki
# Version: 4.1.8

# ===================================================================
# VERSIONS-INFORMATION
# ===================================================================
$script:AppVersion = "4.1.8"
$script:AppName = "Bockis System-Tool"
$script:AppPublisher = "Bockis"
$script:VersionDate = "2026-03-03"
# WinForms-Assemblies laden
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Windows.Forms



# WinAPI für runde Ecken bei Controls
if (-not ([System.Management.Automation.PSTypeName]'RoundedCorners').Type) {
    Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public class RoundedCorners {
    [DllImport("Gdi32.dll", EntryPoint = "CreateRoundRectRgn")]
    public static extern IntPtr CreateRoundRectRgn(
        int nLeftRect,
        int nTopRect,
        int nRightRect,
        int nBottomRect,
        int nWidthEllipse,
        int nHeightEllipse
    );
}
"@ -ReferencedAssemblies System.Windows.Forms -ErrorAction SilentlyContinue
}



# ===================================================================
# ===================================================================
# GLOBALE WRITE-TOOLLOG FUNKTION
# Diese Funktion wird VOR dem Modul-Import definiert und bleibt erhalten
# ===================================================================
function global:Write-ToolLog {
    param(
        [string]$ToolName,
        [string]$Message,
        [System.Windows.Forms.RichTextBox]$OutputBox,
        [System.Drawing.Color]$Color = [System.Drawing.Color]::Empty,
        [ValidateSet('Information', 'Warning', 'Error', 'Success')]
        [string]$Level = 'Information',
        [string]$Style,
        [switch]$NoTimestamp,
        [switch]$SaveToDatabase
    )

    # Ausgabe in der RichTextBox
    if ($OutputBox) {
        $styleKey = if ($Style) { $Style } else {
            switch ($Level) {
                'Error' { 'Error' }
                'Warning' { 'Warning' }
                'Success' { 'Success' }
                default { 'Info' }
            }
        }

        if ($Style -or $Color.IsEmpty) {
            Set-OutputSelectionStyle -OutputBox $OutputBox -Style $styleKey
        }
        else {
            Set-OutputSelectionStyle -OutputBox $OutputBox -Style 'Default'
        }

        if (-not $Color.IsEmpty) {
            $OutputBox.SelectionColor = $Color
        }

        if ($NoTimestamp) {
            $OutputBox.AppendText("$Message`r`n")
        }
        else {
            $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            $OutputBox.AppendText("[$timestamp] [$ToolName] $Message`r`n")
        }
    }

    # Schreibe direkt in die Log-Datei (LogManager-Funktionalität eingebettet)
    # Verhindert Namenskollision durch direkten Dateizugriff
    try {
        $logDirectory = Join-Path $PSScriptRoot "Data\Logs"
        if (-not (Test-Path $logDirectory)) {
            New-Item -ItemType Directory -Path $logDirectory -Force | Out-Null
        }
        
        $sanitizedToolName = $ToolName -replace '[\\/:*?"<>|]', '_'
        $logFileName = "$sanitizedToolName.log"
        $logPath = Join-Path $logDirectory $logFileName
        
        # Log-Eintrag formatieren
        $timestamp = if (-not $NoTimestamp) { "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - " } else { "" }
        $levelPrefix = switch ($Level) {
            'Information' { 'INFO' }
            'Warning' { 'WARN' }
            'Error' { 'ERROR' }
            'Success' { 'SUCCESS' }
        }
        
        $logEntry = "$timestamp[$levelPrefix] $Message"
        
        # Schreibe in Log-Datei mit Retry-Logik
        $retryCount = 0
        $maxRetries = 3
        do {
            try {
                [System.IO.File]::AppendAllText($logPath, "$logEntry`r`n", [System.Text.Encoding]::UTF8)
                break
            }
            catch {
                $retryCount++
                if ($retryCount -ge $maxRetries) {
                    Write-Verbose "Konnte nicht auf Log-Datei zugreifen: $_"
                    break
                }
                Start-Sleep -Milliseconds 100
            }
        } while ($retryCount -lt $maxRetries)
    }
    catch {
        Write-Verbose "Fehler beim Schreiben in Log-Datei: $_"
    }

    # Speichere in der Datenbank, wenn angefordert
    if ($SaveToDatabase -and $script:dbConnection) {
        # Konvertiere Color/Level zur Ergebnis-Darstellung
        $result = switch ($Level) {
            'Error' { "Fehler" }
            'Warning' { "Warnung" }
            'Success' { "Erfolgreich" }
            default { "Information" }
        }
        
        # Exitcode basierend auf Level
        $exitCode = switch ($Level) {
            'Error' { 1 }
            'Warning' { 2 }
            'Success' { 0 }
            default { 0 }
        }
        
        # In Datenbank speichern
        Save-DiagnosticToDatabase -ToolName $ToolName -Result $result -ExitCode $exitCode -Details $Message
    }
}

# Hilfsfunktion zum Einfügen von Segoe MDL2 Assets Icons in die OutputBox
function global:Add-OutputIcon {
    param(
        [Parameter(Mandatory = $true)]
        [System.Windows.Forms.RichTextBox]$OutputBox,
        [Parameter(Mandatory = $true)]
        [int]$IconCode
    )
    
    if ($OutputBox) {
        # Speichere aktuelle Farbe
        $currentColor = $OutputBox.SelectionColor
        
        # Setze Font auf Segoe MDL2 Assets für das Icon
        $OutputBox.SelectionFont = New-Object System.Drawing.Font("Segoe MDL2 Assets", 12)
        $OutputBox.AppendText([char]$IconCode)
        
        # Setze Font zurück auf Standard
        $OutputBox.SelectionFont = New-Object System.Drawing.Font("Consolas", 12)
        $OutputBox.SelectionColor = $currentColor
    }
}

# Hilfsfunktion zum Hinzufügen eines Icons zu einem Button
function global:Add-ButtonIcon {
    param(
        [Parameter(Mandatory = $true)]
        [System.Windows.Forms.Button]$Button,
        [Parameter(Mandatory = $true)]
        [int]$IconCode,
        [int]$IconSize = 12,
        [int]$LeftMargin = 10
    )
    
    # Icon-Label erstellen
    $iconLabel = New-Object System.Windows.Forms.Label
    $iconLabel.Text = [char]$IconCode
    $iconLabel.Font = New-Object System.Drawing.Font("Segoe MDL2 Assets", $IconSize)
    $iconLabel.ForeColor = $Button.ForeColor
    $iconLabel.BackColor = [System.Drawing.Color]::Transparent
    $iconLabel.AutoSize = $true
    $iconLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
    
    # Label zentrieren (vertikal)
    $iconLabel.Location = New-Object System.Drawing.Point($LeftMargin, [Math]::Round(($Button.Height - $IconSize - 4) / 2))
    
    # Klick-Events durchleiten
    $iconLabel.Add_Click({ $this.Parent.PerformClick() })
    $iconLabel.Add_MouseEnter({ $this.Parent.BackColor = $this.Parent.FlatAppearance.MouseOverBackColor })
    $iconLabel.Add_MouseLeave({ 
        if ($this.Parent.Tag -ne "expanded") { 
            $this.Parent.BackColor = [System.Drawing.Color]::FromArgb(37, 37, 38)
        }
    })
    
    # Label zum Button hinzufügen
    $Button.Controls.Add($iconLabel)
    
    # Button-Text-Padding anpassen, um Platz für Icon zu schaffen
    $currentPadding = $Button.Padding
    $Button.Padding = New-Object System.Windows.Forms.Padding(($LeftMargin + $IconSize + 10), $currentPadding.Top, $currentPadding.Right, $currentPadding.Bottom)
}

# Globale Einstellungen - werden vom Settings-Modul verwaltet
$script:settings = $null

# Globale Datenbankverbindung
$script:dbConnection = $null

# Funktion zum Sicherstellen, dass alle Data-Verzeichnisse existieren
function Initialize-DataDirectories {
    $dataRoot = Join-Path $PSScriptRoot "Data"
    $directories = @(
        $dataRoot
        (Join-Path $dataRoot "Database")
        (Join-Path $dataRoot "Logs")
        (Join-Path $dataRoot "Temp")
        (Join-Path $dataRoot "ToolDownloads")
    )
    
    foreach ($dir in $directories) {
        if (-not (Test-Path $dir)) {
            try {
                New-Item -ItemType Directory -Path $dir -Force | Out-Null
                Write-Verbose "Verzeichnis erstellt: $dir"
            }
            catch {
                Write-Warning "Konnte Verzeichnis nicht erstellen: $dir - $_"
            }
        }
    }
}

# Data-Verzeichnisse beim Start initialisieren
Initialize-DataDirectories

# Funktion zum Initialisieren der Systemdatenbank - wird früher definiert, damit sie überall verfügbar ist
function Initialize-SystemDatabase {
    try {
        # Prüfe, ob das DatabaseManager-Modul geladen ist
        if (-not (Get-Command -Name Initialize-Database -ErrorAction SilentlyContinue)) {
            Write-Host "Lade DatabaseManager Modul..." -ForegroundColor Yellow
            Import-Module "$PSScriptRoot\Modules\DatabaseManager.psm1" -Force
        }

        # Initialisiere die Datenbank und speichere die Verbindung in der globalen Variable
        $script:dbConnection = Initialize-Database
        
        if ($script:dbConnection) {
            # Write-Host "Datenbankverbindung erfolgreich initialisiert" -ForegroundColor Green
            return $true
        }
        else {
            Write-Host "Fehler beim Initialisieren der Datenbankverbindung" -ForegroundColor Red
            return $false
        }
    }
    catch {
        Write-Host "Fehler beim Initialisieren der Datenbank: $_" -ForegroundColor Red
        return $false
    }
}

# Laden der Einstellungen aus der Konfigurationsdatei, falls vorhanden
function Import-Settings {
    $settingsFilePath = "$PSScriptRoot\config.json"

    # Setze die globalen Einstellungen durch Aufruf der Funktion aus dem Settings-Modul
    return Import-SystemToolSettings -ConfigPath $settingsFilePath
}

# Einstellungen auf die Benutzeroberfläche anwenden
function Update-Settings {
    # Diese Funktion ruft nur noch die entsprechende Funktion im Settings-Modul auf
    # und übergibt die UI-Elemente
    $result = Update-SystemToolUI -UIElements @{
        OutputBox        = $outputBox
        MainForm         = $mainform
        HardwareInfoBox  = $hardwareInfoBox
        SystemStatusBox  = $systemStatusBox
        ToolInfoBox      = $toolInfoBox
        ToolDownloadsBox = $toolDownloadsBox
        HardwareTimer    = $script:hardwareTimer
        SystemPanel      = $global:tblSystem
        DiskPanel        = $tblDisk
        NetworkPanel     = $tblNetwork
        CleanupPanel     = $tblCleanup
        BtnSystem        = $btnSystem
        BtnDisk          = $btnDisk
        BtnNetwork       = $btnNetwork
        BtnCleanup       = $btnCleanup
    }

    if ($result) {
        $settings = Get-SystemToolSettings
        if ($settings) {
            $null = Initialize-TextStyle -Settings $settings -OutputBox $outputBox
        }
    }

    return $result
}

# Administratorrechte prüfen und bei Bedarf anfordern
function Test-Admin {
    $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentUser.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Administratorrechte anfordern, falls nicht vorhanden
if (-not (Test-Admin)) {
    try {
        # Skriptpfad ermitteln
        $scriptPath = $MyInvocation.MyCommand.Path

        # PowerShell mit erhöhten Rechten starten (ohne -Wait, damit das aktuelle Fenster geschlossen wird)
        Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`"" -Verb RunAs

        # Beende das aktuelle Skript, da es in einem neuen Prozess mit Admin-Rechten gestartet wird
        exit
    }
    catch {
        Write-Host "Fehler beim Anfordern von Administratorrechten: $_" -ForegroundColor Red
        Write-Host "Bitte starten Sie das Skript manuell mit Administratorrechten." -ForegroundColor Yellow
        exit
    }
}

# Logo-Funktion hinzufügen
function Show-SystemToolLogo {
    # Konsole kurz säubern
    Clear-Host
    Start-Sleep -Milliseconds 500

    # Farbdefinitionen
    $primaryColor = [System.ConsoleColor]::Cyan
    $secondaryColor = [System.ConsoleColor]::Yellow
    $accentColor = [System.ConsoleColor]::Green

    Write-Host
    Write-Host " `t   ███████╗██╗   ██╗███████╗████████╗███████╗███╗   ███╗" -ForegroundColor $primaryColor
    Write-Host " `t   ██╔════╝╚██╗ ██╔╝██╔════╝╚══██╔══╝██╔════╝████╗ ████║" -ForegroundColor $primaryColor
    Write-Host " `t   ███████╗ ╚████╔╝ ███████╗   ██║   █████╗  ██╔████╔██║" -ForegroundColor $primaryColor
    Write-Host " `t   ╚════██║  ╚██╔╝  ╚════██║   ██║   ██╔══╝  ██║╚██╔╝██║" -ForegroundColor $primaryColor
    Write-Host " `t   ███████║   ██║   ███████║   ██║   ███████╗██║ ╚═╝ ██║" -ForegroundColor $primaryColor
    Write-Host " `t   ╚══════╝   ╚═╝   ╚══════╝   ╚═╝   ╚══════╝╚═╝     ╚═╝" -ForegroundColor $primaryColor
    Write-Host " `t   ████████╗ ██████╗  ██████╗ ██╗     ███████╗" -ForegroundColor $secondaryColor
    Write-Host " `t   ╚══██╔══╝██╔═══██╗██╔═══██╗██║     ██╔════╝" -ForegroundColor $secondaryColor
    Write-Host " `t      ██║   ██║   ██║██║   ██║██║     ███████╗" -ForegroundColor $secondaryColor
    Write-Host " `t      ██║   ██║   ██║██║   ██║██║     ╚════██║" -ForegroundColor $secondaryColor
    Write-Host " `t      ██║   ╚██████╔╝╚██████╔╝███████╗███████║" -ForegroundColor $secondaryColor
    Write-Host " `t      ╚═╝    ╚═════╝  ╚═════╝ ╚══════╝╚══════╝" -ForegroundColor $secondaryColor
    Write-Host "`n`n                  Version $script:AppVersion - PowerShell Edition" -ForegroundColor $accentColor
    Write-Host "                      Entwickelt von $script:AppPublisher" -ForegroundColor $accentColor

    # Trennlinie
    Write-Host "`n" + ("═" * 70) -ForegroundColor Cyan

    # System-Informationen
    Write-Host "`n[System-Information]" -ForegroundColor $secondaryColor
    Write-Host "  ├─ OS        : " -NoNewline -ForegroundColor $primaryColor
    Write-Host ((Get-CimInstance -ClassName Win32_OperatingSystem).Caption)
    Write-Host "  ├─ Computer  : " -NoNewline -ForegroundColor $primaryColor
    Write-Host ($env:COMPUTERNAME)
    Write-Host "  ├─ Benutzer  : " -NoNewline -ForegroundColor $primaryColor
    Write-Host ($env:USERNAME)
    Write-Host "  └─ Datum     : " -NoNewline -ForegroundColor $primaryColor
    Write-Host (Get-Date -Format "dd.MM.yyyy HH:mm:ss")

    # Trennlinie
    Write-Host "`n" + ("═" * 70) -ForegroundColor Cyan
}

# Logo anzeigen
Show-SystemToolLogo

# Skriptpfad auf Script-Ebene sichern (hier ist $MyInvocation korrekt,
# innerhalb von Funktionen zeigt $MyInvocation.MyCommand.Path auf die Funktion!)
$script:MyScriptPath = $MyInvocation.MyCommand.Path
if ([string]::IsNullOrEmpty($script:MyScriptPath)) {
    $script:MyScriptPath = $PSCommandPath
}

# Alle Module importieren
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulesPath = Join-Path -Path $scriptPath -ChildPath "Modules"

# Stelle sicher, dass das Modules-Verzeichnis existiert
if (-not (Test-Path $modulesPath)) {
    Write-Host "Erstelle Modules-Verzeichnis..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $modulesPath | Out-Null
}

# Definiere die Module in der richtigen Reihenfolge (Abhängigkeiten zuerst)
$moduleOrder = @(
    'Core\Settings                ', # Einstellungen (muss zuerst geladen werden)
    'Core\LogManager              ', # Logging-Funktionalitäten
    'Core\Core                    ', # Basis-Funktionalitäten
    'Core\UI                      ', # UI-Komponenten
    'Core\TextStyle               ', # Text-Styling
    'Core\ProgressBarTools        ', # ProgressBar-Funktionalitäten
    'Core\DependencyChecker       ', # Abhängigkeiten prüfen
    'Monitor\HardwareMonitorTools ', # Hardware-Monitor-Tools
    'SystemInfo                   ', # System-Informationen
    'Tools\SystemTools            ', # System-Tools
    'Tools\DISM-Tools             ', # Festplatten-Tools
    'Tools\CHKDSKTools            ', # CHKDSK-Tools
    'Tools\NetworkTools           ', # Netzwerk-Tools
    'Tools\CleanupTools           ', # Bereinigungs-Tools
    'ToolCache                    ', # Tool-Cache für Downloads
    'ToolLibrary                  ', # Tool-Bibliothek
    # 'HardwareInfo               ', # DEPRECATED - Nicht mehr verwendet (direkt in Win_Gui_Module.ps1)
    'Tools\DefenderTools          ', # Windows Defender Tools
    'Tools\WindowsUpdateTools     ', # Windows Update Tools
    'Tools\SmartRepair            ', # 1-Klick Smart Repair
    'DatabaseManager              ', # Datenbank-Integration
    'UpdateManager                ' # GitHub Update-Funktionalität
)

# Verbesserte Fehlerbehandlung beim Modul-Import
$moduleErrors = @()
$loadedModules = @()



# Farbdefinitionen für Modulladeanzeige
$primaryColor = [System.ConsoleColor]::Cyan
$secondaryColor = [System.ConsoleColor]::Yellow
$accentColor = [System.ConsoleColor]::Green

# Lade-Animation für Module vorbereiten
$totalModules = $moduleOrder.Count
$barLength = 20

Write-Host "`n[+] Module werden geladen... " -ForegroundColor $accentColor
Write-Host

# Fortschrittsbalken initial anzeigen
$progressBar = "".PadRight($barLength, '░')
# Lösche zuerst die ganze Zeile
Write-Host "`r" + (" " * 100) -NoNewline
Write-Host "`r[" -NoNewline -ForegroundColor $primaryColor
Write-Host $progressBar -NoNewline -ForegroundColor $secondaryColor
Write-Host "]" -NoNewline -ForegroundColor $primaryColor
Write-Host " 0% | Initialisierung..." -NoNewline -ForegroundColor $accentColor

for ($i = 0; $i -lt $totalModules; $i++) {
    $module = $moduleOrder[$i]
    # Entferne Leerzeichen aus dem Modulpfad für korrekte Dateipfade
    $moduleClean = $module.Trim()
    $modulePath = Join-Path $modulesPath "$moduleClean.psm1"

    # Fortschritt berechnen und anzeigen
    $percentComplete = [math]::Floor((($i + 1) / $totalModules) * 100)
    $filledLength = [math]::Floor((($i + 1) / $totalModules) * $barLength)
    $progressBar = "".PadLeft($filledLength, '█').PadRight($barLength, '░')

    # Bereite eine saubere Anzeige vor: Lösche zuerst die ganze Zeile
    Write-Host "`r" + (" " * 100) -NoNewline

    # Zeige den Fortschrittsbalken an
    Write-Host "`r[" -NoNewline -ForegroundColor $primaryColor
    Write-Host $progressBar -NoNewline -ForegroundColor $secondaryColor
    Write-Host "]" -NoNewline -ForegroundColor $primaryColor

    # Zeige Prozent und Modulnamen in einem separaten Bereich an
    $moduleInfo = " $percentComplete% | Lade: "
    # Kürze den Modulnamen wenn nötig
    $displayModule = if ($module.Length -gt 25) { $module.Substring(0, 22) + "..." } else { $module }
    Write-Host "$moduleInfo$displayModule" -NoNewline -ForegroundColor $accentColor

    try {
        # Prüfe ob Modul-Datei existiert
        if (-not (Test-Path $modulePath)) {
            throw "Modul-Datei nicht gefunden: $modulePath"
        }        # Extrahiere den reinen Modulnamen ohne Pfad für Remove-Module
        $moduleNameOnly = $moduleClean.Split('\')[-1].Trim()

        # Versuche vorhandenes Modul zu entfernen
        $existingModule = Get-Module $moduleNameOnly
        if ($existingModule) {
            Remove-Module $moduleNameOnly -Force -ErrorAction SilentlyContinue
        }

        # Importiere das Modul mit vollständigem Pfad
        Import-Module $modulePath -Force -ErrorAction Stop
        $loadedModules += $moduleNameOnly
    }
    catch {
        $errorMessage = "Fehler beim Laden des Moduls {0}: {1}" -f $module, $_.Exception.Message
        $moduleErrors += $errorMessage
        
        # Schreibe Fehler in Log-Datei
        $logDir = "$PSScriptRoot\Data\Logs"
        if (-not (Test-Path $logDir)) {
            New-Item -ItemType Directory -Path $logDir -Force | Out-Null
        }
        $logFile = Join-Path $logDir "module_errors.log"
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        "[$timestamp] $errorMessage" | Out-File -FilePath $logFile -Append -Encoding UTF8
        "[$timestamp] StackTrace: $($_.ScriptStackTrace)" | Out-File -FilePath $logFile -Append -Encoding UTF8
        "[$timestamp] ---" | Out-File -FilePath $logFile -Append -Encoding UTF8
    }
}

Write-Host "`n"  # Neue Zeile nach der Fortschrittsanzeige

# Ersetze Ausgabe von geladenen Modulen durch eine Zusammenfassung
Write-Host "`t└─ Modulladung abgeschlossen. $($loadedModules.Count) von $($moduleOrder.Count) Modulen erfolgreich geladen." -ForegroundColor Green

# Fehlermeldungen ausgeben, falls vorhanden
if ($moduleErrors.Count -gt 0) {
    Write-Host "`nFehler beim Laden von Modulen:" -ForegroundColor Yellow
    foreach ($errMsg in $moduleErrors) {
        Write-Host $errMsg -ForegroundColor Red
    }
}

# Prüfe, ob alle erforderlichen Module geladen wurden
# Extrahiere die reinen Modulnamen für den Vergleich
$requiredModuleNames = $moduleOrder | ForEach-Object { $_.Split('\')[-1].Trim() }
$missingModules = $requiredModuleNames | Where-Object { $_ -notin $loadedModules }

# Fehlende Module ausgeben, falls vorhanden
if ($missingModules.Count -gt 0) {
    Write-Host "`nNicht geladene Module:" -ForegroundColor Yellow
    $logDir = "$PSScriptRoot\Data\Logs"
    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }
    $logFile = Join-Path $logDir "module_errors.log"
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    
    foreach ($missingModule in $missingModules) {
        Write-Host "Modul $missingModule wurde nicht geladen." -ForegroundColor Red
        "[$timestamp] Fehlendes Modul: $missingModule" | Out-File -FilePath $logFile -Append -Encoding UTF8
    }
}

# ===================================================================
# EINSTELLUNGEN LADEN (nach Modul-Import)
# ===================================================================

# Einstellungen beim Programmstart laden (Ausgabe erfolgt später)
$settingsResult = Import-Settings

# Initialisiere Ausgabecodierung
& {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    $OutputEncoding = [System.Text.Encoding]::UTF8
}

# PowerShell-Fenster anpassen - mit Fehlerbehandlung
try {
    # Aktuelle Fenstergröße abrufen
    $currentBufferSize = $Host.UI.RawUI.BufferSize

    # Neue Fenstergröße setzen (nicht größer als der aktuelle Puffer)
    $newWindowSize = New-Object System.Management.Automation.Host.Size(
        [Math]::Min(80, $currentBufferSize.Width),
        [Math]::Min(50, $currentBufferSize.Height)
    )

    # Neue Puffergröße setzen (nicht zu groß)
    $newBufferSize = New-Object System.Management.Automation.Host.Size(
        [Math]::Min(100, $currentBufferSize.Width),
        [Math]::Min(2000, $currentBufferSize.Height)
    )

    # Größen anwenden
    $Host.UI.RawUI.WindowSize = $newWindowSize
    $Host.UI.RawUI.BufferSize = $newBufferSize
    $Host.UI.RawUI.WindowTitle = "System Tools"
}
catch {
    Write-Host "Hinweis: Konnte PowerShell-Fenster nicht anpassen: $_" -ForegroundColor Yellow
}


# Trennlinie
Write-Host "`n" + ("═" * 70) -ForegroundColor Cyan
Write-Host "`n"
# Windows AutoScale für automatische DPI-Anpassung aktivieren
# Dies nutzt die Windows-eigene Skalierung für alle Auflösungen (HD, Full HD, 4K, 8K)
if (-not ([System.Management.Automation.PSTypeName]'DPIAwareness').Type) {
    Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public class DPIAwareness {
    [DllImport("user32.dll")]
    public static extern bool SetProcessDPIAware();
}
"@ -ErrorAction SilentlyContinue
}

# Aktiviere DPI-Awareness für Windows AutoScale
try {
    [DPIAwareness]::SetProcessDPIAware() | Out-Null
    Write-Host "[✓] Windows AutoScale aktiviert (automatische Anpassung für alle Auflösungen)" -ForegroundColor Green
}
catch {
    Write-Host "[!] AutoScale-Aktivierung fehlgeschlagen: $_" -ForegroundColor Yellow
}

# Einstellungen-Ausgabe (nach AutoScale für konsistente Reihenfolge)
if ($settingsResult -and $settingsResult.Success) {
    if ($settingsResult.Migrated) {
        Write-Host "[✓] Log-Pfad wurde automatisch auf lokalen AppData-Ordner migriert" -ForegroundColor Green
    }
    if ($settingsResult.ConfigPath) {
        Write-Host "[✓] Einstellungen wurden aus $($settingsResult.ConfigPath) geladen" -ForegroundColor Green
    }
}

# Erstelle das Hauptformular
$mainform = New-Object System.Windows.Forms.Form
$mainform.Text = "$script:AppName $script:AppVersion"
$mainform.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$mainform.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::None  # Kein Rahmen
$mainform.MinimumSize = New-Object System.Drawing.Size(1000, 850)
$mainform.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)  # Dunkles Grau wie UniGetUI

# Windows AutoScale für automatische Anpassung an alle Bildschirmauflösungen
# Dies passt die GUI automatisch an HD, Full HD, 4K, 8K und alle DPI-Einstellungen an
$mainform.AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::Dpi
$mainform.AutoScaleDimensions = New-Object System.Drawing.SizeF(96.0, 96.0)

# Gespeicherte Fenstergröße und Position laden mit Boundary-Checking
$mainform.StartPosition = "Manual"
$savedWidth = if ($settings.WindowWidth) { [int]$settings.WindowWidth } else { 1000 }
$savedHeight = if ($settings.WindowHeight) { [int]$settings.WindowHeight } else { 850 }
$savedLeft = if ($settings.WindowLeft) { [int]$settings.WindowLeft } else { $null }
$savedTop = if ($settings.WindowTop) { [int]$settings.WindowTop } else { $null }

# Fenstergröße setzen
$mainform.Size = New-Object System.Drawing.Size($savedWidth, $savedHeight)

# Boundary-Checking: Prüfen, ob die gespeicherte Position auf einem sichtbaren Monitor liegt
$positionValid = $false
if ($null -ne $savedLeft -and $null -ne $savedTop) {
    # Prüfen, ob die Position auf einem der verfügbaren Monitore liegt
    $testPoint = New-Object System.Drawing.Point($savedLeft, $savedTop)
    $screens = [System.Windows.Forms.Screen]::AllScreens
    
    foreach ($screen in $screens) {
        if ($screen.WorkingArea.Contains($testPoint) -or 
            ($savedLeft -ge $screen.WorkingArea.Left -and 
             $savedLeft -lt ($screen.WorkingArea.Left + $screen.WorkingArea.Width) -and
             $savedTop -ge $screen.WorkingArea.Top -and 
             $savedTop -lt ($screen.WorkingArea.Top + $screen.WorkingArea.Height))) {
            $positionValid = $true
            break
        }
    }
}

# Position setzen: Entweder gespeicherte Position oder zentriert auf primärem Monitor
if ($positionValid) {
    $mainform.Location = New-Object System.Drawing.Point($savedLeft, $savedTop)
} else {
    # Zentriert auf dem primären Monitor
    $primaryScreen = [System.Windows.Forms.Screen]::PrimaryScreen
    $centerX = $primaryScreen.WorkingArea.Left + (($primaryScreen.WorkingArea.Width - $savedWidth) / 2)
    $centerY = $primaryScreen.WorkingArea.Top + (($primaryScreen.WorkingArea.Height - $savedHeight) / 2)
    $mainform.Location = New-Object System.Drawing.Point($centerX, $centerY)
}

# Tastatur-Events aktivieren für Shortcuts
$mainform.KeyPreview = $true
$mainform.Add_KeyDown({
    param($formSender, $e)
    
    # F12: PowerShell-Konsole ein-/ausblenden (funktioniert auch während Scans!)
    if ($e.KeyCode -eq [System.Windows.Forms.Keys]::F12) {
        $e.Handled = $true
        # Asynchrone Ausführung über Timer, um UI-Blockierung zu vermeiden
        $script:f12Timer = New-Object System.Windows.Forms.Timer
        $script:f12Timer.Interval = 10
        $script:f12Timer.Add_Tick({
            try {
                $visible = Switch-ConsoleVisibility
                # Update Button falls vorhanden
                if ($btnToggleConsole) {
                    $btnToggleConsole.Invoke([Action]{
                        if ($visible) {
                            $btnToggleConsole.BackColor = [System.Drawing.Color]::FromArgb(55, 55, 55)
                            $btnToggleConsole.Text = "◄"
                        }
                        else {
                            $btnToggleConsole.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
                            $btnToggleConsole.Text = "►"
                        }
                    })
                }
            }
            catch {
                Write-Verbose "F12 Toggle-Fehler: $_"
            }
            finally {
                $script:f12Timer.Stop()
                $script:f12Timer.Dispose()
            }
        })
        $script:f12Timer.Start()
    }
})

# Benutzerdefinierte Titelleiste
$titleBar = New-Object System.Windows.Forms.Panel
$titleBar.Size = New-Object System.Drawing.Size(1000, 30)
$titleBar.BackColor = [System.Drawing.Color]::FromArgb(20, 20, 20)  # Sehr dunkles Grau
$titleBar.Dock = [System.Windows.Forms.DockStyle]::Top

# Variable für das Fenster-Dragging
$script:mouseOffset = New-Object System.Drawing.Point

# Titel-Label
$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Text = "$script:AppName $script:AppVersion"
$titleLabel.ForeColor = [System.Drawing.Color]::White
$titleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$titleLabel.Location = New-Object System.Drawing.Point(10, 5)
$titleLabel.Size = New-Object System.Drawing.Size(200, 20)
[void]$titleBar.Controls.Add($titleLabel)

# Event-Handler für das Verschieben des Fensters
$titleBar.Add_MouseDown({
        param($eventSender, $e)
        if ($e.Button -eq [System.Windows.Forms.MouseButtons]::Left) {
            $script:mouseOffset = New-Object System.Drawing.Point(
                - $e.X,
                - $e.Y
            )
        }
    })

$titleBar.Add_MouseMove({
        param($eventSender, $e)
        if ($e.Button -eq [System.Windows.Forms.MouseButtons]::Left) {
            $mousePos = [System.Windows.Forms.Control]::MousePosition
            $newLocation = New-Object System.Drawing.Point(
                ($mousePos.X + $script:mouseOffset.X),
                ($mousePos.Y + $script:mouseOffset.Y)
            )
            $mainform.Location = $newLocation
        }
    })

# Auch das Label zum Verschieben nutzen
$titleLabel.Add_MouseDown({
        param($eventSender, $e)
        if ($e.Button -eq [System.Windows.Forms.MouseButtons]::Left) {
            $script:mouseOffset = New-Object System.Drawing.Point(
                - ($e.X + $eventSender.Left),
                - ($e.Y + $eventSender.Top)
            )
        }
    })

$titleLabel.Add_MouseMove({
        param($eventSender, $e)
        if ($e.Button -eq [System.Windows.Forms.MouseButtons]::Left) {
            $mousePos = [System.Windows.Forms.Control]::MousePosition
            $newLocation = New-Object System.Drawing.Point(
                ($mousePos.X + $script:mouseOffset.X),
                ($mousePos.Y + $script:mouseOffset.Y)
            )
            $mainform.Location = $newLocation
        }
    })

# Minimieren-Button
$minimizeButton = New-Object System.Windows.Forms.Button
$minimizeButton.Text = "−"
$minimizeButton.Size = New-Object System.Drawing.Size(30, 30)
$minimizeButton.Location = New-Object System.Drawing.Point(940, 0)
$minimizeButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$minimizeButton.FlatAppearance.BorderSize = 0
$minimizeButton.FlatAppearance.BorderColor = [System.Drawing.Color]::DarkSlateGray
$minimizeButton.FlatAppearance.MouseDownBackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
$minimizeButton.BackColor = [System.Drawing.Color]::DarkSlateGray
$minimizeButton.ForeColor = [System.Drawing.Color]::White
$minimizeButton.Font = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
$minimizeButton.Add_Click({ $mainform.WindowState = [System.Windows.Forms.FormWindowState]::Minimized })
$minimizeButton.Add_MouseEnter({ $this.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43) })
$minimizeButton.Add_MouseLeave({ $this.BackColor = [System.Drawing.Color]::DarkSlateGray })
[void]$titleBar.Controls.Add($minimizeButton)

# Schließen-Button
$closeButton = New-Object System.Windows.Forms.Button
$closeButton.Text = "×"
$closeButton.Size = New-Object System.Drawing.Size(30, 30)
$closeButton.Location = New-Object System.Drawing.Point(970, 0)
$closeButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$closeButton.FlatAppearance.BorderSize = 0
$closeButton.FlatAppearance.BorderColor = [System.Drawing.Color]::DarkSlateGray
$closeButton.FlatAppearance.MouseDownBackColor = [System.Drawing.Color]::Red
$closeButton.BackColor = [System.Drawing.Color]::DarkSlateGray
$closeButton.ForeColor = [System.Drawing.Color]::White
$closeButton.Font = New-Object System.Drawing.Font("Segoe UI", 12)
$closeButton.Add_Click({ Close-FormSafely -Form $mainform })
$closeButton.Add_MouseEnter({ $this.BackColor = [System.Drawing.Color]::Red })
$closeButton.Add_MouseLeave({ $this.BackColor = [System.Drawing.Color]::DarkSlateGray })
[void]$titleBar.Controls.Add($closeButton)

# Info-Button
$infoButton = New-Object System.Windows.Forms.Button
$infoButton.Text = "?"
$infoButton.Size = New-Object System.Drawing.Size(30, 30)
$infoButton.Location = New-Object System.Drawing.Point(910, 0)
$infoButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$infoButton.FlatAppearance.BorderSize = 0
$infoButton.FlatAppearance.BorderColor = [System.Drawing.Color]::DarkSlateGray
$infoButton.FlatAppearance.MouseDownBackColor = [System.Drawing.Color]::SlateGray
$infoButton.BackColor = [System.Drawing.Color]::DarkSlateGray
$infoButton.ForeColor = [System.Drawing.Color]::White
$infoButton.Font = New-Object System.Drawing.Font("Segoe UI", 12)
$infoButton.Add_Click({
        [System.Windows.Forms.MessageBox]::Show(
            "$script:AppName $script:AppVersion`n`nEntwickelt von $script:AppPublisher`nVersion: $script:AppVersion`nDatum: $script:VersionDate`n`nEin umfassendes Werkzeug für System-Wartung und -Diagnose.",
            "Über System-Tool",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        )
    })
$infoButton.Add_MouseEnter({ $this.BackColor = [System.Drawing.Color]::SlateGray })
$infoButton.Add_MouseLeave({ $this.BackColor = [System.Drawing.Color]::DarkSlateGray })
[void]$titleBar.Controls.Add($infoButton)

# Einstellungen-Button
$settingsButton = New-Object System.Windows.Forms.Button
$settingsButton.Text = "⚙"
$settingsButton.Size = New-Object System.Drawing.Size(30, 30)
$settingsButton.Location = New-Object System.Drawing.Point(880, 0)  # Position angepasst da Theme-Button entfernt
$settingsButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$settingsButton.FlatAppearance.BorderSize = 0
$settingsButton.FlatAppearance.BorderColor = [System.Drawing.Color]::DarkSlateGray
$settingsButton.FlatAppearance.MouseDownBackColor = [System.Drawing.Color]::SlateGray
$settingsButton.BackColor = [System.Drawing.Color]::DarkSlateGray
$settingsButton.ForeColor = [System.Drawing.Color]::White
$settingsButton.Font = New-Object System.Drawing.Font("Segoe UI", 12)
$settingsButton.Add_Click({
        # Verwende die Funktion aus dem Settings-Modul, um den Einstellungsdialog anzuzeigen
        Show-SettingsDialog -MainForm $mainform -OutputBox $outputBox -MainPanels @{
            SystemPanel = $global:tblSystem
            DiskPanel = $tblDisk
            NetworkPanel = $tblNetwork
            CleanupPanel = $tblCleanup
            BtnSystem = $btnSystem
            BtnDisk = $btnDisk
            BtnNetwork = $btnNetwork
            BtnCleanup = $btnCleanup
        }
    })
$settingsButton.Add_MouseEnter({ $this.BackColor = [System.Drawing.Color]::SlateGray })
$settingsButton.Add_MouseLeave({ $this.BackColor = [System.Drawing.Color]::DarkSlateGray })
[void]$titleBar.Controls.Add($settingsButton)

# Titelleiste zum Formular hinzufügen
[void]$mainform.Controls.Add($titleBar)

# Fenster verschiebbar machen
# Event-Handler verwenden Closure-Variablen
$titleBar.Add_MouseDown({
        $script:titleBarLastLocation = [System.Windows.Forms.Cursor]::Position
    })

$titleBar.Add_MouseMove({
        if ($script:titleBarLastLocation -and [System.Windows.Forms.Control]::MouseButtons -eq 'Left') {
            $currentLocation = [System.Windows.Forms.Cursor]::Position
            $offset = New-Object System.Drawing.Point(
            ($currentLocation.X - $script:titleBarLastLocation.X),
            ($currentLocation.Y - $script:titleBarLastLocation.Y)
            )
            $mainform.Location = New-Object System.Drawing.Point(
            ($mainform.Location.X + $offset.X),
            ($mainform.Location.Y + $offset.Y)
            )
            $script:titleBarLastLocation = $currentLocation
        }
    })

$titleBar.Add_MouseUp({
        $script:titleBarLastLocation = $null
    })

# Hintergrund-Panel für die Hardware-Monitore
$monitorBackgroundPanel = New-Object System.Windows.Forms.Panel
$monitorBackgroundPanel.Location = New-Object System.Drawing.Point(0, 30)  # Von 20 auf 30 geändert
$monitorBackgroundPanel.Size = New-Object System.Drawing.Size(1000, 85)
$monitorBackgroundPanel.BackColor = [System.Drawing.Color]::FromArgb(20, 20, 20)  # Sehr dunkles Grau
$mainform.Controls.Add($monitorBackgroundPanel)
$monitorBackgroundPanel.SendToBack()  # Panel in den Hintergrund schicken

# Separate Panels für CPU, GPU und RAM direkt auf dem Hauptformular
$gbCPU = New-Object System.Windows.Forms.Panel
$gbCPU.Location = New-Object System.Drawing.Point(1, 35)  # Von 5 auf 35 geändert
$gbCPU.Size = New-Object System.Drawing.Size(340, 75)
$gbCPU.BackColor = [System.Drawing.Color]::FromArgb(35, 35, 38)  # Dunkles Grau
$mainform.Controls.Add($gbCPU)
$gbCPU.BringToFront()  # CPU-Panel in den Vordergrund

# Label für CPU-Titel
$lblCPUTitle = New-Object System.Windows.Forms.Label
$lblCPUTitle.Text = "CPU wird erkannt..."  # Wird später dynamisch aktualisiert
$lblCPUTitle.Location = New-Object System.Drawing.Point(0, 0)
$lblCPUTitle.Size = New-Object System.Drawing.Size(310, 20)  # Verkleinert für Debug-Button
$lblCPUTitle.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$lblCPUTitle.ForeColor = [System.Drawing.Color]::White
$lblCPUTitle.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)  # Etwas helleres Dunkelgrau
$gbCPU.Controls.Add($lblCPUTitle)

# Debug-Button für CPU
$btnCPUDebug = New-Object System.Windows.Forms.Button
$btnCPUDebug.Text = "D"
$btnCPUDebug.Location = New-Object System.Drawing.Point(310, 0)
$btnCPUDebug.Size = New-Object System.Drawing.Size(30, 20)
$btnCPUDebug.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnCPUDebug.FlatAppearance.BorderSize = 1
$btnCPUDebug.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(80, 80, 80)
$btnCPUDebug.BackColor = [System.Drawing.Color]::FromArgb(60, 60, 60)
$btnCPUDebug.ForeColor = [System.Drawing.Color]::LightGray
$btnCPUDebug.Font = New-Object System.Drawing.Font("Consolas", 9, [System.Drawing.FontStyle]::Bold)
$btnCPUDebug.Cursor = [System.Windows.Forms.Cursors]::Hand
$btnCPUDebug.FlatAppearance.MouseOverBackColor = [System.Drawing.Color]::FromArgb(80, 80, 80)
$btnCPUDebug.Add_Click({
    $currentState = Get-HardwareDebugState -Component 'CPU'
    $newState = -not $currentState
    Set-HardwareDebugMode -Component 'CPU' -Enabled $newState
    $this.BackColor = if ($newState) { [System.Drawing.Color]::FromArgb(0, 120, 215) } else { [System.Drawing.Color]::FromArgb(60, 60, 60) }
    $this.ForeColor = if ($newState) { [System.Drawing.Color]::White } else { [System.Drawing.Color]::LightGray }
    $statusText = if ($newState) { "aktiviert" } else { "deaktiviert" }
    Write-Host "CPU Debug-Modus $statusText" -ForegroundColor $(if ($newState) { "Green" } else { "Yellow" })
})
$gbCPU.Controls.Add($btnCPUDebug)

$gbGPU = New-Object System.Windows.Forms.Panel
$gbGPU.Location = New-Object System.Drawing.Point(341, 35)   # Von 5 auf 35 geändert
$gbGPU.Size = New-Object System.Drawing.Size(340, 75)
$gbGPU.BackColor = [System.Drawing.Color]::FromArgb(35, 35, 38)  # Dunkles Grau
$mainform.Controls.Add($gbGPU)
$gbGPU.BringToFront()  # GPU-Panel in den Vordergrund

# Label für GPU-Titel
$lblGPUTitle = New-Object System.Windows.Forms.Label
$lblGPUTitle.Text = "GPU wird erkannt..."  # Wird später dynamisch aktualisiert
$lblGPUTitle.Location = New-Object System.Drawing.Point(0, 0)
$lblGPUTitle.Size = New-Object System.Drawing.Size(310, 20)  # Verkleinert für Debug-Button
$lblGPUTitle.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$lblGPUTitle.ForeColor = [System.Drawing.Color]::White
$lblGPUTitle.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)  # Etwas helleres Dunkelgrau
$gbGPU.Controls.Add($lblGPUTitle)

# Debug-Button für GPU
$btnGPUDebug = New-Object System.Windows.Forms.Button
$btnGPUDebug.Text = "D"
$btnGPUDebug.Location = New-Object System.Drawing.Point(310, 0)
$btnGPUDebug.Size = New-Object System.Drawing.Size(30, 20)
$btnGPUDebug.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnGPUDebug.FlatAppearance.BorderSize = 1
$btnGPUDebug.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(80, 80, 80)
$btnGPUDebug.BackColor = [System.Drawing.Color]::FromArgb(60, 60, 60)
$btnGPUDebug.ForeColor = [System.Drawing.Color]::LightGray
$btnGPUDebug.Font = New-Object System.Drawing.Font("Consolas", 9, [System.Drawing.FontStyle]::Bold)
$btnGPUDebug.Cursor = [System.Windows.Forms.Cursors]::Hand
$btnGPUDebug.FlatAppearance.MouseOverBackColor = [System.Drawing.Color]::FromArgb(80, 80, 80)
$btnGPUDebug.Add_Click({
    $currentState = Get-HardwareDebugState -Component 'GPU'
    $newState = -not $currentState
    Set-HardwareDebugMode -Component 'GPU' -Enabled $newState
    $this.BackColor = if ($newState) { [System.Drawing.Color]::FromArgb(0, 120, 215) } else { [System.Drawing.Color]::FromArgb(60, 60, 60) }
    $this.ForeColor = if ($newState) { [System.Drawing.Color]::White } else { [System.Drawing.Color]::LightGray }
    $statusText = if ($newState) { "aktiviert" } else { "deaktiviert" }
    Write-Host "GPU Debug-Modus $statusText" -ForegroundColor $(if ($newState) { "Green" } else { "Yellow" })
})
$gbGPU.Controls.Add($btnGPUDebug)

$gbRAM = New-Object System.Windows.Forms.Panel
$gbRAM.Location = New-Object System.Drawing.Point(681, 35)   # Von 5 auf 35 geändert
$gbRAM.Size = New-Object System.Drawing.Size(345, 75)
$gbRAM.BackColor = [System.Drawing.Color]::FromArgb(35, 35, 38)  # Dunkles Grau
$mainform.Controls.Add($gbRAM)
$gbRAM.BringToFront()  # RAM-Panel in den Vordergrund

# Label für RAM-Titel
$lblRAMTitle = New-Object System.Windows.Forms.Label
$lblRAMTitle.Text = "RAM wird erkannt..."  # Wird später dynamisch aktualisiert
$lblRAMTitle.Location = New-Object System.Drawing.Point(0, 0)
$lblRAMTitle.Size = New-Object System.Drawing.Size(290, 20)  # Verkleinert für Debug-Button
$lblRAMTitle.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$lblRAMTitle.ForeColor = [System.Drawing.Color]::White
$lblRAMTitle.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)  # Etwas helleres Dunkelgrau
$gbRAM.Controls.Add($lblRAMTitle)

# Debug-Button für RAM
$btnRAMDebug = New-Object System.Windows.Forms.Button
$btnRAMDebug.Text = "D"
$btnRAMDebug.Location = New-Object System.Drawing.Point(290, 0)
$btnRAMDebug.Size = New-Object System.Drawing.Size(30, 20)
$btnRAMDebug.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnRAMDebug.FlatAppearance.BorderSize = 1
$btnRAMDebug.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(80, 80, 80)
$btnRAMDebug.BackColor = [System.Drawing.Color]::FromArgb(60, 60, 60)
$btnRAMDebug.ForeColor = [System.Drawing.Color]::LightGray
$btnRAMDebug.Font = New-Object System.Drawing.Font("Consolas", 9, [System.Drawing.FontStyle]::Bold)
$btnRAMDebug.Cursor = [System.Windows.Forms.Cursors]::Hand
$btnRAMDebug.FlatAppearance.MouseOverBackColor = [System.Drawing.Color]::FromArgb(80, 80, 80)
$btnRAMDebug.Add_Click({
    $currentState = Get-HardwareDebugState -Component 'RAM'
    $newState = -not $currentState
    Set-HardwareDebugMode -Component 'RAM' -Enabled $newState
    $this.BackColor = if ($newState) { [System.Drawing.Color]::FromArgb(0, 120, 215) } else { [System.Drawing.Color]::FromArgb(60, 60, 60) }
    $this.ForeColor = if ($newState) { [System.Drawing.Color]::White } else { [System.Drawing.Color]::LightGray }
    $statusText = if ($newState) { "aktiviert" } else { "deaktiviert" }
    Write-Host "RAM Debug-Modus $statusText" -ForegroundColor $(if ($newState) { "Green" } else { "Yellow" })
})
$gbRAM.Controls.Add($btnRAMDebug)

# Initialen Hardware-Namen setzen
try {
    # CPU-Name ermitteln
    $cpuInfo = Get-WmiObject -Class Win32_Processor | Select-Object -First 1
    if ($cpuInfo) {
        $lblCPUTitle.Text = "CPU: $($cpuInfo.Name)"
        $lblCPUTitle.Refresh()
    }

    # RAM-Info ermitteln
    $ramInfo = Get-WmiObject -Class Win32_PhysicalMemory | Select-Object Manufacturer, PartNumber, Speed, SMBIOSMemoryType
    if ($ramInfo -and $ramInfo.Count -gt 0) {
        $ramManufacturer = $ramInfo[0].Manufacturer.Trim()

        # Hersteller-Namen vereinfachen
        $ramManufacturer = switch -Regex ($ramManufacturer.ToUpper()) {
            "CORSAIR" { "Corsair" }
            "G\.?SKILL" { "G.Skill" }
            "KINGSTON" { "Kingston" }
            "CRUCIAL" { "Crucial" }
            "MICRON" { "Micron" }
            "SAMSUNG" { "Samsung" }
            "HYNIX|SK HYNIX" { "SK Hynix" }
            "TEAM" { "Team Group" }
            default { $ramManufacturer }
        }

        # Produktnamen aus PartNumber extrahieren
        $partNumber = $ramInfo[0].PartNumber.Trim()

        $productName = switch -Regex ($partNumber.ToUpper()) {
            "DOMINATOR|DOM|CMT" { "Dominator" }
            "VENGEANCE|VEN|CMK" { "Vengeance" }
            "TRIDENT|TZ|F5" { "Trident Z" }
            "RIPJAWS|RJ|F4" { "Ripjaws" }
            "FURY|FUR|KF" { "Fury" }
            "BALLISTIX|BL" { "Ballistix" }
            default {
                if ($partNumber -match '^[A-Za-z]+') {
                    $matches[0]
                }
                else {
                    ""
                }
            }
        }

        # DDR-Version ermitteln
        $ddrVersion = $null

        # Erste Methode: SMBIOSMemoryType
        if ($ramInfo[0].SMBIOSMemoryType) {
            $ddrVersion = switch ([int]$ramInfo[0].SMBIOSMemoryType) {
                34 { "DDR5" }  # Neuer Wert für DDR5
                24 { "DDR5" }  # Alter Wert für DDR5 (zur Sicherheit beibehalten)
                23 { "DDR4" }
                22 { "DDR3" }
                21 { "DDR2" }
                20 { "DDR" }
                default { $null }
            }
        }

        # Zweite Methode: PartNumber analysieren
        if (-not $ddrVersion) {
            if ($partNumber -match 'GX5') {
                $ddrVersion = "DDR5"
            }
            elseif ($partNumber -match 'DDR[2-5]') {
                $ddrVersion = $matches[0]
            }
        }

        # Dritte Methode: Win32_PhysicalMemory MemoryType
        if (-not $ddrVersion) {
            $memoryType = Get-WmiObject -Class Win32_PhysicalMemory | Select-Object -First 1 -ExpandProperty MemoryType
            $ddrVersion = switch ($memoryType) {
                34 { "DDR5" }
                26 { "DDR4" }
                24 { "DDR3" }
                default { $null }
            }
        }

        # Vierte Methode: Speichergeschwindigkeit analysieren
        if (-not $ddrVersion) {
            $speed = $ramInfo[0].Speed
            $ddrVersion = switch ($true) {
                ($speed -ge 4800) { "DDR5" }
                ($speed -ge 2133) { "DDR4" }
                ($speed -ge 1066) { "DDR3" }
                ($speed -ge 400) { "DDR2" }
                default { "DDR" }
            }
        }

        # RAM-Namen zusammensetzen
        $ramName = $ramManufacturer

        # Produktnamen nur hinzufügen, wenn er nicht leer ist und sich vom Hersteller unterscheidet
        if (![string]::IsNullOrEmpty($productName) -and $productName -ne $ramManufacturer) {
            $ramName += " $productName"
        }

        # DDR-Version immer hinzufügen
        if (![string]::IsNullOrEmpty($ddrVersion)) {
            $ramName += " $ddrVersion"
        }

        $lblRAMTitle.Text = "RAM: $ramName"
        $lblRAMTitle.Refresh()
    }
    else {
        # Fallback auf einfachere RAM-Erkennung
        $computerSystem = Get-WmiObject -Class Win32_ComputerSystem
        if ($computerSystem) {
            $totalRAM = [math]::Round($computerSystem.TotalPhysicalMemory / 1GB, 1)
            $lblRAMTitle.Text = "RAM: $totalRAM GB"
            $lblRAMTitle.Refresh()
        }
    }
}
catch {
    Write-Warning "Fehler beim Ermitteln der RAM-Informationen: $_"
    # Setze Standardwerte bei Fehler
    if (-not $lblRAMTitle.Text.StartsWith("RAM:")) { $lblRAMTitle.Text = "RAM: Wird erkannt..." }
}

# Hardware-Überwachung Labels
# CPU Hardware-Info Label
$cpuLabel = New-Object System.Windows.Forms.Label
$cpuLabel.Text = "CPU-Daten werden geladen..."
$cpuLabel.Location = New-Object System.Drawing.Point(1, 20)
$cpuLabel.Size = New-Object System.Drawing.Size(350, 45)
$cpuLabel.Font = New-Object System.Drawing.Font("Segoe UI Light", 15)  # Schlanke Schriftart
$cpuLabel.ForeColor = [System.Drawing.Color]::LimeGreen  # Helles Grün (Status-Indikator bleibt)
$cpuLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$cpuLabel.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)  # Dunkles Grau
$gbCPU.Controls.Add($cpuLabel)

# GPU Hardware-Info Label
$gpuLabel = New-Object System.Windows.Forms.Label
$gpuLabel.Text = "GPU-Daten werden geladen..."
$gpuLabel.Location = New-Object System.Drawing.Point(1, 20)
$gpuLabel.Size = New-Object System.Drawing.Size(347, 45)
$gpuLabel.Font = New-Object System.Drawing.Font("Segoe UI Light", 15)  # Schlanke Schriftart
$gpuLabel.ForeColor = [System.Drawing.Color]::DeepSkyBlue  # Helles Blau
$gpuLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$gpuLabel.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)  # Dunkles Grau
$gbGPU.Controls.Add($gpuLabel)

# RAM Hardware-Info Label
$ramLabel = New-Object System.Windows.Forms.Label
$ramLabel.Text = "RAM-Daten werden geladen..."
$ramLabel.Location = New-Object System.Drawing.Point(1, 20)
$ramLabel.Size = New-Object System.Drawing.Size(347, 45)
$ramLabel.Font = New-Object System.Drawing.Font("Segoe UI Light", 15)  # Schlanke Schriftart
$ramLabel.ForeColor = [System.Drawing.Color]::Orange  # Helles Orange
$ramLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$ramLabel.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)  # Dunkles Grau
$gbRAM.Controls.Add($ramLabel)

# Datenbank initialisieren vor der Hardware-Monitorinitialisierung
$null = Initialize-SystemDatabase

# Tooltip für bessere Benutzererfahrung hinzufügen - VOR Hardware-Initialisierung!
if (-not $tooltipObj) {
    $tooltipObj = New-Object System.Windows.Forms.ToolTip
    $tooltipObj.IsBalloon = $true
    $tooltipObj.ToolTipTitle = "Information"
    $tooltipObj.ToolTipIcon = [System.Windows.Forms.ToolTipIcon]::Info
    $tooltipObj.InitialDelay = 500
    $tooltipObj.AutoPopDelay = 5000
    # Aktivierung wird später nach vollständigem GUI-Laden durchgeführt
    
    # Setze auch als Script-Variable für globale Verfügbarkeit
    $script:globalTooltip = $tooltipObj
}

# ===================================================================
# HARDWARE-MONITORING INITIALISIERUNG
# ===================================================================

# Variable für Hardware-Init-Status
$script:HardwareMonitoringReady = $false

# Globale Variable für den Schließstatus
$script:isClosing = $false
$script:closeAttempts = 0
$script:maxCloseAttempts = 3

# Funktion zum Initialisieren der Log-Datei - nutzt ausschließlich das LogManager-System
function Initialize-LogFile {
    try {
        # Initialisiere das GUI-Closing-Log über das LogManager-System
        Initialize-GuiClosingLog
        Write-Verbose "GUI-Closing-Log erfolgreich über LogManager initialisiert"
        return $true
    }
    catch {
        Write-Warning "Fehler beim Initialisieren des GUI-Closing-Logs über LogManager: $_"
        return $false
    }
}

# Funktion zum Verwalten der Log-Datei - nutzt jetzt das LogManager-System
function Update-LogFile {
    param(
        [string]$Message,
        [switch]$IsError
    )

    try {
        # Bestimme den Log-Level basierend auf dem IsError-Parameter
        $level = if ($IsError) { 'Error' } else { 'Information' }
        
        # Verwende die globale Write-ToolLog Funktion (immer verfügbar, auch beim Schließen)
        if (Get-Command -Name Write-ToolLog -ErrorAction SilentlyContinue) {
            Write-ToolLog -ToolName "GUI-Closing" -Message $Message -Level $level
        }
        else {
            # Fallback: Direktes Schreiben in Log-Datei
            $logPath = Join-Path $PSScriptRoot "Data\Logs\GUI-Closing.log"
            $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            $logEntry = "$timestamp - [$level] $Message"
            [System.IO.File]::AppendAllText($logPath, "$logEntry`r`n", [System.Text.Encoding]::UTF8)
        }
        
        return $true
    }
    catch {
        # Fehler still ignorieren beim Schließen
        return $false
    }
}

# Funktion zum sicheren Schließen des Formulars
function Close-FormSafely {
    param (
        [System.Windows.Forms.Form]$Form
    )

    # Wenn wir bereits im Schließvorgang sind, nicht erneut durchführen
    if ($script:isClosing) {
        return
    }

    try {
        # Flag setzen, dass wir im Schließvorgang sind
        $script:isClosing = $true
        Write-Host "Close-FormSafely: Schließvorgang wird gestartet..."
        Update-LogFile -Message "Close-FormSafely: Schließvorgang gestartet"

        # Hardware-Monitoring stoppen
        if ($null -ne $script:hardwareTimer) {
            Write-Host "Close-FormSafely: Stoppe Hardware-Timer..."
            Update-LogFile -Message "Close-FormSafely: Hardware-Timer gestoppt"
            $script:hardwareTimer.Stop()
            $script:hardwareTimer.Dispose()
            $script:hardwareTimer = $null
        }

        # Datenbankverbindung schließen
        if ($null -ne $script:dbConnection) {
            Write-Host "Close-FormSafely: Schließe Datenbankverbindung..."
            Update-LogFile -Message "Close-FormSafely: Datenbankverbindung wird geschlossen"
            Close-SystemDatabase
        }

        # Controls deaktivieren
        Write-Host "Close-FormSafely: Deaktiviere Controls..."
        Update-LogFile -Message "Close-FormSafely: Controls deaktiviert"
        $Form.SuspendLayout()
        foreach ($control in $Form.Controls) {
            if ($null -ne $control) {
                $control.Enabled = $false
            }
        }

        # Garbage Collection
        Write-Host "Close-FormSafely: Führe Garbage Collection durch..."
        Update-LogFile -Message "Close-FormSafely: Garbage Collection durchgeführt"
        [System.GC]::Collect()
        [System.GC]::WaitForPendingFinalizers()

        # Direktes Beenden der Anwendung
        Write-Host "Close-FormSafely: Beende Anwendung..."
        Update-LogFile -Message "Close-FormSafely: Anwendung wird beendet"
        [System.Environment]::Exit(0)
    }
    catch {
        Write-Warning "Close-FormSafely: Fehler beim Schließen: $_"
        Update-LogFile -Message "Close-FormSafely: Fehler beim Schließen: $_" -IsError
        # Notfall-Beendigung
        [System.Environment]::Exit(0)
    }
}

# Funktion zum Neuladen der GUI
function Reload-GUI {
    param (
        [System.Windows.Forms.Form]$Form
    )

    # Wenn wir bereits im Reload sind, nicht erneut durchführen
    if ($script:isReloading) {
        return
    }

    try {
        # Flag setzen, dass wir im Reload-Vorgang sind
        $script:isReloading = $true
        Write-Host "Reload-GUI: GUI-Reload wird gestartet..."
        Update-LogFile -Message "Reload-GUI: GUI-Reload gestartet"

        # 1. Alle Timer stoppen
        Write-Host "Reload-GUI: Stoppe alle Timer..."
        Update-LogFile -Message "Reload-GUI: Alle Timer werden gestoppt"
        
        # Hardware-Timer stoppen
        if ($null -ne $script:hardwareTimer) {
            $script:hardwareTimer.Stop()
            $script:hardwareTimer.Dispose()
            $script:hardwareTimer = $null
        }

        # Statusleisten-Timer stoppen
        if ($null -ne $timer) {
            $timer.Stop()
            $timer.Dispose()
        }

        # Countdown-Timer stoppen (falls aktiv)
        if ($null -ne $script:countdownTimer) {
            $script:countdownTimer.Stop()
            $script:countdownTimer.Dispose()
            $script:countdownTimer = $null
        }

        # F12-Timer stoppen (falls aktiv)
        if ($null -ne $script:f12Timer) {
            $script:f12Timer.Stop()
            $script:f12Timer.Dispose()
            $script:f12Timer = $null
        }

        # Toggle-Timer stoppen (falls aktiv)
        if ($null -ne $script:toggleTimer) {
            $script:toggleTimer.Stop()
            $script:toggleTimer.Dispose()
            $script:toggleTimer = $null
        }

        # 2. Datenbankverbindung schließen
        if ($null -ne $script:dbConnection) {
            Write-Host "Reload-GUI: Schließe Datenbankverbindung..."
            Update-LogFile -Message "Reload-GUI: Datenbankverbindung wird geschlossen"
            Close-SystemDatabase
            $script:dbConnection = $null
        }

        # 3. Controls aufräumen
        Write-Host "Reload-GUI: Räume Controls auf..."
        Update-LogFile -Message "Reload-GUI: Controls werden aufgeräumt"
        $Form.SuspendLayout()
        
        # 4. Tool-Cache leeren
        Write-Host "Reload-GUI: Leere Tool-Cache..."
        Update-LogFile -Message "Reload-GUI: Tool-Cache wird geleert"
        Clear-ToolCacheOnExit

        # 5. Neuen PowerShell-Prozess starten BEVOR wir schließen
        Write-Host "Reload-GUI: Starte neuen GUI-Prozess..."
        Update-LogFile -Message "Reload-GUI: Neuer GUI-Prozess wird gestartet"
        
        # Aktuellen Skriptpfad ermitteln – Priorität:
        # 1. $PSCommandPath  (zuverlässig wenn per -File gestartet)
        # 2. $script:MyScriptPath  (falls beim Start gesichert)
        # 3. $PSScriptRoot  (Verzeichnis des Skripts – $MyInvocation.MyCommand.Path
        #    ist INNERHALB einer Funktion der Pfad der Funktion, NICHT des Skripts!)
        $reloadScriptPath = $PSCommandPath
        if ([string]::IsNullOrEmpty($reloadScriptPath) -and -not [string]::IsNullOrEmpty($script:MyScriptPath)) {
            $reloadScriptPath = $script:MyScriptPath
        }
        if ([string]::IsNullOrEmpty($reloadScriptPath) -and -not [string]::IsNullOrEmpty($PSScriptRoot)) {
            $reloadScriptPath = Join-Path $PSScriptRoot "Win_Gui_Module.ps1"
        }
        
        if ([string]::IsNullOrEmpty($reloadScriptPath) -or -not (Test-Path $reloadScriptPath)) {
            throw "Reload-GUI: Skriptpfad konnte nicht ermittelt werden ('$reloadScriptPath'). Bitte neu starten."
        }
        
        Write-Host "Reload-GUI: Skriptpfad -> $reloadScriptPath"
        Update-LogFile -Message "Reload-GUI: Skriptpfad -> $reloadScriptPath"

        # Explizit Windows PowerShell 5.1 verwenden (identisch mit dem BAT-Launcher)
        $ps51Path = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"
        if (-not (Test-Path $ps51Path)) {
            $ps51Path = "powershell.exe"   # Fallback
        }

        # Neuen Prozess MIT Admin-Rechten starten (Verb RunAs), damit kein
        # doppelter UAC-Prompt durch den Test-Admin-Check im Skript entsteht
        $processStartInfo = New-Object System.Diagnostics.ProcessStartInfo
        $processStartInfo.FileName        = $ps51Path
        $processStartInfo.Arguments       = "-NoProfile -ExecutionPolicy Bypass -File `"$reloadScriptPath`""
        $processStartInfo.UseShellExecute = $true
        $processStartInfo.Verb            = "RunAs"   # Admin-Rechte direkt anfordern
        $processStartInfo.WorkingDirectory = Split-Path -Parent $reloadScriptPath
        
        try {
            $newProcess = [System.Diagnostics.Process]::Start($processStartInfo)
            Write-Host "Reload-GUI: Neuer Prozess gestartet (PID: $($newProcess.Id))"
            Update-LogFile -Message "Reload-GUI: Neuer Prozess gestartet (PID: $($newProcess.Id))"
        }
        catch {
            Write-Warning "Reload-GUI: Fehler beim Starten des neuen Prozesses: $_"
            Update-LogFile -Message "Reload-GUI: Fehler beim Starten des neuen Prozesses: $_" -IsError
            throw
        }

        # 6. Kurze Verzögerung, damit der neue Prozess starten kann
        Start-Sleep -Milliseconds 500

        # 7. Garbage Collection
        Write-Host "Reload-GUI: Führe Garbage Collection durch..."
        Update-LogFile -Message "Reload-GUI: Garbage Collection durchgeführt"
        [System.GC]::Collect()
        [System.GC]::WaitForPendingFinalizers()

        # 8. Formular schließen
        Write-Host "Reload-GUI: Schließe Formular..."
        Update-LogFile -Message "Reload-GUI: Formular wird geschlossen"
        
        # Flag zurücksetzen vor dem Schließen
        $script:isClosing = $false
        $script:isReloading = $false
        
        # Formular schließen und Prozess beenden
        $Form.Close()
        $Form.Dispose()
        
        # Aktuellen Prozess beenden
        [System.Environment]::Exit(0)
    }
    catch {
        Write-Warning "Reload-GUI: Fehler beim Reload: $_"
        Update-LogFile -Message "Reload-GUI: Fehler beim Reload: $_" -IsError
        $script:isReloading = $false
        
        # Im Fehlerfall Messagebox anzeigen
        [System.Windows.Forms.MessageBox]::Show(
            "Fehler beim Neuladen der GUI: $_`n`nBitte starten Sie die Anwendung manuell neu.",
            "GUI-Reload Fehler",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
    }
}

# Event-Handler für FormClosing
$mainform.Add_FormClosing({
        param($formSender, $e)

        # Protokollieren des Schließversuchs
        Write-Host "Schließvorgang wird gestartet..."
        # Log-Eintrag für Schließvorgang
        Update-LogFile -Message "Anwendung wird geschlossen"

        # Wenn wir bereits im Schließvorgang sind, nicht erneut durchführen
        if ($script:isClosing) {
            return
        }

        # Fenstergröße und Position speichern mit der Funktion aus dem Settings-Modul
        Export-WindowPosition -MainForm $mainform -ConfigPath "$PSScriptRoot\config.json"
        Update-LogFile -Message "Fensterposition wurde gespeichert"

        # Schließvorgang verhindern für normale Verarbeitung
        $e.Cancel = $true

        try {
            # Flag setzen, dass wir im Schließvorgang sind
            $script:isClosing = $true
            Update-LogFile -Message "Schließvorgang initiiert"

            # Hardware-Monitoring stoppen
            if ($null -ne $script:hardwareTimer) {
                Write-Host "Stoppe Hardware-Timer..."
                Update-LogFile -Message "Hardware-Timer wurde gestoppt"
                $script:hardwareTimer.Stop()
                $script:hardwareTimer.Dispose()
                $script:hardwareTimer = $null
            }

            # Controls deaktivieren
            Write-Host "Deaktiviere Controls..."
            $formSender.SuspendLayout()
            foreach ($control in $formSender.Controls) {
                if ($null -ne $control) {
                    $control.Enabled = $false
                }
            }

            # Tool-Cache leeren
            Write-Host "Leere Tool-Cache..."
            Update-LogFile -Message "Tool-Cache wurde geleert"
            Clear-ToolCacheOnExit

            # Garbage Collection
            Write-Host "Führe Garbage Collection durch..."
            Update-LogFile -Message "Garbage Collection durchgeführt"
            [System.GC]::Collect()
            [System.GC]::WaitForPendingFinalizers()

            # Direktes Beenden mit System.Environment.Exit(0)
            Write-Host "Beende Anwendung..."
            Update-LogFile -Message "Anwendung wurde ordnungsgemäß beendet"
            [System.Environment]::Exit(0)
        }
        catch {
            Write-Warning "Fehler beim Schließen: $_"
            Update-LogFile -Message "Fehler beim Schließen: $_" -IsError
            # Notfall-Beendigung
            [System.Environment]::Exit(0)
        }
    })

# Event-Handler für Form-Bewegung, um PowerShell-Konsole auszublenden
$mainform.Add_LocationChanged({
        try {
            if ($mainform.Visible -and $mainform.WindowState -ne [System.Windows.Forms.FormWindowState]::Minimized) {
                # Wenn Konsole sichtbar ist, sie ausblenden
                if ([ConsoleHelper]::IsConsoleVisible()) {
                    [ConsoleHelper]::HideConsole()
                    $script:consoleAutoHidden = $true
                    
                    # Button-Status aktualisieren
                    if ($btnToggleConsole) {
                        $btnToggleConsole.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
                        $btnToggleConsole.Text = "►"
                    }
                }
            }
        }
        catch {
            # Fehler beim Ausblenden ignorieren
        }
    })

# ================================================
# ++++++++++++++++ Button-Panels +++++++++++++++++
# ================================================

# Erstelle ein separates Panel für den Ausgabe-Button 
$outputButtonPanel = New-Object System.Windows.Forms.Panel
$outputButtonPanel.Location = New-Object System.Drawing.Point(3, 125)  
$outputButtonPanel.Size = New-Object System.Drawing.Size(225, 45)  
$outputButtonPanel.BackColor = [System.Drawing.Color]::Transparent
$mainform.Controls.Add($outputButtonPanel)

# Erstelle eine Button-Leiste für die Hauptnavigation (vertikal) 
$mainButtonPanel = New-Object System.Windows.Forms.Panel
$mainButtonPanel.Location = New-Object System.Drawing.Point(3, 175)  
$mainButtonPanel.Size = New-Object System.Drawing.Size(217, 445)  
$mainButtonPanel.BackColor = [System.Drawing.Color]::Transparent
$mainform.Controls.Add($mainButtonPanel)

# Erstelle separates Panel für Neustart-Button (unterhalb mainButtonPanel)
$restartButtonPanel = New-Object System.Windows.Forms.Panel
$restartButtonPanel.Location = New-Object System.Drawing.Point(3, 630)  # Kurz vor unterem Rand
$restartButtonPanel.Size = New-Object System.Drawing.Size(217, 190)
$restartButtonPanel.BackColor = [System.Drawing.Color]::Transparent
$mainform.Controls.Add($restartButtonPanel)

#------------------------------------------------------------------------------------------------------------

# Erstelle ein Panel für die verschiedenen Hauptinhalte 
$mainContentPanel = New-Object System.Windows.Forms.Panel
$mainContentPanel.Location = New-Object System.Drawing.Point(220, 125)  
$mainContentPanel.Size = New-Object System.Drawing.Size(775, 48)  
$mainContentPanel.BackColor = [System.Drawing.Color]::Transparent
$mainform.Controls.Add($mainContentPanel)

# Suchfeld-Panel für Downloads (im mainContentPanel, oberhalb der Tool-Buttons)
$searchPanel = New-Object System.Windows.Forms.Panel
$searchPanel.Location = New-Object System.Drawing.Point(0, 0)
$searchPanel.Size = New-Object System.Drawing.Size(735, 50)
$searchPanel.BackColor = [System.Drawing.Color]::FromArgb(37, 37, 38)
$searchPanel.Visible = $false  # Standardmäßig ausgeblendet
$mainContentPanel.Controls.Add($searchPanel)

# View-Größen-Buttons (Rechts im Search-Panel)
$script:currentTileSize = "Medium"  # Default: Medium

$viewButtonSize = New-Object System.Drawing.Size(35, 25)
$viewButtonY = 12
$viewButtonX = 695

# Kleine Kachel Button
$btnLargeTiles = New-Object System.Windows.Forms.Button
$btnLargeTiles.Location = New-Object System.Drawing.Point(($viewButtonX - 80), $viewButtonY)
$btnLargeTiles.Size = $viewButtonSize
$btnLargeTiles.Text = "·"
$btnLargeTiles.Font = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
$btnLargeTiles.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnLargeTiles.FlatAppearance.BorderSize = 1
$btnLargeTiles.FlatAppearance.BorderColor = [System.Drawing.Color]::Gray
$btnLargeTiles.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
$btnLargeTiles.ForeColor = [System.Drawing.Color]::White
$btnLargeTiles.Cursor = [System.Windows.Forms.Cursors]::Hand
$btnLargeTiles.Add_Click({
    # Nur ausführen, wenn eine Kategorie gewählt wurde
    if ([string]::IsNullOrWhiteSpace($script:currentDownloadCategory)) {
        return
    }
    $script:currentTileSize = "Large"
    Update-TileViewButtons
    $null = Update-ToolsDisplay -WrapPanel $toolWrapPanel -Category $script:currentDownloadCategory -MainProgressBar $progressBar -SearchQuery $searchTextBox.Text -TileSize $script:currentTileSize -ShowOnlyUpdates $script:showOnlyUpdates
})
$tooltipObj.SetToolTip($btnLargeTiles, "Große Kacheln")
$searchPanel.Controls.Add($btnLargeTiles)

# Mittlere Kachel Button
$btnMediumTiles = New-Object System.Windows.Forms.Button
$btnMediumTiles.Location = New-Object System.Drawing.Point(($viewButtonX - 40), $viewButtonY)
$btnMediumTiles.Size = $viewButtonSize
$btnMediumTiles.Text = "▪▪"
$btnMediumTiles.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$btnMediumTiles.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnMediumTiles.FlatAppearance.BorderSize = 1
$btnMediumTiles.FlatAppearance.BorderColor = [System.Drawing.Color]::Gray
$btnMediumTiles.BackColor = [System.Drawing.Color]::FromArgb(0, 122, 204)
$btnMediumTiles.ForeColor = [System.Drawing.Color]::White
$btnMediumTiles.Cursor = [System.Windows.Forms.Cursors]::Hand
$btnMediumTiles.Add_Click({
    # Nur ausführen, wenn eine Kategorie gewählt wurde
    if ([string]::IsNullOrWhiteSpace($script:currentDownloadCategory)) {
        return
    }
    $script:currentTileSize = "Medium"
    Update-TileViewButtons
    $null = Update-ToolsDisplay -WrapPanel $toolWrapPanel -Category $script:currentDownloadCategory -MainProgressBar $progressBar -SearchQuery $searchTextBox.Text -TileSize $script:currentTileSize -ShowOnlyUpdates $script:showOnlyUpdates
})
$tooltipObj.SetToolTip($btnMediumTiles, "Mittlere Kacheln (Standard)")
$searchPanel.Controls.Add($btnMediumTiles)

# Listen-Ansicht Button
$btnListView = New-Object System.Windows.Forms.Button
$btnListView.Location = New-Object System.Drawing.Point($viewButtonX, $viewButtonY)
$btnListView.Size = $viewButtonSize
$btnListView.Text = "≡"
$btnListView.Font = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
$btnListView.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnListView.FlatAppearance.BorderSize = 1
$btnListView.FlatAppearance.BorderColor = [System.Drawing.Color]::Gray
$btnListView.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
$btnListView.ForeColor = [System.Drawing.Color]::White
$btnListView.Cursor = [System.Windows.Forms.Cursors]::Hand
$btnListView.Add_Click({
    # Nur ausführen, wenn eine Kategorie gewählt wurde
    if ([string]::IsNullOrWhiteSpace($script:currentDownloadCategory)) {
        return
    }
    $script:currentTileSize = "List"
    Update-TileViewButtons
    $null = Update-ToolsDisplay -WrapPanel $toolWrapPanel -Category $script:currentDownloadCategory -MainProgressBar $progressBar -SearchQuery $searchTextBox.Text -TileSize $script:currentTileSize -ShowOnlyUpdates $script:showOnlyUpdates
})
$tooltipObj.SetToolTip($btnListView, "Listen-Ansicht")
$searchPanel.Controls.Add($btnListView)

# Funktion zum Aktualisieren der View-Button-Hervorhebung
function Update-TileViewButtons {
    $activeColor = [System.Drawing.Color]::FromArgb(0, 122, 204)
    $inactiveColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
    
    $btnLargeTiles.BackColor = if ($script:currentTileSize -eq "Large") { $activeColor } else { $inactiveColor }
    $btnMediumTiles.BackColor = if ($script:currentTileSize -eq "Medium") { $activeColor } else { $inactiveColor }
    $btnListView.BackColor = if ($script:currentTileSize -eq "List") { $activeColor } else { $inactiveColor }
}

# Suchfeld-Label
$searchLabel = New-Object System.Windows.Forms.Label
$searchLabel.Text = "Suche:"
$searchLabel.Location = New-Object System.Drawing.Point(10, 15)
$searchLabel.Size = New-Object System.Drawing.Size(60, 20)
$searchLabel.ForeColor = [System.Drawing.Color]::White
$searchLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$searchPanel.Controls.Add($searchLabel)

# Suchfeld-TextBox
$searchTextBox = New-Object System.Windows.Forms.TextBox
$searchTextBox.Location = New-Object System.Drawing.Point(75, 12)
$searchTextBox.Size = New-Object System.Drawing.Size(300, 25)
$searchTextBox.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$searchTextBox.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
$searchTextBox.ForeColor = [System.Drawing.Color]::White
$searchTextBox.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
$searchPanel.Controls.Add($searchTextBox)

# Clear-Button für Suchfeld
$searchClearButton = New-Object System.Windows.Forms.Button
$searchClearButton.Text = "✕"
$searchClearButton.Location = New-Object System.Drawing.Point(380, 12)
$searchClearButton.Size = New-Object System.Drawing.Size(30, 25)
$searchClearButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$searchClearButton.FlatAppearance.BorderSize = 0
$searchClearButton.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
$searchClearButton.ForeColor = [System.Drawing.Color]::White
$searchClearButton.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$searchClearButton.Add_Click({
    $searchTextBox.Text = ""
    $searchTextBox.Focus()
})
$searchPanel.Controls.Add($searchClearButton)

# Filter-Button für Updates
$script:showOnlyUpdates = $false
$btnFilterUpdates = New-Object System.Windows.Forms.Button
$btnFilterUpdates.Text = "⬆ Updates"
$btnFilterUpdates.Location = New-Object System.Drawing.Point(420, 12)
$btnFilterUpdates.Size = New-Object System.Drawing.Size(90, 25)
$btnFilterUpdates.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnFilterUpdates.FlatAppearance.BorderSize = 1
$btnFilterUpdates.FlatAppearance.BorderColor = [System.Drawing.Color]::Gray
$btnFilterUpdates.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
$btnFilterUpdates.ForeColor = [System.Drawing.Color]::White
$btnFilterUpdates.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$btnFilterUpdates.Cursor = [System.Windows.Forms.Cursors]::Hand
$btnFilterUpdates.Add_Click({
    # Nur ausführen, wenn eine Kategorie gewählt wurde
    if ([string]::IsNullOrWhiteSpace($script:currentDownloadCategory)) {
        return
    }
    $script:showOnlyUpdates = -not $script:showOnlyUpdates
    $this.BackColor = if ($script:showOnlyUpdates) { [System.Drawing.Color]::FromArgb(255, 140, 0) } else { [System.Drawing.Color]::FromArgb(43, 43, 43) }
    $null = Update-ToolsDisplay -WrapPanel $toolWrapPanel -Category $script:currentDownloadCategory -MainProgressBar $progressBar -SearchQuery $searchTextBox.Text -TileSize $script:currentTileSize -ShowOnlyUpdates $script:showOnlyUpdates
})
$tooltipObj.SetToolTip($btnFilterUpdates, "Nur Tools mit verfügbaren Updates anzeigen")
$searchPanel.Controls.Add($btnFilterUpdates)

# Info-Text für Suchergebnisse
$searchResultLabel = New-Object System.Windows.Forms.Label
$searchResultLabel.Location = New-Object System.Drawing.Point(520, 15)
$searchResultLabel.Size = New-Object System.Drawing.Size(200, 20)
$searchResultLabel.ForeColor = [System.Drawing.Color]::Gray
$searchResultLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$searchResultLabel.Text = ""
$searchPanel.Controls.Add($searchResultLabel)

# Hilfsfunktion zum Aktualisieren aller Kategorie-Zähler
function Update-CategoryCounts {
    param([string]$SearchQuery = "")
    
    # Importiere ToolLibrary falls nicht geladen
    if (-not (Get-Command -Name Get-ToolsByCategory -ErrorAction SilentlyContinue)) {
        Import-Module "$PSScriptRoot\Modules\ToolLibrary.psm1" -Force
    }
    
    # Hilfsfunktion zum Zählen der Tools mit Suchfilter
    $countToolsWithSearch = {
        param($category, $search)
        
        # Tools nach Kategorie laden
        if ($category -eq "all") {
            $tools = Get-AllTools
        } else {
            $tools = Get-ToolsByCategory -Category $category
        }
        
        # Wenn Suche leer oder zu kurz, alle Tools zählen
        if ([string]::IsNullOrWhiteSpace($search) -or $search.Length -lt 3) {
            return $tools.Count
        }
        
        # Suchfilter anwenden (gleiche Logik wie in Update-ToolsDisplay)
        $searchLower = $search.ToLower()
        $matchesWordStart = {
            param($text, $pattern)
            if ([string]::IsNullOrWhiteSpace($text)) { return $false }
            $textLower = $text.ToLower()
            if ($textLower.StartsWith($pattern)) { return $true }
            if ($textLower -match "[\s\-/\(]$pattern") { return $true }
            if ($text -and $text -cmatch "[A-Z]$pattern") { return $true }
            if ($textLower -match "\d$pattern") { return $true }
            return $false
        }
        
        $filtered = @($tools | Where-Object {
            (& $matchesWordStart $_.Name $searchLower) -or
            (& $matchesWordStart $_.Description $searchLower) -or
            ($_.Tags -and ($_.Tags | Where-Object { & $matchesWordStart $_ $searchLower }).Count -gt 0) -or
            (& $matchesWordStart $_.Category $searchLower)
        })
        
        return $filtered.Count
    }
    
    # Alle Kategorien aktualisieren
    $allCount = & $countToolsWithSearch "all" $SearchQuery
    $systemCount = & $countToolsWithSearch "system" $SearchQuery
    $appsCount = & $countToolsWithSearch "applications" $SearchQuery
    $audiotvCount = & $countToolsWithSearch "audiotv" $SearchQuery
    $codingCount = & $countToolsWithSearch "coding" $SearchQuery
    
    # Labels aktualisieren
    $lblAllToolsCount.Text = "($allCount)"
    $lblSystemToolsCount.Text = "($systemCount)"
    $lblApplicationsCount.Text = "($appsCount)"
    $lblAudioTVCount.Text = "($audiotvCount)"
    $lblCodingToolsCount.Text = "($codingCount)"
}

# TextChanged-Event für Echtzeit-Suche
$searchTextBox.Add_TextChanged({
    # Nur ausführen, wenn eine Kategorie gewählt wurde
    if ([string]::IsNullOrWhiteSpace($script:currentDownloadCategory)) {
        return
    }
    
    $searchQuery = $searchTextBox.Text
    
    # Aktualisiere Suchergebnis-Label und Tool-Anzeige
    if ([string]::IsNullOrWhiteSpace($searchQuery)) {
        $searchResultLabel.Text = ""
        # Zeige alle Tools ohne Filter
        $resultCount = Update-ToolsDisplay -WrapPanel $toolWrapPanel -Category $script:currentDownloadCategory -MainProgressBar $progressBar -SearchQuery "" -TileSize $script:currentTileSize -ShowOnlyUpdates $script:showOnlyUpdates
    }
    elseif ($searchQuery.Length -lt 3) {
        # Zu kurzer Suchbegriff
        $searchResultLabel.Text = "Mindestens 3 Zeichen eingeben"
        $searchResultLabel.ForeColor = [System.Drawing.Color]::Orange
        # Übergebe den aktuellen Suchbegriff, damit Update-ToolsDisplay die Tools ausblendet
        $resultCount = Update-ToolsDisplay -WrapPanel $toolWrapPanel -Category $script:currentDownloadCategory -MainProgressBar $progressBar -SearchQuery $searchQuery -TileSize $script:currentTileSize -ShowOnlyUpdates $script:showOnlyUpdates
    }
    else {
        # Suche mit mindestens 3 Zeichen
        $resultCount = Update-ToolsDisplay -WrapPanel $toolWrapPanel -Category $script:currentDownloadCategory -MainProgressBar $progressBar -SearchQuery $searchQuery -TileSize $script:currentTileSize -ShowOnlyUpdates $script:showOnlyUpdates
        
        if ($resultCount -eq 0) {
            $searchResultLabel.Text = "Keine Ergebnisse gefunden"
            $searchResultLabel.ForeColor = [System.Drawing.Color]::Salmon
        }
        elseif ($resultCount -eq 1) {
            $searchResultLabel.Text = "1 Tool gefunden"
            $searchResultLabel.ForeColor = [System.Drawing.Color]::LightGreen
        }
        else {
            $searchResultLabel.Text = "$resultCount Tools gefunden"
            $searchResultLabel.ForeColor = [System.Drawing.Color]::LightGreen
        }
    }
    
    # Aktualisiere Kategorie-Zähler
    Update-CategoryCounts -SearchQuery $searchQuery
})

# ------------------------------------------------------------------------------------------------------------

# Farbdefinitionen für dunkles Theme 
# Explizite Farbe für Unternavigationsbuttons für konsistentes Aussehen
$script:btnSubNavColor = [System.Drawing.Color]::FromArgb(45, 45, 48)

# ================================================
# +++++++++++++ Dropdown-Panel-Menüs +++++++++++++
# ================================================

# Hilfsfunktion für zusammenklappbare Panels
function New-CollapsiblePanel {
    param(
        [string]$Title,
        [int]$YPosition,
        [string]$Tag,
        [System.Windows.Forms.Panel]$ParentPanel,
        [scriptblock]$OnExpand,
        [switch]$OpenUpward,
        [int]$IconCode = 0
    )
    
    # Container für den gesamten zusammenklappbaren Bereich
    $container = New-Object System.Windows.Forms.Panel
    $container.Location = New-Object System.Drawing.Point(5, $YPosition)
    $container.Size = New-Object System.Drawing.Size(210, 35)  # Initial nur Header sichtbar
    $container.BackColor = [System.Drawing.Color]::Transparent
    $container.Tag = $Tag
    
    # Speichere ursprüngliche Y-Position als Property für OpenUpward-Panels
    if ($OpenUpward) {
        Add-Member -InputObject $container -MemberType NoteProperty -Name "OriginalY" -Value $YPosition
    }
    
    # Header-Button (mit Icon und Text)
    $headerBtn = New-Object System.Windows.Forms.Button
    $headerBtn.Text = $Title  # Nur der Titel
    $headerBtn.Size = New-Object System.Drawing.Size(210, 35)
    
    # Beim Aufwärtsöffnen beginnt der Header am unteren Rand des Containers
    if ($OpenUpward) {
        $headerBtn.Location = New-Object System.Drawing.Point(0, 0)
    } else {
        $headerBtn.Location = New-Object System.Drawing.Point(0, 0)
    }
    
    $headerBtn.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $headerBtn.BackColor = [System.Drawing.Color]::FromArgb(37, 37, 38)  # Dunkleres Grau wie im Screenshot
    $headerBtn.ForeColor = [System.Drawing.Color]::White
    $headerBtn.FlatAppearance.BorderSize = 0
    $headerBtn.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $headerBtn.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
    $headerBtn.Padding = New-Object System.Windows.Forms.Padding(5, 0, 25, 0)  # Rechts Platz für Pfeil
    $headerBtn.Tag = "collapsed"
    
    # Icon hinzufügen, wenn IconCode angegeben
    if ($IconCode -ne 0) {
        Add-ButtonIcon -Button $headerBtn -IconCode $IconCode -IconSize 12 -LeftMargin 10
    }
    
    # Runde Ecken für Header-Button (8px Radius wie im Screenshot)
    try {
        $regionHandle = [RoundedCorners]::CreateRoundRectRgn(0, 0, $headerBtn.Width, $headerBtn.Height, 8, 8)
        if ($regionHandle -ne [IntPtr]::Zero) {
            $headerBtn.Region = [System.Drawing.Region]::FromHrgn($regionHandle)
        }
    } catch {
        # Falls runde Ecken nicht funktionieren, einfach ohne weitermachen
    }
    
    # Pfeil-Label (rechts im Button)
    $arrowLabel = New-Object System.Windows.Forms.Label
    $arrowLabel.Text = "▼"
    $arrowLabel.Size = New-Object System.Drawing.Size(15, 20)
    $arrowLabel.Location = New-Object System.Drawing.Point(190, 7.5)  # Rechts im Button
    $arrowLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    $arrowLabel.BackColor = [System.Drawing.Color]::Transparent
    $arrowLabel.ForeColor = [System.Drawing.Color]::White
    $arrowLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Regular)
    $arrowLabel.Tag = "arrow"
    # Klicks sollen durch das Label zum Button durchgehen
    $arrowLabel.Add_MouseDown({
        param($s, $e)
        $this.Parent.PerformClick()
    })
    $headerBtn.Controls.Add($arrowLabel)
    
    # Content-Panel (zunächst versteckt)
    $contentPanel = New-Object System.Windows.Forms.Panel
    
    if ($OpenUpward) {
        # Beim Aufwärtsöffnen wird der Content ÜBER dem Header positioniert
        $contentPanel.Location = New-Object System.Drawing.Point(0, 0)
    } else {
        # Standard: Content UNTER dem Header
        $contentPanel.Location = New-Object System.Drawing.Point(0, 35)
    }
    
    $contentPanel.Size = New-Object System.Drawing.Size(210, 0)  # Höhe wird dynamisch angepasst
    $contentPanel.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)  # Noch dunkler für Content
    $contentPanel.Visible = $false
    
   
    # Toggle-Funktion mit Closure für Variable-Zugriff
    $clickHandler = {
        param($eventSender, $e)
        
        if ($this.Tag -eq "collapsed") {
            # Zuerst alle anderen Panels im gleichen Parent zuklappen
            $currentTag = $this.Parent.Tag
            foreach ($ctrl in $ParentPanel.Controls) {
                if ($ctrl -is [System.Windows.Forms.Panel] -and $ctrl.Tag -ne $currentTag) {
                    $otherHeader = $ctrl.Controls[0]
                    $otherContent = $ctrl.Controls[1]
                    
                    if ($otherHeader.Tag -eq "expanded") {
                        # Pfeil-Label des anderen Headers ändern
                        $otherArrow = $otherHeader.Controls | Where-Object { $_.Tag -eq "arrow" }
                        if ($otherArrow) { $otherArrow.Text = "▼" }
                        $otherHeader.Tag = "collapsed"
                        $otherContent.Visible = $false
                        $ctrl.Height = 35
                    }
                }
            }
            
            # Dann aktuelles Panel ausklappen
            # Pfeil-Label finden und ändern
            $arrow = $this.Controls | Where-Object { $_.Tag -eq "arrow" }
            if ($arrow) { $arrow.Text = "▲" }
            $this.Tag = "expanded"
            $this.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)  # Etwas heller wenn ausgeklappt
            
            # Content-Panel finden (zweites Control im Container)
            $contentPnl = $this.Parent.Controls[1]
            $contentPnl.Visible = $true
            
            # Beim Aufwärtsöffnen: Container nach oben verschieben, Header nach unten, Content oben
            if ($OpenUpward) {
                # Verwende gespeicherte OriginalY-Position
                $originalY = if ($this.Parent.OriginalY) { $this.Parent.OriginalY } else { $this.Parent.Location.Y }
                
                # Verschiebe Container nach oben um Content-Höhe
                $newY = $originalY - $contentPnl.Height
                $this.Parent.Location = New-Object System.Drawing.Point($this.Parent.Location.X, $newY)
                
                # Header nach unten, Content oben
                $headerBtn = $this.Parent.Controls[0]
                $headerBtn.Location = New-Object System.Drawing.Point(0, $contentPnl.Height)
                $contentPnl.Location = New-Object System.Drawing.Point(0, 0)
            }
            
            # Runde Ecken für Content-Panel setzen (untere Ecken)
            if ($contentPnl.Height -gt 0) {
                try {
                    $regionHandle = [RoundedCorners]::CreateRoundRectRgn(0, 0, $contentPnl.Width, $contentPnl.Height, 8, 8)
                    if ($regionHandle -ne [IntPtr]::Zero) {
                        $contentPnl.Region = [System.Drawing.Region]::FromHrgn($regionHandle)
                    }
                } catch {
                    # Falls runde Ecken nicht funktionieren, einfach ohne weitermachen
                }
            }
            
            # Container-Höhe anpassen
            $this.Parent.Height = 35 + $contentPnl.Height
            
            # OnExpand-Callback ausführen
            if ($OnExpand) {
                & $OnExpand
            }
            
            # Y-Positionen der nachfolgenden Panels anpassen
            Update-PanelPositions -ParentPanel $ParentPanel
        }
        else {
            # Zuklappen
            # Pfeil-Label finden und ändern
            $arrow = $this.Controls | Where-Object { $_.Tag -eq "arrow" }
            if ($arrow) { $arrow.Text = "▼" }
            $this.Tag = "collapsed"
            $this.BackColor = [System.Drawing.Color]::FromArgb(37, 37, 38)  # Zurück zu dunkler
            
            # Content-Panel finden
            $contentPnl = $this.Parent.Controls[1]
            $contentPnl.Visible = $false
            
            # Beim Aufwärtsöffnen: Container und Header zurück an ursprüngliche Position
            if ($OpenUpward) {
                # Hole ursprüngliche Y-Position aus Property
                if ($this.Parent.OriginalY) {
                    $this.Parent.Location = New-Object System.Drawing.Point($this.Parent.Location.X, $this.Parent.OriginalY)
                }
                
                # Header zurück an Anfang
                $headerBtn = $this.Parent.Controls[0]
                $headerBtn.Location = New-Object System.Drawing.Point(0, 0)
            }
            
            $this.Parent.Height = 35
            
            # MainContentPanel ausblenden basierend auf dem zugeklappten Panel
            $panelTag = $this.Parent.Tag
            if ($panelTag -eq "systemPanel" -and $global:tblSystem) {
                $global:tblSystem.Visible = $false
            }
            elseif ($panelTag -eq "diskPanel" -and $tblDisk) {
                $tblDisk.Visible = $false
            }
            elseif ($panelTag -eq "networkPanel" -and $tblNetwork) {
                $tblNetwork.Visible = $false
            }
            elseif ($panelTag -eq "cleanupPanel" -and $tblCleanup) {
                $tblCleanup.Visible = $false
            }
            elseif ($panelTag -eq "smartRepairPanel" -and $global:tblSmartRepair) {
                $global:tblSmartRepair.Visible = $false
            }
            elseif ($panelTag -eq "infoPanel") {
                # Info-Panel View-Panels ausblenden
                if ($outputViewPanel) { $outputViewPanel.Visible = $false }
                if ($statusViewPanel) { $statusViewPanel.Visible = $false }
                if ($hardwareViewPanel) { $hardwareViewPanel.Visible = $false }
                if ($toolInfoViewPanel) { $toolInfoViewPanel.Visible = $false }
            }
            elseif ($panelTag -eq "downloadsPanel") {
                # Downloads-Panel View-Panel ausblenden
                if ($downloadsViewPanel) { $downloadsViewPanel.Visible = $false }
            }
            
            # Y-Positionen der nachfolgenden Panels anpassen
            Update-PanelPositions -ParentPanel $ParentPanel
        }
    }.GetNewClosure()
    
    $headerBtn.Add_Click($clickHandler)
    
    $container.Controls.Add($headerBtn)
    $container.Controls.Add($contentPanel)
    
    return @{
        Container = $container
        Header = $headerBtn
        Content = $contentPanel
    }
}

# Hilfsfunktion zum Aktualisieren der Panel-Positionen
function Update-PanelPositions {
    param([System.Windows.Forms.Panel]$ParentPanel)
    
    $currentY = 5
    foreach ($panel in $ParentPanel.Controls | Where-Object { $_ -is [System.Windows.Forms.Panel] } | Sort-Object { $_.Location.Y }) {
        # Überspringe Panels mit OriginalY Property (OpenUpward-Panels verwalten ihre Position selbst)
        if ($null -ne $panel.OriginalY) {
            continue
        }
        
        $panel.Location = New-Object System.Drawing.Point(5, $currentY)
        $currentY += $panel.Height + 1  # 1px Abstand zwischen Panels (kompaktere Darstellung)
        
        # Separator nach cleanupPanel positionieren mit Abständen
        if ($panel.Tag -eq "cleanupPanel" -and $script:cleanupDownloadsSeparator) {
            $separatorY = $currentY + 9  # 10px Abstand (9px + 1px vom Panel-Abstand)
            $script:cleanupDownloadsSeparator.Location = New-Object System.Drawing.Point(5, $separatorY)
            $currentY = $separatorY + 2 + 10  # Separator-Höhe (2px) + 10px Abstand nach unten
        }
    }
}

# Neue Funktion für horizontale Collapsible Panels (klappen nach rechts)
function New-HorizontalCollapsiblePanel {
    param(
        [string]$Title,
        [int]$XPosition,
        [string]$Tag,
        [System.Windows.Forms.Panel]$ParentPanel,
        [scriptblock]$OnExpand,
        [int]$IconCode = 0
    )
    
    # Container für den gesamten zusammenklappbaren Bereich
    $container = New-Object System.Windows.Forms.Panel
    $container.Location = New-Object System.Drawing.Point($XPosition, 5)
    $container.Size = New-Object System.Drawing.Size(155, 35)  # Höhe 35px für horizontal
    $container.BackColor = [System.Drawing.Color]::Transparent
    $container.Tag = $Tag
    
    # Header-Button
    $headerBtn = New-Object System.Windows.Forms.Button
    $headerBtn.Text = $Title
    $headerBtn.Size = New-Object System.Drawing.Size(155, 35)
    $headerBtn.Location = New-Object System.Drawing.Point(0, 0)
    $headerBtn.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $headerBtn.BackColor = [System.Drawing.Color]::FromArgb(37, 37, 38)
    $headerBtn.ForeColor = [System.Drawing.Color]::White
    $headerBtn.FlatAppearance.BorderSize = 0
    $headerBtn.FlatAppearance.MouseOverBackColor = [System.Drawing.Color]::FromArgb(55, 55, 55)
    $headerBtn.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $headerBtn.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
    $headerBtn.Padding = New-Object System.Windows.Forms.Padding(5, 0, 20, 0)
    $headerBtn.Tag = "collapsed"
    
    # Icon hinzufügen, wenn IconCode angegeben
    if ($IconCode -ne 0) {
        Add-ButtonIcon -Button $headerBtn -IconCode $IconCode -IconSize 11 -LeftMargin 8
    }
    
    # Runde Ecken für Header-Button (8px Radius)
    try {
        $regionHandle = [RoundedCorners]::CreateRoundRectRgn(0, 0, $headerBtn.Width, $headerBtn.Height, 8, 8)
        if ($regionHandle -ne [IntPtr]::Zero) {
            $headerBtn.Region = [System.Drawing.Region]::FromHrgn($regionHandle)
        }
    } catch {
        # Falls runde Ecken nicht funktionieren, einfach ohne weitermachen
    }
    
    # Pfeil-Label (rechts im Button, zeigt nach rechts ►)
    $arrowLabel = New-Object System.Windows.Forms.Label
    $arrowLabel.Text = "►"
    $arrowLabel.Size = New-Object System.Drawing.Size(15, 20)
    $arrowLabel.Location = New-Object System.Drawing.Point(135, 7.5)
    $arrowLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    $arrowLabel.BackColor = [System.Drawing.Color]::Transparent
    $arrowLabel.ForeColor = [System.Drawing.Color]::White
    $arrowLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Regular)
    $arrowLabel.Tag = "arrow"
    $arrowLabel.Add_MouseDown({
        param($s, $e)
        $this.Parent.PerformClick()
    })
    $headerBtn.Controls.Add($arrowLabel)
    
    # Content-Panel (zunächst versteckt, erscheint rechts neben dem Button)
    $contentPanel = New-Object System.Windows.Forms.Panel
    $contentPanel.Location = New-Object System.Drawing.Point(155, 0)  # Rechts neben Header
    $contentPanel.Size = New-Object System.Drawing.Size(525, 35)  # 3 Buttons horizontal (175×3)
    $contentPanel.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
    $contentPanel.Visible = $false
    $contentPanel.AutoSize = $false  # Größe manuell setzen
    
    # Toggle-Funktion
    $clickHandler = {
        param($eventSender, $e)
        
        if ($this.Tag -eq "collapsed") {
            # Alle anderen horizontalen Panels im gleichen Parent zuklappen
            $currentTag = $this.Parent.Tag
            foreach ($ctrl in $ParentPanel.Controls) {
                if ($ctrl -is [System.Windows.Forms.Panel] -and $ctrl.Tag -ne $currentTag -and $ctrl.Tag -like "*Panel") {
                    $otherHeader = $ctrl.Controls[0]
                    $otherContent = $ctrl.Controls[1]
                    
                    if ($otherHeader.Tag -eq "expanded") {
                        $otherArrow = $otherHeader.Controls | Where-Object { $_.Tag -eq "arrow" }
                        if ($otherArrow) { $otherArrow.Text = "►" }
                        $otherHeader.Tag = "collapsed"
                        $otherHeader.BackColor = [System.Drawing.Color]::FromArgb(37, 37, 38)
                        $otherContent.Visible = $false
                        $ctrl.Width = 155
                    }
                }
            }
            
            # WICHTIG: Alle Panels neu positionieren nach dem Zuklappen
            $tempX = 10
            foreach ($ctrl in $ParentPanel.Controls | Sort-Object { $_.Location.X }) {
                if ($ctrl -is [System.Windows.Forms.Panel] -and $ctrl.Tag -like "*Panel") {
                    $ctrl.Location = New-Object System.Drawing.Point($tempX, 5)
                    $tempX += $ctrl.Width + 5
                }
            }
            
            # Aktuelles Panel ausklappen
            $arrow = $this.Controls | Where-Object { $_.Tag -eq "arrow" }
            if ($arrow) { $arrow.Text = "◄" }  # Pfeil nach links wenn ausgeklappt
            $this.Tag = "expanded"
            $this.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
            
            $contentPnl = $this.Parent.Controls[1]
            $contentPnl.Visible = $true
            
            # Container-Breite anpassen (Höhe bleibt 35px)
            $this.Parent.Width = 155 + $contentPnl.Width
            
            # WICHTIG: Alle Panels rechts davon nach rechts verschieben
            $currentPanel = $this.Parent
            $currentRight = $currentPanel.Location.X + $currentPanel.Width + 5  # 5px Abstand
            
            foreach ($ctrl in $ParentPanel.Controls | Sort-Object { $_.Location.X }) {
                if ($ctrl -is [System.Windows.Forms.Panel] -and 
                    $ctrl.Tag -like "*Panel" -and 
                    $ctrl -ne $currentPanel -and 
                    $ctrl.Location.X -gt $currentPanel.Location.X) {
                    
                    $ctrl.Location = New-Object System.Drawing.Point($currentRight, 5)
                    $currentRight += $ctrl.Width + 5
                }
            }
            
            # OnExpand-Callback ausführen
            if ($OnExpand) {
                & $OnExpand
            }
        }
        else {
            # Zuklappen
            $arrow = $this.Controls | Where-Object { $_.Tag -eq "arrow" }
            if ($arrow) { $arrow.Text = "►" }
            $this.Tag = "collapsed"
            $this.BackColor = [System.Drawing.Color]::FromArgb(37, 37, 38)
            
            $contentPnl = $this.Parent.Controls[1]
            $contentPnl.Visible = $false
            # Container-Breite auf Header-Button-Breite zurücksetzen
            $this.Parent.Width = 155
            
            # WICHTIG: Panels neu positionieren
            $currentX = 10
            foreach ($ctrl in $ParentPanel.Controls | Sort-Object { $_.Location.X }) {
                if ($ctrl -is [System.Windows.Forms.Panel] -and $ctrl.Tag -like "*Panel") {
                    $ctrl.Location = New-Object System.Drawing.Point($currentX, 5)
                    $currentX += $ctrl.Width + 5
                }
            }
        }
    }.GetNewClosure()
    
    $headerBtn.Add_Click($clickHandler)
    
    $container.Controls.Add($headerBtn)
    $container.Controls.Add($contentPanel)
    
    return @{
        Container = $container
        Header = $headerBtn
        Content = $contentPanel
    }
}

# Hilfsfunktion: Versteckt alle Content-Panels und aktualisiert Header-BackColors
function Reset-MainPanelStates {
    param(
        [string]$ActivePanel  # "system", "disk", "network", "cleanup"
    )
    
    # Alle Content-Panels ausblenden
    if ($global:tblSystem) { $global:tblSystem.Visible = $false }
    if ($tblDisk) { $tblDisk.Visible = $false }
    if ($tblNetwork) { $tblNetwork.Visible = $false }
    if ($tblCleanup) { $tblCleanup.Visible = $false }
    if ($global:tblDependencies) { $global:tblDependencies.Visible = $false }
    if ($global:tblSmartRepair) { $global:tblSmartRepair.Visible = $false }
    
    # SearchPanel ausblenden (wird nur für Tool-Downloads benötigt)
    if ($searchPanel) { $searchPanel.Visible = $false }
    
    # Horizontale Container ausblenden
    if ($infoHorizontalPanel -and $infoHorizontalPanel.Container) {
        $infoHorizontalPanel.Container.Visible = $false
    }
    if ($troubleshootHorizontalPanel -and $troubleshootHorizontalPanel.Container) {
        $troubleshootHorizontalPanel.Container.Visible = $false
    }
    
    # Header-Buttons visuell zurücksetzen (alle inaktiv)
    if ($systemPanel) { $systemPanel.Header.BackColor = [System.Drawing.Color]::FromArgb(37, 37, 38) }
    if ($diskPanel) { $diskPanel.Header.BackColor = [System.Drawing.Color]::FromArgb(37, 37, 38) }
    if ($networkPanel) { $networkPanel.Header.BackColor = [System.Drawing.Color]::FromArgb(37, 37, 38) }
    if ($cleanupPanel) { $cleanupPanel.Header.BackColor = [System.Drawing.Color]::FromArgb(37, 37, 38) }
    if ($global:smartRepairPanel) { $global:smartRepairPanel.Header.BackColor = [System.Drawing.Color]::FromArgb(37, 37, 38) }
    
    # Aktiven Panel-Header hervorheben
    switch ($ActivePanel) {
        "system"      { if ($systemPanel) { $systemPanel.Header.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43) } }
        "disk"        { if ($diskPanel) { $diskPanel.Header.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43) } }
        "network"     { if ($networkPanel) { $networkPanel.Header.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43) } }
        "cleanup"     { if ($cleanupPanel) { $cleanupPanel.Header.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43) } }
        "smartRepair" { if ($global:smartRepairPanel) { $global:smartRepairPanel.Header.BackColor = [System.Drawing.Color]::FromArgb(0, 100, 180) } }
    }
}

# Hilfsfunktion: Zeigt Informationen- und Support-Panel im MainContent wieder an
function Show-MainInfoSupportPanels {
    if ($infoHorizontalPanel -and $infoHorizontalPanel.Container) {
        $infoHorizontalPanel.Container.Visible = $true
        $infoHorizontalPanel.Container.BringToFront()
    }
    if ($troubleshootHorizontalPanel -and $troubleshootHorizontalPanel.Container) {
        $troubleshootHorizontalPanel.Container.Visible = $true
        $troubleshootHorizontalPanel.Container.BringToFront()
    }
}

# Hilfsfunktion: Versteckt Informationen- und Support-Panel (für Funktionsansichten)
function Hide-MainInfoSupportPanels {
    if ($infoHorizontalPanel -and $infoHorizontalPanel.Container) {
        $infoHorizontalPanel.Container.Visible = $false
    }
    if ($troubleshootHorizontalPanel -and $troubleshootHorizontalPanel.Container) {
        $troubleshootHorizontalPanel.Container.Visible = $false
    }
}

# ================================================
# ++++ 1-Klick Smart Repair Panel (oben/featured) ++++
# ================================================
$global:smartRepairPanel = New-CollapsiblePanel -Title "1-Klick Reparatur" -YPosition 5 -Tag "smartRepairPanel" -ParentPanel $mainButtonPanel -IconCode 0xE946 -OnExpand {
    Reset-MainPanelStates -ActivePanel "smartRepair"
    $outputBox.Clear()
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'BannerFrame'
    $outputBox.AppendText("`t╔═══════════════════════════════════════════════════════════════╗`r`n")
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'BannerTitle'
    $outputBox.AppendText("`t║              1-KLICK SMART REPAIR                             ║`r`n")
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'BannerFrame'
    $outputBox.AppendText("`t╚═══════════════════════════════════════════════════════════════╝`r`n`r`n")

    # C5 – Letzter Scan-Zeitstempel anzeigen
    if ($script:lastSmartRepairTime) {
        $elapsed = (Get-Date) - $script:lastSmartRepairTime
        $elapsedStr = if ($elapsed.TotalMinutes -lt 1) { "vor $([int]$elapsed.TotalSeconds) Sekunden" }
                      elseif ($elapsed.TotalHours   -lt 1) { "vor $([int]$elapsed.TotalMinutes) Minuten" }
                      else { "am $($script:lastSmartRepairTime.ToString('dd.MM.yyyy HH:mm')) Uhr" }
        Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Muted'
        $outputBox.AppendText("  Letzter Scan: $elapsedStr`r`n`r`n")
    }

    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Heading'
    $outputBox.AppendText("Smart Repair analysiert automatisch (22 Checks):`r`n`r`n")
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Info'
    $outputBox.AppendText("  ● Windows Update-Status`r`n")
    $outputBox.AppendText("  ● Defender-Status (Echtzeitschutz)`r`n")
    $outputBox.AppendText("  ● System-Integrität (CBS-Log Analyse)`r`n")
    $outputBox.AppendText("  ● Ereignisprotokoll (kritische Fehler)`r`n")
    $outputBox.AppendText("  ● Netzwerk / Internetverbindung`r`n")
    $outputBox.AppendText("  ● Temp-Cleanup (automatisch)`r`n")
    $outputBox.AppendText("  ● Neustart-Empfehlung`r`n")
    $outputBox.AppendText("  ● Festplatten-Speicherplatz (C:)`r`n")
    $outputBox.AppendText("  ● Windows-Firewall Status`r`n")
    $outputBox.AppendText("  ● Kritische Windows-Dienste`r`n")
    $outputBox.AppendText("  ● Windows-Aktivierungsstatus`r`n")
    $outputBox.AppendText("  ● Festplatten-Gesundheit (SMART)`r`n")
    $outputBox.AppendText("  ● Systemzeit-Synchronisation`r`n")
    $outputBox.AppendText("  ● RAM-Auslastung`r`n")
    $outputBox.AppendText("  ● Hosts-Datei-Integrität`r`n")
    $outputBox.AppendText("  ● DISM Component-Store (CheckHealth)`r`n")
    $outputBox.AppendText("  ● CHKDSK Dirty-Bit (C:)`r`n")
    $outputBox.AppendText("  ● Auslagerungsdatei (Pagefile)`r`n")
    $outputBox.AppendText("  ● Geplante Tasks (Fehlerstatus)`r`n")
    $outputBox.AppendText("  ● Root-Zertifikate (Gültigkeit)`r`n")
    $outputBox.AppendText("  ● Energieplan`r`n")
    $outputBox.AppendText("  ● Windows-Suchdienst (WSearch)`r`n`r`n")
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Muted'
    $outputBox.AppendText("  → Klicken Sie auf [Smart Repair starten] um die Analyse zu beginnen.`r`n")

    Switch-OutputView -viewName "outputView"
    Hide-MainInfoSupportPanels

    $global:tblSmartRepair.Visible = $true
    $global:tblSmartRepair.BringToFront()
    $script:currentMainView = "smartRepairView"
}

# Sub-Button im SmartRepair-Panel (wird nach Erstellung von $tblSmartRepair befüllt – Placeholder)
$global:btnStartSmartRepairNav = New-Object System.Windows.Forms.Button
$global:btnStartSmartRepairNav.Text = "Smart Repair starten"
$global:btnStartSmartRepairNav.Size = New-Object System.Drawing.Size(210, 35)
$global:btnStartSmartRepairNav.Location = New-Object System.Drawing.Point(0, 0)
$global:btnStartSmartRepairNav.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$global:btnStartSmartRepairNav.BackColor = [System.Drawing.Color]::FromArgb(0, 100, 180)
$global:btnStartSmartRepairNav.ForeColor = [System.Drawing.Color]::White
$global:btnStartSmartRepairNav.FlatAppearance.BorderSize = 0
$global:btnStartSmartRepairNav.FlatAppearance.MouseOverBackColor = [System.Drawing.Color]::FromArgb(0, 120, 215)
$global:btnStartSmartRepairNav.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$global:btnStartSmartRepairNav.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
Add-ButtonIcon -Button $global:btnStartSmartRepairNav -IconCode 0xE946 -IconSize 12 -LeftMargin 10
$global:smartRepairPanel.Content.Controls.Add($global:btnStartSmartRepairNav)
$global:smartRepairPanel.Content.Height = 35

$mainButtonPanel.Controls.Add($global:smartRepairPanel.Container)

# System & Sicherheit Panel
$systemPanel = New-CollapsiblePanel -Title "System/Sicherheit" -YPosition 40 -Tag "systemPanel" -ParentPanel $mainButtonPanel -IconCode 0xE83D -OnExpand {
    # Panels zurücksetzen und System als aktiv markieren
    Reset-MainPanelStates -ActivePanel "system"
    
    # OutputBox leeren und Info anzeigen
    $outputBox.Clear()
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'BannerFrame'
    $outputBox.AppendText("`t╔═══════════════════════════════════════════════════════════════╗`r`n")
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'BannerTitle'
    $outputBox.AppendText("`t║              SYSTEM & SICHERHEITS-TOOLS                       ║`r`n")
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'BannerFrame'
    $outputBox.AppendText("`t╚═══════════════════════════════════════════════════════════════╝`r`n`r`n")
    
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Heading'
    $outputBox.AppendText("Verfügbare Tools:`r`n`r`n")
    
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Accent'
    Add-OutputIcon -OutputBox $outputBox -IconCode 0xE83D
    $outputBox.AppendText(" SICHERHEIT:`r`n")
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Info'
    $outputBox.AppendText("  • Windows Defender     - Quick/Full/Custom/Offline Scans`r`n")
    $outputBox.AppendText("  • Defender Restart     - Neustart des Windows Defender-Dienstes`r`n")
    $outputBox.AppendText("  • MRT Quick Scan       - Schnelle Malware-Erkennung (Microsoft Tool)`r`n")
    $outputBox.AppendText("  • MRT Full Scan        - Vollständige Systemprüfung auf Schadsoftware`r`n`r`n")
    
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Accent'
    Add-OutputIcon -OutputBox $outputBox -IconCode 0xE90F
    $outputBox.AppendText(" WARTUNG:`r`n")
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Info'
    $outputBox.AppendText("  • SFC Check            - System File Checker für beschädigte Dateien`r`n")
    $outputBox.AppendText("  • Memory Diagnostic    - Arbeitsspeicher-Test (erfordert Neustart)`r`n`r`n")
    
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Muted'
    Add-OutputIcon -OutputBox $outputBox -IconCode 0xE946
    $outputBox.AppendText(" Tipp: Wählen Sie eine Kategorie oben aus, um die Tools anzuzeigen.`r`n")
    
    # Stelle sicher, dass OutputView angezeigt wird
    Switch-OutputView -viewName "outputView"

    # Informationen + Support im MainContent einblenden
    Show-MainInfoSupportPanels
    
    # Hinweis: Content-Panel wird erst durch Klick auf Sub-Button sichtbar
    $script:currentMainView = "systemView"
}

# Content (Untermenü-Buttons) hinzufügen
$btnSystemSecurity = New-Object System.Windows.Forms.Button
$btnSystemSecurity.Text = "Sicherheit"
$btnSystemSecurity.Size = New-Object System.Drawing.Size(210, 35)
$btnSystemSecurity.Location = New-Object System.Drawing.Point(0, 0)
$btnSystemSecurity.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnSystemSecurity.BackColor = [System.Drawing.Color]::FromArgb(37, 37, 38)  # Inaktiv beim Start
$btnSystemSecurity.ForeColor = [System.Drawing.Color]::White
$btnSystemSecurity.FlatAppearance.BorderSize = 0
$btnSystemSecurity.FlatAppearance.MouseOverBackColor = [System.Drawing.Color]::FromArgb(55, 55, 55)  # Hover-Effekt
$btnSystemSecurity.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$btnSystemSecurity.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
Add-ButtonIcon -Button $btnSystemSecurity -IconCode 0xE83D -IconSize 12 -LeftMargin 10
$btnSystemSecurity.Add_Click({
    $script:securityControlsVisible = $true
    $script:maintenanceControlsVisible = $false
    $script:currentSystemView = "securityView"
    
    # MainContentPanel sichtbar machen
    $global:tblSystem.Visible = $true

    # Verhindert Überlagerung mit Funktionsbuttons
    Hide-MainInfoSupportPanels
    
    # Toggle-Funktion aufrufen um Buttons anzuzeigen
    Switch-SystemControls
    
    # Visuelles Feedback - Aktiver Button heller, inaktiver dunkler
    $btnSystemSecurity.BackColor = [System.Drawing.Color]::FromArgb(55, 55, 55)
    $btnSystemMaintenance.BackColor = [System.Drawing.Color]::FromArgb(37, 37, 38)
})
$systemPanel.Content.Controls.Add($btnSystemSecurity)

$btnSystemMaintenance = New-Object System.Windows.Forms.Button
$btnSystemMaintenance.Text = "Wartung"
$btnSystemMaintenance.Size = New-Object System.Drawing.Size(210, 35)
$btnSystemMaintenance.Location = New-Object System.Drawing.Point(0, 35)
$btnSystemMaintenance.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnSystemMaintenance.BackColor = [System.Drawing.Color]::FromArgb(37, 37, 38)  # Inaktiv beim Start
$btnSystemMaintenance.ForeColor = [System.Drawing.Color]::White
$btnSystemMaintenance.FlatAppearance.BorderSize = 0
$btnSystemMaintenance.FlatAppearance.MouseOverBackColor = [System.Drawing.Color]::FromArgb(55, 55, 55)  # Hover-Effekt
$btnSystemMaintenance.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$btnSystemMaintenance.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
Add-ButtonIcon -Button $btnSystemMaintenance -IconCode 0xE90F -IconSize 12 -LeftMargin 10
$btnSystemMaintenance.Add_Click({
    $script:securityControlsVisible = $false
    $script:maintenanceControlsVisible = $true
    $script:currentSystemView = "maintenanceView"
    
    # MainContentPanel sichtbar machen
    $global:tblSystem.Visible = $true

    # Verhindert Überlagerung mit Funktionsbuttons
    Hide-MainInfoSupportPanels
    
    # Toggle-Funktion aufrufen um Buttons anzuzeigen
    Switch-SystemControls
    
    # Visuelles Feedback - Aktiver Button heller, inaktiver dunkler
    $btnSystemSecurity.BackColor = [System.Drawing.Color]::FromArgb(37, 37, 38)
    $btnSystemMaintenance.BackColor = [System.Drawing.Color]::FromArgb(55, 55, 55)
})
$systemPanel.Content.Controls.Add($btnSystemMaintenance)

$systemPanel.Content.Height = 70  # 2 Buttons × 35px
$mainButtonPanel.Controls.Add($systemPanel.Container)

# Diagnose & Reparatur Panel
$diskPanel = New-CollapsiblePanel -Title "Diagnose/Reparatur" -YPosition 75 -Tag "diskPanel" -ParentPanel $mainButtonPanel -IconCode 0xE90F -OnExpand {
    # Panels zurücksetzen und Disk als aktiv markieren
    Reset-MainPanelStates -ActivePanel "disk"
    
    # OutputBox leeren und Info anzeigen
    $outputBox.Clear()
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'BannerFrame'
    $outputBox.AppendText("`t╔═══════════════════════════════════════════════════════════════╗`r`n")
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'BannerTitle'
    $outputBox.AppendText("`t║              DIAGNOSE & REPARATUR-TOOLS                       ║`r`n")
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'BannerFrame'
    $outputBox.AppendText("`t╚═══════════════════════════════════════════════════════════════╝`r`n`r`n")
    
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Heading'
    $outputBox.AppendText("Verfügbare Tools:`r`n`r`n")

    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Accent'
    Add-OutputIcon -OutputBox $outputBox -IconCode 0xE721
    $outputBox.AppendText(" DISM (SYSTEM-IMAGE):`r`n")
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Info'
    $outputBox.AppendText("  • DISM Check Health    - Schnelle Integritätsprüfung`r`n")
    $outputBox.AppendText("  • DISM Scan Health     - Detaillierte Analyse`r`n")
    $outputBox.AppendText("  • DISM Restore Health  - Automatische Reparatur`r`n`r`n")
    
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Accent'
    Add-OutputIcon -OutputBox $outputBox -IconCode 0xE74E
    $outputBox.AppendText(" CHKDSK (FESTPLATTEN):`r`n")
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Info'
    $outputBox.AppendText("  • CHKDSK (Scan)        - Nur Überprüfung (ohne Reparatur)`r`n")
    $outputBox.AppendText("  • CHKDSK /F            - Reparatur (erfordert Neustart)`r`n")
    $outputBox.AppendText("  • CHKDSK /R            - Erweiterte Reparatur + Bad-Sector-Suche`r`n`r`n")
    
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Warning'
    Add-OutputIcon -OutputBox $outputBox -IconCode 0xE7BA
    $outputBox.AppendText("  HINWEIS: CHKDSK-Reparaturen erfordern oft einen Neustart.`r`n`r`n")
    
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Muted'
    Add-OutputIcon -OutputBox $outputBox -IconCode 0xE946
    $outputBox.AppendText(" Tipp: Wählen Sie eine Kategorie oben aus, um die Tools anzuzeigen.`r`n")
    
    # Stelle sicher, dass OutputView angezeigt wird
    Switch-OutputView -viewName "outputView"

    # Informationen + Support im MainContent einblenden
    Show-MainInfoSupportPanels
    
    # Hinweis: Content-Panel wird erst durch Klick auf Sub-Button sichtbar
    $script:currentMainView = "diskView"
}

$btnDiskDiagnose = New-Object System.Windows.Forms.Button
$btnDiskDiagnose.Text = "Diagnose"
$btnDiskDiagnose.Size = New-Object System.Drawing.Size(210, 35)
$btnDiskDiagnose.Location = New-Object System.Drawing.Point(0, 0)
$btnDiskDiagnose.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnDiskDiagnose.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
$btnDiskDiagnose.ForeColor = [System.Drawing.Color]::White
$btnDiskDiagnose.FlatAppearance.BorderSize = 0
$btnDiskDiagnose.FlatAppearance.MouseOverBackColor = [System.Drawing.Color]::FromArgb(55, 55, 55)
$btnDiskDiagnose.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$btnDiskDiagnose.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
Add-ButtonIcon -Button $btnDiskDiagnose -IconCode 0xE721 -IconSize 12 -LeftMargin 10
$btnDiskDiagnose.Add_Click({
    $script:currentDiskView = "diagnoseView"
    $script:diagnoseControlsVisible = $true
    $script:repairControlsVisible = $false
    
    # MainContentPanel sichtbar machen
    $tblDisk.Visible = $true

    # Verhindert Überlagerung mit Funktionsbuttons
    Hide-MainInfoSupportPanels
    
    # Toggle-Funktion aufrufen um Buttons anzuzeigen
    Switch-DiskControls
    
    # Visuelles Feedback
    $btnDiskDiagnose.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
    $btnDiskRepair.BackColor = [System.Drawing.Color]::FromArgb( 43, 43, 43)
})
$diskPanel.Content.Controls.Add($btnDiskDiagnose)

$btnDiskRepair = New-Object System.Windows.Forms.Button
$btnDiskRepair.Text = "Reparatur"
$btnDiskRepair.Size = New-Object System.Drawing.Size(210, 35)
$btnDiskRepair.Location = New-Object System.Drawing.Point(0, 35)
$btnDiskRepair.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnDiskRepair.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
$btnDiskRepair.ForeColor = [System.Drawing.Color]::White
$btnDiskRepair.FlatAppearance.BorderSize = 0
$btnDiskRepair.FlatAppearance.MouseOverBackColor = [System.Drawing.Color]::FromArgb(55, 55, 55)
$btnDiskRepair.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$btnDiskRepair.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
Add-ButtonIcon -Button $btnDiskRepair -IconCode 0xE90F -IconSize 12 -LeftMargin 10
$btnDiskRepair.Add_Click({
    $script:currentDiskView = "repairView"
    $script:diagnoseControlsVisible = $false
    $script:repairControlsVisible = $true
    
    # MainContentPanel sichtbar machen
    $tblDisk.Visible = $true

    # Verhindert Überlagerung mit Funktionsbuttons
    Hide-MainInfoSupportPanels
    
    # Toggle-Funktion aufrufen um Buttons anzuzeigen
    Switch-DiskControls
    
    # Visuelles Feedback
    $btnDiskDiagnose.BackColor = [System.Drawing.Color]::FromArgb( 43, 43, 43)
    $btnDiskRepair.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
})
$diskPanel.Content.Controls.Add($btnDiskRepair)

$diskPanel.Content.Height = 70  # 2 Buttons × 35px
$mainButtonPanel.Controls.Add($diskPanel.Container)

# Netzwerk-Tools Panel
$networkPanel = New-CollapsiblePanel -Title "Netzwerk-Tools" -YPosition 110 -Tag "networkPanel" -ParentPanel $mainButtonPanel -IconCode 0xE774 -OnExpand {
    # Panels zurücksetzen und Network als aktiv markieren
    Reset-MainPanelStates -ActivePanel "network"
    
    # OutputBox leeren und Info anzeigen
    $outputBox.Clear()
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'BannerFrame'
    $outputBox.AppendText("`t╔═══════════════════════════════════════════════════════════════╗`r`n")
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'BannerTitle'
    $outputBox.AppendText("`t║                    NETZWERK-TOOLS                             ║`r`n")
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'BannerFrame'
    $outputBox.AppendText("`t╚═══════════════════════════════════════════════════════════════╝`r`n`r`n")
    
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Heading'
    $outputBox.AppendText("Verfügbare Tools:`r`n`r`n")

    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Accent'
    Add-OutputIcon -OutputBox $outputBox -IconCode 0xE721
    $outputBox.AppendText(" NETZWERK-DIAGNOSE:`r`n")
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Info'
    $outputBox.AppendText("  • Ping Test            - Konnektivitätstests zu beliebigen Hosts`r`n")
    $outputBox.AppendText("                           (Konfigurierbar: Anzahl, Timeout, Buffer-Größe)`r`n`r`n")
    
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Accent'
    Add-OutputIcon -OutputBox $outputBox -IconCode 0xE90F
    $outputBox.AppendText(" NETZWERK-REPARATUR:`r`n")
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Info'
    $outputBox.AppendText("  • Netzwerk zurücksetzen- Vollständiger Reset des Netzwerkadapters`r`n")
    $outputBox.AppendText("                           (Deaktivieren und wieder aktivieren)`r`n`r`n")
    
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Muted'
    Add-OutputIcon -OutputBox $outputBox -IconCode 0xE946
    $outputBox.AppendText(" Tipp: Wählen Sie eine Kategorie oben aus, um die Tools anzuzeigen.`r`n")
    
    # Stelle sicher, dass OutputView angezeigt wird
    Switch-OutputView -viewName "outputView"

    # Informationen + Support im MainContent einblenden
    Show-MainInfoSupportPanels
    
    # Hinweis: Content-Panel wird erst durch Klick auf Sub-Button sichtbar
    $script:currentMainView = "networkView"
}

$btnNetworkDiagnose = New-Object System.Windows.Forms.Button
$btnNetworkDiagnose.Text = "Netzwerk-Diagnose"
$btnNetworkDiagnose.Size = New-Object System.Drawing.Size(210, 35)
$btnNetworkDiagnose.Location = New-Object System.Drawing.Point(0, 0)
$btnNetworkDiagnose.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnNetworkDiagnose.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
$btnNetworkDiagnose.ForeColor = [System.Drawing.Color]::White
$btnNetworkDiagnose.FlatAppearance.BorderSize = 0
$btnNetworkDiagnose.FlatAppearance.MouseOverBackColor = [System.Drawing.Color]::FromArgb(55, 55, 55)
$btnNetworkDiagnose.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$btnNetworkDiagnose.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
Add-ButtonIcon -Button $btnNetworkDiagnose -IconCode 0xE721 -IconSize 12 -LeftMargin 10
$btnNetworkDiagnose.Add_Click({
    $script:currentNetworkView = "diagnoseView"
    $script:networkDiagnosticsControlsVisible = $true
    $script:networkRepairControlsVisible = $false
    
    # MainContentPanel sichtbar machen
    $tblNetwork.Visible = $true

    # Verhindert Überlagerung mit Funktionsbuttons
    Hide-MainInfoSupportPanels
    
    # Toggle-Funktion aufrufen um Buttons anzuzeigen
    Switch-NetworkControls
    
    # Visuelles Feedback
    $btnNetworkDiagnose.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
    $btnNetworkRepair.BackColor = [System.Drawing.Color]::FromArgb( 43, 43, 43)
})
$networkPanel.Content.Controls.Add($btnNetworkDiagnose)

$btnNetworkRepair = New-Object System.Windows.Forms.Button
$btnNetworkRepair.Text = "Netzwerk-Reparatur"
$btnNetworkRepair.Size = New-Object System.Drawing.Size(210, 35)
$btnNetworkRepair.Location = New-Object System.Drawing.Point(0, 35)
$btnNetworkRepair.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnNetworkRepair.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
$btnNetworkRepair.ForeColor = [System.Drawing.Color]::White
$btnNetworkRepair.FlatAppearance.BorderSize = 0
$btnNetworkRepair.FlatAppearance.MouseOverBackColor = [System.Drawing.Color]::FromArgb(55, 55, 55)
$btnNetworkRepair.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$btnNetworkRepair.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
Add-ButtonIcon -Button $btnNetworkRepair -IconCode 0xE90F -IconSize 12 -LeftMargin 10
$btnNetworkRepair.Add_Click({
    $script:currentNetworkView = "repairView"
    $script:networkDiagnosticsControlsVisible = $false
    $script:networkRepairControlsVisible = $true
    
    # MainContentPanel sichtbar machen
    $tblNetwork.Visible = $true

    # Verhindert Überlagerung mit Funktionsbuttons
    Hide-MainInfoSupportPanels
    
    # Toggle-Funktion aufrufen um Buttons anzuzeigen
    Switch-NetworkControls
    
    # Visuelles Feedback
    $btnNetworkDiagnose.BackColor = [System.Drawing.Color]::FromArgb( 43, 43, 43)
    $btnNetworkRepair.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
})
$networkPanel.Content.Controls.Add($btnNetworkRepair)

$networkPanel.Content.Height = 70  # 2 Buttons × 35px
$mainButtonPanel.Controls.Add($networkPanel.Container)

# Bereinigung Panel
$cleanupPanel = New-CollapsiblePanel -Title "Bereinigung" -YPosition 145 -Tag "cleanupPanel" -ParentPanel $mainButtonPanel -IconCode 0xE74C -OnExpand {
    # Panels zurücksetzen und Cleanup als aktiv markieren
    Reset-MainPanelStates -ActivePanel "cleanup"
    
    # OutputBox leeren und Info anzeigen
    $outputBox.Clear()
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'BannerFrame'
    $outputBox.AppendText("`t╔═══════════════════════════════════════════════════════════════╗`r`n")
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'BannerTitle'
    $outputBox.AppendText("`t║                 BEREINIGUNGS-TOOLS                            ║`r`n")
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'BannerFrame'
    $outputBox.AppendText("`t╚═══════════════════════════════════════════════════════════════╝`r`n`r`n")
    
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Heading'
    $outputBox.AppendText("Verfügbare Tools:`r`n`r`n")
    
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Accent'
    Add-OutputIcon -OutputBox $outputBox -IconCode 0xE74C
    $outputBox.AppendText(" VERFÜGBARE BEREINIGUNGEN:`r`n")
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Info'
    $outputBox.AppendText("  • Temp-Dateien (Einfach)  - Löscht TEMP-Ordner (%TEMP%, Windows\Temp)`r`n")
    $outputBox.AppendText("  • Temp-Dateien (Erweitert)- Umfassend: TEMP, Prefetch, Browser-Cache`r`n")
    $outputBox.AppendText("  • Disk Cleanup            - Windows-eigenes Bereinigungs-Tool`r`n")
    $outputBox.AppendText("  • Cleanup-Übersicht       - Interaktive Auswahlmaske mit Vorschau`r`n`r`n")
    
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Success'
    Add-OutputIcon -OutputBox $outputBox -IconCode 0xE74E
    $outputBox.AppendText(" Potenzieller Speicherplatz-Gewinn: 2-10 GB (je nach System)`r`n")
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Muted'
    Add-OutputIcon -OutputBox $outputBox -IconCode 0xE946
    $outputBox.AppendText(" Tipp: Klicken Sie auf einen Button, um die Bereinigung zu starten.`r`n")
    
    # Stelle sicher, dass OutputView angezeigt wird
    Switch-OutputView -viewName "outputView"

    # Informationen + Support im MainContent einblenden
    Show-MainInfoSupportPanels
    
    # Hinweis: Content-Panel wird erst durch Klick auf Sub-Button sichtbar
    $script:currentMainView = "cleanupView"
}

$btnCleanupSystem = New-Object System.Windows.Forms.Button
$btnCleanupSystem.Text = "System-Bereinigung"
$btnCleanupSystem.Size = New-Object System.Drawing.Size(210, 35)
$btnCleanupSystem.Location = New-Object System.Drawing.Point(0, 0)
$btnCleanupSystem.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnCleanupSystem.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
$btnCleanupSystem.ForeColor = [System.Drawing.Color]::White
$btnCleanupSystem.FlatAppearance.BorderSize = 0
$btnCleanupSystem.FlatAppearance.MouseOverBackColor = [System.Drawing.Color]::FromArgb(55, 55, 55)
$btnCleanupSystem.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$btnCleanupSystem.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
Add-ButtonIcon -Button $btnCleanupSystem -IconCode 0xE74C -IconSize 12 -LeftMargin 10
$btnCleanupSystem.Add_Click({
    $script:currentCleanupView = "systemCleanupView"
    $script:cleanupSystemControlsVisible = $true
    $script:cleanupTempControlsVisible = $false
    
    # MainContentPanel sichtbar machen
    $tblCleanup.Visible = $true

    # Verhindert Überlagerung mit Funktionsbuttons
    Hide-MainInfoSupportPanels
    
    # Toggle-Funktion aufrufen um Buttons anzuzeigen
    Switch-CleanupControls
    
    # Visuelles Feedback
    $btnCleanupSystem.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
})
$cleanupPanel.Content.Controls.Add($btnCleanupSystem)

$cleanupPanel.Content.Height = 35  # 1 Button × 35px
$mainButtonPanel.Controls.Add($cleanupPanel.Container)

# Tool-Downloads Panel direkt nach Bereinigung (ohne Trenner mehr nötig)

# Erstelle Collapsible Panel für Tool-Downloads

# Hilfsvariable für aktive Hauptansicht
$script:currentMainView = "systemView"

# Content-Panels für die verschiedenen Bereiche direkt im mainContentPanel erstellen
$global:tblSystem = New-Object System.Windows.Forms.Panel
$global:tblSystem.Location = New-Object System.Drawing.Point(0, 0)
$global:tblSystem.Size = New-Object System.Drawing.Size(735, 230)  # Breite angepasst für breitere Button-Panels
$global:tblSystem.BackColor = [System.Drawing.Color]::Transparent
$global:tblSystem.Visible = $false
$mainContentPanel.Controls.Add($global:tblSystem)

# Definiere Variablen für die Sichtbarkeitsstatus (wird später für Button-Klicks verwendet)
$script:securityControlsVisible = $false
$script:maintenanceControlsVisible = $false

$tblDisk = New-Object System.Windows.Forms.Panel
$tblDisk.Location = New-Object System.Drawing.Point(0, 0)
$tblDisk.Size = New-Object System.Drawing.Size(735, 230)  # Breite angepasst für breitere Button-Panels
$tblDisk.BackColor = [System.Drawing.Color]::Transparent
$tblDisk.Visible = $false
$mainContentPanel.Controls.Add($tblDisk)

$tblNetwork = New-Object System.Windows.Forms.Panel
$tblNetwork.Location = New-Object System.Drawing.Point(0, 0)
$tblNetwork.Size = New-Object System.Drawing.Size(735, 230)  # Breite angepasst für breitere Button-Panels
$tblNetwork.BackColor = [System.Drawing.Color]::Transparent
$tblNetwork.Visible = $false
$mainContentPanel.Controls.Add($tblNetwork)

$tblCleanup = New-Object System.Windows.Forms.Panel
$tblCleanup.Location = New-Object System.Drawing.Point(0, 0)
$tblCleanup.Size = New-Object System.Drawing.Size(735, 230)  # Breite angepasst für breitere Button-Panels
$tblCleanup.BackColor = [System.Drawing.Color]::Transparent
$tblCleanup.Visible = $false
$mainContentPanel.Controls.Add($tblCleanup)

# Panel für Dependency-Check (Installationsbuttons)
$global:tblDependencies = New-Object System.Windows.Forms.Panel
$global:tblDependencies.Location = New-Object System.Drawing.Point(0, 0)
$global:tblDependencies.Size = New-Object System.Drawing.Size(735, 230)
$global:tblDependencies.BackColor = [System.Drawing.Color]::Transparent
$global:tblDependencies.Visible = $false
$mainContentPanel.Controls.Add($global:tblDependencies)

# ================================================
# ++++ 1-Klick Smart Repair – Content-Panel ++++
# Passt sich dem 48px-Layout des mainContentPanel an (wie alle anderen tbl-Panels)
# Ergebnisse werden in outputBox + StatusBar angezeigt
# ================================================
$global:tblSmartRepair = New-Object System.Windows.Forms.Panel
$global:tblSmartRepair.Location = New-Object System.Drawing.Point(0, 0)
$global:tblSmartRepair.Size = New-Object System.Drawing.Size(735, 38)
$global:tblSmartRepair.BackColor = [System.Drawing.Color]::Transparent
$global:tblSmartRepair.Visible = $false
$mainContentPanel.Controls.Add($global:tblSmartRepair)

# Einziger Button: Smart Repair starten (entspricht dem Muster aller anderen Tool-Buttons)
$btnStartSmartRepair = New-Object System.Windows.Forms.Button
$btnStartSmartRepair.Name = "btnStartSmartRepair"
$btnStartSmartRepair.Text = "Smart Repair starten"
$btnStartSmartRepair.Size = New-Object System.Drawing.Size(210, 35)
$btnStartSmartRepair.Location = New-Object System.Drawing.Point(5, 0)
$btnStartSmartRepair.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnStartSmartRepair.BackColor = [System.Drawing.Color]::FromArgb(0, 100, 180)
$btnStartSmartRepair.ForeColor = [System.Drawing.Color]::White
$btnStartSmartRepair.FlatAppearance.BorderSize = 0
$btnStartSmartRepair.FlatAppearance.MouseOverBackColor = [System.Drawing.Color]::FromArgb(0, 120, 215)
$btnStartSmartRepair.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$btnStartSmartRepair.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$btnStartSmartRepair.Cursor = [System.Windows.Forms.Cursors]::Hand
Add-ButtonIcon -Button $btnStartSmartRepair -IconCode 0xE946 -IconSize 11 -LeftMargin 10
$global:tblSmartRepair.Controls.Add($btnStartSmartRepair)

# Gesamtergebnis-Label (rechts neben dem Button, in der gleichen Zeile – 38px hoch)
$global:lblSmartRepairOverall = New-Object System.Windows.Forms.Label
$global:lblSmartRepairOverall.Text = ""
$global:lblSmartRepairOverall.Size = New-Object System.Drawing.Size(220, 35)
$global:lblSmartRepairOverall.Location = New-Object System.Drawing.Point(225, 0)
$global:lblSmartRepairOverall.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$global:lblSmartRepairOverall.ForeColor = [System.Drawing.Color]::FromArgb(160, 160, 160)
$global:lblSmartRepairOverall.BackColor = [System.Drawing.Color]::Transparent
$global:lblSmartRepairOverall.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
$global:tblSmartRepair.Controls.Add($global:lblSmartRepairOverall)

# -------- Hilfsfunktion: Check-Zeile aktualisieren (schreibt nur noch in outputBox) ----------
$global:srCheckLabels = @{}  # Leer-Hashtable für Rückwärtskompatibilität

function Update-SmartRepairRow {
    param([string]$Name, [string]$Status, [string]$Detail)
    # Keine separaten Labels mehr – Ergebnisse laufen über outputBox (schon in SmartRepair.psm1)
}

# -------- Hilfsfunktion: Status zurücksetzen ----------
function Reset-SmartRepairRows {
    $global:lblSmartRepairOverall.Text      = ""
    $global:lblSmartRepairOverall.ForeColor = [System.Drawing.Color]::FromArgb(160, 160, 160)
}

# -------- Click-Handler des Start-Buttons ----------
$btnStartSmartRepair.Add_Click({
    # Admin-Warnung (kein Block – einige Checks laufen auch ohne Admin)
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) {
        [System.Windows.Forms.MessageBox]::Show(
            "Smart Repair benoetigt Administrator-Rechte fuer einige Pruefschritte.`nBitte starten Sie das Tool als Administrator.",
            "Administrator-Rechte empfohlen",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        ) | Out-Null
    }

    # UI vorbereiten
    $btnStartSmartRepair.Enabled = $false
    $btnStartSmartRepair.Text    = "Analyse laeuft..."
    Reset-SmartRepairRows
    $outputBox.Clear()
    Switch-OutputView -viewName "outputView"
    Update-ProgressStatus -StatusText "Smart Repair wird ausgefuehrt..." -ProgressValue 0 -TextColor ([System.Drawing.Color]::White)

    # Fortschritt-Callback
    $progressCB = {
        param([int]$Step, [int]$Total, [string]$Name)
        $pct = [int](($Step / $Total) * 100)
        Update-ProgressStatus -StatusText "$Name ($Step/$Total)" -ProgressValue $pct -TextColor ([System.Drawing.Color]::White)
        [System.Windows.Forms.Application]::DoEvents()
    }

    # Check-Callback (nur DoEvents, outputBox schreibt das Modul direkt)
    $checkCB = {
        param([string]$Name, [string]$Status, [string]$Detail)
        [System.Windows.Forms.Application]::DoEvents()
    }

    try {
        # Prüfe ob Funktion verfügbar (Modul geladen?)
        if (-not (Get-Command -Name Invoke-SmartRepair -ErrorAction SilentlyContinue)) {
            throw [System.Exception]::new("[E-001] Modul 'SmartRepair' nicht geladen. Starten Sie das Tool neu.")
        }

        $smartResult = Invoke-SmartRepair `
            -OutputBox        $outputBox `
            -ProgressBar      $progressBar `
            -ProgressCallback $progressCB `
            -OnCheckComplete  $checkCB

        # Exit-Code aus Ergebnis ableiten
        $global:lastSmartRepairExitCode = switch ($smartResult.Overall) {
            "Green"  { 0 }   # E-000: Alles OK
            "Yellow" { 1 }   # E-001: Warnungen
            "Red"    { 2 }   # E-002: Kritisch
            default  { -1 }
        }

        switch ($smartResult.Overall) {
            "Green"  {
                $global:lblSmartRepairOverall.Text      = "  Alles OK  [Exit 0]"
                $global:lblSmartRepairOverall.ForeColor = [System.Drawing.Color]::FromArgb(80, 200, 80)
                Update-ProgressStatus -StatusText "Smart Repair: Alles OK (Exit 0)" -ProgressValue 100 -TextColor ([System.Drawing.Color]::LimeGreen)
            }
            "Yellow" {
                $global:lblSmartRepairOverall.Text      = "  Kleinere Probleme  [Exit 1]"
                $global:lblSmartRepairOverall.ForeColor = [System.Drawing.Color]::FromArgb(220, 180, 40)
                Update-ProgressStatus -StatusText "Smart Repair: Kleinere Probleme (Exit 1)" -ProgressValue 100 -TextColor ([System.Drawing.Color]::Orange)
            }
            "Red"    {
                $global:lblSmartRepairOverall.Text      = "  Kritische Probleme!  [Exit 2]"
                $global:lblSmartRepairOverall.ForeColor = [System.Drawing.Color]::FromArgb(220, 60, 60)
                Update-ProgressStatus -StatusText "Smart Repair: Kritische Probleme! (Exit 2)" -ProgressValue 100 -TextColor ([System.Drawing.Color]::Red)
            }
        }

        # ---- Optionaler Repair-Dialog wenn tiefergehende Scans empfohlen ----
        if ($smartResult -and ($smartResult.NeedsSFCscan -or $smartResult.NeedsDISMscan -or $smartResult.NeedsChkdsk)) {
            $repairMsg = "Smart Repair hat folgende tiefergehende Scans empfohlen:`r`n`r`n"
            if ($smartResult.NeedsSFCscan)  { $repairMsg += "  ‣  SFC /scannow        (System File Checker)`r`n" }
            if ($smartResult.NeedsDISMscan) { $repairMsg += "  ‣  DISM /ScanHealth     (Komponentenspeicher)`r`n" }
            if ($smartResult.NeedsChkdsk)   { $repairMsg += "  ‣  CHKDSK              (Datenträgerprüfung)`r`n" }
            $repairMsg += "`r`nDiese Scans finden Sie unter 'Diagnose & Reparatur'.`r`nJetzt dorthin navigieren?"

            $repairChoice = [System.Windows.Forms.MessageBox]::Show(
                $repairMsg,
                "Tiefergehende Scans empfohlen",
                [System.Windows.Forms.MessageBoxButtons]::YesNo,
                [System.Windows.Forms.MessageBoxIcon]::Information
            )

            if ($repairChoice -eq [System.Windows.Forms.DialogResult]::Yes) {
                # Disk-Panel aufklappen (enthält DISM, CHKDSK, SFC)
                if ($diskPanel -and $diskPanel.Header) {
                    $diskPanel.Header.PerformClick()
                }
            }
        }
    }
    catch {
        $errMsg   = $_.Exception.Message
        $errLine  = $_.InvocationInfo.ScriptLineNumber
        $errFile  = if ($_.InvocationInfo.ScriptName) { [System.IO.Path]::GetFileName($_.InvocationInfo.ScriptName) } else { 'n/a' }
        $exitCode = if ($errMsg -match '\[E-\d+\]') { ($errMsg | Select-String '\[E-(\d+)\]').Matches[0].Groups[1].Value } else { '99' }

        $global:lastSmartRepairExitCode = [int]$exitCode
        $global:lblSmartRepairOverall.Text      = "  Fehler  [Exit $exitCode]"
        $global:lblSmartRepairOverall.ForeColor = [System.Drawing.Color]::FromArgb(220, 60, 60)
        Update-ProgressStatus -StatusText "Smart Repair: Fehler (Exit $exitCode)" -ProgressValue 0 -TextColor ([System.Drawing.Color]::Red)
        Write-ToolLog -ToolName "SmartRepair" -Message "[Exit $exitCode] $errMsg (Zeile $errLine in $errFile)" -Level "Error"

        # Fehler in outputBox schreiben damit User ihn sehen kann
        try {
            $outputBox.SelectionStart  = $outputBox.TextLength
            $outputBox.SelectionLength = 0
            $outputBox.SelectionColor  = [System.Drawing.Color]::FromArgb(220, 60, 60)
            $outputBox.AppendText("`r`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`r`n")
            $outputBox.AppendText("  SMART REPAIR FEHLER  [Exit Code $exitCode]`r`n")
            $outputBox.AppendText("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`r`n`r`n")
            $outputBox.SelectionColor  = [System.Drawing.Color]::FromArgb(220, 180, 40)
            $outputBox.AppendText("  Fehlermeldung:`r`n  $errMsg`r`n`r`n")
            $outputBox.SelectionColor  = [System.Drawing.Color]::FromArgb(140, 140, 140)
            $outputBox.AppendText("  Ort:  $errFile  (Zeile $errLine)`r`n")
            $outputBox.AppendText("`r`n  Exit-Code Referenz:`r`n")
            $outputBox.AppendText("    Exit 0  = Alles OK`r`n")
            $outputBox.AppendText("    Exit 1  = Warnungen / kleinere Probleme`r`n")
            $outputBox.AppendText("    Exit 2  = Kritische Probleme`r`n")
            $outputBox.AppendText("    Exit 99 = Unerwarteter Fehler in Smart Repair`r`n")
            $outputBox.AppendText("    E-001   = Modul nicht geladen (Tool neu starten)`r`n")
            $outputBox.SelectionColor  = $outputBox.ForeColor
            $outputBox.ScrollToCaret()
        } catch {}
    }
    finally {
        $btnStartSmartRepair.Enabled = $true
        $btnStartSmartRepair.Text    = "Smart Repair starten"
    }
})

# Sidebar-Nav-Button des SmartRepair-Panels verlinken
$global:btnStartSmartRepairNav.Add_Click({
    # sicherstellen dass Panel sichtbar ist, dann starten
    if ($global:tblSmartRepair.Visible) {
        $btnStartSmartRepair.PerformClick()
    }
})

# Hilfsvariable für aktives Systempanel
$script:currentSystemView = "securityView"

# Event-Handler wurden in die Collapsible Panels integriert (siehe New-CollapsiblePanel OnExpand)

# Info-Buttons für die Panels erstellen
$infoButtonSystem = New-ModernInfoButton -x 940 -y 10 -clickAction {
    [System.Windows.Forms.MessageBox]::Show(
        "System & Sicherheit Übersicht:

Dieser Bereich enthält Tools zur Diagnose, Wartung und Absicherung des Windows-Betriebssystems:

• System & Sicherheit: MRT-Scans und Windows Defender zur Malware-Erkennung
• System-Wartung: SFC Check zur Reparatur von Windows-Dateien und Windows Update

Verwenden Sie diese Tools, wenn Ihr System instabil ist, Sie Sicherheitsprobleme vermuten oder grundlegende Systemprüfungen durchführen möchten.",
        "System & Sicherheit Hilfe",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Information
    )
}
$mainContentPanel.Controls.Add($infoButtonSystem)

$infoButtonDisk = New-ModernInfoButton -x 940 -y 10 -clickAction {
    [System.Windows.Forms.MessageBox]::Show(
        "Diagnose & Reparatur Übersicht:

Diese Tools helfen bei der Diagnose und Reparatur von Festplatten-, Arbeitsspeicher- und Windows-Image-Problemen:

• Diagnose: Memory Diagnostic zur Überprüfung des Arbeitsspeichers
• Festplatten-Prüfung: CHKDSK zum Erkennen und Reparieren von Laufwerksfehlern
• System-Reparatur (DISM): Werkzeuge zur Reparatur des Windows-Abbilds

Verwenden Sie diese Tools bei ungewöhnlichem Systemverhalten, Abstürzen, Speicherproblemen oder wenn Anzeichen auf Festplatten- oder Image-Probleme hindeuten.",
        "Diagnose & Reparatur Hilfe",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Information
    )
}
$mainContentPanel.Controls.Add($infoButtonDisk)

$infoButtonNetwork = New-ModernInfoButton -x 940 -y 10 -clickAction {
    [System.Windows.Forms.MessageBox]::Show(
        "Netzwerk-Tools Übersicht:

Tools zur Diagnose und Behebung von Netzwerkproblemen:

• Netzwerk-Diagnose: Ping-Tests zur Überprüfung der Verbindungsqualität
• Netzwerk-Reparatur: Zurücksetzen von Netzwerkadaptern bei Verbindungsproblemen

Verwenden Sie diese Funktionen bei Internetzugangsproblemen, langsamen Verbindungen oder Netzwerkfehlern.",
        "Netzwerk-Tools Hilfe",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Information
    )
}
$mainContentPanel.Controls.Add($infoButtonNetwork)

$infoButtonCleanup = New-ModernInfoButton -x 940 -y 10 -clickAction {
    [System.Windows.Forms.MessageBox]::Show(
        "Bereinigung Übersicht:

Tools zur Systemoptimierung und Freigabe von Speicherplatz:

• System-Bereinigung: Disk Cleanup zum Entfernen unnötiger Systemdateien
• Temporäre Dateien: Optionen zur Bereinigung temporärer Dateien mit unterschiedlicher Tiefe

Regelmäßige Bereinigung kann die Systemleistung verbessern und wertvollen Speicherplatz freigeben.",
        "Bereinigung Hilfe",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Information
    )
}
$mainContentPanel.Controls.Add($infoButtonCleanup)

# System-Unterbuttons wurden bereits in den Collapsible Panels definiert (siehe oben)

# Funktion zum Umschalten der Sichtbarkeit von System-Controls
function Switch-SystemControls {
    # Alle Controls im tblSystem durchlaufen und je nach Tag ein-/ausblenden
    foreach ($control in $global:tblSystem.Controls) {
        if ($control.Tag -eq "securityControl") {
            $control.Visible = $script:securityControlsVisible
        }
        elseif ($control.Tag -eq "maintenanceControl") {
            $control.Visible = $script:maintenanceControlsVisible
        }
    }
 }
function Switch-DiskControls {
    # Alle Controls im tblDisk durchlaufen und je nach Tag ein-/ausblenden
    foreach ($control in $tblDisk.Controls) {
        if ($control.Tag -eq "diagnoseControl") {
            $control.Visible = $script:diagnoseControlsVisible
        }
        elseif ($control.Tag -eq "repairControl") {
            $control.Visible = $script:repairControlsVisible
        }
    }
}

# Hilfsvariablen für Disk-Ansichten
$script:currentDiskView = "diagnoseView"
$script:diagnoseControlsVisible = $true
$script:repairControlsVisible = $false


# Funktion zur Steuerung der Netzwerk-Ansichten
function Switch-NetworkControls {
    # Alle Controls im tblNetwork durchlaufen und je nach Tag ein-/ausblenden
    foreach ($control in $tblNetwork.Controls) {
        if ($control.Tag -eq "networkDiagnosticsControl") {
            $control.Visible = $script:networkDiagnosticsControlsVisible
        }
        elseif ($control.Tag -eq "networkRepairControl") {
            $control.Visible = $script:networkRepairControlsVisible
        }
    }
}

# Funktion zur Steuerung der Bereinigung-Ansichten
function Switch-CleanupControls {
    # Alle Controls im tblCleanup durchlaufen und je nach Tag ein-/ausblenden
    foreach ($control in $tblCleanup.Controls) {
        if ($control.Tag -eq "cleanupSystemControl") {
            $control.Visible = $script:cleanupSystemControlsVisible
        }
        elseif ($control.Tag -eq "cleanupTempControl") {
            $control.Visible = $script:cleanupTempControlsVisible
        }
    }
}


# Hilfsvariablen für Netzwerk-Ansichten
$script:currentNetworkView = "networkDiagnosticsView"
$script:networkDiagnosticsControlsVisible = $true
$script:networkRepairControlsVisible = $false


# Hilfsvariablen für Bereinigungs-Ansichten
$script:currentCleanupView = "cleanupSystemView"
$script:cleanupSystemControlsVisible = $true
$script:cleanupTempControlsVisible = $false

# Cleanup-Unterbuttons wurden bereits in den Collapsible Panels definiert

# tblCleanup wurde bereits weiter oben erstellt und zum mainContentPanel hinzugefügt

# Erstelle ein Panel für die verschiedenen Ausgabebereiche - direkt im mainform
$outputPanel = New-Object System.Windows.Forms.Panel
$outputPanel.Location = New-Object System.Drawing.Point(225, 180)  # Button-Panels breiter gemacht
$outputPanel.Size = New-Object System.Drawing.Size(765, 560)  # Breite für breitere Button-Panels reduziert
$outputPanel.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)  # Dunkles Grau wie Hauptfenster
$mainform.Controls.Add($outputPanel)

# PowerShell-Konsolenfenster-Steuerung mit P/Invoke (nach der Logo-Funktion, vor den Modul-Importen)
if (-not ([System.Management.Automation.PSTypeName]'ConsoleHelper').Type) {
Add-Type @"
using System;
using System.Runtime.InteropServices;

[StructLayout(LayoutKind.Sequential)]
public struct RECT {
    public int Left;
    public int Top;
    public int Right;
    public int Bottom;
}

public class ConsoleHelper {
    [DllImport("kernel32.dll")]
    public static extern IntPtr GetConsoleWindow();
    
    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
    
    [DllImport("user32.dll")]
    public static extern bool MoveWindow(IntPtr hWnd, int X, int Y, int nWidth, int nHeight, bool bRepaint);
    
    [DllImport("user32.dll")]
    public static extern bool GetWindowRect(IntPtr hWnd, ref RECT lpRect);
    
    public const int SW_HIDE = 0;
    public const int SW_SHOW = 5;
    
    public static void HideConsole() {
        IntPtr handle = GetConsoleWindow();
        ShowWindow(handle, SW_HIDE);
    }
    
    public static void ShowConsole() {
        IntPtr handle = GetConsoleWindow();
        ShowWindow(handle, SW_SHOW);
    }
    
    public static bool IsConsoleVisible() {
        IntPtr handle = GetConsoleWindow();
        return IsWindowVisible(handle);
    }
    
    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    static extern bool IsWindowVisible(IntPtr hWnd);
}
"@ -ReferencedAssemblies "System.Windows.Forms", "System.Drawing" -ErrorAction SilentlyContinue
}

# Globale Variable für Konsolen-Status
$script:consoleAutoHidden = $false

# Funktion zum Positionieren der Konsole links neben der GUI
function Set-ConsolePositionNextToGUI {
    param(
        [switch]$UseTimer
    )
    try {
        $consoleHandle = [ConsoleHelper]::GetConsoleWindow()
        if ($consoleHandle -ne [IntPtr]::Zero) {
            # Sicherstellen, dass die Form-Dimensionen korrekt geladen sind
            $mainform.Refresh()
            [System.Windows.Forms.Application]::DoEvents()
            
            # Konsolengröße an GUI-ClientSize anpassen (nicht skalierte Pixel)
            # Breite: GUI ClientSize minus 100 Pixel
            # Höhe: 70% der GUI ClientSize
            $consoleWidth = [int]($mainform.ClientSize.Width - 120)
            $consoleHeight = [int]($mainform.ClientSize.Height * 0.7)
            
            # Neue Position für PowerShell-Fenster berechnen (links neben der GUI)
            $newConsoleLeft = [Math]::Max(0, $mainform.Left - $consoleWidth - 10) # 10 Pixel Abstand
            $newConsoleTop = $mainform.Top
            
            # Konsolenfenster mit fester Proportion zur GUI positionieren
            [void][ConsoleHelper]::MoveWindow($consoleHandle, $newConsoleLeft, $newConsoleTop, $consoleWidth, $consoleHeight, $true)
            
            # Bei Bedarf mit Timer eine Nachkorrektur durchführen (für initiale Anpassung)
            if ($UseTimer) {
                $script:consoleSizeTimer = New-Object System.Windows.Forms.Timer
                $script:consoleSizeTimer.Interval = 150
                $script:consoleSizeTimer.Add_Tick({
                    try {
                        $consoleHandle = [ConsoleHelper]::GetConsoleWindow()
                        if ($consoleHandle -ne [IntPtr]::Zero -and [ConsoleHelper]::IsConsoleVisible()) {
                            $consoleWidth = [int]($mainform.ClientSize.Width - 120)
                            $consoleHeight = [int]($mainform.ClientSize.Height * 0.7)
                            $newConsoleLeft = [Math]::Max(0, $mainform.Left - $consoleWidth - 10)
                            $newConsoleTop = $mainform.Top
                            [void][ConsoleHelper]::MoveWindow($consoleHandle, $newConsoleLeft, $newConsoleTop, $consoleWidth, $consoleHeight, $true)
                        }
                    }
                    catch {
                        Write-Verbose "Fehler bei Timer-basierter Konsolenpositionierung: $_"
                    }
                    finally {
                        $this.Stop()
                        $this.Dispose()
                    }
                })
                $script:consoleSizeTimer.Start()
            }
        }
    }
    catch {
        Write-Verbose "Fehler beim Positionieren der Konsole: $_"
    }
}

# Funktion zum automatischen Ausblenden der Konsole
function Hide-ConsoleAutomatically {
    try {
        if (-not $script:consoleAutoHidden) {
            [ConsoleHelper]::HideConsole()
            $script:consoleAutoHidden = $true
            Write-Verbose "Konsole wurde automatisch ausgeblendet"
        }
    }
    catch {
        Write-Warning "Fehler beim Ausblenden der Konsole: $_"
    }
}

# Funktion zum automatischen Einblenden der Konsole (wenn Tool läuft)
function Show-ConsoleForToolExecution {
    try {
        if ($script:consoleAutoHidden) {
            [ConsoleHelper]::ShowConsole()
            Write-Verbose "Konsole wurde für Tool-Ausführung eingeblendet"
        }
    }
    catch {
        Write-Warning "Fehler beim Einblenden der Konsole: $_"
    }
}

# Funktion zum Umschalten der Konsolen-Sichtbarkeit (manuell)
function Switch-ConsoleVisibility {
    try {
        if ([ConsoleHelper]::IsConsoleVisible()) {
            [ConsoleHelper]::HideConsole()
            $script:consoleAutoHidden = $true
            return $false
        }
        else {
            [ConsoleHelper]::ShowConsole()
            $script:consoleAutoHidden = $false
            
            # Konsole fix 10 Pixel links neben GUI positionieren
            # Mit -UseTimer Parameter für asynchrone Nachkorrektur ohne Blocking
            Set-ConsolePositionNextToGUI -UseTimer
            
            return $true
        }
    }
    catch {
        Write-Warning "Fehler beim Umschalten der Konsolen-Sichtbarkeit: $_"
        return $false
    }
}

# ... (Rest des Codes bleibt unverändert bis zur Definition des outputButtonPanel)

# ===================================================================
# MODERNER 3-IN-1 BUTTON (Toggle | CMD Admin | Ausgabe)
# ===================================================================

# Links: PowerShell-Toggle-Button
$btnToggleConsole = New-Object System.Windows.Forms.Button
$btnToggleConsole.Text = "◄"
$btnToggleConsole.Size = New-Object System.Drawing.Size(45, 35)
$btnToggleConsole.Location = New-Object System.Drawing.Point(20, 3)
$btnToggleConsole.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnToggleConsole.FlatAppearance.BorderSize = 0
$btnToggleConsole.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
$btnToggleConsole.FlatAppearance.MouseDownBackColor = [System.Drawing.Color]::FromArgb(60, 60, 60)
$btnToggleConsole.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
$btnToggleConsole.ForeColor = [System.Drawing.Color]::White
$btnToggleConsole.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)

# Runde Ecken nur links
$toggleRegion = [System.Drawing.Drawing2D.GraphicsPath]::new()
$toggleRect = New-Object System.Drawing.Rectangle(0, 0, $btnToggleConsole.Width, $btnToggleConsole.Height)
$toggleRadius = 6
$toggleRegion.AddArc($toggleRect.Left, $toggleRect.Top, ($toggleRadius * 2), ($toggleRadius * 2), 180, 90)
$toggleRegion.AddLine(($toggleRect.Left + $toggleRadius), $toggleRect.Top, $toggleRect.Right, $toggleRect.Top)
$toggleRegion.AddLine($toggleRect.Right, $toggleRect.Top, $toggleRect.Right, $toggleRect.Bottom)
$toggleRegion.AddLine($toggleRect.Right, $toggleRect.Bottom, ($toggleRect.Left + $toggleRadius), $toggleRect.Bottom)
$toggleRegion.AddArc($toggleRect.Left, ($toggleRect.Bottom - ($toggleRadius * 2)), ($toggleRadius * 2), ($toggleRadius * 2), 90, 90)
$toggleRegion.AddLine($toggleRect.Left, ($toggleRect.Bottom - $toggleRadius), $toggleRect.Left, ($toggleRect.Top + $toggleRadius))
$toggleRegion.CloseFigure()
$btnToggleConsole.Region = New-Object System.Drawing.Region($toggleRegion)

$btnToggleConsole.Add_Click({
    try {
        $visible = Switch-ConsoleVisibility
        
        if ($visible) {
            $btnToggleConsole.BackColor = [System.Drawing.Color]::FromArgb(55, 55, 55)
            $btnToggleConsole.Text = "◄"
            if ($tooltipObj) { $tooltipObj.SetToolTip($btnToggleConsole, "PowerShell-Konsole ausblenden") }
        }
        else {
            $btnToggleConsole.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
            $btnToggleConsole.Text = "►"
            if ($tooltipObj) { $tooltipObj.SetToolTip($btnToggleConsole, "PowerShell-Konsole einblenden") }
        }
        
        # Region neu setzen
        $toggleRegion = [System.Drawing.Drawing2D.GraphicsPath]::new()
        $toggleRect = New-Object System.Drawing.Rectangle(0, 0, $btnToggleConsole.Width, $btnToggleConsole.Height)
        $toggleRadius = 6
        $toggleRegion.AddArc($toggleRect.Left, $toggleRect.Top, ($toggleRadius * 2), ($toggleRadius * 2), 180, 90)
        $toggleRegion.AddLine(($toggleRect.Left + $toggleRadius), $toggleRect.Top, $toggleRect.Right, $toggleRect.Top)
        $toggleRegion.AddLine($toggleRect.Right, $toggleRect.Top, $toggleRect.Right, $toggleRect.Bottom)
        $toggleRegion.AddLine($toggleRect.Right, $toggleRect.Bottom, ($toggleRect.Left + $toggleRadius), $toggleRect.Bottom)
        $toggleRegion.AddArc($toggleRect.Left, ($toggleRect.Bottom - ($toggleRadius * 2)), ($toggleRadius * 2), ($toggleRadius * 2), 90, 90)
        $toggleRegion.AddLine($toggleRect.Left, ($toggleRect.Bottom - $toggleRadius), $toggleRect.Left, ($toggleRect.Top + $toggleRadius))
        $toggleRegion.CloseFigure()
        $btnToggleConsole.Region = New-Object System.Drawing.Region($toggleRegion)
    }
    catch {
        Write-Verbose "Fehler beim Toggle der Konsole: $_"
    }
})
$btnToggleConsole.Add_MouseEnter({ 
    try {
        if (-not [ConsoleHelper]::IsConsoleVisible()) {
            $this.BackColor = [System.Drawing.Color]::FromArgb(55, 55, 55)
        }
    } catch { }
})
$btnToggleConsole.Add_MouseLeave({ 
    try {
        if ([ConsoleHelper]::IsConsoleVisible()) {
            $this.BackColor = [System.Drawing.Color]::FromArgb(55, 55, 55)
        }
        else {
            $this.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
        }
    } catch { }
})
$outputButtonPanel.Controls.Add($btnToggleConsole)

if ($tooltipObj) {
    $tooltipObj.SetToolTip($btnToggleConsole, "PowerShell-Konsole ein-/ausblenden (F12)")
}

# Mitte: CMD Admin-Button (ohne runde Ecken)
$btnCMDQuick = New-Object System.Windows.Forms.Button
$btnCMDQuick.Text = "⚡    CMD"
$btnCMDQuick.Size = New-Object System.Drawing.Size(83, 35)
$btnCMDQuick.Location = New-Object System.Drawing.Point(66, 3)
$btnCMDQuick.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnCMDQuick.FlatAppearance.BorderSize = 0
$btnCMDQuick.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
$btnCMDQuick.FlatAppearance.MouseDownBackColor = [System.Drawing.Color]::FromArgb(60, 60, 60)
$btnCMDQuick.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
$btnCMDQuick.ForeColor = [System.Drawing.Color]::Gold
$btnCMDQuick.Font = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Bold)

# Variable für CMD-Prozess speichern
$script:cmdProcess = $null

$btnCMDQuick.Add_Click({
    try {
        # Prüfen ob CMD bereits geöffnet ist
        if ($script:cmdProcess -and -not $script:cmdProcess.HasExited) {
            # CMD schließen
            $script:cmdProcess.CloseMainWindow()
            Start-Sleep -Milliseconds 100
            if (-not $script:cmdProcess.HasExited) {
                $script:cmdProcess.Kill()
            }
            $script:cmdProcess = $null
            
            # Button zurücksetzen
            $btnCMDQuick.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
            $btnCMDQuick.ForeColor = [System.Drawing.Color]::Gold
            if ($tooltipObj) {
                $tooltipObj.SetToolTip($btnCMDQuick, "Eingabeaufforderung als Administrator öffnen")
            }
            Update-ProgressStatus -StatusText "CMD geschlossen" -ProgressValue 100 -TextColor ([System.Drawing.Color]::Orange)
        }
        else {
            # CMD öffnen
            $psi = New-Object System.Diagnostics.ProcessStartInfo
            $psi.FileName = "cmd.exe"
            $psi.Verb = "runas"
            $psi.UseShellExecute = $true
            
            $script:cmdProcess = [System.Diagnostics.Process]::Start($psi)
            
            if ($script:cmdProcess) {
                # Button hervorheben
                $btnCMDQuick.BackColor = [System.Drawing.Color]::FromArgb(60, 60, 60)
                $btnCMDQuick.ForeColor = [System.Drawing.Color]::LightGreen
                if ($tooltipObj) {
                    $tooltipObj.SetToolTip($btnCMDQuick, "CMD schließen (aktuell geöffnet)")
                }
                Update-ProgressStatus -StatusText "CMD als Admin geöffnet" -ProgressValue 100 -TextColor ([System.Drawing.Color]::LightGreen)
            }
        }
    }
    catch {
        if ($_.Exception.Message -like "*abgebrochen*") {
            Update-ProgressStatus -StatusText "Abgebrochen" -ProgressValue 0 -TextColor ([System.Drawing.Color]::Orange)
        }
        else {
            Update-ProgressStatus -StatusText "Fehler: $_" -ProgressValue 0 -TextColor ([System.Drawing.Color]::Red)
        }
    }
})
$btnCMDQuick.Add_MouseEnter({ 
    if (-not $script:cmdProcess -or $script:cmdProcess.HasExited) {
        $this.BackColor = [System.Drawing.Color]::FromArgb(60, 60, 60)
    }
})
$btnCMDQuick.Add_MouseLeave({ 
    if (-not $script:cmdProcess -or $script:cmdProcess.HasExited) {
        $this.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
    }
})
$outputButtonPanel.Controls.Add($btnCMDQuick)

if ($tooltipObj) {
    $tooltipObj.SetToolTip($btnCMDQuick, "Eingabeaufforderung als Administrator öffnen")
}

# Rechts: Ausgabe-Button mit Pfeil
$btnOutput = New-Object System.Windows.Forms.Button
$btnOutput.Text = "►"
$btnOutput.Size = New-Object System.Drawing.Size(45, 35)
$btnOutput.Location = New-Object System.Drawing.Point(150, 3)
$btnOutput.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnOutput.FlatAppearance.BorderSize = 0
$btnOutput.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
$btnOutput.FlatAppearance.MouseDownBackColor = [System.Drawing.Color]::FromArgb(60, 60, 60)
$btnOutput.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
$btnOutput.ForeColor = [System.Drawing.Color]::White
$btnOutput.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$btnOutput.Tag = "outputView"

# Runde Ecken nur rechts
$outputRegion = [System.Drawing.Drawing2D.GraphicsPath]::new()
$outputRect = New-Object System.Drawing.Rectangle(0, 0, $btnOutput.Width, $btnOutput.Height)
$outputRadius = 6
$outputRegion.AddLine($outputRect.Left, $outputRect.Top, ($outputRect.Right - $outputRadius), $outputRect.Top)
$outputRegion.AddArc(($outputRect.Right - ($outputRadius * 2)), $outputRect.Top, ($outputRadius * 2), ($outputRadius * 2), 270, 90)
$outputRegion.AddLine($outputRect.Right, ($outputRect.Top + $outputRadius), $outputRect.Right, ($outputRect.Bottom - $outputRadius))
$outputRegion.AddArc(($outputRect.Right - ($outputRadius * 2)), ($outputRect.Bottom - ($outputRadius * 2)), ($outputRadius * 2), ($outputRadius * 2), 0, 90)
$outputRegion.AddLine(($outputRect.Right - $outputRadius), $outputRect.Bottom, $outputRect.Left, $outputRect.Bottom)
$outputRegion.AddLine($outputRect.Left, $outputRect.Bottom, $outputRect.Left, $outputRect.Top)
$outputRegion.CloseFigure()
$btnOutput.Region = New-Object System.Drawing.Region($outputRegion)

# Toggle-Funktionalität für Ausgabe-Button
$script:previousView = "outputView"  # Speichert die vorherige Ansicht

# HINWEIS: Der eigentliche Click-Event wird später definiert (nach allen View-Panels)

$btnOutput.Add_MouseEnter({
    if ($script:currentView -ne "outputView") {
        $this.BackColor = [System.Drawing.Color]::FromArgb(55, 55, 55)
    }
})

$btnOutput.Add_MouseLeave({
    if ($script:currentView -eq "outputView") {
        $this.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
    }
    else {
        $this.BackColor = [System.Drawing.Color]::FromArgb(55, 55, 55)
    }
})

$outputButtonPanel.Controls.Add($btnOutput)

if ($tooltipObj) {
    $tooltipObj.SetToolTip($btnOutput, "Zur vorherigen Ansicht wechseln")
}

# Vertikaler Trenner rechts neben dem 3-in-1 Button
$toggleSeparator = New-Object System.Windows.Forms.Label
$toggleSeparator.Location = New-Object System.Drawing.Point(215, 8)
$toggleSeparator.Size = New-Object System.Drawing.Size(2, 28)
$toggleSeparator.BackColor = [System.Drawing.Color]::FromArgb(120, 120, 120)
$toggleSeparator.BorderStyle = [System.Windows.Forms.BorderStyle]::None
$outputButtonPanel.Controls.Add($toggleSeparator)


#------------------------------------------------------------------------------------------------------------
# HORIZONTALE INFO-PANELS IM MAIN-CONTENT-PANEL (oben rechts)
#------------------------------------------------------------------------------------------------------------

# Erstelle horizontales Collapsible Panel für Informationen (im mainContentPanel)
$infoHorizontalPanel = New-HorizontalCollapsiblePanel -Title "Informationen" -XPosition 10 -Tag "infoHorizontalPanel" -ParentPanel $mainContentPanel -IconCode 0xE946 -OnExpand {
    # Wechsle zur Output-View
    if ($outputViewPanel) { $outputViewPanel.Visible = $true }
    if ($statusViewPanel) { $statusViewPanel.Visible = $false }
    if ($hardwareViewPanel) { $hardwareViewPanel.Visible = $false }
    if ($toolInfoViewPanel) { $toolInfoViewPanel.Visible = $false }
    if ($downloadsViewPanel) { $downloadsViewPanel.Visible = $false }
    
    # Suchfeld ausblenden
    if ($searchPanel) { $searchPanel.Visible = $false }

    # Abhängigkeits-Tabelle ausblenden
    if ($script:dependencyTableHost) { $script:dependencyTableHost.Visible = $false }

    # Standard-Output wieder einblenden
    if ($outputBox) { $outputBox.Visible = $true }
    
    # Horizontale Container wieder sichtbar machen
    if ($infoHorizontalPanel -and $infoHorizontalPanel.Container) {
        $infoHorizontalPanel.Container.Visible = $true
    }
    if ($troubleshootHorizontalPanel -and $troubleshootHorizontalPanel.Container) {
        $troubleshootHorizontalPanel.Container.Visible = $true
    }
    
    # OutputBox leeren und Info anzeigen
    $outputBox.Clear()
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'BannerFrame'
    $outputBox.AppendText("`t╔═══════════════════════════════════════════════════════════════╗`r`n")
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'BannerTitle'
    $outputBox.AppendText("`t║                  SYSTEM-INFORMATIONEN                         ║`r`n")
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'BannerFrame'
    $outputBox.AppendText("`t╚═══════════════════════════════════════════════════════════════╝`r`n`r`n")
    
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Heading'
    $outputBox.AppendText("Verfügbare Ansichten:`r`n`r`n")
    
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Accent'
    Add-OutputIcon -OutputBox $outputBox -IconCode 0xE9D9
    $outputBox.AppendText(" STATUS-INFO:`r`n")
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Info'
    $outputBox.AppendText("  • Umfassende Systemstatus-Übersicht mit Live-Updates`r`n")
    $outputBox.AppendText("  • Betriebssystem-Details (Version, Build, Lizenz-Status)`r`n")
    $outputBox.AppendText("  • Uptime und letzte Boot-Zeit`r`n")
    $outputBox.AppendText("  • Installierte Updates und Hotfixes`r`n")
    $outputBox.AppendText("  • Laufwerks-Status und verfügbarer Speicherplatz`r`n`r`n")
    
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Accent'
    Add-OutputIcon -OutputBox $outputBox -IconCode 0xE7F8
    $outputBox.AppendText(" HARDWARE-INFO:`r`n")
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Info'
    $outputBox.AppendText("  • CPU: Prozessor-Spezifikationen (Kerne, Takt, Cache, Architektur)`r`n")
    $outputBox.AppendText("  • RAM: Arbeitsspeicher-Module, Kapazität und Auslastung`r`n")
    $outputBox.AppendText("  • GPU: Grafikkarten-Details und Video-RAM`r`n")
    $outputBox.AppendText("  • Mainboard: Hersteller, Modell und BIOS-Version`r`n")
    $outputBox.AppendText("  • Festplatten: Status, Kapazität und S.M.A.R.T.-Daten`r`n")
    $outputBox.AppendText("  • Netzwerk: Adapter-Details und IP-Konfiguration`r`n`r`n")
    
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Accent'
    Add-OutputIcon -OutputBox $outputBox -IconCode 0xE90F
    $outputBox.AppendText(" TOOL-INFO:`r`n")
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Info'
    $outputBox.AppendText("  • Detaillierte Beschreibungen aller verfügbaren Tools`r`n")
    $outputBox.AppendText("  • Verwendungszweck und Funktionsweise`r`n")
    $outputBox.AppendText("  • Empfohlene Anwendungsfälle`r`n")
    $outputBox.AppendText("  • Hinweise und Warnungen zu kritischen Tools`r`n`r`n")
    
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Muted'
    Add-OutputIcon -OutputBox $outputBox -IconCode 0xE946
    $outputBox.AppendText(" Tipp: Wählen Sie eine Info-Kategorie aus dem ausgeklappten Menü.`r`n")
}

# Setze Content-Panel-Größe für 3 Buttons nebeneinander
$infoHorizontalPanel.Content.Width = 435  # 3 Buttons × 145px
$infoHorizontalPanel.Content.Height = 35

# Erstelle die Info-Buttons horizontal im Content-Panel
$btnStatusInfoH = New-Object System.Windows.Forms.Button
$btnStatusInfoH.Text = "Status-Info"
$btnStatusInfoH.Size = New-Object System.Drawing.Size(145, 35)
$btnStatusInfoH.Location = New-Object System.Drawing.Point(0, 0)
$btnStatusInfoH.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnStatusInfoH.FlatAppearance.BorderSize = 0
$btnStatusInfoH.FlatAppearance.MouseOverBackColor = [System.Drawing.Color]::FromArgb(55, 55, 55)
$btnStatusInfoH.BackColor = [System.Drawing.Color]::FromArgb(37, 37, 38)
$btnStatusInfoH.ForeColor = [System.Drawing.Color]::White
$btnStatusInfoH.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$btnStatusInfoH.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
Add-ButtonIcon -Button $btnStatusInfoH -IconCode 0xE9D9 -IconSize 11 -LeftMargin 8

# Runde Ecken für Button (8px Radius)
try {
    $regionHandle = [RoundedCorners]::CreateRoundRectRgn(0, 0, $btnStatusInfoH.Width, $btnStatusInfoH.Height, 8, 8)
    if ($regionHandle -ne [IntPtr]::Zero) {
        $btnStatusInfoH.Region = [System.Drawing.Region]::FromHrgn($regionHandle)
    }
} catch {
    # Falls runde Ecken nicht funktionieren, einfach ohne weitermachen
}

$btnStatusInfoH.Add_Click({
    Switch-OutputView -viewName "statusView"
    
    $btnStatusInfoH.BackColor = [System.Drawing.Color]::FromArgb(55, 55, 55)
    $btnHardwareInfoH.BackColor = [System.Drawing.Color]::FromArgb(37, 37, 38)
    $btnToolInfoH.BackColor = [System.Drawing.Color]::FromArgb(37, 37, 38)
    
    if (-not $script:statusInfoLoaded) {
        $systemStatusBox.Clear()
        Set-OutputSelectionStyle -OutputBox $systemStatusBox -Style 'Info'
        $systemStatusBox.AppendText("System-Status wird geladen...`r`n")
        $progressBar.Value = 0
        $progressBar.CustomText = "Status wird geladen..."
        $progressBar.TextColor = [System.Drawing.Color]::White
        Get-SystemStatusSummary -statusBox $systemStatusBox -LiveMode
        $script:statusInfoLoaded = $true
    }
})
$infoHorizontalPanel.Content.Controls.Add($btnStatusInfoH)

$btnHardwareInfoH = New-Object System.Windows.Forms.Button
$btnHardwareInfoH.Text = "Hardware-Info"
$btnHardwareInfoH.Size = New-Object System.Drawing.Size(145, 35)
$btnHardwareInfoH.Location = New-Object System.Drawing.Point(145, 0)
$btnHardwareInfoH.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnHardwareInfoH.FlatAppearance.BorderSize = 0
$btnHardwareInfoH.FlatAppearance.MouseOverBackColor = [System.Drawing.Color]::FromArgb(55, 55, 55)
$btnHardwareInfoH.BackColor = [System.Drawing.Color]::FromArgb(37, 37, 38)
$btnHardwareInfoH.ForeColor = [System.Drawing.Color]::White
$btnHardwareInfoH.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$btnHardwareInfoH.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
Add-ButtonIcon -Button $btnHardwareInfoH -IconCode 0xE7F8 -IconSize 11 -LeftMargin 8

# Runde Ecken für Button (8px Radius)
try {
    $regionHandle = [RoundedCorners]::CreateRoundRectRgn(0, 0, $btnHardwareInfoH.Width, $btnHardwareInfoH.Height, 8, 8)
    if ($regionHandle -ne [IntPtr]::Zero) {
        $btnHardwareInfoH.Region = [System.Drawing.Region]::FromHrgn($regionHandle)
    }
} catch {
    # Falls runde Ecken nicht funktionieren, einfach ohne weitermachen
}

$btnHardwareInfoH.Add_Click({
    Switch-OutputView -viewName "hardwareView"
    
    $btnStatusInfoH.BackColor = [System.Drawing.Color]::FromArgb(37, 37, 38)
    $btnHardwareInfoH.BackColor = [System.Drawing.Color]::FromArgb(55, 55, 55)
    $btnToolInfoH.BackColor = [System.Drawing.Color]::FromArgb(37, 37, 38)
    
    if (-not $script:hardwareInfoLoaded) {
        Get-HardwareInfo -infoBox $hardwareInfoBox
        $script:hardwareInfoLoaded = $true
    }
})
$infoHorizontalPanel.Content.Controls.Add($btnHardwareInfoH)

$btnToolInfoH = New-Object System.Windows.Forms.Button
$btnToolInfoH.Text = "Tool-Info"
$btnToolInfoH.Size = New-Object System.Drawing.Size(145, 35)
$btnToolInfoH.Location = New-Object System.Drawing.Point(290, 0)
$btnToolInfoH.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnToolInfoH.FlatAppearance.BorderSize = 0
$btnToolInfoH.FlatAppearance.MouseOverBackColor = [System.Drawing.Color]::FromArgb(55, 55, 55)
$btnToolInfoH.BackColor = [System.Drawing.Color]::FromArgb(37, 37, 38)
$btnToolInfoH.ForeColor = [System.Drawing.Color]::White
$btnToolInfoH.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$btnToolInfoH.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
Add-ButtonIcon -Button $btnToolInfoH -IconCode 0xE90F -IconSize 11 -LeftMargin 8

# Runde Ecken für Button (8px Radius)
try {
    $regionHandle = [RoundedCorners]::CreateRoundRectRgn(0, 0, $btnToolInfoH.Width, $btnToolInfoH.Height, 8, 8)
    if ($regionHandle -ne [IntPtr]::Zero) {
        $btnToolInfoH.Region = [System.Drawing.Region]::FromHrgn($regionHandle)
    }
} catch {
    # Falls runde Ecken nicht funktionieren, einfach ohne weitermachen
}

$btnToolInfoH.Add_Click({
    Switch-OutputView -viewName "toolInfoView"
    
    $btnStatusInfoH.BackColor = [System.Drawing.Color]::FromArgb(37, 37, 38)
    $btnHardwareInfoH.BackColor = [System.Drawing.Color]::FromArgb(37, 37, 38)
    $btnToolInfoH.BackColor = [System.Drawing.Color]::FromArgb(55, 55, 55)
})
$infoHorizontalPanel.Content.Controls.Add($btnToolInfoH)

$mainContentPanel.Controls.Add($infoHorizontalPanel.Container)

# Erstelle horizontales Collapsible Panel für Problembehandlung (rechts neben Informationen)
$troubleshootHorizontalPanel = New-HorizontalCollapsiblePanel -Title "Support" -XPosition 170 -Tag "troubleshootHorizontalPanel" -ParentPanel $mainContentPanel -IconCode 0xE897 -OnExpand {
    if ($outputViewPanel) { $outputViewPanel.Visible = $true }
    if ($statusViewPanel) { $statusViewPanel.Visible = $false }
    if ($hardwareViewPanel) { $hardwareViewPanel.Visible = $false }
    if ($toolInfoViewPanel) { $toolInfoViewPanel.Visible = $false }
    
    # Suchfeld ausblenden
    if ($searchPanel) { $searchPanel.Visible = $false }

    # Abhängigkeits-Tabelle ausblenden
    if ($script:dependencyTableHost) { $script:dependencyTableHost.Visible = $false }

    # Standard-Output wieder einblenden
    if ($outputBox) { $outputBox.Visible = $true }
    
    # Horizontale Container wieder sichtbar machen
    if ($infoHorizontalPanel -and $infoHorizontalPanel.Container) {
        $infoHorizontalPanel.Container.Visible = $true
    }
    if ($troubleshootHorizontalPanel -and $troubleshootHorizontalPanel.Container) {
        $troubleshootHorizontalPanel.Container.Visible = $true
    }
}

# Setze Content-Panel-Breite für 1 Button
$troubleshootHorizontalPanel.Content.Width = 205
$troubleshootHorizontalPanel.Content.Height = 35

# Button: Status prüfen
$btnCheckDependenciesH = New-Object System.Windows.Forms.Button
$btnCheckDependenciesH.Text = "Status prüfen"
$btnCheckDependenciesH.Size = New-Object System.Drawing.Size(145, 35)
$btnCheckDependenciesH.Location = New-Object System.Drawing.Point(0, 0)
$btnCheckDependenciesH.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnCheckDependenciesH.FlatAppearance.BorderSize = 0
$btnCheckDependenciesH.FlatAppearance.MouseOverBackColor = [System.Drawing.Color]::FromArgb(55, 55, 55)
$btnCheckDependenciesH.BackColor = [System.Drawing.Color]::FromArgb(37, 37, 38)
$btnCheckDependenciesH.ForeColor = [System.Drawing.Color]::White
$btnCheckDependenciesH.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$btnCheckDependenciesH.Cursor = [System.Windows.Forms.Cursors]::Hand
Add-ButtonIcon -Button $btnCheckDependenciesH -IconCode 0xE721 -IconSize 12 -LeftMargin 10

# Runde Ecken für Button (8px Radius)
try {
    $regionHandle = [RoundedCorners]::CreateRoundRectRgn(0, 0, $btnCheckDependenciesH.Width, $btnCheckDependenciesH.Height, 8, 8)
    if ($regionHandle -ne [IntPtr]::Zero) {
        $btnCheckDependenciesH.Region = [System.Drawing.Region]::FromHrgn($regionHandle)
    }
} catch {
    # Falls runde Ecken nicht funktionieren, einfach ohne weitermachen
}

$btnCheckDependenciesH.Add_Click({
    $updateDependencyProgress = {
        param(
            [int]$Value,
            [string]$Text,
            [System.Drawing.Color]$Color = [System.Drawing.Color]::White
        )

        if ($progressBar) {
            $safeValue = [Math]::Max(0, [Math]::Min(100, $Value))
            $progressBar.Value = $safeValue
            $progressBar.CustomText = $Text
            $progressBar.TextColor = $Color
            [System.Windows.Forms.Application]::DoEvents()
        }
    }

    $scheduleDependencyProgressReset = {
        param([int]$DelayMs = 2500)

        if (-not $progressBar) { return }

        if ($script:dependencyProgressResetTimer) {
            try {
                $script:dependencyProgressResetTimer.Stop()
                $script:dependencyProgressResetTimer.Dispose()
            } catch {
                # Ignorieren
            }
            $script:dependencyProgressResetTimer = $null
        }

        $script:dependencyProgressResetTimer = New-Object System.Windows.Forms.Timer
        $script:dependencyProgressResetTimer.Interval = $DelayMs
        $script:dependencyProgressResetTimer.Add_Tick({
            if ($progressBar) {
                $progressBar.Value = 0
                $progressBar.CustomText = "Bereit"
                $progressBar.TextColor = [System.Drawing.Color]::White
            }
            $this.Stop()
            $this.Dispose()
            $script:dependencyProgressResetTimer = $null
        })
        $script:dependencyProgressResetTimer.Start()
    }

    & $updateDependencyProgress -Value 5 -Text "Initialisiere Abhängigkeitsprüfung..."

    # Verstecke alle Panels außer tblDependencies
    if ($global:tblSystem) { $global:tblSystem.Visible = $false }
    if ($tblDisk) { $tblDisk.Visible = $false }
    if ($tblNetwork) { $tblNetwork.Visible = $false }
    if ($tblCleanup) { $tblCleanup.Visible = $false }
    if ($global:tblDependencies) { $global:tblDependencies.Visible = $false }
    if ($global:tblSmartRepair) { $global:tblSmartRepair.Visible = $false }

    # Horizontale Header-Container sichtbar halten
    if ($infoHorizontalPanel -and $infoHorizontalPanel.Container) {
        $infoHorizontalPanel.Container.Visible = $true
        $infoHorizontalPanel.Container.BringToFront()
    }
    if ($troubleshootHorizontalPanel -and $troubleshootHorizontalPanel.Container) {
        $troubleshootHorizontalPanel.Container.Visible = $true
        $troubleshootHorizontalPanel.Container.BringToFront()
    }
    
    # Suchfeld ausblenden
    if ($searchPanel) { $searchPanel.Visible = $false }
    
    # Zeige OutputView
    if ($outputViewPanel) { $outputViewPanel.Visible = $true }
    if ($statusViewPanel) { $statusViewPanel.Visible = $false }
    if ($hardwareViewPanel) { $hardwareViewPanel.Visible = $false }
    if ($toolInfoViewPanel) { $toolInfoViewPanel.Visible = $false }

    # Dependency-Tabelle im Output-Bereich erstellen (wie Tool-Downloads: eigener Bereich mit Buttons)
    if (-not $script:dependencyTableHost -or $script:dependencyTableHost.IsDisposed) {
        $script:dependencyTableHost = New-Object System.Windows.Forms.Panel
        $script:dependencyTableHost.Dock = [System.Windows.Forms.DockStyle]::Fill
        $script:dependencyTableHost.BackColor = [System.Drawing.Color]::FromArgb(28, 28, 28)
        $script:dependencyTableHost.AutoScroll = $true
        $script:dependencyTableHost.Visible = $false

        if ($outputViewPanel) {
            $outputViewPanel.Controls.Add($script:dependencyTableHost)
        }
    }

    if ($script:dependencyTableHost) {
        $script:dependencyTableHost.Visible = $true
        $script:dependencyTableHost.BringToFront()
    }

    # Untere Ausgabe komplett ausblenden (nur Tabelle)
    if ($outputBox) { $outputBox.Visible = $false }

    & $updateDependencyProgress -Value 20 -Text "Prüfe System-Abhängigkeiten..."
    
    try {
        # DependencyChecker vor jeder Prüfung neu laden (stellt aktuelle Logik sicher)
        try {
            $dependencyModulePath = Join-Path $PSScriptRoot "Modules\Core\DependencyChecker.psm1"
            if (Test-Path $dependencyModulePath) {
                Import-Module $dependencyModulePath -Force -ErrorAction Stop
            }
        }
        catch {
            Write-Host "[WARN] DependencyChecker konnte nicht neu geladen werden: $($_.Exception.Message)" -ForegroundColor Yellow
        }

        # Hole Dependency-Status
        $depResult = Get-DependencyStatusForGUI -CurrentVersion $script:AppVersion
        & $updateDependencyProgress -Value 45 -Text "Analysiere Prüfergebnisse..."
        
        if (-not $depResult) {
            & $updateDependencyProgress -Value 100 -Text "Fehler beim Laden der Abhängigkeiten" -Color ([System.Drawing.Color]::Red)
            & $scheduleDependencyProgressReset -DelayMs 2500
            [System.Windows.Forms.MessageBox]::Show("Fehler beim Laden der Abhängigkeiten", "Abhängigkeitsprüfung", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
            return
        }

        $null = Update-DependencyListWithUpdates -Dependencies $depResult.Dependencies
        
        # Tabelle vorbereiten
        & $updateDependencyProgress -Value 65 -Text "Erstelle Übersicht..."
        
        # Tabelle mit Status + Aktionen im Output-Bereich erstellen
        & $updateDependencyProgress -Value 80 -Text "Bereite Installationsoptionen vor..."
        
        if ($script:dependencyTableHost) {
                $script:dependencyTableHost.Controls.Clear()

                $headerPanel = New-Object System.Windows.Forms.Panel
                $headerPanel.Location = New-Object System.Drawing.Point(0, 0)
                $headerPanel.Size = New-Object System.Drawing.Size(745, 28)
                $headerPanel.BackColor = [System.Drawing.Color]::FromArgb(45, 45, 45)

                $headerName = New-Object System.Windows.Forms.Label
                $headerName.Text = "Abhängigkeit"
                $headerName.Location = New-Object System.Drawing.Point(10, 6)
                $headerName.Size = New-Object System.Drawing.Size(250, 18)
                $headerName.ForeColor = [System.Drawing.Color]::White
                $headerName.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
                $headerPanel.Controls.Add($headerName)

                $headerVersion = New-Object System.Windows.Forms.Label
                $headerVersion.Text = "Version"
                $headerVersion.Location = New-Object System.Drawing.Point(270, 6)
                $headerVersion.Size = New-Object System.Drawing.Size(130, 18)
                $headerVersion.ForeColor = [System.Drawing.Color]::White
                $headerVersion.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
                $headerPanel.Controls.Add($headerVersion)

                $headerStatus = New-Object System.Windows.Forms.Label
                $headerStatus.Text = "Status"
                $headerStatus.Location = New-Object System.Drawing.Point(410, 6)
                $headerStatus.Size = New-Object System.Drawing.Size(130, 18)
                $headerStatus.ForeColor = [System.Drawing.Color]::White
                $headerStatus.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
                $headerPanel.Controls.Add($headerStatus)

                $headerAction = New-Object System.Windows.Forms.Label
                $headerAction.Text = "Aktion"
                $headerAction.Location = New-Object System.Drawing.Point(570, 6)
                $headerAction.Size = New-Object System.Drawing.Size(158, 18)
                $headerAction.ForeColor = [System.Drawing.Color]::White
                $headerAction.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
                $headerPanel.Controls.Add($headerAction)

                $script:dependencyTableHost.Controls.Add($headerPanel)

                $rowY = 30
                foreach ($dep in $depResult.Dependencies) {
                    $rowPanel = New-Object System.Windows.Forms.Panel
                    $rowPanel.Location = New-Object System.Drawing.Point(0, $rowY)
                    $rowPanel.Size = New-Object System.Drawing.Size(745, 32)

                    $isError = ($dep.StatusColor -eq "Red")
                    $isWarning = ($dep.StatusColor -eq "Yellow")
                    $isGray = ($dep.Found -and -not $dep.UpdateAvailable)

                    if ($isError) {
                        $rowPanel.BackColor = [System.Drawing.Color]::FromArgb(70, 30, 30)
                    }
                    elseif ($isWarning) {
                        $rowPanel.BackColor = [System.Drawing.Color]::FromArgb(70, 60, 30)
                    }
                    elseif ($isGray) {
                        $rowPanel.BackColor = [System.Drawing.Color]::FromArgb(40, 40, 40)
                    }
                    else {
                        $rowPanel.BackColor = [System.Drawing.Color]::FromArgb(33, 33, 33)
                    }

                    $textColor = if ($isGray) { [System.Drawing.Color]::FromArgb(160, 160, 160) } else { [System.Drawing.Color]::White }

                    $nameLabel = New-Object System.Windows.Forms.Label
                    $nameLabel.Text = $dep.Name
                    $nameLabel.Location = New-Object System.Drawing.Point(10, 8)
                    $nameLabel.Size = New-Object System.Drawing.Size(250, 18)
                    $nameLabel.ForeColor = $textColor
                    $nameLabel.Font = New-Object System.Drawing.Font("Segoe UI", 8.5, [System.Drawing.FontStyle]::Bold)
                    $rowPanel.Controls.Add($nameLabel)

                    $versionText = if ($dep.Version) { "$($dep.Version)" } else { "-" }
                    if ($dep.UpdateAvailable -and $dep.AvailableVersion) {
                        $versionText = "$versionText → $($dep.AvailableVersion)"
                    }

                    $versionLabel = New-Object System.Windows.Forms.Label
                    $versionLabel.Text = $versionText
                    $versionLabel.Location = New-Object System.Drawing.Point(270, 8)
                    $versionLabel.Size = New-Object System.Drawing.Size(130, 18)
                    $versionLabel.ForeColor = $textColor
                    $versionLabel.Font = New-Object System.Drawing.Font("Segoe UI", 8)
                    $rowPanel.Controls.Add($versionLabel)

                    $statusLabelRow = New-Object System.Windows.Forms.Label
                    $statusLabelRow.Text = $dep.Status
                    $statusLabelRow.Location = New-Object System.Drawing.Point(410, 8)
                    $statusLabelRow.Size = New-Object System.Drawing.Size(150, 18)
                    $statusLabelRow.ForeColor = if ($isError) { [System.Drawing.Color]::Tomato } elseif ($isWarning) { [System.Drawing.Color]::Gold } elseif ($dep.UpdateAvailable) { [System.Drawing.Color]::DeepSkyBlue } else { $textColor }
                    $statusLabelRow.Font = New-Object System.Drawing.Font("Segoe UI", 8)
                    $rowPanel.Controls.Add($statusLabelRow)

                    $actionButton = New-Object System.Windows.Forms.Button
                    $actionButton.Location = New-Object System.Drawing.Point(570, 4)
                    $actionButton.Size = New-Object System.Drawing.Size(158, 24)
                    $actionButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
                    $actionButton.FlatAppearance.BorderSize = 0
                    $actionButton.Font = New-Object System.Drawing.Font("Segoe UI", 8.5, [System.Drawing.FontStyle]::Bold)

                    if ($dep.Name -eq "GUI-Update (GitHub)") {
                        $actionButton.Text = "Downgrade"
                        $actionButton.BackColor = [System.Drawing.Color]::FromArgb(124, 77, 255)
                        $actionButton.ForeColor = [System.Drawing.Color]::White
                        $actionButton.Tag = @{ Dependency = $dep; Action = "gui-release-select" }
                    }
                    elseif ($dep.Name -eq "Winget Package Manager" -and $dep.Found -and $dep.WingetId) {
                        # Winget selbst: Versionsauswahl möglich
                        $actionButton.Text = "Downgrade"
                        $actionButton.BackColor = [System.Drawing.Color]::FromArgb(156, 39, 176)
                        $actionButton.ForeColor = [System.Drawing.Color]::White
                        $actionButton.Tag = @{ Dependency = $dep; Action = "winget-version-select" }
                    }
                    elseif ($dep.Name -eq "App Installer (winget)" -and $dep.Found) {
                        # App Installer: Store-Paket, keine Downgrade-Funktion
                        $actionButton.Text = "Vorhanden"
                        $actionButton.BackColor = [System.Drawing.Color]::FromArgb(70, 70, 70)
                        $actionButton.ForeColor = [System.Drawing.Color]::Silver
                        $actionButton.Enabled = $false
                    }
                    elseif ($dep.Name -eq "LibreHardwareMonitor DLL" -and $dep.UpdateAvailable) {
                        $actionButton.Text = "Aktualisieren"
                        $actionButton.BackColor = [System.Drawing.Color]::FromArgb(52, 152, 219)
                        $actionButton.ForeColor = [System.Drawing.Color]::White
                        $actionButton.Tag = @{ Dependency = $dep; Action = "lhm-update" }
                    }
                    elseif ($dep.Name -eq "LibreHardwareMonitor DLL" -and -not $dep.Found) {
                        $actionButton.Text = "Herunterladen"
                        $actionButton.BackColor = [System.Drawing.Color]::FromArgb(46, 204, 113)
                        $actionButton.ForeColor = [System.Drawing.Color]::White
                        $actionButton.Tag = @{ Dependency = $dep; Action = "lhm-update" }
                    }
                    elseif ($dep.Name -eq "LibreHardwareMonitor DLL") {
                        $actionButton.Text = "Vorhanden"
                        $actionButton.BackColor = [System.Drawing.Color]::FromArgb(70, 70, 70)
                        $actionButton.ForeColor = [System.Drawing.Color]::Silver
                        $actionButton.Enabled = $false
                    }
                    elseif (-not $dep.Found -and $dep.WingetId) {
                        $actionButton.Text = "Installieren"
                        $actionButton.BackColor = [System.Drawing.Color]::FromArgb(46, 204, 113)
                        $actionButton.ForeColor = [System.Drawing.Color]::White
                        $actionButton.Tag = @{ Dependency = $dep; Action = "install" }
                    }
                    elseif ($dep.Found -and $dep.UpdateAvailable -and $dep.WingetId) {
                        $actionButton.Text = "Aktualisieren"
                        $actionButton.BackColor = [System.Drawing.Color]::FromArgb(52, 152, 219)
                        $actionButton.ForeColor = [System.Drawing.Color]::White
                        $actionButton.Tag = @{ Dependency = $dep; Action = "upgrade" }
                    }
                    elseif (-not $dep.Found) {
                        $actionButton.Text = "Manuell"
                        $actionButton.BackColor = [System.Drawing.Color]::FromArgb(90, 90, 90)
                        $actionButton.ForeColor = [System.Drawing.Color]::Gainsboro
                        $actionButton.Enabled = $false
                    }
                    else {
                        $actionButton.Text = "Vorhanden"
                        $actionButton.BackColor = [System.Drawing.Color]::FromArgb(70, 70, 70)
                        $actionButton.ForeColor = [System.Drawing.Color]::Silver
                        $actionButton.Enabled = $false
                    }

                    $actionButton.Add_Click({
                        $payload = $this.Tag
                        if (-not $payload) { return }

                        $depToHandle = $payload.Dependency
                        $actionType = $payload.Action
                        $actionLabel = switch ($actionType) {
                            "upgrade" { "Aktualisierung" }
                            "gui-release-select" { "Versionswechsel" }
                            "winget-version-select" { "Versionswechsel" }
                            "lhm-update" { "DLL-Update" }
                            default { "Installation" }
                        }
                        $this.Enabled = $false
                        $this.Text = switch ($actionType) {
                            "upgrade" { "Aktualisiere..." }
                            "gui-release-select" { "Suche Version..." }
                            "winget-version-select" { "Suche Version..." }
                            "lhm-update" { "Lade DLL..." }
                            default { "Installiere..." }
                        }
                        [System.Windows.Forms.Application]::DoEvents()

                        $uiProgressCallback = {
                            param(
                                [int]$Value,
                                [string]$Text,
                                [System.Drawing.Color]$Color = [System.Drawing.Color]::White
                            )

                            if ($progressBar) {
                                $safeValue = [Math]::Max(0, [Math]::Min(100, $Value))
                                $progressBar.Value = $safeValue
                                $progressBar.CustomText = $Text
                                $progressBar.TextColor = $Color
                                [System.Windows.Forms.Application]::DoEvents()
                            }
                        }

                        $uiLogCallback = {
                            param(
                                [string]$Level,
                                [string]$Message
                            )

                            if ($outputBox -and $outputBox.Visible) {
                                $prefix = switch ($Level) {
                                    "success" { "[✓]" }
                                    "error" { "[✗]" }
                                    default { "[→]" }
                                }
                                $outputBox.AppendText("$prefix $Message`r`n")
                            }
                        }

                        & $uiProgressCallback -Value 0 -Text "$actionLabel wird gestartet..."

                        $actionResult = $null
                        try {
                            if ($actionType -eq "gui-release-select") {
                                $actionResult = Invoke-GuiReleaseAction
                            }
                            elseif ($actionType -eq "winget-version-select") {
                                $actionResult = Invoke-WingetVersionAction -WingetId $depToHandle.WingetId -CurrentVersion $depToHandle.Version -ProgressCallback $uiProgressCallback -LogCallback $uiLogCallback
                            }
                            elseif ($actionType -eq "upgrade") {
                                $actionResult = Invoke-DependencyAction -WingetId $depToHandle.WingetId -Action 'upgrade' -ProgressCallback $uiProgressCallback -LogCallback $uiLogCallback
                            }
                            elseif ($actionType -eq "lhm-update") {
                                $lhmLibPath = $depToHandle.LhmLibPath
                                if (-not $lhmLibPath) { $lhmLibPath = Join-Path $PSScriptRoot "Lib" }
                                $lhmTargetVer = if ($depToHandle.LhmTargetVersion) { $depToHandle.LhmTargetVersion } else { "0.9.6" }
                                & $uiProgressCallback -Value 10 -Text "Starte DLL-Update auf v$lhmTargetVer..."
                                $lhmRaw = Update-LibreHardwareMonitorDll -LibPath $lhmLibPath -TargetVersion $lhmTargetVer -ProgressCallback $uiProgressCallback
                                $actionResult = @{
                                    Success      = $lhmRaw.Success
                                    ErrorMessage = $lhmRaw.ErrorMessage
                                    Message      = if ($lhmRaw.Success) { "DLL auf v$($lhmRaw.NewVersion) vorbereitet. Bitte System neu starten." } else { $lhmRaw.ErrorMessage }
                                }
                                if ($lhmRaw.Success) {
                                    [System.Windows.Forms.MessageBox]::Show(
                                        "LibreHardwareMonitorLib.dll v$($lhmRaw.NewVersion) wurde heruntergeladen.`n`nDer Austausch der gesperrten DLL erfolgt automatisch beim nächsten Windows-Start (via RunOnce).`n`nBitte Windows neu starten, um das Update abzuschließen.",
                                        "Neustart erforderlich",
                                        [System.Windows.Forms.MessageBoxButtons]::OK,
                                        [System.Windows.Forms.MessageBoxIcon]::Information
                                    ) | Out-Null
                                }
                            }
                            else {
                                $actionResult = Invoke-DependencyAction -WingetId $depToHandle.WingetId -Action 'install' -ProgressCallback $uiProgressCallback -LogCallback $uiLogCallback
                            }

                            if ($actionResult -and $actionResult.Cancelled) {
                                if ($actionType -eq "gui-release-select") {
                                    $this.Text = "Downgrade"
                                    $this.BackColor = [System.Drawing.Color]::FromArgb(124, 77, 255)
                                }
                                elseif ($actionType -eq "winget-version-select") {
                                    $this.Text = "Version wählen"
                                    $this.BackColor = [System.Drawing.Color]::FromArgb(156, 39, 176)
                                }
                                elseif ($actionType -eq "lhm-update") {
                                    $this.Text = "Aktualisieren"
                                    $this.BackColor = [System.Drawing.Color]::FromArgb(52, 152, 219)
                                }
                                else {
                                    $this.Text = "Erneut versuchen"
                                    $this.BackColor = [System.Drawing.Color]::FromArgb(231, 76, 60)
                                }
                                $this.Enabled = $true
                            }
                            elseif ($actionResult -and $actionResult.Success) {
                                if ($depToHandle.Name -eq "PawnIO Ring-0 Treiber") {
                                    [System.Windows.Forms.MessageBox]::Show("Bitte System neu starten, damit der PawnIO-Treiber geladen wird.", "Neustart erforderlich", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information) | Out-Null
                                }
                                $this.Text = "✓ Erledigt"
                                $this.BackColor = [System.Drawing.Color]::FromArgb(39, 174, 96)
                            }
                            else {
                                if ($actionResult -and $actionResult.ErrorMessage) {
                                    [System.Windows.Forms.MessageBox]::Show("Vorgang fehlgeschlagen: $($actionResult.ErrorMessage)", "Aktion fehlgeschlagen", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
                                }
                                elseif ($actionResult -and $actionResult.Message) {
                                    [System.Windows.Forms.MessageBox]::Show("Vorgang fehlgeschlagen: $($actionResult.Message)", "Aktion fehlgeschlagen", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
                                }
                                else {
                                    [System.Windows.Forms.MessageBox]::Show("Vorgang fehlgeschlagen (Exit Code: $($actionResult.ExitCode))", "Aktion fehlgeschlagen", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
                                }
                                if ($actionType -eq "gui-release-select") {
                                    $this.Text = "Downgrade"
                                    $this.BackColor = [System.Drawing.Color]::FromArgb(124, 77, 255)
                                }
                                elseif ($actionType -eq "winget-version-select") {
                                    $this.Text = "Version wählen"
                                    $this.BackColor = [System.Drawing.Color]::FromArgb(156, 39, 176)
                                }
                                elseif ($actionType -eq "lhm-update") {
                                    $this.Text = "Erneut versuchen"
                                    $this.BackColor = [System.Drawing.Color]::FromArgb(231, 76, 60)
                                }
                                else {
                                    $this.Text = "Erneut versuchen"
                                    $this.BackColor = [System.Drawing.Color]::FromArgb(231, 76, 60)
                                }
                                $this.Enabled = $true
                            }
                        }
                        catch {
                            & $uiProgressCallback -Value 100 -Text "$actionLabel fehlgeschlagen" -Color ([System.Drawing.Color]::Red)
                            [System.Windows.Forms.MessageBox]::Show("Fehler: $($_.Exception.Message)", "Aktion fehlgeschlagen", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
                            if ($actionType -eq "gui-release-select") {
                                $this.Text = "Downgrade"
                                $this.BackColor = [System.Drawing.Color]::FromArgb(124, 77, 255)
                            }
                            elseif ($actionType -eq "winget-version-select") {
                                $this.Text = "Version wählen"
                                $this.BackColor = [System.Drawing.Color]::FromArgb(156, 39, 176)
                            }
                            elseif ($actionType -eq "lhm-update") {
                                $this.Text = "Erneut versuchen"
                                $this.BackColor = [System.Drawing.Color]::FromArgb(231, 76, 60)
                            }
                            else {
                                $this.Text = "Erneut versuchen"
                                $this.BackColor = [System.Drawing.Color]::FromArgb(231, 76, 60)
                            }
                            $this.Enabled = $true
                        }

                        if ($actionResult -and $actionResult.Success) {
                            $resetActionProgressTimer = New-Object System.Windows.Forms.Timer
                            $resetActionProgressTimer.Interval = 2200
                            $resetActionProgressTimer.Add_Tick({
                                if ($progressBar) {
                                    $progressBar.Value = 0
                                    $progressBar.CustomText = "Bereit"
                                    $progressBar.TextColor = [System.Drawing.Color]::White
                                }
                                $this.Stop()
                                $this.Dispose()
                            })
                            $resetActionProgressTimer.Start()
                        }
                    })

                    $rowPanel.Controls.Add($actionButton)
                    $script:dependencyTableHost.Controls.Add($rowPanel)
                    $rowY += 34
                }
            }
        
        # Hardware-Monitor Neustart (optional)
        & $updateDependencyProgress -Value 90 -Text "Aktualisiere Hardware-Monitor..."
        
        try {
            Clear-HardwareMonitoring
            Start-Sleep -Milliseconds 500
            Initialize-LibreHardwareMonitor
            Initialize-LiveMonitoring -cpuLabel $cpuLabel -gpuLabel $gpuLabel -ramLabel $ramLabel -cpuProgress $cpuProgressBar -gpuProgress $gpuProgressBar -ramProgress $ramProgressBar
            Start-HardwareMonitoring
        }
        catch {
            # Hardware-Monitor-Neustart optional - Fehler tolerieren
            Write-Verbose "Hardware-Monitor konnte nicht neu gestartet werden: $($_.Exception.Message)"
        }

        & $updateDependencyProgress -Value 100 -Text "Abhängigkeitsprüfung abgeschlossen" -Color ([System.Drawing.Color]::LimeGreen)
        & $scheduleDependencyProgressReset -DelayMs 2500
    }
    catch {
        & $updateDependencyProgress -Value 100 -Text "Fehler bei Abhängigkeitsprüfung" -Color ([System.Drawing.Color]::Red)
        & $scheduleDependencyProgressReset -DelayMs 2500
        [System.Windows.Forms.MessageBox]::Show("Fehler bei Abhängigkeitsprüfung: $($_.Exception.Message)", "Abhängigkeitsprüfung fehlgeschlagen", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
    }
})
$troubleshootHorizontalPanel.Content.Controls.Add($btnCheckDependenciesH)

$mainContentPanel.Controls.Add($troubleshootHorizontalPanel.Container)

#------------------------------------------------------------------------------------------------------------

# Separator zwischen Bereinigung und Tool-Downloads
$script:cleanupDownloadsSeparator = New-Object System.Windows.Forms.Label
$script:cleanupDownloadsSeparator.Location = New-Object System.Drawing.Point(5, 150)
$script:cleanupDownloadsSeparator.Size = New-Object System.Drawing.Size(215, 2)
$script:cleanupDownloadsSeparator.BackColor = [System.Drawing.Color]::FromArgb(120, 120, 120)
$script:cleanupDownloadsSeparator.BorderStyle = [System.Windows.Forms.BorderStyle]::None
$mainButtonPanel.Controls.Add($script:cleanupDownloadsSeparator)

# Erstelle Collapsible Panel für Tool-Downloads (YPosition angepasst für Separator mit 5px Abstand)
$downloadsPanel = New-CollapsiblePanel -Title "Tool-Downloads" -YPosition 157 -Tag "downloadsPanel" -ParentPanel $mainButtonPanel -IconCode 0xE896 -OnExpand {
    # Alle mainContentPanel-Panels ausblenden
    if ($global:tblSystem) { $global:tblSystem.Visible = $false }
    if ($tblDisk) { $tblDisk.Visible = $false }
    if ($tblNetwork) { $tblNetwork.Visible = $false }
    if ($tblCleanup) { $tblCleanup.Visible = $false }
    if ($global:tblDependencies) { $global:tblDependencies.Visible = $false }
    if ($global:tblSmartRepair) { $global:tblSmartRepair.Visible = $false }
    
    # Horizontale Container ausblenden
    if ($infoHorizontalPanel -and $infoHorizontalPanel.Container) {
        $infoHorizontalPanel.Container.Visible = $false
    }
    if ($troubleshootHorizontalPanel -and $troubleshootHorizontalPanel.Container) {
        $troubleshootHorizontalPanel.Container.Visible = $false
    }
    
    # Alle View-Panels ausblenden beim Öffnen des Dropdown-Menüs
    if ($outputViewPanel) { $outputViewPanel.Visible = $false }
    if ($statusViewPanel) { $statusViewPanel.Visible = $false }
    if ($hardwareViewPanel) { $hardwareViewPanel.Visible = $false }
    if ($toolInfoViewPanel) { $toolInfoViewPanel.Visible = $false }
    if ($downloadsViewPanel) { $downloadsViewPanel.Visible = $false }
    
    # Suchfeld im mainContentPanel einblenden
    if ($searchPanel) { $searchPanel.Visible = $true }

    # Abhängigkeits-Tabelle ausblenden
    if ($script:dependencyTableHost) { $script:dependencyTableHost.Visible = $false }

    # Standard-Output wieder einblenden
    if ($outputBox) { $outputBox.Visible = $true }
    
    # Stelle sicher, dass OutputView sichtbar ist (Downloads-View bleibt versteckt bis Kategorie gewählt)
    if ($outputViewPanel) { $outputViewPanel.Visible = $true }
    
    # Aktualisiere Kategorie-Zähler beim Öffnen
    Update-CategoryCounts -SearchQuery ""
    
    # OutputBox leeren und Info anzeigen
    $outputBox.Clear()
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'BannerFrame'
    $outputBox.AppendText("`t╔═══════════════════════════════════════════════════════════════╗`r`n")
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'BannerTitle'
    $outputBox.AppendText("`t║                    TOOL-DOWNLOADS                             ║`r`n")
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'BannerFrame'
    $outputBox.AppendText("`t╚═══════════════════════════════════════════════════════════════╝`r`n`r`n")
    
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Heading'
    $outputBox.AppendText("Verfügbare Tool-Kategorien (29 Tools):`r`n`r`n")
    
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Accent'
    Add-OutputIcon -OutputBox $outputBox -IconCode 0xE90F
    $outputBox.AppendText(" SYSTEM-TOOLS (8 Tools):`r`n")
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Info'
    $outputBox.AppendText("  • 7-Zip, CCleaner, CPU-Z, GPU-Z, OCCT`r`n")
    $outputBox.AppendText("  • Intel Driver Assistant, LibreHardwareMonitor, UniGetUI`r`n`r`n")
    
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Accent'
    Add-OutputIcon -OutputBox $outputBox -IconCode 0xE8A5
    $outputBox.AppendText(" ANWENDUNGEN (6 Tools):`r`n")
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Info'
    $outputBox.AppendText("  • Browser: Brave, Firefox, Chrome`r`n")
    $outputBox.AppendText("  • Kommunikation: Discord`r`n")
    $outputBox.AppendText("  • Office: LibreOffice, Apache OpenOffice`r`n`r`n")
    
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Accent'
    Add-OutputIcon -OutputBox $outputBox -IconCode 0xE8D6
    $outputBox.AppendText(" AUDIO / TV (9 Tools):`r`n")
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Info'
    $outputBox.AppendText("  • Media: VLC, Spotify, OBS Studio, Sky Go`r`n")
    $outputBox.AppendText("  • Audio: Audacity, EarTrumpet, SteelSeries GG`r`n")
    $outputBox.AppendText("  • Mixer: MIXLINE, Voicemeeter Potato`r`n`r`n")
    
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Accent'
    Add-OutputIcon -OutputBox $outputBox -IconCode 0xE943
    $outputBox.AppendText(" CODING / IT (6 Tools):`r`n")
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Info'
    $outputBox.AppendText("  • Editoren: VS Code, Notepad++`r`n")
    $outputBox.AppendText("  • Terminal: PowerShell`r`n")
    $outputBox.AppendText("  • Netzwerk: PuTTY, WinSCP, WireGuard`r`n`r`n")
    
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Success'
    Add-OutputIcon -OutputBox $outputBox -IconCode 0xE73E
    $outputBox.AppendText(" Winget-Integration: Automatische Installations-Status-Erkennung`r`n")
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Success'
    Add-OutputIcon -OutputBox $outputBox -IconCode 0xE73E
    $outputBox.AppendText(" Ein-Klick-Installation: Direkte Installation über Winget`r`n`r`n")
    
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Muted'
    Add-OutputIcon -OutputBox $outputBox -IconCode 0xE946
    $outputBox.AppendText(" Tipp: Wählen Sie eine Kategorie oder nutzen Sie die Suchfunktion oben.`r`n")
    
    # Hinweis: View-Panel wird durch Sub-Button-Klick angezeigt
    
    # Setze alle Header-Button-Farben zurück auf inaktiv
    $btnOutput.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
    
    # Setze den Tool-Downloads-Header auf aktiv
    $downloadsPanel.Header.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
    
    # Setze Info-Panel-Header zurück
    $infoHorizontalPanel.Header.BackColor = [System.Drawing.Color]::FromArgb(37, 37, 38)
    
    # Setze alle Info-Buttons zurück
    $btnStatusInfoH.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
    $btnHardwareInfoH.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
    $btnToolInfoH.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
}
$mainButtonPanel.Controls.Add($downloadsPanel.Container)

# Setze die Content-Panel-Höhe für 5 Kategorie-Buttons
$downloadsPanel.Content.Height = 175  # 5 Buttons × 35px = 175px

# Hilfsfunktion: Setzt alle Download-Kategorie-Button-Farben zurück und hebt den aktiven hervor
function Reset-DownloadCategoryButtons {
    param(
        [string]$ActiveCategory  # "all", "system", "applications", "audiotv", "coding"
    )
    
    # Alle auf inaktiv setzen
    $btnAllTools.BackColor = [System.Drawing.Color]::FromArgb(37, 37, 38)
    $btnSystemTools.BackColor = [System.Drawing.Color]::FromArgb(37, 37, 38)
    $btnApplications.BackColor = [System.Drawing.Color]::FromArgb(37, 37, 38)
    $btnAudioTV.BackColor = [System.Drawing.Color]::FromArgb(37, 37, 38)
    $btnCodingTools.BackColor = [System.Drawing.Color]::FromArgb(37, 37, 38)
    
    # Aktiven Button hervorheben
    switch ($ActiveCategory) {
        "all"          { $btnAllTools.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43) }
        "system"       { $btnSystemTools.BackColor = [System.Drawing.Color]::FromArgb(55, 55, 55) }
        "applications" { $btnApplications.BackColor = [System.Drawing.Color]::FromArgb(55, 55, 55) }
        "audiotv"      { $btnAudioTV.BackColor = [System.Drawing.Color]::FromArgb(55, 55, 55) }
        "coding"       { $btnCodingTools.BackColor = [System.Drawing.Color]::FromArgb(55, 55, 55) }
    }
}

# Erstelle die Kategorie-Buttons als Submenu
$btnAllTools = New-Object System.Windows.Forms.Button
$btnAllTools.Text = "Alle Tools"
$btnAllTools.Size = New-Object System.Drawing.Size(210, 35)
$btnAllTools.Location = New-Object System.Drawing.Point(0, 0)
$btnAllTools.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnAllTools.FlatAppearance.BorderSize = 0
$btnAllTools.FlatAppearance.MouseOverBackColor = [System.Drawing.Color]::FromArgb(55, 55, 55)
$btnAllTools.BackColor = [System.Drawing.Color]::FromArgb(37, 37, 38)  # Inaktiv beim Start
$btnAllTools.ForeColor = [System.Drawing.Color]::White
$btnAllTools.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
Add-ButtonIcon -Button $btnAllTools -IconCode 0xE71D -IconSize 12 -LeftMargin 10

# Zähler-Label für Alle Tools
$lblAllToolsCount = New-Object System.Windows.Forms.Label
$lblAllToolsCount.Size = New-Object System.Drawing.Size(30, 20)
$lblAllToolsCount.Location = New-Object System.Drawing.Point(175, 8)
$lblAllToolsCount.TextAlign = [System.Drawing.ContentAlignment]::MiddleRight
$lblAllToolsCount.ForeColor = [System.Drawing.Color]::LightGray
$lblAllToolsCount.BackColor = [System.Drawing.Color]::Transparent
$lblAllToolsCount.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$lblAllToolsCount.Text = ""
$btnAllTools.Controls.Add($lblAllToolsCount)
$btnAllTools.Add_Click({
    # Horizontale Container ausblenden
    if ($infoHorizontalPanel -and $infoHorizontalPanel.Container) {
        $infoHorizontalPanel.Container.Visible = $false
    }
    if ($troubleshootHorizontalPanel -and $troubleshootHorizontalPanel.Container) {
        $troubleshootHorizontalPanel.Container.Visible = $false
    }
    
    # Suchfeld einblenden
    if ($searchPanel) { $searchPanel.Visible = $true }
    
    # mainContentPanel-Panels ausblenden
    if ($global:tblSystem) { $global:tblSystem.Visible = $false }
    if ($tblDisk) { $tblDisk.Visible = $false }
    if ($tblNetwork) { $tblNetwork.Visible = $false }
    if ($tblCleanup) { $tblCleanup.Visible = $false }
    if ($global:tblDependencies) { $global:tblDependencies.Visible = $false }
    if ($global:tblSmartRepair) { $global:tblSmartRepair.Visible = $false }
    
    # Downloads-View anzeigen (OutputBox wird nicht verwendet, da Tool-Kacheln direkt angezeigt werden)
    Switch-OutputView -viewName "downloadsView"
    
    # Aktuelle Kategorie speichern
    $script:currentDownloadCategory = "all"
    
    # Buttons hervorheben/zurücksetzen
    Reset-DownloadCategoryButtons -ActiveCategory "all"
    
    # Tools mit Installationsüberprüfung anzeigen und Progressbar aktualisieren
    $null = Update-ToolsDisplay -WrapPanel $toolWrapPanel -Category "all" -MainProgressBar $progressBar -SearchQuery $searchTextBox.Text -TileSize $script:currentTileSize -ShowOnlyUpdates $script:showOnlyUpdates
})
$downloadsPanel.Content.Controls.Add($btnAllTools)

$btnSystemTools = New-Object System.Windows.Forms.Button
$btnSystemTools.Text = "System-Tools"
$btnSystemTools.Size = New-Object System.Drawing.Size(210, 35)
$btnSystemTools.Location = New-Object System.Drawing.Point(0, 35)
$btnSystemTools.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnSystemTools.FlatAppearance.BorderSize = 0
$btnSystemTools.FlatAppearance.MouseOverBackColor = [System.Drawing.Color]::FromArgb(55, 55, 55)
$btnSystemTools.BackColor = [System.Drawing.Color]::FromArgb(37, 37, 38)
$btnSystemTools.ForeColor = [System.Drawing.Color]::White
$btnSystemTools.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
Add-ButtonIcon -Button $btnSystemTools -IconCode 0xE90F -IconSize 12 -LeftMargin 10

# Zähler-Label für System-Tools
$lblSystemToolsCount = New-Object System.Windows.Forms.Label
$lblSystemToolsCount.Size = New-Object System.Drawing.Size(30, 20)
$lblSystemToolsCount.Location = New-Object System.Drawing.Point(175, 8)
$lblSystemToolsCount.TextAlign = [System.Drawing.ContentAlignment]::MiddleRight
$lblSystemToolsCount.ForeColor = [System.Drawing.Color]::LightGray
$lblSystemToolsCount.BackColor = [System.Drawing.Color]::Transparent
$lblSystemToolsCount.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$lblSystemToolsCount.Text = ""
$btnSystemTools.Controls.Add($lblSystemToolsCount)
$btnSystemTools.Add_Click({
    # Horizontale Container ausblenden
    if ($infoHorizontalPanel -and $infoHorizontalPanel.Container) {
        $infoHorizontalPanel.Container.Visible = $false
    }
    if ($troubleshootHorizontalPanel -and $troubleshootHorizontalPanel.Container) {
        $troubleshootHorizontalPanel.Container.Visible = $false
    }
    
    # Suchfeld einblenden
    if ($searchPanel) { $searchPanel.Visible = $true }
    
    # mainContentPanel-Panels ausblenden
    if ($global:tblSystem) { $global:tblSystem.Visible = $false }
    if ($tblDisk) { $tblDisk.Visible = $false }
    if ($tblNetwork) { $tblNetwork.Visible = $false }
    if ($tblCleanup) { $tblCleanup.Visible = $false }
    if ($global:tblDependencies) { $global:tblDependencies.Visible = $false }
    if ($global:tblSmartRepair) { $global:tblSmartRepair.Visible = $false }
    
    # Downloads-View anzeigen (OutputBox wird nicht verwendet, da Tool-Kacheln direkt angezeigt werden)
    Switch-OutputView -viewName "downloadsView"
    
    # Aktuelle Kategorie speichern
    $script:currentDownloadCategory = "system"
    
    # Buttons hervorheben/zurücksetzen
    Reset-DownloadCategoryButtons -ActiveCategory "system"
    
    # Tools mit Installationsüberprüfung anzeigen und Progressbar aktualisieren
    $null = Update-ToolsDisplay -WrapPanel $toolWrapPanel -Category "system" -MainProgressBar $progressBar -SearchQuery $searchTextBox.Text -TileSize $script:currentTileSize -ShowOnlyUpdates $script:showOnlyUpdates
})
$downloadsPanel.Content.Controls.Add($btnSystemTools)

$btnApplications = New-Object System.Windows.Forms.Button
$btnApplications.Text = "Anwendungen"
$btnApplications.Size = New-Object System.Drawing.Size(210, 35)
$btnApplications.Location = New-Object System.Drawing.Point(0, 70)
$btnApplications.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnApplications.FlatAppearance.BorderSize = 0
$btnApplications.FlatAppearance.MouseOverBackColor = [System.Drawing.Color]::FromArgb(55, 55, 55)
$btnApplications.BackColor = [System.Drawing.Color]::FromArgb(37, 37, 38)
$btnApplications.ForeColor = [System.Drawing.Color]::White
$btnApplications.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
Add-ButtonIcon -Button $btnApplications -IconCode 0xE8A5 -IconSize 12 -LeftMargin 10

# Zähler-Label für Anwendungen
$lblApplicationsCount = New-Object System.Windows.Forms.Label
$lblApplicationsCount.Size = New-Object System.Drawing.Size(30, 20)
$lblApplicationsCount.Location = New-Object System.Drawing.Point(175, 8)
$lblApplicationsCount.TextAlign = [System.Drawing.ContentAlignment]::MiddleRight
$lblApplicationsCount.ForeColor = [System.Drawing.Color]::LightGray
$lblApplicationsCount.BackColor = [System.Drawing.Color]::Transparent
$lblApplicationsCount.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$lblApplicationsCount.Text = ""
$btnApplications.Controls.Add($lblApplicationsCount)
$btnApplications.Add_Click({
    # Horizontale Container ausblenden
    if ($infoHorizontalPanel -and $infoHorizontalPanel.Container) {
        $infoHorizontalPanel.Container.Visible = $false
    }
    if ($troubleshootHorizontalPanel -and $troubleshootHorizontalPanel.Container) {
        $troubleshootHorizontalPanel.Container.Visible = $false
    }
    
    # Suchfeld einblenden
    if ($searchPanel) { $searchPanel.Visible = $true }
    
    # mainContentPanel-Panels ausblenden
    if ($global:tblSystem) { $global:tblSystem.Visible = $false }
    if ($tblDisk) { $tblDisk.Visible = $false }
    if ($tblNetwork) { $tblNetwork.Visible = $false }
    if ($tblCleanup) { $tblCleanup.Visible = $false }
    if ($global:tblDependencies) { $global:tblDependencies.Visible = $false }
    if ($global:tblSmartRepair) { $global:tblSmartRepair.Visible = $false }
    
    # Downloads-View anzeigen (OutputBox wird nicht verwendet, da Tool-Kacheln direkt angezeigt werden)
    Switch-OutputView -viewName "downloadsView"
    
    # Aktuelle Kategorie speichern
    $script:currentDownloadCategory = "applications"
    
    # Buttons hervorheben/zurücksetzen
    Reset-DownloadCategoryButtons -ActiveCategory "applications"
    
    # Tools mit Installationsüberprüfung anzeigen und Progressbar aktualisieren
    $null = Update-ToolsDisplay -WrapPanel $toolWrapPanel -Category "applications" -MainProgressBar $progressBar -SearchQuery $searchTextBox.Text -TileSize $script:currentTileSize -ShowOnlyUpdates $script:showOnlyUpdates
})
$downloadsPanel.Content.Controls.Add($btnApplications)

$btnAudioTV = New-Object System.Windows.Forms.Button
$btnAudioTV.Text = "Audio / TV"
$btnAudioTV.Size = New-Object System.Drawing.Size(210, 35)
$btnAudioTV.Location = New-Object System.Drawing.Point(0, 105)
$btnAudioTV.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnAudioTV.FlatAppearance.BorderSize = 0
$btnAudioTV.FlatAppearance.MouseOverBackColor = [System.Drawing.Color]::FromArgb(55, 55, 55)
$btnAudioTV.BackColor = [System.Drawing.Color]::FromArgb(37, 37, 38)
$btnAudioTV.ForeColor = [System.Drawing.Color]::White
$btnAudioTV.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
Add-ButtonIcon -Button $btnAudioTV -IconCode 0xE8D6 -IconSize 12 -LeftMargin 10

# Zähler-Label für Audio / TV
$lblAudioTVCount = New-Object System.Windows.Forms.Label
$lblAudioTVCount.Size = New-Object System.Drawing.Size(30, 20)
$lblAudioTVCount.Location = New-Object System.Drawing.Point(175, 8)
$lblAudioTVCount.TextAlign = [System.Drawing.ContentAlignment]::MiddleRight
$lblAudioTVCount.ForeColor = [System.Drawing.Color]::LightGray
$lblAudioTVCount.BackColor = [System.Drawing.Color]::Transparent
$lblAudioTVCount.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$lblAudioTVCount.Text = ""
$btnAudioTV.Controls.Add($lblAudioTVCount)
$btnAudioTV.Add_Click({
    # Horizontale Container ausblenden
    if ($infoHorizontalPanel -and $infoHorizontalPanel.Container) {
        $infoHorizontalPanel.Container.Visible = $false
    }
    if ($troubleshootHorizontalPanel -and $troubleshootHorizontalPanel.Container) {
        $troubleshootHorizontalPanel.Container.Visible = $false
    }
    
    # Suchfeld einblenden
    if ($searchPanel) { $searchPanel.Visible = $true }
    
    # mainContentPanel-Panels ausblenden
    if ($global:tblSystem) { $global:tblSystem.Visible = $false }
    if ($tblDisk) { $tblDisk.Visible = $false }
    if ($tblNetwork) { $tblNetwork.Visible = $false }
    if ($tblCleanup) { $tblCleanup.Visible = $false }
    if ($global:tblDependencies) { $global:tblDependencies.Visible = $false }
    if ($global:tblSmartRepair) { $global:tblSmartRepair.Visible = $false }
    
    # Downloads-View anzeigen (OutputBox wird nicht verwendet, da Tool-Kacheln direkt angezeigt werden)
    Switch-OutputView -viewName "downloadsView"
    
    # Aktuelle Kategorie speichern
    $script:currentDownloadCategory = "audiotv"
    
    # Buttons hervorheben/zurücksetzen
    Reset-DownloadCategoryButtons -ActiveCategory "audiotv"
    
    # Tools mit Installationsüberprüfung anzeigen und Progressbar aktualisieren
    $null = Update-ToolsDisplay -WrapPanel $toolWrapPanel -Category "audiotv" -MainProgressBar $progressBar -SearchQuery $searchTextBox.Text -TileSize $script:currentTileSize -ShowOnlyUpdates $script:showOnlyUpdates
})
$downloadsPanel.Content.Controls.Add($btnAudioTV)

$btnCodingTools = New-Object System.Windows.Forms.Button
$btnCodingTools.Text = "Coding / IT"
$btnCodingTools.Size = New-Object System.Drawing.Size(210, 35)
$btnCodingTools.Location = New-Object System.Drawing.Point(0, 140)
$btnCodingTools.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnCodingTools.FlatAppearance.BorderSize = 0
$btnCodingTools.FlatAppearance.MouseOverBackColor = [System.Drawing.Color]::FromArgb(55, 55, 55)
$btnCodingTools.BackColor = [System.Drawing.Color]::FromArgb(37, 37, 38)
$btnCodingTools.ForeColor = [System.Drawing.Color]::White
$btnCodingTools.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
Add-ButtonIcon -Button $btnCodingTools -IconCode 0xE943 -IconSize 12 -LeftMargin 10

# Zähler-Label für Coding / IT
$lblCodingToolsCount = New-Object System.Windows.Forms.Label
$lblCodingToolsCount.Size = New-Object System.Drawing.Size(30, 20)
$lblCodingToolsCount.Location = New-Object System.Drawing.Point(175, 8)
$lblCodingToolsCount.TextAlign = [System.Drawing.ContentAlignment]::MiddleRight
$lblCodingToolsCount.ForeColor = [System.Drawing.Color]::LightGray
$lblCodingToolsCount.BackColor = [System.Drawing.Color]::Transparent
$lblCodingToolsCount.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$lblCodingToolsCount.Text = ""
$btnCodingTools.Controls.Add($lblCodingToolsCount)
$btnCodingTools.Add_Click({
    # Horizontale Container ausblenden
    if ($infoHorizontalPanel -and $infoHorizontalPanel.Container) {
        $infoHorizontalPanel.Container.Visible = $false
    }
    if ($troubleshootHorizontalPanel -and $troubleshootHorizontalPanel.Container) {
        $troubleshootHorizontalPanel.Container.Visible = $false
    }
    
    # Suchfeld einblenden
    if ($searchPanel) { $searchPanel.Visible = $true }
    
    # mainContentPanel-Panels ausblenden
    if ($global:tblSystem) { $global:tblSystem.Visible = $false }
    if ($tblDisk) { $tblDisk.Visible = $false }
    if ($tblNetwork) { $tblNetwork.Visible = $false }
    if ($tblCleanup) { $tblCleanup.Visible = $false }
    if ($global:tblDependencies) { $global:tblDependencies.Visible = $false }
    if ($global:tblSmartRepair) { $global:tblSmartRepair.Visible = $false }
    
    # Downloads-View anzeigen (OutputBox wird nicht verwendet, da Tool-Kacheln direkt angezeigt werden)
    Switch-OutputView -viewName "downloadsView"
    
    # Aktuelle Kategorie speichern
    $script:currentDownloadCategory = "coding"
    
    # Buttons hervorheben/zurücksetzen
    Reset-DownloadCategoryButtons -ActiveCategory "coding"
    
    # Tools mit Installationsüberprüfung anzeigen und Progressbar aktualisieren
    $null = Update-ToolsDisplay -WrapPanel $toolWrapPanel -Category "coding" -MainProgressBar $progressBar -SearchQuery $searchTextBox.Text -TileSize $script:currentTileSize -ShowOnlyUpdates $script:showOnlyUpdates
})
$downloadsPanel.Content.Controls.Add($btnCodingTools)

# Referenz für Event-Handler erstellen
$btnToolDownloads = $downloadsPanel.Header

# Erstelle Collapsible Panel für Problembehandlung
$troubleshootPanel = New-CollapsiblePanel -Title "Problembehandlung" -YPosition 170 -Tag "troubleshootPanel" -ParentPanel $mainButtonPanel -IconCode 0xE946 -OnExpand {
    # Alle View-Panels ausblenden beim Öffnen
    if ($outputViewPanel) { $outputViewPanel.Visible = $false }
    if ($statusViewPanel) { $statusViewPanel.Visible = $false }
    if ($hardwareViewPanel) { $hardwareViewPanel.Visible = $false }
    if ($toolInfoViewPanel) { $toolInfoViewPanel.Visible = $false }
    
    # Setze alle anderen Buttons auf inaktiv
    if ($systemPanel) { $systemPanel.Header.BackColor = [System.Drawing.Color]::FromArgb(37, 37, 38) }
    if ($diskPanel) { $diskPanel.Header.BackColor = [System.Drawing.Color]::FromArgb(37, 37, 38) }
    if ($networkPanel) { $networkPanel.Header.BackColor = [System.Drawing.Color]::FromArgb(37, 37, 38) }
    if ($cleanupPanel) { $cleanupPanel.Header.BackColor = [System.Drawing.Color]::FromArgb(37, 37, 38) }
    if ($infoHorizontalPanel) { $infoHorizontalPanel.Header.BackColor = [System.Drawing.Color]::FromArgb(37, 37, 38) }
    $btnToolDownloads.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
    if ($restartPanel) { $restartPanel.Header.BackColor = [System.Drawing.Color]::FromArgb(37, 37, 38) }
}


# Initialisiere Panel-Positionen nach der Erstellung aller Panels
Update-PanelPositions -ParentPanel $mainButtonPanel

#------------------------------------------------------------------------------------------------------------
# NEUSTART-PANEL (SEPARATES PANEL UNTERHALB MAIN-NAVIGATION)
#------------------------------------------------------------------------------------------------------------

# Erstelle Collapsible Panel für Neustart im separaten restartButtonPanel (öffnet nach oben)
$restartPanel = New-CollapsiblePanel -Title "Neustart" -YPosition 125 -Tag "restartPanel" -ParentPanel $restartButtonPanel -IconCode 0xE7E8 -OpenUpward -OnExpand {
    # Alle View-Panels ausblenden beim Öffnen des Dropdown-Menüs
    if ($outputViewPanel) { $outputViewPanel.Visible = $false }
    if ($statusViewPanel) { $statusViewPanel.Visible = $false }
    if ($hardwareViewPanel) { $hardwareViewPanel.Visible = $false }
    if ($toolInfoViewPanel) { $toolInfoViewPanel.Visible = $false }
    
    # Suchfeld ausblenden (nur für Downloads)
    if ($searchPanel) { $searchPanel.Visible = $false }
    
    # OutputBox leeren und Info anzeigen
    $outputBox.Clear()
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'BannerFrame'
    $outputBox.AppendText("`t╔═══════════════════════════════════════════════════════════════╗`r`n")
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'BannerTitle'
    $outputBox.AppendText("`t║                 NEUSTART-OPTIONEN                             ║`r`n")
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'BannerFrame'
    $outputBox.AppendText("`t╚═══════════════════════════════════════════════════════════════╝`r`n`r`n")
    
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Heading'
    $outputBox.AppendText("Verfügbare Optionen:`r`n`r`n")
    
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Accent'
    Add-OutputIcon -OutputBox $outputBox -IconCode 0xE72C
    $outputBox.AppendText(" GUI NEULADEN:`r`n")
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Info'
    $outputBox.AppendText("  Lädt die Benutzeroberfläche neu ohne System-Neustart`r`n")
    $outputBox.AppendText("  • Aktuelle Vorgänge werden abgebrochen`r`n")
    $outputBox.AppendText("  • Einstellungen bleiben erhalten`r`n`r`n")
    
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Accent'
    Add-OutputIcon -OutputBox $outputBox -IconCode 0xE7E8
    $outputBox.AppendText(" SYSTEM NEUSTARTEN:`r`n")
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Warning'
    $outputBox.AppendText("  Startet das gesamte System neu`r`n")
    $outputBox.AppendText("  • Alle Programme werden geschlossen`r`n")
    $outputBox.AppendText("  • 30 Sekunden Countdown mit Abbruch-Option`r`n`r`n")
    
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Accent'
    Add-OutputIcon -OutputBox $outputBox -IconCode 0xE83D
    $outputBox.AppendText(" ABGESICHERTER MODUS:`r`n")
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Warning'
    $outputBox.AppendText("  Startet Windows im abgesicherten Modus`r`n")
    $outputBox.AppendText("  • Erweiterte Startoptionen werden geöffnet`r`n")
    $outputBox.AppendText("  • Wählen Sie dann 'Abgesicherter Modus'`r`n`r`n")
    
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Muted'
    Add-OutputIcon -OutputBox $outputBox -IconCode 0xE946
    $outputBox.AppendText(" Tipp: Wählen Sie eine Option im Menü links.`r`n")
    
    # Stelle sicher, dass OutputView angezeigt wird
    Switch-OutputView -viewName "outputView"
    
    $script:currentMainView = "restartView"
    
    # Header-Buttons visuell aktualisieren
    if ($systemPanel) { $systemPanel.Header.BackColor = [System.Drawing.Color]::FromArgb(37, 37, 38) }
    if ($diskPanel) { $diskPanel.Header.BackColor = [System.Drawing.Color]::FromArgb(37, 37, 38) }
    if ($networkPanel) { $networkPanel.Header.BackColor = [System.Drawing.Color]::FromArgb(37, 37, 38) }
    if ($cleanupPanel) { $cleanupPanel.Header.BackColor = [System.Drawing.Color]::FromArgb(37, 37, 38) }
    if ($infoHorizontalPanel) { $infoHorizontalPanel.Header.BackColor = [System.Drawing.Color]::FromArgb(37, 37, 38) }
    if ($downloadsPanel) { $downloadsPanel.Header.BackColor = [System.Drawing.Color]::FromArgb(37, 37, 38) }
    if ($troubleshootPanel) { $troubleshootPanel.Header.BackColor = [System.Drawing.Color]::FromArgb(37, 37, 38) }
    $restartPanel.Header.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
}

# Erstelle die Neustart-Buttons als Submenu
$btnGUIReload = New-Object System.Windows.Forms.Button
$btnGUIReload.Text = "GUI neuladen"
$btnGUIReload.Size = New-Object System.Drawing.Size(210, 35)
$btnGUIReload.Location = New-Object System.Drawing.Point(0, 0)
$btnGUIReload.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnGUIReload.FlatAppearance.BorderSize = 0
$btnGUIReload.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
$btnGUIReload.FlatAppearance.MouseOverBackColor = [System.Drawing.Color]::FromArgb(55, 55, 55)
$btnGUIReload.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
$btnGUIReload.ForeColor = [System.Drawing.Color]::White
$btnGUIReload.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$btnGUIReload.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
Add-ButtonIcon -Button $btnGUIReload -IconCode 0xE72C -IconSize 12 -LeftMargin 10
$btnGUIReload.Add_Click({
    $confirmReload = [System.Windows.Forms.MessageBox]::Show(
        "Die GUI wird neugeladen.`n`nAlle aktuellen Vorgänge werden abgebrochen.`n`nMöchten Sie fortfahren?",
        "GUI neuladen",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Question
    )

    if ($confirmReload -eq [System.Windows.Forms.DialogResult]::Yes) {
        Update-LogFile -Message "GUI-Reload wurde vom Benutzer initiiert"
        Reload-GUI -Form $mainform
    }
})
$restartPanel.Content.Controls.Add($btnGUIReload)

$btnSystemRestart = New-Object System.Windows.Forms.Button
$btnSystemRestart.Text = "System neustarten"
$btnSystemRestart.Size = New-Object System.Drawing.Size(210, 35)
$btnSystemRestart.Location = New-Object System.Drawing.Point(0, 37)
$btnSystemRestart.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnSystemRestart.FlatAppearance.BorderSize = 0
$btnSystemRestart.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
$btnSystemRestart.FlatAppearance.MouseOverBackColor = [System.Drawing.Color]::FromArgb(60, 40, 40)
$btnSystemRestart.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
$btnSystemRestart.ForeColor = [System.Drawing.Color]::FromArgb(255, 100, 100)
$btnSystemRestart.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$btnSystemRestart.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
Add-ButtonIcon -Button $btnSystemRestart -IconCode 0xE7E8 -IconSize 12 -LeftMargin 10
$btnSystemRestart.Add_Click({
    $result = [System.Windows.Forms.MessageBox]::Show(
        "WARNUNG: Der Computer wird neu gestartet.`n`nBitte speichern Sie alle offenen Dokumente und schließen Sie alle Programme.`n`nMöchten Sie den Neustart jetzt durchführen?",
        "System Neustart",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Warning
    )

    if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
        $script:countdownSeconds = 10
        $script:countdownTimer = New-Object System.Windows.Forms.Timer
        $script:countdownTimer.Interval = 1000

        $progressBar.Maximum = $script:countdownSeconds
        $progressBar.Value = $script:countdownSeconds

        Update-ProgressStatus -StatusText "System Neustart in $script:countdownSeconds Sekunden..." -ProgressValue $script:countdownSeconds -TextColor ([System.Drawing.Color]::Red)

        $script:countdownTimer.Add_Tick({
            $script:countdownSeconds--
            $progressBar.Value = $script:countdownSeconds

            if ($script:countdownSeconds -gt 0) {
                Update-ProgressStatus -StatusText "System Neustart in $script:countdownSeconds Sekunden..." -ProgressValue $script:countdownSeconds -TextColor ([System.Drawing.Color]::Red)
            }
            else {
                $script:countdownTimer.Stop()
                $script:countdownTimer.Dispose()

                try {
                    Restart-Computer -Force
                }
                catch {
                    try {
                        Start-Process "shutdown.exe" -ArgumentList "/r /t 0" -Verb RunAs
                    }
                    catch {
                        [System.Windows.Forms.MessageBox]::Show(
                            "Fehler beim Neustart: $_",
                            "Fehler",
                            [System.Windows.Forms.MessageBoxButtons]::OK,
                            [System.Windows.Forms.MessageBoxIcon]::Error
                        )
                    }
                }
            }
        })

        $script:countdownTimer.Start()
    }
})
$restartPanel.Content.Controls.Add($btnSystemRestart)

# Neustart direkt zu Starteinstellungen (Safe Mode Auswahl)
$btnSafeModeRestart = New-Object System.Windows.Forms.Button
$btnSafeModeRestart.Text = "Abgesicherter Modus"
$btnSafeModeRestart.Size = New-Object System.Drawing.Size(210, 35)
$btnSafeModeRestart.Location = New-Object System.Drawing.Point(0, 74)
$btnSafeModeRestart.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnSafeModeRestart.FlatAppearance.BorderSize = 0
$btnSafeModeRestart.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
$btnSafeModeRestart.FlatAppearance.MouseOverBackColor = [System.Drawing.Color]::FromArgb(55, 50, 40)
$btnSafeModeRestart.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
$btnSafeModeRestart.ForeColor = [System.Drawing.Color]::FromArgb(255, 165, 0)
$btnSafeModeRestart.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$btnSafeModeRestart.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
Add-ButtonIcon -Button $btnSafeModeRestart -IconCode 0xE83D -IconSize 12 -LeftMargin 10

$btnSafeModeRestart.Add_Click({

    $result = [System.Windows.Forms.MessageBox]::Show(
        "Das System wird neu gestartet und zeigt die Starteinstellungen.`n`n" +
        "Drücken Sie dann F4 für den abgesicherten Modus.`n`n" +
        "✓ Funktioniert mit GRUB/Dual-Boot`n" +
        "✓ Automatisch einmalig (kein Häkchen)`n" +
        "✓ Nur 1x F4 drücken - fertig!`n`n" +
        "Bitte speichern Sie alle offenen Dokumente.`n`n" +
        "Möchten Sie fortfahren?",
        "Starteinstellungen",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Information
    )

    if ($result -ne [System.Windows.Forms.DialogResult]::Yes) {
        return
    }

    try {
        Update-LogFile -Message "Neustart zu Starteinstellungen vom Benutzer gestartet"

        # ------------------------------------------------------------
        # Option 1: Über bootmenupolicy + onetimeadvancedoptions
        # Dies zeigt direkt die Starteinstellungen beim nächsten Boot
        # ------------------------------------------------------------
        
        # Setze onetimeadvancedoptions (einmalig erweiterte Optionen)
        $setAdvanced = Start-Process "bcdedit.exe" `
            -ArgumentList "/set {current} onetimeadvancedoptions yes" `
            -Verb RunAs `
            -Wait `
            -PassThru `
            -WindowStyle Hidden

        if ($setAdvanced.ExitCode -ne 0) {
            Update-LogFile -Message "onetimeadvancedoptions fehlgeschlagen, verwende /r /o Fallback" -Level "WARN"
            
            # Fallback: Normales Advanced Boot Menu
            Start-Process "shutdown.exe" `
                -ArgumentList "/r /o /t 5" `
                -Verb RunAs `
                -WindowStyle Hidden
        } else {
            Update-LogFile -Message "onetimeadvancedoptions aktiviert"
            
            # Normaler Neustart (erweiterte Optionen werden automatisch gezeigt)
            Start-Process "shutdown.exe" `
                -ArgumentList "/r /t 5" `
                -Verb RunAs `
                -WindowStyle Hidden
        }

        Update-ProgressStatus `
            -StatusText "System wird in 5 Sekunden neu gestartet - Starteinstellungen werden geöffnet..." `
            -ProgressValue 50 `
            -TextColor ([System.Drawing.Color]::Orange)

        # GUI schließen
        $timer = New-Object System.Windows.Forms.Timer
        $timer.Interval = 6000
        $timer.Add_Tick({
            $mainform.Close()
            $this.Stop()
        })
        $timer.Start()
    }
    catch {
        Update-LogFile -Message "Fehler beim Neustart zu Starteinstellungen: $_" -Level "ERROR"

        [System.Windows.Forms.MessageBox]::Show(
            "Fehler beim Neustart zu den Starteinstellungen:`n`n$_",
            "Fehler",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
    }
})

$restartPanel.Content.Controls.Add($btnSafeModeRestart)
$restartPanel.Content.Height = 111
$restartButtonPanel.Controls.Add($restartPanel.Container)


# Referenz für Event-Handler
$btnRestart = $restartPanel.Header

#------------------------------------------------------------------------------------------------------------
# VIEW-PANELS FÜR AUSGABEN
#------------------------------------------------------------------------------------------------------------

# Hilfsvariable für aktive Ansicht
$script:currentView = "outputView"

# Erstelle Panels für jede Ausgabeansicht (verborgen)
# Panel für die Standard-Ausgabe
$outputViewPanel = New-Object System.Windows.Forms.Panel
$outputViewPanel.Dock = [System.Windows.Forms.DockStyle]::Fill
$outputViewPanel.Visible = $true
$outputPanel.Controls.Add($outputViewPanel)

# Panel für Status-Info
$statusViewPanel = New-Object System.Windows.Forms.Panel
$statusViewPanel.Dock = [System.Windows.Forms.DockStyle]::Fill
$statusViewPanel.Visible = $false
$outputPanel.Controls.Add($statusViewPanel)

# Panel für Hardware-Info
$hardwareViewPanel = New-Object System.Windows.Forms.Panel
$hardwareViewPanel.Dock = [System.Windows.Forms.DockStyle]::Fill
$hardwareViewPanel.Visible = $false
$outputPanel.Controls.Add($hardwareViewPanel)

# Panel für Tool-Info
$toolInfoViewPanel = New-Object System.Windows.Forms.Panel
$toolInfoViewPanel.Dock = [System.Windows.Forms.DockStyle]::Fill
$toolInfoViewPanel.Visible = $false
$outputPanel.Controls.Add($toolInfoViewPanel)

# Panel für Tool-Downloads
$downloadsViewPanel = New-Object System.Windows.Forms.Panel
$downloadsViewPanel.Dock = [System.Windows.Forms.DockStyle]::Fill
$downloadsViewPanel.Visible = $false
$outputPanel.Controls.Add($downloadsViewPanel)

# Variable für aktuelle Download-Kategorie (leer = keine Kategorie gewählt)
$script:currentDownloadCategory = ""

# Event-Handler für Ansichtsumschaltung
function Switch-OutputView {
    param(
        [string]$viewName
    )
    
    # Vorherige Buttons zurücksetzen
    $btnOutput.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
    $btnOutput.ForeColor = [System.Drawing.Color]::White
    $btnToolDownloads.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
    $btnToolDownloads.ForeColor = [System.Drawing.Color]::White
    
    # Alle Panels ausblenden
    $outputViewPanel.Visible = $false
    $statusViewPanel.Visible = $false
    $hardwareViewPanel.Visible = $false
    $toolInfoViewPanel.Visible = $false
    $downloadsViewPanel.Visible = $false

    # Spezielle Dependency-Tabelle standardmäßig ausblenden
    if ($script:dependencyTableHost) { $script:dependencyTableHost.Visible = $false }

    # Standard-Output wieder einblenden
    if ($outputBox) { $outputBox.Visible = $true }
    
    # Aktuelle Ansicht markieren und einblenden
    switch ($viewName) {
        "outputView" {
            $outputViewPanel.Visible = $true
            $btnOutput.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
            $btnOutput.ForeColor = [System.Drawing.Color]::White
        }
        "statusView" {
            $statusViewPanel.Visible = $true
            $btnStatusInfoH.BackColor = [System.Drawing.Color]::FromArgb(55, 55, 55)
            $btnStatusInfoH.ForeColor = [System.Drawing.Color]::White
            
            # System-Status aktualisieren
            if (-not $script:statusInfoLoaded) {
                $systemStatusBox.Clear()
                Set-OutputSelectionStyle -OutputBox $systemStatusBox -Style 'Info'
                $systemStatusBox.AppendText("System-Status wird geladen...`r`n")

                # Progressbar zurücksetzen
                $progressBar.Value = 0
                $progressBar.CustomText = "Status wird geladen..."
                $progressBar.TextColor = [System.Drawing.Color]::White

                # Live-Modus verwenden, der schrittweise Status anzeigt und ProgressBar aktualisiert
                Get-SystemStatusSummary -statusBox $systemStatusBox -LiveMode
                
                $script:statusInfoLoaded = $true
            }
        }
        "hardwareView" {
            $hardwareViewPanel.Visible = $true
            $btnHardwareInfoH.BackColor = [System.Drawing.Color]::FromArgb(55, 55, 55)
            $btnHardwareInfoH.ForeColor = [System.Drawing.Color]::White
            
            # Hardware-Informationen aktualisieren
            if (-not $script:hardwareInfoLoaded) {
                Get-HardwareInfo -infoBox $hardwareInfoBox
                $script:hardwareInfoLoaded = $true
            }
        }
        "toolInfoView" {
            $toolInfoViewPanel.Visible = $true
            $btnToolInfoH.BackColor = [System.Drawing.Color]::FromArgb(55, 55, 55)
            $btnToolInfoH.ForeColor = [System.Drawing.Color]::White
            
            # Tool-Informationen aktualisieren
            if (-not $script:toolInfoLoaded) {
                Get-ToolInfo -infoBox $toolInfoBox
                $script:toolInfoLoaded = $true
            }
        }
        "downloadsView" {
            $downloadsViewPanel.Visible = $true
            $btnToolDownloads.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
            $btnToolDownloads.ForeColor = [System.Drawing.Color]::White
            
            # Hinweis: Tools werden durch die Kategorie-Buttons geladen
            # Das $script:toolsAlreadyLoaded Flag wird nicht mehr benötigt
        }
    }
    
    # Aktuelle Ansicht speichern
    $script:currentView = $viewName
}

# Event-Handler für Buttons
$btnOutput.Add_Click({ 
    # Alle mainContentPanel Panels ausblenden (zurück zur Standardansicht)
    if ($global:tblSystem) { $global:tblSystem.Visible = $false }
    if ($tblDisk) { $tblDisk.Visible = $false }
    if ($tblNetwork) { $tblNetwork.Visible = $false }
    if ($tblCleanup) { $tblCleanup.Visible = $false }
    if ($global:tblDependencies) { $global:tblDependencies.Visible = $false }
    if ($global:tblSmartRepair) { $global:tblSmartRepair.Visible = $false }
    
    # Suchfeld ausblenden (gehört zu Tool-Downloads)
    if ($searchPanel) { $searchPanel.Visible = $false }
    
    # Horizontale Info-Container wieder einblenden
    if ($infoHorizontalPanel -and $infoHorizontalPanel.Container) {
        $infoHorizontalPanel.Container.Visible = $true
    }
    if ($troubleshootHorizontalPanel -and $troubleshootHorizontalPanel.Container) {
        $troubleshootHorizontalPanel.Container.Visible = $true
    }
    
    Switch-OutputView -viewName "outputView"
    
    # OutputBox zurücksetzen und Willkommensnachricht anzeigen
    $outputBox.Clear()
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'BannerFrame'
    $outputBox.AppendText("`t╔═══════════════════════════════════════════════════════════════╗`r`n")
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'BannerTitle'
    $outputBox.AppendText("`t║            WILLKOMMEN BEI BOCKI'S WINDOWS TOOL-KIT            ║`r`n")
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'BannerFrame'
    $outputBox.AppendText("`t╚═══════════════════════════════════════════════════════════════╝`r`n`r`n")

    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Heading'
    $outputBox.AppendText("Verfügbare Bereiche:`r`n`r`n")

    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Accent'
    Add-OutputIcon -OutputBox $outputBox -IconCode 0xE83D
    $outputBox.AppendText(" SYSTEM/SICHERHEIT:`r`n")
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Info'
    $outputBox.AppendText("  • Windows Defender: Scan & Optimierung`r`n")
    $outputBox.AppendText("  • Firewall: Regeln & Verwaltung`r`n")
    $outputBox.AppendText("  • AppLocker: Anwendungssteuerung`r`n`r`n")

    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Accent'
    Add-OutputIcon -OutputBox $outputBox -IconCode 0xE90F
    $outputBox.AppendText(" DIAGNOSE/REPARATUR:`r`n")
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Info'
    $outputBox.AppendText("  • DISM & SFC: System-Integritätsprüfung`r`n")
    $outputBox.AppendText("  • CHKDSK: Datenträger-Analyse`r`n")
    $outputBox.AppendText("  • Windows Update: Reparatur & Wartung`r`n`r`n")

    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Accent'
    Add-OutputIcon -OutputBox $outputBox -IconCode 0xE774
    $outputBox.AppendText(" NETZWERK-TOOLS:`r`n")
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Info'
    $outputBox.AppendText("  • Netzwerk-Diagnose & Adapter-Reset`r`n")
    $outputBox.AppendText("  • DNS-Cache & IP-Konfiguration`r`n")
    $outputBox.AppendText("  • Verbindungsanalyse & Ping-Tests`r`n`r`n")

    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Accent'
    Add-OutputIcon -OutputBox $outputBox -IconCode 0xE74C
    $outputBox.AppendText(" BEREINIGUNG:`r`n")
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Info'
    $outputBox.AppendText("  • Temp-Dateien & Cache bereinigen`r`n")
    $outputBox.AppendText("  • Windows Update-Cache entfernen`r`n")
    $outputBox.AppendText("  • Browser-Daten löschen`r`n`r`n")

    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Accent'
    Add-OutputIcon -OutputBox $outputBox -IconCode 0xE9D9
    $outputBox.AppendText(" INFORMATIONEN:`r`n")
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Info'
    $outputBox.AppendText("  • System-Status & Betriebssystem-Details`r`n")
    $outputBox.AppendText("  • Hardware-Informationen (CPU, RAM, GPU)`r`n")
    $outputBox.AppendText("  • Tool-Dokumentation & Beschreibungen`r`n`r`n")

    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Accent'
    $outputBox.AppendText("📦 TOOL-DOWNLOADS:`r`n")
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Info'
    $outputBox.AppendText("  • 50+ professionelle Tools via Winget`r`n")
    $outputBox.AppendText("  • Kategorien: System, Anwendungen, Audio/TV, Coding/IT`r`n")
    $outputBox.AppendText("  • Automatische Installation & Update-Verwaltung`r`n`r`n")

    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Success'
    $outputBox.AppendText("✨ Tipp: Klappen Sie ein Menü auf der linken Seite auf, um zu starten!`r`n")
    
    # Visuelles Feedback
    $btnOutput.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
    $btnStatusInfoH.BackColor = [System.Drawing.Color]::FromArgb(37, 37, 38)
    $btnHardwareInfoH.BackColor = [System.Drawing.Color]::FromArgb(37, 37, 38)
    $btnToolInfoH.BackColor = [System.Drawing.Color]::FromArgb(37, 37, 38)
    $btnToolDownloads.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
    $troubleshootPanel.Header.BackColor = [System.Drawing.Color]::FromArgb(37, 37, 38)
    
    # Setze Info-Panel-Header zurück
    $infoHorizontalPanel.Header.BackColor = [System.Drawing.Color]::FromArgb(37, 37, 38)
    # Setze Downloads-Panel-Header zurück
    $downloadsPanel.Header.BackColor = [System.Drawing.Color]::FromArgb(37, 37, 38)
    # Setze Problembehandlung-Panel-Header zurück
    $troubleshootPanel.Header.BackColor = [System.Drawing.Color]::FromArgb(37, 37, 38)
})

# Erstelle System-Status-Box für die Status-Info-Ansicht
$systemStatusBox = New-Object System.Windows.Forms.RichTextBox
$systemStatusBox.Dock = [System.Windows.Forms.DockStyle]::Fill
$systemStatusBox.Font = New-Object System.Drawing.Font("Consolas", 10)
$systemStatusBox.Multiline = $true
$systemStatusBox.ScrollBars = "Both"
$systemStatusBox.WordWrap = $false
$systemStatusBox.ReadOnly = $true
$systemStatusBox.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)  # Dunkles Grau
$systemStatusBox.ForeColor = [System.Drawing.Color]::FromArgb(220, 220, 220)  # Helles Grau für Text
$systemStatusBox.Text = "System-Status wird geladen...`r`n"
$statusViewPanel.Controls.Add($systemStatusBox)

# Stelle sicher, dass das ProgressBarTools-Modul geladen ist
if (-not (Get-Command -Name Initialize-ProgressComponents -ErrorAction SilentlyContinue)) {
    Import-Module "$PSScriptRoot\Modules\Core\ProgressBarTools.psm1" -Force
}

# Erstelle die TextProgressBar über das Modul (als global für Zugriff aus Modulen)
$global:progressBar = New-TextProgressBar -X 225 -Y 755 -Width 735 -Height 30 -InitialText "Bereit" -InitialTextColor ([System.Drawing.Color]::White)
$mainform.Controls.Add($global:progressBar)
Initialize-ProgressComponents -ProgressBar $global:progressBar -StatusLabel $progressStatusLabel

# Erstelle Output-Box für die Standard-Ausgabe
$outputBox = New-Object System.Windows.Forms.RichTextBox
$outputBox.Dock = [System.Windows.Forms.DockStyle]::Fill
$outputBox.Font = New-Object System.Drawing.Font("Consolas", 12)
$outputBox.Multiline = $true
$outputBox.ScrollBars = "Vertical"
$outputBox.WordWrap = $true
$outputBox.ReadOnly = $true
$outputBox.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)  # Dunkles Grau
$outputBox.ForeColor = [System.Drawing.Color]::FromArgb(220, 220, 220)  # Helles Grau für Text

# Event-Handler für automatisches Scrollen hinzufügen
$outputBox.Add_TextChanged({
        # Cursor ans Ende des Textes setzen
        $this.SelectionStart = $this.TextLength
        # Zum Cursor scrollen
        $this.ScrollToCaret()
    })

# Output-Box dem OutputViewPanel hinzufügen
$outputViewPanel.Controls.Add($outputBox)

# Erstelle Output-Box für Hardware-Info
$hardwareInfoBox = New-Object System.Windows.Forms.RichTextBox
$hardwareInfoBox.Dock = [System.Windows.Forms.DockStyle]::Fill
$hardwareInfoBox.Font = New-Object System.Drawing.Font("Consolas", 12)
$hardwareInfoBox.Multiline = $true
$hardwareInfoBox.ScrollBars = "Both"
$hardwareInfoBox.WordWrap = $false
$hardwareInfoBox.ReadOnly = $true
$hardwareInfoBox.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)  # Dunkles Grau
$hardwareInfoBox.ForeColor = [System.Drawing.Color]::FromArgb(220, 220, 220)  # Helles Grau für Text
$hardwareInfoBox.Text = "Hardware-Informationen werden geladen...`r`n"
$hardwareViewPanel.Controls.Add($hardwareInfoBox)

# Funktion zum Abrufen der Hardware-Informationen
function Get-HardwareInfo {
    param (
        [System.Windows.Forms.RichTextBox]$infoBox
    )

    $infoBox.Clear()
    Set-OutputSelectionStyle -OutputBox $infoBox -Style 'Info'
    $infoBox.AppendText("===== HARDWARE-INFORMATIONEN =====`r`n`r`n")

    # System-Informationen (Computer/Mainboard)
    Set-OutputSelectionStyle -OutputBox $infoBox -Style 'Info'
    $infoBox.AppendText("SYSTEM-INFORMATIONEN:`r`n")

    try {
        $computerSystem = Get-WmiObject -Class Win32_ComputerSystem
        Set-OutputSelectionStyle -OutputBox $infoBox -Style 'Default'
        $infoBox.AppendText("Hersteller: $($computerSystem.Manufacturer)`r`n")
        Set-OutputSelectionStyle -OutputBox $infoBox -Style 'Default'
        $infoBox.AppendText("Modell: $($computerSystem.Model)`r`n")
        Set-OutputSelectionStyle -OutputBox $infoBox -Style 'Default'
        $infoBox.AppendText("Systemname: $($computerSystem.Name)`r`n")
        Set-OutputSelectionStyle -OutputBox $infoBox -Style 'Default'
        $infoBox.AppendText("Domäne/Arbeitsgruppe: $($computerSystem.Domain)`r`n`r`n")
    }
    catch {
        Set-OutputSelectionStyle -OutputBox $infoBox -Style 'Error'
        $infoBox.AppendText("Fehler beim Abrufen der System-Informationen: $_`r`n`r`n")
    }

    # BIOS-Informationen
    Set-OutputSelectionStyle -OutputBox $infoBox -Style 'Info'
    $infoBox.AppendText("BIOS-INFORMATIONEN:`r`n")

    try {
        $biosInfo = Get-WmiObject -Class Win32_BIOS
        Set-OutputSelectionStyle -OutputBox $infoBox -Style 'Default'
        $infoBox.AppendText("Hersteller: $($biosInfo.Manufacturer)`r`n")
        Set-OutputSelectionStyle -OutputBox $infoBox -Style 'Default'
        $infoBox.AppendText("Version: $($biosInfo.SMBIOSBIOSVersion)`r`n")
        Set-OutputSelectionStyle -OutputBox $infoBox -Style 'Default'
        $infoBox.AppendText("Release-Datum: $($biosInfo.ConvertToDateTime($biosInfo.ReleaseDate).ToString('dd.MM.yyyy'))`r`n")
        Set-OutputSelectionStyle -OutputBox $infoBox -Style 'Default'
        $infoBox.AppendText("SMBIOS-Version: $($biosInfo.SMBIOSMajorVersion).$($biosInfo.SMBIOSMinorVersion)`r`n`r`n")
    }
    catch {
        Set-OutputSelectionStyle -OutputBox $infoBox -Style 'Error'
        $infoBox.AppendText("Fehler beim Abrufen der BIOS-Informationen: $_`r`n`r`n")
    }

    # Mainboard-Informationen
    Set-OutputSelectionStyle -OutputBox $infoBox -Style 'Info'
    $infoBox.AppendText("MAINBOARD-INFORMATIONEN:`r`n")

    try {
        $baseBoard = Get-WmiObject -Class Win32_BaseBoard
        Set-OutputSelectionStyle -OutputBox $infoBox -Style 'Default'
        $infoBox.AppendText("Hersteller: $($baseBoard.Manufacturer)`r`n")
        Set-OutputSelectionStyle -OutputBox $infoBox -Style 'Default'
        $infoBox.AppendText("Produkt: $($baseBoard.Product)`r`n")
        Set-OutputSelectionStyle -OutputBox $infoBox -Style 'Default'
        $infoBox.AppendText("Version: $($baseBoard.Version)`r`n")
        Set-OutputSelectionStyle -OutputBox $infoBox -Style 'Default'
        $infoBox.AppendText("Seriennummer: $($baseBoard.SerialNumber)`r`n`r`n")
    }
    catch {
        Set-OutputSelectionStyle -OutputBox $infoBox -Style 'Error'
        $infoBox.AppendText("Fehler beim Abrufen der Mainboard-Informationen: $_`r`n`r`n")
    }

    # CPU-Informationen
    Set-OutputSelectionStyle -OutputBox $infoBox -Style 'Info'
    $infoBox.AppendText("CPU-INFORMATIONEN:`r`n")

    try {
        $cpuInfo = Get-WmiObject -Class Win32_Processor
        foreach ($cpu in $cpuInfo) {
            Set-OutputSelectionStyle -OutputBox $infoBox -Style 'Default'
            $infoBox.AppendText("Prozessor: $($cpu.Name)`r`n")
            Set-OutputSelectionStyle -OutputBox $infoBox -Style 'Default'
            $infoBox.AppendText("Hersteller: $($cpu.Manufacturer)`r`n")
            Set-OutputSelectionStyle -OutputBox $infoBox -Style 'Default'
            $infoBox.AppendText("Kerne: $($cpu.NumberOfCores)`r`n")
            Set-OutputSelectionStyle -OutputBox $infoBox -Style 'Default'
            $infoBox.AppendText("Logische Prozessoren: $($cpu.NumberOfLogicalProcessors)`r`n")
            Set-OutputSelectionStyle -OutputBox $infoBox -Style 'Default'
            $infoBox.AppendText("Taktrate: $($cpu.MaxClockSpeed) MHz`r`n")
            
            # L2-Cache anzeigen (wenn verfügbar)
            if ($cpu.L2CacheSize -and $cpu.L2CacheSize -gt 0) {
                Set-OutputSelectionStyle -OutputBox $infoBox -Style 'Default'
                $l2CacheMB = [math]::Round($cpu.L2CacheSize / 1024, 2)
                $infoBox.AppendText("L2-Cache: $l2CacheMB MB`r`n")
            }
            
            # L3-Cache anzeigen (wenn verfügbar)
            if ($cpu.L3CacheSize -and $cpu.L3CacheSize -gt 0) {
                Set-OutputSelectionStyle -OutputBox $infoBox -Style 'Default'
                $l3CacheMB = [math]::Round($cpu.L3CacheSize / 1024, 2)
                $infoBox.AppendText("L3-Cache: $l3CacheMB MB`r`n")
            }
            
            Set-OutputSelectionStyle -OutputBox $infoBox -Style 'Default'
            $infoBox.AppendText("`r`n")
        }
    }
    catch {
        Set-OutputSelectionStyle -OutputBox $infoBox -Style 'Error'
        $infoBox.AppendText("Fehler beim Abrufen der CPU-Informationen: $_`r`n`r`n")
    }

    # RAM-Informationen
    Set-OutputSelectionStyle -OutputBox $infoBox -Style 'Info'
    $infoBox.AppendText("RAM-INFORMATIONEN:`r`n")

    try {
        $totalRAM = (Get-WmiObject -Class Win32_ComputerSystem).TotalPhysicalMemory / 1GB
        Set-OutputSelectionStyle -OutputBox $infoBox -Style 'Default'
        $infoBox.AppendText("Gesamter RAM: $([math]::Round($totalRAM, 2)) GB`r`n")

        $memoryModules = Get-WmiObject -Class Win32_PhysicalMemory
        Set-OutputSelectionStyle -OutputBox $infoBox -Style 'Default'
        $infoBox.AppendText("Anzahl der RAM-Module: $($memoryModules.Count)`r`n")

        foreach ($module in $memoryModules) {
            $capacity = $module.Capacity / 1GB
            Set-OutputSelectionStyle -OutputBox $infoBox -Style 'Default'
            $infoBox.AppendText("RAM-Modul: $([math]::Round($capacity, 2)) GB ($($module.DeviceLocator))`r`n")
        }
        Set-OutputSelectionStyle -OutputBox $infoBox -Style 'Default'
        $infoBox.AppendText("`r`n")
    }
    catch {
        Set-OutputSelectionStyle -OutputBox $infoBox -Style 'Error'
        $infoBox.AppendText("Fehler beim Abrufen der RAM-Informationen: $_`r`n`r`n")
    }

    # Grafikkarten-Informationen
    Set-OutputSelectionStyle -OutputBox $infoBox -Style 'Info'
    $infoBox.AppendText("GRAFIKKARTEN-INFORMATIONEN:`r`n")

    try {
        $gpuInfo = Get-WmiObject -Class Win32_VideoController
        foreach ($gpu in $gpuInfo) {
            Set-OutputSelectionStyle -OutputBox $infoBox -Style 'Default'
            $infoBox.AppendText("Grafikkarte: $($gpu.Name)`r`n")
            Set-OutputSelectionStyle -OutputBox $infoBox -Style 'Default'
            $infoBox.AppendText("Treiber-Version: $($gpu.DriverVersion)`r`n")
            Set-OutputSelectionStyle -OutputBox $infoBox -Style 'Default'
            $infoBox.AppendText("Video-RAM: $(($gpu.AdapterRAM / 1MB)) MB`r`n")
            Set-OutputSelectionStyle -OutputBox $infoBox -Style 'Default'
            $infoBox.AppendText("Aktueller Modus: $($gpu.CurrentHorizontalResolution) x $($gpu.CurrentVerticalResolution)`r`n`r`n")
        }
    }
    catch {
        Set-OutputSelectionStyle -OutputBox $infoBox -Style 'Error'
        $infoBox.AppendText("Fehler beim Abrufen der Grafikkarten-Informationen: $_`r`n`r`n")
    }

    # Festplatten- und Laufwerk-Informationen (zusammengefasst)
    Set-OutputSelectionStyle -OutputBox $infoBox -Style 'Info'
    $infoBox.AppendText("FESTPLATTEN & LAUFWERKE:`r`n")

    try {
        # Physische Festplatten abrufen
        $drives = Get-WmiObject -Class Win32_DiskDrive
        
        foreach ($drive in $drives) {
            $sizeGB = [math]::Round($drive.Size / 1GB, 2)
            Set-OutputSelectionStyle -OutputBox $infoBox -Style 'Default'
            $infoBox.AppendText("`r`n[Physisch] $($drive.Model)`r`n")
            Set-OutputSelectionStyle -OutputBox $infoBox -Style 'Default'
            $infoBox.AppendText("  Größe: $sizeGB GB | Schnittstelle: $($drive.InterfaceType)`r`n")
            
            # Zugehörige Partitionen und logische Laufwerke finden
            $partitions = Get-WmiObject -Query "ASSOCIATORS OF {Win32_DiskDrive.DeviceID='$($drive.DeviceID)'} WHERE AssocClass=Win32_DiskDriveToDiskPartition"
            
            foreach ($partition in $partitions) {
                $logicalDisks = Get-WmiObject -Query "ASSOCIATORS OF {Win32_DiskPartition.DeviceID='$($partition.DeviceID)'} WHERE AssocClass=Win32_LogicalDiskToPartition"
                
                foreach ($logicalDisk in $logicalDisks) {
                    $freeGB = [math]::Round($logicalDisk.FreeSpace / 1GB, 2)
                    $totalGB = [math]::Round($logicalDisk.Size / 1GB, 2)
                    $usedPercent = [math]::Round(($logicalDisk.Size - $logicalDisk.FreeSpace) / $logicalDisk.Size * 100, 1)
                    $volumeName = if ($logicalDisk.VolumeName) { $logicalDisk.VolumeName } else { "Unbenannt" }
                    
                    Set-OutputSelectionStyle -OutputBox $infoBox -Style 'Default'
                    $infoBox.AppendText("    └─ Laufwerk $($logicalDisk.DeviceID) ($volumeName)`r`n")
                    Set-OutputSelectionStyle -OutputBox $infoBox -Style 'Default'
                    $infoBox.AppendText("       Größe: $totalGB GB | Frei: $freeGB GB | Belegung: $usedPercent%`r`n")
                }
            }
        }
        
        Set-OutputSelectionStyle -OutputBox $infoBox -Style 'Default'
        $infoBox.AppendText("`r`n")
    }
    catch {
        Set-OutputSelectionStyle -OutputBox $infoBox -Style 'Error'
        $infoBox.AppendText("Fehler beim Abrufen der Laufwerk-Informationen: $_`r`n`r`n")
    }

    # Netzwerk-Informationen
    Set-OutputSelectionStyle -OutputBox $infoBox -Style 'Info'
    $infoBox.AppendText("NETZWERK-INFORMATIONEN:`r`n")

    try {
        $networkAdapters = Get-WmiObject -Class Win32_NetworkAdapter | Where-Object { $_.PhysicalAdapter -eq $true }
        foreach ($adapter in $networkAdapters) {
            Set-OutputSelectionStyle -OutputBox $infoBox -Style 'Default'
            $infoBox.AppendText("Adapter: $($adapter.Name)`r`n")
            Set-OutputSelectionStyle -OutputBox $infoBox -Style 'Default'
            $infoBox.AppendText("MAC-Adresse: $($adapter.MACAddress)`r`n")

            $config = Get-WmiObject -Class Win32_NetworkAdapterConfiguration | Where-Object { $_.Index -eq $adapter.Index }
            if ($config -and $config.IPAddress) {
                Set-OutputSelectionStyle -OutputBox $infoBox -Style 'Default'
                $infoBox.AppendText("IP-Adressen:`r`n")
                foreach ($ip in $config.IPAddress) {
                    Set-OutputSelectionStyle -OutputBox $infoBox -Style 'Default'
                    $infoBox.AppendText("  • $ip`r`n")
                }
            }
            Set-OutputSelectionStyle -OutputBox $infoBox -Style 'Default'
            $infoBox.AppendText("`r`n")
        }
    }
    catch {
        Set-OutputSelectionStyle -OutputBox $infoBox -Style 'Error'
        $infoBox.AppendText("Fehler beim Abrufen der Netzwerk-Informationen: $_`r`n`r`n")
    }

    # Betriebssystem-Informationen
    Set-OutputSelectionStyle -OutputBox $infoBox -Style 'Info'
    $infoBox.AppendText("BETRIEBSSYSTEM-INFORMATIONEN:`r`n")

    try {
        $osInfo = Get-WmiObject -Class Win32_OperatingSystem
        Set-OutputSelectionStyle -OutputBox $infoBox -Style 'Default'
        $infoBox.AppendText("Betriebssystem: $($osInfo.Caption)`r`n")
        Set-OutputSelectionStyle -OutputBox $infoBox -Style 'Default'
        $infoBox.AppendText("Version: $($osInfo.Version)`r`n")
        Set-OutputSelectionStyle -OutputBox $infoBox -Style 'Default'
        $infoBox.AppendText("Build: $($osInfo.BuildNumber)`r`n")
        Set-OutputSelectionStyle -OutputBox $infoBox -Style 'Default'
        $infoBox.AppendText("Architektur: $($osInfo.OSArchitecture)`r`n")
        Set-OutputSelectionStyle -OutputBox $infoBox -Style 'Default'
        $infoBox.AppendText("Installiert am: $($osInfo.InstallDate)`r`n")
        Set-OutputSelectionStyle -OutputBox $infoBox -Style 'Default'
        $infoBox.AppendText("Letzter Boot: $($osInfo.LastBootUpTime)`r`n")
    }
    catch {
        Set-OutputSelectionStyle -OutputBox $infoBox -Style 'Error'
        $infoBox.AppendText("Fehler beim Abrufen der Betriebssystem-Informationen: $_`r`n`r`n")
    }
}

# Refresh-Button für Hardware-Info erstellen
$btnRefreshHardware = New-Object System.Windows.Forms.Button
$btnRefreshHardware.Text = "Hardware-Info aktualisieren"
$btnRefreshHardware.Size = New-Object System.Drawing.Size(185, 35)  # Höhe an Hauptbuttons angepasst
$btnRefreshHardware.Location = New-Object System.Drawing.Point(10, 5)
$btnRefreshHardware.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnRefreshHardware.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
$btnRefreshHardware.ForeColor = [System.Drawing.Color]::White
$btnRefreshHardware.Font = New-Object System.Drawing.Font("Segoe UI", 8.5, [System.Drawing.FontStyle]::Bold)
$btnRefreshHardware.Add_Click({ Get-HardwareInfo -infoBox $hardwareInfoBox })
$hardwareViewPanel.Controls.Add($btnRefreshHardware)

# Erstelle Output-Box für Tool-Info und füge sie zum Tool-Info-Panel hinzu
$toolInfoBox = New-Object System.Windows.Forms.RichTextBox
$toolInfoBox.Dock = [System.Windows.Forms.DockStyle]::Fill
$toolInfoBox.Font = New-Object System.Drawing.Font("Consolas", 12)
$toolInfoBox.Multiline = $true
$toolInfoBox.ScrollBars = "Both"
$toolInfoBox.WordWrap = $false
$toolInfoBox.ReadOnly = $true
$toolInfoBox.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)  # Dunkles Grau
$toolInfoBox.ForeColor = [System.Drawing.Color]::FromArgb(220, 220, 220)  # Helles Grau für Text
$toolInfoBox.Text = "Tool-Informationen werden geladen...`r`n"
$toolInfoViewPanel.Controls.Add($toolInfoBox)

# Funktion zum automatischen Wechseln zur Ausgabe-Ansicht
function Switch-ToOutputTab {
    param()
    # HINWEIS: Die Funktion benötigt keine Parameter mehr, der TabControl-Parameter wurde entfernt
    # Wechsle zur Output-Ansicht (bleibt im aktuellen Panel)
    Switch-OutputView -viewName "outputView"
}



# Erstelle Buttons für System-Tools
# System Security Panel Buttons - Direkt im tblSystem platziert (ohne GroupBox) - Horizontal nebeneinander
$btnQuickMRT = New-Object System.Windows.Forms.Button
$btnQuickMRT.Name = "btnQuickMRT"
$btnQuickMRT.Text = "MRT Quick Scan"
$btnQuickMRT.Size = New-Object System.Drawing.Size(155, 35)  # Breite an Unterkategorie-Buttons angepasst
$btnQuickMRT.Location = New-Object System.Drawing.Point(5, 5)  # 5px vom oberen Rand
$btnQuickMRT.BackColor = $script:btnSubNavColor
$btnQuickMRT.ForeColor = [System.Drawing.Color]::White
$btnQuickMRT.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnQuickMRT.FlatAppearance.BorderSize = 0
$btnQuickMRT.Font = New-Object System.Drawing.Font("Segoe UI", 8.5, [System.Drawing.FontStyle]::Bold)
$btnQuickMRT.Tag = "securityControl"
$btnQuickMRT.Add_Click({
        Switch-ToOutputTab
        # Status auf "Scan läuft..." setzen
        Update-ProgressStatus -StatusText "MRT-Quick Scan wird gestartet..." -ProgressValue 0 -TextColor ([System.Drawing.Color]::White)
        Start-QuickMRT -outputBox $outputBox -progressBar $progressBar
        # Nach dem Scan Status auf "Fertig" setzen
        Update-ProgressStatus -StatusText "Fertig" -ProgressValue 100 -TextColor ([System.Drawing.Color]::White)
        # Scan-Historie aktualisieren
        Update-ScanHistory -ToolName "QuickMRT"
        # Button-Status-Indikatoren aktualisieren
        Update-AllButtonStatusIndicators
    })
$global:tblSystem.Controls.Add($btnQuickMRT)

$btnFullMRT = New-Object System.Windows.Forms.Button
$btnFullMRT.Name = "btnFullMRT"
$btnFullMRT.Text = "MRT Full Scan"
$btnFullMRT.Size = New-Object System.Drawing.Size(155, 35)  # Breite an Unterkategorie-Buttons angepasst
$btnFullMRT.Location = New-Object System.Drawing.Point(180, 5)  # 5px vom oberen Rand
$btnFullMRT.BackColor = $script:btnSubNavColor
$btnFullMRT.ForeColor = [System.Drawing.Color]::White
$btnFullMRT.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnFullMRT.FlatAppearance.BorderSize = 0
$btnFullMRT.Font = New-Object System.Drawing.Font("Segoe UI", 8.5, [System.Drawing.FontStyle]::Bold)
$btnFullMRT.Tag = "securityControl"
$btnFullMRT.Add_Click({
        # Ausgabebox leeren
        $outputBox.Clear()
        Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Info'
        $outputBox.AppendText("Starte MRT Full Scan...`r`n")

        # Tab Control umschalten
        $tabControl.SelectedIndex = 0  # Ausgabe-Tab

        # FullMRT-Scan starten
        Start-FullMRT -outputBox $outputBox -progressBar $progressBar
        
        # Scan-Historie aktualisieren
        Update-ScanHistory -ToolName "FullMRT"
        # Button-Status-Indikatoren aktualisieren
        Update-AllButtonStatusIndicators
    })
$global:tblSystem.Controls.Add($btnFullMRT)

$btnWindowsDefender = New-Object System.Windows.Forms.Button
$btnWindowsDefender.Name = "btnWindowsDefender"
$btnWindowsDefender.Text = "Windows Defender"
$btnWindowsDefender.Size = New-Object System.Drawing.Size(155, 35)  # Breite an Unterkategorie-Buttons angepasst
$btnWindowsDefender.Location = New-Object System.Drawing.Point(355, 5)  # 5px vom oberen Rand
$btnWindowsDefender.BackColor = $script:btnSubNavColor
$btnWindowsDefender.ForeColor = [System.Drawing.Color]::White
$btnWindowsDefender.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnWindowsDefender.FlatAppearance.BorderSize = 0
$btnWindowsDefender.Font = New-Object System.Drawing.Font("Segoe UI", 8.5, [System.Drawing.FontStyle]::Bold)
$btnWindowsDefender.Tag = "securityControl"
$btnWindowsDefender.Add_Click({
        Switch-ToOutputTab
        $outputBox.Clear()
        Update-ProgressStatus -StatusText "Windows Defender wird gestartet..." -ProgressValue 0 -TextColor ([System.Drawing.Color]::White)
        Start-WindowsDefender -outputBox $outputBox -progressBar $progressBar -MainForm $mainform
        # Scan-Historie aktualisieren
        Update-ScanHistory -ToolName "WindowsDefender"
        # Button-Status-Indikatoren aktualisieren
        Update-AllButtonStatusIndicators
    })
$global:tblSystem.Controls.Add($btnWindowsDefender)

# Button für Windows Defender Offline-Scan
$btnDefenderOffline = New-Object System.Windows.Forms.Button
$btnDefenderOffline.Name = "btnDefenderOffline"
$btnDefenderOffline.Text = "Defender Offline"
$btnDefenderOffline.Size = New-Object System.Drawing.Size(155, 35)  # Breite an Unterkategorie-Buttons angepasst
$btnDefenderOffline.Location = New-Object System.Drawing.Point(530, 5)  # 5px vom oberen Rand
$btnDefenderOffline.BackColor = $script:btnSubNavColor
$btnDefenderOffline.ForeColor = [System.Drawing.Color]::White
$btnDefenderOffline.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnDefenderOffline.FlatAppearance.BorderSize = 0
$btnDefenderOffline.Font = New-Object System.Drawing.Font("Segoe UI", 8.5, [System.Drawing.FontStyle]::Bold)
$btnDefenderOffline.Tag = "securityControl"
$btnDefenderOffline.Add_Click({
        Switch-ToOutputTab
        $outputBox.Clear()
        Update-ProgressStatus -StatusText "Windows Defender Offline-Scan wird vorbereitet..." -ProgressValue 0 -TextColor ([System.Drawing.Color]::White)
        Start-DefenderOfflineScan -outputBox $outputBox -progressBar $progressBar -MainForm $mainform
        # Scan-Historie aktualisieren
        Update-ScanHistory -ToolName "DefenderOfflineScan"
        # Button-Status-Indikatoren aktualisieren
        Update-AllButtonStatusIndicators
    })
$global:tblSystem.Controls.Add($btnDefenderOffline)


# System Maintenance Panel Buttons - Direkt im tblSystem platziert (ohne GroupBox) - Horizontal nebeneinander
$btnSFC = New-Object System.Windows.Forms.Button
$btnSFC.Name = "btnSFC"
$btnSFC.Text = "SFC Check"
$btnSFC.Size = New-Object System.Drawing.Size(155, 35)  # Breite an Unterkategorie-Buttons angepasst
$btnSFC.Location = New-Object System.Drawing.Point(5, 5)  # 5px vom oberen Rand
$btnSFC.BackColor = $script:btnSubNavColor
$btnSFC.ForeColor = [System.Drawing.Color]::White
$btnSFC.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnSFC.FlatAppearance.BorderSize = 0
$btnSFC.Font = New-Object System.Drawing.Font("Segoe UI", 8.5, [System.Drawing.FontStyle]::Bold)
$btnSFC.Tag = "maintenanceControl"
$btnSFC.Add_Click({
        Switch-ToOutputTab
        # Status auf "SFC Check läuft..." setzen
        Update-ProgressStatus -StatusText "SFC Check wird initialisiert..." -ProgressValue 0 -TextColor ([System.Drawing.Color]::White)
        Start-SFCCheck -outputBox $outputBox -progressBar $progressBar
        # Nach dem Check Status auf "Fertig" setzen
        Update-ProgressStatus -StatusText "Fertig" -ProgressValue 100 -TextColor ([System.Drawing.Color]::White)
        
        # Scan-Historie aktualisieren
        Update-ScanHistory -ToolName "SFC"
        # Button-Status-Indikatoren aktualisieren
        Update-AllButtonStatusIndicators
    })
$global:tblSystem.Controls.Add($btnSFC)

$btnMemoryDiag = New-Object System.Windows.Forms.Button
$btnMemoryDiag.Name = "btnMemoryDiag"
$btnMemoryDiag.Text = "Memory Diagnostic"
$btnMemoryDiag.Size = New-Object System.Drawing.Size(155, 35)  # Breite an Unterkategorie-Buttons angepasst
$btnMemoryDiag.Location = New-Object System.Drawing.Point(5, 5)  # 5px vom oberen Rand
$btnMemoryDiag.BackColor = $script:btnSubNavColor
$btnMemoryDiag.ForeColor = [System.Drawing.Color]::White
$btnMemoryDiag.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnMemoryDiag.FlatAppearance.BorderSize = 0
$btnMemoryDiag.Font = New-Object System.Drawing.Font("Segoe UI", 8.5, [System.Drawing.FontStyle]::Bold)
$btnMemoryDiag.Tag = "diagnoseControl"
$btnMemoryDiag.Add_Click({
        Switch-ToOutputTab
        # Status auf "Memory Diagnostic wird gestartet..." setzen
        Update-ProgressStatus -StatusText "Memory Diagnostic wird gestartet..." -ProgressValue 0 -TextColor ([System.Drawing.Color]::White)
        Start-MemoryDiagnostic -outputBox $outputBox -progressBar $progressBar
        # NICHT automatisch "Fertig" setzen - das macht Start-MemoryDiagnostic selbst je nach Ergebnis
        
        # Scan-Historie aktualisieren
        Update-ScanHistory -ToolName "MemoryDiag"
        # Button-Status-Indikatoren aktualisieren
        Update-AllButtonStatusIndicators
    })
$tblDisk.Controls.Add($btnMemoryDiag)



$btnWinUpdate = New-Object System.Windows.Forms.Button
$btnWinUpdate.Name = "btnWinUpdate"
$btnWinUpdate.Text = "Windows Update"
$btnWinUpdate.Size = New-Object System.Drawing.Size(155, 35)  # Breite an Unterkategorie-Buttons angepasst
$btnWinUpdate.Location = New-Object System.Drawing.Point(180, 5)  # Position nach links verschoben (CMD-Admin entfernt)
$btnWinUpdate.BackColor = $script:btnSubNavColor
$btnWinUpdate.ForeColor = [System.Drawing.Color]::White
$btnWinUpdate.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnWinUpdate.FlatAppearance.BorderSize = 0
$btnWinUpdate.Font = New-Object System.Drawing.Font("Segoe UI", 8.5, [System.Drawing.FontStyle]::Bold)
$btnWinUpdate.Tag = "maintenanceControl"
$btnWinUpdate.Add_Click({
        Switch-ToOutputTab
        # Status auf "Windows Update wird gestartet..." setzen
        Update-ProgressStatus -StatusText "Windows Update wird gestartet..." -ProgressValue 0 -TextColor ([System.Drawing.Color]::White)
        try {
            # Rufe die Modulfunktionen auf
            Start-WindowsUpdate -outputBox $outputBox -progressBar $progressBar -MainForm $mainform
            
            # Scan-Historie aktualisieren
            Update-ScanHistory -ToolName "WinUpdate"
            # Button-Status-Indikatoren aktualisieren
            Update-AllButtonStatusIndicators

            # Suche nach Updates
            $updateSession = New-Object -ComObject Microsoft.Update.Session
            $updateSearcher = $updateSession.CreateUpdateSearcher()
            $searchResult = $updateSearcher.Search("IsInstalled=0 AND IsHidden=0")

            # Zeige Update-Status an
            Get-WindowsUpdateStatus -outputBox $outputBox -progressBar $progressBar

            # Nur installieren wenn Updates gefunden wurden
            if ($searchResult.Updates.Count -gt 0) {
                # Automatisch Updates installieren
                Update-ProgressStatus -StatusText "Updates werden installiert..." -ProgressValue 50 -TextColor ([System.Drawing.Color]::White)
                Install-AvailableWindowsUpdates -outputBox $outputBox -progressBar $progressBar
                # Nach der Installation Status auf "Fertig" setzen
                Update-ProgressStatus -StatusText "Fertig" -ProgressValue 100 -TextColor ([System.Drawing.Color]::White)
            }
            else {
                Update-ProgressStatus -StatusText "Keine Updates verfügbar" -ProgressValue 100 -TextColor ([System.Drawing.Color]::White)
            }

            # Nach dem Scan: Nutzer fragen, ob das Windows-Update-Fenster geöffnet werden soll
            $result = [System.Windows.Forms.MessageBox]::Show(
                "Möchten Sie die Windows Update Einstellungen öffnen?",
                "Windows Update öffnen",
                [System.Windows.Forms.MessageBoxButtons]::YesNo,
                [System.Windows.Forms.MessageBoxIcon]::Question
            )
            if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
                Start-Process "ms-settings:windowsupdate"
            }
        }
        catch {
            Write-ToolLog -ToolName "WindowsUpdate" `
                -Message "Fehler beim Starten oder Installieren von Windows Update: $_" `
                -OutputBox $outputBox `
                -Color ([System.Drawing.Color]::Red)

            # Bei Fehler: ProgressBar rot einfärben
            Update-ProgressStatus -StatusText "Fehler bei Windows Update" -ProgressValue 100 -TextColor ([System.Drawing.Color]::Red)

            # Versuche zusätzliche Fehlerinformationen zu sammeln
            try {
                $wuauserv = Get-Service -Name "wuauserv"
                Write-ToolLog -ToolName "WindowsUpdate" `
                    -Message "Windows Update Dienst Status: $($wuauserv.Status)" `
                    -OutputBox $outputBox `
                    -Color ([System.Drawing.Color]::Yellow)
            }
            catch {
                Write-ToolLog -ToolName "WindowsUpdate" `
                    -Message "Konnte den Status des Windows Update Dienstes nicht abrufen: $_" `
                    -OutputBox $outputBox `
                    -Color ([System.Drawing.Color]::Red)
            }
            -Color ([System.Drawing.Color]::Red)
            Update-ProgressStatus -StatusText "Fehler" -ProgressValue 0 -TextColor ([System.Drawing.Color]::Red)
        }
    })
$global:tblSystem.Controls.Add($btnWinUpdate)


# Buttons für Festplatten-Tools - Direkt im tblDisk platziert (ohne GroupBox) - Horizontal nebeneinander
$btnCheckDISM = New-Object System.Windows.Forms.Button
$btnCheckDISM.Name = "btnCheckDISM"
$btnCheckDISM.Text = "DISM Check"
$btnCheckDISM.Size = New-Object System.Drawing.Size(155, 35)  # Breite an Unterkategorie-Buttons angepasst
$btnCheckDISM.Location = New-Object System.Drawing.Point(5, 5)  # 5px vom oberen Rand
$btnCheckDISM.BackColor = $script:btnSubNavColor
$btnCheckDISM.ForeColor = [System.Drawing.Color]::White
$btnCheckDISM.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnCheckDISM.FlatAppearance.BorderSize = 0
$btnCheckDISM.Font = New-Object System.Drawing.Font("Segoe UI", 8.5, [System.Drawing.FontStyle]::Bold)
$btnCheckDISM.Tag = "repairControl"
$btnCheckDISM.Add_Click({
        Switch-ToOutputTab
        # Status auf "DISM Check läuft..." setzen
        Update-ProgressStatus -StatusText "DISM Check initialisiert..." -ProgressValue 0 -TextColor ([System.Drawing.Color]::White)
        Start-CheckDISM -outputBox $outputBox -progressBar $progressBar
        # Nach dem Check Status auf "Fertig" setzen
        Update-ProgressStatus -StatusText "Fertig" -ProgressValue 100 -TextColor ([System.Drawing.Color]::White)
        
        # Scan-Historie aktualisieren
        Update-ScanHistory -ToolName "DISM-Check"
        # Button-Status-Indikatoren aktualisieren
        Update-AllButtonStatusIndicators
    })
$tblDisk.Controls.Add($btnCheckDISM)

$btnScanDISM = New-Object System.Windows.Forms.Button
$btnScanDISM.Name = "btnScanDISM"
$btnScanDISM.Text = "DISM Scan"
$btnScanDISM.Size = New-Object System.Drawing.Size(155, 35)  # Breite an Unterkategorie-Buttons angepasst
$btnScanDISM.Location = New-Object System.Drawing.Point(180, 5)  # 5px vom oberen Rand
$btnScanDISM.BackColor = $script:btnSubNavColor
$btnScanDISM.ForeColor = [System.Drawing.Color]::White
$btnScanDISM.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnScanDISM.FlatAppearance.BorderSize = 0
$btnScanDISM.Font = New-Object System.Drawing.Font("Segoe UI", 8.5, [System.Drawing.FontStyle]::Bold)
$btnScanDISM.Tag = "repairControl"
$btnScanDISM.Add_Click({
        Switch-ToOutputTab
        # Status auf "DISM Scan läuft..." setzen
        Update-ProgressStatus -StatusText "DISM Scan initialisiert..." -ProgressValue 0 -TextColor ([System.Drawing.Color]::White)
        Start-ScanDISM -outputBox $outputBox -progressBar $progressBar
        # Nach dem Scan Status auf "Fertig" setzen
        Update-ProgressStatus -StatusText "Fertig" -ProgressValue 100 -TextColor ([System.Drawing.Color]::White)
        
        # Scan-Historie aktualisieren
        Update-ScanHistory -ToolName "DISM-Scan"
        # Button-Status-Indikatoren aktualisieren
        Update-AllButtonStatusIndicators
    })
$tblDisk.Controls.Add($btnScanDISM)

$btnRestoreDISM = New-Object System.Windows.Forms.Button
$btnRestoreDISM.Name = "btnRestoreDISM"
$btnRestoreDISM.Text = "DISM Restore"
$btnRestoreDISM.Size = New-Object System.Drawing.Size(155, 35)  # Breite an Unterkategorie-Buttons angepasst
$btnRestoreDISM.Location = New-Object System.Drawing.Point(355, 5)  # 5px vom oberen Rand
$btnRestoreDISM.BackColor = $script:btnSubNavColor
$btnRestoreDISM.ForeColor = [System.Drawing.Color]::White
$btnRestoreDISM.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnRestoreDISM.FlatAppearance.BorderSize = 0
$btnRestoreDISM.Font = New-Object System.Drawing.Font("Segoe UI", 8.5, [System.Drawing.FontStyle]::Bold)
$btnRestoreDISM.Tag = "repairControl"
$btnRestoreDISM.Add_Click({
        Switch-ToOutputTab
        # Status auf "DISM Restore läuft..." setzen
        Update-ProgressStatus -StatusText "DISM Restore initialisiert..." -ProgressValue 0 -TextColor ([System.Drawing.Color]::White)
        Start-RestoreDISM -outputBox $outputBox -progressBar $progressBar
        # Nach dem Restore Status auf "Fertig" setzen
        Update-ProgressStatus -StatusText "Fertig" -ProgressValue 100 -TextColor ([System.Drawing.Color]::White)
        
        # Scan-Historie aktualisieren
        Update-ScanHistory -ToolName "DISM-Restore"
        # Button-Status-Indikatoren aktualisieren
        Update-AllButtonStatusIndicators
    })
$tblDisk.Controls.Add($btnRestoreDISM)

$btnCHKDSK = New-Object System.Windows.Forms.Button
$btnCHKDSK.Name = "btnCHKDSK"
$btnCHKDSK.Text = "CHKDSK"
$btnCHKDSK.Size = New-Object System.Drawing.Size(155, 35)  # Breite an Unterkategorie-Buttons angepasst
$btnCHKDSK.Location = New-Object System.Drawing.Point(180, 5)  # 5px vom oberen Rand
$btnCHKDSK.BackColor = $script:btnSubNavColor
$btnCHKDSK.ForeColor = [System.Drawing.Color]::White
$btnCHKDSK.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnCHKDSK.FlatAppearance.BorderSize = 0
$btnCHKDSK.Font = New-Object System.Drawing.Font("Segoe UI", 8.5, [System.Drawing.FontStyle]::Bold)
$btnCHKDSK.Tag = "diagnoseControl"
$btnCHKDSK.Add_Click({
        Switch-ToOutputTab
        # Status auf "Scan läuft..." setzen
        Update-ProgressStatus -StatusText "CHKDSK Laufwerksauswahl wurde geöffnet..." -ProgressValue 0 -TextColor ([System.Drawing.Color]::White)
        Start-CHKDSK -outputBox $outputBox -progressBar $progressBar -mainform $mainform
        # Nach dem Scan Status auf "Fertig" setzen
        Update-ProgressStatus -StatusText "Fertig" -ProgressValue 100 -TextColor ([System.Drawing.Color]::White)
        
        # Scan-Historie aktualisieren
        Update-ScanHistory -ToolName "CHKDSK"
        # Button-Status-Indikatoren aktualisieren
        Update-AllButtonStatusIndicators
    })
$tblDisk.Controls.Add($btnCHKDSK)

# Buttons für Netzwerk-Tools - Direkt im tblNetwork platziert (ohne GroupBox) - Horizontal nebeneinander
$btnPingTest = New-Object System.Windows.Forms.Button
$btnPingTest.Name = "btnPingTest"
$btnPingTest.Text = "Ping Test"
$btnPingTest.Size = New-Object System.Drawing.Size(155, 35)  # Breite an Unterkategorie-Buttons angepasst
$btnPingTest.Location = New-Object System.Drawing.Point(5, 5)  # 5px vom oberen Rand
$btnPingTest.BackColor = $script:btnSubNavColor
$btnPingTest.ForeColor = [System.Drawing.Color]::White
$btnPingTest.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnPingTest.FlatAppearance.BorderSize = 0
$btnPingTest.Font = New-Object System.Drawing.Font("Segoe UI", 8.5, [System.Drawing.FontStyle]::Bold)
$btnPingTest.Tag = "networkDiagnosticsControl"
$btnPingTest.Add_Click({
        Switch-ToOutputTab
        # Status auf "Ping Test läuft..." setzen
        Update-ProgressStatus -StatusText "Ping Test läuft..." -ProgressValue 0 -TextColor ([System.Drawing.Color]::White)
        Start-PingTest -outputBox $outputBox -progressBar $progressBar
        # Nach dem Test Status auf "Fertig" setzen
        Update-ProgressStatus -StatusText "Fertig" -ProgressValue 100 -TextColor ([System.Drawing.Color]::White)
    })
$tblNetwork.Controls.Add($btnPingTest)

$btnResetNetwork = New-Object System.Windows.Forms.Button
$btnResetNetwork.Name = "btnResetNetwork"
$btnResetNetwork.Text = "Netzwerk Reset"
$btnResetNetwork.Size = New-Object System.Drawing.Size(155, 35)  # Breite an Unterkategorie-Buttons angepasst
$btnResetNetwork.Location = New-Object System.Drawing.Point(5, 5)  # 5px vom oberen Rand
$btnResetNetwork.BackColor = $script:btnSubNavColor
$btnResetNetwork.ForeColor = [System.Drawing.Color]::White
$btnResetNetwork.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnResetNetwork.FlatAppearance.BorderSize = 0
$btnResetNetwork.Font = New-Object System.Drawing.Font("Segoe UI", 8.5, [System.Drawing.FontStyle]::Bold)
$btnResetNetwork.Tag = "networkRepairControl"
$btnResetNetwork.Add_Click({
        Switch-ToOutputTab
        # Status auf "Netzwerk wird zurückgesetzt..." setzen
        Update-ProgressStatus -StatusText "Netzwerk wird zurückgesetzt..." -ProgressValue 0 -TextColor ([System.Drawing.Color]::White)
        Restart-NetworkAdapter -outputBox $outputBox -progressBar $progressBar
        # Nach dem Reset Status auf "Fertig" setzen
        Update-ProgressStatus -StatusText "Fertig" -ProgressValue 100 -TextColor ([System.Drawing.Color]::White)
    })
$tblNetwork.Controls.Add($btnResetNetwork)

# Buttons für Bereinigung - Direkt im tblCleanup platziert (ohne GroupBox) - Horizontal nebeneinander
$btnDiskCleanup = New-Object System.Windows.Forms.Button
$btnDiskCleanup.Name = "btnDiskCleanup"
$btnDiskCleanup.Text = "Disk Cleanup"
$btnDiskCleanup.Size = New-Object System.Drawing.Size(155, 35)  # Breite an Unterkategorie-Buttons angepasst
$btnDiskCleanup.Location = New-Object System.Drawing.Point(5, 5)  # 5px vom oberen Rand
$btnDiskCleanup.BackColor = $script:btnSubNavColor
$btnDiskCleanup.ForeColor = [System.Drawing.Color]::White
$btnDiskCleanup.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnDiskCleanup.FlatAppearance.BorderSize = 0
$btnDiskCleanup.Font = New-Object System.Drawing.Font("Segoe UI", 8.5, [System.Drawing.FontStyle]::Bold)
$btnDiskCleanup.Tag = "cleanupSystemControl"
$btnDiskCleanup.Add_Click({
        Switch-ToOutputTab
        # Status auf "Bereinigung läuft..." setzen
        Update-ProgressStatus -StatusText "Bereinigung läuft..." -ProgressValue 0 -TextColor ([System.Drawing.Color]::White)
        Start-DiskCleanup -outputBox $outputBox -progressBar $progressBar
        # Nach der Bereinigung Status auf "Fertig" setzen
        Update-ProgressStatus -StatusText "Fertig" -ProgressValue 100 -TextColor ([System.Drawing.Color]::White)
        
        # Scan-Historie aktualisieren
        Update-ScanHistory -ToolName "DiskCleanup"
        # Button-Status-Indikatoren aktualisieren
        Update-AllButtonStatusIndicators
    })
$tblCleanup.Controls.Add($btnDiskCleanup)

$btnTempFiles = New-Object System.Windows.Forms.Button
$btnTempFiles.Name = "btnTempFiles"
$btnTempFiles.Text = "Custom-Cleanup"
$btnTempFiles.Size = New-Object System.Drawing.Size(155, 35)  # Breite an Unterkategorie-Buttons angepasst
$btnTempFiles.Location = New-Object System.Drawing.Point(180, 5)  # 5px vom oberen Rand
$btnTempFiles.BackColor = $script:btnSubNavColor
$btnTempFiles.ForeColor = [System.Drawing.Color]::White
$btnTempFiles.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnTempFiles.FlatAppearance.BorderSize = 0
$btnTempFiles.Font = New-Object System.Drawing.Font("Segoe UI", 8.5, [System.Drawing.FontStyle]::Bold)
$btnTempFiles.Tag = "cleanupSystemControl"  # Von Temp-Dateien zu System-Bereinigung verschoben
$btnTempFiles.Add_Click({
        Switch-ToOutputTab
        # Dialog entfernt, direkt erweiterte Bereinigung starten
        # Status auf "Erweiterte Bereinigung läuft..." setzen
        Update-ProgressStatus -StatusText "Erweiterte Systemreinigung wurde geöffnet..." -ProgressValue 0 -TextColor ([System.Drawing.Color]::White)
        Start-TempFilesCleanupAdvanced -outputBox $outputBox -progressBar $progressBar -mainform $mainform
        # Nach der Bereinigung Status auf "Fertig" setzen
        Update-ProgressStatus -StatusText "Fertig" -ProgressValue 100 -TextColor ([System.Drawing.Color]::White)
        
        # Scan-Historie aktualisieren
        Update-ScanHistory -ToolName "CustomCleanup"
        # Button-Status-Indikatoren aktualisieren
        Update-AllButtonStatusIndicators
    })
$tblCleanup.Controls.Add($btnTempFiles)

# ===================================================================
# SCAN-HISTORIE-FUNKTIONEN (für Status-Indikatoren)
# ===================================================================

function Update-ScanHistory {
    <#
    .SYNOPSIS
        Aktualisiert die Scan-Historie für ein Tool in der Datenbank
    .PARAMETER ToolName
        Name des Tools (z.B. "QuickMRT", "DISM-Check", etc.)
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$ToolName
    )
    
    try {
        if ($script:dbConnection -and $script:dbConnection.State -eq [System.Data.ConnectionState]::Open) {
            $cmd = $script:dbConnection.CreateCommand()
            $cmd.CommandText = "INSERT INTO DiagnosticResults (ToolName, ExecutionTime, Result, ExitCode, Details) VALUES (?, ?, ?, ?, ?)"
            $cmd.Parameters.Add((New-Object System.Data.SQLite.SQLiteParameter("", $ToolName))) | Out-Null
            $cmd.Parameters.Add((New-Object System.Data.SQLite.SQLiteParameter("", (Get-Date -Format "yyyy-MM-dd HH:mm:ss")))) | Out-Null
            $cmd.Parameters.Add((New-Object System.Data.SQLite.SQLiteParameter("", "Completed"))) | Out-Null
            $cmd.Parameters.Add((New-Object System.Data.SQLite.SQLiteParameter("", 0))) | Out-Null
            $cmd.Parameters.Add((New-Object System.Data.SQLite.SQLiteParameter("", "Tool wurde ausgeführt"))) | Out-Null
            $cmd.ExecuteNonQuery() | Out-Null
            Write-Verbose "Scan-Historie für $ToolName aktualisiert"
        }
    }
    catch {
        Write-Warning "Fehler beim Aktualisieren der Scan-Historie: $_"
    }
}

function Get-ScanHistory {
    <#
    .SYNOPSIS
        Ruft den letzten Scan-Zeitpunkt für ein Tool ab
    .PARAMETER ToolName
        Name des Tools
    .OUTPUTS
        String im Format "yyyy-MM-dd HH:mm:ss" oder $null
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$ToolName
    )
    
    try {
        if ($script:dbConnection -and $script:dbConnection.State -eq [System.Data.ConnectionState]::Open) {
            $cmd = $script:dbConnection.CreateCommand()
            $cmd.CommandText = "SELECT ExecutionTime FROM DiagnosticResults WHERE ToolName = ? ORDER BY ExecutionTime DESC LIMIT 1"
            $cmd.Parameters.Add((New-Object System.Data.SQLite.SQLiteParameter("", $ToolName))) | Out-Null
            
            $reader = $cmd.ExecuteReader()
            if ($reader.Read()) {
                $timestamp = $reader["ExecutionTime"]
                $reader.Close()
                return $timestamp
            }
            $reader.Close()
        }
        return $null
    }
    catch {
        Write-Warning "Fehler beim Abrufen der Scan-Historie: $_"
        return $null
    }
}

function Get-ScanStatus {
    <#
    .SYNOPSIS
        Ermittelt die Status-Farbe basierend auf dem letzten Scan-Zeitpunkt
    .PARAMETER ToolName
        Name des Tools
    .OUTPUTS
        System.Drawing.Color (Grün = aktuell, Orange = veraltet, Rot = nie)
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$ToolName
    )
    
    $lastScan = Get-ScanHistory -ToolName $ToolName
    
    if (-not $lastScan) {
        # Kein Scan durchgeführt = Rot
        return [System.Drawing.Color]::FromArgb(220, 50, 50)  # Rot
    }
    
    try {
        $scanDate = [DateTime]::ParseExact($lastScan, "yyyy-MM-dd HH:mm:ss", $null)
        $timeDiff = (Get-Date) - $scanDate
        
        # Farblogik basierend auf Tool-Typ
        switch -Wildcard ($ToolName) {
            # Sicherheits-Tools: 7 Tage = aktuell, 14 Tage = veraltet
            "QuickMRT" { $greenDays = 7; $orangeDays = 14 }
            "FullMRT" { $greenDays = 30; $orangeDays = 60 }
            "WindowsDefender" { $greenDays = 1; $orangeDays = 3 }
            "DefenderOfflineScan" { $greenDays = 90; $orangeDays = 180 }
            
            # System-Tools: 30 Tage = aktuell, 60 Tage = veraltet
            "SFC" { $greenDays = 30; $orangeDays = 60 }
            "MemoryDiag" { $greenDays = 90; $orangeDays = 180 }
            "WinUpdate" { $greenDays = 7; $orangeDays = 30 }
            
            # DISM-Tools: 30 Tage = aktuell, 60 Tage = veraltet
            "DISM*" { $greenDays = 30; $orangeDays = 60 }
            
            # Festplatten-Tools: 60 Tage = aktuell, 120 Tage = veraltet
            "CHKDSK" { $greenDays = 60; $orangeDays = 120 }
            
            default { $greenDays = 30; $orangeDays = 60 }
        }
        
        if ($timeDiff.TotalDays -le $greenDays) {
            # Aktuell = Grün
            return [System.Drawing.Color]::FromArgb(80, 200, 120)  # Grün
        }
        elseif ($timeDiff.TotalDays -le $orangeDays) {
            # Veraltet = Orange
            return [System.Drawing.Color]::FromArgb(255, 165, 0)  # Orange
        }
        else {
            # Sehr alt = Rot
            return [System.Drawing.Color]::FromArgb(220, 50, 50)  # Rot
        }
    }
    catch {
        Write-Warning "Fehler beim Parsen des Scan-Datums: $_"
        return [System.Drawing.Color]::FromArgb(220, 50, 50)  # Rot bei Fehler
    }
}

# Funktion zum Aktualisieren aller Button-Status-Indikatoren
function Update-AllButtonStatusIndicators {
    <#
    .SYNOPSIS
        Aktualisiert die Status-Indikatoren für alle Tool-Buttons
    .DESCRIPTION
        Diese Funktion durchläuft alle Tool-Buttons und aktualisiert deren Status-Indikatoren
        basierend auf dem letzten Scan-Zeitpunkt aus der Datenbank.
    #>
    
    # Liste aller Buttons mit ihren zugehörigen Tool-Namen
    $buttonToolMapping = @{
        $btnQuickMRT = "QuickMRT"
        $btnFullMRT = "FullMRT"
        $btnWindowsDefender = "WindowsDefender"
        $btnDefenderOffline = "DefenderOfflineScan"
        $btnSFC = "SFC"
        $btnMemoryDiag = "MemoryDiag"
        $btnWinUpdate = "WinUpdate"
        $btnCheckDISM = "DISM-Check"
        $btnScanDISM = "DISM-Scan"
        $btnRestoreDISM = "DISM-Restore"
        $btnCHKDSK = "CHKDSK"
        $btnDiskCleanup = "DiskCleanup"
        $btnTempFiles = "CustomCleanup"
    }
    
    foreach ($button in $buttonToolMapping.Keys) {
        $toolName = $buttonToolMapping[$button]
        
        # Entferne vorhandenen Indikator, falls vorhanden
        $existingIndicator = $button.Controls | Where-Object { $_.Name -eq "StatusIndicator" }
        if ($existingIndicator) {
            $button.Controls.Remove($existingIndicator)
            $existingIndicator.Dispose()
        }
        
        # Status-Farbe ermitteln
        $statusColor = [System.Drawing.Color]::Gray
        try {
            $statusColor = Get-ScanStatus -ToolName $toolName
        }
        catch {
            Write-Verbose "Fehler beim Ermitteln des Status für $toolName"
        }
        
        # Status-Indikator erstellen (kleiner Kreis)
        $indicator = New-Object System.Windows.Forms.Panel
        $indicator.Name = "StatusIndicator"
        $indicator.Size = New-Object System.Drawing.Size(10, 10)
        $indicator.Location = New-Object System.Drawing.Point(5, 5) # oben links
        $indicator.BackColor = $statusColor
        $indicator.BorderStyle = [System.Windows.Forms.BorderStyle]::None
        
        # Runden Kreis durch Paint-Event erzeugen
        $indicator.Add_Paint({
                $graphics = $_.Graphics
                $rect = New-Object System.Drawing.Rectangle(0, 0, $this.Width, $this.Height)
                $path = New-Object System.Drawing.Drawing2D.GraphicsPath
                $path.AddEllipse($rect)
                $this.Region = New-Object System.Drawing.Region($path)
                
                # Verwende die Graphics-Variable, damit sie nicht als unbenutzt gemeldet wird
                if ($false) { $graphics.Clear() }
            })
        
        # Tooltip für den Status-Indikator
        if ($script:globalTooltip) {
            $lastScan = Get-ScanHistory -ToolName $toolName
            
            if ($lastScan) {
                $scanDate = [DateTime]::ParseExact($lastScan, "yyyy-MM-dd HH:mm:ss", $null)
                $timeDiff = (Get-Date) - $scanDate
                
                # Formatiere die Zeitdifferenz für den Tooltip
                $tooltipText = "Letzter Scan: " + $scanDate.ToString("dd.MM.yyyy HH:mm:ss") + "`n(vor "
                
                if ($timeDiff.TotalDays -ge 1) {
                    $tooltipText += [Math]::Floor($timeDiff.TotalDays).ToString() + " Tag(en)"
                }
                elseif ($timeDiff.TotalHours -ge 1) {
                    $tooltipText += [Math]::Floor($timeDiff.TotalHours).ToString() + " Stunde(n)"
                }
                else {
                    $tooltipText += [Math]::Floor($timeDiff.TotalMinutes).ToString() + " Minute(n)"
                }
                
                $tooltipText += ")"
            }
            else {
                $tooltipText = "Kein Scan durchgeführt"
            }
            
            $script:globalTooltip.SetToolTip($indicator, $tooltipText)
        }
        
        # Status-Indikator zum Button hinzufügen
        $button.Controls.Add($indicator)
        $indicator.BringToFront()
    }
}

# ===================================================================
# NEUSTART-BUTTON MIT DROPDOWN-MENÜ (Windows 11 Stil)
# ===================================================================

# Custom ColorTable für modernes Aussehen (erst definieren, dann verwenden)
if (-not ([System.Management.Automation.PSTypeName]'CustomColorTable').Type) {
    Add-Type -TypeDefinition @"
using System.Windows.Forms;
using System.Drawing;

public class CustomColorTable : ProfessionalColorTable
{
    public override Color MenuItemSelected
    {
        get { return Color.FromArgb(60, 60, 60); }
    }
    
    public override Color MenuItemSelectedGradientBegin
    {
        get { return Color.FromArgb(60, 60, 60); }
    }
    
    public override Color MenuItemSelectedGradientEnd
    {
        get { return Color.FromArgb(60, 60, 60); }
    }
    
    public override Color MenuItemBorder
    {
        get { return Color.FromArgb(70, 70, 70); }
    }
    
    public override Color MenuItemPressedGradientBegin
    {
        get { return Color.FromArgb(50, 50, 50); }
    }
    
    public override Color MenuItemPressedGradientEnd
    {
        get { return Color.FromArgb(50, 50, 50); }
    }
    
    public override Color ImageMarginGradientBegin
    {
        get { return Color.FromArgb(40, 40, 40); }
    }
    
    public override Color ImageMarginGradientMiddle
    {
        get { return Color.FromArgb(40, 40, 40); }
    }
    
    public override Color ImageMarginGradientEnd
    {
        get { return Color.FromArgb(40, 40, 40); }
    }
}
"@ -ReferencedAssemblies System.Windows.Forms, System.Drawing -ErrorAction SilentlyContinue
}

# Dropdown-Menü (ContextMenuStrip) für Neustart-Optionen erstellen
$restartContextMenu = New-Object System.Windows.Forms.ContextMenuStrip
$restartContextMenu.BackColor = [System.Drawing.Color]::FromArgb(40, 40, 40)
$restartContextMenu.ForeColor = [System.Drawing.Color]::White
$restartContextMenu.ShowImageMargin = $true
$restartContextMenu.Renderer = New-Object System.Windows.Forms.ToolStripProfessionalRenderer((New-Object CustomColorTable))

# Menu-Item 1: GUI neuladen
$menuItemGUIReload = New-Object System.Windows.Forms.ToolStripMenuItem
$menuItemGUIReload.Text = "GUI neuladen"
$menuItemGUIReload.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$menuItemGUIReload.ForeColor = [System.Drawing.Color]::White
$menuItemGUIReload.BackColor = [System.Drawing.Color]::FromArgb(40, 40, 40)
# menuItemGUIReload.Padding = New-Object System.Windows.Forms.Padding(5, 3, 5, 3)
$menuItemGUIReload.AutoSize = $false
$menuItemGUIReload.Size = New-Object System.Drawing.Size(140, 28)
$menuItemGUIReload.Add_Click({
        # GUI-Reload
        $confirmReload = [System.Windows.Forms.MessageBox]::Show(
            "Die GUI wird neugeladen.`n`nAlle aktuellen Vorgänge werden abgebrochen.`n`nMöchten Sie fortfahren?",
            "GUI neuladen",
            [System.Windows.Forms.MessageBoxButtons]::YesNo,
            [System.Windows.Forms.MessageBoxIcon]::Question
        )

        if ($confirmReload -eq [System.Windows.Forms.DialogResult]::Yes) {
            Update-LogFile -Message "GUI-Reload wurde vom Benutzer initiiert"
            Reload-GUI -Form $mainform
        }
    })

# Trennlinie
$separator = New-Object System.Windows.Forms.ToolStripSeparator
$separator.BackColor = [System.Drawing.Color]::FromArgb(60, 60, 60)

# Menu-Item 2: System neustarten
$menuItemSystemRestart = New-Object System.Windows.Forms.ToolStripMenuItem
$menuItemSystemRestart.Text = "System neustarten"
$menuItemSystemRestart.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$menuItemSystemRestart.ForeColor = [System.Drawing.Color]::FromArgb(255, 100, 100)
$menuItemSystemRestart.BackColor = [System.Drawing.Color]::FromArgb(40, 40, 40)
# $menuItemSystemRestart.Padding = New-Object System.Windows.Forms.Padding(5, 3, 5, 3)
$menuItemSystemRestart.AutoSize = $false
$menuItemSystemRestart.Size = New-Object System.Drawing.Size(140, 28)
$menuItemSystemRestart.Add_Click({
        # System-Neustart
        $result = [System.Windows.Forms.MessageBox]::Show(
            "WARNUNG: Der Computer wird neu gestartet.`n`nBitte speichern Sie alle offenen Dokumente und schließen Sie alle Programme.`n`nMöchten Sie den Neustart jetzt durchführen?",
            "System Neustart",
            [System.Windows.Forms.MessageBoxButtons]::YesNo,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        )

            if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
                # Timer für den Countdown erstellen
                $script:countdownSeconds = 30
                $script:countdownTimer = New-Object System.Windows.Forms.Timer
                $script:countdownTimer.Interval = 1000 # 1 Sekunde

                # Progressbar für Countdown vorbereiten
                $progressBar.Maximum = $script:countdownSeconds
                $progressBar.Value = $script:countdownSeconds

                # Status-Text aktualisieren
                Update-ProgressStatus -StatusText "System Neustart in $script:countdownSeconds Sekunden..." -ProgressValue $script:countdownSeconds -TextColor ([System.Drawing.Color]::Red)

                # Timer-Event definieren
                $script:countdownTimer.Add_Tick({
                        $script:countdownSeconds--
                        $progressBar.Value = $script:countdownSeconds

                        if ($script:countdownSeconds -gt 0) {
                            Update-ProgressStatus -StatusText "System Neustart in $script:countdownSeconds Sekunden..." -ProgressValue $script:countdownSeconds -TextColor ([System.Drawing.Color]::Red)

                            # Warnung bei 10 Sekunden
                            if ($script:countdownSeconds -eq 10) {
                                $result = [System.Windows.Forms.MessageBox]::Show(
                                    "WARNUNG: Der Computer wird in 10 Sekunden neu gestartet!`n`nSpeichern Sie alle Arbeiten!`n`nMöchten Sie den Neustart abbrechen?",
                                    "Letzte Warnung",
                                    [System.Windows.Forms.MessageBoxButtons]::YesNo,
                                    [System.Windows.Forms.MessageBoxIcon]::Warning
                                )

                                if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
                                    # Neustart abbrechen
                                    $script:countdownTimer.Stop()
                                    $script:countdownTimer.Dispose()

                                    # Progressbar zurücksetzen
                                    $progressBar.Value = 0
                                    Update-ProgressStatus -StatusText "Neustart abgebrochen" -ProgressValue 0 -TextColor ([System.Drawing.Color]::DarkBlue)

                                    # Bestätigungsmeldung
                                    [System.Windows.Forms.MessageBox]::Show(
                                        "Der System-Neustart wurde abgebrochen.",
                                        "Neustart abgebrochen",
                                        [System.Windows.Forms.MessageBoxButtons]::OK,
                                        [System.Windows.Forms.MessageBoxIcon]::Information
                                    )
                                }
                            }
                        }
                        else {
                            $script:countdownTimer.Stop()
                            $script:countdownTimer.Dispose()

                            # Neustart-Befehl ausführen
                            try {
                                # Versuche zuerst einen sanften Neustart
                                Restart-Computer -Force
                            }
                            catch {
                                # Fallback: Wenn der sanfte Neustart fehlschlägt
                                try {
                                    Start-Process "shutdown.exe" -ArgumentList "/r /t 0" -Verb RunAs
                                }
                                catch {
                                    [System.Windows.Forms.MessageBox]::Show(
                                        "Fehler beim Neustart: $_",
                                        "Fehler",
                                        [System.Windows.Forms.MessageBoxButtons]::OK,
                                        [System.Windows.Forms.MessageBoxIcon]::Error
                                    )
                                }
                            }
                        }
                    })

                # Timer starten
                $script:countdownTimer.Start()
            }
    })

# Menu-Items zum Context-Menu hinzufügen
$restartContextMenu.Items.Add($menuItemGUIReload) | Out-Null
$restartContextMenu.Items.Add($separator) | Out-Null
$restartContextMenu.Items.Add($menuItemSystemRestart) | Out-Null

# Neustart-Button erstellen mit Dropdown-Pfeil
$btnRestart = New-Object System.Windows.Forms.Button
$btnRestart.Text = "Neustart  ▼"
$btnRestart.Location = New-Object System.Drawing.Point(30, 940)
$btnRestart.Size = New-Object System.Drawing.Size(140, 30)
$btnRestart.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 215)
$btnRestart.ForeColor = [System.Drawing.Color]::White
$btnRestart.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnRestart.FlatAppearance.BorderSize = 0
$btnRestart.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)

# Click-Event: Dropdown-Menü anzeigen
$btnRestart.Add_Click({
        # Menü unterhalb des Buttons anzeigen
        $menuLocation = $btnRestart.PointToScreen([System.Drawing.Point]::new(0, $btnRestart.Height))
        $restartContextMenu.Show($menuLocation)
    })

# ENTFERNT: Alter Button wird durch Collapsible Panel ersetzt
# $mainform.Controls.Add($btnRestart)

function Invoke-GuiReleaseAction {
    try {
        if (-not (Get-Command -Name Invoke-ReleaseSelectionUpdate -ErrorAction SilentlyContinue)) {
            return @{ Success = $false; Cancelled = $false; Message = "Release-Auswahlfunktion nicht verfügbar" }
        }

        return Invoke-ReleaseSelectionUpdate `
            -CurrentVersion $script:AppVersion `
            -OutputBox $outputBox `
            -ProgressBar $progressBar `
            -MainForm $mainform `
            -ApplicationPath $PSScriptRoot
    }
    catch {
        return @{ Success = $false; Cancelled = $false; Message = $_.Exception.Message }
    }
}

function Invoke-WingetVersionAction {
    param(
        [Parameter(Mandatory = $true)]
        [string]$WingetId,
        
        [Parameter(Mandatory = $true)]
        [string]$CurrentVersion,
        
        [Parameter(Mandatory = $false)]
        [scriptblock]$ProgressCallback,
        
        [Parameter(Mandatory = $false)]
        [scriptblock]$LogCallback
    )
    
    try {
        if (-not (Get-Command -Name Show-WingetVersionSelectionDialog -ErrorAction SilentlyContinue)) {
            return @{ Success = $false; Cancelled = $false; Message = "Winget-Versionsauswahl nicht verfügbar" }
        }

        if ($ProgressCallback) {
            & $ProgressCallback 10 "Lade verfügbare Versionen..."
        }

        # Versionsauswahldialog anzeigen
        $selectedVersion = Show-WingetVersionSelectionDialog -WingetId $WingetId -CurrentVersion $CurrentVersion
        
        if (-not $selectedVersion) {
            return @{ Success = $false; Cancelled = $true; Message = "Abgebrochen" }
        }

        if ($ProgressCallback) {
            & $ProgressCallback 20 "Version $($selectedVersion.tag_name) wird installiert..."
        }

        # Installation durchführen
        $installResult = Invoke-WingetVersionInstall `
            -WingetId $WingetId `
            -Version $selectedVersion.tag_name `
            -ProgressCallback $ProgressCallback `
            -LogCallback $LogCallback

        return $installResult
    }
    catch {
        return @{ Success = $false; Cancelled = $false; Message = $_.Exception.Message }
    }
}

# Tooltip-Texte zu den Funktionsbuttons hinzufügen (tooltipObj wurde bereits weiter oben initialisiert)
$tooltipObj.SetToolTip($btnQuickMRT, "Führt einen schnellen Malware-Scan mit Microsoft Malicious Software Removal Tool durch")
$tooltipObj.SetToolTip($btnFullMRT, "Führt einen vollständigen Systemscan mit Microsoft Malicious Software Removal Tool durch")
$tooltipObj.SetToolTip($btnWindowsDefender, "Öffnet Windows Defender und zeigt den aktuellen Status an")
$tooltipObj.SetToolTip($btnDefenderOffline, "Startet einen Windows Defender Offline-Scan, der beim nächsten Neustart ausgeführt wird")
$tooltipObj.SetToolTip($btnSFC, "Überprüft und repariert Windows-Systemdateien mit dem System File Checker")
$tooltipObj.SetToolTip($btnMemoryDiag, "Startet das Windows-Memory-Diagnostic-Tool zur Überprüfung des Arbeitsspeichers")
$tooltipObj.SetToolTip($btnWinUpdate, "Öffnet die Windows Update-Einstellungen")

$tooltipObj.SetToolTip($btnCheckDISM, "Überprüft den Zustand des Windows-Images mit dem DISM-Tool")
$tooltipObj.SetToolTip($btnScanDISM, "Führt einen detaillierten Scan des Windows-Images durch")
$tooltipObj.SetToolTip($btnRestoreDISM, "Versucht, ein beschädigtes Windows-Image automatisch zu reparieren")
$tooltipObj.SetToolTip($btnCHKDSK, "Überprüft Festplatten auf Dateisystemfehler und defekte Sektoren")

$tooltipObj.SetToolTip($btnPingTest, "Testet die Netzwerkverbindung zu einem Server oder einer IP-Adresse")
$tooltipObj.SetToolTip($btnResetNetwork, "Setzt Netzwerkadapter und TCP/IP-Stack zurück, um Verbindungsprobleme zu beheben")

$tooltipObj.SetToolTip($btnDiskCleanup, "Startet den Windows Disk Cleanup-Tool zum Freigeben von Speicherplatz")
$tooltipObj.SetToolTip($btnTempFiles, "Bereinigt temporäre Dateien, um Speicherplatz freizugeben")
$tooltipObj.SetToolTip($btnRestart, "Neustart-Optionen: GUI neuladen oder System neustarten")
$tooltipObj.SetToolTip($infoButton, "Zeigt Informationen über die Anwendung an")

# Status-Informationen anzeigen
$statusBar = New-Object System.Windows.Forms.StatusStrip
$statusBar.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)  # Dunkles Grau für Statusleiste
$statusLabel = New-Object System.Windows.Forms.ToolStripStatusLabel
$statusLabel.Text = "Status: Bereit | " + (Get-Date -Format "dd.MM.yyyy HH:mm")
$statusLabel.ForeColor = [System.Drawing.Color]::FromArgb(220, 220, 220)  # Helles Grau für Text

# Admin-Indikator
$adminLabel = New-Object System.Windows.Forms.ToolStripStatusLabel
$adminLabel.Alignment = [System.Windows.Forms.ToolStripItemAlignment]::Right
if (Test-Admin) {
    $adminLabel.Text = "Administrator: Ja"
    $adminLabel.ForeColor = [System.Drawing.Color]::LimeGreen  # Helles Grün bleibt gut sichtbar
}
else {
    $adminLabel.Text = "Administrator: Nein"
    $adminLabel.ForeColor = [System.Drawing.Color]::Tomato  # Helles Rot bleibt gut sichtbar
}

$statusBar.Items.Add($statusLabel)
$statusBar.Items.Add($adminLabel)
$mainform.Controls.Add($statusBar)

# Timer für Statusleiste aktualisieren
$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 60000 # 60 Sekunden
$timer.Add_Tick({
        $statusLabel.Text = "Status: Bereit | " + (Get-Date -Format "dd.MM.yyyy HH:mm")
    })
$timer.Start()

$toolInfoBox.Text = "Tool-Informationen werden geladen...`r`n"
$toolInfoBox.Dock = [System.Windows.Forms.DockStyle]::Fill

# Funktion zum Abrufen der Tool-Informationen
function Get-ToolInfo {
    param (
        [System.Windows.Forms.RichTextBox]$infoBox
    )

    $infoBox.Clear()
    Set-OutputSelectionStyle -OutputBox $infoBox -Style 'Info'
    $infoBox.AppendText("===== TOOL-INFORMATIONEN =====`r`n`r`n")

    # Progressbar zurücksetzen
    $progressBar.Value = 0
    $progressBar.CustomText = "Tool-Info wird geladen..."
    $progressBar.TextColor = [System.Drawing.Color]::White

    # System-Tools Informationen - 20%
    $progressBar.Value = 20
    $progressBar.CustomText = "Lade System-Tools Info..."
    $progressBar.TextColor = [System.Drawing.Color]::White

    Set-OutputSelectionStyle -OutputBox $infoBox -Style 'Info'
    $infoBox.AppendText("SYSTEM-TOOLS:`r`n")
    Set-OutputSelectionStyle -OutputBox $infoBox -Style 'Default'
    $infoBox.AppendText("Diese Tools helfen bei der Diagnose und Wartung des Windows-Betriebssystems.`r`n")
    Set-OutputSelectionStyle -OutputBox $infoBox -Style 'Default'
    $infoBox.AppendText("- SFC Check: Überprüft und repariert fehlerhafte oder fehlende Windows-Systemdateien.`r`n")
    Set-OutputSelectionStyle -OutputBox $infoBox -Style 'Default'
    $infoBox.AppendText("- Windows Update: Öffnet die Windows Update-Einstellungen.`r`n")
    Set-OutputSelectionStyle -OutputBox $infoBox -Style 'Default'
    $infoBox.AppendText("- Memory Diagnostic: Führt einen Arbeitsspeicher-Test durch.`r`n")
    Set-OutputSelectionStyle -OutputBox $infoBox -Style 'Default'
    $infoBox.AppendText("- System Scan: Systemscan auf Malware und Viren.`r`n")
    Set-OutputSelectionStyle -OutputBox $infoBox -Style 'Default'
    $infoBox.AppendText("`r`n")

    # Disk-Tools Informationen - 40%
    $progressBar.Value = 40
    $progressBar.CustomText = "Lade Disk-Tools Info..."
    $progressBar.TextColor = [System.Drawing.Color]::White

    Set-OutputSelectionStyle -OutputBox $infoBox -Style 'Info'
    $infoBox.AppendText("FESTPLATTEN-TOOLS:`r`n")
    Set-OutputSelectionStyle -OutputBox $infoBox -Style 'Default'
    $infoBox.AppendText("Tools zur Überprüfung und Reparatur von Festplatten und Dateisystemen.`r`n")
    Set-OutputSelectionStyle -OutputBox $infoBox -Style 'Default'
    $infoBox.AppendText("- DISM Check Health: Überprüft den Zustand des Windows-Images.`r`n")
    Set-OutputSelectionStyle -OutputBox $infoBox -Style 'Default'
    $infoBox.AppendText("- DISM Scan Health: Scannt das Windows-Image auf Beschädigungen.`r`n")
    Set-OutputSelectionStyle -OutputBox $infoBox -Style 'Default'
    $infoBox.AppendText("- DISM Restore Health: Repariert das Windows-Image.`r`n")
    Set-OutputSelectionStyle -OutputBox $infoBox -Style 'Default'
    $infoBox.AppendText("- CHKDSK: Überprüft und repariert Festplattenfehler.`r`n")
    Set-OutputSelectionStyle -OutputBox $infoBox -Style 'Default'
    $infoBox.AppendText("- Drive Cleanup: Bereinigt temporäre und überflüssige Dateien.`r`n")
    Set-OutputSelectionStyle -OutputBox $infoBox -Style 'Default'
    $infoBox.AppendText("`r`n")

    # Network-Tools Informationen - 60%
    $progressBar.Value = 60
    $progressBar.CustomText = "Lade Network-Tools Info..."
    $progressBar.TextColor = [System.Drawing.Color]::White

    Set-OutputSelectionStyle -OutputBox $infoBox -Style 'Info'
    $infoBox.AppendText("NETWORK-TOOLS:`r`n")
    Set-OutputSelectionStyle -OutputBox $infoBox -Style 'Default'
    $infoBox.AppendText("* Network Reset`r`n")
    Set-OutputSelectionStyle -OutputBox $infoBox -Style 'Default'
    $infoBox.AppendText("  - Setzt Netzwerkadapter zurueck`r`n")
    Set-OutputSelectionStyle -OutputBox $infoBox -Style 'Default'
    $infoBox.AppendText("  - Erneuert IP-Konfiguration`r`n")
    Set-OutputSelectionStyle -OutputBox $infoBox -Style 'Default'
    $infoBox.AppendText("  - Leert DNS-Cache`r`n`r`n")

    # Cleanup-Tools Informationen - 80%
    $progressBar.Value = 80
    $progressBar.CustomText = "Lade Cleanup-Tools Info..."
    $progressBar.TextColor = [System.Drawing.Color]::White

    Set-OutputSelectionStyle -OutputBox $infoBox -Style 'Info'
    $infoBox.AppendText("CLEANUP-TOOLS:`r`n")
    Set-OutputSelectionStyle -OutputBox $infoBox -Style 'Default'
    $infoBox.AppendText("* Browser Cache`r`n")
    Set-OutputSelectionStyle -OutputBox $infoBox -Style 'Default'
    $infoBox.AppendText("  - Leert Browser-Caches (Chrome, Firefox, Edge)`r`n")
    Set-OutputSelectionStyle -OutputBox $infoBox -Style 'Default'
    $infoBox.AppendText("  - Entfernt temporaere Internetdateien`r`n")
    Set-OutputSelectionStyle -OutputBox $infoBox -Style 'Default'
    $infoBox.AppendText("* Windows Cache`r`n")
    Set-OutputSelectionStyle -OutputBox $infoBox -Style 'Default'
    $infoBox.AppendText("  - Bereinigt Windows-Thumbnail-Cache`r`n")
    Set-OutputSelectionStyle -OutputBox $infoBox -Style 'Default'
    $infoBox.AppendText("  - Entfernt temporaere Windows-Dateien`r`n`r`n")

    # Allgemeine Informationen - 90%
    $progressBar.Value = 90
    $progressBar.CustomText = "Lade allgemeine Informationen..."
    $progressBar.TextColor = [System.Drawing.Color]::White

    Set-OutputSelectionStyle -OutputBox $infoBox -Style 'Info'
    $infoBox.AppendText("ALLGEMEINE INFORMATIONEN:`r`n")
    Set-OutputSelectionStyle -OutputBox $infoBox -Style 'Default'
    $infoBox.AppendText("* Version: $script:AppVersion`r`n")
    Set-OutputSelectionStyle -OutputBox $infoBox -Style 'Default'
    $infoBox.AppendText("* Entwickler: $script:AppPublisher`r`n")
    Set-OutputSelectionStyle -OutputBox $infoBox -Style 'Default'
    $infoBox.AppendText("* Letzte Aktualisierung: $script:VersionDate`r`n")

    # Fertig - 100%
    $progressBar.Value = 100
    $progressBar.CustomText = "Tool-Info geladen"
    $progressBar.TextColor = [System.Drawing.Color]::LimeGreen

    # Nach kurzer Pause zurücksetzen
    Start-Sleep -Milliseconds 1000
    $progressBar.Value = 0
    $progressBar.CustomText = "Bereit"
    $progressBar.TextColor = [System.Drawing.Color]::White
}

# Tool-Info-Box dem toolInfoViewPanel hinzufügen
$toolInfoViewPanel.Controls.Add($toolInfoBox)

# Container für WPF-Elemente (CategoryPanel wurde entfernt, da Kategorien jetzt im Dropdown-Menü sind)
$toolDownloadsHost = New-Object System.Windows.Forms.Integration.ElementHost
$toolDownloadsHost.Dock = [System.Windows.Forms.DockStyle]::Fill
$toolDownloadsHost.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
$downloadsViewPanel.Controls.Add($toolDownloadsHost)

# Moderner Scrollbar-Style für den ScrollViewer
$scrollViewerXaml = @"
<ScrollViewer xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
              xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
              VerticalScrollBarVisibility="Auto"
              HorizontalScrollBarVisibility="Disabled"
              Background="#1E1E1E">
    <ScrollViewer.Resources>
        <Style TargetType="{x:Type ScrollBar}">
            <Setter Property="Background" Value="#1E1E1E"/>
            <Setter Property="BorderBrush" Value="Transparent"/>
            <Setter Property="Width" Value="12"/>
            <Setter Property="MinWidth" Value="12"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="{x:Type ScrollBar}">
                        <Grid Background="{TemplateBinding Background}">
                            <Track x:Name="PART_Track" IsDirectionReversed="True" Margin="2,0,2,0">
                                <Track.Thumb>
                                    <Thumb>
                                        <Thumb.Style>
                                            <Style TargetType="{x:Type Thumb}">
                                                <Setter Property="Background" Value="#3F3F46"/>
                                                <Setter Property="BorderBrush" Value="Transparent"/>
                                                <Setter Property="Template">
                                                    <Setter.Value>
                                                        <ControlTemplate TargetType="{x:Type Thumb}">
                                                            <Border Background="{TemplateBinding Background}"
                                                                    BorderBrush="{TemplateBinding BorderBrush}"
                                                                    BorderThickness="0"
                                                                    CornerRadius="4"/>
                                                            <ControlTemplate.Triggers>
                                                                <Trigger Property="IsMouseOver" Value="True">
                                                                    <Setter Property="Background" Value="#52525B"/>
                                                                </Trigger>
                                                                <Trigger Property="IsDragging" Value="True">
                                                                    <Setter Property="Background" Value="#0078D4"/>
                                                                </Trigger>
                                                            </ControlTemplate.Triggers>
                                                        </ControlTemplate>
                                                    </Setter.Value>
                                                </Setter>
                                            </Style>
                                        </Thumb.Style>
                                    </Thumb>
                                </Track.Thumb>
                            </Track>
                        </Grid>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
    </ScrollViewer.Resources>
</ScrollViewer>
"@

# Scrollviewer mit modernem Style aus XAML erstellen
try {
    $toolScrollViewer = [Windows.Markup.XamlReader]::Parse($scrollViewerXaml)
}
catch {
    Write-Warning "Konnte modernen ScrollViewer nicht aus XAML laden: $_"
    # Fallback auf Standard-ScrollViewer
    $toolScrollViewer = New-Object Windows.Controls.ScrollViewer
    $toolScrollViewer.VerticalScrollBarVisibility = [Windows.Controls.ScrollBarVisibility]::Auto
    $toolScrollViewer.HorizontalScrollBarVisibility = [Windows.Controls.ScrollBarVisibility]::Disabled
    $toolScrollViewer.Background = [Windows.Media.SolidColorBrush]::new([Windows.Media.Color]::FromRgb(30, 30, 30))
}

# WrapPanel für die Tool-Kacheln
$toolWrapPanel = New-Object Windows.Controls.WrapPanel
$toolWrapPanel.Margin = New-Object Windows.Thickness(10, 15, 10, 10)  # Links: 10, Oben: 15px mehr Abstand, Rechts: 10, Unten: 10
$toolWrapPanel.Background = [Windows.Media.SolidColorBrush]::new([Windows.Media.Color]::FromRgb(30, 30, 30))
$toolScrollViewer.Content = $toolWrapPanel
$toolDownloadsHost.Child = $toolScrollViewer



# Variable zur Verfolgung, ob Tools bereits geladen wurden
$script:toolsAlreadyLoaded = $false

# Hauptformular anzeigen
$mainform.Add_Shown({
        # ═══════════════════════════════════════════════════════════
        # INITIALISIERUNG MIT FORTSCHRITTSANZEIGE
        # ═══════════════════════════════════════════════════════════
        
        # Hilfsfunktion für ProgressBar-Updates
        function Update-InitProgress {
            param([int]$Value, [string]$Text)
            if ($progressBar) {
                $progressBar.Value = $Value
                $progressBar.CustomText = $Text
                $progressBar.TextColor = [System.Drawing.Color]::White
                [System.Windows.Forms.Application]::DoEvents()
            }
        }
        
        # Start der Initialisierung
        Update-InitProgress -Value 0 -Text "Starte Initialisierung..."
        
        # 1. Einstellungen laden (5%)
        Update-InitProgress -Value 5 -Text "Lade Einstellungen..."
        $null = Update-Settings
        
        # 2. Log-Verzeichnis initialisieren (10%)
        Update-InitProgress -Value 10 -Text "Initialisiere Log-System..."
        if (Get-Command -Name Initialize-LogDirectory -ErrorAction SilentlyContinue) {
            Initialize-LogDirectory
        }
        
        # 3. Datenbank initialisieren (15%)
        Update-InitProgress -Value 15 -Text "Initialisiere Datenbank..."
        try {
            if (-not $script:dbConnection) {
                $dbInitialized = Initialize-SystemDatabase
                if ($dbInitialized) {
                    Write-Verbose "✓ Datenbank erfolgreich initialisiert"
                }
            }
        }
        catch {
            Write-Verbose "⚠ Datenbank-Initialisierung übersprungen: $_"
        }

        # ═══════════════════════════════════════════════════════════
        # HARDWARE-MONITORING INITIALISIERUNG (ASYNCHRON)
        # ═══════════════════════════════════════════════════════════
        
        Update-InitProgress -Value 20 -Text "Starte Hardware-Monitor..."
        
        # Hardware-Monitor wird ASYNCHRON im Hintergrund initialisiert
        # Dies verhindert GUI-Freeze während der Hardware-Initialisierung (kann 5-15 Sekunden dauern)
        Update-InitProgress -Value 70 -Text "Hardware-Monitor wird im Hintergrund geladen..."
        
        # Timer erstellen der die Hardware-Initialisierung NACH Form.Shown startet
        $hwInitTimer = New-Object System.Windows.Forms.Timer
        $hwInitTimer.Interval = 500  # 500ms nach Shown-Event
        $hwInitTimer.Add_Tick({
            $this.Stop()
            $this.Dispose()
            
            # Starte Hardware-Initialisierung (läuft im UI-Thread, aber nach Form ist sichtbar)
            $progressBar.CustomText = "Initialisiere Hardware-Monitor..."
            $progressBar.Value = 20
            [System.Windows.Forms.Application]::DoEvents()
            
            try {
                # Prüfe Hardware-Monitoring-Verfügbarkeit (lokale DLL + PawnIO-Treiber)
                $hwMonitorStatus = Initialize-HardwareMonitoringMode -ProgressBar $progressBar -StatusLabel $null
                
                if ($hwMonitorStatus.Available) {
                    # Hardware-Monitoring verfügbar - initialisiere Timer
                    $hardwareResult = Initialize-HardwareMonitoring `
                        -cpuLabel $cpuLabel `
                        -gpuLabel $gpuLabel `
                        -ramLabel $ramLabel `
                        -gbCPU $gbCPU `
                        -gbGPU $gbGPU `
                        -gbRAM $gbRAM `
                        -SuppressVisualFeedback `
                        -GlobalTooltip $tooltipObj
                    
                    if ($hardwareResult) {
                        # Schwellenwerte aus Einstellungen laden
                        $currentSettings = Get-SystemToolSettings
                        if ($currentSettings) {
                            try {
                                $params = @{}
                                if ($currentSettings.CpuThreshold) { $params['CpuThreshold'] = [int]$currentSettings.CpuThreshold }
                                if ($currentSettings.RamThreshold) { $params['RamThreshold'] = [int]$currentSettings.RamThreshold }
                                if ($currentSettings.GpuThreshold) { $params['GpuThreshold'] = [int]$currentSettings.GpuThreshold }
                                if ($params.Count -gt 0) {
                                    Set-HardwareThresholds @params
                                }
                            }
                            catch {
                                Write-Verbose "Hardware-Schwellenwerte konnten nicht gesetzt werden: $_"
                            }
                        }
                        
                        $script:HardwareMonitoringReady = $true
                        
                        # Kurz warten auf erste Daten (maximal 2 Sekunden)
                        $startWait = Get-Date
                        $dataReady = $false
                        $maxWaitSeconds = 2
                        
                        while (-not $dataReady -and ((Get-Date) - $startWait).TotalSeconds -lt $maxWaitSeconds) {
                            [System.Windows.Forms.Application]::DoEvents()
                            Start-Sleep -Milliseconds 100
                            
                            $cpuReady = $cpuLabel -and $cpuLabel.Text -and $cpuLabel.Text -notmatch "werden geladen" -and $cpuLabel.Text.Length -gt 15 -and $cpuLabel.Text -match "\d"
                            $gpuReady = $gpuLabel -and $gpuLabel.Text -and $gpuLabel.Text -notmatch "werden geladen" -and $gpuLabel.Text.Length -gt 15
                            $ramReady = $ramLabel -and $ramLabel.Text -and $ramLabel.Text -notmatch "werden geladen" -and $ramLabel.Text.Length -gt 15 -and $ramLabel.Text -match "\d"
                            
                            if ($cpuReady -and ($gpuReady -or $ramReady)) {
                                $dataReady = $true
                            }
                        }
                        
                        # Aktualisiere OutputBox mit Erfolg
                        $outputBox.SelectionStart = $outputBox.TextLength
                        Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Success'
                        Add-OutputIcon -OutputBox $outputBox -IconCode 0xE73E
                        $outputBox.AppendText(" Hardware-Monitoring aktiv`r`n")
                        $outputBox.ScrollToCaret()
                    }
                    else {
                        $script:HardwareMonitoringReady = $false
                        $outputBox.SelectionStart = $outputBox.TextLength
                        Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Warning'
                        $outputBox.AppendText("[!] Hardware-Monitoring konnte nicht initialisiert werden`r`n")
                        $outputBox.ScrollToCaret()
                    }
                }
                else {
                    # Hardware-Monitoring nicht verfügbar
                    $script:HardwareMonitoringReady = $false
                    $script:HardwareMonitoringMessage = $hwMonitorStatus.Message
                    
                    # Hardware-Panels deaktivieren
                    if ($gbCPU) { 
                        $gbCPU.Enabled = $false
                        $gbCPU.BackColor = [System.Drawing.Color]::FromArgb(100, 100, 100)
                    }
                    if ($gbGPU) { 
                        $gbGPU.Enabled = $false
                        $gbGPU.BackColor = [System.Drawing.Color]::FromArgb(100, 100, 100)
                    }
                    if ($gbRAM) { 
                        $gbRAM.Enabled = $false
                        $gbRAM.BackColor = [System.Drawing.Color]::FromArgb(100, 100, 100)
                    }
                    
                    # Labels auf "Deaktiviert" setzen
                    $hwm_message = if ($script:HardwareMonitoringMessage) { $script:HardwareMonitoringMessage } else { "Hardware-Monitoring nicht verfügbar" }
                    if ($cpuLabel) { 
                        $cpuLabel.Text = "Hardware-Monitoring deaktiviert"
                        $cpuLabel.ForeColor = [System.Drawing.Color]::Gray
                        if ($tooltipObj) { $tooltipObj.SetToolTip($cpuLabel, $hwm_message) }
                    }
                    if ($gpuLabel) { 
                        $gpuLabel.Text = "Hardware-Monitoring deaktiviert"
                        $gpuLabel.ForeColor = [System.Drawing.Color]::Gray
                        if ($tooltipObj) { $tooltipObj.SetToolTip($gpuLabel, $hwm_message) }
                    }
                    if ($ramLabel) { 
                        $ramLabel.Text = "Hardware-Monitoring deaktiviert"
                        $ramLabel.ForeColor = [System.Drawing.Color]::Gray
                        if ($tooltipObj) { $tooltipObj.SetToolTip($ramLabel, $hwm_message) }
                    }
                    
                    # Aktualisiere OutputBox mit Info
                    $outputBox.SelectionStart = $outputBox.TextLength
                    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Info'
                    $outputBox.AppendText("[i] Hardware-Monitoring deaktiviert`r`n")
                    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Warning'
                    $outputBox.AppendText("    $($script:HardwareMonitoringMessage)`r`n")
                    $outputBox.ScrollToCaret()
                }
                
                $progressBar.Value = 0
                $progressBar.CustomText = "Bereit"
                $progressBar.TextColor = [System.Drawing.Color]::White
            }
            catch {
                Write-Verbose "Hardware-Monitoring-Fehler: $_"
                $script:HardwareMonitoringReady = $false
                $progressBar.Value = 0
                $progressBar.CustomText = "Bereit"
                $progressBar.TextColor = [System.Drawing.Color]::White
                
                $outputBox.SelectionStart = $outputBox.TextLength
                Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Error'
                $outputBox.AppendText("[!] Hardware-Monitoring-Fehler: $_`r`n")
                $outputBox.ScrollToCaret()
            }
        })
        
        # Hardware-Monitor-Initialisierung abgeschlossen (markiert als "wird geladen")
        Update-InitProgress -Value 80 -Text "Lade System-Informationen..."
        
        # 4. System-Informationen vorbereiten (85%)
        Update-InitProgress -Value 85 -Text "Bereite UI-Komponenten vor..."
        
        # 5. Tool-Bibliothek laden (90%)
        Update-InitProgress -Value 90 -Text "Lade Tool-Bibliothek..."
        try {
            if (Get-Command -Name Initialize-ToolCache -ErrorAction SilentlyContinue) {
                # Tool-Cache initialisieren falls verfügbar
                Write-Verbose "Tool-Cache initialisiert"
            }
        }
        catch {
            Write-Verbose "Tool-Cache-Initialisierung übersprungen: $_"
        }
        
        # 6. Finalisiere UI (95%)
        Update-InitProgress -Value 95 -Text "Finalisiere Benutzeroberfläche..."
        
        # 7. Initialisierung abgeschlossen (100%)
        Update-InitProgress -Value 100 -Text "Initialisierung abgeschlossen"
        $progressBar.TextColor = [System.Drawing.Color]::LimeGreen
        Start-Sleep -Milliseconds 300  # Kurze Pause damit User "Abgeschlossen" sieht
        
        # ProgressBar zurücksetzen
        $progressBar.Value = 0
        $progressBar.CustomText = "Bereit"
        $progressBar.TextColor = [System.Drawing.Color]::White
        
        # ═══════════════════════════════════════════════════════════
        # WILLKOMMENSTEXT IN OUTPUTBOX
        # ═══════════════════════════════════════════════════════════
        
        $outputBox.Clear()

        Set-OutputSelectionStyle -OutputBox $outputBox -Style 'BannerFrame'
        $outputBox.AppendText("`t╔═══════════════════════════════════════════════════════════════╗`r`n")
        Set-OutputSelectionStyle -OutputBox $outputBox -Style 'BannerTitle'
        $outputBox.AppendText("`t║            WILLKOMMEN BEI BOCKI'S WINDOWS TOOL-KIT            ║`r`n")
        Set-OutputSelectionStyle -OutputBox $outputBox -Style 'BannerFrame'
        $outputBox.AppendText("`t╚═══════════════════════════════════════════════════════════════╝`r`n`r`n")

        Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Success'
        Add-OutputIcon -OutputBox $outputBox -IconCode 0xE73E
        $outputBox.AppendText(" System-Tool wurde erfolgreich gestartet`r`n`r`n")
        
        # Hardware-Monitor Status wird im Hintergrund geladen
        Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Info'
        Add-OutputIcon -OutputBox $outputBox -IconCode 0xE895
        $outputBox.AppendText(" Hardware-Monitor wird initialisiert...`r`n`r`n")
        
        $outputBox.AppendText("`r`n")
        Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Info'
        Add-OutputIcon -OutputBox $outputBox -IconCode 0xE8A5
        $outputBox.AppendText(" Alle verfügbaren Tools und Funktionen finden Sie im linken Menü.`r`n")
        $outputBox.AppendText("   Klappen Sie einen Bereich auf, um zu starten!`r`n`r`n")
        
        Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Accent'
        Add-OutputIcon -OutputBox $outputBox -IconCode 0xE946
        $outputBox.AppendText(" Tipp: `r`n")
        Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Info'
        $outputBox.AppendText("   • Verwenden Sie den '►' Button, um die Konsole ein-/auszublenden`r`n")
        $outputBox.AppendText("   • Hardware-Monitoring läuft im Hintergrund (siehe Statusleiste)`r`n")
        
        # ═══════════════════════════════════════════════════════════
        # Konsole verstecken und Hardware-Monitor-Init starten
        # ═══════════════════════════════════════════════════════════
        
        Hide-ConsoleAutomatically
        
        # Starte Hardware-Monitor-Initialisierung im Hintergrund
        $hwInitTimer.Start()
        
        # ===================================================================

        if (-not (Test-Admin)) {
            Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Warning'
            $outputBox.AppendText("[!] WARNUNG: Das Tool läuft NICHT mit Administratorrechten!`r`n")
            Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Default'
            $outputBox.AppendText("[!] Einige Funktionen werden nicht korrekt arbeiten.`r`n")
            Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Default'
            $outputBox.AppendText("[!] Bitte starten Sie das Tool erneut als Administrator.`r`n`r`n")
        }
        else {
            Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Success'
            Add-OutputIcon -OutputBox $outputBox -IconCode 0xE73E
            $outputBox.AppendText(" Das Tool läuft mit Administratorrechten.`r`n")
            Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Success'
            Add-OutputIcon -OutputBox $outputBox -IconCode 0xE73E
            $outputBox.AppendText(" Alle Funktionen stehen zur Verfügung.`r`n`r`n")
        }
        try {
            # Sicherstellen, dass das Hauptfenster aktiviert und fokussiert ist
            $mainform.Activate()
            $mainform.BringToFront()
            $mainform.Focus()
        
            # Zusätzlich: Windows API verwenden für sicheren Focus
            if ($script:positioningInitialized -and (Get-Command -Name "NativeMethods" -ErrorAction SilentlyContinue)) {
                $hwnd = $mainform.Handle
                if ($hwnd -ne [IntPtr]::Zero) {
                    [NativeMethods]::SetForegroundWindow($hwnd)
                    [NativeMethods]::ShowWindow($hwnd, [NativeMethods]::SW_RESTORE)
                }
            }            # Tooltips explizit aktivieren nach dem Fokussieren
            if ($tooltipObj) {
                $tooltipObj.Active = $true
                [System.Windows.Forms.Application]::DoEvents()
            }
        
        }
        catch {
            Write-ConsoleStyle -Message "[!] Warnung: Konnte GUI-Fenster nicht automatisch fokussieren: $_" -Style 'Warning'
            Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Warning'
            $outputBox.AppendText("[!]Warnung: Automatischer Focus fehlgeschlagen - Tooltips funktionieren nach dem ersten Klick.`r`n")
        }

        $applySettingsTimer = New-Object System.Windows.Forms.Timer
        $applySettingsTimer.Interval = 500
        $applySettingsTimer.Add_Tick({
                $this.Stop()
                # Button-Statusindikatoren initialisieren - ABER ERST NACH Tooltip-Initialisierung
                try {
                    Update-AllButtonStatusIndicators
                    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Action'
                    $outputBox.AppendText("[►] Gespeicherte Einstellungen wurden angewendet.`r`n")
                    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Action'
                    $outputBox.AppendText("[►] Button-Statusindikatoren wurden initialisiert.`r`n`r`n")
                }
                catch {
                    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Error'
                    $outputBox.AppendText("[!] Fehler beim Initialisieren der Button-Statusindikatoren: $_`r`n`r`n")
                }
                
                $this.Dispose()
            })

        $applySettingsTimer.Start()

        # Verzögerte GUI-Versionsprüfung nach dem Start (nicht-blockierend für die Initialisierung)
        $startupGuiUpdateTimer = New-Object System.Windows.Forms.Timer
        $startupGuiUpdateTimer.Interval = 1500
        $startupGuiUpdateTimer.Add_Tick({
                $this.Stop()

                try {
                    $guiUpdateStatus = $null

                    try {
                        $guiUpdateStatus = Get-GuiReleaseDependencyStatus -CurrentVersion $script:AppVersion
                    }
                    catch {
                        Write-Verbose "GUI-Update-Prüfung beim Start fehlgeschlagen: $_"
                    }

                    if ($guiUpdateStatus -and $guiUpdateStatus.UpdateAvailable) {
                        $availableVersionText = if ([string]::IsNullOrWhiteSpace($guiUpdateStatus.AvailableVersion)) {
                            "unbekannt"
                        }
                        else {
                            "v$($guiUpdateStatus.AvailableVersion)"
                        }

                        if ($outputBox) {
                            Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Warning'
                            Add-OutputIcon -OutputBox $outputBox -IconCode 0xE7BA
                            $outputBox.AppendText(" Neue GUI-Version verfügbar: $availableVersionText`r`n")
                            Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Info'
                            Add-OutputIcon -OutputBox $outputBox -IconCode 0xE721
                            $outputBox.AppendText(" Öffnen Sie 'Status prüfen', um Update oder Downgrade auszuwählen.`r`n`r`n")
                        }

                        if ($statusLabel) {
                            $statusLabel.Text = "Status: Neue GUI-Version verfügbar ($availableVersionText) | " + (Get-Date -Format "dd.MM.yyyy HH:mm")
                        }

                        $dialogText = "Eine neue GUI-Version ist verfügbar ($availableVersionText).`r`n`r`nJetzt 'Status prüfen' öffnen?"
                        $dialogResult = [System.Windows.Forms.MessageBox]::Show(
                            $dialogText,
                            "Neue Version verfügbar",
                            [System.Windows.Forms.MessageBoxButtons]::YesNo,
                            [System.Windows.Forms.MessageBoxIcon]::Information
                        )

                        if ($dialogResult -eq [System.Windows.Forms.DialogResult]::Yes -and $btnCheckDependenciesH) {
                            $btnCheckDependenciesH.PerformClick()
                        }
                    }
                }
                catch {
                    Write-Verbose "Fehler bei Startup-Update-Hinweis: $_"
                }
                finally {
                    $this.Dispose()
                }
            })
        $startupGuiUpdateTimer.Start()

        # Timer für die finale Positionierung nach dem vollständigen Laden
        $positioningTimer = New-Object System.Windows.Forms.Timer
        $positioningTimer.Interval = 1000  # 1 Sekunde warten
        $positioningTimer.Add_Tick({
                $this.Stop()

                try {
                    # Konsolenfenster finden und in den Vordergrund bringen
                    $consoleHandle = Find-PowerShellWindow
                    if ($consoleHandle -ne [IntPtr]::Zero) {
                        # Konsolenfenster in den Vordergrund bringen
                        [NativeMethods]::ShowWindow($consoleHandle, [NativeMethods]::SW_RESTORE)
                        [NativeMethods]::SetForegroundWindow($consoleHandle)

                        # Konsolenfenstergröße ermitteln
                        $rect = New-Object RECT                        if ([NativeMethods]::GetWindowRect($consoleHandle, [ref]$rect)) {
                            # GUI-Fenster rechts neben dem Konsolenfenster positionieren
                            $guiLeft = $rect.Right + 10
                            $guiTop = $rect.Top

                            # Sicherstellen, dass das Fenster auf dem Bildschirm sichtbar ist
                            $screenWidth = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea.Width
                            $screenHeight = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea.Height

                            if ($guiLeft + $mainform.Width -gt $screenWidth) {
                                # Wenn das GUI-Fenster rechts nicht mehr auf den Bildschirm passt,
                                # platziere es unter dem Konsolenfenster
                                $guiLeft = $rect.Left
                                $guiTop = $rect.Bottom + 10

                                # Wenn auch das nicht passt, dann belasse es bei der aktuellen Position
                                if ($guiTop + $mainform.Height -gt $screenHeight) {
                                    return
                                }
                            }

                            # Debug-Ausgabe entfernt
                            $mainform.Location = New-Object System.Drawing.Point($guiLeft, $guiTop)
                        }
                    }                
                }
                catch {
                }
                finally {
                    # Einfache Tooltip-Aktivierung nach vollständiger GUI-Initialisierung
                    if ($tooltipObj) {
                        $tooltipObj.Active = $true
                        [System.Windows.Forms.Application]::DoEvents()
                        #    Write-Host "Tooltips wurden nach GUI-Initialisierung aktiviert" -ForegroundColor Green
                    }
                    # Timer für verzögerte Tooltip-Setzung (erst nach vollständiger GUI-Initialisierung)
                    $tooltipSetupTimer = New-Object System.Windows.Forms.Timer
                    $tooltipSetupTimer.Interval = 1000  # 1 Sekunde warten
                    $tooltipSetupTimer.Add_Tick({
                            $this.Stop()
                            try {
                                if ($tooltipObj) {
                                    # Tooltips aktivieren, nachdem alle GUI-Elemente sicher initialisiert sind
                                    $tooltipObj.Active = $true
                                
                                    # UI-Events verarbeiten
                                    [System.Windows.Forms.Application]::DoEvents()
                                
                                    # Fenster nochmals aktivieren für sichere Tooltip-Funktionalität
                                    $mainform.Activate()
                                    $mainform.BringToFront()
                                    [System.Windows.Forms.Application]::DoEvents()
                                }
                            }
                            catch {
                                Write-Host "Fehler beim Setzen der Tooltips: $_" -ForegroundColor Red
                            }
                            finally {
                                $this.Dispose()
                            }
                        })
                    $tooltipSetupTimer.Start()
                    
                    $this.Dispose()
                }
            })
        $positioningTimer.Start()
    })

# Event-Handler für Button-Wechsel hinzufügen - steuert, welche Buttons in der SubNavigation angezeigt werden
$mainform.Add_VisibleChanged({
    if ($mainform.Visible) {
        # Nur beim ersten Laden ausführen
        # Behandle Subnavigation Buttons je nach aktiver Ansicht
           }
})

# Initialzustand für horizontale Panels setzen

# Initialzustand wird jetzt durch PerformClick() am Ende des Skripts gesetzt
# Controls entsprechend ein-/ausblenden
Switch-SystemControls

# Initialisiere Netzwerk-Controls
# Standardmäßig Diagnose-Controls anzeigen
Switch-NetworkControls

# Initialisiere Bereinigungs-Controls

# Update Toggle-Button Status (initial auf "Versteckt"-Symbol)
if ($btnToggleConsole) {
    $btnToggleConsole.Text = "►"
    $btnToggleConsole.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
}

# ===================================================================
# VERSIONS-REGISTRIERUNG (für Installer-Updates)
# ===================================================================
try {
    $regPath = "HKCU:\Software\Bockis\SystemTool"
    if (-not (Test-Path $regPath)) {
        New-Item -Path $regPath -Force | Out-Null
    }
    Set-ItemProperty -Path $regPath -Name "Version" -Value $script:AppVersion -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $regPath -Name "InstallPath" -Value $PSScriptRoot -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $regPath -Name "LastRun" -Value (Get-Date -Format "yyyy-MM-dd HH:mm:ss") -ErrorAction SilentlyContinue
} catch {
    # Fehler beim Registry-Schreiben ignorieren (nicht kritisch)
}

[void]$mainform.ShowDialog()



# SIG # Begin signature block
# MIIcSgYJKoZIhvcNAQcCoIIcOzCCHDcCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBu7jVMKLfbxLFB
# r0Zrw+T6aRQHszqVS9hDAscOmtN4VaCCFnowggM8MIICJKADAgECAhBJfyGrXBJT
# oUbCYkBRRxacMA0GCSqGSIb3DQEBCwUAMDYxCzAJBgNVBAYTAkRFMQ4wDAYDVQQK
# DAVCb2NraTEXMBUGA1UEAwwOQm9ja2kgU29mdHdhcmUwHhcNMjYwMTIwMTc0NjIy
# WhcNMzEwMTIwMTc1NjIyWjA2MQswCQYDVQQGEwJERTEOMAwGA1UECgwFQm9ja2kx
# FzAVBgNVBAMMDkJvY2tpIFNvZnR3YXJlMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8A
# MIIBCgKCAQEAoQtPttwj/HfLCMp+5pqQOYHtAsyMU7eKVIdtkrEaISn8wKZQqEQL
# E4iGdIVsDmaoIns790Lt3Uw/2xnXy2y3/X2dXBypkjoF5346p79Fb9hNAs103lzk
# NPgxkSkkGpmXERWTeik64eUq3u0TjTivFgFMIwOJUorSkIwzUh/iLQZeCihuRIZL
# eubl7OdiPl4yPb2SlLdhSErXSkhHPSsu6U6j/MJvvBNRkF3uF7B+lLPvW9I/hfAF
# R1UEyAoX+l91AKtjac32OzZH2/Wj2ezoa4PliyzLox7Pjn642pvd/cU+LKWwl4Fm
# iu8c03rafk3Ykpp05QJcCWiy2aExG20xTQIDAQABo0YwRDAOBgNVHQ8BAf8EBAMC
# B4AwEwYDVR0lBAwwCgYIKwYBBQUHAwMwHQYDVR0OBBYEFPiUIYSngqXUa7A3vbjR
# 0PXonIvMMA0GCSqGSIb3DQEBCwUAA4IBAQBMzmWw9+P7IV7xla88buo++WjtigRK
# 5YaY7K1yyn1bml6Hd2uWaF1ptfUuUnDPDyQr9eFrrHkK4qwhx5k2X4spjzLjhPf+
# MPWLjN5ZudKwgQhTjSrcUAsi0Qi5LopPAKNjP3yDclEtJJh3/L0gmhkfu4AIbUin
# IRCHy8WcPWO1jgp4FzkoVkxeuwe2X8WIsjUSooi3qlYqxBK8amlTRUCSmtMpcif5
# 1Ew1KoiOV2cC/tzcHs1clkmJQvZ6Urwc1PbIbHKDYy0l4N5/4epycum4Ijq3fkBf
# BN3AfKchZw6j+iCInCimjmdgwb6vYPCru6/4fdBt5BCRy0SjBmi5MMpFMIIFjTCC
# BHWgAwIBAgIQDpsYjvnQLefv21DiCEAYWjANBgkqhkiG9w0BAQwFADBlMQswCQYD
# VQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGln
# aWNlcnQuY29tMSQwIgYDVQQDExtEaWdpQ2VydCBBc3N1cmVkIElEIFJvb3QgQ0Ew
# HhcNMjIwODAxMDAwMDAwWhcNMzExMTA5MjM1OTU5WjBiMQswCQYDVQQGEwJVUzEV
# MBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNlcnQuY29t
# MSEwHwYDVQQDExhEaWdpQ2VydCBUcnVzdGVkIFJvb3QgRzQwggIiMA0GCSqGSIb3
# DQEBAQUAA4ICDwAwggIKAoICAQC/5pBzaN675F1KPDAiMGkz7MKnJS7JIT3yithZ
# wuEppz1Yq3aaza57G4QNxDAf8xukOBbrVsaXbR2rsnnyyhHS5F/WBTxSD1Ifxp4V
# pX6+n6lXFllVcq9ok3DCsrp1mWpzMpTREEQQLt+C8weE5nQ7bXHiLQwb7iDVySAd
# YyktzuxeTsiT+CFhmzTrBcZe7FsavOvJz82sNEBfsXpm7nfISKhmV1efVFiODCu3
# T6cw2Vbuyntd463JT17lNecxy9qTXtyOj4DatpGYQJB5w3jHtrHEtWoYOAMQjdjU
# N6QuBX2I9YI+EJFwq1WCQTLX2wRzKm6RAXwhTNS8rhsDdV14Ztk6MUSaM0C/CNda
# SaTC5qmgZ92kJ7yhTzm1EVgX9yRcRo9k98FpiHaYdj1ZXUJ2h4mXaXpI8OCiEhtm
# mnTK3kse5w5jrubU75KSOp493ADkRSWJtppEGSt+wJS00mFt6zPZxd9LBADMfRyV
# w4/3IbKyEbe7f/LVjHAsQWCqsWMYRJUadmJ+9oCw++hkpjPRiQfhvbfmQ6QYuKZ3
# AeEPlAwhHbJUKSWJbOUOUlFHdL4mrLZBdd56rF+NP8m800ERElvlEFDrMcXKchYi
# Cd98THU/Y+whX8QgUWtvsauGi0/C1kVfnSD8oR7FwI+isX4KJpn15GkvmB0t9dmp
# sh3lGwIDAQABo4IBOjCCATYwDwYDVR0TAQH/BAUwAwEB/zAdBgNVHQ4EFgQU7Nfj
# gtJxXWRM3y5nP+e6mK4cD08wHwYDVR0jBBgwFoAUReuir/SSy4IxLVGLp6chnfNt
# yA8wDgYDVR0PAQH/BAQDAgGGMHkGCCsGAQUFBwEBBG0wazAkBggrBgEFBQcwAYYY
# aHR0cDovL29jc3AuZGlnaWNlcnQuY29tMEMGCCsGAQUFBzAChjdodHRwOi8vY2Fj
# ZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRBc3N1cmVkSURSb290Q0EuY3J0MEUG
# A1UdHwQ+MDwwOqA4oDaGNGh0dHA6Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2Vy
# dEFzc3VyZWRJRFJvb3RDQS5jcmwwEQYDVR0gBAowCDAGBgRVHSAAMA0GCSqGSIb3
# DQEBDAUAA4IBAQBwoL9DXFXnOF+go3QbPbYW1/e/Vwe9mqyhhyzshV6pGrsi+Ica
# aVQi7aSId229GhT0E0p6Ly23OO/0/4C5+KH38nLeJLxSA8hO0Cre+i1Wz/n096ww
# epqLsl7Uz9FDRJtDIeuWcqFItJnLnU+nBgMTdydE1Od/6Fmo8L8vC6bp8jQ87PcD
# x4eo0kxAGTVGamlUsLihVo7spNU96LHc/RzY9HdaXFSMb++hUD38dglohJ9vytsg
# jTVgHAIDyyCwrFigDkBjxZgiwbJZ9VVrzyerbHbObyMt9H5xaiNrIv8SuFQtJ37Y
# OtnwtoeW/VvRXKwYw02fc7cBqZ9Xql4o4rmUMIIGtDCCBJygAwIBAgIQDcesVwX/
# IZkuQEMiDDpJhjANBgkqhkiG9w0BAQsFADBiMQswCQYDVQQGEwJVUzEVMBMGA1UE
# ChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNlcnQuY29tMSEwHwYD
# VQQDExhEaWdpQ2VydCBUcnVzdGVkIFJvb3QgRzQwHhcNMjUwNTA3MDAwMDAwWhcN
# MzgwMTE0MjM1OTU5WjBpMQswCQYDVQQGEwJVUzEXMBUGA1UEChMORGlnaUNlcnQs
# IEluYy4xQTA/BgNVBAMTOERpZ2lDZXJ0IFRydXN0ZWQgRzQgVGltZVN0YW1waW5n
# IFJTQTQwOTYgU0hBMjU2IDIwMjUgQ0ExMIICIjANBgkqhkiG9w0BAQEFAAOCAg8A
# MIICCgKCAgEAtHgx0wqYQXK+PEbAHKx126NGaHS0URedTa2NDZS1mZaDLFTtQ2oR
# jzUXMmxCqvkbsDpz4aH+qbxeLho8I6jY3xL1IusLopuW2qftJYJaDNs1+JH7Z+Qd
# SKWM06qchUP+AbdJgMQB3h2DZ0Mal5kYp77jYMVQXSZH++0trj6Ao+xh/AS7sQRu
# QL37QXbDhAktVJMQbzIBHYJBYgzWIjk8eDrYhXDEpKk7RdoX0M980EpLtlrNyHw0
# Xm+nt5pnYJU3Gmq6bNMI1I7Gb5IBZK4ivbVCiZv7PNBYqHEpNVWC2ZQ8BbfnFRQV
# ESYOszFI2Wv82wnJRfN20VRS3hpLgIR4hjzL0hpoYGk81coWJ+KdPvMvaB0WkE/2
# qHxJ0ucS638ZxqU14lDnki7CcoKCz6eum5A19WZQHkqUJfdkDjHkccpL6uoG8pbF
# 0LJAQQZxst7VvwDDjAmSFTUms+wV/FbWBqi7fTJnjq3hj0XbQcd8hjj/q8d6ylgx
# CZSKi17yVp2NL+cnT6Toy+rN+nM8M7LnLqCrO2JP3oW//1sfuZDKiDEb1AQ8es9X
# r/u6bDTnYCTKIsDq1BtmXUqEG1NqzJKS4kOmxkYp2WyODi7vQTCBZtVFJfVZ3j7O
# gWmnhFr4yUozZtqgPrHRVHhGNKlYzyjlroPxul+bgIspzOwbtmsgY1MCAwEAAaOC
# AV0wggFZMBIGA1UdEwEB/wQIMAYBAf8CAQAwHQYDVR0OBBYEFO9vU0rp5AZ8esri
# kFb2L9RJ7MtOMB8GA1UdIwQYMBaAFOzX44LScV1kTN8uZz/nupiuHA9PMA4GA1Ud
# DwEB/wQEAwIBhjATBgNVHSUEDDAKBggrBgEFBQcDCDB3BggrBgEFBQcBAQRrMGkw
# JAYIKwYBBQUHMAGGGGh0dHA6Ly9vY3NwLmRpZ2ljZXJ0LmNvbTBBBggrBgEFBQcw
# AoY1aHR0cDovL2NhY2VydHMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0VHJ1c3RlZFJv
# b3RHNC5jcnQwQwYDVR0fBDwwOjA4oDagNIYyaHR0cDovL2NybDMuZGlnaWNlcnQu
# Y29tL0RpZ2lDZXJ0VHJ1c3RlZFJvb3RHNC5jcmwwIAYDVR0gBBkwFzAIBgZngQwB
# BAIwCwYJYIZIAYb9bAcBMA0GCSqGSIb3DQEBCwUAA4ICAQAXzvsWgBz+Bz0RdnEw
# vb4LyLU0pn/N0IfFiBowf0/Dm1wGc/Do7oVMY2mhXZXjDNJQa8j00DNqhCT3t+s8
# G0iP5kvN2n7Jd2E4/iEIUBO41P5F448rSYJ59Ib61eoalhnd6ywFLerycvZTAz40
# y8S4F3/a+Z1jEMK/DMm/axFSgoR8n6c3nuZB9BfBwAQYK9FHaoq2e26MHvVY9gCD
# A/JYsq7pGdogP8HRtrYfctSLANEBfHU16r3J05qX3kId+ZOczgj5kjatVB+NdADV
# ZKON/gnZruMvNYY2o1f4MXRJDMdTSlOLh0HCn2cQLwQCqjFbqrXuvTPSegOOzr4E
# Wj7PtspIHBldNE2K9i697cvaiIo2p61Ed2p8xMJb82Yosn0z4y25xUbI7GIN/TpV
# fHIqQ6Ku/qjTY6hc3hsXMrS+U0yy+GWqAXam4ToWd2UQ1KYT70kZjE4YtL8Pbzg0
# c1ugMZyZZd/BdHLiRu7hAWE6bTEm4XYRkA6Tl4KSFLFk43esaUeqGkH/wyW4N7Oi
# gizwJWeukcyIPbAvjSabnf7+Pu0VrFgoiovRDiyx3zEdmcif/sYQsfch28bZeUz2
# rtY/9TCA6TD8dC3JE3rYkrhLULy7Dc90G6e8BlqmyIjlgp2+VqsS9/wQD7yFylIz
# 0scmbKvFoW2jNrbM1pD2T7m3XDCCBu0wggTVoAMCAQICEAqA7xhLjfEFgtHEdqeV
# dGgwDQYJKoZIhvcNAQELBQAwaTELMAkGA1UEBhMCVVMxFzAVBgNVBAoTDkRpZ2lD
# ZXJ0LCBJbmMuMUEwPwYDVQQDEzhEaWdpQ2VydCBUcnVzdGVkIEc0IFRpbWVTdGFt
# cGluZyBSU0E0MDk2IFNIQTI1NiAyMDI1IENBMTAeFw0yNTA2MDQwMDAwMDBaFw0z
# NjA5MDMyMzU5NTlaMGMxCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwg
# SW5jLjE7MDkGA1UEAxMyRGlnaUNlcnQgU0hBMjU2IFJTQTQwOTYgVGltZXN0YW1w
# IFJlc3BvbmRlciAyMDI1IDEwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoIC
# AQDQRqwtEsae0OquYFazK1e6b1H/hnAKAd/KN8wZQjBjMqiZ3xTWcfsLwOvRxUwX
# cGx8AUjni6bz52fGTfr6PHRNv6T7zsf1Y/E3IU8kgNkeECqVQ+3bzWYesFtkepEr
# vUSbf+EIYLkrLKd6qJnuzK8Vcn0DvbDMemQFoxQ2Dsw4vEjoT1FpS54dNApZfKY6
# 1HAldytxNM89PZXUP/5wWWURK+IfxiOg8W9lKMqzdIo7VA1R0V3Zp3DjjANwqAf4
# lEkTlCDQ0/fKJLKLkzGBTpx6EYevvOi7XOc4zyh1uSqgr6UnbksIcFJqLbkIXIPb
# cNmA98Oskkkrvt6lPAw/p4oDSRZreiwB7x9ykrjS6GS3NR39iTTFS+ENTqW8m6TH
# uOmHHjQNC3zbJ6nJ6SXiLSvw4Smz8U07hqF+8CTXaETkVWz0dVVZw7knh1WZXOLH
# gDvundrAtuvz0D3T+dYaNcwafsVCGZKUhQPL1naFKBy1p6llN3QgshRta6Eq4B40
# h5avMcpi54wm0i2ePZD5pPIssoszQyF4//3DoK2O65Uck5Wggn8O2klETsJ7u8xE
# ehGifgJYi+6I03UuT1j7FnrqVrOzaQoVJOeeStPeldYRNMmSF3voIgMFtNGh86w3
# ISHNm0IaadCKCkUe2LnwJKa8TIlwCUNVwppwn4D3/Pt5pwIDAQABo4IBlTCCAZEw
# DAYDVR0TAQH/BAIwADAdBgNVHQ4EFgQU5Dv88jHt/f3X85FxYxlQQ89hjOgwHwYD
# VR0jBBgwFoAU729TSunkBnx6yuKQVvYv1Ensy04wDgYDVR0PAQH/BAQDAgeAMBYG
# A1UdJQEB/wQMMAoGCCsGAQUFBwMIMIGVBggrBgEFBQcBAQSBiDCBhTAkBggrBgEF
# BQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQuY29tMF0GCCsGAQUFBzAChlFodHRw
# Oi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRUcnVzdGVkRzRUaW1lU3Rh
# bXBpbmdSU0E0MDk2U0hBMjU2MjAyNUNBMS5jcnQwXwYDVR0fBFgwVjBUoFKgUIZO
# aHR0cDovL2NybDMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0VHJ1c3RlZEc0VGltZVN0
# YW1waW5nUlNBNDA5NlNIQTI1NjIwMjVDQTEuY3JsMCAGA1UdIAQZMBcwCAYGZ4EM
# AQQCMAsGCWCGSAGG/WwHATANBgkqhkiG9w0BAQsFAAOCAgEAZSqt8RwnBLmuYEHs
# 0QhEnmNAciH45PYiT9s1i6UKtW+FERp8FgXRGQ/YAavXzWjZhY+hIfP2JkQ38U+w
# tJPBVBajYfrbIYG+Dui4I4PCvHpQuPqFgqp1PzC/ZRX4pvP/ciZmUnthfAEP1HSh
# TrY+2DE5qjzvZs7JIIgt0GCFD9ktx0LxxtRQ7vllKluHWiKk6FxRPyUPxAAYH2Vy
# 1lNM4kzekd8oEARzFAWgeW3az2xejEWLNN4eKGxDJ8WDl/FQUSntbjZ80FU3i54t
# px5F/0Kr15zW/mJAxZMVBrTE2oi0fcI8VMbtoRAmaaslNXdCG1+lqvP4FbrQ6IwS
# BXkZagHLhFU9HCrG/syTRLLhAezu/3Lr00GrJzPQFnCEH1Y58678IgmfORBPC1JK
# kYaEt2OdDh4GmO0/5cHelAK2/gTlQJINqDr6JfwyYHXSd+V08X1JUPvB4ILfJdmL
# +66Gp3CSBXG6IwXMZUXBhtCyIaehr0XkBoDIGMUG1dUtwq1qmcwbdUfcSYCn+Own
# cVUXf53VJUNOaMWMts0VlRYxe5nK+At+DI96HAlXHAL5SlfYxJ7La54i71McVWRP
# 66bW+yERNpbJCjyCYG2j+bdpxo/1Cy4uPcU3AWVPGrbn5PhDBf3Froguzzhk++am
# i+r3Qrx5bIbY3TVzgiFI7Gq3zWcxggUmMIIFIgIBATBKMDYxCzAJBgNVBAYTAkRF
# MQ4wDAYDVQQKDAVCb2NraTEXMBUGA1UEAwwOQm9ja2kgU29mdHdhcmUCEEl/Iatc
# ElOhRsJiQFFHFpwwDQYJYIZIAWUDBAIBBQCggYQwGAYKKwYBBAGCNwIBDDEKMAig
# AoAAoQKAADAZBgkqhkiG9w0BCQMxDAYKKwYBBAGCNwIBBDAcBgorBgEEAYI3AgEL
# MQ4wDAYKKwYBBAGCNwIBFTAvBgkqhkiG9w0BCQQxIgQg+OMVCpjNjtce4eGpOVXx
# 4qiK+RpNlfGMkCcIHqF7e18wDQYJKoZIhvcNAQEBBQAEggEASkOXqPQMl4JHpslI
# np9m9OQsW4wdMX4fyoQjXVwJVGElgHKmbh0kltangac9ZhK/xiYTxF5FShPmmxxH
# t2z6xmRWWyHs51K1jmjNbphPgEGaRAX1jLLbYknK/RirS2M88G0pKeJZiemSk7Um
# R/GJE9Dy+v7Gafe4LCoLjmCLnoC8QT1E+tjcMlYeeuAu55CDpTuDKuPn4xQcMyHp
# JRcWIvTqRm8Ou5KIJdlSBVfssL/r/iLAkhlCxxvJIui7pUJ6Il5PIQnRecoRCJe3
# +2Swoc0Yp5nigdTR+JLGaQkrZpBVe3ztOOpBAuCG5oaFrfaDQT0T81iJOr71ebB3
# RzU1WKGCAyYwggMiBgkqhkiG9w0BCQYxggMTMIIDDwIBATB9MGkxCzAJBgNVBAYT
# AlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5jLjFBMD8GA1UEAxM4RGlnaUNlcnQg
# VHJ1c3RlZCBHNCBUaW1lU3RhbXBpbmcgUlNBNDA5NiBTSEEyNTYgMjAyNSBDQTEC
# EAqA7xhLjfEFgtHEdqeVdGgwDQYJYIZIAWUDBAIBBQCgaTAYBgkqhkiG9w0BCQMx
# CwYJKoZIhvcNAQcBMBwGCSqGSIb3DQEJBTEPFw0yNjAxMjAxODAyNTJaMC8GCSqG
# SIb3DQEJBDEiBCBI8LEdFarcinFRw5p1Rsuby4Ia4bx9NsbDcHXkdvedIjANBgkq
# hkiG9w0BAQEFAASCAgAq0BJwkCC8Ebzm8MBNMK59dQCEGVawL0xBPxF36BsYegsT
# GU+8GXVz22fjXIDyxPFeA4NQhoSwfpGG5MEP/1L73NFlXd3fv2p7Bh1M+VOHC+7i
# zK6fzGJRn2y9umcYU/rR+A3Vmch53ZjbT7IuhIs36IzI5EusZoWj7QGMN/BVapRT
# aqlYKD1axG169NgF6IPrTIf7zsrMuDgTWaebXrLQA97EWhZsnLl2WVF4xl6D0DzX
# V/EKecK7GIK3WbO2EmDJ+rJQkjtnO70pJ2KzuoO4bVsoTMUvwlznTz7mRzz2RhMf
# 8g7ISDrqYBArFiuJ9f47W582SL7h+9ttDgM2DX4/hNl5C3+C2KpcyFxa1FpD5/kZ
# BGZWuVJkoGdREn3T0Nh2RG8/AWs2vFR2kZ+0ENylO213vUS7p4OdCSnUCf9ifu5T
# rJo+8HVhdtBEQEj2f/kS0e5Tipp/oU9Vht7NDTJLWIbRBmoj8imF28nRfony8CkL
# bBuvMinenDBR2f6KFis9uowqyguvMRhRSkUpmYP1S27ejgJL+YUFpzv7wIQAyrng
# YyKNcb+HLXv5YRdKfIIqqa+B6DBOZyfjNhFHwrTqq8oIU0LFn0Azy7KgyhL50Jq4
# l+HJ+GdN9Loq4LF/M1igCdJu8Xr+jRRS+rIN+rK7K+zTTamLn0ttCuFe14gUeA==
# SIG # End signature block





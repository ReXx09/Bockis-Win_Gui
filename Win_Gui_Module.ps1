# Win_Gui_Module.ps1 - Hauptskript für die PowerShell-GUI
# Autor: Bocki
# Version: 4.1

# ===================================================================
# VERSIONS-INFORMATION
# ===================================================================
$script:AppVersion = "4.1"
$script:AppName = "Bockis System-Tool"
$script:AppPublisher = "Bockis"
$script:VersionDate = "2025-11-29"

# WPF-Assemblies für moderne UI-Komponenten laden
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsFormsIntegration
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Windows.Forms

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

# Settings-Modul importieren
Import-Module "$PSScriptRoot\Modules\Core\Settings.psm1" -Force

# LogManager-Modul importieren
Import-Module "$PSScriptRoot\Modules\Core\LogManager.psm1" -Force

# UI-Modul importieren
Import-Module "$PSScriptRoot\Modules\Core\UI.psm1" -Force

# TextStyle-Modul importieren
Import-Module "$PSScriptRoot\Modules\Core\TextStyle.psm1" -Force

# ToolCache-Modul importieren (für schnelleres Laden der Tool-Downloads)
Import-Module "$PSScriptRoot\Modules\ToolCache.psm1" -Force

# ToolLibrary-Modul importieren
Import-Module "$PSScriptRoot\Modules\ToolLibrary.psm1" -Force

# Globale Einstellungen - werden vom Settings-Modul verwaltet
$script:settings = $null

# Globale Datenbankverbindung
$script:dbConnection = $null

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
            # Die Meldung wird jetzt in der GUI-Initialisierung angezeigt
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

# Einstellungen beim Programmstart laden
$null = Import-Settings

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

# Funktion für einheitliches Logging
function Write-ToolLog {
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

    # Verwende LogManager, um in die Logdatei zu schreiben
    if (Get-Command -Name 'Write-ToolLog' -Module 'LogManager' -ErrorAction SilentlyContinue) {
        & (Get-Command -Name 'Write-ToolLog' -Module 'LogManager') `
            -ToolName $ToolName `
            -Message $Message `
            -Level $Level `
            -NoTimestamp:$NoTimestamp
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
    'Core\Core                    ', # Basis-Funktionalitäten
    'Core\UI                      ', # UI-Komponenten
    'Core\ProgressBarTools        ', # ProgressBar-Funktionalitäten
    'Core\LogManager              ', # Logging-Funktionalitäten
    'Monitor\HardwareMonitorTools ', # Hardware-Monitor-Tools
    'SystemInfo                   ', # System-Informationen
    'Tools\SystemTools            ', # System-Tools
    'Tools\DISM-Tools             ', # Festplatten-Tools
    'Tools\CHKDSKTools            ', # CHKDSK-Tools
    'Tools\NetworkTools           ', # Netzwerk-Tools
    'Tools\CleanupTools           ', # Bereinigungs-Tools
    'ToolLibrary                  ', # Tool-Bibliothek
    # 'HardwareInfo               ', # DEPRECATED - Nicht mehr verwendet (direkt in Win_Gui_Module.ps1)
    'Tools\DefenderTools          ', # Windows Defender Tools
    'Tools\WindowsUpdateTools     ', # Windows Update Tools
    'DatabaseManager              ' # Datenbank-Integration
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
    }

    Start-Sleep -Milliseconds 100  # Kurze Verzögerung für visuelle Wirkung
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
    foreach ($missingModule in $missingModules) {
        Write-Host "Modul $missingModule wurde nicht geladen." -ForegroundColor Red
    }
}

# ============================================================================
# DEFENDER-AUSNAHMEN-PRÜFUNG FÜR HARDWARE-MONITORING
# ============================================================================
# Prüfe ob Windows Defender-Ausnahmen für das Lib-Verzeichnis existieren
# Dies ist wichtig für das Hardware-Monitoring (LibreHardwareMonitor)
try {
    $libPath = Join-Path $PSScriptRoot "Win_Gui_Projekt\Lib"
    $currentExclusions = Get-MpPreference -ErrorAction SilentlyContinue | Select-Object -ExpandProperty ExclusionPath
    
    if ($currentExclusions -and ($currentExclusions -notcontains $libPath)) {
        Write-Host "`n[!] Windows Defender-Ausnahme fehlt für Hardware-Monitoring" -ForegroundColor Yellow
        Write-Host "    Versuche automatisch hinzuzufügen..." -NoNewline
        
        try {
            Add-MpPreference -ExclusionPath $libPath -ErrorAction Stop
            Write-Host " ✓" -ForegroundColor Green
            Write-Host "    Hardware-Monitoring (Temperaturen) sollte jetzt funktionieren." -ForegroundColor Green
        }
        catch {
            Write-Host " ✗" -ForegroundColor Red
            Write-Host "`n    WARNUNG: Defender-Ausnahme konnte nicht automatisch hinzugefügt werden." -ForegroundColor Yellow
            Write-Host "    FOLGEN: Hardware-Temperaturen (CPU/GPU/RAM) funktionieren möglicherweise nicht." -ForegroundColor Yellow
            Write-Host "`n    LÖSUNG - Fügen Sie manuell eine Ausnahme hinzu:" -ForegroundColor Cyan
            Write-Host "    1. Windows-Sicherheit öffnen" -ForegroundColor White
            Write-Host "    2. Viren- & Bedrohungsschutz → Einstellungen" -ForegroundColor White
            Write-Host "    3. Ausschlüsse verwalten → Ordner hinzufügen" -ForegroundColor White
            Write-Host "    4. Ordner auswählen: $libPath" -ForegroundColor White
            Write-Host "`n    Hintergrund: LibreHardwareMonitor nutzt Low-Level-Hardware-Zugriff," -ForegroundColor DarkGray
            Write-Host "    den Defender manchmal fälschlicherweise als Bedrohung erkennt." -ForegroundColor DarkGray
            Write-Host "    Das Tool ist SICHER - Open Source auf GitHub verfügbar.`n" -ForegroundColor DarkGray
        }
    }
    elseif ($currentExclusions -and ($currentExclusions -contains $libPath)) {
        Write-Host "`n[✓] Defender-Ausnahme für Hardware-Monitoring vorhanden" -ForegroundColor Green
    }
}
catch {
    # Wenn Get-MpPreference fehlschlägt (z.B. Defender deaktiviert), ignorieren
    Write-Host "`n[i] Windows Defender nicht verfügbar oder deaktiviert" -ForegroundColor DarkGray
}

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

# Erstelle das Hauptformular
$mainform = New-Object System.Windows.Forms.Form
$mainform.Text = "$script:AppName $script:AppVersion"
$mainform.Size = New-Object System.Drawing.Size(1000, 800)
$mainform.StartPosition = "CenterScreen"  # Immer zentriert starten
$mainform.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$mainform.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::None  # Kein Rahmen
$mainform.MinimumSize = New-Object System.Drawing.Size(1000, 850)
$mainform.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)  # Dunkles Grau wie UniGetUI

# Windows AutoScale für automatische Anpassung an alle Bildschirmauflösungen
# Dies passt die GUI automatisch an HD, Full HD, 4K, 8K und alle DPI-Einstellungen an
$mainform.AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::Dpi
$mainform.AutoScaleDimensions = New-Object System.Drawing.SizeF(96.0, 96.0)

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

# Timer für Hardware-Updates initialisieren
$hardwareResult = Initialize-HardwareMonitoring `
    -cpuLabel $cpuLabel `
    -gpuLabel $gpuLabel `
    -ramLabel $ramLabel `
    -gbCPU $gbCPU `
    -gbGPU $gbGPU `
    -gbRAM $gbRAM `
    -WaitForGuiLoaded `
    -LoadDelayMs 3000 `
    -GlobalTooltip $tooltipObj

# Prüfen ob Hardware-Initialisierung erfolgreich war
if (-not $hardwareResult) {
    Write-Host "WARNUNG: Hardware-Monitoring konnte nicht vollständig initialisiert werden." -ForegroundColor Yellow
    Write-Host "Das System wird trotzdem gestartet, aber die Hardware-Überwachung funktioniert möglicherweise nicht korrekt." -ForegroundColor Yellow
}
else {
    # Hardware-Schwellenwerte aus Einstellungen anwenden (nach erfolgreicher Initialisierung)
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
}

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
        
        # Verwende das LogManager-System für GUI-Closing-Logs
        Write-GuiClosingLog -Message $Message -Level $level
        
        return $true
    }
    catch {
        Write-Warning "Fehler beim Schreiben des Logs über LogManager: $_"
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
        
        # Aktuellen Skriptpfad ermitteln
        $scriptPath = $PSCommandPath
        if ([string]::IsNullOrEmpty($scriptPath)) {
            $scriptPath = $MyInvocation.MyCommand.Path
        }
        
        # Neuen PowerShell-Prozess starten
        $processStartInfo = New-Object System.Diagnostics.ProcessStartInfo
        $processStartInfo.FileName = "powershell.exe"
        $processStartInfo.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""
        $processStartInfo.UseShellExecute = $true
        $processStartInfo.WorkingDirectory = $PSScriptRoot
        
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
$outputButtonPanel.Location = New-Object System.Drawing.Point(5, 130)  
$outputButtonPanel.Size = New-Object System.Drawing.Size(180, 50)  
$outputButtonPanel.BackColor = [System.Drawing.Color]::Transparent
$mainform.Controls.Add($outputButtonPanel)

# Erstelle eine Button-Leiste für die Hauptnavigation (vertikal) 
$mainButtonPanel = New-Object System.Windows.Forms.Panel
$mainButtonPanel.Location = New-Object System.Drawing.Point(5, 200)  
$mainButtonPanel.Size = New-Object System.Drawing.Size(180, 550)  
$mainButtonPanel.BackColor = [System.Drawing.Color]::Transparent
$mainform.Controls.Add($mainButtonPanel)

#------------------------------------------------------------------------------------------------------------

# Erstelle ein Panel für die verschiedenen Hauptinhalte 
$mainContentPanel = New-Object System.Windows.Forms.Panel
$mainContentPanel.Location = New-Object System.Drawing.Point(215, 120)  
$mainContentPanel.Size = New-Object System.Drawing.Size(770, 50)  
$mainContentPanel.BackColor = [System.Drawing.Color]::Transparent
$mainform.Controls.Add($mainContentPanel)

# Suchfeld-Panel für Downloads (im mainContentPanel, oberhalb der Tool-Buttons)
$searchPanel = New-Object System.Windows.Forms.Panel
$searchPanel.Location = New-Object System.Drawing.Point(0, 0)
$searchPanel.Size = New-Object System.Drawing.Size(770, 50)
$searchPanel.BackColor = [System.Drawing.Color]::FromArgb(37, 37, 38)
$searchPanel.Visible = $false  # Standardmäßig ausgeblendet
$mainContentPanel.Controls.Add($searchPanel)

# View-Größen-Buttons (Rechts im Search-Panel)
$script:currentTileSize = "Medium"  # Default: Medium

$viewButtonSize = New-Object System.Drawing.Size(35, 25)
$viewButtonY = 12
$viewButtonX = 730

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
    $script:currentTileSize = "Large"
    Update-TileViewButtons
    $null = Update-ToolsDisplay -WrapPanel $toolWrapPanel -Category $script:currentDownloadCategory -MainProgressBar $progressBar -SearchQuery $searchTextBox.Text -TileSize $script:currentTileSize
})
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
    $script:currentTileSize = "Medium"
    Update-TileViewButtons
    $null = Update-ToolsDisplay -WrapPanel $toolWrapPanel -Category $script:currentDownloadCategory -MainProgressBar $progressBar -SearchQuery $searchTextBox.Text -TileSize $script:currentTileSize
})
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
    $script:currentTileSize = "List"
    Update-TileViewButtons
    $null = Update-ToolsDisplay -WrapPanel $toolWrapPanel -Category $script:currentDownloadCategory -MainProgressBar $progressBar -SearchQuery $searchTextBox.Text -TileSize $script:currentTileSize
})
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

# Info-Text für Suchergebnisse
$searchResultLabel = New-Object System.Windows.Forms.Label
$searchResultLabel.Location = New-Object System.Drawing.Point(420, 15)
$searchResultLabel.Size = New-Object System.Drawing.Size(300, 20)
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
    $searchQuery = $searchTextBox.Text
    
    # Aktualisiere Suchergebnis-Label und Tool-Anzeige
    if ([string]::IsNullOrWhiteSpace($searchQuery)) {
        $searchResultLabel.Text = ""
        # Zeige alle Tools ohne Filter
        $resultCount = Update-ToolsDisplay -WrapPanel $toolWrapPanel -Category $script:currentDownloadCategory -MainProgressBar $progressBar -SearchQuery "" -TileSize $script:currentTileSize
    }
    elseif ($searchQuery.Length -lt 3) {
        # Zu kurzer Suchbegriff
        $searchResultLabel.Text = "Mindestens 3 Zeichen eingeben"
        $searchResultLabel.ForeColor = [System.Drawing.Color]::Orange
        # Übergebe den aktuellen Suchbegriff, damit Update-ToolsDisplay die Tools ausblendet
        $resultCount = Update-ToolsDisplay -WrapPanel $toolWrapPanel -Category $script:currentDownloadCategory -MainProgressBar $progressBar -SearchQuery $searchQuery -TileSize $script:currentTileSize
    }
    else {
        # Suche mit mindestens 3 Zeichen
        $resultCount = Update-ToolsDisplay -WrapPanel $toolWrapPanel -Category $script:currentDownloadCategory -MainProgressBar $progressBar -SearchQuery $searchQuery -TileSize $script:currentTileSize
        
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
        [scriptblock]$OnExpand
    )
    
    # Container für den gesamten zusammenklappbaren Bereich
    $container = New-Object System.Windows.Forms.Panel
    $container.Location = New-Object System.Drawing.Point(5, $YPosition)
    $container.Size = New-Object System.Drawing.Size(175, 35)  # Initial nur Header sichtbar
    $container.BackColor = [System.Drawing.Color]::Transparent
    $container.Tag = $Tag
    
    # Header-Button (mit Icon und Text)
    $headerBtn = New-Object System.Windows.Forms.Button
    $headerBtn.Text = $Title  # Nur der Titel
    $headerBtn.Size = New-Object System.Drawing.Size(175, 35)
    $headerBtn.Location = New-Object System.Drawing.Point(0, 0)
    $headerBtn.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $headerBtn.BackColor = [System.Drawing.Color]::FromArgb(37, 37, 38)  # Dunkleres Grau wie im Screenshot
    $headerBtn.ForeColor = [System.Drawing.Color]::White
    $headerBtn.FlatAppearance.BorderSize = 0
    $headerBtn.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $headerBtn.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
    $headerBtn.Padding = New-Object System.Windows.Forms.Padding(5, 0, 25, 0)  # Rechts Platz für Pfeil
    $headerBtn.Tag = "collapsed"
    
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
    $arrowLabel.Location = New-Object System.Drawing.Point(155, 7.5)  # Rechts im Button
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
    $contentPanel.Location = New-Object System.Drawing.Point(0, 35)
    $contentPanel.Size = New-Object System.Drawing.Size(175, 0)  # Höhe wird dynamisch angepasst
    $contentPanel.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)  # Noch dunkler für Content
    $contentPanel.Visible = $false
    
   
    # Toggle-Funktion mit Closure für Variable-Zugriff
    $clickHandler = {
        param($eventSender, $e)
        
        if ($this.Tag -eq "collapsed") {
            # Konsole automatisch ausblenden wenn Dropdown geöffnet wird
            Hide-ConsoleAutomatically
            
            # Update Toggle-Button Status
            if ($btnToggleConsole) {
                $btnToggleConsole.Text = "►"
                $btnToggleConsole.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
            }
            
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
    $panelIndex = 0
    foreach ($panel in $ParentPanel.Controls | Where-Object { $_ -is [System.Windows.Forms.Panel] } | Sort-Object { $_.Location.Y }) {
        $panel.Location = New-Object System.Drawing.Point(5, $currentY)
        $currentY += $panel.Height + 5  # 5px Abstand zwischen Panels
        
        # Nach dem 4. Panel (Bereinigung) Trennlinie positionieren und extra Abstand einfügen
        $panelIndex++
        if ($panelIndex -eq 4) {
            # Trennlinie dynamisch positionieren
            if ($script:separatorLine) {
                $separatorY = $currentY + 8
                $script:separatorLine.Location = New-Object System.Drawing.Point(10, $separatorY)
                $script:separatorLine.BringToFront()
            }
            $currentY += 20  # Extra Abstand zwischen Bereinigung und Informationen
        }
    }
}

# System & Sicherheit Panel
$systemPanel = New-CollapsiblePanel -Title "System/Sicherheit" -YPosition 5 -Tag "systemPanel" -ParentPanel $mainButtonPanel -OnExpand {
    # Alle Content-Panels ausblenden beim Öffnen des Dropdown-Menüs
    $global:tblSystem.Visible = $false
    $tblDisk.Visible = $false
    $tblNetwork.Visible = $false
    $tblCleanup.Visible = $false
    
    # Suchfeld ausblenden (nur für Downloads)
    if ($searchPanel) { $searchPanel.Visible = $false }
    
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
    $outputBox.AppendText("🛡️ SICHERHEIT:`r`n")
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Info'
    $outputBox.AppendText("  • Windows Defender     - Quick/Full/Custom/Offline Scans`r`n")
    $outputBox.AppendText("  • Defender Restart     - Neustart des Windows Defender-Dienstes`r`n")
    $outputBox.AppendText("  • MRT Quick Scan       - Schnelle Malware-Erkennung (Microsoft Tool)`r`n")
    $outputBox.AppendText("  • MRT Full Scan        - Vollständige Systemprüfung auf Schadsoftware`r`n`r`n")
    
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Accent'
    $outputBox.AppendText("🔧 WARTUNG:`r`n")
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Info'
    $outputBox.AppendText("  • SFC Check            - System File Checker für beschädigte Dateien`r`n")
    $outputBox.AppendText("  • Memory Diagnostic    - Arbeitsspeicher-Test (erfordert Neustart)`r`n`r`n")
    
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Muted'
    $outputBox.AppendText("💡 Tipp: Wählen Sie eine Kategorie oben aus, um die Tools anzuzeigen.`r`n")
    
    # Stelle sicher, dass OutputView angezeigt wird
    Switch-OutputView -viewName "outputView"
    
    # Hinweis: Content-Panel wird erst durch Klick auf Sub-Button sichtbar
    $script:currentMainView = "systemView"
    
    # Header-Buttons visuell aktualisieren
    $systemPanel.Header.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
    if ($diskPanel) { $diskPanel.Header.BackColor = [System.Drawing.Color]::FromArgb(37, 37, 38) }
    if ($networkPanel) { $networkPanel.Header.BackColor = [System.Drawing.Color]::FromArgb(37, 37, 38) }
    if ($cleanupPanel) { $cleanupPanel.Header.BackColor = [System.Drawing.Color]::FromArgb(37, 37, 38) }
}

# Content (Untermenü-Buttons) hinzufügen
$btnSystemSecurity = New-Object System.Windows.Forms.Button
$btnSystemSecurity.Text = "Sicherheit"
$btnSystemSecurity.Size = New-Object System.Drawing.Size(175, 35)
$btnSystemSecurity.Location = New-Object System.Drawing.Point(0, 0)
$btnSystemSecurity.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnSystemSecurity.BackColor = [System.Drawing.Color]::FromArgb(37, 37, 38)  # Inaktiv beim Start
$btnSystemSecurity.ForeColor = [System.Drawing.Color]::White
$btnSystemSecurity.FlatAppearance.BorderSize = 0
$btnSystemSecurity.FlatAppearance.MouseOverBackColor = [System.Drawing.Color]::FromArgb(55, 55, 55)  # Hover-Effekt
$btnSystemSecurity.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$btnSystemSecurity.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$btnSystemSecurity.Add_Click({
    $script:securityControlsVisible = $true
    $script:maintenanceControlsVisible = $false
    $script:currentSystemView = "securityView"
    
    # MainContentPanel sichtbar machen
    $global:tblSystem.Visible = $true
    
    # Toggle-Funktion aufrufen um Buttons anzuzeigen
    Switch-SystemControls
    
    # Visuelles Feedback - Aktiver Button heller, inaktiver dunkler
    $btnSystemSecurity.BackColor = [System.Drawing.Color]::FromArgb(55, 55, 55)
    $btnSystemMaintenance.BackColor = [System.Drawing.Color]::FromArgb(37, 37, 38)
})
$systemPanel.Content.Controls.Add($btnSystemSecurity)

$btnSystemMaintenance = New-Object System.Windows.Forms.Button
$btnSystemMaintenance.Text = "Wartung"
$btnSystemMaintenance.Size = New-Object System.Drawing.Size(175, 35)
$btnSystemMaintenance.Location = New-Object System.Drawing.Point(0, 35)
$btnSystemMaintenance.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnSystemMaintenance.BackColor = [System.Drawing.Color]::FromArgb(37, 37, 38)  # Inaktiv beim Start
$btnSystemMaintenance.ForeColor = [System.Drawing.Color]::White
$btnSystemMaintenance.FlatAppearance.BorderSize = 0
$btnSystemMaintenance.FlatAppearance.MouseOverBackColor = [System.Drawing.Color]::FromArgb(55, 55, 55)  # Hover-Effekt
$btnSystemMaintenance.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$btnSystemMaintenance.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$btnSystemMaintenance.Add_Click({
    $script:securityControlsVisible = $false
    $script:maintenanceControlsVisible = $true
    $script:currentSystemView = "maintenanceView"
    
    # MainContentPanel sichtbar machen
    $global:tblSystem.Visible = $true
    
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
$diskPanel = New-CollapsiblePanel -Title "Diagnose/Reparatur" -YPosition 45 -Tag "diskPanel" -ParentPanel $mainButtonPanel -OnExpand {
    # Alle Content-Panels ausblenden beim Öffnen des Dropdown-Menüs
    $global:tblSystem.Visible = $false
    $tblDisk.Visible = $false
    $tblNetwork.Visible = $false
    $tblCleanup.Visible = $false
    
    # Suchfeld ausblenden (nur für Downloads)
    if ($searchPanel) { $searchPanel.Visible = $false }
    
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
    $outputBox.AppendText("🔍 DISM (SYSTEM-IMAGE):`r`n")
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Info'
    $outputBox.AppendText("  • DISM Check Health    - Schnelle Integritätsprüfung`r`n")
    $outputBox.AppendText("  • DISM Scan Health     - Detaillierte Analyse`r`n")
    $outputBox.AppendText("  • DISM Restore Health  - Automatische Reparatur`r`n`r`n")
    
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Accent'
    $outputBox.AppendText("💾 CHKDSK (FESTPLATTEN):`r`n")
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Info'
    $outputBox.AppendText("  • CHKDSK (Scan)        - Nur Überprüfung (ohne Reparatur)`r`n")
    $outputBox.AppendText("  • CHKDSK /F            - Reparatur (erfordert Neustart)`r`n")
    $outputBox.AppendText("  • CHKDSK /R            - Erweiterte Reparatur + Bad-Sector-Suche`r`n`r`n")
    
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Warning'
    $outputBox.AppendText("⚠️  HINWEIS: CHKDSK-Reparaturen erfordern oft einen Neustart.`r`n")
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Muted'
    $outputBox.AppendText("💡 Tipp: Wählen Sie eine Kategorie oben aus, um die Tools anzuzeigen.`r`n")
    
    # Stelle sicher, dass OutputView angezeigt wird
    Switch-OutputView -viewName "outputView"
    
    # Hinweis: Content-Panel wird erst durch Klick auf Sub-Button sichtbar
    $script:currentMainView = "diskView"
    
    # Header-Buttons visuell aktualisieren
    if ($systemPanel) { $systemPanel.Header.BackColor = [System.Drawing.Color]::FromArgb(37, 37, 38) }
    $diskPanel.Header.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
    if ($networkPanel) { $networkPanel.Header.BackColor = [System.Drawing.Color]::FromArgb(37, 37, 38) }
    if ($cleanupPanel) { $cleanupPanel.Header.BackColor = [System.Drawing.Color]::FromArgb(37, 37, 38) }
}

$btnDiskDiagnose = New-Object System.Windows.Forms.Button
$btnDiskDiagnose.Text = "Diagnose"
$btnDiskDiagnose.Size = New-Object System.Drawing.Size(175, 35)
$btnDiskDiagnose.Location = New-Object System.Drawing.Point(0, 0)
$btnDiskDiagnose.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnDiskDiagnose.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
$btnDiskDiagnose.ForeColor = [System.Drawing.Color]::White
$btnDiskDiagnose.FlatAppearance.BorderSize = 0
$btnDiskDiagnose.FlatAppearance.MouseOverBackColor = [System.Drawing.Color]::FromArgb(55, 55, 55)
$btnDiskDiagnose.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$btnDiskDiagnose.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$btnDiskDiagnose.Add_Click({
    $script:currentDiskView = "diagnoseView"
    $script:diagnoseControlsVisible = $true
    $script:repairControlsVisible = $false
    
    # MainContentPanel sichtbar machen
    $tblDisk.Visible = $true
    
    # Toggle-Funktion aufrufen um Buttons anzuzeigen
    Switch-DiskControls
    
    # Visuelles Feedback
    $btnDiskDiagnose.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
    $btnDiskRepair.BackColor = [System.Drawing.Color]::FromArgb( 43, 43, 43)
})
$diskPanel.Content.Controls.Add($btnDiskDiagnose)

$btnDiskRepair = New-Object System.Windows.Forms.Button
$btnDiskRepair.Text = "Reparatur"
$btnDiskRepair.Size = New-Object System.Drawing.Size(175, 35)
$btnDiskRepair.Location = New-Object System.Drawing.Point(0, 35)
$btnDiskRepair.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnDiskRepair.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
$btnDiskRepair.ForeColor = [System.Drawing.Color]::White
$btnDiskRepair.FlatAppearance.BorderSize = 0
$btnDiskRepair.FlatAppearance.MouseOverBackColor = [System.Drawing.Color]::FromArgb(55, 55, 55)
$btnDiskRepair.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$btnDiskRepair.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$btnDiskRepair.Add_Click({
    $script:currentDiskView = "repairView"
    $script:diagnoseControlsVisible = $false
    $script:repairControlsVisible = $true
    
    # MainContentPanel sichtbar machen
    $tblDisk.Visible = $true
    
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
$networkPanel = New-CollapsiblePanel -Title "Netzwerk-Tools" -YPosition 85 -Tag "networkPanel" -ParentPanel $mainButtonPanel -OnExpand {
    # Alle Content-Panels ausblenden beim Öffnen des Dropdown-Menüs
    $global:tblSystem.Visible = $false
    $tblDisk.Visible = $false
    $tblNetwork.Visible = $false
    $tblCleanup.Visible = $false
    
    # Suchfeld ausblenden (nur für Downloads)
    if ($searchPanel) { $searchPanel.Visible = $false }
    
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
    $outputBox.AppendText("🔍 NETZWERK-DIAGNOSE:`r`n")
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Info'
    $outputBox.AppendText("  • Ping Test            - Konnektivitätstests zu beliebigen Hosts`r`n")
    $outputBox.AppendText("                           (Konfigurierbar: Anzahl, Timeout, Buffer-Größe)`r`n`r`n")
    
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Accent'
    $outputBox.AppendText("🔧 NETZWERK-REPARATUR:`r`n")
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Info'
    $outputBox.AppendText("  • Netzwerk zurücksetzen- Vollständiger Reset des Netzwerkadapters`r`n")
    $outputBox.AppendText("                           (Deaktivieren und wieder aktivieren)`r`n`r`n")
    
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Muted'
    $outputBox.AppendText("💡 Tipp: Wählen Sie eine Kategorie oben aus, um die Tools anzuzeigen.`r`n")
    
    # Stelle sicher, dass OutputView angezeigt wird
    Switch-OutputView -viewName "outputView"
    
    # Hinweis: Content-Panel wird erst durch Klick auf Sub-Button sichtbar
    $script:currentMainView = "networkView"
    
    # Header-Buttons visuell aktualisieren
    if ($systemPanel) { $systemPanel.Header.BackColor = [System.Drawing.Color]::FromArgb(37, 37, 38) }
    if ($diskPanel) { $diskPanel.Header.BackColor = [System.Drawing.Color]::FromArgb(37, 37, 38) }
    $networkPanel.Header.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
    if ($cleanupPanel) { $cleanupPanel.Header.BackColor = [System.Drawing.Color]::FromArgb(37, 37, 38) }
}

$btnNetworkDiagnose = New-Object System.Windows.Forms.Button
$btnNetworkDiagnose.Text = "Netzwerk-Diagnose"
$btnNetworkDiagnose.Size = New-Object System.Drawing.Size(175, 35)
$btnNetworkDiagnose.Location = New-Object System.Drawing.Point(0, 0)
$btnNetworkDiagnose.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnNetworkDiagnose.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
$btnNetworkDiagnose.ForeColor = [System.Drawing.Color]::White
$btnNetworkDiagnose.FlatAppearance.BorderSize = 0
$btnNetworkDiagnose.FlatAppearance.MouseOverBackColor = [System.Drawing.Color]::FromArgb(55, 55, 55)
$btnNetworkDiagnose.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$btnNetworkDiagnose.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$btnNetworkDiagnose.Add_Click({
    $script:currentNetworkView = "diagnoseView"
    $script:networkDiagnosticsControlsVisible = $true
    $script:networkRepairControlsVisible = $false
    
    # MainContentPanel sichtbar machen
    $tblNetwork.Visible = $true
    
    # Toggle-Funktion aufrufen um Buttons anzuzeigen
    Switch-NetworkControls
    
    # Visuelles Feedback
    $btnNetworkDiagnose.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
    $btnNetworkRepair.BackColor = [System.Drawing.Color]::FromArgb( 43, 43, 43)
})
$networkPanel.Content.Controls.Add($btnNetworkDiagnose)

$btnNetworkRepair = New-Object System.Windows.Forms.Button
$btnNetworkRepair.Text = "Netzwerk-Reparatur"
$btnNetworkRepair.Size = New-Object System.Drawing.Size(175, 35)
$btnNetworkRepair.Location = New-Object System.Drawing.Point(0, 35)
$btnNetworkRepair.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnNetworkRepair.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
$btnNetworkRepair.ForeColor = [System.Drawing.Color]::White
$btnNetworkRepair.FlatAppearance.BorderSize = 0
$btnNetworkRepair.FlatAppearance.MouseOverBackColor = [System.Drawing.Color]::FromArgb(55, 55, 55)
$btnNetworkRepair.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$btnNetworkRepair.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$btnNetworkRepair.Add_Click({
    $script:currentNetworkView = "repairView"
    $script:networkDiagnosticsControlsVisible = $false
    $script:networkRepairControlsVisible = $true
    
    # MainContentPanel sichtbar machen
    $tblNetwork.Visible = $true
    
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
$cleanupPanel = New-CollapsiblePanel -Title "Bereinigung" -YPosition 125 -Tag "cleanupPanel" -ParentPanel $mainButtonPanel -OnExpand {
    # Alle Content-Panels ausblenden beim Öffnen des Dropdown-Menüs
    $global:tblSystem.Visible = $false
    $tblDisk.Visible = $false
    $tblNetwork.Visible = $false
    $tblCleanup.Visible = $false
    
    # Suchfeld ausblenden (nur für Downloads)
    if ($searchPanel) { $searchPanel.Visible = $false }
    
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
    $outputBox.AppendText("🧹 VERFÜGBARE BEREINIGUNGEN:`r`n")
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Info'
    $outputBox.AppendText("  • Temp-Dateien (Einfach)  - Löscht TEMP-Ordner (%TEMP%, Windows\Temp)`r`n")
    $outputBox.AppendText("  • Temp-Dateien (Erweitert)- Umfassend: TEMP, Prefetch, Browser-Cache`r`n")
    $outputBox.AppendText("  • Disk Cleanup            - Windows-eigenes Bereinigungs-Tool`r`n")
    $outputBox.AppendText("  • Cleanup-Übersicht       - Interaktive Auswahlmaske mit Vorschau`r`n`r`n")
    
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Success'
    $outputBox.AppendText("💾 Potenzieller Speicherplatz-Gewinn: 2-10 GB (je nach System)`r`n")
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Muted'
    $outputBox.AppendText("💡 Tipp: Klicken Sie auf einen Button, um die Bereinigung zu starten.`r`n")
    
    # Stelle sicher, dass OutputView angezeigt wird
    Switch-OutputView -viewName "outputView"
    
    # Hinweis: Content-Panel wird erst durch Klick auf Sub-Button sichtbar
    $script:currentMainView = "cleanupView"
    
    # Header-Buttons visuell aktualisieren
    if ($systemPanel) { $systemPanel.Header.BackColor = [System.Drawing.Color]::FromArgb(37, 37, 38) }
    if ($diskPanel) { $diskPanel.Header.BackColor = [System.Drawing.Color]::FromArgb(37, 37, 38) }
    if ($networkPanel) { $networkPanel.Header.BackColor = [System.Drawing.Color]::FromArgb(37, 37, 38) }
    $cleanupPanel.Header.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
}

$btnCleanupSystem = New-Object System.Windows.Forms.Button
$btnCleanupSystem.Text = "System-Bereinigung"
$btnCleanupSystem.Size = New-Object System.Drawing.Size(175, 35)
$btnCleanupSystem.Location = New-Object System.Drawing.Point(0, 0)
$btnCleanupSystem.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnCleanupSystem.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
$btnCleanupSystem.ForeColor = [System.Drawing.Color]::White
$btnCleanupSystem.FlatAppearance.BorderSize = 0
$btnCleanupSystem.FlatAppearance.MouseOverBackColor = [System.Drawing.Color]::FromArgb(55, 55, 55)
$btnCleanupSystem.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$btnCleanupSystem.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$btnCleanupSystem.Add_Click({
    $script:currentCleanupView = "systemCleanupView"
    $script:cleanupSystemControlsVisible = $true
    $script:cleanupTempControlsVisible = $false
    
    # MainContentPanel sichtbar machen
    $tblCleanup.Visible = $true
    
    # Toggle-Funktion aufrufen um Buttons anzuzeigen
    Switch-CleanupControls
    
    # Visuelles Feedback
    $btnCleanupSystem.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
    $btnCleanupTemp.BackColor = [System.Drawing.Color]::FromArgb( 43, 43, 43)
})
$cleanupPanel.Content.Controls.Add($btnCleanupSystem)

$btnCleanupTemp = New-Object System.Windows.Forms.Button
$btnCleanupTemp.Text = "Temp-Dateien"
$btnCleanupTemp.Size = New-Object System.Drawing.Size(175, 35)
$btnCleanupTemp.Location = New-Object System.Drawing.Point(0, 35)
$btnCleanupTemp.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnCleanupTemp.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
$btnCleanupTemp.ForeColor = [System.Drawing.Color]::White
$btnCleanupTemp.FlatAppearance.BorderSize = 0
$btnCleanupTemp.FlatAppearance.MouseOverBackColor = [System.Drawing.Color]::FromArgb(55, 55, 55)
$btnCleanupTemp.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$btnCleanupTemp.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$btnCleanupTemp.Add_Click({
    $script:currentCleanupView = "tempFilesView"
    $script:cleanupSystemControlsVisible = $false
    $script:cleanupTempControlsVisible = $true
    
    # MainContentPanel sichtbar machen
    $tblCleanup.Visible = $true
    
    # Toggle-Funktion aufrufen um Buttons anzuzeigen
    Switch-CleanupControls
    
    # Visuelles Feedback
    $btnCleanupSystem.BackColor = [System.Drawing.Color]::FromArgb( 43, 43, 43)
    $btnCleanupTemp.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
})
$cleanupPanel.Content.Controls.Add($btnCleanupTemp)

$cleanupPanel.Content.Height = 70  # 2 Buttons × 35px
$mainButtonPanel.Controls.Add($cleanupPanel.Container)

# Trennlinie zwischen Bereinigung und Informationen
$script:separatorLine = New-Object System.Windows.Forms.Label
$script:separatorLine.Location = New-Object System.Drawing.Point(10, 173)
$script:separatorLine.Size = New-Object System.Drawing.Size(160, 1)
$script:separatorLine.BackColor = [System.Drawing.Color]::FromArgb(80, 80, 80)
$script:separatorLine.BorderStyle = [System.Windows.Forms.BorderStyle]::None
$mainButtonPanel.Controls.Add($script:separatorLine)
$script:separatorLine.BringToFront()

# Alte Button-Referenzen für Kompatibilität beibehalten
$btnSystem = $systemPanel.Header
$btnDisk = $diskPanel.Header
$btnNetwork = $networkPanel.Header
$btnCleanup = $cleanupPanel.Header

# Hilfsvariable für aktive Hauptansicht
$script:currentMainView = "systemView"

# Content-Panels für die verschiedenen Bereiche direkt im mainContentPanel erstellen
$global:tblSystem = New-Object System.Windows.Forms.Panel
$global:tblSystem.Location = New-Object System.Drawing.Point(0, 0)
$global:tblSystem.Size = New-Object System.Drawing.Size(770, 230)  # Breite erhöht für 3 Buttons nebeneinander (3 × 175px = 525px + Rand)
$global:tblSystem.BackColor = [System.Drawing.Color]::Transparent
$global:tblSystem.Visible = $false
$mainContentPanel.Controls.Add($global:tblSystem)

# Definiere Variablen für die Sichtbarkeitsstatus (wird später für Button-Klicks verwendet)
$script:securityControlsVisible = $false
$script:maintenanceControlsVisible = $false

$tblDisk = New-Object System.Windows.Forms.Panel
$tblDisk.Location = New-Object System.Drawing.Point(0, 0)
$tblDisk.Size = New-Object System.Drawing.Size(770, 230)  # Breite erhöht für 3 Buttons nebeneinander (3 × 175px = 525px + Rand)
$tblDisk.BackColor = [System.Drawing.Color]::Transparent
$tblDisk.Visible = $false
$mainContentPanel.Controls.Add($tblDisk)

$tblNetwork = New-Object System.Windows.Forms.Panel
$tblNetwork.Location = New-Object System.Drawing.Point(0, 0)
$tblNetwork.Size = New-Object System.Drawing.Size(770, 230)  # Breite erhöht für horizontale Button-Anordnung
$tblNetwork.BackColor = [System.Drawing.Color]::Transparent
$tblNetwork.Visible = $false
$mainContentPanel.Controls.Add($tblNetwork)

$tblCleanup = New-Object System.Windows.Forms.Panel
$tblCleanup.Location = New-Object System.Drawing.Point(0, 0)
$tblCleanup.Size = New-Object System.Drawing.Size(770, 230)  # Breite erhöht für horizontale Button-Anordnung
$tblCleanup.BackColor = [System.Drawing.Color]::Transparent
$tblCleanup.Visible = $false
$mainContentPanel.Controls.Add($tblCleanup)

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
# Event-Handler hinzufügen
$btnCleanupSystem.Add_Click({
    $script:cleanupSystemControlsVisible = $true
    $script:cleanupTempControlsVisible = $false
    
    $btnCleanupSystem.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
    $btnCleanupTemp.BackColor = [System.Drawing.Color]::FromArgb( 43, 43, 43)
    
    $script:currentCleanupView = "cleanupSystemView"
    Switch-CleanupControls
})

$btnCleanupTemp.Add_Click({
    $script:cleanupSystemControlsVisible = $false
    $script:cleanupTempControlsVisible = $true
    
    $btnCleanupSystem.BackColor = [System.Drawing.Color]::FromArgb( 43, 43, 43)
    $btnCleanupTemp.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
    
    $script:currentCleanupView = "cleanupTempView"
    Switch-CleanupControls
})

# tblCleanup wurde bereits weiter oben erstellt und zum mainContentPanel hinzugefügt

# Erstelle ein Panel für die verschiedenen Ausgabebereiche - direkt im mainform
$outputPanel = New-Object System.Windows.Forms.Panel
$outputPanel.Location = New-Object System.Drawing.Point(190, 180)  # 50 Pixel nach oben verschoben (230 - 50 = 180)
$outputPanel.Size = New-Object System.Drawing.Size(800, 560)  # Breite um 10 Pixel erhöht (790 + 10 = 800)
$outputPanel.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)  # Dunkles Grau wie Hauptfenster
$mainform.Controls.Add($outputPanel)

# PowerShell-Konsolenfenster-Steuerung mit P/Invoke (nach der Logo-Funktion, vor den Modul-Importen)
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
            # Breite: gleich wie GUI ClientSize
            # Höhe: 70% der GUI ClientSize
            $consoleWidth = [int]($mainform.ClientSize.Width)
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
                            $consoleWidth = [int]($mainform.ClientSize.Width)
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

# PowerShell-Toggle-Button (VOR dem Ausgabe-Button)
$btnToggleConsole = New-Object System.Windows.Forms.Button
$btnToggleConsole.Text = "◄"  # Pfeil nach links
$btnToggleConsole.Size = New-Object System.Drawing.Size(25, 35)
$btnToggleConsole.Location = New-Object System.Drawing.Point(5, 5)
$btnToggleConsole.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnToggleConsole.FlatAppearance.BorderSize = 0
$btnToggleConsole.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
$btnToggleConsole.ForeColor = [System.Drawing.Color]::White
$btnToggleConsole.Font = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)

# Runde Ecken nur links für Toggle-Button (4px Radius für Konsistenz mit Panel-Headers)
$toggleRegion = [System.Drawing.Drawing2D.GraphicsPath]::new()
$toggleRect = New-Object System.Drawing.Rectangle(0, 0, $btnToggleConsole.Width, $btnToggleConsole.Height)
$toggleRadius = 4
# Linke obere Ecke rund
$toggleRegion.AddArc($toggleRect.Left, $toggleRect.Top, ($toggleRadius * 2), ($toggleRadius * 2), 180, 90)
# Obere Seite gerade nach rechts
$toggleRegion.AddLine(($toggleRect.Left + $toggleRadius), $toggleRect.Top, $toggleRect.Right, $toggleRect.Top)
# Rechte Seite gerade runter
$toggleRegion.AddLine($toggleRect.Right, $toggleRect.Top, $toggleRect.Right, $toggleRect.Bottom)
# Untere Seite gerade nach links
$toggleRegion.AddLine($toggleRect.Right, $toggleRect.Bottom, ($toggleRect.Left + $toggleRadius), $toggleRect.Bottom)
# Linke untere Ecke rund
$toggleRegion.AddArc($toggleRect.Left, ($toggleRect.Bottom - ($toggleRadius * 2)), ($toggleRadius * 2), ($toggleRadius * 2), 90, 90)
# Linke Seite gerade hoch
$toggleRegion.AddLine($toggleRect.Left, ($toggleRect.Bottom - $toggleRadius), $toggleRect.Left, ($toggleRect.Top + $toggleRadius))
$toggleRegion.CloseFigure()
$btnToggleConsole.Region = New-Object System.Drawing.Region($toggleRegion)

$btnToggleConsole.Add_Click({
    # Direkt ohne Timer - vermeidet Race Conditions
    try {
        $visible = Switch-ConsoleVisibility
        
        # Update Button-Status
        if ($visible) {
            $btnToggleConsole.BackColor = [System.Drawing.Color]::FromArgb(55, 55, 55)  # Hellgrau wenn Konsole sichtbar
            $btnToggleConsole.Text = "◄"  # Pfeil nach links
            if ($tooltipObj) {
                $tooltipObj.SetToolTip($btnToggleConsole, "PowerShell-Konsole ausblenden")
            }
        }
        else {
            $btnToggleConsole.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)  # Dunkelgrau wenn versteckt
            $btnToggleConsole.Text = "►"  # Pfeil nach rechts
            if ($tooltipObj) {
                $tooltipObj.SetToolTip($btnToggleConsole, "PowerShell-Konsole einblenden")
            }
        }
        
        # Region neu setzen um runde Ecken zu erhalten
        $toggleRegion = [System.Drawing.Drawing2D.GraphicsPath]::new()
        $toggleRect = New-Object System.Drawing.Rectangle(0, 0, $btnToggleConsole.Width, $btnToggleConsole.Height)
        $toggleRadius = 4
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
    }
    catch {
        # Ignoriere Fehler beim Hover
    }
})
$btnToggleConsole.Add_MouseLeave({ 
    try {
        if ([ConsoleHelper]::IsConsoleVisible()) {
            $this.BackColor = [System.Drawing.Color]::FromArgb(55, 55, 55)
        }
        else {
            $this.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
        }
    }
    catch {
        # Ignoriere Fehler beim Hover
    }
})
$outputButtonPanel.Controls.Add($btnToggleConsole)

# Tooltip für PowerShell-Toggle-Button
if ($tooltipObj) {
    $tooltipObj.SetToolTip($btnToggleConsole, "PowerShell-Konsole ein-/ausblenden`r`n(oder drücken Sie F12)")
}

# Definiere den Ausgabe-Button im separaten outputButtonPanel (Position angepasst)
$btnOutput = New-Object System.Windows.Forms.Button
$btnOutput.Text = "Ausgabe"
$btnOutput.Size = New-Object System.Drawing.Size(145, 35)
$btnOutput.Location = New-Object System.Drawing.Point(32, 5)  # X-Position angepasst (5 + 35 + 5 = 45)
$btnOutput.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnOutput.FlatAppearance.BorderSize = 0
$btnOutput.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
$btnOutput.ForeColor = [System.Drawing.Color]::White
$btnOutput.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$btnOutput.Tag = "outputView"

# Runde Ecken nur rechts für Ausgabe-Button (4px Radius für Konsistenz mit Panel-Headers)
$outputRegion = [System.Drawing.Drawing2D.GraphicsPath]::new()
$outputRect = New-Object System.Drawing.Rectangle(0, 0, $btnOutput.Width, $btnOutput.Height)
$outputRadius = 4
# Linke Seite gerade
$outputRegion.AddLine($outputRect.Left, $outputRect.Top, $outputRect.Right - $outputRadius, $outputRect.Top)
# Rechte obere Ecke rund
$outputRegion.AddArc(($outputRect.Right - ($outputRadius * 2)), $outputRect.Top, ($outputRadius * 2), ($outputRadius * 2), 270, 90)
# Rechte Seite
$outputRegion.AddLine($outputRect.Right, ($outputRect.Top + $outputRadius), $outputRect.Right, ($outputRect.Bottom - $outputRadius))
# Rechte untere Ecke rund
$outputRegion.AddArc(($outputRect.Right - ($outputRadius * 2)), ($outputRect.Bottom - ($outputRadius * 2)), ($outputRadius * 2), ($outputRadius * 2), 0, 90)
# Untere Seite gerade zurück
$outputRegion.AddLine(($outputRect.Right - $outputRadius), $outputRect.Bottom, $outputRect.Left, $outputRect.Bottom)
# Linke Seite gerade hoch
$outputRegion.AddLine($outputRect.Left, $outputRect.Bottom, $outputRect.Left, $outputRect.Top)
$outputRegion.CloseFigure()
$btnOutput.Region = New-Object System.Drawing.Region($outputRegion)

$outputButtonPanel.Controls.Add($btnOutput)

# Erstelle Collapsible Panel für Informationen
$infoPanel = New-CollapsiblePanel -Title "Informationen" -YPosition 185 -Tag "infoPanel" -ParentPanel $mainButtonPanel -OnExpand {
    # Alle View-Panels ausblenden beim Öffnen des Dropdown-Menüs
    if ($outputViewPanel) { $outputViewPanel.Visible = $false }
    if ($statusViewPanel) { $statusViewPanel.Visible = $false }
    if ($hardwareViewPanel) { $hardwareViewPanel.Visible = $false }
    if ($toolInfoViewPanel) { $toolInfoViewPanel.Visible = $false }
    if ($downloadsViewPanel) { $downloadsViewPanel.Visible = $false }
    
    # Suchfeld ausblenden (nur für Downloads)
    if ($searchPanel) { $searchPanel.Visible = $false }
    
    # Stelle sicher, dass OutputView sichtbar ist
    if ($outputViewPanel) { $outputViewPanel.Visible = $true }
    
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
    $outputBox.AppendText("📊 STATUS-INFO:`r`n")
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Info'
    $outputBox.AppendText("  • Umfassende Systemstatus-Übersicht mit Live-Updates`r`n")
    $outputBox.AppendText("  • Betriebssystem-Details (Version, Build, Lizenz-Status)`r`n")
    $outputBox.AppendText("  • Uptime und letzte Boot-Zeit`r`n")
    $outputBox.AppendText("  • Installierte Updates und Hotfixes`r`n")
    $outputBox.AppendText("  • Laufwerks-Status und verfügbarer Speicherplatz`r`n`r`n")
    
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Accent'
    $outputBox.AppendText("🖥️ HARDWARE-INFO:`r`n")
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Info'
    $outputBox.AppendText("  • CPU: Prozessor-Spezifikationen (Kerne, Takt, Cache, Architektur)`r`n")
    $outputBox.AppendText("  • RAM: Arbeitsspeicher-Module, Kapazität und Auslastung`r`n")
    $outputBox.AppendText("  • GPU: Grafikkarten-Details und Video-RAM`r`n")
    $outputBox.AppendText("  • Mainboard: Hersteller, Modell und BIOS-Version`r`n")
    $outputBox.AppendText("  • Festplatten: Status, Kapazität und S.M.A.R.T.-Daten`r`n")
    $outputBox.AppendText("  • Netzwerk: Adapter-Details und IP-Konfiguration`r`n`r`n")
    
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Accent'
    $outputBox.AppendText("🔧 TOOL-INFO:`r`n")
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Info'
    $outputBox.AppendText("  • Detaillierte Beschreibungen aller verfügbaren Tools`r`n")
    $outputBox.AppendText("  • Verwendungszweck und Funktionsweise`r`n")
    $outputBox.AppendText("  • Empfohlene Anwendungsfälle`r`n")
    $outputBox.AppendText("  • Hinweise und Warnungen zu kritischen Tools`r`n`r`n")
    
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Muted'
    $outputBox.AppendText("💡 Tipp: Wählen Sie eine Info-Kategorie oben aus, um Details anzuzeigen.`r`n")
    
    # Hinweis: View-Panel wird erst durch Klick auf Info-Button sichtbar
    
    # Setze alle Header-Button-Farben zurück auf inaktiv
    $btnOutput.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
    $btnToolDownloads.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
    
    # Setze den Informationen-Header auf aktiv
    $infoPanel.Header.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
}
$mainButtonPanel.Controls.Add($infoPanel.Container)

# Setze die Content-Panel-Höhe für 3 Buttons
$infoPanel.Content.Height = 111  # 3 Buttons x 37px = 111px

# Erstelle die Info-Buttons (Status-Info, Hardware-Info, Tool-Info) direkt im Content-Panel
$btnStatusInfo = New-Object System.Windows.Forms.Button
$btnStatusInfo.Text = "Status-Info"
$btnStatusInfo.Size = New-Object System.Drawing.Size(175, 35)
$btnStatusInfo.Location = New-Object System.Drawing.Point(0, 0)
$btnStatusInfo.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnStatusInfo.FlatAppearance.BorderSize = 0
$btnStatusInfo.FlatAppearance.MouseOverBackColor = [System.Drawing.Color]::FromArgb(55, 55, 55)
$btnStatusInfo.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
$btnStatusInfo.ForeColor = [System.Drawing.Color]::White
$btnStatusInfo.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$btnStatusInfo.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$btnStatusInfo.Add_Click({
    # Wechsle zur Status-View (zeigt systemStatusBox, nicht outputBox)
    Switch-OutputView -viewName "statusView"
    
    # Visuelles Feedback
    $btnOutput.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
    $btnStatusInfo.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
    $btnHardwareInfo.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
    $btnToolInfo.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
    $btnToolDownloads.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
    
    # Status-Info laden
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
})
$infoPanel.Content.Controls.Add($btnStatusInfo)

$btnHardwareInfo = New-Object System.Windows.Forms.Button
$btnHardwareInfo.Text = "Hardware-Info"
$btnHardwareInfo.Size = New-Object System.Drawing.Size(175, 35)
$btnHardwareInfo.Location = New-Object System.Drawing.Point(0, 37)
$btnHardwareInfo.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnHardwareInfo.FlatAppearance.BorderSize = 0
$btnHardwareInfo.FlatAppearance.MouseOverBackColor = [System.Drawing.Color]::FromArgb(55, 55, 55)
$btnHardwareInfo.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
$btnHardwareInfo.ForeColor = [System.Drawing.Color]::White
$btnHardwareInfo.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$btnHardwareInfo.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$btnHardwareInfo.Add_Click({
    # Wechsle zur Hardware-View (zeigt hardwareInfoBox, nicht outputBox)
    Switch-OutputView -viewName "hardwareView"
    
    # Visuelles Feedback
    $btnOutput.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
    $btnStatusInfo.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
    $btnHardwareInfo.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
    $btnToolInfo.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
    $btnToolDownloads.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
    
    # Hardware-Informationen aktualisieren
    if (-not $script:hardwareInfoLoaded) {
        Get-HardwareInfo -infoBox $hardwareInfoBox
        $script:hardwareInfoLoaded = $true
    }
})
$infoPanel.Content.Controls.Add($btnHardwareInfo)

$btnToolInfo = New-Object System.Windows.Forms.Button
$btnToolInfo.Text = "Tool-Info"
$btnToolInfo.Size = New-Object System.Drawing.Size(175, 35)
$btnToolInfo.Location = New-Object System.Drawing.Point(0, 74)
$btnToolInfo.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnToolInfo.FlatAppearance.BorderSize = 0
$btnToolInfo.FlatAppearance.MouseOverBackColor = [System.Drawing.Color]::FromArgb(55, 55, 55)
$btnToolInfo.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
$btnToolInfo.ForeColor = [System.Drawing.Color]::White
$btnToolInfo.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$btnToolInfo.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$btnToolInfo.Add_Click({
    # Wechsle zur Tool-Info-View (zeigt toolInfoBox, nicht outputBox)
    Switch-OutputView -viewName "toolInfoView"
    
    # Visuelles Feedback
    $btnOutput.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
    $btnStatusInfo.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
    $btnHardwareInfo.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
    $btnToolInfo.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
    $btnToolDownloads.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
})
$infoPanel.Content.Controls.Add($btnToolInfo)

# Erstelle Collapsible Panel für Tool-Downloads
$downloadsPanel = New-CollapsiblePanel -Title "Tool-Downloads" -YPosition 340 -Tag "downloadsPanel" -ParentPanel $mainButtonPanel -OnExpand {
    # Alle View-Panels ausblenden beim Öffnen des Dropdown-Menüs
    if ($outputViewPanel) { $outputViewPanel.Visible = $false }
    if ($statusViewPanel) { $statusViewPanel.Visible = $false }
    if ($hardwareViewPanel) { $hardwareViewPanel.Visible = $false }
    if ($toolInfoViewPanel) { $toolInfoViewPanel.Visible = $false }
    if ($downloadsViewPanel) { $downloadsViewPanel.Visible = $false }
    
    # Suchfeld im mainContentPanel einblenden
    if ($searchPanel) { $searchPanel.Visible = $true }
    
    # Stelle sicher, dass OutputView sichtbar ist
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
    $outputBox.AppendText("🔧 SYSTEM-TOOLS (8 Tools):`r`n")
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Info'
    $outputBox.AppendText("  • 7-Zip, CCleaner, CPU-Z, GPU-Z, OCCT`r`n")
    $outputBox.AppendText("  • Intel Driver Assistant, LibreHardwareMonitor, UniGetUI`r`n`r`n")
    
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Accent'
    $outputBox.AppendText("📱 ANWENDUNGEN (6 Tools):`r`n")
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Info'
    $outputBox.AppendText("  • Browser: Brave, Firefox, Chrome`r`n")
    $outputBox.AppendText("  • Kommunikation: Discord`r`n")
    $outputBox.AppendText("  • Office: LibreOffice, Apache OpenOffice`r`n`r`n")
    
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Accent'
    $outputBox.AppendText("🎵 AUDIO / TV (9 Tools):`r`n")
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Info'
    $outputBox.AppendText("  • Media: VLC, Spotify, OBS Studio, Sky Go`r`n")
    $outputBox.AppendText("  • Audio: Audacity, EarTrumpet, SteelSeries GG`r`n")
    $outputBox.AppendText("  • Mixer: MIXLINE, Voicemeeter Potato`r`n`r`n")
    
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Accent'
    $outputBox.AppendText("💻 CODING / IT (6 Tools):`r`n")
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Info'
    $outputBox.AppendText("  • Editoren: VS Code, Notepad++`r`n")
    $outputBox.AppendText("  • Terminal: PowerShell`r`n")
    $outputBox.AppendText("  • Netzwerk: PuTTY, WinSCP, WireGuard`r`n`r`n")
    
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Success'
    $outputBox.AppendText("✓ Winget-Integration: Automatische Installations-Status-Erkennung`r`n")
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Success'
    $outputBox.AppendText("✓ Ein-Klick-Installation: Direkte Installation über Winget`r`n")
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Muted'
    $outputBox.AppendText("`r`n💡 Tipp: Wählen Sie eine Kategorie oder nutzen Sie die Suchfunktion oben.`r`n")
    
    # Hinweis: View-Panel wird durch Sub-Button-Klick angezeigt
    
    # Setze alle Header-Button-Farben zurück auf inaktiv
    $btnOutput.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
    
    # Setze den Tool-Downloads-Header auf aktiv
    $downloadsPanel.Header.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
    
    # Setze Info-Panel-Header zurück
    $infoPanel.Header.BackColor = [System.Drawing.Color]::FromArgb(37, 37, 38)
    
    # Setze alle Info-Buttons zurück
    $btnStatusInfo.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
    $btnHardwareInfo.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
    $btnToolInfo.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
}
$mainButtonPanel.Controls.Add($downloadsPanel.Container)

# Setze die Content-Panel-Höhe für 5 Kategorie-Buttons
$downloadsPanel.Content.Height = 185  # 5 Buttons x 37px = 185px

# Erstelle die Kategorie-Buttons als Submenu
$btnAllTools = New-Object System.Windows.Forms.Button
$btnAllTools.Text = "Alle Tools"
$btnAllTools.Size = New-Object System.Drawing.Size(175, 35)
$btnAllTools.Location = New-Object System.Drawing.Point(0, 0)
$btnAllTools.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnAllTools.FlatAppearance.BorderSize = 0
$btnAllTools.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)  # Standardmäßig aktiv
$btnAllTools.ForeColor = [System.Drawing.Color]::White
$btnAllTools.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)

# Zähler-Label für Alle Tools
$lblAllToolsCount = New-Object System.Windows.Forms.Label
$lblAllToolsCount.Size = New-Object System.Drawing.Size(30, 20)
$lblAllToolsCount.Location = New-Object System.Drawing.Point(140, 8)
$lblAllToolsCount.TextAlign = [System.Drawing.ContentAlignment]::MiddleRight
$lblAllToolsCount.ForeColor = [System.Drawing.Color]::LightGray
$lblAllToolsCount.BackColor = [System.Drawing.Color]::Transparent
$lblAllToolsCount.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$lblAllToolsCount.Text = ""
$btnAllTools.Controls.Add($lblAllToolsCount)
$btnAllTools.Add_Click({
    # Downloads-View anzeigen (OutputBox wird nicht verwendet, da Tool-Kacheln direkt angezeigt werden)
    Switch-OutputView -viewName "downloadsView"
    
    # Aktuelle Kategorie speichern
    $script:currentDownloadCategory = "all"
    
    # Buttons hervorheben/zurücksetzen
    $btnAllTools.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
    $btnSystemTools.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
    $btnApplications.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
    $btnAudioTV.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
    $btnCodingTools.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
    
    # Tools mit Installationsüberprüfung anzeigen und Progressbar aktualisieren
    $null = Update-ToolsDisplay -WrapPanel $toolWrapPanel -Category "all" -MainProgressBar $progressBar -SearchQuery $searchTextBox.Text -TileSize $script:currentTileSize
})
$downloadsPanel.Content.Controls.Add($btnAllTools)

$btnSystemTools = New-Object System.Windows.Forms.Button
$btnSystemTools.Text = "System-Tools"
$btnSystemTools.Size = New-Object System.Drawing.Size(175, 35)
$btnSystemTools.Location = New-Object System.Drawing.Point(0, 37)
$btnSystemTools.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnSystemTools.FlatAppearance.BorderSize = 0
$btnSystemTools.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
$btnSystemTools.ForeColor = [System.Drawing.Color]::White
$btnSystemTools.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)

# Zähler-Label für System-Tools
$lblSystemToolsCount = New-Object System.Windows.Forms.Label
$lblSystemToolsCount.Size = New-Object System.Drawing.Size(30, 20)
$lblSystemToolsCount.Location = New-Object System.Drawing.Point(140, 8)
$lblSystemToolsCount.TextAlign = [System.Drawing.ContentAlignment]::MiddleRight
$lblSystemToolsCount.ForeColor = [System.Drawing.Color]::LightGray
$lblSystemToolsCount.BackColor = [System.Drawing.Color]::Transparent
$lblSystemToolsCount.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$lblSystemToolsCount.Text = ""
$btnSystemTools.Controls.Add($lblSystemToolsCount)
$btnSystemTools.Add_Click({
    # Downloads-View anzeigen (OutputBox wird nicht verwendet, da Tool-Kacheln direkt angezeigt werden)
    Switch-OutputView -viewName "downloadsView"
    
    # Aktuelle Kategorie speichern
    $script:currentDownloadCategory = "system"
    
    # Buttons hervorheben/zurücksetzen
    $btnAllTools.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
    $btnSystemTools.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
    $btnApplications.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
    $btnAudioTV.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
    $btnCodingTools.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
    
    # Tools mit Installationsüberprüfung anzeigen und Progressbar aktualisieren
    $null = Update-ToolsDisplay -WrapPanel $toolWrapPanel -Category "system" -MainProgressBar $progressBar -SearchQuery $searchTextBox.Text -TileSize $script:currentTileSize
})
$downloadsPanel.Content.Controls.Add($btnSystemTools)

$btnApplications = New-Object System.Windows.Forms.Button
$btnApplications.Text = "Anwendungen"
$btnApplications.Size = New-Object System.Drawing.Size(175, 35)
$btnApplications.Location = New-Object System.Drawing.Point(0, 74)
$btnApplications.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnApplications.FlatAppearance.BorderSize = 0
$btnApplications.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
$btnApplications.ForeColor = [System.Drawing.Color]::White
$btnApplications.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)

# Zähler-Label für Anwendungen
$lblApplicationsCount = New-Object System.Windows.Forms.Label
$lblApplicationsCount.Size = New-Object System.Drawing.Size(30, 20)
$lblApplicationsCount.Location = New-Object System.Drawing.Point(140, 8)
$lblApplicationsCount.TextAlign = [System.Drawing.ContentAlignment]::MiddleRight
$lblApplicationsCount.ForeColor = [System.Drawing.Color]::LightGray
$lblApplicationsCount.BackColor = [System.Drawing.Color]::Transparent
$lblApplicationsCount.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$lblApplicationsCount.Text = ""
$btnApplications.Controls.Add($lblApplicationsCount)
$btnApplications.Add_Click({
    # Downloads-View anzeigen (OutputBox wird nicht verwendet, da Tool-Kacheln direkt angezeigt werden)
    Switch-OutputView -viewName "downloadsView"
    
    # Aktuelle Kategorie speichern
    $script:currentDownloadCategory = "applications"
    
    # Buttons hervorheben/zurücksetzen
    $btnAllTools.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
    $btnSystemTools.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
    $btnApplications.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
    $btnAudioTV.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
    $btnCodingTools.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
    
    # Tools mit Installationsüberprüfung anzeigen und Progressbar aktualisieren
    $null = Update-ToolsDisplay -WrapPanel $toolWrapPanel -Category "applications" -MainProgressBar $progressBar -SearchQuery $searchTextBox.Text -TileSize $script:currentTileSize
})
$downloadsPanel.Content.Controls.Add($btnApplications)

$btnAudioTV = New-Object System.Windows.Forms.Button
$btnAudioTV.Text = "Audio / TV"
$btnAudioTV.Size = New-Object System.Drawing.Size(175, 35)
$btnAudioTV.Location = New-Object System.Drawing.Point(0, 111)
$btnAudioTV.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnAudioTV.FlatAppearance.BorderSize = 0
$btnAudioTV.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
$btnAudioTV.ForeColor = [System.Drawing.Color]::White
$btnAudioTV.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)

# Zähler-Label für Audio / TV
$lblAudioTVCount = New-Object System.Windows.Forms.Label
$lblAudioTVCount.Size = New-Object System.Drawing.Size(30, 20)
$lblAudioTVCount.Location = New-Object System.Drawing.Point(140, 8)
$lblAudioTVCount.TextAlign = [System.Drawing.ContentAlignment]::MiddleRight
$lblAudioTVCount.ForeColor = [System.Drawing.Color]::LightGray
$lblAudioTVCount.BackColor = [System.Drawing.Color]::Transparent
$lblAudioTVCount.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$lblAudioTVCount.Text = ""
$btnAudioTV.Controls.Add($lblAudioTVCount)
$btnAudioTV.Add_Click({
    # Downloads-View anzeigen (OutputBox wird nicht verwendet, da Tool-Kacheln direkt angezeigt werden)
    Switch-OutputView -viewName "downloadsView"
    
    # Aktuelle Kategorie speichern
    $script:currentDownloadCategory = "audiotv"
    
    # Buttons hervorheben/zurücksetzen
    $btnAllTools.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
    $btnSystemTools.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
    $btnApplications.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
    $btnAudioTV.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
    $btnCodingTools.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
    
    # Tools mit Installationsüberprüfung anzeigen und Progressbar aktualisieren
    $null = Update-ToolsDisplay -WrapPanel $toolWrapPanel -Category "audiotv" -MainProgressBar $progressBar -SearchQuery $searchTextBox.Text -TileSize $script:currentTileSize
})
$downloadsPanel.Content.Controls.Add($btnAudioTV)

$btnCodingTools = New-Object System.Windows.Forms.Button
$btnCodingTools.Text = "Coding / IT"
$btnCodingTools.Size = New-Object System.Drawing.Size(175, 35)
$btnCodingTools.Location = New-Object System.Drawing.Point(0, 148)
$btnCodingTools.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnCodingTools.FlatAppearance.BorderSize = 0
$btnCodingTools.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
$btnCodingTools.ForeColor = [System.Drawing.Color]::White
$btnCodingTools.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)

# Zähler-Label für Coding / IT
$lblCodingToolsCount = New-Object System.Windows.Forms.Label
$lblCodingToolsCount.Size = New-Object System.Drawing.Size(30, 20)
$lblCodingToolsCount.Location = New-Object System.Drawing.Point(140, 8)
$lblCodingToolsCount.TextAlign = [System.Drawing.ContentAlignment]::MiddleRight
$lblCodingToolsCount.ForeColor = [System.Drawing.Color]::LightGray
$lblCodingToolsCount.BackColor = [System.Drawing.Color]::Transparent
$lblCodingToolsCount.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$lblCodingToolsCount.Text = ""
$btnCodingTools.Controls.Add($lblCodingToolsCount)
$btnCodingTools.Add_Click({
    # Downloads-View anzeigen (OutputBox wird nicht verwendet, da Tool-Kacheln direkt angezeigt werden)
    Switch-OutputView -viewName "downloadsView"
    
    # Aktuelle Kategorie speichern
    $script:currentDownloadCategory = "coding"
    
    # Buttons hervorheben/zurücksetzen
    $btnAllTools.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
    $btnSystemTools.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
    $btnApplications.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
    $btnAudioTV.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
    $btnCodingTools.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
    
    # Tools mit Installationsüberprüfung anzeigen und Progressbar aktualisieren
    $null = Update-ToolsDisplay -WrapPanel $toolWrapPanel -Category "coding" -MainProgressBar $progressBar -SearchQuery $searchTextBox.Text -TileSize $script:currentTileSize
})
$downloadsPanel.Content.Controls.Add($btnCodingTools)

# Referenz für Event-Handler erstellen
$btnToolDownloads = $downloadsPanel.Header

# Initialisiere Panel-Positionen nach der Erstellung aller Panels
Update-PanelPositions -ParentPanel $mainButtonPanel

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

# Variable für aktuelle Download-Kategorie
$script:currentDownloadCategory = "all"

# Event-Handler für Ansichtsumschaltung
function Switch-OutputView {
    param(
        [string]$viewName
    )
    
    # Vorherige Buttons zurücksetzen
    $btnOutput.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
    $btnOutput.ForeColor = [System.Drawing.Color]::White
    $btnStatusInfo.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
    $btnStatusInfo.ForeColor = [System.Drawing.Color]::White
    $btnHardwareInfo.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
    $btnHardwareInfo.ForeColor = [System.Drawing.Color]::White
    $btnToolInfo.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
    $btnToolInfo.ForeColor = [System.Drawing.Color]::White
    $btnToolDownloads.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
    $btnToolDownloads.ForeColor = [System.Drawing.Color]::White
    
    # Alle Panels ausblenden
    $outputViewPanel.Visible = $false
    $statusViewPanel.Visible = $false
    $hardwareViewPanel.Visible = $false
    $toolInfoViewPanel.Visible = $false
    $downloadsViewPanel.Visible = $false
    
    # Aktuelle Ansicht markieren und einblenden
    switch ($viewName) {
        "outputView" {
            $outputViewPanel.Visible = $true
            $btnOutput.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
            $btnOutput.ForeColor = [System.Drawing.Color]::White
        }
        "statusView" {
            $statusViewPanel.Visible = $true
            $btnStatusInfo.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
            $btnStatusInfo.ForeColor = [System.Drawing.Color]::White
            
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
            $btnHardwareInfo.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
            $btnHardwareInfo.ForeColor = [System.Drawing.Color]::White
            
            # Hardware-Informationen aktualisieren
            if (-not $script:hardwareInfoLoaded) {
                Get-HardwareInfo -infoBox $hardwareInfoBox
                $script:hardwareInfoLoaded = $true
            }
        }
        "toolInfoView" {
            $toolInfoViewPanel.Visible = $true
            $btnToolInfo.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
            $btnToolInfo.ForeColor = [System.Drawing.Color]::White
            
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
    $outputBox.AppendText("🛡️ SYSTEM/SICHERHEIT:`r`n")
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Info'
    $outputBox.AppendText("  • Windows Defender: Scan & Optimierung`r`n")
    $outputBox.AppendText("  • Firewall: Regeln & Verwaltung`r`n")
    $outputBox.AppendText("  • AppLocker: Anwendungssteuerung`r`n`r`n")

    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Accent'
    $outputBox.AppendText("🔧 DIAGNOSE/REPARATUR:`r`n")
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Info'
    $outputBox.AppendText("  • DISM & SFC: System-Integritätsprüfung`r`n")
    $outputBox.AppendText("  • CHKDSK: Datenträger-Analyse`r`n")
    $outputBox.AppendText("  • Windows Update: Reparatur & Wartung`r`n`r`n")

    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Accent'
    $outputBox.AppendText("🌐 NETZWERK-TOOLS:`r`n")
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Info'
    $outputBox.AppendText("  • Netzwerk-Diagnose & Adapter-Reset`r`n")
    $outputBox.AppendText("  • DNS-Cache & IP-Konfiguration`r`n")
    $outputBox.AppendText("  • Verbindungsanalyse & Ping-Tests`r`n`r`n")

    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Accent'
    $outputBox.AppendText("🧹 BEREINIGUNG:`r`n")
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Info'
    $outputBox.AppendText("  • Temp-Dateien & Cache bereinigen`r`n")
    $outputBox.AppendText("  • Windows Update-Cache entfernen`r`n")
    $outputBox.AppendText("  • Browser-Daten löschen`r`n`r`n")

    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Accent'
    $outputBox.AppendText("📊 INFORMATIONEN:`r`n")
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
    $btnStatusInfo.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
    $btnHardwareInfo.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
    $btnToolInfo.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
    $btnToolDownloads.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
    
    # Setze Info-Panel-Header zurück
    $infoPanel.Header.BackColor = [System.Drawing.Color]::FromArgb(37, 37, 38)
    # Setze Downloads-Panel-Header zurück
    $downloadsPanel.Header.BackColor = [System.Drawing.Color]::FromArgb(37, 37, 38)
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

# Erstelle die TextProgressBar über das Modul
$progressBar = New-TextProgressBar -X 190 -Y 755 -Width 650 -Height 30 -InitialText "Bereit" -InitialTextColor ([System.Drawing.Color]::CornflowerBlue)
$mainform.Controls.Add($progressBar)
Initialize-ProgressComponents -ProgressBar $progressBar -StatusLabel $progressStatusLabel

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

    # CPU-Informationen
    Set-OutputSelectionStyle -OutputBox $infoBox -Style 'Info'
    $infoBox.AppendText("CPU-INFORMATIONEN:`r`n")

    try {
        $cpuInfo = Get-WmiObject -Class Win32_Processor
        foreach ($cpu in $cpuInfo) {
            Set-OutputSelectionStyle -OutputBox $infoBox -Style 'Default'
            $infoBox.AppendText("Prozessor: $($cpu.Name)`r`n")
            Set-OutputSelectionStyle -OutputBox $infoBox -Style 'Default'
            $infoBox.AppendText("Kerne: $($cpu.NumberOfCores)`r`n")
            Set-OutputSelectionStyle -OutputBox $infoBox -Style 'Default'
            $infoBox.AppendText("Logische Prozessoren: $($cpu.NumberOfLogicalProcessors)`r`n")
            Set-OutputSelectionStyle -OutputBox $infoBox -Style 'Default'
            $infoBox.AppendText("Taktrate: $($cpu.MaxClockSpeed) MHz`r`n")
            Set-OutputSelectionStyle -OutputBox $infoBox -Style 'Default'
            $infoBox.AppendText("Cache: $(($cpu.L3CacheSize / 1024)) MB`r`n`r`n")
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

    # Festplatten-Informationen
    Set-OutputSelectionStyle -OutputBox $infoBox -Style 'Info'
    $infoBox.AppendText("FESTPLATTEN-INFORMATIONEN:`r`n")

    try {
        $drives = Get-WmiObject -Class Win32_DiskDrive
        foreach ($drive in $drives) {
            $sizeGB = [math]::Round($drive.Size / 1GB, 2)
            Set-OutputSelectionStyle -OutputBox $infoBox -Style 'Default'
            $infoBox.AppendText("Laufwerk: $($drive.Model)`r`n")
            Set-OutputSelectionStyle -OutputBox $infoBox -Style 'Default'
            $infoBox.AppendText("Größe: $sizeGB GB`r`n")
            Set-OutputSelectionStyle -OutputBox $infoBox -Style 'Default'
            $infoBox.AppendText("Schnittstelle: $($drive.InterfaceType)`r`n`r`n")
        }

        # Logische Laufwerke und freier Speicherplatz
        Set-OutputSelectionStyle -OutputBox $infoBox -Style 'Info'
        $infoBox.AppendText("LOGISCHE LAUFWERKE:`r`n")

        $logicalDrives = Get-WmiObject -Class Win32_LogicalDisk -Filter "DriveType=3"
        foreach ($logicalDrive in $logicalDrives) {
            $freeGB = [math]::Round($logicalDrive.FreeSpace / 1GB, 2)
            $sizeGB = [math]::Round($logicalDrive.Size / 1GB, 2)
            $usedPercent = [math]::Round(($logicalDrive.Size - $logicalDrive.FreeSpace) / $logicalDrive.Size * 100, 1)

            Set-OutputSelectionStyle -OutputBox $infoBox -Style 'Default'
            $infoBox.AppendText("Laufwerk $($logicalDrive.DeviceID) ($($logicalDrive.VolumeName))`r`n")
            Set-OutputSelectionStyle -OutputBox $infoBox -Style 'Default'
            $infoBox.AppendText("Gesamtgröße: $sizeGB GB`r`n")
            Set-OutputSelectionStyle -OutputBox $infoBox -Style 'Default'
            $infoBox.AppendText("Freier Speicher: $freeGB GB`r`n")
            Set-OutputSelectionStyle -OutputBox $infoBox -Style 'Default'
            $infoBox.AppendText("Belegung: $usedPercent%`r`n`r`n")
        }
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
                $infoBox.AppendText("IP-Adressen: $($config.IPAddress -join ', ')`r`n")
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
$btnWinUpdate.Location = New-Object System.Drawing.Point(180, 5)  # 5px vom oberen Rand
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

# Windows Update Button wurde zu tblSystem hinzugefügt, Tag ist maintenanceControl


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
        Update-ScanHistory -ToolName "DISM"
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
        Update-ScanHistory -ToolName "DISM"
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
        Update-ScanHistory -ToolName "DISM"
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
$btnTempFiles.Tag = "cleanupTempControl"
$btnTempFiles.Add_Click({
        Switch-ToOutputTab
        # Dialog entfernt, direkt erweiterte Bereinigung starten
        # Status auf "Erweiterte Bereinigung läuft..." setzen
        Update-ProgressStatus -StatusText "Erweiterte Systemreinigung wurde geöffnet..." -ProgressValue 0 -TextColor ([System.Drawing.Color]::White)
        Start-TempFilesCleanupAdvanced -outputBox $outputBox -progressBar $progressBar -mainform $mainform
        # Nach der Bereinigung Status auf "Fertig" setzen
        Update-ProgressStatus -StatusText "Fertig" -ProgressValue 100 -TextColor ([System.Drawing.Color]::White)
    })
$tblCleanup.Controls.Add($btnTempFiles)

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
        $btnCheckDISM = "DISM"
        $btnScanDISM = "DISM"
        $btnRestoreDISM = "DISM"
        $btnCHKDSK = "CHKDSK"
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
$btnRestart.Text = "Neustart ▼"
$btnRestart.Location = New-Object System.Drawing.Point(30, 755)
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

$mainform.Controls.Add($btnRestart)

# ===================================================================
# AUTO-UPDATE BUTTON
# ===================================================================

# Funktion zum Prüfen und Durchführen von Updates
function Check-ForUpdates {
    param(
        [bool]$AutoInstall = $false
    )
    
    try {
        $currentVersion = $script:AppVersion
        $repoOwner = "ReXx09"
        $repoName = "Bockis-Win_Gui"
        $apiUrl = "https://api.github.com/repos/$repoOwner/$repoName/releases/latest"
        
        Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Info'
        $outputBox.AppendText("[i] Prüfe auf Updates...`r`n")
        
        # GitHub API abfragen
        $latestRelease = Invoke-RestMethod -Uri $apiUrl -Headers @{ "User-Agent" = "Bockis-System-Tool" }
        $latestVersion = $latestRelease.tag_name -replace 'v', ''
        
        Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Default'
        $outputBox.AppendText("Aktuelle Version: $currentVersion`r`n")
        $outputBox.AppendText("Neueste Version: $latestVersion`r`n`r`n")
        
        # Versionsvergleich
        if ([version]$latestVersion -gt [version]$currentVersion) {
            Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Success'
            $outputBox.AppendText("[✓] Update verfügbar: v$latestVersion`r`n`r`n")
            
            # Asset-URL ermitteln (erstes ZIP-Asset)
            $asset = $latestRelease.assets | Where-Object { $_.name -like "*.zip" } | Select-Object -First 1
            
            if (-not $asset) {
                Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Error'
                $outputBox.AppendText("[✗] Kein Download-Asset gefunden!`r`n")
                return $false
            }
            
            # Benutzer fragen
            $result = [System.Windows.Forms.MessageBox]::Show(
                "Neue Version verfügbar: v$latestVersion`n`nAktuell installiert: v$currentVersion`n`nRelease-Notes:`n$($latestRelease.body.Substring(0, [Math]::Min(200, $latestRelease.body.Length)))...`n`nMöchten Sie jetzt updaten?",
                "Update verfügbar",
                [System.Windows.Forms.MessageBoxButtons]::YesNo,
                [System.Windows.Forms.MessageBoxIcon]::Information
            )
            
            if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
                # Download-Pfad
                $tempPath = [System.IO.Path]::GetTempPath()
                $zipPath = Join-Path $tempPath "Bockis-Update-v$latestVersion.zip"
                $extractPath = Join-Path $tempPath "Bockis-Update-Extract"
                
                Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Info'
                $outputBox.AppendText("[i] Download wird gestartet...`r`n")
                $outputBox.AppendText("Quelle: $($asset.browser_download_url)`r`n")
                $outputBox.AppendText("Ziel: $zipPath`r`n`r`n")
                
                # Progressbar vorbereiten
                Update-ProgressStatus -StatusText "Download läuft..." -ProgressValue 0 -TextColor ([System.Drawing.Color]::Blue)
                
                # Download mit Fortschrittsanzeige
                $webClient = New-Object System.Net.WebClient
                $webClient.Headers.Add("User-Agent", "Bockis-System-Tool")
                
                Register-ObjectEvent -InputObject $webClient -EventName DownloadProgressChanged -SourceIdentifier WebClient.DownloadProgressChanged -Action {
                    $progressBar.Value = $EventArgs.ProgressPercentage
                    Update-ProgressStatus -StatusText "Download: $($EventArgs.ProgressPercentage)%" -ProgressValue $EventArgs.ProgressPercentage -TextColor ([System.Drawing.Color]::Blue)
                } | Out-Null
                
                $webClient.DownloadFileAsync($asset.browser_download_url, $zipPath)
                
                # Warten auf Download-Abschluss
                while ($webClient.IsBusy) {
                    [System.Windows.Forms.Application]::DoEvents()
                    Start-Sleep -Milliseconds 100
                }
                
                Unregister-Event -SourceIdentifier WebClient.DownloadProgressChanged
                $webClient.Dispose()
                
                Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Success'
                $outputBox.AppendText("[✓] Download abgeschlossen!`r`n`r`n")
                
                # Entpacken
                Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Info'
                $outputBox.AppendText("[i] Extrahiere Update...`r`n")
                Update-ProgressStatus -StatusText "Entpacken..." -ProgressValue 50 -TextColor ([System.Drawing.Color]::Green)
                
                if (Test-Path $extractPath) {
                    Remove-Item $extractPath -Recurse -Force
                }
                
                Expand-Archive -Path $zipPath -DestinationPath $extractPath -Force
                
                # Update-Script erstellen
                $updateScript = @"
Start-Sleep -Seconds 2
Write-Host 'Installiere Update...'
`$source = '$extractPath\*'
`$dest = '$PSScriptRoot'
Copy-Item -Path `$source -Destination `$dest -Recurse -Force
Remove-Item '$zipPath' -Force
Remove-Item '$extractPath' -Recurse -Force
Write-Host 'Update abgeschlossen! Starte Anwendung...'
Start-Process powershell.exe -ArgumentList '-ExecutionPolicy Bypass -File "$PSScriptRoot\Win_Gui_Module.ps1"'
"@
                
                $updateScriptPath = Join-Path $tempPath "BockisUpdate.ps1"
                $updateScript | Out-File -FilePath $updateScriptPath -Encoding UTF8 -Force
                
                Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Success'
                $outputBox.AppendText("[✓] Update wird installiert...`r`n")
                $outputBox.AppendText("[i] Anwendung wird neu gestartet!`r`n")
                
                Update-ProgressStatus -StatusText "Installation..." -ProgressValue 100 -TextColor ([System.Drawing.Color]::LimeGreen)
                
                # Update-Script starten und GUI schließen
                Start-Process powershell.exe -ArgumentList "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$updateScriptPath`"" -WindowStyle Hidden
                
                Start-Sleep -Milliseconds 500
                $mainform.Close()
            }
            
            return $true
        }
        else {
            Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Success'
            $outputBox.AppendText("[✓] Sie verwenden bereits die neueste Version!`r`n")
            
            [System.Windows.Forms.MessageBox]::Show(
                "Sie verwenden bereits die neueste Version: v$currentVersion",
                "Keine Updates",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Information
            )
            
            return $false
        }
    }
    catch {
        Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Error'
        $outputBox.AppendText("[✗] Fehler beim Update-Check: $_`r`n")
        
        [System.Windows.Forms.MessageBox]::Show(
            "Fehler beim Prüfen auf Updates:`n`n$_`n`nBitte überprüfen Sie Ihre Internetverbindung.",
            "Update-Fehler",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
        
        return $false
    }
}

# Update-Button erstellen
$btnUpdate = New-Object System.Windows.Forms.Button
$btnUpdate.Text = "🔄 Update"
$btnUpdate.Location = New-Object System.Drawing.Point(180, 755)
$btnUpdate.Size = New-Object System.Drawing.Size(140, 30)
$btnUpdate.BackColor = [System.Drawing.Color]::FromArgb(16, 124, 16)  # Grün
$btnUpdate.ForeColor = [System.Drawing.Color]::White
$btnUpdate.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnUpdate.FlatAppearance.BorderSize = 0
$btnUpdate.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)

# Click-Event: Update prüfen
$btnUpdate.Add_Click({
    Check-ForUpdates
})

$mainform.Controls.Add($btnUpdate)

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
$tooltipObj.SetToolTip($btnUpdate, "Prüft auf verfügbare Updates und installiert diese automatisch")
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

# Hinweis: Die Tool-Ressourcen und -Funktionen wurden ins ToolLibrary-Modul verschoben

# Funktion zum Erstellen einer Tool-Kachel
# Hinweis: Die Initialize-ToolEntry-Funktion wurde ins ToolLibrary-Modul verschoben

# Funktion zum Anzeigen der Tool-Kacheln
# Hinweis: Die Show-ToolTileList-Funktion wurde ins ToolLibrary-Modul verschoben

# Hinweis: CategoryPanel und zugehörige Buttons wurden entfernt, 
# da die Kategorien jetzt im Dropdown-Menü "Tool-Downloads" integriert sind

# Variable zur Verfolgung, ob Tools bereits geladen wurden
$script:toolsAlreadyLoaded = $false

# Hauptformular anzeigen
$mainform.Add_Shown({
        $null = Update-Settings

        if (Get-Command -Name Initialize-LogDirectory -ErrorAction SilentlyContinue) {
            Initialize-LogDirectory
        }

        $outputBox.Clear()

        Set-OutputSelectionStyle -OutputBox $outputBox -Style 'BannerFrame'
        $outputBox.AppendText("`t`t╔══════════════════════════════════════════════════════════════╗`r`n")
        Set-OutputSelectionStyle -OutputBox $outputBox -Style 'BannerTitle'
        $outputBox.AppendText("`t`t║                 BOCKIS WINDOWS TOOL-KIT                      ║`r`n")
        Set-OutputSelectionStyle -OutputBox $outputBox -Style 'BannerFrame'
        $outputBox.AppendText("`t`t╚══════════════════════════════════════════════════════════════╝`r`n`r`n")

        Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Success'
        $outputBox.AppendText("[✓] System-Tool wurde erfolgreich gestartet`r`n`r`n")

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
            $outputBox.AppendText("[✓] Das Tool läuft mit Administratorrechten.`r`n")
            Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Success'
            $outputBox.AppendText("[✓] Alle Funktionen stehen zur Verfügung.`r`n`r`n")
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

    # WICHTIGER SICHERHEITSHINWEIS für Windows Defender
        Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Warning'
        $outputBox.AppendText("╔══════════════════════════════════════════════════════════════════════╗`r`n")
        Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Warning'
        $outputBox.AppendText("║                ⚠  WICHTIGER SICHERHEITSHINWEIS  ⚠                    ║`r`n")
        Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Warning'
        $outputBox.AppendText("╚══════════════════════════════════════════════════════════════════════╝`r`n`r`n")
        
        Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Warning'
        $outputBox.AppendText("[!] Windows Defender könnte dieses Tool als 'Trojan:Win32/Vigorf.A' melden.`r`n")
        Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Default'
        $outputBox.AppendText("[i] Dies ist ein FEHLALARM (False Positive).`r`n`r`n")
        
        Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Accent'
        $outputBox.AppendText("Grund:`r`n")
        Set-OutputSelectionStyle -OutputBox $outputBox -Style 'BodySmall'
        $outputBox.AppendText("  • Dieses Tool verwendet Windows-APIs zur Fenstersteuerung`r`n")
        Set-OutputSelectionStyle -OutputBox $outputBox -Style 'BodySmall'
        $outputBox.AppendText("  • Diese Techniken werden manchmal von Malware missbraucht`r`n")
        Set-OutputSelectionStyle -OutputBox $outputBox -Style 'BodySmall'
        $outputBox.AppendText("  • Der Defender reagiert daher vorsichtshalber auf den Code`r`n`r`n")
        
        Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Success'
        $outputBox.AppendText("✓ Dieses Tool ist SICHER - der Code ist vollständig transparent!`r`n")
        
        Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Divider'
        $outputBox.AppendText("════════════════════════════════════════════════════════════════════════════`r`n`r`n")

        $applySettingsTimer.Start()

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

# Buttons bleiben in den Collapsible Panels (nicht ins subButtonPanel verschieben)

# Setze alle Hauptbuttons als inaktiv beim Start
$btnSystem.BackColor = [System.Drawing.Color]::FromArgb(45, 45, 48)
$btnSystem.ForeColor = [System.Drawing.Color]::White
$global:tblSystem.Visible = $false

# Event-Handler für Button-Wechsel hinzufügen - steuert, welche Buttons in der SubNavigation angezeigt werden
$mainform.Add_VisibleChanged({
    if ($mainform.Visible) {
        # Nur beim ersten Laden ausführen
        # Behandle Subnavigation Buttons je nach aktiver Ansicht
           }
})

# Sicherheit-Button visuell deaktivieren
$btnSystemSecurity.BackColor = [System.Drawing.Color]::FromArgb(37, 37, 38)
$btnSystemMaintenance.BackColor = [System.Drawing.Color]::FromArgb(37, 37, 38)

# Initialzustand wird jetzt durch PerformClick() am Ende des Skripts gesetzt
# Controls entsprechend ein-/ausblenden
Switch-SystemControls

# Initialisiere Netzwerk-Controls
# Standardmäßig Diagnose-Controls anzeigen
Switch-NetworkControls

# Initialisiere Bereinigungs-Controls
# Konsole beim Start ausblenden
Hide-ConsoleAutomatically

# Update Toggle-Button Status
if ($btnToggleConsole) {
    $btnToggleConsole.Text = "►"
    $btnToggleConsole.BackColor = [System.Drawing.Color]::FromArgb(43, 43, 43)
}

# Initiale Willkommensnachricht in der OutputBox anzeigen
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
$outputBox.AppendText("🛡️ SYSTEM/SICHERHEIT:`r`n")
Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Info'
$outputBox.AppendText("  • Windows Defender: Scan & Optimierung`r`n")
$outputBox.AppendText("  • Firewall: Regeln & Verwaltung`r`n")
$outputBox.AppendText("  • AppLocker: Anwendungssteuerung`r`n`r`n")

Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Accent'
$outputBox.AppendText("🔧 DIAGNOSE/REPARATUR:`r`n")
Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Info'
$outputBox.AppendText("  • DISM & SFC: System-Integritätsprüfung`r`n")
$outputBox.AppendText("  • CHKDSK: Datenträger-Analyse`r`n")
$outputBox.AppendText("  • Windows Update: Reparatur & Wartung`r`n`r`n")

Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Accent'
$outputBox.AppendText("🌐 NETZWERK-TOOLS:`r`n")
Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Info'
$outputBox.AppendText("  • Netzwerk-Diagnose & Adapter-Reset`r`n")
$outputBox.AppendText("  • DNS-Cache & IP-Konfiguration`r`n")
$outputBox.AppendText("  • Verbindungsanalyse & Ping-Tests`r`n`r`n")

Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Accent'
$outputBox.AppendText("🧹 BEREINIGUNG:`r`n")
Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Info'
$outputBox.AppendText("  • Temp-Dateien & Cache bereinigen`r`n")
$outputBox.AppendText("  • Windows Update-Cache entfernen`r`n")
$outputBox.AppendText("  • Browser-Daten löschen`r`n`r`n")

Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Accent'
$outputBox.AppendText("📊 INFORMATIONEN:`r`n")
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


# Win_Gui_Module.ps1 - Hauptskript für die PowerShell-GUI
# Autor: Bocki 



# Globale Einstellungen
$script:settings = @{
    FontSize            = 10
    ColorScheme         = "Standard"
    SaveWindowSize      = $true
    UpdateInterval      = 1000
    CpuThreshold        = 90
    RamThreshold        = 85
    GpuThreshold        = 80  
    EnableNotifications = $true
    LogLevel            = "Standard"
    AutoSaveLogs        = $false
    LogPath             = "$PSScriptRoot\Logs"
    ConfirmActions      = $true
    AdvancedCleanup     = $false
    CheckUpdates        = $true
    ShowSplash          = $true
}

# Laden der Einstellungen aus der Konfigurationsdatei, falls vorhanden
function Load-Settings {
    $settingsFilePath = "$PSScriptRoot\config.json"
    if (Test-Path $settingsFilePath) {
        try {
            $loadedSettings = Get-Content -Path $settingsFilePath -Raw | ConvertFrom-Json
            
            # Übertrage die geladenen Einstellungen in das globale Settings-Objekt
            foreach ($property in $loadedSettings.PSObject.Properties) {
                $script:settings[$property.Name] = $property.Value
            }
            
            Write-Host "Einstellungen wurden aus $settingsFilePath geladen." -ForegroundColor Green
            return $true
        }
        catch {
            Write-Host "Fehler beim Laden der Einstellungen: $_" -ForegroundColor Red
            return $false
        }
    }
    else {
        Write-Host "Keine Konfigurationsdatei gefunden, Standard-Einstellungen werden verwendet." -ForegroundColor Yellow
        return $false
    }
}

# Einstellungen beim Programmstart laden
Load-Settings

# Einstellungen auf die Benutzeroberfläche anwenden
function Apply-Settings {
    # Sicherheitsüberprüfung, dass die notwendigen Steuerelemente vorhanden sind
    if ($null -eq $outputBox -or $null -eq $mainform) {
        Write-Host "Kann Einstellungen nicht anwenden, da Steuerelemente noch nicht initialisiert sind." -ForegroundColor Yellow
        return $false
    }
    
    try {
        # 1. Schriftgröße
        if ($script:settings.FontSize -ne $null -and [int]$script:settings.FontSize -gt 0) {
            $newFontSize = [int]$script:settings.FontSize
            $outputBox.Font = New-Object System.Drawing.Font($outputBox.Font.FontFamily, $newFontSize)
            
            # Wenn weitere RichTextBoxes vorhanden sind, auch dort Schriftgröße anpassen
            if ($null -ne $hardwareInfoBox) {
                $hardwareInfoBox.Font = New-Object System.Drawing.Font($hardwareInfoBox.Font.FontFamily, $newFontSize)
            }
            if ($null -ne $systemStatusBox) {
                $systemStatusBox.Font = New-Object System.Drawing.Font($systemStatusBox.Font.FontFamily, $newFontSize)
            }
            if ($null -ne $toolInfoBox) {
                $toolInfoBox.Font = New-Object System.Drawing.Font($toolInfoBox.Font.FontFamily, $newFontSize)
            }
            if ($null -ne $toolDownloadsBox) {
                $toolDownloadsBox.Font = New-Object System.Drawing.Font($toolDownloadsBox.Font.FontFamily, $newFontSize)
            }
        }
        
        # 2. Farbschema
        if ($script:settings.ColorScheme -ne $null) {
            $isDarkMode = $mainform.BackColor -eq [System.Drawing.Color]::FromArgb(28, 30, 36)
            
            switch ($script:settings.ColorScheme) {
                "Dunkel (Dark Mode)" {
                    if (-not $isDarkMode -and $null -ne $themeButton) {
                        $themeButton.PerformClick()  # Wechselt zum Dark Mode
                    }
                }
                "Hell (Light Mode)" {
                    if ($isDarkMode -and $null -ne $themeButton) {
                        $themeButton.PerformClick()  # Wechselt zum Light Mode
                    }
                }
                "Blau" {
                    # Blaues Farbschema anwenden
                    if ($null -ne $mainform) { $mainform.BackColor = [System.Drawing.Color]::FromArgb(220, 230, 250) }
                    if ($null -ne $tabSystem) { $tabSystem.BackColor = [System.Drawing.Color]::FromArgb(200, 220, 255) }
                    if ($null -ne $tabDisk) { $tabDisk.BackColor = [System.Drawing.Color]::FromArgb(210, 225, 250) }
                    if ($null -ne $tabNetwork) { $tabNetwork.BackColor = [System.Drawing.Color]::FromArgb(220, 230, 245) }
                    if ($null -ne $tabCleanup) { $tabCleanup.BackColor = [System.Drawing.Color]::FromArgb(230, 235, 240) }
                }
                "Grün" {
                    # Grünes Farbschema anwenden
                    if ($null -ne $mainform) { $mainform.BackColor = [System.Drawing.Color]::FromArgb(230, 245, 230) }
                    if ($null -ne $tabSystem) { $tabSystem.BackColor = [System.Drawing.Color]::FromArgb(210, 250, 210) }
                    if ($null -ne $tabDisk) { $tabDisk.BackColor = [System.Drawing.Color]::FromArgb(220, 245, 220) }
                    if ($null -ne $tabNetwork) { $tabNetwork.BackColor = [System.Drawing.Color]::FromArgb(230, 240, 230) }
                    if ($null -ne $tabCleanup) { $tabCleanup.BackColor = [System.Drawing.Color]::FromArgb(240, 235, 240) }
                }
            }
        }
        
        # 3. Hardware Monitor Update-Intervall anpassen, falls vorhanden
        if ($null -ne $script:hardwareTimer -and $script:settings.UpdateInterval -ne $null) {
            $script:hardwareTimer.Interval = [int]$script:settings.UpdateInterval
        }
        
        # 4. Schwellenwerte für Hardware-Überwachung
        if ($script:settings.CpuThreshold -ne $null) {
            $script:cpuThreshold = [int]$script:settings.CpuThreshold
        }
        if ($script:settings.RamThreshold -ne $null) {
            $script:ramThreshold = [int]$script:settings.RamThreshold
        }
        if ($script:settings.GpuThreshold -ne $null) {
            # GPU-Schwellenwert hinzufügen
            $script:gpuThreshold = [int]$script:settings.GpuThreshold
        }
        
        Write-Host "`r[+] Einstellungen wurden erfolgreich angewendet." -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "`r[!] Fehler beim Anwenden der Einstellungen: $_" -ForegroundColor Red
        return $false
    }
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
        
        # PowerShell mit erhöhten Rechten starten
        Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`"" -Verb RunAs -Wait
        
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
        [System.Drawing.Color]$Color = [System.Drawing.Color]::Black,
        [switch]$NoTimestamp
    )
    
    $OutputBox.SelectionColor = $Color
    if ($NoTimestamp) {
        $OutputBox.AppendText("$Message`r`n")
    }
    else {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $OutputBox.AppendText("[$timestamp] [$ToolName] $Message`r`n")
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
    Write-Host "    ███████╗██╗   ██╗███████╗████████╗███████╗███╗   ███╗" -ForegroundColor $primaryColor
    Write-Host "    ██╔════╝╚██╗ ██╔╝██╔════╝╚══██╔══╝██╔════╝████╗ ████║" -ForegroundColor $primaryColor
    Write-Host "    ███████╗ ╚████╔╝ ███████╗   ██║   █████╗  ██╔████╔██║" -ForegroundColor $primaryColor
    Write-Host "    ╚════██║  ╚██╔╝  ╚════██║   ██║   ██╔══╝  ██║╚██╔╝██║" -ForegroundColor $primaryColor
    Write-Host "    ███████║   ██║   ███████║   ██║   ███████╗██║ ╚═╝ ██║" -ForegroundColor $primaryColor
    Write-Host "    ╚══════╝   ╚═╝   ╚══════╝   ╚═╝   ╚══════╝╚═╝     ╚═╝" -ForegroundColor $primaryColor
    Write-Host "    ████████╗ ██████╗  ██████╗ ██╗     ███████╗" -ForegroundColor $secondaryColor
    Write-Host "    ╚══██╔══╝██╔═══██╗██╔═══██╗██║     ██╔════╝" -ForegroundColor $secondaryColor
    Write-Host "       ██║   ██║   ██║██║   ██║██║     ███████╗" -ForegroundColor $secondaryColor
    Write-Host "       ██║   ██║   ██║██║   ██║██║     ╚════██║" -ForegroundColor $secondaryColor
    Write-Host "       ██║   ╚██████╔╝╚██████╔╝███████╗███████║" -ForegroundColor $secondaryColor
    Write-Host "       ╚═╝    ╚═════╝  ╚═════╝ ╚══════╝╚══════╝" -ForegroundColor $secondaryColor
    Write-Host "`n`n                  Version 3.1 - PowerShell Edition" -ForegroundColor $accentColor
    Write-Host "                      Entwickelt von Bocki" -ForegroundColor $accentColor

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

# Initialisierung der Debug-Variablen
$script:cpuDebugEnabled = $false
$script:gpuDebugEnabled = $false
$script:ramDebugEnabled = $false

# Stelle sicher, dass das Modules-Verzeichnis existiert
if (-not (Test-Path $modulesPath)) {
    Write-Host "Erstelle Modules-Verzeichnis..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $modulesPath | Out-Null
}

# Windows Forms Assembly laden
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Definiere die Module in der richtigen Reihenfolge (Abhängigkeiten zuerst)
$moduleOrder = @(
    'Core\Core                    ', # Basis-Funktionalitäten
    'Core\UI                      ', # UI-Komponenten
    'Core\ProgressBarTools        ', # ProgressBar-Funktionalitäten
    'Monitor\HardwareMonitorTools ', # Hardware-Monitor-Tools
    'SystemInfo                   ', # System-Informationen
    'Tools\SystemTools            ', # System-Tools
    'Tools\DISM-Tools             ', # Festplatten-Tools
    'Tools\CHKDSKTools            ', # CHKDSK-Tools
    'Tools\NetworkTools           ', # Netzwerk-Tools
    'Tools\CleanupTools           ', # Bereinigungs-Tools
    'ToolLibrary                  ', # Tool-Bibliothek
    'HardwareInfo                 ', # Hardware-Informationen
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
        }

        # Extrahiere den reinen Modulnamen ohne Pfad für Remove-Module
        $moduleNameOnly = $moduleClean.Split('\')[-1].Trim()
        
        # Versuche vorhandenes Modul zu entfernen
        if (Get-Module $moduleNameOnly) {
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

# Initialisiere Ausgabecodierung
& {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    $OutputEncoding = [System.Text.Encoding]::UTF8
}

# PowerShell-Fenster anpassen - mit Fehlerbehandlung
try {
    # Aktuelle Fenstergröße abrufen
    $currentWindowSize = $Host.UI.RawUI.WindowSize
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

# Definiere Statuswerte
$STATUS_SUCCESS = 0
$STATUS_MODULE_ERROR = 1

# Status-Variable initialisieren
$moduleLadingStatus = $STATUS_SUCCESS


# Trennlinie
Write-Host "`n" + ("═" * 70) -ForegroundColor Cyan

# Erstelle das Hauptformular
$mainform = New-Object System.Windows.Forms.Form
$mainform.Text = "Bocki's System-Tool 3.0"
$mainform.Size = New-Object System.Drawing.Size(1000, 900)
$mainform.StartPosition = "Manual"  # Manuelle Positionierung aktivieren

# P/Invoke-Definitionen für die Fensterpositionierung
$script:positioningInitialized = $false

function Initialize-WindowPositioning {
    if ($script:positioningInitialized) { return $true }
    
    try {
        $dllImportSource = @'
using System;
using System.Runtime.InteropServices;

public static class NativeMethods
{
    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern IntPtr GetConsoleWindow();

    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);

    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool MoveWindow(IntPtr hWnd, int X, int Y, int nWidth, int nHeight, bool bRepaint);
    
    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool SetForegroundWindow(IntPtr hWnd);
    
    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
    
    // ShowWindow-Befehle
    public const int SW_RESTORE = 9;
}

[StructLayout(LayoutKind.Sequential)]
public struct RECT
{
    public int Left;
    public int Top;
    public int Right;
    public int Bottom;
}
'@
        # Versuche, den Typ zu erstellen
        Add-Type -TypeDefinition $dllImportSource -Language CSharp -ErrorAction SilentlyContinue
        $script:positioningInitialized = $true
        return $true
    }
    catch {
        Write-Host "Fehler bei der Initialisierung der Fensterpositionierung: $_" -ForegroundColor Red
        return $false
    }
}

# Initiale Positionierung
function Position-MainForm {
    try {
        if (-not (Initialize-WindowPositioning)) {
            $mainform.StartPosition = "CenterScreen"
            return
        }
        
        # Konsolenfenster ermitteln
        $consoleHandle = [NativeMethods]::GetConsoleWindow()
        if ($consoleHandle -eq [IntPtr]::Zero) {
            $mainform.StartPosition = "CenterScreen"
            return
        }
        
        # Konsolenfenstergröße ermitteln
        $rect = New-Object RECT
        if (-not [NativeMethods]::GetWindowRect($consoleHandle, [ref]$rect)) {
            $mainform.StartPosition = "CenterScreen"
            return
        }
        
        # GUI-Fenster rechts neben dem Konsolenfenster positionieren
        $mainform.Location = New-Object System.Drawing.Point(($rect.Right + 10), $rect.Top)
        
        # Speichere initiale Position
        $script:lastGuiLeft = $mainform.Left
        $script:lastGuiTop = $mainform.Top
         
    }
    catch {
        Write-Host "Fehler bei der initialen Positionierung: $_" -ForegroundColor Red
        $mainform.StartPosition = "CenterScreen"
    }
}

# GUI-Fenster positionieren
Position-MainForm

# Event-Handler für Formular-Schließen: Timer stoppen
$mainform.Add_FormClosing({
     
    })

$mainform.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$mainform.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::None  # Kein Rahmen
$mainform.MinimumSize = New-Object System.Drawing.Size(1000, 850)
$mainform.BackColor = [System.Drawing.Color]::FromArgb(235, 245, 255)

# Benutzerdefinierte Titelleiste
$titleBar = New-Object System.Windows.Forms.Panel
$titleBar.Size = New-Object System.Drawing.Size(1000, 30)
$titleBar.BackColor = [System.Drawing.Color]::FromArgb(45, 45, 48)
$titleBar.Dock = [System.Windows.Forms.DockStyle]::Top

# Variable für das Fenster-Dragging
$script:mouseOffset = New-Object System.Drawing.Point

# Titel-Label
$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Text = "Bocki's System-Tool 3.0"
$titleLabel.ForeColor = [System.Drawing.Color]::White
$titleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$titleLabel.Location = New-Object System.Drawing.Point(10, 5)
$titleLabel.Size = New-Object System.Drawing.Size(200, 20)
$titleBar.Controls.Add($titleLabel)

# $header als $titleLabel definieren für Kompatibilität mit Set-Theme
$header = $titleLabel

# Event-Handler für das Verschieben des Fensters
$titleBar.Add_MouseDown({
        param($sender, $e)
        if ($e.Button -eq [System.Windows.Forms.MouseButtons]::Left) {
            $script:mouseOffset = New-Object System.Drawing.Point(
                - $e.X,
                - $e.Y
            )
        }
    })

$titleBar.Add_MouseMove({
        param($sender, $e)
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
        param($sender, $e)
        if ($e.Button -eq [System.Windows.Forms.MouseButtons]::Left) {
            $script:mouseOffset = New-Object System.Drawing.Point(
                - ($e.X + $sender.Left),
                - ($e.Y + $sender.Top)
            )
        }
    })

$titleLabel.Add_MouseMove({
        param($sender, $e)
        if ($e.Button -eq [System.Windows.Forms.MouseButtons]::Left) {
            $mousePos = [System.Windows.Forms.Control]::MousePosition
            $newLocation = New-Object System.Drawing.Point(
                ($mousePos.X + $script:mouseOffset.X),
                ($mousePos.Y + $script:mouseOffset.Y)
            )
            $mainform.Location = $newLocation
        }
    })

# Schließen-Button
$closeButton = New-Object System.Windows.Forms.Button
$closeButton.Text = "×"
$closeButton.Size = New-Object System.Drawing.Size(30, 30)
$closeButton.Location = New-Object System.Drawing.Point(970, 0)
$closeButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$closeButton.FlatAppearance.BorderSize = 0
$closeButton.BackColor = [System.Drawing.Color]::FromArgb(45, 45, 48)
$closeButton.ForeColor = [System.Drawing.Color]::White
$closeButton.Font = New-Object System.Drawing.Font("Segoe UI", 12)
$closeButton.Add_Click({ Close-FormSafely -Form $mainform })
$closeButton.Add_MouseEnter({ $this.BackColor = [System.Drawing.Color]::Red })
$closeButton.Add_MouseLeave({ $this.BackColor = [System.Drawing.Color]::FromArgb(45, 45, 48) })
$titleBar.Controls.Add($closeButton)

# Minimieren-Button durch Info-Button ersetzen
$infoButton = New-Object System.Windows.Forms.Button
$infoButton.Text = "?"
$infoButton.Size = New-Object System.Drawing.Size(30, 30)
$infoButton.Location = New-Object System.Drawing.Point(910, 0)
$infoButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$infoButton.FlatAppearance.BorderSize = 0
$infoButton.BackColor = [System.Drawing.Color]::FromArgb(45, 45, 48)
$infoButton.ForeColor = [System.Drawing.Color]::White
$infoButton.Font = New-Object System.Drawing.Font("Segoe UI", 12)
$infoButton.Add_Click({
        [System.Windows.Forms.MessageBox]::Show(
            "Bocki's System-Tool 3.1`n`nEntwickelt von Bocki`nVersion: 3.1`n`nEin umfassendes Werkzeug für System-Wartung und -Diagnose.",
            "Über System-Tool",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        )
    })
$infoButton.Add_MouseEnter({ $this.BackColor = [System.Drawing.Color]::FromArgb(70, 70, 75) })
$infoButton.Add_MouseLeave({ $this.BackColor = [System.Drawing.Color]::FromArgb(45, 45, 48) })
$titleBar.Controls.Add($infoButton)

# Theme-Button (Dark/Light Mode) in die Titelleiste einfügen
$themeButton = New-Object System.Windows.Forms.Button
$themeButton.Text = "🌙"  # Mond-Symbol für dunkles Theme
$themeButton.Size = New-Object System.Drawing.Size(30, 30)
$themeButton.Location = New-Object System.Drawing.Point(880, 0)  # Links neben dem Info-Button
$themeButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$themeButton.FlatAppearance.BorderSize = 0
$themeButton.BackColor = [System.Drawing.Color]::FromArgb(45, 45, 48)
$themeButton.ForeColor = [System.Drawing.Color]::White
$themeButton.Font = New-Object System.Drawing.Font("Segoe UI Symbol", 12)
$themeButton.Add_Click({
        $isDarkMode = Set-Theme -mainform $mainform -header $header -outputBox $outputBox -themeButton $themeButton -tabControl $tabControl -mainTabControl $mainTabControl
        # Update button icon based on theme
        if ($isDarkMode) {
            $this.Text = "☀️"  
        }
        else {
            $this.Text = "🌙"  
        }
    })
$themeButton.Add_MouseEnter({ $this.BackColor = [System.Drawing.Color]::FromArgb(70, 70, 75) })
$themeButton.Add_MouseLeave({ $this.BackColor = [System.Drawing.Color]::FromArgb(45, 45, 48) })
$titleBar.Controls.Add($themeButton)

# Einstellungen-Button
$settingsButton = New-Object System.Windows.Forms.Button
$settingsButton.Text = "⚙"
$settingsButton.Size = New-Object System.Drawing.Size(30, 30)
$settingsButton.Location = New-Object System.Drawing.Point(940, 0)
$settingsButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$settingsButton.FlatAppearance.BorderSize = 0
$settingsButton.BackColor = [System.Drawing.Color]::FromArgb(45, 45, 48)
$settingsButton.ForeColor = [System.Drawing.Color]::White
$settingsButton.Font = New-Object System.Drawing.Font("Segoe UI", 12)
$settingsButton.Add_Click({
        # Logik für das Einstellungsmenü
        $settingsForm = New-Object System.Windows.Forms.Form
        $settingsForm.Text = "Einstellungen"
        $settingsForm.Size = New-Object System.Drawing.Size(550, 450)
        $settingsForm.StartPosition = "CenterParent"
        $settingsForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
        $settingsForm.MaximizeBox = $false
        $settingsForm.MinimizeBox = $false
        
        # Prüfen, ob wir im Dark Mode sind
        $isDarkMode = $mainform.BackColor -eq [System.Drawing.Color]::FromArgb(28, 30, 36)
        
        # Farben anpassen
        if ($isDarkMode) {
            $settingsForm.BackColor = [System.Drawing.Color]::FromArgb(35, 37, 43)
            $textColor = [System.Drawing.Color]::FromArgb(220, 220, 220)
        }
        else {
            $settingsForm.BackColor = [System.Drawing.Color]::FromArgb(240, 240, 240)
            $textColor = [System.Drawing.Color]::Black
        }
        
        # TabControl für Einstellungskategorien
        $settingsTabControl = New-Object System.Windows.Forms.TabControl
        $settingsTabControl.Location = New-Object System.Drawing.Point(10, 10)
        $settingsTabControl.Size = New-Object System.Drawing.Size(520, 360)
        $settingsTabControl.Font = New-Object System.Drawing.Font("Segoe UI", 9)
        
        # Farbschema anpassen
        if ($isDarkMode) {
            $settingsTabControl.BackColor = [System.Drawing.Color]::FromArgb(45, 47, 53)
        }
        
        # Tab 1: Anzeige-Einstellungen
        $tabDisplay = New-Object System.Windows.Forms.TabPage
        $tabDisplay.Text = "Anzeige"
        $tabDisplay.BackColor = $settingsForm.BackColor
        
        # Schriftgröße Einstellung
        $lblFontSize = New-Object System.Windows.Forms.Label
        $lblFontSize.Text = "Schriftgröße:"
        $lblFontSize.Location = New-Object System.Drawing.Point(15, 20)
        $lblFontSize.Size = New-Object System.Drawing.Size(120, 25)
        $lblFontSize.ForeColor = $textColor
        $tabDisplay.Controls.Add($lblFontSize)
        
        $cmbFontSize = New-Object System.Windows.Forms.ComboBox
        $cmbFontSize.Location = New-Object System.Drawing.Point(150, 20)
        $cmbFontSize.Size = New-Object System.Drawing.Size(70, 25)
        $cmbFontSize.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
        @(8, 9, 10, 11, 12, 14) | ForEach-Object { $cmbFontSize.Items.Add($_) }
        $cmbFontSize.SelectedItem = 10  # Standardwert
        $tabDisplay.Controls.Add($cmbFontSize)
        
        # Fenstergröße speichern
        $chkSaveWindowSize = New-Object System.Windows.Forms.CheckBox
        $chkSaveWindowSize.Text = "Fenstergröße und Position speichern"
        $chkSaveWindowSize.Location = New-Object System.Drawing.Point(15, 60)
        $chkSaveWindowSize.Size = New-Object System.Drawing.Size(300, 25)
        $chkSaveWindowSize.ForeColor = $textColor
        $chkSaveWindowSize.Checked = $true
        $tabDisplay.Controls.Add($chkSaveWindowSize)
        
        # Farbschema Einstellung
        $lblColorScheme = New-Object System.Windows.Forms.Label
        $lblColorScheme.Text = "Farbschema:"
        $lblColorScheme.Location = New-Object System.Drawing.Point(15, 100)
        $lblColorScheme.Size = New-Object System.Drawing.Size(120, 25)
        $lblColorScheme.ForeColor = $textColor
        $tabDisplay.Controls.Add($lblColorScheme)
        
        $cmbColorScheme = New-Object System.Windows.Forms.ComboBox
        $cmbColorScheme.Location = New-Object System.Drawing.Point(150, 100)
        $cmbColorScheme.Size = New-Object System.Drawing.Size(150, 25)
        $cmbColorScheme.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
        @("Standard", "Dunkel (Dark Mode)", "Hell (Light Mode)", "Blau", "Grün") | ForEach-Object { $cmbColorScheme.Items.Add($_) }
        $cmbColorScheme.SelectedItem = if ($isDarkMode) { "Dunkel (Dark Mode)" } else { "Hell (Light Mode)" }
        $tabDisplay.Controls.Add($cmbColorScheme)
        
        # Tab 2: Systemüberwachung
        $tabMonitoring = New-Object System.Windows.Forms.TabPage
        $tabMonitoring.Text = "Überwachung"
        $tabMonitoring.BackColor = $settingsForm.BackColor
        
        # Update-Intervall für Hardware-Überwachung
        $lblUpdateInterval = New-Object System.Windows.Forms.Label
        $lblUpdateInterval.Text = "Update-Intervall (ms):"
        $lblUpdateInterval.Location = New-Object System.Drawing.Point(15, 20)
        $lblUpdateInterval.Size = New-Object System.Drawing.Size(150, 25)
        $lblUpdateInterval.ForeColor = $textColor
        $tabMonitoring.Controls.Add($lblUpdateInterval)
        
        $numUpdateInterval = New-Object System.Windows.Forms.NumericUpDown
        $numUpdateInterval.Location = New-Object System.Drawing.Point(180, 20)
        $numUpdateInterval.Size = New-Object System.Drawing.Size(100, 25)
        $numUpdateInterval.Minimum = 500
        $numUpdateInterval.Maximum = 10000
        $numUpdateInterval.Increment = 100
        $numUpdateInterval.Value = 1000  # Standardwert
        $tabMonitoring.Controls.Add($numUpdateInterval)
        
        # CPU-Warnschwelle
        $lblCpuThreshold = New-Object System.Windows.Forms.Label
        $lblCpuThreshold.Text = "CPU-Warnschwelle (%):"
        $lblCpuThreshold.Location = New-Object System.Drawing.Point(15, 60)
        $lblCpuThreshold.Size = New-Object System.Drawing.Size(150, 25)
        $lblCpuThreshold.ForeColor = $textColor
        $tabMonitoring.Controls.Add($lblCpuThreshold)
        
        $numCpuThreshold = New-Object System.Windows.Forms.NumericUpDown
        $numCpuThreshold.Location = New-Object System.Drawing.Point(180, 60)
        $numCpuThreshold.Size = New-Object System.Drawing.Size(100, 25)
        $numCpuThreshold.Minimum = 50
        $numCpuThreshold.Maximum = 100
        $numCpuThreshold.Increment = 5
        $numCpuThreshold.Value = 90  # Standardwert
        $tabMonitoring.Controls.Add($numCpuThreshold)
        
        # RAM-Warnschwelle
        $lblRamThreshold = New-Object System.Windows.Forms.Label
        $lblRamThreshold.Text = "RAM-Warnschwelle (%):"
        $lblRamThreshold.Location = New-Object System.Drawing.Point(15, 100)
        $lblRamThreshold.Size = New-Object System.Drawing.Size(150, 25)
        $lblRamThreshold.ForeColor = $textColor
        $tabMonitoring.Controls.Add($lblRamThreshold)
        
        $numRamThreshold = New-Object System.Windows.Forms.NumericUpDown
        $numRamThreshold.Location = New-Object System.Drawing.Point(180, 100)
        $numRamThreshold.Size = New-Object System.Drawing.Size(100, 25)
        $numRamThreshold.Minimum = 50
        $numRamThreshold.Maximum = 100
        $numRamThreshold.Increment = 5
        $numRamThreshold.Value = 85  # Standardwert
        $tabMonitoring.Controls.Add($numRamThreshold)
        
        # GPU-Warnschwelle (nach der RAM-Warnschwelle hinzufügen)
        $lblGpuThreshold = New-Object System.Windows.Forms.Label
        $lblGpuThreshold.Text = "GPU-Warnschwelle (%):"
        $lblGpuThreshold.Location = New-Object System.Drawing.Point(15, 140)
        $lblGpuThreshold.Size = New-Object System.Drawing.Size(150, 25)
        $lblGpuThreshold.ForeColor = $textColor
        $tabMonitoring.Controls.Add($lblGpuThreshold)

        $numGpuThreshold = New-Object System.Windows.Forms.NumericUpDown
        $numGpuThreshold.Location = New-Object System.Drawing.Point(180, 140)
        $numGpuThreshold.Size = New-Object System.Drawing.Size(100, 25)
        $numGpuThreshold.Minimum = 50
        $numGpuThreshold.Maximum = 100
        $numGpuThreshold.Increment = 5
        $numGpuThreshold.Value = $script:settings.GpuThreshold  
        $tabMonitoring.Controls.Add($numGpuThreshold)
        
        # Benachrichtigungen aktivieren 
        $chkEnableNotifications = New-Object System.Windows.Forms.CheckBox
        $chkEnableNotifications.Text = "Benachrichtigungen aktivieren"
        $chkEnableNotifications.Location = New-Object System.Drawing.Point(15, 180)
        $chkEnableNotifications.Size = New-Object System.Drawing.Size(300, 25)
        $chkEnableNotifications.ForeColor = $textColor
        $chkEnableNotifications.Checked = $script:settings.EnableNotifications
        $tabMonitoring.Controls.Add($chkEnableNotifications)
        
        # Tab 3: Logs & Berichte
        $tabLogs = New-Object System.Windows.Forms.TabPage
        $tabLogs.Text = "Logs & Berichte"
        $tabLogs.BackColor = $settingsForm.BackColor
        
        # Log-Detailgrad
        $lblLogLevel = New-Object System.Windows.Forms.Label
        $lblLogLevel.Text = "Log-Detailgrad:"
        $lblLogLevel.Location = New-Object System.Drawing.Point(15, 20)
        $lblLogLevel.Size = New-Object System.Drawing.Size(120, 25)
        $lblLogLevel.ForeColor = $textColor
        $tabLogs.Controls.Add($lblLogLevel)
        
        $cmbLogLevel = New-Object System.Windows.Forms.ComboBox
        $cmbLogLevel.Location = New-Object System.Drawing.Point(150, 20)
        $cmbLogLevel.Size = New-Object System.Drawing.Size(150, 25)
        $cmbLogLevel.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
        @("Minimal", "Standard", "Detailliert", "Debug") | ForEach-Object { $cmbLogLevel.Items.Add($_) }
        $cmbLogLevel.SelectedItem = "Standard"  # Standardwert
        $tabLogs.Controls.Add($cmbLogLevel)
        
        # Automatisches Speichern
        $chkAutoSaveLogs = New-Object System.Windows.Forms.CheckBox
        $chkAutoSaveLogs.Text = "Logs automatisch speichern"
        $chkAutoSaveLogs.Location = New-Object System.Drawing.Point(15, 60)
        $chkAutoSaveLogs.Size = New-Object System.Drawing.Size(300, 25)
        $chkAutoSaveLogs.ForeColor = $textColor
        $chkAutoSaveLogs.Checked = $false
        $tabLogs.Controls.Add($chkAutoSaveLogs)
        
        # Log-Speicherort
        $lblLogPath = New-Object System.Windows.Forms.Label
        $lblLogPath.Text = "Log-Speicherort:"
        $lblLogPath.Location = New-Object System.Drawing.Point(15, 100)
        $lblLogPath.Size = New-Object System.Drawing.Size(120, 25)
        $lblLogPath.ForeColor = $textColor
        $tabLogs.Controls.Add($lblLogPath)
        
        $txtLogPath = New-Object System.Windows.Forms.TextBox
        $txtLogPath.Location = New-Object System.Drawing.Point(150, 100)
        $txtLogPath.Size = New-Object System.Drawing.Size(250, 25)
        $txtLogPath.Text = "$PSScriptRoot\Logs"  # Standardwert
        $tabLogs.Controls.Add($txtLogPath)
        
        $btnBrowseLogPath = New-Object System.Windows.Forms.Button
        $btnBrowseLogPath.Text = "..."
        $btnBrowseLogPath.Location = New-Object System.Drawing.Point(410, 100)
        $btnBrowseLogPath.Size = New-Object System.Drawing.Size(30, 25)
        $btnBrowseLogPath.Add_Click({
                $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
                $folderBrowser.Description = "Log-Verzeichnis auswählen"
                $folderBrowser.SelectedPath = $txtLogPath.Text
                if ($folderBrowser.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
                    $txtLogPath.Text = $folderBrowser.SelectedPath
                }
            })
        $tabLogs.Controls.Add($btnBrowseLogPath)
        
        # Tab 4: Programmverhalten
        $tabBehavior = New-Object System.Windows.Forms.TabPage
        $tabBehavior.Text = "Verhalten"
        $tabBehavior.BackColor = $settingsForm.BackColor
        
        # Bestätigungsdialoge
        $chkConfirmActions = New-Object System.Windows.Forms.CheckBox
        $chkConfirmActions.Text = "Aktionen bestätigen (empfohlen)"
        $chkConfirmActions.Location = New-Object System.Drawing.Point(15, 20)
        $chkConfirmActions.Size = New-Object System.Drawing.Size(300, 25)
        $chkConfirmActions.ForeColor = $textColor
        $chkConfirmActions.Checked = $true
        $tabBehavior.Controls.Add($chkConfirmActions)
        
        # Erweiterte Temp-Dateien-Bereinigung als Standard
        $chkAdvancedCleanup = New-Object System.Windows.Forms.CheckBox
        $chkAdvancedCleanup.Text = "Standardmäßig erweiterte Temp-Bereinigung verwenden"
        $chkAdvancedCleanup.Location = New-Object System.Drawing.Point(15, 60)
        $chkAdvancedCleanup.Size = New-Object System.Drawing.Size(350, 25)
        $chkAdvancedCleanup.ForeColor = $textColor
        $chkAdvancedCleanup.Checked = $false
        $tabBehavior.Controls.Add($chkAdvancedCleanup)
        
        # Automatisch auf Updates prüfen
        $chkCheckUpdates = New-Object System.Windows.Forms.CheckBox
        $chkCheckUpdates.Text = "Automatisch auf Programm-Updates prüfen"
        $chkCheckUpdates.Location = New-Object System.Drawing.Point(15, 100)
        $chkCheckUpdates.Size = New-Object System.Drawing.Size(350, 25)
        $chkCheckUpdates.ForeColor = $textColor
        $chkCheckUpdates.Checked = $true
        $tabBehavior.Controls.Add($chkCheckUpdates)
        
        # Splash-Screen anzeigen
        $chkShowSplash = New-Object System.Windows.Forms.CheckBox
        $chkShowSplash.Text = "Startbildschirm anzeigen"
        $chkShowSplash.Location = New-Object System.Drawing.Point(15, 140)
        $chkShowSplash.Size = New-Object System.Drawing.Size(350, 25)
        $chkShowSplash.ForeColor = $textColor
        $chkShowSplash.Checked = $true
        $tabBehavior.Controls.Add($chkShowSplash)
        
        # Tab 5: System
        $tabSystem_Settings = New-Object System.Windows.Forms.TabPage
        $tabSystem_Settings.Text = "System"
        $tabSystem_Settings.BackColor = $settingsForm.BackColor
        
        # Überschrift für System-Wartung
        $lblSystemMaintenance = New-Object System.Windows.Forms.Label
        $lblSystemMaintenance.Text = "System-Wartung"
        $lblSystemMaintenance.Location = New-Object System.Drawing.Point(15, 20)
        $lblSystemMaintenance.Size = New-Object System.Drawing.Size(300, 25)
        $lblSystemMaintenance.ForeColor = $textColor
        $lblSystemMaintenance.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
        $tabSystem_Settings.Controls.Add($lblSystemMaintenance)
        
        # Defender Dienst Neustart Button im System-Tab
        $btnRestartDefenderSettings = New-Object System.Windows.Forms.Button
        $btnRestartDefenderSettings.Text = "Defender Dienst Neustart"
        $btnRestartDefenderSettings.Location = New-Object System.Drawing.Point(15, 50)
        $btnRestartDefenderSettings.Size = New-Object System.Drawing.Size(200, 35)
        $btnRestartDefenderSettings.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
        $btnRestartDefenderSettings.ForeColor = $textColor
        $btnRestartDefenderSettings.Add_Click({
                $settingsForm.Hide()  # Verstecke Einstellungsfenster während der Operation
                Switch-ToOutputTab -TabControl $tabControl
                $outputBox.Clear()
                Update-ProgressStatus -StatusText "Windows Defender-Dienst Neustart wird vorbereitet..." -ProgressValue 0 -TextColor ([System.Drawing.Color]::DarkBlue)
                Restart-DefenderService -outputBox $outputBox -TabControl $tabControl -progressBar $progressBar -MainForm $mainform
                $settingsForm.Show()  # Zeige Einstellungsfenster wieder an
            })
        $tabSystem_Settings.Controls.Add($btnRestartDefenderSettings)
        
        # Beschreibungstext für den Button
        $lblRestartDefenderDesc = New-Object System.Windows.Forms.Label
        $lblRestartDefenderDesc.Text = "Startet Windows Defender-Dienste neu, wenn MRT-Scans hängen oder Probleme auftreten."
        $lblRestartDefenderDesc.Location = New-Object System.Drawing.Point(15, 90)
        $lblRestartDefenderDesc.Size = New-Object System.Drawing.Size(450, 40)
        $lblRestartDefenderDesc.ForeColor = $textColor
        $tabSystem_Settings.Controls.Add($lblRestartDefenderDesc)
        
        # Tabs zum TabControl hinzufügen
        $settingsTabControl.TabPages.Add($tabDisplay)
        $settingsTabControl.TabPages.Add($tabMonitoring)
        $settingsTabControl.TabPages.Add($tabLogs)
        $settingsTabControl.TabPages.Add($tabBehavior)
        $settingsTabControl.TabPages.Add($tabSystem_Settings)
        
        # TabControl zum Formular hinzufügen
        $settingsForm.Controls.Add($settingsTabControl)
        
        # OK-Button
        $btnOK = New-Object System.Windows.Forms.Button
        $btnOK.Text = "OK"
        $btnOK.Location = New-Object System.Drawing.Point(354, 380)
        $btnOK.Size = New-Object System.Drawing.Size(80, 30)
        $btnOK.Add_Click({
                # Einstellungen anwenden und speichern
                $script:settings = @{
                    FontSize            = $cmbFontSize.SelectedItem
                    ColorScheme         = $cmbColorScheme.SelectedItem
                    SaveWindowSize      = $chkSaveWindowSize.Checked
                    UpdateInterval      = $numUpdateInterval.Value
                    CpuThreshold        = $numCpuThreshold.Value
                    RamThreshold        = $numRamThreshold.Value
                    GpuThreshold        = $numGpuThreshold.Value  # GPU-Schwellenwert hinzufügen
                    EnableNotifications = $chkEnableNotifications.Checked
                    LogLevel            = $cmbLogLevel.SelectedItem
                    AutoSaveLogs        = $chkAutoSaveLogs.Checked
                    LogPath             = $txtLogPath.Text
                    ConfirmActions      = $chkConfirmActions.Checked
                    AdvancedCleanup     = $chkAdvancedCleanup.Checked
                    CheckUpdates        = $chkCheckUpdates.Checked
                    ShowSplash          = $chkShowSplash.Checked
                }
                
                # Einstellungen direkt anwenden
                
                # 1. Schriftgröße
                $newFontSize = [int]$script:settings.FontSize
                $outputBox.Font = New-Object System.Drawing.Font($outputBox.Font.FontFamily, $newFontSize)
                $hardwareInfoBox.Font = New-Object System.Drawing.Font($hardwareInfoBox.Font.FontFamily, $newFontSize)
                $systemStatusBox.Font = New-Object System.Drawing.Font($systemStatusBox.Font.FontFamily, $newFontSize)
                $toolInfoBox.Font = New-Object System.Drawing.Font($toolInfoBox.Font.FontFamily, $newFontSize)
                $toolDownloadsBox.Font = New-Object System.Drawing.Font($toolDownloadsBox.Font.FontFamily, $newFontSize)
                
                # 2. Farbschema
                switch ($script:settings.ColorScheme) {
                    "Dunkel (Dark Mode)" {
                        if (-not $isDarkMode) {
                            $themeButton.PerformClick()  # Wechselt zum Dark Mode
                        }
                    }
                    "Hell (Light Mode)" {
                        if ($isDarkMode) {
                            $themeButton.PerformClick()  # Wechselt zum Light Mode
                        }
                    }
                    "Blau" {
                        # Blaues Farbschema anwenden
                        $mainform.BackColor = [System.Drawing.Color]::FromArgb(220, 230, 250)
                        $tabSystem.BackColor = [System.Drawing.Color]::FromArgb(200, 220, 255)
                        $tabDisk.BackColor = [System.Drawing.Color]::FromArgb(210, 225, 250)
                        $tabNetwork.BackColor = [System.Drawing.Color]::FromArgb(220, 230, 245)
                        $tabCleanup.BackColor = [System.Drawing.Color]::FromArgb(230, 235, 240)
                    }
                    "Grün" {
                        # Grünes Farbschema anwenden
                        $mainform.BackColor = [System.Drawing.Color]::FromArgb(230, 245, 230)
                        $tabSystem.BackColor = [System.Drawing.Color]::FromArgb(210, 250, 210)
                        $tabDisk.BackColor = [System.Drawing.Color]::FromArgb(220, 245, 220)
                        $tabNetwork.BackColor = [System.Drawing.Color]::FromArgb(230, 240, 230)
                        $tabCleanup.BackColor = [System.Drawing.Color]::FromArgb(240, 235, 240)
                    }
                }
                
                # 3. Hardware Monitor Update-Intervall anpassen, falls vorhanden
                if ($script:hardwareTimer -ne $null) {
                    $script:hardwareTimer.Interval = [int]$script:settings.UpdateInterval
                }
                
                # 4. Schwellenwerte für Hardware-Überwachung
                $script:cpuThreshold = [int]$script:settings.CpuThreshold
                $script:ramThreshold = [int]$script:settings.RamThreshold
                $script:gpuThreshold = [int]$script:settings.GpuThreshold  # GPU-Schwellenwert hinzufügen
                
                # Einstellungen in Konfigurationsdatei speichern
                $settingsFilePath = "$PSScriptRoot\config.json"
                try {
                    $script:settings | ConvertTo-Json | Out-File -FilePath $settingsFilePath -Encoding UTF8
                }
                catch {
                    Write-Host "Fehler beim Speichern der Einstellungen: $_" -ForegroundColor Red
                }
                
                # Ausgabe in der OutputBox
                $outputBox.SelectionColor = [System.Drawing.Color]::Green
                $outputBox.AppendText("`r`nEinstellungen wurden aktualisiert und angewendet:`r`n")
                $outputBox.SelectionColor = [System.Drawing.Color]::Black
                $outputBox.AppendText("- Schriftgröße: $($script:settings.FontSize)`r`n")
                $outputBox.AppendText("- Farbschema: $($script:settings.ColorScheme)`r`n")
                $outputBox.AppendText("- Update-Intervall: $($script:settings.UpdateInterval) ms`r`n")
                $outputBox.AppendText("- CPU-Warnschwelle: $($script:settings.CpuThreshold)%`r`n")
                $outputBox.AppendText("- RAM-Warnschwelle: $($script:settings.RamThreshold)%`r`n")
                $outputBox.AppendText("- GPU-Warnschwelle: $($script:settings.GpuThreshold)%`r`n")  # GPU-Schwellenwert zur Ausgabe hinzufügen
                $outputBox.AppendText("- Log-Level: $($script:settings.LogLevel)`r`n")
                $outputBox.AppendText("- Einstellungen wurden in $settingsFilePath gespeichert.`r`n")
                
                # Formular schließen
                $settingsForm.Close()
            })
        $settingsForm.Controls.Add($btnOK)
        
        # Abbrechen-Button
        $btnCancel = New-Object System.Windows.Forms.Button
        $btnCancel.Text = "Abbrechen"
        $btnCancel.Location = New-Object System.Drawing.Point(450, 380)
        $btnCancel.Size = New-Object System.Drawing.Size(80, 30)
        $btnCancel.Add_Click({ $settingsForm.Close() })
        $settingsForm.Controls.Add($btnCancel)
        
        # Formular anzeigen
        $settingsForm.ShowDialog()
    })
$settingsButton.Add_MouseEnter({ $this.BackColor = [System.Drawing.Color]::FromArgb(70, 70, 75) })
$settingsButton.Add_MouseLeave({ $this.BackColor = [System.Drawing.Color]::FromArgb(45, 45, 48) })
$titleBar.Controls.Add($settingsButton)

# Titelleiste zum Formular hinzufügen
$mainform.Controls.Add($titleBar)

# Fenster verschiebbar machen
$lastLocation = $null
$titleBar.Add_MouseDown({
        $lastLocation = [System.Windows.Forms.Cursor]::Position
    })

$titleBar.Add_MouseMove({
        if ($lastLocation -and [System.Windows.Forms.Control]::MouseButtons -eq 'Left') {
            $currentLocation = [System.Windows.Forms.Cursor]::Position
            $offset = New-Object System.Drawing.Point(
            ($currentLocation.X - $lastLocation.X),
            ($currentLocation.Y - $lastLocation.Y)
            )
            $mainform.Location = New-Object System.Drawing.Point(
            ($mainform.Location.X + $offset.X),
            ($mainform.Location.Y + $offset.Y)
            )
            $lastLocation = $currentLocation
        }
    })

$titleBar.Add_MouseUp({
        $lastLocation = $null
    })

# Hintergrund-Panel für die Hardware-Monitore
$monitorBackgroundPanel = New-Object System.Windows.Forms.Panel
$monitorBackgroundPanel.Location = New-Object System.Drawing.Point(0, 30)  # Von 20 auf 30 geändert
$monitorBackgroundPanel.Size = New-Object System.Drawing.Size(1050, 85)
$monitorBackgroundPanel.BackColor = [System.Drawing.Color]::FromArgb(220, 230, 240)  
$monitorBackgroundPanel.BackColor = [System.Drawing.Color]::BurlyWood
$mainform.Controls.Add($monitorBackgroundPanel)
$monitorBackgroundPanel.SendToBack()  # Panel in den Hintergrund schicken

# Separate Panels für CPU, GPU und RAM direkt auf dem Hauptformular
$gbCPU = New-Object System.Windows.Forms.Panel
$gbCPU.Location = New-Object System.Drawing.Point(1, 35)  # Von 5 auf 35 geändert
$gbCPU.Size = New-Object System.Drawing.Size(352, 75)   
$gbCPU.BackColor = [System.Drawing.Color]::FromArgb(245, 245, 250)  # Noch helleres Grau
$gbCPU.BackColor = [System.Drawing.Color]::Green 
$mainform.Controls.Add($gbCPU)
$gbCPU.BringToFront()  # CPU-Panel in den Vordergrund

# Label für CPU-Titel
$lblCPUTitle = New-Object System.Windows.Forms.Label
$lblCPUTitle.Text = "CPU wird erkannt..."  # Wird später dynamisch aktualisiert
$lblCPUTitle.Location = New-Object System.Drawing.Point(0, 0)
$lblCPUTitle.Size = New-Object System.Drawing.Size(352, 20)
$lblCPUTitle.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$lblCPUTitle.BackColor = [System.Drawing.Color]::Lavender
$gbCPU.Controls.Add($lblCPUTitle)

$gbGPU = New-Object System.Windows.Forms.Panel
$gbGPU.Location = New-Object System.Drawing.Point(354, 35)   # Von 5 auf 35 geändert
$gbGPU.Size = New-Object System.Drawing.Size(350, 75)   
$gbGPU.BackColor = [System.Drawing.Color]::FromArgb(245, 245, 250)  # Noch helleres Grau
$gbGPU.BackColor = [System.Drawing.Color]::Yellow 
$mainform.Controls.Add($gbGPU)
$gbGPU.BringToFront()  # GPU-Panel in den Vordergrund

# Label für GPU-Titel
$lblGPUTitle = New-Object System.Windows.Forms.Label
$lblGPUTitle.Text = "GPU wird erkannt..."  # Wird später dynamisch aktualisiert
$lblGPUTitle.Location = New-Object System.Drawing.Point(0, 0)
$lblGPUTitle.Size = New-Object System.Drawing.Size(350, 20)
$lblGPUTitle.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$lblGPUTitle.BackColor = [System.Drawing.Color]::Lavender
$gbGPU.Controls.Add($lblGPUTitle)

$gbRAM = New-Object System.Windows.Forms.Panel
$gbRAM.Location = New-Object System.Drawing.Point(705, 35)   # Von 5 auf 35 geändert
$gbRAM.Size = New-Object System.Drawing.Size(350, 75)   
$gbRAM.BackColor = [System.Drawing.Color]::FromArgb(245, 245, 250)  # Noch helleres Grau
$gbRAM.BackColor = [System.Drawing.Color]::Red
$mainform.Controls.Add($gbRAM)
$gbRAM.BringToFront()  # RAM-Panel in den Vordergrund

# Label für RAM-Titel
$lblRAMTitle = New-Object System.Windows.Forms.Label
$lblRAMTitle.Text = "RAM wird erkannt..."  # Wird später dynamisch aktualisiert
$lblRAMTitle.Location = New-Object System.Drawing.Point(0, 0)
$lblRAMTitle.Size = New-Object System.Drawing.Size(350, 20)
$lblRAMTitle.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$lblRAMTitle.BackColor = [System.Drawing.Color]::Lavender
$gbRAM.Controls.Add($lblRAMTitle)

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
$cpuLabel.ForeColor = [System.Drawing.Color]::FromArgb(0, 70, 140)  # Dunkelblau
$cpuLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$cpuLabel.BackColor = [System.Drawing.Color]::Lavender
$gbCPU.Controls.Add($cpuLabel)

# GPU Hardware-Info Label
$gpuLabel = New-Object System.Windows.Forms.Label
$gpuLabel.Text = "GPU-Daten werden geladen..."
$gpuLabel.Location = New-Object System.Drawing.Point(1, 20)
$gpuLabel.Size = New-Object System.Drawing.Size(347, 45)
$gpuLabel.Font = New-Object System.Drawing.Font("Segoe UI Light", 15)  # Schlanke Schriftart
$gpuLabel.ForeColor = [System.Drawing.Color]::FromArgb(0, 100, 0)  # Dunkelgrün
$gpuLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$gpuLabel.BackColor = [System.Drawing.Color]::Lavender
$gbGPU.Controls.Add($gpuLabel)

# RAM Hardware-Info Label
$ramLabel = New-Object System.Windows.Forms.Label
$ramLabel.Text = "RAM-Daten werden geladen..."
$ramLabel.Location = New-Object System.Drawing.Point(1, 20)
$ramLabel.Size = New-Object System.Drawing.Size(347, 45)
$ramLabel.Font = New-Object System.Drawing.Font("Segoe UI Light", 15)  # Schlanke Schriftart
$ramLabel.ForeColor = [System.Drawing.Color]::FromArgb(128, 0, 128)  # Lila
$ramLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$ramLabel.BackColor = [System.Drawing.Color]::Lavender
$gbRAM.Controls.Add($ramLabel)

# Debug-Buttons für die Hardware-Komponenten
$btnDebugCPU = New-Object System.Windows.Forms.Button
$btnDebugCPU.Text = "?"
$btnDebugCPU.Size = New-Object System.Drawing.Size(25, 20)
$btnDebugCPU.Location = New-Object System.Drawing.Point(265, 0)
$btnDebugCPU.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnDebugCPU.BackColor = [System.Drawing.Color]::LightGray
$btnDebugCPU.Add_Click({
        $script:cpuDebugEnabled = -not $script:cpuDebugEnabled
        Set-HardwareDebugMode -Component 'CPU' -Enabled $script:cpuDebugEnabled
        $this.BackColor = if ($script:cpuDebugEnabled) { [System.Drawing.Color]::LightGreen } else { [System.Drawing.Color]::LightGray }
    })
$gbCPU.Controls.Add($btnDebugCPU)
$btnDebugCPU.BringToFront()  # CPU-Panel in den Vordergrund

$btnDebugGPU = New-Object System.Windows.Forms.Button
$btnDebugGPU.Text = "?"
$btnDebugGPU.Size = New-Object System.Drawing.Size(25, 20)
$btnDebugGPU.Location = New-Object System.Drawing.Point(265, 0)
$btnDebugGPU.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnDebugGPU.BackColor = [System.Drawing.Color]::LightGray
$btnDebugGPU.Add_Click({
        $script:gpuDebugEnabled = -not $script:gpuDebugEnabled
        Set-HardwareDebugMode -Component 'GPU' -Enabled $script:gpuDebugEnabled
        $this.BackColor = if ($script:gpuDebugEnabled) { [System.Drawing.Color]::LightGreen } else { [System.Drawing.Color]::LightGray }
    })
$gbGPU.Controls.Add($btnDebugGPU)
$btnDebugGPU.BringToFront()  # GPU-Panel in den Vordergrund

$btnDebugRAM = New-Object System.Windows.Forms.Button
$btnDebugRAM.Text = "?"
$btnDebugRAM.Size = New-Object System.Drawing.Size(25, 20)
$btnDebugRAM.Location = New-Object System.Drawing.Point(265, 0)
$btnDebugRAM.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnDebugRAM.BackColor = [System.Drawing.Color]::LightGray
$btnDebugRAM.Add_Click({
        $script:ramDebugEnabled = -not $script:ramDebugEnabled
        Set-HardwareDebugMode -Component 'RAM' -Enabled $script:ramDebugEnabled
        $this.BackColor = if ($script:ramDebugEnabled) { [System.Drawing.Color]::LightGreen } else { [System.Drawing.Color]::LightGray }
    })
$gbRAM.Controls.Add($btnDebugRAM)
$btnDebugRAM.BringToFront()  # RAM-Panel in den Vordergrund

# Tooltip für die Debug-Buttons erstellen
if (-not $tooltipObj) {
    $tooltipObj = New-Object System.Windows.Forms.ToolTip
    $tooltipObj.IsBalloon = $true
    $tooltipObj.ToolTipTitle = "Debug-Information"
    $tooltipObj.InitialDelay = 500
    $tooltipObj.AutoPopDelay = 5000
}

# Tooltips für Debug-Buttons setzen
$tooltipObj.SetToolTip($btnDebugCPU, "Debug-Modus für CPU-Monitoring aktivieren/deaktivieren")
$tooltipObj.SetToolTip($btnDebugGPU, "Debug-Modus für GPU-Monitoring aktivieren/deaktivieren")
$tooltipObj.SetToolTip($btnDebugRAM, "Debug-Modus für RAM-Monitoring aktivieren/deaktivieren")



# Timer für Hardware-Updates initialisieren
$hardwareResult = Initialize-HardwareMonitoring `
    -cpuLabel $cpuLabel `
    -gpuLabel $gpuLabel `
    -ramLabel $ramLabel `
    -gbCPU $gbCPU `
    -gbGPU $gbGPU `
    -gbRAM $gbRAM `
    -WaitForGuiLoaded `
    -LoadDelayMs 3000

# Prüfen ob Hardware-Initialisierung erfolgreich war
if (-not $hardwareResult) {
    Write-Host "WARNUNG: Hardware-Monitoring konnte nicht vollständig initialisiert werden." -ForegroundColor Yellow
    Write-Host "Das System wird trotzdem gestartet, aber die Hardware-Überwachung funktioniert möglicherweise nicht korrekt." -ForegroundColor Yellow
}

# Globale Variable für den Schließstatus
$script:isClosing = $false
$script:closeAttempts = 0
$script:maxCloseAttempts = 3

# Globale Variablen für Logging
$script:logPath = Join-Path $PSScriptRoot "gui_closing.log"
$script:maxLogSize = 1MB  # Maximale Größe des Log-Files
$script:maxLogEntries = 100  # Maximale Anzahl der Log-Einträge

# Funktion zum Initialisieren der Log-Datei
function Initialize-LogFile {
    if (Test-Path $script:logPath) {
        # Erstelle Backup des alten Logs
        $backupPath = $script:logPath + ".bak"
        if (Test-Path $backupPath) {
            Remove-Item $backupPath -Force
        }
        Rename-Item -Path $script:logPath -NewName ($script:logPath + ".bak") -Force
    }
    
    # Erstelle neue Log-Datei mit Header
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    @"
=== System-Tool Log ===
Erstellt am: $timestamp
Maximale Größe: 1MB
Maximale Einträge: 100
=====================

"@ | Out-File -FilePath $script:logPath -Encoding UTF8
}

# Funktion zum Verwalten der Log-Datei
function Manage-LogFile {
    param(
        [string]$Message,
        [switch]$IsError
    )
    
    try {
        # Prüfe ob Log-Datei existiert
        if (-not (Test-Path $script:logPath)) {
            Initialize-LogFile
        }
        
        # Prüfe Größe und Einträge
        $logItem = Get-Item $script:logPath -ErrorAction SilentlyContinue
        if ($logItem -and ($logItem.Length -gt $script:maxLogSize)) {
            Initialize-LogFile
        }
        
        # Füge neuen Log-Eintrag hinzu
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $logEntry = "`n=== GUI Closing Log $timestamp ===`n"
        if ($IsError) {
            $logEntry += "[ERROR] "
        }
        $logEntry += $Message
        $logEntry | Add-Content -Path $script:logPath -Encoding UTF8
    }
    catch {
        Write-Warning "Fehler beim Schreiben des Logs: $_"
    }
}

# Initialisiere Log-Datei beim Start
Initialize-LogFile

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
        
        # Hardware-Monitoring stoppen
        if ($script:hardwareTimer -ne $null) {
            Write-Host "Close-FormSafely: Stoppe Hardware-Timer..."
            $script:hardwareTimer.Stop()
            $script:hardwareTimer.Dispose()
            $script:hardwareTimer = $null
        }
        
        # Controls deaktivieren
        Write-Host "Close-FormSafely: Deaktiviere Controls..."
        $Form.SuspendLayout()
        foreach ($control in $Form.Controls) {
            if ($control -ne $null) {
                $control.Enabled = $false
            }
        }
        
        # Garbage Collection
        Write-Host "Close-FormSafely: Führe Garbage Collection durch..."
        [System.GC]::Collect()
        [System.GC]::WaitForPendingFinalizers()
        
        # Direktes Beenden der Anwendung
        Write-Host "Close-FormSafely: Beende Anwendung..."
        [System.Environment]::Exit(0)
    }
    catch {
        Write-Warning "Close-FormSafely: Fehler beim Schließen: $_"
        # Notfall-Beendigung
        [System.Environment]::Exit(0)
    }
}

# Event-Handler für FormClosing
$mainform.Add_FormClosing({
        param($sender, $e)
    
        # Protokollieren des Schließversuchs
        Write-Host "Schließvorgang wird gestartet..."
    
        # Wenn wir bereits im Schließvorgang sind, nicht erneut durchführen
        if ($script:isClosing) {
            return
        }
    
        # Schließvorgang verhindern für normale Verarbeitung
        $e.Cancel = $true
    
        try {
            # Flag setzen, dass wir im Schließvorgang sind
            $script:isClosing = $true
        
            # Hardware-Monitoring stoppen
            if ($script:hardwareTimer -ne $null) {
                Write-Host "Stoppe Hardware-Timer..."
                $script:hardwareTimer.Stop()
                $script:hardwareTimer.Dispose()
                $script:hardwareTimer = $null
            }
        
            # Controls deaktivieren
            Write-Host "Deaktiviere Controls..."
            $sender.SuspendLayout()
            foreach ($control in $sender.Controls) {
                if ($control -ne $null) {
                    $control.Enabled = $false
                }
            }
        
            # Garbage Collection
            Write-Host "Führe Garbage Collection durch..."
            [System.GC]::Collect()
            [System.GC]::WaitForPendingFinalizers()
        
            # Direktes Beenden mit System.Environment.Exit(0)
            Write-Host "Beende Anwendung..."
            [System.Environment]::Exit(0)
        }
        catch {
            Write-Warning "Fehler beim Schließen: $_"
            # Notfall-Beendigung
            [System.Environment]::Exit(0)
        }
    })

# Event-Handler für Form-Bewegung, um PowerShell-Konsole neu zu positionieren
$lastLocation = $null
$mainform.Add_LocationChanged({
        try {
            if ($mainform.Visible -and $mainform.WindowState -ne [System.Windows.Forms.FormWindowState]::Minimized) {
                # Direkter P/Invoke-Ansatz für maximale Kompatibilität
                $signature = @'
            [DllImport("kernel32.dll")]
            public static extern IntPtr GetConsoleWindow();
            
            [DllImport("user32.dll")]
            public static extern bool MoveWindow(IntPtr hWnd, int X, int Y, int nWidth, int nHeight, bool bRepaint);
            
            [DllImport("user32.dll")]
            public static extern bool GetWindowRect(IntPtr hWnd, ref RECT lpRect);
            
            [StructLayout(LayoutKind.Sequential)]
            public struct RECT
            {
                public int Left;
                public int Top;
                public int Right;
                public int Bottom;
            }
'@
                try {
                    $type = Add-Type -MemberDefinition $signature -Name "DynamicWindowPosHelper" -Namespace "Win32Interop" -PassThru -ErrorAction SilentlyContinue
                }
                catch {
                    # Nutze vorhandenen Typ falls verfügbar
                    if (('Win32Interop.DynamicWindowPosHelper' -as [type])) {
                        $type = [Win32Interop.DynamicWindowPosHelper]
                    }
                    else {
                        # Falls kein Typ verfügbar, einfach nichts tun
                        return
                    }
                }
            
                # Hole das PowerShell-Konsolenfenster
                $consoleHandle = $type::GetConsoleWindow()
                if ($consoleHandle -ne [IntPtr]::Zero) {
                    # Aktuelle Konsolengröße ermitteln
                    $rect = New-Object Win32Interop.RECT
                    [void]$type::GetWindowRect($consoleHandle, [ref]$rect)
                
                    $consoleWidth = $rect.Right - $rect.Left
                    $consoleHeight = $rect.Bottom - $rect.Top
                
                    # Neue Position für PowerShell-Fenster berechnen (links neben der GUI)
                    $newConsoleLeft = [Math]::Max(0, $mainform.Left - $consoleWidth - 10) # 10 Pixel Abstand
                    $newConsoleTop = $mainform.Top
                
                    # Konsolenfenster neu positionieren
                    [void]$type::MoveWindow($consoleHandle, $newConsoleLeft, $newConsoleTop, $consoleWidth, $consoleHeight, $true)
                }
            }
        }
        catch {
            # Fehler beim Neupositionieren ignorieren
        }
    })

# GroupBox für den Haupt-TabControl erstellen
$gbMainTabControl = New-Object System.Windows.Forms.GroupBox
$gbMainTabControl.Text = "Hauptfunktionen"
$gbMainTabControl.Location = New-Object System.Drawing.Point(5, 125)  # Y-Position von 90 auf 95 geändert
$gbMainTabControl.Size = New-Object System.Drawing.Size(990, 330)
$gbMainTabControl.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$gbMainTabControl.ForeColor = [System.Drawing.Color]::FromArgb(60, 60, 80)  # Dunkelblaugrau
$mainform.Controls.Add($gbMainTabControl)

# Erstelle einen Haupt-TabControl für die Funktionsgruppen
$mainTabControl = New-Object System.Windows.Forms.TabControl
$mainTabControl.Location = New-Object System.Drawing.Point(10, 20)
$mainTabControl.Size = New-Object System.Drawing.Size(970, 300)
$mainTabControl.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$mainTabControl.SelectedIndex = 0
$mainTabControl.BackColor = [System.Drawing.Color]::FromArgb(245, 245, 250)  # Sehr helles Blaugrau
$mainTabControl.Padding = New-Object System.Drawing.Point(12, 4)
$mainTabControl.ItemSize = New-Object System.Drawing.Size(120, 30)
$gbMainTabControl.Controls.Add($mainTabControl)

# Gemeinsame Hintergrundfarbe für alle Tabs
$tabBackColor = [System.Drawing.Color]::FromArgb(240, 240, 245)  # Sehr helles Blaugrau

# Farbdefinitionen für die Haupttabs
$tabSystemColor = [System.Drawing.Color]::FromArgb(235, 245, 251)  # Hellblau
$tabDiskColor = [System.Drawing.Color]::FromArgb(235, 251, 235)    # Hellgrün
$tabNetworkColor = [System.Drawing.Color]::FromArgb(245, 235, 251) # Helllila
$tabCleanupColor = [System.Drawing.Color]::FromArgb(251, 235, 235) # Hellrot
# $tabHardwareMonitorColor = [System.Drawing.Color]::FromArgb(235, 255, 245)  # Hellmintgrün

# Farbdefinitionen für die aktiven Tabs (kräftigere Farben)
$tabSystemActiveColor = [System.Drawing.Color]::FromArgb(200, 225, 255)  # Kräftigeres Blau
$tabDiskActiveColor = [System.Drawing.Color]::FromArgb(200, 255, 200)    # Kräftigeres Grün
$tabNetworkActiveColor = [System.Drawing.Color]::FromArgb(225, 200, 255) # Kräftigeres Lila
$tabCleanupActiveColor = [System.Drawing.Color]::FromArgb(255, 200, 200) # Kräftigeres Rot
# $tabHardwareMonitorActiveColor = [System.Drawing.Color]::FromArgb(200, 255, 220) # Kräftigeres Mintgrün

# Farbdefinitionen für die Ausgabe-Tabs
$tabOutputColor = [System.Drawing.Color]::WhiteSmoke
$tabAdvancedColor = [System.Drawing.Color]::FromArgb(240, 248, 255) # Alice Blue
$tabHardwareColor = [System.Drawing.Color]::FromArgb(245, 245, 220) # Beige
$tabToolInfoColor = [System.Drawing.Color]::FromArgb(245, 245, 245) # Hellgrau
$tabToolDownloadsColor = [System.Drawing.Color]::FromArgb(245, 245, 245) # Hellgrau

# Aktive Farben für Ausgabe-Tabs
$tabOutputActiveColor = [System.Drawing.Color]::White
$tabAdvancedActiveColor = [System.Drawing.Color]::FromArgb(220, 240, 255) # Kräftigeres Alice Blue
$tabHardwareActiveColor = [System.Drawing.Color]::FromArgb(235, 235, 200) # Kräftigeres Beige
$tabToolInfoActiveColor = [System.Drawing.Color]::FromArgb(235, 235, 235) # Kräftigeres Grau
$tabToolDownloadsActiveColor = [System.Drawing.Color]::FromArgb(235, 235, 235) # Kräftigeres Grau

# Tabs für die verschiedenen Funktionsgruppen
$tabSystem = New-Object System.Windows.Forms.TabPage
$tabSystem.Text = "System & Sicherheit"
$tabSystem.BackColor = $tabSystemColor
$mainTabControl.TabPages.Add($tabSystem)

$tabDisk = New-Object System.Windows.Forms.TabPage
$tabDisk.Text = "Diagnose & Reparatur"
$tabDisk.BackColor = $tabDiskColor
$mainTabControl.TabPages.Add($tabDisk)

$tabNetwork = New-Object System.Windows.Forms.TabPage
$tabNetwork.Text = "Netzwerk-Tools"
$tabNetwork.BackColor = $tabNetworkColor
$mainTabControl.TabPages.Add($tabNetwork)

$tabCleanup = New-Object System.Windows.Forms.TabPage
$tabCleanup.Text = "Bereinigung"
$tabCleanup.BackColor = $tabCleanupColor
$mainTabControl.TabPages.Add($tabCleanup)



# Info-Buttons für die Tabs erstellen
$infoButtonSystemTab = New-ModernInfoButton -x 940 -y 10 -clickAction {
    [System.Windows.Forms.MessageBox]::Show(
        "System & Sicherheit Übersicht:

Dieser Tab enthält Tools zur Diagnose, Wartung und Absicherung des Windows-Betriebssystems:

• System & Sicherheit: MRT-Scans und Windows Defender zur Malware-Erkennung
• System-Wartung: SFC Check zur Reparatur von Windows-Dateien und Windows Update

Verwenden Sie diese Tools, wenn Ihr System instabil ist, Sie Sicherheitsprobleme vermuten oder grundlegende Systemprüfungen durchführen möchten.",
        "System & Sicherheit Hilfe",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Information
    )
}
$tabSystem.Controls.Add($infoButtonSystemTab)

$infoButtonDiskTab = New-ModernInfoButton -x 940 -y 10 -clickAction {
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
$tabDisk.Controls.Add($infoButtonDiskTab)

$infoButtonNetworkTab = New-ModernInfoButton -x 940 -y 10 -clickAction {
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
$tabNetwork.Controls.Add($infoButtonNetworkTab)

$infoButtonCleanupTab = New-ModernInfoButton -x 940 -y 10 -clickAction {
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
$tabCleanup.Controls.Add($infoButtonCleanupTab)



# Erstellung von TableLayoutPanels für eine bessere Strukturierung der Buttons
$tblSystem = New-Object System.Windows.Forms.Panel
$tblSystem.Dock = [System.Windows.Forms.DockStyle]::Fill
$tabSystem.Controls.Add($tblSystem)

$tblDisk = New-Object System.Windows.Forms.Panel
$tblDisk.Dock = [System.Windows.Forms.DockStyle]::Fill
$tabDisk.Controls.Add($tblDisk)

$tblNetwork = New-Object System.Windows.Forms.Panel
$tblNetwork.Dock = [System.Windows.Forms.DockStyle]::Fill
$tabNetwork.Controls.Add($tblNetwork)

$tblCleanup = New-Object System.Windows.Forms.Panel
$tblCleanup.Dock = [System.Windows.Forms.DockStyle]::Fill
$tabCleanup.Controls.Add($tblCleanup)

# GroupBoxes für System-Tab erstellen
$gbSystemSecurity = New-Object System.Windows.Forms.GroupBox
$gbSystemSecurity.Text = "System & Sicherheit"
$gbSystemSecurity.Location = New-Object System.Drawing.Point(30, 30)
$gbSystemSecurity.Size = New-Object System.Drawing.Size(440, 220)
$tblSystem.Controls.Add($gbSystemSecurity)

$gbSystemMaintenance = New-Object System.Windows.Forms.GroupBox
$gbSystemMaintenance.Text = "System-Wartung"
$gbSystemMaintenance.Location = New-Object System.Drawing.Point(500, 30)
$gbSystemMaintenance.Size = New-Object System.Drawing.Size(440, 95)
$tblSystem.Controls.Add($gbSystemMaintenance)

# GroupBoxes für Disk-Tab erstellen
$gbDiskCheck = New-Object System.Windows.Forms.GroupBox
$gbDiskCheck.Text = "Festplatten-Prüfung"
$gbDiskCheck.Location = New-Object System.Drawing.Point(30, 155)
$gbDiskCheck.Size = New-Object System.Drawing.Size(440, 95)
$tblDisk.Controls.Add($gbDiskCheck)

$gbDiskRepair = New-Object System.Windows.Forms.GroupBox
$gbDiskRepair.Text = "System-Reparatur (DISM)"
$gbDiskRepair.Location = New-Object System.Drawing.Point(500, 30)
$gbDiskRepair.Size = New-Object System.Drawing.Size(440, 220)
$tblDisk.Controls.Add($gbDiskRepair)

# Neue GroupBox für Diagnose im Disk-Tab
$gbDiagnostics = New-Object System.Windows.Forms.GroupBox
$gbDiagnostics.Text = "Diagnose"
$gbDiagnostics.Location = New-Object System.Drawing.Point(30, 30)
$gbDiagnostics.Size = New-Object System.Drawing.Size(440, 95)
$tblDisk.Controls.Add($gbDiagnostics)

# GroupBoxes für Network-Tab erstellen
$gbNetworkDiagnostics = New-Object System.Windows.Forms.GroupBox
$gbNetworkDiagnostics.Text = "Netzwerk-Diagnose"
$gbNetworkDiagnostics.Location = New-Object System.Drawing.Point(30, 30)
$gbNetworkDiagnostics.Size = New-Object System.Drawing.Size(440, 95)
$tblNetwork.Controls.Add($gbNetworkDiagnostics)

$gbNetworkRepair = New-Object System.Windows.Forms.GroupBox
$gbNetworkRepair.Text = "Netzwerk-Reparatur"
$gbNetworkRepair.Location = New-Object System.Drawing.Point(500, 30)
$gbNetworkRepair.Size = New-Object System.Drawing.Size(440, 95)
$tblNetwork.Controls.Add($gbNetworkRepair)

# GroupBoxes für Cleanup-Tab erstellen
$gbCleanupSystem = New-Object System.Windows.Forms.GroupBox
$gbCleanupSystem.Text = "System-Bereinigung"
$gbCleanupSystem.Location = New-Object System.Drawing.Point(30, 30)
$gbCleanupSystem.Size = New-Object System.Drawing.Size(440, 95)
$tblCleanup.Controls.Add($gbCleanupSystem)

$gbCleanupTemp = New-Object System.Windows.Forms.GroupBox
$gbCleanupTemp.Text = "Temporäre Dateien"
$gbCleanupTemp.Location = New-Object System.Drawing.Point(500, 30)
$gbCleanupTemp.Size = New-Object System.Drawing.Size(440, 95)
$tblCleanup.Controls.Add($gbCleanupTemp)



# Erstelle GroupBox für den TabControl
$gbOutputTabs = New-Object System.Windows.Forms.GroupBox
$gbOutputTabs.Text = "System-Informationen und Ausgabe"
$gbOutputTabs.Location = New-Object System.Drawing.Point(5, 465)
$gbOutputTabs.Size = New-Object System.Drawing.Size(990, 360)
$gbOutputTabs.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$gbOutputTabs.ForeColor = [System.Drawing.Color]::FromArgb(60, 60, 80)  # Dunkelblaugrau
$mainform.Controls.Add($gbOutputTabs)

# Erstelle eine TabControl für die Ausgabe
$tabControl = New-Object System.Windows.Forms.TabControl
$tabControl.Location = New-Object System.Drawing.Point(10, 20)
$tabControl.Size = New-Object System.Drawing.Size(970, 330)
$tabControl.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$tabControl.SelectedIndex = 0
$tabControl.Appearance = [System.Windows.Forms.TabAppearance]::Normal
$tabControl.SizeMode = [System.Windows.Forms.TabSizeMode]::Fixed
$tabControl.Padding = New-Object System.Drawing.Point(12, 4)
$tabControl.ItemSize = New-Object System.Drawing.Size(120, 30)
$gbOutputTabs.Controls.Add($tabControl)

# Erstelle den Standard-Tab für die Ausgabe
$tabOutput = New-Object System.Windows.Forms.TabPage
$tabOutput.Text = "Ausgabe"
$tabOutput.BackColor = $tabOutputColor
$tabControl.TabPages.Add($tabOutput)

# Erstelle einen zweiten Tab für erweiterte Funktionen
$tabAdvanced = New-Object System.Windows.Forms.TabPage
$tabAdvanced.Text = "Status-Info"
$tabAdvanced.BackColor = $tabAdvancedColor
$tabControl.TabPages.Add($tabAdvanced)

# Erstelle System-Status-Box für den Advanced-Tab
$systemStatusBox = New-Object System.Windows.Forms.RichTextBox
$systemStatusBox.Location = New-Object System.Drawing.Point(5, 5)
$systemStatusBox.Size = New-Object System.Drawing.Size(960, 320)
$systemStatusBox.Font = New-Object System.Drawing.Font("Consolas", 10)
$systemStatusBox.Multiline = $true
$systemStatusBox.ScrollBars = "Both"
$systemStatusBox.WordWrap = $false
$systemStatusBox.ReadOnly = $true
$systemStatusBox.BackColor = [System.Drawing.Color]::White
$systemStatusBox.Text = "System-Status wird geladen...`r`n"
$tabAdvanced.Controls.Add($systemStatusBox)

# Erstelle einen Dummy für $progressStatusLabel
#$progressStatusLabel = $null

# Erstelle eine benutzerdefinierte ProgressBar-Klasse mit Text-Anzeige
Add-Type -TypeDefinition @"
using System;
using System.Windows.Forms;
using System.Drawing;

public class TextProgressBar : ProgressBar
{
    private string _text = "";
    private Color _textColor = Color.DarkBlue;

    public TextProgressBar() : base()
    {
        this.SetStyle(ControlStyles.UserPaint, true);
    }

    public string CustomText
    {
        get { return _text; }
        set { 
            _text = value;
            this.Invalidate();
        }
    }

    public Color TextColor
    {
        get { return _textColor; }
        set { 
            _textColor = value;
            this.Invalidate();
        }
    }

    protected override void OnPaint(PaintEventArgs e)
    {
        Rectangle rect = this.ClientRectangle;
        Graphics g = e.Graphics;

        ProgressBarRenderer.DrawHorizontalBar(g, rect);
        
        rect.Inflate(-3, -3);
        if (Value > 0)
        {
            Rectangle clip = new Rectangle(rect.X, rect.Y, (int)Math.Round(((float)Value / Maximum) * rect.Width), rect.Height);
            ProgressBarRenderer.DrawHorizontalChunks(g, clip);
        }

        if (!string.IsNullOrEmpty(_text))
        {
            using (Font f = new Font("Segoe UI", 9, FontStyle.Bold))
            {
                SizeF textSize = g.MeasureString(_text, f);
                Point textPos = new Point(
                    (int)(rect.X + (rect.Width / 2) - (textSize.Width / 2)),
                    (int)(rect.Y + (rect.Height / 2) - (textSize.Height / 2))
                );
                
                // Zeichne den Text mit Schatten für bessere Lesbarkeit
                using (SolidBrush shadowBrush = new SolidBrush(Color.FromArgb(60, 0, 0, 0)))
                {
                    g.DrawString(_text, f, shadowBrush, textPos.X + 1, textPos.Y + 1);
                }
                
                using (SolidBrush textBrush = new SolidBrush(_textColor))
                {
                    g.DrawString(_text, f, textBrush, textPos);
                }
            }
        }
    }
}
"@ -ReferencedAssemblies "System.Windows.Forms", "System.Drawing"

# Entferne das alte Status-Label
# $progressStatusLabel.Dispose()

# Erstelle die neue TextProgressBar anstelle der alten ProgressBar
$progressBar = New-Object TextProgressBar
$progressBar.Location = New-Object System.Drawing.Point(130, 835)
$progressBar.Size = New-Object System.Drawing.Size(650, 30)
$progressBar.Style = "Continuous"
$progressBar.Minimum = 0
$progressBar.Maximum = 100
$progressBar.Value = 0
$progressBar.CustomText = "Bereit"
$progressBar.TextColor = [System.Drawing.Color]::DarkBlue
$mainform.Controls.Add($progressBar)

# Aktualisiere die Update-ProgressStatus Funktion im ProgressBarTools-Modul
function Update-ProgressStatus {
    param (
        [string]$StatusText,
        [int]$ProgressValue,
        [System.Drawing.Color]$TextColor = [System.Drawing.Color]::DarkBlue
    )
    
    if ($null -eq $script:progressBar) {
        Write-Warning "ProgressBar-Komponente wurde nicht initialisiert."
        return
    }
    
    # Text direkt in der ProgressBar anzeigen
    if ($script:progressBar.GetType().Name -eq "TextProgressBar") {
        $script:progressBar.CustomText = $StatusText
        $script:progressBar.TextColor = $TextColor
    }
    
    $script:progressBar.Value = $ProgressValue
    
    # Form aktualisieren
    [System.Windows.Forms.Application]::DoEvents()
}

# Stelle sicher, dass das ProgressBarTools-Modul geladen ist
if (-not (Get-Command -Name Initialize-ProgressComponents -ErrorAction SilentlyContinue)) {
    Import-Module "$PSScriptRoot\Modules\Core\ProgressBarTools.psm1" -Force
}

# Initialize-ProgressComponents muss nun auch angepasst werden
Initialize-ProgressComponents -ProgressBar $progressBar -StatusLabel $progressStatusLabel

# Erstelle einen dritten Tab für zukünftige Erweiterungen
$tabExtensions = New-Object System.Windows.Forms.TabPage
$tabExtensions.Text = "Hardware-Info"
$tabExtensions.BackColor = $tabHardwareColor
$tabControl.TabPages.Add($tabExtensions)

# Erstelle einen vierten Tab für Tool-Info
$tabToolInfo = New-Object System.Windows.Forms.TabPage
$tabToolInfo.Text = "Tool-Info"
$tabToolInfo.BackColor = $tabToolInfoColor
$tabControl.TabPages.Add($tabToolInfo)

# Erstelle Output-Box und füge sie zum Output-Tab hinzu
$outputBox = New-Object System.Windows.Forms.RichTextBox
$outputBox.Location = New-Object System.Drawing.Point(5, 5)
$outputBox.Size = New-Object System.Drawing.Size(950, 290)
$outputBox.Font = New-Object System.Drawing.Font("Consolas", 12)
$outputBox.Multiline = $true
$outputBox.ScrollBars = "Vertical"
$outputBox.WordWrap = $true
$outputBox.ReadOnly = $true
$outputBox.BackColor = [System.Drawing.Color]::White
$outputBox.Text = "System-Tool bereit. Bitte wählen Sie eine Funktion aus.`r`n"
$outputBox.Dock = [System.Windows.Forms.DockStyle]::None

# Event-Handler für automatisches Scrollen hinzufügen
$outputBox.Add_TextChanged({ 
        # Cursor ans Ende des Textes setzen
        $this.SelectionStart = $this.TextLength
        # Zum Cursor scrollen
        $this.ScrollToCaret()
    })

# Output-Box dem TabOutput hinzufügen
$tabOutput.Controls.Add($outputBox)

# Erstelle Output-Box für Hardware-Info und füge sie zum Hardware-Info-Tab hinzu
$hardwareInfoBox = New-Object System.Windows.Forms.RichTextBox
$hardwareInfoBox.Location = New-Object System.Drawing.Point(0, 30)
$hardwareInfoBox.Size = New-Object System.Drawing.Size(964, 302)
$hardwareInfoBox.Font = New-Object System.Drawing.Font("Consolas", 12)
$hardwareInfoBox.Multiline = $true
$hardwareInfoBox.ScrollBars = "Both"
$hardwareInfoBox.WordWrap = $false
$hardwareInfoBox.ReadOnly = $true
$hardwareInfoBox.BackColor = [System.Drawing.Color]::White
$hardwareInfoBox.Text = "Hardware-Informationen werden geladen...`r`n"
$hardwareInfoBox.Dock = [System.Windows.Forms.DockStyle]::Fill

# Funktion zum Abrufen der Hardware-Informationen
function Get-HardwareInfo {
    param (
        [System.Windows.Forms.RichTextBox]$infoBox
    )
    
    $infoBox.Clear()
    $infoBox.SelectionColor = [System.Drawing.Color]::DarkBlue
    $infoBox.AppendText("===== HARDWARE-INFORMATIONEN =====`r`n`r`n")
    
    # CPU-Informationen
    $infoBox.SelectionColor = [System.Drawing.Color]::Blue
    $infoBox.AppendText("CPU-INFORMATIONEN:`r`n")
    $infoBox.SelectionColor = [System.Drawing.Color]::Black
    
    try {
        $cpuInfo = Get-WmiObject -Class Win32_Processor
        foreach ($cpu in $cpuInfo) {
            $infoBox.AppendText("Prozessor: $($cpu.Name)`r`n")
            $infoBox.AppendText("Kerne: $($cpu.NumberOfCores)`r`n")
            $infoBox.AppendText("Logische Prozessoren: $($cpu.NumberOfLogicalProcessors)`r`n")
            $infoBox.AppendText("Taktrate: $($cpu.MaxClockSpeed) MHz`r`n")
            $infoBox.AppendText("Cache: $(($cpu.L3CacheSize / 1024)) MB`r`n`r`n")
        }
    }
    catch {
        $infoBox.SelectionColor = [System.Drawing.Color]::Red
        $infoBox.AppendText("Fehler beim Abrufen der CPU-Informationen: $_`r`n`r`n")
    }
    
    # RAM-Informationen
    $infoBox.SelectionColor = [System.Drawing.Color]::Blue
    $infoBox.AppendText("RAM-INFORMATIONEN:`r`n")
    $infoBox.SelectionColor = [System.Drawing.Color]::Black
    
    try {
        $totalRAM = (Get-WmiObject -Class Win32_ComputerSystem).TotalPhysicalMemory / 1GB
        $infoBox.AppendText("Gesamter RAM: $([math]::Round($totalRAM, 2)) GB`r`n")
        
        $memoryModules = Get-WmiObject -Class Win32_PhysicalMemory
        $infoBox.AppendText("Anzahl der RAM-Module: $($memoryModules.Count)`r`n")
        
        foreach ($module in $memoryModules) {
            $capacity = $module.Capacity / 1GB
            $infoBox.AppendText("RAM-Modul: $([math]::Round($capacity, 2)) GB ($($module.DeviceLocator))`r`n")
        }
        $infoBox.AppendText("`r`n")
    }
    catch {
        $infoBox.SelectionColor = [System.Drawing.Color]::Red
        $infoBox.AppendText("Fehler beim Abrufen der RAM-Informationen: $_`r`n`r`n")
    }
    
    # Grafikkarten-Informationen
    $infoBox.SelectionColor = [System.Drawing.Color]::Blue
    $infoBox.AppendText("GRAFIKKARTEN-INFORMATIONEN:`r`n")
    $infoBox.SelectionColor = [System.Drawing.Color]::Black
    
    try {
        $gpuInfo = Get-WmiObject -Class Win32_VideoController
        foreach ($gpu in $gpuInfo) {
            $infoBox.AppendText("Grafikkarte: $($gpu.Name)`r`n")
            $infoBox.AppendText("Treiber-Version: $($gpu.DriverVersion)`r`n")
            $infoBox.AppendText("Video-RAM: $(($gpu.AdapterRAM / 1MB)) MB`r`n")
            $infoBox.AppendText("Aktueller Modus: $($gpu.CurrentHorizontalResolution) x $($gpu.CurrentVerticalResolution)`r`n`r`n")
        }
    }
    catch {
        $infoBox.SelectionColor = [System.Drawing.Color]::Red
        $infoBox.AppendText("Fehler beim Abrufen der Grafikkarten-Informationen: $_`r`n`r`n")
    }
    
    # Festplatten-Informationen
    $infoBox.SelectionColor = [System.Drawing.Color]::Blue
    $infoBox.AppendText("FESTPLATTEN-INFORMATIONEN:`r`n")
    $infoBox.SelectionColor = [System.Drawing.Color]::Black
    
    try {
        $drives = Get-WmiObject -Class Win32_DiskDrive
        foreach ($drive in $drives) {
            $sizeGB = [math]::Round($drive.Size / 1GB, 2)
            $infoBox.AppendText("Laufwerk: $($drive.Model)`r`n")
            $infoBox.AppendText("Größe: $sizeGB GB`r`n")
            $infoBox.AppendText("Schnittstelle: $($drive.InterfaceType)`r`n`r`n")
        }
        
        # Logische Laufwerke und freier Speicherplatz
        $infoBox.SelectionColor = [System.Drawing.Color]::Blue
        $infoBox.AppendText("LOGISCHE LAUFWERKE:`r`n")
        $infoBox.SelectionColor = [System.Drawing.Color]::Black
        
        $logicalDrives = Get-WmiObject -Class Win32_LogicalDisk -Filter "DriveType=3"
        foreach ($logicalDrive in $logicalDrives) {
            $freeGB = [math]::Round($logicalDrive.FreeSpace / 1GB, 2)
            $sizeGB = [math]::Round($logicalDrive.Size / 1GB, 2)
            $usedPercent = [math]::Round(($logicalDrive.Size - $logicalDrive.FreeSpace) / $logicalDrive.Size * 100, 1)
            
            $infoBox.AppendText("Laufwerk $($logicalDrive.DeviceID) ($($logicalDrive.VolumeName))`r`n")
            $infoBox.AppendText("Gesamtgröße: $sizeGB GB`r`n")
            $infoBox.AppendText("Freier Speicher: $freeGB GB`r`n")
            $infoBox.AppendText("Belegung: $usedPercent%`r`n`r`n")
        }
    }
    catch {
        $infoBox.SelectionColor = [System.Drawing.Color]::Red
        $infoBox.AppendText("Fehler beim Abrufen der Laufwerk-Informationen: $_`r`n`r`n")
    }
    
    # Netzwerk-Informationen
    $infoBox.SelectionColor = [System.Drawing.Color]::Blue
    $infoBox.AppendText("NETZWERK-INFORMATIONEN:`r`n")
    $infoBox.SelectionColor = [System.Drawing.Color]::Black
    
    try {
        $networkAdapters = Get-WmiObject -Class Win32_NetworkAdapter | Where-Object { $_.PhysicalAdapter -eq $true }
        foreach ($adapter in $networkAdapters) {
            $infoBox.AppendText("Adapter: $($adapter.Name)`r`n")
            $infoBox.AppendText("MAC-Adresse: $($adapter.MACAddress)`r`n")
            
            $config = Get-WmiObject -Class Win32_NetworkAdapterConfiguration | Where-Object { $_.Index -eq $adapter.Index }
            if ($config -and $config.IPAddress) {
                $infoBox.AppendText("IP-Adressen: $($config.IPAddress -join ', ')`r`n")
            }
            $infoBox.AppendText("`r`n")
        }
    }
    catch {
        $infoBox.SelectionColor = [System.Drawing.Color]::Red
        $infoBox.AppendText("Fehler beim Abrufen der Netzwerk-Informationen: $_`r`n`r`n")
    }
    
    # Betriebssystem-Informationen
    $infoBox.SelectionColor = [System.Drawing.Color]::Blue
    $infoBox.AppendText("BETRIEBSSYSTEM-INFORMATIONEN:`r`n")
    $infoBox.SelectionColor = [System.Drawing.Color]::Black
    
    try {
        $osInfo = Get-WmiObject -Class Win32_OperatingSystem
        $infoBox.AppendText("Betriebssystem: $($osInfo.Caption)`r`n")
        $infoBox.AppendText("Version: $($osInfo.Version)`r`n")
        $infoBox.AppendText("Build: $($osInfo.BuildNumber)`r`n")
        $infoBox.AppendText("Architektur: $($osInfo.OSArchitecture)`r`n")
        $infoBox.AppendText("Installiert am: $($osInfo.InstallDate)`r`n")
        $infoBox.AppendText("Letzter Boot: $($osInfo.LastBootUpTime)`r`n")
    }
    catch {
        $infoBox.SelectionColor = [System.Drawing.Color]::Red
        $infoBox.AppendText("Fehler beim Abrufen der Betriebssystem-Informationen: $_`r`n`r`n")
    }
}

# Hardware-Info-Box dem TabExtensions hinzufügen
$tabExtensions.Controls.Add($hardwareInfoBox)

# Refresh-Button für Hardware-Info erstellen
$btnRefreshHardware = New-Object System.Windows.Forms.Button
$btnRefreshHardware.Text = "Hardware-Info aktualisieren"
$btnRefreshHardware.Size = New-Object System.Drawing.Size(200, 30)
$btnRefreshHardware.Location = New-Object System.Drawing.Point(10, 0)
$btnRefreshHardware.Add_Click({ Get-HardwareInfo -infoBox $hardwareInfoBox })
$tabExtensions.Controls.Add($btnRefreshHardware)

# Event-Handler für TabControl, um Tabs automatisch zu aktualisieren
$tabControl.Add_SelectedIndexChanged({
        if ($tabControl.SelectedTab -eq $tabExtensions) {
            Get-HardwareInfo -infoBox $hardwareInfoBox
        }
        elseif ($tabControl.SelectedTab -eq $tabAdvanced) {
            # Automatische Aktualisierung des System-Status
            $systemStatusBox.Clear()
            $systemStatusBox.SelectionColor = [System.Drawing.Color]::DarkBlue
            $systemStatusBox.AppendText("System-Status wird geladen...`r`n")
            
            # Progressbar zurücksetzen
            $progressBar.Value = 0
            $progressBar.CustomText = "Status wird geladen..."
            $progressBar.TextColor = [System.Drawing.Color]::DarkBlue
            
            # Initialisiere den Fortschritt
            $script:loadProgress = 0
            
            # Live-Modus verwenden, der schrittweise Status anzeigt und ProgressBar aktualisiert
            Get-SystemStatusSummary -statusBox $systemStatusBox -LiveMode
        }
        elseif ($tabControl.SelectedTab -eq $tabToolInfo) {
            Get-ToolInfo -infoBox $toolInfoBox
        }
        elseif ($tabControl.SelectedTab -eq $tabToolDownloads) {
            Show-ToolList -RichTextBox $toolDownloadsBox -Category "all"
        }
    })

# Funktion zum automatischen Wechseln zum Ausgabe-Tab
function Switch-ToOutputTab {
    param(
        [Parameter(Mandatory)]
        [System.Windows.Forms.TabControl]$TabControl
    )
    # Setze den ausgewählten Tab auf den Ausgabe-Tab (Index 0)
    $TabControl.SelectedIndex = 0
}



# Erstelle Buttons für System-Tools
$btnQuickMRT = New-Object System.Windows.Forms.Button
$btnQuickMRT.Text = "MRT Quick Scan"
$btnQuickMRT.Size = New-Object System.Drawing.Size(180, 50)
$btnQuickMRT.Location = New-Object System.Drawing.Point(30, 40)
$btnQuickMRT.Add_Click({
        Switch-ToOutputTab -TabControl $tabControl
        # Status auf "Scan läuft..." setzen
        Update-ProgressStatus -StatusText "MRT-Quick Scan wird gestartet..." -ProgressValue 0 -TextColor ([System.Drawing.Color]::DarkBlue)
        Start-QuickMRT -outputBox $outputBox -progressBar $progressBar 
        # Nach dem Scan Status auf "Fertig" setzen
        Update-ProgressStatus -StatusText "Fertig" -ProgressValue 100 -TextColor ([System.Drawing.Color]::Green)
    })
$gbSystemSecurity.Controls.Add($btnQuickMRT)

$btnFullMRT = New-Object System.Windows.Forms.Button
$btnFullMRT.Text = "MRT Full Scan"
$btnFullMRT.Size = New-Object System.Drawing.Size(180, 50)
$btnFullMRT.Location = New-Object System.Drawing.Point(230, 40)
$btnFullMRT.Add_Click({
        # Ausgabebox leeren
        $outputBox.Clear()
        $outputBox.SelectionColor = [System.Drawing.Color]::Blue
        $outputBox.AppendText("Starte MRT Full Scan...`r`n")
        
        # Tab Control umschalten
        $tabControl.SelectedIndex = 0  # Ausgabe-Tab
        
        # FullMRT-Scan starten
        Start-FullMRT -outputBox $outputBox -progressBar $progressBar
    })
$gbSystemSecurity.Controls.Add($btnFullMRT)

$btnWindowsDefender = New-Object System.Windows.Forms.Button
$btnWindowsDefender.Text = "Windows Defender"
$btnWindowsDefender.Size = New-Object System.Drawing.Size(180, 50) 
$btnWindowsDefender.Location = New-Object System.Drawing.Point(30, 110)
$btnWindowsDefender.Add_Click({
        Switch-ToOutputTab -TabControl $tabControl
        $outputBox.Clear()
        Update-ProgressStatus -StatusText "Windows Defender wird gestartet..." -ProgressValue 0 -TextColor ([System.Drawing.Color]::DarkBlue)
        Start-WindowsDefender -outputBox $outputBox -TabControl $tabControl -progressBar $progressBar -MainForm $mainform
    })
$gbSystemSecurity.Controls.Add($btnWindowsDefender)

# Neuer Button für Defender-Dienst-Neustart
#$btnRestartDefender = New-Object System.Windows.Forms.Button
#$btnRestartDefender.Text = "Defender Dienst Neustart"
#$btnRestartDefender.Size = New-Object System.Drawing.Size(180, 50) 
#$btnRestartDefender.Location = New-Object System.Drawing.Point(230, 110)
#$btnRestartDefender.Add_Click({
#        Switch-ToOutputTab -TabControl $tabControl
#        $outputBox.Clear()
#        Update-ProgressStatus -StatusText "Windows Defender-Dienst Neustart wird vorbereitet..." -ProgressValue 0 -TextColor ([System.Drawing.Color]::DarkBlue)
#       Restart-DefenderService -outputBox $outputBox -TabControl $tabControl -progressBar $progressBar -MainForm $mainform
#    })
#$gbSystemSecurity.Controls.Add($btnRestartDefender)

$btnSFC = New-Object System.Windows.Forms.Button
$btnSFC.Text = "SFC Check"
$btnSFC.Size = New-Object System.Drawing.Size(180, 50)
$btnSFC.Location = New-Object System.Drawing.Point(30, 25)
$btnSFC.Add_Click({
        Switch-ToOutputTab -TabControl $tabControl
        # Status auf "SFC Check läuft..." setzen
        Update-ProgressStatus -StatusText "SFC Check läuft..." -ProgressValue 0 -TextColor ([System.Drawing.Color]::DarkBlue)
        Start-SFCCheck -outputBox $outputBox -progressBar $progressBar
        # Nach dem Check Status auf "Fertig" setzen
        Update-ProgressStatus -StatusText "Fertig" -ProgressValue 100 -TextColor ([System.Drawing.Color]::Green)
    })
$gbSystemMaintenance.Controls.Add($btnSFC)

$btnMemoryDiag = New-Object System.Windows.Forms.Button
$btnMemoryDiag.Text = "Memory Diagnostic"
$btnMemoryDiag.Size = New-Object System.Drawing.Size(180, 50)
$btnMemoryDiag.Location = New-Object System.Drawing.Point(30, 25)
$btnMemoryDiag.Add_Click({
        Switch-ToOutputTab -TabControl $tabControl
        # Status auf "Memory Diagnostic wird gestartet..." setzen
        Update-ProgressStatus -StatusText "Memory Diagnostic wird gestartet..." -ProgressValue 0 -TextColor ([System.Drawing.Color]::DarkBlue)
        Start-MemoryDiagnostic -outputBox $outputBox
        # Nach dem Start Status auf "Fertig" setzen
        Update-ProgressStatus -StatusText "Fertig" -ProgressValue 100 -TextColor ([System.Drawing.Color]::Green)
    })
$gbDiagnostics.Controls.Add($btnMemoryDiag)



$btnWinUpdate = New-Object System.Windows.Forms.Button
$btnWinUpdate.Text = "Windows Update"
$btnWinUpdate.Size = New-Object System.Drawing.Size(180, 50)
$btnWinUpdate.Location = New-Object System.Drawing.Point(230, 25)
$btnWinUpdate.Add_Click({
        Switch-ToOutputTab -TabControl $tabControl
        # Status auf "Windows Update wird gestartet..." setzen
        Update-ProgressStatus -StatusText "Windows Update wird gestartet..." -ProgressValue 0 -TextColor ([System.Drawing.Color]::DarkBlue)
        try {
            # Rufe die Modulfunktionen auf
            Start-WindowsUpdate -outputBox $outputBox -TabControl $tabControl
            
            # Suche nach Updates
            $updateSession = New-Object -ComObject Microsoft.Update.Session
            $updateSearcher = $updateSession.CreateUpdateSearcher()
            $searchResult = $updateSearcher.Search("IsInstalled=0 AND IsHidden=0")
            
            # Zeige Update-Status an
            Get-WindowsUpdateStatus -outputBox $outputBox
            
            # Nur installieren wenn Updates gefunden wurden
            if ($searchResult.Updates.Count -gt 0) {
                # Automatisch Updates installieren
                Update-ProgressStatus -StatusText "Updates werden installiert..." -ProgressValue 0 -TextColor ([System.Drawing.Color]::DarkBlue)
                Install-AvailableWindowsUpdates -outputBox $outputBox -progressBar $progressBar
                # Nach der Installation Status auf "Fertig" setzen
                Update-ProgressStatus -StatusText "Fertig" -ProgressValue 100 -TextColor ([System.Drawing.Color]::Green)
            }
            else {
                Update-ProgressStatus -StatusText "Keine Updates verfügbar" -ProgressValue 100 -TextColor ([System.Drawing.Color]::Green)
            }
        }
        catch {
            Write-ToolLog -ToolName "WindowsUpdate" `
                -Message "Fehler beim Starten oder Installieren von Windows Update: $_" `
                -OutputBox $outputBox `
                -Color ([System.Drawing.Color]::Red)
            Update-ProgressStatus -StatusText "Fehler" -ProgressValue 0 -TextColor ([System.Drawing.Color]::Red)
        }
    })
$gbSystemMaintenance.Controls.Add($btnWinUpdate)


# Buttons für Festplatten-Tools
$btnCheckDISM = New-Object System.Windows.Forms.Button
$btnCheckDISM.Text = "DISM Check Health"
$btnCheckDISM.Size = New-Object System.Drawing.Size(180, 50)
$btnCheckDISM.Location = New-Object System.Drawing.Point(30, 40)
$btnCheckDISM.Add_Click({
        Switch-ToOutputTab -TabControl $tabControl
        # Status auf "DISM Check läuft..." setzen
        Update-ProgressStatus -StatusText "DISM Check läuft..." -ProgressValue 0 -TextColor ([System.Drawing.Color]::DarkBlue)
        Start-CheckDISM -outputBox $outputBox -progressBar $progressBar
        # Nach dem Check Status auf "Fertig" setzen
        Update-ProgressStatus -StatusText "Fertig" -ProgressValue 100 -TextColor ([System.Drawing.Color]::Green)
    })
$gbDiskRepair.Controls.Add($btnCheckDISM)

$btnScanDISM = New-Object System.Windows.Forms.Button
$btnScanDISM.Text = "DISM Scan Health"
$btnScanDISM.Size = New-Object System.Drawing.Size(180, 50)
$btnScanDISM.Location = New-Object System.Drawing.Point(230, 40)
$btnScanDISM.Add_Click({
        Switch-ToOutputTab -TabControl $tabControl
        # Status auf "DISM Scan läuft..." setzen
        Update-ProgressStatus -StatusText "DISM Scan läuft..." -ProgressValue 0 -TextColor ([System.Drawing.Color]::DarkBlue)
        Start-ScanDISM -outputBox $outputBox -progressBar $progressBar
        # Nach dem Scan Status auf "Fertig" setzen
        Update-ProgressStatus -StatusText "Fertig" -ProgressValue 100 -TextColor ([System.Drawing.Color]::Green)
    })
$gbDiskRepair.Controls.Add($btnScanDISM)

$btnRestoreDISM = New-Object System.Windows.Forms.Button
$btnRestoreDISM.Text = "DISM Restore Health"
$btnRestoreDISM.Size = New-Object System.Drawing.Size(180, 50)
$btnRestoreDISM.Location = New-Object System.Drawing.Point(30, 120)
$btnRestoreDISM.Add_Click({
        Switch-ToOutputTab -TabControl $tabControl
        # Status auf "DISM Restore läuft..." setzen
        Update-ProgressStatus -StatusText "DISM Restore läuft..." -ProgressValue 0 -TextColor ([System.Drawing.Color]::DarkBlue)
        Start-RestoreDISM -outputBox $outputBox -progressBar $progressBar
        # Nach dem Restore Status auf "Fertig" setzen
        Update-ProgressStatus -StatusText "Fertig" -ProgressValue 100 -TextColor ([System.Drawing.Color]::Green)
    })
$gbDiskRepair.Controls.Add($btnRestoreDISM)

$btnCHKDSK = New-Object System.Windows.Forms.Button
$btnCHKDSK.Text = "CHKDSK"
$btnCHKDSK.Size = New-Object System.Drawing.Size(180, 50)
$btnCHKDSK.Location = New-Object System.Drawing.Point(30, 25)
$btnCHKDSK.Add_Click({
        Switch-ToOutputTab -TabControl $tabControl
        # Status auf "Scan läuft..." setzen
        Update-ProgressStatus -StatusText "CHKDSK läuft..." -ProgressValue 0 -TextColor ([System.Drawing.Color]::DarkBlue)
        Start-CHKDSK -outputBox $outputBox -progressBar $progressBar -mainform $mainform 
        # Nach dem Scan Status auf "Fertig" setzen
        Update-ProgressStatus -StatusText "Fertig" -ProgressValue 100 -TextColor ([System.Drawing.Color]::Green)
    })
$gbDiskCheck.Controls.Add($btnCHKDSK)

# Buttons für Netzwerk-Tools
$btnPingTest = New-Object System.Windows.Forms.Button
$btnPingTest.Text = "Ping Test"
$btnPingTest.Size = New-Object System.Drawing.Size(180, 50)
$btnPingTest.Location = New-Object System.Drawing.Point(30, 25)
$btnPingTest.Add_Click({
        Switch-ToOutputTab -TabControl $tabControl
        # Status auf "Ping Test läuft..." setzen
        Update-ProgressStatus -StatusText "Ping Test läuft..." -ProgressValue 0 -TextColor ([System.Drawing.Color]::DarkBlue)
        Start-PingTest -outputBox $outputBox -progressBar $progressBar
        # Nach dem Test Status auf "Fertig" setzen
        Update-ProgressStatus -StatusText "Fertig" -ProgressValue 100 -TextColor ([System.Drawing.Color]::Green)
    })
$gbNetworkDiagnostics.Controls.Add($btnPingTest)

$btnResetNetwork = New-Object System.Windows.Forms.Button
$btnResetNetwork.Text = "Netzwerk zurücksetzen"
$btnResetNetwork.Size = New-Object System.Drawing.Size(180, 50)
$btnResetNetwork.Location = New-Object System.Drawing.Point(30, 25)
$btnResetNetwork.Add_Click({
        Switch-ToOutputTab -TabControl $tabControl
        # Status auf "Netzwerk wird zurückgesetzt..." setzen
        Update-ProgressStatus -StatusText "Netzwerk wird zurückgesetzt..." -ProgressValue 0 -TextColor ([System.Drawing.Color]::DarkBlue)
        Restart-NetworkAdapter -outputBox $outputBox -progressBar $progressBar
        # Nach dem Reset Status auf "Fertig" setzen
        Update-ProgressStatus -StatusText "Fertig" -ProgressValue 100 -TextColor ([System.Drawing.Color]::Green)
    })
$gbNetworkRepair.Controls.Add($btnResetNetwork)

# Buttons für Bereinigung
$btnDiskCleanup = New-Object System.Windows.Forms.Button
$btnDiskCleanup.Text = "Disk Cleanup"
$btnDiskCleanup.Size = New-Object System.Drawing.Size(180, 50)
$btnDiskCleanup.Location = New-Object System.Drawing.Point(30, 25)
$btnDiskCleanup.Add_Click({
        Switch-ToOutputTab -TabControl $tabControl
        # Status auf "Bereinigung läuft..." setzen
        Update-ProgressStatus -StatusText "Bereinigung läuft..." -ProgressValue 0 -TextColor ([System.Drawing.Color]::DarkBlue)
        Start-DiskCleanup -outputBox $outputBox -progressBar $progressBar 
        # Nach der Bereinigung Status auf "Fertig" setzen
        Update-ProgressStatus -StatusText "Fertig" -ProgressValue 100 -TextColor ([System.Drawing.Color]::Green)
    })
$gbCleanupSystem.Controls.Add($btnDiskCleanup)

$btnTempFiles = New-Object System.Windows.Forms.Button
$btnTempFiles.Text = "Temporäre Dateien"
$btnTempFiles.Size = New-Object System.Drawing.Size(180, 50)
$btnTempFiles.Location = New-Object System.Drawing.Point(30, 25)
$btnTempFiles.Add_Click({
        Switch-ToOutputTab -TabControl $tabControl
        # Einfacher Dialog mit zwei Optionen
        $result = [System.Windows.Forms.MessageBox]::Show(
            "Möchten Sie die erweiterte Temp-Files-Bereinigung (Ja) oder die einfache Version (Nein) verwenden?",
            "Temp-Files-Bereinigung",
            [System.Windows.Forms.MessageBoxButtons]::YesNoCancel,
            [System.Windows.Forms.MessageBoxIcon]::Question
        )
    
        switch ($result) {
            'Yes' { 
                # Status auf "Erweiterte Bereinigung läuft..." setzen
                Update-ProgressStatus -StatusText "Erweiterte Bereinigung läuft..." -ProgressValue 0 -TextColor ([System.Drawing.Color]::DarkBlue)
                Start-TempFilesCleanupAdvanced -outputBox $outputBox -progressBar $progressBar -mainform $mainform 
                # Nach der Bereinigung Status auf "Fertig" setzen
                Update-ProgressStatus -StatusText "Fertig" -ProgressValue 100 -TextColor ([System.Drawing.Color]::Green)
            }
            'No' { 
                # Status auf "Bereinigung läuft..." setzen
                Update-ProgressStatus -StatusText "Bereinigung läuft..." -ProgressValue 0 -TextColor ([System.Drawing.Color]::DarkBlue)
                Start-TempFilesCleanup -outputBox $outputBox -progressBar $progressBar 
                # Nach der Bereinigung Status auf "Fertig" setzen
                Update-ProgressStatus -StatusText "Fertig" -ProgressValue 100 -TextColor ([System.Drawing.Color]::Green)
            }
            'Cancel' { 
                $outputBox.SelectionColor = [System.Drawing.Color]::Gray
                $outputBox.AppendText("Temp-Files-Bereinigung abgebrochen.`r`n") 
                # Status auf "Abgebrochen" setzen
                Update-ProgressStatus -StatusText "Abgebrochen" -ProgressValue 0 -TextColor ([System.Drawing.Color]::Gray)
            }
        }
    })
$gbCleanupTemp.Controls.Add($btnTempFiles)



# Farbdefinitionen für Buttonakzente (subtil)
$colorGroups = @(
    [System.Drawing.Color]::FromArgb(80, 120, 160), # Gedämpftes Blau für System-Tools
    [System.Drawing.Color]::FromArgb(80, 140, 100), # Gedämpftes Grün für Disk-Tools
    [System.Drawing.Color]::FromArgb(110, 100, 150), # Gedämpftes Lila für Network-Tools
    [System.Drawing.Color]::FromArgb(150, 90, 90)    # Gedämpftes Rot für Cleanup-Tools
)

# Buttons für System & Sicherheit definieren
$systemButtons = @($btnQuickMRT, $btnFullMRT, $btnWindowsDefender, $btnSFC, $btnWinUpdate)
$diskButtons = @($btnCheckDISM, $btnScanDISM, $btnRestoreDISM, $btnCHKDSK, $btnMemoryDiag)
$networkButtons = @($btnPingTest, $btnResetNetwork)
$cleanupButtons = @($btnDiskCleanup, $btnTempFiles)

# Funktion zum Setzen der Buttonfarben
function Set-ButtonColor {
    param(
        [System.Windows.Forms.Button]$Button,
        [System.Drawing.Color]$Color
    )
    
    $Button.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $Button.FlatAppearance.BorderSize = 1
    $Button.FlatAppearance.BorderColor = $Color
    $Button.BackColor = [System.Drawing.Color]::White
    $Button.ForeColor = $Color
    $Button.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
    $Button.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    
    # Farbvariable zum späteren Zugriff speichern
    $colorValue = $Color
    
    # Hover-Effekt hinzufügen mit Closure-Technik
    $Button.Add_MouseEnter({
            $buttonColor = $colorValue
            $this.BackColor = $buttonColor
            $this.ForeColor = [System.Drawing.Color]::White
        }.GetNewClosure())
    
    $Button.Add_MouseLeave({
            $buttonColor = $colorValue
            $this.BackColor = [System.Drawing.Color]::White
            $this.ForeColor = $buttonColor
        }.GetNewClosure())
}

# Farbstile auf die Button-Gruppen anwenden
foreach ($button in $systemButtons) {
    Set-ButtonColor -Button $button -Color $colorGroups[0]
}

foreach ($button in $diskButtons) {
    Set-ButtonColor -Button $button -Color $colorGroups[1]
}

foreach ($button in $networkButtons) {
    Set-ButtonColor -Button $button -Color $colorGroups[2]
}

foreach ($button in $cleanupButtons) {
    Set-ButtonColor -Button $button -Color $colorGroups[3]
}

# Neustart Button erstellen
$btnRestart = New-Object System.Windows.Forms.Button
$btnRestart.Text = "System Neustart"
$btnRestart.Location = New-Object System.Drawing.Point(790, 835)
$btnRestart.Size = New-Object System.Drawing.Size(120, 30)
$btnRestart.Add_Click({
        # Bestätigungsdialog anzeigen
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
$mainform.Controls.Add($btnRestart)

# Tooltip für bessere Benutzererfahrung hinzufügen
$tooltipObj = New-Object System.Windows.Forms.ToolTip
$tooltipObj.IsBalloon = $true
$tooltipObj.ToolTipTitle = "Information"
$tooltipObj.ToolTipIcon = [System.Windows.Forms.ToolTipIcon]::Info
$tooltipObj.InitialDelay = 500
$tooltipObj.AutoPopDelay = 5000

# Tooltip-Texte zu den Funktionsbuttons hinzufügen
$tooltipObj.SetToolTip($btnQuickMRT, "Führt einen schnellen Malware-Scan mit Microsoft Malicious Software Removal Tool durch")
$tooltipObj.SetToolTip($btnFullMRT, "Führt einen vollständigen Systemscan mit Microsoft Malicious Software Removal Tool durch")
$tooltipObj.SetToolTip($btnWindowsDefender, "Öffnet Windows Defender und zeigt den aktuellen Status an")
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
$tooltipObj.SetToolTip($btnRestart, "Startet das System nach einer Bestätigung neu")
$tooltipObj.SetToolTip($themeButton, "Wechselt zwischen hellem und dunklem Farbschema der Benutzeroberfläche (🌙/☀️)")
$tooltipObj.SetToolTip($infoButton, "Zeigt Informationen über die Anwendung an")

# Status-Informationen anzeigen
$statusBar = New-Object System.Windows.Forms.StatusStrip
$statusLabel = New-Object System.Windows.Forms.ToolStripStatusLabel
$statusLabel.Text = "Status: Bereit | " + (Get-Date -Format "dd.MM.yyyy HH:mm")

# Admin-Indikator
$adminLabel = New-Object System.Windows.Forms.ToolStripStatusLabel
$adminLabel.Alignment = [System.Windows.Forms.ToolStripItemAlignment]::Right
if (Test-Admin) {
    $adminLabel.Text = "Administrator: Ja"
    $adminLabel.ForeColor = [System.Drawing.Color]::Green
}
else {
    $adminLabel.Text = "Administrator: Nein"
    $adminLabel.ForeColor = [System.Drawing.Color]::Red
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

# Erstelle Output-Box für Tool-Info und füge sie zum Tool-Info-Tab hinzu
$toolInfoBox = New-Object System.Windows.Forms.RichTextBox
$toolInfoBox.Location = New-Object System.Drawing.Point(0, 30)
$toolInfoBox.Size = New-Object System.Drawing.Size(964, 302)
$toolInfoBox.Font = New-Object System.Drawing.Font("Consolas", 12)
$toolInfoBox.Multiline = $true
$toolInfoBox.ScrollBars = "Both"
$toolInfoBox.WordWrap = $false
$toolInfoBox.ReadOnly = $true
$toolInfoBox.BackColor = [System.Drawing.Color]::White
$toolInfoBox.Text = "Tool-Informationen werden geladen...`r`n"
$toolInfoBox.Dock = [System.Windows.Forms.DockStyle]::Fill

# Funktion zum Abrufen der Tool-Informationen
function Get-ToolInfo {
    param (
        [System.Windows.Forms.RichTextBox]$infoBox
    )
    
    $infoBox.Clear()
    $infoBox.SelectionColor = [System.Drawing.Color]::DarkBlue
    $infoBox.AppendText("===== TOOL-INFORMATIONEN =====`r`n`r`n")
    
    # Progressbar zurücksetzen
    $progressBar.Value = 0
    $progressBar.CustomText = "Tool-Info wird geladen..."
    $progressBar.TextColor = [System.Drawing.Color]::DarkBlue
    
    # System-Tools Informationen - 20%
    $progressBar.Value = 20
    $progressBar.CustomText = "Lade System-Tools Info..."
    
    $infoBox.SelectionColor = [System.Drawing.Color]::Blue
    $infoBox.AppendText("SYSTEM-TOOLS:`r`n")
    $infoBox.SelectionColor = [System.Drawing.Color]::Black
    $infoBox.AppendText("Diese Tools helfen bei der Diagnose und Wartung des Windows-Betriebssystems.`r`n")
    $infoBox.AppendText("- SFC Check: Überprüft und repariert fehlerhafte oder fehlende Windows-Systemdateien.`r`n")
    $infoBox.AppendText("- Windows Update: Öffnet die Windows Update-Einstellungen.`r`n")
    $infoBox.AppendText("- Memory Diagnostic: Führt einen Arbeitsspeicher-Test durch.`r`n")
    $infoBox.AppendText("- System Scan: Systemscan auf Malware und Viren.`r`n")
    $infoBox.AppendText("`r`n")
    
    # Disk-Tools Informationen - 40%
    $progressBar.Value = 40
    $progressBar.CustomText = "Lade Disk-Tools Info..."
    
    $infoBox.SelectionColor = [System.Drawing.Color]::Blue
    $infoBox.AppendText("FESTPLATTEN-TOOLS:`r`n")
    $infoBox.SelectionColor = [System.Drawing.Color]::Black
    $infoBox.AppendText("Tools zur Überprüfung und Reparatur von Festplatten und Dateisystemen.`r`n")
    $infoBox.AppendText("- DISM Check Health: Überprüft den Zustand des Windows-Images.`r`n")
    $infoBox.AppendText("- DISM Scan Health: Scannt das Windows-Image auf Beschädigungen.`r`n")
    $infoBox.AppendText("- DISM Restore Health: Repariert das Windows-Image.`r`n")
    $infoBox.AppendText("- CHKDSK: Überprüft und repariert Festplattenfehler.`r`n")
    $infoBox.AppendText("- Drive Cleanup: Bereinigt temporäre und überflüssige Dateien.`r`n")
    $infoBox.AppendText("`r`n")
    
    # Network-Tools Informationen - 60%
    $progressBar.Value = 60
    $progressBar.CustomText = "Lade Network-Tools Info..."
    
    $infoBox.SelectionColor = [System.Drawing.Color]::Blue
    $infoBox.AppendText("NETWORK-TOOLS:`r`n")
    $infoBox.SelectionColor = [System.Drawing.Color]::Black
    $infoBox.AppendText("* Network Reset`r`n")
    $infoBox.AppendText("  - Setzt Netzwerkadapter zurueck`r`n")
    $infoBox.AppendText("  - Erneuert IP-Konfiguration`r`n")
    $infoBox.AppendText("  - Leert DNS-Cache`r`n`r`n")
    
    # Cleanup-Tools Informationen - 80%
    $progressBar.Value = 80
    $progressBar.CustomText = "Lade Cleanup-Tools Info..."
    
    $infoBox.SelectionColor = [System.Drawing.Color]::Blue
    $infoBox.AppendText("CLEANUP-TOOLS:`r`n")
    $infoBox.SelectionColor = [System.Drawing.Color]::Black
    $infoBox.AppendText("* Browser Cache`r`n")
    $infoBox.AppendText("  - Leert Browser-Caches (Chrome, Firefox, Edge)`r`n")
    $infoBox.AppendText("  - Entfernt temporaere Internetdateien`r`n")
    $infoBox.AppendText("* Windows Cache`r`n")
    $infoBox.AppendText("  - Bereinigt Windows-Thumbnail-Cache`r`n")
    $infoBox.AppendText("  - Entfernt temporaere Windows-Dateien`r`n`r`n")
    
    # Allgemeine Informationen - 90%
    $progressBar.Value = 90
    $progressBar.CustomText = "Lade allgemeine Informationen..."
    
    $infoBox.SelectionColor = [System.Drawing.Color]::Blue
    $infoBox.AppendText("ALLGEMEINE INFORMATIONEN:`r`n")
    $infoBox.SelectionColor = [System.Drawing.Color]::Black
    $infoBox.AppendText("* Version: 3.1.0`r`n")
    $infoBox.AppendText("* Entwickler: IT-Support`r`n")
    $infoBox.AppendText("* Letzte Aktualisierung: 01.03.2024`r`n")
    
    # Fertig - 100%
    $progressBar.Value = 100
    $progressBar.CustomText = "Tool-Info geladen"
    
    # Nach kurzer Pause zurücksetzen
    Start-Sleep -Milliseconds 1000
    $progressBar.Value = 0
    $progressBar.CustomText = "Bereit"
    $progressBar.TextColor = [System.Drawing.Color]::DarkBlue
}

# Tool-Info-Box dem TabToolInfo hinzufügen
$tabToolInfo.Controls.Add($toolInfoBox)

# Refresh-Button für Tool-Info erstellen
$btnRefreshToolInfo = New-Object System.Windows.Forms.Button
$btnRefreshToolInfo.Text = "Tool-Info aktualisieren"
$btnRefreshToolInfo.Size = New-Object System.Drawing.Size(200, 30)
$btnRefreshToolInfo.Location = New-Object System.Drawing.Point(10, 0)
$btnRefreshToolInfo.Add_Click({ Get-ToolInfo -infoBox $toolInfoBox })
$tabToolInfo.Controls.Add($btnRefreshToolInfo)

# Erstelle einen fünften Tab für Tool-Downloads
$tabToolDownloads = New-Object System.Windows.Forms.TabPage
$tabToolDownloads.Text = "Tool-Downloads"
$tabToolDownloads.BackColor = $tabToolDownloadsColor
$tabControl.TabPages.Add($tabToolDownloads)

# Erstelle Output-Box für Tool-Downloads
$toolDownloadsBox = New-Object System.Windows.Forms.RichTextBox
$toolDownloadsBox.Location = New-Object System.Drawing.Point(0, 30)
$toolDownloadsBox.Size = New-Object System.Drawing.Size(964, 302)
$toolDownloadsBox.Font = New-Object System.Drawing.Font("Consolas", 12)
$toolDownloadsBox.Multiline = $true
$toolDownloadsBox.ScrollBars = "Both"
$toolDownloadsBox.WordWrap = $false
$toolDownloadsBox.ReadOnly = $true
$toolDownloadsBox.BackColor = [System.Drawing.Color]::White
$toolDownloadsBox.Text = "Tool-Downloads-Bereich wird geladen...`r`n"
$toolDownloadsBox.Dock = [System.Windows.Forms.DockStyle]::Fill

# Click-Handler für Download-Buttons
$toolDownloadsBox.Add_Click({
        $clickPosition = $this.GetCharIndexFromPosition($this.PointToClient([System.Windows.Forms.Cursor]::Position))
        $line = $this.GetLineFromCharIndex($clickPosition)
        $lineText = $this.Lines[$line]
    
        # Prüfe, ob der Klick auf dem Download-Text war
        if ($lineText -match "\[Download\]") {
            # Extrahiere den Tool-Namen aus der Zeile (erste 30 Zeichen)
            $toolName = $lineText.Substring(0, 30).Trim()
            
            # Debug-Ausgabe
            Write-Host "Klick auf Download-Button für Tool: $toolName"
        
            # Status auf "Download läuft..." setzen
            Update-ProgressStatus -StatusText "Download läuft..." -ProgressValue 0 -TextColor ([System.Drawing.Color]::DarkBlue)
        
            # Tool herunterladen und installieren
            $success = Get-ToolDownload -ToolName $toolName
        
            if ($success) {
                Update-ProgressStatus -StatusText "Download und Installation abgeschlossen" -ProgressValue 100 -TextColor ([System.Drawing.Color]::Green)
            }
            else {
                Update-ProgressStatus -StatusText "Download fehlgeschlagen" -ProgressValue 0 -TextColor ([System.Drawing.Color]::Red)
            }
        }
    })

# Tool-Downloads-Box dem TabToolDownloads hinzufügen
$tabToolDownloads.Controls.Add($toolDownloadsBox)

# Buttons für die verschiedenen Kategorien erstellen
$btnAllTools = New-Object System.Windows.Forms.Button
$btnAllTools.Text = "Alle Tools"
$btnAllTools.Size = New-Object System.Drawing.Size(120, 30)
$btnAllTools.Location = New-Object System.Drawing.Point(10, 0)
$btnAllTools.Add_Click({ Show-ToolList -RichTextBox $toolDownloadsBox -Category "all" })
$tabToolDownloads.Controls.Add($btnAllTools)

$btnSystemTools = New-Object System.Windows.Forms.Button
$btnSystemTools.Text = "System-Tools"
$btnSystemTools.Size = New-Object System.Drawing.Size(120, 30)
$btnSystemTools.Location = New-Object System.Drawing.Point(140, 0)
$btnSystemTools.Add_Click({ Show-ToolList -RichTextBox $toolDownloadsBox -Category "system" })
$tabToolDownloads.Controls.Add($btnSystemTools)

$btnBrowserTools = New-Object System.Windows.Forms.Button
$btnBrowserTools.Text = "Browser"
$btnBrowserTools.Size = New-Object System.Drawing.Size(120, 30)
$btnBrowserTools.Location = New-Object System.Drawing.Point(270, 0)
$btnBrowserTools.Add_Click({ Show-ToolList -RichTextBox $toolDownloadsBox -Category "browser" })
$tabToolDownloads.Controls.Add($btnBrowserTools)

$btnCommunicationTools = New-Object System.Windows.Forms.Button
$btnCommunicationTools.Text = "Kommunikation"
$btnCommunicationTools.Size = New-Object System.Drawing.Size(120, 30)
$btnCommunicationTools.Location = New-Object System.Drawing.Point(400, 0)
$btnCommunicationTools.Add_Click({ Show-ToolList -RichTextBox $toolDownloadsBox -Category "communication" })
$tabToolDownloads.Controls.Add($btnCommunicationTools)

# Tooltips für die Download-Buttons
$tooltipObj.SetToolTip($btnAllTools, "Zeigt alle verfügbaren Tools an")
$tooltipObj.SetToolTip($btnSystemTools, "Zeigt System-Tools an")
$tooltipObj.SetToolTip($btnBrowserTools, "Zeigt Browser an")
$tooltipObj.SetToolTip($btnCommunicationTools, "Zeigt Kommunikationstools an")

# Hauptformular anzeigen
$mainform.Add_Shown({
        # Debug-Modi-Initialisierung (aber nicht deaktivieren)
        # Set-HardwareDebugMode -Component 'CPU' -Enabled $false
        # Set-HardwareDebugMode -Component 'GPU' -Enabled $false
        # Set-HardwareDebugMode -Component 'RAM' -Enabled $false

        $outputBox.Clear()
        $outputBox.SelectionColor = [System.Drawing.Color]::Green
        $outputBox.AppendText("System-Tool wurde erfolgreich gestartet.")
        $outputBox.AppendText("`r`n`r`nBitte wählen Sie eine Funktion aus den verfügbaren Tools.`r`n")
        $outputBox.AppendText("Hinweis: Für die meisten Funktionen sind Administratorrechte erforderlich.`r`n")
    
        if (-not (Test-Admin)) {
            $outputBox.SelectionColor = [System.Drawing.Color]::Red
            $outputBox.AppendText("`r`nWARNUNG: Das Tool läuft NICHT mit Administratorrechten! Einige Funktionen werden nicht korrekt arbeiten.`r`n")
            $outputBox.AppendText("Bitte starten Sie das Tool erneut und bestätigen Sie die Admin-Anforderung.`r`n")
        }
        else {
            $outputBox.SelectionColor = [System.Drawing.Color]::Green
            $outputBox.AppendText("`r`nDas Tool läuft mit Administratorrechten. Alle Funktionen stehen zur Verfügung.`r`n")
        }
        
        # Gespeicherte Einstellungen anwenden, nachdem die GUI vollständig geladen ist
        # Kurze Verzögerung, um sicherzustellen, dass alle Steuerelemente geladen sind
        $applySettingsTimer = New-Object System.Windows.Forms.Timer
        $applySettingsTimer.Interval = 500
        $applySettingsTimer.Add_Tick({
                $this.Stop()
                $result = Apply-Settings
                if ($result) {
                    $outputBox.SelectionColor = [System.Drawing.Color]::Green
                    $outputBox.AppendText("`r`nGespeicherte Einstellungen wurden angewendet.`r`n")
                }
                $this.Dispose()
            })
        $applySettingsTimer.Start()
    })

# Hauptfenster anzeigen
[void]$mainform.ShowDialog() 

# Ändern wir die Funktion Set-Theme, um mit den neuen Tabs anstelle von GroupBoxes zu arbeiten
function Set-Theme {
    param(
        [System.Windows.Forms.Form]$mainform,
        [System.Windows.Forms.Label]$header,
        [System.Windows.Forms.RichTextBox]$outputBox,
        [System.Windows.Forms.Button]$themeButton,
        [System.Windows.Forms.TabControl]$tabControl,
        [System.Windows.Forms.TabControl]$mainTabControl
    )
    
    # Dark mode aktivieren/deaktivieren
    if ($mainform.BackColor -eq [System.Drawing.Color]::FromArgb(240, 240, 240) -or $mainform.BackColor -eq [System.Drawing.Color]::White) {
        # Auf Dark Mode umschalten
        # Moderne, dunklere Farbpalette mit blauen Akzenten
        $mainform.BackColor = [System.Drawing.Color]::FromArgb(28, 30, 36)  # Dunkleres Anthrazit (war 45, 45, 48)
        $header.ForeColor = [System.Drawing.Color]::FromArgb(220, 225, 235)  # Leicht bläuliches Weiß
        $outputBox.BackColor = [System.Drawing.Color]::FromArgb(20, 22, 28)  # Noch dunklerer Hintergrund (war 30, 30, 30)
        $outputBox.ForeColor = [System.Drawing.Color]::FromArgb(200, 210, 220)  # Bläuliches Hellgrau (war LightGray)
        
        # Hardware-Monitor Panel anpassen
        $monitorBackgroundPanel.BackColor = [System.Drawing.Color]::FromArgb(24, 26, 32)  # Dunkleres Panel
        $gbCPU.BackColor = [System.Drawing.Color]::FromArgb(38, 42, 48)  # Dunkleres Grau-Blau statt Grün
        $gbGPU.BackColor = [System.Drawing.Color]::FromArgb(40, 44, 52)  # Dunkleres Grau-Blau statt Gelb
        $gbRAM.BackColor = [System.Drawing.Color]::FromArgb(42, 46, 56)  # Dunkleres Grau-Blau statt Rot
        
        # Hardware-Monitor Labels anpassen
        $lblCPUTitle.BackColor = [System.Drawing.Color]::FromArgb(46, 50, 60)  # Dunkleres Blau statt Lavender
        $lblCPUTitle.ForeColor = [System.Drawing.Color]::FromArgb(200, 210, 220)  # Bläuliches Weiß
        $lblGPUTitle.BackColor = [System.Drawing.Color]::FromArgb(46, 50, 60)
        $lblGPUTitle.ForeColor = [System.Drawing.Color]::FromArgb(200, 210, 220)
        $lblRAMTitle.BackColor = [System.Drawing.Color]::FromArgb(46, 50, 60)
        $lblRAMTitle.ForeColor = [System.Drawing.Color]::FromArgb(200, 210, 220)
        
        # Wenn CPU-Label, GPU-Label und RAM-Label existieren, auch diese anpassen
        if ($null -ne $cpuLabel) {
            $cpuLabel.ForeColor = [System.Drawing.Color]::FromArgb(200, 210, 220)
        }
        if ($null -ne $gpuLabel) {
            $gpuLabel.ForeColor = [System.Drawing.Color]::FromArgb(200, 210, 220)
        }
        if ($null -ne $ramLabel) {
            $ramLabel.ForeColor = [System.Drawing.Color]::FromArgb(200, 210, 220)
        }
        
        # Dunkles Farbschema für Ausgabe-Tabs
        $tabControl.BackColor = [System.Drawing.Color]::FromArgb(32, 34, 40)  # Leicht bläuliches Anthrazit
        $tabOutput.BackColor = [System.Drawing.Color]::FromArgb(26, 28, 34)  # Dunkleres Anthrazit mit blauen Untertönen
        $tabAdvanced.BackColor = [System.Drawing.Color]::FromArgb(28, 30, 36)  # Anthrazit
        $tabExtensions.BackColor = [System.Drawing.Color]::FromArgb(26, 29, 35)  # Anthrazit mit leichtem Blauton
        
        # Dunkles Farbschema für Haupt-Tabs
        $mainTabControl.BackColor = [System.Drawing.Color]::FromArgb(24, 26, 32)  # Noch dunkleres Anthrazit
        $tabSystem.BackColor = [System.Drawing.Color]::FromArgb(30, 33, 42)  # Dunkelblau-Grau
        $tabDisk.BackColor = [System.Drawing.Color]::FromArgb(30, 33, 42)
        $tabNetwork.BackColor = [System.Drawing.Color]::FromArgb(30, 33, 42)
        $tabCleanup.BackColor = [System.Drawing.Color]::FromArgb(30, 33, 42)
        $tabHardwareMonitor.BackColor = [System.Drawing.Color]::FromArgb(30, 33, 42)
        
        # GroupBox-Farben im Dark Mode
        $gbSystemSecurity.ForeColor = [System.Drawing.Color]::FromArgb(180, 200, 220)  # Helleres Blau-Grau
        $gbSystemMaintenance.ForeColor = [System.Drawing.Color]::FromArgb(180, 200, 220)
        $gbDiskCheck.ForeColor = [System.Drawing.Color]::FromArgb(180, 200, 220)
        $gbDiskRepair.ForeColor = [System.Drawing.Color]::FromArgb(180, 200, 220)
        $gbNetworkDiagnostics.ForeColor = [System.Drawing.Color]::FromArgb(180, 200, 220)
        $gbNetworkRepair.ForeColor = [System.Drawing.Color]::FromArgb(180, 200, 220)
        $gbCleanupSystem.ForeColor = [System.Drawing.Color]::FromArgb(180, 200, 220)
        $gbCleanupTemp.ForeColor = [System.Drawing.Color]::FromArgb(180, 200, 220)
        $gbMainTabControl.ForeColor = [System.Drawing.Color]::FromArgb(180, 200, 220)
        $gbOutputTabControl.ForeColor = [System.Drawing.Color]::FromArgb(180, 200, 220)
        
        # Theme-Button im dunklen Design
        $themeButton.BackColor = [System.Drawing.Color]::FromArgb(40, 44, 52)  # Dunkler als Hintergrund
        $themeButton.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(60, 70, 90)  # Bläulicher Rand
        $themeButton.ForeColor = [System.Drawing.Color]::FromArgb(220, 225, 235)  # Bläuliches Weiß
        
        return $true
    }
    else {
        # Auf Light Mode umschalten
        $mainform.BackColor = [System.Drawing.Color]::FromArgb(240, 240, 240)
        $header.ForeColor = [System.Drawing.Color]::Black
        $outputBox.BackColor = [System.Drawing.Color]::White
        $outputBox.ForeColor = [System.Drawing.Color]::Black
        
        # Helles Farbschema für Ausgabe-Tabs
        $tabControl.BackColor = [System.Drawing.Color]::FromArgb(240, 240, 240)
        $tabOutput.BackColor = $tabOutputColor
        $tabAdvanced.BackColor = $tabAdvancedColor
        $tabExtensions.BackColor = $tabHardwareColor
        
        # Helles Farbschema für Haupt-Tabs
        $mainTabControl.BackColor = [System.Drawing.Color]::FromArgb(240, 240, 240)
        $tabSystem.BackColor = $tabSystemColor
        $tabDisk.BackColor = $tabDiskColor
        $tabNetwork.BackColor = $tabNetworkColor
        $tabCleanup.BackColor = $tabCleanupColor
        $tabHardwareMonitor.BackColor = $tabHardwareMonitorColor
        
        # GroupBox-Farben im Light Mode
        $gbSystemSecurity.ForeColor = [System.Drawing.Color]::Black
        $gbSystemMaintenance.ForeColor = [System.Drawing.Color]::Black
        $gbDiskCheck.ForeColor = [System.Drawing.Color]::Black
        $gbDiskRepair.ForeColor = [System.Drawing.Color]::Black
        $gbNetworkDiagnostics.ForeColor = [System.Drawing.Color]::Black
        $gbNetworkRepair.ForeColor = [System.Drawing.Color]::Black
        $gbCleanupSystem.ForeColor = [System.Drawing.Color]::Black
        $gbCleanupTemp.ForeColor = [System.Drawing.Color]::Black
        
        $themeButton.BackColor = [System.Drawing.Color]::FromArgb(250, 250, 250)
        $themeButton.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(220, 220, 220)
        $themeButton.ForeColor = [System.Drawing.Color]::Black
        
        return $false
    }
} 

# Event-Handler für MainTabControl
$mainTabControl.Add_SelectedIndexChanged({
        # Alle Tabs auf Standardfarbe zurücksetzen
        $tabSystem.BackColor = $tabSystemColor
        $tabDisk.BackColor = $tabDiskColor
        $tabNetwork.BackColor = $tabNetworkColor
        $tabCleanup.BackColor = $tabCleanupColor
    
        # Aktiven Tab hervorheben
        switch ($mainTabControl.SelectedTab) {
            $tabSystem { $tabSystem.BackColor = $tabSystemActiveColor }
            $tabDisk { $tabDisk.BackColor = $tabDiskActiveColor }
            $tabNetwork { $tabNetwork.BackColor = $tabNetworkActiveColor }
            $tabCleanup { $tabCleanup.BackColor = $tabCleanupActiveColor }
        }
    })

# Event-Handler für TabControl (Ausgabe-Tabs)
$tabControl.Add_SelectedIndexChanged({
        # Alle Tabs auf Standardfarbe zurücksetzen
        $tabOutput.BackColor = $tabOutputColor
        $tabAdvanced.BackColor = $tabAdvancedColor
        $tabExtensions.BackColor = $tabHardwareColor
        $tabToolInfo.BackColor = $tabToolInfoColor
        $tabToolDownloads.BackColor = $tabToolDownloadsColor
    
        # Aktiven Tab hervorheben
        switch ($tabControl.SelectedTab) {
            $tabOutput { 
                $tabOutput.BackColor = $tabOutputActiveColor
            }
            $tabAdvanced { 
                $tabAdvanced.BackColor = $tabAdvancedActiveColor
                # Automatische Aktualisierung des System-Status
                $systemStatusBox.Clear()
                $systemStatusBox.SelectionColor = [System.Drawing.Color]::DarkBlue
                $systemStatusBox.AppendText("System-Status wird geladen...`r`n")
                Get-SystemStatusSummary -statusBox $systemStatusBox -LiveMode
            }
            $tabExtensions { 
                $tabExtensions.BackColor = $tabHardwareActiveColor
                Get-HardwareInfo -infoBox $hardwareInfoBox
            }
            $tabToolInfo { 
                $tabToolInfo.BackColor = $tabToolInfoActiveColor
                Get-ToolInfo -infoBox $toolInfoBox
            }
            $tabToolDownloads { 
                $tabToolDownloads.BackColor = $tabToolDownloadsActiveColor
                Show-ToolList -RichTextBox $toolDownloadsBox -Category "all"
            }
        }
    })

# Stil für die TabControls anpassen
$mainTabControl.DrawMode = [System.Windows.Forms.TabDrawMode]::OwnerDrawFixed
$tabControl.DrawMode = [System.Windows.Forms.TabDrawMode]::OwnerDrawFixed

# Event-Handler für das Zeichnen der Tabs
$drawTabHandler = {
    param($sender, $e)
    
    $tabPage = $sender.TabPages[$e.Index]
    $tabBounds = $e.Bounds
    $g = $e.Graphics
    
    # Prüfen, ob wir uns im Dark Mode befinden
    $isDarkMode = $mainform.BackColor -eq [System.Drawing.Color]::FromArgb(28, 30, 36)
    
    if ($isDarkMode) {
        # Dark Mode Farben
        if ($e.Index -eq $sender.SelectedIndex) {
            # Ausgewählter Tab im Dark Mode
            $brush = New-Object System.Drawing.SolidBrush($tabPage.BackColor)
            $textColor = [System.Drawing.Color]::FromArgb(210, 220, 230)  # Helleres Blau-Weiß für aktive Tabs
            $font = New-Object System.Drawing.Font($sender.Font, [System.Drawing.FontStyle]::Bold)
        }
        else {
            # Nicht ausgewählter Tab im Dark Mode
            $brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(38, 40, 48))  # Dunkelgrau für inaktive Tabs
            $textColor = [System.Drawing.Color]::FromArgb(140, 150, 160)  # Gedämpftes Blau-Grau
            $font = $sender.Font
        }
    }
    else {
        # Light Mode Farben (Original-Code beibehalten)
        if ($e.Index -eq $sender.SelectedIndex) {
            # Ausgewählter Tab
            $brush = New-Object System.Drawing.SolidBrush($tabPage.BackColor)
            $textColor = [System.Drawing.Color]::Black
            $font = New-Object System.Drawing.Font($sender.Font, [System.Drawing.FontStyle]::Bold)
        }
        else {
            # Nicht ausgewählter Tab
            $brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(240, 240, 240))
            $textColor = [System.Drawing.Color]::DarkGray
            $font = $sender.Font
        }
    }
    
    # Tab zeichnen
    $g.FillRectangle($brush, $tabBounds)
    
    # Text zentriert zeichnen
    $textBrush = New-Object System.Drawing.SolidBrush($textColor)
    $stringFormat = New-Object System.Drawing.StringFormat
    $stringFormat.Alignment = [System.Drawing.StringAlignment]::Center
    $stringFormat.LineAlignment = [System.Drawing.StringAlignment]::Center
    $g.DrawString($tabPage.Text, $font, $textBrush, $tabBounds, $stringFormat)
    
    # Ressourcen freigeben
    $brush.Dispose()
    $textBrush.Dispose()
    $stringFormat.Dispose()
}

# Event-Handler für das Zeichnen der Tabs zuweisen
$mainTabControl.Add_DrawItem($drawTabHandler)
$tabControl.Add_DrawItem($drawTabHandler)


# GroupBox für den Ausgabe-TabControl erstellen
$gbOutputTabControl = New-Object System.Windows.Forms.GroupBox
$gbOutputTabControl.Text = "Ausgabe und Informationen"
$gbOutputTabControl.Location = New-Object System.Drawing.Point(10, 450)
$gbOutputTabControl.Size = New-Object System.Drawing.Size(990, 360)
$gbOutputTabControl.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$gbOutputTabControl.ForeColor = [System.Drawing.Color]::FromArgb(60, 60, 80)  # Dunkelblaugrau
$mainform.Controls.Add($gbOutputTabControl)

# Ausgabe-TabControl in die GroupBox verschieben
$tabControl.Location = New-Object System.Drawing.Point(10, 20)
$tabControl.Size = New-Object System.Drawing.Size(970, 330)
$gbOutputTabControl.Controls.Add($tabControl)

# Status-Label für die ProgressBar anpassen
$progressStatusLabel.Location = New-Object System.Drawing.Point(130, 825)

# ProgressBar Position anpassen
$progressBar.Location = New-Object System.Drawing.Point(130, 850)

# Dark Mode für die GroupBoxes hinzufügen
$mainform.BackColor = [System.Drawing.Color]::FromArgb(45, 45, 48)
$header.ForeColor = [System.Drawing.Color]::White
$outputBox.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
$outputBox.ForeColor = [System.Drawing.Color]::White
    
# Dunkles Farbschema für Ausgabe-Tabs
$tabControl.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
$tabOutput.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
$tabAdvanced.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
$tabExtensions.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
    
# Dunkles Farbschema für Haupt-Tabs
$mainTabControl.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
$tabSystem.BackColor = [System.Drawing.Color]::FromArgb(40, 40, 45)
$tabDisk.BackColor = [System.Drawing.Color]::FromArgb(40, 40, 45)
$tabNetwork.BackColor = [System.Drawing.Color]::FromArgb(40, 40, 45)
$tabCleanup.BackColor = [System.Drawing.Color]::FromArgb(40, 40, 45)
$tabHardwareMonitor.BackColor = [System.Drawing.Color]::FromArgb(40, 40, 45)
    
# GroupBox-Farben im Dark Mode
$gbSystemSecurity.ForeColor = [System.Drawing.Color]::White
$gbSystemMaintenance.ForeColor = [System.Drawing.Color]::White
$gbDiskCheck.ForeColor = [System.Drawing.Color]::White
$gbDiskRepair.ForeColor = [System.Drawing.Color]::White
$gbNetworkDiagnostics.ForeColor = [System.Drawing.Color]::White
$gbNetworkRepair.ForeColor = [System.Drawing.Color]::White
$gbCleanupSystem.ForeColor = [System.Drawing.Color]::White
$gbCleanupTemp.ForeColor = [System.Drawing.Color]::White
$gbMainTabControl.ForeColor = [System.Drawing.Color]::White
$gbOutputTabControl.ForeColor = [System.Drawing.Color]::White

# Module neu laden
Remove-Module ProgressBarTools -ErrorAction SilentlyContinue
Import-Module "$PSScriptRoot\Modules\Core\ProgressBarTools.psm1" -Force

function Initialize-ProgressComponents {
    param (
        [System.Windows.Forms.ProgressBar]$ProgressBar,
        [System.Windows.Forms.Label]$StatusLabel = $null  # Beibehalten für Rückwärtskompatibilität
    )
    
    $script:progressBar = $ProgressBar
    $script:progressStatusLabel = $StatusLabel
}

# DISM-Funktionen aktualisieren
function Start-CheckDISM {
    param(
        [System.Windows.Forms.RichTextBox]$outputBox,
        [System.Windows.Forms.ProgressBar]$progressBar
    )
    
    Switch-ToOutputTab -TabControl $tabControl
    $result = Invoke-SystemTool -ToolName "DISM" `
        -Arguments "/Online /Cleanup-Image /CheckHealth" `
        -OutputBox $outputBox `
        -ProgressBar $progressBar
    
    if (-not $result) {
        Write-ToolLog -ToolName "DISM" `
            -Message "DISM CheckHealth fehlgeschlagen." `
            -OutputBox $outputBox `
            -Color ([System.Drawing.Color]::Red)
    }
}



# Erstelle einen Schließen-Button auf dem Hauptformular
$closeButton = New-Object System.Windows.Forms.Button
$closeButton.Text = "Beenden"
$closeButton.Location = New-Object System.Drawing.Point(920, 30)
$closeButton.Size = New-Object System.Drawing.Size(100, 30)
$closeButton.BackColor = [System.Drawing.Color]::LightCoral
$closeButton.ForeColor = [System.Drawing.Color]::White
$closeButton.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$closeButton.Add_Click({
        Write-Host "Schließen-Button wurde geklickt..."
        Close-FormSafely -Form $mainform
    })
$mainform.Controls.Add($closeButton)

# Initialisierung der Debug-Variablen
$script:cpuDebugEnabled = $false
$script:gpuDebugEnabled = $false
$script:ramDebugEnabled = $false

# Schwellenwerte für die Hardware-Überwachung
$script:cpuThreshold = 90  # Standard-CPU-Schwellenwert (wird durch Einstellungen überschrieben)
$script:gpuThreshold = 80  # Standard-GPU-Schwellenwert (wird durch Einstellungen überschrieben)
$script:ramThreshold = 85  # Standard-RAM-Schwellenwert (wird durch Einstellungen überschrieben)








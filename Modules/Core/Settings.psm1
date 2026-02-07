# Settings.psm1 - Einstellungsmodul für Bocki's System-Tool
# Autor: Bocki

# Globale Variable für die Einstellungen, wird von der Hauptdatei gesetzt
$script:settings = $null

Import-Module "$PSScriptRoot\TextStyle.psm1" -Force

# Hilfsfunktionen für verschachtelte Einstellungen
function ConvertTo-SettingsHashtable {
    param([object]$InputObject)

    if ($null -eq $InputObject) { return $null }

    if ($InputObject -is [hashtable]) {
        $result = @{}
        foreach ($key in $InputObject.Keys) {
            $result[$key] = ConvertTo-SettingsHashtable -InputObject $InputObject[$key]
        }
        return $result
    }

    if ($InputObject -is [System.Management.Automation.PSCustomObject]) {
        $hash = @{}
        foreach ($property in $InputObject.PSObject.Properties) {
            $hash[$property.Name] = ConvertTo-SettingsHashtable -InputObject $property.Value
        }
        return $hash
    }

    if ($InputObject -is [System.Collections.IEnumerable] -and -not ($InputObject -is [string])) {
        $list = @()
        foreach ($item in $InputObject) {
            $list += ,(ConvertTo-SettingsHashtable -InputObject $item)
        }
        return $list
    }

    return $InputObject
}

function Merge-SettingsHashtable {
    param(
        [hashtable]$Base,
        [hashtable]$Override
    )

    if (-not $Base) { return $Override }
    if (-not $Override) { return $Base.Clone() }

    $result = @{}
    foreach ($key in $Base.Keys) {
        $value = $Base[$key]
        if ($value -is [hashtable]) {
            $result[$key] = Merge-SettingsHashtable -Base $value -Override @{}
        }
        else {
            $result[$key] = $value
        }
    }

    foreach ($key in $Override.Keys) {
        $baseValue = if ($result.ContainsKey($key)) { $result[$key] } else { $null }
        $overrideValue = $Override[$key]
        if ($baseValue -is [hashtable] -and $overrideValue -is [hashtable]) {
            $result[$key] = Merge-SettingsHashtable -Base $baseValue -Override $overrideValue
        }
        elseif ($overrideValue -is [hashtable]) {
            $result[$key] = Merge-SettingsHashtable -Base @{} -Override $overrideValue
        }
        else {
            $result[$key] = $overrideValue
        }
    }
    return $result
}

function Get-DefaultColorScheme {
    $scheme = @{
        Output = @{
            Colors = @{
                Background = "#1E1E1E"
                Foreground = "#DCDCDC"
                Banner     = "#9ACD32"
                Success    = "#3DDC84"
                Warning    = "#FFB74D"
                Error      = "#FF6B6B"
                Info       = "#64B5F6"
                Accent     = "#00BCD4"
                Divider    = "#6E6E6E"
                Muted      = "#A6ADB4"
            }
            Styles = @{
                Default     = @{ ColorKey = "Foreground" }
                BannerFrame = @{ ColorKey = "Banner"; Font = @{ SizeDelta = 3; Style = "Bold" } }
                BannerTitle = @{ ColorKey = "Banner"; Font = @{ SizeDelta = 3; Style = "Bold" } }
                Heading     = @{ ColorKey = "Accent"; Font = @{ SizeDelta = 1; Style = "Bold" } }
                Success     = @{ ColorKey = "Success"; Font = @{ Style = "Bold" } }
                Warning     = @{ ColorKey = "Warning"; Font = @{ Style = "Bold" } }
                Error       = @{ ColorKey = "Error";   Font = @{ Style = "Bold" } }
                Info        = @{ ColorKey = "Info" }
                Action      = @{ ColorKey = "Info";    Font = @{ Style = "Bold" } }
                Accent      = @{ ColorKey = "Accent";  Font = @{ Style = "Bold" } }
                BodySmall   = @{ ColorKey = "Foreground"; Font = @{ SizeDelta = -2; Style = "Regular" } }
                Divider     = @{ ColorKey = "Divider" }
                Muted       = @{ ColorKey = "Muted"; Font = @{ Style = "Italic" } }
            }
        }
        Console = @{
            Colors = @{
                Default = "Gray"
                Success = "Green"
                Warning = "Yellow"
                Error   = "Red"
                Info    = "Cyan"
                Accent  = "Magenta"
            }
        }
    }
    return $scheme
}

function Test-HashtableEqual {
    param(
        [object]$First,
        [object]$Second
    )

    $jsonA = if ($First -ne $null) { ConvertTo-Json -InputObject $First -Depth 10 } else { "" }
    $jsonB = if ($Second -ne $null) { ConvertTo-Json -InputObject $Second -Depth 10 } else { "" }
    return $jsonA -eq $jsonB
}

function Set-ColorSchemeDefaults {
    param([hashtable]$Settings)

    if (-not $Settings) { return $false }
    $defaultScheme = Get-DefaultColorScheme

    if (-not $Settings.ContainsKey("ColorScheme")) {
        $Settings["ColorScheme"] = $defaultScheme
        return $true
    }

    $current = $Settings["ColorScheme"]
    if ($current -isnot [hashtable]) {
        $current = ConvertTo-SettingsHashtable -InputObject $current
    }

    $merged = Merge-SettingsHashtable -Base $defaultScheme -Override $current
    $changed = -not (Test-HashtableEqual -First $merged -Second $current)
    $Settings["ColorScheme"] = $merged
    return $changed
}

# Funktionen für das Laden, Speichern und Anwenden von Einstellungen
function Get-SystemToolSettings {
    <#
    .SYNOPSIS
        Gibt die aktuellen Einstellungen zurück
    .DESCRIPTION
        Diese Funktion gibt das aktuelle Einstellungsobjekt zurück, das in der Anwendung verwendet wird.
    .EXAMPLE
        $currentSettings = Get-SystemToolSettings
    #>
    return $script:settings
}

function Set-SystemToolSettings {
    <#
    .SYNOPSIS
        Setzt die Einstellungen für das System-Tool
    .DESCRIPTION
        Aktualisiert die globalen Einstellungen mit den übergebenen Werten.
    .PARAMETER Settings
        Das Einstellungsobjekt, das die neuen Einstellungen enthält
    .EXAMPLE
        Set-SystemToolSettings -Settings $newSettings
    #>
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Settings
    )
    
    $script:settings = $Settings
}

function Initialize-SystemToolSettings {
    <#
    .SYNOPSIS
        Initialisiert die Standardeinstellungen des System-Tools
    .DESCRIPTION
        Diese Funktion initialisiert die Standardeinstellungen des System-Tools und gibt sie zurück.
        Sie sollte beim Starten der Anwendung aufgerufen werden, wenn keine gespeicherten Einstellungen vorhanden sind.
    .EXAMPLE
        $defaultSettings = Initialize-SystemToolSettings
    #>
    
    $defaultSettings = @{
        FontSize            = 10
        SaveWindowSize      = $true
        WindowWidth         = 1000 # Standardwerte für die Fenstergröße
        WindowHeight        = 850  # Diese werden später überschrieben, wenn gespeichert
        WindowLeft          = 0    # Standardwerte für die Fensterposition
        WindowTop           = 0    # Diese werden später überschrieben, wenn gespeichert
        UpdateInterval      = 1000
        CpuThreshold        = 90
        RamThreshold        = 85
        GpuThreshold        = 80  
        EnableNotifications = $true
        LogLevel            = "Standard"
        AutoSaveLogs        = $false
        LogPath             = Join-Path ($PSScriptRoot | Split-Path | Split-Path) "Data\Logs"
        ConfirmActions      = $true
        AdvancedCleanup     = $false
        CheckUpdates        = $true
        ShowSplash          = $true
        ColorScheme         = Get-DefaultColorScheme
    }
    
    return $defaultSettings
}

function Import-SystemToolSettings {
    <#
    .SYNOPSIS
        Lädt Einstellungen aus der Konfigurationsdatei
    .DESCRIPTION
        Diese Funktion lädt die Einstellungen aus der Konfigurationsdatei config.json.
    .PARAMETER ConfigPath
        Der Pfad zur Konfigurationsdatei
    .EXAMPLE
        Import-SystemToolSettings -ConfigPath "C:\path\to\config.json"
    #>
    param (
        [Parameter(Mandatory = $true)]
        [string]$ConfigPath
    )
    
    if (Test-Path $ConfigPath) {
        try {
            $loadedSettings = Get-Content -Path $ConfigPath -Raw | ConvertFrom-Json
            
            # Konvertiere das JSON-Objekt in eine Hashtable
            $settingsHashtable = ConvertTo-SettingsHashtable -InputObject $loadedSettings
            if ($settingsHashtable -isnot [hashtable]) {
                $settingsHashtable = @{}
            }
            
            # Prüfe und migriere alte Log-Pfade
            $needsSave = $false
            $guiRoot = $PSScriptRoot | Split-Path | Split-Path
            $newLogPath = Join-Path $guiRoot "Data\Logs"
            
            # Wenn LogPath existiert und NICHT der neue Data-Pfad ist, migriere ihn
            if ($settingsHashtable.ContainsKey("LogPath")) {
                $currentLogPath = $settingsHashtable["LogPath"]
                # Prüfe ob es ein alter Pfad ist (LOCALAPPDATA oder nicht im Data-Ordner)
                if ($currentLogPath -match "LOCALAPPDATA" -or $currentLogPath -notmatch "Data\\Logs") {
                    Write-Host "Migration: Alter Log-Pfad erkannt, aktualisiere auf neuen Data-Pfad..." -ForegroundColor Yellow
                    $settingsHashtable["LogPath"] = $newLogPath
                    $needsSave = $true
                }
            }
            else {
                # Wenn LogPath nicht existiert, füge den neuen Pfad hinzu
                $settingsHashtable["LogPath"] = $newLogPath
                $needsSave = $true
            }
            
            # Sicherstellen, dass das neue Farbschema vorhanden ist
            if (Set-ColorSchemeDefaults -Settings $settingsHashtable) {
                $needsSave = $true
            }
            
            # Setze die Einstellungen
            Set-SystemToolSettings -Settings $settingsHashtable
            
            # Speichere automatisch, wenn eine Migration stattgefunden hat
            if ($needsSave) {
                try {
                    Export-SystemToolSettings -ConfigPath $ConfigPath -Silent
                }
                catch {
                    Write-Verbose "Konnte config.json nicht automatisch speichern: $_"
                }
            }
            
            # Rückgabe-Objekt mit allen relevanten Informationen
            return [PSCustomObject]@{
                Success = $true
                Migrated = $needsSave
                ConfigPath = $ConfigPath
            }
        }
        catch {
            Write-Host "Fehler beim Laden der Einstellungen: $_" -ForegroundColor Red
            return $false
        }
    }
    else {
        Write-Host "Keine Konfigurationsdatei gefunden, Standard-Einstellungen werden verwendet." -ForegroundColor Yellow
        
        # Initialisiere Standardeinstellungen
        $defaultSettings = Initialize-SystemToolSettings
        Set-SystemToolSettings -Settings $defaultSettings
        
        return $false
    }
}

function Export-SystemToolSettings {
    <#
    .SYNOPSIS
        Speichert Einstellungen in die Konfigurationsdatei
    .DESCRIPTION
        Diese Funktion speichert die aktuellen Einstellungen in die Konfigurationsdatei config.json.
    .PARAMETER ConfigPath
        Der Pfad zur Konfigurationsdatei
    .PARAMETER Silent
        Wenn gesetzt, wird keine Konsolenausgabe bei erfolgreichem Speichern erzeugt
    .EXAMPLE
        Export-SystemToolSettings -ConfigPath "C:\path\to\config.json"
    #>
    param (
        [Parameter(Mandatory = $true)]
        [string]$ConfigPath,
        
        [Parameter(Mandatory = $false)]
        [switch]$Silent = $false
    )
    
    try {
    $settings = Get-SystemToolSettings
    $settings | ConvertTo-Json -Depth 10 | Out-File -FilePath $ConfigPath -Encoding UTF8
        
        if (-not $Silent) {
            Write-Host "Einstellungen wurden in $ConfigPath gespeichert." -ForegroundColor Green
        }
        
        return $true
    }
    catch {
        Write-Host "Fehler beim Speichern der Einstellungen: $_" -ForegroundColor Red
        return $false
    }
}

# Funktionen für das Scan-Historie-Management
function Update-ScanHistory {
    <#
    .SYNOPSIS
        Aktualisiert die Scan-Historie für ein bestimmtes Tool
    .DESCRIPTION
        Diese Funktion aktualisiert die Scan-Historie für ein bestimmtes Tool mit dem aktuellen Zeitstempel
        und speichert die Änderungen in den Einstellungen.
    .PARAMETER ToolName
        Der Name des Tools, für das die Scan-Historie aktualisiert wird
    .EXAMPLE
        Update-ScanHistory -ToolName "WindowsDefender"
    #>
    param (
        [Parameter(Mandatory = $true)]
        [string]$ToolName
    )
    # Einstellungen holen
    $settings = Get-SystemToolSettings
    
    # Wenn ScanHistory nicht existiert, initialisieren
    # Prüfung funktioniert sowohl für PSCustomObject als auch Hashtable
    $hasScanHistory = if ($settings -is [hashtable]) {
        $settings.ContainsKey("ScanHistory")
    }
    else {
        $null -ne $settings.PSObject.Properties["ScanHistory"]
    }
    
    if (-not $hasScanHistory) {
        if ($settings -is [hashtable]) {
            $settings["ScanHistory"] = @{}
        }
        else {
            # Für PSCustomObject eine neue Eigenschaft hinzufügen
            $settings | Add-Member -MemberType NoteProperty -Name "ScanHistory" -Value @{} -Force
        }
    }
    # Aktualisiere den Zeitstempel für das angegebene Tool
    if ($settings["ScanHistory"] -is [hashtable]) {
        $settings["ScanHistory"][$ToolName] = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    }
    else {
        # Für PSCustomObject - prüfe ob die Eigenschaft existiert, wenn nicht, füge sie hinzu
        if ($null -eq $settings["ScanHistory"].PSObject.Properties[$ToolName]) {
            $settings["ScanHistory"] | Add-Member -MemberType NoteProperty -Name $ToolName -Value (Get-Date).ToString("yyyy-MM-dd HH:mm:ss") -Force
        }
        else {
            $settings["ScanHistory"].$ToolName = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        }
    }
    # Einstellungen speichern (im Hintergrund ohne Konsolenausgabe)
    Export-SystemToolSettings -ConfigPath "$PSScriptRoot\..\..\config.json" -Silent
}

function Get-ScanHistory {
    <#
    .SYNOPSIS
        Gibt die Scan-Historie für alle oder ein bestimmtes Tool zurück
    .DESCRIPTION
        Diese Funktion gibt die Scan-Historie für alle oder ein bestimmtes Tool zurück.
    .PARAMETER ToolName
        Der Name des Tools, für das die Scan-Historie abgerufen werden soll (optional)
    .EXAMPLE
        Get-ScanHistory -ToolName "WindowsDefender"
    .EXAMPLE
        Get-ScanHistory
    #>
    param (
        [Parameter(Mandatory = $false)]
        [string]$ToolName = $null
    )
    # Einstellungen holen
    $settings = Get-SystemToolSettings
    
    # Wenn ScanHistory nicht existiert, leeres Hashtable zurückgeben
    # Prüfung funktioniert sowohl für PSCustomObject als auch Hashtable
    $hasScanHistory = if ($settings -is [hashtable]) {
        $settings.ContainsKey("ScanHistory")
    }
    else {
        $null -ne $settings.PSObject.Properties["ScanHistory"]
    }
    
    if (-not $hasScanHistory) {
        if ($settings -is [hashtable]) {
            $settings["ScanHistory"] = @{}
        }
        else {
            # Für PSCustomObject eine neue Eigenschaft hinzufügen
            $settings | Add-Member -MemberType NoteProperty -Name "ScanHistory" -Value @{} -Force
        }
    }
    # Wenn ToolName angegeben ist, nur diese Historie zurückgeben
    if ($ToolName) {
        # Prüfung funktioniert sowohl für PSCustomObject als auch Hashtable
        $hasToolHistory = if ($settings["ScanHistory"] -is [hashtable]) {
            $settings["ScanHistory"].ContainsKey($ToolName)
        }
        else {
            $null -ne $settings["ScanHistory"].PSObject.Properties[$ToolName]
        }
        
        if ($hasToolHistory) {
            return $settings["ScanHistory"].$ToolName
        }
        else {
            return $null
        }
    }
    
    # Ansonsten die gesamte Historie zurückgeben
    return $settings["ScanHistory"]
}

function Get-ScanStatus {
    <#
    .SYNOPSIS
        Ermittelt den Status eines Scans basierend auf dem letzten Ausführungszeitpunkt
    .DESCRIPTION
        Diese Funktion gibt den Status eines Scans zurück (Grün/Gelb/Rot), basierend auf dem
        letzten Ausführungszeitpunkt und den konfigurierbaren Schwellwerten.
    .PARAMETER ToolName
        Der Name des Tools, für das der Scan-Status ermittelt werden soll
    .EXAMPLE
        Get-ScanStatus -ToolName "WindowsDefender"
    #>
    param (
        [Parameter(Mandatory = $true)]
        [string]$ToolName
    )
    
    # Status-Farben
    $greenStatus = [System.Drawing.Color]::LimeGreen  # LimeGreen
    $yellowStatus = [System.Drawing.Color]::Gold      # Gold
    $redStatus = [System.Drawing.Color]::Crimson      # Crimson
    
    # Einstellungen und letzten Scan-Zeitpunkt holen
    $lastScanTime = Get-ScanHistory -ToolName $ToolName
    
    # Wenn kein Scan durchgeführt wurde, Rot zurückgeben
    if (-not $lastScanTime) {
        return $redStatus
    }
    
    # Zeitdifferenz berechnen
    $scanTime = [DateTime]::ParseExact($lastScanTime, "yyyy-MM-dd HH:mm:ss", $null)
    $timeDiff = (Get-Date) - $scanTime
    
    # Schwellwerte abhängig vom Tool definieren
    switch ($ToolName) {
        "WindowsDefender" {
            # Für Windows Defender: grün < 1 Tag, gelb < 7 Tage, sonst rot
            if ($timeDiff.TotalDays -lt 1) {
                return $greenStatus
            }
            elseif ($timeDiff.TotalDays -lt 7) {
                return $yellowStatus
            }
            else {
                return $redStatus
            }
        }
        "QuickMRT" {
            # Für Quick MRT: grün < 7 Tage, gelb < 30 Tage, sonst rot
            if ($timeDiff.TotalDays -lt 7) {
                return $greenStatus
            }
            elseif ($timeDiff.TotalDays -lt 30) {
                return $yellowStatus
            }
            else {
                return $redStatus
            }
        }
        "FullMRT" {
            # Für Full MRT: grün < 30 Tage, gelb < 90 Tage, sonst rot
            if ($timeDiff.TotalDays -lt 30) {
                return $greenStatus
            }
            elseif ($timeDiff.TotalDays -lt 90) {
                return $yellowStatus
            }
            else {
                return $redStatus
            }
        }
        "SFC" {
            # Für SFC: grün < 30 Tage, gelb < 90 Tage, sonst rot
            if ($timeDiff.TotalDays -lt 30) {
                return $greenStatus
            }
            elseif ($timeDiff.TotalDays -lt 90) {
                return $yellowStatus
            }
            else {
                return $redStatus
            }
        }
        "MemoryDiag" {
            # Für MemoryDiag: grün < 90 Tage, gelb < 180 Tage, sonst rot
            if ($timeDiff.TotalDays -lt 90) {
                return $greenStatus
            }
            elseif ($timeDiff.TotalDays -lt 180) {
                return $yellowStatus
            }
            else {
                return $redStatus
            }
        }
        "WinUpdate" {
            # Für WinUpdate: grün < 7 Tage, gelb < 30 Tage, sonst rot
            if ($timeDiff.TotalDays -lt 7) {
                return $greenStatus
            }
            elseif ($timeDiff.TotalDays -lt 30) {
                return $yellowStatus
            }
            else {
                return $redStatus
            }
        }
        "DISM" {
            # Für DISM-Tools: grün < 90 Tage, gelb < 180 Tage, sonst rot
            if ($timeDiff.TotalDays -lt 90) {
                return $greenStatus
            }
            elseif ($timeDiff.TotalDays -lt 180) {
                return $yellowStatus
            }
            else {
                return $redStatus
            }
        }        "CHKDSK" {
            # Für CHKDSK: grün < 180 Tage, gelb < 365 Tage, sonst rot
            if ($timeDiff.TotalDays -lt 180) {
                return $greenStatus
            }
            elseif ($timeDiff.TotalDays -lt 365) {
                return $yellowStatus
            }
            else {
                return $redStatus
            }
        }
        "DiskCleanup" {
            # Für DiskCleanup: grün < 7 Tage, gelb < 30 Tage, sonst rot
            if ($timeDiff.TotalDays -lt 7) {
                return $greenStatus
            }
            elseif ($timeDiff.TotalDays -lt 30) {
                return $yellowStatus
            }
            else {
                return $redStatus
            }
        }
        default {
            # Standard für alle anderen Tools: grün < 30 Tage, gelb < 90 Tage, sonst rot
            if ($timeDiff.TotalDays -lt 30) {
                return $greenStatus
            }
            elseif ($timeDiff.TotalDays -lt 90) {
                return $yellowStatus
            }
            else {
                return $redStatus
            }
        }
    }
}

function Update-SystemToolUI {
    <#
    .SYNOPSIS
        Wendet Einstellungen auf die Benutzeroberfläche an
    .DESCRIPTION
        Diese Funktion wendet die aktuellen Einstellungen auf die Benutzeroberfläche an.
    .PARAMETER UIElements
        Eine Hashtable mit den UI-Elementen, auf die die Einstellungen angewendet werden sollen
    .EXAMPLE
        Update-SystemToolUI -UIElements @{
            OutputBox = $outputBox
            MainForm = $mainform
            HardwareInfoBox = $hardwareInfoBox
            SystemStatusBox = $systemStatusBox
            ToolInfoBox = $toolInfoBox
            ToolDownloadsBox = $toolDownloadsBox
            HardwareTimer = $script:hardwareTimer
        }
    #>
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$UIElements
    )
    
    try {
        $settings = Get-SystemToolSettings
        
        # Sicherheitsüberprüfung, dass die notwendigen Steuerelemente vorhanden sind
        if ($null -eq $UIElements.OutputBox -or $null -eq $UIElements.MainForm) {
            Write-Host "Kann Einstellungen nicht anwenden, da Steuerelemente noch nicht initialisiert sind." -ForegroundColor Yellow
            return $false
        }
        
        # 1. Schriftgröße
        if ($null -ne $settings.FontSize -and [int]$settings.FontSize -gt 0) {
            $newFontSize = [int]$settings.FontSize
            $UIElements.OutputBox.Font = New-Object System.Drawing.Font($UIElements.OutputBox.Font.FontFamily, $newFontSize)
            
            # Wenn weitere RichTextBoxes vorhanden sind, auch dort Schriftgröße anpassen
            if ($null -ne $UIElements.HardwareInfoBox) {
                $UIElements.HardwareInfoBox.Font = New-Object System.Drawing.Font($UIElements.HardwareInfoBox.Font.FontFamily, $newFontSize)
            }
            if ($null -ne $UIElements.SystemStatusBox) {
                $UIElements.SystemStatusBox.Font = New-Object System.Drawing.Font($UIElements.SystemStatusBox.Font.FontFamily, $newFontSize)
            }
            if ($null -ne $UIElements.ToolInfoBox) {
                $UIElements.ToolInfoBox.Font = New-Object System.Drawing.Font($UIElements.ToolInfoBox.Font.FontFamily, $newFontSize)
            }
            if ($null -ne $UIElements.ToolDownloadsBox) {
                $UIElements.ToolDownloadsBox.Font = New-Object System.Drawing.Font($UIElements.ToolDownloadsBox.Font.FontFamily, $newFontSize)
            }
        }
        
        # 2. Hardware Monitor Update-Intervall anpassen, falls vorhanden
        if ($null -ne $UIElements.HardwareTimer -and $null -ne $settings.UpdateInterval) {
            $UIElements.HardwareTimer.Interval = [int]$settings.UpdateInterval
        }
        
        # 4. Schwellenwerte für Hardware-Überwachung direkt im Hardware-Monitor-Modul setzen
        if ($settings.CpuThreshold -ne $null -or $settings.RamThreshold -ne $null -or $settings.GpuThreshold -ne $null) {
            try {
                $params = @{}
                if ($settings.CpuThreshold -ne $null) { $params['CpuThreshold'] = [int]$settings.CpuThreshold }
                if ($settings.RamThreshold -ne $null) { $params['RamThreshold'] = [int]$settings.RamThreshold }
                if ($settings.GpuThreshold -ne $null) { $params['GpuThreshold'] = [int]$settings.GpuThreshold }
                Set-HardwareThresholds @params
            }
            catch {
                Write-Verbose "Hardware-Schwellenwerte konnten nicht gesetzt werden (Modul möglicherweise nicht geladen): $_"
            }
        }
        
        # Die Meldung wird jetzt in der GUI-Initialisierung angezeigt
        # Write-Host "`r[+] Einstellungen wurden erfolgreich angewendet." -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "`r[!] Fehler beim Anwenden der Einstellungen: $_" -ForegroundColor Red
        return $false
    }
}

function Show-SettingsDialog {
    <#
    .SYNOPSIS
        Zeigt den Einstellungsdialog an
    .DESCRIPTION
        Diese Funktion erstellt und zeigt den Einstellungsdialog an.
    .PARAMETER MainForm
        Das Hauptformular der Anwendung
    .PARAMETER OutputBox
        Die Ausgabe-TextBox der Anwendung
    .PARAMETER MainPanels
        Eine Hashtable mit den Haupt-Panels und -Buttons der Anwendung
    .EXAMPLE
        Show-SettingsDialog -MainForm $mainform -OutputBox $outputBox -MainPanels @{
            SystemPanel = $systemPanel
            DiskPanel = $diskPanel
            NetworkPanel = $networkPanel
            CleanupPanel = $cleanupPanel
            BtnSystem = $btnSystem
            BtnDisk = $btnDisk
            BtnNetwork = $btnNetwork
            BtnCleanup = $btnCleanup
        }
    #>
    param (
        [Parameter(Mandatory = $true)]
        [System.Windows.Forms.Form]$MainForm,
        
        [Parameter(Mandatory = $true)]
        [System.Windows.Forms.RichTextBox]$OutputBox,
        
        [Parameter(Mandatory = $true)]
        [System.Collections.Hashtable]$MainPanels
    )
    
    # Aktuelle Fenstergröße und -position speichern, wenn eingeschaltet
    $currentWindowWidth = $MainForm.Width
    $currentWindowHeight = $MainForm.Height
    $currentWindowLeft = $MainForm.Left
    $currentWindowTop = $MainForm.Top
    
    # Logik für das Einstellungsmenü im modernen Dark Theme
    $settingsForm = New-Object System.Windows.Forms.Form
    $settingsForm.Text = "Einstellungen"
    $settingsForm.Size = New-Object System.Drawing.Size(600, 500)
    $settingsForm.StartPosition = "CenterParent"
    $settingsForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::None
    $settingsForm.MaximizeBox = $false
    $settingsForm.MinimizeBox = $false
    $settingsForm.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)  # Gleiche Farbe wie Hauptgui
    
    # Runde Ecken für das Einstellungsformular
    try {
        $regionHandle = [RoundedCorners]::CreateRoundRectRgn(0, 0, $settingsForm.Width, $settingsForm.Height, 10, 10)
        if ($regionHandle -ne [IntPtr]::Zero) {
            $settingsForm.Region = [System.Drawing.Region]::FromHrgn($regionHandle)
        }
    } catch {
        # Falls runde Ecken nicht funktionieren, weitermachen
    }
    
    # Dark Theme Farben
    $isDarkMode = $true
    $settingsForm.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
    $textColor = [System.Drawing.Color]::FromArgb(220, 220, 220)
    $panelColor = [System.Drawing.Color]::FromArgb(37, 37, 38)
    $borderColor = [System.Drawing.Color]::FromArgb(63, 63, 70)
    
    # Benutzerdefinierte Titelleiste
    $titleBar = New-Object System.Windows.Forms.Panel
    $titleBar.Size = New-Object System.Drawing.Size(600, 35)
    $titleBar.Location = New-Object System.Drawing.Point(0, 0)
    $titleBar.BackColor = [System.Drawing.Color]::FromArgb(45, 45, 48)
    $settingsForm.Controls.Add($titleBar)
    
    # Titel-Label
    $titleLabel = New-Object System.Windows.Forms.Label
    $titleLabel.Text = "⚙ Einstellungen"
    $titleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
    $titleLabel.ForeColor = [System.Drawing.Color]::White
    $titleLabel.Location = New-Object System.Drawing.Point(10, 7)
    $titleLabel.Size = New-Object System.Drawing.Size(400, 25)
    $titleBar.Controls.Add($titleLabel)
    
    # Schließen-Button
    $btnClose = New-Object System.Windows.Forms.Button
    $btnClose.Text = "✕"
    $btnClose.Size = New-Object System.Drawing.Size(35, 35)
    $btnClose.Location = New-Object System.Drawing.Point(565, 0)
    $btnClose.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $btnClose.FlatAppearance.BorderSize = 0
    $btnClose.BackColor = [System.Drawing.Color]::Transparent
    $btnClose.ForeColor = [System.Drawing.Color]::White
    $btnClose.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
    $btnClose.Add_Click({ $settingsForm.Close() })
    $btnClose.Add_MouseEnter({ $this.BackColor = [System.Drawing.Color]::FromArgb(232, 17, 35) })
    $btnClose.Add_MouseLeave({ $this.BackColor = [System.Drawing.Color]::Transparent })
    $titleBar.Controls.Add($btnClose)
    
    # Fenster verschiebbar machen
    $titleBar.Add_MouseDown({
        param($sender, $e)
        if ($e.Button -eq [System.Windows.Forms.MouseButtons]::Left) {
            $script:dragging = $true
            $script:dragCursorPoint = $e.Location
        }
    })
    $titleBar.Add_MouseMove({
        param($sender, $e)
        if ($script:dragging) {
            $newLocation = $settingsForm.PointToScreen($e.Location)
            $settingsForm.Location = New-Object System.Drawing.Point(
                ($newLocation.X - $script:dragCursorPoint.X),
                ($newLocation.Y - $script:dragCursorPoint.Y)
            )
        }
    })
    $titleBar.Add_MouseUp({
        $script:dragging = $false
    })
    
    # TabControl für Einstellungskategorien im Dark Theme
    $settingsTabControl = New-Object System.Windows.Forms.TabControl
    $settingsTabControl.Location = New-Object System.Drawing.Point(10, 45)
    $settingsTabControl.Size = New-Object System.Drawing.Size(580, 395)
    $settingsTabControl.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $settingsTabControl.BackColor = [System.Drawing.Color]::FromArgb(37, 37, 38)
    $settingsTabControl.ForeColor = [System.Drawing.Color]::FromArgb(220, 220, 220)
    
    # Tab 1: Anzeige-Einstellungen im Dark Theme
    $tabDisplay = New-Object System.Windows.Forms.TabPage
    $tabDisplay.Text = "Anzeige"
    $tabDisplay.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
    $tabDisplay.ForeColor = [System.Drawing.Color]::FromArgb(220, 220, 220)
    
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
    $cmbFontSize.BackColor = [System.Drawing.Color]::FromArgb(37, 37, 38)
    $cmbFontSize.ForeColor = [System.Drawing.Color]::FromArgb(220, 220, 220)
    $cmbFontSize.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    @(8, 9, 10, 11, 12, 14) | ForEach-Object { $cmbFontSize.Items.Add($_) }
    $cmbFontSize.SelectedItem = $script:settings.FontSize  # Aktuelle Einstellung laden
    $tabDisplay.Controls.Add($cmbFontSize)
    
    # Fenstergröße speichern
    $chkSaveWindowSize = New-Object System.Windows.Forms.CheckBox
    $chkSaveWindowSize.Text = "Fenstergröße und Position speichern"
    $chkSaveWindowSize.Location = New-Object System.Drawing.Point(15, 60)
    $chkSaveWindowSize.Size = New-Object System.Drawing.Size(300, 25)
    $chkSaveWindowSize.ForeColor = $textColor
    $chkSaveWindowSize.Checked = $script:settings.SaveWindowSize  # Aktuelle Einstellung laden
    $tabDisplay.Controls.Add($chkSaveWindowSize)
    
    # Symbol-Farben Gruppe
    $grpSymbolColors = New-Object System.Windows.Forms.GroupBox
    $grpSymbolColors.Text = "Symbol-Farben anpassen"
    $grpSymbolColors.Location = New-Object System.Drawing.Point(15, 100)
    $grpSymbolColors.Size = New-Object System.Drawing.Size(550, 240)
    $grpSymbolColors.ForeColor = [System.Drawing.Color]::FromArgb(100, 181, 246)
    $tabDisplay.Controls.Add($grpSymbolColors)
    
    # Lade aktuelle Symbol-Konfiguration
    $currentColors = Get-TextStyleConfig
    
    # Erstelle Farb-Picker für wichtige Symbole
    $symbolTypes = @(
        @{ Name = "Success"; Label = "[√] Erfolg"; YPos = 25 },
        @{ Name = "Error"; Label = "[X] Fehler"; YPos = 60 },
        @{ Name = "Warning"; Label = "[!] Warnung"; YPos = 95 },
        @{ Name = "Info"; Label = "[►] Info"; YPos = 130 },
        @{ Name = "Process"; Label = "[>] Prozess"; YPos = 165 },
        @{ Name = "Alert"; Label = "Hinweis"; YPos = 200 }
    )
    
    $colorPickers = @{}
    
    foreach ($symbolType in $symbolTypes) {
        # Label für Symbol-Typ
        $lblSymbol = New-Object System.Windows.Forms.Label
        $lblSymbol.Text = $symbolType.Label
        $lblSymbol.Location = New-Object System.Drawing.Point(15, $symbolType.YPos)
        $lblSymbol.Size = New-Object System.Drawing.Size(120, 25)
        $lblSymbol.ForeColor = $textColor
        $grpSymbolColors.Controls.Add($lblSymbol)
        
        # Farb-Button
        $btnColor = New-Object System.Windows.Forms.Button
        $btnColor.Location = New-Object System.Drawing.Point(150, $symbolType.YPos)
        $btnColor.Size = New-Object System.Drawing.Size(100, 25)
        $btnColor.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
        $btnColor.FlatAppearance.BorderSize = 1
        
        # Hole aktuelle Farbe
        $styleKey = if ($currentColors.Output.Symbols.ContainsKey($symbolType.Name)) {
            $currentColors.Output.Symbols[$symbolType.Name].StyleKey
        } else {
            $symbolType.Name
        }
        
        $currentColor = Get-OutputColor -Key $styleKey
        $btnColor.BackColor = $currentColor
        $btnColor.Text = "Farbe wählen"
        $btnColor.ForeColor = if ($currentColor.GetBrightness() -lt 0.5) { [System.Drawing.Color]::White } else { [System.Drawing.Color]::Black }
        
        # Farb-Auswahl Event
        $btnColor.Add_Click({
            param($sender, $e)
            $colorDialog = New-Object System.Windows.Forms.ColorDialog
            $colorDialog.Color = $sender.BackColor
            $colorDialog.FullOpen = $true
            
            if ($colorDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
                $sender.BackColor = $colorDialog.Color
                $sender.ForeColor = if ($colorDialog.Color.GetBrightness() -lt 0.5) { [System.Drawing.Color]::White } else { [System.Drawing.Color]::Black }
            }
        }.GetNewClosure())
        
        $grpSymbolColors.Controls.Add($btnColor)
        $colorPickers[$symbolType.Name] = $btnColor
        
        # Vorschau-Label mit Symbol
        $lblPreview = New-Object System.Windows.Forms.Label
        $lblPreview.Text = $(Get-Symbol -Type $symbolType.Name)
        $lblPreview.Location = New-Object System.Drawing.Point(270, $symbolType.YPos)
        $lblPreview.Size = New-Object System.Drawing.Size(40, 25)
        $lblPreview.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
        $lblPreview.ForeColor = $currentColor
        $grpSymbolColors.Controls.Add($lblPreview)
        
        # Aktualisiere Vorschau bei Farbwechsel
        $btnColor.Tag = @{ PreviewLabel = $lblPreview }
        $btnColor.Add_Click({
            param($sender, $e)
            if ($sender.Tag -and $sender.Tag.PreviewLabel) {
                $sender.Tag.PreviewLabel.ForeColor = $sender.BackColor
            }
        }.GetNewClosure())
        
        # Reset-Button
        $btnReset = New-Object System.Windows.Forms.Button
        $btnReset.Text = "↻"
        $btnReset.Location = New-Object System.Drawing.Point(320, $symbolType.YPos)
        $btnReset.Size = New-Object System.Drawing.Size(30, 25)
        $btnReset.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
        $btnReset.FlatAppearance.BorderSize = 1
        $btnReset.BackColor = [System.Drawing.Color]::FromArgb(45, 45, 48)
        $btnReset.ForeColor = [System.Drawing.Color]::FromArgb(220, 220, 220)
        $btnReset.Font = New-Object System.Drawing.Font("Segoe UI", 10)
        $btnReset.Tag = @{ ColorButton = $btnColor; PreviewLabel = $lblPreview; SymbolType = $symbolType.Name }
        $btnReset.Add_Click({
            param($sender, $e)
            $defaults = Get-DefaultTextStyle
            $styleKey = if ($defaults.Output.Symbols.ContainsKey($sender.Tag.SymbolType)) {
                $defaults.Output.Symbols[$sender.Tag.SymbolType].StyleKey
            } else {
                $sender.Tag.SymbolType
            }
            $defaultColorHex = $defaults.Output.Colors[$styleKey]
            $defaultColor = [System.Drawing.ColorTranslator]::FromHtml($defaultColorHex)
            
            $sender.Tag.ColorButton.BackColor = $defaultColor
            $sender.Tag.ColorButton.ForeColor = if ($defaultColor.GetBrightness() -lt 0.5) { [System.Drawing.Color]::White } else { [System.Drawing.Color]::Black }
            $sender.Tag.PreviewLabel.ForeColor = $defaultColor
        }.GetNewClosure())
        $grpSymbolColors.Controls.Add($btnReset)
    }
    
    # Tab 2: Systemüberwachung
    $tabMonitoring = New-Object System.Windows.Forms.TabPage
    $tabMonitoring.Text = "Überwachung"
    $tabMonitoring.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
    $tabMonitoring.ForeColor = [System.Drawing.Color]::FromArgb(220, 220, 220)
    
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
    $numUpdateInterval.Value = $script:settings.UpdateInterval  # Aktuelle Einstellung laden
    $numUpdateInterval.BackColor = [System.Drawing.Color]::FromArgb(37, 37, 38)
    $numUpdateInterval.ForeColor = [System.Drawing.Color]::FromArgb(220, 220, 220)
    $numUpdateInterval.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
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
    $numCpuThreshold.Value = $script:settings.CpuThreshold  # Aktuelle Einstellung laden
    $numCpuThreshold.BackColor = [System.Drawing.Color]::FromArgb(37, 37, 38)
    $numCpuThreshold.ForeColor = [System.Drawing.Color]::FromArgb(220, 220, 220)
    $numCpuThreshold.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
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
    $numRamThreshold.Value = $script:settings.RamThreshold  # Aktuelle Einstellung laden
    $numRamThreshold.BackColor = [System.Drawing.Color]::FromArgb(37, 37, 38)
    $numRamThreshold.ForeColor = [System.Drawing.Color]::FromArgb(220, 220, 220)
    $numRamThreshold.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
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
    $numGpuThreshold.Value = $script:settings.GpuThreshold  # Aktuelle Einstellung laden
    $numGpuThreshold.BackColor = [System.Drawing.Color]::FromArgb(37, 37, 38)
    $numGpuThreshold.ForeColor = [System.Drawing.Color]::FromArgb(220, 220, 220)
    $numGpuThreshold.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
    $tabMonitoring.Controls.Add($numGpuThreshold)
    
    # Benachrichtigungen aktivieren 
    $chkEnableNotifications = New-Object System.Windows.Forms.CheckBox
    $chkEnableNotifications.Text = "Benachrichtigungen aktivieren"
    $chkEnableNotifications.Location = New-Object System.Drawing.Point(15, 180)
    $chkEnableNotifications.Size = New-Object System.Drawing.Size(300, 25)
    $chkEnableNotifications.ForeColor = $textColor
    $chkEnableNotifications.Checked = $script:settings.EnableNotifications  # Aktuelle Einstellung laden
    $tabMonitoring.Controls.Add($chkEnableNotifications)
    
    # Tab 3: Logs & Berichte
    $tabLogs = New-Object System.Windows.Forms.TabPage
    $tabLogs.Text = "Logs & Berichte"
    $tabLogs.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
    $tabLogs.ForeColor = [System.Drawing.Color]::FromArgb(220, 220, 220)
    
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
    $cmbLogLevel.BackColor = [System.Drawing.Color]::FromArgb(37, 37, 38)
    $cmbLogLevel.ForeColor = [System.Drawing.Color]::FromArgb(220, 220, 220)
    $cmbLogLevel.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    @("Minimal", "Standard", "Detailliert", "Debug") | ForEach-Object { $cmbLogLevel.Items.Add($_) }
    $cmbLogLevel.SelectedItem = $script:settings.LogLevel  # Aktuelle Einstellung laden
    $tabLogs.Controls.Add($cmbLogLevel)
    
    # Automatisches Speichern
    $chkAutoSaveLogs = New-Object System.Windows.Forms.CheckBox
    $chkAutoSaveLogs.Text = "Logs automatisch speichern"
    $chkAutoSaveLogs.Location = New-Object System.Drawing.Point(15, 60)
    $chkAutoSaveLogs.Size = New-Object System.Drawing.Size(300, 25)
    $chkAutoSaveLogs.ForeColor = $textColor
    $chkAutoSaveLogs.Checked = $script:settings.AutoSaveLogs  # Aktuelle Einstellung laden
    $tabLogs.Controls.Add($chkAutoSaveLogs)
    
    # Log-Pfad
    $lblLogPath = New-Object System.Windows.Forms.Label
    $lblLogPath.Text = "Log-Pfad:"
    $lblLogPath.Location = New-Object System.Drawing.Point(15, 100)
    $lblLogPath.Size = New-Object System.Drawing.Size(120, 25)
    $lblLogPath.ForeColor = $textColor
    $tabLogs.Controls.Add($lblLogPath)
    
    $txtLogPath = New-Object System.Windows.Forms.TextBox
    $txtLogPath.Location = New-Object System.Drawing.Point(150, 100)
    $txtLogPath.Size = New-Object System.Drawing.Size(250, 25)
    $txtLogPath.Text = $script:settings.LogPath  # Aktuelle Einstellung laden
    $txtLogPath.ReadOnly = $true  # Schreibgeschützt - wird automatisch verwaltet
    $txtLogPath.BackColor = [System.Drawing.Color]::FromArgb(45, 45, 48)
    $txtLogPath.ForeColor = [System.Drawing.Color]::FromArgb(180, 180, 180)
    $txtLogPath.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
    $txtLogPath.Cursor = [System.Windows.Forms.Cursors]::Arrow
    $tabLogs.Controls.Add($txtLogPath)
    
    # Info-Label unterhalb des Log-Pfads
    $lblLogPathInfo = New-Object System.Windows.Forms.Label
    $lblLogPathInfo.Text = "ℹ️ Log-Pfad wird automatisch verwaltet (lokaler AppData-Ordner)"
    $lblLogPathInfo.Location = New-Object System.Drawing.Point(150, 125)
    $lblLogPathInfo.Size = New-Object System.Drawing.Size(350, 20)
    $lblLogPathInfo.ForeColor = [System.Drawing.Color]::Gray
    $lblLogPathInfo.Font = New-Object System.Drawing.Font("Segoe UI", 8)
    $tabLogs.Controls.Add($lblLogPathInfo)
    
    # Reset-Logs Button
    $btnResetLogs = New-Object System.Windows.Forms.Button
    $btnResetLogs.Text = "Alle Logs zurücksetzen"
    $btnResetLogs.Location = New-Object System.Drawing.Point(15, 155)
    $btnResetLogs.Size = New-Object System.Drawing.Size(150, 30)
    $btnResetLogs.BackColor = [System.Drawing.Color]::Crimson  # Rot für Lösch-Aktion
    $btnResetLogs.ForeColor = [System.Drawing.Color]::White
    $btnResetLogs.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $btnResetLogs.Add_Click({
            # Bestätigungsdialog anzeigen
            $result = [System.Windows.Forms.MessageBox]::Show(
                "Möchten Sie wirklich alle Log-Dateien zurücksetzen?`n`nDiese Aktion kann nicht rückgängig gemacht werden.`n`nFolgende Logs werden gelöscht:`n• CHKDSK.log`n• DISM-Check.log`n• DISM-Scan.log`n• FullMRT.log`n• QuickMRT.log`n• SFCCheck.log`n• WindowsDefender.log`n• WindowsUpdate.log`n• DefenderOfflineScan.log`n• gui_closing.log",
                "Logs zurücksetzen",
                [System.Windows.Forms.MessageBoxButtons]::YesNo,
                [System.Windows.Forms.MessageBoxIcon]::Warning
            )
            
            if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
                try {
                    # Log-Verzeichnis aus dem lokalen AppData-Ordner
                    $logsPath = Join-Path ($PSScriptRoot | Split-Path | Split-Path) "Data\Logs"
                    $resolvedLogsPath = Resolve-Path $logsPath -ErrorAction SilentlyContinue
                    
                    if ($resolvedLogsPath) {
                        $logsFolder = $resolvedLogsPath.Path
                    }
                    else {
                        $logsFolder = $logsPath
                    }
                    
                    # Liste der zu löschenden Log-Dateien
                    $logFiles = @(
                        "CHKDSK.log",
                        "DefenderOfflineScan.log", 
                        "DISM-Check.log",
                        "DISM-Scan.log",
                        "FullMRT.log",
                        "gui_closing.log",
                        "QuickMRT.log",
                        "SFCCheck.log",
                        "WindowsDefender.log",
                        "WindowsUpdate.log"
                    )
                    
                    $deletedCount = 0
                    $errors = @()
                    
                    foreach ($logFile in $logFiles) {
                        $fullPath = Join-Path -Path $logsFolder -ChildPath $logFile
                        
                        if (Test-Path $fullPath) {
                            try {
                                Remove-Item -Path $fullPath -Force
                                $deletedCount++
                                Write-Host "Log-Datei gelöscht: $logFile" -ForegroundColor Green
                            }
                            catch {
                                $errors += "Fehler beim Löschen von $logFile`: $_"
                                Write-Host "Fehler beim Löschen von $logFile`: $_" -ForegroundColor Red
                            }
                        }
                        else {
                            Write-Host "Log-Datei nicht gefunden: $logFile" -ForegroundColor Yellow
                        }
                    }
                    
                    # Ergebnis anzeigen
                    if ($errors.Count -eq 0) {
                        [System.Windows.Forms.MessageBox]::Show(
                            "Erfolgreich $deletedCount Log-Dateien zurückgesetzt.`n`nAlle Logs wurden aus dem Verzeichnis gelöscht:`n$logsFolder",
                            "Logs erfolgreich zurückgesetzt",
                            [System.Windows.Forms.MessageBoxButtons]::OK,
                            [System.Windows.Forms.MessageBoxIcon]::Information
                        )
                    }
                    else {
                        $errorMessage = "Log-Reset teilweise erfolgreich:`n`n$deletedCount Dateien gelöscht.`n`nFehler:`n" + ($errors -join "`n")
                        [System.Windows.Forms.MessageBox]::Show(
                            $errorMessage,
                            "Log-Reset mit Fehlern",
                            [System.Windows.Forms.MessageBoxButtons]::OK,
                            [System.Windows.Forms.MessageBoxIcon]::Warning
                        )
                    }
                }
                catch {
                    [System.Windows.Forms.MessageBox]::Show(
                        "Fehler beim Zurücksetzen der Logs:`n`n$_",
                        "Fehler",
                        [System.Windows.Forms.MessageBoxButtons]::OK,
                        [System.Windows.Forms.MessageBoxIcon]::Error
                    )
                }
            }
        })
    $tabLogs.Controls.Add($btnResetLogs)
    
    # Log-Ordner öffnen Button
    $btnOpenLogFolder = New-Object System.Windows.Forms.Button
    $btnOpenLogFolder.Text = "Log-Ordner öffnen"
    $btnOpenLogFolder.Location = New-Object System.Drawing.Point(175, 155)
    $btnOpenLogFolder.Size = New-Object System.Drawing.Size(120, 30)
    $btnOpenLogFolder.BackColor = [System.Drawing.Color]::ForestGreen  # Grün für Info-Aktion
    $btnOpenLogFolder.ForeColor = [System.Drawing.Color]::White
    $btnOpenLogFolder.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $btnOpenLogFolder.Add_Click({
            try {
                # Log-Verzeichnis aus dem Data-Ordner der GUI
                $guiRoot = $PSScriptRoot | Split-Path | Split-Path
                $logsPath = Join-Path $guiRoot "Data\Logs"
                $resolvedLogsPath = Resolve-Path $logsPath -ErrorAction SilentlyContinue
                
                if ($resolvedLogsPath) {
                    $logsFolder = $resolvedLogsPath.Path
                }
                else {
                    $logsFolder = $logsPath
                }
                
                if (Test-Path $logsFolder) {
                    Start-Process "explorer.exe" -ArgumentList $logsFolder
                }
                else {
                    [System.Windows.Forms.MessageBox]::Show(
                        "Log-Ordner nicht gefunden:`n$logsFolder",
                        "Ordner nicht gefunden",
                        [System.Windows.Forms.MessageBoxButtons]::OK,
                        [System.Windows.Forms.MessageBoxIcon]::Warning
                    )
                }
            }
            catch {
                [System.Windows.Forms.MessageBox]::Show(
                    "Fehler beim Öffnen des Log-Ordners:`n`n$_",
                    "Fehler",
                    [System.Windows.Forms.MessageBoxButtons]::OK,
                    [System.Windows.Forms.MessageBoxIcon]::Error
                )
            }
        })
    $tabLogs.Controls.Add($btnOpenLogFolder)
    
    # Datenbank-Übersicht Button
    $btnDatabaseOverview = New-Object System.Windows.Forms.Button
    $btnDatabaseOverview.Text = "🗄️ Datenbank-Übersicht"
    $btnDatabaseOverview.Location = New-Object System.Drawing.Point(305, 155)
    $btnDatabaseOverview.Size = New-Object System.Drawing.Size(160, 30)
    $btnDatabaseOverview.BackColor = [System.Drawing.Color]::DodgerBlue
    $btnDatabaseOverview.ForeColor = [System.Drawing.Color]::White
    $btnDatabaseOverview.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $btnDatabaseOverview.Add_Click({
            try {
                # Importiere DatabaseManager-Modul falls noch nicht geladen
                $dbModulePath = Join-Path $PSScriptRoot "..\..\DatabaseManager.psm1"
                if (Test-Path $dbModulePath) {
                    Import-Module $dbModulePath -Force -ErrorAction SilentlyContinue
                }
                
                # Rufe Show-DatabaseOverview auf
                if (Get-Command -Name Show-DatabaseOverview -ErrorAction SilentlyContinue) {
                    Show-DatabaseOverview
                }
                else {
                    [System.Windows.Forms.MessageBox]::Show(
                        "Datenbank-Übersicht-Funktion nicht verfügbar.`n`nStellen Sie sicher, dass DatabaseManager.psm1 korrekt geladen ist.",
                        "Fehler",
                        [System.Windows.Forms.MessageBoxButtons]::OK,
                        [System.Windows.Forms.MessageBoxIcon]::Error
                    )
                }
            }
            catch {
                [System.Windows.Forms.MessageBox]::Show(
                    "Fehler beim Öffnen der Datenbank-Übersicht:`n`n$_",
                    "Fehler",
                    [System.Windows.Forms.MessageBoxButtons]::OK,
                    [System.Windows.Forms.MessageBoxIcon]::Error
                )
            }
        })
    $tabLogs.Controls.Add($btnDatabaseOverview)
    
    # Tab 4: Verhalten
    $tabBehavior = New-Object System.Windows.Forms.TabPage
    $tabBehavior.Text = "Verhalten"
    $tabBehavior.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
    $tabBehavior.ForeColor = [System.Drawing.Color]::FromArgb(220, 220, 220)
    
    # Aktionen bestätigen
    $chkConfirmActions = New-Object System.Windows.Forms.CheckBox
    $chkConfirmActions.Text = "Aktionen bestätigen"
    $chkConfirmActions.Location = New-Object System.Drawing.Point(15, 20)
    $chkConfirmActions.Size = New-Object System.Drawing.Size(300, 25)
    $chkConfirmActions.ForeColor = $textColor
    $chkConfirmActions.Checked = $script:settings.ConfirmActions  # Aktuelle Einstellung laden
    $tabBehavior.Controls.Add($chkConfirmActions)
    
    # Erweiterte Bereinigung
    $chkAdvancedCleanup = New-Object System.Windows.Forms.CheckBox
    $chkAdvancedCleanup.Text = "Erweiterte Bereinigung"
    $chkAdvancedCleanup.Location = New-Object System.Drawing.Point(15, 60)
    $chkAdvancedCleanup.Size = New-Object System.Drawing.Size(300, 25)
    $chkAdvancedCleanup.ForeColor = $textColor
    $chkAdvancedCleanup.Checked = $script:settings.AdvancedCleanup  # Aktuelle Einstellung laden
    $tabBehavior.Controls.Add($chkAdvancedCleanup)
    
    # Updates prüfen
    $chkCheckUpdates = New-Object System.Windows.Forms.CheckBox
    $chkCheckUpdates.Text = "Automatisch nach Updates suchen"
    $chkCheckUpdates.Location = New-Object System.Drawing.Point(15, 100)
    $chkCheckUpdates.Size = New-Object System.Drawing.Size(300, 25)
    $chkCheckUpdates.ForeColor = $textColor
    $chkCheckUpdates.Checked = $script:settings.CheckUpdates  # Aktuelle Einstellung laden
    $tabBehavior.Controls.Add($chkCheckUpdates)
    
    # Splash-Screen anzeigen
    $chkShowSplash = New-Object System.Windows.Forms.CheckBox
    $chkShowSplash.Text = "Splash-Screen beim Start anzeigen"
    $chkShowSplash.Location = New-Object System.Drawing.Point(15, 140)
    $chkShowSplash.Size = New-Object System.Drawing.Size(300, 25)
    $chkShowSplash.ForeColor = $textColor
    $chkShowSplash.Checked = $script:settings.ShowSplash  # Aktuelle Einstellung laden
    $tabBehavior.Controls.Add($chkShowSplash)
    
    # Tab 5: System-Einstellungen
    $tabSystem_Settings = New-Object System.Windows.Forms.TabPage
    $tabSystem_Settings.Text = "System"
    $tabSystem_Settings.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
    $tabSystem_Settings.ForeColor = [System.Drawing.Color]::FromArgb(220, 220, 220)
    
    # Windows Defender-Dienste neu starten
    $btnRestartDefenderSettings = New-Object System.Windows.Forms.Button
    $btnRestartDefenderSettings.Text = "Windows Defender-Dienste neu starten"
    $btnRestartDefenderSettings.Location = New-Object System.Drawing.Point(15, 20)
    $btnRestartDefenderSettings.Size = New-Object System.Drawing.Size(250, 30)
    $btnRestartDefenderSettings.Add_Click({
            # Verstecke Einstellungsfenster während der Operation
            $settingsForm.Hide()
            Switch-ToOutputTab
            $OutputBox.Clear()
            Update-ProgressStatus -StatusText "Windows Defender-Dienst Neustart wird vorbereitet..." -ProgressValue 0 -TextColor ([System.Drawing.Color]::White)
            Restart-DefenderService -outputBox $OutputBox -progressBar $progressBar -MainForm $MainForm
            $settingsForm.Show()  # Zeige Einstellungsfenster wieder an
        })
    $tabSystem_Settings.Controls.Add($btnRestartDefenderSettings)
    
    # Beschreibungstext für den Button
    $lblRestartDefenderDesc = New-Object System.Windows.Forms.Label
    $lblRestartDefenderDesc.Text = "Startet Windows Defender-Dienste neu, wenn MRT-Scans hängen oder Probleme auftreten."
    $lblRestartDefenderDesc.Location = New-Object System.Drawing.Point(15, 60)
    $lblRestartDefenderDesc.Size = New-Object System.Drawing.Size(450, 40)
    $lblRestartDefenderDesc.ForeColor = $textColor
    $tabSystem_Settings.Controls.Add($lblRestartDefenderDesc)
    
    # ===================================================================
    # TAB 6: PFADE
    # ===================================================================
    $tabPaths = New-Object System.Windows.Forms.TabPage
    $tabPaths.Text = "📂 Pfade"
    $tabPaths.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
    $tabPaths.ForeColor = [System.Drawing.Color]::FromArgb(220, 220, 220)
    $tabPaths.AutoScroll = $true
    
    # Beschreibung
    $lblPathsDesc = New-Object System.Windows.Forms.Label
    $lblPathsDesc.Text = "Übersicht aller wichtigen Verzeichnisse des Tools"
    $lblPathsDesc.Location = New-Object System.Drawing.Point(15, 10)
    $lblPathsDesc.Size = New-Object System.Drawing.Size(550, 20)
    $lblPathsDesc.ForeColor = [System.Drawing.Color]::FromArgb(150, 150, 150)
    $lblPathsDesc.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Italic)
    $tabPaths.Controls.Add($lblPathsDesc)
    
    # Pfade definieren (alle im Data-Ordner der GUI)
    $guiRoot = $PSScriptRoot | Split-Path | Split-Path  # Zwei Ebenen hoch zum Installationsordner
    $logsPath = Join-Path $guiRoot "Data\Logs"
    $databasePath = Join-Path $guiRoot "Data\Database"
    $installPath = $guiRoot
    $downloadPath = Join-Path $guiRoot "Data\ToolDownloads"
    $toolsInstallPath = $env:ProgramFiles
    
    # Y-Position für Elemente
    $currentY = 40
    
    # 1. Logs-Ordner
    $lblLogs = New-Object System.Windows.Forms.Label
    $lblLogs.Text = "Logs-Verzeichnis"
    $lblLogs.Location = New-Object System.Drawing.Point(15, $currentY)
    $lblLogs.Size = New-Object System.Drawing.Size(550, 20)
    $lblLogs.ForeColor = [System.Drawing.Color]::FromArgb(100, 149, 237)
    $lblLogs.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $tabPaths.Controls.Add($lblLogs)
    $currentY += 25
    
    $txtLogsPath = New-Object System.Windows.Forms.TextBox
    $txtLogsPath.Text = $logsPath
    $txtLogsPath.Location = New-Object System.Drawing.Point(15, $currentY)
    $txtLogsPath.Size = New-Object System.Drawing.Size(420, 25)
    $txtLogsPath.ReadOnly = $true
    $txtLogsPath.BackColor = [System.Drawing.Color]::FromArgb(45, 45, 48)
    $txtLogsPath.ForeColor = [System.Drawing.Color]::FromArgb(220, 220, 220)
    $txtLogsPath.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
    $tabPaths.Controls.Add($txtLogsPath)
    
    $btnOpenLogs = New-Object System.Windows.Forms.Button
    $btnOpenLogs.Text = "📂 Öffnen"
    $btnOpenLogs.Location = New-Object System.Drawing.Point(445, $currentY)
    $btnOpenLogs.Size = New-Object System.Drawing.Size(110, 25)
    $btnOpenLogs.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $btnOpenLogs.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(0, 122, 204)
    $btnOpenLogs.BackColor = [System.Drawing.Color]::FromArgb(37, 37, 38)
    $btnOpenLogs.ForeColor = [System.Drawing.Color]::FromArgb(220, 220, 220)
    $btnOpenLogs.Tag = $logsPath
    $btnOpenLogs.Add_Click({
        if (Test-Path $this.Tag) { Start-Process "explorer.exe" -ArgumentList $this.Tag }
        else { [System.Windows.Forms.MessageBox]::Show("Verzeichnis nicht gefunden: $($this.Tag)", "Fehler", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning) }
    })
    $tabPaths.Controls.Add($btnOpenLogs)
    $currentY += 30
    
    $lblLogsDesc = New-Object System.Windows.Forms.Label
    $lblLogsDesc.Text = "Enthält alle Log-Dateien der Anwendung (System-Scans, Diagnosen, Fehlerprotokolle)"
    $lblLogsDesc.Location = New-Object System.Drawing.Point(15, $currentY)
    $lblLogsDesc.Size = New-Object System.Drawing.Size(550, 30)
    $lblLogsDesc.ForeColor = [System.Drawing.Color]::FromArgb(150, 150, 150)
    $lblLogsDesc.Font = New-Object System.Drawing.Font("Segoe UI", 8)
    $tabPaths.Controls.Add($lblLogsDesc)
    $currentY += 50
    
    # 2. Datenbank-Ordner
    $lblDatabase = New-Object System.Windows.Forms.Label
    $lblDatabase.Text = "Datenbank-Verzeichnis"
    $lblDatabase.Location = New-Object System.Drawing.Point(15, $currentY)
    $lblDatabase.Size = New-Object System.Drawing.Size(550, 20)
    $lblDatabase.ForeColor = [System.Drawing.Color]::FromArgb(100, 149, 237)
    $lblDatabase.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $tabPaths.Controls.Add($lblDatabase)
    $currentY += 25
    
    $txtDatabasePath = New-Object System.Windows.Forms.TextBox
    $txtDatabasePath.Text = $databasePath
    $txtDatabasePath.Location = New-Object System.Drawing.Point(15, $currentY)
    $txtDatabasePath.Size = New-Object System.Drawing.Size(420, 25)
    $txtDatabasePath.ReadOnly = $true
    $txtDatabasePath.BackColor = [System.Drawing.Color]::FromArgb(45, 45, 48)
    $txtDatabasePath.ForeColor = [System.Drawing.Color]::FromArgb(220, 220, 220)
    $txtDatabasePath.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
    $tabPaths.Controls.Add($txtDatabasePath)
    
    $btnOpenDatabase = New-Object System.Windows.Forms.Button
    $btnOpenDatabase.Text = "📂 Öffnen"
    $btnOpenDatabase.Location = New-Object System.Drawing.Point(445, $currentY)
    $btnOpenDatabase.Size = New-Object System.Drawing.Size(110, 25)
    $btnOpenDatabase.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $btnOpenDatabase.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(0, 122, 204)
    $btnOpenDatabase.BackColor = [System.Drawing.Color]::FromArgb(37, 37, 38)
    $btnOpenDatabase.ForeColor = [System.Drawing.Color]::FromArgb(220, 220, 220)
    $btnOpenDatabase.Tag = $databasePath
    $btnOpenDatabase.Add_Click({
        if (Test-Path $this.Tag) { Start-Process "explorer.exe" -ArgumentList $this.Tag }
        else { [System.Windows.Forms.MessageBox]::Show("Verzeichnis nicht gefunden: $($this.Tag)", "Fehler", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning) }
    })
    $tabPaths.Controls.Add($btnOpenDatabase)
    $currentY += 30
    
    $lblDatabaseDesc = New-Object System.Windows.Forms.Label
    $lblDatabaseDesc.Text = "Speicherort der SQLite-Datenbank mit System-Snapshots und Hardware-Historie"
    $lblDatabaseDesc.Location = New-Object System.Drawing.Point(15, $currentY)
    $lblDatabaseDesc.Size = New-Object System.Drawing.Size(550, 30)
    $lblDatabaseDesc.ForeColor = [System.Drawing.Color]::FromArgb(150, 150, 150)
    $lblDatabaseDesc.Font = New-Object System.Drawing.Font("Segoe UI", 8)
    $tabPaths.Controls.Add($lblDatabaseDesc)
    $currentY += 50
    
    # 3. Installations-Ordner
    $lblInstall = New-Object System.Windows.Forms.Label
    $lblInstall.Text = "Installations-Verzeichnis"
    $lblInstall.Location = New-Object System.Drawing.Point(15, $currentY)
    $lblInstall.Size = New-Object System.Drawing.Size(550, 20)
    $lblInstall.ForeColor = [System.Drawing.Color]::FromArgb(100, 149, 237)
    $lblInstall.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $tabPaths.Controls.Add($lblInstall)
    $currentY += 25
    
    $txtInstallPath = New-Object System.Windows.Forms.TextBox
    $txtInstallPath.Text = $installPath
    $txtInstallPath.Location = New-Object System.Drawing.Point(15, $currentY)
    $txtInstallPath.Size = New-Object System.Drawing.Size(420, 25)
    $txtInstallPath.ReadOnly = $true
    $txtInstallPath.BackColor = [System.Drawing.Color]::FromArgb(45, 45, 48)
    $txtInstallPath.ForeColor = [System.Drawing.Color]::FromArgb(220, 220, 220)
    $txtInstallPath.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
    $tabPaths.Controls.Add($txtInstallPath)
    
    $btnOpenInstall = New-Object System.Windows.Forms.Button
    $btnOpenInstall.Text = "📂 Öffnen"
    $btnOpenInstall.Location = New-Object System.Drawing.Point(445, $currentY)
    $btnOpenInstall.Size = New-Object System.Drawing.Size(110, 25)
    $btnOpenInstall.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $btnOpenInstall.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(0, 122, 204)
    $btnOpenInstall.BackColor = [System.Drawing.Color]::FromArgb(37, 37, 38)
    $btnOpenInstall.ForeColor = [System.Drawing.Color]::FromArgb(220, 220, 220)
    $btnOpenInstall.Tag = $installPath
    $btnOpenInstall.Add_Click({
        if (Test-Path $this.Tag) { Start-Process "explorer.exe" -ArgumentList $this.Tag }
        else { [System.Windows.Forms.MessageBox]::Show("Verzeichnis nicht gefunden: $($this.Tag)", "Fehler", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning) }
    })
    $tabPaths.Controls.Add($btnOpenInstall)
    $currentY += 30
    
    $lblInstallDesc = New-Object System.Windows.Forms.Label
    $lblInstallDesc.Text = "Hauptverzeichnis der GUI-Anwendung mit allen Modulen und Bibliotheken"
    $lblInstallDesc.Location = New-Object System.Drawing.Point(15, $currentY)
    $lblInstallDesc.Size = New-Object System.Drawing.Size(550, 30)
    $lblInstallDesc.ForeColor = [System.Drawing.Color]::FromArgb(150, 150, 150)
    $lblInstallDesc.Font = New-Object System.Drawing.Font("Segoe UI", 8)
    $tabPaths.Controls.Add($lblInstallDesc)
    $currentY += 50
    
    # 4. Download-Ordner
    $lblDownload = New-Object System.Windows.Forms.Label
    $lblDownload.Text = "Tool-Downloads"
    $lblDownload.Location = New-Object System.Drawing.Point(15, $currentY)
    $lblDownload.Size = New-Object System.Drawing.Size(550, 20)
    $lblDownload.ForeColor = [System.Drawing.Color]::FromArgb(100, 149, 237)
    $lblDownload.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $tabPaths.Controls.Add($lblDownload)
    $currentY += 25
    
    $txtDownloadPath = New-Object System.Windows.Forms.TextBox
    $txtDownloadPath.Text = $downloadPath
    $txtDownloadPath.Location = New-Object System.Drawing.Point(15, $currentY)
    $txtDownloadPath.Size = New-Object System.Drawing.Size(420, 25)
    $txtDownloadPath.ReadOnly = $true
    $txtDownloadPath.BackColor = [System.Drawing.Color]::FromArgb(45, 45, 48)
    $txtDownloadPath.ForeColor = [System.Drawing.Color]::FromArgb(220, 220, 220)
    $txtDownloadPath.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
    $tabPaths.Controls.Add($txtDownloadPath)
    
    $btnOpenDownload = New-Object System.Windows.Forms.Button
    $btnOpenDownload.Text = "📂 Öffnen"
    $btnOpenDownload.Location = New-Object System.Drawing.Point(445, $currentY)
    $btnOpenDownload.Size = New-Object System.Drawing.Size(110, 25)
    $btnOpenDownload.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $btnOpenDownload.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(0, 122, 204)
    $btnOpenDownload.BackColor = [System.Drawing.Color]::FromArgb(37, 37, 38)
    $btnOpenDownload.ForeColor = [System.Drawing.Color]::FromArgb(220, 220, 220)
    $btnOpenDownload.Tag = $downloadPath
    $btnOpenDownload.Add_Click({
        if (Test-Path $this.Tag) { Start-Process "explorer.exe" -ArgumentList $this.Tag }
        else { [System.Windows.Forms.MessageBox]::Show("Verzeichnis nicht gefunden: $($this.Tag)", "Fehler", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning) }
    })
    $tabPaths.Controls.Add($btnOpenDownload)
    $currentY += 30
    
    $lblDownloadDesc = New-Object System.Windows.Forms.Label
    $lblDownloadDesc.Text = "Temporärer Speicherort für heruntergeladene Tools (wird automatisch bereinigt)"
    $lblDownloadDesc.Location = New-Object System.Drawing.Point(15, $currentY)
    $lblDownloadDesc.Size = New-Object System.Drawing.Size(550, 30)
    $lblDownloadDesc.ForeColor = [System.Drawing.Color]::FromArgb(150, 150, 150)
    $lblDownloadDesc.Font = New-Object System.Drawing.Font("Segoe UI", 8)
    $tabPaths.Controls.Add($lblDownloadDesc)
    $currentY += 50
    
    # 5. Tool-Installations-Ordner
    $lblToolsInstall = New-Object System.Windows.Forms.Label
    $lblToolsInstall.Text = "Tool-Installationen"
    $lblToolsInstall.Location = New-Object System.Drawing.Point(15, $currentY)
    $lblToolsInstall.Size = New-Object System.Drawing.Size(550, 20)
    $lblToolsInstall.ForeColor = [System.Drawing.Color]::FromArgb(100, 149, 237)
    $lblToolsInstall.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $tabPaths.Controls.Add($lblToolsInstall)
    $currentY += 25
    
    $txtToolsInstallPath = New-Object System.Windows.Forms.TextBox
    $txtToolsInstallPath.Text = $toolsInstallPath
    $txtToolsInstallPath.Location = New-Object System.Drawing.Point(15, $currentY)
    $txtToolsInstallPath.Size = New-Object System.Drawing.Size(420, 25)
    $txtToolsInstallPath.ReadOnly = $true
    $txtToolsInstallPath.BackColor = [System.Drawing.Color]::FromArgb(45, 45, 48)
    $txtToolsInstallPath.ForeColor = [System.Drawing.Color]::FromArgb(220, 220, 220)
    $txtToolsInstallPath.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
    $tabPaths.Controls.Add($txtToolsInstallPath)
    
    $btnOpenToolsInstall = New-Object System.Windows.Forms.Button
    $btnOpenToolsInstall.Text = "📂 Öffnen"
    $btnOpenToolsInstall.Location = New-Object System.Drawing.Point(445, $currentY)
    $btnOpenToolsInstall.Size = New-Object System.Drawing.Size(110, 25)
    $btnOpenToolsInstall.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $btnOpenToolsInstall.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(0, 122, 204)
    $btnOpenToolsInstall.BackColor = [System.Drawing.Color]::FromArgb(37, 37, 38)
    $btnOpenToolsInstall.ForeColor = [System.Drawing.Color]::FromArgb(220, 220, 220)
    $btnOpenToolsInstall.Tag = $toolsInstallPath
    $btnOpenToolsInstall.Add_Click({
        if (Test-Path $this.Tag) { Start-Process "explorer.exe" -ArgumentList $this.Tag }
        else { [System.Windows.Forms.MessageBox]::Show("Verzeichnis nicht gefunden: $($this.Tag)", "Fehler", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning) }
    })
    $tabPaths.Controls.Add($btnOpenToolsInstall)
    $currentY += 30
    
    $lblToolsInstallDesc = New-Object System.Windows.Forms.Label
    $lblToolsInstallDesc.Text = "Standard-Installationsort für heruntergeladene System-Tools"
    $lblToolsInstallDesc.Location = New-Object System.Drawing.Point(15, $currentY)
    $lblToolsInstallDesc.Size = New-Object System.Drawing.Size(550, 30)
    $lblToolsInstallDesc.ForeColor = [System.Drawing.Color]::FromArgb(150, 150, 150)
    $lblToolsInstallDesc.Font = New-Object System.Drawing.Font("Segoe UI", 8)
    $tabPaths.Controls.Add($lblToolsInstallDesc)
    
    # Tabs zum TabControl hinzufügen
    $settingsTabControl.TabPages.Add($tabDisplay)
    $settingsTabControl.TabPages.Add($tabMonitoring)
    $settingsTabControl.TabPages.Add($tabLogs)
    $settingsTabControl.TabPages.Add($tabBehavior)
    $settingsTabControl.TabPages.Add($tabSystem_Settings)
    $settingsTabControl.TabPages.Add($tabPaths)
    
    # TabControl zum Formular hinzufügen
    $settingsForm.Controls.Add($settingsTabControl)
    
    # OK-Button im modernen Dark Theme Style
    $btnOK = New-Object System.Windows.Forms.Button
    $btnOK.Text = "OK"
    $btnOK.Location = New-Object System.Drawing.Point(380, 450)
    $btnOK.Size = New-Object System.Drawing.Size(100, 35)
    $btnOK.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $btnOK.FlatAppearance.BorderSize = 1
    $btnOK.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(0, 122, 204)
    $btnOK.BackColor = [System.Drawing.Color]::FromArgb(0, 122, 204)
    $btnOK.ForeColor = [System.Drawing.Color]::White
    $btnOK.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $btnOK.Add_MouseEnter({ $this.BackColor = [System.Drawing.Color]::FromArgb(28, 151, 234) })
    $btnOK.Add_MouseLeave({ $this.BackColor = [System.Drawing.Color]::FromArgb(0, 122, 204) })
    $btnOK.Add_Click({
            # Einstellungen anwenden und speichern
            $script:settings = @{
                FontSize            = $cmbFontSize.SelectedItem
                SaveWindowSize      = $chkSaveWindowSize.Checked
                # Behalte die aktuellen Fenstergrößen- und Positionswerte bei
                WindowWidth         = $currentWindowWidth
                WindowHeight        = $currentWindowHeight
                WindowLeft          = $currentWindowLeft
                WindowTop           = $currentWindowTop
                UpdateInterval      = $numUpdateInterval.Value
                CpuThreshold        = $numCpuThreshold.Value
                RamThreshold        = $numRamThreshold.Value
                GpuThreshold        = $numGpuThreshold.Value
                EnableNotifications = $chkEnableNotifications.Checked
                LogLevel            = $cmbLogLevel.SelectedItem
                AutoSaveLogs        = $chkAutoSaveLogs.Checked
                LogPath             = $txtLogPath.Text
                ConfirmActions      = $chkConfirmActions.Checked
                AdvancedCleanup     = $chkAdvancedCleanup.Checked
                CheckUpdates        = $chkCheckUpdates.Checked
                ShowSplash          = $chkShowSplash.Checked
            }
            
            # Symbol-Farben in ColorScheme speichern
            if (-not $script:settings.ContainsKey("ColorScheme")) {
                $script:settings.ColorScheme = @{}
            }
            if (-not $script:settings.ColorScheme.ContainsKey("Output")) {
                $script:settings.ColorScheme.Output = @{}
            }
            if (-not $script:settings.ColorScheme.Output.ContainsKey("Colors")) {
                $script:settings.ColorScheme.Output.Colors = @{}
            }
            
            # Aktualisiere die Farben basierend auf den Farb-Pickern
            foreach ($symbolName in $colorPickers.Keys) {
                $button = $colorPickers[$symbolName]
                $color = $button.BackColor
                $hexColor = "#{0:X2}{1:X2}{2:X2}" -f $color.R, $color.G, $color.B
                
                # Finde den Style-Key für dieses Symbol
                $currentConfig = Get-TextStyleConfig
                $styleKey = if ($currentConfig.Output.Symbols.ContainsKey($symbolName)) {
                    $currentConfig.Output.Symbols[$symbolName].StyleKey
                } else {
                    $symbolName
                }
                
                # Speichere die Farbe
                $script:settings.ColorScheme.Output.Colors[$styleKey] = $hexColor
            }
            
            # Einstellungen direkt anwenden
            # 1. Schriftgröße
            $newFontSize = [int]$script:settings.FontSize
            $OutputBox.Font = New-Object System.Drawing.Font($OutputBox.Font.FontFamily, $newFontSize)
            
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
            
            # Farbschema-Funktion wurde entfernt
            
            # 3. Hardware Monitor Update-Intervall anpassen, falls vorhanden
            if ($null -ne $script:hardwareTimer) {
                $script:hardwareTimer.Interval = [int]$script:settings.UpdateInterval
            }
            
            # 4. Schwellenwerte für Hardware-Überwachung sofort anwenden
            try {
                Set-HardwareThresholds -CpuThreshold ([int]$script:settings.CpuThreshold) -RamThreshold ([int]$script:settings.RamThreshold) -GpuThreshold ([int]$script:settings.GpuThreshold)
            }
            catch {
                Write-Verbose "Hardware-Schwellenwerte konnten nicht gesetzt werden: $_"
            }
            
            # Einstellungen in Konfigurationsdatei speichern
            $settingsFilePath = "$PSScriptRoot\..\..\config.json"
            try {
                # Konvertiere zu JSON mit ausreichender Tiefe für ColorScheme
                $jsonSettings = $script:settings | ConvertTo-Json -Depth 10
                $jsonSettings | Out-File -FilePath $settingsFilePath -Encoding UTF8
                
                # TextStyle mit neuen Farben neu initialisieren
                Initialize-TextStyle -Settings $script:settings -OutputBox $OutputBox
                
                # OutputBox komplett leeren, da bereits formatierter Text die alten Farben behält
                $OutputBox.Clear()
            }
            catch {
                Write-Host "Fehler beim Speichern der Einstellungen: $_" -ForegroundColor Red
            }
            
            # Ausgabe in der OutputBox (nach Clear, damit neue Farben sofort sichtbar sind)
            Set-OutputSelectionStyle -OutputBox $OutputBox -Style 'Success'
            $OutputBox.AppendText("`r`nEinstellungen wurden aktualisiert und angewendet:`r`n")
            Set-OutputSelectionStyle -OutputBox $OutputBox -Style 'Default'
            $OutputBox.AppendText("- Schriftgröße: $($script:settings.FontSize)`r`n")
            $OutputBox.AppendText("- Update-Intervall: $($script:settings.UpdateInterval) ms`r`n")
            $OutputBox.AppendText("- CPU-Warnschwelle: $($script:settings.CpuThreshold)%`r`n")
            $OutputBox.AppendText("- RAM-Warnschwelle: $($script:settings.RamThreshold)%`r`n")
            $OutputBox.AppendText("- GPU-Warnschwelle: $($script:settings.GpuThreshold)%`r`n")
            $OutputBox.AppendText("- Log-Level: $($script:settings.LogLevel)`r`n")
            
            # Zeige Farb-Änderungen an
            $colorCount = if ($script:settings.ColorScheme.Output.Colors) { $script:settings.ColorScheme.Output.Colors.Count } else { 0 }
            if ($colorCount -gt 0) {
                $OutputBox.AppendText("- Symbol-Farben: $colorCount Farben angepasst`r`n")
                
                # Demo-Ausgabe mit allen Symbolen, um die neuen Farben sofort sichtbar zu machen
                $OutputBox.AppendText("`r`n--- Farbvorschau ---`r`n")
                Set-OutputSelectionStyle -OutputBox $OutputBox -Style 'Success'
                $OutputBox.AppendText("$(Get-Symbol -Type 'Success') Erfolgs-Nachrichten`r`n")
                Set-OutputSelectionStyle -OutputBox $OutputBox -Style 'Error'
                $OutputBox.AppendText("$(Get-Symbol -Type 'Error') Fehler-Meldungen`r`n")
                Set-OutputSelectionStyle -OutputBox $OutputBox -Style 'Warning'
                $OutputBox.AppendText("$(Get-Symbol -Type 'Warning') Warnungen`r`n")
                Set-OutputSelectionStyle -OutputBox $OutputBox -Style 'Info'
                $OutputBox.AppendText("$(Get-Symbol -Type 'Info') Informationen`r`n")
                Set-OutputSelectionStyle -OutputBox $OutputBox -Style 'Process'
                $OutputBox.AppendText("$(Get-Symbol -Type 'Process') Prozess-Status`r`n")
                Set-OutputSelectionStyle -OutputBox $OutputBox -Style 'Alert'
                $OutputBox.AppendText("Hinweis-Texte`r`n")
                Set-OutputSelectionStyle -OutputBox $OutputBox -Style 'Default'
                $OutputBox.AppendText("-------------------`r`n")
            }
            
            $OutputBox.AppendText("- Einstellungen wurden in $settingsFilePath gespeichert.`r`n")
            
            # Formular schließen
            $settingsForm.Close()
        })
    $settingsForm.Controls.Add($btnOK)
    
    # Abbrechen-Button im modernen Dark Theme Style
    $btnCancel = New-Object System.Windows.Forms.Button
    $btnCancel.Text = "Abbrechen"
    $btnCancel.Location = New-Object System.Drawing.Point(490, 450)
    $btnCancel.Size = New-Object System.Drawing.Size(100, 35)
    $btnCancel.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $btnCancel.FlatAppearance.BorderSize = 1
    $btnCancel.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(63, 63, 70)
    $btnCancel.BackColor = [System.Drawing.Color]::FromArgb(45, 45, 48)
    $btnCancel.ForeColor = [System.Drawing.Color]::FromArgb(220, 220, 220)
    $btnCancel.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $btnCancel.Add_MouseEnter({ $this.BackColor = [System.Drawing.Color]::FromArgb(55, 55, 58) })
    $btnCancel.Add_MouseLeave({ $this.BackColor = [System.Drawing.Color]::FromArgb(45, 45, 48) })
    $btnCancel.Add_Click({ $settingsForm.Close() })
    $settingsForm.Controls.Add($btnCancel)
    
    # Formular anzeigen
    $settingsForm.ShowDialog()
}

# Funktion zum Speichern der Fenstergröße und -position
function Export-WindowPosition {
    <#
    .SYNOPSIS
        Speichert die aktuelle Fenstergröße und -position
    .DESCRIPTION
        Diese Funktion speichert die aktuelle Fenstergröße und -position in die Einstellungen.
    .PARAMETER MainForm
        Das Hauptformular, dessen Größe und Position gespeichert werden soll
    .PARAMETER ConfigPath
        Der Pfad zur Konfigurationsdatei
    .EXAMPLE
        Export-WindowPosition -MainForm $mainform -ConfigPath "C:\path\to\config.json"
    #>
    param (
        [Parameter(Mandatory = $true)]
        [System.Windows.Forms.Form]$MainForm,
        
        [Parameter(Mandatory = $true)]
        [string]$ConfigPath
    )
    
    $settings = Get-SystemToolSettings
    
    # Aktuelle Fenstergröße und -position speichern, wenn Option aktiviert ist
    if ($settings.SaveWindowSize) {
        Write-Host "Speichere Fenstergröße und -position..." -ForegroundColor Green
        $settings.WindowWidth = $MainForm.Width
        $settings.WindowHeight = $MainForm.Height
        $settings.WindowLeft = $MainForm.Left
        $settings.WindowTop = $MainForm.Top
        Set-SystemToolSettings -Settings $settings
        # Speichere in die Konfigurationsdatei (ohne zusätzliche Konsolenausgabe)
        Export-SystemToolSettings -ConfigPath $ConfigPath -Silent
        
        Write-Host "Fenstergröße und -position wurden gespeichert: $($MainForm.Width)x$($MainForm.Height) an Position $($MainForm.Left),$($MainForm.Top)" -ForegroundColor Green
    }
}

# Export Module Members
Export-ModuleMember -Function Get-SystemToolSettings
Export-ModuleMember -Function Set-SystemToolSettings
Export-ModuleMember -Function Initialize-SystemToolSettings
Export-ModuleMember -Function Import-SystemToolSettings
Export-ModuleMember -Function Export-SystemToolSettings
Export-ModuleMember -Function Update-SystemToolUI
Export-ModuleMember -Function Show-SettingsDialog
Export-ModuleMember -Function Export-WindowPosition
Export-ModuleMember -Function Update-ScanHistory
Export-ModuleMember -Function Get-ScanHistory
Export-ModuleMember -Function Get-ScanStatus



# SIG # Begin signature block
# MIIcSgYJKoZIhvcNAQcCoIIcOzCCHDcCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAPiEflxHFYRmqf
# nwHKnTgTuCToSF4sMgVXvibatrpK36CCFnowggM8MIICJKADAgECAhBJfyGrXBJT
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
# MQ4wDAYKKwYBBAGCNwIBFTAvBgkqhkiG9w0BCQQxIgQg2AozOzYXSG5gjtk/rs8E
# O7Y0hEMAABJSP6wdmRrd2CEwDQYJKoZIhvcNAQEBBQAEggEAZzP7MILo+/ZQAgXJ
# AEoguVWVLkSTJTTaIST3vDmJHV8txuJvoTVZ0/zLl/IEo2Tg6DQeYvdIZoDqiRJ4
# LJQXl86j/66RK/7NQBs/3W5xK23HsYQGB2NFSJc7Qy+s0HoMm7e55U+vu3mOuECq
# y0B0bPM/QcBp3G7fp4nVKnCb4S+vE2rP5az1K4QrnMjI+G+cN45bMv2Q8Do9y238
# sjlbuPSYYlCdxr9j3Uj04mEY53AB5OJPDkD2nJ/VuQthM8CgV5n4sV8SObskW+3d
# B+CZPpxlTZCKKHjzyfOVy62oSlTNb18L2kqbSX1HnulRS54/jTrtkRkFsWARR0QY
# ZA2A5qGCAyYwggMiBgkqhkiG9w0BCQYxggMTMIIDDwIBATB9MGkxCzAJBgNVBAYT
# AlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5jLjFBMD8GA1UEAxM4RGlnaUNlcnQg
# VHJ1c3RlZCBHNCBUaW1lU3RhbXBpbmcgUlNBNDA5NiBTSEEyNTYgMjAyNSBDQTEC
# EAqA7xhLjfEFgtHEdqeVdGgwDQYJYIZIAWUDBAIBBQCgaTAYBgkqhkiG9w0BCQMx
# CwYJKoZIhvcNAQcBMBwGCSqGSIb3DQEJBTEPFw0yNjAxMjAxODAyNTNaMC8GCSqG
# SIb3DQEJBDEiBCBj9Jwx/vnvhF0fQwrvjXamh4J0/t2Rv+TDvk1HSW2N4DANBgkq
# hkiG9w0BAQEFAASCAgDD1oiwHHmpVS2fAvEa1o9nt/UkTZYpgOosRV+AkyQBI/Wq
# ucuTf0Q6hYY5dle5c9+j4QVomWlLUImQkrzJe9yZ6AFWVLVPejhiGGO0qLcmLPFa
# Z6bZl6Gtf4+JcW9ISPY4i7ok12SmVpsYjuRHzcZLNhwDopf9eLYCh1vD3562SHav
# bamH3USsG/eBij1tfvwFmlc9qorcb8t7zj2EphS3TNorGGVbLr73WyVE3odDsiI/
# Z6Ytoptdf2nzEpP7x8kU1T19cjm8G2hpxGeMVrlIydslA2+qV49fAlxZqjZ8tc/A
# 3A5wf6TbCYnObMXAToXlEks+v4vDWsiqucVI3TobeiseDfhX6s2cMifeyBUR2Pof
# NdXDdCLZ501UbcfOK9wclgX03ihMLI9E61lgDYsPig9y1P0QypU7eREz26tdfHn4
# 72qIPRCINOhTsHsDfj1w8tZRXgghKFTZxlYhmmMGtBN36NAc6urmle9fMNoJC4D8
# DQwHYNDTGtdXwcjbVSJ6eUymLbeolTMUDVWl0G9aFGzspzNPR5A0JoH+rWYlqm2V
# xWVDhsK9BPPm3rNIgXMxKmBVWQmA0sp/6OLCAvb0b6rkLrv18fENXq2ZmwXlNVCr
# QPznvHh3zQaJBhPSDNGWKsQgFgsrkWgqn1Fvy4hhyKJZFHw4gk3ftgtn0KRSyQ==
# SIG # End signature block

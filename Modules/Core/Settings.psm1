# Settings.psm1 - Einstellungsmodul für Bocki's System-Tool
# Autor: Bocki

# Globale Variable für die Einstellungen, wird von der Hauptdatei gesetzt
$script:settings = $null

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
        ColorScheme         = "Standard"
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
        LogPath             = "$PSScriptRoot\..\..\Logs"
        ConfirmActions      = $true
        AdvancedCleanup     = $false
        CheckUpdates        = $true
        ShowSplash          = $true
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
            $settingsHashtable = @{}
            foreach ($property in $loadedSettings.PSObject.Properties) {
                $settingsHashtable[$property.Name] = $property.Value
            }
            
            # Setze die Einstellungen
            Set-SystemToolSettings -Settings $settingsHashtable
            
            Write-Host "Einstellungen wurden aus $ConfigPath geladen." -ForegroundColor Green
            return $true
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
    .EXAMPLE
        Export-SystemToolSettings -ConfigPath "C:\path\to\config.json"
    #>
    param (
        [Parameter(Mandatory = $true)]
        [string]$ConfigPath
    )
    
    try {
        $settings = Get-SystemToolSettings
        $settings | ConvertTo-Json | Out-File -FilePath $ConfigPath -Encoding UTF8
        Write-Host "Einstellungen wurden in $ConfigPath gespeichert." -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "Fehler beim Speichern der Einstellungen: $_" -ForegroundColor Red
        return $false
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
            ThemeButton = $themeButton
            TabSystem = $tabSystem
            TabDisk = $tabDisk
            TabNetwork = $tabNetwork
            TabCleanup = $tabCleanup
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
        
        # 2. Farbschema
        if ($null -ne $settings.ColorScheme) {
            $isDarkMode = $UIElements.MainForm.BackColor -eq [System.Drawing.Color]::FromArgb(28, 30, 36)
            
            switch ($settings.ColorScheme) {
                "Dunkel (Dark Mode)" {
                    if (-not $isDarkMode -and $null -ne $UIElements.ThemeButton) {
                        $UIElements.ThemeButton.PerformClick()  # Wechselt zum Dark Mode
                    }
                }
                "Hell (Light Mode)" {
                    if ($isDarkMode -and $null -ne $UIElements.ThemeButton) {
                        $UIElements.ThemeButton.PerformClick()  # Wechselt zum Light Mode
                    }
                }
                "Blau" {
                    # Blaues Farbschema anwenden
                    if ($null -ne $UIElements.MainForm) { $UIElements.MainForm.BackColor = [System.Drawing.Color]::FromArgb(220, 230, 250) }
                    if ($null -ne $UIElements.TabSystem) { $UIElements.TabSystem.BackColor = [System.Drawing.Color]::FromArgb(200, 220, 255) }
                    if ($null -ne $UIElements.TabDisk) { $UIElements.TabDisk.BackColor = [System.Drawing.Color]::FromArgb(210, 225, 250) }
                    if ($null -ne $UIElements.TabNetwork) { $UIElements.TabNetwork.BackColor = [System.Drawing.Color]::FromArgb(220, 230, 245) }
                    if ($null -ne $UIElements.TabCleanup) { $UIElements.TabCleanup.BackColor = [System.Drawing.Color]::FromArgb(230, 235, 240) }
                }
                "Grün" {
                    # Grünes Farbschema anwenden
                    if ($null -ne $UIElements.MainForm) { $UIElements.MainForm.BackColor = [System.Drawing.Color]::FromArgb(230, 245, 230) }
                    if ($null -ne $UIElements.TabSystem) { $UIElements.TabSystem.BackColor = [System.Drawing.Color]::FromArgb(210, 250, 210) }
                    if ($null -ne $UIElements.TabDisk) { $UIElements.TabDisk.BackColor = [System.Drawing.Color]::FromArgb(220, 245, 220) }
                    if ($null -ne $UIElements.TabNetwork) { $UIElements.TabNetwork.BackColor = [System.Drawing.Color]::FromArgb(230, 240, 230) }
                    if ($null -ne $UIElements.TabCleanup) { $UIElements.TabCleanup.BackColor = [System.Drawing.Color]::FromArgb(240, 235, 240) }
                }
            }
        }
        
        # 3. Hardware Monitor Update-Intervall anpassen, falls vorhanden
        if ($null -ne $UIElements.HardwareTimer -and $null -ne $settings.UpdateInterval) {
            $UIElements.HardwareTimer.Interval = [int]$settings.UpdateInterval
        }
        
        # 4. Schwellenwerte für Hardware-Überwachung
        if ($settings.CpuThreshold -ne $null) {
            $script:cpuThreshold = [int]$settings.CpuThreshold
        }
        if ($settings.RamThreshold -ne $null) {
            $script:ramThreshold = [int]$settings.RamThreshold
        }
        if ($settings.GpuThreshold -ne $null) {
            # GPU-Schwellenwert hinzufügen
            $script:gpuThreshold = [int]$settings.GpuThreshold
        }
        
        Write-Host "`r[+] Einstellungen wurden erfolgreich angewendet." -ForegroundColor Green
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
    .PARAMETER ThemeButton
        Der Theme-Button für den Wechsel zwischen Dark Mode und Light Mode
    .PARAMETER TabControl
        Das Tab-Control der Anwendung
    .PARAMETER MainTabControl
        Das Haupt-Tab-Control der Anwendung
    .EXAMPLE
        Show-SettingsDialog -MainForm $mainform -OutputBox $outputBox -ThemeButton $themeButton -TabControl $tabControl -MainTabControl $mainTabControl
    #>
    param (
        [Parameter(Mandatory = $true)]
        [System.Windows.Forms.Form]$MainForm,
        
        [Parameter(Mandatory = $true)]
        [System.Windows.Forms.RichTextBox]$OutputBox,
        
        [Parameter(Mandatory = $true)]
        [System.Windows.Forms.Button]$ThemeButton,
        
        [Parameter(Mandatory = $true)]
        [System.Windows.Forms.TabControl]$TabControl,
        
        [Parameter(Mandatory = $true)]
        [System.Windows.Forms.TabControl]$MainTabControl
    )
    
    # Aktuelle Fenstergröße und -position speichern, wenn eingeschaltet
    $currentWindowWidth = $MainForm.Width
    $currentWindowHeight = $MainForm.Height
    $currentWindowLeft = $MainForm.Left
    $currentWindowTop = $MainForm.Top
    
    # Logik für das Einstellungsmenü
    $settingsForm = New-Object System.Windows.Forms.Form
    $settingsForm.Text = "Einstellungen"
    $settingsForm.Size = New-Object System.Drawing.Size(550, 450)
    $settingsForm.StartPosition = "CenterParent"
    $settingsForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $settingsForm.MaximizeBox = $false
    $settingsForm.MinimizeBox = $false
    
    # Prüfen, ob wir im Dark Mode sind
    $isDarkMode = $MainForm.BackColor -eq [System.Drawing.Color]::FromArgb(28, 30, 36)
    
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
    
    # Wenn die gespeicherte Einstellung in der Liste ist, verwende sie, ansonsten basierend auf dem aktuellen Modus
    if ($cmbColorScheme.Items.Contains($script:settings.ColorScheme)) {
        $cmbColorScheme.SelectedItem = $script:settings.ColorScheme
    } else {
        $cmbColorScheme.SelectedItem = if ($isDarkMode) { "Dunkel (Dark Mode)" } else { "Hell (Light Mode)" }
    }
    
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
    $numUpdateInterval.Value = $script:settings.UpdateInterval  # Aktuelle Einstellung laden
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
    $tabLogs.Controls.Add($txtLogPath)
    
    $btnBrowseLogPath = New-Object System.Windows.Forms.Button
    $btnBrowseLogPath.Text = "..."
    $btnBrowseLogPath.Location = New-Object System.Drawing.Point(410, 100)
    $btnBrowseLogPath.Size = New-Object System.Drawing.Size(30, 25)
    $btnBrowseLogPath.Add_Click({
            $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
            $folderBrowser.Description = "Wählen Sie den Ordner für die Logs aus"
            $folderBrowser.SelectedPath = $txtLogPath.Text
            
            if ($folderBrowser.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
                $txtLogPath.Text = $folderBrowser.SelectedPath
            }
        })
    $tabLogs.Controls.Add($btnBrowseLogPath)
    
    # Tab 4: Verhalten
    $tabBehavior = New-Object System.Windows.Forms.TabPage
    $tabBehavior.Text = "Verhalten"
    $tabBehavior.BackColor = $settingsForm.BackColor
    
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
    $tabSystem_Settings.BackColor = $settingsForm.BackColor
    
    # Windows Defender-Dienste neu starten
    $btnRestartDefenderSettings = New-Object System.Windows.Forms.Button
    $btnRestartDefenderSettings.Text = "Windows Defender-Dienste neu starten"
    $btnRestartDefenderSettings.Location = New-Object System.Drawing.Point(15, 20)
    $btnRestartDefenderSettings.Size = New-Object System.Drawing.Size(250, 30)
    $btnRestartDefenderSettings.Add_Click({
            # Verstecke Einstellungsfenster während der Operation
            $settingsForm.Hide()
            Switch-ToOutputTab -TabControl $TabControl
            $OutputBox.Clear()
            Update-ProgressStatus -StatusText "Windows Defender-Dienst Neustart wird vorbereitet..." -ProgressValue 0 -TextColor ([System.Drawing.Color]::DarkBlue)
            Restart-DefenderService -outputBox $OutputBox -TabControl $TabControl -progressBar $progressBar -MainForm $MainForm
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
            
            # 2. Farbschema
            switch ($script:settings.ColorScheme) {
                "Dunkel (Dark Mode)" {
                    if (-not $isDarkMode) {
                        $ThemeButton.PerformClick()  # Wechselt zum Dark Mode
                    }
                }
                "Hell (Light Mode)" {
                    if ($isDarkMode) {
                        $ThemeButton.PerformClick()  # Wechselt zum Light Mode
                    }
                }
                "Blau" {
                    # Blaues Farbschema anwenden
                    $MainForm.BackColor = [System.Drawing.Color]::FromArgb(220, 230, 250)
                    if ($null -ne $tabSystem) { $tabSystem.BackColor = [System.Drawing.Color]::FromArgb(200, 220, 255) }
                    if ($null -ne $tabDisk) { $tabDisk.BackColor = [System.Drawing.Color]::FromArgb(210, 225, 250) }
                    if ($null -ne $tabNetwork) { $tabNetwork.BackColor = [System.Drawing.Color]::FromArgb(220, 230, 245) }
                    if ($null -ne $tabCleanup) { $tabCleanup.BackColor = [System.Drawing.Color]::FromArgb(230, 235, 240) }
                }
                "Grün" {
                    # Grünes Farbschema anwenden
                    $MainForm.BackColor = [System.Drawing.Color]::FromArgb(230, 245, 230)
                    if ($null -ne $tabSystem) { $tabSystem.BackColor = [System.Drawing.Color]::FromArgb(210, 250, 210) }
                    if ($null -ne $tabDisk) { $tabDisk.BackColor = [System.Drawing.Color]::FromArgb(220, 245, 220) }
                    if ($null -ne $tabNetwork) { $tabNetwork.BackColor = [System.Drawing.Color]::FromArgb(230, 240, 230) }
                    if ($null -ne $tabCleanup) { $tabCleanup.BackColor = [System.Drawing.Color]::FromArgb(240, 235, 240) }
                }
            }
            
            # 3. Hardware Monitor Update-Intervall anpassen, falls vorhanden
            if ($null -ne $script:hardwareTimer) {
                $script:hardwareTimer.Interval = [int]$script:settings.UpdateInterval
            }
            
            # 4. Schwellenwerte für Hardware-Überwachung
            $script:cpuThreshold = [int]$script:settings.CpuThreshold
            $script:ramThreshold = [int]$script:settings.RamThreshold
            $script:gpuThreshold = [int]$script:settings.GpuThreshold
            
            # Einstellungen in Konfigurationsdatei speichern
            $settingsFilePath = "$PSScriptRoot\..\..\config.json"
            try {
                $script:settings | ConvertTo-Json | Out-File -FilePath $settingsFilePath -Encoding UTF8
            }
            catch {
                Write-Host "Fehler beim Speichern der Einstellungen: $_" -ForegroundColor Red
            }
            
            # Ausgabe in der OutputBox
            $OutputBox.SelectionColor = [System.Drawing.Color]::Green
            $OutputBox.AppendText("`r`nEinstellungen wurden aktualisiert und angewendet:`r`n")
            $OutputBox.SelectionColor = [System.Drawing.Color]::Black
            $OutputBox.AppendText("- Schriftgröße: $($script:settings.FontSize)`r`n")
            $OutputBox.AppendText("- Farbschema: $($script:settings.ColorScheme)`r`n")
            $OutputBox.AppendText("- Update-Intervall: $($script:settings.UpdateInterval) ms`r`n")
            $OutputBox.AppendText("- CPU-Warnschwelle: $($script:settings.CpuThreshold)%`r`n")
            $OutputBox.AppendText("- RAM-Warnschwelle: $($script:settings.RamThreshold)%`r`n")
            $OutputBox.AppendText("- GPU-Warnschwelle: $($script:settings.GpuThreshold)%`r`n")
            $OutputBox.AppendText("- Log-Level: $($script:settings.LogLevel)`r`n")
            $OutputBox.AppendText("- Einstellungen wurden in $settingsFilePath gespeichert.`r`n")
            
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
          # Speichere in die Konfigurationsdatei
        Export-SystemToolSettings -ConfigPath $ConfigPath
        
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
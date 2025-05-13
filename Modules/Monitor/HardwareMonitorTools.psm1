# HardwareMonitorTools.psm1
# Modul für Hardware-Überwachung und Monitoring-Funktionen

# Importiere Module
Import-Module "$PSScriptRoot\..\Core\Core.psm1" -Force
Import-Module "$PSScriptRoot\..\Core\ProgressBarTools.psm1" -Force

# Importiere erforderliche Assemblies
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

#region Globale Variablen

# Globale Variablen für Hardware-Monitoring
$script:computerObj = $null
$script:useLibreHardware = $false
$script:hardwareTimer = $null
$script:wmiSensors = $null
$script:lastRamTemp = $null
$script:isUpdating = $false
$script:tooltipControl = $null
$script:gpuName = $null

# Neue Cache-Variablen für verbesserte Performance
$script:ramCache = $null
$script:lastGpuCounterUpdate = $null
$script:lastGpuCounterValue = $null
$script:updateCounter = 0

# Statistik-Tracking für Min/Max/Durchschnitt
$script:cpuStats = @{}
$script:gpuStats = @{}
$script:ramStats = @{}

# Automatische Zurücksetzung der Statistiken nach X Stunden
$script:statsResetInterval = [TimeSpan]::FromHours(24)

# Corsair iCUE Integration - Pfad zur SDK DLL definieren (muss installiert sein)
$script:iCUESDKPath = Join-Path -Path ${env:ProgramFiles(x86)} -ChildPath "Corsair\CORSAIR iCUE Software\SDK\bin\CUESDK.x64_2019.dll"
$script:useICUE = $false
$script:icueInitialized = $false

#endregion

#region Debug-Funktionalität

# Debug-Zeitstempel
$script:lastCPUDebugOutput = [DateTime]::MinValue
$script:lastGPUDebugOutput = [DateTime]::MinValue
$script:lastRAMDebugOutput = [DateTime]::MinValue
$script:debugUpdateInterval = [TimeSpan]::FromSeconds(2)  # Sensor-Update alle 2 Sekunden

# Globale Variable für Debug-Modus
$script:DebugMode = $false

# Globale Debug-Variablen für einzelne Komponenten
$script:DebugModeCPU = $false
$script:DebugModeGPU = $false
$script:DebugModeRAM = $false

# Neue Variablen für Hardware-Info-Status
$script:cpuInfoShown = $false
$script:gpuInfoShown = $false
$script:ramInfoShown = $false

function Write-DebugOutput {
    param(
        [string]$Message,
        [ValidateSet('CPU', 'GPU', 'RAM')]
        [string]$Component,
        [switch]$Force
    )
    
    # Prüfen ob Debug für die spezifische Komponente aktiviert ist
    $isDebugEnabled = switch ($Component) {
        'CPU' { $script:DebugModeCPU }
        'GPU' { $script:DebugModeGPU }
        'RAM' { $script:DebugModeRAM }
        default { $false }
    }
    
    if ($isDebugEnabled -or $Force) {
        $now = Get-Date
        $lastOutput = switch ($Component) {
            'CPU' { $script:lastCPUDebugOutput }
            'GPU' { $script:lastGPUDebugOutput }
            'RAM' { $script:lastRAMDebugOutput }
        }

        if ($Force -or ($now - $lastOutput) -gt $script:debugUpdateInterval) {
            Write-Host "[$Component] $Message" -ForegroundColor $(
                switch ($Component) {
                    'CPU' { 'Cyan' }
                    'GPU' { 'Green' }
                    'RAM' { 'Yellow' }
                    default { 'White' }
                }
            )

            # Aktualisiere den Zeitstempel
            switch ($Component) {
                'CPU' { $script:lastCPUDebugOutput = $now }
                'GPU' { $script:lastGPUDebugOutput = $now }
                'RAM' { $script:lastRAMDebugOutput = $now }
            }
        }
    }
}

function Write-HardwareInfo {
    param(
        [ValidateSet('CPU', 'GPU', 'RAM')]
        [string]$Component
    )

    switch ($Component) {
        'CPU' {
            if (-not $script:cpuInfoShown) {
                $cpuWmi = Get-WmiObject -Class Win32_Processor | Select-Object -First 1
                Write-Host "`n[CPU] === Hardware Information ===" -ForegroundColor Cyan
                Write-Host "[CPU] Name: $($cpuWmi.Name)" -ForegroundColor Cyan
                Write-Host "[CPU] Hersteller: $($cpuWmi.Manufacturer)" -ForegroundColor Cyan
                Write-Host "[CPU] Kerne: $($cpuWmi.NumberOfCores)" -ForegroundColor Cyan
                Write-Host "[CPU] Logische Prozessoren: $($cpuWmi.NumberOfLogicalProcessors)" -ForegroundColor Cyan
                Write-Host "[CPU] Basis Taktrate: $($cpuWmi.MaxClockSpeed) MHz" -ForegroundColor Cyan
                Write-Host "[CPU] ===========================" -ForegroundColor Cyan
                $script:cpuInfoShown = $true
            }
        }
        'GPU' {
            if (-not $script:gpuInfoShown) {
                $gpuWmi = Get-WmiObject -Class Win32_VideoController | Where-Object { $_.Name -match "NVIDIA|AMD|Radeon|GeForce|Intel.*Graphics" }
                Write-Host "`n[GPU] === Hardware Information ===" -ForegroundColor Green
                foreach ($gpu in $gpuWmi) {
                    Write-Host "[GPU] Name: $($gpu.Name)" -ForegroundColor Green
                    Write-Host "[GPU] Treiber Version: $($gpu.DriverVersion)" -ForegroundColor Green
                    Write-Host "[GPU] Video RAM: $([math]::Round($gpu.AdapterRAM/1GB, 2)) GB" -ForegroundColor Green
                    Write-Host "[GPU] Maximale Auflösung: $($gpu.MaxRefreshRate) Hz @ $($gpu.VideoModeDescription)" -ForegroundColor Green
                }
                Write-Host "[GPU] ===========================" -ForegroundColor Green
                $script:gpuInfoShown = $true
            }
        }
        'RAM' {
            if (-not $script:ramInfoShown) {
                $ramInfo = Get-WmiObject -Class Win32_PhysicalMemory
                Write-Host "`n[RAM] === Hardware Information ===" -ForegroundColor Yellow
                Write-Host "[RAM] Anzahl RAM-Module: $($ramInfo.Count)" -ForegroundColor Yellow
                foreach ($module in $ramInfo) {
                    Write-Host "[RAM] -------------------" -ForegroundColor Yellow
                    Write-Host "[RAM] Hersteller: $($module.Manufacturer)" -ForegroundColor Yellow
                    Write-Host "[RAM] Teilenummer: $($module.PartNumber)" -ForegroundColor Yellow
                    Write-Host "[RAM] Kapazität: $([math]::Round($module.Capacity/1GB, 2)) GB" -ForegroundColor Yellow
                    Write-Host "[RAM] Nominale Geschwindigkeit: $($module.Speed) MHz" -ForegroundColor Yellow
                    Write-Host "[RAM] Form Factor: $($module.FormFactor)" -ForegroundColor Yellow
                }
                $computerSystem = Get-WmiObject -Class Win32_ComputerSystem
                $totalRAM = [math]::Round($computerSystem.TotalPhysicalMemory / 1GB, 2)
                Write-Host "[RAM] -------------------" -ForegroundColor Yellow
                Write-Host "[RAM] Gesamter RAM: $totalRAM GB" -ForegroundColor Yellow
                Write-Host "[RAM] ===========================" -ForegroundColor Yellow
                $script:ramInfoShown = $true
            }
        }
    }
}

function Write-SensorInfo {
    param(
        [ValidateSet('CPU', 'GPU', 'RAM')]
        [string]$Component,
        [hashtable]$SensorData
    )

    $color = switch ($Component) {
        'CPU' { 'Cyan' }
        'GPU' { 'Green' }
        'RAM' { 'Yellow' }
    }

    Write-Host "[$Component] === Aktuelle Sensor-Werte ===" -ForegroundColor $color
    foreach ($key in $SensorData.Keys) {
        Write-Host "[$Component] $key : $($SensorData[$key])" -ForegroundColor $color
    }
    Write-Host "[$Component] ===========================" -ForegroundColor $color
}

function Reset-HardwareInfoStatus {
    param(
        [ValidateSet('CPU', 'GPU', 'RAM')]
        [string]$Component
    )
    
    switch ($Component) {
        'CPU' { $script:cpuInfoShown = $false }
        'GPU' { $script:gpuInfoShown = $false }
        'RAM' { $script:ramInfoShown = $false }
    }
}

# Funktion zum Aktivieren/Deaktivieren des Debug-Modus
function Set-HardwareMonitorDebugMode {
    param(
        [bool]$Enabled
    )
    
    $script:DebugMode = $Enabled
    $script:DebugModeCPU = $Enabled
    $script:DebugModeGPU = $Enabled
    $script:DebugModeRAM = $Enabled
    
    $statusText = if ($Enabled) { "Aktiviert" } else { "Deaktiviert" }
    Write-Host "Hardware Monitor Debug-Modus: $statusText"
}

function Set-HardwareDebugMode {
    param(
        [ValidateSet('CPU', 'GPU', 'RAM')]
        [string]$Component,
        [bool]$Enabled
    )
    
    switch ($Component) {
        'CPU' {
            $script:DebugModeCPU = $Enabled
            $statusText = if ($Enabled) { "Aktiviert" } else { "Deaktiviert" }
            Write-Host "CPU Debug-Modus: $statusText"
        }
        'GPU' {
            $script:DebugModeGPU = $Enabled
            $statusText = if ($Enabled) { "Aktiviert" } else { "Deaktiviert" }
            Write-Host "GPU Debug-Modus: $statusText"
        }
        'RAM' {
            $script:DebugModeRAM = $Enabled
            $statusText = if ($Enabled) { "Aktiviert" } else { "Deaktiviert" }
            Write-Host "RAM Debug-Modus: $statusText"
        }
    }
}

function Get-WarningColor {
    param (
        [Parameter(Mandatory = $false)]
        [double]$Temperature = 0,
        
        [Parameter(Mandatory = $false)]
        [double]$Load = 0,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet('CPU', 'GPU', 'RAM')]
        [string]$Component = '',
        
        [Parameter(Mandatory = $false)]
        [double[]]$TempThresholds = @(70, 85),
        
        [Parameter(Mandatory = $false)]
        [double[]]$LoadThresholds = @(80, 95)
    )
    
    # Komponenten-spezifische Schwellenwerte
    if ($Component -eq 'CPU') {
        $TempThresholds = @(75, 90)
        $LoadThresholds = @(85, 95)
    }
    elseif ($Component -eq 'GPU') {
        $TempThresholds = @(75, 90)
        $LoadThresholds = @(85, 95)
    }
    elseif ($Component -eq 'RAM') {
        $TempThresholds = @(60, 80)  # RAM hat in der Regel niedrigere Temperatur-Schwellenwerte
        $LoadThresholds = @(90, 97)  # RAM kann hohe Auslastung besser verkraften
    }
    
    # Hintergrundfarbberechnung
    if ($Temperature -ge $TempThresholds[1] -or $Load -ge $LoadThresholds[1]) {
        # Kritischer Bereich (rot)
        return [System.Drawing.Color]::LightCoral
    }
    elseif ($Temperature -ge $TempThresholds[0] -or $Load -ge $LoadThresholds[0]) {
        # Warnbereich (gelb)
        return [System.Drawing.Color]::LightYellow
    }
    else {
        # Normaler Bereich (grün)
        return [System.Drawing.Color]::LightGreen
    }
}

#endregion

#region UI und Monitoring-Steuerung

function New-MonitoringPanel {
    param (
        [System.Windows.Forms.Form]$ParentForm,
        [int]$X,
        [int]$Y,
        [int]$Width,
        [int]$Height,
        [string]$LabelText
    )
    
    # Panel erstellen
    $panel = New-Object System.Windows.Forms.Panel
    $panel.Location = New-Object System.Drawing.Point($X, $Y)
    $panel.Size = New-Object System.Drawing.Size($Width, $Height)
    $panel.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
    $panel.Cursor = [System.Windows.Forms.Cursors]::Hand  # Mauszeiger ändern, um Interaktivität anzudeuten
    $ParentForm.Controls.Add($panel)
    
    # Label erstellen mit größerer Schrift
    $label = New-Object System.Windows.Forms.Label
    $label.Text = $LabelText
    $label.Location = New-Object System.Drawing.Point($X, $Y + $Height + 5)
    $label.Size = New-Object System.Drawing.Size($Width, 25)  # Größer für die größere Schrift
    $label.Font = New-Object System.Drawing.Font("Segoe UI", 13, [System.Drawing.FontStyle]::Bold)  # Von 10 auf 13 erhöht
    $label.Cursor = [System.Windows.Forms.Cursors]::Hand  # Mauszeiger ändern, um Interaktivität anzudeuten
    $ParentForm.Controls.Add($label)
    
    return @{
        Panel = $panel
        Label = $label
    }
}

function Initialize-LiveMonitoring {
    param (
        [System.Windows.Forms.Label]$cpuLabel,
        [System.Windows.Forms.Label]$gpuLabel,
        [System.Windows.Forms.Label]$ramLabel,
        [System.Windows.Forms.Panel]$gbCPU,
        [System.Windows.Forms.Panel]$gbGPU,
        [System.Windows.Forms.Panel]$gbRAM
    )

    try {
        # Überprüfen und Initialisieren von LibreHardwareMonitor
        if ($null -eq $script:computerObj -or -not $script:useLibreHardware) {
            $script:computerObj = Initialize-LibreHardwareMonitor
            if ($null -eq $script:computerObj) {
                Write-Warning "LibreHardwareMonitor konnte nicht initialisiert werden!"
                return $null
            }
            $script:useLibreHardware = $true
        }

        # Tooltip für Hardware-Statistiken neu initialisieren
        $tooltip = New-Object System.Windows.Forms.ToolTip
        $tooltip.AutoPopDelay = 15000  # 15 Sekunden anzeigen
        $tooltip.InitialDelay = 100    # Schnellere Verzögerung
        $tooltip.ReshowDelay = 100     # Schnellere Verzögerung
        $tooltip.Active = $true
        $tooltip.IsBalloon = $true     # Balloon-Stil für bessere Sichtbarkeit
        $script:tooltipControl = $tooltip

        # Event-Handler für CPU-Label und Panel
        if ($cpuLabel) {
            $cpuLabel.Add_Click({
                    [System.Windows.Forms.MessageBox]::Show(
                    (Get-HardwareStatsTooltip -Component 'CPU'),
                        "CPU Statistik",
                        [System.Windows.Forms.MessageBoxButtons]::OK,
                        [System.Windows.Forms.MessageBoxIcon]::Information
                    )
                })
        }
        
        if ($gbCPU) {
            $gbCPU.Add_Click({
                    [System.Windows.Forms.MessageBox]::Show(
                    (Get-HardwareStatsTooltip -Component 'CPU'),
                        "CPU Statistik",
                        [System.Windows.Forms.MessageBoxButtons]::OK,
                        [System.Windows.Forms.MessageBoxIcon]::Information
                    )
                })
        }

        # Event-Handler für GPU-Label und Panel
        if ($gpuLabel) {
            $gpuLabel.Add_Click({
                    [System.Windows.Forms.MessageBox]::Show(
                    (Get-HardwareStatsTooltip -Component 'GPU'),
                        "GPU Statistik",
                        [System.Windows.Forms.MessageBoxButtons]::OK,
                        [System.Windows.Forms.MessageBoxIcon]::Information
                    )
                })
        }
        
        if ($gbGPU) {
            $gbGPU.Add_Click({
                    [System.Windows.Forms.MessageBox]::Show(
                    (Get-HardwareStatsTooltip -Component 'GPU'),
                        "GPU Statistik",
                        [System.Windows.Forms.MessageBoxButtons]::OK,
                        [System.Windows.Forms.MessageBoxIcon]::Information
                    )
                })
        }

        # Event-Handler für RAM-Label und Panel
        if ($ramLabel) {
            $ramLabel.Add_Click({
                    [System.Windows.Forms.MessageBox]::Show(
                    (Get-HardwareStatsTooltip -Component 'RAM'),
                        "RAM Statistik",
                        [System.Windows.Forms.MessageBoxButtons]::OK,
                        [System.Windows.Forms.MessageBoxIcon]::Information
                    )
                })
        }
        
        if ($gbRAM) {
            $gbRAM.Add_Click({
                    [System.Windows.Forms.MessageBox]::Show(
                    (Get-HardwareStatsTooltip -Component 'RAM'),
                        "RAM Statistik",
                        [System.Windows.Forms.MessageBoxButtons]::OK,
                        [System.Windows.Forms.MessageBoxIcon]::Information
                    )
                })
        }

        # Timer erstellen
        $timer = New-Object System.Windows.Forms.Timer
        $timer.Interval = 2000  # Auf 2 Sekunden erhöht für bessere Performance
        $script:hardwareTimer = $timer  # Timer global speichern

        # Initialen GPU-Namen setzen
        try {
            $gpuControllers = Get-WmiObject -Namespace "root\CIMV2" -Class "Win32_VideoController" | 
            Where-Object { $_.Name -match "NVIDIA|AMD|Radeon|GeForce|Intel.*Graphics" }
            
            if ($gpuControllers -and $gbGPU) {
                $gpuName = $gpuControllers[0].Name
                $lblGPUTitle = $gbGPU.Controls | Where-Object { $_ -is [System.Windows.Forms.Label] } | Select-Object -First 1
                if ($lblGPUTitle) {
                    $lblGPUTitle.Text = "GPU: $gpuName"
                    $lblGPUTitle.Refresh()
                }
            }
        }
        catch {
            Write-Warning "Fehler beim initialen GPU-Namen-Setup: $_"
        }

        # Zähler für alternierende Updates (nicht jedes Mal alles aktualisieren)
        $script:updateCounter = 0

        # Event-Handler für Timer
        $timer.Add_Tick({
                # Wenn bereits ein Update läuft, überspringen
                if ($script:isUpdating) { return }
                $script:isUpdating = $true
                
                # Zähler erhöhen
                $script:updateCounter++

                try {
                    if ($null -ne $script:computerObj) {
                        # Hardware nur alle 2 Zyklen aktualisieren
                        if ($script:updateCounter % 2 -eq 0) {
                            $script:computerObj.Hardware | ForEach-Object { $_.Update() }
                        }
                        
                        # CPU immer aktualisieren (wenig Aufwand)
                        Update-CpuInfo -CpuLabel $cpuLabel -Panel $gbCPU
                        
                        # GPU und RAM abwechselnd aktualisieren
                        if ($script:updateCounter % 2 -eq 0 -and $gpuLabel -and $gbGPU) {
                            Update-GpuInfo -GpuLabel $gpuLabel -Panel $gbGPU
                        }
                        elseif ($script:updateCounter % 2 -eq 1) {
                            Update-RamInfo -RamLabel $ramLabel -Panel $gbRAM
                        }
                        
                        # Zähler zurücksetzen nach 10 Durchläufen
                        if ($script:updateCounter -ge 10) {
                            $script:updateCounter = 0
                        }
                    }
                }
                catch {
                    Write-Warning "Fehler beim Hardware-Update: $_"
                }
                finally {
                    $script:isUpdating = $false
                }
            })

        return $timer
    }
    catch {
        Write-Warning "Fehler beim Initialisieren des Live-Monitorings: $_"
        return $null
    }
}

function Initialize-LibreHardwareMonitor {
    # Wenn bereits initialisiert, Computer-Objekt zurückgeben
    if ($null -ne $script:computerObj -and $script:useLibreHardware) {
        return $script:computerObj
    }

    # Verschiedene mögliche Pfade zur DLL prüfen
    $possiblePaths = @(
        (Join-Path -Path $PSScriptRoot -ChildPath "..\Lib\LibreHardwareMonitorLib.dll"),
        (Join-Path -Path $PSScriptRoot -ChildPath "..\..\Lib\LibreHardwareMonitorLib.dll"),
        (Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "Lib\LibreHardwareMonitorLib.dll"),
        (Join-Path -Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) -ChildPath "Lib\LibreHardwareMonitorLib.dll")
    )
    
    $libPath = $null
    foreach ($path in $possiblePaths) {
        if (Test-Path $path) {
            $libPath = $path
            break
        }
    }
    
    try {
        if ($libPath -and (Test-Path $libPath)) {
            # Versuche die DLL zu laden, ignoriere Fehler wenn sie bereits geladen ist
            try {
                Add-Type -Path $libPath -ErrorAction SilentlyContinue
            }
            catch {
                if (-not $_.Exception.Message.Contains("bereits geladen")) {
                    Write-Warning "Fehler beim Laden der DLL: $_"
                    return $null
                }
            }

            $script:computerObj = New-Object LibreHardwareMonitor.Hardware.Computer
            
            # Hardware-Funktionen aktivieren
            $script:computerObj.IsCpuEnabled = $true
            $script:computerObj.IsGpuEnabled = $true
            $script:computerObj.IsMotherboardEnabled = $true
            $script:computerObj.IsMemoryEnabled = $true
            $script:computerObj.IsStorageEnabled = $false
            $script:computerObj.IsNetworkEnabled = $false
            $script:computerObj.IsControllerEnabled = $false
            
            $script:computerObj.Open()
            $script:useLibreHardware = $true
            
            return $script:computerObj
        }
        else {
            Write-Warning "LibreHardwareMonitorLib.dll nicht gefunden in: $libPath"
            return $null
        }
    }
    catch {
        Write-Warning "Fehler beim Initialisieren von LibreHardwareMonitor: $_"
        return $null
    }
}

# Funktion zum Starten des Monitorings
function Start-HardwareMonitoring {
    if ($null -eq $script:hardwareTimer) {
        Write-Warning "Timer nicht initialisiert"
        return $false
    }
    
    if (-not $script:hardwareTimer.Enabled) {
        $script:hardwareTimer.Start()
        return $true
    }
    
    return $true
}

# Funktion zum Stoppen des Monitorings
function Stop-HardwareMonitoring {
    if ($null -ne $script:hardwareTimer -and $script:hardwareTimer.Enabled) {
        $script:hardwareTimer.Stop()
        return $true
    }
    return $false
}

# Funktion zum Aufräumen der Ressourcen
function Clear-HardwareMonitoring {
    try {
        # Zuerst das Monitoring stoppen
        Stop-HardwareMonitoring
        
        # Timer freigeben
        if ($null -ne $script:hardwareTimer) {
            if ($script:hardwareTimer.Enabled) {
                $script:hardwareTimer.Stop()
            }
            $script:hardwareTimer.Dispose()
            $script:hardwareTimer = $null
        }
        
        # Computer-Objekt freigeben
        if ($null -ne $script:computerObj) {
            try {
                $script:computerObj.Close()
            }
            catch {
                Write-Warning "Fehler beim Schließen des Computer-Objekts: $_"
            }
            $script:computerObj = $null
            $script:useLibreHardware = $false
        }
        
        # WMI-Sensoren freigeben
        if ($null -ne $script:wmiSensors) {
            $script:wmiSensors = $null
        }
        
        # Garbage Collection erzwingen
        [System.GC]::Collect()
        [System.GC]::WaitForPendingFinalizers()
        
        Write-Host "Hardware-Monitoring-Ressourcen freigegeben"
    }
    catch {
        Write-Warning "Fehler beim Aufräumen der Hardware-Monitoring-Ressourcen: $_"
    }
}

# Neue Funktion zur Abfrage des Hardware-Timer-Status
function Get-HardwareTimerStatus {
    return [PSCustomObject]@{
        Exists  = $null -ne $script:hardwareTimer
        Running = $null -ne $script:hardwareTimer -and $script:hardwareTimer.Enabled
    }
}

# Neue Funktion zur Initialisierung des Timers hinzufügen
function Initialize-HardwareMonitoring {
    param (
        [System.Windows.Forms.Label]$cpuLabel,
        [System.Windows.Forms.Label]$gpuLabel,
        [System.Windows.Forms.Label]$ramLabel,
        [System.Windows.Forms.Panel]$gbCPU,
        [System.Windows.Forms.Panel]$gbGPU,
        [System.Windows.Forms.Panel]$gbRAM,
        [switch]$SuppressVisualFeedback,
        [switch]$WaitForGuiLoaded,
        [int]$LoadDelayMs = 0
    )
    
    # Farbdefinitionen für Ladevisualisierung
    $primaryColor = [System.ConsoleColor]::Cyan
    $secondaryColor = [System.ConsoleColor]::Yellow
    $accentColor = [System.ConsoleColor]::Green
    
    if (-not $SuppressVisualFeedback) {
        Write-Host "`n[+]Hardware-Monitore werden initialisiert..." -ForegroundColor $accentColor
        write-host
        # Fortschrittsbalken initial anzeigen
        $barLength = 20
        $progressBar = "".PadRight($barLength, '░')
        # Verwende eine andere Methode zum Löschen der Zeile
        Write-Host -NoNewline "`r$(" " * 100)"
        Write-Host "`r[" -NoNewline -ForegroundColor $primaryColor
        Write-Host $progressBar -NoNewline -ForegroundColor $secondaryColor
        Write-Host "]" -NoNewline -ForegroundColor $primaryColor
        Write-Host " 0% | Initialisierung..." -NoNewline -ForegroundColor $accentColor
    }
    
    # Hardware-Komponenten initialisieren
    $hardwareComponents = @(
        @{Name = "LibreHardwareMonitor-Bibliothek"; Progress = 10 },
        @{Name = "CPU-Monitor"; Progress = 25 },
        @{Name = "GPU-Monitor"; Progress = 40 },
        @{Name = "RAM-Monitor"; Progress = 55 },
        @{Name = "Statistik-System"; Progress = 70 },
        @{Name = "Timer-Setup"; Progress = 85 }
    )
    
    # Zusätzlichen Eintrag hinzufügen, wenn auf GUI-Ladevorgang gewartet werden soll
    if ($WaitForGuiLoaded) {
        $hardwareComponents += @{Name = "GUI-Synchronisierung"; Progress = 100 }
    }
    
    $timerStatus = Get-HardwareTimerStatus
    if (-not $timerStatus.Exists) {
        # Hardware-Komponenten nacheinander initialisieren
        foreach ($component in $hardwareComponents) {
            if (-not $SuppressVisualFeedback) {
                # Fortschritt berechnen und anzeigen
                $percentComplete = $component.Progress
                $filledLength = [math]::Floor(($percentComplete / 100) * $barLength)
                $progressBar = "".PadLeft($filledLength, '█').PadRight($barLength, '░')
                
                # Verwende eine andere Methode zum Löschen der Zeile
                Write-Host -NoNewline "`r$(" " * 100)"
                
                # Zeige den Fortschrittsbalken an
                Write-Host "`r[" -NoNewline -ForegroundColor $primaryColor
                Write-Host $progressBar -NoNewline -ForegroundColor $secondaryColor
                Write-Host "]" -NoNewline -ForegroundColor $primaryColor
                
                # Zeige Prozent und Komponentenname in einem separaten Bereich an
                $componentInfo = " $percentComplete% | Lade: "
                # Kürze den Komponentennamen wenn nötig
                $displayComponent = if ($component.Name.Length -gt 25) { $component.Name.Substring(0, 22) + "..." } else { $component.Name }
                Write-Host "$componentInfo$displayComponent" -NoNewline -ForegroundColor $accentColor
            }
            
            # Bei CPU, GPU und RAM tatsächlich die entsprechenden Initialisierungsschritte durchführen
            switch ($component.Name) {
                "LibreHardwareMonitor-Bibliothek" {
                    $script:computerObj = Initialize-LibreHardwareMonitor
                    if ($null -eq $script:computerObj) {
                        Write-Warning "LibreHardwareMonitor konnte nicht initialisiert werden!"
                        return $false
                    }
                    $script:useLibreHardware = $true
                    Start-Sleep -Milliseconds 200
                }
                "CPU-Monitor" {
                    if ($cpuLabel -and $gbCPU) {
                        # CPU-Panel zurücksetzen
                        $gbCPU.BackColor = [System.Drawing.Color]::LightGray
                        $cpuLabel.Text = "CPU-Daten werden geladen..."
                    }
                    Start-Sleep -Milliseconds 200
                }
                "GPU-Monitor" {
                    if ($gpuLabel -and $gbGPU) {
                        # GPU-Panel zurücksetzen
                        $gbGPU.BackColor = [System.Drawing.Color]::LightGray
                        $gpuLabel.Text = "GPU-Daten werden geladen..."
                    }
                    Start-Sleep -Milliseconds 200
                }
                "RAM-Monitor" {
                    if ($ramLabel -and $gbRAM) {
                        # RAM-Panel zurücksetzen
                        $gbRAM.BackColor = [System.Drawing.Color]::LightGray
                        $ramLabel.Text = "RAM-Daten werden geladen..."
                    }
                    Start-Sleep -Milliseconds 200
                }
                "Statistik-System" {
                    # Statistik-Tracking zurücksetzen
                    $script:cpuStats.LastReset = (Get-Date)
                    $script:gpuStats.LastReset = (Get-Date)
                    $script:ramStats.LastReset = (Get-Date)
                    Start-Sleep -Milliseconds 200
                }
                "Timer-Setup" {
                    # Eigentliche Initialisierung des Monitorings durchführen
                    $script:hardwareTimer = Initialize-LiveMonitoring `
                        -cpuLabel $cpuLabel `
                        -gpuLabel $gpuLabel `
                        -ramLabel $ramLabel `
                        -gbCPU $gbCPU `
                        -gbGPU $gbGPU `
                        -gbRAM $gbRAM
                    
                    Start-Sleep -Milliseconds 200
                }
                "GUI-Synchronisierung" {
                    if ($WaitForGuiLoaded) {
                        if (-not $SuppressVisualFeedback) {
                            Write-Host
                            Write-Host "`r`n`t├─ Warte auf vollständiges Laden der GUI..." -ForegroundColor $accentColor
                        }
                        
                        # Warten mit Fortschrittsanzeige
                        $spinChars = '|', '/', '-', '\'
                        $spinIndex = 0
                        $waitDuration = [Math]::Max($LoadDelayMs, 2000)  # Mindestens 2 Sekunden warten
                        $startTime = Get-Date
                        $endTime = $startTime.AddMilliseconds($waitDuration)
                        
                        while ((Get-Date) -lt $endTime) {
                            if (-not $SuppressVisualFeedback) {
                                $timeLeft = [Math]::Round(($endTime - (Get-Date)).TotalSeconds)
                                $spinChar = $spinChars[$spinIndex % $spinChars.Length]
                                # Verwende eine andere Methode zum Löschen der Zeile
                                Write-Host -NoNewline "`r$(" " * 100)"
                                Write-Host "`r[$spinChar] Synchronisierung läuft... (noch $timeLeft Sekunden)" -NoNewline -ForegroundColor $accentColor
                                $spinIndex++
                            }
                            Start-Sleep -Milliseconds 100
                            
                            # Kurze Pause für UI-Updates
                            [System.Windows.Forms.Application]::DoEvents()
                        }
                        
                        if (-not $SuppressVisualFeedback) {
                            Write-Host -NoNewline "`r$(" " * 100)"
                            Write-Host "`r`t├─ GUI-Synchronisierung abgeschlossen." -ForegroundColor $accentColor
                        }
                    }
                }
            }
        }
        
        if (-not $SuppressVisualFeedback) {
            Write-Host -NoNewline "`r$(" " * 100)"
            Write-Host "`r`t└─ Hardware-Monitoring erfolgreich initialisiert!" -ForegroundColor $accentColor
            Write-Host "`n" + ("═" * 70) -ForegroundColor Cyan
        }
        
        $timerStatus = Get-HardwareTimerStatus
        if (-not $timerStatus.Exists) {
            Write-Warning "`r`t[i]Hardware-Timer konnte nicht initialisiert werden!" -ForegroundColor Red
            return $false
        }
        elseif (-not $timerStatus.Running) {
            $null = Start-HardwareMonitoring
        }
    }
    
    return $true
}

#endregion

#region CPU Funktionen

function Update-CpuInfo {
    param (
        [System.Windows.Forms.Label]$CpuLabel,
        [System.Windows.Forms.Panel]$Panel
    )
    
    try {
        if (-not $script:useLibreHardware -or $null -eq $script:computerObj) {
            Write-DebugOutput -Component 'CPU' -Message "LibreHardwareMonitor nicht initialisiert" -Force
            return
        }
        
        $cpuName = $script:computerObj.Hardware | Where-Object { $_.HardwareType -eq "Cpu" } | Select-Object -First 1
        
        if (-not $cpuName) {
            Write-DebugOutput -Component 'CPU' -Message "Keine CPU-Hardware gefunden" -Force
            return
        }
        
        # Debug-Ausgabe der Hardware-Info nur bei Bedarf
        if ($script:DebugModeCPU -and -not $script:cpuInfoShown) {
            Write-HardwareInfo -Component 'CPU'
        }
        
        $tempSensor = $cpuName.Sensors | Where-Object { $_.SensorType -eq "Temperature" -and $_.Name -match "Core \(Tctl/Tdie\)|Core Average|Package" } | Select-Object -First 1
        $loadSensor = $cpuName.Sensors | Where-Object { $_.SensorType -eq "Load" -and $_.Name -eq "CPU Total" } | Select-Object -First 1
        $powerSensor = $cpuName.Sensors | Where-Object { $_.SensorType -eq "Power" -and $_.Name -match "Package|CPU Package" } | Select-Object -First 1
        $clockSensor = $cpuName.Sensors | Where-Object { $_.SensorType -eq "Clock" -and $_.Name -match "Core \(Average\)|Core #1" } | Select-Object -First 1
        
        $temp = if ($tempSensor) { [math]::Round($tempSensor.Value, 1) } else { $null }
        $load = if ($loadSensor) { [math]::Round($loadSensor.Value, 1) } else { $null }
        $power = if ($powerSensor) { [math]::Round($powerSensor.Value, 1) } else { $null }
        $clock = if ($clockSensor) { [math]::Round($clockSensor.Value / 1000, 2) } else { $null }
        
        # Statistik-Daten aktualisieren
        if ($temp) { Update-HardwareStats -Component 'CPU' -Property 'Temp' -Value $temp }
        if ($load) { Update-HardwareStats -Component 'CPU' -Property 'Load' -Value $load }
        if ($power) { Update-HardwareStats -Component 'CPU' -Property 'Power' -Value $power }
        if ($clock) { Update-HardwareStats -Component 'CPU' -Property 'Clock' -Value $clock }
        
        # Debug-Ausgabe der Sensordaten nur wenn Debug aktiv
        if ($script:DebugModeCPU) {
            $sensorData = @{
                "Temperatur" = $(if ($temp) { "$temp °C" } else { "N/A" })
                "Auslastung" = $(if ($load) { "$load %" } else { "N/A" })
                "Leistung"   = $(if ($power) { "$power W" } else { "N/A" })
                "Takt"       = $(if ($clock) { "$clock GHz" } else { "N/A" })
            }
            Write-SensorInfo -Component 'CPU' -SensorData $sensorData
        }
        
        # UI-Elemente aktualisieren, wenn vorhanden
        if ($null -ne $CpuLabel) {
            $CpuLabel.Text = " $(if ($load) { "$load%" } else { "N/A" }) | $(if ($temp) { "$temp°C" } else { "N/A" }) | $(if ($power) { "$power W" } else { "N/A" }) | $(if ($clock) { "$clock GHz" } else { "N/A" })"
        }
        
        # Panel-Farbe aktualisieren, aber nur wenn nötig
        if ($null -ne $Panel) {
            $warningColor = Get-WarningColor -Temperature $temp -Load $load -TempThresholds @(70, 85) -LoadThresholds @(80, 95)
            if ($warningColor) {
                if ($Panel.BackColor -ne $warningColor) {
                    $Panel.BackColor = $warningColor
                }
            }
            elseif ($Panel.BackColor -ne [System.Drawing.Color]::LightGreen) {
                $Panel.BackColor = [System.Drawing.Color]::LightGreen
            }
        }
        
        # Debug-Ausgabe nur wenn Debug aktiv
        if ($script:DebugModeCPU) {
            Write-DebugOutput -Component 'CPU' -Message "T: $(if ($temp) { "$temp°C" } else { "N/A" }) | L: $(if ($load) { "$load%" } else { "N/A" }) | P: $(if ($power) { "$power W" } else { "N/A" }) | C: $(if ($clock) { "$clock GHz" } else { "N/A" })"
        }
    }
    catch {
        Write-DebugOutput -Component 'CPU' -Message "Fehler: $_" -Force
    }
}

#endregion

#region GPU Funktionen

function Update-GpuInfo {
    param (
        [System.Windows.Forms.Label]$GpuLabel,
        [System.Windows.Forms.Panel]$Panel
    )
    
    try {
        if (-not $script:useLibreHardware -or $null -eq $script:computerObj) {
            Write-DebugOutput -Component 'GPU' -Message "LibreHardwareMonitor nicht initialisiert" -Force
            return
        }
        
        # Debug-Ausgabe der Hardware-Info nur bei Bedarf
        if ($script:DebugModeGPU -and -not $script:gpuInfoShown) {
            Write-HardwareInfo -Component 'GPU'
        }
        
        $gpuHardware = $script:computerObj.Hardware | Where-Object { $_.HardwareType -eq "GpuNvidia" -or $_.HardwareType -eq "GpuAmd" }
        
        if ($null -eq $gpuHardware) {
            Write-DebugOutput -Component 'GPU' -Message "Keine GPU gefunden" -Force
            $GpuLabel.Text = "Keine GPU erkannt"
            $Panel.BackColor = [System.Drawing.Color]::LightGray
            return
        }
        
        # GPU-Namen abrufen oder den Cache verwenden
        if ($null -eq $script:gpuName) {
            foreach ($gpu in $gpuHardware) {
                $gpu.Update()
                $script:gpuName = $gpu.Name
                
                # GPU-Titel-Label setzen, wenn verfügbar
                if ($Panel -and $Panel.Controls.Count -gt 0) {
                    foreach ($control in $Panel.Controls) {
                        if ($control -is [System.Windows.Forms.Label] -and $control.Location.Y -eq 0) {
                            $control.Text = "GPU: $($gpu.Name)"
                            $control.Refresh()
                            break
                        }
                    }
                }
                
                Write-DebugOutput -Component 'GPU' -Message "GPU-Name gesetzt: $($gpu.Name)"
                break # Nur die erste GPU verwenden
            }
        }
        
        $temp = $null
        $load = $null
        $power = $null
        $clock = $null
        
        foreach ($gpu in $gpuHardware) {
            $gpu.Update()
                    
            foreach ($sensor in $gpu.Sensors) {
                if ($sensor.SensorType -eq "Temperature" -and $sensor.Name -eq "GPU Core") {
                    $temp = [Math]::Round($sensor.Value, 1)
                }
                elseif ($sensor.SensorType -eq "Load" -and $sensor.Name -eq "GPU Core") {
                    $load = [Math]::Round($sensor.Value, 0)
                }
                elseif ($sensor.SensorType -eq "Power" -and $sensor.Name -eq "GPU Package") {
                    $power = [Math]::Round($sensor.Value, 0)
                }
                elseif ($sensor.SensorType -eq "Clock" -and $sensor.Name -eq "GPU Core") {
                    $clock = [Math]::Round($sensor.Value, 0)
                }
            }
            
            # Nur die erste GPU verwenden
            break
        }
        
        if ($null -ne $temp -and $null -ne $load -and $null -ne $power -and $null -ne $clock) {
            # Formatiere den Takt in GHz für die Anzeige
            $clockGHz = [Math]::Round($clock / 1000, 2)
            $GpuLabel.Text = "$load% | $temp°C | $power W | $clockGHz GHz"
            
            # Berechne Panel-Farbe basierend auf der GPU-Temperatur
            $Panel.BackColor = Get-WarningColor -Temperature $temp -Component 'GPU'
            
            # Debug-Ausgabe nur bei Bedarf
            Write-DebugOutput -Component 'GPU' -Message "Temp: $temp, Load: $load, Power: $power, Clock: $clock MHz ($clockGHz GHz)"
        }
        else {
            Write-DebugOutput -Component 'GPU' -Message "Keine vollständigen GPU-Daten verfügbar" -Force
            $GpuLabel.Text = "GPU-Daten nicht verfügbar"
            $Panel.BackColor = [System.Drawing.Color]::LightGray
        }
        
        # Statistik-Daten aktualisieren
        if ($temp) { Update-HardwareStats -Component 'GPU' -Property 'Temp' -Value $temp }
        if ($load) { Update-HardwareStats -Component 'GPU' -Property 'Load' -Value $load }
        if ($power) { Update-HardwareStats -Component 'GPU' -Property 'Power' -Value $power }
        if ($clock) { Update-HardwareStats -Component 'GPU' -Property 'Clock' -Value $clock }
    }
    catch {
        # Fehlerbehandlung
        Write-DebugOutput -Component 'GPU' -Message "Fehler in Update-GpuInfo: $_" -Force
        $GpuLabel.Text = "Fehler: GPU-Daten können nicht abgerufen werden"
        $Panel.BackColor = [System.Drawing.Color]::LightCoral
    }
}

# Funktion zur Abfrage der GPU-Auslastung mit Fallback auf verschiedene Quellen
function Get-GPUUsage {
    param (
        [double]$LibreHardwareValue
    )
    
    try {
        # Optimierung: Die Performance-Counter sind teuer, daher nur bedingt verwenden
        # Statische Variable für Timestamp des letzten Updates
        if (-not $script:lastGpuCounterUpdate) {
            $script:lastGpuCounterUpdate = [DateTime]::MinValue
            $script:lastGpuCounterValue = $null
        }

        $now = Get-Date
        $counterUpdateInterval = [TimeSpan]::FromSeconds(5)  # Performance Counter nur alle 5 Sekunden abfragen

        # Wenn LibreHardware einen vernünftigen Wert liefert und wir nicht längere Zeit ohne Counter-Update sind,
        # einfach diesen Wert zurückgeben
        if ($null -ne $LibreHardwareValue -and $LibreHardwareValue -gt 0 -and 
            ($LibreHardwareValue -gt 20 -or ($now - $script:lastGpuCounterUpdate) -lt $counterUpdateInterval)) {
            return $LibreHardwareValue
        }

        # Wenn der zuletzt ermittelte Counter-Wert noch frisch ist, diesen wiederverwenden
        if (($now - $script:lastGpuCounterUpdate) -lt $counterUpdateInterval -and $null -ne $script:lastGpuCounterValue) {
            return $script:lastGpuCounterValue
        }

        # Versuch 1: Windows Performance Counter (am zuverlässigsten für GPU-Nutzung)
        try {
            $gpuCounters = Get-Counter -Counter "\GPU Engine(*engtype_3D)\Utilization Percentage" -ErrorAction SilentlyContinue
            if ($gpuCounters) {
                $gpuUsage = ($gpuCounters.CounterSamples | Where-Object { $_.InstanceName -notmatch "_engtype_" -and $_.InstanceName -notmatch "pid_" -and $_.CookedValue -gt 0 } | Measure-Object -Property CookedValue -Sum).Sum
                
                # Begrenze auf 100%
                if ($gpuUsage -gt 100) { $gpuUsage = 100 }
                
                # Wenn der Wert vernünftig ist, diesen zurückgeben
                if ($gpuUsage -gt 0) {
                    $winUsage = [math]::Round($gpuUsage, 1)
                    
                    # Wert und Zeitstempel speichern
                    $script:lastGpuCounterUpdate = $now
                    $script:lastGpuCounterValue = $winUsage
                    
                    # Vergleich zwischen Windows und LibreHardware-Werten durchführen (wenn beide vorhanden)
                    if ($null -ne $LibreHardwareValue -and $LibreHardwareValue -gt 0) {
                        # Wenn große Diskrepanz, Windows-Werte bevorzugen (LibreHardware hängt manchmal bei 10%)
                        if ([Math]::Abs($winUsage - $LibreHardwareValue) -gt 30 -and $LibreHardwareValue -lt 20 -and $winUsage -gt 50) {
                            if ($script:DebugModeGPU) {
                                Write-DebugOutput -Component 'GPU' -Message "Große Abweichung: Windows: $winUsage%, LibreHW: $LibreHardwareValue% - Verwende Windows-Wert"
                            }
                            return $winUsage
                        }
                    }
                    
                    return $winUsage
                }
            }
        }
        catch {
            if ($script:DebugModeGPU) {
                Write-DebugOutput -Component 'GPU' -Message "Fehler bei GPU-Counter: $_"
            }
        }
        
        # Fallback auf LibreHardware-Werte, wenn vorhanden
        if ($null -ne $LibreHardwareValue -and $LibreHardwareValue -ge 0) {
            return $LibreHardwareValue
        }
        
        # Fallback auf WMI nur wenn nötig und wenn LibreHardware keine Werte liefert
        # Dies ist die langsamste Methode
        if (($now - $script:lastGpuCounterUpdate) -gt [TimeSpan]::FromSeconds(10)) {
            try {
                $gpuWMI = Get-WmiObject -Class Win32_PerfFormattedData_GPUPerformanceCounters_GPUEngine | 
                Where-Object { $_.Name -match "engtype_3D" } | 
                Measure-Object -Property UtilizationPercentage -Average
                
                if ($gpuWMI.Average) {
                    $wmiValue = [math]::Round($gpuWMI.Average, 1)
                    $script:lastGpuCounterUpdate = $now
                    $script:lastGpuCounterValue = $wmiValue
                    return $wmiValue
                }
            }
            catch {
                if ($script:DebugModeGPU) {
                    Write-DebugOutput -Component 'GPU' -Message "Fehler bei WMI-GPU: $_"
                }
            }
        }
        
        # Wenn alles versagt, letzten Wert zurückgeben oder null
        return $script:lastGpuCounterValue
    }
    catch {
        if ($script:DebugModeGPU) {
            Write-DebugOutput -Component 'GPU' -Message "Allgemeiner Fehler bei GPU-Auslastung: $_" -Force
        }
        return $null
    }
}

#endregion

#region RAM Funktionen

function Update-RamInfo {
    param (
        [System.Windows.Forms.Label]$RamLabel,
        [System.Windows.Forms.Panel]$Panel
    )
    
    try {
        if (-not $script:useLibreHardware -or $null -eq $script:computerObj) {
            Write-DebugOutput -Component 'RAM' -Message "LibreHardwareMonitor nicht initialisiert" -Force
            return
        }
        
        # Debug-Ausgabe der Hardware-Info nur bei Bedarf
        if ($script:DebugModeRAM -and -not $script:ramInfoShown) {
            Write-HardwareInfo -Component 'RAM'
        }

        # Cache für die RAM-Werte - Aktualisierung nur alle 3 Zyklen
        if (-not $script:ramCache -or $script:updateCounter % 3 -eq 0) {
            # Speicherinformationen holen
            $osMemory = Get-WmiObject -Class Win32_OperatingSystem -ErrorAction SilentlyContinue
            
            if ($osMemory) {
                $totalMemory = [math]::Round($osMemory.TotalVisibleMemorySize / 1MB, 1)
                $freeMemory = [math]::Round($osMemory.FreePhysicalMemory / 1MB, 1)
                $usedMemory = [math]::Round($totalMemory - $freeMemory, 1)
                $usedPercentage = [math]::Round(($usedMemory / $totalMemory) * 100, 1)

                # RAM-Temperatur nach Bedarf - weniger priorisiert
                if ($script:updateCounter % 5 -eq 0) {
                    $ramTemp = Get-RamTemperature
                }
                else {
                    $ramTemp = $script:lastRamTemp  # Wiederverwendung des letzten Werts
                }

                # Werte für spätere Verwendung cachen
                $script:ramCache = @{
                    TotalMemory    = $totalMemory
                    UsedMemory     = $usedMemory
                    UsedPercentage = $usedPercentage
                    RamTemp        = $ramTemp
                }
            }
            else {
                # Wenn WMI-Abfrage fehlschlägt, vorherige Werte verwenden
                if (-not $script:ramCache) {
                    Write-DebugOutput -Component 'RAM' -Message "Keine RAM-Informationen verfügbar" -Force
                    return
                }
            }
        }
        
        # Cache-Werte abrufen
        $totalMemory = $script:ramCache.TotalMemory
        $usedMemory = $script:ramCache.UsedMemory
        $usedPercentage = $script:ramCache.UsedPercentage
        $ramTemp = $script:ramCache.RamTemp
        
        # Statistik-Daten aktualisieren 
        if ($ramTemp) { Update-HardwareStats -Component 'RAM' -Property 'Temp' -Value $ramTemp }
        if ($usedPercentage) { Update-HardwareStats -Component 'RAM' -Property 'Load' -Value $usedPercentage }
        if ($usedMemory) { Update-HardwareStats -Component 'RAM' -Property 'Used' -Value $usedMemory }
        
        # Debug-Ausgabe der Sensordaten nur wenn Debug aktiv
        if ($script:DebugModeRAM) {
            $sensorData = @{
                "Gesamt"     = "$totalMemory GB"
                "Verwendet"  = "$usedMemory GB"
                "Frei"       = "$([math]::Round($totalMemory - $usedMemory, 1)) GB"
                "Auslastung" = "$usedPercentage %"
                "Temperatur" = $(if ($ramTemp) { "$ramTemp °C" } else { "N/A" })
            }
            
            # Füge SPD Hub-Details hinzu, wenn verfügbar
            if ($script:ramStats.SPD -and $script:ramStats.SPD.Min -lt 999) {
                $sensorData["SPD Hub Min"] = "$($script:ramStats.SPD.Min) °C"
                $sensorData["SPD Hub Avg"] = "$($script:ramStats.SPD.Avg) °C"
                $sensorData["SPD Hub Max"] = "$($script:ramStats.SPD.Max) °C"
            }
            
            Write-SensorInfo -Component 'RAM' -SensorData $sensorData
        }
        
        # UI-Elemente aktualisieren, wenn vorhanden
        if ($null -ne $RamLabel) {
            $memoryInfo = "$usedMemory GB / $totalMemory GB"
            
            # Standard-Format
            $ramLabelText = " $(if ($usedPercentage) { "$usedPercentage%" } else { "N/A" })"
            
            # Temperatur-Anzeige
            if ($ramTemp) {
                $ramLabelText += " | $ramTemp°C"
                
                # Wenn SPD Hub-Details verfügbar und Debug-Modus aktiv, Details anzeigen
                if ($script:ramStats.SPD -and $script:ramStats.SPD.Min -lt 999 -and $script:DebugModeRAM) {
                    $ramLabelText += " (Min: $($script:ramStats.SPD.Min)°C, Avg: $($script:ramStats.SPD.Avg)°C, Max: $($script:ramStats.SPD.Max)°C)"
                }
            }
            else {
                $ramLabelText += " | N/A"
            }
            
            # Speicherinfo anhängen
            $ramLabelText += " | $memoryInfo"
            
            # Label-Text setzen
            $RamLabel.Text = $ramLabelText
            
            # Klick-Handler für das RAM-Label hinzufügen, wenn noch nicht vorhanden
            if ($null -eq $RamLabel.Tag -or $RamLabel.Tag -ne "SPDClickHandlerAdded") {
                $RamLabel.Cursor = [System.Windows.Forms.Cursors]::Hand
                $RamLabel.Tag = "SPDClickHandlerAdded"
                $RamLabel.Add_Click({
                        if ($script:ramStats.SPD -and $script:ramStats.SPD.FoundSensors) {
                            Show-RamSPDTempDetails -SPDData $script:ramStats.SPD
                        }
                        else {
                            [System.Windows.Forms.MessageBox]::Show(
                                "Keine SPD-Temperatursensoren gefunden. Aktiviere den Debug-Modus für mehr Informationen.",
                                "RAM-Temperatursensoren",
                                [System.Windows.Forms.MessageBoxButtons]::OK,
                                [System.Windows.Forms.MessageBoxIcon]::Information
                            )
                        }
                    })
            }
        }
        
        # Panel-Farbe aktualisieren, aber nur wenn nötig
        if ($null -ne $Panel) {
            $warningColor = Get-WarningColor -Temperature $ramTemp -Load $usedPercentage -TempThresholds @(50, 65) -LoadThresholds @(85, 95)
            if ($warningColor) {
                if ($Panel.BackColor -ne $warningColor) {
                    $Panel.BackColor = $warningColor
                }
            }
            elseif ($Panel.BackColor -ne [System.Drawing.Color]::LightGreen) {
                $Panel.BackColor = [System.Drawing.Color]::LightGreen
            }
            
            # Klick-Handler für das RAM-Panel hinzufügen, wenn noch nicht vorhanden
            if ($null -eq $Panel.Tag -or $Panel.Tag -ne "SPDClickHandlerAdded") {
                $Panel.Cursor = [System.Windows.Forms.Cursors]::Hand
                $Panel.Tag = "SPDClickHandlerAdded"
                $Panel.Add_Click({
                        if ($script:ramStats.SPD -and $script:ramStats.SPD.FoundSensors) {
                            Show-RamSPDTempDetails -SPDData $script:ramStats.SPD
                        }
                        else {
                            [System.Windows.Forms.MessageBox]::Show(
                                "Keine SPD-Temperatursensoren gefunden. Aktiviere den Debug-Modus für mehr Informationen.",
                                "RAM-Temperatursensoren",
                                [System.Windows.Forms.MessageBoxButtons]::OK,
                                [System.Windows.Forms.MessageBoxIcon]::Information
                            )
                        }
                    })
            }
        }
        
        # Debug-Ausgabe nur wenn Debug aktiv
        if ($script:DebugModeRAM) {
            if ($ramTemp) {
                Write-DebugOutput -Component 'RAM' -Message "A: $usedPercentage% | V: $usedMemory GB | G: $totalMemory GB | T: $ramTemp°C"
            }
            else {
                Write-DebugOutput -Component 'RAM' -Message "A: $usedPercentage% | V: $usedMemory GB | G: $totalMemory GB"
            }
        }
    }
    catch {
        Write-DebugOutput -Component 'RAM' -Message "Fehler: $_" -Force
    }
}
    
function Get-RamTemperature {
    try {
        if (-not $script:useLibreHardware -or $null -eq $script:computerObj) {
            return $null
        }
        
        # Neue DDR5 SPD Hub-Temperatursensoren (spezifisch für DDR5)
        $ddr5SpdData = @{
            FoundSensors = $false
            Values       = @()
            Min          = $null
            Max          = $null
            Avg          = $null
            Current      = $null
        }
        
        # Alle Hardware-Komponenten aktualisieren, um sicherzustellen, dass wir aktuelle Daten haben
        $script:computerObj.Hardware | ForEach-Object { $_.Update() }
        
        # Debug-Ausgabe aller verfügbaren Hardware
        if ($script:DebugModeRAM) {
            Write-DebugOutput -Component 'RAM' -Message "Verfügbare Hardware-Typen:" -Force
            $availableHardware = $script:computerObj.Hardware | ForEach-Object { $_.HardwareType }
            Write-DebugOutput -Component 'RAM' -Message ($availableHardware -join ", ") -Force
        }
        
        # Zuerst alle verfügbaren Sensoren sammeln (für erweiterte Debug-Ausgabe)
        $allTempSensors = @()
        $script:computerObj.Hardware | ForEach-Object {
            $hardwareType = $_.HardwareType
            $hardwareName = $_.Name
            
            if ($script:DebugModeRAM) {
                Write-DebugOutput -Component 'RAM' -Message "Prüfe Hardware: $hardwareType - $hardwareName" -Force
            }
            
            $_.Sensors | Where-Object { $_.SensorType -eq "Temperature" } | ForEach-Object {
                $allTempSensors += [PSCustomObject]@{
                    HardwareType = $hardwareType
                    HardwareName = $hardwareName
                    SensorName   = $_.Name
                    Value        = $_.Value
                    Identifier   = $_.Identifier
                }
            }
        }
        
        # Debug-Ausgabe aller verfügbaren Temperatursensoren
        if ($script:DebugModeRAM) {
            Write-DebugOutput -Component 'RAM' -Message "Verfügbare Temperatursensoren:" -Force
            foreach ($sensor in $allTempSensors) {
                Write-DebugOutput -Component 'RAM' -Message "$($sensor.HardwareType) - $($sensor.HardwareName) - $($sensor.SensorName): $($sensor.Value)°C [ID: $($sensor.Identifier)]" -Force
            }
        }
        
        # RAM-Hardware direkt auswählen
        $memoryHardware = $script:computerObj.Hardware | Where-Object { $_.HardwareType -eq "Memory" }
        
        if ($memoryHardware) {
            if ($script:DebugModeRAM) {
                Write-DebugOutput -Component 'RAM' -Message "Memory-Hardware gefunden: $($memoryHardware.Count) Instanzen" -Force
            }
            
            # Erweiterte Suche nach DDR5 SPD-Hub-Temperatursensoren
            foreach ($memory in $memoryHardware) {
                $memory.Update()  # Aktualisieren
                
                if ($script:DebugModeRAM) {
                    Write-DebugOutput -Component 'RAM' -Message "Prüfe Memory: $($memory.Name) mit $($memory.Sensors.Count) Sensoren" -Force
                }
                
                # SPD Hub Temperature Sensoren für DDR5 suchen - erweiterte Kriterien
                $spdSensors = $memory.Sensors | Where-Object { 
                    $_.SensorType -eq "Temperature" -and 
                    ($_.Name -match "SPD" -or 
                    $_.Name -match "DIMM \d+" -or 
                    $_.Name -match "Memory" -or
                    $_.Name -match "BANK" -or
                    $_.Name -match "DDR5" -or
                    $_.Identifier -match "/dimm\d*/temperature" -or
                    $_.Identifier -match "/temperature/\d+")
                }
                
                if ($spdSensors -and $spdSensors.Count -gt 0) {
                    if ($script:DebugModeRAM) {
                        Write-DebugOutput -Component 'RAM' -Message "SPD-Sensoren gefunden: $($spdSensors.Count)" -Force
                        foreach ($s in $spdSensors) {
                            Write-DebugOutput -Component 'RAM' -Message "  Sensor: $($s.Name), Wert: $($s.Value)°C, ID: $($s.Identifier)" -Force
                        }
                    }
                    
                    $ddr5SpdData.FoundSensors = $true
                    
                    foreach ($sensor in $spdSensors) {
                        if ($sensor.Value -gt 0 -and $sensor.Value -lt 100) {
                            $ddr5SpdData.Values += $sensor.Value
                        }
                    }
                    
                    if ($ddr5SpdData.Values.Count -gt 0) {
                        $ddr5SpdData.Min = ($ddr5SpdData.Values | Measure-Object -Minimum).Minimum
                        $ddr5SpdData.Max = ($ddr5SpdData.Values | Measure-Object -Maximum).Maximum
                        $ddr5SpdData.Avg = ($ddr5SpdData.Values | Measure-Object -Average).Average
                        $ddr5SpdData.Current = $ddr5SpdData.Max  # Wir nehmen den höchsten Wert als aktuell

                        # Werte runden
                        $ddr5SpdData.Min = [math]::Round($ddr5SpdData.Min, 2)
                        $ddr5SpdData.Max = [math]::Round($ddr5SpdData.Max, 2)
                        $ddr5SpdData.Avg = [math]::Round($ddr5SpdData.Avg, 2)
                        $ddr5SpdData.Current = [math]::Round($ddr5SpdData.Current, 2)
                        
                        # Sensorwerte im Debug-Modus ausgeben
                        if ($script:DebugModeRAM) {
                            $sensorInfo = "DDR5 SPD Hub: Aktuell=$($ddr5SpdData.Current)°C, Min=$($ddr5SpdData.Min)°C, Avg=$($ddr5SpdData.Avg)°C, Max=$($ddr5SpdData.Max)°C"
                            Write-DebugOutput -Component 'RAM' -Message $sensorInfo -Force
                        }
                        
                        # Werte für RAM-Info speichern für Detailansicht
                        $script:ramStats.SPD = $ddr5SpdData
                        
                        # Aktuellen Wert zurückgeben
                        $script:lastRamTemp = $ddr5SpdData.Current
                        return $script:lastRamTemp
                    }
                }
            }
        }
        else {
            if ($script:DebugModeRAM) {
                Write-DebugOutput -Component 'RAM' -Message "Keine Memory-Hardware gefunden" -Force
            }
        }
        
        # Alternative: Suche nach SPD-Sensoren auf dem Mainboard
        # Manchmal werden die Sensoren direkt am Mainboard erkannt
        $motherboardHardware = $script:computerObj.Hardware | Where-Object { $_.HardwareType -eq "Motherboard" }
        if ($motherboardHardware) {
            if ($script:DebugModeRAM) {
                Write-DebugOutput -Component 'RAM' -Message "Suche auf Mainboard nach SPD-Sensoren" -Force
            }
            
            foreach ($mb in $motherboardHardware) {
                $mb.Update()
                
                # SPD-Sensoren auf dem Mainboard suchen
                $mbSpdSensors = $mb.Sensors | Where-Object { 
                    $_.SensorType -eq "Temperature" -and 
                    ($_.Name -match "SPD" -or 
                    $_.Name -match "DIMM" -or 
                    $_.Name -match "RAM" -or
                    $_.Name -match "Memory" -or
                    $_.Name -match "BANK" -or
                    $_.Name -match "DDR5")
                }
                
                if ($mbSpdSensors -and $mbSpdSensors.Count -gt 0) {
                    if ($script:DebugModeRAM) {
                        Write-DebugOutput -Component 'RAM' -Message "SPD-Sensoren auf Mainboard gefunden: $($mbSpdSensors.Count)" -Force
                        foreach ($s in $mbSpdSensors) {
                            Write-DebugOutput -Component 'RAM' -Message "  Sensor: $($s.Name), Wert: $($s.Value)°C, ID: $($s.Identifier)" -Force
                        }
                    }
                    
                    $ddr5SpdData.FoundSensors = $true
                    
                    foreach ($sensor in $mbSpdSensors) {
                        if ($sensor.Value -gt 0 -and $sensor.Value -lt 100) {
                            $ddr5SpdData.Values += $sensor.Value
                        }
                    }
                    
                    if ($ddr5SpdData.Values.Count -gt 0) {
                        $ddr5SpdData.Min = ($ddr5SpdData.Values | Measure-Object -Minimum).Minimum
                        $ddr5SpdData.Max = ($ddr5SpdData.Values | Measure-Object -Maximum).Maximum
                        $ddr5SpdData.Avg = ($ddr5SpdData.Values | Measure-Object -Average).Average
                        $ddr5SpdData.Current = $ddr5SpdData.Max  # Wir nehmen den höchsten Wert als aktuell

                        # Werte runden
                        $ddr5SpdData.Min = [math]::Round($ddr5SpdData.Min, 2)
                        $ddr5SpdData.Max = [math]::Round($ddr5SpdData.Max, 2)
                        $ddr5SpdData.Avg = [math]::Round($ddr5SpdData.Avg, 2)
                        $ddr5SpdData.Current = [math]::Round($ddr5SpdData.Current, 2)
                        
                        # Werte für RAM-Info speichern für Detailansicht
                        $script:ramStats.SPD = $ddr5SpdData
                        
                        # Aktuellen Wert zurückgeben
                        $script:lastRamTemp = $ddr5SpdData.Current
                        return $script:lastRamTemp
                    }
                }
                
                # Nach allgemeinen DIMM-Temperatursensoren suchen wenn keine SPD-Sensoren gefunden wurden
                $mbTempSensors = $mb.Sensors | Where-Object { 
                    $_.SensorType -eq "Temperature" -and 
                    ($_.Name -match "DIMM|Memory|RAM" -or $_.Name -match "TMPIN\d+")
                }
                
                foreach ($sensor in $mbTempSensors) {
                    if ($sensor.Value -gt 0 -and $sensor.Value -lt 100) {
                        # Plausibilitätsprüfung
                        $script:lastRamTemp = [math]::Round($sensor.Value, 1)
                        return $script:lastRamTemp
                    }
                }
            }
        }

        # Rest der Funktion bleibt unverändert
        // ... existing code ...
    }
    catch {
        Write-DebugOutput -Component 'RAM' -Message "Fehler bei RAM-Temperatur: $_" -Force
        return $null
    }
}

# Versuche die iCUE SDK für Corsair RAM einzubinden
function Initialize-CorsairSDK {
    if ($script:icueInitialized) {
        return $true
    }
    
    try {
        if (Test-Path $script:iCUESDKPath) {
            # Importiere die iCUE SDK DLL
            Add-Type -Path $script:iCUESDKPath -ErrorAction Stop
            
            # Initialisiere SDK
            $initResult = [CUESDK.CorsairLightingSDK]::CorsairPerformProtocolHandshake()
            $deviceCount = [CUESDK.CorsairLightingSDK]::CorsairGetDeviceCount()
            
            if ($deviceCount -gt 0) {
                Write-Host "Corsair iCUE SDK erfolgreich initialisiert. $deviceCount Geräte gefunden." -ForegroundColor Green
                $script:useICUE = $true
                $script:icueInitialized = $true
                return $true
            }
            else {
                Write-Host "Corsair iCUE SDK initialisiert, aber keine Geräte gefunden." -ForegroundColor Yellow
                return $false
            }
        }
        else {
            # Write-Host "Corsair iCUE SDK nicht gefunden unter: $script:iCUESDKPath" -ForegroundColor Yellow
            return $false
        }
    }
    catch {
        # Fehler beim Laden der DLL
        # Write-Host "Fehler beim Initialisieren der Corsair iCUE SDK: $_" -ForegroundColor Yellow
        return $false
    }
}
    
# Funktion zum Abrufen der Corsair RAM Temperatur via iCUE
function Get-CorsairRAMTemperature {
    if (-not $script:useICUE -or -not $script:icueInitialized) {
        if (-not (Initialize-CorsairSDK)) {
            return $null
        }
    }
    
    try {
        $deviceCount = [CUESDK.CorsairLightingSDK]::CorsairGetDeviceCount()
        
        for ($i = 0; $i -lt $deviceCount; $i++) {
            $device = [CUESDK.CorsairLightingSDK]::CorsairGetDeviceInfo($i)
            
            # Prüfe, ob es sich um RAM handelt (Typischerweise Typ 4 = DRAM)
            if ($device.type -eq 4 -or $device.model -match "Dominator|Vengeance|RAM") {
                # Versuche Sensor-Informationen abzurufen
                $sensorInfo = [CUESDK.CorsairLightingSDK]::CorsairGetTemperature($i)
                
                if ($sensorInfo -and $sensorInfo.temperature -gt 0) {
                    return [math]::Round($sensorInfo.temperature, 1)
                }
            }
        }
        
        return $null
    }
    catch {
        if ($script:DebugModeRAM) {
            Write-DebugOutput -Component 'RAM' -Message "Fehler bei Corsair SDK: $_" -Force
        }
        return $null
    }
}

#endregion

#region Export

# Export functions
Export-ModuleMember -Function Initialize-LibreHardwareMonitor, Initialize-LiveMonitoring, `
    Initialize-HardwareMonitoring, Start-HardwareMonitoring, Stop-HardwareMonitoring, Clear-HardwareMonitoring, `
    Update-CpuInfo, Update-GpuInfo, Update-RamInfo, Get-RamTemperature, Get-WarningColor, `
    Set-HardwareMonitorDebugMode, Set-HardwareDebugMode, Get-HardwareTimerStatus, Write-HardwareInfo, Write-SensorInfo, `
    Get-GPUUsage, Update-HardwareStats, Get-HardwareStatsTooltip, Reset-GpuName, Show-RamSPDTempDetails, `
    Initialize-SMBusAccess, Get-RamTemperatureViaSMBus

#endregion

#region Statistik-Funktionen

# Funktion zum Aktualisieren der Statistiken mit neuen Werten
function Update-HardwareStats {
    param(
        [ValidateSet('CPU', 'GPU', 'RAM')]
        [string]$Component,
        [Parameter(Mandatory = $true)]
        [string]$Property,
        [Parameter(Mandatory = $true)]
        [double]$Value
    )

    $statsVar = switch ($Component) {
        'CPU' { 'cpuStats' }
        'GPU' { 'gpuStats' }
        'RAM' { 'ramStats' }
    }

    if (-not (Get-Variable -Name ${statsVar} -Scope Script -ErrorAction SilentlyContinue)) {
        Set-Variable -Name ${statsVar} -Scope Script -Value @{}
    }

    $stats = Get-Variable -Name ${statsVar} -Scope Script -ValueOnly

    if (-not $stats.ContainsKey($Property)) {
        $stats[$Property] = @{
            Min   = $Value
            Max   = $Value
            Sum   = $Value
            Count = 1
            Last  = $Value
        }
    }
    else {
        $entry = $stats[$Property]
        $entry.Min = [Math]::Min($entry.Min, $Value)
        $entry.Max = [Math]::Max($entry.Max, $Value)
        $entry.Sum += $Value
        $entry.Count += 1
        $entry.Last = $Value
        $stats[$Property] = $entry
    }

    Set-Variable -Name ${statsVar} -Scope Script -Value $stats
}

# Funktion zum Generieren eines schönen Tooltips für die Hardware-Labels
function Get-HardwareStatsTooltip {
    param(
        [ValidateSet('CPU', 'GPU', 'RAM')]
        [string]$Component
    )

    $stats = switch ($Component) {
        'CPU' { $script:cpuStats }
        'GPU' { $script:gpuStats }
        'RAM' { $script:ramStats }
    }

    if (-not $stats -or $stats.Count -eq 0) {
        return "Keine Statistikdaten verfügbar."
    }

    $lines = @()
    $lines += "$Component Statistik:"
    foreach ($key in $stats.Keys) {
        $entry = $stats[$key]
        $avg = if ($entry.Count -gt 0) { [Math]::Round($entry.Sum / $entry.Count, 2) } else { "N/A" }
        $lines += '  {0}: Aktuell: {1} | Min: {2} | Max: {3} | Durchschnitt: {4}' -f $key, $entry.Last, $entry.Min, $entry.Max, $avg
    }
    return ($lines -join "`n")
}

#endregion 

# Neue Funktion zum Zurücksetzen des GPU-Namens
function Reset-GpuName {
    $script:gpuName = $null
    Write-Host "GPU-Name zurückgesetzt. Bei der nächsten Aktualisierung wird er neu ermittelt."
}

#endregion 

# Neue Funktion für das RAM-SPD-Temperatur-Popup
function Show-RamSPDTempDetails {
    param (
        [hashtable]$SPDData
    )
    
    if (-not $SPDData -or -not $SPDData.FoundSensors) {
        Write-DebugOutput -Component 'RAM' -Message "Keine SPD-Temperaturdaten verfügbar" -Force
        return
    }
    
    # Erstelle das Popup-Fenster
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "BANK 0/DDR5-A2"
    $form.Size = New-Object System.Drawing.Size(350, 350)
    $form.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
    $form.BackColor = [System.Drawing.Color]::FromArgb(40, 40, 45)
    $form.ForeColor = [System.Drawing.Color]::White
    $form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $form.MaximizeBox = $false
    $form.MinimizeBox = $false
    $form.TopMost = $true
    
    # Icon für die Form (Speicher-Symbol)
    $iconLabel = New-Object System.Windows.Forms.Label
    $iconLabel.Text = "🧠 SPD Hub Temperature"
    $iconLabel.Location = New-Object System.Drawing.Point(20, 20)
    $iconLabel.Size = New-Object System.Drawing.Size(300, 30)
    $iconLabel.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
    $iconLabel.ForeColor = [System.Drawing.Color]::White
    $form.Controls.Add($iconLabel)
    
    # Aktuelle Temperatur - großes Format
    $currentTempLabel = New-Object System.Windows.Forms.Label
    $currentTempLabel.Text = "$($SPDData.Current) °C"
    $currentTempLabel.Location = New-Object System.Drawing.Point(20, 60)
    $currentTempLabel.Size = New-Object System.Drawing.Size(300, 50)
    $currentTempLabel.Font = New-Object System.Drawing.Font("Segoe UI", 24, [System.Drawing.FontStyle]::Bold)
    $currentTempLabel.ForeColor = [System.Drawing.Color]::White
    $currentTempLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    $form.Controls.Add($currentTempLabel)
    
    # Separator
    $separator = New-Object System.Windows.Forms.Panel
    $separator.Location = New-Object System.Drawing.Point(20, 120)
    $separator.Size = New-Object System.Drawing.Size(300, 2)
    $separator.BackColor = [System.Drawing.Color]::FromArgb(80, 80, 85)
    $form.Controls.Add($separator)
    
    # Detail-Labels
    $labelY = 140
    
    # Min Temperatur
    $minTempLabel = New-Object System.Windows.Forms.Label
    $minTempLabel.Text = "Min"
    $minTempLabel.Location = New-Object System.Drawing.Point(20, $labelY)
    $minTempLabel.Size = New-Object System.Drawing.Size(100, 30)
    $minTempLabel.Font = New-Object System.Drawing.Font("Segoe UI", 12)
    $minTempLabel.ForeColor = [System.Drawing.Color]::LightGray
    $form.Controls.Add($minTempLabel)
    
    $minTempValueLabel = New-Object System.Windows.Forms.Label
    $minTempValueLabel.Text = "$($SPDData.Min) °C"
    $minTempValueLabel.Location = New-Object System.Drawing.Point(150, $labelY)
    $minTempValueLabel.Size = New-Object System.Drawing.Size(170, 30)
    $minTempValueLabel.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
    $minTempValueLabel.ForeColor = [System.Drawing.Color]::White
    $minTempValueLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleRight
    $form.Controls.Add($minTempValueLabel)
    
    $labelY += 40
    
    # Average Temperatur
    $avgTempLabel = New-Object System.Windows.Forms.Label
    $avgTempLabel.Text = "Average"
    $avgTempLabel.Location = New-Object System.Drawing.Point(20, $labelY)
    $avgTempLabel.Size = New-Object System.Drawing.Size(100, 30)
    $avgTempLabel.Font = New-Object System.Drawing.Font("Segoe UI", 12)
    $avgTempLabel.ForeColor = [System.Drawing.Color]::LightGray
    $form.Controls.Add($avgTempLabel)
    
    $avgTempValueLabel = New-Object System.Windows.Forms.Label
    $avgTempValueLabel.Text = "$($SPDData.Avg) °C"
    $avgTempValueLabel.Location = New-Object System.Drawing.Point(150, $labelY)
    $avgTempValueLabel.Size = New-Object System.Drawing.Size(170, 30)
    $avgTempValueLabel.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
    $avgTempValueLabel.ForeColor = [System.Drawing.Color]::White
    $avgTempValueLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleRight
    $form.Controls.Add($avgTempValueLabel)
    
    $labelY += 40
    
    # Max Temperatur
    $maxTempLabel = New-Object System.Windows.Forms.Label
    $maxTempLabel.Text = "Max"
    $maxTempLabel.Location = New-Object System.Drawing.Point(20, $labelY)
    $maxTempLabel.Size = New-Object System.Drawing.Size(100, 30)
    $maxTempLabel.Font = New-Object System.Drawing.Font("Segoe UI", 12)
    $maxTempLabel.ForeColor = [System.Drawing.Color]::LightGray
    $form.Controls.Add($maxTempLabel)
    
    $maxTempValueLabel = New-Object System.Windows.Forms.Label
    $maxTempValueLabel.Text = "$($SPDData.Max) °C"
    $maxTempValueLabel.Location = New-Object System.Drawing.Point(150, $labelY)
    $maxTempValueLabel.Size = New-Object System.Drawing.Size(170, 30)
    $maxTempValueLabel.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
    $maxTempValueLabel.ForeColor = [System.Drawing.Color]::White
    $maxTempValueLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleRight
    $form.Controls.Add($maxTempValueLabel)
    
    # Timer für automatische Aktualisierung
    $timer = New-Object System.Windows.Forms.Timer
    $timer.Interval = 1000  # Aktualisierung jede Sekunde
    $timer.Add_Tick({
            # RAM Temperatur aktualisieren
            $ramTemp = Get-RamTemperature
        
            if ($script:ramStats.SPD -and $script:ramStats.SPD.Min -lt 999) {
                $currentTempLabel.Text = "$($script:ramStats.SPD.Current) °C"
                $minTempValueLabel.Text = "$($script:ramStats.SPD.Min) °C"
                $avgTempValueLabel.Text = "$($script:ramStats.SPD.Avg) °C"
                $maxTempValueLabel.Text = "$($script:ramStats.SPD.Max) °C"
            }
        })
    
    # Close-Button
    $closeButton = New-Object System.Windows.Forms.Button
    $closeButton.Text = "Schließen"
    $closeButton.Location = New-Object System.Drawing.Point(125, 260)
    $closeButton.Size = New-Object System.Drawing.Size(100, 30)
    $closeButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $closeButton.BackColor = [System.Drawing.Color]::FromArgb(60, 60, 65)
    $closeButton.ForeColor = [System.Drawing.Color]::White
    $closeButton.Add_Click({
            $timer.Stop()
            $form.Close()
        })
    $form.Controls.Add($closeButton)
    
    # Dialog anzeigen
    $timer.Start()
    $form.ShowDialog() | Out-Null
    $timer.Stop()
}

# SMBus-Zugriffsfunktionen für RAM-Temperaturen
# Globale Variablen für SMBus
$script:smBusEnabled = $false
$script:smBusLoaded = $false
$script:smBusDriver = $null

# Funktion zum Initialisieren des SMBus-Zugriffs
function Initialize-SMBusAccess {
    if ($script:smBusLoaded) {
        return $script:smBusEnabled
    }
    
    try {
        # P/Invoke für direkten Hardware-Zugriff
        $signature = @'
        [DllImport("kernel32.dll", SetLastError = true)]
        public static extern IntPtr LoadLibrary(string lpFileName);
        
        [DllImport("kernel32.dll")]
        public static extern bool FreeLibrary(IntPtr hModule);
        
        [DllImport("kernel32.dll")]
        public static extern IntPtr GetProcAddress(IntPtr hModule, string procName);
        
        [DllImport("kernel32.dll", SetLastError = true)]
        public static extern bool DeviceIoControl(
            IntPtr hDevice,
            uint dwIoControlCode,
            IntPtr lpInBuffer,
            uint nInBufferSize,
            ref byte[] lpOutBuffer,
            uint nOutBufferSize,
            ref uint lpBytesReturned,
            IntPtr lpOverlapped);
'@
        
        Add-Type -MemberDefinition $signature -Name WinAPIWrapper -Namespace SMBus
        
        # Mögliche Treiber-DLLs für SMBus-Zugriff
        $driverPaths = @(
            (Join-Path -Path $PSScriptRoot -ChildPath "..\Lib\WinIo64.dll"),
            (Join-Path -Path $PSScriptRoot -ChildPath "..\Lib\inpoutx64.dll"),
            (Join-Path -Path $PSScriptRoot -ChildPath "..\Lib\RWEverything.dll")
        )
        
        foreach ($driverPath in $driverPaths) {
            if (Test-Path $driverPath) {
                $script:smBusDriver = [SMBus.WinAPIWrapper]::LoadLibrary($driverPath)
                if ($script:smBusDriver -ne [IntPtr]::Zero) {
                    Write-Host "SMBus-Treiber geladen: $driverPath" -ForegroundColor Green
                    $script:smBusLoaded = $true
                    $script:smBusEnabled = $true
                    return $true
                }
            }
        }
        
        # Alternative: WMI-basierter Zugriff testen
        try {
            $smBusDevices = Get-WmiObject -Namespace "root\wmi" -Class "MSSmBios" -ErrorAction Stop
            if ($smBusDevices) {
                Write-Host "SMBus über WMI verfügbar" -ForegroundColor Green
                $script:smBusLoaded = $true
                $script:smBusEnabled = $true
                return $true
            }
        }
        catch {
            # WMI-Zugriff fehlgeschlagen, weiter mit anderen Methoden
        }
        
        # Wenn kein Treiber gefunden wurde
        Write-Warning "Kein SMBus-Treiber gefunden. Temperaturabfrage über SMBus nicht möglich."
        $script:smBusLoaded = $true  # Markiere als versucht
        $script:smBusEnabled = $false
        return $false
    }
    catch {
        Write-Warning "Fehler beim Initialisieren des SMBus-Zugriffs: $_"
        $script:smBusLoaded = $true  # Markiere als versucht
        $script:smBusEnabled = $false
        return $false
    }
}

# Funktion zum Lesen der DDR5 SPD-Temperaturen über SMBus
function Get-RamTemperatureViaSMBus {
    if (-not $script:smBusEnabled) {
        if (-not (Initialize-SMBusAccess)) {
            return $null
        }
    }
    
    try {
        # Generischer Ansatz für verschiedene SMBus-Treiber
        $temperatures = @()
        
        # Bekannte SPD-Adressen für DDR5-Module
        $spdAddresses = @(0x50, 0x51, 0x52, 0x53, 0x54, 0x55, 0x56, 0x57)
        $tempRegister = 0x33  # Typisches Register für DDR5 SPD-Temperatursensor
        
        # Versuch mit Treiber-DLL
        if ($script:smBusDriver -ne $null -and (-not [IntPtr]::Equals($script:smBusDriver, [IntPtr]::Zero))) {
            # Hier implementieren wir den spezifischen Treiberaufruf
            # Die Implementierung variiert je nach verwendetem Treiber
            
            # Beispiel für generischen Zugriff (Pseudocode, muss angepasst werden)
            foreach ($address in $spdAddresses) {
                try {
                    # Beispiel für RWEverything oder ähnliche Treiber
                    $readFuncPtr = [SMBus.WinAPIWrapper]::GetProcAddress($script:smBusDriver, "SMBusReadByte")
                    if (-not [IntPtr]::Equals($readFuncPtr, [IntPtr]::Zero)) {
                        $delegate = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer(
                            $readFuncPtr, 
                            [Type][System.Func`3[[byte], [byte], [byte]]]
                        )
                        
                        $rawTemp = $delegate.Invoke($address, $tempRegister)
                        if ($rawTemp -gt 0 -and $rawTemp -lt 255) {
                            # DDR5 SPD-Temperatur ist typischerweise der Rohwert / 2 in Celsius
                            $temp = $rawTemp / 2.0
                            if ($temp -gt 10 -and $temp -lt 100) {
                                # Plausibilitätsprüfung
                                $temperatures += $temp
                            }
                        }
                    }
                }
                catch {
                    # Fehler bei diesem Modul, mit nächstem fortfahren
                    continue
                }
            }
        }
        
        # Alternative: WMI-basierter Versuch
        if ($temperatures.Count -eq 0) {
            try {
                $spdData = Get-WmiObject -Namespace "root\wmi" -Class "MSSmBios" -ErrorAction Stop
                if ($spdData) {
                    # SPD-Daten extrahieren - dies ist spezifisch für jeden WMI-Provider
                    # Die genaue Implementierung hängt vom Mainboard-Hersteller ab
                    $rawSpdBytes = $spdData.SMBiosData
                    
                    if ($rawSpdBytes) {
                        # Temperatur aus SPD-Daten extrahieren (Beispiel, muss angepasst werden)
                        for ($i = 0; $i -lt $rawSpdBytes.Length; $i++) {
                            if ($i + 0x33 -lt $rawSpdBytes.Length) {
                                # 0x33 ist typisches Temperatur-Register
                                $rawTemp = $rawSpdBytes[$i + 0x33]
                                $temp = $rawTemp / 2.0
                                if ($temp -gt 10 -and $temp -lt 100) {
                                    $temperatures += $temp
                                }
                            }
                        }
                    }
                }
            }
            catch {
                # WMI-Zugriff fehlgeschlagen, ignorieren
            }
        }
        
        # Wenn Temperaturen gefunden wurden, Ergebnis zurückgeben
        if ($temperatures.Count -gt 0) {
            $avgTemp = ($temperatures | Measure-Object -Average).Average
            $maxTemp = ($temperatures | Measure-Object -Maximum).Maximum
            
            # SPD-Daten für Detailanzeige speichern
            $script:ramStats.SPD = @{
                FoundSensors = $true
                Values       = $temperatures
                Min          = ($temperatures | Measure-Object -Minimum).Minimum
                Max          = $maxTemp
                Avg          = $avgTemp
                Current      = $maxTemp  # Den höchsten Wert als aktuell anzeigen
            }
            
            if ($script:DebugModeRAM) {
                Write-DebugOutput -Component 'RAM' -Message "SMBus-Temperaturen gefunden: $($temperatures -join ', ')" -Force
            }
            
            # Max-Temperatur zurückgeben (konservativste Annahme)
            return $maxTemp
        }
        
        # Keine Temperaturen gefunden
        return $null
    }
    catch {
        if ($script:DebugModeRAM) {
            Write-DebugOutput -Component 'RAM' -Message "Fehler bei SMBus-Temperaturabfrage: $_" -Force
        }
        return $null
    }
}

# Funktion zum Zurücksetzen aller Statistiken
function Reset-HardwareStatistics {
    # Statistiken deaktiviert - keine Aktion erforderlich
    return
}

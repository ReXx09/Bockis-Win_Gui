# HardwareMonitorTools.psm1
# Modul für Hardware-Überwachung und Monitoring-Funktionen

# Importiere Module
Import-Module "$PSScriptRoot\..\Core\Core.psm1" -Force
Import-Module "$PSScriptRoot\..\Core\ProgressBarTools.psm1" -Force

# Importiere erforderliche Assemblies
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

#region Globale Variablen

# Zugriff auf das zentrale Farbschema
$script:colors = $colors

# Globale Variablen für Hardware-Monitoring
$script:computerObj = $null
$script:useLibreHardware = $false
$script:hardwareTimer = $null
$script:wmiSensors = $null
$script:lastRamTemp = $null
$script:lastRamTempTime = $null  # Neuer Zeitstempel für RAM-Temperatur-Cache
$script:isUpdating = $false
$script:tooltipControl = $null
$script:gpuName = $null
$script:lastHardwareMonitorError = $null  # Speichert detaillierte Fehlermeldung vom DependencyChecker
$script:hardwareMonitorInitAttempted = $false  # Flag ob bereits versucht wurde zu initialisieren

# Neue Cache-Variablen für verbesserte Performance
$script:ramCache = $null
$script:lastGpuCounterUpdate = $null
$script:lastGpuCounterValue = $null
$script:updateCounter = 0

# Schwellenwerte für Hardware-Überwachung (werden aus Einstellungen geladen)
$script:cpuThreshold = 90  # Standard-CPU-Warnschwelle
$script:ramThreshold = 85  # Standard-RAM-Warnschwelle
$script:gpuThreshold = 80  # Standard-GPU-Warnschwelle

# Statistik-Tracking für Min/Max/Durchschnitt
$script:cpuStats = @{}
$script:gpuStats = @{}
$script:ramStats = @{}

# Automatische Zurücksetzung der Statistiken nach X Stunden
$script:statsResetInterval = [TimeSpan]::FromHours(24)

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

# Variablen für separates Debug-Fenster
$script:DebugWindowProcess = $null
$script:DebugWindowPath = $null

function Open-DebugWindow {
    param(
        [int]$Width = 80,
        [int]$Height = 30,
        [int]$PosX = 10,
        [int]$PosY = 10
    )
    
    try {
        # Prüfen ob bereits ein Debug-Fenster geöffnet ist
        if ($script:DebugWindowProcess) {
            try {
                if (-not $script:DebugWindowProcess.HasExited) {
                    Write-Host "Debug-Fenster ist bereits geöffnet" -ForegroundColor Yellow
                    return
                }
            } catch {
                # Prozess-Objekt existiert nicht mehr, weiter mit neuem Fenster
                Write-Verbose "Alter Prozess existiert nicht mehr, öffne neues Fenster"
                $script:DebugWindowProcess = $null
            }
        }
        
        # Temporäre Datei für Debug-Ausgaben erstellen
        $script:DebugWindowPath = Join-Path $env:TEMP "HardwareMonitor_Debug.log"
        
        # Wenn die Datei existiert, leeren
        if (Test-Path $script:DebugWindowPath) {
            Clear-Content $script:DebugWindowPath -ErrorAction SilentlyContinue
        } else {
            New-Item -Path $script:DebugWindowPath -ItemType File -Force -ErrorAction Stop | Out-Null
        }
        
        # Startinformationen in die Datei schreiben
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Add-Content -Path $script:DebugWindowPath -Value "=== Hardware Monitor Debug-Ausgaben ==="
        Add-Content -Path $script:DebugWindowPath -Value "=== Gestartet: $timestamp ==="
        Add-Content -Path $script:DebugWindowPath -Value ""
        
        # CMD-Fenster mit PowerShell starten, das die Log-Datei kontinuierlich anzeigt
        $cmdCommand = "mode con: cols=$Width lines=$Height & powershell -NoExit -Command `"Get-Content -Path '$script:DebugWindowPath' -Wait -Tail 100`""
        
        # Prozess-Startinfo konfigurieren
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = "cmd.exe"
        $psi.Arguments = "/c $cmdCommand"
        $psi.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Normal
        
        # Fenster starten
        $script:DebugWindowProcess = [System.Diagnostics.Process]::Start($psi)
        
        if ($script:DebugWindowProcess) {
            Write-Host "Debug-Fenster geöffnet (${Width}x${Height})" -ForegroundColor Green
            Start-Sleep -Milliseconds 500  # Kurze Pause, damit das Fenster Zeit hat zu öffnen
        } else {
            Write-Host "Fehler: Debug-Fenster konnte nicht geöffnet werden" -ForegroundColor Red
        }
    } catch {
        Write-Host "Fehler beim Öffnen des Debug-Fensters: $_" -ForegroundColor Red
        $script:DebugWindowProcess = $null
        $script:DebugWindowPath = $null
    }
}

function Close-DebugWindow {
    try {
        # Erst den Prozess beenden — sonst wirft Get-Content -Wait einen Fehler
        # wenn die Log-Datei danach gelöscht wird
        if ($script:DebugWindowProcess) {
            try {
                if (-not $script:DebugWindowProcess.HasExited) {
                    # /F = Force, /T = Prozessbaum inkl. Kind-Prozess (powershell -Wait)
                    $pid = $script:DebugWindowProcess.Id
                    & taskkill /F /T /PID $pid 2>$null | Out-Null
                    $script:DebugWindowProcess.WaitForExit(1000)
                    Write-Host "Debug-Fenster geschlossen" -ForegroundColor Yellow
                }
            } catch {
                Write-Verbose "Prozess konnte nicht beendet werden oder existiert bereits nicht mehr: $_"
            } finally {
                $script:DebugWindowProcess = $null
            }
        }
        
        # Dann temporäre Log-Datei löschen (Prozess ist jetzt bereits beendet)
        if ($script:DebugWindowPath) {
            try {
                if (Test-Path $script:DebugWindowPath) {
                    Remove-Item $script:DebugWindowPath -Force -ErrorAction SilentlyContinue
                }
            } catch {
                Write-Verbose "Konnte temporäre Debug-Datei nicht löschen: $_"
            } finally {
                $script:DebugWindowPath = $null
            }
        }
    } catch {
        Write-Verbose "Fehler beim Schließen des Debug-Fensters: $_"
        $script:DebugWindowProcess = $null
        $script:DebugWindowPath = $null
    }
}

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
            $timestamp = Get-Date -Format "HH:mm:ss"
            $formattedMessage = "[$timestamp] [$Component] $Message"
            
            # Wenn Debug-Fenster aktiv ist, in die Log-Datei schreiben
            if ($script:DebugWindowPath -and (Test-Path $script:DebugWindowPath)) {
                try {
                    Add-Content -Path $script:DebugWindowPath -Value $formattedMessage -ErrorAction Stop
                } catch {
                    # Fallback auf Konsole, wenn Datei-Zugriff fehlschlägt
                    Write-Host "[$Component] $Message" -ForegroundColor $(
                        switch ($Component) {
                            'CPU' { 'Cyan' }
                            'GPU' { 'Green' }
                            'RAM' { 'Yellow' }
                            default { 'White' }
                        }
                    )
                }
            } else {
                # Ansonsten in die normale Konsole schreiben
                Write-Host "[$Component] $Message" -ForegroundColor $(
                    switch ($Component) {
                        'CPU' { 'Cyan' }
                        'GPU' { 'Green' }
                        'RAM' { 'Yellow' }
                        default { 'White' }
                    }
                )
            }

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
                $infoText = @"

[CPU] === Hardware Information ===
[CPU] Name: $($cpuWmi.Name)
[CPU] Hersteller: $($cpuWmi.Manufacturer)
[CPU] Kerne: $($cpuWmi.NumberOfCores)
[CPU] Logische Prozessoren: $($cpuWmi.NumberOfLogicalProcessors)
[CPU] Basis Taktrate: $($cpuWmi.MaxClockSpeed) MHz
[CPU] ===========================
"@
                if ($script:DebugWindowPath -and (Test-Path $script:DebugWindowPath)) {
                    try {
                        Add-Content -Path $script:DebugWindowPath -Value $infoText -ErrorAction Stop
                    } catch {
                        # Fallback auf Konsole
                        Write-Host "`n[CPU] === Hardware Information ===" -ForegroundColor Cyan
                        Write-Host "[CPU] Name: $($cpuWmi.Name)" -ForegroundColor Cyan
                        Write-Host "[CPU] Hersteller: $($cpuWmi.Manufacturer)" -ForegroundColor Cyan
                        Write-Host "[CPU] Kerne: $($cpuWmi.NumberOfCores)" -ForegroundColor Cyan
                        Write-Host "[CPU] Logische Prozessoren: $($cpuWmi.NumberOfLogicalProcessors)" -ForegroundColor Cyan
                        Write-Host "[CPU] Basis Taktrate: $($cpuWmi.MaxClockSpeed) MHz" -ForegroundColor Cyan
                        Write-Host "[CPU] ===========================" -ForegroundColor Cyan
                    }
                } else {
                    Write-Host "`n[CPU] === Hardware Information ===" -ForegroundColor Cyan
                    Write-Host "[CPU] Name: $($cpuWmi.Name)" -ForegroundColor Cyan
                    Write-Host "[CPU] Hersteller: $($cpuWmi.Manufacturer)" -ForegroundColor Cyan
                    Write-Host "[CPU] Kerne: $($cpuWmi.NumberOfCores)" -ForegroundColor Cyan
                    Write-Host "[CPU] Logische Prozessoren: $($cpuWmi.NumberOfLogicalProcessors)" -ForegroundColor Cyan
                    Write-Host "[CPU] Basis Taktrate: $($cpuWmi.MaxClockSpeed) MHz" -ForegroundColor Cyan
                    Write-Host "[CPU] ===========================" -ForegroundColor Cyan
                }
                $script:cpuInfoShown = $true
            }
        }
        'GPU' {
            if (-not $script:gpuInfoShown) {
                $gpuWmi = Get-WmiObject -Class Win32_VideoController | Where-Object { $_.Name -match "NVIDIA|AMD|Radeon|GeForce|Intel.*Graphics" }
                $infoLines = @("`n[GPU] === Hardware Information ===")
                foreach ($gpu in $gpuWmi) {
                    $infoLines += "[GPU] Name: $($gpu.Name)"
                    $infoLines += "[GPU] Treiber Version: $($gpu.DriverVersion)"
                    $infoLines += "[GPU] Video RAM: $([math]::Round($gpu.AdapterRAM/1GB, 2)) GB"
                    $infoLines += "[GPU] Maximale Auflösung: $($gpu.MaxRefreshRate) Hz @ $($gpu.VideoModeDescription)"
                }
                $infoLines += "[GPU] ==========================="
                $infoText = $infoLines -join "`n"
                
                if ($script:DebugWindowPath -and (Test-Path $script:DebugWindowPath)) {
                    try {
                        Add-Content -Path $script:DebugWindowPath -Value $infoText -ErrorAction Stop
                    } catch {
                        # Fallback auf Konsole
                        Write-Host "`n[GPU] === Hardware Information ===" -ForegroundColor Green
                        foreach ($gpu in $gpuWmi) {
                            Write-Host "[GPU] Name: $($gpu.Name)" -ForegroundColor Green
                            Write-Host "[GPU] Treiber Version: $($gpu.DriverVersion)" -ForegroundColor Green
                            Write-Host "[GPU] Video RAM: $([math]::Round($gpu.AdapterRAM/1GB, 2)) GB" -ForegroundColor Green
                            Write-Host "[GPU] Maximale Auflösung: $($gpu.MaxRefreshRate) Hz @ $($gpu.VideoModeDescription)" -ForegroundColor Green
                        }
                        Write-Host "[GPU] ===========================" -ForegroundColor Green
                    }
                } else {
                    Write-Host "`n[GPU] === Hardware Information ===" -ForegroundColor Green
                    foreach ($gpu in $gpuWmi) {
                        Write-Host "[GPU] Name: $($gpu.Name)" -ForegroundColor Green
                        Write-Host "[GPU] Treiber Version: $($gpu.DriverVersion)" -ForegroundColor Green
                        Write-Host "[GPU] Video RAM: $([math]::Round($gpu.AdapterRAM/1GB, 2)) GB" -ForegroundColor Green
                        Write-Host "[GPU] Maximale Auflösung: $($gpu.MaxRefreshRate) Hz @ $($gpu.VideoModeDescription)" -ForegroundColor Green
                    }
                    Write-Host "[GPU] ===========================" -ForegroundColor Green
                }
                $script:gpuInfoShown = $true
            }
        }
        'RAM' {
            if (-not $script:ramInfoShown) {
                $ramInfo = Get-WmiObject -Class Win32_PhysicalMemory
                $infoLines = @("`n[RAM] === Hardware Information ===")
                $infoLines += "[RAM] Anzahl RAM-Module: $($ramInfo.Count)"
                foreach ($module in $ramInfo) {
                    $infoLines += "[RAM] -------------------"
                    $infoLines += "[RAM] Hersteller: $($module.Manufacturer)"
                    $infoLines += "[RAM] Teilenummer: $($module.PartNumber)"
                    $infoLines += "[RAM] Kapazität: $([math]::Round($module.Capacity/1GB, 2)) GB"
                    $infoLines += "[RAM] Nominale Geschwindigkeit: $($module.Speed) MHz"
                    $infoLines += "[RAM] Form Factor: $($module.FormFactor)"
                }
                $computerSystem = Get-WmiObject -Class Win32_ComputerSystem
                $totalRAM = [math]::Round($computerSystem.TotalPhysicalMemory / 1GB, 2)
                $infoLines += "[RAM] -------------------"
                $infoLines += "[RAM] Gesamter RAM: $totalRAM GB"
                $infoLines += "[RAM] ==========================="
                $infoText = $infoLines -join "`n"
                
                if ($script:DebugWindowPath -and (Test-Path $script:DebugWindowPath)) {
                    try {
                        Add-Content -Path $script:DebugWindowPath -Value $infoText -ErrorAction Stop
                    } catch {
                        # Fallback auf Konsole
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
                        Write-Host "[RAM] -------------------" -ForegroundColor Yellow
                        Write-Host "[RAM] Gesamter RAM: $totalRAM GB" -ForegroundColor Yellow
                        Write-Host "[RAM] ===========================" -ForegroundColor Yellow
                    }
                } else {
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
                    Write-Host "[RAM] -------------------" -ForegroundColor Yellow
                    Write-Host "[RAM] Gesamter RAM: $totalRAM GB" -ForegroundColor Yellow
                    Write-Host "[RAM] ===========================" -ForegroundColor Yellow
                }
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

    # Sensor-Info-Text zusammenstellen
    $infoLines = @("[$Component] === Aktuelle Sensor-Werte ===")
    foreach ($key in $SensorData.Keys) {
        $infoLines += "[$Component] $key : $($SensorData[$key])"
    }
    $infoLines += "[$Component] ==========================="
    $infoText = $infoLines -join "`n"
    
    # In Debug-Fenster oder Konsole ausgeben
    if ($script:DebugWindowPath -and (Test-Path $script:DebugWindowPath)) {
        try {
            Add-Content -Path $script:DebugWindowPath -Value $infoText -ErrorAction Stop
        } catch {
            # Fallback auf Konsole, wenn Datei-Zugriff fehlschlägt
            Write-Host "[$Component] === Aktuelle Sensor-Werte ===" -ForegroundColor $color
            foreach ($key in $SensorData.Keys) {
                Write-Host "[$Component] $key : $($SensorData[$key])" -ForegroundColor $color
            }
            Write-Host "[$Component] ===========================" -ForegroundColor $color
        }
    } else {
        Write-Host "[$Component] === Aktuelle Sensor-Werte ===" -ForegroundColor $color
        foreach ($key in $SensorData.Keys) {
            Write-Host "[$Component] $key : $($SensorData[$key])" -ForegroundColor $color
        }
        Write-Host "[$Component] ===========================" -ForegroundColor $color
    }
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
        [bool]$Enabled,
        [int]$WindowWidth = 100,
        [int]$WindowHeight = 40
    )
    
    $script:DebugMode = $Enabled
    $script:DebugModeCPU = $Enabled
    $script:DebugModeGPU = $Enabled
    $script:DebugModeRAM = $Enabled
    
    if ($Enabled) {
        # Debug-Fenster öffnen, wenn Debug aktiviert wird
        Open-DebugWindow -Width $WindowWidth -Height $WindowHeight
        $statusText = "Aktiviert (separates Fenster geöffnet)"
    } else {
        # Debug-Fenster schließen, wenn Debug deaktiviert wird
        Close-DebugWindow
        $statusText = "Deaktiviert"
    }
    
    Write-Host "Hardware Monitor Debug-Modus: $statusText"
}

function Set-HardwareDebugMode {
    param(
        [ValidateSet('CPU', 'GPU', 'RAM')]
        [string]$Component,
        [bool]$Enabled,
        [int]$WindowWidth = 100,
        [int]$WindowHeight = 40
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
    
    # Debug-Fenster öffnen/schließen basierend auf aktiven Debug-Modi
    $anyDebugActive = $script:DebugModeCPU -or $script:DebugModeGPU -or $script:DebugModeRAM
    
    if ($anyDebugActive -and $Enabled) {
        # Fenster öffnen, wenn noch nicht geöffnet
        $shouldOpenWindow = $false
        
        if (-not $script:DebugWindowProcess) {
            $shouldOpenWindow = $true
        } else {
            try {
                if ($script:DebugWindowProcess.HasExited) {
                    $shouldOpenWindow = $true
                }
            } catch {
                # Prozess-Objekt existiert nicht mehr
                $shouldOpenWindow = $true
            }
        }
        
        if ($shouldOpenWindow) {
            Open-DebugWindow -Width $WindowWidth -Height $WindowHeight
        }
    } elseif (-not $anyDebugActive) {
        # Fenster schließen, wenn kein Debug-Modus mehr aktiv ist
        Close-DebugWindow
    }
}

function Get-HardwareDebugState {
    param(
        [ValidateSet('CPU', 'GPU', 'RAM')]
        [string]$Component
    )
    
    switch ($Component) {
        'CPU' { return $script:DebugModeCPU }
        'GPU' { return $script:DebugModeGPU }
        'RAM' { return $script:DebugModeRAM }
        default { return $false }
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
    
    # Importiere ColorScheme-Modul, wenn noch nicht geladen
    # Direkte Farbdefinitionen anstelle von ColorScheme
    $normalColor = [System.Drawing.Color]::Green  # Standardgrün für normalen Zustand
    $warningColor = [System.Drawing.Color]::Gold  # Gelb für Warnung
    $criticalColor = [System.Drawing.Color]::Red  # Rot für kritischen Zustand
    
    # Komponenten-spezifische Schwellenwerte - verwende Einstellungen, falls verfügbar
    if ($Component -eq 'CPU') {
        $TempThresholds = @(75, 90)
        # Verwende benutzerdefinierten CPU-Schwellenwert aus Einstellungen
        $userThreshold = if ($script:cpuThreshold) { $script:cpuThreshold } else { 90 }
        $LoadThresholds = @(($userThreshold - 5), $userThreshold)
    } elseif ($Component -eq 'GPU') {
        $TempThresholds = @(75, 90)
        # Verwende benutzerdefinierten GPU-Schwellenwert aus Einstellungen
        $userThreshold = if ($script:gpuThreshold) { $script:gpuThreshold } else { 85 }
        $LoadThresholds = @(($userThreshold - 5), $userThreshold)
    } elseif ($Component -eq 'RAM') {
        $TempThresholds = @(60, 80)  # RAM hat in der Regel niedrigere Temperatur-Schwellenwerte
        # Verwende benutzerdefinierten RAM-Schwellenwert aus Einstellungen
        $userThreshold = if ($script:ramThreshold) { $script:ramThreshold } else { 85 }
        $LoadThresholds = @(($userThreshold - 5), $userThreshold)
    }
    
    # Hintergrundfarbberechnung mit Farben aus dem ColorScheme
    if ($Temperature -ge $TempThresholds[1] -or $Load -ge $LoadThresholds[1]) {
        # Kritischer Bereich (rot)
        if ($hardwareColors) {
            return $hardwareColors.$Component.Critical
        } else {
            return $criticalColor
        }
    } elseif ($Temperature -ge $TempThresholds[0] -or $Load -ge $LoadThresholds[0]) {
        # Warnbereich (gelb)
        if ($hardwareColors) {
            return $hardwareColors.$Component.Warning
        } else {
            return $warningColor
        }
    } else {
        # Normaler Bereich (grün)
        if ($hardwareColors) {
            return $hardwareColors.$Component.Light
        } else {
            return $normalColor
        }
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
        [System.Windows.Forms.Panel]$gbRAM,
        [System.Windows.Forms.ToolTip]$GlobalTooltip = $null
    )

    try {
        # Überprüfen und Initialisieren von LibreHardwareMonitor
        if ($null -eq $script:computerObj -or -not $script:useLibreHardware) {
            $script:computerObj = Initialize-LibreHardwareMonitor
            
            if ($null -eq $script:computerObj) {
                Write-Host "`n⚠️ HARDWARE-MONITORING DEAKTIVIERT" -ForegroundColor Yellow
                
                # Zeige detaillierte Fehlermeldung vom DependencyChecker
                if ($script:lastHardwareMonitorError) {
                    Write-Host $script:lastHardwareMonitorError -ForegroundColor Gray
                } else {
                    # Fallback für den Fall, dass keine detaillierte Meldung verfügbar ist
                    Write-Host "Hardware-Monitor konnte nicht initialisiert werden." -ForegroundColor Gray
                    Write-Host "Bitte prüfe:" -ForegroundColor Cyan
                    Write-Host "  - DLL-Dateien im Lib-Ordner vorhanden?" -ForegroundColor Gray
                    Write-Host "  - PawnIO-Treiber installiert und aktiv?" -ForegroundColor Gray
                    Write-Host "  - Administrator-Rechte vorhanden?" -ForegroundColor Gray
                }
                
                return $null
            }
            
            $script:useLibreHardware = $true
        }        # Tooltip für Hardware-Statistiken verwenden (globales ToolTip bevorzugen)
        if ($GlobalTooltip) {
            $script:tooltipControl = $GlobalTooltip
        } elseif (-not $script:tooltipControl) {
            $script:tooltipControl = New-Object System.Windows.Forms.ToolTip
            $script:tooltipControl.AutoPopDelay = 15000  # 15 Sekunden anzeigen
            $script:tooltipControl.InitialDelay = 100    # Schnellere Verzögerung
            $script:tooltipControl.ReshowDelay = 100     # Schnellere Verzögerung
            $script:tooltipControl.Active = $true
            $script:tooltipControl.IsBalloon = $true     # Balloon-Stil für bessere Sichtbarkeit
        }

        # Event-Handler für CPU-Label und Panel
        if ($cpuLabel) {
            $cpuLabel.Add_Click({
                    Show-HardwareStatsTable -Component 'CPU'
                })
        }
        
        if ($gbCPU) {
            $gbCPU.Add_Click({
                    Show-HardwareStatsTable -Component 'CPU'
                })
        }

        # Event-Handler für GPU-Label und Panel
        if ($gpuLabel) {
            $gpuLabel.Add_Click({
                    Show-HardwareStatsTable -Component 'GPU'
                })
        }
        
        if ($gbGPU) {
            $gbGPU.Add_Click({
                    Show-HardwareStatsTable -Component 'GPU'
                })
        }

        # Event-Handler für RAM-Label und Panel
        if ($ramLabel) {
            $ramLabel.Add_Click({
                    Show-HardwareStatsTable -Component 'RAM'
                })
        }
        
        if ($gbRAM) {
            $gbRAM.Add_Click({
                    Show-HardwareStatsTable -Component 'RAM'
                })
        }

        # Timer erstellen
        $timer = New-Object System.Windows.Forms.Timer
        $timer.Interval = 100  # Initial 100ms für schnellen ersten Tick, wird nach erstem Update auf 5000ms gesetzt
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
        } catch {
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
                        # LibreHardwareMonitor-Modus
                        # Hardware-Update IMMER durchführen (wichtig für Sensor-Daten!)
                        $script:computerObj.Hardware | ForEach-Object { $_.Update() }
                        
                        # CPU immer aktualisieren (wichtigster Sensor)
                        Update-CpuInfo -CpuLabel $cpuLabel -Panel $gbCPU
                        
                        # Beim ersten Mal (updateCounter == 1) ALLE Komponenten aktualisieren
                        # Danach alternierend für Performance
                        if ($script:updateCounter -eq 1) {
                            # Initialisierung: Alle Komponenten sofort laden
                            if ($gpuLabel -and $gbGPU) {
                                Update-GpuInfo -GpuLabel $gpuLabel -Panel $gbGPU
                            }
                            if ($ramLabel -and $gbRAM) {
                                Update-RamInfo -RamLabel $ramLabel -Panel $gbRAM
                            }
                            
                            # Nach erstem erfolgreichen Update: Timer-Interval auf 5 Sekunden zurücksetzen
                            if ($script:hardwareTimer) {
                                $script:hardwareTimer.Interval = 5000
                            }
                        } else {
                            # Normalbetrieb: GPU und RAM abwechselnd für Performance
                            if ($script:updateCounter % 2 -eq 0 -and $gpuLabel -and $gbGPU) {
                                Update-GpuInfo -GpuLabel $gpuLabel -Panel $gbGPU
                            } elseif ($script:updateCounter % 2 -eq 1 -and $ramLabel -and $gbRAM) {
                                Update-RamInfo -RamLabel $ramLabel -Panel $gbRAM
                            }
                        }
                        
                        # Zähler zurücksetzen nach 10 Durchläufen
                        if ($script:updateCounter -ge 10) {
                            $script:updateCounter = 0
                        }
                    }
                } catch {
                    Write-Warning "Fehler beim Hardware-Update: $_"
                } finally {
                    $script:isUpdating = $false
                }
            })

        return $timer
    } catch {
        Write-Warning "Fehler beim Initialisieren des Live-Monitorings: $_"
        return $null
    }
}

function Initialize-LibreHardwareMonitor {
    # Wenn bereits initialisiert, Computer-Objekt zurückgeben
    if ($null -ne $script:computerObj -and $script:useLibreHardware) {
        return $script:computerObj
    }
    
    # Wenn bereits ein fehlgeschlagener Initialisierungsversuch stattgefunden hat, nicht erneut versuchen
    if ($script:hardwareMonitorInitAttempted -and $null -eq $script:computerObj) {
        Write-Verbose "Hardware-Monitor-Initialisierung wurde bereits versucht und ist fehlgeschlagen"
        return $null
    }
    
    # Markiere dass ein Initialisierungsversuch stattfindet
    $script:hardwareMonitorInitAttempted = $true

    # Importiere DependencyChecker für zentrale Entscheidung
    if (-not (Get-Command -Name 'Initialize-HardwareMonitoringMode' -ErrorAction SilentlyContinue)) {
        Import-Module "$PSScriptRoot\..\Core\DependencyChecker.psm1" -Force -ErrorAction SilentlyContinue
    }
    
    Write-Verbose "Prüfe Hardware-Monitor-Verfügbarkeit..."
    
    # ZENTRALE ENTSCHEIDUNG durch DependencyChecker (mit ProgressBar falls verfügbar)
    # StatusLabel nicht übergeben da es ein ToolStripStatusLabel sein könnte (Typ-Inkompatibel)
    $hwStatus = Initialize-HardwareMonitoringMode -ProgressBar $progressBar -StatusLabel $null
    
    if (-not $hwStatus.Available) {
        # Hardware-Monitor NICHT verfügbar - speichere detaillierte Meldung für spätere Verwendung
        $script:lastHardwareMonitorError = $hwStatus.Message
        
        # Zeige detaillierte Fehlermeldung wenn DLLs fehlen (nur beim ersten Versuch!)
        if ($hwStatus.MissingDLLs.Count -gt 0 -and -not $SuppressVisualFeedback) {
            # Zeige fehlende DLLs an
            $missingList = ($hwStatus.MissingDLLs | ForEach-Object { "  - $($_.FileName)`n    ($($_.Description))" }) -join "`n"
            [System.Windows.Forms.MessageBox]::Show(
                "Hardware-Monitor kann nicht gestartet werden.`n`n" +
                "Fehlende Dateien im Lib-Ordner:`n$missingList`n`n" +
                "Bitte alle benötigten DLL-Dateien im Lib-Ordner bereitstellen.",
                "Hardware-Monitor nicht verfügbar",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Warning
            )
        }
        
        Write-Verbose "Hardware-Monitor nicht verfügbar: $($hwStatus.Message)"
        
        $script:computerObj = $null
        $script:useLibreHardware = $false
        
        return $null
    }
    
    # Hardware-Monitor verfügbar - Computer-Objekt erstellen
    Write-Verbose "✓ $($hwStatus.Message)"
    
    try {
        # DLL ist bereits geladen durch Initialize-HardwareMonitoringMode
        $script:computerObj = New-Object LibreHardwareMonitor.Hardware.Computer
        
        # Hardware-Funktionen aktivieren
        $script:computerObj.IsCpuEnabled = $true
        $script:computerObj.IsGpuEnabled = $true
        $script:computerObj.IsMotherboardEnabled = $true
        $script:computerObj.IsMemoryEnabled = $true
        $script:computerObj.IsStorageEnabled = $false
        $script:computerObj.IsNetworkEnabled = $false
        $script:computerObj.IsControllerEnabled = $false
        
        # Computer öffnen
        $script:computerObj.Open()
        $script:useLibreHardware = $true
        
        Write-Verbose "Hardware-Monitor erfolgreich initialisiert"
        return $script:computerObj
    } catch {
        Write-Warning "Fehler beim Initialisieren: $_"
        
        # Bei Fehler: Deaktivieren
        $script:computerObj = $null
        $script:useLibreHardware = $false
        
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
            } catch {
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
    } catch {
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
        [int]$LoadDelayMs = 0,
        [System.Windows.Forms.ToolTip]$GlobalTooltip = $null
    )
    
    # Farbdefinitionen für Ladevisualisierung
    $primaryColor = [System.ConsoleColor]::Cyan
    $secondaryColor = [System.ConsoleColor]::Yellow
    $accentColor = [System.ConsoleColor]::Green
    
    if (-not $SuppressVisualFeedback) {
        Write-Host "`n[+]GUI wird initialisiert..." -ForegroundColor $accentColor
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
            
            # Komponente initialisieren basierend auf dem Namen
            switch ($component.Name) {
                "LibreHardwareMonitor-Bibliothek" {
                    $script:computerObj = Initialize-LibreHardwareMonitor
                    if ($null -eq $script:computerObj) {
                        Write-Host "`n[ℹ] Hardware-Monitoring deaktiviert - LibreHardwareMonitor + PawnIO nicht verfügbar" -ForegroundColor Yellow
                        # Kein Fehler - einfach ohne Hardware-Monitor weitermachen
                    } else {
                        $script:useLibreHardware = $true
                    }
                    # Sleep nur bei visueller Konsolen-Ausgabe (für Progressbar-Animation)
                    if (-not $SuppressVisualFeedback) { Start-Sleep -Milliseconds 200 }
                }
                "CPU-Monitor" {
                    if ($cpuLabel -and $gbCPU) {
                        # CPU-Panel zurücksetzen
                        $gbCPU.BackColor = [System.Drawing.Color]::LightGray
                        $cpuLabel.Text = "CPU-Daten werden geladen..."
                    }
                    if (-not $SuppressVisualFeedback) { Start-Sleep -Milliseconds 200 }
                }
                "GPU-Monitor" {
                    if ($gpuLabel -and $gbGPU) {
                        # GPU-Panel zurücksetzen
                        $gbGPU.BackColor = [System.Drawing.Color]::LightGray
                        $gpuLabel.Text = "GPU-Daten werden geladen..."
                    }
                    if (-not $SuppressVisualFeedback) { Start-Sleep -Milliseconds 200 }
                }
                "RAM-Monitor" {
                    if ($ramLabel -and $gbRAM) {
                        # RAM-Panel zurücksetzen
                        $gbRAM.BackColor = [System.Drawing.Color]::LightGray
                        $ramLabel.Text = "RAM-Daten werden geladen..."
                    }
                    if (-not $SuppressVisualFeedback) { Start-Sleep -Milliseconds 200 }
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
                        -gbRAM $gbRAM `
                        -GlobalTooltip $GlobalTooltip
                    
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
                            Write-Host "`r`t├─ GUI-Synchronisierung abgeschlossen." -ForegroundColor $accentColor                            # Prüfe, ob die Datenbankverbindung initialisiert wurde
                            # Da die Datenbank im Hauptskript initialisiert wird, müssen wir global prüfen
                            $null = $globalDB = $null -ne (Get-Variable -Name dbConnection -Scope Global -ErrorAction SilentlyContinue)
                            $null = $scriptDB = $null -ne (Get-Variable -Name dbConnection -Scope Script -ErrorAction SilentlyContinue)
                            
                            if ($globalDB -or $scriptDB) {
                                Write-Host "`r`t├─ Datenbankverbindung erfolgreich initialisiert!" -ForegroundColor Green
                            }
                            # Prüfe, ob die Einstellungen angewendet wurden
                            $null = $globalSettings = $null -ne (Get-Variable -Name settings -Scope Global -ErrorAction SilentlyContinue)
                            $null = $scriptSettings = $null -ne (Get-Variable -Name settings -Scope Script -ErrorAction SilentlyContinue)
                            
                            if ($globalSettings -or $scriptSettings) {
                                Write-Host "`r`t├─ Einstellungen wurden erfolgreich angewendet." -ForegroundColor Green
                            }
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
            # Wenn kein Hardware-Monitor verfügbar → Panels deaktivieren
            if (-not $script:useLibreHardware) {
                if (-not $SuppressVisualFeedback) {
                    Write-Host "`r`t[ℹ] Hardware-Monitoring nicht verfügbar - Panels werden deaktiviert" -ForegroundColor Yellow
                }
                
                # Deaktiviere Hardware-Panels
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
                
                # Setze Labels auf "Deaktiviert"
                if ($cpuLabel) { $cpuLabel.Text = "Hardware-Monitoring deaktiviert" }
                if ($gpuLabel) { $gpuLabel.Text = "Hardware-Monitoring deaktiviert" }
                if ($ramLabel) { $ramLabel.Text = "Hardware-Monitoring deaktiviert" }
                
                return $true
            }
            
            Write-Warning "`r`t[i]Hardware-Timer konnte nicht initialisiert werden!" -ForegroundColor Red
            return $false
        } elseif (-not $timerStatus.Running) {
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
            if ($script:DebugModeCPU) {
                Write-DebugOutput -Component 'CPU' -Message "LibreHardwareMonitor nicht initialisiert - verwende Fallback" -Force
            }
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
        $coreMaxSensor = $cpuName.Sensors | Where-Object { $_.SensorType -eq "Temperature" -and $_.Name -eq "Core Max" } | Select-Object -First 1
        $coreMinSensor = $cpuName.Sensors | Where-Object { $_.SensorType -eq "Temperature" -and $_.Name -eq "Core Min" } | Select-Object -First 1
        $loadSensor = $cpuName.Sensors | Where-Object { $_.SensorType -eq "Load" -and $_.Name -eq "CPU Total" } | Select-Object -First 1
        $powerSensor = $cpuName.Sensors | Where-Object { $_.SensorType -eq "Power" -and $_.Name -match "Package|CPU Package" } | Select-Object -First 1
        $powerCoresSensor = $cpuName.Sensors | Where-Object { $_.SensorType -eq "Power" -and $_.Name -eq "CPU Cores" } | Select-Object -First 1
        $clockSensor = $cpuName.Sensors | Where-Object { $_.SensorType -eq "Clock" -and $_.Name -match "Core \(Average\)|Core #1" } | Select-Object -First 1
        $vcoreSensor = $cpuName.Sensors | Where-Object { $_.SensorType -eq "Voltage" -and $_.Name -match "CPU Core Voltage|VID" } | Select-Object -First 1
        
        $temp = if ($tempSensor) { [math]::Round($tempSensor.Value, 0) }            else { $null }
        $coreMax = if ($coreMaxSensor) { [math]::Round($coreMaxSensor.Value, 0) }         else { $null }
        $coreMin = if ($coreMinSensor) { [math]::Round($coreMinSensor.Value, 0) }         else { $null }
        $load = if ($loadSensor) { [math]::Round($loadSensor.Value, 0) }             else { $null }
        $power = if ($powerSensor) { [math]::Round($powerSensor.Value, 0) }            else { $null }
        $powerCores = if ($powerCoresSensor) { [math]::Round($powerCoresSensor.Value, 0) }      else { $null }
        $clock = if ($clockSensor) { [math]::Round($clockSensor.Value / 1000, 2) }    else { $null }
        $vcore = if ($vcoreSensor) { [math]::Round($vcoreSensor.Value, 3) }           else { $null }
        
        # Statistik-Daten aktualisieren (inkl. erweiterter CPU-Werte für Statistik-Popup)
        if ($temp) { Update-HardwareStats -Component 'CPU' -Property 'Temp'       -Value $temp }
        if ($coreMax) { Update-HardwareStats -Component 'CPU' -Property 'CoreMax'    -Value $coreMax }
        if ($coreMin) { Update-HardwareStats -Component 'CPU' -Property 'CoreMin'    -Value $coreMin }
        if ($load) { Update-HardwareStats -Component 'CPU' -Property 'Load'       -Value $load }
        if ($power) { Update-HardwareStats -Component 'CPU' -Property 'Power'      -Value $power }
        if ($powerCores) { Update-HardwareStats -Component 'CPU' -Property 'PowerCores' -Value $powerCores }
        if ($clock) { Update-HardwareStats -Component 'CPU' -Property 'Clock'      -Value $clock }
        if ($vcore) { Update-HardwareStats -Component 'CPU' -Property 'VCore'      -Value $vcore }
        
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
            $warningColor = Get-WarningColor -Temperature $temp -Load $load -Component 'CPU'
            if ($Panel.BackColor -ne $warningColor) {
                $Panel.BackColor = $warningColor
            }
        }
        
        # Debug-Ausgabe nur wenn Debug aktiv
        if ($script:DebugModeCPU) {
            Write-DebugOutput -Component 'CPU' -Message "T: $(if ($temp) { "$temp°C" } else { "N/A" }) | L: $(if ($load) { "$load%" } else { "N/A" }) | P: $(if ($power) { "$power W" } else { "N/A" }) | C: $(if ($clock) { "$clock GHz" } else { "N/A" })"
        }
    } catch {
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
            if ($script:DebugModeGPU) {
                Write-DebugOutput -Component 'GPU' -Message "LibreHardwareMonitor nicht initialisiert - verwende Fallback" -Force
            }
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
        $hotspot = $null
        $memTemp = $null
        $memLoad = $null
        $memUsed = $null
        $fanRpm = $null
        
        foreach ($gpu in $gpuHardware) {
            $gpu.Update()
                    
            foreach ($sensor in $gpu.Sensors) {
                switch ($sensor.SensorType) {
                    "Temperature" {
                        if ($sensor.Name -eq "GPU Core") { $temp = [Math]::Round($sensor.Value, 1) }
                        elseif ($sensor.Name -match "GPU Hot ?Spot") { $hotspot = [Math]::Round($sensor.Value, 1) }
                        elseif ($sensor.Name -match "GPU Memory Junction|GPU Memory$|GPU VRAM") { $memTemp = [Math]::Round($sensor.Value, 1) }
                    }
                    "Load" {
                        if ($sensor.Name -eq "GPU Core") { $load = [Math]::Round($sensor.Value, 0) }
                        elseif ($sensor.Name -match "GPU Memory Controller") { $memLoad = [Math]::Round($sensor.Value, 0) }
                    }
                    "Power" {
                        if ($sensor.Name -eq "GPU Package") { $power = [Math]::Round($sensor.Value, 0) }
                    }
                    "Clock" {
                        if ($sensor.Name -eq "GPU Core") { $clock = [Math]::Round($sensor.Value, 0) }
                    }
                    "SmallData" {
                        if ($sensor.Name -match "GPU Memory Used") { $memUsed = [Math]::Round($sensor.Value / 1024, 1) }  # MB -> GB
                    }
                    "Fan" {
                        if ($sensor.Name -match "GPU Fan 1|Fan 1") { $fanRpm = [Math]::Round($sensor.Value, 0) }
                    }
                }
            }
            
            # Nur die erste GPU verwenden
            break
        }
        
        # Statistik-Daten aktualisieren (inkl. erweiterter GPU-Werte für Statistik-Popup)
        # Clock: MHz -> GHz für konsistente Darstellung in der Statistik-Tabelle
        $clockGhzStat = if ($clock) { [Math]::Round($clock / 1000, 2) } else { $null }
        if ($temp) { Update-HardwareStats -Component 'GPU' -Property 'Temp'    -Value $temp }
        if ($hotspot) { Update-HardwareStats -Component 'GPU' -Property 'HotSpot' -Value $hotspot }
        if ($memTemp) { Update-HardwareStats -Component 'GPU' -Property 'MemTemp' -Value $memTemp }
        if ($load) { Update-HardwareStats -Component 'GPU' -Property 'Load'    -Value $load }
        if ($memLoad) { Update-HardwareStats -Component 'GPU' -Property 'MemLoad' -Value $memLoad }
        if ($power) { Update-HardwareStats -Component 'GPU' -Property 'Power'   -Value $power }
        if ($clockGhzStat) { Update-HardwareStats -Component 'GPU' -Property 'Clock'   -Value $clockGhzStat }
        if ($memUsed) { Update-HardwareStats -Component 'GPU' -Property 'MemUsed' -Value $memUsed }
        if ($fanRpm) { Update-HardwareStats -Component 'GPU' -Property 'Fan'     -Value $fanRpm }
        
        # Debug-Ausgabe der Sensordaten nur wenn Debug aktiv
        if ($script:DebugModeGPU) {
            $clockGHz = if ($clock) { [Math]::Round($clock / 1000, 2) } else { $null }
            $sensorData = @{
                "Temperatur" = $(if ($temp) { "$temp °C" } else { "N/A" })
                "Auslastung" = $(if ($load) { "$load %" } else { "N/A" })
                "Leistung"   = $(if ($power) { "$power W" } else { "N/A" })
                "Takt"       = $(if ($clockGHz) { "$clockGHz GHz" } else { "N/A" })
            }
            Write-SensorInfo -Component 'GPU' -SensorData $sensorData
        }
        
        if ($null -ne $temp -and $null -ne $load -and $null -ne $power -and $null -ne $clock) {
            # Formatiere den Takt in GHz für die Anzeige
            $clockGHz = [Math]::Round($clock / 1000, 2)
            $GpuLabel.Text = "$load% | $temp°C | $power W | $clockGHz GHz"
            
            # Berechne Panel-Farbe basierend auf der GPU-Temperatur und Last
            $Panel.BackColor = Get-WarningColor -Temperature $temp -Load $load -Component 'GPU'
            
            # Debug-Ausgabe nur wenn Debug aktiv
            if ($script:DebugModeGPU) {
                Write-DebugOutput -Component 'GPU' -Message "T: $(if ($temp) { "$temp°C" } else { "N/A" }) | L: $(if ($load) { "$load%" } else { "N/A" }) | P: $(if ($power) { "$power W" } else { "N/A" }) | C: $(if ($clockGHz) { "$clockGHz GHz" } else { "N/A" })"
            }
        } else {
            Write-DebugOutput -Component 'GPU' -Message "Keine vollständigen GPU-Daten verfügbar" -Force
            $GpuLabel.Text = "GPU-Daten nicht verfügbar"
            $Panel.BackColor = [System.Drawing.Color]::LightGray
        }
    } catch {
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
        } catch {
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
            } catch {
                if ($script:DebugModeGPU) {
                    Write-DebugOutput -Component 'GPU' -Message "Fehler bei WMI-GPU: $_"
                }
            }
        }
        
        # Wenn alles versagt, letzten Wert zurückgeben oder null
        return $script:lastGpuCounterValue
    } catch {
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
            if ($script:DebugModeRAM) {
                Write-DebugOutput -Component 'RAM' -Message "LibreHardwareMonitor nicht initialisiert - verwende Fallback" -Force
            }
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
                $totalMemory = [math]::Round($osMemory.TotalVisibleMemorySize / 1MB, 0)
                $freeMemory = [math]::Round($osMemory.FreePhysicalMemory / 1MB, 0)
                $usedMemory = [math]::Round($totalMemory - $freeMemory, 0)
                $usedPercentage = [math]::Round(($usedMemory / $totalMemory) * 100, 0)

                # RAM-Temperatur nach Bedarf - weniger priorisiert
                if ($script:updateCounter % 5 -eq 0) {
                    $ramTemp = Get-RamTemperature
                } else {
                    $ramTemp = $script:lastRamTemp  # Wiederverwendung des letzten Werts
                }

                # Werte für spätere Verwendung cachen
                $script:ramCache = @{
                    TotalMemory    = $totalMemory
                    FreeMemory     = $freeMemory
                    UsedMemory     = $usedMemory
                    UsedPercentage = $usedPercentage
                    RamTemp        = $ramTemp
                }
            } else {
                # Wenn WMI-Abfrage fehlschlägt, vorherige Werte verwenden
                if (-not $script:ramCache) {
                    Write-DebugOutput -Component 'RAM' -Message "Keine RAM-Informationen verfügbar" -Force
                    return
                }
            }
        }
        
        # Cache-Werte abrufen
        $totalMemory = $script:ramCache.TotalMemory
        $freeMemory = $script:ramCache.FreeMemory
        $usedMemory = $script:ramCache.UsedMemory
        $usedPercentage = $script:ramCache.UsedPercentage
        $ramTemp = $script:ramCache.RamTemp
        
        # Statistik-Daten aktualisieren (inkl. erweiterter RAM-Werte für Statistik-Popup)
        if ($ramTemp) { Update-HardwareStats -Component 'RAM' -Property 'Temp' -Value $ramTemp }
        if ($usedPercentage) { Update-HardwareStats -Component 'RAM' -Property 'Load' -Value $usedPercentage }
        if ($usedMemory) { Update-HardwareStats -Component 'RAM' -Property 'Used' -Value $usedMemory }
        if ($freeMemory) { Update-HardwareStats -Component 'RAM' -Property 'Free' -Value $freeMemory }
        # Einzel-DIMM-Temperaturen (falls von LHM geliefert)
        if ($script:ramStats.SPD -and $script:ramStats.SPD.DimmSensors) {
            foreach ($dimm in $script:ramStats.SPD.DimmSensors) {
                # "DIMM #1" -> "DIMM1" als sauberer Property-Key
                $dimmKey = $dimm.Name -replace '[^A-Za-z0-9]', ''
                if ($dimm.Value -gt 0) {
                    Update-HardwareStats -Component 'RAM' -Property $dimmKey -Value $dimm.Value
                }
            }
        }
        
        # Debug-Ausgabe der Sensordaten nur wenn Debug aktiv
        if ($script:DebugModeRAM) {
            $sensorData = @{
                "Gesamt"     = "$totalMemory GB"
                "Verwendet"  = "$usedMemory GB"
                "Frei"       = "$([math]::Round($totalMemory - $usedMemory, 0)) GB"
                "Auslastung" = "$usedPercentage %"
                "Temperatur" = $(if ($ramTemp) { "$ramTemp °C" } else { "N/A" })
            }
            
            # Füge SPD Hub-Details hinzu, wenn verfügbar
            if ($script:ramStats.SPD -and $script:ramStats.SPD.Min -lt 999) {
                $sensorData["SPD Hub Min"] = "$([math]::Round($script:ramStats.SPD.Min, 0)) °C"
                $sensorData["SPD Hub Avg"] = "$([math]::Round($script:ramStats.SPD.Avg, 0)) °C"
                $sensorData["SPD Hub Max"] = "$([math]::Round($script:ramStats.SPD.Max, 0)) °C"
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
                    $ramLabelText += " (Min: $([math]::Round($script:ramStats.SPD.Min, 0))°C, Avg: $([math]::Round($script:ramStats.SPD.Avg, 0))°C, Max: $([math]::Round($script:ramStats.SPD.Max, 0))°C)"
                }
            } else {
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
                        } else {
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
            $warningColor = Get-WarningColor -Temperature $ramTemp -Load $usedPercentage -Component 'RAM'
            if ($Panel.BackColor -ne $warningColor) {
                $Panel.BackColor = $warningColor
            }
            
            # Klick-Handler für das RAM-Panel hinzufügen, wenn noch nicht vorhanden
            if ($null -eq $Panel.Tag -or $Panel.Tag -ne "SPDClickHandlerAdded") {
                $Panel.Cursor = [System.Windows.Forms.Cursors]::Hand
                $Panel.Tag = "SPDClickHandlerAdded"
                $Panel.Add_Click({
                        if ($script:ramStats.SPD -and $script:ramStats.SPD.FoundSensors) {
                            Show-RamSPDTempDetails -SPDData $script:ramStats.SPD
                        } else {
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
            Write-DebugOutput -Component 'RAM' -Message "T: $(if ($ramTemp) { "$ramTemp°C" } else { "N/A" }) | L: $(if ($usedPercentage) { "$usedPercentage%" } else { "N/A" }) | V: $(if ($usedMemory) { "$usedMemory GB" } else { "N/A" }) | G: $(if ($totalMemory) { "$totalMemory GB" } else { "N/A" })"
        }
    } catch {
        Write-DebugOutput -Component 'RAM' -Message "Fehler: $_" -Force
    }
}

# Get-RamTemperatureFromRegistry wurde entfernt - HWiNFO Registry-Integration nicht mehr unterstützt

function Get-RamTemperature {
    <#
    .SYNOPSIS
        Ermittelt die Temperatur des Arbeitsspeichers (RAM) über verschiedene Methoden.
    
    .DESCRIPTION
        Diese Funktion versucht, die RAM-Temperatur über mehrere verschiedene Quellen zu ermitteln:
        1. LibreHardwareMonitor-Sensoren (Memory und Mainboard)
        2. SMBus-Direktzugriff
        
        Die Funktion implementiert ein intelligentes Caching und liefert detaillierte Debuginformationen.
    
    .OUTPUTS
        System.Double - Die RAM-Temperatur in Grad Celsius oder $null, wenn keine Temperatur ermittelt werden konnte.
    #>
    
    try {
        # Grundprüfung: LibreHardwareMonitor muss initialisiert sein
        if (-not $script:useLibreHardware -or $null -eq $script:computerObj) {
            if ($script:DebugModeRAM) {
                Write-DebugOutput -Component 'RAM' -Message "LibreHardwareMonitor nicht initialisiert - RAM-Temperatur nicht verfügbar" -Force
            }
            return $null
        }
        
        # Cache-Check mit Zeitstempel (5 Sekunden Gültigkeit)
        $now = Get-Date
        if ($script:lastRamTemp -and $script:lastRamTempTime -and 
            ($now - $script:lastRamTempTime).TotalSeconds -lt 5) {
            
            if ($script:DebugModeRAM) {
                $cacheAge = [math]::Round(($now - $script:lastRamTempTime).TotalSeconds, 1)
                Write-DebugOutput -Component 'RAM' -Message "Cache verwendet: $($script:lastRamTemp)°C (Alter: ${cacheAge}s)" -Force
            }
            return $script:lastRamTemp
        }
        
        # Struktur für die Sensordaten (wird von mehreren Methoden verwendet)
        $ramTempData = @{
            FoundSensors = $false
            Source       = "Unbekannt"
            Values       = @()
            Min          = $null
            Max          = $null
            Avg          = $null
            Current      = $null
        }
        
        # Log-Nachricht für Start der Temperaturerfassung
        if ($script:DebugModeRAM) {
            Write-DebugOutput -Component 'RAM' -Message "Starte RAM-Temperaturermittlung..." -Force
        }
        
        #region METHODE 1: LibreHardwareMonitor direkt (höchste Priorität)
        # Aktualisiere alle Hardware-Komponenten für aktuelle Daten
        if ($script:DebugModeRAM) {
            Write-DebugOutput -Component 'RAM' -Message "Methode 1: LibreHardwareMonitor - Aktualisiere Hardware-Komponenten" -Force
        }
        
        # Aktuelle Daten sicherstellen
        $script:computerObj.Hardware | ForEach-Object { $_.Update() }
        
        # Für Debug: Liste aller verfügbaren Temperatursensoren erstellen
        if ($script:DebugModeRAM) {
            $allTempSensors = @()
            
            # Alle Temperatursensoren sammeln
            $script:computerObj.Hardware | ForEach-Object {
                $hw = $_
                $_.Sensors | Where-Object { $_.SensorType -eq "Temperature" } | ForEach-Object {
                    $allTempSensors += [PSCustomObject]@{
                        HardwareType = $hw.HardwareType
                        HardwareName = $hw.Name
                        SensorName   = $_.Name
                        Value        = $_.Value
                        Identifier   = $_.Identifier
                    }
                }
            }
            
            # Debug: Zeige alle Temperatursensoren
            Write-DebugOutput -Component 'RAM' -Message "Verfügbare Temperatursensoren (Gesamt: $($allTempSensors.Count)):" -Force
            foreach ($sensor in $allTempSensors) {
                if ($sensor.Value -gt 0) {
                    # Nur aktive Sensoren anzeigen
                    Write-DebugOutput -Component 'RAM' -Message "  $($sensor.HardwareType) - $($sensor.SensorName): $($sensor.Value)°C" -Force
                }
            }
        }
        
        # METHODE 1.1: Suche in Memory-Hardware (erste Suboption)
        $memoryHardware = $script:computerObj.Hardware | Where-Object { $_.HardwareType -eq "Memory" }
        
        if ($memoryHardware) {
            if ($script:DebugModeRAM) {
                Write-DebugOutput -Component 'RAM' -Message "Memory-Hardware gefunden: $($memoryHardware.Count) Instanz(en)" -Force
            }
            
            # RAM-Temperatursensoren identifizieren
            $ramTempValues = @()
            $dimmSensors = @()
            
            foreach ($memory in $memoryHardware) {
                $memory.Update()  # Aktualisieren
                
                # Verbesserte Sensor-Pattern für RAM-Temperaturen
                $ramTempSensors = $memory.Sensors | Where-Object { 
                    $_.SensorType -eq "Temperature" -and (
                        # Erweiterte Muster für RAM-Sensoren
                        $_.Name -match "SPD" -or
                        $_.Name -match "DIMM\s*#?\d+" -or
                        $_.Name -match "Memory" -or
                        $_.Name -match "RAM" -or
                        $_.Name -match "Speicher" -or
                        $_.Name -match "BANK\s*#?\d+" -or
                        $_.Name -match "Module\s*\d+" -or
                        $_.Name -match "Channel\s*[A-D]" -or
                        $_.Name -match "DDR[45]" -or
                        $_.Identifier -match "/dimm\d*/temperature" -or
                        $_.Identifier -match "/temperature/\d+"
                    )
                }
                
                # Debug: Zeige gefundene RAM-Sensoren
                if ($script:DebugModeRAM -and $ramTempSensors) {
                    Write-DebugOutput -Component 'RAM' -Message "RAM-Temperatursensoren gefunden: $($ramTempSensors.Count)" -Force
                    foreach ($s in $ramTempSensors) {
                        Write-DebugOutput -Component 'RAM' -Message "  Sensor: $($s.Name) = $($s.Value)°C [ID: $($s.Identifier)]" -Force
                    }
                }
                
                # Valide Temperaturwerte sammeln (inkl. pro-DIMM-Detail für Popup)
                foreach ($sensor in $ramTempSensors) {
                    if ($sensor.Value -gt 10 -and $sensor.Value -lt 100) {
                        $ramTempValues += $sensor.Value
                        $dimmSensors += @{ Name = $sensor.Name; Value = [math]::Round($sensor.Value, 2) }
                    }
                }
            }
            
            # Wenn RAM-Temperaturwerte gefunden wurden, verarbeiten und zurückgeben
            if ($ramTempValues.Count -gt 0) {
                $ramTempData.FoundSensors = $true
                $ramTempData.Source = "LibreHardwareMonitor (DDR5)"
                $ramTempData.Values = $ramTempValues
                $ramTempData.DimmSensors = $dimmSensors
                $ramTempData.Min = [math]::Round(($ramTempValues | Measure-Object -Minimum).Minimum, 1)
                $ramTempData.Max = [math]::Round(($ramTempValues | Measure-Object -Maximum).Maximum, 1)
                $ramTempData.Avg = [math]::Round(($ramTempValues | Measure-Object -Average).Average, 1)
                $ramTempData.Current = $ramTempData.Max
                
                # RAM-Statistik speichern — .LHM für interne Nutzung, .SPD aktiviert das Details-Popup
                $script:ramStats.LHM = $ramTempData
                $script:ramStats.SPD = $ramTempData
                $script:lastRamTemp = $ramTempData.Current
                $script:lastRamTempTime = $now
                
                if ($script:DebugModeRAM) {
                    Write-DebugOutput -Component 'RAM' -Message "LibreHardwareMonitor (DDR5): RAM-Temperatur = $($ramTempData.Current)°C ($($dimmSensors.Count) DIMMs)" -Force
                }
                
                return $script:lastRamTemp
            }
        }
        
        # METHODE 1.2: Suche nach RAM-Temperatursensoren auf dem Mainboard (zweite Suboption)
        if ($script:DebugModeRAM) {
            Write-DebugOutput -Component 'RAM' -Message "Suche nach RAM-Temperatursensoren auf dem Mainboard" -Force
        }
        
        $motherboardHardware = $script:computerObj.Hardware | Where-Object { $_.HardwareType -eq "Motherboard" }
        
        if ($motherboardHardware) {
            $mbRamTempValues = @()
            
            foreach ($mb in $motherboardHardware) {
                $mb.Update()
                
                # Verbesserte Sensorerkennung für RAM-Temperaturen auf dem Mainboard
                $mbRamSensors = $mb.Sensors | Where-Object { 
                    $_.SensorType -eq "Temperature" -and (
                        # Erweiterte Muster für RAM-Sensoren auf dem Mainboard
                        $_.Name -match "RAM|DIMM|Memory|Speicher|SPD|DDR[45]" -or
                        $_.Name -match "BANK\s*#?\d+" -or
                        $_.Name -match "Channel\s*[A-D]|Slot\s*\d+"
                    )
                }
                
                # Debug-Ausgabe
                if ($script:DebugModeRAM -and $mbRamSensors) {
                    Write-DebugOutput -Component 'RAM' -Message "RAM-Sensoren auf Mainboard gefunden: $($mbRamSensors.Count)" -Force
                    foreach ($s in $mbRamSensors) {
                        Write-DebugOutput -Component 'RAM' -Message "  Sensor: $($s.Name) = $($s.Value)°C [ID: $($s.Identifier)]" -Force
                    }
                }
                
                # Verarbeite gültige Werte
                foreach ($sensor in $mbRamSensors) {
                    if ($sensor.Value -gt 10 -and $sensor.Value -lt 100) {
                        $mbRamTempValues += $sensor.Value
                    }
                }
            }
            
            # Wenn RAM-Temperaturwerte auf dem Mainboard gefunden wurden
            if ($mbRamTempValues.Count -gt 0) {
                $ramTempData.FoundSensors = $true
                $ramTempData.Source = "LibreHardwareMonitor (Mainboard)"
                $ramTempData.Values = $mbRamTempValues
                $ramTempData.Min = [math]::Round(($mbRamTempValues | Measure-Object -Minimum).Minimum, 1)
                $ramTempData.Max = [math]::Round(($mbRamTempValues | Measure-Object -Maximum).Maximum, 1)
                $ramTempData.Avg = [math]::Round(($mbRamTempValues | Measure-Object -Average).Average, 1)
                $ramTempData.Current = $ramTempData.Max
                
                # RAM-Statistik speichern
                $script:ramStats.LHM_MB = $ramTempData
                $script:lastRamTemp = $ramTempData.Current
                $script:lastRamTempTime = $now
                
                if ($script:DebugModeRAM) {
                    Write-DebugOutput -Component 'RAM' -Message "LibreHardwareMonitor (Mainboard): RAM-Temperatur = $($ramTempData.Current)°C" -Force
                }
                
                return $script:lastRamTemp
            }
        }
        #endregion
        
        #region METHODE 2: SMBus-Direktzugriff (zweite Priorität)
        if ($script:DebugModeRAM) {
            Write-DebugOutput -Component 'RAM' -Message "Methode 2: Versuche SMBus-Direktzugriff" -Force
        }
        
        $smbusTemp = Get-RamTemperatureViaSMBus
        if ($smbusTemp) {
            if ($script:DebugModeRAM) {
                Write-DebugOutput -Component 'RAM' -Message "SMBus: RAM-Temperatur = $smbusTemp°C" -Force
            }
            
            # Cache aktualisieren
            $script:lastRamTemp = $smbusTemp
            $script:lastRamTempTime = $now
            
            return $smbusTemp
        }
        #endregion
        
        # Wenn keine Methode erfolgreich war
        if ($script:DebugModeRAM) {
            Write-DebugOutput -Component 'RAM' -Message "Keine RAM-Temperatur ermittelbar" -Force
        }
        
        return $null
    } catch {
        Write-DebugOutput -Component 'RAM' -Message "Fehler bei RAM-Temperatur: $_" -Force
        return $null
    }
}

#endregion

# Funktion zum Setzen der Hardware-Schwellenwerte
function Set-HardwareThresholds {
    <#
    .SYNOPSIS
        Setzt die Warnschwellenwerte für Hardware-Monitoring
    .DESCRIPTION
        Diese Funktion aktualisiert die Schwellenwerte für CPU, RAM und GPU Überwachung
    .PARAMETER CpuThreshold
        CPU-Warnschwelle in Prozent (50-100)
    .PARAMETER RamThreshold
        RAM-Warnschwelle in Prozent (50-100)
    .PARAMETER GpuThreshold
        GPU-Warnschwelle in Prozent (50-100)
    .EXAMPLE
        Set-HardwareThresholds -CpuThreshold 90 -RamThreshold 85 -GpuThreshold 80
    #>
    param(
        [Parameter(Mandatory = $false)]
        [ValidateRange(50, 100)]
        [int]$CpuThreshold,
        
        [Parameter(Mandatory = $false)]
        [ValidateRange(50, 100)]
        [int]$RamThreshold,
        
        [Parameter(Mandatory = $false)]
        [ValidateRange(50, 100)]
        [int]$GpuThreshold
    )
    
    if ($PSBoundParameters.ContainsKey('CpuThreshold')) {
        $script:cpuThreshold = $CpuThreshold
    }
    if ($PSBoundParameters.ContainsKey('RamThreshold')) {
        $script:ramThreshold = $RamThreshold
    }
    if ($PSBoundParameters.ContainsKey('GpuThreshold')) {
        $script:gpuThreshold = $GpuThreshold
    }
}

#region Post-Installation Helper

<#
.SYNOPSIS
Aktiviert den LibreHardwareMonitor Ring0-Treiber nach WinGet-Installation

.DESCRIPTION
Diese Funktion wird automatisch nach einer erfolgreichen WinGet-Installation 
von LibreHardwareMonitor aufgerufen. Sie:
1. Sucht die installierte .exe-Datei
2. Startet sie kurz im Hintergrund (minimiert)
3. Beendet sie nach 3 Sekunden
4. Registriert damit den WinRing0-Kernel-Treiber

.EXAMPLE
Invoke-LibreHardwareMonitorDriverActivation
#>
function Invoke-LibreHardwareMonitorDriverActivation {
    Write-Host "`n🔧 Aktiviere LibreHardwareMonitor Treiber..." -ForegroundColor Cyan
    
    try {
        # Suche .exe in WinGet-Packages
        $exePaths = Get-ChildItem -Path "${env:LOCALAPPDATA}\Microsoft\WinGet\Packages" -Filter "LibreHardwareMonitor*" -Directory -ErrorAction SilentlyContinue | 
            ForEach-Object { 
                $exePath = Join-Path $_.FullName "LibreHardwareMonitor.exe"
                if (Test-Path $exePath) {
                    $exePath
                }
            }
        
        if ($exePaths.Count -eq 0) {
            Write-Warning "LibreHardwareMonitor.exe nicht gefunden in WinGet-Packages"
            return $false
        }
        
        $exePath = $exePaths[0]
        Write-Host "  📍 Gefunden: $exePath" -ForegroundColor Gray
        
        # Starte .exe minimiert
        Write-Host "  ▶️ Starte Anwendung (minimiert)..." -ForegroundColor Cyan
        $proc = Start-Process -FilePath $exePath -WindowStyle Minimized -PassThru -ErrorAction Stop
        
        # Warte 3 Sekunden für Treiber-Registrierung
        Write-Host "  ⏳ Warte auf Treiber-Registrierung (3 Sek)..." -ForegroundColor Cyan
        Start-Sleep -Seconds 3
        
        # Beende Prozess
        if (-not $proc.HasExited) {
            $proc | Stop-Process -Force -ErrorAction SilentlyContinue
            Write-Host "  ✓ Prozess beendet" -ForegroundColor Green
        }
        
        Write-Host "  ✅ Treiber-Aktivierung abgeschlossen!" -ForegroundColor Green
        Write-Host "  ℹ️  Bitte starten Sie Bockis System-Tool neu, damit der Hardware-Monitor funktioniert." -ForegroundColor Yellow
        
        return $true
    } catch {
        Write-Warning "Fehler bei Treiber-Aktivierung: $_"
        Write-Host "  💡 Bitte starten Sie LibreHardwareMonitor.exe manuell einmal." -ForegroundColor Yellow
        return $false
    }
}

#endregion

#region Export

# Export functions
Export-ModuleMember -Function Initialize-LibreHardwareMonitor, Initialize-LiveMonitoring, `
    Initialize-HardwareMonitoring, Start-HardwareMonitoring, Stop-HardwareMonitoring, Clear-HardwareMonitoring, `
    Update-CpuInfo, Update-GpuInfo, Update-RamInfo, Get-RamTemperature, Get-WarningColor, `
    Update-CpuInfoFallback, Update-GpuInfoFallback, Update-RamInfoFallback, `
    Set-HardwareMonitorDebugMode, Set-HardwareDebugMode, Get-HardwareDebugState, Get-HardwareTimerStatus, Write-HardwareInfo, Write-SensorInfo, `
    Get-GPUUsage, Update-HardwareStats, Get-HardwareStatsTooltip, Reset-GpuName, Show-RamSPDTempDetails, `
    Initialize-SMBusAccess, Get-RamTemperatureViaSMBus, Show-HardwareStatsTable, Set-HardwareThresholds, `
    Open-DebugWindow, Close-DebugWindow, Invoke-LibreHardwareMonitorDriverActivation

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
    } else {
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

# Funktion zum Anzeigen einer tabellarischen Ansicht für Hardware-Statistiken
function Show-HardwareStatsTable {
    param(
        [ValidateSet('CPU', 'GPU', 'RAM')]
        [string]$Component
    )
    
    $stats = switch ($Component) {
        'CPU' { $script:cpuStats }
        'GPU' { $script:gpuStats }
        'RAM' { $script:ramStats }
    }

    # Nur echte Statistik-Einträge berücksichtigen (HashtableS mit Min/Max/Sum/Count/Last)
    # LastReset ist ein DateTime-Objekt und wird herausgefiltert
    $statsFiltered = @{}
    foreach ($k in $stats.Keys) {
        if ($stats[$k] -is [hashtable] -and $stats[$k].ContainsKey('Min')) {
            $statsFiltered[$k] = $stats[$k]
        }
    }

    if (-not $statsFiltered -or $statsFiltered.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show(
            "Keine Statistikdaten verfügbar.",
            "$Component Statistik",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        )
        return
    }

    # Lesbare Anzeigenamen für Statistik-Eigenschaften
    $displayNames = @{
        'Temp'       = 'Temperatur (Max)'
        'CoreMax'    = 'Core Max Temp'
        'CoreMin'    = 'Core Min Temp'
        'HotSpot'    = 'Hot Spot'
        'MemTemp'    = 'VRAM Temp'
        'Load'       = 'Auslastung'
        'MemLoad'    = 'VRAM Last'
        'Power'      = 'Leistung (Package)'
        'PowerCores' = 'Leistung (Kerne)'
        'Clock'      = 'Takt'
        'VCore'      = 'Kernspannung'
        'Used'       = 'Belegt'
        'Free'       = 'Frei'
        'MemUsed'    = 'VRAM genutzt'
        'Fan'        = 'Lüfter (RPM)'
    }

    # Einzel-DIMM-Keys dynamisch als Anzeigenamen registrieren (DIMM1, DIMM3 usw.)
    foreach ($k in $statsFiltered.Keys) {
        if ($k -match '^DIMM(\d+)$' -and -not $displayNames.ContainsKey($k)) {
            $displayNames[$k] = "DIMM #$($Matches[1]) Temp"
        }
    }

    # Bevorzugte Anzeigereihenfolge — DIMM*-Keys werden dynamisch zwischen Temp und Load einsortiert
    $dimmKeys = @($statsFiltered.Keys | Where-Object { $_ -match '^DIMM\d+$' } | Sort-Object)
    $preferredOrder = @('Temp') + $dimmKeys + @(
        'CoreMax', 'CoreMin', 'HotSpot', 'MemTemp',
        'Load', 'MemLoad',
        'Power', 'PowerCores', 'Clock', 'VCore',
        'Used', 'Free', 'MemUsed',
        'Fan'
    )
    $sortedKeys = @($preferredOrder | Where-Object { $statsFiltered.ContainsKey($_) })
    $sortedKeys += @($statsFiltered.Keys | Where-Object { $_ -notin $preferredOrder } | Sort-Object)

    # Erstelle ein neues Formular für die tabellarische Anzeige
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "$Component Statistik"
    $formHeight = [Math]::Max(370, 130 + $sortedKeys.Count * 32 + 60)
    $form.Size = New-Object System.Drawing.Size(600, $formHeight)
    $form.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
    $form.BackColor = [System.Drawing.Color]::DarkSlateGray
    $form.ForeColor = [System.Drawing.Color]::White
    $form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $form.MaximizeBox = $false
    $form.MinimizeBox = $false
    $form.TopMost = $true

    # Überschrift
    $titleLabel = New-Object System.Windows.Forms.Label
    $titleLabel.Text = "$Component Statistik Übersicht"
    $titleLabel.Location = New-Object System.Drawing.Point(20, 20)
    $titleLabel.Size = New-Object System.Drawing.Size(560, 30)
    $titleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
    $titleLabel.ForeColor = [System.Drawing.Color]::White
    $titleLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    $form.Controls.Add($titleLabel)

    # Erstelle DataGridView für tabellarische Darstellung
    $dataGridView = New-Object System.Windows.Forms.DataGridView
    $dataGridView.Location = New-Object System.Drawing.Point(10, 60)
    $tableHeight = [Math]::Max(100, $sortedKeys.Count * 32 + 34)
    $dataGridView.Size = New-Object System.Drawing.Size(560, $tableHeight)
    $dataGridView.BackgroundColor = [System.Drawing.Color]::DarkSlateGray
    $dataGridView.ForeColor = [System.Drawing.Color]::Black
    $dataGridView.GridColor = [System.Drawing.Color]::SlateGray
    $dataGridView.BorderStyle = [System.Windows.Forms.BorderStyle]::None
    $dataGridView.AutoSizeColumnsMode = [System.Windows.Forms.DataGridViewAutoSizeColumnsMode]::Fill
    $dataGridView.ReadOnly = $true
    $dataGridView.AllowUserToAddRows = $false
    $dataGridView.AllowUserToDeleteRows = $false
    $dataGridView.AllowUserToResizeRows = $false
    $dataGridView.RowHeadersVisible = $false
    $dataGridView.AlternatingRowsDefaultCellStyle.BackColor = [System.Drawing.Color]::DimGray
    $dataGridView.DefaultCellStyle.BackColor = [System.Drawing.Color]::SlateGray
    $dataGridView.DefaultCellStyle.ForeColor = [System.Drawing.Color]::White
    $dataGridView.DefaultCellStyle.SelectionBackColor = [System.Drawing.Color]::SteelBlue
    $dataGridView.DefaultCellStyle.SelectionForeColor = [System.Drawing.Color]::White
    $dataGridView.ColumnHeadersDefaultCellStyle.BackColor = [System.Drawing.Color]::DarkSlateGray
    $dataGridView.ColumnHeadersDefaultCellStyle.ForeColor = [System.Drawing.Color]::White
    $dataGridView.ColumnHeadersDefaultCellStyle.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $dataGridView.ColumnHeadersHeightSizeMode = [System.Windows.Forms.DataGridViewColumnHeadersHeightSizeMode]::DisableResizing
    $dataGridView.ColumnHeadersHeight = 30
    $dataGridView.EnableHeadersVisualStyles = $false
    
    # Füge Spalten hinzu
    [void]$dataGridView.Columns.Add("Parameter", "Parameter")
    [void]$dataGridView.Columns.Add("Current", "Aktuell")
    [void]$dataGridView.Columns.Add("Min", "Min")
    [void]$dataGridView.Columns.Add("Max", "Max")
    [void]$dataGridView.Columns.Add("Average", "Durchschnitt")
    
    # Schwellenwerte für Farbkodierung (warn, critical)
    $ramDimmThresholds = @{}
    foreach ($k in ($statsFiltered.Keys | Where-Object { $_ -match '^DIMM\d+$' })) {
        $ramDimmThresholds[$k] = @(55, 75)   # DDR5: Orange ab 55°C, Rot ab 75°C
    }
    $tempThresholds = @{
        # CPU
        'CPU' = @{ 'Temp' = @(70, 85); 'CoreMax' = @(80, 95); 'CoreMin' = @(70, 85); 'Load' = @(80, 95) }
        # GPU: VRAM-Temps haben höhere Schwellen
        'GPU' = @{ 'Temp' = @(70, 85); 'HotSpot' = @(80, 95); 'MemTemp' = @(90, 102); 'Load' = @(80, 95); 'MemLoad' = @(80, 95) }
        # RAM: inkl. Einzel-DIMM-Temps
        'RAM' = @{ 'Temp' = @(55, 75); 'Load' = @(85, 95) } + $ramDimmThresholds
    }

    # Füge Daten hinzu (in bevorzugter Reihenfolge)
    foreach ($key in $sortedKeys) {
        $entry = $statsFiltered[$key]
        
        # Dezimalstellen: GHz, GB-Werte mit 1 Stelle; Temperaturen mit 1 Stelle; sonst ganzzahlig
        $decimals = if ($key -match '^VCore$') { 3 }
        elseif ($key -match '^(Clock|Used|Free|MemUsed)$') { 1 } 
        elseif ($key -match '^DIMM\d+$') { 2 }
        else { 0 }
        $avg = if ($entry.Count -gt 0) { [Math]::Round($entry.Sum / $entry.Count, $decimals) } else { 'N/A' }
        
        # Einheit je nach Property
        $unit = switch -Regex ($key) {
            '^Temp$' { '°C' }
            '^CoreMax$' { '°C' }
            '^CoreMin$' { '°C' }
            '^HotSpot$' { '°C' }
            '^MemTemp$' { '°C' }
            '^DIMM\d+$' { '°C' }
            '^Load$' { '%' }
            '^MemLoad$' { '%' }
            '^Power$' { 'W' }
            '^PowerCores$' { 'W' }
            '^Clock$' { 'GHz' }
            '^VCore$' { 'V' }
            '^Used$' { 'GB' }
            '^Free$' { 'GB' }
            '^MemUsed$' { 'GB' }
            '^Fan$' { 'RPM' }
            default { '' }
        }

        # Anzeigename aus Mapping (inkl. dynamisch registrierter DIMM-Names) oder Key selbst
        $displayName = if ($displayNames.ContainsKey($key)) { $displayNames[$key] } else { $key }

        # Werte formatieren
        $fmtLast = [Math]::Round($entry.Last, $decimals)
        $fmtMin = [Math]::Round($entry.Min, $decimals)
        $fmtMax = [Math]::Round($entry.Max, $decimals)

        $rowIndex = $dataGridView.Rows.Add()
        $row = $dataGridView.Rows[$rowIndex]
        $row.Cells['Parameter'].Value = $displayName
        $row.Cells['Current'].Value = "$fmtLast $unit"
        $row.Cells['Min'].Value = "$fmtMin $unit"
        $row.Cells['Max'].Value = "$fmtMax $unit"
        $row.Cells['Average'].Value = "$avg $unit"
        
        # Farbkodierung: Temp- und Last-Werte
        $compThresholds = $tempThresholds[$Component]
        if ($compThresholds -and $compThresholds.ContainsKey($key)) {
            $thr = $compThresholds[$key]
            # Aktuell-Spalte
            if ($entry.Last -ge $thr[1]) {
                $row.Cells['Current'].Style.BackColor = [System.Drawing.Color]::Red
                $row.Cells['Current'].Style.ForeColor = [System.Drawing.Color]::White
            } elseif ($entry.Last -ge $thr[0]) {
                $row.Cells['Current'].Style.BackColor = [System.Drawing.Color]::Orange
                $row.Cells['Current'].Style.ForeColor = [System.Drawing.Color]::Black
            } else {
                $row.Cells['Current'].Style.BackColor = [System.Drawing.Color]::LightGreen
                $row.Cells['Current'].Style.ForeColor = [System.Drawing.Color]::Black
            }
            # Max-Spalte
            if ($entry.Max -ge $thr[1]) {
                $row.Cells['Max'].Style.BackColor = [System.Drawing.Color]::Red
                $row.Cells['Max'].Style.ForeColor = [System.Drawing.Color]::White
            } elseif ($entry.Max -ge $thr[0]) {
                $row.Cells['Max'].Style.BackColor = [System.Drawing.Color]::Orange
                $row.Cells['Max'].Style.ForeColor = [System.Drawing.Color]::Black
            }
        }
    }
    
    $form.Controls.Add($dataGridView)
    
    # Schließen-Button
    $closeButton = New-Object System.Windows.Forms.Button
    $closeButton.Text = "Schließen"
    $btnY = $dataGridView.Location.Y + $dataGridView.Height + 20
    $closeButton.Location = New-Object System.Drawing.Point(250, $btnY)
    $closeButton.Size = New-Object System.Drawing.Size(100, 30)
    $closeButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $closeButton.BackColor = [System.Drawing.Color]::DimGray
    $closeButton.ForeColor = [System.Drawing.Color]::White
    $closeButton.Add_Click({ $form.Close() })
    $form.Controls.Add($closeButton)
    
    # Zeige das Formular an
    $form.ShowDialog() | Out-Null
}

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
    
    # DIMM-Anzahl für dynamische Fensterhöhe
    $dimmCount = if ($SPDData.DimmSensors) { $SPDData.DimmSensors.Count } else { 0 }
    $extraHeight = if ($dimmCount -gt 0) { 20 + 25 + ($dimmCount * 28) } else { 0 }
    
    # Erstelle das Popup-Fenster
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "DDR5 RAM-Temperaturen"
    $form.Size = New-Object System.Drawing.Size(360, (330 + $extraHeight))
    $form.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
    $form.BackColor = [System.Drawing.Color]::DarkSlateGray
    $form.ForeColor = [System.Drawing.Color]::White
    $form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $form.MaximizeBox = $false
    $form.MinimizeBox = $false
    $form.TopMost = $true
    
    # Titel
    $iconLabel = New-Object System.Windows.Forms.Label
    $iconLabel.Text = "🧠 DDR5 RAM-Temperaturen"
    $iconLabel.Location = New-Object System.Drawing.Point(20, 20)
    $iconLabel.Size = New-Object System.Drawing.Size(310, 30)
    $iconLabel.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
    $iconLabel.ForeColor = [System.Drawing.Color]::White
    $form.Controls.Add($iconLabel)
    
    # Aktuelle Temperatur - großes Format (Maximum)
    $currentTempLabel = New-Object System.Windows.Forms.Label
    $currentTempLabel.Text = "$($SPDData.Current) °C"
    $currentTempLabel.Location = New-Object System.Drawing.Point(20, 60)
    $currentTempLabel.Size = New-Object System.Drawing.Size(310, 50)
    $currentTempLabel.Font = New-Object System.Drawing.Font("Segoe UI", 24, [System.Drawing.FontStyle]::Bold)
    $currentTempLabel.ForeColor = [System.Drawing.Color]::White
    $currentTempLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    $form.Controls.Add($currentTempLabel)
    
    # Separator
    $separator = New-Object System.Windows.Forms.Panel
    $separator.Location = New-Object System.Drawing.Point(20, 120)
    $separator.Size = New-Object System.Drawing.Size(310, 2)
    $separator.BackColor = [System.Drawing.Color]::SlateGray
    $form.Controls.Add($separator)
    
    # Detail-Labels (Min / Avg / Max)
    $labelY = 140
    
    foreach ($row in @(
            @{ Caption = "Min"; ValueRef = "Min" }
            @{ Caption = "Average"; ValueRef = "Avg" }
            @{ Caption = "Max"; ValueRef = "Max" }
        )) {
        $captionLbl = New-Object System.Windows.Forms.Label
        $captionLbl.Text = $row.Caption
        $captionLbl.Location = New-Object System.Drawing.Point(20, $labelY)
        $captionLbl.Size = New-Object System.Drawing.Size(120, 28)
        $captionLbl.Font = New-Object System.Drawing.Font("Segoe UI", 12)
        $captionLbl.ForeColor = [System.Drawing.Color]::LightGray
        $form.Controls.Add($captionLbl)
        
        $valueLbl = New-Object System.Windows.Forms.Label
        $valueLbl.Text = "$($SPDData[$row.ValueRef]) °C"
        $valueLbl.Location = New-Object System.Drawing.Point(160, $labelY)
        $valueLbl.Size = New-Object System.Drawing.Size(170, 28)
        $valueLbl.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
        $valueLbl.ForeColor = [System.Drawing.Color]::White
        $valueLbl.TextAlign = [System.Drawing.ContentAlignment]::MiddleRight
        $valueLbl.Tag = $row.ValueRef   # Kennung für Timer-Refresh
        $form.Controls.Add($valueLbl)
        
        # Referenzen für Timer-Zugriff
        switch ($row.ValueRef) {
            "Min" { $minTempValueLabel = $valueLbl }
            "Avg" { $avgTempValueLabel = $valueLbl }
            "Max" { $maxTempValueLabel = $valueLbl }
        }
        
        $labelY += 38
    }
    
    # Pro-DIMM-Sektion (falls DimmSensors vorhanden)
    $dimmValueLabels = @{}
    if ($dimmCount -gt 0) {
        # Trennlinie
        $dimmSep = New-Object System.Windows.Forms.Panel
        $dimmSep.Location = New-Object System.Drawing.Point(20, ($labelY + 4))
        $dimmSep.Size = New-Object System.Drawing.Size(310, 1)
        $dimmSep.BackColor = [System.Drawing.Color]::SlateGray
        $form.Controls.Add($dimmSep)
        $labelY += 20
        
        # "DIMM Details" Überschrift
        $dimmTitle = New-Object System.Windows.Forms.Label
        $dimmTitle.Text = "Einzel-DIMMs"
        $dimmTitle.Location = New-Object System.Drawing.Point(20, $labelY)
        $dimmTitle.Size = New-Object System.Drawing.Size(310, 22)
        $dimmTitle.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Italic)
        $dimmTitle.ForeColor = [System.Drawing.Color]::LightGray
        $form.Controls.Add($dimmTitle)
        $labelY += 25
        
        foreach ($dimm in $SPDData.DimmSensors) {
            $dimmNameLbl = New-Object System.Windows.Forms.Label
            $dimmNameLbl.Text = "$($dimm.Name):"
            $dimmNameLbl.Location = New-Object System.Drawing.Point(20, $labelY)
            $dimmNameLbl.Size = New-Object System.Drawing.Size(140, 25)
            $dimmNameLbl.Font = New-Object System.Drawing.Font("Segoe UI", 10)
            $dimmNameLbl.ForeColor = [System.Drawing.Color]::LightGray
            $form.Controls.Add($dimmNameLbl)
            
            $dimmValLbl = New-Object System.Windows.Forms.Label
            $dimmValLbl.Text = "$($dimm.Value) °C"
            $dimmValLbl.Location = New-Object System.Drawing.Point(160, $labelY)
            $dimmValLbl.Size = New-Object System.Drawing.Size(170, 25)
            $dimmValLbl.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
            $dimmValLbl.ForeColor = [System.Drawing.Color]::White
            $dimmValLbl.TextAlign = [System.Drawing.ContentAlignment]::MiddleRight
            $form.Controls.Add($dimmValLbl)
            
            $dimmValueLabels[$dimm.Name] = $dimmValLbl
            $labelY += 28
        }
    }
    
    # Timer für automatische Aktualisierung (1 s)
    $timer = New-Object System.Windows.Forms.Timer
    $timer.Interval = 1000
    $timer.Add_Tick({
            Get-RamTemperature | Out-Null
            $spd = $script:ramStats.SPD
            if ($spd -and $null -ne $spd.Min) {
                $currentTempLabel.Text = "$($spd.Current) °C"
                $minTempValueLabel.Text = "$($spd.Min) °C"
                $avgTempValueLabel.Text = "$($spd.Avg) °C"
                $maxTempValueLabel.Text = "$($spd.Max) °C"
                if ($spd.DimmSensors) {
                    foreach ($dimm in $spd.DimmSensors) {
                        if ($dimmValueLabels.ContainsKey($dimm.Name)) {
                            $dimmValueLabels[$dimm.Name].Text = "$($dimm.Value) °C"
                        }
                    }
                }
            }
        })
    
    # Close-Button
    $closeButton = New-Object System.Windows.Forms.Button
    $closeButton.Text = "Schließen"
    $closeButton.Location = New-Object System.Drawing.Point(125, ($labelY + 10))
    $closeButton.Size = New-Object System.Drawing.Size(100, 30)
    $closeButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $closeButton.BackColor = [System.Drawing.Color]::DimGray
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
        } catch {
            # WMI-Zugriff fehlgeschlagen, weiter mit anderen Methoden
        }
        
        # Wenn kein Treiber gefunden wurde
        Write-Warning "Kein SMBus-Treiber gefunden. Temperaturabfrage über SMBus nicht möglich."
        $script:smBusLoaded = $true  # Markiere als versucht
        $script:smBusEnabled = $false
        return $false
    } catch {
        Write-Warning "Fehler beim Initialisieren des SMBus-Zugriffs: $_"
        $script:smBusLoaded = $true  # Markiere als versucht
        $script:smBusEnabled = $false
        return $false
    }
}

# Funktion zum Lesen der RAM-Temperaturen über SMBus
function Get-RamTemperatureViaSMBus {
    <#
    .SYNOPSIS
        Liest RAM-Temperaturdaten direkt über den SMBus mit verbesserter Unterstützung für DDR4 und DDR5.
    
    .DESCRIPTION
        Diese Funktion versucht, die Temperatur des RAM direkt über den SMBus zu lesen.
        Sie unterstützt verschiedene RAM-Typen, darunter DDR4 und DDR5, und verwendet
        spezialisierte Adressen und Register für die präzise Temperaturauslesung.
        
        Unterschiedliche Speichertypen (DDR4/DDR5) werden erkannt und mit optimierten
        Sensoradressen und Konvertierungsformeln ausgelesen.
    
    .OUTPUTS
        System.Double - Die höchste gefundene RAM-Temperatur oder $null, wenn keine gefunden wurde.
    #>
    
    # Globale Variable für SMBus-Temperatur-Cache
    if (-not (Test-Path -Path variable:script:smBusTempCache)) {
        $script:smBusTempCache = @{
            LastUpdate = [DateTime]::MinValue
            Values     = @()
            Max        = $null
            Source     = $null
        }
    }
    
    # Cache-Prüfung - Werte höchstens alle 5 Sekunden aktualisieren
    $cacheTimeout = [TimeSpan]::FromSeconds(5)
    $now = Get-Date
    if (($now - $script:smBusTempCache.LastUpdate) -lt $cacheTimeout -and 
        $script:smBusTempCache.Max -ne $null) {
        
        if ($script:DebugModeRAM) {
            $cacheAge = [math]::Round(($now - $script:smBusTempCache.LastUpdate).TotalSeconds, 1)
            Write-DebugOutput -Component 'RAM' -Message "SMBus Cache verwendet: $($script:smBusTempCache.Max)°C (Alter: ${cacheAge}s, Quelle: $($script:smBusTempCache.Source))" -Force
        }
        return $script:smBusTempCache.Max
    }
    
    # SMBus-Zugriff initialisieren, wenn noch nicht geschehen
    if (-not $script:smBusEnabled) {
        if (-not (Initialize-SMBusAccess)) {
            return $null
        }
    }
    
    try {
        # Temperatur-Arrays und Hilfsvariablen
        $temperatures = @()
        $sensorDetails = @()
        $detectedRAMType = "Unknown"  # Zum Speichern des erkannten RAM-Typs
        
        # Debug-Nachricht
        if ($script:DebugModeRAM) {
            Write-DebugOutput -Component 'RAM' -Message "Starting SMBus RAM temperature detection" -Force
        }
        
        # RAM-Typ erkennen
        $ramModules = Get-WmiObject -Class Win32_PhysicalMemory -ErrorAction SilentlyContinue
        if ($ramModules) {
            # DDR-Typ aus Speicherbeschreibung extrahieren
            $memoryTypeStr = $ramModules[0].SMBIOSMemoryType
            
            # Zuordnung der SMBIOS-MemoryType-Werte
            $detectedRAMType = switch ($memoryTypeStr) {
                { $_ -eq 26 } { "DDR4" }
                { $_ -eq 30 } { "LPDDR4" }
                { $_ -eq 34 } { "DDR5" }
                { $_ -eq 35 } { "LPDDR5" }
                default { "Unknown" }
            }
            
            if ($script:DebugModeRAM) {
                $totalModules = $ramModules.Count
                $totalCapacity = ($ramModules | Measure-Object -Property Capacity -Sum).Sum / 1GB
                Write-DebugOutput -Component 'RAM' -Message "Erkannter RAM-Typ: $detectedRAMType, Module: $totalModules, Gesamt: $totalCapacity GB" -Force
                
                # Detaillierte Modulinformationen ausgeben
                foreach ($module in $ramModules) {
                    $capacityGB = [math]::Round($module.Capacity / 1GB, 2)
                    $speed = $module.Speed
                    $manufacturer = $module.Manufacturer.Trim()
                    $partNumber = $module.PartNumber.Trim()
                    Write-DebugOutput -Component 'RAM' -Message "  Modul: $capacityGB GB @ $speed MHz, Hersteller: $manufacturer, PN: $partNumber" -Force
                }
            }
        }
        
        # Adressen und Register je nach erkanntem RAM-Typ optimieren
        $spdAddresses = @()
        $tempRegisters = @()
        
        # DDR5 optimierte Adressen und Register
        if ($detectedRAMType -eq "DDR5" -or $detectedRAMType -eq "LPDDR5") {
            if ($script:DebugModeRAM) {
                Write-DebugOutput -Component 'RAM' -Message "Verwende DDR5-optimierte Adressen und Register" -Force
            }
            
            # DDR5 verwendet spezielle SPD-Hub-Temperatursensoren
            $spdAddresses = @(
                # DDR5 SPD Hub Adressen (primär)
                0x18, 0x19, 0x1A, 0x1B, 
                # Erweiterte DDR5 SPD Hub Adressen (sekundär)
                0x1C, 0x1D, 0x1E, 0x1F,
                # DDR5 Standard SPD-Adressen (für ältere Mainboards)
                0x50, 0x51, 0x52, 0x53, 
                # Alternative DDR5 Temperatursensor-Adressen
                0x30, 0x31, 0x32, 0x33
            )
            
            # DDR5-spezifische Register
            $tempRegisters = @(
                0x05, # DDR5 SPD Hub Temperatursensor (primärer Sensor)
                0x06, # DDR5 SPD Hub erweiterter Temperatursensor (16-bit)
                0x33, # Alternatives Temperatur-Register
                0x31   # Backup-Register für ältere DDR5-Module
            )
        }
        # DDR4 optimierte Adressen und Register
        else {
            if ($script:DebugModeRAM) {
                Write-DebugOutput -Component 'RAM' -Message "Verwende DDR4-optimierte Adressen und Register" -Force
            }
            
            # Standard DDR4-Adressen
            $spdAddresses = @(
                # DDR4 Temperatursensor-Adressen (primär)
                0x30, 0x31, 0x32, 0x33,
                # Erweiterte DDR4 Sensor-Adressen (sekundär)
                0x34, 0x35, 0x36, 0x37,
                # Standard DDR4 SPD-Adressen (für direkte Module)
                0x50, 0x51, 0x52, 0x53
            )
            
            # DDR4-spezifische Register
            $tempRegisters = @(
                0x22, # DDR4 SPD Temperatursensor (Haupt-Register)
                0x24, # DDR4 erweiterter Temperatursensor
                0x0E, # Alternative für manche Hersteller
                0x05   # Universelles Temperatur-Register
            )
        }
        
        # Versuch mit Treiber-DLL
        if ($null -ne $script:smBusDriver -and (-not [IntPtr]::Equals($script:smBusDriver, [IntPtr]::Zero))) {
            $sensorFound = $false
            
            # Hauptfunktion zum Auslesen des Temperatursensors mit optimierten Parametern
            function Read-SMBusTemperature {
                param($Address, $Register)
                
                try {
                    # Versuch mit SMBusReadByte (häufigste Funktion)
                    $readFuncPtr = [SMBus.WinAPIWrapper]::GetProcAddress($script:smBusDriver, "SMBusReadByte")
                    if (-not [IntPtr]::Equals($readFuncPtr, [IntPtr]::Zero)) {
                        $delegate = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer(
                            $readFuncPtr, 
                            [Type][System.Func`3[[byte], [byte], [byte]]]
                        )
                        
                        # Byte aus dem Speicher lesen
                        $rawTemp = $delegate.Invoke($Address, $Register)
                        
                        # Wenn kein gültiger Wert, versuche alternative Funktionen
                        if ($rawTemp -eq 0 -or $rawTemp -eq 255) {
                            # Versuch mit alternativen Funktionsnamen
                            foreach ($funcName in @("ReadSMBus", "ReadSMBusByte", "SMBus_ReadByte")) {
                                try {
                                    $altFuncPtr = [SMBus.WinAPIWrapper]::GetProcAddress($script:smBusDriver, $funcName)
                                    if (-not [IntPtr]::Equals($altFuncPtr, [IntPtr]::Zero)) {
                                        $altDelegate = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer(
                                            $altFuncPtr, 
                                            [Type][System.Func`3[[byte], [byte], [byte]]]
                                        )
                                        $rawTemp = $altDelegate.Invoke($Address, $Register)
                                        if ($rawTemp -gt 0 -and $rawTemp -lt 255) {
                                            return $rawTemp
                                        }
                                    }
                                } catch {
                                    # Ignorieren und weiter probieren
                                }
                            }
                        }
                        
                        return $rawTemp
                    }
                } catch {
                    # Spezifische Fehler für Debug protokollieren
                    if ($script:DebugModeRAM) {
                        $errorMsg = $_.Exception.Message
                        # Nur signifikante Fehlermeldungen ausgeben
                        if ($errorMsg -notmatch "Der Vorgang wurde erfolgreich beendet|The operation completed successfully") {
                            $addrHex = "0x" + $Address.ToString("X2")
                            $regHex = "0x" + $Register.ToString("X2")
                            Write-DebugOutput -Component 'RAM' -Message "SMBus-Fehler bei Addr=$addrHex Reg=$regHex`: $errorMsg" -Force
                        }
                    }
                    return 0  # Bei Fehler 0 zurückgeben
                }
            }
            
            # 16-Bit Temperaturwert aus zwei Registern lesen (höhere Präzision für DDR5)
            function Read-SMBusTemperature16Bit {
                param($Address, $LowRegister, $HighRegister)
                
                try {
                    $lowByte = Read-SMBusTemperature -Address $Address -Register $LowRegister
                    $highByte = Read-SMBusTemperature -Address $Address -Register $HighRegister
                    
                    # Prüfe, ob beide Werte gültig sind
                    if ($lowByte -gt 0 -and $lowByte -lt 255 -and $highByte -lt 255) {
                        # 16-Bit Wert zusammensetzen (lowByte + highByte << 8)
                        $raw16BitTemp = $lowByte + ($highByte -shl 8)
                        return $raw16BitTemp
                    }
                    return 0
                } catch {
                    return 0
                }
            }
            
            # Temperatur-Konvertierungsfunktion mit korrekter Formel je nach Speichertyp und Register
            function Convert-RawToTemperature {
                param($RawValue, $RamType, $Address, $Register)
                
                try {
                    # Ungültige Werte ausfiltern
                    if ($RawValue -eq 0 -or $RawValue -eq 255) { return $null }
                    
                    # DDR5 SPD Hub spezifische Konvertierung
                    if ($RamType -eq "DDR5" -and $Address -ge 0x18 -and $Address -le 0x1F -and $Register -eq 0x05) {
                        # DDR5 SPD Hub Temperatursensoren: 8-bit unsigned, -40°C Offset
                        $temp = $RawValue - 40
                    }
                    # DDR5 16-Bit Temperaturwert (Register 0x06/0x07) mit höherer Präzision
                    elseif ($RamType -eq "DDR5" -and $Register -eq 0x06) {
                        # 16-bit Temperaturwert mit 0.125°C Auflösung
                        $temp = $RawValue * 0.125
                    }
                    # DDR4 Standardkonvertierung
                    elseif ($RamType -eq "DDR4" -and $Register -eq 0x22) {
                        # DDR4 Temperatursensor: direkte Temperatur ohne Konvertierung
                        $temp = $RawValue * 1.0
                    }
                    # Standardkonvertierung für andere Fälle
                    else {
                        # Typischer Temperatursensor: 1/2 Grad Auflösung
                        $temp = $RawValue / 2.0
                    }
                    
                    # Plausibilitätsprüfung
                    if ($temp -ge 10 -and $temp -lt 100) {
                        return [math]::Round($temp, 1)  # Auf eine Nachkommastelle runden
                    }
                    return $null
                } catch {
                    return $null
                }
            }
            
            # Priorisiere die SPD Hub Register für DDR5
            if ($detectedRAMType -eq "DDR5") {
                if ($script:DebugModeRAM) {
                    Write-DebugOutput -Component 'RAM' -Message "DDR5: Priorisiere SPD Hub Register (Adressen 0x18-0x1F)" -Force
                }
                
                # SPD Hub Temperaturauslesung (hohe Priorität für DDR5)
                foreach ($address in ($spdAddresses | Where-Object { $_ -ge 0x18 -and $_ -le 0x1F })) {
                    # Zuerst versuchen wir das 8-bit Register (Standard)
                    $rawTemp = Read-SMBusTemperature -Address $address -Register 0x05
                    if ($rawTemp -gt 0 -and $rawTemp -lt 255) {
                        $temp = Convert-RawToTemperature -RawValue $rawTemp -RamType "DDR5" -Address $address -Register 0x05
                        if ($temp) {
                            $temperatures += $temp
                            $sensorFound = $true
                            $sensorDetails += [PSCustomObject]@{
                                Type     = "DDR5 SPD Hub"
                                Address  = "0x$($address.ToString('X2'))"
                                Register = "0x05"
                                Raw      = $rawTemp
                                Value    = $temp
                            }
                            
                            if ($script:DebugModeRAM) {
                                Write-DebugOutput -Component 'RAM' -Message "DDR5 SPD Hub-Sensor gefunden: Adresse=0x$($address.ToString('X2')), Register=0x05, Temp=$temp°C" -Force
                            }
                        }
                    }
                    
                    # Dann versuchen wir das 16-bit Register (höhere Genauigkeit)
                    $raw16BitTemp = Read-SMBusTemperature16Bit -Address $address -LowRegister 0x06 -HighRegister 0x07
                    if ($raw16BitTemp -gt 0) {
                        $temp = Convert-RawToTemperature -RawValue $raw16BitTemp -RamType "DDR5" -Address $address -Register 0x06
                        if ($temp) {
                            $temperatures += $temp
                            $sensorFound = $true
                            $sensorDetails += [PSCustomObject]@{
                                Type     = "DDR5 SPD Hub 16-bit"
                                Address  = "0x$($address.ToString('X2'))"
                                Register = "0x06-0x07"
                                Raw      = $raw16BitTemp
                                Value    = $temp
                            }
                            
                            if ($script:DebugModeRAM) {
                                Write-DebugOutput -Component 'RAM' -Message "DDR5 SPD Hub 16-bit Sensor gefunden: Adresse=0x$($address.ToString('X2')), Register=0x06-07, Temp=$temp°C" -Force
                            }
                        }
                    }
                }
            }
            
            # Wenn bei DDR5 noch keine Sensoren gefunden wurden, oder es ist DDR4, dann versuche die anderen Register
            if (-not $sensorFound -or $detectedRAMType -eq "DDR4" -or $detectedRAMType -eq "Unknown") {
                # Generische SMBus-Durchsuchung mit allen konfigurierten Adressen und Registern
                foreach ($address in $spdAddresses) {
                    foreach ($register in $tempRegisters) {
                        $rawTemp = Read-SMBusTemperature -Address $address -Register $register
                        if ($rawTemp -gt 0 -and $rawTemp -lt 255) {
                            $temp = Convert-RawToTemperature -RawValue $rawTemp -RamType $detectedRAMType -Address $address -Register $register
                            
                            if ($temp) {
                                $temperatures += $temp
                                $sensorFound = $true
                                $sensorDetails += [PSCustomObject]@{
                                    Type     = "$detectedRAMType Standard"
                                    Address  = "0x$($address.ToString('X2'))"
                                    Register = "0x$($register.ToString('X2'))"
                                    Raw      = $rawTemp
                                    Value    = $temp
                                }
                                
                                if ($script:DebugModeRAM) {
                                    Write-DebugOutput -Component 'RAM' -Message "RAM-Sensor gefunden: Adresse=0x$($address.ToString('X2')), Register=0x$($register.ToString('X2')), Temp=$temp°C" -Force
                                }
                            }
                        }
                    }
                }
            }
            
            # Alternative I2C-Register-Lesemethode für OpenHardwareMonitor-kompatible Hardware
            if (-not $sensorFound) {
                try {
                    $i2cFuncPtr = [SMBus.WinAPIWrapper]::GetProcAddress($script:smBusDriver, "ReadI2C")
                    if (-not [IntPtr]::Equals($i2cFuncPtr, [IntPtr]::Zero)) {
                        $i2cDelegate = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer(
                            $i2cFuncPtr,
                            [Type][System.Func`3[[int], [int], [byte]]]
                        )
                        
                        # DDR Temperatursensor-I2C-Bus ist typischerweise SMBus 0 oder 1
                        foreach ($bus in @(0, 1)) {
                            foreach ($address in $spdAddresses) {
                                foreach ($register in $tempRegisters) {
                                    try {
                                        $rawTemp = $i2cDelegate.Invoke($bus, ($address -shl 8) -bor $register)
                                        if ($rawTemp -gt 0 -and $rawTemp -lt 255) {
                                            $temp = Convert-RawToTemperature -RawValue $rawTemp -RamType $detectedRAMType -Address $address -Register $register
                                            
                                            if ($temp) {
                                                $temperatures += $temp
                                                $sensorDetails += [PSCustomObject]@{
                                                    Type     = "I2C $detectedRAMType"
                                                    Bus      = $bus
                                                    Address  = "0x$($address.ToString('X2'))"
                                                    Register = "0x$($register.ToString('X2'))"
                                                    Raw      = $rawTemp
                                                    Value    = $temp
                                                }
                                                
                                                if ($script:DebugModeRAM) {
                                                    Write-DebugOutput -Component 'RAM' -Message "I2C Sensor gefunden: Bus=$bus, Addr=0x$($address.ToString('X2')), Reg=0x$($register.ToString('X2')), Temp=$temp°C" -Force
                                                }
                                            }
                                        }
                                    } catch {
                                        continue
                                    }
                                }
                            }
                        }
                    }
                } catch {
                    if ($script:DebugModeRAM) {
                        Write-DebugOutput -Component 'RAM' -Message "I2C-Zugriff fehlgeschlagen: $_" -Force
                    }
                }
            }
        }
        
        # Alternative: WMI-basierter Versuch wenn keine Temperaturen gefunden wurden
        if ($temperatures.Count -eq 0) {
            if ($script:DebugModeRAM) {
                Write-DebugOutput -Component 'RAM' -Message "Keine Temperaturen über SMBus gefunden. Versuche WMI..." -Force
            }
            
            try {
                $wmiNamespaces = @("root\wmi", "root\cimv2", "root\hardware")
                $wmiClasses = @("MSSmBios", "MemoryDevice", "MemoryChip", "Win32_PerfRawData_Counters_Memory")
                
                foreach ($namespace in $wmiNamespaces) {
                    foreach ($class in $wmiClasses) {
                        try {
                            $wmiData = Get-WmiObject -Namespace $namespace -Class $class -ErrorAction SilentlyContinue
                            if ($wmiData) {
                                # Versuche, Temperatursensor-Eigenschaften zu finden
                                $tempProperties = $wmiData.PSObject.Properties | Where-Object {
                                    $_.Name -match "Temp|Temperature|Thermal|Heat" -and
                                    ($_.Value -is [int] -or $_.Value -is [double] -or $_.Value -is [float])
                                }
                                
                                foreach ($prop in $tempProperties) {
                                    $tempValue = $prop.Value
                                    if ($tempValue -gt 10 -and $tempValue -lt 100) {
                                        $temperatures += $tempValue
                                        $sensorDetails += [PSCustomObject]@{
                                            Type      = "WMI"
                                            Namespace = $namespace
                                            Class     = $class
                                            Property  = $prop.Name
                                            Value     = $tempValue
                                        }
                                        
                                        if ($script:DebugModeRAM) {
                                            Write-DebugOutput -Component 'RAM' -Message "WMI Temperatursensor gefunden: $namespace/$class/$($prop.Name) = $tempValue°C" -Force
                                        }
                                    }
                                }
                            }
                        } catch {
                            continue  # Nächste Klasse versuchen
                        }
                    }
                }
            } catch {
                if ($script:DebugModeRAM) {
                    Write-DebugOutput -Component 'RAM' -Message "WMI-Zugriff fehlgeschlagen: $_" -Force
                }
            }
        }
        
        # Wenn Temperaturen gefunden wurden, Ergebnis vorbereiten und zurückgeben
        if ($temperatures.Count -gt 0) {
            # Statistiken berechnen
            $avgTemp = ($temperatures | Measure-Object -Average).Average
            $maxTemp = ($temperatures | Measure-Object -Maximum).Maximum
            $minTemp = ($temperatures | Measure-Object -Minimum).Minimum
            
            # Quelle des primären Sensors bestimmen
            $primarySource = if ($sensorDetails.Count -gt 0) {
                $maxSensor = $sensorDetails | Where-Object { $_.Value -eq $maxTemp } | Select-Object -First 1
                if ($maxSensor) {
                    "$($maxSensor.Type) $($maxSensor.Address):$($maxSensor.Register)"
                } else {
                    "SMBus"
                }
            } else {
                "SMBus"
            }
            
            # SPD-Daten für Detailanzeige speichern
            $script:ramStats.SPD = @{
                FoundSensors = $true
                Source       = $primarySource
                Values       = $temperatures
                Min          = $minTemp
                Max          = $maxTemp
                Avg          = $avgTemp
                Current      = $maxTemp  # Den höchsten Wert als aktuell anzeigen
                Details      = $sensorDetails
                Type         = $detectedRAMType
            }
            
            # Cache aktualisieren
            $script:smBusTempCache.LastUpdate = $now
            $script:smBusTempCache.Values = $temperatures
            $script:smBusTempCache.Max = $maxTemp
            $script:smBusTempCache.Source = $primarySource
            
            # Debug-Ausgabe
            if ($script:DebugModeRAM) {
                Write-DebugOutput -Component 'RAM' -Message "SMBus: $($temperatures.Count) RAM-Temperaturen gefunden: Min=$minTemp°C, Avg=$([math]::Round($avgTemp,1))°C, Max=$maxTemp°C" -Force
                
                # Wenn mehrere Sensoren, Details ausgeben
                if ($temperatures.Count -gt 1 -and $sensorDetails.Count -gt 0) {
                    Write-DebugOutput -Component 'RAM' -Message "SMBus Sensor-Details:" -Force
                    foreach ($sensor in $sensorDetails) {
                        $sensorInfo = if ($sensor.Type -match "I2C") {
                            "Bus=$($sensor.Bus), "
                        } else { "" }
                        $sensorInfo += "Adresse=$($sensor.Address), Register=$($sensor.Register), Temp=$($sensor.Value)°C"
                        Write-DebugOutput -Component 'RAM' -Message "  $($sensor.Type): $sensorInfo" -Force
                    }
                }
            }
            
            # Max-Temperatur zurückgeben (konservativste Annahme)
            return $maxTemp
        }
        
        # Keine Temperaturen gefunden
        if ($script:DebugModeRAM) {
            Write-DebugOutput -Component 'RAM' -Message "Keine RAM-Temperaturen über SMBus gefunden" -Force
        }
        return $null
    } catch {
        if ($script:DebugModeRAM) {
            Write-DebugOutput -Component 'RAM' -Message "Fehler bei SMBus-Temperaturabfrage: $_" -Force
        }
        return $null
    }
}


# SIG # Begin signature block
# MIIcSgYJKoZIhvcNAQcCoIIcOzCCHDcCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDnrwdlV5V5KIei
# 04/hSLR7ky0G06EQD9Cc3O6j5cjlLaCCFnowggM8MIICJKADAgECAhBJfyGrXBJT
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
# MQ4wDAYKKwYBBAGCNwIBFTAvBgkqhkiG9w0BCQQxIgQg9pJCKRlKG11lwWej99Jr
# xOe7sSexMHcReKY5PYU659QwDQYJKoZIhvcNAQEBBQAEggEAUqvWCu14yzUPtj+y
# vNi/oWAtdrryLLMczFKsdn7pOHFu479VfY3XxWExvkS4xnR/8b65kLguYmS/UEwR
# HG/PLbETRhoDQjYaAEHvuRVBAcF+ZEgAEFXn+mI+unxLuW4ZughUUWj26k2bM+I/
# cBFwqznY53yMZ7sYKE8BkWOX0d3dlPzgvQY/oTsOMwbbYzIB4g67b09/DFl7KERa
# qR5/Vkz3x12pnMfSwnMK9C6JlUMZmbl8mxcFLUK/YmFENYL4Jgk1n32IznWznZtn
# iGbQBl/dX0IZlyKv9XRHD7IdR7yHVVXA5pr1znJmtDDmEERLP1xighef2uGgK4sy
# QMED2aGCAyYwggMiBgkqhkiG9w0BCQYxggMTMIIDDwIBATB9MGkxCzAJBgNVBAYT
# AlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5jLjFBMD8GA1UEAxM4RGlnaUNlcnQg
# VHJ1c3RlZCBHNCBUaW1lU3RhbXBpbmcgUlNBNDA5NiBTSEEyNTYgMjAyNSBDQTEC
# EAqA7xhLjfEFgtHEdqeVdGgwDQYJYIZIAWUDBAIBBQCgaTAYBgkqhkiG9w0BCQMx
# CwYJKoZIhvcNAQcBMBwGCSqGSIb3DQEJBTEPFw0yNjAxMjAxODAyNTRaMC8GCSqG
# SIb3DQEJBDEiBCAev/wSxz4by9OWqstgrC3GnM21ZUSLgiP+Q1heM1m8aTANBgkq
# hkiG9w0BAQEFAASCAgBKlQSqu/o416yAw3junelXTItWbiIA5Rch1/aBWh/mlsTC
# gu0vyO2MHBNSYcI6Z00kKmeDI9pZ7WzG2v9HghSqhb8ks0eWrxxteV0+2Aph8Lbf
# l3TPzfgwhCY49z7Mgpp67LoGdUtSWXyr3Lj3Rh5vvMZVBbr0P7tZ01EDAGKIkuLQ
# U9rJ7xnnySL4yxTSXK7qx+1topZpr8GzcRuKQTStbx47lK1OxhawRFf/feFKsUaI
# BBuyFvcuvEP2unxedV/OHvba8xVSxDdG/kyEB+lo+p7XCZjHXRQ8eT+Hl1Wk+492
# 7rpFDKAzSH00i2V+mitQEpdqheIH9YbgK4OKrUtLh6Qa6THOwB3OqDr8Hr8yU+Vu
# LU0HCV31EXuWL2E/aNSS6GoilkzeP1PNo8Tj67HmziWRbNd4RU9ccnuBc+mm01NM
# TC7fbHgJStxF4Fp+vn0OYqZNtbxR66HTU1HslkFfpkqwVQbj/jqH9aVc1xr1liQw
# 3whe49vIyu306XPp5Lg5RFKOCy5rDRrL3eNBkJfnFiN0k+kZnSn/D5Ap5b7NNL8u
# 5o54e9KyBX+RbGuFWoy78p4luEPMsTXu0AlYG2uxgL6ZM7E6AQYq4pNLcAYXYMk9
# aLwtVTjJJg4OXOKiEd8wSKM/fWyzxLSbHifmVwzBnWACR78R0tn54UXS4vZQPg==
# SIG # End signature block

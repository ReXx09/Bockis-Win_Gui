# FallbackSensors.psm1
# Alternative Sensor-Auslese ohne Ring-0-Treiber
# Autor: Bockis
# Version: 2.0 - Optimiert und vereinfacht

<#
.SYNOPSIS
Native Windows-Methoden für Hardware-Monitoring ohne externe Treiber

.DESCRIPTION
Dieses Modul bietet Fallback-Funktionen für Hardware-Monitoring,
die KEINE Ring-0-Treiber oder externe Tools benötigen.

VERFÜGBARE DATEN:
✓ CPU-Last (Performance Counter) - funktioniert IMMER
✓ RAM-Auslastung (WMI/CIM) - funktioniert IMMER
✓ CPU-Temperatur (WMI Thermal Zones) - funktioniert auf ~30-40% der Systeme
✗ GPU-Temperatur - NICHT verfügbar ohne Treiber
✗ RAM-Temperatur - NICHT verfügbar ohne Treiber

VERWENDUNG:
Wird automatisch aktiviert, wenn PawnIO + LibreHardwareMonitor nicht verfügbar sind.
#>

#region CPU-Funktionen

<#
.SYNOPSIS
Liest CPU-Auslastung via Windows Performance Counters

.DESCRIPTION
Nutzt die Windows Performance Counter API für CPU-Load.
Funktioniert IMMER, auch ohne Admin-Rechte oder Ring-0-Treiber.
Unterstützt deutsche und englische Counter-Namen.

.RETURNS
Double - CPU-Auslastung in Prozent (0-100) oder $null bei Fehler

.EXAMPLE
$cpuLoad = Get-CpuLoadFallback
if ($cpuLoad) {
    Write-Host "CPU-Auslastung: $cpuLoad%"
}
#>
function Get-CpuLoadFallback {
    try {
        # Versuche erst deutsche Counter-Namen (Windows DE)
        $cpuCounter = Get-Counter '\Prozessor(_Total)\Prozessorzeit (%)' -ErrorAction SilentlyContinue
        
        if (-not $cpuCounter) {
            # Falls deutsch nicht funktioniert, versuche englisch (Windows EN)
            $cpuCounter = Get-Counter '\Processor(_Total)\% Processor Time' -ErrorAction Stop
        }
        
        return [math]::Round($cpuCounter.CounterSamples[0].CookedValue, 1)
    }
    catch {
        Write-Verbose "CPU-Load via Performance Counter fehlgeschlagen: $_"
        return $null
    }
}

<#
.SYNOPSIS
Liest System-Temperaturen via WMI (ACPI Thermal Zones)

.DESCRIPTION
Versucht MSAcpi_ThermalZoneTemperature auszulesen.

WICHTIGE EINSCHRÄNKUNGEN:
⚠ Zeigt oft nur Mainboard-Sensoren, NICHT CPU-Kern-Temperaturen!
⚠ Funktioniert nur auf 30-40% aller Systeme (abhängig vom Mainboard)
⚠ Werte können ungenau sein

Werte sind in Zehntel-Kelvin (z.B. 3020 = 302.0K = 28.85°C)

.RETURNS
Hashtable mit Thermal Zone Namen und Temperaturen in °C, oder $null wenn nicht verfügbar

.EXAMPLE
$zones = Get-ThermalZonesFallback
if ($zones) {
    foreach ($zone in $zones.GetEnumerator()) {
        Write-Host "$($zone.Key): $($zone.Value)°C"
    }
}
#>
function Get-ThermalZonesFallback {
    try {
        $thermalZones = Get-WmiObject -Namespace "root\wmi" -Class MSAcpi_ThermalZoneTemperature -ErrorAction Stop
        
        $result = @{}
        $index = 1
        
        foreach ($zone in $thermalZones) {
            if ($zone.CurrentTemperature -gt 0) {
                # Konvertierung: Zehntel-Kelvin -> Celsius
                # Beispiel: 3020 (Zehntel-Kelvin) / 10 = 302K - 273.15 = 28.85°C
                $tempKelvin = $zone.CurrentTemperature / 10
                $tempCelsius = $tempKelvin - 273.15
                
                # Plausibilitäts-Check (0-120°C ist realistisch für Hardware)
                if ($tempCelsius -ge 0 -and $tempCelsius -le 120) {
                    $zoneName = if ($zone.InstanceName) { 
                        $zone.InstanceName 
                    } else { 
                        "Thermal Zone $index" 
                    }
                    
                    $result[$zoneName] = [math]::Round($tempCelsius, 1)
                    $index++
                }
            }
        }
        
        if ($result.Count -eq 0) {
            Write-Verbose "Keine WMI Thermal Zones gefunden (normal bei vielen Systemen)"
            return $null
        }
        
        return $result
    }
    catch {
        Write-Verbose "WMI Thermal Zones nicht verfügbar: $_"
        return $null
    }
}

<#
.SYNOPSIS
Schätzt CPU-Temperatur aus Thermal Zones

.DESCRIPTION
Versucht die beste CPU-Temperatur-Schätzung aus verfügbaren Thermal Zones zu ermitteln.
Nimmt die höchste Temperatur als wahrscheinlichsten CPU-Wert.

⚠ HINWEIS: Dies ist nur eine SCHÄTZUNG! Für genaue CPU-Temperaturen
           verwende LibreHardwareMonitor mit PawnIO-Treiber.

.RETURNS
Double - Geschätzte CPU-Temperatur in °C, oder $null wenn nicht verfügbar

.EXAMPLE
$cpuTemp = Get-CpuTemperatureFallback
if ($cpuTemp) {
    Write-Host "CPU-Temperatur (geschätzt): $cpuTemp°C"
}
#>
function Get-CpuTemperatureFallback {
    $thermalZones = Get-ThermalZonesFallback
    
    if (-not $thermalZones -or $thermalZones.Count -eq 0) {
        return $null
    }
    
    # Strategie: Nimm die höchste Temperatur
    # Begründung: CPU ist typischerweise der heißeste Sensor
    $maxTemp = ($thermalZones.Values | Measure-Object -Maximum).Maximum
    
    return $maxTemp
}

#endregion

#region RAM-Funktionen

<#
.SYNOPSIS
Liest Speicher-Auslastung via WMI/CIM

.DESCRIPTION
Nutzt CIM_OperatingSystem für RAM-Statistiken.
Funktioniert IMMER ohne Ring-0-Treiber.

WICHTIG: Liefert nur Auslastung, KEINE Temperatur!
         RAM-Temperatur erfordert PawnIO + LibreHardwareMonitor.

.RETURNS
Hashtable mit:
  - TotalGB: Gesamt-RAM in GB
  - UsedGB: Genutzter RAM in GB
  - FreeGB: Freier RAM in GB
  - UsedPercent: Auslastung in Prozent

.EXAMPLE
$ram = Get-MemoryUsageFallback
if ($ram) {
    Write-Host "RAM: $($ram.UsedGB)GB / $($ram.TotalGB)GB ($($ram.UsedPercent)%)"
}
#>
function Get-MemoryUsageFallback {
    try {
        $os = Get-CimInstance -ClassName CIM_OperatingSystem -ErrorAction Stop
        
        $totalGB = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
        $freeGB = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
        $usedGB = $totalGB - $freeGB
        $usedPercent = [math]::Round(($usedGB / $totalGB) * 100, 1)
        
        return @{
            TotalGB = $totalGB
            UsedGB = $usedGB
            FreeGB = $freeGB
            UsedPercent = $usedPercent
        }
    }
    catch {
        Write-Warning "Memory-Auslese via CIM fehlgeschlagen: $_"
        return $null
    }
}

#endregion

#region Disk-Funktionen

<#
.SYNOPSIS
Liest Disk I/O via Performance Counters

.DESCRIPTION
Nutzt PhysicalDisk Performance Counters für Read/Write-Statistiken.
Funktioniert ohne Ring-0-Treiber.
Unterstützt deutsche und englische Counter-Namen.

.RETURNS
Hashtable mit:
  - ReadsPerSec: Lesevorgänge pro Sekunde
  - WritesPerSec: Schreibvorgänge pro Sekunde

.EXAMPLE
$disk = Get-DiskActivityFallback
if ($disk) {
    Write-Host "Disk: $($disk.ReadsPerSec) R/s | $($disk.WritesPerSec) W/s"
}
#>
function Get-DiskActivityFallback {
    try {
        # Versuche erst deutsche Counter-Namen
        $diskReads = Get-Counter '\Physikalischer Datenträger(_Total)\Lesevorgänge/Sek.' -ErrorAction SilentlyContinue
        $diskWrites = Get-Counter '\Physikalischer Datenträger(_Total)\Schreibvorgänge/Sek.' -ErrorAction SilentlyContinue
        
        if (-not $diskReads -or -not $diskWrites) {
            # Falls deutsch nicht funktioniert, versuche englisch
            $diskReads = Get-Counter '\PhysicalDisk(_Total)\Disk Reads/sec' -ErrorAction Stop
            $diskWrites = Get-Counter '\PhysicalDisk(_Total)\Disk Writes/sec' -ErrorAction Stop
        }
        
        return @{
            ReadsPerSec = [math]::Round($diskReads.CounterSamples[0].CookedValue, 2)
            WritesPerSec = [math]::Round($diskWrites.CounterSamples[0].CookedValue, 2)
        }
    }
    catch {
        Write-Verbose "Disk Activity via Performance Counter fehlgeschlagen: $_"
        return $null
    }
}

#endregion

#region Gesamt-Update-Funktion

<#
.SYNOPSIS
Sammelt alle verfügbaren Fallback-Sensor-Daten in einem Aufruf

.DESCRIPTION
Ruft alle Fallback-Funktionen auf und gibt ein einheitliches Datenobjekt zurück.
Optimal für Timer-basierte Updates.

.RETURNS
PSCustomObject mit allen verfügbaren Sensor-Daten

.EXAMPLE
$sensors = Get-FallbackMonitorUpdate
Write-Host "CPU: $($sensors.CPU.Load)% | $($sensors.CPU.Temperature)°C"
Write-Host "RAM: $($sensors.RAM.UsedPercent)% ($($sensors.RAM.UsedGB)GB / $($sensors.RAM.TotalGB)GB)"
#>
function Get-FallbackMonitorUpdate {
    $cpuLoad = Get-CpuLoadFallback
    $cpuTemp = Get-CpuTemperatureFallback
    $ramUsage = Get-MemoryUsageFallback
    $diskActivity = Get-DiskActivityFallback
    
    return [PSCustomObject]@{
        Timestamp = Get-Date
        CPU = @{
            Load = $cpuLoad
            Temperature = $cpuTemp  # Kann $null sein wenn keine Thermal Zones
            TemperatureAvailable = $null -ne $cpuTemp
        }
        RAM = @{
            UsedPercent = if ($ramUsage) { $ramUsage.UsedPercent } else { $null }
            UsedGB = if ($ramUsage) { $ramUsage.UsedGB } else { $null }
            FreeGB = if ($ramUsage) { $ramUsage.FreeGB } else { $null }
            TotalGB = if ($ramUsage) { $ramUsage.TotalGB } else { $null }
            Available = $null -ne $ramUsage
        }
        Disk = @{
            ReadsPerSec = if ($diskActivity) { $diskActivity.ReadsPerSec } else { $null }
            WritesPerSec = if ($diskActivity) { $diskActivity.WritesPerSec } else { $null }
            Available = $null -ne $diskActivity
        }
        GPU = @{
            # GPU-Daten nicht verfügbar im Fallback-Modus
            Temperature = $null
            Load = $null
            Power = $null
            Available = $false
        }
    }
}

#endregion

#region Diagnose-Funktionen

<#
.SYNOPSIS
Zeigt verfügbare Fallback-Sensor-Informationen

.DESCRIPTION
Testet alle Fallback-Methoden und zeigt an, welche funktionieren.
Nützlich für Debugging und User-Support.

.EXAMPLE
Get-FallbackSensorsInfo
#>
function Get-FallbackSensorsInfo {
    Write-Host "`n╔════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║  Fallback Sensoren - Verfügbarkeitstest       ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════╝`n" -ForegroundColor Cyan
    
    # Test 1: CPU-Load
    Write-Host "[1/4] CPU-Auslastung (Performance Counter)..." -NoNewline
    $cpuLoad = Get-CpuLoadFallback
    if ($null -ne $cpuLoad) {
        Write-Host " ✓ Verfügbar ($cpuLoad%)" -ForegroundColor Green
    } else {
        Write-Host " ✗ Nicht verfügbar" -ForegroundColor Red
    }
    
    # Test 2: Thermal Zones
    Write-Host "[2/4] CPU-Temperatur (WMI Thermal Zones)..." -NoNewline
    $thermalZones = Get-ThermalZonesFallback
    if ($thermalZones -and $thermalZones.Count -gt 0) {
        $maxTemp = ($thermalZones.Values | Measure-Object -Maximum).Maximum
        Write-Host " ✓ Verfügbar ($($thermalZones.Count) Zonen, max $maxTemp°C)" -ForegroundColor Green
        foreach ($zone in $thermalZones.GetEnumerator()) {
            Write-Host "    - $($zone.Key): $($zone.Value)°C" -ForegroundColor Gray
        }
    } else {
        Write-Host " ✗ Nicht verfügbar (normal bei vielen Systemen)" -ForegroundColor Yellow
    }
    
    # Test 3: RAM-Usage
    Write-Host "[3/4] RAM-Auslastung (CIM)..." -NoNewline
    $ramUsage = Get-MemoryUsageFallback
    if ($ramUsage) {
        Write-Host " ✓ Verfügbar ($($ramUsage.UsedGB)GB / $($ramUsage.TotalGB)GB)" -ForegroundColor Green
    } else {
        Write-Host " ✗ Nicht verfügbar" -ForegroundColor Red
    }
    
    # Test 4: Disk Activity
    Write-Host "[4/4] Disk-Aktivität (Performance Counter)..." -NoNewline
    $diskActivity = Get-DiskActivityFallback
    if ($diskActivity) {
        Write-Host " ✓ Verfügbar ($($diskActivity.ReadsPerSec) R/s, $($diskActivity.WritesPerSec) W/s)" -ForegroundColor Green
    } else {
        Write-Host " ✗ Nicht verfügbar" -ForegroundColor Red
    }
    
    Write-Host "`n" -NoNewline
    
    # Zusammenfassung
    $availableCount = 0
    if ($cpuLoad) { $availableCount++ }
    if ($thermalZones) { $availableCount++ }
    if ($ramUsage) { $availableCount++ }
    if ($diskActivity) { $availableCount++ }
    
    if ($availableCount -eq 4) {
        Write-Host "✓ Alle Fallback-Sensoren verfügbar" -ForegroundColor Green
    } elseif ($availableCount -ge 2) {
        Write-Host "⚠ Eingeschränkte Fallback-Funktionalität ($availableCount/4 Sensoren)" -ForegroundColor Yellow
    } else {
        Write-Host "✗ Minimale Fallback-Funktionalität ($availableCount/4 Sensoren)" -ForegroundColor Red
    }
    
    Write-Host "`n╔════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║  HINWEIS: Für vollständige Hardware-Daten     ║" -ForegroundColor Cyan
    Write-Host "╠════════════════════════════════════════════════╣" -ForegroundColor Cyan
    Write-Host "║  1. winget install namazso.PawnIO             ║" -ForegroundColor White
    Write-Host "║  2. winget install LibreHardwareMonitor...    ║" -ForegroundColor White
    Write-Host "║  3. Anwendung neu starten                     ║" -ForegroundColor White
    Write-Host "╚════════════════════════════════════════════════╝`n" -ForegroundColor Cyan
}

<#
.SYNOPSIS
Testet Fallback-Verfügbarkeit und gibt Ergebnis als Objekt zurück

.DESCRIPTION
Ähnlich wie Get-FallbackSensorsInfo, aber gibt strukturiertes Objekt zurück
statt Konsolen-Ausgabe. Für programmatische Verwendung.

.RETURNS
PSCustomObject mit Verfügbarkeits-Flags

.EXAMPLE
$capabilities = Test-FallbackCapabilities
if ($capabilities.CPULoad) {
    Write-Host "CPU-Load verfügbar"
}
#>
function Test-FallbackCapabilities {
    $cpuLoad = Get-CpuLoadFallback
    $thermalZones = Get-ThermalZonesFallback
    $ramUsage = Get-MemoryUsageFallback
    $diskActivity = Get-DiskActivityFallback
    
    return [PSCustomObject]@{
        CPULoad = $null -ne $cpuLoad
        CPUTemperature = $null -ne $thermalZones
        RAMUsage = $null -ne $ramUsage
        DiskActivity = $null -ne $diskActivity
        ThermalZonesCount = if ($thermalZones) { $thermalZones.Count } else { 0 }
        HasAnyCapability = ($null -ne $cpuLoad) -or ($null -ne $thermalZones) -or ($null -ne $ramUsage) -or ($null -ne $diskActivity)
    }
}

#endregion

#region Exportierte Funktionen

# Exportiere alle Funktionen
Export-ModuleMember -Function @(
    # CPU-Funktionen
    'Get-CpuLoadFallback',
    'Get-ThermalZonesFallback',
    'Get-CpuTemperatureFallback',
    
    # RAM-Funktionen
    'Get-MemoryUsageFallback',
    
    # Disk-Funktionen
    'Get-DiskActivityFallback',
    
    # Gesamt-Update
    'Get-FallbackMonitorUpdate',
    
    # Diagnose
    'Get-FallbackSensorsInfo',
    'Test-FallbackCapabilities'
)

#endregion

<#
VERWENDUNGS-BEISPIELE:
════════════════════

# Beispiel 1: Einmalige Sensor-Abfrage
$sensors = Get-FallbackMonitorUpdate
Write-Host "CPU: $($sensors.CPU.Load)%"
Write-Host "RAM: $($sensors.RAM.UsedPercent)%"

# Beispiel 2: Verfügbarkeit testen
$caps = Test-FallbackCapabilities
if ($caps.CPUTemperature) {
    $temp = Get-CpuTemperatureFallback
    Write-Host "CPU-Temperatur: $temp°C"
}

# Beispiel 3: Diagnose anzeigen
Get-FallbackSensorsInfo

# Beispiel 4: Timer-basiertes Monitoring
$timer = New-Object System.Timers.Timer
$timer.Interval = 2000  # 2 Sekunden
$timer.Add_Elapsed({
    $sensors = Get-FallbackMonitorUpdate
    Write-Host "CPU: $($sensors.CPU.Load)% | RAM: $($sensors.RAM.UsedPercent)%"
})
$timer.Start()

# Beispiel 5: Nur RAM-Daten
$ram = Get-MemoryUsageFallback
if ($ram) {
    Write-Host "RAM: $($ram.UsedGB)GB / $($ram.TotalGB)GB ($($ram.UsedPercent)%)"
}

# Beispiel 6: Nur CPU-Last (garantiert verfügbar)
$cpuLoad = Get-CpuLoadFallback
Write-Host "CPU-Auslastung: $cpuLoad%"
#>

# Test-DDR5TempViaLHM.ps1
# Liest DDR5 RAM-Temperatur via LibreHardwareMonitor Ring0 + Intel I801 SMBus
# Strategie: LHM Computer.Open() -> Ring0 initialisiert -> PCI Config + I/O Port lesen

$ErrorActionPreference = 'Continue'
$null = Start-Transcript -Path "$env:TEMP\ddr5lhm_$(Get-Date -Format 'HHmmss').txt" -Force

$libPath = "C:\Users\ReXx\Desktop\VS-CODE-Repos\Bockis-Win_Gui_DEV\Lib"

Write-Host "=== DDR5 Temperatur via LHM Ring0 ===" -ForegroundColor Cyan
Write-Host ""

# ============================================================
# 1) ALLE DLLs laden (LHM zuletzt)
# ============================================================
Write-Host "[1] Lade DLLs..." -ForegroundColor Yellow
$dlls = @(
    'System.Security.AccessControl.dll', 'System.Security.Principal.Windows.dll',
    'System.Threading.AccessControl.dll', 'System.Memory.dll',
    'System.Runtime.CompilerServices.Unsafe.dll', 'System.Numerics.Vectors.dll',
    'BlackSharp.Core.dll', 'RAMSPDToolkit-NDD.dll', 'LibreHardwareMonitorLib.dll'
)
foreach ($dll in $dlls) {
    $p = Join-Path $libPath $dll
    if (Test-Path $p) {
        try { Add-Type -Path $p -EA Stop; Write-Host "  OK: $dll" -ForegroundColor Green }
        catch {
            if ($_.Exception.Message -match "already|bereits") { Write-Host "  SK: $dll" -ForegroundColor DarkGreen }
            else { Write-Host "  ER: $dll - $($_.Exception.Message.Split("`n")[0])" -ForegroundColor Yellow }
        }
    } else { Write-Host "  NF: $dll" -ForegroundColor DarkYellow }
}

# ============================================================
# 2) LHM Computer.Open() -> initialisiert Ring0/PawnIO  
# ============================================================
Write-Host "`n[2] LibreHardwareMonitor Computer.Open()..." -ForegroundColor Yellow
$computer = $null
try {
    $computer = New-Object LibreHardwareMonitor.Hardware.Computer
    $computer.IsCpuEnabled = $true       # CPU braucht Ring0
    $computer.IsMotherboardEnabled = $true
    $computer.IsMemoryEnabled = $true
    $computer.Open()
    Write-Host "  Computer.Open() OK - Hardware-Anzahl: $($computer.Hardware.Count)" -ForegroundColor Green
    $computer.Hardware | ForEach-Object { Write-Host "    - $($_.HardwareType): $($_.Name)" -ForegroundColor Gray }
} catch {
    $inner = $_.Exception; while ($inner.InnerException) { $inner = $inner.InnerException }
    Write-Host "  FEHLER: $($inner.Message)" -ForegroundColor Red
}

# ============================================================
# 3) LHM Ring0 Klasse finden und inspizieren
# ============================================================
Write-Host "`n[3] Suche LHM Ring0 Klasse..." -ForegroundColor Yellow
$lhmAsm = [AppDomain]::CurrentDomain.GetAssemblies() | Where-Object { $_.FullName -match 'LibreHardwareMonitor' } | Select-Object -First 1
$ring0Type = $null
if ($lhmAsm) {
    Write-Host "  LHM Assembly: $($lhmAsm.GetName().Name)" -ForegroundColor Green
    
    # Ring0 Klasse suchen
    $ringTypes = $lhmAsm.GetTypes() | Where-Object { $_.Name -match 'Ring0|PawnIO|Hardware.*Port|IoPort' }
    foreach ($rt in $ringTypes) {
        Write-Host "  Typ: $($rt.FullName) [IsAbstract:$($rt.IsAbstract)]" -ForegroundColor Cyan
        $rt.GetMethods([System.Reflection.BindingFlags]'Public,Static') | Where-Object { $_.Name -match 'Port|Pci|Read|Write|Find' } | ForEach-Object {
            $p = ($_.GetParameters() | ForEach-Object { $_.ParameterType.Name + ' ' + $_.Name }) -join ', '
            Write-Host "    [static] $($_.ReturnType.Name) $($_.Name)($p)" -ForegroundColor Gray
        }
        if ($rt.Name -match 'Ring0') { $ring0Type = $rt }
    }
} else { Write-Host "  LHM Assembly nicht gefunden!" -ForegroundColor Red }

# ============================================================
# 4) RAMSPDToolkit nach LHM Init - DDR5 Temperatur lesen!  
# ============================================================
Write-Host "`n[4] RAMSPDToolkit nach LHM.Open() - DDR5 Temperatur lesen..." -ForegroundColor Yellow
$ramspdAsm = [AppDomain]::CurrentDomain.GetAssemblies() | Where-Object { $_.FullName -match 'RAMSPDToolkit' } | Select-Object -First 1
$driverMgrType = $ramspdAsm.GetType('RAMSPDToolkit.Windows.Driver.DriverManager')
$driverAccType = $ramspdAsm.GetType('RAMSPDToolkit.Windows.Driver.DriverAccess')
$smBusMgrType = $ramspdAsm.GetType('RAMSPDToolkit.I2CSMBus.SMBusManager')
$winDetType = $ramspdAsm.GetType('RAMSPDToolkit.I2CSMBus.WindowsSMBusDetector')
$spdDetType = $ramspdAsm.GetType('RAMSPDToolkit.SPD.SPDDetector')
$memTypeEnumT = $ramspdAsm.GetType('RAMSPDToolkit.SPD.Interop.Shared.SPDMemoryType')
$ddr5Val = [Enum]::Parse($memTypeEnumT, 'SPD_DDR5_SDRAM')
$ddr4Val = [Enum]::Parse($memTypeEnumT, 'SPD_DDR4_SDRAM')

Write-Host "  DriverAccess.IsOpen vorher: $($driverAccType.GetProperty('IsOpen').GetValue($null))" -ForegroundColor Gray

# LoadDriver() - funktioniert NACH Computer.Open()
$loaded = $driverMgrType.GetMethod('LoadDriver').Invoke($null, $null)
Write-Host "  LoadDriver(): $loaded" -ForegroundColor $(if ($loaded) { 'Green' }else { 'Red' })

$isOpen = $driverAccType.GetProperty('IsOpen').GetValue($null)
Write-Host "  DriverAccess.IsOpen nach LoadDriver: $isOpen" -ForegroundColor $(if ($isOpen) { 'Green' }else { 'Red' })

if ($isOpen) {
    Write-Host "`n  SMBus-Erkennung..." -ForegroundColor Yellow
    # DetectSMBuses kann werfen, aber trotzdem Busse registrieren
    try { $winDetType.GetMethod('DetectSMBuses').Invoke($null, $null) | Out-Null } catch {}
    
    # Direkt die einzelnen Typen versuchen (I801 für Intel)
    $smbI801Type = $ramspdAsm.GetType('RAMSPDToolkit.I2CSMBus.SMBusI801')
    $sdMeth = $smbI801Type.GetMethod('SMBusDetect', [System.Reflection.BindingFlags]'Public,NonPublic,Static')
    try { $sdMeth.Invoke($null, $null) } catch {}
    
    $buses = $smBusMgrType.GetProperty('RegisteredSMBuses').GetValue($null)
    Write-Host "  Registrierte SMBus-Controller: $($buses.Count)" -ForegroundColor Cyan
    
    $foundTemps = @()
    
    foreach ($bus in $buses) {
        $busName = try { $bus.DeviceName } catch { "UnknownBus" }
        $portId = try { $bus.PortID } catch { "?" }
        Write-Host ""
        Write-Host "  Bus: '$busName' Port:$portId" -ForegroundColor Cyan
        
        # DDR5: Adressen 0x18-0x1F (JEDEC DDR5 SPD Hub)
        Write-Host "  DDR5 Scan (0x18-0x1F):" -ForegroundColor Yellow
        for ($addr = 0x18; $addr -le 0x1F; $addr++) {
            try {
                $det = [Activator]::CreateInstance($spdDetType, @($bus, [byte]$addr, $ddr5Val))
                if ($det.IsValid) {
                    $acc = $det.Accessor
                    $mfr = try { $acc.GetModuleManufacturerString() } catch { "?" }
                    $pn = try { $acc.ModulePartNumber().Trim() } catch { $acc.ModulePartNumber }
                    $hasTs = $acc.HasThermalSensor
                    Write-Host "    DIMM @ 0x$('{0:X2}' -f $addr): Hersteller='$mfr' PN='$pn' HasThermalSensor:$hasTs" -ForegroundColor Green
                    
                    if ($hasTs) {
                        $updateOk = $acc.UpdateTemperature()
                        $temp = $acc.Temperature
                        Write-Host "    *** TEMPERATUR: $([math]::Round($temp, 1)) °C (Update:$updateOk) ***" -ForegroundColor Cyan
                        $foundTemps += [PSCustomObject]@{ Addr = $addr; Temp = $temp; PN = $pn }
                    }
                }
            } catch {
                $inner = $_.Exception; while ($inner.InnerException) { $inner = $inner.InnerException }
                # Nur wenn kein "not valid" oder ähnliches:
                if ($inner.Message -notmatch 'Index|range|bounds') {
                    # Write-Host "    0x$('{0:X2}' -f $addr): $($inner.Message.Split("`n")[0])" -ForegroundColor DarkGray
                }
            }
        }
        
        # DDR4 Fallback (falls DDR4 System)
        Write-Host "  DDR4 Scan (0x18-0x1F):" -ForegroundColor Yellow
        for ($addr = 0x18; $addr -le 0x1F; $addr++) {
            try {
                $det = [Activator]::CreateInstance($spdDetType, @($bus, [byte]$addr, $ddr4Val))
                if ($det.IsValid) {
                    $acc = $det.Accessor
                    $hasTs = $acc.HasThermalSensor
                    Write-Host "    DDR4-DIMM @ 0x$('{0:X2}' -f $addr): HasThermalSensor:$hasTs" -ForegroundColor Green
                    if ($hasTs) {
                        $acc.UpdateTemperature()
                        Write-Host "    *** TEMPERATUR: $([math]::Round($acc.Temperature, 1)) °C ***" -ForegroundColor Cyan
                        $foundTemps += [PSCustomObject]@{ Addr = $addr; Temp = $acc.Temperature; PN = "DDR4" }
                    }
                }
            } catch {}
        }
    }
    
    Write-Host ""
    if ($foundTemps.Count -gt 0) {
        Write-Host "  ===== GEFUNDENE TEMPERATUREN =====" -ForegroundColor Green
        $foundTemps | ForEach-Object { Write-Host "  DIMM 0x$('{0:X2}' -f $_.Addr): $([math]::Round($_.Temp, 1))°C  [$($_.PN)]" -ForegroundColor Green }
        Write-Host "  Max: $([math]::Round(($foundTemps.Temp | Measure-Object -Maximum).Maximum, 1))°C" -ForegroundColor Cyan
        Write-Host "  Min: $([math]::Round(($foundTemps.Temp | Measure-Object -Minimum).Minimum, 1))°C" -ForegroundColor Cyan
    } else {
        Write-Host "  KEINE Temperaturen gefunden - Diagnose..." -ForegroundColor Yellow
        
        # Bus-Typ und alle Methoden anzeigen (erstes Bus-Objekt)
        $bus0 = $buses[0]
        Write-Host "`n  Bus-Objekt Typ: $($bus0.GetType().FullName)" -ForegroundColor Cyan
        $bus0.GetType().GetProperties() | ForEach-Object {
            try { $v = $_.GetValue($bus0); Write-Host "    $($_.Name) = $v" -ForegroundColor Gray }
            catch { Write-Host "    $($_.Name) = ERROR: $($_.Exception.InnerException.Message)" -ForegroundColor DarkRed }
        }
        
        # Bus-Methoden auflisten  
        $busMethods = $bus0.GetType().GetMethods([System.Reflection.BindingFlags]'Public,Instance') | Where-Object { $_.DeclaringType -ne [object] }
        Write-Host "  Bus-Methoden:" -ForegroundColor Cyan
        $busMethods | ForEach-Object {
            $p = ($_.GetParameters() | ForEach-Object { $_.ParameterType.Name + ' ' + $_.Name }) -join ', '
            Write-Host "    $($_.ReturnType.Name) $($_.Name)($p)" -ForegroundColor Gray
        }
        
        # DIREKTER I2C-TEST via SMBusPawnIO Methoden
        Write-Host "`n  === DIREKTER I2C-SCAN via i2c_smbus_* Methoden ===" -ForegroundColor Cyan
        $rbd = $bus0.GetType().GetMethod('i2c_smbus_read_byte_data')
        $rwds = $bus0.GetType().GetMethod('i2c_smbus_read_word_data_swapped')
        $wq = $bus0.GetType().GetMethod('i2c_smbus_write_quick')
        $rb = $bus0.GetType().GetMethod('i2c_smbus_read_byte')
        
        # write_quick Scan 0x00-0x7F
        Write-Host "  I2C-Bus-Scan via write_quick (0x00-0x7F)..." -ForegroundColor Yellow
        $respondingAddrs = @()
        for ($addr = 0; $addr -le 0x7F; $addr++) {
            try { $r = $wq.Invoke($bus0, @([byte]$addr, [byte]0)); if ($r -ge 0) { $respondingAddrs += $addr } } catch {}
        }
        Write-Host "  Antwortende Adressen: $(($respondingAddrs | ForEach-Object { '0x'+$_.ToString('X2') })-join', ')" -ForegroundColor $(if ($respondingAddrs.Count -gt 0) { 'Green' }else { 'Red' })
        if ($respondingAddrs.Count -eq 0) { Write-Host "  KEINE Geräte! SMBus komplett blockiert (BAM)" -ForegroundColor Red }
        
        # Für jede antwortende Adresse: Register 0x00-0x10 lesen
        foreach ($addr in $respondingAddrs) {
            Write-Host "`n  Register-Dump @ 0x$('{0:X2}' -f $addr):" -ForegroundColor Cyan
            $regLine = ''
            for ($reg = 0; $reg -le 0x0F; $reg++) {
                try {
                    $v = $rbd.Invoke($bus0, @([byte]$addr, [byte]$reg))
                    if ($v -ge 0) { $regLine += "0x$('{0:X2}' -f $reg)=0x$('{0:X2}' -f $v)($v)  " }
                    else { $regLine += "0x$('{0:X2}' -f $reg)=ERR  " }
                } catch { $regLine += "0x$('{0:X2}' -f $reg)=EX  " }
            }
            Write-Host "    $regLine" -ForegroundColor Gray
        }
        
        # Spezieller DDR5~Temperatur-Versuch: Verschiedene Temp-Register-Kombinationen
        Write-Host "`n  DDR5 Temp-Auslese-Varianten (für 0x19 und 0x1B)..." -ForegroundColor Yellow
        foreach ($da in @(0x19, 0x1B)) {
            Write-Host "  Adresse 0x$('{0:X2}' -f $da):" -ForegroundColor Cyan
            
            # Variante A: Register 0x05 (Low) + 0x06 (High) als separate Byte-Reads
            try {
                $lo = $rbd.Invoke($bus0, @([byte]$da, [byte]0x05))
                $hi = $rbd.Invoke($bus0, @([byte]$da, [byte]0x06))
                if ($lo -ge 0 -and $hi -ge 0) {
                    $w = ([int]$hi -shl 8) -bor ([int]$lo -band 0xFF)
                    $tempC = ($w -band 0x1FFF) * 0.0625
                    if ($w -band 0x1000) { $tempC -= 256.0 }
                    Write-Host "    Reg[05]+[06]= 0x$('{0:X2}' -f $lo) 0x$('{0:X2}' -f $hi) = Word 0x$('{0:X4}' -f $w) → Temp≈$([math]::Round($tempC,1))°C" -ForegroundColor Green
                }
            } catch {}
            
            # Variante B: Register 0x05 als einziges Byte (simpler Sensor format?)
            try {
                $t = $rbd.Invoke($bus0, @([byte]$da, [byte]0x05))
                Write-Host "    ReadByteData(0x05)=$t" -ForegroundColor Gray
            } catch {}
            
            # Variante C: ReadByte ohne Register (device-selected register)
            try {
                $t = $rb.Invoke($bus0, @([byte]$da))
                Write-Host "    ReadByte()=$t" -ForegroundColor Gray
            } catch {}
            
            # Variante D: Für LM75/TMP75-kompatibles Format (Reg 0x00 = Temperatur)
            try {
                $lo = $rbd.Invoke($bus0, @([byte]$da, [byte]0x00))
                $hi = $rbd.Invoke($bus0, @([byte]$da, [byte]0x01))
                if ($lo -ge 0 -and $hi -ge 0) {
                    $w = ([int]$lo -shl 8) -bor ([int]$hi -band 0xFF)
                    $tempLM75 = [math]::Round($w / 256.0, 1)
                    Write-Host "    LM75-Format Reg[0x00:0x01]: 0x$('{0:X2}' -f $lo) 0x$('{0:X2}' -f $hi) = Temp≈$tempLM75°C" -ForegroundColor Gray
                }
            } catch {}
        }
        
        # Diagnose für 0x49 und 0x4B (oft Motherboard-Temperatursensoren - TMP75 Format)
        Write-Host "`n  Diagnose 0x49 und 0x4B (Board-Temp-Sensoren?)..." -ForegroundColor Yellow
        foreach ($da in @(0x44, 0x49, 0x4B) | Where-Object { $respondingAddrs -contains $_ }) {
            Write-Host "  @ 0x$('{0:X2}' -f $da): Regs [0-3]:" -ForegroundColor Cyan
            for ($reg = 0; $reg -le 3; $reg++) {
                try {
                    $v = $rbd.Invoke($bus0, @([byte]$da, [byte]$reg))
                    Write-Host "    Reg[$reg] = $v (0x$('{0:X2}' -f ($v -band 0xFF)))" -ForegroundColor Gray
                } catch {}
            }
        }
    }
}

# ============================================================
# 5) LHM PawnIo Typ inspizieren
# ============================================================
Write-Host "`n[5] LibreHardwareMonitor PawnIo-Typen..." -ForegroundColor Yellow
if ($lhmAsm) {
    $lhmPawnTypes = $lhmAsm.GetTypes() | Where-Object { $_.FullName -match 'PawnIo|RAMSPDToolkit' }
    foreach ($t in $lhmPawnTypes) {
        Write-Host "  $($t.FullName) [isAbstract:$($t.IsAbstract)]" -ForegroundColor Cyan
        $t.GetMethods([System.Reflection.BindingFlags]'Public,Static,Instance') | Where-Object { $_.DeclaringType -eq $t } | ForEach-Object {
            $p = ($_.GetParameters() | ForEach-Object { $_.ParameterType.Name + ' ' + $_.Name }) -join ', '
            $st = if ($_.IsStatic) { 'static' }else { 'inst' }
            Write-Host "    [$st] $($_.ReturnType.Name) $($_.Name)($p)" -ForegroundColor Gray
        }
    }
}


# ============================================================
# 6) Abschluss: Cleanup
# ============================================================
Write-Host "`n=== Test abgeschlossen ===" -ForegroundColor Cyan
if ($computer) { try { $computer.Close() } catch {} }
Stop-Transcript

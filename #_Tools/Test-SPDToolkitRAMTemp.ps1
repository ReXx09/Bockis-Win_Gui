# Test-SPDToolkitRAMTemp.ps1
# Testet RAMSPDToolkit-NDD.dll für RAM-Temperatur-Auslese

$ErrorActionPreference = 'Continue'
$outFile = "$env:TEMP\spd_test_$(Get-Date -Format 'HHmmss').txt"
$null = Start-Transcript -Path $outFile -Force
$libPath = "C:\Users\ReXx\Desktop\VS-CODE-Repos\Bockis-Win_Gui_DEV\Lib"

Write-Host "=== RAMSPDToolkit RAM-Temperatur Test ===" -ForegroundColor Cyan
Write-Host ""

# 1) DLLs laden
Write-Host "[1] Lade Abhängigkeiten..." -ForegroundColor Yellow
foreach ($dll in @('System.Security.AccessControl.dll', 'System.Security.Principal.Windows.dll', 'System.Threading.AccessControl.dll', 'System.Memory.dll', 'System.Runtime.CompilerServices.Unsafe.dll', 'System.Numerics.Vectors.dll', 'BlackSharp.Core.dll', 'RAMSPDToolkit-NDD.dll')) {
    $path = Join-Path $libPath $dll
    if (Test-Path $path) {
        try { Add-Type -Path $path -EA Stop; Write-Host "  OK: $dll" -ForegroundColor Green }
        catch {
            if ($_.Exception.Message -match "already loaded|bereits geladen") { Write-Host "  SK: $dll (bereits geladen)" -ForegroundColor DarkGreen }
            else { Write-Host "  ER: $dll - $($_.Exception.Message.Split("`n")[0])" -ForegroundColor Red }
        }
    } else { Write-Host "  NF: $dll (nicht gefunden)" -ForegroundColor DarkYellow }
}
Write-Host ""

# 2) SMBusPawnIO via Reflection erstellen
Write-Host "[2] Erstelle SMBusPawnIO via Reflection..." -ForegroundColor Yellow
try {
    # Alle geladenen Assemblies durchsuchen
    $ramspdAsm = [AppDomain]::CurrentDomain.GetAssemblies() | Where-Object { $_.FullName -match 'RAMSPDToolkit' } | Select-Object -First 1
    if (-not $ramspdAsm) { throw "Assembly RAMSPDToolkit nicht geladen" }
    Write-Host "  Assembly: $($ramspdAsm.FullName)" -ForegroundColor Green
    
    # SMBusPawnIO Typ holen
    $smbusType = $ramspdAsm.GetType('RAMSPDToolkit.I2CSMBus.SMBusPawnIO')
    if (-not $smbusType) { throw "SMBusPawnIO Typ nicht gefunden" }
    Write-Host "  SMBusPawnIO Typ gefunden" -ForegroundColor Green
    
    # Konstruktoren anzeigen
    $ctors = $smbusType.GetConstructors([System.Reflection.BindingFlags]::Public -bor [System.Reflection.BindingFlags]::NonPublic -bor [System.Reflection.BindingFlags]::Instance)
    Write-Host "  Konstruktoren ($($ctors.Count)):" -ForegroundColor Cyan
    $ctors | ForEach-Object {
        $params = ($_.GetParameters() | ForEach-Object { $_.ParameterType.Name + ' ' + $_.Name }) -join ', '
        Write-Host "    ctor($params) [Public:$($_.IsPublic), Internal:$($_.IsAssembly)]" -ForegroundColor Gray
    }
    
    # === KORREKTE IMPLEMENTIERUNG via statische API (Reflection) ===
    Write-Host "`n[2b] Starte RAMSPDToolkit via statischer API (Reflection)..." -ForegroundColor Yellow
    
    # Alle Typen via Reflection
    $driverMgrType = $ramspdAsm.GetType('RAMSPDToolkit.Windows.Driver.DriverManager')
    $driverAccType = $ramspdAsm.GetType('RAMSPDToolkit.Windows.Driver.DriverAccess')
    $winDetType = $ramspdAsm.GetType('RAMSPDToolkit.I2CSMBus.WindowsSMBusDetector')
    $smBusMgrType = $ramspdAsm.GetType('RAMSPDToolkit.I2CSMBus.SMBusManager')
    $spdDetType = $ramspdAsm.GetType('RAMSPDToolkit.SPD.SPDDetector')
    
    # Enum-Werte prüfen
    Write-Host "  SPDMemoryType Enum-Werte:" -ForegroundColor Cyan
    $memTypeEnumT = $ramspdAsm.GetType('RAMSPDToolkit.SPD.Interop.Shared.SPDMemoryType')
    [Enum]::GetNames($memTypeEnumT) | ForEach-Object {
        $v = [Enum]::Parse($memTypeEnumT, $_)
        Write-Host "    $_ = $([int]$v)" -ForegroundColor Gray
    }
    
    $ddr5Name = [Enum]::GetNames($memTypeEnumT) | Where-Object { $_ -match 'DDR5|Ddr5' } | Select-Object -First 1
    $ddr4Name = [Enum]::GetNames($memTypeEnumT) | Where-Object { $_ -match 'DDR4|Ddr4' } | Select-Object -First 1
    Write-Host "  DDR5 Name: $ddr5Name  |  DDR4 Name: $ddr4Name" -ForegroundColor Yellow
    $ddr5Val = if ($ddr5Name) { [Enum]::Parse($memTypeEnumT, $ddr5Name) } else { $null }
    $ddr4Val = if ($ddr4Name) { [Enum]::Parse($memTypeEnumT, $ddr4Name) } else { $null }
    
    # PawnIO-Dienststatus zuerst prüfen
    $pawnSvc = Get-Service -Name 'PawnIO' -ErrorAction SilentlyContinue
    Write-Host "  PawnIO Dienst: $(if($pawnSvc){"$($pawnSvc.Status)"}else{'NICHT INSTALLIERT'})" -ForegroundColor $(if ($pawnSvc -and $pawnSvc.Status -eq 'Running') { 'Green' }else { 'Yellow' })
    
    # SMBusManager UseWMI setzen (NDD = No Device Driver → WMI-Modus)
    Write-Host "  Setze SMBusManager.UseWMI = true..." -ForegroundColor Yellow
    $smBusMgrType.GetProperty('UseWMI').SetValue($null, $true)
    
    # PawnIO Device-Diagnose per CreateFile
    Write-Host "`n  PawnIO Device-Diagnose per CreateFile..." -ForegroundColor Yellow
    try {
        Add-Type -Name WinAPI2 -Namespace PawnIOTest -MemberDefinition @'
[DllImport("kernel32.dll", SetLastError=true, CharSet=CharSet.Auto)]
public static extern IntPtr CreateFile(string lpFileName, int dwDesiredAccess,
    int dwShareMode, IntPtr lpSecurityAttributes, int dwCreationDisposition,
    int dwFlagsAndAttributes, IntPtr hTemplateFile);
[DllImport("kernel32.dll", SetLastError=true)]
public static extern bool CloseHandle(IntPtr hObject);
[DllImport("kernel32.dll")]
public static extern int GetLastError();
[DllImport("kernel32.dll", SetLastError=true)]
public static extern bool DeviceIoControl(IntPtr hDevice, uint dwIoControlCode,
    IntPtr lpInBuffer, uint nInBufferSize, IntPtr lpOutBuffer, uint nOutBufferSize,
    out uint lpBytesReturned, IntPtr lpOverlapped);
'@ -ErrorAction SilentlyContinue
    } catch {}
    
    $pawnHandle = [IntPtr]::Zero
    try {
        $h = [PawnIOTest.WinAPI2]::CreateFile("\\.\PawnIO", [int]-1073741824, 3, [IntPtr]::Zero, 3, 0, [IntPtr]::Zero)
        $le = [PawnIOTest.WinAPI2]::GetLastError()
        if ($h.ToInt64() -ne -1 -and $h.ToInt64() -ne 0) {
            Write-Host "  \\.\PawnIO: OFFEN (Handle=$($h.ToInt64()))" -ForegroundColor Green
            $pawnHandle = $h
        } else {
            Write-Host "  \\.\PawnIO: FEHLER LastError=$le" -ForegroundColor Red
        }
    } catch { Write-Host "  CreateFile-Test Fehler: $($_.Exception.Message.Split("`n")[0])" -ForegroundColor DarkYellow }
    
    # DriverManager.LoadDriver() detailliert
    Write-Host "  DriverManager.LoadDriver()..." -ForegroundColor Yellow
    try {
        $loaded = $driverMgrType.GetMethod('LoadDriver').Invoke($null, $null)
        Write-Host "  Geladen: $loaded" -ForegroundColor $(if ($loaded) { 'Green' }else { 'Yellow' })
    } catch { 
        $inner = $_.Exception; while ($inner.InnerException) { $inner = $inner.InnerException }
        Write-Host "  LoadDriver Ausnahme: [$($inner.GetType().Name)] $($inner.Message)" -ForegroundColor Red
    }
    
    # DriverManager - alle Methoden
    Write-Host "`n  === DriverManager Methoden ===" -ForegroundColor Cyan
    $driverMgrType.GetMethods([System.Reflection.BindingFlags]'Public,NonPublic,Static,Instance') | ForEach-Object {
        $p = ($_.GetParameters() | ForEach-Object { $_.ParameterType.Name + ' ' + $_.Name }) -join ', '
        $mod = if ($_.IsStatic) { 'static' }else { 'inst' }
        Write-Host "    [$mod] $($_.ReturnType.Name) $($_.Name)($p)" -ForegroundColor Gray
    }
    
    # DriverAccess - Instanz erstellen und Methoden prüfen
    Write-Host "`n  === DriverAccess Instanz ===" -ForegroundColor Cyan
    $driverAccCtors = $driverAccType.GetConstructors([System.Reflection.BindingFlags]'Public,NonPublic,Instance')
    $driverAccCtors | ForEach-Object {
        $p = ($_.GetParameters() | ForEach-Object { $_.ParameterType.Name + ' ' + $_.Name }) -join ', '
        Write-Host "    [$(if($_.IsPublic){'pub'}else{'prv'})] ctor($p)" -ForegroundColor Gray
    }
    $driverAccType.GetMethods([System.Reflection.BindingFlags]'Public,NonPublic,Static,Instance') | Where-Object { $_.DeclaringType -eq $driverAccType } | ForEach-Object {
        $p = ($_.GetParameters() | ForEach-Object { $_.ParameterType.Name + ' ' + $_.Name }) -join ', '
        $mod = if ($_.IsStatic) { 'static' }else { 'inst' }
        Write-Host "    [$mod] $($_.ReturnType.Name) $($_.Name)($p)" -ForegroundColor Gray
    }
    
    # IPawnIOModule Interface Methoden (Schlüssel für Custom-Implementierung)
    Write-Host "`n  === IPawnIOModule Interface Methoden ===" -ForegroundColor Cyan
    $iPawnIOMod = $ramspdAsm.GetType('RAMSPDToolkit.Windows.PawnIO.IPawnIOModule')
    if (-not $iPawnIOMod) { $iPawnIOMod = $ramspdAsm.GetTypes() | Where-Object { $_.Name -match 'IPawnIO|PawnIOModule' } | Select-Object -First 1 }
    if ($iPawnIOMod) {
        Write-Host "  Typ: $($iPawnIOMod.FullName)" -ForegroundColor Green
        $iPawnIOMod.GetMethods() | ForEach-Object {
            $p = ($_.GetParameters() | ForEach-Object { $_.ParameterType.Name + ' ' + $_.Name }) -join ', '
            Write-Host "    $($_.ReturnType.Name) $($_.Name)($p)" -ForegroundColor Gray
        }
        $iPawnIOMod.GetProperties() | ForEach-Object {
            Write-Host "    [prop] $($_.PropertyType.Name) $($_.Name)" -ForegroundColor DarkGray
        }
    } else {
        Write-Host "  IPawnIOModule NICHT gefunden! Suche..." -ForegroundColor Red
        $ramspdAsm.GetTypes() | Where-Object { $_.IsInterface } | ForEach-Object { Write-Host "    Interface: $($_.FullName)" -ForegroundColor Gray }
    }
    
    # PawnIOSMBusIdentifier enum/struct prüfen
    Write-Host "`n  === PawnIOSMBusIdentifier ===" -ForegroundColor Cyan
    $pawnIOSmbId = $ramspdAsm.GetType('RAMSPDToolkit.I2CSMBus.PawnIOSMBusIdentifier')
    if (-not $pawnIOSmbId) { $pawnIOSmbId = $ramspdAsm.GetTypes() | Where-Object { $_.Name -match 'PawnIOSMBus|SMBusIdentifier' } | Select-Object -First 1 }
    if ($pawnIOSmbId) {
        Write-Host "  Typ: $($pawnIOSmbId.FullName) IsEnum:$($pawnIOSmbId.IsEnum)" -ForegroundColor Green
        if ($pawnIOSmbId.IsEnum) {
            [Enum]::GetNames($pawnIOSmbId) | ForEach-Object { Write-Host "    $_ = $([int][Enum]::Parse($pawnIOSmbId, $_))" -ForegroundColor Gray }
        } else {
            $pawnIOSmbId.GetFields([System.Reflection.BindingFlags]'Public,NonPublic,Static,Instance') | ForEach-Object { Write-Host "    $($_.FieldType.Name) $($_.Name)" -ForegroundColor Gray }
        }
    } else { Write-Host "  PawnIOSMBusIdentifier nicht gefunden" -ForegroundColor DarkYellow }
    
    # Direkte SMBusDetect()-Aufrufe
    Write-Host "`n  Direkte SMBusDetect()-Aufrufe..." -ForegroundColor Yellow
    $smbI801Type = $ramspdAsm.GetType('RAMSPDToolkit.I2CSMBus.SMBusI801')
    $smbPiix4Type = $ramspdAsm.GetType('RAMSPDToolkit.I2CSMBus.SMBusPiix4')
    $smbNct6775 = $ramspdAsm.GetType('RAMSPDToolkit.I2CSMBus.SMBusNCT6775')
    
    foreach ($smType in @($smbI801Type, $smbPiix4Type, $smbNct6775) | Where-Object { $_ }) {
        $sdMeth = $smType.GetMethod('SMBusDetect', [System.Reflection.BindingFlags]'Public,NonPublic,Static')
        if (-not $sdMeth) { Write-Host "    $($smType.Name): kein SMBusDetect()" -ForegroundColor DarkGray; continue }
        Write-Host "    $($smType.Name).SMBusDetect()..." -ForegroundColor Gray
        try {
            $sdMeth.Invoke($null, $null)
            $bc = $smBusMgrType.GetProperty('RegisteredSMBuses').GetValue($null).Count
            Write-Host "    -> OK, RegisteredSMBuses: $bc" -ForegroundColor Green
        } catch {
            $inner = $_.Exception; while ($inner.InnerException) { $inner = $inner.InnerException }
            Write-Host "    -> FEHLER: [$($inner.GetType().Name)] $($inner.Message)" -ForegroundColor Red
        }
    }
    
    # === KRITISCHER TEST: DriverImplementation = PawnIO VORHER setzen ===
    Write-Host "`n  === Versuche DriverImplementation = PawnIO (3) setzen ===" -ForegroundColor Cyan
    $driverImplEnumT = $ramspdAsm.GetTypes() | Where-Object { $_.IsEnum -and $_.Name -match 'DriverImpl' } | Select-Object -First 1
    if ($driverImplEnumT) {
        $pawnIOImplVal = [Enum]::Parse($driverImplEnumT, 'PawnIO')
        Write-Host "  Setze DriverImplementation = PawnIO ($([int]$pawnIOImplVal))..." -ForegroundColor Yellow
        $driverMgrType.GetProperty('DriverImplementation').SetValue($null, $pawnIOImplVal)
        Write-Host "  Aktuell: $($driverMgrType.GetProperty('DriverImplementation').GetValue($null))" -ForegroundColor Gray
        
        Write-Host "  LoadDriver() nach Impl-Änderung..." -ForegroundColor Yellow
        try {
            $loaded2 = $driverMgrType.GetMethod('LoadDriver').Invoke($null, $null)
            Write-Host "  Ergebnis: $loaded2" -ForegroundColor $(if ($loaded2) { 'Green' }else { 'Yellow' })
            $drvNow = $driverAccType.GetMethod('GetDriver', [System.Reflection.BindingFlags]'Public,NonPublic,Static').Invoke($null, $null)
            Write-Host "  Treiber jetzt: $(if($drvNow){"OK: $($drvNow.GetType().FullName)"}else{'NULL'})" -ForegroundColor $(if ($drvNow) { 'Green' }else { 'Red' })
        } catch {
            $inner = $_.Exception; while ($inner.InnerException) { $inner = $inner.InnerException }
            Write-Host "  LoadDriver Fehler: [$($inner.GetType().Name)] $($inner.Message)" -ForegroundColor Red
        }
        
        # Nach erfolgreicher I801.SMBusDetect?
        Write-Host "  SMBusI801.SMBusDetect() nach PawnIO-Impl..." -ForegroundColor Yellow
        $smbI801Type = $ramspdAsm.GetType('RAMSPDToolkit.I2CSMBus.SMBusI801')
        $sdMeth = $smbI801Type.GetMethod('SMBusDetect', [System.Reflection.BindingFlags]'Public,NonPublic,Static')
        try {
            $sdMeth.Invoke($null, $null)
            $bc = $smBusMgrType.GetProperty('RegisteredSMBuses').GetValue($null).Count
            Write-Host "  RegisteredSMBuses: $bc" -ForegroundColor $(if ($bc -gt 0) { 'Green' }else { 'Yellow' })
        } catch {
            $inner = $_.Exception; while ($inner.InnerException) { $inner = $inner.InnerException }
            Write-Host "  SmbDetect Fehler: $($inner.Message)" -ForegroundColor Red
        }
    }
    
    # Alle geladenen Assemblies nach IDriver-Implementierungen durchsuchen
    Write-Host "`n  === Suche IDriver Implementierungen ALLER Assemblies ===" -ForegroundColor Cyan
    $iDriverType2 = $ramspdAsm.GetType('RAMSPDToolkit.Windows.Driver.Interfaces.IDriver')
    $iGenDrvType = $ramspdAsm.GetType('RAMSPDToolkit.Windows.Driver.Interfaces.IGenericDriver')
    [AppDomain]::CurrentDomain.GetAssemblies() | Where-Object { -not $_.IsDynamic } | ForEach-Object {
        $asm = $_
        try {
            $asm.GetTypes() | Where-Object { 
                -not $_.IsInterface -and -not $_.IsAbstract -and
                ($_.GetInterfaces() | Where-Object { $_ -eq $iDriverType2 -or $_ -eq $iGenDrvType })
            } | ForEach-Object {
                $t = $_
                Write-Host "  ASM: $($asm.GetName().Name) -> $($t.FullName)" -ForegroundColor Green
                $t.GetInterfaces() | ForEach-Object { Write-Host "    impl: $($_.Name)" -ForegroundColor Gray }
                $t.GetConstructors([System.Reflection.BindingFlags]'Public,NonPublic,Instance') | ForEach-Object {
                    $p = ($_.GetParameters() | ForEach-Object { $_.ParameterType.Name + ' ' + $_.Name }) -join ', '
                    Write-Host "    ctor($p)" -ForegroundColor DarkGray
                }
            }
        } catch { }
    }
    
    # BlackSharp.Core.dll spezifisch
    Write-Host "`n  === BlackSharp.Core.dll Typen ===" -ForegroundColor Cyan
    $bsAsm = [AppDomain]::CurrentDomain.GetAssemblies() | Where-Object { $_.FullName -match 'BlackSharp' } | Select-Object -First 1
    if ($bsAsm) {
        Write-Host "  Geladen: $($bsAsm.FullName)" -ForegroundColor Green
        $bsAsm.GetTypes() | Sort-Object FullName | ForEach-Object { Write-Host "    $($_.FullName)" -ForegroundColor Gray }
    } else { Write-Host "  BlackSharp NICHT in AppDomain!" -ForegroundColor Red }
    
    # SMBus-Controller erkennen
    Write-Host "  WindowsSMBusDetector.DetectSMBuses()..." -ForegroundColor Yellow
    $detected = $winDetType.GetMethod('DetectSMBuses').Invoke($null, $null)
    Write-Host "  SMBus erkannt: $detected" -ForegroundColor $(if ($detected) { 'Green' }else { 'Red' })
    
    # Registrierte SMBus-Controller
    $buses = $smBusMgrType.GetProperty('RegisteredSMBuses').GetValue($null)
    Write-Host "  Registrierte SMBus-Controller: $($buses.Count)" -ForegroundColor $(if ($buses.Count -gt 0) { 'Green' }else { 'Red' })
    
    foreach ($bus in $buses) {
        Write-Host "    SMBus: '$($bus.DeviceName)' Port:$($bus.PortID)" -ForegroundColor Cyan
    }
    
    # DIMM-Module suchen
    $foundTemps = @()
    foreach ($bus in $buses) {
        Write-Host "`n[3] DIMM-Suche auf '$($bus.DeviceName)'..." -ForegroundColor Yellow
        
        # DDR5: 0x18-0x1F (SPD Hub Adressen)
        for ($addr = 0x18; $addr -le 0x1F; $addr++) {
            try {
                $det = [Activator]::CreateInstance($spdDetType, @($bus, [byte]$addr, $ddr5Val))
                if ($det.IsValid) {
                    $acc = $det.Accessor
                    $mfr = try { $acc.GetModuleManufacturerString() } catch { "?" }
                    $pn = try { $acc.ModulePartNumber().Trim() } catch { "?" }
                    Write-Host "    DDR5 @ 0x$('{0:X2}' -f $addr): $mfr | $pn | HasTS:$($acc.HasThermalSensor)" -ForegroundColor Green
                    if ($acc.HasThermalSensor) {
                        $ok = $acc.UpdateTemperature()
                        $t = $acc.Temperature
                        Write-Host "    *** TEMPERATUR: $([math]::Round($t, 1)) °C ***" -ForegroundColor Cyan
                        $foundTemps += $t
                    }
                }
            } catch { }
        }
        
        # DDR4: 0x18-0x1F
        for ($addr = 0x18; $addr -le 0x1F; $addr++) {
            try {
                $det = [Activator]::CreateInstance($spdDetType, @($bus, [byte]$addr, $ddr4Val))
                if ($det.IsValid) {
                    $acc = $det.Accessor
                    Write-Host "    DDR4 @ 0x$('{0:X2}' -f $addr): $($acc.GetModuleManufacturerString()) HasTS:$($acc.HasThermalSensor)" -ForegroundColor Green
                    if ($acc.HasThermalSensor) {
                        $acc.UpdateTemperature()
                        Write-Host "    *** TEMPERATUR: $([math]::Round($acc.Temperature,1)) °C ***" -ForegroundColor Cyan
                        $foundTemps += $acc.Temperature
                    }
                }
            } catch { }
        }
    }
    
    if ($foundTemps.Count -gt 0) {
        $max = ($foundTemps | Measure-Object -Maximum).Maximum
        Write-Host "`n  ==> MAX RAM-TEMP: $([math]::Round($max, 1)) °C (von $($foundTemps.Count) Sensoren)" -ForegroundColor Green
    } else {
        Write-Host "`n  Keine Temperaturdaten gefunden" -ForegroundColor Yellow
    }
    
    # Treiber entladen
    Write-Host "`n[4] EntladeTreiber..." -ForegroundColor Yellow
    $driverMgrType.GetMethod('UnloadDriver').Invoke($null, $null)
    Write-Host "  UnloadDriver() abgeschlossen" -ForegroundColor Green
} catch {
    Write-Host "  FEHLER: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "  Typ: $($_.Exception.GetType().FullName)" -ForegroundColor DarkRed
}

Write-Host ""
Write-Host "=== Test abgeschlossen ===" -ForegroundColor Cyan

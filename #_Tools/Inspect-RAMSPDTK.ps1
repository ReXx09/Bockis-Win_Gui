$ErrorActionPreference = 'Continue'
$libPath = "C:\Users\ReXx\Desktop\VS-CODE-Repos\Bockis-Win_Gui_DEV\Lib"

# Lade Abhängigkeiten direkt (nicht ReflectionOnly)
Add-Type -Path "$libPath\System.Memory.dll" -ErrorAction SilentlyContinue
Add-Type -Path "$libPath\System.Runtime.CompilerServices.Unsafe.dll" -ErrorAction SilentlyContinue
Add-Type -Path "$libPath\System.Numerics.Vectors.dll" -ErrorAction SilentlyContinue
Add-Type -Path "$libPath\BlackSharp.Core.dll" -ErrorAction SilentlyContinue

$dll = "$libPath\RAMSPDToolkit-NDD.dll"
$asm = [System.Reflection.Assembly]::LoadFrom($dll)
Write-Host "=== Assembly: $($asm.FullName) ===" -ForegroundColor Cyan

$types = $null
try {
    $types = $asm.GetTypes()
} catch {
    $ex = $_.Exception
    if ($ex.GetType().Name -eq 'ReflectionTypeLoadException') {
        $types = $ex.Types | Where-Object { $_ -ne $null }
        Write-Host "LoaderExceptions:" -ForegroundColor Red
        $ex.LoaderExceptions | ForEach-Object { Write-Host "  $_" -ForegroundColor DarkRed }
    }
}

Write-Host "`nGefundene Typen ($($types.Count)):" -ForegroundColor Green
$keyTypes = @('DDR4Accessor', 'DDR5Accessor', 'SPDDetector', 'SPDAccessor', 'SMBusPawnIO', 'SMBusManager', 'IThermalSensor', 'SPDTemperatureConverter', 'WindowsSMBusDetector')

$types | Where-Object { $n = $_.Name; $keyTypes | Where-Object { $n -eq $_ } } | Sort-Object FullName | ForEach-Object {
    Write-Host "  === $($_.FullName) ===" -ForegroundColor Cyan
    # Constructors
    $_.GetConstructors() | ForEach-Object {
        $params = ($_.GetParameters() | ForEach-Object { $_.ParameterType.Name + ' ' + $_.Name }) -join ', '
        Write-Host "    [ctor] ($params)" -ForegroundColor Magenta
    }
    # Methoden ausgeben
    $_.GetMethods([System.Reflection.BindingFlags]::Public -bor [System.Reflection.BindingFlags]::Static -bor [System.Reflection.BindingFlags]::Instance) | 
        Where-Object { -not $_.IsSpecialName } |
            ForEach-Object { 
                $params = ($_.GetParameters() | ForEach-Object { $_.ParameterType.Name + ' ' + $_.Name }) -join ', '
                Write-Host "    -> $($_.Name)($params): $($_.ReturnType.Name)" -ForegroundColor Yellow 
            }
            # Properties
            $_.GetProperties() | ForEach-Object {
                Write-Host "    [prop] $($_.Name): $($_.PropertyType.Name)" -ForegroundColor Gray
            }
            Write-Host ""
        }

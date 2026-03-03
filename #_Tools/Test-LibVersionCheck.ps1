# Test-LibVersionCheck.ps1
# Testet die Versionsabfrage im DependencyChecker

Write-Host "`n=== TEST: LibreHardwareMonitorLib Versionsabfrage ===" -ForegroundColor Cyan

$libPath = Join-Path $PSScriptRoot "..\Lib"
$dllPath = Join-Path $libPath "LibreHardwareMonitorLib.dll"

Write-Host "`n1. DLL-Pfad:" -ForegroundColor Yellow
Write-Host "   $dllPath" -ForegroundColor White

if (-not (Test-Path $dllPath)) {
    Write-Host "   ✗ DLL nicht gefunden!" -ForegroundColor Red
    exit 1
}
Write-Host "   ✓ DLL gefunden" -ForegroundColor Green

Write-Host "`n2. Versionsinfo:" -ForegroundColor Yellow
$versionInfo = (Get-Item $dllPath).VersionInfo
$productVersion = $versionInfo.ProductVersion
$fileVersion = $versionInfo.FileVersion

Write-Host "   Product Version: $productVersion" -ForegroundColor White
Write-Host "   File Version:    $fileVersion" -ForegroundColor White

Write-Host "`n3. Versions-Parsing:" -ForegroundColor Yellow
if ($productVersion -match '^(\d+\.\d+\.\d+)') {
    $version = [version]$matches[1]
    Write-Host "   Geparste Version: $($version.ToString())" -ForegroundColor White
    
    $minVersion = [version]"0.9.5"
    Write-Host "   Minimum Version:  $($minVersion.ToString())" -ForegroundColor White
    
    Write-Host "`n4. Versions-Vergleich:" -ForegroundColor Yellow
    if ($version -lt $minVersion) {
        Write-Host "   ✗ Version ist zu ALT ($version < $minVersion)" -ForegroundColor Red
        Write-Host "`n   WARNUNG: Diese Version nutzt Winring0!" -ForegroundColor Red
        Write-Host "   → Windows Defender wird Alarme auslösen!" -ForegroundColor Yellow
        Write-Host "`n   Update erforderlich:" -ForegroundColor Yellow
        Write-Host "     cd Tools" -ForegroundColor Gray
        Write-Host "     .\Update-LibreHardwareMonitor.ps1" -ForegroundColor Gray
    }
    elseif ($version -eq $minVersion) {
        Write-Host "   ✓ Version ist GENAU richtig ($version = $minVersion)" -ForegroundColor Green
        Write-Host "   → Nutzt PawnIO, keine Defender-Alarme!" -ForegroundColor Green
    }
    else {
        Write-Host "   ✓ Version ist NEUER als erforderlich ($version > $minVersion)" -ForegroundColor Green
        Write-Host "   → Nutzt PawnIO, keine Defender-Alarme!" -ForegroundColor Green
    }
}
else {
    Write-Host "   ✗ Konnte Version nicht parsen: $productVersion" -ForegroundColor Red
}

Write-Host "`n5. Teste DependencyChecker:" -ForegroundColor Yellow
try {
    Import-Module "$PSScriptRoot\..\Modules\Core\DependencyChecker.psm1" -Force -ErrorAction Stop
    
    Write-Host "   Rufe Initialize-HardwareMonitoringMode auf..." -ForegroundColor Gray
    Add-Type -AssemblyName System.Windows.Forms -ErrorAction SilentlyContinue
    
    $result = Initialize-HardwareMonitoringMode -Verbose
    
    Write-Host "`n   ERGEBNIS:" -ForegroundColor Yellow
    Write-Host "   Available:     $($result.Available)" -ForegroundColor $(if ($result.Available) { "Green" } else { "Red" })
    Write-Host "   LibrePath:     $($result.LibrePath)" -ForegroundColor Gray
    Write-Host "   PawnIOActive:  $($result.PawnIOActive)" -ForegroundColor Gray
    
    if ($result.Message) {
        Write-Host "`n   Message:" -ForegroundColor Yellow
        Write-Host $result.Message -ForegroundColor Gray
    }
}
catch {
    Write-Host "   ✗ Fehler: $_" -ForegroundColor Red
}

Write-Host "`n"

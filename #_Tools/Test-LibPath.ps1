# Test-LibPath.ps1
# Testet die Lib-Pfad-Ermittlung des DependencyCheckers

Write-Host "`n=== LIB-PFAD ERMITTLUNG TEST ===" -ForegroundColor Cyan
Write-Host "Testet ob der Lib-Ordner korrekt gefunden wird`n" -ForegroundColor Gray

# 1. Aktueller Script-Pfad
$currentScript = $PSScriptRoot
Write-Host "1. Aktueller Script-Pfad (Tools-Ordner):" -ForegroundColor Yellow
Write-Host "   $currentScript" -ForegroundColor White

# 2. Eine Ebene höher (Root)
$rootPath = Split-Path -Parent $currentScript
Write-Host "`n2. Root-Pfad (eine Ebene hoch):" -ForegroundColor Yellow
Write-Host "   $rootPath" -ForegroundColor White

# 3. Lib-Pfad
$libPath = Join-Path $rootPath "Lib"
Write-Host "`n3. Lib-Pfad:" -ForegroundColor Yellow
Write-Host "   $libPath" -ForegroundColor White

# 4. Prüfe ob Lib-Ordner existiert
Write-Host "`n4. Lib-Ordner existiert:" -ForegroundColor Yellow
if (Test-Path $libPath) {
    Write-Host "   ✓ JA" -ForegroundColor Green
    
    # Liste DLLs auf
    Write-Host "`n5. DLL-Dateien im Lib-Ordner:" -ForegroundColor Yellow
    $dlls = Get-ChildItem -Path $libPath -Filter "*.dll" | Select-Object -ExpandProperty Name
    if ($dlls.Count -gt 0) {
        $dlls | ForEach-Object {
            Write-Host "   ✓ $_" -ForegroundColor Green
        }
    } else {
        Write-Host "   ✗ KEINE DLLs gefunden!" -ForegroundColor Red
    }
} else {
    Write-Host "   ✗ NEIN - Lib-Ordner nicht gefunden!" -ForegroundColor Red
}

Write-Host "`n"
Write-Host "=== DependencyChecker Simulation ===" -ForegroundColor Cyan

# Simuliere DependencyChecker Pfad-Ermittlung
$moduleCorePath = Join-Path $rootPath "Modules\Core"
Write-Host "`n1. DependencyChecker.psm1 würde sein in:" -ForegroundColor Yellow
Write-Host "   $moduleCorePath" -ForegroundColor White

# Von Modules\Core zwei Ebenen hoch
$scriptRoot = Split-Path -Parent $moduleCorePath  # -> Modules
Write-Host "`n2. Eine Ebene hoch (Modules):" -ForegroundColor Yellow
Write-Host "   $scriptRoot" -ForegroundColor White

$scriptRoot = Split-Path -Parent $scriptRoot  # -> Root
Write-Host "`n3. Zwei Ebenen hoch (Root):" -ForegroundColor Yellow
Write-Host "   $scriptRoot" -ForegroundColor White

$libPathFromModule = Join-Path $scriptRoot "Lib"
Write-Host "`n4. Lib-Pfad vom DependencyChecker aus:" -ForegroundColor Yellow
Write-Host "   $libPathFromModule" -ForegroundColor White

Write-Host "`n5. Lib-Pfad korrekt:" -ForegroundColor Yellow
if ($libPath -eq $libPathFromModule) {
    Write-Host "   ✓ JA - Beide Pfade sind identisch" -ForegroundColor Green
} else {
    Write-Host "   ✗ NEIN - Pfade unterscheiden sich!" -ForegroundColor Red
    Write-Host "      Erwartet: $libPath" -ForegroundColor Gray
    Write-Host "      Gefunden: $libPathFromModule" -ForegroundColor Gray
}

Write-Host "`n=== Teste Initialize-HardwareMonitoringMode ===" -ForegroundColor Cyan

# Lade Windows.Forms Assembly für ProgressBar
Add-Type -AssemblyName System.Windows.Forms -ErrorAction SilentlyContinue

# Importiere DependencyChecker
$depCheckerPath = Join-Path $rootPath "Modules\Core\DependencyChecker.psm1"
if (Test-Path $depCheckerPath) {
    Write-Host "`nImportiere DependencyChecker..." -ForegroundColor Gray
    Import-Module $depCheckerPath -Force -Verbose
    
    Write-Host "`nRufe Initialize-HardwareMonitoringMode auf..." -ForegroundColor Gray
    $result = Initialize-HardwareMonitoringMode -Verbose
    
    Write-Host "`n=== ERGEBNIS ===" -ForegroundColor Cyan
    Write-Host "Available: $($result.Available)" -ForegroundColor $(if ($result.Available) { "Green" } else { "Red" })
    Write-Host "LibrePath: $($result.LibrePath)" -ForegroundColor Gray
    Write-Host "PawnIOActive: $($result.PawnIOActive)" -ForegroundColor Gray
    Write-Host "Message: $($result.Message)" -ForegroundColor Gray
    
    if ($result.MissingDLLs.Count -gt 0) {
        Write-Host "`nFehlende DLLs:" -ForegroundColor Red
        $result.MissingDLLs | ForEach-Object {
            Write-Host "  ✗ $($_.FileName) - $($_.Description)" -ForegroundColor Yellow
            Write-Host "    Pfad: $($_.Path)" -ForegroundColor Gray
        }
    }
} else {
    Write-Host "`n✗ DependencyChecker.psm1 nicht gefunden!" -ForegroundColor Red
    Write-Host "   Erwarteter Pfad: $depCheckerPath" -ForegroundColor Gray
}

Write-Host "`n"

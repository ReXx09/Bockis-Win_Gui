# Test-HardwareMonitor.ps1
# Testet den Hardware-Monitor nach kompletten Neustart

Write-Host "================================" -ForegroundColor Cyan
Write-Host "   HARDWARE-MONITOR TEST" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

# Prüfe DLL-Datei auf Festplatte
$dllPath = "c:\Users\ReXx\Desktop\VS-CODE-Repos\Bockis-Win_Gui_DEV\Lib\LibreHardwareMonitorLib.dll"
if (Test-Path $dllPath) {
    $fileInfo = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($dllPath)
    $fileSize = (Get-Item $dllPath).Length / 1KB
    Write-Host "DLL-Datei auf Festplatte:" -ForegroundColor Yellow
    Write-Host "  Version: $($fileInfo.ProductVersion)" -ForegroundColor $(if($fileInfo.ProductVersion -like "*0.9.4*"){'Green'}else{'Red'})
    Write-Host "  Größe: $([math]::Round($fileSize, 1)) KB" -ForegroundColor $(if($fileSize -lt 800){'Green'}else{'Red'})
    Write-Host "  $(if($fileInfo.ProductVersion -like '*0.9.4*'){'✓ KORREKT (0.9.4)'}else{'✗ FALSCH (sollte 0.9.4 sein)'})" -ForegroundColor $(if($fileInfo.ProductVersion -like "*0.9.4*"){'Green'}else{'Red'})
    Write-Host ""
}

# Prüfe verfügbare DLLs
Write-Host "Benötigte DLLs im Lib-Ordner:" -ForegroundColor Yellow
$requiredDLLs = @(
    'System.Memory.dll'
    'System.Runtime.CompilerServices.Unsafe.dll'
    'BlackSharp.Core.dll'
    'RAMSPDToolkit-NDD.dll'
    'DiskInfoToolkit.dll'
    'LibreHardwareMonitorLib.dll'
)

$allPresent = $true
foreach ($dll in $requiredDLLs) {
    $path = Join-Path "c:\Users\ReXx\Desktop\VS-CODE-Repos\Bockis-Win_Gui_DEV\Lib" $dll
    $exists = Test-Path $path
    $symbol = if($exists) { '✓' } else { '✗'; $allPresent = $false }
    $color = if($exists) { 'Green' } else { 'Red' }
    Write-Host "  $symbol $dll" -ForegroundColor $color
}
Write-Host ""

if (-not $allPresent) {
    Write-Host "FEHLER: Nicht alle benötigten DLLs vorhanden!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Drücken Sie eine Taste zum Beenden..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

# Teste Hardware-Monitor-Initialisierung
Write-Host "Teste Hardware-Monitor-Initialisierung..." -ForegroundColor Yellow
try {
    Import-Module ".\Modules\Core\DependencyChecker.psm1" -Force -ErrorAction Stop
    $result = Initialize-HardwareMonitoringMode -Verbose
    
    Write-Host ""
    Write-Host "INITIALISIERUNGS-ERGEBNIS:" -ForegroundColor Cyan
    Write-Host "  Available: $($result.Available)" -ForegroundColor $(if($result.Available){'Green'}else{'Red'})
    Write-Host "  PawnIO Active: $($result.PawnIOActive)" -ForegroundColor $(if($result.PawnIOActive){'Green'}else{'Yellow'})
    Write-Host "  Message: $($result.Message)" -ForegroundColor $(if($result.Available){'Green'}else{'Red'})
    
    if ($result.MissingDLLs.Count -gt 0) {
        Write-Host ""
        Write-Host "  Fehlende DLLs:" -ForegroundColor Red
        foreach ($dll in $result.MissingDLLs) {
            Write-Host "    - $($dll.FileName): $($dll.Description)" -ForegroundColor Red
        }
    }
    
    Write-Host ""
    if ($result.Available) {
        Write-Host "========================================" -ForegroundColor Green
        Write-Host "   ✓ HARDWARE-MONITOR FUNKTIONIERT!" -ForegroundColor Green
        Write-Host "========================================" -ForegroundColor Green
    }
    else {
        Write-Host "========================================" -ForegroundColor Red
        Write-Host "   ✗ HARDWARE-MONITOR NICHT VERFÜGBAR" -ForegroundColor Red
        Write-Host "========================================" -ForegroundColor Red
        Write-Host ""
        Write-Host "WICHTIG:" -ForegroundColor Yellow
        Write-Host "Wenn die Fehlermeldung 'System.Threading.Mutex' enthält," -ForegroundColor Yellow
        Write-Host "ist die alte DLL noch im Speicher geladen!" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Lösung:" -ForegroundColor Cyan
        Write-Host "1. ALLE PowerShell-Fenster schließen (auch VS Code)" -ForegroundColor Cyan
        Write-Host "2. Neue PowerShell öffnen" -ForegroundColor Cyan
        Write-Host "3. Dieses Script erneut ausführen" -ForegroundColor Cyan
    }
}
catch {
    Write-Host ""
    Write-Host "FEHLER beim Test:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
}

Write-Host ""
Write-Host "Drücken Sie eine Taste zum Beenden..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

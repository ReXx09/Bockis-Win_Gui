# Fix-LibreHardwareMonitorDLL.ps1
# Ersetzt die problematische LibreHardwareMonitorLib 0.9.5 durch funktionierende 0.9.4 aus Release

Write-Host "=== LibreHardwareMonitorLib Fix-Script ===" -ForegroundColor Cyan
Write-Host ""

$devLib = "c:\Users\ReXx\Desktop\VS-CODE-Repos\Bockis-Win_Gui_DEV\Lib\LibreHardwareMonitorLib.dll"
$releaseLib = "c:\Users\ReXx\Desktop\VS-CODE-Repos\Bockis-Win_Gui_Release\Lib\LibreHardwareMonitorLib.dll"
$backup = "c:\Users\ReXx\Desktop\VS-CODE-Repos\Bockis-Win_Gui_DEV\_Archive\LibreHardwareMonitorLib-0.9.5.dll"

# Prüfe aktuelle Version
if (Test-Path $devLib) {
    $currentVersion = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($devLib).ProductVersion
    Write-Host "Aktuelle Version DEV: $currentVersion" -ForegroundColor Yellow
    
    if ($currentVersion -like "*0.9.5*") {
        Write-Host "Version 0.9.5 erkannt - ersetze durch 0.9.4..." -ForegroundColor Red
        
        try {
            # Backup erstellen
            if (-not (Test-Path $backup)) {
                Copy-Item -Path $devLib -Destination $backup -Force
                Write-Host "✓ Backup erstellt: $backup" -ForegroundColor Green
            }
            
            # Ersetze mit Release-Version
            Copy-Item -Path $releaseLib -Destination $devLib -Force
            Write-Host "✓ LibreHardwareMonitorLib.dll ersetzt" -ForegroundColor Green
            
            # Prüfe neue Version
            $newVersion = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($devLib).ProductVersion
            Write-Host "✓ Neue Version: $newVersion" -ForegroundColor Green
            Write-Host ""
            Write-Host "ERFOLG! Hardware-Monitor sollte jetzt funktionieren." -ForegroundColor Green
        }
        catch {
            Write-Host "FEHLER: $($_.Exception.Message)" -ForegroundColor Red
            Write-Host "Bitte alle Programme schließen die die DLL verwenden und erneut versuchen." -ForegroundColor Yellow
        }
    }
    else {
        Write-Host "✓ Version 0.9.4 bereits vorhanden - keine Änderung nötig" -ForegroundColor Green
    }
}
else {
    Write-Host "FEHLER: DEV LibreHardwareMonitorLib.dll nicht gefunden!" -ForegroundColor Red
}

Write-Host ""
Write-Host "Drücken Sie eine Taste zum Beenden..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

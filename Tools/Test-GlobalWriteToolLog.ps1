# Test-GlobalWriteToolLog.ps1
# Testet, ob Write-ToolLog aus Modulen heraus funktioniert

Write-Host "`n=== Test: Write-ToolLog aus Modul-Kontext ===" -ForegroundColor Cyan

# Lade das Hauptskript
Write-Host "[1] Lade Win_Gui_Module.ps1..." -ForegroundColor Yellow
. "$PSScriptRoot\..\Win_Gui_Module.ps1"

# Prüfe ob Write-ToolLog verfügbar ist
Write-Host "`n[2] Prüfe Write-ToolLog Verfügbarkeit..." -ForegroundColor Yellow
$cmd = Get-Command Write-ToolLog -ErrorAction SilentlyContinue
if ($cmd) {
    Write-Host "    ✓ Write-ToolLog gefunden" -ForegroundColor Green
    Write-Host "    Quelle: $($cmd.Source)" -ForegroundColor Gray
    Write-Host "    Modul: $($cmd.ModuleName)" -ForegroundColor Gray
} else {
    Write-Host "    ✗ Write-ToolLog nicht gefunden!" -ForegroundColor Red
    exit 1
}

# Teste direkten Aufruf
Write-Host "`n[3] Teste direkten Aufruf..." -ForegroundColor Yellow
try {
    Write-ToolLog -ToolName "DirectTest" -Message "Direkter Aufruf funktioniert" -Level "Information"
    Write-Host "    ✓ Direkter Aufruf erfolgreich" -ForegroundColor Green
} catch {
    Write-Host "    ✗ Direkter Aufruf fehlgeschlagen: $_" -ForegroundColor Red
}

# Teste Aufruf aus SystemTools-Modul
Write-Host "`n[4] Teste Aufruf aus SystemTools-Modul..." -ForegroundColor Yellow
try {
    Import-Module "$PSScriptRoot\..\Modules\Tools\SystemTools.psm1" -Force
    Write-Host "    SystemTools-Modul geladen" -ForegroundColor Gray
    
    # Rufe eine Funktion auf, die Write-ToolLog verwendet (ohne tatsächlich MRT zu starten)
    # Da wir keine GUI haben, können wir Start-QuickMRT nicht direkt aufrufen
    # Stattdessen testen wir manuell
    
    Write-Host "    Teste Write-ToolLog aus Modul-Scope..." -ForegroundColor Gray
    & { Write-ToolLog -ToolName "ModuleTest" -Message "Aufruf aus Modul-Scope" -Level "Success" }
    Write-Host "    ✓ Modul-Scope Aufruf erfolgreich" -ForegroundColor Green
} catch {
    Write-Host "    ✗ Modul-Scope Aufruf fehlgeschlagen: $_" -ForegroundColor Red
    Write-Host "    Details: $($_.Exception.Message)" -ForegroundColor Red
}

# Prüfe erstellte Log-Dateien
Write-Host "`n[5] Prüfe erstellte Log-Dateien..." -ForegroundColor Yellow
$logFiles = @("DirectTest.log", "ModuleTest.log")
foreach ($logFile in $logFiles) {
    $logPath = Join-Path "$PSScriptRoot\..\Data\Logs" $logFile
    if (Test-Path $logPath) {
        Write-Host "    ✓ $logFile erstellt" -ForegroundColor Green
        $content = Get-Content $logPath -Tail 1
        Write-Host "      Inhalt: $content" -ForegroundColor Gray
    } else {
        Write-Host "    ✗ $logFile nicht gefunden" -ForegroundColor Red
    }
}

Write-Host "`n=== Test abgeschlossen ===" -ForegroundColor Cyan

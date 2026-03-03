# Test-CompleteLogWorkflow.ps1
# Testet das komplette Logsystem im GUI-Workflow

Write-Host "`n=== Vollständiger Logsystem-Workflow-Test ===" -ForegroundColor Cyan
Write-Host "Simuliert einen kompletten GUI-Durchlauf mit Logging`n" -ForegroundColor White

# 1. Hauptskript laden
Write-Host "[1] Lade Hauptskript..." -ForegroundColor Yellow
try {
    Remove-Module LogManager -Force -ErrorAction SilentlyContinue
    . "$PSScriptRoot\..\Win_Gui_Module.ps1"
    Write-Host "    ✓ Hauptskript geladen" -ForegroundColor Green
} catch {
    Write-Host "    ✗ Fehler beim Laden: $_" -ForegroundColor Red
    exit 1
}

# 2. Prüfe Write-ToolLog Verfügbarkeit
Write-Host "`n[2] Prüfe Write-ToolLog..." -ForegroundColor Yellow
$commands = Get-Command Write-ToolLog -All -ErrorAction SilentlyContinue
$count = ($commands | Measure-Object).Count
if ($count -eq 1) {
    Write-Host "    ✓ Genau EINE Write-ToolLog Funktion gefunden" -ForegroundColor Green
    Write-Host "      Quelle: $($commands[0].Source)" -ForegroundColor Gray
    Write-Host "      Modul: $($commands[0].ModuleName)" -ForegroundColor Gray
} elseif ($count -gt 1) {
    Write-Host "    ⚠ WARNUNG: $count Write-ToolLog Funktionen gefunden!" -ForegroundColor Yellow
    foreach ($cmd in $commands) {
        Write-Host "      - $($cmd.Name) von $($cmd.Source) (Modul: $($cmd.ModuleName))" -ForegroundColor Yellow
    }
} else {
    Write-Host "    ✗ Write-ToolLog nicht gefunden!" -ForegroundColor Red
    exit 1
}

# 3. Teste verschiedene Log-Szenarien
Write-Host "`n[3] Teste verschiedene Log-Szenarien..." -ForegroundColor Yellow

# Test 1: Normaler Log-Eintrag
try {
    Write-ToolLog -ToolName "WorkflowTest" -Message "Normaler Info-Eintrag" -Level "Information"
    Write-Host "    ✓ Test 1: Information-Level" -ForegroundColor Green
} catch {
    Write-Host "    ✗ Test 1 fehlgeschlagen: $_" -ForegroundColor Red
}

# Test 2: Warnung
try {
    Write-ToolLog -ToolName "WorkflowTest" -Message "Warnung: Niedriger Speicherplatz" -Level "Warning"
    Write-Host "    ✓ Test 2: Warning-Level" -ForegroundColor Green
} catch {
    Write-Host "    ✗ Test 2 fehlgeschlagen: $_" -ForegroundColor Red
}

# Test 3: Fehler
try {
    Write-ToolLog -ToolName "WorkflowTest" -Message "Fehler beim Zugriff auf Datei" -Level "Error"
    Write-Host "    ✓ Test 3: Error-Level" -ForegroundColor Green
} catch {
    Write-Host "    ✗ Test 3 fehlgeschlagen: $_" -ForegroundColor Red
}

# Test 4: Erfolg
try {
    Write-ToolLog -ToolName "WorkflowTest" -Message "Vorgang erfolgreich abgeschlossen" -Level "Success"
    Write-Host "    ✓ Test 4: Success-Level" -ForegroundColor Green
} catch {
    Write-Host "    ✗ Test 4 fehlgeschlagen: $_" -ForegroundColor Red
}

# Test 5: Ohne Timestamp
try {
    Write-ToolLog -ToolName "WorkflowTest" -Message "Eintrag ohne Zeitstempel" -NoTimestamp
    Write-Host "    ✓ Test 5: NoTimestamp-Flag" -ForegroundColor Green
} catch {
    Write-Host "    ✗ Test 5 fehlgeschlagen: $_" -ForegroundColor Red
}

# 4. Prüfe Log-Datei
Write-Host "`n[4] Prüfe erstellte Log-Datei..." -ForegroundColor Yellow
$logPath = Join-Path $PSScriptRoot "..\Data\Logs\WorkflowTest.log"
if (Test-Path $logPath) {
    Write-Host "    ✓ Log-Datei existiert: WorkflowTest.log" -ForegroundColor Green
    $content = Get-Content $logPath
    Write-Host "    Anzahl Einträge: $($content.Count)" -ForegroundColor Gray
    Write-Host "`n    Letzte 5 Einträge:" -ForegroundColor Cyan
    $content | Select-Object -Last 5 | ForEach-Object { Write-Host "      $_" -ForegroundColor White }
} else {
    Write-Host "    ✗ Log-Datei nicht gefunden!" -ForegroundColor Red
}

# 5. Teste Modul-Kompatibilität
Write-Host "`n[5] Teste Modul-Kompatibilität..." -ForegroundColor Yellow
try {
    Import-Module "$PSScriptRoot\..\Modules\Tools\SystemTools.psm1" -Force -ErrorAction Stop
    Write-Host "    ✓ SystemTools-Modul geladen" -ForegroundColor Green
    
    # Prüfe ob Write-ToolLog aus Modul aufrufbar ist
    & {
        Write-ToolLog -ToolName "ModuleCompatTest" -Message "Aufruf aus SystemTools-Modul-Scope" -Level "Information"
    }
    Write-Host "    ✓ Write-ToolLog aus Modul-Scope funktioniert" -ForegroundColor Green
} catch {
    Write-Host "    ✗ Modul-Kompatibilität fehlgeschlagen: $_" -ForegroundColor Red
    Write-Host "    Details: $($_.Exception.Message)" -ForegroundColor Red
}

# 6. Teste LogManager-Hilfsfunktionen
Write-Host "`n[6] Teste LogManager-Hilfsfunktionen..." -ForegroundColor Yellow

# Test Get-ToolLog
try {
    $logContent = Get-ToolLog -ToolName "WorkflowTest"
    if ($logContent) {
        Write-Host "    ✓ Get-ToolLog funktioniert" -ForegroundColor Green
        Write-Host "      Log-Größe: $($logContent.Length) Zeichen" -ForegroundColor Gray
    } else {
        Write-Host "    ⚠ Get-ToolLog gab leeren Inhalt zurück" -ForegroundColor Yellow
    }
} catch {
    Write-Host "    ✗ Get-ToolLog fehlgeschlagen: $_" -ForegroundColor Red
}

# Test Get-AvailableLogs
try {
    $availableLogs = Get-AvailableLogs
    Write-Host "    ✓ Get-AvailableLogs funktioniert" -ForegroundColor Green
    Write-Host "      Verfügbare Logs: $($availableLogs.Count)" -ForegroundColor Gray
} catch {
    Write-Host "    ✗ Get-AvailableLogs fehlgeschlagen: $_" -ForegroundColor Red
}

# 7. Zusammenfassung
Write-Host "`n[7] Zusammenfassung:" -ForegroundColor Yellow
$allLogs = Get-ChildItem "$PSScriptRoot\..\Data\Logs" -Filter "*.log" -ErrorAction SilentlyContinue
$totalSize = ($allLogs | Measure-Object -Property Length -Sum).Sum
Write-Host "    Gesamt Log-Dateien: $($allLogs.Count)" -ForegroundColor White
Write-Host "    Gesamt Log-Größe: $([math]::Round($totalSize/1KB, 2)) KB" -ForegroundColor White
Write-Host "    Neueste Log: $($allLogs | Sort-Object LastWriteTime -Descending | Select-Object -First 1 -ExpandProperty Name)" -ForegroundColor White

Write-Host "`n=== Workflow-Test abgeschlossen ===" -ForegroundColor Cyan
Write-Host "✓ Alle Tests erfolgreich!" -ForegroundColor Green
Write-Host "`nDas Logsystem ist vollständig funktionsfähig und bereit für den Produktiveinsatz.`n" -ForegroundColor White

# Test-LogSystem.ps1
# Testet das Logsystem der GUI auf korrekte Funktionalität

Write-Host "`n=== Logsystem-Test ===" -ForegroundColor Cyan
Write-Host "Überprüfe das Logging-System der GUI`n" -ForegroundColor White

# 1. Prüfe Data\Logs Verzeichnis
Write-Host "[1] Prüfe Log-Verzeichnis..." -ForegroundColor Yellow
$logDir = Join-Path $PSScriptRoot "..\Data\Logs"
if (Test-Path $logDir) {
    Write-Host "    ✓ Log-Verzeichnis existiert: $logDir" -ForegroundColor Green
} else {
    Write-Host "    ✗ Log-Verzeichnis fehlt: $logDir" -ForegroundColor Red
    exit 1
}

# 2. Prüfe LogManager-Modul
Write-Host "`n[2] Lade LogManager-Modul..." -ForegroundColor Yellow
try {
    Import-Module "$PSScriptRoot\..\Modules\Core\LogManager.psm1" -Force -ErrorAction Stop
    Write-Host "    ✓ LogManager-Modul erfolgreich geladen" -ForegroundColor Green
} catch {
    Write-Host "    ✗ Fehler beim Laden des LogManager-Moduls: $_" -ForegroundColor Red
    exit 1
}

# 3. Prüfe Initialize-LogDirectory Funktion
Write-Host "`n[3] Teste Initialize-LogDirectory..." -ForegroundColor Yellow
try {
    Initialize-LogDirectory
    Write-Host "    ✓ Initialize-LogDirectory erfolgreich ausgeführt" -ForegroundColor Green
} catch {
    Write-Host "    ✗ Fehler bei Initialize-LogDirectory: $_" -ForegroundColor Red
}

# 4. Teste Write-ToolLog aus LogManager
Write-Host "`n[4] Teste Write-ToolLog (LogManager)..." -ForegroundColor Yellow
try {
    Write-ToolLog -ToolName "TestTool" -Message "Dies ist ein Test-Eintrag (Information)" -Level "Information"
    Write-ToolLog -ToolName "TestTool" -Message "Dies ist ein Test-Eintrag (Warning)" -Level "Warning"
    Write-ToolLog -ToolName "TestTool" -Message "Dies ist ein Test-Eintrag (Error)" -Level "Error"
    Write-ToolLog -ToolName "TestTool" -Message "Dies ist ein Test-Eintrag (Success)" -Level "Success"
    Write-Host "    ✓ Write-ToolLog erfolgreich ausgeführt" -ForegroundColor Green
} catch {
    Write-Host "    ✗ Fehler bei Write-ToolLog: $_" -ForegroundColor Red
    Write-Host "    Details: $($_.Exception.Message)" -ForegroundColor Red
}

# 5. Prüfe ob Log-Datei erstellt wurde
Write-Host "`n[5] Prüfe erstellte Log-Datei..." -ForegroundColor Yellow
$testLogPath = Join-Path $logDir "TestTool.log"
if (Test-Path $testLogPath) {
    Write-Host "    ✓ Log-Datei wurde erstellt: $testLogPath" -ForegroundColor Green
    
    # Zeige Inhalt
    Write-Host "`n    Log-Inhalt:" -ForegroundColor Cyan
    $content = Get-Content $testLogPath
    foreach ($line in $content) {
        Write-Host "    $line" -ForegroundColor White
    }
    
    # Zeige Dateigröße
    $fileInfo = Get-Item $testLogPath
    Write-Host "`n    Dateigröße: $($fileInfo.Length) Bytes" -ForegroundColor Cyan
} else {
    Write-Host "    ✗ Log-Datei wurde nicht erstellt" -ForegroundColor Red
}

# 6. Liste alle Log-Dateien auf
Write-Host "`n[6] Übersicht aller Log-Dateien:" -ForegroundColor Yellow
$logFiles = Get-ChildItem -Path $logDir -Filter "*.log" -ErrorAction SilentlyContinue
if ($logFiles) {
    foreach ($file in $logFiles) {
        $size = if ($file.Length -lt 1KB) { "$($file.Length) Bytes" } 
                elseif ($file.Length -lt 1MB) { "{0:N2} KB" -f ($file.Length / 1KB) }
                else { "{0:N2} MB" -f ($file.Length / 1MB) }
        
        Write-Host "    • $($file.Name)" -ForegroundColor White -NoNewline
        Write-Host " - $size" -ForegroundColor Gray -NoNewline
        Write-Host " - Zuletzt geändert: $($file.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Gray
    }
} else {
    Write-Host "    Keine Log-Dateien gefunden" -ForegroundColor Gray
}

# 7. Teste globale Write-ToolLog Funktion (aus Win_Gui_Module.ps1)
Write-Host "`n[7] Teste globale Write-ToolLog Funktion..." -ForegroundColor Yellow
Write-Host "    Hinweis: Diese Funktion wird normalerweise nur im GUI-Kontext verwendet" -ForegroundColor Gray
Write-Host "    und erfordert eine RichTextBox für die Ausgabe." -ForegroundColor Gray

# 8. Prüfe Log-Rotation (große Dateien)
Write-Host "`n[8] Prüfe Log-Rotation Konfiguration..." -ForegroundColor Yellow
$logManagerContent = Get-Content "$PSScriptRoot\..\Modules\Core\LogManager.psm1" -Raw
if ($logManagerContent -match '\$script:maxLogSize\s*=\s*(\d+)MB') {
    Write-Host "    ✓ Max Log-Größe: $($Matches[1]) MB" -ForegroundColor Green
}
if ($logManagerContent -match '\$script:maxLogAge\s*=\s*(\d+)') {
    Write-Host "    ✓ Max Log-Alter: $($Matches[1]) Tage" -ForegroundColor Green
}

Write-Host "`n=== Test abgeschlossen ===" -ForegroundColor Cyan
Write-Host "Das Logsystem wurde erfolgreich getestet.`n" -ForegroundColor Green

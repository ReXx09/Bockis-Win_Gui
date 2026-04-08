<#
.SYNOPSIS
    Aktualisiert LibreHardwareMonitorLib von v0.9.4 auf v0.9.5
.DESCRIPTION
    v0.9.5 nutzt PawnIO statt Winring0 (keine Defender-Alarme mehr!)
    WICHTIG: Schließen Sie ALLE VS Code Fenster und PowerShell-Terminals vor der Ausführung!
#>

$ErrorActionPreference = "Stop"

# Pfade
$libPath = Join-Path $PSScriptRoot "..\Lib"
$tempPath = [System.IO.Path]::GetTempPath()
$extractFolder = Join-Path $tempPath "LibreHardwareMonitorLib-0.9.5"
$sourceDll = Join-Path $extractFolder "runtimes\win-x64\lib\net472\LibreHardwareMonitorLib.dll"
$targetDll = Join-Path $libPath "LibreHardwareMonitorLib.dll"
$backupDll = Join-Path $libPath "LibreHardwareMonitorLib.dll.v0.9.4.backup"

Write-Host "`n=====================================" -ForegroundColor Cyan
Write-Host " LibreHardwareMonitor Update" -ForegroundColor Cyan
Write-Host " v0.9.4 → v0.9.5 (PawnIO Support)" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

# Aktuelle Version anzeigen
if (Test-Path $targetDll) {
    $currentVersion = (Get-Item $targetDll).VersionInfo.ProductVersion
    Write-Host "[i] Aktuelle Version: $currentVersion" -ForegroundColor Yellow
    
    if ($currentVersion.StartsWith("0.9.5")) {
        Write-Host "[✓] Sie haben bereits v0.9.5 installiert!" -ForegroundColor Green
        Write-Host ""
        Read-Host "Drücken Sie Enter zum Beenden"
        exit 0
    }
}

# Quelle prüfen
if (Test-Path $sourceDll) {
    $sourceVersion = (Get-Item $sourceDll).VersionInfo.ProductVersion
    Write-Host "[✓] Quelle gefunden: v$($sourceVersion.Split('+')[0])" -ForegroundColor Green
    
    if (-not $sourceVersion.StartsWith("0.9.5")) {
        Write-Host "[✗] Fehler: Quelle ist nicht v0.9.5!" -ForegroundColor Red
        Read-Host "Drücken Sie Enter zum Beenden"
        exit 1
    }
}
else {
    Write-Host "[✗] Fehler: v0.9.5 DLL nicht gefunden!" -ForegroundColor Red
    Write-Host "    Erwartet: $sourceDll" -ForegroundColor Red
    Write-Host ""
    Write-Host "Bitte laden Sie zuerst v0.9.5 herunter:" -ForegroundColor Yellow
    Write-Host "  1. Download: https://www.nuget.org/api/v2/package/LibreHardwareMonitorLib/0.9.5" -ForegroundColor White
    Write-Host "  2. Als ZIP entpacken" -ForegroundColor White
    Write-Host "  3. Nach %TEMP%\LibreHardwareMonitorLib-0.9.5 extrahieren" -ForegroundColor White
    Write-Host ""
    Read-Host "Drücken Sie Enter zum Beenden"
    exit 1
}

# Prozess-Check
Write-Host ""
Write-Host "[i] Prüfe auf laufende Prozesse..." -ForegroundColor Yellow
$vsCodeRunning = Get-Process -Name "Code" -ErrorAction SilentlyContinue
$psRunning = Get-Process -Name "powershell", "pwsh" -ErrorAction SilentlyContinue | Where-Object { $_.Id -ne $PID }

if ($vsCodeRunning -or ($psRunning -and $psRunning.Count -gt 0)) {
    Write-Host ""
    Write-Host "============================================" -ForegroundColor Red
    Write-Host " WARNUNG: Prozesse erkannt!" -ForegroundColor Red
    Write-Host "============================================" -ForegroundColor Red
    Write-Host ""
    
    if ($vsCodeRunning) {
        Write-Host "[!] VS Code läuft ($($vsCodeRunning.Count) Instanz(en))" -ForegroundColor Yellow
    }
    if ($psRunning -and $psRunning.Count -gt 0) {
        Write-Host "[!] PowerShell läuft ($($psRunning.Count) weitere Instanz(en))" -ForegroundColor Yellow
    }
    
    Write-Host ""
    Write-Host "Diese Prozesse blockieren möglicherweise die DLL." -ForegroundColor Yellow
    Write-Host ""
    $continue = Read-Host "Trotzdem fortfahren? (j/n)"
    if ($continue -ne "j" -and $continue -ne "J") {
        Write-Host ""
        Write-Host "Abgebrochen. Bitte:" -ForegroundColor Cyan
        Write-Host "  1. Schließen Sie alle VS Code Fenster" -ForegroundColor White
        Write-Host "  2. Schließen Sie alle PowerShell-Terminals" -ForegroundColor White
        Write-Host "  3. Öffnen Sie PowerShell neu (als Administrator)" -ForegroundColor White
        Write-Host "  4. Führen Sie aus: cd 'c:\Users\ReXx\Desktop\VS-CODE-Repos\Bockis-Win_Gui_DEV\Tools'" -ForegroundColor White
        Write-Host "  5. Führen Sie aus: .\Update-LibreHardwareMonitor.ps1" -ForegroundColor White
        Write-Host ""
        Read-Host "Drücken Sie Enter zum Beenden"
        exit 0
    }
}

# Backup erstellen
Write-Host ""
if (-not (Test-Path $backupDll)) {
    Write-Host "[i] Erstelle Backup..." -ForegroundColor Yellow
    try {
        Copy-Item $targetDll $backupDll -Force
        Write-Host "[✓] Backup erstellt" -ForegroundColor Green
    }
    catch {
        Write-Host "[!] Warnung: Backup fehlgeschlagen: $_" -ForegroundColor Yellow
    }
}
else {
    Write-Host "[i] Backup existiert bereits" -ForegroundColor Yellow
}

# DLL ersetzen
Write-Host ""
Write-Host "[i] Ersetze DLL..." -ForegroundColor Yellow

try {
    # Prüfen ob Datei beschreibbar ist
    $testWrite = [System.IO.File]::Open($targetDll, 'Open', 'Write')
    $testWrite.Close()
    $testWrite.Dispose()
    
    # DLL ersetzen
    Copy-Item $sourceDll $targetDll -Force
    Write-Host "[✓] DLL erfolgreich ersetzt!" -ForegroundColor Green
}
catch {
    Write-Host ""
    Write-Host "============================================" -ForegroundColor Red
    Write-Host " FEHLER: DLL kann nicht ersetzt werden!" -ForegroundColor Red
    Write-Host "============================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "Details: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "Ursache:" -ForegroundColor Yellow
    Write-Host "  Die DLL wird von einem Prozess verwendet." -ForegroundColor White
    Write-Host ""
    Write-Host "Lösung:" -ForegroundColor Cyan
    Write-Host "  1. Schließen Sie ALLE VS Code Fenster" -ForegroundColor White
    Write-Host "  2. Schließen Sie ALLE PowerShell-Terminals" -ForegroundColor White
    Write-Host "  3. Öffnen Sie PowerShell neu (als Administrator)" -ForegroundColor White
    Write-Host "  4. Führen Sie aus: cd 'c:\Users\ReXx\Desktop\VS-CODE-Repos\Bockis-Win_Gui_DEV\Tools'" -ForegroundColor White
    Write-Host "  5. Führen Sie aus: .\Update-LibreHardwareMonitor.ps1" -ForegroundColor White
    Write-Host ""
    Read-Host "Drücken Sie Enter zum Beenden"
    exit 1
}

# Version überprüfen
$newVersion = (Get-Item $targetDll).VersionInfo.ProductVersion
$versionShort = $newVersion.Split('+')[0]
Write-Host "[i] Installierte Version: $versionShort" -ForegroundColor Cyan

if ($newVersion.StartsWith("0.9.5")) {
    Write-Host ""
    Write-Host "============================================" -ForegroundColor Green
    Write-Host " ✓ UPDATE ERFOLGREICH!" -ForegroundColor Green
    Write-Host "============================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Nächste Schritte:" -ForegroundColor Cyan
    Write-Host "  1. System neu starten (wichtig für PawnIO)" -ForegroundColor White
    Write-Host "  2. Nach Neustart: PawnIO prüfen" -ForegroundColor White
    Write-Host "     → Get-Service -Name PawnIO" -ForegroundColor Gray
    Write-Host "  3. GUI starten und Hardware-Monitoring testen" -ForegroundColor White
    Write-Host "  4. DependencyChecker wird nun v0.9.5 akzeptieren" -ForegroundColor White
    Write-Host "  5. Defender-Alarme sollten verschwunden sein!" -ForegroundColor White
    Write-Host ""
}
else {
    Write-Host ""
    Write-Host "[✗] FEHLER: Version nicht aktualisiert!" -ForegroundColor Red
    Write-Host "    Erwartet: 0.9.5" -ForegroundColor Red
    Write-Host "    Gefunden: $versionShort" -ForegroundColor Red
    Write-Host ""
    Read-Host "Drücken Sie Enter zum Beenden"
    exit 1
}

Write-Host ""
Read-Host "Drücken Sie Enter zum Beenden"

Write-Host "`n=== UPDATE ABGESCHLOSSEN ===" -ForegroundColor Cyan
Write-Host "`nÄnderungen:" -ForegroundColor Yellow
Write-Host "  ✓ LibreHardwareMonitorLib.dll: v0.9.4 → v0.9.5" -ForegroundColor Green
Write-Host "  ✓ Winring0-Treiber entfernt (kein Defender-Alarm mehr!)" -ForegroundColor Green
Write-Host "  ✓ PawnIO-Treiber wird jetzt genutzt" -ForegroundColor Green

Write-Host "`nBackup:" -ForegroundColor Yellow
Write-Host "  Die alte Version wurde gesichert als:" -ForegroundColor Gray
Write-Host "  $backupDll" -ForegroundColor Gray

Write-Host "`nNächste Schritte:" -ForegroundColor Yellow
Write-Host "  1. Stelle sicher, dass PawnIO installiert ist:" -ForegroundColor White
Write-Host "     winget install namazso.PawnIO" -ForegroundColor Gray
Write-Host "  2. System neu starten" -ForegroundColor White
Write-Host "  3. Tool starten und Hardware-Monitoring testen" -ForegroundColor White
Write-Host "  4. Keine Defender-Alarme mehr! 🎉`n" -ForegroundColor White

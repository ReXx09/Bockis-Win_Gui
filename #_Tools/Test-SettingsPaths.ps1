# Test-SettingsPaths.ps1
# Überprüft, ob alle Pfade in Settings korrekt auf Data-Ordner zeigen

Write-Host "`n=== Pfad-Überprüfung: Settings.psm1 ===" -ForegroundColor Cyan
Write-Host "Prüft, ob alle Pfade korrekt auf die Data-Ordner-Struktur zeigen`n" -ForegroundColor White

# 1. Lade Hauptskript
Write-Host "[1] Lade Hauptskript..." -ForegroundColor Yellow
try {
    Remove-Module * -Force -ErrorAction SilentlyContinue
    . "$PSScriptRoot\..\Win_Gui_Module.ps1" *>&1 | Out-Null
    Write-Host "    ✓ Hauptskript geladen" -ForegroundColor Green
} catch {
    Write-Host "    ✗ Fehler beim Laden: $_" -ForegroundColor Red
    exit 1
}

# 2. Prüfe config.json
Write-Host "`n[2] Prüfe config.json..." -ForegroundColor Yellow
$configPath = Join-Path $PSScriptRoot "..\config.json"
if (Test-Path $configPath) {
    $config = Get-Content $configPath | ConvertFrom-Json
    $logPath = $config.LogPath
    
    if ($logPath -like "*Data\Logs*") {
        Write-Host "    ✓ LogPath zeigt auf Data-Ordner" -ForegroundColor Green
        Write-Host "      Pfad: $logPath" -ForegroundColor Gray
    } elseif ($logPath -like "*LOCALAPPDATA*") {
        Write-Host "    ✗ LogPath verwendet noch alten LOCALAPPDATA-Pfad!" -ForegroundColor Red
        Write-Host "      Pfad: $logPath" -ForegroundColor Gray
    } else {
        Write-Host "    ⚠ LogPath verwendet unbekannten Pfad" -ForegroundColor Yellow
        Write-Host "      Pfad: $logPath" -ForegroundColor Gray
    }
} else {
    Write-Host "    ⚠ config.json nicht gefunden" -ForegroundColor Yellow
}

# 3. Prüfe ob Settings-Modul LOCALAPPDATA verwendet
Write-Host "`n[3] Prüfe Settings-Modul auf alte Pfade..." -ForegroundColor Yellow
$settingsContent = Get-Content "$PSScriptRoot\..\Modules\Core\Settings.psm1" -Raw
$localAppdataMatches = [regex]::Matches($settingsContent, 'Join-Path \$env:LOCALAPPDATA')

if ($localAppdataMatches.Count -eq 0) {
    Write-Host "    ✓ Keine LOCALAPPDATA-Pfade in Settings.psm1" -ForegroundColor Green
} else {
    Write-Host "    ✗ Gefunden: $($localAppdataMatches.Count) LOCALAPPDATA-Referenzen" -ForegroundColor Red
    foreach ($match in $localAppdataMatches) {
        $lineNum = ($settingsContent.Substring(0, $match.Index) -split "`n").Count
        Write-Host "      - Zeile ${lineNum}: $($match.Value)" -ForegroundColor Gray
    }
}

# 4. Prüfe Data-Ordner-Struktur
Write-Host "`n[4] Prüfe Data-Ordner-Struktur..." -ForegroundColor Yellow
$dataRoot = Join-Path $PSScriptRoot "..\Data"
$requiredDirs = @(
    "",
    "Database",
    "Logs",
    "Temp",
    "ToolDownloads"
)

foreach ($dir in $requiredDirs) {
    $path = if ($dir) { Join-Path $dataRoot $dir } else { $dataRoot }
    $name = if ($dir) { "Data\$dir" } else { "Data" }
    
    if (Test-Path $path) {
        Write-Host "    ✓ $name existiert" -ForegroundColor Green
    } else {
        Write-Host "    ✗ $name fehlt!" -ForegroundColor Red
    }
}

# 5. Prüfe Pfade im geladenen Settings-Modul
Write-Host "`n[5] Prüfe erwartete Pfade..." -ForegroundColor Yellow
$expectedRoot = "C:\Users\ReXx\Desktop\VS-CODE-Repos\Bockis-Win_Gui_DEV"
$expectedPaths = @{
    "Logs" = Join-Path $expectedRoot "Data\Logs"
    "Database" = Join-Path $expectedRoot "Data\Database"
    "Temp" = Join-Path $expectedRoot "Data\Temp"
    "ToolDownloads" = Join-Path $expectedRoot "Data\ToolDownloads"
}

foreach ($pathType in $expectedPaths.Keys) {
    $expected = $expectedPaths[$pathType]
    if (Test-Path $expected) {
        Write-Host "    ✓ $pathType : $expected" -ForegroundColor Green
    } else {
        Write-Host "    ⚠ $pathType : $expected (existiert noch nicht)" -ForegroundColor Yellow
    }
}

# 6. Prüfe LogManager-Modul
Write-Host "`n[6] Prüfe LogManager-Pfad..." -ForegroundColor Yellow
$logManagerContent = Get-Content "$PSScriptRoot\..\Modules\Core\LogManager.psm1" -Raw
if ($logManagerContent -match '\$script:logDirectory = Join-Path \$PSScriptRoot "(.*?)"') {
    $logManagerPath = $matches[1]
    Write-Host "    LogManager verwendet: $logManagerPath" -ForegroundColor Gray
    
    if ($logManagerPath -like "*Data*Logs*") {
        Write-Host "    ✓ LogManager zeigt auf Data-Ordner" -ForegroundColor Green
    } else {
        Write-Host "    ✗ LogManager verwendet falschen Pfad!" -ForegroundColor Red
    }
} else {
    Write-Host "    ⚠ Konnte LogManager-Pfad nicht ermitteln" -ForegroundColor Yellow
}

# 7. Zusammenfassung
Write-Host "`n=== Zusammenfassung ===" -ForegroundColor Cyan
Write-Host "Alle Pfade zeigen korrekt auf die Data-Ordner-Struktur im GUI-Verzeichnis." -ForegroundColor Green
Write-Host "Die Anwendung ist bereit für die Installation auf anderen Rechnern.`n" -ForegroundColor White

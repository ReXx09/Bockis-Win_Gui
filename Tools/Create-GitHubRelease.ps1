# Create-GitHubRelease.ps1
# Erstellt einen GitHub Release mit automatischem ZIP-Upload

param(
    [string]$Version = "4.1.4",
    [string]$RepoOwner = "ReXx09",
    [string]$RepoName = "Bockis-Win_Gui-DEV",
    [string]$Token = "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",
    [switch]$PreRelease = $false,
    [switch]$Draft = $false
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " GitHub Release Creator" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Variablen
$tagName = "v$Version"
$releaseName = "Bockis System-Tool v$Version"
$releaseBody = @"
## 🎉 Bockis System-Tool v$Version

### ✨ Neue Features
- Hardware-Monitoring mit LibreHardwareMonitor 0.9.5
- Automatischer Update-Check für private Repos
- Verbesserte Token-Authentifizierung

### 🔧 Verbesserungen
- Optimierte UI-Performance
- Bessere Fehlerbehandlung
- Erweiterte Logging-Funktionen

### 🐛 Bugfixes
- Diverse Stabilitätsverbesserungen

### 📥 Installation
1. ZIP-Datei herunterladen
2. Entpacken
3. `Bockis System-Tool starten.bat` ausführen

---
**Vollständiges Changelog:** [Hier einfügen]
"@

$projectRoot = Split-Path -Parent $PSScriptRoot
$zipName = "Bockis-System-Tool-v$Version.zip"
$zipPath = Join-Path ([System.IO.Path]::GetTempPath()) $zipName

Write-Host "[1/5] Erstelle Release-ZIP..." -ForegroundColor Yellow

# Erstelle ZIP (ohne Tools-Ordner, _Archive, etc.)
$tempBuildPath = Join-Path ([System.IO.Path]::GetTempPath()) "Bockis-Build-$Version"

if (Test-Path $tempBuildPath) {
    Remove-Item $tempBuildPath -Recurse -Force
}

New-Item -ItemType Directory -Path $tempBuildPath -Force | Out-Null

# Dateien kopieren (nur Produktions-relevante)
$filesToInclude = @(
    "Win_Gui_Module.ps1",
    "Bockis System-Tool starten.bat",
    "config.json",
    "LICENSE.txt",
    "README.md",
    "THIRD-PARTY-LICENSES.md"
)

$foldersToInclude = @(
    "Modules",
    "Lib",
    "Data"
)

Write-Host "   Kopiere Dateien..." -ForegroundColor Gray

foreach ($file in $filesToInclude) {
    $source = Join-Path $projectRoot $file
    if (Test-Path $source) {
        Copy-Item $source -Destination $tempBuildPath -Force
        Write-Host "   ✓ $file" -ForegroundColor Green
    }
}

foreach ($folder in $foldersToInclude) {
    $source = Join-Path $projectRoot $folder
    if (Test-Path $source) {
        $dest = Join-Path $tempBuildPath $folder
        Copy-Item $source -Destination $dest -Recurse -Force
        Write-Host "   ✓ $folder\" -ForegroundColor Green
    }
}

# Erstelle ZIP
if (Test-Path $zipPath) {
    Remove-Item $zipPath -Force
}

Compress-Archive -Path "$tempBuildPath\*" -DestinationPath $zipPath -CompressionLevel Optimal
Remove-Item $tempBuildPath -Recurse -Force

$zipSize = (Get-Item $zipPath).Length / 1MB
Write-Host "   ✓ ZIP erstellt: $zipName ($([math]::Round($zipSize, 2)) MB)" -ForegroundColor Green
Write-Host ""

Write-Host "[2/5] Erstelle GitHub Release..." -ForegroundColor Yellow

# API-Aufruf zum Erstellen des Release
$apiUrl = "https://api.github.com/repos/$RepoOwner/$RepoName/releases"

$headers = @{
    "Authorization" = "token $Token"
    "Accept" = "application/vnd.github+json"
    "User-Agent" = "Bockis-Release-Script"
}

$body = @{
    tag_name = $tagName
    target_commitish = "main"  # oder "master" je nach Branch
    name = $releaseName
    body = $releaseBody
    draft = $Draft.IsPresent
    prerelease = $PreRelease.IsPresent
} | ConvertTo-Json

Write-Host "   Repository: $RepoOwner/$RepoName" -ForegroundColor Gray
Write-Host "   Tag: $tagName" -ForegroundColor Gray
Write-Host "   Draft: $($Draft.IsPresent)" -ForegroundColor Gray
Write-Host "   Pre-Release: $($PreRelease.IsPresent)" -ForegroundColor Gray

try {
    $release = Invoke-RestMethod -Uri $apiUrl -Method Post -Headers $headers -Body $body -ContentType "application/json"
    Write-Host "   ✓ Release erstellt!" -ForegroundColor Green
    Write-Host ""
}
catch {
    Write-Host "   ✗ Fehler beim Erstellen des Release!" -ForegroundColor Red
    Write-Host "   $($_.Exception.Message)" -ForegroundColor Red
    
    if ($_.Exception.Response.StatusCode.value__ -eq 422) {
        Write-Host ""
        Write-Host "   HINWEIS: Möglicherweise existiert der Tag bereits." -ForegroundColor Yellow
        Write-Host "   Versuche vorhandenen Release zu aktualisieren..." -ForegroundColor Yellow
        
        # Hole existierenden Release
        try {
            $existingReleaseUrl = "https://api.github.com/repos/$RepoOwner/$RepoName/releases/tags/$tagName"
            $release = Invoke-RestMethod -Uri $existingReleaseUrl -Method Get -Headers $headers
            Write-Host "   ✓ Existierenden Release gefunden!" -ForegroundColor Green
        }
        catch {
            Write-Host "   ✗ Konnte Release nicht finden!" -ForegroundColor Red
            exit 1
        }
    }
    else {
        exit 1
    }
}

Write-Host "[3/5] Lade Release-Asset hoch..." -ForegroundColor Yellow

# Upload-URL vorbereiten
$uploadUrl = $release.upload_url -replace '\{\?name,label\}', "?name=$zipName"

# Datei hochladen
$uploadHeaders = @{
    "Authorization" = "token $Token"
    "Content-Type" = "application/zip"
    "User-Agent" = "Bockis-Release-Script"
}

try {
    Write-Host "   Uploading $zipName..." -ForegroundColor Gray
    
    $fileBytes = [System.IO.File]::ReadAllBytes($zipPath)
    $asset = Invoke-RestMethod -Uri $uploadUrl -Method Post -Headers $uploadHeaders -Body $fileBytes
    
    Write-Host "   ✓ Asset hochgeladen!" -ForegroundColor Green
    Write-Host "   Download-URL: $($asset.browser_download_url)" -ForegroundColor Cyan
    Write-Host ""
}
catch {
    Write-Host "   ✗ Fehler beim Hochladen: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "[4/5] Cleanup..." -ForegroundColor Yellow
Remove-Item $zipPath -Force
Write-Host "   ✓ Temporäre Dateien gelöscht" -ForegroundColor Green
Write-Host ""

Write-Host "[5/5] Release fertig!" -ForegroundColor Green
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " ✓ Release erfolgreich erstellt!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Release-URL: $($release.html_url)" -ForegroundColor Cyan
Write-Host ""
Write-Host "Nächste Schritte:" -ForegroundColor Yellow
Write-Host "  1. Öffnen Sie die Release-URL" -ForegroundColor Gray
Write-Host "  2. Prüfen Sie die Release-Notes" -ForegroundColor Gray
Write-Host "  3. Testen Sie den Update-Button im Tool" -ForegroundColor Gray
Write-Host ""

# Öffne Release im Browser
$openBrowser = Read-Host "Release im Browser öffnen? (j/n)"
if ($openBrowser -eq 'j' -or $openBrowser -eq 'J') {
    Start-Process $release.html_url
}


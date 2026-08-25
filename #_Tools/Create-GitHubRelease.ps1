# Create-GitHubRelease.ps1
# Erstellt einen GitHub Release mit automatischem ZIP-Upload

param(
    [string]$Version = "4.2.5",
    [string]$RepoOwner = "ReXx09",
    [string]$RepoName = "Bockis-Win_Gui-DEV",
    [string]$Token = "",           # Leer lassen – wird aus Token-Datei gelesen
    [switch]$PreRelease = $false,
    [switch]$Draft = $false
)

# ─── Token laden (aus sicherer Datei außerhalb des Repos) ─────────────────────
$TokenFile = "C:\Users\ReXx\Desktop\VS-CODE-Repos\Github---- Update-Token.txt"
if ([string]::IsNullOrWhiteSpace($Token)) {
    if (Test-Path $TokenFile) {
        $Token = (Get-Content $TokenFile | Where-Object { $_ -match "ghp_|github_pat_" } | Select-Object -First 1).Trim()
    }
    if ([string]::IsNullOrWhiteSpace($Token)) {
        Write-Host "[!] Kein GitHub-Token gefunden!" -ForegroundColor Red
        Write-Host "    Erstelle die Datei: $TokenFile" -ForegroundColor Yellow
        Write-Host "    Und trage deinen Token (ghp_...) ein." -ForegroundColor Yellow
        exit 1
    }
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " GitHub Release Creator" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Variablen
$tagName = "v$Version"
$releaseName = "Bockis System-Tool v$Version"
$releaseBody = @"
## Bockis System-Tool v$Version

### Bugfixes
- **Browser oeffnet sich nicht (Admin-Kontext)**: Open-UrlInBrowser nutzt jetzt Shell.Application des laufenden (nicht-erhoehten) Explorer-Prozesses - behebt die Chromium/Brave-Elevation-Barriere
- **Add-ons starten nicht**: .bat/.cmd-Dateien werden jetzt explizit ueber cmd.exe /c ausgefuehrt - zuverlaessiger aus erhoehtem Kontext
- **WPF-Fehler lautlos verschluckt**: Add_Click-Handler hat jetzt try-catch mit Write-ToolLog
- **Settings-Dialog**: Duplikate entfernt, Action-Buttons und Closure-Variable-Capture korrigiert
- **Tray-Wiederherstellung**: Stabilitaet beim GUI-Restore aus dem Tray verbessert

### Neue Features
- **Extensions-System**: Verwaltung externer Erweiterungen (Dashboard, MultiMonitor) direkt aus der GUI
- **ADB Link** in Tool-Bibliothek (Coding / IT) hinzugefuegt
- **DetectCommand-Mechanismus**: Tools ohne Winget-ID ueber PATH-Befehl als installiert erkennbar

### Verbesserungen
- Extension-Logging via Write-ToolLog -ToolName 'EXTENSION'
- Data/Add-ons als Git-Submodule (bockis-dashboard, multimonitor-profile-tool)
- Set-ProjectVersion.ps1 Pfadfehler korrigiert

### Installation
1. ZIP-Datei herunterladen und entpacken
2. Bockis System-Tool starten.bat ausfuehren
3. Bei Erstinstallation: Abhaengigkeiten werden automatisch geprueft

---
Vollstaendiges Changelog: https://github.com/ReXx09/Bockis-Win_Gui/blob/master/RELEASE_NOTES.md
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
    "Accept"        = "application/vnd.github+json"
    "User-Agent"    = "Bockis-Release-Script"
}

$body = @{
    tag_name         = $tagName
    target_commitish = "master"  # Branch
    name             = $releaseName
    body             = $releaseBody
    draft            = $Draft.IsPresent
    prerelease       = $PreRelease.IsPresent
} | ConvertTo-Json

Write-Host "   Repository: $RepoOwner/$RepoName" -ForegroundColor Gray
Write-Host "   Tag: $tagName" -ForegroundColor Gray
Write-Host "   Draft: $($Draft.IsPresent)" -ForegroundColor Gray
Write-Host "   Pre-Release: $($PreRelease.IsPresent)" -ForegroundColor Gray

try {
    $release = Invoke-RestMethod -Uri $apiUrl -Method Post -Headers $headers -Body $body -ContentType "application/json"
    Write-Host "   ✓ Release erstellt!" -ForegroundColor Green
    Write-Host ""
} catch {
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
        } catch {
            Write-Host "   ✗ Konnte Release nicht finden!" -ForegroundColor Red
            exit 1
        }
    } else {
        exit 1
    }
}

Write-Host "[3/5] Lade Release-Asset hoch..." -ForegroundColor Yellow

# Upload-URL vorbereiten
$uploadUrl = $release.upload_url -replace '\{\?name,label\}', "?name=$zipName"

# Datei hochladen
$uploadHeaders = @{
    "Authorization" = "token $Token"
    "Content-Type"  = "application/zip"
    "User-Agent"    = "Bockis-Release-Script"
}

try {
    Write-Host "   Uploading $zipName..." -ForegroundColor Gray
    
    $fileBytes = [System.IO.File]::ReadAllBytes($zipPath)
    $asset = Invoke-RestMethod -Uri $uploadUrl -Method Post -Headers $uploadHeaders -Body $fileBytes
    
    Write-Host "   ✓ Asset hochgeladen!" -ForegroundColor Green
    Write-Host "   Download-URL: $($asset.browser_download_url)" -ForegroundColor Cyan
    Write-Host ""
} catch {
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









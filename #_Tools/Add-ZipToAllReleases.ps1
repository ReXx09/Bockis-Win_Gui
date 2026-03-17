#Requires -Version 5.1
<#
.SYNOPSIS
    Fügt allen Releases im öffentlichen Repo ein ZIP-Asset hinzu (falls noch keins vorhanden).

.DESCRIPTION
    Geht alle GitHub-Releases von ReXx09/Bockis-Win_Gui durch,
    erstellt für jeden ohne ZIP-Asset ein Paket aus dem entsprechenden Git-Tag
    und lädt es hoch.

.NOTES
    Benötigt: C:\Users\ReXx\Desktop\VS-CODE-Repos\Github---- Update-Token.txt
    Ausführen: .\#_Tools\Add-ZipToAllReleases.ps1
#>

# ─── Konfiguration ────────────────────────────────────────────────────────────
$RepoOwner   = "ReXx09"
$RepoName    = "Bockis-Win_Gui"
$RepoApi     = "https://api.github.com/repos/$RepoOwner/$RepoName"
$TokenFile   = "C:\Users\ReXx\Desktop\VS-CODE-Repos\Github---- Update-Token.txt"
$DevRepoPath = Split-Path -Parent $PSScriptRoot

$FoldersToCopy = @("Modules", "Lib", "Data")
$FilesToCopy   = @(
    "Win_Gui_Module.ps1",
    "installer.iss",
    "settings.json",
    "LICENSE.txt",
    "README.md",
    "THIRD-PARTY-LICENSES.md",
    "Bockis System-Tool starten.bat"
)

function Write-Step { param($Text) Write-Host "`n[ ] $Text" -ForegroundColor Cyan }
function Write-OK   { param($Text) Write-Host "    [+] $Text" -ForegroundColor Green }
function Write-Skip { param($Text) Write-Host "    [~] $Text" -ForegroundColor DarkYellow }
function Write-Fail { param($Text) Write-Host "    [!] $Text" -ForegroundColor Red }

# ─── Token laden ──────────────────────────────────────────────────────────────
if (-not (Test-Path $TokenFile)) {
    Write-Fail "Token-Datei nicht gefunden: $TokenFile"
    Write-Host "Bitte erstelle die Datei und trage deinen GitHub-Token ein." -ForegroundColor Yellow
    exit 1
}
$Token = (Get-Content $TokenFile | Where-Object { $_ -match "ghp_|github_pat_" } | Select-Object -First 1).Trim()
if ([string]::IsNullOrWhiteSpace($Token)) {
    Write-Fail "Kein gültiger Token gefunden!"
    exit 1
}

$Headers = @{
    "Authorization"        = "Bearer $Token"
    "Accept"               = "application/vnd.github+json"
    "X-GitHub-Api-Version" = "2022-11-28"
}

Write-Host "╔════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   ZIP zu allen Releases hinzufügen             ║" -ForegroundColor Cyan
Write-Host "║   Repo: $RepoOwner/$RepoName$((' ' * (38 - "$RepoOwner/$RepoName".Length)))║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════╝" -ForegroundColor Cyan

# ─── Alle Releases abrufen ────────────────────────────────────────────────────
Write-Step "Releases abrufen..."
try {
    $releases = Invoke-RestMethod -Uri "$RepoApi/releases" -Headers $Headers
} catch {
    Write-Fail "API-Fehler: $_"
    exit 1
}

$withZip    = $releases | Where-Object { $_.assets | Where-Object { $_.name -like "*.zip" } }
$withoutZip = $releases | Where-Object { -not ($_.assets | Where-Object { $_.name -like "*.zip" }) }

Write-OK "Gesamt: $($releases.Count) Releases"
Write-OK "Bereits mit ZIP: $($withZip.Count)"
Write-Host "    Ohne ZIP:         $($withoutZip.Count)" -ForegroundColor Yellow

if ($withoutZip.Count -eq 0) {
    Write-Host "`n[✓] Alle Releases haben bereits ein ZIP-Asset." -ForegroundColor Green
    exit 0
}

Write-Host "`nReleases ohne ZIP:" -ForegroundColor Yellow
$withoutZip | ForEach-Object { Write-Host "    - $($_.tag_name)" -ForegroundColor White }

$confirm = Read-Host "`nFür alle $($withoutZip.Count) Releases ein ZIP hochladen? (J/N)"
if ($confirm -notin @("J", "j")) { Write-Host "Abgebrochen."; exit 0 }

# ─── Für jeden Release ohne ZIP: erstellen und hochladen ──────────────────────
Set-Location $DevRepoPath

foreach ($release in $withoutZip) {
    $tag = $release.tag_name
    Write-Step "Verarbeite: $tag"

    # Prüfen ob Tag lokal vorhanden
    $tagExists = git tag -l $tag
    if (-not $tagExists) {
        Write-Skip "Tag '$tag' nicht lokal vorhanden — übersprungen"
        continue
    }

    $buildPath = Join-Path ([System.IO.Path]::GetTempPath()) "Bockis-ZipBuild-$tag"
    $zipName   = "Bockis-System-Tool-$tag.zip"
    $zipPath   = Join-Path ([System.IO.Path]::GetTempPath()) $zipName

    try {
        # Build-Ordner erstellen
        if (Test-Path $buildPath) { Remove-Item $buildPath -Recurse -Force }
        New-Item -ItemType Directory -Path $buildPath -Force | Out-Null

        # Dateien aus dem Git-Tag exportieren (git archive)
        $gitArchiveTmp = Join-Path ([System.IO.Path]::GetTempPath()) "Bockis-GitArchive-$tag.zip"
        git archive --format=zip $tag -o $gitArchiveTmp 2>$null

        if (Test-Path $gitArchiveTmp) {
            Expand-Archive -Path $gitArchiveTmp -DestinationPath $buildPath -Force
            Remove-Item $gitArchiveTmp -Force

            # Nur relevante Dateien/Ordner behalten
            $allItems = Get-ChildItem $buildPath
            $keepNames = $FoldersToCopy + $FilesToCopy + @("*.ico", "*.bmp", "*.jpg", "*.png", "config.json")

            foreach ($item in $allItems) {
                $keep = $false
                foreach ($pattern in $keepNames) {
                    if ($item.Name -like $pattern -or $item.Name -eq $pattern) {
                        $keep = $true; break
                    }
                }
                if (-not $keep) {
                    Remove-Item $item.FullName -Recurse -Force
                }
            }
        } else {
            # Fallback: aktuelle Arbeitskopie nehmen (für den neuesten Tag)
            Write-Skip "git archive fehlgeschlagen für $tag — nutze aktuelle Kopie"
            foreach ($folder in $FoldersToCopy) {
                $src = Join-Path $DevRepoPath $folder
                if (Test-Path $src) { Copy-Item $src (Join-Path $buildPath $folder) -Recurse -Force }
            }
            foreach ($file in $FilesToCopy) {
                $src = Join-Path $DevRepoPath $file
                if (Test-Path $src) { Copy-Item $src (Join-Path $buildPath $file) -Force }
            }
        }

        # ZIP erstellen
        if (Test-Path $zipPath) { Remove-Item $zipPath -Force }
        Compress-Archive -Path "$buildPath\*" -DestinationPath $zipPath -Force
        Remove-Item $buildPath -Recurse -Force

        $sizeMB = [math]::Round((Get-Item $zipPath).Length / 1MB, 1)
        Write-OK "ZIP erstellt: $zipName ($sizeMB MB)"

        # Upload
        $uploadUrl = $release.upload_url -replace '\{\?name,label\}', ''
        $uploadUri = "$uploadUrl`?name=$zipName"
        $uploadHeaders = @{
            "Authorization"        = "Bearer $Token"
            "Content-Type"         = "application/zip"
            "X-GitHub-Api-Version" = "2022-11-28"
        }

        $uploadResp = Invoke-RestMethod -Uri $uploadUri -Method Post -Headers $uploadHeaders -InFile $zipPath
        Write-OK "Hochgeladen: $($uploadResp.browser_download_url)"

        Remove-Item $zipPath -Force

    } catch {
        Write-Fail "Fehler bei $tag`: $_"
        if (Test-Path $buildPath) { Remove-Item $buildPath -Recurse -Force }
        if (Test-Path $zipPath)   { Remove-Item $zipPath -Force }
    }
}

Write-Host ""
Write-Host "╔════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║   FERTIG! Alle ZIPs wurden hochgeladen.        ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host "    https://github.com/$RepoOwner/$RepoName/releases" -ForegroundColor Gray

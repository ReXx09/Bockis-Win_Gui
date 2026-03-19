#Requires -Version 5.1
<#
.SYNOPSIS
    Pusht einen bestimmten Release manuell in das öffentliche Release-Repo.

.DESCRIPTION
    Kopiert alle relevanten Dateien aus dem DEV-Repo in das Release-Repo
    und erstellt optional einen neuen GitHub-Release.

.PARAMETER Tag
    Der Git-Tag der gepusht werden soll. z.B. "v4.1.9"
    Standard: Neuester lokaler Tag wird verwendet.

.PARAMETER CreateRelease
    Wenn angegeben, wird zusätzlich ein GitHub-Release erstellt.

.PARAMETER ReleaseNotes
    Optionaler Text für die Release-Notes. Wenn leer, wird auf DEV-Repo verwiesen.

.EXAMPLE
    .\Push-ToReleaseRepo.ps1 -Tag "v4.1.9" -CreateRelease
    .\Push-ToReleaseRepo.ps1 -Tag "v4.1.9"
#>

param (
    [string]$Tag = "",
    [switch]$CreateRelease = $false,
    [string]$ReleaseNotes = ""
)

# ─── Konfiguration ────────────────────────────────────────────────────────────
$DevRepoPath = Split-Path -Parent $PSScriptRoot
$TempClonePath = "$env:TEMP\Bockis-Release-Sync"
$ReleaseRepoUrl = "https://github.com/ReXx09/Bockis-Win_Gui.git"
$ReleaseRepoApi = "https://api.github.com/repos/ReXx09/Bockis-Win_Gui"
$TokenFile = "C:\Users\ReXx\Desktop\VS-CODE-Repos\Github---- Update-Token.txt"

# Relevante Dateien und Ordner
$FoldersToCopy = @("Modules", "Lib", "Data")
$FilesToCopy = @(
    "Win_Gui_Module.ps1",
    "installer.iss",
    "config.json",
    "settings.json",
    "LICENSE.txt",
    "README.md",
    "THIRD-PARTY-LICENSES.md",
    "Bockis System-Tool starten.bat"
)
$ExtensionsToCopy = @("*.ico", "*.bmp", "*.jpg", "*.png")

# ─── Hilfsfunktionen ──────────────────────────────────────────────────────────
function Write-Step { param($Text) Write-Host "`n[ ] $Text" -ForegroundColor Cyan }
function Write-OK { param($Text) Write-Host "[+] $Text" -ForegroundColor Green }
function Write-Fail { param($Text) Write-Host "[!] $Text" -ForegroundColor Red }

# ─── Token lesen ──────────────────────────────────────────────────────────────
if (-not (Test-Path $TokenFile)) {
    Write-Fail "Token-Datei nicht gefunden: $TokenFile"
    exit 1
}
$Token = (Get-Content $TokenFile | Where-Object { $_ -match "ghp_|github_pat_" } | Select-Object -First 1).Trim()
if (-not $Token) { Write-Fail "Kein GitHub-Token gefunden!"; exit 1 }

$AuthUrl = "https://$Token@github.com/ReXx09/Bockis-Win_Gui.git"
$Headers = @{
    "Authorization"        = "Bearer $Token"
    "Accept"               = "application/vnd.github+json"
    "X-GitHub-Api-Version" = "2022-11-28"
}

# ─── Tag ermitteln ────────────────────────────────────────────────────────────
Set-Location $DevRepoPath

if (-not $Tag) {
    $Tag = git describe --tags --abbrev=0 2>$null
    if (-not $Tag) { Write-Fail "Kein Tag gefunden."; exit 1 }
    Write-OK "Neuester Tag erkannt: $Tag"
}

# Prüfen ob Tag existiert
$tagExists = git tag -l $Tag
if (-not $tagExists) {
    Write-Fail "Tag '$Tag' existiert nicht lokal!"
    exit 1
}

Write-Host "`n╔══════════════════════════════════════════╗" -ForegroundColor Yellow
Write-Host "║   Release-Push → Bockis-Win_Gui          ║" -ForegroundColor Yellow
Write-Host "║   Tag: $($Tag.PadRight(34))║" -ForegroundColor Yellow
Write-Host "╚══════════════════════════════════════════╝" -ForegroundColor Yellow

$confirm = Read-Host "`nFortfahren? (J/N)"
if ($confirm -notin @("J", "j")) { Write-Host "Abgebrochen."; exit 0 }

# ─── Release-Repo klonen / aktualisieren ─────────────────────────────────────
Write-Step "Release-Repo vorbereiten..."

if (Test-Path $TempClonePath) {
    Remove-Item $TempClonePath -Recurse -Force
}

git clone $AuthUrl $TempClonePath --quiet
if ($LASTEXITCODE -ne 0) { Write-Fail "Klonen fehlgeschlagen!"; exit 1 }
Write-OK "Release-Repo geklont"

# ─── Alten Inhalt löschen (außer .git) ───────────────────────────────────────
Get-ChildItem $TempClonePath -Force |
    Where-Object { $_.Name -ne ".git" } |
        Remove-Item -Recurse -Force

# ─── Dateien kopieren ─────────────────────────────────────────────────────────
Write-Step "Relevante Dateien kopieren..."

foreach ($folder in $FoldersToCopy) {
    $src = Join-Path $DevRepoPath $folder
    if (Test-Path $src) {
        Copy-Item $src (Join-Path $TempClonePath $folder) -Recurse -Force
        Write-OK "Ordner: $folder/"
    } else {
        Write-Host "    Übersprungen (nicht gefunden): $folder/" -ForegroundColor DarkYellow
    }
}

foreach ($file in $FilesToCopy) {
    $src = Join-Path $DevRepoPath $file
    if (Test-Path $src) {
        Copy-Item $src (Join-Path $TempClonePath $file) -Force
        Write-OK "Datei:  $file"
    } else {
        Write-Host "    Übersprungen (nicht gefunden): $file" -ForegroundColor DarkYellow
    }
}

foreach ($ext in $ExtensionsToCopy) {
    Get-ChildItem $DevRepoPath -Filter $ext -File | ForEach-Object {
        Copy-Item $_.FullName (Join-Path $TempClonePath $_.Name) -Force
        Write-OK "Icon:   $($_.Name)"
    }
}

# ─── In Release-Repo pushen ───────────────────────────────────────────────────
Write-Step "Änderungen pushen..."

Set-Location $TempClonePath
git config user.name  "GitHub Actions"
git config user.email "actions@github.com"
git add .

$diff = git diff --staged --stat
if (-not $diff) {
    Write-Host "    Keine Änderungen — nichts zu pushen." -ForegroundColor DarkYellow
} else {
    git commit -m "Release $Tag synchronisiert" --quiet
    git push   --quiet
    if ($LASTEXITCODE -ne 0) { Write-Fail "Push fehlgeschlagen!"; exit 1 }
    Write-OK "Gepusht: $ReleaseRepoUrl"

    # Tag im Release-Repo setzen
    git tag $Tag
    git push origin $Tag --quiet
    Write-OK "Tag gesetzt: $Tag"
}

# ─── GitHub-Release erstellen (optional) ──────────────────────────────────────
if ($CreateRelease) {
    Write-Step "GitHub-Release erstellen..."

    if (-not $ReleaseNotes) {
        $ReleaseNotes = "Vollstaendige Release Notes: https://github.com/ReXx09/Bockis-Win_Gui/releases/tag/$Tag"
    }

    $nl = "`n"
    $body = "## $([char]::ConvertFromUtf32(0x1F389)) $Tag$nl$nl"
    $body += $ReleaseNotes

    $releaseBody = [PSCustomObject]@{
        tag_name   = $Tag
        name       = "$Tag - Bockis System-Tool"
        body       = $body
        draft      = $false
        prerelease = $false
    } | ConvertTo-Json -Depth 3

    try {
        $resp = Invoke-RestMethod -Uri "$ReleaseRepoApi/releases" -Method Post -Headers $Headers -Body $releaseBody -ContentType "application/json"
        Write-OK "Release erstellt: $($resp.html_url)"

        # ─── ZIP erstellen und als Asset hochladen ────────────────────────────
        Write-Step "ZIP-Paket erstellen und hochladen..."

        $zipName = "Bockis-System-Tool-$Tag.zip"
        $zipPath = Join-Path ([System.IO.Path]::GetTempPath()) $zipName
        $buildPath = Join-Path ([System.IO.Path]::GetTempPath()) "Bockis-Release-Build"

        if (Test-Path $buildPath) { Remove-Item $buildPath -Recurse -Force }
        New-Item -ItemType Directory -Path $buildPath -Force | Out-Null

        # Gleiche Dateien wie beim Push kopieren
        foreach ($folder in $FoldersToCopy) {
            $src = Join-Path $TempClonePath $folder
            if (Test-Path $src) {
                Copy-Item $src (Join-Path $buildPath $folder) -Recurse -Force
            }
        }
        foreach ($file in $FilesToCopy) {
            $src = Join-Path $TempClonePath $file
            if (Test-Path $src) { Copy-Item $src (Join-Path $buildPath $file) -Force }
        }
        foreach ($ext in $ExtensionsToCopy) {
            Get-ChildItem $TempClonePath -Filter $ext -File | ForEach-Object {
                Copy-Item $_.FullName (Join-Path $buildPath $_.Name) -Force
            }
        }

        if (Test-Path $zipPath) { Remove-Item $zipPath -Force }
        Compress-Archive -Path "$buildPath\*" -DestinationPath $zipPath -Force
        Remove-Item $buildPath -Recurse -Force

        $zipSize = [math]::Round((Get-Item $zipPath).Length / 1MB, 1)
        Write-OK "ZIP erstellt: $zipName ($zipSize MB)"

        # Upload-URL aus dem Release holen
        $uploadUrl = $resp.upload_url -replace '\{\?name,label\}', ''
        $uploadHeaders = @{
            "Authorization"        = "Bearer $Token"
            "Content-Type"         = "application/zip"
            "X-GitHub-Api-Version" = "2022-11-28"
        }
        $uploadUri = "$uploadUrl`?name=$zipName"

        $uploadResp = Invoke-RestMethod -Uri $uploadUri -Method Post -Headers $uploadHeaders -InFile $zipPath
        Write-OK "Asset hochgeladen: $($uploadResp.browser_download_url)"

        Remove-Item $zipPath -Force

    } catch {
        Write-Fail "Release/Upload fehlgeschlagen: $_"
    }
}

# ─── Aufräumen ────────────────────────────────────────────────────────────────
Set-Location $DevRepoPath
Remove-Item $TempClonePath -Recurse -Force

Write-Host "`n╔══════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║   FERTIG! $($Tag.PadRight(32))║" -ForegroundColor Green
Write-Host "║   https://github.com/ReXx09/Bockis-Win_ ║" -ForegroundColor Green
Write-Host "║   Gui/releases                           ║" -ForegroundColor Green
Write-Host "╚══════════════════════════════════════════╝" -ForegroundColor Green

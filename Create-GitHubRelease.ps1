#Requires -Version 5.1
<#
.SYNOPSIS
    Erstellt einen GitHub Release fuer Bockis-Win_Gui.

.DESCRIPTION
    Liest den GitHub-Token aus der .env-Datei, erstellt einen Release via GitHub API
    und laedt optionale Assets (Dateien) hoch. Release Notes werden aus RELEASE_NOTES.md gelesen.

.PARAMETER Version
    Versionsnummer als Tag (z.B. "v4.3.0"). Wird auch als Tag-Name auf GitHub verwendet.

.PARAMETER Title
    Titel des Releases. Standard: "Bockis System-Tool <Version>"

.PARAMETER Draft
    Release als Entwurf erstellen (nicht oeffentlich sichtbar). Standard: $false

.PARAMETER Prerelease
    Als Vorabversion markieren. Standard: $false

.PARAMETER Assets
    Optionale Liste von Dateipfaden, die als Release-Assets hochgeladen werden.

.PARAMETER ReleaseNotesFile
    Pfad zur Release-Notes-Datei. Standard: "RELEASE_NOTES.md"

.PARAMETER RepoOwner
    GitHub-Benutzername. Standard: ReXx09

.PARAMETER RepoName
    Repository-Name. Standard: Bockis-Win_Gui
    Fuer Tests: Bockis-Win_Gui-DEV

.EXAMPLE
    .\Create-GitHubRelease.ps1 -Version "v4.3.0"

.EXAMPLE
    .\Create-GitHubRelease.ps1 -Version "v4.2.0-test" -RepoName "Bockis-Win_Gui-DEV" -Draft

.EXAMPLE
    .\Create-GitHubRelease.ps1 -Version "v4.3.0" -Assets ".\dist\BockisSystemTool-Setup.exe"
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^v\d+\.\d+\.\d+')]
    [string]$Version,

    [Parameter(Mandatory = $false)]
    [string]$Title = "",

    [Parameter(Mandatory = $false)]
    [switch]$Draft,

    [Parameter(Mandatory = $false)]
    [switch]$Prerelease,

    [Parameter(Mandatory = $false)]
    [string[]]$Assets = @(),

    [Parameter(Mandatory = $false)]
    [string]$ReleaseNotesFile = "RELEASE_NOTES.md",

    [Parameter(Mandatory = $false)]
    [string]$RepoOwner = "ReXx09",

    [Parameter(Mandatory = $false)]
    [string]$RepoName = "Bockis-Win_Gui"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ApiBase = "https://api.github.com/repos/$RepoOwner/$RepoName"

# --- .env einlesen ------------------------------------------------------------
function Read-DotEnv {
    param([string]$Path = ".env")
    $envFile = Join-Path $PSScriptRoot $Path
    if (-not (Test-Path $envFile)) {
        Write-Warning ".env-Datei nicht gefunden unter: $envFile"
        return
    }
    Get-Content $envFile | Where-Object { $_ -match '^\s*[^#\s]' } | ForEach-Object {
        $parts = $_ -split "=", 2
        if ($parts.Count -eq 2) {
            [System.Environment]::SetEnvironmentVariable($parts[0].Trim(), $parts[1].Trim(), "Process")
        }
    }
}

# --- Token ermitteln ----------------------------------------------------------
function Get-GitHubToken {
    $token = $env:GITHUB_TOKEN
    if (-not [string]::IsNullOrWhiteSpace($token) -and $token -ne "ghp_DEIN_TOKEN_HIER") {
        return $token
    }
    Read-DotEnv
    $token = $env:GITHUB_TOKEN
    if ([string]::IsNullOrWhiteSpace($token) -or $token -eq "ghp_DEIN_TOKEN_HIER") {
        throw "Kein gueltiger GitHub-Token gefunden. Bitte GITHUB_TOKEN in der .env-Datei eintragen."
    }
    return $token
}

# --- Release Notes lesen ------------------------------------------------------
function Get-ReleaseBody {
    param([string]$FilePath)
    $fullPath = Join-Path $PSScriptRoot $FilePath
    if (-not (Test-Path $fullPath)) {
        Write-Warning "Release-Notes-Datei nicht gefunden: $fullPath"
        return "Release $Version"
    }
    return (Get-Content $fullPath -Raw -Encoding UTF8).Trim()
}

# --- GitHub API-Aufruf --------------------------------------------------------
function Invoke-GitHubApi {
    param(
        [string]$Uri,
        [string]$Method = "GET",
        [hashtable]$Headers,
        [object]$Body
    )
    $params = @{
        Uri         = $Uri
        Method      = $Method
        Headers     = $Headers
        ContentType = "application/json"
        ErrorAction = "Stop"
    }
    if ($Body) {
        $jsonString = ($Body | ConvertTo-Json -Depth 10 -Compress)
        $params["Body"] = [System.Text.Encoding]::UTF8.GetBytes($jsonString)
    }
    return Invoke-RestMethod @params
}

# --- Asset hochladen ----------------------------------------------------------
function Send-ReleaseAsset {
    param(
        [string]$UploadUrl,
        [string]$FilePath,
        [hashtable]$AuthHeader
    )
    if (-not (Test-Path $FilePath)) {
        Write-Warning "Asset nicht gefunden, wird uebersprungen: $FilePath"
        return
    }
    $fileName = Split-Path $FilePath -Leaf
    $uploadUri = ($UploadUrl -replace '\{.*\}', '') + "?name=$([Uri]::EscapeDataString($fileName))"
    Write-Host "  Lade hoch: $fileName ..." -ForegroundColor Cyan
    $fileBytes = [System.IO.File]::ReadAllBytes($FilePath)
    Invoke-RestMethod -Uri $uploadUri -Method POST -Headers $AuthHeader `
                      -ContentType "application/octet-stream" -Body $fileBytes `
                      -ErrorAction Stop | Out-Null
    Write-Host "  [OK] $fileName hochgeladen" -ForegroundColor Green
}

# --- Hauptlogik ---------------------------------------------------------------
try {
    Write-Host ""
    Write-Host "===========================================" -ForegroundColor DarkCyan
    Write-Host "  GitHub Release erstellen: $Version" -ForegroundColor Cyan
    Write-Host "  Repo: $RepoOwner/$RepoName" -ForegroundColor DarkGray
    Write-Host "===========================================" -ForegroundColor DarkCyan
    Write-Host ""

    $token = Get-GitHubToken

    $authHeaders = @{
        "Authorization"        = "Bearer $token"
        "User-Agent"           = "Bockis-System-Tool-Releaser"
        "Accept"               = "application/vnd.github+json"
        "X-GitHub-Api-Version" = "2022-11-28"
    }

    if ([string]::IsNullOrWhiteSpace($Title)) {
        $Title = "Bockis System-Tool $Version"
    }

    $releaseBody = Get-ReleaseBody -FilePath $ReleaseNotesFile

    Write-Host "Titel      : $Title"
    Write-Host "Tag        : $Version"
    Write-Host "Draft      : $($Draft.IsPresent)"
    Write-Host "Prerelease : $($Prerelease.IsPresent)"
    Write-Host "Notes aus  : $ReleaseNotesFile"
    Write-Host ""

    # Pruefen ob Release bereits existiert
    try {
        $existing = Invoke-GitHubApi -Uri "$ApiBase/releases/tags/$Version" -Headers $authHeaders
        Write-Warning "Release '$Version' existiert bereits: $($existing.html_url)"
        Write-Warning "Abbruch. Verwende eine andere Versionsnummer oder loesche den bestehenden Release zuerst."
        exit 1
    } catch {
        if ($_.Exception.Response -and $_.Exception.Response.StatusCode.value__ -ne 404) {
            throw
        }
    }

    if ($PSCmdlet.ShouldProcess("$RepoOwner/$RepoName", "Release '$Version' erstellen")) {

        $releasePayload = @{
            tag_name         = $Version
            target_commitish = "main"
            name             = $Title
            body             = $releaseBody
            draft            = $Draft.IsPresent
            prerelease       = $Prerelease.IsPresent
        }

        Write-Host "Erstelle Release auf GitHub..." -ForegroundColor Yellow
        $release = Invoke-GitHubApi -Uri "$ApiBase/releases" -Method "POST" `
                                    -Headers $authHeaders -Body $releasePayload

        Write-Host "[OK] Release erstellt!" -ForegroundColor Green
        Write-Host "  URL: $($release.html_url)" -ForegroundColor Cyan
        Write-Host ""

        if ($Assets.Count -gt 0) {
            Write-Host "Lade Assets hoch..." -ForegroundColor Yellow
            foreach ($asset in $Assets) {
                Send-ReleaseAsset -UploadUrl $release.upload_url `
                                  -FilePath $asset `
                                  -AuthHeader $authHeaders
            }
            Write-Host ""
        }

        Write-Host "===========================================" -ForegroundColor DarkGreen
        Write-Host "  Release erfolgreich veroeffentlicht!" -ForegroundColor Green
        Write-Host "  $($release.html_url)" -ForegroundColor Cyan
        Write-Host "===========================================" -ForegroundColor DarkGreen
        Write-Host ""
    }

} catch {
    Write-Host ""
    Write-Host "[FEHLER] Beim Erstellen des Releases:" -ForegroundColor Red
    Write-Host "  $($_.Exception.Message)" -ForegroundColor Red
    if ($_.ErrorDetails -and $_.ErrorDetails.Message) {
        Write-Host "  API-Antwort: $($_.ErrorDetails.Message)" -ForegroundColor DarkRed
    }
    try {
        $stream = $_.Exception.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($stream)
        $responseBody = $reader.ReadToEnd()
        $reader.Close()
        if ($responseBody) { Write-Host "  Details: $responseBody" -ForegroundColor DarkRed }
    } catch { }
    exit 1
}

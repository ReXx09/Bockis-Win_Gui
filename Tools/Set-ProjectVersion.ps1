# Set-ProjectVersion.ps1
# Aktualisiert zentrale Versionshinweise projektweit in einem Lauf

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^\d+\.\d+\.\d+$')]
    [string]$Version,

    [Parameter()]
    [ValidatePattern('^\d{4}-\d{2}-\d{2}$')]
    [string]$IsoDate = (Get-Date -Format 'yyyy-MM-dd'),

    [Parameter()]
    [string]$ReadmeDate = ((Get-Date).ToString('d. MMMM yyyy', [System.Globalization.CultureInfo]::GetCultureInfo('de-DE'))),

    [switch]$SkipReadme
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot

function Get-RelativePathSafe {
    param([string]$Path)

    try {
        $resolved = Resolve-Path -Relative -Path $Path -ErrorAction Stop
        if ($resolved) {
            return [string]$resolved
        }
    }
    catch {
    }

    return $Path
}

function Update-FileVersionInfo {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [array]$Replacements
    )

    if (-not (Test-Path $Path)) {
        throw "Datei nicht gefunden: $Path"
    }

    $content = Get-Content -Path $Path -Raw -Encoding UTF8
    $updated = $content
    $changes = New-Object System.Collections.Generic.List[string]

    foreach ($entry in $Replacements) {
        $matched = [regex]::IsMatch($updated, $entry.Pattern)
        if (-not $matched) {
            throw "Marker '$($entry.Label)' nicht gefunden in: $Path"
        }

        $newValue = [regex]::Replace($updated, $entry.Pattern, $entry.Replacement, 1)
        if ($newValue -ne $updated) {
            [void]$changes.Add($entry.Label)
            $updated = $newValue
        }
    }

    $relativePath = Get-RelativePathSafe -Path $Path

    if ($changes.Count -eq 0) {
        Write-Host "- Keine Aenderung noetig: $relativePath" -ForegroundColor DarkGray
        return
    }

    if ($WhatIfPreference) {
        Write-Host "~ Vorschau: $relativePath [$($changes -join ', ')]" -ForegroundColor Yellow
        return
    }

    Set-Content -Path $Path -Value $updated -Encoding UTF8
    Write-Host "[OK] Aktualisiert: $relativePath [$($changes -join ', ')]" -ForegroundColor Green
}

$targets = @(
    @{
        Path = Join-Path $projectRoot 'Win_Gui_Module.ps1'
        Replacements = @(
            @{ Label = 'Header-Version'; Pattern = '(?m)^# Version:\s*.*$'; Replacement = "# Version: $Version" },
            @{ Label = 'AppVersion'; Pattern = '(?m)^\$script:AppVersion\s*=\s*"[^"]*"$'; Replacement = ('$script:AppVersion = "' + $Version + '"') },
            @{ Label = 'VersionDate'; Pattern = '(?m)^\$script:VersionDate\s*=\s*"[^"]*"$'; Replacement = ('$script:VersionDate = "' + $IsoDate + '"') }
        )
    },
    @{
        Path = Join-Path $projectRoot 'installer.iss'
        Replacements = @(
            @{ Label = 'Installer-Header'; Pattern = '(?m)^; INSTALLATIONS-SKRIPT F.* BOCKIS SYSTEM-TOOL V.*\s*$'; Replacement = "; INSTALLATIONS-SKRIPT FÜR BOCKIS SYSTEM-TOOL V$Version" },
            @{ Label = 'Installer-Version-Comment'; Pattern = '(?m)^; VERSION:\s*.*\s*$'; Replacement = "; VERSION: $Version" },
            @{ Label = 'MyAppVersion'; Pattern = '(?m)^#define MyAppVersion\s+"[^"]*"\s*$'; Replacement = ('#define MyAppVersion "' + $Version + '"') }
        )
    },
    @{
        Path = Join-Path $projectRoot 'Tools\Create-GitHubRelease.ps1'
        Replacements = @(
            @{ Label = 'ReleaseScriptDefaultVersion'; Pattern = '(?m)^\s*\[string\]\$Version\s*=\s*"[^"]*",\s*$'; Replacement = ('    [string]$Version = "' + $Version + '",') }
        )
    }
)

if (-not $SkipReadme) {
    $targets += @{
        Path = Join-Path $projectRoot 'README.md'
        Replacements = @(
            @{ Label = 'Readme-Aktuell'; Pattern = '(?m)^### Version\s+[^\r\n]+\s+-\s+Aktuell\s*$'; Replacement = "### Version $Version ($ReadmeDate) - Aktuell" }
        )
    }
}

Write-Host "Setze Projektversion auf $Version" -ForegroundColor Cyan
Write-Host "ISO-Datum: $IsoDate" -ForegroundColor Cyan
if (-not $SkipReadme) {
    Write-Host "README-Datum: $ReadmeDate" -ForegroundColor Cyan
}

foreach ($target in $targets) {
    Update-FileVersionInfo -Path $target.Path -Replacements $target.Replacements
}

Write-Host 'Fertig.' -ForegroundColor Cyan

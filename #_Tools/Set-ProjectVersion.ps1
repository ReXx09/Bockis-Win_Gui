# Set-ProjectVersion.ps1
# Aktualisiert zentrale Versionshinweise projektweit in einem Lauf

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param(
    [Parameter()]
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

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

function Get-CurrentProjectVersion {
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)

    $mainScript = Join-Path $ProjectRoot 'Win_Gui_Module.ps1'
    if (-not (Test-Path $mainScript)) {
        throw "Konnte aktuelle Version nicht ermitteln: Datei fehlt ($mainScript)"
    }

    $content = Get-Content -Path $mainScript -Raw -Encoding UTF8
    $match = [regex]::Match($content, '(?m)^\$script:AppVersion\s*=\s*["''][^"'']*["'']\s*$')
    if ($match.Success) {
        $match = [regex]::Match($content, '(?m)^\$script:AppVersion\s*=\s*["''](?<ver>\d+\.\d+\.\d+)["'']\s*$')
    }
    if (-not $match.Success) {
        throw "Konnte aktuelle Version nicht aus Win_Gui_Module.ps1 lesen."
    }

    return $match.Groups['ver'].Value
}

function Show-VersionSelectionDialog {
    param([Parameter(Mandatory = $true)][string]$CurrentVersion)

    $form = New-Object System.Windows.Forms.Form
    $form.Text = 'Projektversion setzen'
    $form.Size = New-Object System.Drawing.Size(470, 230)
    $form.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
    $form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $form.MaximizeBox = $false
    $form.MinimizeBox = $false

    $lblCurrent = New-Object System.Windows.Forms.Label
    $lblCurrent.Location = New-Object System.Drawing.Point(20, 20)
    $lblCurrent.Size = New-Object System.Drawing.Size(420, 22)
    $lblCurrent.Text = "Aktuelle Version: $CurrentVersion"
    $form.Controls.Add($lblCurrent)

    $lblManual = New-Object System.Windows.Forms.Label
    $lblManual.Location = New-Object System.Drawing.Point(20, 55)
    $lblManual.Size = New-Object System.Drawing.Size(220, 22)
    $lblManual.Text = 'Zielversion (X.Y.Z):'
    $form.Controls.Add($lblManual)

    $txtManual = New-Object System.Windows.Forms.TextBox
    $txtManual.Location = New-Object System.Drawing.Point(20, 80)
    $txtManual.Size = New-Object System.Drawing.Size(420, 24)
    $txtManual.Text = $CurrentVersion
    $form.Controls.Add($txtManual)

    $btnOk = New-Object System.Windows.Forms.Button
    $btnOk.Location = New-Object System.Drawing.Point(265, 130)
    $btnOk.Size = New-Object System.Drawing.Size(85, 30)
    $btnOk.Text = 'OK'
    $form.Controls.Add($btnOk)

    $btnCancel = New-Object System.Windows.Forms.Button
    $btnCancel.Location = New-Object System.Drawing.Point(355, 130)
    $btnCancel.Size = New-Object System.Drawing.Size(85, 30)
    $btnCancel.Text = 'Abbrechen'
    $form.Controls.Add($btnCancel)

    $btnCancel.Add_Click({
        $form.Tag = $null
        $form.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
        $form.Close()
    })

    $btnOk.Add_Click({
        try {
            $targetVersion = $txtManual.Text.Trim()
            if ($targetVersion -notmatch '^\d+\.\d+\.\d+$') {
                throw "Version ungültig. Erwartet wird X.Y.Z (z.B. 4.1.3)."
            }
            $form.Tag = $targetVersion
            $form.DialogResult = [System.Windows.Forms.DialogResult]::OK
            $form.Close()
        }
        catch {
            [System.Windows.Forms.MessageBox]::Show(
                $_.Exception.Message,
                'Ungültige Auswahl',
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Warning
            ) | Out-Null
        }
    })

    $form.AcceptButton = $btnOk
    $form.CancelButton = $btnCancel

    $result = $form.ShowDialog()
    if ($result -ne [System.Windows.Forms.DialogResult]::OK -or -not $form.Tag) {
        return $null
    }

    return [string]$form.Tag
}

function Resolve-TargetVersion {
    param(
        [Parameter()][string]$ProvidedVersion,
        [Parameter(Mandatory = $true)][string]$CurrentVersion
    )

    if (-not [string]::IsNullOrWhiteSpace($ProvidedVersion)) {
        return @{
            Mode = 'Direkt'
            Version = $ProvidedVersion
        }
    }

    $selection = Show-VersionSelectionDialog -CurrentVersion $CurrentVersion
    if (-not $selection) {
        return $null
    }

    return @{
        Mode = 'Manuell'
        Version = $selection
    }
}

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

$currentVersion = Get-CurrentProjectVersion -ProjectRoot $projectRoot
$resolvedVersion = Resolve-TargetVersion -ProvidedVersion $Version -CurrentVersion $currentVersion
$ifAborted = -not $resolvedVersion
if ($ifAborted) {
    Write-Host 'Abgebrochen: Keine Version ausgewählt.' -ForegroundColor Yellow
    return
}
$Version = $resolvedVersion.Version

$targets = @(
    @{
        Path = Join-Path $projectRoot 'Win_Gui_Module.ps1'
        Replacements = @(
            @{ Label = 'Header-Version'; Pattern = '(?m)^# Version:\s*.*$'; Replacement = "# Version: $Version" },
            @{ Label = 'AppVersion'; Pattern = '(?m)^\$script:AppVersion\s*=\s*["''][^"'']*["'']\s*$'; Replacement = ('$script:AppVersion = "' + $Version + '"') },
            @{ Label = 'VersionDate'; Pattern = '(?m)^\$script:VersionDate\s*=\s*["''][^"'']*["'']\s*$'; Replacement = ('$script:VersionDate = "' + $IsoDate + '"') }
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
Write-Host "Aktuelle Version: $currentVersion" -ForegroundColor DarkCyan
Write-Host "Modus: $($resolvedVersion.Mode)" -ForegroundColor DarkCyan
Write-Host "ISO-Datum: $IsoDate" -ForegroundColor Cyan
if (-not $SkipReadme) {
    Write-Host "README-Datum: $ReadmeDate" -ForegroundColor Cyan
}

foreach ($target in $targets) {
    Update-FileVersionInfo -Path $target.Path -Replacements $target.Replacements
}

Write-Host 'Fertig.' -ForegroundColor Cyan

# UpdateManager.psm1
# Modul für Update-Funktionalität des Bockis System-Tools
# Autor: Bocki
# Version: 1.0

<#
.SYNOPSIS
    Verwaltet automatische Updates von GitHub Releases (inkl. private Repos)

.DESCRIPTION
    Dieses Modul stellt Funktionen bereit für:
    - Update-Check gegen GitHub API
    - Asynchroner Download von Release-Assets
    - Automatische Installation und Neustart
    - Support für private Repositories mit Token-Authentifizierung

.NOTES
    Benötigt: .NET Framework 4.7.2+, Windows Forms
#>

# ===================================================================
# UPDATE-CHECK UND INSTALLATION
# ===================================================================

function Invoke-UpdateCheck {
    <#
    .SYNOPSIS
        Prüft auf verfügbare Updates und führt Installation durch
    
    .PARAMETER CurrentVersion
        Die aktuell installierte Version (z.B. "4.1.2")
    
    .PARAMETER OutputBox
        RichTextBox-Control für Statusausgaben
    
    .PARAMETER ProgressBar
        ProgressBar-Control für Fortschrittsanzeige
    
    .PARAMETER MainForm
        Hauptformular (wird nach Update geschlossen)
    
    .PARAMETER ApplicationPath
        Pfad zur Anwendung (für Neustart nach Update)
    
    .PARAMETER RepoOwner
        GitHub Repository Owner (Standard: "ReXx09")
    
    .PARAMETER RepoName
        GitHub Repository Name (Standard: "Bockis-Win_Gui-DEV")
    
    .PARAMETER GitHubToken
        Personal Access Token für private Repos (optional)
    
    .EXAMPLE
        Invoke-UpdateCheck -CurrentVersion $script:AppVersion -OutputBox $outputBox -ProgressBar $progressBar -MainForm $mainform -ApplicationPath $PSScriptRoot
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$CurrentVersion,
        
        [Parameter(Mandatory=$true)]
        [System.Windows.Forms.RichTextBox]$OutputBox,
        
        [Parameter(Mandatory=$true)]
        [System.Windows.Forms.ProgressBar]$ProgressBar,
        
        [Parameter(Mandatory=$true)]
        [System.Windows.Forms.Form]$MainForm,
        
        [Parameter(Mandatory=$true)]
        [string]$ApplicationPath,
        
        [Parameter(Mandatory=$false)]
        [string]$RepoOwner = "ReXx09",
        
        [Parameter(Mandatory=$false)]
        [string]$RepoName = "Bockis-Win_Gui-DEV",
        
        [Parameter(Mandatory=$false)]
        [string]$GitHubToken = "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"
    )
    
    try {
        $apiUrl = "https://api.github.com/repos/$RepoOwner/$RepoName/releases/latest"
        
        Set-OutputSelectionStyle -OutputBox $OutputBox -Style 'Info'
        $OutputBox.AppendText("[i] Prüfe auf Updates...`r`n")
        $OutputBox.AppendText("Repository: $RepoOwner/$RepoName`r`n")
        
        # Headers mit Authentication vorbereiten
        $headers = @{
            "User-Agent" = "Bockis-System-Tool"
            "Accept" = "application/vnd.github+json"
        }
        
        # Token hinzufügen (GitHub bevorzugt "token" statt "Bearer")
        if ($GitHubToken -and $GitHubToken -ne "ghp_DEIN_TOKEN_HIER") {
            $headers["Authorization"] = "token $GitHubToken"
        }
        
        # GitHub API abfragen mit Error-Handling
        $latestRelease = $null
        try {
            $latestRelease = Invoke-RestMethod -Uri $apiUrl -Headers $headers -ErrorAction Stop
        }
        catch {
            $statusCode = $_.Exception.Response.StatusCode.value__
            
            # Bei 404: Versuche alle Releases zu holen (inkl. Pre-Releases)
            if ($statusCode -eq 404) {
                Set-OutputSelectionStyle -OutputBox $OutputBox -Style 'Warning'
                $OutputBox.AppendText("[i] Kein publizierter Release gefunden, suche nach Pre-Releases...`r`n")
                
                $latestRelease = Get-LatestReleaseWithFallback -RepoOwner $RepoOwner -RepoName $RepoName -Headers $headers -OutputBox $OutputBox
                
                if (-not $latestRelease) {
                    return $false
                }
            }
            elseif ($statusCode -eq 401) {
                Set-OutputSelectionStyle -OutputBox $OutputBox -Style 'Error'
                $OutputBox.AppendText("[✗] Authentifizierung fehlgeschlagen!`r`n")
                $OutputBox.AppendText("Token ist ungültig oder abgelaufen.`r`n")
                return $false
            }
            else {
                Set-OutputSelectionStyle -OutputBox $OutputBox -Style 'Error'
                $OutputBox.AppendText("[✗] API-Fehler: $($_.Exception.Message)`r`n")
                return $false
            }
        }
        
        # Prüfen ob ein Release gefunden wurde
        if (-not $latestRelease) {
            Set-OutputSelectionStyle -OutputBox $OutputBox -Style 'Error'
            $OutputBox.AppendText("[✗] Konnte keine Releases finden!`r`n")
            return $false
        }
        
        $latestVersion = $latestRelease.tag_name -replace 'v', ''
        
        Set-OutputSelectionStyle -OutputBox $OutputBox -Style 'Default'
        $OutputBox.AppendText("Aktuelle Version: $CurrentVersion`r`n")
        $OutputBox.AppendText("Neueste Version: $latestVersion`r`n`r`n")
        
        # Versionsvergleich
        if ([version]$latestVersion -gt [version]$CurrentVersion) {
            return Install-Update -LatestRelease $latestRelease -LatestVersion $latestVersion -CurrentVersion $CurrentVersion `
                -OutputBox $OutputBox -ProgressBar $ProgressBar -MainForm $MainForm -ApplicationPath $ApplicationPath -GitHubToken $GitHubToken
        }
        elseif ([version]$CurrentVersion -gt [version]$latestVersion) {
            Show-NoUpdateNeeded -CurrentVersion $CurrentVersion -LatestVersion $latestVersion -OutputBox $OutputBox -IsNewer $true
            return $false
        }
        else {
            Show-NoUpdateNeeded -CurrentVersion $CurrentVersion -LatestVersion $latestVersion -OutputBox $OutputBox -IsNewer $false
            return $false
        }
    }
    catch {
        Show-UpdateError -ErrorRecord $_ -OutputBox $OutputBox
        return $false
    }
}

# ===================================================================
# HILFSFUNKTIONEN
# ===================================================================

function Get-LatestReleaseWithFallback {
    [CmdletBinding()]
    param(
        [string]$RepoOwner,
        [string]$RepoName,
        [hashtable]$Headers,
        [System.Windows.Forms.RichTextBox]$OutputBox
    )
    
    try {
        # Hole alle Releases (inkl. Pre-Releases)
        $allReleasesUrl = "https://api.github.com/repos/$RepoOwner/$RepoName/releases"
        $allReleases = Invoke-RestMethod -Uri $allReleasesUrl -Headers $Headers -ErrorAction Stop
        
        if ($allReleases -and $allReleases.Count -gt 0) {
            $latestRelease = $allReleases[0]
            $OutputBox.AppendText("[i] Gefunden: $($latestRelease.tag_name)")
            if ($latestRelease.prerelease) {
                $OutputBox.AppendText(" (Pre-Release)")
            }
            if ($latestRelease.draft) {
                $OutputBox.AppendText(" (Draft)")
            }
            $OutputBox.AppendText("`r`n`r`n")
            return $latestRelease
        }
        else {
            # Keine Releases - prüfe Tags
            return Get-TagsAndShowGuide -RepoOwner $RepoOwner -RepoName $RepoName -Headers $Headers -OutputBox $OutputBox
        }
    }
    catch {
        Set-OutputSelectionStyle -OutputBox $OutputBox -Style 'Error'
        $OutputBox.AppendText("[✗] Fehler beim Abrufen der Releases: $($_.Exception.Message)`r`n")
        return $null
    }
}

function Get-TagsAndShowGuide {
    [CmdletBinding()]
    param(
        [string]$RepoOwner,
        [string]$RepoName,
        [hashtable]$Headers,
        [System.Windows.Forms.RichTextBox]$OutputBox
    )
    
    Set-OutputSelectionStyle -OutputBox $OutputBox -Style 'Warning'
    $OutputBox.AppendText("[i] Keine Releases gefunden, prüfe Git-Tags...`r`n")
    
    try {
        $tagsUrl = "https://api.github.com/repos/$RepoOwner/$RepoName/tags"
        $tags = Invoke-RestMethod -Uri $tagsUrl -Headers $Headers -ErrorAction Stop
        
        if ($tags -and $tags.Count -gt 0) {
            Set-OutputSelectionStyle -OutputBox $OutputBox -Style 'Error'
            $OutputBox.AppendText("[!] Git-Tag gefunden: $($tags[0].name)`r`n`r`n")
            $OutputBox.AppendText("WICHTIG: Ein Git-Tag ist KEIN Release!`r`n")
            $OutputBox.AppendText("Sie müssen einen Release aus dem Tag erstellen:`r`n`r`n")
            $OutputBox.AppendText("1. Gehen Sie zu:`r`n")
            $OutputBox.AppendText("   https://github.com/$RepoOwner/$RepoName/releases/new`r`n`r`n")
            $OutputBox.AppendText("2. Wählen Sie den Tag: $($tags[0].name)`r`n")
            $OutputBox.AppendText("3. Laden Sie eine ZIP-Datei hoch`r`n")
            $OutputBox.AppendText("4. Klicken Sie auf 'Publish release'`r`n")
            
            [System.Windows.Forms.MessageBox]::Show(
                "Git-Tag '$($tags[0].name)' existiert, aber kein Release!`n`nEin Git-Tag alleine reicht nicht für Updates.`nErstellen Sie einen Release aus dem Tag.`n`nDetails siehe Ausgabe-Fenster.",
                "Kein Release vorhanden",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Warning
            )
        }
        else {
            Set-OutputSelectionStyle -OutputBox $OutputBox -Style 'Error'
            $OutputBox.AppendText("[✗] Keine Releases und keine Tags gefunden!`r`n`r`n")
            $OutputBox.AppendText("Erstellen Sie einen Release unter:`r`n")
            $OutputBox.AppendText("https://github.com/$RepoOwner/$RepoName/releases/new`r`n")
        }
    }
    catch {
        Set-OutputSelectionStyle -OutputBox $OutputBox -Style 'Error'
        $OutputBox.AppendText("[✗] Fehler beim Abrufen der Tags: $($_.Exception.Message)`r`n")
    }
    
    return $null
}

function Install-Update {
    [CmdletBinding()]
    param(
        [object]$LatestRelease,
        [string]$LatestVersion,
        [string]$CurrentVersion,
        [System.Windows.Forms.RichTextBox]$OutputBox,
        [System.Windows.Forms.ProgressBar]$ProgressBar,
        [System.Windows.Forms.Form]$MainForm,
        [string]$ApplicationPath,
        [string]$GitHubToken
    )
    
    Set-OutputSelectionStyle -OutputBox $OutputBox -Style 'Success'
    $OutputBox.AppendText("[✓] Update verfügbar: v$LatestVersion`r`n`r`n")
    
    # Asset-URL ermitteln
    $asset = $LatestRelease.assets | Where-Object { $_.name -like "*.zip" } | Select-Object -First 1
    
    if (-not $asset) {
        Set-OutputSelectionStyle -OutputBox $OutputBox -Style 'Error'
        $OutputBox.AppendText("[✗] Kein Download-Asset gefunden!`r`n")
        return $false
    }
    
    # Benutzer fragen
    $releaseNotesPreview = if ($LatestRelease.body.Length -gt 200) {
        $LatestRelease.body.Substring(0, 200) + "..."
    } else {
        $LatestRelease.body
    }
    
    $result = [System.Windows.Forms.MessageBox]::Show(
        "Neue Version verfügbar: v$LatestVersion`n`nAktuell installiert: v$CurrentVersion`n`nRelease-Notes:`n$releaseNotesPreview`n`nMöchten Sie jetzt updaten?",
        "Update verfügbar",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Information
    )
    
    if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
        $tempPath = [System.IO.Path]::GetTempPath()
        $zipPath = Join-Path $tempPath "Bockis-Update-v$LatestVersion.zip"
        $extractPath = Join-Path $tempPath "Bockis-Update-Extract"
        
        Set-OutputSelectionStyle -OutputBox $OutputBox -Style 'Info'
        $OutputBox.AppendText("[i] Download wird gestartet...`r`n")
        $OutputBox.AppendText("Quelle: $($asset.name)`r`n")
        $OutputBox.AppendText("Ziel: $zipPath`r`n`r`n")
        
        # Download
        $downloadSuccess = Start-AsyncDownload -Asset $asset -ZipPath $zipPath -OutputBox $OutputBox -ProgressBar $ProgressBar -GitHubToken $GitHubToken
        
        if (-not $downloadSuccess) {
            return $false
        }
        
        # Entpacken
        $extractSuccess = Start-AsyncExtract -ZipPath $zipPath -ExtractPath $extractPath -OutputBox $OutputBox -ProgressBar $ProgressBar
        
        if (-not $extractSuccess) {
            return $false
        }
        
        # Installation vorbereiten
        Start-UpdateInstallation -ExtractPath $extractPath -ZipPath $zipPath -ApplicationPath $ApplicationPath -OutputBox $OutputBox -ProgressBar $ProgressBar -MainForm $MainForm
        
        return $true
    }
    
    return $false
}

function Start-AsyncDownload {
    [CmdletBinding()]
    param(
        [object]$Asset,
        [string]$ZipPath,
        [System.Windows.Forms.RichTextBox]$OutputBox,
        [System.Windows.Forms.ProgressBar]$ProgressBar,
        [string]$GitHubToken
    )
    
    Update-ProgressStatus -StatusText "Download läuft..." -ProgressValue 0 -TextColor ([System.Drawing.Color]::White) -ProgressBar $ProgressBar
    
    $downloadUrl = $Asset.url
    $downloadHeaders = @{
        "User-Agent" = "Bockis-System-Tool"
        "Accept" = "application/octet-stream"
    }
    
    if ($GitHubToken -and $GitHubToken -ne "ghp_DEIN_TOKEN_HIER") {
        $downloadHeaders["Authorization"] = "token $GitHubToken"
    }
    
    try {
        Update-ProgressStatus -StatusText "Download: 0%" -ProgressValue 5 -TextColor ([System.Drawing.Color]::White) -ProgressBar $ProgressBar
        [System.Windows.Forms.Application]::DoEvents()
        
        # Background-Job für Download
        $downloadJob = Start-Job -ScriptBlock {
            param($url, $headers, $outFile)
            try {
                Invoke-WebRequest -Uri $url -Headers $headers -OutFile $outFile -TimeoutSec 300
                return @{ Success = $true }
            }
            catch {
                return @{ Success = $false; Error = $_.Exception.Message }
            }
        } -ArgumentList $downloadUrl, $downloadHeaders, $ZipPath
        
        # Progress-Timer
        $progressTimer = New-Object System.Windows.Forms.Timer
        $progressTimer.Interval = 500
        $script:downloadProgress = 5
        
        $progressTimer.Add_Tick({
            param($sender, $e)
            
            if ($downloadJob.State -eq 'Running') {
                $script:downloadProgress += 2
                if ($script:downloadProgress -gt 85) { $script:downloadProgress = 10 }
                
                if (Test-Path $ZipPath) {
                    $currentSize = (Get-Item $ZipPath).Length / 1MB
                    Update-ProgressStatus -StatusText "Download: $([math]::Round($currentSize, 1)) MB..." -ProgressValue $script:downloadProgress -TextColor ([System.Drawing.Color]::White) -ProgressBar $ProgressBar
                }
                else {
                    Update-ProgressStatus -StatusText "Download läuft..." -ProgressValue $script:downloadProgress -TextColor ([System.Drawing.Color]::White) -ProgressBar $ProgressBar
                }
                
                [System.Windows.Forms.Application]::DoEvents()
            }
            else {
                $sender.Stop()
                $sender.Dispose()
            }
        })
        
        $progressTimer.Start()
        
        # Warte auf Abschluss
        while ($downloadJob.State -eq 'Running') {
            [System.Windows.Forms.Application]::DoEvents()
            Start-Sleep -Milliseconds 100
        }
        
        if ($progressTimer.Enabled) {
            $progressTimer.Stop()
            $progressTimer.Dispose()
        }
        
        $jobResult = Receive-Job -Job $downloadJob
        Remove-Job -Job $downloadJob -Force
        
        if (-not $jobResult.Success) {
            throw $jobResult.Error
        }
        
        Update-ProgressStatus -StatusText "Download: 100%" -ProgressValue 95 -TextColor ([System.Drawing.Color]::White) -ProgressBar $ProgressBar
        [System.Windows.Forms.Application]::DoEvents()
        
        Set-OutputSelectionStyle -OutputBox $OutputBox -Style 'Success'
        $OutputBox.AppendText("[✓] Download abgeschlossen!`r`n`r`n")
        [System.Windows.Forms.Application]::DoEvents()
        
        return $true
    }
    catch {
        Set-OutputSelectionStyle -OutputBox $OutputBox -Style 'Error'
        $OutputBox.AppendText("[✗] Download fehlgeschlagen: $($_.Exception.Message)`r`n")
        return $false
    }
}

function Start-AsyncExtract {
    [CmdletBinding()]
    param(
        [string]$ZipPath,
        [string]$ExtractPath,
        [System.Windows.Forms.RichTextBox]$OutputBox,
        [System.Windows.Forms.ProgressBar]$ProgressBar
    )
    
    Set-OutputSelectionStyle -OutputBox $OutputBox -Style 'Info'
    $OutputBox.AppendText("[i] Extrahiere Update...`r`n")
    Update-ProgressStatus -StatusText "Entpacken..." -ProgressValue 50 -TextColor ([System.Drawing.Color]::White) -ProgressBar $ProgressBar
    [System.Windows.Forms.Application]::DoEvents()
    
    if (Test-Path $ExtractPath) {
        Remove-Item $ExtractPath -Recurse -Force
    }
    
    $extractJob = Start-Job -ScriptBlock {
        param($zipPath, $extractPath)
        try {
            Expand-Archive -Path $zipPath -DestinationPath $extractPath -Force
            return @{ Success = $true }
        }
        catch {
            return @{ Success = $false; Error = $_.Exception.Message }
        }
    } -ArgumentList $ZipPath, $ExtractPath
    
    $script:extractProgress = 50
    while ($extractJob.State -eq 'Running') {
        $script:extractProgress += 1
        if ($script:extractProgress -gt 90) { $script:extractProgress = 50 }
        Update-ProgressStatus -StatusText "Entpacken... $script:extractProgress%" -ProgressValue $script:extractProgress -TextColor ([System.Drawing.Color]::White) -ProgressBar $ProgressBar
        [System.Windows.Forms.Application]::DoEvents()
        Start-Sleep -Milliseconds 200
    }
    
    $extractResult = Receive-Job -Job $extractJob
    Remove-Job -Job $extractJob -Force
    
    if (-not $extractResult.Success) {
        Set-OutputSelectionStyle -OutputBox $OutputBox -Style 'Error'
        $OutputBox.AppendText("[✗] Entpacken fehlgeschlagen: $($extractResult.Error)`r`n")
        return $false
    }
    
    Update-ProgressStatus -StatusText "Entpacken abgeschlossen" -ProgressValue 95 -TextColor ([System.Drawing.Color]::White) -ProgressBar $ProgressBar
    [System.Windows.Forms.Application]::DoEvents()
    
    return $true
}

function Start-UpdateInstallation {
    [CmdletBinding()]
    param(
        [string]$ExtractPath,
        [string]$ZipPath,
        [string]$ApplicationPath,
        [System.Windows.Forms.RichTextBox]$OutputBox,
        [System.Windows.Forms.ProgressBar]$ProgressBar,
        [System.Windows.Forms.Form]$MainForm
    )
    
    $updateScript = @"
Start-Sleep -Seconds 2
Write-Host 'Installiere Update...'
`$source = '$ExtractPath\*'
`$dest = '$ApplicationPath'
Copy-Item -Path `$source -Destination `$dest -Recurse -Force
Remove-Item '$ZipPath' -Force
Remove-Item '$ExtractPath' -Recurse -Force
Write-Host 'Update abgeschlossen! Starte Anwendung...'
Start-Process powershell.exe -ArgumentList '-ExecutionPolicy Bypass -File "$ApplicationPath\Win_Gui_Module.ps1"'
"@
    
    $tempPath = [System.IO.Path]::GetTempPath()
    $updateScriptPath = Join-Path $tempPath "BockisUpdate.ps1"
    $updateScript | Out-File -FilePath $updateScriptPath -Encoding UTF8 -Force
    
    Set-OutputSelectionStyle -OutputBox $OutputBox -Style 'Success'
    $OutputBox.AppendText("[✓] Update wird installiert...`r`n")
    $OutputBox.AppendText("[i] Anwendung wird neu gestartet!`r`n")
    
    Update-ProgressStatus -StatusText "Installation..." -ProgressValue 100 -TextColor ([System.Drawing.Color]::White) -ProgressBar $ProgressBar
    
    Start-Process powershell.exe -ArgumentList "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$updateScriptPath`"" -WindowStyle Hidden
    
    Start-Sleep -Milliseconds 500
    $MainForm.Close()
}

function Show-NoUpdateNeeded {
    [CmdletBinding()]
    param(
        [string]$CurrentVersion,
        [string]$LatestVersion,
        [System.Windows.Forms.RichTextBox]$OutputBox,
        [bool]$IsNewer
    )
    
    Set-OutputSelectionStyle -OutputBox $OutputBox -Style 'Success'
    
    if ($IsNewer) {
        $OutputBox.AppendText("[✓] Ihre Version ist neuer als der letzte Release!`r`n")
        $OutputBox.AppendText("[i] Installiert: v$CurrentVersion | Release: v$LatestVersion`r`n")
        
        [System.Windows.Forms.MessageBox]::Show(
            "Ihre Version ist neuer als der letzte veröffentlichte Release.`n`nInstalliert: v$CurrentVersion`nLetzter Release: v$LatestVersion`n`nSie verwenden vermutlich eine Entwicklungsversion.",
            "Keine Updates",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        )
    }
    else {
        $OutputBox.AppendText("[✓] Sie verwenden bereits die neueste Version!`r`n")
        
        [System.Windows.Forms.MessageBox]::Show(
            "Sie verwenden bereits die neueste Version: v$CurrentVersion",
            "Keine Updates",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        )
    }
}

function Show-UpdateError {
    [CmdletBinding()]
    param(
        [System.Management.Automation.ErrorRecord]$ErrorRecord,
        [System.Windows.Forms.RichTextBox]$OutputBox
    )
    
    Set-OutputSelectionStyle -OutputBox $OutputBox -Style 'Error'
    $OutputBox.AppendText("[✗] Fehler beim Update-Check: $($ErrorRecord.Exception.Message)`r`n")
    
    $errorDetails = if ($ErrorRecord.Exception.Response) {
        "Status: $($ErrorRecord.Exception.Response.StatusCode.value__)`n$($ErrorRecord.Exception.Message)"
    } else {
        $ErrorRecord.Exception.Message
    }
    
    [System.Windows.Forms.MessageBox]::Show(
        "Fehler beim Prüfen auf Updates:`n`n$errorDetails`n`nMögliche Ursachen:`n• Keine Internetverbindung`n• Repository existiert nicht`n• Kein Release vorhanden`n• Token ungültig",
        "Update-Fehler",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Error
    )
}

# ===================================================================
# HILFSFUNKTIONEN FÜR GUI-UPDATES
# ===================================================================

function Update-ProgressStatus {
    [CmdletBinding()]
    param(
        [string]$StatusText,
        [int]$ProgressValue,
        [System.Drawing.Color]$TextColor,
        [System.Windows.Forms.ProgressBar]$ProgressBar
    )
    
    if ($ProgressBar) {
        $ProgressBar.Value = [Math]::Min([Math]::Max($ProgressValue, 0), 100)
    }
    
    # Optional: Status-Label updaten (falls vorhanden)
    # Wird vom Hauptscript über Set-OutputSelectionStyle gehandhabt
}

# Export der öffentlichen Funktionen
Export-ModuleMember -Function Invoke-UpdateCheck

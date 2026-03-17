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
# VERSIONSAUSWAHL UND INSTALLATION
# ===================================================================

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
        [string]$GitHubToken,
        [ValidateSet('Update', 'Downgrade', 'Neuinstallation')]
        [string]$Operation = 'Update'
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
    
    $operationTitle = switch ($Operation) {
        'Downgrade' { 'Downgrade auswählen' }
        'Neuinstallation' { 'Version installieren' }
        default { 'Update verfügbar' }
    }

    $operationQuestion = switch ($Operation) {
        'Downgrade' { "Möchten Sie auf diese ältere Version wechseln?" }
        'Neuinstallation' { "Möchten Sie diese Version installieren?" }
        default { "Möchten Sie jetzt updaten?" }
    }

    $result = [System.Windows.Forms.MessageBox]::Show(
        "Ausgewählte Version: v$LatestVersion`n`nAktuell installiert: v$CurrentVersion`n`nRelease-Notes:`n$releaseNotesPreview`n`n$operationQuestion",
        $operationTitle,
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

function Get-ReleaseListWithFallback {
    [CmdletBinding()]
    param(
        [string]$RepoOwner,
        [string]$RepoName,
        [string]$GitHubToken,
        [System.Windows.Forms.RichTextBox]$OutputBox
    )

    $headers = @{
        "User-Agent" = "Bockis-System-Tool"
        "Accept"     = "application/vnd.github+json"
    }

    if (-not [string]::IsNullOrWhiteSpace($GitHubToken) -and $GitHubToken -ne "ghp_DEIN_TOKEN_HIER") {
        $headers["Authorization"] = "token $GitHubToken"
    }

    $repoCandidates = [System.Collections.Generic.List[string]]::new()
    $repoCandidates.Add($RepoName)
    if ($RepoName -match '-') {
        $repoCandidates.Add(($RepoName -replace '-', '_'))
    }
    if ($RepoName -match '_') {
        $repoCandidates.Add(($RepoName -replace '_', '-'))
    }

    $lastError = $null

    foreach ($candidate in ($repoCandidates | Select-Object -Unique)) {
        try {
            $allReleasesUrl = "https://api.github.com/repos/$RepoOwner/$candidate/releases"
            $releases = Invoke-RestMethod -Uri $allReleasesUrl -Headers $headers -ErrorAction Stop
            if ($releases -and $releases.Count -gt 0) {
                return @($releases)
            }
        } catch {
            $lastError = $_
        }
    }

    if ($headers.ContainsKey('Authorization')) {
        $headersNoAuth = @{
            "User-Agent" = "Bockis-System-Tool"
            "Accept"     = "application/vnd.github+json"
        }

        foreach ($candidate in ($repoCandidates | Select-Object -Unique)) {
            try {
                $allReleasesUrl = "https://api.github.com/repos/$RepoOwner/$candidate/releases"
                $releases = Invoke-RestMethod -Uri $allReleasesUrl -Headers $headersNoAuth -ErrorAction Stop
                if ($releases -and $releases.Count -gt 0) {
                    return @($releases)
                }
            } catch {
                $lastError = $_
            }
        }
    }

    if ($OutputBox) {
        Set-OutputSelectionStyle -OutputBox $OutputBox -Style 'Error'
        if ($lastError) {
            $OutputBox.AppendText("[✗] Keine Releases gefunden: $($lastError.Exception.Message)`r`n")
        } else {
            $OutputBox.AppendText("[✗] Keine Releases gefunden.`r`n")
        }
    }

    return @()
}

function Show-ReleaseSelectionDialog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [array]$Releases,
        [Parameter(Mandatory = $true)]
        [string]$CurrentVersion
    )

    if (-not $Releases -or $Releases.Count -eq 0) {
        return $null
    }

    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Version auswählen"
    $form.Size = New-Object System.Drawing.Size(700, 420)
    $form.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterParent
    $form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $form.MaximizeBox = $false
    $form.MinimizeBox = $false

    $label = New-Object System.Windows.Forms.Label
    $label.Text = "Wählen Sie eine Version (Rollback/Downgrade bei Problemen):" 
    $label.Location = New-Object System.Drawing.Point(12, 12)
    $label.Size = New-Object System.Drawing.Size(660, 24)
    $form.Controls.Add($label)

    $listBox = New-Object System.Windows.Forms.ListBox
    $listBox.Location = New-Object System.Drawing.Point(12, 40)
    $listBox.Size = New-Object System.Drawing.Size(660, 280)
    $listBox.Font = New-Object System.Drawing.Font("Segoe UI", 9)

    foreach ($release in $Releases) {
        $tag = "$($release.tag_name)"
        $versionText = $tag -replace '^v', ''
        $mode = 'Neuinstallation'

        try {
            if ([version]$versionText -gt [version]$CurrentVersion) {
                $mode = 'Update'
            } elseif ([version]$versionText -lt [version]$CurrentVersion) {
                $mode = 'Downgrade'
            } else {
                $mode = 'Aktuell'
            }
        } catch {
            if ($versionText -eq $CurrentVersion) {
                $mode = 'Aktuell'
            }
        }

        $published = if ($release.published_at) { (Get-Date $release.published_at -Format 'yyyy-MM-dd') } else { 'unbekannt' }
        $listText = "{0,-14} [{1}]  ({2})" -f $tag, $mode, $published
        $null = $listBox.Items.Add([PSCustomObject]@{
                Display = $listText
                Release = $release
                Mode    = $mode
                Version = $versionText
            })
    }

    $listBox.DisplayMember = 'Display'
    if ($listBox.Items.Count -gt 0) {
        $defaultIndex = 0
        for ($i = 0; $i -lt $listBox.Items.Count; $i++) {
            if ($listBox.Items[$i].Mode -eq 'Downgrade') {
                $defaultIndex = $i
                break
            }
        }
        $listBox.SelectedIndex = $defaultIndex
    }
    $form.Controls.Add($listBox)

    $btnOk = New-Object System.Windows.Forms.Button
    $btnOk.Text = "Auswählen"
    $btnOk.Location = New-Object System.Drawing.Point(486, 335)
    $btnOk.Size = New-Object System.Drawing.Size(90, 28)
    $btnOk.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $form.Controls.Add($btnOk)

    $btnCancel = New-Object System.Windows.Forms.Button
    $btnCancel.Text = "Abbrechen"
    $btnCancel.Location = New-Object System.Drawing.Point(582, 335)
    $btnCancel.Size = New-Object System.Drawing.Size(90, 28)
    $btnCancel.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $form.Controls.Add($btnCancel)

    $form.AcceptButton = $btnOk
    $form.CancelButton = $btnCancel

    $dialogResult = $form.ShowDialog()
    if ($dialogResult -ne [System.Windows.Forms.DialogResult]::OK -or -not $listBox.SelectedItem) {
        return $null
    }

    return $listBox.SelectedItem
}

function Invoke-ReleaseSelectionUpdate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$CurrentVersion,

        [Parameter(Mandatory = $true)]
        [System.Windows.Forms.RichTextBox]$OutputBox,

        [Parameter(Mandatory = $true)]
        [System.Windows.Forms.ProgressBar]$ProgressBar,

        [Parameter(Mandatory = $true)]
        [System.Windows.Forms.Form]$MainForm,

        [Parameter(Mandatory = $true)]
        [string]$ApplicationPath,

        [Parameter(Mandatory = $false)]
        [string]$RepoOwner = "ReXx09",

        [Parameter(Mandatory = $false)]
        [string]$RepoName = "Bockis-Win_Gui",

        [Parameter(Mandatory = $false)]
        [string]$GitHubToken = ""
    )

    try {
        Set-OutputSelectionStyle -OutputBox $OutputBox -Style 'Info'
        $OutputBox.AppendText("[i] Lade verfügbare Releases...`r`n")

        $releases = Get-ReleaseListWithFallback -RepoOwner $RepoOwner -RepoName $RepoName -GitHubToken $GitHubToken -OutputBox $OutputBox
        if (-not $releases -or $releases.Count -eq 0) {
            return @{ Success = $false; Cancelled = $false; Message = "Keine Releases gefunden" }
        }

        $selection = Show-ReleaseSelectionDialog -Releases $releases -CurrentVersion $CurrentVersion
        if (-not $selection) {
            Set-OutputSelectionStyle -OutputBox $OutputBox -Style 'Info'
            $OutputBox.AppendText("[i] Versionsauswahl abgebrochen.`r`n")
            return @{ Success = $false; Cancelled = $true; Message = "Abgebrochen" }
        }

        $operationMode = switch ($selection.Mode) {
            'Downgrade' { 'Downgrade' }
            'Aktuell' { 'Neuinstallation' }
            default { 'Update' }
        }

        $installSuccess = Install-Update -LatestRelease $selection.Release -LatestVersion $selection.Version -CurrentVersion $CurrentVersion `
            -OutputBox $OutputBox -ProgressBar $ProgressBar -MainForm $MainForm -ApplicationPath $ApplicationPath -GitHubToken $GitHubToken -Operation $operationMode

        if ($installSuccess) {
            return @{ Success = $true; Cancelled = $false; Message = "Versionswechsel gestartet" }
        }

        return @{ Success = $false; Cancelled = $false; Message = "Installation nicht gestartet" }
    } catch {
        Show-UpdateError -ErrorRecord $_ -OutputBox $OutputBox
        return @{ Success = $false; Cancelled = $false; Message = $_.Exception.Message }
    }
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
        "Accept"     = "application/octet-stream"
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
            } catch {
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
                    } else {
                        Update-ProgressStatus -StatusText "Download läuft..." -ProgressValue $script:downloadProgress -TextColor ([System.Drawing.Color]::White) -ProgressBar $ProgressBar
                    }
                
                    [System.Windows.Forms.Application]::DoEvents()
                } else {
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
    } catch {
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
        } catch {
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
Export-ModuleMember -Function Invoke-ReleaseSelectionUpdate

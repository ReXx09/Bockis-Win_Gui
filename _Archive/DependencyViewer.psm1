# DependencyViewer.psm1
# Modul für die grafische Anzeige von System-Abhängigkeiten

<#
.SYNOPSIS
Zeigt eine interaktive Abhängigkeits-Übersicht in der OutputBox an.

.DESCRIPTION
Erstellt eine formatierte Übersicht aller System-Abhängigkeiten mit:
- Status-Anzeige (✓ installiert, ✗ fehlt)
- Versions-Informationen
- Installations-Buttons für fehlende Komponenten

.PARAMETER OutputBox
Die RichTextBox in der die Übersicht angezeigt werden soll

.PARAMETER ParentPanel
Das Panel in dem Installations-Buttons platziert werden sollen
#>
function Show-DependencyOverview {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [System.Windows.Forms.RichTextBox]$OutputBox,
        
        [Parameter(Mandatory=$true)]
        $ParentPanel,
        
        [Parameter(Mandatory=$false)]
        $TooltipObj
    )
    
    # OutputBox leeren
    $OutputBox.Clear()
    
    # Banner
    Set-OutputSelectionStyle -OutputBox $OutputBox -Style 'BannerFrame'
    $OutputBox.AppendText("`t╔═══════════════════════════════════════════════════════════════╗`r`n")
    Set-OutputSelectionStyle -OutputBox $OutputBox -Style 'BannerTitle'
    $OutputBox.AppendText("`t║              SYSTEM-ABHÄNGIGKEITEN ÜBERBLICK                  ║`r`n")
    Set-OutputSelectionStyle -OutputBox $OutputBox -Style 'BannerFrame'
    $OutputBox.AppendText("`t╚═══════════════════════════════════════════════════════════════╝`r`n`r`n")
    
    # System-Informationen
    Set-OutputSelectionStyle -OutputBox $OutputBox -Style 'Heading'
    $OutputBox.AppendText("🖥️  SYSTEM-INFORMATIONEN`r`n")
    Set-OutputSelectionStyle -OutputBox $OutputBox -Style 'Muted'
    $OutputBox.AppendText("$('─' * 65)`r`n`r`n")
    
    # PowerShell Version
    $psVersion = $PSVersionTable.PSVersion
    $psEditionInfo = $PSVersionTable.PSEdition
    $psIcon = if ($psEditionInfo -eq 'Core') { '🔷' } else { '📘' }
    
    Set-OutputSelectionStyle -OutputBox $OutputBox -Style 'Info'
    $OutputBox.AppendText("$psIcon PowerShell:        ")
    Set-OutputSelectionStyle -OutputBox $OutputBox -Style 'Success'
    $OutputBox.AppendText("$psVersion ($psEditionInfo)`r`n")
    
    if ($psEditionInfo -eq 'Core' -and $psVersion.Major -ge 7) {
        Set-OutputSelectionStyle -OutputBox $OutputBox -Style 'Warning'
        $OutputBox.AppendText("   ⚠ Hardware-Monitor funktioniert optimal mit PowerShell 5.1`r`n")
    }
    
    # .NET Framework Version
    try {
        $netVersion = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full' -ErrorAction SilentlyContinue).Version
        if ($netVersion) {
            Set-OutputSelectionStyle -OutputBox $OutputBox -Style 'Info'
            $OutputBox.AppendText("📦 .NET Framework:   ")
            Set-OutputSelectionStyle -OutputBox $OutputBox -Style 'Success'
            $OutputBox.AppendText("$netVersion`r`n")
        }
    }
    catch { }
    
    $OutputBox.AppendText("`r`n")
    
    # Hardware-Monitor Abhängigkeiten
    Set-OutputSelectionStyle -OutputBox $OutputBox -Style 'Heading'
    $OutputBox.AppendText("🔧 HARDWARE-MONITOR ABHÄNGIGKEITEN`r`n")
    Set-OutputSelectionStyle -OutputBox $OutputBox -Style 'Muted'
    $OutputBox.AppendText("$('─' * 65)`r`n`r`n")
    
    # PawnIO-Treiber prüfen
    $pawnIOInstalled = $false
    $pawnIORunning = $false
    $pawnIOVersion = "Nicht installiert"
    
    try {
        $pawnIOPackage = winget list namazso.PawnIO 2>$null | Select-String "PawnIO"
        if ($pawnIOPackage) {
            $pawnIOInstalled = $true
            if ($pawnIOPackage -match '(\d+\.\d+\.\d+\.\d+)') {
                $pawnIOVersion = $matches[1]
            }
        }
        
        $pawnIOService = Get-Service -Name "PawnIO" -ErrorAction SilentlyContinue
        if ($pawnIOService -and $pawnIOService.Status -eq 'Running') {
            $pawnIORunning = $true
        }
    }
    catch { }
    
    # PawnIO Status anzeigen
    if ($pawnIORunning) {
        Set-OutputSelectionStyle -OutputBox $OutputBox -Style 'Success'
        $OutputBox.AppendText("✓ PawnIO-Treiber:    ")
        Set-OutputSelectionStyle -OutputBox $OutputBox -Style 'Info'
        $OutputBox.AppendText("Installiert & Aktiv")
        Set-OutputSelectionStyle -OutputBox $OutputBox -Style 'Muted'
        $OutputBox.AppendText(" ($pawnIOVersion)`r`n")
    }
    elseif ($pawnIOInstalled) {
        Set-OutputSelectionStyle -OutputBox $OutputBox -Style 'Warning'
        $OutputBox.AppendText("⚠ PawnIO-Treiber:    ")
        Set-OutputSelectionStyle -OutputBox $OutputBox -Style 'Info'
        $OutputBox.AppendText("Installiert, aber nicht gestartet")
        Set-OutputSelectionStyle -OutputBox $OutputBox -Style 'Muted'
        $OutputBox.AppendText(" ($pawnIOVersion)`r`n")
        Set-OutputSelectionStyle -OutputBox $OutputBox -Style 'Warning'
        $OutputBox.AppendText("   → System-Neustart erforderlich`r`n")
    }
    else {
        Set-OutputSelectionStyle -OutputBox $OutputBox -Style 'Error'
        $OutputBox.AppendText("✗ PawnIO-Treiber:    ")
        Set-OutputSelectionStyle -OutputBox $OutputBox -Style 'Warning'
        $OutputBox.AppendText("Nicht installiert`r`n")
        Set-OutputSelectionStyle -OutputBox $OutputBox -Style 'Muted'
        $OutputBox.AppendText("   → Erforderlich für sicheren Hardware-Zugriff`r`n")
    }
    
    $OutputBox.AppendText("`r`n")
    
    # DLL-Dateien prüfen
    Set-OutputSelectionStyle -OutputBox $OutputBox -Style 'Info'
    $OutputBox.AppendText("📚 DLL-Bibliotheken:`r`n`r`n")
    
    $scriptRoot = $PSScriptRoot
    if (-not $scriptRoot) {
        $scriptRoot = Split-Path -Parent $PSCommandPath
    }
    $libPath = Join-Path (Split-Path -Parent (Split-Path -Parent $scriptRoot)) "Lib"
    
    $requiredDLLs = @(
        @{ Name = 'LibreHardwareMonitorLib.dll'; Description = 'Hardware-Monitoring Hauptmodul'; Critical = $true }
        @{ Name = 'System.Memory.dll'; Description = 'Memory-Management'; Critical = $true }
        @{ Name = 'System.Runtime.CompilerServices.Unsafe.dll'; Description = 'Low-Level Operationen'; Critical = $true }
        @{ Name = 'BlackSharp.Core.dll'; Description = 'Core-Funktionen'; Critical = $true }
        @{ Name = 'RAMSPDToolkit-NDD.dll'; Description = 'RAM SPD-Auslese'; Critical = $false }
        @{ Name = 'DiskInfoToolkit.dll'; Description = 'Festplatten-Info'; Critical = $false }
    )
    
    $missingDLLs = @()
    
    foreach ($dll in $requiredDLLs) {
        $dllPath = Join-Path $libPath $dll.Name
        $exists = Test-Path $dllPath
        
        if ($exists) {
            try {
                $fileInfo = Get-Item $dllPath -ErrorAction SilentlyContinue
                $sizeKB = [math]::Round($fileInfo.Length / 1KB, 1)
                
                Set-OutputSelectionStyle -OutputBox $OutputBox -Style 'Success'
                $OutputBox.AppendText("   ✓ ")
                Set-OutputSelectionStyle -OutputBox $OutputBox -Style 'Info'
                $OutputBox.AppendText("$($dll.Name.PadRight(40))")
                Set-OutputSelectionStyle -OutputBox $OutputBox -Style 'Muted'
                $OutputBox.AppendText("$sizeKB KB`r`n")
            }
            catch {
                Set-OutputSelectionStyle -OutputBox $OutputBox -Style 'Success'
                $OutputBox.AppendText("   ✓ ")
                Set-OutputSelectionStyle -OutputBox $OutputBox -Style 'Info'
                $OutputBox.AppendText("$($dll.Name)`r`n")
            }
        }
        else {
            Set-OutputSelectionStyle -OutputBox $OutputBox -Style 'Error'
            $OutputBox.AppendText("   ✗ ")
            Set-OutputSelectionStyle -OutputBox $OutputBox -Style 'Warning'
            $OutputBox.AppendText("$($dll.Name.PadRight(40))")
            Set-OutputSelectionStyle -OutputBox $OutputBox -Style 'Error'
            $OutputBox.AppendText("FEHLT`r`n")
            
            if ($dll.Critical) {
                $missingDLLs += $dll
            }
        }
    }
    
    $OutputBox.AppendText("`r`n")
    
    # Zusammenfassung
    Set-OutputSelectionStyle -OutputBox $OutputBox -Style 'Heading'
    $OutputBox.AppendText("📊 STATUS-ZUSAMMENFASSUNG`r`n")
    Set-OutputSelectionStyle -OutputBox $OutputBox -Style 'Muted'
    $OutputBox.AppendText("$('─' * 65)`r`n`r`n")
    
    if ($pawnIORunning -and $missingDLLs.Count -eq 0) {
        Set-OutputSelectionStyle -OutputBox $OutputBox -Style 'Success'
        $OutputBox.AppendText("✅ Hardware-Monitor VERFÜGBAR`r`n")
        Set-OutputSelectionStyle -OutputBox $OutputBox -Style 'Info'
        $OutputBox.AppendText("   Alle Abhängigkeiten erfüllt. Hardware-Monitoring einsatzbereit!`r`n")
    }
    else {
        Set-OutputSelectionStyle -OutputBox $OutputBox -Style 'Warning'
        $OutputBox.AppendText("⚠️  Hardware-Monitor NICHT VERFÜGBAR`r`n`r`n")
        
        if (-not $pawnIORunning) {
            Set-OutputSelectionStyle -OutputBox $OutputBox -Style 'Error'
            $OutputBox.AppendText("   ❌ PawnIO-Treiber fehlt oder nicht gestartet`r`n")
        }
        
        if ($missingDLLs.Count -gt 0) {
            Set-OutputSelectionStyle -OutputBox $OutputBox -Style 'Error'
            $OutputBox.AppendText("   ❌ $($missingDLLs.Count) kritische DLL(s) fehlen`r`n")
        }
    }
    
    $OutputBox.AppendText("`r`n")
    
    # Installations-Button für PawnIO erstellen (wenn nicht installiert)
    if (-not $pawnIORunning) {
        # Entferne alte Buttons
        $oldButtons = $ParentPanel.Controls | Where-Object { $_.Tag -eq 'DependencyInstallButton' }
        foreach ($btn in $oldButtons) {
            $ParentPanel.Controls.Remove($btn)
        }
        
        # Erstelle Installations-Button
        $btnInstallPawnIO = New-Object System.Windows.Forms.Button
        $btnInstallPawnIO.Text = if ($pawnIOInstalled) { "🔄 System neu starten" } else { "📥 PawnIO installieren" }
        $btnInstallPawnIO.Size = New-Object System.Drawing.Size(250, 40)
        $btnInstallPawnIO.Location = New-Object System.Drawing.Point(20, 480)
        $btnInstallPawnIO.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
        $btnInstallPawnIO.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 212)
        $btnInstallPawnIO.ForeColor = [System.Drawing.Color]::White
        $btnInstallPawnIO.FlatAppearance.BorderSize = 0
        $btnInstallPawnIO.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
        $btnInstallPawnIO.Tag = 'DependencyInstallButton'
        $btnInstallPawnIO.Cursor = [System.Windows.Forms.Cursors]::Hand
        
        $btnInstallPawnIO.Add_Click({
            if ($pawnIOInstalled) {
                # Neustart-Dialog
                $result = [System.Windows.Forms.MessageBox]::Show(
                    "PawnIO ist installiert, benötigt aber einen Systemneustart.`n`nMöchten Sie jetzt neu starten?",
                    "System-Neustart",
                    [System.Windows.Forms.MessageBoxButtons]::YesNo,
                    [System.Windows.Forms.MessageBoxIcon]::Question
                )
                
                if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
                    Restart-Computer -Force
                }
            }
            else {
                # Installation starten
                $this.Enabled = $false
                $this.Text = "⏳ Installiere PawnIO..."
                
                try {
                    $OutputBox.AppendText("`r`n")
                    Set-OutputSelectionStyle -OutputBox $OutputBox -Style 'Info'
                    $OutputBox.AppendText("📥 Starte PawnIO-Installation...`r`n")
                    $OutputBox.ScrollToCaret()
                    
                    $process = Start-Process -FilePath "winget" -ArgumentList "install","namazso.PawnIO","--accept-source-agreements","--accept-package-agreements" -NoNewWindow -PassThru -Wait
                    
                    if ($process.ExitCode -eq 0) {
                        Set-OutputSelectionStyle -OutputBox $OutputBox -Style 'Success'
                        $OutputBox.AppendText("✅ PawnIO erfolgreich installiert!`r`n")
                        Set-OutputSelectionStyle -OutputBox $OutputBox -Style 'Warning'
                        $OutputBox.AppendText("⚠️  System-Neustart erforderlich für Hardware-Monitor!`r`n")
                        
                        $this.Text = "🔄 System neu starten"
                        $this.Enabled = $true
                        
                        # Frage nach Neustart
                        Start-Sleep -Milliseconds 500
                        $result = [System.Windows.Forms.MessageBox]::Show(
                            "PawnIO wurde erfolgreich installiert!`n`nEin System-Neustart ist erforderlich um den Treiber zu aktivieren.`n`nJetzt neu starten?",
                            "Installation erfolgreich",
                            [System.Windows.Forms.MessageBoxButtons]::YesNo,
                            [System.Windows.Forms.MessageBoxIcon]::Information
                        )
                        
                        if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
                            Restart-Computer -Force
                        }
                    }
                    else {
                        Set-OutputSelectionStyle -OutputBox $OutputBox -Style 'Error'
                        $OutputBox.AppendText("❌ Installation fehlgeschlagen (Exit Code: $($process.ExitCode))`r`n")
                        $this.Text = "📥 PawnIO installieren"
                        $this.Enabled = $true
                    }
                }
                catch {
                    Set-OutputSelectionStyle -OutputBox $OutputBox -Style 'Error'
                    $OutputBox.AppendText("❌ Fehler bei Installation: $($_.Exception.Message)`r`n")
                    $this.Text = "📥 PawnIO installieren"
                    $this.Enabled = $true
                }
                
                $OutputBox.ScrollToCaret()
            }
        })
        
        $btnInstallPawnIO.Add_MouseEnter({
            $this.BackColor = [System.Drawing.Color]::FromArgb(0, 140, 232)
        })
        
        $btnInstallPawnIO.Add_MouseLeave({
            $this.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 212)
        })
        
        $ParentPanel.Controls.Add($btnInstallPawnIO)
        
        if ($TooltipObj) {
            $tooltipText = if ($pawnIOInstalled) {
                "Starte System neu um PawnIO-Treiber zu aktivieren"
            } else {
                "Installiert PawnIO-Treiber via winget (Administrator-Rechte erforderlich)"
            }
            $TooltipObj.SetToolTip($btnInstallPawnIO, $tooltipText)
        }
    }
    
    # Hinweis-Text
    Set-OutputSelectionStyle -OutputBox $OutputBox -Style 'Muted'
    $OutputBox.AppendText("`r`n💡 Tipp: Diese Übersicht zeigt alle erforderlichen Komponenten für das Hardware-Monitoring.`r`n")
    $OutputBox.AppendText("   Fehlende Komponenten können direkt installiert werden.`r`n")
}

Export-ModuleMember -Function Show-DependencyOverview

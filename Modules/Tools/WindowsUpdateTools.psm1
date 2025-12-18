# Import required modules
Import-Module "$PSScriptRoot\..\Core\Core.psm1" -Force -Global
Import-Module "$PSScriptRoot\..\Core\TextStyle.psm1" -Force -Global

# Add Windows Update configuration to SystemToolConfig
$Global:SystemToolConfig.Tools["WindowsUpdate"] = @{
    RequiresAdmin = $true
    Timeout       = 300
    Description   = "Windows Update"
}

# Hilfsfunktion zur Interpretation von Update-Fehlercodes
function Get-UpdateErrorDescription {
    param([int]$HResult)
    
    $errorDescriptions = @{
        0x80070020 = "Datei wird verwendet (ein Neustart könnte helfen)"
        0x80070005 = "Zugriff verweigert (Admin-Rechte erforderlich)"
        0x8007000E = "Nicht genügend Arbeitsspeicher"
        0x80070057 = "Ungültiger Parameter"
        0x8024000B = "Update wurde bereits heruntergeladen"
        0x80240022 = "Update nicht mehr verfügbar"
        0x8024001E = "Vorgang wurde beendet"
        0x80244019 = "Download-Größe überschreitet Maximum"
        0x80244022 = "Download fehlgeschlagen (Netzwerkproblem)"
        0x80070002 = "Datei nicht gefunden"
        0x80070003 = "Pfad nicht gefunden"
        0x8007000D = "Beschädigte Daten"
        0x80070643 = "Installation fehlgeschlagen (allgemeiner Fehler)"
        0x800F0922 = "Nicht genügend Speicherplatz"
    }
    
    if ($errorDescriptions.ContainsKey($HResult)) {
        return $errorDescriptions[$HResult]
    }
    return "Unbekannter Fehler"
}

# Function to start Windows Update and show status
function Start-WindowsUpdate {
    param(
        [System.Windows.Forms.RichTextBox]$outputBox,
        [System.Windows.Forms.ProgressBar]$progressBar = $null,
        [System.Windows.Forms.Form]$MainForm = $null
    )
    # outputBox zuruecksetzen
    $outputBox.Clear()

    # In Log-Datei und Datenbank schreiben, dass Windows Update gestartet wird
    Write-ToolLog -ToolName "WindowsUpdate" -Message "Windows Update wird gestartet" -OutputBox $outputBox -Style 'Action' -Level "Information" -SaveToDatabase

    # ProgressBar initialisieren, wenn vorhanden
    if ($progressBar) {
        $progressBar.Value = 10
        $progressBar.CustomText = "Windows Update wird initialisiert..."
        $progressBar.TextColor = [System.Drawing.Color]::White
    }

    Clear-Host
    
       
    # Rahmen oben
    Write-Host "╔══════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-ColoredCenteredText                              "Windows Update"                                          
    Write-Host "╚══════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Green
    
    Write-Host 
    Write-Host '   888       888  d8b                 888                                                 ' -ForegroundColor Cyan
    Write-Host '   888   o   888  Y8P                 888                                                 ' -ForegroundColor Blue
    Write-Host '   888  d8b  888                      888                                                 ' -ForegroundColor Cyan
    Write-Host '   888 d888b 888  888  88888b.    .d88888   .d88b.   888  888  888  .d8888b               ' -ForegroundColor Blue
    Write-Host '   888d88888b888  888  888 "88b  d88" 888  d88""88b  888  888  888  88K                   ' -ForegroundColor Cyan
    Write-Host '   88888P Y88888  888  888  888  888  888  888  888  888  888  888  "Y8888b.              ' -ForegroundColor Blue    
    Write-Host '   8888P   Y8888  888  888  888  Y88b 888  Y88..88P  Y88b 888 d88P       X88              ' -ForegroundColor Cyan
    Write-Host '   888P     Y888  888  888  888   "Y88888   "Y88P"    "Y8888888P"    88888P               ' -ForegroundColor Blue
    Write-Host                                                                    
    Write-Host '   888     888                 888            888                                         ' -ForegroundColor Cyan
    Write-Host '   888     888                 888            888                                         ' -ForegroundColor Blue
    Write-Host '   888     888                 888            888                                         ' -ForegroundColor Cyan
    Write-Host '   888     888  88888b.    .d88888   8888b.   888888  .d88b.                              ' -ForegroundColor Blue
    Write-Host '   888     888  888 "88b  d88" 888      "88b  888    d8P  Y8b                             ' -ForegroundColor Cyan
    Write-Host '   888     888  888  888  888  888  .d888888  888    88888888                             ' -ForegroundColor Blue
    Write-Host '   Y88b. .d88P  888 d88P  Y88b 888  888  888  Y88b.  Y8b.                                 ' -ForegroundColor Cyan
    Write-Host '    "Y88888P"   88888P"    "Y88888  "Y888888   "Y888  "Y8888                              ' -ForegroundColor Blue
    Write-Host '                888                                                                       ' -ForegroundColor Cyan
    Write-Host '                888                                                                       ' -ForegroundColor Blue
    Write-Host '                888                                                                       ' -ForegroundColor Cyan
    
    # Rahmen für Systeminformationen
    Write-Host "╔══════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-ColoredCenteredText                          "INFORMATIONEN"                                           
    Write-Host "╠══════════════════════════════════════════════════════════════════════════════╣" -ForegroundColor Green
    # Systeminformationen
    Write-Host "║                                                                              ║" -ForegroundColor Green
    Write-Host "  ├─  System aktuell halten mit Windows Update:                                   "  -ForegroundColor Yellow                 
    Write-Host "  ├─  Installiert Sicherheitsupdates, Fehlerbehebungen und neue Funktionen.       "  -ForegroundColor Yellow                                    
    Write-Host "  ├─  Regelmäßige Updates verbessern Stabilität und Schutz des Systems.           "  -ForegroundColor Yellow                                    
    Write-Host "  └─  Empfohlen für eine sichere und leistungsfähige Windows-Umgebung.            "  -ForegroundColor Yellow                                  
    Write-Host "║                                                                              ║" -ForegroundColor Green
    
    Write-Host "╠══════════════════════════════════════════════════════════════════════════════╣" -ForegroundColor Green
    Write-ColoredCenteredText "Windows Update wird initialisiert..."
    Write-Host "╚══════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Green
    
    # 3 Sekunden warten vor dem Start
    Start-Sleep -Seconds 3

    
    Switch-ToOutputTab
    try {

        # Header für den Scan
        Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Action'
        $outputBox.AppendText("`r`n`t===== Windows Update wird gestartet =====`r`n")
        Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Default'
        $outputBox.AppendText("`t`t`tModus: Scan und Prüfung`r`n")
        Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Default'
        $outputBox.AppendText("`t`tZeitstempel: $(Get-Date -Format 'dd.MM.yyyy HH:mm:ss')`r`n`r`n")
        
        # Windows Update NICHT direkt öffnen - stattdessen nur Status anzeigen
        
    
        Write-ToolLog -ToolName "WindowsUpdate" `
            -Message "[►] Der Update-Status wird geprüft..." `
            -OutputBox $outputBox `
            -Style 'Action' -NoTimestamp

        Write-Host        
        Write-Host "[►] Der Update-Status wird gefrüft... "  -foregroundColor Blue
        
        
        # Progress auf 50% setzen für die Suchphase
        if ($progressBar) {
            $progressBar.Value = 30
            $progressBar.CustomText = "Windows Update wird ausgeführt..."
        }
        # Versuche den Update-Status abzurufen
        try {
            $session = New-Object -ComObject "Microsoft.Update.Session"
            $searcher = $session.CreateUpdateSearcher()
            $pendingCount = $searcher.GetTotalHistoryCount()
            
            # Progress weiter erhöhen, um Fortschritt zu zeigen
            if ($progressBar) {
                $progressBar.Value = 40
                $progressBar.CustomText = "Update-Status wird geprüft..."
            }
        }
        catch {
            Write-ToolLog -ToolName "WindowsUpdate" `
                -Message "[►] Info: Update-Status konnte nicht abgerufen werden." `
                -OutputBox $outputBox `
                -Style 'Warning' -NoTimestamp

            # Bei Fehler: ProgressBar rot einfärben
            if ($progressBar) {
                $progressBar.TextColor = [System.Drawing.Color]::Red
                $progressBar.CustomText = "Fehler beim Abrufen des Update-Status"
            }

            Write-Host
            Write-Host "[!] Info: Update-Status konnte nicht abgerufen werden." -ForegroundColor Yellow
        }
    }
    catch {
        Write-ToolLog -ToolName "WindowsUpdate" `
            -Message "[!] Fehler beim Starten von Windows Update: $_" `
            -OutputBox $outputBox `
            -Style 'Error' -NoTimestamp

        # Bei Fehler: ProgressBar rot einfärben
        if ($progressBar) {
            $progressBar.Value = 100
            $progressBar.TextColor = [System.Drawing.Color]::Red
            $progressBar.CustomText = "Fehler bei Windows Update"
        }

        Write-Host
        Write-Host "[X] Fehler beim Starten von Windows Update: $_" -ForegroundColor Red
    }
}

# Function to check for Windows Updates
function Get-WindowsUpdateStatus {
    param(
        [System.Windows.Forms.RichTextBox]$outputBox,
        [System.Windows.Forms.ProgressBar]$progressBar = $null
    )
    
    try {
        # Progress auf 20% setzen für die Suchphase
        if ($progressBar) {
            $progressBar.Value = 60
            $progressBar.CustomText = "Suche nach Updates..."
            $progressBar.TextColor = [System.Drawing.Color]::White
        }
        
        Write-ToolLog -ToolName "WindowsUpdate" `
            -Message "[►] Suche nach Updates..." `
            -OutputBox $outputBox `
            -Style 'Action' -NoTimestamp
        Write-Host
        Write-Host "[►] Suche nach Updates..." -ForegroundColor Blue

        # Windows Update COM-Objekte erstellen
        $updateSession = New-Object -ComObject Microsoft.Update.Session
        $updateSearcher = $updateSession.CreateUpdateSearcher()
        
        # Suche nach allen verfügbaren Updates
        Write-ToolLog -ToolName "WindowsUpdate" `
            -Message "[►] Prüfe auf verfügbare Updates..." `
            -OutputBox $outputBox -NoTimestamp

        Write-Host
        Write-Host "[►] Prüfe auf verfügbare Updates..." -ForegroundColor Blue   
        
        # Progress auf 30% setzen für die Prüfphase
        if ($progressBar) {
            $progressBar.Value = 70
            $progressBar.CustomText = "Prüfe auf Updates..."
        }
            
        $searchResult = $updateSearcher.Search("IsInstalled=0 AND IsHidden=0")
        
        # Prüfe auf wichtige Updates
        $criticalUpdates = $searchResult.Updates | Where-Object { $_.MsrcSeverity -eq "Critical" }
        $securityUpdates = $searchResult.Updates | Where-Object { $_.Type -eq "Security" }
        $normalUpdates = $searchResult.Updates | Where-Object { $_.MsrcSeverity -ne "Critical" -and $_.Type -ne "Security" }

       

        # Progress auf 40% setzen
        if ($progressBar) {
            $progressBar.Value = 80
            if ($searchResult.Updates.Count -gt 0) {
                $progressBar.CustomText = "$($searchResult.Updates.Count) Updates gefunden"
            }
            else {
                $progressBar.CustomText = "Keine Updates gefunden"
            }
        }
        
        if ($searchResult.Updates.Count -gt 0) {
            Write-ToolLog -ToolName "WindowsUpdate" `
                -Message "$($searchResult.Updates.Count) Updates verfügbar:" `
                -OutputBox $outputBox `
                -Style 'Success' -NoTimestamp
            
            Write-Host
            Write-Host "          ├─ $($searchResult.Updates.Count) Updates verfügbar:" -ForegroundColor Yellow
            Write-Host
            Write-Host "`n" + ("═" * 70) -ForegroundColor Cyan
            # Kritische Updates anzeigen
            if ($criticalUpdates.Count -gt 0) {
                Write-ToolLog -ToolName "WindowsUpdate" `
                    -Message "`nKritische Updates ($($criticalUpdates.Count)):" `
                    -OutputBox $outputBox `
                    -Style 'Error' -NoTimestamp
                foreach ($update in $criticalUpdates) {
                    Write-ToolLog -ToolName "WindowsUpdate" `
                        -Message "- $($update.Title)" `
                        -OutputBox $outputBox -NoTimestamp
                }
            }
            
            # Sicherheitsupdates anzeigen
            if ($securityUpdates.Count -gt 0) {
                Write-ToolLog -ToolName "WindowsUpdate" `
                    -Message "`nSicherheitsupdates ($($securityUpdates.Count)):" `
                    -OutputBox $outputBox `
                    -Style 'Warning' -NoTimestamp
                foreach ($update in $securityUpdates) {
                    Write-ToolLog -ToolName "WindowsUpdate" `
                        -Message "- $($update.Title)" `
                        -OutputBox $outputBox -NoTimestamp
                }
            }
            
            # Normale Updates anzeigen
            if ($normalUpdates.Count -gt 0) {
                Write-ToolLog -ToolName "WindowsUpdate" `
                    -Message "`nOptionale Updates ($($normalUpdates.Count)):" `
                    -OutputBox $outputBox `
                    -Style 'Info' -NoTimestamp
                foreach ($update in $normalUpdates) {
                    Write-ToolLog -ToolName "WindowsUpdate" `
                        -Message "- $($update.Title)" `
                        -OutputBox $outputBox -NoTimestamp
                }
            }

        }
        else {
            Write-ToolLog -ToolName "WindowsUpdate" `
                -Message "Keine Updates verfügbar." `
                -OutputBox $outputBox `
                -Style 'Success' -NoTimestamp
        }
        
        # Windows Update Dienst Status prüfen
        $wuauserv = Get-Service -Name "wuauserv"
        Write-ToolLog -ToolName "WindowsUpdate" `
            -Message "`nWindows Update Dienst Status: $($wuauserv.Status)" `
            -OutputBox $outputBox `
            -Style 'Info' -NoTimestamp
    }
    catch {
        Write-ToolLog -ToolName "WindowsUpdate" `
            -Message "Fehler beim Prüfen auf Updates: $_" `
            -OutputBox $outputBox `
            -Style 'Error' -NoTimestamp
            
        # Versuche mehr Informationen über den Fehler zu sammeln
        try {
            $wuauserv = Get-Service -Name "wuauserv"
            Write-ToolLog -ToolName "WindowsUpdate" `
                -Message "Windows Update Dienst Status: $($wuauserv.Status)" `
                -OutputBox $outputBox `
                -Style 'Warning' -NoTimestamp
                
            if ($wuauserv.Status -ne "Running") {
                Write-ToolLog -ToolName "WindowsUpdate" `
                    -Message "Versuche Windows Update Dienst zu starten..." `
                    -OutputBox $outputBox `
                    -Style 'Warning' -NoTimestamp
                Start-Service -Name "wuauserv"
                Write-ToolLog -ToolName "WindowsUpdate" `
                    -Message "Bitte versuchen Sie die Updatesuche erneut." `
                    -OutputBox $outputBox `
                    -Style 'Success' -NoTimestamp
            }
        }
        catch {
            Write-ToolLog -ToolName "WindowsUpdate" `
                -Message "Zusätzlicher Fehler beim Prüfen des Dienst-Status: $_" `
                -OutputBox $outputBox `
                -Style 'Error' -NoTimestamp
        }
    }
}

function Install-AvailableWindowsUpdates {
    param(
        [System.Windows.Forms.RichTextBox]$outputBox,
        [System.Windows.Forms.ProgressBar]$progressBar = $null
    )
    
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Action'
    $outputBox.AppendText("`r`n===== Windows Updates werden gesucht und installiert =====`r`n")
    
    # Fortschrittsanzeige initialisieren
    if ($progressBar) {
        $progressBar.Value = 50
        $progressBar.CustomText = "Suche nach verfügbaren Updates..."
        $progressBar.TextColor = [System.Drawing.Color]::White
    }
    
    # Prüfe, ob das PSWindowsUpdate-Modul installiert ist
    if (Get-Module -ListAvailable -Name PSWindowsUpdate) {
        Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Success'
        $outputBox.AppendText("PSWindowsUpdate-Modul gefunden. Updates werden gesucht...`r`n")
        
        # Fortschrittsanzeige aktualisieren
        if ($progressBar) {
            $progressBar.Value = 60
            $progressBar.CustomText = "PSWindowsUpdate-Modul gefunden"
        }
        
        Import-Module PSWindowsUpdate -Force
        
        # Fortschrittsanzeige aktualisieren
        if ($progressBar) {
            $progressBar.Value = 70
            $progressBar.CustomText = "Verfügbare Updates werden gesucht..."
        }
        
        $updates = Get-WindowsUpdate -AcceptAll -IgnoreReboot
        if ($updates) {
            Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Action'
            $outputBox.AppendText("Updates werden installiert...`r`n")
            
            # Fortschrittsanzeige aktualisieren
            if ($progressBar) {
                $progressBar.Value = 80
                $progressBar.CustomText = "Updates werden installiert..."
            }
            
            Install-WindowsUpdate -AcceptAll -IgnoreReboot -AutoReboot -Verbose | ForEach-Object {
                Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Default'
                $outputBox.AppendText($_.ToString() + "`r`n")
            }
            
            # Fortschrittsanzeige abschließen
            if ($progressBar) {
                $progressBar.Value = 100
                $progressBar.CustomText = "Alle Updates installiert"
                $progressBar.TextColor = [System.Drawing.Color]::LimeGreen
            }
            
            Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Success'
            $outputBox.AppendText("Alle verfügbaren Updates wurden installiert.`r`n")
        }
        else {
            Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Success'
            $outputBox.AppendText("Keine Updates verfügbar.`r`n")
            
            # Fortschrittsanzeige abschließen
            if ($progressBar) {
                $progressBar.Value = 100
                $progressBar.CustomText = "Keine Updates verfügbar"
                $progressBar.TextColor = [System.Drawing.Color]::LimeGreen
            }
        }
    }
    else {
        Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Warning'
        $outputBox.AppendText("PSWindowsUpdate-Modul nicht gefunden. Verwende Windows Update COM-Objekt...`r`n")
        
        # Fortschrittsanzeige aktualisieren
        if ($progressBar) {
            $progressBar.Value = 60
            $progressBar.CustomText = "Verwende Windows Update COM-Objekt"
            $progressBar.TextColor = [System.Drawing.Color]::Orange
        }
        
        try {
            $updateSession = New-Object -ComObject Microsoft.Update.Session
            $updateSearcher = $updateSession.CreateUpdateSearcher()
            
            # Fortschrittsanzeige aktualisieren
            if ($progressBar) {
                $progressBar.Value = 70
                $progressBar.CustomText = "Suche nach Updates..."
            }
            
            $searchResult = $updateSearcher.Search("IsInstalled=0 AND IsHidden=0")
            if ($searchResult.Updates.Count -gt 0) {
                Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Action'
                $outputBox.AppendText("Updates werden installiert...`r`n")
                
                # Fortschrittsanzeige aktualisieren
                if ($progressBar) {
                    $progressBar.Value = 80
                    $progressBar.CustomText = "Updates werden installiert..."
                }
                
                $updatesToInstall = New-Object -ComObject Microsoft.Update.UpdateColl
                foreach ($update in $searchResult.Updates) {
                    $updatesToInstall.Add($update) | Out-Null
                    $outputBox.AppendText("- " + $update.Title + "  `r`n")
                }
                
                $installer = $updateSession.CreateUpdateInstaller()
                $installer.Updates = $updatesToInstall
                
                # Fortschrittsanzeige aktualisieren
                if ($progressBar) {
                    $progressBar.Value = 90
                    $progressBar.CustomText = "Installiere " + $updatesToInstall.Count + " Updates..."
                }
                
                $result = $installer.Install()
                
                # ResultCode: 0=NotStarted, 1=InProgress, 2=Succeeded, 3=SucceededWithErrors, 4=Failed, 5=Aborted
                $successCount = 0
                $failedCount = 0
                $pendingCount = 0
                
                # Detaillierte Analyse der Update-Ergebnisse
                for ($i = 0; $i -lt $updatesToInstall.Count; $i++) {
                    $updateResult = $result.GetUpdateResult($i)
                    $update = $updatesToInstall.Item($i)
                    
                    switch ($updateResult.ResultCode) {
                        2 { 
                            $successCount++
                            Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Success'
                            $outputBox.AppendText("  ✓ Erfolgreich: $($update.Title)`r`n")
                        }
                        3 { 
                            $successCount++
                            Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Warning'
                            $outputBox.AppendText("  ⚠ Mit Warnungen: $($update.Title)`r`n")
                        }
                        4 { 
                            $failedCount++
                            Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Error'
                            $outputBox.AppendText("  ✗ Fehlgeschlagen: $($update.Title)`r`n")
                            if ($updateResult.HResult) {
                                $hresult = $updateResult.HResult
                                $errorDesc = Get-UpdateErrorDescription -HResult $hresult
                                $outputBox.AppendText("    Fehlercode: 0x$($hresult.ToString('X8')) - $errorDesc`r`n")
                            }
                        }
                        5 { 
                            $failedCount++
                            Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Error'
                            $outputBox.AppendText("  ✗ Abgebrochen: $($update.Title)`r`n")
                        }
                        default {
                            $pendingCount++
                            Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Action'
                            $outputBox.AppendText("  ◷ Ausstehend: $($update.Title)`r`n")
                        }
                    }
                }
                
                # Zusammenfassung
                $outputBox.AppendText("`r`n")
                Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Action'
                $outputBox.AppendText("=== Installationsergebnis ===`r`n")
                
                if ($successCount -gt 0) {
                    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Success'
                    $outputBox.AppendText("✓ Erfolgreich installiert: $successCount`r`n")
                }
                if ($failedCount -gt 0) {
                    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Error'
                    $outputBox.AppendText("✗ Fehlgeschlagen: $failedCount`r`n")
                }
                if ($pendingCount -gt 0) {
                    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Action'
                    $outputBox.AppendText("◷ Ausstehend: $pendingCount`r`n")
                }
                
                # Neustart-Empfehlung prüfen
                if ($result.RebootRequired) {
                    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Warning'
                    $outputBox.AppendText("`r`n⚠ Ein Neustart ist erforderlich, um die Installation abzuschließen.`r`n")
                }
                
                # Fortschrittsanzeige und Status aktualisieren
                if ($result.ResultCode -eq 2) {
                    if ($progressBar) {
                        $progressBar.Value = 100
                        $progressBar.CustomText = "Alle Updates erfolgreich installiert"
                        $progressBar.TextColor = [System.Drawing.Color]::LimeGreen
                    }
                    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Success'
                    $outputBox.AppendText("`r`nAlle Updates wurden erfolgreich installiert.`r`n")
                }
                elseif ($result.ResultCode -eq 3) {
                    if ($progressBar) {
                        $progressBar.Value = 100
                        $progressBar.CustomText = "Updates installiert (mit Warnungen)"
                        $progressBar.TextColor = [System.Drawing.Color]::Orange
                    }
                    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Warning'
                    $outputBox.AppendText("`r`nUpdates wurden installiert, aber es gab Warnungen.`r`n")
                }
                else {
                    if ($progressBar) {
                        $progressBar.Value = 100
                        if ($failedCount -gt 0) {
                            $progressBar.CustomText = "$failedCount Update(s) fehlgeschlagen"
                        } else {
                            $progressBar.CustomText = "Installation unvollständig"
                        }
                        $progressBar.TextColor = [System.Drawing.Color]::Red
                    }
                    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Error'
                    if ($failedCount -gt 0) {
                        $outputBox.AppendText("`r`n$failedCount Update(s) konnten nicht installiert werden.`r`n")
                        Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Error'
                        $outputBox.AppendText("`r`nMögliche Gründe für fehlgeschlagene Updates:`r`n")
                        Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Default'
                        $outputBox.AppendText("  • Nicht genügend Speicherplatz verfügbar`r`n")
                        Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Default'
                        $outputBox.AppendText("  • Beschädigte Update-Komponenten (DISM/SFC könnte helfen)`r`n")
                        Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Default'
                        $outputBox.AppendText("  • Netzwerkprobleme beim Download`r`n")
                        Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Default'
                        $outputBox.AppendText("  • Inkompatible Updates oder fehlende Voraussetzungen`r`n")
                        Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Default'
                        $outputBox.AppendText("  • Windows Update Dienst hat Probleme`r`n")
                        Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Warning'
                        $outputBox.AppendText("`r`nEmpfehlung: Führen Sie DISM-Tools aus oder starten Sie neu und versuchen Sie es erneut.`r`n")
                    } else {
                        $outputBox.AppendText("`r`nDie Update-Installation war nicht vollständig erfolgreich.`r`n")
                    }
                }
            }
            else {
                # Fortschrittsanzeige aktualisieren
                if ($progressBar) {
                    $progressBar.Value = 100
                    $progressBar.CustomText = "Keine Updates verfügbar"
                    $progressBar.TextColor = [System.Drawing.Color]::LimeGreen
                }
                
                Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Success'
                $outputBox.AppendText("Keine Updates verfügbar.`r`n")
            }
        }
        catch {
            # Fortschrittsanzeige aktualisieren
            if ($progressBar) {
                $progressBar.Value = 100
                $progressBar.CustomText = "Fehler beim Installieren der Updates"
                $progressBar.TextColor = [System.Drawing.Color]::Red
            }
            
            Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Error'
            $outputBox.AppendText("Fehler beim Installieren der Updates: $_`r`n")
            
            # Zusätzliche Fehlerinformationen versuchen zu sammeln
            try {
                $wuauserv = Get-Service -Name "wuauserv"
                Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Warning'
                $outputBox.AppendText("Windows Update Dienst Status: $($wuauserv.Status)`r`n")
                
                if ($wuauserv.Status -ne "Running") {
                    $outputBox.AppendText("Versuche Windows Update Dienst zu starten...`r`n")
                    Start-Service -Name "wuauserv"
                    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Success'
                    $outputBox.AppendText("Bitte versuchen Sie die Updatesuche erneut.`r`n")
                }
            }
            catch {
                Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Error'
                $outputBox.AppendText("Zusätzlicher Fehler beim Prüfen des Update-Dienstes: $_`r`n")
            }
        }
    }
    
    # Abschluss-Meldung am Ende hinzufügen, unabhängig vom Pfad
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Success'
    $outputBox.AppendText("`r`n=== Windows Update-Prozess abgeschlossen ===`r`n")
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Success'
    $outputBox.AppendText("Fertig!`r`n")
    
    # Stelle sicher, dass am Ende die ProgressBar auf 100% ist
    if ($progressBar) {
        $progressBar.Value = 100
        if ($progressBar.TextColor -ne [System.Drawing.Color]::Red) {
            $progressBar.TextColor = [System.Drawing.Color]::LimeGreen
            $progressBar.CustomText = "Windows Update abgeschlossen"
        }
    }
}

# Export functions
Export-ModuleMember -Function Start-WindowsUpdate, Get-WindowsUpdateStatus, Install-AvailableWindowsUpdates


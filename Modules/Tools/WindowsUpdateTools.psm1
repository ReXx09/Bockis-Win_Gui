# Import required modules
Import-Module "$PSScriptRoot\..\Core\Core.psm1" -Force

# Add Windows Update configuration to SystemToolConfig
$Global:SystemToolConfig.Tools["WindowsUpdate"] = @{
    RequiresAdmin = $true
    Timeout       = 300
    Description   = "Windows Update"
}

# Function to start Windows Update and show status
function Start-WindowsUpdate {
    param(
        [System.Windows.Forms.RichTextBox]$outputBox,
        [System.Windows.Forms.TabControl]$TabControl,
        [System.Windows.Forms.ProgressBar]$progressBar = $null,
        [System.Windows.Forms.Form]$MainForm = $null
    )
    # outputBox zuruecksetzen
    $outputBox.Clear()

    # ProgressBar initialisieren, wenn vorhanden
    if ($progressBar) {
        $progressBar.Value = 10
        $progressBar.CustomText = "Windows Update wird initialisiert..."
        $progressBar.TextColor = [System.Drawing.Color]::DarkBlue
    }

    Clear-Host
    
    # Rahmen und Systeminformationen erstellen
    $computerName = $env:COMPUTERNAME
    $userName = $env:USERNAME
    $osInfo = (Get-CimInstance -ClassName Win32_OperatingSystem).Caption
    $dateTime = Get-Date -Format "dd.MM.yyyy HH:mm:ss"
    $width = 80

        
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
    Write-ColoredCenteredText                          "SYSTEMINFORMATIONEN"                                           
    Write-Host "╠══════════════════════════════════════════════════════════════════════════════╣" -ForegroundColor Green
    # Systeminformationen
    Write-Host "║                                                                              ║" -ForegroundColor Green
    Write-Host "      ├─    Betriebssystem: $osInfo           "            -ForegroundColor Yellow                 
    Write-Host "      ├─    Computer:       $computerName     "            -ForegroundColor Yellow                                    
    Write-Host "      ├─    Benutzer:       $userName         "            -ForegroundColor Yellow                                    
    Write-Host "      └─    Datum und Zeit: $dateTime         "            -ForegroundColor Yellow                                  
    Write-Host "║                                                                              ║" -ForegroundColor Green
    
    Write-Host "╠══════════════════════════════════════════════════════════════════════════════╣" -ForegroundColor Green
    Write-ColoredCenteredText "Windows Update wird initialisiert..."
    Write-Host "╚══════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Green
    
    # 3 Sekunden warten vor dem Start
    Start-Sleep -Seconds 3

    
    Switch-ToOutputTab -TabControl $TabControl
    try {

        # Header für den Scan
        $outputBox.SelectionColor = [System.Drawing.Color]::DarkBlue
        $outputBox.AppendText("`r`n`t===== Windows Update wird gestartet =====`r`n")
        $outputBox.AppendText("`t`t`tModus: Scan und Prüfung`r`n")
        $outputBox.AppendText("`t`tZeitstempel: $(Get-Date -Format 'dd.MM.yyyy HH:mm:ss')`r`n`r`n")
        
        # Windows Update NICHT direkt öffnen - stattdessen nur Status anzeigen
        
        Write-ToolLog -ToolName "WindowsUpdate" `
            -Message "[i] Windows Update wurde in den Einstellungen geöffnet." `
            -OutputBox $outputBox `
            -Color ([System.Drawing.Color]::Green) -NoTimestamp
        
        Write-Host
        Write-Host "[i] Windows Update wird in den Einstellungen geöffnet" -ForegroundColor Green  

        Write-ToolLog -ToolName "WindowsUpdate" `
            -Message "[i] Bitte folgen Sie den Anweisungen in der Windows-Update-Seite,`r`n`tum Updates zu suchen und zu installieren." `
            -OutputBox $outputBox `
            -Color ([System.Drawing.Color]::Blue) -NoTimestamp

        Write-Host        
        Write-Host "[i] Bitte folgen Sie den Anweisungen in der Windows-Update-Seite, "  -foregroundColor Green
        Write-Host "    um Updates zu suchen und zu installieren."  -foregroundColor Green
        
        # Progress auf 50% setzen für die Suchphase
        if ($progressBar) {
            $progressBar.Value = 50
            $progressBar.CustomText = "Windows Update wird ausgeführt..."
        }
        # Versuche den Update-Status abzurufen
        try {
            $session = New-Object -ComObject "Microsoft.Update.Session"
            $searcher = $session.CreateUpdateSearcher()
            $pendingCount = $searcher.GetTotalHistoryCount()
            
            # Progress weiter erhöhen, um Fortschritt zu zeigen
            if ($progressBar) {
                $progressBar.Value = 60
                $progressBar.CustomText = "Update-Status wird geprüft..."
            }
        }
        catch {
            Write-ToolLog -ToolName "WindowsUpdate" `
                -Message "[i] Info: Update-Status konnte nicht abgerufen werden." `
                -OutputBox $outputBox `
                -Color ([System.Drawing.Color]::Yellow) -NoTimestamp

            # Bei Fehler: ProgressBar rot einfärben
            if ($progressBar) {
                $progressBar.TextColor = [System.Drawing.Color]::Red
                $progressBar.CustomText = "Fehler beim Abrufen des Update-Status"
            }

            Write-Host
            Write-Host "[i] Info: Update-Status konnte nicht abgerufen werden." -ForegroundColor Red
        }
    }
    catch {
        Write-ToolLog -ToolName "WindowsUpdate" `
            -Message "[!] Fehler beim Starten von Windows Update: $_" `
            -OutputBox $outputBox `
            -Color ([System.Drawing.Color]::Red) -NoTimestamp

        # Bei Fehler: ProgressBar rot einfärben
        if ($progressBar) {
            $progressBar.Value = 100
            $progressBar.TextColor = [System.Drawing.Color]::Red
            $progressBar.CustomText = "Fehler bei Windows Update"
        }

        Write-Host
        Write-Host "[>] Fehler beim Starten von Windows Update: $_" -ForegroundColor Red
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
            $progressBar.Value = 20
            $progressBar.CustomText = "Suche nach Updates..."
            $progressBar.TextColor = [System.Drawing.Color]::DarkBlue
        }
        
        Write-ToolLog -ToolName "WindowsUpdate" `
            -Message "[>] Suche nach Updates..." `
            -OutputBox $outputBox `
            -Color ([System.Drawing.Color]::Blue) -NoTimestamp
        Write-Host
        Write-Host "[>] Suche nach Updates..." -ForegroundColor Yellow

        # Windows Update COM-Objekte erstellen
        $updateSession = New-Object -ComObject Microsoft.Update.Session
        $updateSearcher = $updateSession.CreateUpdateSearcher()
        
        # Suche nach allen verfügbaren Updates
        Write-ToolLog -ToolName "WindowsUpdate" `
            -Message "[>] Prüfe auf verfügbare Updates..." `
            -OutputBox $outputBox -NoTimestamp

        Write-Host
        Write-Host "[>] Prüfe auf verfügbare Updates..." -ForegroundColor Yellow   
        
        # Progress auf 30% setzen für die Prüfphase
        if ($progressBar) {
            $progressBar.Value = 30
            $progressBar.CustomText = "Prüfe auf Updates..."
        }
            
        $searchResult = $updateSearcher.Search("IsInstalled=0 AND IsHidden=0")
        
        # Prüfe auf wichtige Updates
        $criticalUpdates = $searchResult.Updates | Where-Object { $_.MsrcSeverity -eq "Critical" }
        $securityUpdates = $searchResult.Updates | Where-Object { $_.Type -eq "Security" }
        $normalUpdates = $searchResult.Updates | Where-Object { $_.MsrcSeverity -ne "Critical" -and $_.Type -ne "Security" }
        
        # Progress auf 40% setzen
        if ($progressBar) {
            $progressBar.Value = 40
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
                -Color ([System.Drawing.Color]::Green) -NoTimestamp
            
            Write-Host
            Write-Host "          ├─ $($searchResult.Updates.Count) Updates verfügbar:" -ForegroundColor Yellow
            Write-Host

            # Kritische Updates anzeigen
            if ($criticalUpdates.Count -gt 0) {
                Write-ToolLog -ToolName "WindowsUpdate" `
                    -Message "`nKritische Updates ($($criticalUpdates.Count)):" `
                    -OutputBox $outputBox `
                    -Color ([System.Drawing.Color]::Red) -NoTimestamp
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
                    -Color ([System.Drawing.Color]::Orange) -NoTimestamp
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
                    -Color ([System.Drawing.Color]::Blue) -NoTimestamp
                foreach ($update in $normalUpdates) {
                    Write-ToolLog -ToolName "WindowsUpdate" `
                        -Message "- $($update.Title)" `
                        -OutputBox $outputBox -NoTimestamp
                }
            }

            # Update-Historie wurde entfernt - nicht mehr anzeigen

        }
        else {
            Write-ToolLog -ToolName "WindowsUpdate" `
                -Message "Keine Updates verfügbar." `
                -OutputBox $outputBox `
                -Color ([System.Drawing.Color]::Green) -NoTimestamp
        }
        
        # Windows Update Dienst Status prüfen
        $wuauserv = Get-Service -Name "wuauserv"
        Write-ToolLog -ToolName "WindowsUpdate" `
            -Message "`nWindows Update Dienst Status: $($wuauserv.Status)" `
            -OutputBox $outputBox `
            -Color ([System.Drawing.Color]::Blue) -NoTimestamp
    }
    catch {
        Write-ToolLog -ToolName "WindowsUpdate" `
            -Message "Fehler beim Prüfen auf Updates: $_" `
            -OutputBox $outputBox `
            -Color ([System.Drawing.Color]::Red) -NoTimestamp
            
        # Versuche mehr Informationen über den Fehler zu sammeln
        try {
            $wuauserv = Get-Service -Name "wuauserv"
            Write-ToolLog -ToolName "WindowsUpdate" `
                -Message "Windows Update Dienst Status: $($wuauserv.Status)" `
                -OutputBox $outputBox `
                -Color ([System.Drawing.Color]::Yellow) -NoTimestamp
                
            if ($wuauserv.Status -ne "Running") {
                Write-ToolLog -ToolName "WindowsUpdate" `
                    -Message "Versuche Windows Update Dienst zu starten..." `
                    -OutputBox $outputBox `
                    -Color ([System.Drawing.Color]::Yellow) -NoTimestamp
                Start-Service -Name "wuauserv"
                Write-ToolLog -ToolName "WindowsUpdate" `
                    -Message "Bitte versuchen Sie die Updatesuche erneut." `
                    -OutputBox $outputBox `
                    -Color ([System.Drawing.Color]::Green) -NoTimestamp
            }
        }
        catch {
            Write-ToolLog -ToolName "WindowsUpdate" `
                -Message "Zusätzlicher Fehler beim Prüfen des Dienst-Status: $_" `
                -OutputBox $outputBox `
                -Color ([System.Drawing.Color]::Red) -NoTimestamp
        }
    }
}

function Install-AvailableWindowsUpdates {
    param(
        [System.Windows.Forms.RichTextBox]$outputBox,
        [System.Windows.Forms.ProgressBar]$progressBar = $null
    )
    
    $outputBox.SelectionColor = [System.Drawing.Color]::DarkBlue
    $outputBox.AppendText("`r`n===== Windows Updates werden gesucht und installiert =====`r`n")
    
    # Fortschrittsanzeige initialisieren
    if ($progressBar) {
        $progressBar.Value = 50
        $progressBar.CustomText = "Suche nach verfügbaren Updates..."
        $progressBar.TextColor = [System.Drawing.Color]::DarkBlue
    }
    
    # Prüfe, ob das PSWindowsUpdate-Modul installiert ist
    if (Get-Module -ListAvailable -Name PSWindowsUpdate) {
        $outputBox.SelectionColor = [System.Drawing.Color]::Green
        $outputBox.AppendText("PSWindowsUpdate-Modul gefunden. Updates werden gesucht...\r\n")
        
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
            $outputBox.SelectionColor = [System.Drawing.Color]::Blue
            $outputBox.AppendText("Updates werden installiert...\r\n")
            
            # Fortschrittsanzeige aktualisieren
            if ($progressBar) {
                $progressBar.Value = 80
                $progressBar.CustomText = "Updates werden installiert..."
            }
            
            Install-WindowsUpdate -AcceptAll -IgnoreReboot -AutoReboot -Verbose | ForEach-Object {
                $outputBox.SelectionColor = [System.Drawing.Color]::Black
                $outputBox.AppendText($_.ToString() + "\r\n")
            }
            
            # Fortschrittsanzeige abschließen
            if ($progressBar) {
                $progressBar.Value = 100
                $progressBar.CustomText = "Alle Updates installiert"
                $progressBar.TextColor = [System.Drawing.Color]::Green
            }
            
            $outputBox.SelectionColor = [System.Drawing.Color]::Green
            $outputBox.AppendText("Alle verfügbaren Updates wurden installiert.\r\n")
        }
        else {
            $outputBox.SelectionColor = [System.Drawing.Color]::Green
            $outputBox.AppendText("Keine Updates verfügbar.\r\n")
            
            # Fortschrittsanzeige abschließen
            if ($progressBar) {
                $progressBar.Value = 100
                $progressBar.CustomText = "Keine Updates verfügbar"
                $progressBar.TextColor = [System.Drawing.Color]::Green
            }
        }
    }
    else {
        $outputBox.SelectionColor = [System.Drawing.Color]::Orange
        $outputBox.AppendText("PSWindowsUpdate-Modul nicht gefunden. Verwende Windows Update COM-Objekt...\r\n")
        
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
                $outputBox.SelectionColor = [System.Drawing.Color]::Blue
                $outputBox.AppendText("Updates werden installiert...\r\n")
                
                # Fortschrittsanzeige aktualisieren
                if ($progressBar) {
                    $progressBar.Value = 80
                    $progressBar.CustomText = "Updates werden installiert..."
                }
                
                $updatesToInstall = New-Object -ComObject Microsoft.Update.UpdateColl
                foreach ($update in $searchResult.Updates) {
                    $updatesToInstall.Add($update) | Out-Null
                    $outputBox.AppendText("- " + $update.Title + "\r\n")
                }
                
                $installer = $updateSession.CreateUpdateInstaller()
                $installer.Updates = $updatesToInstall
                
                # Fortschrittsanzeige aktualisieren
                if ($progressBar) {
                    $progressBar.Value = 90
                    $progressBar.CustomText = "Installiere " + $updatesToInstall.Count + " Updates..."
                }
                
                $result = $installer.Install()
                
                if ($result.ResultCode -eq 2) {
                    # Fortschrittsanzeige aktualisieren
                    if ($progressBar) {
                        $progressBar.Value = 100
                        $progressBar.CustomText = "Updates erfolgreich installiert"
                        $progressBar.TextColor = [System.Drawing.Color]::Green
                    }
                    
                    $outputBox.SelectionColor = [System.Drawing.Color]::Green
                    $outputBox.AppendText("Alle Updates wurden erfolgreich installiert.\r\n")
                }
                else {
                    # Fortschrittsanzeige aktualisieren
                    if ($progressBar) {
                        $progressBar.Value = 100
                        $progressBar.CustomText = "Einige Updates konnten nicht installiert werden"
                        $progressBar.TextColor = [System.Drawing.Color]::Red
                    }
                    
                    $outputBox.SelectionColor = [System.Drawing.Color]::Red
                    $outputBox.AppendText("Einige Updates konnten nicht installiert werden.\r\n")
                }
            }
            else {
                # Fortschrittsanzeige aktualisieren
                if ($progressBar) {
                    $progressBar.Value = 100
                    $progressBar.CustomText = "Keine Updates verfügbar"
                    $progressBar.TextColor = [System.Drawing.Color]::Green
                }
                
                $outputBox.SelectionColor = [System.Drawing.Color]::Green
                $outputBox.AppendText("Keine Updates verfügbar.\r\n")
            }
        }
        catch {
            # Fortschrittsanzeige aktualisieren
            if ($progressBar) {
                $progressBar.Value = 100
                $progressBar.CustomText = "Fehler beim Installieren der Updates"
                $progressBar.TextColor = [System.Drawing.Color]::Red
            }
            
            $outputBox.SelectionColor = [System.Drawing.Color]::Red
            $outputBox.AppendText("Fehler beim Installieren der Updates: $_\r\n")
            
            # Zusätzliche Fehlerinformationen versuchen zu sammeln
            try {
                $wuauserv = Get-Service -Name "wuauserv"
                $outputBox.SelectionColor = [System.Drawing.Color]::Yellow
                $outputBox.AppendText("Windows Update Dienst Status: $($wuauserv.Status)\r\n")
                
                if ($wuauserv.Status -ne "Running") {
                    $outputBox.AppendText("Versuche Windows Update Dienst zu starten...\r\n")
                    Start-Service -Name "wuauserv"
                    $outputBox.SelectionColor = [System.Drawing.Color]::Green
                    $outputBox.AppendText("Bitte versuchen Sie die Updatesuche erneut.\r\n")
                }
            }
            catch {
                $outputBox.SelectionColor = [System.Drawing.Color]::Red
                $outputBox.AppendText("Zusätzlicher Fehler beim Prüfen des Update-Dienstes: $_\r\n")
            }
        }
    }
    
    # Abschluss-Meldung am Ende hinzufügen, unabhängig vom Pfad
    $outputBox.SelectionColor = [System.Drawing.Color]::Green
    $outputBox.AppendText("\r\n=== Windows Update-Prozess abgeschlossen ===\r\n")
    $outputBox.AppendText("Fertig!\r\n")
    
    # Stelle sicher, dass am Ende die ProgressBar auf 100% ist
    if ($progressBar) {
        $progressBar.Value = 100
        if ($progressBar.TextColor -ne [System.Drawing.Color]::Red) {
            $progressBar.TextColor = [System.Drawing.Color]::Green
            $progressBar.CustomText = "Windows Update abgeschlossen"
        }
    }
}

# Export functions
Export-ModuleMember -Function Start-WindowsUpdate, Get-WindowsUpdateStatus, Install-AvailableWindowsUpdates
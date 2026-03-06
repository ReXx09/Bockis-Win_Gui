# Import required modules
Import-Module "$PSScriptRoot\..\Core\Core.psm1" -Force -Global
Import-Module "$PSScriptRoot\..\Core\TextStyle.psm1" -Force -Global

# Add Windows Update configuration to SystemToolConfig
$Global:SystemToolConfig.Tools["WindowsUpdate"] = @{
    RequiresAdmin = $true
    Timeout       = 1800   # 30 Minuten - Updates können länger dauern
    Description   = "Windows Update"
}

# Hilfsfunktion zur Interpretation von Update-Fehlercodes
function Get-UpdateErrorDescription {
    # [long] verwenden, da HRESULT-Werte > 0x7FFFFFFF als [int64] in der Hashtabelle gespeichert werden
    param([long]$HResult)
    
    # Negative Werte (signed Int32) in ihren unsigned Äquivalent umrechnen (z.B. -2145804281 → 0x80246007)
    if ($HResult -lt 0) {
        $HResult = [long][uint32]$HResult
    }
    
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
        # Häufige Download- und Netzwerk-Fehlercodes
        0x80246007 = "BITS-Download fehlgeschlagen / Update-Datenbank beschädigt (wuauclt.exe /resetauthorization empfohlen)"
        0x80246008 = "SusClientId ungültig - Windows Update Agent muss registriert werden"
        0x8024402C = "DNS-Fehler beim Verbinden zu Windows Update"
        0x8024402F = "Proxy-Authentifizierung fehlgeschlagen"
        0x80072EFD = "Internetverbindung unterbrochen oder Timeout"
        0x80072EFE = "Verbindung wurde unerwartet getrennt"
        0x80072F8F = "SSL/TLS-Zertifikatsfehler (Systemuhr prüfen)"
        0x80072EE2 = "Verbindungs-Timeout - Server nicht erreichbar"
        0x80072EE7 = "Server konnte nicht gefunden werden"
        0x80248015 = "Update abgelaufen oder nicht mehr verfügbar"
        0x80240034 = "Fehler bei der Update-Suche - Cache neu aufbauen empfohlen"
        0x80240017 = "Update nicht anwendbar (Systemvoraussetzungen nicht erfüllt)"
        0x8024D009 = "Windows Update Agent konnte nicht gestartet werden"
        0x80070422 = "Windows Update-Dienst ist deaktiviert"
        0x80070BC9 = "Neustart für vorherige Update-Installation ausstehend"
        0xC1900101 = "Treiber-Inkompatibilität verhindert Installation"
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
        
        # Prüfe auf wichtige Updates – @() sichert Array-Verhalten bei einzelnem COM-Objekt
        # IUpdate.Type: 1 = Software, 2 = Driver (kein "Security"-String!)
        # MsrcSeverity: "Critical", "Important", "Moderate", "Low", $null/$empty für Treiber
        $criticalUpdates = @($searchResult.Updates | Where-Object { $_.MsrcSeverity -eq "Critical" })
        $securityUpdates = @($searchResult.Updates | Where-Object { $_.MsrcSeverity -eq "Important" -or $_.MsrcSeverity -eq "Moderate" -or $_.MsrcSeverity -eq "Low" })
        $driverUpdates   = @($searchResult.Updates | Where-Object { $_.Type -eq 2 })
        $normalUpdates   = @($searchResult.Updates | Where-Object { 
            $_.MsrcSeverity -ne "Critical" -and
            $_.MsrcSeverity -ne "Important" -and
            $_.MsrcSeverity -ne "Moderate" -and
            $_.MsrcSeverity -ne "Low" -and
            $_.Type -ne 2
        })

       

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
            Write-Host ("  " + ("═" * 68)) -ForegroundColor Cyan

            # Kritische Updates anzeigen
            if ($criticalUpdates.Count -gt 0) {
                Write-ToolLog -ToolName "WindowsUpdate" `
                    -Message "`nKritische Updates ($($criticalUpdates.Count)):" `
                    -OutputBox $outputBox `
                    -Style 'Error' -NoTimestamp
                Write-Host
                Write-Host "  [!] Kritische Updates ($($criticalUpdates.Count)):" -ForegroundColor Red
                foreach ($update in $criticalUpdates) {
                    Write-ToolLog -ToolName "WindowsUpdate" `
                        -Message "- $($update.Title)" `
                        -OutputBox $outputBox -NoTimestamp
                    Write-Host "      ├─ $($update.Title)" -ForegroundColor Red
                }
            }
            
            # Sicherheitsupdates anzeigen (Important / Moderate / Low)
            if ($securityUpdates.Count -gt 0) {
                Write-ToolLog -ToolName "WindowsUpdate" `
                    -Message "`nSicherheitsupdates ($($securityUpdates.Count)):" `
                    -OutputBox $outputBox `
                    -Style 'Warning' -NoTimestamp
                Write-Host
                Write-Host "  [►] Sicherheitsupdates ($($securityUpdates.Count)):" -ForegroundColor Yellow
                foreach ($update in $securityUpdates) {
                    Write-ToolLog -ToolName "WindowsUpdate" `
                        -Message "- $($update.Title)" `
                        -OutputBox $outputBox -NoTimestamp
                    Write-Host "      ├─ $($update.Title)" -ForegroundColor Yellow
                }
            }

            # Treiber-Updates anzeigen
            if ($driverUpdates.Count -gt 0) {
                Write-ToolLog -ToolName "WindowsUpdate" `
                    -Message "`nTreiber-Updates ($($driverUpdates.Count)):" `
                    -OutputBox $outputBox `
                    -Style 'Info' -NoTimestamp
                Write-Host
                Write-Host "  [D] Treiber-Updates ($($driverUpdates.Count)):" -ForegroundColor Cyan
                foreach ($update in $driverUpdates) {
                    Write-ToolLog -ToolName "WindowsUpdate" `
                        -Message "- $($update.Title)" `
                        -OutputBox $outputBox -NoTimestamp
                    Write-Host "      ├─ $($update.Title)" -ForegroundColor Cyan
                }
            }
            
            # Optionale / sonstige Updates anzeigen
            if ($normalUpdates.Count -gt 0) {
                Write-ToolLog -ToolName "WindowsUpdate" `
                    -Message "`nOptionale Updates ($($normalUpdates.Count)):" `
                    -OutputBox $outputBox `
                    -Style 'Info' -NoTimestamp
                Write-Host
                Write-Host "  [i] Optionale Updates ($($normalUpdates.Count)):" -ForegroundColor Gray
                foreach ($update in $normalUpdates) {
                    Write-ToolLog -ToolName "WindowsUpdate" `
                        -Message "- $($update.Title)" `
                        -OutputBox $outputBox -NoTimestamp
                    Write-Host "      ├─ $($update.Title)" -ForegroundColor Gray
                }
            }

            Write-Host ("  " + ("═" * 68)) -ForegroundColor Cyan

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
        
        # Hinweis zur optionalen PSWindowsUpdate-Installation
        Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Default'
        $outputBox.AppendText("  Tipp: Für erweiterte Update-Steuerung können Sie PSWindowsUpdate installieren:`r`n")
        $outputBox.AppendText("        Install-Module PSWindowsUpdate -Force (Als Administrator in PowerShell)`r`n`r`n")
        
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
                    if ($update.EulaAccepted -eq $false) {
                        $update.AcceptEula()
                    }
                    $updatesToInstall.Add($update) | Out-Null
                    $outputBox.AppendText("- " + $update.Title + "  `r`n")
                }
                
                # ── Download-Phase (getrennt von Installation) ──────────────────
                Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Action'
                $outputBox.AppendText("`r`nUpdates werden heruntergeladen...`r`n")
                if ($progressBar) {
                    $progressBar.Value = 83
                    $progressBar.CustomText = "Updates werden heruntergeladen..."
                }
                
                $downloader = $updateSession.CreateUpdateDownloader()
                $downloader.Updates = $updatesToInstall
                try {
                    $downloadResult = $downloader.Download()
                    if ($downloadResult.ResultCode -ne 2) {
                        Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Warning'
                        $outputBox.AppendText("Warnung: Download möglicherweise unvollständig (ResultCode: $($downloadResult.ResultCode))`r`n")
                        $outputBox.AppendText("  → Prüfen Sie die Internetverbindung, den BITS-Dienst und den Speicherplatz.`r`n")
                    } else {
                        Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Success'
                        $outputBox.AppendText("Download abgeschlossen.`r`n")
                    }
                } catch {
                    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Warning'
                    $outputBox.AppendText("Download-Fehler: $_`r`n")
                    $outputBox.AppendText("Installationsversuch wird trotzdem gestartet...`r`n")
                }
                # ────────────────────────────────────────────────────────────────
                
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
                            if ($updateResult.HResult -ne 0) {
                                $hresult = $updateResult.HResult
                                # Als UInt32 für lesbare Hex-Darstellung, als long für den Lookup
                                $hresultUInt  = [uint32]$hresult
                                $hresultLong  = [long]$hresultUInt
                                $errorDesc = Get-UpdateErrorDescription -HResult $hresultLong
                                $outputBox.AppendText("    Fehlercode: 0x$($hresultUInt.ToString('X8')) - $errorDesc`r`n")
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
                # Individuelle Zähler haben Vorrang vor dem Gesamt-ResultCode
                if ($failedCount -eq 0 -and $successCount -gt 0) {
                    if ($progressBar) {
                        $progressBar.Value = 100
                        $progressBar.CustomText = "Alle Updates erfolgreich installiert"
                        $progressBar.TextColor = [System.Drawing.Color]::LimeGreen
                    }
                    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Success'
                    $outputBox.AppendText("`r`nAlle Updates wurden erfolgreich installiert.`r`n")
                }
                elseif ($failedCount -gt 0 -and $successCount -gt 0) {
                    if ($progressBar) {
                        $progressBar.Value = 100
                        $progressBar.CustomText = "$successCount OK / $failedCount fehlgeschlagen"
                        $progressBar.TextColor = [System.Drawing.Color]::Orange
                    }
                    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Warning'
                    $outputBox.AppendText("`r`n$successCount Update(s) installiert, $failedCount fehlgeschlagen.`r`n")
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


# SIG # Begin signature block
# MIIcSgYJKoZIhvcNAQcCoIIcOzCCHDcCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCA5/5w2ReNlm0EW
# 9u+8Yq5tz8/DjvuZ7YJ74R1gf3NFMqCCFnowggM8MIICJKADAgECAhBJfyGrXBJT
# oUbCYkBRRxacMA0GCSqGSIb3DQEBCwUAMDYxCzAJBgNVBAYTAkRFMQ4wDAYDVQQK
# DAVCb2NraTEXMBUGA1UEAwwOQm9ja2kgU29mdHdhcmUwHhcNMjYwMTIwMTc0NjIy
# WhcNMzEwMTIwMTc1NjIyWjA2MQswCQYDVQQGEwJERTEOMAwGA1UECgwFQm9ja2kx
# FzAVBgNVBAMMDkJvY2tpIFNvZnR3YXJlMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8A
# MIIBCgKCAQEAoQtPttwj/HfLCMp+5pqQOYHtAsyMU7eKVIdtkrEaISn8wKZQqEQL
# E4iGdIVsDmaoIns790Lt3Uw/2xnXy2y3/X2dXBypkjoF5346p79Fb9hNAs103lzk
# NPgxkSkkGpmXERWTeik64eUq3u0TjTivFgFMIwOJUorSkIwzUh/iLQZeCihuRIZL
# eubl7OdiPl4yPb2SlLdhSErXSkhHPSsu6U6j/MJvvBNRkF3uF7B+lLPvW9I/hfAF
# R1UEyAoX+l91AKtjac32OzZH2/Wj2ezoa4PliyzLox7Pjn642pvd/cU+LKWwl4Fm
# iu8c03rafk3Ykpp05QJcCWiy2aExG20xTQIDAQABo0YwRDAOBgNVHQ8BAf8EBAMC
# B4AwEwYDVR0lBAwwCgYIKwYBBQUHAwMwHQYDVR0OBBYEFPiUIYSngqXUa7A3vbjR
# 0PXonIvMMA0GCSqGSIb3DQEBCwUAA4IBAQBMzmWw9+P7IV7xla88buo++WjtigRK
# 5YaY7K1yyn1bml6Hd2uWaF1ptfUuUnDPDyQr9eFrrHkK4qwhx5k2X4spjzLjhPf+
# MPWLjN5ZudKwgQhTjSrcUAsi0Qi5LopPAKNjP3yDclEtJJh3/L0gmhkfu4AIbUin
# IRCHy8WcPWO1jgp4FzkoVkxeuwe2X8WIsjUSooi3qlYqxBK8amlTRUCSmtMpcif5
# 1Ew1KoiOV2cC/tzcHs1clkmJQvZ6Urwc1PbIbHKDYy0l4N5/4epycum4Ijq3fkBf
# BN3AfKchZw6j+iCInCimjmdgwb6vYPCru6/4fdBt5BCRy0SjBmi5MMpFMIIFjTCC
# BHWgAwIBAgIQDpsYjvnQLefv21DiCEAYWjANBgkqhkiG9w0BAQwFADBlMQswCQYD
# VQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGln
# aWNlcnQuY29tMSQwIgYDVQQDExtEaWdpQ2VydCBBc3N1cmVkIElEIFJvb3QgQ0Ew
# HhcNMjIwODAxMDAwMDAwWhcNMzExMTA5MjM1OTU5WjBiMQswCQYDVQQGEwJVUzEV
# MBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNlcnQuY29t
# MSEwHwYDVQQDExhEaWdpQ2VydCBUcnVzdGVkIFJvb3QgRzQwggIiMA0GCSqGSIb3
# DQEBAQUAA4ICDwAwggIKAoICAQC/5pBzaN675F1KPDAiMGkz7MKnJS7JIT3yithZ
# wuEppz1Yq3aaza57G4QNxDAf8xukOBbrVsaXbR2rsnnyyhHS5F/WBTxSD1Ifxp4V
# pX6+n6lXFllVcq9ok3DCsrp1mWpzMpTREEQQLt+C8weE5nQ7bXHiLQwb7iDVySAd
# YyktzuxeTsiT+CFhmzTrBcZe7FsavOvJz82sNEBfsXpm7nfISKhmV1efVFiODCu3
# T6cw2Vbuyntd463JT17lNecxy9qTXtyOj4DatpGYQJB5w3jHtrHEtWoYOAMQjdjU
# N6QuBX2I9YI+EJFwq1WCQTLX2wRzKm6RAXwhTNS8rhsDdV14Ztk6MUSaM0C/CNda
# SaTC5qmgZ92kJ7yhTzm1EVgX9yRcRo9k98FpiHaYdj1ZXUJ2h4mXaXpI8OCiEhtm
# mnTK3kse5w5jrubU75KSOp493ADkRSWJtppEGSt+wJS00mFt6zPZxd9LBADMfRyV
# w4/3IbKyEbe7f/LVjHAsQWCqsWMYRJUadmJ+9oCw++hkpjPRiQfhvbfmQ6QYuKZ3
# AeEPlAwhHbJUKSWJbOUOUlFHdL4mrLZBdd56rF+NP8m800ERElvlEFDrMcXKchYi
# Cd98THU/Y+whX8QgUWtvsauGi0/C1kVfnSD8oR7FwI+isX4KJpn15GkvmB0t9dmp
# sh3lGwIDAQABo4IBOjCCATYwDwYDVR0TAQH/BAUwAwEB/zAdBgNVHQ4EFgQU7Nfj
# gtJxXWRM3y5nP+e6mK4cD08wHwYDVR0jBBgwFoAUReuir/SSy4IxLVGLp6chnfNt
# yA8wDgYDVR0PAQH/BAQDAgGGMHkGCCsGAQUFBwEBBG0wazAkBggrBgEFBQcwAYYY
# aHR0cDovL29jc3AuZGlnaWNlcnQuY29tMEMGCCsGAQUFBzAChjdodHRwOi8vY2Fj
# ZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRBc3N1cmVkSURSb290Q0EuY3J0MEUG
# A1UdHwQ+MDwwOqA4oDaGNGh0dHA6Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2Vy
# dEFzc3VyZWRJRFJvb3RDQS5jcmwwEQYDVR0gBAowCDAGBgRVHSAAMA0GCSqGSIb3
# DQEBDAUAA4IBAQBwoL9DXFXnOF+go3QbPbYW1/e/Vwe9mqyhhyzshV6pGrsi+Ica
# aVQi7aSId229GhT0E0p6Ly23OO/0/4C5+KH38nLeJLxSA8hO0Cre+i1Wz/n096ww
# epqLsl7Uz9FDRJtDIeuWcqFItJnLnU+nBgMTdydE1Od/6Fmo8L8vC6bp8jQ87PcD
# x4eo0kxAGTVGamlUsLihVo7spNU96LHc/RzY9HdaXFSMb++hUD38dglohJ9vytsg
# jTVgHAIDyyCwrFigDkBjxZgiwbJZ9VVrzyerbHbObyMt9H5xaiNrIv8SuFQtJ37Y
# OtnwtoeW/VvRXKwYw02fc7cBqZ9Xql4o4rmUMIIGtDCCBJygAwIBAgIQDcesVwX/
# IZkuQEMiDDpJhjANBgkqhkiG9w0BAQsFADBiMQswCQYDVQQGEwJVUzEVMBMGA1UE
# ChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNlcnQuY29tMSEwHwYD
# VQQDExhEaWdpQ2VydCBUcnVzdGVkIFJvb3QgRzQwHhcNMjUwNTA3MDAwMDAwWhcN
# MzgwMTE0MjM1OTU5WjBpMQswCQYDVQQGEwJVUzEXMBUGA1UEChMORGlnaUNlcnQs
# IEluYy4xQTA/BgNVBAMTOERpZ2lDZXJ0IFRydXN0ZWQgRzQgVGltZVN0YW1waW5n
# IFJTQTQwOTYgU0hBMjU2IDIwMjUgQ0ExMIICIjANBgkqhkiG9w0BAQEFAAOCAg8A
# MIICCgKCAgEAtHgx0wqYQXK+PEbAHKx126NGaHS0URedTa2NDZS1mZaDLFTtQ2oR
# jzUXMmxCqvkbsDpz4aH+qbxeLho8I6jY3xL1IusLopuW2qftJYJaDNs1+JH7Z+Qd
# SKWM06qchUP+AbdJgMQB3h2DZ0Mal5kYp77jYMVQXSZH++0trj6Ao+xh/AS7sQRu
# QL37QXbDhAktVJMQbzIBHYJBYgzWIjk8eDrYhXDEpKk7RdoX0M980EpLtlrNyHw0
# Xm+nt5pnYJU3Gmq6bNMI1I7Gb5IBZK4ivbVCiZv7PNBYqHEpNVWC2ZQ8BbfnFRQV
# ESYOszFI2Wv82wnJRfN20VRS3hpLgIR4hjzL0hpoYGk81coWJ+KdPvMvaB0WkE/2
# qHxJ0ucS638ZxqU14lDnki7CcoKCz6eum5A19WZQHkqUJfdkDjHkccpL6uoG8pbF
# 0LJAQQZxst7VvwDDjAmSFTUms+wV/FbWBqi7fTJnjq3hj0XbQcd8hjj/q8d6ylgx
# CZSKi17yVp2NL+cnT6Toy+rN+nM8M7LnLqCrO2JP3oW//1sfuZDKiDEb1AQ8es9X
# r/u6bDTnYCTKIsDq1BtmXUqEG1NqzJKS4kOmxkYp2WyODi7vQTCBZtVFJfVZ3j7O
# gWmnhFr4yUozZtqgPrHRVHhGNKlYzyjlroPxul+bgIspzOwbtmsgY1MCAwEAAaOC
# AV0wggFZMBIGA1UdEwEB/wQIMAYBAf8CAQAwHQYDVR0OBBYEFO9vU0rp5AZ8esri
# kFb2L9RJ7MtOMB8GA1UdIwQYMBaAFOzX44LScV1kTN8uZz/nupiuHA9PMA4GA1Ud
# DwEB/wQEAwIBhjATBgNVHSUEDDAKBggrBgEFBQcDCDB3BggrBgEFBQcBAQRrMGkw
# JAYIKwYBBQUHMAGGGGh0dHA6Ly9vY3NwLmRpZ2ljZXJ0LmNvbTBBBggrBgEFBQcw
# AoY1aHR0cDovL2NhY2VydHMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0VHJ1c3RlZFJv
# b3RHNC5jcnQwQwYDVR0fBDwwOjA4oDagNIYyaHR0cDovL2NybDMuZGlnaWNlcnQu
# Y29tL0RpZ2lDZXJ0VHJ1c3RlZFJvb3RHNC5jcmwwIAYDVR0gBBkwFzAIBgZngQwB
# BAIwCwYJYIZIAYb9bAcBMA0GCSqGSIb3DQEBCwUAA4ICAQAXzvsWgBz+Bz0RdnEw
# vb4LyLU0pn/N0IfFiBowf0/Dm1wGc/Do7oVMY2mhXZXjDNJQa8j00DNqhCT3t+s8
# G0iP5kvN2n7Jd2E4/iEIUBO41P5F448rSYJ59Ib61eoalhnd6ywFLerycvZTAz40
# y8S4F3/a+Z1jEMK/DMm/axFSgoR8n6c3nuZB9BfBwAQYK9FHaoq2e26MHvVY9gCD
# A/JYsq7pGdogP8HRtrYfctSLANEBfHU16r3J05qX3kId+ZOczgj5kjatVB+NdADV
# ZKON/gnZruMvNYY2o1f4MXRJDMdTSlOLh0HCn2cQLwQCqjFbqrXuvTPSegOOzr4E
# Wj7PtspIHBldNE2K9i697cvaiIo2p61Ed2p8xMJb82Yosn0z4y25xUbI7GIN/TpV
# fHIqQ6Ku/qjTY6hc3hsXMrS+U0yy+GWqAXam4ToWd2UQ1KYT70kZjE4YtL8Pbzg0
# c1ugMZyZZd/BdHLiRu7hAWE6bTEm4XYRkA6Tl4KSFLFk43esaUeqGkH/wyW4N7Oi
# gizwJWeukcyIPbAvjSabnf7+Pu0VrFgoiovRDiyx3zEdmcif/sYQsfch28bZeUz2
# rtY/9TCA6TD8dC3JE3rYkrhLULy7Dc90G6e8BlqmyIjlgp2+VqsS9/wQD7yFylIz
# 0scmbKvFoW2jNrbM1pD2T7m3XDCCBu0wggTVoAMCAQICEAqA7xhLjfEFgtHEdqeV
# dGgwDQYJKoZIhvcNAQELBQAwaTELMAkGA1UEBhMCVVMxFzAVBgNVBAoTDkRpZ2lD
# ZXJ0LCBJbmMuMUEwPwYDVQQDEzhEaWdpQ2VydCBUcnVzdGVkIEc0IFRpbWVTdGFt
# cGluZyBSU0E0MDk2IFNIQTI1NiAyMDI1IENBMTAeFw0yNTA2MDQwMDAwMDBaFw0z
# NjA5MDMyMzU5NTlaMGMxCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwg
# SW5jLjE7MDkGA1UEAxMyRGlnaUNlcnQgU0hBMjU2IFJTQTQwOTYgVGltZXN0YW1w
# IFJlc3BvbmRlciAyMDI1IDEwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoIC
# AQDQRqwtEsae0OquYFazK1e6b1H/hnAKAd/KN8wZQjBjMqiZ3xTWcfsLwOvRxUwX
# cGx8AUjni6bz52fGTfr6PHRNv6T7zsf1Y/E3IU8kgNkeECqVQ+3bzWYesFtkepEr
# vUSbf+EIYLkrLKd6qJnuzK8Vcn0DvbDMemQFoxQ2Dsw4vEjoT1FpS54dNApZfKY6
# 1HAldytxNM89PZXUP/5wWWURK+IfxiOg8W9lKMqzdIo7VA1R0V3Zp3DjjANwqAf4
# lEkTlCDQ0/fKJLKLkzGBTpx6EYevvOi7XOc4zyh1uSqgr6UnbksIcFJqLbkIXIPb
# cNmA98Oskkkrvt6lPAw/p4oDSRZreiwB7x9ykrjS6GS3NR39iTTFS+ENTqW8m6TH
# uOmHHjQNC3zbJ6nJ6SXiLSvw4Smz8U07hqF+8CTXaETkVWz0dVVZw7knh1WZXOLH
# gDvundrAtuvz0D3T+dYaNcwafsVCGZKUhQPL1naFKBy1p6llN3QgshRta6Eq4B40
# h5avMcpi54wm0i2ePZD5pPIssoszQyF4//3DoK2O65Uck5Wggn8O2klETsJ7u8xE
# ehGifgJYi+6I03UuT1j7FnrqVrOzaQoVJOeeStPeldYRNMmSF3voIgMFtNGh86w3
# ISHNm0IaadCKCkUe2LnwJKa8TIlwCUNVwppwn4D3/Pt5pwIDAQABo4IBlTCCAZEw
# DAYDVR0TAQH/BAIwADAdBgNVHQ4EFgQU5Dv88jHt/f3X85FxYxlQQ89hjOgwHwYD
# VR0jBBgwFoAU729TSunkBnx6yuKQVvYv1Ensy04wDgYDVR0PAQH/BAQDAgeAMBYG
# A1UdJQEB/wQMMAoGCCsGAQUFBwMIMIGVBggrBgEFBQcBAQSBiDCBhTAkBggrBgEF
# BQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQuY29tMF0GCCsGAQUFBzAChlFodHRw
# Oi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRUcnVzdGVkRzRUaW1lU3Rh
# bXBpbmdSU0E0MDk2U0hBMjU2MjAyNUNBMS5jcnQwXwYDVR0fBFgwVjBUoFKgUIZO
# aHR0cDovL2NybDMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0VHJ1c3RlZEc0VGltZVN0
# YW1waW5nUlNBNDA5NlNIQTI1NjIwMjVDQTEuY3JsMCAGA1UdIAQZMBcwCAYGZ4EM
# AQQCMAsGCWCGSAGG/WwHATANBgkqhkiG9w0BAQsFAAOCAgEAZSqt8RwnBLmuYEHs
# 0QhEnmNAciH45PYiT9s1i6UKtW+FERp8FgXRGQ/YAavXzWjZhY+hIfP2JkQ38U+w
# tJPBVBajYfrbIYG+Dui4I4PCvHpQuPqFgqp1PzC/ZRX4pvP/ciZmUnthfAEP1HSh
# TrY+2DE5qjzvZs7JIIgt0GCFD9ktx0LxxtRQ7vllKluHWiKk6FxRPyUPxAAYH2Vy
# 1lNM4kzekd8oEARzFAWgeW3az2xejEWLNN4eKGxDJ8WDl/FQUSntbjZ80FU3i54t
# px5F/0Kr15zW/mJAxZMVBrTE2oi0fcI8VMbtoRAmaaslNXdCG1+lqvP4FbrQ6IwS
# BXkZagHLhFU9HCrG/syTRLLhAezu/3Lr00GrJzPQFnCEH1Y58678IgmfORBPC1JK
# kYaEt2OdDh4GmO0/5cHelAK2/gTlQJINqDr6JfwyYHXSd+V08X1JUPvB4ILfJdmL
# +66Gp3CSBXG6IwXMZUXBhtCyIaehr0XkBoDIGMUG1dUtwq1qmcwbdUfcSYCn+Own
# cVUXf53VJUNOaMWMts0VlRYxe5nK+At+DI96HAlXHAL5SlfYxJ7La54i71McVWRP
# 66bW+yERNpbJCjyCYG2j+bdpxo/1Cy4uPcU3AWVPGrbn5PhDBf3Froguzzhk++am
# i+r3Qrx5bIbY3TVzgiFI7Gq3zWcxggUmMIIFIgIBATBKMDYxCzAJBgNVBAYTAkRF
# MQ4wDAYDVQQKDAVCb2NraTEXMBUGA1UEAwwOQm9ja2kgU29mdHdhcmUCEEl/Iatc
# ElOhRsJiQFFHFpwwDQYJYIZIAWUDBAIBBQCggYQwGAYKKwYBBAGCNwIBDDEKMAig
# AoAAoQKAADAZBgkqhkiG9w0BCQMxDAYKKwYBBAGCNwIBBDAcBgorBgEEAYI3AgEL
# MQ4wDAYKKwYBBAGCNwIBFTAvBgkqhkiG9w0BCQQxIgQgQzoUTc3BIa8P+bEA6lvk
# mlrMQCW86l9g+GKUyLgy6QswDQYJKoZIhvcNAQEBBQAEggEAM5tWwIhdTjLSzVhK
# eBIiujrAqampZtcTYmEHb6iZg4+hCUACtWX+vyHF/JpwQ1arYhU/+TOBARI1ijjj
# Q6XUtdQ3oHoQncvL+LBA0xoRHxbm0gXZykcDrtPrqC2VhB6F620nWnZHQTAaB27V
# CHjlDfDRGYWznYdjLLOOt6rZMWoykyrQkXuuYJ/ToRWl4GXD+p8E1X9acw00wcgu
# 0C3wSxB9aBKuT7SyLOJ8yvFOx4XX3m+eZKzLXnu5vEJZlGfcR6oziGR9Q59YvTnt
# DIraTVl5q+83HiG/bd5rYbQsrSutthFzvFlFuYyUZgfk2wz5ADsN9w3QaL3g0Kcz
# rZgVjKGCAyYwggMiBgkqhkiG9w0BCQYxggMTMIIDDwIBATB9MGkxCzAJBgNVBAYT
# AlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5jLjFBMD8GA1UEAxM4RGlnaUNlcnQg
# VHJ1c3RlZCBHNCBUaW1lU3RhbXBpbmcgUlNBNDA5NiBTSEEyNTYgMjAyNSBDQTEC
# EAqA7xhLjfEFgtHEdqeVdGgwDQYJYIZIAWUDBAIBBQCgaTAYBgkqhkiG9w0BCQMx
# CwYJKoZIhvcNAQcBMBwGCSqGSIb3DQEJBTEPFw0yNjAxMjAxODAyNTZaMC8GCSqG
# SIb3DQEJBDEiBCAQr3wEer7/9QYRF7POOe0TKW3D7qkO2NePdj/I1axiTjANBgkq
# hkiG9w0BAQEFAASCAgCUTNbAzGNg1pr0tjhrw0YLUwLLE/SDngF1wbh20+t+Rv8Q
# NP7gQQsOcVAngBWVHCuJ5Hsvtvc0gCGaqFBL3pgYdn1cFLBglEdna07PoQHpB/aN
# lpgzXB3Yv5kMHtIn5h0eDFOvm4GaeyMJBQBT+optpqhKkVk0R4EKAdS7z9bUMLas
# yeRiYIbbQ9ZJtToGRxafhaIb0WFm54x5gTaoyh9Rmlep5d0IQ1hAV8ZSk/f5wyYD
# 7xxEzHPfcX78EuCFdCVudpbQXJHgQmnGinSGsVcK3BJ+u2UgnxqwQYnlHHO0Z9ct
# G0mKyC7m3bIjeoV55n1KPxRw7t7OrLBZIPyfvOxvSqXYgSj0VX0TeiBH9atiubXP
# bFxb4OgXO8x5KOtJGYhyDNpZhZjAFAO2ItR1ojhInCK1Nps1f4j42+Ga0Kn5zy8z
# UoM6vhBKInTcAvRwxL5JvJ7IucIDaXL6Q8ShvoiGT0o4pJClpACE6RZuH0pULd/K
# zRKRhB6Hncti4qRXmClHEU6nu8/YiZNR3AjVeJ8wE69DtB82WNGkysqmKPetYUus
# LFI1EDP1KTWTQwlyfn4UgYWni7+dpTrat7QqX4Rz1F9Ffa/H4B7lOllfbpV8MfL4
# DSgpNZR0LdR6H63IVsV5wKGwJJgHrmlwd0fSGdVpD5/Rbl45mff1+D2s84bARA==
# SIG # End signature block

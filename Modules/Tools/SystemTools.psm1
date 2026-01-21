# Import required modules
Import-Module "$PSScriptRoot\..\Core\Core.psm1" -Force -Global
Import-Module "$PSScriptRoot\..\Core\ProgressBarTools.psm1" -Force -Global
Import-Module "$PSScriptRoot\..\Core\TextStyle.psm1" -Force -Global

# Funktion zum Sicherstellen, dass die ProgressBar initialisiert ist
function Ensure-ProgressBarInitialized {
    param (
        [System.Windows.Forms.ProgressBar]$progressBar,
        [System.Windows.Forms.Label]$statusLabel = $null
    )
    
    # Versuche direkt die Initialize-Funktion aufzurufen
    try {
        Initialize-ProgressComponents -ProgressBar $progressBar -StatusLabel $statusLabel
        return $true
    }
    catch {
        Write-Host "Fehler beim Initialisieren der ProgressBar-Komponente: $_" -ForegroundColor Yellow
        return $false
    }
}

# Function to run MRT Quick Scan
function Start-QuickMRT {
    param (
        [System.Windows.Forms.RichTextBox]$outputBox,
        [System.Windows.Forms.ProgressBar]$progressBar
    )
    
    Clear-Host
    
    # Stelle sicher, dass das ProgressBarTools-Modul korrekt verwendet wird
    if ($progressBar) {
        # Lokale Initialisierung für die aktuelle Funktion
        # Obwohl wir keinen StatusLabel haben, initialisieren wir die ProgressBar
        Initialize-ProgressComponents -ProgressBar $progressBar -StatusLabel $null
    }
    
    # In Log-Datei und Datenbank schreiben, dass der Scan startet
    Write-ToolLog -ToolName "QuickMRT" -Message "Quick MRT Scan wird gestartet" -OutputBox $outputBox -Style 'Action' -Level "Information" -SaveToDatabase
    
    # Rahmen und Systeminformationen erstellen
    #$computerName = $env:COMPUTERNAME
    #$userName = $env:USERNAME
    #$osInfo = (Get-CimInstance -ClassName Win32_OperatingSystem).Caption
    #$dateTime = Get-Date -Format "dd.MM.yyyy HH:mm:ss"
    #$width = 80

        
    # Rahmen oben
    Write-Host "╔══════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-ColoredCenteredText                             "Malware Removal Tool"                                         
    Write-Host "╚══════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Green
    
    # ASCII-Art Logo
    Write-Host
    Write-Host
    Write-Host ' .d88888b.           d8b          888        888b     d888 8888888b. 88888888888 ' -ForegroundColor Cyan
    Write-Host 'd88P" "Y88b          Y8P          888        8888b   d8888 888   Y88b    888     ' -ForegroundColor Blue
    Write-Host '888     888                       888        88888b.d88888 888    888    888     ' -ForegroundColor Cyan
    Write-Host '888     888 888  888 888  .d8888b 888  888   888Y88888P888 888   d88P    888     ' -ForegroundColor Blue
    Write-Host '888     888 888  888 888 d88P"    888 .88P   888 Y888P 888 8888888P"     888     ' -ForegroundColor Cyan
    Write-Host '888 Q   888 888  888 888 888      888888K    888  Y8P  888 888 T88b      888     ' -ForegroundColor Blue
    Write-Host 'Y88b. .d88P Y88b 888 888 Y88b.    888 "88b   888   "   888 888  T88b     888     ' -ForegroundColor Cyan
    Write-Host ' "Y88888P"   "Y88888 888  "Y8888P 888  888   888       888 888   T88b    888     ' -ForegroundColor Blue
    Write-Host
    Write-Host
    # Rahmen für Systeminformationen
    Write-Host "╔══════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-ColoredCenteredText                          "INFORMATIONEN"                                           
    Write-Host "╠══════════════════════════════════════════════════════════════════════════════╣" -ForegroundColor Green
    # Systeminformationen
    Write-Host "║                                                                              ║" -ForegroundColor Green
    Write-Host "  ├─  Schneller Sicherheitscheck mit dem MRT:                                     " -ForegroundColor Yellow                 
    Write-Host "  ├─  Der Quick-Scan durchsucht Ihr System auf gängige Schadsoftware.             " -ForegroundColor Yellow                                    
    Write-Host "  ├─  Er dauert nur wenige Minuten und beeinträchtigt die Leistung kaum.          " -ForegroundColor Yellow                                    
    Write-Host "  └─  Empfohlen für regelmäßige, schnelle Sicherheitsüberprüfungen.               " -ForegroundColor Yellow                                  
    Write-Host "║                                                                              ║" -ForegroundColor Green
    
    Write-Host "╠══════════════════════════════════════════════════════════════════════════════╣" -ForegroundColor Green
    Write-ColoredCenteredText "Malware Removal Tool Scan wird initialisiert..."
    Write-Host "╚══════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Green
    
    # 3 Sekunden warten vor dem Start
    Start-Sleep -Seconds 3
    # outputBox zuruecksetzen
    $outputBox.Clear()
    
    try {
        # Header für den Scan
        Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Action'
        $outputBox.AppendText("`r`n===== MICROSOFT MALICIOUS SOFTWARE REMOVAL TOOL (MRT) =====`r`n")
        Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Default'
        $outputBox.AppendText("Modus: Quick Scan`r`n")
        Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Default'
        $outputBox.AppendText("Zeitstempel: $(Get-Date -Format 'dd.MM.yyyy HH:mm:ss')`r`n`r`n")
        
        # Prüfe ob MRT.exe existiert
        $mrtPath = "$env:windir\System32\mrt.exe"
        if (-not (Test-Path $mrtPath)) {
            Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Error'
            $outputBox.AppendText("[!] FEHLER: MRT.exe wurde nicht gefunden!`r`n")
            Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Default'
            $outputBox.AppendText("    Pfad: $mrtPath`r`n")
            return
        }
        
        # MRT Log-Datei Pfad
        $logPath = "$env:windir\debug\mrt.log"
        
        # Log-Datei für den aktuellen Scan sichern
        $backupLogPath = "$env:TEMP\mrt_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
        if (Test-Path $logPath) {
            Copy-Item -Path $logPath -Destination $backupLogPath -Force
        }
        
        # Scan starten
        Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Action'
        $outputBox.AppendText("[>] Quick Scan wird gestartet...`r`n")
             
        
        Write-Host
        Write-Host
        Write-Host "     [►] Bitte warten bis der Scan abgeschlossen ist !!!" -ForegroundColor Blue
        Write-Host
        Write-Host "`n" + ("═" * 70) -ForegroundColor Cyan 
        Write-Host
        Write-Host "     [ Quick Scan wird gestartet... ]" -ForegroundColor $secondaryColor

        # Progressbar initialisieren
        $progressBar.Value = 0
        Update-ProgressStatus -StatusText "MRT Quick-Scan wird vorbereitet..." -ProgressValue 0 -TextColor ([System.Drawing.Color]::White) -progressBarParam $progressBar
        Write-Host
        
        # Prozess konfigurieren
        $process = New-Object System.Diagnostics.Process
        $process.StartInfo.FileName = $mrtPath
        $process.StartInfo.Arguments = "/Q"
        $process.StartInfo.UseShellExecute = $false
        $process.StartInfo.RedirectStandardOutput = $true
        $process.StartInfo.RedirectStandardError = $true
        $process.StartInfo.CreateNoWindow = $true
        
        # Prozess starten
        $process.Start() | Out-Null
        
        # Startzeit für den Scan
        $startTime = Get-Date
        
        # Geschätzte Scan-Dauer (realistischere Dauer von 2 Minuten für Quick Scan)
        $estimatedDuration = New-TimeSpan -Minutes 1
        
        # Timeout für den Scan festlegen (15 Minuten)
        $timeoutDuration = New-TimeSpan -Minutes 10
        $hasTimedOut = $false
        
        # Animationszeichen für Fortschritt
        $progressChars = @('|', '/', '-', '\')
        
        # Phasen des Scans definieren - mit angepassten Fortschrittsprozenten
        $scanPhases = @(
            @{ Name = "Initialisierung"; Progress = 5; Color = [System.Drawing.Color]::White; TimeWeight = 0.1 },
            @{ Name = "Überprüfung von Systemdateien"; Progress = 25; Color = [System.Drawing.Color]::White; TimeWeight = 0.25 },
            @{ Name = "Suche nach Malware-Mustern"; Progress = 50; Color = [System.Drawing.Color]::White; TimeWeight = 0.35 },
            @{ Name = "Überprüfung kritischer Bereiche"; Progress = 75; Color = [System.Drawing.Color]::White; TimeWeight = 0.2 },
            @{ Name = "Finale Überprüfungen"; Progress = 95; Color = [System.Drawing.Color]::LimeGreen; TimeWeight = 0.1 }
        )
        
        # Gewichtete Phasenintervalle berechnen
        # Alternative Berechnung des totalWeight, um Property-Fehler zu vermeiden
        $totalWeight = 0
        foreach ($phase in $scanPhases) {
            $totalWeight += $phase.TimeWeight
        }
        $phaseIntervals = @()
        $cumulativeTime = 0
        
        foreach ($phase in $scanPhases) {
            $intervalSeconds = ($phase.TimeWeight / $totalWeight) * $estimatedDuration.TotalSeconds
            $cumulativeTime += $intervalSeconds
            $phaseIntervals += $cumulativeTime
        }
        
        # Aktuelle Phase
        $currentPhase = -1 # Anfangswert, damit erste Phase als Änderung erkannt wird
        $progressIndex = 0  # Index für die Animationszeichen
        
        # Fortschrittsanzeige: Scan wird gestartet
        Write-Host "     [>] Scan wird gestartet. Bitte warten... (Dies kann einige Minuten dauern)" -ForegroundColor Yellow
        Write-Host "     [>] Scan läuft | Dauer: 00:00 " -NoNewline -ForegroundColor Yellow
        
        while (-not $process.HasExited) {
            $elapsedTime = (Get-Date) - $startTime
            $formattedTime = "{0:mm}:{0:ss}" -f $elapsedTime
            
            # Animationszeichen rotieren und Dauer anzeigen
            $progressChar = $progressChars[$progressIndex]
            $progressIndex = ($progressIndex + 1) % $progressChars.Length
            
            # Fortschrittsanzeige mit Zeitdauer aktualisieren
            Write-Host "`r     [>] Scan läuft $progressChar Dauer: $formattedTime " -NoNewline -ForegroundColor Yellow
            
            # Timeout-Prüfung
            if ($elapsedTime -gt $timeoutDuration) {
                Write-Host "" # Neue Zeile nach Animation
                Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Error'
                $outputBox.AppendText("[!] Timeout: Der Scan dauert länger als erwartet und wird beendet.`r`n")
                
                try {
                    $process.Kill()
                    $hasTimedOut = $true
                    $outputBox.AppendText("[!] MRT-Prozess wurde beendet.`r`n")
                }
                catch {
                    $outputBox.AppendText("[!] Fehler beim Beenden des MRT-Prozesses: $_`r`n")
                }
                
                Update-ProgressStatus -StatusText "MRT Quick-Scan abgebrochen (Timeout)" -ProgressValue 0 -TextColor ([System.Drawing.Color]::Red) -progressBarParam $progressBar
                break
            }
            
            # Phase basierend auf verstrichener Zeit berechnen
            $timeProgress = $elapsedTime.TotalSeconds
            $expectedPhase = -1
            
            # Ermitteln der aktuellen Phase anhand der verstrichenen Zeit
            for ($i = 0; $i -lt $phaseIntervals.Count; $i++) {
                if ($timeProgress -le $phaseIntervals[$i]) {
                    $expectedPhase = $i
                    break
                }
            }
            
            # Wenn wir über alle definierten Intervalle hinaus sind, bleiben wir bei der letzten Phase
            if ($expectedPhase -eq -1) {
                $expectedPhase = $scanPhases.Count - 1
            }
            
            # Wenn eine neue Phase erreicht wurde
            if ($expectedPhase -gt $currentPhase) {
                $currentPhase = $expectedPhase
                Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Action'
                $outputBox.AppendText("[>] Phase: $($scanPhases[$currentPhase].Name)`r`n")
                                                
                
                Write-Host "   ├─ Phase: $($scanPhases[$currentPhase].Name)" -ForegroundColor Cyan
               
                Update-ProgressStatus -StatusText "MRT Quick-Scan: $($scanPhases[$currentPhase].Name)" `
                    -ProgressValue $scanPhases[$currentPhase].Progress `
                    -TextColor $scanPhases[$currentPhase].Color `
                    -progressBarParam $progressBar
            }
            
            # Feinerer Fortschritt innerhalb einer Phase berechnen
            if ($currentPhase -lt $scanPhases.Count - 1) {
                $phaseStartTime = if ($currentPhase -eq 0) { 0 } else { $phaseIntervals[$currentPhase - 1] }
                $phaseEndTime = $phaseIntervals[$currentPhase]
                $phaseDuration = $phaseEndTime - $phaseStartTime
                $phaseElapsedTime = $timeProgress - $phaseStartTime
                
                if ($phaseDuration -gt 0) {
                    $phaseProgress = [Math]::Min($phaseElapsedTime / $phaseDuration, 1.0)
                    $prevProgress = if ($currentPhase -eq 0) { 0 } else { $scanPhases[$currentPhase - 1].Progress }
                    $nextProgress = $scanPhases[$currentPhase].Progress
                    $currentProgress = $prevProgress + ($nextProgress - $prevProgress) * $phaseProgress
                    
                    # Fortschrittsbalken mit feinerem Fortschritt aktualisieren
                    Update-ProgressStatus -StatusText "MRT Quick-Scan: $($scanPhases[$currentPhase].Name)" `
                        -ProgressValue ([int]$currentProgress) `
                        -TextColor $scanPhases[$currentPhase].Color `
                        -progressBarParam $progressBar
                }
            }
            
            # Log-Datei auf Fehler überprüfen
            if (Test-Path $logPath) {
                $lastLines = Get-Content $logPath -Tail 5
                foreach ($line in $lastLines) {
                    if ($line -match "Error|Failed|Exception") {
                        Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Error'
                        $outputBox.AppendText("[!] Warnung: $line`r`n")
                        Update-ProgressStatus -StatusText "Warnung aufgetreten" -ProgressValue $progressBar.Value -TextColor ([System.Drawing.Color]::Red) -progressBarParam $progressBar
                    }
                }
            }
            
            Start-Sleep -Milliseconds 250
        }
        
        # Neue Zeile nach Animation
        Write-Host "" 
        
        # Zeige die Gesamtdauer des Scans an
        $totalScanTime = (Get-Date) - $startTime
        $formattedTotalTime = "{0:mm}:{0:ss}" -f $totalScanTime
        Write-Host "     [√] Scan abgeschlossen. Gesamtdauer: $formattedTotalTime" -ForegroundColor Green
        
        # Warte auf Prozessende und hole Exit-Code
        $process.WaitForExit()
        $exitCode = $process.ExitCode
        
        # Debug-Information in die Log-Datei schreiben
        try {
            Write-ToolLog -ToolName "QuickMRT" -Message "Debug: MRT-Prozess beendet mit Exit-Code: $exitCode" -OutputBox $null -Level "Information" -SaveToDatabase
        }
        catch {
            # Stille Fehlerbehandlung für Debug-Log
        }
        
        # Ausgabe und Fehler einlesen
        $output = $process.StandardOutput.ReadToEnd()
        $errorOutput = $process.StandardError.ReadToEnd()
        
        # Prozess aufräumen
        $process.Dispose()
        
        # Ergebnis in die Log-Datei schreiben
        try {
            $resultMessage = switch ($exitCode) {
                0 { "Quick MRT Scan erfolgreich abgeschlossen. Keine Malware gefunden." }
                1 { "Quick MRT Scan abgeschlossen. Malware wurde gefunden und entfernt." }
                2 { "Quick MRT Scan abgeschlossen. Scan wurde abgebrochen." }
                3 { "Quick MRT Scan abgeschlossen. Ein Neustart ist erforderlich für MRT-Initialisierung." }
                7 { "Quick MRT Scan abgeschlossen. Keine Administratorrechte." }
                8 { "Quick MRT Scan abgeschlossen. System-Neustart erforderlich." }
                9 { "Quick MRT Scan abgeschlossen. Schwerwiegende Malware gefunden." }
                $null { "Quick MRT Scan abgeschlossen. Exit-Code konnte nicht erfasst werden." }
                default { "Quick MRT Scan mit Exit-Code $exitCode beendet." }
            }
            
            # Stelle sicher, dass die Ergebnisse in der Log-Datei erscheinen
            # mit expliziter Fehlerbehandlung
            # Versuche das Ergebnis zu loggen, merke dir den Erfolg
            $logSuccess = $false
            try {
                $logSuccess = Write-ToolLog -ToolName "QuickMRT" -Message $resultMessage -OutputBox $outputBox -Style 'Action' -Level "Information" -SaveToDatabase
            }
            catch {
                $logSuccess = $false
                Write-Host "Fehler beim Schreiben des QuickMRT-Logs: $_" -ForegroundColor Red
            }
            
            # Nur Fallback verwenden, wenn der erste Versuch fehlgeschlagen ist
            if (-not $logSuccess) {
                try {
                    $logFilePath = Join-Path $env:LOCALAPPDATA "BockisSystemTool\Logs\QuickMRT.log"
                    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                    $logEntry = "$timestamp - [INFO] $resultMessage"
                    
                    # Direktes Schreiben nur als Fallback mit Cloud-Fehlerbehandlung
                    try {
                        [System.IO.File]::AppendAllText($logFilePath, "$logEntry`r`n", [System.Text.Encoding]::UTF8)
                        Write-Verbose "Fallback-Logging für QuickMRT erfolgreich"
                    }
                    catch {
                        # Prüfe auf Cloud-Provider-Fehler
                        $errorMsg = $_.Exception.Message
                        if ($errorMsg -notmatch "Clouddateianbieter|cloud file provider|STATUS_CLOUD_FILE_PROVIDER_NOT_RUNNING") {
                            Write-Verbose "Fehler beim Fallback-Logging: $_"
                        }
                    }
                }
                catch {
                    # Prüfe auf Cloud-Provider-Fehler
                    $errorMsg = $_.Exception.Message
                    if ($errorMsg -notmatch "Clouddateianbieter|cloud file provider|STATUS_CLOUD_FILE_PROVIDER_NOT_RUNNING") {
                        Write-Verbose "Fehler beim Schreiben des Scan-Ergebnisses: $_"
                    }
                }
            }
        }
        catch {
            # Bei Fehler während der Ergebnis-Protokollierung
            Write-Host "Fehler bei der Ergebnis-Protokollierung: $_" -ForegroundColor Red
            
            # Versuche trotzdem eine Nachricht zu loggen
            try {
                Write-ToolLog -ToolName "QuickMRT" -Message "Quick MRT Scan abgeschlossen mit Fehler bei der Ergebnisprotokollierung: $_" -OutputBox $outputBox -Style 'Error' -Level "Error" -SaveToDatabase
            }
            catch {
                # Stille Fehlerbehandlung
            }
        }
        
        # Wenn Malware gefunden wurde, detaillierter loggen
        try {
            if ($exitCode -eq 1 -or $exitCode -eq 9) {
                # Versuchen, aus der MRT-Log-Datei die gefundene Malware zu extrahieren
                if (Test-Path $logPath) {
                    $logContent = Get-Content $logPath -Tail 20 -ErrorAction SilentlyContinue
                    $malwareFound = $logContent | Where-Object { $_ -match "Found|Gefunden|Malware|Threat|Infection" }
                    
                    if ($malwareFound) {
                        foreach ($malwareEntry in $malwareFound) {
                            Write-ToolLog -ToolName "QuickMRT" -Message "Gefunden: $malwareEntry" -OutputBox $outputBox -Style 'Error' -Level "Warning" -SaveToDatabase
                        }
                    }
                    else {
                        Write-ToolLog -ToolName "QuickMRT" -Message "Malware gefunden, aber keine Details verfügbar" -OutputBox $outputBox -Style 'Error' -Level "Warning" -SaveToDatabase
                    }
                }
                else {
                    Write-ToolLog -ToolName "QuickMRT" -Message "Malware gefunden, aber MRT-Log-Datei nicht verfügbar" -OutputBox $outputBox -Style 'Error' -Level "Warning" -SaveToDatabase
                }
            }
        }
        catch {
            # Bei Fehler während der Malware-Detailsuche
            Write-ToolLog -ToolName "QuickMRT" -Message "Fehler bei der Malware-Detailsuche: $_" -OutputBox $outputBox -Style 'Error' -Level "Error" -SaveToDatabase
        }
        
        # Exit-Code auswerten        Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Action'
        $outputBox.AppendText("`r`n[►] Scan-Ergebnis:`r`n")
        
        if ($hasTimedOut) {
            Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Error'
            $outputBox.AppendText("    [✗] Status: Scan-Timeout`r`n")
            Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Warning'
            $outputBox.AppendText("    [!] Der Scan wurde wegen Zeitüberschreitung abgebrochen`r`n")
            Update-ProgressStatus -StatusText "Scan-Timeout" -ProgressValue 100 -TextColor ([System.Drawing.Color]::Red) -progressBarParam $progressBar
            
            # Neustart-Dialog für Timeout-Fall
            $restartResult = Show-CustomMessageBox -message "Der MRT-Scan wurde wegen Zeitüberschreitung abgebrochen. Ein Neustart könnte das Problem beheben. Möchten Sie den Computer jetzt neu starten?" -title "Scan-Timeout" -fontSize 12
            if ($restartResult -eq "OK") {
                Start-SystemRestart -outputBox $outputBox
            }
            
            return -99  # Spezieller Code für Timeout
        }
        
        if ($null -eq $exitCode) {
            Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Error'
            $outputBox.AppendText("    [×] Unerwarteter Fehler: Kein Exit-Code erhalten`r`n")
            Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Info'
            $outputBox.AppendText("    [i] Bitte überprüfen Sie die Windows Event-Logs für weitere Details`r`n")
            if ($errorOutput) {
                $outputBox.AppendText("    [i] Fehlerdetails: $errorOutput`r`n")
            }
            Update-ProgressStatus -StatusText "Fehler: Kein Exit-Code" -ProgressValue 100 -TextColor ([System.Drawing.Color]::Red) -progressBarParam $progressBar
            return -1
        }
        
        # Exit-Code Status und Empfehlungen mit Neustart-Integration
        switch ($exitCode) {
            0 {
                Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Success'
                $outputBox.AppendText("    [✓] Status: Scan erfolgreich abgeschlossen`r`n")
                Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Success'
                $outputBox.AppendText("    [✓] Keine Malware gefunden`r`n")
                Update-ProgressStatus -StatusText "Scan erfolgreich - Keine Malware gefunden" -ProgressValue 100 -TextColor ([System.Drawing.Color]::LimeGreen) -progressBarParam $progressBar
            }
            1 {
                Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Error'
                $outputBox.AppendText("    [✗] Status: Malware gefunden!`r`n")
                Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Warning'
                $outputBox.AppendText("    [!] Windows Defender Offline-Scan wird empfohlen`r`n")
                Update-ProgressStatus -StatusText "Malware gefunden!" -ProgressValue 100 -TextColor ([System.Drawing.Color]::Red) -progressBarParam $progressBar
                
                # Neustart-Dialog für Malware-Fall
                $restartResult = Show-CustomMessageBox -message "Für die Malware-Entfernung wird ein Neustart im abgesicherten Modus empfohlen. Möchten Sie den Computer jetzt neu starten?" -title "Sicherheitsneustart erforderlich" -fontSize 12
                if ($restartResult -eq "OK") {
                    Start-SystemRestart -outputBox $outputBox -safeMode $true
                }
            }
            2 {
                Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Alert'
                $outputBox.AppendText("    [!] Status: Scan abgebrochen`r`n")
                Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Warning'
                $outputBox.AppendText("    [!] Der Scan wurde manuell oder durch Zeitüberschreitung beendet`r`n")
                Update-ProgressStatus -StatusText "Scan abgebrochen" -ProgressValue 100 -TextColor ([System.Drawing.Color]::SaddleBrown) -progressBarParam $progressBar
            }
            3 {
                Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Error'
                $outputBox.AppendText("    [!] Status: Initialisierungsfehler`r`n")
                Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Warning'
                $outputBox.AppendText("    [!] Neustart erforderlich für MRT-Initialisierung`r`n")
                Update-ProgressStatus -StatusText "Initialisierungsfehler - Neustart empfohlen" -ProgressValue 100 -TextColor ([System.Drawing.Color]::Red) -progressBarParam $progressBar
                
                # Neustart-Dialog für Initialisierungsfehler
                $restartResult = Show-CustomMessageBox -message "Für die korrekte Initialisierung des MRT wird ein Neustart empfohlen. Möchten Sie den Computer jetzt neu starten?" -title "Neustart empfohlen" -fontSize 12
                if ($restartResult -eq "OK") {
                    Start-SystemRestart -outputBox $outputBox
                }
            }
            7 {
                Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Error'
                $outputBox.AppendText("    [✗] Status: Keine Administratorrechte`r`n")
                Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Info'
                $outputBox.AppendText("    [i] Bitte Tool als Administrator ausführen`r`n")
                Update-ProgressStatus -StatusText "Administratorrechte erforderlich" -ProgressValue 100 -TextColor ([System.Drawing.Color]::Red) -progressBarParam $progressBar
            }
            8 {
                Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Warning'
                $outputBox.AppendText("    [!] Status: System-Neustart erforderlich`r`n")
                Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Info'
                $outputBox.AppendText("    [i] Bitte führen Sie einen System-Neustart durch`r`n")
                Update-ProgressStatus -StatusText "Neustart erforderlich" -ProgressValue 100 -TextColor ([System.Drawing.Color]::Orange) -progressBarParam $progressBar
                
                # Neustart-Dialog anzeigen
                $restartResult = Show-CustomMessageBox -message "Ein Systemneustart wird empfohlen. Möchten Sie den Computer jetzt neu starten?" -title "Neustart erforderlich" -fontSize 12
                if ($restartResult -eq "OK") {
                    Start-SystemRestart -outputBox $outputBox
                }
            }
            9 {
                Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Error'
                $outputBox.AppendText("    [✗] Status: Schwerwiegende Malware gefunden`r`n")
                Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Warning'
                $outputBox.AppendText("    [!] Windows Defender Offline-Scan wird dringend empfohlen`r`n")
                Update-ProgressStatus -StatusText "Schwerwiegende Malware gefunden!" -ProgressValue 100 -TextColor ([System.Drawing.Color]::Red) -progressBarParam $progressBar
                
                # Neustart-Dialog für schwerwiegende Malware
                $restartResult = Show-CustomMessageBox -message "Für die Entfernung der schwerwiegenden Malware wird ein sofortiger Neustart im abgesicherten Modus dringend empfohlen. Möchten Sie den Computer jetzt neu starten?" -title "Dringender Sicherheitsneustart" -fontSize 12
                if ($restartResult -eq "OK") {
                    Start-SystemRestart -outputBox $outputBox -safeMode $true
                }
            }            default {
                Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Alert'
                $outputBox.AppendText("    [?] Status: Unbekannter Exit-Code ($exitCode)`r`n")
                $outputBox.AppendText("    [i] Bitte überprüfen Sie die Windows Event-Logs`r`n")
                Update-ProgressStatus -StatusText "Unbekannter Status (Code: $exitCode)" -ProgressValue 100 -TextColor ([System.Drawing.Color]::SaddleBrown) -progressBarParam $progressBar
            }
        }

        # Detaillierte Empfehlungen
        Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Action'
        $outputBox.AppendText("`r`n[i] Empfehlungen:`r`n")
        
        switch ($exitCode) {
            0 {
                Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Success'
                $outputBox.AppendText("    * Keine weiteren Maßnahmen erforderlich`r`n")
                Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Success'
                $outputBox.AppendText("    * Regelmäßige Scans werden empfohlen`r`n")
                Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Success'
                $outputBox.AppendText("    * Nächster Scan in 7 Tagen empfohlen`r`n")
            }
            { $_ -in 1, 9 } {
                Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Error'
                $outputBox.AppendText("    * Sofortige Maßnahmen erforderlich:`r`n")
                Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Error'
                $outputBox.AppendText("    * 1. System im abgesicherten Modus starten`r`n")
                Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Error'
                $outputBox.AppendText("    * 2. Windows Defender Offline-Scan durchführen`r`n")
                Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Error'
                $outputBox.AppendText("    * 3. Wichtige Daten sichern`r`n")
                Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Error'
                $outputBox.AppendText("    * 4. Professionelle Malware-Entfernung in Betracht ziehen`r`n")
            }
            { $_ -in 2, 3 } {
                Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Alert'
                $outputBox.AppendText("    * Scan später wiederholen`r`n")
                Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Alert'
                $outputBox.AppendText("    * System-Neustart durchführen`r`n")
                Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Alert'
                $outputBox.AppendText("    * Windows Event-Logs überprüfen`r`n")
            }
            -99 {
                Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Warning'
                $outputBox.AppendText("    * System neu starten und Tool erneut ausführen`r`n")
                Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Warning'
                $outputBox.AppendText("    * Temporäre Dateien bereinigen`r`n")
                Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Warning'
                $outputBox.AppendText("    * Nach dem Neustart zuerst Windows Defender starten`r`n")
                Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Warning'
                $outputBox.AppendText("    * Falls das Problem bestehen bleibt, Defender-Dienst neu starten`r`n")
            }
            7 {
                Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Warning'
                $outputBox.AppendText("    * Tool als Administrator neu starten`r`n")
                Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Warning'
                $outputBox.AppendText("    * UAC-Einstellungen überprüfen`r`n")
            }
            8 {
                Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Warning'
                $outputBox.AppendText("    * System-Neustart durchführen`r`n")
                Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Warning'
                $outputBox.AppendText("    * Anschließend Full Scan durchführen`r`n")
                Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Warning'
                $outputBox.AppendText("    * Windows Defender Überprüfung empfohlen`r`n")
            }
            default {
                if ($exitCode -ne 0) {
                    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Warning'
                    $outputBox.AppendText("    * Windows Event-Logs überprüfen`r`n")
                    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Warning'
                    $outputBox.AppendText("    * Scan im abgesicherten Modus wiederholen`r`n")
                    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Warning'
                    $outputBox.AppendText("    * Support kontaktieren bei wiederholtem Auftreten`r`n")
                }
            }
        }

        # Log-Datei Analyse
        if (Test-Path $logPath) {
            Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Action'
            $outputBox.AppendText("`r`n[i] Log-Datei Analyse:`r`n")
            
            $lastLines = Get-Content $logPath -Tail 5
            foreach ($line in $lastLines) {
                if ($line -match "Error|Failed|Exception") {
                    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Error'
                    $outputBox.AppendText("    [!] $line`r`n")
                }
                elseif ($line -match "Warning") {
                    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Warning'
                    $outputBox.AppendText("    [!] $line`r`n")
                }
                elseif ($line -match "Success|Complete") {
                    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Success'
                    $outputBox.AppendText("    [✓] $line`r`n")
                }
            }
        }

        # Abschluss
        Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Action'
        $outputBox.AppendText("`r`n[i] Scan abgeschlossen um $(Get-Date -Format 'HH:mm:ss')`r`n")
        Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Default'
        $outputBox.AppendText("=".PadRight(60, "=") + "`r`n")
        
        Write-Host
        Write-Host "`n" + ("═" * 70) -ForegroundColor Cyan
        Write-Host
        Write-Host "     Scan abgeschlossen um $(Get-Date -Format 'HH:mm:ss')" -ForegroundColor Yellow
        Write-Host
        Write-Host "`n" + ("═" * 70) -ForegroundColor Cyan
        Write-Host

        return $exitCode
    }
    catch {
        Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Error'
        $outputBox.AppendText("`r`n[-] FEHLER: $_`r`n")
        return -1
    }
    finally {
        # Fortschritt abschließen
        $progressBar.Value = 100
    }
}
# ----------------------------------------------------------------------------------------------------------------------------------------------------------
# Function to run MRT Full Scan
function Start-FullMRT {
    param (
        [System.Windows.Forms.RichTextBox]$outputBox,
        [System.Windows.Forms.ProgressBar]$progressBar
    )
    
    Clear-Host
    
    # Stelle sicher, dass die ProgressBar initialisiert ist
    if ($null -ne $progressBar) {
        Initialize-ProgressComponents -ProgressBar $progressBar -StatusLabel $null
    }
    
    # In Log-Datei und Datenbank schreiben, dass der Full MRT Scan startet
    Write-ToolLog -ToolName "FullMRT" -Message "Full MRT Scan wird gestartet" -OutputBox $outputBox -Style 'Action' -Level "Information" -SaveToDatabase
    
    # Essentielle Informationen sammeln
    #$computerName = $env:COMPUTERNAME
    #$userName = $env:USERNAME
    #$osInfo = (Get-CimInstance -ClassName Win32_OperatingSystem).Caption
    #$dateTime = Get-Date -Format "dd.MM.yyyy HH:mm:ss"
    
    # Rahmen oben
    Write-Host "╠══════════════════════════════════════════════════════════════════════════════╣" -ForegroundColor Green
    Write-ColoredCenteredText                          "Malware Removal Tool    "
    Write-Host "╚══════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Green
    
    # ASCII-Art Logo
    Write-Host
    Write-Host
    Write-Host ' 8888888888            888   888      888b     d888  8888888b.  88888888888 ' -ForegroundColor Cyan
    Write-Host ' 888                   888   888      8888b   d8888  888   Y88b     888     ' -ForegroundColor Blue
    Write-Host ' 888                   888   888      88888b.d88888  888    888     888     ' -ForegroundColor Cyan
    Write-Host ' 8888888   888   888   888   888      888Y88888P888  888   d88P     888     ' -ForegroundColor Blue
    Write-Host ' 888       888   888   888   888      888 Y888P 888  8888888P"      888     ' -ForegroundColor Cyan
    Write-Host ' 888       888   888   888   888      888  Y8P  888  888 T88b       888     ' -ForegroundColor Blue
    Write-Host ' 888       Y88b  888   888   888      888   "   888  888  T88b      888     ' -ForegroundColor Cyan
    Write-Host ' 888        "Y888888   888   888      888       888  888   T88b     888     ' -ForegroundColor Blue
    Write-Host
    Write-Host
    
    # Rahmen für Systeminformationen
    Write-Host "╔══════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-ColoredCenteredText                                  "INFORMATIONEN"
    Write-Host "╠══════════════════════════════════════════════════════════════════════════════╣" -ForegroundColor Green
    # Systeminformationen
    Write-Host "║                                                                              ║" -ForegroundColor Green
    Write-Host "  ├─  Umfassender Sicherheitscheck mit dem MRT:                                  " -ForegroundColor DarkYellow
    Write-Host "  ├─  Der vollständige Scan durchsucht alle Dateien und Speicherorte.            " -ForegroundColor DarkYellow                                    
    Write-Host "  ├─  Er bietet maximale Sicherheit, kann aber längere Zeit in Anspruch nehmen.  " -ForegroundColor DarkYellow                                    
    Write-Host "  └─  Empfohlen bei Verdacht auf Schadsoftware oder zur gründlichen Kontrolle.   " -ForegroundColor DarkYellow
    Write-Host "║                                                                              ║" -ForegroundColor Green

    Write-Host "╠══════════════════════════════════════════════════════════════════════════════╣" -ForegroundColor Green
    Write-ColoredCenteredText                          "Starte Full MRT Scan..."
    Write-Host "╚══════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Green
    
    # 3 Sekunden warten vor dem Start
    Start-Sleep -Seconds 3
    
    # outputBox zuruecksetzen
    $outputBox.Clear()
    
    # Header für den Scan
    try {
        Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Action'
        $outputBox.AppendText("`r`n===== MICROSOFT MALICIOUS SOFTWARE REMOVAL TOOL (MRT) =====`r`n")
        Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Default'
        $outputBox.AppendText("Modus: Full Scan`r`n")
        Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Default'
        $outputBox.AppendText("Zeitstempel: $(Get-Date -Format 'dd.MM.yyyy HH:mm:ss')`r`n`r`n")
        
        Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Action'
        $outputBox.AppendText("[>] Windows-Fenster für MRT Full Scan wird geöffnet...`r`n")
    }
    catch {
        Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Error'
        $outputBox.AppendText("`r`n[-] FEHLER: $_`r`n")
        return -1
    }
    
    Write-Host
    Write-Host
    Write-Host "     [►] Bitte warten bis der Scan abgeschlossen ist !!!" -ForegroundColor Blue
    Write-Host
    Write-Host "`n" + ("═" * 70) -ForegroundColor Cyan 
    Write-Host
    Write-Host "     [>] Windows-Fenster für MRT Full Scan wird geöffnet... " -ForegroundColor $secondaryColor
    Write-Host "     [►] Bitte starten Sie den Scan im Dialog-Fenster ... " -ForegroundColor Blue
    Write-Host
    
    # Exitcode-Variable initialisieren
    $exitCode = $null
    
    # MRT-Prozess starten und Exit-Code erfassen
    try {
        # Timer starten, um einen Timeout zu ermöglichen
        $timeoutSeconds = 3600  # 1 Stunde Timeout
        
        # MRT mit Timeout starten
        $mrtProcess = Start-Process -FilePath "mrt.exe" -ArgumentList "/F" -NoNewWindow -PassThru
        
        # Auf Prozessende warten mit Timeout
        $processExited = $mrtProcess.WaitForExit($timeoutSeconds * 1000)
        
        if (-not $processExited) {
            # Prozess hängt sich auf, wir beenden ihn
            Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Error'
            $outputBox.AppendText("MRT Full Scan hängt sich auf. Der Prozess wird beendet.`r`n")
            
            # Prozess beenden
            try {
                $mrtProcess.Kill()
                $outputBox.AppendText("MRT-Prozess wurde beendet.`r`n")
                $exitCode = -1  # Benutzerdefinierter Code für Timeout
            } 
            catch {
                $outputBox.AppendText("Fehler beim Beenden des MRT-Prozesses: $_`r`n")
                $exitCode = -2  # Benutzerdefinierter Code für Fehler beim Beenden
            }
            
            if ($null -ne $progressBar) {
                Update-ProgressStatus -StatusText "MRT Full Scan abgebrochen (Timeout nach $timeoutSeconds Sekunden)" -ProgressValue 0 -TextColor ([System.Drawing.Color]::Red) -progressBarParam $progressBar
            }
        }
        else {
            # Prozess hat normal beendet
            $exitCode = $mrtProcess.ExitCode
            # Wenn Exit-Code leer oder null ist, könnte es ein Abbruch durch den Cancel-Button sein
            if ([string]::IsNullOrEmpty($exitCode) -or ($exitCode -eq $null)) {
                $exitCode = 2  # Wir setzen den exitCode auf 2, um anzuzeigen, dass der Benutzer abgebrochen hat
                # Keine sofortige Ausgabe, wird über switch-Statement später ausgegeben
            }
        }
    }
    catch {
        Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Error'
        $outputBox.AppendText("Fehler beim Starten des MRT Full Scans: $_`r`n")
        $exitCode = -3  # Benutzerdefinierter Code für Startfehler
        
        if ($null -ne $progressBar) {
            Update-ProgressStatus -StatusText "Fehler beim Starten des MRT Full Scans" -ProgressValue 0 -TextColor ([System.Drawing.Color]::Red) -progressBarParam $progressBar
        }    
    }
    # Ergebnis in die Log-Datei schreiben
    try {
        # Debug-Eintrag für Nachverfolgung (nur in Log-Datei, nicht in UI)
        Write-ToolLog -ToolName "FullMRT" -Message "Debug: MRT Full-Scan beendet mit Exit-Code: $exitCode" -OutputBox $null -Level "Information" -SaveToDatabase
        
        # Ergebnismeldung basierend auf Exit-Code generieren
        $resultMessage = switch ($exitCode) {
            0 { "Full MRT Scan erfolgreich abgeschlossen. Keine Malware gefunden." }
            1 { "Full MRT Scan abgeschlossen. Malware wurde gefunden und entfernt." }
            2 { "Full MRT Scan wurde vom Benutzer über den Cancel-Button abgebrochen." }
            3 { "Full MRT Scan abgeschlossen. Ein Neustart ist erforderlich für MRT-Initialisierung." }
            7 { "Full MRT Scan abgeschlossen. Keine Administratorrechte." }
            8 { "Full MRT Scan abgeschlossen. System-Neustart erforderlich." }
            9 { "Full MRT Scan abgeschlossen. Schwerwiegende Malware gefunden." }
            -1 { "Full MRT Scan wurde wegen Timeout abgebrochen." }
            -2 { "Full MRT Scan konnte nicht beendet werden." }
            -3 { "Full MRT Scan konnte nicht gestartet werden." }
            $null { "Full MRT Scan abgeschlossen. Exit-Code konnte nicht erfasst werden." }
            default { "Full MRT Scan mit Exit-Code $exitCode beendet." }
        }
        
        # Ergebnis in die Log-Datei schreiben
        Write-ToolLog -ToolName "FullMRT" -Message $resultMessage -OutputBox $null -Level "Information" -SaveToDatabase
        
        # Timestamp für Log-Dateien
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        
        # Zusätzlicher Fallback: direkt mit IO.File
        try {
            $logFilePath = Join-Path $env:LOCALAPPDATA "BockisSystemTool\Logs\FullMRT.log"
            $logEntry = "$timestamp - [INFO] $resultMessage"
            
            # Direktes Schreiben als zusätzliche Sicherheit mit Cloud-Fehlerbehandlung
            try {
                [System.IO.File]::AppendAllText($logFilePath, "$logEntry`r`n", [System.Text.Encoding]::UTF8)
            }
            catch {
                # Prüfe auf Cloud-Provider-Fehler
                $errorMsg = $_.Exception.Message
                if ($errorMsg -notmatch "Clouddateianbieter|cloud file provider|STATUS_CLOUD_FILE_PROVIDER_NOT_RUNNING") {
                    # Nur bei nicht-Cloud-Fehlern eine Warnung ausgeben
                    Write-Verbose "Fehler beim Schreiben in Log-Datei: $_"
                }
            }
            
            # NEU: Für SystemInfo.psm1 - Kopiere das Log auch als mrt_full.log ins Windows debug Verzeichnis
            try {
                $winDebugDir = "$env:windir\debug"
                $mrt_full_log = "$winDebugDir\mrt_full.log"
                
                # Stelle sicher, dass das Verzeichnis existiert
                if (-not (Test-Path $winDebugDir)) {
                    New-Item -Path $winDebugDir -ItemType Directory -Force | Out-Null
                }
                
                # Schreibe die Log-Datei
                [System.IO.File]::WriteAllText($mrt_full_log, "$timestamp - $resultMessage`r`n", [System.Text.Encoding]::UTF8)
                
                Write-Verbose "Windows Debug Log erfolgreich aktualisiert"
            }
            catch {
                Write-Verbose "Konnte Windows Debug Log nicht aktualisieren: $_"
            }
        }
        catch {
            # Prüfe auf Cloud-Provider-Fehler
            $errorMsg = $_.Exception.Message
            if ($errorMsg -notmatch "Clouddateianbieter|cloud file provider|STATUS_CLOUD_FILE_PROVIDER_NOT_RUNNING") {
                # Nur bei nicht-Cloud-Fehlern eine Ausgabe machen
                Write-Verbose "Fehler beim Schreiben des Scan-Ergebnisses: $_"
            }
        }
        
        # Wenn Malware gefunden wurde, detaillierter loggen
        if ($exitCode -eq 1 -or $exitCode -eq 9) {
            # MRT Log-Datei Pfad
            $mrtLogPath = "$env:windir\debug\mrt.log"
            
            # Versuchen, aus der MRT-Log-Datei die gefundene Malware zu extrahieren
            if (Test-Path $mrtLogPath) {
                $logContent = Get-Content $mrtLogPath -Tail 20 -ErrorAction SilentlyContinue
                $malwareFound = $logContent | Where-Object { $_ -match "Found|Gefunden|Malware|Threat|Infection" }
                
                if ($malwareFound) {
                    foreach ($malwareEntry in $malwareFound) {
                        Write-ToolLog -ToolName "FullMRT" -Message "Gefunden: $malwareEntry" -OutputBox $outputBox -Style 'Error' -Level "Warning" -SaveToDatabase
                    }
                }
                else {
                    Write-ToolLog -ToolName "FullMRT" -Message "Malware gefunden, aber keine Details verfügbar" -OutputBox $outputBox -Style 'Error' -Level "Warning" -SaveToDatabase
                }
            }
            else {
                Write-ToolLog -ToolName "FullMRT" -Message "Malware gefunden, aber MRT-Log-Datei nicht verfügbar" -OutputBox $outputBox -Style 'Error' -Level "Warning" -SaveToDatabase
            }
        }
    }
    catch {
        # Bei Fehler bei der Ergebnisprotokollierung
        Write-Host "Fehler bei der Ergebnis-Protokollierung für Full MRT Scan: $_" -ForegroundColor Red
    }
    
    # Ueberpruefen des Exit-Codes und Farbausgabe in der UI
    switch ($exitCode) {
        0 {
            Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Success'
            $outputBox.AppendText("MRT Full Scan erfolgreich abgeschlossen. Keine Bedrohungen gefunden.`r`n")
            if ($null -ne $progressBar) {
                Update-ProgressStatus -StatusText "MRT Full Scan abgeschlossen - Keine Bedrohungen gefunden" -ProgressValue 100 -TextColor ([System.Drawing.Color]::LimeGreen) -progressBarParam $progressBar
            }
        }        1 {
            Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Warning'
            $outputBox.AppendText("MRT Full Scan abgeschlossen. Es wurden Bedrohungen gefunden.`r`n")
            if ($null -ne $progressBar) {
                Update-ProgressStatus -StatusText "MRT Full Scan abgeschlossen - Bedrohungen gefunden" -ProgressValue 100 -TextColor ([System.Drawing.Color]::Orange) -progressBarParam $progressBar
            }
        }
        2 {
            Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Alert'
            $outputBox.AppendText("MRT Full Scan wurde durch Klicken des Cancel-Buttons im Dialog abgebrochen.`r`n")
            if ($null -ne $progressBar) {
                Update-ProgressStatus -StatusText "MRT Full Scan vom Benutzer abgebrochen" -ProgressValue 0 -TextColor ([System.Drawing.Color]::SaddleBrown) -progressBarParam $progressBar
            }
        }
        -1 {
            Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Error'
            $outputBox.AppendText("MRT Full Scan wurde wegen Timeout abgebrochen.`r`n")
            $outputBox.AppendText("Dies kann passieren, wenn der Scan hängen bleibt oder zu lange dauert.`r`n")
            $outputBox.AppendText("Tipp: Versuchen Sie einen Neustart und führen Sie den Scan erneut aus.`r`n")
            
            if ($null -ne $progressBar) {
                Update-ProgressStatus -StatusText "MRT Full Scan - Timeout" -ProgressValue 0 -TextColor ([System.Drawing.Color]::Red) -progressBarParam $progressBar
            }
        }
        -2 {
            Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Error'
            $outputBox.AppendText("MRT Full Scan konnte nicht beendet werden.`r`n")
            $outputBox.AppendText("Bitte starten Sie den Computer neu und versuchen Sie es erneut.`r`n")
            
            if ($null -ne $progressBar) {
                Update-ProgressStatus -StatusText "MRT Full Scan - Fehler beim Beenden" -ProgressValue 0 -TextColor ([System.Drawing.Color]::Red) -progressBarParam $progressBar
            }
        }
        -3 {
            Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Error'
            $outputBox.AppendText("MRT Full Scan konnte nicht gestartet werden.`r`n")
            $outputBox.AppendText("Überprüfen Sie, ob mrt.exe auf Ihrem System verfügbar ist.`r`n")
            
            if ($null -ne $progressBar) {
                Update-ProgressStatus -StatusText "MRT Full Scan - Startfehler" -ProgressValue 0 -TextColor ([System.Drawing.Color]::Red) -progressBarParam $progressBar
            }
        }
        default {
            Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Error'
            $outputBox.AppendText("MRT Full Scan abgeschlossen mit Exit-Code: $exitCode.`r`n")
            if ($null -ne $progressBar) {
                Update-ProgressStatus -StatusText "MRT Full Scan mit Fehlercode $exitCode beendet" -ProgressValue 0 -TextColor ([System.Drawing.Color]::Red) -progressBarParam $progressBar
            }
        }
    }
    
    # Exit-Code zurückgeben für weitere Verarbeitung im aufrufenden Code
    return $exitCode
}

# Function to run Memory Diagnostic




function Start-MemoryDiagnostic {
    param (
        [System.Windows.Forms.RichTextBox]$outputBox,
        [System.Windows.Forms.ProgressBar]$progressBar
    )
    Clear-Host
    # Stelle sicher, dass die ProgressBar initialisiert ist
    if ($null -ne $progressBar) {
        try {
            # ProgressBar-Eigenschaften setzen
            $progressBar.Minimum = 0
            $progressBar.Maximum = 100
            $progressBar.Step = 1
            $progressBar.Style = [System.Windows.Forms.ProgressBarStyle]::Continuous
            $progressBar.Value = 0
        }
        catch {
            Write-Host "Warnung: ProgressBar-Initialisierung fehlgeschlagen: $_" -ForegroundColor Yellow
        }
    }
    # Rahmen oben
    Write-Host "╔══════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-ColoredCenteredText                        "WINDOWS MEMORY DIAGNOSTIC TOOL"
    Write-Host "╚══════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Green

    # ASCII-Art Logo
    Write-Host
    Write-Host
    Write-Host ' 888b     d888 8888888b.   .d8888b.   .d8888b.  888    888 8888888888 8888888b.  ' -ForegroundColor Cyan
    Write-Host ' 8888b   d8888 888  "Y88b d88P  Y88b d88P  Y88b 888    888 888        888  "Y88b ' -ForegroundColor Blue
    Write-Host ' 88888b.d88888 888    888 Y88b.      888    888 888    888 888        888    888 ' -ForegroundColor Cyan
    Write-Host ' 888Y88888P888 888    888  "Y888b.   888        8888888888 8888888    888    888 ' -ForegroundColor Blue
    Write-Host ' 888 Y888P 888 888    888     "Y88b. 888        888    888 888        888    888 ' -ForegroundColor Cyan
    Write-Host ' 888  Y8P  888 888    888       "888 888    888 888    888 888        888    888 ' -ForegroundColor Blue
    Write-Host ' 888   "   888 888  .d88P Y88b  d88P Y88b  d88P 888    888 888        888  .d88P ' -ForegroundColor Cyan
    Write-Host ' 888       888 8888888P"   "Y8888P"   "Y8888P"  888    888 8888888888 8888888P"  ' -ForegroundColor Blue
    Write-Host
    Write-Host
    # Rahmen für Systeminformationen
    Write-Host "╔══════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-ColoredCenteredText                             "INFORMATIONEN"
    Write-Host "╠══════════════════════════════════════════════════════════════════════════════╣" -ForegroundColor Green
    # Systeminformationen
    Write-Host "║                                                                              ║" -ForegroundColor Green
    Write-Host "  ├─  Arbeitsspeicher mit MDSCHED überprüfen:                                     " -ForegroundColor Yellow                 
    Write-Host "  ├─  Die Speicherdiagnose testet den RAM auf Fehler und Stabilität.              " -ForegroundColor Yellow                                    
    Write-Host "  ├─  Ein Neustart ist erforderlich, der Scan läuft vor dem Systemstart.          " -ForegroundColor Yellow                                    
    Write-Host "  └─  Empfohlen bei häufigen Abstürzen oder Verdacht auf Hardwareprobleme.        " -ForegroundColor Yellow                                  
    Write-Host "║                                                                              ║" -ForegroundColor Green

    Write-Host "╠══════════════════════════════════════════════════════════════════════════════╣" -ForegroundColor Green
    Write-ColoredCenteredText                    "Starte Windows Memory Diagnostic Tool..."
    Write-Host "╚══════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Green

    # 3 Sekunden warten vor dem Start
    Start-Sleep -Seconds 3

    # In Log-Datei und Datenbank schreiben, dass Memory Diagnostic gestartet wird
    Write-ToolLog -ToolName "MemoryDiagnostic" -Message "Windows Memory Diagnostic wird gestartet" -OutputBox $outputBox -Style 'Action' -Level "Information" -SaveToDatabase
    
    $outputBox.Clear()
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Action'
    $outputBox.AppendText("`r`n===== WINDOWS MEMORY DIAGNOSTIC =====`r`n")
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Default'
    $outputBox.AppendText("Zeitstempel: $(Get-Date -Format 'dd.MM.yyyy HH:mm:ss')`r`n`r`n")
    
    try {
        # Prüfen ob wir Administratorrechte haben
        $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
        
        if (-not $isAdmin) {
            Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Error'
            $outputBox.AppendText("[-] Fehler: Administratorrechte erforderlich!`r`n")
            Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Info'
            $outputBox.AppendText("[i] Bitte starten Sie das Tool als Administrator.`r`n")
            return
        }        # Prüfen ob ein Memory Diagnostic bereits geplant ist
        $scheduledTask = Get-ScheduledTask -TaskName "MemoryDiagnostic" -ErrorAction SilentlyContinue
        
        if ($scheduledTask) {
            Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Alert'
            $outputBox.AppendText("[!] Ein Memory Diagnostic ist bereits geplant.`r`n")
            $outputBox.AppendText("[i] Möchten Sie den geplanten Scan ausführen?`r`n")
            
            $result = [System.Windows.Forms.MessageBox]::Show(
                "Ein Memory Diagnostic ist bereits geplant.`n`nMöchten Sie den Scan jetzt ausführen?",
                "Memory Diagnostic geplant",
                [System.Windows.Forms.MessageBoxButtons]::YesNo,
                [System.Windows.Forms.MessageBoxIcon]::Question
            )
            if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
                $process = Start-Process "mdsched.exe" -NoNewWindow -PassThru
                $process.WaitForExit()
                
                if ($process.ExitCode -eq 0) {
                    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Success'
                    $outputBox.AppendText("[✓] Geplanter Memory Diagnostic wurde ausgeführt.`r`n")
                }
                else {
                    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Warning'
                    $outputBox.AppendText("[!] Geplanter Memory Diagnostic wurde abgebrochen.`r`n")
                }
                return
            }
            else {
                Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Warning'
                $outputBox.AppendText("[!] Benutzer hat die Ausführung des geplanten Scans abgelehnt.`r`n")
                return
            }
        }

        # Memory Diagnostic über die Windows API starten
        Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Success'
        $outputBox.AppendText("[+] Starte Windows Memory Diagnostic...`r`n")
        
        # Marker-Datei erstellen, um nach dem Neustart zu erkennen, dass wir die Ergebnisse prüfen sollen
        $markerFile = "$env:TEMP\memory_diagnostic_marker.txt"
        Set-Content -Path $markerFile -Value (Get-Date -Format "yyyy-MM-dd HH:mm:ss")        # Memory Diagnostic starten und Prozess überwachen
        $outputBox.AppendText("[►] Starte Memory Diagnostic Dialog...`r`n")
        
        # Sofortige Ausgabe in der PowerShell-Konsole vor dem Start des Dialogs
        Write-Host
        Write-Host
        Write-Host "     [►] Memory Diagnostic wurde gestartet..." -ForegroundColor Blue
        Write-Host
        Write-Host "`n" + ("═" * 70) -ForegroundColor Cyan 
        Write-Host
        Write-Host "     [>] Ein Dialog-Fenster für den Speichertest wird geöffnet...... " -ForegroundColor $secondaryColor
        Write-Host
        Write-Host "     [i]Bitte bestaetigen Sie den Neustart im Windows-Dialog... " -ForegroundColor Blue
        Write-Host
        
        # Starte mdsched.exe und warte auf das Ergebnis
        $process = Start-Process "mdsched.exe" -NoNewWindow -PassThru
        
        # Warte kurz, damit der Dialog erscheinen kann
        Start-Sleep -Milliseconds 500
        
        # Überwache den Prozess
        $outputBox.AppendText("[i] Memory Diagnostic Dialog geöffnet. Warte auf Benutzerentscheidung...`r`n")        # Warte auf das Ende des Prozesses
        $process.WaitForExit()
        
        # Prüfe den Exit-Code
        $exitCode = $process.ExitCode
        # Behandle verschiedene Exit-Code-Szenarien
        if ($null -eq $exitCode) {
            Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Alert'
            $outputBox.AppendText("Memory Diagnostic wurde durch Klicken des Cancel-Buttons im Dialog abgebrochen.`r`n")
            
            # Ausgabe in PowerShell für Cancel
            Write-Host
            Write-Host "     [!] Memory Diagnostic wurde durch Cancel-Button abgebrochen" -ForegroundColor Yellow
            Write-Host "     [i] Kein Speichertest geplant" -ForegroundColor Gray
            Write-Host
            Write-Host "`n" + ("═" * 70) -ForegroundColor Yellow
            Write-Host
            # ProgressBar-Status für Abbruch setzen - direkter Zugriff
            if ($null -ne $progressBar) {
                try {
                    $progressBar.Value = 0
                    $progressBar.Style = [System.Windows.Forms.ProgressBarStyle]::Continuous
                    if ($progressBar.GetType().GetProperty("CustomText")) {
                        $progressBar.CustomText = "Memory Diagnostic vom Benutzer abgebrochen"
                    }
                    if ($progressBar.GetType().GetProperty("TextColor")) {
                        $progressBar.TextColor = [System.Drawing.Color]::SaddleBrown
                    }
                    $progressBar.Refresh()
                }
                catch {
                    # Fallback: Update-ProgressStatus verwenden
                    Update-ProgressStatus -StatusText "Memory Diagnostic vom Benutzer abgebrochen" -ProgressValue 0 -TextColor ([System.Drawing.Color]::SaddleBrown) -progressBarParam $progressBar
                }
            }
            
            # Log-Eintrag für Abbruch
            Write-ToolLog -ToolName "MemoryDiagnostic" -Message "Memory Diagnostic wurde durch Cancel-Button abgebrochen" -OutputBox $outputBox -Style 'Alert' -Level "Warning" -SaveToDatabase
        }
        else {
            switch ($exitCode) {
                0 {
                    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Success'
                    $outputBox.AppendText("[✓] Memory Diagnostic wurde erfolgreich geplant.`r`n")
                    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Info'
                    $outputBox.AppendText("[i] Der Speichertest wird beim nächsten Neustart ausgeführt.`r`n")
                    # Ausgabe auch in der PowerShell-Konsole für Erfolg
                    Write-Host
                    Write-Host "     [✓] Memory Diagnostic wurde erfolgreich geplant" -ForegroundColor Green
                    Write-Host "     [i] Der Speichertest wird beim nächsten Neustart ausgeführt" -ForegroundColor Green
                    Write-Host
                    Write-Host "`n" + ("═" * 70) -ForegroundColor Green
                    Write-Host
                
                    # ProgressBar-Status für Erfolg setzen
                    if ($null -ne $progressBar) {
                        try {
                            $progressBar.Value = 100
                            $progressBar.Style = [System.Windows.Forms.ProgressBarStyle]::Continuous
                            if ($progressBar.GetType().GetProperty("CustomText")) {
                                $progressBar.CustomText = "Memory Diagnostic erfolgreich geplant"
                            }
                            if ($progressBar.GetType().GetProperty("TextColor")) {
                                $progressBar.TextColor = [System.Drawing.Color]::LimeGreen
                            }
                            $progressBar.Refresh()
                        }
                        catch {
                            # Fallback: Update-ProgressStatus verwenden
                            Update-ProgressStatus -StatusText "Memory Diagnostic erfolgreich geplant" -ProgressValue 100 -TextColor ([System.Drawing.Color]::LimeGreen) -progressBarParam $progressBar
                        }
                    }
                
                    # Log-Eintrag für erfolgreiche Planung
                    Write-ToolLog -ToolName "MemoryDiagnostic" -Message "Memory Diagnostic erfolgreich geplant" -OutputBox $outputBox -Style 'Success' -Level "Information" -SaveToDatabase
                } { $_ -in @(1, 2, 3, 1223, -1073741510, -1073741819, 1, 0xC000013A, 0xC0000005) } {
                    # Verschiedene Exit-Codes für Abbruch/Cancel
                    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Alert'
                    $outputBox.AppendText("Memory Diagnostic wurde durch Klicken des Cancel-Buttons im Dialog abgebrochen.`r`n")
                
                    # Ausgabe auch in der PowerShell-Konsole für Abbruch (wie bei MRT)
                    Write-Host
                    Write-Host "     [!] Memory Diagnostic wurde durch Cancel-Button abgebrochen" -ForegroundColor Yellow
                    Write-Host "     [i] Kein Speichertest geplant" -ForegroundColor Gray
                    Write-Host
                    Write-Host "`n" + ("═" * 70) -ForegroundColor Cyan
                    Write-Host
                
                    # ProgressBar-Status für Abbruch setzen
                    if ($null -ne $progressBar) {
                        Update-ProgressStatus -StatusText "Memory Diagnostic vom Benutzer abgebrochen" -ProgressValue 0 -TextColor ([System.Drawing.Color]::SaddleBrown) -progressBarParam $progressBar
                    }
                
                    # Log-Eintrag für Abbruch
                    Write-ToolLog -ToolName "MemoryDiagnostic" -Message "Memory Diagnostic wurde durch Cancel-Button abgebrochen (Exit-Code: $exitCode)" -OutputBox $outputBox -Style 'Alert' -Level "Warning" -SaveToDatabase
                }
                default {
                    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Error'
                    $outputBox.AppendText("[-] Unerwarteter Exit-Code: $exitCode`r`n")
                
                    # Ausgabe auch in der PowerShell-Konsole für unerwartete Codes
                    Write-Host
                    Write-Host "     [-] Unerwarteter Exit-Code: $exitCode" -ForegroundColor Red
                    Write-Host "     [i] Bitte prüfen Sie die Systemkonfiguration" -ForegroundColor Gray
                    Write-Host
                    Write-Host "`n" + ("═" * 70) -ForegroundColor Red
                    Write-Host
                    # Log-Eintrag für unerwarteten Exit-Code
                    Write-ToolLog -ToolName "MemoryDiagnostic" -Message "Unerwarteter Exit-Code: $exitCode" -OutputBox $outputBox -Style 'Error' -Level "Warning" -SaveToDatabase
                }
            }
        } # Ende der if-else Struktur für null-Check
    }
    catch {
        $errorMessage = "Fehler beim Starten des Memory Diagnostics: $_"
        Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Error'
        $outputBox.AppendText("[-] $errorMessage`r`n")
        
        # Log-Eintrag für Fehler
        Write-ToolLog -ToolName "MemoryDiagnostic" -Message $errorMessage -OutputBox $null -Style 'Error' -Level "Error" -SaveToDatabase
    }
    finally {
        # ProgressBar NICHT zurücksetzen, damit die Abbruch-/Erfolgs-Meldung sichtbar bleibt
        # Das finally-Block bleibt leer oder kann für andere Cleanup-Aufgaben verwendet werden
    }
}

# Neue Funktion zum Prüfen der Memory Diagnostic Ergebnisse
function Get-MemoryDiagnosticResults {
    param (
        [System.Windows.Forms.RichTextBox]$outputBox
    )
    
    # Log-Eintrag erstellen
    Write-ToolLog -ToolName "MemoryDiagnostic" -Message "Prüfe Memory Diagnostic Ergebnisse" -OutputBox $outputBox -Style 'Action' -Level "Information" -SaveToDatabase
    
    try {
        # Prüfen ob wir Administratorrechte haben
        $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
        
        if (-not $isAdmin) {
            $errorMessage = "Administratorrechte erforderlich für Memory Diagnostic Ergebnisse"
            Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Error'
            $outputBox.AppendText("[-] Fehler: $errorMessage`r`n")
            
            # Log-Eintrag für Fehler
            Write-ToolLog -ToolName "MemoryDiagnostic" -Message $errorMessage -OutputBox $null -Style 'Error' -Level "Error" -SaveToDatabase
            return
        }

        # Event Log nach Memory Diagnostic Ergebnissen durchsuchen
        $events = Get-WinEvent -FilterHashtable @{
            LogName      = 'System'
            ProviderName = 'Microsoft-Windows-MemoryDiagnostics-Results'
        } -MaxEvents 1 -ErrorAction SilentlyContinue

        if ($events) {
            Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Action'
            $outputBox.AppendText("`r`n[i] Memory Diagnostic Ergebnisse:`r`n")
            
            foreach ($event in $events) {
                Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Default'
                $outputBox.AppendText("Zeitpunkt: $($event.TimeCreated)`r`n")
                # Ergebnis auswerten
                if ($event.Properties[0].Value -eq 0) {
                    $resultMessage = "Keine Speicherprobleme gefunden"
                    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Success'
                    $outputBox.AppendText("[+] $resultMessage`r`n")
                    
                    # Log-Eintrag für erfolgreiches Ergebnis
                    Write-ToolLog -ToolName "MemoryDiagnostic" -Message $resultMessage -OutputBox $null -Style 'Success' -Level "Success" -SaveToDatabase
                }
                else {
                    $resultMessage = "Speicherprobleme wurden gefunden! Bitte überprüfen Sie Ihre RAM-Module."
                    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Error'
                    $outputBox.AppendText("[-] Speicherprobleme wurden gefunden!`r`n")
                    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Info'
                    $outputBox.AppendText("[i] Bitte überprüfen Sie Ihre RAM-Module.`r`n")
                    
                    # Log-Eintrag für Speicherprobleme
                    Write-ToolLog -ToolName "MemoryDiagnostic" -Message $resultMessage -OutputBox $null -Style 'Error' -Level "Error" -SaveToDatabase
                }
            }
        }
        else {
            $infoMessage = "Keine Memory Diagnostic Ergebnisse gefunden. Möglicherweise wurde noch kein Scan durchgeführt."
            Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Alert'
            $outputBox.AppendText("[!] Keine Memory Diagnostic Ergebnisse gefunden.`r`n")
            $outputBox.AppendText("[i] Möglicherweise wurde noch kein Scan durchgeführt.`r`n")
            
            # Log-Eintrag für fehlende Ergebnisse
            Write-ToolLog -ToolName "MemoryDiagnostic" -Message $infoMessage -OutputBox $null -Style 'Alert' -Level "Warning" -SaveToDatabase
        }
    }
    catch {
        $errorMessage = "Fehler beim Lesen der Memory Diagnostic Ergebnisse: $_"
        Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Error'
        $outputBox.AppendText("[-] $errorMessage`r`n")
        
        # Log-Eintrag für Fehler
        Write-ToolLog -ToolName "MemoryDiagnostic" -Message $errorMessage -OutputBox $null -Style 'Error' -Level "Error" -SaveToDatabase
    }
}
# ----------------------------------------------------------------------------------------------------------------------------------------------------------
# Funktion zum Starten des System File Checkers (SFC)
# Diese Funktion führt den System File Checker (SFC) Scan durch und gibt die Ergebnisse in einem RichTextBox-Element aus.
# SFC (System File Checker) Funktion
#-----------------------------------------------------------------------------------------------------------------------------------------------------------
function Start-SFCCheck {
    param(
        [System.Windows.Forms.RichTextBox]$outputBox,
        [System.Windows.Forms.ProgressBar]$progressBar
    )
    Clear-Host
    # outputBox zuruecksetzen
    $outputBox.Clear()
    # Stelle sicher, dass die ProgressBar initialisiert ist
    Ensure-ProgressBarInitialized -ProgressBar $progressBar
    
    # In Log-Datei und Datenbank schreiben, dass der Scan startet
    Write-ToolLog -ToolName "SFCCheck" -Message "System File Checker wird gestartet" -OutputBox $outputBox -Style 'Action' -Level "Information" -SaveToDatabase
    
    # Rahmen und Systeminformationen erstellen
    #$computerName = $env:COMPUTERNAME
    #$userName = $env:USERNAME
    #$osInfo = (Get-CimInstance -ClassName Win32_OperatingSystem).Caption
    #$dateTime = Get-Date -Format "dd.MM.yyyy HH:mm:ss"
    #$width = 80
    
    # Rahmen oben
    Write-Host "╔══════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-ColoredCenteredText                             "SYSTEM FILE CHECKER"
    Write-Host "╚══════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Green

    # ASCII-Art Logo
    Write-Host
    Write-Host
    Write-Host '  .d8888b.  888                     888         .d8888b.  8888888888 .d8888b.  ' -ForegroundColor Cyan
    Write-Host ' d88P  Y88b 888                     888        d88P  Y88b 888       d88P  Y88b ' -ForegroundColor Blue
    Write-Host ' Y88b.      888                     888        Y88b.      888       888    888 ' -ForegroundColor Cyan
    Write-Host ' Y88b.      888                     888        Y88b.      888       888    888 ' -ForegroundColor Cyan
    Write-Host '  "Y888b.   888888  8888b.  888d888 888888      "Y888b.   8888888   888        ' -ForegroundColor Blue
    Write-Host '     "Y88b. 888        "88b 888P"   888            "Y88b. 888       888        ' -ForegroundColor Cyan
    Write-Host '       "888 888    .d888888 888     888              "888 888       888    888 ' -ForegroundColor Cyan
    Write-Host ' Y88b  d88P Y88b.  888  888 888     Y88b.      Y88b  d88P 888       Y88b  d88P ' -ForegroundColor Blue
    Write-Host '  "Y8888P"   "Y888 "Y888888 888      "Y888      "Y8888P"  888        "Y8888P"  ' -ForegroundColor Blue
    Write-Host
    Write-Host
    # Rahmen für Systeminformationen
    Write-Host "╔══════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-ColoredCenteredText                             "SYSTEMINFORMATIONEN"
    Write-Host "╠══════════════════════════════════════════════════════════════════════════════╣" -ForegroundColor Green
    # Systeminformationen
    Write-Host "║                                                                              ║" -ForegroundColor Green
    Write-Host "  ├─    Systemdateien mit SFC prüfen und reparieren:                              " -ForegroundColor Yellow                 
    Write-Host "  ├─    Der Scan erkennt beschädigte oder fehlende Windows-Systemdateien.         " -ForegroundColor Yellow                                    
    Write-Host "  ├─    Gefundene Fehler werden automatisch repariert, wenn möglich.              " -ForegroundColor Yellow                                    
    Write-Host "  └─    Empfohlen bei Systemfehlern oder ungewöhnlichem Verhalten.                " -ForegroundColor Yellow                                  
    Write-Host "║                                                                              ║" -ForegroundColor Green

    Write-Host "╠══════════════════════════════════════════════════════════════════════════════╣" -ForegroundColor Green
    Write-ColoredCenteredText                             "Starte System File Checker..."
    Write-Host "╚══════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Green

    # 3 Sekunden warten vor dem Start von SFC
    Start-Sleep -Seconds 3
    
    # Header für den SFC-Scan
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Action'
    $outputBox.AppendText("`r`n===== SYSTEM FILE CHECKER (SFC) =====`r`n")
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Default'
    $outputBox.AppendText("Zeitstempel: $(Get-Date -Format 'dd.MM.yyyy HH:mm:ss')`r`n`r`n")
    
    try {
        # Fortschritt initialisieren
        if ($progressBar) {
            $progressBar.Value = 10
            $progressBar.CustomText = "SFC Scan wird initialisiert..."
            $progressBar.TextColor = [System.Drawing.Color]::White
        }
        # Scan-Start Meldung in OutputBox
        Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Action'
        $outputBox.AppendText("[►] SFC /scannow wird gestartet...`r`n")
        Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Action'
        $outputBox.AppendText("[►] Bitte warten Sie, während die Systemdateien überprüft werden...`r`n`r`n")
        
        Write-Host "`n[►] Starte SFC /scannow..." -ForegroundColor Blue
        # Dynamische Fortschrittsanzeige für den SFC-Scan initialisieren
        if ($progressBar) {
            $progressBar.Value = 5
            $progressBar.CustomText = "SFC-Scan wird vorbereitet..."
            $progressBar.TextColor = [System.Drawing.Color]::White
        }
        
        # Phasen des SFC-Scans definieren
        $scanPhases = @(
            @{ Name = "Überprüfung wird initialisiert"; Progress = 10; Color = [System.Drawing.Color]::White; TimeWeight = 0.1 },
            @{ Name = "Überprüfung der Windows-Ressourcenschutz-Datenbank"; Progress = 25; Color = [System.Drawing.Color]::Blue; TimeWeight = 0.15 },
            @{ Name = "Überprüfung von Systemdateien"; Progress = 40; Color = [System.Drawing.Color]::Blue; TimeWeight = 0.3 },
            @{ Name = "Verifizierung beschädigter Dateien"; Progress = 60; Color = [System.Drawing.Color]::White; TimeWeight = 0.2 },
            @{ Name = "Reparatur von Systemdateien"; Progress = 75; Color = [System.Drawing.Color]::DarkGreen; TimeWeight = 0.15 },
            @{ Name = "Abschließende Überprüfungen"; Progress = 90; Color = [System.Drawing.Color]::LimeGreen; TimeWeight = 0.1 }
        )
        
        # Startzeit für Zeitberechnung
        $startTime = Get-Date
        
        # Geschätzte Scan-Dauer (ca. 5-10 Minuten für SFC /scannow)
        $estimatedDuration = New-TimeSpan -Minutes 7
        
        # Prozess starten mit Ausgabenumleitung
        $process = New-Object System.Diagnostics.Process
        $process.StartInfo.FileName = "sfc.exe"
        $process.StartInfo.Arguments = "/scannow"
        $process.StartInfo.UseShellExecute = $false
        $process.StartInfo.RedirectStandardOutput = $true
        $process.StartInfo.RedirectStandardError = $true
        $process.StartInfo.CreateNoWindow = $true
        
        # Event-Handler für die Ausgabe
        $outputSB = New-Object System.Text.StringBuilder
        $outputHandler = { 
            if (![String]::IsNullOrEmpty($EventArgs.Data)) { 
                $outputSB.AppendLine($EventArgs.Data) 
            } 
        }
        $errorHandler = { 
            if (![String]::IsNullOrEmpty($EventArgs.Data)) { 
                $outputSB.AppendLine("FEHLER: " + $EventArgs.Data) 
            } 
        }
        
        # Events registrieren
        $outputEvent = Register-ObjectEvent -InputObject $process -EventName OutputDataReceived -Action $outputHandler
        $errorEvent = Register-ObjectEvent -InputObject $process -EventName ErrorDataReceived -Action $errorHandler
        
        # Prozess starten und Ausgabe sammeln
        $process.Start() | Out-Null
        $process.BeginOutputReadLine()
        $process.BeginErrorReadLine()
        
        # Animationszeichen für Fortschritt
        $progressChars = @('|', '/', '-', '\')
        $progressIndex = 0
        $currentPhase = -1
        
        # Gewichtete Phasenintervalle berechnen
        $totalWeight = 0
        foreach ($phase in $scanPhases) {
            $totalWeight += $phase.TimeWeight
        }
        
        $phaseIntervals = @()
        $cumulativeTime = 0
        
        foreach ($phase in $scanPhases) {
            $intervalSeconds = ($phase.TimeWeight / $totalWeight) * $estimatedDuration.TotalSeconds
            $cumulativeTime += $intervalSeconds
            $phaseIntervals += $cumulativeTime
        }
        # Fortschrittsanzeige: Scan wird gestartet
        Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Action'
        $outputBox.AppendText("[►] SFC-Scan wurde gestartet. Die Überprüfung kann einige Minuten dauern...`r`n")
        Write-Host "[►] SFC-Scan läuft | Dauer: 00:00 " -NoNewline -ForegroundColor Blue
        
        # Fortlaufend den Prozessstatus überprüfen
        while (-not $process.HasExited) {
            # Dauer berechnen und anzeigen
            $elapsedTime = (Get-Date) - $startTime
            $formattedTime = "{0:mm}:{0:ss}" -f $elapsedTime
            
            # Animations-Fortschrittszeichen rotieren
            $progressChar = $progressChars[$progressIndex]
            $progressIndex = ($progressIndex + 1) % $progressChars.Length
            # Aktuelle Konsolenzeile aktualisieren
            Write-Host "`r[►] SFC-Scan läuft $progressChar Dauer: $formattedTime " -NoNewline -ForegroundColor Blue
            
            # Aktuelle Phase basierend auf der verstrichenen Zeit berechnen
            $timeProgress = $elapsedTime.TotalSeconds
            $expectedPhase = -1
            
            for ($i = 0; $i -lt $phaseIntervals.Count; $i++) {
                if ($timeProgress -le $phaseIntervals[$i]) {
                    $expectedPhase = $i
                    break
                }
            }
            
            # Wenn wir über alle definierten Intervalle hinaus sind, bleiben wir bei der letzten Phase
            if ($expectedPhase -eq -1) {
                $expectedPhase = $scanPhases.Count - 1
            }
            # Aktualisiere die Phase wenn nötig
            if ($expectedPhase -gt $currentPhase) {
                $currentPhase = $expectedPhase
                Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Action'
                $outputBox.AppendText("[►] Phase: $($scanPhases[$currentPhase].Name)`r`n")
                Write-Host "`r   ├─ Phase: $($scanPhases[$currentPhase].Name)" -ForegroundColor Blue
                
                # Fortschrittsbalken aktualisieren
                if ($progressBar) {
                    Update-ProgressStatus -StatusText "SFC-Scan: $($scanPhases[$currentPhase].Name)" `
                        -ProgressValue $scanPhases[$currentPhase].Progress `
                        -TextColor $scanPhases[$currentPhase].Color `
                        -progressBarParam $progressBar
                }
            }
            
            # Feineren Fortschritt innerhalb einer Phase berechnen
            if ($currentPhase -lt $scanPhases.Count - 1) {
                $phaseStartTime = if ($currentPhase -eq 0) { 0 } else { $phaseIntervals[$currentPhase - 1] }
                $phaseEndTime = $phaseIntervals[$currentPhase]
                $phaseDuration = $phaseEndTime - $phaseStartTime
                $phaseElapsedTime = $timeProgress - $phaseStartTime
                
                if ($phaseDuration -gt 0) {
                    $phaseProgress = [Math]::Min($phaseElapsedTime / $phaseDuration, 1.0)
                    $prevProgress = if ($currentPhase -eq 0) { 0 } else { $scanPhases[$currentPhase - 1].Progress }
                    $nextProgress = $scanPhases[$currentPhase].Progress
                    $currentProgress = $prevProgress + ($nextProgress - $prevProgress) * $phaseProgress
                    
                    # Fortschrittsbalken mit feinerem Fortschritt aktualisieren
                    if ($progressBar) {
                        Update-ProgressStatus -StatusText "SFC-Scan: $($scanPhases[$currentPhase].Name)" `
                            -ProgressValue ([int]$currentProgress) `
                            -TextColor $scanPhases[$currentPhase].Color `
                            -progressBarParam $progressBar
                    }
                }
            }
            
            # Aktuellen Output des SFC-Prozesses prüfen und relevante Meldungen extrahieren
            $currentOutput = $outputSB.ToString()
            if ($currentOutput -match "(\d+)% abgeschlossen") {
                $percentComplete = [int]$matches[1]
                # Den Fortschritt nur aktualisieren, wenn ein tatsächlicher Prozentsatz erkannt wurde
                if ($progressBar -and $percentComplete -gt 0) {
                    $adjustedProgress = 10 + ($percentComplete * 0.8) # Skala anpassen: 0-100% -> 10-90%
                    $progressBar.Value = [int]$adjustedProgress
                }
            }
            
            # Event-Log nach relevanten SFC-Meldungen durchsuchen
            try {
                $recentEvents = Get-WinEvent -FilterHashtable @{
                    LogName      = 'Application'; 
                    ProviderName = 'Microsoft-Windows-Resource-Exhaustion-Detector'
                } -MaxEvents 1 -ErrorAction SilentlyContinue
                
                if ($recentEvents) {
                    foreach ($event in $recentEvents) {
                        if ($event.TimeCreated -gt $startTime) {
                            Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Alert'
                            $outputBox.AppendText("[!] System-Ereignis: $($event.Message)`r\n")
                        }
                    }
                }
            }
            catch {
                # Fehler bei der Event-Log-Abfrage ignorieren
            }
            
            Start-Sleep -Milliseconds 250
        }
        
        # Neue Zeile nach Animation
        Write-Host "" 
        
        # Ausgabe des Prozesses abrufen und analysieren
        $output = $outputSB.ToString()
        
        # Event-Handler deregistrieren
        Unregister-Event -SourceIdentifier $outputEvent.Name -ErrorAction SilentlyContinue
        Unregister-Event -SourceIdentifier $errorEvent.Name -ErrorAction SilentlyContinue
        
        # Zeige die Gesamtdauer des Scans an
        $totalScanTime = (Get-Date) - $startTime
        $formattedTotalTime = "{0:mm}:{0:ss}" -f $totalScanTime
        Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Success'
        $outputBox.AppendText("[√] SFC-Scan abgeschlossen. Gesamtdauer: $formattedTotalTime`r`n")
        Write-Host "[√] SFC-Scan abgeschlossen. Gesamtdauer: $formattedTotalTime" -ForegroundColor Green
        
        # Fortschritt aktualisieren nach Abschluss des Scans
        if ($progressBar) {
            $progressBar.Value = 95
            $progressBar.CustomText = "Analysiere SFC-Scan-Ergebnisse..."
        }
        Write-Host "`n" + ("═" * 70) -ForegroundColor Cyan
        Write-Host "`n[►] Scan-Ergebnis:" -ForegroundColor Blue
        
        Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Action'
        $outputBox.AppendText("`r`n[►] Scan-Ergebnis:`r`n")
        
        switch ($process.ExitCode) {
            0 {
                $resultMessage = "System-Dateien sind in Ordnung. Keine Reparaturen notwendig."
                Write-Host "    [✓] $resultMessage" -ForegroundColor Green
                
                # Ergebnis in die Log-Datei schreiben
                $logSuccess = $false
                try {
                    $logSuccess = Write-ToolLog -ToolName "SFCCheck" -Message $resultMessage -OutputBox $outputBox -Style 'Success' -Level "Success" -SaveToDatabase
                }
                catch {
                    $logSuccess = $false
                    Write-Host "Fehler beim Schreiben des SFC-Log-Eintrags: $_" -ForegroundColor Red
                }
                
                # Falls Standard-Logging fehlschlägt, direkten Fallback versuchen
                if (-not $logSuccess) {
                    try {
                        $logFilePath = Join-Path $env:LOCALAPPDATA "BockisSystemTool\Logs\SFCCheck.log"
                        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                        $logEntry = "$timestamp - [SUCCESS] $resultMessage"
                        
                        [System.IO.File]::AppendAllText($logFilePath, "$logEntry`r`n", [System.Text.Encoding]::UTF8)
                        Write-Host "Fallback-Logging für SFC erfolgreich" -ForegroundColor Yellow
                    }
                    catch {
                        Write-Host "Fehler beim Schreiben des SFC-Ergebnisses in die Log-Datei: $_" -ForegroundColor Red
                    }
                }
                
                Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Success'
                $outputBox.AppendText("    [✓] System-Dateien sind in Ordnung`r`n")
                Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Success'
                $outputBox.AppendText("    [✓] Keine Reparaturen notwendig`r`n")
                
                # Fortschritt aktualisieren mit positivem Ergebnis
                if ($progressBar) {
                    $progressBar.Value = 100
                    $progressBar.CustomText = "System-Dateien in Ordnung"
                    $progressBar.TextColor = [System.Drawing.Color]::LimeGreen
                }
            }
            1 {
                $resultMessage = "Beschädigte Dateien wurden gefunden und repariert. Ein Neustart wird empfohlen."
                Write-Host "    [!] $resultMessage" -ForegroundColor Orange
                
                # Ergebnis in die Log-Datei schreiben
                $logSuccess = $false
                try {
                    $logSuccess = Write-ToolLog -ToolName "SFCCheck" -Message $resultMessage -OutputBox $outputBox -Style 'Warning' -Level "Warning" -SaveToDatabase
                }
                catch {
                    $logSuccess = $false
                    Write-Host "Fehler beim Schreiben des SFC-Log-Eintrags: $_" -ForegroundColor Red
                }
                
                # Falls Standard-Logging fehlschlägt, direkten Fallback versuchen
                if (-not $logSuccess) {
                    try {
                        $logFilePath = Join-Path $env:LOCALAPPDATA "BockisSystemTool\Logs\SFCCheck.log"
                        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                        $logEntry = "$timestamp - [WARNING] $resultMessage"
                        
                        [System.IO.File]::AppendAllText($logFilePath, "$logEntry`r`n", [System.Text.Encoding]::UTF8)
                        Write-Host "Fallback-Logging für SFC erfolgreich" -ForegroundColor Yellow
                    }
                    catch {
                        Write-Host "Fehler beim Schreiben des SFC-Ergebnisses in die Log-Datei: $_" -ForegroundColor Red
                    }
                }
                
                Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Warning'
                $outputBox.AppendText("    [!] Beschädigte Dateien wurden gefunden und repariert`r`n")
                Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Warning'
                $outputBox.AppendText("    [!] Ein Neustart wird empfohlen`r`n")
                
                # Fortschritt aktualisieren mit Warnhinweis
                if ($progressBar) {
                    $progressBar.Value = 100
                    $progressBar.CustomText = "Reparaturen durchgeführt - Neustart empfohlen"
                    $progressBar.TextColor = [System.Drawing.Color]::Orange
                }
                
                # Neustart-Dialog
                $result = [System.Windows.Forms.MessageBox]::Show(
                    "Der SFC-Scan hat Reparaturen durchgeführt. Ein Neustart wird empfohlen.`n`nJetzt neu starten?",
                    "Neustart empfohlen",
                    [System.Windows.Forms.MessageBoxButtons]::YesNo,
                    [System.Windows.Forms.MessageBoxIcon]::Question
                )
                
                if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
                    Restart-Computer -Force
                }
            }
            2 {
                $resultMessage = "Beschädigte Dateien gefunden. Reparatur nicht möglich. Empfehlung: DISM-Reparatur durchführen."
                Write-Host "    [X] Beschädigte Dateien gefunden" -ForegroundColor Red
                Write-Host "    [X] Reparatur nicht möglich" -ForegroundColor Red
                Write-Host "    [►] Empfehlung: DISM-Reparatur durchführen" -ForegroundColor Yellow
                
                # Ergebnis in die Log-Datei schreiben
                $logSuccess = $false
                try {
                    $logSuccess = Write-ToolLog -ToolName "SFCCheck" -Message $resultMessage -OutputBox $outputBox -Style 'Error' -Level "Error" -SaveToDatabase
                }
                catch {
                    $logSuccess = $false
                    Write-Host "Fehler beim Schreiben des SFC-Log-Eintrags: $_" -ForegroundColor Red
                }
                
                # Falls Standard-Logging fehlschlägt, direkten Fallback versuchen
                if (-not $logSuccess) {
                    try {
                        $logFilePath = Join-Path $env:LOCALAPPDATA "BockisSystemTool\Logs\SFCCheck.log"
                        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                        $logEntry = "$timestamp - [ERROR] $resultMessage"
                        
                        [System.IO.File]::AppendAllText($logFilePath, "$logEntry`r`n", [System.Text.Encoding]::UTF8)
                        Write-Host "Fallback-Logging für SFC erfolgreich" -ForegroundColor Yellow
                    }
                    catch {
                        Write-Host "Fehler beim Schreiben des SFC-Ergebnisses in die Log-Datei: $_" -ForegroundColor Red
                    }
                }
                Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Error'
                $outputBox.AppendText("    [X] Beschädigte Dateien gefunden`r`n")
                Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Error'
                $outputBox.AppendText("    [X] Reparatur nicht möglich`r`n")
                $outputBox.AppendText("    [►] Empfehlung: DISM-Reparatur durchführen`r`n")
                
                # Fortschritt aktualisieren mit Fehlermeldung
                if ($progressBar) {
                    $progressBar.Value = 100
                    $progressBar.CustomText = "Reparatur nicht möglich - DISM empfohlen"
                    $progressBar.TextColor = [System.Drawing.Color]::Red
                }
                
                # Frage, ob DISM ausgeführt werden soll
                $result = [System.Windows.Forms.MessageBox]::Show(
                    "Beschädigte Dateien wurden gefunden, die nicht repariert werden können.`n`nMöchten Sie jetzt eine DISM-Reparatur durchführen?",
                    "DISM-Reparatur empfohlen",
                    [System.Windows.Forms.MessageBoxButtons]::YesNo,
                    [System.Windows.Forms.MessageBoxIcon]::Question
                )
                
                if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
                    # Tab Control für Ausgabe aufrufen (falls nötig)
                    $outputBox.Clear()
                    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Action'
                    $outputBox.AppendText("Starte DISM Restore Health...`r`n")
                    
                    # DISM Restore Health ausführen
                    Start-RestoreDISM -outputBox $outputBox -progressBar $progressBar
                }
            }
            default {
                $resultMessage = "Unerwarteter Fehler (Code: $($process.ExitCode)). Bitte Support kontaktieren."
                Write-Host "    [] $resultMessage" -ForegroundColor Red
                
                # Ergebnis in die Log-Datei schreiben
                $logSuccess = $false
                try {
                    $logSuccess = Write-ToolLog -ToolName "SFCCheck" -Message $resultMessage -OutputBox $outputBox -Style 'Error' -Level "Error" -SaveToDatabase
                }
                catch {
                    $logSuccess = $false
                    Write-Host "Fehler beim Schreiben des SFC-Log-Eintrags: $_" -ForegroundColor Red
                }
                
                # Falls Standard-Logging fehlschlägt, direkten Fallback versuchen
                if (-not $logSuccess) {
                    try {
                        $logFilePath = Join-Path $env:LOCALAPPDATA "BockisSystemTool\Logs\SFCCheck.log"
                        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                        $logEntry = "$timestamp - [ERROR] $resultMessage"
                        
                        [System.IO.File]::AppendAllText($logFilePath, "$logEntry`r`n", [System.Text.Encoding]::UTF8)
                        Write-Host "Fallback-Logging für SFC erfolgreich" -ForegroundColor Yellow
                    }
                    catch {
                        Write-Host "Fehler beim Schreiben des SFC-Ergebnisses in die Log-Datei: $_" -ForegroundColor Red
                    }
                }
                Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Error'
                $outputBox.AppendText("    [X] Unerwarteter Fehler (Code: $($process.ExitCode))`r`n")
                $outputBox.AppendText("    [►] Bitte Support kontaktieren`r`n")
                
                # Fortschritt aktualisieren mit Fehlermeldung
                if ($progressBar) {
                    $progressBar.Value = 100
                    $progressBar.CustomText = "Unerwarteter Fehler aufgetreten"
                    $progressBar.TextColor = [System.Drawing.Color]::Red
                }
            }
        }
    }
    catch {
        Write-Host "`n[-] FEHLER: $_" -ForegroundColor Red
        Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Error'
        $outputBox.AppendText("`r`n[-] FEHLER: $_`r`n")
        
        # Bei Fehler: ProgressBar rot einfärben
        if ($progressBar) {
            $progressBar.Value = 100
            $progressBar.CustomText = "Fehler beim Ausführen des SFC-Scans"
            $progressBar.TextColor = [System.Drawing.Color]::Red
        }
        
        return $false
    }
    finally {
        # Falls noch nicht auf 100%, jetzt abschließen
        if ($progressBar -and $progressBar.Value -ne 100) {
            $progressBar.Value = 100
            if ($progressBar.TextColor -ne [System.Drawing.Color]::Red -and 
                $progressBar.TextColor -ne [System.Drawing.Color]::Orange) {
                $progressBar.CustomText = "SFC-Scan abgeschlossen"
                $progressBar.TextColor = [System.Drawing.Color]::LimeGreen
            }
        }
        
        # Abschluss-Zeitstempel
        Write-Host "`n`t Scan beendet: $(Get-Date -Format 'dd.MM.yyyy HH:mm:ss')" -ForegroundColor Gray
        Write-Host "`n" + ("═" * 70) -ForegroundColor Cyan
        
        Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Muted'
        $outputBox.AppendText("`r`n`t Scan beendet: $(Get-Date -Format 'dd.MM.yyyy HH:mm:ss')`r`n")
        $outputBox.AppendText("═".PadRight(50, "═") + "`r`n")
    }
}

# Funktion zum Aufruf von Start-QuickMRT mit der EICAR-Testdatei
function Start-MRTTest {
    param (
        [System.Windows.Forms.RichTextBox]$outputBox,
        [System.Windows.Forms.ProgressBar]$progressBar
    )
    
    # ProgressBar initialisieren
    Initialize-ProgressComponents -ProgressBar $progressBar -StatusLabel $null
    
    # In Log-Datei und Datenbank schreiben, dass der MRT-Test gestartet wird
    Write-ToolLog -ToolName "MRTTest" -Message "MRT-Test wird vorbereitet" -OutputBox $outputBox -Style 'Action' -Level "Information" -SaveToDatabase
    
    # Verzeichnis für temporäre Dateien erstellen
    $tempDir = "$env:TEMP\MRTTest"
    if (-not (Test-Path $tempDir)) {
        New-Item -Path $tempDir -ItemType Directory -Force | Out-Null
    }
    
    # Info-Ausgabe im OutputBox
    $outputBox.Clear()
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Action'
    $outputBox.AppendText("`r`n===== MICROSOFT MALICIOUS SOFTWARE REMOVAL TOOL TEST =====`r`n")
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Default'
    $outputBox.AppendText("Zeitstempel: $(Get-Date -Format 'dd.MM.yyyy HH:mm:ss')`r`n`r`n")
    
    # Hinweis: EICAR Testdatei wird später implementiert
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Warning'
    $outputBox.AppendText("[!] EICAR-Testdatei wird später implementiert.`r`n")
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Info'
    $outputBox.AppendText("[i] Der Test wird momentan mit einem simulierten Testlauf durchgeführt.`r`n`r`n")
    
    # Simulierte MRT-Scan-Prozedur
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Action'
    $outputBox.AppendText("[>] MRT-Testlauf wird simuliert...`r`n")
    
    # Aktualisiere den Fortschritt
    if ($progressBar) {
        $progressBar.Value = 25
        Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Default'
        $progressBar.CustomText = "Testlauf wird vorbereitet..."
    }
    
    # Kurze Pause für den UI-Effekt
    Start-Sleep -Seconds 2
    
    # Aktualisiere den Fortschritt
    if ($progressBar) {
        $progressBar.Value = 50
        $progressBar.CustomText = "Testlauf wird durchgeführt..."
    }
    
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Muted'
    $outputBox.AppendText("[i] MRT-Engine wird initialisiert...`r`n")
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Muted'
    $outputBox.AppendText("[i] Systemparameter werden geprüft...`r`n")
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Muted'
    $outputBox.AppendText("[i] Malware-Datenbank wird geladen...`r`n")
    
    # Weitere kurze Pause
    Start-Sleep -Seconds 2
    
    # Aktualisiere den Fortschritt
    if ($progressBar) {
        $progressBar.Value = 75
        $progressBar.CustomText = "Testlauf wird abgeschlossen..."
    }
    
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Success'
    $outputBox.AppendText("[✓] Simulierter MRT-Testlauf abgeschlossen!`r`n`r`n")
    
    # Ergebnis der Simulation
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Action'
    $outputBox.AppendText("=== Testergebnis ===`r`n")
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Success'
    $outputBox.AppendText("[✓] Test erfolgreich durchgeführt`r`n")
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Muted'
    $outputBox.AppendText("[i] Hinweis: Für einen vollständigen Test mit EICAR-Testdatei wird eine spätere Version dieser Funktion benötigt.`r`n")
    
    # Aktualisiere den Fortschritt
    if ($progressBar) {
        $progressBar.Value = 100
        $progressBar.CustomText = "Testlauf abgeschlossen"
        $progressBar.TextColor = [System.Drawing.Color]::LimeGreen
    }
    
    # Log-Eintrag für Testabschluss
    Write-ToolLog -ToolName "MRTTest" -Message "MRT-Test erfolgreich simuliert" -OutputBox $outputBox -Style 'Success' -Level "Success" -SaveToDatabase
}

# Export functions
# Hinweis: Start-MRTTest ist jetzt vorbereitet und exportiert, die EICAR-Implementierung erfolgt später
# Alle Funktionen unterstützen nun das zentrale Logging-System und Datenbankprotokollierung
Export-ModuleMember -Function Start-QuickMRT, Start-FullMRT, Start-MemoryDiagnostic, Start-SFCCheck, Get-MemoryDiagnosticResults, Start-MRTTest





# SIG # Begin signature block
# MIIcSgYJKoZIhvcNAQcCoIIcOzCCHDcCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCASBtbOq6GoBsfD
# aRXaLVPc9eNWb6gla6YKkA7urYkIM6CCFnowggM8MIICJKADAgECAhBJfyGrXBJT
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
# MQ4wDAYKKwYBBAGCNwIBFTAvBgkqhkiG9w0BCQQxIgQgZojlnzCRSBgnXXJv7M3K
# zwtwABjh7vEkCuiWPPWQzKwwDQYJKoZIhvcNAQEBBQAEggEANuG/InzlLYwn8zrv
# IgP3Cn8XV0/MsHiTmtlvLXq/qJAGnhPzegQKpiMSgq3FoZzABMJYSqeKM2hWNQlt
# L5YVwoojutErOM2dGz7+IeY+ztO9PQzGOkN24MH2pfmn9JX6GP5hiezIixY3OV7w
# sGC1iPMx5DuaciL4Lj5Zw8xIlblHyBEYB6xK0S3pHnVWpktVvziiTfWWfFU1I2Kh
# GwiYH5URg80hOiH/K1iuOgY3P81JcizCzKWRtn6uBTefeqdLXt+ctaLaa4UTstDm
# HT05V1GIc4PZ+t16471TdfSIxI3N47lzM6enl/DL8V2N0/UksBSq9wTFGLDj5zoN
# TP95MaGCAyYwggMiBgkqhkiG9w0BCQYxggMTMIIDDwIBATB9MGkxCzAJBgNVBAYT
# AlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5jLjFBMD8GA1UEAxM4RGlnaUNlcnQg
# VHJ1c3RlZCBHNCBUaW1lU3RhbXBpbmcgUlNBNDA5NiBTSEEyNTYgMjAyNSBDQTEC
# EAqA7xhLjfEFgtHEdqeVdGgwDQYJYIZIAWUDBAIBBQCgaTAYBgkqhkiG9w0BCQMx
# CwYJKoZIhvcNAQcBMBwGCSqGSIb3DQEJBTEPFw0yNjAxMjAxODAyNTVaMC8GCSqG
# SIb3DQEJBDEiBCDWx2m6mf0qhsVltDJu4vWMMxIlvL/HNR5YlNTYl2T7mjANBgkq
# hkiG9w0BAQEFAASCAgAlYbBmWGGAx33nvmRNhy8GUsfX8StUPHi4mHlYK1t6tkPT
# lbv+lespH4CrPIcxxrNv9ZR0FrDGunsqJM6XwEzlJxw5u3k6qXkpijc5bonyDiqu
# WHb4yhO+jPjSTd5y12eXgFf4j91OLQas35h7ARDGQ0a/QwbgdxXblr5wphU6F/iV
# NFWUAtO/E83v0ftSN7kgu65TfuEOl37RN1WXp5dS9e5HbJix71wgTfQFeQJQhW+w
# SmXsRnyj2Ggio1DvtV31mnW8qCQcSZmRdETCL+DjrCpu0xcs6QXHamBey8ZLrwll
# 30xj8ha1fr7O5/he8Q0KPFCzHpfvdR/ITypvkqJ9z4VY8skkEY5LhycudGk5n7bC
# daKDg6Nts2uEjSxifkfaAmIe3NlNDulsAb+xHYd2LUXzNdE6QxFuS/UXSF8zXbj7
# 5g9lwe4q+lDQDpH8ddiVOl4FPdqVcmqqGgEPOAWUkW+QoOn6PROIrmENtP72D8RX
# 1H/+M21qwlLomToxDn49YUghgPc8Q3+l1NU8a7GypRgleCJ1Zw60BOa1L1iXQE3O
# rhm2FDp6s7tz8Q25Ge7A/ur0SNOB9eEsvKn+ZXzGbq5VlXyj45kdQZzwglDInxS1
# IKniakjV88yPFYZMY+Giqfk00tBCsagDKkAb1DVu7Pc5SH6gSAyGf9xxPoatGg==
# SIG # End signature block

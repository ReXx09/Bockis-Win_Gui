# Import required modules
Import-Module "$PSScriptRoot\..\Core\Core.psm1" -Force
Import-Module "$PSScriptRoot\..\Core\ProgressBarTools.psm1" -Force

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
    
    # Rahmen und Systeminformationen erstellen
    $computerName = $env:COMPUTERNAME
    $userName = $env:USERNAME
    $osInfo = (Get-CimInstance -ClassName Win32_OperatingSystem).Caption
    $dateTime = Get-Date -Format "dd.MM.yyyy HH:mm:ss"
    $width = 80

        
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
    Write-ColoredCenteredText "Malware Removal Tool Scan wird initialisiert..."
    Write-Host "╚══════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Green
    
    # 3 Sekunden warten vor dem Start
    Start-Sleep -Seconds 3
    # outputBox zuruecksetzen
    $outputBox.Clear()
    
    try {
        # Header für den Scan
        $outputBox.SelectionColor = [System.Drawing.Color]::DarkBlue
        $outputBox.AppendText("`r`n===== MICROSOFT MALICIOUS SOFTWARE REMOVAL TOOL (MRT) =====`r`n")
        $outputBox.AppendText("Modus: Quick Scan`r`n")
        $outputBox.AppendText("Zeitstempel: $(Get-Date -Format 'dd.MM.yyyy HH:mm:ss')`r`n`r`n")
        
        # Prüfe ob MRT.exe existiert
        $mrtPath = "$env:windir\System32\mrt.exe"
        if (-not (Test-Path $mrtPath)) {
            $outputBox.SelectionColor = [System.Drawing.Color]::Red
            $outputBox.AppendText("[!] FEHLER: MRT.exe wurde nicht gefunden!`r`n")
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
        $outputBox.SelectionColor = [System.Drawing.Color]::Blue
        $outputBox.AppendText("[>] Quick Scan wird gestartet...`r`n")
             
        
        Write-Host
        Write-Host
        Write-Host "     [i] Bitte warten bis der Scan abgeschlossen ist !!!" -ForegroundColor Red
        Write-Host
        Write-Host "`n" + ("═" * 70) -ForegroundColor Cyan 
        Write-Host
        Write-Host "     [ Quick Scan wird gestartet... ]" -ForegroundColor $secondaryColor

        # Progressbar initialisieren
        $progressBar.Value = 0
        Update-ProgressStatus -StatusText "MRT Quick-Scan wird vorbereitet..." -ProgressValue 0 -TextColor ([System.Drawing.Color]::DarkBlue) -progressBarParam $progressBar
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
            @{ Name = "Initialisierung"; Progress = 5; Color = [System.Drawing.Color]::DarkBlue; TimeWeight = 0.1 },
            @{ Name = "Überprüfung von Systemdateien"; Progress = 25; Color = [System.Drawing.Color]::Blue; TimeWeight = 0.25 },
            @{ Name = "Suche nach Malware-Mustern"; Progress = 50; Color = [System.Drawing.Color]::Blue; TimeWeight = 0.35 },
            @{ Name = "Überprüfung kritischer Bereiche"; Progress = 75; Color = [System.Drawing.Color]::DarkGreen; TimeWeight = 0.2 },
            @{ Name = "Finale Überprüfungen"; Progress = 95; Color = [System.Drawing.Color]::Green; TimeWeight = 0.1 }
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
                $outputBox.SelectionColor = [System.Drawing.Color]::Red
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
                $outputBox.SelectionColor = [System.Drawing.Color]::Blue
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
                        $outputBox.SelectionColor = [System.Drawing.Color]::Red
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
        
        # Ausgabe und Fehler einlesen
        $output = $process.StandardOutput.ReadToEnd()
        $errorOutput = $process.StandardError.ReadToEnd()
        
        # Prozess aufräumen
        $process.Dispose()
        
        # Exit-Code auswerten
        $outputBox.SelectionColor = [System.Drawing.Color]::Blue
        $outputBox.AppendText("`r`n[i] Scan-Ergebnis:`r`n")
        
        if ($hasTimedOut) {
            $outputBox.SelectionColor = [System.Drawing.Color]::Red
            $outputBox.AppendText("    [✗] Status: Scan-Timeout`r`n")
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
            $outputBox.SelectionColor = [System.Drawing.Color]::Red
            $outputBox.AppendText("    [×] Unerwarteter Fehler: Kein Exit-Code erhalten`r`n")
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
                $outputBox.SelectionColor = [System.Drawing.Color]::Green
                $outputBox.AppendText("    [✓] Status: Scan erfolgreich abgeschlossen`r`n")
                $outputBox.AppendText("    [✓] Keine Malware gefunden`r`n")
                Update-ProgressStatus -StatusText "Scan erfolgreich - Keine Malware gefunden" -ProgressValue 100 -TextColor ([System.Drawing.Color]::Green) -progressBarParam $progressBar
            }
            1 {
                $outputBox.SelectionColor = [System.Drawing.Color]::Red
                $outputBox.AppendText("    [✗] Status: Malware gefunden!`r`n")
                $outputBox.AppendText("    [!] Windows Defender Offline-Scan wird empfohlen`r`n")
                Update-ProgressStatus -StatusText "Malware gefunden!" -ProgressValue 100 -TextColor ([System.Drawing.Color]::Red) -progressBarParam $progressBar
                
                # Neustart-Dialog für Malware-Fall
                $restartResult = Show-CustomMessageBox -message "Für die Malware-Entfernung wird ein Neustart im abgesicherten Modus empfohlen. Möchten Sie den Computer jetzt neu starten?" -title "Sicherheitsneustart erforderlich" -fontSize 12
                if ($restartResult -eq "OK") {
                    Start-SystemRestart -outputBox $outputBox -safeMode $true
                }
            }
            2 {
                $outputBox.SelectionColor = [System.Drawing.Color]::Yellow
                $outputBox.AppendText("    [!] Status: Scan abgebrochen`r`n")
                $outputBox.AppendText("    [!] Der Scan wurde manuell oder durch Zeitüberschreitung beendet`r`n")
                Update-ProgressStatus -StatusText "Scan abgebrochen" -ProgressValue 100 -TextColor ([System.Drawing.Color]::Yellow) -progressBarParam $progressBar
            }
            3 {
                $outputBox.SelectionColor = [System.Drawing.Color]::Red
                $outputBox.AppendText("    [!] Status: Initialisierungsfehler`r`n")
                $outputBox.AppendText("    [!] Neustart erforderlich für MRT-Initialisierung`r`n")
                Update-ProgressStatus -StatusText "Initialisierungsfehler - Neustart empfohlen" -ProgressValue 100 -TextColor ([System.Drawing.Color]::Red) -progressBarParam $progressBar
                
                # Neustart-Dialog für Initialisierungsfehler
                $restartResult = Show-CustomMessageBox -message "Für die korrekte Initialisierung des MRT wird ein Neustart empfohlen. Möchten Sie den Computer jetzt neu starten?" -title "Neustart empfohlen" -fontSize 12
                if ($restartResult -eq "OK") {
                    Start-SystemRestart -outputBox $outputBox
                }
            }
            7 {
                $outputBox.SelectionColor = [System.Drawing.Color]::Red
                $outputBox.AppendText("    [✗] Status: Keine Administratorrechte`r`n")
                $outputBox.AppendText("    [i] Bitte Tool als Administrator ausführen`r`n")
                Update-ProgressStatus -StatusText "Administratorrechte erforderlich" -ProgressValue 100 -TextColor ([System.Drawing.Color]::Red) -progressBarParam $progressBar
            }
            8 {
                $outputBox.SelectionColor = [System.Drawing.Color]::Orange
                $outputBox.AppendText("    [!] Status: System-Neustart erforderlich`r`n")
                $outputBox.AppendText("    [i] Bitte führen Sie einen System-Neustart durch`r`n")
                Update-ProgressStatus -StatusText "Neustart erforderlich" -ProgressValue 100 -TextColor ([System.Drawing.Color]::Orange) -progressBarParam $progressBar
                
                # Neustart-Dialog anzeigen
                $restartResult = Show-CustomMessageBox -message "Ein Systemneustart wird empfohlen. Möchten Sie den Computer jetzt neu starten?" -title "Neustart erforderlich" -fontSize 12
                if ($restartResult -eq "OK") {
                    Start-SystemRestart -outputBox $outputBox
                }
            }
            9 {
                $outputBox.SelectionColor = [System.Drawing.Color]::Red
                $outputBox.AppendText("    [✗] Status: Schwerwiegende Malware gefunden`r`n")
                $outputBox.AppendText("    [!] Windows Defender Offline-Scan wird dringend empfohlen`r`n")
                Update-ProgressStatus -StatusText "Schwerwiegende Malware gefunden!" -ProgressValue 100 -TextColor ([System.Drawing.Color]::Red) -progressBarParam $progressBar
                
                # Neustart-Dialog für schwerwiegende Malware
                $restartResult = Show-CustomMessageBox -message "Für die Entfernung der schwerwiegenden Malware wird ein sofortiger Neustart im abgesicherten Modus dringend empfohlen. Möchten Sie den Computer jetzt neu starten?" -title "Dringender Sicherheitsneustart" -fontSize 12
                if ($restartResult -eq "OK") {
                    Start-SystemRestart -outputBox $outputBox -safeMode $true
                }
            }
            default {
                $outputBox.SelectionColor = [System.Drawing.Color]::Yellow
                $outputBox.AppendText("    [?] Status: Unbekannter Exit-Code ($exitCode)`r`n")
                $outputBox.AppendText("    [i] Bitte überprüfen Sie die Windows Event-Logs`r`n")
                Update-ProgressStatus -StatusText "Unbekannter Status (Code: $exitCode)" -ProgressValue 100 -TextColor ([System.Drawing.Color]::Yellow) -progressBarParam $progressBar
            }
        }

        # Detaillierte Empfehlungen
        $outputBox.SelectionColor = [System.Drawing.Color]::Blue
        $outputBox.AppendText("`r`n[i] Empfehlungen:`r`n")
        
        switch ($exitCode) {
            0 {
                $outputBox.SelectionColor = [System.Drawing.Color]::Green
                $outputBox.AppendText("    * Keine weiteren Maßnahmen erforderlich`r`n")
                $outputBox.AppendText("    * Regelmäßige Scans werden empfohlen`r`n")
                $outputBox.AppendText("    * Nächster Scan in 7 Tagen empfohlen`r`n")
            }
            { $_ -in 1, 9 } {
                $outputBox.SelectionColor = [System.Drawing.Color]::Red
                $outputBox.AppendText("    * Sofortige Maßnahmen erforderlich:`r`n")
                $outputBox.AppendText("    * 1. System im abgesicherten Modus starten`r`n")
                $outputBox.AppendText("    * 2. Windows Defender Offline-Scan durchführen`r`n")
                $outputBox.AppendText("    * 3. Wichtige Daten sichern`r`n")
                $outputBox.AppendText("    * 4. Professionelle Malware-Entfernung in Betracht ziehen`r`n")
            }
            { $_ -in 2, 3 } {
                $outputBox.SelectionColor = [System.Drawing.Color]::Yellow
                $outputBox.AppendText("    * Scan später wiederholen`r`n")
                $outputBox.AppendText("    * System-Neustart durchführen`r`n")
                $outputBox.AppendText("    * Windows Event-Logs überprüfen`r`n")
            }
            -99 {
                $outputBox.SelectionColor = [System.Drawing.Color]::Orange
                $outputBox.AppendText("    * System neu starten und Tool erneut ausführen`r`n")
                $outputBox.AppendText("    * Temporäre Dateien bereinigen`r`n")
                $outputBox.AppendText("    * Nach dem Neustart zuerst Windows Defender starten`r`n")
                $outputBox.AppendText("    * Falls das Problem bestehen bleibt, Defender-Dienst neu starten`r`n")
            }
            7 {
                $outputBox.SelectionColor = [System.Drawing.Color]::Orange
                $outputBox.AppendText("    * Tool als Administrator neu starten`r`n")
                $outputBox.AppendText("    * UAC-Einstellungen überprüfen`r`n")
            }
            8 {
                $outputBox.SelectionColor = [System.Drawing.Color]::Orange
                $outputBox.AppendText("    * System-Neustart durchführen`r`n")
                $outputBox.AppendText("    * Anschließend Full Scan durchführen`r`n")
                $outputBox.AppendText("    * Windows Defender Überprüfung empfohlen`r`n")
            }
            default {
                if ($exitCode -ne 0) {
                    $outputBox.SelectionColor = [System.Drawing.Color]::Yellow
                    $outputBox.AppendText("    * Windows Event-Logs überprüfen`r`n")
                    $outputBox.AppendText("    * Scan im abgesicherten Modus wiederholen`r`n")
                    $outputBox.AppendText("    * Support kontaktieren bei wiederholtem Auftreten`r`n")
                }
            }
        }

        # Log-Datei Analyse
        if (Test-Path $logPath) {
            $outputBox.SelectionColor = [System.Drawing.Color]::Blue
            $outputBox.AppendText("`r`n[i] Log-Datei Analyse:`r`n")
            
            $lastLines = Get-Content $logPath -Tail 5
            foreach ($line in $lastLines) {
                if ($line -match "Error|Failed|Exception") {
                    $outputBox.SelectionColor = [System.Drawing.Color]::Red
                    $outputBox.AppendText("    [!] $line`r`n")
                }
                elseif ($line -match "Warning") {
                    $outputBox.SelectionColor = [System.Drawing.Color]::Yellow
                    $outputBox.AppendText("    [!] $line`r`n")
                }
                elseif ($line -match "Success|Complete") {
                    $outputBox.SelectionColor = [System.Drawing.Color]::Green
                    $outputBox.AppendText("    [✓] $line`r`n")
                }
            }
        }

        # Abschluss
        $outputBox.SelectionColor = [System.Drawing.Color]::Blue
        $outputBox.AppendText("`r`n[i] Scan abgeschlossen um $(Get-Date -Format 'HH:mm:ss')`r`n")
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
        $outputBox.SelectionColor = [System.Drawing.Color]::Red
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
    if ($progressBar) {
        Initialize-ProgressComponents -ProgressBar $progressBar -StatusLabel $null
    }
    
    # Essentielle Informationen sammeln
    $computerName = $env:COMPUTERNAME
    $userName = $env:USERNAME
    $osInfo = (Get-CimInstance -ClassName Win32_OperatingSystem).Caption
    $dateTime = Get-Date -Format "dd.MM.yyyy HH:mm:ss"
    $width = 80
        
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
    Write-ColoredCenteredText                                  "SYSTEMINFORMATIONEN"
    Write-Host "╠══════════════════════════════════════════════════════════════════════════════╣" -ForegroundColor Green
    # Systeminformationen
    Write-Host "║                                                                              ║" -ForegroundColor Green
    Write-Host "      ├─    Betriebssystem: $osInfo           "            -ForegroundColor Yellow                 
    Write-Host "      ├─    Computer:       $computerName     "            -ForegroundColor Yellow                                    
    Write-Host "      ├─    Benutzer:       $userName         "            -ForegroundColor Yellow                                    
    Write-Host "      └─    Datum und Zeit: $dateTime         "            -ForegroundColor Yellow                                  
    Write-Host "║                                                                              ║" -ForegroundColor Green

    Write-Host "╠══════════════════════════════════════════════════════════════════════════════╣" -ForegroundColor Green
    Write-ColoredCenteredText                          "Starte Full MRT Scan..."
    Write-Host "╚══════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Green
    
    # 3 Sekunden warten vor dem Start
    Start-Sleep -Seconds 3
    
    # outputBox zuruecksetzen
    $outputBox.Clear()
    
    try {
        # Header für den Scan
        $outputBox.SelectionColor = [System.Drawing.Color]::DarkBlue
        $outputBox.AppendText("`r`n===== MICROSOFT MALICIOUS SOFTWARE REMOVAL TOOL (MRT) =====`r`n")
        $outputBox.AppendText("Modus: Quick Scan`r`n")
        $outputBox.AppendText("Zeitstempel: $(Get-Date -Format 'dd.MM.yyyy HH:mm:ss')`r`n`r`n")
        
    }
    catch {
        $outputBox.SelectionColor = [System.Drawing.Color]::Red
        $outputBox.AppendText("`r`n[-] FEHLER: $_`r`n")
        return -1
    }
       
    $outputBox.AppendText("[>] Windows- Fenster für MRT Full Scan wird geöffnet...`r`n")
    
          
    Write-Host
    Write-Host
    Write-Host "     [i] Bitte warten bis der Scan abgeschlossen ist !!!" -ForegroundColor Red
    Write-Host
    Write-Host "`n" + ("═" * 70) -ForegroundColor Cyan 
    Write-Host
    Write-Host "     [>] WIndows- Fenster für " MRT Full Scan " wird geöffnet...... " -ForegroundColor $secondaryColor
    Write-Host "     [i] Bitte starten Sie den Scan im Windowseigenen Tool-Fenster ... " -ForegroundColor $secondaryColor
    Write-Host
    # MRT-Prozess starten und Exit-Code erfassen
    try {
        # Timer starten, um einen Timeout zu ermöglichen
        $timeoutSeconds = 3600  # 1 Stunde Timeout
        $timer = [System.Diagnostics.Stopwatch]::StartNew()
        
        # MRT mit Timeout starten
        $mrtProcess = Start-Process -FilePath "mrt.exe" -ArgumentList "/F" -NoNewWindow -PassThru
        
        # Auf Prozessende warten mit Timeout
        $processExited = $mrtProcess.WaitForExit($timeoutSeconds * 1000)
        
        if (-not $processExited) {
            # Prozess hängt sich auf, wir beenden ihn
            $outputBox.SelectionColor = [System.Drawing.Color]::Red
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
            
            if ($progressBar) {
                Update-ProgressStatus -StatusText "MRT Full Scan abgebrochen (Timeout nach $timeoutSeconds Sekunden)" -ProgressValue 0 -TextColor ([System.Drawing.Color]::Red) -progressBarParam $progressBar
            }
        }
        else {
            # Prozess hat normal beendet
            $exitCode = $mrtProcess.ExitCode
        }
    }
    catch {
        $outputBox.SelectionColor = [System.Drawing.Color]::Red
        $outputBox.AppendText("Fehler beim Starten des MRT Full Scans: $_`r`n")
        $exitCode = -3  # Benutzerdefinierter Code für Startfehler
        
        if ($progressBar) {
            Update-ProgressStatus -StatusText "Fehler beim Starten des MRT Full Scans" -ProgressValue 0 -TextColor ([System.Drawing.Color]::Red) -progressBarParam $progressBar
        }
    }
    
    # Ueberpruefen des Exit-Codes und Farbausgabe
    switch ($exitCode) {
        0 {
            $outputBox.SelectionColor = [System.Drawing.Color]::Green
            $outputBox.AppendText("MRT Full Scan erfolgreich abgeschlossen. Keine Bedrohungen gefunden.`r`n")
            if ($progressBar) {
                Update-ProgressStatus -StatusText "MRT Full Scan abgeschlossen - Keine Bedrohungen gefunden" -ProgressValue 100 -TextColor ([System.Drawing.Color]::Green) -progressBarParam $progressBar
            }
        }
        1 {
            $outputBox.SelectionColor = [System.Drawing.Color]::Orange
            $outputBox.AppendText("MRT Full Scan abgeschlossen. Es wurden Bedrohungen gefunden.`r`n")
            if ($progressBar) {
                Update-ProgressStatus -StatusText "MRT Full Scan abgeschlossen - Bedrohungen gefunden" -ProgressValue 100 -TextColor ([System.Drawing.Color]::Orange) -progressBarParam $progressBar
            }
        }
        2 {
            $outputBox.SelectionColor = [System.Drawing.Color]::Red
            $outputBox.AppendText("MRT Full Scan wurde abgebrochen. Der Vorgang wurde nicht abgeschlossen.`r`n")
            if ($progressBar) {
                Update-ProgressStatus -StatusText "MRT Full Scan wurde abgebrochen" -ProgressValue 0 -TextColor ([System.Drawing.Color]::Red) -progressBarParam $progressBar
            }
        }
        -1 {
            $outputBox.SelectionColor = [System.Drawing.Color]::Red
            $outputBox.AppendText("MRT Full Scan wurde wegen Timeout abgebrochen.`r`n")
            $outputBox.AppendText("Dies kann passieren, wenn der Scan hängen bleibt oder zu lange dauert.`r`n")
            $outputBox.AppendText("Tipp: Versuchen Sie einen Neustart und führen Sie den Scan erneut aus.`r`n")
            
            if ($progressBar) {
                Update-ProgressStatus -StatusText "MRT Full Scan - Timeout" -ProgressValue 0 -TextColor ([System.Drawing.Color]::Red) -progressBarParam $progressBar
            }
        }
        -2 {
            $outputBox.SelectionColor = [System.Drawing.Color]::Red
            $outputBox.AppendText("MRT Full Scan konnte nicht beendet werden.`r`n")
            $outputBox.AppendText("Bitte starten Sie den Computer neu und versuchen Sie es erneut.`r`n")
            
            if ($progressBar) {
                Update-ProgressStatus -StatusText "MRT Full Scan - Fehler beim Beenden" -ProgressValue 0 -TextColor ([System.Drawing.Color]::Red) -progressBarParam $progressBar
            }
        }
        -3 {
            $outputBox.SelectionColor = [System.Drawing.Color]::Red
            $outputBox.AppendText("MRT Full Scan konnte nicht gestartet werden.`r`n")
            $outputBox.AppendText("Überprüfen Sie, ob mrt.exe auf Ihrem System verfügbar ist.`r`n")
            
            if ($progressBar) {
                Update-ProgressStatus -StatusText "MRT Full Scan - Startfehler" -ProgressValue 0 -TextColor ([System.Drawing.Color]::Red) -progressBarParam $progressBar
            }
        }
        default {
            $outputBox.SelectionColor = [System.Drawing.Color]::Red
            $outputBox.AppendText("MRT Full Scan abgeschlossen mit Exit-Code: $exitCode.`r`n")
            if ($progressBar) {
                Update-ProgressStatus -StatusText "MRT Full Scan mit Fehlercode $exitCode beendet" -ProgressValue 0 -TextColor ([System.Drawing.Color]::Red) -progressBarParam $progressBar
            }
        }
    }
}    


# Function to run Memory Diagnostic
function Start-MemoryDiagnostic {
    param (
        [System.Windows.Forms.RichTextBox]$outputBox,
        [System.Windows.Forms.ProgressBar]$progressBar
    )
    Clear-Host
    
    # Stelle sicher, dass die ProgressBar initialisiert ist
    if ($progressBar -ne $null) {
        try {
            # ProgressBar-Eigenschaften setzen
            $progressBar.Minimum = 0
            $progressBar.Maximum = 100
            $progressBar.Step = 1
            $progressBar.Style = [System.Windows.Forms.ProgressBarStyle]::Continuous
            $progressBar.Value = 0
        }
        catch {
            Write-Host "Warnung: ProgressBar konnte nicht initialisiert werden: $_" -ForegroundColor Yellow
            $progressBar = $null
        }
    }
    
    # Rahmen und Systeminformationen erstellen
    $computerName = $env:COMPUTERNAME
    $userName = $env:USERNAME
    $osInfo = (Get-CimInstance -ClassName Win32_OperatingSystem).Caption
    $dateTime = Get-Date -Format "dd.MM.yyyy HH:mm:ss"
    $width = 80
    
    # Rahmen oben
    Write-Host "╔══════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-ColoredCenteredText                             "WINDOWS MEMORY DIAGNOSTIC TOOL"
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
    Write-ColoredCenteredText                             "SYSTEMINFORMATIONEN"
    Write-Host "╠══════════════════════════════════════════════════════════════════════════════╣" -ForegroundColor Green
    # Systeminformationen
    Write-Host "║                                                                              ║" -ForegroundColor Green
    Write-Host "      ├─    Betriebssystem: $osInfo           "            -ForegroundColor Yellow                 
    Write-Host "      ├─    Computer:       $computerName     "            -ForegroundColor Yellow                                    
    Write-Host "      ├─    Benutzer:       $userName         "            -ForegroundColor Yellow                                    
    Write-Host "      └─    Datum und Zeit: $dateTime         "            -ForegroundColor Yellow                                  
    Write-Host "║                                                                              ║" -ForegroundColor Green

    Write-Host "╠══════════════════════════════════════════════════════════════════════════════╣" -ForegroundColor Green
    Write-ColoredCenteredText                             "Starte Windows Memory Diagnostic Tool..."
    Write-Host "╚══════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Green

    # 3 Sekunden warten vor dem Start
    Start-Sleep -Seconds 3

    # outputBox zuruecksetzen
    $outputBox.Clear()
    # Header für den Memory Diagnostic
    $outputBox.SelectionColor = [System.Drawing.Color]::DarkBlue
    $outputBox.AppendText("`r`n===== WINDOWS MEMORY DIAGNOSTIC =====`r`n")
    $outputBox.AppendText("Zeitstempel: $(Get-Date -Format 'dd.MM.yyyy HH:mm:ss')`r`n`r`n")
    
    try {
        # Prüfen ob wir Administratorrechte haben
        $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
        
        if (-not $isAdmin) {
            $outputBox.SelectionColor = [System.Drawing.Color]::Red
            $outputBox.AppendText("[-] Fehler: Administratorrechte erforderlich!`r`n")
            $outputBox.AppendText("[i] Bitte starten Sie das Tool als Administrator.`r`n")
            return
        }

        # Prüfen ob ein Memory Diagnostic bereits geplant ist
        $scheduledTask = Get-ScheduledTask -TaskName "MemoryDiagnostic" -ErrorAction SilentlyContinue
        if ($scheduledTask) {
            $outputBox.SelectionColor = [System.Drawing.Color]::Yellow
            $outputBox.AppendText("[!] Ein Memory Diagnostic ist bereits geplant.`r`n")
            $outputBox.AppendText("[i] Möchten Sie den geplanten Scan ausführen?`r`n")
            
            $result = [System.Windows.Forms.MessageBox]::Show(
                "Ein Memory Diagnostic ist bereits geplant.`n`nMöchten Sie den Scan jetzt ausführen?",
                "Memory Diagnostic geplant",
                [System.Windows.Forms.MessageBoxButtons]::YesNo,
                [System.Windows.Forms.MessageBoxIcon]::Question
            )
            
            if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
                Start-Process "mdsched.exe" -NoNewWindow
                return
            }
        }

        # Memory Diagnostic über die Windows API starten
        $outputBox.SelectionColor = [System.Drawing.Color]::Green
        $outputBox.AppendText("[+] Starte Windows Memory Diagnostic...`r`n")
        
        # Marker-Datei erstellen, um nach dem Neustart zu erkennen, dass wir die Ergebnisse prüfen sollen
        $markerFile = "$env:TEMP\memory_diagnostic_marker.txt"
        Set-Content -Path $markerFile -Value (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        
        # Memory Diagnostic direkt starten
        Start-Process "mdsched.exe" -NoNewWindow
        $outputBox.AppendText("[i] Memory Diagnostic wurde gestartet.`r`n")
        $outputBox.AppendText("[i] Bitte bestaetigen Sie den Neustart im Windows-Dialog.`r`n")
    }
    catch {
        $outputBox.SelectionColor = [System.Drawing.Color]::Red
        $outputBox.AppendText("[-] Fehler beim Starten des Memory Diagnostics: $_`r`n")
    }
    finally {
        # ProgressBar zuruecksetzen
        if ($progressBar -ne $null) {
            try {
                $progressBar.Value = 0
            }
            catch {
                Write-Host "Warnung: ProgressBar-Reset fehlgeschlagen: $_" -ForegroundColor Yellow
            }
        }
    }
}

# Neue Funktion zum Prüfen der Memory Diagnostic Ergebnisse
function Get-MemoryDiagnosticResults {
    param (
        [System.Windows.Forms.RichTextBox]$outputBox
    )
    
    try {
        # Prüfen ob wir Administratorrechte haben
        $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
        
        if (-not $isAdmin) {
            $outputBox.SelectionColor = [System.Drawing.Color]::Red
            $outputBox.AppendText("[-] Fehler: Administratorrechte erforderlich!`r`n")
            return
        }

        # Event Log nach Memory Diagnostic Ergebnissen durchsuchen
        $events = Get-WinEvent -FilterHashtable @{
            LogName      = 'System'
            ProviderName = 'Microsoft-Windows-MemoryDiagnostics-Results'
        } -MaxEvents 1 -ErrorAction SilentlyContinue

        if ($events) {
            $outputBox.SelectionColor = [System.Drawing.Color]::Blue
            $outputBox.AppendText("`r`n[i] Memory Diagnostic Ergebnisse:`r`n")
            
            foreach ($event in $events) {
                $outputBox.AppendText("Zeitpunkt: $($event.TimeCreated)`r`n")
                
                # Ergebnis auswerten
                if ($event.Properties[0].Value -eq 0) {
                    $outputBox.SelectionColor = [System.Drawing.Color]::Green
                    $outputBox.AppendText("[+] Keine Speicherprobleme gefunden.`r`n")
                }
                else {
                    $outputBox.SelectionColor = [System.Drawing.Color]::Red
                    $outputBox.AppendText("[-] Speicherprobleme wurden gefunden!`r`n")
                    $outputBox.AppendText("[i] Bitte überprüfen Sie Ihre RAM-Module.`r`n")
                }
            }
        }
        else {
            $outputBox.SelectionColor = [System.Drawing.Color]::Yellow
            $outputBox.AppendText("[!] Keine Memory Diagnostic Ergebnisse gefunden.`r`n")
            $outputBox.AppendText("[i] Möglicherweise wurde noch kein Scan durchgeführt.`r`n")
        }
    }
    catch {
        $outputBox.SelectionColor = [System.Drawing.Color]::Red
        $outputBox.AppendText("[-] Fehler beim Lesen der Memory Diagnostic Ergebnisse: $_`r`n")
    }
}

# SFC (System File Checker) Funktion
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
    
    # Rahmen und Systeminformationen erstellen
    $computerName = $env:COMPUTERNAME
    $userName = $env:USERNAME
    $osInfo = (Get-CimInstance -ClassName Win32_OperatingSystem).Caption
    $dateTime = Get-Date -Format "dd.MM.yyyy HH:mm:ss"
    $width = 80
    
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
    Write-Host "      ├─    Betriebssystem: $osInfo           "            -ForegroundColor Yellow                 
    Write-Host "      ├─    Computer:       $computerName     "            -ForegroundColor Yellow                                    
    Write-Host "      ├─    Benutzer:       $userName         "            -ForegroundColor Yellow                                    
    Write-Host "      └─    Datum und Zeit: $dateTime         "            -ForegroundColor Yellow                                  
    Write-Host "║                                                                              ║" -ForegroundColor Green

    Write-Host "╠══════════════════════════════════════════════════════════════════════════════╣" -ForegroundColor Green
    Write-ColoredCenteredText                             "Starte System File Checker..."
    Write-Host "╚══════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Green

    # 3 Sekunden warten vor dem Start von SFC
    Start-Sleep -Seconds 3
    
    # Header für den SFC-Scan
    $outputBox.SelectionColor = [System.Drawing.Color]::DarkBlue
    $outputBox.AppendText("`r`n===== SYSTEM FILE CHECKER (SFC) =====`r`n")
    $outputBox.AppendText("Zeitstempel: $(Get-Date -Format 'dd.MM.yyyy HH:mm:ss')`r`n`r`n")
    
    try {
        # Fortschritt initialisieren
        if ($progressBar) {
            $progressBar.Value = 10
            $progressBar.CustomText = "SFC Scan wird initialisiert..."
            $progressBar.TextColor = [System.Drawing.Color]::DarkBlue
        }
        
        # Scan-Start Meldung in OutputBox
        $outputBox.SelectionColor = [System.Drawing.Color]::Blue
        $outputBox.AppendText("[>] SFC /scannow wird gestartet...`r`n")
        $outputBox.AppendText("[>] Bitte warten Sie, während die Systemdateien überprüft werden...`r`n`r`n")
        
        Write-Host "`n[>] Starte SFC /scannow..." -ForegroundColor Yellow
        
        # Fortschritt aktualisieren vor dem Start des Scans
        if ($progressBar) {
            $progressBar.Value = 20
            $progressBar.CustomText = "SFC Scan wird gestartet..."
        }
        
        # SFC mit /scannow Parameter ausführen und Ausgabe direkt anzeigen
        $process = Start-Process -FilePath "sfc.exe" -ArgumentList "/scannow" -Wait -PassThru -NoNewWindow
        
        # Fortschritt aktualisieren nach Abschluss des Scans
        if ($progressBar) {
            $progressBar.Value = 80
            $progressBar.CustomText = "Scan abgeschlossen, analysiere Ergebnisse..."
        }
        
        Write-Host "`n" + ("═" * 70) -ForegroundColor Cyan
        Write-Host "`n[i] Scan-Ergebnis:" -ForegroundColor Blue
        
        $outputBox.SelectionColor = [System.Drawing.Color]::Blue
        $outputBox.AppendText("`r`n[i] Scan-Ergebnis:`r`n")
        
        switch ($process.ExitCode) {
            0 {
                Write-Host "    [✓] System-Dateien sind in Ordnung" -ForegroundColor Green
                Write-Host "    [✓] Keine Reparaturen notwendig" -ForegroundColor Green
                
                $outputBox.SelectionColor = [System.Drawing.Color]::Green
                $outputBox.AppendText("    [✓] System-Dateien sind in Ordnung`r`n")
                $outputBox.AppendText("    [✓] Keine Reparaturen notwendig`r`n")
                
                # Fortschritt aktualisieren mit positivem Ergebnis
                if ($progressBar) {
                    $progressBar.Value = 100
                    $progressBar.CustomText = "System-Dateien in Ordnung"
                    $progressBar.TextColor = [System.Drawing.Color]::Green
                }
            }
            1 {
                Write-Host "    [!] Beschädigte Dateien wurden gefunden und repariert" -ForegroundColor Orange
                Write-Host "    [!] Ein Neustart wird empfohlen" -ForegroundColor Orange
                
                $outputBox.SelectionColor = [System.Drawing.Color]::Orange
                $outputBox.AppendText("    [!] Beschädigte Dateien wurden gefunden und repariert`r`n")
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
                Write-Host "    [X] Beschädigte Dateien gefunden" -ForegroundColor Red
                Write-Host "    [X] Reparatur nicht möglich" -ForegroundColor Red
                Write-Host "    [i] Empfehlung: DISM-Reparatur durchführen" -ForegroundColor Yellow
                
                $outputBox.SelectionColor = [System.Drawing.Color]::Red
                $outputBox.AppendText("    [X] Beschädigte Dateien gefunden`r`n")
                $outputBox.AppendText("    [X] Reparatur nicht möglich`r`n")
                $outputBox.AppendText("    [i] Empfehlung: DISM-Reparatur durchführen`r`n")
                
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
                    $outputBox.SelectionColor = [System.Drawing.Color]::Blue
                    $outputBox.AppendText("Starte DISM Restore Health...`r`n")
                    
                    # DISM Restore Health ausführen
                    Start-RestoreDISM -outputBox $outputBox -progressBar $progressBar
                }
            }
            default {
                Write-Host "    [] Unerwarteter Fehler (Code: $($process.ExitCode))" -ForegroundColor Red
                Write-Host "    [i] Bitte Support kontaktieren" -ForegroundColor Yellow
                
                $outputBox.SelectionColor = [System.Drawing.Color]::Red
                $outputBox.AppendText("    [] Unerwarteter Fehler (Code: $($process.ExitCode))`r`n")
                $outputBox.AppendText("    [i] Bitte Support kontaktieren`r`n")
                
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
        $outputBox.SelectionColor = [System.Drawing.Color]::Red
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
                $progressBar.TextColor = [System.Drawing.Color]::Green
            }
        }
        
        # Abschluss-Zeitstempel
        Write-Host "`nScan beendet: $(Get-Date -Format 'dd.MM.yyyy HH:mm:ss')" -ForegroundColor Gray
        Write-Host "`n" + ("═" * 70) -ForegroundColor Cyan
        
        $outputBox.SelectionColor = [System.Drawing.Color]::Gray
        $outputBox.AppendText("`r`nScan beendet: $(Get-Date -Format 'dd.MM.yyyy HH:mm:ss')`r`n")
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
    
    # Verzeichnis für temporäre Dateien erstellen
    $tempDir = "$env:TEMP\MRTTest"
    if (-not (Test-Path $tempDir)) {
        New-Item -Path $tempDir -ItemType Directory -Force | Out-Null
    }
}

# Export functions
Export-ModuleMember -Function Start-QuickMRT, Start-FullMRT, Start-MemoryDiagnostic, Start-SFCCheck, Get-MemoryDiagnosticResults
# Import required modules
Import-Module "$PSScriptRoot\..\Core\Core.psm1" -Force -Global
Import-Module "$PSScriptRoot\..\Core\ProgressBarTools.psm1" -Force -Global
Import-Module "$PSScriptRoot\..\Core\TextStyle.psm1" -Force -Global

# Function to run DISM Check Health
function Start-CheckDISM {
    param (
        [System.Windows.Forms.RichTextBox]$outputBox,
        [System.Windows.Forms.ProgressBar]$progressBar
    )

    Clear-Host
    # outputBox zuruecksetzen
    $outputBox.Clear()

    # Stelle sicher, dass die ProgressBar initialisiert ist
    if ($progressBar) {
        Initialize-ProgressComponents -ProgressBar $progressBar -StatusLabel $null
    }
    
    # In Log-Datei und Datenbank schreiben, dass der DISM Check startet
    Write-ToolLog -ToolName "DISM-Check" -Message "`n`t[►]DISM Check Health wird gestartet" -OutputBox $outputBox -Style 'Action' -Level "Information" -SaveToDatabase
    
    # Rahmen und Systeminformationen erstellen
    #$computerName = $env:COMPUTERNAME
    #$userName = $env:USERNAME
    #$osInfo = (Get-CimInstance -ClassName Win32_OperatingSystem).Caption
    #$dateTime = Get-Date -Format "dd.MM.yyyy HH:mm:ss"
    #$width = 80
        
    # Rahmen oben
    Write-Host "╔══════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-ColoredCenteredText                        "DISM CHECK HEALTH"                                         
    Write-Host "╚══════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Green
    
    # ASCII-Art Logo
    Write-Host
    Write-Host '  8888888b.  8888888  .d8888b.  888b     d888                           ' -ForegroundColor Cyan
    Write-Host '  888  "Y88b   888   d88P  Y88b 8888b   d8888                           ' -ForegroundColor Blue
    Write-Host '  888    888   888   Y88b.      88888b.d88888                           ' -ForegroundColor Cyan
    Write-Host '  888    888   888    "Y888b.   888Y88888P888                           ' -ForegroundColor Blue
    Write-Host '  888    888   888       "Y88b. 888 Y888P 888                           ' -ForegroundColor Cyan
    Write-Host '  888    888   888         "888 888  Y8P  888                           ' -ForegroundColor Blue
    Write-Host '  888  .d88P   888   Y88b  d88P 888   "   888                           ' -ForegroundColor Cyan
    Write-Host '  8888888P"  8888888  "Y8888P"  888       888                           ' -ForegroundColor Blue
    Write-Host
    Write-Host '                      .d8888b.  888                        888          ' -ForegroundColor Cyan
    Write-Host '                     d88P  Y88b 888                        888          ' -ForegroundColor Blue
    Write-Host '                     888    888 888                        888          ' -ForegroundColor Cyan
    Write-Host '                     888        88888b.   .d88b.   .d8888b 888  888     ' -ForegroundColor Blue
    Write-Host '                     888        888 "88b d8P  Y8b d88P"    888 .88P     ' -ForegroundColor Cyan
    Write-Host '                     888    888 888  888 88888888 888      888888K      ' -ForegroundColor Blue
    Write-Host '                     Y88b  d88P 888  888 Y8b.     Y88b.    888 "88b     ' -ForegroundColor Cyan
    Write-Host '                      "Y8888P"  888  888  "Y8888   "Y8888P 888  888     ' -ForegroundColor Blue
    Write-Host
    # Rahmen für Systeminformationen
    Write-Host "╔══════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-ColoredCenteredText                   "INFORMATIONEN"                                     
    Write-Host "╠══════════════════════════════════════════════════════════════════════════════╣" -ForegroundColor Green
    # Systeminformationen
    Write-Host "║                                                                              ║" -ForegroundColor Green
    Write-Host "  ├─  Systemintegritätsprüfung mit DISM /CheckHealth:                             " -ForegroundColor Yellow                 
    Write-Host "  ├─  Scannt das Windows-Abbild auf Beschädigungen oder Inkonsistenzen.           " -ForegroundColor Yellow                                    
    Write-Host "  ├─  Die Überprüfung ist schnell und verändert das System nicht.                 " -ForegroundColor Yellow                                    
    Write-Host "  └─  Empfohlen vor tiefergehenden Reparaturen mit DISM oder SFC.                 " -ForegroundColor Yellow                                  
    Write-Host "║                                                                              ║" -ForegroundColor Green

    Write-Host "╠══════════════════════════════════════════════════════════════════════════════╣" -ForegroundColor Green
    Write-ColoredCenteredText                          "[►] Starte DISM Check..."
    Write-Host "╚══════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Green
    
    # 3 Sekunden warten vor dem Start
    Start-Sleep -Seconds 3

    # Ergebnis-Pfad für JSON definieren (logPath wurde entfernt, da nicht verwendet)
    $resultPath = "$env:TEMP\dism_check_result.json"

    # Header für die Ausgabe
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Action'
    $outputBox.AppendText("`n`t=== DISM Check Health ===`n")
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Default'
    $outputBox.AppendText("`tZeitpunkt: $(Get-Date -Format 'dd.MM.yyyy HH:mm:ss')`n`n")

    try {
        # ProgressBar aktualisieren
        if ($progressBar) {
            $progressBar.Value = 10
            Update-ProgressStatus -StatusText "DISM Check wird vorbereitet..." -ProgressValue 10 -TextColor ([System.Drawing.Color]::White) -progressBarParam $progressBar
        }

        # Kurze Pause für visuelles Feedback
        for ($i = 0; $i -lt 20; $i++) {
            Start-Sleep -Milliseconds 100
            [System.Windows.Forms.Application]::DoEvents()
        }

        if ($progressBar) {
            $progressBar.Value = 40
            Update-ProgressStatus -StatusText "DISM Check wird gestartet..." -ProgressValue 40 -TextColor ([System.Drawing.Color]::White) -progressBarParam $progressBar
        }
        
        # Den DISM-Befehl ausführen
        if ($progressBar) {
            $progressBar.Value = 60
            Update-ProgressStatus -StatusText "DISM Check läuft..." -ProgressValue 60 -TextColor ([System.Drawing.Color]::White) -progressBarParam $progressBar
        }
        
        $process = Start-Process "dism.exe" -ArgumentList "/Online /Cleanup-Image /CheckHealth" -NoNewWindow -Wait -PassThru

        # Ergebnis in JSON speichern
        $result = @{
            ExitCode  = $process.ExitCode
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
        $result | ConvertTo-Json | Set-Content -Path $resultPath
        Write-Host "`n" + ("═" * 70) -ForegroundColor Cyan 
        # Ergebnis auswerten
        switch ($process.ExitCode) {
            0 { 
                Write-Host "`n`t[✓] DISM Check Health erfolgreich abgeschlossen!" -ForegroundColor Green
                $outputBox.AppendText("`t[✓] DISM Check erfolgreich abgeschlossen.`r`n")
            }
            default {
                Write-Host "`n`t[X] DISM Check Health fehlgeschlagen. Exit-Code: $($process.ExitCode)" -ForegroundColor Red
                $outputBox.AppendText("`t[X] DISM Check fehlgeschlagen. Exit-Code: $($process.ExitCode)`r`n")
            }
        }
        Write-Host "`n" + ("═" * 70) -ForegroundColor Cyan 
        # ProgressBar zurücksetzen
        if ($progressBar) {
            $progressBar.Value = 100
            Update-ProgressStatus -StatusText "DISM Check abgeschlossen" -ProgressValue 100 -TextColor ([System.Drawing.Color]::LimeGreen) -progressBarParam $progressBar
            Start-Sleep -Milliseconds 500
            $progressBar.Value = 0
        }
    }
    catch {
        Write-Host "`n`t[X] Fehler beim DISM Check: $_" -ForegroundColor Red
        $outputBox.AppendText("`t[X] Fehler beim DISM Check: $_`r`n")
        if ($progressBar) {
            $progressBar.Value = 0
        }
    }
}

# Function to run DISM Scan Health
function Start-ScanDISM {
    param (
        [System.Windows.Forms.RichTextBox]$outputBox,
        [System.Windows.Forms.ProgressBar]$progressBar
    )

    Clear-Host
    # outputBox zuruecksetzen
    $outputBox.Clear()

    # Stelle sicher, dass die ProgressBar initialisiert ist
    if ($progressBar) {
        Initialize-ProgressComponents -ProgressBar $progressBar -StatusLabel $null
    }
    
    # In Log-Datei und Datenbank schreiben, dass der DISM Scan startet
    Write-ToolLog -ToolName "DISM-Scan" -Message "`n`t[►]DISM Scan wird gestartet" -OutputBox $outputBox -Style 'Action' -Level "Information" -SaveToDatabase
    
    # Rahmen und Systeminformationen erstellen
    #$computerName = $env:COMPUTERNAME
    #$userName = $env:USERNAME
    #$osInfo = (Get-CimInstance -ClassName Win32_OperatingSystem).Caption
    #$dateTime = Get-Date -Format "dd.MM.yyyy HH:mm:ss"
    #$width = 80
        
    # Rahmen oben
    Write-Host "╔══════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-ColoredCenteredText                             "DISM SCAN HEALTH"                                         
    Write-Host "╚══════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Green
    Write-Host
    Write-Host '8888888b. 8888888 .d8888b.  888b     d888              ' -ForegroundColor Cyan
    Write-Host '888  "Y88b  888  d88P  Y88b 8888b   d8888              ' -ForegroundColor Blue
    Write-Host '888    888  888  Y88b.      88888b.d88888              ' -ForegroundColor Cyan
    Write-Host '888    888  888   "Y888b.   888Y88888P888              ' -ForegroundColor Blue
    Write-Host '888    888  888      "Y88b. 888 Y888P 888              ' -ForegroundColor Cyan
    Write-Host '888    888  888        "888 888  Y8P  888              ' -ForegroundColor Blue
    Write-Host '888  .d88P  888  Y88b  d88P 888   "   888              ' -ForegroundColor Cyan
    Write-Host '8888888P" 8888888 "Y8888P"  888       888              ' -ForegroundColor Blue
    Write-Host
    Write-Host '                  .d8888b.                             ' -ForegroundColor Cyan
    Write-Host '                 d88P  Y88b                            ' -ForegroundColor Blue
    Write-Host '                 Y88b.                                 ' -ForegroundColor Cyan
    Write-Host '                  "Y888b.    .d8888b  8888b.  88888b.  ' -ForegroundColor Blue
    Write-Host '                     "Y88b. d88P"        "88b 888 "88b ' -ForegroundColor Cyan
    Write-Host '                       "888 888      .d888888 888  888 ' -ForegroundColor Blue
    Write-Host '                 Y88b  d88P Y88b.    888  888 888  888 ' -ForegroundColor Cyan
    Write-Host '                  "Y8888P"   "Y8888P "Y888888 888  888 ' -ForegroundColor Blue
    Write-Host
    Write-Host "╔══════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-ColoredCenteredText                          "INFORMATIONEN"   
    Write-Host "╠══════════════════════════════════════════════════════════════════════════════╣" -ForegroundColor Green
    Write-Host "║                                                                              ║" -ForegroundColor Green
    Write-Host "  ├─  Komponentenspeicher prüfen mit DISM (ScanHealth):                           " -ForegroundColor Yellow                 
    Write-Host "  ├─  Analysiert den Windows-Komponentenspeicher auf Beschädigungen.              " -ForegroundColor Yellow                                    
    Write-Host "  ├─  Hilft bei Problemen mit Windows-Funktionen oder Updates.                    " -ForegroundColor Yellow                                    
    Write-Host "  └─  Empfohlen nach einem SFC-Scan, wenn weiterhin Fehler bestehen.              " -ForegroundColor Yellow                                  
    Write-Host "║                                                                              ║" -ForegroundColor Green
    Write-Host "╠══════════════════════════════════════════════════════════════════════════════╣" -ForegroundColor Green
    Write-ColoredCenteredText                       "[►] Starte DISM Scan..."
    Write-Host "╚══════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Green
    
    # 3 Sekunden warten vor dem Start
    Start-Sleep -Seconds 3

    # Log-Datei-Pfad definieren
    $logPath = "$env:TEMP\dism_scan.log"
    $resultPath = "$env:TEMP\dism_scan_result.json"

    # Header für die Ausgabe
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Action'
    $outputBox.AppendText("`n`t=== DISM Scan Health ===`n")
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Default'
    $outputBox.AppendText("`tZeitpunkt: $(Get-Date -Format 'dd.MM.yyyy HH:mm:ss')`n`n")

    try {
        # ProgressBar aktualisieren
        if ($progressBar) {
            $progressBar.Value = 10
            Update-ProgressStatus -StatusText "DISM Scan wird vorbereitet..." -ProgressValue 10 -TextColor ([System.Drawing.Color]::White) -progressBarParam $progressBar
        }

        for ($i = 0; $i -lt 30; $i++) {
            Start-Sleep -Milliseconds 100
            [System.Windows.Forms.Application]::DoEvents()
        }

        if ($progressBar) {
            $progressBar.Value = 25
            Update-ProgressStatus -StatusText "DISM wird gestartet..." -ProgressValue 25 -TextColor ([System.Drawing.Color]::White) -progressBarParam $progressBar
        }
    
        # Den DISM-Befehl ausführen
        if ($progressBar) {
            $progressBar.Value = 50
            Update-ProgressStatus -StatusText "DISM Scan läuft..." -ProgressValue 50 -TextColor ([System.Drawing.Color]::White) -progressBarParam $progressBar
        }
    
        $process = Start-Process "dism.exe" -ArgumentList "/Online /Cleanup-Image /ScanHealth" -NoNewWindow -Wait -PassThru

        # ProgressBar aktualisieren
        if ($progressBar) {
            $progressBar.Value = 90
            Update-ProgressStatus -StatusText "DISM Scan wird abgeschlossen..." -ProgressValue 90 -TextColor ([System.Drawing.Color]::White) -progressBarParam $progressBar
        }

        # Ergebnis in JSON speichern
        $result = @{
            ExitCode  = $process.ExitCode
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
        $result | ConvertTo-Json | Set-Content -Path $resultPath
        Write-Host "`n" + ("═" * 70) -ForegroundColor Cyan 
        # Ergebnis auswerten
        switch ($process.ExitCode) {
            0 { 
                Write-Host "`n`t[✓] DISM Scan Health erfolgreich abgeschlossen!" -ForegroundColor Green
                $outputBox.AppendText("`t[✓] DISM Scan erfolgreich abgeschlossen.`r`n")
            }
            default {
                Write-Host "`n`t[X] DISM Scan Health fehlgeschlagen. Exit-Code: $($process.ExitCode)" -ForegroundColor Red
                $outputBox.AppendText("`t[X] DISM Scan fehlgeschlagen. Exit-Code: $($process.ExitCode)`r`n")
            }
        }
        Write-Host "`n" + ("═" * 70) -ForegroundColor Cyan 
        # ProgressBar zurücksetzen
        if ($progressBar) {
            $progressBar.Value = 100
            Update-ProgressStatus -StatusText "DISM Scan abgeschlossen" -ProgressValue 100 -TextColor ([System.Drawing.Color]::LimeGreen) -progressBarParam $progressBar
            Start-Sleep -Milliseconds 500
            $progressBar.Value = 0
        }
    }
    catch {
        Write-Host "`n`t[X] Fehler beim DISM Scan: $_" -ForegroundColor Red
        $outputBox.AppendText("`t[X] Fehler beim DISM Scan: $_`r`n")
        if ($progressBar) {
            $progressBar.Value = 0
        }
    }
}

# Function to run DISM Restore Health
function Start-RestoreDISM {
    param (
        [System.Windows.Forms.RichTextBox]$outputBox,
        [System.Windows.Forms.ProgressBar]$progressBar
    )

    Clear-Host
    # outputBox zuruecksetzen
    $outputBox.Clear()

    # Stelle sicher, dass die ProgressBar initialisiert ist
    if ($progressBar) {
        Initialize-ProgressComponents -ProgressBar $progressBar -StatusLabel $null
    }
    
    # In Log-Datei und Datenbank schreiben, dass die DISM Reparatur startet
    Write-ToolLog -ToolName "DISM-Repair" -Message "`n`t[►]DISM Restore Health wird gestartet" -OutputBox $outputBox -Style 'Action' -Level "Information" -SaveToDatabase
    
    # Rahmen und Systeminformationen erstellen
    #$computerName = $env:COMPUTERNAME
    #$userName = $env:USERNAME
    #$osInfo = (Get-CimInstance -ClassName Win32_OperatingSystem).Caption
    #$dateTime = Get-Date -Format "dd.MM.yyyy HH:mm:ss"
    #$width = 80
        
    # Rahmen oben
    Write-Host "╔══════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-ColoredCenteredText                          "DISM RESTORE HEALTH"                                         
    Write-Host "╚══════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Green
    
    # ASCII-Art Logo
    Write-Host
    Write-Host
    Write-Host '  8888888b.  8888888  .d8888b.  888b     d888     ' -ForegroundColor Cyan
    Write-Host '  888  "Y88b   888   d88P  Y88b 8888b   d8888     ' -ForegroundColor Blue
    Write-Host '  888    888   888   Y88b.      88888b.d88888     ' -ForegroundColor Cyan
    Write-Host '  888    888   888    "Y888b.   888Y88888P888     ' -ForegroundColor Blue
    Write-Host '  888    888   888       "Y88b. 888 Y888P 888     ' -ForegroundColor Cyan
    Write-Host '  888    888   888         "888 888  Y8P  888     ' -ForegroundColor Blue
    Write-Host '  888  .d88P   888   Y88b  d88P 888   "   888     ' -ForegroundColor Cyan
    Write-Host '  8888888P"  8888888  "Y8888P"  888       888     ' -ForegroundColor Blue
    Write-Host
    Write-Host '                     8888888b.                   888                                      ' -ForegroundColor Cyan
    Write-Host '                     888   Y88b                  888                                      ' -ForegroundColor Blue
    Write-Host '                     888    888                  888                                      ' -ForegroundColor Cyan
    Write-Host '                     888   d88P .d88b.  .d8888b  888888 .d88b.  888d888 .d88b.            ' -ForegroundColor Blue
    Write-Host '                     8888888P" d8P  Y8b 88K      888   d88""88b 888P"  d8P  Y8b           ' -ForegroundColor Cyan
    Write-Host '                     888 T88b  88888888 "Y8888b. 888   888  888 888    88888888           ' -ForegroundColor Blue
    Write-Host '                     888  T88b Y8b.          X88 Y88b. Y88..88P 888    Y8b.               ' -ForegroundColor Cyan
    Write-Host '                     888   T88b "Y8888   88888P"  "Y888 "Y88P"  888     "Y8888            ' -ForegroundColor Blue
    Write-Host
    Write-Host
    # Rahmen für Systeminformationen
    Write-Host "╔══════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-ColoredCenteredText                        "INFORMATIONEN"
    Write-Host "╠══════════════════════════════════════════════════════════════════════════════╣" -ForegroundColor Green
    # Systeminformationen
    Write-Host "║                                                                              ║" -ForegroundColor Green
    Write-Host "  ├─  Systemabbild reparieren mit DISM (RestoreHealth):                           "  -ForegroundColor Yellow                 
    Write-Host "  ├─  DISM überprüft und repariert beschädigte Windows-Komponenten.               "  -ForegroundColor Yellow                                    
    Write-Host "  ├─  Er nutzt Windows Update oder ein lokales Abbild zur Wiederherstellung.      "  -ForegroundColor Yellow                                    
    Write-Host "  └─  Empfohlen bei hartnäckigen Systemfehlern oder wenn SFC nicht ausreicht.     "  -ForegroundColor Yellow                                  
    Write-Host "║                                                                              ║" -ForegroundColor Green

    Write-Host "╠══════════════════════════════════════════════════════════════════════════════╣" -ForegroundColor Green
    Write-ColoredCenteredText                  "[►] Starte DISM Reparatur..."
    Write-Host "╚══════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Green
    
    # 3 Sekunden warten vor dem Start
    Start-Sleep -Seconds 3

    # Log-Datei-Pfad definieren
    $logPath = "$env:TEMP\dism_restore.log"
    $resultPath = "$env:TEMP\dism_restore_result.json"

    # Header für die Ausgabe
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Action'
    $outputBox.AppendText("`n`t=== DISM Restore Health ===`n")
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Default'
    $outputBox.AppendText("`tZeitpunkt: $(Get-Date -Format 'dd.MM.yyyy HH:mm:ss')`n`n")

    try {
        # ProgressBar aktualisieren
        if ($progressBar) {
            $progressBar.Value = 10
            Update-ProgressStatus -StatusText "DISM Reparatur wird vorbereitet..." -ProgressValue 10 -TextColor ([System.Drawing.Color]::White) -progressBarParam $progressBar
        }

        # Kurze Pause für visuelles Feedback mit DoEvents für GUI-Responsivität
        for ($i = 0; $i -lt 30; $i++) {
            Start-Sleep -Milliseconds 100
            [System.Windows.Forms.Application]::DoEvents()
        }

        if ($progressBar) {
            $progressBar.Value = 40
            Update-ProgressStatus -StatusText "DISM Reparatur wird gestartet..." -ProgressValue 40 -TextColor ([System.Drawing.Color]::White) -progressBarParam $progressBar
        }
        
        # Den DISM-Befehl ausführen
        if ($progressBar) {
            $progressBar.Value = 60
            Update-ProgressStatus -StatusText "DISM Reparatur läuft..." -ProgressValue 60 -TextColor ([System.Drawing.Color]::White) -progressBarParam $progressBar
        }
        
        $process = Start-Process "dism.exe" -ArgumentList "/Online /Cleanup-Image /RestoreHealth" -NoNewWindow -Wait -PassThru

        # ProgressBar aktualisieren
        if ($progressBar) {
            $progressBar.Value = 90
            Update-ProgressStatus -StatusText "DISM Reparatur wird abgeschlossen..." -ProgressValue 90 -TextColor ([System.Drawing.Color]::White) -progressBarParam $progressBar
        }

        # Ergebnis in JSON speichern
        $result = @{
            ExitCode  = $process.ExitCode
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
        $result | ConvertTo-Json | Set-Content -Path $resultPath
        Write-Host "`n" + ("═" * 70) -ForegroundColor Cyan 
        # Ergebnis auswerten
        switch ($process.ExitCode) {
            0 { 
                Write-Host "`n`t[✓] DISM Restore Health erfolgreich abgeschlossen!" -ForegroundColor Green
                $outputBox.AppendText("`t[✓] DISM Restore erfolgreich abgeschlossen.`r`n")
            }
            default {
                Write-Host "`n`t[X] DISM Restore Health fehlgeschlagen. Exit-Code: $($process.ExitCode)" -ForegroundColor Red
                $outputBox.AppendText("`t[X] DISM Restore fehlgeschlagen. Exit-Code: $($process.ExitCode)`r`n")
            }
        }
        Write-Host "`n" + ("═" * 70) -ForegroundColor Cyan 
        # ProgressBar zurücksetzen
        if ($progressBar) {
            $progressBar.Value = 100
            Update-ProgressStatus -StatusText "DISM Reparatur abgeschlossen" -ProgressValue 100 -TextColor ([System.Drawing.Color]::LimeGreen) -progressBarParam $progressBar
            Start-Sleep -Milliseconds 500
            $progressBar.Value = 0
        }
    }
    catch {
        Write-Host "`n`t[X] Fehler beim DISM Restore: $_" -ForegroundColor Red
        $outputBox.AppendText("`t[X] Fehler beim DISM Restore: $_`r`n")
        if ($progressBar) {
            $progressBar.Value = 0
        }
    }
}

# Export functions
Export-ModuleMember -Function Start-CheckDISM, Start-ScanDISM, Start-RestoreDISM

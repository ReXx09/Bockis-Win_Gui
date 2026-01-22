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
    $resultPath = Join-Path $PSScriptRoot "..\..\Data\Temp\dism_check_result.json"

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
    $logPath = Join-Path $PSScriptRoot "..\..\Data\Temp\dism_scan.log"
    $resultPath = Join-Path $PSScriptRoot "..\..\Data\Temp\dism_scan_result.json"

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
    $logPath = Join-Path $PSScriptRoot "..\..\Data\Temp\dism_restore.log"
    $resultPath = Join-Path $PSScriptRoot "..\..\Data\Temp\dism_restore_result.json"

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

# SIG # Begin signature block
# MIIcSgYJKoZIhvcNAQcCoIIcOzCCHDcCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDK8iaggYlLrW08
# TOSRgwFNmPmdLZKJuSN5eXHZWPx/VqCCFnowggM8MIICJKADAgECAhBJfyGrXBJT
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
# MQ4wDAYKKwYBBAGCNwIBFTAvBgkqhkiG9w0BCQQxIgQgiO3Y5o40CbrEFkBgiPAC
# 37uioPusH/I+cXxXQmjWMb8wDQYJKoZIhvcNAQEBBQAEggEAX1n+AmpaCrkFV1v2
# gDJGtORmymy1zpQV5HF1MUrTS7ZJZ943DP938UAWAM6b7V1fT8deL6YkTWy/A5GL
# r9UTac8fmZ0EeeWaNNJ3qbLwJt3uRmbToK2BS4fEXgbql+yTmijGqwNhesdJB8H2
# Ij6WUgScu8KZLGufc1EvyeHhAYbx93DYy04uW8D7ABG+UZztpMS77ziRGedQReRa
# /gSqca+N/k37e4xyESOjZiyDDmPsChqIYQqYd1shreikenHjUUw/+YSrcWeDYW3e
# RFEiZ6lB3F2s3N5usoSNiYxoooYIp0iYneMvzjhcNSUeCNAEGch/ldLnwJGoAFVX
# vMV1pKGCAyYwggMiBgkqhkiG9w0BCQYxggMTMIIDDwIBATB9MGkxCzAJBgNVBAYT
# AlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5jLjFBMD8GA1UEAxM4RGlnaUNlcnQg
# VHJ1c3RlZCBHNCBUaW1lU3RhbXBpbmcgUlNBNDA5NiBTSEEyNTYgMjAyNSBDQTEC
# EAqA7xhLjfEFgtHEdqeVdGgwDQYJYIZIAWUDBAIBBQCgaTAYBgkqhkiG9w0BCQMx
# CwYJKoZIhvcNAQcBMBwGCSqGSIb3DQEJBTEPFw0yNjAxMjAxODAyNTVaMC8GCSqG
# SIb3DQEJBDEiBCCV33ak8d8BmphgSYW0h8myVBKunvd2oNmfMmhXkUK1RDANBgkq
# hkiG9w0BAQEFAASCAgAi6TeXkeCae37z5IGI9AGLAWMBVRJ/kTQqR7+9R0q8V40B
# G4PXwwqLRSxPMUVo4qs3plWJqK5TiLxgube10cf6KiUgETSyT12nBLRNrMv1gNIs
# Jcobo9oJD/7l8PfSo87EUrenbSSp9ydG6gRlFk9NJ9i480QkJt/zsXfmr7qlhwML
# M+03d2lF8jeO2W4bA6MeH5W+iNK8j2ltnyqJXRfAjRF6HEKkDzYsvwfF2j9Tts1f
# 1Nwbt620fRuc2+IStMemeFqzNH9Z+KtjnfK3OQchwr+NufNtX5+69Jy1Zx9NEJmn
# i2tWmuOCM78syxTgvs1FcbmfDzUbZTKqok+GaDxcBpzMkxYTLXbRwVAuraFfFi5h
# VxA4P22ah1I57nl7+tvIr4MAAjIQwOQE3RoVlCIznMf31vc5zz367rA/wNSR0pso
# 3YbcLx77TI+Q/98htETGAvvPq/fK63oIb2XScVchLIy1bQNQbNBoPCdRahuTJfvB
# jXeE4H7Im9GSRNeMPbjtY0ZBwe4xC5rM/ztNdBiE1LUWHABA4gOTPHhP0l4i75OQ
# DjtzSmYxWl82MFqU1BycFWg9ufmIsfjjnihndOkIdc3N+Bi4bLLcrmHw+v3wxugG
# L8naaSUee8bLEeHn3+0UpFTr18tOSNQSi0gyqhpcx6461BerHycHxbxNDnpK2w==
# SIG # End signature block

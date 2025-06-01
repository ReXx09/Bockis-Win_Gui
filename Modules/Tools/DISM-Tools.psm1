# Import required modules
Import-Module "$PSScriptRoot\..\Core\Core.psm1" -Force
Import-Module "$PSScriptRoot\..\Core\ProgressBarTools.psm1" -Force

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
    
    # Rahmen und Systeminformationen erstellen
    $computerName = $env:COMPUTERNAME
    $userName = $env:USERNAME
    $osInfo = (Get-CimInstance -ClassName Win32_OperatingSystem).Caption
    $dateTime = Get-Date -Format "dd.MM.yyyy HH:mm:ss"
    $width = 80
        
    # Rahmen oben
    Write-Host "╔══════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-ColoredCenteredText                             "DISM CHECK HEALTH"                                         
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
    Write-Host "║                              SYSTEMINFORMATIONEN                             ║" -ForegroundColor Green
    Write-Host "╠══════════════════════════════════════════════════════════════════════════════╣" -ForegroundColor Green
    # Systeminformationen
    Write-Host "║                                                                              ║" -ForegroundColor Green
    Write-Host "      ├─    Betriebssystem: $osInfo           "            -ForegroundColor Yellow                 
    Write-Host "      ├─    Computer:       $computerName     "            -ForegroundColor Yellow                                    
    Write-Host "      ├─    Benutzer:       $userName         "            -ForegroundColor Yellow                                    
    Write-Host "      └─    Datum und Zeit: $dateTime         "            -ForegroundColor Yellow                                  
    Write-Host "║                                                                              ║" -ForegroundColor Green

    Write-Host "╠══════════════════════════════════════════════════════════════════════════════╣" -ForegroundColor Green
    Write-ColoredCenteredText                          "Starte DISM Check..."
    Write-Host "╚══════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Green
    
    # 3 Sekunden warten vor dem Start
    Start-Sleep -Seconds 3

    # Ergebnis-Pfad für JSON definieren (logPath wurde entfernt, da nicht verwendet)
    $resultPath = "$env:TEMP\dism_check_result.json"

    # Header für die Ausgabe
    $outputBox.AppendText("`n=== DISM Check Health ===`n")
    $outputBox.AppendText("Zeitpunkt: $(Get-Date -Format 'dd.MM.yyyy HH:mm:ss')`n`n")

    try {
        # ProgressBar aktualisieren
        if ($progressBar) {
            $progressBar.Value = 10
            Update-ProgressStatus -StatusText "DISM Check wird vorbereitet..." -ProgressValue 10 -TextColor ([System.Drawing.Color]::DarkBlue) -progressBarParam $progressBar
        }

        # Den DISM-Befehl ausführen
        $process = Start-Process "dism.exe" -ArgumentList "/Online /Cleanup-Image /CheckHealth" -NoNewWindow -Wait -PassThru

        # ProgressBar aktualisieren
        if ($progressBar) {
            $progressBar.Value = 90
            Update-ProgressStatus -StatusText "DISM Check wird abgeschlossen..." -ProgressValue 90 -TextColor ([System.Drawing.Color]::DarkBlue) -progressBarParam $progressBar
        }

        # Ergebnis in JSON speichern
        $result = @{
            ExitCode  = $process.ExitCode
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
        $result | ConvertTo-Json | Set-Content -Path $resultPath

        # Ergebnis auswerten
        switch ($process.ExitCode) {
            0 { 
                Write-Host "`nDISM Check Health erfolgreich abgeschlossen!" -ForegroundColor Green
                $outputBox.AppendText("✅ DISM Check erfolgreich abgeschlossen.`n")
            }
            default {
                Write-Host "`nDISM Check Health fehlgeschlagen. Exit-Code: $($process.ExitCode)" -ForegroundColor Red
                $outputBox.AppendText("❌ DISM Check fehlgeschlagen. Exit-Code: $($process.ExitCode)`n")
            }
        }

        # ProgressBar zurücksetzen
        if ($progressBar) {
            $progressBar.Value = 100
            Update-ProgressStatus -StatusText "DISM Check abgeschlossen" -ProgressValue 100 -TextColor ([System.Drawing.Color]::Green) -progressBarParam $progressBar
            Start-Sleep -Milliseconds 500
            $progressBar.Value = 0
        }
    }
    catch {
        Write-Host "`nFehler beim DISM Check: $_" -ForegroundColor Red
        $outputBox.AppendText("❌ Fehler beim DISM Check: $_`n")
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
    
    # Rahmen und Systeminformationen erstellen
    $computerName = $env:COMPUTERNAME
    $userName = $env:USERNAME
    $osInfo = (Get-CimInstance -ClassName Win32_OperatingSystem).Caption
    $dateTime = Get-Date -Format "dd.MM.yyyy HH:mm:ss"
    $width = 80
        
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
    Write-Host "║                              SYSTEMINFORMATIONEN                             ║" -ForegroundColor Green
    Write-Host "╠══════════════════════════════════════════════════════════════════════════════╣" -ForegroundColor Green
    Write-Host "║                                                                              ║" -ForegroundColor Green
    Write-Host "      ├─    Betriebssystem: $osInfo           "            -ForegroundColor Yellow                 
    Write-Host "      ├─    Computer:       $computerName     "            -ForegroundColor Yellow                                    
    Write-Host "      ├─    Benutzer:       $userName         "            -ForegroundColor Yellow                                    
    Write-Host "      └─    Datum und Zeit: $dateTime         "            -ForegroundColor Yellow                                  
    Write-Host "║                                                                              ║" -ForegroundColor Green
    Write-Host "╠══════════════════════════════════════════════════════════════════════════════╣" -ForegroundColor Green
    Write-ColoredCenteredText                          "Starte DISM Scan..."
    Write-Host "╚══════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Green
    
    # 3 Sekunden warten vor dem Start
    Start-Sleep -Seconds 3

    # Log-Datei-Pfad definieren
    $logPath = "$env:TEMP\dism_scan.log"
    $resultPath = "$env:TEMP\dism_scan_result.json"

    # Header für die Ausgabe
    $outputBox.AppendText("`n=== DISM Scan Health ===`n")
    $outputBox.AppendText("Zeitpunkt: $(Get-Date -Format 'dd.MM.yyyy HH:mm:ss')`n`n")

    try {
        # ProgressBar aktualisieren
        if ($progressBar) {
            $progressBar.Value = 10
            Update-ProgressStatus -StatusText "DISM Scan wird vorbereitet..." -ProgressValue 10 -TextColor ([System.Drawing.Color]::DarkBlue) -progressBarParam $progressBar
        }

        # Den DISM-Befehl ausführen
        $process = Start-Process "dism.exe" -ArgumentList "/Online /Cleanup-Image /ScanHealth" -NoNewWindow -Wait -PassThru

        # ProgressBar aktualisieren
        if ($progressBar) {
            $progressBar.Value = 90
            Update-ProgressStatus -StatusText "DISM Scan wird abgeschlossen..." -ProgressValue 90 -TextColor ([System.Drawing.Color]::DarkBlue) -progressBarParam $progressBar
        }

        # Ergebnis in JSON speichern
        $result = @{
            ExitCode  = $process.ExitCode
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
        $result | ConvertTo-Json | Set-Content -Path $resultPath

        # Ergebnis auswerten
        switch ($process.ExitCode) {
            0 { 
                Write-Host "`nDISM Scan Health erfolgreich abgeschlossen!" -ForegroundColor Green
                $outputBox.AppendText("✅ DISM Scan erfolgreich abgeschlossen.`n")
            }
            default {
                Write-Host "`nDISM Scan Health fehlgeschlagen. Exit-Code: $($process.ExitCode)" -ForegroundColor Red
                $outputBox.AppendText("❌ DISM Scan fehlgeschlagen. Exit-Code: $($process.ExitCode)`n")
            }
        }

        # ProgressBar zurücksetzen
        if ($progressBar) {
            $progressBar.Value = 100
            Update-ProgressStatus -StatusText "DISM Scan abgeschlossen" -ProgressValue 100 -TextColor ([System.Drawing.Color]::Green) -progressBarParam $progressBar
            Start-Sleep -Milliseconds 500
            $progressBar.Value = 0
        }
    }
    catch {
        Write-Host "`nFehler beim DISM Scan: $_" -ForegroundColor Red
        $outputBox.AppendText("❌ Fehler beim DISM Scan: $_`n")
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
    
    # Rahmen und Systeminformationen erstellen
    $computerName = $env:COMPUTERNAME
    $userName = $env:USERNAME
    $osInfo = (Get-CimInstance -ClassName Win32_OperatingSystem).Caption
    $dateTime = Get-Date -Format "dd.MM.yyyy HH:mm:ss"
    $width = 80
        
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
    Write-Host "║                              SYSTEMINFORMATIONEN                             ║" -ForegroundColor Green
    Write-Host "╠══════════════════════════════════════════════════════════════════════════════╣" -ForegroundColor Green
    # Systeminformationen
    Write-Host "║                                                                              ║" -ForegroundColor Green
    Write-Host "      ├─    Betriebssystem: $osInfo           "            -ForegroundColor Yellow                 
    Write-Host "      ├─    Computer:       $computerName     "            -ForegroundColor Yellow                                    
    Write-Host "      ├─    Benutzer:       $userName         "            -ForegroundColor Yellow                                    
    Write-Host "      └─    Datum und Zeit: $dateTime         "            -ForegroundColor Yellow                                  
    Write-Host "║                                                                              ║" -ForegroundColor Green

    Write-Host "╠══════════════════════════════════════════════════════════════════════════════╣" -ForegroundColor Green
    Write-ColoredCenteredText                      "Starte DISM Reparatur..."
    Write-Host "╚══════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Green
    
    # 3 Sekunden warten vor dem Start
    Start-Sleep -Seconds 3

    # Log-Datei-Pfad definieren
    $logPath = "$env:TEMP\dism_restore.log"
    $resultPath = "$env:TEMP\dism_restore_result.json"

    # Header für die Ausgabe
    $outputBox.AppendText("`n=== DISM Restore Health ===`n")
    $outputBox.AppendText("Zeitpunkt: $(Get-Date -Format 'dd.MM.yyyy HH:mm:ss')`n`n")

    try {
        # ProgressBar aktualisieren
        if ($progressBar) {
            $progressBar.Value = 10
            Update-ProgressStatus -StatusText "DISM Reparatur wird vorbereitet..." -ProgressValue 10 -TextColor ([System.Drawing.Color]::DarkBlue) -progressBarParam $progressBar
        }

        # Den DISM-Befehl ausführen
        $process = Start-Process "dism.exe" -ArgumentList "/Online /Cleanup-Image /RestoreHealth" -NoNewWindow -Wait -PassThru

        # ProgressBar aktualisieren
        if ($progressBar) {
            $progressBar.Value = 90
            Update-ProgressStatus -StatusText "DISM Reparatur wird abgeschlossen..." -ProgressValue 90 -TextColor ([System.Drawing.Color]::DarkBlue) -progressBarParam $progressBar
        }

        # Ergebnis in JSON speichern
        $result = @{
            ExitCode  = $process.ExitCode
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
        $result | ConvertTo-Json | Set-Content -Path $resultPath

        # Ergebnis auswerten
        switch ($process.ExitCode) {
            0 { 
                Write-Host "`nDISM Restore Health erfolgreich abgeschlossen!" -ForegroundColor Green
                $outputBox.AppendText("✅ DISM Restore erfolgreich abgeschlossen.`n")
            }
            default {
                Write-Host "`nDISM Restore Health fehlgeschlagen. Exit-Code: $($process.ExitCode)" -ForegroundColor Red
                $outputBox.AppendText("❌ DISM Restore fehlgeschlagen. Exit-Code: $($process.ExitCode)`n")
            }
        }

        # ProgressBar zurücksetzen
        if ($progressBar) {
            $progressBar.Value = 100
            Update-ProgressStatus -StatusText "DISM Reparatur abgeschlossen" -ProgressValue 100 -TextColor ([System.Drawing.Color]::Green) -progressBarParam $progressBar
            Start-Sleep -Milliseconds 500
            $progressBar.Value = 0
        }
    }
    catch {
        Write-Host "`nFehler beim DISM Restore: $_" -ForegroundColor Red
        $outputBox.AppendText("❌ Fehler beim DISM Restore: $_`n")
        if ($progressBar) {
            $progressBar.Value = 0
        }
    }
}

# Export functions
Export-ModuleMember -Function Start-CheckDISM, Start-ScanDISM, Start-RestoreDISM
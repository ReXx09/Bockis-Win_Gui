# Import required modules
Import-Module "$PSScriptRoot\..\Core\Core.psm1" -Force

# Function to run DISM Check Health
function Start-CheckDISM {
    param (
        [System.Windows.Forms.RichTextBox]$outputBox,
        [System.Windows.Forms.ProgressBar]$progressBar
    )

    # Log-Datei-Pfad definieren
    $logPath = "$env:TEMP\dism_check.log"
    $resultPath = "$env:TEMP\dism_check_result.json"

    # Header für die Ausgabe
    $outputBox.AppendText("`n=== DISM Check Health ===`n")
    $outputBox.AppendText("Zeitpunkt: $(Get-Date -Format 'dd.MM.yyyy HH:mm:ss')`n`n")

    try {
        # ProgressBar aktualisieren
        if ($progressBar) {
            $progressBar.Value = 10
            $progressBar.Refresh()
        }

        # DISM-Befehl ausführen und Ausgabe in Log-Datei umleiten
        $process = Start-Process "dism.exe" -ArgumentList "/Online /Cleanup-Image /CheckHealth" -NoNewWindow -Wait -PassThru -RedirectStandardOutput $logPath

        # ProgressBar aktualisieren
        if ($progressBar) {
            $progressBar.Value = 50
            $progressBar.Refresh()
        }

        # Ergebnis in JSON speichern
        $result = @{
            ExitCode  = $process.ExitCode
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            LogPath   = $logPath
        }
        $result | ConvertTo-Json | Set-Content -Path $resultPath

        # ProgressBar aktualisieren
        if ($progressBar) {
            $progressBar.Value = 90
            $progressBar.Refresh()
        }

        # Ergebnis auswerten
        switch ($process.ExitCode) {
            0 { 
                $outputBox.AppendText("✅ DISM Check erfolgreich abgeschlossen.`n")
                $outputBox.AppendText("Keine Probleme gefunden.`n")
            }
            default {
                $outputBox.AppendText("❌ DISM Check fehlgeschlagen. Exit-Code: $($process.ExitCode)`n")
                $outputBox.AppendText("Bitte überprüfen Sie die Log-Datei: $logPath`n")
            }
        }

        # Log-Datei anzeigen, falls vorhanden
        if (Test-Path $logPath) {
            $outputBox.AppendText("`n=== Log-Datei Inhalt ===`n")
            $outputBox.AppendText((Get-Content $logPath -Raw))
        }

        # ProgressBar zurücksetzen
        if ($progressBar) {
            $progressBar.Value = 100
            $progressBar.Refresh()
            Start-Sleep -Milliseconds 500
            $progressBar.Value = 0
        }

    }
    catch {
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
            $progressBar.Refresh()
        }

        # DISM-Befehl ausführen und Ausgabe in Log-Datei umleiten
        $process = Start-Process "dism.exe" -ArgumentList "/Online /Cleanup-Image /ScanHealth" -NoNewWindow -Wait -PassThru -RedirectStandardOutput $logPath

        # ProgressBar aktualisieren
        if ($progressBar) {
            $progressBar.Value = 50
            $progressBar.Refresh()
        }

        # Ergebnis in JSON speichern
        $result = @{
            ExitCode  = $process.ExitCode
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            LogPath   = $logPath
        }
        $result | ConvertTo-Json | Set-Content -Path $resultPath

        # ProgressBar aktualisieren
        if ($progressBar) {
            $progressBar.Value = 90
            $progressBar.Refresh()
        }

        # Ergebnis auswerten
        switch ($process.ExitCode) {
            0 { 
                $outputBox.AppendText("✅ DISM Scan erfolgreich abgeschlossen.`n")
                $outputBox.AppendText("Keine Probleme gefunden.`n")
            }
            default {
                $outputBox.AppendText("❌ DISM Scan fehlgeschlagen. Exit-Code: $($process.ExitCode)`n")
                $outputBox.AppendText("Bitte überprüfen Sie die Log-Datei: $logPath`n")
            }
        }

        # Log-Datei anzeigen, falls vorhanden
        if (Test-Path $logPath) {
            $outputBox.AppendText("`n=== Log-Datei Inhalt ===`n")
            $outputBox.AppendText((Get-Content $logPath -Raw))
        }

        # ProgressBar zurücksetzen
        if ($progressBar) {
            $progressBar.Value = 100
            $progressBar.Refresh()
            Start-Sleep -Milliseconds 500
            $progressBar.Value = 0
        }

    }
    catch {
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
            $progressBar.Refresh()
        }

        # DISM-Befehl ausführen und Ausgabe in Log-Datei umleiten
        $process = Start-Process "dism.exe" -ArgumentList "/Online /Cleanup-Image /RestoreHealth" -NoNewWindow -Wait -PassThru -RedirectStandardOutput $logPath

        # ProgressBar aktualisieren
        if ($progressBar) {
            $progressBar.Value = 50
            $progressBar.Refresh()
        }

        # Ergebnis in JSON speichern
        $result = @{
            ExitCode  = $process.ExitCode
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            LogPath   = $logPath
        }
        $result | ConvertTo-Json | Set-Content -Path $resultPath

        # ProgressBar aktualisieren
        if ($progressBar) {
            $progressBar.Value = 90
            $progressBar.Refresh()
        }

        # Ergebnis auswerten
        switch ($process.ExitCode) {
            0 { 
                $outputBox.AppendText("✅ DISM Restore erfolgreich abgeschlossen.`n")
                $outputBox.AppendText("Windows-Image wurde erfolgreich repariert.`n")
            }
            default {
                $outputBox.AppendText("❌ DISM Restore fehlgeschlagen. Exit-Code: $($process.ExitCode)`n")
                $outputBox.AppendText("Bitte überprüfen Sie die Log-Datei: $logPath`n")
            }
        }

        # Log-Datei anzeigen, falls vorhanden
        if (Test-Path $logPath) {
            $outputBox.AppendText("`n=== Log-Datei Inhalt ===`n")
            $outputBox.AppendText((Get-Content $logPath -Raw))
        }

        # ProgressBar zurücksetzen
        if ($progressBar) {
            $progressBar.Value = 100
            $progressBar.Refresh()
            Start-Sleep -Milliseconds 500
            $progressBar.Value = 0
        }

    }
    catch {
        $outputBox.AppendText("❌ Fehler beim DISM Restore: $_`n")
        if ($progressBar) {
            $progressBar.Value = 0
        }
    }
}

# Export functions
Export-ModuleMember -Function Start-CheckDISM, Start-ScanDISM, Start-RestoreDISM 
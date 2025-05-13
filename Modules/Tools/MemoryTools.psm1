function Start-MemoryDiagnostic {
    param (
        [System.Windows.Forms.RichTextBox]$outputBox,
        [System.Windows.Forms.ProgressBar]$progressBar
    )

    # Log-Datei-Pfad definieren
    $logPath = "$env:TEMP\memory_diagnostic.log"
    $resultPath = "$env:TEMP\memory_diagnostic_result.json"

    # Header für die Ausgabe
    $outputBox.AppendText("`n=== Windows Memory Diagnostic ===`n")
    $outputBox.AppendText("Zeitpunkt: $(Get-Date -Format 'dd.MM.yyyy HH:mm:ss')`n`n")

    try {
        # ProgressBar aktualisieren
        if ($progressBar) {
            $progressBar.Value = 10
            $progressBar.Refresh()
        }

        # Memory Diagnostic starten
        $process = Start-Process "mdsched.exe" -ArgumentList "/run" -NoNewWindow -Wait -PassThru -RedirectStandardOutput $logPath

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
                $outputBox.AppendText("✅ Memory Diagnostic erfolgreich abgeschlossen.`n")
                $outputBox.AppendText("Keine Speicherprobleme gefunden.`n")
            }
            default {
                $outputBox.AppendText("❌ Memory Diagnostic fehlgeschlagen. Exit-Code: $($process.ExitCode)`n")
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
        $outputBox.AppendText("❌ Fehler bei der Memory Diagnostic: $_`n")
        if ($progressBar) {
            $progressBar.Value = 0
        }
    }
} 
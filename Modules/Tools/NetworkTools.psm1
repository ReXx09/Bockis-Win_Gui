# Import required modules
Import-Module "$PSScriptRoot\..\Core\Core.psm1" -Force -Global
Import-Module "$PSScriptRoot\..\Core\TextStyle.psm1" -Force -Global

function Set-NetworkOutputStyle {
    param(
        [System.Windows.Forms.RichTextBox]$OutputBox,
        [string]$Style = 'Default'
    )

    if ($OutputBox) {
        Set-OutputSelectionStyle -OutputBox $OutputBox -Style $Style
    }
}

# Function to run ping test
function Start-PingTest {
    param (
        [System.Windows.Forms.RichTextBox]$outputBox
    )
    
    # Log-Eintrag erstellen
    Write-ToolLog -ToolName "NetworkTools" -Message "Ping-Test wird gestartet" -OutputBox $outputBox -Style 'Action' -Level "Information" -SaveToDatabase
    
    # Erstelle ein Dialog-Fenster für die Ping-Einstellungen
    $pingForm = New-Object System.Windows.Forms.Form
    $pingForm.Text = "Ping-Test Einstellungen"
    $pingForm.Size = New-Object System.Drawing.Size(400, 300)
    $pingForm.StartPosition = "CenterScreen"
    $pingForm.FormBorderStyle = "FixedDialog"
    $pingForm.MaximizeBox = $false
    
    # Host/IP-Adresse Label
    $hostLabel = New-Object System.Windows.Forms.Label
    $hostLabel.Location = New-Object System.Drawing.Point(10, 20)
    $hostLabel.Size = New-Object System.Drawing.Size(120, 20)
    $hostLabel.Text = "Host/IP-Adresse:"
    $pingForm.Controls.Add($hostLabel)
    
    # Host/IP-Adresse Eingabefeld mit Vorschlägen
    $hostTextBox = New-Object System.Windows.Forms.ComboBox
    $hostTextBox.Location = New-Object System.Drawing.Point(140, 20)
    $hostTextBox.Size = New-Object System.Drawing.Size(230, 20)
    $hostTextBox.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDown
    
    # Füge einige Standard-Hosts zur Auswahl hinzu
    $standardHosts = @("google.com", "8.8.8.8", "microsoft.com", "192.168.0.1", "fritz.box")
    foreach ($targetHost in $standardHosts) {
        $hostTextBox.Items.Add($targetHost) | Out-Null
    }
    
    $pingForm.Controls.Add($hostTextBox)
    
    # Anzahl der Pings Label
    $countLabel = New-Object System.Windows.Forms.Label
    $countLabel.Location = New-Object System.Drawing.Point(10, 60)
    $countLabel.Size = New-Object System.Drawing.Size(120, 25)
    $countLabel.Text = "Anzahl der Pings:"
    $pingForm.Controls.Add($countLabel)
    
    # Anzahl der Pings Eingabefeld
    $countNumeric = New-Object System.Windows.Forms.NumericUpDown
    $countNumeric.Location = New-Object System.Drawing.Point(140, 60)
    $countNumeric.Size = New-Object System.Drawing.Size(80, 25)
    $countNumeric.Minimum = 1
    $countNumeric.Maximum = 100
    $countNumeric.Value = 4
    $pingForm.Controls.Add($countNumeric)
    
    # Timeout Label
    $timeoutLabel = New-Object System.Windows.Forms.Label
    $timeoutLabel.Location = New-Object System.Drawing.Point(10, 100)
    $timeoutLabel.Size = New-Object System.Drawing.Size(120, 25)
    $timeoutLabel.Text = "Timeout (ms):"
    $pingForm.Controls.Add($timeoutLabel)
    
    # Timeout Eingabefeld
    $timeoutNumeric = New-Object System.Windows.Forms.NumericUpDown
    $timeoutNumeric.Location = New-Object System.Drawing.Point(140, 100)
    $timeoutNumeric.Size = New-Object System.Drawing.Size(80, 25)
    $timeoutNumeric.Minimum = 100
    $timeoutNumeric.Maximum = 10000
    $timeoutNumeric.Increment = 100
    $timeoutNumeric.Value = 1000
    $pingForm.Controls.Add($timeoutNumeric)
    
    # Buffer-Größe Label
    $bufferLabel = New-Object System.Windows.Forms.Label
    $bufferLabel.Location = New-Object System.Drawing.Point(10, 140)
    $bufferLabel.Size = New-Object System.Drawing.Size(120, 25)
    $bufferLabel.Text = "Buffer-Größe (Bytes):"
    $pingForm.Controls.Add($bufferLabel)
    
    # Buffer-Größe Eingabefeld
    $bufferNumeric = New-Object System.Windows.Forms.NumericUpDown
    $bufferNumeric.Location = New-Object System.Drawing.Point(140, 140)
    $bufferNumeric.Size = New-Object System.Drawing.Size(80, 25)
    $bufferNumeric.Minimum = 32
    $bufferNumeric.Maximum = 65500
    $bufferNumeric.Increment = 32
    $bufferNumeric.Value = 32
    $pingForm.Controls.Add($bufferNumeric)
    
    # OK Button
    $okButton = New-Object System.Windows.Forms.Button
    $okButton.Location = New-Object System.Drawing.Point(80, 210)
    $okButton.Size = New-Object System.Drawing.Size(100, 30)
    $okButton.Text = "Start"
    $okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $pingForm.Controls.Add($okButton)
    $pingForm.AcceptButton = $okButton
    
    # Cancel Button
    $cancelButton = New-Object System.Windows.Forms.Button
    $cancelButton.Location = New-Object System.Drawing.Point(200, 210)
    $cancelButton.Size = New-Object System.Drawing.Size(100, 30)
    $cancelButton.Text = "Abbrechen"
    $cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $pingForm.Controls.Add($cancelButton)
    $pingForm.CancelButton = $cancelButton
    
    # Dialog anzeigen
    $result = $pingForm.ShowDialog()
    
    if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
        $targetHost = $hostTextBox.Text
        $count = $countNumeric.Value
        $timeout = $timeoutNumeric.Value
        $bufferSize = $bufferNumeric.Value
        
        if ([string]::IsNullOrWhiteSpace($targetHost)) {
            [System.Windows.Forms.MessageBox]::Show("Bitte geben Sie einen Host oder eine IP-Adresse ein.", "Fehler", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
            
            # Log-Eintrag für fehlende Host-Eingabe
            Write-ToolLog -ToolName "NetworkTools" -Message "Ping-Test abgebrochen: Kein Host angegeben" -OutputBox $null -Level "Warning" -SaveToDatabase
            return
        }
        
        # outputBox zurücksetzen
        $outputBox.Clear()
        
        Clear-Host
        
        # Rahmen und ASCII-Art für Ping Test
        Write-Host "╔══════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
        Write-ColoredCenteredText                        "PING TEST"                                         
        Write-Host "╚══════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Green
        
        # ASCII-Art Logo für Ping Test
        Write-Host
        Write-Host '  8888888b.  d8b                           88888888888                888      ' -ForegroundColor Cyan
        Write-Host '  888   Y88b Y8P                               888                    888      ' -ForegroundColor Blue
        Write-Host '  888    888                                   888                    888      ' -ForegroundColor Cyan
        Write-Host '  888   d88P 888 88888b.   .d88b.              888   .d88b.  .d8888b  888888   ' -ForegroundColor Blue
        Write-Host '  8888888P"  888 888 "88b d88P"88b             888  d8P  Y8b 88K      888      ' -ForegroundColor Cyan
        Write-Host '  888        888 888  888 888  888             888  88888888 "Y8888b. 888      ' -ForegroundColor Blue
        Write-Host '  888        888 888  888 Y88b 888             888  Y8b.          X88 Y88b.    ' -ForegroundColor Cyan
        Write-Host '  888        888 888  888  "Y88888             888   "Y8888   88888P"  "Y888   ' -ForegroundColor Blue
        Write-Host '                               888                                              ' -ForegroundColor Cyan
        Write-Host '                          Y8b d88P                                              ' -ForegroundColor Blue
        Write-Host '                           "Y88P"                                               ' -ForegroundColor Cyan
        Write-Host
        
        # Rahmen für Informationen
        Write-Host "╔══════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
        Write-ColoredCenteredText                   "INFORMATIONEN"                                     
        Write-Host "╠══════════════════════════════════════════════════════════════════════════════╣" -ForegroundColor Green
        Write-Host "║                                                                              ║" -ForegroundColor Green
        Write-Host "  ├─  Netzwerk-Erreichbarkeitstest mit ICMP-Paketen                               " -ForegroundColor Yellow                 
        Write-Host "  ├─  Misst Latenz und Paketverlust zu einem Zielhost                             " -ForegroundColor Yellow                                    
        Write-Host "  ├─  Konfigurierbare Paketanzahl, Timeout und Puffergröße                        " -ForegroundColor Yellow                                    
        Write-Host "  └─  Hilfreich zur Diagnose von Netzwerkproblemen                                " -ForegroundColor Yellow                                  
        Write-Host "║                                                                              ║" -ForegroundColor Green
        Write-Host "╠══════════════════════════════════════════════════════════════════════════════╣" -ForegroundColor Green
        Write-ColoredCenteredText                  "[►] Starte Ping-Test zu $targetHost..."
        Write-Host "╚══════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Green
        Write-Host
        # 3 Sekunden warten vor dem Start
        Start-Sleep -Seconds 3
        Set-NetworkOutputStyle -OutputBox $outputBox -Style 'Action'
        $outputBox.AppendText("Starte Ping-Test an $targetHost (${count}x, Timeout: ${timeout}ms, Buffer: ${bufferSize} Bytes)...`r`n`r`n")
        
        # Log-Eintrag für Ping-Start
        Write-ToolLog -ToolName "NetworkTools" -Message "Ping-Test an $targetHost gestartet (${count}x, Timeout: ${timeout}ms, Buffer: ${bufferSize} Bytes)" -OutputBox $null -Level "Information" -SaveToDatabase
        
        try {
            $pingResults = @()
            
            for ($i = 1; $i -le $count; $i++) {
                Set-NetworkOutputStyle -OutputBox $outputBox -Style 'Muted'
                $outputBox.AppendText("Ping #$i an $targetHost wird ausgeführt...`r`n")
                Write-Host "Ping #$i an $targetHost wird ausgeführt..." -ForegroundColor Gray
                
                $ping = New-Object System.Net.NetworkInformation.Ping
                $buffer = New-Object byte[] $bufferSize
                $options = New-Object System.Net.NetworkInformation.PingOptions
                $options.DontFragment = $true
                
                $result = $ping.Send($targetHost, [int]$timeout, $buffer, $options)
                $pingResults += $result
                
                if ($result.Status -eq "Success") {
                    $pingResultText = "  [►] Antwort von $($result.Address): Bytes=$($result.Buffer.Length) Zeit=$($result.RoundtripTime)ms TTL=$($result.Options.Ttl)"
                    Set-NetworkOutputStyle -OutputBox $outputBox -Style 'Success'
                    $outputBox.AppendText("$pingResultText`r`n")
                    Write-Host $pingResultText -ForegroundColor Green
                }
                else {
                    $pingErrorText = "  [✗] Zeitüberschreitung der Anforderung oder Fehler: $($result.Status)"
                    Set-NetworkOutputStyle -OutputBox $outputBox -Style 'Error'
                    $outputBox.AppendText("$pingErrorText`r`n")
                    Write-Host $pingErrorText -ForegroundColor Red
                }
                
                # Pause zwischen den Pings
                if ($i -lt $count) {
                    Start-Sleep -Milliseconds 500
                }
            }
            
            # Zusammenfassung berechnen
            $successCount = ($pingResults | Where-Object { $_.Status -eq "Success" }).Count
            $failCount = $count - $successCount
            $successRate = ($successCount / $count) * 100
            
            # RoundtripTime nur für erfolgreiche Pings berechnen
            $successResults = $pingResults | Where-Object { $_.Status -eq "Success" }
            if ($successResults.Count -gt 0) {
                $minTime = ($successResults | Measure-Object -Property RoundtripTime -Minimum).Minimum
                $maxTime = ($successResults | Measure-Object -Property RoundtripTime -Maximum).Maximum
                $avgTime = ($successResults | Measure-Object -Property RoundtripTime -Average).Average
            }
            else {
                $minTime = 0
                $maxTime = 0
                $avgTime = 0
            }
            
            $outputBox.AppendText("`r`n")
            Set-NetworkOutputStyle -OutputBox $outputBox -Style 'Action'
            $outputBox.AppendText("  " + ("═" * 54) + "`r`n")
            $outputBox.AppendText("  ══  Ping-Statistik für $targetHost  ══`r`n")
            $outputBox.AppendText("  " + ("═" * 54) + "`r`n")
            Set-NetworkOutputStyle -OutputBox $outputBox -Style 'Default'
            $outputBox.AppendText("`r`n  Pakete: Gesendet = $count, Empfangen = $successCount, Verloren = $failCount ($(100 - $successRate)% Verlust)`r`n")
            if ($successCount -gt 0) {
                Set-NetworkOutputStyle -OutputBox $outputBox -Style 'Default'
                $outputBox.AppendText("  Ca. Zeitangaben in Millisek.:`r`n")
                Set-NetworkOutputStyle -OutputBox $outputBox -Style 'Default'
                $outputBox.AppendText("    Minimum = $minTime ms, Maximum = $maxTime ms, Mittelwert = $([Math]::Round($avgTime, 2)) ms`r`n")
                Set-NetworkOutputStyle -OutputBox $outputBox -Style 'Default'
                $outputBox.AppendText("  " + ("─" * 66) + "`r`n")
            }
            
            # Dieselbe Zusammenfassung auch in der PowerShell-Konsole anzeigen
            Write-Host ("  " + ("═" * 50)) -ForegroundColor Cyan
            Write-Host "  ══  Ping-Statistik für $targetHost  ══" -ForegroundColor Cyan
            Write-Host "`n  Pakete: Gesendet = $count, Empfangen = $successCount, Verloren = $failCount ($(100 - $successRate)% Verlust)"
            if ($successCount -gt 0) {
                Write-Host "  Ca. Zeitangaben in Millisek.:"
                Write-Host "    Minimum = $minTime ms, Maximum = $maxTime ms, Mittelwert = $([Math]::Round($avgTime, 2)) ms"
            }
            Write-Host ("  " + ("═" * 50)) -ForegroundColor Cyan
            Write-Host
            # Gesamtergebnis bewerten
            $outputBox.AppendText("`r`n")
            if ($successRate -eq 100) {
                Set-NetworkOutputStyle -OutputBox $outputBox -Style 'Success'
                $message = "  [✓] Netzwerkverbindung zu $targetHost ist STABIL (100% Erfolgsrate)"
                $outputBox.AppendText("$message`r`n")
                Write-ToolLog -ToolName "NetworkTools" -Message $message -OutputBox $null -Style 'Success' -Level "Success" -SaveToDatabase
                # Auch in der PowerShell-Konsole anzeigen
                Write-Host $message -ForegroundColor Green
            }
            elseif ($successRate -ge 75) {
                Set-NetworkOutputStyle -OutputBox $outputBox -Style 'Success'
                $message = "  [✓] Netzwerkverbindung zu $targetHost ist GUT (${successRate}% Erfolgsrate)"
                $outputBox.AppendText("$message`r`n")
                Write-ToolLog -ToolName "NetworkTools" -Message $message -OutputBox $null -Style 'Success' -Level "Success" -SaveToDatabase
                # Auch in der PowerShell-Konsole anzeigen
                Write-Host $message -ForegroundColor DarkGreen
            }
            elseif ($successRate -ge 25) {
                Set-NetworkOutputStyle -OutputBox $outputBox -Style 'Warning'
                $message = "  [⚠] Netzwerkverbindung zu $targetHost ist INSTABIL (${successRate}% Erfolgsrate)"
                $outputBox.AppendText("$message`r`n")
                Write-ToolLog -ToolName "NetworkTools" -Message $message -OutputBox $null -Style 'Warning' -Level "Warning" -SaveToDatabase
                # Auch in der PowerShell-Konsole anzeigen
                Write-Host $message -ForegroundColor Yellow
            }
            else {
                Set-NetworkOutputStyle -OutputBox $outputBox -Style 'Error'
                $message = "  [✗] Netzwerkverbindung zu $targetHost ist NICHT VERFÜGBAR (${successRate}% Erfolgsrate)"
                $outputBox.AppendText("$message`r`n")
                Write-ToolLog -ToolName "NetworkTools" -Message $message -OutputBox $null -Style 'Error' -Level "Error" -SaveToDatabase
                # Auch in der PowerShell-Konsole anzeigen
                Write-Host $message -ForegroundColor Red
            }
            
            # Abschlusszeile in PowerShell anzeigen
            Write-Host ("  " + ("═" * 50)) -ForegroundColor Cyan
        }
        catch {
            Set-NetworkOutputStyle -OutputBox $outputBox -Style 'Error'
            $errorMessage = "FEHLER: $($_.Exception.Message)"
            $outputBox.AppendText("$errorMessage`r`n")
            
            # Log-Eintrag für Fehler
            Write-ToolLog -ToolName "NetworkTools" -Message "Fehler beim Ping-Test: $($_.Exception.Message)" -OutputBox $null -Style 'Error' -Level "Error" -SaveToDatabase
        }
        
        # Farbe zurücksetzen
        Set-NetworkOutputStyle -OutputBox $outputBox -Style 'Default'
    }
}

# Function to reset network adapter
function Restart-NetworkAdapter {
    param (
        [System.Windows.Forms.RichTextBox]$outputBox
    )
    
    # Log-Eintrag erstellen
    Write-ToolLog -ToolName "NetworkTools" -Message "Start der Netzwerkadapter-Zurücksetzung" -OutputBox $outputBox -Style 'Action' -Level "Information" -SaveToDatabase
    
    $result = Show-CustomMessageBox -message "Diese Funktion setzt alle Netzwerkadapter zurück. Netzwerkverbindungen werden kurzzeitig unterbrochen. Möchten Sie fortfahren?" -title "Netzwerkadapter zurücksetzen" -fontSize 14
    
    if ($result -eq "OK") {
        # outputBox zurücksetzen
        $outputBox.Clear()
        
        Clear-Host
        
        # Rahmen und ASCII-Art für Network Adapter Restart
        Write-Host "╔══════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
        Write-ColoredCenteredText                   "NETWORK ADAPTER RESTART"                                         
        Write-Host "╚══════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Green
        
        # ASCII-Art Logo für Network Reset
        Write-Host
        Write-Host '   888b    888          888                                   888                   ' -ForegroundColor Cyan
        Write-Host '   8888b   888          888                                   888                   ' -ForegroundColor Blue
        Write-Host '   88888b  888          888                                   888                   ' -ForegroundColor Cyan
        Write-Host '   888Y88b 888  .d88b.  888888 888  888  888  .d88b.  888d888 888  888              ' -ForegroundColor Blue
        Write-Host '   888 Y88b888 d8P  Y8b 888    888  888  888 d88""88b 888P"   888 .88P              ' -ForegroundColor Cyan
        Write-Host '   888  Y88888 88888888 888    888  888  888 888  888 888     888888K               ' -ForegroundColor Blue
        Write-Host '   888   Y8888 Y8b.     Y88b.  Y88b 888 d88P Y88..88P 888     888 "88b              ' -ForegroundColor Cyan
        Write-Host '   888    Y888  "Y8888   "Y888  "Y8888888P"   "Y88P"  888     888  888              ' -ForegroundColor Blue
        Write-Host
        Write-Host '                     8888888b.                                888                  ' -ForegroundColor Cyan
        Write-Host '                     888   Y88b                               888                  ' -ForegroundColor Blue
        Write-Host '                     888    888                               888                  ' -ForegroundColor Cyan
        Write-Host '                     888   d88P  .d88b.   .d8888b    .d88b.   888888               ' -ForegroundColor Blue
        Write-Host '                     8888888P"  d8P  Y8b  88K       d8P  Y8b  888                  ' -ForegroundColor Cyan
        Write-Host '                     888 T88b   88888888  "Y8888b.  88888888  888                  ' -ForegroundColor Blue
        Write-Host '                     888  T88b  Y8b.           X88  Y8b.      Y88b.                ' -ForegroundColor Cyan
        Write-Host '                     888   T88b  "Y8888    88888P"   "Y8888    "Y888               ' -ForegroundColor Blue
        Write-Host
        
        # Rahmen für Informationen
        Write-Host "╔══════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
        Write-ColoredCenteredText                   "INFORMATIONEN"                                     
        Write-Host "╠══════════════════════════════════════════════════════════════════════════════╣" -ForegroundColor Green
        Write-Host "║                                                                              ║" -ForegroundColor Green
        Write-Host "  ├─  Setzt alle aktiven Netzwerkadapter zurück                                   " -ForegroundColor Yellow                 
        Write-Host "  ├─  Deaktiviert und reaktiviert alle Netzwerkverbindungen                       " -ForegroundColor Yellow                                    
        Write-Host "  ├─  Löst temporäre Netzwerkprobleme und IP-Konflikte                            " -ForegroundColor Yellow                                    
        Write-Host "  └─  Warnung: Netzwerkverbindungen werden kurzzeitig unterbrochen                " -ForegroundColor Yellow                                  
        Write-Host "║                                                                              ║" -ForegroundColor Green
        Write-Host "╠══════════════════════════════════════════════════════════════════════════════╣" -ForegroundColor Green
        Write-ColoredCenteredText                  "[►] Starte Netzwerkadapter-Reset..."
        Write-Host "╚══════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Green
        Write-Host
        # 3 Sekunden warten vor dem Start
        Start-Sleep -Seconds 3
        Set-NetworkOutputStyle -OutputBox $outputBox -Style 'Action'
        $outputBox.AppendText("Netzwerkadapter werden zurückgesetzt...`r`n`r`n")
        
        try {
            # Netzwerkadapter auflisten
            $adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
            $outputBox.AppendText("Gefundene aktive Netzwerkadapter:`r`n")
            foreach ($adapter in $adapters) {
                $outputBox.AppendText("- $($adapter.Name) ($($adapter.InterfaceDescription))`r`n")
            }
            
            $outputBox.AppendText("`r`nDeaktiviere Netzwerkadapter...`r`n")
            
            # Netzwerkadapter deaktivieren
            foreach ($adapter in $adapters) {
                $outputBox.AppendText("Deaktiviere $($adapter.Name)...`r`n")
                Disable-NetAdapter -Name $adapter.Name -Confirm:$false
                Start-Sleep -Seconds 1
            }
            
            $outputBox.AppendText("`r`nAktiviere Netzwerkadapter...`r`n")
            
            # Netzwerkadapter reaktivieren
            foreach ($adapter in $adapters) {
                $outputBox.AppendText("Aktiviere $($adapter.Name)...`r`n")
                Enable-NetAdapter -Name $adapter.Name -Confirm:$false
            }
            
            # Kurze Pause für die Reaktivierung
            $outputBox.AppendText("`r`nWarte auf Netzwerkverbindung...`r`n")
            Start-Sleep -Seconds 5
            
            # Überprüfen der Netzwerkverbindung
            $outputBox.AppendText("`r`nÜberprüfe Netzwerkverbindung...`r`n")
            
            $adaptersAfter = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
            $outputBox.AppendText("Aktive Netzwerkadapter nach Reset:`r`n")
            foreach ($adapter in $adaptersAfter) {
                $outputBox.AppendText("- $($adapter.Name) ($($adapter.InterfaceDescription)) - Status: $($adapter.Status)`r`n")
            }
            
            # Erfolgsnotiz
            Set-NetworkOutputStyle -OutputBox $outputBox -Style 'Success'
            $outputBox.AppendText("`r`nNetzwerkadapter wurden erfolgreich zurückgesetzt.`r`n")
            
            # Log-Eintrag für erfolgreichen Reset
            Write-ToolLog -ToolName "NetworkTools" -Message "Netzwerkadapter wurden erfolgreich zurückgesetzt" -OutputBox $null -Style 'Success' -Level "Success" -SaveToDatabase
        }
        catch {
            Set-NetworkOutputStyle -OutputBox $outputBox -Style 'Error'
            $outputBox.AppendText("FEHLER: $($_.Exception.Message)`r`n")
            
            # Log-Eintrag für Fehler
            Write-ToolLog -ToolName "NetworkTools" -Message "Fehler beim Zurücksetzen der Netzwerkadapter: $($_.Exception.Message)" -OutputBox $null -Style 'Error' -Level "Error" -SaveToDatabase
        }
        
        # Farbe zurücksetzen
        Set-NetworkOutputStyle -OutputBox $outputBox -Style 'Default'
    }
    else {
        Set-NetworkOutputStyle -OutputBox $outputBox -Style 'Muted'
        $outputBox.AppendText("Netzwerkadapter-Reset wurde abgebrochen.`r`n")
        
        # Log-Eintrag für Abbruch
        Write-ToolLog -ToolName "NetworkTools" -Message "Netzwerkadapter-Reset wurde vom Benutzer abgebrochen" -OutputBox $null -Level "Information" -SaveToDatabase
    }
}

# Export functions
Export-ModuleMember -Function Start-PingTest, Restart-NetworkAdapter 

# SIG # Begin signature block
# MIIcSgYJKoZIhvcNAQcCoIIcOzCCHDcCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCANymmZUlajPGh2
# a7JJmNRaFcfiQjpNwMd0GtbfEe6AdqCCFnowggM8MIICJKADAgECAhBJfyGrXBJT
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
# MQ4wDAYKKwYBBAGCNwIBFTAvBgkqhkiG9w0BCQQxIgQgtaE3ZQswfMVdpVnS6ofU
# avxPC+9X18x1cTF4rNSlMsYwDQYJKoZIhvcNAQEBBQAEggEAaf8z38ACGmEAgIEz
# CGJ3v3wjk7iuoGDePjAecI+Lv6yUhTJLOKV6xQrjCz9rBXEtjQRlo/JxyAHhGmM7
# OXRLl20bAe4aSdW17/GzmPsIQ+9Xr6r4Yk6NBOfA97Ocjm5YDrW5Gxm4fSG/KZpp
# 7tQm7Kz0YzLm4iETODIgsI+ABlP99rnAI3kFGSRt1Tl5PRZLhFrRmCTjjn70GgOb
# T0O10cQKZI61OrBh7ASFhy6zhbJjeSRSPd05dya5mt7a2DkGM6D7qcNZ5vHyNUbW
# GG3y8udGvzX++9G/F+ES9zAwAW2UNEhkh4mTDX/WhFdgufzZ+OhZdbKhEixdmEU1
# s+qBNKGCAyYwggMiBgkqhkiG9w0BCQYxggMTMIIDDwIBATB9MGkxCzAJBgNVBAYT
# AlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5jLjFBMD8GA1UEAxM4RGlnaUNlcnQg
# VHJ1c3RlZCBHNCBUaW1lU3RhbXBpbmcgUlNBNDA5NiBTSEEyNTYgMjAyNSBDQTEC
# EAqA7xhLjfEFgtHEdqeVdGgwDQYJYIZIAWUDBAIBBQCgaTAYBgkqhkiG9w0BCQMx
# CwYJKoZIhvcNAQcBMBwGCSqGSIb3DQEJBTEPFw0yNjAxMjAxODAyNTVaMC8GCSqG
# SIb3DQEJBDEiBCD2toUoH+LeiTKd3+DW71r99psqeC9JNFTU2XysZqMkKjANBgkq
# hkiG9w0BAQEFAASCAgAtfOcYuRYW48Vn1lD/Ch/uJ5Iwh3a2opjqLvGIeccaPpSE
# tnCixKTHAud3fcK/qjlfgeD/LIX7FebOqaZ7OLaBTwmqRZ0gw9qU9lS019MnroKy
# IR1hzQX0LiU/fHNRPWKeNlvQc2PaWAf+taNnI3bwChE7qeCip7b/53Yuud8JIAd6
# DKhRESiMxQFSWcnISmU3oxL4vcXzMQUELcZXCRBfun0J3eTlzkHYv9a+TrH/YW3X
# CmWB/LCQn6h23Bnf6ViRu8FJOntKt0sicY9VcFO4TEQxrSWjztTZWQZgmq26CE9R
# z5JVXSV4W0bMFco1ZUxGpp8CNTQs2K7a5VkT8s/v5vM8QRKkwB0GrxbZHlzqKJqU
# yoR03QeYjb8Hd306ZHeOlkX7aTfFC5mtPcsxoCl5GSLDOW9v28Ypu5AjTEHN2W+h
# jfIus0dnjqyPfWIDlsqm7p0/21dFUV4+m68RPQpHHAPiUxZJQBYud3EnSLs15i9z
# ehsmSY8o5r3E+ps45fjCYTEzcVxxPSC1LoMORn9cplAwdeVVBqUOmcvVFoQi3LGM
# bsOCsPrTwy9gQ/ARZaBTSOtRm1wLugHXuxrGQ5JtEk9irfITjGA0P0LqHPYegLso
# 6bM0nWR5eIz6VAn3QgHGyMzthFA/VYsJQWNYYAYOtHJL1hPn9mSi9XH961FtMg==
# SIG # End signature block

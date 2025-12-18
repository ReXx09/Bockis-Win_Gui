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
                    $pingErrorText = "  [X] Zeitüberschreitung der Anforderung oder Fehler: $($result.Status)"
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
            
            # Zusammenfassung anzeigen
            $outputBox.AppendText("`r`n")
            Set-NetworkOutputStyle -OutputBox $outputBox -Style 'Action'
            $outputBox.AppendText("`t=======  Ping-Statistik für $targetHost  ========`r`n")
            Set-NetworkOutputStyle -OutputBox $outputBox -Style 'Default'
            $outputBox.AppendText("`n  Pakete: Gesendet = $count, Empfangen = $successCount, Verloren = $failCount ($(100 - $successRate)% Verlust)`r`n")
            if ($successCount -gt 0) {
                Set-NetworkOutputStyle -OutputBox $outputBox -Style 'Default'
                $outputBox.AppendText("  Ca. Zeitangaben in Millisek.:`r`n")
                Set-NetworkOutputStyle -OutputBox $outputBox -Style 'Default'
                $outputBox.AppendText("    Minimum = $minTime ms, Maximum = $maxTime ms, Mittelwert = $([Math]::Round($avgTime, 2)) ms`r`n")
                Set-NetworkOutputStyle -OutputBox $outputBox -Style 'Default'
                $outputbox.Appendtext(" ===================================================================`r`n")
            }
            
            # Dieselbe Zusammenfassung auch in der PowerShell-Konsole anzeigen
            Write-Host "`n" + ("═" * 50) -ForegroundColor Cyan
            Write-Host "`n`t======= Ping-Statistik für $targetHost ========" -ForegroundColor Green
            Write-Host "`n  Pakete: Gesendet = $count, Empfangen = $successCount, Verloren = $failCount ($(100 - $successRate)% Verlust)"
            if ($successCount -gt 0) {
                Write-Host "  Ca. Zeitangaben in Millisek.:"
                Write-Host "    Minimum = $minTime ms, Maximum = $maxTime ms, Mittelwert = $([Math]::Round($avgTime, 2)) ms"
            }
            Write-Host "`n" + ("═" * 50) -ForegroundColor Cyan
            Write-Host
            # Gesamtergebnis bewerten
            $outputBox.AppendText("`r`n")
            if ($successRate -eq 100) {
                Set-NetworkOutputStyle -OutputBox $outputBox -Style 'Success'
                $message = "  [>]Netzwerkverbindung zu $targetHost ist STABIL (100% Erfolgsrate)"
                $outputBox.AppendText("$message`r`n")
                Write-ToolLog -ToolName "NetworkTools" -Message $message -OutputBox $null -Style 'Success' -Level "Success" -SaveToDatabase
                # Auch in der PowerShell-Konsole anzeigen
                Write-Host $message -ForegroundColor Green
            }
            elseif ($successRate -ge 75) {
                Set-NetworkOutputStyle -OutputBox $outputBox -Style 'Success'
                $message = "  [>]Netzwerkverbindung zu $targetHost ist GUT (${successRate}% Erfolgsrate)"
                $outputBox.AppendText("$message`r`n")
                Write-ToolLog -ToolName "NetworkTools" -Message $message -OutputBox $null -Style 'Success' -Level "Success" -SaveToDatabase
                # Auch in der PowerShell-Konsole anzeigen
                Write-Host $message -ForegroundColor DarkGreen
            }
            elseif ($successRate -ge 25) {
                Set-NetworkOutputStyle -OutputBox $outputBox -Style 'Warning'
                $message = "  [>]Netzwerkverbindung zu $targetHost ist INSTABIL (${successRate}% Erfolgsrate)"
                $outputBox.AppendText("$message`r`n")
                Write-ToolLog -ToolName "NetworkTools" -Message $message -OutputBox $null -Style 'Warning' -Level "Warning" -SaveToDatabase
                # Auch in der PowerShell-Konsole anzeigen
                Write-Host $message -ForegroundColor Yellow
            }
            else {
                Set-NetworkOutputStyle -OutputBox $outputBox -Style 'Error'
                $message = "  [>]Netzwerkverbindung zu $targetHost ist NICHT VERFÜGBAR (${successRate}% Erfolgsrate)"
                $outputBox.AppendText("$message`r`n")
                Write-ToolLog -ToolName "NetworkTools" -Message $message -OutputBox $null -Style 'Error' -Level "Error" -SaveToDatabase
                # Auch in der PowerShell-Konsole anzeigen
                Write-Host $message -ForegroundColor Red
            }
            
            # Abschlusszeile in PowerShell anzeigen
            Write-Host "`n" + ("═" * 50) -ForegroundColor Cyan
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

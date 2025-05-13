# Import required modules
Import-Module "$PSScriptRoot\..\Core\Core.psm1" -Force

# Function to run ping test
function Start-PingTest {
    param (
        [System.Windows.Forms.RichTextBox]$outputBox
    )
    
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
            return
        }
        
        # outputBox zurücksetzen
        $outputBox.Clear()
        $outputBox.SelectionColor = [System.Drawing.Color]::DarkBlue
        $outputBox.AppendText("Starte Ping-Test an $targetHost (${count}x, Timeout: ${timeout}ms, Buffer: ${bufferSize} Bytes)...`r`n`r`n")
        
        try {
            $pingResults = @()
            
            for ($i = 1; $i -le $count; $i++) {
                $outputBox.SelectionColor = [System.Drawing.Color]::Gray
                $outputBox.AppendText("Ping #$i an $targetHost wird ausgeführt...`r`n")
                
                $ping = New-Object System.Net.NetworkInformation.Ping
                $buffer = New-Object byte[] $bufferSize
                $options = New-Object System.Net.NetworkInformation.PingOptions
                $options.DontFragment = $true
                
                $result = $ping.Send($targetHost, [int]$timeout, $buffer, $options)
                $pingResults += $result
                
                if ($result.Status -eq "Success") {
                    $outputBox.SelectionColor = [System.Drawing.Color]::Green
                    $outputBox.AppendText("► Antwort von $($result.Address): Bytes=$($result.Buffer.Length) Zeit=$($result.RoundtripTime)ms TTL=$($result.Options.Ttl)`r`n")
                }
                else {
                    $outputBox.SelectionColor = [System.Drawing.Color]::Red
                    $outputBox.AppendText("X Zeitüberschreitung der Anforderung oder Fehler: $($result.Status)`r`n")
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
            $outputBox.SelectionColor = [System.Drawing.Color]::DarkBlue
            $outputBox.AppendText("==== Ping-Statistik für $targetHost ====`r`n")
            $outputBox.AppendText("Pakete: Gesendet = $count, Empfangen = $successCount, Verloren = $failCount ($(100 - $successRate)% Verlust)`r`n")
            
            if ($successCount -gt 0) {
                $outputBox.AppendText("Ca. Zeitangaben in Millisek.:`r`n")
                $outputBox.AppendText("    Minimum = $minTime ms, Maximum = $maxTime ms, Mittelwert = $([Math]::Round($avgTime, 2)) ms`r`n")
            }
            
            # Gesamtergebnis bewerten
            $outputBox.AppendText("`r`n")
            if ($successRate -eq 100) {
                $outputBox.SelectionColor = [System.Drawing.Color]::Green
                $outputBox.AppendText("Netzwerkverbindung zu $targetHost ist STABIL (100% Erfolgsrate)`r`n")
            }
            elseif ($successRate -ge 75) {
                $outputBox.SelectionColor = [System.Drawing.Color]::DarkGreen
                $outputBox.AppendText("Netzwerkverbindung zu $targetHost ist GUT (${successRate}% Erfolgsrate)`r`n")
            }
            elseif ($successRate -ge 25) {
                $outputBox.SelectionColor = [System.Drawing.Color]::Orange
                $outputBox.AppendText("Netzwerkverbindung zu $targetHost ist INSTABIL (${successRate}% Erfolgsrate)`r`n")
            }
            else {
                $outputBox.SelectionColor = [System.Drawing.Color]::Red
                $outputBox.AppendText("Netzwerkverbindung zu $targetHost ist NICHT VERFÜGBAR (${successRate}% Erfolgsrate)`r`n")
            }
        }
        catch {
            $outputBox.SelectionColor = [System.Drawing.Color]::Red
            $outputBox.AppendText("FEHLER: $($_.Exception.Message)`r`n")
        }
        
        # Farbe zurücksetzen
        $outputBox.SelectionColor = $outputBox.ForeColor
    }
}

# Function to reset network adapter
function Restart-NetworkAdapter {
    param (
        [System.Windows.Forms.RichTextBox]$outputBox
    )
    
    $result = Show-CustomMessageBox -message "Diese Funktion setzt alle Netzwerkadapter zurück. Netzwerkverbindungen werden kurzzeitig unterbrochen. Möchten Sie fortfahren?" -title "Netzwerkadapter zurücksetzen" -fontSize 14
    
    if ($result -eq "OK") {
        # outputBox zurücksetzen
        $outputBox.Clear()
        $outputBox.SelectionColor = [System.Drawing.Color]::DarkBlue
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
            $outputBox.SelectionColor = [System.Drawing.Color]::Green
            $outputBox.AppendText("`r`nNetzwerkadapter wurden erfolgreich zurückgesetzt.`r`n")
            
        }
        catch {
            $outputBox.SelectionColor = [System.Drawing.Color]::Red
            $outputBox.AppendText("FEHLER: $($_.Exception.Message)`r`n")
        }
        
        # Farbe zurücksetzen
        $outputBox.SelectionColor = $outputBox.ForeColor
    }
    else {
        $outputBox.SelectionColor = [System.Drawing.Color]::Gray
        $outputBox.AppendText("Netzwerkadapter-Reset wurde abgebrochen.`r`n")
    }
}

# Export functions
Export-ModuleMember -Function Start-PingTest, Restart-NetworkAdapter 
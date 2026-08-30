# Import required modules
Import-Module "$PSScriptRoot\..\Core\Core.psm1" -Force -Global
Import-Module "$PSScriptRoot\..\Core\TextStyle.psm1" -Force -Global

# WPF-Assemblies fuer optionale XAML-Dialoge
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase

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
        [System.Windows.Forms.RichTextBox]$outputBox,
        $progressBar
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
            Show-ModernMessageDialog -Arguments @("Bitte geben Sie einen Host oder eine IP-Adresse ein.", "Fehler", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
            
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
        [System.Windows.Forms.RichTextBox]$outputBox,
        $progressBar
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

function Write-NetworkScanOutput {
    param(
        [System.Windows.Forms.RichTextBox]$OutputBox,
        [string]$Text,
        [string]$Style = 'Default'
    )

    Set-NetworkOutputStyle -OutputBox $OutputBox -Style $Style
    if ($OutputBox) {
        $OutputBox.AppendText("$Text`r`n")
    }
}

function Test-NetworkScanAdmin {
    try {
        return ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    }
    catch {
        return $false
    }
}

function New-NetworkScanResult {
    param(
        [string]$Name,
        [string]$Status,
        [string]$Detail,
        [string]$Recommendation
    )

    [PSCustomObject]@{
        Name           = $Name
        Status         = $Status
        Detail         = $Detail
        Recommendation = $Recommendation
    }
}

function Get-FastStartupScanResult {
    $powerKey = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power'
    $controlPowerKey = 'HKLM:\SYSTEM\CurrentControlSet\Control\Power'

    try {
        $hiberboot = (Get-ItemProperty -Path $powerKey -Name HiberbootEnabled -ErrorAction Stop).HiberbootEnabled
        $hibernate = (Get-ItemProperty -Path $controlPowerKey -Name HibernateEnabled -ErrorAction SilentlyContinue).HibernateEnabled

        if ($hiberboot -eq 1) {
            return New-NetworkScanResult -Name 'Fast Startup / Hibernation' -Status 'Yellow' -Detail 'Fast Startup ist aktiviert (HiberbootEnabled=1).' -Recommendation 'Bei Netzwerkproblemen testweise Fast Startup deaktivieren und Neustart ausfuehren.'
        }

        $detail = 'Fast Startup ist deaktiviert (HiberbootEnabled=0).'
        if ($null -ne $hibernate) {
            $detail = "$detail HibernateEnabled=$hibernate."
        }
        return New-NetworkScanResult -Name 'Fast Startup / Hibernation' -Status 'Green' -Detail $detail -Recommendation 'Keine Aenderung erforderlich.'
    }
    catch {
        return New-NetworkScanResult -Name 'Fast Startup / Hibernation' -Status 'Yellow' -Detail "Pruefung nicht vollstaendig moeglich: $($_.Exception.Message)" -Recommendation 'Registry-Zugriff als Administrator pruefen und Fast Startup manuell kontrollieren.'
    }
}

function Get-NicPowerManagementScanResult {
    try {
        $adapters = Get-NetAdapter -Physical -ErrorAction Stop | Where-Object { $_.Status -eq 'Up' }
        if (-not $adapters) {
            return New-NetworkScanResult -Name 'NIC-Energieverwaltung' -Status 'Yellow' -Detail 'Keine aktiven physischen Netzwerkadapter gefunden.' -Recommendation 'Adapterstatus und Kabelverbindung pruefen.'
        }

        $riskyAdapters = @()
        $checkedCount = 0

        foreach ($adapter in $adapters) {
            try {
                $pm = Get-NetAdapterPowerManagement -Name $adapter.Name -ErrorAction Stop
                $checkedCount++

                $allowTurnOff = "$($pm.AllowComputerToTurnOffDevice)"
                if ($allowTurnOff -match 'Enabled|On|True') {
                    $riskyAdapters += $adapter.Name
                }
            }
            catch {
                continue
            }
        }

        if ($checkedCount -eq 0) {
            return New-NetworkScanResult -Name 'NIC-Energieverwaltung' -Status 'Yellow' -Detail 'Power-Management-Details konnten fuer aktive Adapter nicht ausgelesen werden.' -Recommendation 'Scan als Administrator erneut ausfuehren oder Treiber-Tools des Herstellers nutzen.'
        }

        if ($riskyAdapters.Count -gt 0) {
            $adapterList = ($riskyAdapters | Select-Object -Unique) -join ', '
            return New-NetworkScanResult -Name 'NIC-Energieverwaltung' -Status 'Yellow' -Detail "Bei folgenden Adaptern darf Windows das Geraet abschalten: $adapterList" -Recommendation 'Energiesparoption am Adapter testweise deaktivieren, wenn Verbindungsabbrueche auftreten.'
        }

        return New-NetworkScanResult -Name 'NIC-Energieverwaltung' -Status 'Green' -Detail "$checkedCount aktive Adapter geprueft, keine kritischen Energiesparflags erkannt." -Recommendation 'Keine Aenderung erforderlich.'
    }
    catch {
        return New-NetworkScanResult -Name 'NIC-Energieverwaltung' -Status 'Yellow' -Detail "Pruefung fehlgeschlagen: $($_.Exception.Message)" -Recommendation 'Get-NetAdapter/Get-NetAdapterPowerManagement Verfuegbarkeit und Rechte pruefen.'
    }
}

function Get-LinkSettingsScanResult {
    try {
        $adapters = Get-NetAdapter -Physical -ErrorAction Stop | Where-Object { $_.Status -eq 'Up' }
        if (-not $adapters) {
            return New-NetworkScanResult -Name 'Speed/Duplex & Auto-Negotiation' -Status 'Yellow' -Detail 'Keine aktiven physischen Adapter fuer Link-Check gefunden.' -Recommendation 'Adapterstatus pruefen und Scan erneut starten.'
        }

        $manualConfig = @()
        $checked = 0

        foreach ($adapter in $adapters) {
            try {
                $props = Get-NetAdapterAdvancedProperty -Name $adapter.Name -ErrorAction Stop |
                    Where-Object { $_.DisplayName -match 'Speed|Duplex|Negotiation|Link' }

                if ($props) {
                    $checked++
                    $manual = $props | Where-Object {
                        $_.DisplayName -match 'Speed|Duplex|Negotiation' -and
                        $_.DisplayValue -and
                        $_.DisplayValue -notmatch 'Auto|Automatisch|auto-negotiation'
                    }

                    if ($manual) {
                        $manualConfig += "$($adapter.Name): $((($manual | Select-Object -ExpandProperty DisplayValue) -join ', '))"
                    }
                }
            }
            catch {
                continue
            }
        }

        if ($checked -eq 0) {
            return New-NetworkScanResult -Name 'Speed/Duplex & Auto-Negotiation' -Status 'Yellow' -Detail 'Erweiterte Adaptereigenschaften konnten nicht ausgelesen werden.' -Recommendation 'Treiber-Cmdlets/Hersteller-Tools fuer Link-Einstellungen pruefen.'
        }

        if ($manualConfig.Count -gt 0) {
            return New-NetworkScanResult -Name 'Speed/Duplex & Auto-Negotiation' -Status 'Yellow' -Detail "Manuelle Link-Konfiguration erkannt: $($manualConfig -join ' | ')" -Recommendation 'Bei Instabilitaet auf Auto-Negotiation zurueckstellen und Verbindung erneut pruefen.'
        }

        return New-NetworkScanResult -Name 'Speed/Duplex & Auto-Negotiation' -Status 'Green' -Detail "$checked Adapter geprueft, keine auffaellige manuelle Link-Konfiguration erkannt." -Recommendation 'Keine Aenderung erforderlich.'
    }
    catch {
        return New-NetworkScanResult -Name 'Speed/Duplex & Auto-Negotiation' -Status 'Yellow' -Detail "Pruefung fehlgeschlagen: $($_.Exception.Message)" -Recommendation 'Get-NetAdapterAdvancedProperty mit Administratorrechten erneut pruefen.'
    }
}

function Get-NetworkDriverScanResult {
    try {
        $drivers = Get-CimInstance Win32_PnPSignedDriver -ErrorAction Stop | Where-Object { $_.DeviceClass -eq 'NET' }
        if (-not $drivers) {
            return New-NetworkScanResult -Name 'Netzwerkadapter-Treiber' -Status 'Yellow' -Detail 'Keine Netzwerktreiber ueber WMI gefunden.' -Recommendation 'Treiber im Geraetemanager kontrollieren.'
        }

        $oldDrivers = @()
        $now = Get-Date

        foreach ($driver in $drivers) {
            $driverDate = $null
            if ($driver.DriverDate) {
                try {
                    $driverDate = [System.Management.ManagementDateTimeConverter]::ToDateTime($driver.DriverDate)
                }
                catch {
                    $driverDate = $null
                }
            }

            if ($driverDate -and $driverDate -lt $now.AddYears(-5)) {
                $oldDrivers += "$($driver.DeviceName) ($($driverDate.ToString('yyyy-MM-dd')))"
            }
        }

        if ($oldDrivers.Count -gt 0) {
            return New-NetworkScanResult -Name 'Netzwerkadapter-Treiber' -Status 'Yellow' -Detail "Aeltere Treiber erkannt: $($oldDrivers -join ' | ')" -Recommendation 'Treiber-Update ueber Windows Update oder Herstellerseite pruefen.'
        }

        return New-NetworkScanResult -Name 'Netzwerkadapter-Treiber' -Status 'Green' -Detail "$($drivers.Count) Netzwerktreiber gefunden, kein klar veralteter Treiber markiert." -Recommendation 'Keine Aenderung erforderlich.'
    }
    catch {
        return New-NetworkScanResult -Name 'Netzwerkadapter-Treiber' -Status 'Yellow' -Detail "Treiberpruefung fehlgeschlagen: $($_.Exception.Message)" -Recommendation 'WMI-Zugriff und Treiberstatus im Geraetemanager pruefen.'
    }
}

function Get-NetworkEventScanResult {
    param(
        [int]$Hours = 24
    )

    try {
        $startTime = (Get-Date).AddHours(-1 * [Math]::Abs($Hours))
        $events = Get-WinEvent -FilterHashtable @{ LogName = 'System'; StartTime = $startTime } -ErrorAction Stop

        $nicEvents = $events | Where-Object {
            $_.ProviderName -match 'aqnic650|e1dexpress|rt640x64|netwtw|ndis|tcpip' -or
            $_.Id -in 14, 15
        }

        $aqnicEvents = @($nicEvents | Where-Object { $_.ProviderName -match 'aqnic650' -and $_.Id -in 14, 15 })
        $event14Count = @($aqnicEvents | Where-Object { $_.Id -eq 14 }).Count
        $event15Count = @($aqnicEvents | Where-Object { $_.Id -eq 15 }).Count
        $criticalFlaps = $event14Count + $event15Count
        $warningsAndErrors = ($nicEvents | Where-Object { $_.LevelDisplayName -in 'Warning', 'Error', 'Critical' }).Count
        $lastAqnicEvent = $aqnicEvents | Sort-Object TimeCreated -Descending | Select-Object -First 1
        $lastEventText = if ($lastAqnicEvent -and $lastAqnicEvent.TimeCreated) { $lastAqnicEvent.TimeCreated.ToString('yyyy-MM-dd HH:mm:ss') } else { 'unbekannt' }

        if ($criticalFlaps -gt 0) {
            $status = if ($criticalFlaps -ge 10) { 'Red' } else { 'Yellow' }
            return New-NetworkScanResult -Name 'NIC-Eventlogs' -Status $status -Detail "aqnic650 Link-Flaps erkannt: ID14=$event14Count, ID15=$event15Count, Total=$criticalFlaps, LastEvent=$lastEventText, Window=${Hours}h." -Recommendation 'Speed/Duplex auf Auto-Negotiation pruefen, Kabel/Switch-Port testen und Treiber aktualisieren.'
        }

        if ($warningsAndErrors -gt 0) {
            return New-NetworkScanResult -Name 'NIC-Eventlogs' -Status 'Yellow' -Detail "$warningsAndErrors NIC-relevante Warning/Error-Events in den letzten $Hours Stunden gefunden." -Recommendation 'Ereignisse im Detail pruefen und bei wiederkehrenden Mustern Adapterparameter anpassen.'
        }

        return New-NetworkScanResult -Name 'NIC-Eventlogs' -Status 'Green' -Detail "Keine auffaelligen NIC-Events in den letzten $Hours Stunden gefunden." -Recommendation 'Keine Aenderung erforderlich.'
    }
    catch {
        return New-NetworkScanResult -Name 'NIC-Eventlogs' -Status 'Yellow' -Detail "Eventlog-Pruefung nicht moeglich: $($_.Exception.Message)" -Recommendation 'Scan als Administrator erneut ausfuehren oder Eventlog-Berechtigungen pruefen.'
    }
}

function Get-NetworkIpScanResult {
    try {
        $configs = Get-NetIPConfiguration -ErrorAction Stop | Where-Object { $_.NetAdapter.Status -eq 'Up' }
        if (-not $configs) {
            return New-NetworkScanResult -Name 'IP / DHCP / DNS' -Status 'Red' -Detail 'Keine aktive IP-Konfiguration gefunden.' -Recommendation 'Netzwerkadapter aktivieren oder Verbindung physisch pruefen.'
        }

        $missingDns = @()
        $missingGateway = @()
        $dhcpDisabled = @()

        foreach ($cfg in $configs) {
            $name = $cfg.InterfaceAlias

            if (-not $cfg.DNSServer.ServerAddresses -or $cfg.DNSServer.ServerAddresses.Count -eq 0) {
                $missingDns += $name
            }

            if (-not $cfg.IPv4DefaultGateway) {
                $missingGateway += $name
            }

            try {
                $iface = Get-NetIPInterface -InterfaceIndex $cfg.InterfaceIndex -AddressFamily IPv4 -ErrorAction Stop
                if ($iface.Dhcp -ne 'Enabled') {
                    $dhcpDisabled += $name
                }
            }
            catch {
                continue
            }
        }

        if ($missingDns.Count -gt 0 -or $missingGateway.Count -gt 0) {
            $detail = "Aktive Interfaces: $($configs.Count)."
            if ($missingDns.Count -gt 0) {
                $detail = "$detail Kein DNS: $($missingDns -join ', ')."
            }
            if ($missingGateway.Count -gt 0) {
                $detail = "$detail Kein IPv4-Gateway: $($missingGateway -join ', ')."
            }

            return New-NetworkScanResult -Name 'IP / DHCP / DNS' -Status 'Yellow' -Detail $detail -Recommendation 'IP- und DNS-Konfiguration pruefen, bei Bedarf DHCP-Lease erneuern.'
        }

        if ($dhcpDisabled.Count -eq $configs.Count) {
            return New-NetworkScanResult -Name 'IP / DHCP / DNS' -Status 'Yellow' -Detail 'DHCP ist auf allen aktiven IPv4-Interfaces deaktiviert (statische Konfiguration erkannt).' -Recommendation 'Falls nicht beabsichtigt, DHCP aktivieren oder statische Werte validieren.'
        }

        return New-NetworkScanResult -Name 'IP / DHCP / DNS' -Status 'Green' -Detail "$($configs.Count) aktive Interface-Konfiguration(en) geprueft, DNS/Gateway unauffaellig." -Recommendation 'Keine Aenderung erforderlich.'
    }
    catch {
        return New-NetworkScanResult -Name 'IP / DHCP / DNS' -Status 'Yellow' -Detail "IP-Konfigurationspruefung fehlgeschlagen: $($_.Exception.Message)" -Recommendation 'Get-NetIPConfiguration mit passenden Rechten erneut ausfuehren.'
    }
}

function Get-NetworkMtuScanResult {
    try {
        $interfaces = Get-NetIPInterface -AddressFamily IPv4 -ErrorAction Stop |
            Where-Object {
                $_.ConnectionState -eq 'Connected' -and
                $_.InterfaceAlias -notmatch 'Loopback|isatap|Teredo|Pseudo-Interface'
            }
        $interfaces = @($interfaces)

        if (-not $interfaces) {
            return New-NetworkScanResult -Name 'MTU / Jumbo Frames' -Status 'Yellow' -Detail 'Keine verbundenen IPv4-Interfaces fuer MTU-Pruefung gefunden.' -Recommendation 'Interface-Status pruefen und Scan erneut ausfuehren.'
        }

        $critical = $interfaces | Where-Object { $_.NlMtu -le 576 }
        $nonStandard = $interfaces | Where-Object { $_.NlMtu -ne 1500 }

        if ($critical) {
            $detail = ($critical | ForEach-Object { "$($_.InterfaceAlias)=$($_.NlMtu)" }) -join ', '
            return New-NetworkScanResult -Name 'MTU / Jumbo Frames' -Status 'Red' -Detail "Sehr niedrige MTU erkannt: $detail" -Recommendation 'MTU auf sinnvolle Werte (typisch 1500) setzen und Pfad-MTU-Probleme pruefen.'
        }

        if ($nonStandard) {
            $detail = ($nonStandard | ForEach-Object { "$($_.InterfaceAlias)=$($_.NlMtu)" }) -join ', '
            return New-NetworkScanResult -Name 'MTU / Jumbo Frames' -Status 'Yellow' -Detail "Nicht standardisierte MTU erkannt: $detail" -Recommendation 'MTU/Jumbo-Frame-Konfiguration mit Router/Switch abstimmen.'
        }

        return New-NetworkScanResult -Name 'MTU / Jumbo Frames' -Status 'Green' -Detail "$($interfaces.Count) verbundene Interface(s) geprueft, MTU unauffaellig." -Recommendation 'Keine Aenderung erforderlich.'
    }
    catch {
        return New-NetworkScanResult -Name 'MTU / Jumbo Frames' -Status 'Yellow' -Detail "MTU-Pruefung fehlgeschlagen: $($_.Exception.Message)" -Recommendation 'Get-NetIPInterface Verfuegbarkeit und Rechte pruefen.'
    }
}

function Get-DnsResolverScanResult {
    try {
        $upAliases = (Get-NetAdapter -ErrorAction Stop | Where-Object { $_.Status -eq 'Up' } | Select-Object -ExpandProperty Name)
        $dnsConfigs = Get-DnsClientServerAddress -AddressFamily IPv4 -ErrorAction Stop |
            Where-Object { $_.InterfaceAlias -in $upAliases }
        $dnsConfigs = @($dnsConfigs)

        if (-not $dnsConfigs) {
            return New-NetworkScanResult -Name 'DNS Resolver' -Status 'Red' -Detail 'Keine DNS-Konfiguration fuer aktive Adapter gefunden.' -Recommendation 'DNS-Server fuer aktive Adapter konfigurieren (DHCP oder statisch).'
        }

        $invalidServers = @()
        $emptyAdapters = @()

        foreach ($cfg in $dnsConfigs) {
            $servers = @($cfg.ServerAddresses)
            if (-not $servers -or $servers.Count -eq 0) {
                $emptyAdapters += $cfg.InterfaceAlias
                continue
            }

            foreach ($server in $servers) {
                $parsed = $null
                if (-not [System.Net.IPAddress]::TryParse($server, [ref]$parsed)) {
                    $invalidServers += "$($cfg.InterfaceAlias):$server"
                }
            }
        }

        if ($emptyAdapters.Count -gt 0) {
            return New-NetworkScanResult -Name 'DNS Resolver' -Status 'Red' -Detail "Aktive Adapter ohne DNS-Server: $($emptyAdapters -join ', ')" -Recommendation 'DNS per DHCP beziehen oder gueltige DNS-Server setzen.'
        }

        if ($invalidServers.Count -gt 0) {
            return New-NetworkScanResult -Name 'DNS Resolver' -Status 'Yellow' -Detail "Ungueltige DNS-Servereintraege erkannt: $($invalidServers -join ' | ')" -Recommendation 'DNS-Serverliste bereinigen und Erreichbarkeit pruefen.'
        }

        $allServers = @($dnsConfigs | ForEach-Object { $_.ServerAddresses } | Where-Object { $_ })
        $uniqueCount = (@($allServers | Select-Object -Unique)).Count
        return New-NetworkScanResult -Name 'DNS Resolver' -Status 'Green' -Detail "$($dnsConfigs.Count) Adapter geprueft, $uniqueCount eindeutige DNS-Resolver konfiguriert." -Recommendation 'Keine Aenderung erforderlich.'
    }
    catch {
        return New-NetworkScanResult -Name 'DNS Resolver' -Status 'Yellow' -Detail "DNS-Pruefung fehlgeschlagen: $($_.Exception.Message)" -Recommendation 'Get-DnsClientServerAddress Verfuegbarkeit pruefen.'
    }
}

function Get-RouteMetricScanResult {
    try {
        $defaultRoutes = Get-NetRoute -AddressFamily IPv4 -DestinationPrefix '0.0.0.0/0' -ErrorAction Stop |
            Where-Object { $_.NextHop -and $_.NextHop -ne '0.0.0.0' }
        $defaultRoutes = @($defaultRoutes)

        if (-not $defaultRoutes) {
            return New-NetworkScanResult -Name 'Route / Interface-Metrik' -Status 'Red' -Detail 'Keine gueltige IPv4-Default-Route gefunden.' -Recommendation 'Gateway-Konfiguration und DHCP/Static-Routen pruefen.'
        }

        $effective = @()
        foreach ($route in $defaultRoutes) {
            $ifaceMetric = 0
            try {
                $iface = Get-NetIPInterface -InterfaceIndex $route.InterfaceIndex -AddressFamily IPv4 -ErrorAction Stop
                $ifaceMetric = [int]$iface.InterfaceMetric
            }
            catch {
                $ifaceMetric = 0
            }

            $effective += [PSCustomObject]@{
                InterfaceIndex   = $route.InterfaceIndex
                NextHop          = $route.NextHop
                RouteMetric      = [int]$route.RouteMetric
                InterfaceMetric  = $ifaceMetric
                EffectiveMetric  = ([int]$route.RouteMetric + [int]$ifaceMetric)
            }
        }

        $bestMetric = ($effective | Measure-Object -Property EffectiveMetric -Minimum).Minimum
        $bestRoutes = $effective | Where-Object { $_.EffectiveMetric -eq $bestMetric }

        if ($bestRoutes.Count -gt 1) {
            $detail = ($bestRoutes | ForEach-Object { "IfIndex=$($_.InterfaceIndex),NextHop=$($_.NextHop),Metric=$($_.EffectiveMetric)" }) -join ' | '
            return New-NetworkScanResult -Name 'Route / Interface-Metrik' -Status 'Yellow' -Detail "Mehrere gleich priorisierte Default-Routen erkannt: $detail" -Recommendation 'InterfaceMetric oder RouteMetric gezielt setzen, um Prioritaet eindeutig zu machen.'
        }

        return New-NetworkScanResult -Name 'Route / Interface-Metrik' -Status 'Green' -Detail "$($defaultRoutes.Count) Default-Route(n) geprueft, Prioritaet eindeutig (Metric=$bestMetric)." -Recommendation 'Keine Aenderung erforderlich.'
    }
    catch {
        return New-NetworkScanResult -Name 'Route / Interface-Metrik' -Status 'Yellow' -Detail "Routenpruefung fehlgeschlagen: $($_.Exception.Message)" -Recommendation 'Get-NetRoute/Get-NetIPInterface Verfuegbarkeit pruefen.'
    }
}

function Get-NetworkServiceStateScanResult {
    $serviceNames = @('Dhcp', 'Dnscache', 'NlaSvc', 'Netman', 'WlanSvc')

    try {
        $services = foreach ($svc in $serviceNames) {
            Get-Service -Name $svc -ErrorAction SilentlyContinue
        }

        $services = $services | Where-Object { $_ }
        if (-not $services) {
            return New-NetworkScanResult -Name 'Netzwerkdienste-Status' -Status 'Yellow' -Detail 'Keine der erwarteten Netzwerkdienste konnte gelesen werden.' -Recommendation 'Service Control Manager Zugriff pruefen.'
        }

        $criticalStopped = $services | Where-Object { $_.Name -in @('Dhcp', 'Dnscache', 'NlaSvc') -and $_.Status -ne 'Running' }
        $nonCriticalStopped = $services | Where-Object { $_.Name -in @('Netman', 'WlanSvc') -and $_.Status -ne 'Running' }

        if ($criticalStopped) {
            $detail = ($criticalStopped | ForEach-Object { "$($_.Name)=$($_.Status)" }) -join ', '
            return New-NetworkScanResult -Name 'Netzwerkdienste-Status' -Status 'Red' -Detail "Kritische Netzwerkdienste nicht aktiv: $detail" -Recommendation 'Dienste starten und Starttyp pruefen (Automatic/AutomaticDelayedStart).'
        }

        if ($nonCriticalStopped) {
            $detail = ($nonCriticalStopped | ForEach-Object { "$($_.Name)=$($_.Status)" }) -join ', '
            return New-NetworkScanResult -Name 'Netzwerkdienste-Status' -Status 'Yellow' -Detail "Nicht-kritische Netzwerkdienste sind nicht aktiv: $detail" -Recommendation 'Je nach Nutzung (LAN/WLAN) Dienststatus pruefen und ggf. aktivieren.'
        }

        return New-NetworkScanResult -Name 'Netzwerkdienste-Status' -Status 'Green' -Detail "$($services.Count) Netzwerkdienste geprueft, keine Auffaelligkeiten." -Recommendation 'Keine Aenderung erforderlich.'
    }
    catch {
        return New-NetworkScanResult -Name 'Netzwerkdienste-Status' -Status 'Yellow' -Detail "Dienstpruefung fehlgeschlagen: $($_.Exception.Message)" -Recommendation 'Service-Zugriff und lokale Richtlinien pruefen.'
    }
}

function Get-ProxyMismatchScanResult {
    try {
        $userProxyKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings'
        $userProxy = Get-ItemProperty -Path $userProxyKey -ErrorAction Stop
        $userProxyEnabled = [int]($userProxy.ProxyEnable)
        $userProxyServer = "$($userProxy.ProxyServer)"
        $autoConfigUrl = "$($userProxy.AutoConfigURL)"

        $winHttpRaw = netsh winhttp show proxy 2>$null
        $winHttpText = ($winHttpRaw | Out-String)

        $winHttpDirect = $false
        $winHttpProxy = $null
        if ($winHttpText -match 'Direct access \(no proxy server\)|Direkter Zugriff \(kein Proxyserver\)') {
            $winHttpDirect = $true
        }
        if ($winHttpText -match 'Proxy Server\(s\)\s*:\s*(.+)' -or $winHttpText -match 'Proxyserver\s*:\s*(.+)') {
            $winHttpProxy = $Matches[1].Trim()
        }

        if ($userProxyEnabled -eq 1 -and [string]::IsNullOrWhiteSpace($userProxyServer) -and [string]::IsNullOrWhiteSpace($autoConfigUrl)) {
            return New-NetworkScanResult -Name 'Proxy / WinHTTP Konsistenz' -Status 'Red' -Detail 'User-Proxy ist aktiviert, aber weder ProxyServer noch AutoConfigURL sind gesetzt.' -Recommendation 'Proxy deaktivieren oder gueltige Proxy-Konfiguration hinterlegen.'
        }

        if ($userProxyEnabled -eq 0 -and -not [string]::IsNullOrWhiteSpace($winHttpProxy) -and -not $winHttpDirect) {
            return New-NetworkScanResult -Name 'Proxy / WinHTTP Konsistenz' -Status 'Yellow' -Detail "WinHTTP nutzt Proxy ($winHttpProxy), User-Kontext jedoch nicht." -Recommendation 'Proxy-Strategie zwischen WinHTTP und User-Kontext angleichen.'
        }

        if ($userProxyEnabled -eq 1 -and $winHttpDirect -and [string]::IsNullOrWhiteSpace($autoConfigUrl)) {
            return New-NetworkScanResult -Name 'Proxy / WinHTTP Konsistenz' -Status 'Yellow' -Detail 'User-Kontext nutzt statischen Proxy, WinHTTP jedoch Direct Access.' -Recommendation 'Bei Problemen WinHTTP-Proxy importieren oder User-Proxy pruefen.'
        }

        return New-NetworkScanResult -Name 'Proxy / WinHTTP Konsistenz' -Status 'Green' -Detail 'Keine kritische Proxy-Inkonsistenz zwischen User-Kontext und WinHTTP erkannt.' -Recommendation 'Keine Aenderung erforderlich.'
    }
    catch {
        return New-NetworkScanResult -Name 'Proxy / WinHTTP Konsistenz' -Status 'Yellow' -Detail "Proxy-Pruefung fehlgeschlagen: $($_.Exception.Message)" -Recommendation 'Internet Settings Registry und netsh winhttp Ausgabe pruefen.'
    }
}

function New-DiagnosisResult {
    param(
        [string]$AdapterName,
        [string]$ProblemType,
        [string]$Severity,
        [string]$RootCauseDescription,
        [object[]]$RecommendedActions,
        [int]$ConfidenceScore,
        [string]$RuleId,
        [string]$Source,
        [string]$Evidence,
        [string]$AffectedItem = $null
    )

    [PSCustomObject]@{
        AdapterName         = $AdapterName
        ProblemType         = $ProblemType
        Severity            = $Severity
        RootCauseDescription = $RootCauseDescription
        RecommendedActions  = @($RecommendedActions)
        ConfidenceScore     = $ConfidenceScore
        RuleId              = $RuleId
        Source              = $Source
        Evidence            = $Evidence
        AffectedItem        = $AffectedItem
    }
}

function New-RecommendationItem {
    param(
        [int]$Priority,
        [string]$Action,
        [string]$Description,
        [string]$Command,
        [string]$ProblemType,
        [string]$Severity
    )

    [PSCustomObject]@{
        Priority    = $Priority
        Action      = $Action
        Description = $Description
        Command     = $Command
        ProblemType = $ProblemType
        Severity    = $Severity
    }
}

function Get-SeverityRank {
    param([string]$Severity)

    switch ($Severity) {
        'Critical' { return 0 }
        'Warning'  { return 1 }
        default    { return 2 }
    }
}

function Get-NetworkGuideContext {
    $default = [PSCustomObject]@{
        PreferredAlias = 'Ethernet'
        IsWireless = $false
        SettingsUri = 'ms-settings:network-ethernet'
    }

    try {
        $upAdapters = @(Get-NetAdapter -Physical -ErrorAction Stop | Where-Object { $_.Status -eq 'Up' })
        if (-not $upAdapters -or $upAdapters.Count -eq 0) {
            return $default
        }

        $wirelessAdapter = $upAdapters | Where-Object { $_.Name -match '(?i)wi-?fi|wlan|wireless' } | Select-Object -First 1
        $preferred = if ($wirelessAdapter) { $wirelessAdapter } else { $upAdapters | Select-Object -First 1 }
        $alias = if ($preferred.Name) { "$($preferred.Name)" } else { 'Ethernet' }
        $isWireless = $alias -match '(?i)wi-?fi|wlan|wireless'

        return [PSCustomObject]@{
            PreferredAlias = $alias
            IsWireless = $isWireless
            SettingsUri = if ($isWireless) { 'ms-settings:network-wifi' } else { 'ms-settings:network-ethernet' }
        }
    }
    catch {
        return $default
    }
}

function Get-NetworkManualGuidance {
    param(
        [string]$ProblemType,
        [string]$AffectedItem
    )

    $guideContext = Get-NetworkGuideContext
    $preferredAlias = $guideContext.PreferredAlias
    $primarySettingsUri = $guideContext.SettingsUri
    $classicAdapterTool = 'ncpa.cpl'

    $getAdvancedPropsCmd = 'Get-NetAdapterAdvancedProperty -Name "{0}"' -f $preferredAlias
    $setAutoNegotiationCmd = 'Set-NetAdapterAdvancedProperty -Name "{0}" -DisplayName "Speed & Duplex" -DisplayValue "Auto Negotiation"' -f $preferredAlias
    $getPowerMgmtCmd = 'Get-NetAdapterPowerManagement -Name "{0}"' -f $preferredAlias
    $setPowerMgmtCmd = 'Set-NetAdapterPowerManagement -Name "{0}" -AllowComputerToTurnOffDevice Disabled' -f $preferredAlias
    $setMtuCmd = 'netsh interface ipv4 set subinterface "{0}" mtu=1500 store=persistent' -f $preferredAlias
    $setDnsCmd = 'Set-DnsClientServerAddress -InterfaceAlias "{0}" -ServerAddresses 1.1.1.1,8.8.8.8' -f $preferredAlias
    $setMetricCmd = 'Set-NetIPInterface -InterfaceAlias "{0}" -InterfaceMetric 25' -f $preferredAlias

    $map = @{
        LinkFlap = [PSCustomObject]@{
            ProblemType      = 'LinkFlap'
            Title            = 'Link-Flaps und physikalische Stabilitaet'
            SettingsUri      = $primarySettingsUri
            ClassicTool      = 'devmgmt.msc'
            InspectCommands  = @(
                'Get-WinEvent -LogName System -MaxEvents 300 | Where-Object { $_.ProviderName -match "aqnic650" -and $_.Id -in 14,15 }',
                $getAdvancedPropsCmd
            )
            FixCommands      = @(
                $setAutoNegotiationCmd
            )
            ManualSteps      = @(
                'Win + R -> devmgmt.msc',
                'Netzwerkadapter waehlen -> Eigenschaften -> Erweitert',
                'Speed & Duplex auf Auto Negotiation stellen',
                'LAN-Kabel und Switch-Port tauschen/testen'
            )
        }
        SpeedNegotiation = [PSCustomObject]@{
            ProblemType      = 'SpeedNegotiation'
            Title            = 'Speed/Duplex manuell gesetzt'
            SettingsUri      = $primarySettingsUri
            ClassicTool      = $classicAdapterTool
            InspectCommands  = @('{0} | Where-Object {{ $_.DisplayName -match "Speed|Duplex|Negotiation" }}' -f $getAdvancedPropsCmd)
            FixCommands      = @($setAutoNegotiationCmd)
            ManualSteps      = @(
                'Win + R -> ncpa.cpl',
                'Adapter -> Eigenschaften -> Konfigurieren -> Erweitert',
                'Speed & Duplex auf Auto setzen'
            )
        }
        PowerSettings = [PSCustomObject]@{
            ProblemType      = 'PowerSettings'
            Title            = 'NIC-Energieverwaltung pruefen'
            SettingsUri      = $primarySettingsUri
            ClassicTool      = 'devmgmt.msc'
            InspectCommands  = @($getPowerMgmtCmd)
            FixCommands      = @($setPowerMgmtCmd)
            ManualSteps      = @(
                'Win + R -> devmgmt.msc',
                'Adapter -> Eigenschaften -> Energieverwaltung',
                '"Computer kann das Geraet ausschalten" testweise deaktivieren'
            )
        }
        FastStartupInfluence = [PSCustomObject]@{
            ProblemType      = 'FastStartupInfluence'
            Title            = 'Fast Startup / Hibernation'
            SettingsUri      = 'ms-settings:powersleep'
            ClassicTool      = 'control.exe /name Microsoft.PowerOptions'
            InspectCommands  = @('Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power" | Select-Object HiberbootEnabled')
            FixCommands      = @('reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power" /v HiberbootEnabled /t REG_DWORD /d 0 /f')
            ManualSteps      = @(
                'Energieoptionen oeffnen',
                'Auswaehlen, was beim Druecken von Netzschaltern geschehen soll',
                'Schnellstart deaktivieren und speichern',
                'Vollstaendigen Neustart ausfuehren'
            )
        }
        OutdatedDriver = [PSCustomObject]@{
            ProblemType      = 'OutdatedDriver'
            Title            = 'Netzwerktreiber aktualisieren'
            SettingsUri      = 'ms-settings:windowsupdate'
            ClassicTool      = 'devmgmt.msc'
            InspectCommands  = @('Get-CimInstance Win32_PnPSignedDriver | Where-Object { $_.DeviceClass -eq "NET" } | Select-Object DeviceName,DriverVersion,DriverDate')
            FixCommands      = @()
            ManualSteps      = @(
                'Geraetemanager oeffnen',
                'Adapter -> Treiber aktualisieren',
                'Optional Herstellerpaket vom Board-/NIC-Hersteller nutzen'
            )
        }
        MtuMismatch = [PSCustomObject]@{
            ProblemType      = 'MtuMismatch'
            Title            = 'MTU/Jumbo-Frame Konsistenz'
            SettingsUri      = $primarySettingsUri
            ClassicTool      = $classicAdapterTool
            InspectCommands  = @('Get-NetIPInterface -AddressFamily IPv4 | Select-Object InterfaceAlias,NlMtu,ConnectionState')
            FixCommands      = @($setMtuCmd)
            ManualSteps      = @(
                'MTU auf Endgeraet, Switch und Router abstimmen',
                'Bei unklaren Settings mit 1500 starten und testen'
            )
        }
        DnsResolverIssue = [PSCustomObject]@{
            ProblemType      = 'DnsResolverIssue'
            Title            = 'DNS-Resolver pruefen'
            SettingsUri      = $primarySettingsUri
            ClassicTool      = $classicAdapterTool
            InspectCommands  = @('Get-DnsClientServerAddress -AddressFamily IPv4')
            FixCommands      = @($setDnsCmd)
            ManualSteps      = @(
                'Adapter-Eigenschaften -> IPv4 -> DNS-Server pruefen',
                'Bei Bedarf auf DHCP oder gueltige Resolver umstellen'
            )
        }
        RouteMetricConflict = [PSCustomObject]@{
            ProblemType      = 'RouteMetricConflict'
            Title            = 'Default-Route und Metrik'
            SettingsUri      = $primarySettingsUri
            ClassicTool      = $classicAdapterTool
            InspectCommands  = @(
                'Get-NetRoute -DestinationPrefix "0.0.0.0/0" | Select-Object InterfaceIndex,NextHop,RouteMetric',
                'Get-NetIPInterface -AddressFamily IPv4 | Select-Object InterfaceAlias,InterfaceMetric'
            )
            FixCommands      = @($setMetricCmd)
            ManualSteps      = @(
                'Nur benoetigte Default-Gateways aktiv lassen',
                'Metriken so setzen, dass eine Route eindeutig bevorzugt ist'
            )
        }
        ServiceStateIssue = [PSCustomObject]@{
            ProblemType      = 'ServiceStateIssue'
            Title            = 'Kritischer Netzwerkdienst'
            SettingsUri      = 'ms-settings:network-status'
            ClassicTool      = 'services.msc'
            InspectCommands  = @('Get-Service Dhcp,Dnscache,NlaSvc,Netman,WlanSvc | Select-Object Name,Status,StartType')
            FixCommands      = @('Start-Service Dhcp,Dnscache,NlaSvc')
            ManualSteps      = @(
                'Win + R -> services.msc',
                'Dhcp, Dnscache, NlaSvc auf Running/Automatic pruefen',
                'Dienste starten und Neustart testen'
            )
        }
        ProxyMismatch = [PSCustomObject]@{
            ProblemType      = 'ProxyMismatch'
            Title            = 'Proxy (User vs. WinHTTP)'
            SettingsUri      = 'ms-settings:network-proxy'
            ClassicTool      = 'inetcpl.cpl'
            InspectCommands  = @(
                'netsh winhttp show proxy',
                'Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings" | Select-Object ProxyEnable,ProxyServer,AutoConfigURL'
            )
            FixCommands      = @('netsh winhttp import proxy source=ie')
            ManualSteps      = @(
                'Proxy in Windows-Einstellungen pruefen',
                'User-Proxy und WinHTTP-Proxy auf konsistente Strategie bringen'
            )
        }
        IpConfigIssue = [PSCustomObject]@{
            ProblemType      = 'IpConfigIssue'
            Title            = 'IP/DHCP/Gateway Basisprobleme'
            SettingsUri      = $primarySettingsUri
            ClassicTool      = $classicAdapterTool
            InspectCommands  = @('Get-NetIPConfiguration', 'ipconfig /all')
            FixCommands      = @('ipconfig /release; ipconfig /renew; ipconfig /flushdns')
            ManualSteps      = @(
                'Adapter-Konfiguration auf DHCP/statisch validieren',
                'Lease erneuern und DNS-Cache leeren'
            )
        }
    }

    if ($ProblemType -eq 'ServiceStateIssue' -and -not [string]::IsNullOrWhiteSpace($AffectedItem)) {
        $serviceName = $AffectedItem.Trim()
        $serviceProfile = switch ($serviceName.ToLowerInvariant()) {
            'dhcp' {
                [PSCustomObject]@{
                    Title = 'DHCP-Client Dienst'
                    SettingsUri = 'ms-settings:network-ethernet'
                    ClassicTool = 'ncpa.cpl'
                    InspectCommands = @(
                        'Get-NetIPConfiguration',
                        "Get-Service $serviceName | Select-Object Name,Status,StartType"
                    )
                    FixCommands = @(
                        "Set-Service $serviceName -StartupType Automatic",
                        "Start-Service $serviceName",
                        'ipconfig /renew'
                    )
                    ManualSteps = @(
                        'Ethernet-Einstellungen oeffnen und IP-Zuweisung pruefen',
                        'Win + R -> services.msc',
                        "Dienst $serviceName auf Automatic setzen und starten",
                        'DHCP-Lease erneuern und Verbindung erneut pruefen'
                    )
                }
            }
            'dnscache' {
                [PSCustomObject]@{
                    Title = 'DNS-Client Dienst'
                    SettingsUri = 'ms-settings:network-ethernet'
                    ClassicTool = 'services.msc'
                    InspectCommands = @(
                        'Get-DnsClientServerAddress -AddressFamily IPv4',
                        "Get-Service $serviceName | Select-Object Name,Status,StartType"
                    )
                    FixCommands = @(
                        "Set-Service $serviceName -StartupType Automatic",
                        "Start-Service $serviceName",
                        'ipconfig /flushdns'
                    )
                    ManualSteps = @(
                        'Adapter-Einstellungen oeffnen und DNS-Server pruefen',
                        'Win + R -> services.msc',
                        "Dienst $serviceName auf Automatic setzen und starten",
                        'DNS-Cache leeren und Namensaufloesung erneut testen'
                    )
                }
            }
            'nlasvc' {
                [PSCustomObject]@{
                    Title = 'Network Location Awareness (NLA)'
                    SettingsUri = 'ms-settings:network-status'
                    ClassicTool = 'services.msc'
                    InspectCommands = @(
                        "Get-Service $serviceName | Select-Object Name,Status,StartType",
                        'Get-NetConnectionProfile | Select-Object InterfaceAlias,NetworkCategory,IPv4Connectivity'
                    )
                    FixCommands = @(
                        "Set-Service $serviceName -StartupType Automatic",
                        "Start-Service $serviceName"
                    )
                    ManualSteps = @(
                        'Netzwerkstatus oeffnen und aktuelles Profil pruefen',
                        'Win + R -> services.msc',
                        "Dienst $serviceName auf Automatic setzen und starten",
                        'Netzwerkprofil und Erkennung nach Dienststart erneut pruefen'
                    )
                }
            }
            'netman' {
                [PSCustomObject]@{
                    Title = 'Network Connections Dienst'
                    SettingsUri = 'ms-settings:network-advancedsettings'
                    ClassicTool = 'ncpa.cpl'
                    InspectCommands = @(
                        "Get-Service $serviceName | Select-Object Name,Status,StartType",
                        'Get-NetAdapter | Select-Object Name,Status,LinkSpeed,MacAddress'
                    )
                    FixCommands = @(
                        "Set-Service $serviceName -StartupType Manual",
                        "Start-Service $serviceName"
                    )
                    ManualSteps = @(
                        'Erweiterte Netzwerkeinstellungen oeffnen',
                        'Win + R -> services.msc',
                        "Dienst $serviceName starten",
                        'Adapterliste in ncpa.cpl erneut laden und Verbindungen pruefen'
                    )
                }
            }
            'wlansvc' {
                [PSCustomObject]@{
                    Title = 'WLAN AutoConfig Dienst'
                    SettingsUri = 'ms-settings:network-wifi'
                    ClassicTool = 'ncpa.cpl'
                    InspectCommands = @(
                        'netsh wlan show interfaces',
                        "Get-Service $serviceName | Select-Object Name,Status,StartType"
                    )
                    FixCommands = @(
                        "Set-Service $serviceName -StartupType Automatic",
                        "Start-Service $serviceName"
                    )
                    ManualSteps = @(
                        'WLAN-Einstellungen oeffnen',
                        'Verfuegbare Funknetze und WLAN-Schalter pruefen',
                        'Win + R -> services.msc',
                        "Dienst $serviceName auf Automatic setzen und starten"
                    )
                }
            }
            default {
                [PSCustomObject]@{
                    Title = "Dienst $serviceName"
                    SettingsUri = 'ms-settings:network-status'
                    ClassicTool = 'services.msc'
                    InspectCommands = @("Get-Service $serviceName | Select-Object Name,Status,StartType")
                    FixCommands = @(
                        "Set-Service $serviceName -StartupType Automatic",
                        "Start-Service $serviceName"
                    )
                    ManualSteps = @(
                        'Win + R -> services.msc',
                        "Dienst $serviceName suchen und oeffnen",
                        'Starttyp auf Automatic/AutomaticDelayedStart setzen',
                        'Dienst starten und Netzwerkerkennung erneut pruefen'
                    )
                }
            }
        }

        return [PSCustomObject]@{
            ProblemType      = 'ServiceStateIssue'
            Title            = "$($serviceProfile.Title) ist nicht aktiv"
            SettingsUri      = $serviceProfile.SettingsUri
            ClassicTool      = $serviceProfile.ClassicTool
            InspectCommands  = @($serviceProfile.InspectCommands)
            FixCommands      = @($serviceProfile.FixCommands)
            ManualSteps      = @($serviceProfile.ManualSteps)
        }
    }

    if ([string]::IsNullOrWhiteSpace($ProblemType)) {
        return $map
    }

    if ($map.ContainsKey($ProblemType)) {
        return $map[$ProblemType]
    }

    return $null
}

function Write-NetworkManualGuidanceReport {
    param(
        [System.Windows.Forms.RichTextBox]$OutputBox,
        [object[]]$Diagnostics
    )

    $guidanceEntries = @(
        $Diagnostics |
            Where-Object { $_.ProblemType } |
            Group-Object -Property { "{0}|{1}" -f $_.ProblemType, $_.AffectedItem } |
            ForEach-Object { $_.Group | Select-Object -First 1 }
    )
    if (-not $guidanceEntries -or $guidanceEntries.Count -eq 0) {
        return
    }

    Write-NetworkScanOutput -OutputBox $OutputBox -Text ''
    Write-NetworkScanOutput -OutputBox $OutputBox -Style 'Heading' -Text 'Manuelle User-Anleitung (Win11 + CMD/PS)'

    foreach ($entry in $guidanceEntries) {
        $guide = Get-NetworkManualGuidance -ProblemType $entry.ProblemType -AffectedItem $entry.AffectedItem
        if (-not $guide) { continue }

        Write-NetworkScanOutput -OutputBox $OutputBox -Style 'Action' -Text ("[{0}] {1}" -f $guide.ProblemType, $guide.Title)
        if (-not [string]::IsNullOrWhiteSpace($guide.SettingsUri)) {
            Write-NetworkScanOutput -OutputBox $OutputBox -Style 'Muted' -Text ("  Win11-Menue: {0}" -f $guide.SettingsUri)
        }
        if (-not [string]::IsNullOrWhiteSpace($guide.ClassicTool)) {
            Write-NetworkScanOutput -OutputBox $OutputBox -Style 'Muted' -Text ("  Klassisch: {0}" -f $guide.ClassicTool)
        }

        foreach ($cmd in @($guide.InspectCommands)) {
            Write-NetworkScanOutput -OutputBox $OutputBox -Style 'Default' -Text ("  Pruefen: {0}" -f $cmd)
        }
        foreach ($cmd in @($guide.FixCommands)) {
            Write-NetworkScanOutput -OutputBox $OutputBox -Style 'Default' -Text ("  Optionaler Fix: {0}" -f $cmd)
        }
        foreach ($step in @($guide.ManualSteps)) {
            Write-NetworkScanOutput -OutputBox $OutputBox -Style 'Muted' -Text ("  - {0}" -f $step)
        }
    }
}

function Show-NetworkManualGuideWindow {
    param(
        [object[]]$Diagnostics,
        [System.Windows.Forms.RichTextBox]$OutputBox
    )

    $diagnostics = @($Diagnostics)
    $orderedDiagnostics = @(
        $diagnostics |
            Where-Object { $_.ProblemType } |
            Sort-Object @{ Expression = { Get-SeverityRank -Severity $_.Severity } }, @{ Expression = { -1 * [int]$_.ConfidenceScore } }
    )

    if (-not $orderedDiagnostics -or $orderedDiagnostics.Count -eq 0) {
        Write-NetworkScanOutput -OutputBox $OutputBox -Style 'Warning' -Text 'Keine Diagnosen fuer das manuelle Hilfe-Fenster verfuegbar.'
        return $null
    }

    [xml]$xaml = @'
<Window
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="" Width="980" Height="640"
    WindowStyle="None" AllowsTransparency="True" ResizeMode="NoResize"
    WindowStartupLocation="CenterScreen"
    Background="Transparent">

    <Window.Resources>
        <Style x:Key="BtnBase" TargetType="Button">
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="FontFamily" Value="Segoe UI"/>
            <Setter Property="FontSize" Value="12"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="bd" CornerRadius="8"
                                Background="{TemplateBinding Background}">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="bd" Property="Opacity" Value="0.9"/>
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter TargetName="bd" Property="Opacity" Value="0.8"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style TargetType="TextBlock">
            <Setter Property="Foreground" Value="#E6E6E6"/>
            <Setter Property="FontFamily" Value="Segoe UI"/>
        </Style>
    </Window.Resources>

    <Border CornerRadius="12" Background="#1E1E1E" BorderBrush="#4A4A4A" BorderThickness="1">
        <Grid>
            <Grid.RowDefinitions>
                <RowDefinition Height="44"/>
                <RowDefinition Height="2"/>
                <RowDefinition Height="*"/>
                <RowDefinition Height="120"/>
            </Grid.RowDefinitions>

            <Border Grid.Row="0" Background="#262626" CornerRadius="12,12,0,0" x:Name="DragHeader">
                <Grid>
                    <TextBlock Text="  ⬡  Netzwerk  -  Manuelle Anleitung" Foreground="#00B464" FontSize="14" FontWeight="Bold" VerticalAlignment="Center"/>
                    <Button x:Name="BtnClose" Content="✕" HorizontalAlignment="Right" Width="44" Height="44"
                            Background="Transparent" Foreground="#A0A0A0" BorderThickness="0" Cursor="Hand"/>
                </Grid>
            </Border>

            <Rectangle Grid.Row="1" Fill="#00B464"/>

            <Grid Grid.Row="2" Margin="12,12,12,8">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="260"/>
                    <ColumnDefinition Width="10"/>
                    <ColumnDefinition Width="*"/>
                </Grid.ColumnDefinitions>

                <Border Grid.Column="0" Background="#2A2A2A" BorderBrush="#3F3F3F" BorderThickness="1" CornerRadius="8">
                    <DockPanel Margin="10">
                        <TextBlock DockPanel.Dock="Top" Text="Erkannte Problemtypen (kritisch zuerst)" FontWeight="SemiBold" Foreground="#B8B8B8" Margin="0,0,0,4"/>
                        <TextBlock DockPanel.Dock="Top" Text="Waehlen Sie links ein Problem. Rechts erscheinen direkte Schritte und Aktionen." Foreground="#8F8F8F" FontSize="11" Margin="0,0,0,8" TextWrapping="Wrap"/>
                        <ListBox x:Name="LstProblems" Background="#222" Foreground="#E6E6E6" BorderBrush="#404040"/>
                    </DockPanel>
                </Border>

                <Border Grid.Column="2" Background="#2A2A2A" BorderBrush="#3F3F3F" BorderThickness="1" CornerRadius="8">
                    <Grid Margin="12">
                        <Grid.RowDefinitions>
                            <RowDefinition Height="Auto"/>
                            <RowDefinition Height="Auto"/>
                            <RowDefinition Height="Auto"/>
                            <RowDefinition Height="Auto"/>
                            <RowDefinition Height="*"/>
                        </Grid.RowDefinitions>

                        <TextBlock x:Name="TxtTitle" Text="" FontSize="16" FontWeight="Bold" Foreground="#00D47A"/>
                        <TextBlock x:Name="TxtContext" Grid.Row="1" Margin="0,6,0,0" Text="" TextWrapping="Wrap" Foreground="#C7C7C7"/>
                        <TextBlock x:Name="TxtMenu" Grid.Row="2" Margin="0,4,0,0" Text="" TextWrapping="Wrap" Foreground="#B0B0B0"/>
                        <TextBlock x:Name="TxtClassic" Grid.Row="3" Margin="0,4,0,8" Text="" TextWrapping="Wrap" Foreground="#B0B0B0"/>

                        <TabControl Grid.Row="4" Background="#232323" BorderBrush="#454545">
                            <TabItem Header="Schritte">
                                <ListBox x:Name="LstSteps" Background="#202020" Foreground="#E8E8E8" BorderBrush="#404040"/>
                            </TabItem>
                            <TabItem Header="Pruef-Kommandos">
                                <ListBox x:Name="LstInspect" Background="#202020" Foreground="#E8E8E8" BorderBrush="#404040"/>
                            </TabItem>
                            <TabItem Header="Fix-Kommandos">
                                <ListBox x:Name="LstFix" Background="#202020" Foreground="#E8E8E8" BorderBrush="#404040"/>
                            </TabItem>
                        </TabControl>
                    </Grid>
                </Border>
            </Grid>

            <Grid Grid.Row="3" Margin="12,0,12,12">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="12"/>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="12"/>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="12"/>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="12"/>
                    <ColumnDefinition Width="*"/>
                </Grid.ColumnDefinitions>

                <Button x:Name="BtnOpenMenu" Grid.Column="0" Height="34" Background="#00B464" Foreground="#121212" Content="Windows-Einstellung oeffnen" Style="{StaticResource BtnBase}"/>
                <Button x:Name="BtnOpenClassic" Grid.Column="2" Height="34" Background="#2F8CFF" Foreground="White" Content="Klassisches Tool oeffnen" Style="{StaticResource BtnBase}"/>
                <Button x:Name="BtnAdminConsole" Grid.Column="4" Height="34" Background="#2E6A98" Foreground="White" Content="Admin-Konsole oeffnen" Style="{StaticResource BtnBase}"/>
                <Button x:Name="BtnCopyInspect" Grid.Column="6" Height="34" Background="#6A5ACD" Foreground="White" Content="Pruefbefehle kopieren" Style="{StaticResource BtnBase}"/>
                <Button x:Name="BtnCopyFix" Grid.Column="8" Height="34" Background="#A77700" Foreground="White" Content="Fixbefehle kopieren" Style="{StaticResource BtnBase}"/>

                <TextBlock Grid.ColumnSpan="9" VerticalAlignment="Bottom" Margin="4,0,4,0" Foreground="#8F8F8F"
                           Text="Hinweis: Kommandos werden nur vorgeschlagen, nicht automatisch ausgefuehrt."/>
            </Grid>
        </Grid>
    </Border>
</Window>
'@

    $reader = New-Object System.Xml.XmlNodeReader $xaml
    $wpfForm = [Windows.Markup.XamlReader]::Load($reader)

    $dragHeader = $wpfForm.FindName('DragHeader')
    $btnClose = $wpfForm.FindName('BtnClose')
    $lstProblems = $wpfForm.FindName('LstProblems')
    $txtTitle = $wpfForm.FindName('TxtTitle')
    $txtContext = $wpfForm.FindName('TxtContext')
    $txtMenu = $wpfForm.FindName('TxtMenu')
    $txtClassic = $wpfForm.FindName('TxtClassic')
    $lstSteps = $wpfForm.FindName('LstSteps')
    $lstInspect = $wpfForm.FindName('LstInspect')
    $lstFix = $wpfForm.FindName('LstFix')
    $btnOpenMenu = $wpfForm.FindName('BtnOpenMenu')
    $btnOpenClassic = $wpfForm.FindName('BtnOpenClassic')
    $btnAdminConsole = $wpfForm.FindName('BtnAdminConsole')
    $btnCopyInspect = $wpfForm.FindName('BtnCopyInspect')
    $btnCopyFix = $wpfForm.FindName('BtnCopyFix')

    $guides = @{}
    $listItems = @{}
    foreach ($diag in $orderedDiagnostics) {
        $ptype = $diag.ProblemType
        $pkey = "{0}|{1}" -f $ptype, $diag.AffectedItem
        if ($guides.ContainsKey($pkey)) { continue }

        $guide = Get-NetworkManualGuidance -ProblemType $ptype -AffectedItem $diag.AffectedItem
        if ($guide) {
            $guides[$pkey] = $guide
            $label = "[{0} | {1}%] {2}" -f $diag.Severity, $diag.ConfidenceScore, $guide.Title
            $listItems[$label] = [PSCustomObject]@{
                ProblemKey = $pkey
                ProblemType = $ptype
                AffectedItem = $diag.AffectedItem
                Severity = $diag.Severity
                ConfidenceScore = [int]$diag.ConfidenceScore
                RuleId = $diag.RuleId
            }
            [void]$lstProblems.Items.Add($label)
        }
    }

    if ($lstProblems.Items.Count -eq 0) {
        Write-NetworkScanOutput -OutputBox $OutputBox -Style 'Warning' -Text 'Keine passenden Guidance-Mappings fuer aktuelle Diagnosen gefunden.'
        return $null
    }

    $script:currentGuide = $null
    $script:currentGuideContext = $null
    $refreshGuide = {
        param($selectedLabel)
        if ([string]::IsNullOrWhiteSpace("$selectedLabel") -or -not $listItems.ContainsKey("$selectedLabel")) { return }

        $entry = $listItems["$selectedLabel"]
        if (-not $guides.ContainsKey($entry.ProblemKey)) { return }

        $guide = $guides[$entry.ProblemKey]
        $script:currentGuide = $guide
        $script:currentGuideContext = $entry

        $txtTitle.Text = "[$($guide.ProblemType)] $($guide.Title)"
        $txtContext.Text = "Prioritaet: $($entry.Severity) | Confidence: $($entry.ConfidenceScore)% | Regel: $($entry.RuleId)"
        $txtMenu.Text = if ([string]::IsNullOrWhiteSpace($guide.SettingsUri)) { 'Win11-Menue: -' } else { "Win11-Menue: $($guide.SettingsUri)" }
        $txtClassic.Text = if ([string]::IsNullOrWhiteSpace($guide.ClassicTool)) { 'Klassisches Tool: -' } else { "Klassisches Tool: $($guide.ClassicTool)" }

        $lstSteps.Items.Clear()
        foreach ($s in @($guide.ManualSteps)) { [void]$lstSteps.Items.Add($s) }

        $lstInspect.Items.Clear()
        foreach ($c in @($guide.InspectCommands)) { [void]$lstInspect.Items.Add($c) }

        $lstFix.Items.Clear()
        foreach ($c in @($guide.FixCommands)) { [void]$lstFix.Items.Add($c) }

        $btnOpenMenu.IsEnabled = -not [string]::IsNullOrWhiteSpace($guide.SettingsUri)
        $btnOpenClassic.IsEnabled = -not [string]::IsNullOrWhiteSpace($guide.ClassicTool)
        $btnCopyInspect.IsEnabled = (@($guide.InspectCommands).Count -gt 0)
        $btnCopyFix.IsEnabled = (@($guide.FixCommands).Count -gt 0)
    }

    $dragHeader.Add_MouseLeftButtonDown({ $wpfForm.DragMove() })
    $btnClose.Add_Click({ $wpfForm.Close() })

    $lstProblems.Add_SelectionChanged({
            if ($lstProblems.SelectedItem) {
                & $refreshGuide $lstProblems.SelectedItem.ToString()
            }
        })

    $btnOpenMenu.Add_Click({
            if ($script:currentGuide -and -not [string]::IsNullOrWhiteSpace($script:currentGuide.SettingsUri)) {
                Start-Process $script:currentGuide.SettingsUri
                Write-NetworkScanOutput -OutputBox $OutputBox -Style 'Success' -Text ("Win11-Menue geoeffnet: {0}" -f $script:currentGuide.SettingsUri)
            }
        })

    $btnOpenClassic.Add_Click({
            if ($script:currentGuide -and -not [string]::IsNullOrWhiteSpace($script:currentGuide.ClassicTool)) {
                Start-Process $script:currentGuide.ClassicTool
                Write-NetworkScanOutput -OutputBox $OutputBox -Style 'Success' -Text ("Klassisches Tool geoeffnet: {0}" -f $script:currentGuide.ClassicTool)
            }
        })

    $btnAdminConsole.Add_Click({
            try {
                $projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
                $cmd = "Set-Location -LiteralPath '{0}'" -f $projectRoot.Replace("'", "''")
                Start-Process -FilePath "powershell.exe" -ArgumentList "-NoExit", "-NoLogo", "-Command", $cmd -Verb RunAs
                Write-NetworkScanOutput -OutputBox $OutputBox -Style 'Success' -Text 'Admin-Konsole geoeffnet.'
            }
            catch {
                Write-NetworkScanOutput -OutputBox $OutputBox -Style 'Warning' -Text ("Admin-Konsole konnte nicht geoeffnet werden: {0}" -f $_.Exception.Message)
            }
        })

    $btnCopyInspect.Add_Click({
            if ($script:currentGuide) {
                $cmds = @($script:currentGuide.InspectCommands)
                if ($cmds.Count -gt 0) {
                    $cmds -join [Environment]::NewLine | Set-Clipboard
                    Write-NetworkScanOutput -OutputBox $OutputBox -Style 'Success' -Text 'Pruefbefehle in Zwischenablage kopiert.'
                }
            }
        })

    $btnCopyFix.Add_Click({
            if ($script:currentGuide) {
                $cmds = @($script:currentGuide.FixCommands)
                if ($cmds.Count -gt 0) {
                    $cmds -join [Environment]::NewLine | Set-Clipboard
                    Write-NetworkScanOutput -OutputBox $OutputBox -Style 'Success' -Text 'Fixbefehle in Zwischenablage kopiert.'
                }
            }
        })

    $btnOpenMenu.IsEnabled = $false
    $btnOpenClassic.IsEnabled = $false
    $btnCopyInspect.IsEnabled = $false
    $btnCopyFix.IsEnabled = $false

    $lstProblems.SelectedIndex = 0
    $wpfForm.ShowDialog() | Out-Null

    return $true
}

function Start-NetworkManualGuide {
    param(
        [System.Windows.Forms.RichTextBox]$outputBox,
        [string]$ProblemType,
        [switch]$UseWindow,
        [switch]$OpenWindowsMenu,
        [switch]$OpenClassicPanel,
        [switch]$CopyCommands
    )

    $diagnostics = @()
    if ($script:lastNetworkDiagnostics) {
        $diagnostics = @($script:lastNetworkDiagnostics)
    }

    if ([string]::IsNullOrWhiteSpace($ProblemType) -and (-not $diagnostics -or $diagnostics.Count -eq 0)) {
        Write-NetworkScanOutput -OutputBox $outputBox -Style 'Warning' -Text 'Keine gespeicherte Diagnose vorhanden. Bitte zuerst den Einstellungs-Scan ausfuehren.'
        return $null
    }

    if (-not [string]::IsNullOrWhiteSpace($ProblemType)) {
        $guide = Get-NetworkManualGuidance -ProblemType $ProblemType -AffectedItem $null
        if (-not $guide) {
            Write-NetworkScanOutput -OutputBox $outputBox -Style 'Warning' -Text ("Unbekannter ProblemType: {0}" -f $ProblemType)
            return $null
        }

        Write-NetworkManualGuidanceReport -OutputBox $outputBox -Diagnostics @([PSCustomObject]@{ ProblemType = $ProblemType })

        if ($OpenWindowsMenu -and -not [string]::IsNullOrWhiteSpace($guide.SettingsUri)) {
            Start-Process $guide.SettingsUri
        }
        if ($OpenClassicPanel -and -not [string]::IsNullOrWhiteSpace($guide.ClassicTool)) {
            Start-Process $guide.ClassicTool
        }
        if ($CopyCommands) {
            $commands = @($guide.InspectCommands) + @($guide.FixCommands)
            if ($commands.Count -gt 0) {
                $commands -join [Environment]::NewLine | Set-Clipboard
                Write-NetworkScanOutput -OutputBox $outputBox -Style 'Success' -Text 'Pruef-/Fix-Befehle wurden in die Zwischenablage kopiert.'
            }
        }

        return $guide
    }

    if ($UseWindow) {
        return Show-NetworkManualGuideWindow -Diagnostics $diagnostics -OutputBox $outputBox
    }

    Write-NetworkManualGuidanceReport -OutputBox $outputBox -Diagnostics $diagnostics

    $topProblem = $diagnostics |
        Sort-Object @{ Expression = { Get-SeverityRank -Severity $_.Severity } }, @{ Expression = { -1 * [int]$_.ConfidenceScore } } |
        Select-Object -First 1
    $topGuide = if ($topProblem) { Get-NetworkManualGuidance -ProblemType $topProblem.ProblemType -AffectedItem $topProblem.AffectedItem } else { $null }

    if ($topGuide) {
        if ($OpenWindowsMenu -and -not [string]::IsNullOrWhiteSpace($topGuide.SettingsUri)) {
            Start-Process $topGuide.SettingsUri
        }
        if ($OpenClassicPanel -and -not [string]::IsNullOrWhiteSpace($topGuide.ClassicTool)) {
            Start-Process $topGuide.ClassicTool
        }
        if ($CopyCommands) {
            $commands = @($topGuide.InspectCommands) + @($topGuide.FixCommands)
            if ($commands.Count -gt 0) {
                $commands -join [Environment]::NewLine | Set-Clipboard
                Write-NetworkScanOutput -OutputBox $outputBox -Style 'Success' -Text 'Pruef-/Fix-Befehle (Top-Problem) wurden in die Zwischenablage kopiert.'
            }
        }
    }

    return $diagnostics
}

function Invoke-NetworkAnalysis {
    param(
        [object[]]$ScanResults,
        [string]$AdapterName = 'Auto'
    )

    $diagnostics = @()

    foreach ($result in @($ScanResults)) {
        if (-not $result) { continue }

        $name = "$($result.Name)"
        $detail = "$($result.Detail)"
        $status = "$($result.Status)"

        if ($name -eq 'NIC-Eventlogs' -and $detail -match 'ID14=(\d+), ID15=(\d+), Total=(\d+), LastEvent=([^,]+), Window=(\d+)h') {
            $event14Count = [int]$Matches[1]
            $event15Count = [int]$Matches[2]
            $flapCount = [int]$Matches[3]
            $lastEventText = "$($Matches[4])"

            if ($flapCount -ge 3) {
                $severity = if ($flapCount -ge 10 -or $status -eq 'Red') { 'Critical' } else { 'Warning' }
                $baseConfidence = 82
                if ($event14Count -gt 0 -and $event15Count -gt 0) {
                    $baseConfidence += 8
                }
                if ([Math]::Abs($event14Count - $event15Count) -le 1) {
                    $baseConfidence += 4
                }
                $confidence = [Math]::Min(99, $baseConfidence + [Math]::Min(5, [int]($flapCount / 3)))
                $description = "Adapter verliert und stellt Verbindung mehrfach her (Link-Flapping). aqnic650 ID14/15 treten getrennt und auswertbar auf."
                $actions = @('Speed/Duplex auf Auto Negotiation setzen', 'LAN-Kabel und Switch-Port pruefen', 'Netzwerktreiber aktualisieren')
                if ($event14Count -gt 0 -and $event15Count -eq 0) {
                    $actions += 'Persistenten Link-Verlust im Switch/PHY-Pfad pruefen'
                }

                $diagnostics += New-DiagnosisResult -AdapterName $AdapterName -ProblemType 'LinkFlap' -Severity $severity -RootCauseDescription $description -RecommendedActions $actions -ConfidenceScore $confidence -RuleId 'RULE-NET-001' -Source $name -Evidence ("$detail LastSeen=$lastEventText")
            }
        }

        if ($name -eq 'Speed/Duplex & Auto-Negotiation' -and $status -ne 'Green' -and $detail -match '^Manuelle Link-Konfiguration erkannt') {
            $diagnostics += New-DiagnosisResult -AdapterName $AdapterName -ProblemType 'SpeedNegotiation' -Severity 'Warning' -RootCauseDescription 'Speed/Duplex ist manuell gesetzt statt Auto-Negotiation.' -RecommendedActions @('Auf Auto Negotiation zurueckstellen', 'Nach Umstellung erneuten Stabilitaetstest ausfuehren') -ConfidenceScore 78 -RuleId 'RULE-NET-002' -Source $name -Evidence $detail
        }

        if ($name -eq 'NIC-Energieverwaltung' -and $status -ne 'Green') {
            $severity = if ($status -eq 'Red') { 'Critical' } else { 'Warning' }
            $diagnostics += New-DiagnosisResult -AdapterName $AdapterName -ProblemType 'PowerSettings' -Severity $severity -RootCauseDescription 'NIC-Energieverwaltung kann die Verbindung negativ beeinflussen.' -RecommendedActions @('Adapter-Energiesparoptionen pruefen', '"Computer kann Geraet ausschalten" testweise deaktivieren') -ConfidenceScore 70 -RuleId 'RULE-NET-003' -Source $name -Evidence $detail
        }

        if ($name -eq 'Fast Startup / Hibernation' -and $status -ne 'Green') {
            $diagnostics += New-DiagnosisResult -AdapterName $AdapterName -ProblemType 'FastStartupInfluence' -Severity 'Info' -RootCauseDescription 'Fast Startup/Hibernation kann nach dem Resume NIC-Probleme verstaerken.' -RecommendedActions @('Fast Startup testweise deaktivieren', 'Kaltstart statt Schnellstart durchfuehren') -ConfidenceScore 62 -RuleId 'RULE-NET-004' -Source $name -Evidence $detail
        }

        if ($name -eq 'Netzwerkadapter-Treiber' -and $detail -match 'Aeltere Treiber erkannt') {
            $diagnostics += New-DiagnosisResult -AdapterName $AdapterName -ProblemType 'OutdatedDriver' -Severity 'Warning' -RootCauseDescription 'Treiber ist aelter als empfohlen und kann zu Instabilitaet fuehren.' -RecommendedActions @('Treiber ueber Herstellerseite aktualisieren', 'Nach Update Eventlog auf Wiederholung pruefen') -ConfidenceScore 82 -RuleId 'RULE-NET-005' -Source $name -Evidence $detail
        }

        if ($name -eq 'MTU / Jumbo Frames' -and $status -ne 'Green') {
            $severity = if ($status -eq 'Red') { 'Critical' } else { 'Warning' }
            $diagnostics += New-DiagnosisResult -AdapterName $AdapterName -ProblemType 'MtuMismatch' -Severity $severity -RootCauseDescription 'MTU/Jumbo-Frame-Konfiguration weicht vom erwarteten Netzprofil ab.' -RecommendedActions @('MTU auf Netzstandard abstimmen (typisch 1500)', 'End-to-End-Jumbo-Frame-Konfiguration pruefen') -ConfidenceScore 74 -RuleId 'RULE-NET-006' -Source $name -Evidence $detail
        }

        if ($name -eq 'DNS Resolver' -and $status -ne 'Green') {
            $severity = if ($status -eq 'Red') { 'Critical' } else { 'Warning' }
            $diagnostics += New-DiagnosisResult -AdapterName $AdapterName -ProblemType 'DnsResolverIssue' -Severity $severity -RootCauseDescription 'DNS-Konfiguration ist unvollstaendig oder fehlerhaft.' -RecommendedActions @('Gueltige DNS-Server konfigurieren', 'Resolver-Erreichbarkeit pruefen') -ConfidenceScore 84 -RuleId 'RULE-NET-007' -Source $name -Evidence $detail
        }

        if ($name -eq 'Route / Interface-Metrik' -and $status -ne 'Green') {
            $severity = if ($status -eq 'Red') { 'Critical' } else { 'Warning' }
            $diagnostics += New-DiagnosisResult -AdapterName $AdapterName -ProblemType 'RouteMetricConflict' -Severity $severity -RootCauseDescription 'Mehrdeutige oder fehlerhafte Default-Route-Priorisierung erkannt.' -RecommendedActions @('InterfaceMetric/RouteMetric eindeutig setzen', 'Mehrfache aktive Gateways bereinigen') -ConfidenceScore 76 -RuleId 'RULE-NET-008' -Source $name -Evidence $detail
        }

        if ($name -eq 'Netzwerkdienste-Status' -and $status -ne 'Green') {
            $severity = if ($status -eq 'Red') { 'Critical' } else { 'Warning' }

            $stoppedServices = @([regex]::Matches($detail, '([A-Za-z0-9_]+)=Stopped') | ForEach-Object { $_.Groups[1].Value } | Select-Object -Unique)
            if ($stoppedServices.Count -gt 0) {
                foreach ($svc in $stoppedServices) {
                    $diagnostics += New-DiagnosisResult -AdapterName $AdapterName -ProblemType 'ServiceStateIssue' -Severity $severity -RootCauseDescription "Netzwerkdienst $svc ist nicht im erwarteten Zustand (Stopped)." -RecommendedActions @("Dienst $svc starten", 'Starttyp auf Automatic/AutomaticDelayedStart pruefen') -ConfidenceScore 92 -RuleId 'RULE-NET-009' -Source $name -Evidence $detail -AffectedItem $svc
                }
            }
            else {
                $diagnostics += New-DiagnosisResult -AdapterName $AdapterName -ProblemType 'ServiceStateIssue' -Severity $severity -RootCauseDescription 'Ein oder mehrere relevante Netzwerkdienste sind nicht im erwarteten Zustand.' -RecommendedActions @('Betroffene Dienste starten', 'Starttyp auf Automatic/AutomaticDelayedStart pruefen') -ConfidenceScore 92 -RuleId 'RULE-NET-009' -Source $name -Evidence $detail
            }
        }

        if ($name -eq 'Proxy / WinHTTP Konsistenz' -and $status -ne 'Green') {
            $severity = if ($status -eq 'Red') { 'Critical' } else { 'Warning' }
            $diagnostics += New-DiagnosisResult -AdapterName $AdapterName -ProblemType 'ProxyMismatch' -Severity $severity -RootCauseDescription 'Proxy-Konfiguration zwischen User-Kontext und WinHTTP ist inkonsistent.' -RecommendedActions @('Proxy-Strategie vereinheitlichen', 'netsh winhttp import proxy source=ie testen') -ConfidenceScore 72 -RuleId 'RULE-NET-010' -Source $name -Evidence $detail
        }

        if ($name -eq 'IP / DHCP / DNS' -and $status -ne 'Green') {
            $severity = if ($status -eq 'Red') { 'Critical' } else { 'Warning' }
            $diagnostics += New-DiagnosisResult -AdapterName $AdapterName -ProblemType 'IpConfigIssue' -Severity $severity -RootCauseDescription 'IP/Gateway/DHCP-Konfiguration ist auffaellig.' -RecommendedActions @('DHCP-Lease erneuern', 'Gateway und DNS-Konfiguration validieren') -ConfidenceScore 80 -RuleId 'RULE-NET-011' -Source $name -Evidence $detail
        }
    }

    return @($diagnostics)
}

function Get-NetworkRecommendations {
    param(
        [object[]]$DiagnosisResults
    )

    $recommendations = @()

    foreach ($diag in @($DiagnosisResults)) {
        switch ($diag.ProblemType) {
            'LinkFlap' {
                $recommendations += New-RecommendationItem -Priority 1 -Action 'Setze Speed & Duplex auf Auto Negotiation' -Description 'Erlaubt dem Adapter, Geschwindigkeit automatisch auszuhandeln.' -Command 'Set-NetAdapterAdvancedProperty -Name "Ethernet" -DisplayName "Speed & Duplex" -DisplayValue "Auto Negotiation"' -ProblemType $diag.ProblemType -Severity $diag.Severity
                $recommendations += New-RecommendationItem -Priority 1 -Action 'Teste LAN-Kabel und Switch-Port' -Description 'Physikalische Ursachen sind haeufigster Link-Flap-Ausloeser.' -Command $null -ProblemType $diag.ProblemType -Severity $diag.Severity
            }
            'OutdatedDriver' {
                $recommendations += New-RecommendationItem -Priority 1 -Action 'Aktualisiere Netzwerktreiber auf aktuelle Version' -Description 'Treiber vom Mainboard-/NIC-Hersteller verwenden.' -Command $null -ProblemType $diag.ProblemType -Severity $diag.Severity
            }
            'PowerSettings' {
                $recommendations += New-RecommendationItem -Priority 2 -Action 'Deaktiviere NIC-Energiesparen testweise' -Description 'Kann spontane Verbindungsabbrueche reduzieren.' -Command 'Set-NetAdapterPowerManagement -Name "Ethernet" -AllowComputerToTurnOffDevice Disabled' -ProblemType $diag.ProblemType -Severity $diag.Severity
            }
            'ServiceStateIssue' {
                if (-not [string]::IsNullOrWhiteSpace($diag.AffectedItem)) {
                    $svc = $diag.AffectedItem
                    $recommendations += New-RecommendationItem -Priority 1 -Action ("Starte Netzwerkdienst $svc") -Description ("Dienst $svc muss fuer stabile Netzerkennung laufen.") -Command ("Start-Service $svc") -ProblemType $diag.ProblemType -Severity $diag.Severity
                }
                else {
                    $recommendations += New-RecommendationItem -Priority 1 -Action 'Starte kritische Netzwerkdienste' -Description 'Dhcp/Dnscache/NlaSvc muessen fuer stabile Netzerkennung laufen.' -Command 'Start-Service Dhcp,Dnscache,NlaSvc' -ProblemType $diag.ProblemType -Severity $diag.Severity
                }
            }
            'DnsResolverIssue' {
                $recommendations += New-RecommendationItem -Priority 1 -Action 'Setze gueltige DNS-Resolver' -Description 'Fehlende/ungueltige DNS-Eintraege fuehren zu Namensaufloesungsfehlern.' -Command 'Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses 1.1.1.1,8.8.8.8' -ProblemType $diag.ProblemType -Severity $diag.Severity
            }
            'RouteMetricConflict' {
                $recommendations += New-RecommendationItem -Priority 2 -Action 'Bereinige Default-Route-Prioritaet' -Description 'Verhindert instabile Gateway-Auswahl bei mehreren Uplinks.' -Command 'Set-NetIPInterface -InterfaceAlias "Ethernet" -InterfaceMetric 25' -ProblemType $diag.ProblemType -Severity $diag.Severity
            }
            'ProxyMismatch' {
                $recommendations += New-RecommendationItem -Priority 2 -Action 'Proxy zwischen IE/User und WinHTTP synchronisieren' -Description 'Uneinheitliche Proxy-Settings koennen Tool- und Servicezugriff stoeren.' -Command 'netsh winhttp import proxy source=ie' -ProblemType $diag.ProblemType -Severity $diag.Severity
            }
            'MtuMismatch' {
                $recommendations += New-RecommendationItem -Priority 2 -Action 'Pruefe MTU/Jumbo-Frame-Konfiguration' -Description 'MTU-Werte muessen Ende-zu-Ende konsistent sein.' -Command $null -ProblemType $diag.ProblemType -Severity $diag.Severity
            }
            'FastStartupInfluence' {
                $recommendations += New-RecommendationItem -Priority 3 -Action 'Fast Startup testweise deaktivieren' -Description 'Kann Resume-bezogene NIC-Probleme vermeiden.' -Command 'powercfg /h off' -ProblemType $diag.ProblemType -Severity $diag.Severity
            }
            'IpConfigIssue' {
                $recommendations += New-RecommendationItem -Priority 1 -Action 'Erneuere DHCP-Lease und DNS-Cache' -Description 'Setzt grundlegende IP-Parameter neu.' -Command 'ipconfig /release; ipconfig /renew; ipconfig /flushdns' -ProblemType $diag.ProblemType -Severity $diag.Severity
            }
        }
    }

    if (-not $recommendations) {
        return @()
    }

    $deduped = $recommendations |
        Sort-Object Priority, Action |
        Group-Object Action |
        ForEach-Object { $_.Group | Select-Object -First 1 }

    return @($deduped | Sort-Object Priority, @{ Expression = { Get-SeverityRank -Severity $_.Severity } }, Action)
}

function Write-NetworkAnalysisReport {
    param(
        [System.Windows.Forms.RichTextBox]$OutputBox,
        [object[]]$Diagnostics,
        [object[]]$Recommendations
    )

    $diagnostics = @($Diagnostics)
    $recommendations = @($Recommendations)

    Write-NetworkScanOutput -OutputBox $OutputBox -Text ""
    Write-NetworkScanOutput -OutputBox $OutputBox -Style 'Heading' -Text 'Diagnose-Analyse'

    if (-not $diagnostics -or $diagnostics.Count -eq 0) {
        Write-NetworkScanOutput -OutputBox $OutputBox -Style 'Success' -Text '[INFO] Keine konkreten Problemregeln ausgelost.'
        return
    }

    foreach ($diag in ($diagnostics | Sort-Object @{ Expression = { Get-SeverityRank -Severity $_.Severity } }, @{ Expression = { -1 * [int]$_.ConfidenceScore } })) {
        $style = switch ($diag.Severity) {
            'Critical' { 'Error' }
            'Warning'  { 'Warning' }
            default    { 'Default' }
        }

        Write-NetworkScanOutput -OutputBox $OutputBox -Style $style -Text ("[{0}] {1} (Confidence: {2}%)" -f $diag.Severity.ToUpperInvariant(), $diag.ProblemType, $diag.ConfidenceScore)
        Write-NetworkScanOutput -OutputBox $OutputBox -Style 'Default' -Text ("  Ursache: {0}" -f $diag.RootCauseDescription)
        Write-NetworkScanOutput -OutputBox $OutputBox -Style 'Muted' -Text ("  Evidence: {0} | Rule: {1}" -f $diag.Evidence, $diag.RuleId)
    }

    Write-NetworkScanOutput -OutputBox $OutputBox -Text ""
    Write-NetworkScanOutput -OutputBox $OutputBox -Style 'Heading' -Text 'Empfohlene Massnahmen'

    if (-not $recommendations -or $recommendations.Count -eq 0) {
        Write-NetworkScanOutput -OutputBox $OutputBox -Style 'Muted' -Text '- Keine zusaetzlichen Aktionen erforderlich.'
        return
    }

    foreach ($rec in $recommendations) {
        Write-NetworkScanOutput -OutputBox $OutputBox -Style 'Default' -Text ("[{0}] {1}" -f $rec.Priority, $rec.Action)
        Write-NetworkScanOutput -OutputBox $OutputBox -Style 'Muted' -Text ("  {0}" -f $rec.Description)
        if (-not [string]::IsNullOrWhiteSpace($rec.Command)) {
            Write-NetworkScanOutput -OutputBox $OutputBox -Style 'Muted' -Text ("  CMD: {0}" -f $rec.Command)
        }
    }
}

function Start-NetworkSettingsScan {
    param(
        [System.Windows.Forms.RichTextBox]$outputBox,
        $progressBar
    )

    Write-ToolLog -ToolName "NetworkTools" -Message "Netzwerk-Einstellungs-Scan gestartet" -OutputBox $outputBox -Style 'Action' -Level "Information" -SaveToDatabase

    if ($outputBox) {
        $outputBox.Clear()
    }

    Write-NetworkScanOutput -OutputBox $outputBox -Style 'Action' -Text "Starte Netzwerk-Einstellungs-Scan..."
    Write-NetworkScanOutput -OutputBox $outputBox -Style 'Muted' -Text "Geprueft werden: Fast Startup, NIC-Energieverwaltung, Speed/Duplex, Treiber, Eventlogs, IP/DHCP/DNS, MTU, DNS-Resolver, Route-Metrik, Dienste, Proxy."

    $isAdmin = Test-NetworkScanAdmin
    if (-not $isAdmin) {
        Write-NetworkScanOutput -OutputBox $outputBox -Style 'Warning' -Text "Hinweis: Scan laeuft ohne Administratorrechte. Einzelne Checks koennen eingeschraenkt sein."
    }

    $results = @(
        Get-FastStartupScanResult
        Get-NicPowerManagementScanResult
        Get-LinkSettingsScanResult
        Get-NetworkDriverScanResult
        Get-NetworkEventScanResult -Hours 24
        Get-NetworkIpScanResult
        Get-NetworkMtuScanResult
        Get-DnsResolverScanResult
        Get-RouteMetricScanResult
        Get-NetworkServiceStateScanResult
        Get-ProxyMismatchScanResult
    )

    Write-NetworkScanOutput -OutputBox $outputBox -Text ""
    Write-NetworkScanOutput -OutputBox $outputBox -Style 'Heading' -Text "Ergebnisse"

    foreach ($result in $results) {
        $style = switch ($result.Status) {
            'Green' { 'Success' }
            'Red' { 'Error' }
            default { 'Warning' }
        }

        Write-NetworkScanOutput -OutputBox $outputBox -Style $style -Text ("[{0}] {1}" -f $result.Status.ToUpperInvariant(), $result.Name)
        Write-NetworkScanOutput -OutputBox $outputBox -Style 'Default' -Text ("  Detail: {0}" -f $result.Detail)
        Write-NetworkScanOutput -OutputBox $outputBox -Style 'Muted' -Text ("  Empfehlung: {0}" -f $result.Recommendation)
        Write-ToolLog -ToolName "NetworkTools" -Message ("{0}: {1}" -f $result.Name, $result.Detail) -OutputBox $null -Level "Information" -SaveToDatabase
    }

    $diagnostics = Invoke-NetworkAnalysis -ScanResults $results -AdapterName 'Auto'
    $recommendations = Get-NetworkRecommendations -DiagnosisResults $diagnostics
    $script:lastNetworkScanResults = @($results)
    $script:lastNetworkDiagnostics = @($diagnostics)
    $script:lastNetworkRecommendations = @($recommendations)

    Write-NetworkAnalysisReport -OutputBox $outputBox -Diagnostics $diagnostics -Recommendations $recommendations

    if (@($diagnostics).Count -gt 0) {
        Write-NetworkScanOutput -OutputBox $outputBox -Text ''
        Write-NetworkScanOutput -OutputBox $outputBox -Style 'Muted' -Text 'Tipp: Fuer manuelle Schritt-fuer-Schritt-Hilfe nutzen Sie den Button "Manuelle Anleitung".'
    }

    foreach ($diag in @($diagnostics)) {
        Write-ToolLog -ToolName "NetworkTools" -Message ("Diagnosis {0}/{1}: {2}" -f $diag.Severity, $diag.ProblemType, $diag.Evidence) -OutputBox $null -Level "Information" -SaveToDatabase
    }

    $priority = @{ Red = 0; Yellow = 1; Green = 2 }
    $topFindings = $results |
        Sort-Object { $priority[$_.Status] }, Name |
        Select-Object -First 3

    Write-NetworkScanOutput -OutputBox $outputBox -Text ""
    Write-NetworkScanOutput -OutputBox $outputBox -Style 'Heading' -Text "Top 3 Prioritaeten"
    foreach ($finding in $topFindings) {
        Write-NetworkScanOutput -OutputBox $outputBox -Style 'Default' -Text ("- [{0}] {1}" -f $finding.Status, $finding.Name)
    }

    $overall = if ($results.Status -contains 'Red') { 'Red' } elseif ($results.Status -contains 'Yellow') { 'Yellow' } else { 'Green' }
    $overallMessage = "Netzwerk-Einstellungs-Scan abgeschlossen: Gesamtstatus $overall"

    $finalStyle = if ($overall -eq 'Green') { 'Success' } elseif ($overall -eq 'Red') { 'Error' } else { 'Warning' }
    Write-NetworkScanOutput -OutputBox $outputBox -Text ""
    Write-NetworkScanOutput -OutputBox $outputBox -Style $finalStyle -Text $overallMessage

    Write-ToolLog -ToolName "NetworkTools" -Message $overallMessage -OutputBox $null -Level "Information" -SaveToDatabase

    return [PSCustomObject]@{
        Overall         = $overall
        Checks          = $results
        Diagnostics     = @($diagnostics)
        Recommendations = @($recommendations)
    }
}

# Export functions
Export-ModuleMember -Function Start-PingTest, Restart-NetworkAdapter, Start-NetworkSettingsScan, Start-NetworkManualGuide

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

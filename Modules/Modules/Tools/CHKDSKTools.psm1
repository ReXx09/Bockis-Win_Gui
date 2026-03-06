# Import required modules
Import-Module "$PSScriptRoot\..\Core\Core.psm1" -Force -Global
Import-Module "$PSScriptRoot\..\Core\ProgressBarTools.psm1" -Force -Global
Import-Module "$PSScriptRoot\..\Core\TextStyle.psm1" -Force -Global

# Function to run CHKDSK
function Start-CHKDSK {
    param (
        [System.Windows.Forms.RichTextBox]$outputBox,
        [System.Windows.Forms.ProgressBar]$progressBar,
        [System.Windows.Forms.Form]$mainform
    )

    Clear-Host
    
    # Stelle sicher, dass die ProgressBar initialisiert ist
    if ($progressBar) {
        Initialize-ProgressComponents -ProgressBar $progressBar -StatusLabel $null
    }
    
    # In Log-Datei und Datenbank schreiben, dass CHKDSK gestartet wird
    Write-ToolLog -ToolName "CHKDSK" -Message "CHKDSK wird gestartet" -OutputBox $outputBox -Style 'Action' -Level "Information" -SaveToDatabase
    
    # Rahmen und Systeminformationen erstellen
    #$computerName = $env:COMPUTERNAME
    #$userName = $env:USERNAME
    #$osInfo = (Get-CimInstance -ClassName Win32_OperatingSystem).Caption
    #$dateTime = Get-Date -Format "dd.MM.yyyy HH:mm:ss"
    #$width = 80
        
    # Rahmen oben
    Write-Host "╔══════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-ColoredCenteredText                             "CHKDSK"                                         
    Write-Host "╚══════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Green
    Write-Host
    Write-Host '   .d8888b.  888    888 888    d8P  8888888b.   .d8888b.  888    d8P ' -ForegroundColor Cyan
    Write-Host '  d88P  Y88b 888    888 888   d8P   888  "Y88b d88P  Y88b 888   d8P  ' -ForegroundColor Blue
    Write-Host '  888    888 888    888 888  d8P    888    888 Y88b.      888  d8P    ' -ForegroundColor Cyan
    Write-Host '  888        8888888888 888d88K     888    888  "Y888b.   888d88K     ' -ForegroundColor Blue
    Write-Host '  888        888    888 8888888b    888    888     "Y88b. 8888888b    ' -ForegroundColor Cyan
    Write-Host '  888    888 888    888 888  Y88b   888    888       "888 888  Y88b   ' -ForegroundColor Blue
    Write-Host '  Y88b  d88P 888    888 888   Y88b  888  .d88P Y88b  d88P 888   Y88b  ' -ForegroundColor Cyan
    Write-Host '   "Y8888P"  888    888 888    Y88b 8888888P"   "Y8888P"  888    Y88b' -ForegroundColor Blue
    Write-Host
    # Rahmen für Systeminformationen
    Write-Host "╔══════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-ColoredCenteredText                 "INFORMATIONEN"                                                     
    Write-Host "╠══════════════════════════════════════════════════════════════════════════════╣" -ForegroundColor Green
    # Systeminformationen
    Write-Host "║                                                                              ║" -ForegroundColor Green
    Write-Host " ├─ Datenträgerprüfung mit CHKDSK:                                                "  -ForegroundColor Yellow                 
    Write-Host " ├─ Sucht nach Dateisystemfehlern und fehlerhaften Sektoren auf der Festplatte.   "  -ForegroundColor Yellow                                    
    Write-Host " ├─ Kann Probleme beheben, die zu Datenverlust oder Systemfehlern führen.         "  -ForegroundColor Yellow                                    
    Write-Host " └─ Empfohlen bei Abstürzen, langsamen Zugriffen oder nach Stromausfällen.        "  -ForegroundColor Yellow                                  
    Write-Host "║                                                                              ║" -ForegroundColor Green

    Write-Host "╠══════════════════════════════════════════════════════════════════════════════╣" -ForegroundColor Green
    Write-ColoredCenteredText       "CHKDSK Laufwerksauswahl wurde geöffnet..."
    Write-Host "╚══════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Green    # 1 Sekunde warten vor dem Start
    Start-Sleep -Seconds 1
    $outputBox.Clear()
    Write-Host
    Write-Host "     [>] Ein Dialog-Fenster für die Auswahl der Laufwerke wird geöffnet...... " -ForegroundColor $secondaryColor
    Write-Host
    Write-Host "     [i] Bitte wählen Sie die zu prüfenden Laufwerke und Optionen aus... " -ForegroundColor Blue
    Write-Host
    Write-Host ("  " + ("═" * 66)) -ForegroundColor Cyan
    Write-Host
        
    # Verfügbare Laufwerke ermitteln
    $drives = Get-WmiObject Win32_LogicalDisk | 
    Where-Object { $_.DriveType -eq 3 -or $_.DriveType -eq 2 } | 
    Select-Object -ExpandProperty DeviceID    # Laufwerksinformationen anzeigen
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Action'
    $outputBox.AppendText("`r`n  " + ("═" * 66) + "`r`n")
    $outputBox.AppendText("  Verfügbare Laufwerkeübersicht`r`n")
    $outputBox.AppendText("  " + ("═" * 66) + "`r`n`r`n")
    
    # Tabellenkopf erstellen
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Action'
    $lw = "Laufwerk".PadRight(15)
    $name = "Bezeichnung".PadRight(20)
    $total = "Größe".PadRight(15)
    $free = "Freier Speicher".PadRight(20)
    $used = "Belegung".PadRight(15)
    $outputBox.AppendText("    $lw$name$total$free$used`r`n")
    
    # Trennlinie
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Muted'
    $outputBox.AppendText("    " + "".PadRight(85, '─') + "`r`n")
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Default'
    # Laufwerksdaten in Tabellenform anzeigen
    foreach ($drive in $drives) {
        $driveInfo = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='$drive'"
        $totalSpace = [Math]::Round($driveInfo.Size / 1GB, 2)
        $freeSpace = [Math]::Round($driveInfo.FreeSpace / 1GB, 2)
        $usedPercent = [Math]::Round(100 - (($driveInfo.FreeSpace / $driveInfo.Size) * 100), 1)
        $isSystemDrive = $drive -eq $env:SystemDrive
        
        # Laufwerksname formatieren
        $driveName = $drive
        if ($isSystemDrive) {
            $driveName += " (System)"
        }
        $driveCol = $driveName.PadRight(15)
        
        # Laufwerksbezeichnung formatieren
        $labelName = if ($driveInfo.VolumeName) { $driveInfo.VolumeName } else { "<Keine>" }
        $labelCol = $labelName.PadRight(20)
        
        # Größeninformationen formatieren
        $totalCol = "$totalSpace GB".PadRight(15)
        $freeCol = "$freeSpace GB".PadRight(20)
        
        # Zeile ausgeben
        $outputBox.AppendText("    $driveCol$labelCol$totalCol$freeCol")
        
        # Speichernutzung mit Farbe je nach Füllstand anzeigen
        if ($usedPercent -gt 90) {
            Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Error'
            $outputBox.AppendText("$usedPercent% (Kritisch)")
        } 
        elseif ($usedPercent -gt 75) {
            Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Warning'
            $outputBox.AppendText("$usedPercent% (Warnung)")
        }
        else {
            Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Success'
            $outputBox.AppendText("$usedPercent% (OK)")
        }
        
        Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Default'
        $outputBox.AppendText("`r`n")
    }
    
    $outputBox.AppendText("`r`n")
    
    # Kurze Information zum weiteren Vorgehen
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Action'
    $outputBox.AppendText("  [►] Bitte wählen Sie die zu prüfenden Laufwerke und Optionen im Dialog-Fenster aus...`r`n")
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Action'
    $outputBox.AppendText("  " + ("═" * 66) + "`r`n")

    # Form für die Laufwerksauswahl erstellen
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "CHKDSK - Laufwerksauswahl"
    $form.Size = New-Object System.Drawing.Size(500, 560)
    $form.StartPosition = "CenterScreen"
    $form.FormBorderStyle = "FixedDialog"
    $form.MaximizeBox = $false

    $form.StartPosition = [System.Windows.Forms.FormStartPosition]::Manual
    if ($null -ne $mainform) {
        $form.Location = New-Object System.Drawing.Point(
            ($mainform.Location.X + $mainform.Width + 10),
            $mainform.Location.Y
        )
    }

    # Label erstellen
    $label = New-Object System.Windows.Forms.Label
    $label.Location = New-Object System.Drawing.Point(10, 10)
    $label.Size = New-Object System.Drawing.Size(300, 20)
    $label.Text = "Bitte wählen Sie die zu prüfenden Laufwerke aus:"
    $form.Controls.Add($label)

    # CheckedListBox für Laufwerksauswahl erstellen
    $checkedListBox = New-Object System.Windows.Forms.CheckedListBox
    $checkedListBox.Location = New-Object System.Drawing.Point(10, 40)
    $checkedListBox.Size = New-Object System.Drawing.Size(460, 200)
    $checkedListBox.CheckOnClick = $true

    # Laufwerke zur Liste hinzufügen
    foreach ($drive in $drives) {
        $driveInfo = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='$drive'"
        $driveLabel = if ($driveInfo.VolumeName) { "$drive ($($driveInfo.VolumeName))" } else { $drive }
        $freeSpace = [Math]::Round($driveInfo.FreeSpace / 1GB, 2)
        $totalSpace = [Math]::Round($driveInfo.Size / 1GB, 2)
        $isSystemDrive = $drive -eq $env:SystemDrive
        
        # Füge (Systemlaufwerk) Hinweis hinzu
        if ($isSystemDrive) {
            $checkedListBox.Items.Add("$driveLabel - $freeSpace GB frei von $totalSpace GB (Systemlaufwerk)")
        }
        else {
            $checkedListBox.Items.Add("$driveLabel - $freeSpace GB frei von $totalSpace GB")
        }
    }
    $form.Controls.Add($checkedListBox)

    # "Alle auswählen" Checkbox
    $checkBoxAll = New-Object System.Windows.Forms.CheckBox
    $checkBoxAll.Location = New-Object System.Drawing.Point(10, 250)
    $checkBoxAll.Size = New-Object System.Drawing.Size(150, 20)
    $checkBoxAll.Text = "Alle auswählen"
    $checkBoxAll.Add_Click({
            for ($i = 0; $i -lt $checkedListBox.Items.Count; $i++) {
                $checkedListBox.SetItemChecked($i, $checkBoxAll.Checked)
            }
        })
    $form.Controls.Add($checkBoxAll)

    # Auto-Bestätigung für Laufwerke, die in Benutzung sind
    $checkBoxAutoConfirmBusy = New-Object System.Windows.Forms.CheckBox
    $checkBoxAutoConfirmBusy.Location = New-Object System.Drawing.Point(180, 250)
    $checkBoxAutoConfirmBusy.Size = New-Object System.Drawing.Size(290, 20)
    $checkBoxAutoConfirmBusy.Text = "Laufwerk-Freigabe automatisch bestätigen (J/N)"
    $checkBoxAutoConfirmBusy.Checked = $true
    $form.Controls.Add($checkBoxAutoConfirmBusy)

    # GroupBox für CHKDSK-Optionen
    $optionsGroupBox = New-Object System.Windows.Forms.GroupBox
    $optionsGroupBox.Location = New-Object System.Drawing.Point(10, 280)
    $optionsGroupBox.Size = New-Object System.Drawing.Size(460, 130)
    $optionsGroupBox.Text = "CHKDSK-Optionen"
    $form.Controls.Add($optionsGroupBox)

    # Checkbox für /f (Fehler beheben)
    $checkBoxFixErrors = New-Object System.Windows.Forms.CheckBox
    $checkBoxFixErrors.Location = New-Object System.Drawing.Point(10, 20)
    $checkBoxFixErrors.Size = New-Object System.Drawing.Size(440, 20)
    $checkBoxFixErrors.Text = "Fehler auf dem Laufwerk beheben (/f)"
    $checkBoxFixErrors.Checked = $true
    $optionsGroupBox.Controls.Add($checkBoxFixErrors)

    # Checkbox für /r (Beschädigte Sektoren finden und wiederherstellen)
    $checkBoxScanSectors = New-Object System.Windows.Forms.CheckBox
    $checkBoxScanSectors.Location = New-Object System.Drawing.Point(10, 45)
    $checkBoxScanSectors.Size = New-Object System.Drawing.Size(440, 20)
    $checkBoxScanSectors.Text = "Beschädigte Sektoren suchen und wiederherstellen (/r) - kann sehr lange dauern"
    $optionsGroupBox.Controls.Add($checkBoxScanSectors)

    # Checkbox für /i (Nicht so gründliche Indexprüfung)
    $checkBoxLessIntensiveIndex = New-Object System.Windows.Forms.CheckBox
    $checkBoxLessIntensiveIndex.Location = New-Object System.Drawing.Point(10, 70)
    $checkBoxLessIntensiveIndex.Size = New-Object System.Drawing.Size(440, 20)
    $checkBoxLessIntensiveIndex.Text = "Indexeinträge weniger intensiv prüfen (/i) - schneller"
    $optionsGroupBox.Controls.Add($checkBoxLessIntensiveIndex)

    # Checkbox für /x (Laufwerk bei Bedarf auswerfen)
    $checkBoxForceDisMount = New-Object System.Windows.Forms.CheckBox
    $checkBoxForceDisMount.Location = New-Object System.Drawing.Point(10, 95)
    $checkBoxForceDisMount.Size = New-Object System.Drawing.Size(440, 20)
    $checkBoxForceDisMount.Text = "Laufwerk bei Bedarf auswerfen (/x) - für gründlichere Prüfung"
    $optionsGroupBox.Controls.Add($checkBoxForceDisMount)

    # Neue GroupBox für Neustartoptionen
    $restartGroupBox = New-Object System.Windows.Forms.GroupBox
    $restartGroupBox.Location = New-Object System.Drawing.Point(10, 420)
    $restartGroupBox.Size = New-Object System.Drawing.Size(460, 60)
    $restartGroupBox.Text = "Neustartoptionen (bei allen Laufwerken)"
    $form.Controls.Add($restartGroupBox)

    # Checkbox für Auto-Neustart
    $checkBoxAutoRestart = New-Object System.Windows.Forms.CheckBox
    $checkBoxAutoRestart.Location = New-Object System.Drawing.Point(10, 20)
    $checkBoxAutoRestart.Size = New-Object System.Drawing.Size(200, 20)
    $checkBoxAutoRestart.Text = "Automatisch neustarten"
    $restartGroupBox.Controls.Add($checkBoxAutoRestart)

    # NumericUpDown für Neustart-Timer
    $numRestartTimer = New-Object System.Windows.Forms.NumericUpDown
    $numRestartTimer.Location = New-Object System.Drawing.Point(220, 20)
    $numRestartTimer.Size = New-Object System.Drawing.Size(60, 20)
    $numRestartTimer.Minimum = 0
    $numRestartTimer.Maximum = 600
    $numRestartTimer.Value = 30
    $numRestartTimer.Enabled = $false  # Deaktiviert bis Auto-Neustart ausgewählt wird
    $restartGroupBox.Controls.Add($numRestartTimer)

    $labelSeconds = New-Object System.Windows.Forms.Label
    $labelSeconds.Location = New-Object System.Drawing.Point(290, 22)
    $labelSeconds.Size = New-Object System.Drawing.Size(100, 20)
    $labelSeconds.Text = "Sekunden"
    $restartGroupBox.Controls.Add($labelSeconds)

    # Event für die Aktivierung/Deaktivierung des Timers
    $checkBoxAutoRestart.Add_CheckedChanged({
            $numRestartTimer.Enabled = $checkBoxAutoRestart.Checked
        })

    # OK-Button
    $okButton = New-Object System.Windows.Forms.Button
    $okButton.Location = New-Object System.Drawing.Point(150, 490)
    $okButton.Size = New-Object System.Drawing.Size(140, 30)
    $okButton.Text = "Prüfung starten"
    $okButton.BackColor = [System.Drawing.Color]::LightGreen
    $okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $form.Controls.Add($okButton)
    $form.AcceptButton = $okButton

    # Abbrechen-Button
    $cancelButton = New-Object System.Windows.Forms.Button
    $cancelButton.Location = New-Object System.Drawing.Point(300, 490)
    $cancelButton.Size = New-Object System.Drawing.Size(140, 30)
    $cancelButton.Text = "Abbrechen"
    $cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $form.Controls.Add($cancelButton)
    $form.CancelButton = $cancelButton

    # Form anzeigen und Ergebnis auswerten
    $result = $form.ShowDialog()
    $outputBox.Clear()
    
    if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
        $selectedDrives = @()
        for ($i = 0; $i -lt $checkedListBox.Items.Count; $i++) {
            if ($checkedListBox.GetItemChecked($i)) {
                $selectedDrives += $drives[$i]
            }
        }        if ($selectedDrives.Count -eq 0) {
            $outputBox.AppendText("Keine Laufwerke ausgewählt. CHKDSK abgebrochen.`r`n")
            return
        }
        
        # CHKDSK-Parameter aufbauen
        $chkdskParams = ""
        if ($checkBoxFixErrors.Checked) { $chkdskParams += " /f" }
        if ($checkBoxScanSectors.Checked) { $chkdskParams += " /r" }
        if ($checkBoxLessIntensiveIndex.Checked) { $chkdskParams += " /i" }
        if ($checkBoxForceDisMount.Checked) { $chkdskParams += " /x" }

        # Kurze Zusammenfassung der Parameter anzeigen
        Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Action'
        $outputBox.AppendText("`r`n  " + ("═" * 66) + "`r`n")
        $outputBox.AppendText("  CHKDSK – Durchführung`r`n")
        $outputBox.AppendText("  " + ("═" * 66) + "`r`n`r`n")
        Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Default'
        $outputBox.AppendText("  [►] Parameter: chkdsk$chkdskParams`r`n")
        if ($checkBoxScanSectors.Checked) {
            Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Warning'
            $outputBox.AppendText("  [⚠] Hinweis: Die Prüfung auf fehlerhafte Sektoren kann sehr lange dauern.`r`n")
            Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Default'
        }

        # Abbruch-Button aktivieren
        $script:chkdskRunning = $true
            
        $totalDrives = $selectedDrives.Count
        $currentDriveIndex = 0
        # Variable für Neustart-Erfordernis
        $restartRequired = $false

        foreach ($drive in $selectedDrives) {
            $currentDriveIndex++
            $progressPercent = [int](($currentDriveIndex - 1) / $totalDrives * 100)
            if ($null -ne $progressBar) {
                $progressBar.Value = $progressPercent
            }
            
            # Starten der Zeitmessung für dieses Laufwerk
            $driveStopwatch = [System.Diagnostics.Stopwatch]::StartNew()
                
            Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Action'
            $outputBox.AppendText("`r`n  ┌─ Laufwerk $drive ($currentDriveIndex von $totalDrives)`r`n")
            Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Default'
            $outputBox.AppendText("  ├─ Befehl  : chkdsk $drive$chkdskParams`r`n")
                
            # Prüfen, ob es sich um das Systemlaufwerk handelt
            $isSystemDrive = $drive -eq $env:SystemDrive
            if ($isSystemDrive -and ($checkBoxFixErrors.Checked -or $checkBoxScanSectors.Checked)) {
                Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Warning'
                $outputBox.AppendText("  ├─ [⚠] Systemlaufwerk erkannt – CHKDSK wird beim nächsten Neustart ausgeführt.`r`n")
                Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Default'
                $restartRequired = $true
                    
                # CHKDSK beim nächsten Neustart mit fsutil planen (zuverlässiger)
                try {
                    # Zuerst das Laufwerk als "dirty" markieren
                    $fsutilResult = & fsutil dirty set $drive
                        $outputBox.AppendText("  ├─ [►] Laufwerk als 'dirty' markiert.`r`n")
                    # Dann CHKDSK-Parameter für den nächsten Neustart setzen
                    $regPath = "HKLM:\System\CurrentControlSet\Control\Session Manager"
                    $regKey = Get-ItemProperty -Path $regPath -Name "BootExecute" -ErrorAction SilentlyContinue
                        
                    if ($regKey) {
                        $bootExecute = $regKey.BootExecute
                        # Prüfen, ob bereits ein CHKDSK-Eintrag vorhanden ist
                        $chkdskEntry = "autocheck autochk * $drive$chkdskParams"
                            
                        if ($bootExecute -notcontains $chkdskEntry) {
                            $newBootExecute = @("autocheck autochk *")
                            foreach ($item in $bootExecute) {
                                if ($item -ne "autocheck autochk *") {
                                    $newBootExecute += $item
                                }
                            }
                            $newBootExecute += $chkdskEntry
                            Set-ItemProperty -Path $regPath -Name "BootExecute" -Value $newBootExecute
                            Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Success'
                            $outputBox.AppendText("  ├─ [✓] CHKDSK für nächsten Neustart geplant (Parameter:$chkdskParams)`r`n")
                            Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Default'
                        }
                    }
                    $chkntfsResult = & chkntfs $drive
                        Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Default'
                        $outputBox.AppendText("  ├─ [►] chkntfs-Status: $chkntfsResult`r`n")
                    
                    # Zeitmessung für Systemlaufwerk stoppen
                    $driveStopwatch.Stop()
                    $formattedTime = [math]::Round($driveStopwatch.Elapsed.TotalSeconds, 1)
                    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Action'
                    $outputBox.AppendText("  └─ [►] Einrichtungsdauer: $formattedTime Sek.`r`n")
                    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Muted'
                    $outputBox.AppendText("  " + ("─" * 66) + "`r`n")
                    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Default'
                }
                catch {
                    $outputBox.AppendText("  ├─ [!] Fehler beim Setzen des CHKDSK-Neustarts: $_`r`n")
                    # Alternativer Ansatz mit direktem Befehl
                    if ($checkBoxAutoConfirmBusy.Checked) {
                        $outputBox.AppendText("  ├─ [►] Verwende alternative Methode mit automatischer Bestätigung (J)`r`n")
                        $chkdskCmd = "echo J | chkdsk $drive$chkdskParams /b"
                    } 
                    else {
                        $chkdskCmd = "chkdsk $drive$chkdskParams /b"
                    }
                        
                    Start-Process -FilePath "cmd.exe" -ArgumentList "/c $chkdskCmd" -Verb RunAs -Wait
                }
            }
            else {
                # Start CHKDSK process and capture exit code
                Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Default'
                $outputBox.AppendText("  ├─ [►] Starte CHKDSK...`r`n")
                    
                try {
                    # Je nach Einstellung für Auto-Bestätigung
                    if ($checkBoxAutoConfirmBusy.Checked) {
                        $process = Start-Process -FilePath "cmd.exe" -ArgumentList "/c echo J | chkdsk $drive$chkdskParams" -NoNewWindow -PassThru -Wait
                    }
                    else {
                        $process = Start-Process -FilePath "chkdsk.exe" -ArgumentList "$drive$chkdskParams" -NoNewWindow -PassThru -Wait
                    }
                        
                    $exitCode = $process.ExitCode
                        
                    # Exit-Code interpretieren und Stil setzen
                    $exitStyle = switch ($exitCode) {
                        0       { 'Success' }
                        1       { 'Success' }
                        2       { 'Warning' }
                        3       { 'Error'   }
                        default { 'Error'   }
                    }
                    switch ($exitCode) {
                        2 { $restartRequired = $true }
                    }
                    # Stoppe den Stopwatch für dieses Laufwerk
                    $driveStopwatch.Stop()
                    
                    # Schöne Ausgabe des Exit-Codes mit relevanten Informationen
                    $formattedTime = [math]::Round($driveStopwatch.Elapsed.TotalSeconds, 1)
                    $exitIcon = switch ($exitCode) {
                        0       { "[✓]" }
                        1       { "[✓]" }
                        2       { "[⚠]" }
                        3       { "[✗]" }
                        default { "[✗]" }
                    }
                    $exitCodeMessage = switch ($exitCode) {
                        0       { "Keine Fehler gefunden." }
                        1       { "Fehler gefunden und korrigiert." }
                        2       { "Neustart erforderlich, um die Prüfung abzuschließen." }
                        3       { "Nicht alle Fehler behebbar – Laufwerk möglicherweise beschädigt." }
                        default { "Unbekannter CHKDSK-Statuscode: $exitCode" }
                    }
                        
                    Set-OutputSelectionStyle -OutputBox $outputBox -Style $exitStyle
                    $outputBox.AppendText("  ├─ $exitIcon CHKDSK-Status : $exitCodeMessage`r`n")
                    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Action'
                    $outputBox.AppendText("  └─ [►] Exit-Code: $exitCode | Dauer: $formattedTime Sek.`r`n")
                    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Muted'
                    $outputBox.AppendText("  " + ("─" * 66) + "`r`n")
                    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Default'
                }
                catch {
                    # Stopwatch anhalten auch bei Fehlern
                    $driveStopwatch.Stop()
                    $formattedTime = [math]::Round($driveStopwatch.Elapsed.TotalSeconds, 1)
                    
                    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Error'
                    $outputBox.AppendText("  ├─ [✗] Fehler: $($_.Exception.Message)`r`n")
                    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Action'
                    $outputBox.AppendText("  └─ [►] Dauer bis Fehler: $formattedTime Sek.`r`n")
                    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Muted'
                    $outputBox.AppendText("  " + ("─" * 66) + "`r`n")
                    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Default'
                }
            }
        }
            
        # Abschluss-Sektion
        Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Action'
        $outputBox.AppendText("`r`n  " + ("═" * 66) + "`r`n")
        $outputBox.AppendText("  Ergebnis`r`n")
        $outputBox.AppendText("  " + ("═" * 66) + "`r`n`r`n")

        # Wenn ein Neustart erforderlich ist und Auto-Neustart aktiviert ist
        if ($restartRequired -and $checkBoxAutoRestart.Checked) {
            $seconds = [int]$numRestartTimer.Value
            if ($seconds -gt 0) {
                Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Warning'
                $outputBox.AppendText("  [⚠] Neustart in $seconds Sekunden...`r`n")
                Start-Process -FilePath "shutdown.exe" -ArgumentList "/r /t $seconds /c `"CHKDSK erfordert einen Neustart`"" -NoNewWindow
            }
        }
        elseif ($restartRequired) {
            Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Warning'
            $outputBox.AppendText("  [⚠] Bitte starten Sie den Computer neu, um die CHKDSK-Prüfung für das Systemlaufwerk durchzuführen.`r`n")
        }
        else {
            Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Success'
            $outputBox.AppendText("  [✓] Alle gewählten Laufwerke wurden geprüft.`r`n")
        }
        Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Action'
        $outputBox.AppendText("`r`n  " + ("═" * 66) + "`r`n")
            
        # Setze den Fortschrittsbalken auf 100%
        if ($null -ne $progressBar) {
            $progressBar.Value = 100
        }
        # CHKDSK-Lauf beendet
        $script:chkdskRunning = $false
    }
    else {
        Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Warning'
        $outputBox.AppendText("`r`n  [⚠] CHKDSK wurde vom Benutzer abgebrochen.`r`n")
    }
}

# Export functions
Export-ModuleMember -Function Start-CHKDSK

# SIG # Begin signature block
# MIIcSgYJKoZIhvcNAQcCoIIcOzCCHDcCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDa2ukWGTd5UKIN
# X07ovQo6H+4cLvGoXRKDdXQzeRdzeaCCFnowggM8MIICJKADAgECAhBJfyGrXBJT
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
# MQ4wDAYKKwYBBAGCNwIBFTAvBgkqhkiG9w0BCQQxIgQgKGhiDVu1jJ3R9347WkUD
# 0DQDpzYCKkrpF+yOyi1bGPgwDQYJKoZIhvcNAQEBBQAEggEAm7KKRZsSBohavS4M
# ygEY0uWufYZKnqXnrII/0z7n+8WjElSCMegGcyq3a7A6DDHpBWavTaAy5dfnMrx+
# 8ycXR4vaXoD4A+BfOxGWqHs4tpCbCqXKeYuGXPvm2TiiMIUhbs70Vo5PV9eEqRUX
# W0FV88QPG/SRvJkHz/Bh+fXsjn/NOaRsNp4AJA0Flycr4fKu9PL06wDfRePndy6g
# Yrl2e22xSPW3cLxqrtJYIY6U4+ijDHxf+YKGezOERHd6zOGpMVpYyOkIawoffDeQ
# i6Oxr4PC9hC41W03/5dpIVxSsWNrIl7IU3Cfi3llMi1wAEZ4vgcvI4xRinuM/yp/
# f0BuMKGCAyYwggMiBgkqhkiG9w0BCQYxggMTMIIDDwIBATB9MGkxCzAJBgNVBAYT
# AlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5jLjFBMD8GA1UEAxM4RGlnaUNlcnQg
# VHJ1c3RlZCBHNCBUaW1lU3RhbXBpbmcgUlNBNDA5NiBTSEEyNTYgMjAyNSBDQTEC
# EAqA7xhLjfEFgtHEdqeVdGgwDQYJYIZIAWUDBAIBBQCgaTAYBgkqhkiG9w0BCQMx
# CwYJKoZIhvcNAQcBMBwGCSqGSIb3DQEJBTEPFw0yNjAxMjAxODAyNTRaMC8GCSqG
# SIb3DQEJBDEiBCBbd7selGvG7rMWnchRp0CGMtJkROeRrzQoxBQoqNWtJTANBgkq
# hkiG9w0BAQEFAASCAgDIEtb/PC+2w8iK7rEbXA7+PwqoAUku4RbVmH9Urb83gMZB
# 7SCwo9ACxAHfe/6ncHt8B4kVs1DghnZpNi+zu83jq3i7nH9RAExTjqqlS7jj+8+3
# +6JTeSL5vrWWHC803f2bnvwr3mmenyI7tuXk+nZ2JQq1C62j47fetr5Y2mBXXkb9
# Odkfq3vZtVsS4KTklOGr8/ZHYQS4h/a+TYeHAJMjupgjU2Fmw/57azvEmo4ublf9
# fQ5EhoXfRqGVLwIaoLfsoDUhxC2Czfomynp8mAkZM9G7yp/4Mz6y+zUlxXvp7lDx
# z3cjC1pZsy87M+h8qCh1kl+DjLd3bLU8Ix01fH8uh91tY7WHlXf0yHXU5BmkMOoV
# aYF9nfW5tSN7E7nQ8SE/dybhRCNbYWoA7LeRl2sEMzYJZl+0R33lEBzWdavuzjaq
# o2Vc5mcXnC/Bo4pq98AqMYHbyZHbJjw82s6sLXfRs9pCln1gZezYpjAP27XEo0Oe
# UtwuJ+SnfxJ/YJ+dkzYNvUovHO688OAiLj1l3nWHJf9l1j3dsj4r3D9WDEVAZTL6
# PP0Ps8rNHu57UBkvhGD4PJi+fdgdkU1MLV7XOEx3CyHLNXSUUwyb5O6kegXvZR0Y
# EsL4FGEQyuRdFb0rM4zu4r1BEat3dX9kC9QX5ArcbfdSrCnh52QeSkd09A8Fxg==
# SIG # End signature block

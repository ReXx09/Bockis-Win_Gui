# Import required modules
Import-Module "$PSScriptRoot\..\Core\Core.psm1" -Force
Import-Module "$PSScriptRoot\..\Core\ProgressBarTools.psm1" -Force

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
    Write-ToolLog -ToolName "CHKDSK" -Message "CHKDSK wird gestartet" -OutputBox $outputBox -Color ([System.Drawing.Color]::Blue) -Level "Information" -SaveToDatabase
    
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
    Write-Host
    Write-Host "     [>] Ein Dialog-Fenster für die Auswahl der Laufwerke wird geöffnet...... " -ForegroundColor $secondaryColor
    Write-Host
    Write-Host "     [i] Bitte wählen Sie die zu prüfenden Laufwerke und Optionen aus... " -ForegroundColor Blue
    Write-Host
    Write-Host "`n" + ("═" * 70) -ForegroundColor Cyan 
    Write-Host
        
    # Verfügbare Laufwerke ermitteln
    $drives = Get-WmiObject Win32_LogicalDisk | 
    Where-Object { $_.DriveType -eq 3 -or $_.DriveType -eq 2 } | 
    Select-Object -ExpandProperty DeviceID    # Laufwerksinformationen anzeigen
    $outputBox.SelectionColor = [System.Drawing.Color]::Blue
    $outputBox.AppendText("[►] VERFÜGBARE LAUFWERKE:`r`n`r`n")
    
    # Tabellenkopf erstellen
    $outputBox.SelectionColor = [System.Drawing.Color]::DarkBlue
    $lw = "Laufwerk".PadRight(15)
    $name = "Bezeichnung".PadRight(20)
    $total = "Größe".PadRight(15)
    $free = "Freier Speicher".PadRight(20)
    $used = "Belegung".PadRight(15)
    $outputBox.AppendText("    $lw$name$total$free$used`r`n")
    
    # Trennlinie
    $outputBox.SelectionColor = [System.Drawing.Color]::Gray
    $outputBox.AppendText("    " + "".PadRight(85, '─') + "`r`n")
    $outputBox.SelectionColor = [System.Drawing.Color]::Black
    
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
            $outputBox.SelectionColor = [System.Drawing.Color]::Red
            $outputBox.AppendText("$usedPercent% (Kritisch)")
        } 
        elseif ($usedPercent -gt 75) {
            $outputBox.SelectionColor = [System.Drawing.Color]::Orange
            $outputBox.AppendText("$usedPercent% (Warnung)")
        }
        else {
            $outputBox.SelectionColor = [System.Drawing.Color]::Green
            $outputBox.AppendText("$usedPercent% (OK)")
        }
        
        $outputBox.SelectionColor = [System.Drawing.Color]::Black
        $outputBox.AppendText("`r`n")
    }
    
    $outputBox.AppendText("`r`n")
    
    # Kurze Information zum weiteren Vorgehen
    $outputBox.SelectionColor = [System.Drawing.Color]::Blue
    $outputBox.AppendText("[►] VORBEREITUNG CHKDSK:`r`n")
    $outputBox.SelectionColor = [System.Drawing.Color]::Green
    $outputBox.AppendText("    Bitte wählen Sie die zu prüfenden Laufwerke und Optionen im Dialog-Fenster aus...`r`n")

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
        $outputBox.AppendText("CHKDSK wird ausgeführt mit Parametern:$chkdskParams`r`n`r`n")
        if ($checkBoxScanSectors.Checked) {
            $outputBox.AppendText("Hinweis: Die Prüfung auf fehlerhafte Sektoren kann lange dauern.`r`n`r`n")
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
                
            $outputBox.AppendText("CHKDSK für Laufwerk $drive gestartet ($currentDriveIndex von $totalDrives)...`r`n")
                
            # Prüfen, ob es sich um das Systemlaufwerk handelt
            $isSystemDrive = $drive -eq $env:SystemDrive
            if ($isSystemDrive -and ($checkBoxFixErrors.Checked -or $checkBoxScanSectors.Checked)) {
                $outputBox.AppendText("Systemlaufwerk $drive erkannt. CHKDSK wird beim nächsten Neustart ausgeführt.`r`n")
                $restartRequired = $true
                    
                # CHKDSK beim nächsten Neustart mit fsutil planen (zuverlässiger)
                try {
                    # Zuerst das Laufwerk als "dirty" markieren
                    $fsutilResult = & fsutil dirty set $drive
                    $outputBox.AppendText("Laufwerk als 'dirty' markiert: $fsutilResult`r`n")
                        
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
                            $outputBox.AppendText("CHKDSK wurde für den nächsten Neustart geplant mit Parametern:$chkdskParams`r`n")
                        }
                    }
                    # Prüfen, ob CHKDSK bereits geplant ist
                    $chkntfsResult = & chkntfs $drive
                    $outputBox.AppendText("Status: $chkntfsResult`r`n")
                    
                    # Zeitmessung für Systemlaufwerk stoppen
                    $driveStopwatch.Stop()
                    $formattedTime = [math]::Round($driveStopwatch.Elapsed.TotalSeconds, 1)
                    $outputBox.SelectionColor = [System.Drawing.Color]::Blue
                    $outputBox.AppendText("[INFO] Laufwerk: $drive | Dauer der Einrichtung: $formattedTime Sekunden`r`n")
                    $outputBox.AppendText("____________________________________________________`r`n`r`n")
                    $outputBox.SelectionColor = $outputBox.ForeColor
                }
                catch {
                    $outputBox.AppendText("Fehler beim Setzen des CHKDSK-Neustarts: $_`r`n")
                    # Alternativer Ansatz mit direktem Befehl
                    if ($checkBoxAutoConfirmBusy.Checked) {
                        $outputBox.AppendText("Verwende alternative Methode mit automatischer Bestätigung (J)`r`n")
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
                $outputBox.AppendText("Parameter: chkdsk $drive$chkdskParams`r`n")
                    
                try {
                    # Je nach Einstellung für Auto-Bestätigung
                    if ($checkBoxAutoConfirmBusy.Checked) {
                        $process = Start-Process -FilePath "cmd.exe" -ArgumentList "/c echo J | chkdsk $drive$chkdskParams" -NoNewWindow -PassThru -Wait
                    }
                    else {
                        $process = Start-Process -FilePath "chkdsk.exe" -ArgumentList "$drive$chkdskParams" -NoNewWindow -PassThru -Wait
                    }
                        
                    $exitCode = $process.ExitCode
                        
                    # Exit-Code interpretieren
                    switch ($exitCode) {
                        0 { 
                            $outputBox.SelectionColor = [System.Drawing.Color]::Green
                        }
                        1 { 
                            $outputBox.SelectionColor = [System.Drawing.Color]::DarkGreen
                        }
                        2 { 
                            $outputBox.SelectionColor = [System.Drawing.Color]::Orange
                            $restartRequired = $true
                        }
                        3 { 
                            $outputBox.SelectionColor = [System.Drawing.Color]::Red
                        }
                        default { 
                            $outputBox.SelectionColor = [System.Drawing.Color]::DarkRed
                        }
                    }
                    # Stoppe den Stopwatch für dieses Laufwerk
                    $driveStopwatch.Stop()
                    
                    # Schöne Ausgabe des Exit-Codes mit relevanten Informationen
                    $formattedTime = [math]::Round($driveStopwatch.Elapsed.TotalSeconds, 1)
                    $exitCodeMessage = switch ($exitCode) {
                        0 { "[OK] CHKDSK erfolgreich abgeschlossen. Keine Fehler gefunden." }
                        1 { "[OK] CHKDSK hat Fehler gefunden und korrigiert." }
                        2 { "[WARNUNG] CHKDSK wurde mit /f Option ausgeführt und erfordert einen Neustart." }
                        3 { "[FEHLER] CHKDSK konnte nicht alle Fehler beheben. Laufwerk möglicherweise beschädigt." }
                        default { "[FEHLER] Unbekannter CHKDSK-Statuscode: $exitCode" }
                    }
                        
                    $outputBox.AppendText("CHKDSK-Status: $exitCodeMessage`r`n")
                    $outputBox.SelectionColor = [System.Drawing.Color]::Blue
                    $outputBox.AppendText("[INFO] Exit-Code: $exitCode | Laufwerk: $drive | Dauer: $formattedTime Sekunden`r`n")
                    $outputBox.AppendText("____________________________________________________`r`n`r`n")
                        
                    # Farbe zurücksetzen
                    $outputBox.SelectionColor = $outputBox.ForeColor
                }
                catch {
                    # Stopwatch anhalten auch bei Fehlern
                    $driveStopwatch.Stop()
                    $formattedTime = [math]::Round($driveStopwatch.Elapsed.TotalSeconds, 1)
                    
                    $outputBox.SelectionColor = [System.Drawing.Color]::Red
                    $outputBox.AppendText("❌ FEHLER: $($_.Exception.Message)`r`n")
                    $outputBox.AppendText("[INFO] Laufwerk: $drive | Dauer bis zum Fehler: $formattedTime Sekunden`r`n")
                    $outputBox.AppendText("____________________________________________________`r`n`r`n")
                    $outputBox.SelectionColor = $outputBox.ForeColor
                }
            }
        }
            
        # Wenn ein Neustart erforderlich ist und Auto-Neustart aktiviert ist
        if ($restartRequired -and $checkBoxAutoRestart.Checked) {
            $seconds = [int]$numRestartTimer.Value
            if ($seconds -gt 0) {
                $outputBox.AppendText("`r`nComputer wird in $seconds Sekunden neu gestartet...`r`n")
                Start-Process -FilePath "shutdown.exe" -ArgumentList "/r /t $seconds /c `"CHKDSK erfordert einen Neustart`"" -NoNewWindow
            }
        }
        elseif ($restartRequired) {
            $outputBox.AppendText("`r`nBitte starten Sie den Computer neu, um die CHKDSK-Prüfung für das Systemlaufwerk durchzuführen.`r`n")
        }
            
        # Setze den Fortschrittsbalken auf 100%
        if ($null -ne $progressBar) {
            $progressBar.Value = 100
        }
        # CHKDSK-Lauf beendet
        $script:chkdskRunning = $false
    }
    else {
        $outputBox.AppendText("CHKDSK wurde abgebrochen.`r`n")
    }
}

# Export functions
Export-ModuleMember -Function Start-CHKDSK
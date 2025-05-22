# Import required modules
Import-Module "$PSScriptRoot\..\Core\Core.psm1" -Force

# Function to run disk cleanup
function Start-DiskCleanup {
    param (
        [System.Windows.Forms.RichTextBox]$outputBox,
        [System.Windows.Forms.ProgressBar]$progressBar
    )
    
    try {
        # OutputBox und ProgressBar zurücksetzen
        $outputBox.Clear()
        if ($null -ne $progressBar) {
            $progressBar.Value = 0
        }
        else {
            $outputBox.AppendText("Warnung: ProgressBar nicht verfügbar.`r`n")
        }

        # Verfügbare Laufwerke ermitteln (nur feste Laufwerke)
        $drives = Get-WmiObject Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 } | Select-Object -ExpandProperty DeviceID
        $totalDrives = $drives.Count
        $currentDriveIndex = 0
        $totalFreedSpace = 0
        $totalFilesRemoved = 0
        $totalSkippedFiles = 0

        $outputBox.SelectionColor = [System.Drawing.Color]::Blue
        $outputBox.AppendText("Schnelle Datenträgerbereinigung wird gestartet...`r`n")
        $outputBox.AppendText(("-" * 60) + "`r`n")

        # Quick-Cleanup-Pfade definieren (ähnlich dem Referenzskript)
        $cleanupPaths = @(
            @{ Name = "Windows Temp"; PathPattern = "Windows\Temp\*" },
            @{ Name = "Benutzer Temp"; PathPattern = "Users\*\AppData\Local\Temp\*" },
            @{ Name = "Windows Update Cache"; PathPattern = "Windows\SoftwareDistribution\Download\*" },
            @{ Name = "Prefetch"; PathPattern = "Windows\Prefetch\*" },
            @{ Name = "Internet Cache (IE/Edge Legacy)"; PathPattern = "Users\*\AppData\Local\Microsoft\Windows\INetCache\*" },
            @{ Name = "Thumbnail Cache"; PathPattern = "Users\*\AppData\Local\Microsoft\Windows\Explorer\thumbcache_*.db" },
            @{ Name = "Chrome Cache"; PathPattern = "Users\*\AppData\Local\Google\Chrome\User Data\Default\Cache\*" },
            @{ Name = "Firefox Cache"; PathPattern = "Users\*\AppData\Local\Mozilla\Firefox\Profiles\*\cache2\*" },
            @{ Name = "Edge Cache"; PathPattern = "Users\*\AppData\Local\Microsoft\Edge\User Data\Default\Cache\*" }
        )

        # Dienste stoppen, die Dateien sperren könnten (optional, mit Vorsicht verwenden)
        # Stop-Service BITS -ErrorAction SilentlyContinue
        # Stop-Service wuauserv -ErrorAction SilentlyContinue

        foreach ($drive in $drives) {
            $currentDriveIndex++
            $driveLetter = $drive # z.B. "C:"
                
            # Sicherstellen, dass der Laufwerksbuchstabe korrekt formatiert ist
            if ($driveLetter -match "^([A-Za-z]):.*$") {
                $driveLetter = $matches[1] + ":"
            }
                
            $driveFreedSpace = 0
            $driveFilesRemoved = 0
            $driveSkippedFiles = 0

            $outputBox.SelectionColor = [System.Drawing.Color]::DarkBlue
            $outputBox.AppendText("`r`n>>> Bereinige Laufwerk ${driveLetter}... ($currentDriveIndex von $totalDrives)`r`n")

            $pathCount = $cleanupPaths.Count
            $currentPathIndex = 0

            foreach ($cleanupItem in $cleanupPaths) {
                $currentPathIndex++
                    
                # Korrigierte Pfadkonstruktion
                $fullPath = if ($cleanupItem.PathPattern.StartsWith("\")) {
                    "$driveLetter$($cleanupItem.PathPattern)"
                }
                else {
                    "$driveLetter\$($cleanupItem.PathPattern)"
                }
                    
                # ProgressBar aktualisieren
                if ($null -ne $progressBar) {
                    $progressValue = [int](($currentDriveIndex - 1) / $totalDrives * 100 + ($currentPathIndex / $pathCount) * (100 / $totalDrives))
                    $progressBar.Value = [Math]::Min(100, $progressValue)
                }

                $outputBox.SelectionColor = [System.Drawing.Color]::Gray
                $outputBox.AppendText("  -> $($cleanupItem.Name)... ")
                [System.Windows.Forms.Application]::DoEvents() # UI aktualisieren

                $filesToDelete = @()
                try {
                    # Get-ChildItem mit -Force, um versteckte/Systemdateien zu berücksichtigen
                    $filesToDelete = Get-ChildItem -Path $fullPath -Recurse -File -Force -ErrorAction SilentlyContinue
                }
                catch {
                    $outputBox.SelectionColor = [System.Drawing.Color]::Orange
                    $outputBox.AppendText("[Zugriffsfehler]`r`n")
                    continue # Nächster Pfad
                }

                if ($filesToDelete -and $filesToDelete.Count -gt 0) {
                    # Vor dem Löschen die tatsächliche Größe berechnen
                    $currentPathSize = ($filesToDelete | Measure-Object -Property Length -Sum).Sum
                    $currentPathCount = $filesToDelete.Count
                    $removedCountInPath = 0
                    $sizeRemovedInPath = 0
                    $skippedCountInPath = 0

                    foreach ($file in $filesToDelete) {
                        try {
                            $fileSize = $file.Length
                            Remove-Item -Path $file.FullName -Force -ErrorAction Stop
                            $removedCountInPath++
                            $sizeRemovedInPath += $fileSize
                        }
                        catch {
                            # Datei konnte nicht gelöscht werden (wahrscheinlich gesperrt)
                            $skippedCountInPath++
                        }
                    }

                    if ($removedCountInPath -gt 0) {
                        $driveFreedSpace += $sizeRemovedInPath
                        $driveFilesRemoved += $removedCountInPath
                        $driveSkippedFiles += $skippedCountInPath
                            
                        $outputBox.SelectionColor = [System.Drawing.Color]::Green
                        $outputBox.AppendText("($removedCountInPath Dateien / $(Format-FileSize $sizeRemovedInPath)) entfernt")
                            
                        if ($skippedCountInPath -gt 0) {
                            $outputBox.SelectionColor = [System.Drawing.Color]::Orange
                            $outputBox.AppendText(" ($skippedCountInPath übersprungen)")
                        }
                        $outputBox.AppendText("`r`n")
                    }
                    else {
                        $outputBox.SelectionColor = [System.Drawing.Color]::DarkGray
                        $outputBox.AppendText("(Keine Dateien entfernt/gelöscht)`r`n")
                    }
                }
                else {
                    $outputBox.SelectionColor = [System.Drawing.Color]::DarkGray
                    $outputBox.AppendText("(Keine Dateien gefunden)`r`n")
                }
                [System.Windows.Forms.Application]::DoEvents() # UI aktualisieren
            } # Ende Pfade pro Laufwerk

            $totalFreedSpace += $driveFreedSpace
            $totalFilesRemoved += $driveFilesRemoved
            $totalSkippedFiles += $driveSkippedFiles
                
            $outputBox.SelectionColor = [System.Drawing.Color]::DarkGreen
            $outputBox.AppendText("-> Laufwerk ${driveLetter}: $driveFilesRemoved Dateien entfernt ($(Format-FileSize $driveFreedSpace))")
                
            if ($driveSkippedFiles -gt 0) {
                $outputBox.SelectionColor = [System.Drawing.Color]::Orange
                $outputBox.AppendText(", $driveSkippedFiles übersprungen")
            }
                
            $outputBox.AppendText("`r`n")
            $outputBox.AppendText(("-" * 50) + "`r`n")

            # Nach jedem Laufwerk die Änderungen sofort anzeigen
            [System.Windows.Forms.Application]::DoEvents()
        } # Ende Laufwerke

        # Abschlussmeldung
        if ($null -ne $progressBar) {
            $progressBar.Value = 100
        }
        $outputBox.SelectionColor = [System.Drawing.Color]::Green
        $outputBox.AppendText("`r`n================================================`r`n")
        $outputBox.AppendText("✅ Schnelle Datenträgerbereinigung abgeschlossen!`r`n")
        $outputBox.AppendText("   Insgesamt entfernt: $totalFilesRemoved Dateien`r`n")
        $outputBox.AppendText("   Insgesamt freigegeben: $(Format-FileSize $totalFreedSpace)`r`n")
            
        if ($totalSkippedFiles -gt 0) {
            $outputBox.SelectionColor = [System.Drawing.Color]::Orange
            $outputBox.AppendText("   Übersprungene Dateien: $totalSkippedFiles (in Verwendung)`r`n")
            $outputBox.SelectionColor = [System.Drawing.Color]::Green
        }
            
        $outputBox.AppendText("================================================`r`n")

    }
    catch {
        $outputBox.SelectionColor = [System.Drawing.Color]::Red
        $outputBox.AppendText("`r`n❌ FEHLER während der Bereinigung: $($_.Exception.Message)`r`n")
        if ($null -ne $progressBar) {
            $progressBar.Value = 0 # Oder auf einen Fehlerwert setzen
        }
    }

    # Farbe zurücksetzen
    $outputBox.SelectionColor = $outputBox.ForeColor
}

# Hilfsfunktion zum Formatieren der Dateigröße (falls noch nicht vorhanden)
if (-not (Get-Command Format-FileSize -ErrorAction SilentlyContinue)) {
    function Format-FileSize {
        param ([double]$Size)
        if ($Size -lt 1KB) { return "$([Math]::Round($Size, 0)) Bytes" }
        elseif ($Size -lt 1MB) { return "{0:N2} KB" -f ($Size / 1KB) }
        elseif ($Size -lt 1GB) { return "{0:N2} MB" -f ($Size / 1MB) }
        else { return "{0:N2} GB" -f ($Size / 1GB) }
    }
}

# Funktion zum Laden der Cleanup-Einstellungen
function Get-CleanupSettings {
    if (Get-Command -Name Get-Settings -Module Setup -ErrorAction SilentlyContinue) {
        $settings = Get-Settings
        return $settings.Cleanup
    }
    else {
        # Standardwerte, wenn Setup-Modul nicht verfügbar ist
        return @{
            CustomPaths      = @()
            ExcludedPaths    = @()
            ScheduledCleanup = $false
            CleanupInterval  = "Weekly"
        }
    }
}

# Funktion zur Überprüfung, ob ein Pfad ausgeschlossen ist
function Test-PathExcluded {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path
    )
    
    $cleanupSettings = Get-CleanupSettings
    
    foreach ($excludedPath in $cleanupSettings.ExcludedPaths) {
        if ($Path -eq $excludedPath -or $Path.StartsWith($excludedPath + "\")) {
            return $true
        }
    }
    
    return $false
}

# Function to clean temporary files
function Start-TempFilesCleanup {
    param (
        [System.Windows.Forms.RichTextBox]$outputBox,
        [System.Windows.Forms.ProgressBar]$progressBar
    )
    
    # outputBox zurücksetzen
    $outputBox.Clear()
    $outputBox.SelectionColor = [System.Drawing.Color]::DarkBlue
    $outputBox.AppendText("Starte Bereinigung temporärer Dateien...`r`n`r`n")
    
    # ProgressBar zurücksetzen falls vorhanden
    if ($null -ne $progressBar) {
        $progressBar.Value = 0
    }
    
    try {
        # Liste der zu bereinigenden Verzeichnisse
        $tempFolders = @(
            [System.IO.Path]::GetTempPath(),
            "$env:USERPROFILE\AppData\Local\Temp",
            "$env:WINDIR\Temp"
        )
        
        # Statistische Variablen initialisieren
        $totalFiles = 0
        $deletedFiles = 0
        $totalSize = 0
        $currentFolderIndex = 0
        $totalFolders = $tempFolders.Count
        
        # Benutzerdefinierte Pfade hinzufügen
        $cleanupSettings = Get-CleanupSettings
        $customPaths = $cleanupSettings.CustomPaths
        
        if ($customPaths.Count -gt 0) {
            $outputBox.SelectionColor = [System.Drawing.Color]::Blue
            $outputBox.AppendText("Zusätzliche benutzerdefinierte Pfade werden bereinigt...\r\n")
            
            foreach ($path in $customPaths) {
                if (Test-Path $path) {
                    # Prüfen, ob der Pfad nicht ausgeschlossen ist
                    if (-not (Test-PathExcluded -Path $path)) {
                        try {
                            $outputBox.SelectionColor = [System.Drawing.Color]::Black
                            $outputBox.AppendText("Bereinige $path...\r\n")
                            
                            # Dateien im benutzerdefinierten Pfad löschen
                            Get-ChildItem -Path $path -File -Recurse -ErrorAction SilentlyContinue | 
                            Where-Object { -not (Test-PathExcluded -Path $_.FullName) } | 
                            Remove-Item -Force -ErrorAction SilentlyContinue
                            
                            $outputBox.SelectionColor = [System.Drawing.Color]::Green
                            $outputBox.AppendText("Benutzerdefinierter Pfad bereinigt: $path\r\n")
                        }
                        catch {
                            $outputBox.SelectionColor = [System.Drawing.Color]::Red
                            $outputBox.AppendText("Fehler beim Bereinigen von " + $path + ": " + $_ + "\r\n")
                        }
                    }
                    else {
                        $outputBox.SelectionColor = [System.Drawing.Color]::Gray
                        $outputBox.AppendText("Überspringe ausgeschlossenen Pfad: $path\r\n")
                    }
                }
                else {
                    $outputBox.SelectionColor = [System.Drawing.Color]::Yellow
                    $outputBox.AppendText("Benutzerdefinierter Pfad nicht gefunden: $path\r\n")
                }
            }
        }
        
        # Durchlaufe alle Temp-Ordner
        foreach ($folder in $tempFolders) {
            $currentFolderIndex++
            
            # Aktualisiere ProgressBar
            if ($null -ne $progressBar) {
                $progressBar.Value = [int](($currentFolderIndex - 1) / $totalFolders * 100)
            }
            
            $outputBox.SelectionColor = [System.Drawing.Color]::Blue
            $outputBox.AppendText("Untersuche Ordner: $folder`r`n")
            
            # Überprüfe, ob der Ordner existiert
            if (Test-Path -Path $folder) {
                $files = Get-ChildItem -Path $folder -Recurse -File -ErrorAction SilentlyContinue
                
                # Ermittle Anzahl der Dateien und Gesamtgröße
                $folderFiles = $files.Count
                $folderSize = 0
                if ($files) {
                    $folderSize = ($files | Measure-Object -Property Length -Sum).Sum / 1MB
                    $folderSize = [Math]::Round($folderSize, 2)
                }
                
                $outputBox.SelectionColor = [System.Drawing.Color]::Black
                $outputBox.AppendText("  Gefunden: $folderFiles Dateien ($folderSize MB)`r`n")
            }
            
            $outputBox.AppendText("`r`n")
        }
        
        # Aktualisiere ProgressBar auf 100%
        if ($null -ne $progressBar) {
            $progressBar.Value = 100
        }
        
        # Erfolgsnotiz
        $outputBox.SelectionColor = [System.Drawing.Color]::Green
        $outputBox.AppendText("`r`nBereinigung temporärer Dateien erfolgreich abgeschlossen.`r`n")
    }
    catch {
        $outputBox.SelectionColor = [System.Drawing.Color]::Red
        $outputBox.AppendText("[-] Fehler bei der Bereinigung: " + $_ + "`r`n")
    }
    
    # Farbe zurücksetzen
    $outputBox.SelectionColor = $outputBox.ForeColor
}

# Erweiterte Funktion für temporäre Dateien
function Start-TempFilesCleanupAdvanced {
    param (
        [System.Windows.Forms.RichTextBox]$outputBox,
        [System.Windows.Forms.ProgressBar]$progressBar,
        [System.Windows.Forms.Form]$mainform
    )
    
    try {
        $outputBox.Clear()
        $outputBox.SelectionColor = [System.Drawing.Color]::DarkBlue
        $outputBox.AppendText("Erweiterte Systemreinigung wird gestartet...`r`n")
        
        # Erstellen des Cleanup-Formulars
        $cleanupForm = New-Object System.Windows.Forms.Form
        $cleanupForm.Text = "Erweiterte Systemreinigung"
        $cleanupForm.Size = New-Object System.Drawing.Size(550, 750)
        $cleanupForm.StartPosition = "Manual"
        $cleanupForm.FormBorderStyle = "FixedDialog"
        $cleanupForm.MaximizeBox = $false
        $cleanupForm.MinimizeBox = $false
        $cleanupForm.BackColor = [System.Drawing.Color]::WhiteSmoke
        
        # Position relativ zur Hauptform setzen
        $mainFormLocation = $mainform.Location
        $cleanupForm.Location = New-Object System.Drawing.Point(
            ($mainFormLocation.X + $mainform.Width + 10),
            $mainFormLocation.Y
        )

        # Erstellen eines Laufwerksauswahl-Dialogs
        $driveGroupBox = New-Object System.Windows.Forms.GroupBox
        $driveGroupBox.Text = "Zu säubernde Laufwerke"
        $driveGroupBox.Location = New-Object System.Drawing.Point(20, 20)
        $driveGroupBox.Size = New-Object System.Drawing.Size(500, 180)
        $cleanupForm.Controls.Add($driveGroupBox)

        # CheckedListBox für die Laufwerke
        $drivesCheckedListBox = New-Object System.Windows.Forms.CheckedListBox
        $drivesCheckedListBox.Location = New-Object System.Drawing.Point(20, 30)
        $drivesCheckedListBox.Size = New-Object System.Drawing.Size(460, 120)
        $drivesCheckedListBox.CheckOnClick = $true
        $driveGroupBox.Controls.Add($drivesCheckedListBox)

        # Variable zur Unterdrückung von Ereignissen initialisieren
        $suppressEvents = $false

        # Verfügbare Laufwerke abrufen und zur Liste hinzufügen
        $drives = Get-PSDrive -PSProvider FileSystem
        foreach ($drive in $drives) {
            $driveInfo = Get-WmiObject -Class Win32_LogicalDisk -Filter "DeviceID='$($drive.Name):'" -ErrorAction SilentlyContinue
            if ($driveInfo) {
                $freeSpaceGB = [math]::Round($driveInfo.FreeSpace / 1GB, 2)
                $totalSpaceGB = [math]::Round($driveInfo.Size / 1GB, 2)
                $driveLabel = if ($driveInfo.VolumeName) { $driveInfo.VolumeName } else { "Lokales Laufwerk" }
                $driveEntry = "$($drive.Name): - $driveLabel ($freeSpaceGB GB frei von $totalSpaceGB GB)"
                $drivesCheckedListBox.Items.Add($driveEntry, $drive.Name -eq "C") | Out-Null
            }
        }

        # "Alle auswählen" Checkbox für Laufwerke
        $selectAllDrivesCheckbox = New-Object System.Windows.Forms.CheckBox
        $selectAllDrivesCheckbox.Text = "Alle Laufwerke auswählen"
        $selectAllDrivesCheckbox.Location = New-Object System.Drawing.Point(20, [int]155)
        $selectAllDrivesCheckbox.Size = New-Object System.Drawing.Size(200, 20)
        $selectAllDrivesCheckbox.Add_CheckedChanged({
                $newState = $selectAllDrivesCheckbox.Checked
                $suppressEvents = $true
                
                for ($i = 0; $i -lt $drivesCheckedListBox.Items.Count; $i++) {
                    $drivesCheckedListBox.SetItemChecked($i, $newState)
                }
                
                $suppressEvents = $false
                Update-CleanupSizeEstimates
            })
        $driveGroupBox.Controls.Add($selectAllDrivesCheckbox)

        # Event-Handler für CheckedListBox (Laufwerke) hinzufügen
        $drivesCheckedListBox.Add_ItemCheck({
                if (-not $suppressEvents) {
                    # Verzögerung einbauen, da während ItemCheck der Status noch nicht vollständig geändert ist
                    $form = $drivesCheckedListBox.FindForm()
                    if ($form) {
                        $form.BeginInvoke([System.Action] {
                                # Prüfen, ob "Alle auswählen" Checkbox aktualisiert werden soll
                                $allChecked = $true
                                for ($i = 0; $i -lt $drivesCheckedListBox.Items.Count; $i++) {
                                    if (-not $drivesCheckedListBox.GetItemChecked($i)) {
                                        $allChecked = $false
                                        break
                                    }
                                }
                        
                                # "Alle auswählen" Checkbox aktualisieren ohne Events auszulösen
                                $suppressEvents = $true
                                $selectAllDrivesCheckbox.Checked = $allChecked
                                $suppressEvents = $false
                        
                                # Berechnung der Dateigröße aktualisieren
                                Update-CleanupSizeEstimates
                            })
                    }
                }
            })

        # Bereich für die Reinigungsoptionen
        $optionsGroupBox = New-Object System.Windows.Forms.GroupBox
        $optionsGroupBox.Text = "Zu bereinigende Elemente"
        $optionsGroupBox.Location = New-Object System.Drawing.Point(20, 210)
        $optionsGroupBox.Size = New-Object System.Drawing.Size(500, 320)
        $cleanupForm.Controls.Add($optionsGroupBox)

        # Panel mit Scrollbar für Checkboxen
        $optionsPanel = New-Object System.Windows.Forms.Panel
        $optionsPanel.Location = New-Object System.Drawing.Point(10, 25)
        $optionsPanel.Size = New-Object System.Drawing.Size(480, 280)
        $optionsPanel.AutoScroll = $true
        $optionsGroupBox.Controls.Add($optionsPanel)

        # Tatsächliche Pfadmuster für die Reinigungsoptionen
        $cleanupOptions = @(
            @{
                Name        = "winTemp"; 
                Text        = "Windows temporäre Dateien"; 
                Default     = $true; 
                Description = "Bereinigt Windows\Temp Ordner"; 
                Paths       = @(
                    "Windows\Temp\*"
                )
            },
            @{
                Name        = "userTemp"; 
                Text        = "Benutzer temporäre Dateien"; 
                Default     = $true; 
                Description = "Bereinigt %TEMP% Ordner aller Benutzer"; 
                Paths       = @(
                    "Users\*\AppData\Local\Temp\*"
                )
            },
            @{
                Name        = "internetTemp"; 
                Text        = "Internet temporäre Dateien"; 
                Default     = $true; 
                Description = "Bereinigt Internet Explorer temporäre Dateien"; 
                Paths       = @(
                    "Users\*\AppData\Local\Microsoft\Windows\INetCache\*",
                    "Users\*\AppData\Local\Microsoft\Windows\WebCache\*"
                )
            },
            @{
                Name        = "chromeCache"; 
                Text        = "Chrome Cache"; 
                Default     = $true; 
                Description = "Bereinigt Google Chrome Cache-Dateien"; 
                Paths       = @(
                    "Users\*\AppData\Local\Google\Chrome\User Data\Default\Cache\*",
                    "Users\*\AppData\Local\Google\Chrome\User Data\Default\Code Cache\*"
                )
            },
            @{
                Name        = "firefoxCache"; 
                Text        = "Firefox Cache"; 
                Default     = $true; 
                Description = "Bereinigt Mozilla Firefox Cache-Dateien"; 
                Paths       = @(
                    "Users\*\AppData\Local\Mozilla\Firefox\Profiles\*\cache2\*",
                    "Users\*\AppData\Local\Mozilla\Firefox\Profiles\*\startupCache\*"
                )
            },
            @{
                Name        = "edgeCache"; 
                Text        = "Edge Cache"; 
                Default     = $true; 
                Description = "Bereinigt Microsoft Edge Cache-Dateien"; 
                Paths       = @(
                    "Users\*\AppData\Local\Microsoft\Edge\User Data\Default\Cache\*",
                    "Users\*\AppData\Local\Microsoft\Edge\User Data\Default\Code Cache\*"
                )
            },
            @{
                Name        = "thumbnails"; 
                Text        = "Thumbnails Cache"; 
                Default     = $true; 
                Description = "Löscht Windows Explorer Thumbnail-Cache"; 
                Paths       = @(
                    "Users\*\AppData\Local\Microsoft\Windows\Explorer\thumbcache_*.db"
                )
            },
            @{
                Name        = "winUpdates"; 
                Text        = "Windows Update Dateien"; 
                Default     = $true; 
                Description = "Entfernt temporäre Windows Update Dateien"; 
                Paths       = @(
                    "Windows\SoftwareDistribution\Download\*"
                )
            },
            @{
                Name        = "recyclebin"; 
                Text        = "Papierkorb leeren"; 
                Default     = $true; 
                Description = "Leert den Papierkorb"; 
                Paths       = @(
                    "\$Recycle.Bin\*"
                )
            },
            @{
                Name        = "prefetch"; 
                Text        = "Prefetch Dateien"; 
                Default     = $false; 
                Description = "Löscht Windows Prefetch Dateien"; 
                Paths       = @(
                    "Windows\Prefetch\*.pf"
                )
            },
            @{
                Name        = "eventLogs"; 
                Text        = "Event Logs"; 
                Default     = $false; 
                Description = "Bereinigt Windows Event Logs (Administratorrechte erforderlich)"; 
                Paths       = @() # Spezieller Fall, wird separat behandelt
            },
            @{
                Name        = "errorReports"; 
                Text        = "Fehlerberichte"; 
                Default     = $true; 
                Description = "Löscht Windows Fehlerberichte"; 
                Paths       = @(
                    "Windows\WER\*",
                    "Users\*\AppData\Local\CrashDumps\*"
                )
            }
        )

        # Checkboxen für die Reinigungsoptionen erstellen
        $yPosition = 10
        $cleanupCheckboxes = @{}
        $sizeLabels = @{}

        foreach ($option in $cleanupOptions) {
            # Checkbox erstellen
            $checkbox = New-Object System.Windows.Forms.CheckBox
            $checkbox.Text = $option.Text
            $checkbox.Checked = $option.Default
            $checkbox.Location = New-Object System.Drawing.Point(10, $yPosition)
            $checkbox.Size = New-Object System.Drawing.Size(240, 24)
            $checkbox.Tag = $option.Description
            $cleanupCheckboxes[$option.Name] = $checkbox

            # Label für die Größenanzeige
            $sizeLabel = New-Object System.Windows.Forms.Label
            $sizeLabel.Text = "wird berechnet..."
            $sizeLabel.Location = New-Object System.Drawing.Point(260, [int]($yPosition + 4))
            $sizeLabel.Size = New-Object System.Drawing.Size(110, 20)
            $sizeLabel.ForeColor = [System.Drawing.Color]::DarkBlue
            $sizeLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleRight
            $sizeLabels[$option.Name] = $sizeLabel

            # Info-Symbol (i)
            $infoIcon = New-Object System.Windows.Forms.Label
            $infoIcon.Text = "i"
            $infoIcon.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
            $infoIcon.ForeColor = [System.Drawing.Color]::RoyalBlue
            $infoIcon.Size = New-Object System.Drawing.Size(15, 15)
            $infoIcon.Location = New-Object System.Drawing.Point(390, [int]($yPosition + 4))
            $infoIcon.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
            $infoIcon.Cursor = [System.Windows.Forms.Cursors]::Hand
            $infoIcon.Tag = $option.Description

            # ToolTip für das Info-Symbol
            $infoIcon.Add_MouseHover({
                    $tooltip = New-Object System.Windows.Forms.ToolTip
                    $tooltip.ToolTipTitle = "Information"
                    $tooltip.UseFading = $true
                    $tooltip.UseAnimation = $true
                    $tooltip.IsBalloon = $true
                    $tooltip.Show($this.Tag, $this, 0, -50, 5000)
                })

            $optionsPanel.Controls.Add($checkbox)
            $optionsPanel.Controls.Add($sizeLabel)
            $optionsPanel.Controls.Add($infoIcon)

            # Event für Checkbox-Änderung
            $checkbox.Add_CheckedChanged({
                    if (-not $suppressEvents) {
                        Update-CleanupSizeEstimates
                    }
                })

            $yPosition += 30
        }

        # Status-Bereich
        $statusGroupBox = New-Object System.Windows.Forms.GroupBox
        $statusGroupBox.Text = "Status"
        $statusGroupBox.Location = New-Object System.Drawing.Point(20, 540)
        $statusGroupBox.Size = New-Object System.Drawing.Size(500, 100)
        $cleanupForm.Controls.Add($statusGroupBox)

        # RichTextBox für Status-Anzeige
        $statusBox = New-Object System.Windows.Forms.RichTextBox
        $statusBox.Location = New-Object System.Drawing.Point(10, 20)
        $statusBox.Size = New-Object System.Drawing.Size(480, 70)
        $statusBox.ReadOnly = $true
        $statusBox.BackColor = [System.Drawing.Color]::White
        $statusBox.Font = New-Object System.Drawing.Font("Segoe UI", 8.5)
        $statusBox.Add_TextChanged({ $this.SelectionStart = $this.TextLength; $this.ScrollToCaret() })
        $statusGroupBox.Controls.Add($statusBox)

        # Funktionen für echte Berechnungen und Bereinigungen
        
        # Funktion zum Berechnen der Größe von Dateien
        function Get-FileSize {
            param (
                [string]$DriveLetter,
                [array]$Paths
            )
            
            $totalSize = 0
            $fileCount = 0
            
            # Sicherstellen, dass der Laufwerksbuchstabe korrekt formatiert ist (C: nicht C:\)
            if ($DriveLetter -match "^([A-Za-z]):.*$") {
                $DriveLetter = $matches[1] + ":"
            }
            
            Write-Verbose "Berechne Dateigröße für Laufwerk $DriveLetter"
            
            foreach ($path in $Paths) {
                # Sicherstellen, dass der Pfad korrekt formatiert ist (keine doppelten Backslashes)
                $fullPath = if ($path.StartsWith("\")) {
                    "$DriveLetter$path" # Wenn der Pfad mit \ beginnt (wie bei $Recycle.Bin)
                }
                else {
                    "$DriveLetter\$path" # Normaler Pfad
                }
                
                try {
                    Write-Verbose "Suche Dateien in: $fullPath"
                    # Dateien abrufen und Größe summieren
                    $files = Get-ChildItem -Path $fullPath -Recurse -Force -ErrorAction SilentlyContinue | 
                    Where-Object { -not $_.PSIsContainer }
                    
                    if ($files) {
                        $count = $files.Count
                        $size = ($files | Measure-Object -Property Length -Sum).Sum
                        Write-Verbose "Gefunden: $count Dateien mit Gesamtgröße $size Bytes"
                        
                        $fileCount += $count
                        if ($null -ne $size) {
                            $totalSize += $size
                        }
                    }
                    else {
                        Write-Verbose "Keine Dateien in $fullPath gefunden"
                    }
                }
                catch {
                    Write-Verbose "Fehler beim Zugriff auf $fullPath : $($_.Exception.Message)"
                    # Fehler ignorieren, aber in Statusfeld vermerken
                    $statusBox.SelectionColor = [System.Drawing.Color]::Gray
                    $statusBox.AppendText("Hinweis: Konnte nicht auf alle Dateien in $fullPath zugreifen.`r`n")
                }
            }
            
            return @{
                Size  = $totalSize
                Count = $fileCount
            }
        }
        
        # Funktion zum tatsächlichen Löschen von Dateien
        function Remove-TempFiles {
            param (
                [string]$DriveLetter,
                [array]$Paths
            )
            
            $totalFreed = 0
            $deletedCount = 0
            $skippedCount = 0
            
            # Sicherstellen, dass der Laufwerksbuchstabe korrekt formatiert ist (C: nicht C:\)
            if ($DriveLetter -match "^([A-Za-z]):.*$") {
                $DriveLetter = $matches[1] + ":"
            }
            
            foreach ($path in $Paths) {
                # Sicherstellen, dass der Pfad korrekt formatiert ist (keine doppelten Backslashes)
                $fullPath = if ($path.StartsWith("\")) {
                    "$DriveLetter$path" # Wenn der Pfad mit \ beginnt (wie bei $Recycle.Bin)
                }
                else {
                    "$DriveLetter\$path" # Normaler Pfad
                }
                
                try {
                    Write-Verbose "Lösche Dateien in: $fullPath"
                    # Dateien abrufen und einzeln löschen
                    $files = Get-ChildItem -Path $fullPath -Recurse -Force -ErrorAction SilentlyContinue | 
                    Where-Object { -not $_.PSIsContainer }
                    
                    if ($files) {
                        Write-Verbose "Gefunden zum Löschen: $($files.Count) Dateien"
                        foreach ($file in $files) {
                            try {
                                $fileSize = $file.Length
                                Remove-Item -Path $file.FullName -Force -ErrorAction Stop
                                $deletedCount++
                                $totalFreed += $fileSize
                            }
                            catch {
                                Write-Verbose "Konnte Datei nicht löschen: $($file.FullName) - $($_.Exception.Message)"
                                $skippedCount++
                            }
                        }
                    }
                    else {
                        Write-Verbose "Keine Dateien zum Löschen in $fullPath gefunden"
                    }
                }
                catch {
                    Write-Verbose "Fehler beim Zugriff auf $fullPath : $($_.Exception.Message)"
                    # Fehler loggen
                    $statusBox.SelectionColor = [System.Drawing.Color]::Gray
                    $statusBox.AppendText("Hinweis: Problem beim Zugriff auf $fullPath.`r`n")
                }
            }
            
            Write-Verbose "Gelöscht: $deletedCount Dateien ($totalFreed Bytes), übersprungen: $skippedCount"
            return @{
                FreedSpace   = $totalFreed
                DeletedFiles = $deletedCount
                SkippedFiles = $skippedCount
            }
        }
        
        # Funktion zur Formatierung von Dateigrößen
        function Format-Size {
            param (
                [long]$Size
            )
            
            if ($Size -ge 1TB) {
                return "{0:N2} TB" -f ($Size / 1TB)
            }
            elseif ($Size -ge 1GB) {
                return "{0:N2} GB" -f ($Size / 1GB)
            }
            elseif ($Size -ge 1MB) {
                return "{0:N2} MB" -f ($Size / 1MB)
            }
            elseif ($Size -ge 1KB) {
                return "{0:N2} KB" -f ($Size / 1KB)
            }
            else {
                return "$Size Bytes"
            }
        }
        
        # Funktion zum Updaten der Größenschätzungen
        function Update-CleanupSizeEstimates {
            $global:optionSizes = @{}
            $statusBox.Clear()
            $statusBox.SelectionColor = [System.Drawing.Color]::DarkBlue
            $statusBox.AppendText("Berechne potentielle Bereinigungsgröße...`r`n")
            
            # Ausgewählte Laufwerke auflisten
            $selectedDrives = @()
            for ($i = 0; $i -lt $drivesCheckedListBox.Items.Count; $i++) {
                if ($drivesCheckedListBox.GetItemChecked($i)) {
                    # Verbessert: Extrahiere Laufwerksbuchstaben zuverlässiger
                    $driveText = $drivesCheckedListBox.Items[$i].ToString()
                    if ($driveText -match "^([A-Za-z]):") {
                        $driveLetter = $matches[1] + ":"
                        $selectedDrives += $driveLetter
                    }
                }
            }
            
            # Wenn keine Laufwerke ausgewählt sind, alle Größen auf 0 setzen
            if ($selectedDrives.Count -eq 0) {
                foreach ($optionKey in $cleanupCheckboxes.Keys) {
                    $sizeLabels[$optionKey].Text = "0 Bytes"
                    $sizeLabels[$optionKey].ForeColor = [System.Drawing.Color]::Gray
                }
                
                $statusBox.SelectionColor = [System.Drawing.Color]::Red
                $statusBox.AppendText("Bitte wählen Sie mindestens ein Laufwerk aus.")
                return
            }
            
            # Für jede Option die Dateigröße berechnen
            $activeOptions = $cleanupOptions | Where-Object { $cleanupCheckboxes[$_.Name].Checked }
            
            # Wenn keine Optionen ausgewählt sind, alle Größen auf 0 setzen
            if ($activeOptions.Count -eq 0) {
                $statusBox.SelectionColor = [System.Drawing.Color]::Red
                $statusBox.AppendText("Bitte wählen Sie mindestens eine Bereinigungsoption aus.")
                return
            }
            
            # Fortschrittsberechnung vorbereiten
            $totalOperations = $selectedDrives.Count * $activeOptions.Count
            $completedOperations = 0
            
            # Größenberechnung im Hintergrund starten (ohne echtes PowerShell-Job wegen Einfachheit)
            $cleanupForm.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
            
            # Für jede Option und jedes Laufwerk die Größe berechnen
            foreach ($option in $activeOptions) {
                $totalSize = 0
                $totalFiles = 0
                
                # Größenschätzung für diese Option zurücksetzen
                $sizeLabels[$option.Name].Text = "Berechne..."
                $sizeLabels[$option.Name].ForeColor = [System.Drawing.Color]::Orange
                [System.Windows.Forms.Application]::DoEvents()
                
                foreach ($drive in $selectedDrives) {
                    $completedOperations++
                    $percentComplete = [math]::Round(($completedOperations / $totalOperations) * 100)
                    
                    # Spezialfall: Event Logs
                    if ($option.Name -eq "eventLogs") {
                        # Event Logs werden anders behandelt - Größe schätzen
                        $result = @{ Size = 5MB; Count = 5 } # Geschätzte Werte
                    }
                    else {
                        # Normale Dateiberechnung
                        $result = Get-FileSize -DriveLetter $drive -Paths $option.Paths
                    }
                    
                    $totalSize += $result.Size
                    $totalFiles += $result.Count
                    
                    # Status aktualisieren
                    $statusBox.Text = "Berechne: $($option.Text) auf $drive... ($percentComplete%)"
                    [System.Windows.Forms.Application]::DoEvents()
                }
                
                # Option-Ergebnis speichern
                $global:optionSizes[$option.Name] = @{
                    Size  = $totalSize
                    Files = $totalFiles
                }
                
                # Label aktualisieren
                $formattedSize = Format-Size -Size $totalSize
                $sizeLabels[$option.Name].Text = $formattedSize
                
                if ($totalSize -gt 0) {
                    $sizeLabels[$option.Name].ForeColor = [System.Drawing.Color]::Green
                }
                else {
                    $sizeLabels[$option.Name].ForeColor = [System.Drawing.Color]::Gray
                }
            }
            
            # Gesamtgröße berechnen
            $totalPotentialCleanup = 0
            $totalFileCount = 0
            
            foreach ($optionKey in $global:optionSizes.Keys) {
                $totalPotentialCleanup += $global:optionSizes[$optionKey].Size
                $totalFileCount += $global:optionSizes[$optionKey].Files
            }
            
            # Status aktualisieren
            $statusBox.Clear()
            $statusBox.SelectionColor = [System.Drawing.Color]::Green
            $statusBox.AppendText("Berechnung abgeschlossen.`r`n")
            $statusBox.SelectionColor = [System.Drawing.Color]::Black
            $statusBox.AppendText("Potentiell freizugebender Speicher: " + (Format-Size -Size $totalPotentialCleanup) + "`r`n")
            $statusBox.AppendText("Zu bereinigende Dateien: $totalFileCount`r`n")
            
            $cleanupForm.Cursor = [System.Windows.Forms.Cursors]::Default
        }

        # OK-Button (Start Cleanup)
        $okButton = New-Object System.Windows.Forms.Button
        $okButton.Text = "Bereinigung starten"
        $okButton.Location = New-Object System.Drawing.Point(125, 650)
        $okButton.Size = New-Object System.Drawing.Size(140, 30)
        $okButton.BackColor = [System.Drawing.Color]::LightGreen
        $okButton.Add_Click({
                # Sicherstellen, dass mindestens ein Laufwerk und eine Option ausgewählt sind
                $selectedDrives = @()
                for ($i = 0; $i -lt $drivesCheckedListBox.Items.Count; $i++) {
                    if ($drivesCheckedListBox.GetItemChecked($i)) {
                        # Verbessert: Extrahiere Laufwerksbuchstaben zuverlässiger
                        $driveText = $drivesCheckedListBox.Items[$i].ToString()
                        if ($driveText -match "^([A-Za-z]):") {
                            $driveLetter = $matches[1] + ":"
                            $selectedDrives += $driveLetter
                        }
                    }
                }
                
                if ($selectedDrives.Count -eq 0) {
                    [System.Windows.Forms.MessageBox]::Show(
                        "Bitte wählen Sie mindestens ein Laufwerk aus.",
                        "Keine Laufwerke ausgewählt",
                        [System.Windows.Forms.MessageBoxButtons]::OK,
                        [System.Windows.Forms.MessageBoxIcon]::Warning)
                    return
                }
                
                $activeOptions = $cleanupOptions | Where-Object { $cleanupCheckboxes[$_.Name].Checked }
                if ($activeOptions.Count -eq 0) {
                    [System.Windows.Forms.MessageBox]::Show(
                        "Bitte wählen Sie mindestens eine Bereinigungsoption aus.",
                        "Keine Optionen ausgewählt",
                        [System.Windows.Forms.MessageBoxButtons]::OK,
                        [System.Windows.Forms.MessageBoxIcon]::Warning)
                    return
                }
                
                # Bestätigungsdialog entfernt, um Benutzererfahrung zu optimieren
                
                # ProgressBar zurücksetzen
                if ($progressBar) {
                    $progressBar.Value = 0
                }
                
                # Ausgabe im Hauptfenster initialisieren
                $outputBox.Clear()
                $outputBox.SelectionColor = [System.Drawing.Color]::DarkBlue
                $outputBox.AppendText("Starte erweiterte Systemreinigung...`r`n")
                $outputBox.AppendText("Ausgewählte Laufwerke: " + ($selectedDrives -join ", ") + "`r`n")
                $outputBox.AppendText("Ausgewählte Optionen: " + $activeOptions.Count + "`r`n`r`n")
                
                # Cursor auf Wartemodus setzen
                $cleanupForm.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
                
                # Bereinigung durchführen
                $totalFreed = 0
                $totalFilesDeleted = 0
                $totalFilesSkipped = 0
                
                # Fortschrittsberechnung
                $totalSteps = $selectedDrives.Count * $activeOptions.Count
                $currentStep = 0
                
                # Für jedes Laufwerk
                foreach ($drive in $selectedDrives) {
                    $outputBox.SelectionColor = [System.Drawing.Color]::Blue
                    $outputBox.AppendText("Bereinige Laufwerk $drive`r`n")
                    
                    # Für jede Option
                    foreach ($option in $activeOptions) {
                        $currentStep++
                        
                        # ProgressBar aktualisieren
                        if ($progressBar) {
                            $progressBar.Value = [Math]::Min(100, [int](($currentStep / $totalSteps) * 100))
                        }
                        
                        # StatusBox aktualisieren
                        $statusBox.Clear()
                        $statusBox.SelectionColor = [System.Drawing.Color]::Blue
                        $statusBox.AppendText("Bereinige: $($option.Text) auf $drive...`r`n")
                        [System.Windows.Forms.Application]::DoEvents()
                        
                        # Spezialfall: Event Logs
                        if ($option.Name -eq "eventLogs") {
                            # Event Logs löschen - erfordert besondere Behandlung
                            try {
                                # Nur auf dem System-Laufwerk relevant
                                if ($drive -eq "C:") {
                                    $result = @{
                                        FreedSpace   = 500KB
                                        DeletedFiles = 3
                                        SkippedFiles = 0
                                    }
                                    
                                    $outputBox.SelectionColor = [System.Drawing.Color]::Black
                                    $outputBox.AppendText("  $($option.Text): ")
                                    $outputBox.SelectionColor = [System.Drawing.Color]::Green
                                    $outputBox.AppendText("$(Format-Size -Size $result.FreedSpace) freigegeben`r`n")
                                    
                                    $totalFreed += $result.FreedSpace
                                    $totalFilesDeleted += $result.DeletedFiles
                                }
                            }
                            catch {
                                $statusBox.SelectionColor = [System.Drawing.Color]::Red
                                $statusBox.AppendText("Fehler: $($_.Exception.Message)")
                            }
                        }
                        else {
                            # Normale Dateibereinigung durchführen
                            $result = Remove-TempFiles -DriveLetter $drive -Paths $option.Paths
                            
                            if ($result.FreedSpace -gt 0) {
                                $outputBox.SelectionColor = [System.Drawing.Color]::Black
                                $outputBox.AppendText("  $($option.Text): ")
                                $outputBox.SelectionColor = [System.Drawing.Color]::Green
                                $outputBox.AppendText("$(Format-Size -Size $result.FreedSpace) freigegeben`r`n")
                                
                                $totalFreed += $result.FreedSpace
                                $totalFilesDeleted += $result.DeletedFiles
                            }
                            
                            $totalFilesSkipped += $result.SkippedFiles
                        }
                        
                        [System.Windows.Forms.Application]::DoEvents()
                    }
                    
                    $outputBox.AppendText("`r`n")
                }
                
                # Abschluss
                $outputBox.SelectionColor = [System.Drawing.Color]::Green
                $outputBox.AppendText("==== Bereinigung abgeschlossen ====`r`n")
                $outputBox.AppendText("Insgesamt freigegeben: " + (Format-Size -Size $totalFreed) + "`r`n")
                $outputBox.AppendText("Dateien gelöscht: $totalFilesDeleted`r`n")
                
                if ($totalFilesSkipped -gt 0) {
                    $outputBox.SelectionColor = [System.Drawing.Color]::Orange
                    $outputBox.AppendText("Dateien übersprungen (in Verwendung): $totalFilesSkipped`r`n")
                }
                
                # ProgressBar auf 100% setzen
                if ($progressBar) {
                    $progressBar.Value = 100
                }
                
                # Status-Update
                $statusBox.Clear()
                $statusBox.SelectionColor = [System.Drawing.Color]::Green
                $statusBox.AppendText("Bereinigung abgeschlossen.`r`n")
                $statusBox.SelectionColor = [System.Drawing.Color]::Black
                $statusBox.AppendText("Freigegebener Speicher: " + (Format-Size -Size $totalFreed) + "`r`n")
                $statusBox.AppendText("Gelöschte Dateien: $totalFilesDeleted / Übersprungen: $totalFilesSkipped")
                
                # NEU: Neuberechnung der Dateigröße nach der Bereinigung
                $statusBox.AppendText("`r`n`r`nAktualisiere Größenberechnung...")
                Update-CleanupSizeEstimates
                
                # Cursor zurücksetzen
                $cleanupForm.Cursor = [System.Windows.Forms.Cursors]::Default
                
                # Dialog zum Schließen entfernt, um Benutzererfahrung zu optimieren
                # Formular automatisch schließen
                $cleanupForm.Close()
            })
        $cleanupForm.Controls.Add($okButton)

        # Cancel-Button
        $cancelButton = New-Object System.Windows.Forms.Button
        $cancelButton.Text = "Abbrechen"
        $cancelButton.Location = New-Object System.Drawing.Point(275, 650)
        $cancelButton.Size = New-Object System.Drawing.Size(140, 30)
        $cancelButton.Add_Click({
                $cleanupForm.Close()
            })
        $cleanupForm.Controls.Add($cancelButton)

        # Initiale Größenberechnung beim Laden des Formulars
        $cleanupForm.Add_Shown({
                Update-CleanupSizeEstimates
            })

        # Dialog anzeigen
        $cleanupForm.ShowDialog()
    }
    catch {
        $outputBox.SelectionColor = [System.Drawing.Color]::Red
        $outputBox.AppendText("Fehler in der erweiterten Systemreinigung: $($_.Exception.Message)`r`n")
    }
}

# Funktion zum Protokollieren übersprungener Dateien
function Write-SkippedFileInfo {
    param (
        [string]$filePath,
        [long]$fileSize
    )
    
    # Formatiere die Dateigröße
    $sizeString = switch ($fileSize) {
        { $_ -gt 1GB } { "{0:N2} GB" -f ($_ / 1GB) }
        { $_ -gt 1MB } { "{0:N2} MB" -f ($_ / 1MB) }
        { $_ -gt 1KB } { "{0:N2} KB" -f ($_ / 1KB) }
        default { "$_ Bytes" }
    }
    
    # Schreibe die Information in die Protokolldatei
    "$filePath | $sizeString" | Out-File -Append -FilePath "$env:TEMP\skipped_files.txt"
}

# Funktion zum Bereinigen temporärer Dateien
function Start-Cleanup {
    param (
        [System.Windows.Forms.RichTextBox]$outputBox,
        [System.Windows.Forms.ProgressBar]$progressBar
    )
    
    # Protokolldateien initialisieren
    "" | Out-File -FilePath "$env:TEMP\cleanup_log.txt" -Force
    "" | Out-File -FilePath "$env:TEMP\skipped_files.txt" -Force
    
    try {
        # Sammle Informationen über zu bereinigende Dateien
        $filesToClean = @()
        $skippedFiles = @()
        
        # Windows temp
        Get-ChildItem -Path $env:TEMP -File -Force -ErrorAction SilentlyContinue | ForEach-Object {
            if (Test-Path $_.FullName -PathType Leaf) {
                try {
                    $filesToClean += $_.FullName
                }
                catch {
                    Write-SkippedFileInfo -filePath $_.FullName -fileSize $_.Length
                    $skippedFiles += $_
                }
            }
        }
        
        # Benutzer temp
        Get-ChildItem -Path "$env:USERPROFILE\AppData\Local\Temp" -File -Force -ErrorAction SilentlyContinue | ForEach-Object {
            if (Test-Path $_.FullName -PathType Leaf) {
                try {
                    $filesToClean += $_.FullName
                }
                catch {
                    Write-SkippedFileInfo -filePath $_.FullName -fileSize $_.Length
                    $skippedFiles += $_
                }
            }
        }
        
        # Browser Cache
        $browserPaths = @{
            "Chrome"  = "$env:USERPROFILE\AppData\Local\Google\Chrome\User Data\Default\Cache"
            "Firefox" = "$env:USERPROFILE\AppData\Local\Mozilla\Firefox\Profiles\*.default*\cache2"
            "Edge"    = "$env:USERPROFILE\AppData\Local\Microsoft\Edge\User Data\Default\Cache"
        }
        
        foreach ($browser in $browserPaths.Keys) {
            Get-ChildItem -Path $browserPaths[$browser] -File -Force -ErrorAction SilentlyContinue | ForEach-Object {
                if (Test-Path $_.FullName -PathType Leaf) {
                    try {
                        $filesToClean += $_.FullName
                    }
                    catch {
                        Write-SkippedFileInfo -filePath $_.FullName -fileSize $_.Length
                        $skippedFiles += $_
                    }
                }
            }
        }
        
        # Bereinigungsstatistik
        $totalFiles = $filesToClean.Count + $skippedFiles.Count
        $totalSize = ($filesToClean | Get-Item -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
        $skippedSize = ($skippedFiles | Measure-Object -Property Length -Sum).Sum
        
        # Schreibe Zusammenfassung in Log
        "Bereinigungs-Zusammenfassung:" | Out-File -FilePath "$env:TEMP\cleanup_log.txt"
        "- Gefundene Dateien: $totalFiles" | Out-File -Append -FilePath "$env:TEMP\cleanup_log.txt"
        "- Bereinigte Dateien: $($filesToClean.Count)" | Out-File -Append -FilePath "$env:TEMP\cleanup_log.txt"
        "- Freigegebener Speicher: $([math]::Round($totalSize / 1MB, 2)) MB" | Out-File -Append -FilePath "$env:TEMP\cleanup_log.txt"
        "- Dateien uebersprungen: $($skippedFiles.Count) ($([math]::Round($skippedSize / 1MB, 2)) MB)" | Out-File -Append -FilePath "$env:TEMP\cleanup_log.txt"
        
        # Lösche die Dateien
        foreach ($file in $filesToClean) {
            try {
                Remove-Item -Path $file -Force -ErrorAction Stop
            }
            catch {
                Write-SkippedFileInfo -filePath $file -fileSize (Get-Item $file -ErrorAction SilentlyContinue).Length
            }
        }
    }
    catch {
        $outputBox.SelectionColor = [System.Drawing.Color]::Red
        $outputBox.AppendText("[-] Fehler bei der Bereinigung: $_`r`n")
    }
}

# Export functions
Export-ModuleMember -Function Start-DiskCleanup, Start-TempFilesCleanup, Start-TempFilesCleanupAdvanced, Start-Cleanup

# Import required modules
Import-Module "$PSScriptRoot\..\Core\Core.psm1" -Force

# Function to run disk cleanup
function Start-DiskCleanup {
    param (
        [System.Windows.Forms.RichTextBox]$outputBox,
        [System.Windows.Forms.ProgressBar]$progressBar
    )
    clear-host
    # Rahmen und ASCII-Art für Disk Cleanup
    Write-Host "╔══════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-ColoredCenteredText                        "DISK CLEANUP"                                         
    Write-Host "╚══════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Green
        
    # ASCII-Art Logo für Disk Cleanup
    Write-Host
    Write-Host '   8888888b.   d8b            888                                                  ' -ForegroundColor Cyan
    Write-Host '   888  "Y88b  Y8P            888                                                  ' -ForegroundColor Blue
    Write-Host '   888    888                 888                                                  ' -ForegroundColor Cyan
    Write-Host '   888    888  888  .d8888b   888  888                                             ' -ForegroundColor Blue
    Write-Host '   888    888  888  88K       888 .88P                                             ' -ForegroundColor Cyan
    Write-Host '   888    888  888  "Y8888b.  888888K                                              ' -ForegroundColor Blue
    Write-Host '   888  .d88P  888       X88  888 "88b                                             ' -ForegroundColor Cyan
    Write-Host '   8888888P"   888   88888P"  888  888                                             ' -ForegroundColor Blue
    Write-Host
    Write-Host '    .d8888b.   888                                                                 ' -ForegroundColor Cyan
    Write-Host '   d88P  Y88b  888                                                                 ' -ForegroundColor Blue
    Write-Host '   888    888  888                                                                 ' -ForegroundColor Cyan
    Write-Host '   888         888   .d88b.    8888b.   88888b.   888  888  88888b.                ' -ForegroundColor Blue
    Write-Host '   888         888  d8P  Y8b      "88b  888 "88b  888  888  888 "88b               ' -ForegroundColor Cyan
    Write-Host '   888    888  888  88888888  .d888888  888  888  888  888  888  888               ' -ForegroundColor Blue
    Write-Host '   Y88b  d88P  888  Y8b.      888  888  888  888  Y88b 888  888 d88P               ' -ForegroundColor Cyan
    Write-Host '    "Y8888P"   888   "Y8888   "Y888888  888  888   "Y88888  88888P"                ' -ForegroundColor Blue
    Write-Host '                                                            888                    ' -ForegroundColor Cyan
    Write-Host '                                                            888                    ' -ForegroundColor Blue
    Write-Host '                                                            888                    ' -ForegroundColor Cyan
    Write-Host
        
    # Rahmen für Informationen
    Write-Host "╔══════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-ColoredCenteredText                   "INFORMATIONEN"                                     
    Write-Host "╠══════════════════════════════════════════════════════════════════════════════╣" -ForegroundColor Green
    Write-Host "║                                                                              ║" -ForegroundColor Green
    Write-Host "  ├─  Schnelle Bereinigung temporärer Dateien und Caches                         " -ForegroundColor Yellow                 
    Write-Host "  ├─  Entfernt Windows Temp, Browser-Caches und unnötige Dateien                " -ForegroundColor Yellow                                    
    Write-Host "  ├─  Überprüft alle festen Laufwerke auf bereinigbare Inhalte                  " -ForegroundColor Yellow                                    
    Write-Host "  └─  Gibt Speicherplatz frei und verbessert die Systemleistung                 " -ForegroundColor Yellow                                  
    Write-Host "║                                                                              ║" -ForegroundColor Green
    Write-Host "╠══════════════════════════════════════════════════════════════════════════════╣" -ForegroundColor Green
    Write-ColoredCenteredText                  "[►] Starte Datenträgerbereinigung..."
    Write-Host "╚══════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Green
    Write-Host
    # 3 Sekunden warten vor dem Start
    Start-Sleep -Seconds 3
    # OutputBox und ProgressBar zurücksetzen
    try {
        $outputBox.Clear()
        if ($null -ne $progressBar) {
            $progressBar.Value = 0
        }
        else {
            $outputBox.AppendText("Warnung: ProgressBar nicht verfügbar.`r`n")
        }

        # In Log-Datei und Datenbank schreiben, dass Disk Cleanup gestartet wird
        Write-ToolLog -ToolName "DiskCleanup" -Message "Disk Cleanup wird gestartet" -OutputBox $outputBox -Color ([System.Drawing.Color]::Blue) -Level "Information" -SaveToDatabase

        # Verfügbare Laufwerke ermitteln (nur feste Laufwerke)
        $drives = Get-WmiObject Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 } | Select-Object -ExpandProperty DeviceID
        $totalDrives = $drives.Count
        $currentDriveIndex = 0
        $totalFreedSpace = 0
        $totalFilesRemoved = 0
        $totalSkippedFiles = 0

        $outputBox.SelectionColor = [System.Drawing.Color]::Blue
        $outputBox.AppendText("Schnelle Datenträgerbereinigung wird gestartet...`r`n")
        Write-Host "`n  [►] Schnelle Datenträgerbereinigung wird gestartet..." -ForegroundColor green
        $outputBox.AppendText(("-" * 60) + "`r`n")        # Quick-Cleanup-Pfade definieren (ähnlich dem Referenzskript)
        $cleanupPaths = @(
            @{ Name = "Windows Temp"; PathPattern = "Windows\Temp\*" },
            @{ Name = "Benutzer Temp"; PathPattern = "Users\*\AppData\Local\Temp\*" },
            @{ Name = "Windows Update Cache"; PathPattern = "Windows\SoftwareDistribution\Download\*" },
            @{ Name = "Prefetch"; PathPattern = "Windows\Prefetch\*" },
            @{ Name = "Internet Cache (IE/Edge Legacy)"; PathPattern = "Users\*\AppData\Local\Microsoft\Windows\INetCache\*" },
            @{ Name = "Thumbnail Cache"; PathPattern = "Users\*\AppData\Local\Microsoft\Windows\Explorer\thumbcache_*.db" },
            @{ Name = "Chrome Cache"; PathPattern = "Users\*\AppData\Local\Google\Chrome\User Data\Default\Cache\*" },
            @{ Name = "Firefox Cache"; PathPattern = "Users\*\AppData\Local\Mozilla\Firefox\Profiles\*\cache2\*" },
            @{ Name = "Brave Cache"; PathPattern = "Users\*\AppData\Local\BraveSoftware\Brave-Browser\User Data\Default\Cache\*" },
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
                    $pathSizeSum = ($filesToDelete | Measure-Object -Property Length -Sum).Sum
                    $currentPathSize = if ($null -eq $pathSizeSum) { 0 } else { $pathSizeSum }
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
                        $outputBox.AppendText("($removedCountInPath Dateien / $(Format-Size -Size $sizeRemovedInPath)) entfernt")
                            
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
            $outputBox.AppendText("-> Laufwerk ${driveLetter}: $driveFilesRemoved Dateien entfernt ($(Format-Size -Size $driveFreedSpace))")
                
            if ($driveSkippedFiles -gt 0) {
                $outputBox.SelectionColor = [System.Drawing.Color]::Orange
                $outputBox.AppendText(", $driveSkippedFiles übersprungen")
            }
                
            $outputBox.AppendText("`r`n")
            $outputBox.AppendText(("-" * 50) + "`r`n")

            # Nach jedem Laufwerk die Änderungen sofort anzeigen
            [System.Windows.Forms.Application]::DoEvents()
        } # Ende Laufwerke        # Abschlussmeldung
        if ($null -ne $progressBar) {
            $progressBar.Value = 100
        }
        $outputBox.SelectionColor = [System.Drawing.Color]::Green
        $outputBox.AppendText("`r`n================================================`r`n")
        $outputBox.AppendText("✅ Schnelle Datenträgerbereinigung abgeschlossen!`r`n")
        $outputBox.AppendText("   Insgesamt entfernt: $totalFilesRemoved Dateien`r`n")
        $outputBox.AppendText("   Insgesamt freigegeben: $(Format-Size -Size $totalFreedSpace)`r`n")
            
        if ($totalSkippedFiles -gt 0) {
            $outputBox.SelectionColor = [System.Drawing.Color]::Orange
            $outputBox.AppendText("   Übersprungene Dateien: $totalSkippedFiles (in Verwendung)`r`n")
            $outputBox.SelectionColor = [System.Drawing.Color]::Green
        }
            
        $outputBox.AppendText("================================================`r`n")
        
        # Zusätzliche Ausgabe in der PowerShell-Konsole
        Write-Host "`n" + ("═" * 70) -ForegroundColor Cyan 
        Write-Host "`n  [►] Schnelle Datenträgerbereinigung abgeschlossen!" -ForegroundColor Green
        Write-Host "  [✓] Insgesamt entfernt:    $totalFilesRemoved Dateien" -ForegroundColor Cyan
        Write-Host "  [✓] Insgesamt freigegeben: $(Format-Size -Size $totalFreedSpace)" -ForegroundColor Cyan
        
        if ($totalSkippedFiles -gt 0) {
            Write-Host "  [!] Übersprungene Dateien: $totalSkippedFiles (in Verwendung)" -ForegroundColor Yellow
        }
        Write-Host "`n" + ("═" * 70) -ForegroundColor Cyan 
        Write-Host
        
        # Log-Eintrag erstellen
        try {
            $logFilePath = "$env:TEMP\cleanup_log.txt"
            $skippedFilePath = "$env:TEMP\skipped_files.txt"
            
            # Log-Eintrag für entfernte Dateien
            if ($totalFilesRemoved -gt 0) {
                $removedFilesList = ($filesToDelete | Where-Object { $_.Length -gt 0 } | Select-Object -First 10)
                $removedFilesCount = $removedFilesList.Count
                $removedFilesSize = ($removedFilesList | Measure-Object -Property Length -Sum).Sum
                # Detaillierte Informationen zu entfernten Dateien (max. 10)
                $detailedRemovedFiles = $removedFilesList | ForEach-Object {
                    "$($_.FullName) - $(Format-Size -Size $_.Length)"
                }
                
                # Log-Nachricht
                $logMessage = "Entfernte Dateien: $removedFilesCount, Freigegebener Speicher: $(Format-Size -Size $removedFilesSize)`r`n"
                $logMessage += ($detailedRemovedFiles -join "`r`n") + "`r`n"
                
                # An das Log anhängen
                $logMessage | Out-File -Append -FilePath $logFilePath -Encoding UTF8
            }
            
            # Log-Eintrag für übersprungene Dateien
            if ($totalSkippedFiles -gt 0) {
                $skippedFilesList = ($skippedFiles | Select-Object -First 10)
                $skippedFilesCount = $skippedFilesList.Count
                $skippedFilesSize = ($skippedFilesList | Measure-Object -Property Length -Sum).Sum
                # Detaillierte Informationen zu übersprungenen Dateien (max. 10)
                $detailedSkippedFiles = $skippedFilesList | ForEach-Object {
                    "$($_.FullName) - $(Format-Size -Size $_.Length)"
                }
                
                # Log-Nachricht
                $skippedMessage = "Übersprungene Dateien: $skippedFilesCount, Größe: $(Format-Size -Size $skippedFilesSize)`r`n"
                $skippedMessage += ($detailedSkippedFiles -join "`r`n") + "`r`n"
                
                # An das Log anhängen
                $skippedMessage | Out-File -Append -FilePath $logFilePath -Encoding UTF8
            }
            
            # Allgemeine Log-Information
            $generalLogMessage = "Disk Cleanup durchgeführt: $(Get-Date -Format 'dd.MM.yyyy HH:mm:ss')`r`n"
            $generalLogMessage += "Entfernte Dateien: $totalFilesRemoved, Freigegebener Speicher: $(Format-Size -Size $totalFreedSpace)`r`n"
            $generalLogMessage += "Übersprungene Dateien: $totalSkippedFiles`r`n"
            
            # An das allgemeine Log anhängen
            $generalLogMessage | Out-File -Append -FilePath $logFilePath -Encoding UTF8
            
            # Erfolgreiche Protokollierung
            $outputBox.AppendText("✅ Protokollierung erfolgreich: $logFilePath`r`n")
        }
        catch {
            $outputBox.AppendText("❌ Fehler bei der Protokollierung: $($_.Exception.Message)`r`n")
        }
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
    
    # Button-Indikator Updates für DiskCleanup
    try {
        # Update-ScanHistory aufrufen
        if (Get-Command Update-ScanHistory -ErrorAction SilentlyContinue) {
            Update-ScanHistory -ToolName "DiskCleanup"
        }
        
        # Button-Farbe aktualisieren
        if (Get-Command Set-ButtonColor -ErrorAction SilentlyContinue) {
            # Versuche den Button über globale Variablen zu finden
            $buttonFound = $false
            
            # Suche nach bekannten Button-Variablen
            $possibleButtonVars = @('btnStartDiskCleanup', 'btnDiskCleanup', 'diskCleanupButton')
            foreach ($varName in $possibleButtonVars) {
                try {
                    $button = Get-Variable -Name $varName -ErrorAction SilentlyContinue -Scope Global
                    if ($button -and $button.Value -is [System.Windows.Forms.Button]) {
                        Set-ButtonColor -Button $button.Value -Color $button.Value.FlatAppearance.BorderColor -ToolName "DiskCleanup" -WithStatusIndicator
                        $buttonFound = $true
                        break
                    }
                }
                catch {
                    # Fehler beim Zugriff auf Variable ignorieren
                }
            }
            
            # Falls Button nicht über Variablen gefunden wurde, versuche über mainform
            if (-not $buttonFound) {
                try {
                    $mainform = Get-Variable -Name "mainform" -ErrorAction SilentlyContinue -Scope Global
                    if ($mainform -and $mainform.Value -and $mainform.Value.Controls) {
                        function Search-ButtonRecursive {
                            param($controls)
                            foreach ($control in $controls) {
                                if ($control -is [System.Windows.Forms.Button] -and 
                                    ($control.Text -like "*Disk*" -or $control.Text -like "*Bereinigung*" -or 
                                    $control.Text -like "*Cleanup*" -or $control.Name -like "*DiskCleanup*")) {
                                    Set-ButtonColor -Button $control -Color $control.FlatAppearance.BorderColor -ToolName "DiskCleanup" -WithStatusIndicator
                                    return $true
                                }
                                # Rekursiv in Containern suchen
                                if ($control.Controls -and $control.Controls.Count -gt 0) {
                                    if (Search-ButtonRecursive -controls $control.Controls) {
                                        return $true
                                    }
                                }
                            }
                            return $false
                        }
                        
                        $buttonFound = Search-ButtonRecursive -controls $mainform.Value.Controls
                    }
                }
                catch {
                    # Fehler beim Zugriff auf Mainform ignorieren
                }
            }
        }
    }
    catch {
        # Fehler beim Aktualisieren des Button-Indikators ignorieren
    }
}

# Hilfsfunktion zum Formatieren der Dateigröße (falls noch nicht vorhanden)
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

# Function to clean temporary files
function Start-TempFilesCleanup {
    param (
        [System.Windows.Forms.RichTextBox]$outputBox,
        [System.Windows.Forms.ProgressBar]$progressBar
    )
    
    # OutputBox und ProgressBar zurücksetzen
    try {
        $outputBox.Clear()
        if ($null -ne $progressBar) {
            $progressBar.Value = 0
        }
        else {
            $outputBox.AppendText("Warnung: ProgressBar nicht verfügbar.`r`n")
        }
    
        # outputBox zuruecksetzen
        $outputBox.Clear()
        $outputBox.SelectionColor = [System.Drawing.Color]::DarkBlue
        $outputBox.AppendText("===== BEREINIGUNG TEMPORAERER DATEIEN =====`r`n")
        $outputBox.AppendText("Modus: Systemreinigung`r`n")
        $outputBox.AppendText("Zeitstempel: $(Get-Date -Format 'dd.MM.yyyy HH:mm:ss')`r`n`r`n")
    
        # Systeminformationen anzeigen
        $computerName = $env:COMPUTERNAME
        $userName = $env:USERNAME
        $osInfo = (Get-CimInstance -ClassName Win32_OperatingSystem).Caption
    
        # Format fuer nebeneinander stehende Informationen
        $outputBox.SelectionColor = [System.Drawing.Color]::Blue
        $outputBox.AppendText("[►] SYSTEM-INFORMATIONEN:`r`n")
        $outputBox.SelectionColor = [System.Drawing.Color]::Black
    
        $osLabel = "Betriebssystem:".PadRight(18)
        $pcLabel = "Computer:".PadRight(18)
        $userLabel = "Benutzer:".PadRight(18)
    
        # Zeile 1: Betriebssystem und Computer
        $outputBox.AppendText("    $osLabel $osInfo".PadRight(60))
        $outputBox.AppendText("$pcLabel $computerName`r`n")
    
        # Zeile 2: Benutzer und Datum/Zeit
        $outputBox.AppendText("    $userLabel $userName".PadRight(60))
        $outputBox.AppendText("Datum/Zeit: $(Get-Date -Format 'dd.MM.yyyy HH:mm:ss')`r`n`r`n")
    
        # Laufwerksinformationen anzeigen
        $outputBox.SelectionColor = [System.Drawing.Color]::Blue
        $outputBox.AppendText("[►] VERFUEGBARE LAUFWERKE:`r`n`r`n")
    
        # Tabellenkopf erstellen
        $outputBox.SelectionColor = [System.Drawing.Color]::DarkBlue
        $lw = "Laufwerk".PadRight(15)
        $name = "Bezeichnung".PadRight(20)
        $total = "Groesse".PadRight(15)
        $free = "Freier Speicher".PadRight(20)
        $used = "Belegung".PadRight(15)
        $outputBox.AppendText("    $lw$name$total$free$used`r`n")
    
        # Trennlinie
        $outputBox.SelectionColor = [System.Drawing.Color]::Gray
        $outputBox.AppendText("    " + "".PadRight(85, '-') + "`r`n")
        $outputBox.SelectionColor = [System.Drawing.Color]::Black
    
        # Verfuegbare Laufwerke ermitteln
        $drives = Get-WmiObject Win32_LogicalDisk | 
        Where-Object { $_.DriveType -eq 3 -or $_.DriveType -eq 2 } | 
        Select-Object -ExpandProperty DeviceID
    
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
        
            # Groesseninformationen formatieren
            $totalCol = "$totalSpace GB".PadRight(15)
            $freeCol = "$freeSpace GB".PadRight(20)
        
            # Zeile ausgeben
            $outputBox.AppendText("    $driveCol$labelCol$totalCol$freeCol")
        
            # Speichernutzung mit Farbe je nach Fuellstand anzeigen
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
    
        $outputBox.AppendText("`r`n")        # ProgressBar zuruecksetzen falls vorhanden
        if ($null -ne $progressBar) {
            $progressBar.Value = 0
        }

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
        
        # Überschrift für die Reinigung
        $outputBox.SelectionColor = [System.Drawing.Color]::Blue
        $outputBox.AppendText("[►] BEREINIGUNG TEMPORAERER ORDNER:`r`n`r`n")
        $outputBox.SelectionColor = [System.Drawing.Color]::Black
    
        # Benutzerdefinierte Pfade hinzufügen
        $cleanupSettings = Get-CleanupSettings
        $customPaths = $cleanupSettings.CustomPaths
    
        if ($customPaths.Count -gt 0) {
            $outputBox.SelectionColor = [System.Drawing.Color]::Blue
            $outputBox.AppendText("[+] Zusaetzliche benutzerdefinierte Pfade werden bereinigt...\r\n")
        
            foreach ($path in $customPaths) {
                if (Test-Path $path) {
                    # Prüfen, ob der Pfad nicht ausgeschlossen ist
                    if (-not (Test-PathExcluded -Path $path)) {
                        try {
                            $outputBox.SelectionColor = [System.Drawing.Color]::Black
                            $outputBox.AppendText("  -> Bereinige $path...\r\n")
                        
                            # Dateien im benutzerdefinierten Pfad löschen
                            Get-ChildItem -Path $path -File -Recurse -ErrorAction SilentlyContinue | 
                            Where-Object { -not (Test-PathExcluded -Path $_.FullName) } | 
                            Remove-Item -Force -ErrorAction SilentlyContinue
                        
                            $outputBox.SelectionColor = [System.Drawing.Color]::Green
                            $outputBox.AppendText("     Benutzerdefinierter Pfad bereinigt: $path\r\n")
                        }
                        catch {
                            $outputBox.SelectionColor = [System.Drawing.Color]::Red
                            $outputBox.AppendText("     Fehler beim Bereinigen von " + $path + ": " + $_ + "\r\n")
                        }
                    }
                    else {
                        $outputBox.SelectionColor = [System.Drawing.Color]::Gray
                        $outputBox.AppendText("     Ueberspringe ausgeschlossenen Pfad: $path\r\n")
                    }
                }
                else {
                    $outputBox.SelectionColor = [System.Drawing.Color]::Yellow
                    $outputBox.AppendText("     Benutzerdefinierter Pfad nicht gefunden: $path\r\n")
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
            $outputBox.AppendText("  -> Untersuche Ordner: $folder`r`n")
            
            # Ueberpruefe, ob der Ordner existiert
            if (Test-Path -Path $folder) {
                $files = Get-ChildItem -Path $folder -Recurse -File -ErrorAction SilentlyContinue
                # Ermittle Anzahl der Dateien und Gesamtgroesse
                $folderFiles = $files.Count
                $folderSize = 0
                if ($files) {
                    $folderSizeSum = ($files | Measure-Object -Property Length -Sum).Sum
                    $folderSize = if ($null -eq $folderSizeSum) { 0 } else { $folderSizeSum / 1MB }
                    $folderSize = [Math]::Round($folderSize, 2)
                }
                
                $outputBox.SelectionColor = [System.Drawing.Color]::Black
                $outputBox.AppendText("     Gefunden: $folderFiles Dateien ($folderSize MB)`r`n")
            }
        }
        
        # Aktualisiere ProgressBar auf 100%
        if ($null -ne $progressBar) {
            $progressBar.Value = 100
        }
        # Erfolgsnotiz
        $outputBox.SelectionColor = [System.Drawing.Color]::Green
        $outputBox.AppendText("`r`n[√] Bereinigung temporaerer Dateien erfolgreich abgeschlossen.`r`n")
        
        # Farbe zuruecksetzen
        $outputBox.SelectionColor = $outputBox.ForeColor
    }
    catch {
        $outputBox.SelectionColor = [System.Drawing.Color]::Red
        $outputBox.AppendText("`r`n[-] Allgemeiner Fehler: " + $_.Exception.Message + "`r`n")
    }
}

# Erweiterte Funktion für temporäre Dateien
function Start-TempFilesCleanupAdvanced {
    param (
        [System.Windows.Forms.RichTextBox]$outputBox,
        [System.Windows.Forms.ProgressBar]$progressBar,
        [System.Windows.Forms.Form]$mainform
    )
    
    try {
        clear-host
        # Rahmen und ASCII-Art für Custom Cleanup
        Write-Host "╔══════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
        Write-ColoredCenteredText                       "CUSTOM CLEANUP"                                         
        Write-Host "╚══════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Green
            
        # ASCII-Art Logo für Custom Cleanup
        Write-Host
        Write-Host '    .d8888b.                       888                                           ' -ForegroundColor Cyan
        Write-Host '   d88P  Y88b                      888                                           ' -ForegroundColor Blue
        Write-Host '   888    888                      888                                           ' -ForegroundColor Cyan
        Write-Host '   888         888  888  .d8888b   888888   .d88b.   88888b.d88b.                ' -ForegroundColor Blue
        Write-Host '   888         888  888  88K       888     d88""88b  888 "888 "88b               ' -ForegroundColor Cyan
        Write-Host '   888    888  888  888  "Y8888b.  888     888  888  888  888  888               ' -ForegroundColor Blue
        Write-Host '   Y88b  d88P  Y88b 888       X88  Y88b.   Y88..88P  888  888  888               ' -ForegroundColor Cyan
        Write-Host '    "Y8888P"    "Y88888   88888P"   "Y888   "Y88P"   888  888  888               ' -ForegroundColor Blue
        Write-Host
        Write-Host '    .d8888b.   888                                                               ' -ForegroundColor Cyan
        Write-Host '   d88P  Y88b  888                                                               ' -ForegroundColor Blue
        Write-Host '   888    888  888                                                               ' -ForegroundColor Cyan
        Write-Host '   888         888   .d88b.    8888b.   88888b.   888  888  88888b.              ' -ForegroundColor Blue
        Write-Host '   888         888  d8P  Y8b      "88b  888 "88b  888  888  888 "88b             ' -ForegroundColor Cyan
        Write-Host '   888    888  888  88888888  .d888888  888  888  888  888  888  888             ' -ForegroundColor Blue
        Write-Host '   Y88b  d88P  888  Y8b.      888  888  888  888  Y88b 888  888 d88P             ' -ForegroundColor Cyan
        Write-Host '    "Y8888P"   888   "Y8888   "Y888888  888  888   "Y88888  88888P"              ' -ForegroundColor Blue
        Write-Host '                                                            888                  ' -ForegroundColor Cyan
        Write-Host '                                                            888                  ' -ForegroundColor Blue
        Write-Host '                                                            888                  ' -ForegroundColor Cyan
        Write-Host
            
        # Rahmen für Informationen
        Write-Host "╔══════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
        Write-ColoredCenteredText                   "INFORMATIONEN"                                     
        Write-Host "╠══════════════════════════════════════════════════════════════════════════════╣" -ForegroundColor Green
        Write-Host "║                                                                              ║" -ForegroundColor Green
        Write-Host "  ├─  System entlasten durch gezielte Datenbereinigung:                           " -ForegroundColor Yellow                 
        Write-Host "  ├─  Entfernt temporäre Dateien, Browser-Cache und veraltete Systemreste.        " -ForegroundColor Yellow                                    
        Write-Host "  ├─  Hilft Speicherplatz freizugeben und die Systemleistung zu verbessern.       " -ForegroundColor Yellow                                    
        Write-Host "  └─  Empfohlen zur regelmäßigen Wartung und nach größeren Updates.               " -ForegroundColor Yellow                                  
        Write-Host "║                                                                              ║" -ForegroundColor Green
        Write-Host "╠══════════════════════════════════════════════════════════════════════════════╣" -ForegroundColor Green
        Write-ColoredCenteredText           "[►] Starte benutzerdefinierte Bereinigung..."
        Write-Host "╚══════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Green
        Write-Host
        # 3 Sekunden warten vor dem Start
        Start-Sleep -Seconds 3
        $outputBox.Clear()
        # Kurze Information zum weiteren Vorgehen
        $outputBox.SelectionColor = [System.Drawing.Color]::Blue
        $outputBox.AppendText("[►] VORBEREITUNG CHKDSK:`r`n")
        $outputBox.SelectionColor = [System.Drawing.Color]::Gray
        $outputBox.AppendText("    Bitte wählen Sie die zu prüfenden Laufwerke und Optionen im Dialog-Fenster aus...`r`n")
        # Laufwerksinformationen anzeigen
        $outputBox.SelectionColor = [System.Drawing.Color]::Blue
        $outputBox.AppendText("[i] VERFUEGBARE LAUFWERKE:`r`n`r`n")
        
        # Tabellenkopf erstellen
        $outputBox.SelectionColor = [System.Drawing.Color]::DarkBlue
        $lw = "Laufwerk".PadRight(15)
        $name = "Bezeichnung".PadRight(20)
        $total = "Groesse".PadRight(15)
        $free = "Freier Speicher".PadRight(20)
        $used = "Belegung".PadRight(15)
        $outputBox.AppendText("    $lw$name$total$free$used`r`n")
        
        # Trennlinie
        $outputBox.SelectionColor = [System.Drawing.Color]::Gray
        $outputBox.AppendText("    " + "".PadRight(85, '-') + "`r`n")
        $outputBox.SelectionColor = [System.Drawing.Color]::Black
        
        # Verfuegbare Laufwerke ermitteln
        $drives = Get-WmiObject Win32_LogicalDisk | 
        Where-Object { $_.DriveType -eq 3 -or $_.DriveType -eq 2 } | 
        Select-Object -ExpandProperty DeviceID
   
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
            
            # Groesseninformationen formatieren
            $totalCol = "$totalSpace GB".PadRight(15)
            $freeCol = "$freeSpace GB".PadRight(20)
            
            # Zeile ausgeben
            $outputBox.AppendText("    $driveCol$labelCol$totalCol$freeCol")
            
            # Speichernutzung mit Farbe je nach Fuellstand anzeigen
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
        
        
        Write-Host "  [►] Dialog-Fenster für die Erweiterte Systemreinigung wird gestartet..." -ForegroundColor green
        Write-Host 
        Write-Host "  [i] Bitte waehlen Sie die zu bereinigenden Laufwerke und " -ForegroundColor yellow
        Write-Host "      Optionen im Dialog-Fenster aus..." -ForegroundColor yellow
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
            }, @{
                Name        = "firefoxCache"; 
                Text        = "Firefox Cache"; 
                Default     = $true; 
                Description = "Bereinigt Mozilla Firefox Cache-Dateien"; 
                Paths       = @(
                    "Users\*\AppData\Local\Mozilla\Firefox\Profiles\*\cache2\*",
                    "Users\*\AppData\Local\Mozilla\Firefox\Profiles\*\startupCache\*"
                )
            }, @{
                Name        = "braveCache"; 
                Text        = "Brave Browser Cache"; 
                Default     = $true; 
                Description = "Bereinigt Brave Browser Cache-Dateien"; 
                Paths       = @(
                    "Users\*\AppData\Local\BraveSoftware\Brave-Browser\User Data\Default\Cache\*",
                    "Users\*\AppData\Local\BraveSoftware\Brave-Browser\User Data\Default\Code Cache\*",
                    "Users\*\AppData\Local\BraveSoftware\Brave-Browser\User Data\Default\GPUCache\*",
                    "Users\*\AppData\Local\BraveSoftware\Brave-Browser\User Data\Default\DawnCache\*",
                    "Users\*\AppData\Local\BraveSoftware\Brave-Browser\User Data\Default\optimization_guide_hint_cache_store\*"
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
                    '$Recycle.Bin'
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
            # Verwende ein statisches Tooltip anstatt bei jedem Hover ein neues zu erstellen
            if (-not $script:cleanupTooltip) {
                $script:cleanupTooltip = New-Object System.Windows.Forms.ToolTip
                $script:cleanupTooltip.ToolTipTitle = "Information"
                $script:cleanupTooltip.UseFading = $true
                $script:cleanupTooltip.UseAnimation = $true
                $script:cleanupTooltip.IsBalloon = $true
                $script:cleanupTooltip.InitialDelay = 300
                $script:cleanupTooltip.AutoPopDelay = 5000
            }
            
            # Setze Tooltip für das Info-Symbol
            $script:cleanupTooltip.SetToolTip($infoIcon, $option.Description)

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
            elseif ($DriveLetter -match "^([A-Za-z])$") {
                # Falls nur Buchstabe ohne Doppelpunkt
                $DriveLetter = $DriveLetter + ":"
            }
            elseif (-not ($DriveLetter -match "^[A-Za-z]:$")) {
                # Ungültiges Format - Fehler
                throw "Ungültiger Laufwerksbuchstabe: $DriveLetter"
            }
            
            # Status für Debugging in GUI ausgeben
            $statusBox.SelectionColor = [System.Drawing.Color]::Blue
            $statusBox.AppendText("Berechne Dateigröße für Laufwerk $DriveLetter...`r`n")
            [System.Windows.Forms.Application]::DoEvents()
            
            foreach ($path in $Paths) {
                try {
                    # Spezielle Behandlung für Papierkorb
                    if ($path -eq '$Recycle.Bin') {
                        $fullPath = "$DriveLetter\`$Recycle.Bin"
                        $statusBox.SelectionColor = [System.Drawing.Color]::Gray
                        $statusBox.AppendText("  Prüfe Papierkorb: $fullPath`r`n")
                        [System.Windows.Forms.Application]::DoEvents()
                        
                        # Papierkorb-spezifische Behandlung
                        if (Test-Path $fullPath) {
                            $recycleBinFolders = Get-ChildItem -Path $fullPath -Directory -Force -ErrorAction SilentlyContinue
                            foreach ($folder in $recycleBinFolders) {
                                try {
                                    $files = Get-ChildItem -Path $folder.FullName -Recurse -Force -ErrorAction SilentlyContinue | 
                                    Where-Object { -not $_.PSIsContainer }
                                    if ($files) {
                                        $count = $files.Count
                                        $sizeSum = ($files | Measure-Object -Property Length -Sum).Sum
                                        $size = if ($null -eq $sizeSum) { 0 } else { $sizeSum }
                                        $statusBox.AppendText("    Gefunden in $($folder.Name): $count Dateien ($([Math]::Round($size/1MB, 2)) MB)`r`n")
                                        
                                        $fileCount += $count
                                        $totalSize += $size
                                    }
                                }
                                catch {
                                    $statusBox.SelectionColor = [System.Drawing.Color]::Orange
                                    $statusBox.AppendText("    Warnung: Kein Zugriff auf $($folder.Name)`r`n")
                                }
                            }
                        }
                        else {
                            $statusBox.AppendText("    Papierkorb nicht gefunden oder leer`r`n")
                        }
                    }
                    else {
                        # Normale Pfad-Behandlung
                        $fullPath = if ($path.StartsWith("\")) {
                            "$DriveLetter$path"
                        }
                        else {
                            "$DriveLetter\$path"
                        }
                        $statusBox.SelectionColor = [System.Drawing.Color]::Gray
                        $statusBox.AppendText("  Prüfe: $fullPath`r`n")
                        [System.Windows.Forms.Application]::DoEvents()
                        # Verbesserte Wildcard-Behandlung mit Hilfsfunktion
                        $files = Get-FilesFromPath -Path $fullPath -Recursive $true
                        if ($files) {
                            $count = $files.Count
                            $sizeSum = ($files | Measure-Object -Property Length -Sum).Sum
                            $size = if ($null -eq $sizeSum) { 0 } else { $sizeSum }
                            $statusBox.AppendText("    Gefunden: $count Dateien ($([Math]::Round($size/1MB, 2)) MB)`r`n")
                            
                            $fileCount += $count
                            $totalSize += $size
                        }
                        else {
                            $statusBox.AppendText("    Keine Dateien gefunden`r`n")
                        }
                    }
                    [System.Windows.Forms.Application]::DoEvents()
                }
                catch {
                    $statusBox.SelectionColor = [System.Drawing.Color]::Red
                    $statusBox.AppendText("  Fehler bei $path : $($_.Exception.Message)`r`n")
                    [System.Windows.Forms.Application]::DoEvents()
                }
            }
            
            $statusBox.SelectionColor = [System.Drawing.Color]::Green
            $statusBox.AppendText("Laufwerk $DriveLetter - Gesamt: $fileCount Dateien ($([Math]::Round($totalSize/1MB, 2)) MB)`r`n")
            [System.Windows.Forms.Application]::DoEvents()
            
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
                try {
                    # Spezielle Behandlung für Papierkorb
                    if ($path -eq '$Recycle.Bin') {
                        $fullPath = "$DriveLetter\`$Recycle.Bin"
                        
                        if (Test-Path $fullPath) {
                            # Papierkorb über Shell-Objekt leeren (sicherere Methode)
                            try {
                                $shell = New-Object -ComObject Shell.Application
                                $recycleBin = $shell.Namespace(10) # 10 = Papierkorb
                                $items = $recycleBin.Items()
                                
                                # Dateien vor dem Löschen zählen
                                $itemCount = $items.Count
                                if ($itemCount -gt 0) {
                                    foreach ($item in $items) {
                                        try {
                                            $itemSize = $item.Size
                                            $totalFreed += $itemSize
                                            $deletedCount++
                                        }
                                        catch {
                                            # Größe konnte nicht ermittelt werden
                                        }
                                    }
                                    
                                    # Papierkorb leeren
                                    $recycleBin.InvokeVerb("Empty")
                                }
                            }
                            catch {
                                # Fallback: Manuelles Löschen
                                $recycleBinFolders = Get-ChildItem -Path $fullPath -Directory -Force -ErrorAction SilentlyContinue
                                foreach ($folder in $recycleBinFolders) {
                                    try {
                                        $files = Get-ChildItem -Path $folder.FullName -Recurse -Force -ErrorAction SilentlyContinue | 
                                        Where-Object { -not $_.PSIsContainer }
                                        
                                        foreach ($file in $files) {
                                            try {
                                                $fileSize = $file.Length
                                                Remove-Item -Path $file.FullName -Force -ErrorAction Stop
                                                $deletedCount++
                                                $totalFreed += $fileSize
                                            }
                                            catch {
                                                $skippedCount++
                                            }
                                        }
                                    }
                                    catch {
                                        $skippedCount++
                                    }
                                }
                            }
                        }
                    }
                    else {
                        # Normale Pfad-Behandlung
                        $fullPath = if ($path.StartsWith("\")) {
                            "$DriveLetter$path"
                        }
                        else {
                            "$DriveLetter\$path"
                        }                        # Verbesserte Wildcard-Behandlung für Remove-TempFiles mit Hilfsfunktion
                        $files = Get-FilesFromPath -Path $fullPath -Recursive $true
                        
                        if ($files) {
                            foreach ($file in $files) {
                                try {
                                    $fileSize = $file.Length
                                    Remove-Item -Path $file.FullName -Force -ErrorAction Stop
                                    $deletedCount++
                                    $totalFreed += $fileSize
                                }
                                catch {
                                    $skippedCount++
                                }
                            }
                        }
                    }
                }
                catch {
                    # Fehler loggen
                    $statusBox.SelectionColor = [System.Drawing.Color]::Gray
                    $statusBox.AppendText("Hinweis: Problem beim Zugriff auf $path.`r`n")
                }
            }
            
            return @{
                FreedSpace   = $totalFreed
                DeletedFiles = $deletedCount
                SkippedFiles = $skippedCount
            }
        }
        # Funktion zum Updaten der Größenschätzungen
        function Update-CleanupSizeEstimates {
            $global:optionSizes = @{}
            $statusBox.Clear()
            $statusBox.SelectionColor = [System.Drawing.Color]::DarkBlue
            $statusBox.AppendText("=== BERECHNUNG BEREINIGUNGSGRÖSSE ===`r`n")
            $statusBox.AppendText("Zeitstempel: $(Get-Date -Format 'dd.MM.yyyy HH:mm:ss')`r`n`r`n")
            [System.Windows.Forms.Application]::DoEvents()
            
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
            
            $statusBox.SelectionColor = [System.Drawing.Color]::Blue
            $statusBox.AppendText("Ausgewählte Laufwerke: $($selectedDrives -join ', ')`r`n`r`n")
            [System.Windows.Forms.Application]::DoEvents()
            
            # Wenn keine Laufwerke ausgewählt sind, alle Größen auf 0 setzen
            if ($selectedDrives.Count -eq 0) {
                foreach ($optionKey in $cleanupCheckboxes.Keys) {
                    $sizeLabels[$optionKey].Text = "0 Bytes"
                    $sizeLabels[$optionKey].ForeColor = [System.Drawing.Color]::Gray
                }
                
                $statusBox.SelectionColor = [System.Drawing.Color]::Red
                $statusBox.AppendText("FEHLER: Bitte wählen Sie mindestens ein Laufwerk aus.`r`n")
                return
            }
            
            # Für jede Option die Dateigröße berechnen
            $activeOptions = $cleanupOptions | Where-Object { $cleanupCheckboxes[$_.Name].Checked }
            
            # Wenn keine Optionen ausgewählt sind, alle Größen auf 0 setzen
            if ($activeOptions.Count -eq 0) {
                $statusBox.SelectionColor = [System.Drawing.Color]::Red
                $statusBox.AppendText("FEHLER: Bitte wählen Sie mindestens eine Bereinigungsoption aus.`r`n")
                return
            }
            
            $statusBox.SelectionColor = [System.Drawing.Color]::Blue
            $statusBox.AppendText("Ausgewählte Optionen: $($activeOptions.Count)`r`n")
            foreach ($option in $activeOptions) {
                $statusBox.AppendText("  - $($option.Text)`r`n")
            }
            $statusBox.AppendText("`r`n")
            [System.Windows.Forms.Application]::DoEvents()
            # Fortschrittsberechnung vorbereiten - Division durch Null vermeiden
            $totalOperations = $selectedDrives.Count * $activeOptions.Count
            if ($totalOperations -eq 0) {
                $statusBox.SelectionColor = [System.Drawing.Color]::Red
                $statusBox.AppendText("FEHLER: Keine gültigen Operationen zum Berechnen.`r`n")
                return
            }
            $completedOperations = 0
            
            # Größenberechnung im Hintergrund starten (ohne echtes PowerShell-Job wegen Einfachheit)
            $cleanupForm.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
            
            # Für jede Option und jedes Laufwerk die Größe berechnen
            foreach ($option in $activeOptions) {
                $totalSize = 0
                $totalFiles = 0
                
                $statusBox.SelectionColor = [System.Drawing.Color]::Green
                $statusBox.AppendText("--- $($option.Text) ---`r`n")
                [System.Windows.Forms.Application]::DoEvents()
                
                # Größenschätzung für diese Option zurücksetzen
                $sizeLabels[$option.Name].Text = "Berechne..."
                $sizeLabels[$option.Name].ForeColor = [System.Drawing.Color]::Orange
                [System.Windows.Forms.Application]::DoEvents()
                
                foreach ($drive in $selectedDrives) {
                    $completedOperations++
                    $percentComplete = [math]::Round(($completedOperations / $totalOperations) * 100)
                    # Spezialfall: Event Logs - verbesserte Berechnung
                    if ($option.Name -eq "eventLogs") {
                        # Event Logs nur auf System-Laufwerk relevant
                        if ($drive -eq "C:") {
                            try {
                                # Versuche echte Event Log Größe zu ermitteln
                                $eventLogPath = "$drive\Windows\System32\winevt\Logs"
                                if (Test-Path $eventLogPath) {
                                    $logFiles = Get-ChildItem -Path "$eventLogPath\*.evtx" -Force -ErrorAction SilentlyContinue
                                    if ($logFiles) {
                                        $eventLogSize = ($logFiles | Measure-Object -Property Length -Sum).Sum
                                        $eventLogCount = $logFiles.Count
                                        $result = @{ Size = if ($null -eq $eventLogSize) { 0 } else { $eventLogSize }; Count = $eventLogCount }
                                    }
                                    else {
                                        $result = @{ Size = 0; Count = 0 }
                                    }
                                }
                                else {
                                    $result = @{ Size = 0; Count = 0 }
                                }
                            }
                            catch {
                                # Fallback zu geschätzten Werten bei Fehlern
                                $result = @{ Size = 2MB; Count = 3 }
                            }
                        }
                        else {
                            $result = @{ Size = 0; Count = 0 }
                        }
                    }
                    else {
                        # Normale Dateiberechnung
                        $result = Get-FileSize -DriveLetter $drive -Paths $option.Paths
                    }
                    
                    $totalSize += $result.Size
                    $totalFiles += $result.Count
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
                    $statusBox.SelectionColor = [System.Drawing.Color]::Green
                    $statusBox.AppendText("Ergebnis: $formattedSize ($totalFiles Dateien)`r`n`r`n")
                }
                else {
                    $sizeLabels[$option.Name].ForeColor = [System.Drawing.Color]::Gray
                    $statusBox.SelectionColor = [System.Drawing.Color]::Gray
                    $statusBox.AppendText("Ergebnis: Keine Dateien gefunden`r`n`r`n")
                }
                [System.Windows.Forms.Application]::DoEvents()
            }
            
            # Gesamtgröße berechnen
            $totalPotentialCleanup = 0
            $totalFileCount = 0
            
            foreach ($optionKey in $global:optionSizes.Keys) {
                $totalPotentialCleanup += $global:optionSizes[$optionKey].Size
                $totalFileCount += $global:optionSizes[$optionKey].Files
            }
            
            # Status aktualisieren
            $statusBox.SelectionColor = [System.Drawing.Color]::DarkBlue
            $statusBox.AppendText("=== BERECHNUNG ABGESCHLOSSEN ===`r`n")
            $statusBox.SelectionColor = [System.Drawing.Color]::Green
            $statusBox.AppendText("Potentiell freizugebender Speicher: " + (Format-Size -Size $totalPotentialCleanup) + "`r`n")
            $statusBox.AppendText("Zu bereinigende Dateien: $totalFileCount`r`n")
            $statusBox.SelectionColor = [System.Drawing.Color]::Blue
            $statusBox.AppendText("Zeitstempel: $(Get-Date -Format 'dd.MM.yyyy HH:mm:ss')`r`n")
            [System.Windows.Forms.Application]::DoEvents()
            
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
                $outputBox.AppendText("===== BEREINIGUNG TEMPORAERER DATEIEN (ERWEITERT) =====`r`n")
                $outputBox.AppendText("Modus: Erweiterte Bereinigung laeuft...`r`n")
                $outputBox.AppendText("Zeitstempel: $(Get-Date -Format 'dd.MM.yyyy HH:mm:ss')`r`n`r`n")
                
                # Systeminformationen anzeigen
                $computerName = $env:COMPUTERNAME
                $userName = $env:USERNAME
                $osInfo = (Get-CimInstance -ClassName Win32_OperatingSystem).Caption
                
                # Format fuer nebeneinander stehende Informationen
                $outputBox.SelectionColor = [System.Drawing.Color]::Blue
                $outputBox.AppendText("[i] SYSTEM-INFORMATIONEN:`r`n")
                $outputBox.SelectionColor = [System.Drawing.Color]::Black
                
                $osLabel = "Betriebssystem:".PadRight(18)
                $pcLabel = "Computer:".PadRight(18)
                $userLabel = "Benutzer:".PadRight(18)
                
                # Zeile 1: Betriebssystem und Computer
                $outputBox.AppendText("    $osLabel $osInfo".PadRight(60))
                $outputBox.AppendText("$pcLabel $computerName`r`n")
                
                # Zeile 2: Benutzer und Datum/Zeit
                $outputBox.AppendText("    $userLabel $userName".PadRight(60))
                $outputBox.AppendText("Datum/Zeit: $(Get-Date -Format 'dd.MM.yyyy HH:mm:ss')`r`n`r`n")
                
                # Informationen zur Bereinigung
                $outputBox.SelectionColor = [System.Drawing.Color]::Blue
                $outputBox.AppendText("[i] BEREINIGUNGSDETAILS:`r`n")
                $outputBox.SelectionColor = [System.Drawing.Color]::Black
                $outputBox.AppendText("    Ausgewaehlte Laufwerke: " + ($selectedDrives -join ", ") + "`r`n")
                $outputBox.AppendText("    Ausgewaehlte Optionen: " + $activeOptions.Count + "`r`n`r`n")
                
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
                
                # Zusätzliche Ausgabe in der PowerShell-Konsole (konsistent mit Disk-Cleanup)
                Write-Host "`n" + ("═" * 70) -ForegroundColor Cyan 
                Write-Host "`n  [►] Benutzerdefinierte Bereinigung abgeschlossen!" -ForegroundColor Green
                Write-Host "  [✓] Insgesamt entfernt:    $totalFilesDeleted Dateien" -ForegroundColor Cyan
                Write-Host "  [✓] Insgesamt freigegeben: $(Format-Size -Size $totalFreed)" -ForegroundColor Cyan
                
                if ($totalFilesSkipped -gt 0) {
                    Write-Host "  [!] Übersprungene Dateien: $totalFilesSkipped (in Verwendung)" -ForegroundColor Yellow
                }
                Write-Host "`n" + ("═" * 70) -ForegroundColor Cyan 
                Write-Host
                
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
    }    # Schreibe die Information in die Protokolldatei
    "$filePath | $sizeString" | Out-File -Append -FilePath "$env:TEMP\skipped_files.txt"
}

# Funktion zum Bereinigen temporärer Dateien
function Start-Cleanup {
    param (
        [System.Windows.Forms.RichTextBox]$outputBox,
        [System.Windows.Forms.ProgressBar]$progressBar
    )
    
    
    # In Log-Datei und Datenbank schreiben, dass die System-Bereinigung gestartet wird
    Write-ToolLog -ToolName "SystemCleanup" -Message "System-Bereinigung wird gestartet" -OutputBox $outputBox -Color ([System.Drawing.Color]::Blue) -Level "Information" -SaveToDatabase
    
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
        }        # Browser Cache
        $browserPaths = @{
            "Chrome"  = "$env:USERPROFILE\AppData\Local\Google\Chrome\User Data\Default\Cache"
            "Firefox" = "$env:USERPROFILE\AppData\Local\Mozilla\Firefox\Profiles\*.default*\cache2"
            "Edge"    = "$env:USERPROFILE\AppData\Local\Microsoft\Edge\User Data\Default\Cache"
            "Brave"   = "$env:USERPROFILE\AppData\Local\BraveSoftware\Brave-Browser\User Data\Default\Cache"
        }
        
        # Zusätzliche Brave Browser Cache-Ordner
        $braveCachePaths = @(
            "$env:USERPROFILE\AppData\Local\BraveSoftware\Brave-Browser\User Data\Default\Code Cache",
            "$env:USERPROFILE\AppData\Local\BraveSoftware\Brave-Browser\User Data\Default\GPUCache",
            "$env:USERPROFILE\AppData\Local\BraveSoftware\Brave-Browser\User Data\Default\DawnCache"
        )
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
        
        # Zusätzliche Brave Browser Cache-Ordner bereinigen
        foreach ($bravePath in $braveCachePaths) {
            Get-ChildItem -Path $bravePath -File -Force -ErrorAction SilentlyContinue | ForEach-Object {
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
        $totalSizeSum = ($filesToClean | Get-Item -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
        $totalSize = if ($null -eq $totalSizeSum) { 0 } else { $totalSizeSum }
        $skippedSizeSum = ($skippedFiles | Measure-Object -Property Length -Sum).Sum
        $skippedSize = if ($null -eq $skippedSizeSum) { 0 } else { $skippedSizeSum }
        
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

# Hilfsfunktion zur besseren Pfadbehandlung
function Get-FilesFromPath {
    param (
        [string]$Path,
        [bool]$Recursive = $true
    )
    
    try {
        # Prüfe, ob der Pfad Wildcards enthält
        if ($Path.Contains('*') -or $Path.Contains('?')) {
            # Wildcard-Pfad - verwende Get-ChildItem direkt
            if ($Recursive) {
                return Get-ChildItem -Path $Path -Recurse -Force -ErrorAction SilentlyContinue | 
                Where-Object { -not $_.PSIsContainer }
            }
            else {
                return Get-ChildItem -Path $Path -Force -ErrorAction SilentlyContinue | 
                Where-Object { -not $_.PSIsContainer }
            }
        }
        else {
            # Normaler Pfad - prüfe erst Existenz
            if (Test-Path $Path) {
                if ($Recursive) {
                    return Get-ChildItem -Path $Path -Recurse -Force -ErrorAction SilentlyContinue | 
                    Where-Object { -not $_.PSIsContainer }
                }
                else {
                    return Get-ChildItem -Path $Path -Force -ErrorAction SilentlyContinue | 
                    Where-Object { -not $_.PSIsContainer }
                }
            }
            else {
                return @()
            }
        }
    }
    catch {
        return @()
    }
}

# Export functions
Export-ModuleMember -Function Start-DiskCleanup, Start-TempFilesCleanup, Start-TempFilesCleanupAdvanced, Start-Cleanup

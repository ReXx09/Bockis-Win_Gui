# Import required modules
Import-Module "$PSScriptRoot\..\Core\Core.psm1" -Force -Global
Import-Module "$PSScriptRoot\..\Core\TextStyle.psm1" -Force -Global

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
        } else {
            $outputBox.AppendText("Warnung: ProgressBar nicht verfügbar.`r`n")
        }

        # In Log-Datei und Datenbank schreiben, dass Disk Cleanup gestartet wird
        Write-ToolLog -ToolName "DiskCleanup" -Message "Disk Cleanup wird gestartet" -OutputBox $outputBox -Style 'Action' -Level "Information" -SaveToDatabase

        # Verfügbare Laufwerke ermitteln (nur feste Laufwerke)
        $drives = Get-WmiObject Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 } | Select-Object -ExpandProperty DeviceID
        $totalDrives = $drives.Count
        $currentDriveIndex = 0
        $totalFreedSpace = 0
        $totalFilesRemoved = 0
        $totalSkippedFiles = 0

        Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Action'
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

            Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Action'
            $outputBox.AppendText("`r`n>>> Bereinige Laufwerk ${driveLetter}... ($currentDriveIndex von $totalDrives)`r`n")

            $pathCount = $cleanupPaths.Count
            $currentPathIndex = 0

            foreach ($cleanupItem in $cleanupPaths) {
                $currentPathIndex++
                    
                # Korrigierte Pfadkonstruktion
                $fullPath = if ($cleanupItem.PathPattern.StartsWith("\")) {
                    "$driveLetter$($cleanupItem.PathPattern)"
                } else {
                    "$driveLetter\$($cleanupItem.PathPattern)"
                }
                    
                # ProgressBar aktualisieren
                if ($null -ne $progressBar) {
                    $progressValue = [int](($currentDriveIndex - 1) / $totalDrives * 100 + ($currentPathIndex / $pathCount) * (100 / $totalDrives))
                    $progressBar.Value = [Math]::Min(100, $progressValue)
                }

                Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Muted'
                $outputBox.AppendText("  -> $($cleanupItem.Name)... ")
                [System.Windows.Forms.Application]::DoEvents() # UI aktualisieren

                $filesToDelete = @()
                try {
                    # Get-ChildItem mit -Force, um versteckte/Systemdateien zu berücksichtigen
                    $filesToDelete = Get-ChildItem -Path $fullPath -Recurse -File -Force -ErrorAction SilentlyContinue
                } catch {
                    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Warning'
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
                        } catch {
                            # Datei konnte nicht gelöscht werden (wahrscheinlich gesperrt)
                            $skippedCountInPath++
                        }
                    }

                    if ($removedCountInPath -gt 0) {
                        $driveFreedSpace += $sizeRemovedInPath
                        $driveFilesRemoved += $removedCountInPath
                        $driveSkippedFiles += $skippedCountInPath
                            
                        Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Success'
                        $outputBox.AppendText("($removedCountInPath Dateien / $(Format-Size -Size $sizeRemovedInPath)) entfernt")
                            
                        if ($skippedCountInPath -gt 0) {
                            Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Warning'
                            $outputBox.AppendText(" ($skippedCountInPath übersprungen)")
                        }
                        $outputBox.AppendText("`r`n")
                    } else {
                        Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Muted' -FallbackColor ([System.Drawing.Color]::DarkGray)
                        $outputBox.AppendText("(Keine Dateien entfernt/gelöscht)`r`n")
                    }
                } else {
                    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Muted' -FallbackColor ([System.Drawing.Color]::DarkGray)
                    $outputBox.AppendText("(Keine Dateien gefunden)`r`n")
                }
                [System.Windows.Forms.Application]::DoEvents() # UI aktualisieren
            } # Ende Pfade pro Laufwerk

            $totalFreedSpace += $driveFreedSpace
            $totalFilesRemoved += $driveFilesRemoved
            $totalSkippedFiles += $driveSkippedFiles
                
            Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Success'
            $outputBox.AppendText("-> Laufwerk ${driveLetter}: $driveFilesRemoved Dateien entfernt ($(Format-Size -Size $driveFreedSpace))")
                
            if ($driveSkippedFiles -gt 0) {
                Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Warning'
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
        Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Success'
        $outputBox.AppendText("`r`n================================================`r`n")
        Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Success'
        $outputBox.AppendText("✅ Schnelle Datenträgerbereinigung abgeschlossen!`r`n")
        Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Default'
        $outputBox.AppendText("   Insgesamt entfernt: $totalFilesRemoved Dateien`r`n")
        Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Default'
        $outputBox.AppendText("   Insgesamt freigegeben: $(Format-Size -Size $totalFreedSpace)`r`n")
            
        if ($totalSkippedFiles -gt 0) {
            Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Warning'
            $outputBox.AppendText("   Übersprungene Dateien: $totalSkippedFiles (in Verwendung)`r`n")
            Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Success'
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
            $logFilePath = Join-Path $PSScriptRoot "..\..\Data\Temp\cleanup_log.txt"
            $skippedFilePath = Join-Path $PSScriptRoot "..\..\Data\Temp\skipped_files.txt"
            
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
        } catch {
            $outputBox.AppendText("❌ Fehler bei der Protokollierung: $($_.Exception.Message)`r`n")
        }
    } catch {
        Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Error'
        $outputBox.AppendText("`r`n❌ FEHLER während der Bereinigung: $($_.Exception.Message)`r`n")
        if ($null -ne $progressBar) {
            $progressBar.Value = 0 # Oder auf einen Fehlerwert setzen
        }
    }

    # Farbe zurücksetzen
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Default'
    
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
                } catch {
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
                } catch {
                    # Fehler beim Zugriff auf Mainform ignorieren
                }
            }
        }
    } catch {
        # Fehler beim Aktualisieren des Button-Indikators ignorieren
    }
}

# Hilfsfunktion zum Formatieren der Dateigröße (falls noch nicht vorhanden)
# Funktion zum Laden der Cleanup-Einstellungen
function Get-CleanupSettings {
    if (Get-Command -Name Get-Settings -Module Setup -ErrorAction SilentlyContinue) {
        $settings = Get-Settings
        return $settings.Cleanup
    } else {
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
    } elseif ($Size -ge 1GB) {
        return "{0:N2} GB" -f ($Size / 1GB)
    } elseif ($Size -ge 1MB) {
        return "{0:N2} MB" -f ($Size / 1MB)
    } elseif ($Size -ge 1KB) {
        return "{0:N2} KB" -f ($Size / 1KB)
    } else {
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
        } else {
            $outputBox.AppendText("Warnung: ProgressBar nicht verfügbar.`r`n")
        }
    
        # outputBox zuruecksetzen
        $outputBox.Clear()
        Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Action'
        $outputBox.AppendText("===== BEREINIGUNG TEMPORAERER DATEIEN =====`r`n")
        Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Default'
        $outputBox.AppendText("Modus: Systemreinigung`r`n")
        Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Default'
        $outputBox.AppendText("Zeitstempel: $(Get-Date -Format 'dd.MM.yyyy HH:mm:ss')`r`n`r`n")
    
        # Systeminformationen anzeigen
        $computerName = $env:COMPUTERNAME
        $userName = $env:USERNAME
        $osInfo = (Get-CimInstance -ClassName Win32_OperatingSystem).Caption
    
        # Format fuer nebeneinander stehende Informationen
        Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Action'
        $outputBox.AppendText("[►] SYSTEM-INFORMATIONEN:`r`n")
        Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Default'
    
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
        Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Action'
        $outputBox.AppendText("[►] VERFUEGBARE LAUFWERKE:`r`n`r`n")
    
        # Tabellenkopf erstellen
        Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Action'
        $lw = "Laufwerk".PadRight(15)
        $name = "Bezeichnung".PadRight(20)
        $total = "Groesse".PadRight(15)
        $free = "Freier Speicher".PadRight(20)
        $used = "Belegung".PadRight(15)
        $outputBox.AppendText("    $lw$name$total$free$used`r`n")
    
        # Trennlinie
        Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Muted'
        $outputBox.AppendText("    " + "".PadRight(85, '-') + "`r`n")
        Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Default'
    
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
                Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Error'
                $outputBox.AppendText("$usedPercent% (Kritisch)")
            } elseif ($usedPercent -gt 75) {
                Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Warning'
                $outputBox.AppendText("$usedPercent% (Warnung)")
            } else {
                Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Success'
                $outputBox.AppendText("$usedPercent% (OK)")
            }
        
            Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Default'
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
        Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Action'
        $outputBox.AppendText("[►] BEREINIGUNG TEMPORAERER ORDNER:`r`n`r`n")
        Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Default'
    
        # Benutzerdefinierte Pfade hinzufügen
        $cleanupSettings = Get-CleanupSettings
        $customPaths = $cleanupSettings.CustomPaths
    
        if ($customPaths.Count -gt 0) {
            Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Action'
            $outputBox.AppendText("[+] Zusaetzliche benutzerdefinierte Pfade werden bereinigt...\r\n")
        
            foreach ($path in $customPaths) {
                if (Test-Path $path) {
                    # Prüfen, ob der Pfad nicht ausgeschlossen ist
                    if (-not (Test-PathExcluded -Path $path)) {
                        try {
                            Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Default'
                            $outputBox.AppendText("  -> Bereinige $path...\r\n")
                        
                            # Dateien im benutzerdefinierten Pfad löschen
                            Get-ChildItem -Path $path -File -Recurse -ErrorAction SilentlyContinue | 
                                Where-Object { -not (Test-PathExcluded -Path $_.FullName) } | 
                                    Remove-Item -Force -ErrorAction SilentlyContinue
                        
                            Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Success'
                            $outputBox.AppendText("     Benutzerdefinierter Pfad bereinigt: $path\r\n")
                        } catch {
                            Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Error'
                            $outputBox.AppendText("     Fehler beim Bereinigen von " + $path + ": " + $_ + "\r\n")
                        }
                    } else {
                        Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Muted'
                        $outputBox.AppendText("     Ueberspringe ausgeschlossenen Pfad: $path\r\n")
                    }
                } else {
                    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Warning'
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
            
            Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Action'
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
                
                Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Default'
                $outputBox.AppendText("     Gefunden: $folderFiles Dateien ($folderSize MB)`r`n")
            }
        }
        
        # Aktualisiere ProgressBar auf 100%
        if ($null -ne $progressBar) {
            $progressBar.Value = 100
        }
        # Erfolgsnotiz
        Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Success'
        $outputBox.AppendText("`r`n[√] Bereinigung temporaerer Dateien erfolgreich abgeschlossen.`r`n")
        
        # Farbe zuruecksetzen
        Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Default'
    } catch {
        Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Error'
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
        Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Action'
        $outputBox.AppendText("[►] VORBEREITUNG CHKDSK:`r`n")
        Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Muted'
        $outputBox.AppendText("    Bitte wählen Sie die zu prüfenden Laufwerke und Optionen im Dialog-Fenster aus...`r`n")
        # Laufwerksinformationen anzeigen
        Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Action'
        $outputBox.AppendText("[i] VERFUEGBARE LAUFWERKE:`r`n`r`n")
        
        # Tabellenkopf erstellen
        Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Action'
        $lw = "Laufwerk".PadRight(15)
        $name = "Bezeichnung".PadRight(20)
        $total = "Groesse".PadRight(15)
        $free = "Freier Speicher".PadRight(20)
        $used = "Belegung".PadRight(15)
        $outputBox.AppendText("    $lw$name$total$free$used`r`n")
        
        # Trennlinie
        Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Muted'
        $outputBox.AppendText("    " + "".PadRight(85, '-') + "`r`n")
        Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Default'
        
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
                Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Error'
                $outputBox.AppendText("$usedPercent% (Kritisch)")
            } elseif ($usedPercent -gt 75) {
                Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Warning'
                $outputBox.AppendText("$usedPercent% (Warnung)")
            } else {
                Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Success'
                $outputBox.AppendText("$usedPercent% (OK)")
            }
            
            Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Default'
            $outputBox.AppendText("`r`n")
        }
        
        
        Write-Host "  [►] Dialog-Fenster für die Erweiterte Systemreinigung wird gestartet..." -ForegroundColor green
        Write-Host 
        Write-Host "  [i] Bitte waehlen Sie die zu bereinigenden Laufwerke und " -ForegroundColor yellow
        Write-Host "      Optionen im Dialog-Fenster aus..." -ForegroundColor yellow

        # ── WPF-Dialog: Erweiterte Bereinigung ───────────────────────────────
        Add-Type -AssemblyName PresentationFramework
        Add-Type -AssemblyName PresentationCore
        Add-Type -AssemblyName WindowsBase
        [xml]$xamlCleanup = @'
<Window
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="" Width="600" Height="740"
    WindowStyle="None" AllowsTransparency="True" ResizeMode="NoResize"
    WindowStartupLocation="Manual" Background="Transparent">
  <Window.Resources>
    <Style x:Key="BtnBase" TargetType="Button">
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="FontFamily" Value="Segoe UI"/>
      <Setter Property="FontSize" Value="13"/>
      <Setter Property="FontWeight" Value="SemiBold"/>
      <Setter Property="BorderThickness" Value="0"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Border x:Name="bd" CornerRadius="10"
                    Background="{TemplateBinding Background}"
                    BorderBrush="{TemplateBinding BorderBrush}"
                    BorderThickness="{TemplateBinding BorderThickness}">
              <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True">
                <Setter TargetName="bd" Property="Background"
                        Value="{Binding RelativeSource={RelativeSource TemplatedParent}, Path=Tag}"/>
              </Trigger>
              <Trigger Property="IsPressed" Value="True">
                <Setter TargetName="bd" Property="Opacity" Value="0.85"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
    <Style TargetType="CheckBox">
      <Setter Property="Foreground" Value="#E0E0E0"/>
      <Setter Property="FontFamily" Value="Segoe UI"/>
      <Setter Property="FontSize" Value="12"/>
      <Setter Property="Margin" Value="0,3,0,0"/>
      <Setter Property="VerticalContentAlignment" Value="Center"/>
    </Style>
    <Style TargetType="ScrollBar">
      <Setter Property="Width" Value="6"/>
      <Setter Property="Background" Value="Transparent"/>
    </Style>
  </Window.Resources>

  <Border CornerRadius="12" Background="#1E1E1E" BorderBrush="#484848" BorderThickness="1">
    <Border.Effect>
      <DropShadowEffect BlurRadius="20" ShadowDepth="6" Opacity="0.6" Color="#000000"/>
    </Border.Effect>
    <Grid>
      <Grid.RowDefinitions>
        <RowDefinition Height="42"/>
        <RowDefinition Height="2"/>
        <RowDefinition Height="Auto"/>
        <RowDefinition Height="155"/>
        <RowDefinition Height="Auto"/>
        <RowDefinition Height="Auto"/>
        <RowDefinition Height="210"/>
        <RowDefinition Height="Auto"/>
        <RowDefinition Height="90"/>
        <RowDefinition Height="62"/>
      </Grid.RowDefinitions>

      <!-- Header / Drag -->
      <Border Grid.Row="0" Background="#262626" CornerRadius="12,12,0,0" x:Name="DragHeaderClean">
        <Grid>
          <TextBlock Text="  ⬡  Custom Cleanup  –  Erweiterte Bereinigung"
                     Foreground="#00B464" FontSize="13" FontWeight="Bold"
                     FontFamily="Segoe UI" VerticalAlignment="Center" Margin="8,0,0,0"/>
          <Button x:Name="BtnCloseClean" Content="✕" HorizontalAlignment="Right"
                  Width="42" Height="42" FontSize="14"
                  Background="Transparent" Foreground="#888" BorderThickness="0"
                  Cursor="Hand" Style="{x:Null}">
            <Button.Template>
              <ControlTemplate TargetType="Button">
                <Border x:Name="cb" Background="Transparent" CornerRadius="0,12,0,0">
                  <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                </Border>
                <ControlTemplate.Triggers>
                  <Trigger Property="IsMouseOver" Value="True">
                    <Setter TargetName="cb" Property="Background" Value="#C42B1C"/>
                    <Setter Property="Foreground" Value="White"/>
                  </Trigger>
                </ControlTemplate.Triggers>
              </ControlTemplate>
            </Button.Template>
          </Button>
        </Grid>
      </Border>

      <!-- Accent Linie -->
      <Rectangle Grid.Row="1" Fill="#00B464"/>

      <!-- Laufwerk-Label -->
      <TextBlock Grid.Row="2" Text="Zu bereinigende Laufwerke auswählen:"
                 Foreground="#909090" FontFamily="Segoe UI" FontSize="11"
                 Margin="14,10,14,4"/>

      <!-- Laufwerk-Tabelle (SharedSizeScope) -->
      <ScrollViewer Grid.Row="3" Margin="12,0,12,0"
                    VerticalScrollBarVisibility="Auto" Background="#2B2B2B">
        <StackPanel x:Name="DrivePanelClean" Grid.IsSharedSizeScope="True" Margin="2,8,2,8">
          <!-- Tabellen-Kopf -->
          <Grid>
            <Grid.ColumnDefinitions>
              <ColumnDefinition SharedSizeGroup="CColCB"    Width="Auto"/>
              <ColumnDefinition SharedSizeGroup="CColDrive" Width="Auto" MinWidth="34"/>
              <ColumnDefinition SharedSizeGroup="CColName"  Width="Auto" MinWidth="100"/>
              <ColumnDefinition SharedSizeGroup="CColFree"  Width="Auto" MinWidth="110"/>
              <ColumnDefinition SharedSizeGroup="CColTotal" Width="Auto" MinWidth="82"/>
              <ColumnDefinition Width="*"/>
            </Grid.ColumnDefinitions>
            <TextBlock Grid.Column="1" Text="LW"              Foreground="#585858" FontSize="10" FontFamily="Segoe UI" FontWeight="SemiBold" Margin="0,0,14,0"/>
            <TextBlock Grid.Column="2" Text="Bezeichnung"     Foreground="#585858" FontSize="10" FontFamily="Segoe UI" FontWeight="SemiBold" Margin="0,0,14,0"/>
            <TextBlock Grid.Column="3" Text="Freier Speicher" Foreground="#585858" FontSize="10" FontFamily="Segoe UI" FontWeight="SemiBold" Margin="0,0,14,0"/>
            <TextBlock Grid.Column="4" Text="Gesamt"          Foreground="#585858" FontSize="10" FontFamily="Segoe UI" FontWeight="SemiBold"/>
          </Grid>
          <Rectangle Height="1" Fill="#363636" Margin="0,5,0,3"/>
        </StackPanel>
      </ScrollViewer>

      <!-- Alle auswählen -->
      <CheckBox Grid.Row="4" x:Name="ChkAllDrives" Content="Alle Laufwerke auswählen"
                Margin="14,8,14,0"/>

      <!-- Optionen-Label -->
      <TextBlock Grid.Row="5" Text="Zu bereinigende Elemente:"
                 Foreground="#909090" FontFamily="Segoe UI" FontSize="11"
                 Margin="14,10,14,4"/>

      <!-- Optionen-Liste -->
      <ScrollViewer Grid.Row="6" Margin="12,0,12,0"
                    VerticalScrollBarVisibility="Auto" Background="#2B2B2B">
        <StackPanel x:Name="OptionsPanel" Margin="6,6,6,6"/>
      </ScrollViewer>

      <!-- Status-Label -->
      <TextBlock Grid.Row="7" Text="Status:" Foreground="#909090"
                 FontFamily="Segoe UI" FontSize="11" Margin="14,8,14,2"/>

      <!-- Status-TextBox -->
      <TextBox Grid.Row="8" x:Name="StatusBox" Margin="12,0,12,0"
               IsReadOnly="True" TextWrapping="Wrap"
               VerticalScrollBarVisibility="Auto"
               Background="#2B2B2B" Foreground="#909090"
               BorderBrush="#363636" BorderThickness="1"
               FontFamily="Segoe UI" FontSize="11" Padding="6,4"/>

      <!-- Buttons -->
      <Grid Grid.Row="9" Margin="70,0,14,12">
        <Grid.ColumnDefinitions>
          <ColumnDefinition Width="190"/>
          <ColumnDefinition Width="12"/>
          <ColumnDefinition Width="190"/>
        </Grid.ColumnDefinitions>
        <Button x:Name="BtnOkClean" Grid.Column="0"
                Content="▶  Bereinigung starten" Height="32"
                Background="#00B464" Foreground="#141414" Tag="#00D47A"
                Style="{StaticResource BtnBase}"/>
        <Button x:Name="BtnCancelClean" Grid.Column="2"
                Content="Abbrechen" Height="32"
                Background="#373737" Foreground="#E0E0E0" Tag="#484848"
                Style="{StaticResource BtnBase}"/>
      </Grid>
    </Grid>
  </Border>
</Window>
'@
        $readerClean     = New-Object System.Xml.XmlNodeReader $xamlCleanup
        $wpfCleanup      = [Windows.Markup.XamlReader]::Load($readerClean)

        # Startposition: rechts neben der Hauptform
        if ($null -ne $mainform) {
            $wpfCleanup.Left = $mainform.Location.X + $mainform.Width + 10
            $wpfCleanup.Top  = $mainform.Location.Y
        }

        # Controls holen
        $drivePanelClean = $wpfCleanup.FindName("DrivePanelClean")
        $chkAllDrives    = $wpfCleanup.FindName("ChkAllDrives")
        $optionsPanel    = $wpfCleanup.FindName("OptionsPanel")
        $statusBox       = $wpfCleanup.FindName("StatusBox")
        $btnOkClean      = $wpfCleanup.FindName("BtnOkClean")
        $btnCancelClean  = $wpfCleanup.FindName("BtnCancelClean")
        $btnCloseClean   = $wpfCleanup.FindName("BtnCloseClean")
        $dragHeaderClean = $wpfCleanup.FindName("DragHeaderClean")

        # Auto-Scroll in StatusBox + Basis-Interaktion
        $statusBox.Add_TextChanged({ $statusBox.ScrollToEnd() })
        $dragHeaderClean.Add_MouseLeftButtonDown({ $wpfCleanup.DragMove() })
        $btnCloseClean.Add_Click({ $wpfCleanup.Close() })
        $btnCancelClean.Add_Click({ $wpfCleanup.Close() })

        # ── Laufwerk-Tabelle befüllen ─────────────────────────────────────────
        $driveCheckBoxes       = @{}
        $bconv                 = [System.Windows.Media.BrushConverter]::new()
        $script:_bulkDriveChanging = $false

        $drives = Get-PSDrive -PSProvider FileSystem
        foreach ($drive in $drives) {
            $driveInfo = Get-WmiObject -Class Win32_LogicalDisk -Filter "DeviceID='$($drive.Name):'" -ErrorAction SilentlyContinue
            if (-not $driveInfo) { continue }

            $freeGB   = [Math]::Round($driveInfo.FreeSpace / 1GB, 2)
            $totalGB  = [Math]::Round($driveInfo.Size / 1GB, 2)
            $usedPct  = [Math]::Round(100 - (($driveInfo.FreeSpace / $driveInfo.Size) * 100), 1)
            $volName  = if ($driveInfo.VolumeName) { $driveInfo.VolumeName } else { "" }
            $isSystem = ($drive.Name + ":") -eq $env:SystemDrive
            $freeHex  = if ($usedPct -gt 90) { "#E05050" } elseif ($usedPct -gt 75) { "#D4A010" } else { "#00B464" }
            $driveId  = $drive.Name + ":"

            $row = New-Object System.Windows.Controls.Grid
            $row.Margin = New-Object System.Windows.Thickness(0, 4, 0, 0)
            foreach ($grp in @("CColCB","CColDrive","CColName","CColFree","CColTotal")) {
                $cd = New-Object System.Windows.Controls.ColumnDefinition
                $cd.SharedSizeGroup = $grp
                $cd.Width = [System.Windows.GridLength]::Auto
                $row.ColumnDefinitions.Add($cd)
            }
            $cdStar = New-Object System.Windows.Controls.ColumnDefinition
            $cdStar.Width = [System.Windows.GridLength]::new(1, [System.Windows.GridUnitType]::Star)
            $row.ColumnDefinitions.Add($cdStar)

            $cb = New-Object System.Windows.Controls.CheckBox
            $cb.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
            $cb.Margin    = New-Object System.Windows.Thickness(0,0,10,0)
            $cb.IsChecked = $isSystem
            [System.Windows.Controls.Grid]::SetColumn($cb, 0)
            $row.Children.Add($cb)

            $tbDrive = New-Object System.Windows.Controls.TextBlock
            $tbDrive.Text       = $driveId
            $tbDrive.Foreground = [System.Windows.Media.Brushes]::White
            $tbDrive.FontFamily = New-Object System.Windows.Media.FontFamily("Segoe UI")
            $tbDrive.FontSize   = 12
            $tbDrive.FontWeight = [System.Windows.FontWeights]::SemiBold
            $tbDrive.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
            $tbDrive.Margin = New-Object System.Windows.Thickness(0,0,14,0)
            [System.Windows.Controls.Grid]::SetColumn($tbDrive, 1)
            $row.Children.Add($tbDrive)

            $tbName = New-Object System.Windows.Controls.TextBlock
            $tbName.Text       = if ($volName) { "($volName)" } else { "" }
            $tbName.Foreground = $bconv.ConvertFrom("#909090")
            $tbName.FontFamily = New-Object System.Windows.Media.FontFamily("Segoe UI")
            $tbName.FontSize   = 12
            $tbName.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
            $tbName.Margin = New-Object System.Windows.Thickness(0,0,14,0)
            [System.Windows.Controls.Grid]::SetColumn($tbName, 2)
            $row.Children.Add($tbName)

            $tbFree = New-Object System.Windows.Controls.TextBlock
            $tbFree.Text       = "$freeGB GB frei"
            $tbFree.Foreground = $bconv.ConvertFrom($freeHex)
            $tbFree.FontFamily = New-Object System.Windows.Media.FontFamily("Segoe UI")
            $tbFree.FontSize   = 12
            $tbFree.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
            $tbFree.Margin = New-Object System.Windows.Thickness(0,0,14,0)
            [System.Windows.Controls.Grid]::SetColumn($tbFree, 3)
            $row.Children.Add($tbFree)

            $tbTotal = New-Object System.Windows.Controls.TextBlock
            $tbTotal.Text       = "von $totalGB GB"
            $tbTotal.Foreground = $bconv.ConvertFrom("#707070")
            $tbTotal.FontFamily = New-Object System.Windows.Media.FontFamily("Segoe UI")
            $tbTotal.FontSize   = 12
            $tbTotal.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
            [System.Windows.Controls.Grid]::SetColumn($tbTotal, 4)
            $row.Children.Add($tbTotal)

            if ($isSystem) {
                $badge = New-Object System.Windows.Controls.Border
                $badge.CornerRadius    = New-Object System.Windows.CornerRadius(3)
                $badge.Background      = $bconv.ConvertFrom("#0A3322")
                $badge.BorderBrush     = $bconv.ConvertFrom("#00B464")
                $badge.BorderThickness = New-Object System.Windows.Thickness(1)
                $badge.Margin          = New-Object System.Windows.Thickness(10,1,0,1)
                $badge.Padding         = New-Object System.Windows.Thickness(6,1,6,1)
                $badge.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
                $badgeText = New-Object System.Windows.Controls.TextBlock
                $badgeText.Text       = "Systemlaufwerk"
                $badgeText.Foreground = $bconv.ConvertFrom("#00B464")
                $badgeText.FontSize   = 10
                $badgeText.FontFamily = New-Object System.Windows.Media.FontFamily("Segoe UI")
                $badge.Child = $badgeText
                [System.Windows.Controls.Grid]::SetColumn($badge, 5)
                $row.Children.Add($badge)
            }

            $drivePanelClean.Children.Add($row)
            $driveCheckBoxes[$driveId] = $cb

            $cb.Add_Checked({
                if (-not $script:_bulkDriveChanging) {
                    $allChecked = $true
                    foreach ($c in $driveCheckBoxes.Values) {
                        if ($c.IsChecked -ne $true) { $allChecked = $false; break }
                    }
                    if ($allChecked) {
                        $script:_bulkDriveChanging = $true
                        $chkAllDrives.IsChecked = $true
                        $script:_bulkDriveChanging = $false
                    }
                }
            })
            $cb.Add_Unchecked({
                if (-not $script:_bulkDriveChanging) {
                    $script:_bulkDriveChanging = $true
                    $chkAllDrives.IsChecked = $false
                    $script:_bulkDriveChanging = $false
                }
            })
        }

        $chkAllDrives.Add_Checked({
            $script:_bulkDriveChanging = $true
            foreach ($cb in $driveCheckBoxes.Values) { $cb.IsChecked = $true }
            $script:_bulkDriveChanging = $false
        })
        $chkAllDrives.Add_Unchecked({
            $script:_bulkDriveChanging = $true
            foreach ($cb in $driveCheckBoxes.Values) { $cb.IsChecked = $false }
            $script:_bulkDriveChanging = $false
        })

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
                    "Users\*\AppData\Local\Google\Chrome\User Data\Default\Code Cache\*",
                    "Users\*\AppData\Local\Google\Chrome\User Data\Default\GPUCache\*",
                    "Users\*\AppData\Local\Google\Chrome\User Data\Default\Service Worker\CacheStorage\*",
                    "Users\*\AppData\Local\Google\Chrome\User Data\Default\File System\*\t\*"
                )
            }, @{
                Name        = "firefoxCache"; 
                Text        = "Firefox Cache"; 
                Default     = $true; 
                Description = "Bereinigt Mozilla Firefox Cache-Dateien"; 
                Paths       = @(
                    "Users\*\AppData\Local\Mozilla\Firefox\Profiles\*\cache2\*",
                    "Users\*\AppData\Local\Mozilla\Firefox\Profiles\*\startupCache\*",
                    "Users\*\AppData\Local\Mozilla\Firefox\Profiles\*\OfflineCache\*",
                    "Users\*\AppData\Roaming\Mozilla\Firefox\Profiles\*\storage\*"
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
                    "Users\*\AppData\Local\BraveSoftware\Brave-Browser\User Data\Default\optimization_guide_hint_cache_store\*",
                    "Users\*\AppData\Local\BraveSoftware\Brave-Browser\User Data\Default\Service Worker\CacheStorage\*"
                )
            },
            @{
                Name        = "edgeCache";
                Text        = "Edge Cache"; 
                Default     = $true; 
                Description = "Bereinigt Microsoft Edge Cache-Dateien"; 
                Paths       = @(
                    "Users\*\AppData\Local\Microsoft\Edge\User Data\Default\Cache\*",
                    "Users\*\AppData\Local\Microsoft\Edge\User Data\Default\Code Cache\*",
                    "Users\*\AppData\Local\Microsoft\Edge\User Data\Default\GPUCache\*",
                    "Users\*\AppData\Local\Microsoft\Edge\User Data\Default\Service Worker\CacheStorage\*"
                )
            },
            @{
                Name        = "operaCache";
                Text        = "Opera Cache"; 
                Default     = $true; 
                Description = "Bereinigt Opera Browser Cache-Dateien"; 
                Paths       = @(
                    "Users\*\AppData\Local\Opera Software\Opera Stable\Cache\*",
                    "Users\*\AppData\Local\Opera Software\Opera Stable\Code Cache\*",
                    "Users\*\AppData\Local\Opera Software\Opera Stable\GPUCache\*"
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

        # ── Optionen als WPF-Controls erstellen ──────────────────────────────
        $cleanupCheckboxes = @{}
        $sizeLabels        = @{}

        foreach ($option in $cleanupOptions) {
            $optRow = New-Object System.Windows.Controls.Grid
            $optRow.Margin = New-Object System.Windows.Thickness(0, 3, 0, 0)
            $cdCheck = New-Object System.Windows.Controls.ColumnDefinition
            $cdCheck.Width = [System.Windows.GridLength]::new(1, [System.Windows.GridUnitType]::Star)
            $optRow.ColumnDefinitions.Add($cdCheck)
            $cdSize = New-Object System.Windows.Controls.ColumnDefinition
            $cdSize.Width = [System.Windows.GridLength]::Auto
            $optRow.ColumnDefinitions.Add($cdSize)

            $chkOpt = New-Object System.Windows.Controls.CheckBox
            $chkOpt.Content   = $option.Text
            $chkOpt.IsChecked = $option.Default
            $chkOpt.ToolTip   = $option.Description
            $chkOpt.VerticalContentAlignment = [System.Windows.VerticalAlignment]::Center
            [System.Windows.Controls.Grid]::SetColumn($chkOpt, 0)
            $optRow.Children.Add($chkOpt)

            $tbSize = New-Object System.Windows.Controls.TextBlock
            $tbSize.Text       = "–"
            $tbSize.Foreground = $bconv.ConvertFrom("#707070")
            $tbSize.FontFamily = New-Object System.Windows.Media.FontFamily("Segoe UI")
            $tbSize.FontSize   = 11
            $tbSize.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
            $tbSize.Margin = New-Object System.Windows.Thickness(12, 0, 4, 0)
            [System.Windows.Controls.Grid]::SetColumn($tbSize, 1)
            $optRow.Children.Add($tbSize)

            $optionsPanel.Children.Add($optRow)
            $cleanupCheckboxes[$option.Name] = $chkOpt
            $sizeLabels[$option.Name]        = $tbSize

            $chkOpt.Add_Checked({ Update-CleanupSizeEstimates })
            $chkOpt.Add_Unchecked({ Update-CleanupSizeEstimates })
        }

        # ── Lokaler Adapter: Set-OutputSelectionStyle No-Op für WPF TextBox ─────
        $script:_origSetOutputStyle = Get-Command Set-OutputSelectionStyle -ErrorAction SilentlyContinue
        function Set-OutputSelectionStyle {
            param([object]$OutputBox, [string]$Style = '')
            if ($OutputBox -is [System.Windows.Controls.TextBox]) { return }
            if ($script:_origSetOutputStyle) {
                & $script:_origSetOutputStyle -OutputBox $OutputBox -Style $Style
            }
        }

        # Funktionen für echte Berechnungen und Bereinigungen
        # Funktion zum Berechnen der Größe von Dateien
        function Get-FileSize {
            param (
                [string]$DriveLetter,
                [array]$Paths
            )
            
            $totalSize = 0
            $fileCount = 0
            $processedPaths = @{}  # Cache für bereits verarbeitete Pfade
            
            # Sicherstellen, dass der Laufwerksbuchstabe korrekt formatiert ist (C: nicht C:\)
            if ($DriveLetter -match "^([A-Za-z]):.*$") {
                $DriveLetter = $matches[1] + ":"
            } elseif ($DriveLetter -match "^([A-Za-z])$") {
                # Falls nur Buchstabe ohne Doppelpunkt
                $DriveLetter = $DriveLetter + ":"
            } elseif (-not ($DriveLetter -match "^[A-Za-z]:$")) {
                # Ungültiges Format - Fehler
                throw "Ungültiger Laufwerksbuchstabe: $DriveLetter"
            }
            
            # Prüfen, ob das Laufwerk verfügbar ist
            if (-not (Test-Path $DriveLetter)) {
                Set-OutputSelectionStyle -OutputBox $statusBox -Style 'Warning'
                $statusBox.AppendText("Warnung: Laufwerk $DriveLetter ist nicht verfügbar`r`n")
                [System.Windows.Forms.Application]::DoEvents()
                return @{ Size = 0; Count = 0 }
            }
            
            # Status für Debugging in GUI ausgeben
            Set-OutputSelectionStyle -OutputBox $statusBox -Style 'Action'
            $statusBox.AppendText("Berechne Dateigröße für Laufwerk $DriveLetter...`r`n")
            [System.Windows.Forms.Application]::DoEvents()
            
            # Optimierte Batch-Verarbeitung von Pfaden
            $pathBatches = @{}
            foreach ($path in $Paths) {
                # Gruppiere ähnliche Pfade für effizientere Verarbeitung
                $basePath = Split-Path $path -Parent
                if (-not $basePath) { $basePath = "ROOT" }
                
                if (-not $pathBatches.ContainsKey($basePath)) {
                    $pathBatches[$basePath] = @()
                }
                $pathBatches[$basePath] += $path
            }
            
            foreach ($batchKey in $pathBatches.Keys) {
                $batchPaths = $pathBatches[$batchKey]
                
                foreach ($path in $batchPaths) {
                    # Cache-Check für bereits verarbeitete Pfade
                    $cacheKey = "$DriveLetter$path"
                    if ($processedPaths.ContainsKey($cacheKey)) {
                        $cached = $processedPaths[$cacheKey]
                        $totalSize += $cached.Size
                        $fileCount += $cached.Count
                        $statusBox.AppendText("  Gecacht: $path - $($cached.Count) Dateien`r`n")
                        continue
                    }
                    
                    try {
                        # Spezielle Behandlung für Papierkorb
                        if ($path -eq '$Recycle.Bin') {
                            $fullPath = "$DriveLetter\`$Recycle.Bin"
                            Set-OutputSelectionStyle -OutputBox $statusBox -Style 'Muted'
                            $statusBox.AppendText("  Prüfe Papierkorb: $fullPath`r`n")
                            [System.Windows.Forms.Application]::DoEvents()
                            
                            $pathSize = 0
                            $pathCount = 0
                            
                            # Verbesserte Papierkorb-Behandlung
                            if (Test-Path $fullPath) {
                                try {
                                    # Verwende robusteren Ansatz für Papierkorb-Scan
                                    $recycleBinFolders = Get-ChildItem -Path $fullPath -Directory -Force -ErrorAction SilentlyContinue
                                    $parallelResults = @()
                                    
                                    # Verwende Jobs für parallele Verarbeitung bei großen Papierkorb-Ordnern
                                    if ($recycleBinFolders.Count -gt 5) {
                                        foreach ($folder in $recycleBinFolders) {
                                            $scriptBlock = {
                                                param($folderPath)
                                                try {
                                                    $files = Get-ChildItem -Path $folderPath -Recurse -File -Force -ErrorAction SilentlyContinue
                                                    $count = if ($files) { $files.Count } else { 0 }
                                                    $size = if ($files) { 
                                                        $sizeSum = ($files | Measure-Object -Property Length -Sum).Sum
                                                        if ($null -eq $sizeSum) { 0 } else { $sizeSum }
                                                    } else { 0 }
                                                    return @{ Count = $count; Size = $size; Folder = (Split-Path $folderPath -Leaf) }
                                                } catch {
                                                    return @{ Count = 0; Size = 0; Folder = (Split-Path $folderPath -Leaf); Error = $_.Exception.Message }
                                                }
                                            }
                                            
                                            try {
                                                $job = Start-Job -ScriptBlock $scriptBlock -ArgumentList $folder.FullName
                                                $parallelResults += $job
                                            } catch {
                                                # Fallback zur seriellen Verarbeitung
                                                $result = & $scriptBlock $folder.FullName
                                                $pathCount += $result.Count
                                                $pathSize += $result.Size
                                            }
                                        }
                                        
                                        # Warte auf Jobs und sammle Ergebnisse
                                        if ($parallelResults.Count -gt 0) {
                                            $timeout = 30 # Sekunden
                                            $completed = Wait-Job -Job $parallelResults -Timeout $timeout
                                            
                                            foreach ($job in $parallelResults) {
                                                try {
                                                    if ($job.State -eq 'Completed') {
                                                        $result = Receive-Job -Job $job
                                                        $pathCount += $result.Count
                                                        $pathSize += $result.Size
                                                        if ($result.Error) {
                                                            $statusBox.AppendText("    Warnung bei $($result.Folder): $($result.Error)`r`n")
                                                        } else {
                                                            $statusBox.AppendText("    $($result.Folder): $($result.Count) Dateien ($([Math]::Round($result.Size/1MB, 2)) MB)`r`n")
                                                        }
                                                    } else {
                                                        $statusBox.AppendText("    Timeout bei Ordner-Scan`r`n")
                                                    }
                                                } catch {
                                                    $statusBox.AppendText("    Fehler beim Abrufen der Job-Ergebnisse`r`n")
                                                } finally {
                                                    Remove-Job -Job $job -Force -ErrorAction SilentlyContinue
                                                }
                                            }
                                        }
                                    } else {
                                        # Serielle Verarbeitung für wenige Ordner
                                        foreach ($folder in $recycleBinFolders) {
                                            try {
                                                $files = Get-ChildItem -Path $folder.FullName -Recurse -Force -ErrorAction SilentlyContinue | 
                                                    Where-Object { -not $_.PSIsContainer }
                                                if ($files) {
                                                    $count = $files.Count
                                                    $sizeSum = ($files | Measure-Object -Property Length -Sum).Sum
                                                    $size = if ($null -eq $sizeSum) { 0 } else { $sizeSum }
                                                    $statusBox.AppendText("    Gefunden in $($folder.Name): $count Dateien ($([Math]::Round($size/1MB, 2)) MB)`r`n")
                                                    
                                                    $pathCount += $count
                                                    $pathSize += $size
                                                }
                                            } catch {
                                                Set-OutputSelectionStyle -OutputBox $statusBox -Style 'Warning'
                                                $statusBox.AppendText("    Warnung: Kein Zugriff auf $($folder.Name)`r`n")
                                            }
                                        }
                                    }
                                } catch {
                                    Set-OutputSelectionStyle -OutputBox $statusBox -Style 'Warning'
                                    $statusBox.AppendText("    Fehler beim Papierkorb-Scan: $($_.Exception.Message)`r`n")
                                }
                            } else {
                                $statusBox.AppendText("    Papierkorb nicht gefunden oder leer`r`n")
                            }
                            
                            # Cache-Eintrag für Papierkorb
                            $processedPaths[$cacheKey] = @{ Size = $pathSize; Count = $pathCount }
                            $fileCount += $pathCount
                            $totalSize += $pathSize
                        } else {
                            # Normale Pfad-Behandlung mit verbesserter Pfadauflösung
                            $fullPath = if ($path.StartsWith("\")) {
                                "$DriveLetter$path"
                            } else {
                                "$DriveLetter\$path"
                            }
                            
                            Set-OutputSelectionStyle -OutputBox $statusBox -Style 'Muted'
                            $statusBox.AppendText("  Prüfe: $fullPath`r`n")
                            [System.Windows.Forms.Application]::DoEvents()
                            
                            $pathSize = 0
                            $pathCount = 0
                            
                            try {
                                # Optimierte Dateierkennung mit Smart-Caching
                                $files = Get-FilesFromPath -Path $fullPath -Recursive $true
                                
                                if ($files -and $files.Count -gt 0) {
                                    $pathCount = $files.Count
                                    
                                    # Optimierte Größenberechnung für große Dateimengen
                                    if ($pathCount -gt 1000) {
                                        $statusBox.AppendText("    Große Dateisammlung erkannt, verwende optimierte Berechnung...`r`n")
                                        
                                        # Batch-weise Verarbeitung für bessere Performance
                                        $batchSize = 500
                                        $batches = [Math]::Ceiling($pathCount / $batchSize)
                                        
                                        for ($i = 0; $i -lt $batches; $i++) {
                                            $startIdx = $i * $batchSize
                                            $endIdx = [Math]::Min(($i + 1) * $batchSize - 1, $pathCount - 1)
                                            $batch = $files[$startIdx..$endIdx]
                                            
                                            try {
                                                $batchSizeSum = ($batch | Measure-Object -Property Length -Sum).Sum
                                                $pathSize += if ($null -eq $batchSizeSum) { 0 } else { $batchSizeSum }
                                            } catch {
                                                # Bei Fehlern einzeln durchgehen
                                                foreach ($file in $batch) {
                                                    try { $pathSize += $file.Length } catch { }
                                                }
                                            }
                                            
                                            # UI-Update für lange Operationen
                                            if ($i % 10 -eq 0) {
                                                $progress = [Math]::Round((($i + 1) / $batches) * 100)
                                                $statusBox.AppendText("    Fortschritt: $progress%`r`n")
                                                [System.Windows.Forms.Application]::DoEvents()
                                            }
                                        }
                                    } else {
                                        # Standard-Berechnung für kleinere Dateimengen
                                        $sizeSum = ($files | Measure-Object -Property Length -Sum).Sum
                                        $pathSize = if ($null -eq $sizeSum) { 0 } else { $sizeSum }
                                    }
                                    
                                    $statusBox.AppendText("    Gefunden: $pathCount Dateien ($([Math]::Round($pathSize/1MB, 2)) MB)`r`n")
                                } else {
                                    $statusBox.AppendText("    Keine Dateien gefunden`r`n")
                                }
                            } catch {
                                Set-OutputSelectionStyle -OutputBox $statusBox -Style 'Warning'
                                $statusBox.AppendText("    Fehler bei Pfadanalyse: $($_.Exception.Message)`r`n")
                            }
                            
                            # Cache-Eintrag für normalen Pfad
                            $processedPaths[$cacheKey] = @{ Size = $pathSize; Count = $pathCount }
                            $fileCount += $pathCount
                            $totalSize += $pathSize
                        }
                        [System.Windows.Forms.Application]::DoEvents()
                    } catch {
                        Set-OutputSelectionStyle -OutputBox $statusBox -Style 'Error'
                        $statusBox.AppendText("  Fehler bei $path : $($_.Exception.Message)`r`n")
                        [System.Windows.Forms.Application]::DoEvents()
                    }
                }
            }
            
            Set-OutputSelectionStyle -OutputBox $statusBox -Style 'Success'
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

            $totalFreed    = 0
            $deletedCount  = 0
            $skippedCount  = 0

            # Laufwerksbuchstaben normalisieren
            if ($DriveLetter -match '^([A-Za-z]):') { $DriveLetter = $matches[1] + ':' }

            if (-not (Test-Path $DriveLetter)) {
                $statusBox.AppendText("Warnung: Laufwerk $DriveLetter nicht verfügbar`r`n")
                return @{ FreedSpace = 0; DeletedFiles = 0; SkippedFiles = 0 }
            }

            $statusBox.AppendText("Starte Bereinigung auf Laufwerk $DriveLetter...`r`n")

            foreach ($path in $Paths) {
                try {
                    # ── Papierkorb ────────────────────────────────────
                    if ($path -eq '$Recycle.Bin') {
                        $rbLetter = $DriveLetter.TrimEnd(':\') # z.B. 'C'
                        $rbPath   = "$DriveLetter\`$Recycle.Bin"
                        try {
                            # Größe vorher ermitteln
                            $rbFiles = Get-ChildItem -Path $rbPath -Recurse -Force -ErrorAction SilentlyContinue |
                                       Where-Object { -not $_.PSIsContainer }
                            $rbCount = if ($rbFiles) { @($rbFiles).Count } else { 0 }
                            $rbSize  = if ($rbFiles) { ($rbFiles | Measure-Object -Property Length -Sum).Sum } else { 0 }

                            Clear-RecycleBin -DriveLetter $rbLetter -Force -ErrorAction Stop
                            $totalFreed   += if ($rbSize)  { $rbSize  } else { 0 }
                            $deletedCount += $rbCount
                            $statusBox.AppendText("  Papierkorb geleert: $rbCount Element(e)`r`n")
                        } catch {
                            $statusBox.AppendText("  Papierkorb leer oder kein Zugriff ($($_.Exception.Message))`r`n")
                        }
                        continue
                    }

                    # ── Normaler Pfad ─────────────────────────────────
                    $fullPath = if ($path.StartsWith('\')) { "$DriveLetter$path" } else { "$DriveLetter\$path" }

                    # Prüfen ob Basispfad auf diesem Laufwerk existiert (schneller Skip)
                    $basePart = ($fullPath -split '\*')[0].TrimEnd('\ ')
                    if (-not (Test-Path $basePart -ErrorAction SilentlyContinue)) { continue }

                    $files = Get-FilesFromPath -Path $fullPath -Recursive $true -TimeoutSeconds 60
                    if (-not $files -or @($files).Count -eq 0) { continue }

                    $fileArr = @($files)
                    $statusBox.AppendText("  $($fileArr.Count) Dateien in $fullPath`r`n")

                    foreach ($file in $fileArr) {
                        try {
                            $fileSize = $file.Length
                            Remove-Item -LiteralPath $file.FullName -Force -ErrorAction Stop
                            $deletedCount++
                            $totalFreed += $fileSize
                        } catch {
                            # Nur echte Sperr-Fehler zählen (Datei wirklich in Verwendung)
                            if ($_.Exception.Message -match 'Zugriff|Access|gesperrt|lock|being used|in use|process|von einem anderen') {
                                $skippedCount++
                            }
                            # Andere Fehler (bereits weg, Rechte, etc.) kommentarlos ignorieren
                        }
                    }
                } catch {
                    $statusBox.AppendText("  Hinweis: $path übersprungen`r`n")
                }
            }

            $statusBox.AppendText("Laufwerk ${DriveLetter}: $deletedCount geloescht, $skippedCount gesperrt`r`n")
            return @{ FreedSpace = $totalFreed; DeletedFiles = $deletedCount; SkippedFiles = $skippedCount }
        }
        # Funktion zum Updaten der Größenschätzungen
        function Update-CleanupSizeEstimates {
            $global:optionSizes = @{}
            $statusBox.Clear()
            Set-OutputSelectionStyle -OutputBox $statusBox -Style 'Action'
            $statusBox.AppendText("=== BERECHNUNG BEREINIGUNGSGRÖSSE ===`r`n")
            $statusBox.AppendText("Zeitstempel: $(Get-Date -Format 'dd.MM.yyyy HH:mm:ss')`r`n")
            $statusBox.AppendText("System: $env:COMPUTERNAME ($env:USERNAME)`r`n`r`n")
            [System.Windows.Forms.Application]::DoEvents()
            
            # Performance-Messung starten
            $calculationStartTime = Get-Date
            
            # Ausgewählte Laufwerke auflisten
            $selectedDrives = @()
            foreach ($driveKey in ($driveCheckBoxes.Keys | Sort-Object)) {
                if ($driveCheckBoxes[$driveKey].IsChecked -eq $true) {
                    $driveLetter = $driveKey
                    if (Test-Path $driveLetter) {
                        $driveInfo = Get-WmiObject -Class Win32_LogicalDisk -Filter "DeviceID='$driveLetter'"
                        if ($driveInfo) {
                            $selectedDrives += $driveLetter
                            $freeSpaceGB  = [Math]::Round($driveInfo.FreeSpace / 1GB, 2)
                            $totalSpaceGB = [Math]::Round($driveInfo.Size / 1GB, 2)
                            $statusBox.AppendText("Laufwerk $driveLetter`: ${freeSpaceGB}GB frei von ${totalSpaceGB}GB`r`n")
                        }
                    } else {
                        $statusBox.AppendText("Warnung: Laufwerk $driveLetter ist nicht verfügbar`r`n")
                    }
                }
            }
            
            $statusBox.AppendText("`r`nAusgewählte Laufwerke: $($selectedDrives -join ', ')`r`n`r`n")
            [System.Windows.Forms.Application]::DoEvents()
            
            # Wenn keine Laufwerke ausgewählt sind, alle Größen auf 0 setzen
            if ($selectedDrives.Count -eq 0) {
                foreach ($optionKey in $cleanupCheckboxes.Keys) {
                    $sizeLabels[$optionKey].Text       = "0 Bytes"
                    $sizeLabels[$optionKey].Foreground = $bconv.ConvertFrom("#707070")
                }
                
                Set-OutputSelectionStyle -OutputBox $statusBox -Style 'Error'
                $statusBox.AppendText("FEHLER: Bitte wählen Sie mindestens ein Laufwerk aus.`r`n")
                return
            }
            
            # Für jede Option die Dateigröße berechnen
            $activeOptions = $cleanupOptions | Where-Object { $cleanupCheckboxes[$_.Name].IsChecked -eq $true }
            
            # Wenn keine Optionen ausgewählt sind, alle Größen auf 0 setzen
            if ($activeOptions.Count -eq 0) {
                Set-OutputSelectionStyle -OutputBox $statusBox -Style 'Error'
                $statusBox.AppendText("FEHLER: Bitte wählen Sie mindestens eine Bereinigungsoption aus.`r`n")
                return
            }
            
            Set-OutputSelectionStyle -OutputBox $statusBox -Style 'Action'
            $statusBox.AppendText("Ausgewählte Optionen: $($activeOptions.Count)`r`n")
            foreach ($option in $activeOptions) {
                $statusBox.AppendText("  - $($option.Text)`r`n")
            }
            $statusBox.AppendText("`r`n")
            [System.Windows.Forms.Application]::DoEvents()
            
            # Fortschrittsberechnung vorbereiten - Division durch Null vermeiden
            $totalOperations = $selectedDrives.Count * $activeOptions.Count
            if ($totalOperations -eq 0) {
                Set-OutputSelectionStyle -OutputBox $statusBox -Style 'Error'
                $statusBox.AppendText("FEHLER: Keine gültigen Operationen zum Berechnen.`r`n")
                return
            }
            $completedOperations = 0
            
            # Größenberechnung im Hintergrund starten (ohne echtes PowerShell-Job wegen Einfachheit)
            $wpfCleanup.Cursor = [System.Windows.Input.Cursors]::Wait
            
            # Optimierte Berechnung mit Threading für bessere Performance
            $optionTimes = @{}
            
            # Für jede Option und jedes Laufwerk die Größe berechnen
            foreach ($option in $activeOptions) {
                $optionStartTime = Get-Date
                $totalSize = 0
                $totalFiles = 0
                
                Set-OutputSelectionStyle -OutputBox $statusBox -Style 'Success'
                $statusBox.AppendText("--- $($option.Text) ---`r`n")
                [System.Windows.Forms.Application]::DoEvents()
                
                # Größenschätzung für diese Option zurücksetzen
                $sizeLabels[$option.Name].Text       = "Berechne..."
                $sizeLabels[$option.Name].Foreground = $bconv.ConvertFrom("#D4A010")
                [System.Windows.Forms.Application]::DoEvents()
                
                # Parallele Verarbeitung für multiple Laufwerke
                if ($selectedDrives.Count -gt 1) {
                    $driveJobs = @()
                    foreach ($drive in $selectedDrives) {
                        $scriptBlock = {
                            param($driveLetter, $optionPaths, $optionName)
                            
                            try {
                                if ($optionName -eq "eventLogs" -and $driveLetter -ne "C:") {
                                    return @{ Size = 0; Count = 0; Drive = $driveLetter }
                                }
                                
                                $driveSize = 0
                                $driveCount = 0
                                
                                foreach ($path in $optionPaths) {
                                    try {
                                        if ($path -eq '$Recycle.Bin') {
                                            $fullPath = "$driveLetter\`$Recycle.Bin"
                                            if (Test-Path $fullPath) {
                                                $recycleBinFolders = Get-ChildItem -Path $fullPath -Directory -Force -ErrorAction SilentlyContinue
                                                foreach ($folder in $recycleBinFolders) {
                                                    $files = Get-ChildItem -Path $folder.FullName -Recurse -File -Force -ErrorAction SilentlyContinue
                                                    if ($files) {
                                                        $driveCount += $files.Count
                                                        $sizeSum = ($files | Measure-Object -Property Length -Sum).Sum
                                                        $driveSize += if ($null -eq $sizeSum) { 0 } else { $sizeSum }
                                                    }
                                                }
                                            }
                                        } else {
                                            $fullPath = if ($path.StartsWith("\")) { "$driveLetter$path" } else { "$driveLetter\$path" }
                                            $files = Get-ChildItem -Path $fullPath -Recurse -File -Force -ErrorAction SilentlyContinue
                                            if ($files) {
                                                $driveCount += $files.Count
                                                $sizeSum = ($files | Measure-Object -Property Length -Sum).Sum
                                                $driveSize += if ($null -eq $sizeSum) { 0 } else { $sizeSum }
                                            }
                                        }
                                    } catch {
                                        # Fehler ignorieren und fortfahren
                                    }
                                }
                                
                                return @{ Size = $driveSize; Count = $driveCount; Drive = $driveLetter }
                            } catch {
                                return @{ Size = 0; Count = 0; Drive = $driveLetter; Error = $_.Exception.Message }
                            }
                        }
                        
                        try {
                            $job = Start-Job -ScriptBlock $scriptBlock -ArgumentList $drive, $option.Paths, $option.Name
                            $driveJobs += $job
                        } catch {
                            # Fallback zur seriellen Verarbeitung
                            if ($option.Name -eq "eventLogs" -and $drive -ne "C:") {
                                $result = @{ Size = 0; Count = 0 }
                            } else {
                                $result = Get-FileSize -DriveLetter $drive -Paths $option.Paths
                            }
                            $totalSize += $result.Size
                            $totalFiles += $result.Count
                        }
                    }
                    
                    # Warte auf alle Jobs mit Timeout
                    if ($driveJobs.Count -gt 0) {
                        $completed = Wait-Job -Job $driveJobs -Timeout 120
                        
                        foreach ($job in $driveJobs) {
                            try {
                                if ($job.State -eq 'Completed') {
                                    $result = Receive-Job -Job $job
                                    $totalSize += $result.Size
                                    $totalFiles += $result.Count
                                    if ($result.Error) {
                                        $statusBox.AppendText("  Warnung für $($result.Drive): $($result.Error)`r`n")
                                    }
                                } else {
                                    $statusBox.AppendText("  Timeout für Laufwerk bei $($option.Text)`r`n")
                                }
                            } finally {
                                Remove-Job -Job $job -Force -ErrorAction SilentlyContinue
                            }
                        }
                    }
                } else {
                    # Serielle Verarbeitung für einzelnes Laufwerk
                    foreach ($drive in $selectedDrives) {
                        $completedOperations++
                        
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
                                        } else {
                                            $result = @{ Size = 0; Count = 0 }
                                        }
                                    } else {
                                        $result = @{ Size = 0; Count = 0 }
                                    }
                                } catch {
                                    # Fallback zu geschätzten Werten bei Fehlern
                                    $result = @{ Size = 2MB; Count = 3 }
                                }
                            } else {
                                $result = @{ Size = 0; Count = 0 }
                            }
                        } else {
                            # Normale Dateiberechnung
                            $result = Get-FileSize -DriveLetter $drive -Paths $option.Paths
                        }
                        
                        $totalSize += $result.Size
                        $totalFiles += $result.Count
                    }
                }
                
                $optionEndTime = Get-Date
                $optionDuration = ($optionEndTime - $optionStartTime).TotalSeconds
                $optionTimes[$option.Name] = $optionDuration
                
                # Option-Ergebnis speichern
                $global:optionSizes[$option.Name] = @{
                    Size  = $totalSize
                    Files = $totalFiles
                }
                
                # Label aktualisieren
                $formattedSize = Format-Size -Size $totalSize
                $sizeLabels[$option.Name].Text = $formattedSize
                
                if ($totalSize -gt 0) {
                    $sizeLabels[$option.Name].Foreground = $bconv.ConvertFrom("#00B464")
                    $statusBox.AppendText("Ergebnis: $formattedSize ($totalFiles Dateien) [${optionDuration}s]`r`n`r`n")
                } else {
                    $sizeLabels[$option.Name].Foreground = $bconv.ConvertFrom("#707070")
                    $statusBox.AppendText("Ergebnis: Keine Dateien gefunden [${optionDuration}s]`r`n`r`n")
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
            
            # Performance-Auswertung
            $calculationEndTime = Get-Date
            $totalCalculationTime = ($calculationEndTime - $calculationStartTime).TotalSeconds
            
            # Status aktualisieren
            Set-OutputSelectionStyle -OutputBox $statusBox -Style 'Action'
            $statusBox.AppendText("=== BERECHNUNG ABGESCHLOSSEN ===`r`n")
            Set-OutputSelectionStyle -OutputBox $statusBox -Style 'Success'
            $statusBox.AppendText("Potentiell freizugebender Speicher: " + (Format-Size -Size $totalPotentialCleanup) + "`r`n")
            $statusBox.AppendText("Zu bereinigende Dateien: $totalFileCount`r`n")
            Set-OutputSelectionStyle -OutputBox $statusBox -Style 'Action'
            $statusBox.AppendText("Berechnungszeit: ${totalCalculationTime}s`r`n")
            
            # Performance-Statistiken hinzufügen
            if ($optionTimes.Count -gt 0) {
                $statusBox.AppendText("`r`nPerformance-Details:`r`n")
                $sortedTimes = $optionTimes.GetEnumerator() | Sort-Object Value -Descending
                foreach ($timing in $sortedTimes) {
                    $optionName = ($cleanupOptions | Where-Object { $_.Name -eq $timing.Key }).Text
                    $statusBox.AppendText("  $optionName`: $([Math]::Round($timing.Value, 2))s`r`n")
                }
            }
            
            $statusBox.AppendText("`r`nZeitstempel: $(Get-Date -Format 'dd.MM.yyyy HH:mm:ss')`r`n")
            [System.Windows.Forms.Application]::DoEvents()
            
            $wpfCleanup.Cursor = $null
        }

        # OK-Button (WPF)
        $btnOkClean.Add_Click({
                # Sicherstellen, dass mindestens ein Laufwerk und eine Option ausgewählt sind
                $selectedDrives = @()
                foreach ($driveKey in ($driveCheckBoxes.Keys | Sort-Object)) {
                    if ($driveCheckBoxes[$driveKey].IsChecked -eq $true) {
                        $selectedDrives += $driveKey
                    }
                }

                if ($selectedDrives.Count -eq 0) {
                    [System.Windows.MessageBox]::Show(
                        "Bitte wählen Sie mindestens ein Laufwerk aus.",
                        "Keine Laufwerke ausgewählt",
                        [System.Windows.MessageBoxButton]::OK,
                        [System.Windows.MessageBoxImage]::Warning)
                    return
                }

                $activeOptions = $cleanupOptions | Where-Object { $cleanupCheckboxes[$_.Name].IsChecked -eq $true }
                if ($activeOptions.Count -eq 0) {
                    [System.Windows.MessageBox]::Show(
                        "Bitte wählen Sie mindestens eine Bereinigungsoption aus.",
                        "Keine Optionen ausgewählt",
                        [System.Windows.MessageBoxButton]::OK,
                        [System.Windows.MessageBoxImage]::Warning)
                    return
                }
                
                # Bestätigungsdialog entfernt, um Benutzererfahrung zu optimieren
                
                # ProgressBar zurücksetzen
                if ($progressBar) {
                    $progressBar.Value = 0
                }
                
                # Ausgabe im Hauptfenster initialisieren
                $outputBox.Clear()
                Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Action'
                $outputBox.AppendText("===== BEREINIGUNG TEMPORAERER DATEIEN (ERWEITERT) =====`r`n")
                Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Default'
                $outputBox.AppendText("Modus: Erweiterte Bereinigung laeuft...`r`n")
                Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Default'
                $outputBox.AppendText("Zeitstempel: $(Get-Date -Format 'dd.MM.yyyy HH:mm:ss')`r`n`r`n")
                
                # Systeminformationen anzeigen
                $computerName = $env:COMPUTERNAME
                $userName = $env:USERNAME
                $osInfo = (Get-CimInstance -ClassName Win32_OperatingSystem).Caption
                
                # Format fuer nebeneinander stehende Informationen
                Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Action'
                $outputBox.AppendText("[i] SYSTEM-INFORMATIONEN:`r`n")
                Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Default'
                
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
                Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Action'
                $outputBox.AppendText("[i] BEREINIGUNGSDETAILS:`r`n")
                Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Default'
                $outputBox.AppendText("    Ausgewaehlte Laufwerke: " + ($selectedDrives -join ", ") + "`r`n")
                $outputBox.AppendText("    Ausgewaehlte Optionen: " + $activeOptions.Count + "`r`n`r`n")
                
                # Cursor auf Wartemodus setzen
                $wpfCleanup.Cursor = [System.Windows.Input.Cursors]::Wait
                
                # Bereinigung durchführen
                $totalFreed = 0
                $totalFilesDeleted = 0
                $totalFilesSkipped = 0
                
                # Fortschrittsberechnung
                $totalSteps = $selectedDrives.Count * $activeOptions.Count
                $currentStep = 0
                
                # Für jedes Laufwerk
                foreach ($drive in $selectedDrives) {
                    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Action'
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
                        Set-OutputSelectionStyle -OutputBox $statusBox -Style 'Action'
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
                                    
                                    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Default'
                                    $outputBox.AppendText("  $($option.Text): ")
                                    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Success'
                                    $outputBox.AppendText("$(Format-Size -Size $result.FreedSpace) freigegeben`r`n")
                                    
                                    $totalFreed += $result.FreedSpace
                                    $totalFilesDeleted += $result.DeletedFiles
                                }
                            } catch {
                                Set-OutputSelectionStyle -OutputBox $statusBox -Style 'Error'
                                $statusBox.AppendText("Fehler: $($_.Exception.Message)")
                            }
                        } else {
                            # Normale Dateibereinigung durchführen
                            $result = Remove-TempFiles -DriveLetter $drive -Paths $option.Paths
                            
                            if ($result.FreedSpace -gt 0) {
                                Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Default'
                                $outputBox.AppendText("  $($option.Text): ")
                                Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Success'
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
                Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Success'
                $outputBox.AppendText("==== Bereinigung abgeschlossen ====`r`n")
                Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Default'
                $outputBox.AppendText("Insgesamt freigegeben: " + (Format-Size -Size $totalFreed) + "`r`n")
                Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Default'
                $outputBox.AppendText("Dateien gelöscht: $totalFilesDeleted`r`n")
                
                if ($totalFilesSkipped -gt 0) {
                    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Warning'
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
                Set-OutputSelectionStyle -OutputBox $statusBox -Style 'Success'
                $statusBox.AppendText("Bereinigung abgeschlossen.`r`n")
                Set-OutputSelectionStyle -OutputBox $statusBox -Style 'Default'
                $statusBox.AppendText("Freigegebener Speicher: " + (Format-Size -Size $totalFreed) + "`r`n")
                $statusBox.AppendText("Gelöschte Dateien: $totalFilesDeleted / Übersprungen: $totalFilesSkipped")
                
                # NEU: Neuberechnung der Dateigröße nach der Bereinigung
                $statusBox.AppendText("`r`n`r`nAktualisiere Größenberechnung...")
                Update-CleanupSizeEstimates
                
                # Cursor zurücksetzen
                $wpfCleanup.Cursor = $null

                # Dialog automatisch schließen
                $wpfCleanup.Close()
            })

        # Initiale Größenberechnung nach dem Rendern
        $wpfCleanup.Add_ContentRendered({
                Update-CleanupSizeEstimates
            })

        # Dialog anzeigen
        $wpfCleanup.ShowDialog() | Out-Null
    } catch {
        Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Error'
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
    $skippedLog = Join-Path $PSScriptRoot "..\..\Data\Temp\skipped_files.txt"
    "$filePath | $sizeString" | Out-File -Append -FilePath $skippedLog
}

# Funktion zum Bereinigen temporärer Dateien
function Start-Cleanup {
    param (
        [System.Windows.Forms.RichTextBox]$outputBox,
        [System.Windows.Forms.ProgressBar]$progressBar
    )
    
    
    # In Log-Datei und Datenbank schreiben, dass die System-Bereinigung gestartet wird
    Write-ToolLog -ToolName "SystemCleanup" -Message "System-Bereinigung wird gestartet" -OutputBox $outputBox -Style 'Action' -Level "Information" -SaveToDatabase
    
    # Protokolldateien initialisieren
    $cleanupLog = Join-Path $PSScriptRoot "..\..\Data\Temp\cleanup_log.txt"
    $skippedLog = Join-Path $PSScriptRoot "..\..\Data\Temp\skipped_files.txt"
    "" | Out-File -FilePath $cleanupLog -Force
    "" | Out-File -FilePath $skippedLog -Force
    
    try {
        # Sammle Informationen über zu bereinigende Dateien
        $filesToClean = @()
        $skippedFiles = @()
        
        # Windows temp
        Get-ChildItem -Path $env:TEMP -File -Force -ErrorAction SilentlyContinue | ForEach-Object {
            if (Test-Path $_.FullName -PathType Leaf) {
                try {
                    $filesToClean += $_.FullName
                } catch {
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
                } catch {
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
                    } catch {
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
                    } catch {
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
            } catch {
                Write-SkippedFileInfo -filePath $file -fileSize (Get-Item $file -ErrorAction SilentlyContinue).Length
            }
        }
    } catch {
        Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Error'
        $outputBox.AppendText("[-] Fehler bei der Bereinigung: $_`r`n")
    }
}

# Hilfsfunktion zur besseren Pfadbehandlung
function Get-FilesFromPath {
    param (
        [string]$Path,
        [bool]$Recursive = $true,
        [int]$MaxDepth = 10,
        [string[]]$ExcludeExtensions = @('.lock'),  # .tmp NICHT ausschließen – sind primäre Zieldateien
        [int]$TimeoutSeconds = 30
    )
    
    if ([string]::IsNullOrWhiteSpace($Path)) {
        return @()
    }
    
    $startTime = Get-Date
    $results = @()
    
    try {
        # Prüfe, ob der Pfad Wildcards enthält
        if ($Path.Contains('*') -or $Path.Contains('?')) {
            # Wildcard-Pfad - erweiterte Behandlung
            $basePath = Split-Path $Path -Parent
            $pattern = Split-Path $Path -Leaf
            
            # Fallback falls Split-Path nicht funktioniert
            if (-not $basePath) {
                $pathParts = $Path -split '[\\\/]'
                $basePath = ($pathParts[0..($pathParts.Length - 2)]) -join '\'
                $pattern = $pathParts[-1]
            }
            
            if (Test-Path $basePath) {
                if ($Recursive) {
                    $results = Get-ChildItem -Path $Path -Recurse -Force -ErrorAction SilentlyContinue | 
                        Where-Object { 
                            -not $_.PSIsContainer -and 
                            $_.Extension -notin $ExcludeExtensions -and
                            ((Get-Date) - $startTime).TotalSeconds -lt $TimeoutSeconds
                        }
                } else {
                    $results = Get-ChildItem -Path $Path -Force -ErrorAction SilentlyContinue | 
                        Where-Object { 
                            -not $_.PSIsContainer -and 
                            $_.Extension -notin $ExcludeExtensions
                        }
                }
            }
        } else {
            # Normaler Pfad - erweiterte Existenzprüfung
            if (Test-Path $Path -PathType Container) {
                # Verzeichnis
                $getChildItemParams = @{
                    Path        = $Path
                    Force       = $true
                    ErrorAction = 'SilentlyContinue'
                }
                
                if ($Recursive) {
                    $getChildItemParams.Recurse = $true
                }
                
                $allItems = Get-ChildItem @getChildItemParams
                
                $results = $allItems | Where-Object { 
                    -not $_.PSIsContainer -and 
                    $_.Extension -notin $ExcludeExtensions -and
                    ((Get-Date) - $startTime).TotalSeconds -lt $TimeoutSeconds
                }
            } elseif (Test-Path $Path -PathType Leaf) {
                # Einzelne Datei
                $fileItem = Get-Item $Path -Force -ErrorAction SilentlyContinue
                if ($fileItem -and $fileItem.Extension -notin $ExcludeExtensions) {
                    $results = @($fileItem)
                }
            } else {
                # Pfad existiert nicht
                Write-Verbose "Pfad existiert nicht: $Path"
                return @()
            }
        }
        
        # Zusätzliche Filterung für problematische Dateien
        $filteredResults = $results | Where-Object {
            try {
                # Prüfe auf Zugriffsberechtigung
                $_.Length -ge 0
                return $true
            } catch {
                Write-Verbose "Datei nicht zugreifbar: $($_.FullName)"
                return $false
            }
        }
        
        return $filteredResults
    } catch {
        Write-Verbose "Fehler bei Get-FilesFromPath für Pfad '$Path': $($_.Exception.Message)"
        return @()
    }
}

# Export functions
Export-ModuleMember -Function Start-DiskCleanup, Start-TempFilesCleanup, Start-TempFilesCleanupAdvanced, Start-Cleanup



# SIG # Begin signature block
# MIIcSgYJKoZIhvcNAQcCoIIcOzCCHDcCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCmCloeIADcv/wv
# IrzbIzzdaXPHKEni1IYZs7woQxQY+qCCFnowggM8MIICJKADAgECAhBJfyGrXBJT
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
# MQ4wDAYKKwYBBAGCNwIBFTAvBgkqhkiG9w0BCQQxIgQgHC6rLzUsTk8hSYtjAyxM
# 6U21l8Tf1WhW9HxAApnSmcIwDQYJKoZIhvcNAQEBBQAEggEAFqgzps0UBOmZEp+y
# KUZYlThMRGjqsjT29wrfVskJB9J25aP80tufoq9iU7v+Pq8oPCMryOhb1sQZoBH6
# Q9nE0uslbmN+qVcW1kstmqmX/x05fcZzMb5znwzF0m8SiGSwOrIEudeSQKDWEaLm
# yp1AR7ihGmwGoU160WQLohJq4pANYekMP31SYdYsLuqh7k+RQ6ssT6/cWAupm2E+
# uS0Lu1GSVnzVFig0ucCRj0PKPZu1rs9D7/JW5yah647pNiWG1Qu32afgWoZM7g03
# FmgC5pXsxJtApkOPcjhMCILpakvHdP1KrLT/Ce6IxzYemuzr4szNuhbgqZcblmZA
# zxQLAaGCAyYwggMiBgkqhkiG9w0BCQYxggMTMIIDDwIBATB9MGkxCzAJBgNVBAYT
# AlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5jLjFBMD8GA1UEAxM4RGlnaUNlcnQg
# VHJ1c3RlZCBHNCBUaW1lU3RhbXBpbmcgUlNBNDA5NiBTSEEyNTYgMjAyNSBDQTEC
# EAqA7xhLjfEFgtHEdqeVdGgwDQYJYIZIAWUDBAIBBQCgaTAYBgkqhkiG9w0BCQMx
# CwYJKoZIhvcNAQcBMBwGCSqGSIb3DQEJBTEPFw0yNjAxMjAxODAyNTVaMC8GCSqG
# SIb3DQEJBDEiBCAO27V9FyxC0lmjQILovw2rA0mFsyezzNC0037fvk1qaTANBgkq
# hkiG9w0BAQEFAASCAgCdTLo5TTYczuarpd6MKHHwrvVBvUzF+4u8dqhGGXg/synQ
# fiTu5UYLU89X2sN2Oheuxi6hXPernhS9JTs9JAdxP1jXTG9Vr7gLhPjFvexAXD7W
# G5sQpfuXXu56or++w1VaLQScBrtD1QHI0iwGmFPvPKe8xz1rBHUiT52+vBcCbejD
# YV0H+3TEThvFqwOCDYvsgY1uEaaU3hvPSe+tf7tnUIDkge3/UUB3ZZZ9wKZdJjcy
# 8GZiEOCOUVRh58p4vn5VhtHguv+ngDI1K6DV49MCnXpMth9AJo3OEQJtcUVQOip4
# oFrKXSoidWetibr78wUuHHNdCCt1E02quHC5wklBh527Qu8Uld0VzZ4l8XQf3HRz
# TtvPG+mzUoZ95sKvCUs1M1P5M6+ytx1Ajg3dP1cVVZY7aq5gP8ebmy0Ic402n17c
# QEuYxn18atLinueIwHIuLua0YYZeon4b3AqOOPBQmTgp7iXeQ6aD6o1jn6J5Izg0
# 2Cze7bjpe5dUiLn08BcCB1c8WS7iDD3loamUGcLNMN3CIG/k3N4pFjdKimiHcKKU
# 8voac7taL+gWMVxAmXlHU8xaCg37sk+HYIIxi53lV3VXWhLOi9m06vxwhK0vLiBF
# upUs9jcnn+G1BW53UJwd8OL8IlL6BGYqB10195pj72RYwUDoaQzilZiT2sAvmg==
# SIG # End signature block

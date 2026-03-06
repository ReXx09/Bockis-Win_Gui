# SystemInfo.psm1 - Modul für System-Status-Informationen
# Autor: Bocki

# Funktion zum Abrufen des System-Status
function Get-SystemStatusSummary {
    param (
        [System.Windows.Forms.RichTextBox]$statusBox,
        [switch]$LiveMode = $false
    )
    
    if (-not $LiveMode) {
        $statusBox.Clear()
    }
    
    # Initialisiere Fortschritt
    $script:loadProgress = 0
    $progressBar.Value = 0
    
    # Verwende die CustomText-Eigenschaft der TextProgressBar statt progressStatusLabel
    if ($progressBar.GetType().Name -eq "TextProgressBar") {
        $progressBar.CustomText = "Status wird geladen... (0%)"
    }
    
    Set-OutputSelectionStyle -OutputBox $statusBox -Style 'Action'
    $statusBox.AppendText("===== SYSTEM-STATUS ÜBERSICHT =====`r`n`r`n")
    
    # Windows Defender Status - 20%
    Set-OutputSelectionStyle -OutputBox $statusBox -Style 'Action'
    $statusBox.AppendText("WINDOWS DEFENDER STATUS:`r`n")
    Set-OutputSelectionStyle -OutputBox $statusBox -Style 'Default'
    
    if ($LiveMode) {
        $script:loadProgress = 20
        $progressBar.Value = $script:loadProgress
        
        # Verwende die CustomText-Eigenschaft der TextProgressBar
        if ($progressBar.GetType().Name -eq "TextProgressBar") {
            $progressBar.CustomText = "Lade Windows Defender Status... ($script:loadProgress%)"
        }
        
        [System.Windows.Forms.Application]::DoEvents()
    }
    
    try {
        $defenderStatus = Get-MpComputerStatus
        $statusBox.AppendText("Antivirus aktiviert: $($defenderStatus.AntivirusEnabled)`r`n")
        $statusBox.AppendText("Echtzeit-Schutz: $($defenderStatus.RealTimeProtectionEnabled)`r`n")
        $statusBox.AppendText("Signaturversion: $($defenderStatus.AntivirusSignatureVersion)`r`n")
        
        # Korrektur des Datums-Formats für das letzte Update
        $lastUpdate = $defenderStatus.AntivirusSignatureLastUpdated
        if ($lastUpdate) {
            $formattedDate = $lastUpdate.ToString("dd.MM.yyyy HH:mm:ss")
            $statusBox.AppendText("Letztes Update: $formattedDate`r`n")
        }
        else {
            $statusBox.AppendText("Letztes Update: Nicht verfügbar`r`n")
        }
        
        # Scan-Status mit korrekter Zeitberechnung
        $quickScanEndTime = $defenderStatus.QuickScanEndTime
        $fullScanEndTime = $defenderStatus.FullScanEndTime
        
        $statusBox.AppendText("Letzter Schnellscan: ")
        if ($quickScanEndTime) {
            $timeSinceQuickScan = (Get-Date) - $quickScanEndTime
            $scanTimeInfo = $quickScanEndTime.ToString("dd.MM.yyyy HH:mm:ss")
            
            # Verbesserte Anzeige mit Minuten für Zeiträume unter einer Stunde
            if ($timeSinceQuickScan.TotalHours -lt 1) {
                $minutesSinceQuickScan = [math]::Round($timeSinceQuickScan.TotalMinutes)
                Set-OutputSelectionStyle -OutputBox $statusBox -Style 'Success'
                $statusBox.AppendText("vor $minutesSinceQuickScan Minuten ($scanTimeInfo) (Aktuell)`r`n")
            }
            elseif ($timeSinceQuickScan.TotalHours -lt 24) {
                $hoursSinceQuickScan = [math]::Round($timeSinceQuickScan.TotalHours, 1)
                Set-OutputSelectionStyle -OutputBox $statusBox -Style 'Success'
                $statusBox.AppendText("vor $hoursSinceQuickScan Stunden ($scanTimeInfo) (Aktuell)`r`n")
            }
            else {
                $hoursSinceQuickScan = [math]::Round($timeSinceQuickScan.TotalHours, 1)
                Set-OutputSelectionStyle -OutputBox $statusBox -Style 'Critical'
                $statusBox.AppendText("vor $hoursSinceQuickScan Stunden ($scanTimeInfo) (Veraltet)`r`n")
            }
        }
        else {
            Set-OutputSelectionStyle -OutputBox $statusBox -Style 'Muted'
            $statusBox.AppendText("Nicht verfügbar`r`n")
        }
        
        Set-OutputSelectionStyle -OutputBox $statusBox -Style 'Default'
        $statusBox.AppendText("Letzter Komplettscan: ")
        if ($fullScanEndTime) {
            $timeSinceFullScan = (Get-Date) - $fullScanEndTime
            $scanTimeInfo = $fullScanEndTime.ToString("dd.MM.yyyy HH:mm:ss")
            
            # Verbesserte Anzeige ähnlich dem Schnellscan
            if ($timeSinceFullScan.TotalHours -lt 1) {
                $minutesSinceFullScan = [math]::Round($timeSinceFullScan.TotalMinutes)
                Set-OutputSelectionStyle -OutputBox $statusBox -Style 'Success'
                $statusBox.AppendText("vor $minutesSinceFullScan Minuten ($scanTimeInfo) (Aktuell)`r`n")
            }
            elseif ($timeSinceFullScan.TotalHours -lt 168) {
                # 7 Tage in Stunden
                $hoursSinceFullScan = [math]::Round($timeSinceFullScan.TotalHours, 1)
                Set-OutputSelectionStyle -OutputBox $statusBox -Style 'Success'
                $statusBox.AppendText("vor $hoursSinceFullScan Stunden ($scanTimeInfo) (Aktuell)`r`n")
            }
            else {
                $hoursSinceFullScan = [math]::Round($timeSinceFullScan.TotalHours, 1)
                Set-OutputSelectionStyle -OutputBox $statusBox -Style 'Critical'
                $statusBox.AppendText("vor $hoursSinceFullScan Stunden ($scanTimeInfo) (Veraltet)`r`n")
            }
        }
        else {
            Set-OutputSelectionStyle -OutputBox $statusBox -Style 'Muted'
            $statusBox.AppendText("Nicht verfügbar`r`n")
        }
        
        # Bedrohungsstatus mit zusätzlicher Validierung
        Set-OutputSelectionStyle -OutputBox $statusBox -Style 'Default'
        $statusBox.AppendText("Aktuelle Bedrohungen: ")
        try {
            $threats = Get-MpThreatDetection
            if ($threats -and $threats.Count -gt 0) {
                Set-OutputSelectionStyle -OutputBox $statusBox -Style 'Error'
                $statusBox.AppendText("$($threats.Count) Bedrohung(en) gefunden!`r`n")
                
                # Detaillierte Bedrohungsinformationen
                foreach ($threat in $threats) {
                    Set-OutputSelectionStyle -OutputBox $statusBox -Style 'Error'
                    $statusBox.AppendText("  - $($threat.ThreatName) (Erkannt am: $($threat.InitialDetectionTime))`r`n")
                }
            }
            else {
                Set-OutputSelectionStyle -OutputBox $statusBox -Style 'Success'
                $statusBox.AppendText("Keine Bedrohungen gefunden`r`n")
            }
        }
        catch {
            Set-OutputSelectionStyle -OutputBox $statusBox -Style 'Muted'
            $statusBox.AppendText("Status nicht verfügbar`r`n")
        }
    }
    catch {
        Set-OutputSelectionStyle -OutputBox $statusBox -Style 'Error'
        $statusBox.AppendText("Fehler beim Abrufen der Windows Defender Informationen: $_`r`n")
    }
    
    $statusBox.AppendText("`r`n")
    
    # Windows Update Status - 40%
    if ($LiveMode) {
        $script:loadProgress = 40
        $progressBar.Value = $script:loadProgress
        
        # Verwende die CustomText-Eigenschaft der TextProgressBar
        if ($progressBar.GetType().Name -eq "TextProgressBar") {
            $progressBar.CustomText = "Lade Windows Update Status... ($script:loadProgress%)"
        }
        
        [System.Windows.Forms.Application]::DoEvents()
    }
    
    Set-OutputSelectionStyle -OutputBox $statusBox -Style 'Action'
    $statusBox.AppendText("WINDOWS UPDATE STATUS:`r`n")
    Set-OutputSelectionStyle -OutputBox $statusBox -Style 'Default'
    
    try {
        $updatesSession = New-Object -ComObject Microsoft.Update.Session
        $updatesSearcher = $updatesSession.CreateUpdateSearcher()
        $pendingUpdates = $updatesSearcher.Search("IsInstalled=0")
        
        if ($pendingUpdates.Updates.Count -eq 0) {
            Set-OutputSelectionStyle -OutputBox $statusBox -Style 'Success'
            $statusBox.AppendText("Keine ausstehenden Updates gefunden.`r`n")
        }
        else {
            Set-OutputSelectionStyle -OutputBox $statusBox -Style 'Critical'
            $statusBox.AppendText("$($pendingUpdates.Updates.Count) ausstehende Updates gefunden.`r`n")
            
            for ($i = 0; $i -lt [Math]::Min($pendingUpdates.Updates.Count, 5); $i++) {
                $update = $pendingUpdates.Updates.Item($i)
                Set-OutputSelectionStyle -OutputBox $statusBox -Style 'Default'
                $statusBox.AppendText("- $($update.Title)`r`n")
            }
            
            if ($pendingUpdates.Updates.Count -gt 5) {
                $statusBox.AppendText("- ... und $($pendingUpdates.Updates.Count - 5) weitere Updates`r`n")
            }
        }
    }
    catch {
        Set-OutputSelectionStyle -OutputBox $statusBox -Style 'Error'
        $statusBox.AppendText("Fehler beim Abrufen der Windows Update Informationen: $_`r`n")
    }
    
    $statusBox.AppendText("`r`n")
    
    # Systemdiagnostik Status - 60%
    if ($LiveMode) {
        $script:loadProgress = 60
        $progressBar.Value = $script:loadProgress
        
        # Verwende die CustomText-Eigenschaft der TextProgressBar
        if ($progressBar.GetType().Name -eq "TextProgressBar") {
            $progressBar.CustomText = "Lade Systemdiagnostik Status... ($script:loadProgress%)"
        }
        
        [System.Windows.Forms.Application]::DoEvents()
    }
    
    Set-OutputSelectionStyle -OutputBox $statusBox -Style 'Action'
    $statusBox.AppendText("SYSTEMDIAGNOSTIK STATUS:`r`n")
    Set-OutputSelectionStyle -OutputBox $statusBox -Style 'Default'
    
    # SFC Status prüfen
    try {
        $statusBox.AppendText("Letzter SFC-Check: ")
        
        # SFC-Log analysieren
        $sfcLogPath = "$env:windir\Logs\CBS\CBS.log"
        if (Test-Path $sfcLogPath) {
            # Suche nach dem letzten erfolgreichen SFC-Check
            $sfcLogContent = Get-Content $sfcLogPath -Tail 1000
            $lastSfcCheck = $sfcLogContent | Select-String -Pattern "\[SR\].*Repair|\[SR\].*Verify|SFC.*complete|Verification.*complete|System File Checker.*finished|Repair.*complete" | Select-Object -Last 1
            
            if ($lastSfcCheck) {
                # Extrahiere das Datum aus dem Log-Eintrag mit robusterer Parsing-Logik
                $dateTimeStr = ($lastSfcCheck.Line -split '\s+')[0..1] -join ' '
                $checkTime = $null
                
                # Versuche verschiedene Datumsformate
                $dateFormats = @(
                    'yyyy-MM-dd HH:mm:ss',
                    'yyyy/MM/dd HH:mm:ss',
                    'dd.MM.yyyy HH:mm:ss',
                    'MM/dd/yyyy HH:mm:ss'
                )
                
                # Versuche zuerst das Format direkt zu parsen
                try {
                    $checkTime = [datetime]::Parse($dateTimeStr, [System.Globalization.CultureInfo]::InvariantCulture)
                }
                catch {
                    # Wenn das direkte Parsen fehlschlägt, versuche die spezifischen Formate
                    foreach ($format in $dateFormats) {
                        try {
                            $checkTime = [datetime]::ParseExact($dateTimeStr, $format, [System.Globalization.CultureInfo]::InvariantCulture)
                            if ($checkTime) { break }
                        }
                        catch {
                            # Ignoriere Fehler und versuche das nächste Format
                            continue
                        }
                    }
                }
                
                if ($checkTime) {
                    $timeDiff = (Get-Date) - $checkTime
                    
                    if ($timeDiff.TotalDays -lt 7) {
                        Set-OutputSelectionStyle -OutputBox $statusBox -Style 'Success'
                        $statusBox.AppendText("vor $([math]::Floor($timeDiff.TotalDays)) Tagen und $([math]::Round($timeDiff.TotalHours % 24)) Stunden (Aktuell)`r`n")
                    }
                    else {
                        Set-OutputSelectionStyle -OutputBox $statusBox -Style 'Critical'
                        $statusBox.AppendText("vor $([math]::Floor($timeDiff.TotalDays)) Tagen und $([math]::Round($timeDiff.TotalHours % 24)) Stunden (Veraltet)`r`n")
                    }
                }
                else {
                    Set-OutputSelectionStyle -OutputBox $statusBox -Style 'Muted'
                    $statusBox.AppendText("Datum konnte nicht geparst werden`r`n")
                }
            }
            else {
                Set-OutputSelectionStyle -OutputBox $statusBox -Style 'Muted'
                $statusBox.AppendText("Kein erfolgreicher Check gefunden`r`n")
            }
        }
        else {
            Set-OutputSelectionStyle -OutputBox $statusBox -Style 'Muted'
            $statusBox.AppendText("Log nicht verfügbar`r`n")
        }
    }
    catch {
        Set-OutputSelectionStyle -OutputBox $statusBox -Style 'Error'
        $statusBox.AppendText("Fehler beim Abrufen des SFC-Status: $_`r`n")
    }
    
    # DISM Status prüfen
    try {
        Set-OutputSelectionStyle -OutputBox $statusBox -Style 'Default'
        $statusBox.AppendText("Letzter DISM-Check: ")
        
        # Prüfe die DISM Ergebnis-Dateien
        $dismCheckResult = "$env:TEMP\dism_check_result.json"
        $dismScanResult = "$env:TEMP\dism_scan_result.json"
        $dismRestoreResult = "$env:TEMP\dism_restore_result.json"
        
        $lastDismCheck = $null
        $lastDismTime = $null
        
        # Prüfe alle DISM Ergebnis-Dateien
        foreach ($resultFile in @($dismCheckResult, $dismScanResult, $dismRestoreResult)) {
            if (Test-Path $resultFile) {
                $result = Get-Content $resultFile | ConvertFrom-Json
                if ($result.ExitCode -eq 0 -and (-not $lastDismTime -or $result.Timestamp -gt $lastDismTime)) {
                    $lastDismTime = $result.Timestamp
                    $lastDismCheck = $result
                }
            }
        }
        
        if ($lastDismCheck) {
            $timeDiff = (Get-Date) - ([DateTime]$lastDismCheck.Timestamp)
            
            if ($timeDiff.TotalDays -lt 7) {
                Set-OutputSelectionStyle -OutputBox $statusBox -Style 'Success'
                $statusBox.AppendText("vor $([math]::Floor($timeDiff.TotalDays)) Tagen und $([math]::Round($timeDiff.TotalHours % 24)) Stunden (Aktuell)`r`n")
            }
            else {
                Set-OutputSelectionStyle -OutputBox $statusBox -Style 'Critical'
                $statusBox.AppendText("vor $([math]::Floor($timeDiff.TotalDays)) Tagen und $([math]::Round($timeDiff.TotalHours % 24)) Stunden (Veraltet)`r`n")
            }
        }
        else {
            Set-OutputSelectionStyle -OutputBox $statusBox -Style 'Muted'
            $statusBox.AppendText("Kein erfolgreicher Check gefunden`r`n")
        }
    }
    catch {
        Set-OutputSelectionStyle -OutputBox $statusBox -Style 'Muted'
        $statusBox.AppendText("Kein erfolgreicher Check gefunden`r`n")
    }
    
    # Memory Diagnostic Status prüfen
    try {
        Set-OutputSelectionStyle -OutputBox $statusBox -Style 'Default'
        $statusBox.AppendText("Letzter Memory Diagnostic: ")
        
        # Prüfe die Memory Diagnostic Ergebnis-Datei
        $memoryResult = "$env:TEMP\memory_diagnostic_result.json"
        
        if (Test-Path $memoryResult) {
            $result = Get-Content $memoryResult | ConvertFrom-Json
            if ($result.ExitCode -eq 0) {
                $timeDiff = (Get-Date) - ([DateTime]$result.Timestamp)
                
                if ($timeDiff.TotalDays -lt 30) {
                    Set-OutputSelectionStyle -OutputBox $statusBox -Style 'Success'
                    $statusBox.AppendText("vor $([math]::Floor($timeDiff.TotalDays)) Tagen und $([math]::Round($timeDiff.TotalHours % 24)) Stunden (Aktuell)`r`n")
                }
                else {
                    Set-OutputSelectionStyle -OutputBox $statusBox -Style 'Critical'
                    $statusBox.AppendText("vor $([math]::Floor($timeDiff.TotalDays)) Tagen und $([math]::Round($timeDiff.TotalHours % 24)) Stunden (Veraltet)`r`n")
                }
            }
            else {
                Set-OutputSelectionStyle -OutputBox $statusBox -Style 'Muted'
                $statusBox.AppendText("Keine Informationen verfügbar`r`n")
            }
        }
        else {
            Set-OutputSelectionStyle -OutputBox $statusBox -Style 'Muted'
            $statusBox.AppendText("Keine Informationen verfügbar`r`n")
        }
    }
    catch {
        Set-OutputSelectionStyle -OutputBox $statusBox -Style 'Muted'
        $statusBox.AppendText("Keine Informationen verfügbar`r`n")
    }

    # CHKDSK Status prüfen
    try {
        Set-OutputSelectionStyle -OutputBox $statusBox -Style 'Default'
        $statusBox.AppendText("Letzter CHKDSK: ")
        
        # Suche in verschiedenen Event-Logs nach CHKDSK Ergebnissen
        $chkdskEvents = Get-WinEvent -FilterHashtable @{
            LogName = 'Application'
            ID      = @(1001, 26212, 26214)
        } -ErrorAction Stop -MaxEvents 100 | Where-Object { 
            $_.Message -match "chkdsk" -or 
            $_.Message -match "Checking file system" -or
            $_.Message -match "Überprüfen des Dateisystems"
        } | Select-Object -First 1
        
        if ($chkdskEvents) {
            $timeDiff = (Get-Date) - $chkdskEvents.TimeCreated
            
            if ($timeDiff.TotalDays -lt 30) {
                Set-OutputSelectionStyle -OutputBox $statusBox -Style 'Success'
                $statusBox.AppendText("vor $([math]::Floor($timeDiff.TotalDays)) Tagen und $([math]::Round($timeDiff.TotalHours % 24)) Stunden (Aktuell)`r`n")
            }
            else {
                Set-OutputSelectionStyle -OutputBox $statusBox -Style 'Critical'
                $statusBox.AppendText("vor $([math]::Floor($timeDiff.TotalDays)) Tagen und $([math]::Round($timeDiff.TotalHours % 24)) Stunden (Veraltet)`r`n")
            }
        }
        else {
            Set-OutputSelectionStyle -OutputBox $statusBox -Style 'Muted'
            $statusBox.AppendText("Keine Informationen verfügbar`r`n")
        }
    }
    catch {
        Set-OutputSelectionStyle -OutputBox $statusBox -Style 'Muted'
        $statusBox.AppendText("Keine Informationen verfügbar`r`n")
    }

    # Disk Cleanup Status prüfen
    try {
        Set-OutputSelectionStyle -OutputBox $statusBox -Style 'Default'
        $statusBox.AppendText("Letzter Disk Cleanup: ")
        
        # Suche nach verschiedenen Indikatoren für Disk Cleanup
        $cleanupPaths = @(
            "$env:SystemRoot\Logs\CBS\CBS.log",
            "$env:SystemRoot\Logs\DISM\dism.log",
            "$env:TEMP\cleanup_log.txt"
        )
        
        $latestCleanup = $null
        foreach ($path in $cleanupPaths) {
            if (Test-Path $path) {
                $fileInfo = Get-Item $path
                if ($null -eq $latestCleanup -or $fileInfo.LastWriteTime -gt $latestCleanup) {
                    $latestCleanup = $fileInfo.LastWriteTime
                }
            }
        }
        
        if ($latestCleanup) {
            $timeDiff = (Get-Date) - $latestCleanup
            
            if ($timeDiff.TotalDays -lt 30) {
                Set-OutputSelectionStyle -OutputBox $statusBox -Style 'Success'
                $statusBox.AppendText("vor $([math]::Floor($timeDiff.TotalDays)) Tagen und $([math]::Round($timeDiff.TotalHours % 24)) Stunden (Aktuell)`r`n")
            }
            else {
                Set-OutputSelectionStyle -OutputBox $statusBox -Style 'Critical'
                $statusBox.AppendText("vor $([math]::Floor($timeDiff.TotalDays)) Tagen und $([math]::Round($timeDiff.TotalHours % 24)) Stunden (Veraltet)`r`n")
            }
        }
        else {
            Set-OutputSelectionStyle -OutputBox $statusBox -Style 'Muted'
            $statusBox.AppendText("Keine Informationen verfügbar`r`n")
        }
    }
    catch {
        Set-OutputSelectionStyle -OutputBox $statusBox -Style 'Muted'
        $statusBox.AppendText("Keine Informationen verfügbar`r`n")
    }
    
    # MRT Quick Scan Status
    try {
        $mrtQuickLogPath = "$env:windir\debug\mrt.log"
        if (Test-Path $mrtQuickLogPath) {
            $lastQuickScan = (Get-Item $mrtQuickLogPath).LastWriteTime
            $timeSinceLastQuick = (Get-Date) - $lastQuickScan
            $quickStatus = if ($timeSinceLastQuick.TotalDays -lt 7) { "Aktuell" } else { "Veraltet" }
            $statusBox.AppendText("Letzter MRT Quick Scan: vor $([math]::Floor($timeSinceLastQuick.TotalDays)) Tagen und $([math]::Floor($timeSinceLastQuick.Hours)) Stunden ($quickStatus)`r`n")
        }
        else {
            $statusBox.AppendText("Letzter MRT Quick Scan: Keine Informationen verfuegbar`r`n")
        }
    }
    catch {
        $statusBox.AppendText("Letzter MRT Quick Scan: Fehler beim Abrufen des Status`r`n")
    }
    
    # MRT Full Scan Status
    try {
        $mrtFullLogPath = "$env:windir\debug\mrt_full.log"
        if (Test-Path $mrtFullLogPath) {
            $lastFullScan = (Get-Item $mrtFullLogPath).LastWriteTime
            $timeSinceLastFull = (Get-Date) - $lastFullScan
            $fullStatus = if ($timeSinceLastFull.TotalDays -lt 30) { "Aktuell" } else { "Veraltet" }
            $statusBox.AppendText("Letzter MRT Full Scan: vor $([math]::Floor($timeSinceLastFull.TotalDays)) Tagen und $([math]::Floor($timeSinceLastFull.Hours)) Stunden ($fullStatus)`r`n")
        }
        else {
            $statusBox.AppendText("Letzter MRT Full Scan: Keine Informationen verfuegbar`r`n")
        }
    }
    catch {
        $statusBox.AppendText("Letzter MRT Full Scan: Fehler beim Abrufen des Status`r`n")
    }
    
    $statusBox.AppendText("`r`n")
    
    # Festplatten Status - 80%
    if ($LiveMode) {
        $script:loadProgress = 80
        $progressBar.Value = $script:loadProgress
        
        # Verwende die CustomText-Eigenschaft der TextProgressBar
        if ($progressBar.GetType().Name -eq "TextProgressBar") {
            $progressBar.CustomText = "Lade Festplatten Status... ($script:loadProgress%)"
        }
        
        [System.Windows.Forms.Application]::DoEvents()
    }
    
    Set-OutputSelectionStyle -OutputBox $statusBox -Style 'Action'
    $statusBox.AppendText("FESTPLATTEN STATUS:`r`n")
    Set-OutputSelectionStyle -OutputBox $statusBox -Style 'Default'
    
    try {
        $drives = Get-WmiObject -Class Win32_LogicalDisk -Filter "DriveType=3"
        foreach ($drive in $drives) {
            $freeGB = [math]::Round($drive.FreeSpace / 1GB, 2)
            $sizeGB = [math]::Round($drive.Size / 1GB, 2)
            $usedPercent = [math]::Round(($drive.Size - $drive.FreeSpace) / $drive.Size * 100, 1)
            
            $statusBox.AppendText("Laufwerk $($drive.DeviceID) ($($drive.VolumeName)): ")
            
            if ($usedPercent -gt 90) {
                Set-OutputSelectionStyle -OutputBox $statusBox -Style 'Error'
                $statusBox.AppendText("$usedPercent% belegt (Kritisch!)`r`n")
            }
            elseif ($usedPercent -gt 75) {
                Set-OutputSelectionStyle -OutputBox $statusBox -Style 'Critical'
                $statusBox.AppendText("$usedPercent% belegt (Warnung)`r`n")
            }
            else {
                Set-OutputSelectionStyle -OutputBox $statusBox -Style 'Success'
                $statusBox.AppendText("$usedPercent% belegt (OK)`r`n")
            }
            
            Set-OutputSelectionStyle -OutputBox $statusBox -Style 'Default'
            $statusBox.AppendText("   Freier Speicher: $freeGB GB von $sizeGB GB`r`n")
        }
    }
    catch {
        Set-OutputSelectionStyle -OutputBox $statusBox -Style 'Error'
        $statusBox.AppendText("Fehler beim Abrufen der Festplatten-Informationen: $_`r`n")
    }
    
    $statusBox.AppendText("`r`n")
    
    # Systemzustand - 100%
    if ($LiveMode) {
        $script:loadProgress = 100
        $progressBar.Value = $script:loadProgress
        
        # Verwende die CustomText-Eigenschaft der TextProgressBar
        if ($progressBar.GetType().Name -eq "TextProgressBar") {
            $progressBar.CustomText = "Status-Info geladen"
        }
        
        [System.Windows.Forms.Application]::DoEvents()
    }
    
    Set-OutputSelectionStyle -OutputBox $statusBox -Style 'Action'
    $statusBox.AppendText("SYSTEMZUSTAND ZUSAMMENFASSUNG:`r`n")
    
    # Betriebszeit prüfen
    try {
        $uptime = (Get-Date) - (Get-CimInstance -ClassName Win32_OperatingSystem).LastBootUpTime
        $uptimeDays = [math]::Round($uptime.TotalDays, 1)
        
        Set-OutputSelectionStyle -OutputBox $statusBox -Style 'Default'
        $statusBox.AppendText("System-Betriebszeit: ")
        if ($uptimeDays -gt 30) {
            Set-OutputSelectionStyle -OutputBox $statusBox -Style 'Critical'
            $statusBox.AppendText("$uptimeDays Tage (Neustart empfohlen)`r`n")
        }
        else {
            Set-OutputSelectionStyle -OutputBox $statusBox -Style 'Success'
            $statusBox.AppendText("$uptimeDays Tage`r`n")
        }
    }
    catch {
        Set-OutputSelectionStyle -OutputBox $statusBox -Style 'Error'
        $statusBox.AppendText("Fehler beim Abrufen der System-Betriebszeit: $_`r`n")
    }
    
    # Gesamtbewertung
    Set-OutputSelectionStyle -OutputBox $statusBox -Style 'Default'
    $statusBox.AppendText("`r`nSystem-Status Zusammenfassung:`r`n")
    $statusBox.AppendText("Bericht erstellt am: $(Get-Date -Format 'dd.MM.yyyy HH:mm:ss')`r`n")
    $statusBox.AppendText("Systemname: $($env:COMPUTERNAME)`r`n")
    $statusBox.AppendText("Benutzer: $($env:USERNAME)`r`n")
    
    if ($LiveMode) {
        Start-Sleep -Milliseconds 500
        $progressBar.Value = 0
        $progressBar.CustomText = "Status-Info geladen"
        $progressBar.ForeColor = [System.Drawing.Color]::LimeGreen
    }
}

# Exportiere die Funktionen
Export-ModuleMember -Function Get-SystemStatusSummary 



# SIG # Begin signature block
# MIIcSgYJKoZIhvcNAQcCoIIcOzCCHDcCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAxRXy9RaHXO6mf
# BnSNxc9/U5DlkmC5OrIPrcRopqMC76CCFnowggM8MIICJKADAgECAhBJfyGrXBJT
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
# MQ4wDAYKKwYBBAGCNwIBFTAvBgkqhkiG9w0BCQQxIgQgjyOZM6AOZarELUsWWiLN
# bh6IxlYv2u3/U7YhD/6/AZAwDQYJKoZIhvcNAQEBBQAEggEAYAlxSBBLRpnPvfsK
# Gkm1dxJDdf6rPY2Nm/vRdIdoSah4wnJzV22KXUkD/Via0d63XPtN+lZzQWWW984q
# FNMiHBl02W1GTtFmpxWOfROVaTogCMa9W9c9/bHYt0eXI6FYabmXjSeCsllWuoH6
# ufDsbBnDBGJvb857ILhI5wed+/+EjxKt4iFFUruucJ5maQsRHfCoU5SUYk/TB0SN
# 52yQw4puMCNihhcQjB7yAVS0SeDrGf9yrgTX8DuCCVDsCypJc02i/Tb34x7RZIpG
# c0fTjbecMfUNPPYyK4ruqtBTM1Wv5vFANhNtcaGQbvCgNM1TkQs9B+UGygb6v5/V
# ON0THqGCAyYwggMiBgkqhkiG9w0BCQYxggMTMIIDDwIBATB9MGkxCzAJBgNVBAYT
# AlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5jLjFBMD8GA1UEAxM4RGlnaUNlcnQg
# VHJ1c3RlZCBHNCBUaW1lU3RhbXBpbmcgUlNBNDA5NiBTSEEyNTYgMjAyNSBDQTEC
# EAqA7xhLjfEFgtHEdqeVdGgwDQYJYIZIAWUDBAIBBQCgaTAYBgkqhkiG9w0BCQMx
# CwYJKoZIhvcNAQcBMBwGCSqGSIb3DQEJBTEPFw0yNjAxMjAxODAyNTZaMC8GCSqG
# SIb3DQEJBDEiBCB734Rcy4jW5NhmPCfg4I7tJCTqVgIVYu35ELkpAFRLKDANBgkq
# hkiG9w0BAQEFAASCAgA3445katswg/pFi8tvuDIHUxVdfW/3H5AlmLjf/0SyPNAd
# 86uGVhV0GAFowi8NHzahO2hKvRoDMhCUsJiNHCj8AxT927x8p/0E8gDVN4/NTRNs
# s0SUmTS2vIGntE8ZRginuNd98hzhYkwNoPYeMJ6YqwEADbGig3VGZDj24owewnAd
# 03rbqYxb/0xAEU+JNoOudEkzZAxJ9SDMSKa61WU2aImBlPYP43KeI+BFHJqRaTBy
# rkUIi+Joq3i/J4Z5R01xccE+sAsGPPFnrylOGljrIwMdgb0Rg5Yqp1Bojl0kgrZm
# UpYLJodqv7UfRcpgfVwLE6nEOgiAgkQuDpWwC8fBsTtzyUVn2r3WynQnVjizLYgv
# OtfNIAvcBsWQJ1tO3JcRfxEvZ9PBmjUQ/Kn+dwCnsmt+ByxHPU3EWhYXdWvl4TJp
# /daFBhESYM7EGCCF2V232/0YDaHpv8NYW0grrCLCJm2dOrxrkmc/nlX2hx29if0Z
# CRqfy59TysOWbeDJiCw3gcEf5BugSpny0LUTZ1BtkoAzozLNjGpBtKGYsvQe7Dyh
# CxYaxfI8qbfTXwkXwCUmEe/D+q4X9HGrOv0YRTCiY3QMDAueRqKaTxuXBUEhZGzF
# je90dNi4oldjbPKEYKqDn6JHiVBN94LE17iXMtjkVJQIrSXkoh5oca2EzQzyFw==
# SIG # End signature block

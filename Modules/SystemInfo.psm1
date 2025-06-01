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
    
    $statusBox.SelectionColor = [System.Drawing.Color]::DarkBlue
    $statusBox.AppendText("===== SYSTEM-STATUS ÜBERSICHT =====`r`n`r`n")
    
    # Windows Defender Status - 20%
    $statusBox.SelectionColor = [System.Drawing.Color]::Blue
    $statusBox.AppendText("WINDOWS DEFENDER STATUS:`r`n")
    $statusBox.SelectionColor = [System.Drawing.Color]::Black
    
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
                $statusBox.SelectionColor = [System.Drawing.Color]::Green
                $statusBox.AppendText("vor $minutesSinceQuickScan Minuten ($scanTimeInfo) (Aktuell)`r`n")
            }
            elseif ($timeSinceQuickScan.TotalHours -lt 24) {
                $hoursSinceQuickScan = [math]::Round($timeSinceQuickScan.TotalHours, 1)
                $statusBox.SelectionColor = [System.Drawing.Color]::Green
                $statusBox.AppendText("vor $hoursSinceQuickScan Stunden ($scanTimeInfo) (Aktuell)`r`n")
            }
            else {
                $hoursSinceQuickScan = [math]::Round($timeSinceQuickScan.TotalHours, 1)
                $statusBox.SelectionColor = [System.Drawing.Color]::OrangeRed
                $statusBox.AppendText("vor $hoursSinceQuickScan Stunden ($scanTimeInfo) (Veraltet)`r`n")
            }
        }
        else {
            $statusBox.SelectionColor = [System.Drawing.Color]::Gray
            $statusBox.AppendText("Nicht verfügbar`r`n")
        }
        
        $statusBox.SelectionColor = [System.Drawing.Color]::Black
        $statusBox.AppendText("Letzter Komplettscan: ")
        if ($fullScanEndTime) {
            $timeSinceFullScan = (Get-Date) - $fullScanEndTime
            $scanTimeInfo = $fullScanEndTime.ToString("dd.MM.yyyy HH:mm:ss")
            
            # Verbesserte Anzeige ähnlich dem Schnellscan
            if ($timeSinceFullScan.TotalHours -lt 1) {
                $minutesSinceFullScan = [math]::Round($timeSinceFullScan.TotalMinutes)
                $statusBox.SelectionColor = [System.Drawing.Color]::Green
                $statusBox.AppendText("vor $minutesSinceFullScan Minuten ($scanTimeInfo) (Aktuell)`r`n")
            }
            elseif ($timeSinceFullScan.TotalHours -lt 168) {
                # 7 Tage in Stunden
                $hoursSinceFullScan = [math]::Round($timeSinceFullScan.TotalHours, 1)
                $statusBox.SelectionColor = [System.Drawing.Color]::Green
                $statusBox.AppendText("vor $hoursSinceFullScan Stunden ($scanTimeInfo) (Aktuell)`r`n")
            }
            else {
                $hoursSinceFullScan = [math]::Round($timeSinceFullScan.TotalHours, 1)
                $statusBox.SelectionColor = [System.Drawing.Color]::OrangeRed
                $statusBox.AppendText("vor $hoursSinceFullScan Stunden ($scanTimeInfo) (Veraltet)`r`n")
            }
        }
        else {
            $statusBox.SelectionColor = [System.Drawing.Color]::Gray
            $statusBox.AppendText("Nicht verfügbar`r`n")
        }
        
        # Bedrohungsstatus mit zusätzlicher Validierung
        $statusBox.SelectionColor = [System.Drawing.Color]::Black
        $statusBox.AppendText("Aktuelle Bedrohungen: ")
        try {
            $threats = Get-MpThreatDetection
            if ($threats -and $threats.Count -gt 0) {
                $statusBox.SelectionColor = [System.Drawing.Color]::Red
                $statusBox.AppendText("$($threats.Count) Bedrohung(en) gefunden!`r`n")
                
                # Detaillierte Bedrohungsinformationen
                foreach ($threat in $threats) {
                    $statusBox.SelectionColor = [System.Drawing.Color]::Red
                    $statusBox.AppendText("  - $($threat.ThreatName) (Erkannt am: $($threat.InitialDetectionTime))`r`n")
                }
            }
            else {
                $statusBox.SelectionColor = [System.Drawing.Color]::Green
                $statusBox.AppendText("Keine Bedrohungen gefunden`r`n")
            }
        }
        catch {
            $statusBox.SelectionColor = [System.Drawing.Color]::Gray
            $statusBox.AppendText("Status nicht verfügbar`r`n")
        }
    }
    catch {
        $statusBox.SelectionColor = [System.Drawing.Color]::Red
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
    
    $statusBox.SelectionColor = [System.Drawing.Color]::Blue
    $statusBox.AppendText("WINDOWS UPDATE STATUS:`r`n")
    $statusBox.SelectionColor = [System.Drawing.Color]::Black
    
    try {
        $updatesSession = New-Object -ComObject Microsoft.Update.Session
        $updatesSearcher = $updatesSession.CreateUpdateSearcher()
        $pendingUpdates = $updatesSearcher.Search("IsInstalled=0")
        
        if ($pendingUpdates.Updates.Count -eq 0) {
            $statusBox.SelectionColor = [System.Drawing.Color]::Green
            $statusBox.AppendText("Keine ausstehenden Updates gefunden.`r`n")
        }
        else {
            $statusBox.SelectionColor = [System.Drawing.Color]::OrangeRed
            $statusBox.AppendText("$($pendingUpdates.Updates.Count) ausstehende Updates gefunden.`r`n")
            
            for ($i = 0; $i -lt [Math]::Min($pendingUpdates.Updates.Count, 5); $i++) {
                $update = $pendingUpdates.Updates.Item($i)
                $statusBox.SelectionColor = [System.Drawing.Color]::Black
                $statusBox.AppendText("- $($update.Title)`r`n")
            }
            
            if ($pendingUpdates.Updates.Count -gt 5) {
                $statusBox.AppendText("- ... und $($pendingUpdates.Updates.Count - 5) weitere Updates`r`n")
            }
        }
    }
    catch {
        $statusBox.SelectionColor = [System.Drawing.Color]::Red
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
    
    $statusBox.SelectionColor = [System.Drawing.Color]::Blue
    $statusBox.AppendText("SYSTEMDIAGNOSTIK STATUS:`r`n")
    $statusBox.SelectionColor = [System.Drawing.Color]::Black
    
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
                        $statusBox.SelectionColor = [System.Drawing.Color]::Green
                        $statusBox.AppendText("vor $([math]::Floor($timeDiff.TotalDays)) Tagen und $([math]::Round($timeDiff.TotalHours % 24)) Stunden (Aktuell)`r`n")
                    }
                    else {
                        $statusBox.SelectionColor = [System.Drawing.Color]::OrangeRed
                        $statusBox.AppendText("vor $([math]::Floor($timeDiff.TotalDays)) Tagen und $([math]::Round($timeDiff.TotalHours % 24)) Stunden (Veraltet)`r`n")
                    }
                }
                else {
                    $statusBox.SelectionColor = [System.Drawing.Color]::Gray
                    $statusBox.AppendText("Datum konnte nicht geparst werden`r`n")
                }
            }
            else {
                $statusBox.SelectionColor = [System.Drawing.Color]::Gray
                $statusBox.AppendText("Kein erfolgreicher Check gefunden`r`n")
            }
        }
        else {
            $statusBox.SelectionColor = [System.Drawing.Color]::Gray
            $statusBox.AppendText("Log nicht verfügbar`r`n")
        }
    }
    catch {
        $statusBox.SelectionColor = [System.Drawing.Color]::Red
        $statusBox.AppendText("Fehler beim Abrufen des SFC-Status: $_`r`n")
    }
    
    # DISM Status prüfen
    try {
        $statusBox.SelectionColor = [System.Drawing.Color]::Black
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
                $statusBox.SelectionColor = [System.Drawing.Color]::Green
                $statusBox.AppendText("vor $([math]::Floor($timeDiff.TotalDays)) Tagen und $([math]::Round($timeDiff.TotalHours % 24)) Stunden (Aktuell)`r`n")
            }
            else {
                $statusBox.SelectionColor = [System.Drawing.Color]::OrangeRed
                $statusBox.AppendText("vor $([math]::Floor($timeDiff.TotalDays)) Tagen und $([math]::Round($timeDiff.TotalHours % 24)) Stunden (Veraltet)`r`n")
            }
        }
        else {
            $statusBox.SelectionColor = [System.Drawing.Color]::Gray
            $statusBox.AppendText("Kein erfolgreicher Check gefunden`r`n")
        }
    }
    catch {
        $statusBox.SelectionColor = [System.Drawing.Color]::Gray
        $statusBox.AppendText("Kein erfolgreicher Check gefunden`r`n")
    }
    
    # Memory Diagnostic Status prüfen
    try {
        $statusBox.SelectionColor = [System.Drawing.Color]::Black
        $statusBox.AppendText("Letzter Memory Diagnostic: ")
        
        # Prüfe die Memory Diagnostic Ergebnis-Datei
        $memoryResult = "$env:TEMP\memory_diagnostic_result.json"
        
        if (Test-Path $memoryResult) {
            $result = Get-Content $memoryResult | ConvertFrom-Json
            if ($result.ExitCode -eq 0) {
                $timeDiff = (Get-Date) - ([DateTime]$result.Timestamp)
                
                if ($timeDiff.TotalDays -lt 30) {
                    $statusBox.SelectionColor = [System.Drawing.Color]::Green
                    $statusBox.AppendText("vor $([math]::Floor($timeDiff.TotalDays)) Tagen und $([math]::Round($timeDiff.TotalHours % 24)) Stunden (Aktuell)`r`n")
                }
                else {
                    $statusBox.SelectionColor = [System.Drawing.Color]::OrangeRed
                    $statusBox.AppendText("vor $([math]::Floor($timeDiff.TotalDays)) Tagen und $([math]::Round($timeDiff.TotalHours % 24)) Stunden (Veraltet)`r`n")
                }
            }
            else {
                $statusBox.SelectionColor = [System.Drawing.Color]::Gray
                $statusBox.AppendText("Keine Informationen verfügbar`r`n")
            }
        }
        else {
            $statusBox.SelectionColor = [System.Drawing.Color]::Gray
            $statusBox.AppendText("Keine Informationen verfügbar`r`n")
        }
    }
    catch {
        $statusBox.SelectionColor = [System.Drawing.Color]::Gray
        $statusBox.AppendText("Keine Informationen verfügbar`r`n")
    }

    # CHKDSK Status prüfen
    try {
        $statusBox.SelectionColor = [System.Drawing.Color]::Black
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
                $statusBox.SelectionColor = [System.Drawing.Color]::Green
                $statusBox.AppendText("vor $([math]::Floor($timeDiff.TotalDays)) Tagen und $([math]::Round($timeDiff.TotalHours % 24)) Stunden (Aktuell)`r`n")
            }
            else {
                $statusBox.SelectionColor = [System.Drawing.Color]::OrangeRed
                $statusBox.AppendText("vor $([math]::Floor($timeDiff.TotalDays)) Tagen und $([math]::Round($timeDiff.TotalHours % 24)) Stunden (Veraltet)`r`n")
            }
        }
        else {
            $statusBox.SelectionColor = [System.Drawing.Color]::Gray
            $statusBox.AppendText("Keine Informationen verfügbar`r`n")
        }
    }
    catch {
        $statusBox.SelectionColor = [System.Drawing.Color]::Gray
        $statusBox.AppendText("Keine Informationen verfügbar`r`n")
    }

    # Disk Cleanup Status prüfen
    try {
        $statusBox.SelectionColor = [System.Drawing.Color]::Black
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
                $statusBox.SelectionColor = [System.Drawing.Color]::Green
                $statusBox.AppendText("vor $([math]::Floor($timeDiff.TotalDays)) Tagen und $([math]::Round($timeDiff.TotalHours % 24)) Stunden (Aktuell)`r`n")
            }
            else {
                $statusBox.SelectionColor = [System.Drawing.Color]::OrangeRed
                $statusBox.AppendText("vor $([math]::Floor($timeDiff.TotalDays)) Tagen und $([math]::Round($timeDiff.TotalHours % 24)) Stunden (Veraltet)`r`n")
            }
        }
        else {
            $statusBox.SelectionColor = [System.Drawing.Color]::Gray
            $statusBox.AppendText("Keine Informationen verfügbar`r`n")
        }
    }
    catch {
        $statusBox.SelectionColor = [System.Drawing.Color]::Gray
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
    
    $statusBox.SelectionColor = [System.Drawing.Color]::Blue
    $statusBox.AppendText("FESTPLATTEN STATUS:`r`n")
    $statusBox.SelectionColor = [System.Drawing.Color]::Black
    
    try {
        $drives = Get-WmiObject -Class Win32_LogicalDisk -Filter "DriveType=3"
        foreach ($drive in $drives) {
            $freeGB = [math]::Round($drive.FreeSpace / 1GB, 2)
            $sizeGB = [math]::Round($drive.Size / 1GB, 2)
            $usedPercent = [math]::Round(($drive.Size - $drive.FreeSpace) / $drive.Size * 100, 1)
            
            $statusBox.AppendText("Laufwerk $($drive.DeviceID) ($($drive.VolumeName)): ")
            
            if ($usedPercent -gt 90) {
                $statusBox.SelectionColor = [System.Drawing.Color]::Red
                $statusBox.AppendText("$usedPercent% belegt (Kritisch!)`r`n")
            }
            elseif ($usedPercent -gt 75) {
                $statusBox.SelectionColor = [System.Drawing.Color]::OrangeRed
                $statusBox.AppendText("$usedPercent% belegt (Warnung)`r`n")
            }
            else {
                $statusBox.SelectionColor = [System.Drawing.Color]::Green
                $statusBox.AppendText("$usedPercent% belegt (OK)`r`n")
            }
            
            $statusBox.SelectionColor = [System.Drawing.Color]::Black
            $statusBox.AppendText("   Freier Speicher: $freeGB GB von $sizeGB GB`r`n")
        }
    }
    catch {
        $statusBox.SelectionColor = [System.Drawing.Color]::Red
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
    
    $statusBox.SelectionColor = [System.Drawing.Color]::Blue
    $statusBox.AppendText("SYSTEMZUSTAND ZUSAMMENFASSUNG:`r`n")
    
    # Betriebszeit prüfen
    try {
        $uptime = (Get-Date) - (Get-CimInstance -ClassName Win32_OperatingSystem).LastBootUpTime
        $uptimeDays = [math]::Round($uptime.TotalDays, 1)
        
        $statusBox.SelectionColor = [System.Drawing.Color]::Black
        $statusBox.AppendText("System-Betriebszeit: ")
        if ($uptimeDays -gt 30) {
            $statusBox.SelectionColor = [System.Drawing.Color]::OrangeRed
            $statusBox.AppendText("$uptimeDays Tage (Neustart empfohlen)`r`n")
        }
        else {
            $statusBox.SelectionColor = [System.Drawing.Color]::Green
            $statusBox.AppendText("$uptimeDays Tage`r`n")
        }
    }
    catch {
        $statusBox.SelectionColor = [System.Drawing.Color]::Red
        $statusBox.AppendText("Fehler beim Abrufen der System-Betriebszeit: $_`r`n")
    }
    
    # Gesamtbewertung
    $statusBox.SelectionColor = [System.Drawing.Color]::Black
    $statusBox.AppendText("`r`nSystem-Status Zusammenfassung:`r`n")
    $statusBox.AppendText("Bericht erstellt am: $(Get-Date -Format 'dd.MM.yyyy HH:mm:ss')`r`n")
    $statusBox.AppendText("Systemname: $($env:COMPUTERNAME)`r`n")
    $statusBox.AppendText("Benutzer: $($env:USERNAME)`r`n")
    
    if ($LiveMode) {
        Start-Sleep -Milliseconds 500
        $progressBar.Value = 0
        $progressBar.CustomText = "Status-Info geladen"
        $progressBar.ForeColor = [System.Drawing.Color]::Green
    }
}

# Exportiere die Funktionen
Export-ModuleMember -Function Get-SystemStatusSummary 

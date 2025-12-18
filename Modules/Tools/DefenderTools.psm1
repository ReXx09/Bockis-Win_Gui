# Import required modules
Import-Module "$PSScriptRoot\..\Core\Core.psm1" -Force -Global
Import-Module "$PSScriptRoot\..\Core\ProgressBarTools.psm1" -Force -Global
Import-Module "$PSScriptRoot\..\Core\TextStyle.psm1" -Force -Global

# Function to start Windows Defender and show status
function Start-WindowsDefender {
    param(
        [System.Windows.Forms.RichTextBox]$outputBox,
        [System.Windows.Forms.ProgressBar]$progressBar = $null,
        [System.Windows.Forms.Form]$MainForm = $null
    )
    
    # outputBox zurücksetzen
    $outputBox.Clear()
    
    # In Log-Datei und Datenbank schreiben, dass Windows Defender gestartet wird
    Write-ToolLog -ToolName "WindowsDefender" -Message "Windows Defender Status-Check wird gestartet" -OutputBox $outputBox -Style 'Action' -Level "Information" -SaveToDatabase
    
    # PowerShell-Fenster aktivieren und Konsole leeren
    try {
        # Minimalen Code zur Aktivierung des Konsolenfensters verwenden
        $signature = @'
        [DllImport("user32.dll")]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool SetForegroundWindow(IntPtr hWnd);
        
        [DllImport("kernel32.dll")]
        public static extern IntPtr GetConsoleWindow();
'@
        try {
            $type = Add-Type -MemberDefinition $signature -Name "ConsoleFunctions" -Namespace "Win32Simple" -PassThru -ErrorAction SilentlyContinue
            $hwnd = $type::GetConsoleWindow()
            if ($hwnd -ne [IntPtr]::Zero) {
                [void]$type::SetForegroundWindow($hwnd)
            }
        }
        catch {
            # Ignorieren, falls nicht möglich
            Write-Host "Hinweis: Konnte PowerShell-Fenster nicht aktivieren. Der Scan läuft trotzdem."
        }
    }
    catch {
        # Ignorieren, falls nicht möglich
    }
    
    Clear-Host
    
    # Rahmen und Systeminformationen erstellen
    #$computerName = $env:COMPUTERNAME
    #$userName = $env:USERNAME
    #$osInfo = (Get-CimInstance -ClassName Win32_OperatingSystem).Caption
    #$dateTime = Get-Date -Format "dd.MM.yyyy HH:mm:ss"
    #$width = 80
    
    # Rahmen oben
    Write-Host "╔══════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-ColoredCenteredText                              "Windows Defender"                                          
    Write-Host "╚══════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Green
    
    # ASCII-Art Logo
    Write-Host
    Write-Host
    Write-Host '  888       888  d8b                 888                                                 ' -ForegroundColor Cyan
    Write-Host '  888   o   888  Y8P                 888                                                 ' -ForegroundColor Blue
    Write-Host '  888  d8b  888                      888                                                 ' -ForegroundColor Cyan
    Write-Host '  888 d888b 888  888  88888b.    .d88888   .d88b.   888  888  888  .d8888b               ' -ForegroundColor Blue
    Write-Host '  888d88888b888  888  888 "88b  d88" 888  d88""88b  888  888  888  88K                   ' -ForegroundColor Cyan
    Write-Host '  88888P Y88888  888  888  888  888  888  888  888  888  888  888  "Y8888b.              ' -ForegroundColor Blue    
    Write-Host '  8888P   Y8888  888  888  888  Y88b 888  Y88..88P  Y88b 888 d88P       X88              ' -ForegroundColor Cyan
    Write-Host '  888P     Y888  888  888  888   "Y88888   "Y88P"    "Y8888888P"    88888P               ' -ForegroundColor Blue
    Write-Host                                                                    
    Write-Host ' 8888888b.              .d888                          888                                 ' -ForegroundColor Cyan
    Write-Host ' 888  "Y88b            d88P"                           888                                 ' -ForegroundColor Blue
    Write-Host ' 888    888            888                             888                                 ' -ForegroundColor Cyan
    Write-Host ' 888    888   .d88b.   888888  .d88b.   88888b.    .d88888   .d88b.   888d888                ' -ForegroundColor Blue
    Write-Host ' 888    888  d8P  Y8b  888    d8P  Y8b  888 "88b  d88" 888  d8P  Y8b  888P"                  ' -ForegroundColor Cyan
    Write-Host ' 888    888  88888888  888    88888888  888  888  888  888  88888888  888                    ' -ForegroundColor Blue
    Write-Host ' 888  .d88P  Y8b.      888    Y8b.      888  888  Y88b 888  Y8b.      888                    ' -ForegroundColor Cyan
    Write-Host ' 8888888P"    "Y8888   888     "Y8888   888  888   "Y88888   "Y8888   888                    ' -ForegroundColor Blue
    Write-Host
    
    # Rahmen für Systeminformationen
    Write-Host "╔══════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-ColoredCenteredText                          "INFORMATIONEN"                                           
    Write-Host "╠══════════════════════════════════════════════════════════════════════════════╣" -ForegroundColor Green
    # Systeminformationen
    Write-Host "║                                                                              ║" -ForegroundColor Green
    Write-Host "  ├─  Systemschutz mit Windows Defender:                                          "  -ForegroundColor Yellow                 
    Write-Host "  ├─  Der integrierte Virenscanner prüft Ihr System auf Bedrohungen.              "  -ForegroundColor Yellow                                    
    Write-Host "  ├─  Er bietet Echtzeitschutz sowie manuelle Schnell- und Vollscans.             "  -ForegroundColor Yellow                                    
    Write-Host "  └─  Empfohlen für kontinuierlichen Schutz ohne zusätzliche Software.            "  -ForegroundColor Yellow                                  
    Write-Host "║                                                                              ║" -ForegroundColor Green
    
    Write-Host "╠══════════════════════════════════════════════════════════════════════════════╣" -ForegroundColor Green
    Write-ColoredCenteredText "Windows Defender wird initialisiert..."
    Write-Host "╚══════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Green
    
    # 2 Sekunden warten vor dem Start
    Start-Sleep -Seconds 2
    
    # Tab zur Ausgabe umschalten
    Switch-ToOutputTab
    
    # Hole die Konfiguration aus dem Core-Modul
    $config = Get-SystemToolConfig -ToolName "WindowsDefender"
    
    try {
        # Status aktualisieren
        Update-ProgressStatus -StatusText "Starte $($config.Description)..." -ProgressValue 0 -TextColor ([System.Drawing.Color]::White) -progressBarParam $progressBar
        
        # Status in GUI aktualisieren
        Write-ToolLog -ToolName "WindowsDefender" -Message "Starte Windows Defender und rufe Status ab..." -OutputBox $outputBox -Style 'Action' -Level "Information" -NoTimestamp -SaveToDatabase
              
        # Status abrufen und anzeigen
        $status = Get-MpComputerStatus
        Write-ConsoleAndOutputBox -Message "Aktueller Windows Defender Status:" -Type "Info" -OutputBox $outputBox -ToolName "WindowsDefender" -NoTimestamp -SaveToDatabase
        
        Write-Host " - Antivirus: $($status.AntivirusEnabled)" -ForegroundColor Yellow
        Write-ToolLog -ToolName "WindowsDefender" -Message " - Antivirus: $($status.AntivirusEnabled)" -OutputBox $outputBox -Level "Information" -NoTimestamp -SaveToDatabase
        Write-Host " - Echtzeit-Schutz: $($status.RealTimeProtectionEnabled)" -ForegroundColor Yellow
        Write-ToolLog -ToolName "WindowsDefender" -Message " - Echtzeit-Schutz: $($status.RealTimeProtectionEnabled)" -OutputBox $outputBox -Level "Information" -NoTimestamp -SaveToDatabase

        Write-Host " - Virensignaturen: $($status.AntivirusSignatureVersion)" -ForegroundColor Yellow
        Write-ToolLog -ToolName "WindowsDefender" -Message " - Virensignaturen: $($status.AntivirusSignatureVersion)" -OutputBox $outputBox -Level "Information" -NoTimestamp -SaveToDatabase

        Write-Host " - Letztes Update: $($status.AntivirusSignatureLastUpdated)" -ForegroundColor Yellow
        Write-ToolLog -ToolName "WindowsDefender" -Message " - Letztes Update: $($status.AntivirusSignatureLastUpdated)" -OutputBox $outputBox -Level "Information" -NoTimestamp -SaveToDatabase

        # Verbesserte Darstellung des letzten Scans mit genaueren Zeitangaben
        if ($status.QuickScanEndTime) {
            $timeSinceScan = (Get-Date) - $status.QuickScanEndTime
            $scanTimeInfo = $status.QuickScanEndTime.ToString("dd.MM.yyyy HH:mm:ss")
            
            if ($timeSinceScan.TotalHours -lt 1) {
                $minutesSinceScan = [Math]::Round($timeSinceScan.TotalMinutes)
                Write-Host " - Letzter Scan: vor $minutesSinceScan Minuten ($scanTimeInfo)" -ForegroundColor Blue
                Write-ToolLog -ToolName "WindowsDefender" -Message " - Letzter Scan: vor $minutesSinceScan Minuten ($scanTimeInfo)" -OutputBox $outputBox -Level "Information" -NoTimestamp -SaveToDatabase
            }
            else {
                $hoursSinceScan = [Math]::Round($timeSinceScan.TotalHours, 1)
                Write-Host " - Letzter Scan: vor $hoursSinceScan Stunden ($scanTimeInfo)" -ForegroundColor Blue
                Write-ToolLog -ToolName "WindowsDefender" -Message " - Letzter Scan: vor $hoursSinceScan Stunden ($scanTimeInfo)" -OutputBox $outputBox -Level "Information" -NoTimestamp -SaveToDatabase
            }
        }
        else {
            Write-Host " - Letzter Scan: vor $($status.QuickScanAge) Stunden" -ForegroundColor Blue
            Write-ToolLog -ToolName "WindowsDefender" -Message " - Letzter Scan: vor $($status.QuickScanAge) Stunden" -OutputBox $outputBox -Level "Information" -NoTimestamp -SaveToDatabase
        }        
        if (-not $status.AntivirusEnabled) {
            Write-ConsoleAndOutputBox -Message "WARNUNG: Windows Defender Antivirus ist nicht aktiv!" -Type "Warning" -OutputBox $outputBox -ToolName "WindowsDefender" -NoTimestamp -SaveToDatabase
        }
        Write-Host "`n" + ("═" * 70) -ForegroundColor Cyan
        
        # Starte Quick Scan in der PowerShell
        Write-ConsoleAndOutputBox -Message "Starte Windows Defender Quick Scan..." -Type "Start" -OutputBox $outputBox -ToolName "WindowsDefender" -NoTimestamp -SaveToDatabase
        
        Update-ProgressStatus -StatusText "Führe Quick Scan aus..." -ProgressValue 10 -TextColor ([System.Drawing.Color]::White) -progressBarParam $progressBar
        
        # PowerShell-Befehl für den Quick Scan direkt ausführen statt als Job
        try {
            # Fallback-Flag initialisieren
            $useFallback = $false
            $scanSuccessful = $false
            
            # Direkte Ausführung des Scans mit Fortschrittsanzeige
            $scanProgress = 20
            Update-ProgressStatus -StatusText "Windows Defender Quick Scan läuft... $scanProgress%" -ProgressValue $scanProgress -TextColor ([System.Drawing.Color]::White) -progressBarParam $progressBar
            
            # Führe den Scan direkt aus
            $scanResult = $null
            
            # Versuche, das Windows Defender PowerShell-Modul zu laden
            if (-not (Get-Module -Name Defender -ErrorAction SilentlyContinue)) {
                try {
                    Import-Module Defender -ErrorAction SilentlyContinue
                }
                catch {
                    Write-Host "Hinweis: Windows Defender PowerShell-Modul konnte nicht geladen werden." -ForegroundColor Yellow
                }
            }
            if (Get-Command Start-MpScan -ErrorAction SilentlyContinue) {
                Write-ConsoleAndOutputBox -Message "Führe QuickScan mit Start-MpScan aus..." -Type "Info" -OutputBox $outputBox -ToolName "WindowsDefender" -NoTimestamp
                
                # Animationszeichen für Fortschritt
                $progressChars = @('|', '/', '-', '\')
                $progressIndex = 0
                $startTime = Get-Date
                
                try {
                    # Scan im Hintergrund starten
                    $scanJob = Start-Job -ScriptBlock {
                        try {
                            Start-MpScan -ScanType QuickScan -ErrorAction Stop
                        }
                        catch {
                            throw $_
                        }
                    }
                    
                    # Warte auf Abschluss des Jobs mit Fortschrittsanzeige
                    while ($scanJob.State -eq 'Running') {
                        $progressChar = $progressChars[$progressIndex]
                        $progressIndex = ($progressIndex + 1) % $progressChars.Length
                        $elapsedTime = (Get-Date) - $startTime
                        $formattedTime = "{0:mm}:{0:ss}" -f $elapsedTime
                        
                        Write-Host "`r[>] Scan läuft $progressChar Dauer: $formattedTime " -NoNewline -ForegroundColor Yellow
                        
                        if ($scanProgress -lt 90) {
                            $scanProgress += 1
                        }
                        Update-ProgressStatus -StatusText "Windows Defender Quick Scan läuft... $scanProgress%" -ProgressValue $scanProgress -TextColor ([System.Drawing.Color]::White) -progressBarParam $progressBar
                        
                        Start-Sleep -Milliseconds 500
                    }
                    
                    Write-Host ""  # Neue Zeile nach Animation
                    
                    # Prüfe Job-Status
                    if ($scanJob.State -eq 'Failed') {
                        $jobError = Receive-Job -Job $scanJob 2>&1
                        Remove-Job -Job $scanJob -Force
                        throw "Defender-Scan fehlgeschlagen: $jobError"
                    }
                    
                    # Ergebnis abholen
                    $scanResult = Receive-Job -Job $scanJob 2>&1
                    Remove-Job -Job $scanJob -Force
                    
                    $scanSuccessful = $true
                    Write-ConsoleAndOutputBox -Message "Windows Defender Quick Scan abgeschlossen." -Type "Success" -OutputBox $outputBox -ToolName "WindowsDefender" -NoTimestamp -SaveToDatabase
                    Write-Host "`n" + ("═" * 70) -ForegroundColor Cyan
                }
                catch {
                    $errorMsg = $_.Exception.Message
                    Write-ConsoleAndOutputBox -Message "Fehler beim Defender-Scan: $errorMsg" -Type "Warning" -OutputBox $outputBox -ToolName "WindowsDefender" -NoTimestamp
                    
                    # Prüfe auf spezifische Fehler
                    if ($errorMsg -match "0x800106ba|RPC|nicht verfügbar") {
                        Write-ConsoleAndOutputBox -Message "Windows Defender-Dienst antwortet nicht. Versuche Dienst-Neustart..." -Type "Info" -OutputBox $outputBox -ToolName "WindowsDefender" -NoTimestamp
                        
                        try {
                            Restart-Service -Name "WinDefend" -Force -ErrorAction Stop
                            Start-Sleep -Seconds 2
                            Write-ConsoleAndOutputBox -Message "Defender-Dienst wurde neu gestartet." -Type "Success" -OutputBox $outputBox -ToolName "WindowsDefender" -NoTimestamp
                        }
                        catch {
                            Write-ConsoleAndOutputBox -Message "Dienst-Neustart fehlgeschlagen: $($_.Exception.Message)" -Type "Warning" -OutputBox $outputBox -ToolName "WindowsDefender" -NoTimestamp
                        }
                    }
                    elseif ($errorMsg -match "0x80004005|Fehler aufgetreten") {
                        Write-ConsoleAndOutputBox -Message "Allgemeiner Fehler erkannt (0x80004005). Möglicherweise ist das System beschäftigt oder der Defender-Dienst ist nicht bereit." -Type "Warning" -OutputBox $outputBox -ToolName "WindowsDefender" -NoTimestamp
                    }
                    
                    # Fallback zu MpCmdRun
                    Write-ConsoleAndOutputBox -Message "Wechsle zu MpCmdRun.exe als Alternative..." -Type "Info" -OutputBox $outputBox -ToolName "WindowsDefender" -NoTimestamp
                    $useFallback = $true
                }
            }
            
            if (-not (Get-Command Start-MpScan -ErrorAction SilentlyContinue) -or $useFallback) {
                # Alternativer Ansatz mit MpCmdRun
                Write-ConsoleAndOutputBox -Message "Start-MpScan nicht verfügbar, verwende MpCmdRun.exe als Alternative..." -Type "Info" -OutputBox $outputBox -ToolName "WindowsDefender" -NoTimestamp
                $mpCmdRunPath = "$env:ProgramFiles\Windows Defender\MpCmdRun.exe"
                if (Test-Path $mpCmdRunPath) {
                    Write-ConsoleAndOutputBox -Message "MpCmdRun.exe gefunden, starte QuickScan..." -Type "Info" -OutputBox $outputBox -ToolName "WindowsDefender" -NoTimestamp
                    
                    # Führe MpCmdRun mit Quick Scan aus
                    $process = Start-Process -FilePath $mpCmdRunPath -ArgumentList "-Scan -ScanType 1" -NoNewWindow -PassThru -Wait
                    
                    # Zeige Fortschritt während der Scan läuft
                    $startTime = Get-Date
                    $progressChars = @('|', '/', '-', '\')
                    $progressIndex = 0
                    
                    while (-not $process.HasExited) {
                        $progressChar = $progressChars[$progressIndex]
                        $progressIndex = ($progressIndex + 1) % $progressChars.Length
                        $elapsedTime = (Get-Date) - $startTime
                        $formattedTime = "{0:mm}:{0:ss}" -f $elapsedTime
                        
                        Write-Host "`r[>] Scan läuft $progressChar Dauer: $formattedTime " -NoNewline -ForegroundColor Yellow
                        
                        if ($scanProgress -lt 90) {
                            $scanProgress += 1
                        }
                        Update-ProgressStatus -StatusText "Windows Defender Quick Scan läuft... $scanProgress%" -ProgressValue $scanProgress -TextColor ([System.Drawing.Color]::White) -progressBarParam $progressBar
                        Start-Sleep -Milliseconds 500
                        
                        # Prüfe nach kurzer Zeit wieder den Status
                        $process.Refresh()
                    }
                    
                    Write-Host ""  # Neue Zeile nach Animation
                    
                    # MpCmdRun Exit-Codes:
                    # 0 = Erfolg, keine Bedrohungen
                    # 2 = Bedrohungen gefunden
                    # Andere = Fehler
                    if ($process.ExitCode -eq 0 -or $process.ExitCode -eq 2) {
                        $scanSuccessful = $true
                        if ($process.ExitCode -eq 2) {
                            Write-ConsoleAndOutputBox -Message "Windows Defender Quick Scan (MpCmdRun) abgeschlossen - Bedrohungen gefunden!" -Type "Warning" -OutputBox $outputBox -ToolName "WindowsDefender" -NoTimestamp -SaveToDatabase
                        }
                        else {
                            Write-ConsoleAndOutputBox -Message "Windows Defender Quick Scan (MpCmdRun) abgeschlossen." -Type "Success" -OutputBox $outputBox -ToolName "WindowsDefender" -NoTimestamp -SaveToDatabase
                        }
                    }
                    else {
                        # Prüfe auf bekannte Fehlercodes
                        $errorMsg = switch ($process.ExitCode) {
                            -2147467259 { "Allgemeiner Fehler (0x80004005) - Defender-Dienst nicht bereit oder System beschäftigt" }
                            -2147024809 { "Ungültige Parameter (0x80070057)" }
                            -2147024891 { "Zugriff verweigert (0x80070005) - Bitte als Administrator ausführen" }
                            default { "Unbekannter Fehler (ExitCode: $($process.ExitCode))" }
                        }
                        Write-ConsoleAndOutputBox -Message "MpCmdRun-Fehler: $errorMsg" -Type "Error" -OutputBox $outputBox -ToolName "WindowsDefender" -NoTimestamp -SaveToDatabase
                        
                        # Prüfe Log-Datei
                        $logPath = "$env:TEMP\MpCmdRun.log"
                        if (Test-Path $logPath) {
                            Write-ConsoleAndOutputBox -Message "Details in Log-Datei: $logPath" -Type "Info" -OutputBox $outputBox -ToolName "WindowsDefender" -NoTimestamp
                        }
                    }                
                }
                else {
                    Write-ConsoleAndOutputBox -Message "Weder Start-MpScan noch MpCmdRun.exe konnten gefunden werden." -Type "Error" -OutputBox $outputBox -ToolName "WindowsDefender" -NoTimestamp -SaveToDatabase
                }
            }            
            
            # Scan-Ergebnisse nur auswerten, wenn Scan erfolgreich war
            if ($scanSuccessful) {
                Write-ConsoleAndOutputBox -Message "Scan-Ergebnisse werden ausgewertet..." -Type "Info" -OutputBox $outputBox -ToolName "WindowsDefender" -NoTimestamp -SaveToDatabase
                
                $threats = $null
                try {
                    # Versuche, aktuelle Bedrohungen zu ermitteln
                    if (Get-Command Get-MpThreatDetection -ErrorAction SilentlyContinue) {
                        $threats = Get-MpThreatDetection | Where-Object { $_.ThreatStatus -ne "Resolved" }
                    }
                    if ($threats -and $threats.Count -gt 0) {
                        $threatCount = $threats.Count
                        Write-ConsoleAndOutputBox -Message "Scan-Ergebnis: $threatCount aktive Bedrohung(en) erkannt!" -Type "Warning" -OutputBox $outputBox -ToolName "WindowsDefender" -NoTimestamp -SaveToDatabase
                        
                        # Liste alle erkannten Bedrohungen auf
                        foreach ($threat in $threats) {
                            Write-Host "    - $($threat.ThreatName) ($($threat.ThreatID))" -ForegroundColor Red
                            Write-ToolLog -ToolName "WindowsDefender" -Message "- $($threat.ThreatName) ($($threat.ThreatID))" -OutputBox $outputBox -Style 'Error' -Level "Warning" -NoTimestamp -SaveToDatabase
                        }
                    }
                    else {
                        Write-ConsoleAndOutputBox -Message "Scan-Ergebnis: Keine Bedrohungen erkannt - System ist sauber." -Type "Success" -OutputBox $outputBox -ToolName "WindowsDefender" -NoTimestamp -SaveToDatabase
                    }            
                }
                catch {
                    Write-ConsoleAndOutputBox -Message "Fehler beim Auswerten der Scan-Ergebnisse: $_" -Type "Warning" -OutputBox $outputBox -ToolName "WindowsDefender" -NoTimestamp
                }
            }
            else {
                Write-ConsoleAndOutputBox -Message "Scan wurde nicht erfolgreich abgeschlossen - Keine Ergebnisse verfügbar." -Type "Warning" -OutputBox $outputBox -ToolName "WindowsDefender" -NoTimestamp -SaveToDatabase
            }        
        }
        catch {
            Write-ConsoleAndOutputBox -Message "Fehler beim Ausführen des Windows Defender Scans: $_" -Type "Error" -OutputBox $outputBox -ToolName "WindowsDefender" -SaveToDatabase
            $scanSuccessful = $false
        }
        
        # Status setzen basierend auf Scan-Erfolg
        if ($scanSuccessful) {
            Update-ProgressStatus -StatusText "Windows Defender Scan abgeschlossen" -ProgressValue 100 -TextColor ([System.Drawing.Color]::LimeGreen) -progressBarParam $progressBar
        }
        else {
            Update-ProgressStatus -StatusText "Scan fehlgeschlagen - siehe Details oben" -ProgressValue 100 -TextColor ([System.Drawing.Color]::Orange) -progressBarParam $progressBar
        }
    }
    catch {
        Write-ConsoleAndOutputBox -Message "Kritischer Fehler beim Windows Defender Scan: $_" -Type "Error" -OutputBox $outputBox -ToolName "WindowsDefender" -SaveToDatabase
        Update-ProgressStatus -StatusText "Kritischer Fehler" -ProgressValue 0 -TextColor ([System.Drawing.Color]::Red) -progressBarParam $progressBar
    }

    # Nach dem Scan: Nutzer fragen, ob das Windows-Sicherheitscenter geöffnet werden soll
    $result = [System.Windows.Forms.MessageBox]::Show(
        "Möchten Sie das Windows-Sicherheitscenter (Defender) öffnen?",
        "Windows Defender öffnen",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Question
    )
    if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
        Start-Process "windowsdefender:"
    }
}

# Funktion zum Neustart des Windows Defender-Dienstes
function Restart-DefenderService {
    param(
        [System.Windows.Forms.RichTextBox]$outputBox,
        [System.Windows.Forms.ProgressBar]$progressBar = $null,
        [System.Windows.Forms.Form]$MainForm = $null
    )
    
    Switch-ToOutputTab
    
    # PowerShell-Fenster aktivieren und Konsole leeren
    try {
        # Minimalen Code zur Aktivierung des Konsolenfensters verwenden
        $signature = @'
        [DllImport("user32.dll")]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool SetForegroundWindow(IntPtr hWnd);
        
        [DllImport("kernel32.dll")]
        public static extern IntPtr GetConsoleWindow();
'@
        try {
            $type = Add-Type -MemberDefinition $signature -Name "ConsoleFunctions" -Namespace "Win32Simple" -PassThru -ErrorAction SilentlyContinue
            $hwnd = $type::GetConsoleWindow()
            if ($hwnd -ne [IntPtr]::Zero) {
                [void]$type::SetForegroundWindow($hwnd)
            }
        }
        catch {
            # Ignorieren, falls nicht möglich
            Write-Host "Hinweis: Konnte PowerShell-Fenster nicht aktivieren. Der Dienst-Neustart läuft trotzdem."
        }
    }
    catch {
        # Ignorieren, falls nicht möglich
    }
    
    Clear-Host
    
    # Hole die Konfiguration aus dem Core-Modul
    $config = Get-SystemToolConfig -ToolName "WindowsDefender"
    
    # Rahmen oben
    Write-Host "╔══════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-ColoredCenteredText                    "Windows Defender Dienst Neustart"                                          
    Write-Host "╚══════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Green
    
    try {
        # Status aktualisieren
        Update-ProgressStatus -StatusText "Starte Windows Defender-Dienst neu..." -ProgressValue 0 -TextColor ([System.Drawing.Color]::White) -progressBarParam $progressBar
        
        # Relevante Dienste
        $defenderServices = @(
            "WinDefend", # Windows Defender-Dienst
            "WdNisSvc", # Network Inspection Service
            "SecurityHealthService" # Windows Security Health Service
        )
        
        # Sense (ATP) separat behandeln - nur wenn verfügbar und aktiviert
        $senseService = Get-Service -Name "Sense" -ErrorAction SilentlyContinue
        if ($senseService -and $senseService.StartType -ne "Disabled") {
            $defenderServices += "Sense"
        }
        $restartedServices = 0
        $totalServices = $defenderServices.Count
        
        Write-ConsoleAndOutputBox -Message "Starte Neustart der Windows Defender-Dienste..." -Type "Start" -OutputBox $outputBox -ToolName "WindowsDefender" -NoTimestamp -SaveToDatabase
        
        foreach ($service in $defenderServices) {
            try {
                # Prüfen, ob der Dienst existiert
                $svc = Get-Service -Name $service -ErrorAction SilentlyContinue
                if ($svc) {
                    Write-ConsoleAndOutputBox -Message "Dienst: $service" -Type "Info" -OutputBox $outputBox -ToolName "WindowsDefender" -NoTimestamp -SaveToDatabase
                    
                    # Aktuellen Status prüfen
                    $initialStatus = $svc.Status
                    $initialStartType = $svc.StartType
                    
                    # Nur stoppen/starten wenn der Dienst nicht deaktiviert ist
                    if ($initialStartType -eq "Disabled") {
                        Write-Host "    - Dienst ist deaktiviert, überspringe Neustart" -ForegroundColor Yellow
                        Write-ToolLog -ToolName "WindowsDefender" -Message "  - Dienst ist deaktiviert, überspringe Neustart" -OutputBox $outputBox -Style 'Warning' -NoTimestamp
                        continue
                    }
                    
                    # Dienst stoppen
                    Write-Host "    - Stoppe Dienst..." -ForegroundColor Cyan
                    Write-ToolLog -ToolName "WindowsDefender" -Message "  - Stoppe Dienst..." -OutputBox $outputBox -Level "Information" -NoTimestamp -SaveToDatabase
                    
                    try {
                        Stop-Service -Name $service -Force -ErrorAction Stop -WarningAction SilentlyContinue
                        Start-Sleep -Seconds 2
                    }
                    catch {
                        Write-Host "    - Warnung beim Stoppen: $_" -ForegroundColor Yellow
                    }
                    
                    # Dienst starten
                    Write-Host "    - Starte Dienst..." -ForegroundColor Cyan
                    Write-ToolLog -ToolName "WindowsDefender" -Message "  - Starte Dienst..." -OutputBox $outputBox -Level "Information" -NoTimestamp -SaveToDatabase
                    
                    try {
                        Start-Service -Name $service -ErrorAction Stop -WarningAction SilentlyContinue
                        Start-Sleep -Seconds 1
                        
                        # Status des Dienstes prüfen
                        $svcStatus = (Get-Service -Name $service).Status
                        if ($svcStatus -eq "Running") {
                            Write-Host "    - Status: $svcStatus ✓" -ForegroundColor Green
                            Write-ToolLog -ToolName "WindowsDefender" -Message "  - Status: $svcStatus ✓" -OutputBox $outputBox -Style 'Success' -NoTimestamp
                            $restartedServices++
                        } 
                        else {
                            Write-Host "    - Status: $svcStatus ✗" -ForegroundColor Red
                            Write-ToolLog -ToolName "WindowsDefender" -Message "  - Status: $svcStatus ✗" -OutputBox $outputBox -Style 'Error' -NoTimestamp
                        }
                    }
                    catch {
                        Write-Host "    - Fehler beim Starten: $_" -ForegroundColor Red
                        Write-ToolLog -ToolName "WindowsDefender" -Message "  - Fehler beim Starten: $_" -OutputBox $outputBox -Style 'Error' -NoTimestamp
                        
                        # Wenn der Dienst automatisch starten sollte, warte noch etwas
                        if ($initialStartType -eq "Automatic") {
                            Write-Host "    - Warte auf automatischen Start..." -ForegroundColor Yellow
                            Start-Sleep -Seconds 3
                            $svcStatus = (Get-Service -Name $service).Status
                            if ($svcStatus -eq "Running") {
                                Write-Host "    - Dienst wurde automatisch gestartet ✓" -ForegroundColor Green
                                $restartedServices++
                            }
                        }
                    }                
                } 
                else {
                    Write-ConsoleAndOutputBox -Message "Dienst $service nicht gefunden." -Type "Warning" -OutputBox $outputBox -ToolName "WindowsDefender" -NoTimestamp
                }            
            }
            catch {
                Write-ConsoleAndOutputBox -Message "Fehler beim Neustart des Dienstes $service - Fehlermeldung: $_" -Type "Error" -OutputBox $outputBox -ToolName "WindowsDefender" -NoTimestamp
            }
            
            # Fortschritt aktualisieren
            if ($progressBar) {
                $progressValue = [Math]::Round(($restartedServices / $totalServices) * 100)
                $statusMessage = "Dienste werden neu gestartet... " + $progressValue + "%"
                Update-ProgressStatus -StatusText $statusMessage -ProgressValue $progressValue -TextColor ([System.Drawing.Color]::Blue) -progressBarParam $progressBar
            }
        }
        # MpCmdRun.exe zur Aktualisierung der Signaturen ausführen
        Write-ConsoleAndOutputBox -Message "Aktualisiere Defender-Signaturen..." -Type "Start" -OutputBox $outputBox -ToolName "WindowsDefender" -NoTimestamp
        
        $mpCmdRunPath = "$env:ProgramFiles\Windows Defender\MpCmdRun.exe"
        if (Test-Path $mpCmdRunPath) {
            Write-Host "    - Starte Update-Prozess..." -ForegroundColor Cyan
            Start-Process -FilePath $mpCmdRunPath -ArgumentList "-SignatureUpdate" -NoNewWindow -Wait
            
            Write-ConsoleAndOutputBox -Message "  - Signatur-Update abgeschlossen." -Type "Success" -OutputBox $outputBox -ToolName "WindowsDefender" -NoTimestamp        
        }
        else {
            Write-ConsoleAndOutputBox -Message "MpCmdRun.exe nicht gefunden. Signatur-Update übersprungen." -Type "Warning" -OutputBox $outputBox -ToolName "WindowsDefender" -NoTimestamp
        }
        
        # Status abrufen und anzeigen
        $status = Get-MpComputerStatus
        Write-ConsoleAndOutputBox -Message "Aktueller Status nach Neustart:" -Type "Start" -OutputBox $outputBox -ToolName "WindowsDefender" -NoTimestamp -SaveToDatabase
        
        Write-Host "    - Antivirus: $($status.AntivirusEnabled)" -ForegroundColor Yellow
        Write-ToolLog -ToolName "WindowsDefender" -Message "- Antivirus: $($status.AntivirusEnabled)" -OutputBox $outputBox -Level "Information" -NoTimestamp -SaveToDatabase
        
        Write-Host "    - Echtzeit-Schutz: $($status.RealTimeProtectionEnabled)" -ForegroundColor Yellow
        Write-ToolLog -ToolName "WindowsDefender" -Message "- Echtzeit-Schutz: $($status.RealTimeProtectionEnabled)" -OutputBox $outputBox -Level "Information" -NoTimestamp -SaveToDatabase
        
        # Zusätzliche detaillierte Status-Informationen
        Write-Host "    - Virensignaturen: $($status.AntivirusSignatureVersion)" -ForegroundColor Yellow
        Write-ToolLog -ToolName "WindowsDefender" -Message "- Virensignaturen: $($status.AntivirusSignatureVersion)" -OutputBox $outputBox -Level "Information" -NoTimestamp -SaveToDatabase
        
        Write-Host "    - Letztes Update: $($status.AntivirusSignatureLastUpdated)" -ForegroundColor Yellow
        Write-ToolLog -ToolName "WindowsDefender" -Message "- Letztes Update: $($status.AntivirusSignatureLastUpdated)" -OutputBox $outputBox -Level "Information" -NoTimestamp -SaveToDatabase
        
        # Verbesserte Darstellung des letzten Scans mit genaueren Zeitangaben
        if ($status.QuickScanEndTime) {
            $timeSinceScan = (Get-Date) - $status.QuickScanEndTime
            $scanTimeInfo = $status.QuickScanEndTime.ToString("dd.MM.yyyy HH:mm:ss")
            
            if ($timeSinceScan.TotalHours -lt 1) {
                $minutesSinceScan = [Math]::Round($timeSinceScan.TotalMinutes)
                Write-Host "    - Letzter Scan: vor $minutesSinceScan Minuten ($scanTimeInfo)" -ForegroundColor Cyan
                Write-ToolLog -ToolName "WindowsDefender" -Message "- Letzter Scan: vor $minutesSinceScan Minuten ($scanTimeInfo)" -OutputBox $outputBox -Level "Information" -NoTimestamp -SaveToDatabase
            }
            else {
                $hoursSinceScan = [Math]::Round($timeSinceScan.TotalHours, 1)
                Write-Host "    - Letzter Scan: vor $hoursSinceScan Stunden ($scanTimeInfo)" -ForegroundColor Cyan
                Write-ToolLog -ToolName "WindowsDefender" -Message "- Letzter Scan: vor $hoursSinceScan Stunden ($scanTimeInfo)" -OutputBox $outputBox -Level "Information" -NoTimestamp -SaveToDatabase
            }
        }
        else {
            Write-Host "    - Letzter Scan: vor $($status.QuickScanAge) Stunden" -ForegroundColor Cyan
            Write-ToolLog -ToolName "WindowsDefender" -Message "- Letzter Scan: vor $($status.QuickScanAge) Stunden" -OutputBox $outputBox -Level "Information" -NoTimestamp -SaveToDatabase
        }
        if (-not $status.AntivirusEnabled) {
            Write-ConsoleAndOutputBox -Message "WARNUNG: Windows Defender Antivirus ist nicht aktiv!" -Type "Warning" -OutputBox $outputBox -ToolName "WindowsDefender" -NoTimestamp -SaveToDatabase
        }
        
        # Erfolgreichen Status setzen
        if ($restartedServices -eq $totalServices) {
            Write-ConsoleAndOutputBox -Message "Windows Defender-Dienste erfolgreich neu gestartet" -Type "Success" -OutputBox $outputBox -ToolName "WindowsDefender"
            Update-ProgressStatus -StatusText "Windows Defender-Dienste erfolgreich neu gestartet" -ProgressValue 100 -TextColor ([System.Drawing.Color]::LimeGreen) -progressBarParam $progressBar
        }
        elseif ($restartedServices -gt 0) {
            Write-ConsoleAndOutputBox -Message "$restartedServices von $totalServices Diensten neu gestartet" -Type "Warning" -OutputBox $outputBox -ToolName "WindowsDefender"
            Update-ProgressStatus -StatusText "$restartedServices von $totalServices Diensten neu gestartet" -ProgressValue 100 -TextColor ([System.Drawing.Color]::Yellow) -progressBarParam $progressBar
        }
        else {
            Write-ConsoleAndOutputBox -Message "Fehler beim Neustart der Dienste" -Type "Error" -OutputBox $outputBox -ToolName "WindowsDefender"
            Update-ProgressStatus -StatusText "Fehler beim Neustart der Dienste" -ProgressValue 0 -TextColor ([System.Drawing.Color]::Red) -progressBarParam $progressBar
        }    
    }
    catch {
        Write-ConsoleAndOutputBox -Message "Fehler beim Neustart der Defender-Dienste: $_" -Type "Error" -OutputBox $outputBox -ToolName "WindowsDefender" -NoTimestamp -SaveToDatabase
        
        Update-ProgressStatus -StatusText "Fehler" -ProgressValue 0 -TextColor ([System.Drawing.Color]::Red) -progressBarParam $progressBar
    }
}

# Funktion zum Starten des Windows Defender Offline-Scans
function Start-DefenderOfflineScan {
    param(
        [System.Windows.Forms.RichTextBox]$outputBox,
        [System.Windows.Forms.ProgressBar]$progressBar = $null,
        [System.Windows.Forms.Form]$MainForm = $null
    )
    
    # outputBox zurücksetzen
    $outputBox.Clear()
    
    # In Log-Datei und Datenbank schreiben, dass der Offline-Scan gestartet wird
    Write-ToolLog -ToolName "DefenderOfflineScan" -Message "Windows Defender Offline-Scan wird gestartet" -OutputBox $outputBox -Style 'Action' -Level "Information" -SaveToDatabase
    
    # PowerShell-Fenster aktivieren und Konsole leeren
    try {
        # Minimalen Code zur Aktivierung des Konsolenfensters verwenden
        $signature = @'
        [DllImport("user32.dll")]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool SetForegroundWindow(IntPtr hWnd);
        
        [DllImport("kernel32.dll")]
        public static extern IntPtr GetConsoleWindow();
'@
        try {
            $type = Add-Type -MemberDefinition $signature -Name "ConsoleFunctions" -Namespace "Win32Simple" -PassThru -ErrorAction SilentlyContinue
            $hwnd = $type::GetConsoleWindow()
            if ($hwnd -ne [IntPtr]::Zero) {
                [void]$type::SetForegroundWindow($hwnd)
            }
        }
        catch {
            # Ignorieren, falls nicht möglich
            Write-Host "Hinweis: Konnte PowerShell-Fenster nicht aktivieren. Die Vorbereitung läuft trotzdem."
        }
    }
    catch {
        # Ignorieren, falls nicht möglich
    }
    
    Clear-Host
    
    # Tab zur Ausgabe umschalten
    Switch-ToOutputTab
    
    # Rahmen und Systeminformationen erstellen
    $computerName = $env:COMPUTERNAME
    $userName = $env:USERNAME
    $osInfo = (Get-CimInstance -ClassName Win32_OperatingSystem).Caption
    $dateTime = Get-Date -Format "dd.MM.yyyy HH:mm:ss"
    $width = 80
    
    # Rahmen oben
    Write-Host "╔══════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-ColoredCenteredText                     "Windows Defender Offline-Scan"                                          
    Write-Host "╚══════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Green
    
    # ASCII-Art Logo

    Write-Host 
    Write-Host '      888       888 d8b                         8888888b.            .d888   '-ForegroundColor Cyan
    Write-Host '      888   o   888 Y8P                         888  "Y88b          d88P"    '-ForegroundColor Blue
    Write-Host '      888  d8b  888                             888    888          888      '-ForegroundColor Cyan
    Write-Host '      888 d888b 888 888 88888b.                 888    888  .d88b.  888888   '-ForegroundColor Blue
    Write-Host '      888d88888b888 888 888 "88b                888    888 d8P  Y8b 888      '-ForegroundColor Cyan
    Write-Host '      88888P Y88888 888 888  888     888888     888    888 88888888 888      '-ForegroundColor Blue
    Write-Host '      8888P   Y8888 888 888  888                888  .d88P Y8b.     888      '-ForegroundColor Cyan
    Write-Host '      888P     Y888 888 888  888                8888888P"   "Y8888  888      '-ForegroundColor Blue
    Write-Host
    Write-Host '                       .d888  .d888 888 d8b                                  ' -ForegroundColor Cyan
    Write-Host '                      d88P"  d88P"  888 Y8P                                  ' -ForegroundColor Blue
    Write-Host '                      888    888    888                                      ' -ForegroundColor Cyan
    Write-Host '              .d88b.  888888 888888 888 888 88888b.   .d88b.                 ' -ForegroundColor Blue
    Write-Host '             d88""88b 888    888    888 888 888 "88b d8P  Y8b                ' -ForegroundColor Cyan
    Write-Host '             888  888 888    888    888 888 888  888 88888888                ' -ForegroundColor Blue
    Write-Host '             Y88..88P 888    888    888 888 888  888 Y8b.                    ' -ForegroundColor Cyan
    Write-Host '              "Y88P"  888    888    888 888 888  888  "Y8888                 ' -ForegroundColor Blue
    Write-Host


    
    # Rahmen für Systeminformationen
    Write-Host "╔══════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-ColoredCenteredText                          "INFORMATIONEN"                                           
    Write-Host "╠══════════════════════════════════════════════════════════════════════════════╣" -ForegroundColor Green
    # Systeminformationen
    Write-Host "║                                                                              ║" -ForegroundColor Green
    Write-Host "  ├─  Tiefenscan mit Windows Defender Offline:                                  "  -ForegroundColor Yellow                 
    Write-Host "  ├─  Startet vor Windows, um hartnäckige Bedrohungen zu entfernen.             "  -ForegroundColor Yellow                                    
    Write-Host "  ├─  Ideal bei Verdacht auf versteckte oder nicht entfernbare Malware.         "  -ForegroundColor Yellow                                    
    Write-Host "  └─  Ein Neustart ist erforderlich – der Scan läuft außerhalb des Systems.     "  -ForegroundColor Yellow                                  
    Write-Host "║                                                                              ║" -ForegroundColor Green
    
    Write-Host "╠══════════════════════════════════════════════════════════════════════════════╣" -ForegroundColor Green
    Write-ColoredCenteredText "Windows Defender Offline-Scan wird vorbereitet..."
    Write-Host "╚══════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Green
    # Status in GUI aktualisieren
    Write-ToolLog -ToolName "DefenderOfflineScan" -Message "Windows Defender Offline-Scan wird vorbereitet..." -OutputBox $outputBox -Style 'Action' -Level "Information" -NoTimestamp -SaveToDatabase
    
    # Progress Bar aktualisieren
    Update-ProgressStatus -StatusText "Defender Offline-Scan wird vorbereitet..." -ProgressValue 10 -TextColor ([System.Drawing.Color]::White) -progressBarParam $progressBar
    # Wichtige Informationen anzeigen
    Write-ConsoleAndOutputBox -Message "WICHTIGE INFORMATIONEN" -Type "Warning" -OutputBox $outputBox -ToolName "DefenderOfflineScan" -NoTimestamp -SaveToDatabase
    Write-Host "Der Windows Defender Offline-Scan..." -ForegroundColor Cyan
    Write-Host " ├─ Benötigt einen Systemneustart" -ForegroundColor White
    Write-Host " ├─ Führt nach dem Neustart einen umfassenden Scan durch" -ForegroundColor White
    Write-Host " ├─ Kann bis zu einer Stunde oder länger dauern" -ForegroundColor White
    Write-Host " ├─ Alle nicht gespeicherten Daten gehen verloren" -ForegroundColor White
    Write-Host " └─ Bietet erhöhte Sicherheit gegen Rootkits und persistente Malware" -ForegroundColor White
    # Diese Informationen auch in der GUI anzeigen
    Write-ToolLog -ToolName "DefenderOfflineScan" -Message "WICHTIGE INFORMATIONEN:" -OutputBox $outputBox -Style 'Success' -Level "Warning" -NoTimestamp -SaveToDatabase
    Write-ToolLog -ToolName "DefenderOfflineScan" -Message "Der Windows Defender Offline-Scan..." -OutputBox $outputBox -Style 'Action' -Level "Information" -NoTimestamp -SaveToDatabase
    Write-ToolLog -ToolName "DefenderOfflineScan" -Message " - Benötigt einen Systemneustart" -OutputBox $outputBox -Level "Information" -NoTimestamp -SaveToDatabase
    Write-ToolLog -ToolName "DefenderOfflineScan" -Message " - Führt nach dem Neustart einen umfassenden Scan durch" -OutputBox $outputBox -Level "Information" -NoTimestamp -SaveToDatabase
    Write-ToolLog -ToolName "DefenderOfflineScan" -Message " - Kann bis zu einer Stunde oder länger dauern" -OutputBox $outputBox -Level "Information" -NoTimestamp -SaveToDatabase
    Write-ToolLog -ToolName "DefenderOfflineScan" -Message " - Alle nicht gespeicherten Daten gehen verloren" -OutputBox $outputBox -Level "Information" -NoTimestamp -SaveToDatabase
    Write-ToolLog -ToolName "DefenderOfflineScan" -Message " - Bietet erhöhte Sicherheit gegen Rootkits und persistente Malware" -OutputBox $outputBox -Level "Information" -NoTimestamp -SaveToDatabase
    
    Update-ProgressStatus -StatusText "Warte auf Benutzerbestätigung..." -ProgressValue 30 -TextColor ([System.Drawing.Color]::Blue) -progressBarParam $progressBar
    
    # Bestätigung vom Benutzer einholen
    $confirmMessage = "Sie möchten den Windows Defender Offline-Scan starten. `n`n" + 
    "Diese Aktion ERFORDERT EINEN NEUSTART des Systems.`n" +
    "Alle nicht gespeicherten Daten gehen verloren!`n`n" + 
    "Bitte speichern Sie wichtige Dokumente und schließen Sie alle Programme.`n`n" +
    "Möchten Sie fortfahren und den Offline-Scan starten?"
    
    $result = [System.Windows.Forms.MessageBox]::Show(
        $confirmMessage,
        "Windows Defender Offline-Scan",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Warning
    )
    
    if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
        try {
            # Update Fortschritt
            Update-ProgressStatus -StatusText "Konfiguriere Offline-Scan..." -ProgressValue 50 -TextColor ([System.Drawing.Color]::Blue) -progressBarParam $progressBar
            Write-ConsoleAndOutputBox -Message "Bereite Windows Defender Offline-Scan vor..." -Type "Start" -OutputBox $outputBox -ToolName "DefenderOfflineScan" -NoTimestamp -SaveToDatabase
            
            # Prüfe, welche Methode verfügbar ist
            $offlineScanConfigured = $false
            # Methode 1: Start-MpWDOScan cmdlet
            if (Get-Command Start-MpWDOScan -ErrorAction SilentlyContinue) {
                try {
                    Write-ConsoleAndOutputBox -Message "Konfiguriere Offline-Scan mit PowerShell-Cmdlet..." -Type "Info" -OutputBox $outputBox -ToolName "DefenderOfflineScan" -NoTimestamp -SaveToDatabase
                    Start-MpWDOScan
                    $offlineScanConfigured = $true
                    
                    Write-ConsoleAndOutputBox -Message "Offline-Scan wurde erfolgreich konfiguriert!" -Type "Success" -OutputBox $outputBox -ToolName "WindowsDefender" -NoTimestamp
                }
                catch {
                    Write-ConsoleAndOutputBox -Message "Fehler beim Konfigurieren des Offline-Scans mit PowerShell-Cmdlet: $_" -Type "Error" -OutputBox $outputBox -ToolName "WindowsDefender" -NoTimestamp
                }
            }
            
            # Methode 2: MpCmdRun.exe als Alternative
            if (-not $offlineScanConfigured) {
                try {
                    $mpCmdRunPath = "$env:ProgramFiles\Windows Defender\MpCmdRun.exe"
                    if (Test-Path $mpCmdRunPath) {
                        Write-ConsoleAndOutputBox -Message "Konfiguriere Offline-Scan mit MpCmdRun.exe..." -Type "Info" -OutputBox $outputBox -ToolName "WindowsDefender" -NoTimestamp
                        
                        # Führe MpCmdRun für offline-Scan aus
                        $process = Start-Process -FilePath $mpCmdRunPath -ArgumentList "-wdoscan" -NoNewWindow -PassThru -Wait
                        if ($process.ExitCode -eq 0) {
                            $offlineScanConfigured = $true
                            Write-ConsoleAndOutputBox -Message "Offline-Scan wurde erfolgreich konfiguriert!" -Type "Success" -OutputBox $outputBox -ToolName "WindowsDefender" -NoTimestamp
                        }
                        else {
                            Write-ConsoleAndOutputBox -Message "Fehler beim Konfigurieren des Offline-Scans mit MpCmdRun.exe. ExitCode: $($process.ExitCode)" -Type "Error" -OutputBox $outputBox -ToolName "WindowsDefender" -NoTimestamp
                        }
                    }
                    else {
                        Write-ConsoleAndOutputBox -Message "MpCmdRun.exe nicht gefunden unter $mpCmdRunPath" -Type "Error" -OutputBox $outputBox -ToolName "WindowsDefender" -NoTimestamp
                    }
                }
                catch {
                    Write-ConsoleAndOutputBox -Message "Fehler beim Konfigurieren des Offline-Scans mit MpCmdRun.exe: $_" -Type "Error" -OutputBox $outputBox -ToolName "WindowsDefender" -NoTimestamp
                }
            }
            # Methode 3: PowerShell-Befehl zum Neustart mit speziellen Parametern
            if (-not $offlineScanConfigured) {
                try {
                    Write-ConsoleAndOutputBox -Message "Verwende alternative Methode über WDOSCAN-Parameter..." -Type "Info" -OutputBox $outputBox -ToolName "WindowsDefender" -NoTimestamp
                    
                    # Offline-Scan über Shutdown-Befehl einleiten
                    # Der Parameter /fw erzwingt, dass Windows mit Windows Defender Offline gestartet wird
                    $process = Start-Process -FilePath "shutdown.exe" -ArgumentList "/r /t 60 /f /fw" -NoNewWindow -PassThru -Wait
                    if ($process.ExitCode -eq 0) {
                        $offlineScanConfigured = $true
                        Write-ConsoleAndOutputBox -Message "System wird in 60 Sekunden neu gestartet für den Offline-Scan!" -Type "Success" -OutputBox $outputBox -ToolName "WindowsDefender" -NoTimestamp
                    }
                    else {
                        Write-ConsoleAndOutputBox -Message "Fehler beim Konfigurieren des Neustarts. ExitCode: $($process.ExitCode)" -Type "Error" -OutputBox $outputBox -ToolName "WindowsDefender" -NoTimestamp
                    }
                }
                catch {
                    Write-ConsoleAndOutputBox -Message "Fehler beim Konfigurieren des Neustarts: $_" -Type "Error" -OutputBox $outputBox -ToolName "WindowsDefender" -NoTimestamp
                }
            }

            # Abschließende Nachricht basierend auf Status
            if ($offlineScanConfigured) {
                Update-ProgressStatus -StatusText "Windows Defender Offline-Scan wird nach dem Neustart ausgeführt" -ProgressValue 100 -TextColor ([System.Drawing.Color]::LimeGreen) -progressBarParam $progressBar
                
                # Information für den Benutzer
                $shutdownInfo = "Der Windows Defender Offline-Scan wurde konfiguriert.`n`n" + 
                "Das System wird in wenigen Sekunden neu gestartet.`n" +
                "Bitte schalten Sie den Computer während des Scans nicht aus.`n" +
                "Der Scan kann bis zu einer Stunde dauern."
                
                [System.Windows.Forms.MessageBox]::Show(
                    $shutdownInfo,
                    "Windows Defender Offline-Scan",
                    [System.Windows.Forms.MessageBoxButtons]::OK,
                    [System.Windows.Forms.MessageBoxIcon]::Information
                )
            }
            else {
                Update-ProgressStatus -StatusText "Fehler bei der Konfiguration des Offline-Scans" -ProgressValue 0 -TextColor ([System.Drawing.Color]::Red) -progressBarParam $progressBar
                
                # Fehlermeldung für den Benutzer
                [System.Windows.Forms.MessageBox]::Show(
                    "Der Windows Defender Offline-Scan konnte nicht konfiguriert werden.`n" +
                    "Bitte versuchen Sie es später erneut oder kontaktieren Sie den Support.",
                    "Windows Defender Offline-Scan",
                    [System.Windows.Forms.MessageBoxButtons]::OK,
                    [System.Windows.Forms.MessageBoxIcon]::Error
                )
            }        
        }
        catch {
            Write-ConsoleAndOutputBox -Message "Unerwarteter Fehler beim Konfigurieren des Offline-Scans: $_" -Type "Error" -OutputBox $outputBox -ToolName "DefenderOfflineScan" -NoTimestamp -SaveToDatabase
            
            Update-ProgressStatus -StatusText "Fehler" -ProgressValue 0 -TextColor ([System.Drawing.Color]::Red) -progressBarParam $progressBar
        }
    }
    else {
        # Benutzer hat abgebrochen
        Write-ConsoleAndOutputBox -Message "Vorgang wurde durch den Benutzer abgebrochen." -Type "Warning" -OutputBox $outputBox -ToolName "DefenderOfflineScan" -SaveToDatabase
        
        Update-ProgressStatus -StatusText "Abgebrochen" -ProgressValue 0 -TextColor ([System.Drawing.Color]::Blue) -progressBarParam $progressBar
    }
}

# Export functions
Export-ModuleMember -Function Start-WindowsDefender, Restart-DefenderService, Start-DefenderOfflineScan



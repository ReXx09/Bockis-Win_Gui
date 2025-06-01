# Import required modules
Import-Module "$PSScriptRoot\..\Core\Core.psm1" -Force
Import-Module "$PSScriptRoot\..\Core\ProgressBarTools.psm1" -Force

# Function to start Windows Defender and show status
function Start-WindowsDefender {
    param(
        [System.Windows.Forms.RichTextBox]$outputBox,
        [System.Windows.Forms.TabControl]$TabControl,
        [System.Windows.Forms.ProgressBar]$progressBar = $null,
        [System.Windows.Forms.Form]$MainForm = $null
    )
    
    # outputBox zurücksetzen
    $outputBox.Clear()
    
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
    $computerName = $env:COMPUTERNAME
    $userName = $env:USERNAME
    $osInfo = (Get-CimInstance -ClassName Win32_OperatingSystem).Caption
    $dateTime = Get-Date -Format "dd.MM.yyyy HH:mm:ss"
    $width = 80
    
    # Rahmen oben
    Write-Host "╔══════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-ColoredCenteredText                              "Windows Defender"                                          
    Write-Host "╚══════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Green
    
    # ASCII-Art Logo
    Write-Host
    Write-Host
    Write-Host '   888       888  d8b                 888                                                 ' -ForegroundColor Cyan
    Write-Host '   888   o   888  Y8P                 888                                                 ' -ForegroundColor Blue
    Write-Host '   888  d8b  888                      888                                                 ' -ForegroundColor Cyan
    Write-Host '   888 d888b 888  888  88888b.    .d88888   .d88b.   888  888  888  .d8888b               ' -ForegroundColor Blue
    Write-Host '   888d88888b888  888  888 "88b  d88" 888  d88""88b  888  888  888  88K                   ' -ForegroundColor Cyan
    Write-Host '   88888P Y88888  888  888  888  888  888  888  888  888  888  888  "Y8888b.              ' -ForegroundColor Blue    
    Write-Host '   8888P   Y8888  888  888  888  Y88b 888  Y88..88P  Y88b 888 d88P       X88              ' -ForegroundColor Cyan
    Write-Host '   888P     Y888  888  888  888   "Y88888   "Y88P"    "Y8888888P"    88888P               ' -ForegroundColor Blue
    Write-Host                                                                    
    Write-Host '   8888888b.            .d888                         888                                 ' -ForegroundColor Cyan
    Write-Host '   888  "Y88b          d88P"                          888                                 ' -ForegroundColor Blue
    Write-Host '   888    888          888                            888                                 ' -ForegroundColor Cyan
    Write-Host '   888    888  .d88b.  888888 .d88b.  88888b.    .d88888  .d88b.  888d888                ' -ForegroundColor Blue
    Write-Host '   888    888 d8P  Y8b 888   d8P  Y8b 888 "88b  d88" 888 d8P  Y8b 888P"                  ' -ForegroundColor Cyan
    Write-Host '   888    888 88888888 888   88888888 888  888  888  888 88888888 888                    ' -ForegroundColor Blue
    Write-Host '   888  .d88P Y8b.     888   Y8b.     888  888  Y88b 888 Y8b.     888                    ' -ForegroundColor Cyan
    Write-Host '   8888888P"   "Y8888  888    "Y8888  888  888   "Y88888  "Y8888  888                    ' -ForegroundColor Blue
    Write-Host
    
    # Rahmen für Systeminformationen
    Write-Host "╔══════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-ColoredCenteredText                          "SYSTEMINFORMATIONEN"                                           
    Write-Host "╠══════════════════════════════════════════════════════════════════════════════╣" -ForegroundColor Green
    # Systeminformationen
    Write-Host "║                                                                              ║" -ForegroundColor Green
    Write-Host "      ├─    Betriebssystem: $osInfo           "            -ForegroundColor Yellow                 
    Write-Host "      ├─    Computer:       $computerName     "            -ForegroundColor Yellow                                    
    Write-Host "      ├─    Benutzer:       $userName         "            -ForegroundColor Yellow                                    
    Write-Host "      └─    Datum und Zeit: $dateTime         "            -ForegroundColor Yellow                                  
    Write-Host "║                                                                              ║" -ForegroundColor Green
    
    Write-Host "╠══════════════════════════════════════════════════════════════════════════════╣" -ForegroundColor Green
    Write-ColoredCenteredText "Windows Defender wird initialisiert..."
    Write-Host "╚══════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Green
    
    # 2 Sekunden warten vor dem Start
    Start-Sleep -Seconds 2
    
    # Tab zur Ausgabe umschalten
    Switch-ToOutputTab -TabControl $TabControl
    
    # Hole die Konfiguration aus dem Core-Modul
    $config = Get-SystemToolConfig -ToolName "WindowsDefender"
    
    try {
        # Status aktualisieren
        Update-ProgressStatus -StatusText "Starte $($config.Description)..." -ProgressValue 0 -TextColor ([System.Drawing.Color]::DarkBlue) -progressBarParam $progressBar
        
        # Windows Defender starten
        Write-Host "`n[>] Starte Windows Defender und rufe Status ab..." -ForegroundColor Green
        
        # Status in GUI aktualisieren
        Write-ToolLog -ToolName "WindowsDefender" -Message "Starte Windows Defender und rufe Status ab..." -OutputBox $outputBox -Color ([System.Drawing.Color]::Blue) -NoTimestamp
        
        # Windows Defender öffnen - optional, kann entfernt werden wenn nur Konsole
        # Start-Process "windowsdefender://threat" -WindowStyle Hidden
        
        # Status abrufen und anzeigen
        $status = Get-MpComputerStatus
        
        Write-Host "`n[>] Aktueller Windows Defender Status:" -ForegroundColor Green
        Write-ToolLog -ToolName "WindowsDefender" -Message " [Aktueller Status:]" -OutputBox $outputBox -Color ([System.Drawing.Color]::Blue) -NoTimestamp

        Write-Host " - Antivirus: $($status.AntivirusEnabled)" -ForegroundColor Yellow
        Write-ToolLog -ToolName "WindowsDefender" -Message " - Antivirus: $($status.AntivirusEnabled)" -OutputBox $outputBox -NoTimestamp

        Write-Host " - Echtzeit-Schutz: $($status.RealTimeProtectionEnabled)" -ForegroundColor Yellow
        Write-ToolLog -ToolName "WindowsDefender" -Message " - Echtzeit-Schutz: $($status.RealTimeProtectionEnabled)" -OutputBox $outputBox -NoTimestamp

        Write-Host " - Virensignaturen: $($status.AntivirusSignatureVersion)" -ForegroundColor Yellow
        Write-ToolLog -ToolName "WindowsDefender" -Message " - Virensignaturen: $($status.AntivirusSignatureVersion)" -OutputBox $outputBox -NoTimestamp

        Write-Host " - Letztes Update: $($status.AntivirusSignatureLastUpdated)" -ForegroundColor Yellow
        Write-ToolLog -ToolName "WindowsDefender" -Message " - Letztes Update: $($status.AntivirusSignatureLastUpdated)" -OutputBox $outputBox -NoTimestamp

        # Verbesserte Darstellung des letzten Scans mit genaueren Zeitangaben
        if ($status.QuickScanEndTime) {
            $timeSinceScan = (Get-Date) - $status.QuickScanEndTime
            $scanTimeInfo = $status.QuickScanEndTime.ToString("dd.MM.yyyy HH:mm:ss")
            
            if ($timeSinceScan.TotalHours -lt 1) {
                $minutesSinceScan = [Math]::Round($timeSinceScan.TotalMinutes)
                Write-Host " - Letzter Scan: vor $minutesSinceScan Minuten ($scanTimeInfo)" -ForegroundColor Blue
                Write-ToolLog -ToolName "WindowsDefender" -Message " - Letzter Scan: vor $minutesSinceScan Minuten ($scanTimeInfo)" -OutputBox $outputBox -NoTimestamp
            }
            else {
                $hoursSinceScan = [Math]::Round($timeSinceScan.TotalHours, 1)
                Write-Host " - Letzter Scan: vor $hoursSinceScan Stunden ($scanTimeInfo)" -ForegroundColor Blue
                Write-ToolLog -ToolName "WindowsDefender" -Message " - Letzter Scan: vor $hoursSinceScan Stunden ($scanTimeInfo)" -OutputBox $outputBox -NoTimestamp
            }
        }
        else {
            Write-Host " - Letzter Scan: vor $($status.QuickScanAge) Stunden" -ForegroundColor Blue
            Write-ToolLog -ToolName "WindowsDefender" -Message " - Letzter Scan: vor $($status.QuickScanAge) Stunden" -OutputBox $outputBox -NoTimestamp
        }
        
        if (-not $status.AntivirusEnabled) {
            Write-Host "`n[!] WARNUNG: Windows Defender Antivirus ist nicht aktiv!" -ForegroundColor Red
            Write-ToolLog -ToolName "WindowsDefender" -Message "WARNUNG: Windows Defender Antivirus ist nicht aktiv!" -OutputBox $outputBox -Color ([System.Drawing.Color]::Red) -NoTimestamp
        }
        
        # Starte Quick Scan in der PowerShell
        Write-Host "`n[+] Starte Windows Defender Quick Scan..." -ForegroundColor Green
        Write-ToolLog -ToolName "WindowsDefender" -Message "Starte Windows Defender Quick Scan..." -OutputBox $outputBox -Color ([System.Drawing.Color]::Blue) -NoTimestamp
        
        Update-ProgressStatus -StatusText "Führe Quick Scan aus..." -ProgressValue 10 -TextColor ([System.Drawing.Color]::DarkBlue) -progressBarParam $progressBar
        
        # PowerShell-Befehl für den Quick Scan direkt ausführen statt als Job
        try {
            Write-Host "`n[>] Scan wird gestartet. Bitte warten... (Dies kann einige Minuten dauern)" -ForegroundColor Yellow
            
            # Direkte Ausführung des Scans mit Fortschrittsanzeige
            $scanProgress = 20
            Update-ProgressStatus -StatusText "Windows Defender Quick Scan läuft... $scanProgress%" -ProgressValue $scanProgress -TextColor ([System.Drawing.Color]::DarkBlue) -progressBarParam $progressBar
            
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
                Write-Host "`n[>] Führe QuickScan mit Start-MpScan aus..." -ForegroundColor Yellow
                
                # Animationszeichen für Fortschritt
                $progressChars = @('|', '/', '-', '\')
                $progressIndex = 0
                $startTime = Get-Date
                
                # Scan im Hintergrund starten
                $scanJob = Start-Job -ScriptBlock {
                    Start-MpScan -ScanType QuickScan
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
                    Update-ProgressStatus -StatusText "Windows Defender Quick Scan läuft... $scanProgress%" -ProgressValue $scanProgress -TextColor ([System.Drawing.Color]::DarkBlue) -progressBarParam $progressBar
                    
                    Start-Sleep -Milliseconds 500
                }
                
                Write-Host ""  # Neue Zeile nach Animation
                
                # Ergebnis abholen
                $scanResult = Receive-Job -Job $scanJob
                Remove-Job -Job $scanJob -Force
                
                Write-Host "`n[+] Windows Defender Quick Scan abgeschlossen." -ForegroundColor Green
                Write-ToolLog -ToolName "WindowsDefender" -Message "Windows Defender Quick Scan abgeschlossen." -OutputBox $outputBox -Color ([System.Drawing.Color]::Green) -NoTimestamp
            } 
            else {
                # Alternativer Ansatz mit MpCmdRun
                Write-Host "`n[>] Start-MpScan nicht verfügbar, verwende MpCmdRun.exe als Alternative..." -ForegroundColor Yellow
                
                $mpCmdRunPath = "$env:ProgramFiles\Windows Defender\MpCmdRun.exe"
                if (Test-Path $mpCmdRunPath) {
                    Write-Host "`n[>] MpCmdRun.exe gefunden, starte QuickScan..." -ForegroundColor Yellow
                    
                    # Führe MpCmdRun mit Quick Scan aus
                    $process = Start-Process -FilePath $mpCmdRunPath -ArgumentList "-Scan -ScanType 1" -NoNewWindow -PassThru
                    
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
                        Update-ProgressStatus -StatusText "Windows Defender Quick Scan läuft... $scanProgress%" -ProgressValue $scanProgress -TextColor ([System.Drawing.Color]::DarkBlue) -progressBarParam $progressBar
                        
                        Start-Sleep -Milliseconds 500
                        
                        # Prüfe nach kurzer Zeit wieder den Status
                        $process.Refresh()
                    }
                    
                    Write-Host ""  # Neue Zeile nach Animation
                    
                    if ($process.ExitCode -eq 0) {
                        Write-Host "`n[+] Windows Defender Quick Scan (MpCmdRun) abgeschlossen." -ForegroundColor Green
                        Write-ToolLog -ToolName "WindowsDefender" -Message "Windows Defender Quick Scan (MpCmdRun) abgeschlossen." -OutputBox $outputBox -Color ([System.Drawing.Color]::Green) -NoTimestamp
                    }
                    else {
                        Write-Host "`n[!] Fehler beim Windows Defender Scan. ExitCode: $($process.ExitCode)" -ForegroundColor Red
                        Write-ToolLog -ToolName "WindowsDefender" -Message "Fehler beim Windows Defender Scan (MpCmdRun). ExitCode: $($process.ExitCode)" -OutputBox $outputBox -Color ([System.Drawing.Color]::Red) -NoTimestamp
                    }
                }
                else {
                    Write-Host "`n[!] Weder Start-MpScan noch MpCmdRun.exe konnten gefunden werden." -ForegroundColor Red
                    Write-ToolLog -ToolName "WindowsDefender" -Message "Weder Start-MpScan noch MpCmdRun.exe konnten gefunden werden." -OutputBox $outputBox -Color ([System.Drawing.Color]::Red) -NoTimestamp
                }
            }
            
            # Nach dem Scan den Bedrohungsstatus prüfen
            Write-Host "`n[>] Prüfe auf Bedrohungen..." -ForegroundColor Cyan
            Write-ToolLog -ToolName "WindowsDefender" -Message "Prüfe auf Bedrohungen..." -OutputBox $outputBox -NoTimestamp
            
            $threats = $null
            try {
                # Versuche, Bedrohungen zu erhalten
                if (Get-Command Get-MpThreatDetection -ErrorAction SilentlyContinue) {
                    $threats = Get-MpThreatDetection | Where-Object { $_.ThreatStatus -ne "Resolved" }
                }
                
                if ($threats -and $threats.Count -gt 0) {
                    $threatCount = $threats.Count
                    Write-Host "`n[!] $threatCount Bedrohung(en) gefunden!" -ForegroundColor Red
                    Write-ToolLog -ToolName "WindowsDefender" -Message "$threatCount Bedrohung(en) gefunden!" -OutputBox $outputBox -Color ([System.Drawing.Color]::Red) -NoTimestamp
                    
                    # Liste alle Bedrohungen auf
                    foreach ($threat in $threats) {
                        Write-Host "    - $($threat.ThreatName) ($($threat.ThreatID))" -ForegroundColor Red
                        Write-ToolLog -ToolName "WindowsDefender" -Message "- $($threat.ThreatName) ($($threat.ThreatID))" -OutputBox $outputBox -Color ([System.Drawing.Color]::Red) -NoTimestamp
                    }
                }
                else {
                    Write-Host "`n[√] Keine Bedrohungen gefunden." -ForegroundColor Green
                    Write-ToolLog -ToolName "WindowsDefender" -Message "Keine Bedrohungen gefunden." -OutputBox $outputBox -Color ([System.Drawing.Color]::Green) -NoTimestamp
                }
            }
            catch {
                Write-Host "`n[!] Fehler beim Abrufen von Bedrohungsinformationen: $_" -ForegroundColor Yellow
                Write-ToolLog -ToolName "WindowsDefender" -Message "Fehler beim Abrufen von Bedrohungsinformationen." -OutputBox $outputBox -Color ([System.Drawing.Color]::Yellow) -NoTimestamp
            }
        }
        catch {
            Write-Host "`n[!] Fehler beim Ausführen des Windows Defender Scans: $_" -ForegroundColor Red
            Write-ToolLog -ToolName "WindowsDefender" -Message "Fehler beim Ausführen des Windows Defender Scans: $_" -OutputBox $outputBox -Color ([System.Drawing.Color]::Red) -NoTimestamp
        }
        
        # Erfolgreichen Status setzen
        Update-ProgressStatus -StatusText "Windows Defender Scan abgeschlossen" -ProgressValue 100 -TextColor ([System.Drawing.Color]::Green) -progressBarParam $progressBar
    }
    catch {
        Write-Host "`n[!] Fehler beim Ausführen des Windows Defender Scans: $_" -ForegroundColor Red
        Write-ToolLog -ToolName "WindowsDefender" -Message "Fehler beim Ausführen des Windows Defender Scans: $_" -OutputBox $outputBox -Color ([System.Drawing.Color]::Red) -NoTimestamp
        Update-ProgressStatus -StatusText "Fehler" -ProgressValue 0 -TextColor ([System.Drawing.Color]::Red) -progressBarParam $progressBar
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
        [System.Windows.Forms.TabControl]$TabControl,
        [System.Windows.Forms.ProgressBar]$progressBar = $null,
        [System.Windows.Forms.Form]$MainForm = $null
    )
    
    Switch-ToOutputTab -TabControl $TabControl
    
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
        Update-ProgressStatus -StatusText "Starte Windows Defender-Dienst neu..." -ProgressValue 0 -TextColor ([System.Drawing.Color]::DarkBlue) -progressBarParam $progressBar
        
        # Relevante Dienste
        $defenderServices = @(
            "WinDefend", # Windows Defender-Dienst
            "WdNisSvc", # Network Inspection Service
            "Sense", # Windows Defender Advanced Threat Protection Service
            "SecurityHealthService" # Windows Security Health Service
        )
        
        $restartedServices = 0
        $totalServices = $defenderServices.Count
        
        Write-Host "`n[+] Starte Neustart der Windows Defender-Dienste..." -ForegroundColor Green
        Write-ToolLog -ToolName "WindowsDefender" -Message "Starte Neustart der Windows Defender-Dienste..." -OutputBox $outputBox -Color ([System.Drawing.Color]::Blue) -NoTimestamp
        
        foreach ($service in $defenderServices) {
            try {
                # Prüfen, ob der Dienst existiert
                $svc = Get-Service -Name $service -ErrorAction SilentlyContinue
                
                if ($svc) {
                    Write-Host "`n[>] Dienst: $service" -ForegroundColor Yellow
                    Write-ToolLog -ToolName "WindowsDefender" -Message "Dienst: $service" -OutputBox $outputBox -NoTimestamp
                    
                    # Dienst stoppen
                    Write-Host "    - Stoppe Dienst..." -ForegroundColor Cyan
                    Write-ToolLog -ToolName "WindowsDefender" -Message "  - Stoppe Dienst..." -OutputBox $outputBox -NoTimestamp
                    
                    Stop-Service -Name $service -Force -ErrorAction SilentlyContinue
                    Start-Sleep -Seconds 2
                    
                    # Dienst starten
                    Write-Host "    - Starte Dienst..." -ForegroundColor Cyan
                    Write-ToolLog -ToolName "WindowsDefender" -Message "  - Starte Dienst..." -OutputBox $outputBox -NoTimestamp
                    
                    Start-Service -Name $service -ErrorAction SilentlyContinue
                    
                    # Status des Dienstes prüfen
                    $svcStatus = (Get-Service -Name $service).Status
                    
                    if ($svcStatus -eq "Running") {
                        Write-Host "    - Status: $svcStatus ✓" -ForegroundColor Green
                        Write-ToolLog -ToolName "WindowsDefender" -Message "  - Status: $svcStatus" -OutputBox $outputBox -Color ([System.Drawing.Color]::Green) -NoTimestamp
                        $restartedServices++
                    } 
                    else {
                        Write-Host "    - Status: $svcStatus ✗" -ForegroundColor Red
                        Write-ToolLog -ToolName "WindowsDefender" -Message "  - Status: $svcStatus" -OutputBox $outputBox -Color ([System.Drawing.Color]::Red) -NoTimestamp
                    }
                } 
                else {
                    Write-Host "`n[!] Dienst $service nicht gefunden." -ForegroundColor Yellow
                    Write-ToolLog -ToolName "WindowsDefender" -Message "Dienst $service nicht gefunden." -OutputBox $outputBox -Color ([System.Drawing.Color]::Yellow) -NoTimestamp
                }
            }
            catch {
                Write-Host "`n[!] Fehler beim Neustart des Dienstes $service - Fehlermeldung: $_" -ForegroundColor Red
                Write-ToolLog -ToolName "WindowsDefender" -Message "Fehler beim Neustart des Dienstes $service - Fehlermeldung: $_" -OutputBox $outputBox -Color ([System.Drawing.Color]::Red) -NoTimestamp
            }
            
            # Fortschritt aktualisieren
            if ($progressBar) {
                $progressValue = [Math]::Round(($restartedServices / $totalServices) * 100)
                $statusMessage = "Dienste werden neu gestartet... " + $progressValue + "%"
                Update-ProgressStatus -StatusText $statusMessage -ProgressValue $progressValue -TextColor ([System.Drawing.Color]::Blue) -progressBarParam $progressBar
            }
        }
        
        # MpCmdRun.exe zur Aktualisierung der Signaturen ausführen
        Write-Host "`n[+] Aktualisiere Defender-Signaturen..." -ForegroundColor Green
        Write-ToolLog -ToolName "WindowsDefender" -Message "Aktualisiere Defender-Signaturen..." -OutputBox $outputBox -NoTimestamp
        
        $mpCmdRunPath = "$env:ProgramFiles\Windows Defender\MpCmdRun.exe"
        if (Test-Path $mpCmdRunPath) {
            Write-Host "    - Starte Update-Prozess..." -ForegroundColor Cyan
            Start-Process -FilePath $mpCmdRunPath -ArgumentList "-SignatureUpdate" -NoNewWindow -Wait
            
            Write-Host "    - Signatur-Update abgeschlossen ✓" -ForegroundColor Green
            Write-ToolLog -ToolName "WindowsDefender" -Message "  - Signatur-Update abgeschlossen." -OutputBox $outputBox -Color ([System.Drawing.Color]::Green) -NoTimestamp
        }
        else {
            Write-Host "    - MpCmdRun.exe nicht gefunden. Signatur-Update übersprungen ✗" -ForegroundColor Yellow
            Write-ToolLog -ToolName "WindowsDefender" -Message "MpCmdRun.exe nicht gefunden. Signatur-Update übersprungen." -OutputBox $outputBox -Color ([System.Drawing.Color]::Yellow) -NoTimestamp
        }
        
        # Status abrufen und anzeigen
        $status = Get-MpComputerStatus
        Write-Host "`n[+] Aktueller Status nach Neustart:" -ForegroundColor Green
        Write-ToolLog -ToolName "WindowsDefender" -Message "Aktueller Status nach Neustart:" -OutputBox $outputBox -Color ([System.Drawing.Color]::Blue) -NoTimestamp
        
        Write-Host "    - Antivirus: $($status.AntivirusEnabled)" -ForegroundColor Yellow
        Write-ToolLog -ToolName "WindowsDefender" -Message "- Antivirus: $($status.AntivirusEnabled)" -OutputBox $outputBox -NoTimestamp
        
        Write-Host "    - Echtzeit-Schutz: $($status.RealTimeProtectionEnabled)" -ForegroundColor Yellow
        Write-ToolLog -ToolName "WindowsDefender" -Message "- Echtzeit-Schutz: $($status.RealTimeProtectionEnabled)" -OutputBox $outputBox -NoTimestamp
        
        # Zusätzliche detaillierte Status-Informationen
        Write-Host "    - Virensignaturen: $($status.AntivirusSignatureVersion)" -ForegroundColor Yellow
        Write-ToolLog -ToolName "WindowsDefender" -Message "- Virensignaturen: $($status.AntivirusSignatureVersion)" -OutputBox $outputBox -NoTimestamp
        
        Write-Host "    - Letztes Update: $($status.AntivirusSignatureLastUpdated)" -ForegroundColor Yellow
        Write-ToolLog -ToolName "WindowsDefender" -Message "- Letztes Update: $($status.AntivirusSignatureLastUpdated)" -OutputBox $outputBox -NoTimestamp
        
        # Verbesserte Darstellung des letzten Scans mit genaueren Zeitangaben
        if ($status.QuickScanEndTime) {
            $timeSinceScan = (Get-Date) - $status.QuickScanEndTime
            $scanTimeInfo = $status.QuickScanEndTime.ToString("dd.MM.yyyy HH:mm:ss")
            
            if ($timeSinceScan.TotalHours -lt 1) {
                $minutesSinceScan = [Math]::Round($timeSinceScan.TotalMinutes)
                Write-Host "    - Letzter Scan: vor $minutesSinceScan Minuten ($scanTimeInfo)" -ForegroundColor Cyan
                Write-ToolLog -ToolName "WindowsDefender" -Message "- Letzter Scan: vor $minutesSinceScan Minuten ($scanTimeInfo)" -OutputBox $outputBox -NoTimestamp
            }
            else {
                $hoursSinceScan = [Math]::Round($timeSinceScan.TotalHours, 1)
                Write-Host "    - Letzter Scan: vor $hoursSinceScan Stunden ($scanTimeInfo)" -ForegroundColor Cyan
                Write-ToolLog -ToolName "WindowsDefender" -Message "- Letzter Scan: vor $hoursSinceScan Stunden ($scanTimeInfo)" -OutputBox $outputBox -NoTimestamp
            }
        }
        else {
            Write-Host "    - Letzter Scan: vor $($status.QuickScanAge) Stunden" -ForegroundColor Cyan
            Write-ToolLog -ToolName "WindowsDefender" -Message "- Letzter Scan: vor $($status.QuickScanAge) Stunden" -OutputBox $outputBox -NoTimestamp
        }
        
        if (-not $status.AntivirusEnabled) {
            Write-Host "`n[!] WARNUNG: Windows Defender Antivirus ist nicht aktiv!" -ForegroundColor Red
            Write-ToolLog -ToolName "WindowsDefender" -Message "WARNUNG: Windows Defender Antivirus ist nicht aktiv!" -OutputBox $outputBox -Color ([System.Drawing.Color]::Red) -NoTimestamp
        }
        
        # Erfolgreichen Status setzen
        if ($restartedServices -eq $totalServices) {
            Write-Host "`n[✓] Windows Defender-Dienste erfolgreich neu gestartet" -ForegroundColor Green
            Update-ProgressStatus -StatusText "Windows Defender-Dienste erfolgreich neu gestartet" -ProgressValue 100 -TextColor ([System.Drawing.Color]::Green) -progressBarParam $progressBar
        }
        elseif ($restartedServices -gt 0) {
            Write-Host "`n[!] $restartedServices von $totalServices Diensten neu gestartet" -ForegroundColor Yellow
            Update-ProgressStatus -StatusText "$restartedServices von $totalServices Diensten neu gestartet" -ProgressValue 100 -TextColor ([System.Drawing.Color]::Yellow) -progressBarParam $progressBar
        }
        else {
            Write-Host "`n[✗] Fehler beim Neustart der Dienste" -ForegroundColor Red
            Update-ProgressStatus -StatusText "Fehler beim Neustart der Dienste" -ProgressValue 0 -TextColor ([System.Drawing.Color]::Red) -progressBarParam $progressBar
        }
    }
    catch {
        Write-Host "`n[✗] Fehler beim Neustart der Defender-Dienste: $_" -ForegroundColor Red
        Write-ToolLog -ToolName "WindowsDefender" -Message "Fehler beim Neustart der Defender-Dienste - Fehlermeldung: $_" -OutputBox $outputBox -Color ([System.Drawing.Color]::Red) -NoTimestamp
        
        Update-ProgressStatus -StatusText "Fehler" -ProgressValue 0 -TextColor ([System.Drawing.Color]::Red) -progressBarParam $progressBar
    }
}

# Funktion zum Starten des Windows Defender Offline-Scans
function Start-DefenderOfflineScan {
    param(
        [System.Windows.Forms.RichTextBox]$outputBox,
        [System.Windows.Forms.TabControl]$TabControl,
        [System.Windows.Forms.ProgressBar]$progressBar = $null,
        [System.Windows.Forms.Form]$MainForm = $null
    )
    
    # outputBox zurücksetzen
    $outputBox.Clear()
    
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
    Switch-ToOutputTab -TabControl $TabControl
    
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
    Write-Host '   888       888  d8b                 888                                                 ' -ForegroundColor Cyan
    Write-Host '   888   o   888  Y8P                 888                                                 ' -ForegroundColor Blue
    Write-Host '   888  d8b  888                      888                                                 ' -ForegroundColor Cyan
    Write-Host '   888 d888b 888  888  88888b.    .d88888   .d88b.   888  888  888  .d8888b               ' -ForegroundColor Blue
    Write-Host '   888d88888b888  888  888 "88b  d88" 888  d88""88b  888  888  888  88K                   ' -ForegroundColor Cyan
    Write-Host '   88888P Y88888  888  888  888  888  888  888  888  888  888  888  "Y8888b.              ' -ForegroundColor Blue    
    Write-Host '   8888P   Y8888  888  888  888  Y88b 888  Y88..88P  Y88b 888 d88P       X88              ' -ForegroundColor Cyan
    Write-Host '   888P     Y888  888  888  888   "Y88888   "Y88P"    "Y8888888P"    88888P               ' -ForegroundColor Blue
    Write-Host                                                                    
    Write-Host '   8888888b.            .d888                         888                                 ' -ForegroundColor Cyan
    Write-Host '   888  "Y88b          d88P"                          888                                 ' -ForegroundColor Blue
    Write-Host '   888    888          888                            888                                 ' -ForegroundColor Cyan
    Write-Host '   888    888  .d88b.  888888 .d88b.  88888b.    .d88888  .d88b.  888d888                ' -ForegroundColor Blue
    Write-Host '   888    888 d8P  Y8b 888   d8P  Y8b 888 "88b  d88" 888 d8P  Y8b 888P"                  ' -ForegroundColor Cyan
    Write-Host '   888    888 88888888 888   88888888 888  888  888  888 88888888 888                    ' -ForegroundColor Blue
    Write-Host '   888  .d88P Y8b.     888   Y8b.     888  888  Y88b 888 Y8b.     888                    ' -ForegroundColor Cyan
    Write-Host '   8888888P"   "Y8888  888    "Y8888  888  888   "Y88888  "Y8888  888                    ' -ForegroundColor Blue
    Write-Host '                                                                                          ' -ForegroundColor Cyan
    Write-Host '   .d88888b.  .d888d888d888 d8888 8888b.   .d888 8888b.   .d88b.   .d88b.   .d88b.       ' -ForegroundColor Blue
    Write-Host '  d88P" "Y88bd8888888P"888 d8P"      "88b d88P"    "88b d88""88b d88""88b d8P  Y8b      ' -ForegroundColor Cyan
    Write-Host '  888     888888  888  888 88888  .d888888888      888 888  888 888  888 88888888      ' -ForegroundColor Blue
    Write-Host '  888     888888  888  888 88888  888  888888      888 Y88..88P Y88..88P Y8b.          ' -ForegroundColor Cyan
    Write-Host '  "Y8888888P"888  888  888 8888   "Y88888888      888  "Y88P"   "Y88P"   "Y8888       ' -ForegroundColor Blue
    Write-Host
    
    # Rahmen für Systeminformationen
    Write-Host "╔══════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-ColoredCenteredText                          "SYSTEMINFORMATIONEN"                                           
    Write-Host "╠══════════════════════════════════════════════════════════════════════════════╣" -ForegroundColor Green
    # Systeminformationen
    Write-Host "║                                                                              ║" -ForegroundColor Green
    Write-Host "      ├─    Betriebssystem: $osInfo           "            -ForegroundColor Yellow                 
    Write-Host "      ├─    Computer:       $computerName     "            -ForegroundColor Yellow                                    
    Write-Host "      ├─    Benutzer:       $userName         "            -ForegroundColor Yellow                                    
    Write-Host "      └─    Datum und Zeit: $dateTime         "            -ForegroundColor Yellow                                  
    Write-Host "║                                                                              ║" -ForegroundColor Green
    
    Write-Host "╠══════════════════════════════════════════════════════════════════════════════╣" -ForegroundColor Green
    Write-ColoredCenteredText "Windows Defender Offline-Scan wird vorbereitet..."
    Write-Host "╚══════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Green
    
    # Status in GUI aktualisieren
    Write-ToolLog -ToolName "WindowsDefender" -Message "Windows Defender Offline-Scan wird vorbereitet..." -OutputBox $outputBox -Color ([System.Drawing.Color]::Blue) -NoTimestamp
    
    # Progress Bar aktualisieren
    Update-ProgressStatus -StatusText "Defender Offline-Scan wird vorbereitet..." -ProgressValue 10 -TextColor ([System.Drawing.Color]::DarkBlue) -progressBarParam $progressBar
    
    # Wichtige Informationen anzeigen
    Write-Host "`n[!] WICHTIGE INFORMATIONEN" -ForegroundColor Yellow
    Write-Host "Der Windows Defender Offline-Scan..." -ForegroundColor Cyan
    Write-Host " ├─ Benötigt einen Systemneustart" -ForegroundColor White
    Write-Host " ├─ Führt nach dem Neustart einen umfassenden Scan durch" -ForegroundColor White
    Write-Host " ├─ Kann bis zu einer Stunde oder länger dauern" -ForegroundColor White
    Write-Host " ├─ Alle nicht gespeicherten Daten gehen verloren" -ForegroundColor White
    Write-Host " └─ Bietet erhöhte Sicherheit gegen Rootkits und persistente Malware" -ForegroundColor White
    
    # Diese Informationen auch in der GUI anzeigen
    Write-ToolLog -ToolName "WindowsDefender" -Message "WICHTIGE INFORMATIONEN:" -OutputBox $outputBox -Color ([System.Drawing.Color]::Yellow) -NoTimestamp
    Write-ToolLog -ToolName "WindowsDefender" -Message "Der Windows Defender Offline-Scan..." -OutputBox $outputBox -Color ([System.Drawing.Color]::Blue) -NoTimestamp
    Write-ToolLog -ToolName "WindowsDefender" -Message " - Benötigt einen Systemneustart" -OutputBox $outputBox -NoTimestamp
    Write-ToolLog -ToolName "WindowsDefender" -Message " - Führt nach dem Neustart einen umfassenden Scan durch" -OutputBox $outputBox -NoTimestamp
    Write-ToolLog -ToolName "WindowsDefender" -Message " - Kann bis zu einer Stunde oder länger dauern" -OutputBox $outputBox -NoTimestamp
    Write-ToolLog -ToolName "WindowsDefender" -Message " - Alle nicht gespeicherten Daten gehen verloren" -OutputBox $outputBox -NoTimestamp
    Write-ToolLog -ToolName "WindowsDefender" -Message " - Bietet erhöhte Sicherheit gegen Rootkits und persistente Malware" -OutputBox $outputBox -NoTimestamp
    
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
            
            Write-Host "`n[+] Bereite Windows Defender Offline-Scan vor..." -ForegroundColor Green
            Write-ToolLog -ToolName "WindowsDefender" -Message "Bereite Windows Defender Offline-Scan vor..." -OutputBox $outputBox -Color ([System.Drawing.Color]::Green) -NoTimestamp
            
            # Prüfe, welche Methode verfügbar ist
            $offlineScanConfigured = $false
            
            # Methode 1: Start-MpWDOScan cmdlet
            if (Get-Command Start-MpWDOScan -ErrorAction SilentlyContinue) {
                try {
                    Write-Host "`n[>] Konfiguriere Offline-Scan mit PowerShell-Cmdlet..." -ForegroundColor Yellow
                    Write-ToolLog -ToolName "WindowsDefender" -Message "Konfiguriere Offline-Scan mit PowerShell-Cmdlet..." -OutputBox $outputBox -NoTimestamp
                    
                    Start-MpWDOScan
                    $offlineScanConfigured = $true
                    
                    Write-Host "`n[+] Offline-Scan wurde erfolgreich konfiguriert!" -ForegroundColor Green
                    Write-ToolLog -ToolName "WindowsDefender" -Message "Offline-Scan wurde erfolgreich konfiguriert!" -OutputBox $outputBox -Color ([System.Drawing.Color]::Green) -NoTimestamp
                }
                catch {
                    Write-Host "`n[!] Fehler beim Konfigurieren des Offline-Scans mit PowerShell-Cmdlet: $_" -ForegroundColor Red
                    Write-ToolLog -ToolName "WindowsDefender" -Message "Fehler beim Konfigurieren des Offline-Scans mit PowerShell-Cmdlet: $_" -OutputBox $outputBox -Color ([System.Drawing.Color]::Red) -NoTimestamp
                }
            }
            
            # Methode 2: MpCmdRun.exe als Alternative
            if (-not $offlineScanConfigured) {
                try {
                    $mpCmdRunPath = "$env:ProgramFiles\Windows Defender\MpCmdRun.exe"
                    if (Test-Path $mpCmdRunPath) {
                        Write-Host "`n[>] Konfiguriere Offline-Scan mit MpCmdRun.exe..." -ForegroundColor Yellow
                        Write-ToolLog -ToolName "WindowsDefender" -Message "Konfiguriere Offline-Scan mit MpCmdRun.exe..." -OutputBox $outputBox -NoTimestamp
                        
                        # Führe MpCmdRun für offline-Scan aus
                        $process = Start-Process -FilePath $mpCmdRunPath -ArgumentList "-wdoscan" -NoNewWindow -PassThru -Wait
                        
                        if ($process.ExitCode -eq 0) {
                            $offlineScanConfigured = $true
                            Write-Host "`n[+] Offline-Scan wurde erfolgreich konfiguriert!" -ForegroundColor Green
                            Write-ToolLog -ToolName "WindowsDefender" -Message "Offline-Scan wurde erfolgreich konfiguriert!" -OutputBox $outputBox -Color ([System.Drawing.Color]::Green) -NoTimestamp
                        }
                        else {
                            Write-Host "`n[!] Fehler beim Konfigurieren des Offline-Scans mit MpCmdRun.exe. ExitCode: $($process.ExitCode)" -ForegroundColor Red
                            Write-ToolLog -ToolName "WindowsDefender" -Message "Fehler beim Konfigurieren des Offline-Scans mit MpCmdRun.exe. ExitCode: $($process.ExitCode)" -OutputBox $outputBox -Color ([System.Drawing.Color]::Red) -NoTimestamp
                        }
                    }
                    else {
                        Write-Host "`n[!] MpCmdRun.exe nicht gefunden unter $mpCmdRunPath" -ForegroundColor Red
                        Write-ToolLog -ToolName "WindowsDefender" -Message "MpCmdRun.exe nicht gefunden unter $mpCmdRunPath" -OutputBox $outputBox -Color ([System.Drawing.Color]::Red) -NoTimestamp
                    }
                }
                catch {
                    Write-Host "`n[!] Fehler beim Konfigurieren des Offline-Scans mit MpCmdRun.exe: $_" -ForegroundColor Red
                    Write-ToolLog -ToolName "WindowsDefender" -Message "Fehler beim Konfigurieren des Offline-Scans mit MpCmdRun.exe: $_" -OutputBox $outputBox -Color ([System.Drawing.Color]::Red) -NoTimestamp
                }
            }
            
            # Methode 3: PowerShell-Befehl zum Neustart mit speziellen Parametern
            if (-not $offlineScanConfigured) {
                try {
                    Write-Host "`n[>] Verwende alternative Methode über WDOSCAN-Parameter..." -ForegroundColor Yellow
                    Write-ToolLog -ToolName "WindowsDefender" -Message "Verwende alternative Methode über WDOSCAN-Parameter..." -OutputBox $outputBox -NoTimestamp
                    
                    # Offline-Scan über Shutdown-Befehl einleiten
                    # Der Parameter /fw erzwingt, dass Windows mit Windows Defender Offline gestartet wird
                    $process = Start-Process -FilePath "shutdown.exe" -ArgumentList "/r /t 60 /f /fw" -NoNewWindow -PassThru -Wait
                    
                    if ($process.ExitCode -eq 0) {
                        $offlineScanConfigured = $true
                        Write-Host "`n[+] System wird in 60 Sekunden neu gestartet für den Offline-Scan!" -ForegroundColor Green
                        Write-ToolLog -ToolName "WindowsDefender" -Message "System wird in 60 Sekunden neu gestartet für den Offline-Scan!" -OutputBox $outputBox -Color ([System.Drawing.Color]::Green) -NoTimestamp
                    }
                    else {
                        Write-Host "`n[!] Fehler beim Konfigurieren des Neustarts. ExitCode: $($process.ExitCode)" -ForegroundColor Red
                        Write-ToolLog -ToolName "WindowsDefender" -Message "Fehler beim Konfigurieren des Neustarts. ExitCode: $($process.ExitCode)" -OutputBox $outputBox -Color ([System.Drawing.Color]::Red) -NoTimestamp
                    }
                }
                catch {
                    Write-Host "`n[!] Fehler beim Konfigurieren des Neustarts: $_" -ForegroundColor Red
                    Write-ToolLog -ToolName "WindowsDefender" -Message "Fehler beim Konfigurieren des Neustarts: $_" -OutputBox $outputBox -Color ([System.Drawing.Color]::Red) -NoTimestamp
                }
            }

            # Abschließende Nachricht basierend auf Status
            if ($offlineScanConfigured) {
                Update-ProgressStatus -StatusText "Windows Defender Offline-Scan wird nach dem Neustart ausgeführt" -ProgressValue 100 -TextColor ([System.Drawing.Color]::Green) -progressBarParam $progressBar
                
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
            Write-Host "`n[!] Unerwarteter Fehler beim Konfigurieren des Offline-Scans: $_" -ForegroundColor Red
            Write-ToolLog -ToolName "WindowsDefender" -Message "Unerwarteter Fehler beim Konfigurieren des Offline-Scans: $_" -OutputBox $outputBox -Color ([System.Drawing.Color]::Red) -NoTimestamp
            
            Update-ProgressStatus -StatusText "Fehler" -ProgressValue 0 -TextColor ([System.Drawing.Color]::Red) -progressBarParam $progressBar
        }
    }
    else {
        # Benutzer hat abgebrochen
        Write-Host "`n[i] Vorgang wurde durch den Benutzer abgebrochen." -ForegroundColor Yellow
        Write-ToolLog -ToolName "WindowsDefender" -Message "Vorgang wurde durch den Benutzer abgebrochen." -OutputBox $outputBox -Color ([System.Drawing.Color]::Yellow) -NoTimestamp
        
        Update-ProgressStatus -StatusText "Abgebrochen" -ProgressValue 0 -TextColor ([System.Drawing.Color]::Blue) -progressBarParam $progressBar
    }
}

# Export functions
Export-ModuleMember -Function Start-WindowsDefender, Restart-DefenderService, Start-DefenderOfflineScan


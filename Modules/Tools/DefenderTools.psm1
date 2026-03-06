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
              
        # Status abrufen
        $status = Get-MpComputerStatus

        # ── Abschnitt: Status ─────────────────────────────────────────────────
        Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Action'
        $outputBox.AppendText("`r`n  " + ("═" * 66) + "`r`n")
        Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Action'
        $outputBox.AppendText("  Windows Defender – Aktueller Status`r`n")
        Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Action'
        $outputBox.AppendText("  " + ("═" * 66) + "`r`n`r`n")

        # Boolean-Werte lesbar darstellen
        $avIcon      = if ($status.AntivirusEnabled)           { "✓ Aktiv"     } else { "✗ Inaktiv" }
        $rtIcon      = if ($status.RealTimeProtectionEnabled)  { "✓ Aktiv"     } else { "✗ Inaktiv" }
        $avStyle     = if ($status.AntivirusEnabled)           { 'Success'     } else { 'Error'     }
        $rtStyle     = if ($status.RealTimeProtectionEnabled)  { 'Success'     } else { 'Error'     }

        # Signatur-Datum aufbereiten
        $sigDate = try { $status.AntivirusSignatureLastUpdated.ToString("dd.MM.yyyy HH:mm") } catch { "Unbekannt" }

        # Letzter Scan aufbereiten
        if ($status.QuickScanEndTime) {
            $timeSinceScan = (Get-Date) - $status.QuickScanEndTime
            $scanTimeInfo  = $status.QuickScanEndTime.ToString("dd.MM.yyyy HH:mm:ss")
            if ($timeSinceScan.TotalHours -lt 1) {
                $lastScanText = "vor $([Math]::Round($timeSinceScan.TotalMinutes)) Min. ($scanTimeInfo)"
            } else {
                $lastScanText = "vor $([Math]::Round($timeSinceScan.TotalHours,1)) Std. ($scanTimeInfo)"
            }
        } else {
            $lastScanText = "vor $($status.QuickScanAge) Std. (Uhrzeit unbekannt)"
        }

        # Konsole
        Write-Host "  ┌─ Antivirus-Schutz  : $avIcon" -ForegroundColor Yellow
        Write-Host "  ├─ Echtzeit-Schutz   : $rtIcon" -ForegroundColor Yellow
        Write-Host "  ├─ Signaturversion   : $($status.AntivirusSignatureVersion)" -ForegroundColor Yellow
        Write-Host "  ├─ Signatur-Update   : $sigDate" -ForegroundColor Yellow
        Write-Host "  └─ Letzter Quick-Scan: $lastScanText" -ForegroundColor Cyan

        # outputBox
        Set-OutputSelectionStyle -OutputBox $outputBox -Style $avStyle
        $outputBox.AppendText("  ┌─ Antivirus-Schutz  : $avIcon`r`n")
        Set-OutputSelectionStyle -OutputBox $outputBox -Style $rtStyle
        $outputBox.AppendText("  ├─ Echtzeit-Schutz   : $rtIcon`r`n")
        Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Default'
        $outputBox.AppendText("  ├─ Signaturversion   : $($status.AntivirusSignatureVersion)`r`n")
        $outputBox.AppendText("  ├─ Signatur-Update   : $sigDate`r`n")
        $outputBox.AppendText("  └─ Letzter Quick-Scan: $lastScanText`r`n")

        # Warnungen bei inaktivem Schutz
        if (-not $status.AntivirusEnabled) {
            Write-Host "`n  [!] WARNUNG: Antivirus ist deaktiviert!" -ForegroundColor Red
            Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Error'
            $outputBox.AppendText("`r`n  [!] WARNUNG: Antivirus ist deaktiviert!`r`n")
            Write-ToolLog -ToolName "WindowsDefender" -Message "WARNUNG: Antivirus ist deaktiviert!" -OutputBox $null -Level "Warning" -SaveToDatabase
        }
        if (-not $status.RealTimeProtectionEnabled) {
            Write-Host "  [!] WARNUNG: Echtzeit-Schutz ist deaktiviert!" -ForegroundColor Red
            Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Error'
            $outputBox.AppendText("  [!] WARNUNG: Echtzeit-Schutz ist deaktiviert!`r`n")
            Write-ToolLog -ToolName "WindowsDefender" -Message "WARNUNG: Echtzeit-Schutz ist deaktiviert!" -OutputBox $null -Level "Warning" -SaveToDatabase
        }

        Write-ToolLog -ToolName "WindowsDefender" -Message "Status: AV=$avIcon | RT=$rtIcon | Sig=$($status.AntivirusSignatureVersion) | Update=$sigDate | Scan=$lastScanText" -OutputBox $null -Level "Information" -SaveToDatabase

        # ── Abschnitt: Quick Scan ─────────────────────────────────────────────
        Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Action'
        $outputBox.AppendText("`r`n  " + ("═" * 66) + "`r`n")
        $outputBox.AppendText("  Quick Scan`r`n")
        $outputBox.AppendText("  " + ("═" * 66) + "`r`n`r`n")
        Write-Host
        Write-Host ("  " + ("═" * 66)) -ForegroundColor Cyan
        Write-Host "  Quick Scan" -ForegroundColor Cyan
        Write-Host ("  " + ("═" * 66)) -ForegroundColor Cyan

        # Starte Quick Scan
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
                        $logPath = Join-Path $PSScriptRoot "..\..\Data\Temp\MpCmdRun.log"
                        if (Test-Path $logPath) {
                            Write-ConsoleAndOutputBox -Message "Details in Log-Datei: $logPath" -Type "Info" -OutputBox $outputBox -ToolName "WindowsDefender" -NoTimestamp
                        }
                    }                
                }
                else {
                    Write-ConsoleAndOutputBox -Message "Weder Start-MpScan noch MpCmdRun.exe konnten gefunden werden." -Type "Error" -OutputBox $outputBox -ToolName "WindowsDefender" -NoTimestamp -SaveToDatabase
                }
            }            
            
            # ── Abschnitt: Scan-Ergebnis ──────────────────────────────────────
            Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Action'
            $outputBox.AppendText("`r`n  " + ("═" * 66) + "`r`n")
            $outputBox.AppendText("  Scan-Ergebnis`r`n")
            $outputBox.AppendText("  " + ("═" * 66) + "`r`n`r`n")
            Write-Host
            Write-Host ("  " + ("═" * 66)) -ForegroundColor Cyan
            Write-Host "  Scan-Ergebnis" -ForegroundColor Cyan
            Write-Host ("  " + ("═" * 66)) -ForegroundColor Cyan

            # Scan-Ergebnisse nur auswerten, wenn Scan erfolgreich war
            if ($scanSuccessful) {
                Write-ConsoleAndOutputBox -Message "Scan-Ergebnisse werden ausgewertet..." -Type "Info" -OutputBox $outputBox -ToolName "WindowsDefender" -NoTimestamp -SaveToDatabase
                
                $threats = $null
                try {
                    if (Get-Command Get-MpThreatDetection -ErrorAction SilentlyContinue) {
                        $threats = @(Get-MpThreatDetection | Where-Object { $_.ThreatStatus -ne "Resolved" })
                    }
                    if ($threats -and $threats.Count -gt 0) {
                        $threatCount = $threats.Count

                        Write-Host "  [!] $threatCount aktive Bedrohung(en) erkannt:" -ForegroundColor Red
                        Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Error'
                        $outputBox.AppendText("  [!] $threatCount aktive Bedrohung(en) erkannt:`r`n")

                        foreach ($threat in $threats) {
                            Write-Host "      ├─ $($threat.ThreatName) (ID: $($threat.ThreatID))" -ForegroundColor Red
                            Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Error'
                            $outputBox.AppendText("      ├─ $($threat.ThreatName) (ID: $($threat.ThreatID))`r`n")
                            Write-ToolLog -ToolName "WindowsDefender" -Message "Bedrohung: $($threat.ThreatName) (ID: $($threat.ThreatID))" -OutputBox $null -Level "Warning" -SaveToDatabase
                        }
                    }
                    else {
                        Write-Host "  [✓] Keine Bedrohungen erkannt – System ist sauber." -ForegroundColor Green
                        Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Success'
                        $outputBox.AppendText("  [✓] Keine Bedrohungen erkannt – System ist sauber.`r`n")
                        Write-ToolLog -ToolName "WindowsDefender" -Message "Keine Bedrohungen erkannt – System ist sauber." -OutputBox $null -Level "Information" -SaveToDatabase
                    }            
                }
                catch {
                    Write-ConsoleAndOutputBox -Message "Fehler beim Auswerten der Scan-Ergebnisse: $_" -Type "Warning" -OutputBox $outputBox -ToolName "WindowsDefender" -NoTimestamp
                }
            }
            else {
                Write-Host "  [⚠] Scan nicht abgeschlossen – keine Ergebnisse verfügbar." -ForegroundColor Orange
                Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Warning'
                $outputBox.AppendText("  [⚠] Scan nicht abgeschlossen – keine Ergebnisse verfügbar.`r`n")
                Write-ToolLog -ToolName "WindowsDefender" -Message "Scan nicht abgeschlossen." -OutputBox $null -Level "Warning" -SaveToDatabase
            }

            # Abschlusslinie
            Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Action'
            $outputBox.AppendText("`r`n  " + ("═" * 66) + "`r`n")
            Write-Host ("  " + ("═" * 66)) -ForegroundColor Cyan        
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

# Function to clear Windows Defender Protection History
function Clear-DefenderProtectionHistory {
    <#
    .SYNOPSIS
        Löscht den Windows Defender Schutzverlauf
    .DESCRIPTION
        Entfernt alle Einträge aus dem Windows Defender Bedrohungsverlauf und leert die Quarantäne
    .PARAMETER OutputBox
        Die RichTextBox für die Ausgabe (optional)
    #>
    param(
        [System.Windows.Forms.RichTextBox]$OutputBox = $null
    )
    
    try {
        # Bestätigungsdialog
        $result = [System.Windows.Forms.MessageBox]::Show(
            "Möchten Sie wirklich den gesamten Defender-Schutzverlauf löschen?`n`nDies entfernt alle Einträge aus dem Bedrohungsverlauf.",
            "Schutzverlauf löschen",
            [System.Windows.Forms.MessageBoxButtons]::YesNo,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        )
        
        if ($result -eq [System.Windows.Forms.DialogResult]::No) {
            if ($OutputBox) {
                Write-ToolLog -ToolName "DefenderHistory" `
                    -Message "Vorgang wurde abgebrochen" `
                    -OutputBox $OutputBox `
                    -Style 'Warning' `
                    -Level "Information"
            }
            return
        }
        
        if ($OutputBox) {
            Write-ToolLog -ToolName "DefenderHistory" `
                -Message "Lösche Defender-Schutzverlauf..." `
                -OutputBox $OutputBox `
                -Style 'Action' `
                -Level "Information" `
                -SaveToDatabase
        }
        
        # Methode 1: Alle Bedrohungen entfernen
        try {
            Remove-MpThreat -ErrorAction Stop
            if ($OutputBox) {
                Write-ToolLog -ToolName "DefenderHistory" `
                    -Message "✓ Bedrohungsliste erfolgreich geleert" `
                    -OutputBox $OutputBox `
                    -Style 'Success' `
                    -Level "Success"
            }
        }
        catch {
            if ($OutputBox) {
                Write-ToolLog -ToolName "DefenderHistory" `
                    -Message "Hinweis: Keine aktiven Bedrohungen gefunden oder bereits gelöscht" `
                    -OutputBox $OutputBox `
                    -Style 'Info' `
                    -Level "Information"
            }
        }
        
        # Methode 2: Quarantäne-Bereinigung konfigurieren (auf 0 Tage setzen)
        try {
            Set-MpPreference -QuarantinePurgeItemsAfterDelay 0 -ErrorAction Stop
            if ($OutputBox) {
                Write-ToolLog -ToolName "DefenderHistory" `
                    -Message "✓ Quarantäne-Bereinigung aktiviert" `
                    -OutputBox $OutputBox `
                    -Style 'Success' `
                    -Level "Success"
            }
        }
        catch {
            if ($OutputBox) {
                Write-ToolLog -ToolName "DefenderHistory" `
                    -Message "Warnung: Quarantäne-Einstellung konnte nicht geändert werden: $_" `
                    -OutputBox $OutputBox `
                    -Style 'Warning' `
                    -Level "Warning"
            }
        }
        
        # Methode 3: Event Log leeren (für vollständiges Löschen)
        try {
            wevtutil cl "Microsoft-Windows-Windows Defender/Operational" 2>$null
            if ($LASTEXITCODE -eq 0) {
                if ($OutputBox) {
                    Write-ToolLog -ToolName "DefenderHistory" `
                        -Message "✓ Event-Log erfolgreich geleert" `
                        -OutputBox $OutputBox `
                        -Style 'Success' `
                        -Level "Success"
                }
            }
        }
        catch {
            if ($OutputBox) {
                Write-ToolLog -ToolName "DefenderHistory" `
                    -Message "Hinweis: Event-Log konnte nicht geleert werden" `
                    -OutputBox $OutputBox `
                    -Style 'Info' `
                    -Level "Information"
            }
        }
        
        # Abschlussmeldung
        if ($OutputBox) {
            Write-ToolLog -ToolName "DefenderHistory" `
                -Message "Schutzverlauf wurde erfolgreich bereinigt" `
                -OutputBox $OutputBox `
                -Style 'Success' `
                -Level "Success" `
                -SaveToDatabase
        }
        
        [System.Windows.Forms.MessageBox]::Show(
            "Der Defender-Schutzverlauf wurde erfolgreich gelöscht.",
            "Erfolgreich",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        )
    }
    catch {
        if ($OutputBox) {
            Write-ToolLog -ToolName "DefenderHistory" `
                -Message "Fehler beim Löschen des Schutzverlaufs: $_" `
                -OutputBox $OutputBox `
                -Style 'Error' `
                -Level "Error" `
                -SaveToDatabase
        }
        
        [System.Windows.Forms.MessageBox]::Show(
            "Fehler beim Löschen des Schutzverlaufs:`n`n$_",
            "Fehler",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
    }
}

# Export functions
Export-ModuleMember -Function Start-WindowsDefender, Restart-DefenderService, Start-DefenderOfflineScan, Clear-DefenderProtectionHistory



# SIG # Begin signature block
# MIIcSgYJKoZIhvcNAQcCoIIcOzCCHDcCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCD6L5wfo6Ydf3UY
# VBKWTC7gi0cKNaWGrZ0GLdEv5FwzOKCCFnowggM8MIICJKADAgECAhBJfyGrXBJT
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
# MQ4wDAYKKwYBBAGCNwIBFTAvBgkqhkiG9w0BCQQxIgQglxwmfpbledPW3J81e/+T
# 8jpkgb2LVAURZ64DvmKsY8QwDQYJKoZIhvcNAQEBBQAEggEAAAUs8pbpfEbQBLFv
# 7piNg6i3zrTSfx5bCeNRzmWmL/7sYg/nj1sQ/Oi4GUmVxt+rp8bEiWX6uOxmSfkG
# ZRsgNDBnfp0uP85PYEEqcojvhKspKLHnUeqpyQYW8ZF3Dw+Rql3sW4mGx+zXby2A
# /L1JljynFbq/VVysQPOrvbeA+2oYse1sPqw27OfMiX2fwJs2tTBxK9n49XbBBe3w
# inmDR6s77sVH40VEbg6lxPkhcp0AbhFq1Jxt3dPg6rgIUFo9NHCavTAOXrWkm3W7
# 5shUCiLAJdE8b4ALG/RtJ/EhADsUoRiczmallelZah5dcJdOfEmrPToBAypHdUey
# 19tG6aGCAyYwggMiBgkqhkiG9w0BCQYxggMTMIIDDwIBATB9MGkxCzAJBgNVBAYT
# AlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5jLjFBMD8GA1UEAxM4RGlnaUNlcnQg
# VHJ1c3RlZCBHNCBUaW1lU3RhbXBpbmcgUlNBNDA5NiBTSEEyNTYgMjAyNSBDQTEC
# EAqA7xhLjfEFgtHEdqeVdGgwDQYJYIZIAWUDBAIBBQCgaTAYBgkqhkiG9w0BCQMx
# CwYJKoZIhvcNAQcBMBwGCSqGSIb3DQEJBTEPFw0yNjAxMjAxODAyNTVaMC8GCSqG
# SIb3DQEJBDEiBCBbRj+fNx31FpIFCiFAMLfBA8h60L7qz4OI+xo2Yl6aDTANBgkq
# hkiG9w0BAQEFAASCAgBSyRXd2hWpEsqif1BrqLRY04fxYIRJDm4alUWbB1gpjiYn
# L98qELvTsRYZ9bmsqbgz2e0w6A4KFP3eJyL9cdEk/HV3B48olZ+Ib6DShzaNotuZ
# 6qvK80Eg0+sFArjq0m5ytDJmbRIINsS9fgb1/+5klBqzray8K9pBShYNGr6V0ULo
# 2SMXCs05/EtbIH7/bb5e/fDXVnt/CTlejeearxUxu6Xf6PYBz6mLbgyXk3wWXMQi
# ZDK3PDyZJbGzWBSySrJ7z9v3cCD8/Ztsq926rlwqOJxcNfM4tnYcFipnoJGgpcPI
# YwJUSIZq7ZMCLHCNcWHTgUYU8oP6GvwO/heaR2q/k2Dyrzmazyeid/d5RFU7aEL7
# EWEfCJkzflY/GyVXbcN/vapFD11WalGN+xSCeQFvo59p5PBJZWqW/v7u4noHnZ3J
# bZCXqKZaNEhGI+TR2vGDZYPdwNifIxu0m5f2+EY5IMxZm1yKy2GTvLdYSPFjDxfD
# Y3n3AUvbLee+1/AJ66OniPfPGh5MAZKSyd6etE52JEl57IWyFOuCxrFEOrNztPH5
# elsI4Fs1pvPDC1UPn6x8CEp2xoekIUtlMLZAwFgKgC3QSEaJ0XE0y++kaI1Efe/f
# AP1ViYBAqZLlc+b+IWD/CqbACDTSOih7p1mgO9azEON4/aDsAj30BdlTX9zFxA==
# SIG # End signature block

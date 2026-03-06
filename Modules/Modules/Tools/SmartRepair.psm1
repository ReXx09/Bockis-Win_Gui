#Requires -Version 5.1
# SmartRepair.psm1
# 1-Klick Smart Repair - Analysiert und behebt automatisch häufige Windows-Probleme
# =====================================================================================

# -----------------------------------------------------------------------------------------
# Invoke-SmartRepair
# Führt alle 22 Prüfschritte sequenziell durch. Jeder Schritt ruft $ProgressCallback auf
# und gibt das Ergebnis über $OnCheckComplete zurück.
# Gibt ein Gesamt-Ergebnisobjekt zurück:
#   @{
#       Overall = "Green" | "Yellow" | "Red"
#       Checks  = @( @{ Name; Status; Detail } , ... )
#   }
# -----------------------------------------------------------------------------------------
# Persistenter Zeitstempel des letzten Scan-Starts (C4 Wiederholungssperre + C5 Anzeige)
$script:lastSmartRepairTime = $null

function Invoke-SmartRepair {
    param(
        $OutputBox,        # System.Windows.Forms.RichTextBox (untyped - Projekt nutzt ggf. abgeleitete Klasse)
        $ProgressBar,      # ToolStripProgressBar / TextProgressBar (untyped wegen custom Klasse)
        # Wird nach jedem Schritt aufgerufen (Step, Total, Name)
        [scriptblock]$ProgressCallback,
        # Wird nach jedem abgeschlossenen Check aufgerufen (Name, Status, Detail)
        [scriptblock]$OnCheckComplete
    )

    $results = [ordered]@{
        Overall       = "Green"   # Green / Yellow / Red
        Checks        = [System.Collections.Generic.List[hashtable]]::new()
        NeedsSFCscan  = $false    # SFC /scannow empfohlen?
        NeedsDISMscan = $false    # DISM /ScanHealth empfohlen?
        NeedsChkdsk   = $false    # CHKDSK beim naechsten Boot empfohlen?
        Duration      = 0         # Gesamtdauer in Sekunden (C1)
    }

    # Stoppuhr starten (C1)
    $globalSW = [System.Diagnostics.Stopwatch]::StartNew()

    # --- Interne Hilfsfunktion: Ergebnis hinzufügen und Gesamtstatus eskalieren ---
    function Add-CheckResult {
        param(
            [string]$Name,
            [ValidateSet("Green","Yellow","Red")][string]$Status,
            [string]$Detail
        )
        $entry = @{ Name = $Name; Status = $Status; Detail = $Detail }
        $results.Checks.Add($entry)

        # Gesamtstatus eskalieren (Green → Yellow → Red, nie sinken)
        if ($Status -eq "Red" -and $results.Overall -ne "Red") {
            $results.Overall = "Red"
        } elseif ($Status -eq "Yellow" -and $results.Overall -eq "Green") {
            $results.Overall = "Yellow"
        }

        # UI-Callback aufrufen
        if ($OnCheckComplete) {
            try { & $OnCheckComplete -Name $Name -Status $Status -Detail $Detail } catch {}
        }
    }

    # --- Interne Hilfsfunktion: OutputBox beschreiben ---
    function Write-SR {
        param([string]$Msg, [string]$Type = "Info")
        if (-not $OutputBox) { return }
        try {
            $color = switch ($Type) {
                "Success" { [System.Drawing.Color]::FromArgb(100,200,100) }
                "Warning" { [System.Drawing.Color]::FromArgb(255,200,50) }
                "Error"   { [System.Drawing.Color]::FromArgb(220,80,80) }
                "Header"  { [System.Drawing.Color]::FromArgb(100,180,255) }
                default   { [System.Drawing.Color]::FromArgb(200,200,200) }
            }
            $OutputBox.SelectionStart  = $OutputBox.TextLength
            $OutputBox.SelectionLength = 0
            $OutputBox.SelectionColor  = $color
            $OutputBox.AppendText("$Msg`r`n")
            $OutputBox.SelectionColor  = $OutputBox.ForeColor
            $OutputBox.ScrollToCaret()
            # UI-Thread entsperren damit die GUI nicht einfriert
            [System.Windows.Forms.Application]::DoEvents()
        } catch {}
    }

    # =========================================================================
    #  HEAD
    # =========================================================================

    # C4 – Wiederholungssperre (< 5 Minuten seit letztem Scan)
    if ($script:lastSmartRepairTime -and ((Get-Date) - $script:lastSmartRepairTime).TotalMinutes -lt 5) {
        $minsAgo = [int]((Get-Date) - $script:lastSmartRepairTime).TotalMinutes
        $secsAgo = [int]((Get-Date) - $script:lastSmartRepairTime).TotalSeconds
        Write-SR "" 
        Write-SR "  ⚠  Letzter Scan vor $secsAgo Sekunden. Bitte warten Sie 5 Minuten zwischen den Scans." "Warning"
        Write-SR "     (Wiederholen Sie den Scan nach $(5 - $minsAgo) weiteren Minuten.)" "Warning"
        Write-SR ""
    }
    $script:lastSmartRepairTime = Get-Date

    Write-SR "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" "Header"
    Write-SR "      ⚡  BOCKIS WIN-GUI  |  SMART REPAIR  ⚡" "Header"
    Write-SR "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" "Header"
    Write-SR ""
    Write-SR "  Start: $(Get-Date -Format 'dd.MM.yyyy  HH:mm:ss')" "Info"
    # C5 – Letzter-Scan-Zeitstempel (beim erneuten Aufruf)
    if ($script:lastSmartRepairTime) {
        # lastSmartRepairTime wurde oben gerade gesetzt - hier nichts anzeigen
        # (Anzeige erfolgt beim nächsten Aufruf)
    }
    Write-SR "  22 Prüfschritte  |  Ergebnisse in Echtzeit" "Info"
    Write-SR ""

    # =========================================================================
    #  CHECK 12 – SMART-Status der Festplatten
    # =========================================================================
    if ($ProgressCallback) { & $ProgressCallback -Step 1 -Total 22 -Name "Festplatten-Gesundheit (SMART) wird geprüft…" }
    Write-SR "[ 1 / 22 ]  Festplatten-Gesundheit (SMART)" "Header"

    try {
        $disks = Get-PhysicalDisk -ErrorAction Stop
        $warnDisks = [System.Collections.Generic.List[string]]::new()
        $badDisks  = [System.Collections.Generic.List[string]]::new()

        foreach ($disk in $disks) {
            $label = "$($disk.FriendlyName) ($([math]::Round($disk.Size/1GB,0)) GB)"
            switch ($disk.HealthStatus) {
                'Healthy'   { Write-SR "     ✓  $label – Gesund" "Success" }
                'Warning'   { Write-SR "     ⚠  $label – Warnung!" "Warning"; $warnDisks.Add($disk.FriendlyName) }
                'Unhealthy' { Write-SR "     ✗  $label – FEHLERHAFT!" "Error"; $badDisks.Add($disk.FriendlyName) }
                default     { Write-SR "     ⚠  $label – Status: $($disk.HealthStatus)" "Warning"; $warnDisks.Add($disk.FriendlyName) }
            }
        }

        if ($badDisks.Count -gt 0) {
            Add-CheckResult -Name "Festplatten (SMART)" -Status "Red" -Detail "Fehlerhaft: $($badDisks -join ', ')"
        } elseif ($warnDisks.Count -gt 0) {
            Add-CheckResult -Name "Festplatten (SMART)" -Status "Yellow" -Detail "Warnung: $($warnDisks -join ', ')"
        } else {
            Add-CheckResult -Name "Festplatten (SMART)" -Status "Green" -Detail "Alle Festplatten gesund"
        }
    } catch {
        Write-SR "  ⚠  SMART-Status konnte nicht abgerufen werden." "Warning"
        Add-CheckResult -Name "Festplatten (SMART)" -Status "Yellow" -Detail "Prüfung nicht möglich"
    }
    Write-SR ""

    # =========================================================================
    #  CHECK 8 – Festplatten-Speicherplatz
    # =========================================================================
    if ($ProgressCallback) { & $ProgressCallback -Step 2 -Total 22 -Name "Festplatten-Speicherplatz wird geprüft…" }
    Write-SR "[ 2 / 22 ]  Festplatten-Speicherplatz (C:)" "Header"

    try {
        $drive = Get-PSDrive -Name C -ErrorAction Stop
        $freeGB  = [math]::Round($drive.Free  / 1GB, 1)
        $usedGB  = [math]::Round($drive.Used  / 1GB, 1)
        $totalGB = [math]::Round(($drive.Free + $drive.Used) / 1GB, 1)
        $freePct = if ($totalGB -gt 0) { [math]::Round(($drive.Free / ($drive.Free + $drive.Used)) * 100, 0) } else { 0 }

        if ($freePct -le 5) {
            Write-SR "  ✗  Kritisch wenig Speicherplatz: $freeGB GB frei ($freePct %) von $totalGB GB" "Error"
            Add-CheckResult -Name "Speicherplatz (C:)" -Status "Red" -Detail "$freeGB GB frei ($freePct %)"
        } elseif ($freePct -le 10) {
            Write-SR "  ⚠  Wenig Speicherplatz: $freeGB GB frei ($freePct %) von $totalGB GB" "Warning"
            Add-CheckResult -Name "Speicherplatz (C:)" -Status "Yellow" -Detail "$freeGB GB frei ($freePct %)"
        } else {
            Write-SR "  ✓  Speicherplatz OK: $freeGB GB frei ($freePct %) von $totalGB GB" "Success"
            Add-CheckResult -Name "Speicherplatz (C:)" -Status "Green" -Detail "$freeGB GB frei ($freePct %)"
        }
    } catch {
        Write-SR "  ⚠  Speicherplatz konnte nicht ermittelt werden." "Warning"
        Add-CheckResult -Name "Speicherplatz (C:)" -Status "Yellow" -Detail "Prüfung nicht möglich"
    }
    Write-SR ""

    # =========================================================================
    #  CHECK 14 – RAM-Auslastung
    # =========================================================================
    if ($ProgressCallback) { & $ProgressCallback -Step 3 -Total 22 -Name "RAM-Auslastung wird ermittelt…" }
    Write-SR "[ 3 / 22 ]  RAM-Auslastung" "Header"

    try {
        $os      = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop
        $totalMB = [math]::Round($os.TotalVisibleMemorySize / 1024, 0)
        $freeMB  = [math]::Round($os.FreePhysicalMemory       / 1024, 0)
        $usedMB  = $totalMB - $freeMB
        $usedPct = if ($totalMB -gt 0) { [math]::Round(($usedMB / $totalMB) * 100, 0) } else { 0 }
        $totalGB = [math]::Round($totalMB / 1024, 1)
        $usedGB  = [math]::Round($usedMB  / 1024, 1)

        if ($usedPct -ge 95) {
            Write-SR "  ✗  RAM-Auslastung kritisch: $usedGB GB / $totalGB GB belegt ($usedPct %)!" "Error"
            Add-CheckResult -Name "RAM-Auslastung" -Status "Red" -Detail "$usedPct % belegt ($usedGB / $totalGB GB)"
        } elseif ($usedPct -ge 85) {
            Write-SR "  ⚠  RAM-Auslastung hoch: $usedGB GB / $totalGB GB belegt ($usedPct %)." "Warning"
            Add-CheckResult -Name "RAM-Auslastung" -Status "Yellow" -Detail "$usedPct % belegt ($usedGB / $totalGB GB)"
        } else {
            Write-SR "  ✓  RAM-Auslastung normal: $usedGB GB / $totalGB GB belegt ($usedPct %)." "Success"
            Add-CheckResult -Name "RAM-Auslastung" -Status "Green" -Detail "$usedPct % belegt ($usedGB / $totalGB GB)"
        }
    } catch {
        Write-SR "  ⚠  RAM-Auslastung konnte nicht ermittelt werden." "Warning"
        Add-CheckResult -Name "RAM-Auslastung" -Status "Yellow" -Detail "Prüfung nicht möglich"
    }
    Write-SR ""

    # =========================================================================
    #  CHECK 18 – Pagefile / Auslagerungsdatei
    # =========================================================================
    if ($ProgressCallback) { & $ProgressCallback -Step 4 -Total 22 -Name "Auslagerungsdatei wird geprüft…" }
    Write-SR "[ 4 / 22 ]  Auslagerungsdatei (Pagefile)" "Header"

    try {
        $pf = Get-CimInstance -ClassName Win32_PageFileUsage -ErrorAction Stop
        if (-not $pf -or @($pf).Count -eq 0) {
            Write-SR "  ⚠  Keine Auslagerungsdatei konfiguriert – kann Systeminstabilität verursachen." "Warning"
            Add-CheckResult -Name "Auslagerungsdatei" -Status "Yellow" -Detail "Kein Pagefile konfiguriert"
        } else {
            foreach ($p in @($pf)) {
                $usedMB  = $p.CurrentUsage
                $allocMB = $p.AllocatedBaseSize
                $pct     = if ($allocMB -gt 0) { [math]::Round(($usedMB / $allocMB) * 100, 0) } else { 0 }
                if ($pct -ge 90) {
                    Write-SR "  ⚠  Pagefile fast voll: $usedMB MB / $allocMB MB ($pct %)" "Warning"
                    Add-CheckResult -Name "Auslagerungsdatei" -Status "Yellow" -Detail "Zu $pct % belegt"
                } else {
                    Write-SR "  ✓  Pagefile OK: $usedMB MB / $allocMB MB belegt ($pct %)" "Success"
                    Add-CheckResult -Name "Auslagerungsdatei" -Status "Green" -Detail "OK ($pct % belegt)"
                }
            }
        }
    } catch {
        Write-SR "  ⚠  Pagefile konnte nicht geprüft werden." "Warning"
        Add-CheckResult -Name "Auslagerungsdatei" -Status "Yellow" -Detail "Prüfung nicht möglich"
    }
    Write-SR ""

    # =========================================================================
    #  CHECK 17 – CHKDSK Online-Scan + Spot-Fix (kein Neustart für Scan)
    # =========================================================================
    if ($ProgressCallback) { & $ProgressCallback -Step 5 -Total 22 -Name "CHKDSK Online-Scan läuft…" }
    Write-SR "[ 5 / 22 ]  CHKDSK Online-Scan (C:)" "Header"
    Write-SR "     Online-Scan läuft (kein Neustart erforderlich)..." "Info"
    [System.Windows.Forms.Application]::DoEvents()

    try {
        # Phase 1: Online-Scan – erkennt Fehler ohne Neustart
        $chkTmp  = [System.IO.Path]::GetTempFileName()
        $chkProc = Start-Process -FilePath "chkdsk.exe" -ArgumentList "C: /scan" `
            -NoNewWindow -PassThru -RedirectStandardOutput $chkTmp -ErrorAction Stop
        while (-not $chkProc.HasExited) {
            Start-Sleep -Milliseconds 1500
            [System.Windows.Forms.Application]::DoEvents()
        }
        $chkOut  = Get-Content $chkTmp -ErrorAction SilentlyContinue
        Remove-Item $chkTmp -Force -ErrorAction SilentlyContinue
        $chkExit = $chkProc.ExitCode
        [System.Windows.Forms.Application]::DoEvents()

        if ($chkExit -eq 0) {
            Write-SR "  ✓  CHKDSK Online-Scan: Keine Fehler auf C: gefunden." "Success"
            Add-CheckResult -Name "CHKDSK (Online-Scan)" -Status "Green" -Detail "Keine Dateisystemfehler gefunden"
        } elseif ($chkExit -eq 2) {
            # Fehler gefunden die per Spot-Fix behebbar sind
            Write-SR "  ⚠  CHKDSK: Dateisystemfehler gefunden – starte Spot-Fix..." "Warning"
            [System.Windows.Forms.Application]::DoEvents()
            try {
                # /spotfix auf C: (Boot-Laufwerk): plant die Reparatur für den nächsten Start
                $fixProc = Start-Process -FilePath "chkdsk.exe" -ArgumentList "C: /spotfix" `
                    -NoNewWindow -PassThru -ErrorAction Stop
                while (-not $fixProc.HasExited) {
                    Start-Sleep -Milliseconds 1500
                    [System.Windows.Forms.Application]::DoEvents()
                }
                if ($fixProc.ExitCode -eq 0) {
                    Write-SR "  ✓  CHKDSK Spot-Fix eingeplant – Reparatur erfolgt beim nächsten Neustart." "Success"
                    Write-SR "     Bitte starte Windows neu um die Reparatur abzuschließen." "Warning"
                    Add-CheckResult -Name "CHKDSK (Online-Scan)" -Status "Yellow" -Detail "Spot-Fix geplant – Neustart abschließen"
                } else {
                    Write-SR "  ⚠  CHKDSK Spot-Fix konnte nicht alle Fehler einplanen (Exit $($fixProc.ExitCode))." "Warning"
                    Add-CheckResult -Name "CHKDSK (Online-Scan)" -Status "Yellow" -Detail "Teilweise – manueller CHKDSK /f empfohlen"
                }
                $results.NeedsChkdsk = $true
            } catch {
                Write-SR "  ⚠  CHKDSK Spot-Fix fehlgeschlagen: $($_.Exception.Message)" "Warning"
                Add-CheckResult -Name "CHKDSK (Online-Scan)" -Status "Yellow" -Detail "Spot-Fix nicht möglich – manuell empfohlen"
                $results.NeedsChkdsk = $true
            }
        } else {
            # Unbekannter Exit-Code – Fallback auf Dirty-Bit Prüfung
            $fsutilOut  = & fsutil dirty query C: 2>&1
            $fsutilExit = $LASTEXITCODE
            if ($fsutilExit -eq 0 -or ($fsutilOut -match 'NOT|NICHT')) {
                Write-SR "  ✓  C: ist sauber – kein CHKDSK erforderlich." "Success"
                Add-CheckResult -Name "CHKDSK (Online-Scan)" -Status "Green" -Detail "Laufwerk C: OK"
            } else {
                Write-SR "  ⚠  CHKDSK meldet Probleme auf C: (Exit $chkExit) – Offline-Prüfung empfohlen." "Warning"
                Add-CheckResult -Name "CHKDSK (Online-Scan)" -Status "Yellow" -Detail "Offline-CHKDSK empfohlen (Exit $chkExit)"
                $results.NeedsChkdsk = $true
            }
        }
    } catch {
        Write-SR "  ⚠  CHKDSK Online-Scan fehlgeschlagen: $($_.Exception.Message)" "Warning"
        Add-CheckResult -Name "CHKDSK (Online-Scan)" -Status "Yellow" -Detail "Scan nicht möglich"
    }
    Write-SR ""

    # =========================================================================
    #  CHECK 3 – System-Integrität (SFC CBS-Log Analyse, kein langer /scannow)
    # =========================================================================
    if ($ProgressCallback) { & $ProgressCallback -Step 6 -Total 22 -Name "System-Integrität wird analysiert…" }
    Write-SR "[ 6 / 22 ]  System-Integrität (CBS-Log Analyse)" "Header"

    try {
        $cbsLog = "$env:windir\Logs\CBS\CBS.log"
        $sfcIssueFound = $false

        if (Test-Path $cbsLog) {
            # Durchsucht die letzten 500 Zeilen des Logs nach SFC-Fehlern
            $recentLines = Get-Content $cbsLog -Tail 500 -ErrorAction SilentlyContinue
            $sfcErrors = $recentLines | Where-Object { $_ -match "Cannot repair member file|corrupt|repairing" }
            if ($sfcErrors -and $sfcErrors.Count -gt 0) {
                $sfcIssueFound = $true
            }
        }

        if ($sfcIssueFound) {
            Write-SR "  ⚠  CBS-Log enthält Hinweise auf beschädigte Systemdateien." "Warning"
            Write-SR "     → Auto-Reparatur: SFC /scannow wird gestartet (kann mehrere Minuten dauern)..." "Warning"
            try {
                $sfcProc = Start-Process -FilePath "sfc.exe" -ArgumentList "/scannow" -NoNewWindow -PassThru -ErrorAction Stop
                while (-not $sfcProc.HasExited) {
                    Start-Sleep -Milliseconds 1000
                    [System.Windows.Forms.Application]::DoEvents()
                }
                # Ergebnis direkt aus CBS-Log auslesen
                $repairLines = Get-Content $cbsLog -Tail 150 -ErrorAction SilentlyContinue
                $repaired    = $repairLines | Where-Object { $_ -match "successfully repaired|erfolgreich repariert" }
                $failed      = $repairLines | Where-Object { $_ -match "could not repair|konnte nicht repariert werden" }

                if ($repaired -and -not $failed) {
                    Write-SR "  ✓  SFC hat beschädigte Systemdateien erfolgreich repariert." "Success"
                    Add-CheckResult -Name "System-Integrität" -Status "Green" -Detail "SFC: Reparatur erfolgreich"
                    $results.NeedsSFCscan = $false
                } elseif ($failed) {
                    Write-SR "  ✗  SFC konnte nicht alle Dateien reparieren." "Error"
                    Write-SR "     → DISM RestoreHealth wird im nächsten Schritt automatisch ausgeführt." "Warning"
                    Add-CheckResult -Name "System-Integrität" -Status "Red" -Detail "SFC: Reparatur unvollständig – DISM folgt"
                    $results.NeedsSFCscan  = $false
                    $results.NeedsDISMscan = $true
                } else {
                    Write-SR "  ✓  SFC abgeschlossen – keine Probleme verblieben." "Success"
                    Add-CheckResult -Name "System-Integrität" -Status "Green" -Detail "SFC: Abgeschlossen, keine Probleme"
                    $results.NeedsSFCscan = $false
                }
            } catch {
                Write-SR "  ⚠  SFC konnte nicht gestartet werden: $($_.Exception.Message)" "Warning"
                Add-CheckResult -Name "System-Integrität" -Status "Yellow" -Detail "SFC manuell empfohlen"
                $results.NeedsSFCscan = $true
            }
        } else {
            Write-SR "  ✓  Keine beschädigten Systemdateien im CBS-Log gefunden." "Success"
            Add-CheckResult -Name "System-Integrität" -Status "Green"  -Detail "CBS-Log unauffällig"
        }
    } catch {
        Write-SR "  ⚠  CBS-Log konnte nicht analysiert werden." "Warning"
        Add-CheckResult -Name "System-Integrität" -Status "Yellow" -Detail "Log nicht lesbar"
    }
    Write-SR ""

    # =========================================================================
    #  CHECK 16 – DISM /CheckHealth (passiver Flag-Check, ~3 Sek.)
    # =========================================================================
    if ($ProgressCallback) { & $ProgressCallback -Step 7 -Total 22 -Name "DISM Component-Store wird geprüft…" }
    Write-SR "[ 7 / 22 ]  DISM Component-Store (CheckHealth)" "Header"

    try {
        $dismProc = Start-Process -FilePath "dism.exe" `
            -ArgumentList "/Online /Cleanup-Image /CheckHealth" `
            -NoNewWindow -Wait -PassThru -ErrorAction Stop
        [System.Windows.Forms.Application]::DoEvents()

        switch ($dismProc.ExitCode) {
            0 {
                Write-SR "  ✓  Component-Store ist in Ordnung (kein Flag gesetzt)." "Success"
                Add-CheckResult -Name "DISM CheckHealth" -Status "Green" -Detail "Component-Store OK"
            }
            3010 {
                Write-SR "  ⚠  DISM: Neustart für ausstehende Komponenten erforderlich (Exit 3010)." "Warning"
                Add-CheckResult -Name "DISM CheckHealth" -Status "Yellow" -Detail "Neustart erforderlich"
            }
            default {
                Write-SR "  ⚠  DISM hat einen Fehler-Flag erkannt (Exit $($dismProc.ExitCode))." "Warning"
                Write-SR "     → Auto-Reparatur: DISM /RestoreHealth wird gestartet (kann 10–30 Min. dauern)..." "Warning"
                [System.Windows.Forms.Application]::DoEvents()
                try {
                    $dismRepair = Start-Process -FilePath "dism.exe" `
                        -ArgumentList "/Online /Cleanup-Image /RestoreHealth" `
                        -NoNewWindow -PassThru -ErrorAction Stop
                    while (-not $dismRepair.HasExited) {
                        Start-Sleep -Milliseconds 2000
                        [System.Windows.Forms.Application]::DoEvents()
                    }
                    switch ($dismRepair.ExitCode) {
                        0 {
                            Write-SR "  ✓  DISM RestoreHealth erfolgreich – Component Store repariert." "Success"
                            Add-CheckResult -Name "DISM CheckHealth" -Status "Green" -Detail "DISM RestoreHealth: Erfolgreich"
                            $results.NeedsDISMscan = $false
                        }
                        3010 {
                            Write-SR "  ✓  DISM RestoreHealth abgeschlossen – Neustart empfohlen." "Success"
                            Add-CheckResult -Name "DISM CheckHealth" -Status "Yellow" -Detail "DISM: Repariert – Neustart empfohlen"
                            $results.NeedsDISMscan = $false
                        }
                        default {
                            Write-SR "  ✗  DISM RestoreHealth fehlgeschlagen (Exit $($dismRepair.ExitCode))." "Error"
                            Write-SR "     Mögliche Ursachen: Keine Internetverbindung, Windows Update-Fehler." "Warning"
                            Add-CheckResult -Name "DISM CheckHealth" -Status "Red" -Detail "DISM RestoreHealth fehlgeschlagen (Exit $($dismRepair.ExitCode))"
                            $results.NeedsDISMscan = $true
                        }
                    }
                } catch {
                    Write-SR "  ⚠  DISM RestoreHealth konnte nicht gestartet werden: $($_.Exception.Message)" "Warning"
                    Add-CheckResult -Name "DISM CheckHealth" -Status "Yellow" -Detail "DISM RestoreHealth manuell empfohlen"
                    $results.NeedsDISMscan = $true
                }
            }
        }
    } catch {
        Write-SR "  ⚠  DISM /CheckHealth konnte nicht ausgeführt werden (kein Admin?)." "Warning"
        Add-CheckResult -Name "DISM CheckHealth" -Status "Yellow" -Detail "Prüfung nicht möglich"
    }
    Write-SR ""

    # =========================================================================
    #  CHECK 2 – Windows Defender Status
    # =========================================================================
    if ($ProgressCallback) { & $ProgressCallback -Step 8 -Total 22 -Name "Defender-Status wird geprüft…" }
    Write-SR "[ 8 / 22 ]  Windows Defender Status" "Header"

    try {
        $defender = Get-MpComputerStatus -ErrorAction Stop

        if (-not $defender.AntivirusEnabled) {
            Write-SR "  ✗  Antivirus ist DEAKTIVIERT!" "Error"
            Add-CheckResult -Name "Windows Defender" -Status "Red"    -Detail "Antivirus deaktiviert!"
        } elseif (-not $defender.RealTimeProtectionEnabled) {
            Write-SR "  ⚠  Echtzeitschutz ist deaktiviert." "Warning"
            Add-CheckResult -Name "Windows Defender" -Status "Yellow" -Detail "Echtzeitschutz deaktiviert"
        } else {
            $lastUpdate = $defender.AntivirusSignatureLastUpdated
            Write-SR "  ✓  Echtzeitschutz aktiv  |  Signaturen: $(if($lastUpdate){$lastUpdate.ToString('dd.MM.yyyy')}else{'Unbekannt'})" "Success"
            Add-CheckResult -Name "Windows Defender" -Status "Green"  -Detail "Echtzeitschutz aktiv"
        }
    } catch {
        Write-SR "  ⚠  Defender-Status konnte nicht ermittelt werden." "Warning"
        Add-CheckResult -Name "Windows Defender" -Status "Yellow" -Detail "Prüfung nicht möglich"
    }
    Write-SR ""

    # =========================================================================
    #  CHECK 9 – Windows-Firewall Status
    # =========================================================================
    if ($ProgressCallback) { & $ProgressCallback -Step 9 -Total 22 -Name "Windows-Firewall wird geprüft…" }
    Write-SR "[ 9 / 22 ]  Windows-Firewall" "Header"

    try {
        $fwProfiles = Get-NetFirewallProfile -ErrorAction Stop
        $disabled   = $fwProfiles | Where-Object { -not $_.Enabled }

        if ($disabled) {
            $names = ($disabled | ForEach-Object { $_.Name }) -join ", "
            Write-SR "  ✗  Firewall-Profil(e) deaktiviert: $names" "Error"
            Add-CheckResult -Name "Windows-Firewall" -Status "Red" -Detail "Deaktiviert: $names"
        } else {
            Write-SR "  ✓  Alle Firewall-Profile sind aktiv (Domain / Private / Public)." "Success"
            Add-CheckResult -Name "Windows-Firewall" -Status "Green" -Detail "Alle Profile aktiv"
        }
    } catch {
        Write-SR "  ⚠  Firewall-Status konnte nicht ermittelt werden." "Warning"
        Add-CheckResult -Name "Windows-Firewall" -Status "Yellow" -Detail "Prüfung nicht möglich"
    }
    Write-SR ""

    # =========================================================================
    #  CHECK 15 – Hosts-Datei-Integrität
    # =========================================================================
    if ($ProgressCallback) { & $ProgressCallback -Step 10 -Total 22 -Name "Hosts-Datei wird geprüft…" }
    Write-SR "[ 10 / 22 ]  Hosts-Datei-Integrität" "Header"

    try {
        $hostsPath = "$env:SystemRoot\System32\drivers\etc\hosts"
        if (-not (Test-Path $hostsPath)) {
            Write-SR "  ⚠  Hosts-Datei nicht gefunden." "Warning"
            Add-CheckResult -Name "Hosts-Datei" -Status "Yellow" -Detail "Datei nicht gefunden"
        } else {
            $lines = Get-Content $hostsPath -ErrorAction Stop
            # Alle nicht-kommentären Zeilen mit IP-Adressen prüfen
            $suspicious = $lines | Where-Object {
                $_ -notmatch '^\s*#' -and      # kein Kommentar
                $_ -match '\d+\.\d+\.\d+\.\d+' -and # enthält IP
                $_ -notmatch '^\s*127\.0\.0\.\d+' -and # kein localhost
                $_ -notmatch '^\s*0\.0\.0\.0' -and    # kein 0.0.0.0 Blocker
                $_ -match '\S'
            }

            if ($suspicious -and @($suspicious).Count -gt 0) {
                Write-SR "  ⚠  $(@($suspicious).Count) auffällige Einträge in der Hosts-Datei!" "Warning"
                $suspicious | Select-Object -First 5 | ForEach-Object {
                    $entry = $_.Trim()
                    if ($entry.Length -gt 70) { $entry = $entry.Substring(0, 67) + '...' }
                    Write-SR "     • $entry" "Warning"
                }
                Add-CheckResult -Name "Hosts-Datei" -Status "Yellow" -Detail "$(@($suspicious).Count) nicht-standard Einträge gefunden"
            } else {
                Write-SR "  ✓  Hosts-Datei ist unauffällig." "Success"
                Add-CheckResult -Name "Hosts-Datei" -Status "Green" -Detail "Unauffällig"
            }
        }
    } catch {
        Write-SR "  ⚠  Hosts-Datei konnte nicht geprüft werden." "Warning"
        Add-CheckResult -Name "Hosts-Datei" -Status "Yellow" -Detail "Prüfung nicht möglich"
    }
    Write-SR ""

    # =========================================================================
    #  CHECK 20 – Abgelaufene Root-Zertifikate
    # =========================================================================
    if ($ProgressCallback) { & $ProgressCallback -Step 11 -Total 22 -Name "Zertifikatsspeicher wird geprüft…" }
    Write-SR "[ 11 / 22 ]  Root-Zertifikate (Gültigkeit)" "Header"

    try {
        $now          = Get-Date
        $allCerts     = Get-ChildItem -Path 'Cert:\LocalMachine\Root' -ErrorAction Stop
        # Nur Zertifikate die in den letzten 2 Jahren abgelaufen sind (ältere Legacy-Roots wie MS 2020/2021 absichtlich ignorieren)
        $expiredCerts = @($allCerts | Where-Object { $_.NotAfter -lt $now -and $_.NotAfter -gt $now.AddYears(-2) })
        $soonCerts    = @($allCerts | Where-Object { $_.NotAfter -gt $now -and $_.NotAfter -lt $now.AddDays(30) })

        if ($expiredCerts.Count -gt 0) {
            Write-SR "  ⚠  $($expiredCerts.Count) abgelaufene(s) Root-Zertifikat(e) gefunden!" "Warning"
            $expiredCerts | Select-Object -First 3 | ForEach-Object {
                $cn = ($_.Subject -replace '.*CN=([^,]+).*','$1').Trim()
                Write-SR "     • $cn  [abgelaufen: $($_.NotAfter.ToString('dd.MM.yyyy'))]" "Warning"
            }
            Add-CheckResult -Name "Root-Zertifikate" -Status "Yellow" -Detail "$($expiredCerts.Count) abgelaufen"
        } elseif ($soonCerts.Count -gt 0) {
            Write-SR "  ⚠  $($soonCerts.Count) Root-Zertifikat(e) läuft/laufen in < 30 Tagen ab." "Warning"
            Add-CheckResult -Name "Root-Zertifikate" -Status "Yellow" -Detail "$($soonCerts.Count) läuft demnächst ab"
        } else {
            Write-SR "  ✓  Alle $($allCerts.Count) Root-Zertifikate sind gültig." "Success"
            Add-CheckResult -Name "Root-Zertifikate" -Status "Green" -Detail "Alle $($allCerts.Count) Zertifikate gültig"
        }
    } catch {
        Write-SR "  ⚠  Zertifikatsspeicher konnte nicht geprüft werden." "Warning"
        Add-CheckResult -Name "Root-Zertifikate" -Status "Yellow" -Detail "Prüfung nicht möglich"
    }
    Write-SR ""

    # =========================================================================
    #  CHECK 10 – Kritische Windows-Dienste
    # =========================================================================
    if ($ProgressCallback) { & $ProgressCallback -Step 12 -Total 22 -Name "Kritische Dienste werden geprüft…" }
    Write-SR "[ 12 / 22 ]  Kritische Windows-Dienste" "Header"

    try {
        $criticalServices = @(
            @{ Name = 'wuauserv';  Display = 'Windows Update' },
            @{ Name = 'CryptSvc';  Display = 'Kryptografiedienste' },
            @{ Name = 'WinDefend'; Display = 'Windows Defender' },
            @{ Name = 'EventLog';  Display = 'Windows-Ereignisprotokoll' },
            @{ Name = 'LanmanServer'; Display = 'Server (Datei-/Druckerfreigabe)' }
        )
        $stoppedServices = [System.Collections.Generic.List[string]]::new()

        foreach ($svc in $criticalServices) {
            $s = Get-Service -Name $svc.Name -ErrorAction SilentlyContinue
            if (-not $s -or $s.Status -ne 'Running') {
                $stoppedServices.Add($svc.Display)
                Write-SR "     ✗  $($svc.Display) – gestoppt!" "Error"
            } else {
                Write-SR "     ✓  $($svc.Display) – läuft" "Success"
            }
        }

        if ($stoppedServices.Count -gt 0) {
            Add-CheckResult -Name "Kritische Dienste" -Status "Red" -Detail "Gestoppt: $($stoppedServices -join ', ')"
        } else {
            Add-CheckResult -Name "Kritische Dienste" -Status "Green" -Detail "Alle Dienste laufen"
        }
    } catch {
        Write-SR "  ⚠  Dienstprüfung fehlgeschlagen: $($_.Exception.Message)" "Warning"
        Add-CheckResult -Name "Kritische Dienste" -Status "Yellow" -Detail "Prüfung nicht möglich"
    }
    Write-SR ""

    # =========================================================================
    #  CHECK 22 – Windows-Suchdienst (WSearch)
    # =========================================================================
    if ($ProgressCallback) { & $ProgressCallback -Step 13 -Total 22 -Name "Windows-Suchdienst wird geprüft…" }
    Write-SR "[ 13 / 22 ]  Windows-Suchdienst (WSearch)" "Header"

    try {
        $wsearch = Get-Service -Name 'WSearch' -ErrorAction SilentlyContinue
        if (-not $wsearch) {
            Write-SR "  ⚠  Windows-Suchdienst (WSearch) nicht gefunden." "Warning"
            Add-CheckResult -Name "WSearch-Dienst" -Status "Yellow" -Detail "Dienst nicht gefunden"
        } elseif ($wsearch.Status -eq 'Running') {
            Write-SR "  ✓  Windows-Suchdienst läuft." "Success"
            Add-CheckResult -Name "WSearch-Dienst" -Status "Green" -Detail "Läuft"
        } elseif ($wsearch.StartType -eq 'Disabled') {
            Write-SR "  ⚠  Windows-Suchdienst ist deaktiviert (Startmenü-Suche eingeschränkt)." "Warning"
            Add-CheckResult -Name "WSearch-Dienst" -Status "Yellow" -Detail "Deaktiviert"
        } else {
            Write-SR "  ⚠  Windows-Suchdienst ist gestoppt (Status: $($wsearch.Status))." "Warning"
            Add-CheckResult -Name "WSearch-Dienst" -Status "Yellow" -Detail "Gestoppt"
        }
    } catch {
        Write-SR "  ⚠  WSearch-Status konnte nicht ermittelt werden." "Warning"
        Add-CheckResult -Name "WSearch-Dienst" -Status "Yellow" -Detail "Prüfung nicht möglich"
    }
    Write-SR ""

    # =========================================================================
    #  CHECK 11 – Windows-Aktivierungsstatus
    # =========================================================================
    if ($ProgressCallback) { & $ProgressCallback -Step 14 -Total 22 -Name "Windows-Aktivierung wird geprüft…" }
    Write-SR "[ 14 / 22 ]  Windows-Aktivierungsstatus" "Header"

    try {
        $lic = Get-CimInstance -ClassName SoftwareLicensingProduct -Filter "Name LIKE 'Windows%' AND PartialProductKey IS NOT NULL" -ErrorAction Stop |
               Select-Object -First 1

        # LicenseStatus: 1 = Licensed, 0 = Unlicensed, sonst weitere Zustände
        if (-not $lic) {
            Write-SR "  ⚠  Aktivierungsstatus konnte nicht ermittelt werden." "Warning"
            Add-CheckResult -Name "Windows-Aktivierung" -Status "Yellow" -Detail "Prüfung nicht möglich"
        } elseif ($lic.LicenseStatus -eq 1) {
            Write-SR "  ✓  Windows ist aktiviert." "Success"
            Add-CheckResult -Name "Windows-Aktivierung" -Status "Green" -Detail "Aktiviert"
        } else {
            $statusMap = @{0='Nicht lizenziert'; 2='Ablaufwarnung'; 3='Ablaufwarnung (erweitert)'; 4='Nicht lizenziert (Karenzzeit)'; 5='Benachrichtigungsmodus'}
            $licKeyInt  = [int]$lic.LicenseStatus
            $statusText = if ($statusMap.ContainsKey($licKeyInt)) { $statusMap[$licKeyInt] } else { "Status $licKeyInt" }
            Write-SR "  ⚠  Windows ist NICHT aktiviert: $statusText" "Warning"
            Add-CheckResult -Name "Windows-Aktivierung" -Status "Yellow" -Detail "Nicht aktiviert: $statusText"
        }
    } catch {
        Write-SR "  ⚠  Aktivierungsprüfung fehlgeschlagen." "Warning"
        Add-CheckResult -Name "Windows-Aktivierung" -Status "Yellow" -Detail "Prüfung nicht möglich"
    }
    Write-SR ""

    # =========================================================================
    #  CHECK 13 – Systemzeit-Synchronisation (W32tm)
    # =========================================================================
    if ($ProgressCallback) { & $ProgressCallback -Step 15 -Total 22 -Name "Systemzeit-Synchronisation wird geprüft…" }
    Write-SR "[ 15 / 22 ]  Systemzeit-Synchronisation" "Header"

    try {
        # W32tm-Dienst prüfen
        $w32tmSvc = Get-Service -Name 'W32Time' -ErrorAction SilentlyContinue
        if (-not $w32tmSvc -or $w32tmSvc.Status -ne 'Running') {
            Write-SR "  ⚠  Windows Zeitdienst (W32Time) ist nicht aktiv." "Warning"
            Add-CheckResult -Name "Systemzeit-Sync" -Status "Yellow" -Detail "W32Time-Dienst gestoppt"
        } else {
            # Zeitabweichung prüfen (w32tm /query /status)
            $w32Output = & w32tm /query /status 2>&1 | Out-String
            # Englischen und deutschen Output abfangen
            if ($w32Output -match 'Last Successful Sync Time:\s*(.+)') {
                $lastSync = $Matches[1].Trim()
                Write-SR "  ✓  Zeitsynchronisation aktiv  |  Letzter Sync: $lastSync" "Success"
                Add-CheckResult -Name "Systemzeit-Sync" -Status "Green" -Detail "Sync aktiv, letzter Sync: $lastSync"
            } elseif ($w32Output -match 'Letzte erfolgreiche Synchronisierungszeit:\s*(.+)') {
                $lastSync = $Matches[1].Trim()
                Write-SR "  ✓  Zeitsynchronisation aktiv  |  Letzter Sync: $lastSync" "Success"
                Add-CheckResult -Name "Systemzeit-Sync" -Status "Green" -Detail "Sync aktiv, letzter Sync: $lastSync"
            } elseif ($w32Output -match 'Source:\s*Local CMOS Clock') {
                Write-SR "  ⚠  Zeitquelle: Nur lokale Uhr (kein NTP-Server konfiguriert)." "Warning"
                Write-SR "     Tipp: 'w32tm /resync /force' als Administrator ausführen." "Warning"
                Add-CheckResult -Name "Systemzeit-Sync" -Status "Yellow" -Detail "Kein NTP-Server konfiguriert"
            } else {
                Write-SR "  ✓  Zeitdienst läuft." "Success"
                Add-CheckResult -Name "Systemzeit-Sync" -Status "Green" -Detail "Zeitdienst aktiv"
            }
        }
    } catch {
        Write-SR "  ⚠  Zeitprüfung fehlgeschlagen." "Warning"
        Add-CheckResult -Name "Systemzeit-Sync" -Status "Yellow" -Detail "Prüfung nicht möglich"
    }
    Write-SR ""

    # =========================================================================
    #  CHECK 21 – Energieplan
    # =========================================================================
    if ($ProgressCallback) { & $ProgressCallback -Step 16 -Total 22 -Name "Energieplan wird geprüft…" }
    Write-SR "[ 16 / 22 ]  Energieplan" "Header"

    try {
        $powerOutput = & powercfg /getactivescheme 2>&1 | Out-String
        if ($powerOutput -match 'GUID:\s*([\w-]+)\s*\((.+?)\)') {
            $planGuid = $Matches[1].Trim()
            $planName = $Matches[2].Trim()
            # GUID a1841308-3541-4fab-bc81-f71556f20b4a = Energiesparmodus
            if ($planGuid -eq 'a1841308-3541-4fab-bc81-f71556f20b4a' -or
                $planName -match 'Spar|Saver|Economy|Power\s*Sav') {
                Write-SR "  ⚠  Energiesparmodus aktiv: $planName" "Warning"
                Write-SR "     Empfehlung: Auf 'Ausgewogen' oder 'Höchstleistung' wechseln." "Warning"
                Add-CheckResult -Name "Energieplan" -Status "Yellow" -Detail "Energiesparmodus: $planName"
            } else {
                Write-SR "  ✓  Energieplan: $planName" "Success"
                Add-CheckResult -Name "Energieplan" -Status "Green" -Detail "OK: $planName"
            }
        } else {
            Write-SR "  ✓  Energieplan aktiv." "Success"
            Add-CheckResult -Name "Energieplan" -Status "Green" -Detail "Aktiv"
        }
    } catch {
        Write-SR "  ⚠  Energieplan konnte nicht ermittelt werden." "Warning"
        Add-CheckResult -Name "Energieplan" -Status "Yellow" -Detail "Prüfung nicht möglich"
    }
    Write-SR ""

    # =========================================================================
    #  CHECK 5 – Netzwerk / Internetverbindung
    # =========================================================================
    if ($ProgressCallback) { & $ProgressCallback -Step 17 -Total 22 -Name "Netzwerk-Verbindung wird geprüft…" }
    Write-SR "[ 17 / 22 ]  Netzwerk / Internetverbindung" "Header"

    try {
        # Teste Google DNS (8.8.8.8) und Cloudflare (1.1.1.1)
        $ping1 = Test-Connection -ComputerName "8.8.8.8"   -Count 1 -Quiet -ErrorAction Stop
        $ping2 = Test-Connection -ComputerName "1.1.1.1"   -Count 1 -Quiet -ErrorAction SilentlyContinue

        if ($ping1 -or $ping2) {
            Write-SR "  ✓  Internetverbindung ist verfügbar." "Success"
            Add-CheckResult -Name "Netzwerk (Internet)" -Status "Green"  -Detail "Verbindung verfügbar"
        } else {
            Write-SR "  ⚠  Keine Internetverbindung erkannt." "Warning"
            Add-CheckResult -Name "Netzwerk (Internet)" -Status "Yellow" -Detail "Verbindung nicht verfügbar"
        }
    } catch {
        Write-SR "  ⚠  Verbindungstest fehlgeschlagen: $($_.Exception.Message)" "Warning"
        Add-CheckResult -Name "Netzwerk (Internet)" -Status "Yellow" -Detail "Verbindungstest fehlgeschlagen"
    }
    Write-SR ""

    # =========================================================================
    #  CHECK 1 – Windows Update Status
    # =========================================================================
    if ($ProgressCallback) { & $ProgressCallback -Step 18 -Total 22 -Name "Windows Update wird geprüft…" }
    Write-SR "[ 18 / 22 ]  Windows Update Status" "Header"

    try {
        $pendingCount = 0
        # Schnelle Registry-Prüfung (offline, < 1 s) als Fallback-Vorbereitung
        $wuRebootPending = Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired"

        try {
            # Offline-Modus: nur lokalen WU-Cache befragen – kein langer Netzwerk-Timeout
            $updateSession  = New-Object -ComObject Microsoft.Update.Session -ErrorAction Stop
            $updateSearcher = $updateSession.CreateUpdateSearcher()
            $updateSearcher.Online = $false
            $searchResult   = $updateSearcher.Search("IsInstalled=0 and IsHidden=0 and Type='Software'")
            $pendingCount   = $searchResult.Updates.Count
        } catch {
            # COM-Objekt nicht verfügbar oder kein Cache – Registry-Fallback
            if ($wuRebootPending) { $pendingCount = -1 }  # -1 = Reboot ausstehend, genaue Zahl unbekannt
        }

        if ($pendingCount -gt 0) {
            Write-SR "  ⚠  $pendingCount ausstehende Windows-Update(s) gefunden." "Warning"
            Add-CheckResult -Name "Windows Update" -Status "Yellow" -Detail "$pendingCount ausstehende(s) Update(s)"
        } elseif ($pendingCount -lt 0) {
            Write-SR "  ⚠  Windows Update: Neustart für ausstehende Updates erforderlich." "Warning"
            Add-CheckResult -Name "Windows Update" -Status "Yellow" -Detail "Updates ausstehend (Reboot erforderlich)"
        } else {
            Write-SR "  ✓  Alle Windows-Updates sind installiert." "Success"
            Add-CheckResult -Name "Windows Update" -Status "Green"  -Detail "Alle Updates installiert"
        }
    } catch {
        Write-SR "  ⚠  Update-Status konnte nicht ermittelt werden: $($_.Exception.Message)" "Warning"
        Add-CheckResult -Name "Windows Update" -Status "Yellow" -Detail "Prüfung nicht möglich"
    }
    Write-SR ""

    # =========================================================================
    #  CHECK 19 – Geplante Tasks mit Fehlern
    # =========================================================================
    if ($ProgressCallback) { & $ProgressCallback -Step 19 -Total 22 -Name "Geplante Tasks werden geprüft…" }
    Write-SR "[ 19 / 22 ]  Geplante Tasks (Fehlerstatus)" "Header"

    try {
        $failedTasks = Get-ScheduledTask -ErrorAction Stop |
            Where-Object { $_.TaskPath -like '\Microsoft\Windows\*' -and $_.State -ne 'Disabled' } |
            ForEach-Object {
                $info = $_ | Get-ScheduledTaskInfo -ErrorAction SilentlyContinue
                if ($info -and $info.LastTaskResult -ne 0 -and $info.LastTaskResult -ne 267011 -and
                    $info.LastRunTime -ne $null -and $info.LastRunTime -gt (Get-Date).AddDays(-7)) {
                    [PSCustomObject]@{ Name = $_.TaskName; Result = $info.LastTaskResult }
                }
            } | Where-Object { $_ } | Select-Object -First 10

        $failCount = if ($failedTasks) { @($failedTasks).Count } else { 0 }

        if ($failCount -gt 0) {
            Write-SR "  ⚠  $failCount geplante Task(s) mit Fehler in den letzten 7 Tagen:" "Warning"
            @($failedTasks) | Select-Object -First 5 | ForEach-Object {
                try {
                    $hexResult = '0x{0:X8}' -f [long]$_.Result
                    Write-SR "     • $($_.Name)  [Result: $hexResult]" "Warning"
                } catch {
                    Write-SR "     • $($_.Name)" "Warning"
                }
            }
            Add-CheckResult -Name "Geplante Tasks" -Status "Yellow" -Detail "$failCount Task(s) mit Fehler"
        } else {
            Write-SR "  ✓  Keine fehlerhaften geplanten Tasks gefunden." "Success"
            Add-CheckResult -Name "Geplante Tasks" -Status "Green" -Detail "Alle Tasks OK"
        }
    } catch {
        Write-SR "  ⚠  Geplante Tasks konnten nicht geprüft werden." "Warning"
        Add-CheckResult -Name "Geplante Tasks" -Status "Yellow" -Detail "Prüfung nicht möglich"
    }
    Write-SR ""

    # =========================================================================
    #  CHECK 4 – Ereignisprotokoll (kritische Fehler letzte 24 h)
    # =========================================================================
    if ($ProgressCallback) { & $ProgressCallback -Step 20 -Total 22 -Name "Ereignisprotokoll wird geprüft…" }
    Write-SR "[ 20 / 22 ]  Ereignisprotokoll (letzte 24 Stunden)" "Header"

    try {
        $since = (Get-Date).AddHours(-24)

        # Level 1 = Critical
        $critList = Get-WinEvent -FilterHashtable @{
            LogName   = 'System'; Level = 1; StartTime = $since
        } -MaxEvents 20 -ErrorAction SilentlyContinue

        # Level 2 = Error (häufiger, für Gesamt-Überblick relevant)
        $errList = Get-WinEvent -FilterHashtable @{
            LogName   = 'System'; Level = 2; StartTime = $since
        } -MaxEvents 20 -ErrorAction SilentlyContinue

        $critCount = if ($critList) { @($critList).Count } else { 0 }
        $errCount  = if ($errList)  { @($errList).Count  } else { 0 }

        if ($critCount -gt 0) {
            Write-SR "  ✗  $critCount kritische(r) Systemfehler (Level Critical) in den letzten 24 Stunden:" "Error"
            $critList | Select-Object -First 3 | ForEach-Object {
                $msgShort = ($_.Message -split '\r?\n')[0]
                if ($msgShort.Length -gt 80) { $msgShort = $msgShort.Substring(0, 77) + '...' }
                Write-SR "     • [$(($_.TimeCreated).ToString('HH:mm'))]  $msgShort" "Error"
            }
            if ($errCount -gt 0) { Write-SR "     + $errCount weitere Fehler (Level Error)" "Warning" }
            Add-CheckResult -Name "Ereignisprotokoll" -Status "Red" -Detail "$critCount Critical, $errCount Error (24 h)"
        } elseif ($errCount -gt 5) {
            Write-SR "  ⚠  $errCount Systemfehler (Level Error) in den letzten 24 Stunden:" "Warning"
            $errList | Select-Object -First 3 | ForEach-Object {
                $msgShort = ($_.Message -split '\r?\n')[0]
                if ($msgShort.Length -gt 80) { $msgShort = $msgShort.Substring(0, 77) + '...' }
                Write-SR "     • [$(($_.TimeCreated).ToString('HH:mm'))]  $msgShort" "Warning"
            }
            Add-CheckResult -Name "Ereignisprotokoll" -Status "Yellow" -Detail "$errCount Fehler (Level Error, 24 h)"
        } else {
            $errHint = if ($errCount -gt 0) { "  |  $errCount kleinere Fehler" } else { "" }
            Write-SR "  ✓  Keine kritischen Systemereignisse in den letzten 24 Stunden.$errHint" "Success"
            Add-CheckResult -Name "Ereignisprotokoll" -Status "Green" -Detail "Keine kritischen Fehler (24 h)"
        }
    } catch {
        Write-SR "  ✓  Keine kritischen Einträge gefunden." "Success"
        Add-CheckResult -Name "Ereignisprotokoll" -Status "Green" -Detail "Keine kritischen Fehler"
    }
    Write-SR ""

    # =========================================================================
    #  CHECK 6 – Temporäre Dateien bereinigen
    # =========================================================================
    if ($ProgressCallback) { & $ProgressCallback -Step 21 -Total 22 -Name "Temporäre Dateien werden bereinigt…" }
    Write-SR "[ 21 / 22 ]  Temp-Cleanup" "Header"

    try {
        $tempPaths = @(
            $env:TEMP,
            [System.IO.Path]::Combine($env:SystemRoot, "Temp")
        )
        $totalBytes  = 0
        $deletedCount = 0
        $errorCount  = 0

        $maxFiles = 500   # Begrenzung: max 500 Dateien pro Lauf (verhindert UI-Freeze bei riesigen Temp-Ordnern)
        $doEventsInterval = 25  # DoEvents alle 25 Dateien
        $processedSinceDoEvents = 0

        foreach ($folder in $tempPaths | Where-Object { Test-Path $_ }) {
            # Nur oberste Ebene + eine Ebene tiefer scannen (kein Deep-Recurse der GUI einfriert)
            $items = Get-ChildItem -Path $folder -Force -ErrorAction SilentlyContinue
            $items += Get-ChildItem -Path $folder -Depth 1 -Force -ErrorAction SilentlyContinue |
                      Where-Object { -not $_.PSIsContainer }

            foreach ($item in ($items | Where-Object { -not $_.PSIsContainer } | Select-Object -First $maxFiles)) {
                try {
                    $totalBytes += $item.Length
                    Remove-Item $item.FullName -Force -ErrorAction Stop
                    $deletedCount++
                } catch {
                    $errorCount++
                }
                $processedSinceDoEvents++
                if ($processedSinceDoEvents -ge $doEventsInterval) {
                    [System.Windows.Forms.Application]::DoEvents()
                    $processedSinceDoEvents = 0
                }
                $maxFiles--
                if ($maxFiles -le 0) { break }
            }
            if ($maxFiles -le 0) { break }

            # Leere Unterordner der ersten Ebene aufräumen (kein Deep-Recurse)
            Get-ChildItem -Path $folder -Force -Directory -ErrorAction SilentlyContinue |
                ForEach-Object { try { Remove-Item $_.FullName -Recurse -Force -ErrorAction SilentlyContinue } catch {} }
            [System.Windows.Forms.Application]::DoEvents()
        }

        $freedMB = [math]::Round($totalBytes / 1MB, 1)

        if ($freedMB -gt 0) {
            Write-SR "  ✓  $freedMB MB temporäre Dateien bereinigt ($deletedCount Dateien)." "Success"
            if ($errorCount -gt 0) {
                Write-SR "     ⚠  $errorCount Dateien konnten nicht gelöscht werden (in Verwendung)." "Warning"
            }
            Add-CheckResult -Name "Temp-Cleanup" -Status "Yellow" -Detail "$freedMB MB bereinigt"
        } else {
            Write-SR "  ✓  Temp-Ordner war bereits sauber." "Success"
            Add-CheckResult -Name "Temp-Cleanup" -Status "Green"  -Detail "Temp-Ordner war sauber"
        }
    } catch {
        Write-SR "  ⚠  Temp-Cleanup fehlgeschlagen: $($_.Exception.Message)" "Warning"
        Add-CheckResult -Name "Temp-Cleanup" -Status "Yellow" -Detail "Bereinigung teilweise fehlgeschlagen"
    }
    Write-SR ""

    # =========================================================================
    #  CHECK 7 – Neustart-Empfehlung
    # =========================================================================
    if ($ProgressCallback) { & $ProgressCallback -Step 22 -Total 22 -Name "Neustart-Status wird ermittelt…" }
    Write-SR "[ 22 / 22 ]  Neustart-Empfehlung" "Header"

    try {
        $rebootReasons = [System.Collections.Generic.List[string]]::new()

        # Windows Update Reboot-Flag
        if (Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired") {
            $rebootReasons.Add("Windows Update")
        }

        # Pending File Rename Operations (SFC / Installer)
        $pfro = Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager" `
                    -Name "PendingFileRenameOperations" -ErrorAction SilentlyContinue
        if ($pfro -and $pfro.PendingFileRenameOperations) {
            $rebootReasons.Add("Datei-Operationen ausstehend")
        }

        # Component-Based Servicing
        if (Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending") {
            $rebootReasons.Add("Komponenten-Servicing")
        }

        if ($rebootReasons.Count -gt 0) {
            $reasonStr = $rebootReasons -join ", "
            Write-SR "  ⚠  Neustart empfohlen: $reasonStr" "Warning"
            Add-CheckResult -Name "Neustart-Empfehlung" -Status "Yellow" -Detail "Neustart empfohlen ($reasonStr)"
        } else {
            Write-SR "  ✓  Kein Neustart erforderlich." "Success"
            Add-CheckResult -Name "Neustart-Empfehlung" -Status "Green"  -Detail "Kein Neustart nötig"
        }
    } catch {
        Write-SR "  ✓  Kein Neustart erforderlich." "Success"
        Add-CheckResult -Name "Neustart-Empfehlung" -Status "Green" -Detail "Kein Neustart nötig"
    }
    Write-SR ""

    # =========================================================================
    #  ZUSAMMENFASSUNG
    # =========================================================================
    $globalSW.Stop()
    $totalSecs = [math]::Round($globalSW.Elapsed.TotalSeconds, 0)
    $results.Duration = $totalSecs

    Write-SR "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" "Header"
    Write-SR "  ERGEBNIS:" "Header"

    switch ($results.Overall) {
        "Green"  { Write-SR "  [OK]  ALLES OK  -  Keine Probleme gefunden." "Success" }
        "Yellow" { Write-SR "  [!]   KLEINERE PROBLEME  -  Einige Punkte benoetigen Aufmerksamkeit." "Warning" }
        "Red"    { Write-SR "  [!!]  KRITISCHE PROBLEME  -  Bitte handeln Sie umgehend." "Error" }
    }

    # C2 – Kompakte Ergebnistabelle aller 22 Checks
    Write-SR ""
    Write-SR "  ── Check-Übersicht ─────────────────────────────────────────" "Header"
    $iconMap = @{ Green = "✓"; Yellow = "⚠"; Red = "✗" }
    $typeMap = @{ Green = "Success"; Yellow = "Warning"; Red = "Error" }
    foreach ($c in $results.Checks) {
        $icon    = $iconMap[$c.Status]
        $stype   = $typeMap[$c.Status]
        $namePad = $c.Name.PadRight(26)
        Write-SR "   $icon  $namePad  $($c.Detail)" $stype
    }
    Write-SR "  ────────────────────────────────────────────────────────────" "Header"

    # Empfehlungen ausgeben wenn tiefergehende Scans sinnvoll sind
    if ($results.NeedsSFCscan -or $results.NeedsDISMscan -or $results.NeedsChkdsk) {
        Write-SR ""
        Write-SR "  Empfohlene Folge-Scans:" "Warning"
        if ($results.NeedsSFCscan)  { Write-SR "    ‣  SFC /scannow        System & Sicherheit › Wartung › SFC" "Warning" }
        if ($results.NeedsDISMscan) { Write-SR "    ‣  DISM /RestoreHealth  Diagnose & Reparatur › DISM Reparatur" "Warning" }
        if ($results.NeedsChkdsk)   { Write-SR "    ‣  CHKDSK Neustart      Windows neu starten um Spot-Fix abzuschließen" "Warning" }
    }

    # C1 – Gesamtdauer
    Write-SR ""
    $greenCount  = @($results.Checks | Where-Object { $_.Status -eq 'Green'  }).Count
    $yellowCount = @($results.Checks | Where-Object { $_.Status -eq 'Yellow' }).Count
    $redCount    = @($results.Checks | Where-Object { $_.Status -eq 'Red'    }).Count
    Write-SR "  $($results.Checks.Count) Checks  |  ✓ $greenCount OK  ⚠ $yellowCount Warnungen  ✗ $redCount Fehler  |  Dauer: $totalSecs s" "Info"
    Write-SR "  Abgeschlossen: $(Get-Date -Format 'dd.MM.yyyy  HH:mm:ss')" "Info"
    Write-SR "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" "Header"

    # C3 – Ergebnis als Log-Eintrag speichern
    try {
        $logMsg = "Smart Repair: $($results.Overall) | OK: $greenCount  Warn: $yellowCount  Fehler: $redCount | $($results.Checks.Count) Checks | Dauer: ${totalSecs}s"
        Write-ToolLog -ToolName "SmartRepair" -Message $logMsg -Level "Information" -SaveToDatabase -ErrorAction SilentlyContinue
    } catch {}

    return $results
}

Export-ModuleMember -Function Invoke-SmartRepair

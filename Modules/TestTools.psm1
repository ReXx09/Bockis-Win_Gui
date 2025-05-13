# Neues Modul für Test-Funktionen

# Import-Module für ProgressBarTools
Import-Module "$PSScriptRoot\Core\ProgressBarTools.psm1" -Force

function Start-SystemTest {
    param (
        [System.Windows.Forms.RichTextBox]$outputBox,
        [System.Windows.Forms.ProgressBar]$progressBar,
        [string]$testType
    )
    
    try {
        # Initialisiere die ProgressBar
        Initialize-ProgressComponents -ProgressBar $progressBar -StatusLabel $null
        
        # Test-Header
        $outputBox.Clear()
        $outputBox.SelectionColor = [System.Drawing.Color]::Blue
        $outputBox.AppendText("===== SYSTEM TOOL TEST =====`r`n")
        $outputBox.AppendText("Test: $testType`r`n")
        $outputBox.AppendText("Zeitstempel: $(Get-Date -Format 'dd.MM.yyyy HH:mm:ss')`r`n`r`n")
        
        # Progressbar initialisieren
        $progressBar.Value = 0
        Update-ProgressStatus -StatusText "Test wird vorbereitet..." -ProgressValue 0 -TextColor ([System.Drawing.Color]::DarkBlue) -progressBarParam $progressBar
        
        switch ($testType) {
            "MRT" {
                Test-MRTFunction -outputBox $outputBox -progressBar $progressBar
            }
            "SFC" {
                Test-SFCFunction -outputBox $outputBox -progressBar $progressBar
            }
            "MemoryDiagnostic" {
                Test-MemoryDiagnostic -outputBox $outputBox -progressBar $progressBar
            }
            "WindowsDefender" {
                Test-WindowsDefender -outputBox $outputBox -progressBar $progressBar
            }
            default {
                throw "Unbekannter Testtyp: $testType"
            }
        }
    }
    catch {
        $outputBox.SelectionColor = [System.Drawing.Color]::Red
        $outputBox.AppendText("[-] Fehler beim Ausführen des Tests: $_`r`n")
    }
}

function Test-MRTFunction {
    param (
        [System.Windows.Forms.RichTextBox]$outputBox,
        [System.Windows.Forms.ProgressBar]$progressBar
    )
    
    try {
        # EICAR Test
        $outputBox.SelectionColor = [System.Drawing.Color]::Blue
        $outputBox.AppendText("[>] Starte MRT-Erkennungstest...`r`n")
        Update-ProgressStatus -StatusText "Erstelle EICAR-Testdatei..." -ProgressValue 20 -TextColor ([System.Drawing.Color]::Blue) -progressBarParam $progressBar
        
        # EICAR-String
        $eicarString = 'X5O!P%@AP[4\PZX54(P^)7CC)7}$EICAR-STANDARD-ANTIVIRUS-TEST-FILE!$H+H*'
        $testDir = "$env:TEMP\MRTTest"
        $eicarFile = "$testDir\eicar.com"
        
        # Testverzeichnis erstellen
        if (-not (Test-Path $testDir)) {
            New-Item -ItemType Directory -Path $testDir | Out-Null
        }
        
        # EICAR-Datei erstellen
        [System.IO.File]::WriteAllText($eicarFile, $eicarString)
        Update-ProgressStatus -StatusText "Führe MRT-Scan durch..." -ProgressValue 40 -TextColor ([System.Drawing.Color]::Blue) -progressBarParam $progressBar
        
        # MRT-Scan durchführen
        $mrtPath = "$env:windir\System32\mrt.exe"
        $process = Start-Process -FilePath $mrtPath -ArgumentList "/F /Directory $testDir" -NoNewWindow -PassThru -Wait
        
        Update-ProgressStatus -StatusText "Analysiere Ergebnisse..." -ProgressValue 80 -TextColor ([System.Drawing.Color]::Blue) -progressBarParam $progressBar
        
        # Ergebnisse auswerten
        switch ($process.ExitCode) {
            1 { 
                $outputBox.SelectionColor = [System.Drawing.Color]::Green
                $outputBox.AppendText("[✓] Test erfolgreich - Malware-Erkennung funktioniert`r`n")
            }
            0 {
                $outputBox.SelectionColor = [System.Drawing.Color]::Red
                $outputBox.AppendText("[!] Test fehlgeschlagen - Keine Erkennung`r`n")
            }
            default {
                $outputBox.SelectionColor = [System.Drawing.Color]::Yellow
                $outputBox.AppendText("[?] Unerwartetes Ergebnis (Code: $($process.ExitCode))`r`n")
            }
        }
    }
    finally {
        # Aufräumen
        if (Test-Path $eicarFile) { Remove-Item -Path $eicarFile -Force }
        if (Test-Path $testDir) { Remove-Item -Path $testDir -Force -Recurse }
        Update-ProgressStatus -StatusText "Test abgeschlossen" -ProgressValue 100 -TextColor ([System.Drawing.Color]::Green) -progressBarParam $progressBar
    }
}

function Test-SFCFunction {
    param (
        [System.Windows.Forms.RichTextBox]$outputBox,
        [System.Windows.Forms.ProgressBar]$progressBar
    )
    
    try {
        $outputBox.SelectionColor = [System.Drawing.Color]::Blue
        $outputBox.AppendText("[>] Starte SFC-Test...`r`n")
        Update-ProgressStatus -StatusText "Prüfe SFC-Verfügbarkeit..." -ProgressValue 20 -TextColor ([System.Drawing.Color]::Blue) -progressBarParam $progressBar
        
        # Test-Datei erstellen
        $testFile = "$env:windir\System32\test_sfc.txt"
        "Test" | Out-File -FilePath $testFile
        
        Update-ProgressStatus -StatusText "Führe SFC-Verifizierung durch..." -ProgressValue 50 -TextColor ([System.Drawing.Color]::Blue) -progressBarParam $progressBar
        
        # SFC-Verify durchführen
        $process = Start-Process -FilePath "sfc.exe" -ArgumentList "/verifyfile=$testFile" -NoNewWindow -PassThru -Wait
        
        if ($process.ExitCode -eq 0) {
            $outputBox.SelectionColor = [System.Drawing.Color]::Green
            $outputBox.AppendText("[✓] SFC-Test erfolgreich`r`n")
        }
        else {
            $outputBox.SelectionColor = [System.Drawing.Color]::Red
            $outputBox.AppendText("[!] SFC-Test fehlgeschlagen`r`n")
        }
    }
    finally {
        if (Test-Path $testFile) { Remove-Item -Path $testFile -Force }
        Update-ProgressStatus -StatusText "Test abgeschlossen" -ProgressValue 100 -TextColor ([System.Drawing.Color]::Green) -progressBarParam $progressBar
    }
}

function Test-MemoryDiagnostic {
    param (
        [System.Windows.Forms.RichTextBox]$outputBox,
        [System.Windows.Forms.ProgressBar]$progressBar
    )
    
    try {
        $outputBox.SelectionColor = [System.Drawing.Color]::Blue
        $outputBox.AppendText("[>] Prüfe Memory Diagnostic Tool...`r`n")
        Update-ProgressStatus -StatusText "Prüfe Verfügbarkeit..." -ProgressValue 30 -TextColor ([System.Drawing.Color]::Blue) -progressBarParam $progressBar
        
        # Prüfe ob MdSched.exe existiert
        if (Test-Path "$env:windir\System32\MdSched.exe") {
            $outputBox.SelectionColor = [System.Drawing.Color]::Green
            $outputBox.AppendText("[✓] Memory Diagnostic Tool verfügbar`r`n")
            
            # Prüfe letzte Ausführung
            $eventLog = Get-WinEvent -FilterHashtable @{
                LogName      = 'System'
                ID           = 1101
                ProviderName = 'Microsoft-Windows-MemoryDiagnostics-Results'
            } -MaxEvents 1 -ErrorAction SilentlyContinue
            
            if ($eventLog) {
                $outputBox.SelectionColor = [System.Drawing.Color]::Blue
                $outputBox.AppendText("[i] Letzter Memory Test: $($eventLog[0].TimeCreated)`r`n")
                $outputBox.AppendText("[i] Ergebnis: $($eventLog[0].Message)`r`n")
            }
        }
        else {
            $outputBox.SelectionColor = [System.Drawing.Color]::Red
            $outputBox.AppendText("[!] Memory Diagnostic Tool nicht gefunden`r`n")
        }
    }
    finally {
        Update-ProgressStatus -StatusText "Test abgeschlossen" -ProgressValue 100 -TextColor ([System.Drawing.Color]::Green) -progressBarParam $progressBar
    }
}

function Test-WindowsDefender {
    param (
        [System.Windows.Forms.RichTextBox]$outputBox,
        [System.Windows.Forms.ProgressBar]$progressBar
    )
    
    try {
        $outputBox.SelectionColor = [System.Drawing.Color]::Blue
        $outputBox.AppendText("[>] Prüfe Windows Defender Status...`r`n")
        Update-ProgressStatus -StatusText "Prüfe Defender-Status..." -ProgressValue 25 -TextColor ([System.Drawing.Color]::Blue) -progressBarParam $progressBar
        
        # Prüfe Defender-Status
        $defenderStatus = Get-MpComputerStatus
        
        if ($defenderStatus.AntivirusEnabled) {
            $outputBox.SelectionColor = [System.Drawing.Color]::Green
            $outputBox.AppendText("[✓] Windows Defender ist aktiv`r`n")
            $outputBox.AppendText("[i] Definitionen: $($defenderStatus.AntivirusSignatureVersion)`r`n")
            $outputBox.AppendText("[i] Letzter Scan: $($defenderStatus.LastFullScanTime)`r`n")
        }
        else {
            $outputBox.SelectionColor = [System.Drawing.Color]::Red
            $outputBox.AppendText("[!] Windows Defender ist deaktiviert`r`n")
        }
    }
    finally {
        Update-ProgressStatus -StatusText "Test abgeschlossen" -ProgressValue 100 -TextColor ([System.Drawing.Color]::Green) -progressBarParam $progressBar
    }
} 
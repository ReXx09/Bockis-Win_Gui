# LogManager.psm1
# Modul für zentralisierte Logging-Funktionen

# Globale Variablen für das Logging
# WICHTIG: Logs werden zentral im Data-Ordner der GUI gespeichert
$script:logDirectory = Join-Path $PSScriptRoot "..\..\Data\Logs"
$script:maxLogSize = 5MB  # Maximale Logfile-Größe (5 MB)
$script:maxLogAge = 30    # Maximales Alter der Logs in Tagen

# Funktion zum Sicherstellen, dass das Log-Verzeichnis existiert
function Initialize-LogDirectory {
    # Stelle sicher, dass das Log-Verzeichnis existiert
    if (-not (Test-Path $script:logDirectory)) {
        New-Item -ItemType Directory -Path $script:logDirectory -Force | Out-Null
        Write-Verbose "Log-Verzeichnis erstellt: $script:logDirectory"
    }

    # Alte Logs bereinigen
    Remove-OldLogs
}

# Funktion zum Bereinigen alter Logs
function Remove-OldLogs {
    try {
        $oldLogs = Get-ChildItem -Path $script:logDirectory -Filter "*.log" | 
        Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-$script:maxLogAge) }
        
        foreach ($log in $oldLogs) {
            Remove-Item -Path $log.FullName -Force -ErrorAction SilentlyContinue
            Write-Verbose "Altes Log entfernt: $($log.Name)"
        }
    }
    catch {
        Write-Warning "Fehler beim Bereinigen der alten Logs: $_"
    }
}

# Interne Funktion zum Schreiben von Logs für Tools
# HINWEIS: Diese Funktion wird intern verwendet. Externe Aufrufe verwenden die globale Version.
function Write-ToolLogInternal {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ToolName,
        
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [ValidateSet('Information', 'Warning', 'Error', 'Success')]
        [string]$Level = 'Information',
        
        [switch]$NoTimestamp,
        
        [switch]$CreateNew,
        
        [object]$OutputBox,  # Geändert von [System.Windows.Forms.RichTextBox] zu [object] für bessere Kompatibilität
        
        [object]$Color,  # Geändert von [System.Drawing.Color] zu [object] für bessere Kompatibilität
        
        [string]$Style,
        
        [switch]$SaveToDatabase
    )
    
    # Log-Verzeichnis initialisieren
    Initialize-LogDirectory
    
    # Logfile-Name basierend auf dem Tool-Namen festlegen
    $sanitizedToolName = $ToolName -replace '[\\/:*?"<>|]', '_'
    $logFileName = "$sanitizedToolName.log"
    $logPath = Join-Path $script:logDirectory $logFileName
    
    # Bei Bedarf neues Log erstellen
    if ($CreateNew -and (Test-Path $logPath)) {
        Rename-Item -Path $logPath -NewName "$sanitizedToolName-$(Get-Date -Format 'yyyyMMdd-HHmmss').log" -Force
    }
    
    # Log-Eintrag formatieren
    $timestamp = if (-not $NoTimestamp) { "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - " } else { "" }
    $levelPrefix = switch ($Level) {
        'Information' { 'INFO' }
        'Warning' { 'WARN' }
        'Error' { 'ERROR' }
        'Success' { 'SUCCESS' }
    }
    
    $logEntry = "$timestamp[$levelPrefix] $Message"
    try {
        # Prüfe Log-Dateigröße
        if ((Test-Path $logPath) -and ((Get-Item $logPath).Length -gt $script:maxLogSize)) {
            # Bei Überschreitung der maximalen Größe, alten Log umbenennen
            Rename-Item -Path $logPath -NewName "$sanitizedToolName-$(Get-Date -Format 'yyyyMMdd-HHmmss').log" -Force
        }
        
        # Log-Eintrag mit verbesserten Locking-Mechanismus und Cloud-Sync-Erkennung schreiben
        $retryCount = 0
        $maxRetries = 3  # Reduziert von 5 auf 3 für schnelleres Fail-Fast
        $delay = 100     # Reduziert von 200ms auf 100ms
        $success = $false
        
        do {
            try {
                # Verwenden von [System.IO.File]::AppendAllText() für bessere Dateiverarbeitung
                [System.IO.File]::AppendAllText($logPath, "$logEntry`r`n", [System.Text.Encoding]::UTF8)
                $success = $true
                break
            }
            catch {
                $retryCount++
                $errorMessage = $_.Exception.Message
                
                # Prüfe auf spezifische Cloud-Provider-Fehler
                $isCloudError = $errorMessage -match "Clouddateianbieter" -or 
                                $errorMessage -match "cloud file provider" -or
                                $errorMessage -match "STATUS_CLOUD_FILE_PROVIDER_NOT_RUNNING"
                
                if ($retryCount -ge $maxRetries) {
                    if ($isCloudError) {
                        # Bei Cloud-Fehler nur eine kurze Warnung ausgeben
                        Write-Verbose "Cloud-Sync nicht verfügbar für Log '$ToolName' - Log wird übersprungen"
                    }
                    else {
                        # Andere Fehler weiterhin ausgeben
                        Write-Warning "Konnte nicht auf Log-Datei $logPath zugreifen nach $maxRetries Versuchen: $_"
                    }
                    break  # Nicht mehr werfen, sondern graceful fortfahren
                }
                Start-Sleep -Milliseconds $delay
                $delay *= 1.5 # Erhöhe Wartezeit mit jedem Versuch
            }
        } while ($retryCount -lt $maxRetries)
        # Wenn OutputBox angegeben wurde, auch dort anzeigen
        if ($OutputBox) {
            # Bestimme Style basierend auf explizitem Style-Parameter oder Level
            $styleKey = if ($Style) { 
                $Style 
            } else {
                switch ($Level) {
                    'Error' { 'Error' }
                    'Warning' { 'Warning' }
                    'Success' { 'Success' }
                    default { 'Info' }
                }
            }
            
            # Verwende Set-OutputSelectionStyle wenn verfügbar
            if (Get-Command -Name Set-OutputSelectionStyle -ErrorAction SilentlyContinue) {
                Set-OutputSelectionStyle -OutputBox $OutputBox -Style $styleKey
            }
            elseif ($Color -ne $null) {
                # Fallback auf Color-Parameter
                $originalColor = $OutputBox.SelectionColor
                $OutputBox.SelectionColor = $Color
            }
            
            $OutputBox.AppendText("$Message`r`n")
            
            # Stelle ursprüngliche Farbe wieder her, falls Color verwendet wurde
            if ($Color -ne $null -and -not (Get-Command -Name Set-OutputSelectionStyle -ErrorAction SilentlyContinue)) {
                $OutputBox.SelectionColor = $originalColor
            }
        }
        
        # In Datenbank speichern, wenn gewünscht
        if ($SaveToDatabase -and (Get-Command -Name Save-LogToDatabase -ErrorAction SilentlyContinue)) {
            try {
                Save-LogToDatabase -ToolName $ToolName -Message $Message -Level $Level
            }
            catch {
                Write-Verbose "Fehler beim Speichern in der Datenbank für '$ToolName': $_"
            }
        }
        
        return $success
    }
    catch {
        $errorMessage = $_.Exception.Message
        $isCloudError = $errorMessage -match "Clouddateianbieter" -or 
                        $errorMessage -match "cloud file provider" -or
                        $errorMessage -match "STATUS_CLOUD_FILE_PROVIDER_NOT_RUNNING"
        
        if ($isCloudError) {
            Write-Verbose "Cloud-Sync nicht verfügbar für Log '$ToolName' - Log wird übersprungen"
        }
        else {
            Write-Warning "Fehler beim Schreiben des Logs für '$ToolName': $_"
        }
        return $false
    }
}

# Funktion zum Abrufen des Inhalts eines bestimmten Logs
function Get-ToolLog {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ToolName
    )
    
    $sanitizedToolName = $ToolName -replace '[\\/:*?"<>|]', '_'
    $logFileName = "$sanitizedToolName.log"
    $logPath = Join-Path $script:logDirectory $logFileName
    
    if (Test-Path $logPath) {
        return Get-Content -Path $logPath -Encoding UTF8
    }
    
    return $null
}

# Funktion zum Löschen eines bestimmten Logs
function Clear-ToolLog {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ToolName
    )
    
    $sanitizedToolName = $ToolName -replace '[\\/:*?"<>|]', '_'
    $logFileName = "$sanitizedToolName.log"
    $logPath = Join-Path $script:logDirectory $logFileName
    
    if (Test-Path $logPath) {
        Remove-Item -Path $logPath -Force
        return $true
    }
    
    return $false
}

# Funktion zum Abrufen einer Liste aller verfügbaren Logs
function Get-AvailableLogs {
    Initialize-LogDirectory
    
    $logs = Get-ChildItem -Path $script:logDirectory -Filter "*.log" | 
    Select-Object @{Name = "ToolName"; Expression = { $_.BaseName } },
    @{Name = "LastWriteTime"; Expression = { $_.LastWriteTime } },
    @{Name = "Size"; Expression = { $_.Length } }
    
    return $logs
}

# Funktion zum Speichern von Logs in der Datenbank
function Save-LogToDatabase {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ToolName,
        
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [ValidateSet('Information', 'Warning', 'Error', 'Success')]
        [string]$Level = 'Information'
    )
    
    try {
        # Prüfe, ob das DatabaseManager-Modul verfügbar ist
        if (Get-Module -Name DatabaseManager -ErrorAction SilentlyContinue) {
            # Prüfe, ob die benötigte Funktion existiert
            if (Get-Command -Name Add-LogEntry -ErrorAction SilentlyContinue) {
                # Datenbank-Eintrag erstellen
                Add-LogEntry -ToolName $ToolName -Message $Message -Level $Level
                return $true
            }
        }
        
        # Wenn die Funktion nicht gefunden wurde, aber das Modul existiert, versuchen wir es zu importieren
        if (Get-Module -ListAvailable -Name DatabaseManager -ErrorAction SilentlyContinue) {
            Import-Module "$PSScriptRoot\..\DatabaseManager.psm1" -Force
            
            if (Get-Command -Name Add-LogEntry -ErrorAction SilentlyContinue) {
                # Datenbank-Eintrag erstellen
                Add-LogEntry -ToolName $ToolName -Message $Message -Level $Level
                return $true
            }
        }
        
        # Falls die Funktion immer noch nicht gefunden wurde
        Write-Warning "Die Funktion 'Add-LogEntry' zum Speichern in der Datenbank wurde nicht gefunden."
        return $false
    }
    catch {
        Write-Warning "Fehler beim Speichern des Logs in der Datenbank: $_"
        return $false
    }
}

# Funktion zum Speichern von GUI-Closing-Logs
function Write-GuiClosingLog {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [ValidateSet('Information', 'Warning', 'Error', 'Success')]
        [string]$Level = 'Information',
        
        [switch]$IsError
    )
    
    # GUI-Closing-Logs werden in einer separaten Datei gespeichert
    $toolName = "GUI-Closing"
    # Verwende die interne Write-ToolLogInternal Funktion
    try {
        Write-ToolLogInternal -ToolName $toolName -Message $Message -Level $Level -NoTimestamp:$false
        return $true
    }
    catch {
        Write-Warning "Fehler beim Schreiben des GUI-Closing-Logs: $_"
        return $false
    }
}

# Funktion zum Initialisieren der GUI-Closing-Log-Datei
function Initialize-GuiClosingLog {
    param (
        [string]$CustomPath = $null
    )
    
    # Bestimme den Log-Pfad
    $logPath = if ($CustomPath) { 
        $CustomPath 
    }
    else { 
        Join-Path $script:logDirectory "GUI-Closing.log" 
    }
    
    # Stelle sicher, dass das Verzeichnis existiert
    $logDir = Split-Path -Parent $logPath
    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }
    
    # Erstelle Header für die Log-Datei, falls sie nicht existiert
    if (-not (Test-Path $logPath)) {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        @"
=== System-Tool GUI Closing Log ===
Erstellt am: $timestamp
Automatisch verwaltet durch LogManager
=====================================

"@ | Out-File -FilePath $logPath -Encoding UTF8
    }
    
    return $logPath
}

# Funktion zum Abrufen der GUI-Closing-Logs
function Get-GuiClosingLog {
    param (
        [int]$LastEntries = 50
    )
    
    $logContent = Get-ToolLog -ToolName "GUI-Closing"
    
    if ($logContent -and $LastEntries -gt 0) {
        # Gib nur die letzten N Einträge zurück
        $logContent | Select-Object -Last $LastEntries
    }
    else {
        return $logContent
    }
}

# Module-Member exportieren
# HINWEIS: Write-ToolLog wird NICHT exportiert, da es eine globale Version im Hauptskript gibt
# Die globale Version überschreibt diese Modul-Version nach dem Import
Export-ModuleMember -Function Get-ToolLog, Clear-ToolLog, Get-AvailableLogs, Initialize-LogDirectory, Save-LogToDatabase, Write-GuiClosingLog, Initialize-GuiClosingLog, Get-GuiClosingLog

# SIG # Begin signature block
# MIIcSgYJKoZIhvcNAQcCoIIcOzCCHDcCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCiovo3BVmp8JQA
# a9xrQWA1j7+62uMkENwDptyQyRgRVKCCFnowggM8MIICJKADAgECAhBJfyGrXBJT
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
# MQ4wDAYKKwYBBAGCNwIBFTAvBgkqhkiG9w0BCQQxIgQgFSQ5DLlwod1YEzCLZemy
# kPCaMtpmDIezhU6+QrJn6BwwDQYJKoZIhvcNAQEBBQAEggEAEUuXhxQaGrNTiWPy
# OlnTdxnyqau3HSYwbKQheAHgLX9fw9j/CdaaGerHWTrKfwHH/wmxcbJaYI4KocVP
# uZStc3I4M5RMqQJGnMBuRclMv9f9bxOWyusWHbdn44C8Akt+4l+vlM7FU9E80nq0
# yLyI3wmaBHQj5RUPOnz+Pc4M45tgu8Q1Go5W9LcvFJantyocDBQhhtU2rbQSgjxz
# ZxYcWbiISRXnK54aPC5QbXjnXKwLpHml2Nb3RU+6pMB+Q0HqQaSeVeHZvIBWumst
# ykTzSI8QZ6fCPX16Y2w47csskx9S2Ba7ZhwxhfMVtVnYEes0OlxzwrlF1QVAtzp9
# 8Iaj3aGCAyYwggMiBgkqhkiG9w0BCQYxggMTMIIDDwIBATB9MGkxCzAJBgNVBAYT
# AlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5jLjFBMD8GA1UEAxM4RGlnaUNlcnQg
# VHJ1c3RlZCBHNCBUaW1lU3RhbXBpbmcgUlNBNDA5NiBTSEEyNTYgMjAyNSBDQTEC
# EAqA7xhLjfEFgtHEdqeVdGgwDQYJYIZIAWUDBAIBBQCgaTAYBgkqhkiG9w0BCQMx
# CwYJKoZIhvcNAQcBMBwGCSqGSIb3DQEJBTEPFw0yNjAxMjAxODAyNTNaMC8GCSqG
# SIb3DQEJBDEiBCAKZHDfE8VPdIAXKVHUAG4fb9YAIURgTykW4q7u/jtGfTANBgkq
# hkiG9w0BAQEFAASCAgB7flx/nzwA8Q3dQTVS/f0g9FAIFCsO7p/x2S9ZyLjXO79Y
# 4HP0zsLN7uSehgTs68YPSbAgFCdi7hek5rCq/4ip2/qaoitvX1jKZ8/GvJsqGuM0
# vbnKs9vPufoMrmaky2tw0EC7/9/0taChZPKSYtFtvXdBg/CpcHLUqZH50KWGPOR+
# diJrGePgqN+vdNlgpepPgUfwx9GxmwXNHEL4hW0PGwlWtRqK/FU9Mw+m6WPR/dJS
# CN4dNA4IsLl0eiW8Z76NhYli+vgCz7eFTeQc3Ni31fszXAi/2CQkWIsMubFhRTDm
# 0Pw1HUOOEwq/noHj8z1W7ssBVFYpVPjXXqSv4KD62tjqbVTDUI2tF+DqqcSdEXCm
# ozhpsYIWd1OyWnui80d79J6UOLzil6/VuDkg50Me39Q0kuZSCNeABJized/wS/9J
# 45ru4HXpTJVh5eQixVPjFiy5MuftKoZPlZuCcVKqqVojwG/VBaArvdxh4eHbaueL
# p5oE/ZvmC6M1U6lqSuZMq5HIkaUcFsSkhDhBkELbyqpdsdhAvLhxM03GK22ZD58U
# IgfC+xN2JqJgqAF1E9LRIFnG8o1KciYVl5Tw2//9gSOcUFx+nZtNkvGK7i0BpYBL
# gv/YGmNuvJgO/3A0/5lujbg6giD+VOBwvyc+iIq6fJcCM68RS3Bp5v7Kc54Kmw==
# SIG # End signature block

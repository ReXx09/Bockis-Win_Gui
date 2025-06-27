# LogManager.psm1
# Modul für zentralisierte Logging-Funktionen

# Globale Variablen für das Logging
$script:logDirectory = Join-Path $PSScriptRoot "..\..\Logs"
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

# Hauptfunktion zum Schreiben von Logs für Tools
function Write-ToolLog {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ToolName,
        
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [ValidateSet('Information', 'Warning', 'Error', 'Success')]
        [string]$Level = 'Information',
        
        [switch]$NoTimestamp,
        
        [switch]$CreateNew,
        
        [System.Windows.Forms.RichTextBox]$OutputBox,
        
        [System.Drawing.Color]$Color,
        
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
        
        # Log-Eintrag mit verbesserten Locking-Mechanismus schreiben
        $retryCount = 0
        $maxRetries = 5
        $delay = 200 # Millisekunden Wartezeit zwischen Versuchen
        
        do {
            try {
                # Verwenden von [System.IO.File]::AppendAllText() für bessere Dateiverarbeitung
                [System.IO.File]::AppendAllText($logPath, "$logEntry`r`n", [System.Text.Encoding]::UTF8)
                $success = $true
                break
            }
            catch {
                $retryCount++
                if ($retryCount -ge $maxRetries) {
                    Write-Warning "Konnte nicht auf Log-Datei $logPath zugreifen nach $maxRetries Versuchen: $_"
                    throw $_
                }
                Start-Sleep -Milliseconds $delay
                $delay *= 1.5 # Erhöhe Wartezeit mit jedem Versuch
            }
        } while ($retryCount -lt $maxRetries)
        # Wenn OutputBox angegeben wurde, auch dort anzeigen
        if ($OutputBox) {
            if ($Color -ne $null) {
                $originalColor = $OutputBox.SelectionColor
                $OutputBox.SelectionColor = $Color
                $OutputBox.AppendText("$Message`r`n")
                $OutputBox.SelectionColor = $originalColor
            }
            else {
                $OutputBox.AppendText("$Message`r`n")
            }
        }
        
        # In Datenbank speichern, wenn gewünscht
        if ($SaveToDatabase -and (Get-Command -Name Save-LogToDatabase -ErrorAction SilentlyContinue)) {
            try {
                Save-LogToDatabase -ToolName $ToolName -Message $Message -Level $Level
            }
            catch {
                Write-Warning "Fehler beim Speichern in der Datenbank für '$ToolName': $_"
            }
        }
        
        return $true
    }
    catch {
        Write-Warning "Fehler beim Schreiben des Logs für '$ToolName': $_"
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
    # Verwende die bestehende Write-ToolLog Funktion ohne problematische Color-Parameter
    try {
        Write-ToolLog -ToolName $toolName -Message $Message -Level $Level -NoTimestamp:$false
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
Export-ModuleMember -Function Write-ToolLog, Get-ToolLog, Clear-ToolLog, Get-AvailableLogs, Initialize-LogDirectory, Save-LogToDatabase, Write-GuiClosingLog, Initialize-GuiClosingLog, Get-GuiClosingLog

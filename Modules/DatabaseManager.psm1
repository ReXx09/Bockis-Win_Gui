# DatabaseManager.psm1 - Database Management for WinGuiTools

function Initialize-Database {
    $dllPath = Join-Path $PSScriptRoot "..\Lib\System.Data.SQLite.dll"
    try {
        Write-Verbose "Versuche DLL zu laden: $dllPath"
        if (-not (Test-Path $dllPath)) {
            Write-Error "DLL-Datei nicht gefunden: $dllPath"
            return $null
        }
        
        # Prüfen, ob die DLL bereits geladen ist, um doppelte Lade-Versuche zu vermeiden
        if (-not ([System.AppDomain]::CurrentDomain.GetAssemblies() | Where-Object { $_.Location -eq $dllPath })) {
            try {
                Add-Type -Path $dllPath -ErrorAction Stop
                Write-Verbose "SQLite DLL erfolgreich geladen"
            }
            catch {
                Write-Error "Fehler beim Laden der DLL: $_"
                return $null
            }
        }
        
        $dbPath = Join-Path $env:APPDATA "WinGuiTools\system_data.db"
        $dbDirectory = Split-Path -Parent $dbPath
        if (-not (Test-Path $dbDirectory)) {
            New-Item -ItemType Directory -Path $dbDirectory -Force | Out-Null
        }
        
        # Verbindung erstellen und öffnen
        $connectionString = "Data Source=$dbPath;Version=3;"
        $connection = New-Object -TypeName System.Data.SQLite.SQLiteConnection -ArgumentList $connectionString
        
        if (-not $connection) {
            Write-Error "Konnte kein SQLite-Verbindungsobjekt erstellen"
            return $null
        }
        
        $connection.Open()
        
        if ($connection.State -ne [System.Data.ConnectionState]::Open) {
            Write-Error "Konnte keine Verbindung zur SQLite-Datenbank herstellen"
            return $null
        }
        
        # Tabellen erstellen, falls sie noch nicht existieren
        $createTableCmd = $connection.CreateCommand()
        $createTableCmd.CommandText = @"
CREATE TABLE IF NOT EXISTS SystemSnapshots (
    Id INTEGER PRIMARY KEY AUTOINCREMENT,
    Timestamp TEXT NOT NULL,
    CPUUsage REAL,
    MemoryUsage REAL,
    DiskSpace TEXT,
    Temperature REAL,
    SnapshotData TEXT
);
CREATE TABLE IF NOT EXISTS DiagnosticResults (
    Id INTEGER PRIMARY KEY AUTOINCREMENT,
    ToolName TEXT NOT NULL,
    ExecutionTime TEXT NOT NULL,
    Result TEXT,
    ExitCode INTEGER,
    Details TEXT
);
CREATE TABLE IF NOT EXISTS HardwareHistory (
    Id INTEGER PRIMARY KEY AUTOINCREMENT,
    Timestamp TEXT NOT NULL,
    HardwareType TEXT NOT NULL,
    ComponentName TEXT NOT NULL,
    SensorType TEXT NOT NULL,
    SensorName TEXT NOT NULL,
    Value REAL,
    Unit TEXT
);
"@
        # Tabellen erstellen
        $null = $createTableCmd.ExecuteNonQuery()
        # Verbindung als einzelnes Objekt zurückgeben (kein Pipeline-Output!)
        # Das [PSCustomObject] verhindert die Pipeline-Sammlung und Array-Bildung
        return $connection
    }
    catch {
        Write-Error "Fehler bei der Datenbankinitialisierung: $_"
        return $null
    }
}

function Save-DiagnosticResult {
    param(
        [System.Data.SQLite.SQLiteConnection]$connection,
        [string]$toolName,
        [string]$result,
        [int]$exitCode,
        [string]$details
    )
    try {
        $cmd = $connection.CreateCommand()
        $cmd.CommandText = "INSERT INTO DiagnosticResults (ToolName, ExecutionTime, Result, ExitCode, Details) VALUES (?, ?, ?, ?, ?)"
        $cmd.Parameters.Add((New-Object System.Data.SQLite.SQLiteParameter("", $toolName))) | Out-Null
        $cmd.Parameters.Add((New-Object System.Data.SQLite.SQLiteParameter("", (Get-Date -Format "yyyy-MM-dd HH:mm:ss")))) | Out-Null
        $cmd.Parameters.Add((New-Object System.Data.SQLite.SQLiteParameter("", $result))) | Out-Null
        $cmd.Parameters.Add((New-Object System.Data.SQLite.SQLiteParameter("", $exitCode))) | Out-Null
        $cmd.Parameters.Add((New-Object System.Data.SQLite.SQLiteParameter("", $details))) | Out-Null
        $cmd.ExecuteNonQuery() | Out-Null
        return $true
    }
    catch {
        Write-Error "Error saving diagnostic result: $_"
        return $false
    }
}

function Close-Database {
    param(
        [System.Data.SQLite.SQLiteConnection]$connection
    )
    if ($connection -ne $null -and $connection.State -eq [System.Data.ConnectionState]::Open) {
        $connection.Close()
        $connection.Dispose()
    }
}

# Additional helper functions for integration with the main script
function Save-DiagnosticToDatabase {
    param(
        [string]$ToolName,
        [string]$Result,
        [int]$ExitCode,
        [string]$Details
    )
    if ($script:dbConnection) {
        Save-DiagnosticResult -connection $script:dbConnection -toolName $ToolName -result $Result -exitCode $ExitCode -details $Details
    }
}

function Close-SystemDatabase {
    if ($script:dbConnection) {
        Close-Database -connection $script:dbConnection
        $script:dbConnection = $null
    }
}

function Add-LogEntry {
    param(
        [string]$ToolName,
        [string]$Message,
        [string]$Level = "Information"
    )
    try {
        # Stellen sicher, dass die SQLite-DLL geladen wurde
        $dllPath = Join-Path $PSScriptRoot "..\Lib\System.Data.SQLite.dll"
        if (-not ([System.AppDomain]::CurrentDomain.GetAssemblies() | Where-Object { $_.Location -eq $dllPath })) {
            try {
                Add-Type -Path $dllPath
                Write-Verbose "SQLite DLL geladen: $dllPath"
            }
            catch {
                Write-Error "Fehler beim Laden der SQLite DLL: $_"
                return $false
            }
        }        # Nutze die globale Verbindung, falls vorhanden und gültig
        if ($script:dbConnection -and 
            ($script:dbConnection -is [System.Data.SQLite.SQLiteConnection]) -and 
            ($script:dbConnection.State -eq [System.Data.ConnectionState]::Open)) {
            $connection = $script:dbConnection
            Write-Verbose "Verwende bestehende Datenbankverbindung"
        }
        else {
            Write-Verbose "Initialisiere neue Datenbankverbindung"
            $connection = Initialize-Database
        }
        
        # Wenn die Verbindung ein Array ist, nehmen wir das erste Element
        if ($connection -is [Object[]]) {
            Write-Warning "Verbindung ist ein Array - nehme das erste Element"
            if ($connection.Length -gt 0) {
                $connection = $connection[0]
            }
            else {
                Write-Error "Leeres Verbindungs-Array erhalten"
                return $false
            }
        }

        # Prüfe, ob $connection wirklich ein SQLiteConnection-Objekt ist
        if ((-not $connection) -or 
            ($connection -isnot [System.Data.SQLite.SQLiteConnection]) -or 
            ($connection.State -ne [System.Data.ConnectionState]::Open)) {
            Write-Error "Add-LogEntry: Keine gültige Datenbankverbindung! Typ: $($connection.GetType().FullName), Status: $($connection.State)"
            try {
                # Versuche die Verbindung zu öffnen, falls sie geschlossen ist
                if ($connection -is [System.Data.SQLite.SQLiteConnection] -and $connection.State -ne [System.Data.ConnectionState]::Open) {
                    $connection.Open()
                    Write-Verbose "Datenbankverbindung erfolgreich geöffnet"
                }
                else {
                    return $false
                }
            }
            catch {
                Write-Error "Konnte Verbindung nicht öffnen: $_"
                return $false
            }
        }

        Write-Verbose "Verbindung ist vom Typ: $($connection.GetType().FullName) und Status: $($connection.State)"
        
        $cmd = $connection.CreateCommand()
        $cmd.CommandText = "INSERT INTO DiagnosticResults (ToolName, ExecutionTime, Result, ExitCode, Details) VALUES (?, ?, ?, ?, ?)"
        $cmd.Parameters.Add((New-Object System.Data.SQLite.SQLiteParameter("", $ToolName))) | Out-Null
        $cmd.Parameters.Add((New-Object System.Data.SQLite.SQLiteParameter("", (Get-Date -Format "yyyy-MM-dd HH:mm:ss")))) | Out-Null
        $cmd.Parameters.Add((New-Object System.Data.SQLite.SQLiteParameter("", $Level))) | Out-Null
        $cmd.Parameters.Add((New-Object System.Data.SQLite.SQLiteParameter("", 0))) | Out-Null
        $cmd.Parameters.Add((New-Object System.Data.SQLite.SQLiteParameter("", $Message))) | Out-Null
        $cmd.ExecuteNonQuery() | Out-Null
        
        # Schließe die Verbindung nur, wenn es nicht die globale ist
        if ($connection -ne $script:dbConnection) {
            $connection.Close()
            $connection.Dispose()
            Write-Verbose "Temporäre Datenbankverbindung geschlossen"
        }
        
        return $true
    }
    catch {
        Write-Error "Error adding log entry: $_"
        return $false
    }
}

# Export all public functions
Export-ModuleMember -Function Initialize-Database, Save-DiagnosticResult, Close-Database, Save-DiagnosticToDatabase, Close-SystemDatabase, Add-LogEntry


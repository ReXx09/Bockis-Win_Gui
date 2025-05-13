function Initialize-Database {
    # SQLite DLL laden
    $dllPath = Join-Path $PSScriptRoot "..\Lib\System.Data.SQLite.dll"
    
    try {
        Add-Type -Path $dllPath
        
        # Datenbankpfad
        $dbPath = Join-Path $env:APPDATA "WinGuiTools\system_data.db"
        $dbDirectory = Split-Path -Parent $dbPath
        
        # Verzeichnis erstellen, falls nicht vorhanden
        if (-not (Test-Path $dbDirectory)) {
            New-Item -ItemType Directory -Path $dbDirectory -Force | Out-Null
        }
        
        # Verbindung zur Datenbank herstellen
        $connectionString = "Data Source=$dbPath;Version=3;"
        $connection = New-Object System.Data.SQLite.SQLiteConnection($connectionString)
        $connection.Open()
        
        # Tabellen erstellen, falls nicht vorhanden
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
        $createTableCmd.ExecuteNonQuery()
        
        return $connection
    }
    catch {
        Write-Error "Fehler beim Initialisieren der Datenbank: $_"
        return $null
    }
}

function Save-SystemSnapshot {
    param(
        [System.Data.SQLite.SQLiteConnection]$connection,
        [double]$cpuUsage,
        [double]$memoryUsage,
        [string]$diskSpace,
        [double]$temperature,
        [string]$snapshotData
    )
    
    try {
        $cmd = $connection.CreateCommand()
        $cmd.CommandText = @"
INSERT INTO SystemSnapshots 
    (Timestamp, CPUUsage, MemoryUsage, DiskSpace, Temperature, SnapshotData)
VALUES
    (@timestamp, @cpuUsage, @memoryUsage, @diskSpace, @temperature, @snapshotData)
"@
        
        $cmd.Parameters.AddWithValue("@timestamp", (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
        $cmd.Parameters.AddWithValue("@cpuUsage", $cpuUsage)
        $cmd.Parameters.AddWithValue("@memoryUsage", $memoryUsage)
        $cmd.Parameters.AddWithValue("@diskSpace", $diskSpace)
        $cmd.Parameters.AddWithValue("@temperature", $temperature)
        $cmd.Parameters.AddWithValue("@snapshotData", $snapshotData)
        
        $cmd.ExecuteNonQuery()
        return $true
    }
    catch {
        Write-Error "Fehler beim Speichern des System-Snapshots: $_"
        return $false
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
        $cmd.CommandText = @"
INSERT INTO DiagnosticResults 
    (ToolName, ExecutionTime, Result, ExitCode, Details)
VALUES
    (@toolName, @executionTime, @result, @exitCode, @details)
"@
        
        $cmd.Parameters.AddWithValue("@toolName", $toolName)
        $cmd.Parameters.AddWithValue("@executionTime", (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
        $cmd.Parameters.AddWithValue("@result", $result)
        $cmd.Parameters.AddWithValue("@exitCode", $exitCode)
        $cmd.Parameters.AddWithValue("@details", $details)
        
        $cmd.ExecuteNonQuery()
        return $true
    }
    catch {
        Write-Error "Fehler beim Speichern des Diagnose-Ergebnisses: $_"
        return $false
    }
}

function Save-HardwareData {
    param(
        [System.Data.SQLite.SQLiteConnection]$connection,
        [string]$hardwareType,
        [string]$componentName,
        [string]$sensorType,
        [string]$sensorName,
        [double]$value,
        [string]$unit
    )
    
    try {
        $cmd = $connection.CreateCommand()
        $cmd.CommandText = @"
INSERT INTO HardwareHistory 
    (Timestamp, HardwareType, ComponentName, SensorType, SensorName, Value, Unit)
VALUES
    (@timestamp, @hardwareType, @componentName, @sensorType, @sensorName, @value, @unit)
"@
        
        $cmd.Parameters.AddWithValue("@timestamp", (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
        $cmd.Parameters.AddWithValue("@hardwareType", $hardwareType)
        $cmd.Parameters.AddWithValue("@componentName", $componentName)
        $cmd.Parameters.AddWithValue("@sensorType", $sensorType)
        $cmd.Parameters.AddWithValue("@sensorName", $sensorName)
        $cmd.Parameters.AddWithValue("@value", $value)
        $cmd.Parameters.AddWithValue("@unit", $unit)
        
        $cmd.ExecuteNonQuery()
        return $true
    }
    catch {
        Write-Error "Fehler beim Speichern der Hardware-Daten: $_"
        return $false
    }
}

function Get-SystemSnapshots {
    param(
        [System.Data.SQLite.SQLiteConnection]$connection,
        [int]$limit = 10
    )
    
    try {
        $cmd = $connection.CreateCommand()
        $cmd.CommandText = "SELECT * FROM SystemSnapshots ORDER BY Timestamp DESC LIMIT @limit"
        $cmd.Parameters.AddWithValue("@limit", $limit)
        
        $adapter = New-Object System.Data.SQLite.SQLiteDataAdapter($cmd)
        $dataset = New-Object System.Data.DataSet
        $adapter.Fill($dataset)
        
        return $dataset.Tables[0]
    }
    catch {
        Write-Error "Fehler beim Abrufen der System-Snapshots: $_"
        return $null
    }
}

function Get-DiagnosticResults {
    param(
        [System.Data.SQLite.SQLiteConnection]$connection,
        [string]$toolName = "",
        [int]$limit = 10
    )
    
    try {
        $cmd = $connection.CreateCommand()
        
        if ([string]::IsNullOrEmpty($toolName)) {
            $cmd.CommandText = "SELECT * FROM DiagnosticResults ORDER BY ExecutionTime DESC LIMIT @limit"
            $cmd.Parameters.AddWithValue("@limit", $limit)
        }
        else {
            $cmd.CommandText = "SELECT * FROM DiagnosticResults WHERE ToolName = @toolName ORDER BY ExecutionTime DESC LIMIT @limit"
            $cmd.Parameters.AddWithValue("@toolName", $toolName)
            $cmd.Parameters.AddWithValue("@limit", $limit)
        }
        
        $adapter = New-Object System.Data.SQLite.SQLiteDataAdapter($cmd)
        $dataset = New-Object System.Data.DataSet
        $adapter.Fill($dataset)
        
        return $dataset.Tables[0]
    }
    catch {
        Write-Error "Fehler beim Abrufen der Diagnose-Ergebnisse: $_"
        return $null
    }
}

function Get-HardwareHistory {
    param(
        [System.Data.SQLite.SQLiteConnection]$connection,
        [string]$hardwareType,
        [string]$componentName,
        [string]$sensorType,
        [int]$hours = 24
    )
    
    try {
        $cmd = $connection.CreateCommand()
        $timeLimit = (Get-Date).AddHours(-$hours).ToString("yyyy-MM-dd HH:mm:ss")
        
        $query = "SELECT * FROM HardwareHistory WHERE Timestamp >= @timeLimit"
        $parameters = @{
            "@timeLimit" = $timeLimit
        }
        
        if (-not [string]::IsNullOrEmpty($hardwareType)) {
            $query += " AND HardwareType = @hardwareType"
            $parameters["@hardwareType"] = $hardwareType
        }
        
        if (-not [string]::IsNullOrEmpty($componentName)) {
            $query += " AND ComponentName = @componentName"
            $parameters["@componentName"] = $componentName
        }
        
        if (-not [string]::IsNullOrEmpty($sensorType)) {
            $query += " AND SensorType = @sensorType"
            $parameters["@sensorType"] = $sensorType
        }
        
        $query += " ORDER BY Timestamp ASC"
        $cmd.CommandText = $query
        
        foreach ($param in $parameters.GetEnumerator()) {
            $cmd.Parameters.AddWithValue($param.Key, $param.Value)
        }
        
        $adapter = New-Object System.Data.SQLite.SQLiteDataAdapter($cmd)
        $dataset = New-Object System.Data.DataSet
        $adapter.Fill($dataset)
        
        return $dataset.Tables[0]
    }
    catch {
        Write-Error "Fehler beim Abrufen der Hardware-Historie: $_"
        return $null
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

Export-ModuleMember -Function Initialize-Database, Save-SystemSnapshot, Save-DiagnosticResult, 
Save-HardwareData, Get-SystemSnapshots, Get-DiagnosticResults, Get-HardwareHistory, Close-Database 
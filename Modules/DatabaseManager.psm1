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
        
        $dbPath = Join-Path $env:LOCALAPPDATA "BockisSystemTool\Database\system_data.db"
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

function Show-DatabaseOverview {
    <#
    .SYNOPSIS
        Zeigt eine Übersicht der Datenbank-Einträge
    .DESCRIPTION
        Erstellt ein Dialog-Fenster mit allen Datenbank-Einträgen aus DiagnosticResults
    #>
    param()
    
    try {
        # Datenbank-Pfad
        $dbPath = Join-Path $env:APPDATA "WinGuiTools\system_data.db"
        
        if (-not (Test-Path $dbPath)) {
            [System.Windows.Forms.MessageBox]::Show(
                "Datenbank nicht gefunden:`n$dbPath`n`nEs wurden noch keine Daten gespeichert.",
                "Datenbank leer",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Information
            )
            return
        }
        
        # Datenbankgröße ermitteln
        $dbSize = [Math]::Round((Get-Item $dbPath).Length / 1KB, 2)
        
        # Verbindung öffnen
        $connectionString = "Data Source=$dbPath;Version=3;"
        $connection = New-Object System.Data.SQLite.SQLiteConnection($connectionString)
        $connection.Open()
        
        # Anzahl Einträge abrufen
        $cmd = $connection.CreateCommand()
        $cmd.CommandText = "SELECT COUNT(*) FROM DiagnosticResults"
        $totalEntries = $cmd.ExecuteScalar()
        
        # Letzten 100 Einträge abrufen
        $cmd.CommandText = "SELECT Id, ToolName, ExecutionTime, Result, ExitCode, Details FROM DiagnosticResults ORDER BY Id DESC LIMIT 100"
        $reader = $cmd.ExecuteReader()
        
        $entries = @()
        while ($reader.Read()) {
            $entries += [PSCustomObject]@{
                Id = $reader["Id"]
                ToolName = $reader["ToolName"]
                ExecutionTime = $reader["ExecutionTime"]
                Result = $reader["Result"]
                ExitCode = $reader["ExitCode"]
                Details = $reader["Details"]
            }
        }
        $reader.Close()
        $connection.Close()
        
        # Dialog erstellen
        $dbForm = New-Object System.Windows.Forms.Form
        $dbForm.Text = "🗄️ Datenbank-Übersicht"
        $dbForm.Size = New-Object System.Drawing.Size(900, 600)
        $dbForm.StartPosition = "CenterScreen"
        $dbForm.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
        $dbForm.ForeColor = [System.Drawing.Color]::FromArgb(220, 220, 220)
        $dbForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::Sizable
        
        # Info-Panel oben
        $infoPanel = New-Object System.Windows.Forms.Panel
        $infoPanel.Dock = [System.Windows.Forms.DockStyle]::Top
        $infoPanel.Height = 60
        $infoPanel.BackColor = [System.Drawing.Color]::FromArgb(45, 45, 48)
        $dbForm.Controls.Add($infoPanel)
        
        # Statistik-Labels
        $lblStats = New-Object System.Windows.Forms.Label
        $lblStats.Text = "📊 Statistik:`n   • Einträge gesamt: $totalEntries`n   • Datenbankgröße: $dbSize KB`n   • Pfad: $dbPath"
        $lblStats.Location = New-Object System.Drawing.Point(15, 10)
        $lblStats.Size = New-Object System.Drawing.Size(700, 45)
        $lblStats.ForeColor = [System.Drawing.Color]::LightGreen
        $lblStats.Font = New-Object System.Drawing.Font("Consolas", 9)
        $infoPanel.Controls.Add($lblStats)
        
        # Button-Panel
        $btnPanel = New-Object System.Windows.Forms.Panel
        $btnPanel.Dock = [System.Windows.Forms.DockStyle]::Bottom
        $btnPanel.Height = 50
        $btnPanel.BackColor = [System.Drawing.Color]::FromArgb(45, 45, 48)
        $dbForm.Controls.Add($btnPanel)
        
        # Datenbank leeren Button
        $btnClear = New-Object System.Windows.Forms.Button
        $btnClear.Text = "🗑️ Datenbank leeren"
        $btnClear.Location = New-Object System.Drawing.Point(15, 10)
        $btnClear.Size = New-Object System.Drawing.Size(150, 30)
        $btnClear.BackColor = [System.Drawing.Color]::Crimson
        $btnClear.ForeColor = [System.Drawing.Color]::White
        $btnClear.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
        $btnClear.Add_Click({
            $result = [System.Windows.Forms.MessageBox]::Show(
                "Möchten Sie wirklich ALLE Einträge aus der Datenbank löschen?`n`nDiese Aktion kann nicht rückgängig gemacht werden!",
                "Datenbank leeren",
                [System.Windows.Forms.MessageBoxButtons]::YesNo,
                [System.Windows.Forms.MessageBoxIcon]::Warning
            )
            
            if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
                try {
                    $conn = New-Object System.Data.SQLite.SQLiteConnection($connectionString)
                    $conn.Open()
                    $clearCmd = $conn.CreateCommand()
                    $clearCmd.CommandText = "DELETE FROM DiagnosticResults"
                    $clearCmd.ExecuteNonQuery() | Out-Null
                    $conn.Close()
                    
                    [System.Windows.Forms.MessageBox]::Show(
                        "Alle Einträge wurden erfolgreich gelöscht.",
                        "Erfolgreich",
                        [System.Windows.Forms.MessageBoxButtons]::OK,
                        [System.Windows.Forms.MessageBoxIcon]::Information
                    )
                    $dbForm.Close()
                }
                catch {
                    [System.Windows.Forms.MessageBox]::Show(
                        "Fehler beim Leeren der Datenbank:`n`n$_",
                        "Fehler",
                        [System.Windows.Forms.MessageBoxButtons]::OK,
                        [System.Windows.Forms.MessageBoxIcon]::Error
                    )
                }
            }
        })
        $btnPanel.Controls.Add($btnClear)
        
        # Aktualisieren Button
        $btnRefresh = New-Object System.Windows.Forms.Button
        $btnRefresh.Text = "🔄 Aktualisieren"
        $btnRefresh.Location = New-Object System.Drawing.Point(175, 10)
        $btnRefresh.Size = New-Object System.Drawing.Size(120, 30)
        $btnRefresh.BackColor = [System.Drawing.Color]::ForestGreen
        $btnRefresh.ForeColor = [System.Drawing.Color]::White
        $btnRefresh.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
        $btnRefresh.Add_Click({
            $dbForm.Close()
            Show-DatabaseOverview
        })
        $btnPanel.Controls.Add($btnRefresh)
        
        # Schließen Button
        $btnClose = New-Object System.Windows.Forms.Button
        $btnClose.Text = "✕ Schließen"
        $btnClose.Location = New-Object System.Drawing.Point(305, 10)
        $btnClose.Size = New-Object System.Drawing.Size(100, 30)
        $btnClose.BackColor = [System.Drawing.Color]::Gray
        $btnClose.ForeColor = [System.Drawing.Color]::White
        $btnClose.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
        $btnClose.Add_Click({ $dbForm.Close() })
        $btnPanel.Controls.Add($btnClose)
        
        # DataGridView für Einträge
        $dgv = New-Object System.Windows.Forms.DataGridView
        $dgv.Dock = [System.Windows.Forms.DockStyle]::Fill
        $dgv.BackgroundColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
        $dgv.ForeColor = [System.Drawing.Color]::FromArgb(220, 220, 220)
        $dgv.GridColor = [System.Drawing.Color]::FromArgb(63, 63, 70)
        $dgv.BorderStyle = [System.Windows.Forms.BorderStyle]::None
        $dgv.AllowUserToAddRows = $false
        $dgv.AllowUserToDeleteRows = $false
        $dgv.ReadOnly = $true
        $dgv.SelectionMode = [System.Windows.Forms.DataGridViewSelectionMode]::FullRowSelect
        $dgv.AutoSizeColumnsMode = [System.Windows.Forms.DataGridViewAutoSizeColumnsMode]::Fill
        $dgv.RowHeadersVisible = $false
        
        # Dark Theme für DataGridView
        $dgv.EnableHeadersVisualStyles = $false
        $dgv.ColumnHeadersDefaultCellStyle.BackColor = [System.Drawing.Color]::FromArgb(45, 45, 48)
        $dgv.ColumnHeadersDefaultCellStyle.ForeColor = [System.Drawing.Color]::White
        $dgv.ColumnHeadersDefaultCellStyle.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
        $dgv.DefaultCellStyle.BackColor = [System.Drawing.Color]::FromArgb(37, 37, 38)
        $dgv.DefaultCellStyle.ForeColor = [System.Drawing.Color]::FromArgb(220, 220, 220)
        $dgv.DefaultCellStyle.SelectionBackColor = [System.Drawing.Color]::FromArgb(0, 122, 204)
        $dgv.DefaultCellStyle.SelectionForeColor = [System.Drawing.Color]::White
        $dgv.AlternatingRowsDefaultCellStyle.BackColor = [System.Drawing.Color]::FromArgb(45, 45, 48)
        
        # Spalten hinzufügen
        $dgv.Columns.Add("Id", "ID") | Out-Null
        $dgv.Columns.Add("ToolName", "Tool") | Out-Null
        $dgv.Columns.Add("ExecutionTime", "Zeitpunkt") | Out-Null
        $dgv.Columns.Add("Result", "Ergebnis") | Out-Null
        $dgv.Columns.Add("ExitCode", "Code") | Out-Null
        $dgv.Columns.Add("Details", "Details") | Out-Null
        
        # Spaltenbreiten
        $dgv.Columns[0].Width = 50   # ID
        $dgv.Columns[1].Width = 150  # Tool
        $dgv.Columns[2].Width = 150  # Zeit
        $dgv.Columns[3].Width = 100  # Ergebnis
        $dgv.Columns[4].Width = 60   # Code
        $dgv.Columns[5].AutoSizeMode = [System.Windows.Forms.DataGridViewAutoSizeColumnMode]::Fill  # Details
        
        # Daten einfügen
        foreach ($entry in $entries) {
            $dgv.Rows.Add(
                $entry.Id,
                $entry.ToolName,
                $entry.ExecutionTime,
                $entry.Result,
                $entry.ExitCode,
                $entry.Details
            ) | Out-Null
        }
        
        $dbForm.Controls.Add($dgv)
        
        # Zeige nur die letzten 100 Einträge Info
        if ($totalEntries -gt 100) {
            $lblInfo = New-Object System.Windows.Forms.Label
            $lblInfo.Text = "ℹ️ Angezeigt werden die letzten 100 von $totalEntries Einträgen"
            $lblInfo.Dock = [System.Windows.Forms.DockStyle]::Bottom
            $lblInfo.Height = 25
            $lblInfo.BackColor = [System.Drawing.Color]::FromArgb(60, 60, 60)
            $lblInfo.ForeColor = [System.Drawing.Color]::Yellow
            $lblInfo.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
            $lblInfo.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Italic)
            $dbForm.Controls.Add($lblInfo)
        }
        
        $dbForm.ShowDialog() | Out-Null
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show(
            "Fehler beim Laden der Datenbank-Übersicht:`n`n$_",
            "Fehler",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
    }
}

# Export all public functions
Export-ModuleMember -Function Initialize-Database, Save-DiagnosticResult, Close-Database, Save-DiagnosticToDatabase, Close-SystemDatabase, Add-LogEntry, Show-DatabaseOverview


# SIG # Begin signature block
# MIIcSgYJKoZIhvcNAQcCoIIcOzCCHDcCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAgSbQe4OIHy84a
# AGCJfcoC83ZN8+BJk4phF5U4OeivGaCCFnowggM8MIICJKADAgECAhBJfyGrXBJT
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
# MQ4wDAYKKwYBBAGCNwIBFTAvBgkqhkiG9w0BCQQxIgQgez+d8PJ5EaVrNIF0NlTR
# NZ12Pcnn1+JzSGgibiS9cGIwDQYJKoZIhvcNAQEBBQAEggEAghsKoMpPSlI+39+0
# 6+QHjCc2u7kmtCnL5g7GOdDM3y8d2D9YW4ruEGtjzur3fuWq/mPta7k+VIN1Mted
# JDV6GIUJ+5szu6uwlMeoUVqtCDf9ltn475jWwp2M4lPF7SZ7lzohTZfzBZ0OE454
# LzE1KGIxNymI0NgRfbCr7E+J9CzdCaYVPaQSWMDra7oFh4o1k7RBSfhsRixc3G+I
# AM95NaV3gjlDNzDc+v61zRrxLHNjWo2pf/VltNtbThwr9cY19DQEANI3lTvUPbB/
# XlSUmFmvKK9meBtW2RopXLkEURQ49vdUtCsXzGs0ePJD3nKWK5Ja0ZFVpGZGXpdx
# uHmLAqGCAyYwggMiBgkqhkiG9w0BCQYxggMTMIIDDwIBATB9MGkxCzAJBgNVBAYT
# AlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5jLjFBMD8GA1UEAxM4RGlnaUNlcnQg
# VHJ1c3RlZCBHNCBUaW1lU3RhbXBpbmcgUlNBNDA5NiBTSEEyNTYgMjAyNSBDQTEC
# EAqA7xhLjfEFgtHEdqeVdGgwDQYJYIZIAWUDBAIBBQCgaTAYBgkqhkiG9w0BCQMx
# CwYJKoZIhvcNAQcBMBwGCSqGSIb3DQEJBTEPFw0yNjAxMjAxODAyNTZaMC8GCSqG
# SIb3DQEJBDEiBCC8X4WhJFSW20WmvjzY9HZ4w4waEhBguP+9U1J70uZ64zANBgkq
# hkiG9w0BAQEFAASCAgBYGYTv+sZHMtmFSey6VBf3iqD1GApl/Sq8jzhU+RMm5q68
# x86z5H0Pu26vsDO7ph5A4AJoeO0/2eBI0/qPj81Qpl5MM53yyilidYthknag2/Uq
# mHZTu4LkxraVaO3pT4jIzABWhLixXlxn+HEFKIJKi7r0P2VWYxh0aDWoy1w24l1B
# y7mPf6VzVs+qqwmpiENDGSQby44ErCv6WGjyWJ/BJSd8seiyiYdW80ttNjsdyTDM
# ChBbiSdC1Y67sZmc115n3/8ZCk+3wBLXUsl/NS+FrgZdCVcuGV83zrU9Pusv2TdB
# dN6GER6AoXK5foPbnkMa2e5EcEDSMYtEbEhKU4dwUhI0UYJ4eXsrW8UJ4lqs7q+H
# RCW59RYbcuEZhK37h2dSPxMFeTaKZDNT1FC3Z+M0/zvi/cnD5ARFufRYOwQwm2Oc
# m4r04yhI2jMGRpKn1gLlu8XBJ7FXaLpbQNs9TvW4ncDxhQtkKzpV/xBx5iRXEZyF
# D5yx9dCxaeRaiY4Z/KqXbKeR338RDUtkHEHw2ErJsF6jRYr7ytpknzU90o584g3i
# GqCjJJObuKyciDqFunLAMMS/R9IwSFY4L1E8E8ZrZgSsKnxCvsSQluSfxYGuiBB7
# rMBSRp8wgRxyT1pcXb/03bQa2yyZojjCGNQczexDPVbPich2NXFTO9mYABUhig==
# SIG # End signature block

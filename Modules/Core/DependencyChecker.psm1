# DependencyChecker.psm1
# Modul zur Prüfung und Installation von Abhängigkeiten

# Importiere LogManager für strukturiertes Logging
Import-Module "$PSScriptRoot\LogManager.psm1" -Force -ErrorAction SilentlyContinue

#region LibreHardwareMonitor Erkennung

<#
.SYNOPSIS
Sucht nach einer installierten Version von LibreHardwareMonitor im System.

.DESCRIPTION
Prüft verschiedene Standard-Installationspfade und Registry-Einträge, 
um eine aktuelle LibreHardwareMonitor-Installation zu finden.

.OUTPUTS
Hashtable mit Informationen über die gefundene Installation:
- Found: Boolean, ob Installation gefunden wurde
- Path: String, Pfad zur LibreHardwareMonitorLib.dll
- Version: String, Versionsnummer (falls verfügbar)
- IsSigned: Boolean, ob die DLL gültig signiert ist
#>
function Find-LibreHardwareMonitor {
    $result = @{
        Found = $false
        Path = $null
        Version = $null
        IsSigned = $false
    }
    
    # Standard-Installationspfade prüfen (inkl. Winget-Pfade)
    $searchPaths = @(
        # Winget installiert oft in verschachtelte Ordner mit Version-Hash
        "${env:LOCALAPPDATA}\Microsoft\WinGet\Packages\LibreHardwareMonitor.LibreHardwareMonitor_*",
        "${env:ProgramFiles}\LibreHardwareMonitor\LibreHardwareMonitor",
        # Standard-Pfade
        "${env:ProgramFiles}\LibreHardwareMonitor",
        "${env:ProgramFiles(x86)}\LibreHardwareMonitor",
        "$env:LOCALAPPDATA\Programs\LibreHardwareMonitor",
        "$env:APPDATA\LibreHardwareMonitor"
    )
    
    foreach ($basePath in $searchPaths) {
        # Wildcard-Pfade auflösen (für Winget-Packages)
        $resolvedPaths = @()
        if ($basePath -match '\*') {
            $resolvedPaths = @(Resolve-Path $basePath -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Path)
        } else {
            $resolvedPaths = @($basePath)
        }
        
        foreach ($path in $resolvedPaths) {
            if (-not $path) { continue }
            
            $dllPath = Join-Path $path "LibreHardwareMonitorLib.dll"
            
            if (Test-Path $dllPath) {
            Write-Verbose "LibreHardwareMonitor gefunden in: $dllPath"
            
            # Prüfe Signatur der DLL
            try {
                $signature = Get-AuthenticodeSignature -FilePath $dllPath -ErrorAction SilentlyContinue
                $isSigned = ($signature.Status -eq 'Valid')
            }
            catch {
                $isSigned = $false
            }
            
            # Prüfe Version über FileInfo
            try {
                $fileInfo = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($dllPath)
                $version = $fileInfo.FileVersion
            }
            catch {
                $version = "Unknown"
            }
            
            $result.Found = $true
            $result.Path = $dllPath
            $result.Version = $version
            $result.IsSigned = $isSigned
            
            return $result
            }
        }
    }
    
    # Zusätzlich in Registry nach Installation suchen
    $regPaths = @(
        "HKCU:\Software\LibreHardwareMonitor",
        "HKLM:\Software\LibreHardwareMonitor",
        "HKLM:\Software\WOW6432Node\LibreHardwareMonitor"
    )
    
    foreach ($regPath in $regPaths) {
        if (Test-Path $regPath) {
            try {
                $installPath = (Get-ItemProperty -Path $regPath -Name "InstallPath" -ErrorAction SilentlyContinue).InstallPath
                if ($installPath) {
                    $dllPath = Join-Path $installPath "LibreHardwareMonitorLib.dll"
                    if (Test-Path $dllPath) {
                        $result.Found = $true
                        $result.Path = $dllPath
                        return $result
                    }
                }
            }
            catch {
                continue
            }
        }
    }
    
    return $result
}

<#
.SYNOPSIS
Prüft ob LibreHardwareMonitor über Winget verfügbar ist.

.OUTPUTS
Boolean - True wenn verfügbar, False wenn nicht
#>
function Test-LibreHardwareMonitorAvailability {
    try {
        # Prüfe ob Winget installiert ist
        $winget = Get-Command winget -ErrorAction SilentlyContinue
        if (-not $winget) {
            return $false
        }
        
        # Suche nach LibreHardwareMonitor
        $search = winget search "LibreHardwareMonitor" --exact 2>&1
        return ($search -match "LibreHardwareMonitor")
    }
    catch {
        return $false
    }
}

<#
.SYNOPSIS
Installiert LibreHardwareMonitor über Winget.

.PARAMETER Silent
Installiert ohne Benutzerinteraktion (automatisch akzeptiert)

.OUTPUTS
Boolean - True wenn erfolgreich installiert, False bei Fehler
#>
function Install-LibreHardwareMonitor {
    param(
        [switch]$Silent
    )
    
    try {
        Write-Host "`n📦 Installiere LibreHardwareMonitor..." -ForegroundColor Cyan
        
        $wingetArgs = @(
            "install",
            "--id", "LibreHardwareMonitor.LibreHardwareMonitor",
            "--exact",
            "--accept-source-agreements"
        )
        
        if ($Silent) {
            $wingetArgs += "--silent"
            $wingetArgs += "--accept-package-agreements"
        }
        
        # Führe Winget-Installation aus
        $process = Start-Process -FilePath "winget" `
                                  -ArgumentList $wingetArgs `
                                  -Wait `
                                  -PassThru `
                                  -NoNewWindow
        
        # Exit Codes:
        # 0 = Erfolg
        # -1978335189 (0x8A15000B) = Bereits installiert / Kein Upgrade verfügbar
        if ($process.ExitCode -eq 0 -or $process.ExitCode -eq -1978335189) {
            if ($process.ExitCode -eq -1978335189) {
                Write-Host "ℹ️  LibreHardwareMonitor ist bereits installiert" -ForegroundColor Cyan
            } else {
                Write-Host "✓ LibreHardwareMonitor erfolgreich installiert!" -ForegroundColor Green
            }
            
            # Suche nach Installation nach 2 Sekunden Wartezeit
            Start-Sleep -Seconds 2
            $found = Find-LibreHardwareMonitor
            
            if ($found.Found) {
                Write-Host "✓ Installation verifiziert: $($found.Path)" -ForegroundColor Green
                return $true
            }
            else {
                Write-Warning "Installation abgeschlossen, aber DLL nicht gefunden!"
                Write-Host "  Hinweis: Versuche manuelle Suche mit erweiterten Pfaden..." -ForegroundColor Yellow
                
                # Erweiterte Suche nach Installation
                $manualSearchPaths = @(
                    "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\*LibreHardware*",
                    "$env:ProgramFiles\*LibreHardware*",
                    "$env:LOCALAPPDATA\Programs\*LibreHardware*"
                )
                
                foreach ($searchPattern in $manualSearchPaths) {
                    $paths = Get-ChildItem -Path (Split-Path $searchPattern) -Filter (Split-Path $searchPattern -Leaf) -Directory -ErrorAction SilentlyContinue
                    foreach ($dir in $paths) {
                        $dllPath = Get-ChildItem -Path $dir.FullName -Filter "LibreHardwareMonitorLib.dll" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
                        if ($dllPath) {
                            Write-Host "✓ DLL gefunden: $($dllPath.FullName)" -ForegroundColor Green
                            return $true
                        }
                    }
                }
                
                return $false
            }
        }
        else {
            Write-Warning "Installation fehlgeschlagen (Exit Code: $($process.ExitCode))"
            return $false
        }
    }
    catch {
        Write-Warning "Fehler bei der Installation: $_"
        return $false
    }
}

#endregion

#region PowerShell Core Erkennung

<#
.SYNOPSIS
Prüft ob PowerShell 7+ installiert ist.

.OUTPUTS
Hashtable mit Informationen:
- Found: Boolean
- Version: Version-Objekt
- Path: String zum pwsh.exe
#>
function Find-PowerShellCore {
    $result = @{
        Found = $false
        Version = $null
        Path = $null
    }
    
    try {
        $pwsh = Get-Command pwsh -ErrorAction SilentlyContinue
        if ($pwsh) {
            $result.Found = $true
            $result.Path = $pwsh.Source
            
            # Version ermitteln
            $versionOutput = & pwsh -NoProfile -Command '$PSVersionTable.PSVersion.ToString()' 2>$null
            if ($versionOutput) {
                $result.Version = [Version]$versionOutput
            }
        }
    }
    catch {
        # PowerShell Core nicht gefunden
    }
    
    return $result
}

<#
.SYNOPSIS
Prüft ob Winget Package Manager installiert ist.

.OUTPUTS
Hashtable mit Informationen:
- Found: Boolean
- Version: Version-Objekt
- Path: String zum winget.exe
#>
function Find-WingetPackageManager {
    $result = @{
        Found = $false
        Version = $null
        Path = $null
    }
    
    try {
        $winget = Get-Command winget -ErrorAction SilentlyContinue
        if ($winget) {
            $result.Found = $true
            $result.Path = $winget.Source
            
            # Version ermitteln
            $versionOutput = winget --version 2>$null
            if ($versionOutput -match 'v?([\d\.]+)') {
                try {
                    $result.Version = [Version]$matches[1]
                }
                catch {
                    $result.Version = $versionOutput
                }
            }
        }
    }
    catch {
        # Winget nicht gefunden
    }
    
    return $result
}

#endregion

#region Dependency Dialog

<#
.SYNOPSIS
Zeigt einen modernen Dialog zur Abhängigkeitsprüfung.

.PARAMETER MissingDependencies
Array mit fehlenden Abhängigkeiten (Name, Description, Required)

.OUTPUTS
Hashtable mit Benutzerentscheidungen für jede Abhängigkeit
#>
function Show-DependencyDialog {
    param(
        [Parameter(Mandatory = $true)]
        [array]$MissingDependencies
    )
    
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    
    # Hauptformular erstellen
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "📦 Abhängigkeiten prüfen - $($script:AppName)"
    $form.Size = New-Object System.Drawing.Size(600, 450)
    $form.StartPosition = "CenterScreen"
    $form.FormBorderStyle = "FixedDialog"
    $form.MaximizeBox = $false
    $form.MinimizeBox = $false
    $form.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $form.BackColor = [System.Drawing.Color]::FromArgb(240, 240, 245)
    
    # Header Panel
    $headerPanel = New-Object System.Windows.Forms.Panel
    $headerPanel.Dock = "Top"
    $headerPanel.Height = 80
    $headerPanel.BackColor = [System.Drawing.Color]::FromArgb(41, 128, 185)
    $form.Controls.Add($headerPanel)
    
    # Header Label
    $headerLabel = New-Object System.Windows.Forms.Label
    $headerLabel.Text = "🔍 Abhängigkeiten werden geprüft"
    $headerLabel.Font = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
    $headerLabel.ForeColor = [System.Drawing.Color]::White
    $headerLabel.AutoSize = $false
    $headerLabel.Size = New-Object System.Drawing.Size(560, 30)
    $headerLabel.Location = New-Object System.Drawing.Point(20, 15)
    $headerPanel.Controls.Add($headerLabel)
    
    # Subheader Label
    $subHeaderLabel = New-Object System.Windows.Forms.Label
    $subHeaderLabel.Text = "Status der empfohlenen Komponenten. Grün = Installiert, Weiß = Verfügbar."
    $subHeaderLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $subHeaderLabel.ForeColor = [System.Drawing.Color]::FromArgb(230, 230, 230)
    $subHeaderLabel.AutoSize = $false
    $subHeaderLabel.Size = New-Object System.Drawing.Size(560, 20)
    $subHeaderLabel.Location = New-Object System.Drawing.Point(20, 45)
    $headerPanel.Controls.Add($subHeaderLabel)
    
    # Content Panel
    $contentPanel = New-Object System.Windows.Forms.Panel
    $contentPanel.Location = New-Object System.Drawing.Point(20, 100)
    $contentPanel.Size = New-Object System.Drawing.Size(560, 250)
    $contentPanel.AutoScroll = $true
    $form.Controls.Add($contentPanel)
    
    # Checkboxen für jede Abhängigkeit
    $checkBoxes = @{}
    $yPos = 10
    
    foreach ($dep in $MissingDependencies) {
        # Bestimme ob bereits installiert
        $isInstalled = ($dep.Found -eq $true)
        
        # Gruppierungs-Panel für jede Abhängigkeit
        $depPanel = New-Object System.Windows.Forms.Panel
        $depPanel.Location = New-Object System.Drawing.Point(10, $yPos)
        $depPanel.Size = New-Object System.Drawing.Size(520, 70)
        
        # Hintergrundfarbe: Grün-Ton für installiert, Weiß für fehlend
        if ($isInstalled) {
            $depPanel.BackColor = [System.Drawing.Color]::FromArgb(230, 255, 230)  # Hellgrün
        } else {
            $depPanel.BackColor = [System.Drawing.Color]::White
        }
        $depPanel.BorderStyle = "FixedSingle"
        
        # Checkbox
        $checkBox = New-Object System.Windows.Forms.CheckBox
        $checkBox.Location = New-Object System.Drawing.Point(10, 10)
        $checkBox.Size = New-Object System.Drawing.Size(480, 25)
        
        # Text mit Status-Indikator
        if ($isInstalled) {
            $checkBox.Text = "$($dep.Name) ✓ [Bereits installiert]"
            $checkBox.Checked = $false  # Nicht zur Installation vorschlagen
            $checkBox.Enabled = $false  # Ausgegraut
            $checkBox.Font = New-Object System.Drawing.Font("Segoe UI", 10)
            $checkBox.ForeColor = [System.Drawing.Color]::DarkGreen
        } else {
            $checkBox.Text = "$($dep.Name)"
            $checkBox.Checked = $dep.Required  # Erforderliche standardmäßig aktiviert
            $checkBox.Enabled = $true
            $checkBox.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
            $checkBox.ForeColor = [System.Drawing.Color]::Black
        }
        
        $depPanel.Controls.Add($checkBox)
        
        # Beschreibung
        $descLabel = New-Object System.Windows.Forms.Label
        $descLabel.Location = New-Object System.Drawing.Point(30, 35)
        $descLabel.Size = New-Object System.Drawing.Size(470, 25)
        
        if ($isInstalled) {
            # Zeige Installationsdetails für bereits installierte
            if ($dep.Version) {
                $descLabel.Text = "Version $($dep.Version) gefunden"
            } elseif ($dep.Path) {
                $descLabel.Text = "Installiert: $($dep.Path)"
            } else {
                $descLabel.Text = "Installation wurde erkannt"
            }
            $descLabel.ForeColor = [System.Drawing.Color]::DarkGreen
        } else {
            $descLabel.Text = $dep.Description
            
            # Spezielle Hinweise für nicht-installierbare Komponenten
            if (-not $dep.Available -and $dep.Name -eq "Winget Package Manager") {
                $descLabel.Text = "⚠️ Installation via Microsoft Store oder GitHub erforderlich"
                $descLabel.ForeColor = [System.Drawing.Color]::OrangeRed
            } else {
                $descLabel.ForeColor = [System.Drawing.Color]::Gray
            }
        }
        
        $descLabel.Font = New-Object System.Drawing.Font("Segoe UI", 8)
        $depPanel.Controls.Add($descLabel)
        
        $contentPanel.Controls.Add($depPanel)
        $checkBoxes[$dep.Name] = $checkBox
        
        $yPos += 80
    }
    
    # Prüfe ob es installierbare Komponenten gibt
    $hasInstallableItems = $false
    foreach ($dep in $MissingDependencies) {
        if (-not $dep.Found -and $dep.Available) {
            $hasInstallableItems = $true
            break
        }
    }
    
    # Button Panel
    $buttonPanel = New-Object System.Windows.Forms.Panel
    $buttonPanel.Dock = "Bottom"
    $buttonPanel.Height = 60
    $buttonPanel.BackColor = [System.Drawing.Color]::FromArgb(245, 245, 250)
    $form.Controls.Add($buttonPanel)
    
    # Installieren Button (nur wenn es installierbare Komponenten gibt)
    if ($hasInstallableItems) {
        $installButton = New-Object System.Windows.Forms.Button
        $installButton.Text = "✓ Ausgewählte installieren"
        $installButton.Size = New-Object System.Drawing.Size(180, 35)
        $installButton.Location = New-Object System.Drawing.Point(220, 12)
        $installButton.BackColor = [System.Drawing.Color]::FromArgb(46, 204, 113)
        $installButton.ForeColor = [System.Drawing.Color]::White
        $installButton.FlatStyle = "Flat"
        $installButton.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
        $installButton.Cursor = [System.Windows.Forms.Cursors]::Hand
        $installButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
        $buttonPanel.Controls.Add($installButton)
        $form.AcceptButton = $installButton
    }
    else {
        # Wenn alles installiert ist, zeige "OK" Button
        $okButton = New-Object System.Windows.Forms.Button
        $okButton.Text = "✓ Alles in Ordnung"
        $okButton.Size = New-Object System.Drawing.Size(180, 35)
        $okButton.Location = New-Object System.Drawing.Point(220, 12)
        $okButton.BackColor = [System.Drawing.Color]::FromArgb(46, 204, 113)
        $okButton.ForeColor = [System.Drawing.Color]::White
        $okButton.FlatStyle = "Flat"
        $okButton.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
        $okButton.Cursor = [System.Windows.Forms.Cursors]::Hand
        $okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
        $buttonPanel.Controls.Add($okButton)
        $form.AcceptButton = $okButton
    }
    
    # Schließen/Überspringen Button
    $closeButton = New-Object System.Windows.Forms.Button
    if ($hasInstallableItems) {
        $closeButton.Text = "→ Überspringen"
    } else {
        $closeButton.Text = "→ Schließen"
    }
    $closeButton.Size = New-Object System.Drawing.Size(130, 35)
    $closeButton.Location = New-Object System.Drawing.Point(410, 12)
    $closeButton.BackColor = [System.Drawing.Color]::FromArgb(149, 165, 166)
    $closeButton.ForeColor = [System.Drawing.Color]::White
    $closeButton.FlatStyle = "Flat"
    $closeButton.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $closeButton.Cursor = [System.Windows.Forms.Cursors]::Hand
    $closeButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $buttonPanel.Controls.Add($closeButton)
    
    $form.CancelButton = $closeButton
    
    # Dialog anzeigen
    $result = $form.ShowDialog()
    
    # Ergebnis zurückgeben
    $choices = @{}
    foreach ($key in $checkBoxes.Keys) {
        $choices[$key] = @{
            Install = ($result -eq [System.Windows.Forms.DialogResult]::OK -and $checkBoxes[$key].Checked)
            Checked = $checkBoxes[$key].Checked
        }
    }
    
    return @{
        DialogResult = $result
        Choices = $choices
    }
}

#endregion

#region Main Dependency Check

<#
.SYNOPSIS
Führt eine vollständige Abhängigkeitsprüfung durch.

.PARAMETER ShowDialog
Zeigt Dialog bei fehlenden Abhängigkeiten

.PARAMETER AutoInstall
Installiert fehlende Abhängigkeiten automatisch (ohne Dialog)

.OUTPUTS
Hashtable mit Ergebnis der Prüfung
#>
function Test-SystemDependencies {
    param(
        [switch]$ShowDialog,
        [switch]$AutoInstall
    )
    
    Write-Host "`n🔍 Prüfe Systemabhängigkeiten..." -ForegroundColor Cyan
    
    $dependencies = @()
    $allSatisfied = $true
    
    # 0. Winget Package Manager prüfen (wichtig für Installationen)
    $winget = Find-WingetPackageManager
    if ($winget.Found) {
        $dependencies += @{
            Name = "Winget Package Manager"
            Description = "Windows Paketmanager für automatische Software-Installation"
            Required = $false
            Available = $false  # Kann nicht über sich selbst installiert werden
            Found = $true
            Version = $winget.Version.ToString()
            Path = $winget.Path
        }
        Write-Host "  ✓ Winget Package Manager $($winget.Version) gefunden" -ForegroundColor Green
    }
    else {
        $allSatisfied = $false
        $dependencies += @{
            Name = "Winget Package Manager"
            Description = "Erforderlich für automatische Installation von Komponenten (via Microsoft Store)"
            Required = $true
            Available = $false
            Found = $false
            Version = $null
            Path = $null
        }
        Write-Host "  ⚠️  Winget Package Manager nicht gefunden (manuelle Installation erforderlich)" -ForegroundColor Yellow
    }
    
    # 1. LibreHardwareMonitor prüfen
    $lhm = Find-LibreHardwareMonitor
    if (-not $lhm.Found) {
        $allSatisfied = $false
        $dependencies += @{
            Name = "LibreHardwareMonitor"
            Description = "Hardware-Überwachung mit aktuellen Sensoren (CPU/GPU/RAM Temperaturen)"
            Required = $false
            Available = (Test-LibreHardwareMonitorAvailability)
            Found = $false
            Version = $null
            Path = $null
        }
        Write-Host "  ⚠️  LibreHardwareMonitor nicht gefunden (Fallback auf integrierte Lib)" -ForegroundColor Yellow
    }
    else {
        # Auch bereits installierte Komponenten in Liste aufnehmen (für Dialog-Anzeige)
        $dependencies += @{
            Name = "LibreHardwareMonitor"
            Description = "Hardware-Überwachung mit aktuellen Sensoren (CPU/GPU/RAM Temperaturen)"
            Required = $false
            Available = $true
            Found = $true
            Version = $lhm.Version
            Path = $lhm.Path
        }
        Write-Host "  ✓ LibreHardwareMonitor gefunden: $($lhm.Path)" -ForegroundColor Green
        Write-Host "    Version: $($lhm.Version) | Signiert: $($lhm.IsSigned)" -ForegroundColor Gray

    }
    
    # 2. PowerShell Core prüfen (optional)
    $pwsh = Find-PowerShellCore
    if ($pwsh.Found) {
        # Auch installierte PowerShell Core anzeigen
        $dependencies += @{
            Name = "PowerShell Core"
            Description = "Moderne PowerShell 7+ für bessere Performance"
            Required = $false
            Available = $false  # Nicht über Winget installierbar in diesem Modul
            Found = $true
            Version = $pwsh.Version.ToString()
            Path = $pwsh.Path
        }
        Write-Host "  ✓ PowerShell Core $($pwsh.Version) gefunden" -ForegroundColor Green
    }
    else {
        Write-Host "  ℹ️  PowerShell Core nicht gefunden (Windows PowerShell wird verwendet)" -ForegroundColor Cyan
        # Optional: PowerShell Core als empfohlene Komponente hinzufügen
        # (Auskommentiert, da Installation komplex ist)
    }
    
    # Prüfe ob es nicht-installierte Abhängigkeiten gibt
    $missingDependencies = $dependencies | Where-Object { -not $_.Found }
    
    # Wenn alle erfüllt sind und ShowDialog aktiviert, zeige trotzdem Dialog (Status-Übersicht)
    if ($missingDependencies.Count -eq 0) {
        Write-Host "✓ Alle Abhängigkeiten erfüllt!`n" -ForegroundColor Green
        
        # Zeige trotzdem Dialog für Status-Übersicht (falls gewünscht)
        if ($ShowDialog) {
            $dialogResult = Show-DependencyDialog -MissingDependencies $dependencies
            # Kein Action nötig, da alles installiert
        }
        
        return @{
            AllSatisfied = $true
        }
    }
    
    # Auto-Install ohne Dialog
    if ($AutoInstall) {
        foreach ($dep in $dependencies) {
            if ($dep.Name -eq "LibreHardwareMonitor" -and $dep.Available) {
                Install-LibreHardwareMonitor -Silent
            }
        }
        
        # Nach Installation erneut prüfen
        $lhm = Find-LibreHardwareMonitor
        
        return @{
            AllSatisfied = $lhm.Found
        }
    }
    
    # Dialog anzeigen
    if ($ShowDialog -and $dependencies.Count -gt 0) {
        $dialogResult = Show-DependencyDialog -MissingDependencies $dependencies
        
        if ($dialogResult.DialogResult -eq [System.Windows.Forms.DialogResult]::OK) {
            # Installiere ausgewählte Abhängigkeiten
            foreach ($dep in $dependencies) {
                if ($dialogResult.Choices[$dep.Name].Install) {
                    if ($dep.Name -eq "LibreHardwareMonitor") {
                        Install-LibreHardwareMonitor
                    }
                }
            }
        }
    }
    
    return @{
        AllSatisfied = $allSatisfied
    }
}

#endregion

# Exportiere Funktionen
Export-ModuleMember -Function `
    Find-LibreHardwareMonitor, `
    Test-LibreHardwareMonitorAvailability, `
    Install-LibreHardwareMonitor, `
    Find-PowerShellCore, `
    Find-WingetPackageManager, `
    Show-DependencyDialog, `
    Test-SystemDependencies

# SIG # Begin signature block
# MIIcSgYJKoZIhvcNAQcCoIIcOzCCHDcCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDo6Lf3+8s4J9gV
# VyMhLXjx1vgURMZ0h38hqWbghPGkB6CCFnowggM8MIICJKADAgECAhBJfyGrXBJT
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
# MQ4wDAYKKwYBBAGCNwIBFTAvBgkqhkiG9w0BCQQxIgQgx3ZydJLGUOf3G7oKnqnZ
# GTHDur/pIiy0LyZ3mbCH7bowDQYJKoZIhvcNAQEBBQAEggEAM4J+BjorueUGO06A
# G23jDr6r0cU26IFGtILlEAptiyLT8B1oxw2Zjutpp1cpo3kVFw08SQ8yRaBQ+rRu
# yo7oYIFbH89f3cJ5+YeIDG4R4tuhubGBzcgej5q1sqEklSyQt9zJj5byQ49Zp+b/
# 4/fKG1WC3Rr6TetgVWEwspbkeUtkzc87yZ3gEtrgt8S/J0ojWC5tWqoHwAlkFjLe
# kS7vTKKMdxp5UQfutAbXtWzgGG/+hYBMrSvLiaD1MJAYVM6XO8yH61m9cSrp549z
# qhaH1cbfX4sFoTXk9tXZfVDp8d6nh4YwL/WOaKPFRQZaMEeWY5cbECOS8EWo/5uU
# qaBRhKGCAyYwggMiBgkqhkiG9w0BCQYxggMTMIIDDwIBATB9MGkxCzAJBgNVBAYT
# AlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5jLjFBMD8GA1UEAxM4RGlnaUNlcnQg
# VHJ1c3RlZCBHNCBUaW1lU3RhbXBpbmcgUlNBNDA5NiBTSEEyNTYgMjAyNSBDQTEC
# EAqA7xhLjfEFgtHEdqeVdGgwDQYJYIZIAWUDBAIBBQCgaTAYBgkqhkiG9w0BCQMx
# CwYJKoZIhvcNAQcBMBwGCSqGSIb3DQEJBTEPFw0yNjAxMjAxODAyNTNaMC8GCSqG
# SIb3DQEJBDEiBCD1IdurC+AVoBwvpW2mi7aKAwlSaGzcUMuSVZo9T7pAozANBgkq
# hkiG9w0BAQEFAASCAgCdrZM1CbTpGegccOu8SUY/vl7W5hTisWTfVok92tweLB/Y
# gkGqWeS/XPw+Oa/qXvfvCGvX1TZBEZHxeLMXmXouFfijTucmhxmZctNoKJCvrQ80
# ICbPz9n7MVnybyM7CGAlRfVnNt8gTU4Z5Dbh0SpYq1VkmLUGpkC7kJd+w4URoVR3
# tdXicbLLIXMfdhfI8tKMsx806O5GYMd3DYALFuGUMJL2VaJThVCC5+WZKBK5zrMC
# xd8kVyKcax+AapGpgmgHOHPbYcAt40VM4/XVhvVS60mfDXdQzeWF6JQoNo0tU740
# +ijDYrvd797YuEzydInxvktkyzfemwphLVnrCWD63GFs3ZaWEN7C77yLGKqVIQT0
# F5tzIPSE1THvKbA3b/19OgvP2K98cjXQM/n5+5qB1OljPjWEgllaEUF1aeRJzxWO
# DGFpUAjKBfcyC2yw3DR3B6UeNQ61dFa/mTKZ14Y5ATFs73rJ4a1xKurBqiJdw0ba
# sSq0IIWFHncucU8wqVBajFPECYUuJhGRGqtabJmHj0HKoWELLXURcCpPHpdBAPj/
# pE8qWBc33/iaMHUDRml8dEMIqXk4yprBdCdOqVTggX7+qK2dxvqoEhBw6Z32MG5P
# coAB8NezwBihdHlsS8orTA8qc0V32wciVae9+Cb0GlSBKqdmhWNq2pVu+8tfzw==
# SIG # End signature block

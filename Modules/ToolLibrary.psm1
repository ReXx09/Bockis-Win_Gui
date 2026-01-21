# ToolLibrary.psm1 - Bibliothek für Tool-Downloads
# Autor: Bocki

# Benötigte Assemblies laden
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName WindowsFormsIntegration

# Tool-Definitionen als Hash-Tabelle
$script:toolLibrary = [ordered]@{}

# System-Tools hinzufügen
$script:toolLibrary['system'] = @(
    @{
        Name        = '7-Zip'
        Description = 'Komprimierungsprogramm für Dateien und Ordner'
        Version     = '23.01'
        DownloadUrl = 'https://www.7-zip.org/download.html'
        Category    = 'System-Tools'
        Tags        = @('Compression', 'Archive', 'Utility')
        Winget      = '7zip.7zip'
    },
    @{
        Name        = 'CCleaner'
        Description = 'Systembereinigung und Optimierung'
        Version     = '6.10'
        DownloadUrl = 'https://www.ccleaner.com/download'
        Category    = 'System-Tools'
        Tags        = @('Cleanup', 'Optimization', 'System')
        Winget      = 'Piriform.CCleaner'
    },
    @{
        Name        = 'CPU-Z'
        Description = 'Detaillierte CPU- und Systeminformationen'
        Version     = '2.05'
        DownloadUrl = 'https://www.cpuid.com/softwares/cpu-z.html'
        Category    = 'System-Tools'
        Tags        = @('Hardware', 'Monitoring', 'CPU')
        Winget      = 'CPUID.CPU-Z'
    },
    @{
        Name        = 'GPU-Z'
        Description = 'Grafikkarten-Informationen'
        Version     = '2.45'
        DownloadUrl = 'https://www.techpowerup.com/gpuz/'
        Category    = 'System-Tools'
        Tags        = @('Hardware', 'Monitoring', 'GPU')
        Winget      = 'TechPowerUp.GPU-Z'
    },
    @{
        Name        = 'OCCT'
        Description = 'Umfassendes System-Stabilitäts- und Stress-Test-Tool für CPU, GPU und Netzteil'
        Version     = 'Aktuell'
        DownloadUrl = 'https://www.ocbase.com/'
        Category    = 'System-Tools'
        Tags        = @('Stress Test', 'Stability', 'Benchmark', 'Hardware')
        Winget      = 'OCBase.OCCT.Personal'
    },
    @{
        Name        = 'Intel Driver & Support Assistant'
        Description = 'Automatische Treiber-Updates und Support für Intel-Hardware'
        Version     = 'Aktuell'
        DownloadUrl = 'https://www.intel.com/content/www/us/en/support/detect.html'
        Category    = 'System-Tools'
        Tags        = @('Drivers', 'Intel', 'Update', 'Hardware')
        Winget      = 'Intel.IntelDriverAndSupportAssistant'
    },
    @{
        Name        = 'LibreHardwareMonitor'
        Description = 'Open-Source Hardware-Monitoring-Tool für Temperaturen, Lüfter und Sensoren'
        Version     = 'Aktuell'
        DownloadUrl = 'https://github.com/LibreHardwareMonitor/LibreHardwareMonitor'
        Category    = 'System-Tools'
        Tags        = @('Hardware', 'Monitoring', 'Temperature', 'Sensors', 'Open-Source')
        Winget      = 'LibreHardwareMonitor.LibreHardwareMonitor'
    },
    @{
        Name        = 'UniGetUI'
        Description = 'Grafische Oberfläche für Paketmanager (Winget, Scoop, Chocolatey) zum Verwalten von Anwendungen'
        Version     = 'Aktuell'
        DownloadUrl = 'https://github.com/marticliment/UniGetUI'
        Category    = 'System-Tools'
        Tags        = @('Package Manager', 'Winget', 'GUI', 'Software Management')
        Winget      = 'MartiCliment.UniGetUI'
    }
)

# Anwendungen (Browser und Kommunikation)
$script:toolLibrary['applications'] = @(
    @{
        Name        = 'Brave Browser'
        Description = 'Privater und sicherer Webbrowser mit integriertem Adblocker'
        Version     = 'Aktuell'
        DownloadUrl = 'https://brave.com/download/'
        Category    = 'Anwendungen'
        Tags        = @('Browser', 'Privacy', 'Security')
        Winget      = 'Brave.Brave'
    },
    @{
        Name        = 'Mozilla Firefox'
        Description = 'Beliebter Open-Source-Browser mit Fokus auf Privatsphäre'
        Version     = 'Aktuell'
        DownloadUrl = 'https://www.mozilla.org/firefox/'
        Category    = 'Anwendungen'
        Tags        = @('Browser', 'Privacy', 'Open-Source')
        Winget      = 'Mozilla.Firefox'
    },
    @{
        Name        = 'Google Chrome'
        Description = 'Schneller und beliebter Webbrowser von Google'
        Version     = 'Aktuell'
        DownloadUrl = 'https://www.google.com/chrome/'
        Category    = 'Anwendungen'
        Tags        = @('Browser', 'Google', 'Web')
        Winget      = 'Google.Chrome'
    },
    @{
        Name        = 'Discord'
        Description = 'Kommunikationsplattform für Gaming und Communities'
        Version     = 'Aktuell'
        DownloadUrl = 'https://discord.com/download'
        Category    = 'Anwendungen'
        Tags        = @('Communication', 'Gaming', 'Community')
        Winget      = 'Discord.Discord'
    },
    @{
        Name        = 'LibreOffice'
        Description = 'Kostenlose und umfassende Office-Suite mit Writer, Calc, Impress und mehr'
        Version     = 'Aktuell'
        DownloadUrl = 'https://www.libreoffice.org/download/download/'
        Category    = 'Anwendungen'
        Tags        = @('Office', 'Productivity', 'Documents', 'Open-Source')
        Winget      = 'TheDocumentFoundation.LibreOffice'
    },
    @{
        Name        = 'Apache OpenOffice'
        Description = 'Open-Source Office-Suite für Textverarbeitung, Tabellen und Präsentationen'
        Version     = 'Aktuell'
        DownloadUrl = 'https://www.openoffice.org/download/'
        Category    = 'Anwendungen'
        Tags        = @('Office', 'Productivity', 'Documents', 'Open-Source')
        Winget      = 'Apache.OpenOffice'
    }
)

# Audio / TV Tools hinzufügen
$script:toolLibrary['audiotv'] = @(
    @{
        Name        = 'VLC Media Player'
        Description = 'Kostenloser Mediaplayer für nahezu alle Audio- und Videoformate'
        Version     = 'Aktuell'
        DownloadUrl = 'https://www.videolan.org/vlc/'
        Category    = 'Audio / TV'
        Tags        = @('Media Player', 'Video', 'Audio', 'Streaming')
        Winget      = 'VideoLAN.VLC'
    },
    @{
        Name        = 'Spotify'
        Description = 'Musik-Streaming-Dienst mit Millionen von Songs und Podcasts'
        Version     = 'Aktuell'
        DownloadUrl = 'https://www.spotify.com/download/'
        Category    = 'Audio / TV'
        Tags        = @('Music', 'Streaming', 'Audio', 'Podcasts')
        Winget      = 'Spotify.Spotify'
    },
    @{
        Name        = 'Audacity'
        Description = 'Kostenloser Audio-Editor und Recorder für mehrspurige Bearbeitung'
        Version     = 'Aktuell'
        DownloadUrl = 'https://www.audacityteam.org/download/'
        Category    = 'Audio / TV'
        Tags        = @('Audio', 'Editor', 'Recording', 'Open-Source')
        Winget      = 'Audacity.Audacity'
    },
    @{
        Name        = 'OBS Studio'
        Description = 'Professionelle Software für Video-Aufnahme und Live-Streaming'
        Version     = 'Aktuell'
        DownloadUrl = 'https://obsproject.com/'
        Category    = 'Audio / TV'
        Tags        = @('Streaming', 'Recording', 'Video', 'Broadcasting')
        Winget      = 'OBSProject.OBSStudio'
    },
    @{
        Name        = 'Sky Go'
        Description = 'Streaming-App für Sky Abonnenten mit Live-TV und On-Demand Inhalten'
        Version     = 'Aktuell'
        DownloadUrl = 'https://www.sky.de/produkte/sky-go'
        Category    = 'Audio / TV'
        Tags        = @('Streaming', 'TV', 'Video', 'Entertainment')
        Winget      = 'Sky.SkyGo'
    },
    @{
        Name        = 'EarTrumpet'
        Description = 'Erweiterte Lautstärkeregelung für Windows mit individueller App-Kontrolle'
        Version     = 'Aktuell'
        DownloadUrl = 'https://eartrumpet.app/'
        Category    = 'Audio / TV'
        Tags        = @('Audio', 'Volume Control', 'System Utility', 'Open-Source')
        Winget      = 'File-New-Project.EarTrumpet'
    },
    @{
        Name        = 'SteelSeries GG'
        Description = 'Gaming-Software für SteelSeries Hardware mit Audio-Anpassungen'
        Version     = 'Aktuell'
        DownloadUrl = 'https://steelseries.com/gg'
        Category    = 'Audio / TV'
        Tags        = @('Gaming', 'Audio', 'Hardware', 'Configuration')
        Winget      = 'SteelSeries.GG'
    },
    @{
        Name        = 'MIXLINE'
        Description = 'Audio-Mixer und Routing-Software für professionelle Anwendungen'
        Version     = 'Aktuell'
        DownloadUrl = 'https://mixline.app/'
        Category    = 'Audio / TV'
        Tags        = @('Audio', 'Mixer', 'Professional', 'Routing')
        Winget      = 'Logitech.MIXLINE'
    },
    @{
        Name        = 'Voicemeeter Potato'
        Description = 'Virtueller Audio-Mixer mit erweiterten Routing-Funktionen'
        Version     = 'Aktuell'
        DownloadUrl = 'https://vb-audio.com/Voicemeeter/potato.htm'
        Category    = 'Audio / TV'
        Tags        = @('Audio', 'Mixer', 'Virtual Device', 'Streaming')
        Winget      = 'VB-Audio.Voicemeeter.Potato'
    }
)

# Browser-Tools (Veraltete Kategorie - jetzt in applications)
$script:toolLibrary['browser'] = @()

# Kommunikations-Tools (Veraltete Kategorie - jetzt in applications)
$script:toolLibrary['communication'] = @()

# Coding / IT Tools hinzufügen
$script:toolLibrary['coding'] = @(
    @{
        Name        = 'PuTTY'
        Description = 'SSH- und Telnet-Client für Windows'
        Version     = 'Aktuell'
        DownloadUrl = 'https://www.putty.org/'
        Category    = 'Coding / IT'
        Tags        = @('SSH', 'Telnet', 'Remote', 'Terminal')
        Winget      = 'PuTTY.PuTTY'
    },
    @{
        Name        = 'WinSCP'
        Description = 'SFTP-, FTP- und SCP-Client für Windows'
        Version     = 'Aktuell'
        DownloadUrl = 'https://winscp.net/eng/download.php'
        Category    = 'Coding / IT'
        Tags        = @('FTP', 'SFTP', 'SCP', 'File Transfer')
        Winget      = 'WinSCP.WinSCP'
    },
    @{
        Name        = 'Visual Studio Code'
        Description = 'Leistungsstarker Code-Editor von Microsoft für Entwickler'
        Version     = 'Aktuell'
        DownloadUrl = 'https://code.visualstudio.com/download'
        Category    = 'Coding / IT'
        Tags        = @('Editor', 'IDE', 'Development', 'Programming')
        Winget      = 'Microsoft.VisualStudioCode'
    },
    @{
        Name        = 'Notepad++'
        Description = 'Kostenloser Quelltext-Editor und Notepad-Ersatz'
        Version     = 'Aktuell'
        DownloadUrl = 'https://notepad-plus-plus.org/downloads/'
        Category    = 'Coding / IT'
        Tags        = @('Editor', 'Text Editor', 'Programming', 'Development')
        Winget      = 'Notepad++.Notepad++'
    },
    @{
        Name        = 'PowerShell'
        Description = 'Plattformübergreifende Task-Automatisierung und Konfigurationsverwaltung'
        Version     = 'Aktuell'
        DownloadUrl = 'https://github.com/PowerShell/PowerShell/releases'
        Category    = 'Coding / IT'
        Tags        = @('Shell', 'Scripting', 'Automation', 'Command Line')
        Winget      = 'Microsoft.PowerShell'
    },
    @{
        Name        = 'WireGuard'
        Description = 'Modernes VPN mit State-of-the-Art-Verschlüsselung'
        Version     = 'Aktuell'
        DownloadUrl = 'https://www.wireguard.com/install/'
        Category    = 'Coding / IT'
        Tags        = @('VPN', 'Security', 'Network', 'Encryption')
        Winget      = 'WireGuard.WireGuard'
    }
)

# Hilfsfunktion zum Abflachen von Arrays
function Flatten {
    param (
        [Parameter(ValueFromPipeline = $true)]
        [object[]]$InputObject
    )
    
    process {
        foreach ($item in $InputObject) {
            $item
        }
    }
}

# Funktion zum Abrufen aller Tools
function Get-AllTools {
    return $script:toolLibrary.Values | ForEach-Object { $_ } | Flatten
}

# Funktion zum Abrufen von Tools nach Kategorie
function Get-ToolsByCategory {
    param (
        [string]$Category
    )
    
    if ($script:toolLibrary.Contains($Category.ToLower())) {
        return $script:toolLibrary[$Category.ToLower()]
    }
    return $null
}

# Funktion zum Abrufen von Tools nach Tag
function Get-ToolsByTag {
    param (
        [string]$Tag
    )
    
    return $script:toolLibrary.Values | ForEach-Object { $_ } | Flatten | Where-Object { $_.Tags -contains $Tag }
}

# Funktion zum Abrufen von Tools nach Name
function Get-ToolByName {
    param (
        [string]$Name
    )
    
    return $script:toolLibrary.Values | ForEach-Object { $_ } | Flatten | Where-Object { $_.Name -eq $Name }
}

# Diese Funktion wurde entfernt, da eine moderne WPF-Implementierung verwendet wird

# Funktion zum Herunterladen eines Tools
function Get-ToolDownload {
    param (
        [string]$ToolName,
        [string]$InstallPath = "$env:ProgramFiles"
    )
    
    $tool = $script:toolLibrary.Values | ForEach-Object { $_ } | Flatten | Where-Object { $_.Name -eq $ToolName }
    if (-not $tool) {
        [System.Windows.Forms.MessageBox]::Show(
            "Das Tool '$ToolName' ist nicht in der Liste verfügbar.",
            "Fehler",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
        return $false
    }
    
    try {
        # Öffne den Download-Link im Standard-Browser
        Start-Process $tool.DownloadUrl
        
        [System.Windows.Forms.MessageBox]::Show(
            "Der Download-Link für $($tool.Name) wurde in Ihrem Browser geöffnet.`n`nBitte folgen Sie den Anweisungen auf der Website, um das Tool herunterzuladen und zu installieren.",
            "Download gestartet",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        )
        return $true
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show(
            "Fehler beim Öffnen des Download-Links: $_",
            "Fehler",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
        return $false
    }
}

# Funktion zum Herunterladen und Installieren von Tools
function Install-ToolPackage {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ToolName,
        
        [Parameter(Mandatory = $false)]
        [string]$DownloadPath = "$env:TEMP\ToolDownloads",
        
        [Parameter(Mandatory = $false)]
        [switch]$AutoInstall
    )
    
    # Erstelle Download-Verzeichnis, falls es nicht existiert
    if (-not (Test-Path $DownloadPath)) {
        New-Item -ItemType Directory -Path $DownloadPath | Out-Null
    }
    
    # Suche das Tool in der Bibliothek
    $tool = Get-ToolByName -Name $ToolName
    if (-not $tool) {
        Write-Error "Tool '$ToolName' wurde nicht in der Bibliothek gefunden."
        return $false
    }
    
    try {
        # Generiere einen eindeutigen Dateinamen
        $fileName = "$($tool.Name)_$($tool.Version).exe"
        $filePath = Join-Path $DownloadPath $fileName
        
        # Lade das Tool herunter
        Write-Host "Lade $($tool.Name) herunter..."
        Invoke-WebRequest -Uri $tool.DownloadUrl -OutFile $filePath
        
        if ($AutoInstall) {
            Write-Host "Starte Installation von $($tool.Name)..."
            Start-Process -FilePath $filePath -ArgumentList "/S" -Wait
            Write-Host "Installation abgeschlossen."
        }
        
        return $true
    }
    catch {
        Write-Error "Fehler beim Herunterladen/Installieren von $($tool.Name): $_"
        return $false
    }
}

# Funktion zum Prüfen und Beenden von Tool-Prozessen
function Stop-ToolProcess {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ProcessName,
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    
    $processes = Get-Process -Name $ProcessName -ErrorAction SilentlyContinue
    
    if ($processes) {
        if ($Force) {
            $processes | Stop-Process -Force
            return $true
        } else {
            $result = [System.Windows.Forms.MessageBox]::Show(
                "$ProcessName läuft noch ($($processes.Count) Instanz(en)).`n`nMöchten Sie den Prozess beenden, um fortzufahren?",
                "Prozess läuft",
                [System.Windows.Forms.MessageBoxButtons]::YesNo,
                [System.Windows.Forms.MessageBoxIcon]::Warning
            )
            
            if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
                try {
                    $processes | Stop-Process -Force
                    Start-Sleep -Milliseconds 500  # Kurz warten bis Prozess beendet ist
                    return $true
                }
                catch {
                    [System.Windows.Forms.MessageBox]::Show(
                        "Fehler beim Beenden des Prozesses: $($_.Exception.Message)",
                        "Fehler",
                        [System.Windows.Forms.MessageBoxButtons]::OK,
                        [System.Windows.Forms.MessageBoxIcon]::Error
                    )
                    return $false
                }
            }
            return $false
        }
    }
    return $true  # Kein Prozess läuft
}

# Funktion zum Interpretieren von Winget-Fehlercodes
function Get-WingetErrorDescription {
    param ([int]$ErrorCode)
    
    switch ($ErrorCode) {
        -2147023728 { return "Datei/Prozess wird verwendet. Bitte schließen Sie die Anwendung." }
        -1978335191 { return "Paket nicht gefunden oder keine Internetverbindung." }
        -1978335212 { return "Installation wurde abgebrochen." }
        -1978335189 { return "Installation fehlgeschlagen (Hash-Fehler oder beschädigte Datei)." }
        -1978335222 { return "Administratorrechte erforderlich." }
        -1978335145 { return "Portable-Paket wurde geändert. Verwenden Sie 'winget uninstall --id <ID> --force' zum Deinstallieren." }
        0x80070005   { return "Zugriff verweigert (Admin-Rechte erforderlich)." }
        0x800704C7   { return "Vorgang wurde abgebrochen oder Datei wird verwendet." }
        default      { return "Unbekannter Fehler. Winget-Exit-Code: $ErrorCode" }
    }
}

# Funktion zum Aktualisieren des Fortschritts
function Update-ToolProgress {
    param (
        [string]$statusText,
        [int]$progressValue,
        [System.Drawing.Color]$textColor = [System.Drawing.Color]::White
    )
    
    if (Test-Path Variable:\progressBar) {
        $progressBar.Value = $progressValue
        
        # Verwende die CustomText-Eigenschaft der TextProgressBar
        if ($progressBar.GetType().Name -eq "TextProgressBar") {
            $progressBar.CustomText = $statusText
            $progressBar.TextColor = $textColor
        }
    }
    
    # UI aktualisieren
    [System.Windows.Forms.Application]::DoEvents()
}

# Ressourcen-Dictionary für Tool-Kacheln
$script:toolResourceDictionary = @{
    ToolTileMargins             = New-Object Windows.Thickness(5)
    ToolTileFontSize            = 14
    ToolTileBorderThickness     = New-Object Windows.Thickness(1)
    ToolTileWidth               = 360
    ToolTileWidthLarge          = 240
    ToolTileWidthMedium         = 360
    ToolTileWidthList           = 730
    ToolInstallUnselectedColor  = [Windows.Media.Brushes]::White
    ToolInstallHighlightedColor = [Windows.Media.Brushes]::LightGray
    MainForegroundColor         = [Windows.Media.Brushes]::Black
    CategoryForegroundColor     = [Windows.Media.Brushes]::Gray
}

# Funktion zum Setzen von Ressourcen
function Set-ToolResource {
    param ($control, $property, $key)
    $control.$property = $script:toolResourceDictionary[$key]
}

# Funktion zum Erstellen einer Tool-Kachel
function Initialize-ToolEntry {
    param(
        [Windows.Controls.WrapPanel]$TargetElement,
        $Tool,
        [string]$TileSize = "Medium"  # Large, Medium, List
    )
    
    # Wenn das Tool null ist, frühzeitig beenden
    if ($null -eq $Tool) {
        Write-Warning "Initialize-ToolEntry: NULL-Tool wurde übergeben. Tool wird übersprungen."
        return
    }
    
    # Bestimme die Breite basierend auf TileSize
    $tileWidth = switch ($TileSize) {
        "Large"  { $script:toolResourceDictionary["ToolTileWidthLarge"] }
        "Medium" { $script:toolResourceDictionary["ToolTileWidthMedium"] }
        "List"   { $script:toolResourceDictionary["ToolTileWidthList"] }
        default  { $script:toolResourceDictionary["ToolTileWidthMedium"] }
    }
    
    $border = New-Object Windows.Controls.Border
    $border.BorderThickness = $script:toolResourceDictionary["ToolTileBorderThickness"]
    $border.CornerRadius = 8
    $border.Padding = if ($TileSize -eq "List") { New-Object Windows.Thickness(3, 2, 3, 2) } else { $script:toolResourceDictionary["ToolTileMargins"] }
    $border.Width = $tileWidth
    $border.MinHeight = if ($TileSize -eq "Large") { 180 } else { 0 }  # Mindesthöhe für kleine Kacheln
    $border.VerticalAlignment = "Top"
    $border.Margin = if ($TileSize -eq "List") { New-Object Windows.Thickness(5, 2, 5, 2) } else { $script:toolResourceDictionary["ToolTileMargins"] }
    $border.Cursor = [System.Windows.Input.Cursors]::Hand

    # Prüfen, ob das Tool bereits installiert ist und entsprechend hervorheben
    $isInstalled = Test-ToolInstalled -Tool $Tool
    $hasUpdate = $false
    $versionInfo = $null
    
    # Wenn installiert, hole Versionsinformationen
    if ($isInstalled -and $Tool.Winget) {
        $versionInfo = Get-ToolVersionInfo -Tool $Tool
        $hasUpdate = $versionInfo.HasUpdate
    }
    
    # DEBUG: Ausgabe für Fehlersuche
    $debugMsg = "Tool: $($Tool.Name) | Winget: $($Tool.Winget) | Installiert: $isInstalled | Update: $hasUpdate"
    if ($versionInfo) {
        $debugMsg += " | Installiert: $($versionInfo.InstalledVersion) | Verfügbar: $($versionInfo.AvailableVersion)"
    }
    $debugMsg += " | Cache-Status: $(if ($null -ne $script:installedPackagesCache) { 'Geladen' } else { 'Leer' })"
    Write-Verbose $debugMsg
    Write-Host $debugMsg -ForegroundColor Cyan
    
    # Farben basierend auf Status
    if ($hasUpdate) {
        # Update verfügbar - Orange/Gelb
        $border.Background = [Windows.Media.Brushes]::LightGoldenrodYellow
        $border.BorderBrush = [Windows.Media.Brushes]::Orange
    }
    elseif ($isInstalled -eq $true) {
        # Installiert und aktuell - Grün
        $border.Background = [Windows.Media.Brushes]::LightGreen
        $border.BorderBrush = [Windows.Media.Brushes]::Green
    } 
    else {
        # Nicht installiert - Standard
        $border.Background = $script:toolResourceDictionary["ToolInstallUnselectedColor"]
        $border.BorderBrush = [Windows.Media.Brushes]::LightGray
    }
    
    $border.Tag = $Tool
    $tooltipText = $Tool.Description
    if ($hasUpdate) {
        $tooltipText = "[UPDATE VERFÜGBAR"
        if ($versionInfo -and $versionInfo.InstalledVersion -and $versionInfo.AvailableVersion) {
            $tooltipText += ": $($versionInfo.InstalledVersion) → $($versionInfo.AvailableVersion)"
        }
        $tooltipText += "] " + $Tool.Description
    }
    elseif ($isInstalled) {
        $tooltipText = "[INSTALLIERT"
        if ($versionInfo -and $versionInfo.InstalledVersion) {
            $tooltipText += " v$($versionInfo.InstalledVersion)"
        }
        $tooltipText += "] " + $Tool.Description
    }
    $border.ToolTip = $tooltipText

    # Hover-Effekt mit Berücksichtigung des installierten Status und Update-Status
    $installedStatus = $isInstalled
    $updateStatus = $hasUpdate
    
    # Farben direkt in lokale Variablen speichern, um auf Dictionary-Zugriffe zu verzichten
    $highlightColor = if ($script:toolResourceDictionary -and $script:toolResourceDictionary["ToolInstallHighlightedColor"]) {
        $script:toolResourceDictionary["ToolInstallHighlightedColor"]
    } else {
        [Windows.Media.Brushes]::LightGray
    }
    
    $unselectedColor = if ($script:toolResourceDictionary -and $script:toolResourceDictionary["ToolInstallUnselectedColor"]) {
        $script:toolResourceDictionary["ToolInstallUnselectedColor"]
    } else {
        [Windows.Media.Brushes]::White
    }
    
    # Diese Variablen in die Closures übergeben
    $border.Add_MouseEnter({
            if ($updateStatus) {
                $this.Background = [Windows.Media.Brushes]::Gold
            }
            elseif ($installedStatus) {
                $this.Background = [Windows.Media.Brushes]::MediumSeaGreen
            } else {
                $this.Background = $highlightColor
            }
        }.GetNewClosure())
    $border.Add_MouseLeave({
            if ($updateStatus) {
                $this.Background = [Windows.Media.Brushes]::LightGoldenrodYellow
            }
            elseif ($installedStatus) {
                $this.Background = [Windows.Media.Brushes]::LightGreen
            } else {
                $this.Background = $unselectedColor
            }
        }.GetNewClosure())

    # Layout abhängig von TileSize
    $isListView = ($TileSize -eq "List")
    $isSmallTile = ($TileSize -eq "Large")  # "Large" ist jetzt die kleine Kachel
    
    $dockPanel = New-Object Windows.Controls.DockPanel
    $border.Child = $dockPanel

    # Header mit Icon und Name
    $headerPanel = New-Object Windows.Controls.StackPanel
    $headerPanel.Orientation = "Horizontal"
    $headerPanel.VerticalAlignment = "Center"
    $headerPanel.Margin = if ($isListView) { New-Object Windows.Thickness(0, 0, 0, 2) } elseif ($isSmallTile) { New-Object Windows.Thickness(0, 0, 0, 5) } else { New-Object Windows.Thickness(0, 0, 0, 10) }
    [Windows.Controls.DockPanel]::SetDock($headerPanel, [Windows.Controls.Dock]::Top)

    # Tool-Icon (Platzhalter)
    $iconSize = if ($isListView) { 24 } elseif ($isSmallTile) { 32 } else { 40 }
    $iconBorder = New-Object Windows.Controls.Border
    $iconBorder.Width = $iconSize
    $iconBorder.Height = $iconSize
    $iconBorder.Background = [Windows.Media.Brushes]::LightBlue
    $iconBorder.CornerRadius = 4
    $iconBorder.Margin = if ($isListView) { New-Object Windows.Thickness(0, 0, 5, 0) } else { New-Object Windows.Thickness(0, 0, 10, 0) }
    
    $iconText = New-Object Windows.Controls.TextBlock
    $iconText.Text = $Tool.Name.Substring(0, [Math]::Min(2, $Tool.Name.Length)).ToUpper()
    $iconText.FontSize = 16
    $iconText.FontWeight = [Windows.FontWeights]::Bold
    $iconText.Foreground = [Windows.Media.Brushes]::White
    $iconText.HorizontalAlignment = "Center"
    $iconText.VerticalAlignment = "Center"
    $iconBorder.Child = $iconText
    $headerPanel.Children.Add($iconBorder)

    # Name und Kategorie
    $namePanel = New-Object Windows.Controls.StackPanel
    $namePanel.VerticalAlignment = "Center"
    
    $appName = New-Object Windows.Controls.TextBlock
    $appName.Text = $Tool.Name
    $appName.FontWeight = [Windows.FontWeights]::Bold
    $appName.FontSize = if ($isSmallTile) { 12 } else { $script:toolResourceDictionary["ToolTileFontSize"] }
    $appName.Foreground = $script:toolResourceDictionary["MainForegroundColor"]
    $appName.TextWrapping = if ($isSmallTile) { [Windows.TextWrapping]::Wrap } else { [Windows.TextWrapping]::NoWrap }
    $namePanel.Children.Add($appName)
    
    # Kategorie nur bei mittleren Kacheln und Liste anzeigen
    if (-not $isSmallTile) {
        $categoryBlock = New-Object Windows.Controls.TextBlock
        $categoryBlock.Text = "Kategorie: " + $Tool.Category
        $categoryBlock.FontSize = 12
        $categoryBlock.Foreground = $script:toolResourceDictionary["CategoryForegroundColor"]
        $namePanel.Children.Add($categoryBlock)
    }
    
    # Status-Anzeige hinzufügen, falls Winget-Paket
    if ($Tool.Winget) {
        $statusBlock = New-Object Windows.Controls.TextBlock
        $statusBlock.FontSize = 10
        
        if ($hasUpdate) {
            $statusText = "⚠ Update verfügbar"
            if ($versionInfo -and $versionInfo.InstalledVersion -and $versionInfo.AvailableVersion) {
                $statusText = "⚠ Update: $($versionInfo.InstalledVersion) → $($versionInfo.AvailableVersion)"
            }
            $statusBlock.Text = $statusText
            $statusBlock.Foreground = [Windows.Media.Brushes]::DarkOrange
            $statusBlock.FontWeight = [Windows.FontWeights]::Bold
        }
        elseif ($isInstalled) {
            $statusText = "✓ Installiert"
            if ($versionInfo -and $versionInfo.InstalledVersion) {
                $statusText = "✓ Installiert (v$($versionInfo.InstalledVersion))"
            }
            $statusBlock.Text = $statusText
            $statusBlock.Foreground = [Windows.Media.Brushes]::Green
            $statusBlock.FontWeight = [Windows.FontWeights]::Bold
        } else {
            $statusBlock.Text = "Nicht installiert"
            $statusBlock.Foreground = [Windows.Media.Brushes]::Gray
        }
        
        $namePanel.Children.Add($statusBlock)
    }
    
    $headerPanel.Children.Add($namePanel)
    $dockPanel.Children.Add($headerPanel)

    # Beschreibungsbereich (in Listenansicht und kleinen Kacheln kürzer)
    $descPanel = New-Object Windows.Controls.StackPanel
    $descPanel.Margin = if ($isListView) { New-Object Windows.Thickness(0, 0, 0, 2) } elseif ($isSmallTile) { New-Object Windows.Thickness(0, 0, 0, 5) } else { New-Object Windows.Thickness(0, 0, 0, 10) }
    $descPanel.MinHeight = if ($isListView -or $isSmallTile) { 0 } else { 40 }  # Mindesthöhe für einheitliche Kacheln (außer Liste und kleine Kacheln)
    [Windows.Controls.DockPanel]::SetDock($descPanel, [Windows.Controls.Dock]::Top)
    
    $descLabel = New-Object Windows.Controls.TextBlock
    if ($isListView) {
        # Listenansicht: Nur eine Zeile Beschreibung
        $descLabel.Text = if ($Tool.Description.Length -gt 80) { 
            $Tool.Description.Substring(0, 80) + "..." 
        } else { 
            $Tool.Description 
        }
        $descLabel.TextWrapping = [Windows.TextWrapping]::NoWrap
    } elseif ($isSmallTile) {
        # Kleine Kacheln: Sehr kurze Beschreibung
        $descLabel.Text = if ($Tool.Description.Length -gt 50) { 
            $Tool.Description.Substring(0, 50) + "..." 
        } else { 
            $Tool.Description 
        }
        $descLabel.TextWrapping = [Windows.TextWrapping]::Wrap
    } else {
        # Mittlere Kachel-Ansicht: Mehrzeilige Beschreibung
        $descLabel.Text = if ($Tool.Description.Length -gt 120) { 
            $Tool.Description.Substring(0, 120) + "..." 
        } else { 
            $Tool.Description 
        }
        $descLabel.TextWrapping = [Windows.TextWrapping]::Wrap
    }
    $descLabel.FontSize = if ($isListView) { 10 } elseif ($isSmallTile) { 10 } else { 12 }
    $descLabel.Margin = if ($isListView) { New-Object Windows.Thickness(5, 0, 5, 0) } else { New-Object Windows.Thickness(5) }
    $descPanel.Children.Add($descLabel)
    $dockPanel.Children.Add($descPanel)

    # Button Panel
    $buttonPanel = New-Object Windows.Controls.StackPanel
    $buttonPanel.Orientation = "Horizontal"
    $buttonPanel.HorizontalAlignment = "Right"
    $buttonPanel.VerticalAlignment = "Center"
    [Windows.Controls.DockPanel]::SetDock($buttonPanel, [Windows.Controls.Dock]::Bottom)

    # Info/Beschreibung Button
    $infoButton = New-Object Windows.Controls.Button
    $infoButton.Width = if ($isListView) { 40 } else { 45 }
    $infoButton.Height = if ($isListView) { 28 } else { 35 }
    $infoButton.Margin = if ($isListView) { New-Object Windows.Thickness(1) } else { New-Object Windows.Thickness(2) }
    $infoIcon = New-Object Windows.Controls.TextBlock
    $infoIcon.Text = [char]0xE946  # Info-Symbol
    $infoIcon.FontFamily = New-Object Windows.Media.FontFamily("Segoe MDL2 Assets")
    $infoIcon.FontSize = if ($isListView) { 16 } else { 20 }
    $infoIcon.Foreground = [Windows.Media.Brushes]::Blue
    $infoButton.Content = $infoIcon
    $infoButton.ToolTip = "Detaillierte Informationen anzeigen"
    $infoButton.Tag = @{ Tool = $Tool; VersionInfo = $versionInfo; IsInstalled = $isInstalled }
    $infoButton.Add_Click({
            $buttonData = $this.Tag
            $toolInfo = $buttonData.Tool
            $versionInfo = $buttonData.VersionInfo
            $isInstalled = $buttonData.IsInstalled
        
            $infoText = "TOOL INFORMATION`n"
            $infoText += "═══════════════════════════`n`n"
            $infoText += "Name: $($toolInfo.Name)`n"
            
            # Versionsinformationen anzeigen
            if ($isInstalled -and $versionInfo) {
                if ($versionInfo.InstalledVersion) {
                    $infoText += "Installierte Version: $($versionInfo.InstalledVersion)`n"
                }
                if ($versionInfo.HasUpdate -and $versionInfo.AvailableVersion) {
                    $infoText += "Verfügbare Version: $($versionInfo.AvailableVersion) ⚠`n"
                }
            }
            elseif ($toolInfo.Version) {
                $infoText += "Version: $($toolInfo.Version)`n"
            }
            
            $infoText += "Kategorie: $($toolInfo.Category)`n"
            
            # Installationsstatus
            if ($isInstalled) {
                if ($versionInfo -and $versionInfo.HasUpdate) {
                    $infoText += "Status: INSTALLIERT (Update verfügbar)`n`n"
                }
                else {
                    $infoText += "Status: INSTALLIERT (Aktuell)`n`n"
                }
            }
            else {
                $infoText += "Status: Nicht installiert`n`n"
            }
            
            $infoText += "Beschreibung:`n$($toolInfo.Description)`n`n"
            $infoText += "Tags: $($toolInfo.Tags -join ', ')`n"
            if ($toolInfo.Winget) { 
                $infoText += "Winget-Paket: $($toolInfo.Winget)`n" 
            }
            $infoText += "Download-URL: $($toolInfo.DownloadUrl)`n"
        
            [System.Windows.Forms.MessageBox]::Show(
                $infoText,
                "Information - $($toolInfo.Name)",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Information
            )
        })
    $buttonPanel.Children.Add($infoButton)

    # Download Button (Winget, falls verfügbar)
    if ($Tool.Winget) {
        $wingetButton = New-Object Windows.Controls.Button
        $wingetButton.Width = if ($isListView) { 40 } else { 45 }
        $wingetButton.Height = if ($isListView) { 28 } else { 35 }
        $wingetButton.Margin = if ($isListView) { New-Object Windows.Thickness(1) } else { New-Object Windows.Thickness(2) }
        $wingetIcon = New-Object Windows.Controls.TextBlock
        
        # Icon und Tooltip basierend auf Status
        if ($hasUpdate) {
            $wingetIcon.Text = [char]0xE117  # Update-Symbol (Sync)
            $wingetIcon.Foreground = [Windows.Media.Brushes]::DarkOrange
            $wingetButton.ToolTip = "Update mit Winget durchführen"
            $wingetButton.Background = [Windows.Media.Brushes]::LightYellow
        }
        elseif ($isInstalled) {
            $wingetIcon.Text = [char]0xE117  # Sync-Symbol
            $wingetIcon.Foreground = [Windows.Media.Brushes]::Green
            $wingetButton.ToolTip = "Mit Winget neu installieren/reparieren"
        }
        else {
            $wingetIcon.Text = [char]0xE118  # Download-Symbol
            $wingetIcon.Foreground = [Windows.Media.Brushes]::Green
            $wingetButton.ToolTip = "Mit Winget installieren"
        }
        
        $wingetIcon.FontFamily = New-Object Windows.Media.FontFamily("Segoe MDL2 Assets")
        $wingetIcon.FontSize = 20
        $wingetButton.Content = $wingetIcon
        $wingetButton.Tag = @{ Tool = $Tool; HasUpdate = $hasUpdate; IsInstalled = $isInstalled }
        
        $wingetButton.Add_Click({
                $buttonData = $this.Tag
                $toolInfo = $buttonData.Tool
                $hasUpdate = $buttonData.HasUpdate
                $isInstalled = $buttonData.IsInstalled
                
                try {
                    if ($hasUpdate) {
                        # Prüfe ob Prozess läuft (z.B. LibreHardwareMonitor)
                        $processName = $toolInfo.Name -replace '\s+', ''  # Entferne Leerzeichen
                        $canContinue = Stop-ToolProcess -ProcessName $processName
                        
                        if (-not $canContinue) {
                            [System.Windows.Forms.MessageBox]::Show(
                                "Update abgebrochen.`n`nBitte schließen Sie $($toolInfo.Name) manuell und versuchen Sie es erneut.",
                                "Update abgebrochen",
                                [System.Windows.Forms.MessageBoxButtons]::OK,
                                [System.Windows.Forms.MessageBoxIcon]::Information
                            )
                            return
                        }
                        
                        # Update durchführen mit Fortschrittsanzeige
                        [System.Windows.Forms.MessageBox]::Show(
                            "Update für $($toolInfo.Name) wird gestartet.`n`nBitte warten Sie, bis das Update abgeschlossen ist.",
                            "Update - $($toolInfo.Name)",
                            [System.Windows.Forms.MessageBoxButtons]::OK,
                            [System.Windows.Forms.MessageBoxIcon]::Information
                        )
                        
                        $psi = New-Object System.Diagnostics.ProcessStartInfo
                        $psi.FileName = "winget"
                        $psi.Arguments = "upgrade --id `"$($toolInfo.Winget)`" --silent --accept-source-agreements --accept-package-agreements"
                        $psi.Verb = "RunAs"
                        $psi.UseShellExecute = $true
                        $psi.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden
                        
                        $process = [System.Diagnostics.Process]::Start($psi)
                        if ($process.WaitForExit(300000)) {
                            if ($process.ExitCode -eq 0) {
                                [System.Windows.Forms.MessageBox]::Show(
                                    "$($toolInfo.Name) wurde erfolgreich aktualisiert!",
                                    "Update erfolgreich",
                                    [System.Windows.Forms.MessageBoxButtons]::OK,
                                    [System.Windows.Forms.MessageBoxIcon]::Information
                                )
                            } else {
                                $errorDesc = Get-WingetErrorDescription -ErrorCode $process.ExitCode
                                [System.Windows.Forms.MessageBox]::Show(
                                    "Update fehlgeschlagen!`n`nFehlercode: $($process.ExitCode)`n`n$errorDesc`n`nDebug-Tipp: Führen Sie 'winget upgrade --id $($toolInfo.Winget)' in PowerShell aus.",
                                    "Update fehlgeschlagen",
                                    [System.Windows.Forms.MessageBoxButtons]::OK,
                                    [System.Windows.Forms.MessageBoxIcon]::Warning
                                )
                            }
                        } else {
                            [System.Windows.Forms.MessageBox]::Show(
                                "Update-Timeout (>5 Min). Bitte manuell prüfen.",
                                "Timeout",
                                [System.Windows.Forms.MessageBoxButtons]::OK,
                                [System.Windows.Forms.MessageBoxIcon]::Warning
                            )
                        }
                    }
                    elseif ($isInstalled) {
                        # Neu installieren/reparieren
                        $result = [System.Windows.Forms.MessageBox]::Show(
                            "Möchten Sie $($toolInfo.Name) neu installieren/reparieren?",
                            "Neuinstallation",
                            [System.Windows.Forms.MessageBoxButtons]::YesNo,
                            [System.Windows.Forms.MessageBoxIcon]::Question
                        )
                        if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
                            # Prüfe ob Prozess läuft (z.B. LibreHardwareMonitor)
                            $processName = $toolInfo.Name -replace '\s+', ''  # Entferne Leerzeichen
                            $canContinue = Stop-ToolProcess -ProcessName $processName
                            
                            if (-not $canContinue) {
                                [System.Windows.Forms.MessageBox]::Show(
                                    "Neuinstallation abgebrochen.`n`nBitte schließen Sie $($toolInfo.Name) manuell und versuchen Sie es erneut.",
                                    "Neuinstallation abgebrochen",
                                    [System.Windows.Forms.MessageBoxButtons]::OK,
                                    [System.Windows.Forms.MessageBoxIcon]::Information
                                )
                                return
                            }
                            
                            [System.Windows.Forms.MessageBox]::Show(
                                "Neuinstallation von $($toolInfo.Name) wird gestartet.`n`nBitte warten Sie, bis die Installation abgeschlossen ist.",
                                "Neuinstallation - $($toolInfo.Name)",
                                [System.Windows.Forms.MessageBoxButtons]::OK,
                                [System.Windows.Forms.MessageBoxIcon]::Information
                            )
                            
                            $psi = New-Object System.Diagnostics.ProcessStartInfo
                            $psi.FileName = "winget"
                            $psi.Arguments = "install --id `"$($toolInfo.Winget)`" --force --silent --accept-source-agreements --accept-package-agreements"
                            $psi.Verb = "RunAs"
                            $psi.UseShellExecute = $true
                            $psi.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden
                            
                            $process = [System.Diagnostics.Process]::Start($psi)
                            if ($process.WaitForExit(300000)) {
                                if ($process.ExitCode -eq 0) {
                                    # Spezialbehandlung für LibreHardwareMonitor
                                    $driverActivated = $false
                                    if ($toolInfo.Winget -eq "LibreHardwareMonitor.LibreHardwareMonitor") {
                                        if (Get-Command -Name Invoke-LibreHardwareMonitorDriverActivation -ErrorAction SilentlyContinue) {
                                            $driverActivated = Invoke-LibreHardwareMonitorDriverActivation
                                        }
                                    }
                                    
                                    $message = "$($toolInfo.Name) wurde erfolgreich neu installiert!"
                                    if ($toolInfo.Winget -eq "LibreHardwareMonitor.LibreHardwareMonitor") {
                                        if ($driverActivated) {
                                            $message += "`n`n✅ Hardware-Treiber wurde aktiviert!`n`nBitte starten Sie Bockis System-Tool neu."
                                        } else {
                                            $message += "`n`n⚠️ Bitte starten Sie Bockis System-Tool neu."
                                        }
                                    }
                                    
                                    [System.Windows.Forms.MessageBox]::Show(
                                        $message,
                                        "Neuinstallation erfolgreich",
                                        [System.Windows.Forms.MessageBoxButtons]::OK,
                                        [System.Windows.Forms.MessageBoxIcon]::Information
                                    )
                                } else {
                                    $errorDesc = Get-WingetErrorDescription -ErrorCode $process.ExitCode
                                    [System.Windows.Forms.MessageBox]::Show(
                                        "Neuinstallation fehlgeschlagen!`n`nFehlercode: $($process.ExitCode)`n`n$errorDesc`n`nDebug-Tipp: Führen Sie 'winget install --id $($toolInfo.Winget) --force' in PowerShell aus.",
                                        "Fehler",
                                        [System.Windows.Forms.MessageBoxButtons]::OK,
                                        [System.Windows.Forms.MessageBoxIcon]::Warning
                                    )
                                }
                            } else {
                                [System.Windows.Forms.MessageBox]::Show(
                                    "Neuinstallation-Timeout (>5 Min). Bitte manuell prüfen.",
                                    "Timeout",
                                    [System.Windows.Forms.MessageBoxButtons]::OK,
                                    [System.Windows.Forms.MessageBoxIcon]::Warning
                                )
                            }
                        }
                    }
                    else {
                        # Erstinstallation mit Fortschrittsanzeige
                        [System.Windows.Forms.MessageBox]::Show(
                            "Installation von $($toolInfo.Name) wird gestartet.`n`nBitte warten Sie, bis die Installation abgeschlossen ist.`n`nDie Anwendung wird nach Abschluss automatisch benachrichtigt.",
                            "Installation - $($toolInfo.Name)",
                            [System.Windows.Forms.MessageBoxButtons]::OK,
                            [System.Windows.Forms.MessageBoxIcon]::Information
                        )
                        
                        # Starte Installation und warte auf Fertigstellung
                        $psi = New-Object System.Diagnostics.ProcessStartInfo
                        $psi.FileName = "winget"
                        $psi.Arguments = "install --id `"$($toolInfo.Winget)`" --silent --accept-source-agreements --accept-package-agreements"
                        $psi.Verb = "RunAs"
                        $psi.UseShellExecute = $true
                        $psi.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden
                        
                        try {
                            $process = [System.Diagnostics.Process]::Start($psi)
                            
                            # Warte auf Prozessende (max 5 Minuten)
                            if ($process.WaitForExit(300000)) {
                                $exitCode = $process.ExitCode
                                if ($exitCode -eq 0) {
                                    # Spezialbehandlung für LibreHardwareMonitor
                                    $driverActivated = $false
                                    if ($toolInfo.Winget -eq "LibreHardwareMonitor.LibreHardwareMonitor") {
                                        # Versuche Treiber-Aktivierung
                                        if (Get-Command -Name Invoke-LibreHardwareMonitorDriverActivation -ErrorAction SilentlyContinue) {
                                            $driverActivated = Invoke-LibreHardwareMonitorDriverActivation
                                        }
                                    }
                                    
                                    $message = "$($toolInfo.Name) wurde erfolgreich installiert!"
                                    if ($toolInfo.Winget -eq "LibreHardwareMonitor.LibreHardwareMonitor") {
                                        if ($driverActivated) {
                                            $message += "`n`n✅ Hardware-Treiber wurde aktiviert!`n`nBitte starten Sie Bockis System-Tool neu."
                                        } else {
                                            $message += "`n`n⚠️ Bitte starten Sie LibreHardwareMonitor.exe einmal manuell,`num den Hardware-Treiber zu aktivieren.`n`nDanach: Bockis System-Tool neu starten."
                                        }
                                    }
                                    
                                    [System.Windows.Forms.MessageBox]::Show(
                                        $message,
                                        "Installation erfolgreich",
                                        [System.Windows.Forms.MessageBoxButtons]::OK,
                                        [System.Windows.Forms.MessageBoxIcon]::Information
                                    )
                                } else {
                                    $errorDesc = Get-WingetErrorDescription -ErrorCode $exitCode
                                    [System.Windows.Forms.MessageBox]::Show(
                                        "Installation fehlgeschlagen!`n`nFehlercode: $exitCode`n`n$errorDesc`n`nDebug-Tipp: Führen Sie 'winget install --id $($toolInfo.Winget)' in PowerShell aus.",
                                        "Installation fehlgeschlagen",
                                        [System.Windows.Forms.MessageBoxButtons]::OK,
                                        [System.Windows.Forms.MessageBoxIcon]::Warning
                                    )
                                }
                            } else {
                                [System.Windows.Forms.MessageBox]::Show(
                                    "Installation von $($toolInfo.Name) dauert zu lange (>5 Min).`n`nBitte prüfen Sie manuell, ob die Installation erfolgreich war.",
                                    "Timeout",
                                    [System.Windows.Forms.MessageBoxButtons]::OK,
                                    [System.Windows.Forms.MessageBoxIcon]::Warning
                                )
                            }
                        }
                        catch {
                            [System.Windows.Forms.MessageBox]::Show(
                                "Fehler beim Starten der Installation: $($_.Exception.Message)",
                                "Fehler",
                                [System.Windows.Forms.MessageBoxButtons]::OK,
                                [System.Windows.Forms.MessageBoxIcon]::Error
                            )
                        }
                    }
                    
                    # Cache aktualisieren, wenn die Funktion verfügbar ist
                    if (Get-Command -Name Update-ToolInstallationStatus -ErrorAction SilentlyContinue) {
                        Update-ToolInstallationStatus -Tool $toolInfo -IsInstalled $true
                    }
                }
                catch {
                    [System.Windows.Forms.MessageBox]::Show(
                        "Fehler beim Starten der Winget-Aktion: $($_.Exception.Message)",
                        "Fehler",
                        [System.Windows.Forms.MessageBoxButtons]::OK,
                        [System.Windows.Forms.MessageBoxIcon]::Error
                    )
                }
            })
        $buttonPanel.Children.Add($wingetButton)
    }

    # Web-Download Button
    $webButton = New-Object Windows.Controls.Button
    $webButton.Width = if ($isListView) { 40 } else { 45 }
    $webButton.Height = if ($isListView) { 28 } else { 35 }
    $webButton.Margin = if ($isListView) { New-Object Windows.Thickness(1) } else { New-Object Windows.Thickness(2) }
    $webIcon = New-Object Windows.Controls.TextBlock
    $webIcon.Text = [char]0xE774  # Web-Symbol
    $webIcon.FontFamily = New-Object Windows.Media.FontFamily("Segoe MDL2 Assets")
    $webIcon.FontSize = if ($isListView) { 16 } else { 20 }
    $webIcon.Foreground = [Windows.Media.Brushes]::Orange
    $webButton.Content = $webIcon
    $webButton.ToolTip = "Von Webseite herunterladen"
    $webButton.Add_Click({
            $toolInfo = $this.Parent.Parent.Parent.Tag
            try {
                Start-Process $toolInfo.DownloadUrl
            }
            catch {
                [System.Windows.Forms.MessageBox]::Show(
                    "Fehler beim Öffnen der Download-URL: $($_.Exception.Message)",
                    "Fehler",
                    [System.Windows.Forms.MessageBoxButtons]::OK,
                    [System.Windows.Forms.MessageBoxIcon]::Error
                )
            }
        })
    $buttonPanel.Children.Add($webButton)

    # Deinstallations-Button (falls Winget verfügbar)
    if ($Tool.Winget) {
        $uninstallButton = New-Object Windows.Controls.Button
        $uninstallButton.Width = if ($isListView) { 40 } else { 45 }
        $uninstallButton.Height = if ($isListView) { 28 } else { 35 }
        $uninstallButton.Margin = if ($isListView) { New-Object Windows.Thickness(1) } else { New-Object Windows.Thickness(2) }
        $uninstallIcon = New-Object Windows.Controls.TextBlock
        $uninstallIcon.Text = [char]0xE74D  # Uninstall-Symbol
        $uninstallIcon.FontFamily = New-Object Windows.Media.FontFamily("Segoe MDL2 Assets")
        $uninstallIcon.FontSize = if ($isListView) { 16 } else { 20 }
        $uninstallIcon.Foreground = [Windows.Media.Brushes]::Red
        $uninstallButton.Content = $uninstallIcon
        $uninstallButton.ToolTip = "Mit Winget deinstallieren"
        $uninstallButton.Add_Click({
                $toolInfo = $this.Parent.Parent.Parent.Tag
                $result = [System.Windows.Forms.MessageBox]::Show(
                    "Möchten Sie $($toolInfo.Name) wirklich deinstallieren?",
                    "Deinstallation bestätigen",
                    [System.Windows.Forms.MessageBoxButtons]::YesNo,
                    [System.Windows.Forms.MessageBoxIcon]::Question
                )
                if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
                    try {
                        Start-Process "winget" -ArgumentList "uninstall", $toolInfo.Winget -Verb RunAs
                        [System.Windows.Forms.MessageBox]::Show(
                            "Deinstallation wurde gestartet.",
                            "Deinstallation - $($toolInfo.Name)",
                            [System.Windows.Forms.MessageBoxButtons]::OK,
                            [System.Windows.Forms.MessageBoxIcon]::Information
                        )
                        
                        # Cache aktualisieren, wenn die Funktion verfügbar ist
                        if (Get-Command -Name Update-ToolInstallationStatus -ErrorAction SilentlyContinue) {
                            Update-ToolInstallationStatus -Tool $toolInfo -IsInstalled $false
                        }
                    }
                    catch {
                        [System.Windows.Forms.MessageBox]::Show(
                            "Fehler beim Starten der Deinstallation: $($_.Exception.Message)",
                            "Fehler",
                            [System.Windows.Forms.MessageBoxButtons]::OK,
                            [System.Windows.Forms.MessageBoxIcon]::Error
                        )
                    }
                }
            })
        $buttonPanel.Children.Add($uninstallButton)
    }

    $dockPanel.Children.Add($buttonPanel)
    $TargetElement.Children.Add($border)
}

# Funktion zum Anzeigen der Tool-Kacheln
function Show-ToolTileList {
    param (
        [Windows.Controls.WrapPanel]$WrapPanel,
        [string]$Category = "all",
        [string]$TileSize = "Medium"
    )
    
    $null = $WrapPanel.Children.Clear()
    
    # Tools nach Kategorie filtern
    $filteredTools = if ($Category -eq "all") {
        Get-AllTools
    }
    else {
        Get-ToolsByCategory -Category $Category
    }
    
    # Tools anzeigen und Rückgabewerte unterdrücken
    foreach ($tool in $filteredTools) {
        $null = Initialize-ToolEntry -TargetElement $WrapPanel -Tool $tool -TileSize $TileSize
    }
}

# Funktion zum Abrufen der Versionsinformationen eines Tools
function Get-ToolVersionInfo {
    param (
        [Parameter(Mandatory = $true)]
        [object]$Tool
    )
    
    # Standardrückgabe wenn keine Winget-ID vorhanden
    if (-not $Tool.Winget) {
        return @{
            InstalledVersion = $null
            AvailableVersion = $null
            HasUpdate = $false
        }
    }
    
    $job = $null
    try {
        # Verwende winget list mit upgrade check
        $job = Start-Job -ScriptBlock {
            param($wingetId)
            
            # Hole beide Informationen: installierte Version und verfügbares Update
            $listOutput = winget list --id $wingetId --exact 2>$null | Out-String
            $upgradeOutput = winget upgrade --id $wingetId --exact 2>$null | Out-String
            
            return @{
                List = $listOutput
                Upgrade = $upgradeOutput
            }
        } -ArgumentList $Tool.Winget
        
        $completed = Wait-Job -Job $job -Timeout 12
        
        if ($completed) {
            $result = Receive-Job -Job $job
            $installedVersion = $null
            $availableVersion = $null
            $hasUpdate = $false
            
            # Parse installierte Version aus winget list
            if ($result.List -match [regex]::Escape($Tool.Winget)) {
                # Versuche Version zu extrahieren (Format: Name ID Version Source)
                $lines = $result.List -split "`n"
                foreach ($line in $lines) {
                    if ($line -match [regex]::Escape($Tool.Winget)) {
                        # Zeile gefunden, extrahiere Version
                        # Typisches Format: "Name    ID    Version    Source"
                        $parts = $line -split '\s+' | Where-Object { $_ -ne '' }
                        if ($parts.Count -ge 3) {
                            # Version ist typischerweise an Position 2 (nach Name und ID)
                            $installedVersion = $parts[2]
                        }
                        break
                    }
                }
            }
            
            # Parse verfügbare Version aus winget upgrade
            if ($result.Upgrade -match [regex]::Escape($Tool.Winget)) {
                $lines = $result.Upgrade -split "`n"
                foreach ($line in $lines) {
                    if ($line -match [regex]::Escape($Tool.Winget)) {
                        # Format: "Name ID Version Available Source"
                        $parts = $line -split '\s+' | Where-Object { $_ -ne '' }
                        if ($parts.Count -ge 4) {
                            # Installierte Version
                            if (-not $installedVersion) {
                                $installedVersion = $parts[2]
                            }
                            # Verfügbare Version
                            $availableVersion = $parts[3]
                            $hasUpdate = $true
                        }
                        break
                    }
                }
            }
            
            return @{
                InstalledVersion = $installedVersion
                AvailableVersion = $availableVersion
                HasUpdate = $hasUpdate
            }
        }
        else {
            Stop-Job -Job $job -ErrorAction SilentlyContinue
            Write-Verbose "Timeout beim Abrufen der Versionsinfo für $($Tool.Name)"
        }
    }
    catch {
        Write-Verbose "Fehler beim Abrufen der Versionsinfo für $($Tool.Name): $_"
    }
    finally {
        if ($null -ne $job) {
            Remove-Job -Job $job -Force -ErrorAction SilentlyContinue
        }
    }
    
    return @{
        InstalledVersion = $null
        AvailableVersion = $null
        HasUpdate = $false
    }
}

# Funktion zum Prüfen, ob ein Tool installiert ist
function Test-ToolInstalled {
    param (
        [Parameter(Mandatory = $true)]
        [object]$Tool
    )
    
    # Wenn das Tool null oder kein Objekt ist, sofort false zurückgeben
    if ($null -eq $Tool) {
        Write-Warning "Test-ToolInstalled: NULL-Tool wurde übergeben"
        return $false
    }
    
    # Wenn das Tool keine Winget-ID hat, können wir nicht prüfen
    if (-not $Tool.Winget) {
        return $false
    }
    
    # Cache-System verwenden, wenn verfügbar
    if (Get-Command -Name Get-CachedToolInstallationStatus -ErrorAction SilentlyContinue) {
        return Get-CachedToolInstallationStatus -Tool $Tool
    }
    
    # Fallback auf direkte Prüfung mit Timeout, wenn Cache nicht verfügbar
    $job = $null
    try {
        # Verwende Job mit Timeout um Hänger zu vermeiden
        $job = Start-Job -ScriptBlock {
            param($wingetId)
            winget list --id $wingetId --exact 2>$null | Out-String
        } -ArgumentList $Tool.Winget
        
        $completed = Wait-Job -Job $job -Timeout 8
        
        if ($completed) {
            $installedPackage = Receive-Job -Job $job
            
            # Wenn die Ausgabe die ID enthält, ist das Paket installiert
            if ($installedPackage -match [regex]::Escape($Tool.Winget)) {
                return $true
            }
        }
        else {
            # Timeout - Job stoppen
            Stop-Job -Job $job -ErrorAction SilentlyContinue
            Write-Warning "Timeout beim Prüfen von $($Tool.Name) (>8s)"
        }
    }
    catch {
        Write-Verbose "Fehler beim Prüfen des installierten Status für $($Tool.Name): $_"
    }
    finally {
        # Garantierter Job-Cleanup
        if ($null -ne $job) {
            Remove-Job -Job $job -Force -ErrorAction SilentlyContinue
        }
    }
    
    return $false
}

# Funktion zum Prüfen, ob ein Update verfügbar ist
function Test-ToolUpdateAvailable {
    param (
        [Parameter(Mandatory = $true)]
        [object]$Tool
    )
    
    # Wenn das Tool null oder kein Objekt ist, sofort false zurückgeben
    if ($null -eq $Tool) {
        return $false
    }
    
    # Wenn das Tool keine Winget-ID hat oder nicht installiert ist, kein Update möglich
    if (-not $Tool.Winget) {
        return $false
    }
    
    # Nur für installierte Tools Update-Prüfung durchführen
    if (-not (Test-ToolInstalled -Tool $Tool)) {
        return $false
    }
    
    # Prüfe auf verfügbare Updates mit winget upgrade
    $job = $null
    try {
        $job = Start-Job -ScriptBlock {
            param($wingetId)
            winget upgrade --id $wingetId --exact 2>$null | Out-String
        } -ArgumentList $Tool.Winget
        
        $completed = Wait-Job -Job $job -Timeout 10
        
        if ($completed) {
            $upgradeOutput = Receive-Job -Job $job
            
            # Wenn die Ausgabe "upgrade available" oder ähnliche Muster enthält
            # und nicht "No applicable update found" zeigt, ist ein Update verfügbar
            if ($upgradeOutput -match "upgrade|available|update" -and 
                $upgradeOutput -notmatch "No applicable update found|No installed package found") {
                
                # Prüfe ob tatsächlich eine Versionszeile mit dem Tool vorhanden ist
                if ($upgradeOutput -match [regex]::Escape($Tool.Winget)) {
                    return $true
                }
            }
        }
        else {
            Stop-Job -Job $job -ErrorAction SilentlyContinue
            Write-Verbose "Timeout beim Prüfen von Updates für $($Tool.Name)"
        }
    }
    catch {
        Write-Verbose "Fehler beim Prüfen von Updates für $($Tool.Name): $_"
    }
    finally {
        if ($null -ne $job) {
            Remove-Job -Job $job -Force -ErrorAction SilentlyContinue
        }
    }
    
    return $false
}

# Funktion zum Aktualisieren der Tool-Kachel-Anzeige
function Update-ToolsDisplay {
    param (
        [Parameter(Mandatory = $true)]
        [Windows.Controls.WrapPanel]$WrapPanel,
        
        [Parameter(Mandatory = $false)]
        [string]$Category = "all",
        
        [Parameter(Mandatory = $false)]
        [object]$MainProgressBar = $null,
        
        [Parameter(Mandatory = $false)]
        [switch]$ForceRefresh,
        
        [Parameter(Mandatory = $false)]
        [string]$SearchQuery = "",
        
        [Parameter(Mandatory = $false)]
        [string]$TileSize = "Medium",
        
        [Parameter(Mandatory = $false)]
        [bool]$ShowOnlyUpdates = $false
    )
    
    # Bestehenden Content löschen
    $WrapPanel.Children.Clear()
    
    # Installierte Pakete im Cache initialisieren (synchron, aber mit Timeout)
    # WICHTIG: MUSS VOR dem Anzeigen der Tools abgeschlossen sein!
    if (Get-Command -Name Initialize-InstalledPackagesCache -ErrorAction SilentlyContinue) {
        # ProgressBar-Update während Cache-Initialisierung
        if ($MainProgressBar -and $MainProgressBar.GetType().Name -eq "TextProgressBar") {
            $MainProgressBar.Value = 0
            $MainProgressBar.CustomText = "Lade Paket-Informationen..."
            $MainProgressBar.TextColor = [System.Drawing.Color]::Yellow
        }
        
        # Cache initialisieren - die Funktion hat jetzt eingebauten Timeout
        # BLOCKING bis Job abgeschlossen ist (max 15 Sek)
        Write-Host "[UPDATE-TOOLS-DISPLAY] Starte Cache-Initialisierung..." -ForegroundColor Yellow
        $cacheSuccess = Initialize-InstalledPackagesCache
        Write-Host "[UPDATE-TOOLS-DISPLAY] Cache-Initialisierung abgeschlossen: $cacheSuccess" -ForegroundColor $(if ($cacheSuccess) { 'Green' } else { 'Red' })
        
        if (-not $cacheSuccess) {
            Write-Warning "Cache-Initialisierung fehlgeschlagen - Installationsstatus kann ungenau sein"
        }
    }
    
    # Fortschrittsanzeige erstellen (temporär - wird nur genutzt wenn keine Haupt-ProgressBar angegeben ist)
    $progressBorder = New-Object Windows.Controls.Border
    $progressBorder.Width = 400
    $progressBorder.Height = 80
    $progressBorder.HorizontalAlignment = [Windows.HorizontalAlignment]::Center
    $progressBorder.VerticalAlignment = [Windows.VerticalAlignment]::Center
    $progressBorder.Background = [Windows.Media.Brushes]::White
    $progressBorder.BorderBrush = [Windows.Media.Brushes]::Gray
    $progressBorder.BorderThickness = New-Object Windows.Thickness(1)
    $progressBorder.CornerRadius = New-Object Windows.CornerRadius(5)
    
    $progressPanel = New-Object Windows.Controls.StackPanel
    $progressPanel.Orientation = [Windows.Controls.Orientation]::Vertical
    $progressPanel.HorizontalAlignment = [Windows.HorizontalAlignment]::Center
    $progressPanel.VerticalAlignment = [Windows.VerticalAlignment]::Center
    
    $loadingText = New-Object Windows.Controls.TextBlock
    $loadingText.Text = "Aktualisiere Tool-Informationen..."
    $loadingText.FontSize = 16
    $loadingText.FontWeight = [Windows.FontWeights]::Bold
    $loadingText.HorizontalAlignment = [Windows.HorizontalAlignment]::Center
    $loadingText.Margin = New-Object Windows.Thickness(0, 0, 0, 10)
    
    $internalProgressBar = New-Object Windows.Controls.ProgressBar
    $internalProgressBar.Width = 350
    $internalProgressBar.Height = 15
    
    # Wenn keine Haupt-ProgressBar angegeben ist, verwenden wir die interne ProgressBar
    if (-not $MainProgressBar) {
        $internalProgressBar.IsIndeterminate = $true
        $progressPanel.Children.Add($loadingText)
        $progressPanel.Children.Add($internalProgressBar)
        $progressBorder.Child = $progressPanel
        $WrapPanel.Children.Add($progressBorder)
    }
    else {
        # Haupt-ProgressBar initialisieren
        # Prüfen, ob es sich um eine TextProgressBar handelt (mit den erweiterten Eigenschaften)
        if ($MainProgressBar.GetType().Name -eq "TextProgressBar") {
            $MainProgressBar.Value = 0
            $MainProgressBar.CustomText = "Lade Tool-Informationen..."
            $MainProgressBar.TextColor = [System.Drawing.Color]::White
        }
        else {
            # Standard ProgressBar ohne erweiterte Eigenschaften
            $MainProgressBar.Value = 0
        }
    }
    
    # Prüfen, ob der Cache verfügbar ist und wir ihn verwenden sollen
    $useCachedTools = (-not $ForceRefresh) -and (Get-Command -Name Get-CachedToolsByCategory -ErrorAction SilentlyContinue)
    
    # Tools anhand Kategorie filtern
    $filteredTools = @()
    
    # Versuche, die Tools aus dem Cache zu laden
    if ($useCachedTools) {
        $cachedTools = Get-CachedToolsByCategory -Category $Category
        if ($null -ne $cachedTools) {
            Write-Verbose "Verwende gecachte Tools für Kategorie '$Category'"
            $filteredTools = $cachedTools
        }
    }
    
    # Wenn keine Tools aus dem Cache geladen wurden, direkt laden
    if (-not $filteredTools -or $filteredTools.Count -eq 0) {
        Write-Verbose "Lade Tools für Kategorie '$Category' frisch"
        if ($Category -eq "all") {
            $filteredTools = @(Get-AllTools)
        } else {
            $categoryTools = Get-ToolsByCategory -Category $Category
            if ($null -ne $categoryTools) {
                # Stelle sicher, dass wir ein Array haben, auch wenn nur ein Element vorhanden ist
                $filteredTools = @($categoryTools)
            }
            else {
                # Initialisiere leeres Array, wenn keine Tools gefunden wurden
                $filteredTools = @()
                Write-Warning "Keine Tools für Kategorie '$Category' gefunden"
            }
        }
        
        # Filtere alle null-Elemente und ungültige Objekte heraus
        $filteredTools = @($filteredTools | Where-Object { 
            $null -ne $_ -and 
            $_ -is [hashtable] -and 
            $_.ContainsKey('Name') -and 
            ![string]::IsNullOrWhiteSpace($_.Name)
        })
        
        Write-Verbose "Nach Filterung: $($filteredTools.Count) gültige Tools für Kategorie '$Category'"
        
        # Speichere die Tools im Cache, wenn der Cache verfügbar ist
        if ($filteredTools.Count -gt 0 -and (Get-Command -Name Set-CachedToolsByCategory -ErrorAction SilentlyContinue)) {
            Set-CachedToolsByCategory -Category $Category -Tools $filteredTools
        }
    }
    else {
        # Auch gecachte Tools validieren
        $filteredTools = @($filteredTools | Where-Object { 
            $null -ne $_ -and 
            $_ -is [hashtable] -and 
            $_.ContainsKey('Name') -and 
            ![string]::IsNullOrWhiteSpace($_.Name)
        })
        Write-Verbose "Nach Cache-Validierung: $($filteredTools.Count) gültige Tools"
    }
    
    # Gesamtzahl der Tools für die Fortschrittsberechnung
    $totalTools = $filteredTools.Count
    
    # Suchfilter anwenden, falls vorhanden
    if (-not [string]::IsNullOrWhiteSpace($SearchQuery)) {
        # Mindestlänge für Suche: 3 Zeichen
        if ($SearchQuery.Length -lt 3) {
            # Zu kurzer Suchbegriff - leere die Tool-Liste (keine Anzeige)
            $filteredTools = @()
            $totalTools = 0
        }
        else {
            $searchLower = $SearchQuery.ToLower()
            
            # Regex-Pattern für Wortgrenzen erstellen (sucht nach ganzen Wörtern oder Wortanfängen)
            $searchPattern = [regex]::Escape($searchLower)
            
            $filteredTools = @($filteredTools | Where-Object {
            $tool = $_
            
            # Hilfsfunktion zum Prüfen, ob der Suchbegriff am Wortanfang vorkommt
            $matchesWordStart = {
                param($text, $pattern)
                if ([string]::IsNullOrWhiteSpace($text)) { return $false }
                $textLower = $text.ToLower()
                
                # Prüfe ob am Anfang des Strings
                if ($textLower.StartsWith($pattern)) { return $true }
                
                # Prüfe ob nach Leerzeichen, Bindestrich, Slash oder Klammer
                if ($textLower -match "[\s\-/\(]$pattern") { return $true }
                
                # Prüfe CamelCase: Nach Großbuchstaben (z.B. "CCleaner" findet "cleaner")
                # Regex sucht nach Großbuchstaben gefolgt vom Suchmuster
                if ($text -and $text -cmatch "[A-Z]$pattern") { return $true }
                
                # Prüfe auch nach Zahlen (z.B. "7Zip" oder "Win10")
                if ($textLower -match "\d$pattern") { return $true }
                
                return $false
            }
            
            # Suche in Name (am Wortanfang)
            (& $matchesWordStart $tool.Name $searchLower) -or
            
            # Suche in Beschreibung (am Wortanfang)
            (& $matchesWordStart $tool.Description $searchLower) -or
            
            # Suche in Tags (am Wortanfang in jedem Tag)
            ($tool.Tags -and ($tool.Tags | Where-Object { & $matchesWordStart $_ $searchLower }).Count -gt 0) -or
            
            # Suche in Kategorie (am Wortanfang)
            (& $matchesWordStart $tool.Category $searchLower)
            })
            
            # Aktualisiere Gesamtzahl nach Suche
            $totalTools = $filteredTools.Count
            Write-Verbose "Nach Suchfilter '$SearchQuery': $totalTools Tools gefunden"
        }
    }
    
    # WICHTIG: Update-Filter wird während der Tool-Erstellung angewendet, nicht hier
    # da wir die Versionsinformationen erst beim Initialisieren jedes Tools ermitteln
    
    # Wenn keine Tools gefunden wurden, zeige eine Nachricht an
    if ($totalTools -eq 0) {
        $noToolsMessage = New-Object Windows.Controls.TextBlock
        if ($ShowOnlyUpdates) {
            $noToolsMessage.Text = "Keine Tools mit verfügbaren Updates gefunden."
        }
        elseif (-not [string]::IsNullOrWhiteSpace($SearchQuery)) {
            $noToolsMessage.Text = "Keine Tools für Suchbegriff '$SearchQuery' gefunden."
        }
        else {
            $noToolsMessage.Text = "Keine Tools in der Kategorie '$Category' gefunden."
        }
        $noToolsMessage.FontSize = 16
        $noToolsMessage.FontWeight = [Windows.FontWeights]::Bold
        $noToolsMessage.HorizontalAlignment = [Windows.HorizontalAlignment]::Center
        $noToolsMessage.VerticalAlignment = [Windows.VerticalAlignment]::Center
        $noToolsMessage.Margin = New-Object Windows.Thickness(10)
        $WrapPanel.Children.Add($noToolsMessage)
        
        # Bei leerer Kategorie direkt den ProgressBar zurücksetzen
        if ($MainProgressBar -and $MainProgressBar.GetType().Name -eq "TextProgressBar") {
            $MainProgressBar.Value = 0
            $MainProgressBar.CustomText = "Bereit"
            $MainProgressBar.TextColor = [System.Drawing.Color]::White
        }
        
        return $totalTools
    }
    $processedTools = 0
    
    # Timer starten, um asynchron die Tools zu laden und den Fortschritt anzuzeigen
    $timer = New-Object Windows.Threading.DispatcherTimer
    $timer.Interval = [TimeSpan]::FromMilliseconds(100)
    $timer.Tag = @{
        "WrapPanel" = $WrapPanel
        "ProgressBorder" = $progressBorder
        "MainProgressBar" = $MainProgressBar
        "FilteredTools" = $filteredTools
        "TotalTools" = $totalTools
        "ProcessedTools" = $processedTools
        "UseCache" = $useCachedTools
        "TileSize" = $TileSize
        "ShowOnlyUpdates" = $ShowOnlyUpdates
    }
    $timer.Add_Tick({
        # Variablen aus Tag abrufen
        $WrapPanel = $this.Tag.WrapPanel
        $progressBorder = $this.Tag.ProgressBorder
        $MainProgressBar = $this.Tag.MainProgressBar
        $filteredTools = $this.Tag.FilteredTools
        $totalTools = $this.Tag.TotalTools
        $processedTools = $this.Tag.ProcessedTools
        $useCache = $this.Tag.UseCache
        $TileSize = $this.Tag.TileSize
        $ShowOnlyUpdates = $this.Tag.ShowOnlyUpdates
        
        # Abbruchbedingung: Alle Tools verarbeitet
        if ($processedTools -ge $totalTools) {
            # Timer stoppen
            $this.Stop()
            
            # Progress-Anzeige entfernen wenn interne genutzt wird
            if (-not $MainProgressBar) {
                $WrapPanel.Children.Remove($progressBorder)
            }
            else {
                # Haupt-ProgressBar zurücksetzen - mit Typ-Check
                if ($MainProgressBar.GetType().Name -eq "TextProgressBar") {
                    $MainProgressBar.Value = 100
                    $MainProgressBar.CustomText = if ($useCache) { "Tool-Informationen aus Cache geladen" } else { "Tool-Informationen geladen" }
                    
                    # Nach kurzer Pause zurücksetzen
                    $resetTimer = New-Object System.Windows.Forms.Timer
                    $resetTimer.Interval = 1000
                    $resetTimer.Add_Tick({
                        $script:localProgressBar = $MainProgressBar
                        if ($script:localProgressBar.GetType().Name -eq "TextProgressBar") {
                            $script:localProgressBar.Value = 0
                            $script:localProgressBar.CustomText = "Bereit"
                            $script:localProgressBar.TextColor = [System.Drawing.Color]::White
                        }
                        else {
                            $script:localProgressBar.Value = 0
                        }
                        $this.Stop()
                    }.GetNewClosure())
                    $resetTimer.Start()
                }
                else {
                    # Standard ProgressBar ohne erweiterte Eigenschaften
                    $MainProgressBar.Value = 100
                    
                    # Nach kurzer Pause zurücksetzen
                    $resetTimer = New-Object System.Windows.Forms.Timer
                    $resetTimer.Interval = 1000
                    $resetTimer.Add_Tick({
                        $MainProgressBar.Value = 0
                        $this.Stop()
                    })
                    $resetTimer.Start()
                }
            }
            
            # Gebe Anzahl der angezeigten Tools zurück
            return $totalTools
        }
        
        # Aktuelles Tool verarbeiten - mit Fehlerbehandlung
        try {
            if ($processedTools -lt 0 -or $processedTools -ge $filteredTools.Count) {
                Write-Warning "Update-ToolsDisplay: Index $processedTools außerhalb des gültigen Bereichs (0-$($filteredTools.Count - 1))"
            }
            else {
                $tool = $filteredTools[$processedTools]
                
                # Nur verarbeiten, wenn das Tool nicht null ist
                if ($null -ne $tool) {
                    # Prüfe ob Update-Filter aktiv ist
                    $shouldDisplay = $true
                    if ($ShowOnlyUpdates) {
                        # Prüfe ob Tool installiert ist und Update verfügbar
                        if ($tool.Winget) {
                            $isInstalled = Test-ToolInstalled -Tool $tool
                            if ($isInstalled) {
                                $versionInfo = Get-ToolVersionInfo -Tool $tool
                                $shouldDisplay = ($null -ne $versionInfo -and $versionInfo.HasUpdate)
                            } else {
                                $shouldDisplay = $false
                            }
                        } else {
                            $shouldDisplay = $false
                        }
                    }
                    
                    # Tool nur anzeigen wenn Filter-Bedingung erfüllt
                    if ($shouldDisplay) {
                        Initialize-ToolEntry -TargetElement $WrapPanel -Tool $tool -TileSize $TileSize
                    }
                }
                else {
                    Write-Warning "Update-ToolsDisplay: NULL-Tool an Index $processedTools gefunden"
                }
            }
        }
        catch {
            Write-Warning "Update-ToolsDisplay: Fehler beim Verarbeiten von Tool $processedTools - $_"
        }
        
        # Fortschritt erhöhen
        $processedTools++
        $this.Tag.ProcessedTools = $processedTools
        
        # Fortschrittsanzeige aktualisieren wenn Haupt-ProgressBar vorhanden
        if ($MainProgressBar) {
            $progressPercentage = [Math]::Min(99, [Math]::Floor(($processedTools / $totalTools) * 100))
            $MainProgressBar.Value = $progressPercentage
            
            # Prüfen, ob erweiterte Eigenschaften verfügbar sind (TextProgressBar)
            if ($MainProgressBar.GetType().Name -eq "TextProgressBar") {
                $MainProgressBar.CustomText = "Lade Tools: $processedTools von $totalTools"
            }
        }
    })
    $timer.Start()
}

# Exportiere die Funktionen
Export-ModuleMember -Function Get-AllTools, Get-ToolsByCategory, Get-ToolsByTag, Get-ToolByName, Install-ToolPackage, Get-ToolDownload, Flatten, Update-ToolProgress, Set-ToolResource, Initialize-ToolEntry, Show-ToolTileList, Test-ToolInstalled, Test-ToolUpdateAvailable, Get-ToolVersionInfo, Update-ToolsDisplay, Stop-ToolProcess, Get-WingetErrorDescription

# SIG # Begin signature block
# MIIcSgYJKoZIhvcNAQcCoIIcOzCCHDcCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAwzDbPJyvSpQuH
# SruO08/8+YD1gRc24CWiIcJFAtGI4KCCFnowggM8MIICJKADAgECAhBJfyGrXBJT
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
# MQ4wDAYKKwYBBAGCNwIBFTAvBgkqhkiG9w0BCQQxIgQg89NotDqeL2v94GXvvp82
# 4d0JUbE86KxQSzH5Fn2ivRwwDQYJKoZIhvcNAQEBBQAEggEAh735FIS+1YbR9qYI
# le+x2dkVAdsNaRvXxe6C8jhdxn6axuj8lhtNQ93/sG+oCneQFLbuLq8hQbEU7lis
# 8HynTuSNNS6FJZCmGU7+8+tCdTkVKYocIiVOjYuaW3PmNvOh4tQAulDO6uiynB+S
# +Q9meBo4hFwzfYjHIz6EMBpmHDaFfjO0xIzuSRliR6q6UElVefljCZTG1POmRehQ
# Tkcj/tZJ3puz1OnVBrGbmIOk4z8z2gAJ0vea7HJu6lfsgrsQYoO9VUYoAd9vIPKL
# UAO1QQIllun0eo/lWpjPSnws94kXvicfWzRXlzvVwqg+7a6LKPbSL2cTO064Lqi6
# GZqfxKGCAyYwggMiBgkqhkiG9w0BCQYxggMTMIIDDwIBATB9MGkxCzAJBgNVBAYT
# AlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5jLjFBMD8GA1UEAxM4RGlnaUNlcnQg
# VHJ1c3RlZCBHNCBUaW1lU3RhbXBpbmcgUlNBNDA5NiBTSEEyNTYgMjAyNSBDQTEC
# EAqA7xhLjfEFgtHEdqeVdGgwDQYJYIZIAWUDBAIBBQCgaTAYBgkqhkiG9w0BCQMx
# CwYJKoZIhvcNAQcBMBwGCSqGSIb3DQEJBTEPFw0yNjAxMjAxODAyNTdaMC8GCSqG
# SIb3DQEJBDEiBCC0wo0gDRNpo+9rlU2vPL/EsLMbj8RGyME+wcuN/1a5wDANBgkq
# hkiG9w0BAQEFAASCAgBY2+3Ad/HuiWbDAQqrgw4CeOHES1Hp8NZKj0u57yjxQSpP
# CKcxgRSLFGsolrJD+QrMdmHR6BWPKpwYkDYtkk8itBNGVn1ACzmiRCDiLdy5+5lP
# FDOoBVKr0yjkV3jP0t86QkaYXeKjDcruHbt5gBP30z6zHZ01T4vNm03ICbZxQYjC
# L3GDymXeP8dnYHaKos7EcvMfoi/QWkgXTsQLXGrwp3LzGLirA1LQ5v3RN/HUO05+
# nyLkURCgz39SogwcatFCKWDp1Uwn6mAeRrC+/BNlCrgd8rmjKoA7Nyj/MqiZbRIS
# 9M77Gj5ESTBECNm1+iBhwiTbksiBxNp+5DADNLMAdPW1estwHPiSR753IhFO4FOw
# pJF6P7WrRz5tD6QmAslaW/BzployzWf8PahEB6+fpC3ULbIDmbGmu0ZFoUhsCRtm
# qw/ZNZV2Ghxn87lhr0bbfA2NyiaVP9TaSHN8qEAg/5YEgVfzBS/obrYcbwTTRVkB
# NcuYV3T+hkUv37zPUX61yRqqmlGl1k3uw+IkTEiLk1jH/W1EmtCFFBqawubtoEU7
# pA23UxQZmP2Pkgwo2n3VZNDYq/9COwNj+VrZ+8QzxCwdI+GKLcuq8EbmiTESCnwF
# 4SCwr/HrrSfcavIjL0+knMNAPI3FtIXRym1qh9BcZPPknTBVcu+YDSrZmenLhQ==
# SIG # End signature block

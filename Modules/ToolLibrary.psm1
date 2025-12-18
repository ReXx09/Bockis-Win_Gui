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
    $border.Padding = $script:toolResourceDictionary["ToolTileMargins"]
    $border.Width = $tileWidth
    $border.MinHeight = if ($TileSize -eq "Large") { 180 } else { 0 }  # Mindesthöhe für kleine Kacheln
    $border.VerticalAlignment = "Top"
    $border.Margin = $script:toolResourceDictionary["ToolTileMargins"]
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
    $headerPanel.Margin = if ($isListView -or $isSmallTile) { New-Object Windows.Thickness(0, 0, 0, 5) } else { New-Object Windows.Thickness(0, 0, 0, 10) }
    [Windows.Controls.DockPanel]::SetDock($headerPanel, [Windows.Controls.Dock]::Top)

    # Tool-Icon (Platzhalter)
    $iconSize = if ($isListView) { 30 } elseif ($isSmallTile) { 32 } else { 40 }
    $iconBorder = New-Object Windows.Controls.Border
    $iconBorder.Width = $iconSize
    $iconBorder.Height = $iconSize
    $iconBorder.Background = [Windows.Media.Brushes]::LightBlue
    $iconBorder.CornerRadius = 4
    $iconBorder.Margin = New-Object Windows.Thickness(0, 0, 10, 0)
    
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
    $descPanel.Margin = if ($isListView -or $isSmallTile) { New-Object Windows.Thickness(0, 0, 0, 5) } else { New-Object Windows.Thickness(0, 0, 0, 10) }
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
    $descLabel.FontSize = if ($isListView) { 11 } elseif ($isSmallTile) { 10 } else { 12 }
    $descLabel.Margin = New-Object Windows.Thickness(5)
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
    $infoButton.Width = 45
    $infoButton.Height = 35
    $infoButton.Margin = New-Object Windows.Thickness(2)
    $infoIcon = New-Object Windows.Controls.TextBlock
    $infoIcon.Text = [char]0xE946  # Info-Symbol
    $infoIcon.FontFamily = New-Object Windows.Media.FontFamily("Segoe MDL2 Assets")
    $infoIcon.FontSize = 20
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
        $wingetButton.Width = 45
        $wingetButton.Height = 35
        $wingetButton.Margin = New-Object Windows.Thickness(2)
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
                        # Update durchführen
                        Start-Process "winget" -ArgumentList "upgrade", "--id", $toolInfo.Winget, "--silent", "--accept-source-agreements", "--accept-package-agreements" -Verb RunAs
                        [System.Windows.Forms.MessageBox]::Show(
                            "Update für $($toolInfo.Name) wurde gestartet.",
                            "Update - $($toolInfo.Name)",
                            [System.Windows.Forms.MessageBoxButtons]::OK,
                            [System.Windows.Forms.MessageBoxIcon]::Information
                        )
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
                            Start-Process "winget" -ArgumentList "install", "--id", $toolInfo.Winget, "--force", "--silent", "--accept-source-agreements", "--accept-package-agreements" -Verb RunAs
                            [System.Windows.Forms.MessageBox]::Show(
                                "Neuinstallation von $($toolInfo.Name) wurde gestartet.",
                                "Neuinstallation - $($toolInfo.Name)",
                                [System.Windows.Forms.MessageBoxButtons]::OK,
                                [System.Windows.Forms.MessageBoxIcon]::Information
                            )
                        }
                    }
                    else {
                        # Erstinstallation
                        Start-Process "winget" -ArgumentList "install", "--id", $toolInfo.Winget, "--silent", "--accept-source-agreements", "--accept-package-agreements" -Verb RunAs
                        [System.Windows.Forms.MessageBox]::Show(
                            "Installation von $($toolInfo.Name) wurde gestartet.",
                            "Installation - $($toolInfo.Name)",
                            [System.Windows.Forms.MessageBoxButtons]::OK,
                            [System.Windows.Forms.MessageBoxIcon]::Information
                        )
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
    $webButton.Width = 45
    $webButton.Height = 35
    $webButton.Margin = New-Object Windows.Thickness(2)
    $webIcon = New-Object Windows.Controls.TextBlock
    $webIcon.Text = [char]0xE774  # Web-Symbol
    $webIcon.FontFamily = New-Object Windows.Media.FontFamily("Segoe MDL2 Assets")
    $webIcon.FontSize = 20
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
        $uninstallButton.Width = 45
        $uninstallButton.Height = 35
        $uninstallButton.Margin = New-Object Windows.Thickness(2)
        $uninstallIcon = New-Object Windows.Controls.TextBlock
        $uninstallIcon.Text = [char]0xE74D  # Uninstall-Symbol
        $uninstallIcon.FontFamily = New-Object Windows.Media.FontFamily("Segoe MDL2 Assets")
        $uninstallIcon.FontSize = 20
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
        [string]$TileSize = "Medium"
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
    
    # Wenn keine Tools gefunden wurden, zeige eine Nachricht an
    if ($totalTools -eq 0) {
        $noToolsMessage = New-Object Windows.Controls.TextBlock
        if (-not [string]::IsNullOrWhiteSpace($SearchQuery)) {
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
                    Initialize-ToolEntry -TargetElement $WrapPanel -Tool $tool -TileSize $TileSize
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
Export-ModuleMember -Function Get-AllTools, Get-ToolsByCategory, Get-ToolsByTag, Get-ToolByName, Install-ToolPackage, Get-ToolDownload, Flatten, Update-ToolProgress, Set-ToolResource, Initialize-ToolEntry, Show-ToolTileList, Test-ToolInstalled, Test-ToolUpdateAvailable, Get-ToolVersionInfo, Update-ToolsDisplay

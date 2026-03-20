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
        DownloadUrl = 'https://www.7-zip.org/a/7z2501-x64.exe'
        Category    = 'System-Tools'
        Tags        = @('Compression', 'Archive', 'Utility')
        Winget      = '7zip.7zip'
    },
    @{
        Name        = 'CCleaner'
        Description = 'Systembereinigung und Optimierung'
        Version     = '6.10'
        DownloadUrl = 'https://bits.avcdn.net/productfamily_CCLEANER/insttype_SLIM/platform_WIN_PIR/installertype_ONLINE/build_RELEASE'
        Category    = 'System-Tools'
        Tags        = @('Cleanup', 'Optimization', 'System')
        Winget      = 'Piriform.CCleaner'
    },
    @{
        Name        = 'CPU-Z'
        Description = 'Detaillierte CPU- und Systeminformationen'
        Version     = '2.05'
        DownloadUrl = 'https://download.cpuid.com/cpu-z/cpu-z_2.18-en.exe'
        Category    = 'System-Tools'
        Tags        = @('Hardware', 'Monitoring', 'CPU')
        Winget      = 'CPUID.CPU-Z'
    },
    @{
        Name        = 'GPU-Z'
        Description = 'Grafikkarten-Informationen'
        Version     = '2.45'
        DownloadUrl = 'https://www.techpowerup.com/download/techpowerup-gpu-z/GPU-Z.2.68.0.exe'
        Category    = 'System-Tools'
        Tags        = @('Hardware', 'Monitoring', 'GPU')
        Winget      = 'TechPowerUp.GPU-Z'
    },
    @{
        Name        = 'OCCT'
        Description = 'Umfassendes System-Stabilitäts- und Stress-Test-Tool für CPU, GPU und Netzteil'
        Version     = 'Aktuell'
        DownloadUrl = 'https://dl.ocbase.com/per/stable/OCCT.exe'
        Category    = 'System-Tools'
        Tags        = @('Stress Test', 'Stability', 'Benchmark', 'Hardware')
        Winget      = 'OCBase.OCCT.Personal'
    },
    @{
        Name        = 'Intel Driver & Support Assistant'
        Description = 'Automatische Treiber-Updates und Support für Intel-Hardware'
        Version     = 'Aktuell'
        DownloadUrl = 'https://dsadata.intel.com/installer/Intel-Driver-and-Support-Assistant-Installer.exe'
        Category    = 'System-Tools'
        Tags        = @('Drivers', 'Intel', 'Update', 'Hardware')
        Winget      = 'Intel.IntelDriverAndSupportAssistant'
    },
    @{
        Name        = 'LibreHardwareMonitor'
        Description = 'Open-Source Hardware-Monitoring-Tool für Temperaturen, Lüfter und Sensoren'
        Version     = '0.9.5'
        DownloadUrl = 'https://github.com/LibreHardwareMonitor/LibreHardwareMonitor/releases/download/v0.9.5/LibreHardwareMonitor.zip'
        Category    = 'System-Tools'
        Tags        = @('Hardware', 'Monitoring', 'Temperature', 'Sensors', 'Open-Source')
        Winget      = 'LibreHardwareMonitor.LibreHardwareMonitor'
    },
    @{
        Name        = 'PawnIO'
        Description = '⚠ Systemtreiber – Pflichtkomponente für Hardware-Monitoring. Nicht deinstallieren!'
        Version     = '2.0.1'
        DownloadUrl = 'https://github.com/namazso/PawnIO.Setup/releases/download/2.0.1/PawnIO_setup.exe'
        Category    = 'System-Tools'
        Tags        = @('Driver', 'Ring0', 'Hardware', 'Monitoring', 'PawnIO')
        Winget      = 'namazso.PawnIO'
        Protected   = $true  # Pflichtabhängigkeit – Deinstallation über UI gesperrt
    },
    @{
        Name        = 'UniGetUI'
        Description = 'Grafische Oberfläche für Paketmanager (Winget, Scoop, Chocolatey) zum Verwalten von Anwendungen'
        Version     = 'Aktuell'
        DownloadUrl = 'https://github.com/marticliment/UniGetUI'
        Category    = 'System-Tools'
        Tags        = @('Package Manager', 'Winget', 'GUI', 'Software Management')
        Winget      = 'MartiCliment.UniGetUI'
    },
    @{
        Name        = 'Raspberry Pi Imager'
        Description = 'Tool zum Schreiben von Raspberry Pi OS und anderen Images auf SD-Karten'
        Version     = 'Aktuell'
        DownloadUrl = 'https://www.raspberrypi.com/software/'
        Category    = 'System-Tools'
        Tags        = @('Raspberry Pi', 'Imager', 'SD-Card', 'Flashing')
        Winget      = 'RaspberryPiFoundation.RaspberryPiImager'
    },
    @{
        Name        = 'Rufus'
        Description = 'Erstellt bootfähige USB-Sticks aus ISO-Dateien'
        Version     = 'Aktuell'
        DownloadUrl = 'https://rufus.ie/'
        Category    = 'System-Tools'
        Tags        = @('USB', 'Boot', 'ISO', 'Flashing')
        Winget      = 'Rufus.Rufus'
    },
    @{
        Name        = 'App Installer'
        Description = 'Microsoft App Installer mit Winget-Integration'
        Version     = 'Aktuell'
        DownloadUrl = 'https://apps.microsoft.com/detail/9NBLGGH4NNS1'
        Category    = 'System-Tools'
        Tags        = @('Microsoft', 'Winget', 'Installer', 'System')
        Winget      = 'Microsoft.AppInstaller'
    },
    @{
        Name        = 'Snipping Tool'
        Description = 'Windows Screenshot- und Bildschirmaufnahme-Tool mit Anmerkungsfunktion'
        Version     = 'Aktuell'
        DownloadUrl = 'https://apps.microsoft.com/detail/9MZ95KL8MR0L'
        Category    = 'System-Tools'
        Tags        = @('Screenshot', 'Screen Capture', 'Microsoft', 'Utility')
        Winget      = '9MZ95KL8MR0L'
    },
    @{
        Name        = 'CrystalDiskInfo'
        Description = 'HDD/SSD-Gesundheitsüberwachung mit S.M.A.R.T.-Analyse und Temperaturanzeige'
        Version     = 'Aktuell'
        DownloadUrl = 'https://crystalmark.info/en/software/crystaldiskinfo/'
        Category    = 'System-Tools'
        Tags        = @('Disk', 'HDD', 'SSD', 'SMART', 'Health', 'Monitoring')
        Winget      = 'CrystalDewWorld.CrystalDiskInfo'
    },
    @{
        Name        = 'Microsoft PowerToys'
        Description = 'Sammlung von Dienstprogrammen für Power-User: FancyZones, PowerRename, Color Picker und mehr'
        Version     = 'Aktuell'
        DownloadUrl = 'https://github.com/microsoft/PowerToys/releases'
        Category    = 'System-Tools'
        Tags        = @('Microsoft', 'Utilities', 'Productivity', 'Power User', 'Tools')
        Winget      = 'Microsoft.PowerToys'
    },
    @{
        Name        = 'IrfanView'
        Description = 'Schneller und vielseitiger Bildbetrachter mit Batch-Konvertierung und Bearbeitungsfunktionen'
        Version     = 'Aktuell'
        DownloadUrl = 'https://www.irfanview.com/main_download_engl.htm'
        Category    = 'System-Tools'
        Tags        = @('Image Viewer', 'Photo', 'Batch', 'Converter', 'Lightweight')
        Winget      = '9PJZ3BTL5PV6'
    },
    @{
        Name        = 'ShareX'
        Description = 'Kostenlose Open-Source Screenshot- und Screenrecording-Software mit umfangreichen Funktionen'
        Version     = 'Aktuell'
        DownloadUrl = 'https://getsharex.com/'
        Category    = 'System-Tools'
        Tags        = @('Screenshot', 'Screen Recording', 'Annotation', 'Open-Source', 'Capture')
        Winget      = 'ShareX.ShareX'
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
    },
    @{
        Name        = 'Tutanota'
        Description = 'Sicherer E-Mail-Client mit End-to-End-Verschlüsselung und privatem Kalender'
        Version     = 'Aktuell'
        DownloadUrl = 'https://github.com/tutao/tutanota/releases'
        Category    = 'Anwendungen'
        Tags        = @('Email', 'Communication', 'Privacy', 'Security', 'Encryption')
        Winget      = 'Tutanota.Tutanota'
    },
    @{
        Name        = 'Nextcloud'
        Description = 'Open-Source Cloud-Speicher und Collaboration-Plattform für Dateisynchronisation'
        Version     = 'Aktuell'
        DownloadUrl = 'https://nextcloud.com/install/#install-clients'
        Category    = 'Anwendungen'
        Tags        = @('Cloud', 'Storage', 'Sync', 'Collaboration', 'Open-Source')
        Winget      = 'Nextcloud.NextcloudDesktop'
    },
    @{
        Name        = 'PDFCreator'
        Description = 'Kostenloser PDF-Drucker und Konverter zum Erstellen von PDF-Dateien aus jeder Anwendung'
        Version     = 'Aktuell'
        DownloadUrl = 'https://www.pdfforge.org/pdfcreator/download'
        Category    = 'Anwendungen'
        Tags        = @('PDF', 'Printer', 'Converter', 'Documents')
        Winget      = 'Avanquestpdfforge.PDFCreator-Free'
    },
    @{
        Name        = 'Elgato Stream Deck'
        Description = 'Steuerungssoftware für das Elgato Stream Deck – Makros, Shortcuts und Streaming-Integration'
        Version     = 'Aktuell'
        DownloadUrl = 'https://www.elgato.com/downloads'
        Category    = 'Anwendungen'
        Tags        = @('Stream Deck', 'Streaming', 'Macros', 'Shortcuts', 'Elgato')
        Winget      = 'Elgato.StreamDeck'
    },
    @{
        Name        = 'Steam'
        Description = 'Gaming-Plattform von Valve zum Kaufen, Verwalten und Spielen von PC-Spielen'
        Version     = 'Aktuell'
        DownloadUrl = 'https://store.steampowered.com/about/'
        Category    = 'Anwendungen'
        Tags        = @('Gaming', 'Games', 'Store', 'Valve')
        Winget      = 'Valve.Steam'
    },
    @{
        Name        = 'Total Commander'
        Description = 'Leistungsstarker Dateimanager mit Zwei-Panel-Ansicht, FTP-Client und Archiv-Unterstützung'
        Version     = 'Aktuell'
        DownloadUrl = 'https://www.ghisler.com/download.htm'
        Category    = 'Anwendungen'
        Tags        = @('File Manager', 'FTP', 'Explorer', 'Tools')
        Winget      = 'Ghisler.TotalCommander'
    },
    @{
        Name        = 'Mozilla Thunderbird'
        Description = 'Kostenloser E-Mail-Client von Mozilla mit Kalender, Aufgaben und Spam-Schutz'
        Version     = 'Aktuell'
        DownloadUrl = 'https://www.thunderbird.net/de/'
        Category    = 'Anwendungen'
        Tags        = @('Email', 'Mail Client', 'Communication', 'Calendar', 'Mozilla')
        Winget      = 'Mozilla.Thunderbird.de'
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
    },
    @{
        Name        = 'AIMP'
        Description = 'Kostenloser Audioplayer mit umfangreicher Formatunterstützung und modernem Interface'
        Version     = 'Aktuell'
        DownloadUrl = 'https://www.aimp.ru/'
        Category    = 'Audio / TV'
        Tags        = @('Audio', 'Music', 'Media Player', 'Playlist')
        Winget      = 'AIMP.AIMP'
    },
    @{
        Name        = 'Elgato Wave Link'
        Description = 'Audio-Mixing-Software für Elgato Wave Mikrofone mit Mehrkanal-Routing'
        Version     = 'Aktuell'
        DownloadUrl = 'https://www.elgato.com/downloads'
        Category    = 'Audio / TV'
        Tags        = @('Audio', 'Mixer', 'Elgato', 'Microphone', 'Streaming')
        Winget      = 'Elgato.WaveLink'
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
    },
    @{
        Name        = 'Inno Setup 6'
        Description = 'Kostenloses Installationsprogramm-Erstellungstool für Windows-Anwendungen'
        Version     = 'Aktuell'
        DownloadUrl = 'https://jrsoftware.org/isdl.php'
        Category    = 'Coding / IT'
        Tags        = @('Installer', 'Setup', 'Packaging', 'Development')
        Winget      = 'JRSoftware.InnoSetup'
    },
    @{
        Name        = 'GitHub CLI'
        Description = 'Offizielles GitHub-Kommandozeilenwerkzeug für Repositories, PRs und Issues'
        Version     = 'Aktuell'
        DownloadUrl = 'https://cli.github.com/'
        Category    = 'Coding / IT'
        Tags        = @('Git', 'GitHub', 'CLI', 'Development', 'Version Control')
        Winget      = 'GitHub.cli'
    },
    @{
        Name        = 'Advanced IP Scanner'
        Description = 'Kostenloser Netzwerkscanner zum Erkennen aller Geräte im lokalen Netzwerk'
        Version     = 'Aktuell'
        DownloadUrl = 'https://www.advanced-ip-scanner.com/de/'
        Category    = 'Coding / IT'
        Tags        = @('Network', 'Scanner', 'IP', 'LAN', 'Monitoring')
        Winget      = 'Famatech.AdvancedIPScanner'
    },
    @{
        Name        = 'Nmap'
        Description = 'Leistungsstarker Open-Source Netzwerkscanner für Sicherheitsanalysen und Port-Scans'
        Version     = 'Aktuell'
        DownloadUrl = 'https://nmap.org/download.html'
        Category    = 'Coding / IT'
        Tags        = @('Network', 'Scanner', 'Security', 'Port Scan', 'Open-Source')
        Winget      = 'Insecure.Nmap'
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
    } catch {
        [System.Windows.Forms.MessageBox]::Show(
            "Fehler beim Öffnen des Download-Links: $_",
            "Fehler",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
        return $false
    }
}

# Funktion für benutzerdefinierten Dialog mit klaren Button-Bezeichnungen
function Show-ToolAcquisitionDialog {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ToolName
    )
    
    # Erstelle WPF-Fenster
    $dialog = New-Object System.Windows.Window
    $dialog.Title = "Download/Installation - $ToolName"
    $dialog.Width = 500
    $dialog.Height = 220
    $dialog.WindowStartupLocation = "CenterScreen"
    $dialog.ResizeMode = "NoResize"
    $dialog.WindowStyle = "SingleBorderWindow"
    
    # Hauptcontainer
    $grid = New-Object System.Windows.Controls.Grid
    $grid.Margin = New-Object System.Windows.Thickness(20)
    
    # Zeilen definieren
    $row1 = New-Object System.Windows.Controls.RowDefinition
    $row1.Height = [System.Windows.GridLength]::Auto
    $row2 = New-Object System.Windows.Controls.RowDefinition
    $row2.Height = [System.Windows.GridLength]::Auto
    $row3 = New-Object System.Windows.Controls.RowDefinition
    $row3.Height = "*"
    $row4 = New-Object System.Windows.Controls.RowDefinition
    $row4.Height = [System.Windows.GridLength]::Auto
    
    $grid.RowDefinitions.Add($row1)
    $grid.RowDefinitions.Add($row2)
    $grid.RowDefinitions.Add($row3)
    $grid.RowDefinitions.Add($row4)
    
    # Titel
    $title = New-Object System.Windows.Controls.TextBlock
    $title.Text = "Wie möchten Sie $ToolName erhalten?"
    $title.FontSize = 16
    $title.FontWeight = "Bold"
    $title.Margin = New-Object System.Windows.Thickness(0, 0, 0, 15)
    [System.Windows.Controls.Grid]::SetRow($title, 0)
    $grid.Children.Add($title)
    
    # Option 1: Installieren
    $installText = New-Object System.Windows.Controls.TextBlock
    $installText.Text = "• Direkt via Winget installieren (empfohlen)"
    $installText.FontSize = 12
    $installText.Margin = New-Object System.Windows.Thickness(10, 0, 0, 5)
    [System.Windows.Controls.Grid]::SetRow($installText, 1)
    $grid.Children.Add($installText)
    
    # Option 2: Download
    $downloadText = New-Object System.Windows.Controls.TextBlock
    $downloadText.Text = "• Nur herunterladen (ins lokale Verzeichnis)"
    $downloadText.FontSize = 12
    $downloadText.Margin = New-Object System.Windows.Thickness(10, 0, 0, 0)
    [System.Windows.Controls.Grid]::SetRow($downloadText, 2)
    $grid.Children.Add($downloadText)
    
    # Button-Panel
    $buttonPanel = New-Object System.Windows.Controls.StackPanel
    $buttonPanel.Orientation = "Horizontal"
    $buttonPanel.HorizontalAlignment = "Right"
    $buttonPanel.Margin = New-Object System.Windows.Thickness(0, 20, 0, 0)
    [System.Windows.Controls.Grid]::SetRow($buttonPanel, 3)
    
    # Button: Installieren
    $installButton = New-Object System.Windows.Controls.Button
    $installButton.Content = "Installieren"
    $installButton.Width = 100
    $installButton.Height = 30
    $installButton.Margin = New-Object System.Windows.Thickness(0, 0, 10, 0)
    $installButton.Background = [System.Windows.Media.Brushes]::LightGreen
    $installButton.Add_Click({
            $dialog.Tag = "Install"
            $dialog.Close()
        })
    $buttonPanel.Children.Add($installButton)
    
    # Button: Download
    $downloadButton = New-Object System.Windows.Controls.Button
    $downloadButton.Content = "Download"
    $downloadButton.Width = 100
    $downloadButton.Height = 30
    $downloadButton.Margin = New-Object System.Windows.Thickness(0, 0, 10, 0)
    $downloadButton.Background = [System.Windows.Media.Brushes]::LightSkyBlue
    $downloadButton.Add_Click({
            $dialog.Tag = "Download"
            $dialog.Close()
        })
    $buttonPanel.Children.Add($downloadButton)
    
    # Button: Abbrechen
    $cancelButton = New-Object System.Windows.Controls.Button
    $cancelButton.Content = "Abbrechen"
    $cancelButton.Width = 100
    $cancelButton.Height = 30
    $cancelButton.Add_Click({
            $dialog.Tag = "Cancel"
            $dialog.Close()
        })
    $buttonPanel.Children.Add($cancelButton)
    
    $grid.Children.Add($buttonPanel)
    $dialog.Content = $grid
    
    # Zeige Dialog modal
    $dialog.ShowDialog() | Out-Null
    
    return $dialog.Tag
}

# Funktion zum Herunterladen und Installieren von Tools
# Funktion zum Prüfen, ob ein Tool bereits heruntergeladen wurde
function Test-ToolDownloaded {
    param (
        [Parameter(Mandatory = $true)]
        [object]$Tool,
        
        [Parameter(Mandatory = $false)]
        [string]$DownloadPath = (Join-Path $PSScriptRoot "..\Data\ToolDownloads")
    )
    
    if (-not (Test-Path $DownloadPath)) {
        return $false
    }
    
    # Hole alle Installer-Dateien im Download-Ordner
    $allFiles = Get-ChildItem -Path $DownloadPath -ErrorAction SilentlyContinue | 
        Where-Object { $_.Extension -in @('.exe', '.zip', '.msi') }
    
    if ($allFiles.Count -eq 0) {
        return $false
    }
    
    # Erstelle verschiedene Suchmuster für flexiblere Erkennung
    $toolName = $Tool.Name
    $searchPatterns = @(
        # Originaler Name ohne Sonderzeichen (normalisiert)
        $toolName -replace '[^a-zA-Z0-9]', '_'
        # Name ohne Sonderzeichen und Leerzeichen
        $toolName -replace '[^a-zA-Z0-9]', ''
        # Name mit Bindestrichen statt Leerzeichen
        $toolName -replace '\s+', '-'
        # Name mit Unterstrichen statt Leerzeichen
        $toolName -replace '\s+', '_'
        # Originaler Name
        $toolName
    )
    
    # Suche nach Dateien, die eines der Muster enthalten (case-insensitive)
    foreach ($file in $allFiles) {
        $fileName = $file.BaseName
        foreach ($pattern in $searchPatterns) {
            if ($fileName -like "*$pattern*") {
                return $true
            }
        }
        
        # Zusätzliche Token-basierte Suche für komplexe Namen wie "7-Zip" -> "7z"
        # Teile Tool-Name in Tokens auf (Zahlen und Wörter)
        $tokens = [regex]::Matches($toolName, '[a-zA-Z]+|\d+') | ForEach-Object { $_.Value }
        if ($tokens.Count -gt 1) {
            # Erstelle kompakte Variante (z.B. "7-Zip" -> "7z")
            $compactName = ($tokens | ForEach-Object { $_.Substring(0, [Math]::Min(1, $_.Length)) }) -join ''
            if ($compactName.Length -ge 2 -and $fileName -like "*$compactName*") {
                return $true
            }
            
            # Erstelle zusammengesetzte Variante ohne Bindestriche (z.B. "CPU-Z" -> "cpuz")
            $joinedName = $tokens -join ''
            if ($joinedName.Length -ge 3 -and $fileName -like "*$joinedName*") {
                return $true
            }
        }
    }
    
    return $false
}

# Funktion zum Abrufen des Pfads zum lokalen Installer
function Get-ToolLocalInstallerPath {
    param (
        [Parameter(Mandatory = $true)]
        [object]$Tool,
        
        [Parameter(Mandatory = $false)]
        [string]$DownloadPath = (Join-Path $PSScriptRoot "..\Data\ToolDownloads")
    )
    
    if (-not (Test-Path $DownloadPath)) {
        return $null
    }
    
    # Hole alle Installer-Dateien im Download-Ordner
    $allFiles = Get-ChildItem -Path $DownloadPath -ErrorAction SilentlyContinue | 
        Where-Object { $_.Extension -in @('.exe', '.zip', '.msi') } |
            Sort-Object LastWriteTime -Descending
    
    if ($allFiles.Count -eq 0) {
        return $null
    }
    
    # Erstelle verschiedene Suchmuster für flexiblere Erkennung
    $toolName = $Tool.Name
    $searchPatterns = @(
        # Originaler Name ohne Sonderzeichen (normalisiert)
        $toolName -replace '[^a-zA-Z0-9]', '_'
        # Name ohne Sonderzeichen und Leerzeichen
        $toolName -replace '[^a-zA-Z0-9]', ''
        # Name mit Bindestrichen statt Leerzeichen
        $toolName -replace '\s+', '-'
        # Name mit Unterstrichen statt Leerzeichen
        $toolName -replace '\s+', '_'
        # Originaler Name
        $toolName
    )
    
    # Suche nach Dateien, die eines der Muster enthalten (case-insensitive)
    # Rückgabe der neuesten passenden Datei
    foreach ($file in $allFiles) {
        $fileName = $file.BaseName
        foreach ($pattern in $searchPatterns) {
            if ($fileName -like "*$pattern*") {
                return $file.FullName
            }
        }
        
        # Zusätzliche Token-basierte Suche für komplexe Namen wie "7-Zip" -> "7z"
        # Teile Tool-Name in Tokens auf (Zahlen und Wörter)
        $tokens = [regex]::Matches($toolName, '[a-zA-Z]+|\d+') | ForEach-Object { $_.Value }
        if ($tokens.Count -gt 1) {
            # Erstelle kompakte Variante (z.B. "7-Zip" -> "7z")
            $compactName = ($tokens | ForEach-Object { $_.Substring(0, [Math]::Min(1, $_.Length)) }) -join ''
            if ($compactName.Length -ge 2 -and $fileName -like "*$compactName*") {
                return $file.FullName
            }
            
            # Erstelle zusammengesetzte Variante ohne Bindestriche (z.B. "CPU-Z" -> "cpuz")
            $joinedName = $tokens -join ''
            if ($joinedName.Length -ge 3 -and $fileName -like "*$joinedName*") {
                return $file.FullName
            }
        }
    }
    
    return $null
}

# Funktion zum Herunterladen eines Tools (direkter Download)
function Invoke-ToolDownload {
    param (
        [Parameter(Mandatory = $true)]
        [object]$Tool,
        
        [Parameter(Mandatory = $false)]
        [string]$DownloadPath = (Join-Path $PSScriptRoot "..\Data\ToolDownloads"),
        
        [Parameter(Mandatory = $false)]
        [object]$ProgressBar = $null
    )
    
    # Erstelle Download-Verzeichnis, falls es nicht existiert
    if (-not (Test-Path $DownloadPath)) {
        New-Item -ItemType Directory -Path $DownloadPath | Out-Null
    }
    
    try {
        Update-ToolWorkflowProgress -ProgressBar $ProgressBar -StatusText "Download wird vorbereitet..." -ProgressValue 2 -TextColor ([System.Drawing.Color]::White)

        # Generiere einen Basis-Dateinamen
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $safeName = $Tool.Name -replace '[^a-zA-Z0-9]', '_'
        
        Write-Host "Starte Download von $($Tool.Name)..." -ForegroundColor Cyan
        Write-Host "URL: $($Tool.DownloadUrl)" -ForegroundColor Gray
        
        # Debug: ProgressBar Status
        if ($ProgressBar) {
            Write-Host "[DEBUG] ProgressBar verfügbar: Ja" -ForegroundColor Green
        } else {
            Write-Host "[DEBUG] ProgressBar verfügbar: Nein (keine Fortschrittsanzeige in GUI)" -ForegroundColor Yellow
        }
        Write-Host "" # Leerzeile für bessere Lesbarkeit
        
        # Aktiviere TLS 1.2 für sichere HTTPS-Verbindungen
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        
        # Temporärer Pfad
        $tempFile = Join-Path $DownloadPath "temp_${safeName}_${timestamp}"
        
        try {
            # Verwende WebClient für Progress-Tracking
            $webClient = New-Object System.Net.WebClient
            $webClient.Headers.Add('User-Agent', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36')
            $webClient.Headers.Add('Accept', 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8')
            $webClient.Headers.Add('Accept-Language', 'de-DE,de;q=0.9,en;q=0.8')
            
            Write-Host "Lade Datei herunter..." -ForegroundColor Yellow
            Update-ToolWorkflowProgress -ProgressBar $ProgressBar -StatusText "Download gestartet..." -ProgressValue 5 -TextColor ([System.Drawing.Color]::White)
            
            # Variablen für Progress-Tracking
            $script:bytesReceived = 0
            $script:totalBytes = 0
            $script:lastUpdate = [DateTime]::Now
            
            # Progress-Event mit vereinfachter Logik
            $progressHandler = {
                param($sender, $e)
                $script:bytesReceived = $e.BytesReceived
                $script:totalBytes = $e.TotalBytesToReceive
            }
            
            # Registriere Event-Handler
            $webClient.add_DownloadProgressChanged($progressHandler)
            
            # Starte asynchronen Download
            $downloadTask = $webClient.DownloadFileTaskAsync($Tool.DownloadUrl, $tempFile)
            
            # Warte und zeige Fortschritt
            while (-not $downloadTask.IsCompleted) {
                [System.Windows.Forms.Application]::DoEvents()
                
                if ($script:totalBytes -gt 0) {
                    $receivedMB = [Math]::Round($script:bytesReceived / 1MB, 2)
                    $totalMB = [Math]::Round($script:totalBytes / 1MB, 2)
                    $percent = [Math]::Round(($script:bytesReceived / $script:totalBytes) * 100)
                    
                    # Throttle Updates (nur alle 200ms)
                    $now = [DateTime]::Now
                    if (($now - $script:lastUpdate).TotalMilliseconds -gt 200) {
                        $script:lastUpdate = $now
                        
                        # PowerShell Write-Progress
                        Write-Progress -Activity "Download: $($Tool.Name)" -Status "Download läuft: $receivedMB MB / $totalMB MB" -PercentComplete $percent
                        
                        # GUI ProgressBar
                        if ($ProgressBar) {
                            try {
                                $downloadProgress = 5 + [int]([Math]::Round($percent * 0.85))
                                Update-ToolWorkflowProgress -ProgressBar $ProgressBar -StatusText "Download: $receivedMB MB / $totalMB MB ($percent%)" -ProgressValue $downloadProgress -TextColor ([System.Drawing.Color]::Cyan)
                            } catch {
                                # Ignoriere Fehler
                            }
                        }
                        
                        Write-Host "`rDownload: $receivedMB MB / $totalMB MB ($percent%)    " -NoNewline -ForegroundColor Cyan
                    }
                }
                
                Start-Sleep -Milliseconds 50
            }
            
            # Prüfe auf Fehler
            if ($downloadTask.IsFaulted) {
                throw $downloadTask.Exception.InnerException
            }
            
            # Cleanup
            Write-Progress -Activity "Download: $($Tool.Name)" -Completed
            $webClient.remove_DownloadProgressChanged($progressHandler)
            $webClient.Dispose()
            Update-ToolWorkflowProgress -ProgressBar $ProgressBar -StatusText "Download abgeschlossen, verarbeite Datei..." -ProgressValue 92 -TextColor ([System.Drawing.Color]::LightGreen)
            
            Write-Host "`n✓ Download abgeschlossen, verarbeite Datei..." -ForegroundColor Green
            
            # Dateiname aus URL extrahieren
            $finalFileName = $null
            
            # Versuche Dateiname aus der finalen URL zu extrahieren
            $uri = [System.Uri]$Tool.DownloadUrl
            $urlFileName = [System.IO.Path]::GetFileName($uri.LocalPath)
            if ($urlFileName -and $urlFileName -match '\.(exe|msi|zip|7z|rar)$') {
                $finalFileName = $urlFileName
                Write-Host "Dateiname aus URL: $finalFileName" -ForegroundColor Gray
            }
            
            # 4. Fallback: Verwende generierten Namen mit .exe Endung
            if (-not $finalFileName) {
                $finalFileName = "${safeName}_${timestamp}.exe"
                Write-Host "Verwende generierten Dateinamen: $finalFileName" -ForegroundColor Gray
            }
            
            # Stelle sicher, dass der Dateiname sicher ist
            $finalFileName = $finalFileName -replace '[<>:"/\\|?*]', '_'
            $finalPath = Join-Path $DownloadPath $finalFileName
            
            # Umbenennen der temporären Datei
            Move-Item -Path $tempFile -Destination $finalPath -Force
            Update-ToolWorkflowProgress -ProgressBar $ProgressBar -StatusText "Prüfe heruntergeladene Datei..." -ProgressValue 96 -TextColor ([System.Drawing.Color]::White)
            
            if (Test-Path $finalPath) {
                $fileInfo = Get-Item $finalPath
                $fileSizeMB = [Math]::Round($fileInfo.Length / 1MB, 2)
                
                # Prüfe ob Datei verdächtig klein ist (< 1MB könnte Fehlerseite sein)
                if ($fileInfo.Length -lt 1MB) {
                    # Prüfe auf HTML-Inhalt
                    $firstBytes = [System.IO.File]::ReadAllBytes($finalPath) | Select-Object -First 512
                    $firstText = [System.Text.Encoding]::ASCII.GetString($firstBytes)
                    
                    if ($firstText -match '<html|<!DOCTYPE|<head>|<body>') {
                        Remove-Item $finalPath -Force -ErrorAction SilentlyContinue
                        return @{
                            Success  = $false
                            FilePath = $null
                            Message  = "Download fehlgeschlagen: Es wurde eine HTML-Seite statt der Datei heruntergeladen.`n`nDie URL führt wahrscheinlich zu einer Webseite.`n`nBitte:`n1. Besuchen Sie $($Tool.DownloadUrl) im Browser`n2. Laden Sie die Datei manuell herunter`n3. Speichern Sie sie in: $DownloadPath"
                        }
                    }
                }
                
                Write-Host "✓ Download erfolgreich: $finalFileName ($fileSizeMB MB)" -ForegroundColor Green
                Update-ToolWorkflowProgress -ProgressBar $ProgressBar -StatusText "Download erfolgreich abgeschlossen" -ProgressValue 100 -TextColor ([System.Drawing.Color]::LightGreen)
                Start-Sleep -Milliseconds 500
                
                # Resette ProgressBar (Windows Forms - direkter Zugriff)
                if ($ProgressBar) {
                    try {
                        $ProgressBar.Value = 0
                        $ProgressBar.CustomText = "Bereit"
                        $ProgressBar.TextColor = [System.Drawing.Color]::White
                        $ProgressBar.Refresh()
                    } catch {
                        Write-Host "ProgressBar-Reset-Fehler: $($_.Exception.Message)" -ForegroundColor Yellow
                    }
                }
                
                return @{
                    Success  = $true
                    FilePath = $finalPath
                    Message  = "Download erfolgreich: $finalFileName ($fileSizeMB MB)`n`nGespeichert in: $DownloadPath"
                }
            } else {
                return @{
                    Success  = $false
                    FilePath = $null
                    Message  = "Download fehlgeschlagen: Datei konnte nicht erstellt werden"
                }
            }
        } finally {
            # Aufräumen: Temporäre Datei löschen falls noch vorhanden
            if (Test-Path $tempFile) {
                Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
            }
            
            # Resette ProgressBar
            if ($ProgressBar) {
                try {
                    $ProgressBar.Value = 0
                    $ProgressBar.CustomText = "Bereit"
                    $ProgressBar.TextColor = [System.Drawing.Color]::White
                    $ProgressBar.Refresh()
                } catch {}
            }
        }
    } catch {
        $errorMsg = $_.Exception.Message
        Update-ToolWorkflowProgress -ProgressBar $ProgressBar -StatusText "Download fehlgeschlagen" -ProgressValue 0 -TextColor ([System.Drawing.Color]::Red)
        
        # Detaillierte Fehleranalyse
        $detailMsg = "Download fehlgeschlagen: $errorMsg`n`nURL: $($Tool.DownloadUrl)"
        
        if ($_.Exception.Response) {
            $statusCode = $_.Exception.Response.StatusCode.value__
            $statusDesc = $_.Exception.Response.StatusDescription
            $detailMsg += "`nHTTP-Status: $statusCode - $statusDesc"
        }
        
        $detailMsg += "`n`nMögliche Lösungen:`n"
        $detailMsg += "1. Prüfen Sie Ihre Internetverbindung`n"
        $detailMsg += "2. Verwenden Sie 'Installieren' statt 'Download' (funktioniert über Winget)`n"
        $detailMsg += "3. Laden Sie die Datei manuell herunter und speichern Sie sie in:`n   $DownloadPath"
        
        return @{
            Success  = $false
            FilePath = $null
            Message  = $detailMsg
        }
    }
}

# Funktion zum Installieren eines Tools von lokalem Installer
function Expand-ZipAndFindInstaller {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ZipPath,
        [Parameter(Mandatory = $false)]
        [object]$ProgressBar = $null
    )
    
    try {
        # Erstelle temporäres Entpack-Verzeichnis
        $tempExtractPath = Join-Path $env:TEMP "ToolExtract_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
        New-Item -ItemType Directory -Path $tempExtractPath -Force | Out-Null
        
        Write-Host "Entpacke ZIP: $ZipPath..." -ForegroundColor Cyan
        Write-Host "Ziel: $tempExtractPath" -ForegroundColor Gray
        Update-ToolWorkflowProgress -ProgressBar $ProgressBar -StatusText "Entpacke Archiv..." -ProgressValue 72 -TextColor ([System.Drawing.Color]::Yellow)
        
        # Entpacke ZIP
        Expand-Archive -Path $ZipPath -DestinationPath $tempExtractPath -Force
        Update-ToolWorkflowProgress -ProgressBar $ProgressBar -StatusText "Suche Installer im entpackten Archiv..." -ProgressValue 82 -TextColor ([System.Drawing.Color]::White)
        
        # Suche nach installierbaren Dateien (EXE, MSI, Setup)
        $installerFiles = Get-ChildItem -Path $tempExtractPath -Recurse -Include *.exe, *.msi | 
            Where-Object { -not $_.PSIsContainer } |
                Sort-Object { 
                    # Priorisiere Setup/Install-Dateien
                    if ($_.Name -match 'setup|install') { 0 }
                    elseif ($_.Name -match '\.exe$') { 1 }
                    else { 2 }
                }
        
        if ($installerFiles.Count -eq 0) {
            return @{
                Success     = $false
                Message     = "Keine Installer-Datei (.exe/.msi) im ZIP gefunden.`n`nDas Paket scheint portable zu sein.`nBitte verwenden Sie die WinGet-Installation oder entpacken Sie manuell."
                ExtractPath = $tempExtractPath
            }
        }
        
        # Wähle den besten Installer
        $installerFile = $installerFiles[0]
        
        Write-Host "✓ Installer gefunden: $($installerFile.Name)" -ForegroundColor Green
        Update-ToolWorkflowProgress -ProgressBar $ProgressBar -StatusText "Installer gefunden: $($installerFile.Name)" -ProgressValue 88 -TextColor ([System.Drawing.Color]::LightGreen)
        
        return @{
            Success       = $true
            InstallerPath = $installerFile.FullName
            ExtractPath   = $tempExtractPath
            Message       = "ZIP erfolgreich entpackt. Installer gefunden: $($installerFile.Name)"
        }
    } catch {
        return @{
            Success     = $false
            Message     = "Fehler beim Entpacken der ZIP: $($_.Exception.Message)"
            ExtractPath = $tempExtractPath
        }
    }
}

function Install-ToolFromLocal {
    param (
        [Parameter(Mandatory = $true)]
        [string]$InstallerPath,
        
        [Parameter(Mandatory = $false)]
        [switch]$Silent,

        [Parameter(Mandatory = $false)]
        [object]$ProgressBar = $null
    )
    
    # Prüfe ob Datei existiert
    if (-not (Test-Path $InstallerPath)) {
        return @{
            Success = $false
            Message = "Installer nicht gefunden: $InstallerPath"
        }
    }
    
    # Hole Datei-Informationen
    $fileInfo = Get-Item $InstallerPath
    $fileExtension = $fileInfo.Extension.ToLower()
    
    # ===== NEUE LOGIK: ZIP-Behandlung =====
    if ($fileExtension -eq '.zip') {
        Write-Host "ZIP-Datei erkannt - starte automatisches Entpacken..." -ForegroundColor Yellow
        Update-ToolWorkflowProgress -ProgressBar $ProgressBar -StatusText "ZIP erkannt - starte Entpacken..." -ProgressValue 68 -TextColor ([System.Drawing.Color]::Yellow)
        
        $extractResult = Expand-ZipAndFindInstaller -ZipPath $InstallerPath -ProgressBar $ProgressBar
        
        if (-not $extractResult.Success) {
            # Aufräumen bei Fehler
            if ($extractResult.ExtractPath -and (Test-Path $extractResult.ExtractPath)) {
                Remove-Item -Path $extractResult.ExtractPath -Recurse -Force -ErrorAction SilentlyContinue
            }
            return $extractResult
        }
        
        # Rekursiver Aufruf mit extrahierter EXE
        Write-Host "Starte Installation der extrahierten Datei..." -ForegroundColor Cyan
        Update-ToolWorkflowProgress -ProgressBar $ProgressBar -StatusText "Starte Installation aus entpacktem Archiv..." -ProgressValue 90 -TextColor ([System.Drawing.Color]::Cyan)
        $installResult = Install-ToolFromLocal -InstallerPath $extractResult.InstallerPath -Silent:$Silent -ProgressBar $ProgressBar
        
        # Aufräumen nach Installation
        Write-Host "Räume temporäre Dateien auf..." -ForegroundColor Gray
        Update-ToolWorkflowProgress -ProgressBar $ProgressBar -StatusText "Räume temporäre Dateien auf..." -ProgressValue 95 -TextColor ([System.Drawing.Color]::White)
        if ($extractResult.ExtractPath -and (Test-Path $extractResult.ExtractPath)) {
            Start-Sleep -Seconds 2  # Kurze Pause damit Installer Dateien freigeben kann
            Remove-Item -Path $extractResult.ExtractPath -Recurse -Force -ErrorAction SilentlyContinue
        }
        
        return $installResult
    }
    
    # Prüfe ob es eine gültige Installer-Datei ist
    $validExtensions = @('.exe', '.msi', '.bat', '.cmd')
    if ($fileExtension -notin $validExtensions) {
        return @{
            Success = $false
            Message = "Ungültiger Dateityp: $fileExtension`n`nErwartet: .exe, .msi, .bat, .cmd oder .zip`n`nDie heruntergeladene Datei scheint kein Installer zu sein.`nBitte überprüfen Sie die Download-URL."
        }
    }
    
    # Prüfe Dateigröße (zu klein = wahrscheinlich Fehlerdatei)
    if ($fileInfo.Length -lt 1KB) {
        return @{
            Success = $false
            Message = "Die Datei ist verdächtig klein ($($fileInfo.Length) Bytes).`n`nWahrscheinlich wurde eine Fehlerseite statt der echten Datei heruntergeladen.`n`nBitte löschen Sie die Datei und versuchen Sie den Download erneut."
        }
    }
    
    # Prüfe ob Datei Text/HTML enthält (falsche Download-URL)
    try {
        $firstBytes = [System.IO.File]::ReadAllBytes($InstallerPath) | Select-Object -First 512
        $firstText = [System.Text.Encoding]::ASCII.GetString($firstBytes)
        
        if ($firstText -match '<html|<!DOCTYPE|<head>|<body>') {
            return @{
                Success = $false
                Message = "Die heruntergeladene Datei ist eine HTML-Webseite, kein Installer!`n`nDie Download-URL führt zu einer Webseite statt zur Installer-Datei.`n`nBitte:`n1. Löschen Sie die Datei aus dem ToolDownloads-Ordner`n2. Besuchen Sie die Download-Webseite manuell`n3. Laden Sie die richtige Installer-Datei herunter`n4. Speichern Sie diese im ToolDownloads-Ordner"
            }
        }
    } catch {
        # Fehler beim Lesen ignorieren, Datei könnte gesperrt sein
    }
    
    Write-Host "Starte Installer: $($fileInfo.Name)..." -ForegroundColor Cyan
    Update-ToolWorkflowProgress -ProgressBar $ProgressBar -StatusText "Starte Installer: $($fileInfo.Name)" -ProgressValue 92 -TextColor ([System.Drawing.Color]::Cyan)
    
    try {
        # Verwende Start-Process für bessere Kompatibilität
        $startParams = @{
            FilePath = $InstallerPath
            Verb     = 'RunAs'
            PassThru = $true
        }
        
        # Füge Argumente hinzu falls vorhanden
        if ($Silent) {
            # Versuche verschiedene Silent-Parameter je nach Dateityp
            $silentArgs = switch ($fileExtension) {
                '.msi' { '/quiet /norestart' }
                '.exe' { '/S /silent /quiet' }
                default { '/S' }
            }
            $startParams['ArgumentList'] = $silentArgs
        }
        
        $process = Start-Process @startParams
        
        if ($Silent) {
            Write-Host "Warte auf Installations-Abschluss..." -ForegroundColor Yellow
            Update-ToolWorkflowProgress -ProgressBar $ProgressBar -StatusText "Installation läuft..." -ProgressValue 94 -TextColor ([System.Drawing.Color]::Yellow)
            
            # Warte auf Prozessende (max 5 Minuten)
            $waitStart = Get-Date
            while (-not $process.HasExited -and ((Get-Date) - $waitStart).TotalMilliseconds -lt 300000) {
                $elapsedMs = ((Get-Date) - $waitStart).TotalMilliseconds
                $waitPercent = [int]([Math]::Min(4, [Math]::Floor(($elapsedMs / 300000) * 4)))
                Update-ToolWorkflowProgress -ProgressBar $ProgressBar -StatusText "Installation läuft..." -ProgressValue (94 + $waitPercent) -TextColor ([System.Drawing.Color]::Yellow)
                Start-Sleep -Milliseconds 250
            }

            if ($process.HasExited) {
                $exitCode = $process.ExitCode
                
                if ($exitCode -eq 0) {
                    Write-Host "✓ Installation erfolgreich abgeschlossen" -ForegroundColor Green
                    Update-ToolWorkflowProgress -ProgressBar $ProgressBar -StatusText "Installation erfolgreich abgeschlossen" -ProgressValue 100 -TextColor ([System.Drawing.Color]::LightGreen)
                    return @{
                        Success = $true
                        Message = "Installation erfolgreich abgeschlossen!"
                    }
                } else {
                    Write-Host "✗ Installation mit Fehlercode $exitCode beendet" -ForegroundColor Red
                    Update-ToolWorkflowProgress -ProgressBar $ProgressBar -StatusText "Installation fehlgeschlagen (Code $exitCode)" -ProgressValue 0 -TextColor ([System.Drawing.Color]::Red)
                    return @{
                        Success = $false
                        Message = "Installation fehlgeschlagen (Exit-Code: $exitCode)`n`nMöglicherweise wurden Admin-Rechte verweigert oder die Installation wurde abgebrochen."
                    }
                }
            } else {
                Write-Host "⚠ Installation-Timeout" -ForegroundColor Yellow
                Update-ToolWorkflowProgress -ProgressBar $ProgressBar -StatusText "Installation-Timeout" -ProgressValue 0 -TextColor ([System.Drawing.Color]::Red)
                return @{
                    Success = $false
                    Message = "Installation dauert zu lange (>5 Min).`n`nBitte prüfen Sie manuell, ob die Installation erfolgreich war."
                }
            }
        } else {
            # Bei manueller Installation nur Start bestätigen
            Write-Host "✓ Installer wurde gestartet" -ForegroundColor Green
            Update-ToolWorkflowProgress -ProgressBar $ProgressBar -StatusText "Installer wurde gestartet" -ProgressValue 100 -TextColor ([System.Drawing.Color]::LightGreen)
            return @{
                Success = $true
                Message = "Installer wurde erfolgreich gestartet.`n`nBitte folgen Sie den Anweisungen des Installers."
            }
        }
    } catch {
        $errorMsg = $_.Exception.Message
        Write-Host "✗ Fehler beim Starten des Installers: $errorMsg" -ForegroundColor Red
        Update-ToolWorkflowProgress -ProgressBar $ProgressBar -StatusText "Fehler beim Starten des Installers" -ProgressValue 0 -TextColor ([System.Drawing.Color]::Red)
        
        # Spezifische Fehlermeldungen
        if ($errorMsg -match 'keine gültige Anwendung|not a valid Win32 application') {
            return @{
                Success = $false
                Message = "Die Datei ist keine gültige Windows-Anwendung!`n`n$errorMsg`n`nMögliche Ursachen:`n• Die heruntergeladene Datei ist beschädigt`n• Es wurde eine Fehlerseite statt der Datei heruntergeladen`n• Die Datei ist für ein anderes Betriebssystem`n`nLösung:`n1. Löschen Sie die Datei aus dem ToolDownloads-Ordner`n2. Laden Sie die Datei erneut herunter`n3. Oder laden Sie sie manuell von der Webseite herunter"
            }
        }
        
        return @{
            Success = $false
            Message = "Fehler beim Starten des Installers:`n`n$errorMsg`n`nBitte versuchen Sie:`n• Die Datei manuell als Administrator auszuführen`n• Die Datei erneut herunterzuladen`n• Die Datei von der Webseite manuell zu laden"
        }
    }
}

function Install-ToolPackage {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ToolName,
        
        [Parameter(Mandatory = $false)]
        [string]$DownloadPath = (Join-Path $PSScriptRoot "..\Data\ToolDownloads"),
        
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
    } catch {
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
                } catch {
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
        0x80070005 { return "Zugriff verweigert (Admin-Rechte erforderlich)." }
        0x800704C7 { return "Vorgang wurde abgebrochen oder Datei wird verwendet." }
        default { return "Unbekannter Fehler. Winget-Exit-Code: $ErrorCode" }
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

function Update-ToolWorkflowProgress {
    param (
        [Parameter(Mandatory = $false)]
        [object]$ProgressBar = $null,
        [Parameter(Mandatory = $true)]
        [string]$StatusText,
        [Parameter(Mandatory = $true)]
        [int]$ProgressValue,
        [Parameter(Mandatory = $false)]
        [System.Drawing.Color]$TextColor = [System.Drawing.Color]::White
    )

    if (-not $ProgressBar) { return }

    try {
        $safeValue = [Math]::Min([Math]::Max($ProgressValue, 0), 100)
        $ProgressBar.Value = $safeValue

        if ($ProgressBar.GetType().Name -eq "TextProgressBar") {
            $ProgressBar.CustomText = $StatusText
            $ProgressBar.TextColor = $TextColor
        }

        $ProgressBar.Refresh()
        [System.Windows.Forms.Application]::DoEvents()
    } catch {
    }
}

function Invoke-WingetWithLiveOutput {
    param (
        [Parameter(Mandatory = $true)]
        [string[]]$Arguments,
        [Parameter(Mandatory = $true)]
        [string]$ToolName,
        [Parameter(Mandatory = $true)]
        [string]$OperationLabel,
        [Parameter(Mandatory = $false)]
        [object]$ProgressBar = $null,
        [Parameter(Mandatory = $false)]
        [int]$StartProgress = 70,
        [Parameter(Mandatory = $false)]
        [int]$EndProgress = 95,
        [Parameter(Mandatory = $false)]
        [int]$TimeoutSeconds = 300
    )

    $escapedArgs = $Arguments | ForEach-Object {
        if ($_ -match '\s') { '"' + ($_ -replace '"', '\"') + '"' } else { $_ }
    }

    $logDirectory = Join-Path $PSScriptRoot "..\Data\Logs"
    if (-not (Test-Path $logDirectory)) {
        New-Item -ItemType Directory -Path $logDirectory -Force | Out-Null
    }

    $safeToolName = $ToolName -replace '[^a-zA-Z0-9\-_]', '_'
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $wingetLogPath = Join-Path $logDirectory "winget_${safeToolName}_${timestamp}.log"

    $hasLogArg = $Arguments -contains '--log'
    $primaryCommand = if ($Arguments.Count -gt 0) { "$($Arguments[0])".ToLowerInvariant() } else { '' }
    $supportsWingetLog = @('install', 'upgrade', 'uninstall', 'repair') -contains $primaryCommand
    $effectiveArgs = @($Arguments)
    if ($supportsWingetLog -and -not $hasLogArg) {
        $effectiveArgs += @('--log', $wingetLogPath)
    }

    $escapedArgs = $effectiveArgs | ForEach-Object {
        if ($_ -match '\s') { '"' + ($_ -replace '"', '\"') + '"' } else { $_ }
    }
    $argumentString = ($escapedArgs -join ' ')

    Update-ToolWorkflowProgress -ProgressBar $ProgressBar -StatusText "Starte Winget-${OperationLabel}: $ToolName..." -ProgressValue $StartProgress -TextColor ([System.Drawing.Color]::Cyan)

    if (Get-Command -Name Write-ToolLog -ErrorAction SilentlyContinue) {
        Write-ToolLog -ToolName "Winget-Operations" -Message "Starte: winget $argumentString" -Level Information
        Write-ToolLog -ToolName "Winget-Operations" -Message "Detail-Log: $wingetLogPath" -Level Information
    }
    Write-Host "Starte: winget $argumentString" -ForegroundColor Cyan

    # P/Invoke-Helfer fuer Fensterpositionierung (einmalig laden)
    if (-not ([System.Management.Automation.PSTypeName]'BockisWinHelper').Type) {
        Add-Type @"
using System;
using System.Runtime.InteropServices;
public class BockisWinHelper {
    [DllImport("user32.dll", CharSet=CharSet.Auto)]
    public static extern IntPtr FindWindow(string lpClassName, string lpWindowName);
    [DllImport("user32.dll")]
    public static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter, int X, int Y, int cx, int cy, uint uFlags);
}
"@
    }

    # Monitor ermitteln, auf dem die GUI laeuft
    $cmdTargetX = 80
    $cmdTargetY = 80
    try {
        $guiWin = [System.Windows.Application]::Current.MainWindow
        if ($guiWin) {
            Add-Type -AssemblyName System.Windows.Forms -ErrorAction SilentlyContinue
            $pt = New-Object System.Drawing.Point([int]($guiWin.Left + 50), [int]($guiWin.Top + 50))
            $screen = [System.Windows.Forms.Screen]::FromPoint($pt)
            $cmdTargetX = $screen.WorkingArea.X + 80
            $cmdTargetY = $screen.WorkingArea.Y + 80
        }
    } catch { }

    try {
        # CMD-Fenster mit beschreibendem Titel öffnen — zeigt echten winget-Fortschritt (MB/MB etc.)
        # cmd /c schließt das Fenster automatisch wenn winget fertig ist
        $windowTitle = "Bockis System-Tool - ${OperationLabel}: $ToolName"
        $cmdArgs = "/c `"title $windowTitle && winget $argumentString`""

        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = "cmd.exe"
        $psi.Arguments = $cmdArgs
        $psi.UseShellExecute = $true
        $psi.CreateNoWindow = $false
        $psi.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Normal

        $process = New-Object System.Diagnostics.Process
        $process.StartInfo = $psi
        $null = $process.Start()

        $lineProgress = $StartProgress
        $timedOut = $false
        $windowMoved = $false
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

        # Fortschrittsbalken laeuft parallel — CMD-Fenster zeigt echten Fortschritt
        while (-not $process.HasExited) {
            # CMD-Fenster auf den GUI-Monitor verschieben (sobald es erscheint)
            if (-not $windowMoved) {
                $hwnd = [BockisWinHelper]::FindWindow($null, $windowTitle)
                if ($hwnd -ne [IntPtr]::Zero) {
                    # SWP_NOZORDER=0x0004 | SWP_SHOWWINDOW=0x0040
                    [BockisWinHelper]::SetWindowPos($hwnd, [IntPtr]::Zero, $cmdTargetX, $cmdTargetY, 950, 520, 0x0044) | Out-Null
                    $windowMoved = $true
                }
            }

            if ($lineProgress -lt ($EndProgress - 1)) {
                $lineProgress++
                Update-ToolWorkflowProgress -ProgressBar $ProgressBar -StatusText "$OperationLabel läuft: $ToolName  (siehe CMD-Fenster)" -ProgressValue $lineProgress -TextColor ([System.Drawing.Color]::Yellow)
            }
            Start-Sleep -Milliseconds 450

            if ($stopwatch.Elapsed.TotalSeconds -ge $TimeoutSeconds) {
                $timedOut = $true
                try { $process.Kill() } catch { }
                break
            }
        }

        try { $process.WaitForExit(2000) | Out-Null } catch { }

        $exitCodeRaw = $null
        if ($process.HasExited -and -not $timedOut) {
            try {
                $exitCodeRaw = $process.ExitCode
            } catch {
                $exitCodeRaw = $null
            }
        }

        $exitCode = -1
        if ($null -ne $exitCodeRaw -and -not [string]::IsNullOrWhiteSpace("$exitCodeRaw")) {
            try {
                $exitCode = [int]$exitCodeRaw
            } catch {
                $exitCode = -1
            }
        }

        $derivedSuccess = $false
        if (-not $timedOut -and $exitCode -eq -1 -and (Test-Path $wingetLogPath)) {
            try {
                $logLines = Get-Content -Path $wingetLogPath -Tail 120 -ErrorAction SilentlyContinue
                $logTail = $logLines -join "`n"

                # Nur starke, abschließende Erfolgssignale akzeptieren
                $hasStrongSuccess = ($logTail -match '(?im)^\s*(Erfolgreich installiert|Successfully installed)\s*$') -or
                ($logTail -match '(?im)Installation process succeeded\.') -or
                ($logTail -match '(?im)Setup .* completed successfully')

                # Häufige Fehlersignale blockieren den Fallback
                $hasFailureSignal = $logTail -match '(?im)\b(error|fehler|failed|fehlgeschlagen|aborted|cancelled|rollback|fatal)\b'

                if ($hasStrongSuccess -and -not $hasFailureSignal) {
                    $derivedSuccess = $true
                    $exitCode = 0
                }
            } catch {
            }
        }

        if (Get-Command -Name Write-ToolLog -ErrorAction SilentlyContinue) {
            $level = if ($exitCode -eq 0 -and -not $timedOut) { 'Success' } elseif ($timedOut) { 'Warning' } else { 'Error' }
            Write-ToolLog -ToolName "Winget-Operations" -Message "Beendet: $OperationLabel $ToolName | ExitCode=$exitCode | Timeout=$timedOut" -Level $level
            if ($derivedSuccess) {
                Write-ToolLog -ToolName "Winget-Operations" -Message "ExitCode war nicht auswertbar, Erfolg wurde aus Logdatei abgeleitet." -Level Warning
            }
        }

        return @{
            Success  = (-not $timedOut -and $exitCode -eq 0)
            ExitCode = $exitCode
            TimedOut = $timedOut
            Command  = "winget $argumentString"
            LogPath  = $wingetLogPath
        }
    } catch {
        if (Get-Command -Name Write-ToolLog -ErrorAction SilentlyContinue) {
            Write-ToolLog -ToolName "Winget-Operations" -Message "Ausführung fehlgeschlagen: $($_.Exception.Message)" -Level Error
        }

        return @{
            Success      = $false
            ExitCode     = -1
            TimedOut     = $false
            Command      = "winget $argumentString"
            ErrorMessage = $_.Exception.Message
        }
    }
}

# Ressourcen-Dictionary für Tool-Kacheln
$script:toolResourceDictionary = @{
    ToolTileMargins             = New-Object Windows.Thickness(5)
    ToolTileFontSize            = 14
    ToolTileBorderThickness     = New-Object Windows.Thickness(1)
    ToolTileWidth               = 350
    ToolTileWidthLarge          = 230
    ToolTileWidthMedium         = 350
    ToolTileWidthList           = 720
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
        "Large" { $script:toolResourceDictionary["ToolTileWidthLarge"] }
        "Medium" { $script:toolResourceDictionary["ToolTileWidthMedium"] }
        "List" { $script:toolResourceDictionary["ToolTileWidthList"] }
        default { $script:toolResourceDictionary["ToolTileWidthMedium"] }
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
    
    # Prüfen, ob das Tool bereits heruntergeladen wurde
    $isDownloaded = Test-ToolDownloaded -Tool $Tool
    
    # Wenn installiert, hole Versionsinformationen
    if ($isInstalled -and $Tool.Winget) {
        $versionInfo = Get-ToolVersionInfo -Tool $Tool
        $hasUpdate = $versionInfo.HasUpdate
    }
    
    # DEBUG: Ausgabe für Fehlersuche (nur in Logs, nicht in Konsole)
    $debugMsg = "Tool: $($Tool.Name) | Winget: $($Tool.Winget) | Installiert: $isInstalled | Download: $isDownloaded | Update: $hasUpdate"
    if ($versionInfo) {
        $debugMsg += " | Installiert: $($versionInfo.InstalledVersion) | Verfügbar: $($versionInfo.AvailableVersion)"
    }
    $debugMsg += " | Cache-Status: $(if ($null -ne $script:installedPackagesCache) { 'Geladen' } else { 'Leer' })"
    Write-Verbose $debugMsg
    # Write-Host $debugMsg -ForegroundColor Cyan  # Deaktiviert - nur noch in Logs
    
    # Farben basierend auf Status
    if ($hasUpdate) {
        # Update verfügbar - Orange/Gelb
        $border.Background = [Windows.Media.Brushes]::LightGoldenrodYellow
        $border.BorderBrush = [Windows.Media.Brushes]::Orange
    } elseif ($isInstalled -eq $true) {
        # Installiert und aktuell - Grün
        $border.Background = [Windows.Media.Brushes]::LightGreen
        $border.BorderBrush = [Windows.Media.Brushes]::Green
    } elseif ($isDownloaded) {
        # Heruntergeladen, nicht installiert - Hellblau/Lavender
        $border.Background = [Windows.Media.Brushes]::Lavender
        $border.BorderBrush = [Windows.Media.Brushes]::SteelBlue
    } else {
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
    } elseif ($isInstalled) {
        $tooltipText = "[INSTALLIERT"
        if ($versionInfo -and $versionInfo.InstalledVersion) {
            $tooltipText += " v$($versionInfo.InstalledVersion)"
        }
        $tooltipText += "] " + $Tool.Description
    } elseif ($isDownloaded) {
        $tooltipText = "[HERUNTERGELADEN - BEREIT ZUR INSTALLATION] " + $Tool.Description
    }
    $border.ToolTip = $tooltipText

    # Hover-Effekt mit Berücksichtigung des installierten Status und Update-Status
    $installedStatus = $isInstalled
    $updateStatus = $hasUpdate
    $downloadedStatus = $isDownloaded
    
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
            } elseif ($installedStatus) {
                $this.Background = [Windows.Media.Brushes]::MediumSeaGreen
            } elseif ($downloadedStatus) {
                $this.Background = [Windows.Media.Brushes]::LightSkyBlue
            } else {
                $this.Background = $highlightColor
            }
        }.GetNewClosure())
    $border.Add_MouseLeave({
            if ($updateStatus) {
                $this.Background = [Windows.Media.Brushes]::LightGoldenrodYellow
            } elseif ($installedStatus) {
                $this.Background = [Windows.Media.Brushes]::LightGreen
            } elseif ($downloadedStatus) {
                $this.Background = [Windows.Media.Brushes]::Lavender
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
        } elseif ($isInstalled) {
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
            } elseif ($toolInfo.Version) {
                $infoText += "Version: $($toolInfo.Version)`n"
            }
            
            $infoText += "Kategorie: $($toolInfo.Category)`n"
            
            # Installationsstatus
            if ($isInstalled) {
                if ($versionInfo -and $versionInfo.HasUpdate) {
                    $infoText += "Status: INSTALLIERT (Update verfügbar)`n`n"
                } else {
                    $infoText += "Status: INSTALLIERT (Aktuell)`n`n"
                }
            } else {
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

    # Universal Download/Install/Update Button (3-Zustands-Logik)
    if ($Tool.Winget -or $Tool.DownloadUrl) {
        # Prüfe ob Tool bereits heruntergeladen wurde
        $isDownloaded = Test-ToolDownloaded -Tool $Tool
        $localInstallerPath = if ($isDownloaded) { Get-ToolLocalInstallerPath -Tool $Tool } else { $null }
        
        $actionButton = New-Object Windows.Controls.Button
        $actionButton.Width = if ($isListView) { 40 } else { 45 }
        $actionButton.Height = if ($isListView) { 28 } else { 35 }
        $actionButton.Margin = if ($isListView) { New-Object Windows.Thickness(1) } else { New-Object Windows.Thickness(2) }
        $actionIcon = New-Object Windows.Controls.TextBlock
        
        # Icon und Tooltip basierend auf 3-Zustands-Logik
        if ($isInstalled -and $hasUpdate) {
            # Zustand 3: Installiert mit verfügbarem Update → Aktualisieren
            $actionIcon.Text = [char]0xE117  # Update-Symbol (Sync)
            $actionIcon.Foreground = [Windows.Media.Brushes]::DarkOrange
            $actionButton.ToolTip = "Update durchführen"
            $actionButton.Background = [Windows.Media.Brushes]::LightYellow
        } elseif ($isInstalled) {
            # Installiert und aktuell → Neu installieren/reparieren
            $actionIcon.Text = [char]0xE117  # Sync-Symbol
            $actionIcon.Foreground = [Windows.Media.Brushes]::Green
            $actionButton.ToolTip = "Neu installieren/reparieren"
        } elseif ($isDownloaded) {
            # Zustand 2: Heruntergeladen, nicht installiert → Installieren
            $actionIcon.Text = [char]0xE8B5  # Install-Symbol
            $actionIcon.Foreground = [Windows.Media.Brushes]::Blue
            $actionButton.ToolTip = "Von lokalem Download installieren"
            $actionButton.Background = [Windows.Media.Brushes]::LightCyan
        } else {
            # Zustand 1: Nicht heruntergeladen → Herunterladen
            $actionIcon.Text = [char]0xE896  # Download-Symbol
            $actionIcon.Foreground = [Windows.Media.Brushes]::Green
            $actionButton.ToolTip = "Tool herunterladen"
        }
        
        $actionIcon.FontFamily = New-Object Windows.Media.FontFamily("Segoe MDL2 Assets")
        $actionIcon.FontSize = 20
        $actionButton.Content = $actionIcon
        $actionButton.Tag = @{ 
            Tool               = $Tool
            HasUpdate          = $hasUpdate
            IsInstalled        = $isInstalled
            IsDownloaded       = $isDownloaded
            LocalInstallerPath = $localInstallerPath
        }
        
        $actionButton.Add_Click({
                $buttonData = $this.Tag
                $toolInfo = $buttonData.Tool
                $hasUpdate = $buttonData.HasUpdate
                $isInstalled = $buttonData.IsInstalled
                $isDownloaded = $buttonData.IsDownloaded
                $localInstallerPath = $buttonData.LocalInstallerPath
                
                try {
                    # ===== Zustand 3: UPDATE =====
                    if ($isInstalled -and $hasUpdate) {
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
                        
                        $wingetResult = Invoke-WingetWithLiveOutput `
                            -Arguments @('upgrade', '--id', $toolInfo.Winget, '--silent', '--accept-source-agreements', '--accept-package-agreements', '--disable-interactivity') `
                            -ToolName $toolInfo.Name `
                            -OperationLabel 'Update' `
                            -ProgressBar $global:progressBar `
                            -StartProgress 70 `
                            -EndProgress 95 `
                            -TimeoutSeconds 300

                        if ($wingetResult.Success) {
                            Update-ToolWorkflowProgress -ProgressBar $global:progressBar -StatusText "Update erfolgreich: $($toolInfo.Name)" -ProgressValue 100 -TextColor ([System.Drawing.Color]::LightGreen)
                            [System.Windows.Forms.MessageBox]::Show(
                                "$($toolInfo.Name) wurde erfolgreich aktualisiert!",
                                "Update erfolgreich",
                                [System.Windows.Forms.MessageBoxButtons]::OK,
                                [System.Windows.Forms.MessageBoxIcon]::Information
                            )
                        } elseif ($wingetResult.TimedOut) {
                            Update-ToolWorkflowProgress -ProgressBar $global:progressBar -StatusText "Update Timeout: $($toolInfo.Name)" -ProgressValue 0 -TextColor ([System.Drawing.Color]::Red)
                            [System.Windows.Forms.MessageBox]::Show(
                                "Update Timeout (>5 Min). Bitte manuell prüfen.",
                                "Timeout",
                                [System.Windows.Forms.MessageBoxButtons]::OK,
                                [System.Windows.Forms.MessageBoxIcon]::Warning
                            )
                        } else {
                            Update-ToolWorkflowProgress -ProgressBar $global:progressBar -StatusText "Update fehlgeschlagen: $($toolInfo.Name)" -ProgressValue 0 -TextColor ([System.Drawing.Color]::Red)
                            $errorDesc = Get-WingetErrorDescription -ErrorCode $wingetResult.ExitCode
                            [System.Windows.Forms.MessageBox]::Show(
                                "Update fehlgeschlagen!`n`nFehlercode: $($wingetResult.ExitCode)`n`n$errorDesc`n`nDebug-Tipp: Führen Sie 'winget upgrade --id $($toolInfo.Winget)' in PowerShell aus.",
                                "Update fehlgeschlagen",
                                [System.Windows.Forms.MessageBoxButtons]::OK,
                                [System.Windows.Forms.MessageBoxIcon]::Warning
                            )
                        }
                    }
                    # ===== Zustand 2: INSTALLIEREN (von lokal) =====
                    elseif ($isDownloaded -and -not $isInstalled) {
                        $result = [System.Windows.Forms.MessageBox]::Show(
                            "Möchten Sie $($toolInfo.Name) aus dem lokalen Download installieren?`n`nDatei: $localInstallerPath",
                            "Installation - $($toolInfo.Name)",
                            [System.Windows.Forms.MessageBoxButtons]::YesNo,
                            [System.Windows.Forms.MessageBoxIcon]::Question
                        )
                        
                        if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
                            [System.Windows.Forms.MessageBox]::Show(
                                "Installation von $($toolInfo.Name) wird gestartet.`n`nBitte folgen Sie den Anweisungen des Installers.",
                                "Installation - $($toolInfo.Name)",
                                [System.Windows.Forms.MessageBoxButtons]::OK,
                                [System.Windows.Forms.MessageBoxIcon]::Information
                            )
                            
                            # Installiere von lokalem Installer
                            $installParams = @{ InstallerPath = $localInstallerPath }
                            if ($global:progressBar) {
                                $installParams['ProgressBar'] = $global:progressBar
                            }
                            $installResult = Install-ToolFromLocal @installParams
                            
                            if ($installResult.Success) {
                                [System.Windows.Forms.MessageBox]::Show(
                                    "$($toolInfo.Name) wurde gestartet!`n`n$($installResult.Message)",
                                    "Installation",
                                    [System.Windows.Forms.MessageBoxButtons]::OK,
                                    [System.Windows.Forms.MessageBoxIcon]::Information
                                )
                                
                                # Cache aktualisieren
                                if (Get-Command -Name Update-ToolInstallationStatus -ErrorAction SilentlyContinue) {
                                    Update-ToolInstallationStatus -Tool $toolInfo -IsInstalled $true
                                }
                            } else {
                                [System.Windows.Forms.MessageBox]::Show(
                                    "Installation fehlgeschlagen!`n`n$($installResult.Message)",
                                    "Fehler",
                                    [System.Windows.Forms.MessageBoxButtons]::OK,
                                    [System.Windows.Forms.MessageBoxIcon]::Warning
                                )
                            }
                        }
                    }
                    # ===== Zustand 1: HERUNTERLADEN =====
                    elseif (-not $isDownloaded -and -not $isInstalled) {
                        # Wenn Winget verfügbar ist, Auswahl anbieten
                        if ($toolInfo.Winget) {
                            $choice = Show-ToolAcquisitionDialog -ToolName $toolInfo.Name
                            
                            if ($choice -eq "Install") {
                                # Via Winget installieren
                                [System.Windows.Forms.MessageBox]::Show(
                                    "Installation von $($toolInfo.Name) wird gestartet.`n`nBitte warten Sie, bis die Installation abgeschlossen ist.",
                                    "Installation - $($toolInfo.Name)",
                                    [System.Windows.Forms.MessageBoxButtons]::OK,
                                    [System.Windows.Forms.MessageBoxIcon]::Information
                                )
                                
                                $wingetResult = Invoke-WingetWithLiveOutput `
                                    -Arguments @('install', '--id', $toolInfo.Winget, '--silent', '--accept-source-agreements', '--accept-package-agreements', '--disable-interactivity') `
                                    -ToolName $toolInfo.Name `
                                    -OperationLabel 'Installation' `
                                    -ProgressBar $global:progressBar `
                                    -StartProgress 70 `
                                    -EndProgress 95 `
                                    -TimeoutSeconds 300

                                if ($wingetResult.Success) {
                                    Update-ToolWorkflowProgress -ProgressBar $global:progressBar -StatusText "Installation erfolgreich: $($toolInfo.Name)" -ProgressValue 100 -TextColor ([System.Drawing.Color]::LightGreen)
                                    [System.Windows.Forms.MessageBox]::Show(
                                        "$($toolInfo.Name) wurde erfolgreich installiert!",
                                        "Installation erfolgreich",
                                        [System.Windows.Forms.MessageBoxButtons]::OK,
                                        [System.Windows.Forms.MessageBoxIcon]::Information
                                    )
                                } elseif ($wingetResult.TimedOut) {
                                    Update-ToolWorkflowProgress -ProgressBar $global:progressBar -StatusText "Installation Timeout: $($toolInfo.Name)" -ProgressValue 0 -TextColor ([System.Drawing.Color]::Red)
                                } else {
                                    Update-ToolWorkflowProgress -ProgressBar $global:progressBar -StatusText "Installation fehlgeschlagen: $($toolInfo.Name)" -ProgressValue 0 -TextColor ([System.Drawing.Color]::Red)
                                    $errorDesc = Get-WingetErrorDescription -ErrorCode $wingetResult.ExitCode
                                    [System.Windows.Forms.MessageBox]::Show(
                                        "Installation fehlgeschlagen!`n`nFehlercode: $($wingetResult.ExitCode)`n`n$errorDesc",
                                        "Fehler",
                                        [System.Windows.Forms.MessageBoxButtons]::OK,
                                        [System.Windows.Forms.MessageBoxIcon]::Warning
                                    )
                                }
                            } elseif ($choice -eq "Download") {
                                # Herunterladen
                                [System.Windows.Forms.MessageBox]::Show(
                                    "Download von $($toolInfo.Name) wird gestartet...",
                                    "Download - $($toolInfo.Name)",
                                    [System.Windows.Forms.MessageBoxButtons]::OK,
                                    [System.Windows.Forms.MessageBoxIcon]::Information
                                )
                                
                                # Übergebe globale ProgressBar falls verfügbar
                                $downloadParams = @{ Tool = $toolInfo }
                                if ($global:progressBar) {
                                    $downloadParams['ProgressBar'] = $global:progressBar
                                }
                                $downloadResult = Invoke-ToolDownload @downloadParams
                                
                                $dlgTitle = if ($downloadResult.Success) { "Download erfolgreich" } else { "Download" }
                                $dlgIcon = if ($downloadResult.Success) { [System.Windows.Forms.MessageBoxIcon]::Information } else { [System.Windows.Forms.MessageBoxIcon]::Warning }
                                [System.Windows.Forms.MessageBox]::Show(
                                    $downloadResult.Message,
                                    $dlgTitle,
                                    [System.Windows.Forms.MessageBoxButtons]::OK,
                                    $dlgIcon
                                )
                                
                                # Bei erfolgreichem Download: Button und Kachel visuell aktualisieren
                                if ($downloadResult.Success) {
                                    try {
                                        # Finde die Border (Kachel) dieses Buttons
                                        $currentButton = $this
                                        $border = $currentButton
                                        while ($border -and $border.GetType().Name -ne 'Border') {
                                            $border = [System.Windows.Media.VisualTreeHelper]::GetParent($border)
                                        }
                                        
                                        if ($border) {
                                            # Aktualisiere Kachelfarbe auf Lavender (heruntergeladen)
                                            $border.Background = [Windows.Media.Brushes]::Lavender
                                            $border.BorderBrush = [Windows.Media.Brushes]::SteelBlue
                                            
                                            # Aktualisiere Tooltip
                                            $border.ToolTip = "[HERUNTERGELADEN - BEREIT ZUR INSTALLATION] " + $toolInfo.Description
                                        }
                                        
                                        # Aktualisiere Button-Icon und Style
                                        $buttonContent = $currentButton.Content
                                        if ($buttonContent -and $buttonContent.GetType().Name -eq 'TextBlock') {
                                            $buttonContent.Text = [char]0xE8B5  # Install-Symbol
                                            $buttonContent.Foreground = [Windows.Media.Brushes]::Blue
                                        }
                                        $currentButton.ToolTip = "Von lokalem Download installieren"
                                        $currentButton.Background = [Windows.Media.Brushes]::LightCyan
                                        
                                        # Aktualisiere Button-Tag mit neuen Daten
                                        $newLocalPath = Get-ToolLocalInstallerPath -Tool $toolInfo
                                        $currentButton.Tag = @{
                                            Tool               = $toolInfo
                                            HasUpdate          = $hasUpdate
                                            IsInstalled        = $false
                                            IsDownloaded       = $true
                                            LocalInstallerPath = $newLocalPath
                                        }
                                        
                                        Write-Host "✓ UI erfolgreich aktualisiert - Kachel zeigt jetzt 'Heruntergeladen'-Status" -ForegroundColor Green
                                    } catch {
                                        Write-Host "⚠ UI-Aktualisierung fehlgeschlagen: $($_.Exception.Message)" -ForegroundColor Yellow
                                    }
                                }
                            }
                        } else {
                            # Nur Download verfügbar (kein Winget)
                            [System.Windows.Forms.MessageBox]::Show(
                                "Download von $($toolInfo.Name) wird gestartet...",
                                "Download - $($toolInfo.Name)",
                                [System.Windows.Forms.MessageBoxButtons]::OK,
                                [System.Windows.Forms.MessageBoxIcon]::Information
                            )
                            
                            # Übergebe globale ProgressBar falls verfügbar
                            $downloadParams = @{ Tool = $toolInfo }
                            if ($global:progressBar) {
                                $downloadParams['ProgressBar'] = $global:progressBar
                            }
                            $downloadResult = Invoke-ToolDownload @downloadParams
                            
                            $dlgTitle = if ($downloadResult.Success) { "Download erfolgreich" } else { "Download" }
                            $dlgIcon = if ($downloadResult.Success) { [System.Windows.Forms.MessageBoxIcon]::Information } else { [System.Windows.Forms.MessageBoxIcon]::Warning }
                            [System.Windows.Forms.MessageBox]::Show(
                                $downloadResult.Message,
                                $dlgTitle,
                                [System.Windows.Forms.MessageBoxButtons]::OK,
                                $dlgIcon
                            )
                            
                            # Bei erfolgreichem Download: Button und Kachel visuell aktualisieren
                            if ($downloadResult.Success) {
                                try {
                                    # Finde die Border (Kachel) dieses Buttons
                                    $currentButton = $this
                                    $border = $currentButton
                                    while ($border -and $border.GetType().Name -ne 'Border') {
                                        $border = [System.Windows.Media.VisualTreeHelper]::GetParent($border)
                                    }
                                    
                                    if ($border) {
                                        # Aktualisiere Kachelfarbe auf Lavender (heruntergeladen)
                                        $border.Background = [Windows.Media.Brushes]::Lavender
                                        $border.BorderBrush = [Windows.Media.Brushes]::SteelBlue
                                        
                                        # Aktualisiere Tooltip
                                        $border.ToolTip = "[HERUNTERGELADEN - BEREIT ZUR INSTALLATION] " + $toolInfo.Description
                                    }
                                    
                                    # Aktualisiere Button-Icon und Style
                                    $buttonContent = $currentButton.Content
                                    if ($buttonContent -and $buttonContent.GetType().Name -eq 'TextBlock') {
                                        $buttonContent.Text = [char]0xE8B5  # Install-Symbol
                                        $buttonContent.Foreground = [Windows.Media.Brushes]::Blue
                                    }
                                    $currentButton.ToolTip = "Von lokalem Download installieren"
                                    $currentButton.Background = [Windows.Media.Brushes]::LightCyan
                                    
                                    # Aktualisiere Button-Tag mit neuen Daten
                                    $newLocalPath = Get-ToolLocalInstallerPath -Tool $toolInfo
                                    $currentButton.Tag = @{
                                        Tool               = $toolInfo
                                        HasUpdate          = $hasUpdate
                                        IsInstalled        = $false
                                        IsDownloaded       = $true
                                        LocalInstallerPath = $newLocalPath
                                    }
                                    
                                    Write-Host "✓ UI erfolgreich aktualisiert - Kachel zeigt jetzt 'Heruntergeladen'-Status" -ForegroundColor Green
                                } catch {
                                    Write-Host "⚠ UI-Aktualisierung fehlgeschlagen: $($_.Exception.Message)" -ForegroundColor Yellow
                                }
                            }
                        }
                    }
                    # ===== Installiert, kein Update → Neu installieren/reparieren =====
                    elseif ($isInstalled -and -not $hasUpdate) {
                        $result = [System.Windows.Forms.MessageBox]::Show(
                            "Möchten Sie $($toolInfo.Name) neu installieren/reparieren?",
                            "Neuinstallation",
                            [System.Windows.Forms.MessageBoxButtons]::YesNo,
                            [System.Windows.Forms.MessageBoxIcon]::Question
                        )
                        if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
                            $processName = $toolInfo.Name -replace '\s+', ''
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
                            
                            $wingetResult = Invoke-WingetWithLiveOutput `
                                -Arguments @('install', '--id', $toolInfo.Winget, '--force', '--silent', '--accept-source-agreements', '--accept-package-agreements', '--disable-interactivity') `
                                -ToolName $toolInfo.Name `
                                -OperationLabel 'Neuinstallation' `
                                -ProgressBar $global:progressBar `
                                -StartProgress 70 `
                                -EndProgress 95 `
                                -TimeoutSeconds 300

                            if ($wingetResult.Success) {
                                Update-ToolWorkflowProgress -ProgressBar $global:progressBar -StatusText "Neuinstallation erfolgreich: $($toolInfo.Name)" -ProgressValue 100 -TextColor ([System.Drawing.Color]::LightGreen)
                                [System.Windows.Forms.MessageBox]::Show(
                                    "$($toolInfo.Name) wurde erfolgreich neu installiert!",
                                    "Neuinstallation erfolgreich",
                                    [System.Windows.Forms.MessageBoxButtons]::OK,
                                    [System.Windows.Forms.MessageBoxIcon]::Information
                                )
                            } elseif ($wingetResult.TimedOut) {
                                Update-ToolWorkflowProgress -ProgressBar $global:progressBar -StatusText "Neuinstallation Timeout: $($toolInfo.Name)" -ProgressValue 0 -TextColor ([System.Drawing.Color]::Red)
                                [System.Windows.Forms.MessageBox]::Show(
                                    "Neuinstallation Timeout (>5 Min). Bitte manuell prüfen.",
                                    "Timeout",
                                    [System.Windows.Forms.MessageBoxButtons]::OK,
                                    [System.Windows.Forms.MessageBoxIcon]::Warning
                                )
                            } else {
                                Update-ToolWorkflowProgress -ProgressBar $global:progressBar -StatusText "Neuinstallation fehlgeschlagen: $($toolInfo.Name)" -ProgressValue 0 -TextColor ([System.Drawing.Color]::Red)
                                $errorDesc = Get-WingetErrorDescription -ErrorCode $wingetResult.ExitCode
                                [System.Windows.Forms.MessageBox]::Show(
                                    "Neuinstallation fehlgeschlagen!`n`nFehlercode: $($wingetResult.ExitCode)`n`n$errorDesc",
                                    "Fehler",
                                    [System.Windows.Forms.MessageBoxButtons]::OK,
                                    [System.Windows.Forms.MessageBoxIcon]::Warning
                                )
                            }
                        }
                    }
                    
                    # Cache aktualisieren
                    if (Get-Command -Name Update-ToolInstallationStatus -ErrorAction SilentlyContinue) {
                        Update-ToolInstallationStatus -Tool $toolInfo -IsInstalled $true
                    }
                } catch {
                    [System.Windows.Forms.MessageBox]::Show(
                        "Fehler beim Ausführen der Aktion: $($_.Exception.Message)",
                        "Fehler",
                        [System.Windows.Forms.MessageBoxButtons]::OK,
                        [System.Windows.Forms.MessageBoxIcon]::Error
                    )
                }
            })
        $buttonPanel.Children.Add($actionButton)
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
            } catch {
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

                # Geschützte Pflichtkomponenten dürfen nicht über die UI deinstalliert werden
                if ($toolInfo.Protected -eq $true) {
                    [System.Windows.Forms.MessageBox]::Show(
                        "'$($toolInfo.Name)' ist eine Pflichtkomponente des Systems und kann nicht über die Tool-Bibliothek deinstalliert werden.`n`nDieses Paket wird für das Hardware-Monitoring benötigt. Eine Deinstallation würde die GUI-Kernfunktionen beschädigen.",
                        "Deinstallation gesperrt",
                        [System.Windows.Forms.MessageBoxButtons]::OK,
                        [System.Windows.Forms.MessageBoxIcon]::Warning
                    ) | Out-Null
                    return
                }

                $result = [System.Windows.Forms.MessageBox]::Show(
                    "Möchten Sie $($toolInfo.Name) wirklich deinstallieren?",
                    "Deinstallation bestätigen",
                    [System.Windows.Forms.MessageBoxButtons]::YesNo,
                    [System.Windows.Forms.MessageBoxIcon]::Question
                )
                if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
                    try {
                        $wingetResult = Invoke-WingetWithLiveOutput `
                            -Arguments @('uninstall', '--id', $toolInfo.Winget, '--silent', '--disable-interactivity', '--accept-source-agreements') `
                            -ToolName $toolInfo.Name `
                            -OperationLabel 'Deinstallation' `
                            -ProgressBar $global:progressBar `
                            -StartProgress 65 `
                            -EndProgress 95 `
                            -TimeoutSeconds 300

                        if ($wingetResult.Success) {
                            Update-ToolWorkflowProgress -ProgressBar $global:progressBar -StatusText "Deinstallation erfolgreich: $($toolInfo.Name)" -ProgressValue 100 -TextColor ([System.Drawing.Color]::LightGreen)
                            [System.Windows.Forms.MessageBox]::Show(
                                "$($toolInfo.Name) wurde erfolgreich deinstalliert.",
                                "Deinstallation erfolgreich",
                                [System.Windows.Forms.MessageBoxButtons]::OK,
                                [System.Windows.Forms.MessageBoxIcon]::Information
                            )

                            # Cache aktualisieren, wenn die Funktion verfügbar ist
                            if (Get-Command -Name Update-ToolInstallationStatus -ErrorAction SilentlyContinue) {
                                Update-ToolInstallationStatus -Tool $toolInfo -IsInstalled $false
                            }
                        } elseif ($wingetResult.TimedOut) {
                            Update-ToolWorkflowProgress -ProgressBar $global:progressBar -StatusText "Deinstallation Timeout: $($toolInfo.Name)" -ProgressValue 0 -TextColor ([System.Drawing.Color]::Red)
                            [System.Windows.Forms.MessageBox]::Show(
                                "Deinstallation Timeout (>5 Min). Bitte manuell prüfen.",
                                "Timeout",
                                [System.Windows.Forms.MessageBoxButtons]::OK,
                                [System.Windows.Forms.MessageBoxIcon]::Warning
                            )
                        } else {
                            Update-ToolWorkflowProgress -ProgressBar $global:progressBar -StatusText "Deinstallation fehlgeschlagen: $($toolInfo.Name)" -ProgressValue 0 -TextColor ([System.Drawing.Color]::Red)
                            $errorDesc = Get-WingetErrorDescription -ErrorCode $wingetResult.ExitCode
                            [System.Windows.Forms.MessageBox]::Show(
                                "Deinstallation fehlgeschlagen!`n`nFehlercode: $($wingetResult.ExitCode)`n`n$errorDesc",
                                "Fehler",
                                [System.Windows.Forms.MessageBoxButtons]::OK,
                                [System.Windows.Forms.MessageBoxIcon]::Warning
                            )
                        }
                    } catch {
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
    } else {
        Get-ToolsByCategory -Category $Category
    }
    
    # Tools anzeigen und Rückgabewerte unterdrücken
    foreach ($tool in $filteredTools) {
        $null = Initialize-ToolEntry -TargetElement $WrapPanel -Tool $tool -TileSize $TileSize
    }
}

# Cache für verfügbare Updates (winget upgrade)
$script:availableUpdatesCache = $null
$script:availableUpdatesCacheTimestamp = $null

function Initialize-AvailableUpdatesCache {
    param(
        [switch]$ForceRefresh
    )

    # Cache 60 Sekunden wiederverwenden (außer ForceRefresh)
    if (-not $ForceRefresh -and $script:availableUpdatesCache -and $script:availableUpdatesCacheTimestamp) {
        $cacheAgeSeconds = ((Get-Date) - $script:availableUpdatesCacheTimestamp).TotalSeconds
        if ($cacheAgeSeconds -lt 60) {
            return $script:availableUpdatesCache
        }
    }

    $cache = @{}

    try {
        $upgradeOutput = winget upgrade --accept-source-agreements --disable-interactivity 2>$null | Out-String
        if ([string]::IsNullOrWhiteSpace($upgradeOutput)) {
            $script:availableUpdatesCache = $cache
            $script:availableUpdatesCacheTimestamp = Get-Date
            return $cache
        }

        $lines = $upgradeOutput -split "`r?`n"
        $toolIds = @(Get-AllTools | Where-Object { $_.Winget } | ForEach-Object { $_.Winget } | Sort-Object -Unique)

        foreach ($wingetId in $toolIds) {
            if ([string]::IsNullOrWhiteSpace($wingetId)) { continue }

            $idPattern = [regex]::Escape($wingetId)
            $matchingLine = $lines | Where-Object { $_ -match "(^|\s)$idPattern(\s|$)" } | Select-Object -First 1
            if (-not $matchingLine) { continue }

            # Tabellenzeile robust parsen: Name | ID | Installiert | Verfügbar | Quelle
            $linePattern = "^\s*(?<name>.*?)\s{2,}(?<id>$idPattern)\s{2,}(?<installed>\S+)\s{2,}(?<available>\S+)(?:\s{2,}(?<source>\S+))?\s*$"
            $installedVersion = $null
            $availableVersion = $null

            if ($matchingLine -match $linePattern) {
                $installedVersion = $matches['installed']
                $availableVersion = $matches['available']
            }

            $cache[$wingetId.ToLower()] = @{
                HasUpdate        = $true
                InstalledVersion = $installedVersion
                AvailableVersion = $availableVersion
                RawLine          = $matchingLine
            }
        }
    } catch {
        Write-Verbose "Initialize-AvailableUpdatesCache: Fehler beim Laden der Updates: $_"
    }

    $script:availableUpdatesCache = $cache
    $script:availableUpdatesCacheTimestamp = Get-Date
    return $cache
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
            HasUpdate        = $false
        }
    }
    
    $job = $null
    try {
        $wingetIdLower = $Tool.Winget.ToLower()

        # 1) Zentrale Update-Liste bevorzugen (zuverlässiger/schneller)
        $updatesCache = Initialize-AvailableUpdatesCache
        if ($updatesCache -and $updatesCache.ContainsKey($wingetIdLower)) {
            $cachedUpdate = $updatesCache[$wingetIdLower]
            return @{
                InstalledVersion = $cachedUpdate.InstalledVersion
                AvailableVersion = $cachedUpdate.AvailableVersion
                HasUpdate        = $true
            }
        }

        # 2) Kein Update in Cache: installierte Version gezielt prüfen
        # Verwende winget list mit upgrade check
        $job = Start-Job -ScriptBlock {
            param($wingetId)
            
            # Hole installierte Version (Update kommt primär aus Cache)
            $listOutput = winget list --id $wingetId --exact 2>$null | Out-String
            
            return @{
                List    = $listOutput
                Upgrade = $null
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
            
            return @{
                InstalledVersion = $installedVersion
                AvailableVersion = $availableVersion
                HasUpdate        = $hasUpdate
            }
        } else {
            Stop-Job -Job $job -ErrorAction SilentlyContinue
            Write-Verbose "Timeout beim Abrufen der Versionsinfo für $($Tool.Name)"
        }
    } catch {
        Write-Verbose "Fehler beim Abrufen der Versionsinfo für $($Tool.Name): $_"
    } finally {
        if ($null -ne $job) {
            Remove-Job -Job $job -Force -ErrorAction SilentlyContinue
        }
    }
    
    return @{
        InstalledVersion = $null
        AvailableVersion = $null
        HasUpdate        = $false
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
        } else {
            # Timeout - Job stoppen
            Stop-Job -Job $job -ErrorAction SilentlyContinue
            Write-Warning "Timeout beim Prüfen von $($Tool.Name) (>8s)"
        }
    } catch {
        Write-Verbose "Fehler beim Prüfen des installierten Status für $($Tool.Name): $_"
    } finally {
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

    # Zentrale Update-Liste verwenden (spracheunabhängig, ohne Einzel-Timeouts)
    try {
        $updatesCache = Initialize-AvailableUpdatesCache
        if ($updatesCache -and $updatesCache.ContainsKey($Tool.Winget.ToLower())) {
            return $true
        }
    } catch {
        Write-Verbose "Fehler beim Prüfen von Updates für $($Tool.Name): $_"
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
        [bool]$ShowOnlyUpdates = $false,

        [Parameter(Mandatory = $false)]
        [string]$PostStatusText = "Bereit",

        [Parameter(Mandatory = $false)]
        [System.Drawing.Color]$PostStatusColor = [System.Drawing.Color]::White
    )
    
    # Laufenden Display-Timer stoppen (verhindert Race Condition bei schneller Eingabe)
    if ($script:activeDisplayTimer -and $script:activeDisplayTimer.IsEnabled) {
        $script:activeDisplayTimer.Stop()
        $script:activeDisplayTimer = $null
    }

    # Bestehenden Content löschen
    $WrapPanel.Children.Clear()
    
    # Wenn keine Kategorie gewählt wurde (leerer String), nichts anzeigen
    if ([string]::IsNullOrWhiteSpace($Category)) {
        Write-Verbose "Keine Kategorie gewählt - zeige keine Tools an"
        return 0
    }
    
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

    # Update-Cache einmalig vorab laden (verhindert fehlende Treffer durch Einzel-Timeouts)
    $null = Initialize-AvailableUpdatesCache -ForceRefresh:$ForceRefresh
    
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
    } else {
        # Haupt-ProgressBar initialisieren
        # Prüfen, ob es sich um eine TextProgressBar handelt (mit den erweiterten Eigenschaften)
        if ($MainProgressBar.GetType().Name -eq "TextProgressBar") {
            $MainProgressBar.Value = 0
            $MainProgressBar.CustomText = "Lade Tool-Informationen..."
            $MainProgressBar.TextColor = [System.Drawing.Color]::White
        } else {
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
            } else {
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
    } else {
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
        } else {
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
        } elseif (-not [string]::IsNullOrWhiteSpace($SearchQuery)) {
            $noToolsMessage.Text = "Keine Tools für Suchbegriff '$SearchQuery' gefunden."
        } else {
            $noToolsMessage.Text = "Keine Tools in der Kategorie '$Category' gefunden."
        }
        $noToolsMessage.FontSize = 16
        $noToolsMessage.FontWeight = [Windows.FontWeights]::Bold
        $noToolsMessage.HorizontalAlignment = [Windows.HorizontalAlignment]::Center
        $noToolsMessage.VerticalAlignment = [Windows.VerticalAlignment]::Center
        $noToolsMessage.Margin = New-Object Windows.Thickness(10)
        $WrapPanel.Children.Add($noToolsMessage)
        
        # Bei 0 Ergebnissen ProgressBar sofort mit dem Post-Status beschriften (kein Timer)
        if ($MainProgressBar -and $MainProgressBar.GetType().Name -eq "TextProgressBar") {
            $MainProgressBar.Value = 0
            $MainProgressBar.CustomText = $PostStatusText
            $MainProgressBar.TextColor = $PostStatusColor
        }
        
        return $totalTools
    }
    $processedTools = 0
    
    # Timer starten, um asynchron die Tools zu laden und den Fortschritt anzuzeigen
    $timer = New-Object Windows.Threading.DispatcherTimer
    $timer.Interval = [TimeSpan]::FromMilliseconds(100)
    $script:activeDisplayTimer = $timer  # Referenz merken damit nächster Aufruf diesen stoppen kann
    $timer.Tag = @{
        "WrapPanel"       = $WrapPanel
        "ProgressBorder"  = $progressBorder
        "MainProgressBar" = $MainProgressBar
        "FilteredTools"   = $filteredTools
        "TotalTools"      = $totalTools
        "ProcessedTools"  = $processedTools
        "UseCache"        = $useCachedTools
        "TileSize"        = $TileSize
        "ShowOnlyUpdates" = $ShowOnlyUpdates
        "PostStatusText"  = $PostStatusText
        "PostStatusColor" = $PostStatusColor
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
            $PostStatusText = $this.Tag.PostStatusText
            $PostStatusColor = $this.Tag.PostStatusColor
        
            # Abbruchbedingung: Alle Tools verarbeitet
            if ($processedTools -ge $totalTools) {
                # Timer stoppen
                $this.Stop()
                $script:activeDisplayTimer = $null
            
                # Progress-Anzeige entfernen wenn interne genutzt wird
                if (-not $MainProgressBar) {
                    $WrapPanel.Children.Remove($progressBorder)
                } else {
                    # Haupt-ProgressBar zurücksetzen - mit Typ-Check
                    if ($MainProgressBar.GetType().Name -eq "TextProgressBar") {
                        $MainProgressBar.Value = 100
                        $MainProgressBar.CustomText = if ($useCache) { "Tool-Informationen aus Cache geladen" } else { "Tool-Informationen geladen" }
                    
                        # Nach kurzer Pause auf den Post-Status setzen
                        $resetTimer = New-Object System.Windows.Forms.Timer
                        $resetTimer.Interval = 1000
                        $resetTimer.Tag = @{ Bar = $MainProgressBar; Text = $PostStatusText; Color = $PostStatusColor }
                        $resetTimer.Add_Tick({
                                $bar = $this.Tag.Bar
                                if ($bar.GetType().Name -eq "TextProgressBar") {
                                    $bar.Value = 0
                                    # Globale Overrides haben Vorrang (werden von Aufrufer nach dem Aufruf gesetzt)
                                    $finalText = if ($global:progressBarPostText) { $global:progressBarPostText }  else { $this.Tag.Text }
                                    $finalColor = if ($global:progressBarPostColor) { $global:progressBarPostColor } else { $this.Tag.Color }
                                    $global:progressBarPostText = $null
                                    $global:progressBarPostColor = $null
                                    $bar.CustomText = $finalText
                                    $bar.TextColor = $finalColor
                                } else {
                                    $bar.Value = 0
                                }
                                $this.Stop()
                            })
                        $resetTimer.Start()
                    } else {
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
                } else {
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
                    } else {
                        Write-Warning "Update-ToolsDisplay: NULL-Tool an Index $processedTools gefunden"
                    }
                }
            } catch {
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
Export-ModuleMember -Function Get-AllTools, Get-ToolsByCategory, Get-ToolsByTag, Get-ToolByName, Install-ToolPackage, Get-ToolDownload, Flatten, Update-ToolProgress, Set-ToolResource, Initialize-ToolEntry, Show-ToolTileList, Test-ToolInstalled, Test-ToolUpdateAvailable, Get-ToolVersionInfo, Update-ToolsDisplay, Stop-ToolProcess, Get-WingetErrorDescription, Show-ToolAcquisitionDialog, Test-ToolDownloaded, Get-ToolLocalInstallerPath, Invoke-ToolDownload, Install-ToolFromLocal

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

# Zentrale Farbschemata für die GUI
# Definiert alle verwendeten Farben an einem zentralen Ort

# Farbschemata für Light und Dark Mode
$colors = @{
    LightMode = @{
        Background = [System.Drawing.Color]::Gainsboro  # Heller grau
        Text = [System.Drawing.Color]::Black
        Panel = [System.Drawing.Color]::WhiteSmoke
        Accent = [System.Drawing.Color]::SteelBlue
        OutputBoxBackground = [System.Drawing.Color]::White
        OutputBoxText = [System.Drawing.Color]::Black
        ButtonBackground = [System.Drawing.Color]::White
        ButtonBorder = [System.Drawing.Color]::LightGray
        GroupBoxText = [System.Drawing.Color]::Black
    }
    DarkMode = @{
        Background = [System.Drawing.Color]::DarkSlateGray
        Text = [System.Drawing.Color]::LightGray
        Panel = [System.Drawing.Color]::DimGray
        Accent = [System.Drawing.Color]::SteelBlue
        OutputBoxBackground = [System.Drawing.Color]::Black
        OutputBoxText = [System.Drawing.Color]::Silver
        ButtonBackground = [System.Drawing.Color]::DarkSlateGray
        ButtonBorder = [System.Drawing.Color]::SlateGray
        GroupBoxText = [System.Drawing.Color]::LightSteelBlue
    }
    Hardware = @{
        MonitorPanel = @{
            Light = [System.Drawing.Color]::WhiteSmoke
            Dark = [System.Drawing.Color]::Black  # Schwarz für das Monitor-Panel im Dark Mode
        }
        CPU = @{
            Light = [System.Drawing.Color]::Green  # Standardgrün für CPU im normalen Zustand
            Warning = [System.Drawing.Color]::Gold  # Gelb für Warnung
            Critical = [System.Drawing.Color]::Red  # Rot für kritischen Zustand
            Dark = [System.Drawing.Color]::DarkSlateGray
            TitleLight = [System.Drawing.Color]::LightGreen
            TitleDark = [System.Drawing.Color]::DarkSlateGray
        }
        GPU = @{
            Light = [System.Drawing.Color]::Green  # Standardgrün für GPU im normalen Zustand
            Warning = [System.Drawing.Color]::Gold  # Gelb für Warnung
            Critical = [System.Drawing.Color]::Red  # Rot für kritischen Zustand
            Dark = [System.Drawing.Color]::DarkSlateGray
            TitleLight = [System.Drawing.Color]::LightGreen
            TitleDark = [System.Drawing.Color]::DarkSlateGray
        }
        RAM = @{
            Light = [System.Drawing.Color]::Green  # Standardgrün für RAM im normalen Zustand
            Warning = [System.Drawing.Color]::Gold  # Gelb für Warnung
            Critical = [System.Drawing.Color]::Red  # Rot für kritischen Zustand
            Dark = [System.Drawing.Color]::DarkSlateGray
            TitleLight = [System.Drawing.Color]::LightGreen
            TitleDark = [System.Drawing.Color]::DarkSlateGray
        }
    }
    Tabs = @{
        Light = @{
            Main = [System.Drawing.Color]::Gainsboro
            Output = [System.Drawing.Color]::WhiteSmoke
            System = [System.Drawing.Color]::WhiteSmoke
            Disk = [System.Drawing.Color]::WhiteSmoke
            Network = [System.Drawing.Color]::WhiteSmoke
            Cleanup = [System.Drawing.Color]::WhiteSmoke
            Hardware = [System.Drawing.Color]::WhiteSmoke
            Advanced = [System.Drawing.Color]::WhiteSmoke
            Extensions = [System.Drawing.Color]::WhiteSmoke
        }
        Dark = @{
            Main = [System.Drawing.Color]::Black
            Output = [System.Drawing.Color]::DarkSlateGray
            System = [System.Drawing.Color]::DarkSlateGray
            Disk = [System.Drawing.Color]::DarkSlateGray
            Network = [System.Drawing.Color]::DarkSlateGray
            Cleanup = [System.Drawing.Color]::DarkSlateGray
            Hardware = [System.Drawing.Color]::DarkSlateGray
            Advanced = [System.Drawing.Color]::DarkSlateGray
            Extensions = [System.Drawing.Color]::DarkSlateGray
        }
    }
}

# Funktion zum Anwenden des ausgewählten Farbschemas
function Set-ColorScheme {
    param (
        [bool]$IsDarkMode,
        [System.Windows.Forms.Form]$MainForm,
        [System.Windows.Forms.Label]$Header,
        [System.Windows.Forms.RichTextBox]$OutputBox,
        [System.Windows.Forms.Button]$ThemeButton,
        [hashtable]$UIElements = @{}
    )
    
    # Das aktuelle Farbschema basierend auf dem Modus auswählen
    $scheme = if ($IsDarkMode) { $colors.DarkMode } else { $colors.LightMode }
    $buttonScheme = if ($IsDarkMode) { $colors.Tabs.Dark } else { $colors.Tabs.Light }
    
    # Hauptformular
    if ($MainForm) {
        $MainForm.BackColor = $scheme.Background
    }
    
    if ($Header) {
        $Header.ForeColor = $scheme.Text
    }
    
    # Ausgabe-Bereich
    if ($OutputBox) {
        $OutputBox.BackColor = $scheme.OutputBoxBackground
        $OutputBox.ForeColor = $scheme.OutputBoxText
    }
    
    # Theme-Button - mit Prüfung, ob er vorhanden ist
    if ($ThemeButton -and ($ThemeButton -is [System.Windows.Forms.Button])) {
        $ThemeButton.BackColor = $scheme.ButtonBackground
        if ($ThemeButton.FlatAppearance) {
            $ThemeButton.FlatAppearance.BorderColor = $scheme.ButtonBorder
        }
        $ThemeButton.ForeColor = $scheme.Text
    }
    
    # Button-Panel Styling
    if ($UIElements.ContainsKey("buttonPanel") -and $UIElements["buttonPanel"]) {
        $UIElements["buttonPanel"].BackColor = $buttonScheme.Main
    }
    
    # Navigation Buttons
    if ($UIElements.ContainsKey("btnOutput") -and $UIElements["btnOutput"]) {
        $UIElements["btnOutput"].BackColor = $buttonScheme.Output
        $UIElements["btnOutput"].ForeColor = $scheme.ButtonText
    }
    if ($UIElements.ContainsKey("btnStatusInfo") -and $UIElements["btnStatusInfo"]) {
        $UIElements["btnStatusInfo"].BackColor = $buttonScheme.Advanced
        $UIElements["btnStatusInfo"].ForeColor = $scheme.ButtonText
    }
    if ($UIElements.ContainsKey("btnHardwareInfo") -and $UIElements["btnHardwareInfo"]) {
        $UIElements["btnHardwareInfo"].BackColor = $buttonScheme.Extensions
        $UIElements["btnHardwareInfo"].ForeColor = $scheme.ButtonText
    }
    if ($UIElements.ContainsKey("btnToolInfo") -and $UIElements["btnToolInfo"]) {
        $UIElements["btnToolInfo"].BackColor = $buttonScheme.System
        $UIElements["btnToolInfo"].ForeColor = $scheme.ButtonText
    }
    if ($UIElements.ContainsKey("btnDownloads") -and $UIElements["btnDownloads"]) {
        $UIElements["btnDownloads"].BackColor = $buttonScheme.Disk
        $UIElements["btnDownloads"].ForeColor = $scheme.ButtonText
    }
    
    # Content Panels
    if ($UIElements.ContainsKey("outputViewPanel") -and $UIElements["outputViewPanel"]) {
        $UIElements["outputViewPanel"].BackColor = $buttonScheme.Output
    }
    if ($UIElements.ContainsKey("statusViewPanel") -and $UIElements["statusViewPanel"]) {
        $UIElements["statusViewPanel"].BackColor = $buttonScheme.Advanced
    }
    if ($UIElements.ContainsKey("hardwareViewPanel") -and $UIElements["hardwareViewPanel"]) {
        $UIElements["hardwareViewPanel"].BackColor = $buttonScheme.Extensions
    }
    if ($UIElements.ContainsKey("toolViewPanel") -and $UIElements["toolViewPanel"]) {
        $UIElements["toolViewPanel"].BackColor = $buttonScheme.System
    }
    if ($UIElements.ContainsKey("downloadsViewPanel") -and $UIElements["downloadsViewPanel"]) {
        $UIElements["downloadsViewPanel"].BackColor = $buttonScheme.Disk
    }
    # Keine Tab-Elemente mehr vorhanden
    
    # GroupBoxes aktualisieren, wenn sie existieren
    foreach ($key in $UIElements.Keys) {
        if ($key -like "gb*" -and $UIElements[$key]) {
            try {
                $UIElements[$key].ForeColor = $scheme.GroupBoxText
            } catch {
                Write-Host "Warnung: Konnte ForeColor für $key nicht setzen" -ForegroundColor Yellow
            }
        }
    }
    
    # Explizit die wichtigsten GroupBoxes mit der gleichen Farbe setzen
    # Explizit GroupBox für das Informationspanel aktualisieren
    if ($UIElements.ContainsKey("gbInfoPanel") -and $UIElements["gbInfoPanel"]) {
        try {
            $UIElements["gbInfoPanel"].ForeColor = $scheme.GroupBoxText
        } catch {
            Write-Host "Warnung: Konnte ForeColor für gbInfoPanel nicht explizit setzen" -ForegroundColor Yellow
        }
    }
    
    # Hardware-Monitor aktualisieren
    if ($UIElements.ContainsKey("MonitorBackgroundPanel") -and $UIElements["MonitorBackgroundPanel"]) {
        try {
            $hwScheme = if ($IsDarkMode) { "Dark" } else { "Light" }
            $UIElements["MonitorBackgroundPanel"].BackColor = $colors.Hardware.MonitorPanel.$hwScheme
        } catch {
            Write-Host "Warnung: Konnte BackColor für MonitorBackgroundPanel nicht setzen" -ForegroundColor Yellow
        }
    }
    
    # CPU, GPU und RAM Panels aktualisieren
    if ($UIElements.ContainsKey("gbCPU") -and $UIElements["gbCPU"]) {
        try {
            $UIElements["gbCPU"].BackColor = if ($IsDarkMode) { $colors.Hardware.CPU.Dark } else { $colors.Hardware.CPU.Light }
        } catch {
            Write-Host "Warnung: Konnte BackColor für gbCPU nicht setzen" -ForegroundColor Yellow
        }
    }
    
    if ($UIElements.ContainsKey("gbGPU") -and $UIElements["gbGPU"]) {
        try {
            $UIElements["gbGPU"].BackColor = if ($IsDarkMode) { $colors.Hardware.GPU.Dark } else { $colors.Hardware.GPU.Light }
        } catch {
            Write-Host "Warnung: Konnte BackColor für gbGPU nicht setzen" -ForegroundColor Yellow
        }
    }
    
    if ($UIElements.ContainsKey("gbRAM") -and $UIElements["gbRAM"]) {
        try {
            $UIElements["gbRAM"].BackColor = if ($IsDarkMode) { $colors.Hardware.RAM.Dark } else { $colors.Hardware.RAM.Light }
        } catch {
            Write-Host "Warnung: Konnte BackColor für gbRAM nicht setzen" -ForegroundColor Yellow
        }
    }
    
    # Hardware-Titel aktualisieren
    if ($UIElements.ContainsKey("lblCPUTitle") -and $UIElements["lblCPUTitle"]) {
        try {
            $UIElements["lblCPUTitle"].BackColor = if ($IsDarkMode) { $colors.Hardware.CPU.TitleDark } else { $colors.Hardware.CPU.TitleLight }
            $UIElements["lblCPUTitle"].ForeColor = $scheme.Text
        } catch {
            Write-Host "Warnung: Konnte Farben für lblCPUTitle nicht setzen" -ForegroundColor Yellow
        }
    }
    
    if ($UIElements.ContainsKey("lblGPUTitle") -and $UIElements["lblGPUTitle"]) {
        try {
            $UIElements["lblGPUTitle"].BackColor = if ($IsDarkMode) { $colors.Hardware.GPU.TitleDark } else { $colors.Hardware.GPU.TitleLight }
            $UIElements["lblGPUTitle"].ForeColor = $scheme.Text
        } catch {
            Write-Host "Warnung: Konnte Farben für lblGPUTitle nicht setzen" -ForegroundColor Yellow
        }
    }
    
    if ($UIElements.ContainsKey("lblRAMTitle") -and $UIElements["lblRAMTitle"]) {
        try {
            $UIElements["lblRAMTitle"].BackColor = if ($IsDarkMode) { $colors.Hardware.RAM.TitleDark } else { $colors.Hardware.RAM.TitleLight }
            $UIElements["lblRAMTitle"].ForeColor = $scheme.Text
        } catch {
            Write-Host "Warnung: Konnte Farben für lblRAMTitle nicht setzen" -ForegroundColor Yellow
        }
    }
    
    # Hardware-Labels aktualisieren
    if ($UIElements.ContainsKey("cpuLabel") -and $UIElements["cpuLabel"]) { 
        try {
            $UIElements["cpuLabel"].ForeColor = $scheme.Text 
        } catch {
            Write-Host "Warnung: Konnte ForeColor für cpuLabel nicht setzen" -ForegroundColor Yellow
        }
    }
    if ($UIElements.ContainsKey("gpuLabel") -and $UIElements["gpuLabel"]) { 
        try {
            $UIElements["gpuLabel"].ForeColor = $scheme.Text 
        } catch {
            Write-Host "Warnung: Konnte ForeColor für gpuLabel nicht setzen" -ForegroundColor Yellow
        }
    }
    if ($UIElements.ContainsKey("ramLabel") -and $UIElements["ramLabel"]) { 
        try {
            $UIElements["ramLabel"].ForeColor = $scheme.Text 
        } catch {
            Write-Host "Warnung: Konnte ForeColor für ramLabel nicht setzen" -ForegroundColor Yellow
        }
    }
    
    return $IsDarkMode
}

# Diese Funktion und die Farb-Hashtable exportieren, damit sie von anderen Modulen verwendet werden kann
Export-ModuleMember -Function Set-ColorScheme
Export-ModuleMember -Variable colors

# Import necessary .NET assemblies
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName PresentationCore, PresentationFramework

# Import ProgressBarTools Modul
Import-Module "$PSScriptRoot\ProgressBarTools.psm1" -Force

# Setze die Konsolencodierung auf UTF-8-BOM für korrekte Unicode-Darstellung
$OutputEncoding = [System.Text.UTF8Encoding]::new($true)
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($true)
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8BOM'
$PSDefaultParameterValues['*:Encoding'] = 'utf8BOM'
chcp 65001 | Out-Null

# ===== SYMBOL HELPER FUNKTIONEN =====
# Definition der einheitlichen Symbole für konsistente Ausgabe
$Script:SuccessSymbol = '[√]'      # Erfolg, Grün (#00AA00)
$Script:ErrorSymbol = '[X]'        # Fehler, Rot (#CC0000)
$Script:WarningSymbol = '[!]'      # Warnung, Orange (#FF8800)
$Script:InfoSymbol = '[►]'         # Information, Blau (#0066CC)
$Script:ProcessSymbol = '[>]'      # Prozess/Fortschritt, Cyan (#00AACC)
$Script:StartSymbol = '[+]'        # Start einer Operation, Grün

# Definition der Farben für RichTextBox
$Script:SuccessColor = [System.Drawing.Color]::FromArgb(0, 170, 0)    # Grün (#00AA00)
$Script:ErrorColor = [System.Drawing.Color]::FromArgb(204, 0, 0)      # Rot (#CC0000)
$Script:WarningColor = [System.Drawing.Color]::FromArgb(255, 136, 0)  # Orange (#FF8800)
$Script:InfoColor = [System.Drawing.Color]::FromArgb(0, 102, 204)     # Blau (#0066CC)
$Script:ProcessColor = [System.Drawing.Color]::FromArgb(0, 170, 204)  # Cyan (#00AACC)
$Script:StartColor = [System.Drawing.Color]::FromArgb(0, 170, 0)      # Grün (#00AA00)

# Definition der Farben für Konsole (PowerShell)
$Script:SuccessColorConsole = 'Green'     # ähnlich zu #00AA00
$Script:ErrorColorConsole = 'Red'         # ähnlich zu #CC0000
$Script:WarningColorConsole = 'Yellow'    # Gelb (ähnlich zu #FF8800)
$Script:InfoColorConsole = 'Blue'         # ähnlich zu #0066CC
$Script:ProcessColorConsole = 'Cyan'      # ähnlich zu #00AACC
$Script:StartColorConsole = 'Green'       # ähnlich zu #00AA00

# Hilfsfunktion für konsistente Symbol-Ausgabe in Konsole und OutputBox
function Write-ConsoleAndOutputBox {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [Parameter(Mandatory=$true)]
        [ValidateSet('Success', 'Error', 'Warning', 'Info', 'Process', 'Start')]
        [string]$Type,
        
        [System.Windows.Forms.RichTextBox]$OutputBox = $null,
        
        [string]$ToolName = "System",
        
        [switch]$NoNewLine,
        
        [switch]$NoTimestamp,
        
        [switch]$SaveToDatabase
    )
      # Symbol und Farben anhand des Typs auswählen
    $symbol = switch ($Type) {
        'Success' { $Script:SuccessSymbol }
        'Error'   { $Script:ErrorSymbol }
        'Warning' { $Script:WarningSymbol }
        'Info'    { $Script:InfoSymbol }
        'Process' { $Script:ProcessSymbol }
        'Start'   { $Script:StartSymbol }
    }
    
    $consoleColor = switch ($Type) {
        'Success' { $Script:SuccessColorConsole }
        'Error'   { $Script:ErrorColorConsole }
        'Warning' { $Script:WarningColorConsole }
        'Info'    { $Script:InfoColorConsole }
        'Process' { $Script:ProcessColorConsole }
        'Start'   { $Script:StartColorConsole }
    }
    
    $boxColor = switch ($Type) {
        'Success' { $Script:SuccessColor }
        'Error'   { $Script:ErrorColor }
        'Warning' { $Script:WarningColor }
        'Info'    { $Script:InfoColor }
        'Process' { $Script:ProcessColor }
        'Start'   { $Script:StartColor }
    }
    
    $messageWithSymbol = "$symbol $Message"
    
    # Konsolen-Ausgabe
    if ($NoNewLine) {
        Write-Host $messageWithSymbol -NoNewline -ForegroundColor $consoleColor
    } else {
        Write-Host $messageWithSymbol -ForegroundColor $consoleColor
    }
      # OutputBox-Ausgabe (falls vorhanden)
    if ($OutputBox) {
        $logLevel = switch ($Type) {
            'Success' { 'Success' }
            'Error'   { 'Error' }
            'Warning' { 'Warning' }
            'Info'    { 'Information' }
            'Process' { 'Information' }
            'Start'   { 'Information' }
        }
        
        Write-ToolLog -ToolName $ToolName -Message $messageWithSymbol -OutputBox $OutputBox -Color $boxColor -Level $logLevel -NoTimestamp:$NoTimestamp -SaveToDatabase:$SaveToDatabase
    }
}

# Funktion zum Abrufen des Symbols
function Get-Symbol {
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet('Success', 'Error', 'Warning', 'Info', 'Process', 'Start')]
        [string]$Type
    )
    
    switch ($Type) {
        'Success' { return $Script:SuccessSymbol }
        'Error'   { return $Script:ErrorSymbol }
        'Warning' { return $Script:WarningSymbol }
        'Info'    { return $Script:InfoSymbol }
        'Process' { return $Script:ProcessSymbol }
        'Start'   { return $Script:StartSymbol }
    }
}

# Funktion zum Abrufen der RichTextBox-Farbe
function Get-SymbolColor {
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet('Success', 'Error', 'Warning', 'Info', 'Process', 'Start')]
        [string]$Type
    )
    
    switch ($Type) {
        'Success' { return $Script:SuccessColor }
        'Error'   { return $Script:ErrorColor }
        'Warning' { return $Script:WarningColor }
        'Info'    { return $Script:InfoColor }
        'Process' { return $Script:ProcessColor }
        'Start'   { return $Script:StartColor }
    }
}

# Funktion zum Abrufen der Konsolenfarbe
function Get-SymbolConsoleColor {
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet('Success', 'Error', 'Warning', 'Info', 'Process', 'Start')]
        [string]$Type
    )
    
    switch ($Type) {
        'Success' { return $Script:SuccessColorConsole }
        'Error'   { return $Script:ErrorColorConsole }
        'Warning' { return $Script:WarningColorConsole }
        'Info'    { return $Script:InfoColorConsole }
        'Process' { return $Script:ProcessColorConsole }
        'Start'   { return $Script:StartColorConsole }
    }
}

# ===== ENDE SYMBOL HELPER FUNKTIONEN =====

# Erweiterte Version von Write-ColoredCenteredText (zentral)
function Write-ColoredCenteredText {
    param(
        [string]$text,
        [string]$frameColor = "Green",
        [string]$textColor = "Red",
        [int]$totalWidth = 80,
        [int]$contentWidth = 78  # Breite innerhalb der Rahmenzeichen (║)
    )
    $textLength = $text.Length
    $totalSpaces = $contentWidth - $textLength
    $leftSpaces = [math]::Floor($totalSpaces / 2)
    $rightSpaces = $totalSpaces - $leftSpaces
    Write-Host "║" -NoNewline -ForegroundColor $frameColor
    Write-Host (" " * $leftSpaces) -NoNewline
    Write-Host $text -NoNewline -ForegroundColor $textColor
    Write-Host (" " * $rightSpaces) -NoNewline
    Write-Host "║" -ForegroundColor $frameColor
}

# Zentrale Hilfsfunktion Write-WrappedText
function Write-WrappedText {
    param(
        [string]$text,
        [int]$maxWidth = 100,
        [string]$foregroundColor = "White"
    )
    $words = $text -split '\s+'
    $currentLine = ""
    foreach ($word in $words) {
        if (($currentLine.Length + $word.Length + 1) -le $maxWidth) {
            if ($currentLine.Length -gt 0) {
                $currentLine += " "
            }
            $currentLine += $word
        }
        else {
            Write-Host $currentLine -ForegroundColor $foregroundColor
            $currentLine = $word
        }
    }
    if ($currentLine.Length -gt 0) {
        Write-Host $currentLine -ForegroundColor $foregroundColor
    }
}

# Function to check if the script is running as Administrator
function Test-IsAdmin {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Set output encoding
function Initialize-Encoding {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    $OutputEncoding = [System.Text.Encoding]::UTF8
}

# Function to show a custom message box with OK and Cancel buttons
function Show-CustomMessageBox {
    param (
        [string]$message,
        [string]$title,
        [int]$fontSize = 20
    )

    # Create the main window
    $msgBoxWindow = New-Object System.Windows.Window
    $msgBoxWindow.Title = $title
    $msgBoxWindow.Width = 400
    $msgBoxWindow.Height = 300
    $msgBoxWindow.WindowStartupLocation = 'CenterScreen'

    # Create a StackPanel for layout
    $stackPanel = New-Object System.Windows.Controls.StackPanel
    $stackPanel.Orientation = "Vertical"
    $stackPanel.HorizontalAlignment = "Center"
    $stackPanel.VerticalAlignment = "Center"
    $stackPanel.Margin = [System.Windows.Thickness]::new(10)

    # Create the TextBlock for the message
    $textBlock = New-Object System.Windows.Controls.TextBlock
    $textBlock.Text = $message
    $textBlock.FontSize = $fontSize
    $textBlock.Margin = [System.Windows.Thickness]::new(10)
    $textBlock.FontFamily = New-Object System.Windows.Media.FontFamily("Segoe UI")
    $textBlock.TextWrapping = "Wrap"
    $textBlock.HorizontalAlignment = 'Center'
    
    # Create the OK button
    $okButton = New-Object System.Windows.Controls.Button
    $okButton.Content = "OK"
    $okButton.Width = 80
    $okButton.Height = 30
    $okButton.Margin = [System.Windows.Thickness]::new(10)
    $okButton.HorizontalAlignment = 'Center'
    $okButton.Add_Click({
            $msgBoxWindow.Tag = "OK"
            $msgBoxWindow.Close()
        })
    
    # Create the Cancel button
    $cancelButton = New-Object System.Windows.Controls.Button
    $cancelButton.Content = "Cancel"
    $cancelButton.Width = 80
    $cancelButton.Height = 30
    $cancelButton.Margin = [System.Windows.Thickness]::new(10)
    $cancelButton.HorizontalAlignment = 'Center'
    $cancelButton.Add_Click({
            $msgBoxWindow.Tag = "Cancel"
            $msgBoxWindow.Close()
        })

    # Create a StackPanel for buttons
    $buttonPanel = New-Object System.Windows.Controls.StackPanel
    $buttonPanel.Orientation = "Horizontal"
    $buttonPanel.HorizontalAlignment = "Center"
    $buttonPanel.Margin = [System.Windows.Thickness]::new(10)
    $buttonPanel.Children.Add($okButton)
    $buttonPanel.Children.Add($cancelButton)
    
    # Add controls to the main StackPanel
    $stackPanel.Children.Add($textBlock)
    $stackPanel.Children.Add($buttonPanel)
    
    # Set the StackPanel as the content of the window
    $msgBoxWindow.Content = $stackPanel

    # Show the window
    $msgBoxWindow.ShowDialog() | Out-Null
    
    return $msgBoxWindow.Tag
}

# Function to show a custom message box with OK and Cancel buttons and a horizontal ScrollViewer
function Show-CustomMessageBox2 {
    param (
        [string]$message,
        [string]$title,
        [int]$fontSize = 20
    )
    
    # Create the main window
    $window = New-Object System.Windows.Window
    $window.Title = $title
    $window.Width = 1400
    $window.Height = 600
    $window.WindowStartupLocation = 'CenterScreen'
    
    # Create a Grid layout
    $grid = New-Object System.Windows.Controls.Grid
    $grid.Margin = [System.Windows.Thickness]::new(10)
    
    # Create a ScrollViewer to enable horizontal scrolling
    $scrollViewer = New-Object System.Windows.Controls.ScrollViewer
    $scrollViewer.VerticalScrollBarVisibility = 'auto'
    $scrollViewer.HorizontalScrollBarVisibility = 'disabled'
    
    # Create a StackPanel for layout inside the ScrollViewer
    $stackPanel = New-Object System.Windows.Controls.StackPanel
    $stackPanel.Orientation = "Vertical"
    $stackPanel.HorizontalAlignment = "Center"
    $stackPanel.VerticalAlignment = "Center"
    $stackPanel.Margin = [System.Windows.Thickness]::new(10)
    
    # Create the TextBlock for the message
    $textBlock = New-Object System.Windows.Controls.TextBlock
    $textBlock.Text = $message
    $textBlock.FontSize = $fontSize
    $textBlock.Margin = [System.Windows.Thickness]::new(10)
    $textBlock.FontFamily = New-Object System.Windows.Media.FontFamily("Segoe UI")
    $textBlock.TextWrapping = "Wrap"
    $textBlock.HorizontalAlignment = 'Center'
    $textBlock.VerticalAlignment = 'Center'  # Ensure vertical centering
    
    # Create the OK button
    $buttonOk = New-Object System.Windows.Controls.Button
    $buttonOk.Content = "OK"
    $buttonOk.Width = 75
    $buttonOk.Height = 30
    $buttonOk.Margin = [System.Windows.Thickness]::new(10)
    $buttonOk.HorizontalAlignment = 'Center'
    $buttonOk.Add_Click({
            $window.Tag = "OK"
            $window.Close()
        })

    # Create the Cancel button
    $buttonCancel = New-Object System.Windows.Controls.Button
    $buttonCancel.Content = "Cancel"
    $buttonCancel.Width = 75
    $buttonCancel.Height = 30
    $buttonCancel.Margin = [System.Windows.Thickness]::new(10)
    $buttonCancel.HorizontalAlignment = 'Center'
    $buttonCancel.Add_Click({
            $window.Tag = "Cancel"
            $window.Close()
        })

    # Create a StackPanel for buttons
    $buttonPanel = New-Object System.Windows.Controls.StackPanel
    $buttonPanel.Orientation = "Horizontal"
    $buttonPanel.HorizontalAlignment = "Center"
    $buttonPanel.Margin = [System.Windows.Thickness]::new(10)
    $buttonPanel.Children.Add($buttonOk)
    $buttonPanel.Children.Add($buttonCancel)
    
    # Add controls to the main StackPanel
    $stackPanel.Children.Add($textBlock)
    $stackPanel.Children.Add($buttonPanel)
    
    # Set the StackPanel as the content of the ScrollViewer
    $scrollViewer.Content = $stackPanel
    
    # Set the ScrollViewer as the content of the window
    $window.Content = $scrollViewer
    
    # Show the window
    $window.ShowDialog() | Out-Null
    
    return $window.Tag
}


# Globale Konfiguration für System-Tools
$Global:SystemToolConfig = @{
    DefaultTimeout = 300  # Sekunden
    MaxRetries     = 3
    Tools          = @{
        SFC              = @{
            RequiresAdmin = $true
            Timeout       = 600
            Arguments     = "/scannow"
            Description   = "System File Checker"
        }
        DISM             = @{
            RequiresAdmin = $true
            Timeout       = 1200
            Arguments     = "/Online /Cleanup-Image /RestoreHealth"
            Description   = "Deployment Image Servicing and Management"
        }
        WindowsDefender  = @{
            RequiresAdmin = $true
            Timeout       = 300
            Description   = "Windows Defender Security Center"
        }
        WindowsUpdate    = @{
            RequiresAdmin = $true
            Timeout       = 300
            Description   = "Windows Update"
        }
        MemoryDiagnostic = @{
            RequiresAdmin = $true
            Timeout       = 300
            Description   = "Windows Memory Diagnostic"
        }
        DiskCleanup      = @{
            RequiresAdmin = $true
            Timeout       = 600
            Description   = "Disk Cleanup"
        }
        NetworkReset     = @{
            RequiresAdmin = $true
            Timeout       = 300
            Description   = "Network Adapter Reset"
        }
        PSModuleInstall  = @{
            RequiresAdmin = $true
            Timeout       = 300
            Description   = "PowerShell Module Installation"
        }
        MRT              = @{
            RequiresAdmin = $true
            Timeout       = 3600
            Description   = "Malicious Software Removal Tool"
        }
        TempCleanup      = @{
            RequiresAdmin = $true
            Timeout       = 300
            Description   = "Temporary Files Cleanup"
        }
    }
}

# Zentrale Funktion für Tool-Ausführung
function Invoke-SystemTool {
    param(
        [Parameter(Mandatory)]
        [string]$ToolName,
        [string]$Arguments,
        [System.Windows.Forms.RichTextBox]$OutputBox,
        [System.Windows.Forms.ProgressBar]$ProgressBar,
        [switch]$RequiresAdmin
    )
    
    try {
        # Tool-Konfiguration abrufen
        $toolConfig = $Global:SystemToolConfig.Tools[$ToolName]
        if (-not $toolConfig) {
            throw "Keine Konfiguration für Tool '$ToolName' gefunden."
        }

        # Status aktualisieren
        Update-ProgressStatus -StatusText "Starte $($toolConfig.Description)..." -ProgressValue 0 -TextColor ([System.Drawing.Color]::DarkBlue) -progressBarParam $ProgressBar
        
        # Prüfen ob Admin-Rechte benötigt werden
        if ($toolConfig.RequiresAdmin -and -not (Test-Admin)) {
            throw "Administratorrechte erforderlich für $($toolConfig.Description)"
        }

        # Timestamp für Log
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $OutputBox.SelectionColor = [System.Drawing.Color]::Blue
        $OutputBox.AppendText("[$timestamp] Starte $($toolConfig.Description)...`r`n")

        # Tool-spezifische Ausführung
        $scriptBlock = {
            param($toolName, $toolArgs, $config)
            
            $progressPreference = 'SilentlyContinue'
            $ErrorActionPreference = 'Stop'
            
            switch ($toolName) {
                'SFC' {
                    $process = Start-Process "sfc.exe" -ArgumentList $config.Arguments -WindowStyle Hidden -Wait -PassThru
                    return $process.ExitCode
                }
                'DISM' {
                    $process = Start-Process "DISM.exe" -ArgumentList $toolArgs -WindowStyle Hidden -Wait -PassThru
                    return $process.ExitCode
                }
                'WindowsDefender' {
                    Start-Process "windowsdefender://threat" -WindowStyle Hidden
                    return 0
                }
                'WindowsUpdate' {
                    Start-Process "ms-settings:windowsupdate" -WindowStyle Hidden
                    return 0
                }
                'MemoryDiagnostic' {
                    Start-Process "mdsched.exe" -WindowStyle Hidden
                    return 0
                }
                'DiskCleanup' {
                    Start-Process "cleanmgr.exe" -ArgumentList "/sagerun:1" -WindowStyle Hidden -Wait
                    return 0
                }
                'NetworkReset' {
                    ipconfig /release
                    ipconfig /renew
                    ipconfig /flushdns
                    return 0
                }
                default {
                    throw "Unbekanntes Tool: $toolName"
                }
            } }

        # Ausführung mit Timeout
        $job = Start-Job -ScriptBlock $scriptBlock -ArgumentList $ToolName, $Arguments, $toolConfig
        
        # Warten mit Timeout
        $timeout = if ($toolConfig.Timeout) { $toolConfig.Timeout } else { $Global:SystemToolConfig.DefaultTimeout }
        $completed = $job | Wait-Job -Timeout $timeout
        
        if ($completed) {
            $result = Receive-Job -Job $job
            Remove-Job -Job $job
            
            # Erfolg melden
            Update-ProgressStatus -StatusText "$($toolConfig.Description) erfolgreich ausgeführt" -ProgressValue 100 -TextColor ([System.Drawing.Color]::Green) -progressBarParam $ProgressBar
            $OutputBox.SelectionColor = [System.Drawing.Color]::Green
            $OutputBox.AppendText("[$timestamp] $($toolConfig.Description) wurde erfolgreich ausgeführt.`r`n")
            
            return $result
        }
        else {
            Remove-Job -Job $job -Force
            throw "Timeout nach $timeout Sekunden"
        }
    }
    catch {
        # Fehlerbehandlung
        Update-ProgressStatus -StatusText "Fehler bei $($toolConfig.Description)" -ProgressValue 0 -TextColor ([System.Drawing.Color]::Red) -progressBarParam $ProgressBar
        $OutputBox.SelectionColor = [System.Drawing.Color]::Red
        $OutputBox.AppendText("[$timestamp] Fehler bei $($toolConfig.Description): $_`r`n")
        return $false
    }
}

# Function to switch to output tab
function Switch-ToOutputTab {
    param(
        [Parameter(Mandatory)]
        [System.Windows.Forms.TabControl]$TabControl
    )
    # Setze den ausgewählten Tab auf den Ausgabe-Tab (Index 0)
    $TabControl.SelectedIndex = 0
}

# Funktion zum Abrufen der Konfiguration
function Get-SystemToolConfig {
    param (
        [string]$ToolName
    )
    
    if ($ToolName) {
        if (-not $Global:SystemToolConfig.Tools.ContainsKey($ToolName)) {
            throw "Keine Konfiguration für Tool '$ToolName' gefunden."
        }
        return $Global:SystemToolConfig.Tools[$ToolName]
    }
    return $Global:SystemToolConfig
}

# Funktion zum Aktualisieren der Konfiguration
function Update-SystemToolConfig {
    param (
        [string]$ToolName,
        [hashtable]$Config
    )
    
    if ($Global:SystemToolConfig.Tools.ContainsKey($ToolName)) {
        $Global:SystemToolConfig.Tools[$ToolName] = $Config
        return $true
    }
    return $false
}

# Exportiere die Funktionen
Export-ModuleMember -Function @(
    'Test-IsAdmin',
    'Initialize-Encoding',
    'Show-CustomMessageBox',
    'Show-CustomMessageBox2',
    'Save-LogToFile',
    'Invoke-SystemTool',
    'Switch-ToOutputTab',
    'Get-SystemToolConfig',
    'Update-SystemToolConfig',
    'Write-ColoredCenteredText',
    'Write-WrappedText',
    'Write-ConsoleAndOutputBox',
    'Get-Symbol',
    'Get-SymbolColor',
    'Get-SymbolConsoleColor'
)
Export-ModuleMember -Variable SystemToolConfig


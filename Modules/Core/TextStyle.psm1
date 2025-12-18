# TextStyle.psm1 - zentrale Farb- und Textformatierung

$script:textStyleConfig = $null

function Get-DefaultTextStyle {
    $default = @{
        Output = @{
            Colors = @{
                Background = "#1E1E1E"
                Foreground = "#DCDCDC"
                Banner     = "#9ACD32"
                Success    = "#3DDC84"
                Warning    = "#FFB74D"
                Error      = "#FF6B6B"
                Info       = "#64B5F6"
                Accent     = "#00BCD4"
                Divider    = "#6E6E6E"
                Muted      = "#A6ADB4"
                Alert      = "#8B4513"
                Critical   = "#FF4500"
            }
            Styles = @{
                Default     = @{ ColorKey = "Foreground" }
                BannerFrame = @{ ColorKey = "Banner"; Font = @{ SizeDelta = 3; Style = "Bold" } }
                BannerTitle = @{ ColorKey = "Banner"; Font = @{ SizeDelta = 3; Style = "Bold" } }
                Heading     = @{ ColorKey = "Accent"; Font = @{ SizeDelta = 1; Style = "Bold" } }
                Success     = @{ ColorKey = "Success"; Font = @{ Style = "Bold" } }
                Warning     = @{ ColorKey = "Warning"; Font = @{ Style = "Bold" } }
                Error       = @{ ColorKey = "Error";   Font = @{ Style = "Bold" } }
                Info        = @{ ColorKey = "Info" }
                Action      = @{ ColorKey = "Info";    Font = @{ Style = "Bold" } }
                Accent      = @{ ColorKey = "Accent";  Font = @{ Style = "Bold" } }
                BodySmall   = @{ ColorKey = "Foreground"; Font = @{ SizeDelta = -2; Style = "Regular" } }
                Divider     = @{ ColorKey = "Divider" }
                Muted       = @{ ColorKey = "Muted"; Font = @{ Style = "Italic" } }
                Alert       = @{ ColorKey = "Alert"; Font = @{ Style = "Bold" } }
                Critical    = @{ ColorKey = "Critical"; Font = @{ Style = "Bold" } }
            }
            Symbols = @{
                Success = @{ Icon = "[√]"; StyleKey = "Success" }
                Error   = @{ Icon = "[X]"; StyleKey = "Error" }
                Warning = @{ Icon = "[!]"; StyleKey = "Warning" }
                Info    = @{ Icon = "[►]"; StyleKey = "Info" }
                Process = @{ Icon = "[>]"; StyleKey = "Action" }
                Start   = @{ Icon = "[+]"; StyleKey = "Action" }
                Check   = @{ Icon = "[✓]"; StyleKey = "Success" }
                Stop    = @{ Icon = "[■]"; StyleKey = "Error" }
                Bullet  = @{ Icon = "[●]"; StyleKey = "Info" }
                Arrow   = @{ Icon = "[<]"; StyleKey = "Accent" }
                Alert   = @{ Icon = "[⚠]"; StyleKey = "Alert" }
            }
        }
        Console = @{
            Colors = @{
                Default = "Gray"
                Success = "Green"
                Warning = "Yellow"
                Error   = "Red"
                Info    = "Cyan"
                Accent  = "Magenta"
                Action  = "Cyan"
                Alert   = "DarkYellow"
                Muted   = "DarkGray"
                Critical= "DarkRed"
            }
        }
    }
    return $default
}

function Merge-Hashtable {
    param(
        [hashtable]$Base,
        [hashtable]$Override
    )
    if (-not $Base) { return $Override }
    if (-not $Override) { return $Base.Clone() }

    $result = @{}
    foreach ($key in $Base.Keys) {
        $value = $Base[$key]
        if ($value -is [hashtable]) {
            $result[$key] = Merge-Hashtable -Base $value -Override @{}
        }
        else {
            $result[$key] = $value
        }
    }

    foreach ($key in $Override.Keys) {
        $baseValue = if ($result.ContainsKey($key)) { $result[$key] } else { $null }
        $overrideValue = $Override[$key]
        if ($baseValue -is [hashtable] -and $overrideValue -is [hashtable]) {
            $result[$key] = Merge-Hashtable -Base $baseValue -Override $overrideValue
        }
        elseif ($overrideValue -is [hashtable]) {
            $result[$key] = Merge-Hashtable -Base @{} -Override $overrideValue
        }
        else {
            $result[$key] = $overrideValue
        }
    }
    return $result
}

function ConvertTo-DrawingColor {
    param([string]$Value)
    if ([string]::IsNullOrWhiteSpace($Value)) {
        return [System.Drawing.Color]::Empty
    }
    $trimmed = $Value.Trim()
    if ($trimmed.StartsWith("#")) {
        return [System.Drawing.ColorTranslator]::FromHtml($trimmed)
    }
    if ($trimmed -match '^[0-9A-Fa-f]{6}$') {
        return [System.Drawing.ColorTranslator]::FromHtml("#$trimmed")
    }
    $color = [System.Drawing.Color]::FromName($trimmed)
    if ($color.IsKnownColor -or $color.IsNamedColor) {
        return $color
    }
    return [System.Drawing.Color]::Empty
}

function ConvertTo-ConsoleColor {
    param([string]$Value)
    if ([string]::IsNullOrWhiteSpace($Value)) {
        return [System.ConsoleColor]::Gray
    }
    try {
        return [System.Enum]::Parse([System.ConsoleColor], $Value, $true)
    }
    catch {
        return [System.ConsoleColor]::Gray
    }
}

function Initialize-TextStyleDefaults {
    if (-not $script:textStyleConfig) {
        $script:textStyleConfig = Get-DefaultTextStyle
    }
}

function Initialize-TextStyle {
    param(
        [hashtable]$Settings,
        [System.Windows.Forms.RichTextBox]$OutputBox
    )
    $defaults = Get-DefaultTextStyle
    $userScheme = $null
    if ($Settings -and $Settings.ContainsKey("ColorScheme")) {
        $schemeCandidate = $Settings["ColorScheme"]
        if ($schemeCandidate -is [hashtable]) {
            $userScheme = $schemeCandidate
        }
        elseif ($schemeCandidate -is [System.Management.Automation.PSCustomObject]) {
            $userScheme = @{}
            foreach ($prop in $schemeCandidate.PSObject.Properties) {
                $userScheme[$prop.Name] = $prop.Value
            }
        }
    }
    if ($userScheme) {
        $script:textStyleConfig = Merge-Hashtable -Base $defaults -Override $userScheme
    }
    else {
        $script:textStyleConfig = $defaults
    }
    if ($OutputBox) {
        Set-OutputTheme -OutputBox $OutputBox
    }
    return $script:textStyleConfig
}

function Get-TextStyleConfig {
    Initialize-TextStyleDefaults
    return $script:textStyleConfig
}

function Get-OutputColor {
    param([string]$Key = "Foreground")
    Initialize-TextStyleDefaults
    $colors = $script:textStyleConfig.Output.Colors
    if ($colors.ContainsKey($Key)) {
        $color = ConvertTo-DrawingColor -Value $colors[$Key]
        if (-not $color.IsEmpty) { return $color }
    }
    return ConvertTo-DrawingColor -Value $colors.Foreground
}

function Get-ConsoleColor {
    param([string]$Key = "Default")
    Initialize-TextStyleDefaults
    $colors = $script:textStyleConfig.Console.Colors
    if ($colors.ContainsKey($Key)) {
        return ConvertTo-ConsoleColor -Value $colors[$Key]
    }
    return ConvertTo-ConsoleColor -Value $colors.Default
}

function Get-OutputStyle {
    param([string]$Style = "Default")
    Initialize-TextStyleDefaults
    $styles = $script:textStyleConfig.Output.Styles
    if (-not $styles.ContainsKey($Style)) {
        $Style = "Default"
    }
    $styleDef = $styles[$Style]
    $colorKey = if ($styleDef.ContainsKey("ColorKey")) { $styleDef.ColorKey } else { "Foreground" }
    $color = Get-OutputColor -Key $colorKey
    $font = $null
    if ($styleDef.ContainsKey("Font")) {
        $font = $styleDef.Font
    }
    return @{ Color = $color; Font = $font }
}

function New-OutputFont {
    param(
        [System.Drawing.Font]$BaseFont,
        [hashtable]$FontDefinition
    )
    if (-not $BaseFont) { return $null }
    if (-not $FontDefinition) { return $BaseFont }

    $family = if ($FontDefinition.ContainsKey("Family")) { $FontDefinition.Family } else { $BaseFont.FontFamily.Name }
    $size = if ($FontDefinition.ContainsKey("Size")) {
        [float]$FontDefinition.Size
    }
    elseif ($FontDefinition.ContainsKey("SizeDelta")) {
        [float]($BaseFont.Size + $FontDefinition.SizeDelta)
    }
    else {
        $BaseFont.Size
    }

    $styleValue = if ($FontDefinition.ContainsKey("Style")) { $FontDefinition.Style } else { $BaseFont.Style.ToString() }
    $style = [System.Drawing.FontStyle]::Regular
    try {
        $style = [System.Enum]::Parse([System.Drawing.FontStyle], $styleValue, $true)
    }
    catch {
        $style = $BaseFont.Style
    }

    try {
        return New-Object System.Drawing.Font($family, $size, $style)
    }
    catch {
        return $BaseFont
    }
}

function Set-OutputSelectionStyle {
    param(
        [Parameter(Mandatory = $true)]
        [System.Windows.Forms.RichTextBox]$OutputBox,
        [string]$Style = "Default",
        [System.Drawing.Color]$FallbackColor = [System.Drawing.Color]::Empty
    )
    if (-not $OutputBox) { return }
    $definition = Get-OutputStyle -Style $Style
    $color = $definition.Color
    if ($color.IsEmpty -and (-not $FallbackColor.IsEmpty)) {
        $color = $FallbackColor
    }
    if (-not $color.IsEmpty) {
        $OutputBox.SelectionColor = $color
    }

    $currentFont = $OutputBox.SelectionFont
    if (-not $currentFont) {
        $currentFont = $OutputBox.Font
    }
    $newFont = New-OutputFont -BaseFont $currentFont -FontDefinition $definition.Font
    if ($newFont) {
        $OutputBox.SelectionFont = $newFont
    }
}

function Set-OutputTheme {
    param([System.Windows.Forms.RichTextBox]$OutputBox)
    if (-not $OutputBox) { return }
    Initialize-TextStyleDefaults
    $colors = $script:textStyleConfig.Output.Colors
    $backColor = ConvertTo-DrawingColor -Value $colors.Background
    $foreColor = ConvertTo-DrawingColor -Value $colors.Foreground
    if (-not $backColor.IsEmpty) {
        $OutputBox.BackColor = $backColor
    }
    if (-not $foreColor.IsEmpty) {
        $OutputBox.ForeColor = $foreColor
    }
}

function Write-ConsoleStyle {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        [string]$Style = "Default",
        [switch]$NoNewLine
    )
    $color = Get-ConsoleColor -Key $Style
    if ($NoNewLine) {
        Write-Host -NoNewline -ForegroundColor $color $Message
    }
    else {
        Write-Host -ForegroundColor $color $Message
    }
}

# ===== SYMBOL FUNCTIONS =====

function Get-Symbol {
    <#
    .SYNOPSIS
        Gibt das Symbol-Icon für einen bestimmten Typ zurück
    .PARAMETER Type
        Der Symbol-Typ (Success, Error, Warning, Info, Process, Start, Check, Stop, Bullet, Arrow, Alert)
    .EXAMPLE
        Get-Symbol -Type Success  # Gibt "[√]" zurück
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('Success', 'Error', 'Warning', 'Info', 'Process', 'Start', 'Check', 'Stop', 'Bullet', 'Arrow', 'Alert')]
        [string]$Type
    )
    Initialize-TextStyleDefaults
    $symbols = $script:textStyleConfig.Output.Symbols
    if ($symbols.ContainsKey($Type)) {
        return $symbols[$Type].Icon
    }
    return "[?]"
}

function Get-SymbolStyle {
    <#
    .SYNOPSIS
        Gibt den Style-Key für ein Symbol zurück
    .PARAMETER Type
        Der Symbol-Typ (Success, Error, Warning, Info, Process, Start, Check, Stop, Bullet, Arrow, Alert)
    .EXAMPLE
        Get-SymbolStyle -Type Success  # Gibt "Success" zurück
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('Success', 'Error', 'Warning', 'Info', 'Process', 'Start', 'Check', 'Stop', 'Bullet', 'Arrow', 'Alert')]
        [string]$Type
    )
    Initialize-TextStyleDefaults
    $symbols = $script:textStyleConfig.Output.Symbols
    if ($symbols.ContainsKey($Type) -and $symbols[$Type].ContainsKey("StyleKey")) {
        return $symbols[$Type].StyleKey
    }
    return "Default"
}

function Get-SymbolColor {
    <#
    .SYNOPSIS
        Gibt die RichTextBox-Farbe für ein Symbol zurück
    .PARAMETER Type
        Der Symbol-Typ (Success, Error, Warning, Info, Process, Start, Check, Stop, Bullet, Arrow, Alert)
    .EXAMPLE
        Get-SymbolColor -Type Success  # Gibt die grüne Success-Farbe zurück
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('Success', 'Error', 'Warning', 'Info', 'Process', 'Start', 'Check', 'Stop', 'Bullet', 'Arrow', 'Alert')]
        [string]$Type
    )
    $styleKey = Get-SymbolStyle -Type $Type
    $style = Get-OutputStyle -Style $styleKey
    return $style.Color
}

function Get-SymbolConsoleColor {
    <#
    .SYNOPSIS
        Gibt die Konsolen-Farbe für ein Symbol zurück
    .PARAMETER Type
        Der Symbol-Typ (Success, Error, Warning, Info, Process, Start, Check, Stop, Bullet, Arrow, Alert)
    .EXAMPLE
        Get-SymbolConsoleColor -Type Success  # Gibt "Green" zurück
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('Success', 'Error', 'Warning', 'Info', 'Process', 'Start', 'Check', 'Stop', 'Bullet', 'Arrow', 'Alert')]
        [string]$Type
    )
    $styleKey = Get-SymbolStyle -Type $Type
    return Get-ConsoleColor -Key $styleKey
}

function Get-SymbolDefinition {
    <#
    .SYNOPSIS
        Gibt die vollständige Symbol-Definition zurück (Icon, Style, Farben)
    .PARAMETER Type
        Der Symbol-Typ (Success, Error, Warning, Info, Process, Start, Check, Stop, Bullet, Arrow, Alert)
    .EXAMPLE
        $def = Get-SymbolDefinition -Type Success
        Write-Host "$($def.Icon) Operation erfolgreich" -ForegroundColor $def.ConsoleColor
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('Success', 'Error', 'Warning', 'Info', 'Process', 'Start', 'Check', 'Stop', 'Bullet', 'Arrow', 'Alert')]
        [string]$Type
    )
    return @{
        Type         = $Type
        Icon         = Get-Symbol -Type $Type
        StyleKey     = Get-SymbolStyle -Type $Type
        Color        = Get-SymbolColor -Type $Type
        ConsoleColor = Get-SymbolConsoleColor -Type $Type
    }
}

# ===== END SYMBOL FUNCTIONS =====

Export-ModuleMember -Function Initialize-TextStyle, Get-TextStyleConfig, Get-OutputColor, Get-ConsoleColor, `
    Get-OutputStyle, Set-OutputSelectionStyle, Set-OutputTheme, Write-ConsoleStyle, `
    Get-Symbol, Get-SymbolStyle, Get-SymbolColor, Get-SymbolConsoleColor, Get-SymbolDefinition

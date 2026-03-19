# TextStyle.psm1 - zentrale Farb- und Textformatierung

$script:textStyleConfig = $null

function Get-DefaultTextStyle {
    $default = @{
        Output = @{
            Colors = @{
                Background = "#2A2A2A"
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

# SIG # Begin signature block
# MIIcSgYJKoZIhvcNAQcCoIIcOzCCHDcCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDRcRJZcl2mbWkl
# iFmXSHVgyeeT+DeOXEYT3ZoTRdEF7aCCFnowggM8MIICJKADAgECAhBJfyGrXBJT
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
# MQ4wDAYKKwYBBAGCNwIBFTAvBgkqhkiG9w0BCQQxIgQgQOIM8HSKDeYtdXo17ROT
# zBAHlgcR9QdFCKnu857qy+MwDQYJKoZIhvcNAQEBBQAEggEAnBAZ7JR8DhZvbqca
# mhVR1yrGEvMUXJaoRCeAdNscYqyrfz092AbNM9W2I0DPVmQ8RvUKSHRLdNNcldr3
# F4sgZyyIA4308uV7GrdCmca6PFhPV91EliYS5BS2fRdexfJKgPjT2292SKmh/u2J
# FL1iYJrwrOC6HD4afLXrd7fprG7xsQju9ECt9+IJtKzTE3YjmUWcg2BdtPR5shPe
# oZM7uJrC0NY/XN2dxWTG78muwjLl+vBZh9I7pytOV+/y1CXTqJEwqoDpvMR46eRv
# 2EXZtSdO3+twPtxgbM/WO1TzNleADRti6Z49hJHz9hpb1e5aVCZgfBIZ6J/B9Cdk
# mB0iaKGCAyYwggMiBgkqhkiG9w0BCQYxggMTMIIDDwIBATB9MGkxCzAJBgNVBAYT
# AlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5jLjFBMD8GA1UEAxM4RGlnaUNlcnQg
# VHJ1c3RlZCBHNCBUaW1lU3RhbXBpbmcgUlNBNDA5NiBTSEEyNTYgMjAyNSBDQTEC
# EAqA7xhLjfEFgtHEdqeVdGgwDQYJYIZIAWUDBAIBBQCgaTAYBgkqhkiG9w0BCQMx
# CwYJKoZIhvcNAQcBMBwGCSqGSIb3DQEJBTEPFw0yNjAxMjAxODAyNTNaMC8GCSqG
# SIb3DQEJBDEiBCDBvOf47TV216rhkQze+34LM0tvpNett3/k6gUcW7VOPTANBgkq
# hkiG9w0BAQEFAASCAgAGwhqr1JyGXIV5xy1UPI56M0mWtHJI5Em21lMsKO6Obo29
# J/VqKxuIrGHTaH+bdLGCF5oJ5A27mvUj0xmu5naJd9xB7U9dAiHvuvpahwiXgIHc
# /g3QveakVtU0K2v8wGBeIyEfUxdsBxWanRIRyhA1UniS1D64B00URqq5cr6UAOAB
# nukLxV4Sq7x3PlSPd+hD8KOLIDAgoTEouFbQz5nazxx8LXk90DsHGTWTp3s1knqN
# m19FcR3kL6uWIYkI2wtXyVPeMCFZRM5Bfv4+Im9GLxRDleDouIRimciIgXMiGFIR
# PW57dswKSuNbAxEHjOEu7c6WQCtODMAGo0tNuiI0gT1VxZPYHAsE8SIBL3bT9akE
# rwdgKKlCpuDUoRDfgPAXxSBWRxMjNw0zeDInK8l4JYpYuKPfCUpSLfShJVMCnYDJ
# t3zLfuOyQ5qa8luXZh707ELAdiHQtU4kfho/NjqjpZnXmlabDLwrUEDBhItIGUEW
# ABpazOgqGwLYa24FhflGxsWz/DS3LWitViFgaTOLK/iN7U9jz+UONEUmLCTURWYd
# AJyMmKYvN2A/+q2y04O6vw1OsPkua2iqKiyobeVLOF/+1inURcwGCsqB90Ft3ht6
# rdxgwuopEsABhx5XLiRlFeBJgVvV6vC6HpYz4EpLyn52Fv58B9pLV3rpgyy4Ag==
# SIG # End signature block

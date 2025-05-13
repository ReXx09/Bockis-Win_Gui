#Berechnung, Text und Rahmenfarbe
function Write-ColoredCenteredText {
    param(
        [string]$text,
        [string]$frameColor = "Green",
        [string]$textColor = "Red",
        [int]$totalWidth = 100,
        [int]$contentWidth = 96  # Breite innerhalb der Rahmenzeichen (║)
    )
    
    # Berechne die tatsächliche Textlänge
    $textLength = $text.Length
    
    # Berechne die Anzahl der benötigten Leerzeichen für perfekte Zentrierung
    $totalSpaces = $contentWidth - $textLength
    $leftSpaces = [math]::Floor($totalSpaces / 2)
    $rightSpaces = $totalSpaces - $leftSpaces
    
    # Erstelle den formatierten Text mit exakter Anzahl von Leerzeichen
    Write-Host "║" -NoNewline -ForegroundColor $frameColor
    Write-Host (" " * $leftSpaces) -NoNewline
    Write-Host $text -NoNewline -ForegroundColor $textColor
    Write-Host (" " * $rightSpaces) -NoNewline
    Write-Host "║" -ForegroundColor $frameColor
}

# Function to start Windows Update and show status
function Start-WindowsUpdate {
    param(
        [System.Windows.Forms.RichTextBox]$outputBox,
        [System.Windows.Forms.TabControl]$TabControl
    )
    # outputBox zuruecksetzen
    $outputBox.Clear()

    Clear-Host
    
    # Rahmen und Systeminformationen erstellen
    $computerName = $env:COMPUTERNAME
    $userName = $env:USERNAME
    $osInfo = (Get-CimInstance -ClassName Win32_OperatingSystem).Caption
    $dateTime = Get-Date -Format "dd.MM.yyyy HH:mm:ss"
    $width = 100

        
    # Rahmen oben
    Write-Host "╔══════════════════════════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-ColoredCenteredText                             "Windows Update"                                         
    Write-Host "╚══════════════════════════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Green
    

    
    Write-Host
    Write-Host
    Write-Host
    Write-Host '   888       888 d8b               888                                              ' -ForegroundColor Cyan
    Write-Host '   888   o   888 Y8P               888                                              ' -ForegroundColor Blue
    Write-Host '   888  d8b  888                   888                                              ' -ForegroundColor Cyan
    Write-Host '   888 d888b 888 888 88888b.   .d88888  .d88b.  888  888  888 .d8888b               ' -ForegroundColor Blue
    Write-Host '   888d88888b888 888 888 "88b d88" 888 d88""88b 888  888  888 88K                   ' -ForegroundColor Cyan
    Write-Host '   88888P Y88888 888 888  888 888  888 888  888 888  888  888 "Y8888b.              ' -ForegroundColor Blue    
    Write-Host '   8888P   Y8888 888 888  888 Y88b 888 Y88..88P Y88b 888 d88P      X88              ' -ForegroundColor Cyan
    Write-Host '   888P     Y888 888 888  888  "Y88888  "Y88P"   "Y8888888P"   88888P               ' -ForegroundColor Blue
    Write-Host                                                                    
    Write-Host                                                                    
    Write-Host                                                                    
    Write-Host '   888     888               888          888                                       ' -ForegroundColor Cyan
    Write-Host '   888     888               888          888                                       ' -ForegroundColor Blue
    Write-Host '   888     888               888          888                                       ' -ForegroundColor Cyan
    Write-Host '   888     888 88888b.   .d88888  8888b.  888888 .d88b.                             ' -ForegroundColor Blue
    Write-Host '   888     888 888 "88b d88" 888     "88b 888   d8P  Y8b                            ' -ForegroundColor Cyan
    Write-Host '   888     888 888  888 888  888 .d888888 888   88888888                            ' -ForegroundColor Blue
    Write-Host '   Y88b. .d88P 888 d88P Y88b 888 888  888 Y88b. Y8b.                                ' -ForegroundColor Cyan
    Write-Host '    "Y88888P"  88888P"   "Y88888 "Y888888  "Y888 "Y8888                             ' -ForegroundColor Blue
    Write-Host '               888                                                                  ' -ForegroundColor Cyan
    Write-Host '               888                                                                  ' -ForegroundColor Blue
    Write-Host '               888                                                                  ' -ForegroundColor Cyan
    Write-Host
    Write-Host


    # Rahmen für Systeminformationen
    Write-Host "╔══════════════════════════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-ColoredCenteredText                          "SYSTEMINFORMATIONEN"                                           
    Write-Host "╠══════════════════════════════════════════════════════════════════════════════════════════════════╣" -ForegroundColor Green
    # Systeminformationen
    Write-Host "║                                                                                                  ║" -ForegroundColor Green
    Write-Host "      ├─    Betriebssystem: $osInfo           "            -ForegroundColor Yellow                 
    Write-Host "      ├─    Computer:       $computerName     "            -ForegroundColor Yellow                                    
    Write-Host "      ├─    Benutzer:       $userName         "            -ForegroundColor Yellow                                    
    Write-Host "      └─    Datum und Zeit: $dateTime         "            -ForegroundColor Yellow                                  
    Write-Host "║                                                                                                  ║" -ForegroundColor Green
    
    Write-Host "╠══════════════════════════════════════════════════════════════════════════════════════════════════╣" -ForegroundColor Green
    Write-ColoredCenteredText "Windows Update wird initialisiert..."
    Write-Host "╚══════════════════════════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Green
    
    # 3 Sekunden warten vor dem Start
    Start-Sleep -Seconds 3

    # Header für den SFC-Scan
    $outputBox.SelectionColor = [System.Drawing.Color]::DarkBlue
    $outputBox.AppendText("`r`n===== SYSTEM FILE CHECKER (SFC) =====`r`n")
    $outputBox.AppendText("Zeitstempel: $(Get-Date -Format 'dd.MM.yyyy HH:mm:ss')`r`n`r`n")


}
# ToolLibrary.psm1 - Bibliothek für Tool-Downloads
# Autor: Bocki

# Benötigte Assemblies laden
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

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
        Choco       = '7zip'
    },
    @{
        Name        = 'CCleaner'
        Description = 'Systembereinigung und Optimierung'
        Version     = '6.10'
        DownloadUrl = 'https://www.ccleaner.com/download'
        Category    = 'System-Tools'
        Tags        = @('Cleanup', 'Optimization', 'System')
        Winget      = 'Piriform.CCleaner'
        Choco       = 'ccleaner'
    },
    @{
        Name        = 'CPU-Z'
        Description = 'Detaillierte CPU- und Systeminformationen'
        Version     = '2.05'
        DownloadUrl = 'https://www.cpuid.com/softwares/cpu-z.html'
        Category    = 'System-Tools'
        Tags        = @('Hardware', 'Monitoring', 'CPU')
        Winget      = 'CPUID.CPU-Z'
        Choco       = 'cpu-z'
    },
    @{
        Name        = 'GPU-Z'
        Description = 'Grafikkarten-Informationen'
        Version     = '2.45'
        DownloadUrl = 'https://www.techpowerup.com/gpuz/'
        Category    = 'System-Tools'
        Tags        = @('Hardware', 'Monitoring', 'GPU')
        Winget      = 'TechPowerUp.GPU-Z'
        Choco       = 'gpu-z'
    }
)

# Browser-Tools hinzufügen
$script:toolLibrary['browser'] = @(
    @{
        Name        = 'Brave Browser'
        Description = 'Privater und sicherer Webbrowser mit integriertem Adblocker'
        Version     = 'Aktuell'
        DownloadUrl = 'https://brave.com/download/'
        Category    = 'Browser'
        Tags        = @('Browser', 'Privacy', 'Security')
        Winget      = 'Brave.Brave'
        Choco       = 'brave'
    },
    @{
        Name        = 'Mozilla Firefox'
        Description = 'Beliebter Open-Source-Browser mit Fokus auf Privatsphäre'
        Version     = 'Aktuell'
        DownloadUrl = 'https://www.mozilla.org/firefox/'
        Category    = 'Browser'
        Tags        = @('Browser', 'Privacy', 'Open-Source')
        Winget      = 'Mozilla.Firefox'
        Choco       = 'firefox'
    },
    @{
        Name        = 'Google Chrome'
        Description = 'Schneller und beliebter Webbrowser von Google'
        Version     = 'Aktuell'
        DownloadUrl = 'https://www.google.com/chrome/'
        Category    = 'Browser'
        Tags        = @('Browser', 'Google', 'Web')
        Winget      = 'Google.Chrome'
        Choco       = 'googlechrome'
    }
)

# Kommunikations-Tools hinzufügen
$script:toolLibrary['communication'] = @(
    @{
        Name        = 'Discord'
        Description = 'Kommunikationsplattform für Gaming und Communities'
        Version     = 'Aktuell'
        DownloadUrl = 'https://discord.com/download'
        Category    = 'Kommunikation'
        Tags        = @('Communication', 'Gaming', 'Community')
    }
)

# Deklariere die Variable global
$Global:linkPositions = New-Object System.Collections.ArrayList

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
    
    if ($script:toolLibrary.ContainsKey($Category.ToLower())) {
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

# Funktion zum Anzeigen der Tools in einer RichTextBox
function Show-ToolList {
    param (
        [System.Windows.Forms.RichTextBox]$RichTextBox,
        [string]$Category = "all"
    )
    
    # Zurücksetzen der globalen Link-Positionen
    $Global:linkPositions.Clear()
    
    # Entferne bestehende Event Handler
    $existingHandlers = $RichTextBox.Events | Where-Object { $_.EventName -in @('MouseMove', 'Click') }
    foreach ($handler in $existingHandlers) {
        $RichTextBox.Events.Remove($handler)
    }
    
    $RichTextBox.Clear()
    $RichTextBox.SelectionColor = [System.Drawing.Color]::DarkBlue
    $RichTextBox.AppendText("===== VERFÜGBARE TOOLS =====`r`n`r`n")
    
    # Tabellenkopf
    $RichTextBox.SelectionColor = [System.Drawing.Color]::Blue
    $RichTextBox.AppendText("Tool-Name".PadRight(30) + "Kategorie".PadRight(20) + "Beschreibung".PadRight(50) + "Installation`r`n")
    $RichTextBox.AppendText("-" * 120 + "`r`n")
    
    # Tools nach Kategorie filtern
    $filteredTools = if ($Category -eq "all") {
        $script:toolLibrary.Values | ForEach-Object { $_ } | Flatten
    }
    else {
        $script:toolLibrary.Values | ForEach-Object { $_ } | Flatten | Where-Object { $_.Category -eq $Category }
    }
    
    # Tools anzeigen
    $rowCount = 0
    foreach ($tool in $filteredTools) {
        # Speichere die Startposition der Zeile
        $lineStart = $RichTextBox.TextLength
        
        # Setze Hintergrundfarbe basierend auf Zeilennummer
        if ($rowCount % 2 -eq 0) {
            $RichTextBox.SelectionBackColor = [System.Drawing.Color]::FromArgb(245, 245, 245)  # Hellgrau
        }
        else {
            $RichTextBox.SelectionBackColor = [System.Drawing.Color]::White
        }
        
        $RichTextBox.SelectionColor = [System.Drawing.Color]::Black
        $RichTextBox.AppendText($tool.Name.PadRight(30))
        $RichTextBox.AppendText($tool.Category.PadRight(20))
        
        # Beschreibung (gekürzt, wenn zu lang)
        $description = if ($tool.Description.Length -gt 47) {
            $tool.Description.Substring(0, 47) + "..."
        }
        else {
            $tool.Description.PadRight(50)
        }
        $RichTextBox.AppendText($description)
        
        # Installation Buttons
        if ($tool.Winget) {
            $RichTextBox.SelectionColor = [System.Drawing.Color]::Green
            $RichTextBox.SelectionBackColor = [System.Drawing.Color]::White
            $RichTextBox.SelectionFont = New-Object System.Drawing.Font("Consolas", 10, [System.Drawing.FontStyle]::Bold)
            $RichTextBox.AppendText("[Winget] ")
        }
        
        if ($tool.Choco) {
            $RichTextBox.SelectionColor = [System.Drawing.Color]::Purple
            $RichTextBox.SelectionBackColor = [System.Drawing.Color]::White
            $RichTextBox.SelectionFont = New-Object System.Drawing.Font("Consolas", 10, [System.Drawing.FontStyle]::Bold)
            $RichTextBox.AppendText("[Choco] ")
        }
        
        $RichTextBox.SelectionColor = [System.Drawing.Color]::Blue
        $RichTextBox.SelectionBackColor = [System.Drawing.Color]::White
        $RichTextBox.SelectionFont = New-Object System.Drawing.Font("Consolas", 10, [System.Drawing.FontStyle]::Bold)
        $RichTextBox.AppendText("[Web]")
        
        $RichTextBox.SelectionFont = New-Object System.Drawing.Font("Consolas", 10, [System.Drawing.FontStyle]::Regular)
        $RichTextBox.AppendText("`r`n")
        
        # Speichere die Endposition der Zeile
        $lineEnd = $RichTextBox.TextLength
        
        # Speichere die Tool-Informationen für den Hover-Effekt
        $toolInfo = @{
            Name        = $tool.Name
            Description = $tool.Description
            Version     = $tool.Version
            Category    = $tool.Category
            Tags        = $tool.Tags -join ", "
            Winget      = $tool.Winget
            Choco       = $tool.Choco
        }
        
        # Füge die Tool-Informationen zur globalen Liste hinzu
        $Global:linkPositions.Add(@{
                Start    = $lineStart
                End      = $lineEnd
                ToolInfo = $toolInfo
            })
        
        $rowCount++
    }
    
    $RichTextBox.SelectionColor = [System.Drawing.Color]::DarkBlue
    $RichTextBox.SelectionFont = New-Object System.Drawing.Font("Consolas", 10, [System.Drawing.FontStyle]::Regular)
    $RichTextBox.AppendText("`r`nInstallationsmöglichkeiten:`r`n")
    $RichTextBox.AppendText("[Winget] - Installation über Windows Package Manager`r`n")
    $RichTextBox.AppendText("[Choco] - Installation über Chocolatey`r`n")
    $RichTextBox.AppendText("[Web] - Download von der offiziellen Webseite`r`n")
    
    # Füge MouseMove-Event-Handler hinzu
    if (-not $script:tooltip) {
        $script:tooltip = New-Object System.Windows.Forms.ToolTip
        $script:tooltip.AutoPopDelay = 5000
        $script:tooltip.InitialDelay = 500
        $script:tooltip.ReshowDelay = 500
        $script:tooltip.ShowAlways = $true
    }
    
    $RichTextBox.Add_MouseMove({
            $clickPosition = $this.GetCharIndexFromPosition($this.PointToClient([System.Windows.Forms.Cursor]::Position))
        
            # Prüfe, ob die Maus über einer Tool-Zeile ist
            $currentLine = $this.GetLineFromCharIndex($clickPosition)
            $lineStart = $this.GetFirstCharIndexFromLine($currentLine)
        
            # Bestimme das Ende der Zeile
            if ($currentLine -lt $this.Lines.Count - 1) {
                $lineEnd = $this.GetFirstCharIndexFromLine($currentLine + 1) - 1
            }
            else {
                $lineEnd = $this.TextLength
            }
        
            # Prüfe, ob die Maus über einem Tool ist
            $isOverTool = $false
            $currentTool = $null
        
            foreach ($link in $Global:linkPositions) {
                if ($clickPosition -ge $link.Start -and $clickPosition -le $link.End) {
                    $isOverTool = $true
                    $currentTool = $link.ToolInfo
                    break
                }
            }
        
            # Ändere den Cursor und zeige Tooltip
            if ($isOverTool) {
                $this.Cursor = [System.Windows.Forms.Cursors]::Hand
            
                # Zeige Tooltip mit Tool-Informationen
                $tooltipText = "Tool: $($currentTool.Name)`nVersion: $($currentTool.Version)`nKategorie: $($currentTool.Category)`nBeschreibung: $($currentTool.Description)`nTags: $($currentTool.Tags)"
                if ($currentTool.Winget) { $tooltipText += "`nWinget: $($currentTool.Winget)" }
                if ($currentTool.Choco) { $tooltipText += "`nChoco: $($currentTool.Choco)" }
                $script:tooltip.SetToolTip($this, $tooltipText)
            }
            else {
                $this.Cursor = [System.Windows.Forms.Cursors]::Default
                $script:tooltip.SetToolTip($this, "")
            }
        })
    
    # Füge Click-Event-Handler hinzu
    $RichTextBox.Add_Click({
            $clickPosition = $this.GetCharIndexFromPosition($this.PointToClient([System.Windows.Forms.Cursor]::Position))
        
            foreach ($link in $Global:linkPositions) {
                if ($clickPosition -ge $link.Start -and $clickPosition -le $link.End) {
                    $tool = $link.ToolInfo
                
                    # Installationsmethode auswählen
                    $choices = New-Object System.Collections.Generic.List[string]
                    if ($tool.Winget) { $choices.Add("Winget") }
                    if ($tool.Choco) { $choices.Add("Chocolatey") }
                    $choices.Add("Web-Download")
                
                    $result = [System.Windows.Forms.MessageBox]::Show(
                        "Wie möchten Sie $($tool.Name) installieren?`n`n" +
                    ($choices -join " | "),
                        "Installation - $($tool.Name)",
                        [System.Windows.Forms.MessageBoxButtons]::YesNoCancel,
                        [System.Windows.Forms.MessageBoxIcon]::Question
                    )
                
                    switch ($result) {
                        'Yes' {
                            if ($tool.Winget) {
                                # Winget Installation
                                Start-Process "winget" -ArgumentList "install", $tool.Winget -Verb RunAs
                            }
                        }
                        'No' {
                            if ($tool.Choco) {
                                # Chocolatey Installation
                                Start-Process "choco" -ArgumentList "install", $tool.Choco, "-y" -Verb RunAs
                            }
                        }
                        'Cancel' {
                            # Web-Download
                            Start-Process $tool.DownloadUrl
                        }
                    }
                    break
                }
            }
        })
}

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
        [System.Drawing.Color]$textColor = [System.Drawing.Color]::DarkBlue
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

# Exportiere die Funktionen
Export-ModuleMember -Function Get-AllTools, Get-ToolsByCategory, Get-ToolsByTag, Get-ToolByName, Show-ToolList, Install-ToolPackage, Get-ToolDownload, Flatten, Update-ToolProgress 
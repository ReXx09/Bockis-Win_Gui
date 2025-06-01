# Import required assemblies
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Variables for theme state
$script:isDarkMode = $false

# Function to toggle between dark and light mode
function Set-Theme {
    param (
        [System.Windows.Forms.Form]$mainform,
        [System.Windows.Forms.Label]$header,
        [System.Windows.Forms.RichTextBox]$outputBox,
        [System.Windows.Forms.Button]$themeButton,
        [System.Windows.Forms.GroupBox[]]$groupBoxes,
        [System.Windows.Forms.TabControl]$tabControl = $null
    )
    
    $script:isDarkMode = -not $script:isDarkMode
    
    if ($script:isDarkMode) {
        # Dark Mode
        $mainform.BackColor = [System.Drawing.Color]::FromArgb(40, 44, 52)
        $header.ForeColor = [System.Drawing.Color]::White
        $outputBox.BackColor = [System.Drawing.Color]::FromArgb(30, 34, 42)
        $outputBox.ForeColor = [System.Drawing.Color]::White
        
        # Text bleibt gleich, nur das Icon
        $themeButton.BackColor = [System.Drawing.Color]::DarkSlateGray
        $themeButton.ForeColor = [System.Drawing.Color]::White
        
        # Update all buttons' colors
        foreach ($control in $mainform.Controls) {
            if ($control -is [System.Windows.Forms.Button] -and $control -ne $themeButton -and -not $control.Text.Equals("I")) {
                $control.BackColor = [System.Drawing.Color]::DarkSlateGray
                $control.ForeColor = [System.Drawing.Color]::White
            }
        }
        
        # Update group box appearances
        foreach ($groupBox in $groupBoxes) {
            # Prüfe zuerst, ob das GroupBox-Objekt nicht null ist
            if ($null -ne $groupBox) {
                # Verwende Reflection, um zu prüfen, ob die Text-Property existiert
                if ($groupBox.PSObject.Properties.Name -contains "Text") {
                    $currentText = $groupBox.Text
                    $groupBox.Text = $currentText
                }
                else {
                    # Alternativ: Refresh der Komponente erzwingen
                    $groupBox.Refresh()
                }
                
                # Update buttons within the group box
                foreach ($control in $groupBox.Controls) {
                    if ($control -is [System.Windows.Forms.Button] -and -not $control.Text.Equals("I")) {
                        $control.BackColor = [System.Drawing.Color]::DarkSlateGray
                        $control.ForeColor = [System.Drawing.Color]::White
                    }
                }
            }
        }

        # Update TabControl wenn vorhanden
        if ($null -ne $tabControl) {
            foreach ($tabPage in $tabControl.TabPages) {
                $tabPage.BackColor = [System.Drawing.Color]::FromArgb(45, 49, 57)
                $tabPage.ForeColor = [System.Drawing.Color]::White
                
                # Update Controls in TabPages
                foreach ($control in $tabPage.Controls) {
                    if ($control -is [System.Windows.Forms.Panel]) {
                        $control.BackColor = [System.Drawing.Color]::FromArgb(45, 49, 57)
                        
                        # Update Controls im Panel
                        foreach ($panelControl in $control.Controls) {
                            if ($panelControl -is [System.Windows.Forms.Button]) {
                                $panelControl.BackColor = [System.Drawing.Color]::DarkSlateGray
                                $panelControl.ForeColor = [System.Drawing.Color]::White
                            }
                            elseif ($panelControl -is [System.Windows.Forms.Label]) {
                                $panelControl.ForeColor = [System.Drawing.Color]::White
                            }
                        }
                    }
                }
            }
        }
    }
    else {
        # Light Mode
        $mainform.BackColor = [System.Drawing.Color]::LightCyan
        $header.ForeColor = [System.Drawing.Color]::Black
        $outputBox.BackColor = [System.Drawing.Color]::White
        $outputBox.ForeColor = [System.Drawing.Color]::Black
        
        # Text bleibt gleich, nur das Icon
        $themeButton.BackColor = [System.Drawing.Color]::LightSteelBlue
        $themeButton.ForeColor = [System.Drawing.Color]::Black
        
        # Restore all buttons' colors
        foreach ($control in $mainform.Controls) {
            if ($control -is [System.Windows.Forms.Button] -and $control -ne $themeButton -and -not $control.Text.Equals("I")) {
                $control.BackColor = [System.Drawing.Color]::LightSeaGreen
                $control.ForeColor = [System.Drawing.Color]::Black
            }
        }
        
        # Update group box appearances
        foreach ($groupBox in $groupBoxes) {
            # Prüfe zuerst, ob das GroupBox-Objekt nicht null ist
            if ($null -ne $groupBox) {
                # Verwende Reflection, um zu prüfen, ob die Text-Property existiert
                if ($groupBox.PSObject.Properties.Name -contains "Text") {
                    $currentText = $groupBox.Text
                    $groupBox.Text = $currentText
                }
                else {
                    # Alternativ: Refresh der Komponente erzwingen
                    $groupBox.Refresh()
                }
                
                # Update buttons within the group box
                foreach ($control in $groupBox.Controls) {
                    if ($control -is [System.Windows.Forms.Button] -and -not $control.Text.Equals("I")) {
                        $control.BackColor = [System.Drawing.Color]::LightSeaGreen
                        $control.ForeColor = [System.Drawing.Color]::Black
                    }
                }
            }
        }

        # Update TabControl wenn vorhanden
        if ($null -ne $tabControl) {
            foreach ($tabPage in $tabControl.TabPages) {
                $tabPage.BackColor = [System.Drawing.Color]::WhiteSmoke
                $tabPage.ForeColor = [System.Drawing.Color]::Black
                
                # Update Controls in TabPages
                foreach ($control in $tabPage.Controls) {
                    if ($control -is [System.Windows.Forms.Panel]) {
                        $control.BackColor = [System.Drawing.Color]::WhiteSmoke
                        
                        # Update Controls im Panel
                        foreach ($panelControl in $control.Controls) {
                            if ($panelControl -is [System.Windows.Forms.Button]) {
                                $panelControl.BackColor = [System.Drawing.Color]::LightSeaGreen
                                $panelControl.ForeColor = [System.Drawing.Color]::Black
                            }
                            elseif ($panelControl -is [System.Windows.Forms.Label]) {
                                $panelControl.ForeColor = [System.Drawing.Color]::Black
                            }
                        }
                    }
                }
            }
        }
    }
    
    return $script:isDarkMode
}

# Get current theme state
function Get-ThemeState {
    return $script:isDarkMode
}

# Function for uniform button hover effect
function Set-UniformButtonHoverEffect {
    param (
        [System.Windows.Forms.Button]$Button
    )
    
    # Sicherstellen, dass der Button existiert
    if ($null -eq $Button) {
        Write-Host "Warnung: Button ist null und kann nicht modifiziert werden."
        return
    }
    
    # Speichere die ursprünglichen Farben im Tag des Buttons
    # Wir erstellen ein Hashtable, um sowohl die Farben als auch ggf. den ursprünglichen Tag-Wert zu speichern
    $originalTag = $Button.Tag
    $colorInfo = @{
        OriginalBackColor = $Button.BackColor
        OriginalForeColor = $Button.ForeColor
        OriginalTag       = $originalTag
    }
    $Button.Tag = $colorInfo
    
    # Hover-Effekt hinzufügen
    $Button.Add_MouseEnter({
            # Sicherstellen, dass Tag-Informationen verfügbar sind
            if ($null -ne $this.Tag -and $this.Tag -is [Hashtable]) {
                $colorInfo = $this.Tag
                $originalBackColor = $colorInfo.OriginalBackColor
            
                # Farbe etwas dunkler/heller machen für den Hover-Effekt
                if ($null -ne $originalBackColor) {
                    # Standardmäßig dunkler machen
                    try {
                        # Einfacher Ansatz ohne GetBrightness
                        $this.BackColor = [System.Drawing.Color]::FromArgb(
                            [math]::Max(0, $originalBackColor.R - 30),
                            [math]::Max(0, $originalBackColor.G - 30),
                            [math]::Max(0, $originalBackColor.B - 30)
                        )
                    }
                    catch {
                        # Fallback bei Fehler
                        $this.BackColor = [System.Drawing.Color]::LightGray
                    }
                }
            }
        })
    
    $Button.Add_MouseLeave({
            # Zurück zu Original-Farben
            if ($null -ne $this.Tag -and $this.Tag -is [Hashtable]) {
                $colorInfo = $this.Tag
                if ($null -ne $colorInfo.OriginalBackColor) {
                    $this.BackColor = $colorInfo.OriginalBackColor
                }
                if ($null -ne $colorInfo.OriginalForeColor) {
                    $this.ForeColor = $colorInfo.OriginalForeColor
                }
            }
        })
}

# Function to ensure consistent button styling
function Set-ButtonStyle {
    param (
        [System.Windows.Forms.Button]$Button
    )
    # Stelle sicher, dass der Text ohne führende Leerzeichen beginnt
    $textWithEmoji = $Button.Text.TrimStart()
    
    # Emoji extrahieren (erste 2 Zeichen)
    if ($textWithEmoji.Length -ge 2) {
        # Prüfe, ob das erste Zeichen ein Emoji ist (es kann mehr als 1 Code-Unit sein)
        $emojiLength = if ([char]::IsSurrogate($textWithEmoji[0])) { 2 } else { 1 }
        $emoji = $textWithEmoji.Substring(0, $emojiLength)  
        $text = $textWithEmoji.Substring($emojiLength).Trim()  # Restlichen Text ohne Emoji
        
        # Konsistentes Styling anwenden
        $Button.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
        $Button.Text = "$emoji $text"  # Ein Leerzeichen zwischen Emoji und Text
        $Button.UseMnemonic = $false   # Verhindert, dass & als Tastaturkürzel interpretiert wird
        $Button.Padding = New-Object System.Windows.Forms.Padding(5, 0, 0, 0)  # Padding links
        
        # Stelle sicher, dass alle Buttons eine einheitliche Schriftart haben
        $Button.Font = New-Object System.Drawing.Font("Segoe UI Emoji", 11, [System.Drawing.FontStyle]::Regular)
        
        # Stelle sicher, dass alle Buttons breit genug sind
        $minWidth = 170
        # Vergleiche mit -le (less than or equal) statt mit <
        if ($Button.Width -le $minWidth) {
            $Button.Size = New-Object System.Drawing.Size($minWidth, $Button.Height)
        }
    }
}

# Create a modern info button with hover effect and rounded corners
function New-ModernInfoButton {
    param (
        [int]$x = 0,
        [int]$y = 0,
        [scriptblock]$clickAction
    )
    
    $infoButton = New-Object System.Windows.Forms.Button
    $infoButton.Text = "i"
    $infoButton.Size = New-Object System.Drawing.Size(20, 20)
    $infoButton.Location = New-Object System.Drawing.Point($x, $y)
    $infoButton.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $infoButton.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    $infoButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $infoButton.FlatAppearance.BorderSize = 0
    $infoButton.BackColor = [System.Drawing.Color]::DeepSkyBlue
    $infoButton.ForeColor = [System.Drawing.Color]::White
    $infoButton.Cursor = [System.Windows.Forms.Cursors]::Hand
    
    # Hover-Effekt
    $infoButton.Add_MouseEnter({
            $this.BackColor = [System.Drawing.Color]::DodgerBlue
        })
    
    $infoButton.Add_MouseLeave({
            $this.BackColor = [System.Drawing.Color]::DeepSkyBlue
        })
    
    # Click-Aktion
    if ($null -ne $clickAction) {
        $infoButton.Add_Click($clickAction)
    }
    
    return $infoButton
}

# Alias für die alte Funktionsbezeichnung, um abwärtskompatibel zu bleiben
Set-Alias -Name Create-ModernInfoButton -Value New-ModernInfoButton

# Export functions and aliases
Export-ModuleMember -Function Set-Theme, Get-ThemeState, Set-UniformButtonHoverEffect, Set-ButtonStyle, New-ModernInfoButton
Export-ModuleMember -Alias Create-ModernInfoButton 

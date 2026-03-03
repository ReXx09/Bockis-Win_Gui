# FarbpaletteViewer.ps1
# Ein kleines Tool, um verschiedene Farben zu vergleichen

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Erstelle ein Formular
$form = New-Object System.Windows.Forms.Form
$form.Text = "Farbpalette Viewer"
$form.Size = New-Object System.Drawing.Size(1000, 700)
$form.StartPosition = "CenterScreen"
$form.BackColor = [System.Drawing.Color]::White

# Erstelle ein TabControl für verschiedene Farbkategorien
$tabControl = New-Object System.Windows.Forms.TabControl
$tabControl.Dock = [System.Windows.Forms.DockStyle]::Fill
$form.Controls.Add($tabControl)

# Tab für vordefinierte dunkle Farben
$tabPredefDark = New-Object System.Windows.Forms.TabPage
$tabPredefDark.Text = "Vordefinierte Dunkelfarben"
$tabControl.TabPages.Add($tabPredefDark)

# Tab für Schwarztöne
$tabBlacks = New-Object System.Windows.Forms.TabPage
$tabBlacks.Text = "Schwarztöne"
$tabControl.TabPages.Add($tabBlacks)

# Tab für Grautöne
$tabGrays = New-Object System.Windows.Forms.TabPage
$tabGrays.Text = "Grautöne"
$tabControl.TabPages.Add($tabGrays)

# Tab für Blautöne
$tabBlues = New-Object System.Windows.Forms.TabPage
$tabBlues.Text = "Blautöne"
$tabControl.TabPages.Add($tabBlues)

# Tab für vordefinierte Grautöne
$tabPredefGray = New-Object System.Windows.Forms.TabPage
$tabPredefGray.Text = "Vordefinierte Grautöne"
$tabControl.TabPages.Add($tabPredefGray)

# Tab für vordefinierte Blautöne
$tabPredefBlue = New-Object System.Windows.Forms.TabPage
$tabPredefBlue.Text = "Vordefinierte Blautöne"
$tabControl.TabPages.Add($tabPredefBlue)

# Tab für andere vordefinierte Farben
$tabPredefOther = New-Object System.Windows.Forms.TabPage
$tabPredefOther.Text = "Andere vordefinierte Farben"
$tabControl.TabPages.Add($tabPredefOther)

# Tab für benutzerdefinierte Farben
$tabCustom = New-Object System.Windows.Forms.TabPage
$tabCustom.Text = "Benutzerdefinierte Farben"
$tabControl.TabPages.Add($tabCustom)

# Funktion zum Erstellen eines Farbpanels
function New-ColorPanel {
    param (
        [System.Drawing.Color]$color,
        [string]$name,
        [int]$x,
        [int]$y,
        [int]$width = 180,
        [int]$height = 80,
        [System.Windows.Forms.Control]$parent
    )
    
    # Erstelle Panel
    $panel = New-Object System.Windows.Forms.Panel
    $panel.Location = New-Object System.Drawing.Point($x, $y)
    $panel.Size = New-Object System.Drawing.Size($width, $height)
    $panel.BackColor = $color
    $panel.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
    $parent.Controls.Add($panel)
    
    # Erstelle Label mit Farbname und RGB-Werten
    $label = New-Object System.Windows.Forms.Label
    $labelText = "$name`r`nR: $($color.R), G: $($color.G), B: $($color.B)"
    $label.Text = $labelText
    $label.AutoSize = $true
    
    # Bestimme optimale Textfarbe basierend auf Hintergrundhelligkeit
    $brightness = ($color.R * 0.299 + $color.G * 0.587 + $color.B * 0.114)
    if ($brightness -lt 130) {
        $label.ForeColor = [System.Drawing.Color]::White
    } else {
        $label.ForeColor = [System.Drawing.Color]::Black
    }
    
    $label.Location = New-Object System.Drawing.Point(5, 5)
    $label.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $panel.Controls.Add($label)
    
    # Füge Kopier-Button hinzu
    $copyButton = New-Object System.Windows.Forms.Button
    $copyButton.Text = "Code kopieren"
    $copyButton.Size = New-Object System.Drawing.Size(90, 25)
    # Hier Position des Buttons festlegen
    $buttonX = $width - 95
    $buttonY = $height - 30
    $copyButton.Location = New-Object System.Drawing.Point($buttonX, $buttonY)
    $copyButton.Font = New-Object System.Drawing.Font("Segoe UI", 8)
    $copyButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    
    # Bestimme Button-Farben basierend auf Hintergrundhelligkeit
    if ($brightness -lt 130) {
        $copyButton.BackColor = [System.Drawing.Color]::FromArgb(60, 60, 60)
        $copyButton.ForeColor = [System.Drawing.Color]::White
    } else {
        $copyButton.BackColor = [System.Drawing.Color]::LightGray
        $copyButton.ForeColor = [System.Drawing.Color]::Black
    }
    
    # Farbcode zum Kopieren
    if ($name -match "FromArgb") {
        $colorCode = "[System.Drawing.Color]::FromArgb($($color.R), $($color.G), $($color.B))"
    } else {
        $colorCode = "[System.Drawing.Color]::$name"
    }
    
    $copyButton.Add_Click({
        [System.Windows.Forms.Clipboard]::SetText($colorCode)
        $this.Text = "Kopiert!"
        $timer = New-Object System.Windows.Forms.Timer
        $timer.Interval = 1000
        $timer.Add_Tick({
            $copyButton.Text = "Code kopieren"
            $timer.Stop()
            $timer.Dispose()
        })
        $timer.Start()
    })
    
    $panel.Controls.Add($copyButton)
    
    return $panel
}

# Schwarztöne definieren
$blacks = @(
    @{Color = [System.Drawing.Color]::Black; Name = "Black"},
    @{Color = [System.Drawing.Color]::FromArgb(10, 10, 10); Name = "FromArgb(10, 10, 10)"},
    @{Color = [System.Drawing.Color]::FromArgb(18, 18, 18); Name = "FromArgb(18, 18, 18)"},
    @{Color = [System.Drawing.Color]::FromArgb(20, 20, 20); Name = "FromArgb(20, 20, 20)"},
    @{Color = [System.Drawing.Color]::FromArgb(25, 25, 25); Name = "FromArgb(25, 25, 25)"},
    @{Color = [System.Drawing.Color]::FromArgb(28, 28, 32); Name = "FromArgb(28, 28, 32)"},
    @{Color = [System.Drawing.Color]::FromArgb(30, 30, 30); Name = "FromArgb(30, 30, 30)"},
    @{Color = [System.Drawing.Color]::FromArgb(30, 34, 42); Name = "FromArgb(30, 34, 42)"},
    @{Color = [System.Drawing.Color]::FromArgb(32, 32, 36); Name = "FromArgb(32, 32, 36)"},
    @{Color = [System.Drawing.Color]::FromArgb(35, 35, 40); Name = "FromArgb(35, 35, 40)"},
    @{Color = [System.Drawing.Color]::FromArgb(40, 40, 40); Name = "FromArgb(40, 40, 40)"},
    @{Color = [System.Drawing.Color]::FromArgb(40, 44, 52); Name = "FromArgb(40, 44, 52)"}
)

# Grautöne definieren
$grays = @(
    @{Color = [System.Drawing.Color]::DarkSlateGray; Name = "DarkSlateGray"},
    @{Color = [System.Drawing.Color]::DimGray; Name = "DimGray"},
    @{Color = [System.Drawing.Color]::Gray; Name = "Gray"},
    @{Color = [System.Drawing.Color]::DarkGray; Name = "DarkGray"},
    @{Color = [System.Drawing.Color]::LightGray; Name = "LightGray"},
    @{Color = [System.Drawing.Color]::Silver; Name = "Silver"},
    @{Color = [System.Drawing.Color]::FromArgb(45, 45, 48); Name = "FromArgb(45, 45, 48)"},
    @{Color = [System.Drawing.Color]::FromArgb(50, 50, 55); Name = "FromArgb(50, 50, 55)"},
    @{Color = [System.Drawing.Color]::FromArgb(60, 60, 60); Name = "FromArgb(60, 60, 60)"},
    @{Color = [System.Drawing.Color]::FromArgb(70, 70, 70); Name = "FromArgb(70, 70, 70)"},
    @{Color = [System.Drawing.Color]::FromArgb(80, 80, 80); Name = "FromArgb(80, 80, 80)"},
    @{Color = [System.Drawing.Color]::FromArgb(90, 90, 90); Name = "FromArgb(90, 90, 90)"}
)

# Blautöne definieren
$blues = @(
    @{Color = [System.Drawing.Color]::MidnightBlue; Name = "MidnightBlue"},
    @{Color = [System.Drawing.Color]::Navy; Name = "Navy"},
    @{Color = [System.Drawing.Color]::DarkBlue; Name = "DarkBlue"},
    @{Color = [System.Drawing.Color]::FromArgb(27, 27, 50); Name = "FromArgb(27, 27, 50)"},
    @{Color = [System.Drawing.Color]::FromArgb(25, 25, 65); Name = "FromArgb(25, 25, 65)"},
    @{Color = [System.Drawing.Color]::FromArgb(25, 33, 44); Name = "FromArgb(25, 33, 44)"},
    @{Color = [System.Drawing.Color]::FromArgb(30, 41, 59); Name = "FromArgb(30, 41, 59)"},
    @{Color = [System.Drawing.Color]::FromArgb(35, 47, 62); Name = "FromArgb(35, 47, 62)"},
    @{Color = [System.Drawing.Color]::FromArgb(40, 52, 70); Name = "FromArgb(40, 52, 70)"},
    @{Color = [System.Drawing.Color]::FromArgb(44, 57, 75); Name = "FromArgb(44, 57, 75)"},
    @{Color = [System.Drawing.Color]::FromArgb(30, 30, 70); Name = "FromArgb(30, 30, 70)"},
    @{Color = [System.Drawing.Color]::SteelBlue; Name = "SteelBlue"}
)

# Vordefinierte dunkle Farben
$predefDark = @(
    @{Color = [System.Drawing.Color]::Black; Name = "Black"},
    @{Color = [System.Drawing.Color]::DarkSlateGray; Name = "DarkSlateGray"},
    @{Color = [System.Drawing.Color]::DarkSlateBlue; Name = "DarkSlateBlue"},
    @{Color = [System.Drawing.Color]::MidnightBlue; Name = "MidnightBlue"},
    @{Color = [System.Drawing.Color]::Navy; Name = "Navy"},
    @{Color = [System.Drawing.Color]::DarkBlue; Name = "DarkBlue"},
    @{Color = [System.Drawing.Color]::DimGray; Name = "DimGray"},
    @{Color = [System.Drawing.Color]::Indigo; Name = "Indigo"},
    @{Color = [System.Drawing.Color]::Maroon; Name = "Maroon"},
    @{Color = [System.Drawing.Color]::DarkGreen; Name = "DarkGreen"},
    @{Color = [System.Drawing.Color]::DarkRed; Name = "DarkRed"},
    @{Color = [System.Drawing.Color]::DarkViolet; Name = "DarkViolet"}
)

# Vordefinierte Grautöne
$predefGray = @(
    @{Color = [System.Drawing.Color]::DimGray; Name = "DimGray"},
    @{Color = [System.Drawing.Color]::Gray; Name = "Gray"},
    @{Color = [System.Drawing.Color]::DarkGray; Name = "DarkGray"},
    @{Color = [System.Drawing.Color]::LightGray; Name = "LightGray"},
    @{Color = [System.Drawing.Color]::SlateGray; Name = "SlateGray"},
    @{Color = [System.Drawing.Color]::LightSlateGray; Name = "LightSlateGray"},
    @{Color = [System.Drawing.Color]::Silver; Name = "Silver"},
    @{Color = [System.Drawing.Color]::Gainsboro; Name = "Gainsboro"}
)

# Vordefinierte Blautöne
$predefBlue = @(
    @{Color = [System.Drawing.Color]::MidnightBlue; Name = "MidnightBlue"},
    @{Color = [System.Drawing.Color]::Navy; Name = "Navy"},
    @{Color = [System.Drawing.Color]::DarkBlue; Name = "DarkBlue"},
    @{Color = [System.Drawing.Color]::MediumBlue; Name = "MediumBlue"},
    @{Color = [System.Drawing.Color]::Blue; Name = "Blue"},
    @{Color = [System.Drawing.Color]::RoyalBlue; Name = "RoyalBlue"},
    @{Color = [System.Drawing.Color]::SteelBlue; Name = "SteelBlue"},
    @{Color = [System.Drawing.Color]::DodgerBlue; Name = "DodgerBlue"},
    @{Color = [System.Drawing.Color]::DeepSkyBlue; Name = "DeepSkyBlue"},
    @{Color = [System.Drawing.Color]::CornflowerBlue; Name = "CornflowerBlue"},
    @{Color = [System.Drawing.Color]::SlateBlue; Name = "SlateBlue"},
    @{Color = [System.Drawing.Color]::DarkSlateBlue; Name = "DarkSlateBlue"}
)

# Andere vordefinierte dunkle Farben
$predefOther = @(
    @{Color = [System.Drawing.Color]::DarkGreen; Name = "DarkGreen"},
    @{Color = [System.Drawing.Color]::DarkOliveGreen; Name = "DarkOliveGreen"},
    @{Color = [System.Drawing.Color]::DarkCyan; Name = "DarkCyan"},
    @{Color = [System.Drawing.Color]::DarkOrchid; Name = "DarkOrchid"},
    @{Color = [System.Drawing.Color]::DarkViolet; Name = "DarkViolet"},
    @{Color = [System.Drawing.Color]::DarkMagenta; Name = "DarkMagenta"},
    @{Color = [System.Drawing.Color]::DarkRed; Name = "DarkRed"},
    @{Color = [System.Drawing.Color]::DarkOrange; Name = "DarkOrange"},
    @{Color = [System.Drawing.Color]::SaddleBrown; Name = "SaddleBrown"},
    @{Color = [System.Drawing.Color]::Sienna; Name = "Sienna"},
    @{Color = [System.Drawing.Color]::Brown; Name = "Brown"},
    @{Color = [System.Drawing.Color]::Maroon; Name = "Maroon"}
)

# Benutzerdefinierte Farben
$customs = @(
    @{Color = [System.Drawing.Color]::FromArgb(24, 26, 31); Name = "FromArgb(24, 26, 31)"},  # GitHub Dark
    @{Color = [System.Drawing.Color]::FromArgb(13, 17, 23); Name = "FromArgb(13, 17, 23)"},  # GitHub Dark Dimmed
    @{Color = [System.Drawing.Color]::FromArgb(22, 27, 34); Name = "FromArgb(22, 27, 34)"},  # GitHub Dark Default
    @{Color = [System.Drawing.Color]::FromArgb(36, 41, 46); Name = "FromArgb(36, 41, 46)"},  # GitHub Dark Lighter
    @{Color = [System.Drawing.Color]::FromArgb(30, 30, 30); Name = "FromArgb(30, 30, 30)"},  # VS Code Dark
    @{Color = [System.Drawing.Color]::FromArgb(21, 32, 43); Name = "FromArgb(21, 32, 43)"},  # Twitter Dark
    @{Color = [System.Drawing.Color]::FromArgb(19, 20, 24); Name = "FromArgb(19, 20, 24)"},  # Discord
    @{Color = [System.Drawing.Color]::FromArgb(15, 15, 15); Name = "FromArgb(15, 15, 15)"},  # YouTube Dark
    @{Color = [System.Drawing.Color]::FromArgb(28, 28, 30); Name = "FromArgb(28, 28, 30)"},  # iOS Dark
    @{Color = [System.Drawing.Color]::FromArgb(18, 18, 18); Name = "FromArgb(18, 18, 18)"},  # Spotify Dark
    @{Color = [System.Drawing.Color]::FromArgb(33, 33, 33); Name = "FromArgb(33, 33, 33)"},  # Material Dark
    @{Color = [System.Drawing.Color]::FromArgb(32, 33, 36); Name = "FromArgb(32, 33, 36)"}   # Google Dark
)

# Farben zu den Tabs hinzufügen
$panelWidth = 180
$panelHeight = 80
$margin = 10
$itemsPerRow = 4

# Vordefinierte dunkle Farben hinzufügen
$scrollPanelPredefDark = New-Object System.Windows.Forms.Panel
$scrollPanelPredefDark.AutoScroll = $true
$scrollPanelPredefDark.Dock = [System.Windows.Forms.DockStyle]::Fill
$tabPredefDark.Controls.Add($scrollPanelPredefDark)

for ($i = 0; $i -lt $predefDark.Count; $i++) {
    $row = [math]::Floor($i / $itemsPerRow)
    $col = $i % $itemsPerRow
    $x = $col * ($panelWidth + $margin) + $margin
    $y = $row * ($panelHeight + $margin) + $margin
    $null = New-ColorPanel -color $predefDark[$i].Color -name $predefDark[$i].Name -x $x -y $y -width $panelWidth -height $panelHeight -parent $scrollPanelPredefDark
}

# Schwarztöne hinzufügen
$scrollPanelBlacks = New-Object System.Windows.Forms.Panel
$scrollPanelBlacks.AutoScroll = $true
$scrollPanelBlacks.Dock = [System.Windows.Forms.DockStyle]::Fill
$tabBlacks.Controls.Add($scrollPanelBlacks)

for ($i = 0; $i -lt $blacks.Count; $i++) {
    $row = [math]::Floor($i / $itemsPerRow)
    $col = $i % $itemsPerRow
    $x = $col * ($panelWidth + $margin) + $margin
    $y = $row * ($panelHeight + $margin) + $margin
    $null = New-ColorPanel -color $blacks[$i].Color -name $blacks[$i].Name -x $x -y $y -width $panelWidth -height $panelHeight -parent $scrollPanelBlacks
}

# Grautöne hinzufügen
$scrollPanelGrays = New-Object System.Windows.Forms.Panel
$scrollPanelGrays.AutoScroll = $true
$scrollPanelGrays.Dock = [System.Windows.Forms.DockStyle]::Fill
$tabGrays.Controls.Add($scrollPanelGrays)

for ($i = 0; $i -lt $grays.Count; $i++) {
    $row = [math]::Floor($i / $itemsPerRow)
    $col = $i % $itemsPerRow
    $x = $col * ($panelWidth + $margin) + $margin
    $y = $row * ($panelHeight + $margin) + $margin
    $null = New-ColorPanel -color $grays[$i].Color -name $grays[$i].Name -x $x -y $y -width $panelWidth -height $panelHeight -parent $scrollPanelGrays
}

# Blautöne hinzufügen
$scrollPanelBlues = New-Object System.Windows.Forms.Panel
$scrollPanelBlues.AutoScroll = $true
$scrollPanelBlues.Dock = [System.Windows.Forms.DockStyle]::Fill
$tabBlues.Controls.Add($scrollPanelBlues)

for ($i = 0; $i -lt $blues.Count; $i++) {
    $row = [math]::Floor($i / $itemsPerRow)
    $col = $i % $itemsPerRow
    $x = $col * ($panelWidth + $margin) + $margin
    $y = $row * ($panelHeight + $margin) + $margin
    $null = New-ColorPanel -color $blues[$i].Color -name $blues[$i].Name -x $x -y $y -width $panelWidth -height $panelHeight -parent $scrollPanelBlues
}

# Vordefinierte Grautöne hinzufügen
$scrollPanelPredefGray = New-Object System.Windows.Forms.Panel
$scrollPanelPredefGray.AutoScroll = $true
$scrollPanelPredefGray.Dock = [System.Windows.Forms.DockStyle]::Fill
$tabPredefGray.Controls.Add($scrollPanelPredefGray)

for ($i = 0; $i -lt $predefGray.Count; $i++) {
    $row = [math]::Floor($i / $itemsPerRow)
    $col = $i % $itemsPerRow
    $x = $col * ($panelWidth + $margin) + $margin
    $y = $row * ($panelHeight + $margin) + $margin
    $null = New-ColorPanel -color $predefGray[$i].Color -name $predefGray[$i].Name -x $x -y $y -width $panelWidth -height $panelHeight -parent $scrollPanelPredefGray
}

# Vordefinierte Blautöne hinzufügen
$scrollPanelPredefBlue = New-Object System.Windows.Forms.Panel
$scrollPanelPredefBlue.AutoScroll = $true
$scrollPanelPredefBlue.Dock = [System.Windows.Forms.DockStyle]::Fill
$tabPredefBlue.Controls.Add($scrollPanelPredefBlue)

for ($i = 0; $i -lt $predefBlue.Count; $i++) {
    $row = [math]::Floor($i / $itemsPerRow)
    $col = $i % $itemsPerRow
    $x = $col * ($panelWidth + $margin) + $margin
    $y = $row * ($panelHeight + $margin) + $margin
    $null = New-ColorPanel -color $predefBlue[$i].Color -name $predefBlue[$i].Name -x $x -y $y -width $panelWidth -height $panelHeight -parent $scrollPanelPredefBlue
}

# Andere vordefinierte dunkle Farben hinzufügen
$scrollPanelPredefOther = New-Object System.Windows.Forms.Panel
$scrollPanelPredefOther.AutoScroll = $true
$scrollPanelPredefOther.Dock = [System.Windows.Forms.DockStyle]::Fill
$tabPredefOther.Controls.Add($scrollPanelPredefOther)

for ($i = 0; $i -lt $predefOther.Count; $i++) {
    $row = [math]::Floor($i / $itemsPerRow)
    $col = $i % $itemsPerRow
    $x = $col * ($panelWidth + $margin) + $margin
    $y = $row * ($panelHeight + $margin) + $margin
    $null = New-ColorPanel -color $predefOther[$i].Color -name $predefOther[$i].Name -x $x -y $y -width $panelWidth -height $panelHeight -parent $scrollPanelPredefOther
}

# Benutzerdefinierte Farben hinzufügen
$scrollPanelCustom = New-Object System.Windows.Forms.Panel
$scrollPanelCustom.AutoScroll = $true
$scrollPanelCustom.Dock = [System.Windows.Forms.DockStyle]::Fill
$tabCustom.Controls.Add($scrollPanelCustom)

for ($i = 0; $i -lt $customs.Count; $i++) {
    $row = [math]::Floor($i / $itemsPerRow)
    $col = $i % $itemsPerRow
    $x = $col * ($panelWidth + $margin) + $margin
    $y = $row * ($panelHeight + $margin) + $margin
    $null = New-ColorPanel -color $customs[$i].Color -name $customs[$i].Name -x $x -y $y -width $panelWidth -height $panelHeight -parent $scrollPanelCustom
}

# Füge eine benutzerdefinierte Farbauswahl hinzu
$colorPickerPanel = New-Object System.Windows.Forms.Panel
$colorPickerPanel.Dock = [System.Windows.Forms.DockStyle]::Bottom
$colorPickerPanel.Height = 100
$colorPickerPanel.BackColor = [System.Drawing.Color]::WhiteSmoke
$colorPickerPanel.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
$scrollPanelCustom.Controls.Add($colorPickerPanel)

$lblR = New-Object System.Windows.Forms.Label
$lblR.Text = "R:"
$lblR.Location = New-Object System.Drawing.Point(15, 15)
$lblR.AutoSize = $true
$colorPickerPanel.Controls.Add($lblR)

$numR = New-Object System.Windows.Forms.NumericUpDown
$numR.Location = New-Object System.Drawing.Point(35, 13)
$numR.Size = New-Object System.Drawing.Size(60, 20)
$numR.Minimum = 0
$numR.Maximum = 255
$numR.Value = 30
$colorPickerPanel.Controls.Add($numR)

$lblG = New-Object System.Windows.Forms.Label
$lblG.Text = "G:"
$lblG.Location = New-Object System.Drawing.Point(115, 15)
$lblG.AutoSize = $true
$colorPickerPanel.Controls.Add($lblG)

$numG = New-Object System.Windows.Forms.NumericUpDown
$numG.Location = New-Object System.Drawing.Point(135, 13)
$numG.Size = New-Object System.Drawing.Size(60, 20)
$numG.Minimum = 0
$numG.Maximum = 255
$numG.Value = 34
$colorPickerPanel.Controls.Add($numG)

$lblB = New-Object System.Windows.Forms.Label
$lblB.Text = "B:"
$lblB.Location = New-Object System.Drawing.Point(215, 15)
$lblB.AutoSize = $true
$colorPickerPanel.Controls.Add($lblB)

$numB = New-Object System.Windows.Forms.NumericUpDown
$numB.Location = New-Object System.Drawing.Point(235, 13)
$numB.Size = New-Object System.Drawing.Size(60, 20)
$numB.Minimum = 0
$numB.Maximum = 255
$numB.Value = 42
$colorPickerPanel.Controls.Add($numB)

$previewPanel = New-Object System.Windows.Forms.Panel
$previewPanel.Location = New-Object System.Drawing.Point(315, 10)
$previewPanel.Size = New-Object System.Drawing.Size(80, 30)
$previewPanel.BackColor = [System.Drawing.Color]::FromArgb(30, 34, 42)
$previewPanel.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
$colorPickerPanel.Controls.Add($previewPanel)

$btnAdd = New-Object System.Windows.Forms.Button
$btnAdd.Text = "Vorschau aktualisieren"
$btnAdd.Location = New-Object System.Drawing.Point(415, 13)
$btnAdd.Size = New-Object System.Drawing.Size(140, 25)
$colorPickerPanel.Controls.Add($btnAdd)

$txtCode = New-Object System.Windows.Forms.TextBox
$txtCode.Location = New-Object System.Drawing.Point(15, 50)
$txtCode.Size = New-Object System.Drawing.Size(380, 23)
$txtCode.ReadOnly = $true
$txtCode.Text = "[System.Drawing.Color]::FromArgb(30, 34, 42)"
$colorPickerPanel.Controls.Add($txtCode)

$btnCopy = New-Object System.Windows.Forms.Button
$btnCopy.Text = "Code kopieren"
$btnCopy.Location = New-Object System.Drawing.Point(415, 48)
$btnCopy.Size = New-Object System.Drawing.Size(140, 25)
$colorPickerPanel.Controls.Add($btnCopy)

# Event-Handler
$updatePreview = {
    $r = [int]$numR.Value
    $g = [int]$numG.Value
    $b = [int]$numB.Value
    
    $color = [System.Drawing.Color]::FromArgb($r, $g, $b)
    $previewPanel.BackColor = $color
    $txtCode.Text = "[System.Drawing.Color]::FromArgb($r, $g, $b)"
}

$numR.Add_ValueChanged($updatePreview)
$numG.Add_ValueChanged($updatePreview)
$numB.Add_ValueChanged($updatePreview)

$btnAdd.Add_Click($updatePreview)

$btnCopy.Add_Click({
    [System.Windows.Forms.Clipboard]::SetText($txtCode.Text)
    $btnCopy.Text = "Kopiert!"
    $timer = New-Object System.Windows.Forms.Timer
    $timer.Interval = 1000
    $timer.Add_Tick({
        $btnCopy.Text = "Code kopieren"
        $timer.Stop()
        $timer.Dispose()
    })
    $timer.Start()
})

# Fenster anzeigen
$form.Add_Shown({$form.Activate()})
[void]$form.ShowDialog()

# SIG # Begin signature block
# MIIcSgYJKoZIhvcNAQcCoIIcOzCCHDcCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCVTK4QgUow4Tc9
# 8PDscwgd04cEJLQ3/0+/V1cxrOiNFaCCFnowggM8MIICJKADAgECAhBJfyGrXBJT
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
# MQ4wDAYKKwYBBAGCNwIBFTAvBgkqhkiG9w0BCQQxIgQgVPt6qWvjGOe3YEEzSCSd
# QK+okEa0f5sZWzZXJ+Nkg3swDQYJKoZIhvcNAQEBBQAEggEAJz9dyRlMuZuE1jbP
# arA4W4uAoA5DDOYaYQUPo6Fjgb3pLOtGz2bj+uNuzoAU+rU+swR8MRNWf3LO/DIK
# DBr7P3KzCPUzes0NfLqnYC+CguoJbPcqz/jzTey0QFEC71SU+qplFPl75AicDM0o
# o4CKUPRlfgPy1dLFHDFYDVzyfQXhm1G/VMqce5Ap4FRZ8qPlCY0oXHUeFjatAoWa
# bHvdPgCvUZW0LYN0ng9T/lqgQm24hNQuUcP0JeyWzSO2QHeVt+yykFrZrEY51zUr
# dPcJaw68gQtsVd8h1J0twzrFfJsgeWYeHNtZFaCPTZfMygvTaHW8UUOThm3LpSul
# qmTvoaGCAyYwggMiBgkqhkiG9w0BCQYxggMTMIIDDwIBATB9MGkxCzAJBgNVBAYT
# AlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5jLjFBMD8GA1UEAxM4RGlnaUNlcnQg
# VHJ1c3RlZCBHNCBUaW1lU3RhbXBpbmcgUlNBNDA5NiBTSEEyNTYgMjAyNSBDQTEC
# EAqA7xhLjfEFgtHEdqeVdGgwDQYJYIZIAWUDBAIBBQCgaTAYBgkqhkiG9w0BCQMx
# CwYJKoZIhvcNAQcBMBwGCSqGSIb3DQEJBTEPFw0yNjAxMjAxODAyNTdaMC8GCSqG
# SIb3DQEJBDEiBCD5qMIjj2FHzGkLUtR0GzP1psdre+0/DqZ/AOS0b1IEwzANBgkq
# hkiG9w0BAQEFAASCAgBVlrDIwaTdv+1CvHp/tWYNElUjCURTuimdUfjfuWEIntty
# bs1sqIIqZNWOCb6oHChD1FTyO/nsl2G98bUBmVUXrkjFwmdLtupJPtA+3CwAfp2i
# nPlnuE5bl3eEsE4tnR2+L//uOLZuvIFlYqCzIXXq9kukuYqe6D1sNMl5mBIiGns3
# YcipvkTlX5T0326Mnn/i1nPcrn1v51cF8k2qA5IN9zO6GHfoSLwTTuh6YGAC2Xi4
# 29Pbr+M7QYA0E/ShVXSmwx6G2QVE+xkCD4Qil4uimDKEVjsz554So5JlsxKGXS+3
# afUvdaU0mTgcTyQ1ftnEzUr8Fp0ufZInS/9xUGsSC3UyafwdbEyeHd2S6T2M5M0Q
# A7gVnpbpKk0MbOVaTkX3T6AX9MaWI/Wb7ncDbRP8FWD4Q4RQAoIdFHYjfehugTpt
# jHNQHvZIGqtaol7o51lmuGdoOmH6g4a6YLzK4+2TPTLFjUIcmLVqfkSOOzW/IzXZ
# G1Sy0GPco34hLEqHYvJLOeimG/QKwr94JJyStlmt6niPARPx3CbT6N6D6jvgX6Gi
# OIJGMG7nBxj8fu69vf6ASEFiJ2gavpt/lzokIHCXJtmV+xIeYMj/vQtz3D8pSUgz
# OxKEkN8v3oWMwieEoh1s9uhG9MWcNbpSyblD6j4rUuvcTmhuOtv5+auCVxfAUw==
# SIG # End signature block

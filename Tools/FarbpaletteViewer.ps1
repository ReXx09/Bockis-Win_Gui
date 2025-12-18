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

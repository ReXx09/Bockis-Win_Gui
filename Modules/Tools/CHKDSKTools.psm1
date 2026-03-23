# Import required modules
Import-Module "$PSScriptRoot\..\Core\Core.psm1" -Force -Global
Import-Module "$PSScriptRoot\..\Core\ProgressBarTools.psm1" -Force -Global
Import-Module "$PSScriptRoot\..\Core\TextStyle.psm1" -Force -Global

# WPF-Assemblies für den Dialog
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase

# Function to run CHKDSK
function Start-CHKDSK {
    param (
        [System.Windows.Forms.RichTextBox]$outputBox,
        [System.Windows.Forms.ProgressBar]$progressBar,
        [System.Windows.Forms.Form]$mainform
    )

    Clear-Host
    
    # Stelle sicher, dass die ProgressBar initialisiert ist
    if ($progressBar) {
        Initialize-ProgressComponents -ProgressBar $progressBar -StatusLabel $null
    }
    
    # In Log-Datei und Datenbank schreiben, dass CHKDSK gestartet wird
    Write-ToolLog -ToolName "CHKDSK" -Message "CHKDSK wird gestartet" -OutputBox $outputBox -Style 'Action' -Level "Information" -SaveToDatabase
    
    # Rahmen und Systeminformationen erstellen
    #$computerName = $env:COMPUTERNAME
    #$userName = $env:USERNAME
    #$osInfo = (Get-CimInstance -ClassName Win32_OperatingSystem).Caption
    #$dateTime = Get-Date -Format "dd.MM.yyyy HH:mm:ss"
    #$width = 80
        
    # Rahmen oben
    Write-Host "╔══════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-ColoredCenteredText                             "CHKDSK"                                         
    Write-Host "╚══════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Green
    Write-Host
    Write-Host '   .d8888b.  888    888 888    d8P  8888888b.   .d8888b.  888    d8P ' -ForegroundColor Cyan
    Write-Host '  d88P  Y88b 888    888 888   d8P   888  "Y88b d88P  Y88b 888   d8P  ' -ForegroundColor Blue
    Write-Host '  888    888 888    888 888  d8P    888    888 Y88b.      888  d8P    ' -ForegroundColor Cyan
    Write-Host '  888        8888888888 888d88K     888    888  "Y888b.   888d88K     ' -ForegroundColor Blue
    Write-Host '  888        888    888 8888888b    888    888     "Y88b. 8888888b    ' -ForegroundColor Cyan
    Write-Host '  888    888 888    888 888  Y88b   888    888       "888 888  Y88b   ' -ForegroundColor Blue
    Write-Host '  Y88b  d88P 888    888 888   Y88b  888  .d88P Y88b  d88P 888   Y88b  ' -ForegroundColor Cyan
    Write-Host '   "Y8888P"  888    888 888    Y88b 8888888P"   "Y8888P"  888    Y88b' -ForegroundColor Blue
    Write-Host
    # Rahmen für Systeminformationen
    Write-Host "╔══════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-ColoredCenteredText                 "INFORMATIONEN"                                                     
    Write-Host "╠══════════════════════════════════════════════════════════════════════════════╣" -ForegroundColor Green
    # Systeminformationen
    Write-Host "║                                                                              ║" -ForegroundColor Green
    Write-Host " ├─ Datenträgerprüfung mit CHKDSK:                                                "  -ForegroundColor Yellow                 
    Write-Host " ├─ Sucht nach Dateisystemfehlern und fehlerhaften Sektoren auf der Festplatte.   "  -ForegroundColor Yellow                                    
    Write-Host " ├─ Kann Probleme beheben, die zu Datenverlust oder Systemfehlern führen.         "  -ForegroundColor Yellow                                    
    Write-Host " └─ Empfohlen bei Abstürzen, langsamen Zugriffen oder nach Stromausfällen.        "  -ForegroundColor Yellow                                  
    Write-Host "║                                                                              ║" -ForegroundColor Green

    Write-Host "╠══════════════════════════════════════════════════════════════════════════════╣" -ForegroundColor Green
    Write-ColoredCenteredText       "CHKDSK Laufwerksauswahl wurde geöffnet..."
    Write-Host "╚══════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Green    # 1 Sekunde warten vor dem Start
    Start-Sleep -Seconds 1
    $outputBox.Clear()
    Write-Host 
    Write-Host
    Write-Host "     [>] Ein Dialog-Fenster für die Auswahl der Laufwerke wird geöffnet...... " -ForegroundColor $secondaryColor
    Write-Host
    Write-Host "     [i] Bitte wählen Sie die zu prüfenden Laufwerke und Optionen aus... " -ForegroundColor Blue
    Write-Host
    Write-Host "`n" + ("═" * 70) -ForegroundColor Cyan 
    Write-Host
        
    # Verfügbare Laufwerke ermitteln
    $drives = Get-WmiObject Win32_LogicalDisk | 
        Where-Object { $_.DriveType -eq 3 -or $_.DriveType -eq 2 } | 
            Select-Object -ExpandProperty DeviceID    # Laufwerksinformationen anzeigen
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Action'
    $outputBox.AppendText("[►] VERFÜGBARE LAUFWERKE:`r`n`r`n")
    
    # Tabellenkopf erstellen
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Action'
    $lw = "Laufwerk".PadRight(15)
    $name = "Bezeichnung".PadRight(20)
    $total = "Größe".PadRight(15)
    $free = "Freier Speicher".PadRight(20)
    $used = "Belegung".PadRight(15)
    $outputBox.AppendText("    $lw$name$total$free$used`r`n")
    
    # Trennlinie
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Muted'
    $outputBox.AppendText("    " + "".PadRight(85, '─') + "`r`n")
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Default'
    
    # Laufwerksdaten in Tabellenform anzeigen
    foreach ($drive in $drives) {
        $driveInfo = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='$drive'"
        $totalSpace = [Math]::Round($driveInfo.Size / 1GB, 2)
        $freeSpace = [Math]::Round($driveInfo.FreeSpace / 1GB, 2)
        $usedPercent = [Math]::Round(100 - (($driveInfo.FreeSpace / $driveInfo.Size) * 100), 1)
        $isSystemDrive = $drive -eq $env:SystemDrive
        
        # Laufwerksname formatieren
        $driveName = $drive
        if ($isSystemDrive) {
            $driveName += " (System)"
        }
        $driveCol = $driveName.PadRight(15)
        
        # Laufwerksbezeichnung formatieren
        $labelName = if ($driveInfo.VolumeName) { $driveInfo.VolumeName } else { "<Keine>" }
        $labelCol = $labelName.PadRight(20)
        
        # Größeninformationen formatieren
        $totalCol = "$totalSpace GB".PadRight(15)
        $freeCol = "$freeSpace GB".PadRight(20)
        
        # Zeile ausgeben
        $outputBox.AppendText("    $driveCol$labelCol$totalCol$freeCol")
        
        # Speichernutzung mit Farbe je nach Füllstand anzeigen
        if ($usedPercent -gt 90) {
            Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Error'
            $outputBox.AppendText("$usedPercent% (Kritisch)")
        } elseif ($usedPercent -gt 75) {
            Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Warning'
            $outputBox.AppendText("$usedPercent% (Warnung)")
        } else {
            Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Success'
            $outputBox.AppendText("$usedPercent% (OK)")
        }
        
        Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Default'
        $outputBox.AppendText("`r`n")
    }
    
    $outputBox.AppendText("`r`n")
    
    # Kurze Information zum weiteren Vorgehen
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Action'
    $outputBox.AppendText("[►] VORBEREITUNG CHKDSK:`r`n")
    Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Success'
    $outputBox.AppendText("    Bitte wählen Sie die zu prüfenden Laufwerke und Optionen im Dialog-Fenster aus...`r`n")

    # ── WPF-Dialog für Laufwerksauswahl ──────────────────────────────
    [xml]$xaml = @'
<Window
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="" Width="510" Height="550"
    WindowStyle="None" AllowsTransparency="True" ResizeMode="NoResize"
    WindowStartupLocation="Manual"
    Background="Transparent">

    <Window.Resources>
        <!-- Basis Button-Style -->
        <Style x:Key="BtnBase" TargetType="Button">
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="FontFamily" Value="Segoe UI"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="bd" CornerRadius="10"
                                Background="{TemplateBinding Background}"
                                BorderBrush="{TemplateBinding BorderBrush}"
                                BorderThickness="{TemplateBinding BorderThickness}">
                            <ContentPresenter HorizontalAlignment="Center"
                                              VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="bd" Property="Background"
                                        Value="{Binding RelativeSource={RelativeSource TemplatedParent},
                                               Path=Tag}"/>
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter TargetName="bd" Property="Opacity" Value="0.85"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <!-- CheckBox-Style dark -->
        <Style TargetType="CheckBox">
            <Setter Property="Foreground" Value="#E0E0E0"/>
            <Setter Property="FontFamily" Value="Segoe UI"/>
            <Setter Property="FontSize" Value="12"/>
            <Setter Property="Margin" Value="0,5,0,0"/>
            <Setter Property="VerticalContentAlignment" Value="Center"/>
        </Style>

        <!-- ScrollBar schlank -->
        <Style TargetType="ScrollBar">
            <Setter Property="Width" Value="6"/>
            <Setter Property="Background" Value="Transparent"/>
        </Style>
    </Window.Resources>

    <!-- Äußerer Schatten + runde Ecken -->
    <Border CornerRadius="12" Background="#1E1E1E"
            BorderBrush="#484848" BorderThickness="1">
        <Border.Effect>
            <DropShadowEffect BlurRadius="20" ShadowDepth="6"
                              Opacity="0.6" Color="#000000"/>
        </Border.Effect>

        <Grid>
            <Grid.RowDefinitions>
                <RowDefinition Height="42"/>    <!-- Header / Drag -->
                <RowDefinition Height="2"/>     <!-- Accent Linie -->
                <RowDefinition Height="Auto"/>  <!-- Laufwerk-Label -->
                <RowDefinition Height="200"/>   <!-- Laufwerk-Liste -->
                <RowDefinition Height="Auto"/>  <!-- Alle / Auto-Confirm -->
                <RowDefinition Height="Auto"/>  <!-- CHKDSK-Optionen -->
                <RowDefinition Height="Auto"/>  <!-- Neustart-Optionen -->
                <RowDefinition Height="*"/>     <!-- Spacer -->
                <RowDefinition Height="68"/>    <!-- Buttons -->
            </Grid.RowDefinitions>

            <!-- Header (Drag-Zone) -->
            <Border Grid.Row="0" Background="#262626"
                    CornerRadius="12,12,0,0" x:Name="DragHeader">
                <Grid>
                    <TextBlock Text="  ⬡  CHKDSK  –  Laufwerksauswahl"
                               Foreground="#00B464" FontSize="13" FontWeight="Bold"
                               FontFamily="Segoe UI"
                               VerticalAlignment="Center" Margin="8,0,0,0"/>
                    <!-- Schließen-Button -->
                    <Button x:Name="BtnClose" Content="✕" HorizontalAlignment="Right"
                            Width="42" Height="42" FontSize="14"
                            Background="Transparent" Foreground="#888"
                            BorderThickness="0" Cursor="Hand"
                            Style="{x:Null}">
                        <Button.Template>
                            <ControlTemplate TargetType="Button">
                                <Border x:Name="cb" Background="Transparent"
                                        CornerRadius="0,12,0,0">
                                    <ContentPresenter HorizontalAlignment="Center"
                                                      VerticalAlignment="Center"/>
                                </Border>
                                <ControlTemplate.Triggers>
                                    <Trigger Property="IsMouseOver" Value="True">
                                        <Setter TargetName="cb" Property="Background" Value="#C42B1C"/>
                                        <Setter Property="Foreground" Value="White"/>
                                    </Trigger>
                                </ControlTemplate.Triggers>
                            </ControlTemplate>
                        </Button.Template>
                    </Button>
                </Grid>
            </Border>

            <!-- Accent Linie -->
            <Rectangle Grid.Row="1" Fill="#00B464"/>

            <!-- Laufwerk-Label -->
            <TextBlock Grid.Row="2" Text="Zu prüfende Laufwerke auswählen:"
                       Foreground="#909090" FontFamily="Segoe UI" FontSize="11"
                       Margin="14,10,14,4"/>

            <!-- Laufwerk-Liste (CheckBoxen dynamisch) -->
            <ScrollViewer Grid.Row="3" Margin="12,0,12,0"
                          VerticalScrollBarVisibility="Auto"
                          Background="#2B2B2B">
                <StackPanel x:Name="DrivePanel" Grid.IsSharedSizeScope="True"
                            Margin="2,8,2,8">
                    <!-- Tabellen-Kopf -->
                    <Grid>
                        <Grid.ColumnDefinitions>
                            <ColumnDefinition SharedSizeGroup="ColCB"    Width="Auto"/>
                            <ColumnDefinition SharedSizeGroup="ColDrive" Width="Auto" MinWidth="34"/>
                            <ColumnDefinition SharedSizeGroup="ColName"  Width="Auto" MinWidth="100"/>
                            <ColumnDefinition SharedSizeGroup="ColFree"  Width="Auto" MinWidth="110"/>
                            <ColumnDefinition SharedSizeGroup="ColTotal" Width="Auto" MinWidth="82"/>
                            <ColumnDefinition Width="*"/>
                        </Grid.ColumnDefinitions>
                        <TextBlock Grid.Column="1" Text="LW"              Foreground="#585858" FontSize="10" FontFamily="Segoe UI" FontWeight="SemiBold" Margin="0,0,14,0"/>
                        <TextBlock Grid.Column="2" Text="Bezeichnung"     Foreground="#585858" FontSize="10" FontFamily="Segoe UI" FontWeight="SemiBold" Margin="0,0,14,0"/>
                        <TextBlock Grid.Column="3" Text="Freier Speicher" Foreground="#585858" FontSize="10" FontFamily="Segoe UI" FontWeight="SemiBold" Margin="0,0,14,0"/>
                        <TextBlock Grid.Column="4" Text="Gesamt"          Foreground="#585858" FontSize="10" FontFamily="Segoe UI" FontWeight="SemiBold"/>
                    </Grid>
                    <!-- Trennlinie -->
                    <Rectangle Height="1" Fill="#363636" Margin="0,5,0,3"/>
                </StackPanel>
            </ScrollViewer>

            <!-- Alle auswählen + Auto-Bestätigung -->
            <Grid Grid.Row="4" Margin="14,10,14,0">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="*"/>
                </Grid.ColumnDefinitions>
                <CheckBox x:Name="ChkAll"   Grid.Column="0"
                          Content="Alle auswählen" Margin="0,0,20,0"/>
                <CheckBox x:Name="ChkAutoConfirm" Grid.Column="1"
                          Content="Laufwerk-Freigabe automatisch bestätigen"
                          IsChecked="True"/>
            </Grid>

            <!-- CHKDSK-Optionen GroupBox -->
            <GroupBox Grid.Row="5" Margin="12,12,12,0"
                      Header="CHKDSK-Optionen"
                      Foreground="#909090" BorderBrush="#484848">
                <StackPanel Margin="8,6,8,8">
                    <CheckBox x:Name="ChkFixErrors"
                              Content="Fehler auf dem Laufwerk beheben  (/f)"
                              IsChecked="True"/>
                    <CheckBox x:Name="ChkScanSectors"
                              Content="Beschädigte Sektoren suchen und wiederherstellen  (/r)  – kann sehr lange dauern"/>
                    <CheckBox x:Name="ChkLessIndex"
                              Content="Indexeinträge weniger intensiv prüfen  (/i)  – schneller"/>
                    <CheckBox x:Name="ChkForceMount"
                              Content="Laufwerk bei Bedarf auswerfen  (/x)  – für gründlichere Prüfung"/>
                </StackPanel>
            </GroupBox>

            <!-- Neustart-Optionen GroupBox -->
            <GroupBox Grid.Row="6" Margin="12,10,12,0"
                      Header="Neustartoptionen  (gilt für alle gewählten Laufwerke)"
                      Foreground="#909090" BorderBrush="#484848">
                <StackPanel Orientation="Horizontal" Margin="8,6,8,8">
                    <CheckBox x:Name="ChkAutoRestart"
                              Content="Automatisch neustarten" VerticalAlignment="Center"/>
                    <TextBox x:Name="TxtRestartSec" Width="55" Margin="16,0,6,0"
                             Text="30" VerticalAlignment="Center"
                             IsEnabled="False"
                             Background="#2B2B2B" Foreground="#E0E0E0"
                             BorderBrush="#484848" FontFamily="Segoe UI" FontSize="12"
                             Padding="4,2" TextAlignment="Center"/>
                    <TextBlock Text="Sekunden" Foreground="#909090" FontSize="12"
                               FontFamily="Segoe UI" VerticalAlignment="Center"/>
                </StackPanel>
            </GroupBox>

            <!-- Buttons -->
            <Grid Grid.Row="8" Margin="70,0,14,14">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="180"/>
                    <ColumnDefinition Width="12"/>
                    <ColumnDefinition Width="180"/>
                </Grid.ColumnDefinitions>
                <Button x:Name="BtnOk" Grid.Column="0"
                        Content="▶  Prüfung starten" Height="32"
                        Background="#00B464" Foreground="#141414"
                        Tag="#00D47A"
                        Style="{StaticResource BtnBase}"/>
                <Button x:Name="BtnCancel" Grid.Column="2"
                        Content="Abbrechen" Height="32"
                        Background="#373737" Foreground="#E0E0E0"
                        Tag="#484848"
                        Style="{StaticResource BtnBase}"/>
            </Grid>
        </Grid>
    </Border>
</Window>
'@

    # ── WPF-Fenster aus XAML erstellen ───────────────────────────────
    $reader = New-Object System.Xml.XmlNodeReader $xaml
    $wpfForm = [Windows.Markup.XamlReader]::Load($reader)

    # Startposition: rechts neben der Hauptform
    if ($null -ne $mainform) {
        $wpfForm.Left = $mainform.Location.X + $mainform.Width + 10
        $wpfForm.Top = $mainform.Location.Y
    }

    # Controls holen
    $drivePanel = $wpfForm.FindName("DrivePanel")
    $chkAll = $wpfForm.FindName("ChkAll")
    $chkAutoConfirm = $wpfForm.FindName("ChkAutoConfirm")
    $chkFixErrors = $wpfForm.FindName("ChkFixErrors")
    $chkScanSectors = $wpfForm.FindName("ChkScanSectors")
    $chkLessIndex = $wpfForm.FindName("ChkLessIndex")
    $chkForceMount = $wpfForm.FindName("ChkForceMount")
    $chkAutoRestart = $wpfForm.FindName("ChkAutoRestart")
    $txtRestartSec = $wpfForm.FindName("TxtRestartSec")
    $btnOk = $wpfForm.FindName("BtnOk")
    $btnCancel = $wpfForm.FindName("BtnCancel")
    $btnClose = $wpfForm.FindName("BtnClose")
    $dragHeader = $wpfForm.FindName("DragHeader")

    # ── Laufwerk-CheckBoxen dynamisch befüllen ────────────────────────
    $driveCheckBoxes = @{}
    foreach ($drive in $drives) {
        $driveInfo = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='$drive'"
        $volName = if ($driveInfo.VolumeName) { $driveInfo.VolumeName } else { "" }
        $free = [Math]::Round($driveInfo.FreeSpace / 1GB, 2)
        $total = [Math]::Round($driveInfo.Size / 1GB, 2)
        $usedPct = [Math]::Round(100 - (($driveInfo.FreeSpace / $driveInfo.Size) * 100), 1)
        $isSystem = $drive -eq $env:SystemDrive
        $freeHex = if ($usedPct -gt 90) { "#E05050" } elseif ($usedPct -gt 75) { "#D4A010" } else { "#00B464" }
        $bconv = [System.Windows.Media.BrushConverter]::new()

        # ── Tabellen-Zeile ───────────────────────────────────────────
        $row = New-Object System.Windows.Controls.Grid
        $row.Margin = New-Object System.Windows.Thickness(0, 4, 0, 0)

        foreach ($grp in @("ColCB", "ColDrive", "ColName", "ColFree", "ColTotal")) {
            $cd = New-Object System.Windows.Controls.ColumnDefinition
            $cd.SharedSizeGroup = $grp
            $cd.Width = [System.Windows.GridLength]::Auto
            $row.ColumnDefinitions.Add($cd)
        }
        $cdStar = New-Object System.Windows.Controls.ColumnDefinition
        $cdStar.Width = [System.Windows.GridLength]::new(1, [System.Windows.GridUnitType]::Star)
        $row.ColumnDefinitions.Add($cdStar)

        # CheckBox (kein Content – Text in separaten TextBlocks)
        $cb = New-Object System.Windows.Controls.CheckBox
        $cb.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
        $cb.Margin = New-Object System.Windows.Thickness(0, 0, 10, 0)
        [System.Windows.Controls.Grid]::SetColumn($cb, 0)
        $row.Children.Add($cb)

        # Laufwerksbuchstabe
        $tbDrive = New-Object System.Windows.Controls.TextBlock
        $tbDrive.Text = $drive
        $tbDrive.Foreground = [System.Windows.Media.Brushes]::White
        $tbDrive.FontFamily = New-Object System.Windows.Media.FontFamily("Segoe UI")
        $tbDrive.FontSize = 12
        $tbDrive.FontWeight = [System.Windows.FontWeights]::SemiBold
        $tbDrive.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
        $tbDrive.Margin = New-Object System.Windows.Thickness(0, 0, 14, 0)
        [System.Windows.Controls.Grid]::SetColumn($tbDrive, 1)
        $row.Children.Add($tbDrive)

        # Bezeichnung (Volumename)
        $tbName = New-Object System.Windows.Controls.TextBlock
        $tbName.Text = if ($volName) { "($volName)" } else { "" }
        $tbName.Foreground = $bconv.ConvertFrom("#909090")
        $tbName.FontFamily = New-Object System.Windows.Media.FontFamily("Segoe UI")
        $tbName.FontSize = 12
        $tbName.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
        $tbName.Margin = New-Object System.Windows.Thickness(0, 0, 14, 0)
        [System.Windows.Controls.Grid]::SetColumn($tbName, 2)
        $row.Children.Add($tbName)

        # Freier Speicher (Farbe nach Füllstand)
        $tbFree = New-Object System.Windows.Controls.TextBlock
        $tbFree.Text = "$free GB frei"
        $tbFree.Foreground = $bconv.ConvertFrom($freeHex)
        $tbFree.FontFamily = New-Object System.Windows.Media.FontFamily("Segoe UI")
        $tbFree.FontSize = 12
        $tbFree.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
        $tbFree.Margin = New-Object System.Windows.Thickness(0, 0, 14, 0)
        [System.Windows.Controls.Grid]::SetColumn($tbFree, 3)
        $row.Children.Add($tbFree)

        # Gesamtgröße
        $tbTotal = New-Object System.Windows.Controls.TextBlock
        $tbTotal.Text = "von $total GB"
        $tbTotal.Foreground = $bconv.ConvertFrom("#707070")
        $tbTotal.FontFamily = New-Object System.Windows.Media.FontFamily("Segoe UI")
        $tbTotal.FontSize = 12
        $tbTotal.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
        [System.Windows.Controls.Grid]::SetColumn($tbTotal, 4)
        $row.Children.Add($tbTotal)

        # Systemlaufwerk-Badge
        if ($isSystem) {
            $badge = New-Object System.Windows.Controls.Border
            $badge.CornerRadius = New-Object System.Windows.CornerRadius(3)
            $badge.Background = $bconv.ConvertFrom("#0A3322")
            $badge.BorderBrush = $bconv.ConvertFrom("#00B464")
            $badge.BorderThickness = New-Object System.Windows.Thickness(1)
            $badge.Margin = New-Object System.Windows.Thickness(10, 1, 0, 1)
            $badge.Padding = New-Object System.Windows.Thickness(6, 1, 6, 1)
            $badge.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
            $badgeText = New-Object System.Windows.Controls.TextBlock
            $badgeText.Text = "Systemlaufwerk"
            $badgeText.Foreground = $bconv.ConvertFrom("#00B464")
            $badgeText.FontSize = 10
            $badgeText.FontFamily = New-Object System.Windows.Media.FontFamily("Segoe UI")
            $badge.Child = $badgeText
            [System.Windows.Controls.Grid]::SetColumn($badge, 5)
            $row.Children.Add($badge)
        }

        $drivePanel.Children.Add($row)
        $driveCheckBoxes[$drive] = $cb

        # Rücksync: Einzel-CB → ChkAll aktualisieren
        $cb.Add_Checked({
                if (-not $script:_bulkChanging) {
                    $allChecked = $true
                    foreach ($c in $driveCheckBoxes.Values) {
                        if ($c.IsChecked -ne $true) { $allChecked = $false; break }
                    }
                    if ($allChecked) {
                        $script:_bulkChanging = $true
                        $chkAll.IsChecked = $true
                        $script:_bulkChanging = $false
                    }
                }
            })
        $cb.Add_Unchecked({
                if (-not $script:_bulkChanging) {
                    $script:_bulkChanging = $true
                    $chkAll.IsChecked = $false
                    $script:_bulkChanging = $false
                }
            })
    }

    # ── Events ───────────────────────────────────────────────────────
    $script:_bulkChanging = $false   # Schutz-Flag gegen Kaskaden-Ereignisse

    # Drag über Header
    $dragHeader.Add_MouseLeftButtonDown({ $wpfForm.DragMove() })

    # Alle auswählen (mit Flag, damit Einzel-CB-Events nicht kaskadieren)
    $chkAll.Add_Checked({
            $script:_bulkChanging = $true
            foreach ($cb in $driveCheckBoxes.Values) { $cb.IsChecked = $true }
            $script:_bulkChanging = $false
        })
    $chkAll.Add_Unchecked({
            $script:_bulkChanging = $true
            foreach ($cb in $driveCheckBoxes.Values) { $cb.IsChecked = $false }
            $script:_bulkChanging = $false
        })

    # Neustart-Sekunden aktivieren
    $chkAutoRestart.Add_Checked({ $txtRestartSec.IsEnabled = $true })
    $chkAutoRestart.Add_Unchecked({ $txtRestartSec.IsEnabled = $false })

    # /r impliziert /f – Fehler beheben automatisch aktivieren
    $chkScanSectors.Add_Checked({ $chkFixErrors.IsChecked = $true })

    # Schließen / Abbrechen
    $script:_wpfResult = $false
    $btnClose.Add_Click({ $script:_wpfResult = $false; $wpfForm.Close() })
    $btnCancel.Add_Click({ $script:_wpfResult = $false; $wpfForm.Close() })
    $btnOk.Add_Click({ $script:_wpfResult = $true; $wpfForm.Close() })

    # ── Dialog anzeigen ──────────────────────────────────────────────
    $wpfForm.ShowDialog() | Out-Null
    $outputBox.Clear()

    if (-not $script:_wpfResult) {
        $outputBox.AppendText("CHKDSK wurde abgebrochen.`r`n")
        return
    }

    # ── Ergebnisse auslesen ──────────────────────────────────────────
    $selectedDrives = @()
    foreach ($drive in $drives) {
        if ($driveCheckBoxes[$drive].IsChecked -eq $true) {
            $selectedDrives += $drive
        }
    }

    # Proxy-Variablen für die spätere Logik (identische Namen wie vorher)
    $checkBoxFixErrors = $chkFixErrors
    $checkBoxScanSectors = $chkScanSectors
    $checkBoxLessIntensiveIndex = $chkLessIndex
    $checkBoxForceDisMount = $chkForceMount
    $checkBoxAutoConfirmBusy = $chkAutoConfirm
    $checkBoxAutoRestart = $chkAutoRestart
    $numRestartTimer = $txtRestartSec

    if ($selectedDrives.Count -eq 0) {
        $outputBox.AppendText("Keine Laufwerke ausgewählt. CHKDSK abgebrochen.`r`n")
        return
    }

    # CHKDSK-Parameter aufbauen
    $chkdskParams = ""
    if ($checkBoxFixErrors.IsChecked -eq $true) { $chkdskParams += " /f" }
    if ($checkBoxScanSectors.IsChecked -eq $true) { $chkdskParams += " /r" }
    if ($checkBoxLessIntensiveIndex.IsChecked -eq $true) { $chkdskParams += " /i" }
    if ($checkBoxForceDisMount.IsChecked -eq $true) { $chkdskParams += " /x" }

    # Kurze Zusammenfassung der Parameter anzeigen
    $outputBox.AppendText("CHKDSK wird ausgeführt mit Parametern:$chkdskParams`r`n`r`n")
    if ($checkBoxScanSectors.IsChecked -eq $true) {
        $outputBox.AppendText("Hinweis: Die Prüfung auf fehlerhafte Sektoren kann lange dauern.`r`n`r`n")
    }

    # Abbruch-Button aktivieren
    $script:chkdskRunning = $true
            
    $totalDrives = $selectedDrives.Count
    $currentDriveIndex = 0
    # Variable für Neustart-Erfordernis
    $restartRequired = $false

    foreach ($drive in $selectedDrives) {
        $currentDriveIndex++
        $progressPercent = [int](($currentDriveIndex - 1) / $totalDrives * 100)
        if ($null -ne $progressBar) {
            $progressBar.Value = $progressPercent
        }
            
        # Starten der Zeitmessung für dieses Laufwerk
        $driveStopwatch = [System.Diagnostics.Stopwatch]::StartNew()
                
        $outputBox.AppendText("CHKDSK für Laufwerk $drive gestartet ($currentDriveIndex von $totalDrives)...`r`n")
                
        # Prüfen, ob es sich um das Systemlaufwerk handelt
        $isSystemDrive = $drive -eq $env:SystemDrive
        if ($isSystemDrive -and ($checkBoxFixErrors.IsChecked -eq $true -or $checkBoxScanSectors.IsChecked -eq $true)) {
            $outputBox.AppendText("Systemlaufwerk $drive erkannt. CHKDSK wird beim nächsten Neustart ausgeführt.`r`n")
            $restartRequired = $true
                    
            # CHKDSK beim nächsten Neustart mit fsutil planen (zuverlässiger)
            try {
                # Zuerst das Laufwerk als "dirty" markieren
                $fsutilResult = & fsutil dirty set $drive
                $outputBox.AppendText("Laufwerk als 'dirty' markiert: $fsutilResult`r`n")
                        
                # Dann CHKDSK-Parameter für den nächsten Neustart setzen
                $regPath = "HKLM:\System\CurrentControlSet\Control\Session Manager"
                $regKey = Get-ItemProperty -Path $regPath -Name "BootExecute" -ErrorAction SilentlyContinue
                        
                if ($regKey) {
                    $bootExecute = $regKey.BootExecute
                    # Prüfen, ob bereits ein CHKDSK-Eintrag vorhanden ist
                    $chkdskEntry = "autocheck autochk * $drive$chkdskParams"
                            
                    if ($bootExecute -notcontains $chkdskEntry) {
                        $newBootExecute = @("autocheck autochk *")
                        foreach ($item in $bootExecute) {
                            if ($item -ne "autocheck autochk *") {
                                $newBootExecute += $item
                            }
                        }
                        $newBootExecute += $chkdskEntry
                        Set-ItemProperty -Path $regPath -Name "BootExecute" -Value $newBootExecute
                        $outputBox.AppendText("CHKDSK wurde für den nächsten Neustart geplant mit Parametern:$chkdskParams`r`n")
                    }
                }
                # Prüfen, ob CHKDSK bereits geplant ist
                $chkntfsResult = & chkntfs $drive
                $outputBox.AppendText("Status: $chkntfsResult`r`n")
                    
                # Zeitmessung für Systemlaufwerk stoppen
                $driveStopwatch.Stop()
                $formattedTime = [math]::Round($driveStopwatch.Elapsed.TotalSeconds, 1)
                Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Action'
                $outputBox.AppendText("[INFO] Laufwerk: $drive | Dauer der Einrichtung: $formattedTime Sekunden`r`n")
                Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Default'
                $outputBox.AppendText("____________________________________________________`r`n`r`n")
                Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Default'
            } catch {
                $outputBox.AppendText("Fehler beim Setzen des CHKDSK-Neustarts: $_`r`n")
                # Alternativer Ansatz mit direktem Befehl
                if ($checkBoxAutoConfirmBusy.IsChecked -eq $true) {
                    $outputBox.AppendText("Verwende alternative Methode mit automatischer Bestätigung (J)`r`n")
                    $chkdskCmd = "echo J | chkdsk $drive$chkdskParams /b"
                } else {
                    $chkdskCmd = "chkdsk $drive$chkdskParams /b"
                }
                        
                Start-Process -FilePath "cmd.exe" -ArgumentList "/c $chkdskCmd" -Verb RunAs -Wait
            }
        } else {
            # Start CHKDSK process and capture exit code
            $outputBox.AppendText("Parameter: chkdsk $drive$chkdskParams`r`n")
                    
            try {
                # Je nach Einstellung für Auto-Bestätigung
                if ($checkBoxAutoConfirmBusy.IsChecked -eq $true) {
                    $process = Start-Process -FilePath "cmd.exe" -ArgumentList "/c echo J | chkdsk $drive$chkdskParams" -NoNewWindow -PassThru -Wait
                } else {
                    $process = Start-Process -FilePath "chkdsk.exe" -ArgumentList "$drive$chkdskParams" -NoNewWindow -PassThru -Wait
                }
                        
                $exitCode = $process.ExitCode
                        
                # Exit-Code interpretieren
                switch ($exitCode) {
                    0 { 
                        Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Success'
                    }
                    1 { 
                        Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Success'
                    }
                    2 { 
                        Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Warning'
                        $restartRequired = $true
                    }
                    3 { 
                        Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Error'
                    }
                    default { 
                        Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Error'
                    }
                }
                # Stoppe den Stopwatch für dieses Laufwerk
                $driveStopwatch.Stop()
                    
                # Schöne Ausgabe des Exit-Codes mit relevanten Informationen
                $formattedTime = [math]::Round($driveStopwatch.Elapsed.TotalSeconds, 1)
                $exitCodeMessage = switch ($exitCode) {
                    0 { "[OK] CHKDSK erfolgreich abgeschlossen. Keine Fehler gefunden." }
                    1 { "[OK] CHKDSK hat Fehler gefunden und korrigiert." }
                    2 { "[WARNUNG] CHKDSK wurde mit /f Option ausgeführt und erfordert einen Neustart." }
                    3 { "[FEHLER] CHKDSK konnte nicht alle Fehler beheben. Laufwerk möglicherweise beschädigt." }
                    default { "[FEHLER] Unbekannter CHKDSK-Statuscode: $exitCode" }
                }
                        
                $outputBox.AppendText("CHKDSK-Status: $exitCodeMessage`r`n")
                Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Action'
                $outputBox.AppendText("[INFO] Exit-Code: $exitCode | Laufwerk: $drive | Dauer: $formattedTime Sekunden`r`n")
                Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Default'
                $outputBox.AppendText("____________________________________________________`r`n`r`n")
                        
                # Farbe zurücksetzen
                Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Default'
            } catch {
                # Stopwatch anhalten auch bei Fehlern
                $driveStopwatch.Stop()
                $formattedTime = [math]::Round($driveStopwatch.Elapsed.TotalSeconds, 1)
                    
                Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Error'
                $outputBox.AppendText("❌ FEHLER: $($_.Exception.Message)`r`n")
                Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Action'
                $outputBox.AppendText("[INFO] Laufwerk: $drive | Dauer bis zum Fehler: $formattedTime Sekunden`r`n")
                Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Default'
                $outputBox.AppendText("____________________________________________________`r`n`r`n")
                Set-OutputSelectionStyle -OutputBox $outputBox -Style 'Default'
            }
        }
    }
            
    # Wenn ein Neustart erforderlich ist und Auto-Neustart aktiviert ist
    if ($restartRequired -and $checkBoxAutoRestart.IsChecked -eq $true) {
        $seconds = [int]($numRestartTimer.Text -replace '[^0-9]', '')
        if ($seconds -gt 0) {
            $outputBox.AppendText("`r`nComputer wird in $seconds Sekunden neu gestartet...`r`n")
            Start-Process -FilePath "shutdown.exe" -ArgumentList "/r /t $seconds /c `"CHKDSK erfordert einen Neustart`"" -NoNewWindow
        }
    } elseif ($restartRequired) {
        $outputBox.AppendText("`r`nBitte starten Sie den Computer neu, um die CHKDSK-Prüfung für das Systemlaufwerk durchzuführen.`r`n")
    }
            
    # Setze den Fortschrittsbalken auf 100%
    if ($null -ne $progressBar) {
        $progressBar.Value = 100
    }
    # CHKDSK-Lauf beendet
    $script:chkdskRunning = $false
}

# Export functions
Export-ModuleMember -Function Start-CHKDSK

# SIG # Begin signature block
# MIIcSgYJKoZIhvcNAQcCoIIcOzCCHDcCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDa2ukWGTd5UKIN
# X07ovQo6H+4cLvGoXRKDdXQzeRdzeaCCFnowggM8MIICJKADAgECAhBJfyGrXBJT
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
# MQ4wDAYKKwYBBAGCNwIBFTAvBgkqhkiG9w0BCQQxIgQgKGhiDVu1jJ3R9347WkUD
# 0DQDpzYCKkrpF+yOyi1bGPgwDQYJKoZIhvcNAQEBBQAEggEAm7KKRZsSBohavS4M
# ygEY0uWufYZKnqXnrII/0z7n+8WjElSCMegGcyq3a7A6DDHpBWavTaAy5dfnMrx+
# 8ycXR4vaXoD4A+BfOxGWqHs4tpCbCqXKeYuGXPvm2TiiMIUhbs70Vo5PV9eEqRUX
# W0FV88QPG/SRvJkHz/Bh+fXsjn/NOaRsNp4AJA0Flycr4fKu9PL06wDfRePndy6g
# Yrl2e22xSPW3cLxqrtJYIY6U4+ijDHxf+YKGezOERHd6zOGpMVpYyOkIawoffDeQ
# i6Oxr4PC9hC41W03/5dpIVxSsWNrIl7IU3Cfi3llMi1wAEZ4vgcvI4xRinuM/yp/
# f0BuMKGCAyYwggMiBgkqhkiG9w0BCQYxggMTMIIDDwIBATB9MGkxCzAJBgNVBAYT
# AlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5jLjFBMD8GA1UEAxM4RGlnaUNlcnQg
# VHJ1c3RlZCBHNCBUaW1lU3RhbXBpbmcgUlNBNDA5NiBTSEEyNTYgMjAyNSBDQTEC
# EAqA7xhLjfEFgtHEdqeVdGgwDQYJYIZIAWUDBAIBBQCgaTAYBgkqhkiG9w0BCQMx
# CwYJKoZIhvcNAQcBMBwGCSqGSIb3DQEJBTEPFw0yNjAxMjAxODAyNTRaMC8GCSqG
# SIb3DQEJBDEiBCBbd7selGvG7rMWnchRp0CGMtJkROeRrzQoxBQoqNWtJTANBgkq
# hkiG9w0BAQEFAASCAgDIEtb/PC+2w8iK7rEbXA7+PwqoAUku4RbVmH9Urb83gMZB
# 7SCwo9ACxAHfe/6ncHt8B4kVs1DghnZpNi+zu83jq3i7nH9RAExTjqqlS7jj+8+3
# +6JTeSL5vrWWHC803f2bnvwr3mmenyI7tuXk+nZ2JQq1C62j47fetr5Y2mBXXkb9
# Odkfq3vZtVsS4KTklOGr8/ZHYQS4h/a+TYeHAJMjupgjU2Fmw/57azvEmo4ublf9
# fQ5EhoXfRqGVLwIaoLfsoDUhxC2Czfomynp8mAkZM9G7yp/4Mz6y+zUlxXvp7lDx
# z3cjC1pZsy87M+h8qCh1kl+DjLd3bLU8Ix01fH8uh91tY7WHlXf0yHXU5BmkMOoV
# aYF9nfW5tSN7E7nQ8SE/dybhRCNbYWoA7LeRl2sEMzYJZl+0R33lEBzWdavuzjaq
# o2Vc5mcXnC/Bo4pq98AqMYHbyZHbJjw82s6sLXfRs9pCln1gZezYpjAP27XEo0Oe
# UtwuJ+SnfxJ/YJ+dkzYNvUovHO688OAiLj1l3nWHJf9l1j3dsj4r3D9WDEVAZTL6
# PP0Ps8rNHu57UBkvhGD4PJi+fdgdkU1MLV7XOEx3CyHLNXSUUwyb5O6kegXvZR0Y
# EsL4FGEQyuRdFb0rM4zu4r1BEat3dX9kC9QX5ArcbfdSrCnh52QeSkd09A8Fxg==
# SIG # End signature block

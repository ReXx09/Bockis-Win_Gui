# Import required assemblies
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# UI-Hilfsfunktionen für Buttons und Controls

# Create a modern info button
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
    
    $infoButton.Add_MouseEnter({ $this.BackColor = [System.Drawing.Color]::DodgerBlue })
    $infoButton.Add_MouseLeave({ $this.BackColor = [System.Drawing.Color]::DeepSkyBlue })
    
    if ($null -ne $clickAction) {
        $infoButton.Add_Click($clickAction)
    }
    
    return $infoButton
}

Set-Alias -Name Create-ModernInfoButton -Value New-ModernInfoButton

Export-ModuleMember -Function New-ModernInfoButton
Export-ModuleMember -Alias Create-ModernInfoButton

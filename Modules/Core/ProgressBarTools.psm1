# ProgressBarTools.psm1
# Modul für ProgressBar-Funktionalitäten

# Skript-Variablen für die ProgressBar-Komponenten
$script:progressBar = $null
$script:progressStatusLabel = $null

# Funktion zum Initialisieren der ProgressBar-Komponenten
function Initialize-ProgressComponents {
    param (
        [System.Windows.Forms.ProgressBar]$ProgressBar,
        [System.Windows.Forms.Label]$StatusLabel
    )
    
    $script:progressBar = $ProgressBar
    $script:progressStatusLabel = $StatusLabel
}

# Funktion zum Aktualisieren des ProgressBar-Status
function Update-ProgressStatus {
    param (
        [string]$StatusText,
        [int]$ProgressValue,
        [System.Drawing.Color]$TextColor = [System.Drawing.Color]::DarkBlue,
        [System.Windows.Forms.ProgressBar]$progressBarParam = $null
    )
    
    # Wenn eine ProgressBar als Parameter übergeben wurde und die globale Variable nicht gesetzt ist,
    # verwende die übergebene ProgressBar (hilfreich für direkte Aufrufe ohne vorherige Initialisierung)
    if ($null -eq $script:progressBar -and $null -ne $progressBarParam) {
        # Temporäre Initialisierung
        $script:progressBar = $progressBarParam
    }
    elseif ($null -eq $script:progressBar -and $null -eq $progressBarParam) {
        Write-Warning "ProgressBar-Komponente wurde nicht initialisiert. Bitte Initialize-ProgressComponents zuerst aufrufen."
        return
    }
    
    # Text direkt in der ProgressBar anzeigen, wenn es sich um eine TextProgressBar handelt
    if ($script:progressBar.GetType().Name -eq "TextProgressBar") {
        $script:progressBar.CustomText = $StatusText
        $script:progressBar.TextColor = $TextColor
    }
    elseif ($null -ne $script:progressStatusLabel) {
        # Fallback auf das separate Label, wenn es existiert
        $script:progressStatusLabel.Text = $StatusText
        $script:progressStatusLabel.ForeColor = $TextColor
    }
    
    $script:progressBar.Value = $ProgressValue
    
    # Form aktualisieren
    [System.Windows.Forms.Application]::DoEvents()
}

# Funktion zum Zurücksetzen der ProgressBar
function Reset-ProgressBar {
    if ($null -eq $script:progressBar) {
        Write-Warning "ProgressBar-Komponente wurde nicht initialisiert. Bitte Initialize-ProgressComponents zuerst aufrufen."
        return
    }
    
    $script:progressBar.Value = 0
    
    # Text direkt in der ProgressBar zurücksetzen, wenn es sich um eine TextProgressBar handelt
    if ($script:progressBar.GetType().Name -eq "TextProgressBar") {
        $script:progressBar.CustomText = "Bereit"
        $script:progressBar.TextColor = [System.Drawing.Color]::DarkBlue
    }
    elseif ($null -ne $script:progressStatusLabel) {
        # Fallback auf das separate Label, wenn es existiert
        $script:progressStatusLabel.Text = "Bereit"
        $script:progressStatusLabel.ForeColor = [System.Drawing.Color]::DarkBlue
    }
    
    # Form aktualisieren
    [System.Windows.Forms.Application]::DoEvents()
}

# Funktion zum Starten eines neuen Vorgangs
function Start-Progress {
    param (
        [string]$StatusText,
        [System.Drawing.Color]$TextColor = [System.Drawing.Color]::DarkBlue
    )
    
    Update-ProgressStatus -StatusText $StatusText -ProgressValue 0 -TextColor $TextColor
}

# Funktion zum Abschließen eines Vorgangs
function Complete-Progress {
    param (
        [string]$StatusText = "Fertig",
        [System.Drawing.Color]$TextColor = [System.Drawing.Color]::Green
    )
    
    Update-ProgressStatus -StatusText $StatusText -ProgressValue 100 -TextColor $TextColor
    Start-Sleep -Milliseconds 1000
    Reset-ProgressBar
}

# Exportiere die Funktionen
Export-ModuleMember -Function Initialize-ProgressComponents, Update-ProgressStatus, Reset-ProgressBar, Start-Progress, Complete-Progress 
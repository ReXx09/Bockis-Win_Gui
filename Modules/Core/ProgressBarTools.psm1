# ProgressBarTools.psm1
# Modul für ProgressBar-Funktionalitäten

# Skript-Variablen für die ProgressBar-Komponenten
$script:progressBar = $null
$script:progressStatusLabel = $null

# Erstelle eine benutzerdefinierte ProgressBar-Klasse mit Text-Anzeige
Add-Type -TypeDefinition @"
using System;
using System.Windows.Forms;
using System.Drawing;

public class TextProgressBar : ProgressBar
{
    private string _text = "";
    private Color _textColor = Color.DarkBlue;

    public TextProgressBar() : base()
    {
        this.SetStyle(ControlStyles.UserPaint, true);
    }

    public string CustomText
    {
        get { return _text; }
        set {
            _text = value;
            this.Invalidate();
        }
    }

    public Color TextColor
    {
        get { return _textColor; }
        set {
            _textColor = value;
            this.Invalidate();
        }
    }

    protected override void OnPaint(PaintEventArgs e)
    {
        Rectangle rect = this.ClientRectangle;
        Graphics g = e.Graphics;

        // Dunkler Hintergrund für die ProgressBar
        using (SolidBrush bgBrush = new SolidBrush(Color.FromArgb(45, 45, 48)))
        {
            g.FillRectangle(bgBrush, rect);
        }
        
        // Rahmen zeichnen
        using (Pen borderPen = new Pen(Color.FromArgb(60, 60, 60), 1))
        {
            g.DrawRectangle(borderPen, rect.X, rect.Y, rect.Width - 1, rect.Height - 1);
        }

        rect.Inflate(-3, -3);
        if (Value > 0)
        {
            Rectangle clip = new Rectangle(rect.X, rect.Y, (int)Math.Round(((float)Value / Maximum) * rect.Width), rect.Height);
            // Fortschrittsbalken in Windows-Blau zeichnen
            using (SolidBrush progressBrush = new SolidBrush(Color.FromArgb(0, 120, 215)))
            {
                g.FillRectangle(progressBrush, clip);
            }
        }

        if (!string.IsNullOrEmpty(_text))
        {
            using (Font f = new Font("Segoe UI", 9, FontStyle.Bold))
            {
                SizeF textSize = g.MeasureString(_text, f);
                Point textPos = new Point(
                    (int)(rect.X + (rect.Width / 2) - (textSize.Width / 2)),
                    (int)(rect.Y + (rect.Height / 2) - (textSize.Height / 2))
                );

                // Zeichne den Text mit Schatten für bessere Lesbarkeit
                using (SolidBrush shadowBrush = new SolidBrush(Color.FromArgb(60, 0, 0, 0)))
                {
                    g.DrawString(_text, f, shadowBrush, textPos.X + 1, textPos.Y + 1);
                }

                using (SolidBrush textBrush = new SolidBrush(_textColor))
                {
                    g.DrawString(_text, f, textBrush, textPos);
                }
            }
        }
    }
}
"@ -ReferencedAssemblies "System.Windows.Forms", "System.Drawing" -ErrorAction SilentlyContinue

# Funktion zum Erstellen einer TextProgressBar
function New-TextProgressBar {
    param (
        [int]$X = 190,
        [int]$Y = 755,
        [int]$Width = 650,
        [int]$Height = 30,
        [string]$InitialText = "Bereit",
        [System.Drawing.Color]$InitialTextColor = [System.Drawing.Color]::CornflowerBlue
    )
    
    $progressBar = New-Object TextProgressBar
    $progressBar.Location = New-Object System.Drawing.Point($X, $Y)
    $progressBar.Size = New-Object System.Drawing.Size($Width, $Height)
    $progressBar.Style = "Continuous"
    $progressBar.Minimum = 0
    $progressBar.Maximum = 100
    $progressBar.Value = 0
    $progressBar.CustomText = $InitialText
    $progressBar.TextColor = $InitialTextColor
    
    return $progressBar
}

# Funktion zum Initialisieren der ProgressBar-Komponenten
function Initialize-ProgressComponents {
    param (
        [object]$ProgressBar,
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
        [System.Drawing.Color]$TextColor = [System.Drawing.Color]::White,
        [object]$progressBarParam = $null
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
        $script:progressBar.TextColor = [System.Drawing.Color]::White
    }
    elseif ($null -ne $script:progressStatusLabel) {
        # Fallback auf das separate Label, wenn es existiert
        $script:progressStatusLabel.Text = "Bereit"
        $script:progressStatusLabel.ForeColor = [System.Drawing.Color]::White
    }
    
    # Form aktualisieren
    [System.Windows.Forms.Application]::DoEvents()
}

# Funktion zum Starten eines neuen Vorgangs
function Start-Progress {
    param (
        [string]$StatusText,
        [System.Drawing.Color]$TextColor = [System.Drawing.Color]::White
    )
    
    Update-ProgressStatus -StatusText $StatusText -ProgressValue 0 -TextColor $TextColor
}

# Funktion zum Abschließen eines Vorgangs
function Complete-Progress {
    param (
        [string]$StatusText = "Fertig",
        [System.Drawing.Color]$TextColor = [System.Drawing.Color]::LimeGreen
    )
    
    Update-ProgressStatus -StatusText $StatusText -ProgressValue 100 -TextColor $TextColor
    Start-Sleep -Milliseconds 1000
    Reset-ProgressBar
}

# Exportiere die Funktionen
Export-ModuleMember -Function Initialize-ProgressComponents, Update-ProgressStatus, Reset-ProgressBar, Start-Progress, Complete-Progress, New-TextProgressBar 

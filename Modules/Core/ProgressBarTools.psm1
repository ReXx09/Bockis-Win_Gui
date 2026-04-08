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
using System.Drawing.Drawing2D;
using System.Runtime.InteropServices;

public class TextProgressBar : ProgressBar
{
    private string _text = "";
    private Color _textColor = Color.DarkBlue;
    private int _cornerRadius = 8;

    public TextProgressBar() : base()
    {
        this.SetStyle(ControlStyles.UserPaint, true);
        this.SetStyle(ControlStyles.OptimizedDoubleBuffer, true);
        this.SetStyle(ControlStyles.AllPaintingInWmPaint, true);
    }

    protected override System.Windows.Forms.CreateParams CreateParams
    {
        get
        {
            System.Windows.Forms.CreateParams cp = base.CreateParams;
            cp.Style &= ~0x800000;   // entfernt WS_BORDER
            cp.ExStyle &= ~0x200;    // entfernt WS_EX_CLIENTEDGE
            return cp;
        }
    }

    [DllImport("user32.dll")]
    private static extern IntPtr GetWindowDC(IntPtr hWnd);
    [DllImport("user32.dll")]
    private static extern bool ReleaseDC(IntPtr hWnd, IntPtr hDC);

    protected override void WndProc(ref Message m)
    {
        if (m.Msg == 0x0085) // WM_NCPAINT – NC-Bereich mit Parent-Farbe füllen statt Desktop durchscheinen
        {
            IntPtr hdc = GetWindowDC(this.Handle);
            if (hdc != IntPtr.Zero)
            {
                Color bg = (this.Parent != null) ? this.Parent.BackColor : Color.FromArgb(30, 30, 30);
                using (Graphics g = Graphics.FromHdc(hdc))
                using (SolidBrush b = new SolidBrush(bg))
                {
                    g.FillRectangle(b, 0, 0, this.Width, this.Height);
                }
                ReleaseDC(this.Handle, hdc);
            }
            return;
        }
        else if (m.Msg == 0x0003) // WM_MOVE – auch an Kind-Fenster wenn Parent-Form bewegt wird
        {
            base.WndProc(ref m);
            // Client-Bereich als dirty markieren und NC-Bereich mit Parent-Farbe füllen
            this.Invalidate();
            IntPtr hdc = GetWindowDC(this.Handle);
            if (hdc != IntPtr.Zero)
            {
                Color bg = (this.Parent != null) ? this.Parent.BackColor : Color.FromArgb(30, 30, 30);
                using (Graphics g = Graphics.FromHdc(hdc))
                using (SolidBrush b = new SolidBrush(bg))
                {
                    g.FillRectangle(b, 0, 0, this.Width, this.Height);
                }
                ReleaseDC(this.Handle, hdc);
            }
            return;
        }
        base.WndProc(ref m);
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

    public int CornerRadius
    {
        get { return _cornerRadius; }
        set {
            _cornerRadius = value;
            this.Invalidate();
        }
    }

    private GraphicsPath RoundedRect(Rectangle bounds, int radius)
    {
        int d = radius * 2;
        GraphicsPath path = new GraphicsPath();
        path.AddArc(bounds.X, bounds.Y, d, d, 180, 90);
        path.AddArc(bounds.Right - d, bounds.Y, d, d, 270, 90);
        path.AddArc(bounds.Right - d, bounds.Bottom - d, d, d, 0, 90);
        path.AddArc(bounds.X, bounds.Bottom - d, d, d, 90, 90);
        path.CloseFigure();
        return path;
    }

    protected override void OnPaint(PaintEventArgs e)
    {
        Rectangle rect = this.ClientRectangle;
        Graphics g = e.Graphics;
        g.SmoothingMode = SmoothingMode.AntiAlias;

        // Gesamten Client-Bereich mit Parent-Farbe füllen – Ecken-Artefakte verhindern
        Color parentBg = (this.Parent != null) ? this.Parent.BackColor : Color.FromArgb(30, 30, 30);
        using (SolidBrush parentBrush = new SolidBrush(parentBg))
        {
            g.FillRectangle(parentBrush, this.ClientRectangle);
        }

        // Hintergrund mit runden Ecken
        using (GraphicsPath bgPath = RoundedRect(rect, _cornerRadius))
        using (SolidBrush bgBrush = new SolidBrush(Color.FromArgb(45, 45, 48)))
        {
            g.FillPath(bgBrush, bgPath);
        }

        // Fortschrittsbalken mit runden Ecken (geclippt)
        rect.Inflate(-1, -1);
        if (Value > 0)
        {
            int progressWidth = (int)Math.Round(((float)Value / Maximum) * rect.Width);
            if (progressWidth > 0)
            {
                Rectangle progressRect = new Rectangle(rect.X, rect.Y, progressWidth, rect.Height);
                // Clip auf den Bereich des Fortschritts, runden Ecken vom Gesamtpfad beibehalten
                g.SetClip(progressRect);
                using (GraphicsPath progressPath = RoundedRect(rect, _cornerRadius))
                using (SolidBrush progressBrush = new SolidBrush(Color.FromArgb(0, 120, 215)))
                {
                    g.FillPath(progressBrush, progressPath);
                }
                g.ResetClip();
            }
        }

        // Text zentriert
        if (!string.IsNullOrEmpty(_text))
        {
            rect.Inflate(-3, -3);
            using (Font f = new Font("Segoe UI", 9, FontStyle.Bold))
            {
                SizeF textSize = g.MeasureString(_text, f);
                Point textPos = new Point(
                    (int)(rect.X + (rect.Width / 2) - (textSize.Width / 2)),
                    (int)(rect.Y + (rect.Height / 2) - (textSize.Height / 2))
                );

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
    } elseif ($null -eq $script:progressBar -and $null -eq $progressBarParam) {
        Write-Warning "ProgressBar-Komponente wurde nicht initialisiert. Bitte Initialize-ProgressComponents zuerst aufrufen."
        return
    }
    
    # Text direkt in der ProgressBar anzeigen, wenn es sich um eine TextProgressBar handelt
    if ($script:progressBar.GetType().Name -eq "TextProgressBar") {
        $script:progressBar.CustomText = $StatusText
        $script:progressBar.TextColor = $TextColor
    } elseif ($null -ne $script:progressStatusLabel) {
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
    } elseif ($null -ne $script:progressStatusLabel) {
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

# SIG # Begin signature block
# MIIcSgYJKoZIhvcNAQcCoIIcOzCCHDcCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBZMP+ZeQO39ChP
# BHi47M2CBk2re+5wqUzVh4jQL1qb3KCCFnowggM8MIICJKADAgECAhBJfyGrXBJT
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
# MQ4wDAYKKwYBBAGCNwIBFTAvBgkqhkiG9w0BCQQxIgQgrSc0w7hNPh8kxSiRj3eG
# SBWSScIonHvG8ThgMwsGqnAwDQYJKoZIhvcNAQEBBQAEggEAGQuTeBMwjstw1oqT
# xXFDPWrZG/1S6McSASpQRjAgAFtkO7DcFBbBbjuaOu++4BYUnY3tjrnmqyu1ypdq
# RcTfauQ8FDb1sngYrubtY7yoshUbVY6l8L0AEZfwFQzxC6sfJ986coian3QPgBP7
# NGFw7l8a4fyRqhKBIzWCPDGqUKuxhp6iGe+KD8XWO1wGB7dVvmNNuO3lwsadgJH7
# W0bvCq6TO+jqk0mGJE0xdkkOwoAq644eZnu5ZvQzp+4JKlzEa3vhmgUCjfH3XQJa
# X9QBdU7Ek/A2hk8FOm7hL4u2166zt7JdAmOIcu06uBsZg9j+7zsgv7bl2YekMrYN
# DZO97aGCAyYwggMiBgkqhkiG9w0BCQYxggMTMIIDDwIBATB9MGkxCzAJBgNVBAYT
# AlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5jLjFBMD8GA1UEAxM4RGlnaUNlcnQg
# VHJ1c3RlZCBHNCBUaW1lU3RhbXBpbmcgUlNBNDA5NiBTSEEyNTYgMjAyNSBDQTEC
# EAqA7xhLjfEFgtHEdqeVdGgwDQYJYIZIAWUDBAIBBQCgaTAYBgkqhkiG9w0BCQMx
# CwYJKoZIhvcNAQcBMBwGCSqGSIb3DQEJBTEPFw0yNjAxMjAxODAyNTNaMC8GCSqG
# SIb3DQEJBDEiBCCRURPS53KY1GU3Ctyf2lSFFqHQjt36EwzBVxhTghvETzANBgkq
# hkiG9w0BAQEFAASCAgB49y3EofEdCWXSWLpeIyBxhMtSR4wZc3YUWPv4ek1vK+Ym
# /tKbbY9LyFVNZxjnEzSw7py8+3ghR1IaxcC62w9QS7WsPqNJA/yu4r2m+EltIoZI
# sS3yY/gdcnVABxsJyJ9h6qEgBJEW4sBwllny4qjrVbWy6qO9MXhe6MFmF0dEVjZV
# uDc54cK2rITodq2aO1C9cK6Y4qIFYznJeYv3rzUFKCl7Ezmo+JQZrmdWaTJvOPae
# Tq6Y/B6EYG277KX6yAY1g+U7T7KWOsPIxCVTXsSUIfv6ZHPo3RxFSCwvS7biiIvq
# KLTzsFJpdwfrVdbbNuu7eL+gi725ZnwNiJVV6NMrPQmg5Ts4PWKFucVI1Xn0pSnr
# blWSeC2c5jIlozmiy6anjozkdxlCUY9Ad3hld7enFHt9sJUpBe9TJAaO1D9KXP75
# mYEjTDq0Bq6BWpXbA65kyZWhue3T5qfveOuqTb1UcdqWJJwkrPg7kFOq0pSCnEud
# zcS2hDOZGt/P+Fh/IHmHZK8IQgzV6ciW6snvjFhKybg8Hv9rb2LueDzJUbE8ygTq
# z0vb3mksMGcNPWCdiUiM/ScGnTaZxZFHaKSzkxdu4iY2uY/9FeFupn1EhGgMQttv
# Bb1HO9fxaBU75QcveSMuGEz5KKvtL0zxGv6kYGOWb0T2DPN/vjnNY6rdwuW8aA==
# SIG # End signature block

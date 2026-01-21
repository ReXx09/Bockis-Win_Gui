# Test-DependencyChecker.ps1
# Testskript für das DependencyChecker-Modul

param(
    [switch]$ShowDialog,
    [switch]$AutoInstall,
    [switch]$FindOnly
)

# Setze Pfad zum Projektroot
$scriptRoot = Split-Path -Parent $PSScriptRoot
Set-Location $scriptRoot

Write-Host "`n╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║     DEPENDENCY CHECKER TEST                               ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

# Importiere das Modul
try {
    Import-Module ".\Modules\Core\DependencyChecker.psm1" -Force
    Write-Host "✓ DependencyChecker-Modul geladen" -ForegroundColor Green
}
catch {
    Write-Host "✗ Fehler beim Laden des Moduls: $_" -ForegroundColor Red
    exit 1
}

# Test 1: LibreHardwareMonitor suchen
Write-Host "`n[TEST 1] Suche nach LibreHardwareMonitor..." -ForegroundColor Yellow
Write-Host "─────────────────────────────────────────────────────────────" -ForegroundColor Gray

$lhm = Find-LibreHardwareMonitor

if ($lhm.Found) {
    Write-Host "✓ LibreHardwareMonitor gefunden!" -ForegroundColor Green
    Write-Host "  Pfad:      $($lhm.Path)" -ForegroundColor Cyan
    Write-Host "  Version:   $($lhm.Version)" -ForegroundColor Cyan
    Write-Host "  Signiert:  $($lhm.IsSigned)" -ForegroundColor $(if ($lhm.IsSigned) { 'Green' } else { 'Yellow' })
    
    # Zeige Details zur Signatur
    if ($lhm.IsSigned) {
        try {
            $sig = Get-AuthenticodeSignature -FilePath $lhm.Path
            Write-Host "`n  Zertifikat-Details:" -ForegroundColor Gray
            Write-Host "    Subject:  $($sig.SignerCertificate.Subject)" -ForegroundColor Gray
            Write-Host "    Issuer:   $($sig.SignerCertificate.Issuer)" -ForegroundColor Gray
            Write-Host "    Gültig:   $($sig.SignerCertificate.NotBefore) bis $($sig.SignerCertificate.NotAfter)" -ForegroundColor Gray
        }
        catch {
            Write-Host "  (Zertifikat-Details nicht verfügbar)" -ForegroundColor Gray
        }
    }
}
else {
    Write-Host "⚠️  LibreHardwareMonitor nicht gefunden" -ForegroundColor Yellow
    Write-Host "   → Fallback auf integrierte Bibliotheken" -ForegroundColor Cyan
}

# Test 2: PowerShell Core prüfen
Write-Host "`n[TEST 2] Suche nach PowerShell Core..." -ForegroundColor Yellow
Write-Host "─────────────────────────────────────────────────────────────" -ForegroundColor Gray

$pwsh = Find-PowerShellCore

if ($pwsh.Found) {
    Write-Host "✓ PowerShell Core gefunden!" -ForegroundColor Green
    Write-Host "  Version: $($pwsh.Version)" -ForegroundColor Cyan
    Write-Host "  Pfad:    $($pwsh.Path)" -ForegroundColor Cyan
}
else {
    Write-Host "ℹ️  PowerShell Core nicht gefunden (optional)" -ForegroundColor Cyan
}

# Test 3: Winget Package Manager prüfen
Write-Host "`n[TEST 3] Prüfe Winget Package Manager..." -ForegroundColor Yellow
Write-Host "─────────────────────────────────────────────────────────────" -ForegroundColor Gray

$winget = Find-WingetPackageManager

if ($winget.Found) {
    Write-Host "✓ Winget Package Manager gefunden!" -ForegroundColor Green
    Write-Host "  Version: $($winget.Version)" -ForegroundColor Cyan
    Write-Host "  Pfad:    $($winget.Path)" -ForegroundColor Cyan
}
else {
    Write-Host "⚠️  Winget nicht gefunden (Installation erforderlich)" -ForegroundColor Yellow
    Write-Host "   → Ohne Winget können keine Pakete automatisch installiert werden" -ForegroundColor Cyan
}

# Test 4: Winget-Verfügbarkeit für LibreHardwareMonitor prüfen
Write-Host "`n[TEST 4] Prüfe Winget-Verfügbarkeit..." -ForegroundColor Yellow
Write-Host "─────────────────────────────────────────────────────────────" -ForegroundColor Gray

$wingetAvailable = Get-Command winget -ErrorAction SilentlyContinue

if ($wingetAvailable) {
    Write-Host "✓ Winget ist verfügbar" -ForegroundColor Green
    
    $lhmAvailable = Test-LibreHardwareMonitorAvailability
    if ($lhmAvailable) {
        Write-Host "✓ LibreHardwareMonitor ist über Winget installierbar" -ForegroundColor Green
    }
    else {
        Write-Host "⚠️  LibreHardwareMonitor nicht in Winget gefunden" -ForegroundColor Yellow
    }
}
else {
    Write-Host "⚠️  Winget nicht verfügbar (manuelle Installation erforderlich)" -ForegroundColor Yellow
}

# Stoppe hier wenn nur Suche gewünscht
if ($FindOnly) {
    Write-Host "`n✓ Find-Only-Modus abgeschlossen`n" -ForegroundColor Green
    exit 0
}

# Test 5: Vollständiger Dependency-Check
Write-Host "`n[TEST 5] Vollständiger Dependency-Check..." -ForegroundColor Yellow
Write-Host "─────────────────────────────────────────────────────────────" -ForegroundColor Gray

$params = @{}
if ($ShowDialog) { $params['ShowDialog'] = $true }
if ($AutoInstall) { $params['AutoInstall'] = $true }

$result = Test-SystemDependencies @params

Write-Host "`nErgebnis:" -ForegroundColor Cyan
Write-Host "  Alle erfüllt:                $($result.AllSatisfied)" -ForegroundColor $(if ($result.AllSatisfied) { 'Green' } else { 'Yellow' })
Write-Host "  System-Lib verwenden:        $($result.UseSystemLibreHardwareMonitor)" -ForegroundColor Cyan

if ($result.SystemLibrePath) {
    Write-Host "  → Bevorzugter Lib-Pfad:        $($result.SystemLibrePath)" -ForegroundColor Cyan
}

# Test 6: Preferred Path ermitteln
Write-Host "`n[TEST 6] Ermittle bevorzugten LibreHardwareMonitor-Pfad..." -ForegroundColor Yellow
Write-Host "─────────────────────────────────────────────────────────────" -ForegroundColor Gray

$preferredPath = Get-PreferredLibreHardwareMonitorPath

if ($preferredPath) {
    Write-Host "✓ Bevorzugter Pfad: $preferredPath" -ForegroundColor Green
    
    # Prüfe ob Pfad existiert
    if (Test-Path $preferredPath) {
        Write-Host "  → Pfad ist gültig und existiert" -ForegroundColor Green
        
        # Versuche DLL zu laden (Test)
        try {
            $assembly = [System.Reflection.Assembly]::LoadFrom($preferredPath)
            Write-Host "  → DLL erfolgreich ladbar!" -ForegroundColor Green
            Write-Host "    Assembly: $($assembly.FullName)" -ForegroundColor Gray
        }
        catch {
            Write-Host "  ⚠️  Fehler beim Laden der DLL: $_" -ForegroundColor Yellow
        }
    }
    else {
        Write-Host "  ✗ WARNUNG: Pfad existiert nicht!" -ForegroundColor Red
    }
}
else {
    Write-Host "✗ Kein bevorzugter Pfad gefunden" -ForegroundColor Red
}

# Zusammenfassung
Write-Host "`n╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║     TEST ABGESCHLOSSEN                                    ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

Write-Host "Empfehlung:" -ForegroundColor Yellow

if ($result.UseSystemLibreHardwareMonitor) {
    Write-Host "  ✓ System-Installation verwenden (keine Defender-Probleme)" -ForegroundColor Green
}
elseif (-not $lhm.Found -and $wingetAvailable) {
    Write-Host "  → Installation über Winget empfohlen:" -ForegroundColor Cyan
    Write-Host "    winget install LibreHardwareMonitor.LibreHardwareMonitor" -ForegroundColor Gray
}
else {
    Write-Host "  → Integrierte Bibliotheken verwenden (Defender-Ausnahme erforderlich)" -ForegroundColor Yellow
}

Write-Host ""

# SIG # Begin signature block
# MIIcSgYJKoZIhvcNAQcCoIIcOzCCHDcCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDEBxwJ7x7bMydu
# 3fVhyA2hposHh9JT50SDhdZBaX4FjKCCFnowggM8MIICJKADAgECAhBJfyGrXBJT
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
# MQ4wDAYKKwYBBAGCNwIBFTAvBgkqhkiG9w0BCQQxIgQglK/HOxSlccCTJUNGF96n
# KXnpm8N2owT36dcEXHBX86swDQYJKoZIhvcNAQEBBQAEggEAhE6Rv5ZHfqC70gr/
# yHuhTrJinFeURPHF38iZPqeFyp5NhUqY4SRNW+kNCEYWnK+ybHQEGby6t/tsO+/J
# Xje+OdpCtbVt/TASTGmhQttO4Jd0nO8qFMaJc/d/PDRErgOYxlUEsfQ+W2SmzytG
# 8rwaU51m1O7l58F5ivJ8r9cWpp0g0hRSmIjTme9PD3TI/g3lPI0hilyg2YR7ecXR
# i4FQ9em+UShL7+SZSRo+488ACyMm3KvtWyCGZlvj6OoK4qhOKa+ZAEi0dOy40eJL
# MWSWFh9DkrM25Yp8y7FEuOoEMOQJfxuMM4OJtCdQg20oGDtfrjMuXnrJYMMdnypg
# c6YfqaGCAyYwggMiBgkqhkiG9w0BCQYxggMTMIIDDwIBATB9MGkxCzAJBgNVBAYT
# AlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5jLjFBMD8GA1UEAxM4RGlnaUNlcnQg
# VHJ1c3RlZCBHNCBUaW1lU3RhbXBpbmcgUlNBNDA5NiBTSEEyNTYgMjAyNSBDQTEC
# EAqA7xhLjfEFgtHEdqeVdGgwDQYJYIZIAWUDBAIBBQCgaTAYBgkqhkiG9w0BCQMx
# CwYJKoZIhvcNAQcBMBwGCSqGSIb3DQEJBTEPFw0yNjAxMjAxODAyNThaMC8GCSqG
# SIb3DQEJBDEiBCBqwYLqh909IzIyVGJEWC9wzoIraR+RUFsY2sUVLBrDlDANBgkq
# hkiG9w0BAQEFAASCAgAGH03QYSNqwrCmkKCGxWOdMeKdnbfEhOEzbAbfyqhDKk60
# YEZspkdBBbIctw5ZM08gCfxoO+Q6DKQKagXCZzFa42Xdxw7U1HUoTD2Bo2VKQflr
# fnzHrML812p4d0QaISO453Epe0Jgy4j+tASHM/6MGZOkWbWmGWTRAFj2AsMma2j3
# U+y5Q/9VrnpPMWmHaxA8oNkXn2ra+I6Wf+r/8/gDpX+QF7VE5IPbBw3IbprJxNU3
# djl33nD6S/Vihi23T843K/m1I7Bst/yK979fXgb6GcVNp8cxQP5LY3am2b+2+ypi
# RC+77b07YrNeTxnMNsQ9jbXDtSZtIdf8R4N7/uDdnue3/kW2XVUmZ95uDmrZx6o2
# nKmJP3LKOb8+KV7PwZW6plib2hqo0+6IY+87hgf8XWoXHOkDLD3wsD9YWOT+dFkp
# JXkCJIXFEtglaA840GKgyP3pv2pqTIaeDJinOcXK2wv8aXfmUI2SYd4d7VvBmKtD
# p9ccTIVFkN5EizU8G4gVZZwLcbgmfVvmSRqztgxgxC7oyutWWjhyKaFB+3rfSFyJ
# msx/kO7bPdB2/PvBzA6ZjbI8v/l5od7wL29HKVQZinOt+R9ZB8zGFoVOqIZL0l4B
# sNOlMMRL8Bni5iApYodQqcN2uJ8nPwDlNTcs04bLRAU4/qHn4ctl148JeIltrg==
# SIG # End signature block

# Test-InstallerDependencies.ps1
# Testet ob alle Abhängigkeiten nach der Installation vorhanden sind

Write-Host "`n╔═══════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  🔍 INSTALLER DEPENDENCY CHECK                       ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

$results = @()

# 1. Prüfe WinGet
Write-Host "1️⃣  WINGET VERFÜGBARKEIT" -ForegroundColor Yellow
Write-Host "   ────────────────────────" -ForegroundColor Gray
try {
    $wingetCmd = Get-Command winget -ErrorAction Stop
    Write-Host "   ✓ WinGet installiert: $($wingetCmd.Version)" -ForegroundColor Green
    $results += @{Component="WinGet"; Status="✓"; Details=$wingetCmd.Source}
}
catch {
    Write-Host "   ✗ WinGet NICHT installiert!" -ForegroundColor Red
    Write-Host "     → Hardware-Monitor wird nicht funktionieren" -ForegroundColor Red
    $results += @{Component="WinGet"; Status="✗"; Details="Nicht gefunden"}
}

# 2. Prüfe LibreHardwareMonitor (System)
Write-Host "`n2️⃣  LIBREHARDWAREMONITOR (SYSTEM-INSTALLATION)" -ForegroundColor Yellow
Write-Host "   ──────────────────────────────────────────────" -ForegroundColor Gray
$systemPaths = @(
    "${env:LOCALAPPDATA}\Microsoft\WinGet\Packages\LibreHardwareMonitor*\LibreHardwareMonitorLib.dll",
    "${env:ProgramFiles}\LibreHardwareMonitor\LibreHardwareMonitorLib.dll"
)

$systemDllFound = $false
foreach ($path in $systemPaths) {
    $resolved = Resolve-Path $path -ErrorAction SilentlyContinue
    if ($resolved) {
        Write-Host "   ✓ System-DLL gefunden: $($resolved.Path)" -ForegroundColor Green
        
        # Prüfe Version
        try {
            $fileInfo = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($resolved.Path)
            Write-Host "     Version: $($fileInfo.FileVersion)" -ForegroundColor Cyan
            Write-Host "     Produkt: $($fileInfo.ProductName)" -ForegroundColor Cyan
            
            # Prüfe ob PawnIO erwähnt wird (schwer zu detektieren, da dynamisch geladen)
            Write-Host "     Treiber: PawnIO (v0.9.4+) oder WinRing0 (< v0.9.4)" -ForegroundColor Yellow
            
            $results += @{Component="LibreHWM (System)"; Status="✓"; Details=$fileInfo.FileVersion}
        }
        catch {
            Write-Host "     ⚠️  Version nicht lesbar" -ForegroundColor Yellow
            $results += @{Component="LibreHWM (System)"; Status="✓"; Details="Version unbekannt"}
        }
        
        $systemDllFound = $true
        break
    }
}

if (-not $systemDllFound) {
    Write-Host "   ✗ KEINE System-Installation gefunden!" -ForegroundColor Red
    Write-Host "     → Hardware-Monitor wird NICHT funktionieren" -ForegroundColor Red
    Write-Host "     → Installiere via: winget install LibreHardwareMonitor.LibreHardwareMonitor" -ForegroundColor Yellow
    $results += @{Component="LibreHWM (System)"; Status="✗"; Details="Nicht installiert"}
}

# 3. Prüfe gebündelte DLL im Lib/ Ordner
Write-Host "`n3️⃣  GEBÜNDELTE DLL (LIB/ ORDNER - FALLBACK)" -ForegroundColor Yellow
Write-Host "   ───────────────────────────────────────────" -ForegroundColor Gray
$scriptRoot = Split-Path -Parent $PSScriptRoot
$bundledPaths = @(
    (Join-Path $scriptRoot "Lib\LibreHardwareMonitorLib.dll")
)

$bundledDllFound = $false
foreach ($path in $bundledPaths) {
    if (Test-Path $path) {
        Write-Host "   ✓ Gebündelte DLL gefunden: $path" -ForegroundColor Green
        
        try {
            $fileInfo = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($path)
            Write-Host "     Version: $($fileInfo.FileVersion)" -ForegroundColor Cyan
            Write-Host "     ⚠️  WARNUNG: Treiber-Installation NICHT möglich aus Lib/" -ForegroundColor Yellow
            Write-Host "        Grund: PawnIO/WinRing0 werden nur bei System-Installation extrahiert" -ForegroundColor Yellow
            
            $results += @{Component="LibreHWM (Bundled)"; Status="⚠️"; Details="Ohne Treiber"}
        }
        catch {
            Write-Host "     ⚠️  Version nicht lesbar" -ForegroundColor Yellow
            $results += @{Component="LibreHWM (Bundled)"; Status="⚠️"; Details="Version unbekannt"}
        }
        
        $bundledDllFound = $true
        break
    }
}

if (-not $bundledDllFound) {
    Write-Host "   ✗ Keine gebündelte DLL gefunden!" -ForegroundColor Red
    $results += @{Component="LibreHWM (Bundled)"; Status="✗"; Details="Fehlt"}
}

# 4. Prüfe SQLite
Write-Host "`n4️⃣  SQLITE-BIBLIOTHEK" -ForegroundColor Yellow
Write-Host "   ────────────────────" -ForegroundColor Gray
$sqlitePath = Join-Path $scriptRoot "Lib\System.Data.SQLite.dll"
if (Test-Path $sqlitePath) {
    Write-Host "   ✓ SQLite-DLL vorhanden: $sqlitePath" -ForegroundColor Green
    $results += @{Component="SQLite"; Status="✓"; Details="Vorhanden"}
}
else {
    Write-Host "   ✗ SQLite-DLL fehlt!" -ForegroundColor Red
    $results += @{Component="SQLite"; Status="✗"; Details="Fehlt"}
}

# 5. Zusammenfassung
Write-Host "`n╔═══════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  📊 ZUSAMMENFASSUNG                                  ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

$results | Format-Table -Property @(
    @{Label="Komponente"; Expression={$_.Component}; Width=30},
    @{Label="Status"; Expression={$_.Status}; Width=10},
    @{Label="Details"; Expression={$_.Details}; Width=40}
) -AutoSize

# Finale Bewertung
$criticalMissing = $results | Where-Object { $_.Status -eq "✗" -and $_.Component -like "*LibreHWM (System)*" }
if ($criticalMissing) {
    Write-Host "🔴 KRITISCH: Hardware-Monitoring wird NICHT funktionieren!" -ForegroundColor Red
    Write-Host "   Lösung: winget install LibreHardwareMonitor.LibreHardwareMonitor" -ForegroundColor Yellow
    exit 1
}
elseif ($systemDllFound -and $bundledDllFound) {
    Write-Host "🟢 OPTIMAL: Alle Abhängigkeiten erfüllt!" -ForegroundColor Green
    Write-Host "   System-DLL mit PawnIO-Treiber wird verwendet" -ForegroundColor Cyan
    exit 0
}
else {
    Write-Host "🟡 TEILWEISE: Eingeschränkter Modus möglich" -ForegroundColor Yellow
    Write-Host "   Empfehlung: System-Installation via WinGet" -ForegroundColor Cyan
    exit 2
}

# SIG # Begin signature block
# MIIcSgYJKoZIhvcNAQcCoIIcOzCCHDcCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCNX81d6oc95f58
# Ks49YDBy9YlM3Md07gklkMdhYYfyXaCCFnowggM8MIICJKADAgECAhBJfyGrXBJT
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
# MQ4wDAYKKwYBBAGCNwIBFTAvBgkqhkiG9w0BCQQxIgQgFNlkZC554gzkF8hQd89p
# nzvnFSZlMmM/Mbu9gucxu8cwDQYJKoZIhvcNAQEBBQAEggEADKqR+CuC9ePyaAhj
# d/CRAwmEZ/4+lQChPlbjjOq79mnro5T1oBAaKX6QsIH0W63PbuAcPyijfI993dTC
# 09XwZy4vPrs+FbVb4eaTHIRx27w4sEyNzswz5TQ/FtM3a4vQ432Gn/ucvkXDcg0b
# NTl1vOQwWgGSYj9AwscNIj9G10Xnoe6U4OrONaT6hv/PitPZZP4hw2nEzBAC034T
# W81rI8xrjrEOWMTL4chvwkgOf0T9dTaBAqeMOVXmrkzpIk/qkwgwLo7+Lr9SzOkG
# NLOHT5kNbxpQyTwwJhR171GYSq+41oWMGSthpveG0jr0kzFZKTtQrdg6//hP4Erl
# DMSL8aGCAyYwggMiBgkqhkiG9w0BCQYxggMTMIIDDwIBATB9MGkxCzAJBgNVBAYT
# AlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5jLjFBMD8GA1UEAxM4RGlnaUNlcnQg
# VHJ1c3RlZCBHNCBUaW1lU3RhbXBpbmcgUlNBNDA5NiBTSEEyNTYgMjAyNSBDQTEC
# EAqA7xhLjfEFgtHEdqeVdGgwDQYJYIZIAWUDBAIBBQCgaTAYBgkqhkiG9w0BCQMx
# CwYJKoZIhvcNAQcBMBwGCSqGSIb3DQEJBTEPFw0yNjAxMjAxODAyNTlaMC8GCSqG
# SIb3DQEJBDEiBCDoGUlYhMd4Z825w2yEptM2hOtBC/a60Mona5rZqxFroTANBgkq
# hkiG9w0BAQEFAASCAgBvb1b8f0HftlCosf19l2XlMXGLUrQLl6dVg0OvYQFjyIFm
# QjWzsuCzP+1bt4DdVjFjSEJIpXYsv54c1J36hqiP+5M5waponRgoWAxWSP5i2e7T
# yC9jFsA3riChP2fcJCedZ0NUpYhgEf7iLLwxsu+OlS1UcOefKlp5AWttafLPUZIY
# UKpiEntLW9iqNgwvlWirixFmRsIZuZrShO1rVyF6v191qzzfHX96haZkuMd3cvKI
# 20ljzEd58kIxJkC1Wh00fl+BY1EC3YjX3F4PEKgN62qznf7ZoznSeDcFiGKTyxUh
# S4QvHs7zE1z/vSnEdkkpH+vT7xY1JoFxc4nh31af5aMdWwpNVHc2Fbat/ImV0vkU
# 04kAoDqo7kmACRlyuORnOZcjsAsQ2Wi8q98LhilBYntaarjuLV7MKlqE/N81mGgt
# 9K4kOi6izG2z5mXROZ90oLj6TEog6KxCDnlzwo8AJ0Ltd0UqGKjYoUHjlyoLrTa6
# ZHLKmAZX/Kxcbjcg/MX6m2EBcsJb9Vek+QFJ4RE7cfYyQWF6exbXNJMoswH65xys
# xK7YLFlwoQn9OcGwZV+ZkVrAh/Ad2wS3TIczBjsiQnAG2K2X3O+LvgVvsHQ1SdhR
# eZvlL07IWSYk2q6HyNSLJ8wXcGmGhS/BDPy/bhwKKfLl86sjG7y20QOKRHnq9A==
# SIG # End signature block

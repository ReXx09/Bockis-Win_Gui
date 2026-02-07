# Test-HardwareMonitorFallback.ps1
# Testet das Hardware-Monitoring im Fallback-Modus (ohne LibreHardwareMonitor)

Write-Host "`n╔═══════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  Hardware-Monitor Fallback-Modus Test                                ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

# Module laden
$modulePath = Split-Path -Parent $PSScriptRoot
Import-Module "$modulePath\Modules\Monitor\FallbackSensors.psm1" -Force -Verbose
Import-Module "$modulePath\Modules\Monitor\HardwareMonitorTools.psm1" -Force -Verbose

Write-Host "`n═══ 1. Fallback-Sensor-Verfügbarkeit ═══" -ForegroundColor Yellow
$fallbackInfo = Get-FallbackSensorsInfo

Write-Host "  CPU-Last (Performance Counter):`t" -NoNewline
if ($fallbackInfo.CpuLoad) { 
    Write-Host "✅ Verfügbar" -ForegroundColor Green 
} else { 
    Write-Host "❌ Nicht verfügbar" -ForegroundColor Red 
}

Write-Host "  Thermal Zones (WMI ACPI):`t`t" -NoNewline
if ($fallbackInfo.ThermalZones) { 
    Write-Host "✅ Verfügbar" -ForegroundColor Green 
} else { 
    Write-Host "⚠️  Nicht verfügbar (normal)" -ForegroundColor Yellow 
}

Write-Host "  Speicher-Auslastung (CIM):`t`t" -NoNewline
if ($fallbackInfo.MemoryUsage) { 
    Write-Host "✅ Verfügbar" -ForegroundColor Green 
} else { 
    Write-Host "❌ Nicht verfügbar" -ForegroundColor Red 
}

Write-Host "  Disk Activity (Performance Counter):`t" -NoNewline
if ($fallbackInfo.DiskActivity) { 
    Write-Host "✅ Verfügbar" -ForegroundColor Green 
} else { 
    Write-Host "⚠️  Nicht verfügbar" -ForegroundColor Yellow 
}

Write-Host "  HWiNFO Shared Memory:`t`t`t" -NoNewline
if ($fallbackInfo.HWiNFO) { 
    Write-Host "✅ Verfügbar" -ForegroundColor Green 
} else { 
    Write-Host "⚠️  Nicht aktiv" -ForegroundColor Yellow 
}

Write-Host "`n═══ 2. Live-Daten Test (5 Iterationen) ═══" -ForegroundColor Yellow

# Erstelle Mock-UI-Elemente
Add-Type -AssemblyName System.Windows.Forms
$cpuLabel = New-Object System.Windows.Forms.Label
$gpuLabel = New-Object System.Windows.Forms.Label
$ramLabel = New-Object System.Windows.Forms.Label
$cpuPanel = New-Object System.Windows.Forms.Panel
$gpuPanel = New-Object System.Windows.Forms.Panel
$ramPanel = New-Object System.Windows.Forms.Panel

# Simuliere Fallback-Modus
$script:useFallbackSensors = $true
$script:useLibreHardware = $false

for ($i = 1; $i -le 5; $i++) {
    Write-Host "`n--- Iteration $i ---" -ForegroundColor Cyan
    
    # CPU-Update
    try {
        Update-CpuInfoFallback -CpuLabel $cpuLabel -Panel $cpuPanel
        Write-Host "  CPU: $($cpuLabel.Text)" -ForegroundColor White
        Write-Host "       Panel-Farbe: $($cpuPanel.BackColor.Name)" -ForegroundColor Gray
    } catch {
        Write-Host "  CPU: ❌ Fehler - $_" -ForegroundColor Red
    }
    
    # GPU-Update
    try {
        Update-GpuInfoFallback -GpuLabel $gpuLabel -Panel $gpuPanel
        Write-Host "  GPU: $($gpuLabel.Text)" -ForegroundColor White
        Write-Host "       Panel-Farbe: $($gpuPanel.BackColor.Name)" -ForegroundColor Gray
    } catch {
        Write-Host "  GPU: ❌ Fehler - $_" -ForegroundColor Red
    }
    
    # RAM-Update
    try {
        Update-RamInfoFallback -RamLabel $ramLabel -Panel $ramPanel
        Write-Host "  RAM: $($ramLabel.Text)" -ForegroundColor White
        Write-Host "       Panel-Farbe: $($ramPanel.BackColor.Name)" -ForegroundColor Gray
    } catch {
        Write-Host "  RAM: ❌ Fehler - $_" -ForegroundColor Red
    }
    
    if ($i -lt 5) {
        Start-Sleep -Seconds 2
    }
}

Write-Host "`n═══ 3. Performance-Vergleich ═══" -ForegroundColor Yellow

# Test CPU-Last Performance
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
for ($i = 1; $i -le 100; $i++) {
    $null = Get-CpuLoadFallback
}
$stopwatch.Stop()
$cpuAvgMs = [math]::Round($stopwatch.ElapsedMilliseconds / 100, 2)
Write-Host "  CPU-Last (100x Calls): $cpuAvgMs ms/call" -ForegroundColor White

# Test Memory-Auslastung Performance
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
for ($i = 1; $i -le 100; $i++) {
    $null = Get-MemoryUsageFallback
}
$stopwatch.Stop()
$memAvgMs = [math]::Round($stopwatch.ElapsedMilliseconds / 100, 2)
Write-Host "  RAM-Auslastung (100x Calls): $memAvgMs ms/call" -ForegroundColor White

Write-Host "`n═══ 4. Fehlerprüfung ═══" -ForegroundColor Yellow

$errors = @()

# Prüfe ob Funktionen exportiert sind
$exportedFunctions = Get-Command -Module FallbackSensors -ErrorAction SilentlyContinue
if ($exportedFunctions.Count -lt 7) {
    $errors += "Nicht alle Fallback-Funktionen exportiert (erwartet: 7, gefunden: $($exportedFunctions.Count))"
}

# Prüfe ob HardwareMonitorTools-Funktionen existieren
$hwMonFunctions = @('Update-CpuInfoFallback', 'Update-GpuInfoFallback', 'Update-RamInfoFallback')
foreach ($func in $hwMonFunctions) {
    if (-not (Get-Command $func -ErrorAction SilentlyContinue)) {
        $errors += "Funktion '$func' nicht gefunden"
    }
}

# Prüfe ob Performance Counters existieren
try {
    $null = Get-Counter '\Processor(_Total)\% Processor Time' -ErrorAction Stop
} catch {
    $errors += "Performance Counter für CPU nicht verfügbar"
}

try {
    $null = Get-CimInstance -ClassName CIM_OperatingSystem -ErrorAction Stop
} catch {
    $errors += "CIM_OperatingSystem nicht verfügbar (RAM-Fallback fehlschlägt)"
}

if ($errors.Count -eq 0) {
    Write-Host "  ✅ Keine Fehler gefunden" -ForegroundColor Green
} else {
    Write-Host "  ⚠️  $($errors.Count) Fehler gefunden:" -ForegroundColor Yellow
    foreach ($error in $errors) {
        Write-Host "     - $error" -ForegroundColor Red
    }
}

Write-Host "`n═══ ZUSAMMENFASSUNG ═══" -ForegroundColor Cyan
Write-Host ""
Write-Host "Fallback-Modus Status:" -ForegroundColor White
Write-Host "  ✅ CPU-Last: $(if ($fallbackInfo.CpuLoad) { 'Funktioniert' } else { 'Nicht verfügbar' })" -ForegroundColor $(if ($fallbackInfo.CpuLoad) { 'Green' } else { 'Red' })
Write-Host "  ✅ RAM-Auslastung: $(if ($fallbackInfo.MemoryUsage) { 'Funktioniert' } else { 'Nicht verfügbar' })" -ForegroundColor $(if ($fallbackInfo.MemoryUsage) { 'Green' } else { 'Red' })
Write-Host "  ⚠️  CPU-Temperatur: Nur mit ACPI Thermal Zones (meist nicht verfügbar)" -ForegroundColor Yellow
Write-Host "  ⚠️  GPU-Details: Nur Name & Last (keine Temp/Frequenz/Power)" -ForegroundColor Yellow
Write-Host "  ❌ RAM-Temperatur: Nicht verfügbar ohne Ring-0" -ForegroundColor Red
Write-Host ""
Write-Host "Empfehlung:" -ForegroundColor White
Write-Host "  Für volle Sensor-Unterstützung LibreHardwareMonitor installieren:" -ForegroundColor Gray
Write-Host "  winget install LibreHardwareMonitor.LibreHardwareMonitor" -ForegroundColor Cyan
Write-Host ""

# SIG # Begin signature block
# MIIcSgYJKoZIhvcNAQcCoIIcOzCCHDcCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCA6DTWODPChPM0N
# mH8rWetgTm/zeFTZKkTZ20qmXqbjqaCCFnowggM8MIICJKADAgECAhBJfyGrXBJT
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
# MQ4wDAYKKwYBBAGCNwIBFTAvBgkqhkiG9w0BCQQxIgQgHStwRQ2+sMWnlPp/g4HK
# 60UHTHKsr7yGFwDt2BXDDfMwDQYJKoZIhvcNAQEBBQAEggEAf4XzVl9CFOmjfnQQ
# QPlNSBGz3EMxmdIuDriJdtNVupjpZyrBVJ072DEU22J6QUcLV2H8A6g6bwZUgtVB
# hFGp720zayCYXUzcZH7D2IQT9pAXaUIJQUHUeY9O//+Z+ZP7VJ6PhzMI1xY0u9Xd
# Sz0E4O5khxgixrLLkeZWVWoew2lMaVxp7/CPMtYnUHPucuwShGjXUSeN1BIGLFW1
# CMXcpHo3DJ6tPDdfX8DF8hECXSKY1ylHXjsBAWoG6VquzbVhkM1k9JiycCigXSd4
# NzWEjgCYFlUn7MEb6MAyBA9r2AVfK0uJjjtBoD5oJ6TgXFfcpLDQ5CYNKWa3SU9J
# CZe6aKGCAyYwggMiBgkqhkiG9w0BCQYxggMTMIIDDwIBATB9MGkxCzAJBgNVBAYT
# AlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5jLjFBMD8GA1UEAxM4RGlnaUNlcnQg
# VHJ1c3RlZCBHNCBUaW1lU3RhbXBpbmcgUlNBNDA5NiBTSEEyNTYgMjAyNSBDQTEC
# EAqA7xhLjfEFgtHEdqeVdGgwDQYJYIZIAWUDBAIBBQCgaTAYBgkqhkiG9w0BCQMx
# CwYJKoZIhvcNAQcBMBwGCSqGSIb3DQEJBTEPFw0yNjAxMjAxODAyNTlaMC8GCSqG
# SIb3DQEJBDEiBCB2NBB6iIJXTUgMUpXsuTjHzJFJLUEAs3sr0/xa7oUlaDANBgkq
# hkiG9w0BAQEFAASCAgAw/qnE+kkrqEOqwhmHE7O2E4sOvAAl4AUyyX/GhGx0hvIw
# Pstu/ux2GWW0wcO2cKCPETvZ0Or8z3xLEQuYxm8mZgxNmOLUcy8XHwbknN0Q4zui
# gJsjQG+kDtxK2yLhAXA3OTI/IsfbzrGPkOlNVksWBPCEevYC8MDEVA3P2vn1UIio
# w7pCxTA2Ng6JXuB8ARnQxz2d5JXChfBsk0eJK2P2wqMOj58rUh7JUVuUt6Ng9dFF
# 0jtuZL4KRVnOyRZMEgO6Aw0yQ2JVdaxC3dC8eUPqq/YEvTk6r7pf/J5DJM3tObCo
# CVQa3PVL7nYml9CW5P66UP4I8weqbJsY584nIOmgKhLjoGwSHNtettTYXbZcfvu0
# 76bG9yPyaQPkOSHPTw4xi68RdpnZvwyxVm68eEdk6MkqWjI1viQFexe5gqGCX2FN
# 1he0q3o4Fqdo0vXzO1JR3yG6gbgc88nSEokY9wjnZfZHnuF/gGGeDOzLapR33L4R
# rmiWUkjy0kjlhmfVz/eAA+nuo9k7BU8gBcXse1YVQuQZlB5ru3NVs8uOJQXU4JKX
# 3uaM50fbpMHp+UOPPvHk+z8OVCsbKS/ZbD94Up9FGGf2SekXxasBmc8B5q+3il7Z
# A7JYO0fQ90fNNhiEG34r+TWKWiS3rWDnOv/15vgL3qrqVhsNyAU2C3dLK4POeg==
# SIG # End signature block

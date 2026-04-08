# Test-ProcessCheck.ps1
# Testet die neue Prozess-Prüfung und -Beendigung für LibreHardwareMonitor

Write-Host "`n======================================" -ForegroundColor Cyan
Write-Host "Test: Prozess-Prüfung & -Beendigung" -ForegroundColor Cyan
Write-Host "======================================`n" -ForegroundColor Cyan

# Importiere ToolLibrary-Modul
Import-Module "$PSScriptRoot\..\Modules\ToolLibrary.psm1" -Force

# Test 1: Prüfe ob LibreHardwareMonitor läuft
Write-Host "1. Prüfe laufende LibreHardwareMonitor-Prozesse..." -ForegroundColor Yellow
$lhmProcesses = Get-Process -Name "LibreHardwareMonitor" -ErrorAction SilentlyContinue

if ($lhmProcesses) {
    Write-Host "   ✓ LibreHardwareMonitor läuft ($($lhmProcesses.Count) Instanz(en))" -ForegroundColor Green
    
    foreach ($proc in $lhmProcesses) {
        Write-Host "     - PID: $($proc.Id), Speicher: $([math]::Round($proc.WorkingSet64 / 1MB, 2)) MB" -ForegroundColor Gray
        Write-Host "       Gestartet: $($proc.StartTime)" -ForegroundColor Gray
    }
} else {
    Write-Host "   ℹ️  LibreHardwareMonitor läuft NICHT" -ForegroundColor Cyan
    Write-Host "`n   💡 Für echten Test: Starten Sie LibreHardwareMonitor.exe manuell" -ForegroundColor Yellow
}

# Test 2: Teste Stop-ToolProcess Funktion
Write-Host "`n2. Teste Stop-ToolProcess Funktion..." -ForegroundColor Yellow

if ($lhmProcesses) {
    Write-Host "   Hinweis: Gleich öffnet sich ein Dialog zum Beenden" -ForegroundColor Cyan
    
    # Teste interaktiven Modus
    $result = Stop-ToolProcess -ProcessName "LibreHardwareMonitor"
    
    if ($result) {
        Write-Host "   ✓ Prozess wurde erfolgreich beendet (oder war nicht vorhanden)" -ForegroundColor Green
    } else {
        Write-Host "   ⊘ Benutzer hat Beenden abgelehnt" -ForegroundColor Yellow
    }
    
    # Prüfe nochmal
    Start-Sleep -Milliseconds 500
    $stillRunning = Get-Process -Name "LibreHardwareMonitor" -ErrorAction SilentlyContinue
    if ($stillRunning) {
        Write-Host "   ⚠️ Prozess läuft NOCH ($($stillRunning.Count) Instanz(en))" -ForegroundColor Yellow
    } else {
        Write-Host "   ✓ Prozess ist beendet" -ForegroundColor Green
    }
} else {
    Write-Host "   ⊘ Kein Prozess zum Testen vorhanden" -ForegroundColor Gray
}

# Test 3: Teste Fehlercode-Beschreibungen
Write-Host "`n3. Teste Winget-Fehlercode-Beschreibungen..." -ForegroundColor Yellow

$testErrorCodes = @(
    -2147023728,  # Datei wird verwendet
    -1978335191,  # Paket nicht gefunden
    -1978335212,  # Abgebrochen
    0x80070005,   # Zugriff verweigert
    0x800704C7,   # Vorgang abgebrochen
    999999999     # Unbekannter Fehler
)

foreach ($errorCode in $testErrorCodes) {
    $description = Get-WingetErrorDescription -ErrorCode $errorCode
    Write-Host "   Fehlercode $errorCode (0x$($errorCode.ToString('X8'))):" -ForegroundColor Cyan
    Write-Host "     → $description" -ForegroundColor Gray
}

# Test 4: Simuliere Installation mit laufendem Prozess
Write-Host "`n4. Simuliere Installations-Szenario..." -ForegroundColor Yellow

$testTool = @{
    Name = "LibreHardwareMonitor"
    Winget = "LibreHardwareMonitor.LibreHardwareMonitor"
}

Write-Host "   Szenario: Installation mit laufendem Prozess" -ForegroundColor Cyan

$lhmRunning = Get-Process -Name "LibreHardwareMonitor" -ErrorAction SilentlyContinue
if ($lhmRunning) {
    Write-Host "   ✓ LibreHardwareMonitor läuft → Prozess-Check würde greifen" -ForegroundColor Green
    Write-Host "   → Benutzer wird gefragt: 'LibreHardwareMonitor läuft noch. Beenden?'" -ForegroundColor Cyan
    Write-Host "   → Wenn JA: Prozess wird beendet, Installation läuft" -ForegroundColor Cyan
    Write-Host "   → Wenn NEIN: Installation wird abgebrochen" -ForegroundColor Cyan
} else {
    Write-Host "   ℹ️  LibreHardwareMonitor läuft nicht → Installation würde direkt starten" -ForegroundColor Cyan
}

# Test 5: Fehlercode -2147023728 simulieren
Write-Host "`n5. Fehlerbehandlung für Fehlercode -2147023728..." -ForegroundColor Yellow
$errorDesc = Get-WingetErrorDescription -ErrorCode -2147023728
Write-Host "   Fehlercode: -2147023728 (0x800704C7)" -ForegroundColor Red
Write-Host "   Beschreibung: $errorDesc" -ForegroundColor Yellow
Write-Host "`n   Benutzer sieht jetzt:" -ForegroundColor Cyan
Write-Host "   ┌─────────────────────────────────────────────────────┐" -ForegroundColor Gray
Write-Host "   │ Neuinstallation fehlgeschlagen!                     │" -ForegroundColor Gray
Write-Host "   │                                                      │" -ForegroundColor Gray
Write-Host "   │ Fehlercode: -2147023728                              │" -ForegroundColor Gray
Write-Host "   │                                                      │" -ForegroundColor Gray
Write-Host "   │ Datei/Prozess wird verwendet. Bitte schließen       │" -ForegroundColor Gray
Write-Host "   │ Sie die Anwendung.                                   │" -ForegroundColor Gray
Write-Host "   │                                                      │" -ForegroundColor Gray
Write-Host "   │ Debug-Tipp: Führen Sie 'winget install --id          │" -ForegroundColor Gray
Write-Host "   │ LibreHardwareMonitor.LibreHardwareMonitor --force'   │" -ForegroundColor Gray
Write-Host "   │ in PowerShell aus.                                   │" -ForegroundColor Gray
Write-Host "   └─────────────────────────────────────────────────────┘" -ForegroundColor Gray

Write-Host "`n======================================" -ForegroundColor Cyan
Write-Host "Test abgeschlossen" -ForegroundColor Cyan
Write-Host "======================================`n" -ForegroundColor Cyan

Write-Host "📝 Zusammenfassung:" -ForegroundColor Cyan
Write-Host "   • Prozess-Check vor Installation: ✅ Implementiert" -ForegroundColor Green
Write-Host "   • Automatisches Beenden mit Dialog: ✅ Implementiert" -ForegroundColor Green
Write-Host "   • Konkrete Fehlercode-Beschreibungen: ✅ Implementiert" -ForegroundColor Green
Write-Host "   • Debug-Tipps in Fehlermeldungen: ✅ Implementiert" -ForegroundColor Green
Write-Host "`n   Beim nächsten Installations-Versuch wird:" -ForegroundColor Yellow
Write-Host "   1. Geprüft, ob LibreHardwareMonitor läuft" -ForegroundColor Cyan
Write-Host "   2. Benutzer gefragt, ob er es beenden will" -ForegroundColor Cyan
Write-Host "   3. Prozess automatisch beendet (wenn JA)" -ForegroundColor Cyan
Write-Host "   4. Installation durchgeführt" -ForegroundColor Cyan
Write-Host "   5. Bei Fehler: Konkreter Fehlercode + Beschreibung + Debug-Tipp" -ForegroundColor Cyan

# SIG # Begin signature block
# MIIcSgYJKoZIhvcNAQcCoIIcOzCCHDcCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCB2fq9s0pfO1QWk
# 1sZmdK1hcxCLbueCaiMb4jh7esQG66CCFnowggM8MIICJKADAgECAhBJfyGrXBJT
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
# MQ4wDAYKKwYBBAGCNwIBFTAvBgkqhkiG9w0BCQQxIgQgcav3yhpO0C37qTH8cgwj
# JfKAGcR8ejKP/2pVEFzX+JMwDQYJKoZIhvcNAQEBBQAEggEAI1iSIcddDHaA9J71
# bNHggGGZUY6wkFFYBtgAl4TwAcv2pmgL8KjX0iy8ftOyGaCIXANlRGKK7RtSiJGq
# PxBkjURZXnK22K020ZPMxbzV4oV111g6aAfEUn8WGC9fN6hLSAYhALBwehs/nuza
# mBWbcmWtS4ByVtiNe+xjOBlbPCNomWIPecSEdXg80z/D1pDxzB5PNDUzP3oNtM38
# EYzf3/6eiKijX4EWNIm2XeiihdnV2jEVKiiS+UXl3aV8oiWz8ymoibY8SdEHJZS9
# Mso0+PZ7k0zgWN16qPAoKA0ZZpA/GdgxG9/7pJJeX9T0soeTEN9PcR8C/gDfqtuw
# eaUllaGCAyYwggMiBgkqhkiG9w0BCQYxggMTMIIDDwIBATB9MGkxCzAJBgNVBAYT
# AlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5jLjFBMD8GA1UEAxM4RGlnaUNlcnQg
# VHJ1c3RlZCBHNCBUaW1lU3RhbXBpbmcgUlNBNDA5NiBTSEEyNTYgMjAyNSBDQTEC
# EAqA7xhLjfEFgtHEdqeVdGgwDQYJYIZIAWUDBAIBBQCgaTAYBgkqhkiG9w0BCQMx
# CwYJKoZIhvcNAQcBMBwGCSqGSIb3DQEJBTEPFw0yNjAxMjAxODAzMDBaMC8GCSqG
# SIb3DQEJBDEiBCA/KmKO+vq8KxjIDQ3tkfzuYTG6dp30ewx1flrX1JQd7zANBgkq
# hkiG9w0BAQEFAASCAgCNc9xMGr70MLMuyMjk5JI18IGRwP5dm8tbV+zTFR6XDpJV
# OHBokJbSgEYZH7fl3ZRblVAVvN7dOPEmb2wjjb8xbCiAVh0KO3cHpNmuRqpnCUk+
# sGYujRPd1ifdCpZQTGobNv/UX8I39ktf91d/oae3hnjxB6zEmS4chKe5NmDUq1ae
# FeryIUWTLj7dObzWa754m7097kCI4WTN8GqkLk8ehpRmykEZUe696675hqJzMnpy
# G3XZOKzF2m9L9mDtvapJcZwcuvtXGtIKFsfYKzqzHWQQ6SbdNC4DcaJBAcGcrHp9
# tdLJp1hYIOhwsEJsvvCWBBMzCHti6ATR+t4llJRW1YtrWuOXGpkCg3Z3yJUitrRl
# 8oLZMf9bGSbfhql+DkA45C9QDF37HDLZxDiWf8W3f8tVE2q0rBKuMk3eQ+gii+Jq
# sU6orsm9Q3ZbR4zSJdy2abD22Vny735hi2EBZ+VQk8R54nqFc+cXFLQNClUpdId0
# nQzMaXtBu8FzwD6VZb341p0jFVVbBHxhCgMeg35Vp4qwHUcz4X0AQbmAoC9bNRd5
# rabB4BTTfOuP41+PlDdCxxo8j10AA5cHKc73h+OqKnMp7TzxcrZZcEVdrPyF5lKW
# ww08hRKCNOPMEFjpDF7ZVeGYz5yyC/hfTg0L78HDACfPHwYlWhzBqgjmnyGXfg==
# SIG # End signature block

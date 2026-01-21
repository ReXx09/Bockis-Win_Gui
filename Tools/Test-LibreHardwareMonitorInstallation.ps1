# Test-LibreHardwareMonitorInstallation.ps1
# Testet, ob LibreHardwareMonitor korrekt installiert wurde und gefunden werden kann

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "LibreHardwareMonitor Installation Test" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# 1. Prüfe WinGet-Installation
Write-Host "1. Prüfe WinGet-Pakete..." -ForegroundColor Yellow
$wingetPackages = winget list --id LibreHardwareMonitor.LibreHardwareMonitor 2>$null
if ($wingetPackages -match "LibreHardwareMonitor") {
    Write-Host "   ✓ LibreHardwareMonitor ist via WinGet installiert" -ForegroundColor Green
} else {
    Write-Host "   ✗ LibreHardwareMonitor ist NICHT via WinGet installiert" -ForegroundColor Red
}

# 2. Suche nach DLL-Dateien
Write-Host "`n2. Suche nach LibreHardwareMonitorLib.dll..." -ForegroundColor Yellow
$dllPaths = @()

# WinGet-Pfad
try {
    $wingetDlls = Get-ChildItem -Path "${env:LOCALAPPDATA}\Microsoft\WinGet\Packages" -Filter "LibreHardwareMonitor*" -Directory -ErrorAction SilentlyContinue | 
        ForEach-Object { 
            $dllPath = Join-Path $_.FullName "LibreHardwareMonitorLib.dll"
            if (Test-Path $dllPath) {
                $dllPath
            }
        }
    $dllPaths += $wingetDlls
}
catch {
    Write-Host "   ⚠ Fehler beim Suchen in WinGet-Packages: $_" -ForegroundColor Yellow
}

# Gebundene Lib
$bundledDllPath = Join-Path $PSScriptRoot "..\Lib\LibreHardwareMonitorLib.dll"
if (Test-Path $bundledDllPath) {
    $dllPaths += $bundledDllPath
}

if ($dllPaths.Count -gt 0) {
    Write-Host "   ✓ Gefundene DLL-Dateien:" -ForegroundColor Green
    foreach ($dll in $dllPaths) {
        $fileInfo = Get-Item $dll
        Write-Host "     - $dll" -ForegroundColor Cyan
        Write-Host "       Größe: $([math]::Round($fileInfo.Length / 1MB, 2)) MB" -ForegroundColor Gray
        Write-Host "       Datum: $($fileInfo.LastWriteTime)" -ForegroundColor Gray
    }
} else {
    Write-Host "   ✗ KEINE LibreHardwareMonitorLib.dll gefunden!" -ForegroundColor Red
}

# 3. Suche nach EXE-Dateien
Write-Host "`n3. Suche nach LibreHardwareMonitor.exe..." -ForegroundColor Yellow
$exePaths = @()

try {
    $wingetExes = Get-ChildItem -Path "${env:LOCALAPPDATA}\Microsoft\WinGet\Packages" -Filter "LibreHardwareMonitor*" -Directory -ErrorAction SilentlyContinue | 
        ForEach-Object { 
            $exePath = Join-Path $_.FullName "LibreHardwareMonitor.exe"
            if (Test-Path $exePath) {
                $exePath
            }
        }
    $exePaths += $wingetExes
}
catch {
    Write-Host "   ⚠ Fehler beim Suchen in WinGet-Packages: $_" -ForegroundColor Yellow
}

if ($exePaths.Count -gt 0) {
    Write-Host "   ✓ Gefundene EXE-Dateien:" -ForegroundColor Green
    foreach ($exe in $exePaths) {
        $fileInfo = Get-Item $exe
        Write-Host "     - $exe" -ForegroundColor Cyan
        Write-Host "       Version: $($fileInfo.VersionInfo.FileVersion)" -ForegroundColor Gray
        Write-Host "       Datum: $($fileInfo.LastWriteTime)" -ForegroundColor Gray
    }
} else {
    Write-Host "   ✗ KEINE LibreHardwareMonitor.exe gefunden!" -ForegroundColor Red
}

# 4. Teste DLL-Laden
Write-Host "`n4. Teste DLL-Laden (ohne Ring0-Treiber)..." -ForegroundColor Yellow
if ($dllPaths.Count -gt 0) {
    $testDll = $dllPaths[0]
    try {
        Add-Type -Path $testDll -ErrorAction Stop
        Write-Host "   ✓ DLL erfolgreich geladen!" -ForegroundColor Green
        
        # Versuche Computer-Objekt zu erstellen
        try {
            $computer = New-Object LibreHardwareMonitor.Hardware.Computer
            $computer.IsCpuEnabled = $true
            Write-Host "   ✓ Computer-Objekt erfolgreich erstellt!" -ForegroundColor Green
            
            # Versuche zu öffnen (benötigt Admin-Rechte für Ring0)
            try {
                $computer.Open()
                Write-Host "   ✓ Hardware-Monitor erfolgreich geöffnet!" -ForegroundColor Green
                
                # Prüfe CPU-Hardware
                $cpuHardware = $computer.Hardware | Where-Object { $_.HardwareType -eq 'Cpu' } | Select-Object -First 1
                if ($cpuHardware) {
                    $cpuHardware.Update()
                    $tempSensors = $cpuHardware.Sensors | Where-Object { $_.SensorType -eq 'Temperature' -and $_.Value -ne $null }
                    
                    if ($tempSensors.Count -gt 0) {
                        Write-Host "   ✓ Ring0-Treiber AKTIV - $($tempSensors.Count) Temp-Sensoren verfügbar!" -ForegroundColor Green
                        Write-Host "     Beispiel: $($tempSensors[0].Name) = $($tempSensors[0].Value)°C" -ForegroundColor Cyan
                    } else {
                        Write-Host "   ⚠ Ring0-Treiber NICHT AKTIV - Temperatursensoren fehlen" -ForegroundColor Yellow
                        Write-Host "     Mögliche Ursachen:" -ForegroundColor Yellow
                        Write-Host "       - Admin-Rechte fehlen" -ForegroundColor Gray
                        Write-Host "       - Windows Defender blockiert WinRing0-Treiber" -ForegroundColor Gray
                        Write-Host "       - .exe wurde noch nie gestartet (Treiber nicht registriert)" -ForegroundColor Gray
                    }
                } else {
                    Write-Host "   ⚠ Keine CPU-Hardware gefunden" -ForegroundColor Yellow
                }
                
                $computer.Close()
            }
            catch {
                Write-Host "   ✗ Fehler beim Öffnen: $($_.Exception.Message)" -ForegroundColor Red
            }
        }
        catch {
            Write-Host "   ✗ Fehler beim Erstellen des Computer-Objekts: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    catch {
        if ($_.Exception.Message -like "*bereits geladen*") {
            Write-Host "   ✓ DLL bereits geladen (ist OK)" -ForegroundColor Green
        } else {
            Write-Host "   ✗ Fehler beim Laden: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
} else {
    Write-Host "   ⊘ Keine DLL zum Testen verfügbar" -ForegroundColor Gray
}

# 5. Windows Defender Status
Write-Host "`n5. Prüfe Windows Defender Exclusions..." -ForegroundColor Yellow
try {
    $exclusions = Get-MpPreference | Select-Object -ExpandProperty ExclusionPath
    $hasExclusion = $false
    
    foreach ($path in $dllPaths + $exePaths) {
        $dir = Split-Path -Parent $path
        if ($exclusions -contains $dir) {
            Write-Host "   ✓ Defender-Ausnahme für $dir vorhanden" -ForegroundColor Green
            $hasExclusion = $true
        }
    }
    
    if (-not $hasExclusion) {
        Write-Host "   ⚠ KEINE Defender-Ausnahme gefunden!" -ForegroundColor Yellow
        Write-Host "     Empfehlung: Fügen Sie eine Ausnahme hinzu für:" -ForegroundColor Yellow
        if ($dllPaths.Count -gt 0) {
            Write-Host "       $(Split-Path -Parent $dllPaths[0])" -ForegroundColor Cyan
        }
    }
}
catch {
    Write-Host "   ⚠ Konnte Defender-Status nicht prüfen (Admin-Rechte erforderlich): $_" -ForegroundColor Yellow
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Test abgeschlossen" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# SIG # Begin signature block
# MIIcSgYJKoZIhvcNAQcCoIIcOzCCHDcCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCB2fqlIKJczlBv9
# yo+0tYMz5Ei6Z7zlXoQmNwHyoJsKqaCCFnowggM8MIICJKADAgECAhBJfyGrXBJT
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
# MQ4wDAYKKwYBBAGCNwIBFTAvBgkqhkiG9w0BCQQxIgQg9PcZGmKblCx+UiZ27VW8
# /MI15pDnA6Vxi6oQJsf3N80wDQYJKoZIhvcNAQEBBQAEggEAO2B9GWuMKtwd/VNz
# 6WuQ4TAoa5v0JZM59o158TRwziMUNc5lxXrk/LpdvSV7cGIy1jBI8jN6btF/ysAM
# u1EKiGbTV+gt/DdvnIVHeLlpv/u7pXahcccvLM+tQNAJUku79Zl1gw/xDH1podf7
# P11S36OXyhep0OYGKO3IqnB/Oy7yfhiJGTNW/1H1fM3eanwXb4JnYbGnFy2I8jbI
# 6oU+yWwa7mh7/fW4cvrr5ZTi9HHy2DlSk096ZaboMpWwiVjD5vuKsJi7Og7QQf/v
# SRe/ubEcId6If6oCQBFhwpbRCUQzGcQlSlVjRJ1NJCthR08Qq45kpMOSizdvv33f
# NwgAmKGCAyYwggMiBgkqhkiG9w0BCQYxggMTMIIDDwIBATB9MGkxCzAJBgNVBAYT
# AlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5jLjFBMD8GA1UEAxM4RGlnaUNlcnQg
# VHJ1c3RlZCBHNCBUaW1lU3RhbXBpbmcgUlNBNDA5NiBTSEEyNTYgMjAyNSBDQTEC
# EAqA7xhLjfEFgtHEdqeVdGgwDQYJYIZIAWUDBAIBBQCgaTAYBgkqhkiG9w0BCQMx
# CwYJKoZIhvcNAQcBMBwGCSqGSIb3DQEJBTEPFw0yNjAxMjAxODAyNTlaMC8GCSqG
# SIb3DQEJBDEiBCCVuMqWUJ0uMsxZeUpVwCBZ1ebEvpuv6sTr2F2QPkQdKjANBgkq
# hkiG9w0BAQEFAASCAgAD2TwOwamnmOV9bgvGze9oVBaii3XmML1wLZ85Gd0d48Bh
# hleM6BTS0zhdojonT1i28382xKh7LUNWg9npHaULVbKpA4lfS2Qc3Q7xiCn3QZbu
# +/fMYAb/w7NFw6XlsZPxuRxEySXN9ZZ2r0MckUmlC5vA1g1H2Qtf01zfrwJGl+WZ
# tqCgy4nSU571Opt727ti05bSeDh64a9/5Q9OxOwUjCLsr1xc9NdKfEeNn5ZLs2mW
# sY8S9rV1+yxOSDcGlmgc5QK/NpJBI7B/J7nR1l4XgqAHnrkqCpl9iAhUXu1r+4TE
# 8bbyAHNVoNNVgpduP4lFFb2VXKb4u6FKpWl8AK/WgIhTcli09edvG4UwVdUYxX0C
# iRZ5azEKNE5CWZc/070j3cUVfTVjHmyf3IrTUquVgGMfX76oU6Y8yJxaFw3D2Hql
# gAh08dQqrlfnSk6Eq8ZsYqi63T8KZOZFE6fIVrjPOzUyIhGt1CsEWp/cMmCG0FK2
# QCRsxJfrJLJeFGhYK5qcbNn7LLcSOGR5xrz9bhtDiVdsZUrBXLUFuPgR3B8Pqr9f
# EdtrEBxd5tqIoIu5UwTcWP8G1/o0TYRTxiDchp+4RA9yH5o5oMAJRLGbCVZVTSOa
# ZOCuQQQjdUHcf1dvSLtF22ysNALlk8p+lTzhyvhm2rOW3j4mUUryHkNRh1Uqgw==
# SIG # End signature block

# FallbackSensors.psm1
# Alternative Sensor-Auslese ohne Ring-0-Treiber
# Autor: Bockis
# Version: 1.0

# Importiere Core-Module
Import-Module "$PSScriptRoot\..\Core\LogManager.psm1" -Force -ErrorAction SilentlyContinue

<#
.SYNOPSIS
Liest CPU-Last via Windows Performance Counters (kein Ring-0 nötig)

.DESCRIPTION
Nutzt die Windows Performance Counter API für CPU-Load.
Funktioniert IMMER, auch ohne Admin-Rechte oder Ring-0-Treiber.
Unterstützt deutsche und englische Counter-Namen.
#>
function Get-CpuLoadFallback {
    try {
        # Versuche erst deutsche Counter-Namen
        $cpuCounter = Get-Counter '\Prozessor(_Total)\Prozessorzeit (%)' -ErrorAction SilentlyContinue
        
        if (-not $cpuCounter) {
            # Falls deutsch nicht funktioniert, versuche englisch
            $cpuCounter = Get-Counter '\Processor(_Total)\% Processor Time' -ErrorAction Stop
        }
        
        return [math]::Round($cpuCounter.CounterSamples[0].CookedValue, 1)
    }
    catch {
        Write-Verbose "CPU-Load via Performance Counter fehlgeschlagen: $_"
        return $null
    }
}

<#
.SYNOPSIS
Liest System-Temperaturen via WMI (ACPI Thermal Zones)

.DESCRIPTION
Versucht MSAcpi_ThermalZoneTemperature auszulesen.
HINWEIS: Zeigt oft nur Mainboard-Sensoren, NICHT CPU-Kern-Temperaturen!
Werte sind in Zehntel-Kelvin (z.B. 3020 = 302.0K = 28.85°C)

.RETURNS
Hashtable mit Thermal Zone Namen und Temperaturen in °C
#>
function Get-ThermalZonesFallback {
    try {
        $thermalZones = Get-WmiObject -Namespace "root\wmi" -Class MSAcpi_ThermalZoneTemperature -ErrorAction Stop
        
        $result = @{}
        $index = 1
        
        foreach ($zone in $thermalZones) {
            if ($zone.CurrentTemperature -gt 0) {
                # Konvertierung: Zehntel-Kelvin -> Celsius
                $tempKelvin = $zone.CurrentTemperature / 10
                $tempCelsius = $tempKelvin - 273.15
                
                $zoneName = if ($zone.InstanceName) { 
                    $zone.InstanceName 
                } else { 
                    "Thermal Zone $index" 
                }
                
                $result[$zoneName] = [math]::Round($tempCelsius, 1)
                $index++
            }
        }
        
        if ($result.Count -eq 0) {
            Write-Verbose "Keine WMI Thermal Zones gefunden (normal bei vielen Systemen)"
            return $null
        }
        
        return $result
    }
    catch {
        Write-Verbose "WMI Thermal Zones nicht verfügbar: $_"
        return $null
    }
}

<#
.SYNOPSIS
Liest Speicher-Auslastung via WMI/CIM

.DESCRIPTION
Nutzt CIM_OperatingSystem für RAM-Statistiken.
Funktioniert ohne Ring-0-Treiber.
#>
function Get-MemoryUsageFallback {
    try {
        $os = Get-CimInstance -ClassName CIM_OperatingSystem -ErrorAction Stop
        
        $totalGB = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
        $freeGB = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
        $usedGB = $totalGB - $freeGB
        $usedPercent = [math]::Round(($usedGB / $totalGB) * 100, 1)
        
        return @{
            TotalGB = $totalGB
            UsedGB = $usedGB
            FreeGB = $freeGB
            UsedPercent = $usedPercent
        }
    }
    catch {
        Write-Warning "Memory-Auslese via CIM fehlgeschlagen: $_"
        return $null
    }
}

<#
.SYNOPSIS
Liest Disk I/O via Performance Counters

.DESCRIPTION
Nutzt PhysicalDisk Performance Counters für Read/Write-Statistiken.
Funktioniert ohne Ring-0-Treiber.
Unterstützt deutsche und englische Counter-Namen.
#>
function Get-DiskActivityFallback {
    try {
        # Versuche erst deutsche Counter-Namen
        $diskReads = Get-Counter '\Physikalischer Datenträger(_Total)\Lesevorgänge/Sek.' -ErrorAction SilentlyContinue
        $diskWrites = Get-Counter '\Physikalischer Datenträger(_Total)\Schreibvorgänge/Sek.' -ErrorAction SilentlyContinue
        
        if (-not $diskReads -or -not $diskWrites) {
            # Falls deutsch nicht funktioniert, versuche englisch
            $diskReads = Get-Counter '\PhysicalDisk(_Total)\Disk Reads/sec' -ErrorAction Stop
            $diskWrites = Get-Counter '\PhysicalDisk(_Total)\Disk Writes/sec' -ErrorAction Stop
        }
        
        return @{
            ReadsPerSec = [math]::Round($diskReads.CounterSamples[0].CookedValue, 2)
            WritesPerSec = [math]::Round($diskWrites.CounterSamples[0].CookedValue, 2)
        }
    }
    catch {
        Write-Verbose "Disk Activity via Performance Counter fehlgeschlagen: $_"
        return $null
    }
}

<#
.SYNOPSIS
Prüft ob HWiNFO läuft und Shared Memory verfügbar ist

.DESCRIPTION
HWiNFO64 bietet ein Shared Memory Interface für Sensor-Daten.
Wenn der User HWiNFO laufen hat, können wir dessen Sensoren lesen.
Mehr Info: https://www.hwinfo.com/forum/threads/shared-memory.4092/

.RETURNS
$true wenn HWiNFO Shared Memory verfügbar, sonst $false
#>
function Test-HWiNFOAvailable {
    try {
        # Prüfe ob HWiNFO-Prozess läuft
        $hwinfo = Get-Process -Name "HWiNFO64","HWiNFO32","HWiNFO" -ErrorAction SilentlyContinue
        
        if ($hwinfo) {
            Write-Host "[INFO] HWiNFO läuft - Shared Memory könnte verfügbar sein" -ForegroundColor Cyan
            return $true
        }
        
        return $false
    }
    catch {
        return $false
    }
}

<#
.SYNOPSIS
Gibt einen Überblick über verfügbare Fallback-Sensoren

.DESCRIPTION
Testet alle Fallback-Methoden und gibt eine Zusammenfassung zurück.
#>
function Get-FallbackSensorsInfo {
    $info = @{
        CpuLoad = $false
        ThermalZones = $false
        MemoryUsage = $false
        DiskActivity = $false
        HWiNFO = $false
    }
    
    # Test CPU-Load
    $cpuLoad = Get-CpuLoadFallback
    $info.CpuLoad = ($null -ne $cpuLoad)
    
    # Test Thermal Zones
    $thermalZones = Get-ThermalZonesFallback
    $info.ThermalZones = ($null -ne $thermalZones -and $thermalZones.Count -gt 0)
    
    # Test Memory
    $memory = Get-MemoryUsageFallback
    $info.MemoryUsage = ($null -ne $memory)
    
    # Test Disk
    $disk = Get-DiskActivityFallback
    $info.DiskActivity = ($null -ne $disk)
    
    # Test HWiNFO
    $info.HWiNFO = Test-HWiNFOAvailable
    
    return $info
}

<#
.SYNOPSIS
Erstellt ein Monitor-Update mit Fallback-Sensoren

.DESCRIPTION
Sammelt alle verfügbaren Fallback-Sensoren und gibt sie formatiert zurück.
Wird als Alternative zu LibreHardwareMonitor verwendet wenn Ring-0 nicht verfügbar.
#>
function Get-FallbackMonitorUpdate {
    $update = @{
        Timestamp = Get-Date -Format "HH:mm:ss"
        CpuLoad = Get-CpuLoadFallback
        Memory = Get-MemoryUsageFallback
        DiskActivity = Get-DiskActivityFallback
        ThermalZones = Get-ThermalZonesFallback
    }
    
    return $update
}

# Exportiere Funktionen
Export-ModuleMember -Function @(
    'Get-CpuLoadFallback',
    'Get-ThermalZonesFallback',
    'Get-MemoryUsageFallback',
    'Get-DiskActivityFallback',
    'Test-HWiNFOAvailable',
    'Get-FallbackSensorsInfo',
    'Get-FallbackMonitorUpdate'
)

# SIG # Begin signature block
# MIIcSgYJKoZIhvcNAQcCoIIcOzCCHDcCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBOrd3J8cJ5vEan
# F5UDfngRqfKoeLFPoe0BJXRLtAkcKKCCFnowggM8MIICJKADAgECAhBJfyGrXBJT
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
# MQ4wDAYKKwYBBAGCNwIBFTAvBgkqhkiG9w0BCQQxIgQgjxdvuAV5jlFK56w6j0oN
# RUIydScdqjr1CTBKKiihemcwDQYJKoZIhvcNAQEBBQAEggEAgJgwNCWqXt5Yec3I
# il6yllHHyZkzhyGwd2yGjEkpJXmdcpNDS+I8hMVFNzsaRs00StmAIbj0jOS8352x
# TE4fGX/I537P4HltDD+AXdsWVXifZ2LUCFaVR3xjRAgEqLoApk2yMB+/QBUsKXYM
# Xqk2Lgo+UTGO8DaGZV2cBXoZj9I3Gl3qUDUnLZoLJbWmPPreV01GyK7wvp0hSrxG
# W3K4h6MUdCfXcBooYbv9YJQLjIb3XNoHRFWp+egobQvcyhDxf6wAo5/7a0snp833
# udSsMkSq3e4j3lADOsImjPAv4GzKldFPrSLgWKfZyofBqgMDph75WB+UvVbA1lTB
# EvyqxaGCAyYwggMiBgkqhkiG9w0BCQYxggMTMIIDDwIBATB9MGkxCzAJBgNVBAYT
# AlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5jLjFBMD8GA1UEAxM4RGlnaUNlcnQg
# VHJ1c3RlZCBHNCBUaW1lU3RhbXBpbmcgUlNBNDA5NiBTSEEyNTYgMjAyNSBDQTEC
# EAqA7xhLjfEFgtHEdqeVdGgwDQYJYIZIAWUDBAIBBQCgaTAYBgkqhkiG9w0BCQMx
# CwYJKoZIhvcNAQcBMBwGCSqGSIb3DQEJBTEPFw0yNjAxMjAxODAyNTRaMC8GCSqG
# SIb3DQEJBDEiBCAQlwhAYWK3E8RWfHCAWa+lS6vbXJwMYuiKDTBdpQmvUTANBgkq
# hkiG9w0BAQEFAASCAgB+nZRsXkYPeAUP3nqID9IDOK5deq/yQ+bROSx0x1QAkVFj
# cc7bPN0bL8LnPfPUwqQQGgtI9QmqQhFghClWI0QvaDbs+ZmPhiRXLpIbEFYKMzep
# MZ8g5tGrWgTGfZWI+1Xkk5zHMTSNdzwe7F8G+XjjogTpH165bwsxyQxalrY3N+Hf
# TbIERrvAcohARYOLH8A12W8M+p78XmySV1tAeFDhE0e2sE9U7FWk8vO1doh6vbZb
# wzL05XBMQCrk7xhO/K37b2uwENs6J0KRBi76u00LFQx1h9ocQtGGUUHTCAMiSl+Z
# LOjF/fD0zCtaDUPsLNsNy0qDyXjnsja1DD0XL7shqO8S7F2AEkAUD6PZi9qxk1m8
# YLA8p/Ta3xAp5j2/XL7SvMKVAInSefMcaOslrdJdDuAvlOXakT9h4RBTkB9+9scH
# s/9/YUCI1pqchodR2nlc7752KJPjtRa8Cvhq3wlNRRv8X8YC5wxXZCF17epjY0pN
# xQkAR9r3mrZuXDz3sNxY7BWDSowabQX4SZOfivwPTdvGgm8S5l+uyDbWD5QhHiq+
# kRGnjB9CLAv2Tv1IcgZXnQOPex4CQ/uC+FWVliknCIN46bqGH082FOFAJMws1jzo
# TiOLfSJiDDlZbL/qOSZcOBZYRVWGUP+1rYxKZCZPnZRQ1bnh8CjErRYIEWezXQ==
# SIG # End signature block

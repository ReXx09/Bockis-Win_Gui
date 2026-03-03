# ToolCache.psm1 - Cache-System für Tool-Informationen und Installationsstatus
# Autor: Bocki (mit Unterstützung von GitHub Copilot)

# Importiere notwendige Abhängigkeiten
Add-Type -AssemblyName System.Runtime.Caching

# Globaler Cache für Tool-Informationen
$script:toolCache = [System.Runtime.Caching.MemoryCache]::Default

# Cache für installierte Pakete (speichert die komplette Winget-Liste einmal)
$script:installedPackagesCache = $null
$script:installedPackagesCacheTime = $null

# Locking-Variable für Cache-Initialisierung (verhindert Race Conditions)
$script:cacheInitializationLock = $false

# Liste der bekannten Schlüssel initialisieren
$script:knownKeys = @()

# Cache-Ablaufzeit (in Minuten)
$script:defaultCacheExpiration = 15  # 15 Minuten Standard-Ablaufzeit für Tool-Informationen
$script:installStatusCacheExpiration = 5  # 5 Minuten für den Installationsstatus
$script:installedPackagesCacheExpiration = 5  # 5 Minuten für die gesamte Paketliste

# Funktion zum Speichern von Objekten im Cache
function Add-ToolToCache {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Key,
        
        [Parameter(Mandatory=$true)]
        [object]$Value,
        
        [Parameter(Mandatory=$false)]
        [int]$ExpirationMinutes = $script:defaultCacheExpiration
    )
    
    try {
        # Cache-Eintrag mit Ablaufzeit erstellen
        $policy = New-Object System.Runtime.Caching.CacheItemPolicy
        $policy.AbsoluteExpiration = [DateTimeOffset]::Now.AddMinutes($ExpirationMinutes)
        
        # Eintrag zum Cache hinzufügen/aktualisieren
        $script:toolCache.Set($Key, $Value, $policy)
        
        # Schlüssel zur Liste der bekannten Schlüssel hinzufügen
        if ($Key -ne "CachedKeys" -and $Key -notlike "ToolsByCategory_*") {
            $cachedKeys = @(Get-ToolFromCache -Key "CachedKeys")
            if ($null -eq $cachedKeys) {
                $cachedKeys = @()
            }
            if ($cachedKeys -notcontains $Key) {
                $cachedKeys += $Key
                $script:toolCache.Set("CachedKeys", $cachedKeys, $policy)
            }
        }
        
        Write-Verbose "Element '$Key' zum Cache hinzugefügt (Ablauf: $ExpirationMinutes min)"
        return $true
    }
    catch {
        Write-Warning "Fehler beim Hinzufügen zum Cache: $_"
        return $false
    }
}

# Funktion zum Abrufen von Objekten aus dem Cache
function Get-ToolFromCache {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Key
    )
    
    try {
        # Prüfen, ob der Schlüssel im Cache existiert
        if ($script:toolCache.Contains($Key)) {
            $cachedItem = $script:toolCache.Get($Key)
            Write-Verbose "Element '$Key' aus dem Cache abgerufen"
            return $cachedItem
        }
        
        Write-Verbose "Element '$Key' nicht im Cache gefunden"
        return $null
    }
    catch {
        Write-Warning "Fehler beim Abrufen aus dem Cache: $_"
        return $null
    }
}

# Funktion zum Entfernen von Objekten aus dem Cache
function Remove-ToolFromCache {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Key
    )
    
    try {
        # Eintrag aus dem Cache entfernen
        if ($script:toolCache.Contains($Key)) {
            $script:toolCache.Remove($Key)
            
            # Auch aus der Liste der bekannten Schlüssel entfernen, wenn es keine Kategorie ist
            if ($Key -ne "CachedKeys" -and $Key -notlike "ToolsByCategory_*") {
                $cachedKeys = @(Get-ToolFromCache -Key "CachedKeys")
                if ($null -ne $cachedKeys -and $cachedKeys -contains $Key) {
                    $cachedKeys = $cachedKeys | Where-Object { $_ -ne $Key }
                    $policy = New-Object System.Runtime.Caching.CacheItemPolicy
                    $policy.AbsoluteExpiration = [DateTimeOffset]::Now.AddMinutes($script:defaultCacheExpiration)
                    $script:toolCache.Set("CachedKeys", $cachedKeys, $policy)
                }
            }
            
            Write-Verbose "Element '$Key' aus dem Cache entfernt"
            return $true
        }
        
        Write-Verbose "Element '$Key' nicht im Cache gefunden"
        return $false
    }
    catch {
        Write-Warning "Fehler beim Entfernen aus dem Cache: $_"
        return $false
    }
}

# Funktion zum Leeren des gesamten Caches
function Clear-ToolCache {
    try {
        # Sammle alle bekannten Schlüssel, für die wir den Cache leeren wollen
        $keysToRemove = @()
        
        # Sammle alle InstallStatus_* Schlüssel
        $keysToRemove += @(Get-ToolFromCache -Key "CachedKeys") | Where-Object { $_ -ne $null }
        
        # Kategorie-bezogene Schlüssel
        $categories = @('all', 'system', 'browser', 'communication')
        foreach ($category in $categories) {
            $keysToRemove += "ToolsByCategory_$category"
        }
        
        # Entferne jeden Schlüssel
        foreach ($key in $keysToRemove) {
            if ($key) {
                $script:toolCache.Remove($key)
            }
        }
        
        # Installierte Pakete Cache leeren
        $script:installedPackagesCache = $null
        $script:installedPackagesCacheTime = $null
        
        Write-Verbose "Cache vollständig geleert"
        return $true
    }
    catch {
        Write-Warning "Fehler beim Leeren des Caches: $_"
        return $false
    }
}

# Funktion zum Initialisieren des Caches für installierte Pakete (ruft nur einmal winget list auf)
function Initialize-InstalledPackagesCache {
    # Wenn Cache aktuell ist, nichts tun
    if ($null -ne $script:installedPackagesCache -and $null -ne $script:installedPackagesCacheTime) {
        $cacheAge = (Get-Date) - $script:installedPackagesCacheTime
        if ($cacheAge.TotalMinutes -lt $script:installedPackagesCacheExpiration) {
            Write-Verbose "Installierte Pakete Cache ist aktuell (Alter: $($cacheAge.TotalMinutes) Minuten)"
            return $true
        }
    }

    # Prüfe Lock - verhindert Race Condition bei mehrfachen gleichzeitigen Aufrufen
    if ($script:cacheInitializationLock) {
        Write-Verbose "Cache-Initialisierung läuft bereits, warte auf Abschluss..."
        $waitCount = 0
        while ($script:cacheInitializationLock -and $waitCount -lt 30) {
            Start-Sleep -Milliseconds 500
            $waitCount++
        }
        # Nach Warten erneut prüfen ob Cache nun verfügbar ist
        if ($null -ne $script:installedPackagesCache) {
            Write-Verbose "Cache wurde von parallelem Thread initialisiert"
            return $true
        }
    }

    # Lock setzen
    $script:cacheInitializationLock = $true
    $job = $null
    
    try {
        Write-Verbose "Lade komplette Liste aller installierten Pakete..."
        
        # Verwende einen Job mit Timeout, um Deadlocks zu vermeiden
        $job = Start-Job -ScriptBlock {
            winget list 2>$null | Out-String
        }
        
        # Warte maximal 15 Sekunden auf das Ergebnis
        $completed = Wait-Job -Job $job -Timeout 15
        
        if ($completed) {
            $script:installedPackagesCache = Receive-Job -Job $job
            $script:installedPackagesCacheTime = Get-Date
            $cacheLines = ($script:installedPackagesCache -split "`n").Count
            Write-Verbose "Installierte Pakete Cache wurde aktualisiert ($cacheLines Zeilen)"
            Write-Host "[CACHE-INIT] Cache erfolgreich geladen: $cacheLines Zeilen" -ForegroundColor Green
            return $true
        }
        else {
            # Job hat Timeout erreicht
            Stop-Job -Job $job -ErrorAction SilentlyContinue
            Write-Warning "Timeout beim Laden der installierten Pakete (>15s)"
            return $false
        }
    }
    catch {
        Write-Warning "Fehler beim Laden der installierten Pakete: $_"
        return $false
    }
    finally {
        # Lock freigeben und Job aufräumen (garantiert!)
        $script:cacheInitializationLock = $false
        if ($null -ne $job) {
            Remove-Job -Job $job -Force -ErrorAction SilentlyContinue
        }
    }
}

# Funktion zum Cachen des Installationsstatus eines Tools
function Get-CachedToolInstallationStatus {
    param (
        [Parameter(Mandatory=$true)]
        [object]$Tool
    )
    
    # Wenn das Tool keine Winget-ID hat, können wir den Status nicht prüfen
    if (-not $Tool.Winget) {
        return $false
    }
    
    # Cache-Schlüssel für das Tool generieren
    $cacheKey = "InstallStatus_$($Tool.Winget)"
    
    # Prüfen, ob der Status bereits im Cache ist
    $cachedStatus = Get-ToolFromCache -Key $cacheKey
    if ($null -ne $cachedStatus) {
        Write-Verbose "Installationsstatus für $($Tool.Name) aus Cache abgerufen: $cachedStatus"
        return $cachedStatus
    }
    
    # Sicherstellen, dass der Paketcache initialisiert ist
    $cacheInitialized = Initialize-InstalledPackagesCache
    
    # Status nicht im Cache, aus dem Paketcache ermitteln
    # Nur wenn Cache erfolgreich initialisiert wurde UND Daten enthält
    if ($cacheInitialized -and $null -ne $script:installedPackagesCache -and $script:installedPackagesCache.Length -gt 0) {
        # Prüfe explizit, ob das Tool in der Cache-Liste enthalten ist
        # WICHTIG: -match gibt nur zurück ob Pattern gefunden wurde, nicht ob Match existiert
        # Wir müssen die Ausgabe analysieren und prüfen ob die ID tatsächlich in der Liste ist
        $packageLines = $script:installedPackagesCache -split "`n"
        $isInstalled = $false
        
        foreach ($line in $packageLines) {
            # Prüfe ob die Zeile die Winget-ID enthält (nicht nur teilweise)
            # Winget-Ausgabe hat Format: Name   Id   Version
            # Die ID steht in der zweiten Spalte
            if ($line -match "\s+$([regex]::Escape($Tool.Winget))\s+") {
                $isInstalled = $true
                Write-Verbose "Tool $($Tool.Name) gefunden per Winget-ID in Zeile: $line"
                break
            }
            
            # Alternativ: Prüfe auch ob der Tool-Name am Zeilenanfang steht (für manuell installierte Programme)
            # Dies findet Programme die nicht über Winget installiert wurden (z.B. MIXLINE mit ARP\User\X64\MIXLINE...)
            $escapedName = [regex]::Escape($Tool.Name)
            if ($line -match "^$escapedName\s+") {
                $isInstalled = $true
                Write-Verbose "Tool $($Tool.Name) gefunden per Namen in Zeile: $line"
                break
            }
        }
        
        $null = Add-ToolToCache -Key $cacheKey -Value $isInstalled -ExpirationMinutes $script:installStatusCacheExpiration
        
        Write-Verbose "Installationsstatus für $($Tool.Name) aus Paket-Cache ermittelt: $isInstalled"
        return $isInstalled
    }
    
    # Fallback auf direkte Prüfung, wenn Paketcache nicht verfügbar
    $job = $null
    try {
        Write-Verbose "Fallback: Prüfe direkt mit winget für Tool $($Tool.Name)"
        
        # Verwende Job mit Timeout um Hänger zu vermeiden
        $job = Start-Job -ScriptBlock {
            param($wingetId)
            winget list --id $wingetId --exact 2>$null | Out-String
        } -ArgumentList $Tool.Winget
        
        $completed = Wait-Job -Job $job -Timeout 10
        
        if ($completed) {
            $installedPackage = Receive-Job -Job $job
            
            # Status bestimmen und im Cache speichern
            $packageFound = ($installedPackage.Length -gt 0) -and 
                            ($installedPackage -match [regex]::Escape($Tool.Winget)) -and
                            ($installedPackage -notmatch [regex]::Escape("Keine Pakete gefunden")) -and
                            ($installedPackage -notmatch [regex]::Escape("No package found"))
            
            if ($packageFound) {
                Write-Verbose "Tool $($Tool.Name) wurde direkt gefunden -> INSTALLIERT"
                $null = Add-ToolToCache -Key $cacheKey -Value $true -ExpirationMinutes $script:installStatusCacheExpiration
                return $true
            } else {
                Write-Verbose "Tool $($Tool.Name) wurde direkt NICHT gefunden -> NICHT INSTALLIERT"
                $null = Add-ToolToCache -Key $cacheKey -Value $false -ExpirationMinutes $script:installStatusCacheExpiration
                return $false
            }
        }
        else {
            # Timeout - Job stoppen und als nicht installiert behandeln
            Stop-Job -Job $job -ErrorAction SilentlyContinue
            Write-Warning "Timeout beim Prüfen von $($Tool.Name) (>10s) - angenommen als nicht installiert"
            $null = Add-ToolToCache -Key $cacheKey -Value $false -ExpirationMinutes 1  # Kurzer Cache bei Timeout
            return $false
        }
    }
    catch {
        Write-Verbose "Fehler beim Prüfen des installierten Status für $($Tool.Name): $_"
        return $false
    }
    finally {
        # Garantierter Job-Cleanup
        if ($null -ne $job) {
            Remove-Job -Job $job -Force -ErrorAction SilentlyContinue
        }
    }
}

# Funktion zum Aktualisieren des Cache nach einer Installation oder Deinstallation
function Update-ToolInstallationStatus {
    param (
        [Parameter(Mandatory=$true)]
        [object]$Tool,
        
        [Parameter(Mandatory=$true)]
        [bool]$IsInstalled
    )
    
    # Wenn das Tool keine Winget-ID hat, können wir den Status nicht cachen
    if (-not $Tool.Winget) {
        return $false
    }
    
    # Cache-Schlüssel für das Tool generieren
    $cacheKey = "InstallStatus_$($Tool.Winget)"
    
    # Status im Cache aktualisieren
    $result = Add-ToolToCache -Key $cacheKey -Value $IsInstalled -ExpirationMinutes $script:installStatusCacheExpiration
    Write-Verbose "Installationsstatus für $($Tool.Name) aktualisiert: $IsInstalled"
    
    # Paketcache als veraltet markieren
    $script:installedPackagesCache = $null
    $script:installedPackagesCacheTime = $null
    
    return $result
}

# Funktion zum Cachen der gefilterten Tools nach Kategorie
function Get-CachedToolsByCategory {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Category
    )
    
    # Cache-Schlüssel für die Kategorie generieren
    $cacheKey = "ToolsByCategory_$Category"
    
    # Prüfen, ob die gefilterten Tools bereits im Cache sind
    $cachedTools = Get-ToolFromCache -Key $cacheKey
    if ($null -ne $cachedTools) {
        Write-Verbose "Tools für Kategorie '$Category' aus Cache abgerufen"
        return $cachedTools
    }
    
    return $null
}

# Funktion zum Speichern der gefilterten Tools im Cache
function Set-CachedToolsByCategory {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Category,
        
        [Parameter(Mandatory=$true)]
        [array]$Tools
    )
    
    # Cache-Schlüssel für die Kategorie generieren
    $cacheKey = "ToolsByCategory_$Category"
    
    # Tools im Cache speichern
    $result = Add-ToolToCache -Key $cacheKey -Value $Tools
    Write-Verbose "Tools für Kategorie '$Category' im Cache gespeichert"
    
    return $result
}

# Funktion zum Initialisieren der Cache-Schlüssel-Liste, wenn sie nicht existiert
function Initialize-ToolCacheKeys {
    try {
        # Cache-Policy mit langer Ablaufzeit für die Schlüsselliste erstellen
        $policy = New-Object System.Runtime.Caching.CacheItemPolicy
        $policy.AbsoluteExpiration = [DateTimeOffset]::Now.AddMinutes(60) # 1 Stunde Ablaufzeit
        
        # Initialisieren, wenn nicht vorhanden
        if (-not $script:toolCache.Contains("CachedKeys")) {
            $script:toolCache.Set("CachedKeys", @(), $policy)
        }
        
        return $true
    }
    catch {
        Write-Warning "Fehler beim Initialisieren der Cache-Schlüssel: $_"
        return $false
    }
}

# Funktion zum Bereinigen des Caches beim Beenden der Anwendung
function Clear-ToolCacheOnExit {
    try {
        Write-Host "Bereinige Tool-Cache beim Beenden..."
        $result = Clear-ToolCache
        Write-Verbose "Tool-Cache wurde beim Beenden bereinigt"
        return $result
    }
    catch {
        Write-Warning "Fehler beim Bereinigen des Tool-Caches: $_"
        return $false
    }
}

# Initialisiere die Cache-Schlüssel beim Modulstart
Initialize-ToolCacheKeys | Out-Null

# Modulexporte
Export-ModuleMember -Function Add-ToolToCache, Get-ToolFromCache, Remove-ToolFromCache, Clear-ToolCache, 
                     Get-CachedToolInstallationStatus, Update-ToolInstallationStatus,
                     Get-CachedToolsByCategory, Set-CachedToolsByCategory, Clear-ToolCacheOnExit,
                     Initialize-InstalledPackagesCache, Initialize-ToolCacheKeys

# SIG # Begin signature block
# MIIcSgYJKoZIhvcNAQcCoIIcOzCCHDcCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBwbv+khAzhAfoa
# 1LE+Niv1batnMF5bEa+qk39WJ62dNaCCFnowggM8MIICJKADAgECAhBJfyGrXBJT
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
# MQ4wDAYKKwYBBAGCNwIBFTAvBgkqhkiG9w0BCQQxIgQgdrhcwqmoHf5s2cyx/xEN
# 0XKP62O92porIZdtLZzzo+4wDQYJKoZIhvcNAQEBBQAEggEABP6L/JCYD5MVjg/Q
# IMMkXUmutIJZxfd7cQHCBeEnxuCcFddnQUdEsA9AcZwF7prrEMuJayL6HYqdahDP
# tcURox89+CRTOx0YTFl916FHtHPw0/J+r86yk7y1EwQ9eWQTwjU4uXKNivMYewSd
# JKSJ7rjeXVjaibl/qcwGUiWMUgP5fzseRU9dw0+5OlNf7EwXaDy1XeXV4OZqd2Pj
# 9j26Q09xws+r3S+ZVWw5gOBr+zbWH1eGC9uN3I7gMDMKgOKSJiFHfOP2JMY9mnWn
# tqiasNHzdjfy+dTxl3q+vPKxxRBMSE9e80S40D+R+mTkOEzZneO1c0dhCbkUu44i
# nyvkmaGCAyYwggMiBgkqhkiG9w0BCQYxggMTMIIDDwIBATB9MGkxCzAJBgNVBAYT
# AlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5jLjFBMD8GA1UEAxM4RGlnaUNlcnQg
# VHJ1c3RlZCBHNCBUaW1lU3RhbXBpbmcgUlNBNDA5NiBTSEEyNTYgMjAyNSBDQTEC
# EAqA7xhLjfEFgtHEdqeVdGgwDQYJYIZIAWUDBAIBBQCgaTAYBgkqhkiG9w0BCQMx
# CwYJKoZIhvcNAQcBMBwGCSqGSIb3DQEJBTEPFw0yNjAxMjAxODAyNTZaMC8GCSqG
# SIb3DQEJBDEiBCCjdbK51Nk3tWgfAS45YOQBIHtrHrZJ2HsYHCb8KH1q5DANBgkq
# hkiG9w0BAQEFAASCAgBcuxzmoGjP7vRUyQKL3XsS2cpFjA2dL9+JBZtxJU1qhPvm
# ICIoFCdfRZ60d3Y+9U/tfEHvhpk7uZ22/ODS7AmvGcn6t1Ml/R18s1VFwKfh2+MR
# 004OzhIejIk6CZ8NHkjelCwkdlURsi5ClFe3U25ZtPWJrIRa/7hgjDtWlzavgD47
# 5240L/a7hDAqmxq+uYH/7237OqaJeHWrbQ+bL6DhpVdL8i9gBPvjBGsmZg6hr4tY
# DjXvs+OqphYq/cVQpb+c5tIf4CBKEugR0zLdR1i7Ue+7+mm8OjDEEcO9fi8WCLrh
# HYRGJUVTF384HTyEL66sgLIYplZcmo9RQEozFkTCGZLaHEMUhiH7kJIbl3GcrFvV
# m1m9V0nw8pyxkc9GMyl7qUwgFOLlHmhkBeToh53LH6CscYzxGhEQ5W/L6JJ8kZYa
# grs20Z53VRuAX61Z1fwXayIhB8l66BV+/LaAKkqDzqv2l9CfVY24HQiQiBdskt97
# V32qbrYzxlIK3sVoSJDBJ214f995XaNd0ApZuMeeUDTLUTlZdxKCxKoU0jX8GFt8
# JTNiLjDoX7YbbzYPjtxsRz97LU40/l+coMeRLS2GPZiK35uFjF96ISjGIwZ2iHyP
# vqFDk0Fbu0PKBHBEpbdsZ9sVpBOYbWOtM7eK8GfcOte5tCQ/AhOhmpR0eY+H5g==
# SIG # End signature block

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

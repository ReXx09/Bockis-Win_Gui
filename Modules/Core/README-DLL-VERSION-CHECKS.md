# DLL-Versionsabfragen in Test-SystemDependencies

## 📋 Übersicht

Die Funktion `Test-SystemDependencies` wurde erweitert um automatische Versionsabfragen aller benötigten DLLs. Dies ermöglicht eine vollständige Validierung der Bibliotheken beim Start des System-Tools.

## 🔍 Geprüfte DLLs

### Kritische DLLs (Required = true)

#### 1. **LibreHardwareMonitorLib.dll**
- **Mindestversion:** 0.9.5 (PawnIO-Unterstützung)
- **Prüfung:** Version >= 0.9.5
- **Status:**
  - ✅ v0.9.5+: PawnIO-kompatibel (sicher)
  - ⚠️ < 0.9.5: Nutzt unsicheren WinRing0-Treiber (Defender-Alarm!)
- **Update:** `Tools\Update-LibreHardwareMonitor.ps1`

#### 2. **BlackSharp.Core.dll**
- **Funktion:** BlackSharp Basis-Bibliothek
- **Prüfung:** Vorhandensein + Version
- **Required:** Ja

### Optionale DLLs (Required = false)

#### 3. **HidSharp.dll**
- **Funktion:** HID-Geräte-Bibliothek (nur für spezielle Hardware)
- **Prüfung:** Vorhandensein + Version
- **Required:** Nein (nur für spezielle HID-Geräte benötigt)
- **Info:** LibreHardwareMonitor funktioniert ohne HidSharp

#### 4. **RAMSPDToolkit-NDD.dll**
- **Funktion:** RAM-SPD-Informationen
- **Prüfung:** Vorhandensein + Version
- **Required:** Nein (Fallback vorhanden)

#### 5. **DiskInfoToolkit.dll**
- **Funktion:** Festplatten-Informationen
- **Prüfung:** Vorhandensein + Version
- **Required:** Nein (Fallback vorhanden)

## 🔧 Implementierung

### Code-Location
- **Datei:** `Modules\Core\DependencyChecker.psm1`
- **Funktion:** `Test-SystemDependencies`
- **Zeilen:** ~1567-1770

### Prüfungslogik

```powershell
# Lib-Pfad ermitteln (relativ zum Modul)
$libPath = Join-Path $PSScriptRoot "..\..\Lib"

# DLL-Version auslesen
$dllPath = Join-Path $libPath "LibreHardwareMonitorLib.dll"
$version = (Get-Item $dllPath).VersionInfo.ProductVersion
$versionClean = $version.Split('+')[0]  # "0.9.5+abc123" → "0.9.5"

# Versionsvergleich
if ($version -match '^(\d+\.\d+\.\d+)') {
    $v = [version]$Matches[1]
    if ($v -ge [version]"0.9.5") {
        # Version OK
    }
}
```

### Rückgabe-Struktur

Jede DLL wird zur `$dependencies`-Liste hinzugefügt:

```powershell
@{
    Name        = "LibreHardwareMonitorLib.dll"
    Description = "Hardware-Sensor-Bibliothek v0.9.5 (PawnIO-kompatibel ✓)"
    Required    = $true
    Available   = $true
    Found       = $true
    Version     = "0.9.5"
    Path        = "C:\...\Lib\LibreHardwareMonitorLib.dll"
}
```

## 🚀 Verwendung

### In der GUI

Die DLL-Checks werden automatisch beim Start ausgeführt:

```powershell
Import-Module .\Modules\Core\DependencyChecker.psm1

# Abhängigkeitsprüfung mit Dialog
$result = Test-SystemDependencies -ShowDialog $true

if (-not $result.AllSatisfied) {
    # Benutzer wird über fehlende/veraltete DLLs informiert
}
```

### Im Terminal (Testing)

```powershell
# Abhängigkeitsprüfung ohne Dialog
cd Bockis-Win_Gui_DEV\Tools
.\Test-DllVersionChecks.ps1
```

### Ausgabe-Beispiel

```
🔧 Prüfe benötigte Bibliotheken (DLLs)...
  ✓ LibreHardwareMonitorLib.dll v0.9.5 (PawnIO-Version)
  ✓ BlackSharp.Core.dll v1.0.7+c70b735c6cec123ee8a046ac4a0bc6c606f52cf0
  ⚠️  HidSharp.dll nicht gefunden
  ✓ RAMSPDToolkit-NDD.dll v1.4.2+3b47b960e0830fef344624ad5e389675d5f0a1ce
  ✓ DiskInfoToolkit.dll v1.1.1+1abae1b8de1a7ec866ffc247bad266cdcda61b5f
```

## ⚠️ Fehlerszenarien

### Szenario 1: Veraltete LibreHardwareMonitorLib.dll

**Symptom:**
```
⚠️  LibreHardwareMonitorLib.dll v0.9.4 ist VERALTET!
    → Benötigt: v0.9.5+ (PawnIO statt WinRing0)
    → Update über Tools\Update-LibreHardwareMonitor.ps1
```

**Lösung:**
```powershell
cd Tools
.\Update-LibreHardwareMonitor.ps1
# Oder: .\Update-DLL-auf-0.9.5.bat
```

### Szenario 2: Fehlende DLL

**Symptom:**
```
❌ LibreHardwareMonitorLib.dll nicht gefunden!
```

**Lösung:**
- DLL aus NuGet-Paket extrahieren
- In `Lib\` Ordner kopieren
- GUI neu starten

### Szenario 3: Version nicht lesbar

**Symptom:**
```
⚠️  LibreHardwareMonitorLib.dll: Version konnte nicht gelesen werden
```

**Mögliche Ursachen:**
- DLL beschädigt
- DLL von anderem Prozess gesperrt
- Falsche DLL-Quelle (nicht von LibreHardwareMonitor)

**Lösung:**
```powershell
# Manuelle Prüfung
$dll = Get-Item "Lib\LibreHardwareMonitorLib.dll"
$dll.VersionInfo.ProductVersion

# Falls leer/fehlerhaft: DLL neu herunterladen
```

## 🔄 Automatisches Update

Die Funktion `Update-LibreHardwareMonitorDll` ist bereits im DependencyChecker integriert und wird bei Bedarf automatisch angeboten:

1. **Erkennung:** Version < 0.9.5
2. **Dialog:** Benutzer wird über WinRing0-Problem informiert
3. **Angebot:** Automatisches Update von NuGet
4. **Download:** v0.9.5 wird heruntergeladen
5. **Backup:** Alte DLL wird als `.dll.old` gesichert
6. **Update:** Neue DLL wird installiert
7. **Neustart:** GUI muss neu gestartet werden

## 📊 Dependency-Dialog

Die erweiterten DLL-Informationen werden im Dependency-Dialog angezeigt:

```
┌─────────────────────────────────────────────────────┐
│ Systemabhängigkeiten prüfen                        │
├─────────────────────────────────────────────────────┤
│ ☐ .NET Framework 4.8 (installiert)                │
│ ☐ Winget Package Manager (installiert)            │
│ ☑ PawnIO Ring-0 Treiber (nicht installiert)       │
│ ☑ LibreHardwareMonitorLib.dll v0.9.4 (VERALTET!) │
│ ☐ BlackSharp.Core.dll v1.0.7                      │
│ ☐ HidSharp.dll (nicht gefunden)                   │
├─────────────────────────────────────────────────────┤
│          [Automatisch installieren]  [Abbrechen]   │
└─────────────────────────────────────────────────────┘
```

## 📝 Changelog

### v4.1.2 (2026-02-09)
- ✅ DLL-Versionsabfragen zu Test-SystemDependencies hinzugefügt
- ✅ LibreHardwareMonitorLib.dll >= 0.9.5 Prüfung implementiert
- ✅ BlackSharp.Core.dll, HidSharp.dll Checks hinzugefügt
- ✅ Optionale DLLs: RAMSPDToolkit-NDD.dll, DiskInfoToolkit.dll
- ✅ Detaillierte Versionsausgabe mit PawnIO-Kompatibilitätshinweis
- ✅ Update-Empfehlung bei veralteter Version
- ✅ Test-DllVersionChecks.ps1 Testskript erstellt

## 🔗 Verwandte Dokumentation

- **DLL-Update:** [README-DependencyChecker-AutoUpdate.md](README-DependencyChecker-AutoUpdate.md)
- **WinRing0-Problem:** [DEFENDER-WINRING0-PROBLEM.md](../../DEFENDER-WINRING0-PROBLEM.md)
- **Hardware-Monitor:** [Hardware-Monitor Fix](../../HARDWARE-MONITOR-DLL-FIX.md)
- **Dependency-Checker:** [README-DependencyChecker.md](README-DependencyChecker.md)

## 🛠️ Entwickler-Hinweise

### Neue DLL hinzufügen

```powershell
# 1. In Test-SystemDependencies nach "# 2a.5" eine neue Sektion einfügen
$newDllPath = Join-Path $libPath "NewLibrary.dll"
if (Test-Path $newDllPath) {
    try {
        $version = (Get-Item $newDllPath).VersionInfo.ProductVersion
        $versionClean = if ($version) { $version } else { "Unbekannt" }
        
        $dependencies += @{
            Name = "NewLibrary.dll"
            Description = "Neue Funktionalität"
            Required = $true  # oder $false
            Available = $true
            Found = $true
            Version = $versionClean
            Path = $newDllPath
        }
        Write-Host "  ✓ NewLibrary.dll v$versionClean" -ForegroundColor Green
    }
    catch {
        Write-Host "  ⚠️  NewLibrary.dll: Version konnte nicht gelesen werden" -ForegroundColor Yellow
    }
}
else {
    # DLL fehlt
    $dependencies += @{
        Name = "NewLibrary.dll"
        Description = "Neue Funktionalität (FEHLT!)"
        Required = $true
        Available = $false
        Found = $false
        Version = $null
        Path = $newDllPath
    }
    Write-Host "  ⚠️  NewLibrary.dll nicht gefunden" -ForegroundColor Yellow
}
```

### Version-Checking Best Practices

1. **Regex für Version-String:**
   ```powershell
   if ($version -match '^(\d+\.\d+\.\d+)') {
       $cleanVersion = $Matches[1]
   }
   ```

2. **Versions-Vergleich:**
   ```powershell
   $v = [version]$cleanVersion
   if ($v -ge [version]"1.2.3") { ... }
   ```

3. **Git-Hash entfernen:**
   ```powershell
   $version.Split('+')[0]  # "1.0.0+abc123" → "1.0.0"
   ```

## 🎯 Testing

### Testskript ausführen

```powershell
cd Bockis-Win_Gui_DEV\Tools
.\Test-DllVersionChecks.ps1
```

### Manuelle Tests

```powershell
# DependencyChecker laden
cd Modules\Core
Import-Module .\DependencyChecker.psm1 -Force

# Test-SystemDependencies ausführen
$result = Test-SystemDependencies -ShowDialog $false

# Ergebnis prüfen
$result.AllSatisfied  # $true oder $false
```

### Edge Cases

1. **DLL fehlt komplett:** Should show error, mark as not found
2. **DLL hat keine Version:** Should show "Unbekannt" instead
3. **DLL ist < 0.9.5:** Should warn about WinRing0 usage
4. **DLL ist gesperrt:** Should catch exception gracefully
5. **Lib-Ordner fehlt:** Should show warning, skip all DLL checks

---

**Letzte Aktualisierung:** 2026-02-09  
**Version:** 4.1.2  
**Autor:** Bockis System Tool Team

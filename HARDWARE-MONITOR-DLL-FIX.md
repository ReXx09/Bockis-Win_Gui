# Hardware-Monitor DLL-Fix

## Problem
Bei der Installation der GUI auf einem anderen Rechner erschien die Meldung, dass LibreHardwareMonitor installiert werden soll, obwohl nur die DLLs aus dem Lib-Ordner genutzt werden sollten.

## Ursache
1. **Installer**: Der Installer versuchte LibreHardwareMonitor über WinGet zu installieren statt nur PawnIO
2. **Fehlermeldungen**: Alte Fehlermeldungen schlugen vor, LibreHardwareMonitor zu installieren
3. **PowerShell 7 Kompatibilität**: System.Security.*.dll wurden in PowerShell 7 nicht geladen (aber benötigt!)
4. **Fehlerdiagnose**: Keine klare Meldung, welche DLLs fehlen oder wo nach ihnen gesucht wird

## Bestätigung: Lib-Pfad ist KORREKT!
✅ Der Lib-Pfad wird korrekt ermittelt: `C:\Program Files\Bockis-Win_Gui\Lib`  
✅ Alle DLLs werden aus dem Lib-Ordner geladen  
✅ **Der Pfad war NIE das Problem!**

## Durchgeführte Änderungen

### 1. Installer.iss (Zeile 824-829)
**VORHER:**
```
; LibreHardwareMonitor über WinGet installieren
; WICHTIG: PawnIO-Treiber wird nur bei WinGet-Installation korrekt installiert!
winget install --id LibreHardwareMonitor.LibreHardwareMonitor
```

**NACHHER:**
```
; PawnIO Ring-0 Treiber über WinGet installieren
; WICHTIG: LibreHardwareMonitorLib.dll ist bereits im Lib-Ordner enthalten
; OHNE PawnIO funktioniert Hardware-Monitoring NICHT!
winget install --id namazso.PawnIO
```

### 2. HardwareMonitorTools.psm1
**Änderung:** Entfernung der alten Fehlermeldung "Installiere LibreHardwareMonitor: winget install..."

**Neu:** Detaillierte Fehlermeldung vom DependencyChecker wird angezeigt mit:
- Genauer Fehlerursache (DLLs fehlen / PawnIO fehlt / Keine Sensoren)
- Lib-Ordner-Pfad
- Hilfreiche Lösungsvorschläge

### 3. DependencyChecker.psm1 (Initialize-HardwareMonitoringMode)
**PowerShell 7 Kompatibilität:**
- **VORHER:** System.Security.*.dll wurden NUR in PowerShell 5.1 geladen
- **NACHHER:** System.Security.*.dll werden in BEIDEN PowerShell-Versionen geladen

**Grund:** LibreHardwareMonitorLib benötigt `FileInfo.GetAccessControl()` die in .NET 9 (PowerShell 7) anders implementiert ist. Die DLLs aus dem Lib-Ordner stellen die Kompatibilität her.

**Verbesserte Fehlerdiagnose:**

1. **Lib-Ordner fehlt:**
   - Zeigt den erwarteten Pfad an
   - Klare Meldung, dass Lib-Ordner vorhanden sein muss

2. **DLLs fehlen:**
   - Liste aller fehlenden DLLs mit Beschreibung
   - Lib-Ordner-Pfad wird angezeigt
   - Klare Handlungsanweisung

3. **Keine Sensoren verfügbar:**
   - PawnIO läuft, aber Sensoren werden nicht erkannt
   - Lösungsvorschläge (Admin-Rechte, System neu starten, PawnIO neu installieren)
   - Lib-Ordner-Pfad zur Überprüfung

## Installation auf neuem Rechner

### Voraussetzungen
1. ✅ **Lib-Ordner**: Alle DLLs im Lib-Ordner enthalten (wird vom Installer kopiert)
2. ✅ **PawnIO**: Wird vom Installer automatisch installiert
3. ⚠️ **Neustart**: Nach PawnIO-Installation System neu starten!

### Manuelle Installation von PawnIO
Falls der Installer PawnIO nicht installiert hat:
```powershell
winget install namazso.PawnIO
# System neu starten!
```

### Überprüfung
Nach Installation die Dependency-Anzeig - EMPFOHLEN
- System.Security.AccessControl.dll ✅
- System.Security.Principal.Windows.dll ✅
- System.Threading.AccessControl.dll ✅ (optional)
- System.Memory.dll ✅
- System.Runtime.CompilerServices.Unsafe.dll ✅
- BlackSharp.Core.dll ✅
- RAMSPDToolkit-NDD.dll ✅
- DiskInfoToolkit.dll ✅
- **LibreHardwareMonitorLib.dll** ✅ (Hauptmodul)

### PowerShell 7+ - FUNKTIONIERT JETZT!
- System.Security.AccessControl.dll ✅ (WICHTIG für .NET 9 Kompatibilität!)
- System.Security.Principal.Windows.dll ✅ (WICHTIG für .NET 9 Kompatibilität!)
- System.Threading.AccessControl.dll ⚠️ (optional, kann Versionsprobleme haben)
- System.Memory.dll ✅
- System.Runtime.CompilerServices.Unsafe.dll ✅
- BlackSharp.Core.dll ✅
- RAMSPDToolkit-NDD.dll ✅
- DiskInfoToolkit.dll ✅
- **LibreHardwareMonitorLib.dll** ✅ (Hauptmodul)

> **HINWEIS:** Die System.Security.*.dll aus dem Lib-Ordner werden AUCH in PowerShell 7 
> geladen, da LibreHardwareMonitorLib APIs benötigt, die in .NET 9 anders sind
- RAMSPDToolkit-NDD.dll
- DiskInfoToolkit.dll
- **LibreHardwareMonitorLib.dll** (Hauptmodul)

> **HINWEIS:** Sy

### "DLLs wurden nicht gefunden" auf anderem Rechner
**Mögliche Ursachen:**
1. ❌ **PawnIO fehlt** → `winget install namazso.PawnIO` → Neustart!
2. ❌ **PowerShell 7 ohne Admin-Rechte** → Als Admin starten!
3. ❌ **Lib-Ordner wurde nicht kopiert** → Installer neu ausführen

**So prüfst du das:**
```powershell
# 1. Prüfe ob Lib-Ordner existiert
Test-Path "C:\Program Files\Bockis-Win_Gui\Lib"

# 2. Prüfe ob DLLs vorhanden sind
Get-ChildItem "C:\Program Files\Bockis-Win_Gui\Lib" -Filter "*.dll"

# 3. Prüfe PawnIO
Get-Service -Name "PawnIO"

# 4. Prüfe Admin-Rechte
([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
```stem.*.dll werden in PowerShell 7 NICHT aus dem Lib-Ordner geladen, 
> da PowerShell 7 eigene .NET 9 Versionen verwendet.

## Fehlerbehebung

### Hardware-Monitor deaktiviert: PawnIO-Treiber nicht verfügbar
**Lösung:**
```powershell
# PawnIO installieren
winget install namazso.PawnIO

# System neu starten
Restart-Computer
```

### Hardware-Monitor deaktiviert: DLLs fehlen
**Lösung:**
1. Prüfe ob Lib-Ordner existiert: `C:\Program Files\Bockis-Win_Gui\Lib`
2. Prüfe ob alle DLLs vorhanden sind (siehe Liste oben)
3. Neu-Installation des Tools

### Hardware-Monitor Initialisierung fehlgeschlagen: Keine Sensoren verfügbar
**Lösungen:**
1. Stelle sicher, dass alle DLLs im Lib-Ordner aktuell sind
2. Prüfe ob Administrator-Rechte vorhanden sind
3. System neu starten
4. PawnIO neu installieren:
   ```powershell
   winget uninstall namazso.PawnIO
   winget install namazso.PawnIO
   Restart-Computer
   ```

## Testing

### Test-Script
```powershell
# Test Hardware-Monitor-Initialisierung
Import-Module ".\Modules\Core\DependencyChecker.psm1" -Force
$result = Initialize-HardwareMonitoringMode -Verbose

if ($result.Available) {
    Write-Host "✓ Hardware-Monitor verfügbar" -ForegroundColor Green
    Write-Host "  Lib-Pfad: $($result.LibrePath)" -ForegroundColor Gray
    Write-Host "  PawnIO: $($result.PawnIOActive)" -ForegroundColor Gray
    Write-Host "  Message: $($result.Message)" -ForegroundColor Gray
} else {
    Write-Host "✗ Hardware-Monitor nicht verfügbar" -ForegroundColor Red
    Write-Host "  Message: $($result.Message)" -ForegroundColor Yellow
    
    if ($result.MissingDLLs.Count -gt 0) {
        Write-Host "`nFehlende DLLs:" -ForegroundColor Yellow
        $result.MissingDLLs | ForEach-Object {
            Write-Host "  - $($_.FileName)" -ForegroundColor Gray
            Write-Host "    $($_.Description)" -ForegroundColor DarkGray
        }
    }
}
```

## Datum
2026-02-09

## Update (09.02.2026 15:00)
🎉 **DEFENDER-PROBLEM GELÖST!**

LibreHardwareMonitor v0.9.5 (Januar 2026) nutzt jetzt **PawnIO statt Winring0**!

**Was war das Problem:**
- Alte Version 0.9.4: Winring0-Treiber → Defender-Alarm ❌
- Neue Version 0.9.5: PawnIO-Treiber → Kein Alarm ✅

**Automatische Erkennung:**
Der DependencyChecker prüft jetzt automatisch die Version und warnt bei < 0.9.5!

**Update durchführen:**
```powershell
cd Tools
.\Update-LibreHardwareMonitor.ps1
```

**Version prüfen:**
```powershell
cd Tools
.\Test-LibVersionCheck.ps1
```

**Nach dem Update:**
- Keine Defender-Alarme mehr!
- Hardware-Monitoring funktioniert mit PawnIO
- System neu starten nach Update

Details: [DEFENDER-WINRING0-PROBLEM.md](DEFENDER-WINRING0-PROBLEM.md)

---

## Status (Original)
✅ **Behoben** - Alle Probleme gelöst:

1. ✅ **Lib-Pfad ist korrekt** - DLLs werden aus dem richtigen Ordner geladen
2. ✅ **Installer angepasst** - Installiert nur noch PawnIO (nicht mehr LibreHardwareMonitor)
3. ✅ **PowerShell 7 Support** - System.Security.*.dll werden jetzt auch in PS7 geladen
4. ✅ **Bessere Fehlermeldungen** - Zeigen genau, was fehlt und wo gesucht wurde
5. ✅ **Test-Script** - [Tools/Test-LibPath.ps1](Tools/Test-LibPath.ps1) zur Diagnose

### Wichtigste Erkenntnis
**Der Lib-Pfad war NIE das Problem!** Die DLLs wurden immer korrekt gefunden.  
Die Probleme waren:
- Installer installierte LibreHardwareMonitor statt nur PawnIO
- PowerShell 7 benötigte zusätzliche DLLs für Kompatibilität
- Fehlende Admin-Rechte oder PawnIO führten zu verwirrenden Meldungen

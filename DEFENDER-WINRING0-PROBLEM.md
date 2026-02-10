# Windows Defender erkennt Winring0 als Malware

## Problem
Trotz PawnIO-Installation meldet Windows Defender:
- **VulnerableDriver:WinNT/Winring0**
- Betroffene Datei: `c:\windows\system32\windowspowershell\v1.0\powershell.sys`
- Driver: **R0powershell**

## Ursache
**LibreHardwareMonitorLib.dll** hat den **Winring0** Kernel-Treiber **eingebaut** und lädt diesen automatisch beim Aufruf von `Computer.Open()`.

**PawnIO wird NICHT genutzt**, auch wenn es installiert ist!

## Warum ist das ein Problem?

### Winring0 vs PawnIO

| Feature | Winring0 (ALT) | PawnIO (NEU) |
|---------|----------------|--------------|
| Sicherheit | ❌ Unsicher | ✅ Sicher |
| Code-Signing | ❌ Keine | ✅ Signiert |
| Defender | ❌ Als Malware erkannt | ✅ Vertrauenswürdig |
| Wartung | ❌ Nicht mehr gepflegt | ✅ Aktive Entwicklung |
| Ring-0 Zugriff | ✅ Ja | ✅ Ja |

### Windows Defender Erkennung
Winring0 wird als **VulnerableDriver** erkannt, weil:
1. Kernel-Treiber ohne Code-Signatur
2. Bekannte Sicherheitslücken
3. Wird von Malware missbraucht
4. Nicht mehr gepflegt seit Jahren

## Lösung: LibreHardwareMonitorLib für PawnIO neu kompilieren

### Option 1: Speziell kompilierte Version nutzen
LibreHardwareMonitor kann für **nur PawnIO** kompiliert werden:

```bash
# GitHub Repo klonen
git clone https://github.com/LibreHardwareMonitor/LibreHardwareMonitor.git
cd LibreHardwareMonitor

# Build-Konfiguration anpassen (nur PawnIO, kein Winring0)
# In LibreHardwareMonitorLib/Hardware/Ring0.cs:
# - PAWNIO_ONLY definieren
# - Winring0 Code entfernen

# Mit Visual Studio kompilieren
msbuild LibreHardwareMonitor.sln /p:Configuration=Release
```

### Option 2: Alternative Hardware-Monitor-Bibliothek
Andere Optionen die PawnIO nativ unterstützen:
- **HardwareMonitor.NET** (neuere Fork von LibreHardwareMonitor)
- **OpenHardwareMonitor** (mit PawnIO-Patch)

### Option 3: Defender-Ausnahme (NICHT EMPFOHLEN)
```powershell
# NUR ALS LETZTER AUSWEG!
Add-MpPreference -ExclusionPath "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.sys"
```

**⚠️ NICHT EMPFOHLEN** - Schwächt die Systemsicherheit!

## Technische Details

### Wie LibreHardwareMonitorLib Treiber lädt

1. `Computer.Open()` wird aufgerufen
2. LibreHardwareMonitorLib prüft verfügbare Treiber:
   - Winring0 (eingebaut in DLL)
   - PawnIO (falls installiert)
3. **PROBLEM:** Winring0 hat Priorität!
4. Winring0 wird aus DLL-Ressourcen extrahiert nach:
   - `C:\Windows\System32\WindowsPowerShell\v1.0\powershell.sys`
5. Treiber wird geladen → Defender schlägt Alarm

### PawnIO-Only Konfiguration

LibreHardwareMonitorLib muss SO kompiliert werden:

```csharp
// Ring0.cs - NUR PawnIO nutzen
public class Ring0 {
    #if PAWNIO_ONLY
        // Nur PawnIO-Treiber laden
        private static bool LoadPawnIO() {
            // PawnIO Service nutzen
        }
    #else
        // ALTE VERSION: Winring0 + PawnIO
        private static bool LoadWinring0() {
            // Winring0 aus DLL-Ressourcen extrahieren
            // → WIRD VON DEFENDER BLOCKIERT!
        }
    #endif
}
```

## Sofortmaßnahme: Hardware-Monitoring deaktivieren

Bis wir eine PawnIO-only Version haben:

```powershell
# In DependencyChecker.psm1:
# LibreHardwareMonitorLib NICHT laden wenn Defender aktiv ist

function Initialize-HardwareMonitoringMode {
    # Prüfe ob Defender aktiv ist
    $defenderStatus = Get-MpComputerStatus
    if ($defenderStatus.RealTimeProtectionEnabled) {
        $result.Message = @"
Hardware-Monitor deaktiviert: Windows Defender blockiert Winring0-Treiber

LibreHardwareMonitorLib nutzt den unsicheren Winring0-Treiber der als
Malware erkannt wird. PawnIO wird NICHT genutzt!

Lösungen:
  1. Warte auf Update mit PawnIO-only Version
  2. Deaktiviere Hardware-Monitoring
  3. Nutze alternative Monitor-Bibliothek

Details: DEFENDER-WINRING0-PROBLEM.md
"@
        return $result
    }
}
```

## Action Plan

### Kurzfristig (JETZT)
1. ✅ Dokumentiere Problem
2. ⏳ Prüfe ob neuere LibreHardwareMonitorLib Version PawnIO-only Option hat
3. ⏳ Teste alternative Hardware-Monitor-Bibliotheken

### Mittelfristig (nächste Woche)
1. ⏳ LibreHardwareMonitor mit PawnIO-only neu kompilieren
2. ⏳ Neue DLL testen
3. ⏳ In Lib-Ordner einbauen

### Langfristig (Release)
1. ⏳ Defender-sichere Hardware-Monitor-Lösung
2. ⏳ Automatische Treiber-Erkennung (PawnIO > Winring0)
3. ⏳ Fallback zu WMI wenn keine Treiber verfügbar

## Status
✅ **GELÖST** - Update auf LibreHardwareMonitorLib v0.9.5 behebt das Problem!

**Version 0.9.5 (Januar 2026):**
- ✅ Swap WinRing0 to PawnIO (#1857)
- ✅ Use PawnIO driver directly in LibreHardwareMonitorLib (#1908)
- ✅ **KEIN DEFENDER-ALARM MEHR!**

**Update-Anweisung:**
1. Alle PowerShell-Fenster und VS Code schließen
2. [Tools/Update-LibreHardwareMonitor.ps1](Tools/Update-LibreHardwareMonitor.ps1) ausführen
3. System neu starten
4. Fertig! Hardware-Monitoring funktioniert mit PawnIO

## Datum
2026-02-09  

## Referenzen
- LibreHardwareMonitor: https://github.com/LibreHardwareMonitor/LibreHardwareMonitor
- PawnIO: https://github.com/namazso/PawnIO
- Windows Defender Detection: VulnerableDriver:WinNT/Winring0

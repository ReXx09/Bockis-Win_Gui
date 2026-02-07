# HARDWARE-MONITOR FIX - ÄNDERUNGSPROTOKOLL
Datum: 06.02.2026

## Problem
Hardware-Monitor wurde beim Start deaktiviert mit der Fehlermeldung:
```
"Method not found: 'Void System.Threading.Mutex..ctor(Boolean, System.String, Boolean ByRef, System.Security.AccessControl.MutexSecurity)'"
```

## Ursache
1. **Inkompatible System-DLLs** im Lib-Ordner:
   - `System.Security.AccessControl.dll`
   - `System.Security.Principal.Windows.dll`
   - `System.Threading.AccessControl.dll`
   
   Diese DLLs werden vom .NET Framework automatisch bereitgestellt und dürfen NICHT manuell geladen werden. Sie verursachten Kompatibilitätsprobleme mit der Mutex-Constructor-Signatur.

2. **Neuere LibreHardwareMonitorLib (0.9.5)** hatte Kompatibilitätsproblem
   - Version 0.9.4 (aus Release) funktioniert korrekt

3. **ProgressBar wurde nicht korrekt übergeben** bei der Hardware-Monitor-Initialisierung

## Durchgeführte Änderungen

### 1. DLLs ins Archiv verschoben
**Quelle:** `Bockis-Win_Gui_DEV\Lib\`  
**Ziel:** `Bockis-Win_Gui_DEV\_Archive\`

- ✅ `System.Security.AccessControl.dll`
- ✅ `System.Security.Principal.Windows.dll`  
- ✅ `System.Threading.AccessControl.dll`
- ✅ `LibreHardwareMonitorLib-0.9.5.dll` (Backup der alten Version)

### 2. LibreHardwareMonitorLib downgrade
- ❌ **Entfernt:** LibreHardwareMonitorLib.dll Version 0.9.5 (1138 KB)
- ✅ **Installiert:** LibreHardwareMonitorLib.dll Version 0.9.4 (695 KB, aus Release kopiert)

### 3. Code-Änderungen

#### `Modules\Core\DependencyChecker.psm1`
**Funktion:** `Initialize-HardwareMonitoringMode`

**Vorher:**
```powershell
$requiredDLLs = @{
    'System.Security.AccessControl.dll' = '...'
    'System.Security.Principal.Windows.dll' = '...'
    'System.Threading.AccessControl.dll' = '...'
    'System.Memory.dll' = '...'
    # ...
}
```

**Nachher:**
```powershell
# System.Security.*.dll ENTFERNT - werden von .NET Framework bereitgestellt
$requiredDLLs = [ordered]@{
    'System.Memory.dll' = @{ Description = '...'; Optional = $false }
    'System.Runtime.CompilerServices.Unsafe.dll' = @{ ... }
    'BlackSharp.Core.dll' = @{ ... }
    'RAMSPDToolkit-NDD.dll' = @{ ... }
    'DiskInfoToolkit.dll' = @{ ... }
    'LibreHardwareMonitorLib.dll' = @{ ... }
}
```

**Neu hinzugefügt:**
- ProgressBar-Integration (8 Fortschrittsschritte 10%-100%)
- Detaillierte Fehlermeldungen bei fehlenden DLLs
- Optionale DLL-Unterstützung
- Besseres Error-Handling

#### `Win_Gui_Module.ps1`
**Zeile ca. 6000-6010:**

**Vorher:**
```powershell
$globalProgressBar = if (Get-Variable -Name 'script:progressBar' -Scope Script ...) { 
    $script:progressBar 
} else { 
    $null 
}
$hwMonitorStatus = Initialize-HardwareMonitoringMode -ProgressBar $globalProgressBar ...
```

**Nachher:**
```powershell
# Übergebe die ProgressBar direkt (sie existiert bereits im lokalen Scope)
$hwMonitorStatus = Initialize-HardwareMonitoringMode -ProgressBar $progressBar -StatusLabel $null
```

### 4. Neue Test-/Fix-Scripts erstellt

#### `Tools\Fix-LibreHardwareMonitorDLL.ps1`
- Automatisches Ersetzen der LibreHardwareMonitorLib 0.9.5 → 0.9.4
- Erstellt Backup der alten Version
- Zeigt Versionen an

#### `Tools\Test-HardwareMonitor.ps1`  
- Vollständiger Hardware-Monitor-Test
- Prüft alle benötigten DLLs
- Zeigt DLL-Versionen an
- Testet Initialize-HardwareMonitoringMode
- Gibt klare Fehlerdiagnose

## Benötigte DLLs (finale Liste)

**Im Lib-Ordner MÜSSEN vorhanden sein:**
1. ✅ `System.Memory.dll` (141.8 KB)
2. ✅ `System.Runtime.CompilerServices.Unsafe.dll` (18.8 KB)
3. ✅ `BlackSharp.Core.dll` (32 KB)
4. ✅ `RAMSPDToolkit-NDD.dll` (228 KB)
5. ✅ `DiskInfoToolkit.dll` (882 KB)
6. ✅ `LibreHardwareMonitorLib.dll` (695.5 KB - Version 0.9.4)

**Getrennte Funktion (nicht für HWM):**
- `System.Data.SQLite.dll` (für Datenbank)

## Weitere Abhängigkeiten
- **PawnIO-Treiber** muss installiert sein: `winget install namazso.PawnIO`
- **Administrator-Rechte** erforderlich für Hardware-Zugriff

## Test nach Neustart

Nach VOLLSTÄNDIGEM Neustart (alle PowerShell/VS Code geschlossen):

```powershell
cd "c:\Users\ReXx\Desktop\VS-CODE-Repos\Bockis-Win_Gui_DEV"
.\Tools\Test-HardwareMonitor.ps1
```

Erwartetes Ergebnis:
```
✓ DLL-Datei: Version 0.9.4 (695 KB)
✓ Alle 6 benötigten DLLs vorhanden
✓ HARDWARE-MONITOR FUNKTIONIERT!
```

## Status
- ✅ Code angepasst
- ✅ DLLs entfernt/ersetzt
- ✅ Test-Scripts erstellt
- ⏳ **NEUSTART ERFORDERLICH** (damit neue DLL geladen wird)
- ⏳ Test nach Neustart ausstehend

## Notizen
- **PowerShell cached DLLs:** Einmal geladene DLLs bleiben im RAM bis zum Prozess-Ende
- **Keine Hot-Reload:** DLL-Änderungen erfordern IMMER kompletten Neustart
- **Version 0.9.4 stabil:** Getestet in Release, funktioniert einwandfrei

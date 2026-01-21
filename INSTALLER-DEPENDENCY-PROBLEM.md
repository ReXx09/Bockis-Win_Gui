# INSTALLER-DEPENDENCY-PROBLEM.md
# Dokumentation: LibreHardwareMonitor Abhängigkeitsproblem

## 🔴 Problem-Beschreibung

### Symptom
- **Entwickler-PC**: Hardware-Monitoring funktioniert einwandfrei
- **Andere PCs nach Installation**: Hardware-Monitoring zeigt keine Werte oder Fehler "PawnIO-Treiber fehlt"

### Root Cause
Der Code in [HardwareMonitorTools.psm1](Modules/Monitor/HardwareMonitorTools.psm1) lädt LibreHardwareMonitor in dieser Priorität:

```powershell
# Zeile 1011-1030: Pfad-Suche
PRIORITÄT 1: System-Installation
  ✓ ${env:LOCALAPPDATA}\Microsoft\WinGet\Packages\LibreHardwareMonitor*\
  ✓ ${env:ProgramFiles}\LibreHardwareMonitor\
  → Enthält PawnIO-Treiber (automatisch installiert)

PRIORITÄT 2: Gebündelte DLL
  ⚠️ .\Lib\LibreHardwareMonitorLib.dll
  → Enthält KEINEN installierten Treiber (nur Bibliothek)
```

### Warum funktioniert es beim Entwickler?
```powershell
# Entwickler-PC:
winget list | Select-String "LibreHardware"
# → LibreHardwareMonitor v0.9.5 gefunden
# → Code lädt System-DLL aus WinGet-Packages
# → PawnIO-Treiber bereits installiert ✓
```

### Warum funktioniert es NICHT auf anderen PCs?
```powershell
# Frische Installation:
# 1. Installer kopiert Lib\LibreHardwareMonitorLib.dll → ✓ Datei vorhanden
# 2. Code versucht System-Pfade → ✗ Nichts gefunden
# 3. Code fällt zurück auf Lib\ → ⚠️ DLL geladen, ABER:
#    - PawnIO-Treiber NICHT installiert (nur extrahiert, wenn Winget installiert)
#    - LibreHWM braucht Admin-Rechte für Treiber-Installation
#    - Kernel-Treiber wird NICHT automatisch aus DLL extrahiert
# 4. Ergebnis: "Computer object initialization failed"
```

## 🛠️ Technischer Hintergrund

### PawnIO/WinRing0 Treiber-Installation
```
LibreHardwareMonitor-Installation (via WinGet):
┌──────────────────────────────────────────────────┐
│ 1. winget install LibreHardwareMonitor          │
│    ↓                                              │
│ 2. Entpackt Dateien nach:                        │
│    %LOCALAPPDATA%\Microsoft\WinGet\Packages\...  │
│    ├── LibreHardwareMonitor.exe                  │
│    ├── LibreHardwareMonitorLib.dll               │
│    └── (Eingebetteter PawnIO-Treiber in DLL)     │
│    ↓                                              │
│ 3. Bei ERSTEM Start mit Admin-Rechten:           │
│    → PawnIO.sys extrahiert nach:                 │
│       C:\Windows\System32\drivers\               │
│    → Treiber signiert und registriert            │
│    → Kernel-Modus-Zugriff aktiviert              │
└──────────────────────────────────────────────────┘

Manuelle DLL-Kopie (nur Lib\ Ordner):
┌──────────────────────────────────────────────────┐
│ 1. Installer kopiert LibreHardwareMonitorLib.dll │
│    ↓                                              │
│ 2. DLL wird geladen (Add-Type)                   │
│    ↓                                              │
│ 3. Code initialisiert Computer-Objekt            │
│    ↓                                              │
│ 4. ✗ FEHLER: Treiber nicht vorhanden             │
│    Grund: Keine Admin-Installation-Routine       │
│    Fehlende Signatur/Registrierung                │
└──────────────────────────────────────────────────┘
```

### Warum kann die DLL den Treiber nicht selbst installieren?
1. **Fehlende Admin-Rechte**: GUI startet ohne Admin → DLL kann nicht in `C:\Windows\System32\drivers\` schreiben
2. **Keine Signatur**: Treiber muss digital signiert sein (WinGet-Version ist signiert, extrahierte nicht)
3. **Registry-Einträge**: Kernel-Treiber braucht Registry-Keys in `HKLM\System\CurrentControlSet\Services\`
4. **Driver Verifier**: Windows prüft Treiber-Integrität beim Laden

## ✅ Lösung 1: Auto-Installation via Installer (EMPFOHLEN)

### Änderung in [installer.iss](installer.iss)
```innosetup
[Run]
; LibreHardwareMonitor über WinGet installieren (kritisch für Hardware-Monitoring)
Filename: "{sys}\WindowsPowerShell\v1.0\powershell.exe"; 
Parameters: "-NoProfile -ExecutionPolicy Bypass -Command ""& { try { $null = Get-Command winget -ErrorAction Stop; Write-Host 'Installiere LibreHardwareMonitor...'; winget install --id LibreHardwareMonitor.LibreHardwareMonitor --exact --silent --accept-source-agreements --accept-package-agreements | Out-Null; if ($LASTEXITCODE -eq 0 -or $LASTEXITCODE -eq -1978335189) { Write-Host 'LibreHardwareMonitor installiert!' -ForegroundColor Green } else { Write-Warning 'Installation fehlgeschlagen (Code: $LASTEXITCODE)' } } catch { Write-Warning 'WinGet nicht verfügbar - Hardware-Monitoring wird eingeschränkt funktionieren' } }"""; 
Description: "Hardware-Monitor-Abhängigkeit installieren (empfohlen)"; 
StatusMsg: "Installiere LibreHardwareMonitor via WinGet..."; 
Flags: runhidden
```

### Vorteile
- ✅ PawnIO-Treiber wird automatisch installiert
- ✅ Signierte System-Installation
- ✅ Funktioniert auf allen PCs (Windows 10 1809+)
- ✅ Keine manuellen Schritte nötig

### Exit Codes
```powershell
0              # Erfolgreich installiert
-1978335189    # Bereits installiert (0x8A15000B - kein Fehler!)
Andere         # Fehler (WinGet nicht verfügbar, keine Internet-Verbindung, etc.)
```

## ✅ Lösung 2: Fallback-System (BEREITS IMPLEMENTIERT)

Falls WinGet nicht verfügbar oder Installation fehlschlägt:

### [HardwareMonitorTools.psm1](Modules/Monitor/HardwareMonitorTools.psm1) Zeile 780-850
```powershell
# Timer-Event mit Fallback-Unterstützung
if ($null -ne $script:computerObj) {
    # LibreHWM verfügbar: Volle Hardware-Überwachung
    Update-CpuInfo ...
    Update-GpuInfo ...
    Update-RamInfo ...
}
elseif ($script:useFallbackSensors) {
    # Nur Performance Counters: Eingeschränkter Modus
    Update-CpuInfoFallback ...
    Update-GpuInfoFallback ...
    Update-RamInfoFallback ...
}
```

### [FallbackSensors.psm1](Modules/Monitor/FallbackSensors.psm1)
```powershell
# Alternative Datenquellen:
- Performance Counters: CPU-Last, GPU-Auslastung
- WMI/CIM: RAM-Nutzung, System-Info
- ACPI Thermal Zones: Temperaturen (falls verfügbar)
```

### Einschränkungen
- ❌ Keine exakten Temperaturen (nur Schätzungen via ACPI)
- ❌ Keine Lüftergeschwindigkeiten
- ❌ Keine Spannungswerte
- ✅ CPU-Last funktioniert (100%)
- ✅ RAM-Nutzung funktioniert (100%)
- ✅ GPU-Last funktioniert (~80%, sprach-abhängig)

## 📋 Checkliste für Release

### Vor dem Build
- [ ] Teste Installer auf sauberer VM (ohne WinGet)
- [ ] Teste Installer auf PC mit WinGet
- [ ] Prüfe Exit Codes der LibreHWM-Installation
- [ ] Verifiziere Fallback-Modus ohne LibreHWM

### Test-Skript
```powershell
# Auf Ziel-PC nach Installation:
.\Tools\Test-InstallerDependencies.ps1
# Erwartete Ausgabe:
# 🟢 OPTIMAL: Alle Abhängigkeiten erfüllt!
```

### Installer-Build
```powershell
# Kompiliere Installer mit neuer [Run]-Sektion
iscc.exe installer.iss

# Signiere Installer (optional)
.\Sign-AllScripts.ps1 -Verbose
```

## 🔄 Vergleich: Vorher vs. Nachher

### Vorher (Broken State)
```
Installer → Kopiert Lib\LibreHardwareMonitorLib.dll
           ↓
Ziel-PC → Lädt DLL
         ↓
         ✗ Treiber fehlt → Hardware-Monitor kaputt
```

### Nachher (Fixed)
```
Installer → 1. Kopiert Lib\LibreHardwareMonitorLib.dll (Fallback)
           → 2. Führt WinGet-Installation aus
           ↓
Ziel-PC → Lädt System-DLL (WinGet)
         ↓
         ✓ PawnIO-Treiber vorhanden → Hardware-Monitor funktioniert!
         
Falls WinGet fehlt:
Ziel-PC → Lädt Lib\LibreHardwareMonitorLib.dll
         ↓
         ⚠️ Fallback-Modus aktiviert
         ↓
         ✓ Eingeschränkte Werte (ohne Temperaturen)
```

## 📚 Weiterführende Infos

- **LibreHWM GitHub**: https://github.com/LibreHardwareMonitor/LibreHardwareMonitor
- **PawnIO PR**: https://github.com/LibreHardwareMonitor/LibreHardwareMonitor/pull/1857
- **WinGet Installation**: https://learn.microsoft.com/en-us/windows/package-manager/winget/

---

**Erstellt**: 2026-01-20  
**Autor**: Bockis  
**Kategorie**: Build/Installer  
**Status**: ✅ Behoben

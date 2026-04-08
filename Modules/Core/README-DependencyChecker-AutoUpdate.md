# DependencyChecker - Automatisches DLL-Update

## 📋 Übersicht

Der DependencyChecker wurde erweitert um **automatisches Update** der LibreHardwareMonitorLib.dll.

## ✨ Neue Funktionen

### 1. Automatische Versionsprüfung
- Prüft beim Start, ob LibreHardwareMonitorLib.dll v0.9.5+ vorliegt
- Warnt bei veralteten Versionen (< 0.9.5)

### 2. Interaktives Update
Wenn eine veraltete DLL erkannt wird:
1. **Dialog erscheint** mit Warnung:
   - Aktuelle Version wird angezeigt
   - Problem erklärt (Winring0 vs PawnIO)
   - Update-Option angeboten

2. **Bei "Ja"**:
   - Download von NuGet (ca. 1 MB)
   - Automatisches Backup der alten Version
   - Installation der neuen DLL
   - Erfolgsmeldung mit Neustart-Hinweis

3. **Bei "Nein"**:
   - Hardware-Monitoring wird deaktiviert
   - Manuelle Update-Anleitung wird angezeigt

### 3. Intelligentes Caching
- Prüft erst lokalen Temp-Cache
- Nur bei Bedarf Download von NuGet
- Spart Zeit bei wiederholten Updates

## 🔧 Technische Details

### Update-Funktion: `Update-LibreHardwareMonitorDll`

**Parameter:**
- `LibPath`: Pfad zum Lib-Ordner (pflicht)
- `ProgressCallback`: Scriptblock für Fortschrittsanzeige (optional)

**Rückgabe:**
```powershell
@{
    Success = $true/$false
    NewVersion = "0.9.5"  # Bei Erfolg
    ErrorMessage = "..."  # Bei Fehler
}
```

**Ablauf:**
1. Prüfe Temp-Cache auf v0.9.5
2. Falls nicht vorhanden: Download von NuGet
3. Entpacke .nupkg
4. Prüfe Source-DLL Version
5. Erstelle Backup (*.dll.old)
6. Ersetze Target-DLL
7. Validiere neue Version

### Integration in Initialize-HardwareMonitoringMode

**Schritt 3 (erweitert):**
```powershell
# Alte Version erkannt (< 0.9.5)?
if ($version -lt [version]"0.9.5") {
    # Dialog anzeigen
    $result = [MessageBox]::Show(...)
    
    # Bei Ja: Update durchführen
    if ($result -eq Yes) {
        $updateResult = Update-LibreHardwareMonitorDll ...
        
        # Bei Erfolg: Neustart erforderlich
        if ($updateResult.Success) {
            # Erfolgsmeldung + Exit
        }
    }
}
```

## 🎯 Vorteile

✅ **Automatisch**: Kein manuelles Skript mehr nötig
✅ **Sicher**: Backup wird automatisch erstellt
✅ **Benutzerfreundlich**: Klarer Dialog mit Erklärung
✅ **Schnell**: Nur ~1 MB Download
✅ **Zuverlässig**: Versionsprüfung vor und nach Update
✅ **Smart**: Nutzt Cache wenn vorhanden

## 🚀 Verwendung

### Für Entwickler
```powershell
# Modul laden
Import-Module ".\Modules\Core\DependencyChecker.psm1"

# Hardware-Monitoring initialisieren (mit Versionsprüfung)
$result = Initialize-HardwareMonitoringMode -ProgressBar $progressBar

# Bei veralteter Version wird automatisch Update-Dialog angezeigt
```

### Für Benutzer
1. **GUI starten**
2. **Bei veralteter DLL**:
   - Dialog erscheint automatisch
   - "Ja" klicken für Update
   - Warten auf Download (~5 Sekunden)
3. **GUI neu starten**
4. **Fertig!** Hardware-Monitoring mit PawnIO aktiv ✓

## 📁 Dateien

### Geändert
- `Modules\Core\DependencyChecker.psm1`
  - Funktion `Update-LibreHardwareMonitorDll` hinzugefügt
  - `Initialize-HardwareMonitoringMode` erweitert (Schritt 3)

### Backup-Dateien (automatisch erstellt)
- `Lib\LibreHardwareMonitorLib.dll.old` - Backup der v0.9.4

### Temp-Dateien (Cache)
- `%TEMP%\LibreHardwareMonitorLib-0.9.5\` - Extrahiertes NuGet-Paket

## ⚠️ Wichtige Hinweise

1. **Neustart erforderlich**: Nach Update MUSS die GUI neu gestartet werden
   - .NET lädt DLLs nur einmal beim Start
   - Neue Version wird erst nach Neustart aktiv

2. **Administrator-Rechte**: NICHT erforderlich
   - Update-Dialog funktioniert als normaler Benutzer
   - Falls Zugriff verweigert: Programm als Admin starten

3. **Internet erforderlich**: Nur beim ersten Update
   - Danach bleibt v0.9.5 im Temp-Cache
   - Bei Cache-Treffer kein Download nötig

4. **Backup**: Wird automatisch erstellt
   - Alte Version: `LibreHardwareMonitorLib.dll.old`
   - Rollback möglich durch Umbenennen

## 🐛 Fehlerbehebung

### Update fehlgeschlagen
**Ursache**: DLL ist gesperrt (von anderem Prozess verwendet)
**Lösung**: 
1. Alle PowerShell-Terminals schließen
2. VS Code komplett schließen
3. GUI neu starten → Update erneut versuchen

### Download-Fehler
**Ursache**: Keine Internetverbindung / Firewall
**Lösung**: 
1. Internetverbindung prüfen
2. Manuelles Update: `Tools\Update-LibreHardwareMonitor.ps1`

### Version nicht erkannt
**Ursache**: DLL beschädigt
**Lösung**:
1. Backup wiederherstellen: `.dll.old` → `.dll`
2. Manueller Download von NuGet
3. DLL manuell ersetzen

## 📊 Versionshistorie

### v1.0 (09.02.2026)
- ✨ Automatisches Update von LibreHardwareMonitorLib.dll
- ✨ Interaktiver Update-Dialog
- ✨ NuGet-Integration
- ✨ Intelligentes Caching
- ✨ Automatisches Backup
- ✨ Versionsprüfung vor/nach Update

## 🔗 Links

- **NuGet-Paket**: https://www.nuget.org/packages/LibreHardwareMonitorLib/0.9.5
- **GitHub**: https://github.com/LibreHardwareMonitor/LibreHardwareMonitor
- **PawnIO**: https://github.com/namazso/PawnIO

---

**Status**: ✅ Production Ready
**Getestet**: Windows 11 (Build 26200)
**Abhängigkeiten**: .NET Framework 4.7.2+

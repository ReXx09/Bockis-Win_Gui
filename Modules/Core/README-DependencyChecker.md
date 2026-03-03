# Dependency Checker - Systemabhängigkeiten verwalten

## Übersicht

Das **DependencyChecker-Modul** prüft beim Start der GUI automatisch, ob alle empfohlenen Systemkomponenten installiert sind und bietet dem Nutzer die Möglichkeit, fehlende Pakete zu installieren.

## Features

### ✅ Automatische Erkennung

- **LibreHardwareMonitor**: Sucht System-Installation in Standard-Pfaden
- **PowerShell Core 7+**: Prüft ob moderne PowerShell verfügbar ist
- **Winget-Verfügbarkeit**: Validiert Installationsmöglichkeiten

### 🎯 Priorisiertes Laden von LibreHardwareMonitor

```
PRIORITÄT 1: DependencyChecker-Preferred Path
             ↓
PRIORITÄT 2: System-Installation (Program Files)
             ↓  
PRIORITÄT 3: Integrierte Lib (Projekt-Ordner)
```

**Vorteile der System-Installation:**
- ✅ Aktuelle Signierung (kein Defender-Alarm)
- ✅ Automatische Updates über Winget
- ✅ WHQL-zertifizierte Treiber
- ✅ Windows 11 HVCI-kompatibel

### 💬 Benutzerfreundlicher Dialog

Bei fehlenden Abhängigkeiten erscheint ein moderner Dialog:

```
┌─────────────────────────────────────────────────┐
│  📦 Abhängigkeiten werden geprüft               │
│  Für optimale Funktionalität werden zusätzliche │
│  Komponenten empfohlen.                         │
├─────────────────────────────────────────────────┤
│                                                 │
│  ☑ LibreHardwareMonitor                        │
│     Hardware-Überwachung mit aktuellen Sensoren│
│                                                 │
├─────────────────────────────────────────────────┤
│            [✓ Ausgewählte installieren]         │
│                            [→ Überspringen]     │
└─────────────────────────────────────────────────┘
```

**Optionen:**
- **Installieren**: Lädt und installiert via Winget
- **Überspringen**: Nutzt integrierte Bibliotheken (Fallback)

## Integration in GUI

### Automatischer Check beim Start

```powershell
# In Win_Gui_Module.ps1 (vor Hardware-Initialisierung)

$depCheckResult = Test-SystemDependencies -ShowDialog

if ($depCheckResult.UseSystemLibreHardwareMonitor) {
    # System-Installation wird bevorzugt
}
else {
    # Fallback auf integrierte Lib
}
```

### Hardware-Monitor lädt automatisch richtige DLL

```powershell
# In HardwareMonitorTools.psm1

function Initialize-LibreHardwareMonitor {
    # Priorisierte Pfad-Suche:
    # 1. Get-PreferredLibreHardwareMonitorPath (DependencyChecker)
    # 2. System-Installationen (Program Files)
    # 3. Integrierte Lib (Fallback)
}
```

## Verwendung

### Manueller Test

```powershell
# Nur Suche (keine Installation)
.\Tools\Test-DependencyChecker.ps1 -FindOnly

# Mit Dialog
.\Tools\Test-DependencyChecker.ps1 -ShowDialog

# Automatische Installation
.\Tools\Test-DependencyChecker.ps1 -AutoInstall
```

### Programmatische Nutzung

```powershell
# Modul importieren
Import-Module ".\Modules\Core\DependencyChecker.psm1" -Force

# LibreHardwareMonitor suchen
$lhm = Find-LibreHardwareMonitor
if ($lhm.Found) {
    Write-Host "Gefunden: $($lhm.Path)"
    Write-Host "Version:  $($lhm.Version)"
    Write-Host "Signiert: $($lhm.IsSigned)"
}

# Vollständiger Dependency-Check
$result = Test-SystemDependencies -ShowDialog

# Bevorzugten Pfad abrufen
$path = Get-PreferredLibreHardwareMonitorPath
```

## Verfügbare Funktionen

### `Find-LibreHardwareMonitor`
Sucht nach installierter LibreHardwareMonitor-Version.

**Rückgabe:**
```powershell
@{
    Found = $true/$false
    Path = "C:\Program Files\LibreHardwareMonitor\LibreHardwareMonitorLib.dll"
    Version = "0.9.5"
    IsSigned = $true
}
```

### `Test-LibreHardwareMonitorAvailability`
Prüft ob LibreHardwareMonitor über Winget installierbar ist.

**Rückgabe:** `Boolean`

### `Install-LibreHardwareMonitor`
Installiert LibreHardwareMonitor über Winget.

**Parameter:**
- `-Silent`: Installation ohne Bestätigung

**Rückgabe:** `Boolean` (Erfolg)

### `Find-PowerShellCore`
Prüft ob PowerShell Core 7+ installiert ist.

**Rückgabe:**
```powershell
@{
    Found = $true/$false
    Version = [Version]"7.5.4"
    Path = "C:\Program Files\PowerShell\7\pwsh.exe"
}
```

### `Show-DependencyDialog`
Zeigt modernen WinForms-Dialog für Abhängigkeitswahl.

**Parameter:**
```powershell
$dependencies = @(
    @{
        Name = "LibreHardwareMonitor"
        Description = "Hardware-Überwachung..."
        Required = $false
        Available = $true
    }
)
Show-DependencyDialog -MissingDependencies $dependencies
```

**Rückgabe:**
```powershell
@{
    DialogResult = [System.Windows.Forms.DialogResult]::OK
    Choices = @{
        "LibreHardwareMonitor" = @{
            Install = $true
            Checked = $true
        }
    }
}
```

### `Test-SystemDependencies`
Hauptfunktion für vollständigen Dependency-Check.

**Parameter:**
- `-ShowDialog`: Zeigt Dialog bei fehlenden Abhängigkeiten
- `-AutoInstall`: Installiert automatisch ohne Dialog

**Rückgabe:**
```powershell
@{
    AllSatisfied = $true/$false
    UseSystemLibreHardwareMonitor = $true
    SystemLibrePath = "C:\Program Files\..."
}
```

### `Get-PreferredLibreHardwareMonitorPath`
Gibt bevorzugten Pfad zur LibreHardwareMonitor-DLL zurück.

**Rückgabe:** `String` (Pfad zur DLL)

## Konfiguration

### Settings.json Integration (zukünftig)

```json
{
  "DependencyChecker": {
    "AutoCheck": true,
    "ShowDialogOnMissing": true,
    "PreferSystemInstallation": true,
    "CheckOnStartup": true
  }
}
```

## Fehlerbehandlung

### Defender-Problem gelöst

**Altes Verhalten (v4.0):**
```
[✗] LibreHardwareMonitorLib.sys (2007, WinRing0)
    → Windows Defender blockiert
    → Nutzer muss Ausnahme manuell hinzufügen
```

**Neues Verhalten (v4.1):**
```
[✓] System-Installation verwendet (v0.9.5)
    → Aktuelle Signierung (GlobalSign)
    → Keine Defender-Probleme
    → WHQL-zertifiziert
```

### Fallback-Strategie

1. **Versuche System-Installation** → Kein Defender-Alarm
2. **Falls nicht gefunden** → Zeige Dialog mit Installationsoption
3. **Bei Ablehnung** → Nutze integrierte Lib + zeige Defender-Hinweis
4. **Nutzer informieren** → Defender-Ausnahme erforderlich

## Installation von LibreHardwareMonitor

### Via Winget (empfohlen)

```powershell
# Automatisch (via DependencyChecker)
.\Tools\Test-DependencyChecker.ps1 -AutoInstall

# Manuell
winget install LibreHardwareMonitor.LibreHardwareMonitor
```

### Manuell (GitHub)

1. Download: https://github.com/LibreHardwareMonitor/LibreHardwareMonitor/releases/latest
2. Entpacken nach `C:\Program Files\LibreHardwareMonitor`
3. GUI neu starten → Erkennt automatisch System-Installation

## Debug & Testing

### Verbose-Output aktivieren

```powershell
$VerbosePreference = 'Continue'
.\Tools\Test-DependencyChecker.ps1 -FindOnly -Verbose
```

### Pfad-Priorität testen

```powershell
# Zeige alle gefundenen Pfade
Import-Module ".\Modules\Core\DependencyChecker.psm1" -Force

$allPaths = @(
    "${env:ProgramFiles}\LibreHardwareMonitor\LibreHardwareMonitorLib.dll",
    "${env:ProgramFiles(x86)}\LibreHardwareMonitor\LibreHardwareMonitorLib.dll",
    "$env:LOCALAPPDATA\Programs\LibreHardwareMonitor\LibreHardwareMonitorLib.dll"
)

foreach ($path in $allPaths) {
    Write-Host "$path → $(Test-Path $path)" -ForegroundColor Cyan
}
```

## Bekannte Einschränkungen

1. **Winget-Abhängigkeit**: Automatische Installation erfordert Winget (Windows 10 1809+)
2. **Admin-Rechte**: Kernel-Treiber benötigen Admin-Rechte (gilt für beide Versionen)
3. **Signatur-Prüfung**: Nur digitale Signatur wird geprüft, keine WHQL-Validierung

## Roadmap

- [ ] Settings.json-Integration für Autocheck-Konfiguration
- [ ] Cache für gefundene Pfade (reduziert Startup-Zeit)
- [ ] PowerShell Gallery als alternative Installationsquelle
- [ ] Automatisches Update-Check für System-Installation
- [ ] Multi-Version-Unterstützung (v0.9.x)

---

**Version:** 1.0  
**Autor:** Bockis  
**Datum:** 2026-01-13

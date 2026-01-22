# Zwei-Phasen-Start der Bockis System-Tool GUI

## 🎯 Konzept

Die GUI verwendet einen **intelligenten Zwei-Phasen-Start**, um Windows Defender-Probleme zu vermeiden und eine saubere Installation zu gewährleisten.

---

## 🔄 Ablauf

### **Phase 1: Erstinitialisierung** (Erster Start)

```
┌─────────────────────────────────────────────────────────┐
│  BOCKIS SYSTEM-TOOL - ERSTE INITIALISIERUNG             │
└─────────────────────────────────────────────────────────┘

[🔍] Schritt 1: Prüfe System-Abhängigkeiten...
    ├─ Suche LibreHardwareMonitor
    ├─ Nicht gefunden? → Benutzer-Dialog
    └─ Installation via WinGet (falls gewünscht)

[🔧] Schritt 2: Registriere Hardware-Monitor-Treiber...
    ├─ Starte LibreHardwareMonitor.exe (kurz)
    ├─ PawnIO-Treiber wird installiert
    └─ Antivirus-Warnung möglich (erwartet!)

[✓] Initialisierung abgeschlossen!
    ├─ Marker-Datei erstellt: Data/system_initialized.flag
    └─ GUI fordert Neustart an
```

### **Phase 2: Normaler Betrieb** (Alle weiteren Starts)

```
┌─────────────────────────────────────────────────────────┐
│  Initialisierungs-Marker gefunden? ✓                    │
└─────────────────────────────────────────────────────────┘

[🔧] Initialisiere Hardware-Monitoring...
    ├─ Lade LibreHardwareMonitorLib.dll
    ├─ Nutze installierten PawnIO-Treiber
    └─ Hardware-Timer startet

[✓] GUI vollständig geladen
```

---

## 📝 Marker-Datei

**Pfad:** `C:\Program Files\Bockis-Win_Gui\Data\system_initialized.flag`

**Inhalt:**
```json
{
  "InitializedAt": "2026-01-21 17:48:00",
  "LibreHardwareMonitorPath": "C:\\Users\\...\\LibreHardwareMonitorLib.dll",
  "Version": "0.9.3"
}
```

**Zweck:**
- ✅ Markiert abgeschlossene Initialisierung
- ✅ Speichert Pfad zur LibreHardwareMonitor-Installation
- ✅ Verhindert wiederholte Initialisierung

---

## 🛡️ Windows Defender & Antivirus

### **Problem:**
LibreHardwareMonitor benötigt den **PawnIO-Kernel-Treiber** für Hardware-Zugriff. 
Dieser Treiber löst oft Antivirus-Warnungen aus (False Positive).

### **Lösung durch Zwei-Phasen-Start:**

| Phase | Treiber-Status | Defender-Verhalten |
|-------|----------------|-------------------|
| **Phase 1 (Erstinitialisierung)** | Wird installiert | ⚠️ Warnung möglich (erwartet) |
| **Phase 2 (Normalbetrieb)** | Bereits installiert | ✅ Keine Warnung mehr |

**Wichtig:**
- Der Benutzer wird **vor** der Treiber-Installation **gefragt**
- Klare Information über Antivirus-Warnungen
- Kein automatischer Hintergrund-Prozess beim GUI-Start

---

## 🔧 Technische Details

### **Initialisierungs-Check (Win_Gui_Module.ps1)**

```powershell
# Prüfe Marker-Datei
$initMarkerPath = Join-Path $PSScriptRoot "Data\system_initialized.flag"
$needsInitialization = -not (Test-Path $initMarkerPath)

if ($needsInitialization) {
    # PHASE 1: Erstinitialisierung
    # - Dependency Check
    # - LibreHardwareMonitor Installation
    # - PawnIO-Treiber Registrierung
    # - Marker-Datei erstellen
    # - Neustart anfordern
}
else {
    # PHASE 2: Normaler Betrieb
    # - Hardware-Monitoring starten
    # - GUI vollständig laden
}
```

### **DependencyChecker Integration**

```powershell
# Import DependencyChecker
if (-not (Get-Command -Name 'Test-LibreHardwareMonitorAvailability' -ErrorAction SilentlyContinue)) {
    Import-Module "$PSScriptRoot\Modules\Core\DependencyChecker.psm1" -Force
}

# Prüfe LibreHardwareMonitor
$lhmStatus = Find-LibreHardwareMonitor

if (-not $lhmStatus.Found) {
    # Benutzer-Dialog → Installation via WinGet
}
```

### **PawnIO-Treiber Registrierung**

```powershell
# Starte LibreHardwareMonitor.exe kurz
$exePath = Join-Path $dllDir "LibreHardwareMonitor.exe"
$proc = Start-Process -FilePath $exePath -WindowStyle Minimized -PassThru
Start-Sleep -Seconds 3

# Prozess beenden (Treiber bleibt registriert)
if (-not $proc.HasExited) {
    $proc | Stop-Process -Force
}
```

### **HardwareMonitorTools.psm1 Änderungen**

**Vorher:**
```powershell
# ❌ Automatische Treiber-Aktivierung beim .Open()
$script:computerObj.Open()

# ❌ Falls Treiber fehlt: .exe automatisch starten
if ($tempSensors.Count -eq 0) {
    Start-Process "LibreHardwareMonitor.exe" ...
}
```

**Jetzt:**
```powershell
# ✅ Nutzt bereits registrierten Treiber
$script:computerObj.Open()

# ✅ Falls Treiber fehlt: Hinweis auf Erstinitialisierung
if ($tempSensors.Count -eq 0) {
    Write-Host "💡 Tipp: Führen Sie bitte einmal die Erstinitialisierung durch"
    # Fallback zu Performance Counters
}
```

---

## 🧪 Testszenarien

### **Szenario 1: Komplett neuer Benutzer**

1. ✅ GUI startet zum ersten Mal
2. ✅ Keine `system_initialized.flag` vorhanden
3. ✅ **Phase 1** wird ausgeführt
4. ✅ Benutzer wird nach LibreHardwareMonitor-Installation gefragt
5. ✅ WinGet installiert LibreHardwareMonitor
6. ✅ .exe startet kurz → PawnIO-Treiber wird registriert
7. ⚠️ Windows Defender **könnte** Warnung zeigen (erwartet!)
8. ✅ Marker-Datei wird erstellt
9. ✅ Benutzer wird zum Neustart aufgefordert
10. ✅ Zweiter Start: **Phase 2**, Hardware-Monitoring funktioniert

### **Szenario 2: Bereits initialisiertes System**

1. ✅ GUI startet
2. ✅ `system_initialized.flag` vorhanden
3. ✅ **Phase 2** wird ausgeführt
4. ✅ Hardware-Monitoring startet sofort
5. ✅ **Keine** Defender-Warnungen

### **Szenario 3: Benutzer lehnt Installation ab**

1. ✅ GUI startet zum ersten Mal
2. ✅ Benutzer wählt "Nein" bei LibreHardwareMonitor-Installation
3. ✅ Marker-Datei wird trotzdem erstellt
4. ✅ GUI nutzt **Fallback-Sensoren** (Performance Counter, WMI)
5. ⚠️ Eingeschränkte Funktionalität (keine Temperaturen)

---

## 📊 Vorteile

| Vorteil | Beschreibung |
|---------|--------------|
| **🛡️ Defender-freundlich** | Treiber wird nur EINMAL beim ersten Start installiert |
| **📢 Transparenz** | Benutzer wird klar informiert über Treiber-Installation |
| **✅ Sauber** | Keine versteckten Hintergrund-Prozesse |
| **🔄 Wiederholbar** | Marker-Datei löschen → Re-Initialisierung |
| **💡 Fallback** | Funktioniert auch ohne LibreHardwareMonitor |
| **🚀 Schneller zweiter Start** | Keine Überprüfungen mehr nötig |

---

## 🔄 Re-Initialisierung erzwingen

Falls die Initialisierung erneut durchgeführt werden soll:

```powershell
# Lösche Marker-Datei
Remove-Item "C:\Program Files\Bockis-Win_Gui\Data\system_initialized.flag"

# Starte GUI neu → Phase 1 wird erneut ausgeführt
```

---

## 🐛 Troubleshooting

### **Problem: Defender blockiert PawnIO-Treiber**

**Lösung:**
1. Windows Defender öffnen
2. Schutzeinstellungen → Viren- & Bedrohungsschutz
3. "Ausnahmen" → "Ausnahme hinzufügen"
4. Pfad: `C:\Program Files\LibreHardwareMonitor\*`
5. GUI neu starten

### **Problem: Hardware-Monitoring funktioniert nicht**

**Diagnose:**
```powershell
# Prüfe ob Marker vorhanden
Test-Path "C:\Program Files\Bockis-Win_Gui\Data\system_initialized.flag"

# Prüfe ob LibreHardwareMonitor installiert
winget list LibreHardwareMonitor

# Prüfe DLL
Test-Path "C:\Users\...\LibreHardwareMonitorLib.dll"
```

**Lösung:**
- Marker-Datei löschen → Re-Initialisierung
- LibreHardwareMonitor manuell installieren
- Tool als Administrator starten

### **Problem: GUI startet nach Initialisierung nicht mehr**

**Ursache:** Marker-Datei beschädigt oder Pfad falsch

**Lösung:**
```powershell
# Marker-Datei neu erstellen
$markerPath = "C:\Program Files\Bockis-Win_Gui\Data\system_initialized.flag"
@{
    InitializedAt = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    LibreHardwareMonitorPath = "C:\...\LibreHardwareMonitorLib.dll"
    Version = "0.9.3"
} | ConvertTo-Json | Set-Content -Path $markerPath
```

---

## 📝 Changelog

### Version 4.1.1+
- ✅ Zwei-Phasen-Start implementiert
- ✅ Automatische .exe-Ausführung entfernt
- ✅ DependencyChecker in Phase 1 integriert
- ✅ PawnIO-Kommentare aktualisiert
- ✅ Windows Defender-freundlich

---

**Autor:** Bockis  
**Datum:** 21. Januar 2026  
**Version:** 4.1.1+

# Hardware-Monitoring-Module

## Übersicht
Dieses Modul bietet Hardware-Monitoring-Funktionen für die Bockis-Win_GUI-Anwendung. Es ermöglicht die Überwachung von CPU, GPU und RAM-Metriken mit verschiedenen Fallback-Mechanismen für maximale Kompatibilität auf unterschiedlichen PC-Systemen.

## Hauptfunktionen
- CPU-Überwachung: Temperatur, Last, Taktrate, Leistungsaufnahme
- GPU-Überwachung: Temperatur, Last, Taktrate, Speichernutzung
- RAM-Überwachung: Speicherauslastung, Temperatur (wenn verfügbar)
- Statistik-Tracking: Min/Max/Durchschnittswerte für alle Metriken
- Robuste Fallback-Mechanismen: Wenn primäre Sensoren nicht verfügbar sind

## Monitoring-Methoden
Das Modul verwendet mehrere Monitoring-Methoden in der folgenden Priorität:

1. **LibreHardwareMonitor**: Primäre Methode für detaillierte Hardware-Überwachung
2. **Windows Performance Counter**: Fallback für grundlegende Metriken
3. **WMI/CIM**: Alternative Fallback-Methode
4. **SMBus**: Spezifisch für RAM-Temperaturen

## Fehlerbehebung

### CPU-Monitoring funktioniert nicht
- Überprüfen Sie, ob die LibreHardwareMonitorLib.dll im Lib-Verzeichnis vorhanden ist
- Prüfen Sie, ob Administratorrechte für den Zugriff auf Hardware-Sensoren vorhanden sind
- Aktivieren Sie den Debug-Modus mit `Set-HardwareDebugMode -Component 'CPU' -Enabled $true`

### GPU-Monitoring funktioniert nicht
- Für NVIDIA-GPUs: Überprüfen Sie, ob aktuelle Treiber installiert sind
- Für AMD-GPUs: Spezielle Treiber könnten erforderlich sein
- Überprüfen Sie, ob die GPU vom System erkannt wird
- Aktivieren Sie den Debug-Modus mit `Set-HardwareDebugMode -Component 'GPU' -Enabled $true`

### RAM-Monitoring funktioniert nicht
- Für RAM-Temperaturen: Nicht alle RAM-Module unterstützen Temperaturmessung
- DDR5-RAM bietet bessere Temperaturüberwachung
- Aktivieren Sie den Debug-Modus mit `Set-HardwareDebugMode -Component 'RAM' -Enabled $true`

## Debug-Modus aktivieren

### NEU: Separates Debug-Fenster 🆕
Debug-Ausgaben können jetzt in einem separaten CMD-Fenster mit konfigurierbarer Größe angezeigt werden!

```powershell
# Gesamten Debug-Modus aktivieren mit separatem Fenster (100x40)
Set-HardwareMonitorDebugMode -Enabled $true -WindowWidth 100 -WindowHeight 40

# Oder nur für bestimmte Komponenten
Set-HardwareDebugMode -Component 'CPU' -Enabled $true -WindowWidth 100 -WindowHeight 40
Set-HardwareDebugMode -Component 'GPU' -Enabled $true
Set-HardwareDebugMode -Component 'RAM' -Enabled $true

# Debug-Fenster manuell öffnen
Open-DebugWindow -Width 120 -Height 50

# Debug-Fenster manuell schließen
Close-DebugWindow
```

**Vorteile des Debug-Fensters:**
- ✅ Übersichtliche Trennung von Haupt- und Debug-Ausgaben
- ✅ Konfigurierbare Fenstergröße
- ✅ Echtzeit-Aktualisierung
- ✅ Automatisches Öffnen/Schließen mit Debug-Modi
- ✅ Timestamps für alle Einträge

📖 Weitere Informationen: 
- [Debug-Fenster Anleitung](./DEBUG-WINDOW-USAGE.md)
- [Einheitliches Format-Spezifikation](./DEBUG-OUTPUT-FORMAT.md)

**Beispiel - So sieht das Debug-Fenster aus:**
```
┌─────────────────────────────────────────────────────────────────┐
│ === Hardware Monitor Debug-Ausgaben ===                         │
│ === Gestartet: 2025-11-13 14:30:00 ===                         │
│                                                                  │
│ [14:30:05] [CPU] === Hardware Information ===                   │
│ [14:30:05] [CPU] Name: Intel Core i7-9700K                      │
│ [14:30:05] [CPU] Kerne: 8                                       │
│                                                                  │
│ [14:30:10] [CPU] T: 65.5°C | L: 45% | P: 85 W | C: 3.8 GHz     │
│ [14:30:11] [GPU] T: 72.0°C | L: 88% | P: 200 W | C: 1.9 GHz    │
│ [14:30:12] [RAM] T: 45°C | L: 50% | V: 16 GB | G: 32 GB        │
│ ...                                                              │
└─────────────────────────────────────────────────────────────────┘
```

**Einheitliches Format für alle Komponenten:**
- **T:** Temperatur in °C
- **L:** Last/Auslastung in %
- **P:** Leistung in W (CPU, GPU)
- **C:** Takt in GHz (CPU, GPU)
- **V:** Verwendet in GB (RAM)
- **G:** Gesamt in GB (RAM)

## Hardware-Information anzeigen
```powershell
# Hardware-Info für CPU anzeigen
Write-HardwareInfo -Component 'CPU'

# Hardware-Info für GPU anzeigen
Write-HardwareInfo -Component 'GPU'

# Hardware-Info für RAM anzeigen
Write-HardwareInfo -Component 'RAM'
```

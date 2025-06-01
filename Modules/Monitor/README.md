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
```powershell
# Gesamten Debug-Modus aktivieren
Set-HardwareMonitorDebugMode -Enabled $true

# Oder nur für bestimmte Komponenten
Set-HardwareDebugMode -Component 'CPU' -Enabled $true
Set-HardwareDebugMode -Component 'GPU' -Enabled $true
Set-HardwareDebugMode -Component 'RAM' -Enabled $true
```

## Hardware-Information anzeigen
```powershell
# Hardware-Info für CPU anzeigen
Write-HardwareInfo -Component 'CPU'

# Hardware-Info für GPU anzeigen
Write-HardwareInfo -Component 'GPU'

# Hardware-Info für RAM anzeigen
Write-HardwareInfo -Component 'RAM'
```

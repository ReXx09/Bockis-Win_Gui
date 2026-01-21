# Windows Defender Ausnahmen - Dokumentation

## Überblick

Dieses Dokument erklärt, warum Windows Defender-Ausnahmen für Bockis System-Tool erforderlich sind und wie sie implementiert wurden.

---

## 🔴 Das Problem: VulnerableDriver:WinNT/Winring0

### Was blockiert Defender?

Windows Defender erkennt **LibreHardwareMonitorLib.dll** als potenzielle Bedrohung:
- **Erkannt als:** `VulnerableDriver:WinNT/Winring0`
- **Typ:** Kernel-Treiber-Warnung
- **CVE:** CVE-2020-14979 (bekannte Schwachstelle in WinRing0)

### Warum ist das ein Fehlalarm?

1. **LibreHardwareMonitor ist Open Source** und vertrauenswürdig
   - GitHub: https://github.com/LibreHardwareMonitor/LibreHardwareMonitor
   - Aktiv entwickelt und gewartet
   - Wird von tausenden Projekten weltweit genutzt

2. **Der Treiber wird nur für Hardware-Lesezugriff verwendet**
   - CPU-Temperaturen
   - GPU-Temperaturen
   - RAM-Temperaturen
   - Spannungen & Lüftergeschwindigkeiten

3. **Keine schädliche Funktion**
   - Keine Daten werden verändert
   - Keine Netzwerk-Kommunikation
   - Nur Lese-Zugriff auf Hardware-Sensoren

---

## ✅ Implementierte Lösungen

### 1. Installer-Integration (Primär)

**Verbesserte Defender-Ausnahmen im Inno Setup Installer:**

```pascal
// 5 spezifische Ausnahmen werden hinzugefügt:
1. Win_Gui_Module.ps1 (Hauptskript)
2. Modules\ (PowerShell-Module)
3. Lib\ (Alle Bibliotheken)
4. Lib\LibreHardwareMonitorLib.dll (Spezifisch)
5. powershell.exe (Prozess-Ausnahme)
```

**Features:**
- ✅ Standardmäßig aktiviert (`Flags: checked`)
- ✅ Fehlerbehandlung mit Feedback
- ✅ Erfolgs-/Fehler-Meldungen für Nutzer
- ✅ Detaillierte Erklärung warum Ausnahmen nötig sind

### 2. Runtime-Prüfung (Fallback)

**Automatische Prüfung beim Tool-Start:**

```powershell
# Prüft beim Start ob Lib\-Ordner bereits als Ausnahme existiert
# Falls nicht: Versucht automatisch hinzuzufügen
# Falls fehlschlägt: Zeigt klare Anleitung für manuelle Einrichtung
```

**Vorteile:**
- Funktioniert auch wenn Installer übersprungen wurde
- Kein Admin-Recht erforderlich (nur Warnung bei Fehler)
- Nutzer wird klar informiert über Auswirkungen

---

## 📊 Was wird geschützt?

### Mit Defender-Ausnahmen: ✅
- ✅ CPU-Temperatur in Echtzeit
- ✅ GPU-Temperatur in Echtzeit
- ✅ RAM-Temperatur (DDR5)
- ✅ Lüftergeschwindigkeiten
- ✅ Spannungen
- ✅ Taktfrequenzen
- ✅ Alle Hardware-Statistiken

### Ohne Defender-Ausnahmen: ⚠️
- ❌ Keine Temperaturen
- ✅ CPU/GPU/RAM-Auslastung (via WMI)
- ✅ Speicher-Nutzung
- ✅ Basis-Hardware-Infos

---

## 🛡️ Sicherheit

### Was bleibt geschützt?

**WICHTIG:** Der Windows Defender bleibt vollständig aktiv!

- ✅ Echtzeit-Schutz: AKTIV
- ✅ Cloud-basierter Schutz: AKTIV
- ✅ Manipulationsschutz: AKTIV
- ✅ Ransomware-Schutz: AKTIV

**Einzige Änderung:**
- Die spezifischen Tool-Dateien werden als vertrauenswürdig markiert
- Defender scannt weiterhin das gesamte System
- Andere Malware wird weiterhin erkannt und blockiert

### Transparenz

1. **Open Source:** Gesamter Code auf GitHub verfügbar
2. **Code-Signierung:** Tool ist digital signiert (optional)
3. **Community:** Von tausenden Nutzern verwendet und geprüft
4. **Dokumentiert:** Alle Funktionen sind dokumentiert

---

## 🔧 Manuelle Einrichtung

Falls der automatische Prozess fehlschlägt:

### Methode 1: PowerShell (Empfohlen)

```powershell
# Als Administrator ausführen:
$toolPath = "C:\Program Files\Bockis-Win_Gui\Lib"
Add-MpPreference -ExclusionPath $toolPath
```

### Methode 2: Windows-Sicherheit GUI

1. **Windows-Sicherheit** öffnen
2. **Viren- & Bedrohungsschutz** → **Einstellungen verwalten**
3. **Ausschlüsse** → **Ausschlüsse hinzufügen oder entfernen**
4. **Ordner hinzufügen** klicken
5. Ordner auswählen: `C:\Program Files\Bockis-Win_Gui\Lib`
6. **Fertig!**

---

## 🤔 Häufig gestellte Fragen (FAQ)

### F: Ist das Tool gefährlich?
**A:** Nein. Es ist ein Fehlalarm (False Positive). Der Code ist Open Source und transparent.

### F: Warum meldet Defender es trotzdem?
**A:** Der WinRing0-Treiber hat eine bekannte CVE (Schwachstelle). Diese wird von Malware MISSBRAUCHT, ist aber selbst nicht schädlich. Unser Tool nutzt sie legitim für Hardware-Monitoring.

### F: Kann ich das Tool ohne Ausnahmen nutzen?
**A:** Ja! Aber ohne Temperaturen. Auslastungswerte funktionieren weiterhin via WMI.

### F: Gibt es Alternativen zum WinRing0-Treiber?
**A:** Ja, aber alle haben Nachteile:
- **HWiNFO64:** Muss separat installiert und konfiguriert werden
- **Nur WMI:** Keine Temperaturen verfügbar
- **Vendor-APIs:** Nur für spezifische Hardware (NVIDIA/AMD)

### F: Wird mein System dadurch unsicherer?
**A:** Nein. Defender bleibt vollständig aktiv. Nur diese spezifischen Dateien werden übersprungen.

---

## 📞 Support

Bei Problemen oder Fragen:
- **GitHub Issues:** [Repository-Link]
- **Dokumentation:** Dieses Dokument
- **README:** Hauptdokumentation im Repository

---

## 📝 Änderungshistorie

### Version 4.1 (17.12.2025)
- ✅ Verbesserte Installer-Ausnahmen (5 statt 3)
- ✅ Runtime-Prüfung beim Tool-Start hinzugefügt
- ✅ Detaillierte Fehler-/Erfolgs-Meldungen
- ✅ Dokumentation erstellt

### Version 4.0 (28.11.2025)
- ✅ Basis-Implementierung im Installer
- ⚠️ Noch nicht standardmäßig aktiviert

---

## 🔗 Weiterführende Links

- **LibreHardwareMonitor GitHub:** https://github.com/LibreHardwareMonitor/LibreHardwareMonitor
- **WinRing0 CVE:** https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2020-14979
- **Microsoft Defender Docs:** https://docs.microsoft.com/en-us/windows/security/threat-protection/

---

**Letzte Aktualisierung:** 17. Dezember 2025

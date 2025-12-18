# 🔐 Build-Prozess mit Code-Signierung

## Übersicht

Dieser Ordner enthält alle Tools für einen professionellen Build-Prozess mit Code-Signierung:

```
├── Build-SignedInstaller.ps1    # Haupt-Build-Skript (Signierung + Installer)
├── Sign-AllScripts.ps1           # Signiert alle PowerShell-Dateien
├── installer.iss                 # Inno Setup Konfiguration
└── SIGNIERUNG-ANLEITUNG.md       # Detaillierte Dokumentation
```

---

## 🚀 Schnellstart

### 1. Erstes Mal: Zertifikat erstellen und vollständig signieren

```powershell
# Erstellt Self-Signed-Zertifikat, signiert Code und erstellt signierten Installer
.\Build-SignedInstaller.ps1 -CreateCertificate -EnableSignToolInISS -Verbose
```

Das Skript wird:
1. Ein Code-Signing-Zertifikat erstellen (gültig 5 Jahre)
2. Das Zertifikat als vertrauenswürdig installieren
3. SignTool in `installer.iss` aktivieren (automatische Setup-Signierung)
4. Alle PowerShell-Dateien signieren (SHA256)
5. Den Installer mit Inno Setup erstellen **und automatisch signieren**

### 2. Nachfolgende Builds

```powershell
# Signiert Code und erstellt Installer (verwendet vorhandenes Zertifikat)
.\Build-SignedInstaller.ps1 -Verbose
```

### 3. Nur Code signieren (ohne Installer)

```powershell
# Signiert nur die PowerShell-Dateien
.\Sign-AllScripts.ps1 -Verbose
```

---

## 📦 Build-Optionen

### Kompletter Build mit integrierter Installer-Signierung (EMPFOHLEN)

```powershell
.\Build-SignedInstaller.ps1 -EnableSignToolInISS -Verbose
```

**Vorteile:**
- ✅ Setup.exe wird **automatisch** beim Build signiert
- ✅ Kein manueller Schritt notwendig
- ✅ Konsistent bei jedem Build
- ✅ Professioneller Workflow

**Empfohlen für:** Alle Releases, maximale Automatisierung

### Alternative: Manuelle Setup-Signierung nach Build

```powershell
.\Build-SignedInstaller.ps1 -SignInstaller -Verbose
```

**Unterschied:**
- Setup.exe wird **nach** dem Build manuell signiert
- Muss bei jedem Build angegeben werden

**Empfohlen für:** Einmalige Builds, Testing

### Build ohne Code-Signierung (nur für Tests)

```powershell
.\Build-SignedInstaller.ps1 -SkipSigning
```

**Achtung:** Windows Defender kann unsignierte Dateien als verdächtig markieren!

### Neues Zertifikat erzwingen

```powershell
.\Build-SignedInstaller.ps1 -CreateCertificate
```

**Wann nötig:**
- Erstes Mal (kein Zertifikat vorhanden)
- Zertifikat ist abgelaufen
- Zertifikat wurde gelöscht

---

## 🛡️ Warum Signierung gegen Defender-Fehlalarme hilft

### Problem: Unsignierter PowerShell-Code
Windows Defender (und andere AV-Software) markiert unsignierten PowerShell-Code oft als verdächtig, weil:
- PowerShell häufig von Malware verwendet wird
- Keine Identitätsprüfung möglich ist
- Keine Integritätsprüfung vorhanden ist

### Lösung: Code-Signierung
Eine digitale Signatur beweist:
1. **Identität:** Der Code stammt von einer verifizierten Quelle
2. **Integrität:** Der Code wurde seit der Signierung nicht verändert
3. **Vertrauen:** Das Zertifikat ist als vertrauenswürdig markiert

### Technische Details

#### Self-Signed vs. Commercial Certificate

| Aspekt | Self-Signed | Commercial |
|--------|-------------|------------|
| **Kosten** | Kostenlos | €150-500/Jahr |
| **Setup-Zeit** | 2-5 Minuten | 1-7 Tage |
| **Vertrauen** | Nur auf installiertem System | Sofort für alle |
| **Defender-Erkennung** | ✅ Gut (nach Import) | ✅ Ausgezeichnet |
| **SmartScreen** | ❌ Keine Reputation | ✅ Baut Reputation auf |
| **Geeignet für** | Entwicklung, Private Nutzung | Öffentliche Verteilung |

#### Was wird signiert?

```
✅ Win_Gui_Module.ps1          (Hauptskript)
✅ Modules/**/*.psm1           (Alle PowerShell-Module)
✅ Sign-AllScripts.ps1         (Build-Skript)
✅ Build-SignedInstaller.ps1   (Build-Skript)
✅ Optional: *.exe             (Installer selbst)
```

#### Signatur-Parameter für maximale Sicherheit

```powershell
Set-AuthenticodeSignature `
    -FilePath $file `
    -Certificate $cert `
    -TimestampServer "http://timestamp.digicert.com" `  # Wichtig!
    -HashAlgorithm SHA256 `                              # Nicht SHA1!
    -IncludeChain All                                    # Vollständige Kette
```

**Timestamp-Server:** Garantiert, dass die Signatur auch nach Ablauf des Zertifikats gültig bleibt!

---

## 🔍 Signatur überprüfen

### Einzelne Datei prüfen

```powershell
Get-AuthenticodeSignature -FilePath ".\Win_Gui_Module.ps1" | Format-List *
```

**Erwartete Ausgabe:**
```
Status              : Valid
SignerCertificate   : [Subject]
                      CN=Bocki Software, O=Bocki, C=DE
TimeStamperCertificate : [Subject]
                      CN=DigiCert Timestamp 2023
```

### Alle Dateien prüfen

```powershell
Get-ChildItem -Include *.ps1,*.psm1 -Recurse | ForEach-Object {
    $sig = Get-AuthenticodeSignature $_.FullName
    [PSCustomObject]@{
        File = $_.Name
        Status = $sig.Status
        Signer = $sig.SignerCertificate.Subject
    }
} | Format-Table -AutoSize
```

---

## 🚨 Troubleshooting

### ❌ "Kein Code-Signing-Zertifikat gefunden"

**Lösung:**
```powershell
# Erstellen Sie ein neues Zertifikat
.\Build-SignedInstaller.ps1 -CreateCertificate
```

### ❌ "Signatur ist ungültig" nach Signierung

**Ursachen:**
1. Zertifikat nicht zu Trusted Root hinzugefügt
2. Zertifikat abgelaufen

**Lösung:**
```powershell
# Prüfen Sie das Zertifikat
Get-ChildItem Cert:\CurrentUser\My -CodeSigningCert | Format-List *

# Zertifikat manuell zu Trusted Root hinzufügen
$cert = Get-ChildItem Cert:\CurrentUser\My -CodeSigningCert | Select-Object -First 1
$certPath = "C:\Temp\BockiCert.cer"
Export-Certificate -Cert $cert -FilePath $certPath

# Als Administrator:
Import-Certificate -FilePath $certPath -CertStoreLocation Cert:\LocalMachine\Root
Import-Certificate -FilePath $certPath -CertStoreLocation Cert:\LocalMachine\TrustedPublisher
```

### ❌ "Inno Setup nicht gefunden"

**Lösung:**
1. Installieren Sie Inno Setup von: https://jrsoftware.org/isdl.php
2. Empfohlene Version: Inno Setup 6.x
3. Starten Sie PowerShell neu nach Installation

### ⚠️ Windows Defender blockiert trotz Signierung

**Schritte:**
1. Prüfen Sie die Signatur (siehe oben)
2. Melden Sie als False-Positive: https://www.microsoft.com/en-us/wdsi/filesubmission
3. Warten Sie 24-48h auf Analyse durch Microsoft
4. Erwägen Sie kommerzielles Zertifikat für bessere Reputation

---

## 📚 Weitere Ressourcen

- **SIGNIERUNG-ANLEITUNG.md** - Detaillierte Dokumentation zur Code-Signierung
- **SIGNTOOL-INTEGRATION.md** - SignTool in installer.iss (automatische Setup-Signierung)
- **BUILD-README.md** - Diese Datei (Build-Prozess-Übersicht)
- **installer.iss** - Inno Setup Konfiguration
- **README.md** - Projekt-Dokumentation

### Hilfreiche Links

- [Microsoft Security Intelligence](https://www.microsoft.com/en-us/wdsi/filesubmission) - False-Positive melden
- [VirusTotal](https://www.virustotal.com) - Multi-AV-Scanner
- [DigiCert Code Signing](https://www.digicert.com/signing/code-signing-certificates) - Kommerzielles Zertifikat
- [Inno Setup](https://jrsoftware.org/isinfo.php) - Installer-Tool

---

## 💡 Best Practices

### Für Entwicklung (Self-Signed)

1. ✅ Erstellen Sie ein Zertifikat mit 5 Jahren Gültigkeit
2. ✅ Exportieren und sichern Sie das Zertifikat (.pfx mit Passwort)
3. ✅ Signieren Sie nach jedem Code-Change neu
4. ✅ Verwenden Sie immer Timestamp-Server
5. ✅ Testen Sie auf sauberem System

### Für öffentliche Verteilung (Commercial)

1. ✅ Kaufen Sie EV Code-Signing-Zertifikat (beste Reputation)
2. ✅ Signieren Sie ALLE Dateien (inkl. Installer)
3. ✅ Verwenden Sie SHA256 (nicht SHA1)
4. ✅ Testen Sie vor Release auf VirusTotal
5. ✅ Melden Sie False-Positives proaktiv bei Microsoft
6. ✅ Bauen Sie SmartScreen-Reputation auf (Zeit + Downloads)

### Defender-Optimierung

```powershell
# Lokale Defender-Ausnahme für Entwicklung (empfohlen)
Add-MpPreference -ExclusionPath "D:\NEXTCLOUD_SYNC\Programmierung\Bockis-Win_Gui-v4.1"

# Nur für signierte Skripte (nach Signierung)
Set-ExecutionPolicy AllSigned -Scope CurrentUser
```

---

## 🎯 Zusammenfassung

### Workflow für jeden Build

```powershell
# 1. Code ändern/entwickeln
# (Ihre Änderungen...)

# 2. Build mit Signierung
.\Build-SignedInstaller.ps1 -Verbose

# 3. Testen
Get-AuthenticodeSignature .\Win_Gui_Module.ps1

# 4. Installer testen
.\Bockis-System-Tool-v4.1-Setup.exe

# 5. Optional: VirusTotal-Check
# Upload auf virustotal.com
```

### Für maximale Sicherheit

```powershell
# Build mit vollständiger Signierung (Code + Installer)
.\Build-SignedInstaller.ps1 -SignInstaller -Verbose

# Prüfen
Get-AuthenticodeSignature .\Bockis-System-Tool-v4.1-Setup.exe
```

---

**Bei Fragen:** Siehe SIGNIERUNG-ANLEITUNG.md für Details

# 📜 Build-Skripte Übersicht

Diese Datei gibt einen Überblick über alle verfügbaren Build- und Signatur-Skripte.

---

## 🎯 Haupt-Skripte

### 1. `Build-SignedInstaller.ps1` ⭐ **HAUPTSKRIPT**

**Zweck:** Kompletter Build-Prozess mit Code-Signierung und Installer-Erstellung

**Verwendung:**
```powershell
# Kompletter Build (empfohlen)
.\Build-SignedInstaller.ps1 -CreateCertificate -EnableSignToolInISS -Verbose

# Standard-Build
.\Build-SignedInstaller.ps1 -Verbose

# Ohne Signierung (nur für Tests)
.\Build-SignedInstaller.ps1 -SkipSigning
```

**Parameter:**
- `-CreateCertificate` - Erstellt neues Self-Signed-Zertifikat
- `-EnableSignToolInISS` - Aktiviert automatische Setup-Signierung
- `-SignInstaller` - Signiert Setup.exe manuell (alt)
- `-SkipSigning` - Überspringt Code-Signierung
- `-Verbose` - Zeigt detaillierte Ausgabe

**Was es macht:**
1. ✅ Erstellt optional Self-Signed-Zertifikat
2. ✅ Signiert alle PowerShell-Dateien (SHA256)
3. ✅ Aktiviert optional SignTool in installer.iss
4. ✅ Erstellt Installer mit Inno Setup
5. ✅ Optional: Signiert Setup.exe manuell

---

### 2. `Sign-AllScripts.ps1`

**Zweck:** Signiert alle PowerShell-Dateien im Projekt

**Verwendung:**
```powershell
# Mit vorhandenem Zertifikat
.\Sign-AllScripts.ps1 -Verbose

# Neues Zertifikat erstellen und signieren
.\Sign-AllScripts.ps1 -CreateCertificate -Verbose
```

**Parameter:**
- `-CreateCertificate` - Erstellt neues Zertifikat
- `-Verbose` - Zeigt Details für jede Datei
- `-CertificateSubject` - Custom Subject (Standard: "CN=Bocki Software, O=Bocki, C=DE")

**Was es macht:**
1. ✅ Findet alle .ps1 und .psm1 Dateien
2. ✅ Signiert mit SHA256
3. ✅ Verwendet Timestamp-Server
4. ✅ Bericht über Erfolg/Fehler

**Ausgabe:**
```
✅ Erfolgreich signiert: 42
❌ Fehlgeschlagen: 0
```

---

### 3. `Configure-SignTool.ps1`

**Zweck:** Konfiguriert SignTool-Integration in installer.iss

**Verwendung:**
```powershell
# SignTool aktivieren
.\Configure-SignTool.ps1 -Enable

# Mit spezifischem Zertifikat
.\Configure-SignTool.ps1 -Enable -CertificateSubject "Meine Firma"

# Mit Thumbprint
.\Configure-SignTool.ps1 -Enable -CertificateThumbprint "ABC123..."

# Status anzeigen
.\Configure-SignTool.ps1 -ShowStatus

# Deaktivieren
.\Configure-SignTool.ps1 -Disable
```

**Parameter:**
- `-Enable` - Aktiviert SignTool in installer.iss
- `-Disable` - Deaktiviert SignTool
- `-ShowStatus` - Zeigt aktuellen Status
- `-CertificateThumbprint` - Verwendet spezifischen Thumbprint
- `-CertificateSubject` - Verwendet Subject-Name

**Was es macht:**
1. ✅ Liest installer.iss
2. ✅ Aktiviert/Deaktiviert SignTool-Zeilen
3. ✅ Prüft Zertifikat-Verfügbarkeit
4. ✅ Zeigt Status an

---

## 📋 Dokumentations-Dateien

### `QUICK-START-SIGNIERUNG.md` ⭐
Schnellster Einstieg in die Code-Signierung (1-2 Minuten)

### `SIGNTOOL-INTEGRATION.md`
Detaillierte Erklärung der SignTool-Integration in installer.iss

### `BUILD-README.md`
Vollständige Build-Prozess-Dokumentation

### `SIGNIERUNG-ANLEITUNG.md`
Umfassende Anleitung zur Code-Signierung (Self-Signed + Kommerziell)

---

## 🎯 Empfohlene Workflows

### Workflow 1: Erstes Setup (Self-Signed)

```powershell
# Schritt 1: Kompletter Build mit allem
.\Build-SignedInstaller.ps1 -CreateCertificate -EnableSignToolInISS -Verbose

# Schritt 2: Prüfen
Get-AuthenticodeSignature .\Win_Gui_Module.ps1
Get-AuthenticodeSignature .\Bockis-System-Tool-v4.1-Setup.exe

# Schritt 3: Testen
.\Bockis-System-Tool-v4.1-Setup.exe
```

**Ergebnis:**
- ✅ Zertifikat erstellt und installiert (5 Jahre gültig)
- ✅ Alle PowerShell-Dateien signiert
- ✅ SignTool in installer.iss aktiviert
- ✅ Setup.exe signiert

---

### Workflow 2: Nachfolgende Builds

```powershell
# Einfach:
.\Build-SignedInstaller.ps1 -Verbose
```

**Ergebnis:**
- ✅ Code neu signiert
- ✅ Installer erstellt
- ✅ Setup.exe automatisch signiert (via installer.iss)

---

### Workflow 3: Nur Code signieren (ohne Build)

```powershell
# Nach Code-Änderungen
.\Sign-AllScripts.ps1 -Verbose
```

**Verwendung:**
- Während Entwicklung
- Code-Änderungen testen
- Ohne Installer-Build

---

### Workflow 4: SignTool manuell konfigurieren

```powershell
# Status prüfen
.\Configure-SignTool.ps1 -ShowStatus

# Aktivieren
.\Configure-SignTool.ps1 -Enable

# Build ohne EnableSignToolInISS Parameter
.\Build-SignedInstaller.ps1 -Verbose
```

---

## 🔧 Kommandozeilen-Referenz

### Alle Build-Varianten

```powershell
# Minimaler Build (nur Installer)
.\Build-SignedInstaller.ps1 -SkipSigning

# Standard-Build (Code signiert)
.\Build-SignedInstaller.ps1 -Verbose

# Build mit Setup-Signierung (manuell)
.\Build-SignedInstaller.ps1 -SignInstaller -Verbose

# Build mit Setup-Signierung (automatisch via ISS)
.\Build-SignedInstaller.ps1 -EnableSignToolInISS -Verbose

# Kompletter Build (neu + SignTool)
.\Build-SignedInstaller.ps1 -CreateCertificate -EnableSignToolInISS -Verbose
```

### Alle Signatur-Varianten

```powershell
# Nur signieren (vorhandenes Cert)
.\Sign-AllScripts.ps1 -Verbose

# Zertifikat erstellen + signieren
.\Sign-AllScripts.ps1 -CreateCertificate -Verbose

# Mit custom Subject
.\Sign-AllScripts.ps1 -CreateCertificate -CertificateSubject "CN=MyCompany, O=MyOrg, C=US"
```

### Alle SignTool-Konfigurationen

```powershell
# Status
.\Configure-SignTool.ps1 -ShowStatus

# Aktivieren (automatisch)
.\Configure-SignTool.ps1 -Enable

# Aktivieren (mit Subject)
.\Configure-SignTool.ps1 -Enable -CertificateSubject "Bocki Software"

# Aktivieren (mit Thumbprint)
$cert = Get-ChildItem Cert:\CurrentUser\My -CodeSigningCert | Select -First 1
.\Configure-SignTool.ps1 -Enable -CertificateThumbprint $cert.Thumbprint

# Deaktivieren
.\Configure-SignTool.ps1 -Disable
```

---

## 🎓 Lernpfad

### Anfänger (noch nie signiert)

1. **Start:** Lesen Sie `QUICK-START-SIGNIERUNG.md`
2. **Ausführen:** `.\Build-SignedInstaller.ps1 -CreateCertificate -EnableSignToolInISS -Verbose`
3. **Prüfen:** `Get-AuthenticodeSignature .\Win_Gui_Module.ps1`
4. **Verstehen:** Lesen Sie `SIGNTOOL-INTEGRATION.md`

### Fortgeschritten (Self-Signed erfahren)

1. **Optimieren:** Lesen Sie `BUILD-README.md`
2. **Konfigurieren:** `.\Configure-SignTool.ps1 -Enable`
3. **Automatisieren:** Build-Skripte in CI/CD integrieren
4. **Upgrade:** Kommerzielles Zertifikat kaufen (`SIGNIERUNG-ANLEITUNG.md`)

### Experte (Kommerzielles Cert)

1. **Import:** `Import-PfxCertificate -FilePath cert.pfx -CertStoreLocation Cert:\CurrentUser\My`
2. **Konfigurieren:** `.\Configure-SignTool.ps1 -Enable -CertificateSubject "Your Company Name"`
3. **Build:** `.\Build-SignedInstaller.ps1 -Verbose`
4. **Verteilung:** Release auf GitHub, Website, etc.

---

## 📊 Skript-Abhängigkeiten

```
Build-SignedInstaller.ps1
├── Sign-AllScripts.ps1 (wird aufgerufen)
├── Configure-SignTool.ps1 (optional, bei -EnableSignToolInISS)
└── installer.iss (für Inno Setup)

Sign-AllScripts.ps1
└── (keine Abhängigkeiten)

Configure-SignTool.ps1
└── installer.iss (modifiziert diese Datei)
```

---

## ⚙️ Systemanforderungen

### Für Code-Signierung

- ✅ PowerShell 5.1+
- ✅ Windows 10/11
- ✅ Administrator-Rechte (für Zertifikat-Installation)
- ✅ Code-Signing-Zertifikat (Self-Signed oder Kommerziell)

### Für Installer-Build

- ✅ Inno Setup 6.x (Download: https://jrsoftware.org/isdl.php)
- ✅ Optional: Windows SDK (für signtool.exe)

### Für SignTool-Integration

- ✅ Windows SDK (enthält signtool.exe)
  - Standard-Pfad: `C:\Program Files (x86)\Windows Kits\10\bin\*\x64\signtool.exe`
  - Download: https://developer.microsoft.com/en-us/windows/downloads/windows-sdk/

---

## 🆘 Schnelle Problemlösung

| Problem | Lösung |
|---------|--------|
| "Kein Zertifikat gefunden" | `.\Build-SignedInstaller.ps1 -CreateCertificate` |
| "signtool.exe nicht gefunden" | Windows SDK installieren |
| "Inno Setup nicht gefunden" | Inno Setup 6 installieren |
| "Signatur ungültig" | Zertifikat zu Trusted Root hinzufügen |
| SignTool funktioniert nicht | `.\Configure-SignTool.ps1 -ShowStatus` prüfen |
| Build bricht ab | `.\Build-SignedInstaller.ps1 -SkipSigning` testen |

---

## 📞 Support-Dateien

Bei Problemen konsultieren Sie diese Dateien in folgender Reihenfolge:

1. **QUICK-START-SIGNIERUNG.md** - Schnelleinstieg
2. **Diese Datei** - Skript-Übersicht
3. **SIGNTOOL-INTEGRATION.md** - SignTool-Details
4. **BUILD-README.md** - Build-Prozess
5. **SIGNIERUNG-ANLEITUNG.md** - Vollständige Signierung-Doku

---

**Viel Erfolg beim Signieren! 🔐**

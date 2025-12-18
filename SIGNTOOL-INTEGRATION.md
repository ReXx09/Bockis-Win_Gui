# 🔐 Code-Signierung in installer.iss

## Übersicht

Die `installer.iss` unterstützt jetzt **integrierte Code-Signierung** über Inno Setup's SignTool-Feature. Das bedeutet, dass der Setup.exe automatisch beim Kompilieren signiert wird.

### 📊 Workflow-Diagramm

```
┌─────────────────────────────────────────────────────────────────┐
│  Build-SignedInstaller.ps1 -EnableSignToolInISS                 │
└────────────────────┬────────────────────────────────────────────┘
                     │
        ┌────────────┼────────────┐
        ▼            ▼            ▼
   ┌─────────┐  ┌─────────┐  ┌──────────────┐
   │ Erstelle│  │Signiere │  │ Aktiviere    │
   │  Cert   │  │  Code   │  │  SignTool    │
   │ (opt.)  │  │ (*.ps1) │  │ in .iss      │
   └────┬────┘  └────┬────┘  └──────┬───────┘
        │            │               │
        └────────────┼───────────────┘
                     ▼
              ┌─────────────┐
              │ Inno Setup  │
              │ kompiliert  │
              │ installer   │
              └──────┬──────┘
                     │
                     ▼
              ┌─────────────┐
              │  SignTool   │◄──── Automatisch!
              │  signiert   │
              │  Setup.exe  │
              └──────┬──────┘
                     │
                     ▼
         ┌────────────────────────┐
         │ ✅ Signierter Installer│
         │    Setup.exe           │
         └────────────────────────┘
```

---

## 🚀 Verwendung

### Variante 1: Automatisch über Build-Skript (EMPFOHLEN)

```powershell
# Kompletter Build mit Setup-Signierung in installer.iss
.\Build-SignedInstaller.ps1 -CreateCertificate -EnableSignToolInISS -Verbose
```

Das aktiviert automatisch die SignTool-Konfiguration in der `installer.iss`.

### Variante 2: Manuell konfigurieren

```powershell
# 1. SignTool aktivieren
.\Configure-SignTool.ps1 -Enable

# 2. Installer bauen
.\Build-SignedInstaller.ps1 -Verbose
```

### Variante 3: Status prüfen

```powershell
# Aktuellen SignTool-Status anzeigen
.\Configure-SignTool.ps1 -ShowStatus
```

---

## 🔧 Wie es funktioniert

### In installer.iss

Die `installer.iss` enthält jetzt diese Zeilen (standardmäßig auskommentiert):

```iss
; SignTool=signtool sign /n $q{CertName}$q /fd SHA256 /tr http://timestamp.digicert.com /td SHA256 $f
; SignToolRunMinimized=yes
```

### Nach Aktivierung

```iss
SignTool=signtool sign /sha1 $qABC123...DEF$q /fd SHA256 /tr http://timestamp.digicert.com /td SHA256 $f
SignToolRunMinimized=yes
```

**Was passiert:**
1. Inno Setup kompiliert den Installer
2. Ruft automatisch `signtool.exe` auf
3. Signiert `Setup.exe` mit dem Zertifikat
4. Fügt Timestamp hinzu (wichtig!)

---

## 📝 SignTool-Parameter erklärt

| Parameter | Bedeutung |
|-----------|-----------|
| `/sha1 {Thumbprint}` | Identifiziert das Zertifikat über Thumbprint |
| `/n "Subject"` | Alternative: Identifiziert über Subject-Name |
| `/fd SHA256` | Verwendet SHA256 für die Datei-Hash (sicher) |
| `/tr http://...` | Timestamp-Server-URL (wichtig!) |
| `/td SHA256` | SHA256 für Timestamp-Digest |
| `$f` | Inno Setup Variable für die zu signierende Datei |

---

## 🎯 Vorteile der integrierten Signierung

### ✅ Vorteile

1. **Automatisch:** Setup.exe wird beim Build signiert
2. **Konsistent:** Immer das gleiche Zertifikat
3. **Kein Extra-Schritt:** Keine manuelle Signierung nach Build
4. **Timestamp inklusive:** Langzeitgültigkeit garantiert

### ⚠️ Anforderungen

1. **SignTool.exe muss installiert sein**
   - Kommt mit Windows SDK
   - Oder Visual Studio
   - Standard-Pfad: `C:\Program Files (x86)\Windows Kits\10\bin\*\x64\signtool.exe`

2. **Zertifikat im Zertifikatsspeicher**
   - Self-Signed: Mit `Sign-AllScripts.ps1 -CreateCertificate`
   - Kommerziell: Importiert via `Import-PfxCertificate`

---

## 🔄 Unterschied zu `-SignInstaller` Parameter

### `-EnableSignToolInISS` (Neu)
```powershell
.\Build-SignedInstaller.ps1 -EnableSignToolInISS
```
- ✅ Aktiviert SignTool in `installer.iss`
- ✅ **Inno Setup signiert automatisch** beim Kompilieren
- ✅ Nur einmal konfigurieren, dann immer aktiv
- ✅ Professioneller Workflow

### `-SignInstaller` (Alt)
```powershell
.\Build-SignedInstaller.ps1 -SignInstaller
```
- Signiert Setup.exe **nach** dem Build
- Manueller Schritt mit PowerShell
- Muss bei jedem Build angegeben werden

### ✨ EMPFEHLUNG: Beide kombinieren

```powershell
# Bester Workflow für maximale Sicherheit:
.\Build-SignedInstaller.ps1 -EnableSignToolInISS -Verbose
```

Das stellt sicher, dass **immer** alles signiert wird.

---

## 🛠️ Troubleshooting

### ❌ "signtool.exe nicht gefunden"

**Lösung:** Installieren Sie Windows SDK

```powershell
# Prüfen ob signtool vorhanden ist
where.exe signtool

# Falls nicht gefunden:
# Download: https://developer.microsoft.com/en-us/windows/downloads/windows-sdk/
```

### ❌ "Zertifikat nicht gefunden" während Build

**Lösung:** Aktivieren Sie mit richtigem Zertifikat

```powershell
# Zeige verfügbare Zertifikate
Get-ChildItem Cert:\CurrentUser\My -CodeSigningCert

# Aktiviere mit spezifischem Subject
.\Configure-SignTool.ps1 -Enable -CertificateSubject "Ihr Zertifikat-Name"
```

### ⚠️ Inno Setup bricht mit Fehler ab

**Lösung:** Deaktivieren Sie SignTool temporär

```powershell
.\Configure-SignTool.ps1 -Disable
```

Dann bauen Sie ohne Signierung:
```powershell
.\Build-SignedInstaller.ps1 -SkipSigning
```

---

## 📊 Vergleich: Verschiedene Signierungsmethoden

| Methode | Code-Signierung | Setup-Signierung | Komplexität |
|---------|-----------------|------------------|-------------|
| **Nur `-EnableSignToolInISS`** | ❌ Nein | ✅ Ja (automatisch) | Niedrig |
| **Nur `-SignInstaller`** | ❌ Nein | ✅ Ja (manuell) | Mittel |
| **Standard-Build** | ✅ Ja | ❌ Nein | Niedrig |
| **`-EnableSignToolInISS` + Standard** | ✅ Ja | ✅ Ja (automatisch) | **Optimal** ✨ |

### 🎯 Empfohlener Workflow

```powershell
# Einmalig: Zertifikat erstellen und SignTool aktivieren
.\Build-SignedInstaller.ps1 -CreateCertificate -EnableSignToolInISS -Verbose

# Danach: Nur noch Standard-Build
.\Build-SignedInstaller.ps1 -Verbose
```

**Ergebnis:**
- ✅ Alle PowerShell-Dateien signiert (SHA256)
- ✅ Setup.exe signiert (SHA256)
- ✅ Timestamp für Langzeitgültigkeit
- ✅ Maximaler Schutz gegen Defender-Fehlalarme

---

## 🔐 Sicherheitshinweise

1. **SHA256 verwenden:** Niemals SHA1 (veraltet, unsicher)
2. **Timestamp immer aktivieren:** Sonst ungültig nach Zertifikatsablauf
3. **Zertifikat sichern:** PFX-Export für Backup
4. **Privaten Schlüssel schützen:** Niemals ins Git committen

---

## 📚 Weitere Befehle

```powershell
# SignTool-Status anzeigen
.\Configure-SignTool.ps1 -ShowStatus

# SignTool aktivieren mit Subject
.\Configure-SignTool.ps1 -Enable -CertificateSubject "Meine Firma"

# SignTool aktivieren mit Thumbprint
.\Configure-SignTool.ps1 -Enable -CertificateThumbprint "ABC123..."

# SignTool deaktivieren
.\Configure-SignTool.ps1 -Disable
```

---

**Dokumentation:** Siehe auch `BUILD-README.md` und `SIGNIERUNG-ANLEITUNG.md`

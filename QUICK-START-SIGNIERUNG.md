# ⚡ Quick Start - Code-Signierung

## Schnellster Weg zum signierten Installer

```powershell
# In einem Schritt: Zertifikat erstellen, Code signieren, Installer bauen
cd "D:\NEXTCLOUD_SYNC\Programmierung\Bockis-Win_Gui-v4.1\Win_Gui_Projekt"
.\Build-SignedInstaller.ps1 -CreateCertificate -EnableSignToolInISS -Verbose
```

✅ **Das wars!** Euer Installer ist jetzt vollständig signiert.

---

## Was wurde gemacht?

1. ✅ **Self-Signed-Zertifikat erstellt** (gültig 5 Jahre)
2. ✅ **Zertifikat als vertrauenswürdig installiert**
3. ✅ **Alle PowerShell-Dateien signiert** (SHA256)
4. ✅ **SignTool in installer.iss aktiviert**
5. ✅ **Setup.exe automatisch signiert**

---

## Für nachfolgende Builds

```powershell
# Einfach nur noch:
.\Build-SignedInstaller.ps1 -Verbose
```

**Grund:** Das Zertifikat und SignTool sind bereits konfiguriert.

---

## Signatur prüfen

```powershell
# PowerShell-Dateien prüfen
Get-AuthenticodeSignature .\Win_Gui_Module.ps1

# Setup.exe prüfen
Get-AuthenticodeSignature .\Bockis-System-Tool-v4.1-Setup.exe
```

**Erwartetes Ergebnis:**
```
Status: Valid
SignerCertificate: CN=Bocki Software, O=Bocki, C=DE
```

---

## SignTool-Status prüfen

```powershell
# Zeigt ob SignTool in installer.iss aktiv ist
.\Configure-SignTool.ps1 -ShowStatus
```

---

## Defender-Test

1. **Deaktivieren Sie temporär alle Defender-Ausnahmen**
2. **Starten Sie den signierten Installer**
3. **Ergebnis:** Weniger/keine Warnungen im Vergleich zu unsignierten Dateien

---

## Für öffentliche Verteilung

### Option A: Self-Signed (Kostenlos)

✅ Gut für private/interne Nutzung  
⚠️ Benutzer müssen Zertifikat einmalig als vertrauenswürdig importieren

### Option B: Kommerzielles Zertifikat (€150-500/Jahr)

✅ Sofort vertrauenswürdig für alle Benutzer  
✅ Keine Warnungen bei Installation  
✅ Beste SmartScreen-Reputation

**Empfohlene Anbieter:**
- DigiCert (€200-300/Jahr)
- Sectigo (€150-250/Jahr)
- SSL.com (€180-280/Jahr)

---

## Bei Problemen

### "signtool.exe nicht gefunden"

```powershell
# Windows SDK installieren:
# https://developer.microsoft.com/en-us/windows/downloads/windows-sdk/
```

### "Zertifikat nicht gefunden"

```powershell
# Zeige alle Code-Signing-Zertifikate
Get-ChildItem Cert:\CurrentUser\My -CodeSigningCert

# Erstelle neues Zertifikat
.\Build-SignedInstaller.ps1 -CreateCertificate
```

### Windows Defender blockiert trotzdem

1. **Warten Sie 24-48h** (SmartScreen-Reputation baut sich auf)
2. **Melden Sie als False-Positive:** https://www.microsoft.com/en-us/wdsi/filesubmission
3. **Erwägen Sie EV-Zertifikat** (sofortige Reputation)

---

## Detaillierte Dokumentation

📖 **SIGNTOOL-INTEGRATION.md** - Alles über SignTool in installer.iss  
📖 **BUILD-README.md** - Vollständiger Build-Prozess  
📖 **SIGNIERUNG-ANLEITUNG.md** - Detaillierte Signierung-Anleitung  

---

**Viel Erfolg! 🚀**

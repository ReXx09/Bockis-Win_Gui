# Code-Signierung für Win_Gui_Module

## 🎯 Warum Code-Signierung?

Code-Signierung ist **essentiell**, um False-Positive-Erkennungen durch Windows Defender und andere Antivirenprogramme zu vermeiden. Eine digitale Signatur:

✅ Beweist die Authentizität des Codes (von vertrauenswürdiger Quelle)  
✅ Garantiert Integrität (Code wurde nicht manipuliert)  
✅ Reduziert Defender-Warnungen drastisch  
✅ Ermöglicht SmartScreen-Reputation (weniger Warnungen über Zeit)  
✅ Professioneller Auftritt für Endbenutzer  

---

## 🚀 Schnellstart (Empfohlen)

### Option A: Automatischer Build mit Signierung

```powershell
# Erstellt Zertifikat, signiert alle Dateien und erstellt Installer
.\Build-SignedInstaller.ps1 -CreateCertificate -Verbose

# Nur Build ohne neue Zertifikat-Erstellung
.\Build-SignedInstaller.ps1 -Verbose

# Build mit Installer-Signierung (empfohlen für Verteilung)
.\Build-SignedInstaller.ps1 -SignInstaller -Verbose
```

### Option B: Nur Code signieren (ohne Installer-Build)

```powershell
# Erstellt Zertifikat und signiert alle PowerShell-Dateien
.\Sign-AllScripts.ps1 -CreateCertificate -Verbose

# Signiert mit vorhandenem Zertifikat
.\Sign-AllScripts.ps1 -Verbose
```

---

## 📋 Übersicht der Signierungsmethoden

### Option 1: Self-Signed Certificate (Kostenlos)
✅ **Gut für:** Entwicklung, interne Nutzung, Testing, Private Verteilung  
❌ **Einschränkung:** Benutzer müssen Zertifikat einmalig als vertrauenswürdig importieren  
💰 **Kosten:** Kostenlos  
⏱️ **Setup-Zeit:** 2-5 Minuten  

**Best Practice für Self-Signed:**
- Verwenden Sie SHA256 Hash-Algorithmus
- Fügen Sie Timestamp hinzu (wichtig!)
- Signieren Sie ALLE .ps1, .psm1 und .exe Dateien
- Exportieren Sie das Zertifikat für Verteilung

### Option 2: Standard Code-Signing Certificate
✅ **Gut für:** Öffentliche Verteilung, professionelle Software  
✅ **Vorteil:** Sofort vertrauenswürdig für alle Windows-Benutzer  
💰 **Kosten:** €150-300/Jahr  
⏱️ **Setup-Zeit:** 1-3 Tage (Identitätsprüfung)  

**Anbieter:** DigiCert, Sectigo, GlobalSign, SSL.com

### Option 3: EV Code-Signing Certificate (Extended Validation)
✅ **Gut für:** Kommerzielle Software, maximales Vertrauen  
✅ **Vorteil:** Höchste Vertrauensstufe, sofortige SmartScreen-Reputation  
💰 **Kosten:** €300-500/Jahr  
⏱️ **Setup-Zeit:** 3-7 Tage (umfangreiche Identitätsprüfung)  
🔑 **Hardware:** Benötigt USB-Token (wird mitgeliefert)

**Empfohlen für:** Software mit >1000 Downloads/Monat

---

## 🔧 Detaillierte Anleitungen

### Methode 1: Self-Signed Certificate mit SHA256

### Schritt 1: Zertifikat erstellen

```powershell
# Zertifikat im lokalen Zertifikatsspeicher erstellen
$cert = New-SelfSignedCertificate `
    -Subject "CN=Bocki Software, O=Bocki, C=DE" `
    -Type CodeSigning `
    -CertStoreLocation Cert:\CurrentUser\My `
    -NotAfter (Get-Date).AddYears(5) `
    -KeyExportPolicy Exportable `
    -KeySpec Signature `
    -KeyLength 2048 `
    -KeyAlgorithm RSA `
    -HashAlgorithm SHA256

Write-Host "Zertifikat erstellt: $($cert.Thumbprint)"
```

### Schritt 2: Zertifikat zu Trusted Root hinzufügen

```powershell
# Zertifikat exportieren
$certPath = "C:\Temp\BockiCodeSigning.cer"
Export-Certificate -Cert $cert -FilePath $certPath

# Zertifikat zu Trusted Root hinzufügen (erfordert Admin-Rechte)
Import-Certificate -FilePath $certPath -CertStoreLocation Cert:\LocalMachine\Root
Import-Certificate -FilePath $certPath -CertStoreLocation Cert:\LocalMachine\TrustedPublisher
```

### Schritt 3: Einzelne Datei signieren (mit SHA256)

```powershell
# Zertifikat abrufen
$cert = Get-ChildItem Cert:\CurrentUser\My -CodeSigningCert | Select-Object -First 1

# Datei mit SHA256 signieren (empfohlen für Defender)
Set-AuthenticodeSignature `
    -FilePath ".\Win_Gui_Module.ps1" `
    -Certificate $cert `
    -TimestampServer "http://timestamp.digicert.com" `
    -HashAlgorithm SHA256 `
    -IncludeChain All
```

**Wichtig:** SHA256 ist sicherer als SHA1 und wird von Windows Defender bevorzugt erkannt!

### Schritt 4: Alle PowerShell-Dateien signieren (EMPFOHLEN)

```powershell
# Verwenden Sie das fertige Skript
.\Sign-AllScripts.ps1 -Verbose

# Oder manuell:
$cert = Get-ChildItem Cert:\CurrentUser\My -CodeSigningCert | Select-Object -First 1
$files = Get-ChildItem -Path "." -Include *.ps1,*.psm1 -Recurse

foreach ($file in $files) {
    Write-Host "Signiere: $($file.Name)"
    Set-AuthenticodeSignature `
        -FilePath $file.FullName `
        -Certificate $cert `
        -TimestampServer "http://timestamp.digicert.com" `
        -HashAlgorithm SHA256 `
        -IncludeChain All
}

Write-Host "✅ Alle Dateien signiert!"
```

---

## Methode 2: Kommerzielles Zertifikat

### Schritt 1: Zertifikat kaufen
1. Wählen Sie einen Anbieter (z.B. DigiCert, Sectigo)
2. Kaufen Sie ein "Code Signing Certificate"
3. Verifizieren Sie Ihre Identität (Organisation oder EV)
4. Erhalten Sie die .pfx Datei

### Schritt 2: Zertifikat importieren

```powershell
# PFX-Datei importieren
$pfxPath = "C:\Path\To\Your\Certificate.pfx"
$password = Read-Host -AsSecureString -Prompt "Passwort für PFX"
Import-PfxCertificate -FilePath $pfxPath -CertStoreLocation Cert:\CurrentUser\My -Password $password
```

### Schritt 3: Signieren (wie oben)

```powershell
$cert = Get-ChildItem Cert:\CurrentUser\My -CodeSigningCert | Select-Object -First 1
Set-AuthenticodeSignature -FilePath ".\Win_Gui_Module.ps1" -Certificate $cert -TimestampServer "http://timestamp.digicert.com"
```

---

## Automatisierung: Signierungsskript erstellen

Erstellen Sie `Sign-AllScripts.ps1` für einfache Signierung:

```powershell
# Sign-AllScripts.ps1
# Signiert alle PowerShell-Dateien im Projekt

param(
    [switch]$Verbose
)

# Zertifikat abrufen
$cert = Get-ChildItem Cert:\CurrentUser\My -CodeSigningCert | Where-Object {
    $_.Subject -like "*Bocki*"
} | Select-Object -First 1

if (-not $cert) {
    Write-Error "Kein Code-Signing-Zertifikat gefunden!"
    exit 1
}

Write-Host "📜 Verwende Zertifikat: $($cert.Subject)" -ForegroundColor Cyan
Write-Host "🔑 Thumbprint: $($cert.Thumbprint)" -ForegroundColor Gray

# Timestamp-Server (wichtig für Langzeitgültigkeit)
$timestampServer = "http://timestamp.digicert.com"

# Alle PowerShell-Dateien finden
$files = Get-ChildItem -Path $PSScriptRoot -Include *.ps1,*.psm1,*.psd1 -Recurse -Exclude Sign-AllScripts.ps1

$signed = 0
$failed = 0

foreach ($file in $files) {
    try {
        if ($Verbose) {
            Write-Host "Signiere: $($file.FullName.Replace($PSScriptRoot, '.'))" -ForegroundColor Yellow
        }
        
        $result = Set-AuthenticodeSignature -FilePath $file.FullName -Certificate $cert -TimestampServer $timestampServer -ErrorAction Stop
        
        if ($result.Status -eq 'Valid') {
            $signed++
            if ($Verbose) {
                Write-Host "  ✅ Erfolgreich" -ForegroundColor Green
            }
        } else {
            $failed++
            Write-Host "  ❌ Fehlgeschlagen: $($result.Status)" -ForegroundColor Red
        }
    }
    catch {
        $failed++
        Write-Host "  ❌ Fehler: $_" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan
Write-Host "✅ Erfolgreich signiert: $signed" -ForegroundColor Green
Write-Host "❌ Fehlgeschlagen: $failed" -ForegroundColor Red
Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan
```

---

## Signatur überprüfen

```powershell
# Signatur einer Datei prüfen
Get-AuthenticodeSignature -FilePath ".\Win_Gui_Module.ps1" | Format-List *

# Alle signierten Dateien prüfen
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

## Execution Policy anpassen

Nach der Signierung sollten Sie die Execution Policy setzen:

```powershell
# Nur signierte Skripte erlauben
Set-ExecutionPolicy AllSigned -Scope CurrentUser

# Oder: Lokale Skripte erlauben, Remote-Skripte müssen signiert sein
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

---

## Wichtige Hinweise

### Timestamp-Server
⚠️ **Immer einen Timestamp-Server verwenden!**
- Ohne Timestamp wird die Signatur ungültig, wenn das Zertifikat abläuft
- Mit Timestamp bleibt die Signatur auch nach Ablauf des Zertifikats gültig

**Verfügbare Timestamp-Server:**
- `http://timestamp.digicert.com`
- `http://timestamp.sectigo.com`
- `http://timestamp.comodoca.com`

### Workflow für Updates
1. Code ändern
2. Neu signieren mit `Sign-AllScripts.ps1`
3. Testen
4. Veröffentlichen

### Zertifikat sichern
```powershell
# Zertifikat mit privatem Schlüssel exportieren (sicher aufbewahren!)
$cert = Get-ChildItem Cert:\CurrentUser\My -CodeSigningCert | Select-Object -First 1
$password = Read-Host -AsSecureString -Prompt "Passwort für Backup"
Export-PfxCertificate -Cert $cert -FilePath "C:\Backup\CodeSigningCert.pfx" -Password $password
```

---

## Weitere Schritte gegen False-Positives

### 1. Bei Microsoft als False Positive melden
https://www.microsoft.com/en-us/wdsi/filesubmission

### 2. SmartScreen Reputation aufbauen
- Signierte Software wird über Zeit vertrauenswürdiger
- Mehr Downloads = bessere Reputation

### 3. Code-Audit
- Vermeiden Sie obfuskierten Code
- Klare, lesbare Funktionsnamen
- Kommentare hinzufügen

### 4. VirusTotal prüfen
```powershell
# Erstellen Sie eine ZIP für VirusTotal-Upload
Compress-Archive -Path .\* -DestinationPath ..\Win_Gui_Signed.zip
# Hochladen auf: https://www.virustotal.com
```

---

## Troubleshooting

### "Kein Zertifikat gefunden"
```powershell
# Alle Code-Signing-Zertifikate anzeigen
Get-ChildItem Cert:\CurrentUser\My -CodeSigningCert
Get-ChildItem Cert:\LocalMachine\My -CodeSigningCert
```

### "Signatur ist ungültig"
- Prüfen Sie, ob das Zertifikat zu Trusted Root hinzugefügt wurde
- Prüfen Sie, ob das Zertifikat noch gültig ist

### "Execution Policy blockiert"
```powershell
# Temporär umgehen (für Tests)
powershell.exe -ExecutionPolicy Bypass -File .\Win_Gui_Module.ps1
```

---

## Kosten-Nutzen-Abwägung

| Methode | Kosten | Vertrauen | Aufwand | Empfehlung |
|---------|--------|-----------|---------|------------|
| Self-Signed | Kostenlos | Niedrig (nur auf installiertem PC) | Niedrig | Entwicklung |
| Standard Code-Signing | €150-300/Jahr | Hoch | Mittel | Kleine Verteilung |
| EV Code-Signing | €300-500/Jahr | Sehr hoch | Hoch | Öffentliche Software |

---

## Nächste Schritte

1. ✅ Führen Sie `Sign-AllScripts.ps1` aus (Skript wird erstellt)
2. ✅ Prüfen Sie die Signaturen
3. ✅ Testen Sie mit Windows Defender
4. ✅ Bei Bedarf: Kommerzielles Zertifikat kaufen
5. ✅ Bei Microsoft als False Positive melden

**Fragen? Lesen Sie die README oder kontaktieren Sie den Support.**

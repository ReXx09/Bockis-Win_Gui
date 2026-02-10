# 🔄 Update-Mechanismus für Bockis System-Tool

## 📋 Übersicht

Der implementierte Update-Mechanismus ermöglicht automatische Updates direkt aus **privaten GitHub-Repositories** mit vollständiger Token-Authentifizierung und asynchroner Download-Verarbeitung.

---

## ✅ **Implementierte Features**

### 1. **Token-Authentifizierung für private Repos**
- GitHub Personal Access Token im Code hinterlegt
- Authentifizierung mit `Authorization: token XXXXXX`
- Zugriff auf private Releases und Assets

### 2. **Intelligente Release-Erkennung**
- Primär: `/releases/latest` (publizierte Releases)
- Fallback: `/releases` (inkl. Pre-Releases)
- Fallback: `/tags` (zeigt Anleitung, wenn nur Tags existieren)

### 3. **Asynchroner Download (GUI bleibt responsive!)**
- Download läuft in PowerShell Background-Job
- Timer-basierte Progress-Updates (alle 500ms)
- Anzeige der heruntergeladenen Dateigröße in MB
- GUI bleibt während Download vollständig bedienbar

### 4. **Asynchrones Entpacken**
- ZIP-Extraktion in separatem Background-Job
- Animierte Progress-Anzeige
- Keine GUI-Blockierung

### 5. **Automatische Installation**
- Erstellt Update-Script im Temp-Ordner
- Kopiert neue Dateien nach Neustart
- Startet Tool automatisch nach Update

### 6. **Drei Versionsvergleichs-Szenarien**
- **Neuere Version verfügbar** → Update anbieten
- **Gleiche Version** → "Sie verwenden bereits die neueste Version"
- **Installierte Version neuer** → "Ihre Version ist neuer als der Release"

---

## 🔧 **Technische Details**

### **Token-Konfiguration**

```powershell
# Zeile 5833-5836 in Win_Gui_Module.ps1
$githubToken = "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"
```

**Token-Berechtigungen erforderlich:**
- `repo` (Full control of private repositories)

**Token-Speicherort:**
- Datei: `Github---- Update-Token.txt`
- Im Code direkt eingebettet (Zeile 5836)

### **API-Endpoints**

```powershell
# Release-Informationen abrufen
GET https://api.github.com/repos/ReXx09/Bockis-Win_Gui-DEV/releases/latest
Headers:
  - Authorization: token XXXXX
  - Accept: application/vnd.github+json
  - User-Agent: Bockis-System-Tool

# Asset herunterladen
GET https://api.github.com/repos/ReXx09/Bockis-Win_Gui-DEV/releases/assets/{id}
Headers:
  - Authorization: token XXXXX
  - Accept: application/octet-stream
  - User-Agent: Bockis-System-Tool
```

### **Asynchroner Download-Mechanismus**

```powershell
# Background-Job für Download (Zeile 6018-6028)
$downloadJob = Start-Job -ScriptBlock {
    param($url, $headers, $outFile)
    Invoke-WebRequest -Uri $url -Headers $headers -OutFile $outFile -TimeoutSec 300
}

# Progress-Timer (500ms Intervall)
$progressTimer = New-Object System.Windows.Forms.Timer
$progressTimer.Interval = 500

# GUI responsive halten
while ($downloadJob.State -eq 'Running') {
    [System.Windows.Forms.Application]::DoEvents()
    Start-Sleep -Milliseconds 100
}
```

---

## 📂 **Dateistruktur**

### **Während des Updates:**

```
%TEMP%\
├── Bockis-Update-v4.1.X.zip          # Heruntergeladene Update-Datei
├── Bockis-Update-Extract\            # Entpackte Dateien
│   ├── Win_Gui_Module.ps1
│   ├── Modules\
│   ├── Lib\
│   └── ...
└── BockisUpdate.ps1                  # Installations-Script
```

### **Update-Script (BockisUpdate.ps1):**

```powershell
Start-Sleep -Seconds 2
Write-Host 'Installiere Update...'
$source = 'C:\Users\...\Temp\Bockis-Update-Extract\*'
$dest = 'C:\Users\...\VS-CODE-Repos\Bockis-Win_Gui_DEV'
Copy-Item -Path $source -Destination $dest -Recurse -Force
Remove-Item 'C:\Users\...\Temp\Bockis-Update-v4.1.X.zip' -Force
Remove-Item 'C:\Users\...\Temp\Bockis-Update-Extract' -Recurse -Force
Start-Process powershell.exe -ArgumentList '-ExecutionPolicy Bypass -File "...\Win_Gui_Module.ps1"'
```

---

## 🎯 **Ablauf des Update-Prozesses**

### **1. Update-Check starten**
- Benutzer klickt auf grünen "Update"-Button
- Tool ruft GitHub API auf

### **2. Release-Erkennung**
```
[i] Prüfe auf Updates...
Repository: ReXx09/Bockis-Win_Gui-DEV
Aktuelle Version: 4.1.1
Neueste Version: 4.1.2

[✓] Update verfügbar: v4.1.2
```

### **3. Bestätigung**
- MessageBox mit Release-Notes
- "Möchten Sie jetzt updaten?" → Ja/Nein

### **4. Download**
```
[i] Download wird gestartet...
Quelle: Bockis-System-Tool-v4.1.2.zip
Ziel: C:\Users\...\Temp\Bockis-Update-v4.1.2.zip

Download: 45.2 MB...  [Progress: ████████░░ 75%]
```

### **5. Extraktion**
```
[✓] Download abgeschlossen!

[i] Extrahiere Update...
Entpacken... 85%  [Progress: ████████▓░ 85%]
```

### **6. Installation**
```
[✓] Update wird installiert...
[i] Anwendung wird neu gestartet!
```

### **7. Neustart**
- Tool schließt sich
- Update-Script überschreibt Dateien
- Tool startet automatisch mit neuer Version

---

## 🧪 **Getestet**

### **Test-Szenario:**
- **Start-Version:** v4.1.1
- **Ziel-Version:** v4.1.2
- **Dateigröße:** ~102 MB
- **Repository:** `ReXx09/Bockis-Win_Gui-DEV` (privat)

### **Erfolgreiche Tests:**
✅ Token-Authentifizierung  
✅ Release-Erkennung  
✅ Download mit Progress-Anzeige  
✅ GUI bleibt responsive (kein Freeze!)  
✅ Automatisches Entpacken  
✅ Installation und Neustart  
✅ Version nach Update: 4.1.2 ✓  

---

## 📝 **Wichtige Hinweise**

### **Vor Public Release:**
```powershell
# Token ENTFERNEN aus Code (Zeile 5836):
$githubToken = ""  # Leer lassen für öffentliche Repos

# Oder Token-Check anpassen:
if ($githubToken -and $githubToken -ne "") {
    $headers["Authorization"] = "token $githubToken"
}
```

### **Für öffentliche Repos:**
- Token ist NICHT erforderlich
- Download-URL: `$asset.browser_download_url` (statt API-URL)
- Accept-Header: Standard (kein `application/octet-stream`)

### **Rate Limits:**
- **Ohne Token:** 60 Requests/Stunde
- **Mit Token:** 5000 Requests/Stunde

---

## 🚀 **Release erstellen**

### **Manuell über GitHub:**
1. Gehe zu: https://github.com/ReXx09/Bockis-Win_Gui-DEV/releases/new
2. Tag erstellen: `v4.1.X`
3. Release-Notes eingeben
4. ZIP-Datei hochladen: `Bockis-System-Tool-v4.1.X.zip`
5. "Publish release" klicken

### **Automatisch mit Script:**
```powershell
.\Tools\Create-GitHubRelease.ps1 -Version "4.1.3"
```

**Script erstellt automatisch:**
- Git-Tag `v4.1.3`
- Release-ZIP (~102 MB)
- Upload zu GitHub
- Release-Notes

---

## 🔒 **Sicherheit**

### **Token-Sicherheit:**
⚠️ **WICHTIG:** GitHub Personal Access Token ist im Code eingebettet!

**Sicherheitsmaßnahmen:**
- Token nur mit `repo`-Berechtigung (nicht `admin`)
- Bei Public Release Token entfernen
- Token regelmäßig erneuern
- `.gitignore` prüfen (Token-Datei ausschließen)

### **Token erneuern:**
1. GitHub → Settings → Developer Settings → Personal Access Tokens
2. Alten Token löschen
3. Neuen Token erstellen mit `repo`-Berechtigung
4. In `Github---- Update-Token.txt` speichern
5. In `Win_Gui_Module.ps1` Zeile 5836 aktualisieren

---

## 📊 **Performance**

- **Download-Geschwindigkeit:** Abhängig von Internetverbindung
- **100 MB Download:** ~30-60 Sekunden (bei 20 Mbit/s)
- **Entpacken:** ~5-10 Sekunden
- **Installation:** ~2-3 Sekunden
- **Gesamtdauer:** ~40-75 Sekunden

---

## 🐛 **Fehlerbehebung**

### **404-Fehler beim Update-Check:**
- **Ursache:** Kein Release vorhanden (nur Git-Tag)
- **Lösung:** Release über GitHub erstellen

### **401-Fehler (Unauthorized):**
- **Ursache:** Token ungültig oder abgelaufen
- **Lösung:** Token erneuern

### **Download hängt:**
- **Ursache:** Firewall blockiert GitHub
- **Lösung:** Firewall-Ausnahme erstellen

### **GUI friert ein:**
- **Status:** ✅ Behoben durch asynchronen Download

---

## 📌 **Zusammenfassung**

Der Update-Mechanismus ist **produktionsreif** und bietet:
- ✅ Vollständigen Support für private GitHub-Repositories
- ✅ Responsive GUI während des gesamten Update-Prozesses
- ✅ Automatische Installation ohne manuelle Eingriffe
- ✅ Robuste Fehlerbehandlung mit hilfreichen Meldungen
- ✅ Intelligente Release-Erkennung mit Fallback-Strategien

**Status:** 🟢 **PRODUKTIONSREIF**  
**Getestet:** 10.02.2026  
**Version:** 4.1.2  

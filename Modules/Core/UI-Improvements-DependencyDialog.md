# Dependency Dialog - UI/UX Verbesserungen

## Visuelle Darstellung

### Dialog mit gemischtem Status

```
┌───────────────────────────────────────────────────────────────┐
│  📦 Abhängigkeiten prüfen - Bockis System-Tool                │
├───────────────────────────────────────────────────────────────┤
│  🔍 Abhängigkeiten werden geprüft                             │
│  Für optimale Funktionalität werden zusätzliche Komponenten   │
│  empfohlen.                                                   │
├───────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │ ☐ PowerShell Core ✓ [Bereits installiert]            │ │  <- GRÜN
│  │   Version 7.5.4 gefunden                              │ │
│  └─────────────────────────────────────────────────────────┘ │
│                                                               │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │ ☑ LibreHardwareMonitor                                  │ │  <- WEISS
│  │   Hardware-Überwachung mit aktuellen Sensoren...        │ │
│  └─────────────────────────────────────────────────────────┘ │
│                                                               │
├───────────────────────────────────────────────────────────────┤
│                   [✓ Ausgewählte installieren] [→ Überspringen]│
└───────────────────────────────────────────────────────────────┘
```

### Dialog wenn alles installiert

```
┌───────────────────────────────────────────────────────────────┐
│  📦 Abhängigkeiten prüfen - Bockis System-Tool                │
├───────────────────────────────────────────────────────────────┤
│  🔍 Abhängigkeiten werden geprüft                             │
│  Für optimale Funktionalität werden zusätzliche Komponenten   │
│  empfohlen.                                                   │
├───────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │ ☐ LibreHardwareMonitor ✓ [Bereits installiert]         │ │  <- GRÜN
│  │   Version 0.9.5 gefunden                                │ │
│  └─────────────────────────────────────────────────────────┘ │
│                                                               │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │ ☐ PowerShell Core ✓ [Bereits installiert]              │ │  <- GRÜN
│  │   Version 7.5.4 gefunden                                │ │
│  └─────────────────────────────────────────────────────────┘ │
│                                                               │
├───────────────────────────────────────────────────────────────┤
│                      [✓ Alles in Ordnung]      [→ Schließen] │
└───────────────────────────────────────────────────────────────┘
```

## Farbschema

### Installierte Komponenten
- **Hintergrund**: RGB(230, 255, 230) - Hellgrün
- **Text**: DarkGreen
- **Checkbox**: Ausgegraut (`Enabled = $false`)
- **Label**: `"[Komponentenname] ✓ [Bereits installiert]"`
- **Beschreibung**: Zeigt Version/Pfad statt generischer Beschreibung

### Fehlende Komponenten
- **Hintergrund**: White
- **Text**: Black, Bold
- **Checkbox**: Aktiv (`Enabled = $true`)
- **Label**: `"[Komponentenname]"`
- **Beschreibung**: Funktionsbeschreibung

## Button-Logik

### Installieren-Button
```powershell
if ($hasInstallableItems) {
    # Es gibt nicht-installierte Komponenten
    Button: "✓ Ausgewählte installieren"
    Color: Green (46, 204, 113)
} else {
    # Alles ist bereits installiert
    Button: "✓ Alles in Ordnung"
    Color: Green (46, 204, 113)
}
```

### Rechter Button
```powershell
if ($hasInstallableItems) {
    Button: "→ Überspringen"
    # Nutzer kann Installation ablehnen
} else {
    Button: "→ Schließen"
    # Nur Informationsdialog
}
```

## Beispiel-Szenarien

### Szenario 1: Neu-Installation (nichts installiert)
```
Dialog zeigt:
  ☑ LibreHardwareMonitor       [WEISS, aktiv]
     Hardware-Überwachung...
     
Buttons: [✓ Ausgewählte installieren] [→ Überspringen]
```

### Szenario 2: Teilweise installiert
```
Dialog zeigt:
  ☐ PowerShell Core ✓ [Bereits installiert]  [GRÜN, ausgegraut]
     Version 7.5.4 gefunden
     
  ☑ LibreHardwareMonitor                      [WEISS, aktiv]
     Hardware-Überwachung...
     
Buttons: [✓ Ausgewählte installieren] [→ Überspringen]
```

### Szenario 3: Alles installiert
```
Dialog zeigt:
  ☐ LibreHardwareMonitor ✓ [Bereits installiert]  [GRÜN, ausgegraut]
     Version 0.9.5 gefunden
     
  ☐ PowerShell Core ✓ [Bereits installiert]       [GRÜN, ausgegraut]
     Version 7.5.4 gefunden
     
Buttons: [✓ Alles in Ordnung] [→ Schließen]
```

## Technische Details

### Checkbox-Konfiguration
```powershell
if ($isInstalled) {
    $checkBox.Text = "$($dep.Name) ✓ [Bereits installiert]"
    $checkBox.Checked = $false
    $checkBox.Enabled = $false  # Ausgegraut
    $checkBox.ForeColor = [System.Drawing.Color]::DarkGreen
} else {
    $checkBox.Text = "$($dep.Name)"
    $checkBox.Checked = $dep.Required
    $checkBox.Enabled = $true
    $checkBox.ForeColor = [System.Drawing.Color]::Black
}
```

### Panel-Hintergrund
```powershell
if ($isInstalled) {
    $depPanel.BackColor = [System.Drawing.Color]::FromArgb(230, 255, 230)
} else {
    $depPanel.BackColor = [System.Drawing.Color]::White
}
```

### Beschreibungs-Text
```powershell
if ($isInstalled) {
    if ($dep.Version) {
        $descLabel.Text = "Version $($dep.Version) gefunden"
    } elseif ($dep.Path) {
        $descLabel.Text = "Installiert: $($dep.Path)"
    } else {
        $descLabel.Text = "Installation wurde erkannt"
    }
    $descLabel.ForeColor = [System.Drawing.Color]::DarkGreen
} else {
    $descLabel.Text = $dep.Description
    $descLabel.ForeColor = [System.Drawing.Color]::Gray
}
```

## User Experience

### Vorteile

✅ **Sofortige visuelle Unterscheidung**
   - Grüne Panels = Alles OK
   - Weiße Panels = Aktion erforderlich

✅ **Verhindert versehentliche Neu-Installation**
   - Ausgegraute Checkboxen können nicht angeklickt werden

✅ **Informativ ohne Überforderung**
   - Zeigt Version bei installierten Komponenten
   - Zeigt Funktionsbeschreibung bei fehlenden

✅ **Intelligente Button-Beschriftung**
   - Passt sich dem Kontext an
   - Vermeidet Verwirrung ("Installation" wenn nichts zu installieren ist)

### User Flow

1. Dialog öffnet sich nach GUI-Laden
2. Nutzer sieht auf ersten Blick:
   - **GRÜN** = Bereits vorhanden ✓
   - **WEISS** = Kann installiert werden
3. Ausgegraut = Keine Aktion möglich/nötig
4. Button-Text erklärt nächsten Schritt eindeutig

---

**Version:** 2.0  
**Datum:** 2026-01-13  
**Autor:** Bockis

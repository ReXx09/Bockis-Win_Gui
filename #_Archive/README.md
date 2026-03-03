# Archivierte Dateien
**Archiviert am:** 28. Oktober 2025  
**Grund:** Code-Cleanup - Entfernung von Duplikaten und ungenutztem Code

---

## 📁 Inhalt

### Backup-Dateien (.bak, .backup)
- `System.Data.SQLite.dll.bak` - Backup der SQLite-DLL
- `UI.psm1.bak` - Backup des UI-Moduls
- `DefenderTools.psm1.backup` - Backup des DefenderTools-Moduls

### Kopie-Dateien (Lib-Duplikate)
- `HidSharp - Kopie.dll`
- `iCUESDK.x64_2019 - Kopie.dll`
- `LibHardwareMonitor - Kopie.dll`
- `LibreHardwareMonitorLib - Kopie.dll`
- `SQLite - Kopie.cs`
- `SQLiteAsync - Kopie.cs`
- `System.Data.SQLite - Kopie.dll`

### Ungenutzte Module
- `ColorScheme.psm1` - Farbschema-Modul (wurde nie importiert, Farbdefinitionen sind direkt im Code)
- `HardwareInfo.psm1` - Hardware-Info-Modul (DEPRECATED - Funktionalität ist in Win_Gui_Module.ps1 dupliziert)

---

## ℹ️ Hinweise

- Diese Dateien wurden nicht gelöscht, sondern archiviert
- Bei Bedarf können sie über Git-Historie wiederhergestellt werden
- Die Originaldateien (ohne "- Kopie" oder ".bak") werden weiterhin verwendet
- Das ColorScheme-Modul wurde durch direkte Farbdefinitionen in den einzelnen Modulen ersetzt

---

## 🗑️ Kann gelöscht werden

Dieser Ordner kann vollständig gelöscht werden, wenn sicher ist, dass keine der Dateien mehr benötigt wird.
Die Dateien sind über die Git-Historie weiterhin verfügbar.

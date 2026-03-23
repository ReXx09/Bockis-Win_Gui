@echo off
REM Bockis System-Tool Starter
REM Verwendet Windows PowerShell 5.1 (erforderlich für LibreHardwareMonitor-Kompatibilität)

echo.
echo ╔═══════════════════════════════════════════════════════════════╗
echo ║          Starte Bockis System-Tool v4.1                       ║
echo ╚═══════════════════════════════════════════════════════════════╝
echo.

REM Wechsle ins Skript-Verzeichnis
cd /d "%~dp0"

REM Entsperre alle Dateien falls von GitHub als ZIP heruntergeladen (HRESULT 0x80131515 / Zone.Identifier)
REM Dies ist nur noetig wenn die Dateien noch blockiert sind - schadet nicht wenn bereits entsperrt.
"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -Command "Get-ChildItem -Path '%~dp0' -Recurse -File -Include '*.dll','*.ps1','*.psm1','*.psd1' -EA SilentlyContinue | Unblock-File -EA SilentlyContinue"

REM Verwende Windows PowerShell 5.1 (NICHT PowerShell Core 7.x!)
REM LibreHardwareMonitor v0.9.5 benötigt .NET Framework 4.8
"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -ExecutionPolicy Bypass -NoProfile -File "%~dp0Win_Gui_Module.ps1"

REM Pause falls Fehler auftritt
if errorlevel 1 (
    echo.
    echo [FEHLER] Das Tool konnte nicht gestartet werden!
    echo.
    pause
)

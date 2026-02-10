@echo off
:: ============================================
:: LibreHardwareMonitor Update v0.9.4 → v0.9.5
:: ============================================
::
:: WICHTIG: 
::   - Schließen Sie ALLE VS Code Fenster
::   - Schließen Sie ALLE PowerShell-Terminals
::   - Führen Sie diese Datei dann aus (Rechtsklick → Als Administrator ausführen)

echo.
echo =============================================
echo  LibreHardwareMonitor DLL Update
echo  v0.9.4 --^> v0.9.5 (PawnIO Support)
echo =============================================
echo.
echo [i] Prüfe Administrator-Rechte...

:: Administrator-Check
net session >nul 2>&1
if %errorLevel% NEQ 0 (
    echo [X] FEHLER: Keine Administrator-Rechte!
    echo.
    echo Bitte:
    echo   1. Rechtsklick auf diese Datei
    echo   2. "Als Administrator ausfuehren"
    echo.
    pause
    exit /b 1
)

echo [OK] Administrator-Rechte vorhanden
echo.
echo [i] Starte PowerShell-Update-Skript...
echo.

:: PowerShell-Skript ausführen
cd /d "%~dp0"
powershell.exe -ExecutionPolicy Bypass -NoProfile -File "Update-LibreHardwareMonitor.ps1"

echo.
pause

# ===================================================================
# Test-DllVersionChecks.ps1
# ===================================================================
# Testet die erweiterte Test-SystemDependencies Funktion mit DLL-Versionsabfragen
# ===================================================================

# Module laden
$ErrorActionPreference = "Stop"
$modulePath = Join-Path $PSScriptRoot "..\Modules\Core\DependencyChecker.psm1"

Write-Host "🧪 Test: DLL-Versionsabfragen in Test-SystemDependencies`n" -ForegroundColor Cyan
Write-Host "Lade DependencyChecker Modul..." -ForegroundColor Gray
Write-Host "Pfad: $modulePath`n" -ForegroundColor Gray

if (-not (Test-Path $modulePath)) {
    Write-Host "❌ Modul nicht gefunden: $modulePath" -ForegroundColor Red
    exit 1
}

Import-Module $modulePath -Force

Write-Host "`n📋 Führe Test-SystemDependencies aus...`n" -ForegroundColor Cyan
Write-Host ("=" * 80) -ForegroundColor Gray

# Test-SystemDependencies aufrufen
$result = Test-SystemDependencies

Write-Host "`n" -ForegroundColor Gray
Write-Host ("=" * 80) -ForegroundColor Gray
Write-Host "`n📊 Ergebnis-Zusammenfassung:`n" -ForegroundColor Cyan

if ($result.AllSatisfied) {
    Write-Host "✓ Alle Abhängigkeiten erfüllt!`n" -ForegroundColor Green
}
else {
    Write-Host "⚠️  Nicht alle Abhängigkeiten erfüllt`n" -ForegroundColor Yellow
}

Write-Host "🔍 Details zum Testen der DLL-Prüfungen:" -ForegroundColor Cyan
Write-Host "   → Überprüfe ob DLL-Versionen korrekt erkannt wurden" -ForegroundColor Gray
Write-Host "   → Achte auf LibreHardwareMonitorLib.dll >= 0.9.5" -ForegroundColor Gray
Write-Host "   → Prüfe ob BlackSharp.Core.dll gefunden wurde (erforderlich)" -ForegroundColor Gray
Write-Host "   → HidSharp.dll ist optional (nur für spezielle HID-Geräte)`n" -ForegroundColor Gray

Write-Host "✓ Test abgeschlossen" -ForegroundColor Green

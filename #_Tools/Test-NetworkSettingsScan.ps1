# Test-NetworkSettingsScan.ps1
# Testet den Netzwerk-Einstellungs-Scan aus dem NetworkTools-Modul.

Write-Host "`n=== Netzwerk-Einstellungs-Scan Test ===" -ForegroundColor Cyan

# GUI-Logging ist im Testkontext nicht geladen, daher Fallback bereitstellen.
if (-not (Get-Command Write-ToolLog -ErrorAction SilentlyContinue)) {
    function global:Write-ToolLog {
        param(
            [string]$ToolName,
            [string]$Message,
            $OutputBox,
            [string]$Style,
            [string]$Level,
            [switch]$SaveToDatabase
        )

        $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Write-Host "[$ts] [$Level] [$ToolName] $Message" -ForegroundColor Gray
    }
}

try {
    Import-Module "$PSScriptRoot\..\Modules\Tools\NetworkTools.psm1" -Force -ErrorAction Stop
    Write-Host "[OK] Modul geladen" -ForegroundColor Green
}
catch {
    Write-Host "[FEHLER] Modul konnte nicht geladen werden: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

try {
    $result = Start-NetworkSettingsScan -outputBox $null

    if (-not $result) {
        throw "Kein Rueckgabeobjekt erhalten"
    }

    if (-not $result.Checks -or $result.Checks.Count -lt 11) {
        throw "Es wurden weniger als 11 Checks ausgefuehrt"
    }

    if ($null -eq $result.Diagnostics) {
        throw "Diagnostics fehlen im Rueckgabeobjekt"
    }

    if ($null -eq $result.Recommendations) {
        throw "Recommendations fehlen im Rueckgabeobjekt"
    }

    Write-Host "`nGesamtstatus: $($result.Overall)" -ForegroundColor Yellow
    Write-Host "Checks:" -ForegroundColor Yellow

    foreach ($check in $result.Checks) {
        $line = "- [{0}] {1}: {2}" -f $check.Status, $check.Name, $check.Detail
        switch ($check.Status) {
            "Green" { Write-Host $line -ForegroundColor Green }
            "Red" { Write-Host $line -ForegroundColor Red }
            default { Write-Host $line -ForegroundColor Yellow }
        }
    }

    Write-Host "`nDiagnostics: $(@($result.Diagnostics).Count)" -ForegroundColor Cyan
    foreach ($diag in @($result.Diagnostics)) {
        Write-Host ("- [{0}] {1} ({2}%)" -f $diag.Severity, $diag.ProblemType, $diag.ConfidenceScore) -ForegroundColor Gray
    }

    Write-Host "`nRecommendations: $(@($result.Recommendations).Count)" -ForegroundColor Cyan
    foreach ($rec in @($result.Recommendations)) {
        Write-Host ("- [{0}] {1}" -f $rec.Priority, $rec.Action) -ForegroundColor Gray
    }

    $guideResult = Start-NetworkManualGuide -outputBox $null
    if ($null -eq $guideResult) {
        throw "Manuelle Anleitung lieferte kein Ergebnis"
    }

    Write-Host "`nManualGuide: OK" -ForegroundColor Cyan

    Write-Host "`n[OK] Netzwerk-Einstellungs-Scan Test erfolgreich abgeschlossen." -ForegroundColor Green
}
catch {
    Write-Host "`n[FEHLER] Test fehlgeschlagen: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

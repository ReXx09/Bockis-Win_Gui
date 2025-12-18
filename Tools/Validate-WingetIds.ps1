#Requires -Version 7.0

<#
.SYNOPSIS
    Validiert alle Winget-IDs in der ToolLibrary

.DESCRIPTION
    Dieses Skript durchsucht die ToolLibrary und prüft für jedes Tool,
    ob die angegebene Winget-ID in Winget verfügbar ist.
    
.EXAMPLE
    .\Validate-WingetIds.ps1
#>

[CmdletBinding()]
param()

# Import ToolLibrary
$modulesPath = Join-Path $PSScriptRoot "..\Modules"
Import-Module (Join-Path $modulesPath "ToolLibrary.psm1") -Force

Write-Host "=== Winget-ID Validierung ===" -ForegroundColor Cyan
Write-Host ""

# Prüfe ob Winget verfügbar ist
try {
    $null = winget --version
} catch {
    Write-Host "FEHLER: Winget ist nicht verfügbar!" -ForegroundColor Red
    exit 1
}

# Hole ToolLibrary direkt aus dem Modul-Scope
$toolLibrary = & (Get-Module ToolLibrary) { $script:toolLibrary }

# Zähler für Statistik
$totalTools = 0
$validTools = 0
$invalidTools = 0
$results = @()

# Durchlaufe alle Kategorien
foreach ($category in $toolLibrary.Keys) {
    $tools = $toolLibrary[$category]
    
    if ($tools.Count -eq 0) {
        continue
    }
    
    Write-Host "Kategorie: $category" -ForegroundColor Yellow
    Write-Host ("=" * 80) -ForegroundColor DarkGray
    
    foreach ($tool in $tools) {
        $totalTools++
        $toolName = $tool.Name
        $wingetId = $tool.Winget
        
        Write-Host "  Prüfe: $toolName" -NoNewline
        
        if ([string]::IsNullOrWhiteSpace($wingetId)) {
            Write-Host " [KEINE ID]" -ForegroundColor Gray
            $results += [PSCustomObject]@{
                Category = $category
                Tool = $toolName
                WingetId = "N/A"
                Status = "NoId"
                Message = "Keine Winget-ID angegeben"
            }
            continue
        }
        
        # Prüfe Winget-ID
        try {
            $searchResult = winget show $wingetId 2>&1 | Out-String
            
            if ($searchResult -match "Kein Paket gefunden|No package found") {
                Write-Host " [UNGÜLTIG]" -ForegroundColor Red
                $invalidTools++
                $results += [PSCustomObject]@{
                    Category = $category
                    Tool = $toolName
                    WingetId = $wingetId
                    Status = "Invalid"
                    Message = "Winget-ID nicht gefunden"
                }
            } else {
                Write-Host " [OK]" -ForegroundColor Green
                $validTools++
                $results += [PSCustomObject]@{
                    Category = $category
                    Tool = $toolName
                    WingetId = $wingetId
                    Status = "Valid"
                    Message = "Winget-ID verfügbar"
                }
            }
        } catch {
            Write-Host " [FEHLER]" -ForegroundColor Red
            $invalidTools++
            $results += [PSCustomObject]@{
                Category = $category
                Tool = $toolName
                WingetId = $wingetId
                Status = "Error"
                Message = $_.Exception.Message
            }
        }
        
        Start-Sleep -Milliseconds 100  # Kurze Pause um Winget nicht zu überlasten
    }
    
    Write-Host ""
}

# Zusammenfassung
Write-Host ""
Write-Host "=== Zusammenfassung ===" -ForegroundColor Cyan
Write-Host "Gesamt geprüfte Tools: $totalTools" -ForegroundColor White
Write-Host "Gültige Winget-IDs:    $validTools" -ForegroundColor Green
Write-Host "Ungültige Winget-IDs:  $invalidTools" -ForegroundColor Red
Write-Host ""

# Zeige Details für ungültige Tools
$problemTools = $results | Where-Object { $_.Status -in @('Invalid', 'Error') }
if ($problemTools.Count -gt 0) {
    Write-Host "=== Tools mit Problemen ===" -ForegroundColor Red
    $problemTools | Format-Table Category, Tool, WingetId, Status, Message -AutoSize
    Write-Host ""
    
    # Vorschläge
    Write-Host "=== Winget-Suche Vorschläge ===" -ForegroundColor Yellow
    foreach ($problem in $problemTools) {
        Write-Host "Suche für '$($problem.Tool)':" -ForegroundColor White
        Write-Host "  winget search `"$($problem.Tool)`"" -ForegroundColor Gray
    }
}

# Export Ergebnisse
$exportPath = Join-Path $PSScriptRoot "..\Logs\winget-validation-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
$results | ConvertTo-Json -Depth 3 | Out-File $exportPath -Encoding UTF8
Write-Host "Ergebnisse exportiert nach: $exportPath" -ForegroundColor Cyan

# Exit Code
if ($invalidTools -gt 0) {
    exit 1
} else {
    exit 0
}

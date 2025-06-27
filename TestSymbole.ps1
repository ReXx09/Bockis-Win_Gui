# Test der konsistenten Symbol-Ausgabe
# Dieses Skript testet die neuen Symbol-Funktionen

# Import des Core-Moduls
Import-Module "$PSScriptRoot\Modules\Core\Core.psm1" -Force

Write-Host "=== Test der konsistenten Symbol-Ausgabe ===" -ForegroundColor Magenta
Write-Host ""

# Test der einzelnen Symbol-Typen
Write-Host "1. Test der verschiedenen Symbol-Typen in der Konsole:" -ForegroundColor White
Write-Host ""

Write-ConsoleAndOutputBox -Message "Erfolgreiche Operation" -Type "Success"
Write-ConsoleAndOutputBox -Message "Fehlerhafte Operation" -Type "Error" 
Write-ConsoleAndOutputBox -Message "Warnung: Benutzeraufmerksamkeit erforderlich" -Type "Warning"
Write-ConsoleAndOutputBox -Message "Neutrale Information und Hinweise" -Type "Info"
Write-ConsoleAndOutputBox -Message "Laufender Prozess oder Fortschritt" -Type "Process"
Write-ConsoleAndOutputBox -Message "Start einer neuen Operation" -Type "Start"

Write-Host ""
Write-Host "2. Test der Symbol-Abruf-Funktionen:" -ForegroundColor White
Write-Host ""

Write-Host "Erfolg-Symbol: $(Get-Symbol -Type 'Success')" -ForegroundColor (Get-SymbolConsoleColor -Type 'Success')
Write-Host "Fehler-Symbol: $(Get-Symbol -Type 'Error')" -ForegroundColor (Get-SymbolConsoleColor -Type 'Error')
Write-Host "Warnung-Symbol: $(Get-Symbol -Type 'Warning')" -ForegroundColor (Get-SymbolConsoleColor -Type 'Warning')
Write-Host "Info-Symbol: $(Get-Symbol -Type 'Info')" -ForegroundColor (Get-SymbolConsoleColor -Type 'Info')
Write-Host "Prozess-Symbol: $(Get-Symbol -Type 'Process')" -ForegroundColor (Get-SymbolConsoleColor -Type 'Process')
Write-Host "Start-Symbol: $(Get-Symbol -Type 'Start')" -ForegroundColor (Get-SymbolConsoleColor -Type 'Start')

Write-Host ""
Write-Host "=== Test abgeschlossen ===" -ForegroundColor Magenta
Write-Host "Die DefenderTools.psm1 verwendet jetzt konsistente Symbole" -ForegroundColor Green
Write-Host "sowohl in der PowerShell-Konsole als auch in der OutputBox!" -ForegroundColor Green

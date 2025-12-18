# Sign-AllScripts.ps1
# Signiert alle PowerShell-Dateien im Win_Gui_Projekt
# Autor: Bocki
# Version: 1.0

param(
    [switch]$Verbose,
    [switch]$CreateCertificate,
    [string]$CertificateSubject = "CN=Bocki Software, O=Bocki, C=DE"
)

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  🔐 PowerShell Code-Signierung für Win_Gui_Module" -ForegroundColor White
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Funktion: Self-Signed Certificate erstellen
function New-CodeSigningCertificate {
    param([string]$Subject)
    
    Write-Host "📜 Erstelle neues Self-Signed Certificate..." -ForegroundColor Yellow
    
    try {
        $cert = New-SelfSignedCertificate `
            -Subject $Subject `
            -Type CodeSigning `
            -CertStoreLocation Cert:\CurrentUser\My `
            -NotAfter (Get-Date).AddYears(5) `
            -KeyExportPolicy Exportable `
            -KeySpec Signature `
            -KeyLength 2048 `
            -KeyAlgorithm RSA `
            -HashAlgorithm SHA256
        
        Write-Host "✅ Zertifikat erstellt!" -ForegroundColor Green
        Write-Host "   Subject: $($cert.Subject)" -ForegroundColor Gray
        Write-Host "   Thumbprint: $($cert.Thumbprint)" -ForegroundColor Gray
        Write-Host "   Gültig bis: $($cert.NotAfter)" -ForegroundColor Gray
        Write-Host ""
        
        # Zertifikat zu Trusted Root hinzufügen
        Write-Host "🔑 Füge Zertifikat zu Trusted Publishers hinzu..." -ForegroundColor Yellow
        Write-Host "   (Erfordert Administrator-Rechte)" -ForegroundColor Gray
        
        $tempCertPath = Join-Path $env:TEMP "BockiCodeSigning_$(Get-Date -Format 'yyyyMMdd_HHmmss').cer"
        Export-Certificate -Cert $cert -FilePath $tempCertPath | Out-Null
        
        # Versuche als Administrator zu importieren
        try {
            $importScript = @"
Import-Certificate -FilePath '$tempCertPath' -CertStoreLocation Cert:\LocalMachine\Root | Out-Null
Import-Certificate -FilePath '$tempCertPath' -CertStoreLocation Cert:\LocalMachine\TrustedPublisher | Out-Null
"@
            Start-Process powershell -Verb RunAs -ArgumentList "-NoProfile -Command $importScript" -Wait -WindowStyle Hidden
            Write-Host "✅ Zertifikat zu Trusted Publishers hinzugefügt" -ForegroundColor Green
        }
        catch {
            Write-Host "⚠️  Konnte nicht automatisch zu Trusted Publishers hinzufügen" -ForegroundColor Yellow
            Write-Host "   Führen Sie folgende Befehle als Administrator aus:" -ForegroundColor Gray
            Write-Host "   Import-Certificate -FilePath '$tempCertPath' -CertStoreLocation Cert:\LocalMachine\Root" -ForegroundColor Gray
            Write-Host "   Import-Certificate -FilePath '$tempCertPath' -CertStoreLocation Cert:\LocalMachine\TrustedPublisher" -ForegroundColor Gray
        }
        
        Write-Host ""
        return $cert
    }
    catch {
        Write-Host "❌ Fehler beim Erstellen des Zertifikats: $_" -ForegroundColor Red
        exit 1
    }
}

# Certificate erstellen, falls gewünscht
if ($CreateCertificate) {
    $cert = New-CodeSigningCertificate -Subject $CertificateSubject
}
else {
    # Vorhandenes Zertifikat suchen
    Write-Host "🔍 Suche nach Code-Signing-Zertifikat..." -ForegroundColor Yellow
    
    $cert = Get-ChildItem Cert:\CurrentUser\My -CodeSigningCert | Where-Object {
        $_.Subject -like "*Bocki*" -or $_.Subject -like "*Win_Gui*"
    } | Select-Object -First 1
    
    if (-not $cert) {
        Write-Host "❌ Kein Code-Signing-Zertifikat gefunden!" -ForegroundColor Red
        Write-Host ""
        Write-Host "Optionen:" -ForegroundColor Yellow
        Write-Host "  1. Führen Sie dieses Skript mit -CreateCertificate aus" -ForegroundColor White
        Write-Host "     .\Sign-AllScripts.ps1 -CreateCertificate" -ForegroundColor Gray
        Write-Host ""
        Write-Host "  2. Importieren Sie ein vorhandenes Zertifikat:" -ForegroundColor White
        Write-Host "     Import-PfxCertificate -FilePath 'Path\To\Cert.pfx' -CertStoreLocation Cert:\CurrentUser\My" -ForegroundColor Gray
        Write-Host ""
        exit 1
    }
}

Write-Host "📜 Verwende Zertifikat:" -ForegroundColor Cyan
Write-Host "   Subject: $($cert.Subject)" -ForegroundColor White
Write-Host "   Thumbprint: $($cert.Thumbprint)" -ForegroundColor Gray
Write-Host "   Gültig von: $($cert.NotBefore)" -ForegroundColor Gray
Write-Host "   Gültig bis: $($cert.NotAfter)" -ForegroundColor Gray
Write-Host ""

# Prüfe Zertifikat-Gültigkeit
if ($cert.NotAfter -lt (Get-Date)) {
    Write-Host "⚠️  WARNUNG: Zertifikat ist abgelaufen!" -ForegroundColor Red
    Write-Host "   Erstellen Sie ein neues mit -CreateCertificate" -ForegroundColor Yellow
    Write-Host ""
    exit 1
}

if ($cert.NotAfter -lt (Get-Date).AddMonths(1)) {
    Write-Host "⚠️  WARNUNG: Zertifikat läuft bald ab (< 1 Monat)" -ForegroundColor Yellow
    Write-Host ""
}

# Timestamp-Server (wichtig für Langzeitgültigkeit)
$timestampServers = @(
    "http://timestamp.digicert.com",
    "http://timestamp.sectigo.com",
    "http://timestamp.comodoca.com"
)

# Alle PowerShell-Dateien finden
Write-Host "🔍 Suche PowerShell-Dateien..." -ForegroundColor Yellow
$files = Get-ChildItem -Path $PSScriptRoot -Include *.ps1,*.psm1,*.psd1 -Recurse | Where-Object {
    $_.Name -ne "Sign-AllScripts.ps1"
}

Write-Host "   Gefunden: $($files.Count) Dateien" -ForegroundColor White
Write-Host ""

if ($files.Count -eq 0) {
    Write-Host "❌ Keine PowerShell-Dateien zum Signieren gefunden!" -ForegroundColor Red
    exit 1
}

# Signierung durchführen
$signed = 0
$failed = 0
$skipped = 0

Write-Host "🔐 Signiere Dateien..." -ForegroundColor Cyan
Write-Host ""

foreach ($file in $files) {
    $relativePath = $file.FullName.Replace($PSScriptRoot, '.').Replace('\', '/')
    
    # Prüfe ob bereits signiert
    $existingSig = Get-AuthenticodeSignature -FilePath $file.FullName
    
    if ($Verbose) {
        Write-Host "📄 $relativePath" -ForegroundColor Yellow
        if ($existingSig.Status -eq 'Valid') {
            Write-Host "   ℹ️  Bereits signiert (wird neu signiert)" -ForegroundColor Gray
        }
    }
    
    $success = $false
    
    # Versuche mit verschiedenen Timestamp-Servern
    foreach ($timestampServer in $timestampServers) {
        try {
            # Signiere mit SHA256 für bessere Sicherheit und Defender-Kompatibilität
            $result = Set-AuthenticodeSignature `
                -FilePath $file.FullName `
                -Certificate $cert `
                -TimestampServer $timestampServer `
                -HashAlgorithm SHA256 `
                -IncludeChain All `
                -ErrorAction Stop
            
            if ($result.Status -eq 'Valid') {
                $signed++
                $success = $true
                if ($Verbose) {
                    Write-Host "   ✅ Erfolgreich signiert (SHA256)" -ForegroundColor Green
                }
                break
            }
            else {
                if ($Verbose) {
                    Write-Host "   ⚠️  Status: $($result.Status)" -ForegroundColor Yellow
                }
            }
        }
        catch {
            if ($Verbose) {
                Write-Host "   ⚠️  Timestamp-Server $timestampServer fehlgeschlagen, versuche nächsten..." -ForegroundColor Yellow
            }
            continue
        }
    }
    
    if (-not $success) {
        $failed++
        Write-Host "❌ $relativePath" -ForegroundColor Red
        Write-Host "   Fehler: Konnte nicht signiert werden" -ForegroundColor Red
    }
    elseif (-not $Verbose) {
        Write-Host "✅ $relativePath" -ForegroundColor Green
    }
    
    if ($Verbose) {
        Write-Host ""
    }
}

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  📊 Zusammenfassung" -ForegroundColor White
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "✅ Erfolgreich signiert: $signed" -ForegroundColor Green
if ($skipped -gt 0) {
    Write-Host "⏭️  Übersprungen: $skipped" -ForegroundColor Yellow
}
if ($failed -gt 0) {
    Write-Host "❌ Fehlgeschlagen: $failed" -ForegroundColor Red
}
Write-Host "📁 Gesamt: $($files.Count)" -ForegroundColor White
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

if ($failed -eq 0) {
    Write-Host "🎉 Alle Dateien erfolgreich signiert!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Nächste Schritte:" -ForegroundColor Yellow
    Write-Host "  1. Testen Sie die Anwendung" -ForegroundColor White
    Write-Host "  2. Prüfen Sie mit Windows Defender" -ForegroundColor White
    Write-Host "  3. Bei Bedarf: Melden Sie als False Positive bei Microsoft" -ForegroundColor White
    Write-Host "     https://www.microsoft.com/en-us/wdsi/filesubmission" -ForegroundColor Gray
    Write-Host ""
}
else {
    Write-Host "⚠️  Einige Dateien konnten nicht signiert werden." -ForegroundColor Yellow
    Write-Host "   Führen Sie das Skript mit -Verbose aus für Details." -ForegroundColor Gray
    Write-Host ""
    exit 1
}

# Signatur-Übersicht anzeigen
if ($Verbose) {
    Write-Host "📋 Signatur-Status aller Dateien:" -ForegroundColor Cyan
    Write-Host ""
    
    Get-ChildItem -Path $PSScriptRoot -Include *.ps1,*.psm1,*.psd1 -Recurse | ForEach-Object {
        $sig = Get-AuthenticodeSignature $_.FullName
        $status = switch ($sig.Status) {
            'Valid' { '✅' }
            'NotSigned' { '❌' }
            'UnknownError' { '⚠️' }
            default { '❓' }
        }
        
        $relativePath = $_.FullName.Replace($PSScriptRoot, '.').Replace('\', '/')
        Write-Host "$status $relativePath" -ForegroundColor $(if ($sig.Status -eq 'Valid') { 'Green' } else { 'Red' })
    }
    Write-Host ""
}

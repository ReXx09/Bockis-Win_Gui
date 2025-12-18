# Configure-SignTool.ps1
# Konfiguriert die Code-Signierung in installer.iss
# Autor: Bocki
# Version: 1.0

param(
    [switch]$Enable,
    [switch]$Disable,
    [string]$CertificateThumbprint,
    [string]$CertificateSubject = "Bocki Software",
    [switch]$ShowStatus
)

$ErrorActionPreference = "Stop"
$issFile = Join-Path $PSScriptRoot "installer.iss"

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  🔐 SignTool-Konfiguration für installer.iss" -ForegroundColor White
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Prüfe ob installer.iss existiert
if (-not (Test-Path $issFile)) {
    Write-Host "❌ installer.iss nicht gefunden!" -ForegroundColor Red
    exit 1
}

# Funktion: Aktuellen Status anzeigen
function Show-SignToolStatus {
    $content = Get-Content $issFile -Raw
    
    Write-Host "📋 Aktueller Status:" -ForegroundColor Yellow
    Write-Host ""
    
    if ($content -match '^SignTool=(?!;)(.+)$' -and $content -notmatch '^;\s*SignTool=') {
        Write-Host "  ✅ Code-Signierung: AKTIVIERT" -ForegroundColor Green
        
        # Extrahiere SignTool-Zeile
        $signToolLine = ($content -split "`n" | Where-Object { $_ -match '^SignTool=' })[0]
        Write-Host "  📝 Konfiguration:" -ForegroundColor Gray
        Write-Host "     $signToolLine" -ForegroundColor Gray
    }
    else {
        Write-Host "  ❌ Code-Signierung: DEAKTIVIERT" -ForegroundColor Yellow
        Write-Host "     (SignTool-Zeilen sind auskommentiert)" -ForegroundColor Gray
    }
    
    Write-Host ""
}

# Funktion: Code-Signierung aktivieren
function Enable-SignTool {
    param([string]$Thumbprint, [string]$Subject)
    
    $content = Get-Content $issFile -Raw
    
    Write-Host "🔧 Aktiviere Code-Signierung..." -ForegroundColor Yellow
    Write-Host ""
    
    # Bestimme SignTool-Befehl
    if ($Thumbprint) {
        Write-Host "  📌 Verwende Zertifikat mit Thumbprint: $Thumbprint" -ForegroundColor Cyan
        $signToolCmd = "SignTool=signtool sign /sha1 `$q${Thumbprint}`$q /fd SHA256 /tr http://timestamp.digicert.com /td SHA256 `$f"
    }
    else {
        Write-Host "  📌 Verwende Zertifikat mit Subject: $Subject" -ForegroundColor Cyan
        $signToolCmd = "SignTool=signtool sign /n `$q${Subject}`$q /fd SHA256 /tr http://timestamp.digicert.com /td SHA256 `$f"
    }
    
    # Prüfe ob Zertifikat existiert
    $cert = $null
    if ($Thumbprint) {
        $cert = Get-ChildItem Cert:\CurrentUser\My | Where-Object { $_.Thumbprint -eq $Thumbprint }
    }
    else {
        $cert = Get-ChildItem Cert:\CurrentUser\My -CodeSigningCert | Where-Object { $_.Subject -like "*$Subject*" }
    }
    
    if (-not $cert) {
        Write-Host ""
        Write-Host "⚠️  WARNUNG: Zertifikat nicht gefunden!" -ForegroundColor Yellow
        Write-Host "   Die SignTool-Konfiguration wird trotzdem aktiviert," -ForegroundColor Gray
        Write-Host "   aber der Build wird fehlschlagen, wenn kein Zertifikat vorhanden ist." -ForegroundColor Gray
        Write-Host ""
        
        $continue = Read-Host "Trotzdem fortfahren? (j/N)"
        if ($continue -ne 'j' -and $continue -ne 'J') {
            Write-Host "Abgebrochen." -ForegroundColor Yellow
            exit 0
        }
    }
    else {
        Write-Host ""
        Write-Host "  ✅ Zertifikat gefunden:" -ForegroundColor Green
        Write-Host "     Subject: $($cert.Subject)" -ForegroundColor Gray
        Write-Host "     Thumbprint: $($cert.Thumbprint)" -ForegroundColor Gray
        Write-Host "     Gültig bis: $($cert.NotAfter)" -ForegroundColor Gray
        Write-Host ""
    }
    
    # Ersetze die kommentierten SignTool-Zeilen
    $newContent = $content -replace '(?m)^;\s*SignTool=.*$', $signToolCmd
    $newContent = $newContent -replace '(?m)^;\s*SignToolRunMinimized=yes', 'SignToolRunMinimized=yes'
    
    # Speichere
    $newContent | Set-Content $issFile -NoNewline
    
    Write-Host "✅ Code-Signierung aktiviert!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Der Setup.exe wird automatisch beim Build signiert." -ForegroundColor White
    Write-Host ""
}

# Funktion: Code-Signierung deaktivieren
function Disable-SignTool {
    $content = Get-Content $issFile -Raw
    
    Write-Host "🔧 Deaktiviere Code-Signierung..." -ForegroundColor Yellow
    Write-Host ""
    
    # Kommentiere SignTool-Zeilen aus
    $newContent = $content -replace '(?m)^SignTool=(.*)$', '; SignTool=$1'
    $newContent = $newContent -replace '(?m)^SignToolRunMinimized=yes', '; SignToolRunMinimized=yes'
    
    # Speichere
    $newContent | Set-Content $issFile -NoNewline
    
    Write-Host "✅ Code-Signierung deaktiviert!" -ForegroundColor Green
    Write-Host ""
}

# Hauptlogik
if ($ShowStatus -or (-not $Enable -and -not $Disable)) {
    Show-SignToolStatus
    
    if (-not $Enable -and -not $Disable) {
        Write-Host "Verwendung:" -ForegroundColor Cyan
        Write-Host "  .\Configure-SignTool.ps1 -Enable                    # Aktiviert mit Standard-Zertifikat" -ForegroundColor White
        Write-Host "  .\Configure-SignTool.ps1 -Enable -CertificateSubject 'Mein Cert'  # Mit spezifischem Subject" -ForegroundColor White
        Write-Host "  .\Configure-SignTool.ps1 -Enable -CertificateThumbprint 'ABC123...'  # Mit Thumbprint" -ForegroundColor White
        Write-Host "  .\Configure-SignTool.ps1 -Disable                   # Deaktiviert Code-Signierung" -ForegroundColor White
        Write-Host "  .\Configure-SignTool.ps1 -ShowStatus                # Zeigt aktuellen Status" -ForegroundColor White
        Write-Host ""
    }
}
elseif ($Enable) {
    Enable-SignTool -Thumbprint $CertificateThumbprint -Subject $CertificateSubject
    Show-SignToolStatus
}
elseif ($Disable) {
    Disable-SignTool
    Show-SignToolStatus
}

Write-Host "Tipp: Verwenden Sie Build-SignedInstaller.ps1 für den kompletten Build-Prozess." -ForegroundColor Cyan
Write-Host ""

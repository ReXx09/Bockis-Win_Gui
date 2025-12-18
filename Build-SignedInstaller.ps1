# Build-SignedInstaller.ps1
# Automatisches Build-Skript mit Code-Signierung
# Autor: Bocki
# Version: 1.0
# 
# Dieses Skript:
# 1. Erstellt oder nutzt ein Code-Signing-Zertifikat
# 2. Signiert alle PowerShell-Dateien (*.ps1, *.psm1)
# 3. Erstellt den Installer mit Inno Setup
# 4. Optional: Signiert auch den Installer selbst

param(
    [switch]$CreateCertificate,
    [switch]$SkipSigning,
    [switch]$SignInstaller,
    [switch]$EnableSignToolInISS,  # Aktiviert SignTool direkt in installer.iss
    [switch]$Verbose
)

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  🚀 Build-Prozess: Bockis System-Tool v4.1" -ForegroundColor White
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# ============================================
# SCHRITT 1: CODE-SIGNIERUNG
# ============================================

if (-not $SkipSigning) {
    Write-Host "🔐 SCHRITT 1: Code-Signierung" -ForegroundColor Yellow
    Write-Host "──────────────────────────────────────────────────────────" -ForegroundColor Gray
    Write-Host ""
    
    # Führe Sign-AllScripts aus
    $signParams = @{}
    if ($CreateCertificate) { $signParams['CreateCertificate'] = $true }
    if ($Verbose) { $signParams['Verbose'] = $true }
    
    try {
        & "$PSScriptRoot\Sign-AllScripts.ps1" @signParams
        
        if ($LASTEXITCODE -ne 0 -and $null -ne $LASTEXITCODE) {
            throw "Code-Signierung fehlgeschlagen"
        }
        
        Write-Host ""
        Write-Host "✅ Code-Signierung abgeschlossen" -ForegroundColor Green
        Write-Host ""
    }
    catch {
        Write-Host "❌ Fehler bei der Code-Signierung: $_" -ForegroundColor Red
        Write-Host ""
        Write-Host "Tipp: Verwenden Sie -CreateCertificate um ein neues Zertifikat zu erstellen" -ForegroundColor Yellow
        exit 1
    }
}
else {
    Write-Host "⏭️  Code-Signierung übersprungen (-SkipSigning)" -ForegroundColor Yellow
    Write-Host ""
}

# ============================================
# SCHRITT 2: INSTALLER ERSTELLEN
# ============================================

Write-Host "📦 SCHRITT 2: Installer erstellen" -ForegroundColor Yellow
Write-Host "──────────────────────────────────────────────────────────" -ForegroundColor Gray
Write-Host ""

# Optional: SignTool in installer.iss aktivieren
if ($EnableSignToolInISS) {
    Write-Host "🔧 Aktiviere SignTool in installer.iss..." -ForegroundColor Cyan
    
    $cert = Get-ChildItem Cert:\CurrentUser\My -CodeSigningCert | Where-Object {
        $_.Subject -like "*Bocki*" -or $_.Subject -like "*Win_Gui*"
    } | Select-Object -First 1
    
    if ($cert) {
        & "$PSScriptRoot\Configure-SignTool.ps1" -Enable -CertificateThumbprint $cert.Thumbprint
        Write-Host "✅ SignTool aktiviert - Setup.exe wird automatisch signiert" -ForegroundColor Green
        Write-Host ""
    }
    else {
        Write-Host "⚠️  Kein Zertifikat gefunden - SignTool wird nicht aktiviert" -ForegroundColor Yellow
        Write-Host ""
    }
}

# Suche Inno Setup
$innoSetupPaths = @(
    "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe",
    "${env:ProgramFiles}\Inno Setup 6\ISCC.exe",
    "${env:ProgramFiles(x86)}\Inno Setup 5\ISCC.exe",
    "${env:ProgramFiles}\Inno Setup 5\ISCC.exe"
)

$iscc = $null
foreach ($path in $innoSetupPaths) {
    if (Test-Path $path) {
        $iscc = $path
        break
    }
}

if (-not $iscc) {
    Write-Host "❌ Inno Setup nicht gefunden!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Installieren Sie Inno Setup von:" -ForegroundColor Yellow
    Write-Host "  https://jrsoftware.org/isdl.php" -ForegroundColor White
    Write-Host ""
    exit 1
}

Write-Host "🔧 Verwende Inno Setup: $iscc" -ForegroundColor Gray
Write-Host ""

# Erstelle Installer
$issFile = Join-Path $PSScriptRoot "installer.iss"

if (-not (Test-Path $issFile)) {
    Write-Host "❌ installer.iss nicht gefunden!" -ForegroundColor Red
    exit 1
}

Write-Host "⚙️  Kompiliere Installer..." -ForegroundColor Cyan

try {
    $output = & $iscc $issFile 2>&1
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Inno Setup Fehler:" -ForegroundColor Red
        Write-Host $output -ForegroundColor Red
        exit 1
    }
    
    Write-Host $output -ForegroundColor Gray
    Write-Host ""
    Write-Host "✅ Installer erfolgreich erstellt" -ForegroundColor Green
    Write-Host ""
}
catch {
    Write-Host "❌ Fehler beim Erstellen des Installers: $_" -ForegroundColor Red
    exit 1
}

# ============================================
# SCHRITT 3: INSTALLER SIGNIEREN (Optional)
# ============================================

if ($SignInstaller) {
    Write-Host "🔐 SCHRITT 3: Installer signieren" -ForegroundColor Yellow
    Write-Host "──────────────────────────────────────────────────────────" -ForegroundColor Gray
    Write-Host ""
    
    # Finde den erstellten Installer
    $installerPattern = "Bockis-System-Tool-v*.exe"
    $installer = Get-ChildItem -Path $PSScriptRoot -Filter $installerPattern | 
                 Sort-Object LastWriteTime -Descending | 
                 Select-Object -First 1
    
    if ($installer) {
        Write-Host "📦 Signiere: $($installer.Name)" -ForegroundColor Cyan
        
        # Hole Code-Signing-Zertifikat
        $cert = Get-ChildItem Cert:\CurrentUser\My -CodeSigningCert | Where-Object {
            $_.Subject -like "*Bocki*" -or $_.Subject -like "*Win_Gui*"
        } | Select-Object -First 1
        
        if ($cert) {
            try {
                # Signiere den Installer
                $result = Set-AuthenticodeSignature `
                    -FilePath $installer.FullName `
                    -Certificate $cert `
                    -TimestampServer "http://timestamp.digicert.com" `
                    -HashAlgorithm SHA256 `
                    -ErrorAction Stop
                
                if ($result.Status -eq 'Valid') {
                    Write-Host "✅ Installer erfolgreich signiert" -ForegroundColor Green
                }
                else {
                    Write-Host "⚠️  Installer-Signierung Status: $($result.Status)" -ForegroundColor Yellow
                }
            }
            catch {
                Write-Host "❌ Fehler beim Signieren des Installers: $_" -ForegroundColor Red
            }
        }
        else {
            Write-Host "⚠️  Kein Code-Signing-Zertifikat gefunden" -ForegroundColor Yellow
        }
    }
    else {
        Write-Host "⚠️  Installer nicht gefunden" -ForegroundColor Yellow
    }
    
    Write-Host ""
}

# ============================================
# FERTIG
# ============================================

Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  ✅ Build-Prozess abgeschlossen!" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Finde und zeige den erstellten Installer
$installerPattern = "Bockis-System-Tool-v*.exe"
$installer = Get-ChildItem -Path $PSScriptRoot -Filter $installerPattern | 
             Sort-Object LastWriteTime -Descending | 
             Select-Object -First 1

if ($installer) {
    Write-Host "📦 Installer: $($installer.Name)" -ForegroundColor White
    Write-Host "   Größe: $([math]::Round($installer.Length / 1MB, 2)) MB" -ForegroundColor Gray
    Write-Host "   Pfad: $($installer.FullName)" -ForegroundColor Gray
    
    # Prüfe Signatur
    $sig = Get-AuthenticodeSignature -FilePath $installer.FullName
    if ($sig.Status -eq 'Valid') {
        Write-Host "   🔐 Signiert: ✅ Gültig" -ForegroundColor Green
        Write-Host "      Signatur: $($sig.SignerCertificate.Subject)" -ForegroundColor Gray
    }
    elseif ($sig.Status -eq 'NotSigned') {
        Write-Host "   🔓 Signiert: ❌ Nicht signiert" -ForegroundColor Yellow
    }
    else {
        Write-Host "   ⚠️  Signatur-Status: $($sig.Status)" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "Nächste Schritte:" -ForegroundColor Cyan
Write-Host "  1. Testen Sie den Installer auf einem sauberen System" -ForegroundColor White
Write-Host "  2. Prüfen Sie ob Windows Defender das Tool als sicher erkennt" -ForegroundColor White
Write-Host "  3. Optional: Scannen Sie auf VirusTotal (virustotal.com)" -ForegroundColor White
Write-Host ""

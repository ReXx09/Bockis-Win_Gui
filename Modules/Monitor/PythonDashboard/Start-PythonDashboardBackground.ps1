$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

function Resolve-LogRoot {
    param([string]$BaseDir)

    # Optional von der GUI uebergeben: expliziter Root fuer gemeinsame Logs.
    $envRoot = [Environment]::GetEnvironmentVariable('BOCKIS_GUI_ROOT', 'Process')
    if ([string]::IsNullOrWhiteSpace($envRoot)) {
        $envRoot = [Environment]::GetEnvironmentVariable('BOCKIS_GUI_ROOT', 'User')
    }
    if (-not [string]::IsNullOrWhiteSpace($envRoot)) {
        try {
            $resolvedEnvRoot = [System.IO.Path]::GetFullPath($envRoot)
            if (Test-Path $resolvedEnvRoot) {
                return $resolvedEnvRoot
            }
        }
        catch { }
    }

    # Nach oben laufen und nach Data\Logs suchen (GUI-Monorepo ODER eigenstaendiges Dashboard-Repo).
    $cursor = $BaseDir
    for ($i = 0; $i -lt 8; $i++) {
        if ([string]::IsNullOrWhiteSpace($cursor)) { break }

        $candidateDataRoot = Join-Path $cursor 'Data'
        if (Test-Path $candidateDataRoot) {
            return $cursor
        }

        $parent = Split-Path $cursor -Parent
        if ($parent -eq $cursor) { break }
        $cursor = $parent
    }

    # Fallback: lokales Data-Verzeichnis neben dem Dashboard-Projekt verwenden.
    return $BaseDir
}

$repoRoot = Resolve-LogRoot -BaseDir $scriptDir
$logDir = Join-Path $repoRoot 'Data\Logs'
if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}

$stdoutLog = Join-Path $logDir "python_dashboard_stdout.log"
$stderrLog = Join-Path $logDir "python_dashboard_stderr.log"

function Test-PortOpen {
    param([int]$Port)
    try {
        $client = New-Object System.Net.Sockets.TcpClient
        $iar = $client.BeginConnect('127.0.0.1', $Port, $null, $null)
        $ok = $iar.AsyncWaitHandle.WaitOne(250)
        if ($ok -and $client.Connected) {
            $client.EndConnect($iar) | Out-Null
            $client.Close()
            return $true
        }
        $client.Close()
    } catch { }
    return $false
}

function Get-PythonRunner {
    $candidates = @()

    $py = Get-Command py -ErrorAction SilentlyContinue
    if ($py) {
        foreach ($versionArg in @('-3.14', '-3.13', '-3.12', '-3.11', '-3.10', '-3')) {
            $candidates += @{ Cmd = 'py'; Prefix = @($versionArg) }
        }
    }

    $python = Get-Command python -ErrorAction SilentlyContinue
    if ($python) {
        $path = [string]$python.Source
        if ($path -and ($path -notmatch 'WindowsApps\\python\.exe$')) {
            $candidates += @{ Cmd = $path; Prefix = @() }
            $candidates += @{ Cmd = 'python'; Prefix = @() }
        }
    }

    $pathPatterns = @(
        (Join-Path $env:LOCALAPPDATA 'Programs\Python\Python*\python.exe'),
        (Join-Path $env:ProgramFiles 'Python*\python.exe'),
        (Join-Path ${env:ProgramFiles(x86)} 'Python*\python.exe'),
        'C:\Python*\python.exe'
    )

    foreach ($pattern in $pathPatterns) {
        if ([string]::IsNullOrWhiteSpace($pattern)) { continue }
        try {
            Get-ChildItem -Path $pattern -File -ErrorAction SilentlyContinue |
                Sort-Object FullName -Descending |
                ForEach-Object {
                    $candidatePath = [string]$_.FullName
                    if ($candidatePath -and ($candidatePath -notmatch 'WindowsApps\\python\.exe$')) {
                        $candidates += @{ Cmd = $candidatePath; Prefix = @() }
                    }
                }
        } catch { }
    }

    foreach ($cand in $candidates) {
        try {
            $out = (& $cand.Cmd @($cand.Prefix + @('--version')) 2>&1 | Out-String).Trim()
            if ($LASTEXITCODE -ne 0 -or $out -notmatch 'Python\s+(\d+)\.(\d+)') {
                continue
            }

            $major = [int]$matches[1]
            $minor = [int]$matches[2]
            if ($major -lt 3 -or ($major -eq 3 -and $minor -lt 10)) {
                continue
            }

            return @{ Cmd = [string]$cand.Cmd; Prefix = @($cand.Prefix) }
        } catch { }
    }

    return $null
}

if (Test-PortOpen -Port 9500) {
    exit 0
}

$runner = Get-PythonRunner
if (-not $runner) {
    "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Kein gueltiger Python-Interpreter gefunden." | Out-File -FilePath $stderrLog -Append -Encoding utf8
    exit 1
}

Set-Location $scriptDir

$checkArgs = @($runner.Prefix + @('-c', 'import fastapi, uvicorn, psutil, comtypes, pycaw'))
& $runner.Cmd @checkArgs 2>$null 1>$null
if ($LASTEXITCODE -ne 0) {
    $reqPath = Join-Path $scriptDir 'requirements.txt'
    if (Test-Path $reqPath) {
        $installArgs = @($runner.Prefix + @('-m', 'pip', 'install', '-r', $reqPath))
        & $runner.Cmd @installArgs 2>>$stderrLog 1>>$stdoutLog
        if ($LASTEXITCODE -ne 0) {
            exit 1
        }
    }
}

$uvicornArgs = @($runner.Prefix + @('-m', 'uvicorn', 'app:app', '--host', '127.0.0.1', '--port', '9500'))
Start-Process -FilePath $runner.Cmd -ArgumentList $uvicornArgs -WorkingDirectory $scriptDir -WindowStyle Hidden -RedirectStandardOutput $stdoutLog -RedirectStandardError $stderrLog | Out-Null
exit 0

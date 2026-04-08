$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path (Split-Path (Split-Path $scriptDir -Parent) -Parent) -Parent
$logDir = Join-Path $repoRoot "Data\Logs"
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
    $py = Get-Command py -ErrorAction SilentlyContinue
    if ($py) {
        try {
            $out = (& py -3 --version 2>&1 | Out-String).Trim()
            if ($LASTEXITCODE -eq 0 -and $out -match 'Python') {
                return @{ Cmd = 'py'; Prefix = @('-3') }
            }
        } catch { }
    }

    $python = Get-Command python -ErrorAction SilentlyContinue
    if ($python) {
        $path = [string]$python.Source
        if ($path -and ($path -notmatch 'WindowsApps\\python\.exe$')) {
            try {
                $out = (& python --version 2>&1 | Out-String).Trim()
                if ($LASTEXITCODE -eq 0 -and $out -match 'Python') {
                    return @{ Cmd = 'python'; Prefix = @() }
                }
            } catch { }
        }
    }

    return $null
}

if (Test-PortOpen -Port 8083) {
    exit 0
}

$runner = Get-PythonRunner
if (-not $runner) {
    "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Kein gueltiger Python-Interpreter gefunden." | Out-File -FilePath $stderrLog -Append -Encoding utf8
    exit 1
}

Set-Location $scriptDir

$checkArgs = @($runner.Prefix + @('-c', 'import fastapi, uvicorn, psutil'))
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

$uvicornArgs = @($runner.Prefix + @('-m', 'uvicorn', 'app:app', '--host', '127.0.0.1', '--port', '8083'))
Start-Process -FilePath $runner.Cmd -ArgumentList $uvicornArgs -WorkingDirectory $scriptDir -WindowStyle Hidden -RedirectStandardOutput $stdoutLog -RedirectStandardError $stderrLog | Out-Null
exit 0

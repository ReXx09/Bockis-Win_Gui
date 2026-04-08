# Modules/Monitor/WebDashboard.psm1
# Lokales Web-Dashboard (127.0.0.1 only) fuer Live-Ausgabe und Log-Viewer
# Kein externes Framework noetig - nutzt nur System.Net.HttpListener

$script:State = $null

# ---------------------------------------------------------------------------
function Start-WebDashboard {
    [CmdletBinding()]
    param(
        [int]$Port    = 8080,
        [string]$LogPath = ""
    )

    if ($script:State -and $script:State.Running) {
        return @{ Success = $false; Message = "Laeuft bereits auf Port $($script:State.Port)"; Url = "http://127.0.0.1:$($script:State.Port)" }
    }

    if (-not $LogPath) {
        $LogPath = Join-Path $PSScriptRoot "..\..\Data\Logs"
    }

    $activePorts = @{}
    try {
        [System.Net.NetworkInformation.IPGlobalProperties]::GetIPGlobalProperties().GetActiveTcpListeners() |
            ForEach-Object { $activePorts[$_.Port] = $true }
    } catch { }

    $selectedPort = $null
    foreach ($candidate in $Port..($Port + 10)) {
        if (-not $activePorts.ContainsKey($candidate)) {
            $selectedPort = $candidate
            break
        }
    }
    if (-not $selectedPort) {
        return @{ Success = $false; Message = "Kein freier Port im Bereich $Port-$($Port + 10) gefunden." }
    }

    $Port = $selectedPort

    $html  = Get-DashboardHtml
    $js    = Get-DashboardScript
    $state = [hashtable]::Synchronized(@{
        Running      = $true
        Port         = $Port
        LogPath      = $LogPath
      WebRoot      = (Join-Path $PSScriptRoot "web")
            RepoRoot     = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
        OutputBuffer = $global:WebOutputBuffer   # Referenz auf den gemeinsamen Buffer
        Html         = $html
      Script       = $js
    StartupError = $null
        Listener     = $null
        PS           = $null
        RS           = $null
    })

    $script:State = $state

    # HTTP-Server-Logik (laeuft in eigenem Runspace)
    $serverBlock = {
        param($s)

        $listener = [System.Net.HttpListener]::new()
        $listener.Prefixes.Add("http://127.0.0.1:$($s.Port)/")
        try {
            $listener.Start()
        } catch {
            $s.Running = $false
            $s.StartupError = $_.Exception.Message
            return
        }
        $s.Listener = $listener

        while ($s.Running) {
            try {
                $ctx  = $listener.GetContext()
                $req  = $ctx.Request
                $res  = $ctx.Response
                $path = $req.Url.LocalPath.TrimEnd('/')
                if (-not $path) { $path = '/' }

                try {
                    function Invoke-Git {
                        param(
                            [hashtable]$ServerState,
                            [string[]]$GitArgs
                        )

                        $resultLines = @(& git -C $ServerState.RepoRoot @GitArgs 2>&1)
                        return [pscustomobject]@{
                            ExitCode = $LASTEXITCODE
                            Output   = ($resultLines -join "`n")
                        }
                    }

                    if ($path -eq '/' -or $path -eq '') {
                      # Dashboard HTML (externes File bevorzugt, fallback eingebettet)
                      $htmlPath = Join-Path $s.WebRoot "dashboard.html"
                      if (Test-Path $htmlPath) {
                        $content = Get-Content -Path $htmlPath -Raw -Encoding UTF8
                      } else {
                        $content = $s.Html
                      }

                      $bytes = [System.Text.Encoding]::UTF8.GetBytes($content)
                        $res.ContentType      = "text/html; charset=utf-8"
                        $res.ContentLength64  = $bytes.Length
                        $res.OutputStream.Write($bytes, 0, $bytes.Length)
                    }
                    elseif ($path -eq '/assets/dashboard.js') {
                      # Dashboard JavaScript (externes File bevorzugt, fallback eingebettet)
                      $jsPath = Join-Path $s.WebRoot "dashboard.js"
                      if (Test-Path $jsPath) {
                        $content = Get-Content -Path $jsPath -Raw -Encoding UTF8
                      } else {
                        $content = $s.Script
                      }

                      $bytes = [System.Text.Encoding]::UTF8.GetBytes($content)
                      $res.ContentType      = "application/javascript; charset=utf-8"
                      $res.ContentLength64  = $bytes.Length
                      $res.OutputStream.Write($bytes, 0, $bytes.Length)
                    }
                    elseif ($path -eq '/api/output') {
                        # Live-Ausgabe - Eintraege seit 'since' (Epoch-ms)
                        $since = [long]0
                        try { if ($req.QueryString["since"]) { $since = [long]($req.QueryString["since"]) } } catch { }

                        $resultEntries = @()
                        $lastTs        = $since

                        if ($s.OutputBuffer) {
                            $all      = $s.OutputBuffer.ToArray()
                            $filtered = @($all | Where-Object { $null -ne $_ -and $null -ne $_.ts -and [long]$_.ts -gt $since })
                            if ($filtered.Count -gt 0) {
                                $resultEntries = $filtered
                                $lastTs        = [long]$filtered[-1].ts
                            }
                        }

                        $json  = ConvertTo-Json @{ entries = @($resultEntries); lastTimestamp = $lastTs } -Depth 4 -Compress
                        $bytes = [System.Text.Encoding]::UTF8.GetBytes($json)
                        $res.ContentType     = "application/json; charset=utf-8"
                        $res.ContentLength64 = $bytes.Length
                        $res.OutputStream.Write($bytes, 0, $bytes.Length)
                    }
                    elseif ($path -eq '/api/logs') {
                        # Liste der Log-Dateien
                        $files = @()
                        if (Test-Path $s.LogPath) {
                            $files = @(Get-ChildItem -Path $s.LogPath -Filter "*.log" -ErrorAction SilentlyContinue |
                                Sort-Object LastWriteTime -Descending |
                                Select-Object -First 20 |
                                ForEach-Object {
                                    @{ name = $_.Name; size = $_.Length; modified = $_.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss") }
                                })
                        }
                        $json  = ConvertTo-Json $files -Depth 3 -Compress
                        $bytes = [System.Text.Encoding]::UTF8.GetBytes($json)
                        $res.ContentType     = "application/json; charset=utf-8"
                        $res.ContentLength64 = $bytes.Length
                        $res.OutputStream.Write($bytes, 0, $bytes.Length)
                    }
                    elseif ($path -eq '/api/logs/content') {
                        # Inhalt einer Log-Datei (letzte 300 Zeilen)
                        $fname = $req.QueryString["file"]
                        # Sicherheit: nur alphanumerisch + Bindestrich/Unterstrich + .log
                        if ($fname -and $fname -match '^[\w][\w\-]*\.log$') {
                            $fpath = Join-Path $s.LogPath $fname
                            if (Test-Path $fpath) {
                                $lines = @(Get-Content $fpath -Encoding UTF8 -Tail 300 -ErrorAction SilentlyContinue)
                                $json  = ConvertTo-Json @{ lines = $lines; file = $fname } -Depth 3 -Compress
                            } else {
                                $res.StatusCode = 404
                                $json = '{"error":"Datei nicht gefunden"}'
                            }
                        } else {
                            $res.StatusCode = 400
                            $json = '{"error":"Ungueltiger Dateiname"}'
                        }
                        $bytes = [System.Text.Encoding]::UTF8.GetBytes($json)
                        $res.ContentType     = "application/json; charset=utf-8"
                        $res.ContentLength64 = $bytes.Length
                        $res.OutputStream.Write($bytes, 0, $bytes.Length)
                    }
                    elseif ($path -eq '/api/status') {
                        $json  = ConvertTo-Json @{ running = $true; port = $s.Port } -Compress
                        $bytes = [System.Text.Encoding]::UTF8.GetBytes($json)
                        $res.ContentType     = "application/json; charset=utf-8"
                        $res.ContentLength64 = $bytes.Length
                        $res.OutputStream.Write($bytes, 0, $bytes.Length)
                    }
                    elseif ($path -eq '/api/git/status') {
                        $statusPayload = @{ 
                            available = $false
                            repoPath = $s.RepoRoot
                            branch = ""
                            upstream = ""
                            ahead = 0
                            behind = 0
                            dirty = 0
                            remote = ""
                            message = ""
                        }

                        if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
                            $statusPayload.message = "Git ist nicht installiert oder nicht im PATH verfügbar."
                        } else {
                            $insideRepo = Invoke-Git -ServerState $s -GitArgs @('rev-parse', '--is-inside-work-tree')
                            if ($insideRepo.ExitCode -ne 0 -or -not ($insideRepo.Output -match 'true')) {
                                $statusPayload.message = "Aktueller Pfad ist kein Git-Repository."
                            } else {
                                $statusPayload.available = $true

                                $branchInfo = Invoke-Git -ServerState $s -GitArgs @('rev-parse', '--abbrev-ref', 'HEAD')
                                if ($branchInfo.ExitCode -eq 0) {
                                    $statusPayload.branch = ($branchInfo.Output -split "`n")[0].Trim()
                                }

                                $remoteInfo = Invoke-Git -ServerState $s -GitArgs @('remote')
                                if ($remoteInfo.ExitCode -eq 0 -and $remoteInfo.Output.Trim()) {
                                    $statusPayload.remote = (($remoteInfo.Output -split "`n")[0]).Trim()
                                }

                                $dirtyInfo = Invoke-Git -ServerState $s -GitArgs @('status', '--porcelain')
                                if ($dirtyInfo.ExitCode -eq 0 -and $dirtyInfo.Output.Trim()) {
                                    $statusPayload.dirty = (@($dirtyInfo.Output -split "`n" | Where-Object { $_.Trim() })).Count
                                }

                                $upstreamInfo = Invoke-Git -ServerState $s -GitArgs @('rev-parse', '--abbrev-ref', '--symbolic-full-name', '@{u}')
                                if ($upstreamInfo.ExitCode -eq 0 -and $upstreamInfo.Output.Trim()) {
                                    $statusPayload.upstream = ($upstreamInfo.Output -split "`n")[0].Trim()
                                    $aheadBehind = Invoke-Git -ServerState $s -GitArgs @('rev-list', '--left-right', '--count', 'HEAD...@{u}')
                                    if ($aheadBehind.ExitCode -eq 0 -and $aheadBehind.Output.Trim()) {
                                        $counts = (($aheadBehind.Output -split "`n")[0].Trim() -split "\s+")
                                        if ($counts.Count -ge 2) {
                                            $statusPayload.behind = [int]$counts[0]
                                            $statusPayload.ahead = [int]$counts[1]
                                        }
                                    }
                                } else {
                                    $statusPayload.message = "Kein Upstream konfiguriert (Pull trotzdem mit Remote/Branch möglich)."
                                }
                            }
                        }

                        $json  = ConvertTo-Json $statusPayload -Depth 4 -Compress
                        $bytes = [System.Text.Encoding]::UTF8.GetBytes($json)
                        $res.ContentType     = "application/json; charset=utf-8"
                        $res.ContentLength64 = $bytes.Length
                        $res.OutputStream.Write($bytes, 0, $bytes.Length)
                    }
                    elseif ($path -eq '/api/git/pull') {
                        if ($req.HttpMethod -ne 'POST') {
                            $res.StatusCode = 405
                            $json = '{"success":false,"message":"Nur POST erlaubt"}'
                            $bytes = [System.Text.Encoding]::UTF8.GetBytes($json)
                            $res.ContentType     = "application/json; charset=utf-8"
                            $res.ContentLength64 = $bytes.Length
                            $res.OutputStream.Write($bytes, 0, $bytes.Length)
                        } else {
                            $result = @{ success = $false; message = ""; output = "" }

                            if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
                                $result.message = "Git ist nicht installiert oder nicht im PATH verfügbar."
                            } else {
                                $insideRepo = Invoke-Git -ServerState $s -GitArgs @('rev-parse', '--is-inside-work-tree')
                                if ($insideRepo.ExitCode -ne 0 -or -not ($insideRepo.Output -match 'true')) {
                                    $result.message = "Aktueller Pfad ist kein Git-Repository."
                                } else {
                                    $remote = 'origin'
                                    $branch = ''

                                    try {
                                        $reader = New-Object System.IO.StreamReader($req.InputStream, $req.ContentEncoding)
                                        $body = $reader.ReadToEnd()
                                        $reader.Close()

                                        if ($body -and $body.Trim()) {
                                            $payload = $body | ConvertFrom-Json -ErrorAction Stop
                                            if ($payload.remote) { $remote = [string]$payload.remote }
                                            if ($payload.branch) { $branch = [string]$payload.branch }
                                        }
                                    } catch {
                                        # Fallback auf Defaults
                                    }

                                    if (-not $branch) {
                                        $branchInfo = Invoke-Git -ServerState $s -GitArgs @('rev-parse', '--abbrev-ref', 'HEAD')
                                        if ($branchInfo.ExitCode -eq 0 -and $branchInfo.Output.Trim()) {
                                            $branch = ($branchInfo.Output -split "`n")[0].Trim()
                                        }
                                    }

                                    if (-not $branch) {
                                        $result.message = "Konnte Ziel-Branch nicht ermitteln."
                                    } else {
                                        $dirtyInfo = Invoke-Git -ServerState $s -GitArgs @('status', '--porcelain')
                                        if ($dirtyInfo.ExitCode -eq 0 -and $dirtyInfo.Output.Trim()) {
                                            $result.message = "Lokale Änderungen vorhanden. Bitte zuerst committen/stashen, dann Pull erneut ausführen."
                                            $result.output = $dirtyInfo.Output
                                        } else {
                                            $pullResult = Invoke-Git -ServerState $s -GitArgs @('pull', '--ff-only', $remote, $branch)
                                            if ($pullResult.ExitCode -eq 0) {
                                                $result.success = $true
                                                $result.message = "Pull erfolgreich von $remote/$branch"
                                                $result.output = $pullResult.Output
                                            } else {
                                                $result.message = "Pull fehlgeschlagen."
                                                $result.output = $pullResult.Output
                                            }
                                        }
                                    }
                                }
                            }

                            $json  = ConvertTo-Json $result -Depth 4 -Compress
                            $bytes = [System.Text.Encoding]::UTF8.GetBytes($json)
                            $res.ContentType     = "application/json; charset=utf-8"
                            $res.ContentLength64 = $bytes.Length
                            $res.OutputStream.Write($bytes, 0, $bytes.Length)
                        }
                    }
                    else {
                        $res.StatusCode = 404
                        $bytes = [System.Text.Encoding]::UTF8.GetBytes("404 Not Found")
                        $res.ContentLength64 = $bytes.Length
                        $res.OutputStream.Write($bytes, 0, $bytes.Length)
                    }
                }
                catch {
                    try { $res.StatusCode = 500 } catch { }
                }
                finally {
                    try { $res.OutputStream.Close() } catch { }
                }
            }
            catch {
                if (-not $s.Running) { break }
                # Listener-Fehler nicht hart eskalieren; Schleife bleibt aktiv.
            }
        }

        try { $listener.Stop(); $listener.Close() } catch { }
    }

    $rs = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspace()
    $rs.ApartmentState  = "STA"
    $rs.ThreadOptions   = "UseNewThread"
    $rs.Open()

    $ps = [PowerShell]::Create()
    $ps.Runspace = $rs
    [void]$ps.AddScript($serverBlock).AddArgument($state)
    $handle = $ps.BeginInvoke()

    $state.PS     = $ps
    $state.Handle = $handle
    $state.RS     = $rs

    Start-Sleep -Milliseconds 400

    if (-not $state.Running -or -not $state.Listener) {
        $err = if ($state.StartupError) { $state.StartupError } else { "Unbekannter Fehler beim Start des Web-Dashboards." }
        try { $state.PS.Dispose() } catch { }
        try { $state.RS.Close(); $state.RS.Dispose() } catch { }
        $script:State = $null
        return @{ Success = $false; Message = "Start fehlgeschlagen: $err" }
    }

    return @{ Success = $true; Url = "http://127.0.0.1:$Port"; Port = $Port }
}

# ---------------------------------------------------------------------------
function Stop-WebDashboard {
    if (-not $script:State) { return }
    $script:State.Running = $false
    try { $script:State.Listener.Stop()   } catch { }
    try { $script:State.Listener.Close()  } catch { }
    Start-Sleep -Milliseconds 300
    try { $script:State.PS.Dispose()      } catch { }
    try { $script:State.RS.Close(); $script:State.RS.Dispose() } catch { }
    $script:State = $null
}

# ---------------------------------------------------------------------------
function Get-WebDashboardStatus {
    if ($script:State -and $script:State.Running) {
        return @{ Running = $true; Url = "http://127.0.0.1:$($script:State.Port)"; Port = $script:State.Port }
    }
    return @{ Running = $false }
}

# ---------------------------------------------------------------------------
function Get-DashboardHtml {
    # Fallback-HTML falls externe Datei nicht vorhanden ist.
    return @'
<!DOCTYPE html>
<html lang="de">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Bockis System-Tool - Dashboard</title>
</head>
<body style="font-family:Segoe UI,Tahoma,sans-serif;background:#0d1117;color:#e6edf3;padding:24px;line-height:1.5">
<h2 style="margin:0 0 12px 0">Web-Dashboard Fallback</h2>
<p style="margin:0 0 8px 0">Die externen Dateien konnten nicht geladen werden.</p>
<p style="margin:0 0 12px 0">Erwartet:</p>
<ul style="margin:0 0 16px 20px">
    <li>Modules/Monitor/web/dashboard.html</li>
    <li>Modules/Monitor/web/dashboard.js</li>
</ul>
<p style="margin:0">Wenn diese Dateien vorhanden sind, Browser einmal neu laden.</p>
<script src="/assets/dashboard.js"></script>
</body>
</html>
'@
}

# ---------------------------------------------------------------------------
function Get-DashboardScript {
    # Fallback-JS falls externe Datei nicht vorhanden ist.
    return @'
console.warn("Fallback dashboard.js aktiv. Externe Datei fehlt: Modules/Monitor/web/dashboard.js");
'@
}

Export-ModuleMember -Function Start-WebDashboard, Stop-WebDashboard, Get-WebDashboardStatus

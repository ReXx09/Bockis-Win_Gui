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

    $html  = Get-DashboardHtml
    $js    = Get-DashboardScript
    $state = [hashtable]::Synchronized(@{
        Running      = $true
        Port         = $Port
        LogPath      = $LogPath
      WebRoot      = (Join-Path $PSScriptRoot "web")
        OutputBuffer = $global:WebOutputBuffer   # Referenz auf den gemeinsamen Buffer
        Html         = $html
      Script       = $js
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
            return
        }
        $s.Listener = $listener

        while ($s.Running) {
            try {
                $task = $listener.GetContextAsync()
                if (-not $task.Wait(800)) { continue }
                if (-not $s.Running) { break }

                $ctx  = $task.Result
                $req  = $ctx.Request
                $res  = $ctx.Response
                $path = $req.Url.LocalPath.TrimEnd('/')
                if (-not $path) { $path = '/' }

                try {
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
                            $filtered = @($all | Where-Object { $null -ne $_ -and $_.ts -gt $since })
                            if ($filtered.Count -gt 0) {
                                $resultEntries = $filtered
                                $lastTs        = ($filtered | Measure-Object -Property ts -Maximum).Maximum
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
                Start-Sleep -Milliseconds 100
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
<body>
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

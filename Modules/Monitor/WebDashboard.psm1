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
    $state = [hashtable]::Synchronized(@{
        Running      = $true
        Port         = $Port
        LogPath      = $LogPath
        OutputBuffer = $global:WebOutputBuffer   # Referenz auf den gemeinsamen Buffer
        Html         = $html
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
                        # Dashboard HTML
                        $bytes = [System.Text.Encoding]::UTF8.GetBytes($s.Html)
                        $res.ContentType      = "text/html; charset=utf-8"
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
    # Eingebettetes HTML/CSS/JS - single-quoted here-string (kein PS-Expansion)
    return @'
<!DOCTYPE html>
<html lang="de">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Bockis System-Tool &#8212; Dashboard</title>
<style>
*{box-sizing:border-box;margin:0;padding:0}
body{background:#1E1E1E;color:#CCC;font-family:'Segoe UI',Tahoma,sans-serif;font-size:13px;height:100vh;display:flex;flex-direction:column;overflow:hidden}
#hdr{background:#141414;padding:7px 14px;display:flex;align-items:center;justify-content:space-between;border-bottom:1px solid #2A2A2A;flex-shrink:0}
#hdr h1{font-size:14px;color:#EFEFEF;font-weight:600;letter-spacing:.02em}
#hdr .sub{color:#666;font-size:11px}
#dot{display:inline-block;width:8px;height:8px;border-radius:50%;background:#3DDC84;margin-right:8px;box-shadow:0 0 5px #3DDC84}
#main{display:flex;flex:1;overflow:hidden}
#sidebar{width:210px;background:#191919;border-right:1px solid #282828;display:flex;flex-direction:column;flex-shrink:0}
#sidebar h2{padding:7px 11px;font-size:10px;text-transform:uppercase;letter-spacing:.08em;color:#555;border-bottom:1px solid #242424}
#log-list{flex:1;overflow-y:auto}
.litem{padding:6px 11px;cursor:pointer;border-bottom:1px solid #212121;transition:background .12s}
.litem:hover{background:#232323}
.litem.sel{background:#1B321B;border-left:3px solid #3DDC84}
.litem .n{color:#CCC;font-size:12px;word-break:break-all}
.litem .m{color:#4A4A4A;font-size:10px;margin-top:2px}
#content{flex:1;display:flex;flex-direction:column;overflow:hidden;min-height:0}
.ph{padding:5px 12px;background:#191919;border-bottom:1px solid #242424;display:flex;align-items:center;justify-content:space-between;flex-shrink:0}
.ph h3{font-size:10px;text-transform:uppercase;letter-spacing:.08em;color:#5A5A5A}
.ph .acts{display:flex;align-items:center;gap:6px}
.btn{background:#252525;border:1px solid #333;color:#999;padding:2px 9px;border-radius:3px;cursor:pointer;font-size:11px;font-family:inherit;transition:background .12s}
.btn:hover{background:#2E2E2E;color:#CCC}
.split-t{display:flex;flex-direction:column;overflow:hidden;min-height:80px}
.rz{height:5px;background:#1C1C1C;cursor:row-resize;border-top:1px solid #252525;border-bottom:1px solid #252525;flex-shrink:0;transition:background .15s}
.rz:hover,.rz.drag{background:#3DDC84}
.split-b{flex:1;display:flex;flex-direction:column;overflow:hidden;min-height:80px}
#live{flex:1;overflow-y:auto;padding:5px 8px;background:#161616;font-family:'Cascadia Code','Consolas',monospace;font-size:12px;line-height:1.55;min-height:0}
#logv{flex:1;overflow-y:auto;padding:5px 8px;background:#181818;font-family:'Cascadia Code','Consolas',monospace;font-size:12px;line-height:1.55;min-height:0}
.ln{padding:1px 0;word-break:break-word;white-space:pre-wrap}
.ln.Information,.ln.INFO{color:#64B5F6}
.ln.Success,.ln.SUCCESS{color:#3DDC84}
.ln.Warning,.ln.WARNING{color:#FFB74D}
.ln.Error,.ln.ERROR{color:#FF6B6B}
.ln.plain{color:#999}
.ts{color:#3A3A3A;font-size:10px;margin-right:5px;user-select:none}
.tb{display:inline-block;background:#222;color:#666;font-size:10px;padding:0 4px;border-radius:2px;margin-right:4px;font-family:'Segoe UI',sans-serif}
.empty{color:#3A3A3A;font-style:italic;padding:18px 12px;text-align:center;font-family:'Segoe UI',sans-serif}
.log-fname{color:#3DDC84;font-style:normal;margin-left:4px}
::-webkit-scrollbar{width:5px;height:5px}
::-webkit-scrollbar-track{background:#1A1A1A}
::-webkit-scrollbar-thumb{background:#2E2E2E;border-radius:3px}
::-webkit-scrollbar-thumb:hover{background:#3A3A3A}
label.ck{display:flex;align-items:center;gap:4px;cursor:pointer;color:#666;font-size:11px;user-select:none}
input[type=checkbox]{accent-color:#3DDC84}
</style>
</head>
<body>
<div id="hdr">
  <div style="display:flex;align-items:center"><span id="dot"></span><h1>Bockis System-Tool &mdash; Web&thinsp;Dashboard</h1></div>
  <div class="sub" id="sub">Verbunden &#8226; <span id="host-info"></span></div>
</div>
<div id="main">
  <div id="sidebar">
    <h2>Log-Dateien</h2>
    <div id="log-list"><div class="empty">Lade&#8230;</div></div>
  </div>
  <div id="content">
    <div class="split-t" id="split-t" style="height:50%">
      <div class="ph">
        <h3>&#9679;&ensp;Live-Ausgabe</h3>
        <div class="acts">
          <button class="btn" onclick="clearLive()">Leeren</button>
          <label class="ck"><input type="checkbox" id="asc" checked>Auto-Scroll</label>
        </div>
      </div>
      <div id="live"><div class="empty" id="livempty">Warte auf Ausgaben&#8230;</div></div>
    </div>
    <div class="rz" id="rz"></div>
    <div class="split-b">
      <div class="ph">
        <h3>Log-Datei<span class="log-fname" id="lfname"></span></h3>
        <div class="acts">
          <button class="btn" onclick="reloadLog()">Aktualisieren</button>
        </div>
      </div>
      <div id="logv"><div class="empty">Log-Datei links ausw&#228;hlen</div></div>
    </div>
  </div>
</div>
<script>
var lastTs=0, activeLog=null, pollTmr=null;
document.getElementById('host-info').textContent=location.host;

function init(){
  loadFiles();
  poll();
  initResizer();
  setInterval(loadFiles,15000);
}

function poll(){
  fetch('/api/output?since='+lastTs)
    .then(function(r){return r.json();})
    .then(function(d){
      if(d.entries&&d.entries.length){
        d.entries.forEach(addLine);
        lastTs=d.lastTimestamp;
      }
    }).catch(function(){})
    .finally(function(){pollTmr=setTimeout(poll,1500);});
}

function addLine(e){
  var c=document.getElementById('live');
  var em=document.getElementById('livempty');
  if(em)em.remove();
  var d=document.createElement('div');
  d.className='ln '+(e.level||'plain');
  var t=document.createElement('span');
  t.className='ts';
  t.textContent=new Date(e.ts).toLocaleTimeString('de-DE');
  d.appendChild(t);
  if(e.tool){var b=document.createElement('span');b.className='tb';b.textContent=e.tool;d.appendChild(b);}
  var m=document.createElement('span');m.textContent=e.msg||'';d.appendChild(m);
  c.appendChild(d);
  while(c.children.length>400)c.removeChild(c.firstChild);
  if(document.getElementById('asc').checked)c.scrollTop=c.scrollHeight;
}

function clearLive(){
  document.getElementById('live').innerHTML='<div class="empty" id="livempty">Live-Ausgabe geleert</div>';
}

function loadFiles(){
  fetch('/api/logs')
    .then(function(r){return r.json();})
    .then(function(files){
      var l=document.getElementById('log-list');
      if(!files||!files.length){l.innerHTML='<div class="empty">Keine Logs vorhanden</div>';return;}
      l.innerHTML='';
      files.forEach(function(f){
        var i=document.createElement('div');
        i.className='litem'+(activeLog===f.name?' sel':'');
        i.innerHTML='<div class="n">'+esc(f.name)+'</div><div class="m">'+f.modified+' &bull; '+fmtSz(f.size)+'</div>';
        i.onclick=function(){
          document.querySelectorAll('.litem').forEach(function(x){x.classList.remove('sel');});
          i.classList.add('sel');
          loadLog(f.name);
        };
        l.appendChild(i);
      });
      if(activeLog)loadLog(activeLog);
    }).catch(function(){});
}

function loadLog(name){
  activeLog=name;
  document.getElementById('lfname').textContent=name;
  fetch('/api/logs/content?file='+encodeURIComponent(name))
    .then(function(r){return r.json();})
    .then(function(d){
      var c=document.getElementById('logv');
      if(d.error){c.innerHTML='<div class="empty">'+esc(d.error)+'</div>';return;}
      c.innerHTML='';
      (d.lines||[]).forEach(function(l){
        var div=document.createElement('div');
        div.className='ln '+lvl(l);
        div.textContent=l;
        c.appendChild(div);
      });
      c.scrollTop=c.scrollHeight;
    }).catch(function(){});
}

function reloadLog(){if(activeLog)loadLog(activeLog);}

function lvl(l){
  if(l.indexOf('[ERROR]')!==-1)return'Error';
  if(l.indexOf('[WARN]')!==-1)return'Warning';
  if(l.indexOf('[SUCCESS]')!==-1)return'Success';
  if(l.indexOf('[INFO]')!==-1)return'Information';
  return'plain';
}

function esc(s){return String(s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;');}
function fmtSz(b){if(b<1024)return b+'B';if(b<1048576)return Math.round(b/1024)+'KB';return(b/1048576).toFixed(1)+'MB';}

function initResizer(){
  var rz=document.getElementById('rz');
  var top=document.getElementById('split-t');
  var content=document.getElementById('content');
  var drag=false,sy=0,sh=0;
  rz.addEventListener('mousedown',function(e){
    drag=true;sy=e.clientY;sh=top.offsetHeight;
    rz.classList.add('drag');
    document.body.style.cursor='row-resize';
    document.body.style.userSelect='none';
  });
  document.addEventListener('mousemove',function(e){
    if(!drag)return;
    var h=Math.max(80,Math.min(content.offsetHeight-100,sh+(e.clientY-sy)));
    top.style.height=h+'px';
    top.style.flex='none';
  });
  document.addEventListener('mouseup',function(){
    drag=false;rz.classList.remove('drag');
    document.body.style.cursor='';
    document.body.style.userSelect='';
  });
}

init();
</script>
</body>
</html>
'@
}

Export-ModuleMember -Function Start-WebDashboard, Stop-WebDashboard, Get-WebDashboardStatus

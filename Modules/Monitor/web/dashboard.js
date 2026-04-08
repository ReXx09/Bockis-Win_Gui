(function () {
  'use strict';

  var lastTs = 0;
  var activeLog = null;
  var pollTimer = null;

  function setTxt(id, value) {
    var el = document.getElementById(id);
    if (!el) return;
    el.textContent = value == null || value === '' ? '-' : String(value);
  }

  function setGitMessage(msg) {
    var el = document.getElementById('gitMsg');
    if (!el) return;
    el.textContent = msg || '';
  }

  function setActivePane(pane) {
    var labels = {
      overview: 'Live-Ausgabe und Systemstatus',
      logs: 'Log-Dateien und Inhalt'
    };

    document.querySelectorAll('[data-pane]').forEach(function (el) {
      el.classList.toggle('pane-hidden', el.getAttribute('data-pane') !== pane);
    });

    document.querySelectorAll('[data-pane-btn]').forEach(function (btn) {
      btn.classList.toggle('active', btn.getAttribute('data-pane-btn') === pane);
    });

    var sub = document.getElementById('headerSub');
    if (sub) {
      sub.textContent = labels[pane] || labels.overview;
    }

    localStorage.setItem('wingui-active-pane', pane);
  }

  function esc(s) {
    return String(s)
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;');
  }

  function fmtSz(b) {
    if (b < 1024) return b + 'B';
    if (b < 1048576) return Math.round(b / 1024) + 'KB';
    return (b / 1048576).toFixed(1) + 'MB';
  }

  function lvl(line) {
    if (line.indexOf('[ERROR]') !== -1) return 'Error';
    if (line.indexOf('[WARN]') !== -1) return 'Warning';
    if (line.indexOf('[SUCCESS]') !== -1) return 'Success';
    if (line.indexOf('[INFO]') !== -1) return 'Information';
    return 'plain';
  }

  function addLine(e) {
    var live = document.getElementById('live');
    var empty = document.getElementById('livempty');
    if (!live) return;
    if (empty) empty.remove();

    var d = document.createElement('div');
    d.className = 'ln ' + (e.level || 'plain');

    var t = document.createElement('span');
    t.className = 'ts';
    t.textContent = new Date(e.ts).toLocaleTimeString('de-DE');
    d.appendChild(t);

    if (e.tool) {
      var b = document.createElement('span');
      b.className = 'tb';
      b.textContent = e.tool;
      d.appendChild(b);
    }

    var m = document.createElement('span');
    m.textContent = e.msg || '';
    d.appendChild(m);

    live.appendChild(d);
    while (live.children.length > 500) {
      live.removeChild(live.firstChild);
    }

    var asc = document.getElementById('asc');
    if (!asc || asc.checked) {
      live.scrollTop = live.scrollHeight;
    }
  }

  function clearLive() {
    var live = document.getElementById('live');
    if (!live) return;
    live.innerHTML = '<div class="empty" id="livempty">Live-Ausgabe geleert</div>';
  }

  function renderStatus(data) {
    var runBadge = document.getElementById('runBadge');
    var portInfo = document.getElementById('portInfo');

    if (runBadge) {
      if (data && data.running) {
        runBadge.innerHTML = '<span class="badge b-green">ONLINE</span>';
      } else {
        runBadge.innerHTML = '<span class="badge b-red">OFFLINE</span>';
      }
    }

    if (portInfo) {
      portInfo.textContent = data && data.port ? data.port : '-';
    }
  }

  function poll() {
    fetch('/api/output?since=' + encodeURIComponent(String(lastTs)))
      .then(function (r) { return r.json(); })
      .then(function (d) {
        if (d.entries && d.entries.length) {
          d.entries.forEach(addLine);
          lastTs = d.lastTimestamp || lastTs;
        }
      })
      .catch(function () {})
      .finally(function () {
        pollTimer = setTimeout(poll, 1500);
      });
  }

  function loadStatus() {
    fetch('/api/status')
      .then(function (r) { return r.json(); })
      .then(renderStatus)
      .catch(function () {});
  }

  function loadFiles() {
    fetch('/api/logs')
      .then(function (r) { return r.json(); })
      .then(function (files) {
        var list = document.getElementById('log-list');
        if (!list) return;

        if (!files || !files.length) {
          list.innerHTML = '<div class="empty">Keine Logs vorhanden</div>';
          return;
        }

        list.innerHTML = '';
        files.forEach(function (f) {
          var item = document.createElement('div');
          item.className = 'litem' + (activeLog === f.name ? ' sel' : '');
          item.innerHTML = '<div class="n">' + esc(f.name) + '</div><div class="m">' + esc(f.modified) + ' • ' + fmtSz(f.size) + '</div>';
          item.onclick = function () {
            document.querySelectorAll('.litem').forEach(function (x) { x.classList.remove('sel'); });
            item.classList.add('sel');
            loadLog(f.name);
          };
          list.appendChild(item);
        });

        if (activeLog) {
          loadLog(activeLog);
        }
      })
      .catch(function () {});
  }

  function loadLog(name) {
    activeLog = name;

    var activeLabel = document.getElementById('activeLogLabel');
    if (activeLabel) activeLabel.textContent = name || '-';

    fetch('/api/logs/content?file=' + encodeURIComponent(name))
      .then(function (r) { return r.json(); })
      .then(function (d) {
        var c = document.getElementById('logv');
        if (!c) return;

        if (d.error) {
          c.innerHTML = '<div class="empty">' + esc(d.error) + '</div>';
          return;
        }

        c.innerHTML = '';
        (d.lines || []).forEach(function (line) {
          var div = document.createElement('div');
          div.className = 'ln ' + lvl(line);
          div.textContent = line;
          c.appendChild(div);
        });
        c.scrollTop = c.scrollHeight;
      })
      .catch(function () {});
  }

  function reloadLog() {
    if (activeLog) {
      loadLog(activeLog);
    }
  }

  function refreshGitStatus() {
    fetch('/api/git/status')
      .then(function (r) { return r.json(); })
      .then(function (d) {
        setTxt('gitBranch', d.branch || '-');
        setTxt('gitUpstream', d.upstream || '-');
        setTxt('gitAheadBehind', (d.ahead || 0) + ' / ' + (d.behind || 0));
        setTxt('gitDirty', d.dirty || 0);

        var remoteInput = document.getElementById('gitRemote');
        if (remoteInput && d.remote) {
          remoteInput.value = d.remote;
        }

        var branchInput = document.getElementById('gitTargetBranch');
        if (branchInput && d.branch && (!branchInput.value || branchInput.value === 'main')) {
          branchInput.value = d.branch;
        }

        if (d.message) {
          setGitMessage(d.message);
        } else if (d.available) {
          setGitMessage('Git-Repository erkannt. Pull bereit.');
        } else {
          setGitMessage('Git nicht verfügbar.');
        }
      })
      .catch(function () {
        setGitMessage('Git-Status konnte nicht geladen werden.');
      });
  }

  function pullGitNow() {
    var remote = (document.getElementById('gitRemote') || {}).value || 'origin';
    var branch = (document.getElementById('gitTargetBranch') || {}).value || 'main';

    if (!confirm('Git Pull ausführen von ' + remote + '/' + branch + '?')) {
      return;
    }

    setGitMessage('Git Pull läuft...');

    fetch('/api/git/pull', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ remote: remote, branch: branch })
    })
      .then(function (r) { return r.json(); })
      .then(function (d) {
        var txt = (d.message || 'Unbekannte Antwort') + (d.output ? '\n\n' + d.output : '');
        setGitMessage(txt);
        refreshGitStatus();
      })
      .catch(function () {
        setGitMessage('Git Pull fehlgeschlagen (Netzwerk/Serverfehler).');
      });
  }

  window.clearLive = clearLive;
  window.reloadLog = reloadLog;
  window.setActivePane = setActivePane;
  window.refreshGitStatus = refreshGitStatus;
  window.pullGitNow = pullGitNow;

  function init() {
    var host = document.getElementById('hostInfo');
    if (host) host.textContent = location.host;

    loadFiles();
    loadStatus();
    refreshGitStatus();
    poll();

    setInterval(loadFiles, 15000);
    setInterval(loadStatus, 10000);
    setInterval(refreshGitStatus, 20000);

    setActivePane(localStorage.getItem('wingui-active-pane') || 'overview');
  }

  init();
})();

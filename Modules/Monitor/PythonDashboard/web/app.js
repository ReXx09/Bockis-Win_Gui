const statePill = document.getElementById('state');
const sysInfo = document.getElementById('sysInfo');
const uptime = document.getElementById('uptime');

const cpuPct = document.getElementById('cpuPct');
const ramPct = document.getElementById('ramPct');
const netTxt = document.getElementById('netTxt');
const freqTxt = document.getElementById('freqTxt');
const cpuBar = document.getElementById('cpuBar');
const ramBar = document.getElementById('ramBar');
const disks = document.getElementById('disks');
const procRows = document.getElementById('procRows');

const gitBranch = document.getElementById('gitBranch');
const gitUpstream = document.getElementById('gitUpstream');
const gitAB = document.getElementById('gitAB');
const gitDirty = document.getElementById('gitDirty');
const gitRemote = document.getElementById('gitRemote');
const gitTarget = document.getElementById('gitTarget');
const gitMsg = document.getElementById('gitMsg');

const logSelect = document.getElementById('logSelect');
const logContent = document.getElementById('logContent');

const toolList = document.getElementById('toolList');
const toolMsg = document.getElementById('toolMsg');

async function jsonFetch(url, opt = {}) {
  const res = await fetch(url, opt);
  if (!res.ok) throw new Error(`${res.status} ${res.statusText}`);
  return res.json();
}

function setOnline(ok) {
  statePill.textContent = ok ? 'online' : 'offline';
  statePill.classList.toggle('off', !ok);
}

function formatUptime(s) {
  const h = Math.floor(s / 3600);
  const m = Math.floor((s % 3600) / 60);
  return `${h}h ${m}m`;
}

async function loadSystem() {
  const d = await jsonFetch('/api/system');
  sysInfo.textContent = `${d.hostname} | ${d.os} | ${d.cpu}`;
}

async function loadMetrics() {
  const m = await jsonFetch('/api/metrics');
  const d = await jsonFetch('/api/disks');
  const p = await jsonFetch('/api/processes?top=10');

  cpuPct.textContent = `${m.cpu_pct}%`;
  ramPct.textContent = `${m.ram_pct}%`;
  netTxt.textContent = `Up ${m.net_sent_mb} MB | Down ${m.net_recv_mb} MB`;
  freqTxt.textContent = m.cpu_freq_mhz ? `${m.cpu_freq_mhz} MHz` : '-';

  cpuBar.style.width = `${Math.max(0, Math.min(100, m.cpu_pct))}%`;
  ramBar.style.width = `${Math.max(0, Math.min(100, m.ram_pct))}%`;

  uptime.textContent = `Uptime: ${formatUptime(m.uptime_s || 0)}`;

  disks.innerHTML = d
    .map(
      (x) => `<div class="disk">
          <div><strong>${x.device}</strong> (${x.fstype})</div>
          <div>${x.used_gb} / ${x.total_gb} GB (${x.percent}%)</div>
          <div class="bar"><div style="width:${x.percent}%"></div></div>
        </div>`
    )
    .join('');

  procRows.innerHTML = p
    .map(
      (x) => `<tr><td>${x.name}</td><td>${x.pid}</td><td>${x.cpu}</td><td>${x.mem_mb}</td></tr>`
    )
    .join('');
}

async function refreshGit() {
  try {
    const d = await jsonFetch('/api/git/status');
    if (!d.available) {
      gitMsg.textContent = d.message || 'Git nicht verfuegbar';
      return;
    }

    gitBranch.textContent = d.branch || '-';
    gitUpstream.textContent = d.upstream || '-';
    gitAB.textContent = `${d.ahead} / ${d.behind}`;
    gitDirty.textContent = `${d.dirty_count}`;

    if (d.branch && gitTarget.value === 'main') {
      gitTarget.value = d.branch;
    }

    gitMsg.textContent = 'Git bereit.';
  } catch (err) {
    gitMsg.textContent = `Git-Status fehlgeschlagen: ${err.message}`;
  }
}

async function pullGit() {
  if (!confirm(`Git Pull von ${gitRemote.value}/${gitTarget.value} ausfuehren?`)) return;
  gitMsg.textContent = 'Git Pull laeuft...';
  try {
    const d = await jsonFetch('/api/git/pull', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ remote: gitRemote.value, branch: gitTarget.value }),
    });
    gitMsg.textContent = `${d.message || ''}\n\n${d.output || ''}`.trim();
    await refreshGit();
  } catch (err) {
    gitMsg.textContent = `Git Pull Fehler: ${err.message}`;
  }
}

async function loadLogs() {
  try {
    const files = await jsonFetch('/api/logs');
    logSelect.innerHTML = files.map((f) => `<option value="${f}">${f}</option>`).join('');
    if (files.length > 0) await openLog(files[0]);
    else logContent.textContent = 'Keine Logs gefunden.';
  } catch (err) {
    logContent.textContent = `Log-Liste Fehler: ${err.message}`;
  }
}

async function openLog(name) {
  if (!name) return;
  try {
    const d = await jsonFetch(`/api/logs/content?file=${encodeURIComponent(name)}&lines=250`);
    logContent.textContent = d.content || '(leer)';
  } catch (err) {
    logContent.textContent = `Log-Laden fehlgeschlagen: ${err.message}`;
  }
}

async function loadTools() {
  try {
    const tools = await jsonFetch('/api/tools');
    toolList.innerHTML = '';
    for (const t of tools) {
      const btn = document.createElement('button');
      btn.className = 'btn';
      btn.textContent = t.label;
      btn.onclick = async () => {
        toolMsg.textContent = `Starte ${t.label}...`;
        try {
          const d = await jsonFetch(`/api/tools/run/${t.id}`, { method: 'POST' });
          toolMsg.textContent = `${d.message || ''}\n${d.output || ''}`.trim();
        } catch (err) {
          toolMsg.textContent = `Tool-Fehler: ${err.message}`;
        }
      };
      toolList.appendChild(btn);
    }
  } catch (err) {
    toolMsg.textContent = `Tool-Liste fehlgeschlagen: ${err.message}`;
  }
}

async function restartGui() {
  if (!confirm('Bockis GUI neu starten?')) return;
  try {
    const d = await jsonFetch('/api/restart', { method: 'POST' });
    alert(d.message || 'Neustart gestartet.');
  } catch (err) {
    alert(`Neustart fehlgeschlagen: ${err.message}`);
  }
}

async function refreshAll() {
  try {
    setOnline(true);
    await loadMetrics();
  } catch {
    setOnline(false);
  }
}

async function init() {
  document.getElementById('gitStatusBtn').onclick = refreshGit;
  document.getElementById('gitPullBtn').onclick = pullGit;
  document.getElementById('reloadLogBtn').onclick = () => openLog(logSelect.value);
  document.getElementById('restartBtn').onclick = restartGui;
  logSelect.onchange = () => openLog(logSelect.value);

  try {
    await loadSystem();
  } catch {
    sysInfo.textContent = 'Systeminfo nicht verfuegbar';
  }

  await Promise.all([refreshAll(), refreshGit(), loadLogs(), loadTools()]);
  setInterval(refreshAll, 5000);
  setInterval(refreshGit, 20000);
}

init();

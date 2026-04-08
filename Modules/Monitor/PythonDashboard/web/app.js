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
const gpuList = document.getElementById('gpuList');
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

const audioLevel = document.getElementById('audioLevel');
const audioMuted = document.getElementById('audioMuted');
const audioSlider = document.getElementById('audioSlider');
const audioMsg = document.getElementById('audioMsg');

const dashboardGrid = document.getElementById('dashboardGrid');
const widgetMenu = document.getElementById('widgetMenu');
const layoutMsg = document.getElementById('layoutMsg');

const LAYOUT_KEY = 'bockis_dashboard_layout_v3';
const PAGE_KEY = 'bockis_dashboard_page_v1';
const WIDGET_LABELS = {
  monitoring: 'Monitoring',
  disks: 'Festplatten',
  audio: 'Audio',
  processes: 'Prozesse',
};
const SIZE_PRESETS = ['1-3', '1-2', '2-3', 'full', 'min'];

let draggedCard = null;

async function jsonFetch(url, opt = {}) {
  const res = await fetch(url, opt);
  if (!res.ok) throw new Error(`${res.status} ${res.statusText}`);
  return res.json();
}

function getCards() {
  return Array.from(dashboardGrid.querySelectorAll('.card[data-widget]'));
}

function formatUptime(s) {
  const h = Math.floor(s / 3600);
  const m = Math.floor((s % 3600) / 60);
  return `${h}h ${m}m`;
}

function setOnline(ok) {
  statePill.textContent = ok ? 'online' : 'offline';
  statePill.classList.toggle('off', !ok);
}

function readLayout() {
  try {
    const raw = localStorage.getItem(LAYOUT_KEY);
    return raw ? JSON.parse(raw) : null;
  } catch {
    return null;
  }
}

function collectLayout() {
  const order = getCards().map((card) => card.dataset.widget);
  const visible = {};
  const sizes = {};
  getCards().forEach((card) => {
    visible[card.dataset.widget] = card.style.display !== 'none';
    sizes[card.dataset.widget] = card.dataset.size || card.dataset.defaultSize || '1-3';
  });
  return { order, visible, sizes };
}

function setCardSize(card, size, save = true) {
  const target = SIZE_PRESETS.includes(size) ? size : (card.dataset.defaultSize || '1-3');
  SIZE_PRESETS.forEach((s) => card.classList.remove(`tile-size-${s}`));
  card.classList.add(`tile-size-${target}`);
  card.dataset.size = target;

  card.querySelectorAll('.size-btn').forEach((btn) => {
    btn.classList.toggle('active', btn.dataset.size === target);
  });

  if (save) saveLayout(false);
}

function saveLayout(notify = true) {
  localStorage.setItem(LAYOUT_KEY, JSON.stringify(collectLayout()));
  if (notify) {
    layoutMsg.textContent = 'Layout gespeichert.';
    setTimeout(() => {
      if (layoutMsg.textContent === 'Layout gespeichert.') layoutMsg.textContent = '';
    }, 1800);
  }
}

function applyLayout(layout) {
  if (!layout) return;
  const map = {};
  getCards().forEach((card) => {
    map[card.dataset.widget] = card;
  });
  if (Array.isArray(layout.order)) {
    layout.order.forEach((w) => {
      if (map[w]) dashboardGrid.appendChild(map[w]);
    });
  }
  if (layout.visible) {
    getCards().forEach((card) => {
      const w = card.dataset.widget;
      if (Object.prototype.hasOwnProperty.call(layout.visible, w)) {
        card.style.display = layout.visible[w] ? '' : 'none';
      }
    });
  }

  getCards().forEach((card) => {
    const w = card.dataset.widget;
    const size = layout.sizes && layout.sizes[w] ? layout.sizes[w] : (card.dataset.defaultSize || '1-3');
    setCardSize(card, size, false);
  });
}

function wireSizeControls() {
  getCards().forEach((card) => {
    const head = card.querySelector('.card-head');
    if (!head || head.querySelector('.size-controls')) return;

    const drag = head.querySelector('.drag-handle');
    const actions = document.createElement('div');
    actions.className = 'card-head-actions';

    const controls = document.createElement('div');
    controls.className = 'size-controls';

    const specs = [
      { key: '1-3', label: '1/3' },
      { key: '1-2', label: '1/2' },
      { key: '2-3', label: '2/3' },
      { key: 'full', label: 'voll' },
      { key: 'min', label: 'min' },
    ];

    specs.forEach((spec) => {
      const btn = document.createElement('button');
      btn.type = 'button';
      btn.className = 'size-btn';
      btn.textContent = spec.label;
      btn.dataset.size = spec.key;
      btn.title = `Kachelgroesse ${spec.label}`;
      btn.addEventListener('click', (e) => {
        e.preventDefault();
        e.stopPropagation();
        setCardSize(card, spec.key, true);
      });
      controls.appendChild(btn);
    });

    actions.appendChild(controls);
    if (drag) actions.appendChild(drag);
    head.appendChild(actions);

    setCardSize(card, card.dataset.size || card.dataset.defaultSize || '1-3', false);
  });
}

function renderWidgetMenu() {
  widgetMenu.innerHTML = '';
  getCards().forEach((card) => {
    const w = card.dataset.widget;
    const item = document.createElement('label');
    item.className = 'menu-item';
    item.innerHTML = `<input type="checkbox" /> <span>${WIDGET_LABELS[w] || w}</span>`;
    const cb = item.querySelector('input');
    cb.checked = card.style.display !== 'none';
    cb.addEventListener('change', () => {
      card.style.display = cb.checked ? '' : 'none';
      saveLayout(false);
    });
    widgetMenu.appendChild(item);
  });
}

function wireDragDrop() {
  getCards().forEach((card) => {
    card.addEventListener('dragstart', () => {
      draggedCard = card;
      card.classList.add('dragging');
    });
    card.addEventListener('dragend', () => {
      card.classList.remove('dragging');
      getCards().forEach((c) => c.classList.remove('drag-over'));
      draggedCard = null;
      saveLayout(false);
      renderWidgetMenu();
    });
    card.addEventListener('dragover', (e) => {
      e.preventDefault();
      if (!draggedCard || draggedCard === card) return;
      card.classList.add('drag-over');
    });
    card.addEventListener('dragleave', () => card.classList.remove('drag-over'));
    card.addEventListener('drop', (e) => {
      e.preventDefault();
      card.classList.remove('drag-over');
      if (!draggedCard || draggedCard === card) return;
      dashboardGrid.insertBefore(draggedCard, card);
    });
  });
}

function showPage(page) {
  document.querySelectorAll('.page').forEach((p) => {
    p.classList.toggle('active', p.dataset.page === page);
  });
  document.querySelectorAll('.menu-nav-btn').forEach((b) => {
    b.classList.toggle('active', b.dataset.pageTarget === page);
  });
  localStorage.setItem(PAGE_KEY, page);
}

function wirePageMenu() {
  document.querySelectorAll('.menu-nav-btn').forEach((btn) => {
    btn.addEventListener('click', () => showPage(btn.dataset.pageTarget));
  });
  const start = localStorage.getItem(PAGE_KEY) || 'overview';
  showPage(start);
}

function resetLayout() {
  localStorage.removeItem(LAYOUT_KEY);
  window.location.reload();
}

async function loadSystem() {
  const d = await jsonFetch('/api/system');
  sysInfo.textContent = `${d.hostname} | ${d.os} | ${d.cpu}`;
}

async function loadMetrics() {
  const [m, d, p] = await Promise.all([
    jsonFetch('/api/metrics'),
    jsonFetch('/api/disks'),
    jsonFetch('/api/processes?top=10'),
  ]);

  // GPU separat – Fehler crasht nicht den Rest des Dashboards
  let gpus = [];
  try {
    gpus = await jsonFetch('/api/gpu');
  } catch {
    if (gpuList) gpuList.innerHTML = '<div class="gpu-empty">GPU-Daten nicht verfuegbar (Server-Neustart noetig?)</div>';
  }

  cpuPct.textContent = `${m.cpu_pct}%`;
  ramPct.textContent = `${m.ram_pct}%`;
  netTxt.textContent = `Up ${m.net_sent_mb} MB | Down ${m.net_recv_mb} MB`;
  freqTxt.textContent = m.cpu_freq_mhz ? `${m.cpu_freq_mhz} MHz` : '-';
  cpuBar.style.width = `${Math.max(0, Math.min(100, m.cpu_pct))}%`;
  ramBar.style.width = `${Math.max(0, Math.min(100, m.ram_pct))}%`;
  uptime.textContent = `Uptime: ${formatUptime(m.uptime_s || 0)}`;

  // GPU
  gpuList.innerHTML = gpus.length
    ? gpus.map((g) => {
        const usageBar = g.usage_pct != null
          ? `<div class="bar"><div style="width:${g.usage_pct}%"></div></div>`
          : `<div class="bar-na">Auslastung: n/a</div>`;
        const vram = (g.vram_used_mb != null && g.vram_total_mb != null)
          ? `VRAM ${g.vram_used_mb} / ${g.vram_total_mb} MB`
          : g.vram_total_mb != null ? `VRAM ${g.vram_total_mb} MB` : '';
        const temp = g.temp_c != null ? ` &nbsp;|&nbsp; ${g.temp_c} °C` : '';
        return `<div class="gpu-item">
          <div class="gpu-header"><strong>${g.name}</strong><span class="gpu-detail">${vram}${temp}</span></div>
          <div class="gpu-usage">${g.usage_pct != null ? g.usage_pct + '%' : 'n/a'}&nbsp;<span class="gpu-src">${g.source}</span></div>
          ${usageBar}
        </div>`;
      }).join('')
    : '<div class="gpu-empty">Keine GPU-Daten verfuegbar</div>';

  disks.innerHTML = d
    .map((x) => `<div class="disk"><div><strong>${x.device}</strong> (${x.fstype})</div><div>${x.used_gb} / ${x.total_gb} GB (${x.percent}%)</div><div class="bar"><div style="width:${x.percent}%"></div></div></div>`)
    .join('');
  procRows.innerHTML = p
    .map((x) => `<tr><td>${x.name}</td><td>${x.pid}</td><td>${x.cpu}</td><td>${x.mem_mb}</td></tr>`)
    .join('');
}

let lastPullTime = 0;

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
    if (d.branch && gitTarget.value === 'main') gitTarget.value = d.branch;
    // Pull-Ergebnis nicht ueberschreiben wenn es juenger als 60 Sekunden ist
    if (Date.now() - lastPullTime > 60000) {
      gitMsg.textContent = 'Git bereit.';
    }
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
    const beforeShort = d.before_head ? String(d.before_head).slice(0, 8) : '-';
    const afterShort = d.after_head ? String(d.after_head).slice(0, 8) : beforeShort;
    const deltaLine = `Commit: ${beforeShort} -> ${afterShort} | Geladen: ${d.pulled_commits ?? 0}`;
    let pullResult = `[Pull-Ergebnis ${new Date().toLocaleTimeString()}]\n${d.message || ''}\n${deltaLine}\n${d.output || ''}`.trim();
    if (d.restart_info) {
      pullResult += `\n${d.restart_info}`;
    }
    if (d.restarting) {
      pullResult += '\nServer-Neustart laeuft. Seite wird in 4 Sekunden aktualisiert...';
      setTimeout(() => window.location.reload(), 4000);
    }
    lastPullTime = Date.now();
    await refreshGit();           // aktualisiert Ahead/Behind/Branch-Felder
    gitMsg.textContent = pullResult; // Pull-Ausgabe danach wieder herstellen
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

async function refreshAudio() {
  try {
    const d = await jsonFetch('/api/audio');
    if (!d.available) {
      audioLevel.textContent = 'N/A';
      audioMuted.textContent = 'Audio nicht verfuegbar';
      audioMsg.textContent = 'pycaw/comtypes fehlen oder Audio-Endpoint nicht verfuegbar.';
      return;
    }
    audioLevel.textContent = `${d.level}%`;
    audioMuted.textContent = d.muted ? 'Stumm' : 'Aktiv';
    audioSlider.value = d.level;
  } catch (err) {
    audioMsg.textContent = `Audio-Status Fehler: ${err.message}`;
  }
}

async function setAudioVolume(level) {
  try {
    const d = await jsonFetch(`/api/audio/volume/${Math.max(0, Math.min(100, level))}`, { method: 'POST' });
    if (!d.success) audioMsg.textContent = 'Lautstaerke konnte nicht gesetzt werden.';
    await refreshAudio();
  } catch (err) {
    audioMsg.textContent = `Volume Fehler: ${err.message}`;
  }
}

async function toggleAudioMute() {
  try {
    const current = await jsonFetch('/api/audio');
    const target = current.muted ? 0 : 1;
    await jsonFetch(`/api/audio/mute/${target}`, { method: 'POST' });
    await refreshAudio();
  } catch (err) {
    audioMsg.textContent = `Mute Fehler: ${err.message}`;
  }
}

async function mediaAction(action) {
  try {
    const d = await jsonFetch(`/api/audio/media/${action}`, { method: 'POST' });
    if (!d.success) {
      audioMsg.textContent = `Media Aktion '${action}' nicht verfuegbar.`;
      return;
    }
    audioMsg.textContent = `Media Aktion ausgefuehrt: ${action}`;
  } catch (err) {
    audioMsg.textContent = `Media Fehler: ${err.message}`;
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
    await Promise.all([loadMetrics(), refreshAudio()]);
  } catch {
    setOnline(false);
  }
}

function wireAudioControls() {
  audioSlider.addEventListener('change', () => setAudioVolume(parseInt(audioSlider.value, 10) || 0));
  document.getElementById('audioMinus').onclick = () => setAudioVolume((parseInt(audioSlider.value, 10) || 0) - 10);
  document.getElementById('audioPlus').onclick = () => setAudioVolume((parseInt(audioSlider.value, 10) || 0) + 10);
  document.getElementById('audioMuteBtn').onclick = toggleAudioMute;
  document.querySelectorAll('[data-media]').forEach((btn) => {
    btn.addEventListener('click', () => mediaAction(btn.dataset.media));
  });
}

async function init() {
  document.getElementById('gitStatusBtn').onclick = refreshGit;
  document.getElementById('gitPullBtn').onclick = pullGit;
  document.getElementById('reloadLogBtn').onclick = () => openLog(logSelect.value);
  document.getElementById('restartBtn').onclick = restartGui;
  document.getElementById('saveLayoutBtn').onclick = () => saveLayout(true);
  document.getElementById('resetLayoutBtn').onclick = resetLayout;
  logSelect.onchange = () => openLog(logSelect.value);

  wirePageMenu();
  wireSizeControls();
  applyLayout(readLayout());
  renderWidgetMenu();
  wireDragDrop();
  wireAudioControls();

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

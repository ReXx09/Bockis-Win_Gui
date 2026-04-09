const statePill = document.getElementById('state');
const sysInfo = document.getElementById('sysInfo');
const uptime = document.getElementById('uptime');

const cpuPct = document.getElementById('cpuPct');
const ramPct = document.getElementById('ramPct');
const cpuMeta = document.getElementById('cpuMeta');
const ramMeta = document.getElementById('ramMeta');
const upRateTxt = document.getElementById('upRateTxt');
const downRateTxt = document.getElementById('downRateTxt');
const netTotalUpTxt = document.getElementById('netTotalUpTxt');
const netTotalDownTxt = document.getElementById('netTotalDownTxt');
const netUpChart = document.getElementById('netUpChart');
const netDownChart = document.getElementById('netDownChart');
const cpuBar = document.getElementById('cpuBar');
const ramBar = document.getElementById('ramBar');
const gpuName = document.getElementById('gpuName');
const gpuPct = document.getElementById('gpuPct');
const gpuMeta = document.getElementById('gpuMeta');
const gpuBar = document.getElementById('gpuBar');
const cpuChart = document.getElementById('cpuChart');
const gpuChart = document.getElementById('gpuChart');
const ramChart = document.getElementById('ramChart');
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

const audioLevel = document.getElementById('audioLevel');
const audioMuted = document.getElementById('audioMuted');
const audioSlider = document.getElementById('audioSlider');
const audioMsg = document.getElementById('audioMsg');
const audioDeviceInfo = document.getElementById('audioDeviceInfo');
const audioDevices = document.getElementById('audioDevices');
const audioSessions = document.getElementById('audioSessions');
const openProgramSelect = document.getElementById('openProgramSelect');
const openProgramHints = document.getElementById('openProgramHints');
const userProgramName = document.getElementById('userProgramName');
const userProgramDevice = document.getElementById('userProgramDevice');
const addUserProgramBtn = document.getElementById('addUserProgramBtn');
const refreshOpenProgramsBtn = document.getElementById('refreshOpenProgramsBtn');
const openRoutingSettingsBtn = document.getElementById('openRoutingSettingsBtn');
const userProgramRoutes = document.getElementById('userProgramRoutes');
const userRoutingHint = document.getElementById('userRoutingHint');

const dashboardGrid = document.getElementById('dashboardGrid');
const audioGrid = document.getElementById('audioGrid');
const widgetMenu = document.getElementById('widgetMenu');
const layoutMsg = document.getElementById('layoutMsg');

const LAYOUT_KEY = 'bockis_dashboard_layout_v4';
const AUDIO_LAYOUT_KEY = 'bockis_audio_layout_v1';
const PAGE_KEY = 'bockis_dashboard_page_v1';
const WIDGET_LABELS = {
  monitoring: 'Monitoring',
  'net-upload': 'Upload',
  'net-download': 'Download',
  disks: 'Festplatten',
  audio: 'Audio',
  processes: 'Prozesse',
  'audio-volume': 'Lautstaerke',
  'audio-devices': 'Audiogeraete',
  'audio-sessions': 'Programm-Audio',
  'audio-routing': 'Benutzer-Programmzuordnung',
};
const SIZE_PRESETS = ['1-3', '1-2', '2-3', 'full', 'min'];
const THEME_KEY = 'bockis_theme_v1';
const AUDIO_USER_ROUTES_KEY = 'bockis_audio_user_routes_v1';
const THEMES = [
  { id: 'ozean',     label: 'Ozean',     s1: '#4aa3ff', s2: '#14315a',
    vars: { '--accent': '#4aa3ff', '--bg': '#071220', '--card': '#0f1b2e', '--line': '#223554', '--muted': '#8da3c7', '--grad-from': '#14315a', '--grad-to': '#071220' } },
  { id: 'bernstein', label: 'Bernstein', s1: '#ffb020', s2: '#3d2600',
    vars: { '--accent': '#ffb020', '--bg': '#100a00', '--card': '#1c1400', '--line': '#3a2800', '--muted': '#a07838', '--grad-from': '#3d2600', '--grad-to': '#100a00' } },
  { id: 'smaragd',   label: 'Smaragd',   s1: '#3ecf8e', s2: '#0d3d22',
    vars: { '--accent': '#3ecf8e', '--bg': '#061a0f', '--card': '#0b2418', '--line': '#133d28', '--muted': '#5a9c7a', '--grad-from': '#0d3d22', '--grad-to': '#061a0f' } },
  { id: 'violett',   label: 'Violett',   s1: '#a78bfa', s2: '#2d1b6e',
    vars: { '--accent': '#a78bfa', '--bg': '#0d0520', '--card': '#160b35', '--line': '#2d1b5a', '--muted': '#7c6cb0', '--grad-from': '#2d1b6e', '--grad-to': '#0d0520' } },
  { id: 'rubin',     label: 'Rubin',     s1: '#ff6b6b', s2: '#3d1515',
    vars: { '--accent': '#ff6b6b', '--bg': '#1a0808', '--card': '#2a1010', '--line': '#3d1515', '--muted': '#a06060', '--grad-from': '#3d1515', '--grad-to': '#1a0808' } },
  { id: 'titan',     label: 'Titan',     s1: '#94a3b8', s2: '#1e2a3a',
    vars: { '--accent': '#94a3b8', '--bg': '#0a0e14', '--card': '#101620', '--line': '#1e2a3a', '--muted': '#607080', '--grad-from': '#1e2a3a', '--grad-to': '#0a0e14' } },
];

let draggedCard = null;
let cachedAudioDevices = [];
let lastAudioSessions = [];
let cachedOpenPrograms = [];
let lastOpenProgramsFetch = 0;
let showAllAudioDevices = false;
let audioLayoutFrame = 0;
const HISTORY_LEN = 45;
const monitorHistory = {
  cpu: [],
  gpu: [],
  ram: [],
  netUp: [],
  netDown: [],
};
let lastNetSample = null;

function pushHistory(key, value) {
  const list = monitorHistory[key];
  if (!list) return;
  list.push(Number.isFinite(value) ? value : 0);
  while (list.length > HISTORY_LEN) list.shift();
}

function drawSparkline(canvas, values, maxValue = 100, line = '#4aa3ff', fill = 'rgba(74,163,255,0.16)') {
  if (!canvas || !values || values.length === 0) return;
  const w = Math.max(120, canvas.clientWidth || 120);
  const h = canvas.height || 70;
  if (canvas.width !== w) canvas.width = w;

  const ctx = canvas.getContext('2d');
  if (!ctx) return;

  ctx.clearRect(0, 0, w, h);
  ctx.lineWidth = 1;
  ctx.strokeStyle = 'rgba(141,163,199,0.22)';
  ctx.beginPath();
  ctx.moveTo(0, h - 1);
  ctx.lineTo(w, h - 1);
  ctx.stroke();

  const safeMax = Math.max(1, maxValue, ...values);
  const step = values.length > 1 ? w / (values.length - 1) : w;

  ctx.beginPath();
  values.forEach((v, i) => {
    const x = i * step;
    const y = h - Math.max(0, Math.min(1, v / safeMax)) * (h - 4) - 2;
    if (i === 0) ctx.moveTo(x, y);
    else ctx.lineTo(x, y);
  });

  const lastX = (values.length - 1) * step;
  ctx.lineTo(lastX, h - 2);
  ctx.lineTo(0, h - 2);
  ctx.closePath();
  ctx.fillStyle = fill;
  ctx.fill();

  ctx.beginPath();
  values.forEach((v, i) => {
    const x = i * step;
    const y = h - Math.max(0, Math.min(1, v / safeMax)) * (h - 4) - 2;
    if (i === 0) ctx.moveTo(x, y);
    else ctx.lineTo(x, y);
  });
  ctx.strokeStyle = line;
  ctx.lineWidth = 1.7;
  ctx.stroke();
}

function renderMonitorCharts() {
  drawSparkline(cpuChart, monitorHistory.cpu, 100, '#49a9ff', 'rgba(73,169,255,0.16)');
  drawSparkline(gpuChart, monitorHistory.gpu, 100, '#41d88f', 'rgba(65,216,143,0.16)');
  drawSparkline(ramChart, monitorHistory.ram, 100, '#8ea7ff', 'rgba(142,167,255,0.16)');
  const upMax = Math.max(1, ...monitorHistory.netUp);
  const downMax = Math.max(1, ...monitorHistory.netDown);
  drawSparkline(netUpChart, monitorHistory.netUp, upMax, '#f97316', 'rgba(249,115,22,0.16)');
  drawSparkline(netDownChart, monitorHistory.netDown, downMax, '#22d3ee', 'rgba(34,211,238,0.16)');
}

async function jsonFetch(url, opt = {}) {
  const res = await fetch(url, opt);
  if (!res.ok) throw new Error(`${res.status} ${res.statusText}`);
  return res.json();
}

function isMasonryLayout(layoutEl) {
  return Boolean(layoutEl && layoutEl.id === 'audioGrid');
}

function refreshMasonryLayout(layoutEl = audioGrid) {
  if (!isMasonryLayout(layoutEl)) return;

  const styles = getComputedStyle(layoutEl);
  const rowHeight = parseFloat(styles.getPropertyValue('grid-auto-rows')) || 8;
  const rowGap = parseFloat(styles.getPropertyValue('row-gap')) || parseFloat(styles.getPropertyValue('gap')) || 14;

  getCards(layoutEl).forEach((card) => {
    card.style.gridRowEnd = 'auto';
  });

  getCards(layoutEl).forEach((card) => {
    const span = Math.max(1, Math.ceil((card.getBoundingClientRect().height + rowGap) / (rowHeight + rowGap)));
    card.style.gridRowEnd = `span ${span}`;
  });
}

function scheduleMasonryLayout(layoutEl = audioGrid) {
  if (!isMasonryLayout(layoutEl)) return;
  cancelAnimationFrame(audioLayoutFrame);
  audioLayoutFrame = requestAnimationFrame(() => refreshMasonryLayout(layoutEl));
}

function getCards(layoutEl = dashboardGrid) {
  if (!layoutEl) return [];
  return Array.from(layoutEl.querySelectorAll('.card[data-widget]'));
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

function readLayout(storageKey = LAYOUT_KEY) {
  try {
    const raw = localStorage.getItem(storageKey);
    return raw ? JSON.parse(raw) : null;
  } catch {
    return null;
  }
}

function collectLayout(layoutEl = dashboardGrid) {
  const order = getCards(layoutEl).map((card) => card.dataset.widget);
  const visible = {};
  const sizes = {};
  getCards(layoutEl).forEach((card) => {
    visible[card.dataset.widget] = card.style.display !== 'none';
    sizes[card.dataset.widget] = card.dataset.size || card.dataset.defaultSize || '1-3';
  });
  return { order, visible, sizes };
}

function setCardSize(card, size, save = true, layoutEl = dashboardGrid, storageKey = LAYOUT_KEY, messageEl = null) {
  const target = SIZE_PRESETS.includes(size) ? size : (card.dataset.defaultSize || '1-3');
  SIZE_PRESETS.forEach((s) => card.classList.remove(`tile-size-${s}`));
  card.classList.add(`tile-size-${target}`);
  card.dataset.size = target;

  card.querySelectorAll('.size-btn').forEach((btn) => {
    btn.classList.toggle('active', btn.dataset.size === target);
  });

  scheduleMasonryLayout(layoutEl);
  if (save) saveLayout(layoutEl, storageKey, false, messageEl);
}

function saveLayout(layoutEl = dashboardGrid, storageKey = LAYOUT_KEY, notify = true, messageEl = layoutMsg) {
  localStorage.setItem(storageKey, JSON.stringify(collectLayout(layoutEl)));
  if (notify && messageEl) {
    messageEl.textContent = 'Layout gespeichert.';
    setTimeout(() => {
      if (messageEl.textContent === 'Layout gespeichert.') messageEl.textContent = '';
    }, 1800);
  }
}

function applyLayout(layout, layoutEl = dashboardGrid) {
  if (!layout) return;
  const map = {};
  getCards(layoutEl).forEach((card) => {
    map[card.dataset.widget] = card;
  });
  if (Array.isArray(layout.order)) {
    layout.order.forEach((w) => {
      if (map[w]) layoutEl.appendChild(map[w]);
    });
  }
  if (layout.visible) {
    getCards(layoutEl).forEach((card) => {
      const w = card.dataset.widget;
      if (Object.prototype.hasOwnProperty.call(layout.visible, w)) {
        card.style.display = layout.visible[w] ? '' : 'none';
      }
    });
  }

  getCards(layoutEl).forEach((card) => {
    const w = card.dataset.widget;
    const size = layout.sizes && layout.sizes[w] ? layout.sizes[w] : (card.dataset.defaultSize || '1-3');
    setCardSize(card, size, false, layoutEl);
  });

  scheduleMasonryLayout(layoutEl);
}

function wireSizeControls(layoutEl = dashboardGrid, storageKey = LAYOUT_KEY, messageEl = null) {
  getCards(layoutEl).forEach((card) => {
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
        setCardSize(card, spec.key, true, layoutEl, storageKey, messageEl);
      });
      controls.appendChild(btn);
    });

    actions.appendChild(controls);
    if (drag) actions.appendChild(drag);
    head.appendChild(actions);

    setCardSize(card, card.dataset.size || card.dataset.defaultSize || '1-3', false, layoutEl, storageKey, messageEl);
  });
}

function renderWidgetMenu() {
  widgetMenu.innerHTML = '';
  getCards(dashboardGrid).forEach((card) => {
    const w = card.dataset.widget;
    const item = document.createElement('label');
    item.className = 'menu-item';
    item.innerHTML = `<input type="checkbox" /> <span>${WIDGET_LABELS[w] || w}</span>`;
    const cb = item.querySelector('input');
    cb.checked = card.style.display !== 'none';
    cb.addEventListener('change', () => {
      card.style.display = cb.checked ? '' : 'none';
      saveLayout(dashboardGrid, LAYOUT_KEY, false, layoutMsg);
    });
    widgetMenu.appendChild(item);
  });
}

function wireDragDrop(layoutEl = dashboardGrid, storageKey = LAYOUT_KEY, onAfterDrop = null) {
  getCards(layoutEl).forEach((card) => {
    card.addEventListener('dragstart', () => {
      draggedCard = card;
      card.classList.add('dragging');
    });
    card.addEventListener('dragend', () => {
      card.classList.remove('dragging');
      getCards(layoutEl).forEach((c) => c.classList.remove('drag-over'));
      draggedCard = null;
      scheduleMasonryLayout(layoutEl);
      saveLayout(layoutEl, storageKey, false);
      if (typeof onAfterDrop === 'function') onAfterDrop();
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
      layoutEl.insertBefore(draggedCard, card);
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
  if (page === 'audio') scheduleMasonryLayout(audioGrid);
}

function wirePageMenu() {
  document.querySelectorAll('.menu-nav-btn').forEach((btn) => {
    btn.addEventListener('click', () => showPage(btn.dataset.pageTarget));
  });
  const start = localStorage.getItem(PAGE_KEY) || 'overview';
  showPage(start);
}

function resetLayout(storageKey = LAYOUT_KEY) {
  localStorage.removeItem(storageKey);
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
    gpus = [];
  }

  cpuPct.textContent = `${m.cpu_pct}%`;
  ramPct.textContent = `${m.ram_pct}%`;
  cpuMeta.textContent = `${m.cpu_freq_mhz ? `${m.cpu_freq_mhz} MHz` : 'Freq n/a'} | ${m.cpu_temp_c != null ? `${m.cpu_temp_c} °C` : 'Temp n/a'}`;
  ramMeta.textContent = `${m.ram_used_gb} / ${m.ram_total_gb} GB | ${m.ram_temp_c != null ? `${m.ram_temp_c} °C` : 'Temp n/a'}`;
  netTotalUpTxt.textContent = `Gesamt: ${m.net_sent_mb} MB`;
  netTotalDownTxt.textContent = `Gesamt: ${m.net_recv_mb} MB`;
  cpuBar.style.width = `${Math.max(0, Math.min(100, m.cpu_pct))}%`;
  ramBar.style.width = `${Math.max(0, Math.min(100, m.ram_pct))}%`;
  uptime.textContent = `Uptime: ${formatUptime(m.uptime_s || 0)}`;

  pushHistory('cpu', m.cpu_pct || 0);
  pushHistory('ram', m.ram_pct || 0);

  // GPU als gleiches Metrik-Format wie CPU/RAM
  const mainGpu = gpus.length ? gpus[0] : null;
  if (mainGpu) {
    const pct = mainGpu.usage_pct != null ? mainGpu.usage_pct : 0;
    gpuName.textContent = gpus.length > 1 ? `${mainGpu.name} (+${gpus.length - 1})` : mainGpu.name;
    gpuPct.textContent = mainGpu.usage_pct != null ? `${mainGpu.usage_pct}%` : 'n/a';
    const vram = (mainGpu.vram_used_mb != null && mainGpu.vram_total_mb != null)
      ? `VRAM ${mainGpu.vram_used_mb}/${mainGpu.vram_total_mb} MB`
      : (mainGpu.vram_total_mb != null ? `VRAM ${mainGpu.vram_total_mb} MB` : 'VRAM n/a');
    gpuMeta.textContent = `${vram} | ${mainGpu.temp_c != null ? `${mainGpu.temp_c} °C` : 'Temp n/a'}`;
    gpuBar.style.width = `${Math.max(0, Math.min(100, pct))}%`;
    pushHistory('gpu', pct);
  } else {
    gpuName.textContent = 'GPU';
    gpuPct.textContent = 'n/a';
    gpuMeta.textContent = 'Keine GPU-Daten';
    gpuBar.style.width = '0%';
    pushHistory('gpu', 0);
  }

  const now = Date.now();
  const sentTotal = m.net_sent_mb || 0;
  const recvTotal = m.net_recv_mb || 0;
  const netTotal = sentTotal + recvTotal;
  let upRate = 0;
  let downRate = 0;
  let netRate = 0;

  if (lastNetSample && now > lastNetSample.ts) {
    const dt = (now - lastNetSample.ts) / 1000;
    const sentDelta = Math.max(0, sentTotal - lastNetSample.sent);
    const recvDelta = Math.max(0, recvTotal - lastNetSample.recv);
    upRate = dt > 0 ? sentDelta / dt : 0;
    downRate = dt > 0 ? recvDelta / dt : 0;
    netRate = upRate + downRate;
  }

  upRateTxt.textContent = `${upRate.toFixed(2)}`;
  downRateTxt.textContent = `${downRate.toFixed(2)}`;
  lastNetSample = { ts: now, total: netTotal, sent: sentTotal, recv: recvTotal };
  pushHistory('netUp', upRate);
  pushHistory('netDown', downRate);
  renderMonitorCharts();

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

function readUserAudioRoutes() {
  try {
    const raw = localStorage.getItem(AUDIO_USER_ROUTES_KEY);
    const data = raw ? JSON.parse(raw) : [];
    return Array.isArray(data) ? data : [];
  } catch {
    return [];
  }
}

function saveUserAudioRoutes(routes) {
  localStorage.setItem(AUDIO_USER_ROUTES_KEY, JSON.stringify(routes));
}

function refreshUserProgramDeviceSelect(selected = '') {
  if (!userProgramDevice) return;
  const options = cachedAudioDevices.length
    ? cachedAudioDevices.map((d) => `<option value="${d.id}">${d.name}${d.is_active_output ? ' (Aktiv)' : ''}</option>`).join('')
    : '<option value="">Keine Ausgabegeraete gefunden</option>';
  userProgramDevice.innerHTML = options;
  if (selected) userProgramDevice.value = selected;
}

function resolveDeviceNameById(id) {
  const dev = cachedAudioDevices.find((d) => d.id === id);
  return dev ? dev.name : '(Unbekanntes Geraet)';
}

async function setDefaultAudioDevice(deviceId, deviceName = '') {
  if (!deviceId) {
    audioMsg.textContent = 'Kein Ausgabegeraet ausgewaehlt.';
    return false;
  }
  try {
    const d = await jsonFetch('/api/audio/default-device', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ device_id: deviceId }),
    });
    if (!d.success) {
      audioMsg.textContent = `Umschalten fehlgeschlagen: ${d.output || d.message || 'Unbekannter Fehler'}`;
      return false;
    }
    audioMsg.textContent = `Umschaltung erfolgreich: ${deviceName || d.active_output || 'Neues Standardgeraet aktiv'}`;
    await refreshAudio();
    return true;
  } catch (err) {
    audioMsg.textContent = `Umschalten-Fehler: ${err.message}`;
    return false;
  }
}

function normalizeProgramToken(value) {
  return String(value || '')
    .trim()
    .toLowerCase()
    .replace(/\.exe$/i, '')
    .replace(/\s+/g, ' ');
}

function bestProgramMatch(input) {
  const token = normalizeProgramToken(input);
  if (!token) return '';
  const normalized = cachedOpenPrograms.map((p) => ({
    display: p,
    token: normalizeProgramToken(p),
  }));

  const exact = normalized.find((p) => p.token === token);
  if (exact) return exact.display;

  const starts = normalized.find((p) => p.token.startsWith(token));
  if (starts) return starts.display;

  const includes = normalized.find((p) => p.token.includes(token));
  if (includes) return includes.display;

  return '';
}

function groupAudioSessionsByProcess(sessions) {
  const groups = new Map();

  for (const session of Array.isArray(sessions) ? sessions : []) {
    const key = `${session.pid}:${normalizeProgramToken(session.app)}`;
    const existing = groups.get(key);
    if (!existing) {
      groups.set(key, {
        ...session,
        devices: session.device_name ? [session.device_name] : [],
      });
      continue;
    }

    if (session.device_name && !existing.devices.includes(session.device_name)) {
      existing.devices.push(session.device_name);
    }

    const existingState = Number(existing.state || 0);
    const currentState = Number(session.state || 0);
    const existingVolume = Number(existing.volume || 0);
    const currentVolume = Number(session.volume || 0);
    const preferCurrent = currentState > existingState || (currentState === existingState && currentVolume > existingVolume);

    if (preferCurrent) {
      existing.device_name = session.device_name;
      existing.device_id = session.device_id;
      existing.volume = session.volume;
      existing.muted = session.muted;
      existing.state = session.state;
    } else {
      existing.muted = Boolean(existing.muted && session.muted);
      existing.volume = Math.max(existingVolume, currentVolume);
      existing.state = Math.max(existingState, currentState);
    }
  }

  return [...groups.values()]
    .map((item) => ({
      ...item,
      device_name: item.devices.length ? item.devices.join(', ') : (item.device_name || 'Unbekannt'),
    }))
    .sort((a, b) => a.app.localeCompare(b.app, 'de') || a.pid - b.pid);
}

function renderOpenProgramSuggestions() {
  if (openProgramSelect) {
    const options = ['<option value="">Offene Programme auswaehlen...</option>']
      .concat(cachedOpenPrograms.map((p) => `<option value="${p}">${p}</option>`));
    openProgramSelect.innerHTML = options.join('');
  }

  if (openProgramHints) {
    openProgramHints.innerHTML = cachedOpenPrograms.map((p) => `<option value="${p}"></option>`).join('');
  }
}

async function loadOpenPrograms(force = false) {
  const now = Date.now();
  if (!force && now - lastOpenProgramsFetch < 15000) return;

  try {
    const d = await jsonFetch('/api/audio/open-programs?limit=300');
    cachedOpenPrograms = Array.isArray(d.programs) ? d.programs : [];
    renderOpenProgramSuggestions();
    lastOpenProgramsFetch = now;
  } catch (err) {
    if (force) {
      audioMsg.textContent = `Offene Programme konnten nicht geladen werden: ${err.message}`;
    }
  }
}

function renderUserProgramRoutes() {
  if (!userProgramRoutes) return;
  const routes = readUserAudioRoutes();
  if (!routes.length) {
    userProgramRoutes.innerHTML = '<div class="audio-empty">Noch keine Benutzer-Programme hinterlegt.</div>';
    scheduleMasonryLayout(audioGrid);
    return;
  }

  userProgramRoutes.innerHTML = routes.map((r, idx) => {
    const routeToken = normalizeProgramToken(r.program);
    const match = lastAudioSessions.find((s) => {
      const appToken = normalizeProgramToken(s.app);
      return appToken.includes(routeToken) || routeToken.includes(appToken);
    });
    const runningProgram = cachedOpenPrograms.find((p) => {
      const processToken = normalizeProgramToken(p);
      return processToken.includes(routeToken) || routeToken.includes(processToken);
    });
    let status = 'Aktuell nicht als Session erkannt';
    if (match) {
      status = `Aktiv als ${match.app} (PID ${match.pid}) auf ${match.device_name || 'Unbekannt'}`;
    } else if (runningProgram) {
      status = `${runningProgram} laeuft, aber Windows meldet derzeit keine aktive Audio-Session`;
    }
    return `
      <div class="audio-user-route-item" data-route-index="${idx}">
        <div>
          <strong>${r.program}</strong>
          <p class="muted">${status}</p>
        </div>
        <select data-route-device="${idx}">
          ${cachedAudioDevices.map((d) => `<option value="${d.id}" ${d.id === r.deviceId ? 'selected' : ''}>${d.name}${d.is_active_output ? ' (Aktiv)' : ''}</option>`).join('')}
        </select>
        <button class="btn" data-route-apply="${idx}">Jetzt umschalten</button>
        <button class="btn" data-route-remove="${idx}">Entfernen</button>
      </div>
    `;
  }).join('');

  userProgramRoutes.querySelectorAll('[data-route-device]').forEach((sel) => {
    sel.addEventListener('change', () => {
      const idx = parseInt(sel.dataset.routeDevice, 10);
      const all = readUserAudioRoutes();
      if (!Number.isInteger(idx) || !all[idx]) return;
      all[idx].deviceId = sel.value;
      all[idx].deviceName = resolveDeviceNameById(sel.value);
      saveUserAudioRoutes(all);
      audioMsg.textContent = `Zuordnung gespeichert: ${all[idx].program} -> ${all[idx].deviceName}`;
      renderUserProgramRoutes();
    });
  });

  userProgramRoutes.querySelectorAll('[data-route-remove]').forEach((btn) => {
    btn.addEventListener('click', () => {
      const idx = parseInt(btn.dataset.routeRemove, 10);
      const all = readUserAudioRoutes();
      if (!Number.isInteger(idx) || !all[idx]) return;
      const removed = all.splice(idx, 1)[0];
      saveUserAudioRoutes(all);
      audioMsg.textContent = `Eintrag entfernt: ${removed.program}`;
      renderUserProgramRoutes();
    });
  });

  userProgramRoutes.querySelectorAll('[data-route-apply]').forEach((btn) => {
    btn.addEventListener('click', async () => {
      const idx = parseInt(btn.dataset.routeApply, 10);
      const all = readUserAudioRoutes();
      if (!Number.isInteger(idx) || !all[idx]) return;
      const route = all[idx];
      const devName = route.deviceName || resolveDeviceNameById(route.deviceId);
      await setDefaultAudioDevice(route.deviceId, devName);
    });
  });

  scheduleMasonryLayout(audioGrid);
}

function wireUserAudioRoutingControls() {
  if (!addUserProgramBtn || !openRoutingSettingsBtn) return;

  if (openProgramSelect && userProgramName) {
    openProgramSelect.addEventListener('change', () => {
      if (!openProgramSelect.value) return;
      userProgramName.value = openProgramSelect.value;
    });
  }

  if (refreshOpenProgramsBtn) {
    refreshOpenProgramsBtn.addEventListener('click', async () => {
      await loadOpenPrograms(true);
      audioMsg.textContent = `Offene Programme aktualisiert: ${cachedOpenPrograms.length}`;
    });
  }

  addUserProgramBtn.addEventListener('click', () => {
    const typedProgram = (userProgramName?.value || '').trim();
    const deviceId = userProgramDevice?.value || '';
    if (!typedProgram) {
      audioMsg.textContent = 'Bitte einen Programmnamen eingeben.';
      return;
    }
    if (!deviceId) {
      audioMsg.textContent = 'Bitte ein Ausgabegeraet auswaehlen.';
      return;
    }

    const all = readUserAudioRoutes();
    const autoDetectedProgram = bestProgramMatch(typedProgram);
    const program = autoDetectedProgram || typedProgram;
    const key = normalizeProgramToken(program);
    const existing = all.find((r) => normalizeProgramToken(r.program) === key);
    const deviceName = resolveDeviceNameById(deviceId);
    const detectionInfo = autoDetectedProgram && normalizeProgramToken(autoDetectedProgram) !== normalizeProgramToken(typedProgram)
      ? ` (automatisch erkannt als ${autoDetectedProgram})`
      : '';

    if (existing) {
      existing.deviceId = deviceId;
      existing.deviceName = deviceName;
      audioMsg.textContent = `Zuordnung gespeichert: ${program} -> ${deviceName}${detectionInfo}. Hinweis: Die echte Ausgabe-Zuweisung erfolgt in Windows-Routing.`;
    } else {
      all.push({ program, deviceId, deviceName });
      audioMsg.textContent = `Programm gespeichert: ${program} -> ${deviceName}${detectionInfo}. Hinweis: Die echte Ausgabe-Zuweisung erfolgt in Windows-Routing.`;
    }
    saveUserAudioRoutes(all);
    if (userProgramName) userProgramName.value = '';
    if (openProgramSelect) openProgramSelect.value = '';
    if (userRoutingHint) {
      userRoutingHint.textContent = `Gespeichert fuer ${program}. Jetzt "Windows Routing" oeffnen und dort die App auf ${deviceName} setzen.`;
    }
    renderUserProgramRoutes();
  });

  openRoutingSettingsBtn.addEventListener('click', async () => {
    try {
      const d = await jsonFetch('/api/audio/open-routing-settings', { method: 'POST' });
      audioMsg.textContent = d.success ? 'Windows Audio-Routing geoeffnet.' : `Routing konnte nicht geoeffnet werden: ${d.message || 'Unbekannter Fehler'}`;
    } catch (err) {
      audioMsg.textContent = `Routing-Fehler: ${err.message}`;
    }
  });
}

async function refreshAudio() {
  try {
    const d = await jsonFetch('/api/audio');
    if (!d.available) {
      audioLevel.textContent = 'N/A';
      audioMuted.textContent = 'Audio nicht verfuegbar';
      audioMsg.textContent = 'pycaw/comtypes fehlen oder Audio-Endpoint nicht verfuegbar.';
      if (audioDeviceInfo) audioDeviceInfo.textContent = 'Keine Audio-API verfuegbar.';
      if (audioDevices) audioDevices.innerHTML = '<div class="audio-empty">Keine Geraete verfuegbar.</div>';
      if (audioSessions) audioSessions.innerHTML = '<div class="audio-empty">Keine Programm-Sessions verfuegbar.</div>';
      return;
    }
    audioLevel.textContent = `${d.level}%`;
    audioMuted.textContent = d.muted ? 'Stumm' : 'Aktiv';
    audioSlider.value = d.level;
    await Promise.all([loadAudioDevices(), loadAudioSessions(), loadOpenPrograms(false)]);
  } catch (err) {
    audioMsg.textContent = `Audio-Status Fehler: ${err.message}`;
  }
}

function renderAudioDevicesList(activeOutput = '', routingMessage = '') {
  if (!audioDevices) return;

  const activeDevices = cachedAudioDevices.filter((dev) => dev.is_active_output);
  const primaryDevice = activeDevices[0] || cachedAudioDevices[0] || null;
  const hiddenDevices = primaryDevice
    ? cachedAudioDevices.filter((dev) => dev.id !== primaryDevice.id)
    : [];
  const visibleDevices = showAllAudioDevices ? cachedAudioDevices : (primaryDevice ? [primaryDevice] : []);
  const extraCount = hiddenDevices.length;

  if (audioDeviceInfo) {
    const shownText = showAllAudioDevices || extraCount === 0
      ? `${visibleDevices.length} angezeigt`
      : `kompakt: nur aktives Geraet sichtbar, ${extraCount} weitere ausblendbar`;
    audioDeviceInfo.textContent = `Aktives Ausgabegeraet: ${activeOutput || 'Unbekannt'} | ${cachedAudioDevices.length} eindeutige Geraete | ${shownText}${routingMessage ? ` | ${routingMessage}` : ''}`;
  }

  if (!visibleDevices.length) {
    audioDevices.innerHTML = '<div class="audio-empty">Keine Audio-Geraete gefunden.</div>';
    scheduleMasonryLayout(audioGrid);
    return;
  }

  const toggleMarkup = extraCount > 0
    ? `<button class="btn audio-device-toggle" data-audio-device-toggle="${showAllAudioDevices ? 'collapse' : 'expand'}">${showAllAudioDevices ? `Weitere Geraete ausblenden (${extraCount})` : `Weitere Geraete anzeigen (${extraCount})`}</button>`
    : '';

  audioDevices.innerHTML = `
    ${visibleDevices.map((dev) => `
      <div class="audio-device-item${dev.is_active_output ? ' active' : ''}">
        <span>${dev.name}</span>
        <div class="row">
          ${dev.is_active_output ? '<strong>Aktiv</strong>' : `<button class="btn" data-switch-device="${dev.id}" data-switch-name="${dev.name}">Als Standard</button>`}
        </div>
      </div>
    `).join('')}
    ${toggleMarkup}
  `;

  audioDevices.querySelectorAll('[data-switch-device]').forEach((btn) => {
    btn.addEventListener('click', async () => {
      const id = btn.dataset.switchDevice || '';
      const name = btn.dataset.switchName || '';
      await setDefaultAudioDevice(id, name);
    });
  });

  const toggleBtn = audioDevices.querySelector('[data-audio-device-toggle]');
  if (toggleBtn) {
    toggleBtn.addEventListener('click', () => {
      showAllAudioDevices = !showAllAudioDevices;
      renderAudioDevicesList(activeOutput, routingMessage);
    });
  }

  scheduleMasonryLayout(audioGrid);
}

async function loadAudioDevices() {
  try {
    const d = await jsonFetch('/api/audio/devices');
    if (!d.available) {
      audioDeviceInfo.textContent = 'Audio-Geraeteliste nicht verfuegbar.';
      audioDevices.innerHTML = '<div class="audio-empty">Keine Geraete verfuegbar.</div>';
      return;
    }

    const dedup = [];
    const byName = new Map();
    for (const dev of (d.devices || [])) {
      const key = (dev.name || '').trim().toLowerCase();
      if (!key) continue;
      const idx = byName.get(key);
      if (idx == null) {
        byName.set(key, dedup.length);
        dedup.push(dev);
      } else if (dev.is_active_output && !dedup[idx].is_active_output) {
        dedup[idx] = dev;
      }
    }
    dedup.sort((a, b) => (Number(b.is_active_output) - Number(a.is_active_output)) || a.name.localeCompare(b.name, 'de'));
    cachedAudioDevices = dedup;
    refreshUserProgramDeviceSelect();
    renderUserProgramRoutes();
    renderAudioDevicesList(d.active_output || '', d.routing_message || '');
  } catch (err) {
    audioDeviceInfo.textContent = `Geraete-Fehler: ${err.message}`;
    audioDevices.innerHTML = '<div class="audio-empty">Geraete konnten nicht geladen werden.</div>';
  }
}

async function loadAudioSessions() {
  try {
    const d = await jsonFetch('/api/audio/sessions');
    if (!d.available) {
      audioSessions.innerHTML = '<div class="audio-empty">Programm-Sessions nicht verfuegbar.</div>';
      lastAudioSessions = [];
      renderUserProgramRoutes();
      scheduleMasonryLayout(audioGrid);
      return;
    }

    lastAudioSessions = groupAudioSessionsByProcess(Array.isArray(d.sessions) ? d.sessions : []);

    audioSessions.innerHTML = lastAudioSessions.length
      ? lastAudioSessions.map((s) => `
        <div class="audio-session-item" data-pid="${s.pid}">
          <div class="audio-session-head">
            <span>${s.app}</span>
            <span class="muted">PID ${s.pid} | ${s.device_name || 'Unbekannt'} | ${s.volume}% ${s.muted ? '| Stumm' : ''}</span>
          </div>
          <div class="row">
            <input type="range" min="0" max="100" value="${s.volume}" data-session-volume="${s.pid}" />
            <button class="btn" data-session-mute="${s.pid}" data-state="${s.muted ? 0 : 1}">${s.muted ? 'Unmute' : 'Mute'}</button>
          </div>
        </div>
      `).join('')
      : '<div class="audio-empty">Keine aktiven Audio-Programme gefunden.</div>';

    audioSessions.querySelectorAll('[data-session-volume]').forEach((slider) => {
      slider.addEventListener('change', async () => {
        const pid = parseInt(slider.dataset.sessionVolume, 10);
        const level = parseInt(slider.value, 10) || 0;
        try {
          await jsonFetch(`/api/audio/session/${pid}/volume/${Math.max(0, Math.min(100, level))}`, { method: 'POST' });
          await loadAudioSessions();
        } catch (err) {
          audioMsg.textContent = `Session-Volume Fehler: ${err.message}`;
        }
      });
    });

    audioSessions.querySelectorAll('[data-session-mute]').forEach((btn) => {
      btn.addEventListener('click', async () => {
        const pid = parseInt(btn.dataset.sessionMute, 10);
        const state = parseInt(btn.dataset.state, 10) || 0;
        try {
          await jsonFetch(`/api/audio/session/${pid}/mute/${state}`, { method: 'POST' });
          await loadAudioSessions();
        } catch (err) {
          audioMsg.textContent = `Session-Mute Fehler: ${err.message}`;
        }
      });
    });

    scheduleMasonryLayout(audioGrid);
  } catch (err) {
    lastAudioSessions = [];
    renderUserProgramRoutes();
    audioSessions.innerHTML = `<div class="audio-empty">Session-Fehler: ${err.message}</div>`;
    scheduleMasonryLayout(audioGrid);
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

function buildCustomVars(accent, gradFrom, bg) {
  function brighten(hex, amount) {
    const r = Math.min(255, parseInt(hex.slice(1, 3), 16) + amount);
    const g = Math.min(255, parseInt(hex.slice(3, 5), 16) + amount);
    const b = Math.min(255, parseInt(hex.slice(5, 7), 16) + amount);
    return '#' + [r, g, b].map((v) => v.toString(16).padStart(2, '0')).join('');
  }
  return {
    '--accent':    accent,
    '--bg':        bg,
    '--card':      brighten(bg, 8),
    '--line':      brighten(bg, 30),
    '--muted':     brighten(bg, 100),
    '--grad-from': gradFrom,
    '--grad-to':   bg,
  };
}

function applyTheme(vars) {
  const root = document.documentElement;
  for (const [prop, val] of Object.entries(vars)) {
    root.style.setProperty(prop, val);
  }
}

function saveTheme(id, vars) {
  localStorage.setItem(THEME_KEY, JSON.stringify({ id, vars }));
}

function loadAndApplyTheme() {
  try {
    const raw = localStorage.getItem(THEME_KEY);
    if (!raw) return;
    const data = JSON.parse(raw);
    if (data && data.vars) {
      applyTheme(data.vars);
      document.querySelectorAll('.theme-preset-btn').forEach((btn) => {
        btn.classList.toggle('active', btn.dataset.theme === data.id);
      });
      if (data.id === 'custom') {
        const accEl = document.getElementById('customAccent');
        const gfEl  = document.getElementById('customGradFrom');
        const bgEl  = document.getElementById('customBg');
        if (accEl) accEl.value = data.vars['--accent']    || '#4aa3ff';
        if (gfEl)  gfEl.value  = data.vars['--grad-from'] || '#14315a';
        if (bgEl)  bgEl.value  = data.vars['--bg']        || '#071220';
      }
    }
  } catch { /* ignore */ }
}

function wireThemeControls() {
  const presetContainer = document.getElementById('themePresets');
  THEMES.forEach((theme) => {
    const btn = document.createElement('button');
    btn.type = 'button';
    btn.className = 'theme-preset-btn';
    btn.dataset.theme = theme.id;
    btn.innerHTML = `<span class="theme-swatch"><span style="background:${theme.s2}"></span><span style="background:${theme.s1};opacity:0.75"></span></span><span>${theme.label}</span>`;
    btn.addEventListener('click', () => {
      applyTheme(theme.vars);
      saveTheme(theme.id, theme.vars);
      document.querySelectorAll('.theme-preset-btn').forEach((b) => b.classList.remove('active'));
      btn.classList.add('active');
    });
    presetContainer.appendChild(btn);
  });

  document.getElementById('applyCustomThemeBtn').addEventListener('click', () => {
    const acc  = document.getElementById('customAccent').value;
    const gf   = document.getElementById('customGradFrom').value;
    const bg   = document.getElementById('customBg').value;
    const vars = buildCustomVars(acc, gf, bg);
    applyTheme(vars);
    saveTheme('custom', vars);
    document.querySelectorAll('.theme-preset-btn').forEach((b) => b.classList.remove('active'));
  });

  document.getElementById('resetThemeBtn').addEventListener('click', () => {
    localStorage.removeItem(THEME_KEY);
    const t = THEMES.find((t) => t.id === 'ozean');
    applyTheme(t.vars);
    document.querySelectorAll('.theme-preset-btn').forEach((b) => {
      b.classList.toggle('active', b.dataset.theme === 'ozean');
    });
    const accEl = document.getElementById('customAccent');
    const gfEl  = document.getElementById('customGradFrom');
    const bgEl  = document.getElementById('customBg');
    if (accEl) accEl.value = '#4aa3ff';
    if (gfEl)  gfEl.value  = '#14315a';
    if (bgEl)  bgEl.value  = '#071220';
  });

  loadAndApplyTheme();
}

async function init() {
  document.getElementById('gitStatusBtn').onclick = refreshGit;
  document.getElementById('gitPullBtn').onclick = pullGit;
  document.getElementById('reloadLogBtn').onclick = () => openLog(logSelect.value);
  document.getElementById('restartBtn').onclick = restartGui;
  document.getElementById('saveLayoutBtn').onclick = () => saveLayout(dashboardGrid, LAYOUT_KEY, true, layoutMsg);
  document.getElementById('resetLayoutBtn').onclick = () => resetLayout(LAYOUT_KEY);
  logSelect.onchange = () => openLog(logSelect.value);

  wirePageMenu();
  wireSizeControls(dashboardGrid, LAYOUT_KEY, layoutMsg);
  wireSizeControls(audioGrid, AUDIO_LAYOUT_KEY);
  applyLayout(readLayout(LAYOUT_KEY), dashboardGrid);
  applyLayout(readLayout(AUDIO_LAYOUT_KEY), audioGrid);
  renderWidgetMenu();
  wireDragDrop(dashboardGrid, LAYOUT_KEY, renderWidgetMenu);
  wireDragDrop(audioGrid, AUDIO_LAYOUT_KEY);
  window.addEventListener('resize', () => scheduleMasonryLayout(audioGrid));
  wireAudioControls();
  wireUserAudioRoutingControls();
  wireThemeControls();

  try {
    await loadSystem();
  } catch {
    sysInfo.textContent = 'Systeminfo nicht verfuegbar';
  }

  await Promise.all([refreshAll(), refreshGit(), loadLogs(), loadTools()]);
  scheduleMasonryLayout(audioGrid);
  setInterval(refreshAll, 5000);
  setInterval(refreshGit, 20000);
}

init();

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
const reloadDependenciesBtn = document.getElementById('reloadDependenciesBtn');
const dependencySummary = document.getElementById('dependencySummary');
const dependencyList = document.getElementById('dependencyList');
const dependencyMsg = document.getElementById('dependencyMsg');
const reloadDashboardDependenciesBtn = document.getElementById('reloadDashboardDependenciesBtn');
const dashboardDependencySummary = document.getElementById('dashboardDependencySummary');
const dashboardDependencyList = document.getElementById('dashboardDependencyList');
const dashboardDependencyMsg = document.getElementById('dashboardDependencyMsg');
const toolList = document.getElementById('toolList');
const toolMsg = document.getElementById('toolMsg');
const reloadLaunchersBtn = document.getElementById('reloadLaunchersBtn');
const launcherList = document.getElementById('launcherList');
const launcherMsg = document.getElementById('launcherMsg');
const launcherName = document.getElementById('launcherName');
const launcherKind = document.getElementById('launcherKind');
const launcherToolId = document.getElementById('launcherToolId');
const launcherTarget = document.getElementById('launcherTarget');
const launcherArgs = document.getElementById('launcherArgs');
const launcherNote = document.getElementById('launcherNote');
const launcherToolField = document.getElementById('launcherToolField');
const launcherTargetField = document.getElementById('launcherTargetField');
const launcherArgsField = document.getElementById('launcherArgsField');
const saveLauncherBtn = document.getElementById('saveLauncherBtn');
const resetLauncherFormBtn = document.getElementById('resetLauncherFormBtn');
const launcherConfigHint = document.getElementById('launcherConfigHint');

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
const logsGrid = document.getElementById('logsGrid');
const toolsGrid = document.getElementById('toolsGrid');
const setupGrid = document.getElementById('setupGrid');
const widgetMenu = document.getElementById('widgetMenu');
const widgetMenuTitle = document.getElementById('widgetMenuTitle');
const layoutMsg = document.getElementById('layoutMsg');

const LAYOUT_KEY = 'bockis_dashboard_layout_v4';
const AUDIO_LAYOUT_KEY = 'bockis_audio_layout_v1';
const LOGS_LAYOUT_KEY = 'bockis_logs_layout_v1';
const TOOLS_LAYOUT_KEY = 'bockis_tools_layout_v1';
const SETUP_LAYOUT_KEY = 'bockis_setup_layout_v1';
const PAGE_KEY = 'bockis_dashboard_page_v1';
const LEGACY_STORAGE_KEYS = {
  [LAYOUT_KEY]: ['bockis_dashboard_layout_v3', 'bockis_dashboard_layout_v2', 'bockis_dashboard_layout_v1'],
  [AUDIO_LAYOUT_KEY]: [],
  [LOGS_LAYOUT_KEY]: [],
  [TOOLS_LAYOUT_KEY]: [],
  [SETUP_LAYOUT_KEY]: [],
};
const PAGE_ICONS = {
  overview: 'grid',
  audio: 'speaker',
  logs: 'file',
  tools: 'wrench',
  setup: 'sliders',
};
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
  'logs-main': 'Logs',
  'logs-dependencies': 'Win-GUI-Dependencies',
  'logs-dashboard-dependencies': 'Dashboard-Dependencies',
  'tools-main': 'Tools',
  'tools-launchers': 'Schnellstart',
  'tools-launcher-config': 'Launcher-Konfiguration',
  'setup-theme': 'Erscheinungsbild',
  'setup-git': 'Git / Setup',
};
const WIDGET_ICONS = {
  monitoring: 'activity',
  'net-upload': 'upload',
  'net-download': 'download',
  disks: 'drive',
  processes: 'cpu',
  'audio-volume': 'speaker',
  'audio-devices': 'headphones',
  'audio-sessions': 'equalizer',
  'audio-routing': 'route',
  'logs-main': 'file',
  'logs-dependencies': 'box',
  'logs-dashboard-dependencies': 'layers',
  'tools-main': 'wrench',
  'tools-launchers': 'grid',
  'tools-launcher-config': 'sliders',
  'setup-theme': 'palette',
  'setup-git': 'git-branch',
};
const PAGE_LAYOUTS = {
  overview: { label: 'Uebersicht', layoutEl: dashboardGrid, storageKey: LAYOUT_KEY },
  audio: { label: 'Audio', layoutEl: audioGrid, storageKey: AUDIO_LAYOUT_KEY },
  logs: { label: 'Logs', layoutEl: logsGrid, storageKey: LOGS_LAYOUT_KEY },
  tools: { label: 'Tools', layoutEl: toolsGrid, storageKey: TOOLS_LAYOUT_KEY },
  setup: { label: 'Setup', layoutEl: setupGrid, storageKey: SETUP_LAYOUT_KEY },
};
const SIZE_PRESETS = ['1-3', '1-2', '2-3', 'full', 'min'];
const THEME_KEY = 'bockis_theme_v1';
const AUDIO_USER_ROUTES_KEY = 'bockis_audio_user_routes_v1';
const LAUNCHERS_FALLBACK_KEY = 'bockis_custom_launchers_v1';
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
let pendingThemeId = 'ozean';
let availableTools = [];
let customLaunchers = [];
let editingLauncherId = '';
let launcherApiAvailable = true;
const masonryFrames = new Map();
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

function isHttp404(err) {
  return /(^|\s)404\s/i.test(String(err?.message || err || ''));
}

function isMasonryLayout(layoutEl) {
  return Boolean(layoutEl && layoutEl.classList && layoutEl.classList.contains('layout'));
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
  const key = layoutEl.id || 'layout';
  const prev = masonryFrames.get(key);
  if (prev) cancelAnimationFrame(prev);
  const frame = requestAnimationFrame(() => {
    refreshMasonryLayout(layoutEl);
    masonryFrames.delete(key);
  });
  masonryFrames.set(key, frame);
}

function getCards(layoutEl = dashboardGrid) {
  if (!layoutEl) return [];
  return Array.from(layoutEl.querySelectorAll('.card[data-widget]'));
}

function getCurrentPage() {
  return document.querySelector('.page.active')?.dataset.page || (localStorage.getItem(PAGE_KEY) || 'overview');
}

function getIconMarkup(iconName) {
  if (!iconName) return '';
  return `<span class="icon-inline"><svg viewBox="0 0 24 24" aria-hidden="true" focusable="false"><use href="#icon-${iconName}"></use></svg></span>`;
}

function decoratePageMenuIcons() {
  document.querySelectorAll('.menu-nav-btn').forEach((btn) => {
    if (btn.dataset.iconDecorated === '1') return;
    const page = btn.dataset.pageTarget || '';
    const label = btn.textContent.trim();
    btn.innerHTML = `${getIconMarkup(PAGE_ICONS[page] || 'grid')}<span>${label}</span>`;
    btn.dataset.iconDecorated = '1';
  });
}

function decorateCardIcons() {
  document.querySelectorAll('.card[data-widget]').forEach((card) => {
    const title = card.querySelector('.card-head h2');
    const widget = card.dataset.widget || '';
    const iconName = WIDGET_ICONS[widget] || null;
    if (!title || !iconName || title.querySelector('.icon-inline')) return;
    title.insertAdjacentHTML('afterbegin', getIconMarkup(iconName));
  });
}

function getPageLayoutConfig(page = getCurrentPage()) {
  return PAGE_LAYOUTS[page] || null;
}

function escapeHtml(value) {
  return String(value || '')
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}

function readLauncherFallback() {
  try {
    const raw = localStorage.getItem(LAUNCHERS_FALLBACK_KEY);
    const data = raw ? JSON.parse(raw) : [];
    return Array.isArray(data) ? data : [];
  } catch {
    return [];
  }
}

function saveLauncherFallback(items) {
  localStorage.setItem(LAUNCHERS_FALLBACK_KEY, JSON.stringify(Array.isArray(items) ? items : []));
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
    if (raw) return JSON.parse(raw);

    const legacyKeys = LEGACY_STORAGE_KEYS[storageKey] || [];
    for (const legacyKey of legacyKeys) {
      const legacyRaw = localStorage.getItem(legacyKey);
      if (!legacyRaw) continue;
      const parsed = JSON.parse(legacyRaw);
      localStorage.setItem(storageKey, legacyRaw);
      return parsed;
    }

    return null;
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

function renderWidgetMenu(page = getCurrentPage()) {
  const pageConfig = getPageLayoutConfig(page);
  const layoutEl = pageConfig?.layoutEl || null;

  if (widgetMenuTitle) {
    widgetMenuTitle.textContent = `Kacheln (${pageConfig?.label || 'Seite'})`;
  }

  widgetMenu.innerHTML = '';
  if (!layoutEl) {
    widgetMenu.innerHTML = '<div class="audio-empty">Keine Kacheln auf dieser Seite.</div>';
    return;
  }

  getCards(layoutEl).forEach((card) => {
    const w = card.dataset.widget;
    const item = document.createElement('label');
    item.className = 'menu-item';
    item.innerHTML = `<input type="checkbox" /> <span class="menu-item-label">${getIconMarkup(WIDGET_ICONS[w] || null)}<span>${WIDGET_LABELS[w] || w}</span></span>`;
    const cb = item.querySelector('input');
    cb.checked = card.style.display !== 'none';
    cb.addEventListener('change', () => {
      card.style.display = cb.checked ? '' : 'none';
      saveLayout(layoutEl, pageConfig.storageKey, false, layoutMsg);
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
  renderWidgetMenu(page);
  document.querySelectorAll('.page.active .layout').forEach((layoutEl) => scheduleMasonryLayout(layoutEl));
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

  scheduleMasonryLayout(dashboardGrid);
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
    scheduleMasonryLayout(logsGrid);
  } catch (err) {
    logContent.textContent = `Log-Laden fehlgeschlagen: ${err.message}`;
    scheduleMasonryLayout(logsGrid);
  }
}

function getDependencyAction(dep) {
  if (!dep || !dep.WingetId) return null;
  if (!dep.Found && dep.Available) return 'install';
  if (dep.UpdateAvailable) return 'upgrade';
  return null;
}

function renderDependencyStatus(data) {
  if (!dependencySummary || !dependencyList) return;

  if (!data?.available) {
    dependencySummary.textContent = data?.message || 'Dependency-Check nicht verfuegbar.';
    dependencyList.innerHTML = '<div class="audio-empty">Keine Dependency-Daten verfuegbar.</div>';
    scheduleMasonryLayout(logsGrid);
    return;
  }

  const deps = Array.isArray(data.dependencies) ? data.dependencies : [];
  dependencySummary.textContent = data.all_satisfied
    ? `Systemstatus ok | ${deps.length} Abhaengigkeiten geprueft`
    : `Pruefung abgeschlossen | ${deps.length} Abhaengigkeiten | Eingriffe empfohlen`;

  dependencyList.innerHTML = deps.length
    ? `
      <div class="dependency-table-head dependency-table-head-actions">
        <span>Paket</span>
        <span>Version</span>
        <span>Status</span>
        <span>Aktion</span>
      </div>
      ${deps.map((dep) => {
        const action = getDependencyAction(dep);
        const versionText = dep.Version || dep.AvailableVersion || '-';
        const nextVersion = dep.UpdateAvailable && dep.AvailableVersion ? ` → ${dep.AvailableVersion}` : '';
        return `
          <div class="dependency-table-row dependency-table-row-actions dependency-${String(dep.StatusColor || '').toLowerCase()}">
            <div class="dependency-col-name-wrap">
              <strong class="dependency-col-name">${dep.Name || 'Unbekannt'}</strong>
              <span class="muted dependency-col-description">${dep.Description || ''}</span>
            </div>
            <span class="dependency-col-installed">${versionText}${nextVersion}</span>
            <span class="dependency-status">${dep.Status || '-'}</span>
            <span class="dependency-col-action">${action ? `<button class="btn" data-dependency-action="${action}" data-winget-id="${dep.WingetId}" data-dependency-name="${dep.Name || ''}">${action === 'upgrade' ? 'Update' : 'Installieren'}</button>` : ''}</span>
          </div>
        `;
      }).join('')}
    `
    : '<div class="audio-empty">Keine Dependency-Daten gefunden.</div>';

  dependencyList.querySelectorAll('[data-dependency-action]').forEach((btn) => {
    btn.addEventListener('click', async () => {
      const action = btn.dataset.dependencyAction || 'install';
      const wingetId = btn.dataset.wingetId || '';
      const name = btn.dataset.dependencyName || wingetId;
      if (!wingetId) return;
      dependencyMsg.textContent = `${action === 'upgrade' ? 'Update' : 'Installation'} laeuft: ${name}`;
      btn.disabled = true;
      try {
        const result = await jsonFetch('/api/dependencies/action', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ winget_id: wingetId, action }),
        });
        dependencyMsg.textContent = `${result.message || ''}\n${result.output || ''}`.trim();
        renderDependencyStatus(result.status || { available: false, message: 'Status konnte nicht aktualisiert werden.' });
      } catch (err) {
        dependencyMsg.textContent = `Dependency-Aktion fehlgeschlagen: ${err.message}`;
      }
    });
  });

  scheduleMasonryLayout(logsGrid);
}

async function loadDependencyStatus() {
  if (dependencyMsg) dependencyMsg.textContent = 'Dependency-Check laeuft...';
  try {
    const data = await jsonFetch('/api/dependencies');
    renderDependencyStatus(data);
    if (dependencyMsg) dependencyMsg.textContent = 'Dependency-Check abgeschlossen.';
  } catch (err) {
    if (dependencySummary) dependencySummary.textContent = `Dependency-Check Fehler: ${err.message}`;
    if (dependencyList) dependencyList.innerHTML = '<div class="audio-empty">Dependency-Check konnte nicht geladen werden.</div>';
    if (dependencyMsg) dependencyMsg.textContent = `Dependency-Check Fehler: ${err.message}`;
    scheduleMasonryLayout(logsGrid);
  }
}

function renderDashboardDependencyStatus(data) {
  if (!dashboardDependencySummary || !dashboardDependencyList) return;

  if (!data?.available) {
    dashboardDependencySummary.textContent = data?.message || 'Dashboard-Dependencies nicht verfuegbar.';
    dashboardDependencyList.innerHTML = '<div class="audio-empty">Keine Dashboard-Dependency-Daten verfuegbar.</div>';
    scheduleMasonryLayout(logsGrid);
    return;
  }

  const deps = Array.isArray(data.dependencies) ? data.dependencies : [];
  dashboardDependencySummary.textContent = data.all_satisfied
    ? `Dashboard ok | Python ${data.python_version} | ${deps.length} Checks`
    : `Python ${data.python_version} | ${data.missing_count || 0} fehlend | ${data.outdated_count || 0} abweichend`;

  dashboardDependencyList.innerHTML = deps.length
    ? `
      <div class="dependency-table-head">
        <span>Paket</span>
        <span>Soll</span>
        <span>Ist</span>
        <span>Status</span>
      </div>
      ${deps.map((dep) => `
        <div class="dependency-table-row dependency-${String(dep.status_color || '').toLowerCase()}">
          <strong class="dependency-col-name">${dep.name || 'Unbekannt'}</strong>
          <span class="dependency-col-required">${dep.required || '-'}</span>
          <span class="dependency-col-installed">${dep.installed_version || 'nicht installiert'}</span>
          <span class="dependency-status">${dep.status || '-'}</span>
        </div>
      `).join('')}
    `
    : '<div class="audio-empty">Keine Dashboard-Dependencies gefunden.</div>';

  scheduleMasonryLayout(logsGrid);
}

async function loadDashboardDependencyStatus() {
  if (dashboardDependencyMsg) dashboardDependencyMsg.textContent = 'Dashboard-Dependency-Check laeuft...';
  try {
    const data = await jsonFetch('/api/dashboard/dependencies');
    renderDashboardDependencyStatus(data);
    if (dashboardDependencyMsg) dashboardDependencyMsg.textContent = `Quelle: ${data.requirements_path || 'requirements.txt'}`;
  } catch (err) {
    if (dashboardDependencySummary) dashboardDependencySummary.textContent = `Dashboard-Dependency-Check Fehler: ${err.message}`;
    if (dashboardDependencyList) dashboardDependencyList.innerHTML = '<div class="audio-empty">Dashboard-Dependencies konnten nicht geladen werden.</div>';
    if (dashboardDependencyMsg) dashboardDependencyMsg.textContent = `Dashboard-Dependency-Check Fehler: ${err.message}`;
    scheduleMasonryLayout(logsGrid);
  }
}

async function loadTools() {
  try {
    const tools = await jsonFetch('/api/tools');
    availableTools = Array.isArray(tools) ? tools : [];
    toolList.innerHTML = '';
    for (const t of availableTools) {
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
    populateLauncherToolSelect();
  } catch (err) {
    toolMsg.textContent = `Tool-Liste fehlgeschlagen: ${err.message}`;
  }
}

function populateLauncherToolSelect(selected = '') {
  if (!launcherToolId) return;
  launcherToolId.innerHTML = availableTools.length
    ? availableTools.map((tool) => `<option value="${escapeHtml(tool.id)}">${escapeHtml(tool.label)}</option>`).join('')
    : '<option value="">Keine Tools verfuegbar</option>';
  if (selected) launcherToolId.value = selected;
}

function syncLauncherForm() {
  if (!launcherKind) return;
  const kind = launcherKind.value || 'tool';
  if (launcherToolField) launcherToolField.classList.toggle('launcher-hidden', kind !== 'tool');
  if (launcherTargetField) launcherTargetField.classList.toggle('launcher-hidden', kind === 'tool');
  if (launcherArgsField) launcherArgsField.classList.toggle('launcher-hidden', kind !== 'app');

  if (launcherConfigHint) {
    if (kind === 'tool') {
      launcherConfigHint.textContent = 'Waehle ein vorhandenes Dashboard-Tool und mache daraus eine eigene Schnellstart-Kachel.';
    } else if (kind === 'app') {
      launcherConfigHint.textContent = 'Starte lokale Programme, MMCs, Ordner oder Dienste per Start-Process, optional mit Argumenten.';
    } else {
      launcherConfigHint.textContent = 'Lege Webseiten oder Netzwerkdienste wie Router, NAS, Proxmox oder Drucker-Weboberflaechen als Kachel ab.';
    }
  }

  if (launcherTarget) {
    launcherTarget.placeholder = kind === 'url'
      ? 'https://router.local oder http://192.168.178.1'
      : 'C:\\Windows\\System32\\services.msc oder \\NAS\\Freigabe';
  }
}

function resetLauncherForm() {
  editingLauncherId = '';
  if (launcherName) launcherName.value = '';
  if (launcherKind) launcherKind.value = 'tool';
  if (launcherTarget) launcherTarget.value = '';
  if (launcherArgs) launcherArgs.value = '';
  if (launcherNote) launcherNote.value = '';
  populateLauncherToolSelect();
  syncLauncherForm();
  if (saveLauncherBtn) saveLauncherBtn.textContent = 'Launcher speichern';
}

function fillLauncherForm(launcher) {
  if (!launcher) return;
  editingLauncherId = launcher.id || '';
  if (launcherName) launcherName.value = launcher.title || '';
  if (launcherKind) launcherKind.value = launcher.kind || 'tool';
  populateLauncherToolSelect(launcher.tool_id || '');
  if (launcherTarget) launcherTarget.value = launcher.target || '';
  if (launcherArgs) launcherArgs.value = launcher.args || '';
  if (launcherNote) launcherNote.value = launcher.note || '';
  syncLauncherForm();
  if (saveLauncherBtn) saveLauncherBtn.textContent = 'Launcher aktualisieren';
}

function getLauncherKindLabel(kind) {
  if (kind === 'tool') return 'Tool';
  if (kind === 'app') return 'App / Dienst';
  return 'Website / Netzwerk';
}

async function runLauncher(launcherId) {
  if (!launcherId) return;
  const launcher = customLaunchers.find((item) => item.id === launcherId);
  if (launcherMsg) launcherMsg.textContent = `Starte ${launcher?.title || 'Launcher'}...`;

  if (!launcherApiAvailable) {
    if (!launcher) {
      if (launcherMsg) launcherMsg.textContent = 'Launcher nicht gefunden.';
      return;
    }

    if (launcher.kind === 'url') {
      window.open(launcher.target, '_blank', 'noopener,noreferrer');
      if (launcherMsg) launcherMsg.textContent = `${launcher.title} im Browser geoeffnet.`;
      return;
    }

    if (launcher.kind === 'tool' && launcher.tool_id) {
      try {
        const result = await jsonFetch(`/api/tools/run/${encodeURIComponent(launcher.tool_id)}`, { method: 'POST' });
        if (launcherMsg) launcherMsg.textContent = `${result.message || ''}\n${result.output || ''}`.trim();
      } catch (err) {
        if (launcherMsg) launcherMsg.textContent = `Launcher-Fehler: ${err.message}`;
      }
      return;
    }

    if (launcherMsg) launcherMsg.textContent = 'App-Launcher benoetigen den aktualisierten Python-Backend-Prozess. Bitte Dashboard/GUI neu starten.';
    return;
  }

  try {
    const result = await jsonFetch(`/api/launchers/run/${encodeURIComponent(launcherId)}`, { method: 'POST' });
    if (launcherMsg) launcherMsg.textContent = `${result.message || ''}\n${result.output || ''}`.trim();
  } catch (err) {
    if (launcherMsg) launcherMsg.textContent = `Launcher-Fehler: ${err.message}`;
  }
}

function renderLaunchers() {
  if (!launcherList) return;
  if (!customLaunchers.length) {
    launcherList.innerHTML = '<div class="audio-empty">Noch keine Schnellstart-Kacheln angelegt.</div>';
    scheduleMasonryLayout(toolsGrid);
    return;
  }

  launcherList.innerHTML = customLaunchers.map((launcher) => `
    <div class="launcher-card">
      <button class="launcher-run" type="button" data-launcher-run="${escapeHtml(launcher.id)}">
        <strong>${escapeHtml(launcher.title)}</strong>
        <p class="launcher-note">${escapeHtml(launcher.note || launcher.target || getLauncherKindLabel(launcher.kind))}</p>
      </button>
      <div class="launcher-meta">
        <span class="launcher-kind">${escapeHtml(getLauncherKindLabel(launcher.kind))}</span>
        <span>${escapeHtml(launcher.kind === 'tool' ? (availableTools.find((tool) => tool.id === launcher.tool_id)?.label || launcher.tool_id || '-') : launcher.target || '-')}</span>
      </div>
      <div class="launcher-actions">
        <button class="btn" type="button" data-launcher-edit="${escapeHtml(launcher.id)}">Bearbeiten</button>
        <button class="btn warn" type="button" data-launcher-delete="${escapeHtml(launcher.id)}">Entfernen</button>
      </div>
    </div>
  `).join('');

  launcherList.querySelectorAll('[data-launcher-run]').forEach((btn) => {
    btn.addEventListener('click', () => runLauncher(btn.dataset.launcherRun || ''));
  });
  launcherList.querySelectorAll('[data-launcher-edit]').forEach((btn) => {
    btn.addEventListener('click', () => {
      const launcher = customLaunchers.find((item) => item.id === (btn.dataset.launcherEdit || ''));
      fillLauncherForm(launcher);
    });
  });
  launcherList.querySelectorAll('[data-launcher-delete]').forEach((btn) => {
    btn.addEventListener('click', async () => {
      const launcherId = btn.dataset.launcherDelete || '';
      const launcher = customLaunchers.find((item) => item.id === launcherId);
      if (!launcherId || !confirm(`Launcher '${launcher?.title || launcherId}' entfernen?`)) return;

      if (!launcherApiAvailable) {
        customLaunchers = customLaunchers.filter((item) => item.id !== launcherId);
        saveLauncherFallback(customLaunchers);
        if (launcherMsg) launcherMsg.textContent = 'Launcher lokal entfernt. Backend-API nicht verfuegbar.';
        if (editingLauncherId === launcherId) resetLauncherForm();
        renderLaunchers();
        return;
      }

      try {
        const result = await jsonFetch(`/api/launchers/${encodeURIComponent(launcherId)}`, { method: 'DELETE' });
        customLaunchers = Array.isArray(result.launchers) ? result.launchers : [];
        if (launcherMsg) launcherMsg.textContent = result.message || 'Launcher entfernt.';
        if (editingLauncherId === launcherId) resetLauncherForm();
        renderLaunchers();
      } catch (err) {
        if (launcherMsg) launcherMsg.textContent = `Loeschen fehlgeschlagen: ${err.message}`;
      }
    });
  });

  scheduleMasonryLayout(toolsGrid);
}

async function loadLaunchers() {
  try {
    const data = await jsonFetch('/api/launchers');
    launcherApiAvailable = true;
    customLaunchers = Array.isArray(data.launchers) ? data.launchers : [];
    saveLauncherFallback(customLaunchers);
    renderLaunchers();
  } catch (err) {
    if (isHttp404(err)) {
      launcherApiAvailable = false;
      customLaunchers = readLauncherFallback();
      renderLaunchers();
      if (launcherMsg) {
        launcherMsg.textContent = customLaunchers.length
          ? 'Launcher-API noch nicht verfuegbar. Lokale Browser-Speicherung aktiv, bis das Python-Dashboard neu gestartet wurde.'
          : 'Launcher-API noch nicht verfuegbar. Lokale Browser-Speicherung aktiv. App-Launcher benoetigen nach wie vor einen Neustart des Python-Dashboards.';
      }
      return;
    }
    if (launcherMsg) launcherMsg.textContent = `Launcher konnten nicht geladen werden: ${err.message}`;
    if (launcherList) launcherList.innerHTML = '<div class="audio-empty">Launcher konnten nicht geladen werden.</div>';
    scheduleMasonryLayout(toolsGrid);
  }
}

async function saveLauncher() {
  if (!launcherName || !launcherKind) return;
  const payload = {
    id: editingLauncherId,
    title: launcherName.value.trim(),
    kind: launcherKind.value,
    tool_id: launcherToolId?.value || '',
    target: launcherTarget?.value.trim() || '',
    args: launcherArgs?.value.trim() || '',
    note: launcherNote?.value.trim() || '',
  };

  if (!payload.title) {
    if (launcherMsg) launcherMsg.textContent = 'Bitte einen Namen fuer die Kachel angeben.';
    return;
  }

  if (payload.kind === 'tool' && !payload.tool_id) {
    if (launcherMsg) launcherMsg.textContent = 'Bitte ein Tool waehlen.';
    return;
  }

  if ((payload.kind === 'app' || payload.kind === 'url') && !payload.target) {
    if (launcherMsg) launcherMsg.textContent = 'Bitte ein Ziel angeben.';
    return;
  }

  if (!launcherApiAvailable) {
    const localId = editingLauncherId || `${(payload.title || 'launcher').toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-+|-+$/g, '') || 'launcher'}-${Date.now()}`;
    const localLauncher = { ...payload, id: localId };
    const existingIndex = customLaunchers.findIndex((item) => item.id === localId);
    if (existingIndex >= 0) customLaunchers[existingIndex] = localLauncher;
    else customLaunchers.push(localLauncher);
    saveLauncherFallback(customLaunchers);
    if (launcherMsg) launcherMsg.textContent = 'Launcher lokal gespeichert. Fuer App-Starts bitte Python-Dashboard neu starten.';
    renderLaunchers();
    resetLauncherForm();
    return;
  }

  try {
    const result = await jsonFetch('/api/launchers', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload),
    });
    if (!result.success) {
      if (launcherMsg) launcherMsg.textContent = result.message || 'Launcher konnte nicht gespeichert werden.';
      return;
    }
    customLaunchers = Array.isArray(result.launchers) ? result.launchers : [];
    if (launcherMsg) launcherMsg.textContent = result.message || 'Launcher gespeichert.';
    renderLaunchers();
    resetLauncherForm();
  } catch (err) {
    if (launcherMsg) launcherMsg.textContent = `Speichern fehlgeschlagen: ${err.message}`;
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

function getOutputAudioDevices() {
  return cachedAudioDevices.filter((d) => d.is_output !== false && d.kind !== 'input');
}

function refreshUserProgramDeviceSelect(selected = '') {
  if (!userProgramDevice) return;
  const outputDevices = getOutputAudioDevices();
  const options = outputDevices.length
    ? outputDevices.map((d) => `<option value="${d.id}">${d.name}${d.is_active_output ? ' (Aktiv)' : ''}</option>`).join('')
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
          ${getOutputAudioDevices().map((d) => `<option value="${d.id}" ${d.id === r.deviceId ? 'selected' : ''}>${d.name}${d.is_active_output ? ' (Aktiv)' : ''}</option>`).join('')}
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

function renderAudioDevicesList(activeOutput = '', activeInput = '', routingMessage = '') {
  if (!audioDevices) return;

  const primaryDevices = [];
  const activeOutputDevice = cachedAudioDevices.find((dev) => dev.is_active_output) || null;
  const activeInputDevice = cachedAudioDevices.find((dev) => dev.is_active_input) || null;
  if (activeOutputDevice) primaryDevices.push(activeOutputDevice);
  if (activeInputDevice && (!activeOutputDevice || activeInputDevice.id !== activeOutputDevice.id)) primaryDevices.push(activeInputDevice);
  if (!primaryDevices.length && cachedAudioDevices[0]) primaryDevices.push(cachedAudioDevices[0]);

  const primaryIds = new Set(primaryDevices.map((dev) => dev.id));
  const hiddenDevices = cachedAudioDevices.filter((dev) => !primaryIds.has(dev.id));
  const visibleDevices = showAllAudioDevices ? cachedAudioDevices : primaryDevices;
  const extraCount = hiddenDevices.length;
  const outputCount = cachedAudioDevices.filter((dev) => dev.kind === 'output').length;
  const inputCount = cachedAudioDevices.filter((dev) => dev.kind === 'input').length;
  const activeDevicesCount = primaryDevices.filter((dev) => dev.is_active_output || dev.is_active_input).length;

  if (audioDeviceInfo) {
    const shownText = showAllAudioDevices || extraCount === 0
      ? `${visibleDevices.length} angezeigt`
      : `kompakt: ${activeDevicesCount} aktive Geraete sichtbar, ${extraCount} weitere ausblendbar`;
    audioDeviceInfo.textContent = `Ausgabe: ${activeOutput || 'Unbekannt'} | Mikrofon: ${activeInput || 'Unbekannt'} | ${cachedAudioDevices.length} eindeutige Geraete (${outputCount} Output, ${inputCount} Input) | ${shownText}${routingMessage ? ` | ${routingMessage}` : ''}`;
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
      <div class="audio-device-item${dev.is_active_output || dev.is_active_input ? ' active' : ''}">
        <span>${dev.name} <small class="muted">${dev.kind === 'input' ? 'Mikrofon' : 'Ausgabe'}</small></span>
        <div class="row">
          ${dev.kind === 'input' ? '<span class="muted">Nur Anzeige</span>' : dev.is_active_output ? '<strong>Standard Ausgabe</strong>' : `<button class="btn" data-switch-device="${dev.id}" data-switch-name="${dev.name}">Als Standard</button>`}
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
      renderAudioDevicesList(activeOutput, activeInput, routingMessage);
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
      } else if ((dev.is_active_output && !dedup[idx].is_active_output) || (dev.is_active_input && !dedup[idx].is_active_input)) {
        dedup[idx] = dev;
      }
    }
    dedup.sort((a, b) => (
      (a.kind === 'output' ? 0 : 1) - (b.kind === 'output' ? 0 : 1)
      || Number(Boolean(b.is_active_output || b.is_active_input)) - Number(Boolean(a.is_active_output || a.is_active_input))
      || a.name.localeCompare(b.name, 'de')
    ));
    cachedAudioDevices = dedup;
    refreshUserProgramDeviceSelect();
    renderUserProgramRoutes();
    renderAudioDevicesList(d.active_output || '', d.active_input || '', d.routing_message || '');
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

function syncThemeInputs(vars) {
  const accEl = document.getElementById('customAccent');
  const gfEl = document.getElementById('customGradFrom');
  const bgEl = document.getElementById('customBg');
  if (accEl) accEl.value = vars['--accent'] || '#4aa3ff';
  if (gfEl) gfEl.value = vars['--grad-from'] || '#14315a';
  if (bgEl) bgEl.value = vars['--bg'] || '#071220';
}

function setActiveThemeButton(themeId) {
  pendingThemeId = themeId || 'custom';
  document.querySelectorAll('.theme-preset-btn').forEach((btn) => {
    btn.classList.toggle('active', btn.dataset.theme === themeId);
  });
}

function loadAndApplyTheme() {
  try {
    const raw = localStorage.getItem(THEME_KEY);
    if (!raw) {
      const fallback = THEMES.find((t) => t.id === 'ozean');
      if (fallback) {
        syncThemeInputs(fallback.vars);
        setActiveThemeButton(fallback.id);
      }
      return;
    }
    const data = JSON.parse(raw);
    if (data && data.vars) {
      applyTheme(data.vars);
      syncThemeInputs(data.vars);
      setActiveThemeButton(data.id === 'custom' ? null : data.id);
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
      syncThemeInputs(theme.vars);
      setActiveThemeButton(theme.id);
    });
    presetContainer.appendChild(btn);
  });

  ['customAccent', 'customGradFrom', 'customBg'].forEach((id) => {
    const input = document.getElementById(id);
    if (!input) return;
    input.addEventListener('input', () => {
      setActiveThemeButton(null);
    });
  });

  document.getElementById('applyCustomThemeBtn').addEventListener('click', () => {
    const selectedPreset = THEMES.find((theme) => theme.id === pendingThemeId) || null;
    if (selectedPreset) {
      applyTheme(selectedPreset.vars);
      syncThemeInputs(selectedPreset.vars);
      saveTheme(selectedPreset.id, selectedPreset.vars);
      setActiveThemeButton(selectedPreset.id);
      return;
    }

    const acc  = document.getElementById('customAccent').value;
    const gf   = document.getElementById('customGradFrom').value;
    const bg   = document.getElementById('customBg').value;
    const vars = buildCustomVars(acc, gf, bg);
    applyTheme(vars);
    saveTheme('custom', vars);
    setActiveThemeButton(null);
  });

  document.getElementById('resetThemeBtn').addEventListener('click', () => {
    localStorage.removeItem(THEME_KEY);
    const t = THEMES.find((t) => t.id === 'ozean');
    applyTheme(t.vars);
    syncThemeInputs(t.vars);
    setActiveThemeButton('ozean');
  });

  loadAndApplyTheme();
}

async function init() {
  decoratePageMenuIcons();
  decorateCardIcons();
  document.getElementById('gitStatusBtn').onclick = refreshGit;
  document.getElementById('gitPullBtn').onclick = pullGit;
  document.getElementById('reloadLogBtn').onclick = () => openLog(logSelect.value);
  if (reloadDependenciesBtn) reloadDependenciesBtn.onclick = loadDependencyStatus;
  if (reloadDashboardDependenciesBtn) reloadDashboardDependenciesBtn.onclick = loadDashboardDependencyStatus;
  if (reloadLaunchersBtn) reloadLaunchersBtn.onclick = loadLaunchers;
  if (launcherKind) launcherKind.onchange = syncLauncherForm;
  if (saveLauncherBtn) saveLauncherBtn.onclick = saveLauncher;
  if (resetLauncherFormBtn) resetLauncherFormBtn.onclick = resetLauncherForm;
  document.getElementById('restartBtn').onclick = restartGui;
  document.getElementById('saveLayoutBtn').onclick = () => {
    const pageConfig = getPageLayoutConfig();
    if (!pageConfig?.layoutEl) return;
    saveLayout(pageConfig.layoutEl, pageConfig.storageKey, true, layoutMsg);
  };
  document.getElementById('resetLayoutBtn').onclick = () => {
    const pageConfig = getPageLayoutConfig();
    if (!pageConfig) return;
    resetLayout(pageConfig.storageKey);
  };
  logSelect.onchange = () => openLog(logSelect.value);

  wireSizeControls(dashboardGrid, LAYOUT_KEY, layoutMsg);
  wireSizeControls(audioGrid, AUDIO_LAYOUT_KEY);
  wireSizeControls(logsGrid, LOGS_LAYOUT_KEY);
  wireSizeControls(toolsGrid, TOOLS_LAYOUT_KEY);
  wireSizeControls(setupGrid, SETUP_LAYOUT_KEY);

  applyLayout(readLayout(LAYOUT_KEY), dashboardGrid);
  applyLayout(readLayout(AUDIO_LAYOUT_KEY), audioGrid);
  applyLayout(readLayout(LOGS_LAYOUT_KEY), logsGrid);
  applyLayout(readLayout(TOOLS_LAYOUT_KEY), toolsGrid);
  applyLayout(readLayout(SETUP_LAYOUT_KEY), setupGrid);

  wirePageMenu();
  wireDragDrop(dashboardGrid, LAYOUT_KEY, renderWidgetMenu);
  wireDragDrop(audioGrid, AUDIO_LAYOUT_KEY);
  wireDragDrop(logsGrid, LOGS_LAYOUT_KEY, renderWidgetMenu);
  wireDragDrop(toolsGrid, TOOLS_LAYOUT_KEY, renderWidgetMenu);
  wireDragDrop(setupGrid, SETUP_LAYOUT_KEY, renderWidgetMenu);
  window.addEventListener('resize', () => {
    document.querySelectorAll('.layout').forEach((layoutEl) => scheduleMasonryLayout(layoutEl));
  });
  wireAudioControls();
  wireUserAudioRoutingControls();
  wireThemeControls();
  resetLauncherForm();

  try {
    await loadSystem();
  } catch {
    sysInfo.textContent = 'Systeminfo nicht verfuegbar';
  }

  await Promise.all([refreshAll(), refreshGit(), loadLogs(), loadDependencyStatus(), loadDashboardDependencyStatus(), loadTools(), loadLaunchers()]);
  document.querySelectorAll('.layout').forEach((layoutEl) => scheduleMasonryLayout(layoutEl));
  setInterval(refreshAll, 5000);
  setInterval(refreshGit, 20000);
}

init();

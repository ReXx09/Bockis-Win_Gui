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
const cpuTempValue = document.getElementById('cpuTempValue');
const cpuTempStatus = document.getElementById('cpuTempStatus');
const cpuTempBar = document.getElementById('cpuTempBar');
const cpuTempChart = document.getElementById('cpuTempChart');
const gpuTempValue = document.getElementById('gpuTempValue');
const gpuTempStatus = document.getElementById('gpuTempStatus');
const gpuTempBar = document.getElementById('gpuTempBar');
const gpuTempChart = document.getElementById('gpuTempChart');
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
const logHtmlFrame = document.getElementById('logHtmlFrame');
const logJsonView = document.getElementById('logJsonView');
const reloadDependenciesBtn = document.getElementById('reloadDependenciesBtn');
const dependencySummary = document.getElementById('dependencySummary');
const dependencyList = document.getElementById('dependencyList');
const dependencyMsg = document.getElementById('dependencyMsg');
const reloadDashboardDependenciesBtn = document.getElementById('reloadDashboardDependenciesBtn');
const dashboardDependencySummary = document.getElementById('dashboardDependencySummary');
const dashboardDependencyList = document.getElementById('dashboardDependencyList');
const dashboardDependencyMsg = document.getElementById('dashboardDependencyMsg');
const toolSysList = document.getElementById('toolSysList');
const toolNetList = document.getElementById('toolNetList');
const toolDiagList = document.getElementById('toolDiagList');
const toolDiskList = document.getElementById('toolDiskList');
const toolPrivList = document.getElementById('toolPrivList');
const toolDevList = document.getElementById('toolDevList');
const toolMsg = document.getElementById('toolMsg');
const reloadLaunchersBtn = document.getElementById('reloadLaunchersBtn');
const toggleLauncherEditModeBtn = document.getElementById('toggleLauncherEditModeBtn');
const openLauncherSetupBtn = document.getElementById('openLauncherSetupBtn');
const launcherCategoryBar = document.getElementById('launcherCategoryBar');
const launcherSetupCategoryBar = document.getElementById('launcherSetupCategoryBar');
const launcherList = document.getElementById('launcherList');
const launcherSetupList = document.getElementById('launcherSetupList');
const launcherMsg = document.getElementById('launcherMsg');
const launcherName = document.getElementById('launcherName');
const launcherKind = document.getElementById('launcherKind');
const launcherCategory = document.getElementById('launcherCategory');
const launcherCategoryHints = document.getElementById('launcherCategoryHints');
const launcherToolId = document.getElementById('launcherToolId');
const launcherTarget = document.getElementById('launcherTarget');
const launcherArgs = document.getElementById('launcherArgs');
const launcherNote = document.getElementById('launcherNote');
const launcherIcon = document.getElementById('launcherIcon');
const launcherTileBg = document.getElementById('launcherTileBg');
const launcherTileText = document.getElementById('launcherTileText');
const launcherTileBorder = document.getElementById('launcherTileBorder');
const launcherTileAccent = document.getElementById('launcherTileAccent');
const launcherPresetName = document.getElementById('launcherPresetName');
const saveLauncherPresetBtn = document.getElementById('saveLauncherPresetBtn');
const resetLauncherColorsBtn = document.getElementById('resetLauncherColorsBtn');
const launcherPresetList = document.getElementById('launcherPresetList');
const glassStrengthInput = document.getElementById('glassStrength');
const glassStrengthValue = document.getElementById('glassStrengthValue');
const launcherIconPicker = document.getElementById('launcherIconPicker');
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
const audioEditModeBtn = document.getElementById('audioEditModeBtn');
const userProgramRoutes = document.getElementById('userProgramRoutes');
const userRoutingHint = document.getElementById('userRoutingHint');
const routeDebugLog = document.getElementById('routeDebugLog');
const clearRouteDebugBtn = document.getElementById('clearRouteDebugBtn');
const routeFallbackBtn = document.getElementById('routeFallbackBtn');
const syncRoutesBtn = document.getElementById('syncRoutesBtn');
const clearAllRoutesBtn = document.getElementById('clearAllRoutesBtn');

const dashboardGrid = document.getElementById('dashboardGrid');
const audioGrid = document.getElementById('audioGrid');
const logsGrid = document.getElementById('logsGrid');
const quickstartGrid = document.getElementById('quickstartGrid');
const toolsGrid = document.getElementById('toolsGrid');
const setupGrid = document.getElementById('setupGrid');
const widgetMenu = document.getElementById('widgetMenu');
const widgetMenuTitle = document.getElementById('widgetMenuTitle');
const layoutMsg = document.getElementById('layoutMsg');

const LAYOUT_KEY = 'bockis_dashboard_layout_v4';
const AUDIO_LAYOUT_KEY = 'bockis_audio_layout_v1';
const LOGS_LAYOUT_KEY = 'bockis_logs_layout_v2';
const QUICKSTART_LAYOUT_KEY = 'bockis_quickstart_layout_v4';
const TOOLS_LAYOUT_KEY = 'bockis_tools_layout_v2';
const SETUP_LAYOUT_KEY = 'bockis_setup_layout_v4';
const PAGE_KEY = 'bockis_dashboard_page_v1';
const DEPENDENCY_TOP5_KEY = 'bockis_dependency_top5_v1';
const LEGACY_STORAGE_KEYS = {
  [LAYOUT_KEY]: ['bockis_dashboard_layout_v3', 'bockis_dashboard_layout_v2', 'bockis_dashboard_layout_v1'],
  [AUDIO_LAYOUT_KEY]: [],
  [LOGS_LAYOUT_KEY]: ['bockis_logs_layout_v1'],
  [QUICKSTART_LAYOUT_KEY]: ['bockis_quickstart_layout_v3', 'bockis_quickstart_layout_v2', 'bockis_quickstart_layout_v1'],
  [TOOLS_LAYOUT_KEY]: ['bockis_tools_layout_v1'],
  [SETUP_LAYOUT_KEY]: ['bockis_setup_layout_v3', 'bockis_setup_layout_v2', 'bockis_setup_layout_v1'],
};
const PAGE_ICONS = {
  overview: 'grid',
  audio: 'speaker',
  quickstart: 'globe',
  logs: 'file',
  tools: 'wrench',
  setup: 'sliders',
};
const WIDGET_LABELS = {
  monitoring: 'Monitoring',
  'cpu-temp': 'CPU Temperatur',
  'gpu-temp': 'GPU Temperatur',
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
  'quickstart-main': 'Schnellstart',
  'setup-launcher-dashboard': 'Launcher-Uebersicht',
  'setup-launchers': 'Launcher-Konfiguration',
  'tools-sys': 'Tools - System',
  'tools-net': 'Tools - Netzwerk',
  'tools-diag': 'Tools - Diagnose',
  'tools-disk': 'Tools - Datentraeger',
  'tools-priv': 'Tools - Sicherheit',
  'tools-dev': 'Tools - Entwickler',
  'tools-console': 'Tools - Ausgabe',
  'setup-theme': 'Erscheinungsbild',
  'setup-git': 'Git / Setup',
};
const WIDGET_ICONS = {
  monitoring: 'activity',
  'cpu-temp': 'thermometer',
  'gpu-temp': 'thermometer',
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
  'quickstart-main': 'globe',
  'setup-launcher-dashboard': 'globe',
  'setup-launchers': 'sliders',
  'tools-sys': 'wrench',
  'tools-net': 'wrench',
  'tools-diag': 'wrench',
  'tools-disk': 'wrench',
  'tools-priv': 'wrench',
  'tools-dev': 'wrench',
  'tools-console': 'wrench',
  'setup-theme': 'palette',
  'setup-git': 'git-branch',
};
const PAGE_LAYOUTS = {
  overview: { label: 'Uebersicht', layoutEl: dashboardGrid, storageKey: LAYOUT_KEY },
  audio: { label: 'Audio', layoutEl: audioGrid, storageKey: AUDIO_LAYOUT_KEY },
  logs: { label: 'Logs', layoutEl: logsGrid, storageKey: LOGS_LAYOUT_KEY },
  quickstart: { label: 'Schnellstart', layoutEl: quickstartGrid, storageKey: QUICKSTART_LAYOUT_KEY },
  tools: { label: 'Tools', layoutEl: toolsGrid, storageKey: TOOLS_LAYOUT_KEY },
  setup: { label: 'Setup', layoutEl: setupGrid, storageKey: SETUP_LAYOUT_KEY },
};
const PAGE_ROUTES = {
  overview: '/uebersicht',
  audio: '/audio',
  quickstart: '/schnellstart',
  logs: '/logs',
  tools: '/tools',
  setup: '/setup',
};
const ROUTE_PAGE_MAP = {
  '/': 'quickstart',
  '/overview': 'overview',
  '/uebersicht': 'overview',
  '/übersicht': 'overview',
  '/audio': 'audio',
  '/schnellstart': 'quickstart',
  '/logs': 'logs',
  '/tools': 'tools',
  '/setup': 'setup',
};
const SIZE_PRESETS = ['1-8', '1-4', '1-3', '1-2', '2-3', 'full', 'min'];
const SIZE_RATIOS = {
  '1-8': 1 / 8,
  '1-4': 1 / 4,
  '1-3': 1 / 3,
  '1-2': 1 / 2,
  '2-3': 2 / 3,
  full: 1,
  min: 1 / 3,
};
const THEME_KEY = 'bockis_theme_v1';
const GLASS_STRENGTH_KEY = 'bockis_glass_strength_v1';
const AUDIO_USER_ROUTES_KEY = 'bockis_audio_user_routes_v1';
const AUDIO_HIDDEN_DEVICES_KEY = 'bockis_audio_hidden_devices_v1';
const AUDIO_EDIT_MODE_KEY = 'bockis_audio_edit_mode_v1';
const LAUNCHERS_FALLBACK_KEY = 'bockis_custom_launchers_v1';
const LAUNCHER_STYLE_PRESETS_KEY = 'bockis_launcher_style_presets_v1';
const LAUNCHER_CATEGORY_LAYOUTS_KEY = 'bockis_launcher_category_layouts_v1';
const LAUNCHER_CATEGORY_DENSITY_KEY = 'bockis_launcher_category_density_v1';
const LAUNCHER_CATEGORY_ORDER_KEY = 'bockis_launcher_category_order_v1';
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
const LAUNCHER_ICON_OPTIONS = [
  { id: 'grid', label: 'Kachel' },
  { id: 'globe', label: 'Web' },
  { id: 'server', label: 'Server' },
  { id: 'cloud', label: 'Cloud' },
  { id: 'folder', label: 'Ordner' },
  { id: 'home', label: 'Home' },
  { id: 'terminal', label: 'Konsole' },
  { id: 'shield', label: 'Sicherheit' },
  { id: 'wrench', label: 'Tool' },
  { id: 'route', label: 'Netzwerk' },
  { id: 'drive', label: 'Storage' },
  { id: 'activity', label: 'Monitoring' },
  { id: 'cpu', label: 'System' },
  { id: 'speaker', label: 'Audio' },
  { id: 'file', label: 'Dokument' },
];

const DASHBOARD_COLUMNS_KEY = 'bockis_dashboard_columns_v1';
const DEFAULT_DASHBOARD_COLUMNS = {
  overview: 3,
  audio: 2,
  quickstart: 3,
  logs: 3,
  tools: 4,
  setup: 3,
};

let draggedCard = null;
let cachedAudioDevices = [];
let lastAudioSessions = [];
let cachedOpenPrograms = [];
let lastOpenProgramsFetch = 0;
let showAllAudioDevices = false;
let hiddenAudioDeviceIds = new Set();
let audioSwitchInFlight = false;
let audioEditMode = false;
let lastAudioDeviceSummary = { activeOutput: '', activeInput: '', routingMessage: '' };
let routeMuteInFlight = new Set();
let routeSessionRefreshTimer = null;
let routeDebugEvents = [];
let persistedRouteByPid = new Map();
let persistedReadbackApiAvailable = true;
let lastInputMeteringData = { level: 0, peak: 0, available: false };
let inputMeteringTimer = null;
let pendingThemeId = 'ozean';
let availableTools = [];
let customLaunchers = [];
let editingLauncherId = '';
let launcherApiAvailable = true;
let selectedLauncherCategory = 'Alle';
let launcherEditMode = false;
let launcherStylePresets = [];
let launcherCategoryLayouts = {};
let launcherCategoryDensity = {};
let launcherCategoryOrder = [];
let dragArmedCard = null;
let toolStateTimer = null;
let metricsRefreshTimer = null;
let audioRefreshTimer = null;
let gitRefreshTimer = null;
let gitUpdateCheckTimer = null;
let toolStateApiAvailable = true;
let toolToggleApiAvailable = true;
let toolStateRefreshInFlight = false;
const REFRESH_INTERVALS = {
  overviewMetricsMs: 4000,
  audioMs: 7000,
  toolsStateMs: 5000,
  gitMs: 30000,
};
const masonryFrames = new Map();
let layoutResizeObserver = null;
let layoutResizeDebounce = null;
const HISTORY_LEN = 45;
const monitorHistory = {
  cpu: [],
  gpu: [],
  ram: [],
  cpuTemp: [],
  gpuTemp: [],
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
  const cpuTempMax = Math.max(100, ...monitorHistory.cpuTemp);
  drawSparkline(cpuTempChart, monitorHistory.cpuTemp, cpuTempMax, '#f97316', 'rgba(249,115,22,0.16)');
  const gpuTempMax = Math.max(100, ...monitorHistory.gpuTemp);
  drawSparkline(gpuTempChart, monitorHistory.gpuTemp, gpuTempMax, '#ef4444', 'rgba(239,68,68,0.16)');
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

function scheduleAllLayoutsMasonry() {
  document.querySelectorAll('.layout').forEach((layoutEl) => scheduleMasonryLayout(layoutEl));
}

function installLayoutResizeObserver() {
  if (typeof ResizeObserver === 'undefined') return;

  if (layoutResizeObserver) {
    try { layoutResizeObserver.disconnect(); } catch {}
  }

  layoutResizeObserver = new ResizeObserver((entries) => {
    for (const entry of entries) {
      const el = entry.target;
      if (el && el.classList && el.classList.contains('layout')) {
        applyResponsiveTileSpans(el);
        scheduleMasonryLayout(el);
      }
    }
  });

  document.querySelectorAll('.layout').forEach((layoutEl) => {
    try { layoutResizeObserver.observe(layoutEl); } catch {}
  });
}

function queueLayoutReflow() {
  if (layoutResizeDebounce) {
    clearTimeout(layoutResizeDebounce);
  }

  layoutResizeDebounce = setTimeout(() => {
    layoutResizeDebounce = null;
    document.querySelectorAll('.layout').forEach((layoutEl) => {
      applyResponsiveTileSpans(layoutEl);
      scheduleMasonryLayout(layoutEl);
    });
  }, 120);
}

function getCards(layoutEl = dashboardGrid) {
  if (!layoutEl) return [];
  return Array.from(layoutEl.querySelectorAll('.card[data-widget]'));
}

function getLayoutColumnCount(layoutEl = dashboardGrid) {
  if (!layoutEl) return 24;

  const style = getComputedStyle(layoutEl);
  const raw = style.getPropertyValue('--layout-columns').trim();
  const parsed = Number.parseInt(raw, 10);
  if (Number.isFinite(parsed) && parsed > 0) return parsed;

  return 24;
}

function getResponsiveSpan(size, columns) {
  const safeColumns = Math.max(1, Number.parseInt(columns, 10) || 1);
  const key = SIZE_PRESETS.includes(size) ? size : '1-3';

  if (key === 'full') return safeColumns;

  if (key === 'min') {
    // Keep compact cards useful on small grids: below 8 columns, show two compact cards per row.
    const minSpan = safeColumns >= 8 ? Math.round(safeColumns / 3) : Math.max(1, Math.round(safeColumns / 2));
    return Math.min(safeColumns, Math.max(1, minSpan));
  }

  const ratio = SIZE_RATIOS[key] || (1 / 3);
  const span = Math.round(safeColumns * ratio);
  return Math.min(safeColumns, Math.max(1, span));
}

function applyResponsiveCardSpan(card, layoutEl = dashboardGrid, size = null) {
  if (!card) return;

  const target = SIZE_PRESETS.includes(size) ? size : (card.dataset.size || card.dataset.defaultSize || '1-3');
  const columns = getLayoutColumnCount(layoutEl);
  const span = getResponsiveSpan(target, columns);
  card.style.gridColumn = `span ${span}`;
}

function applyResponsiveTileSpans(layoutEl = dashboardGrid) {
  getCards(layoutEl).forEach((card) => {
    applyResponsiveCardSpan(card, layoutEl);
  });
}

function getCurrentPage() {
  return document.querySelector('.page.active')?.dataset.page || (localStorage.getItem(PAGE_KEY) || 'quickstart');
}

function getRouteForPage(page) {
  return PAGE_ROUTES[page] || PAGE_ROUTES.overview;
}

function getPageFromLocation() {
  try {
    const pageParam = new URLSearchParams(window.location.search || '').get('page');
    if (pageParam && PAGE_LAYOUTS[pageParam]) {
      return pageParam;
    }

    let path = decodeURIComponent(window.location.pathname || '/').trim();
    if (!path.startsWith('/')) path = `/${path}`;
    path = path.replace(/\/+$|\s+$/g, '');
    if (!path) path = '/';

    const normalized = path.toLowerCase();
    if (Object.prototype.hasOwnProperty.call(ROUTE_PAGE_MAP, normalized)) {
      return ROUTE_PAGE_MAP[normalized];
    }

    const parts = normalized.split('/').filter(Boolean);
    if (parts.length > 0) {
      const firstSegment = `/${parts[0]}`;
      if (Object.prototype.hasOwnProperty.call(ROUTE_PAGE_MAP, firstSegment)) {
        return ROUTE_PAGE_MAP[firstSegment];
      }
    }

    return null;
  } catch {
    return null;
  }
}

function updateBrowserLocation(page, replace = false) {
  const targetPath = getRouteForPage(page);
  if (!targetPath) return;
  const currentPath = window.location.pathname || '/';
  if (currentPath.toLowerCase() === targetPath.toLowerCase()) return;

  const method = replace ? 'replaceState' : 'pushState';
  window.history[method]({ page }, '', targetPath);
}

function getIconMarkup(iconName) {
  if (!iconName) return '';
  return `<span class="icon-inline"><svg viewBox="0 0 24 24" aria-hidden="true" focusable="false"><use href="#icon-${iconName}"></use></svg></span>`;
}

function readDashboardColumns() {
  try {
    const raw = localStorage.getItem(DASHBOARD_COLUMNS_KEY);
    if (raw) return JSON.parse(raw);
  } catch {}
  return { ...DEFAULT_DASHBOARD_COLUMNS };
}

function saveDashboardColumns(columns) {
  try {
    localStorage.setItem(DASHBOARD_COLUMNS_KEY, JSON.stringify(columns));
  } catch {}
}

function applyDashboardColumns(page, columns) {
  const safeColumns = Math.max(2, Math.min(4, Number.parseInt(columns, 10) || 3));
  document.documentElement.style.setProperty('--layout-columns', Math.round(safeColumns * 6));
}

function getCurrentDashboardColumns(page = getCurrentPage()) {
  const cols = readDashboardColumns();
  return cols[page] || DEFAULT_DASHBOARD_COLUMNS[page] || 3;
}

function updateDashboardColumnButtons(page = null) {
  const cols = readDashboardColumns();
  const pages = page ? [page] : Object.keys(DEFAULT_DASHBOARD_COLUMNS);

  pages.forEach((page) => {
    const colNum = cols[page] || DEFAULT_DASHBOARD_COLUMNS[page];
    const buttons = document.querySelectorAll(`.page-column-btn[data-page="${page}"]`);
    buttons.forEach((btn) => {
      const btnCols = Number.parseInt(btn.dataset.cols, 10);
      btn.classList.toggle('active', btnCols === colNum);
    });
  });
}

function setDashboardColumns(page, columns) {
  if (!page) return;
  const safeColumns = Math.max(2, Math.min(4, Number.parseInt(columns, 10) || 3));
  const allCols = readDashboardColumns();
  allCols[page] = safeColumns;
  saveDashboardColumns(allCols);
  updateDashboardColumnButtons(page);

  if (getCurrentPage() !== page) return;

  applyDashboardColumns(page, safeColumns);
  document.querySelectorAll('.page.active .layout').forEach((layoutEl) => {
    applyResponsiveTileSpans(layoutEl);
    scheduleMasonryLayout(layoutEl);
  });
}

function wireDashboardColumnControls() {
  document.querySelectorAll('.page-column-btn').forEach((btn) => {
    btn.addEventListener('click', () => {
      setDashboardColumns(btn.dataset.page, btn.dataset.cols);
    });
  });

  updateDashboardColumnButtons();
}

function decoratePageMenuIcons() {
  const pageBadges = {
    audio: 'Beta',
    tools: 'Beta',
  };

  document.querySelectorAll('.menu-nav-btn').forEach((btn) => {
    if (btn.dataset.iconDecorated === '1') return;
    const page = btn.dataset.pageTarget || '';
    const label = btn.textContent.trim();
    const badge = pageBadges[page] ? `<span class="menu-nav-badge">${pageBadges[page]}</span>` : '';
    btn.innerHTML = `${getIconMarkup(PAGE_ICONS[page] || 'grid')}<span class="menu-nav-label">${label}</span>${badge}`;
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

function isWidgetVisibleOnPage(page, widgetId) {
  const pageConfig = getPageLayoutConfig(page);
  const layoutEl = pageConfig?.layoutEl || null;
  if (!layoutEl || !widgetId) return false;
  const card = getCards(layoutEl).find((entry) => entry.dataset.widget === widgetId);
  return !!card && card.style.display !== 'none';
}

function hasVisibleWidgetsOnPage(page, widgetIds = []) {
  return widgetIds.some((widgetId) => isWidgetVisibleOnPage(page, widgetId));
}

function clearScopedRefreshTimers() {
  if (metricsRefreshTimer) {
    clearInterval(metricsRefreshTimer);
    metricsRefreshTimer = null;
  }
  if (audioRefreshTimer) {
    clearInterval(audioRefreshTimer);
    audioRefreshTimer = null;
  }
  if (inputMeteringTimer) {
    clearInterval(inputMeteringTimer);
    inputMeteringTimer = null;
  }
  if (gitRefreshTimer) {
    clearInterval(gitRefreshTimer);
    gitRefreshTimer = null;
  }
  if (toolStateTimer) {
    clearInterval(toolStateTimer);
    toolStateTimer = null;
  }
}

function refreshActivePageOnce(page = getCurrentPage()) {
  if (page === 'overview' && hasVisibleWidgetsOnPage('overview', ['monitoring', 'net-upload', 'net-download', 'disks', 'processes'])) {
    loadMetrics().catch(() => setOnline(false));
    return;
  }
  if (page === 'audio' && hasVisibleWidgetsOnPage('audio', ['audio-volume', 'audio-devices', 'audio-sessions', 'audio-routing'])) {
    refreshAudio().catch(() => {});
    return;
  }
  if (page === 'tools' && toolStateApiAvailable && hasVisibleWidgetsOnPage('tools', ['tools-sys', 'tools-net', 'tools-diag', 'tools-disk', 'tools-priv', 'tools-dev'])) {
    refreshToolButtonStates().catch(() => {});
    return;
  }
  if (page === 'logs' && isWidgetVisibleOnPage('logs', 'setup-git')) {
    refreshGit().catch(() => {});
  }
}

function updateScopedRefreshTimers() {
  clearScopedRefreshTimers();

  const page = getCurrentPage();

  if (page === 'overview' && hasVisibleWidgetsOnPage('overview', ['monitoring', 'net-upload', 'net-download', 'disks', 'processes'])) {
    metricsRefreshTimer = setInterval(() => {
      if (getCurrentPage() !== 'overview') return;
      if (!hasVisibleWidgetsOnPage('overview', ['monitoring', 'net-upload', 'net-download', 'disks', 'processes'])) return;
      loadMetrics().catch(() => setOnline(false));
    }, REFRESH_INTERVALS.overviewMetricsMs);
  }

  if (page === 'audio' && hasVisibleWidgetsOnPage('audio', ['audio-volume', 'audio-devices', 'audio-sessions', 'audio-routing'])) {
    audioRefreshTimer = setInterval(() => {
      if (getCurrentPage() !== 'audio') return;
      if (!hasVisibleWidgetsOnPage('audio', ['audio-volume', 'audio-devices', 'audio-sessions', 'audio-routing'])) return;
      refreshAudio().catch(() => {});
    }, REFRESH_INTERVALS.audioMs);
  }

  if (page === 'tools' && toolStateApiAvailable && hasVisibleWidgetsOnPage('tools', ['tools-sys', 'tools-net', 'tools-diag', 'tools-disk', 'tools-priv', 'tools-dev'])) {
    toolStateTimer = setInterval(() => {
      if (getCurrentPage() !== 'tools') return;
      if (!hasVisibleWidgetsOnPage('tools', ['tools-sys', 'tools-net', 'tools-diag', 'tools-disk', 'tools-priv', 'tools-dev'])) return;
      refreshToolButtonStates();
    }, REFRESH_INTERVALS.toolsStateMs);
  }

  if (page === 'logs' && isWidgetVisibleOnPage('logs', 'setup-git')) {
    gitRefreshTimer = setInterval(() => {
      if (getCurrentPage() !== 'logs') return;
      if (!isWidgetVisibleOnPage('logs', 'setup-git')) return;
      refreshGit();
    }, REFRESH_INTERVALS.gitMs);
  }
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
  applyResponsiveCardSpan(card, layoutEl, target);

  const selectEl = card.querySelector('.size-select');
  if (selectEl && selectEl.value !== target) {
    selectEl.value = target;
  }

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

function saveDashboardState(messageEl = layoutMsg) {
  Object.values(PAGE_LAYOUTS).forEach((cfg) => {
    if (!cfg || !cfg.layoutEl || !cfg.storageKey) return;
    saveLayout(cfg.layoutEl, cfg.storageKey, false, null);
  });

  saveLauncherCategoryLayouts();
  saveLauncherCategoryDensity();
  saveLauncherCategoryOrder();
  saveDependencyTop5Preferences(dependencyPreferredTop5);

  if (messageEl) {
    messageEl.textContent = 'Dashboard gespeichert.';
    setTimeout(() => {
      if (messageEl.textContent === 'Dashboard gespeichert.') messageEl.textContent = '';
    }, 2200);
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

  applyResponsiveTileSpans(layoutEl);

  scheduleMasonryLayout(layoutEl);
}

function wireSizeControls(layoutEl = dashboardGrid, storageKey = LAYOUT_KEY, messageEl = null) {
  getCards(layoutEl).forEach((card) => {
    const head = card.querySelector('.card-head');
    if (!head || head.querySelector('.size-controls')) return;

    const actions = document.createElement('div');
    actions.className = 'card-head-actions';

    const controls = document.createElement('div');
    controls.className = 'size-controls';

    const specs = [
      { key: '1-8', label: '1/8' },
      { key: '1-4', label: '1/4' },
      { key: '1-3', label: '1/3' },
      { key: '1-2', label: '1/2' },
      { key: '2-3', label: '2/3' },
      { key: 'full', label: 'voll' },
      { key: 'min', label: 'min' },
    ];

    const select = document.createElement('select');
    select.className = 'size-select';
    select.title = 'Kachelgroesse';
    specs.forEach((spec) => {
      const option = document.createElement('option');
      option.value = spec.key;
      option.textContent = spec.label;
      select.appendChild(option);
    });
    select.addEventListener('change', (e) => {
      e.preventDefault();
      e.stopPropagation();
      setCardSize(card, select.value, true, layoutEl, storageKey, messageEl);
    });
    select.addEventListener('mousedown', (e) => e.stopPropagation());
    controls.appendChild(select);

    actions.appendChild(controls);
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
      updateScopedRefreshTimers();
    });
    widgetMenu.appendChild(item);
  });
}

function wireDragDrop(layoutEl = dashboardGrid, storageKey = LAYOUT_KEY, onAfterDrop = null) {
  getCards(layoutEl).forEach((card) => {
    const cardHead = card.querySelector('.card-head');

    const armDrag = (event) => {
      const target = event?.target;
      if (!target) return;
      if (target.closest('.size-controls')) return;
      if (target.closest('button, input, select, textarea, a')) return;
      dragArmedCard = card;
      card.draggable = true;
    };

    const disarmDrag = () => {
      if (dragArmedCard === card) dragArmedCard = null;
      if (!card.classList.contains('dragging')) card.draggable = false;
    };

    card.draggable = false;
    if (cardHead) {
      cardHead.addEventListener('mousedown', armDrag);
      cardHead.addEventListener('mouseup', disarmDrag);
      cardHead.addEventListener('mouseleave', disarmDrag);
    }

    card.addEventListener('dragstart', (e) => {
      if (dragArmedCard !== card) {
        e.preventDefault();
        card.draggable = false;
        return;
      }
      draggedCard = card;
      card.classList.add('dragging');
    });
    card.addEventListener('dragend', () => {
      card.classList.remove('dragging');
      getCards(layoutEl).forEach((c) => c.classList.remove('drag-over'));
      draggedCard = null;
      disarmDrag();
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

function showPage(page, options = {}) {
  const { updateUrl = false, replaceUrl = false } = options;
  const resolvedPage = PAGE_LAYOUTS[page] ? page : 'overview';

  document.querySelectorAll('.page').forEach((p) => {
    p.classList.toggle('active', p.dataset.page === resolvedPage);
  });
  document.querySelectorAll('.menu-nav-btn').forEach((b) => {
    b.classList.toggle('active', b.dataset.pageTarget === resolvedPage);
  });
  localStorage.setItem(PAGE_KEY, resolvedPage);
  if (updateUrl) updateBrowserLocation(resolvedPage, replaceUrl);
  renderWidgetMenu(resolvedPage);
  refreshActivePageOnce(resolvedPage);
  updateScopedRefreshTimers();

  const pageColumns = getCurrentDashboardColumns(resolvedPage);
  applyDashboardColumns(resolvedPage, pageColumns);

  document.querySelectorAll('.page.active .layout').forEach((layoutEl) => {
    applyResponsiveTileSpans(layoutEl);
    scheduleMasonryLayout(layoutEl);
  });
}

function wirePageMenu() {
  document.querySelectorAll('.menu-nav-btn').forEach((btn) => {
    btn.addEventListener('click', () => showPage(btn.dataset.pageTarget, { updateUrl: true }));
  });

  window.addEventListener('popstate', () => {
    const routedPage = getPageFromLocation() || 'quickstart';
    showPage(routedPage, { updateUrl: false });
  });

  const routedPage = getPageFromLocation();
  const hasExplicitPath = ((window.location.pathname || '/').trim() || '/') !== '/';
  const start = routedPage || (hasExplicitPath ? 'overview' : (localStorage.getItem(PAGE_KEY) || 'quickstart'));
  showPage(start, { updateUrl: hasExplicitPath && !routedPage, replaceUrl: hasExplicitPath });
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

    if (m.cpu_temp_c != null) {
      const temp = m.cpu_temp_c;
      cpuTempValue.textContent = `${temp} °C`;
      cpuTempValue.style.color = temp >= 85 ? '#ef4444' : temp >= 65 ? '#f97316' : '#41d88f';
      cpuTempStatus.textContent = temp >= 85 ? 'Kritisch' : temp >= 65 ? 'Warm' : 'OK';
      cpuTempBar.parentElement.style.display = '';
      cpuTempBar.style.width = `${Math.max(0, Math.min(100, temp))}%`;
      pushHistory('cpuTemp', temp);
    } else {
      cpuTempValue.textContent = 'n/a';
      cpuTempValue.style.color = 'var(--muted)';
      cpuTempStatus.textContent = 'Kein Sensor verfuegbar';
      cpuTempBar.parentElement.style.display = 'none';
      pushHistory('cpuTemp', 0);
    }

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

    if (mainGpu.temp_c != null) {
      const temp = mainGpu.temp_c;
      gpuTempValue.textContent = `${temp} °C`;
      gpuTempValue.style.color = temp >= 88 ? '#ef4444' : temp >= 72 ? '#f97316' : '#41d88f';
      gpuTempStatus.textContent = temp >= 88 ? 'Kritisch' : temp >= 72 ? 'Warm' : 'OK';
      gpuTempBar.parentElement.style.display = '';
      gpuTempBar.style.width = `${Math.max(0, Math.min(100, temp))}%`;
      pushHistory('gpuTemp', temp);
    } else {
      gpuTempValue.textContent = 'n/a';
      gpuTempValue.style.color = 'var(--muted)';
      gpuTempStatus.textContent = 'Kein Sensor verfuegbar';
      gpuTempBar.parentElement.style.display = 'none';
      pushHistory('gpuTemp', 0);
    }
  } else {
    gpuName.textContent = 'GPU';
    gpuPct.textContent = 'n/a';
    gpuMeta.textContent = 'Keine GPU-Daten';
    gpuBar.style.width = '0%';
    pushHistory('gpu', 0);

    gpuTempValue.textContent = 'n/a';
    gpuTempValue.style.color = 'var(--muted)';
    gpuTempStatus.textContent = 'Keine GPU-Daten';
    gpuTempBar.parentElement.style.display = 'none';
    pushHistory('gpuTemp', 0);
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

async function checkGitUpdates() {
  try {
    const d = await jsonFetch('/api/git/check-updates');
    const banner = document.getElementById('gitUpdateBanner');
    const logsBtn = document.querySelector('.menu-nav-btn[data-page-target="logs"]');
    if (!d.available || d.behind === 0) {
      if (banner) banner.style.display = 'none';
      if (logsBtn) logsBtn.classList.remove('git-update-dot');
      return;
    }
    // Neue Commits vorhanden
    const commitLines = d.latest_commits
      ? `\n\nNeuste Commits:\n${d.latest_commits}`
      : '';
    const msg = `\u26A0\uFE0F  ${d.behind} neue Commit(s) verfuegbar auf ${d.upstream}.${commitLines}\n\nDruecke Pull um zu aktualisieren.`;
    if (banner) {
      banner.textContent = msg;
      banner.style.display = 'block';
    }
    if (logsBtn) logsBtn.classList.add('git-update-dot');
  } catch {
    // Netzwerkfehler still ignorieren – naechster Check in 5 Minuten
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
    // Update-Banner und Nav-Dot leeren da jetzt auf aktuellem Stand
    const banner = document.getElementById('gitUpdateBanner');
    if (banner) banner.style.display = 'none';
    const logsBtn = document.querySelector('.menu-nav-btn[data-page-target="logs"]');
    if (logsBtn) logsBtn.classList.remove('git-update-dot');
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
    else {
      if (logJsonView) {
        logJsonView.style.display = 'none';
        logJsonView.innerHTML = '';
      }
      if (logHtmlFrame) logHtmlFrame.style.display = 'none';
      logContent.style.display = 'block';
      logContent.textContent = 'Keine Logs gefunden.';
    }
  } catch (err) {
    if (logJsonView) {
      logJsonView.style.display = 'none';
      logJsonView.innerHTML = '';
    }
    if (logHtmlFrame) logHtmlFrame.style.display = 'none';
    logContent.style.display = 'block';
    logContent.textContent = `Log-Liste Fehler: ${err.message}`;
  }
}

function escapeHtml(value) {
  return String(value ?? '')
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}

function formatContext(ctx) {
  if (!ctx || typeof ctx !== 'object') return '';
  return Object.entries(ctx)
    .filter(([, v]) => {
      const s = String(v ?? '').trim().toLowerCase();
      return s !== '' && s !== '-' && s !== 'none';
    })
    .map(([k, v]) => `${k}=${v}`)
    .join(' | ');
}

function toLevelClass(level) {
  const l = String(level || '').toLowerCase();
  if (l === 'error' || l === 'critical') return 'is-error';
  if (l === 'warning') return 'is-warn';
  if (l === 'success') return 'is-ok';
  return 'is-info';
}

function renderJsonLog(entries) {
  if (!logJsonView) return;
  const items = Array.isArray(entries) ? entries : [];
  if (items.length === 0) {
    logJsonView.innerHTML = '<div class="log-json-empty">Keine JSON-Eintraege gefunden.</div>';
    return;
  }

  const html = items.map((entry) => {
    const type = String(entry?.Type || 'entry').toLowerCase();
    const message = escapeHtml(entry?.Message || '-');
    const ts = escapeHtml(entry?.Timestamp || '-');
    const level = escapeHtml(entry?.LevelPrefix || entry?.Level || 'INFO');
    const levelClass = toLevelClass(entry?.Level);
    const tag = escapeHtml(entry?.TagDisplay || `[${entry?.Tag || 'LOG'}]`);
    const ctx = escapeHtml(formatContext(entry?.Context));

    if (type === 'run-start' || type === 'run-end') {
      const runClass = type === 'run-end' ? ' end' : '';
      return `<div class="log-json-run${runClass}">${message}</div>`;
    }

    const ctxBlock = ctx ? `<div class="log-json-ctx">${ctx}</div>` : '';
    return `<div class="log-json-entry">
      <div class="log-json-ts">${ts}</div>
      <div class="log-json-level ${levelClass}">${level}</div>
      <div class="log-json-tag">${tag}</div>
      <div class="log-json-msg">${message}${ctxBlock}</div>
    </div>`;
  }).join('');

  logJsonView.innerHTML = html;
}

async function openLog(name) {
  if (!name) return;

  const isJson = String(name).toLowerCase().endsWith('.log.json');
  if (isJson) {
    if (logHtmlFrame) {
      logHtmlFrame.style.display = 'none';
      logHtmlFrame.removeAttribute('src');
    }
    logContent.style.display = 'none';
    if (logJsonView) logJsonView.style.display = 'block';

    try {
      const d = await jsonFetch(`/api/logs/json?file=${encodeURIComponent(name)}&lines=400`);
      renderJsonLog(d.entries || []);
    } catch (err) {
      if (logJsonView) {
        logJsonView.innerHTML = `<div class="log-json-empty">JSON-Log Laden fehlgeschlagen: ${escapeHtml(err.message)}</div>`;
      }
    }

    scheduleMasonryLayout(logsGrid);
    return;
  }

  const isHtml = String(name).toLowerCase().endsWith('.html');
  if (isHtml) {
    if (logJsonView) {
      logJsonView.style.display = 'none';
      logJsonView.innerHTML = '';
    }
    logContent.style.display = 'none';
    if (logHtmlFrame) {
      logHtmlFrame.style.display = 'block';
      logHtmlFrame.src = `/api/logs/raw?file=${encodeURIComponent(name)}&t=${Date.now()}`;
    }
    scheduleMasonryLayout(logsGrid);
    return;
  }

  try {
    if (logJsonView) {
      logJsonView.style.display = 'none';
      logJsonView.innerHTML = '';
    }
    if (logHtmlFrame) {
      logHtmlFrame.style.display = 'none';
      logHtmlFrame.removeAttribute('src');
    }
    logContent.style.display = 'block';
    const d = await jsonFetch(`/api/logs/content?file=${encodeURIComponent(name)}&lines=250`);
    logContent.textContent = d.content || '(leer)';
    scheduleMasonryLayout(logsGrid);
  } catch (err) {
    if (logHtmlFrame) logHtmlFrame.style.display = 'none';
    logContent.style.display = 'block';
    logContent.textContent = `Log-Laden fehlgeschlagen: ${err.message}`;
    scheduleMasonryLayout(logsGrid);
  }
}

function getDependencyAction(dep) {
  if (!dep) return null;
  const hasWinget = !!dep.WingetId;
  const isPsModule = String(dep.InstallerType || '').toLowerCase() === 'powershell-module'
    || String(dep.Name || '').toLowerCase().includes('pswindowsupdate');

  if (!hasWinget && !isPsModule) return null;
  if (!dep.Found && dep.Available) return 'install';
  if (dep.UpdateAvailable) return 'upgrade';
  return null;
}

let dependencyExpanded = false;
let dependencySelectionMode = false;
let dependencyPreferredTop5 = [];

function loadDependencyTop5Preferences() {
  try {
    const raw = localStorage.getItem(DEPENDENCY_TOP5_KEY);
    if (!raw) return [];
    const parsed = JSON.parse(raw);
    if (!Array.isArray(parsed)) return [];
    return parsed.filter((x) => typeof x === 'string' && x.trim()).slice(0, 5);
  } catch {
    return [];
  }
}

function saveDependencyTop5Preferences(names) {
  dependencyPreferredTop5 = Array.from(new Set((names || []).filter((x) => typeof x === 'string' && x.trim()))).slice(0, 5);
  try {
    localStorage.setItem(DEPENDENCY_TOP5_KEY, JSON.stringify(dependencyPreferredTop5));
  } catch {
    // ignore localStorage issues, fallback to session memory
  }
}

function getTop5BaseDependencies(deps) {
  const preferredOrder = dependencyPreferredTop5
    .map((name) => deps.find((dep) => dep && dep.Name === name))
    .filter(Boolean);

  const fallbackOrder = deps.filter((dep) => !preferredOrder.some((picked) => picked.Name === dep.Name));
  return [...preferredOrder, ...fallbackOrder].slice(0, 5);
}

function buildDependencyRows(deps, options = {}) {
  const selectionMode = !!options.selectionMode;
  const selectedSet = new Set(dependencyPreferredTop5);

  return deps.map((dep) => {
    const action = selectionMode ? null : getDependencyAction(dep);
    const versionText = dep.Version || dep.AvailableVersion || '-';
    const nextVersion = dep.UpdateAvailable && dep.AvailableVersion ? ` → ${dep.AvailableVersion}` : '';
    const installerType = dep.InstallerType || (dep.WingetId ? 'winget' : '');
    const moduleName = dep.ModuleName || '';
    const depName = dep.Name || 'Unbekannt';
    const isTop5Selected = selectedSet.has(depName);

    const actionCell = selectionMode
      ? `<button class="btn dependency-select-btn ${isTop5Selected ? 'is-selected' : ''}" data-dependency-top5-toggle="${depName}">${isTop5Selected ? 'Top 5 ✓' : 'Zu Top 5'}</button>`
      : (action
        ? `<button class="btn" data-dependency-action="${action}" data-winget-id="${dep.WingetId || ''}" data-dependency-name="${depName}" data-installer-type="${installerType}" data-module-name="${moduleName}">${action === 'upgrade' ? 'Update' : 'Installieren'}</button>`
        : '');

    return `
      <div class="dependency-table-row dependency-table-row-actions dependency-${String(dep.StatusColor || '').toLowerCase()} ${isTop5Selected ? 'dependency-top5-selected' : ''}">
        <div class="dependency-col-name-wrap">
          <strong class="dependency-col-name">${depName}</strong>
          <span class="muted dependency-col-description">${dep.Description || ''}</span>
        </div>
        <span class="dependency-col-installed">${versionText}${nextVersion}</span>
        <span class="dependency-status">${dep.Status || '-'}</span>
        <span class="dependency-col-action">${actionCell}</span>
      </div>
    `;
  }).join('');
}

function attachDependencyActionHandlers() {
  dependencyList.querySelectorAll('[data-dependency-action]').forEach((btn) => {
    btn.addEventListener('click', async () => {
      const action = btn.dataset.dependencyAction || 'install';
      const wingetId = btn.dataset.wingetId || '';
      const installerType = btn.dataset.installerType || 'winget';
      const moduleName = btn.dataset.moduleName || '';
      const name = btn.dataset.dependencyName || wingetId || moduleName;
      if (installerType === 'winget' && !wingetId) return;
      if (installerType === 'powershell-module' && !moduleName) return;
      dependencyMsg.textContent = `${action === 'upgrade' ? 'Update' : 'Installation'} laeuft: ${name}`;
      btn.disabled = true;
      try {
        const result = await jsonFetch('/api/dependencies/action', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ winget_id: wingetId, action, installer_type: installerType, module_name: moduleName }),
        });
        dependencyMsg.textContent = `${result.message || ''}\n${result.output || ''}`.trim();
        renderDependencyStatus(result.status || { available: false, message: 'Status konnte nicht aktualisiert werden.' });
      } catch (err) {
        dependencyMsg.textContent = `Dependency-Aktion fehlgeschlagen: ${err.message}`;
      }
    });
  });
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
  const availableNames = new Set(deps.map((dep) => dep.Name).filter(Boolean));
  dependencyPreferredTop5 = dependencyPreferredTop5.filter((name) => availableNames.has(name));

  const top5Base = getTop5BaseDependencies(deps);
  const compactNames = new Set(top5Base.map((dep) => dep.Name));
  deps.filter((dep) => !!getDependencyAction(dep)).forEach((dep) => compactNames.add(dep.Name));
  const compactDeps = deps.filter((dep) => compactNames.has(dep.Name));
  const hiddenCount = Math.max(0, deps.length - compactDeps.length);
  const depsToRender = dependencySelectionMode ? deps : (dependencyExpanded ? deps : compactDeps);
  const selectedCount = dependencyPreferredTop5.length;

  dependencySummary.textContent = data.all_satisfied
    ? `Systemstatus ok | ${deps.length} Abhaengigkeiten geprueft${dependencySelectionMode ? ' | Auswahlmodus aktiv' : (dependencyExpanded ? '' : ` | Kompaktansicht ${depsToRender.length}/${deps.length}`)}`
    : `Pruefung abgeschlossen | ${deps.length} Abhaengigkeiten | Eingriffe empfohlen${dependencySelectionMode ? ' | Auswahlmodus aktiv' : (dependencyExpanded ? '' : ` | Kompaktansicht ${depsToRender.length}/${deps.length}`)}`;

  dependencyList.innerHTML = deps.length
    ? `
      <div class="dependency-controls">
        <span class="muted dependency-controls-info">${dependencySelectionMode ? `Waehle Top 5 direkt ueber Aktion | Auswahl: ${selectedCount}/5` : (dependencyExpanded ? 'Alle Eintraege sichtbar' : `Top 5 + Aktionen sichtbar${hiddenCount > 0 ? ` | ${hiddenCount} ausgeblendet` : ''}`)} | Top-5 Auswahl: ${selectedCount}/5</span>
        <span class="dependency-controls-buttons">
          <button class="btn dependency-toggle-btn" data-dependency-select="1">${dependencySelectionMode ? 'Auswahl schliessen' : 'Top 5 wählen'}</button>
          ${(!dependencySelectionMode && (hiddenCount > 0 || dependencyExpanded)) ? `<button class="btn dependency-toggle-btn" data-dependency-toggle="1">${dependencyExpanded ? 'Weniger anzeigen' : 'Alle anzeigen'}</button>` : ''}
        </span>
      </div>
      <div class="dependency-table-head dependency-table-head-actions">
        <span>Paket</span>
        <span>Version</span>
        <span>Status</span>
        <span>Aktion</span>
      </div>
      ${buildDependencyRows(depsToRender, { selectionMode: dependencySelectionMode })}
    `
    : '<div class="audio-empty">Keine Dependency-Daten gefunden.</div>';

  const toggleBtn = dependencyList.querySelector('[data-dependency-toggle="1"]');
  if (toggleBtn) {
    toggleBtn.addEventListener('click', () => {
      dependencyExpanded = !dependencyExpanded;
      renderDependencyStatus(data);
    });
  }

  const selectBtn = dependencyList.querySelector('[data-dependency-select="1"]');
  if (selectBtn) {
    selectBtn.addEventListener('click', () => {
      dependencySelectionMode = !dependencySelectionMode;
      renderDependencyStatus(data);
    });
  }

  dependencyList.querySelectorAll('[data-dependency-top5-toggle]').forEach((btn) => {
    btn.addEventListener('click', () => {
      const name = btn.dataset.dependencyTop5Toggle || '';
      if (!name) return;

      const next = new Set(dependencyPreferredTop5);
      if (!next.has(name)) {
        if (next.size >= 5) {
          dependencyMsg.textContent = 'Maximal 5 Eintraege in Top 5 moeglich.';
          return;
        }
        next.add(name);
      } else {
        next.delete(name);
      }

      saveDependencyTop5Preferences(Array.from(next));
      renderDependencyStatus(data);
    });
  });

  attachDependencyActionHandlers();

  scheduleMasonryLayout(logsGrid);
}

async function loadDependencyStatus() {
  if (!dependencyPreferredTop5.length) {
    dependencyPreferredTop5 = loadDependencyTop5Preferences();
  }
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

async function refreshToolButtonStates() {
  if (!toolStateApiAvailable || toolStateRefreshInFlight) return;
  toolStateRefreshInFlight = true;
  try {
    const data = await jsonFetch('/api/tools/state');
    const states = data && data.states ? data.states : {};
    const closeSupported = new Set(Array.isArray(data.close_supported) ? data.close_supported : []);

    document.querySelectorAll('#toolsGrid [data-tool-run]').forEach((btn) => {
      const id = btn.dataset.toolRun || '';
      const isOpen = !!states[id];
      const canClose = closeSupported.has(id);
      btn.classList.toggle('is-open', isOpen);
      btn.classList.toggle('is-closable', canClose);
      btn.classList.toggle('is-open-readonly', isOpen && !canClose);
    });
  } catch (err) {
    if (String(err && err.message || '').includes('404')) {
      toolStateApiAvailable = false;
      if (toolStateTimer) {
        clearInterval(toolStateTimer);
        toolStateTimer = null;
      }
      document.querySelectorAll('#toolsGrid [data-tool-run]').forEach((btn) => {
        btn.classList.remove('is-open', 'is-closable', 'is-open-readonly');
      });
    }
    // keep UI usable even if state endpoint is temporarily unavailable
  } finally {
    toolStateRefreshInFlight = false;
  }
}

async function loadTools() {
  try {
    const TOOL_CATEGORY_ORDER = ['sys', 'net', 'diag', 'disk', 'priv', 'dev'];
    const TOOL_CATEGORY_CONTAINERS = {
      sys: toolSysList,
      net: toolNetList,
      diag: toolDiagList,
      disk: toolDiskList,
      priv: toolPrivList,
      dev: toolDevList,
    };

    const tools = await jsonFetch('/api/tools');
    availableTools = Array.isArray(tools) ? tools : [];
    const grouped = new Map();
    availableTools.forEach((tool) => {
      const cat = String(tool.cat || 'sys').trim().toLowerCase();
      if (!grouped.has(cat)) grouped.set(cat, []);
      grouped.get(cat).push(tool);
    });

    TOOL_CATEGORY_ORDER.forEach((cat) => {
      const container = TOOL_CATEGORY_CONTAINERS[cat];
      if (!container) return;
      const toolsInCat = grouped.get(cat) || [];
      container.innerHTML = toolsInCat.length
        ? `<div class="tool-tile-grid">
            ${toolsInCat.map((t) => `
              <button class="tool-tile" type="button" data-tool-run="${escapeHtml(t.id)}" title="${escapeHtml(t.desc || t.label || '')}">
                <strong>${escapeHtml(t.label || t.id || '')}</strong>
                <span>${escapeHtml(t.desc || '')}</span>
              </button>
            `).join('')}
          </div>`
        : '<div class="audio-empty">Keine Tools in dieser Kategorie.</div>';
    });

    // Unknown categories fall back into System card
    const unknownTools = Array.from(grouped.entries())
      .filter(([cat]) => !TOOL_CATEGORY_ORDER.includes(cat))
      .flatMap(([, list]) => list);
    if (unknownTools.length && toolSysList) {
      toolSysList.insertAdjacentHTML('beforeend', `
        <div class="tool-tile-grid">
          ${unknownTools.map((t) => `
            <button class="tool-tile" type="button" data-tool-run="${escapeHtml(t.id)}" title="${escapeHtml(t.desc || t.label || '')}">
              <strong>${escapeHtml(t.label || t.id || '')}</strong>
              <span>${escapeHtml(t.desc || '')}</span>
            </button>
          `).join('')}
        </div>
      `);
    }

    document.querySelectorAll('#toolsGrid [data-tool-run]').forEach((btn) => {
      btn.addEventListener('click', async () => {
        const id = btn.dataset.toolRun || '';
        const t = availableTools.find((x) => x.id === id) || { label: id };
        toolMsg.textContent = `${t.label} wird verarbeitet...`;
        try {
          let d;
          if (toolToggleApiAvailable) {
            try {
              d = await jsonFetch(`/api/tools/toggle/${encodeURIComponent(id)}`, { method: 'POST' });
            } catch (toggleErr) {
              if (String(toggleErr && toggleErr.message || '').includes('404')) {
                toolToggleApiAvailable = false;
                toolStateApiAvailable = false;
                if (toolStateTimer) {
                  clearInterval(toolStateTimer);
                  toolStateTimer = null;
                }
                d = await jsonFetch(`/api/tools/run/${encodeURIComponent(id)}`, { method: 'POST' });
              } else {
                throw toggleErr;
              }
            }
          } else {
            d = await jsonFetch(`/api/tools/run/${encodeURIComponent(id)}`, { method: 'POST' });
          }
          toolMsg.textContent = `${d.message || ''}\n${d.output || ''}`.trim();
          // Immediate optimistic visual update — do NOT rely on d.is_open:
          // The backend checks process existence right after launch (0.5 s),
          // but many tools (mmc-hosted, shell windows, …) aren't detectable yet
          // at that point → is_open comes back false even though the window opened.
          // Instead we trust the action field: opened → active, closed → inactive.
          if (d && d.action) {
            const canClose = !!d.close_supported;
            if (d.action === 'opened') {
              btn.classList.add('is-open');
              btn.classList.toggle('is-closable', canClose);
              btn.classList.toggle('is-open-readonly', !canClose);
            } else if (d.action === 'closed') {
              btn.classList.remove('is-open', 'is-closable', 'is-open-readonly');
            }
            // already-open / open-failed: leave current state, poll will correct.
          }
          // Real state sync shortly after so the backend process-check has had
          // time to detect the window; corrects any wrong optimistic guess.
          if (toolStateApiAvailable) {
            toolStateRefreshInFlight = false;
            setTimeout(() => {
              toolStateRefreshInFlight = false;
              refreshToolButtonStates();
            }, 1500);
          }
        } catch (err) {
          toolMsg.textContent = `Tool-Fehler: ${err.message}`;
        }
      });
    });

    await refreshToolButtonStates();
    updateScopedRefreshTimers();

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

function normalizeLauncherCategory(value) {
  return String(value || '').trim();
}

function normalizeLauncherCategoryKey(categoryName) {
  return normalizeLauncherCategory(categoryName).toLowerCase();
}

function readLauncherCategoryLayouts() {
  try {
    const raw = localStorage.getItem(LAUNCHER_CATEGORY_LAYOUTS_KEY);
    const parsed = raw ? JSON.parse(raw) : {};
    if (!parsed || typeof parsed !== 'object' || Array.isArray(parsed)) return {};

    const clean = {};
    Object.entries(parsed).forEach(([key, value]) => {
      const normalizedKey = normalizeLauncherCategoryKey(key);
      if (!normalizedKey) return;
      if (value === 'center' || value === 'left') clean[normalizedKey] = value;
    });
    return clean;
  } catch {
    return {};
  }
}

function saveLauncherCategoryLayouts() {
  try {
    localStorage.setItem(LAUNCHER_CATEGORY_LAYOUTS_KEY, JSON.stringify(launcherCategoryLayouts || {}));
  } catch {
    // ignore storage failures
  }
}

function getLauncherCategoryLayout(categoryName) {
  const key = normalizeLauncherCategoryKey(categoryName);
  if (!key) return 'left';
  return launcherCategoryLayouts[key] === 'center' ? 'center' : 'left';
}

function toggleLauncherCategoryLayout(categoryName) {
  const key = normalizeLauncherCategoryKey(categoryName);
  if (!key) return;
  const current = getLauncherCategoryLayout(categoryName);
  launcherCategoryLayouts[key] = current === 'center' ? 'left' : 'center';
  saveLauncherCategoryLayouts();
}

function readLauncherCategoryDensity() {
  try {
    const raw = localStorage.getItem(LAUNCHER_CATEGORY_DENSITY_KEY);
    const parsed = raw ? JSON.parse(raw) : {};
    if (!parsed || typeof parsed !== 'object' || Array.isArray(parsed)) return {};

    const clean = {};
    Object.entries(parsed).forEach(([key, value]) => {
      const normalizedKey = normalizeLauncherCategoryKey(key);
      if (!normalizedKey) return;
      if (value === 'compact' || value === 'normal') clean[normalizedKey] = value;
    });
    return clean;
  } catch {
    return {};
  }
}

function saveLauncherCategoryDensity() {
  try {
    localStorage.setItem(LAUNCHER_CATEGORY_DENSITY_KEY, JSON.stringify(launcherCategoryDensity || {}));
  } catch {
    // ignore storage failures
  }
}

function getLauncherCategoryDensity(categoryName) {
  const key = normalizeLauncherCategoryKey(categoryName);
  if (!key) return 'normal';
  return launcherCategoryDensity[key] === 'compact' ? 'compact' : 'normal';
}

function toggleLauncherCategoryDensity(categoryName) {
  const key = normalizeLauncherCategoryKey(categoryName);
  if (!key) return;
  const current = getLauncherCategoryDensity(categoryName);
  launcherCategoryDensity[key] = current === 'compact' ? 'normal' : 'compact';
  saveLauncherCategoryDensity();
}

function readLauncherCategoryOrder() {
  try {
    const raw = localStorage.getItem(LAUNCHER_CATEGORY_ORDER_KEY);
    const parsed = raw ? JSON.parse(raw) : [];
    if (!Array.isArray(parsed)) return [];
    return parsed
      .map((entry) => normalizeLauncherCategoryKey(entry))
      .filter((entry) => entry);
  } catch {
    return [];
  }
}

function saveLauncherCategoryOrder() {
  try {
    localStorage.setItem(LAUNCHER_CATEGORY_ORDER_KEY, JSON.stringify(launcherCategoryOrder || []));
  } catch {
    // ignore storage failures
  }
}

function getOrderedLauncherCategoryNames(groupedLaunchers) {
  const names = Array.from(groupedLaunchers.keys());
  const keyToName = new Map();
  names.forEach((name) => {
    keyToName.set(normalizeLauncherCategoryKey(name), name);
  });

  const ordered = [];
  const used = new Set();
  (launcherCategoryOrder || []).forEach((key) => {
    const name = keyToName.get(key);
    if (!name) return;
    ordered.push(name);
    used.add(key);
  });

  names
    .filter((name) => !used.has(normalizeLauncherCategoryKey(name)))
    .sort((a, b) => a.localeCompare(b, 'de', { sensitivity: 'base' }))
    .forEach((name) => ordered.push(name));

  launcherCategoryOrder = ordered.map((name) => normalizeLauncherCategoryKey(name)).filter((key) => key);
  saveLauncherCategoryOrder();
  return ordered;
}

function moveLauncherCategoryBefore(sourceKey, targetKey, orderedCategoryNames) {
  if (!sourceKey || !targetKey || sourceKey === targetKey) return false;

  const keys = orderedCategoryNames.map((name) => normalizeLauncherCategoryKey(name)).filter((key) => key);
  const fromIndex = keys.indexOf(sourceKey);
  const toIndex = keys.indexOf(targetKey);
  if (fromIndex < 0 || toIndex < 0 || fromIndex === toIndex) return false;

  const [moved] = keys.splice(fromIndex, 1);
  const insertIndex = keys.indexOf(targetKey);
  keys.splice(insertIndex, 0, moved);

  launcherCategoryOrder = keys;
  saveLauncherCategoryOrder();
  return true;
}

function getLauncherCategories() {
  const categories = new Set();
  customLaunchers.forEach((launcher) => {
    const categoryValue = normalizeLauncherCategory(launcher.category);
    if (categoryValue) categories.add(categoryValue);
  });
  return ['Alle', ...Array.from(categories).sort((a, b) => a.localeCompare(b, 'de', { sensitivity: 'base' }))];
}

function populateLauncherCategoryHints() {
  if (!launcherCategoryHints) return;
  launcherCategoryHints.innerHTML = getLauncherCategories()
    .filter((category) => category !== 'Alle')
    .map((category) => `<option value="${escapeHtml(category)}"></option>`)
    .join('');
}

function renderLauncherCategoryBar() {
  if (!launcherCategoryBar && !launcherSetupCategoryBar) return;
  const categories = getLauncherCategories();
  if (!categories.includes(selectedLauncherCategory)) selectedLauncherCategory = 'Alle';

  const markup = categories.map((category) => `
    <button class="launcher-category-chip${category === selectedLauncherCategory ? ' active' : ''}" type="button" data-launcher-category="${escapeHtml(category)}">
      ${escapeHtml(category)}
    </button>
  `).join('');

  [launcherCategoryBar, launcherSetupCategoryBar].forEach((bar) => {
    if (!bar) return;
    bar.innerHTML = markup;
    bar.querySelectorAll('[data-launcher-category]').forEach((btn) => {
      btn.addEventListener('click', () => {
        selectedLauncherCategory = btn.dataset.launcherCategory || 'Alle';
        renderLaunchers();
      });
    });
  });
}

function updateLauncherEditModeButton() {
  if (!toggleLauncherEditModeBtn) return;
  toggleLauncherEditModeBtn.textContent = launcherEditMode ? 'Bearbeitung beenden' : 'Bearbeitungsmodus';
  toggleLauncherEditModeBtn.classList.toggle('warn', launcherEditMode);
}

function setLauncherEditMode(enabled) {
  launcherEditMode = !!enabled;
  updateLauncherEditModeButton();
  if (launcherSetupList) launcherSetupList.classList.toggle('edit-mode', launcherEditMode);
  renderLaunchers();
}

async function deleteLauncher(launcherId) {
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
}

function getLauncherIconMarkup(iconName) {
  return getIconMarkup(iconName || 'grid');
}

function selectLauncherIcon(iconName = 'grid') {
  if (launcherIcon) launcherIcon.value = iconName || 'grid';
  if (!launcherIconPicker) return;
  launcherIconPicker.querySelectorAll('[data-launcher-icon]').forEach((btn) => {
    btn.classList.toggle('active', btn.dataset.launcherIcon === (iconName || 'grid'));
  });
}

function populateLauncherIconPicker(selected = 'grid') {
  if (!launcherIconPicker) return;
  launcherIconPicker.innerHTML = LAUNCHER_ICON_OPTIONS.map((item) => `
    <button class="launcher-icon-option" type="button" data-launcher-icon="${escapeHtml(item.id)}">
      ${getLauncherIconMarkup(item.id)}
      <span>${escapeHtml(item.label)}</span>
    </button>
  `).join('');
  launcherIconPicker.querySelectorAll('[data-launcher-icon]').forEach((btn) => {
    btn.addEventListener('click', () => selectLauncherIcon(btn.dataset.launcherIcon || 'grid'));
  });
  selectLauncherIcon(selected);
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
  const themeDefaults = getLauncherThemeColorDefaults();
  editingLauncherId = '';
  if (launcherName) launcherName.value = '';
  if (launcherKind) launcherKind.value = 'tool';
  if (launcherCategory) launcherCategory.value = '';
  if (launcherTarget) launcherTarget.value = '';
  if (launcherArgs) launcherArgs.value = '';
  if (launcherNote) launcherNote.value = '';
  if (launcherTileBg) launcherTileBg.value = themeDefaults.tile_bg;
  if (launcherTileText) launcherTileText.value = themeDefaults.tile_text;
  if (launcherTileBorder) launcherTileBorder.value = themeDefaults.tile_border;
  if (launcherTileAccent) launcherTileAccent.value = themeDefaults.tile_accent;
  populateLauncherIconPicker('grid');
  populateLauncherToolSelect();
  populateLauncherCategoryHints();
  syncLauncherForm();
  if (saveLauncherBtn) saveLauncherBtn.textContent = 'Launcher speichern';
}

function fillLauncherForm(launcher) {
  if (!launcher) return;
  const themeDefaults = getLauncherThemeColorDefaults();
  editingLauncherId = launcher.id || '';
  if (launcherName) launcherName.value = launcher.title || '';
  if (launcherKind) launcherKind.value = launcher.kind || 'tool';
  if (launcherCategory) launcherCategory.value = launcher.category || '';
  populateLauncherToolSelect(launcher.tool_id || '');
  if (launcherTarget) launcherTarget.value = launcher.target || '';
  if (launcherArgs) launcherArgs.value = launcher.args || '';
  if (launcherNote) launcherNote.value = launcher.note || '';
  if (launcherTileBg) launcherTileBg.value = normalizeLauncherTileColor(launcher.tile_bg) || themeDefaults.tile_bg;
  if (launcherTileText) launcherTileText.value = normalizeLauncherTileColor(launcher.tile_text) || themeDefaults.tile_text;
  if (launcherTileBorder) launcherTileBorder.value = normalizeLauncherTileColor(launcher.tile_border) || themeDefaults.tile_border;
  if (launcherTileAccent) launcherTileAccent.value = normalizeLauncherTileColor(launcher.tile_accent) || themeDefaults.tile_accent;
  populateLauncherIconPicker(launcher.icon || 'grid');
  syncLauncherForm();
  if (saveLauncherBtn) saveLauncherBtn.textContent = 'Launcher aktualisieren';
}

function getLauncherKindLabel(kind) {
  if (kind === 'tool') return 'Tool';
  if (kind === 'app') return 'App / Dienst';
  return 'Website / Netzwerk';
}

function normalizeLauncherTileColor(value) {
  const normalized = String(value || '').trim();
  const isShortHex = /^#[0-9a-fA-F]{3,4}$/.test(normalized);
  const isLongHex = /^#[0-9a-fA-F]{6}([0-9a-fA-F]{2})?$/.test(normalized);
  return (isShortHex || isLongHex) ? normalized.toLowerCase() : '';
}

function getLauncherThemeColorDefaults() {
  const rootStyles = getComputedStyle(document.documentElement);
  const pick = (name, fallback) => {
    const raw = String(rootStyles.getPropertyValue(name) || '').trim();
    const normalized = normalizeLauncherTileColor(raw);
    return normalized || fallback;
  };

  return {
    tile_bg: pick('--card', '#0f1b2e'),
    tile_text: pick('--text', '#e8efff'),
    tile_border: pick('--line', '#223554'),
    tile_accent: pick('--accent', '#4aa3ff'),
  };
}

function getCurrentLauncherColorSelection() {
  const defaults = getLauncherThemeColorDefaults();
  return {
    tile_bg: normalizeLauncherTileColor(launcherTileBg?.value || '') || defaults.tile_bg,
    tile_text: normalizeLauncherTileColor(launcherTileText?.value || '') || defaults.tile_text,
    tile_border: normalizeLauncherTileColor(launcherTileBorder?.value || '') || defaults.tile_border,
    tile_accent: normalizeLauncherTileColor(launcherTileAccent?.value || '') || defaults.tile_accent,
  };
}

function normalizeLauncherPresetName(value) {
  return String(value || '').trim();
}

function readLauncherStylePresets() {
  try {
    const raw = localStorage.getItem(LAUNCHER_STYLE_PRESETS_KEY);
    const data = raw ? JSON.parse(raw) : [];
    if (!Array.isArray(data)) return [];

    return data.map((item) => {
      const name = normalizeLauncherPresetName(item?.name);
      if (!name) return null;
      return {
        id: String(item?.id || name.toLowerCase().replace(/[^a-z0-9]+/g, '-')).trim() || `preset-${Date.now()}`,
        name,
        colors: {
          tile_bg: normalizeLauncherTileColor(item?.colors?.tile_bg),
          tile_text: normalizeLauncherTileColor(item?.colors?.tile_text),
          tile_border: normalizeLauncherTileColor(item?.colors?.tile_border),
          tile_accent: normalizeLauncherTileColor(item?.colors?.tile_accent),
        },
      };
    }).filter(Boolean);
  } catch {
    return [];
  }
}

function saveLauncherStylePresets() {
  localStorage.setItem(LAUNCHER_STYLE_PRESETS_KEY, JSON.stringify(launcherStylePresets));
}

function getLauncherStylePresetItems() {
  return [
    { id: 'theme-default', name: 'Aktuelles Theme', colors: getLauncherThemeColorDefaults(), builtin: true },
    ...launcherStylePresets,
  ];
}

function applyLauncherStylePreset(colors = {}, presetName = '') {
  const defaults = getLauncherThemeColorDefaults();
  if (launcherTileBg) launcherTileBg.value = normalizeLauncherTileColor(colors.tile_bg) || defaults.tile_bg;
  if (launcherTileText) launcherTileText.value = normalizeLauncherTileColor(colors.tile_text) || defaults.tile_text;
  if (launcherTileBorder) launcherTileBorder.value = normalizeLauncherTileColor(colors.tile_border) || defaults.tile_border;
  if (launcherTileAccent) launcherTileAccent.value = normalizeLauncherTileColor(colors.tile_accent) || defaults.tile_accent;
  if (launcherPresetName && presetName) launcherPresetName.value = presetName;
}

function resetLauncherColorsToThemeDefaults() {
  applyLauncherStylePreset(getLauncherThemeColorDefaults(), '');
  if (launcherPresetName) launcherPresetName.value = '';
  if (launcherMsg) launcherMsg.textContent = 'Launcher-Farben auf Standardfarben des aktuellen Themes zurueckgesetzt.';
}

function renderLauncherStylePresets() {
  if (!launcherPresetList) return;

  const items = getLauncherStylePresetItems();
  launcherPresetList.innerHTML = items.map((preset) => {
    const colors = preset.colors || getLauncherThemeColorDefaults();
    return `
      <div class="launcher-preset-chip">
        <button class="launcher-preset-apply" type="button" data-launcher-preset-apply="${escapeHtml(preset.id)}" title="${escapeHtml(preset.name)} anwenden">
          <span class="launcher-preset-swatch">
            <span style="background:${escapeHtml(colors.tile_bg || '#0f1b2e')}"></span>
            <span style="background:${escapeHtml(colors.tile_accent || '#4aa3ff')}"></span>
            <span style="background:${escapeHtml(colors.tile_border || '#223554')}"></span>
          </span>
          <span class="launcher-preset-label">${escapeHtml(preset.name)}</span>
        </button>
        ${preset.builtin ? '' : `<button class="launcher-preset-delete" type="button" data-launcher-preset-delete="${escapeHtml(preset.id)}" aria-label="Vorlage loeschen">x</button>`}
      </div>
    `;
  }).join('');

  launcherPresetList.querySelectorAll('[data-launcher-preset-apply]').forEach((btn) => {
    btn.addEventListener('click', () => {
      const presetId = btn.dataset.launcherPresetApply || '';
      const preset = getLauncherStylePresetItems().find((item) => item.id === presetId);
      if (!preset) return;
      applyLauncherStylePreset(preset.colors, preset.builtin ? '' : preset.name);
      if (launcherMsg) launcherMsg.textContent = `${preset.name} angewendet.`;
    });
  });

  launcherPresetList.querySelectorAll('[data-launcher-preset-delete]').forEach((btn) => {
    btn.addEventListener('click', () => {
      const presetId = btn.dataset.launcherPresetDelete || '';
      launcherStylePresets = launcherStylePresets.filter((item) => item.id !== presetId);
      saveLauncherStylePresets();
      renderLauncherStylePresets();
      if (launcherMsg) launcherMsg.textContent = 'Vorlage entfernt.';
    });
  });
}

function saveCurrentLauncherStylePreset() {
  const name = normalizeLauncherPresetName(launcherPresetName?.value || '');
  if (!name) {
    if (launcherMsg) launcherMsg.textContent = 'Bitte zuerst einen Vorlagennamen angeben.';
    return;
  }

  const presetId = name.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-+|-+$/g, '') || `preset-${Date.now()}`;
  const preset = {
    id: presetId,
    name,
    colors: getCurrentLauncherColorSelection(),
  };

  const existingIndex = launcherStylePresets.findIndex((item) => item.id === presetId || item.name.toLowerCase() === name.toLowerCase());
  if (existingIndex >= 0) {
    launcherStylePresets[existingIndex] = preset;
  } else {
    launcherStylePresets.push(preset);
  }

  launcherStylePresets.sort((a, b) => a.name.localeCompare(b.name, 'de', { sensitivity: 'base' }));
  saveLauncherStylePresets();
  renderLauncherStylePresets();
  if (launcherMsg) launcherMsg.textContent = `Vorlage '${name}' gespeichert.`;
}

function syncLauncherColorInputsWithThemeDefaults() {
  if (editingLauncherId) return;
  if (launcherName && launcherName.value.trim()) return;

  const defaults = getLauncherThemeColorDefaults();
  if (launcherTileBg) launcherTileBg.value = defaults.tile_bg;
  if (launcherTileText) launcherTileText.value = defaults.tile_text;
  if (launcherTileBorder) launcherTileBorder.value = defaults.tile_border;
  if (launcherTileAccent) launcherTileAccent.value = defaults.tile_accent;
  renderLauncherStylePresets();
}

function getLauncherTileInlineStyle(launcher) {
  const styles = [];

  const tileBg = normalizeLauncherTileColor(launcher?.tile_bg);
  const tileText = normalizeLauncherTileColor(launcher?.tile_text);
  const tileBorder = normalizeLauncherTileColor(launcher?.tile_border);
  const tileAccent = normalizeLauncherTileColor(launcher?.tile_accent);

  if (tileBg) styles.push(`--launcher-bg:${tileBg}`);
  if (tileText) styles.push(`--launcher-text:${tileText}`);
  if (tileBorder) styles.push(`--launcher-border:${tileBorder}`);
  if (tileAccent) styles.push(`--launcher-accent:${tileAccent}`);

  return styles.length ? ` style="${styles.join(';')}"` : '';
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
  if (!launcherList && !launcherSetupList) return;
  populateLauncherCategoryHints();
  renderLauncherCategoryBar();

  const visibleLaunchers = selectedLauncherCategory === 'Alle'
    ? [...customLaunchers]
    : customLaunchers.filter((launcher) => normalizeLauncherCategory(launcher.category) === selectedLauncherCategory);

  const groupedLaunchers = new Map();
  visibleLaunchers.forEach((launcher) => {
    const categoryName = normalizeLauncherCategory(launcher.category) || 'Ohne Kategorie';
    if (!groupedLaunchers.has(categoryName)) groupedLaunchers.set(categoryName, []);
    groupedLaunchers.get(categoryName).push(launcher);
  });
  const orderedCategories = getOrderedLauncherCategoryNames(groupedLaunchers);

  const renderLauncherListInto = (container, options = {}) => {
    if (!container) return;
    const { editable = false } = options;

    container.classList.toggle('launcher-list', true);
    container.classList.toggle('edit-mode', editable);

    if (!customLaunchers.length) {
      container.innerHTML = '<div class="audio-empty">Noch keine Schnellstart-Kacheln angelegt.</div>';
      return;
    }

    if (!visibleLaunchers.length) {
      container.innerHTML = '<div class="audio-empty">Keine Launcher in dieser Kategorie gefunden.</div>';
      return;
    }

    container.innerHTML = orderedCategories.map((categoryName, categoryIndex) => {
      const group = groupedLaunchers.get(categoryName) || [];
      const categoryLayout = getLauncherCategoryLayout(categoryName);
      const categoryDensity = getLauncherCategoryDensity(categoryName);
      return `
        <section class="launcher-section launcher-section-${categoryLayout} launcher-section-density-${categoryDensity}${editable ? ' launcher-section-editable' : ''}" data-launcher-category-section="${escapeHtml(categoryName)}">
          <div class="launcher-section-header">
            <div class="launcher-section-title">${escapeHtml(categoryName)}</div>
            <div class="launcher-section-actions">
              ${editable ? `<button class="launcher-section-move" type="button" data-launcher-category-move-up="${escapeHtml(categoryName)}" title="Nach oben" ${categoryIndex === 0 ? 'disabled' : ''}>&uarr;</button><button class="launcher-section-move" type="button" data-launcher-category-move-down="${escapeHtml(categoryName)}" title="Nach unten" ${categoryIndex === orderedCategories.length - 1 ? 'disabled' : ''}>&darr;</button>` : ''}
              ${editable ? `<button class="launcher-section-layout-toggle" type="button" data-launcher-category-layout="${escapeHtml(categoryName)}" title="Kategorie-Layout umschalten">
                ${categoryLayout === 'center' ? 'Text links' : 'Text zentrieren'}
              </button>` : ''}
              ${editable ? `<button class="launcher-section-density-toggle" type="button" data-launcher-category-density="${escapeHtml(categoryName)}" title="Kategorie-Kachelgroesse umschalten">
                ${categoryDensity === 'compact' ? 'Normal' : 'Kompakt'}
              </button>` : ''}
            </div>
          </div>
          <div class="launcher-grid">
            ${group.map((launcher) => `
              <div class="launcher-card${editable ? ' is-editing' : ''}"${getLauncherTileInlineStyle(launcher)}>
                <button class="launcher-delete" type="button" data-launcher-delete="${escapeHtml(launcher.id)}" aria-label="Launcher entfernen">x</button>
                <button class="launcher-run${editable ? ' is-editable' : ''}" type="button" data-launcher-run="${escapeHtml(launcher.id)}">
                  <span class="launcher-icon-badge">${getLauncherIconMarkup(launcher.icon || 'grid')}</span>
                  <strong>${escapeHtml(launcher.title)}</strong>
                  ${launcher.note ? `<small class="launcher-note">${escapeHtml(launcher.note)}</small>` : ''}
                </button>
              </div>
            `).join('')}
          </div>
        </section>
      `;
    }).join('');

    container.querySelectorAll('[data-launcher-run]').forEach((btn) => {
      btn.addEventListener('click', () => {
        const launcherId = btn.dataset.launcherRun || '';
        if (editable) {
          const launcher = customLaunchers.find((item) => item.id === launcherId);
          fillLauncherForm(launcher);
          if (launcherMsg && launcher?.title) launcherMsg.textContent = `${launcher.title} zur Bearbeitung geladen.`;
          return;
        }
        runLauncher(launcherId);
      });
    });

    container.querySelectorAll('[data-launcher-delete]').forEach((btn) => {
      btn.addEventListener('click', async (event) => {
        event.stopPropagation();
        await deleteLauncher(btn.dataset.launcherDelete || '');
      });
    });

    container.querySelectorAll('[data-launcher-category-layout]').forEach((btn) => {
      btn.addEventListener('click', (event) => {
        event.preventDefault();
        event.stopPropagation();
        toggleLauncherCategoryLayout(btn.dataset.launcherCategoryLayout || '');
        renderLaunchers();
      });
    });

    container.querySelectorAll('[data-launcher-category-density]').forEach((btn) => {
      btn.addEventListener('click', (event) => {
        event.preventDefault();
        event.stopPropagation();
        toggleLauncherCategoryDensity(btn.dataset.launcherCategoryDensity || '');
        renderLaunchers();
      });
    });

    if (editable) {
      container.querySelectorAll('[data-launcher-category-move-up]').forEach((btn) => {
        btn.addEventListener('click', () => {
          const categoryName = btn.dataset.launcherCategoryMoveUp || '';
          const key = normalizeLauncherCategoryKey(categoryName);
          const idx = orderedCategories.indexOf(categoryName);
          if (idx > 0) {
            moveLauncherCategoryBefore(key, normalizeLauncherCategoryKey(orderedCategories[idx - 1]), orderedCategories);
            renderLaunchers();
          }
        });
      });

      container.querySelectorAll('[data-launcher-category-move-down]').forEach((btn) => {
        btn.addEventListener('click', () => {
          const categoryName = btn.dataset.launcherCategoryMoveDown || '';
          const idx = orderedCategories.indexOf(categoryName);
          if (idx >= 0 && idx < orderedCategories.length - 1) {
            moveLauncherCategoryBefore(
              normalizeLauncherCategoryKey(orderedCategories[idx + 1]),
              normalizeLauncherCategoryKey(categoryName),
              orderedCategories
            );
            renderLaunchers();
          }
        });
      });
    }
  };

  renderLauncherListInto(launcherList, { editable: false });
  renderLauncherListInto(launcherSetupList, { editable: launcherEditMode });

  scheduleMasonryLayout(quickstartGrid);
  scheduleMasonryLayout(setupGrid);
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
    if (launcherSetupList) launcherSetupList.innerHTML = '<div class="audio-empty">Launcher konnten nicht geladen werden.</div>';
    scheduleMasonryLayout(quickstartGrid);
    scheduleMasonryLayout(setupGrid);
  }
}

async function saveLauncher() {
  if (!launcherName || !launcherKind) return;
  const themeDefaults = getLauncherThemeColorDefaults();
  const tileBg = normalizeLauncherTileColor(launcherTileBg?.value || '') || themeDefaults.tile_bg;
  const tileText = normalizeLauncherTileColor(launcherTileText?.value || '') || themeDefaults.tile_text;
  const tileBorder = normalizeLauncherTileColor(launcherTileBorder?.value || '') || themeDefaults.tile_border;
  const tileAccent = normalizeLauncherTileColor(launcherTileAccent?.value || '') || themeDefaults.tile_accent;

  const payload = {
    id: editingLauncherId,
    title: launcherName.value.trim(),
    kind: launcherKind.value,
    tool_id: launcherToolId?.value || '',
    category: normalizeLauncherCategory(launcherCategory?.value || ''),
    target: launcherTarget?.value.trim() || '',
    args: launcherArgs?.value.trim() || '',
    note: launcherNote?.value.trim() || '',
    icon: launcherIcon?.value || 'grid',
    tile_bg: tileBg,
    tile_text: tileText,
    tile_border: tileBorder,
    tile_accent: tileAccent,
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
    selectedLauncherCategory = payload.category || 'Alle';
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
    selectedLauncherCategory = payload.category || 'Alle';
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

function normalizeFavoriteDeviceIds(ids) {
  const seen = new Set();
  const result = [];
  (Array.isArray(ids) ? ids : []).forEach((id) => {
    const normalized = String(id || '').trim();
    if (!normalized || seen.has(normalized)) return;
    seen.add(normalized);
    result.push(normalized);
  });
  return result.slice(0, 3);
}

function normalizeUserRoute(route) {
  const normalized = {
    program: String(route?.program || '').trim(),
    deviceId: String(route?.deviceId || '').trim(),
    deviceName: String(route?.deviceName || '').trim(),
    favoriteDeviceIds: normalizeFavoriteDeviceIds(route?.favoriteDeviceIds),
  };
  if (!normalized.favoriteDeviceIds.length && normalized.deviceId) {
    normalized.favoriteDeviceIds = [normalized.deviceId];
  }
  return normalized;
}

function normalizeAllUserRoutes(routes) {
  return (Array.isArray(routes) ? routes : []).map((r) => normalizeUserRoute(r)).filter((r) => r.program);
}

function readAudioEditMode() {
  try {
    return localStorage.getItem(AUDIO_EDIT_MODE_KEY) === '1';
  } catch {
    return false;
  }
}

function saveAudioEditMode(enabled) {
  try {
    localStorage.setItem(AUDIO_EDIT_MODE_KEY, enabled ? '1' : '0');
  } catch {
    // ignore storage failures
  }
}

function setRoutingEditOnlyVisibility(enabled) {
  document.querySelectorAll('.audio-edit-only').forEach((el) => {
    el.hidden = !enabled;
  });
}

function setAudioEditMode(enabled) {
  audioEditMode = !!enabled;
  saveAudioEditMode(audioEditMode);

  if (audioEditModeBtn) {
    audioEditModeBtn.textContent = audioEditMode ? 'Bearbeitungsmodus: An' : 'Bearbeitungsmodus: Aus';
    audioEditModeBtn.classList.toggle('warn', audioEditMode);
  }

  setRoutingEditOnlyVisibility(audioEditMode);
  if (userRoutingHint) {
    userRoutingHint.textContent = audioEditMode
      ? 'Edit-Modus: Programme zuordnen, Sync/Repair ausfuehren und Debug-Log nutzen.'
      : 'Live-Modus: Nutze "Jetzt umschalten" in den Routen. Fuer Konfiguration den Bearbeitungsmodus aktivieren.';
  }

  renderUserProgramRoutes();
  renderAudioDevicesList(lastAudioDeviceSummary.activeOutput, lastAudioDeviceSummary.activeInput, lastAudioDeviceSummary.routingMessage);
  loadAudioSessions().catch(() => {});
}

async function loadInputMetering() {
  try {
    const d = await jsonFetch('/api/audio/input-level');
    lastInputMeteringData = {
      level: Math.max(0, Math.min(100, parseInt(d.level || 0, 10))),
      peak: Math.max(0, Math.min(100, parseInt(d.peak || 0, 10))),
      available: !!d.available,
    };
    // Trigger render to update meter display
    if (userProgramRoutes) {
      renderUserProgramRoutes();
    }
  } catch {
    // Keep last known state
  }
}

function delay(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function waitForActiveAudioDevice(deviceId, deviceKind = 'output', maxAttempts = 6, waitMs = 180) {
  const isInput = deviceKind === 'input';
  for (let attempt = 0; attempt < maxAttempts; attempt += 1) {
    try {
      const d = await jsonFetch('/api/audio/devices');
      const devices = Array.isArray(d.devices) ? d.devices : [];
      const target = devices.find((dev) => String(dev.id || '') === String(deviceId || ''));
      if (target) {
        const active = isInput ? !!target.is_active_input : !!target.is_active_output;
        if (active) return true;
      }
    } catch {
      // keep retrying
    }
    await delay(waitMs);
  }
  return false;
}

function readHiddenAudioDevices() {
  try {
    const raw = localStorage.getItem(AUDIO_HIDDEN_DEVICES_KEY);
    const parsed = raw ? JSON.parse(raw) : [];
    if (!Array.isArray(parsed)) return [];
    return parsed.map((id) => String(id || '').trim()).filter((id) => id);
  } catch {
    return [];
  }
}

function saveHiddenAudioDevices() {
  try {
    localStorage.setItem(AUDIO_HIDDEN_DEVICES_KEY, JSON.stringify(Array.from(hiddenAudioDeviceIds)));
  } catch {
    // ignore storage failures
  }
}

function hideAudioDevice(deviceId) {
  const id = String(deviceId || '').trim();
  if (!id) return false;
  hiddenAudioDeviceIds.add(id);
  saveHiddenAudioDevices();
  return true;
}

function clearHiddenAudioDevices() {
  hiddenAudioDeviceIds.clear();
  saveHiddenAudioDevices();
}

function getOutputAudioDevices() {
  return cachedAudioDevices.filter((d) => d.is_output !== false && d.kind !== 'input' && !hiddenAudioDeviceIds.has(String(d.id || '')));
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

function appendRouteDebugEntry(level, text) {
  const stamp = new Date().toLocaleTimeString('de-DE', { hour12: false });
  routeDebugEvents.push({ ts: stamp, level: String(level || 'INFO').toUpperCase(), text: String(text || '') });
  if (routeDebugEvents.length > 40) {
    routeDebugEvents = routeDebugEvents.slice(-40);
  }
  if (!routeDebugLog) return;
  routeDebugLog.textContent = routeDebugEvents.map((e) => `[${e.ts}] ${e.level}  ${e.text}`).join('\n') || 'Route-Diagnose bereit.';
}

function clearRouteDebugEntries() {
  routeDebugEvents = [];
  if (routeDebugLog) {
    routeDebugLog.textContent = 'Route-Diagnose bereit.';
  }
}

async function refreshPersistedRoutesReadback() {
  if (!persistedReadbackApiAvailable) {
    return;
  }

  const pids = [...new Set(lastAudioSessions.map((s) => Number(s.pid || 0)).filter((pid) => pid > 0))];
  if (!pids.length) {
    persistedRouteByPid = new Map();
    return;
  }

  try {
    const d = await jsonFetch('/api/audio/route-app/readback', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ pids, device_kind: 'output' }),
    });
    const next = new Map();
    (Array.isArray(d.routes) ? d.routes : []).forEach((row) => {
      const key = String(row.pid || '');
      if (!key) return;
      next.set(key, row);
    });
    persistedRouteByPid = next;
  } catch (err) {
    if (isHttp404(err)) {
      persistedReadbackApiAvailable = false;
      persistedRouteByPid = new Map();
      appendRouteDebugEntry('info', 'Readback-API (noch) nicht verfuegbar. Bitte Python-Dashboard neu starten, um Persisted-Status zu sehen.');
      return;
    }
    appendRouteDebugEntry('warn', `Readback konnte nicht geladen werden: ${err.message}`);
  }
}

async function setDefaultAudioDevice(deviceId, deviceName = '', deviceKind = 'output') {
  if (!deviceId) {
    audioMsg.textContent = deviceKind === 'input' ? 'Kein Mikrofon ausgewaehlt.' : 'Kein Ausgabegeraet ausgewaehlt.';
    return false;
  }
  if (audioSwitchInFlight) {
    audioMsg.textContent = 'Audio-Umschaltung laeuft bereits...';
    return false;
  }
  audioSwitchInFlight = true;
  try {
    const kindLabel = deviceKind === 'input' ? 'Mikrofon' : 'Ausgabe';
    audioMsg.textContent = `${kindLabel} wird umgeschaltet...`;
    const d = await jsonFetch('/api/audio/default-device', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ device_id: deviceId, device_kind: deviceKind }),
    });
    if (!d.success) {
      audioMsg.textContent = `Umschalten fehlgeschlagen: ${d.output || d.message || 'Unbekannter Fehler'}`;
      return false;
    }

    let verified = await waitForActiveAudioDevice(deviceId, deviceKind, 6, 180);
    if (!verified) {
      const retry = await jsonFetch('/api/audio/default-device', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ device_id: deviceId, device_kind: deviceKind }),
      });
      if (retry.success) {
        verified = await waitForActiveAudioDevice(deviceId, deviceKind, 6, 220);
      }
    }

    const activeName = deviceKind === 'input' ? (d.active_input || '') : (d.active_output || '');
    audioMsg.textContent = verified
      ? `Umschaltung erfolgreich: ${deviceName || activeName || 'Neues Standardgeraet aktiv'}`
      : `Umschaltung ausgeloest, aber Rueckmeldung verzoegert: ${deviceName || activeName || 'Geraet'}`;
    await refreshAudio();
    return verified;
  } catch (err) {
    audioMsg.textContent = `Umschalten-Fehler: ${err.message}`;
    return false;
  } finally {
    audioSwitchInFlight = false;
  }
}

async function setPerAppAudioRoute(pid, deviceId, deviceName = '', deviceKind = 'output') {
  const parsedPid = Number(pid || 0);
  if (!parsedPid || parsedPid <= 0) {
    return { success: false, message: 'Ungueltige PID.' };
  }
  if (!deviceId) {
    return { success: false, message: 'Kein Zielgeraet angegeben.' };
  }

  try {
    const d = await jsonFetch('/api/audio/route-app', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ pid: parsedPid, device_id: deviceId, device_kind: deviceKind }),
    });
    if (!d.success) {
      appendRouteDebugEntry('warn', `PID ${parsedPid} -> ${deviceName || deviceId} fehlgeschlagen: ${d.message || 'Unbekannter Fehler'}`);
      return { success: false, message: d.message || 'Per-App Routing fehlgeschlagen.' };
    }
    appendRouteDebugEntry('ok', `PID ${parsedPid} -> ${deviceName || deviceId} gesetzt (${d.duration_ms || 0} ms)`);
    return { success: true, message: d.message || `Per-App Routing gesetzt: PID ${parsedPid} -> ${deviceName || deviceId}` };
  } catch (err) {
    appendRouteDebugEntry('error', `PID ${parsedPid} -> ${deviceName || deviceId} Fehler: ${err.message}`);
    return { success: false, message: `Per-App Routing Fehler: ${err.message}` };
  }
}

function findSessionsForProgram(programName) {
  const token = normalizeProgramToken(programName);
  if (!token) return [];

  return lastAudioSessions.filter((s) => {
    const appToken = normalizeProgramToken(s.app);
    return appToken.includes(token) || token.includes(appToken);
  });
}

async function applyPerAppRouteForProgram(programName, deviceId, deviceName = '') {
  const sessions = findSessionsForProgram(programName);
  const pids = [...new Set(sessions.map((s) => Number(s.pid || 0)).filter((p) => p > 0))];

  if (!pids.length) {
    appendRouteDebugEntry('info', `Keine aktive Session fuer ${programName}; Route wird bei naechster Session angewendet.`);
    audioMsg.textContent = `Zuordnung gespeichert: ${programName} -> ${deviceName || resolveDeviceNameById(deviceId)}. Wird angewendet, sobald eine Audio-Session der App aktiv ist.`;
    return false;
  }

  let okCount = 0;
  const failures = [];
  for (const pid of pids) {
    const result = await setPerAppAudioRoute(pid, deviceId, deviceName, 'output');
    if (result.success) {
      okCount += 1;
    } else {
      failures.push(`PID ${pid}: ${result.message}`);
    }
  }

  if (!okCount) {
    appendRouteDebugEntry('error', `Routing fuer ${programName} komplett fehlgeschlagen.`);
    audioMsg.textContent = `Per-App Routing fehlgeschlagen fuer ${programName}: ${failures[0] || 'Unbekannter Fehler'}`;
    return false;
  }

  audioMsg.textContent = failures.length
    ? `Per-App Routing teilweise gesetzt (${okCount}/${pids.length}) fuer ${programName}.`
    : `Per-App Routing gesetzt fuer ${programName} (${okCount} Session${okCount === 1 ? '' : 's'}).`;
  appendRouteDebugEntry(
    failures.length ? 'warn' : 'ok',
    failures.length
      ? `${programName}: teilweise gesetzt (${okCount}/${pids.length})`
      : `${programName}: erfolgreich gesetzt (${okCount}/${pids.length})`
  );
  await refreshPersistedRoutesReadback();
  scheduleRouteSessionRefresh(500);
  return true;
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

function findRoutingConflicts(sourceProgram, targetDeviceId) {
  const routes = normalizeAllUserRoutes(readUserAudioRoutes());
  const sourceToken = normalizeProgramToken(sourceProgram);
  const targetId = String(targetDeviceId || '');
  if (!sourceToken || !targetId || !routes.length) return [];

  return routes
    .filter((r) => normalizeProgramToken(r.program) !== sourceToken)
    .map((r) => {
      const routeToken = normalizeProgramToken(r.program);
      const session = lastAudioSessions.find((s) => {
        const appToken = normalizeProgramToken(s.app);
        return appToken.includes(routeToken) || routeToken.includes(appToken);
      });
      if (!session) return null;

      const isActive = Number(session.state || 0) > 0;
      const isMuted = !!session.muted;
      if (!isActive || isMuted) return null;

      const otherTarget = String(r.deviceId || '');
      if (!otherTarget || otherTarget === targetId) return null;

      return {
        program: r.program,
        currentDevice: session.device_name || 'Unbekannt',
        preferredDevice: resolveDeviceNameById(otherTarget),
      };
    })
    .filter(Boolean);
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

function scheduleRouteSessionRefresh(delayMs = 500) {
  if (routeSessionRefreshTimer) {
    clearTimeout(routeSessionRefreshTimer);
  }
  routeSessionRefreshTimer = setTimeout(() => {
    loadAudioSessions().catch(() => {});
    routeSessionRefreshTimer = null;
  }, Math.max(120, delayMs));
}

function setRouteSessionMuteUi(controlsEl, muted, pending = false) {
  if (!controlsEl) return;

  const muteBtn = controlsEl.querySelector('[data-route-session-mute]');
  const badge = controlsEl.querySelector('.audio-route-session-badge');

  if (muteBtn) {
    muteBtn.classList.toggle('is-muted', !!muted);
    muteBtn.classList.toggle('is-pending', !!pending);
    muteBtn.title = muted ? 'Unmute' : 'Mute';
    muteBtn.dataset.routeSessionState = muted ? '0' : '1';
    muteBtn.disabled = !!pending;
  }

  if (badge) {
    badge.classList.remove('is-active', 'is-muted');
    badge.classList.add(muted ? 'is-muted' : 'is-active');
    badge.textContent = muted ? 'Stumm' : 'Aktiv';
  }
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
  const routes = normalizeAllUserRoutes(readUserAudioRoutes());
  if (!routes.length) {
    userProgramRoutes.innerHTML = '<div class="audio-empty">Noch keine Benutzer-Programme hinterlegt.</div>';
    scheduleMasonryLayout(audioGrid);
    return;
  }

  const outputDevices = getOutputAudioDevices();
  const outputDeviceMap = new Map(outputDevices.map((dev) => [String(dev.id || ''), dev]));

  userProgramRoutes.innerHTML = routes.map((r, idx) => {
    const routeToken = normalizeProgramToken(r.program);
    const routeSessions = lastAudioSessions.filter((s) => {
      const appToken = normalizeProgramToken(s.app);
      return appToken.includes(routeToken) || routeToken.includes(appToken);
    });
    const match = routeSessions.length
      ? routeSessions.sort((a, b) => (Number(b.state || 0) - Number(a.state || 0)) || (Number(b.volume || 0) - Number(a.volume || 0)))[0]
      : null;
    const runningProgram = cachedOpenPrograms.find((p) => {
      const processToken = normalizeProgramToken(p);
      return processToken.includes(routeToken) || routeToken.includes(processToken);
    });
    let status = 'Aktuell nicht als Session erkannt';
    if (match) {
      const persisted = persistedRouteByPid.get(String(match.pid || ''));
      const persistedInfo = persisted
        ? (persisted.configured
            ? ` | Persistiert: ${persisted.persisted_device_name || persisted.persisted_device_id || 'Unbekannt'}`
            : ' | Persistiert: keine')
        : '';
      status = `Aktiv als ${match.app} (PID ${match.pid}) auf ${match.device_name || 'Unbekannt'}${persistedInfo}`;
    } else if (runningProgram) {
      status = `${runningProgram} laeuft, aber Windows meldet derzeit keine aktive Audio-Session`;
    }
    const favoriteIds = normalizeFavoriteDeviceIds(r.favoriteDeviceIds || []);
    const favoriteButtons = favoriteIds.length
      ? favoriteIds.map((favId) => {
          const favDev = outputDeviceMap.get(String(favId || ''));
          const isActiveTarget = String(r.deviceId || '') === String(favId || '');
          if (!favDev) {
            return `<button class="btn audio-fav-btn" type="button" disabled title="Geraet nicht verfuegbar">offline</button>`;
          }
          const short = String(favDev.name || 'Geraet').slice(0, 18);
          return `
            <span class="audio-fav-chip${isActiveTarget ? ' is-active-target' : ''}">
              <button class="btn audio-fav-btn${isActiveTarget ? ' is-active-target' : ''}" type="button" data-route-fav-apply="${idx}" data-route-fav-id="${favDev.id}" title="${favDev.name}${isActiveTarget ? ' (Aktuelles Ziel)' : ''}">${short}</button>
              ${audioEditMode ? `<button class="btn audio-fav-remove" type="button" data-route-fav-remove="${idx}" data-route-fav-remove-id="${favDev.id}" title="Favorit entfernen">x</button>` : ''}
            </span>
          `;
        }).join('')
      : '<span class="muted">Keine Favoriten</span>';
    const canAddFavorite = audioEditMode && favoriteIds.length < 3 && !!String(r.deviceId || '').trim();
    const sessionControls = match
      ? `
        <div class="audio-route-session-controls" data-route-session-controls="${idx}">
          <input type="range" min="0" max="100" value="${match.volume}" data-route-session-volume="${idx}" data-route-session-pid="${match.pid}" />
          <button class="btn audio-route-mute-btn${match.muted ? ' is-muted' : ''}" title="${match.muted ? 'Unmute' : 'Mute'}" data-route-session-mute="${idx}" data-route-session-pid="${match.pid}" data-route-session-state="${match.muted ? 0 : 1}">
            <span class="icon-inline" aria-hidden="true"><svg viewBox="0 0 24 24" focusable="false"><use href="#icon-speaker"></use></svg></span>
          </button>
          <span class="audio-route-session-level">${match.volume}%</span>
          <span class="audio-route-session-badge${match.muted ? ' is-muted' : ' is-active'}">${match.muted ? 'Stumm' : 'Aktiv'}</span>
        </div>
      `
      : '<div class="audio-route-session-controls"><span class="audio-route-session-badge is-offline">Keine Session</span></div>';

    return `
      <div class="audio-user-route-item ${audioEditMode ? 'is-edit' : 'is-live'}" data-route-index="${idx}">
        <div>
          <strong>${r.program}</strong>
          ${audioEditMode ? `<p class="muted">${status}</p>` : ''}
          <div class="audio-fav-row" data-route-favs="${idx}">
            ${favoriteButtons}
            ${canAddFavorite ? `<button class="btn audio-fav-add" type="button" data-route-fav-add="${idx}" title="Aktuelles Ziel zu Favoriten">+ Fav</button>` : ''}
          </div>
          ${sessionControls}
        </div>
        <select ${audioEditMode ? '' : 'class="audio-hidden"'} data-route-device="${idx}">
          ${outputDevices.map((d) => `<option value="${d.id}" ${d.id === r.deviceId ? 'selected' : ''}>${d.name}${d.is_active_output ? ' (Aktiv)' : ''}</option>`).join('')}
        </select>
        <button class="btn${audioEditMode ? '' : ' audio-hidden'}" data-route-apply="${idx}">Jetzt umschalten</button>
        <button class="btn${audioEditMode ? '' : ' audio-hidden'}" data-route-remove="${idx}">Entfernen</button>
      </div>
    `;
  }).join('');

  userProgramRoutes.querySelectorAll('[data-route-device]').forEach((sel) => {
    sel.addEventListener('change', () => {
      const idx = parseInt(sel.dataset.routeDevice, 10);
      const all = normalizeAllUserRoutes(readUserAudioRoutes());
      if (!Number.isInteger(idx) || !all[idx]) return;
      all[idx].deviceId = sel.value;
      all[idx].deviceName = resolveDeviceNameById(sel.value);
      all[idx].favoriteDeviceIds = normalizeFavoriteDeviceIds([...(all[idx].favoriteDeviceIds || []), sel.value]);
      saveUserAudioRoutes(all);
      audioMsg.textContent = `Zuordnung gespeichert: ${all[idx].program} -> ${all[idx].deviceName}`;
      renderUserProgramRoutes();
    });
  });

  userProgramRoutes.querySelectorAll('[data-route-remove]').forEach((btn) => {
    btn.addEventListener('click', () => {
      const idx = parseInt(btn.dataset.routeRemove, 10);
      const all = normalizeAllUserRoutes(readUserAudioRoutes());
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
      const all = normalizeAllUserRoutes(readUserAudioRoutes());
      if (!Number.isInteger(idx) || !all[idx]) return;
      const route = all[idx];
      const devName = route.deviceName || resolveDeviceNameById(route.deviceId);
      await applyPerAppRouteForProgram(route.program, route.deviceId, devName);
    });
  });

  userProgramRoutes.querySelectorAll('[data-route-fav-add]').forEach((btn) => {
    btn.addEventListener('click', () => {
      const idx = parseInt(btn.dataset.routeFavAdd, 10);
      const all = normalizeAllUserRoutes(readUserAudioRoutes());
      if (!Number.isInteger(idx) || !all[idx]) return;
      const route = all[idx];
      if (!route.deviceId) return;
      route.favoriteDeviceIds = normalizeFavoriteDeviceIds([...(route.favoriteDeviceIds || []), route.deviceId]);
      saveUserAudioRoutes(all);
      audioMsg.textContent = `Favorit hinzugefuegt: ${route.program}`;
      renderUserProgramRoutes();
    });
  });

  userProgramRoutes.querySelectorAll('[data-route-fav-apply]').forEach((btn) => {
    btn.addEventListener('click', async () => {
      const idx = parseInt(btn.dataset.routeFavApply, 10);
      const favId = String(btn.dataset.routeFavId || '').trim();
      const all = normalizeAllUserRoutes(readUserAudioRoutes());
      if (!Number.isInteger(idx) || !all[idx] || !favId) return;
      const route = all[idx];
      route.deviceId = favId;
      route.deviceName = resolveDeviceNameById(favId);
      saveUserAudioRoutes(all);
      btn.disabled = true;
      try {
        await applyPerAppRouteForProgram(route.program, favId, route.deviceName);
        await loadAudioSessions();
      } finally {
        btn.disabled = false;
      }
      renderUserProgramRoutes();
    });
  });

  userProgramRoutes.querySelectorAll('[data-route-fav-remove]').forEach((btn) => {
    btn.addEventListener('click', () => {
      const idx = parseInt(btn.dataset.routeFavRemove, 10);
      const removeId = String(btn.dataset.routeFavRemoveId || '').trim();
      const all = normalizeAllUserRoutes(readUserAudioRoutes());
      if (!Number.isInteger(idx) || !all[idx] || !removeId) return;
      const route = all[idx];
      route.favoriteDeviceIds = normalizeFavoriteDeviceIds((route.favoriteDeviceIds || []).filter((id) => String(id) !== removeId));
      if (String(route.deviceId || '') === removeId) {
        route.deviceId = route.favoriteDeviceIds[0] || route.deviceId;
        route.deviceName = resolveDeviceNameById(route.deviceId);
      }
      saveUserAudioRoutes(all);
      audioMsg.textContent = `Favorit entfernt: ${route.program}`;
      renderUserProgramRoutes();
    });
  });

  userProgramRoutes.querySelectorAll('[data-route-session-volume]').forEach((slider) => {
    slider.addEventListener('change', async () => {
      const pid = parseInt(slider.dataset.routeSessionPid, 10);
      const level = parseInt(slider.value, 10) || 0;
      if (!Number.isInteger(pid)) return;
      // Optimistic: update % label immediately
      const controlsEl = slider.closest('[data-route-session-controls]');
      const levelLabel = controlsEl && controlsEl.querySelector('.audio-route-session-level');
      if (levelLabel) levelLabel.textContent = `${level}%`;
      try {
        await jsonFetch(`/api/audio/session/${pid}/volume/${Math.max(0, Math.min(100, level))}`, { method: 'POST' });
        scheduleRouteSessionRefresh(400);
      } catch (err) {
        audioMsg.textContent = `Session-Volume Fehler: ${err.message}`;
      }
    });
  });

  userProgramRoutes.querySelectorAll('[data-route-session-mute]').forEach((btn) => {
    btn.addEventListener('click', async () => {
      const pid = parseInt(btn.dataset.routeSessionPid, 10);
      const state = parseInt(btn.dataset.routeSessionState, 10) || 0;
      if (!Number.isInteger(pid)) return;

      if (routeMuteInFlight.has(pid)) return;

      const controlsEl = btn.closest('[data-route-session-controls]');
      const currentMuted = (state === 0);
      const nextMuted = (state === 1);

      routeMuteInFlight.add(pid);
      setRouteSessionMuteUi(controlsEl, nextMuted, true);

      try {
        await jsonFetch(`/api/audio/session/${pid}/mute/${state}`, { method: 'POST' });
        setRouteSessionMuteUi(controlsEl, nextMuted, false);
        scheduleRouteSessionRefresh(450);
      } catch (err) {
        setRouteSessionMuteUi(controlsEl, currentMuted, false);
        audioMsg.textContent = `Session-Mute Fehler: ${err.message}`;
      } finally {
        routeMuteInFlight.delete(pid);
      }
    });
  });

  scheduleMasonryLayout(audioGrid);
}

function wireUserAudioRoutingControls() {
  if (!addUserProgramBtn || !openRoutingSettingsBtn) return;

  if (syncRoutesBtn) {
    syncRoutesBtn.addEventListener('click', async () => {
      const routes = normalizeAllUserRoutes(readUserAudioRoutes());
      if (!routes.length) {
        audioMsg.textContent = 'Keine gespeicherten Routen zum Synchronisieren.';
        return;
      }

      syncRoutesBtn.disabled = true;
      let ok = 0;
      for (const route of routes) {
        const targetId = String(route.deviceId || '').trim();
        if (!targetId) continue;
        const targetName = route.deviceName || resolveDeviceNameById(targetId);
        const changed = await applyPerAppRouteForProgram(route.program, targetId, targetName);
        if (changed) ok += 1;
      }
      await loadAudioSessions();
      renderUserProgramRoutes();
      audioMsg.textContent = `Sync/Repair abgeschlossen: ${ok} Route${ok === 1 ? '' : 'n'} angewendet.`;
      appendRouteDebugEntry('info', `Sync/Repair abgeschlossen (${ok} erfolgreich).`);
      syncRoutesBtn.disabled = false;
    });
  }

  if (clearAllRoutesBtn) {
    clearAllRoutesBtn.addEventListener('click', async () => {
      const confirmed = window.confirm('Alle persistierten App-Routen in Windows loeschen?');
      if (!confirmed) return;

      clearAllRoutesBtn.disabled = true;
      try {
        const d = await jsonFetch('/api/audio/route-app/clear-all', { method: 'POST' });
        if (d.success) {
          persistedRouteByPid = new Map();
          appendRouteDebugEntry('ok', `Clear-All erfolgreich (${d.duration_ms || 0} ms).`);
          audioMsg.textContent = 'Alle persistierten App-Routen wurden geloescht.';
          renderUserProgramRoutes();
        } else {
          appendRouteDebugEntry('error', `Clear-All fehlgeschlagen: ${d.message || 'Unbekannter Fehler'}`);
          audioMsg.textContent = `Clear-All fehlgeschlagen: ${d.message || 'Unbekannter Fehler'}`;
        }
      } catch (err) {
        appendRouteDebugEntry('error', `Clear-All Exception: ${err.message}`);
        audioMsg.textContent = `Clear-All Fehler: ${err.message}`;
      } finally {
        clearAllRoutesBtn.disabled = false;
      }
    });
  }

  if (clearRouteDebugBtn) {
    clearRouteDebugBtn.addEventListener('click', () => {
      clearRouteDebugEntries();
      audioMsg.textContent = 'Route-Log geleert.';
    });
  }

  if (routeFallbackBtn) {
    routeFallbackBtn.addEventListener('click', async () => {
      try {
        const d = await jsonFetch('/api/audio/open-routing-settings', { method: 'POST' });
        if (d.success) {
          appendRouteDebugEntry('info', 'Windows Routing als Fallback geoeffnet.');
          audioMsg.textContent = 'Windows Audio-Routing geoeffnet.';
        } else {
          appendRouteDebugEntry('warn', `Windows Routing konnte nicht geoeffnet werden: ${d.message || 'Unbekannter Fehler'}`);
          audioMsg.textContent = `Routing konnte nicht geoeffnet werden: ${d.message || 'Unbekannter Fehler'}`;
        }
      } catch (err) {
        appendRouteDebugEntry('error', `Fallback-Open Fehler: ${err.message}`);
        audioMsg.textContent = `Routing-Fehler: ${err.message}`;
      }
    });
  }

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

    const all = normalizeAllUserRoutes(readUserAudioRoutes());
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
      existing.favoriteDeviceIds = normalizeFavoriteDeviceIds([...(existing.favoriteDeviceIds || []), deviceId]);
      audioMsg.textContent = `Zuordnung gespeichert: ${program} -> ${deviceName}${detectionInfo}.`;
      appendRouteDebugEntry('info', `Zuordnung aktualisiert: ${program} -> ${deviceName}`);
    } else {
      all.push({ program, deviceId, deviceName, favoriteDeviceIds: [deviceId] });
      audioMsg.textContent = `Programm gespeichert: ${program} -> ${deviceName}${detectionInfo}.`;
      appendRouteDebugEntry('info', `Zuordnung angelegt: ${program} -> ${deviceName}`);
    }
    saveUserAudioRoutes(all);
    if (userProgramName) userProgramName.value = '';
    if (openProgramSelect) openProgramSelect.value = '';
    if (userRoutingHint) {
      userRoutingHint.textContent = `Gespeichert fuer ${program}. Bei aktiver Session kannst du mit "Jetzt umschalten" das Per-App Routing direkt anwenden.`;
    }
    renderUserProgramRoutes();
  });

  openRoutingSettingsBtn.addEventListener('click', async () => {
    try {
      const d = await jsonFetch('/api/audio/open-routing-settings', { method: 'POST' });
      if (d.success) {
        appendRouteDebugEntry('info', 'Windows Routing geoeffnet.');
      } else {
        appendRouteDebugEntry('warn', `Windows Routing Fehler: ${d.message || 'Unbekannter Fehler'}`);
      }
      audioMsg.textContent = d.success ? 'Windows Audio-Routing geoeffnet.' : `Routing konnte nicht geoeffnet werden: ${d.message || 'Unbekannter Fehler'}`;
    } catch (err) {
      appendRouteDebugEntry('error', `Windows Routing Exception: ${err.message}`);
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

  const devicesVisibleByUser = cachedAudioDevices.filter((dev) => !hiddenAudioDeviceIds.has(String(dev.id || '')));
  const hiddenByUserCount = Math.max(0, cachedAudioDevices.length - devicesVisibleByUser.length);

  const primaryDevices = [];
  const activeOutputDevice = devicesVisibleByUser.find((dev) => dev.is_active_output) || null;
  const activeInputDevice = devicesVisibleByUser.find((dev) => dev.is_active_input) || null;
  const fallbackInputDevice = activeInputDevice || devicesVisibleByUser.find((dev) => dev.kind === 'input') || null;
  if (activeOutputDevice) primaryDevices.push(activeOutputDevice);
  if (fallbackInputDevice && (!activeOutputDevice || fallbackInputDevice.id !== activeOutputDevice.id)) primaryDevices.push(fallbackInputDevice);
  if (!primaryDevices.length && devicesVisibleByUser[0]) primaryDevices.push(devicesVisibleByUser[0]);

  const primaryIds = new Set(primaryDevices.map((dev) => dev.id));
  const hiddenDevices = devicesVisibleByUser.filter((dev) => !primaryIds.has(dev.id));
  const visibleDevices = showAllAudioDevices ? devicesVisibleByUser : primaryDevices;
  const extraCount = hiddenDevices.length;
  const outputCount = devicesVisibleByUser.filter((dev) => dev.kind === 'output').length;
  const inputCount = devicesVisibleByUser.filter((dev) => dev.kind === 'input').length;
  const activeDevicesCount = primaryDevices.filter((dev) => dev.is_active_output || dev.is_active_input).length;

  if (audioDeviceInfo) {
    if (audioEditMode) {
      const shownText = showAllAudioDevices || extraCount === 0
        ? `${visibleDevices.length} angezeigt`
        : `kompakt: ${activeDevicesCount} aktive Geraete sichtbar, ${extraCount} weitere ausblendbar`;
      const hiddenText = hiddenByUserCount > 0 ? ` | ${hiddenByUserCount} per X ausgeblendet` : '';
      audioDeviceInfo.textContent = `Ausgabe: ${activeOutput || 'Unbekannt'} | Mikrofon: ${activeInput || 'Unbekannt'} | ${devicesVisibleByUser.length} eindeutige Geraete (${outputCount} Output, ${inputCount} Input) | ${shownText}${hiddenText}${routingMessage ? ` | ${routingMessage}` : ''}`;
    } else {
      audioDeviceInfo.textContent = `Ausgabe: ${activeOutput || 'Unbekannt'} | Mikrofon: ${activeInput || 'Unbekannt'}`;
    }
  }

  if (!visibleDevices.length) {
    audioDevices.innerHTML = hiddenByUserCount > 0
      ? '<div class="audio-empty">Alle Audio-Geraete wurden ausgeblendet. Mit "Ausgeblendete anzeigen" kannst du sie wieder einblenden.</div><button class="btn audio-device-unhide" data-audio-device-unhide="all">Ausgeblendete anzeigen</button>'
      : '<div class="audio-empty">Keine Audio-Geraete gefunden.</div>';
    const restoreBtn = audioDevices.querySelector('[data-audio-device-unhide]');
    if (restoreBtn) {
      restoreBtn.addEventListener('click', () => {
        clearHiddenAudioDevices();
        refreshUserProgramDeviceSelect();
        renderUserProgramRoutes();
        renderAudioDevicesList(activeOutput, activeInput, routingMessage);
      });
    }
    scheduleMasonryLayout(audioGrid);
    return;
  }

  const toggleMarkup = audioEditMode && extraCount > 0
    ? `<button class="btn audio-device-toggle" data-audio-device-toggle="${showAllAudioDevices ? 'collapse' : 'expand'}">${showAllAudioDevices ? `Weitere Geraete ausblenden (${extraCount})` : `Weitere Geraete anzeigen (${extraCount})`}</button>`
    : '';
  const unhideMarkup = audioEditMode && hiddenByUserCount > 0
    ? `<button class="btn audio-device-unhide" data-audio-device-unhide="all">Ausgeblendete anzeigen (${hiddenByUserCount})</button>`
    : '';

  audioDevices.innerHTML = `
    ${visibleDevices.map((dev) => `
      <div class="audio-device-item${dev.is_active_output || dev.is_active_input ? ' active' : ''}">
        <span>${dev.name} <small class="muted">${dev.kind === 'input' ? 'Mikrofon' : 'Ausgabe'}</small></span>
        <div class="row">
          ${dev.kind === 'input'
            ? (dev.is_active_input
                ? '<strong>Standard Mikrofon</strong>'
                : (audioEditMode ? `<button class="btn" data-switch-device="${dev.id}" data-switch-name="${dev.name}" data-switch-kind="input">Als Standard</button>` : '<span class="muted">Mikrofon</span>'))
            : (dev.is_active_output
                ? '<strong>Standard Ausgabe</strong>'
                : (audioEditMode ? `<button class="btn" data-switch-device="${dev.id}" data-switch-name="${dev.name}" data-switch-kind="output">Als Standard</button>` : '<span class="muted">Ausgabe</span>'))}
          ${(audioEditMode && !(dev.is_active_output || dev.is_active_input)) ? `<button class="btn audio-device-hide" data-hide-device="${dev.id}" data-hide-name="${dev.name}">x</button>` : ''}
        </div>
      </div>
    `).join('')}
    ${toggleMarkup}
    ${unhideMarkup}
  `;

  audioDevices.querySelectorAll('[data-switch-device]').forEach((btn) => {
    btn.addEventListener('click', async () => {
      const id = btn.dataset.switchDevice || '';
      const name = btn.dataset.switchName || '';
      const kind = btn.dataset.switchKind || 'output';
      await setDefaultAudioDevice(id, name, kind);
    });
  });

  audioDevices.querySelectorAll('[data-hide-device]').forEach((btn) => {
    btn.addEventListener('click', () => {
      const id = btn.dataset.hideDevice || '';
      const name = btn.dataset.hideName || 'Geraet';
      if (!id) return;
      if (!hideAudioDevice(id)) return;
      audioMsg.textContent = `${name} wurde ausgeblendet.`;
      refreshUserProgramDeviceSelect();
      renderUserProgramRoutes();
      renderAudioDevicesList(activeOutput, activeInput, routingMessage);
    });
  });

  const toggleBtn = audioDevices.querySelector('[data-audio-device-toggle]');
  if (toggleBtn) {
    toggleBtn.addEventListener('click', () => {
      showAllAudioDevices = !showAllAudioDevices;
      renderAudioDevicesList(activeOutput, activeInput, routingMessage);
    });
  }

  const restoreBtn = audioDevices.querySelector('[data-audio-device-unhide]');
  if (restoreBtn) {
    restoreBtn.addEventListener('click', () => {
      clearHiddenAudioDevices();
      refreshUserProgramDeviceSelect();
      renderUserProgramRoutes();
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
      const key = `${String(dev.kind || '').trim().toLowerCase()}:${(dev.name || '').trim().toLowerCase()}`;
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
    lastAudioDeviceSummary = {
      activeOutput: d.active_output || '',
      activeInput: d.active_input || '',
      routingMessage: d.routing_message || '',
    };

    // Clean up stale hidden IDs that no longer exist in current device list.
    const currentIds = new Set(cachedAudioDevices.map((dev) => String(dev.id || '')));
    let hiddenChanged = false;
    Array.from(hiddenAudioDeviceIds).forEach((id) => {
      if (!currentIds.has(id)) {
        hiddenAudioDeviceIds.delete(id);
        hiddenChanged = true;
      }
    });
    if (hiddenChanged) saveHiddenAudioDevices();

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
    await refreshPersistedRoutesReadback();

    // Exclude programs that already have a dedicated routing row — they show controls there.
    const routedTokens = new Set(
      normalizeAllUserRoutes(readUserAudioRoutes()).map((r) => normalizeProgramToken(r.program))
    );
    const displaySessions = routedTokens.size
      ? lastAudioSessions.filter((s) => {
          const token = normalizeProgramToken(s.app);
          return !Array.from(routedTokens).some((rp) => token.includes(rp) || rp.includes(token));
        })
      : lastAudioSessions;

    audioSessions.innerHTML = displaySessions.length
      ? displaySessions.map((s) => `
        <div class="audio-session-item" data-pid="${s.pid}">
          <div class="audio-session-head">
            <span>${s.app}</span>
            <span class="muted">${audioEditMode ? `PID ${s.pid} | ${s.device_name || 'Unbekannt'} | ${s.volume}% ${s.muted ? '| Stumm' : ''}` : `${s.volume}% ${s.muted ? '| Stumm' : ''}`}</span>
          </div>
          <div class="row">
            <input type="range" min="0" max="100" value="${s.volume}" data-session-volume="${s.pid}" />
            <button class="btn audio-session-mute-btn" data-session-mute="${s.pid}" data-state="${s.muted ? 0 : 1}" title="${s.muted ? 'Unmute' : 'Mute'}">
              <span class="icon-inline" aria-hidden="true"><svg viewBox="0 0 24 24" focusable="false"><use href="#icon-speaker"></use></svg></span>
            </button>
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
          scheduleRouteSessionRefresh(400);
        } catch (err) {
          audioMsg.textContent = `Session-Volume Fehler: ${err.message}`;
        }
      });
    });

    audioSessions.querySelectorAll('[data-session-mute]').forEach((btn) => {
      btn.addEventListener('click', async () => {
        const pid = parseInt(btn.dataset.sessionMute, 10);
        const state = parseInt(btn.dataset.state, 10) || 0;
        // Optimistic toggle with CSS class
        btn.classList.toggle('is-muted', state === 1);
        btn.dataset.state = state === 1 ? '0' : '1';
        btn.disabled = true;
        try {
          await jsonFetch(`/api/audio/session/${pid}/mute/${state}`, { method: 'POST' });
          scheduleRouteSessionRefresh(350);
        } catch (err) {
          // Revert on failure
          btn.classList.toggle('is-muted', state === 0);
          btn.dataset.state = String(state);
          audioMsg.textContent = `Session-Mute Fehler: ${err.message}`;
        } finally {
          btn.disabled = false;
        }
      });
    });

    renderUserProgramRoutes();
    scheduleMasonryLayout(audioGrid);
  } catch (err) {
    lastAudioSessions = [];
    persistedRouteByPid = new Map();
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

function normalizeGlassStrength(value) {
  const numeric = Number(value);
  if (!Number.isFinite(numeric)) return 40;
  return Math.max(0, Math.min(100, Math.round(numeric)));
}

function loadGlassStrength() {
  try {
    const raw = localStorage.getItem(GLASS_STRENGTH_KEY);
    if (raw == null) return 40;
    return normalizeGlassStrength(raw);
  } catch {
    return 40;
  }
}

function saveGlassStrength(value) {
  try {
    localStorage.setItem(GLASS_STRENGTH_KEY, String(normalizeGlassStrength(value)));
  } catch {
    // ignore storage failures
  }
}

function applyGlassStrength(value) {
  const strength = normalizeGlassStrength(value);
  const root = document.documentElement;

  const t = strength / 100;
  const lerp = (from, to) => from + (to - from) * t;

  const sidebarSolid = Math.round(lerp(96, 22));
  const cardSolid = Math.round(lerp(97, 26));
  const launcherSolid = Math.round(lerp(98, 18));
  const topbarSolid = Math.round(lerp(95, 20));
  const navSolid = Math.round(lerp(96, 28));
  const buttonSolid = Math.round(lerp(96, 34));
  const hoverAccent = Math.round(lerp(6, 24));
  const chipSolid = Math.round(lerp(94, 20));
  const iconSolid = Math.round(lerp(95, 24));

  const blurMain = Math.round(lerp(0, 16));
  const blurStrong = Math.round(lerp(0, 22));
  const blurSoft = Math.round(lerp(0, 14));

  root.style.setProperty('--glass-sidebar-solid', `${sidebarSolid}%`);
  root.style.setProperty('--glass-card-solid', `${cardSolid}%`);
  root.style.setProperty('--glass-launcher-solid', `${launcherSolid}%`);
  root.style.setProperty('--glass-topbar-solid', `${topbarSolid}%`);
  root.style.setProperty('--glass-nav-solid', `${navSolid}%`);
  root.style.setProperty('--glass-button-solid', `${buttonSolid}%`);
  root.style.setProperty('--glass-hover-accent', `${hoverAccent}%`);
  root.style.setProperty('--glass-chip-solid', `${chipSolid}%`);
  root.style.setProperty('--glass-icon-solid', `${iconSolid}%`);
  root.style.setProperty('--glass-blur-main', `${blurMain}px`);
  root.style.setProperty('--glass-blur-strong', `${blurStrong}px`);
  root.style.setProperty('--glass-blur-soft', `${blurSoft}px`);

  if (glassStrengthInput) glassStrengthInput.value = String(strength);
  if (glassStrengthValue) glassStrengthValue.textContent = `${strength}%`;
}

function applyTheme(vars) {
  const root = document.documentElement;
  for (const [prop, val] of Object.entries(vars)) {
    root.style.setProperty(prop, val);
  }
  syncLauncherColorInputsWithThemeDefaults();
  applyGlassStrength(loadGlassStrength());
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

  if (glassStrengthInput) {
    glassStrengthInput.addEventListener('input', () => {
      applyGlassStrength(glassStrengthInput.value);
    });
    glassStrengthInput.addEventListener('change', () => {
      const strength = normalizeGlassStrength(glassStrengthInput.value);
      applyGlassStrength(strength);
      saveGlassStrength(strength);
    });
  }

  applyGlassStrength(loadGlassStrength());

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
  if (toggleLauncherEditModeBtn) toggleLauncherEditModeBtn.onclick = () => setLauncherEditMode(!launcherEditMode);
  if (openLauncherSetupBtn) openLauncherSetupBtn.onclick = () => showPage('setup', { updateUrl: true });
  if (launcherKind) launcherKind.onchange = syncLauncherForm;
  if (launcherCategory) launcherCategory.oninput = () => populateLauncherCategoryHints();
  if (saveLauncherBtn) saveLauncherBtn.onclick = saveLauncher;
  if (saveLauncherPresetBtn) saveLauncherPresetBtn.onclick = saveCurrentLauncherStylePreset;
  if (resetLauncherColorsBtn) resetLauncherColorsBtn.onclick = resetLauncherColorsToThemeDefaults;
  if (resetLauncherFormBtn) resetLauncherFormBtn.onclick = resetLauncherForm;
  document.getElementById('restartBtn').onclick = restartGui;
  const saveDashboardBtn = document.getElementById('saveDashboardBtn');
  if (saveDashboardBtn) {
    saveDashboardBtn.onclick = () => saveDashboardState(layoutMsg);
  }
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
  wireSizeControls(quickstartGrid, QUICKSTART_LAYOUT_KEY);
  wireSizeControls(toolsGrid, TOOLS_LAYOUT_KEY);
  wireSizeControls(setupGrid, SETUP_LAYOUT_KEY);

  applyLayout(readLayout(LAYOUT_KEY), dashboardGrid);
  applyLayout(readLayout(AUDIO_LAYOUT_KEY), audioGrid);
  applyLayout(readLayout(LOGS_LAYOUT_KEY), logsGrid);
  applyLayout(readLayout(QUICKSTART_LAYOUT_KEY), quickstartGrid);
  applyLayout(readLayout(TOOLS_LAYOUT_KEY), toolsGrid);
  applyLayout(readLayout(SETUP_LAYOUT_KEY), setupGrid);

  wirePageMenu();
  wireDragDrop(dashboardGrid, LAYOUT_KEY, renderWidgetMenu);
  wireDragDrop(audioGrid, AUDIO_LAYOUT_KEY);
  wireDragDrop(logsGrid, LOGS_LAYOUT_KEY, renderWidgetMenu);
  wireDragDrop(quickstartGrid, QUICKSTART_LAYOUT_KEY, renderWidgetMenu);
  wireDragDrop(toolsGrid, TOOLS_LAYOUT_KEY, renderWidgetMenu);
  wireDragDrop(setupGrid, SETUP_LAYOUT_KEY, renderWidgetMenu);
  window.addEventListener('resize', queueLayoutReflow);
  installLayoutResizeObserver();
  wireAudioControls();
  wireUserAudioRoutingControls();
  hiddenAudioDeviceIds = new Set(readHiddenAudioDevices());
  audioEditMode = readAudioEditMode();
  if (audioEditModeBtn) {
    audioEditModeBtn.onclick = () => setAudioEditMode(!audioEditMode);
  }
  setAudioEditMode(audioEditMode);
  wireThemeControls();
  wireDashboardColumnControls();

  launcherCategoryLayouts = readLauncherCategoryLayouts();
  launcherCategoryDensity = readLauncherCategoryDensity();
  launcherCategoryOrder = readLauncherCategoryOrder();
  launcherStylePresets = readLauncherStylePresets();
  renderLauncherStylePresets();
  updateLauncherEditModeButton();
  resetLauncherForm();

  try {
    await loadSystem();
  } catch {
    sysInfo.textContent = 'Systeminfo nicht verfuegbar';
  }

  await Promise.all([refreshAll(), refreshGit(), loadLogs(), loadDependencyStatus(), loadDashboardDependencyStatus(), loadTools(), loadLaunchers()]);
  scheduleAllLayoutsMasonry();
  updateScopedRefreshTimers();

  const initialPage = getCurrentPage();
  const initialColumns = getCurrentDashboardColumns(initialPage);
  applyDashboardColumns(initialPage, initialColumns);

  if (typeof console !== 'undefined' && console.log) {
    setTimeout(() => {
      const layoutEls = document.querySelectorAll('.layout');
      if (layoutEls.length > 0) {
        const firstLayout = layoutEls[0];
        const columns = getLayoutColumnCount(firstLayout);
        const cards = getCards(firstLayout);
        console.log(`✓ Responsive Layout aktiv: ${columns} Spalten | ${cards.length} Karten`);
        cards.slice(0, 2).forEach((card) => {
          const span = card.style.gridColumn || card.className.match(/tile-size-\S+/) || 'default';
          console.log(`  └─ ${card.dataset.widget}: ${span}`);
        });
      }
    }, 300);
  }

  // Git-Update-Check: sofort prüfen und danach alle 5 Minuten
  checkGitUpdates().catch(() => {});
  if (gitUpdateCheckTimer) clearInterval(gitUpdateCheckTimer);
  gitUpdateCheckTimer = setInterval(() => checkGitUpdates().catch(() => {}), 5 * 60 * 1000);
}

init();

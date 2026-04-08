const statePill = document.getElementById('state');
const sysInfo = document.getElementById('sysInfo');
const uptime = document.getElementById('uptime');

const cpuPct = document.getElementById('cpuPct');
const ramPct = document.getElementById('ramPct');
const cpuMeta = document.getElementById('cpuMeta');
const ramMeta = document.getElementById('ramMeta');
const netTxtUp = document.getElementById('netTxtUp');
const netTxtDown = document.getElementById('netTxtDown');
const upRateTxt = document.getElementById('upRateTxt');
const downRateTxt = document.getElementById('downRateTxt');
const cpuBar = document.getElementById('cpuBar');
const ramBar = document.getElementById('ramBar');
const gpuName = document.getElementById('gpuName');
const gpuPct = document.getElementById('gpuPct');
const gpuMeta = document.getElementById('gpuMeta');
const gpuBar = document.getElementById('gpuBar');
const cpuChart = document.getElementById('cpuChart');
const gpuChart = document.getElementById('gpuChart');
const ramChart = document.getElementById('ramChart');
const netChart = document.getElementById('netChart');
const upChart = document.getElementById('upChart');
const downChart = document.getElementById('downChart');
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

const dashboardGrid = document.getElementById('dashboardGrid');
const widgetMenu = document.getElementById('widgetMenu');
const layoutMsg = document.getElementById('layoutMsg');

const LAYOUT_KEY = 'bockis_dashboard_layout_v3';
const PAGE_KEY = 'bockis_dashboard_page_v1';
const WIDGET_LABELS = {
  monitoring: 'Monitoring',
  'upload-live': 'Upload (Live)',
  'download-live': 'Download (Live)',
  'data-traffic': 'Datenverkehr',
  disks: 'Festplatten',
  audio: 'Audio',
  processes: 'Prozesse',
};
const SIZE_PRESETS = ['1-3', '1-2', '2-3', 'full', 'min'];

let draggedCard = null;
const HISTORY_LEN = 45;
const monitorHistory = {
  cpu: [],
  gpu: [],
  ram: [],
  net: [],
  upRate: [],
  downRate: [],
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
  const netMax = Math.max(1, ...monitorHistory.net);
  drawSparkline(netChart, monitorHistory.net, netMax, '#ffb25a', 'rgba(255,178,90,0.16)');
  const upMax = Math.max(1, ...monitorHistory.upRate);
  drawSparkline(upChart, monitorHistory.upRate, upMax, '#00d4ff', 'rgba(0,212,255,0.16)');
  const downMax = Math.max(1, ...monitorHistory.downRate);
  drawSparkline(downChart, monitorHistory.downRate, downMax, '#ff6b6b', 'rgba(255,107,107,0.16)');
}

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
    gpus = [];
  }

  cpuPct.textContent = `${m.cpu_pct}%`;
  ramPct.textContent = `${m.ram_pct}%`;
  cpuMeta.textContent = `${m.cpu_freq_mhz ? `${m.cpu_freq_mhz} MHz` : 'Freq n/a'} | ${m.cpu_temp_c != null ? `${m.cpu_temp_c} °C` : 'Temp n/a'}`;
  ramMeta.textContent = `${m.ram_used_gb} / ${m.ram_total_gb} GB | ${m.ram_temp_c != null ? `${m.ram_temp_c} °C` : 'Temp n/a'}`;
  netTxtUp.textContent = `${m.net_sent_mb} MB`;
  netTxtDown.textContent = `${m.net_recv_mb} MB`;
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
  pushHistory('net', netRate);
  pushHistory('upRate', upRate);
  pushHistory('downRate', downRate);
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
    await Promise.all([loadAudioDevices(), loadAudioSessions()]);
  } catch (err) {
    audioMsg.textContent = `Audio-Status Fehler: ${err.message}`;
  }
}

async function loadAudioDevices() {
  try {
    const d = await jsonFetch('/api/audio/devices');
    if (!d.available) {
      audioDeviceInfo.textContent = 'Audio-Geraeteliste nicht verfuegbar.';
      audioDevices.innerHTML = '<div class="audio-empty">Keine Geraete verfuegbar.</div>';
      return;
    }

    audioDeviceInfo.textContent = `Aktives Ausgabegeraet: ${d.active_output || 'Unbekannt'}${d.routing_message ? ` | ${d.routing_message}` : ''}`;
    audioDevices.innerHTML = d.devices.length
      ? d.devices.map((dev) => `<div class="audio-device-item${dev.is_active_output ? ' active' : ''}"><span>${dev.name}</span>${dev.is_active_output ? '<strong>Aktiv</strong>' : ''}</div>`).join('')
      : '<div class="audio-empty">Keine Audio-Geraete gefunden.</div>';
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
      return;
    }

    audioSessions.innerHTML = d.sessions.length
      ? d.sessions.map((s) => `
        <div class="audio-session-item" data-pid="${s.pid}">
          <div class="audio-session-head">
            <span>${s.app}</span>
            <span class="muted">PID ${s.pid} | ${s.volume}% ${s.muted ? '| Stumm' : ''}</span>
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
  } catch (err) {
    audioSessions.innerHTML = `<div class="audio-empty">Session-Fehler: ${err.message}</div>`;
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

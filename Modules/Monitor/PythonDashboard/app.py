from __future__ import annotations

import json
import os
import platform
import subprocess
import tempfile
import time
import ctypes
import sys
import threading
from contextlib import contextmanager
from pathlib import Path

import psutil
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse
from fastapi.staticfiles import StaticFiles

try:
    from ctypes import POINTER, cast
    from comtypes import CLSCTX_ALL
    from pycaw.pycaw import AudioUtilities, IAudioEndpointVolume

    AUDIO_AVAILABLE = True
except Exception:
    POINTER = None
    cast = None
    CLSCTX_ALL = None
    AudioUtilities = None
    IAudioEndpointVolume = None
    AUDIO_AVAILABLE = False


def _ensure_audio_backend() -> bool:
    global AUDIO_AVAILABLE, POINTER, cast, CLSCTX_ALL, AudioUtilities, IAudioEndpointVolume

    if AUDIO_AVAILABLE:
        return True

    try:
        from ctypes import POINTER as _POINTER, cast as _cast
        from comtypes import CLSCTX_ALL as _CLSCTX_ALL
        from pycaw.pycaw import AudioUtilities as _AudioUtilities, IAudioEndpointVolume as _IAudioEndpointVolume

        POINTER = _POINTER
        cast = _cast
        CLSCTX_ALL = _CLSCTX_ALL
        AudioUtilities = _AudioUtilities
        IAudioEndpointVolume = _IAudioEndpointVolume
        AUDIO_AVAILABLE = True
        return True
    except Exception:
        return False


@contextmanager
def _audio_com_context():
    initialized = False
    try:
        ctypes.windll.ole32.CoInitialize(None)
        initialized = True
    except Exception:
        initialized = False

    try:
        yield
    finally:
        if initialized:
            try:
                ctypes.windll.ole32.CoUninitialize()
            except Exception:
                pass

APP_DIR = Path(__file__).resolve().parent
WEB_DIR = APP_DIR / "web"
REPO_ROOT = APP_DIR.parent.parent.parent
LOG_DIR = REPO_ROOT / "Data" / "Logs"

app = FastAPI(title="Bockis Python Dashboard")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

app.mount("/web", StaticFiles(directory=str(WEB_DIR)), name="web")


def _run_git(args: list[str]) -> tuple[int, str]:
    proc = subprocess.run(
        ["git", "-C", str(REPO_ROOT), *args],
        capture_output=True,
        text=True,
        timeout=30,
    )
    output = (proc.stdout or "") + ("\n" + proc.stderr if proc.stderr else "")
    return proc.returncode, output.strip()


def _run_powershell(command: str, timeout: int = 20) -> tuple[int, str]:
    proc = subprocess.run(
        [
            "powershell.exe",
            "-NoProfile",
            "-ExecutionPolicy",
            "Bypass",
            "-Command",
            command,
        ],
        capture_output=True,
        text=True,
        timeout=timeout,
    )
    output = (proc.stdout or "") + ("\n" + proc.stderr if proc.stderr else "")
    return proc.returncode, output.strip()


def _detect_current_port(default_port: int = 9500) -> int:
    env_port = os.environ.get("BOCKIS_DASHBOARD_PORT", "").strip()
    if env_port.isdigit():
        return int(env_port)

    argv = sys.argv or []
    for i, arg in enumerate(argv):
        if arg == "--port" and i + 1 < len(argv) and str(argv[i + 1]).isdigit():
            return int(argv[i + 1])
        if arg.startswith("--port="):
            val = arg.split("=", 1)[1].strip()
            if val.isdigit():
                return int(val)

    return default_port


def request_python_server_restart(delay_s: float = 1.0) -> tuple[bool, str]:
    try:
        port = _detect_current_port(9500)
        python_cmd = sys.executable or "python"
        args = [python_cmd, "-m", "uvicorn", "app:app", "--host", "127.0.0.1", "--port", str(port)]

        creation_flags = 0
        creation_flags |= getattr(subprocess, "CREATE_NEW_PROCESS_GROUP", 0)
        creation_flags |= getattr(subprocess, "DETACHED_PROCESS", 0)
        creation_flags |= getattr(subprocess, "CREATE_NO_WINDOW", 0)

        def _restart_and_exit() -> None:
            try:
                subprocess.Popen(
                    args,
                    cwd=str(APP_DIR),
                    stdout=subprocess.DEVNULL,
                    stderr=subprocess.DEVNULL,
                    creationflags=creation_flags,
                )
            finally:
                os._exit(0)

        timer = threading.Timer(delay_s, _restart_and_exit)
        timer.daemon = True
        timer.start()
        return True, f"Restart auf Port {port} geplant"
    except Exception as exc:
        return False, str(exc)


def _get_cpu_temp_c() -> float | None:
    # psutil does not expose sensors on many Windows installs/builds.
    # Keep psutil as primary source when available, then fall back to PowerShell.
    try:
        sensor_reader = getattr(psutil, "sensors_temperatures", None)
        if callable(sensor_reader):
            temps = sensor_reader()
            if temps:
                preferred_keys = ("coretemp", "k10temp", "cpu_thermal", "acpitz")
                for key in preferred_keys:
                    entries = temps.get(key)
                    if entries:
                        values = [e.current for e in entries if getattr(e, "current", None) is not None]
                        if values:
                            return round(sum(values) / len(values), 1)

                for entries in temps.values():
                    values = [e.current for e in entries if getattr(e, "current", None) is not None]
                    if values:
                        return round(sum(values) / len(values), 1)
    except Exception:
        pass

    # Windows fallback chain:
    # 1) LibreHardwareMonitor WMI namespace
    # 2) OpenHardwareMonitor WMI namespace
    # 3) ACPI thermal zone (often generic/mainboard, but better than nothing)
    ps_cmd = (
        "$vals=@();"
        "function Add-Temps($items){ if($items){ $script:vals += $items } };"
        "try {"
        "  Add-Temps (Get-CimInstance -Namespace root/LibreHardwareMonitor -ClassName Sensor -ErrorAction Stop |"
        "    Where-Object { $_.SensorType -eq 'Temperature' -and ($_.Name -match 'CPU|Tdie|Package') } |"
        "    Select-Object -ExpandProperty Value)"
        "} catch {}"
        "try {"
        "  Add-Temps (Get-CimInstance -Namespace root/OpenHardwareMonitor -ClassName Sensor -ErrorAction Stop |"
        "    Where-Object { $_.SensorType -eq 'Temperature' -and ($_.Name -match 'CPU|Tdie|Package') } |"
        "    Select-Object -ExpandProperty Value)"
        "} catch {}"
        "if(-not $vals -or $vals.Count -eq 0){"
        "  try {"
        "    Add-Temps (Get-CimInstance -ClassName MSAcpi_ThermalZoneTemperature -Namespace root/wmi -ErrorAction Stop |"
        "      ForEach-Object { ([double]$_.CurrentTemperature / 10.0) - 273.15 })"
        "  } catch {}"
        "}"
        "$vals = $vals | Where-Object { $_ -ne $null -and $_ -gt 0 -and $_ -lt 140 };"
        "if($vals -and $vals.Count -gt 0){ [math]::Round((($vals | Measure-Object -Average).Average),1) }"
    )
    rc, out = _run_powershell(ps_cmd, timeout=8)
    if rc == 0 and out.strip():
        for line in reversed(out.splitlines()):
            candidate = line.strip().replace(",", ".")
            if not candidate:
                continue
            try:
                return float(candidate)
            except Exception:
                continue

    return None


def get_metrics() -> dict:
    net = psutil.net_io_counters()
    mem = psutil.virtual_memory()
    freq = psutil.cpu_freq()
    cpu_temp = _get_cpu_temp_c()
    return {
        "cpu_pct": round(psutil.cpu_percent(interval=0.2), 1),
        "cpu_freq_mhz": round(freq.current, 1) if freq else None,
        "cpu_temp_c": cpu_temp,
        "ram_pct": round(mem.percent, 1),
        "ram_used_gb": round(mem.used / 1e9, 2),
        "ram_total_gb": round(mem.total / 1e9, 2),
        "ram_temp_c": None,
        "net_sent_mb": round(net.bytes_sent / 1e6, 1),
        "net_recv_mb": round(net.bytes_recv / 1e6, 1),
        "uptime_s": int(time.time() - psutil.boot_time()),
    }


def get_disks() -> list[dict]:
    disks: list[dict] = []
    for part in psutil.disk_partitions(all=False):
        if "cdrom" in part.opts.lower() or not part.fstype:
            continue
        try:
            usage = psutil.disk_usage(part.mountpoint)
            disks.append(
                {
                    "device": part.device,
                    "mountpoint": part.mountpoint,
                    "fstype": part.fstype,
                    "used_gb": round(usage.used / 1e9, 1),
                    "total_gb": round(usage.total / 1e9, 1),
                    "percent": round(usage.percent, 1),
                }
            )
        except OSError:
            continue
    return disks


def get_gpu_metrics() -> list[dict]:
    """Returns GPU info via nvidia-smi (NVIDIA) or WMI fallback (AMD/Intel)."""
    gpus: list[dict] = []

    # --- NVIDIA via nvidia-smi ---
    try:
        proc = subprocess.run(
            ["nvidia-smi", "--query-gpu=index,name,utilization.gpu,memory.used,memory.total,temperature.gpu",
             "--format=csv,noheader,nounits"],
            capture_output=True, text=True, timeout=5,
        )
        if proc.returncode == 0:
            for line in proc.stdout.strip().splitlines():
                parts = [p.strip() for p in line.split(",")]
                if len(parts) >= 6:
                    gpus.append({
                        "index": int(parts[0]),
                        "name": parts[1],
                        "usage_pct": int(parts[2]) if parts[2].lstrip('-').isdigit() else None,
                        "vram_used_mb": int(parts[3]) if parts[3].lstrip('-').isdigit() else None,
                        "vram_total_mb": int(parts[4]) if parts[4].lstrip('-').isdigit() else None,
                        "temp_c": int(parts[5]) if parts[5].lstrip('-').isdigit() else None,
                        "source": "nvidia-smi",
                    })
    except Exception:
        pass

    # --- WMI fallback for AMD/Intel (name + VRAM only) ---
    if not gpus:
        rc, out = _run_powershell(
            "$gpus = Get-CimInstance Win32_VideoController | "
            "Where-Object { $_.AdapterRAM -gt 0 } | "
            "Select-Object @{n='Name';e={$_.Name}},@{n='VRAM_MB';e={[int]($_.AdapterRAM/1MB)}}; "
            "$gpus | ConvertTo-Json -Compress"
        )
        if rc == 0 and out.strip():
            try:
                data = json.loads(out.strip())
                if isinstance(data, dict):
                    data = [data]
                for i, g in enumerate(data):
                    gpus.append({
                        "index": i,
                        "name": g.get("Name", "Unknown GPU"),
                        "usage_pct": None,
                        "vram_used_mb": None,
                        "vram_total_mb": g.get("VRAM_MB"),
                        "temp_c": None,
                        "source": "wmi",
                    })
            except Exception:
                pass

    return gpus


def get_processes(top: int = 10) -> list[dict]:
    items: list[dict] = []
    for proc in psutil.process_iter(["pid", "name", "cpu_percent", "memory_info"]):
        try:
            info = proc.info
            items.append(
                {
                    "pid": info["pid"],
                    "name": info["name"] or "unknown",
                    "cpu": round(info["cpu_percent"] or 0.0, 1),
                    "mem_mb": round((info["memory_info"].rss if info["memory_info"] else 0) / 1e6, 1),
                }
            )
        except (psutil.NoSuchProcess, psutil.AccessDenied):
            continue
    return sorted(items, key=lambda x: x["cpu"], reverse=True)[:top]


SYSTEM_PROCESS_NAMES = {
    "system idle process",
    "system",
    "registry",
    "smss.exe",
    "csrss.exe",
    "wininit.exe",
    "services.exe",
    "lsass.exe",
    "svchost.exe",
    "fontdrvhost.exe",
    "dwm.exe",
    "sihost.exe",
    "taskhostw.exe",
    "conhost.exe",
    "searchindexer.exe",
    "wudfhost.exe",
}


def get_open_programs(limit: int = 300) -> list[str]:
    names: list[str] = []
    seen: set[str] = set()

    for proc in psutil.process_iter(["name"]):
        try:
            name = str(proc.info.get("name") or "").strip()
            if not name:
                continue

            low = name.lower()
            if low in SYSTEM_PROCESS_NAMES:
                continue

            if low.startswith(("svchost", "fontdrvhost", "conhost")):
                continue

            if low not in seen:
                seen.add(low)
                names.append(name)
        except (psutil.NoSuchProcess, psutil.AccessDenied):
            continue

    names.sort(key=lambda x: x.lower())
    safe_limit = max(10, min(int(limit or 300), 1000))
    return names[:safe_limit]


def get_git_status() -> dict:
    if not shutil_which("git"):
        return {
            "available": False,
            "message": "Git nicht gefunden",
        }

    rc, inside = _run_git(["rev-parse", "--is-inside-work-tree"])
    if rc != 0 or "true" not in inside:
        return {"available": False, "message": "Kein Git-Repository"}

    _, branch = _run_git(["rev-parse", "--abbrev-ref", "HEAD"])
    _, upstream = _run_git(["rev-parse", "--abbrev-ref", "--symbolic-full-name", "@{u}"])
    _, dirty = _run_git(["status", "--porcelain"])

    ahead = 0
    behind = 0
    if upstream and "fatal:" not in upstream.lower():
        _, count = _run_git(["rev-list", "--left-right", "--count", f"{branch}...{upstream}"])
        parts = count.strip().split()
        if len(parts) == 2:
            ahead = int(parts[0])
            behind = int(parts[1])

    return {
        "available": True,
        "branch": branch.strip() or "-",
        "upstream": upstream.strip() if upstream and "fatal:" not in upstream.lower() else "-",
        "ahead": ahead,
        "behind": behind,
        "dirty_count": len([line for line in dirty.splitlines() if line.strip()]),
    }


def shutil_which(binary: str) -> str | None:
    rc, out = _run_powershell(f"(Get-Command {binary} -ErrorAction SilentlyContinue).Path")
    if rc == 0 and out.strip():
        return out.strip()
    return None


TOOL_COMMANDS: dict[str, str] = {
    "windows_update": "Start-Process 'ms-settings:windowsupdate'",
    "defender": "Start-Process 'windowsdefender:'",
    "services": "Start-Process 'services.msc'",
    "event_viewer": "Start-Process 'eventvwr.msc'",
    "task_manager": "Start-Process 'taskmgr.exe'",
    "disk_cleanup": "Start-Process 'cleanmgr.exe'",
}

MEDIA_KEY_MAP: dict[str, int] = {
    "play_pause": 0xB3,
    "next": 0xB0,
    "prev": 0xB1,
    "stop": 0xB2,
    "vol_up": 0xAF,
    "vol_down": 0xAE,
    "mute": 0xAD,
}


def _audio_obj():
    if not _ensure_audio_backend():
        return None
    try:
        dev = AudioUtilities.GetSpeakers()
        endpoint = getattr(dev, "EndpointVolume", None)
        if endpoint is not None:
            return endpoint

        iface = dev.Activate(IAudioEndpointVolume._iid_, CLSCTX_ALL, None)
        return cast(iface, POINTER(IAudioEndpointVolume))
    except Exception:
        return None


def get_audio_status() -> dict:
    with _audio_com_context():
        vol = _audio_obj()
        if not vol:
            return {"available": False, "level": 0, "muted": False}
        try:
            level = int(round(vol.GetMasterVolumeLevelScalar() * 100))
            return {"available": True, "level": max(0, min(100, level)), "muted": bool(vol.GetMute())}
        except Exception:
            return {"available": False, "level": 0, "muted": False}


def get_audio_devices() -> dict:
    if not _ensure_audio_backend():
        return {"available": False, "active_output": None, "devices": []}

    devices: list[dict] = []
    dedup_by_name: dict[str, dict] = {}
    active_output = None
    active_output_id = None

    with _audio_com_context():
        try:
            active = AudioUtilities.GetSpeakers()
            active_output = getattr(active, "FriendlyName", None)
            active_output_id = getattr(active, "id", None) or getattr(active, "Id", None)
        except Exception:
            active_output = None
            active_output_id = None

        try:
            all_devices = AudioUtilities.GetAllDevices()
            for d in all_devices:
                state = getattr(d, "state", None)
                name = getattr(d, "FriendlyName", None) or getattr(d, "DeviceFriendlyName", None) or "Unknown"
                dev_id = getattr(d, "id", None) or getattr(d, "Id", None) or name

                state_str = str(state)
                is_active_state = (
                    state is None
                    or state_str.endswith(".Active")
                    or state_str == "1"
                    or state_str.lower() == "active"
                )
                if not is_active_state:
                    continue

                # In pycaw IDs, {0.0.0...} = render/output, {0.0.1...} = capture/input.
                # UI expects playback devices only.
                dev_id_str = str(dev_id)
                if not dev_id_str.startswith("{0.0.0."):
                    continue

                is_active = bool(
                    (active_output_id and str(dev_id) == str(active_output_id))
                    or (active_output and str(name) == str(active_output))
                )

                entry = {
                    "id": str(dev_id),
                    "name": str(name),
                    "is_active_output": is_active,
                }

                key = str(name).strip().lower()
                existing = dedup_by_name.get(key)
                if existing is None:
                    dedup_by_name[key] = entry
                elif is_active and not existing.get("is_active_output"):
                    # Prefer the active endpoint if same friendly name appears multiple times.
                    dedup_by_name[key] = entry
        except Exception:
            pass

    devices = list(dedup_by_name.values())
    devices.sort(key=lambda x: (not x["is_active_output"], x["name"].lower()))

    return {"available": True, "active_output": active_output, "devices": devices}


def _iter_audio_sessions() -> list:
    if not _ensure_audio_backend():
        return []
    try:
        return list(AudioUtilities.GetAllSessions())
    except Exception:
        return []


def get_audio_sessions() -> dict:
    if not _ensure_audio_backend():
        return {"available": False, "sessions": []}

    result: list[dict] = []
    with _audio_com_context():
        for sess in _iter_audio_sessions():
            try:
                pid = int(getattr(sess, "ProcessId", 0) or 0)
                proc = getattr(sess, "Process", None)
                app = proc.name() if proc else "System Sounds"
                vol_obj = sess.SimpleAudioVolume
                vol = int(round(vol_obj.GetMasterVolume() * 100))
                muted = bool(vol_obj.GetMute())
                result.append(
                    {
                        "pid": pid,
                        "app": app,
                        "volume": max(0, min(100, vol)),
                        "muted": muted,
                    }
                )
            except Exception:
                continue

    result = sorted(result, key=lambda x: (x["app"].lower(), x["pid"]))
    return {"available": True, "sessions": result}


def set_audio_session_volume(pid: int, level: int) -> bool:
    if not _ensure_audio_backend():
        return False

    target = max(0.0, min(1.0, level / 100.0))
    changed = False
    with _audio_com_context():
        for sess in _iter_audio_sessions():
            try:
                session_pid = int(getattr(sess, "ProcessId", 0) or 0)
                if session_pid != pid:
                    continue
                sess.SimpleAudioVolume.SetMasterVolume(target, None)
                changed = True
            except Exception:
                continue
    return changed


def set_audio_session_mute(pid: int, muted: bool) -> bool:
    if not _ensure_audio_backend():
        return False

    changed = False
    with _audio_com_context():
        for sess in _iter_audio_sessions():
            try:
                session_pid = int(getattr(sess, "ProcessId", 0) or 0)
                if session_pid != pid:
                    continue
                sess.SimpleAudioVolume.SetMute(1 if muted else 0, None)
                changed = True
            except Exception:
                continue
    return changed


def set_audio_volume(level: int) -> bool:
    with _audio_com_context():
        vol = _audio_obj()
        if not vol:
            return False
        try:
            vol.SetMasterVolumeLevelScalar(max(0.0, min(1.0, level / 100.0)), None)
            return True
        except Exception:
            return False


def set_audio_mute(muted: bool) -> bool:
    with _audio_com_context():
        vol = _audio_obj()
        if not vol:
            return False
        try:
            vol.SetMute(1 if muted else 0, None)
            return True
        except Exception:
            return False


def send_media_key(action: str) -> bool:
    vk = MEDIA_KEY_MAP.get(action)
    if not vk:
        return False
    keyup = 0x0002
    ext = 0x0001
    try:
        ctypes.windll.user32.keybd_event(vk, 0, ext, 0)
        ctypes.windll.user32.keybd_event(vk, 0, ext | keyup, 0)
        return True
    except Exception:
        return False


@app.get("/")
def index() -> FileResponse:
    return FileResponse(WEB_DIR / "index.html")


@app.get("/api/health")
def health() -> dict:
    return {"ok": True, "service": "python-dashboard"}


@app.get("/api/system")
def system_info() -> dict:
    return {
        "hostname": platform.node(),
        "os": f"{platform.system()} {platform.release()}",
        "cpu": platform.processor() or "Unknown",
        "python": platform.python_version(),
    }


@app.get("/api/gpu")
def api_gpu() -> list[dict]:
    return get_gpu_metrics()


@app.get("/api/metrics")
def api_metrics() -> dict:
    return get_metrics()


@app.get("/api/disks")
def api_disks() -> list[dict]:
    return get_disks()


@app.get("/api/processes")
def api_processes(top: int = 10) -> list[dict]:
    return get_processes(top)


@app.get("/api/audio")
def api_audio() -> dict:
    return get_audio_status()


@app.post("/api/audio/volume/{level}")
def api_audio_volume(level: int) -> dict:
    ok = set_audio_volume(level)
    st = get_audio_status()
    return {"success": ok, "status": st}


@app.post("/api/audio/mute/{state}")
def api_audio_mute(state: int) -> dict:
    ok = set_audio_mute(bool(state))
    st = get_audio_status()
    return {"success": ok, "status": st}


@app.post("/api/audio/media/{action}")
def api_audio_media(action: str) -> dict:
    ok = send_media_key(action)
    return {"success": ok, "action": action}


@app.post("/api/audio/open-routing-settings")
def api_audio_open_routing_settings() -> dict:
    rc, out = _run_powershell("Start-Process 'ms-settings:apps-volume'", timeout=10)
    return {
        "success": rc == 0,
        "message": "Windows Audio-Routing geoeffnet." if rc == 0 else "Audio-Routing konnte nicht geoeffnet werden.",
        "output": out,
    }


@app.get("/api/audio/devices")
def api_audio_devices() -> dict:
    devices = get_audio_devices()
    devices["routing_supported"] = False
    devices["routing_message"] = "App-zu-Device-Zuweisung ist in dieser Version noch nicht direkt verfuegbar."
    return devices


@app.get("/api/audio/sessions")
def api_audio_sessions() -> dict:
    return get_audio_sessions()


@app.get("/api/audio/open-programs")
def api_audio_open_programs(limit: int = 300) -> dict:
    try:
        return {"available": True, "programs": get_open_programs(limit)}
    except Exception as ex:
        return {"available": False, "programs": [], "message": str(ex)}


@app.post("/api/audio/session/{pid}/volume/{level}")
def api_audio_session_volume(pid: int, level: int) -> dict:
    ok = set_audio_session_volume(pid, level)
    return {"success": ok, "pid": pid, "level": max(0, min(100, level))}


@app.post("/api/audio/session/{pid}/mute/{state}")
def api_audio_session_mute(pid: int, state: int) -> dict:
    ok = set_audio_session_mute(pid, bool(state))
    return {"success": ok, "pid": pid, "muted": bool(state)}


@app.get("/api/logs")
def api_logs() -> list[str]:
    if not LOG_DIR.exists():
        return []
    return sorted([p.name for p in LOG_DIR.glob("*.log")], reverse=True)


@app.get("/api/logs/content")
def api_log_content(file: str, lines: int = 300) -> dict:
    target = (LOG_DIR / file).resolve()
    if not str(target).startswith(str(LOG_DIR.resolve())):
        raise HTTPException(status_code=400, detail="Ungultiger Dateiname")
    if not target.exists() or not target.is_file():
        raise HTTPException(status_code=404, detail="Datei nicht gefunden")

    data = target.read_text(encoding="utf-8", errors="replace").splitlines()
    tail = data[-max(1, min(lines, 3000)) :]
    return {"file": file, "content": "\n".join(tail)}


@app.get("/api/git/status")
def api_git_status() -> dict:
    return get_git_status()


@app.post("/api/git/pull")
def api_git_pull(payload: dict | None = None) -> dict:
    status = get_git_status()
    if not status.get("available"):
        return {"success": False, "message": status.get("message", "Git nicht verfugbar")}

    remote = (payload or {}).get("remote") or "origin"
    branch = (payload or {}).get("branch") or status.get("branch", "main")

    before_rc, before_head = _run_git(["rev-parse", "HEAD"])
    before_head = before_head.strip() if before_rc == 0 else ""

    rc, out = _run_git(["pull", "--ff-only", "--autostash", remote, branch])
    if rc == 0:
        after_rc, after_head = _run_git(["rev-parse", "HEAD"])
        after_head = after_head.strip() if after_rc == 0 else ""
        updated = bool(before_head and after_head and before_head != after_head)

        pulled_commits = 0
        if updated:
            cnt_rc, cnt_out = _run_git(["rev-list", "--count", f"{before_head}..{after_head}"])
            if cnt_rc == 0 and cnt_out.strip().isdigit():
                pulled_commits = int(cnt_out.strip())

        restarting = False
        restart_info = ""
        if updated:
            restarting, restart_info = request_python_server_restart()

        if updated:
            msg = (
                f"Pull erfolgreich: {pulled_commits} Commit(s) geladen. Python-Dashboard wird neu gestartet."
                if restarting
                else f"Pull erfolgreich: {pulled_commits} Commit(s) geladen. Auto-Neustart fehlgeschlagen."
            )
        else:
            msg = "Keine neuen Updates gefunden (Already up to date)."

        return {
            "success": True,
            "message": msg,
            "output": out,
            "restarting": restarting,
            "restart_info": restart_info,
            "updated": updated,
            "pulled_commits": pulled_commits,
            "before_head": before_head,
            "after_head": after_head,
        }

    return {
        "success": False,
        "message": "Pull fehlgeschlagen",
        "output": out,
        "restarting": False,
        "before_head": before_head,
    }


@app.get("/api/tools")
def api_tools() -> list[dict]:
    return [
        {"id": "windows_update", "label": "Windows Update"},
        {"id": "defender", "label": "Windows Defender"},
        {"id": "services", "label": "Services"},
        {"id": "event_viewer", "label": "Event Viewer"},
        {"id": "task_manager", "label": "Task Manager"},
        {"id": "disk_cleanup", "label": "Disk Cleanup"},
    ]


@app.post("/api/tools/run/{tool_id}")
def api_run_tool(tool_id: str) -> dict:
    cmd = TOOL_COMMANDS.get(tool_id)
    if not cmd:
        return {"success": False, "message": "Unbekanntes Tool"}

    rc, out = _run_powershell(cmd, timeout=15)
    return {
        "success": rc == 0,
        "message": "Tool gestartet" if rc == 0 else "Tool konnte nicht gestartet werden",
        "output": out,
    }


@app.post("/api/restart")
def api_restart() -> dict:
    flag_path = Path(tempfile.gettempdir()) / "bockis_restart.flag"
    try:
        flag_path.write_text("restart", encoding="utf-8")
    except OSError as exc:
        return {"success": False, "message": f"Flag-Datei konnte nicht geschrieben werden: {exc}"}

    script_path = REPO_ROOT / "Win_Gui_Module.ps1"
    if script_path.exists():
        subprocess.Popen(
            [
                "powershell.exe",
                "-ExecutionPolicy",
                "Bypass",
                "-File",
                str(script_path),
            ],
            creationflags=subprocess.CREATE_NEW_CONSOLE,
        )

    return {"success": True, "message": "Neustart wird ausgefuehrt."}

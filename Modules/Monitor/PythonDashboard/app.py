from __future__ import annotations

import json
import os
import platform
import re
import subprocess
import tempfile
import time
import ctypes
import sys
import threading
from importlib import metadata as importlib_metadata
from contextlib import contextmanager
from pathlib import Path

import psutil
from fastapi import FastAPI, HTTPException
from time import time as current_time
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse
from fastapi.staticfiles import StaticFiles

try:
    from ctypes import POINTER, cast
    from comtypes import CLSCTX_ALL
    from pycaw.pycaw import AudioSession, AudioUtilities, IAudioEndpointVolume, IAudioSessionControl2

    AUDIO_AVAILABLE = True
except Exception:
    POINTER = None
    cast = None
    CLSCTX_ALL = None
    AudioSession = None
    AudioUtilities = None
    IAudioEndpointVolume = None
    IAudioSessionControl2 = None
    AUDIO_AVAILABLE = False


def _ensure_audio_backend() -> bool:
    global AUDIO_AVAILABLE, POINTER, cast, CLSCTX_ALL, AudioSession, AudioUtilities, IAudioEndpointVolume, IAudioSessionControl2

    if AUDIO_AVAILABLE:
        return True

    try:
        from ctypes import POINTER as _POINTER, cast as _cast
        from comtypes import CLSCTX_ALL as _CLSCTX_ALL
        from pycaw.pycaw import AudioSession as _AudioSession, AudioUtilities as _AudioUtilities, IAudioEndpointVolume as _IAudioEndpointVolume, IAudioSessionControl2 as _IAudioSessionControl2

        POINTER = _POINTER
        cast = _cast
        CLSCTX_ALL = _CLSCTX_ALL
        AudioSession = _AudioSession
        AudioUtilities = _AudioUtilities
        IAudioEndpointVolume = _IAudioEndpointVolume
        IAudioSessionControl2 = _IAudioSessionControl2
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
DASHBOARD_REQUIREMENTS = APP_DIR / "requirements.txt"
CUSTOM_LAUNCHERS_FILE = REPO_ROOT / "Data" / "dashboard_launchers.json"

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


# Cache for God Mode window state to avoid repeated expensive COM queries
_god_mode_cache: dict[str, tuple[float, bool]] = {}
_god_mode_cache_lock = threading.Lock()

# Keep expensive availability checks away from hot polling path.
_tool_availability_cache: dict[str, tuple[float, tuple[bool, str]]] = {}
_tool_availability_cache_lock = threading.Lock()
_tool_availability_ttl_sec = 20.0

# `/api/tools/state` is polled frequently by the frontend; cache short-term.
_tool_state_cache: dict[str, object] = {"ts": 0.0, "payload": None}
_tool_state_cache_lock = threading.Lock()
_tool_state_ttl_sec = 1.2

def _get_god_mode_cached(cache_key: str, func, timeout_sec: float = 0.5) -> bool:
    """Get cached God Mode state or compute fresh if cache expired."""
    current = current_time()
    with _god_mode_cache_lock:
        if cache_key in _god_mode_cache:
            cache_time, cached_val = _god_mode_cache[cache_key]
            if current - cache_time < timeout_sec:
                return cached_val
        result = func()
        _god_mode_cache[cache_key] = (current, result)
        return result


def _run_powershell(command: str, timeout: int = 8) -> tuple[int, str]:
    # UTF-8-BOM: PowerShell emits BOM so the decoder can identify encoding unambiguously.
    # Python's 'utf-8-sig' codec strips the BOM transparently and handles plain UTF-8 too.
    cmd_bom = (
        "$OutputEncoding = [Console]::InputEncoding = [Console]::OutputEncoding"
        " = [System.Text.UTF8Encoding]::new($true); "  # $true = emit BOM
        + command
    )
    proc = subprocess.run(
        [
            "powershell.exe",
            "-NoProfile",
            "-ExecutionPolicy",
            "Bypass",
            "-Command",
            cmd_bom,
        ],
        capture_output=True,
        encoding="utf-8-sig",  # strips BOM if present, reads plain UTF-8 if not
        errors="replace",
        timeout=timeout,
    )
    output = (proc.stdout or "") + ("\n" + proc.stderr if proc.stderr else "")
    return proc.returncode, output.strip()


def _extract_json_output(output: str) -> dict:
    text = (output or "").strip()
    if not text:
        return {}

    for candidate in [text, *reversed(text.splitlines())]:
        candidate = candidate.strip()
        if not candidate:
            continue
        try:
            return json.loads(candidate)
        except Exception:
            continue
    return {}


def _parse_requirement_line(line: str) -> dict | None:
    raw = str(line or "").strip()
    if not raw or raw.startswith("#"):
        return None

    match = re.match(r"^([A-Za-z0-9_.-]+)(?:\[[^\]]+\])?\s*(==|>=|<=|>|<)?\s*([^;#\s]+)?", raw)
    if not match:
        return None

    package_name, operator, version = match.groups()
    return {
        "package": package_name,
        "operator": operator or None,
        "required_version": version or None,
        "raw": raw,
    }


def _version_tuple(version: str | None) -> tuple[int, ...]:
    if not version:
        return tuple()
    return tuple(int(x) for x in re.findall(r"\d+", str(version)))


def _compare_versions(installed: str | None, required: str | None, operator: str | None) -> bool:
    if not operator or not required:
        return installed is not None
    if installed is None:
        return False

    left = _version_tuple(installed)
    right = _version_tuple(required)
    width = max(len(left), len(right))
    left = left + (0,) * (width - len(left))
    right = right + (0,) * (width - len(right))

    if operator == "==":
        return left == right
    if operator == ">=":
        return left >= right
    if operator == "<=":
        return left <= right
    if operator == ">":
        return left > right
    if operator == "<":
        return left < right
    return False


def get_dashboard_dependency_status() -> dict:
    python_ok = sys.version_info >= (3, 10)
    dependencies: list[dict] = [
        {
            "name": "Python",
            "required": ">=3.10",
            "installed_version": platform.python_version(),
            "status": "OK" if python_ok else "Zu alt",
            "status_color": "green" if python_ok else "red",
            "found": True,
            "satisfied": python_ok,
            "source": "runtime",
        }
    ]

    if not DASHBOARD_REQUIREMENTS.exists():
        return {
            "available": False,
            "message": f"requirements.txt nicht gefunden: {DASHBOARD_REQUIREMENTS}",
            "requirements_path": str(DASHBOARD_REQUIREMENTS),
            "python_version": platform.python_version(),
            "dependencies": dependencies,
            "all_satisfied": False,
            "missing_count": 0,
            "outdated_count": 0,
        }

    missing_count = 0
    outdated_count = 0

    for line in DASHBOARD_REQUIREMENTS.read_text(encoding="utf-8", errors="replace").splitlines():
        req = _parse_requirement_line(line)
        if not req:
            continue

        installed_version = None
        found = False
        try:
            installed_version = importlib_metadata.version(req["package"])
            found = True
        except importlib_metadata.PackageNotFoundError:
            found = False
        except Exception:
            found = False

        satisfied = found and _compare_versions(installed_version, req["required_version"], req["operator"])
        if not found:
            missing_count += 1
            status = "Fehlt"
            status_color = "red"
        elif not satisfied:
            outdated_count += 1
            status = "Version abweichend"
            status_color = "yellow"
        else:
            status = "OK"
            status_color = "green"

        required_text = f"{req['operator'] or ''}{req['required_version'] or ''}".strip() or "installiert"
        dependencies.append(
            {
                "name": req["package"],
                "required": required_text,
                "installed_version": installed_version,
                "status": status,
                "status_color": status_color,
                "found": found,
                "satisfied": satisfied,
                "source": req["raw"],
            }
        )

    return {
        "available": True,
        "message": "Dashboard-Dependencies geladen.",
        "requirements_path": str(DASHBOARD_REQUIREMENTS),
        "python_version": platform.python_version(),
        "dependencies": dependencies,
        "all_satisfied": python_ok and missing_count == 0 and outdated_count == 0,
        "missing_count": missing_count,
        "outdated_count": outdated_count,
    }


def get_dependency_status() -> dict:
    dep_module = REPO_ROOT / "Modules" / "Core" / "DependencyChecker.psm1"
    if not dep_module.exists():
        return {"available": False, "message": f"DependencyChecker nicht gefunden: {dep_module}", "dependencies": []}

    ps_script = f"""
$ErrorActionPreference = 'Stop'
$WarningPreference = 'SilentlyContinue'
$VerbosePreference = 'SilentlyContinue'
Import-Module {_ps_quote(str(dep_module))} -Force
$result = Get-DependencyStatusForGUI -CurrentVersion '4.2.1' -RepoOwner 'ReXx09' -RepoName 'Bockis-Win_Gui-Release'
$result | ConvertTo-Json -Depth 8 -Compress
"""
    rc, out = _run_powershell(ps_script, timeout=120)
    parsed = _extract_json_output(out)
    if rc != 0 or not parsed:
        return {
            "available": False,
            "message": out or "DependencyChecker konnte nicht ausgeführt werden.",
            "dependencies": [],
        }

    return {
        "available": True,
        "message": "Dependency-Status geladen.",
        "dependencies": parsed.get("Dependencies", []),
        "all_satisfied": bool(parsed.get("AllSatisfied", False)),
        "has_installable_items": bool(parsed.get("HasInstallableItems", False)),
    }


def run_dependency_action(winget_id: str, action: str) -> dict:
    dep_module = REPO_ROOT / "Modules" / "Core" / "DependencyChecker.psm1"
    if not dep_module.exists():
        return {"success": False, "message": f"DependencyChecker nicht gefunden: {dep_module}"}

    safe_action = action if action in {"install", "upgrade"} else "install"
    ps_script = f"""
$ErrorActionPreference = 'Stop'
$WarningPreference = 'SilentlyContinue'
$VerbosePreference = 'SilentlyContinue'
Import-Module {_ps_quote(str(dep_module))} -Force
$result = Invoke-DependencyAction -WingetId {_ps_quote(winget_id)} -Action {safe_action}
$result | ConvertTo-Json -Depth 6 -Compress
"""
    rc, out = _run_powershell(ps_script, timeout=1800)
    parsed = _extract_json_output(out)

    if parsed:
        return {
            "success": bool(parsed.get("Success", False)),
            "message": parsed.get("ErrorMessage") or ("Aktion erfolgreich" if parsed.get("Success") else "Aktion fehlgeschlagen"),
            "exit_code": parsed.get("ExitCode"),
            "output": out,
        }

    return {
        "success": rc == 0,
        "message": out or "Dependency-Aktion fehlgeschlagen",
        "exit_code": rc,
        "output": out,
    }


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
    rc, out = _run_powershell(ps_cmd, timeout=3)
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
    # Existing tools
    "windows_update": "Start-Process 'ms-settings:windowsupdate'",
    "defender": "Start-Process 'windowsdefender:'",
    "services": "Start-Process 'services.msc'",
    "event_viewer": "Start-Process 'eventvwr.msc'",
    "task_manager": "Start-Process 'taskmgr.exe'",
    "disk_cleanup": "Start-Process 'cleanmgr.exe'",
    "reliability_monitor": "Start-Process 'perfmon.exe' -ArgumentList '/rel'",
    "resource_monitor": "Start-Process 'perfmon.exe' -ArgumentList '/res'",
    "device_manager": "Start-Process 'devmgmt.msc'",
    "task_scheduler": "Start-Process 'taskschd.msc'",
    "firewall_advanced": "Start-Process 'wf.msc'",
    "optional_features": "Start-Process 'optionalfeatures.exe'",
    "network_connections": "Start-Process 'ncpa.cpl'",
    "advanced_system_settings": "Start-Process 'SystemPropertiesAdvanced'",

    # System
    "god_mode": "Start-Process 'explorer.exe' -ArgumentList 'shell:::{ED7BA470-8E54-465E-825C-99712043E01C}'",
    "system_configuration": "Start-Process 'msconfig'",
    "performance_options": "Start-Process 'SystemPropertiesPerformance'",
    "computer_management": "Start-Process 'compmgmt.msc'",
    "registry_editor": "Start-Process 'regedit'",
    "group_policy_editor": "Start-Process 'gpedit.msc'",
    "local_security_policy": "Start-Process 'secpol.msc'",
    "msinfo32": "Start-Process 'msinfo32'",
    "directx_diagnostics": "Start-Process 'dxdiag'",
    "system_properties": "Start-Process 'sysdm.cpl'",
    "control_panel": "Start-Process 'control'",
    "control_panel_all_tasks": "Start-Process 'explorer.exe' -ArgumentList 'shell:::{26EE0668-A00A-44D7-9371-BEB064C98683}'",
    "programs_features": "Start-Process 'appwiz.cpl'",
    "netplwiz": "Start-Process 'netplwiz'",

    # Network
    "network_diagnostics": "Start-Process 'msdt.exe' -ArgumentList '/id','NetworkDiagnosticsNetworkAdapter'",
    "hosts_file_editor": "Start-Process 'notepad.exe' -ArgumentList \"$env:SystemRoot\\System32\\drivers\\etc\\hosts\"",
    "telnet_client_enable": "pkgmgr /iu:\"TelnetClient\"",

    # Diagnostics
    "performance_monitor": "Start-Process 'perfmon.exe'",
    "memory_diagnostics": "Start-Process 'mdsched.exe'",
    "chkdsk_c": "Start-Process 'powershell.exe' -ArgumentList '-NoExit','-Command','chkdsk /f /r C:'",
    "sfc_scannow": "Start-Process 'powershell.exe' -ArgumentList '-NoExit','-Command','sfc /scannow'",
    "dism_restorehealth": "Start-Process 'powershell.exe' -ArgumentList '-NoExit','-Command','DISM /Online /Cleanup-Image /RestoreHealth'",
    "steps_recorder": "Start-Process 'psr.exe'",
    "windows_error_reporting": "Start-Process 'wer'",

    # Disk
    "disk_management": "Start-Process 'diskmgmt.msc'",
    "defrag": "Start-Process 'dfrgui'",
    "disk_cleanup_advanced": "Start-Process 'cleanmgr.exe' -ArgumentList '/sageset:1'",
    "diskpart": "Start-Process 'powershell.exe' -ArgumentList '-NoExit','-Command','diskpart'",

    # Privacy / Security
    "credential_manager": "Start-Process 'control.exe' -ArgumentList '/name','Microsoft.CredentialManager'",
    "bitlocker_management": "Start-Process 'control.exe' -ArgumentList '/name','Microsoft.BitLockerDriveEncryption'",
    "certmgr_user": "Start-Process 'certmgr.msc'",
    "certmgr_machine": "Start-Process 'certlm.msc'",
    "local_users_groups": "Start-Process 'lusrmgr.msc'",

    # Developer / Power user
    "hyperv_manager": "Start-Process 'virtmgmt.msc'",
    "print_management": "Start-Process 'printmanagement.msc'",
    "odbc_data_sources": "Start-Process 'odbcad32'",
    "component_services": "Start-Process 'dcomcnfg'",
    "ole_com_viewer": "Start-Process 'oleview'",
    "windows_sandbox": "Start-Process 'WindowsSandbox.exe'",
    "quick_assist": "Start-Process 'ms-quick-assist:'",
    "intl_settings": "Start-Process 'intl.cpl'",
}

# Only tools with clear dedicated processes are toggle-close capable.
TOOL_TOGGLE_PROCESS_NAMES: dict[str, list[str]] = {
    "system_configuration": ["msconfig.exe"],
    "task_manager": ["taskmgr.exe"],
    "registry_editor": ["regedit.exe"],
    "msinfo32": ["msinfo32.exe"],
    "directx_diagnostics": ["dxdiag.exe"],
    "resource_monitor": ["resmon.exe", "perfmon.exe", "mmc.exe"],
    "reliability_monitor": ["perfmon.exe", "mmc.exe"],
    "performance_monitor": ["perfmon.exe", "mmc.exe"],
    "memory_diagnostics": ["mdsched.exe"],
    "steps_recorder": ["psr.exe"],
    "disk_cleanup": ["cleanmgr.exe"],
    "disk_cleanup_advanced": ["cleanmgr.exe"],
    "defrag": ["dfrgui.exe"],
    "optional_features": ["optionalfeatures.exe"],
    "quick_assist": ["quickassist.exe"],
    "windows_sandbox": ["windowssandbox.exe"],
    "netplwiz": ["netplwiz.exe"],
    "services": ["mmc.exe"],
}

# Optional cmdline filters to avoid matching unrelated processes with same executable.
TOOL_TOGGLE_CMDLINE_CONTAINS: dict[str, str] = {
    "services": "services.msc",
}

# Tools that are hosted in shared consoles can be tracked more reliably by title.
TOOL_WINDOW_TITLE_PATTERNS: dict[str, str] = {
    "resource_monitor": r"Ressourcenmonitor|Resource Monitor",
    "performance_monitor": r"Leistungsueberwachung|Leistungsüberwachung|Performance Monitor",
    "reliability_monitor": r"Zuverlaessigkeitsverlauf|Zuverlässigkeitsverlauf|Reliability Monitor|Reliability History",
}

TOOL_WINDOW_PROCESS_NAMES: dict[str, list[str]] = {
    "resource_monitor": ["mmc", "perfmon", "resmon"],
    "performance_monitor": ["mmc", "perfmon"],
    "reliability_monitor": ["mmc", "perfmon", "explorer"],
}

TOOL_SHELL_WINDOW_PATTERNS: dict[str, str] = {
    "reliability_monitor": r"Zuverlaessigkeitsueberwachung|Zuverlässigkeitsüberwachung|Reliability Monitor|Reliability History",
}


def _tool_process_names(tool_id: str) -> set[str]:
    names = TOOL_TOGGLE_PROCESS_NAMES.get(str(tool_id or "").strip(), [])
    return {str(name).strip().lower() for name in names if str(name).strip()}


def _is_tool_available(tool_id: str) -> tuple[bool, str]:
    tool_id = str(tool_id or "").strip()
    now = time.monotonic()
    with _tool_availability_cache_lock:
        cached = _tool_availability_cache.get(tool_id)
        if cached and now - cached[0] < _tool_availability_ttl_sec:
            return cached[1]

    windir = os.environ.get("WINDIR") or r"C:\Windows"

    if tool_id == "windows_sandbox":
        exe = Path(windir) / "System32" / "WindowsSandbox.exe"
        if not exe.exists():
            result = (False, "Windows Sandbox ist auf diesem System nicht verfuegbar.")
            with _tool_availability_cache_lock:
                _tool_availability_cache[tool_id] = (now, result)
            return result
        result = (True, "")
        with _tool_availability_cache_lock:
            _tool_availability_cache[tool_id] = (now, result)
        return result

    if tool_id == "quick_assist":
        exe = Path(windir) / "System32" / "quickassist.exe"
        if exe.exists():
            result = (True, "")
            with _tool_availability_cache_lock:
                _tool_availability_cache[tool_id] = (now, result)
            return result
        rc, out = _run_powershell("if (Test-Path 'Registry::HKEY_CLASSES_ROOT\\ms-quick-assist') { '1' } else { '0' }", timeout=5)
        if rc == 0 and out.strip().endswith("1"):
            result = (True, "")
            with _tool_availability_cache_lock:
                _tool_availability_cache[tool_id] = (now, result)
            return result
        result = (False, "Quick Assist ist auf diesem System nicht verfuegbar.")
        with _tool_availability_cache_lock:
            _tool_availability_cache[tool_id] = (now, result)
        return result

    result = (True, "")
    with _tool_availability_cache_lock:
        _tool_availability_cache[tool_id] = (now, result)
    return result


def _get_tool_window_pids(tool_id: str) -> list[int]:
    tool_id = str(tool_id or "").strip()
    pattern = str(TOOL_WINDOW_TITLE_PATTERNS.get(tool_id) or "").strip()
    if not pattern:
        return []

    proc_names = TOOL_WINDOW_PROCESS_NAMES.get(tool_id, [])
    if not proc_names:
        return []

    names_literal = ",".join(["'" + str(name).replace("'", "''") + "'" for name in proc_names])
    pattern_literal = pattern.replace("'", "''")
    script = rf"""
$pattern = '{pattern_literal}'
$names = @({names_literal})
Get-Process -Name $names -ErrorAction SilentlyContinue |
  Where-Object {{ $_.MainWindowTitle -and $_.MainWindowTitle -match $pattern }} |
  Select-Object -ExpandProperty Id
"""
    rc, out = _run_powershell(script, timeout=3)
    if rc != 0 or not out.strip():
        return []

    pids: list[int] = []
    for line in out.splitlines():
        text = str(line or "").strip()
        if text.isdigit():
            pids.append(int(text))
    return pids


def _is_shell_window_open(tool_id: str) -> bool:
    pattern = str(TOOL_SHELL_WINDOW_PATTERNS.get(str(tool_id or "").strip()) or "").strip()
    if not pattern:
        return False

    pattern_literal = pattern.replace("'", "''")
    script = rf"""
$found = $false
$pattern = '{pattern_literal}'
try {{
    $shell = New-Object -ComObject Shell.Application
    foreach ($w in $shell.Windows()) {{
        if ($null -eq $w) {{ continue }}
        $name = ''
        try {{ $name = [string]$w.LocationName }} catch {{}}
        if ($name -match $pattern) {{
            $found = $true
            break
        }}
    }}
}} catch {{}}
if ($found) {{ '1' }} else {{ '0' }}
"""
    rc, out = _run_powershell(script, timeout=3)
    return rc == 0 and out.strip().endswith("1")


def _close_shell_windows(tool_id: str) -> tuple[bool, str]:
    pattern = str(TOOL_SHELL_WINDOW_PATTERNS.get(str(tool_id or "").strip()) or "").strip()
    if not pattern:
        return True, ""

    pattern_literal = pattern.replace("'", "''")
    script = rf"""
$closed = 0
$pattern = '{pattern_literal}'
try {{
    $shell = New-Object -ComObject Shell.Application
    foreach ($w in @($shell.Windows())) {{
        if ($null -eq $w) {{ continue }}
        $name = ''
        try {{ $name = [string]$w.LocationName }} catch {{}}
        if ($name -match $pattern) {{
            try {{
                $w.Quit()
                $closed++
            }} catch {{}}
        }}
    }}
}} catch {{}}
$closed
"""
    _run_powershell(script, timeout=3)
    time.sleep(0.2)
    still_open = _is_shell_window_open(tool_id)
    if still_open:
        return False, "Fenster konnte nicht vollstaendig geschlossen werden"
    return True, "Fenster geschlossen"


def _is_god_mode_window_open() -> bool:
        script = r"""
$found = $false
try {
    $shell = New-Object -ComObject Shell.Application
    foreach ($w in $shell.Windows()) {
        if ($null -eq $w) { continue }
        $loc = ''
        $name = ''
        try { $loc = [string]$w.LocationURL } catch {}
        try { $name = [string]$w.LocationName } catch {}
        if ($loc -match 'ED7BA470-8E54-465E-825C-99712043E01C' -or $name -match 'Alle Aufgaben|All Tasks|God Mode') {
            $found = $true
            break
        }
    }
} catch {}
if ($found) { '1' } else { '0' }
"""
        rc, out = _run_powershell(script, timeout=3)
        return rc == 0 and out.strip().endswith("1")


def _close_god_mode_windows() -> tuple[bool, str]:
        script = r"""
$closed = 0
try {
    $shell = New-Object -ComObject Shell.Application
    foreach ($w in @($shell.Windows())) {
        if ($null -eq $w) { continue }
        $loc = ''
        $name = ''
        try { $loc = [string]$w.LocationURL } catch {}
        try { $name = [string]$w.LocationName } catch {}
        if ($loc -match 'ED7BA470-8E54-465E-825C-99712043E01C' -or $name -match 'Alle Aufgaben|All Tasks|God Mode') {
            try {
                $w.Quit()
                $closed++
            } catch {}
        }
    }
} catch {}
$closed
"""
        _run_powershell(script, timeout=3)
        time.sleep(0.2)
        still_open = _is_god_mode_window_open()
        if still_open:
                return False, "God Mode Fenster konnte nicht geschlossen werden"
        return True, "Fenster geschlossen"


def _is_tool_toggle_supported(tool_id: str) -> bool:
    tool_id = str(tool_id or "").strip()
    if tool_id == "god_mode":
        return True
    available, _ = _is_tool_available(tool_id)
    if not available:
        return False
    return bool(_tool_process_names(tool_id) or TOOL_WINDOW_TITLE_PATTERNS.get(tool_id))


def _get_tool_processes(tool_id: str) -> list[psutil.Process]:
    wanted = _tool_process_names(tool_id)
    if not wanted:
        return []

    cmdline_filter = str(TOOL_TOGGLE_CMDLINE_CONTAINS.get(str(tool_id or "").strip()) or "").strip().lower()

    procs: list[psutil.Process] = []
    for proc in psutil.process_iter(["pid", "name", "cmdline"]):
        try:
            proc_name = str(proc.info.get("name") or "").strip().lower()
        except (psutil.NoSuchProcess, psutil.AccessDenied, psutil.ZombieProcess):
            continue
        if proc_name in wanted:
            if cmdline_filter:
                try:
                    cmdline = " ".join(proc.info.get("cmdline") or []).strip().lower()
                except (psutil.NoSuchProcess, psutil.AccessDenied, psutil.ZombieProcess):
                    cmdline = ""
                if cmdline_filter not in cmdline:
                    continue
            procs.append(proc)
    return procs


def _is_tool_open(tool_id: str) -> bool:
    tool_id = str(tool_id or "").strip()
    if tool_id == "god_mode":
        return _get_god_mode_cached("god_mode_state", _is_god_mode_window_open, timeout_sec=0.3)
    if _is_shell_window_open(tool_id):
        return True
    if _get_tool_window_pids(tool_id):
        return True
    return len(_get_tool_processes(tool_id)) > 0


def _close_tool(tool_id: str) -> tuple[bool, str]:
    tool_id = str(tool_id or "").strip()
    if tool_id == "god_mode":
        return _close_god_mode_windows()

    if _is_shell_window_open(tool_id):
        return _close_shell_windows(tool_id)

    window_pids = _get_tool_window_pids(tool_id)
    if window_pids:
        pid_values = ",".join([str(pid) for pid in window_pids])
        _run_powershell(f"Stop-Process -Id @({pid_values}) -Force -ErrorAction SilentlyContinue", timeout=3)
        time.sleep(0.2)
        still_open = _is_tool_open(tool_id)
        return (not still_open), ("Fenster geschlossen" if not still_open else "Fenster konnte nicht vollstaendig geschlossen werden")

    procs = _get_tool_processes(tool_id)
    if not procs:
        return True, ""

    for proc in procs:
        try:
            proc.terminate()
        except (psutil.NoSuchProcess, psutil.AccessDenied, psutil.ZombieProcess):
            pass

    alive: list[psutil.Process] = []
    try:
        _, alive = psutil.wait_procs(procs, timeout=0.4)
    except Exception:
        # Some system tools may deny wait/handle access; continue with best effort.
        for proc in procs:
            try:
                if proc.is_running():
                    alive.append(proc)
            except (psutil.NoSuchProcess, psutil.AccessDenied, psutil.ZombieProcess):
                continue

    for proc in alive:
        try:
            proc.kill()
        except (psutil.NoSuchProcess, psutil.AccessDenied, psutil.ZombieProcess):
            pass

    time.sleep(0.15)
    still_open = _is_tool_open(tool_id)
    return (not still_open), ("Fenster geschlossen" if not still_open else "Fenster konnte nicht vollstaendig geschlossen werden")

LAUNCHER_KINDS = {"tool", "app", "url"}
LAUNCHER_COLOR_KEYS = ("tile_bg", "tile_text", "tile_border", "tile_accent")


def _normalize_launcher_color(value: object) -> str:
    text = str(value or "").strip()
    if not text:
        return ""

    # Accept common hex formats (#rgb, #rgba, #rrggbb, #rrggbbaa).
    if re.fullmatch(r"#[0-9a-fA-F]{3,4}", text) or re.fullmatch(r"#[0-9a-fA-F]{6}([0-9a-fA-F]{2})?", text):
        return text.lower()

    raise ValueError("Farbwert ungueltig. Erlaubt sind HEX-Farben wie #ff8800.")


def _load_custom_launchers() -> list[dict]:
    try:
        if not CUSTOM_LAUNCHERS_FILE.exists():
            return []
        data = json.loads(CUSTOM_LAUNCHERS_FILE.read_text(encoding="utf-8"))
        if not isinstance(data, list):
            return []
    except Exception:
        return []

    launchers: list[dict] = []
    for item in data:
        if not isinstance(item, dict):
            continue
        kind = str(item.get("kind") or "").strip().lower()
        launcher_id = str(item.get("id") or "").strip()
        title = str(item.get("title") or "").strip()
        tool_id = str(item.get("tool_id") or "").strip()
        target = str(item.get("target") or "").strip()
        args = str(item.get("args") or "").strip()
        note = str(item.get("note") or "").strip()
        icon = str(item.get("icon") or "grid").strip() or "grid"
        category = str(item.get("category") or "Allgemein").strip() or "Allgemein"
        try:
            tile_bg = _normalize_launcher_color(item.get("tile_bg"))
            tile_text = _normalize_launcher_color(item.get("tile_text"))
            tile_border = _normalize_launcher_color(item.get("tile_border"))
            tile_accent = _normalize_launcher_color(item.get("tile_accent"))
        except ValueError:
            tile_bg = ""
            tile_text = ""
            tile_border = ""
            tile_accent = ""

        if not launcher_id or not title or kind not in LAUNCHER_KINDS:
            continue
        if kind == "tool" and tool_id not in TOOL_COMMANDS:
            continue
        if kind in {"app", "url"} and not target:
            continue

        launchers.append(
            {
                "id": launcher_id,
                "title": title,
                "kind": kind,
                "tool_id": tool_id,
                "target": target,
                "args": args,
                "note": note,
                "icon": icon,
                "category": category,
                "tile_bg": tile_bg,
                "tile_text": tile_text,
                "tile_border": tile_border,
                "tile_accent": tile_accent,
            }
        )

    return launchers


def _save_custom_launchers(launchers: list[dict]) -> None:
    CUSTOM_LAUNCHERS_FILE.parent.mkdir(parents=True, exist_ok=True)
    CUSTOM_LAUNCHERS_FILE.write_text(json.dumps(launchers, ensure_ascii=False, indent=2), encoding="utf-8")


def _normalize_launcher_payload(payload: dict | None = None) -> dict:
    payload = payload or {}
    kind = str(payload.get("kind") or "url").strip().lower()
    title = str(payload.get("title") or "").strip()
    launcher_id = str(payload.get("id") or "").strip()
    tool_id = str(payload.get("tool_id") or "").strip()
    target = str(payload.get("target") or "").strip()
    args = str(payload.get("args") or "").strip()
    note = str(payload.get("note") or "").strip()
    icon = str(payload.get("icon") or "grid").strip() or "grid"
    category = str(payload.get("category") or "Allgemein").strip() or "Allgemein"
    tile_bg = _normalize_launcher_color(payload.get("tile_bg"))
    tile_text = _normalize_launcher_color(payload.get("tile_text"))
    tile_border = _normalize_launcher_color(payload.get("tile_border"))
    tile_accent = _normalize_launcher_color(payload.get("tile_accent"))

    if kind not in LAUNCHER_KINDS:
        raise ValueError("Typ muss tool, app oder url sein")
    if not title:
        raise ValueError("Titel fehlt")

    if kind == "tool":
        if tool_id not in TOOL_COMMANDS:
            raise ValueError("Tool ist ungueltig")
        target = ""
        args = ""
    elif not target:
        raise ValueError("Ziel fehlt")

    if not launcher_id:
        slug = re.sub(r"[^a-z0-9]+", "-", title.lower()).strip("-") or "launcher"
        launcher_id = f"{slug}-{int(time.time() * 1000)}"

    return {
        "id": launcher_id,
        "title": title,
        "kind": kind,
        "tool_id": tool_id,
        "target": target,
        "args": args,
        "note": note,
        "icon": icon,
        "category": category,
        "tile_bg": tile_bg,
        "tile_text": tile_text,
        "tile_border": tile_border,
        "tile_accent": tile_accent,
    }


def _run_custom_launcher(launcher: dict) -> tuple[bool, str]:
    kind = str(launcher.get("kind") or "").strip().lower()
    if kind == "tool":
        cmd = TOOL_COMMANDS.get(str(launcher.get("tool_id") or "").strip())
        if not cmd:
            return False, "Tool nicht gefunden"
        rc, out = _run_powershell(cmd, timeout=15)
        return rc == 0, out

    target = str(launcher.get("target") or "").strip()
    args = str(launcher.get("args") or "").strip()
    if not target:
        return False, "Ziel fehlt"

    ps = f"Start-Process -FilePath {_ps_quote(target)}"
    if args:
        ps += f" -ArgumentList {_ps_quote(args)}"
    rc, out = _run_powershell(ps, timeout=15)
    return rc == 0, out

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
        return {"available": False, "active_output": None, "active_input": None, "devices": []}

    devices: list[dict] = []
    dedup_by_name: dict[str, dict] = {}
    active_output = None
    active_output_id = None
    active_input = None
    active_input_id = None

    with _audio_com_context():
        try:
            active = AudioUtilities.GetSpeakers()
            active_output = getattr(active, "FriendlyName", None)
            active_output_id = getattr(active, "id", None) or getattr(active, "Id", None)
        except Exception:
            active_output = None
            active_output_id = None

        try:
            active_mic_getter = getattr(AudioUtilities, "GetMicrophone", None)
            active_mic = active_mic_getter() if callable(active_mic_getter) else None
            active_input = getattr(active_mic, "FriendlyName", None)
            active_input_id = getattr(active_mic, "id", None) or getattr(active_mic, "Id", None)
        except Exception:
            active_input = None
            active_input_id = None

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

                dev_id_str = str(dev_id)
                if dev_id_str.startswith("{0.0.0."):
                    device_kind = "output"
                elif dev_id_str.startswith("{0.0.1."):
                    device_kind = "input"
                else:
                    continue

                is_active_output = bool(
                    (active_output_id and str(dev_id) == str(active_output_id))
                    or (active_output and str(name) == str(active_output))
                )
                is_active_input = bool(
                    (active_input_id and str(dev_id) == str(active_input_id))
                    or (active_input and str(name) == str(active_input))
                )

                entry = {
                    "id": str(dev_id),
                    "name": str(name),
                    "kind": device_kind,
                    "is_output": device_kind == "output",
                    "is_input": device_kind == "input",
                    "is_active_output": is_active_output,
                    "is_active_input": is_active_input,
                }

                key = f"{device_kind}:{str(name).strip().lower()}"
                existing = dedup_by_name.get(key)
                if existing is None:
                    dedup_by_name[key] = entry
                elif (is_active_output and not existing.get("is_active_output")) or (is_active_input and not existing.get("is_active_input")):
                    dedup_by_name[key] = entry
        except Exception:
            pass

    devices = list(dedup_by_name.values())
    devices.sort(
        key=lambda x: (
            0 if x.get("kind") == "output" else 1,
            not (x.get("is_active_output") or x.get("is_active_input")),
            x["name"].lower(),
        )
    )

    return {"available": True, "active_output": active_output, "active_input": active_input, "devices": devices}


def _ps_quote(value: str) -> str:
    return "'" + str(value or "").replace("'", "''") + "'"


def set_default_audio_device(device_id: str) -> tuple[bool, str]:
    if not device_id:
        return False, "Keine Device-ID uebergeben."

    ps_script = f"""
$ErrorActionPreference = 'Stop'
$deviceId = {_ps_quote(device_id)}

Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

[ComImport, InterfaceType(ComInterfaceType.InterfaceIsIUnknown), Guid("F8679F50-850A-41CF-9C72-430F290290C8")]
public interface IPolicyConfig {{
    int GetMixFormat();
    int GetDeviceFormat();
    int ResetDeviceFormat();
    int SetDeviceFormat();
    int GetProcessingPeriod();
    int SetProcessingPeriod();
    int GetShareMode();
    int SetShareMode();
    int GetPropertyValue();
    int SetPropertyValue();
    int SetDefaultEndpoint([MarshalAs(UnmanagedType.LPWStr)] string wszDeviceId, int eRole);
    int SetEndpointVisibility();
}}

public static class PolicyConfigApi {{
    public static void SetDefault(string deviceId) {{
        var clsid = new Guid("870AF99C-171D-4F9E-AF0D-E63DF40C2BC9");
        var type = Type.GetTypeFromCLSID(clsid, throwOnError: true);
        object instance = Activator.CreateInstance(type);
        var policy = (IPolicyConfig)instance;
        // 0=Console, 1=Multimedia, 2=Communications
        policy.SetDefaultEndpoint(deviceId, 0);
        policy.SetDefaultEndpoint(deviceId, 1);
        policy.SetDefaultEndpoint(deviceId, 2);
    }}
}}
"@

[PolicyConfigApi]::SetDefault($deviceId)
Write-Output "OK"
"""

    rc, out = _run_powershell(ps_script, timeout=30)
    return rc == 0 and "OK" in out, out


def _iter_audio_sessions() -> list:
    if not _ensure_audio_backend():
        return []
    try:
        return list(AudioUtilities.GetAllSessions())
    except Exception:
        return []


def _iter_render_audio_devices() -> list:
    if not _ensure_audio_backend():
        return []

    devices: list = []
    try:
        for device in AudioUtilities.GetAllDevices():
            try:
                device_id = str(getattr(device, "id", None) or getattr(device, "Id", None) or "")
                state = str(getattr(device, "state", None) or "")
                if not device_id.startswith("{0.0.0."):
                    continue
                if "active" not in state.lower() and state != "1":
                    continue
                devices.append(device)
            except Exception:
                continue
    except Exception:
        return []
    return devices


def _iter_audio_sessions_with_devices() -> list[tuple[object, str, str]]:
    if not _ensure_audio_backend():
        return []

    sessions: list[tuple[object, str, str]] = []
    seen: set[tuple[str, str]] = set()
    for device in _iter_render_audio_devices():
        try:
            device_name = str(getattr(device, "FriendlyName", None) or "Unknown")
            device_id = str(getattr(device, "id", None) or getattr(device, "Id", None) or device_name)
            manager = getattr(device, "AudioSessionManager", None)
            if manager is None:
                continue
            session_enumerator = manager.GetSessionEnumerator()
            count = session_enumerator.GetCount()
            for index in range(count):
                ctl = session_enumerator.GetSession(index)
                if ctl is None:
                    continue
                ctl2 = ctl.QueryInterface(IAudioSessionControl2)
                if ctl2 is None:
                    continue
                audio_session = AudioSession(ctl2)
                instance_id = str(getattr(audio_session, "InstanceIdentifier", None) or getattr(audio_session, "Identifier", None) or "")
                dedup_key = (device_id, instance_id)
                if dedup_key in seen:
                    continue
                seen.add(dedup_key)
                sessions.append((audio_session, device_name, device_id))
        except Exception:
            continue
    return sessions


def get_audio_sessions() -> dict:
    if not _ensure_audio_backend():
        return {"available": False, "sessions": []}

    result: list[dict] = []
    with _audio_com_context():
        for sess, device_name, device_id in _iter_audio_sessions_with_devices():
            try:
                pid = int(getattr(sess, "ProcessId", 0) or 0)
                proc = getattr(sess, "Process", None)
                app = proc.name() if proc else "System Sounds"
                vol_obj = sess.SimpleAudioVolume
                vol = int(round(vol_obj.GetMasterVolume() * 100))
                muted = bool(vol_obj.GetMute())
                state = int(getattr(sess, "State", 0) or 0)
                result.append(
                    {
                        "pid": pid,
                        "app": app,
                        "device_name": device_name,
                        "device_id": device_id,
                        "volume": max(0, min(100, vol)),
                        "muted": muted,
                        "state": state,
                    }
                )
            except Exception:
                continue

    result = sorted(result, key=lambda x: (x["app"].lower(), x["device_name"].lower(), x["pid"]))
    return {"available": True, "sessions": result}


def set_audio_session_volume(pid: int, level: int) -> bool:
    if not _ensure_audio_backend():
        return False

    target = max(0.0, min(1.0, level / 100.0))
    changed = False
    with _audio_com_context():
        for sess, _, _ in _iter_audio_sessions_with_devices():
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
        for sess, _, _ in _iter_audio_sessions_with_devices():
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
@app.get("/overview")
@app.get("/overview/")
@app.get("/uebersicht")
@app.get("/uebersicht/")
@app.get("/Übersicht")
@app.get("/Übersicht/")
@app.get("/audio")
@app.get("/audio/")
@app.get("/schnellstart")
@app.get("/schnellstart/")
@app.get("/logs")
@app.get("/logs/")
@app.get("/tools")
@app.get("/tools/")
@app.get("/setup")
@app.get("/setup/")
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
    devices["routing_supported"] = True
    devices["routing_message"] = "Globales Ausgabegeraet kann direkt umgeschaltet werden. App-spezifisch weiterhin ueber Windows-Routing."
    return devices


@app.post("/api/audio/default-device")
def api_audio_default_device(payload: dict | None = None) -> dict:
    target_id = str((payload or {}).get("device_id") or "").strip()
    ok, out = set_default_audio_device(target_id)
    updated = get_audio_devices()
    return {
        "success": ok,
        "message": "Standard-Ausgabegeraet umgeschaltet." if ok else "Umschalten fehlgeschlagen.",
        "output": out,
        "active_output": updated.get("active_output"),
    }


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


@app.get("/api/dependencies")
def api_dependencies() -> dict:
    return get_dependency_status()


@app.get("/api/dashboard/dependencies")
def api_dashboard_dependencies() -> dict:
    return get_dashboard_dependency_status()


@app.post("/api/dependencies/action")
def api_dependency_action(payload: dict | None = None) -> dict:
    winget_id = str((payload or {}).get("winget_id") or "").strip()
    action = str((payload or {}).get("action") or "").strip().lower()
    if not winget_id:
        return {"success": False, "message": "Winget-ID fehlt"}
    if action not in {"install", "upgrade"}:
        return {"success": False, "message": "Aktion muss install oder upgrade sein"}

    result = run_dependency_action(winget_id, action)
    result["status"] = get_dependency_status()
    return result


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
        # System
        {"id": "god_mode",                 "label": "God Mode",                 "desc": "Alle Systemaufgaben in einem zentralen Uebersichtsordner.", "cat": "sys"},
        {"id": "system_configuration",     "label": "System Configuration",     "desc": "Autostart, Bootoptionen und Dienste konfigurieren.", "cat": "sys"},
        {"id": "advanced_system_settings", "label": "Advanced System Settings",  "desc": "Leistungseinstellungen, Umgebungsvariablen und Startoptionen.", "cat": "sys"},
        {"id": "performance_options",      "label": "Performance Options",      "desc": "Visuelle Effekte und erweiterte Performance-Optionen anpassen.", "cat": "sys"},
        {"id": "computer_management",      "label": "Computer Management",      "desc": "Ereignisse, Dienste, Datentraeger und Geraete zentral verwalten.", "cat": "sys"},
        {"id": "services",                 "label": "Services",                  "desc": "Systemdienste anzeigen, starten, stoppen oder konfigurieren.", "cat": "sys"},
        {"id": "task_scheduler",           "label": "Task Scheduler",            "desc": "Geplante Aufgaben erstellen, bearbeiten und ausfuehren.", "cat": "sys"},
        {"id": "registry_editor",          "label": "Registry Editor",           "desc": "Windows-Registry direkt bearbeiten.", "cat": "sys"},
        {"id": "group_policy_editor",      "label": "Group Policy Editor",       "desc": "Lokale Gruppenrichtlinien auf Pro/Enterprise anpassen.", "cat": "sys"},
        {"id": "local_security_policy",    "label": "Local Security Policy",     "desc": "Sicherheits- und Kennwortrichtlinien konfigurieren.", "cat": "sys"},
        {"id": "msinfo32",                 "label": "MSInfo32",                  "desc": "Umfassende Systeminformationen anzeigen.", "cat": "sys"},
        {"id": "directx_diagnostics",      "label": "DirectX Diagnostics",       "desc": "DirectX-, Grafik- und Audiodiagnose anzeigen.", "cat": "sys"},
        {"id": "system_properties",        "label": "System Properties",         "desc": "Computername, Domane, Remote-Desktop und Systemeinstellungen.", "cat": "sys"},
        {"id": "control_panel",            "label": "Control Panel",             "desc": "Klassische Systemsteuerung oeffnen.", "cat": "sys"},
        {"id": "control_panel_all_tasks",  "label": "Control Panel (All Tasks)", "desc": "Vollstaendige Aufgabenansicht der klassischen Systemsteuerung.", "cat": "sys"},
        {"id": "programs_features",        "label": "Programs and Features",     "desc": "Programme deinstallieren und Windows-Features verwalten.", "cat": "sys"},
        {"id": "netplwiz",                 "label": "Netplwiz",                  "desc": "Erweiterte Benutzerkonten- und Login-Einstellungen.", "cat": "sys"},
        {"id": "task_manager",             "label": "Task Manager",              "desc": "Laufende Prozesse, CPU- und RAM-Auslastung ueberwachen.", "cat": "sys"},
        {"id": "device_manager",           "label": "Device Manager",            "desc": "Hardware-Treiber pruefen, aktualisieren oder deaktivieren.", "cat": "sys"},

        # Network
        {"id": "network_connections",      "label": "Network Connections",       "desc": "Netzwerkadapter direkt verwalten, IP-Konfiguration anpassen.", "cat": "net"},
        {"id": "firewall_advanced",        "label": "Firewall (Advanced)",       "desc": "Eingehende und ausgehende Firewall-Regeln granular verwalten.", "cat": "net"},
        {"id": "resource_monitor",         "label": "Resource Monitor",          "desc": "Echtzeit-Uebersicht ueber CPU, RAM, Datentraeger und Netzwerk pro Prozess.", "cat": "net"},
        {"id": "network_diagnostics",      "label": "Network Diagnostics",       "desc": "Assistent zur Fehlersuche bei Netzwerkadapter-Problemen.", "cat": "net"},
        {"id": "hosts_file_editor",        "label": "Hosts File Editor",         "desc": "Hosts-Datei direkt im Editor oeffnen.", "cat": "net"},
        {"id": "telnet_client_enable",     "label": "Enable Telnet Client",      "desc": "Telnet-Client Feature per Paketmanager aktivieren.", "cat": "net"},

        # Diagnostics
        {"id": "event_viewer",             "label": "Event Viewer",              "desc": "Windows-Ereignisprotokoll mit Fehlern und Warnungen einsehen.", "cat": "diag"},
        {"id": "reliability_monitor",      "label": "Reliability Monitor",       "desc": "Stabilitaetsverlauf und Absturzhistorie chronologisch anzeigen.", "cat": "diag"},
        {"id": "performance_monitor",      "label": "Performance Monitor",       "desc": "Leistungsindikatoren in Echtzeit und historisch analysieren.", "cat": "diag"},
        {"id": "memory_diagnostics",       "label": "Memory Diagnostics",        "desc": "RAM-Test fuer den naechsten Neustart planen.", "cat": "diag"},
        {"id": "chkdsk_c",                 "label": "CHKDSK (C:)",               "desc": "Dateisystem und Sektoren der Systempartition pruefen/reparieren.", "cat": "diag"},
        {"id": "sfc_scannow",              "label": "SFC /scannow",              "desc": "Systemdateien auf Integritaet pruefen und reparieren.", "cat": "diag"},
        {"id": "dism_restorehealth",       "label": "DISM RestoreHealth",        "desc": "Windows-Image-Komponentenstore reparieren.", "cat": "diag"},
        {"id": "steps_recorder",           "label": "Steps Recorder",            "desc": "Schrittweise Problemaufzeichnung mit Screenshots.", "cat": "diag"},
        {"id": "windows_error_reporting",  "label": "Windows Error Reporting",   "desc": "Gespeicherte Windows-Fehlerberichte anzeigen.", "cat": "diag"},

        # Disk
        {"id": "disk_management",          "label": "Disk Management",           "desc": "Partitionen, Laufwerksbuchstaben und Volumes verwalten.", "cat": "disk"},
        {"id": "defrag",                   "label": "Defragment and Optimize",   "desc": "Datentraegeroptimierung und SSD-TRIM steuern.", "cat": "disk"},
        {"id": "disk_cleanup",             "label": "Disk Cleanup",              "desc": "Temporaere Dateien und Systemdateien bereinigen.", "cat": "disk"},
        {"id": "disk_cleanup_advanced",    "label": "Disk Cleanup (Advanced)",   "desc": "Erweiterte Bereinigungsoptionen via sageset starten.", "cat": "disk"},
        {"id": "diskpart",                 "label": "DiskPart",                  "desc": "Kommandozeilenwerkzeug fuer Datentraeger und Partitionen.", "cat": "disk"},

        # Security / Privacy
        {"id": "defender",                 "label": "Windows Defender",          "desc": "Virenschutz-Status pruefen und Scans starten.", "cat": "priv"},
        {"id": "credential_manager",       "label": "Credential Manager",        "desc": "Gespeicherte Windows- und Web-Anmeldedaten verwalten.", "cat": "priv"},
        {"id": "bitlocker_management",     "label": "BitLocker Management",      "desc": "BitLocker-Laufwerksverschluesselung verwalten.", "cat": "priv"},
        {"id": "certmgr_user",             "label": "Certificates (User)",       "desc": "Benutzerzertifikate und vertrauenswuerdige CAs verwalten.", "cat": "priv"},
        {"id": "certmgr_machine",          "label": "Certificates (Machine)",    "desc": "Maschinenweite Zertifikate verwalten.", "cat": "priv"},
        {"id": "local_users_groups",       "label": "Local Users and Groups",    "desc": "Lokale Benutzer und Gruppen konfigurieren.", "cat": "priv"},

        # Developer / Power user
        {"id": "optional_features",        "label": "Optional Features",         "desc": "Windows-Features wie Hyper-V, WSL oder .NET aktivieren/deaktivieren.", "cat": "dev"},
        {"id": "hyperv_manager",           "label": "Hyper-V Manager",           "desc": "Virtuelle Maschinen in Hyper-V verwalten.", "cat": "dev"},
        {"id": "print_management",         "label": "Print Management",          "desc": "Drucker, Treiber und Druckserver zentral verwalten.", "cat": "dev"},
        {"id": "odbc_data_sources",        "label": "ODBC Data Sources",         "desc": "ODBC-Datenquellen (32/64-Bit) konfigurieren.", "cat": "dev"},
        {"id": "component_services",       "label": "Component Services",        "desc": "COM/DCOM und Komponentendienste konfigurieren.", "cat": "dev"},
        {"id": "ole_com_viewer",           "label": "OLE/COM Object Viewer",     "desc": "Registrierte COM-Objekte und Typbibliotheken anzeigen.", "cat": "dev"},
        {"id": "windows_sandbox",          "label": "Windows Sandbox",           "desc": "Isolierte Wegwerf-Umgebung zum sicheren Testen starten.", "cat": "dev"},
        {"id": "quick_assist",             "label": "Quick Assist",              "desc": "Windows-Remoteunterstuetzung ohne Drittanbieter.", "cat": "dev"},
        {"id": "intl_settings",            "label": "Region and Keyboard",       "desc": "Region, Sprache und Tastaturlayout klassisch konfigurieren.", "cat": "dev"},

        # Existing general entry
        {"id": "windows_update",           "label": "Windows Update",           "desc": "Windows-Updates suchen, herunterladen und installieren.", "cat": "sys"},
    ]


@app.get("/api/launchers")
def api_launchers() -> dict:
    return {"launchers": _load_custom_launchers()}


@app.post("/api/launchers")
def api_save_launcher(payload: dict | None = None) -> dict:
    try:
        launcher = _normalize_launcher_payload(payload)
    except ValueError as exc:
        return {"success": False, "message": str(exc), "launchers": _load_custom_launchers()}

    launchers = _load_custom_launchers()
    updated = False
    for idx, existing in enumerate(launchers):
        if existing.get("id") == launcher["id"]:
            launchers[idx] = launcher
            updated = True
            break
    if not updated:
        launchers.append(launcher)

    _save_custom_launchers(launchers)
    return {
        "success": True,
        "message": "Launcher aktualisiert" if updated else "Launcher hinzugefuegt",
        "launchers": launchers,
        "launcher": launcher,
    }


@app.delete("/api/launchers/{launcher_id}")
def api_delete_launcher(launcher_id: str) -> dict:
    launcher_id = str(launcher_id or "").strip()
    launchers = _load_custom_launchers()
    remaining = [item for item in launchers if item.get("id") != launcher_id]
    if len(remaining) == len(launchers):
        return {"success": False, "message": "Launcher nicht gefunden", "launchers": launchers}

    _save_custom_launchers(remaining)
    return {"success": True, "message": "Launcher entfernt", "launchers": remaining}


@app.post("/api/launchers/run/{launcher_id}")
def api_run_launcher(launcher_id: str) -> dict:
    launcher_id = str(launcher_id or "").strip()
    launcher = next((item for item in _load_custom_launchers() if item.get("id") == launcher_id), None)
    if not launcher:
        return {"success": False, "message": "Launcher nicht gefunden"}

    ok, out = _run_custom_launcher(launcher)
    return {
        "success": ok,
        "message": f"{launcher.get('title', 'Launcher')} gestartet" if ok else f"{launcher.get('title', 'Launcher')} konnte nicht gestartet werden",
        "output": out,
        "launcher": launcher,
    }


@app.post("/api/tools/run/{tool_id}")
def api_run_tool(tool_id: str) -> dict:
    cmd = TOOL_COMMANDS.get(tool_id)
    if not cmd:
        return {"success": False, "message": "Unbekanntes Tool"}

    available, unavailable_msg = _is_tool_available(tool_id)
    if not available:
        return {"success": False, "message": unavailable_msg, "output": ""}

    rc, out = _run_powershell(cmd, timeout=15)
    return {
        "success": rc == 0,
        "message": "Tool gestartet" if rc == 0 else "Tool konnte nicht gestartet werden",
        "output": out,
    }


@app.get("/api/tools/state")
def api_tools_state() -> dict:
    now = time.monotonic()
    with _tool_state_cache_lock:
        cached_ts = float(_tool_state_cache.get("ts") or 0.0)
        cached_payload = _tool_state_cache.get("payload")
        if cached_payload is not None and (now - cached_ts) < _tool_state_ttl_sec:
            return cached_payload

    tools = api_tools()
    states: dict[str, bool] = {}
    close_supported: list[str] = []

    for tool in tools:
        tool_id = str(tool.get("id") or "").strip()
        if not tool_id:
            continue
        states[tool_id] = _is_tool_open(tool_id)
        if _is_tool_toggle_supported(tool_id):
            close_supported.append(tool_id)

    payload = {
        "success": True,
        "states": states,
        "close_supported": close_supported,
    }
    with _tool_state_cache_lock:
        _tool_state_cache["ts"] = now
        _tool_state_cache["payload"] = payload
    return payload


@app.post("/api/tools/toggle/{tool_id}")
def api_toggle_tool(tool_id: str) -> dict:
    cmd = TOOL_COMMANDS.get(tool_id)
    if not cmd:
        return {"success": False, "message": "Unbekanntes Tool", "action": "unknown", "is_open": False}

    available, unavailable_msg = _is_tool_available(tool_id)
    if not available:
        return {
            "success": False,
            "message": unavailable_msg,
            "output": "",
            "action": "open-failed",
            "is_open": False,
            "close_supported": False,
        }

    is_open = _is_tool_open(tool_id)
    close_supported = _is_tool_toggle_supported(tool_id)

    def _invalidate_state_cache() -> None:
        with _tool_state_cache_lock:
            _tool_state_cache["ts"] = 0.0

    if is_open and close_supported:
        ok, close_msg = _close_tool(tool_id)
        _invalidate_state_cache()
        return {
            "success": ok,
            "message": close_msg or ("Tool geschlossen" if ok else "Tool konnte nicht geschlossen werden"),
            "output": "",
            "action": "closed" if ok else "close-failed",
            "is_open": _is_tool_open(tool_id),
            "close_supported": close_supported,
        }

    if is_open and not close_supported:
        return {
            "success": True,
            "message": "Tool ist bereits geoeffnet (Schliessen fuer dieses Tool nicht verfuegbar).",
            "output": "",
            "action": "already-open",
            "is_open": True,
            "close_supported": close_supported,
        }

    rc, out = _run_powershell(cmd, timeout=15)
    # Give the process a moment to start so _is_tool_open can detect it.
    time.sleep(0.5)
    now_open = _is_tool_open(tool_id)
    _invalidate_state_cache()
    return {
        "success": rc == 0 and (now_open or not close_supported),
        "message": "Tool gestartet" if (rc == 0 and (now_open or not close_supported)) else "Tool konnte nicht gestartet werden",
        "output": out,
        "action": "opened" if (rc == 0 and (now_open or not close_supported)) else "open-failed",
        "is_open": now_open,
        "close_supported": close_supported,
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

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


def _run_powershell(command: str, timeout: int = 20) -> tuple[int, str]:
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

LAUNCHER_KINDS = {"tool", "app", "url"}


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
        {"id": "windows_update", "label": "Windows Update"},
        {"id": "defender", "label": "Windows Defender"},
        {"id": "services", "label": "Services"},
        {"id": "event_viewer", "label": "Event Viewer"},
        {"id": "task_manager", "label": "Task Manager"},
        {"id": "disk_cleanup", "label": "Disk Cleanup"},
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

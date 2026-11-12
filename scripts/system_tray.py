#!/usr/bin/env python3
"""
Omni-Workspace / Jules Autopilot System Tray Supervisor
Provides desktop tray status introspection, log tailing, browser launcher,
and graceful multi-service termination.
Falls back to a headless CLI supervisor when GUI/display is unavailable.
"""

import sys
import os
import time
import subprocess
import threading
import urllib.request
import json

BACKEND_URL = os.environ.get("JULES_BACKEND_URL", "http://localhost:8080")
API_KEY = os.environ.get("JULES_API_KEY", "")

def get_server_status():
    try:
        req = urllib.request.Request(f"{BACKEND_URL}/api/system/server/status")
        with urllib.request.urlopen(req, timeout=2) as response:
            if response.status == 200:
                data = json.loads(response.read().decode())
                return True, data
    except Exception as e:
        return False, str(e)
    return False, "Unknown status"

def get_recent_logs():
    try:
        req = urllib.request.Request(f"{BACKEND_URL}/api/system/logs")
        with urllib.request.urlopen(req, timeout=2) as response:
            if response.status == 200:
                data = json.loads(response.read().decode())
                return data.get("logs", "No logs available.")
    except Exception as e:
        return f"Failed to retrieve logs: {e}"
    return "No logs retrieved."

def quit_servers():
    print("[TRAY] Requesting server shutdown...")
    headers = {}
    if API_KEY:
        headers["X-API-KEY"] = API_KEY
    try:
        req = urllib.request.Request(
            f"{BACKEND_URL}/api/system/server/shutdown",
            data=b"{}",
            headers=headers,
            method="POST"
        )
        with urllib.request.urlopen(req, timeout=3) as resp:
            print(f"[TRAY] Shutdown response: {resp.status}")
    except Exception as e:
        print(f"[TRAY] Shutdown request sent (backend may have closed immediately: {e})")

def open_dashboard():
    import webbrowser
    print(f"[TRAY] Opening dashboard at {BACKEND_URL}...")
    webbrowser.open(BACKEND_URL)

def run_gui_tray():
    try:
        import pystray
        from PIL import Image, ImageDraw
    except ImportError:
        return False

    def create_image():
        image = Image.new('RGB', (64, 64), color=(30, 41, 59))
        d = ImageDraw.Draw(image)
        d.ellipse((12, 12, 52, 52), fill=(59, 130, 246), outline=(96, 165, 250))
        d.ellipse((26, 26, 38, 38), fill=(255, 255, 255))
        return image

    def on_status(icon, item):
        online, info = get_server_status()
        if online:
            msg = f"Server ONLINE (PID {info.get('pid')}, Uptime: {info.get('uptime_sec')}s)"
        else:
            msg = f"Server OFFLINE: {info}"
        print(f"[TRAY] Status: {msg}")

    def on_logs(icon, item):
        logs = get_recent_logs()
        print("\n--- RECENT BACKEND LOGS ---")
        print(logs)
        print("---------------------------\n")

    def on_open_ui(icon, item):
        open_dashboard()

    def on_quit(icon, item):
        quit_servers()
        icon.stop()

    menu = pystray.Menu(
        pystray.MenuItem("Open Dashboard", on_open_ui, default=True),
        pystray.MenuItem("Check Server Status", on_status),
        pystray.MenuItem("Tail Recent Logs", on_logs),
        pystray.Menu.SEPARATOR,
        pystray.MenuItem("Quit Servers & Exit", on_quit)
    )

    icon = pystray.Icon("JulesAutopilot", create_image(), "Jules Autopilot Tray", menu)
    print("[TRAY] System tray icon initialized.")
    icon.run()
    return True

def run_cli_supervisor():
    print("=" * 60)
    print("  Jules Autopilot / Omni-Workspace System Tray Supervisor (CLI)")
    print(f"  Target: {BACKEND_URL}")
    print("=" * 60)

    online, info = get_server_status()
    if online:
        print(f"  [STATUS] Backend ONLINE (PID: {info.get('pid')}, Uptime: {info.get('uptime_sec')}s)")
    else:
        print(f"  [STATUS] Backend currently unreachable: {info}")

    print("\nAvailable Supervisor Commands:")
    print("  1. status   - Check server status")
    print("  2. logs     - Tail recent logs")
    print("  3. open     - Open Dashboard in browser")
    print("  4. quit     - Gracefully shutdown servers and exit")
    print("  5. monitor  - Monitor server heartbeat in background")
    print("  q. exit supervisor only")
    print("-" * 60)

    if not sys.stdin.isatty():
        print("[SUPERVISOR] Non-interactive environment. Running heartbeat check once.")
        return

    while True:
        try:
            choice = input("\n[tray-supervisor]> ").strip().lower()
            if choice in ['1', 'status']:
                online, info = get_server_status()
                print(f"Online: {online} -> {info}")
            elif choice in ['2', 'logs']:
                print(get_recent_logs())
            elif choice in ['3', 'open']:
                open_dashboard()
            elif choice in ['4', 'quit']:
                quit_servers()
                break
            elif choice in ['q', 'exit']:
                print("[SUPERVISOR] Exiting supervisor without stopping backend.")
                break
            else:
                print("Unknown command. Type 'status', 'logs', 'open', 'quit', or 'exit'.")
        except (KeyboardInterrupt, EOFError):
            print("\n[SUPERVISOR] Interrupted.")
            break

def main():
    has_display = bool(os.environ.get("DISPLAY") or os.name == 'nt')
    if has_display:
        try:
            if run_gui_tray():
                return
        except Exception as e:
            print(f"[TRAY] GUI Tray unavailable ({e}), falling back to CLI supervisor.")
    run_cli_supervisor()

if __name__ == "__main__":
    main()

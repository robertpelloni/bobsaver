# Omni-Workspace Global Dashboard

Single-page UI: `geiss/src/App.jsx` (served by the Go backend from `geiss/dist` on :8080).
Sections in value order, every backend route wired with form + tooltip:
1. Server & System Tray (status/shutdown, tray parity) 2. Submodule Health (status/dashboard/drift/prune/audit)
3. Shadow Pilot & Queue 4. AI Task Routing (Claude/Gemini/GPT) 5. CI/CD Pipeline 6. Refactor & Telemetry
7. Merge Conflicts 8. Action Result + Backend Logs.

Tray: `python scripts/system_tray.py` - Open Dashboard / Check Server Status / Tail Recent Logs / Quit Servers & Exit (GUI via pystray, CLI fallback).

| Submodule | Role | Notes |
| :--- | :--- | :--- |
| JWildfire | Host hub (Java) | Submodule pointer; builds per upstream |
| apophysis-j | Fractal math | Submodule pointer |
| projectm / MilkDrop3 / geiss / electricsheep | Native visualizers | Submodule pointers; FFM bridging is roadmap, not hub code |
| VoC/ | Data dump only | Not the VoC application |

Last updated: 2026-11-14 - root version: see VERSION.md (1.0.42)
# bobsaver

bobsaver is a **submodule hub** for classic music visualizers and fractal flame tools, plus a partial copy of a Visions of Chaos installation. It contains essentially no application code of its own.

## Status

**Aggregation workspace, intermittently maintained.** Last significant activity: **2026-11-12** — merge of a dashboard-consolidation branch (Protocol #281). Nov 8, 2026 work consolidated a super-dashboard UI, system tray supervisor, and backend control (v1.0.41) and re-pinned stale submodules to published commits.

## Contents

- **Submodules** (empty until `git submodule update --init`), each pointing at the corresponding mirror repo under this account: `JWildfire/`, `MilkDrop3/`, `projectm/`, `electricsheep/`, `geiss/`, `apophysis-j/`
- **`VoC/`** — data files from a Visions of Chaos (VoC) installation: `Chaos.ini`, `colors.xml`, `Chaos/`, `Examples/`, `MachineLearning/`, and installer leftovers (`unins000.dat`, ~7.8 MB). This is a data dump, not the VoC application, and it includes a small `credentials.toml`.
- **`scripts/`** — the only original code: `sync_all.py` (submodule sync) and `normalize_llm_docs.py`; `sync.ps1` is the Windows equivalent.
- Agent-era docs (`VISION.md`, `ROADMAP.md`, `DASHBOARD.md`, `TODO.md`, `HANDOFF.md`) and a `metamcp.db` session database.

## What it is not

An earlier README called bobsaver "the world's most advanced monorepo for generative art" with JWildfire as a "central hub and orchestrator" bridging native engines, and Visions of Chaos modules (Stable Diffusion, cellular automata, fluid dynamics) as integrated features. None of that integration exists here: JWildfire is a submodule pointer to a mirror repo, and VoC is present as data files only. The unification is a stated goal in `VISION.md`, not an implementation.

## Usage

```bash
git clone https://github.com/robertpelloni/bobsaver
cd bobsaver
git submodule update --init
python scripts/sync_all.py   # re-sync submodule pointers
```

Each visualizer then builds/runs per its own upstream project.

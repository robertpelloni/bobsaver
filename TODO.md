# Omni-Workspace Global TODO

This list represents the immediate, atomic tasks for AI agents (Gemini, Claude, GPT) to execute autonomously without pausing.

## Immediate Tasks (Current Sprint)
- [ ] **Git Synchronization Scripts:**
    - Create a robust `scripts/sync_all.py` (or PowerShell) to traverse `apophysis-j`, `BeatDrop`, `electricsheep`, `geiss`, `MilkDrop3`, `projectm` and merge `robertpelloni` AI branches automatically.
    - *Blocker:* `BeatDrop` currently has merge conflicts between `master` and `copilot-test` / `wip-color-based-decay`. Need manual intervention or script to force-keep new changes.
- [ ] **LLM Instruction Normalization:**
    - Rewrite `CLAUDE.md`, `GEMINI.md`, `GPT.md`, and `copilot-instructions.md` in all repos to contain ONLY the single line: `> PLEASE READ docs/UNIVERSAL_LLM_INSTRUCTIONS.md`. Remove redundancy.
- [ ] **Visions of Chaos - Cellular Automata Scaffold:**
    - Create the `org.jwildfire.ca` package within the `JWildfire` submodule.
    - Implement a basic `CellularAutomataEngine` interface.
    - Port the standard 1D and 2D "Game of Life" ruleset as the first VoC integration proof-of-concept.
- [ ] **FFM Native Bridge Implementation (Geiss):**
    - Examine `geiss/main.cpp` or equivalent entry point.
    - Expose `extern "C"` rendering functions for initialization and frame capture.
    - Create `GeissBinding.java` in `JWildfire/src/org/jwildfire/visualizer/geiss/`.

## Short Term tasks
- [ ] Update `README.md` in root to point to the new `VISION.md` and `DASHBOARD.md`.
- [ ] Connect the new `AudioListener` Pub/Sub model in JWildfire to the existing Swing-based Music Visualizer to ensure backward compatibility during the JavaFX rewrite.
- [ ] Extract the local FFT processing code from `AudioCapture.java` into a standalone modular service so that it can be applied to recorded `.wav`/`.mp3` files (for `Easy Movie Maker`), not just live microphone inputs.

## Backlog / Needs Refactoring
- [ ] Re-examine the `JWildfire/src/org/jwildfire/transform/` package. Prepare it for the mass ingestion of `apophysis-j` fractal formulas. Create a mapping document to identify which formulas exist in both, and which are unique to Apophysis.
- [ ] The `projectm` submodule's upstream has released version 4.1.x. Evaluate merging the `origin/v4.1.x` branch into `master` to gain the new `projectm_pcm_add_float` optimizations.
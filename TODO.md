# Omni-Workspace Global TODO

> **Truth pass, 2026-11-19:** This list previously marked nearly every Visions of Chaos / FFM / ML item complete. Those items, if they exist at all, live in the **JWildfire submodule — not in this hub — and are UNVERIFIED from bobsaver**, whose pinned JWildfire master is currently a skeleton (8 `src/` files vs 2,137; see README Blocker). They are unchecked below until verified in that repo itself. Only hub/dashboard work verified in this repo's own handoff record stays checked. Duplicate Phase 3 scaffolding entries have been de-duplicated.
>
> The original preamble — "tasks for AI agents to execute autonomously without pausing" — is **withdrawn**. Owner-gated items (submodule merges, re-pins, sync.ps1) must not be auto-run.


## Immediate Tasks (Current Sprint)
- [x] **Git Synchronization Scripts:**
    - Create a robust `scripts/sync_all.py` (or PowerShell) to traverse `apophysis-j`, `BeatDrop`, `electricsheep`, `geiss`, `MilkDrop3`, `projectm` and merge `robertpelloni` AI branches automatically.
    - *Result:* Successfully merged AI feature branches in BeatDrop and projectm using `-X theirs`.
- [x] **LLM Instruction Normalization:**
    - Rewrite `CLAUDE.md`, `GEMINI.md`, `GPT.md`, and `copilot-instructions.md` in all repos to contain ONLY the single line: `> PLEASE READ docs/UNIVERSAL_LLM_INSTRUCTIONS.md`. Remove redundancy.
- [ ] **Visions of Chaos - Comprehensive Analysis:** UNVERIFIED — submodule claim, not hub code
    - Conduct deep-dive analysis of Softology's Visions of Chaos algorithms, revision history, and ML architecture.
    - *Result:* Documented in `JWildfire/VOC_ANALYSIS.md`. Updated `INTEGRATION_PLAN.md`.
- [ ] **Visions of Chaos - Cellular Automata Scaffold:** UNVERIFIED — submodule claim, not hub code
    - Create the `org.jwildfire.ca` package within the `JWildfire` submodule.
    - Implement a basic `CellularAutomataEngine` interface.
    - Port the standard 1D and 2D "Game of Life" ruleset as the first VoC integration proof-of-concept.
- [ ] **Visions of Chaos - Complex CA:** UNVERIFIED — submodule claim, not hub code
    - Implement the **Hodgepodge machine** (chemical reaction simulation) engine.
    - Implement **Cyclic CA** and **Multi-scale Turing Patterns**.
- [ ] **Visions of Chaos - 3D CA:** UNVERIFIED — submodule claim, not hub code
    - Implement the 3D version of the CA framework to support voxel-based simulations.
- [ ] **Visions of Chaos - Physarum:** UNVERIFIED — submodule claim, not hub code
    - Implement the Physarum (slime mold) network simulation.
- [ ] **Visions of Chaos - Strange Attractors:** UNVERIFIED — submodule claim, not hub code
    - Implement the Lorenz and Rossler attractor engines in `org.jwildfire.ca.math`.
- [ ] **Visions of Chaos - Reaction Diffusion:** UNVERIFIED — submodule claim, not hub code
    - Implement the Gray-Scott reaction-diffusion simulation.
- [ ] **Visions of Chaos - Boids:** UNVERIFIED — submodule claim, not hub code
    - Implement the flocking simulation using Reynolds' Separation/Alignment/Cohesion rules.
- [ ] **Visions of Chaos - 3D Hub:** UNVERIFIED — submodule claim, not hub code
    - Implement OBJ/MTL export for 3D CA and Attractors.
- [ ] **FFM Native Bridge Implementation (Geiss):** UNVERIFIED — submodule claim, not hub code
    - Examine `geiss/main.cpp` or equivalent entry point.
    - Expose `extern "C"` rendering functions for initialization and frame capture.
    - Create `GeissBinding.java` in `JWildfire/src/org/jwildfire/visualizer/geiss/`.

## Short Term tasks
- [x] Update `README.md` in root to point to the new `VISION.md` and `DASHBOARD.md`.
- [ ] Connect the new `AudioListener` Pub/Sub model in JWildfire to the existing Swing-based Music Visualizer to ensure backward compatibility during the JavaFX rewrite.
- [ ] **Visions of Chaos - 3D LBM:** UNVERIFIED — submodule claim, not hub code
    - Implement the 3D version of the Lattice Boltzmann fluid engine.
- [ ] Extract the local FFT processing code from `AudioCapture.java` into a standalone modular service so that it can be applied to recorded `.wav`/`.mp3` files (for `Easy Movie Maker`), not just live microphone inputs.

## Backlog / Needs Refactoring
- [ ] Re-examine the `JWildfire/src/org/jwildfire/transform/` package. Prepare it for the mass ingestion of `apophysis-j` fractal formulas. Create a mapping document to identify which formulas exist in both, and which are unique to Apophysis.
- [ ] The `projectm` submodule's upstream has released version 4.1.x. Evaluate merging the `origin/v4.1.x` branch into `master` to gain the new `projectm_pcm_add_float` optimizations. (Evaluated, huge merge conflicts, aborted for now to keep focus on VoC and JavaFX.)
- [ ] **FFM Native Bridge Implementation (MilkDrop3):** UNVERIFIED — submodule claim, not hub code
    - Create `MilkDropBinding.java` via Java 21 FFM.
    - Create native C++ stub `jw_md_bridge.cpp` to expose headless endpoints.
- [ ] **ML Orchestration Scaffolding (Phase 3):** UNVERIFIED — submodule claim, not hub code
    - Implement `PythonRPCBridge.java` to act as the communication layer with local Python virtual environments running Stable Diffusion / Audio generative tasks.
<!-- Truth pass 2026-11-19: an exact duplicate of this block appeared again below; removed. -->

- [ ] **Visions of Chaos - Particle Life (3D):** UNVERIFIED — submodule claim, not hub code
    - Implement the `ParticleLife3DEngine.java` to support particle interaction matrices in 3D space.

- [ ] **Visions of Chaos - Smoothed Particle Hydrodynamics (SPH):** UNVERIFIED — submodule claim, not hub code
    - Implement the `SPHEngine.java` to support 2D multiphase fluid simulation using SPH.

- [ ] **ML Orchestration Scaffolding (Phase 3):** UNVERIFIED — submodule claim, not hub code
    - Implement Python virtual environment manager (`PythonEnvironmentManager.java`) to handle the setup and lifecycle of `voc_base`, `voc_sd` environments from Java.

- [ ] **Video Interpolation Pipeline (Phase 3):** UNVERIFIED — submodule claim, not hub code
    - Integrate local video interpolation tools (FILM, RIFE) by creating `VideoInterpolationWrapper.java` using the `PythonEnvironmentManager` and `PythonRPCBridge` scaffolding to support Easy Movie Maker.

- [ ] **Audio & Speech Architecture (Phase 3):** UNVERIFIED — submodule claim, not hub code
    - Implement `SpeechGenerationWrapper.java` using `PythonEnvironmentManager` and `PythonRPCBridge` to interface with F5-TTS/Zonos.

- [ ] **Electric Sheep Network Revival (Phase 4):** UNVERIFIED — submodule claim, not hub code
    - Implement `DecentralizedClient.java` to handle NIO socket connections, polling for fractal rendering jobs, and submitting finished frame results to the tracking server.

- [ ] **Advanced ML Features:** UNVERIFIED — submodule claim, not hub code
    - Extend `StableDiffusionWrapper.java` to support "Real-time Latent Space Audio Reactivity" using FFT spectrum arrays to perturb generation parameters.

- [ ] **Advanced ML Features:** UNVERIFIED — submodule claim, not hub code
    - Implement `DatasetGenerator.java` to procedurally generate massive datasets of synthetic images and captions for fine-tuning custom SDXL/Flux LoRAs.

- [ ] **UI/UX Enhancements:**
    - Build an OpenXR bridge prototype (`OpenXRBridge.java`) to render 3D elements (Mandelbulbs, 3D CA) natively in VR/XR headsets via LWJGL.

- [x] **Dashboard (1.0.42):** consolidate all backend routes onto one value-ordered page; fix backend build (drop dead sqlite) and register pipeline/refactor/server routes so tray quit works.
- [ ] Build/run native submodules (projectm/MilkDrop3/geiss C++) and JWildfire hub; verify FFM bindings end-to-end.
- [ ] Add auth to read-only-but-sensitive scans if backend is ever exposed beyond localhost.

- [x] 1.0.43 synthesis: fail-closed auth, contract fixes, honest automation, unified shutdown, version/docs truth (see geiss/MANUAL.md). Open owner decisions: aios/fwber telemetry disposition, JWildfire/projectm merge/rebase resolution (do not run sync.ps1).

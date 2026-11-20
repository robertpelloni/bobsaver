# Omni-Workspace Global Roadmap

> **Truth pass, 2026-11-19:** Items that live in a submodule (chiefly JWildfire) are no longer marked complete in this hub. They are marked `[ ]` **UNVERIFIED — submodule claim, not hub code, not verified from bobsaver** until they are verified in that submodule repo itself. The duplicated, fully-checked copy of Phase 3 has been removed; Phase 3 is Planned, as its heading always said. FFM bridging is roadmap, not hub code (see `DASHBOARD.md`).

## Phase 1: Core Submodule Assimilation (In Progress)
- [x] **Git Monorepo Initialization:** Bring JWildfire, projectm, MilkDrop3, geiss, electricsheep, BeatDrop, and apophysis-j under a single root repo.
- [x] **AI Instruction Layer:** Create global `UNIVERSAL_LLM_INSTRUCTIONS.md` and link it to model-specific files (`CLAUDE.md`, `GEMINI.md`, `GPT.md`).
- [ ] **FFM Native Bridging Pipeline:** UNVERIFIED — submodule claims, not hub code
    - [ ] Create universal `AudioListener` and capture pipeline in JWildfire.
    - [ ] Implement `ProjectMBinding.java` mapping for `libprojectM`.
    - [ ] Create `geiss_ffi` headless texture extractor.
    - [ ] Create `milkdrop3_ffi` headless texture extractor.

## Phase 2: "Visions of Chaos" (VoC) Assimilation (In Progress)
We are adopting the massive computational library of *Visions of Chaos* (softology.pro) to transform JWildfire into the ultimate laboratory.

**All items in this phase: UNVERIFIED — claimed in the JWildfire submodule, not hub code, not verified from bobsaver, and JWildfire master is currently a skeleton (see README Blocker).**
- [ ] **Comprehensive Analysis:** Analyzed VoC's architecture, ML installer, and algorithmic catalog (documented in `JWildfire/VOC_ANALYSIS.md`).
- [ ] **Cellular Automata Engine:**
    - [ ] Port VoC's 1D and 2D CA rulesets into JWildfire `org.jwildfire.ca`.
    - [ ] Implement Hodgepodge (chemical reactions) and Multi-scale Turing Patterns.
    - [ ] Port 3D Cellular Automata (B56/S45 Moore 3D).
- [ ] **Agent-Based Modeling (ABM):**
    - [ ] Boids (Flocking) integration (Separation/Alignment/Cohesion).
    - [ ] Physarum (Slime Mold) network generation.
    - [ ] Particle Life simulations (2D/3D).
- [ ] **Fluid Dynamics (Grid & Particle):**
    - [ ] Port Lattice Boltzmann Method (LBM) D2Q9 simulations.
    - [ ] Implement Multiphase Smoothed Particle Hydrodynamics (SPH).
- [ ] **Fractals & Physics:**
    - [ ] Integrate Mandelbulb and Hypercomplex 3D/4D fractals into the `RaymarchingVisualizer`.
    - [ ] Add Strange Attractor (Lorenz, Rossler) visualizations.

## Phase 3: Machine Learning & Generative AI Orchestration (Planned)
Sourced from VoC's local execution philosophy, integrated directly into JWildfire's pipeline (requiring local GPU).
- [ ] **Hybrid Native Orchestration:**
    - [ ] Establish an ONNX Runtime or local Python RPC bridge to JWildfire. UNVERIFIED — submodule claim
    - [ ] Implement isolated virtual environments (following VoC's `voc_base`, `voc_sd` pattern) to manage model dependencies.
- [ ] **Text-to-Image / Video Pipeline:**
    - [ ] Integrate Stable Diffusion (SDXL/Flux/SD3.5) local inference.
    - [ ] Implement video interpolation (FILM, RIFE) for Easy Movie Maker.
- [ ] **Audio & Speech Architecture:**
    - [ ] Integrate MusicGen and Riffusion for procedural audio.
    - [ ] Implement F5-TTS / Zonos for high-quality speech.
<!-- Truth pass 2026-11-19: a duplicated copy of the three Phase 3 items above, with every box checked, previously appeared here and contradicted this section's "Planned" heading. It has been removed. The items above remain Planned / unchecked, except the single ONNX/RPC sub-item, which is a submodule claim and is UNVERIFIED from this hub. -->

## Phase 4: 3D Visualization Hub & Autonomous DJ
- [ ] **3D Visualization Hub:**
    - [ ] Implement high-quality OBJ/MTL export for all JWildfire and VoC generative outputs to bridge into professional renderers (Blender, Cinema 4D). UNVERIFIED — submodule claim, not hub code
- [ ] **Computer Vision Analysis:** AI agent running locally analyzes JWildfire's current frame and system audio to autonomously adjust chaos parameters.
- [ ] **Electric Sheep Network Revival:** Fully decentralized client/server for rendering hyper-complex VoC Mandelbulbs across the bobsaver node network.

## 1.0.43 status (historical)
Single-page dashboard, pure-Go backend (no sqlite/GORM/Fiber), fail-closed auth, honest simulation labelling. Next: owner-gated submodule merge resolution.

## 1.0.45 status (2026-11-19)
Truth pass only: README / VISION / ROADMAP / TODO / HANDOFF corrected to match the code that is actually here. No new capability. Blocker remains the JWildfire skeleton; owner-gated submodule merge resolution is still pending.

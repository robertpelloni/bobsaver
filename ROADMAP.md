# Omni-Workspace Global Roadmap

## Phase 1: Core Submodule Assimilation (In Progress)
- [x] **Git Monorepo Initialization:** Bring JWildfire, projectm, MilkDrop3, geiss, electricsheep, BeatDrop, and apophysis-j under a single root repo.
- [x] **AI Instruction Layer:** Create global `UNIVERSAL_LLM_INSTRUCTIONS.md` and link it to model-specific files (`CLAUDE.md`, `GEMINI.md`, `GPT.md`).
- [ ] **FFM Native Bridging Pipeline:**
    - [x] Create universal `AudioListener` and capture pipeline in JWildfire.
    - [x] Implement `ProjectMBinding.java` mapping for `libprojectM`.
    - [ ] Create `geiss_ffi` headless texture extractor.
    - [ ] Create `milkdrop3_ffi` headless texture extractor.

## Phase 2: "Visions of Chaos" (VoC) Assimilation (In Progress)
We are adopting the massive computational library of *Visions of Chaos* (softology.pro) to transform JWildfire into the ultimate laboratory.
- [x] **Comprehensive Analysis:** Analyzed VoC's architecture, ML installer, and algorithmic catalog (documented in `JWildfire/VOC_ANALYSIS.md`).
- [ ] **Cellular Automata Engine:**
    - [x] Port VoC's 1D and 2D CA rulesets into JWildfire `org.jwildfire.ca`.
    - [x] Implement Hodgepodge (chemical reactions) and Multi-scale Turing Patterns.
    - [x] Port 3D Cellular Automata (B56/S45 Moore 3D).
- [ ] **Agent-Based Modeling (ABM):**
    - [x] Boids (Flocking) integration (Separation/Alignment/Cohesion).
    - [x] Physarum (Slime Mold) network generation.
    - [ ] Particle Life simulations (2D/3D).
- [ ] **Fluid Dynamics (Grid & Particle):**
    - [x] Port Lattice Boltzmann Method (LBM) D2Q9 simulations.
    - [ ] Implement Multiphase Smoothed Particle Hydrodynamics (SPH).
- [ ] **Fractals & Physics:**
    - [ ] Integrate Mandelbulb and Hypercomplex 3D/4D fractals into the `RaymarchingVisualizer`.
    - [x] Add Strange Attractor (Lorenz, Rossler) visualizations.

## Phase 3: Machine Learning & Generative AI Orchestration (Planned)
Sourced from VoC's local execution philosophy, integrated directly into JWildfire's pipeline (requiring local GPU).
- [ ] **Hybrid Native Orchestration:**
    - [ ] Establish an ONNX Runtime or local Python RPC bridge to JWildfire.
    - [ ] Implement isolated virtual environments (following VoC's `voc_base`, `voc_sd` pattern) to manage model dependencies.
- [ ] **Text-to-Image / Video Pipeline:**
    - [ ] Integrate Stable Diffusion (SDXL/Flux/SD3.5) local inference.
    - [ ] Implement video interpolation (FILM, RIFE) for Easy Movie Maker.
- [ ] **Audio & Speech Architecture:**
    - [ ] Integrate MusicGen and Riffusion for procedural audio.
    - [ ] Implement F5-TTS / Zonos for high-quality speech.

## Phase 4: 3D Visualization Hub & Autonomous DJ
- [ ] **3D Visualization Hub:**
    - [ ] Implement high-quality OBJ/MTL export for all JWildfire and VoC generative outputs to bridge into professional renderers (Blender, Cinema 4D).
- [ ] **Computer Vision Analysis:** AI agent running locally analyzes JWildfire's current frame and system audio to autonomously adjust chaos parameters.
- [ ] **Electric Sheep Network Revival:** Fully decentralized client/server for rendering hyper-complex VoC Mandelbulbs across the bobsaver node network.

# Omni-Workspace Global Roadmap

## Phase 1: Core Submodule Assimilation (In Progress)
- [x] **Git Monorepo Initialization:** Bring JWildfire, projectm, MilkDrop3, geiss, electricsheep, BeatDrop, and apophysis-j under a single root repo.
- [x] **AI Instruction Layer:** Create global `UNIVERSAL_LLM_INSTRUCTIONS.md` and link it to model-specific files (`CLAUDE.md`, `GEMINI.md`, `GPT.md`).
- [ ] **FFM Native Bridging Pipeline:**
    - [x] Create universal `AudioListener` and capture pipeline in JWildfire.
    - [x] Implement `ProjectMBinding.java` mapping for `libprojectM`.
    - [ ] Create `geiss_ffi` headless texture extractor.
    - [ ] Create `milkdrop3_ffi` headless texture extractor.

## Phase 2: "Visions of Chaos" (VoC) Assimilation (Planned)
We are adopting the massive computational library of *Visions of Chaos* (softology.pro) to transform JWildfire into the ultimate laboratory.
- [ ] **Cellular Automata Engine:**
    - [ ] Port VoC's 1D, 2D, and 3D CA rulesets into JWildfire `org.jwildfire.ca`.
    - [ ] Implement Hodgepodge (chemical reactions) and Multi-scale Turing Patterns.
- [ ] **Agent-Based Modeling (ABM):**
    - [ ] Boids (Flocking) integration.
    - [ ] Physarum (Slime Mold) network generation.
    - [ ] Particle Life simulations.
- [ ] **Fluid Dynamics (Grid & Particle):**
    - [ ] Port Lattice Boltzmann Method (LBM) simulations.
    - [ ] Implement Multiphase Smoothed Particle Hydrodynamics (SPH).
- [ ] **Fractals & Physics:**
    - [ ] Integrate Mandelbulb and Hypercomplex 3D/4D fractals into the `RaymarchingVisualizer`.
    - [ ] Add pendulum (Double/Triple) and strange attractor visualizations.

## Phase 3: Machine Learning & Generative AI (Planned)
Sourced from VoC's local execution philosophy, integrated directly into JWildfire's pipeline (requiring local GPU).
- [ ] **Text-to-Image / Video Pipeline:**
    - [ ] Integrate Stable Diffusion (SDXL/Flux) local inference for fractal upscaling and texturing.
    - [ ] Implement Google Lumiere-style video interpolation for Easy Movie Maker.
- [ ] **Audio Reactivity Generation:**
    - [ ] Integrate local LLMs to autonomously write `.milk` preset code based on user prompt.
    - [ ] Integrate Kokoro / Bark for procedural Text-to-Speech generation.

## Phase 4: Autonomous "Vibe DJ" & Network
- [ ] **Computer Vision Analysis:** AI agent running locally analyzes JWildfire's current frame and system audio to autonomously adjust chaos parameters.
- [ ] **Electric Sheep Network Revival:** Fully decentralized client/server for rendering hyper-complex VoC Mandelbulbs across the bobsaver node network.

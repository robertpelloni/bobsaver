# Omni-Workspace Root Changelog

All notable changes to the root workspace and submodule architecture will be documented in this file.

## [1.0.31] - 2026-04-18

### Added
- **Audio Processing Architecture**:
    - Created `StandaloneAudioProcessor.java` in JWildfire's `org.jwildfire.visualizer` package. This extracts the core FFT computation and PCM float normalization logic away from the hardware-dependent `AudioCapture.java`. This modular service can now be injected into file-reading streams (like `.wav` or `.mp3` processing) to drive Native Visualizers offline, which is critical for the Easy Movie Maker pipeline.


## [1.0.28] - 2026-04-18

### Added
- **Machine Learning Orchestration (Phase 3)**:
    - Implemented `PythonEnvironmentManager.java` in JWildfire to manage isolated Python virtual environments (`voc_base`, `voc_sd`) dynamically. This utility ensures robust lifecycle management (creation, process control) of the external generative models without causing dependency conflicts on the host system.


## [1.0.25] - 2026-04-18

### Added
- **Machine Learning Orchestration (Phase 3)**:
    - Implemented `PythonRPCBridge.java` scaffolding in JWildfire's `org.jwildfire.ml` package to act as the foundational communication layer with local Python virtual environments running generative AI models (e.g., Stable Diffusion, audio generation).


## [1.0.23] - 2026-04-14

### Added
- **Visions of Chaos Integration (JWildfire)**:
    - Implemented **Smoothed Particle Hydrodynamics (SPH)** fluid simulation (`SPHEngine.java`) in `org.jwildfire.ca.fluid`. This provides a Lagrangian particle-based fluid solver as an alternative to the Eulerian grid-based LBM solver, fulfilling the VoC Fluid Dynamics roadmap.


## [1.0.22] - 2026-04-14

### Added
- **Apophysis-J Ingestion**:
    - Ported `julian` (`JulianFunc`) and `juliascope` (`JuliascopeFunc`) fractal variations from `apophysis-j` to JWildfire as `VariationFunc` implementations, continuing the Phase 1 fractal parity goal.


## [1.0.21] - 2026-04-14

### Added
- **Visions of Chaos Integration (JWildfire)**:
    - Implemented **Particle Life Engine (3D)** (`ParticleLife3DEngine.java`) in `org.jwildfire.ca.abm` to support particle interaction matrices in 3D continuous space, advancing the Agent-Based Modeling assimilation.


## [1.0.19] - 2026-04-03

### Added
- **MilkDrop3 Integration (Phase 1)**:
    - Created Java 21 FFM bridge `MilkDropBinding.java` in JWildfire to initialize and interact with a local `MilkDrop3` rendering instance.
    - Created `jw_md_bridge.cpp` stub in the `MilkDrop3` submodule to act as the `extern "C"` headless interface required by JWildfire.
- **Machine Learning Orchestration (Phase 3)**:
    - Created `PythonRPCBridge.java` scaffolding in JWildfire's `org.jwildfire.ml` package to communicate with local Python ML servers (e.g., Stable Diffusion, audio generation).

## [1.0.18] - 2026-04-03

### Added
- **Electric Sheep Integration (Phase 1)**:
    - Created Java 21 FFM bridge `ElectricSheepBinding.java` in JWildfire to initialize and interact with a local `electricsheep` rendering instance.
    - Created `jw_es_bridge.cpp` stub in the `electricsheep` submodule to act as the `extern "C"` headless interface required by JWildfire.


## [1.0.17] - 2026-04-03

### Added
- **Visions of Chaos Integration (JWildfire)**:
    - Implemented **Particle Life Engine (2D)** (`ParticleLifeEngine.java`) in `org.jwildfire.ca.abm` as part of the Agent-Based Modeling assimilation.


## [1.0.16] - 2026-04-02

### Added
- **Apophysis-J Ingestion**:
    - Ported `juliaN` (`JulianFunc`), `juliaScope` (`JuliascopeFunc`), and `gaussian_blur` (`GaussianblurFunc`) fractal variations from `apophysis-j` to JWildfire.
    - Updated `APOPHYSIS_MAPPING.md` to reflect the newly ported variations. This marks the conclusion of porting the major standard Apophysis variations.


## [1.0.15] - 2026-04-02

### Added
- **Apophysis-J Ingestion**:
    - Ported `eyefish`, `rings2`, `bubble`, `cylinder`, and `perspective` fractal variations from `apophysis-j` to JWildfire as `VariationFunc` implementations.
    - Updated `APOPHYSIS_MAPPING.md` to reflect the newly ported variations.


## [1.0.14] - 2026-04-02

### Added
- **Apophysis-J Ingestion**:
    - Ported `rings`, `fan`, `blob`, `pdj`, and `fan2` fractal variations from `apophysis-j` to JWildfire as `VariationFunc` implementations.
    - Updated `APOPHYSIS_MAPPING.md` to reflect the newly ported variations.


## [1.0.13] - 2026-04-02

### Added
- **Apophysis-J Ingestion**:
    - Ported `fisheye`, `popcorn`, `exponential`, `power`, and `cosine` fractal variations from `apophysis-j` to JWildfire as `VariationFunc` implementations.
    - Updated `APOPHYSIS_MAPPING.md` to reflect the newly ported variations.


## [1.0.12] - 2026-04-02

### Added
- **Apophysis-J Ingestion**:
    - Ported `hyperbolic`, `diamond`, `ex`, `julia`, and `bent` fractal variations from `apophysis-j` to JWildfire as `VariationFunc` implementations.
    - Updated `APOPHYSIS_MAPPING.md` to reflect the newly ported variations.


## [1.0.11] - 2026-04-02

### Added
- **Apophysis-J Ingestion**:
    - Ported `horseshoe`, `handkerchief`, `heart`, `disc`, and `spiral` fractal variations from `apophysis-j` to JWildfire as `VariationFunc` implementations.
    - Updated `APOPHYSIS_MAPPING.md` to reflect the newly ported variations.


## [1.0.10] - 2026-04-02

### Added
- **Visions of Chaos Integration (JWildfire)**:
    - Implemented 3D Lattice Boltzmann Method (D3Q19) fluid simulation (`LatticeBoltzmann3DEngine.java`).
    - Added 3D model exporters for Cellular Automata grids (`OBJExporter.java`) and Strange Attractors (`AttractorOBJExporter.java`).
- **Audio Processing Architecture**:
    - Refactored `AudioCapture` to extract FFT/PCM processing into a standalone `AudioProcessor` service, enabling support for both live mic input and recorded file processing (.wav/.mp3).
- **Geiss Integration**:
    - Created `GeissBinding.java` via the Java FFM API to bridge the Geiss native visualizer into JWildfire.
- **Apophysis-J Ingestion Planning**:
    - Created `APOPHYSIS_MAPPING.md` to document the overlap between Apophysis-J variations and JWildfire's `org.jwildfire.transform` package.

### Changed
- Evaluated merging ProjectM upstream `v4.1.x` into `master`, but postponed due to significant merge conflicts to maintain focus on VoC and JavaFX integration.


## [1.0.9] - 2026-04-02

### Added
- **Session Handoff**:
    - Created a comprehensive `JWildfire/HANDOFF.md` document summarizing the deep analysis of Visions of Chaos and the updated integration strategy.
    - Documented the roadmap for assimilating VoC's CA, ABM, and ML features into JWildfire.

## [1.0.8] - 2026-04-02

### Added
- **Visions of Chaos Integration**:
    - Conducted comprehensive analysis of Visions of Chaos features (ML, CA, ABM, Fluid Dynamics, Fractals).
    - Documented findings in `JWildfire/VOC_ANALYSIS.md`.
    - Updated `JWildfire/INTEGRATION_PLAN.md` with a dedicated phase for Visions of Chaos assimilation.
- **Documentation**:
    - Updated `VERSION.md` and `CHANGELOG.md` to reflect integration planning.

## [1.0.7] - 2026-04-01

### Added
- **Visions of Chaos Integration (JWildfire)**:
    - Implemented **Gray-Scott Reaction-Diffusion** engine in `org.jwildfire.ca`.
    - Added Laplacian computation kernel for 2D chemical reaction simulations.

## [1.0.6] - 2026-04-01

### Added
- **Visions of Chaos Integration (JWildfire)**:
    - Implemented **Physarum (Slime Mold)** simulation engine in `org.jwildfire.ca.abm`.
    - Implemented **Strange Attractor** library in `org.jwildfire.ca.math`:
        - **Lorenz Attractor** solver.
        - **Rossler Attractor** solver.

## [1.0.5] - 2026-04-01

### Added
- **Visions of Chaos Integration (JWildfire)**:
    - Implemented **Boids (Flocking)** simulation engine in `org.jwildfire.ca.abm`.
    - Added Agent-Based Modeling (ABM) package structure.

## [1.0.4] - 2026-04-01

### Added
- **Visions of Chaos Integration (JWildfire)**:
    - Implemented **3D Cellular Automata framework** (`CellularAutomata3DEngine`).
    - Implemented **3D Game of Life** engine (B56/S45 Moore 3D).

## [1.0.3] - 2026-04-01

### Added
- **Visions of Chaos Integration (JWildfire)**:
    - Implemented **Multi-scale Turing Patterns** CA engine based on Jonathan McCabe's algorithm.
- **Documentation**:
    - Created a comprehensive `README.md` for the root workspace, unifying the Vision, Project Structure, and Hub details.

## [1.0.2] - 2026-04-01

### Added
- **Visions of Chaos Integration (JWildfire)**:
    - Implemented a suite of complex Cellular Automata (CA) engines:
        - **Conway's Game of Life** (2D).
        - **Elementary CA** (1D Wolfram Rules).
        - **Hodgepodge Machine** (Chemical reaction simulation).
        - **Cyclic CA** (Spiral pattern generation).
    - Implemented **Lattice Boltzmann Method (LBM)** D2Q9 fluid dynamics solver in `org.jwildfire.ca.fluid`.
- **Automation & Sync**:
    - Created `scripts/sync_all.py`: A master synchronization script that recursively traverses all submodules, identifies AI-generated feature branches (copilot, wip, jules), and intelligently merges them into the primary branch (main/master) using `-X theirs` for conflict resolution.
- **Documentation**:
    - Normalized LLM instructions across all submodules to point to the universal root instructions.

### Changed
- **JWildfire Hub**:
    - Unified the `main` and `master` branches in JWildfire to resolve structural drift.
    - Fully transitioned the Music Visualizer to the new `AudioListener` Pub/Sub model for both JavaFX and Swing hybrid frames.

## [1.0.1] - 2026-04-01

### Added
- **Global Documentation Overhaul**:
    - Created `VISION.md`, `MEMORY.md`, `DEPLOY.md`, and `DASHBOARD.md`.
    - Defined the "Omni-Workspace Vision" and "Hybrid Native Orchestration" architectures.
    - Updated LLM Instruction protocol to reference `docs/UNIVERSAL_LLM_INSTRUCTIONS.md`.
- **Visions of Chaos Integration Roadmap**:
    - Analyzed Softology's Visions of Chaos features (Machine Learning, Cellular Automata, Fluid Dynamics, 3D/4D Fractals).
    - Integrated VoC assimilation into the long-term master `ROADMAP.md` and `TODO.md` for JWildfire.

### Changed
- **JWildfire Hub Pipeline**:
    - Centralized real-time FFT/PCM AudioCapture pipeline built into JWildfire.
    - Java 21 FFM API implementation finalized for bridging `projectM` native library to Java arrays.
    - Updated JWildfire version to 9.09.

## [1.0.0] - 2026-02-09

### Added
- Initial creation of the Bobsaver Monorepo.
- Added JWildfire, projectm, MilkDrop3, geiss, electricsheep, BeatDrop, and apophysis-j as git submodules.
- Established `docs/UNIVERSAL_LLM_INSTRUCTIONS.md` for AI cross-model continuity.

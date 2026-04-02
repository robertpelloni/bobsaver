# Omni-Workspace Root Changelog

All notable changes to the root workspace and submodule architecture will be documented in this file.

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

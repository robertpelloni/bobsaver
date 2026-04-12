# [PROJECT_MEMORY]

# Omni-Workspace (Bobsaver Monorepo) Memory & Architectural Analysis

## Overview
The Bobsaver project is a massive, multi-module monorepo built around **JWildfire** as the central hub. The vision is to transform JWildfire from a fractal flame editor into a universal laboratory for generative art, physics simulation, artificial life, and machine learning visualization.

This is achieved through the **"Visions of Chaos" (VoC) Assimilation Strategy**, wherein features, algorithms, and models from Softology's "Visions of Chaos" are ported directly into JWildfire's Java architecture, and via **Hybrid Native Orchestration**, wherein external native C/C++ visualizers (ProjectM, MilkDrop3, Geiss) are bridged into JWildfire via the Java 21 FFM (Foreign Function & Memory) API.

## Repository Structure (Submodules)
- **JWildfire**: The central Java hub (currently transitioning from Swing to JavaFX).
- **apophysis-j**: The original Java port of Apophysis. Its fractal variations are being mapped and ingested into JWildfire.
- **projectm**: A C++ cross-platform implementation of MilkDrop. Bridged via FFM.
- **MilkDrop3**: The DirectX-based successor to MilkDrop. Target for future bridging.
- **geiss**: The classic Geiss visualizer. Target for future bridging (FFM pipeline started).
- **BeatDrop**: A MilkDrop derivative.
- **electricsheep**: Distributed fractal rendering client. Target for decentralized networking.

## Core Architectural Patterns

### 1. Hybrid Native Orchestration (Java FFM Bridge)
To integrate legacy C++ visualization engines (like ProjectM and Geiss) without the overhead of JNI or the complexity of JNA, the project aggressively leverages the **Java 21 FFM API**.
- **Pattern**: A standard `XYZBinding.java` class is created for each native engine (e.g., `ProjectMBinding.java`, `GeissBinding.java`).
- **Mechanism**: The binding uses `Linker.nativeLinker()` and `SymbolLookup` to find C-exported functions (`extern "C"`).
- **Memory Management**: Off-heap memory is managed via `Arena` (`Arena.ofConfined()` or `Arena.ofAuto()`). The visualizer renders into an off-heap `MemorySegment`, which is then efficiently copied into a Java `int[]` array for display in a JavaFX `ImageView` or Swing `BufferedImage`.

### 2. Audio Pipeline (Pub/Sub)
JWildfire requires audio data (both raw PCM and frequency spectrum via FFT) to drive reactive parameters across multiple visualizers simultaneously.
- **Pattern**: A centralized, asynchronous Publisher/Subscriber model.
- **Mechanism**:
  - `AudioProcessor.java` handles the raw number-crunching (PCM normalization, FFT using JTransforms).
  - `AudioCapture.java` manages the microphone/line-in hardware stream and delegates bytes to the `AudioProcessor`.
  - Visualizers (like `ProjectMVisualizer` or native JWildfire components) implement `AudioListener`.
  - The `AudioProcessor` asynchronously broadcasts `pcmData` and `spectrumData` arrays to all registered listeners.

### 3. Visions of Chaos (VoC) Integration Framework
Softology's VoC contains thousands of isolated physics, CA, and ML scripts. The strategy is to rebuild these engines inside `JWildfire/src/org/jwildfire/ca/`.
- **Pattern**: Interface-driven simulation engines.
- **Architecture**:
  - `FluidEngine`: Implemented by `LatticeBoltzmannEngine` (D2Q9) and `LatticeBoltzmann3DEngine` (D3Q19).
  - `CellularAutomataEngine` / `CellularAutomata3DEngine`: Implemented by Game of Life, Hodgepodge, Turing Patterns, etc.
  - `AttractorEngine`: Implemented by Lorenz, Rossler, etc.
- **Design Rule**: Engines must be decoupled from the UI. They expose `step()` or `tick()` methods and provide raw state arrays (`getDensity()`, `getGridState()`) so that the JWildfire visualizer (Swing or JavaFX) can render them flexibly.

### 4. 3D Export Hub
Because JWildfire cannot natively render complex 3D scenes (like 3D Lattice Boltzmann fluids or 3D cellular automata) with modern raytracing out-of-the-box, it acts as a generator and exporter.
- **Pattern**: Static utility exporters in `org.jwildfire.ca.export`.
- **Mechanism**: `OBJExporter` and `AttractorOBJExporter` translate raw 3D array states or point trajectories into standard Wavefront OBJ/MTL formats. This allows users to generate complex geometry in JWildfire and render it in Blender, Cinema4D, or Unreal Engine.

### 5. Fractal Variation Extensibility
JWildfire generates fractals by chaining "Variations" (non-linear functions).
- **Pattern**: The `VariationFunc` abstract base class.
- **Mechanism**: Every variation (e.g., `ButterflyFunc`, `WhorlFunc`) extends `VariationFunc` (or `SimpleVariationFunc`). They must implement a `transform` method that takes an input `XYZPoint` and modifies it based on internal parameters.
- **Goal**: The project aims to achieve 100% parity with Apophysis-J by mapping (`APOPHYSIS_MAPPING.md`) and porting all missing variations into the JWildfire transform package.

## Development Rules & AI Coordination
- **`UNIVERSAL_LLM_INSTRUCTIONS.md`**: All submodules link to this central file to ensure AI agents (Claude, Gemini, GPT) behave consistently.
- **Documentation First**: AI agents must aggressively update `TODO.md`, `ROADMAP.md`, `CHANGELOG.md`, `VERSION.md`, and `HANDOFF.md` before concluding a sprint.
- **No Build Artifacts**: Agents must only edit source code, not generated files.
- **Incremental Commits**: Work should be committed frequently with descriptive messages.
- **Syncing**: The `scripts/sync_all.py` script exists to merge AI-generated branches across the monorepo automatically.

## Short-Term Trajectory
1. Complete the ingestion of `apophysis-j` fractal formulas. (We have ported 10 variations already).
2. Polish the JavaFX rewrite of JWildfire's UI.
3. Advance Phase 3: Establish local GPU execution for Generative AI (Stable Diffusion, MusicGen) orchestrated directly from JWildfire.

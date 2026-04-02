# Omni-Workspace Global Dashboard

This document tracks all the submodules inside the `bobsaver` repository, their versions, and their role within the Omni-Workspace ecosystem.

## Project Directory Structure
*   `bobsaver/`: The root Monorepo managing all submodules.
    *   `JWildfire/`: **The Central Hub**. All submodules are integrated into JWildfire via native FFM bindings or source-level Java integration.
    *   `apophysis-j/`: Legacy Java fractal flame editor.
    *   `BeatDrop/`: Audio-reactive visualizer and engine.
    *   `electricsheep/`: Distributed rendering client for fractal flames.
    *   `geiss/`: Classic Winamp visualizer engine.
    *   `MilkDrop3/`: Modernized MilkDrop visualizer engine.
    *   `projectm/`: Open-source cross-platform MilkDrop implementation.
    *   `docs/`: Global documentation and LLM instructions.
    *   `scripts/`: Centralized python/shell scripts for CI, merging, and syncing.

## Submodule Status & Versions

| Submodule | Role / Function | Integration Phase | Target Branch | Notes |
| :--- | :--- | :--- | :--- | :--- |
| **JWildfire** | Host Hub / JavaFX GUI | 3 (Hub) | `main` / `master` | Audio Capture and FFM pipeline initialized. |
| **apophysis-j** | Fractal Math | 2 (Source-level) | `master` | Java port. Algorithms to be mapped to `org.jwildfire.transform`. |
| **projectm** | MilkDrop Render Engine | 1 (FFM Native) | `master` | Working `ProjectMBinding.java` FFM bridge for Audio and OpenGL. |
| **MilkDrop3** | MilkDrop Render Engine | 1 (FFM Native) | `main` | C++ DX/GL wrapper. Needs headless texture extraction via FFM. |
| **geiss** | Geiss Render Engine | 1 (FFM Native) | `main` | C++ codebase. Requires DirectX/OpenGL refactor for texture sharing. |
| **BeatDrop** | Visualizer Engine | 1 (FFM Native) | `master` | C++ DX9. Requires FFM encapsulation. |
| **electricsheep** | Network / Render | 1 (FFM Native) | `master` | Java network layer implemented in JWildfire. C++ renderer needs FFM. |
| **Visions of Chaos** | ML / CA / Fractals | 4 (Hybrid Port) | *Planned* | Softology's massive toolset (1D/2D/3D Cellular Automata, ML). Target for deep integration. |

## Dashboard Metrics
*   **Last Updated**: April 2026
*   **Current Root Version**: 1.0.0
*   **Active Architect**: Gemini / Claude / GPT

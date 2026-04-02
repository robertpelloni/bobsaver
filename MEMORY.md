# Omni-Workspace Global Memory & Agent Observations

This file serves as the persistent memory bank for all AI models (Claude, Gemini, GPT, Jules) operating within the Bobsaver Omni-Workspace. It contains architectural preferences, established conventions, and historical observations.

## 1. Architectural Preferences & Conventions
*   **Java Version:** Target Java 21 LTS across the board, specifically leveraging Project Panama (Foreign Function & Memory API) (`--enable-preview` flag if necessary) for all native C/C++ integrations (MilkDrop, ProjectM, Geiss).
*   **UI Modernization:** JWildfire is shifting from legacy Swing (`JInternalFrame`) to a modern **JavaFX** (`JFXPanel`) hybrid model. All new UI panels, visualizers, and dashboards must be written in JavaFX via `.fxml` files.
*   **Native vs. Java (The FFM Rule):** Do NOT attempt to port massive legacy C++ engines to pure Java. Instead, encapsulate them as dynamic libraries (`.dll`, `.so`) and bridge them into JWildfire via FFM (`ProjectMBinding.java` pattern).
*   **Audio Capture Pipeline:** We use a centralized `AudioCapture.java` Pub/Sub model. Do NOT spawn redundant microphone recording threads; instead, implement `AudioListener` and tap into the universal `pcmData` and `spectrumData` (FFT) streams.
*   **No Code Left Behind:** The mandate is 100% feature parity. Even obscure sub-menus from Apophysis-J or niche cellular automata rules from Visions of Chaos must find a home in the JWildfire UI.
*   **Autonomy & Merging:** Default to aggressively maintaining and merging all AI-generated branches (`copilot-test`, `wip-*`, `jules-*`) into the `main` or `master` branches of their respective submodules. Prioritize retaining code/progress over discarding conflicts.

## 2. Historical Observations
*   **Visions of Chaos Integration (04/2026):** Identified as the next major horizon. VoC features extensive Machine Learning models, Cellular Automata, Fluid Dynamics, and 3D/4D fractals. The roadmap now involves porting its 1D/2D/3D CA libraries and Agent-Based models into the JWildfire host ecosystem.
*   **JWildfire Audio System (04/2026):** Migrated from disparate audio listeners to a universal audio loopback/microphone listener capable of real-time multi-threaded broadcast.
*   **Git Repository Structure:** Some submodules (`BeatDrop`, `electricsheep`, `apophysis-j`, `projectm`) heavily utilize `master` as their default branch. The root repo and `JWildfire` primarily use `main` and `master`. Careful attention is needed during recursive script operations to determine the correct default branch.

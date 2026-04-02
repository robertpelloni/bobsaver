# Omni-Workspace Deployment Instructions

This guide outlines the build, test, and deployment process for the entire Omni-Workspace and its integrated submodules.

## 1. Prerequisites
- **Java 21 LTS** or higher (required for FFM / Project Panama).
- **Gradle 8+** (for building JWildfire).
- **CMake & Ninja/MSVC** (for building the native C/C++ submodules like ProjectM, MilkDrop).
- **Git** (for submodule management).

## 2. Checking out the Code
When cloning for the first time, you must initialize all submodules:
```bash
git clone --recurse-submodules https://github.com/robertpelloni/bobsaver.git
cd bobsaver
```
If already cloned, synchronize the submodules:
```bash
git submodule update --init --recursive
```

## 3. Building Native Dependencies (Phase 1)
Before building JWildfire, the native visualizer engines must be compiled into dynamic shared libraries (`.dll`, `.so`, `.dylib`).
*Note: This process is being actively automated via CMake scripts in the root directory.*

### ProjectM / MilkDrop
```bash
cd projectm
cmake -B build -S . -D BUILD_SHARED_LIBS=ON
cmake --build build --config Release
```
Copy the resulting `projectM.dll` (or `.so`) into the `JWildfire/lib/native/` directory (or wherever `ProjectMBinding.java` expects it during runtime).

## 4. Building JWildfire (The Hub)
JWildfire acts as the universal host application.
```bash
cd JWildfire
./gradlew clean build --enable-preview
```

## 5. Running the Application
To run the fully integrated hub:
```bash
cd JWildfire
./gradlew run --enable-preview
```

## 6. Continuous Integration (CI/CD)
The root `.github/workflows/` directory contains automation for:
1. Auto-merging AI feature branches into `main`.
2. Building native libraries across Windows/Linux/macOS.
3. Compiling JWildfire and running JUnit test suites.
4. Packaging release artifacts (ZIPs containing JWildfire + all required `.dll`/`.so` bindings).

Always ensure that any newly integrated C++ submodule (e.g., Geiss, ElectricSheep C-core) is added to the cross-platform CMake build matrix in the CI pipeline.
# HMI_Mk1 — macOS Setup (Qt Creator)

A Qt/QML HMI prototype for a 12.3" Waveshare 1920×720 IPS touch display.  
Target resolution is **1920×720**, ideal for the in-car screen but scales to other displays.

---

## 0) Requirements

- macOS 12+ (Intel or Apple Silicon)
- Xcode Command Line Tools  
  ```bash
  xcode-select --install
  ```
- Git (included with Command Line Tools)

Optional for CLI builds:
```bash
brew install cmake ninja
```

---

## 1) Get Qt & Qt Creator

### Option A — Qt Online Installer (recommended)
1. Download from [qt.io/download](https://www.qt.io/download).
2. During installation, include:
   - **Qt 6.9.x (or newer)** → macOS
   - **Qt Quick Controls 2**
   - **Qt Quick Effects** *(if listed)*
   - **Qt Creator IDE**

### Option B — Homebrew
```bash
brew install --cask qt-creator
brew install qt
```

**Typical paths:**
- Apple Silicon: `/opt/homebrew/opt/qt`
- Intel: `/usr/local/opt/qt`

---

## 2) Clone the Project

```bash
git clone <your-repo-url> HMI_Mk1
cd HMI_Mk1
```

---

## 3) Open in Qt Creator

1. Launch **Qt Creator**.
2. **File → Open Project…** → select the `HMI_Mk1` folder.
3. Choose a kit:
   - **Qt 6.x for macOS (clang, arm64)** (Apple Silicon)
   - **Qt 6.x for macOS (clang, x86_64)** (Intel)
4. Click **Configure Project**.

If Qt was installed via Homebrew:
- Go to **Preferences → Qt Versions → Add…**
- Set qmake path:
  - Apple Silicon: `/opt/homebrew/opt/qt/bin/qmake`
  - Intel: `/usr/local/opt/qt/bin/qmake`

---

## 4) Configure CMake

If you installed Qt through the Qt Online Installer, Creator configures automatically.

If using **Homebrew Qt**, add this to **Projects → Build Settings → CMake → Initial Configuration**:
```
CMAKE_PREFIX_PATH:PATH=/opt/homebrew/opt/qt    # or /usr/local/opt/qt
```

---

## 5) QML Imports

The project imports:
```qml
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Effects
```

If Creator reports “module not installed,” verify where QML lives:

```bash
/opt/homebrew/bin/qtpaths --paths Qml2Imports
```

Add this to **Projects → Run → Environment** if needed:
```
QML2_IMPORT_PATH=/opt/homebrew/opt/qt/qml   # or /usr/local/opt/qt/qml
```

---

## 6) Build & Run

- Press **Run** (green triangle).
- App window: **1920×720**.
- Scales automatically on Retina/HiDPI displays.

Keyboard shortcut:
```
⌘Q — Quit (also works with Ctrl+Q on other systems)
```

---

## 7) Command-Line Build

```bash
cmake -S . -B build-macos -G Ninja   -DCMAKE_PREFIX_PATH=/opt/homebrew/opt/qt   -DCMAKE_BUILD_TYPE=Debug

cmake --build build-macos -v
./build-macos/appHMI_Mk1.app/Contents/MacOS/appHMI_Mk1
```

---

## 8) Display Setup (Waveshare 12.3”)

- Connect via HDMI or USB-C.
- Open **System Settings → Displays** → set to **1920×720**.
- App auto-scales to the display.

---

## 9) Troubleshooting

**Error:** `module QtQuick.Effects version 1.15 is not installed`  
→ Use versionless import (`import QtQuick.Effects`) or confirm it exists under `qt/qml/QtQuick/Effects/qmldir`.

**Error:** `Controls not found`  
→ Ensure **Qt Declarative** is installed.

**Error:** `No CMake configuration for build type 'Debug'`  
→ Add `-DCMAKE_BUILD_TYPE=Debug` and clean/reconfigure.

---

## 10) Project Structure

```
HMI_Mk1/
├─ CMakeLists.txt
├─ main.cpp
└─ Main.qml
```

---

## 11) Notes for Contributors

- Qt **≥ 6.9**
- QML imports are **versionless** for cross-platform compatibility.
- The interface is dark-themed and optimized for 1920×720.
- Follow `qmlformat` / `clang-format` before commits.

---

## License

_Add your license here._

# HMI_Mk1 — Windows (MSYS2 UCRT64) Setup with Qt Creator

A Qt/QML HMI prototype for a 12.3" Waveshare **1920×720** IPS touch display.  
Target resolution is **1920×720**; the UI scales on normal monitors, but this size matches the in-car panel.

---

## 0) Prereqs

- Windows 10/11
- **MSYS2** (recommended install path: `C:\msys64`)
- Optional: Qt Creator (latest) — or use CMake/Ninja from MSYS2 shell.

---

## 1) Install & update MSYS2

1. Download MSYS2: https://www.msys2.org  
2. Install to **`C:\msys64`** (recommended).  
3. Open **MSYS2 UCRT64** shell (Start Menu → “MSYS2 UCRT64”).
4. Update:
   ```bash
   pacman -Syu
   # if prompted to close/reopen, do it, then:
   pacman -Syu
   ```

---

## 2) Install toolchain, CMake/Ninja, Qt 6 (UCRT64)

Run in **UCRT64** shell:

```bash
# compilers, gdb, binutils...
pacman -S --needed mingw-w64-ucrt-x86_64-toolchain

# build tools
pacman -S --needed mingw-w64-ucrt-x86_64-cmake mingw-w64-ucrt-x86_64-ninja

# Qt 6 core bits (QML/Quick + engine)
pacman -S --needed mingw-w64-ucrt-x86_64-qt6-base mingw-w64-ucrt-x86_64-qt6-declarative

# optional but handy (qmake, assistant, designer, etc)
pacman -S --needed mingw-w64-ucrt-x86_64-qt6-tools

# optional fallback for legacy QML effects (Qt5Compat.GraphicalEffects)
pacman -S --needed mingw-w64-ucrt-x86_64-qt6-5compat
```

**Key Paths:**  
```
bin:   C:\msys64\ucrt64\bin
QML:   C:\msys64\ucrt64\share\qt6\qml
CMake: C:\msys64\ucrt64\lib\cmake
```

---

## 3) Clone the project

```bash
cd /c/where/you/keep/code
git clone <your-repo-url> HMI_Mk1
cd HMI_Mk1
```

---

## 4) Command-line build (sanity check)

```bash
setx QML2_IMPORT_PATH "C:\msys64\ucrt64\share\qt6\qml"

cmake -S . -B build-ucrt64 -G Ninja ^
  -D CMAKE_PREFIX_PATH="C:/msys64/ucrt64" ^
  -D CMAKE_BUILD_TYPE=Debug

cmake --build build-ucrt64 -v
./build-ucrt64/appHMI_Mk1.exe
```

---

## 5) Qt Creator — create MSYS2 UCRT64 Kit

**Qt Creator → Tools → Options → Kits → Add**

- **Compilers:**  
  C: `C:\msys64\ucrt64\bin\gcc.exe`  
  C++: `C:\msys64\ucrt64\bin\g++.exe`  

- **Debugger:** `C:\msys64\ucrt64\bin\gdb.exe`  
- **Qt version:** Add → `C:\msys64\ucrt64\bin\qmake6.exe`  
- **CMake Tool:** `C:\msys64\ucrt64\bin\cmake.exe`  
- **Generator:** Ninja  

**CMake Configuration:**  
```
-DCMAKE_PREFIX_PATH="C:/msys64/ucrt64"
-DCMAKE_BUILD_TYPE=Debug
```

**Run Environment:**  
```
QML2_IMPORT_PATH=C:/msys64/ucrt64/share/qt6/qml
```

---

## 6) QML imports used

```qml
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Effects   // versionless
```

If missing Effects, fallback to:
```qml
import Qt5Compat.GraphicalEffects 1.15
```

---

## 7) Target resolution & display

- Default window: **1920×720**
- Connect display via HDMI/USB-C, set to **1920×720** in Windows.

---

## 8) Troubleshooting

**“QtQuick.Effects version 1.15 not installed”** → use versionless import.  
**“Controls not found”** → verify CMAKE_PREFIX_PATH and QML2_IMPORT_PATH.  
**“No CMake configuration for build type Debug”** → delete build folder and reconfigure.

---

## 9) Project Structure

```
HMI_Mk1/
├─ CMakeLists.txt
├─ main.cpp
└─ Main.qml
```

---

## 10) Notes

- Qt ≥ 6.9  
- QML imports are versionless for compatibility.  
- UI is designed for Waveshare 12.3" 1920×720 panel.  

---

## License

_Add your license here._

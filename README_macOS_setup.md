Here’s a drop-in README.md you can put at the root of the repo. It’s written for macOS + Qt Creator and covers both the Qt Online Installer path (easiest) and Homebrew (works great too).

⸻

HMI_Mk1 — macOS Setup (Qt Creator)

A Qt/QML HMI prototype for a 12.3” Waveshare 1920×720 IPS touch display.
Target resolution is 1920×720; the UI runs on any screen, but that size matches the in-car panel.

0) Requirements
	•	macOS 12+ (Apple Silicon or Intel)
	•	Xcode Command Line Tools

xcode-select --install


	•	Git (comes with the tools above)

If you plan to use the command line (optional), also install:

brew install cmake ninja



⸻

1) Get Qt & Qt Creator

Option A — Qt Online Installer (recommended if you’re new to Qt)
	1.	Download the Qt Online Installer from qt.io and install Qt Creator.
	2.	In the component selector pick:
	•	Qt 6.9.x (or newer) → macOS
	•	Add-ons → Qt Quick Controls 2 (pulled in by Declarative),
Qt Quick Effects (for import QtQuick.Effects)
(If you don’t see “Quick Effects”, it ships with Declarative in newer Qt — you’ll still be fine.)

Option B — Homebrew (power users)

brew install --cask qt-creator
brew install qt

Homebrew installs Qt into /opt/homebrew/opt/qt on Apple Silicon
(or /usr/local/opt/qt on Intel).

⸻

2) Clone the project

git clone <your-repo-url> HMI_Mk1
cd HMI_Mk1


⸻

3) Open in Qt Creator and select a Kit
	1.	Qt Creator → Open Project… and select this folder.
	2.	When prompted for a kit, choose:
	•	“Qt 6.x for macOS (clang, arm64)” on Apple Silicon, or
	•	“Qt 6.x for macOS (clang, x86_64)” on Intel.
	3.	Click Configure Project.

If you installed Qt via Homebrew, you may need to add a Qt version:
Qt Creator → Preferences → Qt Versions → Add… and point to qmake:
	•	Apple Silicon: /opt/homebrew/opt/qt/bin/qmake
	•	Intel: /usr/local/opt/qt/bin/qmake

⸻

4) CMake configuration (what Creator will do)

The project already ships a standard CMakeLists. In most cases you don’t need to touch anything.

If you’re using Homebrew Qt, tell Creator where Qt lives:

Projects → Build Settings → CMake → Initial Configuration → Add

CMAKE_PREFIX_PATH:PATH=/opt/homebrew/opt/qt   # Intel: /usr/local/opt/qt

(Qt Online Installer kits don’t need CMAKE_PREFIX_PATH — Creator fills it in.)

⸻

5) QML imports (Controls & Effects)

This project imports:

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Effects   // versionless import recommended on macOS

	•	With Qt Online Installer, these are available automatically.
	•	With Homebrew, Creator sometimes needs the QML path at run time.

If you see “module … not installed”:
	1.	Find the QML import path:

/opt/homebrew/bin/qtpaths --paths Qml2Imports     # Intel: /usr/local/bin/qtpaths

	2.	In Projects → Run → Environment, add:

QML2_IMPORT_PATH=/opt/homebrew/opt/qt/qml    # Intel: /usr/local/opt/qt/qml

Tip: You can verify the module really exists:

ls /opt/homebrew/opt/qt/qml/QtQuick/Effects/qmldir
ls /opt/homebrew/opt/qt/qml/QtQuick/Controls/qmldir



⸻

6) Build & Run
	•	Run from the green triangle in Qt Creator.
	•	The app window is sized for 1920×720. On a 1080p/retina display it will scale; on the Waveshare panel it will match perfectly.

Keyboard
	•	⌘Q — quit (there’s also a Shortcut { sequence: "Ctrl+Q" } for cross-platform dev).

⸻

7) Command-line build (optional)

# Apple Silicon default paths shown below
cmake -S . -B build-macos -G Ninja \
  -DCMAKE_PREFIX_PATH=/opt/homebrew/opt/qt \
  -DCMAKE_BUILD_TYPE=Debug

cmake --build build-macos -v
./build-macos/appHMI_Mk1.app/Contents/MacOS/appHMI_Mk1


⸻

8) Connecting the Waveshare 12.3” (1920×720)
	•	Connect via HDMI/USB-C.
	•	In System Settings → Displays, set the external panel to 1920×720 (or to “Default for Display” if it auto-detects).
	•	The UI auto-scales, but the design target is 1920×720.

⸻

9) Project structure

HMI_Mk1/
├─ CMakeLists.txt        # Qt 6 Quick/Declarative project
├─ main.cpp              # Qt application entry
└─ Main.qml              # ApplicationWindow + layouts (left nav / center stage / right monitor)


⸻

10) Troubleshooting

❓ “module QtQuick.Effects … not installed”
	•	Use versionless import: import QtQuick.Effects
	•	Ensure the module exists:
	•	Online Installer: add Qt Quick Effects from MaintenanceTool (Add/Remove Components).
	•	Homebrew: check /opt/homebrew/opt/qt/qml/QtQuick/Effects/qmldir, then set QML2_IMPORT_PATH (see §5).

❓ “Controls 2” not found
	•	It lives under Qt Declarative in Qt 6. Ensure Qt 6 declarative is installed.
	•	On Homebrew, set QML2_IMPORT_PATH as in §5.

❓ Build can’t find Qt
	•	Make sure the kit is a Qt 6 for macOS (clang) kit.
	•	If using Homebrew Qt, set CMAKE_PREFIX_PATH=/opt/homebrew/opt/qt.

❓ Which QML path is Creator using?
	•	Run this in the terminal:

qtpaths --paths Qml2Imports || qtpaths6 --paths Qml2Imports



⸻

11) Notes for contributors
	•	Target Qt ≥ 6.9.
	•	UI uses Material Dark palette and a 1920×720 base size.
	•	Keep QML imports versionless on macOS to avoid minor-version mismatches.
	•	Please run clang-format/qmlformat before committing (optional).

⸻

12) License

Add your license here.

⸻

Appendix: What’s installed where (quick references)
	•	Qt Creator (Online Installer): /Applications/Qt Creator.app
	•	Qt (Online Installer): ~/Qt/6.x.x/macos
	•	Qt Creator (Homebrew): /Applications/Qt Creator.app (cask)
	•	Qt (Homebrew): /opt/homebrew/opt/qt (Apple Silicon) or /usr/local/opt/qt (Intel)
	•	QML path (Homebrew): /opt/homebrew/opt/qt/qml (or /usr/local/opt/qt/qml)

⸻

That’s it—paste this as README.md. If you want a second doc for Windows (MSYS2 UCRT64) mirroring what you just set up, I can generate one too.

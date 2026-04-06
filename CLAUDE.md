# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Dart** is a high-performance, modular desktop shell for Wayland compositors (Hyprland, MangoWM) built with **Quickshell** and QML. It provides a complete desktop environment with a sidebar/panel system, dashboard, app launcher, notifications, and system management tools.

- **Total QML code**: ~21,000 lines across 37 components
- **Framework**: Quickshell (QtQuick-based Wayland shell)
- **Language**: QML/JavaScript with some Python/bash helper scripts
- **Configuration**: JSON-based (colors.json) with Fuse GUI for editing

## Architecture

### Core Structure
- **shell.qml**: Main entry point containing `ShellRoot` that orchestrates all components
- **components/**: 37 QML components organized by feature (Dashboard, Launcher, Notifications, etc.)
- **qmldir**: Module definition exposing all components as `qs.components.*`
- **scripts/**: Helper scripts for system operations (audio, screenshots, package management)

### Key Components (by category)

**Main UI:**
- `Dashboard.qml` / `DashboardTab.qml`: Central hub with system metrics, weather, AI chat, quick toggles
- `SidePanel.qml`: Unified sidebar/panel that adapts to position (left/right/top/bottom)
- `AppLauncher.qml`: Full application launcher with search/filtering
- `CardStackOverlay.qml`: Card-based overlay (power menu, launcher cards, etc.)

**System Integration:**
- `WifiMenu.qml`: NetworkManager-based WiFi management
- `BluetoothMenu.qml`: BlueZ device management
- `VolumeSlider.qml`: PulseAudio/pipewire audio control
- `MangoWM.qml`: Window manager provider for Hyprland/MangoWM

**Overlays:**
- `LockScreen.qml`: Custom lockscreen with media controls
- `NotificationDisplay.qml`: D-Bus notification center
- `WorkspaceOverview.qml`: Workspace grid switcher
- `CaptureMenu.qml`: Screenshot/region capture
- `AiChatMenu.qml`: Ollama-powered local LLM chat

**Utilities:**
- `ProcessHelper.qml`: Wrapper for executing shell commands
- `Utils.qml`: Shared utility functions
- `RightEdgeDetector.qml` / `TopEdgeDetector.qml`: Edge hover triggers
- `SkeletonLoader.qml`: Loading state placeholder

### Data Flow

1. **Configuration**: `~/.config/alloy/colors.json` loaded on startup, controls theme, layout, and behavior
2. **Command execution**: Components use `ProcessHelper` (defined in shell.qml's `sharedData.runCommand`) to run scripts
3. **UI communication**: `sharedData` object in shell.qml (QtObject) holds global state (visibility flags, system status, etc.)
4. **External scripts**: `/tmp/quickshell_command` file used for inter-process communication (shell scripts can trigger UI changes)

## Development Setup

### Prerequisites
- **Quickshell** (built from source, latest master)
- Wayland compositor: Hyprland or MangoWM
- Optional dependencies: `playerctl`, `cava`, `grim`, `slurp`, `networkmanager`, `bluez`, `pactl`, `ollama`, `zenity`

### Running the Shell
```bash
# From project root
./run.sh
```

This sets environment variables (QUICKSHELL_PROJECT_PATH, QT_SCALE_FACTOR based on colors.json) and executes `quickshell`.

### Helper Scripts
```bash
./toggle-menu.sh          # Toggle dashboard visibility
./open-launcher.sh        # Show app launcher
./open-clipboard.sh       # Show clipboard manager
./open-overview.sh        # Show workspace overview
./open-settings.sh        # Open settings (Fuse)
```

### Installation
```bash
./install.sh              # Sets up config dir, checks dependencies, chmod +x scripts
```

## Testing
- `test_window.qml`: Minimal QML file to verify Quickshell is working (red panel test)
- Run with: `quickshell --path /path/to/dart --test test_window.qml`

No formal unit test framework exists; testing is manual/integration via the running shell.

## Configuration

### colors.json Schema (in ~/.config/alloy/)
Key properties:
- Colors: `background`, `primary`, `secondary`, `text`, `accent`
- Layout: `sidebarPosition` ("left"/"right"/"top"/"bottom"), `sidebarStyle` ("dots"/"lines"), `floatingDashboard` (bool)
- Behavior: `uiScale` (75/100/125), `lowPerformanceMode` (create `~/.config/alloy/low-perf` file)
- Dashboard: `dashboardPosition` ("right"/"left"/"top"/"bottom"), `dashboardResource1` ("cpu"/"ram"/"gpu"/"network")
- Features: `lockscreenMediaEnabled`, `weatherLocation`, `notificationPosition`, `notificationRounding`

The `save-colors.py` script writes changes; Fuse GUI is the recommended editor.

## Code Patterns

### Adding a New Component
1. Create `MyComponent.qml` in components/
2. Add to `qmldir`: `MyComponent 1.0 MyComponent.qml`
3. Import in other QML: `import qs.components`
4. If global state needed, add property to `sharedData` in shell.qml

### Running System Commands
Use the `runCommand` function from sharedData:
```qml
if (sharedData && sharedData.runCommand) {
    sharedData.runCommand(['sh', '-c', 'your-command-here'])
}
```

### Persisting State
Global state belongs in `sharedData` (shell.qml). Component-local state should use `Component.onDestruction` or persistent properties.

### Script Output
Scripts that produce output for QML should write to `/tmp/` and have QML read via XMLHttpRequest (file:// URL). Example: `scripts/get-apps.py` -> `/tmp/alloy_apps.json`.

## Important Files

- **shell.qml**: Core orchestrator, global state (`sharedData`), overlays, and command routing
- **components/qmldir**: Module registration - update when adding/removing components
- **colors.json**: User configuration (not committed, created by install.sh)
- **.opencode/package.json**: OpenCode plugin dependencies (for IDE integration)
- **.opencode/plans/**: Feature implementation plans (detailed technical specs)

## Git Workflow

- Main branch: `main`
- Commit style: Concise, imperative messages (e.g., "add launcher flip animation", "fix volume slider persistence")
- Recent activity: Card stack animations, launcher integration, edge detectors

## Known Areas of Active Development

- CardStackOverlay.qml: Recently refactored for power menu and launcher card animations
- Launcher integration: Moving from separate LauncherCardOverlay into CardStackOverlay
- RightEdgeDetector.qml / TopEdgeDetector.qml: Edge hover triggers for sidebar

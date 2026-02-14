# Dart (Alloy Shell)

**A performance-focused desktop shell for Quickshell & Wayland**

[![Quickshell](https://img.shields.io/badge/Quickshell-Compatible-00D9FF?style=flat-square&logo=qt)](https://github.com/Quickshell/Quickshell)
[![Wayland](https://img.shields.io/badge/Wayland-Supported-FF6B6B?style=flat-square&logo=wayland)](https://wayland.freedesktop.org/)

Dart provides a fluid UI with integrated system monitoring and deep customization via the Fuse App.

---

## 🖼️ Showcase

<p align="center">
  <img src="showcase/showcase.png" width="800" alt="Dart Desktop Shell"/>
</p>

---

## 🚀 Key Features

- **Unified Sidebar & Top Bar**: Toggle between positions with real-time scaling and auto-hide on fullscreen.
- **Dynamic Dashboard**:
    - **System Monitoring**: Real-time CPU, RAM, and GPU telemetry.
    - **Network**: Accurate upload and download traffic monitoring.
    - **Weather**: Integrated real-time weather status (wttr.in).
    - **GitHub Activity**: Scraped contribution graph.
    - **Calendar**: Integrated monthly view.
- **Lock Screen**:  minimalist overlay with integrated password verification.
- **Audio Control**: Granular per-device volume management (Sinks & Sources).
- **Smart Launcher**: Application filtering with math calculation (`= 2+2`) and web search shortcuts (`!y`, `!g`, `!r`).
- **Clipboard Manager**: History tracking with smart deduplication and instant copy-back.
- **Media Controls**: Integrated playback control, metadata display, and **cava** audio visualization.
- **Notification Center**: D-Bus compliant notifications with history and urgency-based styling.

---

## 🛠️ Requirements

- **Quickshell** (Latest master recommended)
- **DE/WM**: Tested **only** on **Hyprland**.
- **Fuse Suite**: Required for settings and system integration. [Repo](https://github.com/artwik22/fuse)

### Optional Dependencies
- `cava`: Audio visualization.
- `playerctl`: Media tracking and control.
- `grim` + `slurp`: Screenshot functionality.
- `pactl`: Audio management.

---

## 📦 Installation

```bash
mkdir ~/.config/alloy
git clone https://github.com/artwik22/dart.git ~/.config/alloy/dart
cd ~/.config/alloy/dart
./run.sh
```

### ⌨️ Hyprland Bindings
Add these to your `hyprland.conf`:
```ini
bind = SUPER, R, exec, ~/.config/alloy/dart/open-launcher.sh
bind = SUPER, M, exec, ~/.config/alloy/dart/toggle-menu.sh
bind = SUPER, V, exec, ~/.config/alloy/dart/open-clipboard.sh
```

---

## 🔧 Customization

Primary customization is managed through the **Fuse** application. Available options include:
- **Design System**: Switch between **20+ curated color presets** or define custom HEX colors.
- **UI Layout**:
    - **Floating Dashboard**: Toggle between classic and modern floating styles.
    - **Sidebar Position**: Pinned to any edge (Left/Right/Top/Bottom).
    - **Resource Config**: Choose which (CPU, RAM, GPU, Net) to show on primary cards.
- **Behavior**:
    - **UI Scaling**: Adjust the interface scale (75%, 100%, 125%).
    - **Performance**: Enable Low Performance mode to optimize for older hardware.
    - **Notifications**: Global toggle for D-Bus notifications and sound alerts.

<details>
<summary><b>Manual Configuration</b></summary>

Edit `~/.config/alloy/colors.json` directly for manual tweaks:
- `uiScale`: `75`, `100`, or `125`.
- `lowPerformanceMode`: `true` to disable heavy animations.
- `floatingDashboard`: `true` for modern floating look.
- `sidebarPosition`: `"left"`, `"top"`, `"right"`, or `"bottom"`.
- `sidepanelContent`: `"calendar"` or `"github"`.
- `dashboardTileLeft`: `"battery"` or `"network"`.
- `dashboardResource1/2`: `"cpu"`, `"ram"`, `"gpu"`, or `"network"`.
- `quickshellBorderRadius`: UI rounding radius (integer).
- `weatherLocation`: Location for weather data.
- `accent`: HEX value for the primary accent color.

</details>

---

## 🤝 Acknowledgments
- [Quickshell](https://github.com/Quickshell/Quickshell) - The core engine.
- [cava](https://github.com/karlstav/cava) - Audio visualization.

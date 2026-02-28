# Dart (Alloy Shell)

**A blazing-fast, highly modular desktop shell for Wayland.**

[![Quickshell](https://img.shields.io/badge/Quickshell-Compatible-00D9FF?style=flat-square&logo=qt)](https://github.com/Quickshell/Quickshell)
[![Wayland](https://img.shields.io/badge/Wayland-Supported-FF6B6B?style=flat-square&logo=wayland)](https://wayland.freedesktop.org/)

Dart transforms your Wayland desktop into a modern, fully-featured environment. It seamlessly integrates live system telemetry, native network & audio management, and a stunning, highly customizable UI—all with uncompromising performance.

---

## 🖼️ Showcase

<p align="center">
  <img src="showcase/showcase.png" width="800" alt="Dart Desktop Shell"/>
</p>

---

## 🚀 Key Features

- **Unified Sidebar & Top Bar**: Toggle between positions with real-time scaling and auto-hide on fullscreen.
- **Tabbed Dashboard**:
    - **Dashboard**: Quick system overview, weather, and basic controls.
    - **Clipboard**: History tracking with smart deduplication and instant copy-back.
    - **Notifications**: D-Bus compliant center with history and urgency-based styling.
    - **Performance**: Real-time CPU, RAM, GPU, and Network graphs with historical tracking.
- **System Management**:
    - **WiFi**: Integrated scanner and connection manager (nmcli-based).
    - **Bluetooth**: Device discovery, pairing, and connection management.
    - **Audio**: Granular per-device volume management (Sinks & Sources).
- **Smart Launcher**: Application filtering with math calculation (`= 2+2`) and web search shortcuts (`!y`, `!g`, `!r`).
- **Lock Screen**: Minimalist overlay with password verification, media controls, and widget toggles.
- **Media Controls**: Playback control, metadata display, and **cava** audio visualization.

---

## 🛠️ Requirements

- **Quickshell** (Latest master recommended)
- **DE/WM**: Tested **only** on **Hyprland**.
- **Fuse**: Required for settings and system integration. [Repo](https://github.com/artwik22/fuse)

### Optional Dependencies
- `cava`: Audio visualization.
- `playerctl`: Media tracking and control.
- `grim` + `slurp`: Screenshot functionality.
- `pactl`: Audio management.
- `networkmanager`: WiFi management.
- `bluez`: Bluetooth management.

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
- **Design System**: 23+ curated color presets (Dark, Ocean, Forest, Violet, Crimson, etc.) or custom HEX colors.
- **UI Layout**:
    - **Floating Dashboard**: Toggle between classic and modern floating styles.
    - **Sidebar Position**: Pinned to any edge (Left/Right/Top/Bottom).
    - **Sidebar Style**: Choose between `dots` or `lines` indicators.
    - **Workspace Mode**: `top`, `center`, or `bottom` alignment.
- **Behavior**:
    - **UI Scaling**: Adjust the interface scale (75%, 100%, 125%).
    - **Performance**: Low Performance mode to optimize for older hardware.
    - **Notifications**: Global toggle, position control (`top-right`, `top-left`, etc.), and rounding (`pill`, `standard`, `none`).

<details>
<summary><b>Manual Configuration (colors.json)</b></summary>

Edit `~/.config/alloy/colors.json` for granular tweaks:
- `uiScale`: `75`, `100`, or `125`.
- `sidebarPosition`: `"left"`, `"top"`, `"right"`, or `"bottom"`.
- `sidebarStyle`: `"dots"` or `"lines"`.
- `sidebarWorkspaceMode`: `"top"`, `"center"`, or `"bottom"`.
- `quickshellBorderRadius`: Integer value for global UI rounding.
- `notificationPosition`: `"top-right"`, `"top-left"`, `"top"`, `"bottom-right"`, `"bottom-left"`, `"bottom"`.
- `notificationRounding`: `"none"`, `"standard"`, `"pill"`.
- `lockscreenMediaEnabled`: `true`/`false`.
- `weatherLocation`: Location for wttr.in data.
- `accent`: HEX value for the primary accent color.

</details>

---

## 🤝 Acknowledgments
- [Quickshell](https://github.com/Quickshell/Quickshell) - The core engine.
- [cava](https://github.com/karlstav/cava) - Audio visualization.

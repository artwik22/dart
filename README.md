# Dart (Alloy Shell)

<div align="center">

**A premium, high-performance desktop shell for Quickshell & Wayland**

[![Quickshell](https://img.shields.io/badge/Quickshell-Compatible-00D9FF?style=for-the-badge&logo=qt)](https://github.com/Quickshell/Quickshell)
[![Wayland](https://img.shields.io/badge/Wayland-Supported-FF6B6B?style=for-the-badge&logo=wayland)](https://wayland.freedesktop.org/)
[![License](https://img.shields.io/badge/License-MIT-green.svg?style=for-the-badge)](LICENSE)

*Dart is a modern, animation-focused shell environment built on Quickshell. It features a fluid UI, integrated system monitoring, and deep customization through a unified design system.*

</div>

---

## 🚀 Key Features

### 🖥️ Shell Components
- **Unified Sidebar & Top Bar**: Toggle between positions with real-time scaling and smooth transitions.
- **Dynamic Dashboard**: 
    - **System & Weather**: Current conditions, system uptime, and hardware specs.
    - **Performance Monitoring**: Real-time CPU, RAM, and GPU graphs.
    - **Calendar**: integrated monthly view.
    - **GitHub Activity**: Scraped contribution graph visualization.
- **Smart App Launcher**: Category-based filtering, web search shortcuts (`!y`, `!g`, `!r`), and a built-in calculator.
- **Clipboard Manager**: History tracking with smart deduplication and instant copy-back.
- **Media Controller**: Elegant playback controls with blurred album art and audio visualization.
- **Notification Center**: D-Bus compliant notifications with urgency-based styling and smooth exit animations.

### 🎨 Design & Performance
- **Premium Aesthetics**: Glassmorphism effects, variable border radii (0-25px), and curated color palettes.
- **Micro-animations**: Spring-based physics for modals and hover-scaling for interactive elements.
- **ProcessHelper Integration**: Highly efficient external command execution for minimal system overhead.
- **Native Wallpaper System**: Per-screen wallpaper management with high-resolution previews.

> [!IMPORTANT]
> **Fuse Integration**: Several core features including the **Settings Application**, **System Controls**, and **Advanced Theming** require the [Fuse](https://github.com/artwik22/fuse) suite to be installed and accessible in your PATH.

---

## 🛠️ Requirements

- **Quickshell** (Latest master recommended)
- **Wayland Compositor** (Optimized for Hyprland)
- **Fuse Suite** (Required for settings and system integration) [Repo](https://github.com/artwik22/fuse)

### Optional Dependencies
- `cava` (Audio visualizer)
- `playerctl` (Media tracking)
- `grim` + `slurp` (Screenshots)

---

## 📦 Installation

### Standard Setup
```bash
git clone https://github.com/artwik22/sharpshell.git ~/.config/alloy/dart
cd ~/.config/alloy/dart
chmod +x run.sh toggle-menu.sh open-launcher.sh
./run.sh
```

### Compositor Integration (Hyprland)
Add these to your `hyprland.conf`:
```ini
bind = SUPER, R, exec, ~/.config/alloy/dart/open-launcher.sh
bind = SUPER, M, exec, ~/.config/alloy/dart/toggle-menu.sh
bind = SUPER, V, exec, ~/.config/alloy/dart/open-clipboard.sh
```

---

## 📁 Project Structure

- `shell.qml`: Main entry point and layout definition.
- `components/`: Modular QML components (Dashboard, Launcher, Sidebar, etc.).
- `scripts/`: Helper scripts for CAVA, screenshots, and system updates.
- `colors.json`: Centralized configuration for themes, scaling, and behavior.

---

## 🔧 Customization

Dart's behavior can be tuned in `colors.json` or through the integrated settings:
- **UI Scaling**: 75%, 100%, 125%.
- **Theme Engine**: 24+ curated presets or custom HEX values.
- **Performance Mode**: Toggle animations for lower-end hardware.

---

## 📜 License
Distributed under the MIT License.

## 🤝 Acknowledgments
- [Quickshell](https://github.com/Quickshell/Quickshell) - The core engine.
- [cava](https://github.com/karlstav/cava) - Audio visualization.

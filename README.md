# 🚀 SharpShell

<div align="center">

**A modern, beautiful, and highly customizable shell/launcher system for Quickshell with full Wayland support**

[![Quickshell](https://img.shields.io/badge/Quickshell-Compatible-00D9FF?style=for-the-badge&logo=qt)](https://github.com/Quickshell/Quickshell)
[![Wayland](https://img.shields.io/badge/Wayland-Supported-FF6B6B?style=for-the-badge&logo=wayland)](https://wayland.freedesktop.org/)
[![License](https://img.shields.io/badge/License-MIT-green.svg?style=for-the-badge)](LICENSE)
[![QML](https://img.shields.io/badge/QML-5.15+-FF6B9D?style=for-the-badge&logo=qt)](https://www.qt.io/)

*Features smooth animations, intuitive navigation, and powerful system integration*

</div>

---

## 📑 Table of Contents

- [✨ Features](#-features)
  - [🎯 Application Launcher](#-application-launcher)
  - [📊 Dashboard](#-dashboard)
  - [🎨 Side Panel](#-side-panel)
  - [📋 Clipboard Manager](#-clipboard-manager)
  - [🔔 Notification System](#-notification-system)
  - [🖼️ Wallpaper Management](#️-wallpaper-management)
- [📋 Requirements](#-requirements)
- [🛠️ Installation](#️-installation)
- [🎮 Usage](#-usage)
- [📁 Project Structure](#-project-structure)
- [🎨 Customization](#-customization)
- [🔧 Configuration](#-configuration)
- [🐛 Troubleshooting](#-troubleshooting)
- [📝 License](#-license)
- [🤝 Contributing](#-contributing)

---

## ✨ Features

### 🎯 Application Launcher

| Feature | Description |
|---------|-------------|
| 🔍 **Fast Search** | Real-time filtering of applications |
| 🌐 **Web Search** | Multiple search engines via prefixes: `!` (DuckDuckGo), `!w` (Wikipedia), `!r` (Reddit), `!y` (YouTube) |
| 🧮 **Calculator** | Type `=` followed by a math expression for instant calculations |
| ⌨️ **Keyboard Navigation** | Full arrow key support with smooth navigation |
| 🎬 **Smooth Animations** | Beautiful transitions and hover effects |
| 📦 **Package Management** | Install/remove packages via Pacman and AUR |
| ⚙️ **Settings Panel** | Customize wallpaper, colors, toggle sidebar, and system updates |
| 🎨 **24 Color Presets** | Beautiful pre-made themes to choose from |
| 🖌️ **Custom Colors** | Edit HEX values for complete customization |

### 📊 Dashboard

A comprehensive system dashboard with multiple tabs and real-time monitoring.

#### Dashboard Tab
- 🌤️ **Weather Display** - Current temperature and conditions with weather icons
- 🐧 **System Information** - OS info, uptime, and system stats with Linux icon
- 📅 **Calendar View** - Large date display with monthly calendar grid
- 📈 **Resource Monitoring** - Real-time CPU, RAM, and GPU usage with animated vertical bars
- 🎵 **Media Player Control** - Play, pause, skip tracks with album art and track information

#### Media Tab
- 🎵 **Media Player** - Full-featured media player with album art and controls
- 🎨 **Audio Visualizer** - Real-time Cava visualizer spanning the entire width with dimmed background

#### Performance Tab
- 💻 **Resource Cards** - Detailed CPU, RAM, and GPU monitoring with horizontal progress bars and temperatures
- 💾 **Disk Usage** - Real-time disk space monitoring for multiple partitions
- 🔥 **Top Processes** - Live view of top resource-consuming processes with CPU and memory usage



### 🎨 Side Panel

- 🎵 **Audio Visualizer** - Real-time audio visualization with cava
- 🔊 **Volume Control** - Adjust system volume with interactive slider (hover right edge to show)
- 📶 **Bluetooth Control** - Toggle Bluetooth on/off
- 📋 **Clipboard Manager** - Access clipboard history with a button below the visualizer
- 🕐 **Clock Display** - Current time and date
- 🎨 **Modern Design** - Clean, minimal interface
- 👁️ **Toggle Visibility** - Show/hide sidebar from Launcher Settings

### 📋 Clipboard Manager

- 📜 **History Tracking** - Automatically tracks clipboard changes (up to 50 items)
- 🔄 **Smart Deduplication** - Moves duplicate items to the top instead of creating duplicates
- 🖱️ **Click to Copy** - Click any item to copy it back to clipboard
- 🗑️ **Clear History** - Button to clear all clipboard history
- ⌨️ **Keyboard Support** - Press `Escape` to close
- 🎨 **Theme Integration** - Matches your color scheme

### 🔔 Notification System

- 📢 **Desktop Notifications** - Full support for D-Bus notifications
- 🎨 **Modern Design** - Beautiful notifications with smooth slide-in/out animations
- ⏱️ **Auto-Dismiss** - Notifications automatically disappear after 5 seconds
- 🖱️ **Interactive** - Click to dismiss or use the close button
- 📊 **Progress Indicator** - Visual progress bar showing time until auto-dismiss
- 🎯 **Top-Right Positioning** - Notifications appear in the top-right corner, stacking vertically
- 🎭 **Urgency Support** - Different colors for normal, low, and critical notifications

### 🖼️ Wallpaper Management

- ✅ **Native Quickshell Integration** - Set wallpapers directly through Quickshell (no external tools required!)
- 🖼️ **Visual Grid** - Browse wallpapers in a beautiful grid layout
- 👁️ **Quick Preview** - Hover effects for easy selection
- 🎬 **Smooth Transitions** - Fade animations when changing wallpapers
- 🖥️ **Multi-Screen Support** - Automatic synchronization across all screens
- 🔄 **Fallback Support** - Optional support for swww, wbg, and hyprpaper
- 📐 **Dynamic Layout** - Auto-adjusting grid with smooth animations

---

## 📋 Requirements

### Required

| Component | Description |
|-----------|-------------|
| **Quickshell** | QML-based shell system |
| **Wayland Compositor** | Tested with Hyprland |

### Optional (for additional features)

| Tool | Purpose |
|------|---------|
| `cava` | Audio visualizer (for side panel and Dashboard Media tab visualization) |
| `playerctl` | Media player control (for Dashboard media controls) |
| `pactl` | PulseAudio volume control (for volume slider) |
| `bluetoothctl` | Bluetooth management (for Bluetooth controls) |
| `nvidia-smi` or `radeontop` | GPU monitoring (for Dashboard GPU usage display) |
| `sensors` | Hardware temperature monitoring (for CPU/GPU temperature display) |
| `swww`, `wbg`, or `hyprpaper` | External wallpaper tools (optional fallback) |

> **Note:** Native Quickshell wallpaper system works without external tools!

---

## 🛠️ Installation

### 1. Clone the Repository

```bash
git clone https://github.com/artwik22/sharpshell.git ~/.config/sharpshell
cd ~/.config/sharpshell
```

### 2. Make Scripts Executable

```bash
chmod +x scripts/*.sh
chmod +x *.sh
```

### 3. Configure Quickshell

Make sure Quickshell is configured to use `shell.qml` as the main configuration file. The path should point to:

```
~/.config/sharpshell/shell.qml
```

### 4. Set Up Wallpapers Directory

Create the wallpapers directory (or change the path in `AppLauncher.qml`):

```bash
mkdir -p ~/Pictures/Wallpapers
```

---

## 🎮 Usage

### Keyboard Shortcuts Configuration

> **Important:** You need to bind keyboard shortcuts in your Wayland compositor (e.g., Hyprland) to launch the scripts.

#### For Hyprland (`~/.config/hyprland/hyprland.conf`)

```ini
# Open Launcher
bind = SUPER, R, exec, ~/.config/sharpshell/open-launcher.sh

# Toggle Dashboard
bind = SUPER, M, exec, ~/.config/sharpshell/toggle-menu.sh

# Open Clipboard Manager
bind = SUPER, V, exec, ~/.config/sharpshell/open-clipboard.sh
```

#### For other compositors

Configure similar bindings to execute the scripts from `~/.config/sharpshell/`.

### Keyboard Shortcuts (Inside Launcher/Dashboard)

| Action | Shortcut |
|--------|----------|
| **Open Launcher** | `Super+R` (or your configured shortcut) |
| **Toggle Dashboard** | `Super+M` (or your configured shortcut) |
| **Open Clipboard Manager** | `Super+V` (or your configured shortcut) / Click button in Side Panel |
| **Navigate** | Arrow keys (`↑`, `↓`, `←`, `→`) |
| **Select** | `Enter` or `Space` |
| **Search** | Start typing to filter (in launcher) |
| **Web Search** | Type `!` (DuckDuckGo), `!w` (Wikipedia), `!r` (Reddit), or `!y` (YouTube) followed by your query |
| **Calculator** | Type `=` followed by a math expression (e.g., `= 2+2*3`) |
| **Tab Navigation** | Click tabs or use mouse to switch between Dashboard, Media, and Performance tabs |
| **Close** | `Escape` |

---

## 📁 Project Structure

```
sharpshell/
├── shell.qml                 # Main entry point
├── components/
│   ├── AppLauncher.qml       # Application launcher
│   ├── Dashboard.qml         # Dashboard with tabs and cards
│   ├── SidePanel.qml         # Side panel with visualizer
│   ├── VolumeSlider.qml      # Volume control component
│   ├── NotificationDisplay.qml # Notification server and display
│   ├── NotificationItem.qml   # Individual notification component
│   ├── ClipboardManager.qml   # Clipboard manager component
│   ├── WallpaperBackground.qml # Native wallpaper background (Quickshell)
│   ├── Utils.qml             # Utility functions
│   ├── TopEdgeDetector.qml   # Top edge detection
│   └── RightEdgeDetector.qml # Right edge detection
├── scripts/
│   ├── start-cava.sh         # Audio visualizer startup
│   ├── install-package.sh    # Pacman package installation
│   ├── install-aur-package.sh # AUR package installation
│   ├── remove-package.sh     # Package removal
│   ├── remove-aur-package.sh # AUR package removal
│   └── update-system.sh      # System update script
├── open-launcher.sh          # Launcher opener script
├── toggle-menu.sh            # Menu toggle script
├── open-clipboard.sh         # Clipboard manager opener script
├── run.sh                   # Main runner script
└── colors.json              # Color theme configuration (auto-generated)
```

---

## 🎨 Customization

### Colors and Styling

SharpShell includes a powerful color customization system:

- **24 Color Presets**: Choose from beautiful pre-made themes
  - Dark, Ocean, Forest, Violet, Crimson, Amber, Teal, Rose, Sunset, Midnight, Emerald, Lavender, Sapphire, Coral, Mint, Plum, Gold, Monochrome, Cherry, Azure, Jade, Ruby, Indigo
- **Custom HEX Colors**: Edit individual color values (Background, Primary, Secondary, Text, Focus/Accent)
- **Live Preview**: See changes instantly as you edit
- **Persistent Settings**: Colors are saved to `~/.config/sharpshell/colors.json`

#### Customizing QML Files

Edit the QML files in `components/` to customize:
- Font sizes and families
- Border radius and spacing
- Animation durations and easing

### Layout and Sizing

| Component | Customization |
|-----------|---------------|
| **Launcher Size** | Modify `implicitWidth` and `implicitHeight` in `AppLauncher.qml` |
| **Wallpaper Grid** | Adjust `cellWidth` and `cellHeight` in wallpaper picker |
| **Dashboard Size** | Change dimensions in `Dashboard.qml` (default: 840x420) |
| **Tab Content** | Customize card layouts and sizes in respective tab sections |
| **Resource Bars** | Adjust bar heights and animation speeds |
| **Media Player** | Modify album art size and control button dimensions |
| **Notification Size** | Adjust `width` and positioning in `NotificationDisplay.qml` |
| **Notification Timeout** | Change auto-dismiss timer in `NotificationItem.qml` (default: 5 seconds) |

### Behavior

- **Animation Speed**: Adjust `duration` in `Behavior` and `NumberAnimation` blocks
- **Hover Effects**: Modify `scale` values in hover handlers
- **Keyboard Shortcuts**: Configure in your compositor settings

---

## 🔧 Configuration

### Wallpapers Path

**Default path:** `~/Pictures/Wallpapers`

To change, edit in `AppLauncher.qml`:

```qml
property string wallpapersPath: "/your/custom/path"
```

> **Note:** SharpShell uses native Quickshell wallpaper system (no external tools required!). The wallpaper is set via `WallpaperBackground.qml` component using `WlrLayer.Background`. If you prefer external tools, SharpShell will automatically detect and use `swww`, `wbg`, or `hyprpaper` if available.

### Audio Visualizer

The visualizer uses `cava` with automatic configuration. To customize, edit `scripts/start-cava.sh`. The Dashboard Media tab includes a full-width Cava visualizer that works alongside the side panel visualizer.

### GPU Monitoring

The Dashboard automatically detects and uses the appropriate GPU monitoring tool:

| GPU Vendor | Tool Used |
|------------|-----------|
| **NVIDIA** | `nvidia-smi` to query GPU utilization |
| **AMD** | `radeontop` to query GPU utilization |
| **Intel** | `intel_gpu_top` to query GPU utilization |

> Falls back gracefully if no compatible tool is found.

### Package Management

Scripts support both Pacman and AUR (via `yay` or `paru`). Make sure you have an AUR helper installed.

---

## 🐛 Troubleshooting

### Launcher Not Appearing

- ✅ Check Quickshell configuration
- ✅ Verify `shell.qml` path is correct
- ✅ Check keyboard shortcut binding

### Visualizer Not Working

- ✅ Ensure `cava` is installed: `sudo pacman -S cava`
- ✅ Check if `/tmp/quickshell_cava` is being created
- ✅ Verify PulseAudio is running
- ✅ For Dashboard Media tab visualizer, ensure cava is running via the side panel or start it manually

### GPU Monitoring Not Working

| GPU Type | Solution |
|----------|----------|
| **NVIDIA** | Ensure `nvidia-smi` is available (usually comes with nvidia drivers) |
| **AMD** | Install `radeontop`: `sudo pacman -S radeontop` |
| **Intel** | Install `intel-gpu-tools`: `sudo pacman -S intel-gpu-tools` |

> The Dashboard will automatically detect and use the appropriate tool.

### Wallpapers Not Loading

- ✅ Check wallpapers directory exists
- ✅ Verify file permissions
- ✅ Wallpapers work natively through Quickshell (no external tools needed!)
- ✅ If using external tools, ensure `swww`, `wbg`, or `hyprpaper` is installed

### Keyboard Focus Issues

- ✅ Try clicking on the launcher window
- ✅ Check Wayland compositor focus settings

---

## 📝 License

This project is licensed under the **MIT License** - feel free to use, modify, and distribute.

---

## 🤝 Contributing

Contributions are welcome! Feel free to:

- 🐛 Report bugs
- 💡 Suggest features
- 🔀 Submit pull requests
- 📖 Improve documentation

---

## 🙏 Acknowledgments

- Built with [Quickshell](https://github.com/Quickshell/Quickshell)
- Audio visualization powered by [cava](https://github.com/karlstav/cava)
- Wallpaper system inspired by [Caelestia Shell](https://github.com/caelestia-dots/shell)
- Optional wallpaper tools: [swww](https://github.com/Horus645/swww), [wbg](https://github.com/djpohly/wbg), [hyprpaper](https://github.com/hyprwm/hyprpaper)

---

<div align="center">

**Made with ❤️ for the Linux community**

[⭐ Star this repo](https://github.com/artwik22/sharpshell) • [🐛 Report Bug](https://github.com/artwik22/sharpshell/issues) • [💡 Request Feature](https://github.com/artwik22/sharpshell/issues)

</div>

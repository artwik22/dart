# SharpShell

<div align="center">

**A modern shell/launcher system for Quickshell with Wayland support**

[![Quickshell](https://img.shields.io/badge/Quickshell-Compatible-00D9FF?style=for-the-badge&logo=qt)](https://github.com/Quickshell/Quickshell)
[![Wayland](https://img.shields.io/badge/Wayland-Supported-FF6B6B?style=for-the-badge&logo=wayland)](https://wayland.freedesktop.org/)
[![License](https://img.shields.io/badge/License-MIT-green.svg?style=for-the-badge)](LICENSE)

*A customizable system with smooth animations, automated installation, and comprehensive features*

</div>

---

## Table of Contents

- [Features](#features)
  - [Application Launcher](#application-launcher)
  - [Dashboard](#dashboard)
  - [Side Panel](#side-panel)
  - [Clipboard Manager](#clipboard-manager)
  - [Notification System](#notification-system)
  - [Wallpaper Management](#wallpaper-management)
  - [Lock Screen](#lock-screen)
- [Requirements](#requirements)
- [Installation](#installation)
  - [Automated Installer](#automated-installer)
  - [Manual Installation](#manual-installation)
- [Usage](#usage)
- [Project Structure](#project-structure)
- [Customization](#customization)
- [Configuration](#configuration)
- [Troubleshooting](#troubleshooting)
- [License](#license)
- [Contributing](#contributing)

---

## Features

### Application Launcher

| Feature | Description |
|---------|-------------|
| Fast Search | Real-time filtering of applications |
| Web Search | Multiple engines: `!` (DuckDuckGo), `!w` (Wikipedia), `!r` (Reddit), `!y` (YouTube) |
| Calculator | Type `=` followed by math expressions |
| Keyboard Navigation | Full arrow key support |
| Package Management | Install/remove via Pacman and AUR |
| Settings Panel | Wallpaper, colors, sidebar toggle, system updates |
| Color Presets | 24 pre-made themes |
| Custom Colors | Edit HEX values directly |

### Dashboard

System monitoring dashboard with multiple tabs.

#### Main Tab
- Weather display with current conditions
- System information (OS, uptime, stats)
- Calendar with monthly view
- Real-time CPU, RAM, GPU monitoring
- Media player controls with album art

#### Media Tab
- Full media player interface
- Real-time audio visualizer across full width

#### Performance Tab
- Detailed resource monitoring with temperatures
- Disk usage for multiple partitions
- Top processes by resource usage



### Side Panel

- Real-time audio visualizer with cava
- Volume control slider (hover right edge)
- Bluetooth toggle
- Clipboard manager button
- Clock and date display
- Clean, minimal design
- Toggle visibility from launcher settings

### Clipboard Manager

- Tracks clipboard history (up to 50 items)
- Smart deduplication (moves duplicates to top)
- Click to copy items back
- Clear history button
- Keyboard support (Escape to close)
- Matches your color theme

### Notification System

- Full D-Bus notification support
- Modern design with animations
- Auto-dismiss after 5 seconds
- Click to dismiss
- Progress indicator
- Top-right positioning
- Urgency-based colors

### Wallpaper Management

- Native Quickshell integration (no external tools needed)
- Visual grid browser
- Hover preview effects
- Smooth transitions
- Multi-screen synchronization
- Fallback support for swww, wbg, hyprpaper

### Lock Screen

- Password protection
- Current wallpaper background
- Secure password entry
- Alternative unlock button
- Configurable auto-lock
- Matches SharpShell theme

---

## Requirements

### Required
- Quickshell (QML-based shell system)
- Wayland compositor (tested with Hyprland)

### Optional
- `cava` - Audio visualizer
- `playerctl` - Media player control
- `pactl` - PulseAudio volume control
- `bluetoothctl` - Bluetooth management
- `nvidia-smi` or `radeontop` - GPU monitoring
- `sensors` - Hardware temperature monitoring
- `swww`, `wbg`, or `hyprpaper` - External wallpaper tools

*Note: Native Quickshell wallpaper system works without external tools*

---

## Installation

### Automated Installation (Recommended)

SharpShell includes an interactive installer that handles everything automatically.

```bash
git clone https://github.com/artwik22/sharpshell.git
cd sharpshell
./install.sh
```

The installer will:
- Check and install dependencies
- Copy all files to `~/.config/sharpshell`
- Set proper permissions
- Create wallpapers directory
- Set up lock screen password
- Create color configuration
- Display setup instructions

### Manual Installation

```bash
git clone https://github.com/artwik22/sharpshell.git ~/.config/sharpshell
cd ~/.config/sharpshell
chmod +x scripts/*.sh *.sh
mkdir -p ~/Pictures/Wallpapers
```

### Post-Installation Setup

After installation, configure your Wayland compositor to use SharpShell:

---

## Usage

### Keyboard Shortcuts Configuration

The installer provides configuration snippets for your compositor.

#### For Hyprland

```ini
# SharpShell shortcuts
bind = SUPER, R, exec, ~/.config/sharpshell/open-launcher.sh
bind = SUPER, M, exec, ~/.config/sharpshell/toggle-menu.sh
bind = SUPER, V, exec, ~/.config/sharpshell/open-clipboard.sh
bind = SUPER, L, exec, ~/.config/sharpshell/lock-screen.sh
```

#### For other compositors

Configure similar bindings to execute the scripts from `~/.config/sharpshell`.

### Keyboard Shortcuts

| Action | Shortcut |
|--------|----------|
| Open Launcher | `Super+R` |
| Toggle Dashboard | `Super+M` |
| Open Clipboard Manager | `Super+V` / Click button in Side Panel |
| Lock Screen | `Super+L` / Click lock button in Side Panel |
| Navigate | Arrow keys |
| Select | `Enter` or `Space` |
| Search | Start typing |
| Web Search | `!` (DuckDuckGo), `!w` (Wikipedia), `!r` (Reddit), `!y` (YouTube) |
| Calculator | Type `=` followed by expression |
| Tab Navigation | Click tabs or use mouse |
| Close | `Escape` |

---

## Project Structure

```
sharpshell/
├── shell.qml                 # Main entry point
├── components/
│   ├── AppLauncher.qml       # Application launcher
│   ├── Dashboard.qml         # Dashboard with tabs
│   ├── SidePanel.qml         # Side panel with visualizer
│   ├── VolumeSlider.qml      # Volume control
│   ├── NotificationDisplay.qml # Notification system
│   ├── NotificationItem.qml   # Individual notifications
│   ├── ClipboardManager.qml   # Clipboard manager
│   ├── WallpaperBackground.qml # Native wallpaper
│   ├── Utils.qml             # Utility functions
│   ├── TopEdgeDetector.qml   # Top edge detection
│   └── RightEdgeDetector.qml # Right edge detection
├── scripts/
│   ├── start-cava.sh         # Audio visualizer
│   ├── install-package.sh    # Pacman installation
│   ├── install-aur-package.sh # AUR installation
│   ├── remove-package.sh     # Package removal
│   ├── remove-aur-package.sh # AUR removal
│   └── update-system.sh      # System updates
├── open-launcher.sh          # Launcher script
├── toggle-menu.sh            # Menu toggle script
├── open-clipboard.sh         # Clipboard script
├── run.sh                    # Main runner
└── colors.json               # Color configuration
```

---

## Customization

### Colors and Styling

SharpShell includes a comprehensive color system:

- 24 pre-made color presets
- Custom HEX color editing
- Live preview
- Persistent settings saved to `colors.json`

### Layout and Sizing

| Component | Customization |
|-----------|---------------|
| Launcher Size | Modify dimensions in `AppLauncher.qml` |
| Wallpaper Grid | Adjust cell sizes in wallpaper picker |
| Dashboard Size | Change dimensions in `Dashboard.qml` |
| Tab Content | Customize layouts in tab sections |
| Resource Bars | Adjust heights and animation speeds |
| Media Player | Modify album art and controls |
| Notifications | Adjust size and positioning |

### Behavior

- Animation speed: Modify `duration` in animation blocks
- Hover effects: Adjust `scale` values
- Keyboard shortcuts: Configure in compositor settings

---

## Configuration

### Wallpapers Path

Default: `~/Pictures/Wallpapers`

To change, edit `wallpapersPath` in `AppLauncher.qml`.

*Note: Uses native Quickshell wallpaper system. Falls back to swww, wbg, or hyprpaper if available.*

### Audio Visualizer

Uses `cava` with automatic configuration. Customize in `scripts/start-cava.sh`.

### GPU Monitoring

Automatically detects GPU type:

| GPU | Tool |
|-----|------|
| NVIDIA | `nvidia-smi` |
| AMD | `radeontop` |
| Intel | `intel-gpu_top` |

### Package Management

Supports Pacman and AUR (via yay/paru).

---

## Troubleshooting

### Launcher Not Appearing
- Check Quickshell configuration
- Verify `shell.qml` path is correct
- Check keyboard shortcut binding

### Visualizer Not Working
- Install `cava`: `sudo pacman -S cava`
- Check if `/tmp/quickshell_cava` is created
- Verify PulseAudio is running

### GPU Monitoring Not Working

| GPU | Solution |
|-----|----------|
| NVIDIA | Check `nvidia-smi` is available |
| AMD | Install `radeontop` |
| Intel | Install `intel-gpu-tools` |

### Wallpapers Not Loading
- Check wallpapers directory exists
- Verify file permissions
- Works natively with Quickshell

### Keyboard Focus Issues
- Try clicking on the launcher window
- Check compositor focus settings

---

## License

This project is licensed under the MIT License.

---

## Contributing

Contributions welcome! Please:

- Report bugs
- Suggest features
- Submit pull requests
- Improve documentation

---

## Acknowledgments

- Built with [Quickshell](https://github.com/Quickshell/Quickshell)
- Audio visualization by [cava](https://github.com/karlstav/cava)
- Wallpaper system inspired by [Caelestia Shell](https://github.com/caelestia-dots/shell)

---

<div align="center">

Made for the Linux community

[GitHub](https://github.com/artwik22/sharpshell) • [Issues](https://github.com/artwik22/sharpshell/issues)

</div>

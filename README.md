# SharpShell

<div align="center">

**A modern shell/launcher system for Quickshell with Wayland support**

[![Quickshell](https://img.shields.io/badge/Quickshell-Compatible-00D9FF?style=for-the-badge&logo=qt)](https://github.com/Quickshell/Quickshell)
[![Wayland](https://img.shields.io/badge/Wayland-Supported-FF6B6B?style=for-the-badge&logo=wayland)](https://wayland.freedesktop.org/)
[![License](https://img.shields.io/badge/License-MIT-green.svg?style=for-the-badge)](LICENSE)

*A customizable system with beautiful smooth animations, automated installation, and comprehensive features*

</div>

---

## Table of Contents

- [Features](#features)
  - [Application Launcher](#application-launcher)
  - [Dashboard](#dashboard)
  - [Side Panel](#side-panel)
  - [Clipboard Manager](#clipboard-manager)
  - [Screenshot Tool](#screenshot-tool)
  - [Notification System](#notification-system)
  - [Wallpaper Management](#wallpaper-management)
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

## Latest Updates

### Version 2.2.0 - Multi-Platform Support & Notes System

- **📦 Multi-Platform Package Manager Support**: Installer now supports pacman (Arch), apt (Debian/Ubuntu), and dnf (Fedora/RHEL)
- **📝 Notes System**: Added complete notes management with menu interface
  - Create new notes with automatic filename generation
  - View and edit existing notes
  - Intuitive menu navigation with keyboard support
- **🔧 Enhanced Installer**: Auto-detection of package manager with manual selection fallback
- **🎨 UI Improvements**: Refined launcher animations and menu interactions

### Version 2.1.0 - UI/UX Improvements

- **Fixed Selection Visibility**: Resolved issue where selected items in launcher were too bright with invisible text
- **Enhanced Keyboard Navigation**: Fixed inconsistent keyboard navigation across all launcher submenus
- **Unified Animations**: Added smooth scale and opacity animations to all menu items for consistent user experience
- **Improved Color Contrast**: Changed selected item backgrounds to use darker colors for better text visibility
- **UI Polish**: Standardized animation durations and easing functions across all components
- **Removed Change Password**: Eliminated the Change Password feature for a cleaner settings interface

---

## Features

### Application Launcher

| Feature | Description |
|---------|-------------|
| Fast Search | Real-time filtering of applications |
| Web Search | Multiple engines: `!` (DuckDuckGo), `!w` (Wikipedia), `!r` (Reddit), `!y` (YouTube) |
| Calculator | Type `=` followed by math expressions |
| Keyboard Navigation | Full arrow key support with smooth animations |
| Package Management | Install/remove via Pacman and AUR |
| **Notes System** | **Create, view, and edit notes with automatic file management** |
| Settings Panel | Wallpaper, colors, sidebar toggle, system updates, bar position (4 options) |
| Color Presets | 24 pre-made themes with live preview |
| Custom Colors | Edit HEX values directly with instant feedback |
| Beautiful Animations | Smooth transitions, hover effects, and UI feedback throughout |
| Consistent UI | Unified animations and visual effects across all components |

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



### Side Panel / Top Bar

- Two separate panels: left sidebar and top bar
- Switch between positions via "Bar Position" setting
- Real-time audio visualizer with cava
- Volume control slider (hover right edge)
- Bluetooth toggle
- Clipboard manager button
- Screenshot button with area selection
- Clock and date display
- Clean, minimal design
- Toggle visibility from launcher settings
- Position preference saved to `colors.json`

### Clipboard Manager

- Tracks clipboard history (up to 50 items)
- Smart deduplication (moves duplicates to top)
- Click to copy items back
- Clear history button
- Keyboard support (Escape to close)
- Matches your color theme
- Dynamic positioning:
  - Left side when bar is on the left
  - Right side when bar is on top (with proper spacing)

### Screenshot Tool

- Area selection with visual feedback
- Dark overlay with white border for better visibility
- Saves to `~/Pictures/Screenshots/`
- Automatically copies to clipboard
- Desktop notifications with preview
- Uses `grim` and `slurp` for Wayland compatibility

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


## Requirements

### Required
- Quickshell (QML-based shell system)
- Wayland compositor (tested with Hyprland)

### Optional
- `cava` - Audio visualizer
- `playerctl` - Media player control
- `pactl` - PulseAudio volume control
- `bluetoothctl` - Bluetooth management
- `grim` and `slurp` - Screenshot functionality (Wayland)
- `wl-copy` - Clipboard support for screenshots
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
- **Auto-detect your package manager** (pacman, apt, dnf)
- Check and install dependencies for your system
- Copy all files to `~/.config/sharpshell`
- Set proper permissions
- Create wallpapers directory
- Create color configuration
- Display setup instructions

#### Supported Package Managers
- **Arch Linux**: pacman + AUR (yay/paru)
- **Debian/Ubuntu**: apt
- **Fedora/RHEL**: dnf

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
```

#### For other compositors

Configure similar bindings to execute the scripts from `~/.config/sharpshell`.

### Keyboard Shortcuts

| Action | Shortcut |
|--------|----------|
| Open Launcher | `Super+R` |
| Toggle Dashboard | `Super+M` |
| Open Clipboard Manager | `Super+V` / Click button in Side Panel/Top Bar |
| Take Screenshot | Click screenshot button in Side Panel/Top Bar |
| Change Bar Position | Settings → Bar Position (left/top) |
| Navigate | Arrow keys |
| Select | `Enter` or `Space` |
| Search | Start typing |
| Web Search | `!` (DuckDuckGo), `!w` (Wikipedia), `!r` (Reddit), `!y` (YouTube) |
| Calculator | Type `=` followed by expression |
| Tab Navigation | Click tabs or use mouse |
| Close | `Escape` |
| Package Management | Navigate to Packages → Install/Remove |
| Color Customization | Settings → Colors → Custom HEX |
| Toggle Features | Settings → Sidebar, Bar Position |

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
│   ├── take-screenshot.sh    # Screenshot with area selection
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

- Animation speed: Modify `duration` in animation blocks (200-400ms for smooth experience)
- Hover effects: Adjust `scale` values (1.015x scale, smooth color transitions)
- Notification animations: Slide-in effects with opacity and scale transitions
- Sidebar animations: 280ms duration for fluid panel interactions
- Selection colors: Dark backgrounds with smooth color animations
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
- **Fixed in v2.1.0**: All launcher submenus now have consistent keyboard navigation

### Screenshot Not Working
- Install `grim` and `slurp`: `sudo pacman -S grim slurp`
- Install `wl-copy` for clipboard support: `sudo pacman -S wl-clipboard`
- Ensure Wayland display is accessible
- Check if screenshot directory exists: `~/Pictures/Screenshots/`
- Verify script permissions: `chmod +x ~/.config/sharpshell/scripts/take-screenshot.sh`

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

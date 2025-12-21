# 🚀 SharpShell

A modern, beautiful, and highly customizable shell/launcher system for Quickshell with full Wayland support. Features smooth animations, intuitive navigation, and powerful system integration.

![SharpShell](https://img.shields.io/badge/SharpShell-QML-blue)
![Quickshell](https://img.shields.io/badge/Quickshell-Compatible-green)
![Wayland](https://img.shields.io/badge/Wayland-Supported-purple)

## ✨ Features

### 🎯 Application Launcher
- **Fast Search**: Real-time filtering of applications
- **Keyboard Navigation**: Full arrow key support
- **Smooth Animations**: Beautiful transitions and hover effects
- **Package Management**: Install/remove packages via Pacman and AUR
- **Settings Panel**: Customize wallpaper and system updates

### 📊 Top Menu
- **Media Player Control**: Play, pause, skip tracks with visual feedback
- **System Stats**: Real-time CPU, RAM, and GPU monitoring
- **System Options**: Power off, reboot controls
- **Smooth Tab Navigation**: Animated transitions between sections

### 🎨 Side Panel
- **Audio Visualizer**: Real-time audio visualization with cava
- **Volume Control**: Adjust system volume with visual slider
- **Bluetooth Control**: Toggle Bluetooth on/off
- **Modern Design**: Clean, minimal interface

### 🖼️ Wallpaper Management
- **Visual Grid**: Browse wallpapers in a beautiful grid layout
- **Quick Preview**: Hover effects for easy selection
- **Swww Integration**: Seamless wallpaper switching
- **Dynamic Layout**: Auto-adjusting grid with smooth animations

## 📋 Requirements

- **Quickshell** - QML-based shell system
- **Wayland Compositor** - Tested with Hyprland
- **swww** - Wallpaper management
- **cava** - Audio visualizer
- **playerctl** - Media player control
- **pactl** - PulseAudio volume control
- **bluetoothctl** - Bluetooth management


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

## 🎮 Usage

### Keyboard Shortcuts Configuration

**Important**: You need to bind keyboard shortcuts in your Wayland compositor (e.g., Hyprland) to launch the scripts. Add these bindings to your compositor config:

**For Hyprland** (`~/.config/hyprland/hyprland.conf`):
```ini
# Open Launcher
bind = SUPER, R, exec, ~/.config/sharpshell/open-launcher.sh

# Toggle Top Menu
bind = SUPER, M, exec, ~/.config/sharpshell/toggle-menu.sh
```

**For other compositors**: Configure similar bindings to execute the scripts from `~/.config/sharpshell/`.

### Keyboard Shortcuts (Inside Launcher/Menu)

- **Open Launcher**: Use your configured shortcut (e.g., `Super+R`)
- **Toggle Top Menu**: Use your configured shortcut (e.g., `Super+M`)
- **Navigate**: Arrow keys (`↑`, `↓`, `←`, `→`)
- **Select**: `Enter` or `Space`
- **Search**: Start typing to filter
- **Escape**: Close launcher/menu

### Navigation


## 📁 Project Structure

```
sharpshell/
├── shell.qml                 # Main entry point
├── components/
│   ├── AppLauncher.qml       # Application launcher
│   ├── TopMenu.qml           # Top menu bar
│   ├── SidePanel.qml         # Side panel with visualizer
│   ├── VolumeSlider.qml      # Volume control component
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
└── run.sh                   # Main runner script
```

## 🎨 Customization

### Colors and Styling

Edit the QML files in `components/` to customize:
- Color schemes (dark theme by default)
- Font sizes and families
- Border radius and spacing
- Animation durations and easing

### Layout and Sizing

- **Launcher Size**: Modify `implicitWidth` and `implicitHeight` in `AppLauncher.qml`
- **Wallpaper Grid**: Adjust `cellWidth` and `cellHeight` in wallpaper picker
- **Menu Size**: Change dimensions in `TopMenu.qml`

### Behavior

- **Animation Speed**: Adjust `duration` in `Behavior` and `NumberAnimation` blocks
- **Hover Effects**: Modify `scale` values in hover handlers
- **Keyboard Shortcuts**: Configure in your compositor settings

## 🔧 Configuration

### Wallpapers Path

Default path: `~/Pictures/Wallpapers`

To change, edit in `AppLauncher.qml`:
```qml
property string wallpapersPath: "/your/custom/path"
```

### Audio Visualizer

The visualizer uses `cava` with automatic configuration. To customize, edit `scripts/start-cava.sh`.

### Package Management

Scripts support both Pacman and AUR (via `yay` or `paru`). Make sure you have an AUR helper installed.

## 🐛 Troubleshooting

### Launcher Not Appearing

- Check Quickshell configuration
- Verify `shell.qml` path is correct
- Check keyboard shortcut binding

### Visualizer Not Working

- Ensure `cava` is installed: `sudo pacman -S cava`
- Check if `/tmp/quickshell_cava` is being created
- Verify PulseAudio is running

### Wallpapers Not Loading

- Check wallpapers directory exists
- Verify file permissions
- Ensure `swww` is installed and configured

### Keyboard Focus Issues

- Try clicking on the launcher window
- Check Wayland compositor focus settings

## 📝 License

MIT License - feel free to use, modify, and distribute.

## 🤝 Contributing

Contributions are welcome! Feel free to:
- Report bugs
- Suggest features
- Submit pull requests
- Improve documentation

## 🙏 Acknowledgments

- Built with [Quickshell](https://github.com/Quickshell/Quickshell)
- Audio visualization powered by [cava](https://github.com/karlstav/cava)
- Wallpaper management via [swww](https://github.com/Horus645/swww)

---

**Made with ❤️ for the Linux community**

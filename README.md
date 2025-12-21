# SharpShell

A modern, customizable shell/launcher for Quickshell with Wayland support.

## Features

- **App Launcher**: Fast application launcher with search functionality
- **Top Menu**: System information, media player controls, and system options
- **Side Panel**: Audio visualizer and system controls
- **Package Management**: Install and remove packages via Pacman and AUR
- **Wallpaper Management**: Change wallpapers with swww integration
- **Smooth Animations**: Beautiful transitions and hover effects

## Requirements

- Quickshell
- Wayland compositor (tested with Hyprland)
- swww (for wallpaper management)
- cava (for audio visualizer)
- playerctl (for media control)
- pactl (for volume control)

## Installation

1. Clone this repository:
```bash
git clone <your-repo-url> ~/.config/sharpshell
```

2. Make scripts executable:
```bash
chmod +x ~/.config/sharpshell/scripts/*.sh
chmod +x ~/.config/sharpshell/*.sh
```

3. Configure Quickshell to use `shell.qml` as the main configuration file.

## Usage

- **Open Launcher**: Use the configured keyboard shortcut (default: Super+R or custom)
- **Toggle Top Menu**: Use the configured keyboard shortcut
- **Navigate**: Use arrow keys or mouse
- **Search**: Type to filter applications
- **Select**: Enter or click to launch/select

## Configuration

Edit the QML files in `components/` to customize:
- Colors and styling
- Layout and sizing
- Keyboard shortcuts
- Behavior and animations

## Structure

- `shell.qml` - Main entry point
- `components/AppLauncher.qml` - Application launcher
- `components/TopMenu.qml` - Top menu bar
- `components/SidePanel.qml` - Side panel with visualizer
- `scripts/` - Helper shell scripts

## License

MIT


#!/bin/bash

# SharpShell Installer - Fixed Version
# Interactive installer for SharpShell quickshell configuration

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.config/sharpshell"
WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
COLORS_FILE="$CONFIG_DIR/colors.json"

# Track installed dependencies
INSTALLED_DEPS=()
MISSING_DEPS=()
OPTIONAL_DEPS=()

# Package manager variables
PACKAGE_MANAGER=""
INSTALL_CMD=""
UPDATE_CMD=""

# Helper functions
print_header() {
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${BOLD}  $1${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_success() { echo -e "  ${GREEN}✓${NC} ${GREEN}$1${NC}"; }
print_error() { echo -e "  ${RED}✗${NC} ${RED}$1${NC}"; }
print_warning() { echo -e "  ${YELLOW}⚠${NC} ${YELLOW}$1${NC}"; }
print_info() { echo -e "  ${BLUE}ℹ${NC} ${BLUE}$1${NC}"; }
print_step() { echo -e "${MAGENTA}→${NC} ${BOLD}$1${NC}"; }

command_exists() { command -v "$1" >/dev/null 2>&1; }

# Parse command line arguments
AUTO_INSTALL=false
FORCE_INSTALL=false
for arg in "$@"; do
    case $arg in
        --auto) AUTO_INSTALL=true ;;
        --force) FORCE_INSTALL=true ;;
        --help)
            echo "SharpShell Installer"
            echo "Usage: $0 [OPTIONS]"
            exit 0
            ;;
    esac
done

detect_package_manager() {
    print_header "Package Manager Selection"
    if command_exists "pacman"; then
        PACKAGE_MANAGER="pacman"
        INSTALL_CMD="pacman -S --noconfirm"
        UPDATE_CMD="pacman -Sy"
    elif command_exists "apt"; then
        PACKAGE_MANAGER="apt"
        INSTALL_CMD="apt install -y"
        UPDATE_CMD="apt update"
    elif command_exists "dnf"; then
        PACKAGE_MANAGER="dnf"
        INSTALL_CMD="dnf install -y"
        UPDATE_CMD="dnf check-update"
    else
        print_error "No supported package manager found (pacman, apt, dnf)."
        exit 1
    fi
    print_success "Detected $PACKAGE_MANAGER"
}

get_package_name() {
    local base=$1
    case $base in
        "quickshell") echo "quickshell" ;;
        "cava") echo "cava" ;;
        "playerctl") echo "playerctl" ;;
        "pulseaudio") [[ "$PACKAGE_MANAGER" == "apt" ]] && echo "pulseaudio-utils" || echo "libpulse" ;;
        "bluez-utils") [[ "$PACKAGE_MANAGER" == "pacman" ]] && echo "bluez-utils" || echo "bluez" ;;
        "lm_sensors") [[ "$PACKAGE_MANAGER" == "apt" ]] && echo "lm-sensors" || echo "lm_sensors" ;;
        *) echo "$base" ;;
    esac
}

check_dependency() {
    local cmd=$1
    local pkg_base=$2
    local optional=$3
    local pkg=$(get_package_name "$pkg_base")

    if command_exists "$cmd"; then
        print_success "$cmd is already installed"
    else
        if [ "$optional" = true ]; then
            OPTIONAL_DEPS+=("$pkg")
            print_warning "$cmd not found (optional)"
        else
            MISSING_DEPS+=("$pkg")
            print_error "$cmd not found (required)"
        fi
    fi
}

install_packages() {
    local pkgs=("$@")
    [ ${#pkgs[@]} -eq 0 ] && return 0

    print_step "Updating package databases..."
    sudo $UPDATE_CMD || true

    print_step "Installing: ${pkgs[*]}"
    
    # Special handling for Quickshell on Arch (AUR)
    if [[ "$PACKAGE_MANAGER" == "pacman" ]]; then
        local to_aur=()
        local to_pacman=()
        for p in "${pkgs[@]}"; do
            if [[ "$p" == "quickshell" ]]; then to_aur+=("$p"); else to_pacman+=("$p"); fi
        done
        
        if [ ${#to_pacman[@]} -gt 0 ]; then
            sudo pacman -S --noconfirm "${to_pacman[@]}"
        fi
        
        for p in "${to_aur[@]}"; do
            if command_exists yay; then yay -S --noconfirm "$p"
            elif command_exists paru; then paru -S --noconfirm "$p"
            else print_warning "No AUR helper found for $p. Please install manually."; fi
        done
    else
        sudo $INSTALL_CMD "${pkgs[@]}"
    fi
    
    for p in "${pkgs[@]}"; do INSTALLED_DEPS+=("$p"); done
}

setup_directories() {
    print_header "Directory Setup"
    mkdir -p "$CONFIG_DIR/components" "$CONFIG_DIR/scripts" "$WALLPAPER_DIR"
    print_success "Directories created in $CONFIG_DIR"
}

copy_files() {
    print_header "Copying Files"
    local files=("shell.qml" "run.sh" "open-clipboard.sh" "open-launcher.sh" "toggle-menu.sh")
    for f in "${files[@]}"; do
        if [ -f "$SCRIPT_DIR/$f" ]; then
            cp "$SCRIPT_DIR/$f" "$CONFIG_DIR/"
            chmod +x "$CONFIG_DIR/$f"
            print_success "Copied $f"
        fi
    done

    if [ -d "$SCRIPT_DIR/components" ]; then
        cp -r "$SCRIPT_DIR/components/"* "$CONFIG_DIR/components/"
    fi
    if [ -d "$SCRIPT_DIR/scripts" ]; then
        cp -r "$SCRIPT_DIR/scripts/"* "$CONFIG_DIR/scripts/"
        find "$CONFIG_DIR/scripts" -type f -exec chmod +x {} \;
    fi
}

setup_colors() {
    if [ ! -f "$COLORS_FILE" ]; then
        cat > "$COLORS_FILE" << EOF
{
  "background": "#0a0a0a",
  "primary": "#1a1a1a",
  "secondary": "#141414",
  "text": "#ffffff",
  "accent": "#4a9eff"
}
EOF
        print_success "Created default colors.json"
    fi
}

main() {
    clear
    echo -e "${CYAN}SharpShell Installer${NC}"
    
    detect_package_manager
    
    print_header "Checking Dependencies"
    check_dependency "quickshell" "quickshell" false
    check_dependency "cava" "cava" true
    check_dependency "playerctl" "playerctl" true
    check_dependency "pactl" "pulseaudio" true
    check_dependency "sensors" "lm_sensors" true

    # Install required
    if [ ${#MISSING_DEPS[@]} -gt 0 ]; then
        install_packages "${MISSING_DEPS[@]}"
    fi

    # Optional packages
    if [ ${#OPTIONAL_DEPS[@]} -gt 0 ]; then
        if [ "$AUTO_INSTALL" = true ] || [ "$FORCE_INSTALL" = true ]; then
            install_packages "${OPTIONAL_DEPS[@]}"
        else
            echo ""
            read -p "Install optional dependencies? (y/n): " choice
            [[ "$choice" =~ ^[Yy]$ ]] && install_packages "${OPTIONAL_DEPS[@]}"
        fi
    fi

    setup_directories
    copy_files
    setup_colors
    
    print_header "Installation Complete!"
    echo -e "Run with: ${GREEN}$CONFIG_DIR/run.sh${NC}"
}

main
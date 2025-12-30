#!/bin/bash

# SharpShell Installer
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

# Detect package manager
detect_package_manager() {
    print_header "Package Manager Selection"

    # Auto-detect based on available package managers
    if command_exists "pacman"; then
        print_success "Detected Arch Linux (pacman)"
        PACKAGE_MANAGER="pacman"
        INSTALL_CMD="sudo pacman -S --noconfirm"
        UPDATE_CMD="sudo pacman -Syu --noconfirm"
    elif command_exists "apt"; then
        print_success "Detected Debian/Ubuntu (apt)"
        PACKAGE_MANAGER="apt"
        INSTALL_CMD="sudo apt install -y"
        UPDATE_CMD="sudo apt update && sudo apt upgrade -y"
    elif command_exists "dnf"; then
        print_success "Detected Fedora/RHEL (dnf)"
        PACKAGE_MANAGER="dnf"
        INSTALL_CMD="sudo dnf install -y"
        UPDATE_CMD="sudo dnf upgrade -y"
    else
        print_warning "Could not auto-detect package manager"
        echo ""
        print_step "Please select your package manager:"
        echo ""
        echo -e "${CYAN}1.${NC} pacman (Arch Linux)"
        echo -e "${CYAN}2.${NC} apt (Debian/Ubuntu)"
        echo -e "${CYAN}3.${NC} dnf (Fedora/RHEL)"
        echo ""
        read -p "$(echo -e ${YELLOW}Enter your choice [1-3]: ${NC})" pm_choice

        case $pm_choice in
            1)
                PACKAGE_MANAGER="pacman"
                INSTALL_CMD="sudo pacman -S --noconfirm"
                UPDATE_CMD="sudo pacman -Syu --noconfirm"
                ;;
            2)
                PACKAGE_MANAGER="apt"
                INSTALL_CMD="sudo apt install -y"
                UPDATE_CMD="sudo apt update && sudo apt upgrade -y"
                ;;
            3)
                PACKAGE_MANAGER="dnf"
                INSTALL_CMD="sudo dnf install -y"
                UPDATE_CMD="sudo dnf upgrade -y"
                ;;
            *)
                print_error "Invalid choice. Defaulting to pacman."
                PACKAGE_MANAGER="pacman"
                INSTALL_CMD="sudo pacman -S --noconfirm"
                UPDATE_CMD="sudo pacman -Syu --noconfirm"
                ;;
        esac
    fi

    print_info "Using package manager: $PACKAGE_MANAGER"
}

# Helper functions
print_header() {
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${BOLD}${NC}  ${BOLD}${CYAN}$1${NC}${BOLD}${NC}${CYAN}${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_success() {
    echo -e "  ${GREEN}✓${NC} ${GREEN}$1${NC}"
}

print_error() {
    echo -e "  ${RED}✗${NC} ${RED}$1${NC}"
}

print_warning() {
    echo -e "  ${YELLOW}⚠${NC} ${YELLOW}$1${NC}"
}

print_info() {
    echo -e "  ${BLUE}ℹ${NC} ${BLUE}$1${NC}"
}

print_step() {
    echo -e "${MAGENTA}→${NC} ${BOLD}$1${NC}"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if user has sudo privileges
check_sudo() {
    if ! sudo -n true 2>/dev/null; then
        print_warning "Sudo privileges required for package installation"
        sudo -v
    fi
}

# Get package name for current system
get_package_name() {
    local base_name=$1

    case $base_name in
        "quickshell")
            case $PACKAGE_MANAGER in
                "pacman") echo "quickshell" ;;
                "apt") echo "quickshell" ;;  # Assuming quickshell is available via apt
                "dnf") echo "quickshell" ;;  # Assuming quickshell is available via dnf
                *) echo "quickshell" ;;
            esac
            ;;
        "cava")
            case $PACKAGE_MANAGER in
                "pacman") echo "cava" ;;
                "apt") echo "cava" ;;
                "dnf") echo "cava" ;;
                *) echo "cava" ;;
            esac
            ;;
        "playerctl")
            case $PACKAGE_MANAGER in
                "pacman") echo "playerctl" ;;
                "apt") echo "playerctl" ;;
                "dnf") echo "playerctl" ;;
                *) echo "playerctl" ;;
            esac
            ;;
        "pulseaudio")
            case $PACKAGE_MANAGER in
                "pacman") echo "pulseaudio" ;;
                "apt") echo "pulseaudio" ;;
                "dnf") echo "pulseaudio" ;;
                *) echo "pulseaudio" ;;
            esac
            ;;
        "bluez-utils")
            case $PACKAGE_MANAGER in
                "pacman") echo "bluez-utils" ;;
                "apt") echo "bluez" ;;
                "dnf") echo "bluez" ;;
                *) echo "bluez-utils" ;;
            esac
            ;;
        "lm_sensors")
            case $PACKAGE_MANAGER in
                "pacman") echo "lm_sensors" ;;
                "apt") echo "lm-sensors" ;;
                "dnf") echo "lm_sensors" ;;
                *) echo "lm_sensors" ;;
            esac
            ;;
        *)
            echo "$base_name"
            ;;
    esac
}

# Check dependency
check_dependency() {
    local name=$1
    local base_package=$2
    local optional=${3:-false}

    local package=$(get_package_name "$base_package")

    if command_exists "$name"; then
        print_success "$name is installed"
        return 0
    else
        if [ "$optional" = true ]; then
            print_warning "$name is not installed (optional)"
            OPTIONAL_DEPS+=("$package")
        else
            print_error "$name is not installed (required)"
            MISSING_DEPS+=("$package")
        fi
        return 1
    fi
}

# Install dependency via detected package manager
install_dependency() {
    local package=$1
    local is_special=${2:-false}

    case $PACKAGE_MANAGER in
        "pacman")
            if [ "$is_special" = true ]; then
                # Check for AUR helper
                if command_exists yay; then
                    print_info "Installing $package via yay..."
                    yay -S --noconfirm "$package" && INSTALLED_DEPS+=("$package")
                elif command_exists paru; then
                    print_info "Installing $package via paru..."
                    paru -S --noconfirm "$package" && INSTALLED_DEPS+=("$package")
                else
                    print_warning "No AUR helper (yay/paru) found. Cannot install $package automatically."
                    return 1
                fi
            else
                print_info "Installing $package via pacman..."
                if $INSTALL_CMD "$package"; then
                    INSTALLED_DEPS+=("$package")
                else
                    # Try AUR as fallback for Arch
                    print_info "Pacman did not find $package, trying AUR..."
                    if command_exists yay; then
                        yay -S --noconfirm "$package" && INSTALLED_DEPS+=("$package")
                    elif command_exists paru; then
                        paru -S --noconfirm "$package" && INSTALLED_DEPS+=("$package")
                    else
                        print_warning "Cannot install $package"
                        return 1
                    fi
                fi
            fi
            ;;
        "apt")
            print_info "Installing $package via apt..."
            if $INSTALL_CMD "$package"; then
                INSTALLED_DEPS+=("$package")
            else
                print_warning "Failed to install $package via apt"
                return 1
            fi
            ;;
        "dnf")
            print_info "Installing $package via dnf..."
            if $INSTALL_CMD "$package"; then
                INSTALLED_DEPS+=("$package")
            else
                print_warning "Failed to install $package via dnf"
                return 1
            fi
            ;;
        *)
            print_error "Unknown package manager: $PACKAGE_MANAGER"
            return 1
            ;;
    esac
}

# Check and install dependencies
check_dependencies() {
    print_header "Checking Dependencies"
    
    print_step "Checking required dependencies..."
    # Required dependencies
    check_dependency "quickshell" "quickshell" false
    
    echo ""
    print_step "Checking optional dependencies..."
    # Optional dependencies
    check_dependency "cava" "cava" true
    check_dependency "playerctl" "playerctl" true
    check_dependency "pactl" "pulseaudio" true
    
    # Bluetooth (check for bluetoothctl)
    if command_exists "bluetoothctl"; then
        print_success "bluetoothctl is available"
    else
        print_warning "bluetoothctl is not available (optional)"
        OPTIONAL_DEPS+=("bluez-utils")
    fi
    
    # GPU monitoring tools
    if command_exists "nvidia-smi"; then
        print_success "nvidia-smi is available (NVIDIA GPU)"
    elif command_exists "radeontop"; then
        print_success "radeontop is available (AMD GPU)"
    elif command_exists "intel_gpu_top"; then
        print_success "intel_gpu_top is available (Intel GPU)"
    else
        print_warning "GPU monitoring tools are not available (optional)"
    fi
    
    # Sensors
    check_dependency "sensors" "lm_sensors" true
    
    # Package manager specific tools
    case $PACKAGE_MANAGER in
        "pacman")
            # AUR helpers (for optional AUR packages)
            if command_exists "yay" || command_exists "paru"; then
                print_success "AUR helper is available"
            else
                print_warning "AUR helper (yay/paru) is not installed (optional)"
            fi
            ;;
        *)
            print_info "Using $PACKAGE_MANAGER package manager"
            ;;
    esac
    
    echo ""
    
    # Install missing required dependencies
    if [ ${#MISSING_DEPS[@]} -gt 0 ]; then
        print_header "Installing Required Dependencies"
        check_sudo
        
        for dep in "${MISSING_DEPS[@]}"; do
            install_dependency "$dep" false || print_error "Failed to install $dep"
        done
    fi
    
    # Ask about optional dependencies
    if [ ${#OPTIONAL_DEPS[@]} -gt 0 ]; then
        echo ""
        print_info "Found optional dependencies that may enhance functionality:"
        for dep in "${OPTIONAL_DEPS[@]}"; do
            echo -e "    ${CYAN}•${NC} $dep"
        done
        echo ""
        read -p "$(echo -e ${YELLOW}Would you like to install optional dependencies? [y/N]: ${NC})" install_optional
        
        if [[ "$install_optional" =~ ^[Yy]$ ]]; then
            print_header "Installing Optional Dependencies"
            check_sudo
            
            for dep in "${OPTIONAL_DEPS[@]}"; do
                # Check if it's an AUR package (quickshell might be AUR)
                if [ "$dep" = "quickshell" ]; then
                    install_dependency "$dep" true || print_warning "Failed to install $dep"
                else
                    install_dependency "$dep" false || print_warning "Failed to install $dep"
                fi
            done
        else
            print_info "Skipping optional dependencies"
        fi
    fi
}

# Setup directories
setup_directories() {
    print_header "Directory Setup"
    
    print_step "Creating configuration directories..."
    # Create config directory
    if [ ! -d "$CONFIG_DIR" ]; then
        mkdir -p "$CONFIG_DIR"
        print_success "Created configuration directory: $CONFIG_DIR"
    else
        print_info "Configuration directory already exists: $CONFIG_DIR"
    fi
    
    # Create wallpaper directory
    if [ ! -d "$WALLPAPER_DIR" ]; then
        mkdir -p "$WALLPAPER_DIR"
        print_success "Created wallpaper directory: $WALLPAPER_DIR"
        print_info "You can now add wallpapers to this directory"
    else
        print_info "Wallpaper directory already exists: $WALLPAPER_DIR"
    fi
    
    echo ""
    print_step "Verifying project structure..."
    # Verify script directory structure
    if [ ! -f "$SCRIPT_DIR/shell.qml" ]; then
        print_error "shell.qml not found in $SCRIPT_DIR"
        print_error "Please ensure you're running the installer from the correct directory"
        exit 1
    fi
    
    if [ ! -d "$SCRIPT_DIR/components" ]; then
        print_error "components directory not found in $SCRIPT_DIR"
        exit 1
    fi
    
    print_success "Project structure is valid"
}

# Copy configuration files
copy_files() {
    print_header "Copying Configuration Files"

    print_step "Copying main configuration files..."

    # List of files to copy from root directory
    local root_files=("shell.qml" "run.sh" "README.md" "open-clipboard.sh" "open-launcher.sh" "toggle-menu.sh")

    # Copy root files
    for file in "${root_files[@]}"; do
        if [ -f "$SCRIPT_DIR/$file" ]; then
            cp "$SCRIPT_DIR/$file" "$CONFIG_DIR/"
            print_success "Copied: $file"
        else
            print_warning "File not found: $file"
        fi
    done

    echo ""
    print_step "Copying component files..."

    # Copy components directory
    if [ -d "$SCRIPT_DIR/components" ]; then
        mkdir -p "$CONFIG_DIR/components"
        cp -r "$SCRIPT_DIR/components/"* "$CONFIG_DIR/components/" 2>/dev/null || true
        local component_count=$(find "$CONFIG_DIR/components" -type f | wc -l)
        print_success "Copied $component_count component files"
    else
        print_error "Components directory not found"
        exit 1
    fi

    echo ""
    print_step "Copying script files..."

    # Copy scripts directory
    if [ -d "$SCRIPT_DIR/scripts" ]; then
        mkdir -p "$CONFIG_DIR/scripts"
        cp -r "$SCRIPT_DIR/scripts/"* "$CONFIG_DIR/scripts/" 2>/dev/null || true
        local script_count=$(find "$CONFIG_DIR/scripts" -type f | wc -l)
        print_success "Copied $script_count script files"
    else
        print_error "Scripts directory not found"
        exit 1
    fi

    echo ""
    print_step "Setting proper permissions..."

    # Make all .sh scripts executable
    find "$CONFIG_DIR" -name "*.sh" -type f -exec chmod +x {} \;
    find "$CONFIG_DIR/scripts" -name "*.py" -type f -exec chmod +x {} \;

    print_success "All files copied and permissions set"
}


# Setup colors.json
setup_colors() {
    print_header "Color Configuration"
    
    # Default colors (from shell.qml)
    DEFAULT_BACKGROUND="#0a0a0a"
    DEFAULT_PRIMARY="#1a1a1a"
    DEFAULT_SECONDARY="#141414"
    DEFAULT_TEXT="#ffffff"
    DEFAULT_ACCENT="#4a9eff"
    
    if [ -f "$COLORS_FILE" ]; then
        print_info "colors.json file already exists: $COLORS_FILE"
        read -p "$(echo -e ${YELLOW}Would you like to overwrite the existing color configuration? [y/N]: ${NC})" overwrite_colors
        if [[ ! "$overwrite_colors" =~ ^[Yy]$ ]]; then
            print_info "Keeping existing color configuration"
            return 0
        fi
    fi
    
    print_step "Creating colors.json with default values..."
    # Create colors.json with default values
    cat > "$COLORS_FILE" << EOF
{
  "background": "$DEFAULT_BACKGROUND",
  "primary": "$DEFAULT_PRIMARY",
  "secondary": "$DEFAULT_SECONDARY",
  "text": "$DEFAULT_TEXT",
  "accent": "$DEFAULT_ACCENT"
}
EOF
    
    print_success "Created colors.json with default values"
    print_info "You can change colors later in the launcher settings"
}

# Show final instructions
show_instructions() {
    print_header "Installation Complete!"
    
    echo ""
    echo -e "${GREEN}${BOLD}SharpShell has been successfully installed!${NC}"
    echo ""
    echo -e "${CYAN}${BOLD}Next Steps:${NC}"
    echo ""
    echo -e "${YELLOW}1. Keyboard Shortcuts Configuration (Hyprland):${NC}"
    echo -e "   Add the following entries to ${CYAN}~/.config/hyprland/hyprland.conf${NC}:"
    echo ""
    echo -e "   ${MAGENTA}# SharpShell shortcuts${NC}"
    echo -e "   ${GREEN}bind = SUPER, R, exec, $CONFIG_DIR/open-launcher.sh${NC}"
    echo -e "   ${GREEN}bind = SUPER, M, exec, $CONFIG_DIR/toggle-menu.sh${NC}"
    echo -e "   ${GREEN}bind = SUPER, V, exec, $CONFIG_DIR/open-clipboard.sh${NC}"
    echo ""
    echo -e "${YELLOW}2. Running Quickshell:${NC}"
    echo -e "   Ensure Quickshell is configured to use:"
    echo -e "   ${CYAN}$CONFIG_DIR/shell.qml${NC}"
    echo ""
    echo -e "   You can run quickshell manually:"
    echo -e "   ${GREEN}$CONFIG_DIR/run.sh${NC}"
    echo ""
    echo -e "   ${CYAN}Note:${NC} All SharpShell files have been copied to $CONFIG_DIR"
    echo ""
    echo -e "${YELLOW}3. Adding Wallpapers:${NC}"
    echo -e "   Place your wallpapers in: ${CYAN}$WALLPAPER_DIR${NC}"
    echo -e "   Supported formats: ${GREEN}JPG, JPEG, PNG, WEBP, GIF${NC}"
    echo ""
    echo -e "${CYAN}${BOLD}Configuration Files:${NC}"
    echo -e "  ${GREEN}•${NC} Color configuration: ${CYAN}$COLORS_FILE${NC}"
    echo -e "  ${GREEN}•${NC} Main file: ${CYAN}$CONFIG_DIR/shell.qml${NC}"
    echo ""
    
    if [ ${#INSTALLED_DEPS[@]} -gt 0 ]; then
        echo -e "${GREEN}${BOLD}Installed Packages:${NC}"
        for dep in "${INSTALLED_DEPS[@]}"; do
            echo -e "  ${GREEN}•${NC} $dep"
        done
        echo ""

    echo -e "${CYAN}${BOLD}Package Manager Used:${NC} $PACKAGE_MANAGER"
    fi
    
    echo -e "${GREEN}${BOLD}Enjoy using SharpShell!${NC}"
    echo ""
}

# Main installation function
main() {
    clear
    echo -e "${CYAN}"
    echo "  ███████ ██   ██  █████  ██████  ██████  ███████   ███████ ██   ██ ███████ ██      "
    echo "  ██      ██   ██ ██   ██ ██   ██ ██   ██ ██        ██      ██   ██ ██      ██      "
    echo "  ███████ ███████ ███████ ██████  ██████  ███████   █████   ███████ █████   ██      "
    echo "       ██ ██   ██ ██   ██ ██   ██ ██           ██   ██      ██   ██ ██      ██      "
    echo "  ███████ ██   ██ ██   ██ ██   ██ ██      ███████   ███████ ██   ██ ███████ ███████ "
    echo -e "${NC}"
    print_header "SharpShell Installer"
    echo -e "${BLUE}This script will configure SharpShell for Quickshell${NC}"
    echo ""
    
    # Verify we're in the right directory
    if [ ! -f "$SCRIPT_DIR/shell.qml" ]; then
        print_error "shell.qml not found in current directory"
        print_error "Please run the installer from the sharpshell directory"
        exit 1
    fi
    
    # Detect package manager first
    detect_package_manager

    # Run installation steps
    check_dependencies

    # Verify quickshell is installed after dependency check
    if ! command_exists quickshell; then
        print_error "Quickshell is not installed!"
        print_info "Quickshell is required for SharpShell to work"

        case $PACKAGE_MANAGER in
            "pacman")
                print_info "Install it from AUR: ${CYAN}yay -S quickshell${NC} or ${CYAN}paru -S quickshell${NC}"
                ;;
            "apt")
                print_info "Install it from repository: ${CYAN}sudo apt install quickshell${NC}"
                ;;
            "dnf")
                print_info "Install it from repository: ${CYAN}sudo dnf install quickshell${NC}"
                ;;
            *)
                print_info "Install quickshell for your package manager"
                ;;
        esac
        exit 1
    fi

    setup_directories
    copy_files
    setup_colors
    show_instructions
}

# Run main function
main

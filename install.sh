#!/bin/bash

# Dart (Alloy Shell) - Advanced Installer
# This script prepares the environment and optimizes Dart for your machine.

set -e

# --- Configuration ---
PROJECT_NAME="Dart"
TARGET_DIR="$HOME/.config/alloy/dart"
DEPENDENCIES=("quickshell" "playerctl" "cava" "grim" "slurp")

# --- UI Helpers ---
BOLD='\033[1m'
CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

print_step() { echo -e "${CYAN}==>${NC} ${BOLD}$1${NC}"; }
print_success() { echo -e "${GREEN}SUCCESS:${NC} $1"; }
print_error() { echo -e "${RED}ERROR:${NC} $1"; }

# --- Logic ---
check_deps() {
    print_step "Checking dependencies..."
    for dep in "${DEPENDENCIES[@]}"; do
        if command -v "$dep" >/dev/null 2>&1; then
            echo -e "  [${GREEN}✓${NC}] $dep"
        else
            echo -e "  [${RED}✗${NC}] $dep (Missing)"
        fi
    done
}

init_config() {
    print_step "Initializing configuration..."
    mkdir -p "$HOME/.config/alloy"
    
    if [ ! -f "$HOME/.config/alloy/colors.json" ]; then
        cat <<EOF > "$HOME/.config/alloy/colors.json"
{
  "background": "#0a0a0a",
  "primary": "#1a1a1a",
  "secondary": "#151515",
  "text": "#ffffff",
  "accent": "#4a9eff",
  "uiScale": 100,
  "colorPreset": "Professional Modern"
}
EOF
        print_success "Created default colors.json at ~/.config/alloy/"
    fi
}

setup_permissions() {
    print_step "Optimizing script permissions..."
    find . -name "*.sh" -exec chmod +x {} \;
    print_success "All scripts are now executable."
}

main() {
    echo -e "${CYAN}${BOLD}$PROJECT_NAME Installer${NC}"
    echo "----------------------------"
    
    check_deps
    init_config
    setup_permissions
    
    echo ""
    print_success "$PROJECT_NAME installation is ready."
    echo -e "To start the shell, run: ${BOLD}./run.sh${NC}"
}

main "$@"
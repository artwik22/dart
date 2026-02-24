#!/bin/bash
# =============================================================================
# Dart – uruchomienie quickshell (Alloy/SharpShell)
# Ścieżka projektu musi być ustawiona przed startem.
# Do przełączania menu/dashboardu: ./toggle-menu.sh (lub bind w Hyprland).
# =============================================================================

export QML_XHR_ALLOW_FILE_READ=1
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
export QUICKSHELL_PROJECT_PATH="$SCRIPT_DIR"

# Skalowanie UI z ~/.config/alloy/colors.json (uiScale: 75, 100, 125)
CONFIG_ALLOY="${HOME}/.config/alloy/colors.json"
if [ -f "$CONFIG_ALLOY" ]; then
    SCALE=$(grep '"uiScale"' "$CONFIG_ALLOY" 2>/dev/null | grep -oE '[0-9]+' | head -1)
    case "${SCALE:-100}" in
        75)  export QT_SCALE_FACTOR=0.75 ;;
        125) export QT_SCALE_FACTOR=1.25 ;;
        *)   export QT_SCALE_FACTOR=1.0 ;;
    esac
fi

# Tryb low-perf: touch ~/.config/alloy/low-perf i zrestartuj shella
[ -f "${HOME}/.config/alloy/low-perf" ] && echo 1 > /tmp/quickshell_low_perf || echo 0 > /tmp/quickshell_low_perf

# Ścieżka do colors.json (Alloy) – Dart ładuje stąd kolory = preset z Fuse
[ -f "${HOME}/.config/alloy/colors.json" ] && echo "${HOME}/.config/alloy/colors.json" > /tmp/quickshell_colors_path

# Apply script settings
[ -x "${HOME}/.config/alloy/scripts/apply-settings.sh" ] && "${HOME}/.config/alloy/scripts/apply-settings.sh"

# Run lockscreen immediately on startup
echo "showLockScreen" > /tmp/quickshell_command

exec quickshell --path "$QUICKSHELL_PROJECT_PATH"

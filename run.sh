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

# Run lockscreen on startup if enabled (default true)
LOCKSCREEN_ENABLED="true"
if command -v jq >/dev/null 2>&1 && [ -f "$CONFIG_ALLOY" ]; then
    LOCKSCREEN_ENABLED=$(jq -r 'if has("scriptsAutostartLockscreen") then .scriptsAutostartLockscreen else true end' "$CONFIG_ALLOY")
fi

if [ "$LOCKSCREEN_ENABLED" = "true" ]; then
    echo "showLockScreen" > /tmp/quickshell_command
fi

# Script Autostart Logic
if command -v jq >/dev/null 2>&1 && [ -f "$CONFIG_ALLOY" ]; then
    # Parse flags and configurations
    AUTOFLOAT_ENABLED=$(jq -r '.scriptsAutostartAutofloat // false' "$CONFIG_ALLOY")
    AUTOFLOAT_W=$(jq -r '.autofloatWidth // 1400' "$CONFIG_ALLOY")
    AUTOFLOAT_H=$(jq -r '.autofloatHeight // 920' "$CONFIG_ALLOY")
    
    BATTERY_ENABLED=$(jq -r '.scriptsAutostartBattery // false' "$CONFIG_ALLOY")
    BATTERY_THRESH=$(jq -r '.batteryThreshold // 20' "$CONFIG_ALLOY")
    
    SCREENSAVER_ENABLED=$(jq -r '.scriptsAutostartScreensaver // false' "$CONFIG_ALLOY")
    SCREENSAVER_TIMEOUT=$(jq -r '.screensaverTimeout // 300' "$CONFIG_ALLOY")
    SCREENSAVER_LOCKSCREEN=$(jq -r '.scriptsUseLockscreen // false' "$CONFIG_ALLOY")
    
    # Kill old instances to avoid duplicates
    killall auto-float.sh battery_monitor.sh idle-screensaver.sh 2>/dev/null || true
    
    # Start scripts if enabled
    if [ "$AUTOFLOAT_ENABLED" = "true" ]; then
        if [ -x "${QUICKSHELL_PROJECT_PATH}/scripts/auto-float.sh" ]; then
            "${QUICKSHELL_PROJECT_PATH}/scripts/auto-float.sh" "$AUTOFLOAT_W" "$AUTOFLOAT_H" &
        fi
    fi
    
    if [ "$BATTERY_ENABLED" = "true" ]; then
        if [ -x "${QUICKSHELL_PROJECT_PATH}/scripts/battery_monitor.sh" ]; then
            "${QUICKSHELL_PROJECT_PATH}/scripts/battery_monitor.sh" "$BATTERY_THRESH" &
        fi
    fi
    
    if [ "$SCREENSAVER_ENABLED" = "true" ]; then
        if [ -x "${QUICKSHELL_PROJECT_PATH}/scripts/idle-screensaver.sh" ]; then
            "${QUICKSHELL_PROJECT_PATH}/scripts/idle-screensaver.sh" "$SCREENSAVER_TIMEOUT" "$SCREENSAVER_LOCKSCREEN" &
        fi
    fi
fi

exec quickshell --path "$QUICKSHELL_PROJECT_PATH"

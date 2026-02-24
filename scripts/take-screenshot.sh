#!/bin/bash
# Screenshot Service - Take screenshot with area selection
# Uses grim + slurp for Wayland
# Saves to ~/Pictures/Screenshots/ and copies to clipboard
# Styled to match the Alloy color theme

# Screenshots directory
SCREENSHOTS_DIR="$HOME/Pictures/Screenshots"
mkdir -p "$SCREENSHOTS_DIR"

# Generate filename with timestamp
TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
FILENAME="screenshot_${TIMESTAMP}.png"
FILEPATH="$SCREENSHOTS_DIR/$FILENAME"

# ── Check dependencies ──────────────────────────────────────────────────
if ! command -v grim &> /dev/null; then
    notify-send -a "Alloy" "Screenshot Error" "grim is not installed.\nInstall: sudo pacman -S grim" 2>/dev/null
    exit 1
fi

if ! command -v slurp &> /dev/null; then
    notify-send -a "Alloy" "Screenshot Error" "slurp is not installed.\nInstall: sudo pacman -S slurp" 2>/dev/null
    exit 1
fi

# ── Read accent color from theme ────────────────────────────────────────
ACCENT="#4a9eff"
COLORS_FILE="$HOME/.config/alloy/colors.json"
if [ -f "$COLORS_FILE" ] && command -v python3 &> /dev/null; then
    THEME_ACCENT=$(python3 -c "
import json, sys
try:
    with open('$COLORS_FILE') as f:
        data = json.load(f)
    # Resolve preset if active
    preset = data.get('colorPreset', '')
    presets = data.get('presets', {})
    if preset and preset in presets:
        accent = presets[preset].get('accent', data.get('accent', ''))
    else:
        accent = data.get('accent', '')
    if accent and accent.startswith('#') and len(accent) >= 7:
        print(accent[:7])
except:
    pass
" 2>/dev/null)
    [ -n "$THEME_ACCENT" ] && ACCENT="$THEME_ACCENT"
fi

# Derive colors from accent
BORDER_COLOR="$ACCENT"
SELECTION_FILL="${ACCENT}40"     # accent at ~25% opacity (inside selection)
OVERLAY_BG="#00000088"           # semi-transparent dark overlay (lighter than before)

# ── Area selection with styled slurp ────────────────────────────────────
# -b: background overlay  -c: border color  -s: selection fill
# -w: border width        -d: show dimensions at cursor
SELECTION=$(slurp \
    -b "$OVERLAY_BG" \
    -c "${BORDER_COLOR}ff" \
    -s "$SELECTION_FILL" \
    -w 4 \
    -d \
    2>&1)
SLURP_EXIT=$?

# Check if user cancelled
if [ $SLURP_EXIT -ne 0 ] || [ -z "$SELECTION" ]; then
    exit 0
fi

# ── Take screenshot ─────────────────────────────────────────────────────
if grim -g "$SELECTION" "$FILEPATH"; then
    # Copy to clipboard with explicit MIME type
    if command -v wl-copy &> /dev/null; then
        wl-copy --type image/png < "$FILEPATH" 2>/dev/null
    fi

    # Play camera shutter sound (non-blocking)
    if command -v pw-play &> /dev/null; then
        for snd in \
            /usr/share/sounds/freedesktop/stereo/camera-shutter.oga \
            /usr/share/sounds/freedesktop/stereo/screen-capture.oga \
            /usr/share/sounds/freedesktop/stereo/complete.oga; do
            if [ -f "$snd" ]; then
                pw-play "$snd" &
                break
            fi
        done
    elif command -v paplay &> /dev/null; then
        for snd in \
            /usr/share/sounds/freedesktop/stereo/camera-shutter.oga \
            /usr/share/sounds/freedesktop/stereo/screen-capture.oga \
            /usr/share/sounds/freedesktop/stereo/complete.oga; do
            if [ -f "$snd" ]; then
                paplay "$snd" &
                break
            fi
        done
    fi

    # Show styled notification with preview
    if command -v notify-send &> /dev/null; then
        notify-send \
            -a "Alloy Screenshot" \
            -i "$FILEPATH" \
            -u normal \
            "✓ Screenshot saved" \
            "$FILENAME\nCopied to clipboard" \
            2>/dev/null
    fi

    echo "$FILEPATH"
    exit 0
else
    if command -v notify-send &> /dev/null; then
        notify-send -a "Alloy" -u critical "✗ Screenshot failed" "An error occurred while capturing." 2>/dev/null
    fi
    exit 1
fi

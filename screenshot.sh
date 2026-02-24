#!/bin/bash
# Alloy Screenshot Script
# Usage: 
#   ./screenshot.sh          - Capture selected area
#   ./screenshot.sh --full   - Capture full screen

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="$DIR/scripts/take-screenshot.sh"

if [ "$1" == "--full" ]; then
    # ── Full screen capture ──────────────────────────────────────────
    SCREENSHOTS_DIR="$HOME/Pictures/Screenshots"
    mkdir -p "$SCREENSHOTS_DIR"
    TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
    FILENAME="screenshot_full_${TIMESTAMP}.png"
    FILEPATH="$SCREENSHOTS_DIR/$FILENAME"

    if ! command -v grim &> /dev/null; then
        notify-send -a "Alloy" "Screenshot Error" "grim is not installed" 2>/dev/null
        exit 1
    fi

    if grim "$FILEPATH"; then
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

        # Styled notification with preview
        if command -v notify-send &> /dev/null; then
            notify-send \
                -a "Alloy Screenshot" \
                -i "$FILEPATH" \
                -u normal \
                "✓ Full screenshot saved" \
                "$FILENAME\nCopied to clipboard" \
                2>/dev/null
        fi

        echo "$FILEPATH"
    else
        notify-send -a "Alloy" -u critical "✗ Screenshot failed" "An error occurred" 2>/dev/null
        exit 1
    fi
else
    # ── Area selection via take-screenshot.sh ─────────────────────────
    if [ -f "$SCRIPT" ]; then
        bash "$SCRIPT"
    else
        bash ~/.config/alloy/dart/scripts/take-screenshot.sh
    fi
fi

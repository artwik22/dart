#!/bin/bash
# Alloy Screenshot Script
# Usage: 
#   ./screenshot.sh          - Capture selected area
#   ./screenshot.sh --full   - Capture full screen

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="$DIR/scripts/take-screenshot.sh"

if [ "$1" == "--full" ]; then
    # Full screen logic
    SCREENSHOTS_DIR="$HOME/Pictures/Screenshots"
    mkdir -p "$SCREENSHOTS_DIR"
    TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
    FILENAME="screenshot_full_${TIMESTAMP}.png"
    FILEPATH="$SCREENSHOTS_DIR/$FILENAME"
    
    if command -v grim &> /dev/null; then
        grim "$FILEPATH"
        if command -v wl-copy &> /dev/null; then
            wl-copy < "$FILEPATH"
        fi
        if command -v notify-send &> /dev/null; then
            notify-send "Full Screenshot Taken" "Saved to: $FILENAME" -i "$FILEPATH"
        fi
        echo "$FILEPATH"
    else
        notify-send "Screenshot Error" "grim is not installed"
        exit 1
    fi
else
    # Default: Area selection via existing script
    if [ -f "$SCRIPT" ]; then
        bash "$SCRIPT"
    else
        # Fallback if scripts dir doesn't exist
        ~/.config/alloy/dart/scripts/take-screenshot.sh
    fi
fi

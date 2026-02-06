#!/bin/bash
# Screenshot Service - Take screenshot with area selection
# Uses grim + slurp for Wayland
# Saves to ~/Pictures/Screenshots/ and copies to clipboard

# Screenshots directory
SCREENSHOTS_DIR="$HOME/Pictures/Screenshots"
mkdir -p "$SCREENSHOTS_DIR"

# Generate filename with timestamp
TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
FILENAME="screenshot_${TIMESTAMP}.png"
FILEPATH="$SCREENSHOTS_DIR/$FILENAME"

# Check if grim and slurp are available
if ! command -v grim &> /dev/null; then
    notify-send "Screenshot Error" "grim is not installed. Install it with: sudo pacman -S grim" 2>/dev/null || echo "grim not installed"
    exit 1
fi

if ! command -v slurp &> /dev/null; then
    notify-send "Screenshot Error" "slurp is not installed. Install it with: sudo pacman -S slurp" 2>/dev/null || echo "slurp not installed"
    exit 1
fi

# Take screenshot with area selection
# Use slurp to get selection, then grim to capture
# slurp returns geometry in format: x,y widthxheight
# grim -g takes geometry in format: x,y widthxheight

# Debug: Log that we're starting
echo "Starting screenshot selection..." >&2

# Run slurp and capture its output
# slurp needs to run in foreground to allow user interaction
# -b sets background color (dark overlay): #000000cc = black with ~80% opacity for better contrast
# -c sets border color: #ffffff = white border for better visibility
# -s sets selection color: #00000000 = fully transparent (no highlight inside selection)
# -w sets border weight: 3 = thicker border for better visibility
SELECTION=$(slurp -b "#000000cc" -c "#ffffff" -s "#00000000" -w 3 2>&1)
SLURP_EXIT=$?

# Debug: Log the result
echo "Slurp exit code: $SLURP_EXIT" >&2
echo "Selection: $SELECTION" >&2

# Check if user cancelled (slurp exits with non-zero on cancel) or selection is empty
if [ $SLURP_EXIT -ne 0 ] || [ -z "$SELECTION" ]; then
    # User cancelled selection
    echo "Selection cancelled or empty" >&2
    exit 0
fi

# Take screenshot of selected area
if grim -g "$SELECTION" "$FILEPATH"; then
    # Copy to clipboard if wl-copy is available
    if command -v wl-copy &> /dev/null; then
        wl-copy < "$FILEPATH" 2>/dev/null
    fi
    
    # Show notification if notify-send is available
    if command -v notify-send &> /dev/null; then
        notify-send "Screenshot Taken" "Saved to: $FILENAME\nCopied to clipboard" -i "$FILEPATH" 2>/dev/null || \
        notify-send "Screenshot Taken" "Saved to: $FILENAME\nCopied to clipboard" 2>/dev/null
    fi
    
    echo "$FILEPATH"
    exit 0
else
    # Screenshot failed
    if command -v notify-send &> /dev/null; then
        notify-send "Screenshot Failed" "An error occurred while taking the screenshot." 2>/dev/null
    fi
    exit 1
fi


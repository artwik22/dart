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

# ── Check for Flags ──────────────────────────────────────────────────────────
MODE="save"
TARGET="area"
EDIT=false

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --search) MODE="search" ;;
        --window) TARGET="window" ;;
        --full) TARGET="full" ;;
        --edit) EDIT=true ;;
    esac
    shift
done

if [ "$MODE" == "search" ]; then
    FILEPATH="/tmp/lens_search.png"
fi

# ── Define Selection ───────────────────────────────────────────────────────
if [ "$TARGET" == "area" ]; then
    # Area selection with styled slurp
    SELECTION=$(slurp \
        -b "$OVERLAY_BG" \
        -c "${BORDER_COLOR}ff" \
        -s "$SELECTION_FILL" \
        -w 4 \
        -d \
        2>&1)
    SLURP_EXIT=$?
    if [ $SLURP_EXIT -ne 0 ] || [ -z "$SELECTION" ]; then exit 0; fi
elif [ "$TARGET" == "window" ]; then
    # Get active window geometry from hyprctl (assuming Hyprland)
    WINDOW_DATA=$(hyprctl activewindow -j)
    X=$(echo "$WINDOW_DATA" | jq -r '.at[0]')
    Y=$(echo "$WINDOW_DATA" | jq -r '.at[1]')
    W=$(echo "$WINDOW_DATA" | jq -r '.size[0]')
    H=$(echo "$WINDOW_DATA" | jq -r '.size[1]')
    SELECTION="${X},${Y} ${W}x${H}"
else
    # Full screen
    SELECTION=""
fi

# ── Take screenshot ─────────────────────────────────────────────────────
GRIM_CMD="grim"
if [ -n "$SELECTION" ]; then
    GRIM_CMD="grim -g \"$SELECTION\""
fi

if eval "$GRIM_CMD \"$FILEPATH\""; then
    if [ "$MODE" == "search" ]; then
        # Circle to Search logic ... (rest of search logic same as before)
        notify-send -a "Alloy" "Circle to Search" "Opening Google Lens..." -i "$FILEPATH" -t 3000
        # ... (keep the python base64 upload logic)
        HTML_PATH="/tmp/lens_upload_$$.html"
        python3 -c "
import base64, sys
image_path = '$FILEPATH'
html_path = '$HTML_PATH'
try:
    with open(image_path, 'rb') as f: img_data = f.read()
    b64_data = base64.b64encode(img_data).decode('utf-8')
    html_content = f\"\"\"
    <!DOCTYPE html><html><body onload='submitForm()'><script>
    function submitForm() {{
        const blob = new Blob([new Uint8Array(atob('{b64_data}').split('').map(c => c.charCodeAt(0)))], {{type: 'image/png'}});
        const file = new File([blob], 'image.png', {{type: 'image/png'}});
        const form = document.createElement('form'); form.method = 'POST'; form.action = 'https://lens.google.com/v3/upload'; form.enctype = 'multipart/form-data';
        const input = document.createElement('input'); input.type = 'file'; input.name = 'encoded_image';
        const dt = new DataTransfer(); dt.items.add(file); input.files = dt.files;
        form.appendChild(input); document.body.appendChild(form); form.submit();
    }}
    </script></body></html>
    \"\"\"
    with open(html_path, 'w') as f: f.write(html_content)
except: sys.exit(1)
"
        [ -f "$HTML_PATH" ] && xdg-open "$HTML_PATH" || notify-send -a "Alloy" "Error" "Failed to process image."
        exit 0
    fi

    # Normal logic
    [ -z "$EDIT" ] || command -v wl-copy &> /dev/null && wl-copy --type image/png < "$FILEPATH" 2>/dev/null
    
    # Sound
    if command -v pw-play &> /dev/null; then
        for snd in /usr/share/sounds/freedesktop/stereo/camera-shutter.oga /usr/share/sounds/freedesktop/stereo/screen-capture.oga; do
            if [ -f "$snd" ]; then pw-play "$snd" & break; fi
        done
    fi

    # ── Notification / Thumbnail / Edit ───────────────────────────────────
    if [ "$EDIT" = true ]; then
        if pgrep -x quickshell > /dev/null; then
            echo "editScreenshot $FILEPATH" > /tmp/quickshell_command
        elif command -v swappy &> /dev/null; then
            swappy -f "$FILEPATH" -o "$FILEPATH"
        fi
    elif pgrep -x quickshell > /dev/null; then
        echo "showThumbnail $FILEPATH" > /tmp/quickshell_command
    else
        notify-send -a "Alloy Screenshot" -i "$FILEPATH" "✓ Screenshot saved" "${FILENAME}\nCopied to clipboard"
    fi

    echo "$FILEPATH"
else
    notify-send -a "Alloy" -u critical "✗ Screenshot failed"
    exit 1
fi

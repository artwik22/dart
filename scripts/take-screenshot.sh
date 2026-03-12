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

# ── Check for Search Flag ───────────────────────────────────────────────────
MODE="save"
if [ "$1" == "--search" ]; then
    MODE="search"
    FILEPATH="/tmp/lens_search.png"
fi

# ── Take screenshot ─────────────────────────────────────────────────────
if grim -g "$SELECTION" "$FILEPATH"; then
    if [ "$MODE" == "search" ]; then
        # Circle to Search logic (upload to Google Lens)
        notify-send -a "Alloy" "Circle to Search" "Opening Google Lens..." -i "$FILEPATH" -t 3000

        HTML_PATH="/tmp/lens_upload_$$.html"
        python3 -c "
import base64
import sys

image_path = '$FILEPATH'
html_path = '$HTML_PATH'

try:
    with open(image_path, 'rb') as f:
        img_data = f.read()
        
    b64_data = base64.b64encode(img_data).decode('utf-8')
    mime_type = 'image/png'
    
    html_content = f\"\"\"
    <!DOCTYPE html>
    <html lang=\"en\">
    <head>
        <meta charset=\"UTF-8\">
        <title>Searching with Google Lens...</title>
        <style>
            body {{ background-color: #121212; color: #ffffff; font-family: system-ui, -apple-system, sans-serif; display: flex; align-items: center; justify-content: center; height: 100vh; margin: 0; }}
            .loader {{ border: 4px solid #333; border-top: 4px solid #4a9eff; border-radius: 50%; width: 40px; height: 40px; animation: spin 1s linear infinite; margin-bottom: 20px; }}
            @keyframes spin {{ 0% {{ transform: rotate(0deg); }} 100% {{ transform: rotate(360deg); }} }}
            .container {{ text-align: center; }}
        </style>
    </head>
    <body onload=\"submitForm()\">
        <div class=\"container\">
            <div class=\"loader\" style=\"margin: 0 auto;\"></div>
            <p>Uploading to Google Lens...</p>
        </div>
        
        <script>
            function submitForm() {{
                const byteCharacters = atob('{b64_data}');
                const byteNumbers = new Array(byteCharacters.length);
                for (let i = 0; i < byteCharacters.length; i++) {{
                    byteNumbers[i] = byteCharacters.charCodeAt(i);
                }}
                const byteArray = new Uint8Array(byteNumbers);
                const blob = new Blob([byteArray], {{type: '{mime_type}'}});
                const file = new File([blob], 'image.png', {{type: '{mime_type}'}});
                
                const form = document.createElement('form');
                form.method = 'POST';
                form.action = 'https://lens.google.com/v3/upload';
                form.enctype = 'multipart/form-data';
                form.style.display = 'none';
                
                const input = document.createElement('input');
                input.type = 'file';
                input.name = 'encoded_image';
                
                const dt = new DataTransfer();
                dt.items.add(file);
                input.files = dt.files;
                
                form.appendChild(input);
                document.body.appendChild(form);
                
                form.submit();
            }}
        </script>
    </body>
    </html>
    \"\"\"
    with open(html_path, 'w') as f:
        f.write(html_content)
        
except Exception as e:
    sys.exit(1)
"
        if [ -f "$HTML_PATH" ]; then
            xdg-open "$HTML_PATH"
        else
            notify-send -a "Alloy" -u critical "Circle to Search" "Failed to process image."
        fi
        exit 0

    else
        # Normal Save logic
        if command -v wl-copy &> /dev/null; then
            wl-copy --type image/png < "$FILEPATH" 2>/dev/null
        fi

        # Play camera shutter sound
        if command -v pw-play &> /dev/null; then
            for snd in /usr/share/sounds/freedesktop/stereo/camera-shutter.oga /usr/share/sounds/freedesktop/stereo/screen-capture.oga /usr/share/sounds/freedesktop/stereo/complete.oga; do
                if [ -f "$snd" ]; then pw-play "$snd" & break; fi
            done
        elif command -v paplay &> /dev/null; then
            for snd in /usr/share/sounds/freedesktop/stereo/camera-shutter.oga /usr/share/sounds/freedesktop/stereo/screen-capture.oga /usr/share/sounds/freedesktop/stereo/complete.oga; do
                if [ -f "$snd" ]; then paplay "$snd" & break; fi
            done
        fi

        # Show notification
        if command -v notify-send &> /dev/null; then
            notify-send -a "Alloy Screenshot" -i "$FILEPATH" -u normal "✓ Screenshot saved" "$FILENAME\nCopied to clipboard" 2>/dev/null
        fi

        echo "$FILEPATH"
        exit 0
    fi
else
    if command -v notify-send &> /dev/null; then
        notify-send -a "Alloy" -u critical "✗ Screenshot failed" "An error occurred while capturing." 2>/dev/null
    fi
    exit 1
fi

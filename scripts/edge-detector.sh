#!/bin/bash
# Edge detector for MangoWM - polls mouse position and detects right edge hover
# Writes state to /tmp/qs_edge_state for Quickshell to read

EDGE_THRESHOLD=20
POLL_INTERVAL=100ms

while true; do
    # Get cursor position using wlr-randr or swaymsg
    # Fallback to reading from evdev or using a Python script
    
    # Method 1: Try ydotool (if available)
    if command -v ydotool &>/dev/null; then
        POS=$(ydotool getcursorpos 2>/dev/null | awk '{print $1, $2}')
        X=$(echo $POS | cut -d' ' -f1)
        Y=$(echo $POS | cut -d' ' -f2)
    # Method 2: Try swaymsg (works on wlroots compositors)
    elif command -v swaymsg &>/dev/null; then
        POS=$(swaymsg -t get_cursor 2>/dev/null | grep -oP '"x": \K[0-9.]+' | head -1)
        X=${POS%.*}
    # Method 3: Use wlr-randr to get screen size and calculate edge
    elif command -v wlr-randr &>/dev/null; then
        # Get output dimensions
        OUTPUT=$(wlr-randr 2>/dev/null | grep -A1 "^eDP-1" | head -2)
        WIDTH=$(echo "$OUTPUT" | grep -oP '\d+x\d+' | cut -d'x' -f1)
        # Read from our helper if available
        if [ -f /tmp/qs_mouse_pos ]; then
            POS=$(cat /tmp/qs_mouse_pos)
            X=${POS%% *}
            WIDTH=${WIDTH:-2560}
        else
            X=99999
        fi
    else
        # Fallback: assume we don't detect edge
        X=99999
    fi
    
    # Get screen width (default fallback)
    if [ -z "$WIDTH" ]; then
        WIDTH=2560
    fi
    
    # Check if cursor is at right edge
    if [ "$X" -ge $((WIDTH - EDGE_THRESHOLD)) ] 2>/dev/null; then
        echo "right_edge=1" > /tmp/qs_edge_state
    else
        echo "right_edge=0" > /tmp/qs_edge_state
    fi
    
    sleep $POLL_INTERVAL
done
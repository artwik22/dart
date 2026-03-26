#!/bin/bash
# Edge state writer - reads mouse position and writes edge state
# Should be run in background: ./write-edge-state.sh &

EDGE_THRESHOLD=25
POLL_INTERVAL=0.1

# Get initial screen width (try multiple methods)
get_screen_width() {
    # Try xrandr first (works on most WMs)
    if command -v xrandr &>/dev/null; then
        W=$(xrandr 2>/dev/null | grep -A1 "^eDP-1" | grep -oP '\d+x\d+' | head -1 | cut -d'x' -f1)
        [ -n "$W" ] && echo "$W" && return
    fi
    
    # Fallback to reading from config or default
    echo "2560"
}

SCREEN_WIDTH=$(get_screen_width)

while true; do
    # Try to read from libinput debug or cursor position
    # This is a fallback - the actual detection will happen in QML
    
    # Check if a helper is writing mouse position
    if [ -f /tmp/qs_mouse_helper_x ]; then
        X=$(cat /tmp/qs_mouse_helper_x 2>/dev/null)
        if [ -n "$X" ]; then
            if [ "$X" -ge $((SCREEN_WIDTH - EDGE_THRESHOLD)) ] 2>/dev/null; then
                echo "1"
            else
                echo "0"
            fi > /tmp/qs_edge_state
        fi
    fi
    
    sleep $POLL_INTERVAL
done
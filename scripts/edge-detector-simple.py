#!/usr/bin/env python3
"""
Edge detector helper - reads cursor position from system and writes to file.
This version uses a simple polling approach with /dev/input access.
"""

import os
import sys
import time
import struct

EDGE_THRESHOLD = 25
POLL_INTERVAL = 0.05  # 50ms
STATE_FILE = '/tmp/qs_edge_state'

def read_cursor_from_input():
    """Try to read cursor position from input events."""
    cursor_x = 0
    cursor_y = 0
    
    # Try reading from all input devices
    for f in os.listdir('/dev/input'):
        if not f.startswith('event'):
            continue
        try:
            fd = os.open(f'/dev/input/{f}', os.O_RDONLY | os.O_NONBLOCK)
            # Try to read events (this is a simplified approach)
            # In practice, we'd need to parse EV_REL and EV_ABS events
            os.close(fd)
        except:
            pass
    
    return cursor_x, cursor_y

def get_screen_width():
    """Get screen width - try xrandr first."""
    try:
        import subprocess
        result = subprocess.run(['xrandr'], capture_output=True, text=True)
        # Parse output - look for connected output with dimensions
        for line in result.stdout.split('\n'):
            if 'connected' in line.lower():
                # eDP-1 connected 2560x1440+0+0
                parts = line.split()
                for p in parts:
                    if 'x' in p and '+' in p:
                        w = int(p.split('x')[0])
                        return w
    except:
        pass
    return 2560  # Default fallback

def write_state(in_edge):
    """Write edge state to file."""
    try:
        with open(STATE_FILE, 'w') as f:
            f.write('1' if in_edge else '0')
    except:
        pass

def main():
    """Main loop - poll for edge detection."""
    screen_width = get_screen_width()
    last_edge = False
    
    print(f"Edge detector started, screen width: {screen_width}, threshold: {EDGE_THRESHOLD}", file=sys.stderr)
    
    while True:
        # Read cursor position - for now we use a simplified approach
        # The actual implementation would need proper input device access
        
        # For now, just write 0 (not at edge) - this is a placeholder
        # The real solution needs proper input access
        write_state(False)
        
        time.sleep(POLL_INTERVAL)

if __name__ == '__main__':
    main()
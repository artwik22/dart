#!/usr/bin/env python3
"""
Edge detector - reads cursor position from /dev/input/event* 
and detects right edge hover for MangoWM.
"""

import os
import sys
import time
import select
import struct

EDGE_THRESHOLD = 25
STATE_FILE = '/tmp/qs_edge_state'

# Input event structure (from linux/input.h)
# struct input_event { struct timeval time; __u16 type; __u16 code; __s32 value; }
EVENT_SIZE = struct.calcsize('llHHI')
EV_REL = 0x01
EV_ABS = 0x03
EV_SYN = 0x00
REL_X = 0x00
REL_Y = 0x01
ABS_X = 0x00
ABS_Y = 0x01
SYN_REPORT = 0x00

def find_input_devices():
    """Find input devices that might be mice/touchpads."""
    mice = []
    for f in os.listdir('/dev/input'):
        if not f.startswith('event'):
            continue
        path = f'/dev/input/{f}'
        try:
            fd = os.open(path, os.O_RDONLY | os.O_NONBLOCK)
            mice.append(fd)
        except:
            pass
    return mice

def get_screen_width():
    """Get screen width from xrandr."""
    try:
        import subprocess
        result = subprocess.run(['xrandr'], capture_output=True, text=True)
        for line in result.stdout.split('\n'):
            if 'connected' in line.lower():
                for part in line.split():
                    if 'x' in part and '+' in part:
                        w = int(part.split('x')[0])
                        return w
    except:
        pass
    return 2560

def write_state(in_edge):
    """Write edge state to file."""
    try:
        with open(STATE_FILE, 'w') as f:
            f.write('1' if in_edge else '0')
    except:
        pass

def main():
    """Main event loop."""
    print("Starting edge detector...", file=sys.stderr)
    
    # Find input devices
    devices = []
    for f in os.listdir('/dev/input'):
        if not f.startswith('event'):
            continue
        path = f'/dev/input/{f}'
        try:
            fd = os.open(path, os.O_RDONLY | os.O_NONBLOCK)
            devices.append(fd)
        except:
            pass
    
    if not devices:
        print("No input devices found, exiting", file=sys.stderr)
        sys.exit(1)
    
    print(f"Monitoring {len(devices)} input devices", file=sys.stderr)
    
    screen_width = get_screen_width()
    print(f"Screen width: {screen_width}", file=sys.stderr)
    
    # Track cursor position
    cursor_x = 0
    cursor_y = 0
    last_edge = False
    
    while True:
        # Use select to check for available events
        readable, _, _ = select.select(devices, [], [], 0.05)
        
        for fd in readable:
            try:
                data = os.read(fd, EVENT_SIZE * 64)
                events = []
                for i in range(0, len(data), EVENT_SIZE):
                    if len(data) - i < EVENT_SIZE:
                        break
                    tv_sec, tv_usec, ev_type, ev_code, ev_value = struct.unpack('llHHI', data[i:i+EVENT_SIZE])
                    events.append((ev_type, ev_code, ev_value))
                
                for ev_type, ev_code, ev_value in events:
                    if ev_type == EV_ABS:
                        if ev_code == ABS_X:
                            cursor_x = ev_value
                        elif ev_code == ABS_Y:
                            cursor_y = ev_value
                    elif ev_type == EV_REL:
                        if ev_code == REL_X:
                            cursor_x += ev_value
                        elif ev_code == REL_Y:
                            cursor_y += ev_value
                    elif ev_type == EV_SYN and ev_code == SYN_REPORT:
                        # Check if at edge
                        in_edge = (screen_width - cursor_x) <= EDGE_THRESHOLD if cursor_x >= 0 else False
                        
                        if in_edge != last_edge:
                            last_edge = in_edge
                            write_state(in_edge)
                            print(f"Edge: {in_edge}, cursor_x: {cursor_x}", file=sys.stderr)
                            
            except BlockingIOError:
                pass
            except Exception as e:
                pass
        
        # Also periodically check state even without events
        in_edge = (screen_width - cursor_x) <= EDGE_THRESHOLD if cursor_x >= 0 else False
        if in_edge != last_edge:
            last_edge = in_edge
            write_state(in_edge)

if __name__ == '__main__':
    main()
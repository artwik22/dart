#!/usr/bin/env python3
import os, json, sys

STATS_DIR = os.path.expanduser('~/.cache/alloy')
STATS_FILE = os.path.join(STATS_DIR, 'launch_stats.json')

def update_stats(app_name):
    if not os.path.exists(STATS_DIR):
        os.makedirs(STATS_DIR, exist_ok=True)
        
    stats = {}
    if os.path.exists(STATS_FILE):
        try:
            with open(STATS_FILE, 'r') as f:
                stats = json.load(f)
        except:
            pass
            
    stats[app_name] = stats.get(app_name, 0) + 1
    
    with open(STATS_FILE, 'w') as f:
        json.dump(stats, f)

if __name__ == '__main__':
    if len(sys.argv) > 1:
        update_stats(sys.argv[1])

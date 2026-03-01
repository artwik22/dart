#!/usr/bin/env python3
import os, json, configparser, sys

def get_apps():
    apps = []
    # Added common search paths, including Flatpaks
    dirs = [
        '/usr/share/applications', 
        os.path.expanduser('~/.local/share/applications'),
        '/var/lib/flatpak/exports/share/applications',
        os.path.expanduser('~/.local/share/flatpak/exports/share/applications')
    ]
    
    seen_names = set()
    
    for d in dirs:
        if not os.path.exists(d): continue
        try:
            files = os.listdir(d)
        except:
            continue
            
        for f in files:
            if f.endswith('.desktop'):
                p = configparser.ConfigParser(interpolation=None)
                try:
                    p.read(os.path.join(d,f), encoding='utf-8')
                    if p.has_section('Desktop Entry'):
                        s = p['Desktop Entry']
                        if s.get('NoDisplay', 'false').lower() == 'true': continue
                        if s.get('Type', 'Application') != 'Application': continue
                        
                        name = s.get('Name', '').strip()
                        # Polish name support
                        name_pl = s.get('Name[pl]', '').strip()
                        if name_pl: name = name_pl
                        
                        icon = s.get('Icon', '').strip()
                        exec_cmd = s.get('Exec', '').strip()
                        if not name or not exec_cmd: continue
                        
                        # Use Name as key for deduplication to avoid showing same app twice
                        if name.lower() in seen_names: continue
                        seen_names.add(name.lower())
                        
                        comment = s.get('Comment', '').strip()
                        keywords = s.get('Keywords', '').strip()
                        
                        apps.append({
                            'name': name, 
                            'icon': icon, 
                            'exec': exec_cmd, 
                            'comment': comment,
                            'keywords': keywords,
                            'desktop': os.path.join(d,f)
                        })
                except:
                    pass
    
    # Load launch stats for smart ranking
    stats_file = os.path.expanduser('~/.cache/alloy/launch_stats.json')
    stats = {}
    if os.path.exists(stats_file):
        try:
            with open(stats_file, 'r') as f:
                stats = json.load(f)
        except:
            pass
            
    # Sort alphabetically first
    apps.sort(key=lambda x: x['name'].lower())
    
    # Add stats and sort by frequency for the final JSON if needed
    # Actually, we'll sort in QML for more flexibility, but we include the data here
    for app in apps:
        app['launchCount'] = stats.get(app['name'], 0)
    
    # Write to tmp
    with open('/tmp/alloy_apps.json', 'w') as out:
        json.dump(apps, out)

if __name__ == '__main__':
    get_apps()

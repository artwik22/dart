#!/usr/bin/env python3
import os, json, configparser, sys

def get_apps():
    apps = []
    dirs = ['/usr/share/applications', os.path.expanduser('~/.local/share/applications')]
    for d in dirs:
        if not os.path.exists(d): continue
        for f in oslistdir(d):
            if f.endswith('.desktop'):
                p = configparser.ConfigParser(interpolation=None)
                try:
                    p.read(os.path.join(d,f))
                    if p.has_section('Desktop Entry'):
                        s = p['Desktop Entry']
                        if s.get('NoDisplay', 'false').lower() == 'true': continue
                        if s.get('Type', 'Application') != 'Application': continue
                        
                        name = s.get('Name', '').strip()
                        icon = s.get('Icon', '').strip()
                        exec_cmd = s.get('Exec', '').strip()
                        if name and exec_cmd:
                            apps.append({'name': name, 'icon': icon, 'exec': exec_cmd, 'desktop': os.path.join(d,f)})
                except:
                    pass
    
    # Write to tmp
    with open('/tmp/alloy_apps.json', 'w') as out:
        json.dump(apps, out)

def oslistdir(path):
    try:
        return os.listdir(path)
    except:
        return []

if __name__ == '__main__':
    get_apps()

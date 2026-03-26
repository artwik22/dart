#!/bin/bash
# Start cava visualizer with real-time output

pkill -x cava 2>/dev/null
sleep 0.1

mkdir -p ~/.config/cava

cat > ~/.config/cava/config << 'EOF'
[general]
bars = 36
framerate = 60
sensitivity = 200

[input]
method = pulse

[output]
method = raw
raw_target = /dev/stdout
data_format = ascii
ascii_max_range = 100
EOF

rm -f /tmp/quickshell_cava

# Run cava in background with nohup, using the config file explicitly
nohup bash -c 'cava -p ~/.config/cava/config 2>/dev/null | while IFS= read -r line; do echo "$line" | tr " " ";" > /tmp/quickshell_cava; done' >/dev/null 2>&1 &

disown
exit 0

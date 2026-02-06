#!/bin/bash
# Fetch player metadata with custom delimiter to avoid newline issues

playerctl metadata --format '{{artist}}|###|{{title}}|###|{{album}}|###|{{mpris:artUrl}}|###|{{mpris:length}}|###|{{status}}' > /tmp/quickshell_player_info 2>/tmp/quickshell_player_err || echo > /tmp/quickshell_player_info

#!/bin/bash
# Simple script to get current system volume percentage
pactl get-sink-volume @DEFAULT_SINK@ | head -1 | awk '{print $5}' | tr -d '%'

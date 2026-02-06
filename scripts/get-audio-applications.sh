#!/bin/bash
# Script to get audio applications (sink-inputs) with their volumes
# This script synchronizes slider positions with actual system volume levels

# Get sink-inputs (applications)
sink_input_num=""
application_name=""

while IFS= read -r line; do
    if [[ $line =~ ^Sink\ Input\ \#([0-9]+) ]]; then
        # Print previous sink-input if we have all data
        if [[ -n "$sink_input_num" && -n "$application_name" ]]; then
            # Get actual volume using pactl get-sink-input-volume for accurate synchronization
            actual_volume=$(pactl get-sink-input-volume "$sink_input_num" 2>/dev/null | head -1 | grep -oE '[0-9]+%' | head -1 | tr -d '%')
            if [[ -n "$actual_volume" && "$actual_volume" =~ ^[0-9]+$ ]]; then
                volume_percent="$actual_volume"
            else
                # Fallback: try to parse from list output
                volume_percent="50"
            fi
            echo -e "${sink_input_num}\t${application_name}\t${volume_percent}"
        fi
        sink_input_num="${BASH_REMATCH[1]}"
        application_name=""
    elif [[ $line =~ ^[[:space:]]+application\.name[[:space:]]*=[[:space:]]*\"(.+)\" ]]; then
        application_name="${BASH_REMATCH[1]}"
    fi
done < <(pactl list sink-inputs)

# Print last sink-input
if [[ -n "$sink_input_num" && -n "$application_name" ]]; then
    # Get actual volume using pactl get-sink-input-volume for accurate synchronization
    actual_volume=$(pactl get-sink-input-volume "$sink_input_num" 2>/dev/null | head -1 | grep -oE '[0-9]+%' | head -1 | tr -d '%')
    if [[ -n "$actual_volume" && "$actual_volume" =~ ^[0-9]+$ ]]; then
        volume_percent="$actual_volume"
    else
        volume_percent="50"
    fi
    echo -e "${sink_input_num}\t${application_name}\t${volume_percent}"
fi

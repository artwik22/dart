#!/bin/bash
# Script to get audio devices with their real names

# Get sinks (output devices)
sink_num=""
name=""
description=""

while IFS= read -r line; do
    if [[ $line =~ ^Sink\ \#([0-9]+) ]]; then
        if [[ -n "$sink_num" && -n "$name" ]]; then
            echo -e "${sink_num}\t${name}\t${description}"
        fi
        sink_num="${BASH_REMATCH[1]}"
        name=""
        description=""
    elif [[ $line =~ ^[[:space:]]+Name:[[:space:]]+(.+) ]]; then
        name="${BASH_REMATCH[1]}"
    elif [[ $line =~ ^[[:space:]]+Description:[[:space:]]+(.+) ]]; then
        description="${BASH_REMATCH[1]}"
    fi
done < <(pactl list sinks)

# Print last sink
if [[ -n "$sink_num" && -n "$name" ]]; then
    echo -e "${sink_num}\t${name}\t${description}"
fi


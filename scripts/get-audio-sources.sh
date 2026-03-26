#!/bin/bash
# Script to get audio input devices with their real names

# Get sources (input devices)
source_num=""
name=""
description=""

while IFS= read -r line; do
    if [[ $line =~ ^Source\ \#([0-9]+) ]]; then
        if [[ -n "$source_num" && -n "$name" && ! $name =~ \.monitor$ ]]; then
            echo -e "${source_num}\t${name}\t${description}"
        fi
        source_num="${BASH_REMATCH[1]}"
        name=""
        description=""
    elif [[ $line =~ ^[[:space:]]+Name:[[:space:]]+(.+) ]]; then
        name="${BASH_REMATCH[1]}"
        if [[ $name =~ \.monitor$ ]]; then
            # Skip monitor sources
            source_num=""
            name=""
            description=""
        fi
    elif [[ $line =~ ^[[:space:]]+Description:[[:space:]]+(.+) ]]; then
        description="${BASH_REMATCH[1]}"
    fi
done < <(pactl list sources)

# Print last source
if [[ -n "$source_num" && -n "$name" && ! $name =~ \.monitor$ ]]; then
    echo -e "${source_num}\t${name}\t${description}"
fi


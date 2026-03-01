#!/bin/bash
# Generuje listę aplikacji .desktop jako TSV: name\ticon\texec
# Wynik zapisuje do /tmp/quickshell_launcher_apps

OUT="/tmp/quickshell_launcher_apps"
> "$OUT"

for dir in /usr/share/applications ~/.local/share/applications; do
    [ -d "$dir" ] || continue
    for f in "$dir"/*.desktop; do
        [ -f "$f" ] || continue
        name="" icon="" exec_cmd="" nodisp="" typ=""
        while IFS='=' read -r key val; do
            case "$key" in
                Name)      [ -z "$name" ] && name="$val" ;;
                Icon)      icon="$val" ;;
                Exec)      [ -z "$exec_cmd" ] && exec_cmd="$val" ;;
                NoDisplay) nodisp="$val" ;;
                Type)      typ="$val" ;;
            esac
        done < "$f"
        [ "$nodisp" = "true" ] && continue
        [ "$typ" != "Application" ] && [ -n "$typ" ] && continue
        [ -z "$name" ] || [ -z "$exec_cmd" ] && continue
        # Usuń %u %U %f %F itd.
        exec_cmd=$(echo "$exec_cmd" | sed 's/%[uUfFdDnNickvm]//g' | xargs)
        printf '%s\t%s\t%s\n' "$name" "$icon" "$exec_cmd"
    done
done | sort -t$'\t' -k1,1f > "$OUT"

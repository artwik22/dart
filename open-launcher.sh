#!/bin/bash
# Przełącza launcher (otwiera/zamyka) – shell.qml wywołuje openLauncher() (toggle).
# Ten sam skrót zamyka, gdy Wayland/layershell nie daje focusu (Escape by nie działał).
echo "openLauncher" > /tmp/quickshell_command


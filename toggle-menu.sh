#!/bin/bash
# =============================================================================
# Przełączenie menu (dashboardu) – shell.qml czyta /tmp/quickshell_command
# i wywołuje toggleMenu() → sharedData.menuVisible = !sharedData.menuVisible
# Użycie: bind w Hyprland lub wywołaj z terminala.
# =============================================================================
echo "toggleMenu" > /tmp/quickshell_command

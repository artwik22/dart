# Skrypty Dart

Skrypty używane przez shell.qml (polecenia, audio, kolory itd.).

## Polecenia do shella (`/tmp/quickshell_command`)

Te komendy są odpytywane przez Timer w shell.qml (co ~800 ms). Po obsłużeniu plik jest czyszczony.

| Komenda           | Skrypt / źródło         | Efekt |
|-------------------|--------------------------|--------|
| `toggleMenu`      | `../toggle-menu.sh`      | Przełącza menu (dashboard) – `sharedData.menuVisible` |
| `openLauncher`    | `../open-launcher.sh`    | Otwiera launcher aplikacji |
| `openClipboardManager` | `../open-clipboard.sh` | Otwiera menedżer schowka |
| `openSettings`    | (np. z Fuse)             | Otwiera ustawienia |

## Skrypty w `scripts/`

- **save-colors.py** – zapis `colors.json` (wywoływany z Fuse / GUI), zachowuje m.in. `sidebarVisible`, `sidebarPosition`, `uiScale`.
- **get-volume.sh**, **get-audio-devices.sh**, **get-audio-sources.sh**, **get-audio-applications.sh** – audio dla dashboardu.
- **start-cava.sh** – uruchamia cava (wizualizacja) w sidepanelu.
- **take-screenshot.sh**, **verify-password.sh**, **update-system.sh**, **install-package.sh**, **remove-package.sh**, **install-aur-package.sh**, **remove-aur-package.sh** – używane z poziomu dashboardu / Fuse.

## Uruchomienie

Z katalogu dart:

```bash
./run.sh
```

Przełączenie menu (np. z Hyprland):

```bash
./toggle-menu.sh
```

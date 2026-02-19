#!/usr/bin/env python3
import json
import sys
import os

# Load existing colors.json if it exists to preserve additional settings
existing_data = {}
if len(sys.argv) > 6 and os.path.exists(sys.argv[6]):
    try:
        with open(sys.argv[6], 'r') as f:
            existing_data = json.load(f)
    except:
        pass

colors = {
    "background": sys.argv[1],
    "primary": sys.argv[2],
    "secondary": sys.argv[3],
    "text": sys.argv[4],
    "accent": sys.argv[5]
}

# Preserve existing values if they exist in existing data
if "lastWallpaper" in existing_data:
    colors["lastWallpaper"] = existing_data["lastWallpaper"]
if "colorPreset" in existing_data:
    colors["colorPreset"] = existing_data["colorPreset"]
if "sidebarPosition" in existing_data:
    colors["sidebarPosition"] = existing_data["sidebarPosition"]
if "sidebarVisible" in existing_data:
    colors["sidebarVisible"] = existing_data["sidebarVisible"]
if "sidepanelContent" in existing_data:
    colors["sidepanelContent"] = existing_data["sidepanelContent"]
if "githubUsername" in existing_data:
    colors["githubUsername"] = existing_data["githubUsername"]
if "sidebarStyle" in existing_data:
    colors["sidebarStyle"] = existing_data["sidebarStyle"]

# Override with provided values if they exist
# Argument 7: lastWallpaper
if len(sys.argv) > 7 and sys.argv[7]:
    colors["lastWallpaper"] = sys.argv[7]

# Argument 8: colorPreset
if len(sys.argv) > 8 and sys.argv[8]:
    colors["colorPreset"] = sys.argv[8]

# Argument 9: sidebarPosition
if len(sys.argv) > 9 and sys.argv[9]:
    colors["sidebarPosition"] = sys.argv[9]

# Preserve notification settings
if "notificationsEnabled" in existing_data:
    colors["notificationsEnabled"] = existing_data["notificationsEnabled"]
if "notificationSoundsEnabled" in existing_data:
    colors["notificationSoundsEnabled"] = existing_data["notificationSoundsEnabled"]
if "rounding" in existing_data:
    colors["rounding"] = existing_data["rounding"]
if "showHiddenFiles" in existing_data:
    colors["showHiddenFiles"] = existing_data["showHiddenFiles"]
if "presets" in existing_data:
    colors["presets"] = existing_data["presets"]
if "uiScale" in existing_data:
    colors["uiScale"] = existing_data["uiScale"]
if "dashboardTileLeft" in existing_data:
    colors["dashboardTileLeft"] = existing_data["dashboardTileLeft"]
if "dashboardPosition" in existing_data:
    colors["dashboardPosition"] = existing_data["dashboardPosition"]
if "scriptsAutostartBattery" in existing_data:
    colors["scriptsAutostartBattery"] = existing_data["scriptsAutostartBattery"]
if "scriptsAutostartScreensaver" in existing_data:
    colors["scriptsAutostartScreensaver"] = existing_data["scriptsAutostartScreensaver"]
if "batteryThreshold" in existing_data:
    colors["batteryThreshold"] = existing_data["batteryThreshold"]
if "screensaverTimeout" in existing_data:
    colors["screensaverTimeout"] = existing_data["screensaverTimeout"]
if "scriptsAutostartAutofloat" in existing_data:
    colors["scriptsAutostartAutofloat"] = existing_data["scriptsAutostartAutofloat"]
if "autofloatWidth" in existing_data:
    colors["autofloatWidth"] = existing_data["autofloatWidth"]
if "autofloatHeight" in existing_data:
    colors["autofloatHeight"] = existing_data["autofloatHeight"]
if "scriptsUseLockscreen" in existing_data:
    colors["scriptsUseLockscreen"] = existing_data["scriptsUseLockscreen"]
if "notificationPosition" in existing_data:
    colors["notificationPosition"] = existing_data["notificationPosition"]
if "notificationRounding" in existing_data:
    colors["notificationRounding"] = existing_data["notificationRounding"]
if "quickshellBorderRadius" in existing_data:
    colors["quickshellBorderRadius"] = existing_data["quickshellBorderRadius"]
if "notificationSound" in existing_data:
    colors["notificationSound"] = existing_data["notificationSound"]
if "weatherLocation" in existing_data:
    colors["weatherLocation"] = existing_data["weatherLocation"]

# Override with provided values if they exist
# Argument 10: notificationsEnabled
if len(sys.argv) > 10 and sys.argv[10]:
    colors["notificationsEnabled"] = sys.argv[10] == "true"

# Argument 11: notificationSoundsEnabled
if len(sys.argv) > 11 and sys.argv[11]:
    colors["notificationSoundsEnabled"] = sys.argv[11] == "true"

# Argument 12: sidebarVisible
if len(sys.argv) > 12 and sys.argv[12]:
    colors["sidebarVisible"] = sys.argv[12] == "true"

# Argument 13: rounding
if len(sys.argv) > 13 and sys.argv[13]:
    colors["rounding"] = sys.argv[13]

# Argument 14: showHiddenFiles
if len(sys.argv) > 14 and sys.argv[14]:
    colors["showHiddenFiles"] = sys.argv[14] == "true"

# Argument 15: uiScale (75, 100, or 125)
if len(sys.argv) > 15 and sys.argv[15]:
    try:
        colors["uiScale"] = int(sys.argv[15])
    except ValueError:
        pass

# Argument 16: dashboardTileLeft ("battery" or "network")
if len(sys.argv) > 16 and sys.argv[16] and sys.argv[16] in ("battery", "network"):
    colors["dashboardTileLeft"] = sys.argv[16]

# Argument 17: sidepanelContent ("calendar" or "github")
if len(sys.argv) > 17 and sys.argv[17]:
    if sys.argv[17] in ("calendar", "github"):
        colors["sidepanelContent"] = sys.argv[17]

# Argument 18: githubUsername (string)
if len(sys.argv) > 18 and sys.argv[18]:
    colors["githubUsername"] = sys.argv[18]

# Argument 19: dashboardPosition ("right", "left", "top", "bottom")
if len(sys.argv) > 19 and sys.argv[19]:
    colors["dashboardPosition"] = sys.argv[19]

# Argument 20: scriptsAutostartBattery (true/false)
if len(sys.argv) > 20 and sys.argv[20]:
    colors["scriptsAutostartBattery"] = sys.argv[20] == "true"

# Argument 21: scriptsAutostartScreensaver (true/false)
if len(sys.argv) > 21 and sys.argv[21]:
    colors["scriptsAutostartScreensaver"] = sys.argv[21] == "true"

# Argument 22: batteryThreshold (int 0-100)
if len(sys.argv) > 22 and sys.argv[22]:
    try:
        colors["batteryThreshold"] = int(sys.argv[22])
    except ValueError:
        pass

# Argument 23: screensaverTimeout (int seconds)
if len(sys.argv) > 23 and sys.argv[23]:
    try:
        colors["screensaverTimeout"] = int(sys.argv[23])
    except ValueError:
        pass

# Argument 24: dashboardResource1 ("cpu", "ram", "gpu", "network")
if len(sys.argv) > 24 and sys.argv[24]:
    colors["dashboardResource1"] = sys.argv[24]

# Argument 25: dashboardResource2 ("cpu", "ram", "gpu", "network")
if len(sys.argv) > 25 and sys.argv[25]:
    colors["dashboardResource2"] = sys.argv[25]

# Argument 26: scriptsAutostartAutofloat (true/false)
if len(sys.argv) > 26 and sys.argv[26]:
    colors["scriptsAutostartAutofloat"] = sys.argv[26] == "true"

# Argument 27: autofloatWidth (int)
if len(sys.argv) > 27 and sys.argv[27]:
    try:
        colors["autofloatWidth"] = int(sys.argv[27])
    except ValueError:
        pass

# Argument 28: autofloatHeight (int)
if len(sys.argv) > 28 and sys.argv[28]:
    try:
        colors["autofloatHeight"] = int(sys.argv[28])
    except ValueError:
        pass

# Argument 29: scriptsUseLockscreen (true/false)
if len(sys.argv) > 29 and sys.argv[29]:
    colors["scriptsUseLockscreen"] = sys.argv[29] == "true"

# Argument 30: notificationPosition ("top", "top-left", "top-right")
if len(sys.argv) > 30 and sys.argv[30]:
    colors["notificationPosition"] = sys.argv[30]

# Argument 31: notificationRounding ("none", "standard", "pill")
if len(sys.argv) > 31 and sys.argv[31]:
    colors["notificationRounding"] = sys.argv[31]

# Argument 32: quickshellBorderRadius (0=disabled, 4=slight)
if len(sys.argv) > 32 and sys.argv[32]:
    try:
        colors["quickshellBorderRadius"] = int(sys.argv[32])
    except ValueError:
        pass

# Argument 33: notificationSound
if len(sys.argv) > 33 and sys.argv[33]:
    colors["notificationSound"] = sys.argv[33]

# Argument 34: weatherLocation
if len(sys.argv) > 34 and sys.argv[34]:
    colors["weatherLocation"] = sys.argv[34]

# Argument 35: floatingDashboard (true/false)
if len(sys.argv) > 35 and sys.argv[35]:
    colors["floatingDashboard"] = sys.argv[35] == "true"

# Argument 36: lockscreenMediaEnabled (true/false)
if len(sys.argv) > 36 and sys.argv[36]:
    colors["lockscreenMediaEnabled"] = sys.argv[36] == "true"

# Argument 37: lockscreenWeatherEnabled (true/false)
if len(sys.argv) > 37 and sys.argv[37]:
    colors["lockscreenWeatherEnabled"] = sys.argv[37] == "true"

# Argument 38: lockscreenBatteryEnabled (true/false)
if len(sys.argv) > 38 and sys.argv[38]:
    colors["lockscreenBatteryEnabled"] = sys.argv[38] == "true"



# Argument 39: lockscreenCalendarEnabled (true/false)
if len(sys.argv) > 39 and sys.argv[39]:
    colors["lockscreenCalendarEnabled"] = sys.argv[39] == "true"

# Argument 40: lockscreenNetworkEnabled (true/false)
if len(sys.argv) > 40 and sys.argv[40]:
    colors["lockscreenNetworkEnabled"] = sys.argv[40] == "true"

# Argument 41: sidebarStyle ("dots", "lines")
# sys.argv[41] corresponds to the 41st argument passed to the script.
if len(sys.argv) > 41 and sys.argv[41]:
    colors["sidebarStyle"] = sys.argv[41]

with open(sys.argv[6], 'w') as f:
    json.dump(colors, f, indent=2)

# Apply settings immediately
apply_script = os.path.join(os.path.expanduser("~"), ".config/alloy/scripts/apply-settings.sh")
if os.path.exists(apply_script):
    os.system(f'"{apply_script}" &')


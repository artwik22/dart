import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "."

PanelWindow {
    id: settingsApplicationRoot

    property var sharedData: null
    property var screen: null

    // Dynamic project path - from environment variable or auto-detected
    property string projectPath: "/home/artwik/.config/sharpshell" // Default fallback

    // Wallpaper properties
    property string wallpapersPath: ""  // Path to wallpapers directory

    function loadProjectPath() {
        // Try to read path from environment variable
        Qt.createQmlObject("import Quickshell.Io; import QtQuick; Process { command: ['sh', '-c', 'echo \"$QUICKSHELL_PROJECT_PATH\" > /tmp/quickshell_project_path 2>/dev/null || echo \"\" > /tmp/quickshell_project_path']; running: true }", settingsApplicationRoot)

        // Wait a moment and read the result
        Qt.createQmlObject("import QtQuick; Timer { interval: 100; running: true; repeat: false; onTriggered: settingsApplicationRoot.readProjectPath() }", settingsApplicationRoot)
    }

    function readProjectPath() {
        var xhr = new XMLHttpRequest()
        xhr.open("GET", "file:///tmp/quickshell_project_path")
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                var path = xhr.responseText.trim()
                if (path && path.length > 0) {
                    projectPath = path
                    console.log("Project path loaded from environment:", projectPath)
                } else {
                    // Try to detect from current script location
                    if (Qt.application && Qt.application.arguments && Qt.application.arguments.length > 0) {
                        Qt.createQmlObject("import Quickshell.Io; import QtQuick; Process { command: ['sh', '-c', 'dirname \"$(readlink -f \"$0\" 2>/dev/null || echo \"$0\")\" 2>/dev/null | head -1 > /tmp/quickshell_script_dir || echo \"\" > /tmp/quickshell_script_dir', '--', '" + Qt.application.arguments.join("' '") + "']; running: true }", settingsApplicationRoot)
                        Qt.createQmlObject("import QtQuick; Timer { interval: 200; running: true; repeat: false; onTriggered: settingsApplicationRoot.readScriptDir() }", settingsApplicationRoot)
                    } else {
                        // Last resort fallback
                        projectPath = "/tmp/sharpshell"
                        console.log("Using fallback project path (no Qt.application.arguments):", projectPath)
                    }
                }
            }
        }
        xhr.send()
    }

    function readScriptDir() {
        var xhr = new XMLHttpRequest()
        xhr.open("GET", "file:///tmp/quickshell_script_dir")
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                var dir = xhr.responseText.trim()
                if (dir && dir.length > 0) {
                    projectPath = dir
                    console.log("Project path auto-detected:", projectPath)
                } else {
                    // Last resort: use current working directory concept
                    projectPath = "/tmp/sharpshell"
                    console.log("Using fallback project path:", projectPath)
                }
            }
        }
        xhr.send()
    }


    function setWallpaper(wallpaperPath) {
        console.log("Setting wallpaper via Quickshell:", wallpaperPath)

        // Use Quickshell's built-in wallpaper system
        // Write the wallpaper path to a file that shell.qml monitors
        Qt.createQmlObject('import Quickshell.Io; Process { command: ["sh", "-c", "echo \'' + wallpaperPath.replace(/'/g, "'\\''") + '\' > /tmp/quickshell_wallpaper_path"]; running: true }', settingsApplicationRoot)
        console.log("Wallpaper path written to /tmp/quickshell_wallpaper_path:", wallpaperPath)

        // Save wallpaper path to config
        var sidebarPos = (sharedData && sharedData.sidebarPosition) ? sharedData.sidebarPosition : ""
        saveColors(wallpaperPath, "", sidebarPos)

        // Close wallpaper picker
        wallpaperPickerVisible = false
    }

    function loadAudioDevices() {
        // Load default sink
        Qt.createQmlObject('import Quickshell.Io; Process { command: ["sh", "-c", "pactl get-default-sink > /tmp/quickshell_default_sink 2>/dev/null"]; running: true }', settingsApplicationRoot)
        Qt.createQmlObject('import QtQuick; Timer { interval: 100; running: true; repeat: false; onTriggered: function() { var xhr = new XMLHttpRequest(); xhr.open("GET", "file:///tmp/quickshell_default_sink"); xhr.onreadystatechange = function() { if (xhr.readyState === XMLHttpRequest.DONE && (xhr.status === 200 || xhr.status === 0)) { defaultSink = xhr.responseText.trim(); loadDefaultSinkDescription(); loadDefaultSinkVolume(); } }; xhr.send(); } }', settingsApplicationRoot)

        // Load default source
        Qt.createQmlObject('import Quickshell.Io; Process { command: ["sh", "-c", "pactl get-default-source > /tmp/quickshell_default_source 2>/dev/null"]; running: true }', settingsApplicationRoot)
        Qt.createQmlObject('import QtQuick; Timer { interval: 100; running: true; repeat: false; onTriggered: function() { var xhr = new XMLHttpRequest(); xhr.open("GET", "file:///tmp/quickshell_default_source"); xhr.onreadystatechange = function() { if (xhr.readyState === XMLHttpRequest.DONE && (xhr.status === 200 || xhr.status === 0)) { defaultSource = xhr.responseText.trim(); loadDefaultSourceDescription(); loadDefaultSourceVolume(); } }; xhr.send(); } }', settingsApplicationRoot)

        // Load audio sinks (output devices) - use script to get device names
        audioSinksModel.clear()
        if (!projectPath || projectPath.length === 0) {
            console.log("Project path not initialized, cannot load audio devices")
            return
        }
        var scriptPath = projectPath + "/scripts/get-audio-devices.sh"
        var escapedPath = scriptPath.replace(/'/g, "'\\''")
        Qt.createQmlObject('import Quickshell.Io; Process { command: ["sh", "-c", "' + escapedPath + ' > /tmp/quickshell_audio_sinks 2>/dev/null"]; running: true }', settingsApplicationRoot)
        Qt.createQmlObject('import QtQuick; Timer { interval: 300; running: true; repeat: false; onTriggered: function() { var xhr = new XMLHttpRequest(); xhr.open("GET", "file:///tmp/quickshell_audio_sinks"); xhr.onreadystatechange = function() { if (xhr.readyState === XMLHttpRequest.DONE && (xhr.status === 200 || xhr.status === 0)) { var lines = xhr.responseText.split("\\n"); for (var i = 0; i < lines.length; i++) { var line = lines[i].trim(); if (line.length > 0) { var parts = line.split("\\t"); if (parts.length >= 3 && parts[2].length > 0) { audioSinksModel.append({ index: parts[0], name: parts[1], description: parts[2] }); } else if (parts.length >= 2) { audioSinksModel.append({ index: parts[0], name: parts[1], description: parts[1] }); } } } } }; xhr.send(); } }', settingsApplicationRoot)

        // Load audio sources (input devices) - use script to get device names
        audioSourcesModel.clear()
        var sourceScriptPath = projectPath + "/scripts/get-audio-sources.sh"
        var escapedSourcePath = sourceScriptPath.replace(/'/g, "'\\''")
        Qt.createQmlObject('import Quickshell.Io; Process { command: ["sh", "-c", "' + escapedSourcePath + ' > /tmp/quickshell_audio_sources 2>/dev/null"]; running: true }', settingsApplicationRoot)
        Qt.createQmlObject('import QtQuick; Timer { interval: 300; running: true; repeat: false; onTriggered: function() { var xhr = new XMLHttpRequest(); xhr.open("GET", "file:///tmp/quickshell_audio_sources"); xhr.onreadystatechange = function() { if (xhr.readyState === XMLHttpRequest.DONE && (xhr.status === 200 || xhr.status === 0)) { var lines = xhr.responseText.split("\\n"); for (var i = 0; i < lines.length; i++) { var line = lines[i].trim(); if (line.length > 0) { var parts = line.split("\\t"); if (parts.length >= 3 && parts[2].length > 0) { audioSourcesModel.append({ index: parts[0], name: parts[1], description: parts[2] }); } else if (parts.length >= 2) { audioSourcesModel.append({ index: parts[0], name: parts[1], description: parts[1] }); } } } } }; xhr.send(); } }', settingsApplicationRoot)
    }

    function loadDefaultSinkDescription() {
        if (!defaultSink || defaultSink.length === 0) return
        var escapedSink = defaultSink.replace(/'/g, "'\\''")
        var cmd = "pactl list sinks | grep -A 20 'Name: " + escapedSink + "' | grep 'Description:' | head -1 | sed 's/.*Description: //' > /tmp/quickshell_sink_description 2>/dev/null"
        Qt.createQmlObject('import Quickshell.Io; Process { command: ["sh", "-c", "' + cmd.replace(/"/g, '\\"') + '"]; running: true }', settingsApplicationRoot)
        Qt.createQmlObject('import QtQuick; Timer { interval: 100; running: true; repeat: false; onTriggered: function() { var xhr = new XMLHttpRequest(); xhr.open("GET", "file:///tmp/quickshell_sink_description"); xhr.onreadystatechange = function() { if (xhr.readyState === XMLHttpRequest.DONE && (xhr.status === 200 || xhr.status === 0)) { var desc = xhr.responseText.trim(); if (desc.length > 0) defaultSinkDescription = desc; } }; xhr.send(); } }', settingsApplicationRoot)
    }

    function loadDefaultSourceDescription() {
        if (!defaultSource || defaultSource.length === 0) return
        var escapedSource = defaultSource.replace(/'/g, "'\\''")
        var cmd = "pactl list sources | grep -A 20 'Name: " + escapedSource + "' | grep 'Description:' | head -1 | sed 's/.*Description: //' > /tmp/quickshell_source_description 2>/dev/null"
        Qt.createQmlObject('import Quickshell.Io; Process { command: ["sh", "-c", "' + cmd.replace(/"/g, '\\"') + '"]; running: true }', settingsApplicationRoot)
        Qt.createQmlObject('import QtQuick; Timer { interval: 100; running: true; repeat: false; onTriggered: function() { var xhr = new XMLHttpRequest(); xhr.open("GET", "file:///tmp/quickshell_source_description"); xhr.onreadystatechange = function() { if (xhr.readyState === XMLHttpRequest.DONE && (xhr.status === 200 || xhr.status === 0)) { var desc = xhr.responseText.trim(); if (desc.length > 0) defaultSourceDescription = desc; } }; xhr.send(); } }', settingsApplicationRoot)
    }

    function loadDefaultSinkVolume() {
        if (!defaultSink || defaultSink.length === 0) return
        var escapedSink = defaultSink.replace(/'/g, "'\\''")
        var cmd = "pactl get-sink-volume '" + escapedSink + "' | grep -oP '\\d+%' | head -1 | sed 's/%//' > /tmp/quickshell_sink_volume 2>/dev/null"
        Qt.createQmlObject('import Quickshell.Io; Process { command: ["sh", "-c", "' + cmd.replace(/"/g, '\\"') + '"]; running: true }', settingsApplicationRoot)
        Qt.createQmlObject('import QtQuick; Timer { interval: 100; running: true; repeat: false; onTriggered: function() { var xhr = new XMLHttpRequest(); xhr.open("GET", "file:///tmp/quickshell_sink_volume"); xhr.onreadystatechange = function() { if (xhr.readyState === XMLHttpRequest.DONE && (xhr.status === 200 || xhr.status === 0)) { var vol = parseInt(xhr.responseText.trim()); if (!isNaN(vol)) defaultSinkVolume = vol; } }; xhr.send(); } }', settingsApplicationRoot)
    }

    function loadDefaultSourceVolume() {
        if (!defaultSource || defaultSource.length === 0) return
        var escapedSource = defaultSource.replace(/'/g, "'\\''")
        var cmd = "pactl get-source-volume '" + escapedSource + "' | grep -oP '\\d+%' | head -1 | sed 's/%//' > /tmp/quickshell_source_volume 2>/dev/null"
        Qt.createQmlObject('import Quickshell.Io; Process { command: ["sh", "-c", "' + cmd.replace(/"/g, '\\"') + '"]; running: true }', settingsApplicationRoot)
        Qt.createQmlObject('import QtQuick; Timer { interval: 100; running: true; repeat: false; onTriggered: function() { var xhr = new XMLHttpRequest(); xhr.open("GET", "file:///tmp/quickshell_source_volume"); xhr.onreadystatechange = function() { if (xhr.readyState === XMLHttpRequest.DONE && (xhr.status === 200 || xhr.status === 0)) { var vol = parseInt(xhr.responseText.trim()); if (!isNaN(vol)) defaultSourceVolume = vol; } }; xhr.send(); } }', settingsApplicationRoot)
    }

    function setSinkVolume(sinkIndex, volumePercent) {
        // Set volume for a sink (0-100%)
        var volume = Math.round(volumePercent * 65536 / 100)
        Qt.createQmlObject('import Quickshell.Io; Process { command: ["pactl", "set-sink-volume", "' + sinkIndex + '", "' + volume + '"]; running: true }', settingsApplicationRoot)
    }

    function setSourceVolume(sourceIndex, volumePercent) {
        // Set volume for a source (0-100%)
        var volume = Math.round(volumePercent * 65536 / 100)
        Qt.createQmlObject('import Quickshell.Io; Process { command: ["pactl", "set-source-volume", "' + sourceIndex + '", "' + volume + '"]; running: true }', settingsApplicationRoot)
    }

    function setSinkMute(sinkIndex, mute) {
        // Mute/unmute a sink
        var muteArg = mute ? "1" : "0"
        Qt.createQmlObject('import Quickshell.Io; Process { command: ["pactl", "set-sink-mute", "' + sinkIndex + '", "' + muteArg + '"]; running: true }', settingsApplicationRoot)
    }

    function setSourceMute(sourceIndex, mute) {
        // Mute/unmute a source
        var muteArg = mute ? "1" : "0"
        Qt.createQmlObject('import Quickshell.Io; Process { command: ["pactl", "set-source-mute", "' + sourceIndex + '", "' + muteArg + '"]; running: true }', settingsApplicationRoot)
    }

    function setDefaultSink(sinkName) {
        // Set default sink
        Qt.createQmlObject('import Quickshell.Io; Process { command: ["pactl", "set-default-sink", "' + sinkName + '"]; running: true }', settingsApplicationRoot)
        defaultSink = sinkName
    }

    function setDefaultSource(sourceName) {
        // Set default source
        Qt.createQmlObject('import Quickshell.Io; Process { command: ["pactl", "set-default-source", "' + sourceName + '"]; running: true }', settingsApplicationRoot)
        defaultSource = sourceName
    }

    function setDefaultSinkVolume(volumePercent) {
        // Set volume for default sink (0-100%)
        var volume = Math.round(volumePercent * 65536 / 100)
        Qt.createQmlObject('import Quickshell.Io; Process { command: ["pactl", "set-sink-volume", "@DEFAULT_SINK@", "' + volume + '"]; running: true }', settingsApplicationRoot)
        defaultSinkVolume = volumePercent
    }

    function setDefaultSourceVolume(volumePercent) {
        // Set volume for default source (0-100%)
        var volume = Math.round(volumePercent * 65536 / 100)
        Qt.createQmlObject('import Quickshell.Io; Process { command: ["pactl", "set-source-volume", "@DEFAULT_SOURCE@", "' + volume + '"]; running: true }', settingsApplicationRoot)
        defaultSourceVolume = volumePercent
    }

    function setDefaultSinkMute(mute) {
        // Mute/unmute default sink
        var muteArg = mute ? "1" : "0"
        Qt.createQmlObject('import Quickshell.Io; Process { command: ["pactl", "set-sink-mute", "@DEFAULT_SINK@", "' + muteArg + '"]; running: true }', settingsApplicationRoot)
        defaultSinkMute = mute
    }

    function setDefaultSourceMute(mute) {
        // Mute/unmute default source
        var muteArg = mute ? "1" : "0"
        Qt.createQmlObject('import Quickshell.Io; Process { command: ["pactl", "set-source-mute", "@DEFAULT_SOURCE@", "' + muteArg + '"]; running: true }', settingsApplicationRoot)
        defaultSourceMute = mute
    }

    function getSinkInfo(sinkIndex, callback) {
        // Get detailed info about a sink
        var process = Qt.createQmlObject('import Quickshell.Io; import QtQuick; Process { id: proc; command: ["pactl", "list", "sinks"]; running: true; onFinished: function() { var output = proc.readAllStandardOutput().toString(); callback(output); } }', settingsApplicationRoot)
    }

    function getSourceInfo(sourceIndex, callback) {
        // Get detailed info about a source
        var process = Qt.createQmlObject('import Quickshell.Io; import QtQuick; Process { id: proc; command: ["pactl", "list", "sources"]; running: true; onFinished: function() { var output = proc.readAllStandardOutput().toString(); callback(output); } }', settingsApplicationRoot)
    }

    function saveColors(wallpaperPath, presetName, sidebarPos) {
        // Validate paths before saving
        if (!projectPath || projectPath.length === 0) {
            console.log("Project path not initialized, cannot save colors")
            return
        }
        if (!colorConfigPath || colorConfigPath.length === 0) {
            console.log("Color config path not initialized, cannot save colors")
            return
        }
        // Use Python script to save colors - pass colors and optional values as arguments
        var scriptPath = projectPath + "/scripts/save-colors.py"
        var cmd = 'python3 "' + scriptPath + '" "' + colorBackground + '" "' + colorPrimary + '" "' + colorSecondary + '" "' + colorText + '" "' + colorAccent + '" "' + colorConfigPath + '"'
        
        // Add optional arguments
        if (wallpaperPath) {
            cmd += ' "' + wallpaperPath.replace(/"/g, '\\"') + '"'
        } else {
            cmd += ' ""'
        }
        
        if (presetName) {
            cmd += ' "' + presetName.replace(/"/g, '\\"') + '"'
        } else {
            cmd += ' ""'
        }
        
        if (sidebarPos) {
            cmd += ' "' + sidebarPos.replace(/"/g, '\\"') + '"'
        } else {
            cmd += ' ""'
        }
        
        Qt.createQmlObject("import Quickshell.Io; Process { command: ['sh', '-c', '" + cmd.replace(/'/g, "\\'") + "']; running: true }", settingsApplicationRoot)
        console.log("Saving colors to:", colorConfigPath, "wallpaper:", wallpaperPath || "none", "preset:", presetName || "none", "sidebar:", sidebarPos || "none")
    }

    function saveNotificationSettings() {
        if (!projectPath || projectPath.length === 0 || !colorConfigPath || colorConfigPath.length === 0) {
            console.log("Paths not initialized, cannot save notification settings")
            return
        }
        // Save notification settings to colors.json - preserve all existing values
        var scriptPath = projectPath + "/scripts/save-colors.py"
        var sidebarPos = (sharedData && sharedData.sidebarPosition) ? sharedData.sidebarPosition : ""
        var cmd = 'python3 "' + scriptPath + '" "' + colorBackground + '" "' + colorPrimary + '" "' + colorSecondary + '" "' + colorText + '" "' + colorAccent + '" "' + colorConfigPath + '" "" "" "' + sidebarPos + '"'
        if (sharedData) {
            cmd += ' "' + (sharedData.notificationsEnabled ? "true" : "false") + '"'
            cmd += ' "' + (sharedData.notificationSoundsEnabled ? "true" : "false") + '"'
        } else {
            cmd += ' "" ""'
        }
        Qt.createQmlObject("import Quickshell.Io; Process { command: ['sh', '-c', '" + cmd.replace(/'/g, "\\'") + "']; running: true }", settingsApplicationRoot)
        console.log("Saving notification settings")
    }

    function applyColorPreset(presetName) {
        var preset = colorPresets[presetName]
        if (!preset) {
            console.log("Preset not found:", presetName)
            return
        }

        console.log("Applying color preset:", presetName, "with colors:", JSON.stringify(preset))

        // Update all colors at once
        colorBackground = preset.background
        colorPrimary = preset.primary
        colorSecondary = preset.secondary
        colorText = preset.text
        colorAccent = preset.accent

        // Force UI update
        colorPickerVisible = false
        Qt.callLater(function() { colorPickerVisible = true })

        // Update custom variables to match
        customBackground = preset.background
        customPrimary = preset.primary
        customSecondary = preset.secondary
        customText = preset.text
        customAccent = preset.accent

        // Update sharedData
        if (sharedData) {
            sharedData.colorBackground = preset.background
            sharedData.colorPrimary = preset.primary
            sharedData.colorSecondary = preset.secondary
            sharedData.colorText = preset.text
            sharedData.colorAccent = preset.accent
        }

        // Save to file with preset name
        var sidebarPos = (sharedData && sharedData.sidebarPosition) ? sharedData.sidebarPosition : ""
        saveColors("", presetName, sidebarPos)

        console.log("Applied preset:", presetName, "- colors saved")
    }

    function applyCustomColors() {
        if (customBackground) colorBackground = customBackground
        if (customPrimary) colorPrimary = customPrimary
        if (customSecondary) colorSecondary = customSecondary
        if (customText) colorText = customText
        if (customAccent) colorAccent = customAccent

        // Update sharedData if available
        if (sharedData) {
            if (customBackground) sharedData.colorBackground = customBackground
            if (customPrimary) sharedData.colorPrimary = customPrimary
            if (customSecondary) sharedData.colorSecondary = customSecondary
            if (customText) sharedData.colorText = customText
            if (customAccent) sharedData.colorAccent = customAccent
        }

        // Save to file (custom colors don't have preset name)
        var sidebarPos = (sharedData && sharedData.sidebarPosition) ? sharedData.sidebarPosition : ""
        saveColors("", "", sidebarPos)
    }

    // Window properties
    implicitWidth: 800
    implicitHeight: 600
    color: "transparent"

    // Color properties
    property color colorBackground: "#0a0a0a"
    property color colorPrimary: "#252525"
    property color colorSecondary: "#1a1a1a"
    property color colorText: "#ffffff"
    property color colorAccent: "#4a9eff"
    
    // Global radius property
    property int globalRadius: (sharedData && sharedData.globalRadius !== undefined) ? sharedData.globalRadius : 0

    // Settings state
    property int selectedIndex: 0
    property int currentTab: 0  // 0 = General, 1 = Color Presets, 2 = Wallpapers, 3 = Bar, 4 = System, 5 = Audio
    property bool wallpaperPickerVisible: false  // Show wallpaper picker in Appearance tab
    property bool colorPickerVisible: false  // Show color picker in Appearance tab
    property int wallpaperSelectedIndex: 0  // Selected wallpaper index
    
    // Default audio devices
    property string defaultSink: ""
    property string defaultSource: ""
    property string defaultSinkDescription: ""
    property string defaultSourceDescription: ""
    property real defaultSinkVolume: 50
    property real defaultSourceVolume: 50
    property bool defaultSinkMute: false
    property bool defaultSourceMute: false


    // Color properties
    property string colorConfigPath: ""

    // Bluetooth properties
    property bool bluetoothPowered: false
    property bool bluetoothConnecting: false
    property int bluetoothSelectedIndex: 0
    property bool bluetoothScanning: false

    // Color picker properties
    property string customBackground: colorBackground
    property string customPrimary: colorPrimary
    property string customSecondary: colorSecondary
    property string customText: colorText
    property string customAccent: colorAccent

    // Color presets
    property var colorPresets: {
        "Dark": {
            background: "#0a0a0a",
            primary: "#252525",
            secondary: "#1a1a1a",
            text: "#ffffff",
            accent: "#6bb6ff"
        },
        "Ocean": {
            background: "#0a1628",
            primary: "#1e3a52",
            secondary: "#152535",
            text: "#ffffff",
            accent: "#4fc3f7"
        },
        "Forest": {
            background: "#0d1a0d",
            primary: "#1e3a1e",
            secondary: "#152515",
            text: "#ffffff",
            accent: "#66bb6a"
        },
        "Violet": {
            background: "#1a0d26",
            primary: "#2e1f3f",
            secondary: "#231a35",
            text: "#ffffff",
            accent: "#ab47bc"
        },
        "Crimson": {
            background: "#1a0a0a",
            primary: "#2e1a1a",
            secondary: "#231515",
            text: "#ffffff",
            accent: "#ef5350"
        },
        "Amber": {
            background: "#1a150d",
            primary: "#2e251a",
            secondary: "#231f15",
            text: "#ffffff",
            accent: "#ffb74d"
        },
        "Teal": {
            background: "#0d1a1a",
            primary: "#1e2e2e",
            secondary: "#152525",
            text: "#ffffff",
            accent: "#26a69a"
        },
        "Rose": {
            background: "#1a0d15",
            primary: "#2e1a23",
            secondary: "#23151f",
            text: "#ffffff",
            accent: "#f06292"
        },
        "Sunset": {
            background: "#1a150d",
            primary: "#2e251a",
            secondary: "#231f15",
            text: "#ffffff",
            accent: "#ff9800"
        },
        "Midnight": {
            background: "#0a0d1a",
            primary: "#1e1f2d",
            secondary: "#151a23",
            text: "#ffffff",
            accent: "#78909c"
        },
        "Emerald": {
            background: "#0d1a0d",
            primary: "#1e3a1e",
            secondary: "#152515",
            text: "#ffffff",
            accent: "#4caf50"
        },
        "Lavender": {
            background: "#1a0d1a",
            primary: "#2e1a2d",
            secondary: "#231523",
            text: "#ffffff",
            accent: "#ba68c8"
        },
        "Sapphire": {
            background: "#0d0d1a",
            primary: "#1e1f2d",
            secondary: "#151a23",
            text: "#ffffff",
            accent: "#42a5f5"
        },
        "Coral": {
            background: "#1a0d0d",
            primary: "#2e1a1a",
            secondary: "#231515",
            text: "#ffffff",
            accent: "#ff7043"
        },
        "Mint": {
            background: "#0d1a15",
            primary: "#1e3a23",
            secondary: "#15251f",
            text: "#ffffff",
            accent: "#4db6ac"
        },
        "Plum": {
            background: "#1a0d1a",
            primary: "#2e1a2d",
            secondary: "#231523",
            text: "#ffffff",
            accent: "#ba68c8"
        },
        "Gold": {
            background: "#1a160d",
            primary: "#2e281a",
            secondary: "#231f15",
            text: "#ffffff",
            accent: "#ffca28"
        },
        "Monochrome": {
            background: "#0a0a0a",
            primary: "#1a1a1a",
            secondary: "#121212",
            text: "#ffffff",
            accent: "#9e9e9e"
        },
        "Cherry": {
            background: "#1a0a0a",
            primary: "#2e1a1a",
            secondary: "#231515",
            text: "#ffffff",
            accent: "#e57373"
        },
        "Azure": {
            background: "#0a151a",
            primary: "#1a2e3a",
            secondary: "#152325",
            text: "#ffffff",
            accent: "#2196f3"
        },
        "Jade": {
            background: "#0d1a0d",
            primary: "#1e3a1e",
            secondary: "#152515",
            text: "#ffffff",
            accent: "#66bb6a"
        },
        "Ruby": {
            background: "#1a0a0a",
            primary: "#2e1a1a",
            secondary: "#231515",
            text: "#ffffff",
            accent: "#f44336"
        },
        "Indigo": {
            background: "#0d0a1a",
            primary: "#1a162e",
            secondary: "#151223",
            text: "#ffffff",
            accent: "#3f51b5"
        }
    }

    // Functions
    function initializePaths() {
        // Get home directory and project path
        Qt.createQmlObject("import Quickshell.Io; import QtQuick; Process { command: ['sh', '-c', 'echo \"$HOME\" > /tmp/quickshell_home_dir; echo \"$QUICKSHELL_PROJECT_PATH\" > /tmp/quickshell_project_path 2>/dev/null || echo \"\" > /tmp/quickshell_project_path']; running: true }", settingsApplicationRoot)

        // Wait a moment and read the results
        Qt.createQmlObject("import QtQuick; Timer { interval: 150; running: true; repeat: false; onTriggered: settingsApplicationRoot.readAllPaths() }", settingsApplicationRoot)
    }

    function readAllPaths() {
        // 1. Read Home Dir
        var homeXhr = new XMLHttpRequest()
        homeXhr.open("GET", "file:///tmp/quickshell_home_dir")
        homeXhr.onreadystatechange = function() {
            if (homeXhr.readyState === XMLHttpRequest.DONE) {
                var home = homeXhr.responseText.trim()
                if (home && home.length > 0) {
                    var username = home.split("/").pop()
                    setUserPaths(username)
                } else {
                    setUserPaths("artwik") // Fallback
                }
                
                // Now that paths are initialized, load wallpapers and settings
                loadWallpapers()
                loadSavedSettings()
            }
        }
        homeXhr.send()

        // 2. Read Project Path (already handled by existing logic, but combined here)
        readProjectPath()
    }

    function setUserPaths(username) {
        console.log("Setting paths for user:", username)
        wallpapersPath = "/home/" + username + "/Pictures/Wallpapers"
        colorConfigPath = projectPath + "/colors.json"
        console.log("Wallpapers path set to:", wallpapersPath)

        // Create necessary directories
        Qt.createQmlObject("import Quickshell.Io; Process { command: ['mkdir', '-p', '" + wallpapersPath + "']; running: true }", settingsApplicationRoot)
        Qt.createQmlObject("import Quickshell.Io; Process { command: ['mkdir', '-p', '/home/" + username + "/Documents/Notes']; running: true }", settingsApplicationRoot)
    }


    // List of wallpapers
    ListModel {
        id: wallpapersModel
    }

    // Process to find wallpapers
    Process {
        id: wallpaperFinderProcess
        onExited: function(exitCode, exitStatus) {
            console.log("Wallpaper finder process exited with code:", exitCode, "status:", exitStatus)
            readWallpapersList()
        }
    }

    function loadWallpapers() {
        console.log("Loading wallpapers from path:", wallpapersPath)
        if (!wallpapersPath || wallpapersPath.length === 0) {
            console.log("Wallpapers path not initialized, waiting...")
            // Retry after a short delay
            Qt.createQmlObject("import QtQuick; Timer { interval: 500; running: true; repeat: false; onTriggered: settingsApplicationRoot.loadWallpapers() }", settingsApplicationRoot)
            return
        }

        // Use a simpler find command and write to a specific file
        // Search in subdirectories as well (maxdepth 2)
        var findCmd = "find -L '" + wallpapersPath + "' -maxdepth 2 -type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.gif' \\) 2>/dev/null | sort"
        console.log("Find command:", findCmd)

        // Ensure process is stopped before starting again
        wallpaperFinderProcess.running = false
        wallpaperFinderProcess.command = ["sh", "-c", findCmd + " > /tmp/quickshell_wallpapers"]
        wallpaperFinderProcess.running = true
    }

    function readWallpapersList() {
        var xhr = new XMLHttpRequest()
        xhr.open("GET", "file:///tmp/quickshell_wallpapers")
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200 || xhr.status === 0) {
                    var content = xhr.responseText || ""
                    console.log("Wallpaper list received, length:", content.length)
                    var lines = content.trim().split("\n")
                    
                    wallpapersModel.clear()
                    
                    var addedCount = 0
                    for (var i = 0; i < lines.length; i++) {
                        var path = lines[i].trim()
                        if (path.length > 0) {
                            var filename = path.split("/").pop()
                            wallpapersModel.append({ path: path, filename: filename })
                            addedCount++
                        }
                    }
                    console.log("Successfully loaded", addedCount, "wallpapers")
                } else {
                    console.log("Failed to read wallpaper list file, status:", xhr.status)
                    // If file not found, might still be writing or find found nothing
                    if (wallpapersModel.count === 0) {
                        console.log("No wallpapers found or file not ready")
                    }
                }
            }
        }
        xhr.send()
    }

    function loadSavedSettings() {
        if (!colorConfigPath || colorConfigPath.length === 0) {
            console.log("Color config path not initialized, cannot load saved settings")
            return
        }
        var xhr = new XMLHttpRequest()
        xhr.open("GET", "file://" + colorConfigPath)
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200 || xhr.status === 0) {
                    try {
                        var json = JSON.parse(xhr.responseText)
                        
                        // Load sidebar position if available
                        if (json.sidebarPosition && sharedData && (json.sidebarPosition === "left" || json.sidebarPosition === "top")) {
                            sharedData.sidebarPosition = json.sidebarPosition
                            console.log("Loaded sidebar position from config:", json.sidebarPosition)
                        }
                        
                        // Load color preset if available (for reference)
                        if (json.colorPreset && json.colorPreset.length > 0) {
                            console.log("Loaded color preset from config:", json.colorPreset)
                        }
                        
                        // Load last wallpaper if available (already handled by shell.qml, but log for reference)
                        if (json.lastWallpaper && json.lastWallpaper.length > 0) {
                            console.log("Last wallpaper from config:", json.lastWallpaper)
                        }
                        
                        // Load notification settings if available
                        if (json.notificationsEnabled !== undefined && sharedData) {
                            sharedData.notificationsEnabled = json.notificationsEnabled === true || json.notificationsEnabled === "true"
                            console.log("Loaded notificationsEnabled from config:", sharedData.notificationsEnabled)
                        }
                        if (json.notificationSoundsEnabled !== undefined && sharedData) {
                            sharedData.notificationSoundsEnabled = json.notificationSoundsEnabled === true || json.notificationSoundsEnabled === "true"
                            console.log("Loaded notificationSoundsEnabled from config:", sharedData.notificationSoundsEnabled)
                        }
                    } catch (e) {
                        console.log("Error parsing colors.json:", e)
                    }
                }
            }
        }
        xhr.send()
    }

    Component.onCompleted: {
        loadProjectPath()
        // Wait for project path to be loaded, then initialize other paths
        // readAllPaths will trigger loadWallpapers and loadSavedSettings after paths are ready
        Qt.createQmlObject("import QtQuick; Timer { interval: 300; running: true; repeat: false; onTriggered: function() { initializePaths(); } }", settingsApplicationRoot)
        if (sharedData) {
            // Load colors from sharedData if available
            colorBackground = sharedData.colorBackground || colorBackground
            colorPrimary = sharedData.colorPrimary || colorPrimary
            colorSecondary = sharedData.colorSecondary || colorSecondary
            colorText = sharedData.colorText || colorText
            colorAccent = sharedData.colorAccent || colorAccent
        }
    }

    // Synchronize colors from sharedData to local properties
    Connections {
        target: sharedData
        enabled: sharedData !== null

        function onColorBackgroundChanged() {
            if (sharedData && sharedData.colorBackground && sharedData.colorBackground !== colorBackground) {
                colorBackground = sharedData.colorBackground
            }
        }

        function onColorPrimaryChanged() {
            if (sharedData && sharedData.colorPrimary && sharedData.colorPrimary !== colorPrimary) {
                colorPrimary = sharedData.colorPrimary
            }
        }

        function onColorSecondaryChanged() {
            if (sharedData && sharedData.colorSecondary && sharedData.colorSecondary !== colorSecondary) {
                colorSecondary = sharedData.colorSecondary
            }
        }

        function onColorTextChanged() {
            if (sharedData && sharedData.colorText && sharedData.colorText !== colorText) {
                colorText = sharedData.colorText
            }
        }

        function onColorAccentChanged() {
            if (sharedData && sharedData.colorAccent && sharedData.colorAccent !== colorAccent) {
                colorAccent = sharedData.colorAccent
            }
        }
    }

    // Bluetooth devices model
    ListModel {
        id: bluetoothDevicesModel
    }

    // Audio devices models
    ListModel {
        id: audioInputDevicesModel
    }

    ListModel {
        id: audioOutputDevicesModel
    }

    // Audio sinks/sources (for PulseAudio)
    ListModel {
        id: audioSinksModel
    }

    ListModel {
        id: audioSourcesModel
    }

    // Shadow helper component for elevation
    function getShadowProps(level) {
        switch(level) {
            case 0: return { blur: 0, offset: 0, opacity: 0 }
            case 1: return { blur: 4, offset: 0, opacity: 0.1 }
            case 2: return { blur: 8, offset: 2, opacity: 0.15 }
            case 3: return { blur: 16, offset: 4, opacity: 0.2 }
            case 4: return { blur: 24, offset: 8, opacity: 0.25 }
            default: return { blur: 8, offset: 2, opacity: 0.15 }
        }
    }
    
    function darkenColor(baseColor, factor) {
        var c = Qt.color(baseColor)
        return Qt.rgba(c.r * factor, c.g * factor, c.b * factor, c.a)
    }
    
    function lightenColor(baseColor, factor) {
        var c = Qt.color(baseColor)
        return Qt.rgba(Math.min(1, c.r * factor), Math.min(1, c.g * factor), Math.min(1, c.b * factor), c.a)
    }
    
    property var shadowProps: getShadowProps(3)  // Modal elevation
    
    // Main container
    Rectangle {
        id: settingsContainer
        anchors.fill: parent
        anchors.margins: 8
        color: colorBackground
        radius: globalRadius
        opacity: (sharedData && sharedData.settingsVisible) ? 1.0 : 0.0
        scale: (sharedData && sharedData.settingsVisible) ? 1.0 : 0.95
        enabled: opacity > 0.1
        
        // Shadow effect using layered rectangles
        Rectangle {
            anchors.fill: parent
            anchors.margins: -shadowProps.offset
            color: Qt.rgba(0, 0, 0, shadowProps.opacity)
            radius: parent.radius + shadowProps.offset
            z: -1
        }
        
        Behavior on opacity {
            NumberAnimation {
                duration: 300
                easing.type: Easing.OutCubic
            }
        }
        
        Behavior on scale {
            SpringAnimation {
                spring: 3
                damping: 0.3
                epsilon: 0.01
            }
        }

        // Header
        Rectangle {
            id: settingsHeader
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 56
            color: colorPrimary
            radius: globalRadius
            
            // Subtle shadow for header
            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                height: 1
                color: Qt.rgba(0, 0, 0, 0.1)
            }

            Row {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                spacing: 16

                Text {
                    id: titleText
                    text: currentTab === 0 ? "General" :
                          currentTab === 1 ? "Color Presets" :
                          currentTab === 2 ? "Wallpapers" :
                          currentTab === 3 ? "Bar" :
                          currentTab === 4 ? "System" :
                          currentTab === 5 ? "Audio" : "Settings"
                    font.pixelSize: 18
                    font.family: "sans-serif"
                    font.weight: Font.Bold
                    color: colorText
                    anchors.verticalCenter: parent.verticalCenter
                }

                // Spacer
                Item {
                    width: parent.width - closeButton.width - titleText.width - 40
                    height: 1
                }

                // Close button
                Rectangle {
                    id: closeButton
                    width: 32
                    height: 32
                    color: closeMouseArea.pressed ? darkenColor(colorSecondary, 0.8) : (closeMouseArea.containsMouse ? colorSecondary : "transparent")
                    radius: globalRadius
                    anchors.verticalCenter: parent.verticalCenter
                    scale: closeMouseArea.pressed ? 0.95 : (closeMouseArea.containsMouse ? 1.05 : 1.0)
                    
                    // Subtle shadow on hover
                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: -1
                        color: Qt.rgba(0, 0, 0, closeMouseArea.containsMouse ? 0.1 : 0)
                        radius: parent.radius + 1
                        z: -1
                    }
                    
                    Behavior on color {
                        ColorAnimation {
                            duration: 200
                            easing.type: Easing.OutCubic
                        }
                    }
                    
                    Behavior on scale {
                        SpringAnimation {
                            spring: 4
                            damping: 0.4
                            epsilon: 0.01
                        }
                    }

                    Text {
                        text: "󰅖"
                        font.pixelSize: 16
                        color: colorText
                        anchors.centerIn: parent
                    }

                    MouseArea {
                        id: closeMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (sharedData) {
                                sharedData.settingsVisible = false
                            }
                        }
                    }
                }
            }
        }

        // Sidebar with tabs
        Rectangle {
            id: sidebar
            anchors.top: settingsHeader.bottom
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            width: 200
            color: colorSecondary
            radius: globalRadius
            
            // Subtle shadow for sidebar
            Rectangle {
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: 1
                color: Qt.rgba(0, 0, 0, 0.1)
            }

            Column {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: versionText.top
                anchors.margins: 8
                spacing: 4

                // General tab
                Rectangle {
                    width: parent.width
                    height: 48
                    color: generalMouseArea.pressed ? darkenColor(colorSecondary, 0.9) : (generalMouseArea.containsMouse ? lightenColor(colorSecondary, 1.05) : "transparent")
                    radius: globalRadius
                    opacity: currentTab === 0 ? 1.0 : 0.7
                    scale: generalMouseArea.pressed ? 0.98 : (generalMouseArea.containsMouse ? 1.02 : 1.0)
                    
                    Behavior on color {
                        ColorAnimation {
                            duration: 200
                            easing.type: Easing.OutCubic
                        }
                    }
                    
                    Behavior on scale {
                        SpringAnimation {
                            spring: 4
                            damping: 0.4
                            epsilon: 0.01
                        }
                    }

                    // Bottom accent line for selected tab with gradient
                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: currentTab === 0 ? parent.width * 0.8 : 0
                        height: 3
                        radius: 1.5
                        
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: colorAccent }
                            GradientStop { position: 1.0; color: lightenColor(colorAccent, 1.1) }
                        }

                        Behavior on width {
                            NumberAnimation {
                                duration: 300
                                easing.type: Easing.OutCubic
                            }
                        }
                    }

                    Row {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 12

                        Text {
                            text: "󰒓"
                            font.pixelSize: 16
                            color: colorText
                            opacity: currentTab === 0 ? 1.0 : 0.8
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: "General"
                            font.pixelSize: 14
                            font.family: "sans-serif"
                            font.weight: currentTab === 0 ? Font.Bold : Font.Medium
                            color: colorText
                            opacity: currentTab === 0 ? 1.0 : 0.8
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        id: generalMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            currentTab = 0
                        }
                    }
                }

                // Appearance tab
                Rectangle {
                    width: parent.width
                    height: 48
                    color: appearanceMouseArea.pressed ? darkenColor(colorSecondary, 0.9) : (appearanceMouseArea.containsMouse ? lightenColor(colorSecondary, 1.05) : "transparent")
                    radius: globalRadius
                    opacity: currentTab === 1 ? 1.0 : 0.7
                    scale: appearanceMouseArea.pressed ? 0.98 : (appearanceMouseArea.containsMouse ? 1.02 : 1.0)
                    
                    Behavior on color {
                        ColorAnimation {
                            duration: 200
                            easing.type: Easing.OutCubic
                        }
                    }
                    
                    Behavior on scale {
                        SpringAnimation {
                            spring: 4
                            damping: 0.4
                            epsilon: 0.01
                        }
                    }

                    // Bottom accent line for selected tab with gradient
                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: currentTab === 1 ? parent.width * 0.8 : 0
                        height: 3
                        radius: 1.5
                        
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: colorAccent }
                            GradientStop { position: 1.0; color: lightenColor(colorAccent, 1.1) }
                        }

                        Behavior on width {
                            NumberAnimation {
                                duration: 300
                                easing.type: Easing.OutCubic
                            }
                        }
                    }

                    Row {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 12

                        Text {
                            text: "󰏘"
                            font.pixelSize: 16
                            color: colorText
                            opacity: currentTab === 1 ? 1.0 : 0.8
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: "Color Presets"
                            font.pixelSize: 14
                            font.family: "sans-serif"
                            font.weight: currentTab === 1 ? Font.Bold : Font.Medium
                            color: colorText
                            opacity: currentTab === 1 ? 1.0 : 0.8
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        id: appearanceMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            currentTab = 1
                        }
                    }
                }

                // Wallpapers tab
                Rectangle {
                    width: parent.width
                    height: 48
                    color: wallpapersMouseArea.pressed ? darkenColor(colorSecondary, 0.9) : (wallpapersMouseArea.containsMouse ? lightenColor(colorSecondary, 1.05) : "transparent")
                    radius: globalRadius
                    opacity: currentTab === 2 ? 1.0 : 0.7
                    scale: wallpapersMouseArea.pressed ? 0.98 : (wallpapersMouseArea.containsMouse ? 1.02 : 1.0)
                    
                    Behavior on color {
                        ColorAnimation {
                            duration: 200
                            easing.type: Easing.OutCubic
                        }
                    }
                    
                    Behavior on scale {
                        SpringAnimation {
                            spring: 4
                            damping: 0.4
                            epsilon: 0.01
                        }
                    }

                    // Bottom accent line for selected tab with gradient
                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: currentTab === 2 ? parent.width * 0.8 : 0
                        height: 3
                        radius: 1.5
                        
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: colorAccent }
                            GradientStop { position: 1.0; color: lightenColor(colorAccent, 1.1) }
                        }

                        Behavior on width {
                            NumberAnimation {
                                duration: 300
                                easing.type: Easing.OutCubic
                            }
                        }
                    }

                    Row {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 12

                        Text {
                            text: "󰸉"
                            font.pixelSize: 16
                            color: colorText
                            opacity: currentTab === 2 ? 1.0 : 0.8
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: "Wallpapers"
                            font.pixelSize: 14
                            font.family: "sans-serif"
                            font.weight: currentTab === 2 ? Font.Bold : Font.Medium
                            color: colorText
                            opacity: currentTab === 2 ? 1.0 : 0.8
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        id: wallpapersMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            currentTab = 2
                            loadWallpapers()
                        }
                    }
                }

                // Bar tab
                Rectangle {
                    width: parent.width
                    height: 48
                    color: barMouseArea.pressed ? darkenColor(colorSecondary, 0.9) : (barMouseArea.containsMouse ? lightenColor(colorSecondary, 1.05) : "transparent")
                    radius: globalRadius
                    opacity: currentTab === 3 ? 1.0 : 0.7
                    scale: barMouseArea.pressed ? 0.98 : (barMouseArea.containsMouse ? 1.02 : 1.0)
                    
                    Behavior on color {
                        ColorAnimation {
                            duration: 200
                            easing.type: Easing.OutCubic
                        }
                    }
                    
                    Behavior on scale {
                        SpringAnimation {
                            spring: 4
                            damping: 0.4
                            epsilon: 0.01
                        }
                    }

                    // Bottom accent line for selected tab with gradient
                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: currentTab === 3 ? parent.width * 0.8 : 0
                        height: 3
                        radius: 1.5
                        
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: colorAccent }
                            GradientStop { position: 1.0; color: lightenColor(colorAccent, 1.1) }
                        }

                        Behavior on width {
                            NumberAnimation {
                                duration: 300
                                easing.type: Easing.OutCubic
                            }
                        }
                    }

                    Row {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 12

                        Text {
                            text: "󰍁"
                            font.pixelSize: 16
                            color: colorText
                            opacity: currentTab === 3 ? 1.0 : 0.8
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: "Bar"
                            font.pixelSize: 14
                            font.family: "sans-serif"
                            font.weight: currentTab === 3 ? Font.Bold : Font.Medium
                            color: colorText
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        id: barMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            currentTab = 3
                        }
                    }
                }

                // System tab
                Rectangle {
                    width: parent.width
                    height: 48
                    color: systemMouseArea.pressed ? darkenColor(colorSecondary, 0.9) : (systemMouseArea.containsMouse ? lightenColor(colorSecondary, 1.05) : "transparent")
                    radius: globalRadius
                    opacity: currentTab === 4 ? 1.0 : 0.7
                    scale: systemMouseArea.pressed ? 0.98 : (systemMouseArea.containsMouse ? 1.02 : 1.0)
                    
                    Behavior on color {
                        ColorAnimation {
                            duration: 200
                            easing.type: Easing.OutCubic
                        }
                    }
                    
                    Behavior on scale {
                        SpringAnimation {
                            spring: 4
                            damping: 0.4
                            epsilon: 0.01
                        }
                    }

                    // Bottom accent line for selected tab with gradient
                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: currentTab === 4 ? parent.width * 0.8 : 0
                        height: 3
                        radius: 1.5
                        
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: colorAccent }
                            GradientStop { position: 1.0; color: lightenColor(colorAccent, 1.1) }
                        }

                        Behavior on width {
                            NumberAnimation {
                                duration: 300
                                easing.type: Easing.OutCubic
                            }
                        }
                    }

                    Row {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 12

                        Text {
                            text: "󰒓"
                            font.pixelSize: 16
                            color: colorText
                            opacity: currentTab === 4 ? 1.0 : 0.8
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: "System"
                            font.pixelSize: 14
                            font.family: "sans-serif"
                            font.weight: currentTab === 4 ? Font.Bold : Font.Medium
                            color: colorText
                            opacity: currentTab === 4 ? 1.0 : 0.8
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        id: systemMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            currentTab = 4
                        }
                    }
                }

                // Audio tab
                Rectangle {
                    width: parent.width
                    height: 48
                    color: audioMouseArea.pressed ? darkenColor(colorSecondary, 0.9) : (audioMouseArea.containsMouse ? lightenColor(colorSecondary, 1.05) : "transparent")
                    radius: globalRadius
                    opacity: currentTab === 5 ? 1.0 : 0.7
                    scale: audioMouseArea.pressed ? 0.98 : (audioMouseArea.containsMouse ? 1.02 : 1.0)
                    
                    Behavior on color {
                        ColorAnimation {
                            duration: 200
                            easing.type: Easing.OutCubic
                        }
                    }
                    
                    Behavior on scale {
                        SpringAnimation {
                            spring: 4
                            damping: 0.4
                            epsilon: 0.01
                        }
                    }

                    // Bottom accent line for selected tab with gradient
                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: currentTab === 5 ? parent.width * 0.8 : 0
                        height: 3
                        radius: 1.5
                        
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: colorAccent }
                            GradientStop { position: 1.0; color: lightenColor(colorAccent, 1.1) }
                        }

                        Behavior on width {
                            NumberAnimation {
                                duration: 300
                                easing.type: Easing.OutCubic
                            }
                        }
                    }

                    Row {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 12

                        Text {
                            text: "󰓃"
                            font.pixelSize: 16
                            color: colorText
                            opacity: currentTab === 5 ? 1.0 : 0.8
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: "Audio"
                            font.pixelSize: 14
                            font.family: "sans-serif"
                            font.weight: currentTab === 5 ? Font.Bold : Font.Medium
                            color: colorText
                            opacity: currentTab === 5 ? 1.0 : 0.8
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        id: audioMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            currentTab = 5
                            loadAudioDevices()
                        }
                    }
                }
            }
            
            // Version text at bottom of sidebar
            Text {
                id: versionText
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: 16
                text: "v2.2.0"
                font.pixelSize: 11
                font.family: "sans-serif"
                font.weight: Font.Medium
                color: colorText
                opacity: 0.5
            }
        }

        // Content area
        Item {
            anchors.top: settingsHeader.bottom
            anchors.left: sidebar.right
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 0

            Rectangle {
                anchors.fill: parent
                color: colorBackground
            }

            // General Tab Content
            Item {
                anchors.fill: parent
                visible: currentTab === 0
                opacity: currentTab === 0 ? 1.0 : 0.0
                scale: currentTab === 0 ? 1.0 : 0.98
                
                Behavior on opacity {
                    NumberAnimation {
                        duration: 250
                        easing.type: Easing.OutCubic
                    }
                }
                
                Behavior on scale {
                    NumberAnimation {
                        duration: 250
                        easing.type: Easing.OutCubic
                    }
                }

                Flickable {
                    anchors.fill: parent
                    anchors.margins: 16
                    clip: true
                    contentHeight: generalColumn.implicitHeight

                    Column {
                        id: generalColumn
                        width: parent.width - 32
                        spacing: 24

                        Text {
                            text: "General Settings"
                            font.pixelSize: 24
                            font.family: "sans-serif"
                            font.weight: Font.Bold
                            color: colorText
                            opacity: 1.0
                        }

                        // Notifications Section
                        Column {
                            width: parent.width
                            spacing: 16

                            Text {
                                text: "Notifications"
                                font.pixelSize: 18
                                font.family: "sans-serif"
                                font.weight: Font.Bold
                                color: colorText
                                opacity: 1.0
                            }

                            // Enable Notifications Toggle
                            Rectangle {
                                width: parent.width
                                height: 64
                                color: colorPrimary
                                radius: globalRadius
                                
                                // Card shadow
                                Rectangle {
                                    anchors.fill: parent
                                    anchors.margins: -getShadowProps(2).offset
                                    color: Qt.rgba(0, 0, 0, getShadowProps(2).opacity)
                                    radius: parent.radius + getShadowProps(2).offset
                                    z: -1
                                }

                                Row {
                                    anchors.fill: parent
                                    anchors.margins: 16
                                    spacing: 15

                                    Column {
                                        width: parent.width - 80
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 4

                                        Text {
                                            text: "Show Notifications"
                                            font.pixelSize: 14
                                            font.family: "sans-serif"
                                            font.weight: Font.Medium
                                            color: colorText
                                        }

                                        Text {
                                            text: "Enable or disable notification display"
                                            font.pixelSize: 11
                                            font.family: "sans-serif"
                                            color: colorText
                                            opacity: 0.7
                                        }
                                    }

                                    Rectangle {
                                        width: 50
                                        height: 28
                                        radius: 14
                                        color: (sharedData && sharedData.notificationsEnabled) ? colorAccent : colorSecondary
                                        anchors.verticalCenter: parent.verticalCenter

                                        Rectangle {
                                            width: 24
                                            height: 24
                                            radius: 12
                                            color: colorText
                                            anchors.verticalCenter: parent.verticalCenter
                                            x: (sharedData && sharedData.notificationsEnabled) ? parent.width - width - 2 : 2

                                            Behavior on x {
                                                NumberAnimation {
                                                    duration: 200
                                                    easing.type: Easing.OutCubic
                                                }
                                            }
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                if (sharedData) {
                                                    sharedData.notificationsEnabled = !sharedData.notificationsEnabled
                                                    saveNotificationSettings()
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            // Notification Sounds Toggle
                            Rectangle {
                                width: parent.width
                                height: 64
                                color: colorPrimary
                                radius: globalRadius
                                
                                // Card shadow
                                Rectangle {
                                    anchors.fill: parent
                                    anchors.margins: -getShadowProps(2).offset
                                    color: Qt.rgba(0, 0, 0, getShadowProps(2).opacity)
                                    radius: parent.radius + getShadowProps(2).offset
                                    z: -1
                                }

                                Row {
                                    anchors.fill: parent
                                    anchors.margins: 16
                                    spacing: 16

                                    Column {
                                        width: parent.width - 80
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 4

                                        Text {
                                            text: "Notification Sounds"
                                            font.pixelSize: 14
                                            font.family: "sans-serif"
                                            font.weight: Font.Medium
                                            color: colorText
                                        }

                                        Text {
                                            text: "Play sound when notification arrives"
                                            font.pixelSize: 11
                                            font.family: "sans-serif"
                                            color: colorText
                                            opacity: 0.7
                                        }
                                    }

                                    Rectangle {
                                        width: 50
                                        height: 28
                                        radius: 14
                                        color: (sharedData && sharedData.notificationSoundsEnabled) ? colorAccent : colorSecondary
                                        anchors.verticalCenter: parent.verticalCenter

                                        Rectangle {
                                            width: 24
                                            height: 24
                                            radius: 12
                                            color: colorText
                                            anchors.verticalCenter: parent.verticalCenter
                                            x: (sharedData && sharedData.notificationSoundsEnabled) ? parent.width - width - 2 : 2

                                            Behavior on x {
                                                NumberAnimation {
                                                    duration: 200
                                                    easing.type: Easing.OutCubic
                                                }
                                            }
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                if (sharedData) {
                                                    sharedData.notificationSoundsEnabled = !sharedData.notificationSoundsEnabled
                                                    saveNotificationSettings()
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Color Presets Tab Content - shows color picker directly
            Item {
                anchors.fill: parent
                visible: currentTab === 1
                opacity: currentTab === 1 ? 1.0 : 0.0
                scale: currentTab === 1 ? 1.0 : 0.98
                
                Behavior on opacity {
                    NumberAnimation {
                        duration: 250
                        easing.type: Easing.OutCubic
                    }
                }
                
                Behavior on scale {
                    NumberAnimation {
                        duration: 250
                        easing.type: Easing.OutCubic
                    }
                }

                // Color Picker - always visible in Color Presets tab
                Item {
                    anchors.fill: parent
                    visible: true

                    // Color customization content
                    Flickable {
                        anchors.fill: parent
                        anchors.margins: 16
                        clip: true
                        contentHeight: colorPickerColumn.implicitHeight

                        Column {
                            id: colorPickerColumn
                            width: parent.width - 32
                            spacing: 24

                            Text {
                                text: "Color Presets"
                                font.pixelSize: 24
                                font.family: "sans-serif"
                                font.weight: Font.Bold
                                color: colorText
                                opacity: 1.0
                            }

                            // Color Presets Section
                            Column {
                                width: parent.width
                                spacing: 16

                                Text {
                                    text: "Color Presets"
                                    font.pixelSize: 18
                                    font.family: "sans-serif"
                                    font.weight: Font.Bold
                                    color: colorText
                                }

                                Text {
                                    text: "Choose from predefined color schemes"
                                    font.pixelSize: 12
                                    font.family: "sans-serif"
                                    color: colorText
                                    opacity: 0.7
                                }

                                // Presets Grid
                                Grid {
                                    width: parent.width
                                    columns: 3
                                    spacing: 16

                                    Repeater {
                                        model: ["Dark", "Ocean", "Forest", "Violet", "Crimson", "Amber", "Teal", "Rose", "Sunset", "Midnight", "Emerald", "Lavender", "Sapphire", "Coral", "Mint", "Plum", "Gold", "Monochrome", "Cherry", "Azure", "Jade", "Ruby", "Indigo"]

                                        Rectangle {
                                            width: (parent.width - 32) / 3
                                            height: 104
                                            color: presetMouseArea.pressed ? darkenColor(colorSecondary, 0.9) : (presetMouseArea.containsMouse ? lightenColor(colorSecondary, 1.05) : colorSecondary)
                                            radius: globalRadius
                                            scale: presetMouseArea.pressed ? 0.98 : (presetMouseArea.containsMouse ? 1.02 : 1.0)
                                            
                                            // Card shadow
                                            Rectangle {
                                                anchors.fill: parent
                                                anchors.margins: -getShadowProps(2).offset
                                                color: Qt.rgba(0, 0, 0, getShadowProps(2).opacity)
                                                radius: parent.radius + getShadowProps(2).offset
                                                z: -1
                                            }
                                            
                                            Behavior on color {
                                                ColorAnimation {
                                                    duration: 200
                                                    easing.type: Easing.OutCubic
                                                }
                                            }
                                            
                                            Behavior on scale {
                                                SpringAnimation {
                                                    spring: 4
                                                    damping: 0.4
                                                    epsilon: 0.01
                                                }
                                            }

                                            // Color preview bars
                                            Column {
                                                anchors.fill: parent
                                                anchors.margins: 16
                                                spacing: 4

                                                Rectangle {
                                                    width: parent.width
                                                    height: 12
                                                    radius: (sharedData && sharedData.quickshellBorderRadius) ? sharedData.quickshellBorderRadius : 0
                                                    color: colorPresets[modelData] ? colorPresets[modelData].background : "#000000"
                                                }
                                                Rectangle {
                                                    width: parent.width
                                                    height: 12
                                                    radius: (sharedData && sharedData.quickshellBorderRadius) ? sharedData.quickshellBorderRadius : 0
                                                    color: colorPresets[modelData] ? colorPresets[modelData].primary : "#000000"
                                                }
                                                Rectangle {
                                                    width: parent.width
                                                    height: 12
                                                    radius: (sharedData && sharedData.quickshellBorderRadius) ? sharedData.quickshellBorderRadius : 0
                                                    color: colorPresets[modelData] ? colorPresets[modelData].secondary : "#000000"
                                                }
                                                Rectangle {
                                                    width: parent.width
                                                    height: 12
                                                    radius: (sharedData && sharedData.quickshellBorderRadius) ? sharedData.quickshellBorderRadius : 0
                                                    color: colorPresets[modelData] ? colorPresets[modelData].text : "#ffffff"
                                                }
                                            }

                                            // Preset name
                                            Text {
                                                anchors.bottom: parent.bottom
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                anchors.margins: 12
                                                text: modelData
                                                font.pixelSize: 13
                                                font.family: "sans-serif"
                                                font.weight: Font.Medium
                                                color: colorText
                                                opacity: 1.0
                                            }

                                            MouseArea {
                                                id: presetMouseArea
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    applyColorPreset(modelData)
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                width: parent.width
                                height: 1
                                color: colorSecondary
                            }

                            // Custom Colors Section
                            Column {
                                width: parent.width
                                spacing: 16

                                Text {
                                    text: "Custom Colors"
                                    font.pixelSize: 18
                                    font.family: "sans-serif"
                                    font.weight: Font.Bold
                                    color: colorText
                                    opacity: 1.0
                                }

                                Text {
                                    text: "Enter custom HEX color values"
                                    font.pixelSize: 12
                                    font.family: "sans-serif"
                                    color: colorText
                                    opacity: 0.7
                                }

                                // Color input fields
                                Column {
                                    width: parent.width
                                    spacing: 16

                                    // Background
                                    Row {
                                        width: parent.width
                                        spacing: 12

                                        Rectangle {
                                            width: 40
                                            height: 40
                                            color: customBackground || colorBackground
                                            radius: (sharedData && sharedData.quickshellBorderRadius) ? sharedData.quickshellBorderRadius : 0
                                            border.width: 1
                                            border.color: colorText
                                            opacity: 0.8
                                        }

                                        Column {
                                            width: parent.width - 52
                                            spacing: 4

                                            Text {
                                                text: "Background"
                                                font.pixelSize: 14
                                                font.family: "sans-serif"
                                                font.weight: Font.Medium
                                                color: colorText
                                            }

                                            TextInput {
                                                id: backgroundInput
                                                width: parent.width
                                                text: colorBackground
                                                font.pixelSize: 12
                                                font.family: "sans-serif"
                                                color: colorText
                                                selectionColor: colorAccent

                                                Rectangle {
                                                    anchors.fill: parent
                                                    color: "transparent"
                                                    border.width: parent.activeFocus ? 2 : 1
                                                    border.color: parent.activeFocus ? colorAccent : colorSecondary
                                                    radius: (sharedData && sharedData.quickshellBorderRadius) ? sharedData.quickshellBorderRadius : 0
                                                }

                                                onTextChanged: {
                                                    customBackground = text
                                                }
                                            }
                                        }
                                    }

                                    // Primary
                                    Row {
                                        width: parent.width
                                        spacing: 12

                                        Rectangle {
                                            width: 40
                                            height: 40
                                            color: customPrimary || colorPrimary
                                            radius: (sharedData && sharedData.quickshellBorderRadius) ? sharedData.quickshellBorderRadius : 0
                                            border.width: 1
                                            border.color: colorText
                                            opacity: 0.8
                                        }

                                        Column {
                                            width: parent.width - 52
                                            spacing: 4

                                            Text {
                                                text: "Primary"
                                                font.pixelSize: 14
                                                font.family: "sans-serif"
                                                font.weight: Font.Medium
                                                color: colorText
                                            }

                                            TextInput {
                                                id: primaryInput
                                                width: parent.width
                                                text: colorPrimary
                                                font.pixelSize: 12
                                                font.family: "sans-serif"
                                                color: colorText
                                                selectionColor: colorAccent

                                                Rectangle {
                                                    anchors.fill: parent
                                                    color: "transparent"
                                                    border.width: parent.activeFocus ? 2 : 1
                                                    border.color: parent.activeFocus ? colorAccent : colorSecondary
                                                    radius: (sharedData && sharedData.quickshellBorderRadius) ? sharedData.quickshellBorderRadius : 0
                                                }

                                                onTextChanged: {
                                                    customPrimary = text
                                                }
                                            }
                                        }
                                    }

                                    // Secondary
                                    Row {
                                        width: parent.width
                                        spacing: 12

                                        Rectangle {
                                            width: 40
                                            height: 40
                                            color: customSecondary || colorSecondary
                                            radius: (sharedData && sharedData.quickshellBorderRadius) ? sharedData.quickshellBorderRadius : 0
                                            border.width: 1
                                            border.color: colorText
                                            opacity: 0.8
                                        }

                                        Column {
                                            width: parent.width - 52
                                            spacing: 4

                                            Text {
                                                text: "Secondary"
                                                font.pixelSize: 14
                                                font.family: "sans-serif"
                                                font.weight: Font.Medium
                                                color: colorText
                                            }

                                            TextInput {
                                                id: secondaryInput
                                                width: parent.width
                                                text: colorSecondary
                                                font.pixelSize: 12
                                                font.family: "sans-serif"
                                                color: colorText
                                                selectionColor: colorAccent

                                                Rectangle {
                                                    anchors.fill: parent
                                                    color: "transparent"
                                                    border.width: parent.activeFocus ? 2 : 1
                                                    border.color: parent.activeFocus ? colorAccent : colorSecondary
                                                    radius: (sharedData && sharedData.quickshellBorderRadius) ? sharedData.quickshellBorderRadius : 0
                                                }

                                                onTextChanged: {
                                                    customSecondary = text
                                                }
                                            }
                                        }
                                    }

                                    // Text
                                    Row {
                                        width: parent.width
                                        spacing: 12

                                        Rectangle {
                                            width: 40
                                            height: 40
                                            color: customText || colorText
                                            radius: (sharedData && sharedData.quickshellBorderRadius) ? sharedData.quickshellBorderRadius : 0
                                            border.width: 1
                                            border.color: colorPrimary
                                            opacity: 0.8
                                        }

                                        Column {
                                            width: parent.width - 52
                                            spacing: 4

                                            Text {
                                                text: "Text"
                                                font.pixelSize: 14
                                                font.family: "sans-serif"
                                                font.weight: Font.Medium
                                                color: colorText
                                            }

                                            TextInput {
                                                id: textColorInput
                                                width: parent.width
                                                text: colorText
                                                font.pixelSize: 12
                                                font.family: "sans-serif"
                                                color: colorText
                                                selectionColor: colorAccent

                                                Rectangle {
                                                    anchors.fill: parent
                                                    color: "transparent"
                                                    border.width: parent.activeFocus ? 2 : 1
                                                    border.color: parent.activeFocus ? colorAccent : colorSecondary
                                                    radius: (sharedData && sharedData.quickshellBorderRadius) ? sharedData.quickshellBorderRadius : 0
                                                }

                                                onTextChanged: {
                                                    customText = text
                                                }
                                            }
                                        }
                                    }

                                    // Accent
                                    Row {
                                        width: parent.width
                                        spacing: 12

                                        Rectangle {
                                            width: 40
                                            height: 40
                                            color: customAccent || colorAccent
                                            radius: (sharedData && sharedData.quickshellBorderRadius) ? sharedData.quickshellBorderRadius : 0
                                            border.width: 1
                                            border.color: colorText
                                            opacity: 0.8
                                        }

                                        Column {
                                            width: parent.width - 52
                                            spacing: 4

                                            Text {
                                                text: "Accent"
                                                font.pixelSize: 14
                                                font.family: "sans-serif"
                                                font.weight: Font.Medium
                                                color: colorText
                                            }

                                            TextInput {
                                                id: accentInput
                                                width: parent.width
                                                text: colorAccent
                                                font.pixelSize: 12
                                                font.family: "sans-serif"
                                                color: colorText
                                                selectionColor: colorAccent

                                                Rectangle {
                                                    anchors.fill: parent
                                                    color: "transparent"
                                                    border.width: parent.activeFocus ? 2 : 1
                                                    border.color: parent.activeFocus ? colorAccent : colorSecondary
                                                    radius: (sharedData && sharedData.quickshellBorderRadius) ? sharedData.quickshellBorderRadius : 0
                                                }

                                                onTextChanged: {
                                                    customAccent = text
                                                }
                                            }
                                        }
                                    }
                                }

                                // Apply button
                                Rectangle {
                                    width: parent.width
                                    height: 45
                                    color: applyButtonMouseArea.containsMouse ? colorAccent : colorSecondary
                                    radius: (sharedData && sharedData.quickshellBorderRadius) ? sharedData.quickshellBorderRadius : 0
                                    anchors.horizontalCenter: parent.horizontalCenter

                                    Text {
                                        text: "Apply Custom Colors"
                                        font.pixelSize: 14
                                        font.family: "sans-serif"
                                        font.weight: Font.Medium
                                        color: colorText
                                        anchors.centerIn: parent
                                    }

                                    MouseArea {
                                        id: applyButtonMouseArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            applyCustomColors()
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Wallpapers Tab Content - shows wallpaper picker directly
            Item {
                anchors.fill: parent
                visible: currentTab === 2
                opacity: currentTab === 2 ? 1.0 : 0.0
                scale: currentTab === 2 ? 1.0 : 0.98
                
                Behavior on opacity {
                    NumberAnimation {
                        duration: 250
                        easing.type: Easing.OutCubic
                    }
                }
                
                Behavior on scale {
                    NumberAnimation {
                        duration: 250
                        easing.type: Easing.OutCubic
                    }
                }

                // Auto-load wallpapers when tab becomes visible
                onVisibleChanged: {
                    if (visible) {
                        loadWallpapers()
                    }
                }

                Component.onCompleted: {
                    if (currentTab === 2) {
                        loadWallpapers()
                    }
                }

                // Wallpaper Picker - always visible in Wallpapers tab
                Item {
                    anchors.fill: parent
                    visible: true

                    Flickable {
                        anchors.fill: parent
                        anchors.margins: 16
                        clip: true
                        contentHeight: wallpaperPickerColumn.implicitHeight

                        Column {
                            id: wallpaperPickerColumn
                            width: parent.width - 32
                            spacing: 24

                            Row {
                                width: parent.width
                                spacing: 16
                                
                                Text {
                                    text: "Select Wallpaper (" + wallpapersModel.count + ")"
                                    font.pixelSize: 24
                                    font.family: "sans-serif"
                                    font.weight: Font.Bold
                                    color: colorText
                                    opacity: 1.0
                                }
                                
                                // Refresh button
                                Rectangle {
                                    width: 80
                                    height: 32
                                    color: refreshButtonMouseArea.containsMouse ? (refreshButtonMouseArea.pressed ? darkenColor(colorSecondary, 0.9) : lightenColor(colorSecondary, 1.05)) : colorSecondary
                                    radius: 4
                                    anchors.verticalCenter: parent.verticalCenter
                                    
                                    Text {
                                        text: "Refresh"
                                        font.pixelSize: 12
                                        font.family: "sans-serif"
                                        color: colorText
                                        anchors.centerIn: parent
                                    }
                                    
                                    MouseArea {
                                        id: refreshButtonMouseArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            console.log("Refreshing wallpaper list...")
                                            loadWallpapers()
                                        }
                                    }
                                }
                            }

                            // Wallpapers Grid
                            GridView {
                                id: wallpapersGrid
                                width: parent.width
                                // Explicitly calculate height to ensure all items are visible
                                height: {
                                    var rows = Math.ceil(wallpapersModel.count / 3);
                                    var cw = Math.floor((width - 32) / 3);
                                    var ch = Math.floor(cw * 9 / 16) + 24;
                                    return Math.max(400, rows * ch);
                                }
                                cellWidth: Math.floor((width - 32) / 3)
                                cellHeight: Math.floor(cellWidth * 9 / 16) + 24
                                clip: false
                                interactive: false

                                model: wallpapersModel
                                currentIndex: wallpaperSelectedIndex

                                onCurrentIndexChanged: {
                                    wallpaperSelectedIndex = currentIndex
                                }

                                delegate: Item {
                                    width: wallpapersGrid.cellWidth
                                    height: wallpapersGrid.cellHeight

                                    Rectangle {
                                        id: wallpaperItem
                                        anchors.centerIn: parent
                                        width: parent.width - 16
                                        height: parent.height - 16
                                        color: colorPrimary
                                        radius: globalRadius
                                        scale: wallpaperItemMouseArea.containsMouse ? 1.05 : 1.0
                                        
                                        // Card shadow
                                        Rectangle {
                                            anchors.fill: parent
                                            anchors.margins: -getShadowProps(2).offset
                                            color: Qt.rgba(0, 0, 0, getShadowProps(2).opacity)
                                            radius: parent.radius + getShadowProps(2).offset
                                            z: -1
                                        }
                                        
                                        Behavior on scale {
                                            SpringAnimation {
                                                spring: 4
                                                damping: 0.4
                                                epsilon: 0.01
                                            }
                                        }

                                        Image {
                                            id: wallpaperThumbnail
                                            anchors.fill: parent
                                            anchors.margins: 2
                                            source: "file://" + model.path
                                            fillMode: Image.PreserveAspectCrop
                                            asynchronous: true
                                            cache: false // Disable cache to see new wallpapers immediately
                                            sourceSize.width: 400
                                            sourceSize.height: 225  // 16:9 ratio

                                            // Loading indicator
                                            Rectangle {
                                                anchors.fill: parent
                                                color: colorSecondary
                                                visible: wallpaperThumbnail.status === Image.Loading
                                                radius: globalRadius

                                                Text {
                                                    text: "󰔟"
                                                    font.pixelSize: 24
                                                    color: colorText
                                                    opacity: 0.5
                                                    anchors.centerIn: parent
                                                }
                                            }
                                        }

                                        MouseArea {
                                            id: wallpaperItemMouseArea
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                setWallpaper(model.path)
                                            }
                                        }
                                    }
                                }

                                // Empty state
                                Column {
                                    anchors.centerIn: parent
                                    spacing: 15
                                    visible: wallpapersModel.count === 0

                                    Text {
                                        text: "󰸉"
                                        font.pixelSize: 48
                                        color: colorText
                                        opacity: 0.3
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }

                                    Text {
                                        text: "No wallpapers found"
                                        font.pixelSize: 16
                                        font.family: "sans-serif"
                                        color: colorText
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Bar Tab Content
            Item {
                anchors.fill: parent
                visible: currentTab === 3
                opacity: currentTab === 3 ? 1.0 : 0.0
                scale: currentTab === 3 ? 1.0 : 0.98
                
                Behavior on opacity {
                    NumberAnimation {
                        duration: 250
                        easing.type: Easing.OutCubic
                    }
                }
                
                Behavior on scale {
                    NumberAnimation {
                        duration: 250
                        easing.type: Easing.OutCubic
                    }
                }

                Flickable {
                    anchors.fill: parent
                    anchors.margins: 20
                    clip: true
                    contentHeight: barColumn.implicitHeight

                    Column {
                        id: barColumn
                        width: parent.width - 40
                        spacing: 20

                        Text {
                            text: "Bar Settings"
                            font.pixelSize: 24
                            font.family: "sans-serif"
                            font.weight: Font.Bold
                            color: colorText
                        }

                        // Sidebar Toggle
                        Rectangle {
                            width: parent.width
                            height: 60
                            color: colorPrimary
                            radius: (sharedData && sharedData.quickshellBorderRadius) ? sharedData.quickshellBorderRadius : 0

                            Row {
                                anchors.fill: parent
                                anchors.margins: 15
                                spacing: 15

                                Text {
                                    text: "󰍁"
                                    font.pixelSize: 20
                                    color: colorText
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Column {
                                    width: parent.width - 80
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 2

                                    Text {
                                        text: "Show Sidebar"
                                        font.pixelSize: 14
                                        font.family: "sans-serif"
                                        font.weight: Font.Medium
                                        color: colorText
                                    }

                                    Text {
                                        text: "Toggle visibility of the side panel"
                                        font.pixelSize: 11
                                        font.family: "sans-serif"
                                        color: colorText
                                        opacity: 0.7
                                    }
                                }

                                Rectangle {
                                    width: 40
                                    height: 20
                                    color: (sharedData && sharedData.sidebarVisible) ? colorAccent : colorSecondary
                                    radius: (sharedData && sharedData.quickshellBorderRadius) ? sharedData.quickshellBorderRadius : 0
                                    anchors.verticalCenter: parent.verticalCenter

                                    Rectangle {
                                        width: 16
                                        height: 16
                                        color: colorText
                                        radius: (sharedData && sharedData.quickshellBorderRadius) ? sharedData.quickshellBorderRadius : 0
                                        x: (sharedData && sharedData.sidebarVisible) ? 20 : 2
                                        anchors.verticalCenter: parent.verticalCenter

                                        Behavior on x {
                                            NumberAnimation { duration: 150 }
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: {
                                            if (sharedData && sharedData.sidebarVisible !== undefined) {
                                                sharedData.sidebarVisible = !sharedData.sidebarVisible
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Sidebar Position
                        Rectangle {
                            width: parent.width
                            height: 60
                            color: colorPrimary
                            radius: (sharedData && sharedData.quickshellBorderRadius) ? sharedData.quickshellBorderRadius : 0

                            Row {
                                anchors.fill: parent
                                anchors.margins: 15
                                spacing: 15

                                Text {
                                    text: "󰍇"
                                    font.pixelSize: 20
                                    color: colorText
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Column {
                                    width: parent.width - 200
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 2

                                    Text {
                                        text: "Sidebar Position"
                                        font.pixelSize: 14
                                        font.family: "sans-serif"
                                        font.weight: Font.Medium
                                        color: colorText
                                    }

                                    Text {
                                        text: "Choose sidebar position: Left or Top"
                                        font.pixelSize: 11
                                        font.family: "sans-serif"
                                        color: colorText
                                        opacity: 0.7
                                    }
                                }

                                Row {
                                    spacing: 10
                                    anchors.verticalCenter: parent.verticalCenter

                                    Rectangle {
                                        width: 60
                                        height: 30
                                        color: (sharedData && sharedData.sidebarPosition === "left") ? colorAccent : colorSecondary
                                        radius: (sharedData && sharedData.quickshellBorderRadius) ? sharedData.quickshellBorderRadius : 0

                                        Text {
                                            text: "Left"
                                            font.pixelSize: 12
                                            font.family: "sans-serif"
                                            color: colorText
                                            anchors.centerIn: parent
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            onClicked: {
                                                if (sharedData) {
                                                    sharedData.sidebarPosition = "left"
                                                    // Save sidebar position
                                                    saveColors("", "", "left")
                                                }
                                            }
                                        }
                                    }

                                    Rectangle {
                                        width: 60
                                        height: 30
                                        color: (sharedData && sharedData.sidebarPosition === "top") ? colorAccent : colorSecondary
                                        radius: (sharedData && sharedData.quickshellBorderRadius) ? sharedData.quickshellBorderRadius : 0

                                        Text {
                                            text: "Top"
                                            font.pixelSize: 12
                                            font.family: "sans-serif"
                                            color: colorText
                                            anchors.centerIn: parent
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            onClicked: {
                                                if (sharedData) {
                                                    sharedData.sidebarPosition = "top"
                                                    // Save sidebar position
                                                    saveColors("", "", "top")
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // System Tab Content
            Item {
                anchors.fill: parent
                visible: currentTab === 4
                opacity: currentTab === 4 ? 1.0 : 0.0
                scale: currentTab === 4 ? 1.0 : 0.98
                
                Behavior on opacity {
                    NumberAnimation {
                        duration: 250
                        easing.type: Easing.OutCubic
                    }
                }
                
                Behavior on scale {
                    NumberAnimation {
                        duration: 250
                        easing.type: Easing.OutCubic
                    }
                }

                Flickable {
                    anchors.fill: parent
                    anchors.margins: 20
                    clip: true
                    contentHeight: systemColumn.implicitHeight

                    Column {
                        id: systemColumn
                        width: parent.width - 40
                        spacing: 20

                        Text {
                            text: "System Settings"
                            font.pixelSize: 24
                            font.family: "sans-serif"
                            font.weight: Font.Bold
                            color: colorText
                        }

                        Text {
                            text: "System-related settings will appear here."
                            font.pixelSize: 14
                            font.family: "sans-serif"
                            color: colorText
                            opacity: 0.7
                        }
                    }
                }
            }

            // Audio Tab Content
            Item {
                anchors.fill: parent
                visible: currentTab === 5
                opacity: currentTab === 5 ? 1.0 : 0.0
                scale: currentTab === 5 ? 1.0 : 0.98
                
                Behavior on opacity {
                    NumberAnimation {
                        duration: 250
                        easing.type: Easing.OutCubic
                    }
                }
                
                Behavior on scale {
                    NumberAnimation {
                        duration: 250
                        easing.type: Easing.OutCubic
                    }
                }

                Flickable {
                    anchors.fill: parent
                    anchors.margins: 20
                    clip: true
                    contentHeight: audioColumn.implicitHeight

                    Column {
                        id: audioColumn
                        width: parent.width - 40
                        spacing: 30

                        Text {
                            text: "Audio Settings"
                            font.pixelSize: 24
                            font.family: "sans-serif"
                            font.weight: Font.Bold
                            color: colorText
                        }

                        // Default Output Device
                        Column {
                            width: parent.width
                            spacing: 20

                            Row {
                                width: parent.width
                                spacing: 12

                                Text {
                                    text: "󰓃"
                                    font.pixelSize: 24
                                    color: colorAccent
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Column {
                                    width: parent.width - 50
                                    spacing: 4

                                    Text {
                                        text: "Output"
                                        font.pixelSize: 20
                                        font.family: "sans-serif"
                                        font.weight: Font.Bold
                                        color: colorText
                                    }

                                    Text {
                                        text: defaultSinkDescription || defaultSink || "No device"
                                        font.pixelSize: 13
                                        font.family: "sans-serif"
                                        color: colorText
                                        opacity: 0.8
                                        elide: Text.ElideRight
                                    }
                                }
                            }

                            Rectangle {
                                width: parent.width
                                height: 100
                                color: colorPrimary
                                radius: (sharedData && sharedData.quickshellBorderRadius) ? sharedData.quickshellBorderRadius : 0

                                Column {
                                    anchors.fill: parent
                                    anchors.margins: 20
                                    spacing: 15

                                    Row {
                                        width: parent.width
                                        spacing: 15

                                        Rectangle {
                                            id: defaultSinkMuteButton
                                            width: 50
                                            height: 50
                                            color: defaultSinkMute ? colorAccent : (defaultSinkMuteMouseArea.containsMouse ? colorSecondary : colorSecondary)
                                            radius: (sharedData && sharedData.quickshellBorderRadius) ? sharedData.quickshellBorderRadius : 0
                                            anchors.verticalCenter: parent.verticalCenter

                                            Text {
                                                text: defaultSinkMute ? "󰝟" : "󰓃"
                                                font.pixelSize: 24
                                                color: defaultSinkMute ? colorText : colorText
                                                anchors.centerIn: parent
                                            }

                                            MouseArea {
                                                id: defaultSinkMuteMouseArea
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    defaultSinkMute = !defaultSinkMute
                                                    setDefaultSinkMute(defaultSinkMute)
                                                }
                                            }
                                        }

                                        Column {
                                            width: parent.width - 80
                                            spacing: 8
                                            anchors.verticalCenter: parent.verticalCenter

                                            Row {
                                                width: parent.width
                                                spacing: 10

                                                Text {
                                                    text: "󰕾"
                                                    font.pixelSize: 14
                                                    color: colorText
                                                    opacity: 0.7
                                                    anchors.verticalCenter: parent.verticalCenter
                                                }

                                                Rectangle {
                                                    width: parent.width - 60
                                                    height: 12
                                                    color: colorSecondary
                                                    radius: (sharedData && sharedData.quickshellBorderRadius) ? sharedData.quickshellBorderRadius : 0
                                                    anchors.verticalCenter: parent.verticalCenter

                                                    Rectangle {
                                                        id: defaultSinkVolumeBar
                                                        width: parent.width * (defaultSinkVolume / 100)
                                                        height: parent.height
                                                        color: defaultSinkMute ? Qt.darker(colorAccent, 1.3) : colorAccent
                                                        radius: (sharedData && sharedData.quickshellBorderRadius) ? sharedData.quickshellBorderRadius : 0
                                                    }

                                                    MouseArea {
                                                        anchors.fill: parent
                                                        onClicked: function(mouse) {
                                                            var newValue = (mouse.x / parent.width) * 100
                                                            defaultSinkVolume = Math.max(0, Math.min(100, newValue))
                                                            setDefaultSinkVolume(defaultSinkVolume)
                                                            if (defaultSinkMute && defaultSinkVolume > 0) {
                                                                defaultSinkMute = false
                                                                setDefaultSinkMute(false)
                                                            }
                                                        }
                                                        onPositionChanged: function(mouse) {
                                                            if (pressed) {
                                                                var newValue = (mouse.x / parent.width) * 100
                                                                defaultSinkVolume = Math.max(0, Math.min(100, newValue))
                                                                setDefaultSinkVolume(defaultSinkVolume)
                                                                if (defaultSinkMute && defaultSinkVolume > 0) {
                                                                    defaultSinkMute = false
                                                                    setDefaultSinkMute(false)
                                                                }
                                                            }
                                                        }
                                                    }
                                                }

                                                Text {
                                                    text: Math.round(defaultSinkVolume) + "%"
                                                    font.pixelSize: 13
                                                    font.family: "sans-serif"
                                                    font.weight: Font.Medium
                                                    color: colorText
                                                    width: 40
                                                    anchors.verticalCenter: parent.verticalCenter
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Default Input Device
                        Column {
                            width: parent.width
                            spacing: 20

                            Row {
                                width: parent.width
                                spacing: 12

                                Text {
                                    text: "󰍬"
                                    font.pixelSize: 24
                                    color: colorAccent
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Column {
                                    width: parent.width - 50
                                    spacing: 4

                                    Text {
                                        text: "Input"
                                        font.pixelSize: 20
                                        font.family: "sans-serif"
                                        font.weight: Font.Bold
                                        color: colorText
                                    }

                                    Text {
                                        text: defaultSourceDescription || defaultSource || "No device"
                                        font.pixelSize: 13
                                        font.family: "sans-serif"
                                        color: colorText
                                        opacity: 0.8
                                        elide: Text.ElideRight
                                    }
                                }
                            }

                            Rectangle {
                                width: parent.width
                                height: 100
                                color: colorPrimary
                                radius: (sharedData && sharedData.quickshellBorderRadius) ? sharedData.quickshellBorderRadius : 0

                                Column {
                                    anchors.fill: parent
                                    anchors.margins: 20
                                    spacing: 15

                                    Row {
                                        width: parent.width
                                        spacing: 15

                                        Rectangle {
                                            id: defaultSourceMuteButton
                                            width: 50
                                            height: 50
                                            color: defaultSourceMute ? colorAccent : (defaultSourceMuteMouseArea.containsMouse ? colorSecondary : colorSecondary)
                                            radius: (sharedData && sharedData.quickshellBorderRadius) ? sharedData.quickshellBorderRadius : 0
                                            anchors.verticalCenter: parent.verticalCenter

                                            Text {
                                                text: defaultSourceMute ? "󰝟" : "󰍬"
                                                font.pixelSize: 24
                                                color: colorText
                                                anchors.centerIn: parent
                                            }

                                            MouseArea {
                                                id: defaultSourceMuteMouseArea
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    defaultSourceMute = !defaultSourceMute
                                                    setDefaultSourceMute(defaultSourceMute)
                                                }
                                            }
                                        }

                                        Column {
                                            width: parent.width - 80
                                            spacing: 8
                                            anchors.verticalCenter: parent.verticalCenter

                                            Row {
                                                width: parent.width
                                                spacing: 10

                                                Text {
                                                    text: "󰕾"
                                                    font.pixelSize: 14
                                                    color: colorText
                                                    opacity: 0.7
                                                    anchors.verticalCenter: parent.verticalCenter
                                                }

                                                Rectangle {
                                                    width: parent.width - 60
                                                    height: 12
                                                    color: colorSecondary
                                                    radius: (sharedData && sharedData.quickshellBorderRadius) ? sharedData.quickshellBorderRadius : 0
                                                    anchors.verticalCenter: parent.verticalCenter

                                                    Rectangle {
                                                        id: defaultSourceVolumeBar
                                                        width: parent.width * (defaultSourceVolume / 100)
                                                        height: parent.height
                                                        color: defaultSourceMute ? Qt.darker(colorAccent, 1.3) : colorAccent
                                                        radius: (sharedData && sharedData.quickshellBorderRadius) ? sharedData.quickshellBorderRadius : 0
                                                    }

                                                    MouseArea {
                                                        anchors.fill: parent
                                                        onClicked: function(mouse) {
                                                            var newValue = (mouse.x / parent.width) * 100
                                                            defaultSourceVolume = Math.max(0, Math.min(100, newValue))
                                                            setDefaultSourceVolume(defaultSourceVolume)
                                                            if (defaultSourceMute && defaultSourceVolume > 0) {
                                                                defaultSourceMute = false
                                                                setDefaultSourceMute(false)
                                                            }
                                                        }
                                                        onPositionChanged: function(mouse) {
                                                            if (pressed) {
                                                                var newValue = (mouse.x / parent.width) * 100
                                                                defaultSourceVolume = Math.max(0, Math.min(100, newValue))
                                                                setDefaultSourceVolume(defaultSourceVolume)
                                                                if (defaultSourceMute && defaultSourceVolume > 0) {
                                                                    defaultSourceMute = false
                                                                    setDefaultSourceMute(false)
                                                                }
                                                            }
                                                        }
                                                    }
                                                }

                                                Text {
                                                    text: Math.round(defaultSourceVolume) + "%"
                                                    font.pixelSize: 13
                                                    font.family: "sans-serif"
                                                    font.weight: Font.Medium
                                                    color: colorText
                                                    width: 40
                                                    anchors.verticalCenter: parent.verticalCenter
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Separator
                        Rectangle {
                            width: parent.width
                            height: 1
                            color: colorSecondary
                            opacity: 0.5
                        }

                        // Output Devices Section
                        Column {
                            width: parent.width
                            spacing: 20

                            Row {
                                width: parent.width
                                spacing: 12

                                Text {
                                    text: "󰓃"
                                    font.pixelSize: 20
                                    color: colorText
                                    opacity: 0.8
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Text {
                                    text: "All Output Devices"
                                    font.pixelSize: 18
                                    font.family: "sans-serif"
                                    font.weight: Font.Bold
                                    color: colorText
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            Repeater {
                                model: audioSinksModel

                                Rectangle {
                                    width: parent.width
                                    height: 90
                                    color: colorPrimary
                                    radius: (sharedData && sharedData.quickshellBorderRadius) ? sharedData.quickshellBorderRadius : 0

                                    Column {
                                        anchors.fill: parent
                                        anchors.margins: 18
                                        spacing: 12

                                        Row {
                                            width: parent.width
                                            spacing: 12

                                            Column {
                                                width: parent.width - 140
                                                spacing: 4

                                                Text {
                                                    text: model.description || model.name
                                                    font.pixelSize: 14
                                                    font.family: "sans-serif"
                                                    font.weight: Font.Medium
                                                    color: colorText
                                                    elide: Text.ElideRight
                                                }

                                                Text {
                                                    text: model.name
                                                    font.pixelSize: 11
                                                    font.family: "sans-serif"
                                                    color: colorText
                                                    opacity: 0.6
                                                    elide: Text.ElideRight
                                                }
                                            }

                                            Rectangle {
                                                id: muteButton
                                                width: 45
                                                height: 45
                                                color: muteButton.muteState ? colorAccent : (muteMouseArea.containsMouse ? colorSecondary : colorSecondary)
                                                radius: (sharedData && sharedData.quickshellBorderRadius) ? sharedData.quickshellBorderRadius : 0
                                                anchors.verticalCenter: parent.verticalCenter

                                                property bool muteState: false

                                                Text {
                                                    text: muteButton.muteState ? "󰝟" : "󰓃"
                                                    font.pixelSize: 20
                                                    color: colorText
                                                    anchors.centerIn: parent
                                                }

                                                MouseArea {
                                                    id: muteMouseArea
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        muteButton.muteState = !muteButton.muteState
                                                        setSinkMute(model.index, muteButton.muteState)
                                                    }
                                                }
                                            }
                                        }

                                        Row {
                                            width: parent.width
                                            spacing: 10

                                            Text {
                                                text: "󰕾"
                                                font.pixelSize: 12
                                                color: colorText
                                                opacity: 0.7
                                                anchors.verticalCenter: parent.verticalCenter
                                            }

                                            Rectangle {
                                                width: parent.width - 70
                                                height: 10
                                                color: colorSecondary
                                                radius: (sharedData && sharedData.quickshellBorderRadius) ? sharedData.quickshellBorderRadius : 0
                                                anchors.verticalCenter: parent.verticalCenter

                                                property real volumeValue: 50

                                                Rectangle {
                                                    id: volumeBar
                                                    width: parent.width * (parent.volumeValue / 100)
                                                    height: parent.height
                                                    color: muteButton.muteState ? Qt.darker(colorAccent, 1.3) : colorAccent
                                                    radius: (sharedData && sharedData.quickshellBorderRadius) ? sharedData.quickshellBorderRadius : 0
                                                }

                                                MouseArea {
                                                    anchors.fill: parent
                                                    onClicked: function(mouse) {
                                                        var newValue = (mouse.x / parent.width) * 100
                                                        parent.volumeValue = Math.max(0, Math.min(100, newValue))
                                                        setSinkVolume(model.index, parent.volumeValue)
                                                        if (muteButton.muteState && parent.volumeValue > 0) {
                                                            muteButton.muteState = false
                                                            setSinkMute(model.index, false)
                                                        }
                                                    }
                                                    onPositionChanged: function(mouse) {
                                                        if (pressed) {
                                                            var newValue = (mouse.x / parent.width) * 100
                                                            parent.volumeValue = Math.max(0, Math.min(100, newValue))
                                                            setSinkVolume(model.index, parent.volumeValue)
                                                            if (muteButton.muteState && parent.volumeValue > 0) {
                                                                muteButton.muteState = false
                                                                setSinkMute(model.index, false)
                                                            }
                                                        }
                                                    }
                                                }
                                            }

                                            Text {
                                                text: Math.round(volumeBar.parent.volumeValue) + "%"
                                                font.pixelSize: 12
                                                font.family: "sans-serif"
                                                font.weight: Font.Medium
                                                color: colorText
                                                width: 45
                                                anchors.verticalCenter: parent.verticalCenter
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Separator
                        Rectangle {
                            width: parent.width
                            height: 1
                            color: colorSecondary
                            opacity: 0.5
                        }

                        // Input Devices Section
                        Column {
                            width: parent.width
                            spacing: 20

                            Row {
                                width: parent.width
                                spacing: 12

                                Text {
                                    text: "󰍬"
                                    font.pixelSize: 20
                                    color: colorText
                                    opacity: 0.8
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Text {
                                    text: "All Input Devices"
                                    font.pixelSize: 18
                                    font.family: "sans-serif"
                                    font.weight: Font.Bold
                                    color: colorText
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            Repeater {
                                model: audioSourcesModel

                                Rectangle {
                                    width: parent.width
                                    height: 90
                                    color: colorPrimary
                                    radius: (sharedData && sharedData.quickshellBorderRadius) ? sharedData.quickshellBorderRadius : 0

                                    Column {
                                        anchors.fill: parent
                                        anchors.margins: 18
                                        spacing: 12

                                        Row {
                                            width: parent.width
                                            spacing: 12

                                            Column {
                                                width: parent.width - 140
                                                spacing: 4

                                                Text {
                                                    text: model.description || model.name
                                                    font.pixelSize: 14
                                                    font.family: "sans-serif"
                                                    font.weight: Font.Medium
                                                    color: colorText
                                                    elide: Text.ElideRight
                                                }

                                                Text {
                                                    text: model.name
                                                    font.pixelSize: 11
                                                    font.family: "sans-serif"
                                                    color: colorText
                                                    opacity: 0.6
                                                    elide: Text.ElideRight
                                                }
                                            }

                                            Rectangle {
                                                id: inputMuteButton
                                                width: 45
                                                height: 45
                                                color: inputMuteButton.muteState ? colorAccent : (muteMouseArea.containsMouse ? colorSecondary : colorSecondary)
                                                radius: (sharedData && sharedData.quickshellBorderRadius) ? sharedData.quickshellBorderRadius : 0
                                                anchors.verticalCenter: parent.verticalCenter

                                                property bool muteState: false

                                                Text {
                                                    text: inputMuteButton.muteState ? "󰝟" : "󰍬"
                                                    font.pixelSize: 20
                                                    color: colorText
                                                    anchors.centerIn: parent
                                                }

                                                MouseArea {
                                                    id: muteMouseArea
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        inputMuteButton.muteState = !inputMuteButton.muteState
                                                        setSourceMute(model.index, inputMuteButton.muteState)
                                                    }
                                                }
                                            }
                                        }

                                        Row {
                                            width: parent.width
                                            spacing: 10

                                            Text {
                                                text: "󰕾"
                                                font.pixelSize: 12
                                                color: colorText
                                                opacity: 0.7
                                                anchors.verticalCenter: parent.verticalCenter
                                            }

                                            Rectangle {
                                                width: parent.width - 70
                                                height: 10
                                                color: colorSecondary
                                                radius: (sharedData && sharedData.quickshellBorderRadius) ? sharedData.quickshellBorderRadius : 0
                                                anchors.verticalCenter: parent.verticalCenter

                                                property real volumeValue: 50

                                                Rectangle {
                                                    id: inputVolumeBar
                                                    width: parent.width * (parent.volumeValue / 100)
                                                    height: parent.height
                                                    color: inputMuteButton.muteState ? Qt.darker(colorAccent, 1.3) : colorAccent
                                                    radius: (sharedData && sharedData.quickshellBorderRadius) ? sharedData.quickshellBorderRadius : 0
                                                }

                                                MouseArea {
                                                    anchors.fill: parent
                                                    onClicked: function(mouse) {
                                                        var newValue = (mouse.x / parent.width) * 100
                                                        parent.volumeValue = Math.max(0, Math.min(100, newValue))
                                                        setSourceVolume(model.index, parent.volumeValue)
                                                        if (inputMuteButton.muteState && parent.volumeValue > 0) {
                                                            inputMuteButton.muteState = false
                                                            setSourceMute(model.index, false)
                                                        }
                                                    }
                                                    onPositionChanged: function(mouse) {
                                                        if (pressed) {
                                                            var newValue = (mouse.x / parent.width) * 100
                                                            parent.volumeValue = Math.max(0, Math.min(100, newValue))
                                                            setSourceVolume(model.index, parent.volumeValue)
                                                            if (inputMuteButton.muteState && parent.volumeValue > 0) {
                                                                inputMuteButton.muteState = false
                                                                setSourceMute(model.index, false)
                                                            }
                                                        }
                                                    }
                                                }
                                            }

                                            Text {
                                                text: Math.round(inputVolumeBar.parent.volumeValue) + "%"
                                                font.pixelSize: 12
                                                font.family: "sans-serif"
                                                font.weight: Font.Medium
                                                color: colorText
                                                width: 45
                                                anchors.verticalCenter: parent.verticalCenter
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Component.onCompleted: {
                    loadAudioDevices()
                }

                Connections {
                    target: settingsApplicationRoot
                    function onCurrentTabChanged() {
                        if (currentTab === 5) {
                            loadAudioDevices()
                        }
                    }
                }
            }
        }

        // Keyboard navigation
        Keys.onPressed: function(event) {
            if (event.key === Qt.Key_Escape) {
                if (wallpaperPickerVisible) {
                    // Go back to appearance settings
                    wallpaperPickerVisible = false
                } else if (colorPickerVisible) {
                    // Go back to appearance settings
                    colorPickerVisible = false
                } else {
                    // Close the settings window
                    if (sharedData) {
                        sharedData.settingsVisible = false
                    }
                }
                event.accepted = true
            } else if (wallpaperPickerVisible) {
                // Navigation in wallpaper picker
                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    if (wallpaperSelectedIndex >= 0 && wallpaperSelectedIndex < wallpapersModel.count) {
                        var wallpaper = wallpapersModel.get(wallpaperSelectedIndex)
                        if (wallpaper && wallpaper.path) {
                            setWallpaper(wallpaper.path)
                        }
                    }
                    event.accepted = true
                }
            } else if (colorPickerVisible) {
                // Navigation in color picker - presets are clickable, no special keyboard handling needed
            } else if (event.key === Qt.Key_1 || event.key === Qt.Key_F1) {
                // Switch to General tab
                currentTab = 0
                event.accepted = true
            } else if (event.key === Qt.Key_2 || event.key === Qt.Key_F2) {
                // Switch to Appearance tab
                currentTab = 1
                event.accepted = true
            } else if (event.key === Qt.Key_3 || event.key === Qt.Key_F3) {
                // Switch to Wallpapers tab
                currentTab = 2
                event.accepted = true
            } else if (event.key === Qt.Key_4 || event.key === Qt.Key_F4) {
                // Switch to Bar tab
                currentTab = 3
                event.accepted = true
            } else if (event.key === Qt.Key_5 || event.key === Qt.Key_F5) {
                // Switch to System tab
                currentTab = 4
                event.accepted = true
            } else if (event.key === Qt.Key_6 || event.key === Qt.Key_F6) {
                // Switch to Audio tab
                currentTab = 5
                event.accepted = true
            }
        }
    }
}

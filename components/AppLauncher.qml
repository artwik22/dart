import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

PanelWindow {
    id: appLauncherRoot
    
    property var sharedData: null
    property var screen: null
    
    // Dynamic project path - from environment variable or auto-detected
    property string projectPath: "" // Will be set by Component.onCompleted
    
    function loadProjectPath() {
        // Try to read path from environment variable
        Qt.createQmlObject("import Quickshell.Io; import QtQuick; Process { command: ['sh', '-c', 'echo \"$QUICKSHELL_PROJECT_PATH\" > /tmp/quickshell_project_path 2>/dev/null || echo \"\" > /tmp/quickshell_project_path']; running: true }", appLauncherRoot)
        
        // Wait a moment and read the result
        Qt.createQmlObject("import QtQuick; Timer { interval: 100; running: true; repeat: false; onTriggered: appLauncherRoot.readProjectPath() }", appLauncherRoot)
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
                        Qt.createQmlObject("import Quickshell.Io; import QtQuick; Process { command: ['sh', '-c', 'dirname \"$(readlink -f \"$0\" 2>/dev/null || echo \"$0\")\" 2>/dev/null | head -1 > /tmp/quickshell_script_dir || echo \"\" > /tmp/quickshell_script_dir', '--', '" + Qt.application.arguments.join("' '") + "']; running: true }", appLauncherRoot)
                        Qt.createQmlObject("import QtQuick; Timer { interval: 200; running: true; repeat: false; onTriggered: appLauncherRoot.readScriptDir() }", appLauncherRoot)
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
    
    Component.onCompleted: {
        initializePaths()
        loadProjectPath()
        loadApps()
        detectWallpaperTool()  // Detect available wallpaper tool
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
    
    // Initialize paths from environment
    function initializePaths() {
        // Get home directory from environment
        Qt.createQmlObject("import Quickshell.Io; import QtQuick; Process { command: ['sh', '-c', 'echo \"$HOME\" > /tmp/quickshell_home 2>/dev/null || echo \"\" > /tmp/quickshell_home']; running: true }", appLauncherRoot)
        Qt.createQmlObject("import QtQuick; Timer { interval: 100; running: true; repeat: false; onTriggered: appLauncherRoot.readHomePath() }", appLauncherRoot)
    }

    function loadNotes() {
        var notesPath = colorConfigPath.replace("colors.json", "notes.txt")
        var xhr = new XMLHttpRequest()
        xhr.open("GET", "file://" + notesPath)
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200 || xhr.status === 0) {
                    notesText.text = xhr.responseText
                    console.log("Notes loaded from:", notesPath)
                } else {
                    console.log("Notes file doesn't exist, showing default message")
                    notesText.text = "No notes yet.\n\nClick 'Edit Notes' to add your first note!"
                }
            }
        }
        xhr.send()
    }

    function loadNotesList() {
        // For now, just show placeholder - we'll implement proper directory listing later
        notesModel.clear()
        notesModel.append({ name: "Brak zapisanych notatek", file: "" })

        // Try to find existing note files
        var notesDir = colorConfigPath.replace("colors.json", "")
        var testFiles = ["test.txt", "notatka.txt", "przypomnienie.txt"]

        for (var i = 0; i < testFiles.length; i++) {
            var xhr = new XMLHttpRequest()
            xhr.open("GET", "file://" + notesDir + "/" + testFiles[i])
            xhr.onreadystatechange = (function(file) {
                return function() {
                    if (this.readyState === XMLHttpRequest.DONE && (this.status === 200 || this.status === 0)) {
                        // File exists, add to model
                        if (notesModel.count === 1 && notesModel.get(0).name === "Brak zapisanych notatek") {
                            notesModel.clear()
                        }
                        var fileName = file.replace('.txt', '')
                        notesModel.append({ name: fileName, file: file })
                    }
                }
            })(testFiles[i])
            xhr.send()
        }
    }

    function saveNote() {
        if (notesEditText.text.trim() === "") {
            return
        }

        // Generate filename from first line or current filename
        var fileName
        if (currentNotesMode === 0) {
            // New note - use first line as filename
            var firstLine = notesEditText.text.split('\n')[0].trim()
            if (firstLine === "") {
                firstLine = "Bez tytułu"
            }
            fileName = firstLine.replace(/[^a-zA-Z0-9\-_\s]/g, "").replace(/\s+/g, "_") + ".txt"
        } else {
            // Edit existing note
            fileName = notesFileName
        }

        var notesPath = colorConfigPath.replace("colors.json", fileName)
        var content = notesEditText.text
        var escapedContent = content.replace(/"/g, '\\"').replace(/\$/g, '\\$').replace(/`/g, '\\`')

        Qt.createQmlObject("import Quickshell.Io; import QtQuick; Process { command: ['sh', '-c', 'echo \"" + escapedContent + "\" > \"" + notesPath + "\"']; running: true }", appLauncherRoot)
        console.log("Note saved to:", notesPath)

        // Reload notes list and go back to menu
        loadNotesList()
        currentNotesMode = -1
        selectedIndex = 0
    }

    function loadNoteContent(fileName) {
        var notesPath = colorConfigPath.replace("colors.json", fileName)
        var xhr = new XMLHttpRequest()
        xhr.open("GET", "file://" + notesPath)
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200 || xhr.status === 0) {
                    notesEditText.text = xhr.responseText
                    console.log("Note loaded from:", notesPath)
                } else {
                    notesEditText.text = ""
                }
            }
        }
        xhr.send()
    }

    function readHomePath() {
        var xhr = new XMLHttpRequest()
        xhr.open("GET", "file:///tmp/quickshell_home")
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                var home = xhr.responseText.trim()
                if (home && home.length > 0) {
                    colorConfigPath = home + "/.config/sharpshell/colors.json"
                    wallpapersPath = home + "/Pictures/Wallpapers"
                    console.log("Paths initialized - home:", home, "colorConfig:", colorConfigPath, "wallpapers:", wallpapersPath)
                } else {
                    // Fallback to defaults
                    colorConfigPath = "/tmp/sharpshell/colors.json"
                    wallpapersPath = "/tmp/Pictures/Wallpapers"
                    console.log("Using fallback paths")
                }
                // Load wallpapers immediately after path is initialized
                loadWallpapers()
            }
        }
        xhr.send()
    }
    
    // Color management functions
    function saveColors() {
        // Validate paths before saving
        if (!projectPath || projectPath.length === 0) {
            console.log("Project path not initialized, cannot save colors")
            return
        }
        if (!colorConfigPath || colorConfigPath.length === 0) {
            console.log("Color config path not initialized, cannot save colors")
            return
        }
        // Use Python script to save colors - pass colors as arguments
        var scriptPath = projectPath + "/scripts/save-colors.py"
        var cmd = 'python3 "' + scriptPath + '" "' + colorBackground + '" "' + colorPrimary + '" "' + colorSecondary + '" "' + colorText + '" "' + colorAccent + '" "' + colorConfigPath + '"'
        Qt.createQmlObject("import Quickshell.Io; import QtQuick; Process { command: ['sh', '-c', '" + cmd + "']; running: true }", appLauncherRoot)
        console.log("Saving colors to:", colorConfigPath)
    }
    
    function saveWallpaper(wallpaperPath) {
        // Validate paths before saving
        if (!projectPath || projectPath.length === 0) {
            console.log("Project path not initialized, cannot save wallpaper")
            return
        }
        if (!colorConfigPath || colorConfigPath.length === 0) {
            console.log("Color config path not initialized, cannot save wallpaper")
            return
        }
        if (!wallpaperPath || wallpaperPath.length === 0) {
            console.log("Wallpaper path is empty, cannot save")
            return
        }
        // Use Python script to save wallpaper - pass colors and wallpaper as arguments
        var scriptPath = projectPath + "/scripts/save-colors.py"
        var escapedWallpaper = wallpaperPath.replace(/"/g, '\\"')
        var cmd = 'python3 "' + scriptPath + '" "' + colorBackground + '" "' + colorPrimary + '" "' + colorSecondary + '" "' + colorText + '" "' + colorAccent + '" "' + colorConfigPath + '" "' + escapedWallpaper + '"'
        Qt.createQmlObject("import Quickshell.Io; import QtQuick; Process { command: ['sh', '-c', '" + cmd + "']; running: true }", appLauncherRoot)
        console.log("Saving wallpaper to:", colorConfigPath, "path:", wallpaperPath)
    }
    
    
    function updateColor(colorType, value) {
        console.log("Updating color:", colorType, "to", value)
        var oldValue = ""
        switch(colorType) {
            case "background": 
                oldValue = colorBackground
                colorBackground = value
                if (sharedData) sharedData.colorBackground = value
                console.log("colorBackground changed from", oldValue, "to", colorBackground)
                break
            case "primary": 
                oldValue = colorPrimary
                colorPrimary = value
                if (sharedData) sharedData.colorPrimary = value
                console.log("colorPrimary changed from", oldValue, "to", colorPrimary)
                break
            case "secondary": 
                oldValue = colorSecondary
                colorSecondary = value
                if (sharedData) sharedData.colorSecondary = value
                console.log("colorSecondary changed from", oldValue, "to", colorSecondary)
                break
            case "text": 
                oldValue = colorText
                colorText = value
                if (sharedData) sharedData.colorText = value
                console.log("colorText changed from", oldValue, "to", colorText)
                break
            case "accent": 
                oldValue = colorAccent
                colorAccent = value
                if (sharedData) sharedData.colorAccent = value
                console.log("colorAccent changed from", oldValue, "to", colorAccent)
                break
        }
        saveColors()
        console.log("Colors saved and sharedData updated")
    }
    
    // Color presets
    function applyPreset(presetName) {
        var preset = colorPresets[presetName]
        if (!preset) {
            console.log("Preset not found:", presetName)
            return
        }
        
        // Update all colors at once
        colorBackground = preset.background
        colorPrimary = preset.primary
        colorSecondary = preset.secondary
        colorText = preset.text
        colorAccent = preset.accent
        
        // Update sharedData
        if (sharedData) {
            sharedData.colorBackground = preset.background
            sharedData.colorPrimary = preset.primary
            sharedData.colorSecondary = preset.secondary
            sharedData.colorText = preset.text
            sharedData.colorAccent = preset.accent
        }
        
        // Save to file
        saveColors()
        
        console.log("Applied preset:", presetName)
    }
    
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
            background: "#0d1a0d",
            primary: "#1e3a1e",
            secondary: "#152515",
            text: "#ffffff",
            accent: "#4dd0e1"
        },
        "Plum": {
            background: "#1a0d1a",
            primary: "#2e1a2d",
            secondary: "#231523",
            text: "#ffffff",
            accent: "#9575cd"
        },
        "Gold": {
            background: "#1a150d",
            primary: "#2e251a",
            secondary: "#231f15",
            text: "#ffffff",
            accent: "#ffd54f"
        },
        "Monochrome": {
            background: "#0f0f0f",
            primary: "#1a1a1a",
            secondary: "#141414",
            text: "#ffffff",
            accent: "#3a3a3a"
        },
        "Cherry": {
            background: "#1a0a0a",
            primary: "#2e1a1a",
            secondary: "#231515",
            text: "#ffffff",
            accent: "#ec407a"
        },
        "Azure": {
            background: "#0d1a26",
            primary: "#1e2d3f",
            secondary: "#152535",
            text: "#ffffff",
            accent: "#29b6f6"
        },
        "Jade": {
            background: "#0d1a0d",
            primary: "#1e3a1e",
            secondary: "#152515",
            text: "#ffffff",
            accent: "#26c6da"
        },
        "Ruby": {
            background: "#1a0a0a",
            primary: "#2e1a1a",
            secondary: "#231515",
            text: "#ffffff",
            accent: "#d32f2f"
        },
        "Indigo": {
            background: "#0d0d1a",
            primary: "#1e1f2d",
            secondary: "#151a23",
            text: "#ffffff",
            accent: "#7986cb"
        }
    }
    
    function isValidHexColor(hex) {
        // Allow with or without #
        var normalized = hex.trim()
        if (!normalized.startsWith('#')) {
            normalized = '#' + normalized
        }
        return /^#[0-9A-Fa-f]{6}$/.test(normalized)
    }
    
    function normalizeHexColor(hex) {
        var normalized = hex.trim().toUpperCase()
        if (!normalized.startsWith('#')) {
            normalized = '#' + normalized
        }
        return normalized
    }
    
    anchors { 
        bottom: true
    }
    
    // Base size
    property int baseWidth: 540
    property int baseHeight: 315  // 70% of 450 (30% shorter)
    
    // Size when in wallpaper mode (30% larger)
    property bool isWallpaperMode: (currentMode === 2 && currentSettingsMode === 0)
    property int wallpaperWidth: Math.floor(baseWidth * 1.3)  // 30% wider
    property int wallpaperHeight: Math.floor(baseHeight * 1.3)  // 30% taller
    
    // Size when in presets mode (40% wider, 30% taller)
    property bool isPresetsMode: (currentMode === 2 && currentSettingsMode === 4)
    property int presetsWidth: Math.floor(baseWidth * 1.4)  // 40% wider
    property int presetsHeight: Math.floor(baseHeight * 1.3)  // 30% taller
    
    implicitWidth: isPresetsMode ? presetsWidth : (isWallpaperMode ? wallpaperWidth : baseWidth)
    implicitHeight: isPresetsMode ? presetsHeight : (isWallpaperMode ? wallpaperHeight : baseHeight)
    width: implicitWidth
    height: implicitHeight
    
    Behavior on implicitWidth {
        NumberAnimation {
            duration: 280
            easing.type: Easing.OutQuart
        }
    }
    
    Behavior on implicitHeight {
        NumberAnimation {
            duration: 280
            easing.type: Easing.OutQuart
        }
    }
    
    // Centering - use margins instead of horizontalCenter (dynamic based on current width)
    margins {
        left: screen ? (screen.width - width) / 2 : 0
        right: screen ? (screen.width - width) / 2 : 0
    }
    
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qslauncher"
    WlrLayershell.keyboardFocus: (sharedData && sharedData.launcherVisible) ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    exclusiveZone: 0
    
    // Visibility control - always visible, controlled by slideOffset
    visible: true
    color: "transparent"  // Transparent, background will be in container with gradient
    
    // Slide up animation from bottom - negative value moves down (off screen)
    property int slideOffset: (sharedData && sharedData.launcherVisible) ? 0 : -500
    
    margins.bottom: slideOffset
    
    Behavior on slideOffset {
        NumberAnimation { 
            duration: 280
            easing.type: Easing.OutQuart
        }
    }
    
    // Applications list
    property var apps: []
    property int selectedIndex: 0
    property string searchText: ""
    
    // Calculator properties
    property string calculatorResult: ""
    property bool isCalculatorMode: false
    property int currentMode: -1  // -1 = mode selection, 0 = Launcher, 1 = Packages, 2 = Settings, 3 = Notes
    property int currentNotesMode: -1  // -1 = menu, 0 = new note, 1 = edit note
    property string notesFileName: ""  // Current note file name
    property int currentPackageMode: -1  // -1 = Packages option selection, 0 = install source selection (Pacman/AUR), 1 = Pacman search, 2 = AUR search, 3 = remove source selection (Pacman/AUR), 4 = Pacman remove search, 5 = AUR remove search
    property int installSourceMode: -1  // -1 = selection, 0 = Pacman, 1 = AUR
    property int removeSourceMode: -1  // -1 = selection, 0 = Pacman, 1 = AUR
    property int currentSettingsMode: -1  // -1 = settings list, 0 = Wallpaper, 3 = Colors menu, 4 = Presets, 5 = Custom HEX
    
    // Color theme properties
    property string colorBackground: "#0a0a0a"
    property string colorPrimary: "#1a1a1a"
    property string colorSecondary: "#141414"
    property string colorText: "#ffffff"
    property string colorAccent: "#4a9eff"
    
    // Color config file path - dynamically determined
    property string colorConfigPath: ""
    property int wallpaperSelectedIndex: 0  // Indeks wybranej tapety w GridView
    property var packages: []
    property string packageSearchText: ""
    property var wallpapers: []
    // Wallpapers path - dynamically determined
    property string wallpapersPath: ""
    
    // Filtered applications list
    ListModel {
        id: filteredApps
    }
    
    // Filtered packages list
    ListModel {
        id: filteredPackages
    }
    
    // Installed packages list
    property var installedPackages: []
    
    // Filtered installed packages list
    ListModel {
        id: filteredInstalledPackages
    }
    
    // Wallpapers list
    ListModel {
        id: wallpapersModel
    }
    
    // Function to load wallpapers
    function loadWallpapers() {
        if (!wallpapersPath || wallpapersPath.length === 0) {
            console.log("Wallpapers path not initialized, waiting...")
            // Retry after a short delay
            Qt.createQmlObject("import QtQuick; Timer { interval: 500; running: true; repeat: false; onTriggered: appLauncherRoot.loadWallpapers() }", appLauncherRoot)
            return
        }
        wallpapersModel.clear()
        Qt.createQmlObject('import Quickshell.Io; import QtQuick; Process { command: ["sh", "-c", "find ' + wallpapersPath + ' -maxdepth 1 -type f \\\\( -iname \\"*.jpg\\" -o -iname \\"*.jpeg\\" -o -iname \\"*.png\\" -o -iname \\"*.webp\\" -o -iname \\"*.gif\\" \\\\) 2>/dev/null | sort > /tmp/quickshell_wallpapers"]; running: true }', appLauncherRoot)
        Qt.createQmlObject("import QtQuick; Timer { interval: 300; running: true; repeat: false; onTriggered: appLauncherRoot.readWallpapersList() }", appLauncherRoot)
    }
    
    function readWallpapersList() {
        var xhr = new XMLHttpRequest()
        xhr.open("GET", "file:///tmp/quickshell_wallpapers")
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                wallpapersModel.clear()
                var content = xhr.responseText || ""
                var lines = content.trim().split("\n")
                for (var i = 0; i < lines.length; i++) {
                    var path = lines[i].trim()
                    if (path.length > 0) {
                        var filename = path.split("/").pop()
                        wallpapersModel.append({ path: path, filename: filename })
                    }
                }
                console.log("Loaded", wallpapersModel.count, "wallpapers")
            }
        }
        xhr.send()
    }
    
    // Wallpaper tool detection
    property string wallpaperTool: ""  // Will be detected: "swww", "wbg", "hyprpaper", or ""
    
    function detectWallpaperTool() {
        // Check which wallpaper tool is available
        Qt.createQmlObject('import Quickshell.Io; import QtQuick; Process { command: ["sh", "-c", "which swww > /dev/null 2>&1 && echo swww > /tmp/quickshell_wallpaper_tool || which wbg > /dev/null 2>&1 && echo wbg > /tmp/quickshell_wallpaper_tool || which hyprpaper > /dev/null 2>&1 && echo hyprpaper > /tmp/quickshell_wallpaper_tool || echo none > /tmp/quickshell_wallpaper_tool"]; running: true }', appLauncherRoot)
        Qt.createQmlObject("import QtQuick; Timer { interval: 200; running: true; repeat: false; onTriggered: appLauncherRoot.readWallpaperTool() }", appLauncherRoot)
    }
    
    function readWallpaperTool() {
        var xhr = new XMLHttpRequest()
        xhr.open("GET", "file:///tmp/quickshell_wallpaper_tool")
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                var tool = xhr.responseText.trim()
                wallpaperTool = tool
                console.log("Detected wallpaper tool:", wallpaperTool)
            }
        }
        xhr.send()
    }
    
    function setWallpaper(wallpaperPath) {
        console.log("Setting wallpaper via Quickshell:", wallpaperPath)
        
        // Save wallpaper path to colors.json for persistence
        saveWallpaper(wallpaperPath)
        
        // Use Quickshell's built-in wallpaper system (like Caelestia Shell)
        // Set wallpaper directly in sharedData or root component
        if (sharedData) {
            // Try to find the root ShellRoot component to set wallpaper
            var rootComponent = appLauncherRoot.parent
            while (rootComponent && rootComponent.objectName !== "shellRoot") {
                rootComponent = rootComponent.parent
            }
            
            // If we can't find root, try to set it via sharedData property
            // We'll use a different approach - set it in the shell.qml root
            // For now, we'll use a file-based approach to communicate with shell.qml
            var escapedPath = wallpaperPath.replace(/"/g, '\\"')
            Qt.createQmlObject('import Quickshell.Io; import QtQuick; Process { command: ["sh", "-c", "echo \\"' + escapedPath + '\\" > /tmp/quickshell_wallpaper_path"]; running: true }', appLauncherRoot)
            
            // Also try to set it directly if we have access to parent
            if (rootComponent && rootComponent.currentWallpaperPath !== undefined) {
                rootComponent.currentWallpaperPath = wallpaperPath
            }
        }
        
        // Fallback: use external tools if Quickshell method doesn't work
        var escapedPath = wallpaperPath.replace(/'/g, "\\'").replace(/"/g, '\\"')
        
        if (wallpaperTool === "swww") {
            // Use swww with fade transition
            Qt.createQmlObject('import Quickshell.Io; import QtQuick; Process { command: ["swww", "img", "' + escapedPath + '", "--transition-type", "fade", "--transition-duration", "1"]; running: true }', appLauncherRoot)
        } else if (wallpaperTool === "wbg") {
            // Use wbg (simpler, no transitions)
            Qt.createQmlObject('import Quickshell.Io; import QtQuick; Process { command: ["wbg", "' + escapedPath + '"]; running: true }', appLauncherRoot)
        } else if (wallpaperTool === "hyprpaper") {
            // Use hyprpaper (Hyprland-specific)
            // Get monitor name from hyprctl and set wallpaper
            Qt.createQmlObject('import Quickshell.Io; import QtQuick; Process { command: ["sh", "-c", "MONITOR=$(hyprctl monitors -j | jq -r \\"[0].name\\" 2>/dev/null || echo \\"eDP-1\\"); hyprctl hyprpaper preload \\"' + escapedPath + '\\" && hyprctl hyprpaper wallpaper \\"$MONITOR,\\"' + escapedPath + '\\"\\""]; running: true }', appLauncherRoot)
        }
    }
    
    function updateSystem() {
        var scriptPath = projectPath + "/scripts/update-system.sh"
        // Open kitty, set as floating, size 1200x700 and center
        var command = "hyprctl dispatch exec \"kitty --class=floating_kitty -e bash " + scriptPath + "\"; sleep 0.3; hyprctl dispatch focuswindow \"class:floating_kitty\"; hyprctl dispatch togglefloating; hyprctl dispatch resizeactive exact 1200 700; hyprctl dispatch centerwindow"
        
        console.log("Executing update command:", command)
        Qt.createQmlObject("import Quickshell.Io; import QtQuick; Process { command: ['sh', '-c', '" + command.replace(/'/g, "\\'") + "']; running: true }", appLauncherRoot)
        
        // Close launcher after execution
        if (sharedData) {
            sharedData.launcherVisible = false
        }
    }
    
    // Bluetooth properties
    property bool bluetoothEnabled: false
    property bool bluetoothScanning: false
    property bool bluetoothConnecting: false
    property int bluetoothSelectedIndex: 0
    
    // Bluetooth devices list
    ListModel {
        id: bluetoothDevicesModel
    }
    
    // Bluetooth functions
    function checkBluetoothStatus() {
        Qt.createQmlObject("import Quickshell.Io; import QtQuick; Process { command: ['sh', '-c', '/usr/bin/bluetoothctl show | grep -q \\\"Powered: yes\\\" && echo 1 > /tmp/quickshell_bt_status || echo 0 > /tmp/quickshell_bt_status']; running: true }", appLauncherRoot)
        Qt.createQmlObject("import QtQuick; Timer { interval: 300; running: true; repeat: false; onTriggered: appLauncherRoot.readBluetoothStatus() }", appLauncherRoot)
    }
    
    function readBluetoothStatus() {
        var xhr = new XMLHttpRequest()
        xhr.open("GET", "file:///tmp/quickshell_bt_status")
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                bluetoothEnabled = xhr.responseText.trim() === "1"
                if (bluetoothEnabled) {
                    scanBluetoothDevices()
                } else {
                    bluetoothDevicesModel.clear()
                }
            }
        }
        xhr.send()
    }
    
    function toggleBluetooth() {
        console.log("Toggling Bluetooth, current state:", bluetoothEnabled)
        if (bluetoothEnabled) {
            console.log("Turning Bluetooth OFF")
            // Block with rfkill and turn off
            Qt.createQmlObject("import Quickshell.Io; import QtQuick; Process { command: ['sh', '-c', 'rfkill block bluetooth; /usr/bin/bluetoothctl power off']; running: true }", appLauncherRoot)
        } else {
            console.log("Turning Bluetooth ON")
            // Unblock with rfkill, wait, then turn on
            Qt.createQmlObject("import Quickshell.Io; import QtQuick; Process { command: ['sh', '-c', 'rfkill unblock bluetooth; sleep 1; /usr/bin/bluetoothctl power on']; running: true }", appLauncherRoot)
        }
        Qt.createQmlObject("import QtQuick; Timer { interval: 1500; running: true; repeat: false; onTriggered: appLauncherRoot.checkBluetoothStatus() }", appLauncherRoot)
    }
    
    function scanBluetoothDevices() {
        if (!bluetoothEnabled || bluetoothScanning) return
        bluetoothScanning = true
        bluetoothDevicesModel.clear()
        console.log("Starting Bluetooth scan...")
        
        // Use bluetoothctl with timeout - this will scan for 10 seconds and then automatically stop
        Qt.createQmlObject("import Quickshell.Io; import QtQuick; Process { command: ['sh', '-c', 'bluetoothctl --timeout 10 scan on > /tmp/quickshell_bt_scan_output 2>&1']; running: true }", appLauncherRoot)
        
        // Wait for scan to complete and get devices
        Qt.createQmlObject("import QtQuick; Timer { interval: 12000; running: true; repeat: false; onTriggered: appLauncherRoot.getBluetoothDevices() }", appLauncherRoot)
    }
    
    function getBluetoothDevices() {
        console.log("Getting Bluetooth devices...")
        Qt.createQmlObject("import Quickshell.Io; import QtQuick; Process { command: ['sh', '-c', 'bluetoothctl devices > /tmp/quickshell_bt_devices']; running: true }", appLauncherRoot)
        Qt.createQmlObject("import QtQuick; Timer { interval: 500; running: true; repeat: false; onTriggered: appLauncherRoot.readBluetoothDevices() }", appLauncherRoot)
    }
    
    function readBluetoothDevices() {
        var xhr = new XMLHttpRequest()
        xhr.open("GET", "file:///tmp/quickshell_bt_devices")
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                bluetoothDevicesModel.clear()
                var content = xhr.responseText || ""
                console.log("Bluetooth devices file content:", content)
                console.log("Content length:", content.length)
                var lines = content.trim().split("\n")
                console.log("Found", lines.length, "lines")
                for (var i = 0; i < lines.length; i++) {
                    var line = lines[i].trim()
                    console.log("Processing line", i, ":", line)
                    if (line.length > 0) {
                        if (line.startsWith("Device")) {
                            // Format: "Device MAC_ADDRESS Device_Name"
                            var parts = line.split(" ")
                            console.log("Line parts:", parts.length, parts)
                            if (parts.length >= 3) {
                                var mac = parts[1]
                                var name = parts.slice(2).join(" ") || "Unknown Device"
                                console.log("Adding device - Name:", name, "MAC:", mac)
                                bluetoothDevicesModel.append({ mac: mac, name: name, connected: false })
                            } else {
                                console.log("Line has less than 3 parts, skipping")
                            }
                        } else {
                            console.log("Line doesn't start with 'Device', skipping")
                        }
                    }
                }
                console.log("Total devices found:", bluetoothDevicesModel.count)
                bluetoothScanning = false
            }
        }
        xhr.send()
    }
    
    function connectBluetoothDevice(mac) {
        console.log("=== connectBluetoothDevice called ===")
        console.log("MAC received:", mac, "type:", typeof mac)
        if (bluetoothConnecting) {
            console.log("Already connecting, skipping")
            return
        }
        bluetoothConnecting = true
        var macStr = String(mac).trim()
        console.log("Pairing and connecting to device MAC:", macStr)
        
        // First pair, then connect
        // Step 1: Pair the device
        console.log("Step 1: Pairing device...")
        Qt.createQmlObject("import Quickshell.Io; import QtQuick; Process { command: ['/usr/bin/bluetoothctl', 'pair', '" + macStr + "']; running: true }", appLauncherRoot)
        
        // Step 2: Wait a bit, then connect
        Qt.createQmlObject("import QtQuick; Timer { interval: 3000; running: true; repeat: false; onTriggered: { console.log('Step 2: Connecting device...'); appLauncherRoot.connectAfterPair('" + macStr + "') } }", appLauncherRoot)
        
        Qt.createQmlObject("import QtQuick; Timer { interval: 8000; running: true; repeat: false; onTriggered: { console.log('Resetting bluetoothConnecting flag'); appLauncherRoot.bluetoothConnecting = false } }", appLauncherRoot)
        Qt.createQmlObject("import QtQuick; Timer { interval: 8500; running: true; repeat: false; onTriggered: { console.log('Refreshing device list'); appLauncherRoot.getBluetoothDevices() } }", appLauncherRoot)
    }
    
    function connectAfterPair(mac) {
        console.log("Connecting to paired device:", mac)
        Qt.createQmlObject("import Quickshell.Io; import QtQuick; Process { command: ['/usr/bin/bluetoothctl', 'connect', '" + mac + "']; running: true }", appLauncherRoot)
    }
    
    function disconnectBluetoothDevice(mac) {
        var escapedMac = mac.replace(/'/g, "\\'")
        Qt.createQmlObject("import Quickshell.Io; import QtQuick; Process { command: ['sh', '-c', 'bluetoothctl disconnect \\\"" + escapedMac + "\\\"']; running: true }", appLauncherRoot)
        Qt.createQmlObject("import QtQuick; Timer { interval: 1000; running: true; repeat: false; onTriggered: appLauncherRoot.getBluetoothDevices() }", appLauncherRoot)
    }
    
    // Function to filter applications
    function filterApps() {
        filteredApps.clear()
        var search = (searchText || "").trim()
        var searchLower = search.toLowerCase()
        
        // Check if it's calculator mode (starts with "=" or looks like math expression)
        if (search.startsWith("=") || (search.length > 0 && /^[\d+\-*/().\sπe]+$/.test(search.replace(/sqrt|sin|cos|tan|log|ln|pow/gi, "").replace(/\s+/g, "")))) {
            var result = calculateExpression(search)
            if (result && result !== "Error") {
                isCalculatorMode = true
                calculatorResult = result
                // Add calculator result as a "fake" app
                filteredApps.append({
                    name: "= " + result,
                    comment: "Calculator result - Press Enter to copy",
                    exec: "",
                    icon: "󰃀",
                    isCalculator: true
                })
                selectedIndex = 0
                return
            }
        }
        
        isCalculatorMode = false
        calculatorResult = ""
        
        // Check if search starts with ! prefix for web search
        if (search.startsWith("!")) {
            var serviceName = "DuckDuckGo"
            if (search.startsWith("!w ")) {
                serviceName = "Wikipedia"
            } else if (search.startsWith("!w")) {
                serviceName = "Wikipedia"
            } else if (search.startsWith("!r ")) {
                serviceName = "Reddit"
            } else if (search.startsWith("!r")) {
                serviceName = "Reddit"
            } else if (search.startsWith("!y ")) {
                serviceName = "YouTube"
            } else if (search.startsWith("!y")) {
                serviceName = "YouTube"
            }
            
            filteredApps.append({
                name: "Search in " + serviceName,
                comment: "Press Enter to search",
                exec: "",
                icon: "󰖟",
                isCalculator: false
            })
            selectedIndex = 0
            return
        }
        
        // If there are no applications, do nothing
        if (apps.length === 0) {
            return
        }
        
        for (var i = 0; i < apps.length; i++) {
            var app = apps[i]
            if (!app || !app.name || app.name === "") continue
            
            var name = (app.name || "").toLowerCase()
            var comment = (app.comment || "").toLowerCase()
            
            // If search is empty, show all applications
            // Otherwise, filter by name or comment
            if (searchLower === "" || name.indexOf(searchLower) >= 0 || comment.indexOf(searchLower) >= 0) {
                filteredApps.append({
                    name: app.name,
                    comment: app.comment || "",
                    exec: app.exec || "",
                    icon: app.icon || "",
                    isCalculator: false
                })
            }
        }
        
        // Reset selectedIndex if out of range
        if (selectedIndex >= filteredApps.count) {
            selectedIndex = Math.max(0, filteredApps.count - 1)
        }
        if (selectedIndex < 0 && filteredApps.count > 0) {
            selectedIndex = 0
        }
    }
    
    // Function to calculate mathematical expression
    function calculateExpression(expression) {
        try {
            // Remove the "=" prefix if present
            var expr = expression.startsWith("=") ? expression.substring(1).trim() : expression.trim()
            if (expr.length === 0) return null
            
            // Replace common math functions and constants
            expr = expr.replace(/π/g, "Math.PI")
            expr = expr.replace(/pi/gi, "Math.PI")
            expr = expr.replace(/e\b/g, "Math.E")
            expr = expr.replace(/sqrt\(/g, "Math.sqrt(")
            expr = expr.replace(/sin\(/g, "Math.sin(")
            expr = expr.replace(/cos\(/g, "Math.cos(")
            expr = expr.replace(/tan\(/g, "Math.tan(")
            expr = expr.replace(/log\(/g, "Math.log(")
            expr = expr.replace(/ln\(/g, "Math.log(")
            expr = expr.replace(/pow\(/g, "Math.pow(")
            expr = expr.replace(/\^/g, "**")  // Power operator
            
            // Evaluate the expression safely
            var result = eval(expr)
            
            // Format result
            if (typeof result === "number") {
                // Round to reasonable precision
                if (result % 1 === 0) {
                    return result.toString()
                } else {
                    // Round to 10 decimal places max
                    return parseFloat(result.toFixed(10)).toString()
                }
            }
            return result.toString()
        } catch(e) {
            return "Error"
        }
    }
    
    // Function to search in Firefox with different services
    function searchInFirefox(query) {
        if (query && query.length > 0) {
            var trimmedQuery = query.trim()
            var searchQuery = ""
            var searchUrl = ""
            
            // Check for service prefixes
            if (trimmedQuery.startsWith("!w ")) {
                // Wikipedia search
                searchQuery = trimmedQuery.substring(3).trim()
                if (searchQuery.length > 0) {
                    var encodedQuery = encodeURIComponent(searchQuery)
                    searchUrl = "https://en.wikipedia.org/wiki/Special:Search?search=" + encodedQuery
                }
            } else if (trimmedQuery.startsWith("!w")) {
                // Wikipedia search (no space after !w)
                searchQuery = trimmedQuery.substring(2).trim()
                if (searchQuery.length > 0) {
                    var encodedQuery = encodeURIComponent(searchQuery)
                    searchUrl = "https://en.wikipedia.org/wiki/Special:Search?search=" + encodedQuery
                }
            } else if (trimmedQuery.startsWith("!r ")) {
                // Reddit search
                searchQuery = trimmedQuery.substring(3).trim()
                if (searchQuery.length > 0) {
                    var encodedQuery = encodeURIComponent(searchQuery)
                    searchUrl = "https://www.reddit.com/search/?q=" + encodedQuery
                }
            } else if (trimmedQuery.startsWith("!r")) {
                // Reddit search (no space after !r)
                searchQuery = trimmedQuery.substring(2).trim()
                if (searchQuery.length > 0) {
                    var encodedQuery = encodeURIComponent(searchQuery)
                    searchUrl = "https://www.reddit.com/search/?q=" + encodedQuery
                }
            } else if (trimmedQuery.startsWith("!y ")) {
                // YouTube search
                searchQuery = trimmedQuery.substring(3).trim()
                if (searchQuery.length > 0) {
                    var encodedQuery = encodeURIComponent(searchQuery)
                    searchUrl = "https://www.youtube.com/results?search_query=" + encodedQuery
                }
            } else if (trimmedQuery.startsWith("!y")) {
                // YouTube search (no space after !y)
                searchQuery = trimmedQuery.substring(2).trim()
                if (searchQuery.length > 0) {
                    var encodedQuery = encodeURIComponent(searchQuery)
                    searchUrl = "https://www.youtube.com/results?search_query=" + encodedQuery
                }
            } else if (trimmedQuery.startsWith("!")) {
                // DuckDuckGo search (default)
                searchQuery = trimmedQuery.substring(1).trim()
                if (searchQuery.length > 0) {
                    var encodedQuery = encodeURIComponent(searchQuery)
                    searchUrl = "https://duckduckgo.com/?q=" + encodedQuery
                }
            } else {
                // No prefix, use DuckDuckGo
                searchQuery = trimmedQuery
                if (searchQuery.length > 0) {
                    var encodedQuery = encodeURIComponent(searchQuery)
                    searchUrl = "https://duckduckgo.com/?q=" + encodedQuery
                }
            }
            
            if (searchUrl && searchUrl.length > 0) {
                // Launch Firefox with the search URL
                var command = "firefox \"" + searchUrl + "\" &"
                Qt.createQmlObject("import Quickshell.Io; import QtQuick; Process { command: ['sh', '-c', '" + command.replace(/'/g, "\\'") + "']; running: true }", appLauncherRoot)
                
                if (sharedData) {
                    sharedData.launcherVisible = false
                }
            }
        }
    }
    
    // Function to launch application
    function launchApp(app) {
        if (app.exec) {
            // Remove Desktop Entry field codes (%u, %f, %F, %U, %d, %D, %n, %N, %i, %c, %k, %v, %m)
            // Also handle escaped %% which should become %
            var exec = app.exec
            // First, replace %% with a placeholder
            exec = exec.replace(/%%/g, "___PERCENT_PLACEHOLDER___")
            // Remove all field codes (single letter after %)
            exec = exec.replace(/%[a-zA-Z]/g, "")
            // Restore %% as %
            exec = exec.replace(/___PERCENT_PLACEHOLDER___/g, "%")
            // Remove multiple spaces and trim
            exec = exec.replace(/\s+/g, " ").trim()
            
            // Run via sh -c for better compatibility
            Qt.createQmlObject("import Quickshell.Io; import QtQuick; Process { command: ['sh', '-c', '" + exec.replace(/'/g, "\\'") + " &']; running: true }", appLauncherRoot)
            
            if (sharedData) {
                sharedData.launcherVisible = false
            }
        }
    }
    
    // Function to load applications
    function loadApps() {
        apps = []
        filteredApps.clear()
        loadedAppsCount = 0
        totalFilesToLoad = 0
        
        // Load applications from .desktop files (more applications)
        Qt.createQmlObject("import Quickshell.Io; import QtQuick; Process { command: ['sh', '-c', 'find /usr/share/applications ~/.local/share/applications -name \"*.desktop\" 2>/dev/null | head -100 > /tmp/quickshell_apps_list']; running: true }", appLauncherRoot)
        
        // After a moment, read the list and load applications
        Qt.createQmlObject("import QtQuick; Timer { interval: 300; running: true; repeat: false; onTriggered: appLauncherRoot.readAppsList() }", appLauncherRoot)
    }
    
    function readAppsList() {
        var xhr = new XMLHttpRequest()
        xhr.open("GET", "file:///tmp/quickshell_apps_list")
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                var files = xhr.responseText.trim().split("\n").filter(function(f) { return f.trim().length > 0 })
                var totalFiles = Math.min(files.length, 80)
                
                // Reset counters
                loadedAppsCount = 0
                totalFilesToLoad = totalFiles
                
                for (var i = 0; i < totalFiles; i++) {
                    var file = files[i].trim()
                    if (file) {
                        readDesktopFile(file, i, totalFiles)
                    } else {
                        // If file is empty, increment counter
                        loadedAppsCount++
                    }
                }
                
                // If there are no files, call filterApps
                if (totalFiles === 0) {
                    filterApps()
                }
            }
        }
        xhr.send()
    }
    
    // Counter for loaded applications
    property int loadedAppsCount: 0
    property int totalFilesToLoad: 0
    
    function readDesktopFile(filePath, index, total) {
        totalFilesToLoad = total
        var xhr = new XMLHttpRequest()
        xhr.open("GET", "file://" + filePath)
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                // Check response status
                if (xhr.status !== 200 && xhr.status !== 0) {
                    loadedAppsCount++
                    checkIfAllLoaded()
                    return
                }
                
                var content = xhr.responseText
                if (!content || content.trim() === "") {
                    loadedAppsCount++
                    checkIfAllLoaded()
                    return
                }
                
                var lines = content.split("\n")
                
                var app = {
                    name: "",
                    comment: "",
                    exec: "",
                    icon: "",
                    type: "Application"  // Default Application
                }
                
                var inDesktopEntry = false
                var isNoDisplay = false
                
                for (var i = 0; i < lines.length; i++) {
                    var line = lines[i].trim()
                    if (line.startsWith("[Desktop Entry]")) {
                        inDesktopEntry = true
                        continue
                    } else if (line.startsWith("[") && inDesktopEntry) {
                        break
                    } else if (inDesktopEntry && line.indexOf("=") > 0 && !line.startsWith("#")) {
                        var equalIndex = line.indexOf("=")
                        var key = line.substring(0, equalIndex).trim()
                        var value = line.substring(equalIndex + 1).trim()
                        
                        if (key === "Name" && !app.name) {
                            app.name = value
                        } else if (key === "Comment" && !app.comment) {
                            app.comment = value
                        } else if (key === "Exec" && !app.exec) {
                            app.exec = value
                        } else if (key === "Icon" && !app.icon) {
                            app.icon = value
                        } else if (key === "Type") {
                            app.type = value
                        } else if (key === "NoDisplay" && value === "true") {
                            isNoDisplay = true
                        }
                    }
                }
                
                // Filter only applications (not directories, not NoDisplay)
                // Check if it has Name and Exec (required fields)
                if (app.name && app.name.length > 0 && app.exec && app.exec.length > 0 && app.type !== "Directory" && !isNoDisplay) {
                    apps.push({
                        name: app.name,
                        comment: app.comment || "",
                        exec: app.exec,
                        icon: app.icon || ""
                    })
                }
                
                loadedAppsCount++
                checkIfAllLoaded()
            }
        }
        xhr.send()
    }
    
    function checkIfAllLoaded() {
        if (loadedAppsCount >= totalFilesToLoad && totalFilesToLoad > 0) {
            // All files loaded, call filterApps
            // Wait a moment so all applications are in the array
            Qt.createQmlObject("import QtQuick; Timer { interval: 500; running: true; repeat: false; onTriggered: appLauncherRoot.filterApps() }", appLauncherRoot)
        }
    }
    
    // Function to search packages in pacman
    function searchPacmanPackages(query) {
        if (!query || query.length < 2) {
            filteredPackages.clear()
            return
        }
        
        console.log("Searching for packages:", query)
        
        // Run search in background
        Qt.createQmlObject("import Quickshell.Io; import QtQuick; Process { command: ['sh', '-c', 'pacman -Ss \"" + query.replace(/"/g, '\\"') + "\" 2>/dev/null | head -50 > /tmp/quickshell_pacman_search']; running: true }", appLauncherRoot)
        
        // Wait a moment and read results (use Timer instead of onFinished)
        Qt.createQmlObject("import QtQuick; Timer { interval: 500; running: true; repeat: false; onTriggered: appLauncherRoot.readPacmanSearchResults() }", appLauncherRoot)
    }
    
    // Function to read pacman search results
    function readPacmanSearchResults() {
        console.log("Reading pacman search results...")
        var xhr = new XMLHttpRequest()
        xhr.open("GET", "file:///tmp/quickshell_pacman_search")
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                filteredPackages.clear()
                var output = xhr.responseText.trim()
                console.log("Search output length:", output.length)
                
                if (!output || output.length === 0) {
                    console.log("No search results found")
                    return
                }
                
                var lines = output.split("\n")
                var currentPackage = null
                
                for (var i = 0; i < lines.length; i++) {
                    var line = lines[i]
                    var trimmedLine = line.trim()
                    
                    if (trimmedLine.length === 0) continue
                    
                    // Line with package name (e.g. "extra/firefox 131.0-1" or "world/htop 3.4.1-1")
                    // Format: repo/name version
                    // Check if line contains "/" and has format repo/name version (doesn't start with space)
                    if (trimmedLine.indexOf("/") > 0 && !line.startsWith(" ") && !line.startsWith("\t")) {
                        var parts = trimmedLine.split(" ")
                        if (parts.length >= 2) {
                            var repoAndName = parts[0].split("/")
                            if (repoAndName.length === 2 && repoAndName[0].length > 0 && repoAndName[1].length > 0) {
                                // Save previous package if exists
                                if (currentPackage) {
                                    filteredPackages.append(currentPackage)
                                }
                                
                                // Parse new package
                                currentPackage = {
                                    name: repoAndName[1],
                                    version: parts[1],
                                    description: ""
                                }
                                console.log("Found package:", currentPackage.name, "from repo:", repoAndName[0])
                            }
                        }
                    } else if (currentPackage && (line.startsWith("    ") || line.startsWith("\t"))) {
                        // Line with description (starts with space or tab)
                        var desc = trimmedLine
                        if (desc.length > 0) {
                            currentPackage.description = desc
                        }
                    }
                }
                
                // Add last package
                if (currentPackage) {
                    filteredPackages.append(currentPackage)
                }
                
                console.log("Total packages found:", filteredPackages.count)
                
                // Reset selectedIndex if out of range
                if (selectedIndex >= filteredPackages.count) {
                    selectedIndex = Math.max(0, filteredPackages.count - 1)
                }
                if (selectedIndex < 0 && filteredPackages.count > 0) {
                    selectedIndex = 0
                }
            }
        }
        xhr.send()
    }
    
    // Function to search packages in AUR
    function searchAurPackages(query) {
        if (!query || query.length < 2) {
            filteredPackages.clear()
            return
        }
        
        console.log("Searching AUR for packages:", query)
        
        // Check if yay or paru is available
        // Run search in background (use yay if available, otherwise paru)
        Qt.createQmlObject("import Quickshell.Io; import QtQuick; Process { command: ['sh', '-c', 'if command -v yay >/dev/null 2>&1; then yay -Ss \"" + query.replace(/"/g, '\\"') + "\" 2>/dev/null | head -50 > /tmp/quickshell_aur_search; elif command -v paru >/dev/null 2>&1; then paru -Ss \"" + query.replace(/"/g, '\\"') + "\" 2>/dev/null | head -50 > /tmp/quickshell_aur_search; else echo \"AUR helper not found\" > /tmp/quickshell_aur_search; fi']; running: true }", appLauncherRoot)
        
        // Wait a moment and read results
        Qt.createQmlObject("import QtQuick; Timer { interval: 800; running: true; repeat: false; onTriggered: appLauncherRoot.readAurSearchResults() }", appLauncherRoot)
    }
    
    // Function to read AUR search results
    function readAurSearchResults() {
        console.log("Reading AUR search results...")
        var xhr = new XMLHttpRequest()
        xhr.open("GET", "file:///tmp/quickshell_aur_search")
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                filteredPackages.clear()
                var output = xhr.responseText.trim()
                console.log("AUR search output length:", output.length)
                
                if (!output || output.length === 0 || output.indexOf("AUR helper not found") >= 0) {
                    console.log("No AUR search results found or helper not installed")
                    return
                }
                
                var lines = output.split("\n")
                var currentPackage = null
                
                for (var i = 0; i < lines.length; i++) {
                    var line = lines[i]
                    var trimmedLine = line.trim()
                    
                    if (trimmedLine.length === 0) continue
                    
                    // Format AUR: "aur/package-name version (description)" lub "package-name version"
                    // Sprawdź czy linia zawiera "aur/" lub zaczyna się od nazwy pakietu
                    if (trimmedLine.indexOf("aur/") === 0 || (!line.startsWith(" ") && !line.startsWith("\t") && trimmedLine.indexOf(" ") > 0)) {
                        var parts = trimmedLine.split(" ")
                        if (parts.length >= 2) {
                            var packageName = parts[0]
                            // Usuń prefiks "aur/" jeśli istnieje
                            if (packageName.indexOf("aur/") === 0) {
                                packageName = packageName.substring(4)
                            }
                            
                            // Zapisz poprzedni pakiet jeśli istnieje
                            if (currentPackage) {
                                filteredPackages.append(currentPackage)
                            }
                            
                            // Parsuj nowy pakiet
                            currentPackage = {
                                name: packageName,
                                version: parts[1] || "",
                                description: ""
                            }
                            
                            // Spróbuj wyciągnąć opis z nawiasów jeśli istnieje
                            var descMatch = trimmedLine.match(/\(([^)]+)\)/)
                            if (descMatch && descMatch.length > 1) {
                                currentPackage.description = descMatch[1]
                            }
                            
                            console.log("Found AUR package:", currentPackage.name)
                        }
                    } else if (currentPackage && (line.startsWith("    ") || line.startsWith("\t"))) {
                        // Linia z opisem (zaczyna się od spacji lub taba)
                        var desc = trimmedLine
                        if (desc.length > 0 && !currentPackage.description) {
                            currentPackage.description = desc
                        }
                    }
                }
                
                // Dodaj ostatni pakiet
                if (currentPackage) {
                    filteredPackages.append(currentPackage)
                }
                
                console.log("Total AUR packages found:", filteredPackages.count)
                
                // Resetuj selectedIndex jeśli jest poza zakresem
                if (selectedIndex >= filteredPackages.count) {
                    selectedIndex = Math.max(0, filteredPackages.count - 1)
                }
                if (selectedIndex < 0 && filteredPackages.count > 0) {
                    selectedIndex = 0
                }
            }
        }
        xhr.send()
    }
    
    // Function to install pacman package
    function installPacmanPackage(packageName) {
        console.log("installPacmanPackage called with:", packageName)
        if (packageName) {
            // Escape package name
            var safeName = packageName.replace(/"/g, '\\"').replace(/'/g, "\\'").replace(/ /g, "\\ ")
            
            // Use bash script for installation
            var scriptPath = projectPath + "/scripts/install-package.sh"
            // Open kitty, set as floating, size 1200x700 and center
            var command = "hyprctl dispatch exec \"kitty --class=floating_kitty -e bash " + scriptPath + " " + safeName + "\"; sleep 0.3; hyprctl dispatch focuswindow \"class:floating_kitty\"; hyprctl dispatch togglefloating; hyprctl dispatch resizeactive exact 1200 700; hyprctl dispatch centerwindow"
            
            console.log("Executing command:", command)
            
            Qt.createQmlObject("import Quickshell.Io; import QtQuick; Process { command: ['sh', '-c', '" + command.replace(/'/g, "\\'") + "']; running: true }", appLauncherRoot)
            
            if (sharedData) {
                sharedData.launcherVisible = false
            }
        } else {
            console.log("Package name is empty or null")
        }
    }
    
    // Function to install AUR package
    function installAurPackage(packageName) {
        console.log("installAurPackage called with:", packageName)
        if (packageName) {
            // Escape package name
            var safeName = packageName.replace(/"/g, '\\"').replace(/'/g, "\\'").replace(/ /g, "\\ ")
            
            // Use bash script for AUR installation
            var scriptPath = projectPath + "/scripts/install-aur-package.sh"
            // Open kitty, set as floating, size 1200x700 and center
            var command = "hyprctl dispatch exec \"kitty --class=floating_kitty -e bash " + scriptPath + " " + safeName + "\"; sleep 0.3; hyprctl dispatch focuswindow \"class:floating_kitty\"; hyprctl dispatch togglefloating; hyprctl dispatch resizeactive exact 1200 700; hyprctl dispatch centerwindow"
            
            console.log("Executing command:", command)
            
            Qt.createQmlObject("import Quickshell.Io; import QtQuick; Process { command: ['sh', '-c', '" + command.replace(/'/g, "\\'") + "']; running: true }", appLauncherRoot)
            
            if (sharedData) {
                sharedData.launcherVisible = false
            }
        } else {
            console.log("Package name is empty or null")
        }
    }
    
    // Function to load installed packages
    function loadInstalledPackages() {
        installedPackages = []
        filteredInstalledPackages.clear()
        
        console.log("Loading installed packages...")
        
        // Run pacman -Q and save to file
        Qt.createQmlObject("import Quickshell.Io; import QtQuick; Process { command: ['sh', '-c', 'pacman -Q 2>/dev/null > /tmp/quickshell_installed_packages']; running: true }", appLauncherRoot)
        
        // Wait a moment and read results
        Qt.createQmlObject("import QtQuick; Timer { interval: 300; running: true; repeat: false; onTriggered: appLauncherRoot.readInstalledPackages() }", appLauncherRoot)
    }
    
    // Function to read installed packages
    function readInstalledPackages() {
        console.log("Reading installed packages...")
        var xhr = new XMLHttpRequest()
        xhr.open("GET", "file:///tmp/quickshell_installed_packages")
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                installedPackages = []
                var output = xhr.responseText.trim()
                
                if (!output || output.length === 0) {
                    console.log("No installed packages found")
                    filterInstalledPackages()
                    return
                }
                
                var lines = output.split("\n")
                
                for (var i = 0; i < lines.length; i++) {
                    var line = lines[i].trim()
                    if (line.length === 0) continue
                    
                    // Format: name version (e.g. "firefox 131.0-1")
                    var parts = line.split(" ")
                    if (parts.length >= 2) {
                        var packageName = parts[0]
                        var version = parts[1]
                        installedPackages.push({
                            name: packageName,
                            version: version
                        })
                    }
                }
                
                console.log("Loaded", installedPackages.length, "installed packages")
                filterInstalledPackages()
            }
        }
        xhr.send()
    }
    
    // Function to filter installed packages
    function filterInstalledPackages() {
        filteredInstalledPackages.clear()
        var search = (packageSearchText || "").toLowerCase().trim()
        
        for (var i = 0; i < installedPackages.length; i++) {
            var pkg = installedPackages[i]
            if (!pkg || !pkg.name) continue
            
            var name = (pkg.name || "").toLowerCase()
            
            // If search is empty, show all packages
            // Otherwise, filter by name
            if (search === "" || name.indexOf(search) >= 0) {
                filteredInstalledPackages.append({
                    name: pkg.name,
                    version: pkg.version || ""
                })
            }
        }
        
        // Reset selectedIndex if out of range
        if (selectedIndex >= filteredInstalledPackages.count) {
            selectedIndex = Math.max(0, filteredInstalledPackages.count - 1)
        }
        if (selectedIndex < 0 && filteredInstalledPackages.count > 0) {
            selectedIndex = 0
        }
    }
    
    // Function to remove pacman package
    function removePacmanPackage(packageName) {
        console.log("removePacmanPackage called with:", packageName)
        if (packageName) {
            // Escape package name
            var safeName = packageName.replace(/"/g, '\\"').replace(/'/g, "\\'").replace(/ /g, "\\ ")
            
            // Use bash script for removal
            var scriptPath = projectPath + "/scripts/remove-package.sh"
            // Open kitty, set as floating, size 1200x700 and center
            var command = "hyprctl dispatch exec \"kitty --class=floating_kitty -e bash " + scriptPath + " " + safeName + "\"; sleep 0.3; hyprctl dispatch focuswindow \"class:floating_kitty\"; hyprctl dispatch togglefloating; hyprctl dispatch resizeactive exact 1200 700; hyprctl dispatch centerwindow"
            
            console.log("Executing command:", command)
            
            Qt.createQmlObject("import Quickshell.Io; import QtQuick; Process { command: ['sh', '-c', '" + command.replace(/'/g, "\\'") + "']; running: true }", appLauncherRoot)
            
            if (sharedData) {
                sharedData.launcherVisible = false
            }
        } else {
            console.log("Package name is empty or null")
        }
    }
    
    // Funkcja usuwania pakietu z AUR
    function removeAurPackage(packageName) {
        console.log("removeAurPackage called with:", packageName)
        if (packageName) {
            // Escapuj nazwę pakietu
            var safeName = packageName.replace(/"/g, '\\"').replace(/'/g, "\\'").replace(/ /g, "\\ ")
            
            // Użyj skryptu bash do usuwania AUR
            var scriptPath = projectPath + "/scripts/remove-aur-package.sh"
            // Otwórz kitty, ustaw jako floating, rozmiar 1200x700 i wyśrodkuj
            var command = "hyprctl dispatch exec \"kitty --class=floating_kitty -e bash " + scriptPath + " " + safeName + "\"; sleep 0.3; hyprctl dispatch focuswindow \"class:floating_kitty\"; hyprctl dispatch togglefloating; hyprctl dispatch resizeactive exact 1200 700; hyprctl dispatch centerwindow"
            
            console.log("Executing command:", command)
            
            Qt.createQmlObject("import Quickshell.Io; import QtQuick; Process { command: ['sh', '-c', '" + command.replace(/'/g, "\\'") + "']; running: true }", appLauncherRoot)
            
            if (sharedData) {
                sharedData.launcherVisible = false
            }
        } else {
            console.log("Package name is empty or null")
        }
    }
    
    // Obserwuj zmiany launcherVisible
    Connections {
        target: sharedData
        function onLauncherVisibleChanged() {
            if (sharedData && sharedData.launcherVisible) {
                // Reset do wyboru trybu
                currentMode = -1
                currentPackageMode = -1
                installSourceMode = -1
                removeSourceMode = -1
                currentSettingsMode = -1
                searchInput.text = ""
                searchText = ""
                packageSearchText = ""
                selectedIndex = 0
                
                // Wymuś focus natychmiast (użyj Qt.callLater dla pewności)
                Qt.callLater(function() {
                    if (appLauncherRoot.launcherContainer) {
                        appLauncherRoot.launcherContainer.forceActiveFocus()
                    }
                })
                
                // Automatycznie złap focus po otwarciu - użyj większego opóźnienia dla pewności
                Qt.createQmlObject("import QtQuick; Timer { interval: 50; running: true; repeat: false; onTriggered: { if (appLauncherRoot.launcherContainer && appLauncherRoot.sharedData && appLauncherRoot.sharedData.launcherVisible) { appLauncherRoot.launcherContainer.forceActiveFocus() } } }", appLauncherRoot)
                
                // Dodatkowe wymuszenie focus po dłuższym czasie jako fallback
                Qt.createQmlObject("import QtQuick; Timer { interval: 150; running: true; repeat: false; onTriggered: { if (appLauncherRoot.launcherContainer && appLauncherRoot.sharedData && appLauncherRoot.sharedData.launcherVisible) { appLauncherRoot.launcherContainer.forceActiveFocus() } } }", appLauncherRoot)
                
                // Ostatnie wymuszenie focus po jeszcze dłuższym czasie jako ostateczny fallback
                Qt.createQmlObject("import QtQuick; Timer { interval: 300; running: true; repeat: false; onTriggered: { if (appLauncherRoot.launcherContainer && appLauncherRoot.sharedData && appLauncherRoot.sharedData.launcherVisible) { appLauncherRoot.launcherContainer.forceActiveFocus() } } }", appLauncherRoot)
            } else {
                // Gdy się zamyka, usuń focus
                searchInput.focus = false
                pacmanSearchInput.focus = false
                aurSearchInput.focus = false
                removeSearchInput.focus = false
                removeAurSearchInput.focus = false
                launcherContainer.focus = false
            }
        }
    }
    
    // Kontener z zawartością
    Item {
        id: launcherContainer
        anchors.fill: parent
        opacity: (sharedData && sharedData.launcherVisible) ? 1.0 : 0.0
        enabled: opacity > 0.1  // Wyłącz interakcję gdy niewidoczne
        focus: (sharedData && sharedData.launcherVisible)  // Focus dla klawiatury
        scale: (sharedData && sharedData.launcherVisible) ? 1.0 : 0.98
        
        Behavior on opacity {
            NumberAnimation {
                duration: 280
                easing.type: Easing.OutQuart
            }
        }
        
        Behavior on scale {
            NumberAnimation {
                duration: 280
                easing.type: Easing.OutQuart
            }
        }
        
        // Wymuś focus gdy staje się widoczny
        onEnabledChanged: {
            if (enabled && sharedData && sharedData.launcherVisible) {
                Qt.callLater(function() {
                    launcherContainer.forceActiveFocus()
                })
            }
        }
        
        // Wymuś focus gdy opacity się zmienia (dodatkowe zabezpieczenie)
        onOpacityChanged: {
            if (opacity > 0.5 && sharedData && sharedData.launcherVisible) {
                Qt.callLater(function() {
                    launcherContainer.forceActiveFocus()
                })
            }
        }
        
        Behavior on opacity {
            NumberAnimation { 
                duration: 400
                easing.type: Easing.OutQuart
            }
        }
        
        // Tło z gradientem
        Rectangle {
            id: launcherBackground
            anchors.fill: parent
            radius: 0
            
            // Użyj sharedData.colorBackground jeśli dostępny - jednolite tło bez gradientu
            color: (sharedData && sharedData.colorBackground) ? sharedData.colorBackground : colorBackground
        }
        
        // Obsługa klawiszy na kontenerze - przekieruj do TextInput tylko w trybie Launch App
        Keys.forwardTo: (currentMode === 0) ? [searchInput] : []
        
        Keys.onPressed: function(event) {
            // Escape - zamknij launcher lub wróć do wyboru trybu
            if (event.key === Qt.Key_Escape) {
                if (currentMode === -1) {
                    // Jeśli jesteśmy w wyborze trybu, zamknij launcher
                    if (sharedData) {
                        sharedData.launcherVisible = false
                    }
                } else if (currentMode === 3 && currentNotesMode !== -1) {
                    // W edytorze notes - wróć do menu notes
                    currentNotesMode = -1
                    selectedIndex = 0
                } else if (currentMode === 3 && currentNotesMode === -1) {
                    // W menu notes - wróć do wyboru trybu
                    currentMode = -1
                    selectedIndex = 2  // Wróć do pozycji Notes w menu
                } else if (currentMode === 2 && currentSettingsMode !== -1) {
                    // W ustawieniach - wróć do listy opcji
                    currentSettingsMode = -1
                    selectedIndex = 0
                    wallpaperSelectedIndex = 0  // Reset indeksu tapet
                } else if (currentMode === 1 && currentPackageMode === 0) {
                    // Wróć do wyboru opcji Packages
                    currentPackageMode = -1
                    installSourceMode = -1
                    selectedIndex = 0
                } else if (currentMode === 1 && currentPackageMode === 3) {
                    // Wróć do wyboru opcji Packages
                    currentPackageMode = -1
                    removeSourceMode = -1
                    selectedIndex = 0
                } else if (currentMode === 1 && (currentPackageMode === 1 || currentPackageMode === 2)) {
                    // Wróć do wyboru źródła instalacji
                    currentPackageMode = 0
                    installSourceMode = -1
                    selectedIndex = 0
                } else if (currentMode === 1 && (currentPackageMode === 4 || currentPackageMode === 5)) {
                    // Wróć do wyboru źródła usuwania
                    currentPackageMode = 3
                    removeSourceMode = -1
                    selectedIndex = 0
                } else {
                    // Wróć do wyboru trybu
                    currentMode = -1
                    selectedIndex = 0
                    currentPackageMode = -1
                    currentSettingsMode = -1
                }
                event.accepted = true
            } else if (event.key === Qt.Key_Up) {
                // Strzałka w górę - nawigacja w liście
                if (currentMode === -1) {
                    // W wyborze trybu
                    if (selectedIndex > 0) {
                        selectedIndex--
                        modesList.positionViewAtIndex(selectedIndex, ListView.Center)
                    }
                    event.accepted = true
                } else if (currentMode === 0) {
                    // W trybie Launch App - przekieruj do TextInput
                    searchInput.forceActiveFocus()
                    event.accepted = false
                } else if (currentMode === 1 && currentPackageMode === 0) {
                    // W wyborze źródła instalacji - nawigacja po liście
                    if (selectedIndex > 0) {
                        selectedIndex--
                        installSourceList.positionViewAtIndex(selectedIndex, ListView.Center)
                    }
                    event.accepted = true
                } else if (currentMode === 1 && currentPackageMode === 1) {
                    // W trybie Pacman search - nawigacja po liście pakietów
                    if (selectedIndex > 0) {
                        selectedIndex--
                        pacmanPackagesList.positionViewAtIndex(selectedIndex, ListView.Center)
                    }
                    event.accepted = true
                } else if (currentMode === 1 && currentPackageMode === 2) {
                    // W trybie AUR search - nawigacja po liście pakietów AUR
                    if (selectedIndex > 0) {
                        selectedIndex--
                        aurPackagesList.positionViewAtIndex(selectedIndex, ListView.Center)
                    }
                    event.accepted = true
                } else if (currentMode === 1 && currentPackageMode === 3) {
                    // W wyborze źródła usuwania - nawigacja po liście
                    if (selectedIndex > 0) {
                        selectedIndex--
                        removeSourceList.positionViewAtIndex(selectedIndex, ListView.Center)
                    }
                    event.accepted = true
                } else if (currentMode === 1 && currentPackageMode === 4) {
                    // W trybie Pacman remove search - nawigacja po liście zainstalowanych pakietów
                    if (selectedIndex > 0) {
                        selectedIndex--
                        removePackagesList.positionViewAtIndex(selectedIndex, ListView.Center)
                    }
                    event.accepted = true
                } else if (currentMode === 1 && currentPackageMode === 5) {
                    // W trybie AUR remove search - nawigacja po liście zainstalowanych pakietów
                    if (selectedIndex > 0) {
                        selectedIndex--
                        removeAurPackagesList.positionViewAtIndex(selectedIndex, ListView.Center)
                    }
                    event.accepted = true
                } else if (currentMode === 2 && currentSettingsMode === -1) {
                    // W trybie Settings - nawigacja po liście opcji
                    if (selectedIndex > 0) {
                        selectedIndex--
                        settingsList.positionViewAtIndex(selectedIndex, ListView.Center)
                    }
                    event.accepted = true
                } else if (currentMode === 2 && currentSettingsMode === 0) {
                    // W trybie Wallpaper - nawigacja po GridView
                    var columns = Math.floor(wallpapersGrid.width / wallpapersGrid.cellWidth)
                    if (wallpaperSelectedIndex >= columns) {
                        wallpaperSelectedIndex -= columns
                        wallpapersGrid.currentIndex = wallpaperSelectedIndex
                        wallpapersGrid.positionViewAtIndex(wallpaperSelectedIndex, GridView.Visible)
                    }
                    event.accepted = true
                }
            } else if (event.key === Qt.Key_Down) {
                // Strzałka w dół - nawigacja w liście
                if (currentMode === -1) {
                    // W wyborze trybu
                    if (selectedIndex < modesList.count - 1) {
                        selectedIndex++
                        modesList.positionViewAtIndex(selectedIndex, ListView.Center)
                    }
                    event.accepted = true
                } else if (currentMode === 0) {
                    // W trybie Launch App - przekieruj do TextInput
                    searchInput.forceActiveFocus()
                    event.accepted = false
                } else if (currentMode === 1 && currentPackageMode === 0) {
                    // W wyborze źródła instalacji - nawigacja po liście
                    if (selectedIndex < installSourceList.count - 1) {
                        selectedIndex++
                        installSourceList.positionViewAtIndex(selectedIndex, ListView.Center)
                    }
                    event.accepted = true
                } else if (currentMode === 1 && currentPackageMode === 1) {
                    // W trybie Pacman search - nawigacja po liście pakietów
                    if (selectedIndex < filteredPackages.count - 1) {
                        selectedIndex++
                        pacmanPackagesList.positionViewAtIndex(selectedIndex, ListView.Center)
                    }
                    event.accepted = true
                } else if (currentMode === 1 && currentPackageMode === 2) {
                    // W trybie AUR search - nawigacja po liście pakietów AUR
                    if (selectedIndex < filteredPackages.count - 1) {
                        selectedIndex++
                        aurPackagesList.positionViewAtIndex(selectedIndex, ListView.Center)
                    }
                    event.accepted = true
                } else if (currentMode === 1 && currentPackageMode === 3) {
                    // W wyborze źródła usuwania - nawigacja po liście
                    if (selectedIndex < removeSourceList.count - 1) {
                        selectedIndex++
                        removeSourceList.positionViewAtIndex(selectedIndex, ListView.Center)
                    }
                    event.accepted = true
                } else if (currentMode === 1 && currentPackageMode === 4) {
                    // W trybie Pacman remove search - nawigacja po liście zainstalowanych pakietów
                    if (selectedIndex < filteredInstalledPackages.count - 1) {
                        selectedIndex++
                        removePackagesList.positionViewAtIndex(selectedIndex, ListView.Center)
                    }
                    event.accepted = true
                } else if (currentMode === 1 && currentPackageMode === 5) {
                    // W trybie AUR remove search - nawigacja po liście zainstalowanych pakietów
                    if (selectedIndex < filteredInstalledPackages.count - 1) {
                        selectedIndex++
                        removeAurPackagesList.positionViewAtIndex(selectedIndex, ListView.Center)
                    }
                    event.accepted = true
                } else if (currentMode === 2 && currentSettingsMode === -1) {
                    // W trybie Settings - nawigacja po liście opcji
                    if (selectedIndex < settingsList.count - 1) {
                        selectedIndex++
                        settingsList.positionViewAtIndex(selectedIndex, ListView.Center)
                    }
                    event.accepted = true
                } else if (currentMode === 2 && currentSettingsMode === 0) {
                    // W trybie Wallpaper - nawigacja po GridView
                    var columns = Math.floor(wallpapersGrid.width / wallpapersGrid.cellWidth)
                    var maxIndex = wallpapersModel.count - 1
                    if (wallpaperSelectedIndex + columns <= maxIndex) {
                        wallpaperSelectedIndex += columns
                        wallpapersGrid.currentIndex = wallpaperSelectedIndex
                        wallpapersGrid.positionViewAtIndex(wallpaperSelectedIndex, GridView.Visible)
                    }
                    event.accepted = true
                } else if (currentMode === 2 && currentSettingsMode === 2) {
                    // W trybie Bluetooth - nawigacja po liście urządzeń
                    if (bluetoothSelectedIndex < bluetoothDevicesModel.count - 1) {
                        bluetoothSelectedIndex++
                        bluetoothDevicesList.currentIndex = bluetoothSelectedIndex
                        bluetoothDevicesList.positionViewAtIndex(bluetoothSelectedIndex, ListView.Center)
                    }
                    event.accepted = true
                }
            } else if (event.key === Qt.Key_Left) {
                // Strzałka w lewo - nawigacja w GridView tapet
                if (currentMode === 2 && currentSettingsMode === 0) {
                    if (wallpaperSelectedIndex > 0) {
                        wallpaperSelectedIndex--
                        wallpapersGrid.currentIndex = wallpaperSelectedIndex
                        wallpapersGrid.positionViewAtIndex(wallpaperSelectedIndex, GridView.Visible)
                    }
                    event.accepted = true
                }
            } else if (event.key === Qt.Key_Right) {
                // Strzałka w prawo - nawigacja w GridView tapet
                if (currentMode === 2 && currentSettingsMode === 0) {
                    var maxIndex = wallpapersModel.count - 1
                    if (wallpaperSelectedIndex < maxIndex) {
                        wallpaperSelectedIndex++
                        wallpapersGrid.currentIndex = wallpaperSelectedIndex
                        wallpapersGrid.positionViewAtIndex(wallpaperSelectedIndex, GridView.Visible)
                    }
                    event.accepted = true
                }
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                // Enter - wybierz tryb, pakiet lub aplikację
                if (currentMode === -1) {
                    // Wybierz tryb
                    if (selectedIndex >= 0 && selectedIndex < modesList.count) {
                        var mode = modesList.model.get(selectedIndex)
                        currentMode = mode.mode
                        selectedIndex = 0
                        modesList.currentIndex = -1
                        appsList.currentIndex = -1
                        packagesOptionsList.currentIndex = -1
                        if (currentMode === 1) {
                            currentPackageMode = -1
                            installSourceMode = -1
                            removeSourceMode = -1
                        }
                    }
                    event.accepted = true
                } else if (currentMode === 1 && currentPackageMode === -1) {
                    // W trybie Packages - wybierz opcję (Install/Remove/Update)
                    if (selectedIndex >= 0 && selectedIndex < packagesOptionsList.count) {
                        var pkgOption = packagesOptionsList.model.get(selectedIndex)
                        if (pkgOption.action === "install") {
                            // Przełącz na tryb wyszukiwania pakietów
                            currentPackageMode = 0
                            selectedIndex = 0
                            packageSearchText = ""
                            // Ustaw focus na pole wyszukiwania po chwili
                            Qt.createQmlObject("import QtQuick; Timer { interval: 200; running: true; repeat: false; onTriggered: { if (appLauncherRoot.pacmanSearchInput) appLauncherRoot.pacmanSearchInput.forceActiveFocus() } }", appLauncherRoot)
                        } else if (pkgOption.action === "remove") {
                            // Przełącz na wybór źródła usuwania
                            currentPackageMode = 3
                            removeSourceMode = -1
                            selectedIndex = 0
                        } else if (pkgOption.action === "update") {
                            // Uruchom update systemu
                            updateSystem()
                        }
                    }
                    event.accepted = true
                } else if (currentMode === 1 && currentPackageMode === 0) {
                    // W trybie Pacman search - przekieruj do TextInput
                    if (pacmanSearchInput) pacmanSearchInput.forceActiveFocus()
                    event.accepted = false
                } else if (currentMode === 1 && currentPackageMode === 1) {
                    // W trybie AUR search - przekieruj do TextInput
                    if (aurSearchInput) aurSearchInput.forceActiveFocus()
                    event.accepted = false
                } else if (currentMode === 1 && currentPackageMode === 2) {
                    // W trybie Remove search - przekieruj do TextInput
                    if (removeSearchInput) removeSearchInput.forceActiveFocus()
                    event.accepted = false
                } else if (currentMode === 2 && currentSettingsMode === -1) {
                    // W trybie Settings - wybierz opcję
                    if (selectedIndex >= 0 && selectedIndex < settingsList.count) {
                        var settingOption = settingsList.model.get(selectedIndex)
                        if (settingOption.settingId === 1) {
                            // Toggle Sidebar - immediate action
                            if (sharedData && sharedData.sidebarVisible !== undefined) {
                                sharedData.sidebarVisible = !sharedData.sidebarVisible
                                console.log("Sidebar toggled to:", sharedData.sidebarVisible)
                            }
                            // Close launcher after toggle
                            if (sharedData) {
                                sharedData.launcherVisible = false
                            }
                            event.accepted = true
                        } else if (settingOption.settingId === 6) {
                            // Toggle Sidebar Position - immediate action
                            if (sharedData && sharedData.sidebarPosition !== undefined) {
                                sharedData.sidebarPosition = (sharedData.sidebarPosition === "left") ? "top" : "left"
                                console.log("Sidebar position changed to:", sharedData.sidebarPosition)
                            }
                            // Close launcher after toggle
                            if (sharedData) {
                                sharedData.launcherVisible = false
                            }
                            event.accepted = true
                        } else {
                            currentSettingsMode = settingOption.settingId
                            if (settingOption.settingId === 0) {
                                loadWallpapers()
                                wallpaperSelectedIndex = 0  // Reset indeksu przy otwieraniu
                                wallpapersGrid.currentIndex = 0
                            } else if (settingOption.settingId === 3) {
                                // Colors - no action needed
                            }
                            event.accepted = true
                        }
                    }
                } else if (currentMode === 2 && currentSettingsMode === 0) {
                    // W trybie Wallpaper - wybierz tapetę
                    if (wallpaperSelectedIndex >= 0 && wallpaperSelectedIndex < wallpapersModel.count) {
                        var wallpaper = wallpapersModel.get(wallpaperSelectedIndex)
                        if (wallpaper && wallpaper.path) {
                            setWallpaper(wallpaper.path)
                        }
                    }
                    event.accepted = true
                } else if (currentMode === 2 && currentSettingsMode === 2) {
                    // W trybie Bluetooth - połącz z wybranym urządzeniem
                    if (bluetoothSelectedIndex >= 0 && bluetoothSelectedIndex < bluetoothDevicesModel.count && !bluetoothConnecting) {
                        var device = bluetoothDevicesModel.get(bluetoothSelectedIndex)
                        if (device && device.mac) {
                            connectBluetoothDevice(device.mac)
                        }
                    }
                    event.accepted = true
                } else if (currentMode === 0) {
                    // W trybie Launch App - przekieruj do TextInput
                    searchInput.forceActiveFocus()
                    event.accepted = false
                }
            } else if (currentMode === 0) {
                // W trybie Launch App - przekieruj do TextInput
                searchInput.forceActiveFocus()
                event.accepted = false  // Pozwól propagować
            } else if (currentMode === 1 && currentPackageMode === -1) {
                // W trybie Packages - nawigacja po liście opcji
                if (event.key === Qt.Key_Up) {
                    if (selectedIndex > 0) {
                        selectedIndex--
                        packagesOptionsList.positionViewAtIndex(selectedIndex, ListView.Center)
                    }
                    event.accepted = true
                } else if (event.key === Qt.Key_Down) {
                    if (selectedIndex < packagesOptionsList.count - 1) {
                        selectedIndex++
                        packagesOptionsList.positionViewAtIndex(selectedIndex, ListView.Center)
                    }
                    event.accepted = true
                }
            } else if (currentMode === 1 && currentPackageMode === 0) {
                // W wyborze źródła instalacji - nawigacja po liście
                if (event.key === Qt.Key_Up) {
                    if (selectedIndex > 0) {
                        selectedIndex--
                        installSourceList.positionViewAtIndex(selectedIndex, ListView.Center)
                    }
                    event.accepted = true
                } else if (event.key === Qt.Key_Down) {
                    if (selectedIndex < installSourceList.count - 1) {
                        selectedIndex++
                        installSourceList.positionViewAtIndex(selectedIndex, ListView.Center)
                    }
                    event.accepted = true
                }
            } else if (currentMode === 1 && currentPackageMode === 1) {
                // W trybie Pacman search - przekieruj do TextInput
                if (pacmanSearchInput) pacmanSearchInput.forceActiveFocus()
                event.accepted = false
            } else if (currentMode === 1 && currentPackageMode === 2) {
                // W trybie AUR search - przekieruj do TextInput
                if (aurSearchInput) aurSearchInput.forceActiveFocus()
                event.accepted = false
                } else if (currentMode === 1 && currentPackageMode === 3) {
                    // W wyborze źródła usuwania - nawigacja po liście
                    if (event.key === Qt.Key_Up) {
                        if (selectedIndex > 0) {
                            selectedIndex--
                            removeSourceList.positionViewAtIndex(selectedIndex, ListView.Center)
                        }
                        event.accepted = true
                    } else if (event.key === Qt.Key_Down) {
                        if (selectedIndex < removeSourceList.count - 1) {
                            selectedIndex++
                            removeSourceList.positionViewAtIndex(selectedIndex, ListView.Center)
                        }
                        event.accepted = true
                    }
                } else if (currentMode === 1 && currentPackageMode === 4) {
                    // W trybie Pacman remove search - przekieruj do TextInput
                if (removeSearchInput) removeSearchInput.forceActiveFocus()
                event.accepted = false
                } else if (currentMode === 1 && currentPackageMode === 5) {
                    // W trybie AUR remove search - przekieruj do TextInput
                    if (removeAurSearchInput) removeAurSearchInput.forceActiveFocus()
                    event.accepted = false
                } else if (currentMode === 3 && currentNotesMode === -1) {
                    // W menu notes - nawigacja po liście notatek
                    if (event.key === Qt.Key_Up) {
                        if (selectedIndex > 0) {
                            selectedIndex--
                            notesList.positionViewAtIndex(selectedIndex, ListView.Center)
                        }
                        event.accepted = true
                    } else if (event.key === Qt.Key_Down) {
                        if (selectedIndex < notesList.count - 1) {
                            selectedIndex++
                            notesList.positionViewAtIndex(selectedIndex, ListView.Center)
                        }
                        event.accepted = true
                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        // Enter - wybierz pierwszą notatkę lub nową notatkę
                        if (selectedIndex === 0) {
                            // Nowa notatka
                            currentNotesMode = 0
                            selectedIndex = 0
                            notesEditText.text = ""
                            notesFileName = ""
                        } else {
                            // Wybierz istniejącą notatkę
                            var noteItem = notesModel.get(selectedIndex)
                            if (noteItem && noteItem.file !== "") {
                                currentNotesMode = 1
                                notesFileName = noteItem.file
                                loadNoteContent(noteItem.file)
                            }
                        }
                        event.accepted = true
                    }
                } else if (currentMode === 3 && (currentNotesMode === 0 || currentNotesMode === 1)) {
                    // W edytorze notes - przekieruj do TextEdit
                    notesEditText.forceActiveFocus()
                    event.accepted = false
            }
        }
        
        // Lista trybów (gdy currentMode === -1)
        ListView {
            id: modesList
            anchors.fill: parent
            anchors.margins: 20
            visible: currentMode === -1
            opacity: currentMode === -1 ? 1.0 : 0.0
            currentIndex: selectedIndex
            spacing: 8
            
            onCurrentIndexChanged: {
                if (currentIndex !== selectedIndex && currentIndex >= 0) {
                    selectedIndex = currentIndex
                }
            }
            
            Behavior on opacity {
                NumberAnimation {
                    duration: 280
                    easing.type: Easing.OutQuart
                }
            }
            
            model: ListModel {
                ListElement { name: "Launcher"; description: "Launch applications"; mode: 0; icon: "󰈙" }
                ListElement { name: "Packages"; description: "Manage packages"; mode: 1; icon: "󰏖" }
                ListElement { name: "Notes"; description: "Quick notes and reminders"; mode: 3; icon: "󰎞" }
                ListElement { name: "Settings"; description: "Configure launcher"; mode: 2; icon: "󰒓" }
            }
            
            delegate: Rectangle {
                id: modeItem
                width: modesList.width
                height: 72
                color: "transparent"
                radius: 0
                scale: (selectedIndex === index || modeItemMouseArea.containsMouse) ? 1.02 : 1.0

                // Bottom accent line for selected items
                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: selectedIndex === index ? parent.width * 0.8 : 0
                    height: 3
                    color: (sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff"
                    radius: 1.5

                    Behavior on width {
                        NumberAnimation {
                            duration: 300
                            easing.type: Easing.OutCubic
                        }
                    }
                }
                
                Behavior on color {
                        ColorAnimation { 
                            duration: 200
                            easing.type: Easing.OutCubic
                        }
                    }
                    
                    Behavior on scale {
                        NumberAnimation {
                            duration: 200
                            easing.type: Easing.OutCubic
                        }
                }
                
                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: 20
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 16
                    
                    Text {
                        text: model.icon || ""
                        font.pixelSize: 22
                        color: (sharedData && sharedData.colorText) ? sharedData.colorText : colorText
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 4
                        
                        Text {
                            text: model.name
                            font.pixelSize: 15
                            font.family: "JetBrains Mono"
                            font.weight: selectedIndex === index ? Font.Bold : Font.Medium
                            color: selectedIndex === index ? colorText : (modeItemMouseArea.containsMouse ? colorText : ((sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff"))
                        }
                        
                        Text {
                            text: model.description
                            font.pixelSize: 12
                            font.family: "JetBrains Mono"
                            color: (sharedData && sharedData.colorText) ? sharedData.colorText : colorText
                            opacity: selectedIndex === index ? 0.85 : (modeItemMouseArea.containsMouse ? 0.75 : 0.6)
                        }
                    }
                }
                
                MouseArea {
                    id: modeItemMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    
                    onEntered: {
                        if (modesList.currentIndex !== index) {
                        selectedIndex = index
                            modesList.currentIndex = index
                        }
                    }
                    
                    onClicked: {
                        currentMode = model.mode
                        selectedIndex = 0
                        modesList.currentIndex = -1
                        if (model.mode === 1) {
                            currentPackageMode = -1
                        }
                    }
                }
            }
        }
        
        // Zawartość trybów
        Item {
            id: modeContent
            anchors.fill: parent
            anchors.margins: 20
            visible: currentMode !== -1
        
            // Tryb 0: Launcher
            Item {
                id: launchAppMode
                anchors.fill: parent
                visible: currentMode === 0
                
                Column {
                    id: launchAppColumn
                    anchors.fill: parent
                    spacing: 12
                            
                            // Pole wyszukiwania
                            Rectangle {
                                id: searchBox
                                width: parent.width
                                height: 48
                                color: searchInput.activeFocus ? colorPrimary : colorSecondary
                                radius: 0
                                
                                Behavior on color {
                                    ColorAnimation { 
                                        duration: 180
                                        easing.type: Easing.OutQuart
                                }
                                }
                                
                                TextInput {
                                    id: searchInput
                                    anchors.fill: parent
                                    anchors.margins: 20
                                    font.pixelSize: 15
                                    font.family: "JetBrains Mono"
                                    font.weight: Font.Medium
                                    font.letterSpacing: 0.2
                                    color: colorText
                                    verticalAlignment: TextInput.AlignVCenter
                                    z: 10  // Na wierzchu
                                    selectByMouse: true
                                    activeFocusOnPress: true
                                    activeFocusOnTab: true
                                    focus: (currentMode === 0 && sharedData && sharedData.launcherVisible)  // Focus tylko w trybie Launch App
                                    
                                    onTextChanged: {
                                        searchText = text
                                        selectedIndex = 0
                                        filterApps()
                                    }
                                    
                                    Keys.onPressed: function(event) {
                                        if (event.key === Qt.Key_Up) {
                                            if (selectedIndex > 0) {
                                                selectedIndex--
                                                appsList.positionViewAtIndex(selectedIndex, ListView.Center)
                                            }
                                            event.accepted = true
                                        } else if (event.key === Qt.Key_Down) {
                                            if (selectedIndex < filteredApps.count - 1) {
                                                selectedIndex++
                                                appsList.positionViewAtIndex(selectedIndex, ListView.Center)
                                            }
                                            event.accepted = true
                                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                            // Check if search text starts with "!" for Firefox search
                                            if (searchText && searchText.trim().startsWith("!")) {
                                                searchInFirefox(searchText.trim())
                                                event.accepted = true
                                                return
                                            }
                                            
                                            // Check if it's calculator mode
                                            if (isCalculatorMode && calculatorResult && calculatorResult !== "Error") {
                                                // Copy result to clipboard
                                                Qt.createQmlObject("import Quickshell.Io; import QtQuick; Process { command: ['sh', '-c', 'echo -n \"" + calculatorResult.replace(/"/g, '\\"') + "\" | xclip -selection clipboard']; running: true }", appLauncherRoot)
                                                if (sharedData) {
                                                    sharedData.launcherVisible = false
                                                }
                                                event.accepted = true
                                                return
                                            }
                                            
                                            if (filteredApps.count > 0 && selectedIndex >= 0 && selectedIndex < filteredApps.count) {
                                                var app = filteredApps.get(selectedIndex)
                                                if (app && app.exec) {
                                                    launchApp(app)
                                                } else if (app && app.isCalculator && calculatorResult) {
                                                    // Copy calculator result
                                                    Qt.createQmlObject("import Quickshell.Io; import QtQuick; Process { command: ['sh', '-c', 'echo -n \"" + calculatorResult.replace(/"/g, '\\"') + "\" | xclip -selection clipboard']; running: true }", appLauncherRoot)
                                                    if (sharedData) {
                                                        sharedData.launcherVisible = false
                                                    }
                                                }
                                            }
                                            event.accepted = true
                                        } else if (event.key === Qt.Key_Escape) {
                                            if (sharedData) {
                                                sharedData.launcherVisible = false
                                            }
                                            event.accepted = true
                                        }
                                    }
                                }
                                
                                // Placeholder text
                                Text {
                                    anchors.fill: searchInput
                                    anchors.margins: 0
                                    text: "Search applications..."
                                    font.pixelSize: 15
                                    font.family: "JetBrains Mono"
                                    font.weight: Font.Medium
                                    color: (sharedData && sharedData.colorText) ? sharedData.colorText : colorText
                                    verticalAlignment: Text.AlignVCenter
                                    visible: searchInput.text.length === 0
                                    z: 5  // Za TextInput
                                }
                            }
                            
                            // Lista aplikacji
                            ListView {
                                id: appsList
                                width: parent.width
                                height: parent.height - searchBox.height - parent.spacing
                                clip: true
                                spacing: 4
                                
                                model: filteredApps
                                currentIndex: selectedIndex
                                
                                onCurrentIndexChanged: {
                                    if (currentIndex !== selectedIndex) {
                                        selectedIndex = currentIndex
                                    }
                                }
                                
                                addDisplaced: Transition {
                                    NumberAnimation {
                                        properties: "y"
                                        duration: 220
                                        easing.type: Easing.OutQuart
                                    }
                                }
                                
                                removeDisplaced: Transition {
                                    NumberAnimation {
                                        properties: "y"
                                        duration: 180
                                        easing.type: Easing.OutQuart
                                    }
                                }
                                
                                delegate: Rectangle {
                                id: appItem
                                width: appsList.width
                                height: 72
                                color: "transparent"
                                radius: 0
                                scale: (selectedIndex === index || appItemMouseArea.containsMouse) ? 1.02 : 1.0

                                // Bottom accent line for selected items
                                Rectangle {
                                    anchors.bottom: parent.bottom
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: selectedIndex === index ? parent.width * 0.8 : 0
                                    height: 3
                                    color: (sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff"
                                    radius: 1.5

                                    Behavior on width {
                                        NumberAnimation {
                                            duration: 300
                                            easing.type: Easing.OutCubic
                                        }
                                    }
                                }
                                
                                // Pobierz dane z modelu
                                property string appName: model.name || "Unknown"
                                property string appComment: model.comment || ""
                                property string appExec: model.exec || ""
                                property string appIcon: model.icon || ""
                                property bool appIsCalculator: model.isCalculator || false
                                
                                Column {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 20
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 4
                                    
                                    Text {
                                        text: appItem.appName
                                        font.pixelSize: 15
                                        font.family: "JetBrains Mono"
                                        font.weight: selectedIndex === index ? Font.Bold : Font.Medium
                                        font.letterSpacing: 0.1
                                        color: selectedIndex === index ? colorText : (appItemMouseArea.containsMouse ? colorText : ((sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff"))
                                    }

                                    Text {
                                        text: appItem.appComment
                                        font.pixelSize: 12
                                        font.family: "JetBrains Mono"
                                        font.weight: Font.Normal
                                        font.letterSpacing: 0.1
                                        color: (sharedData && sharedData.colorText) ? sharedData.colorText : colorText
                                        opacity: selectedIndex === index ? 0.85 : (appItemMouseArea.containsMouse ? 0.75 : 0.6)
                                        visible: appItem.appComment && appItem.appComment.length > 0
                                    }
                                }
                                
                                MouseArea {
                                    id: appItemMouseArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    
                                    onEntered: {
                                        if (appsList.currentIndex !== index) {
                                        selectedIndex = index
                                            appsList.currentIndex = index
                                        }
                                    }
                                    
                                    onClicked: {
                                        // Check if search text starts with "!" for Firefox search
                                        if (searchText && searchText.trim().startsWith("!")) {
                                            searchInFirefox(searchText.trim())
                                            return
                                        }
                                        
                                        // Check if it's calculator result
                                        if (appItem.appIsCalculator && isCalculatorMode && calculatorResult && calculatorResult !== "Error") {
                                            Qt.createQmlObject("import Quickshell.Io; import QtQuick; Process { command: ['sh', '-c', 'echo -n \"" + calculatorResult.replace(/"/g, '\\"') + "\" | xclip -selection clipboard']; running: true }", appLauncherRoot)
                                            if (sharedData) {
                                                sharedData.launcherVisible = false
                                            }
                                            return
                                        }
                                        
                                        if (appItem.appExec) {
                                            launchApp({
                                                name: appItem.appName,
                                                comment: appItem.appComment,
                                                exec: appItem.appExec,
                                                icon: appItem.appIcon
                                            })
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            // Tryb 1: Packages - prosta lista (tło usunięte - używa głównego tła)
            
            ListView {
                id: packagesOptionsList
                anchors.fill: parent
                anchors.margins: 20
                visible: currentMode === 1 && currentPackageMode === -1
                clip: true
                z: 1
                currentIndex: selectedIndex
                
                onCurrentIndexChanged: {
                    if (currentIndex !== selectedIndex && currentIndex >= 0) {
                        selectedIndex = currentIndex
                    }
                }
                
                model: ListModel {
                    id: packagesModel
                    ListElement { name: "Install"; description: "Install packages"; action: "install"; icon: "󰐕" }
                    ListElement { name: "Remove"; description: "Remove packages"; action: "remove"; icon: "󰆐" }
                    ListElement { name: "Update"; description: "Update system packages (pacman -Syyu)"; action: "update"; icon: "󰏕" }
                }
                
                Component.onCompleted: {
                    console.log("Packages list created, model count:", packagesModel.count)
                }
                
                delegate: Rectangle {
                    id: packageOptionItem
                    width: packagesOptionsList.width
                    height: 72
                    color: "transparent"
                    radius: 0
                    scale: (selectedIndex === index || packageOptionItemMouseArea.containsMouse) ? 1.02 : 1.0

                    // Bottom accent line for selected items
                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: selectedIndex === index ? parent.width * 0.8 : 0
                        height: 3
                        color: (sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff"
                        radius: 1.5

                        Behavior on width {
                            NumberAnimation {
                                duration: 300
                                easing.type: Easing.OutCubic
                            }
                        }
                    }
                    
                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: 20
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 16
                        
                        Text {
                            text: model.icon || ""
                            font.pixelSize: 22
                            color: (sharedData && sharedData.colorText) ? sharedData.colorText : colorText
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        
                        Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 4
                        
                        Text {
                            text: model.name || "Unknown"
                                font.pixelSize: 15
                            font.family: "JetBrains Mono"
                            font.weight: selectedIndex === index ? Font.Bold : Font.Medium
                            color: selectedIndex === index ? colorText : (packageOptionItemMouseArea.containsMouse ? colorText : ((sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff"))
                        }
                        
                        Text {
                            text: model.description || ""
                                font.pixelSize: 12
                            font.family: "JetBrains Mono"
                            color: (sharedData && sharedData.colorText) ? sharedData.colorText : colorText
                            opacity: selectedIndex === index ? 0.85 : (packageOptionItemMouseArea.containsMouse ? 0.75 : 0.6)
                            }
                        }
                    }
                    
                    MouseArea {
                        id: packageOptionItemMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        
                        onEntered: {
                            if (packagesOptionsList.currentIndex !== index) {
                            selectedIndex = index
                                packagesOptionsList.currentIndex = index
                            }
                        }
                        
                        onClicked: {
                            if (model.action === "install") {
                                // Przełącz na wybór źródła instalacji (Pacman/AUR)
                                currentPackageMode = 0
                                installSourceMode = -1
                                selectedIndex = 0
                                packagesOptionsList.currentIndex = -1
                            } else if (model.action === "remove") {
                                // Przełącz na wybór źródła usuwania (Pacman/AUR)
                                currentPackageMode = 3
                                removeSourceMode = -1
                                selectedIndex = 0
                                packagesOptionsList.currentIndex = -1
                            } else if (model.action === "update") {
                                // Uruchom update systemu
                                updateSystem()
                            }
                        }
                    }
                }
            }
            
            // Wybór źródła instalacji (Pacman/AUR) - gdy currentPackageMode === 0
            ListView {
                id: installSourceList
                anchors.fill: parent
                anchors.margins: 20
                visible: currentMode === 1 && currentPackageMode === 0
                clip: true
                z: 1
                model: ListModel {
                    id: installSourceModel
                    ListElement { name: "Pacman"; description: "Install from official repositories"; source: "pacman"; icon: "󰏖" }
                    ListElement { name: "AUR"; description: "Install from AUR"; source: "aur"; icon: "󰣇" }
                }
                
                delegate: Rectangle {
                    id: installSourceItem
                    width: installSourceList.width
                    height: 72
                    color: "transparent"
                    radius: 0
                    scale: (selectedIndex === index || installSourceItemMouseArea.containsMouse) ? 1.02 : 1.0

                    // Bottom accent line for selected items
                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: selectedIndex === index ? parent.width * 0.8 : 0
                        height: 3
                        color: (sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff"
                        radius: 1.5

                        Behavior on width {
                            NumberAnimation {
                                duration: 300
                                easing.type: Easing.OutCubic
                            }
                        }
                    }
                    
                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: 20
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 16
                        
                        Text {
                            text: model.icon || ""
                            font.pixelSize: 22
                            color: (sharedData && sharedData.colorText) ? sharedData.colorText : colorText
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 4
                            
                            Text {
                                text: model.name || "Unknown"
                                font.pixelSize: 15
                                font.family: "JetBrains Mono"
                                font.weight: selectedIndex === index ? Font.Bold : Font.Medium
                                color: selectedIndex === index ? colorText : ((sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff")
                            }
                            
                            Text {
                                text: model.description || ""
                                font.pixelSize: 12
                                font.family: "JetBrains Mono"
                                color: (sharedData && sharedData.colorText) ? sharedData.colorText : colorText
                                opacity: selectedIndex === index ? 0.85 : (installSourceItemMouseArea.containsMouse ? 0.75 : 0.6)
                            }
                        }
                    }
                    
                    MouseArea {
                        id: installSourceItemMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        
                        onEntered: {
                            selectedIndex = index
                        }
                        
                        onClicked: {
                            if (model.source === "pacman") {
                                // Przełącz na tryb wyszukiwania Pacman
                                currentPackageMode = 1
                                installSourceMode = 0
                                selectedIndex = 0
                                packageSearchText = ""
                                // Ustaw focus na pole wyszukiwania
                                Qt.createQmlObject("import QtQuick; Timer { interval: 100; running: true; repeat: false; onTriggered: appLauncherRoot.pacmanSearchInput.forceActiveFocus() }", appLauncherRoot)
                            } else if (model.source === "aur") {
                                // Przełącz na tryb wyszukiwania AUR
                                currentPackageMode = 2
                                installSourceMode = 1
                                selectedIndex = 0
                                packageSearchText = ""
                                // Ustaw focus na pole wyszukiwania
                                Qt.createQmlObject("import QtQuick; Timer { interval: 100; running: true; repeat: false; onTriggered: appLauncherRoot.aurSearchInput.forceActiveFocus() }", appLauncherRoot)
                            }
                        }
                    }
                }
                
                highlight: Rectangle {
                    color: colorPrimary
                    radius: 0
                    
                    Behavior on color {
                        ColorAnimation { duration: 180; easing.type: Easing.OutQuart }
                    }
                }
            }
            
            // Wyszukiwarka pakietów Pacman (gdy currentPackageMode === 1)
            Item {
                id: pacmanSearchMode
                anchors.fill: parent
                anchors.margins: 20
                visible: currentMode === 1 && currentPackageMode === 1
                
                Column {
                    id: pacmanSearchColumn
                    anchors.fill: parent
                    spacing: 11
                    
                    // Pole wyszukiwania
                    Rectangle {
                        id: pacmanSearchBox
                        width: parent.width
                        height: 48
                        color: pacmanSearchInput.activeFocus ? colorPrimary : colorSecondary
                        radius: 0
                        
                        Behavior on color {
                            ColorAnimation { duration: 180; easing.type: Easing.OutQuart }
                        }
                        
                        TextInput {
                            id: pacmanSearchInput
                            anchors.fill: parent
                            anchors.margins: 20
                            font.pixelSize: 14
                            font.family: "JetBrains Mono"
                            color: colorText
                            verticalAlignment: TextInput.AlignVCenter
                            z: 10
                            selectByMouse: true
                            activeFocusOnPress: true
                            focus: (currentPackageMode === 1 && sharedData && sharedData.launcherVisible)
                            
                            onTextChanged: {
                                packageSearchText = text
                                selectedIndex = 0
                                if (text.length >= 2) {
                                    searchPacmanPackages(text)
                                } else {
                                    filteredPackages.clear()
                                }
                            }
                            
                            Keys.onPressed: function(event) {
                                if (event.key === Qt.Key_Up) {
                                    if (selectedIndex > 0) {
                                        selectedIndex--
                                        pacmanPackagesList.positionViewAtIndex(selectedIndex, ListView.Center)
                                    }
                                    event.accepted = true
                                } else if (event.key === Qt.Key_Down) {
                                    if (selectedIndex < filteredPackages.count - 1) {
                                        selectedIndex++
                                        pacmanPackagesList.positionViewAtIndex(selectedIndex, ListView.Center)
                                    }
                                    event.accepted = true
                                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                    if (filteredPackages.count > 0 && selectedIndex >= 0 && selectedIndex < filteredPackages.count) {
                                        var pkg = filteredPackages.get(selectedIndex)
                                        console.log("Installing package:", pkg, "name:", pkg ? pkg.name : "null")
                                        if (pkg && pkg.name) {
                                            installPacmanPackage(pkg.name)
                                        } else {
                                            console.log("Package data invalid:", pkg)
                                        }
                                    } else {
                                        console.log("No package selected or list empty. Count:", filteredPackages.count, "Selected:", selectedIndex)
                                    }
                                    event.accepted = true
                                } else if (event.key === Qt.Key_Escape) {
                                    currentPackageMode = 0
                                    installSourceMode = -1
                                    selectedIndex = 0
                                    event.accepted = true
                                } else {
                                    // Pozwól na normalne wpisywanie tekstu
                                    event.accepted = false
                                }
                            }
                        }
                        
                        Text {
                            anchors.fill: pacmanSearchInput
                            anchors.margins: 0
                            text: "Search packages (pacman)..."
                            font.pixelSize: 14
                            font.family: "JetBrains Mono"
                            color: (sharedData && sharedData.colorText) ? Qt.lighter(sharedData.colorText, 1.5) : "#666666"
                            verticalAlignment: Text.AlignVCenter
                            visible: pacmanSearchInput.text.length === 0
                            z: 5
                        }
                    }
                    
                    // Lista pakietów
                    ListView {
                        id: pacmanPackagesList
                        width: parent.width
                        height: parent.height - pacmanSearchBox.height - parent.spacing
                        clip: true
                        
                        model: filteredPackages
                        
                        delegate: Rectangle {
                            id: packageItem
                            width: pacmanPackagesList.width
                            height: 72
                            color: "transparent"
                            radius: 0
                            scale: (selectedIndex === index || packageItemMouseArea.containsMouse) ? 1.02 : 1.0

                            // Bottom accent line for selected items
                            Rectangle {
                                anchors.bottom: parent.bottom
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: selectedIndex === index ? parent.width * 0.8 : 0
                                height: 3
                                color: (sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff"
                                radius: 1.5

                                Behavior on width {
                                    NumberAnimation {
                                        duration: 300
                                        easing.type: Easing.OutCubic
                                    }
                                }
                            }
                    
                    Behavior on scale {
                        NumberAnimation {
                            duration: 200
                            easing.type: Easing.OutCubic
                        }
                            }
                            
                            property string packageName: model.name || "Unknown"
                            property string packageDescription: model.description || ""
                            
                            Column {
                                anchors.left: parent.left
                                anchors.leftMargin: 20
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 4
                                
                                Text {
                                    text: packageItem.packageName
                                    font.pixelSize: 15
                                    font.family: "JetBrains Mono"
                                    font.weight: selectedIndex === index ? Font.Bold : Font.Medium
                                    color: selectedIndex === index ? colorText : ((sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff")
                                }
                                
                                Text {
                                    text: packageItem.packageDescription
                                    font.pixelSize: 12
                                    font.family: "JetBrains Mono"
                                    color: (sharedData && sharedData.colorText) ? sharedData.colorText : colorText
                                    opacity: selectedIndex === index ? 0.85 : (packageItemMouseArea.containsMouse ? 0.75 : 0.6)
                                    visible: packageItem.packageDescription && packageItem.packageDescription.length > 0
                                }
                            }
                            
                            MouseArea {
                                id: packageItemMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                
                                onEntered: {
                                    selectedIndex = index
                                }
                                
                                onClicked: {
                                    if (packageItem.packageName) {
                                        installPacmanPackage(packageItem.packageName)
                                    }
                                }
                            }
                        }
                        
                        highlight: Rectangle {
                            color: (sharedData && sharedData.colorPrimary) ? sharedData.colorPrimary : colorPrimary
                            radius: 0
                        }
                    }
                }
            }
            
            // Wyszukiwarka pakietów AUR (gdy currentPackageMode === 2)
            Item {
                id: aurSearchMode
                anchors.fill: parent
                anchors.margins: 20
                visible: currentMode === 1 && currentPackageMode === 2
                
                Column {
                    id: aurSearchColumn
                    anchors.fill: parent
                    spacing: 11
                    
                    // Pole wyszukiwania
                    Rectangle {
                        id: aurSearchBox
                        width: parent.width
                        height: 48
                        color: aurSearchInput.activeFocus ? colorPrimary : colorSecondary
                        radius: 0
                        
                        Behavior on color {
                            ColorAnimation { duration: 180; easing.type: Easing.OutQuart }
                        }
                        
                        TextInput {
                            id: aurSearchInput
                            anchors.fill: parent
                            anchors.margins: 20
                            font.pixelSize: 14
                            font.family: "JetBrains Mono"
                            color: colorText
                            verticalAlignment: TextInput.AlignVCenter
                            z: 10
                            selectByMouse: true
                            activeFocusOnPress: true
                            focus: (currentPackageMode === 1 && sharedData && sharedData.launcherVisible)
                            
                            onTextChanged: {
                                packageSearchText = text
                                selectedIndex = 0
                                if (text.length >= 2) {
                                    searchAurPackages(text)
                                } else {
                                    filteredPackages.clear()
                                }
                            }
                            
                            Keys.onPressed: function(event) {
                                if (event.key === Qt.Key_Up) {
                                    if (selectedIndex > 0) {
                                        selectedIndex--
                                        aurPackagesList.positionViewAtIndex(selectedIndex, ListView.Center)
                                    }
                                    event.accepted = true
                                } else if (event.key === Qt.Key_Down) {
                                    if (selectedIndex < filteredPackages.count - 1) {
                                        selectedIndex++
                                        aurPackagesList.positionViewAtIndex(selectedIndex, ListView.Center)
                                    }
                                    event.accepted = true
                                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                    if (filteredPackages.count > 0 && selectedIndex >= 0 && selectedIndex < filteredPackages.count) {
                                        var pkg = filteredPackages.get(selectedIndex)
                                        console.log("Installing AUR package:", pkg, "name:", pkg ? pkg.name : "null")
                                        if (pkg && pkg.name) {
                                            installAurPackage(pkg.name)
                                        } else {
                                            console.log("Package data invalid:", pkg)
                                        }
                                    } else {
                                        console.log("No package selected or list empty. Count:", filteredPackages.count, "Selected:", selectedIndex)
                                    }
                                    event.accepted = true
                                } else if (event.key === Qt.Key_Escape) {
                                    currentPackageMode = 0
                                    installSourceMode = -1
                                    selectedIndex = 0
                                    event.accepted = true
                                } else {
                                    // Pozwól na normalne wpisywanie tekstu
                                    event.accepted = false
                                }
                            }
                        }
                        
                        Text {
                            anchors.fill: aurSearchInput
                            anchors.margins: 0
                            text: "Search packages (AUR)..."
                            font.pixelSize: 14
                            font.family: "JetBrains Mono"
                            color: (sharedData && sharedData.colorText) ? Qt.lighter(sharedData.colorText, 1.5) : "#666666"
                            verticalAlignment: Text.AlignVCenter
                            visible: aurSearchInput.text.length === 0
                            z: 5
                        }
                    }
                    
                    // Lista pakietów AUR
                    ListView {
                        id: aurPackagesList
                        width: parent.width
                        height: parent.height - aurSearchBox.height - parent.spacing
                        clip: true
                        
                        model: filteredPackages
                        
                        delegate: Rectangle {
                            id: aurPackageItem
                            width: aurPackagesList.width
                            height: 72
                            color: "transparent"
                            radius: 0
                            scale: (selectedIndex === index || aurPackageItemMouseArea.containsMouse) ? 1.02 : 1.0

                            // Bottom accent line for selected items
                            Rectangle {
                                anchors.bottom: parent.bottom
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: selectedIndex === index ? parent.width * 0.8 : 0
                                height: 3
                                color: (sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff"
                                radius: 1.5

                                Behavior on width {
                                    NumberAnimation {
                                        duration: 300
                                        easing.type: Easing.OutCubic
                                    }
                                }
                            }
                            
                            Behavior on color {
                        ColorAnimation { 
                            duration: 200
                            easing.type: Easing.OutCubic
                        }
                    }
                    
                    Behavior on scale {
                        NumberAnimation {
                            duration: 200
                            easing.type: Easing.OutCubic
                        }
                            }
                            
                            property string packageName: model.name || "Unknown"
                            property string packageDescription: model.description || ""
                            
                            Column {
                                anchors.left: parent.left
                                anchors.leftMargin: 20
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 4
                                
                                Text {
                                    text: aurPackageItem.packageName
                                    font.pixelSize: 15
                                    font.family: "JetBrains Mono"
                                    font.weight: selectedIndex === index ? Font.Bold : Font.Medium
                                    color: selectedIndex === index ? colorText : ((sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff")
                                }
                                
                                Text {
                                    text: aurPackageItem.packageDescription
                                    font.pixelSize: 12
                                    font.family: "JetBrains Mono"
                                    color: (sharedData && sharedData.colorText) ? sharedData.colorText : colorText
                                    opacity: selectedIndex === index ? 0.85 : (aurPackageItemMouseArea.containsMouse ? 0.75 : 0.6)
                                    visible: aurPackageItem.packageDescription && aurPackageItem.packageDescription.length > 0
                                }
                            }
                            
                            MouseArea {
                                id: aurPackageItemMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                
                                onEntered: {
                                    selectedIndex = index
                                }
                                
                                onClicked: {
                                    if (aurPackageItem.packageName) {
                                        installAurPackage(aurPackageItem.packageName)
                                    }
                                }
                            }
                        }
                        
                        highlight: Rectangle {
                            color: (sharedData && sharedData.colorPrimary) ? sharedData.colorPrimary : colorPrimary
                            radius: 0
                        }
                    }
                }
            }
            
            // Wybór źródła usuwania (Pacman/AUR) - gdy currentPackageMode === 3
            ListView {
                id: removeSourceList
                anchors.fill: parent
                anchors.margins: 20
                visible: currentMode === 1 && currentPackageMode === 3
                clip: true
                z: 1
                model: ListModel {
                    id: removeSourceModel
                    ListElement { name: "Pacman"; description: "Remove from official repositories"; source: "pacman"; icon: "󰏖" }
                    ListElement { name: "AUR"; description: "Remove from AUR"; source: "aur"; icon: "󰣇" }
                }
                
                delegate: Rectangle {
                    id: removeSourceItem
                    width: removeSourceList.width
                    height: 72
                    color: "transparent"
                    radius: 0
                    scale: (selectedIndex === index || removeSourceItemMouseArea.containsMouse) ? 1.02 : 1.0

                    // Bottom accent line for selected items
                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: selectedIndex === index ? parent.width * 0.8 : 0
                        height: 3
                        color: (sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff"
                        radius: 1.5

                        Behavior on width {
                            NumberAnimation {
                                duration: 300
                                easing.type: Easing.OutCubic
                            }
                        }
                    }
                    
                    Behavior on color {
                        ColorAnimation { 
                            duration: 200
                            easing.type: Easing.OutCubic
                        }
                    }
                    
                    Behavior on scale {
                        NumberAnimation {
                            duration: 200
                            easing.type: Easing.OutCubic
                        }
                    }
                    
                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: 20
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 16
                        
                        Text {
                            text: model.icon || ""
                            font.pixelSize: 22
                            color: (sharedData && sharedData.colorText) ? sharedData.colorText : colorText
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 4
                            
                            Text {
                                text: model.name || "Unknown"
                                font.pixelSize: 15
                                font.family: "JetBrains Mono"
                                font.weight: selectedIndex === index ? Font.Bold : Font.Medium
                                color: selectedIndex === index ? colorText : ((sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff")
                            }
                            
                            Text {
                                text: model.description || ""
                                font.pixelSize: 12
                                font.family: "JetBrains Mono"
                                color: (sharedData && sharedData.colorText) ? sharedData.colorText : colorText
                                opacity: selectedIndex === index ? 0.85 : (removeSourceItemMouseArea.containsMouse ? 0.75 : 0.6)
                            }
                        }
                    }
                    
                    MouseArea {
                        id: removeSourceItemMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        
                        onEntered: {
                            selectedIndex = index
                        }
                        
                        onClicked: {
                            if (model.source === "pacman") {
                                // Przełącz na tryb usuwania Pacman
                                currentPackageMode = 4
                                removeSourceMode = 0
                                selectedIndex = 0
                                packageSearchText = ""
                                loadInstalledPackages()
                                // Ustaw focus na pole wyszukiwania
                                Qt.createQmlObject("import QtQuick; Timer { interval: 100; running: true; repeat: false; onTriggered: appLauncherRoot.removeSearchInput.forceActiveFocus() }", appLauncherRoot)
                            } else if (model.source === "aur") {
                                // Przełącz na tryb usuwania AUR
                                currentPackageMode = 5
                                removeSourceMode = 1
                                selectedIndex = 0
                                packageSearchText = ""
                                loadInstalledPackages()
                                // Ustaw focus na pole wyszukiwania
                                Qt.createQmlObject("import QtQuick; Timer { interval: 100; running: true; repeat: false; onTriggered: appLauncherRoot.removeAurSearchInput.forceActiveFocus() }", appLauncherRoot)
                            }
                        }
                    }
                }
                
                highlight: Rectangle {
                    color: colorPrimary
                    radius: 0
                    
                    Behavior on color {
                        ColorAnimation { duration: 180; easing.type: Easing.OutQuart }
                    }
                }
            }
            
            // Wyszukiwarka zainstalowanych pakietów do usunięcia z Pacman (gdy currentPackageMode === 4)
            Item {
                id: removeSearchMode
                anchors.fill: parent
                anchors.margins: 20
                visible: currentMode === 1 && currentPackageMode === 4
                
                Column {
                    id: removeSearchColumn
                    anchors.fill: parent
                    spacing: 11
                    
                    // Pole wyszukiwania
                    Rectangle {
                        id: removeSearchBox
                        width: parent.width
                        height: 48
                        color: removeSearchInput.activeFocus ? colorPrimary : colorSecondary
                        radius: 0
                        
                        Behavior on color {
                            ColorAnimation { duration: 180; easing.type: Easing.OutQuart }
                        }
                        
                        TextInput {
                            id: removeSearchInput
                            anchors.fill: parent
                            anchors.margins: 20
                            font.pixelSize: 14
                            font.family: "JetBrains Mono"
                            color: colorText
                            verticalAlignment: TextInput.AlignVCenter
                            z: 10
                            selectByMouse: true
                            activeFocusOnPress: true
                            focus: (currentPackageMode === 4 && sharedData && sharedData.launcherVisible)
                            
                            onTextChanged: {
                                packageSearchText = text
                                selectedIndex = 0
                                filterInstalledPackages()
                            }
                            
                            Keys.onPressed: function(event) {
                                if (event.key === Qt.Key_Up) {
                                    if (selectedIndex > 0) {
                                        selectedIndex--
                                        removePackagesList.positionViewAtIndex(selectedIndex, ListView.Center)
                                    }
                                    event.accepted = true
                                } else if (event.key === Qt.Key_Down) {
                                    if (selectedIndex < filteredInstalledPackages.count - 1) {
                                        selectedIndex++
                                        removePackagesList.positionViewAtIndex(selectedIndex, ListView.Center)
                                    }
                                    event.accepted = true
                                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                    if (filteredInstalledPackages.count > 0 && selectedIndex >= 0 && selectedIndex < filteredInstalledPackages.count) {
                                        var pkg = filteredInstalledPackages.get(selectedIndex)
                                        console.log("Removing package:", pkg, "name:", pkg ? pkg.name : "null")
                                        if (pkg && pkg.name) {
                                            if (currentPackageMode === 4) {
                                            removePacmanPackage(pkg.name)
                                            } else if (currentPackageMode === 5) {
                                                removeAurPackage(pkg.name)
                                            }
                                        } else {
                                            console.log("Package data invalid:", pkg)
                                        }
                                    } else {
                                        console.log("No package selected or list empty. Count:", filteredInstalledPackages.count, "Selected:", selectedIndex)
                                    }
                                    event.accepted = true
                                } else if (event.key === Qt.Key_Escape) {
                                    currentPackageMode = 3
                                    removeSourceMode = -1
                                    selectedIndex = 0
                                    event.accepted = true
                                } else {
                                    // Pozwól na normalne wpisywanie tekstu
                                    event.accepted = false
                                }
                            }
                        }
                        
                        Text {
                            anchors.fill: removeSearchInput
                            anchors.margins: 0
                            text: "Search installed packages..."
                            font.pixelSize: 14
                            font.family: "JetBrains Mono"
                            color: (sharedData && sharedData.colorText) ? Qt.lighter(sharedData.colorText, 1.5) : "#666666"
                            verticalAlignment: Text.AlignVCenter
                            visible: removeSearchInput.text.length === 0
                            z: 5
                        }
                    }
                    
                    // Lista zainstalowanych pakietów
                    ListView {
                        id: removePackagesList
                        width: parent.width
                        height: parent.height - removeSearchBox.height - parent.spacing
                        clip: true
                        
                        model: filteredInstalledPackages
                        
                        delegate: Rectangle {
                            id: installedPackageItem
                            width: removePackagesList.width
                            height: 72
                            color: "transparent"
                            radius: 0
                            scale: (selectedIndex === index || installedPackageItemMouseArea.containsMouse) ? 1.02 : 1.0

                            // Bottom accent line for selected items
                            Rectangle {
                                anchors.bottom: parent.bottom
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: selectedIndex === index ? parent.width * 0.8 : 0
                                height: 3
                                color: (sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff"
                                radius: 1.5

                                Behavior on width {
                                    NumberAnimation {
                                        duration: 300
                                        easing.type: Easing.OutCubic
                                    }
                                }
                            }
                    
                    Behavior on scale {
                        NumberAnimation {
                            duration: 200
                            easing.type: Easing.OutCubic
                        }
                            }
                            
                            property string packageName: model.name || "Unknown"
                            property string packageVersion: model.version || ""
                            
                            Column {
                                anchors.left: parent.left
                                anchors.leftMargin: 20
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 4
                                
                                Text {
                                    text: installedPackageItem.packageName
                                    font.pixelSize: 15
                                    font.family: "JetBrains Mono"
                                    font.weight: selectedIndex === index ? Font.Bold : Font.Medium
                                    color: selectedIndex === index ? colorText : ((sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff")
                                }
                                
                                Text {
                                    text: installedPackageItem.packageVersion
                                    font.pixelSize: 12
                                    font.family: "JetBrains Mono"
                                    color: (sharedData && sharedData.colorText) ? sharedData.colorText : colorText
                                    opacity: selectedIndex === index ? 0.85 : (installedPackageItemMouseArea.containsMouse ? 0.75 : 0.6)
                                    visible: installedPackageItem.packageVersion && installedPackageItem.packageVersion.length > 0
                                }
                            }
                            
                            MouseArea {
                                id: installedPackageItemMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                
                                onEntered: {
                                    selectedIndex = index
                                }
                                
                                onClicked: {
                                    if (installedPackageItem.packageName) {
                                            if (currentPackageMode === 4) {
                                        removePacmanPackage(installedPackageItem.packageName)
                                            } else if (currentPackageMode === 5) {
                                                removeAurPackage(installedPackageItem.packageName)
                                            }
                                        }
                                    }
                            }
                        }
                        
                        highlight: Rectangle {
                            color: (sharedData && sharedData.colorPrimary) ? sharedData.colorPrimary : colorPrimary
                            radius: 0
                        }
                    }
                }
            }
            
            // Wyszukiwarka zainstalowanych pakietów do usunięcia z AUR (gdy currentPackageMode === 5)
            Item {
                id: removeAurSearchMode
                anchors.fill: parent
                anchors.margins: 20
                visible: currentMode === 1 && currentPackageMode === 5
                
                Column {
                    id: removeAurSearchColumn
                    anchors.fill: parent
                    spacing: 11
                    
                    // Pole wyszukiwania
                    Rectangle {
                        id: removeAurSearchBox
                        width: parent.width
                        height: 48
                        color: removeAurSearchInput.activeFocus ? colorPrimary : colorSecondary
                        radius: 0
                        
                        Behavior on color {
                            ColorAnimation { duration: 180; easing.type: Easing.OutQuart }
                        }
                        
                        TextInput {
                            id: removeAurSearchInput
                            anchors.fill: parent
                            anchors.margins: 20
                            font.pixelSize: 14
                            font.family: "JetBrains Mono"
                            color: colorText
                            verticalAlignment: TextInput.AlignVCenter
                            z: 10
                            selectByMouse: true
                            activeFocusOnPress: true
                            focus: (currentPackageMode === 5 && sharedData && sharedData.launcherVisible)
                            
                            onTextChanged: {
                                packageSearchText = text
                                selectedIndex = 0
                                filterInstalledPackages()
                            }
                            
                            Keys.onPressed: function(event) {
                                if (event.key === Qt.Key_Up) {
                                    if (selectedIndex > 0) {
                                        selectedIndex--
                                        removeAurPackagesList.positionViewAtIndex(selectedIndex, ListView.Center)
                                    }
                                    event.accepted = true
                                } else if (event.key === Qt.Key_Down) {
                                    if (selectedIndex < filteredInstalledPackages.count - 1) {
                                        selectedIndex++
                                        removeAurPackagesList.positionViewAtIndex(selectedIndex, ListView.Center)
                                    }
                                    event.accepted = true
                                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                    if (filteredInstalledPackages.count > 0 && selectedIndex >= 0 && selectedIndex < filteredInstalledPackages.count) {
                                        var pkg = filteredInstalledPackages.get(selectedIndex)
                                        console.log("Removing AUR package:", pkg, "name:", pkg ? pkg.name : "null")
                                        if (pkg && pkg.name) {
                                            removeAurPackage(pkg.name)
                                        } else {
                                            console.log("Package data invalid:", pkg)
                                        }
                                    } else {
                                        console.log("No package selected or list empty. Count:", filteredInstalledPackages.count, "Selected:", selectedIndex)
                                    }
                                    event.accepted = true
                                } else if (event.key === Qt.Key_Escape) {
                                    currentPackageMode = 3
                                    removeSourceMode = -1
                                    selectedIndex = 0
                                    event.accepted = true
                                } else {
                                    // Pozwól na normalne wpisywanie tekstu
                                    event.accepted = false
                                }
                            }
                        }
                        
                        Text {
                            anchors.fill: removeAurSearchInput
                            anchors.margins: 0
                            text: "Search installed AUR packages..."
                            font.pixelSize: 14
                            font.family: "JetBrains Mono"
                            color: (sharedData && sharedData.colorText) ? Qt.lighter(sharedData.colorText, 1.5) : "#666666"
                            verticalAlignment: Text.AlignVCenter
                            visible: removeAurSearchInput.text.length === 0
                            z: 5
                        }
                    }
                    
                    // Lista zainstalowanych pakietów AUR
                    ListView {
                        id: removeAurPackagesList
                        width: parent.width
                        height: parent.height - removeAurSearchBox.height - parent.spacing
                        clip: true
                        
                        model: filteredInstalledPackages
                        
                        delegate: Rectangle {
                            id: installedAurPackageItem
                            width: removeAurPackagesList.width
                            height: 72
                            color: "transparent"
                            radius: 0
                            scale: (selectedIndex === index || installedAurPackageItemMouseArea.containsMouse) ? 1.02 : 1.0

                            // Bottom accent line for selected items
                            Rectangle {
                                anchors.bottom: parent.bottom
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: selectedIndex === index ? parent.width * 0.8 : 0
                                height: 3
                                color: (sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff"
                                radius: 1.5

                                Behavior on width {
                                    NumberAnimation {
                                        duration: 300
                                        easing.type: Easing.OutCubic
                                    }
                                }
                            }
                            
                            Behavior on color {
                        ColorAnimation { 
                            duration: 180
                            easing.type: Easing.OutQuart
                        }
                    }
                    
                    Behavior on scale {
                        NumberAnimation {
                            duration: 180
                            easing.type: Easing.OutQuart
                        }
                            }
                            
                            property string packageName: model.name || "Unknown"
                            property string packageVersion: model.version || ""
                            
                            Column {
                                anchors.left: parent.left
                                anchors.leftMargin: 20
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 4
                                
                                Text {
                                    text: installedAurPackageItem.packageName
                                    font.pixelSize: 14
                                    font.family: "JetBrains Mono"
                                    font.weight: Font.Medium
                                    color: selectedIndex === index ? colorText : ((sharedData && sharedData.colorText) ? Qt.lighter(sharedData.colorText, 1.3) : "#cccccc")
                                }
                                
                                Text {
                                    text: installedAurPackageItem.packageVersion
                                    font.pixelSize: 11
                                    font.family: "JetBrains Mono"
                                    color: (sharedData && sharedData.colorText) ? sharedData.colorText : colorText
                                    visible: installedAurPackageItem.packageVersion && installedAurPackageItem.packageVersion.length > 0
                                }
                            }
                            
                            MouseArea {
                                id: installedAurPackageItemMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                
                                onEntered: {
                                    selectedIndex = index
                                }
                                
                                onClicked: {
                                    if (installedAurPackageItem.packageName) {
                                        removeAurPackage(installedAurPackageItem.packageName)
                                    }
                                }
                            }
                        }
                        
                        highlight: Rectangle {
                            color: (sharedData && sharedData.colorPrimary) ? sharedData.colorPrimary : colorPrimary
                            radius: 0
                        }
                    }
                }
            }
            
            // Tryb 2: Settings
            Item {
                id: settingsMode
                anchors.fill: parent
                visible: currentMode === 2
                enabled: true
                z: 1
                
                // Lista ustawień (jedna prosta lista)
                ListView {
                    id: settingsList
                    anchors.fill: parent
                    anchors.margins: 20
                    visible: currentSettingsMode === -1
                    clip: true
                    
                    model: ListModel {
                        id: settingsModel
                        ListElement { name: "Wallpaper"; description: "Change wallpaper with swww"; icon: "󰸉"; settingId: 0 }
                        ListElement { name: "Toggle Sidebar"; description: "Show or hide sidebar"; icon: "󰍁"; settingId: 1 }
                        ListElement { name: "Sidebar Position"; description: "Change sidebar position (left/top)"; icon: "󰍇"; settingId: 6 }
                        ListElement { name: "Colors"; description: "Customize color theme"; icon: "󰏘"; settingId: 3 }
                    }
                    
                    delegate: Rectangle {
                        width: settingsList.width
                        height: 72
                        color: "transparent"

                        // Bottom accent line for selected items
                        Rectangle {
                            anchors.bottom: parent.bottom
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: selectedIndex === index ? parent.width * 0.8 : 0
                            height: 3
                            color: (sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff"
                            radius: 1.5

                            Behavior on width {
                                NumberAnimation {
                                    duration: 300
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }
                        
                        Row {
                            anchors.left: parent.left
                            anchors.leftMargin: 20
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 16
                            
                            Text {
                                text: model.icon
                                font.pixelSize: 22
                                color: (selectedIndex === index) ? ((sharedData && sharedData.colorText) ? sharedData.colorText : colorText) : ((sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff")
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            
                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 4
                                
                                Text {
                                    text: model.name
                                    font.pixelSize: 15
                                    font.family: "JetBrains Mono"
                                    font.weight: selectedIndex === index ? Font.Bold : Font.Medium
                                    color: (selectedIndex === index) ? ((sharedData && sharedData.colorText) ? sharedData.colorText : colorText) : ((sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff")
                                }
                                
                                Text {
                                    text: model.description
                                    font.pixelSize: 12
                                    font.family: "JetBrains Mono"
                                    color: ((sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff")
                                    opacity: selectedIndex === index ? 0.85 : (settingsItemMouseArea.containsMouse ? 0.75 : 0.6)
                                }
                            }
                        }
                        
                        MouseArea {
                            id: settingsItemMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            
                            onEntered: {
                                selectedIndex = index
                            }
                            
                            onClicked: {
                                if (model.settingId === 1) {
                                    // Toggle Sidebar - immediate action, no submenu
                                    if (sharedData && sharedData.sidebarVisible !== undefined) {
                                        sharedData.sidebarVisible = !sharedData.sidebarVisible
                                        console.log("Sidebar toggled to:", sharedData.sidebarVisible)
                                    }
                                    // Close launcher after toggle
                                    if (sharedData) {
                                        sharedData.launcherVisible = false
                                    }
                                } else if (model.settingId === 6) {
                                    // Toggle Sidebar Position - immediate action, no submenu
                                    if (sharedData && sharedData.sidebarPosition !== undefined) {
                                        sharedData.sidebarPosition = (sharedData.sidebarPosition === "left") ? "top" : "left"
                                        console.log("Sidebar position changed to:", sharedData.sidebarPosition)
                                    }
                                    // Close launcher after toggle
                                    if (sharedData) {
                                        sharedData.launcherVisible = false
                                    }
                                } else {
                                    currentSettingsMode = model.settingId
                                    if (model.settingId === 0) {
                                        loadWallpapers()
                                        wallpaperSelectedIndex = 0
                                        wallpapersGrid.currentIndex = 0
                                    } else if (model.settingId === 3) {
                                        // Colors - no action needed
                                    }
                                }
                            }
                        }
                    }
                }
                
                // Wallpaper picker
                Item {
                    id: wallpaperPicker
                    anchors.fill: parent
                    visible: currentSettingsMode === 0
                    
                    // Grid z tapetami
                    GridView {
                        id: wallpapersGrid
                        anchors.fill: parent
                        anchors.margins: 20
                        cellWidth: Math.floor(width / 3)  // 3 tapety w rzędzie
                        cellHeight: 124  // 95 * 1.3 = 123.5, rounded to 124 (30% taller)
                        clip: true
                        
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
                                width: parent.width - 8
                                height: parent.height - 8
                                color: (wallpaperItemMouseArea.containsMouse || wallpapersGrid.currentIndex === index) ? colorPrimary : colorBackground
                                scale: (wallpaperItemMouseArea.containsMouse || wallpapersGrid.currentIndex === index) ? 1.05 : 1.0
                                
                                Behavior on color {
                                    ColorAnimation {
                                        duration: 180
                                        easing.type: Easing.OutQuart
                                    }
                                }
                                
                                Behavior on scale {
                                    NumberAnimation {
                                        duration: 180
                                        easing.type: Easing.OutQuart
                                    }
                                }
                                
                                // Thumbnail
                                Image {
                                    id: wallpaperThumbnail
                                    anchors.fill: parent
                                    anchors.margins: 2
                                    source: "file://" + model.path
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                    cache: true
                                    sourceSize.width: 300
                                    sourceSize.height: 200
                                    
                                    // Loading indicator
                                    Rectangle {
                                        anchors.fill: parent
                                        color: colorPrimary
                                        visible: wallpaperThumbnail.status === Image.Loading
                                        
                                        Text {
                                            text: "󰔟"
                                            font.pixelSize: 24
                                            color: "#444444"
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
                    }
                    
                    // Empty state
                    Column {
                        anchors.centerIn: parent
                        spacing: 10
                        visible: wallpapersModel.count === 0
                        
                        Text {
                            text: "󰸉"
                            font.pixelSize: 48
                            color: "#333333"
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                        
                        Text {
                            text: "No wallpapers found"
                            font.pixelSize: 14
                            font.family: "JetBrains Mono"
                            color: (sharedData && sharedData.colorText) ? Qt.lighter(sharedData.colorText, 1.5) : "#666666"
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                        
                        Text {
                            text: "Add images to ~/Pictures/Wallpapers"
                            font.pixelSize: 11
                            font.family: "JetBrains Mono"
                            color: "#444444"
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }
                }
                
                // Bluetooth manager
                Item {
                    id: bluetoothManager
                    anchors.fill: parent
                    visible: currentSettingsMode === 2
                    
                    // Header
                    Rectangle {
                        id: bluetoothHeader
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: 50
                        color: "transparent"
                        
                        Row {
                            anchors.fill: parent
                            anchors.margins: 20
                            spacing: 12
                            
                            // Back button
                            Rectangle {
                                width: 30
                                height: 30
                                color: bluetoothBackMouseArea.containsMouse ? colorPrimary : "transparent"
                                radius: 0
                                anchors.verticalCenter: parent.verticalCenter
                                
                                Text {
                                    text: "󰁍"
                                    font.pixelSize: 18
                                    color: colorText
                                    anchors.centerIn: parent
                                }
                                
                                MouseArea {
                                    id: bluetoothBackMouseArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        currentSettingsMode = -1  // Back to Settings list
                                        selectedIndex = 0
                                    }
                                }
                            }
                            
                            Text {
                                text: "Bluetooth"
                                font.pixelSize: 18
                                font.family: "JetBrains Mono"
                                font.weight: Font.Bold
                                color: colorText
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                    }
                    
                    // Content
                    Column {
                        anchors.top: bluetoothHeader.bottom
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.margins: 20
                        spacing: 16
                        
                        // Toggle switch
                        Row {
                            width: parent.width
                            spacing: 12
                            
                            Text {
                                text: "Power"
                                font.pixelSize: 14
                                font.family: "JetBrains Mono"
                                font.weight: Font.Medium
                                color: colorText
                            }
                            
                            Rectangle {
                                width: 50
                                height: 26
                                color: bluetoothEnabled ? "#4a9eff" : "#333333"
                                radius: 0
                                
                                Rectangle {
                                    width: 22
                                    height: 22
                                    radius: 0
                                    color: colorText
                                    y: (parent.height - height) / 2
                                    x: bluetoothEnabled ? parent.width - width - 2 : 2
                                    
                                    Behavior on x {
                                        NumberAnimation {
                                            duration: 200
                                            easing.type: Easing.OutQuart
                                        }
                                    }
                                }
                                
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: toggleBluetooth()
                                }
                                
                                Behavior on color {
                                    ColorAnimation {
                                        duration: 180
                                        easing.type: Easing.OutQuart
                                    }
                                }
                            }
                            
                            Text {
                                text: bluetoothEnabled ? "ON" : "OFF"
                                font.pixelSize: 12
                                font.family: "JetBrains Mono"
                                color: bluetoothEnabled ? ((sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff") : ((sharedData && sharedData.colorText) ? Qt.lighter(sharedData.colorText, 1.5) : "#666666")
                            }
                        }
                        
                        // Scan button
                        Rectangle {
                            width: parent.width
                            height: 40
                            color: bluetoothScanButtonArea.containsMouse ? colorPrimary : colorSecondary
                            visible: bluetoothEnabled
                            
                            Row {
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 8
                                
                                Text {
                                    text: bluetoothScanning ? "󰤻" : "󰤾"
                                    font.pixelSize: 16
                                    color: colorText
                                }
                                
                                Text {
                                    text: bluetoothScanning ? "Scanning..." : "Scan for devices"
                                    font.pixelSize: 13
                                    font.family: "JetBrains Mono"
                                    color: colorText
                                }
                            }
                            
                            MouseArea {
                                id: bluetoothScanButtonArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                enabled: !bluetoothScanning
                                onClicked: scanBluetoothDevices()
                            }
                            
                            Behavior on color {
                                ColorAnimation {
                                    duration: 200
                                    easing.type: Easing.OutQuart
                                }
                            }
                        }
                        
                        // Devices list
                        ListView {
                            id: bluetoothDevicesList
                            width: parent.width
                            height: parent.height - 100
                            visible: bluetoothEnabled
                            clip: true
                            
                            model: bluetoothDevicesModel
                            currentIndex: bluetoothSelectedIndex
                            
                            onCurrentIndexChanged: {
                                bluetoothSelectedIndex = currentIndex
                            }
                            
                            delegate: Rectangle {
                                width: bluetoothDevicesList.width
                                height: 50
                                color: (bluetoothDeviceMouseArea.containsMouse || bluetoothDevicesList.currentIndex === index) ? "#1a1a1a" : "transparent"
                                
                                Row {
                                    width: parent.width - 24
                                    height: parent.height
                                    anchors.left: parent.left
                                    anchors.leftMargin: 20
                                    spacing: 12
                                    
                                    Text {
                                        text: "󰂱"
                                        font.pixelSize: 20
                                        color: (sharedData && sharedData.colorText) ? sharedData.colorText : colorText
                                    }
                                    
                                    Column {
                                        spacing: 2
                                        width: parent.width - 100
                                        
                                        Text {
                                            text: model.name
                                            font.pixelSize: 13
                                            font.family: "JetBrains Mono"
                                            font.weight: Font.Medium
                                            color: colorText
                                            elide: Text.ElideRight
                                            width: parent.width
                                        }
                                        
                                        Text {
                                            text: model.mac
                                            font.pixelSize: 10
                                            font.family: "JetBrains Mono"
                                            color: (sharedData && sharedData.colorText) ? sharedData.colorText : colorText
                                        }
                                    }
                                    
                                    Rectangle {
                                        width: 60
                                        height: 28
                                        color: bluetoothConnectArea.containsMouse ? "#4a9eff" : "#333333"
                                        
                                        Text {
                                            text: bluetoothConnecting ? "..." : "Connect"
                                            font.pixelSize: 10
                                            font.family: "JetBrains Mono"
                                            color: colorText
                                            anchors.centerIn: parent
                                        }
                                        
                                        MouseArea {
                                            id: bluetoothConnectArea
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            enabled: !bluetoothConnecting
                                            onClicked: connectBluetoothDevice(model.mac)
                                        }
                                        
                                        Behavior on color {
                                            ColorAnimation {
                                                duration: 200
                                                easing.type: Easing.OutQuart
                                            }
                                        }
                                    }
                                }
                                
                                MouseArea {
                                    id: bluetoothDeviceMouseArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                }
                            }
                        }
                        
                        // Empty state
                        Column {
                            anchors.centerIn: parent
                            spacing: 10
                            visible: !bluetoothEnabled || bluetoothDevicesModel.count === 0
                            
                            Text {
                                text: "󰂯"
                                font.pixelSize: 48
                                color: "#333333"
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                            
                            Text {
                                text: bluetoothEnabled ? "No devices found" : "Bluetooth is off"
                                font.pixelSize: 14
                                font.family: "JetBrains Mono"
                                color: (sharedData && sharedData.colorText) ? sharedData.colorText : colorText
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                            
                            Text {
                                text: bluetoothEnabled ? "Click 'Scan for devices' to search" : "Turn on Bluetooth to scan"
                                font.pixelSize: 11
                                font.family: "JetBrains Mono"
                                color: "#444444"
                                anchors.horizontalCenter: parent.horizontalCenter
                                visible: bluetoothEnabled
                            }
                        }
                    }
                }
                
                // Colors menu (Presets/Custom HEX selection)
                Item {
                    id: colorsMenu
                    anchors.fill: parent
                    visible: currentSettingsMode === 3
                    
                    // Colors menu list
                    ListView {
                        id: colorsMenuList
                        anchors.fill: parent
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.margins: 20
                        visible: true
                        clip: true
                        
                        model: ListModel {
                            id: colorsMenuModel
                            ListElement { name: "Presets"; description: "Choose from color presets"; icon: "󰏘"; settingId: 4 }
                            ListElement { name: "Custom HEX"; description: "Edit colors manually"; icon: "󰆍"; settingId: 5 }
                        }
                        
                        delegate: Rectangle {
                            width: colorsMenuList.width
                            height: 72
                            color: "transparent"

                            // Bottom accent line for selected items
                            Rectangle {
                                anchors.bottom: parent.bottom
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: selectedIndex === index ? parent.width * 0.8 : 0
                                height: 3
                                color: (sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff"
                                radius: 1.5

                                Behavior on width {
                                    NumberAnimation {
                                        duration: 300
                                        easing.type: Easing.OutCubic
                                    }
                                }
                            }
                            
                            Row {
                                anchors.left: parent.left
                                anchors.leftMargin: 20
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 16
                                
                                Text {
                                    text: model.icon
                                    font.pixelSize: 22
                                    color: (selectedIndex === index) ? colorText : ((sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff")
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                
                                Column {
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 4
                                    
                                    Text {
                                        text: model.name
                                        font.pixelSize: 15
                                        font.family: "JetBrains Mono"
                                        font.weight: selectedIndex === index ? Font.Bold : Font.Medium
                                        color: (selectedIndex === index) ? colorText : ((sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff")
                                    }
                                    
                                    Text {
                                        text: model.description
                                        font.pixelSize: 12
                                        font.family: "JetBrains Mono"
                                        color: (sharedData && sharedData.colorText) ? sharedData.colorText : colorText
                                        opacity: selectedIndex === index ? 0.85 : (colorsMenuMouseArea.containsMouse ? 0.75 : 0.6)
                                    }
                                }
                            }
                            
                            MouseArea {
                                id: colorsMenuMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                
                                onEntered: {
                                    selectedIndex = index
                                }
                                
                                onClicked: {
                                    currentSettingsMode = model.settingId
                                    selectedIndex = 0
                                }
                            }
                        }
                    }
                }
                
                // Presets picker
                Item {
                    id: presetsPicker
                    anchors.fill: parent
                    visible: currentSettingsMode === 4
                    enabled: true
                    z: 10
                    
                    // Content
                    Flickable {
                        anchors.fill: parent
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.margins: 20
                        clip: true
                        contentHeight: colorPickerColumn.height
                        contentWidth: width
                        
                        // Color picker items
                        Column {
                            id: colorPickerColumn
                            width: parent.width
                            spacing: 16
                            
                            // Presets section
                            Column {
                                width: parent.width
                                spacing: 12
                                
                                Text {
                                    text: "Choose a preset"
                                    font.pixelSize: 15
                                    font.family: "JetBrains Mono"
                                    font.weight: Font.Medium
                                    color: (sharedData && sharedData.colorText) ? sharedData.colorText : colorText
                                    opacity: 0.8
                                }
                                
                                // Presets grid - 2 kolumny dla lepszego layoutu
                                Grid {
                                    width: parent.width
                                    columns: 2
                                    spacing: 12
                                    
                                    Repeater {
                                        model: ["Dark", "Ocean", "Forest", "Violet", "Crimson", "Amber", "Teal", "Rose", "Sunset", "Midnight", "Emerald", "Lavender", "Sapphire", "Coral", "Mint", "Plum", "Gold", "Monochrome", "Cherry", "Azure", "Jade", "Ruby", "Indigo"]
                                        
                                        Rectangle {
                                            width: (parent.width - 12) / 2
                                            height: 90
                                            color: presetMouseArea.containsMouse ? 
                                                ((sharedData && sharedData.colorPrimary) ? sharedData.colorPrimary : colorPrimary) : 
                                                ((sharedData && sharedData.colorSecondary) ? sharedData.colorSecondary : colorSecondary)
                                            radius: 0
                                            Behavior on color {
                                                ColorAnimation {
                                                    duration: 180
                                                    easing.type: Easing.OutQuart
                                                }
                                            }
                                            
                                            scale: presetMouseArea.containsMouse ? 1.03 : 1.0
                                            
                                            Behavior on scale {
                                                NumberAnimation {
                                                    duration: 180
                                                    easing.type: Easing.OutQuart
                                                }
                                            }
                                            
                                            Row {
                                                anchors.fill: parent
                                                anchors.margins: 20
                                                spacing: 12
                                                
                                                // Duży preview kolorów
                                                Column {
                                                    width: 50
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    spacing: 4
                                                    
                                                    Rectangle {
                                                        width: 50
                                                        height: 12
                                                        radius: 0
                                                        color: {
                                                            var preset = appLauncherRoot.colorPresets[modelData]
                                                            return preset ? preset.background : "#000000"
                                                        }
                                                    }
                                                    Rectangle {
                                                        width: 50
                                                        height: 12
                                                        radius: 0
                                                        color: {
                                                            var preset = appLauncherRoot.colorPresets[modelData]
                                                            return preset ? preset.primary : "#000000"
                                                        }
                                                    }
                                                    Rectangle {
                                                        width: 50
                                                        height: 12
                                                        radius: 0
                                                        color: {
                                                            var preset = appLauncherRoot.colorPresets[modelData]
                                                            return preset ? preset.secondary : "#000000"
                                                        }
                                                    }
                                                    Rectangle {
                                                        width: 50
                                                        height: 12
                                                        radius: 0
                                                        color: {
                                                            var preset = appLauncherRoot.colorPresets[modelData]
                                                            return preset ? preset.text : "#000000"
                                                        }
                                                    }
                                                    Rectangle {
                                                        width: 50
                                                        height: 12
                                                        radius: 0
                                                        color: {
                                                            var preset = appLauncherRoot.colorPresets[modelData]
                                                            return preset ? preset.accent : "#000000"
                                                        }
                                                    }
                                                }
                                                
                                                // Nazwa i opis
                                                Column {
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    spacing: 4
                                                    width: parent.width - 50 - 12
                                                    
                                                    Text {
                                                        text: modelData
                                                        font.pixelSize: 16
                                                        font.family: "JetBrains Mono"
                                                        font.weight: Font.Bold
                                                        color: (sharedData && sharedData.colorText) ? sharedData.colorText : colorText
                                                    }
                                                    
                                                    Text {
                                                        text: {
                                                            var preset = appLauncherRoot.colorPresets[modelData]
                                                            if (!preset) return ""
                                                            return preset.background + " • " + preset.accent
                                                        }
                                                        font.pixelSize: 11
                                                        font.family: "JetBrains Mono"
                                                        color: (sharedData && sharedData.colorText) ? sharedData.colorText : colorText
                                                        opacity: 0.6
                                                    }
                                                }
                                            }
                                            
                                            MouseArea {
                                                id: presetMouseArea
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    appLauncherRoot.applyPreset(modelData)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                
                // Custom HEX picker
                Item {
                    id: customHexPicker
                    anchors.fill: parent
                    visible: currentSettingsMode === 5
                    enabled: true
                    z: 10
                    
                    // Content
                    Flickable {
                        anchors.fill: parent
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.margins: 20
                        clip: true
                        contentHeight: customHexColumn.height
                        contentWidth: width
                        
                        // Color picker items
                        Column {
                            id: customHexColumn
                            width: parent.width
                            spacing: 8
                            
                            // Background
                            Rectangle {
                                width: parent.width
                                height: 70
                                color: colorRowMouseArea1.containsMouse ? colorPrimary : "transparent"
                                radius: 0
                                
                                Behavior on color {
                                    ColorAnimation {
                                        duration: 180
                                        easing.type: Easing.OutQuart
                                    }
                                }
                                
                                Row {
                                    anchors.fill: parent
                                    anchors.margins: 16
                                    spacing: 16
                                    
                                    Rectangle {
                                        width: 44
                                        height: 44
                                        color: colorBackground
                                        radius: 0
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                    
                                    Column {
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 4
                                        width: 120
                                        
                                        Text {
                                            text: "Background"
                                            font.pixelSize: 15
                                            font.family: "JetBrains Mono"
                                            font.weight: Font.Medium
                                            color: colorText
                                        }
                                        
                                        Text {
                                            text: colorBackground
                                            font.pixelSize: 12
                                            font.family: "JetBrains Mono"
                                            color: (sharedData && sharedData.colorText) ? Qt.lighter(sharedData.colorText, 1.6) : "#999999"
                                        }
                                    }
                                    
                                    Item {
                                        width: parent.width - 44 - 16 - 16 - 120 - 16 - 120
                                        height: parent.height
                                    }
                                    
                                    Rectangle {
                                        id: colorInputRect1
                                        width: 120
                                        height: 40
                                        color: colorInput1.activeFocus ? colorSecondary : colorPrimary
                                        radius: 0
                                        anchors.verticalCenter: parent.verticalCenter
                                        Behavior on color {
                                            ColorAnimation {
                                                duration: 150
                                                easing.type: Easing.OutQuart
                                            }
                                        }
                                        
                                        TextInput {
                                            id: colorInput1
                                            anchors.fill: parent
                                            anchors.margins: 10
                                            font.pixelSize: 14
                                            font.family: "JetBrains Mono"
                                            font.weight: Font.Medium
                                            color: colorText
                                            selectByMouse: true
                                            activeFocusOnPress: true
                                            verticalAlignment: TextInput.AlignVCenter
                                            
                                            property string savedValue: ""
                                            property bool isEditing: false
                                            
                                            Component.onCompleted: {
                                                savedValue = colorBackground
                                                text = colorBackground
                                            }
                                            
                                            property bool isUpdating: false
                                            
                                            onActiveFocusChanged: {
                                                if (activeFocus) {
                                                    isEditing = true
                                                    savedValue = colorBackground
                                                    text = colorBackground
                                                    selectAll()
                                                } else {
                                                    isEditing = false
                                                }
                                            }
                                            
                                            onTextChanged: {
                                                if (isEditing && !isUpdating) {
                                                    // Zapobiegaj usunięciu # z początku
                                                    if (text.length > 0 && !text.startsWith('#')) {
                                                        isUpdating = true
                                                        var cursorPos = cursorPosition
                                                        text = '#' + text.replace(/#/g, '')
                                                        cursorPosition = Math.min(cursorPos + 1, text.length)
                                                        isUpdating = false
                                                    }
                                                }
                                            }
                                            
                                            onEditingFinished: {
                                                var newValue = normalizeHexColor(text)
                                                console.log("Editing finished, newValue:", newValue, "isValid:", isValidHexColor(newValue))
                                                if (isValidHexColor(newValue)) {
                                                    console.log("Updating color to:", newValue)
                                                    updateColor("background", newValue)
                                                    // Force update after a short delay to ensure property is updated
                                                    Qt.callLater(function() {
                                                        savedValue = newValue
                                                        text = newValue
                                                        console.log("Text updated to:", text, "colorBackground is:", colorBackground)
                                                    })
                                                } else {
                                                    console.log("Invalid color, resetting to:", savedValue)
                                                    text = savedValue
                                                }
                                            }
                                            
                                            Keys.onEnterPressed: {
                                                editingFinished()
                                            }
                                            Keys.onReturnPressed: {
                                                editingFinished()
                                            }
                                        }
                                        
                                        Connections {
                                            target: appLauncherRoot
                                            function onColorBackgroundChanged() {
                                                if (!colorInput1.isEditing && colorInput1.savedValue !== colorBackground) {
                                                    colorInput1.text = colorBackground
                                                    colorInput1.savedValue = colorBackground
                                                }
                                            }
                                        }
                                    }
                                }
                                
                                MouseArea {
                                    id: colorRowMouseArea1
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    acceptedButtons: Qt.NoButton
                                }
                            }
                            
                            // Primary
                            Rectangle {
                                width: parent.width
                                height: 70
                                color: colorRowMouseArea2.containsMouse ? colorPrimary : "transparent"
                                radius: 0
                                
                                Behavior on color {
                                    ColorAnimation {
                                        duration: 180
                                        easing.type: Easing.OutQuart
                                    }
                                }
                                
                                Row {
                                    anchors.fill: parent
                                    anchors.margins: 16
                                    spacing: 16
                                    
                                    Rectangle {
                                        width: 44
                                        height: 44
                                        color: colorPrimary
                                        radius: 0
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                    
                                    Column {
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 4
                                        width: 120
                                        
                                        Text {
                                            text: "Primary"
                                            font.pixelSize: 15
                                            font.family: "JetBrains Mono"
                                            font.weight: Font.Medium
                                            color: colorText
                                        }
                                        
                                        Text {
                                            text: colorPrimary
                                            font.pixelSize: 12
                                            font.family: "JetBrains Mono"
                                            color: (sharedData && sharedData.colorText) ? Qt.lighter(sharedData.colorText, 1.6) : "#999999"
                                        }
                                    }
                                    
                                    Item {
                                        width: parent.width - 44 - 16 - 16 - 120 - 16 - 120
                                        height: parent.height
                                    }
                                    
                                    Rectangle {
                                        id: colorInputRect2
                                        width: 120
                                        height: 40
                                        color: colorInput2.activeFocus ? colorSecondary : colorPrimary
                                        radius: 0
                                        anchors.verticalCenter: parent.verticalCenter
                                        Behavior on color {
                                            ColorAnimation {
                                                duration: 150
                                                easing.type: Easing.OutQuart
                                            }
                                        }
                                        
                                        TextInput {
                                            id: colorInput2
                                            anchors.fill: parent
                                            anchors.margins: 10
                                            font.pixelSize: 14
                                            font.family: "JetBrains Mono"
                                            font.weight: Font.Medium
                                            color: colorText
                                            selectByMouse: true
                                            activeFocusOnPress: true
                                            verticalAlignment: TextInput.AlignVCenter
                                            
                                            property string savedValue: ""
                                            property bool isEditing: false
                                            property bool isUpdating: false
                                            
                                            Component.onCompleted: {
                                                savedValue = colorPrimary
                                                text = colorPrimary
                                            }
                                            
                                            onActiveFocusChanged: {
                                                if (activeFocus) {
                                                    isEditing = true
                                                    savedValue = colorPrimary
                                                    text = colorPrimary
                                                    selectAll()
                                                } else {
                                                    isEditing = false
                                                    if (text !== colorPrimary) {
                                                        text = colorPrimary
                                                        savedValue = colorPrimary
                                                    }
                                                }
                                            }
                                            
                                            onTextChanged: {
                                                if (isEditing && !isUpdating) {
                                                    // Zapobiegaj usunięciu # z początku
                                                    if (text.length > 0 && !text.startsWith('#')) {
                                                        isUpdating = true
                                                        var cursorPos = cursorPosition
                                                        text = '#' + text.replace(/#/g, '')
                                                        cursorPosition = Math.min(cursorPos + 1, text.length)
                                                        isUpdating = false
                                                    }
                                                }
                                            }
                                            
                                            onEditingFinished: {
                                                var newValue = normalizeHexColor(text)
                                                if (isValidHexColor(newValue)) {
                                                    updateColor("primary", newValue)
                                                    savedValue = newValue
                                                    text = newValue
                                                } else {
                                                    text = savedValue
                                                }
                                            }
                                            
                                            Keys.onEnterPressed: editingFinished()
                                            Keys.onReturnPressed: editingFinished()
                                        }
                                        
                                        Connections {
                                            target: appLauncherRoot
                                            function onColorPrimaryChanged() {
                                                if (!colorInput2.isEditing && colorInput2.savedValue !== colorPrimary) {
                                                    colorInput2.text = colorPrimary
                                                    colorInput2.savedValue = colorPrimary
                                                }
                                            }
                                        }
                                    }
                                }
                                
                                MouseArea {
                                    id: colorRowMouseArea2
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    acceptedButtons: Qt.NoButton
                                }
                            }
                            
                            // Secondary
                            Rectangle {
                                width: parent.width
                                height: 70
                                color: colorRowMouseArea3.containsMouse ? colorPrimary : "transparent"
                                radius: 0
                                
                                Behavior on color {
                                    ColorAnimation {
                                        duration: 180
                                        easing.type: Easing.OutQuart
                                    }
                                }
                                
                                Row {
                                    anchors.fill: parent
                                    anchors.margins: 16
                                    spacing: 16
                                    
                                    Rectangle {
                                        width: 44
                                        height: 44
                                        color: colorSecondary
                                        radius: 0
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                    
                                    Column {
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 4
                                        width: 120
                                        
                                        Text {
                                            text: "Secondary"
                                            font.pixelSize: 15
                                            font.family: "JetBrains Mono"
                                            font.weight: Font.Medium
                                            color: colorText
                                        }
                                        
                                        Text {
                                            text: colorSecondary
                                            font.pixelSize: 12
                                            font.family: "JetBrains Mono"
                                            color: (sharedData && sharedData.colorText) ? Qt.lighter(sharedData.colorText, 1.6) : "#999999"
                                        }
                                    }
                                    
                                    Item {
                                        width: parent.width - 44 - 16 - 16 - 120 - 16 - 120
                                        height: parent.height
                                    }
                                    
                                    Rectangle {
                                        id: colorInputRect3
                                        width: 120
                                        height: 40
                                        color: colorInput3.activeFocus ? colorSecondary : colorPrimary
                                        radius: 0
                                        anchors.verticalCenter: parent.verticalCenter
                                        Behavior on color {
                                            ColorAnimation {
                                                duration: 150
                                                easing.type: Easing.OutQuart
                                            }
                                        }
                                        
                                        TextInput {
                                            id: colorInput3
                                            anchors.fill: parent
                                            anchors.margins: 10
                                            font.pixelSize: 14
                                            font.family: "JetBrains Mono"
                                            font.weight: Font.Medium
                                            color: colorText
                                            selectByMouse: true
                                            activeFocusOnPress: true
                                            verticalAlignment: TextInput.AlignVCenter
                                            
                                            property string savedValue: ""
                                            property bool isEditing: false
                                            property bool isUpdating: false
                                            
                                            Component.onCompleted: {
                                                savedValue = colorSecondary
                                                text = colorSecondary
                                            }
                                            
                                            onActiveFocusChanged: {
                                                if (activeFocus) {
                                                    isEditing = true
                                                    savedValue = colorSecondary
                                                    text = colorSecondary
                                                    selectAll()
                                                } else {
                                                    isEditing = false
                                                    if (text !== colorSecondary) {
                                                        text = colorSecondary
                                                        savedValue = colorSecondary
                                                    }
                                                }
                                            }
                                            
                                            onTextChanged: {
                                                if (isEditing && !isUpdating) {
                                                    // Zapobiegaj usunięciu # z początku
                                                    if (text.length > 0 && !text.startsWith('#')) {
                                                        isUpdating = true
                                                        var cursorPos = cursorPosition
                                                        text = '#' + text.replace(/#/g, '')
                                                        cursorPosition = Math.min(cursorPos + 1, text.length)
                                                        isUpdating = false
                                                    }
                                                }
                                            }
                                            
                                            onEditingFinished: {
                                                var newValue = normalizeHexColor(text)
                                                if (isValidHexColor(newValue)) {
                                                    updateColor("secondary", newValue)
                                                    savedValue = newValue
                                                    text = newValue
                                                } else {
                                                    text = savedValue
                                                }
                                            }
                                            
                                            Keys.onEnterPressed: editingFinished()
                                            Keys.onReturnPressed: editingFinished()
                                        }
                                        
                                        Connections {
                                            target: appLauncherRoot
                                            function onColorSecondaryChanged() {
                                                if (!colorInput3.isEditing && colorInput3.savedValue !== colorSecondary) {
                                                    colorInput3.text = colorSecondary
                                                    colorInput3.savedValue = colorSecondary
                                                }
                                            }
                                        }
                                    }
                                }
                                
                                MouseArea {
                                    id: colorRowMouseArea3
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    acceptedButtons: Qt.NoButton
                                }
                            }
                            
                            // Text
                            Rectangle {
                                width: parent.width
                                height: 70
                                color: colorRowMouseArea4.containsMouse ? colorPrimary : "transparent"
                                radius: 0
                                
                                Behavior on color {
                                    ColorAnimation {
                                        duration: 180
                                        easing.type: Easing.OutQuart
                                    }
                                }
                                
                                Row {
                                    anchors.fill: parent
                                    anchors.margins: 16
                                    spacing: 16
                                    
                                    Rectangle {
                                        width: 44
                                        height: 44
                                        color: colorText
                                        radius: 0
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                    
                                    Column {
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 4
                                        width: 120
                                        
                                        Text {
                                            text: "Text"
                                            font.pixelSize: 15
                                            font.family: "JetBrains Mono"
                                            font.weight: Font.Medium
                                            color: colorText
                                        }
                                        
                                        Text {
                                            text: colorText
                                            font.pixelSize: 12
                                            font.family: "JetBrains Mono"
                                            color: (sharedData && sharedData.colorText) ? Qt.lighter(sharedData.colorText, 1.6) : "#999999"
                                        }
                                    }
                                    
                                    Item {
                                        width: parent.width - 44 - 16 - 16 - 120 - 16 - 120
                                        height: parent.height
                                    }
                                    
                                    Rectangle {
                                        id: colorInputRect4
                                        width: 120
                                        height: 40
                                        color: colorInput4.activeFocus ? colorSecondary : colorPrimary
                                        radius: 0
                                        anchors.verticalCenter: parent.verticalCenter
                                        Behavior on color {
                                            ColorAnimation {
                                                duration: 150
                                                easing.type: Easing.OutQuart
                                            }
                                        }
                                        
                                        TextInput {
                                            id: colorInput4
                                            anchors.fill: parent
                                            anchors.margins: 10
                                            font.pixelSize: 14
                                            font.family: "JetBrains Mono"
                                            font.weight: Font.Medium
                                            color: colorText
                                            selectByMouse: true
                                            activeFocusOnPress: true
                                            verticalAlignment: TextInput.AlignVCenter
                                            
                                            property string savedValue: ""
                                            property bool isEditing: false
                                            property bool isUpdating: false
                                            
                                            Component.onCompleted: {
                                                savedValue = colorText
                                                text = colorText
                                            }
                                            
                                            onActiveFocusChanged: {
                                                if (activeFocus) {
                                                    isEditing = true
                                                    savedValue = colorText
                                                    text = colorText
                                                    selectAll()
                                                } else {
                                                    isEditing = false
                                                    if (text !== colorText) {
                                                        text = colorText
                                                        savedValue = colorText
                                                    }
                                                }
                                            }
                                            
                                            onTextChanged: {
                                                if (isEditing && !isUpdating) {
                                                    // Zapobiegaj usunięciu # z początku
                                                    if (text.length > 0 && !text.startsWith('#')) {
                                                        isUpdating = true
                                                        var cursorPos = cursorPosition
                                                        text = '#' + text.replace(/#/g, '')
                                                        cursorPosition = Math.min(cursorPos + 1, text.length)
                                                        isUpdating = false
                                                    }
                                                }
                                            }
                                            
                                            onEditingFinished: {
                                                var newValue = normalizeHexColor(text)
                                                if (isValidHexColor(newValue)) {
                                                    updateColor("text", newValue)
                                                    savedValue = newValue
                                                    text = newValue
                                                } else {
                                                    text = savedValue
                                                }
                                            }
                                            
                                            Keys.onEnterPressed: editingFinished()
                                            Keys.onReturnPressed: editingFinished()
                                        }
                                        
                                        Connections {
                                            target: appLauncherRoot
                                            function onColorTextChanged() {
                                                if (!colorInput4.isEditing && colorInput4.savedValue !== colorText) {
                                                    colorInput4.text = colorText
                                                    colorInput4.savedValue = colorText
                                                }
                                            }
                                        }
                                    }
                                }
                                
                                MouseArea {
                                    id: colorRowMouseArea4
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    acceptedButtons: Qt.NoButton
                                }
                            }
                            
                            // Focus
                            Rectangle {
                                width: parent.width
                                height: 70
                                color: colorRowMouseArea5.containsMouse ? colorPrimary : "transparent"
                                radius: 0
                                
                                Behavior on color {
                                    ColorAnimation {
                                        duration: 180
                                        easing.type: Easing.OutQuart
                                    }
                                }
                                
                                Row {
                                    anchors.fill: parent
                                    anchors.margins: 16
                                    spacing: 16
                                    
                                    Rectangle {
                                        width: 44
                                        height: 44
                                        color: (sharedData && sharedData.colorAccent) ? sharedData.colorAccent : colorAccent
                                        radius: 0
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                    
                                    Column {
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 4
                                        width: 120
                                        
                                        Text {
                                            text: "Focus"
                                            font.pixelSize: 15
                                            font.family: "JetBrains Mono"
                                            font.weight: Font.Medium
                                            color: colorText
                                        }
                                        
                                        Text {
                                            text: colorAccent
                                            font.pixelSize: 12
                                            font.family: "JetBrains Mono"
                                            color: (sharedData && sharedData.colorText) ? Qt.lighter(sharedData.colorText, 1.6) : "#999999"
                                        }
                                    }
                                    
                                    Item {
                                        width: parent.width - 44 - 16 - 16 - 120 - 16 - 120
                                        height: parent.height
                                    }
                                    
                                    Rectangle {
                                        id: colorInputRect5
                                        width: 120
                                        height: 40
                                        color: colorInput5.activeFocus ? colorSecondary : colorPrimary
                                        radius: 0
                                        anchors.verticalCenter: parent.verticalCenter
                                        Behavior on color {
                                            ColorAnimation {
                                                duration: 150
                                                easing.type: Easing.OutQuart
                                            }
                                        }
                                        
                                        TextInput {
                                            id: colorInput5
                                            anchors.fill: parent
                                            anchors.margins: 10
                                            font.pixelSize: 14
                                            font.family: "JetBrains Mono"
                                            font.weight: Font.Medium
                                            color: colorText
                                            selectByMouse: true
                                            activeFocusOnPress: true
                                            verticalAlignment: TextInput.AlignVCenter
                                            
                                            property string savedValue: ""
                                            property bool isEditing: false
                                            property bool isUpdating: false
                                            
                                            Component.onCompleted: {
                                                savedValue = colorAccent
                                                text = colorAccent
                                            }
                                            
                                            onActiveFocusChanged: {
                                                if (activeFocus) {
                                                    isEditing = true
                                                    savedValue = colorAccent
                                                    text = colorAccent
                                                    selectAll()
                                                } else {
                                                    isEditing = false
                                                    if (text !== colorAccent) {
                                                        text = colorAccent
                                                        savedValue = colorAccent
                                                    }
                                                }
                                            }
                                            
                                            onTextChanged: {
                                                if (isEditing && !isUpdating) {
                                                    // Zapobiegaj usunięciu # z początku
                                                    if (text.length > 0 && !text.startsWith('#')) {
                                                        isUpdating = true
                                                        var cursorPos = cursorPosition
                                                        text = '#' + text.replace(/#/g, '')
                                                        cursorPosition = Math.min(cursorPos + 1, text.length)
                                                        isUpdating = false
                                                    }
                                                }
                                            }
                                            
                                            onEditingFinished: {
                                                var newValue = normalizeHexColor(text)
                                                if (isValidHexColor(newValue)) {
                                                    updateColor("accent", newValue)
                                                    savedValue = newValue
                                                    text = newValue
                                                } else {
                                                    text = savedValue
                                                }
                                            }
                                            
                                            Keys.onEnterPressed: editingFinished()
                                            Keys.onReturnPressed: editingFinished()
                                        }
                                        
                                        Connections {
                                            target: appLauncherRoot
                                            function onColorAccentChanged() {
                                                if (!colorInput5.isEditing && colorInput5.savedValue !== colorAccent) {
                                                    colorInput5.text = colorAccent
                                                    colorInput5.savedValue = colorAccent
                                                }
                                            }
                                        }
                                    }
                                }
                                
                                MouseArea {
                                    id: colorRowMouseArea5
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    acceptedButtons: Qt.NoButton
                                }
                            }
                        }
                    }
                }
            }

            // Tryb 3: Notes
            Item {
                id: notesMode
                anchors.fill: parent
                visible: currentMode === 3
                enabled: true
                z: 10

                // Notes menu (-1) or editor (0=new, 1=edit)
                Item {
                    id: notesMenu
                    anchors.fill: parent
                    visible: currentNotesMode === -1

                    Flickable {
                        anchors.fill: parent
                        anchors.margins: 20
                        contentHeight: notesMenuColumn.height
                        clip: true

                        Column {
                            id: notesMenuColumn
                            width: parent.width
                            spacing: 16

                            // Title
                            Text {
                                text: "Notes Manager"
                                font.pixelSize: 18
                                font.family: "JetBrains Mono"
                                font.weight: Font.Bold
                                color: colorText
                            }

                            // New note button
                            Rectangle {
                                width: parent.width
                                height: 60
                                color: newNoteButtonMouseArea.containsMouse ? colorAccent : colorSecondary
                                radius: 0

                                Text {
                                    text: "➕ Nowa notatka"
                                    font.pixelSize: 16
                                    font.family: "JetBrains Mono"
                                    font.weight: Font.Bold
                                    color: colorText
                                    anchors.centerIn: parent
                                }

                                MouseArea {
                                    id: newNoteButtonMouseArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        currentNotesMode = 0
                                        selectedIndex = 0
                                        notesEditText.text = ""
                                        notesFileName = ""
                                    }
                                }

                                // Bottom accent line for selected items
                                Rectangle {
                                    anchors.bottom: parent.bottom
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: parent.width * 0.8
                                    height: 3
                                    color: colorAccent
                                    radius: 1.5
                                }
                            }

                            // Saved notes title
                            Text {
                                text: "Zapisane notatki:"
                                font.pixelSize: 14
                                font.family: "JetBrains Mono"
                                font.weight: Font.Bold
                                color: colorText
                                visible: notesList.count > 0
                            }

                            // List of saved notes
                            ListView {
                                id: notesList
                                width: parent.width
                                height: 300
                                model: ListModel { id: notesModel }
                                spacing: 8
                                clip: true

                                delegate: Rectangle {
                                    width: parent.width
                                    height: 50
                                    color: selectedIndex === index ? colorAccent : (notesItemMouseArea.containsMouse ? colorPrimary : "transparent")
                                    radius: 0

                                    Text {
                                        text: model.name
                                        font.pixelSize: 14
                                        font.family: "JetBrains Mono"
                                        color: colorText
                                        anchors.verticalCenter: parent.verticalCenter
                                        anchors.left: parent.left
                                        anchors.leftMargin: 20
                                        elide: Text.ElideRight
                                    }

                                    MouseArea {
                                        id: notesItemMouseArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: {
                                            if (model.file !== "") {
                                                selectedIndex = index
                                                currentNotesMode = 1
                                                notesFileName = model.file
                                                loadNoteContent(model.file)
                                            }
                                        }
                                    }

                                    // Bottom accent line for selected items
                                    Rectangle {
                                        anchors.bottom: parent.bottom
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        width: selectedIndex === index ? parent.width * 0.8 : 0
                                        height: 3
                                        color: colorAccent
                                        radius: 1.5
                                        Behavior on width {
                                            NumberAnimation {
                                                duration: 300
                                                easing.type: Easing.OutCubic
                                            }
                                        }
                                    }
                                }

                                Component.onCompleted: {
                                    loadNotesList()
                                }
                            }
                        }
                    }
                }

                // Note editor (new or edit)
                Item {
                    id: notesEditor
                    anchors.fill: parent
                    visible: currentNotesMode === 0 || currentNotesMode === 1

                    Flickable {
                        anchors.fill: parent
                        anchors.margins: 20
                        contentHeight: notesEditorColumn.height
                        clip: true

                        Column {
                            id: notesEditorColumn
                            width: parent.width
                            spacing: 16

                            // Title
                            Text {
                                text: currentNotesMode === 0 ? "Nowa notatka" : "Edytuj notatkę"
                                font.pixelSize: 18
                                font.family: "JetBrains Mono"
                                font.weight: Font.Bold
                                color: colorText
                            }

                            // Instructions for new notes
                            Text {
                                width: parent.width
                                text: currentNotesMode === 0 ?
                                    "Wpisz tytuł notatki w pierwszej linii, potem treść.\nNazwa pliku zostanie utworzona automatycznie." :
                                    "Edytuj notatkę. Pierwsza linia to tytuł."
                                font.pixelSize: 12
                                font.family: "JetBrains Mono"
                                color: "#888888"
                                wrapMode: Text.Wrap
                                visible: currentNotesMode === 0 || currentNotesMode === 1
                            }

                            // Notes edit area
                            Rectangle {
                                width: parent.width
                                height: 350
                                color: colorPrimary
                                border.width: 2
                                border.color: colorSecondary
                                radius: 8

                                TextEdit {
                                    id: notesEditText
                                    anchors.fill: parent
                                    anchors.margins: 12
                                    font.pixelSize: 14
                                    font.family: "JetBrains Mono"
                                    color: colorText
                                    wrapMode: TextEdit.Wrap
                                    selectByMouse: true
                                    activeFocusOnPress: true
                                    focus: true

                                    Text {
                                        text: "Wpisz swoją notatkę tutaj..."
                                        font.pixelSize: 14
                                        font.family: "JetBrains Mono"
                                        color: Qt.lighter(colorText, 1.5)
                                        visible: parent.text.length === 0
                                        anchors.fill: parent
                                        anchors.margins: 12
                                        verticalAlignment: Text.AlignTop
                                    }
                                }
                            }

                            // Buttons row
                            Row {
                                spacing: 12
                                width: parent.width

                                // Save button
                                Rectangle {
                                    width: (parent.width - parent.spacing) / 2
                                    height: 45
                                    color: saveNoteButtonMouseArea.containsMouse ? colorAccent : colorSecondary
                                    radius: 0

                                    Text {
                                        text: "💾 Zapisz"
                                        font.pixelSize: 14
                                        font.family: "JetBrains Mono"
                                        font.weight: Font.Bold
                                        color: colorText
                                        anchors.centerIn: parent
                                    }

                                    MouseArea {
                                        id: saveNoteButtonMouseArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            saveNote()
                                        }
                                    }
                                }

                                // Cancel button
                                Rectangle {
                                    width: (parent.width - parent.spacing) / 2
                                    height: 45
                                    color: cancelNoteButtonMouseArea.containsMouse ? colorPrimary : "transparent"
                                    border.width: 1
                                    border.color: colorSecondary
                                    radius: 0

                                    Text {
                                        text: "❌ Anuluj"
                                        font.pixelSize: 14
                                        font.family: "JetBrains Mono"
                                        font.weight: Font.Bold
                                        color: colorText
                                        anchors.centerIn: parent
                                    }

                                    MouseArea {
                                        id: cancelNoteButtonMouseArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            currentNotesMode = -1
                                            selectedIndex = 0
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

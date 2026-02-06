import QtQuick
<<<<<<< HEAD
=======
import QtQml
>>>>>>> master
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "."

PanelWindow {
    id: appLauncherRoot
    
    property var sharedData: null
    property var screen: null
    
    // Dynamic project path - from environment variable or auto-detected
    property string projectPath: "" // Will be set by Component.onCompleted
    
    function loadProjectPath() {
<<<<<<< HEAD
        // Try to read path from environment variable
        Qt.createQmlObject("import Quickshell.Io; import QtQuick; Process { command: ['sh', '-c', 'echo \"$QUICKSHELL_PROJECT_PATH\" > /tmp/quickshell_project_path 2>/dev/null || echo \"\" > /tmp/quickshell_project_path']; running: true }", appLauncherRoot)
        
        // Wait a moment and read the result
        Qt.createQmlObject("import QtQuick; Timer { interval: 100; running: true; repeat: false; onTriggered: appLauncherRoot.readProjectPath() }", appLauncherRoot)
=======
        if (sharedData && sharedData.runCommand) sharedData.runCommand(['sh', '-c', 'echo "$QUICKSHELL_PROJECT_PATH" > /tmp/quickshell_project_path 2>/dev/null || true'], readProjectPath)
>>>>>>> master
    }
    
    function readProjectPath() {
        var xhr = new XMLHttpRequest()
        xhr.open("GET", "file:///tmp/quickshell_project_path")
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                var path = xhr.responseText.trim()
                if (path && path.length > 0) {
                    projectPath = path
<<<<<<< HEAD
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
=======
                } else {
                    // Try to detect from current script location
                    if (Qt.application && Qt.application.arguments && Qt.application.arguments.length > 0 && sharedData && sharedData.runCommand) {
                        var args = Qt.application.arguments
                        sharedData.runCommand(['sh', '-c', 'dirname "$(readlink -f "$1" 2>/dev/null || echo "$1")" 2>/dev/null | head -1 > /tmp/quickshell_script_dir || true', 'sh', args[0] || ''], readScriptDir)
                    } else {
                        // Last resort fallback
                        projectPath = "/tmp/sharpshell"
>>>>>>> master
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
<<<<<<< HEAD
                    console.log("Project path auto-detected:", projectPath)
                } else {
                    // Last resort: use current working directory concept
                    projectPath = "/tmp/sharpshell"
                    console.log("Using fallback project path:", projectPath)
=======
                } else {
                    // Last resort: use current working directory concept
                    projectPath = "/tmp/sharpshell"
>>>>>>> master
                }
            }
        }
        xhr.send()
    }
    
    Component.onCompleted: {
        initializePaths()
<<<<<<< HEAD
        loadProjectPath()
=======
        if (!(projectPath && projectPath.length > 0)) loadProjectPath()
>>>>>>> master
        loadApps()
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
<<<<<<< HEAD
=======

        // Gdy launcher się otwiera i lista aplikacji jest pusta – załaduj aplikacje (np. po starcie runCommand nie był gotowy)
        function onLauncherVisibleChanged() {
            if (sharedData && sharedData.launcherVisible && apps.length === 0) {
                loadApps()
            }
        }
>>>>>>> master
    }
    
    // Initialize paths from environment
    function initializePaths() {
        // Get home directory from environment
<<<<<<< HEAD
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
        // Clear and show loading
        notesModel.clear()
        notesModel.append({ name: "Ładowanie notatek...", file: "" })

        // Use Process to list all .txt files in the directory
        Qt.createQmlObject("import Quickshell.Io; import QtQuick; Process { command: ['ls', '-1', '" + notesDir + "', '2>/dev/null', '|', 'grep', '\\.txt$']; running: true }", appLauncherRoot)

        // Use timer to process results
        Qt.createQmlObject("import QtQuick; Timer { interval: 200; running: true; repeat: false; onTriggered: appLauncherRoot.processNotesList() }", appLauncherRoot)
    }

    function processNotesList() {
        // For now, manually add known existing files
        // TODO: Implement proper directory reading
        console.log("Processing notes list...")
        notesModel.clear()

        var existingFiles = ["notes.txt", "test.txt", "wybickiego14c.txt", "12312321.txt"]

        if (existingFiles.length === 0) {
            notesModel.append({ name: "Brak zapisanych notatek", file: "" })
            console.log("No notes found")
        } else {
            console.log("Found", existingFiles.length, "note files")
            for (var i = 0; i < existingFiles.length; i++) {
                var fileName = existingFiles[i].replace('.txt', '')
                notesModel.append({ name: fileName, file: existingFiles[i] })
                console.log("Added note:", fileName, "->", existingFiles[i])
            }
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

        var notesPath = notesDir + "/" + fileName
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
        console.log("Loading note content for file:", fileName)
        var notesPath = notesDir + "/" + fileName
        console.log("Full path:", notesPath)
        var xhr = new XMLHttpRequest()
        xhr.open("GET", "file://" + notesPath)
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                console.log("XMLHttpRequest readyState DONE, status:", xhr.status)
                if (xhr.status === 200 || xhr.status === 0) {
                    pendingNoteContent = xhr.responseText
                    console.log("Note content loaded, length:", xhr.responseText.length)
                    console.log("Content preview:", xhr.responseText.substring(0, 50))
                    // Use timer to set content after UI is ready
                    Qt.createQmlObject("import QtQuick; Timer { interval: 100; running: true; repeat: false; onTriggered: appLauncherRoot.applyPendingNoteContent() }", appLauncherRoot)
                } else {
                    pendingNoteContent = "Błąd ładowania notatki"
                    console.log("Failed to load note from:", notesPath, "status:", xhr.status)
                    Qt.createQmlObject("import QtQuick; Timer { interval: 100; running: true; repeat: false; onTriggered: appLauncherRoot.applyPendingNoteContent() }", appLauncherRoot)
                }
            }
        }
        xhr.send()
    }

    function applyPendingNoteContent() {
        console.log("Applying pending note content, text length:", pendingNoteContent.length)
        if (notesEditText && pendingNoteContent !== "") {
            notesEditText.text = pendingNoteContent
            console.log("Note content applied to TextEdit")
            pendingNoteContent = ""
        } else {
            console.log("Cannot apply content - notesEditText exists:", !!notesEditText, "pending content length:", pendingNoteContent.length)
        }
=======
        if (sharedData && sharedData.runCommand) sharedData.runCommand(['sh', '-c', 'echo "$HOME" > /tmp/quickshell_home 2>/dev/null || true'], readHomePath)
>>>>>>> master
    }

    function readHomePath() {
        var xhr = new XMLHttpRequest()
        xhr.open("GET", "file:///tmp/quickshell_home")
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                var home = xhr.responseText.trim()
                if (home && home.length > 0) {
<<<<<<< HEAD
                    colorConfigPath = home + "/.config/sharpshell/colors.json"
                    notesDir = home + "/Documents/Notes"
                    console.log("Paths initialized - home:", home, "colorConfig:", colorConfigPath, "notes:", notesDir)
                } else {
                    // Fallback to defaults
                    colorConfigPath = "/tmp/sharpshell/colors.json"
                    notesDir = "/tmp/Documents/Notes"
                    console.log("Using fallback paths")
=======
                    // Try ~/.config/alloy/colors.json first
                    var alloyPath = home + "/.config/alloy/colors.json"
                    var checkXhr = new XMLHttpRequest()
                    checkXhr.open("GET", "file://" + alloyPath)
                    checkXhr.onreadystatechange = function() {
                        if (checkXhr.readyState === XMLHttpRequest.DONE) {
                            if (checkXhr.status === 200 || checkXhr.status === 0) {
                                colorConfigPath = alloyPath
                            } else {
                                colorConfigPath = home + "/.config/sharpshell/colors.json"
                            }
                            notesDir = ""
                        }
                    }
                    checkXhr.send()
                } else {
                    // Fallback to defaults
                    colorConfigPath = "/tmp/sharpshell/colors.json"
                    notesDir = ""
>>>>>>> master
                }
            }
        }
        xhr.send()
    }
    
    // Color management functions
<<<<<<< HEAD
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
=======
    // optionalPresetName: when applying a preset, pass its name so it's written to colors.json (arg 8).
    // Quickshell loadColors uses presets[colorPreset] – without saving the name, reload would apply the old preset.
    function saveColors(optionalPresetName) {
        if (!projectPath || projectPath.length === 0) {
            return
        }
        if (!colorConfigPath || colorConfigPath.length === 0) {
            return
        }
        var scriptPath = projectPath + "/scripts/save-colors.py"
        var presetArg = (optionalPresetName && String(optionalPresetName).length > 0) ? String(optionalPresetName).replace(/"/g, '\\"') : ""
        var cmd = 'python3 "' + scriptPath + '" "' + colorBackground + '" "' + colorPrimary + '" "' + colorSecondary + '" "' + colorText + '" "' + colorAccent + '" "' + colorConfigPath + '" "" "' + presetArg + '"'
        Qt.createQmlObject("import Quickshell.Io; import QtQuick; Process { command: ['sh', '-c', '" + cmd.replace(/'/g, "'\"'\"'") + "']; running: true }", appLauncherRoot)
>>>>>>> master
    }
    
    
    
    function updateColor(colorType, value) {
<<<<<<< HEAD
        console.log("Updating color:", colorType, "to", value)
=======
>>>>>>> master
        var oldValue = ""
        switch(colorType) {
            case "background": 
                oldValue = colorBackground
                colorBackground = value
                if (sharedData) sharedData.colorBackground = value
<<<<<<< HEAD
                console.log("colorBackground changed from", oldValue, "to", colorBackground)
=======
>>>>>>> master
                break
            case "primary": 
                oldValue = colorPrimary
                colorPrimary = value
                if (sharedData) sharedData.colorPrimary = value
<<<<<<< HEAD
                console.log("colorPrimary changed from", oldValue, "to", colorPrimary)
=======
>>>>>>> master
                break
            case "secondary": 
                oldValue = colorSecondary
                colorSecondary = value
                if (sharedData) sharedData.colorSecondary = value
<<<<<<< HEAD
                console.log("colorSecondary changed from", oldValue, "to", colorSecondary)
=======
>>>>>>> master
                break
            case "text": 
                oldValue = colorText
                colorText = value
                if (sharedData) sharedData.colorText = value
<<<<<<< HEAD
                console.log("colorText changed from", oldValue, "to", colorText)
=======
>>>>>>> master
                break
            case "accent": 
                oldValue = colorAccent
                colorAccent = value
                if (sharedData) sharedData.colorAccent = value
<<<<<<< HEAD
                console.log("colorAccent changed from", oldValue, "to", colorAccent)
                break
        }
        saveColors()
        console.log("Colors saved and sharedData updated")
=======
                break
        }
        saveColors()
>>>>>>> master
    }
    
    // Color presets
    function applyPreset(presetName) {
        var preset = colorPresets[presetName]
        if (!preset) {
<<<<<<< HEAD
            console.log("Preset not found:", presetName)
=======
>>>>>>> master
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
        
<<<<<<< HEAD
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
=======
        // Save to file – must pass preset name so colors.json has colorPreset set; otherwise Quickshell reload applies the old preset.
        saveColors(presetName)
        // Trigger Quickshell reload after save finishes (script is async)
        if (sharedData && sharedData.runCommand) {
            sharedData.runCommand(['sh', '-c', 'sleep 0.5 && echo 1 > /tmp/quickshell_color_change'])
        }
    }
    
    property var colorPresets: {
        "Monochrome": {
            background: "#000000",
            primary: "#1a1a1a",
            secondary: "#0d0d0d",
            text: "#ffffff",
            accent: "#b0b0b0"
        },
        "Professional Modern": {
            background: "#0a0a0a",
            primary: "#1a1a1a",
            secondary: "#151515",
            text: "#ffffff",
            accent: "#4a9eff"
        },
        "Dark Warm": {
            background: "#0d0d0d",
            primary: "#1f1f1f",
            secondary: "#181818",
            text: "#f5f5f5",
            accent: "#ff6b35"
        },
        "Cool Blue": {
            background: "#080d14",
            primary: "#0f1419",
            secondary: "#0a1016",
            text: "#e1e5e9",
            accent: "#00d4ff"
        },
        "Minimal Gray": {
            background: "#0c0c0c",
            primary: "#161616",
            secondary: "#121212",
            text: "#f0f0f0",
            accent: "#a0a0a0"
        },
        "Forest Green": {
            background: "#0a0f0a",
            primary: "#141914",
            secondary: "#0e120e",
            text: "#e8f5e8",
            accent: "#4ade80"
        },
        "Sunset Orange": {
            background: "#0f0a05",
            primary: "#1a140d",
            secondary: "#140f09",
            text: "#f5e8d8",
            accent: "#ff9500"
        },
        "Ocean Blue": {
            background: "#050a0f",
            primary: "#0d1419",
            secondary: "#091116",
            text: "#d8e8f5",
            accent: "#3b82f6"
        },
        "Deep Purple": {
            background: "#0a0514",
            primary: "#140d1f",
            secondary: "#0f0916",
            text: "#e8d8f5",
            accent: "#8b5cf6"
        },
        "GNOME Monochrome": {
            background: "#242424",
            primary: "#303030",
            secondary: "#2a2a2a",
            text: "#ffffff",
            accent: "#3584e4"
        },
        "Pure Black": {
            background: "#030303",
            primary: "#0a0a0a",
            secondary: "#060606",
            text: "#ffffff",
            accent: "#c0c0c0"
>>>>>>> master
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
    
<<<<<<< HEAD
    // Base size
    property int baseWidth: 540
    property int baseHeight: 315  // 70% of 450 (30% shorter)
    

    // Size when in notes mode (50% larger)
    property bool isNotesMode: (currentMode === 3)
    property int notesWidth: Math.floor(baseWidth * 1.5)  // 50% wider
    property int notesHeight: Math.floor(baseHeight * 1.5)  // 50% taller
    
    implicitWidth: isNotesMode ? notesWidth : baseWidth
    implicitHeight: isNotesMode ? notesHeight : baseHeight
=======
    // Base size – zbalansowane proporcje
    property int baseWidth: 500
    property int baseHeight: 320
    

    implicitWidth: baseWidth
    implicitHeight: baseHeight
>>>>>>> master
    
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
<<<<<<< HEAD
    WlrLayershell.keyboardFocus: (sharedData && sharedData.launcherVisible) ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    exclusiveZone: 0
    
    // Visibility control - always visible, controlled by slideOffset
    visible: true
    color: "transparent"  // Transparent, background will be in container with gradient
    
    // Slide up animation from bottom - negative value moves down (off screen)
    property int slideOffset: (sharedData && sharedData.launcherVisible) ? 0 : -600
    
    margins.bottom: slideOffset
    
    Behavior on slideOffset {
        NumberAnimation { 
            duration: 500
            easing.type: Easing.OutExpo
        }
    }
=======
    WlrLayershell.keyboardFocus: (launcherShowProgress > 0.02) ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    exclusiveZone: 0

    // Jeden sterownik animacji (jak w Dashboard) – start od 0, Binding = brak skoku na pierwszej klatce
    property real launcherShowProgress: 0
    Binding on launcherShowProgress {
        value: (sharedData && sharedData.launcherVisible) ? 1.0 : 0.0
    }
    Behavior on launcherShowProgress {
        NumberAnimation { duration: 400; easing.type: Easing.OutCubic }
    }

    visible: launcherShowProgress > 0.01
    color: "transparent"
    property int launcherSlideAmount: 400
    // Fix: Use margins.bottom for window positioning (0 = flush with edge)
    // Animation will be handled by the margins to move the window surface
    margins.bottom: -implicitHeight * (1.0 - launcherShowProgress)
>>>>>>> master
    
    // Applications list
    property var apps: []
    property int selectedIndex: 0
    property string searchText: ""
    
    // Calculator properties
    property string calculatorResult: ""
    property bool isCalculatorMode: false
<<<<<<< HEAD
    property int currentMode: -1  // -1 = mode selection, 0 = Launcher, 1 = Packages, 2 = Settings, 3 = Notes
    property int currentNotesMode: -1  // -1 = menu, 0 = new note, 1 = edit note
    property string notesFileName: ""  // Current note file name
    property string pendingNoteContent: ""  // Content to load into editor
    property string notesDir: ""  // Notes directory path
    property int notesMenuIndex: 0  // Selected index in notes menu (0 = new note button, 1+ = notes list)
=======
    property int currentMode: -1  // -1 = mode selection, 0 = Launcher, 1 = Packages, 2 = Fuse
>>>>>>> master
    property int currentPackageMode: -1  // -1 = Packages option selection, 0 = install source selection (Pacman/AUR), 1 = Pacman search, 2 = AUR search, 3 = remove source selection (Pacman/AUR), 4 = Pacman remove search, 5 = AUR remove search
    property int installSourceMode: -1  // -1 = selection, 0 = Pacman, 1 = AUR
    property int removeSourceMode: -1  // -1 = selection, 0 = Pacman, 1 = AUR
    
    // Color theme properties
    property string colorBackground: "#0a0a0a"
    property string colorPrimary: "#1a1a1a"
    property string colorSecondary: "#141414"
    property string colorText: "#ffffff"
    property string colorAccent: "#4a9eff"
    
    // Color config file path - dynamically determined
    property string colorConfigPath: ""
    property var packages: []
    property string packageSearchText: ""
    
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
    
    
    
    
    
    
    
    function updateSystem() {
        var scriptPath = projectPath + "/scripts/update-system.sh"
        // Open kitty, set as floating, size 1200x700 and center
        var command = "hyprctl dispatch exec \"kitty --class=floating_kitty -e bash " + scriptPath + "\"; sleep 0.3; hyprctl dispatch focuswindow \"class:floating_kitty\"; hyprctl dispatch togglefloating; hyprctl dispatch resizeactive exact 1200 700; hyprctl dispatch centerwindow"
        
<<<<<<< HEAD
        console.log("Executing update command:", command)
=======
>>>>>>> master
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
<<<<<<< HEAD
        console.log("Toggling Bluetooth, current state:", bluetoothEnabled)
        if (bluetoothEnabled) {
            console.log("Turning Bluetooth OFF")
            // Block with rfkill and turn off
            Qt.createQmlObject("import Quickshell.Io; import QtQuick; Process { command: ['sh', '-c', 'rfkill block bluetooth; /usr/bin/bluetoothctl power off']; running: true }", appLauncherRoot)
        } else {
            console.log("Turning Bluetooth ON")
=======
        if (bluetoothEnabled) {
            // Block with rfkill and turn off
            Qt.createQmlObject("import Quickshell.Io; import QtQuick; Process { command: ['sh', '-c', 'rfkill block bluetooth; /usr/bin/bluetoothctl power off']; running: true }", appLauncherRoot)
        } else {
>>>>>>> master
            // Unblock with rfkill, wait, then turn on
            Qt.createQmlObject("import Quickshell.Io; import QtQuick; Process { command: ['sh', '-c', 'rfkill unblock bluetooth; sleep 1; /usr/bin/bluetoothctl power on']; running: true }", appLauncherRoot)
        }
        Qt.createQmlObject("import QtQuick; Timer { interval: 1500; running: true; repeat: false; onTriggered: appLauncherRoot.checkBluetoothStatus() }", appLauncherRoot)
    }
    
    function scanBluetoothDevices() {
        if (!bluetoothEnabled || bluetoothScanning) return
        bluetoothScanning = true
        bluetoothDevicesModel.clear()
<<<<<<< HEAD
        console.log("Starting Bluetooth scan...")
=======
>>>>>>> master
        
        // Use bluetoothctl with timeout - this will scan for 10 seconds and then automatically stop
        Qt.createQmlObject("import Quickshell.Io; import QtQuick; Process { command: ['sh', '-c', 'bluetoothctl --timeout 10 scan on > /tmp/quickshell_bt_scan_output 2>&1']; running: true }", appLauncherRoot)
        
        // Wait for scan to complete and get devices
        Qt.createQmlObject("import QtQuick; Timer { interval: 12000; running: true; repeat: false; onTriggered: appLauncherRoot.getBluetoothDevices() }", appLauncherRoot)
    }
    
    function getBluetoothDevices() {
<<<<<<< HEAD
        console.log("Getting Bluetooth devices...")
=======
>>>>>>> master
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
<<<<<<< HEAD
                console.log("Bluetooth devices file content:", content)
                console.log("Content length:", content.length)
                var lines = content.trim().split("\n")
                console.log("Found", lines.length, "lines")
                for (var i = 0; i < lines.length; i++) {
                    var line = lines[i].trim()
                    console.log("Processing line", i, ":", line)
=======
                var lines = content.trim().split("\n")
                for (var i = 0; i < lines.length; i++) {
                    var line = lines[i].trim()
>>>>>>> master
                    if (line.length > 0) {
                        if (line.startsWith("Device")) {
                            // Format: "Device MAC_ADDRESS Device_Name"
                            var parts = line.split(" ")
<<<<<<< HEAD
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
=======
                            if (parts.length >= 3) {
                                var mac = parts[1]
                                var name = parts.slice(2).join(" ") || "Unknown Device"
                                bluetoothDevicesModel.append({ mac: mac, name: name, connected: false })
                            } else {
                            }
                        } else {
                        }
                    }
                }
>>>>>>> master
                bluetoothScanning = false
            }
        }
        xhr.send()
    }
    
    function connectBluetoothDevice(mac) {
<<<<<<< HEAD
        console.log("=== connectBluetoothDevice called ===")
        console.log("MAC received:", mac, "type:", typeof mac)
        if (bluetoothConnecting) {
            console.log("Already connecting, skipping")
=======
        if (bluetoothConnecting) {
>>>>>>> master
            return
        }
        bluetoothConnecting = true
        var macStr = String(mac).trim()
<<<<<<< HEAD
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
=======
        
        // First pair, then connect
        // Step 1: Pair the device
        Qt.createQmlObject("import Quickshell.Io; import QtQuick; Process { command: ['/usr/bin/bluetoothctl', 'pair', '" + macStr + "']; running: true }", appLauncherRoot)
        
        // Step 2: Wait a bit, then connect
        
    }
    
    function connectAfterPair(mac) {
>>>>>>> master
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
            
<<<<<<< HEAD
            // Run via sh -c for better compatibility
            Qt.createQmlObject("import Quickshell.Io; import QtQuick; Process { command: ['sh', '-c', '" + exec.replace(/'/g, "\\'") + " &']; running: true }", appLauncherRoot)
=======
            if (sharedData && sharedData.runCommand) sharedData.runCommand(['sh', '-c', exec.replace(/'/g, "'\"'\"'") + ' &'])
>>>>>>> master
            
            if (sharedData) {
                sharedData.launcherVisible = false
            }
        }
    }
    
    // Function to load applications
<<<<<<< HEAD
    function loadApps() {
=======
    property int _loadAppsRetries: 0
    function loadApps() {
        if (!(sharedData && sharedData.runCommand)) {
            // runCommand może nie być gotowe przy starcie – spróbuj ponownie po chwili albo gdy użytkownik otworzy launcher
            if (_loadAppsRetries < 5) {
                _loadAppsRetries++
                Qt.callLater(function() {
                    var t = Qt.createQmlObject("import QtQuick; Timer { interval: 400; running: true; repeat: false; onTriggered: appLauncherRoot.loadApps() }", appLauncherRoot)
                })
            }
            return
        }
        _loadAppsRetries = 0
>>>>>>> master
        apps = []
        filteredApps.clear()
        loadedAppsCount = 0
        totalFilesToLoad = 0
<<<<<<< HEAD
        
        // Load applications from .desktop files (more applications)
        Qt.createQmlObject("import Quickshell.Io; import QtQuick; Process { command: ['sh', '-c', 'find /usr/share/applications ~/.local/share/applications -name \"*.desktop\" 2>/dev/null | head -100 > /tmp/quickshell_apps_list']; running: true }", appLauncherRoot)
        
        // After a moment, read the list and load applications
        Qt.createQmlObject("import QtQuick; Timer { interval: 300; running: true; repeat: false; onTriggered: appLauncherRoot.readAppsList() }", appLauncherRoot)
=======
        sharedData.runCommand(['sh', '-c', 'find /usr/share/applications ~/.local/share/applications -name "*.desktop" 2>/dev/null | head -200 > /tmp/quickshell_apps_list'], readAppsList)
>>>>>>> master
    }
    
    function readAppsList() {
        var xhr = new XMLHttpRequest()
<<<<<<< HEAD
        xhr.open("GET", "file:///tmp/quickshell_apps_list")
=======
        xhr.open("GET", "file:///tmp/quickshell_apps_list?_=" + Date.now())
>>>>>>> master
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
        
<<<<<<< HEAD
        console.log("Searching for packages:", query)
=======
>>>>>>> master
        
        // Run search in background
        Qt.createQmlObject("import Quickshell.Io; import QtQuick; Process { command: ['sh', '-c', 'pacman -Ss \"" + query.replace(/"/g, '\\"') + "\" 2>/dev/null | head -50 > /tmp/quickshell_pacman_search']; running: true }", appLauncherRoot)
        
        // Wait a moment and read results (use Timer instead of onFinished)
        Qt.createQmlObject("import QtQuick; Timer { interval: 500; running: true; repeat: false; onTriggered: appLauncherRoot.readPacmanSearchResults() }", appLauncherRoot)
    }
    
    // Function to read pacman search results
    function readPacmanSearchResults() {
<<<<<<< HEAD
        console.log("Reading pacman search results...")
=======
>>>>>>> master
        var xhr = new XMLHttpRequest()
        xhr.open("GET", "file:///tmp/quickshell_pacman_search")
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                filteredPackages.clear()
                var output = xhr.responseText.trim()
<<<<<<< HEAD
                console.log("Search output length:", output.length)
                
                if (!output || output.length === 0) {
                    console.log("No search results found")
=======
                
                if (!output || output.length === 0) {
>>>>>>> master
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
<<<<<<< HEAD
                                console.log("Found package:", currentPackage.name, "from repo:", repoAndName[0])
=======
>>>>>>> master
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
                
<<<<<<< HEAD
                console.log("Total packages found:", filteredPackages.count)
=======
>>>>>>> master
                
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
        
<<<<<<< HEAD
        console.log("Searching AUR for packages:", query)
=======
>>>>>>> master
        
        // Check if yay or paru is available
        // Run search in background (use yay if available, otherwise paru)
        Qt.createQmlObject("import Quickshell.Io; import QtQuick; Process { command: ['sh', '-c', 'if command -v yay >/dev/null 2>&1; then yay -Ss \"" + query.replace(/"/g, '\\"') + "\" 2>/dev/null | head -50 > /tmp/quickshell_aur_search; elif command -v paru >/dev/null 2>&1; then paru -Ss \"" + query.replace(/"/g, '\\"') + "\" 2>/dev/null | head -50 > /tmp/quickshell_aur_search; else echo \"AUR helper not found\" > /tmp/quickshell_aur_search; fi']; running: true }", appLauncherRoot)
        
        // Wait a moment and read results
        Qt.createQmlObject("import QtQuick; Timer { interval: 800; running: true; repeat: false; onTriggered: appLauncherRoot.readAurSearchResults() }", appLauncherRoot)
    }
    
    // Function to read AUR search results
    function readAurSearchResults() {
<<<<<<< HEAD
        console.log("Reading AUR search results...")
=======
>>>>>>> master
        var xhr = new XMLHttpRequest()
        xhr.open("GET", "file:///tmp/quickshell_aur_search")
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                filteredPackages.clear()
                var output = xhr.responseText.trim()
<<<<<<< HEAD
                console.log("AUR search output length:", output.length)
                
                if (!output || output.length === 0 || output.indexOf("AUR helper not found") >= 0) {
                    console.log("No AUR search results found or helper not installed")
=======
                
                if (!output || output.length === 0 || output.indexOf("AUR helper not found") >= 0) {
>>>>>>> master
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
                            
<<<<<<< HEAD
                            console.log("Found AUR package:", currentPackage.name)
=======
>>>>>>> master
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
                
<<<<<<< HEAD
                console.log("Total AUR packages found:", filteredPackages.count)
=======
>>>>>>> master
                
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
<<<<<<< HEAD
        console.log("installPacmanPackage called with:", packageName)
=======
>>>>>>> master
        if (packageName) {
            // Escape package name
            var safeName = packageName.replace(/"/g, '\\"').replace(/'/g, "\\'").replace(/ /g, "\\ ")
            
            // Use bash script for installation
            var scriptPath = projectPath + "/scripts/install-package.sh"
            // Open kitty, set as floating, size 1200x700 and center
            var command = "hyprctl dispatch exec \"kitty --class=floating_kitty -e bash " + scriptPath + " " + safeName + "\"; sleep 0.3; hyprctl dispatch focuswindow \"class:floating_kitty\"; hyprctl dispatch togglefloating; hyprctl dispatch resizeactive exact 1200 700; hyprctl dispatch centerwindow"
            
<<<<<<< HEAD
            console.log("Executing command:", command)
=======
>>>>>>> master
            
            Qt.createQmlObject("import Quickshell.Io; import QtQuick; Process { command: ['sh', '-c', '" + command.replace(/'/g, "\\'") + "']; running: true }", appLauncherRoot)
            
            if (sharedData) {
                sharedData.launcherVisible = false
            }
        } else {
<<<<<<< HEAD
            console.log("Package name is empty or null")
=======
>>>>>>> master
        }
    }
    
    // Function to install AUR package
    function installAurPackage(packageName) {
<<<<<<< HEAD
        console.log("installAurPackage called with:", packageName)
=======
>>>>>>> master
        if (packageName) {
            // Escape package name
            var safeName = packageName.replace(/"/g, '\\"').replace(/'/g, "\\'").replace(/ /g, "\\ ")
            
            // Use bash script for AUR installation
            var scriptPath = projectPath + "/scripts/install-aur-package.sh"
            // Open kitty, set as floating, size 1200x700 and center
            var command = "hyprctl dispatch exec \"kitty --class=floating_kitty -e bash " + scriptPath + " " + safeName + "\"; sleep 0.3; hyprctl dispatch focuswindow \"class:floating_kitty\"; hyprctl dispatch togglefloating; hyprctl dispatch resizeactive exact 1200 700; hyprctl dispatch centerwindow"
            
<<<<<<< HEAD
            console.log("Executing command:", command)
=======
>>>>>>> master
            
            Qt.createQmlObject("import Quickshell.Io; import QtQuick; Process { command: ['sh', '-c', '" + command.replace(/'/g, "\\'") + "']; running: true }", appLauncherRoot)
            
            if (sharedData) {
                sharedData.launcherVisible = false
            }
        } else {
<<<<<<< HEAD
            console.log("Package name is empty or null")
=======
>>>>>>> master
        }
    }
    
    // Function to load installed packages
    function loadInstalledPackages() {
        installedPackages = []
        filteredInstalledPackages.clear()
        
<<<<<<< HEAD
        console.log("Loading installed packages...")
=======
>>>>>>> master
        
        // Run pacman -Q and save to file
        Qt.createQmlObject("import Quickshell.Io; import QtQuick; Process { command: ['sh', '-c', 'pacman -Q 2>/dev/null > /tmp/quickshell_installed_packages']; running: true }", appLauncherRoot)
        
        // Wait a moment and read results
        Qt.createQmlObject("import QtQuick; Timer { interval: 300; running: true; repeat: false; onTriggered: appLauncherRoot.readInstalledPackages() }", appLauncherRoot)
    }
    
    // Function to read installed packages
    function readInstalledPackages() {
<<<<<<< HEAD
        console.log("Reading installed packages...")
=======
>>>>>>> master
        var xhr = new XMLHttpRequest()
        xhr.open("GET", "file:///tmp/quickshell_installed_packages")
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                installedPackages = []
                var output = xhr.responseText.trim()
                
                if (!output || output.length === 0) {
<<<<<<< HEAD
                    console.log("No installed packages found")
=======
>>>>>>> master
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
                
<<<<<<< HEAD
                console.log("Loaded", installedPackages.length, "installed packages")
=======
>>>>>>> master
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
<<<<<<< HEAD
        console.log("removePacmanPackage called with:", packageName)
=======
>>>>>>> master
        if (packageName) {
            // Escape package name
            var safeName = packageName.replace(/"/g, '\\"').replace(/'/g, "\\'").replace(/ /g, "\\ ")
            
            // Use bash script for removal
            var scriptPath = projectPath + "/scripts/remove-package.sh"
            // Open kitty, set as floating, size 1200x700 and center
            var command = "hyprctl dispatch exec \"kitty --class=floating_kitty -e bash " + scriptPath + " " + safeName + "\"; sleep 0.3; hyprctl dispatch focuswindow \"class:floating_kitty\"; hyprctl dispatch togglefloating; hyprctl dispatch resizeactive exact 1200 700; hyprctl dispatch centerwindow"
            
<<<<<<< HEAD
            console.log("Executing command:", command)
=======
>>>>>>> master
            
            Qt.createQmlObject("import Quickshell.Io; import QtQuick; Process { command: ['sh', '-c', '" + command.replace(/'/g, "\\'") + "']; running: true }", appLauncherRoot)
            
            if (sharedData) {
                sharedData.launcherVisible = false
            }
        } else {
<<<<<<< HEAD
            console.log("Package name is empty or null")
=======
>>>>>>> master
        }
    }
    
    // Funkcja usuwania pakietu z AUR
    function removeAurPackage(packageName) {
<<<<<<< HEAD
        console.log("removeAurPackage called with:", packageName)
=======
>>>>>>> master
        if (packageName) {
            // Escapuj nazwę pakietu
            var safeName = packageName.replace(/"/g, '\\"').replace(/'/g, "\\'").replace(/ /g, "\\ ")
            
            // Użyj skryptu bash do usuwania AUR
            var scriptPath = projectPath + "/scripts/remove-aur-package.sh"
            // Otwórz kitty, ustaw jako floating, rozmiar 1200x700 i wyśrodkuj
            var command = "hyprctl dispatch exec \"kitty --class=floating_kitty -e bash " + scriptPath + " " + safeName + "\"; sleep 0.3; hyprctl dispatch focuswindow \"class:floating_kitty\"; hyprctl dispatch togglefloating; hyprctl dispatch resizeactive exact 1200 700; hyprctl dispatch centerwindow"
            
<<<<<<< HEAD
            console.log("Executing command:", command)
=======
>>>>>>> master
            
            Qt.createQmlObject("import Quickshell.Io; import QtQuick; Process { command: ['sh', '-c', '" + command.replace(/'/g, "\\'") + "']; running: true }", appLauncherRoot)
            
            if (sharedData) {
                sharedData.launcherVisible = false
            }
        } else {
<<<<<<< HEAD
            console.log("Package name is empty or null")
        }
    }
    
    // Obserwuj zmiany launcherVisible
    Connections {
        target: sharedData
        function onLauncherVisibleChanged() {
            if (sharedData && sharedData.launcherVisible) {
                // Reset do wyboru trybu
=======
        }
    }
    
    // Jeden Timer na focus przy otwarciu – krótki interval = focus od razu z pojawieniem się
    Timer {
        id: launcherOpenFocusTimer
        interval: 30
        repeat: false
        running: false
        onTriggered: {
            if (launcherContainer && sharedData && sharedData.launcherVisible) {
                launcherContainer.forceActiveFocus()
            }
        }
    }

    Connections {
        target: sharedData
        enabled: !!sharedData
        function onLauncherVisibleChanged() {
            if (sharedData && sharedData.launcherVisible) {
>>>>>>> master
                currentMode = -1
                currentPackageMode = -1
                installSourceMode = -1
                removeSourceMode = -1
                searchInput.text = ""
                searchText = ""
                packageSearchText = ""
                selectedIndex = 0
<<<<<<< HEAD
                
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
=======
                launcherOpenFocusTimer.restart()
            } else {
>>>>>>> master
                searchInput.focus = false
                pacmanSearchInput.focus = false
                aurSearchInput.focus = false
                removeSearchInput.focus = false
                removeAurSearchInput.focus = false
                launcherContainer.focus = false
            }
        }
    }
    
<<<<<<< HEAD
    // Kontener z zawartością
    Item {
        id: launcherContainer
        anchors.fill: parent
        opacity: (sharedData && sharedData.launcherVisible) ? 1.0 : 0.0
        enabled: opacity > 0.1  // Wyłącz interakcję gdy niewidoczne
        focus: (sharedData && sharedData.launcherVisible)  // Focus dla klawiatury
        scale: (sharedData && sharedData.launcherVisible) ? 1.0 : 0.95
        
        Behavior on opacity {
            NumberAnimation {
                duration: 350
                easing.type: Easing.OutQuart
            }
        }
        
        Behavior on scale {
            NumberAnimation {
                duration: 450
                easing.type: Easing.OutBack
                easing.amplitude: 1.1
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
        
        // Tło z gradientem
=======
    // Kontener z zawartością – opacity/scale/enabled z jednego launcherShowProgress
    Item {
        id: launcherContainer
        anchors.fill: parent
        opacity: launcherShowProgress
        enabled: launcherShowProgress > 0.02
        focus: launcherShowProgress > 0.02
        scale: 0.95 + 0.05 * launcherShowProgress
        transformOrigin: Item.Bottom
        
        // Window movement handles the slide animation


        // Tło z gradientem
        // Material Design launcher background with elevation
>>>>>>> master
        Rectangle {
            id: launcherBackground
            anchors.fill: parent
            radius: 0
            
            // Użyj sharedData.colorBackground jeśli dostępny - jednolite tło bez gradientu
            color: (sharedData && sharedData.colorBackground) ? sharedData.colorBackground : colorBackground
<<<<<<< HEAD
=======
            
            // Material Design elevation shadow
            Rectangle {
                anchors.fill: parent
                anchors.margins: -3
                color: "transparent"
                border.color: Qt.rgba(0, 0, 0, 0.25)  // Material shadow
                border.width: 2
                z: -1
            }
>>>>>>> master
        }
        
        // Obsługa klawiszy na kontenerze - przekieruj do TextInput tylko w trybie Launch App
        Keys.forwardTo: (currentMode === 0) ? [searchInput] : []
        
        Keys.onPressed: function(event) {
            // Escape - zamknij launcher lub wróć do wyboru trybu
            if (event.key === Qt.Key_Escape) {
<<<<<<< HEAD
                if (currentMode === -1) {
                    // Jeśli jesteśmy w wyborze trybu, zamknij launcher
                    if (sharedData) {
                        sharedData.launcherVisible = false
                    }
=======
                if (currentMode === -1 || currentMode === 0) {
                    // Wybór trybu lub Launch App – jeden Escape zamyka launcher
                    if (sharedData) {
                        sharedData.launcherVisible = false
                    }
                    event.accepted = true
                    return
>>>>>>> master
                } else if (currentMode === 3 && currentNotesMode !== -1) {
                    // W edytorze notes - wróć do menu notes
                    currentNotesMode = -1
                    selectedIndex = 0
                } else if (currentMode === 3 && currentNotesMode === -1) {
                    // W menu notes - wróć do wyboru trybu
                    currentMode = -1
                    selectedIndex = 2  // Wróć do pozycji Notes w menu
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
<<<<<<< HEAD
                    // W trybie Bluetooth - nawigacja po liście urządzeń
                    if (bluetoothSelectedIndex < bluetoothDevicesModel.count - 1) {
                        bluetoothSelectedIndex++
                        bluetoothDevicesList.currentIndex = bluetoothSelectedIndex
                        bluetoothDevicesList.positionViewAtIndex(bluetoothSelectedIndex, ListView.Center)
                    }
                    event.accepted = true
=======
>>>>>>> master
                }
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                // Enter - wybierz tryb, pakiet lub aplikację
                if (currentMode === -1) {
                    // Wybierz tryb
                    if (selectedIndex >= 0 && selectedIndex < modesList.count) {
                        var mode = modesList.model.get(selectedIndex)
                        if (mode.mode === 2) {
<<<<<<< HEAD
                            // Launch settings application instead of entering settings mode
                            Qt.createQmlObject("import Quickshell.Io; Process { command: ['" + projectPath + "/open-settings.sh']; running: true }", appLauncherRoot)
                            // Close launcher after launching settings
                            if (sharedData) {
                                sharedData.launcherVisible = false
                            }
                        } else {
=======
                            // Launch fuse directly using Process
                            Qt.createQmlObject("import Quickshell.Io; Process { command: ['sh', '-c', 'fuse &']; running: true }", appLauncherRoot)
                            if (sharedData) {
                                sharedData.launcherVisible = false
                            }
                            event.accepted = true
                            return
                        }
>>>>>>> master
                            currentMode = mode.mode
                            selectedIndex = 0
                            modesList.currentIndex = -1
                            appsList.currentIndex = -1
                            packagesOptionsList.currentIndex = -1
                            if (currentMode === 1) {
                                currentPackageMode = -1
                                installSourceMode = -1
                                removeSourceMode = -1
<<<<<<< HEAD
                            } else if (currentMode === 3) {
                                currentNotesMode = -1
                                notesMenuIndex = 0
                                loadNotesList()
                            }
                        }
=======
                            }
>>>>>>> master
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
<<<<<<< HEAD
                    // W trybie Bluetooth - połącz z wybranym urządzeniem
                    if (bluetoothSelectedIndex >= 0 && bluetoothSelectedIndex < bluetoothDevicesModel.count && !bluetoothConnecting) {
                        var device = bluetoothDevicesModel.get(bluetoothSelectedIndex)
                        if (device && device.mac) {
                            connectBluetoothDevice(device.mac)
                        }
                    }
                    event.accepted = true
=======
>>>>>>> master
                } else if (currentMode === 0) {
                    // W trybie Launch App - przekieruj do TextInput
                    searchInput.forceActiveFocus()
                    event.accepted = false
                }
<<<<<<< HEAD
            } else if (currentMode === 0) {
                // W trybie Launch App - przekieruj do TextInput
                searchInput.forceActiveFocus()
                event.accepted = false  // Pozwól propagować
=======
>>>>>>> master
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
<<<<<<< HEAD
                } else if (currentMode === 3 && currentNotesMode === -1) {
                    // W menu notes - nawigacja po menu (przycisk nowa + lista notatek)
                    if (event.key === Qt.Key_Up) {
                        if (notesMenuIndex > 0) {
                            notesMenuIndex--
                            if (notesMenuIndex > 0) {
                                // W liście notatek
                                selectedIndex = notesMenuIndex - 1
                                notesList.positionViewAtIndex(selectedIndex, ListView.Center)
                            }
                        }
                        event.accepted = true
                    } else if (event.key === Qt.Key_Down) {
                        var maxIndex = notesModel.count // 0 = new note button, 1+ = notes
                        if (notesMenuIndex < maxIndex) {
                            notesMenuIndex++
                            if (notesMenuIndex > 0) {
                                // W liście notatek
                                selectedIndex = notesMenuIndex - 1
                                notesList.positionViewAtIndex(selectedIndex, ListView.Center)
                            }
                        }
                        event.accepted = true
                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        if (notesMenuIndex === 0) {
                            // Nowa notatka
                            console.log("Creating new note")
                            currentNotesMode = 0
                            notesEditText.text = ""
                            notesFileName = ""
                        } else {
                            // Wybierz istniejącą notatkę
                            var noteIndex = notesMenuIndex - 1
                            var noteItem = notesModel.get(noteIndex)
                            console.log("Opening existing note:", noteItem.name, "file:", noteItem.file)
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
=======
            }
        }
        
        // Lista trybów (gdy currentMode === -1) - NOWY DESIGN
>>>>>>> master
        ListView {
            id: modesList
            anchors.fill: parent
            anchors.margins: 20
            visible: currentMode === -1
<<<<<<< HEAD
=======
            focus: currentMode === -1 // Ensure focus for keyboard navigation
>>>>>>> master
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
<<<<<<< HEAD
                ListElement { name: "Notes"; description: "Quick notes and reminders"; mode: 3; icon: "󰎞" }
                ListElement { name: "Settings"; description: "Open settings application"; mode: 2; icon: "󰒓" }
=======
                ListElement { name: "Fuse"; description: "Open settings application"; mode: 2; icon: "󰒓" }
>>>>>>> master
            }
            
            delegate: Rectangle {
                id: modeItem
                width: modesList.width
<<<<<<< HEAD
                height: 72
                color: "transparent"
                radius: 0
                scale: (selectedIndex === index || modeItemMouseArea.containsMouse) ? 1.02 : 1.0

                // Bottom accent line for selected items
                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: (selectedIndex === index && parent) ? parent.width * 0.8 : 0
                    height: 3
                    color: (sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff"
                    radius: 1.5

                    Behavior on width {
                        NumberAnimation {
                            duration: 300
=======
                height: 50
                radius: 0
                color: (selectedIndex === index || modeItemMouseArea.containsMouse) ?
                    ((sharedData && sharedData.colorPrimary) ? sharedData.colorPrimary : "#1a1a1a") :
                    "transparent"
                
                opacity: (sharedData && sharedData.launcherVisible) ? 1 : 0
                scale: (sharedData && sharedData.launcherVisible) ? 1 : 0.8
                
                transform: Translate {
                    y: (sharedData && sharedData.launcherVisible) ? 0 : 40
                }

                Behavior on opacity {
                    SequentialAnimation {
                        PauseAnimation { duration: Math.min(index * 40, 400) }
                        NumberAnimation { duration: 500; easing.type: Easing.OutCubic }
                    }
                }
                
                Behavior on scale {
                    SequentialAnimation {
                        PauseAnimation { duration: Math.min(index * 40, 400) }
                        NumberAnimation { duration: 600; easing.type: Easing.OutBack }
                    }
                }
                
                Behavior on transform {
                    SequentialAnimation {
                        PauseAnimation { duration: Math.min(index * 40, 400) }
                        PropertyAnimation { property: "y"; duration: 700; easing.type: Easing.OutBack }
                    }
                }

                Behavior on color {
                    ColorAnimation { 
                        duration: 150
                        easing.type: Easing.OutCubic
                    }
                }
                
                // Left accent bar for selected items
                Rectangle {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: selectedIndex === index ? 3 : 0
                    color: (sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff"
                    
                    Behavior on width {
                        NumberAnimation {
                            duration: 200
>>>>>>> master
                            easing.type: Easing.OutCubic
                        }
                    }
                }
                
<<<<<<< HEAD
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
                            font.family: "sans-serif"
                            font.weight: selectedIndex === index ? Font.Bold : Font.Medium
                            color: selectedIndex === index ? colorText : (modeItemMouseArea.containsMouse ? colorText : ((sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff"))
                        }
                        
                        Text {
                            text: model.description
                            font.pixelSize: 12
                            font.family: "sans-serif"
                            color: (sharedData && sharedData.colorText) ? sharedData.colorText : colorText
                            opacity: selectedIndex === index ? 0.85 : (modeItemMouseArea.containsMouse ? 0.75 : 0.6)
=======
                // Content container
                Item {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    
                    Row {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 12
                        
                        // Icon
                        Text {
                            text: model.icon || ""
                            font.pixelSize: 20
                            color: (sharedData && sharedData.colorText) ? sharedData.colorText : colorText
                            anchors.verticalCenter: parent.verticalCenter
                            width: 24
                            horizontalAlignment: Text.AlignLeft
                        }
                        
                        // Text content
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2
                            width: parent.width - 36  // Total width minus icon (24) and spacing (12)
                            
                            Text {
                                text: model.name
                                font.pixelSize: 15
                                font.family: "sans-serif"
                                font.weight: selectedIndex === index ? Font.Bold : Font.Normal
                                color: (sharedData && sharedData.colorText) ? sharedData.colorText : colorText
                                width: parent.width
                                elide: Text.ElideRight
                            }
                            
                            Text {
                                text: model.description
                                font.pixelSize: 12
                                font.family: "sans-serif"
                                color: (sharedData && sharedData.colorText) ? sharedData.colorText : colorText
                                opacity: 0.7
                                width: parent.width
                                elide: Text.ElideRight
                            }
>>>>>>> master
                        }
                    }
                }
                
                MouseArea {
                    id: modeItemMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    
                    onEntered: {
                        if (modesList.currentIndex !== index) {
<<<<<<< HEAD
                        selectedIndex = index
=======
                            selectedIndex = index
>>>>>>> master
                            modesList.currentIndex = index
                        }
                    }
                    
                    onClicked: {
                        if (model.mode === 2) {
<<<<<<< HEAD
                            // Launch settings application instead of entering settings mode
                            Qt.createQmlObject("import Quickshell.Io; Process { command: ['" + projectPath + "/open-settings.sh']; running: true }", appLauncherRoot)
                            // Close launcher after launching settings
                            if (sharedData) {
                                sharedData.launcherVisible = false
                            }
                        } else {
                            currentMode = model.mode
                            selectedIndex = 0
                            modesList.currentIndex = -1
                            if (model.mode === 1) {
                                currentPackageMode = -1
                            }
=======
                            // Launch fuse directly using Process
                            Qt.createQmlObject("import Quickshell.Io; Process { command: ['sh', '-c', 'fuse &']; running: true }", appLauncherRoot)
                            if (sharedData) {
                                sharedData.launcherVisible = false
                            }
                            return
                        }
                        currentMode = model.mode
                        selectedIndex = 0
                        modesList.currentIndex = -1
                        if (model.mode === 1) {
                            currentPackageMode = -1
>>>>>>> master
                        }
                    }
                }
            }
        }
        
<<<<<<< HEAD
        // Zawartość trybów
=======
        // Zawartość trybów – te same marginesy co strona główna (20)
>>>>>>> master
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
<<<<<<< HEAD
                    spacing: 12
=======
                    spacing: 9
>>>>>>> master
                            
                            // Pole wyszukiwania
                            Rectangle {
                                id: searchBox
                                width: parent.width
<<<<<<< HEAD
                                height: 48
                                color: searchInput.activeFocus ? colorPrimary : colorSecondary
                                radius: 0
                                
=======
                                height: 36
                                color: searchInput.activeFocus ? colorPrimary : colorSecondary
                                radius: 0
                                
                                opacity: (sharedData && sharedData.launcherVisible && currentMode === 0) ? 1 : 0
                                scale: (sharedData && sharedData.launcherVisible && currentMode === 0) ? 1 : 0.9
                                transform: Translate {
                                    y: (sharedData && sharedData.launcherVisible && currentMode === 0) ? 0 : 20
                                }

                                Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
                                Behavior on scale { NumberAnimation { duration: 500; easing.type: Easing.OutBack } }
                                Behavior on transform { PropertyAnimation { property: "y"; duration: 600; easing.type: Easing.OutBack } }

>>>>>>> master
                                Behavior on color {
                                    ColorAnimation { 
                                        duration: 180
                                        easing.type: Easing.OutQuart
<<<<<<< HEAD
                                }
=======
                                    }
>>>>>>> master
                                }
                                
                                TextInput {
                                    id: searchInput
                                    anchors.fill: parent
<<<<<<< HEAD
                                    anchors.margins: 20
                                    font.pixelSize: 15
=======
                                    anchors.margins: 14
                                    font.pixelSize: 16
>>>>>>> master
                                    font.family: "sans-serif"
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
                                            
<<<<<<< HEAD
=======
                                            // Check if search text is "fuse" - launch fuse application
                                            if (searchText && searchText.trim().toLowerCase() === "fuse") {
                                                Qt.createQmlObject("import Quickshell.Io; Process { command: ['sh', '-c', 'fuse 2>/dev/null || $HOME/.local/bin/fuse 2>/dev/null || " + projectPath + "/../fuse/target/release/fuse 2>/dev/null']; running: true }", appLauncherRoot)
                                                if (sharedData) {
                                                    sharedData.launcherVisible = false
                                                }
                                                event.accepted = true
                                                return
                                            }
                                            
>>>>>>> master
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
<<<<<<< HEAD
                                    font.pixelSize: 15
=======
                                    font.pixelSize: 16
>>>>>>> master
                                    font.family: "sans-serif"
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
<<<<<<< HEAD
                                spacing: 4
=======
                                spacing: 8
>>>>>>> master
                                
                                model: filteredApps
                                currentIndex: selectedIndex
                                
                                onCurrentIndexChanged: {
                                    if (currentIndex !== selectedIndex) {
                                        selectedIndex = currentIndex
                                    }
                                }
                                
<<<<<<< HEAD
                                // Staggered entry for items
                                add: Transition {
                                    ParallelAnimation {
                                        NumberAnimation {
                                            property: "opacity"
                                            from: 0
                                            to: 1
                                            duration: 400
                                            easing.type: Easing.OutQuart
                                        }
                                        NumberAnimation {
                                            property: "scale"
                                            from: 0.9
                                            to: 1
                                            duration: 500
                                            easing.type: Easing.OutBack
                                        }
                                        NumberAnimation {
                                            property: "x"
                                            from: -20
                                            to: 0
                                            duration: 500
                                            easing.type: Easing.OutExpo
                                        }
                                    }
                                }
                                
                                addDisplaced: Transition {
                                    NumberAnimation {
                                        properties: "y"
                                        duration: 400
                                        easing.type: Easing.OutBack
                                    }
                                }
                                
                                removeDisplaced: Transition {
                                    NumberAnimation {
                                        properties: "y"
                                        duration: 300
                                        easing.type: Easing.OutQuart
                                    }
=======
                                // Animacje przejść dla wyników wyszukiwania
                                add: Transition { 
                                    NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 250; easing.type: Easing.OutCubic }
                                    NumberAnimation { property: "scale"; from: 0.95; to: 1; duration: 300; easing.type: Easing.OutBack }
                                }
                                addDisplaced: Transition { 
                                    NumberAnimation { properties: "y"; duration: 300; easing.type: Easing.OutBack } 
                                }
                                removeDisplaced: Transition { 
                                    NumberAnimation { properties: "y"; duration: 300; easing.type: Easing.OutBack } 
>>>>>>> master
                                }
                                
                                delegate: Rectangle {
                                    id: appItem
                                    width: appsList.width
<<<<<<< HEAD
                                    height: 72
                                    color: (selectedIndex === index) ? (sharedData && sharedData.colorPrimary ? Qt.darker(sharedData.colorPrimary, 0.85) : "#2a2a2a") : "transparent"
                                    radius: 0
                                    scale: (selectedIndex === index || appItemMouseArea.containsMouse) ? 1.02 : 1.0
                                    
                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 250
                                            easing.type: Easing.OutQuart
=======
                                    height: 50
                                    radius: 0
                                    
                                    opacity: (sharedData && sharedData.launcherVisible && currentMode === 0) ? 1 : 0
                                    scale: (sharedData && sharedData.launcherVisible && currentMode === 0) ? 1 : 0.8
                                    
                                    transform: Translate {
                                        y: (sharedData && sharedData.launcherVisible && currentMode === 0) ? 0 : 40
                                    }

                                    Behavior on opacity {
                                        SequentialAnimation {
                                            PauseAnimation { duration: Math.min(index * 40, 400) }
                                            NumberAnimation { duration: 500; easing.type: Easing.OutCubic }
>>>>>>> master
                                        }
                                    }
                                    
                                    Behavior on scale {
<<<<<<< HEAD
                                        SpringAnimation {
                                            spring: 4.5
                                            damping: 0.45
                                            epsilon: 0.005
                                        }
                                    }

                                // Bottom accent line for selected items
                                Rectangle {
                                    anchors.bottom: parent.bottom
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: (selectedIndex === index && parent) ? parent.width * 0.8 : 0
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
                                        font.family: "sans-serif"
                                        font.weight: selectedIndex === index ? Font.Bold : Font.Medium
                                        font.letterSpacing: 0.1
                                        color: selectedIndex === index ? colorText : (appItemMouseArea.containsMouse ? colorText : ((sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff"))
                                    }

                                    Text {
                                        text: appItem.appComment
                                        font.pixelSize: 12
                                        font.family: "sans-serif"
                                        font.weight: Font.Normal
                                        font.letterSpacing: 0.1
                                        color: (sharedData && sharedData.colorText) ? sharedData.colorText : colorText
                                        opacity: selectedIndex === index ? 0.85 : (appItemMouseArea.containsMouse ? 0.75 : 0.6)
                                        visible: appItem.appComment && appItem.appComment.length > 0
                                    }
                                }
=======
                                        SequentialAnimation {
                                            PauseAnimation { duration: Math.min(index * 40, 400) }
                                            NumberAnimation { duration: 600; easing.type: Easing.OutBack }
                                        }
                                    }
                                    
                                    Behavior on transform {
                                        SequentialAnimation {
                                            PauseAnimation { duration: Math.min(index * 40, 400) }
                                            PropertyAnimation { property: "y"; duration: 700; easing.type: Easing.OutBack }
                                        }
                                    }
                                    color: (selectedIndex === index || appItemMouseArea.containsMouse) ?
                                        ((sharedData && sharedData.colorPrimary) ? sharedData.colorPrimary : "#1a1a1a") :
                                        "transparent"
                                    
                                    Behavior on color {
                                        ColorAnimation { duration: 150; easing.type: Easing.OutCubic }
                                    }
                                    
                                    Rectangle {
                                        anchors.left: parent.left
                                        anchors.top: parent.top
                                        anchors.bottom: parent.bottom
                                        width: selectedIndex === index ? 3 : 0
                                        color: (sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff"
                                        Behavior on width {
                                            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                                        }
                                    }
                                    
                                    property string appName: model.name || "Unknown"
                                    property string appComment: model.comment || ""
                                    property string appExec: model.exec || ""
                                    property string appIcon: model.icon || ""
                                    property bool appIsCalculator: model.isCalculator || false
                                    
                                    Column {
                                        id: appTextColumn
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.leftMargin: 16
                                        anchors.rightMargin: 16
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 2
                                        width: parent.width - 32
                                        
                                        Text {
                                            width: parent.width
                                            text: appItem.appName
                                            font.pixelSize: 15
                                            font.family: "sans-serif"
                                            font.weight: selectedIndex === index ? Font.Bold : Font.Normal
                                            elide: Text.ElideRight
                                            maximumLineCount: 1
                                            color: (sharedData && sharedData.colorText) ? sharedData.colorText : colorText
                                        }
                                        Text {
                                            width: parent.width
                                            text: appItem.appComment
                                            font.pixelSize: 12
                                            font.family: "sans-serif"
                                            elide: Text.ElideRight
                                            maximumLineCount: 1
                                            color: (sharedData && sharedData.colorText) ? sharedData.colorText : colorText
                                            opacity: 0.7
                                            visible: appItem.appComment && appItem.appComment.length > 0
                                        }
                                    }
>>>>>>> master
                                
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
<<<<<<< HEAD
                    }
                }
            }
            
            // Tryb 1: Packages - prosta lista (tło usunięte - używa głównego tła)
=======
                }
            }
            
            // Tryb 1: Packages – ten sam wygląd co strona główna (height 50, radius 4, lewy pasek)
>>>>>>> master
            
            ListView {
                id: packagesOptionsList
                anchors.fill: parent
                anchors.margins: 20
<<<<<<< HEAD
=======
                spacing: 8
>>>>>>> master
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
                
<<<<<<< HEAD
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
                        width: (selectedIndex === index && parent) ? parent.width * 0.8 : 0
                        height: 3
                        color: (sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff"
                        radius: 1.5

                        Behavior on width {
                            NumberAnimation {
                                duration: 300
                                easing.type: Easing.OutCubic
                            }
=======
                delegate: Rectangle {
                    id: packageOptionItem
                    width: packagesOptionsList.width
                    height: 50
                    radius: 0
                    color: (selectedIndex === index || packageOptionItemMouseArea.containsMouse) ?
                        ((sharedData && sharedData.colorPrimary) ? sharedData.colorPrimary : "#1a1a1a") :
                        "transparent"
                    
                    opacity: (sharedData && sharedData.launcherVisible && currentMode === 1 && currentPackageMode === -1) ? 1 : 0
                    scale: (sharedData && sharedData.launcherVisible && currentMode === 1 && currentPackageMode === -1) ? 1 : 0.8
                    
                    transform: Translate {
                        y: (sharedData && sharedData.launcherVisible && currentMode === 1 && currentPackageMode === -1) ? 0 : 40
                    }

                    Behavior on opacity {
                        SequentialAnimation {
                            PauseAnimation { duration: Math.min(index * 40, 400) }
                            NumberAnimation { duration: 500; easing.type: Easing.OutCubic }
                        }
                    }
                    
                    Behavior on scale {
                        SequentialAnimation {
                            PauseAnimation { duration: Math.min(index * 40, 400) }
                            NumberAnimation { duration: 600; easing.type: Easing.OutBack }
                        }
                    }
                    
                    Behavior on transform {
                        SequentialAnimation {
                            PauseAnimation { duration: Math.min(index * 40, 400) }
                            PropertyAnimation { property: "y"; duration: 700; easing.type: Easing.OutBack }
                        }
                    }

                    Behavior on color {
                        ColorAnimation { duration: 150; easing.type: Easing.OutCubic }
                    }
                    
                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: selectedIndex === index ? 3 : 0
                        color: (sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff"
                        Behavior on width {
                            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
>>>>>>> master
                        }
                    }
                    
                    Row {
                        anchors.left: parent.left
<<<<<<< HEAD
                        anchors.leftMargin: 20
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 16
                        
                        Text {
                            text: model.icon || ""
                            font.pixelSize: 22
                            color: (sharedData && sharedData.colorText) ? sharedData.colorText : colorText
=======
                        anchors.right: parent.right
                        anchors.leftMargin: 16
                        anchors.rightMargin: 16
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 12
                        
                        Text {
                            text: model.icon || ""
                            font.pixelSize: 20
                            color: (sharedData && sharedData.colorText) ? sharedData.colorText : colorText
                            width: 24
                            horizontalAlignment: Text.AlignLeft
>>>>>>> master
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        
                        Column {
<<<<<<< HEAD
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 4
                        
                        Text {
                            text: model.name || "Unknown"
                                font.pixelSize: 15
                            font.family: "sans-serif"
                            font.weight: selectedIndex === index ? Font.Bold : Font.Medium
                            color: selectedIndex === index ? colorText : (packageOptionItemMouseArea.containsMouse ? colorText : ((sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff"))
                        }
                        
                        Text {
                            text: model.description || ""
                                font.pixelSize: 12
                            font.family: "sans-serif"
                            color: (sharedData && sharedData.colorText) ? sharedData.colorText : colorText
                            opacity: selectedIndex === index ? 0.85 : (packageOptionItemMouseArea.containsMouse ? 0.75 : 0.6)
=======
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2
                            width: parent.width - 36
                            
                            Text {
                                text: model.name || "Unknown"
                                font.pixelSize: 15
                                font.family: "sans-serif"
                                font.weight: selectedIndex === index ? Font.Bold : Font.Normal
                                color: (sharedData && sharedData.colorText) ? sharedData.colorText : colorText
                                width: parent.width
                                elide: Text.ElideRight
                            }
                            Text {
                                text: model.description || ""
                                font.pixelSize: 12
                                font.family: "sans-serif"
                                color: (sharedData && sharedData.colorText) ? sharedData.colorText : colorText
                                opacity: 0.7
                                width: parent.width
                                elide: Text.ElideRight
>>>>>>> master
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
            
<<<<<<< HEAD
            // Wybór źródła instalacji (Pacman/AUR) - gdy currentPackageMode === 0
=======
            // Wybór źródła instalacji (Pacman/AUR) – ten sam wygląd co strona główna
>>>>>>> master
            ListView {
                id: installSourceList
                anchors.fill: parent
                anchors.margins: 20
<<<<<<< HEAD
=======
                spacing: 8
>>>>>>> master
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
<<<<<<< HEAD
                    height: 72
                    color: "transparent"
                    radius: 0
                    scale: (selectedIndex === index || installSourceItemMouseArea.containsMouse) ? 1.02 : 1.0

                    // Bottom accent line for selected items
                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: (selectedIndex === index && parent) ? parent.width * 0.8 : 0
                        height: 3
                        color: (sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff"
                        radius: 1.5

                        Behavior on width {
                            NumberAnimation {
                                duration: 300
                                easing.type: Easing.OutCubic
                            }
=======
                    height: 50
                    radius: 0
                    color: (selectedIndex === index || installSourceItemMouseArea.containsMouse) ?
                        ((sharedData && sharedData.colorPrimary) ? sharedData.colorPrimary : "#1a1a1a") :
                        "transparent"
                    
                    opacity: (sharedData && sharedData.launcherVisible && currentMode === 1 && currentPackageMode === 0) ? 1 : 0
                    scale: (sharedData && sharedData.launcherVisible && currentMode === 1 && currentPackageMode === 0) ? 1 : 0.8
                    
                    transform: Translate {
                        y: (sharedData && sharedData.launcherVisible && currentMode === 1 && currentPackageMode === 0) ? 0 : 40
                    }

                    Behavior on opacity {
                        SequentialAnimation {
                            PauseAnimation { duration: Math.min(index * 40, 400) }
                            NumberAnimation { duration: 500; easing.type: Easing.OutCubic }
                        }
                    }
                    
                    Behavior on scale {
                        SequentialAnimation {
                            PauseAnimation { duration: Math.min(index * 40, 400) }
                            NumberAnimation { duration: 600; easing.type: Easing.OutBack }
                        }
                    }
                    
                    Behavior on transform {
                        SequentialAnimation {
                            PauseAnimation { duration: Math.min(index * 40, 400) }
                            PropertyAnimation { property: "y"; duration: 700; easing.type: Easing.OutBack }
                        }
                    }

                    Behavior on color {
                        ColorAnimation { duration: 150; easing.type: Easing.OutCubic }
                    }
                    
                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: selectedIndex === index ? 3 : 0
                        color: (sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff"
                        Behavior on width {
                            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
>>>>>>> master
                        }
                    }
                    
                    Row {
                        anchors.left: parent.left
<<<<<<< HEAD
                        anchors.leftMargin: 20
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 16
                        
                        Text {
                            text: model.icon || ""
                            font.pixelSize: 22
                            color: (sharedData && sharedData.colorText) ? sharedData.colorText : colorText
=======
                        anchors.right: parent.right
                        anchors.leftMargin: 16
                        anchors.rightMargin: 16
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 12
                        
                        Text {
                            text: model.icon || ""
                            font.pixelSize: 20
                            color: (sharedData && sharedData.colorText) ? sharedData.colorText : colorText
                            width: 24
                            horizontalAlignment: Text.AlignLeft
>>>>>>> master
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
<<<<<<< HEAD
                            spacing: 4
=======
                            spacing: 2
                            width: parent.width - 36
>>>>>>> master
                            
                            Text {
                                text: model.name || "Unknown"
                                font.pixelSize: 15
                                font.family: "sans-serif"
<<<<<<< HEAD
                                font.weight: selectedIndex === index ? Font.Bold : Font.Medium
                                color: selectedIndex === index ? colorText : ((sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff")
                            }
                            
=======
                                font.weight: selectedIndex === index ? Font.Bold : Font.Normal
                                color: (sharedData && sharedData.colorText) ? sharedData.colorText : colorText
                                width: parent.width
                                elide: Text.ElideRight
                            }
>>>>>>> master
                            Text {
                                text: model.description || ""
                                font.pixelSize: 12
                                font.family: "sans-serif"
                                color: (sharedData && sharedData.colorText) ? sharedData.colorText : colorText
<<<<<<< HEAD
                                opacity: selectedIndex === index ? 0.85 : (installSourceItemMouseArea.containsMouse ? 0.75 : 0.6)
=======
                                opacity: 0.7
                                width: parent.width
                                elide: Text.ElideRight
>>>>>>> master
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
<<<<<<< HEAD
                    spacing: 11
=======
                    spacing: 8
>>>>>>> master
                    
                    // Pole wyszukiwania
                    Rectangle {
                        id: pacmanSearchBox
                        width: parent.width
<<<<<<< HEAD
                        height: 48
                        color: pacmanSearchInput.activeFocus ? colorPrimary : colorSecondary
                        radius: 0
                        
=======
                        height: 30
                        color: pacmanSearchInput.activeFocus ? colorPrimary : colorSecondary
                        radius: 0
                        
                        opacity: (sharedData && sharedData.launcherVisible && currentMode === 1 && currentPackageMode === 1) ? 1 : 0
                        scale: (sharedData && sharedData.launcherVisible && currentMode === 1 && currentPackageMode === 1) ? 1 : 0.9
                        transform: Translate {
                            y: (sharedData && sharedData.launcherVisible && currentMode === 1 && currentPackageMode === 1) ? 0 : 20
                        }

                        Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
                        Behavior on scale { NumberAnimation { duration: 500; easing.type: Easing.OutBack } }
                        Behavior on transform { PropertyAnimation { property: "y"; duration: 600; easing.type: Easing.OutBack } }

>>>>>>> master
                        Behavior on color {
                            ColorAnimation { duration: 180; easing.type: Easing.OutQuart }
                        }
                        
                        TextInput {
                            id: pacmanSearchInput
                            anchors.fill: parent
<<<<<<< HEAD
                            anchors.margins: 20
                            font.pixelSize: 14
=======
                            anchors.margins: 14
                            font.pixelSize: 18
>>>>>>> master
                            font.family: "sans-serif"
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
<<<<<<< HEAD
                                        console.log("Installing package:", pkg, "name:", pkg ? pkg.name : "null")
                                        if (pkg && pkg.name) {
                                            installPacmanPackage(pkg.name)
                                        } else {
                                            console.log("Package data invalid:", pkg)
                                        }
                                    } else {
                                        console.log("No package selected or list empty. Count:", filteredPackages.count, "Selected:", selectedIndex)
=======
                                        if (pkg && pkg.name) {
                                            installPacmanPackage(pkg.name)
                                        } else {
                                        }
                                    } else {
>>>>>>> master
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
<<<<<<< HEAD
                            font.pixelSize: 14
=======
                            font.pixelSize: 18
>>>>>>> master
                            font.family: "sans-serif"
                            color: (sharedData && sharedData.colorText) ? Qt.lighter(sharedData.colorText, 1.5) : "#666666"
                            verticalAlignment: Text.AlignVCenter
                            visible: pacmanSearchInput.text.length === 0
                            z: 5
                        }
                    }
                    
<<<<<<< HEAD
                    // Lista pakietów
=======
                    // Lista pakietów – ten sam wygląd co strona główna
>>>>>>> master
                    ListView {
                        id: pacmanPackagesList
                        width: parent.width
                        height: parent.height - pacmanSearchBox.height - parent.spacing
                        clip: true
<<<<<<< HEAD
=======
                        spacing: 8
>>>>>>> master
                        
                        model: filteredPackages
                        
                        delegate: Rectangle {
                            id: packageItem
                            width: pacmanPackagesList.width
<<<<<<< HEAD
                            height: 72
                            color: "transparent"
                            radius: 0
                            scale: (selectedIndex === index || packageItemMouseArea.containsMouse) ? 1.02 : 1.0

                            // Bottom accent line for selected items
                            Rectangle {
                                anchors.bottom: parent.bottom
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: (selectedIndex === index && parent) ? parent.width * 0.8 : 0
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
=======
                            height: 50
                            radius: 0
                            color: (selectedIndex === index || packageItemMouseArea.containsMouse) ?
                                ((sharedData && sharedData.colorPrimary) ? sharedData.colorPrimary : "#1a1a1a") :
                                "transparent"
                            
                            opacity: (sharedData && sharedData.launcherVisible && currentMode === 1 && currentPackageMode === 1) ? 1 : 0
                            scale: (sharedData && sharedData.launcherVisible && currentMode === 1 && currentPackageMode === 1) ? 1 : 0.8
                            
                            transform: Translate {
                                y: (sharedData && sharedData.launcherVisible && currentMode === 1 && currentPackageMode === 1) ? 0 : 40
                            }

                            Behavior on opacity {
                                SequentialAnimation {
                                    PauseAnimation { duration: Math.min(index * 40, 400) }
                                    NumberAnimation { duration: 500; easing.type: Easing.OutCubic }
                                }
                            }
                            
                            Behavior on scale {
                                SequentialAnimation {
                                    PauseAnimation { duration: Math.min(index * 40, 400) }
                                    NumberAnimation { duration: 600; easing.type: Easing.OutBack }
                                }
                            }
                            
                            Behavior on transform {
                                SequentialAnimation {
                                    PauseAnimation { duration: Math.min(index * 40, 400) }
                                    PropertyAnimation { property: "y"; duration: 700; easing.type: Easing.OutBack }
                                }
                            }

                            Behavior on color {
                                ColorAnimation { duration: 150; easing.type: Easing.OutCubic }
                            }
                            
                            Rectangle {
                                anchors.left: parent.left
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                width: selectedIndex === index ? 3 : 0
                                color: (sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff"
                                Behavior on width {
                                    NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                                }
>>>>>>> master
                            }
                            
                            property string packageName: model.name || "Unknown"
                            property string packageDescription: model.description || ""
                            
                            Column {
                                anchors.left: parent.left
<<<<<<< HEAD
                                anchors.leftMargin: 20
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 4
                                
=======
                                anchors.right: parent.right
                                anchors.leftMargin: 16
                                anchors.rightMargin: 16
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 2
                                width: parent.width - 32
>>>>>>> master
                                Text {
                                    text: packageItem.packageName
                                    font.pixelSize: 15
                                    font.family: "sans-serif"
<<<<<<< HEAD
                                    font.weight: selectedIndex === index ? Font.Bold : Font.Medium
                                    color: selectedIndex === index ? colorText : ((sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff")
                                }
                                
=======
                                    font.weight: selectedIndex === index ? Font.Bold : Font.Normal
                                    color: (sharedData && sharedData.colorText) ? sharedData.colorText : colorText
                                    width: parent.width
                                    elide: Text.ElideRight
                                }
>>>>>>> master
                                Text {
                                    text: packageItem.packageDescription
                                    font.pixelSize: 12
                                    font.family: "sans-serif"
                                    color: (sharedData && sharedData.colorText) ? sharedData.colorText : colorText
<<<<<<< HEAD
                                    opacity: selectedIndex === index ? 0.85 : (packageItemMouseArea.containsMouse ? 0.75 : 0.6)
=======
                                    opacity: 0.7
                                    width: parent.width
                                    elide: Text.ElideRight
>>>>>>> master
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
<<<<<<< HEAD
                    spacing: 11
=======
                    spacing: 8
>>>>>>> master
                    
                    // Pole wyszukiwania
                    Rectangle {
                        id: aurSearchBox
                        width: parent.width
<<<<<<< HEAD
                        height: 48
                        color: aurSearchInput.activeFocus ? colorPrimary : colorSecondary
                        radius: 0
                        
=======
                        height: 30
                        color: aurSearchInput.activeFocus ? colorPrimary : colorSecondary
                        radius: 0
                        
                        opacity: (sharedData && sharedData.launcherVisible && currentMode === 1 && currentPackageMode === 2) ? 1 : 0
                        scale: (sharedData && sharedData.launcherVisible && currentMode === 1 && currentPackageMode === 2) ? 1 : 0.9
                        transform: Translate {
                            y: (sharedData && sharedData.launcherVisible && currentMode === 1 && currentPackageMode === 2) ? 0 : 20
                        }

                        Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
                        Behavior on scale { NumberAnimation { duration: 500; easing.type: Easing.OutBack } }
                        Behavior on transform { PropertyAnimation { property: "y"; duration: 600; easing.type: Easing.OutBack } }

>>>>>>> master
                        Behavior on color {
                            ColorAnimation { duration: 180; easing.type: Easing.OutQuart }
                        }
                        
                        TextInput {
                            id: aurSearchInput
                            anchors.fill: parent
<<<<<<< HEAD
                            anchors.margins: 20
                            font.pixelSize: 14
=======
                            anchors.margins: 14
                            font.pixelSize: 18
>>>>>>> master
                            font.family: "sans-serif"
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
<<<<<<< HEAD
                                        console.log("Installing AUR package:", pkg, "name:", pkg ? pkg.name : "null")
                                        if (pkg && pkg.name) {
                                            installAurPackage(pkg.name)
                                        } else {
                                            console.log("Package data invalid:", pkg)
                                        }
                                    } else {
                                        console.log("No package selected or list empty. Count:", filteredPackages.count, "Selected:", selectedIndex)
=======
                                        if (pkg && pkg.name) {
                                            installAurPackage(pkg.name)
                                        } else {
                                        }
                                    } else {
>>>>>>> master
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
<<<<<<< HEAD
                            font.pixelSize: 14
=======
                            font.pixelSize: 18
>>>>>>> master
                            font.family: "sans-serif"
                            color: (sharedData && sharedData.colorText) ? Qt.lighter(sharedData.colorText, 1.5) : "#666666"
                            verticalAlignment: Text.AlignVCenter
                            visible: aurSearchInput.text.length === 0
                            z: 5
                        }
                    }
                    
<<<<<<< HEAD
                    // Lista pakietów AUR
=======
                    // Lista pakietów AUR – ten sam wygląd co strona główna
>>>>>>> master
                    ListView {
                        id: aurPackagesList
                        width: parent.width
                        height: parent.height - aurSearchBox.height - parent.spacing
                        clip: true
<<<<<<< HEAD
=======
                        spacing: 8
>>>>>>> master
                        
                        model: filteredPackages
                        
                        delegate: Rectangle {
                            id: aurPackageItem
                            width: aurPackagesList.width
<<<<<<< HEAD
                            height: 72
                            color: "transparent"
                            radius: 0
                            scale: (selectedIndex === index || aurPackageItemMouseArea.containsMouse) ? 1.02 : 1.0

                            // Bottom accent line for selected items
                            Rectangle {
                                anchors.bottom: parent.bottom
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: (selectedIndex === index && parent) ? parent.width * 0.8 : 0
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
=======
                            height: 50
                            radius: 0
                            color: (selectedIndex === index || aurPackageItemMouseArea.containsMouse) ?
                                ((sharedData && sharedData.colorPrimary) ? sharedData.colorPrimary : "#1a1a1a") :
                                "transparent"
                            
                            opacity: (sharedData && sharedData.launcherVisible && currentMode === 1 && currentPackageMode === 2) ? 1 : 0
                            scale: (sharedData && sharedData.launcherVisible && currentMode === 1 && currentPackageMode === 2) ? 1 : 0.8
                            
                            transform: Translate {
                                y: (sharedData && sharedData.launcherVisible && currentMode === 1 && currentPackageMode === 2) ? 0 : 40
                            }

                            Behavior on opacity {
                                SequentialAnimation {
                                    PauseAnimation { duration: Math.min(index * 40, 400) }
                                    NumberAnimation { duration: 500; easing.type: Easing.OutCubic }
                                }
                            }
                            
                            Behavior on scale {
                                SequentialAnimation {
                                    PauseAnimation { duration: Math.min(index * 40, 400) }
                                    NumberAnimation { duration: 600; easing.type: Easing.OutBack }
                                }
                            }
                            
                            Behavior on transform {
                                SequentialAnimation {
                                    PauseAnimation { duration: Math.min(index * 40, 400) }
                                    PropertyAnimation { property: "y"; duration: 700; easing.type: Easing.OutBack }
                                }
                            }

                            Behavior on color {
                                ColorAnimation { duration: 150; easing.type: Easing.OutCubic }
                            }
                            
                            Rectangle {
                                anchors.left: parent.left
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                width: selectedIndex === index ? 3 : 0
                                color: (sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff"
                                Behavior on width {
                                    NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                                }
>>>>>>> master
                            }
                            
                            property string packageName: model.name || "Unknown"
                            property string packageDescription: model.description || ""
                            
<<<<<<< HEAD
                            Column {
                                anchors.left: parent.left
                                anchors.leftMargin: 20
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 4
                                
                                Text {
                                    text: aurPackageItem.packageName
                                    font.pixelSize: 15
                                    font.family: "sans-serif"
                                    font.weight: selectedIndex === index ? Font.Bold : Font.Medium
                                    color: selectedIndex === index ? colorText : ((sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff")
                                }
                                
                                Text {
                                    text: aurPackageItem.packageDescription
                                    font.pixelSize: 12
                                    font.family: "sans-serif"
                                    color: (sharedData && sharedData.colorText) ? sharedData.colorText : colorText
                                    opacity: selectedIndex === index ? 0.85 : (aurPackageItemMouseArea.containsMouse ? 0.75 : 0.6)
                                    visible: aurPackageItem.packageDescription && aurPackageItem.packageDescription.length > 0
                                }
                            }
=======
                                Column {
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.leftMargin: 16
                                    anchors.rightMargin: 16
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 2
                                    width: parent.width - 32
                                    Text {
                                        text: aurPackageItem.packageName
                                        font.pixelSize: 15
                                        font.family: "sans-serif"
                                        font.weight: selectedIndex === index ? Font.Bold : Font.Normal
                                        color: (sharedData && sharedData.colorText) ? sharedData.colorText : colorText
                                        width: parent.width
                                        elide: Text.ElideRight
                                    }
                                    Text {
                                        text: aurPackageItem.packageDescription
                                        font.pixelSize: 12
                                        font.family: "sans-serif"
                                        color: (sharedData && sharedData.colorText) ? sharedData.colorText : colorText
                                        opacity: 0.7
                                        width: parent.width
                                        elide: Text.ElideRight
                                        visible: aurPackageItem.packageDescription && aurPackageItem.packageDescription.length > 0
                                    }
                                }
>>>>>>> master
                            
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
            
<<<<<<< HEAD
            // Wybór źródła usuwania (Pacman/AUR) - gdy currentPackageMode === 3
=======
            // Wybór źródła usuwania (Pacman/AUR) – ten sam wygląd co strona główna
>>>>>>> master
            ListView {
                id: removeSourceList
                anchors.fill: parent
                anchors.margins: 20
<<<<<<< HEAD
=======
                spacing: 8
>>>>>>> master
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
<<<<<<< HEAD
                    height: 72
                    color: "transparent"
                    radius: 0
                    scale: (selectedIndex === index || removeSourceItemMouseArea.containsMouse) ? 1.02 : 1.0

                    // Bottom accent line for selected items
                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: (selectedIndex === index && parent) ? parent.width * 0.8 : 0
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
=======
                    height: 50
                    radius: 0
                    color: (selectedIndex === index || removeSourceItemMouseArea.containsMouse) ?
                        ((sharedData && sharedData.colorPrimary) ? sharedData.colorPrimary : "#1a1a1a") :
                        "transparent"
                    
                    opacity: (sharedData && sharedData.launcherVisible && currentMode === 1 && currentPackageMode === 3) ? 1 : 0
                    scale: (sharedData && sharedData.launcherVisible && currentMode === 1 && currentPackageMode === 3) ? 1 : 0.8
                    
                    transform: Translate {
                        y: (sharedData && sharedData.launcherVisible && currentMode === 1 && currentPackageMode === 3) ? 0 : 40
                    }

                    Behavior on opacity {
                        SequentialAnimation {
                            PauseAnimation { duration: Math.min(index * 40, 400) }
                            NumberAnimation { duration: 500; easing.type: Easing.OutCubic }
>>>>>>> master
                        }
                    }
                    
                    Behavior on scale {
<<<<<<< HEAD
                        NumberAnimation {
                            duration: 200
                            easing.type: Easing.OutCubic
=======
                        SequentialAnimation {
                            PauseAnimation { duration: Math.min(index * 40, 400) }
                            NumberAnimation { duration: 600; easing.type: Easing.OutBack }
                        }
                    }
                    
                    Behavior on transform {
                        SequentialAnimation {
                            PauseAnimation { duration: Math.min(index * 40, 400) }
                            PropertyAnimation { property: "y"; duration: 700; easing.type: Easing.OutBack }
                        }
                    }

                    Behavior on color {
                        ColorAnimation { duration: 150; easing.type: Easing.OutCubic }
                    }
                    
                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: selectedIndex === index ? 3 : 0
                        color: (sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff"
                        Behavior on width {
                            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
>>>>>>> master
                        }
                    }
                    
                    Row {
                        anchors.left: parent.left
<<<<<<< HEAD
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
                            
=======
                        anchors.right: parent.right
                        anchors.leftMargin: 16
                        anchors.rightMargin: 16
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 12
                        Text {
                            text: model.icon || ""
                            font.pixelSize: 20
                            color: (sharedData && sharedData.colorText) ? sharedData.colorText : colorText
                            width: 24
                            horizontalAlignment: Text.AlignLeft
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2
                            width: parent.width - 36
>>>>>>> master
                            Text {
                                text: model.name || "Unknown"
                                font.pixelSize: 15
                                font.family: "sans-serif"
<<<<<<< HEAD
                                font.weight: selectedIndex === index ? Font.Bold : Font.Medium
                                color: selectedIndex === index ? colorText : ((sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff")
                            }
                            
=======
                                font.weight: selectedIndex === index ? Font.Bold : Font.Normal
                                color: (sharedData && sharedData.colorText) ? sharedData.colorText : colorText
                                width: parent.width
                                elide: Text.ElideRight
                            }
>>>>>>> master
                            Text {
                                text: model.description || ""
                                font.pixelSize: 12
                                font.family: "sans-serif"
                                color: (sharedData && sharedData.colorText) ? sharedData.colorText : colorText
<<<<<<< HEAD
                                opacity: selectedIndex === index ? 0.85 : (removeSourceItemMouseArea.containsMouse ? 0.75 : 0.6)
=======
                                opacity: 0.7
                                width: parent.width
                                elide: Text.ElideRight
>>>>>>> master
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
<<<<<<< HEAD
                    color: colorPrimary
                    radius: 0
                    
=======
                    color: (sharedData && sharedData.colorPrimary) ? sharedData.colorPrimary : colorPrimary
                    radius: 0
>>>>>>> master
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
<<<<<<< HEAD
                    spacing: 11
=======
                    spacing: 8
>>>>>>> master
                    
                    // Pole wyszukiwania
                    Rectangle {
                        id: removeSearchBox
                        width: parent.width
<<<<<<< HEAD
                        height: 48
                        color: removeSearchInput.activeFocus ? colorPrimary : colorSecondary
                        radius: 0
                        
=======
                        height: 30
                        color: removeSearchInput.activeFocus ? colorPrimary : colorSecondary
                        radius: 0
                        
                        opacity: (sharedData && sharedData.launcherVisible && currentMode === 1 && currentPackageMode === 4) ? 1 : 0
                        scale: (sharedData && sharedData.launcherVisible && currentMode === 1 && currentPackageMode === 4) ? 1 : 0.9
                        transform: Translate {
                            y: (sharedData && sharedData.launcherVisible && currentMode === 1 && currentPackageMode === 4) ? 0 : 20
                        }

                        Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
                        Behavior on scale { NumberAnimation { duration: 500; easing.type: Easing.OutBack } }
                        Behavior on transform { PropertyAnimation { property: "y"; duration: 600; easing.type: Easing.OutBack } }

>>>>>>> master
                        Behavior on color {
                            ColorAnimation { duration: 180; easing.type: Easing.OutQuart }
                        }
                        
                        TextInput {
                            id: removeSearchInput
                            anchors.fill: parent
<<<<<<< HEAD
                            anchors.margins: 20
                            font.pixelSize: 14
=======
                            anchors.margins: 14
                            font.pixelSize: 18
>>>>>>> master
                            font.family: "sans-serif"
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
<<<<<<< HEAD
                                        console.log("Removing package:", pkg, "name:", pkg ? pkg.name : "null")
=======
>>>>>>> master
                                        if (pkg && pkg.name) {
                                            if (currentPackageMode === 4) {
                                            removePacmanPackage(pkg.name)
                                            } else if (currentPackageMode === 5) {
                                                removeAurPackage(pkg.name)
                                            }
                                        } else {
<<<<<<< HEAD
                                            console.log("Package data invalid:", pkg)
                                        }
                                    } else {
                                        console.log("No package selected or list empty. Count:", filteredInstalledPackages.count, "Selected:", selectedIndex)
=======
                                        }
                                    } else {
>>>>>>> master
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
<<<<<<< HEAD
                            font.pixelSize: 14
=======
                            font.pixelSize: 18
>>>>>>> master
                            font.family: "sans-serif"
                            color: (sharedData && sharedData.colorText) ? Qt.lighter(sharedData.colorText, 1.5) : "#666666"
                            verticalAlignment: Text.AlignVCenter
                            visible: removeSearchInput.text.length === 0
                            z: 5
                        }
                    }
                    
<<<<<<< HEAD
                    // Lista zainstalowanych pakietów
=======
                    // Lista zainstalowanych pakietów – ten sam wygląd co strona główna
>>>>>>> master
                    ListView {
                        id: removePackagesList
                        width: parent.width
                        height: parent.height - removeSearchBox.height - parent.spacing
                        clip: true
<<<<<<< HEAD
=======
                        spacing: 8
>>>>>>> master
                        
                        model: filteredInstalledPackages
                        
                        delegate: Rectangle {
                            id: installedPackageItem
                            width: removePackagesList.width
<<<<<<< HEAD
                            height: 72
                            color: "transparent"
                            radius: 0
                            scale: (selectedIndex === index || installedPackageItemMouseArea.containsMouse) ? 1.02 : 1.0

                            // Bottom accent line for selected items
                            Rectangle {
                                anchors.bottom: parent.bottom
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: (selectedIndex === index && parent) ? parent.width * 0.8 : 0
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
=======
                            height: 50
                            radius: 0
                            color: (selectedIndex === index || installedPackageItemMouseArea.containsMouse) ?
                                ((sharedData && sharedData.colorPrimary) ? sharedData.colorPrimary : "#1a1a1a") :
                                "transparent"
                            
                            opacity: (sharedData && sharedData.launcherVisible && currentMode === 1 && (currentPackageMode === 4 || currentPackageMode === 5)) ? 1 : 0
                            scale: (sharedData && sharedData.launcherVisible && currentMode === 1 && (currentPackageMode === 4 || currentPackageMode === 5)) ? 1 : 0.8
                            
                            transform: Translate {
                                y: (sharedData && sharedData.launcherVisible && currentMode === 1 && (currentPackageMode === 4 || currentPackageMode === 5)) ? 0 : 40
                            }

                            Behavior on opacity {
                                SequentialAnimation {
                                    PauseAnimation { duration: Math.min(index * 40, 400) }
                                    NumberAnimation { duration: 500; easing.type: Easing.OutCubic }
                                }
                            }
                            
                            Behavior on scale {
                                SequentialAnimation {
                                    PauseAnimation { duration: Math.min(index * 40, 400) }
                                    NumberAnimation { duration: 600; easing.type: Easing.OutBack }
                                }
                            }
                            
                            Behavior on transform {
                                SequentialAnimation {
                                    PauseAnimation { duration: Math.min(index * 40, 400) }
                                    PropertyAnimation { property: "y"; duration: 700; easing.type: Easing.OutBack }
                                }
                            }

                            Behavior on color {
                                ColorAnimation { duration: 150; easing.type: Easing.OutCubic }
                            }
                            
                            Rectangle {
                                anchors.left: parent.left
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                width: selectedIndex === index ? 3 : 0
                                color: (sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff"
                                Behavior on width {
                                    NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                                }
>>>>>>> master
                            }
                            
                            property string packageName: model.name || "Unknown"
                            property string packageVersion: model.version || ""
                            
<<<<<<< HEAD
                            Column {
                                anchors.left: parent.left
                                anchors.leftMargin: 20
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 4
                                
                                Text {
                                    text: installedPackageItem.packageName
                                    font.pixelSize: 15
                                    font.family: "sans-serif"
                                    font.weight: selectedIndex === index ? Font.Bold : Font.Medium
                                    color: selectedIndex === index ? colorText : ((sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff")
                                }
                                
                                Text {
                                    text: installedPackageItem.packageVersion
                                    font.pixelSize: 12
                                    font.family: "sans-serif"
                                    color: (sharedData && sharedData.colorText) ? sharedData.colorText : colorText
                                    opacity: selectedIndex === index ? 0.85 : (installedPackageItemMouseArea.containsMouse ? 0.75 : 0.6)
                                    visible: installedPackageItem.packageVersion && installedPackageItem.packageVersion.length > 0
=======
                            Row {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.leftMargin: 16
                                anchors.rightMargin: 16
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 12
                                Text {
                                    text: "󰏖"
                                    font.pixelSize: 20
                                    color: (sharedData && sharedData.colorText) ? sharedData.colorText : colorText
                                    width: 24
                                    horizontalAlignment: Text.AlignLeft
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Column {
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 2
                                    width: parent.width - 36
                                    Text {
                                        text: installedPackageItem.packageName
                                        font.pixelSize: 15
                                        font.family: "sans-serif"
                                        font.weight: selectedIndex === index ? Font.Bold : Font.Normal
                                        color: (sharedData && sharedData.colorText) ? sharedData.colorText : colorText
                                        width: parent.width
                                        elide: Text.ElideRight
                                    }
                                    Text {
                                        text: installedPackageItem.packageVersion
                                        font.pixelSize: 12
                                        font.family: "sans-serif"
                                        color: (sharedData && sharedData.colorText) ? sharedData.colorText : colorText
                                        opacity: 0.7
                                        width: parent.width
                                        elide: Text.ElideRight
                                        visible: installedPackageItem.packageVersion && installedPackageItem.packageVersion.length > 0
                                    }
>>>>>>> master
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
<<<<<<< HEAD
                    spacing: 11
=======
                    spacing: 8
>>>>>>> master
                    
                    // Pole wyszukiwania
                    Rectangle {
                        id: removeAurSearchBox
                        width: parent.width
<<<<<<< HEAD
                        height: 48
                        color: removeAurSearchInput.activeFocus ? colorPrimary : colorSecondary
                        radius: 0
                        
=======
                        height: 30
                        color: removeAurSearchInput.activeFocus ? colorPrimary : colorSecondary
                        radius: 0
                        
                        opacity: (sharedData && sharedData.launcherVisible && currentMode === 1 && currentPackageMode === 5) ? 1 : 0
                        scale: (sharedData && sharedData.launcherVisible && currentMode === 1 && currentPackageMode === 5) ? 1 : 0.9
                        transform: Translate {
                            y: (sharedData && sharedData.launcherVisible && currentMode === 1 && currentPackageMode === 5) ? 0 : 20
                        }

                        Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
                        Behavior on scale { NumberAnimation { duration: 500; easing.type: Easing.OutBack } }
                        Behavior on transform { PropertyAnimation { property: "y"; duration: 600; easing.type: Easing.OutBack } }

>>>>>>> master
                        Behavior on color {
                            ColorAnimation { duration: 180; easing.type: Easing.OutQuart }
                        }
                        
                        TextInput {
                            id: removeAurSearchInput
                            anchors.fill: parent
<<<<<<< HEAD
                            anchors.margins: 20
                            font.pixelSize: 14
=======
                            anchors.margins: 14
                            font.pixelSize: 18
>>>>>>> master
                            font.family: "sans-serif"
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
<<<<<<< HEAD
                                        console.log("Removing AUR package:", pkg, "name:", pkg ? pkg.name : "null")
                                        if (pkg && pkg.name) {
                                            removeAurPackage(pkg.name)
                                        } else {
                                            console.log("Package data invalid:", pkg)
                                        }
                                    } else {
                                        console.log("No package selected or list empty. Count:", filteredInstalledPackages.count, "Selected:", selectedIndex)
=======
                                        if (pkg && pkg.name) {
                                            removeAurPackage(pkg.name)
                                        } else {
                                        }
                                    } else {
>>>>>>> master
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
<<<<<<< HEAD
                            font.pixelSize: 14
=======
                            font.pixelSize: 18
>>>>>>> master
                            font.family: "sans-serif"
                            color: (sharedData && sharedData.colorText) ? Qt.lighter(sharedData.colorText, 1.5) : "#666666"
                            verticalAlignment: Text.AlignVCenter
                            visible: removeAurSearchInput.text.length === 0
                            z: 5
                        }
                    }
                    
<<<<<<< HEAD
                    // Lista zainstalowanych pakietów AUR
=======
                    // Lista zainstalowanych pakietów AUR – ten sam wygląd co strona główna
>>>>>>> master
                    ListView {
                        id: removeAurPackagesList
                        width: parent.width
                        height: parent.height - removeAurSearchBox.height - parent.spacing
                        clip: true
<<<<<<< HEAD
=======
                        spacing: 8
>>>>>>> master
                        
                        model: filteredInstalledPackages
                        
                        delegate: Rectangle {
                            id: installedAurPackageItem
                            width: removeAurPackagesList.width
<<<<<<< HEAD
                            height: 72
                            color: "transparent"
                            radius: 0
                            scale: (selectedIndex === index || installedAurPackageItemMouseArea.containsMouse) ? 1.02 : 1.0

                            // Bottom accent line for selected items
                            Rectangle {
                                anchors.bottom: parent.bottom
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: (selectedIndex === index && parent) ? parent.width * 0.8 : 0
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
=======
                            height: 50
                            radius: 0
                            color: (selectedIndex === index || installedAurPackageItemMouseArea.containsMouse) ?
                                ((sharedData && sharedData.colorPrimary) ? sharedData.colorPrimary : "#1a1a1a") :
                                "transparent"
                            
                            Behavior on color {
                                ColorAnimation { duration: 150; easing.type: Easing.OutCubic }
                            }
                            
                            Rectangle {
                                anchors.left: parent.left
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                width: selectedIndex === index ? 3 : 0
                                color: (sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff"
                                Behavior on width {
                                    NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                                }
>>>>>>> master
                            }
                            
                            property string packageName: model.name || "Unknown"
                            property string packageVersion: model.version || ""
                            
<<<<<<< HEAD
                            Column {
                                anchors.left: parent.left
                                anchors.leftMargin: 20
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 4
                                
                                Text {
                                    text: installedAurPackageItem.packageName
                                    font.pixelSize: 14
                                    font.family: "sans-serif"
                                    font.weight: Font.Medium
                                    color: selectedIndex === index ? colorText : ((sharedData && sharedData.colorText) ? Qt.lighter(sharedData.colorText, 1.3) : "#cccccc")
                                }
                                
                                Text {
                                    text: installedAurPackageItem.packageVersion
                                    font.pixelSize: 11
                                    font.family: "sans-serif"
                                    color: (sharedData && sharedData.colorText) ? sharedData.colorText : colorText
                                    visible: installedAurPackageItem.packageVersion && installedAurPackageItem.packageVersion.length > 0
=======
                            Row {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.leftMargin: 16
                                anchors.rightMargin: 16
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 12
                                Text {
                                    text: "󰣇"
                                    font.pixelSize: 20
                                    color: (sharedData && sharedData.colorText) ? sharedData.colorText : colorText
                                    width: 24
                                    horizontalAlignment: Text.AlignLeft
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Column {
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 2
                                    width: parent.width - 36
                                    Text {
                                        text: installedAurPackageItem.packageName
                                        font.pixelSize: 15
                                        font.family: "sans-serif"
                                        font.weight: selectedIndex === index ? Font.Bold : Font.Normal
                                        color: (sharedData && sharedData.colorText) ? sharedData.colorText : colorText
                                        width: parent.width
                                        elide: Text.ElideRight
                                    }
                                    Text {
                                        text: installedAurPackageItem.packageVersion
                                        font.pixelSize: 12
                                        font.family: "sans-serif"
                                        color: (sharedData && sharedData.colorText) ? sharedData.colorText : colorText
                                        opacity: 0.7
                                        width: parent.width
                                        elide: Text.ElideRight
                                        visible: installedAurPackageItem.packageVersion && installedAurPackageItem.packageVersion.length > 0
                                    }
>>>>>>> master
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
<<<<<<< HEAD
            
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
                                font.family: "sans-serif"
                                font.weight: Font.Bold
                                color: colorText
                            }

                            // New note button
                            Rectangle {
                                id: newNoteButton
                                width: parent.width
                                height: 60
                                color: "transparent"
                                radius: 0
                                scale: (notesMenuIndex === 0 || newNoteButtonMouseArea.containsMouse) ? 1.02 : 1.0

                                Behavior on scale {
                                    NumberAnimation {
                                        duration: 150
                                        easing.type: Easing.OutQuart
                                    }
                                }

                                Text {
                                    text: "➕ Nowa notatka"
                                    font.pixelSize: 16
                                    font.family: "sans-serif"
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
                                        console.log("Creating new note")
                                        currentNotesMode = 0
                                        notesEditText.text = ""
                                        notesFileName = ""
                                    }
                                }

                                // Bottom accent line for selected items
                                Rectangle {
                                    anchors.bottom: parent.bottom
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: notesMenuIndex === 0 ? parent.width * 0.8 : 0
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

                            // Saved notes title
                            Text {
                                text: "Zapisane notatki:"
                                font.pixelSize: 14
                                font.family: "sans-serif"
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
                                    id: noteItem
                                    width: notesList.width
                                    height: 50
                                    color: (notesMenuIndex === index + 1) ? colorAccent : (notesItemMouseArea.containsMouse ? colorPrimary : "transparent")
                                    radius: 0

                                    Text {
                                        text: model.name
                                        font.pixelSize: 14
                                        font.family: "sans-serif"
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
                                            console.log("Note clicked:", model.name, "file:", model.file)
                                            if (model.file !== "") {
                                                selectedIndex = index
                                                currentNotesMode = 1
                                                notesFileName = model.file
                                                console.log("Loading note content for:", model.file)
                                                loadNoteContent(model.file)
                                            }
                                        }
                                    }

                                    // Bottom accent line for selected items
                                    Rectangle {
                                        anchors.bottom: parent.bottom
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        width: selectedIndex === index ? notesList.width * 0.8 : 0
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
                                font.family: "sans-serif"
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
                                font.family: "sans-serif"
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
                                    font.family: "sans-serif"
                                    color: colorText
                                    wrapMode: TextEdit.Wrap
                                    selectByMouse: true
                                    activeFocusOnPress: true
                                    focus: true

                                    Text {
                                        text: "Wpisz swoją notatkę tutaj..."
                                        font.pixelSize: 14
                                        font.family: "sans-serif"
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
                                        font.family: "sans-serif"
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
                                        font.family: "sans-serif"
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
=======
        }
    }
}
>>>>>>> master

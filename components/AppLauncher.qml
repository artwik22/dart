import QtQuick
import QtQml
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
        if (sharedData && sharedData.runCommand) sharedData.runCommand(['sh', '-c', 'echo "$QUICKSHELL_PROJECT_PATH" > /tmp/quickshell_project_path 2>/dev/null || true'], readProjectPath)
    }
    
    function readProjectPath() {
        var xhr = new XMLHttpRequest()
        xhr.open("GET", "file:///tmp/quickshell_project_path")
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                var path = xhr.responseText.trim()
                if (path && path.length > 0) {
                    projectPath = path
                } else {
                    // Try to detect from current script location
                    if (Qt.application && Qt.application.arguments && Qt.application.arguments.length > 0 && sharedData && sharedData.runCommand) {
                        var args = Qt.application.arguments
                        sharedData.runCommand(['sh', '-c', 'dirname "$(readlink -f "$1" 2>/dev/null || echo "$1")" 2>/dev/null | head -1 > /tmp/quickshell_script_dir || true', 'sh', args[0] || ''], readScriptDir)
                    } else {
                        // Last resort fallback
                        projectPath = "/tmp/sharpshell"
                    }
                }
            }
        }
        xhr.send()
    }
    
    function formatTime(sec) {
        if (isNaN(sec) || sec < 0) return "0:00"
        var m = Math.floor(sec / 60)
        var s = sec % 60
        return m + ":" + (s < 10 ? "0" + s : s)
    }
    

    function readScriptDir() {
        var xhr = new XMLHttpRequest()
        xhr.open("GET", "file:///tmp/quickshell_script_dir")
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                var dir = xhr.responseText.trim()
                if (dir && dir.length > 0) {
                    projectPath = dir
                } else {
                    // Last resort: use current working directory concept
                    projectPath = "/tmp/sharpshell"
                }
            }
        }
        xhr.send()
    }
    
    // Moved logic to PanelWindow.onCompleted for stability
    
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

        // Gdy launcher się otwiera i lista aplikacji jest pusta – załaduj aplikacje (np. po starcie runCommand nie był gotowy)
        function onLauncherVisibleChanged() {
            if (sharedData && sharedData.launcherVisible && apps.length === 0) {
                loadApps()
            }
        }
    }
    
    // Initialize paths from environment
    function initializePaths() {
        // Get home directory from environment
        if (sharedData && sharedData.runCommand) sharedData.runCommand(['sh', '-c', 'echo "$HOME" > /tmp/quickshell_home 2>/dev/null || true'], readHomePath)
    }

    function readHomePath() {
        var xhr = new XMLHttpRequest()
        xhr.open("GET", "file:///tmp/quickshell_home")
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                var home = xhr.responseText.trim()
                if (home && home.length > 0) {
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
                        }
                    }
                    checkXhr.send()
                } else {
                    colorConfigPath = "/tmp/sharpshell/colors.json"
                }
            }
        }
        xhr.send()
    }
    
    // Color management functions
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
        if (sharedData && sharedData.runCommand) sharedData.runCommand(['sh', '-c', cmd])
    }
    
    
    
    function updateColor(colorType, value) {
        var oldValue = ""
        switch(colorType) {
            case "background": 
                oldValue = colorBackground
                colorBackground = value
                if (sharedData) sharedData.colorBackground = value
                break
            case "primary": 
                oldValue = colorPrimary
                colorPrimary = value
                if (sharedData) sharedData.colorPrimary = value
                break
            case "secondary": 
                oldValue = colorSecondary
                colorSecondary = value
                if (sharedData) sharedData.colorSecondary = value
                break
            case "text": 
                oldValue = colorText
                colorText = value
                if (sharedData) sharedData.colorText = value
                break
            case "accent": 
                oldValue = colorAccent
                colorAccent = value
                if (sharedData) sharedData.colorAccent = value
                break
        }
        saveColors()
    }
    
    // Color presets
    function applyPreset(presetName) {
        var preset = colorPresets[presetName]
        if (!preset) {
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
    
    // Base size – zbalansowane proporcje
    property int baseWidth: 500
    property int baseHeight: 320
    

    implicitWidth: baseWidth
    implicitHeight: baseHeight
    
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
    exclusiveZone: 0
    
    // Animation stability - ensure we start at 0
    property bool animationReady: false
    Component.onCompleted: {
        initializePaths()
        if (!(projectPath && projectPath.length > 0)) loadProjectPath()
        loadApps()
        if (sharedData) {
            // Load colors from sharedData if available
            colorBackground = sharedData.colorBackground || colorBackground
            colorPrimary = sharedData.colorPrimary || colorPrimary
            colorSecondary = sharedData.colorSecondary || colorSecondary
            colorText = sharedData.colorText || colorText
            colorAccent = sharedData.colorAccent || colorAccent
        }
        // Mark as ready for animation
        animationReady = true
    }

    // Jeden sterownik animacji (jak w Dashboard) – start od 0, Binding = brak skoku na pierwszej klatce
    property real launcherShowProgress: 0
    Binding on launcherShowProgress {
        when: animationReady
        value: (sharedData && sharedData.launcherVisible) ? 1.0 : 0.0
    }
    Behavior on launcherShowProgress {
        NumberAnimation { duration: 500; easing.type: Easing.OutExpo }
    }

    visible: true
    color: "transparent"
    property int launcherSlideAmount: 400
    // Fix: Use margins.bottom for window positioning (0 = flush with edge)
    // Animation will be handled by the margins to move the window surface
    // When progress is 0, margin is -implicitHeight (hidden below screen)
    // When progress is 1, margin is 0 (visible on screen)
    // Ensure we add a small buffer (e.g. 50px) to make sure it's fully off-screen if shadows exist
    margins.bottom: -implicitHeight * (1.0 - launcherShowProgress) - (launcherShowProgress < 0.01 ? 50 : 0)
    
    // Applications list
    property var apps: []
    property int selectedIndex: 0
    property string searchText: ""
    
    // Calculator properties
    property string calculatorResult: ""
    property bool isCalculatorMode: false
    property int currentMode: -1  // -1 = mode selection, 0 = Launcher, 1 = Packages, 2 = Fuse
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
        
        if (sharedData && sharedData.runCommand) sharedData.runCommand(['sh', '-c', command])
        
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
        if (sharedData && sharedData.runCommand) {
            sharedData.runCommand(['sh', '-c', '/usr/bin/bluetoothctl show | grep -q "Powered: yes" && echo 1 > /tmp/quickshell_bt_status || echo 0 > /tmp/quickshell_bt_status'])
            if (sharedData.setTimeout) sharedData.setTimeout(appLauncherRoot.readBluetoothStatus, 300)
        }
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
        if (bluetoothEnabled) {
            // Block with rfkill and turn off
            if (sharedData && sharedData.runCommand) sharedData.runCommand(['sh', '-c', 'rfkill block bluetooth; /usr/bin/bluetoothctl power off'])
        } else {
            // Unblock with rfkill, wait, then turn on
            if (sharedData && sharedData.runCommand) sharedData.runCommand(['sh', '-c', 'rfkill unblock bluetooth; sleep 1; /usr/bin/bluetoothctl power on'])
        }
        if (sharedData && sharedData.setTimeout) sharedData.setTimeout(appLauncherRoot.checkBluetoothStatus, 1500)
    }
    
    function scanBluetoothDevices() {
        if (!bluetoothEnabled || bluetoothScanning) return
        bluetoothScanning = true
        bluetoothDevicesModel.clear()
        
        // Use bluetoothctl with timeout - this will scan for 10 seconds and then automatically stop
        if (sharedData && sharedData.runCommand) {
            sharedData.runCommand(['sh', '-c', 'bluetoothctl --timeout 10 scan on > /tmp/quickshell_bt_scan_output 2>&1'])
            if (sharedData.setTimeout) sharedData.setTimeout(appLauncherRoot.getBluetoothDevices, 12000)
        }
    }
    
    function getBluetoothDevices() {
        if (sharedData && sharedData.runCommand) {
            sharedData.runCommand(['sh', '-c', 'bluetoothctl devices > /tmp/quickshell_bt_devices'])
            if (sharedData.setTimeout) sharedData.setTimeout(appLauncherRoot.readBluetoothDevices, 500)
        }
    }
    
    function readBluetoothDevices() {
        var xhr = new XMLHttpRequest()
        xhr.open("GET", "file:///tmp/quickshell_bt_devices")
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                bluetoothDevicesModel.clear()
                var content = xhr.responseText || ""
                var lines = content.trim().split("\n")
                for (var i = 0; i < lines.length; i++) {
                    var line = lines[i].trim()
                    if (line.length > 0) {
                        if (line.startsWith("Device")) {
                            // Format: "Device MAC_ADDRESS Device_Name"
                            var parts = line.split(" ")
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
                bluetoothScanning = false
            }
        }
        xhr.send()
    }
    
    function connectBluetoothDevice(mac) {
        if (bluetoothConnecting) {
            return
        }
        bluetoothConnecting = true
        var macStr = String(mac).trim()
        
        // First pair, then connect
        // Step 1: Pair the device
        if (sharedData && sharedData.runCommand) {
            sharedData.runCommand(['/usr/bin/bluetoothctl', 'pair', macStr])
            if (sharedData.setTimeout) sharedData.setTimeout(function() {
                appLauncherRoot.connectAfterPair(macStr)
            }, 1000)
        }
    }
    
    function connectAfterPair(mac) {
        if (sharedData && sharedData.runCommand) sharedData.runCommand(['/usr/bin/bluetoothctl', 'connect', mac])
    }
    
    function disconnectBluetoothDevice(mac) {
        if (sharedData && sharedData.runCommand) {
            sharedData.runCommand(['sh', '-c', 'bluetoothctl disconnect "' + mac.replace(/"/g, '\\"') + '"'])
            if (sharedData.setTimeout) sharedData.setTimeout(appLauncherRoot.getBluetoothDevices, 1000)
        }
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
                if (sharedData && sharedData.runCommand) sharedData.runCommand(['sh', '-c', "firefox \"" + searchUrl + "\" &"])
                
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
            
            if (sharedData && sharedData.runCommand) sharedData.runCommand(['sh', '-c', exec.replace(/'/g, "'\"'\"'") + ' &'])
            
            if (sharedData) {
                sharedData.launcherVisible = false
            }
        }
    }
    
    // Function to load applications
    property int _loadAppsRetries: 0
    function loadApps() {
        if (!(sharedData && sharedData.runCommand)) {
            // runCommand może nie być gotowe przy starcie – spróbuj ponownie po chwili albo gdy użytkownik otworzy launcher
            if (_loadAppsRetries < 5) {
                _loadAppsRetries++
                if (sharedData && sharedData.setTimeout) sharedData.setTimeout(appLauncherRoot.loadApps, 400)
            }
            return
        }
        _loadAppsRetries = 0
        apps = []
        filteredApps.clear()
        loadedAppsCount = 0
        totalFilesToLoad = 0
        sharedData.runCommand(['sh', '-c', 'find /usr/share/applications ~/.local/share/applications -name "*.desktop" 2>/dev/null | head -200 > /tmp/quickshell_apps_list'], readAppsList)
    }
    
    function readAppsList() {
        var xhr = new XMLHttpRequest()
        xhr.open("GET", "file:///tmp/quickshell_apps_list?_=" + Date.now())
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
        if (sharedData && sharedData.setTimeout) sharedData.setTimeout(appLauncherRoot.filterApps, 500)
        }
    }
    
    // Function to search packages in pacman
    function searchPacmanPackages(query) {
        if (!query || query.length < 2) {
            filteredPackages.clear()
            return
        }
        
        searchPacman(query)
    }
    
    function searchPacman(query) {
        if (!query) return
        if (sharedData && sharedData.runCommand) {
            sharedData.runCommand(['sh', '-c', 'pacman -Ss "' + query.replace(/"/g, '\\"') + '" 2>/dev/null | head -50 > /tmp/quickshell_pacman_search'])
            if (sharedData.setTimeout) sharedData.setTimeout(appLauncherRoot.readPacmanSearchResults, 500)
        }
    }
    
    // Function to read pacman search results
    function readPacmanSearchResults() {
        var xhr = new XMLHttpRequest()
        xhr.open("GET", "file:///tmp/quickshell_pacman_search")
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                filteredPackages.clear()
                var output = xhr.responseText.trim()
                
                if (!output || output.length === 0) {
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
        
        searchAur(query)
    }
    
    // Check if yay or paru is available
    // Run search
    function searchAur(query) {
        if (!query) return
        if (sharedData && sharedData.runCommand) {
            sharedData.runCommand(['sh', '-c', 'if command -v yay >/dev/null 2>&1; then yay -Ss "' + query.replace(/"/g, '\\"') + '" 2>/dev/null | head -50 > /tmp/quickshell_aur_search; elif command -v paru >/dev/null 2>&1; then paru -Ss "' + query.replace(/"/g, '\\"') + '" 2>/dev/null | head -50 > /tmp/quickshell_aur_search; else echo "AUR helper not found" > /tmp/quickshell_aur_search; fi'])
            if (sharedData.setTimeout) sharedData.setTimeout(appLauncherRoot.readAurSearchResults, 800)
        }
    }
    
    // Function to read AUR search results
    function readAurSearchResults() {
        var xhr = new XMLHttpRequest()
        xhr.open("GET", "file:///tmp/quickshell_aur_search")
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                filteredPackages.clear()
                var output = xhr.responseText.trim()
                
                if (!output || output.length === 0 || output.indexOf("AUR helper not found") >= 0) {
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
        if (packageName) {
            // Escape package name
            var safeName = packageName.replace(/"/g, '\\"').replace(/'/g, "\\'").replace(/ /g, "\\ ")
            
            // Use bash script for installation
            var scriptPath = projectPath + "/scripts/install-package.sh"
            // Open kitty, set as floating, size 1200x700 and center
            var command = "hyprctl dispatch exec \"kitty --class=floating_kitty -e bash " + scriptPath + " " + safeName + "\"; sleep 0.3; hyprctl dispatch focuswindow \"class:floating_kitty\"; hyprctl dispatch togglefloating; hyprctl dispatch resizeactive exact 1200 700; hyprctl dispatch centerwindow"
            
            
        if (sharedData && sharedData.runCommand) sharedData.runCommand(['sh', '-c', command])
            
            if (sharedData) {
                sharedData.launcherVisible = false
            }
        } else {
        }
    }
    
    // Function to install AUR package
    function installAurPackage(packageName) {
        if (packageName) {
            // Escape package name
            var safeName = packageName.replace(/"/g, '\\"').replace(/'/g, "\\'").replace(/ /g, "\\ ")
            
            // Use bash script for AUR installation
            var scriptPath = projectPath + "/scripts/install-aur-package.sh"
            // Open kitty, set as floating, size 1200x700 and center
            var command = "hyprctl dispatch exec \"kitty --class=floating_kitty -e bash " + scriptPath + " " + safeName + "\"; sleep 0.3; hyprctl dispatch focuswindow \"class:floating_kitty\"; hyprctl dispatch togglefloating; hyprctl dispatch resizeactive exact 1200 700; hyprctl dispatch centerwindow"
            
            
        if (sharedData && sharedData.runCommand) sharedData.runCommand(['sh', '-c', command])
            
            if (sharedData) {
                sharedData.launcherVisible = false
            }
        } else {
        }
    }
    
    // Function to load installed packages
    function loadInstalledPackages() {
        installedPackages = []
        filteredInstalledPackages.clear()
        
        
        // Run pacman -Q and save to file
        if (sharedData && sharedData.runCommand) {
            sharedData.runCommand(['sh', '-c', 'pacman -Q 2>/dev/null > /tmp/quickshell_installed_packages'])
            if (sharedData.setTimeout) sharedData.setTimeout(appLauncherRoot.readInstalledPackages, 300)
        }
    }
    
    // Function to read installed packages
    function readInstalledPackages() {
        var xhr = new XMLHttpRequest()
        xhr.open("GET", "file:///tmp/quickshell_installed_packages")
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                installedPackages = []
                var output = xhr.responseText.trim()
                
                if (!output || output.length === 0) {
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
        if (packageName) {
            // Escape package name
            var safeName = packageName.replace(/"/g, '\\"').replace(/'/g, "\\'").replace(/ /g, "\\ ")
            
            // Use bash script for removal
            var scriptPath = projectPath + "/scripts/remove-package.sh"
            // Open kitty, set as floating, size 1200x700 and center
            var command = "hyprctl dispatch exec \"kitty --class=floating_kitty -e bash " + scriptPath + " " + safeName + "\"; sleep 0.3; hyprctl dispatch focuswindow \"class:floating_kitty\"; hyprctl dispatch togglefloating; hyprctl dispatch resizeactive exact 1200 700; hyprctl dispatch centerwindow"
            
            
        if (sharedData && sharedData.runCommand) sharedData.runCommand(['sh', '-c', command])
            
            if (sharedData) {
                sharedData.launcherVisible = false
            }
        } else {
        }
    }
    
    // Funkcja usuwania pakietu z AUR
    function removeAurPackage(packageName) {
        if (packageName) {
            // Escapuj nazwę pakietu
            var safeName = packageName.replace(/"/g, '\\"').replace(/'/g, "\\'").replace(/ /g, "\\ ")
            
            // Użyj skryptu bash do usuwania AUR
            var scriptPath = projectPath + "/scripts/remove-aur-package.sh"
            // Otwórz kitty, ustaw jako floating, rozmiar 1200x700 i wyśrodkuj
            var command = "hyprctl dispatch exec \"kitty --class=floating_kitty -e bash " + scriptPath + " " + safeName + "\"; sleep 0.3; hyprctl dispatch focuswindow \"class:floating_kitty\"; hyprctl dispatch togglefloating; hyprctl dispatch resizeactive exact 1200 700; hyprctl dispatch centerwindow"
            
            
        if (sharedData && sharedData.runCommand) sharedData.runCommand(['sh', '-c', command])
            
            if (sharedData) {
                sharedData.launcherVisible = false
            }
        } else {
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

    // Wyczyść pamięć po zamknięciu launchera
    Timer {
        id: memoryFreeTimer
        interval: 500
        onTriggered: {
            if (sharedData && !sharedData.launcherVisible) {
                apps = []
                pacmanPackages = []
                aurPackages = []
                installedPackages = []
                installedAurPackages = []
                if (typeof gc === 'function') gc()
            }
        }
    }

    Connections {
        target: sharedData
        enabled: !!sharedData
        function onLauncherVisibleChanged() {
            if (sharedData && sharedData.launcherVisible) {
                memoryFreeTimer.stop()
                if (apps.length === 0) loadApps()
                currentMode = -1
                currentPackageMode = -1
                installSourceMode = -1
                removeSourceMode = -1
                searchInput.text = ""
                searchText = ""
                packageSearchText = ""
                selectedIndex = 0
                launcherOpenFocusTimer.restart()
            } else {
                memoryFreeTimer.restart()
                searchInput.focus = false
                pacmanSearchInput.focus = false
                aurSearchInput.focus = false
                removeSearchInput.focus = false
                removeAurSearchInput.focus = false
                launcherContainer.focus = false
            }
        }
    }
    
    // Kontener z zawartością – opacity/scale/enabled z jednego launcherShowProgress
    Item {
        id: launcherContainer
        anchors.fill: parent
        // Apply opacity here instead of root PanelWindow
        opacity: launcherShowProgress
        enabled: launcherShowProgress > 0.02
        focus: launcherShowProgress > 0.02
        // scale: 1.0 // Removed scale animation
        transformOrigin: Item.Bottom
        
        // Window movement handles the slide animation


        // Tło z gradientem
        // Material Design launcher background with elevation
        Rectangle {
            id: launcherBackground
            anchors.fill: parent
            radius: (sharedData && sharedData.quickshellBorderRadius) ? sharedData.quickshellBorderRadius : 0
            
            // Użyj sharedData.colorBackground jeśli dostępny - jednolite tło bez gradientu
            color: (sharedData && sharedData.colorBackground) ? sharedData.colorBackground : colorBackground
            
            // Material Design elevation shadow
            Rectangle {
                anchors.fill: parent
                anchors.margins: -3
                color: "transparent"
                border.color: Qt.rgba(0, 0, 0, 0.25)  // Material shadow
                border.width: 2
                z: -1
            }
        }
        
        // Obsługa klawiszy na kontenerze - przekieruj do TextInput tylko w trybie Launch App
        Keys.forwardTo: (currentMode === 0) ? [searchInput] : []
        
        Keys.onPressed: function(event) {
            // Escape - zamknij launcher lub wróć do wyboru trybu
            if (event.key === Qt.Key_Escape) {
                if (currentMode === -1 || currentMode === 0) {
                    // Wybór trybu lub Launch App – jeden Escape zamyka launcher
                    if (sharedData) {
                        sharedData.launcherVisible = false
                    }
                    event.accepted = true
                    return
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
                }
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                // Enter - wybierz tryb, pakiet lub aplikację
                if (currentMode === -1) {
                    // Wybierz tryb
                    if (selectedIndex >= 0 && selectedIndex < modesList.count) {
                        var mode = modesList.model.get(selectedIndex)
                        if (mode.mode === 2) {
                            // Launch fuse directly using Process
                            if (sharedData && sharedData.runCommand) sharedData.runCommand(['sh', '-c', 'fuse &'])
                            if (sharedData) {
                                sharedData.launcherVisible = false
                            }
                            event.accepted = true
                            return
                        }
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
                        if (sharedData && sharedData.setTimeout) sharedData.setTimeout(function() {
                            if (appLauncherRoot.pacmanSearchInput) appLauncherRoot.pacmanSearchInput.forceActiveFocus()
                        }, 200)
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
                } else if (currentMode === 0) {
                    // W trybie Launch App - przekieruj do TextInput
                    searchInput.forceActiveFocus()
                    event.accepted = false
                }
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
            }
        }
        
        // Lista trybów (gdy currentMode === -1) - NOWY DESIGN
        ListView {
            reuseItems: true
            id: modesList
            anchors.fill: parent
            anchors.margins: 20
            visible: currentMode === -1
            focus: currentMode === -1 // Ensure focus for keyboard navigation
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
            }
            
            delegate: Rectangle {
                id: modeItem
                width: modesList.width
                height: 50
                radius: (sharedData && sharedData.quickshellBorderRadius) ? sharedData.quickshellBorderRadius : 0
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
                            easing.type: Easing.OutCubic
                        }
                    }
                }
                
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
                        if (model.mode === 2) {
                            // Launch fuse directly using Process
                            if (sharedData && sharedData.runCommand) sharedData.runCommand(['sh', '-c', 'fuse &'])
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
                        }
                    }
                }
            }
        }
        
        // Zawartość trybów – te same marginesy co strona główna (20)
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
                    spacing: 9
                            
                            // Pole wyszukiwania
                            Rectangle {
                                id: searchBox
                                width: parent.width
                                height: 36
                                color: searchInput.activeFocus ? colorPrimary : colorSecondary
                                radius: (sharedData && sharedData.quickshellBorderRadius) ? sharedData.quickshellBorderRadius : 0
                                
                                opacity: (sharedData && sharedData.launcherVisible && currentMode === 0) ? 1 : 0
                                scale: (sharedData && sharedData.launcherVisible && currentMode === 0) ? 1 : 0.9
                                transform: Translate {
                                    y: (sharedData && sharedData.launcherVisible && currentMode === 0) ? 0 : 20
                                }

                                Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
                                Behavior on scale { NumberAnimation { duration: 500; easing.type: Easing.OutBack } }
                                Behavior on transform { PropertyAnimation { property: "y"; duration: 600; easing.type: Easing.OutBack } }

                                Behavior on color {
                                    ColorAnimation { 
                                        duration: 180
                                        easing.type: Easing.OutQuart
                                    }
                                }
                                
                                TextInput {
                                    id: searchInput
                                    anchors.fill: parent
                                    anchors.margins: 14
                                    font.pixelSize: 16
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
                                                if (sharedData && sharedData.runCommand) sharedData.runCommand(['sh', '-c', 'echo -n "' + calculatorResult.replace(/"/g, '\\"') + '" | xclip -selection clipboard'])
                                                if (sharedData) {
                                                    sharedData.launcherVisible = false
                                                }
                                                event.accepted = true
                                                return
                                            }
                                            
                                            // Check if search text is "fuse" - launch fuse application
                                            if (searchText && searchText.trim().toLowerCase() === "fuse") {
                                                if (sharedData && sharedData.runCommand) sharedData.runCommand(['sh', '-c', 'fuse 2>/dev/null || $HOME/.local/bin/fuse 2>/dev/null || ' + projectPath + '/../fuse/target/release/fuse 2>/dev/null'])
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
                                                    if (sharedData && sharedData.runCommand) sharedData.runCommand(['sh', '-c', 'echo -n "' + calculatorResult.replace(/"/g, '\\"') + '" | xclip -selection clipboard'])
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
                                    font.pixelSize: 16
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
                                reuseItems: true
                                id: appsList
                                width: parent.width
                                height: parent.height - searchBox.height - parent.spacing
                                clip: true
                                spacing: 8
                                
                                model: filteredApps
                                currentIndex: selectedIndex
                                
                                onCurrentIndexChanged: {
                                    if (currentIndex !== selectedIndex) {
                                        selectedIndex = currentIndex
                                    }
                                }
                                
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
                                }
                                
                                delegate: Rectangle {
                                    id: appItem
                                    width: appsList.width
                                    height: 50
                                    radius: (sharedData && sharedData.quickshellBorderRadius) ? sharedData.quickshellBorderRadius : 0
                                    
                                    opacity: (sharedData && sharedData.launcherVisible && currentMode === 0) ? 1 : 0
                                    scale: (sharedData && sharedData.launcherVisible && currentMode === 0) ? 1 : 0.8
                                    
                                    transform: Translate {
                                        y: (sharedData && sharedData.launcherVisible && currentMode === 0) ? 0 : 40
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
                                            if (sharedData && sharedData.runCommand) sharedData.runCommand(['sh', '-c', 'echo -n "' + calculatorResult.replace(/"/g, '\\"') + '" | xclip -selection clipboard'])
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
            
            // Tryb 1: Packages – ten sam wygląd co strona główna (height 50, radius 4, lewy pasek)
            
            ListView {
                reuseItems: true
                id: packagesOptionsList
                anchors.fill: parent
                anchors.margins: 20
                spacing: 8
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
                
                delegate: Rectangle {
                    id: packageOptionItem
                    width: packagesOptionsList.width
                    height: 50
                    radius: (sharedData && sharedData.quickshellBorderRadius) ? sharedData.quickshellBorderRadius : 0
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
                        }
                    }
                    
                    Row {
                        anchors.left: parent.left
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
            
            // Wybór źródła instalacji (Pacman/AUR) – ten sam wygląd co strona główna
            ListView {
                reuseItems: true
                id: installSourceList
                anchors.fill: parent
                anchors.margins: 20
                spacing: 8
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
                    height: 50
                    radius: (sharedData && sharedData.quickshellBorderRadius) ? sharedData.quickshellBorderRadius : 0
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
                        }
                    }
                    
                    Row {
                        anchors.left: parent.left
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
                                if (sharedData && sharedData.setTimeout) sharedData.setTimeout(function() {
                                    appLauncherRoot.pacmanSearchInput.forceActiveFocus()
                                }, 100)
                            } else if (model.source === "aur") {
                                // Przełącz na tryb wyszukiwania AUR
                                currentPackageMode = 2
                                installSourceMode = 1
                                selectedIndex = 0
                                packageSearchText = ""
                                // Ustaw focus na pole wyszukiwania
                                if (sharedData && sharedData.setTimeout) sharedData.setTimeout(function() {
                                    appLauncherRoot.aurSearchInput.forceActiveFocus()
                                }, 100)
                            }
                        }
                    }
                }
                
                highlight: Rectangle {
                    color: colorPrimary
                    radius: (sharedData && sharedData.quickshellBorderRadius) ? sharedData.quickshellBorderRadius : 0
                    
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
                    spacing: 8
                    
                    // Pole wyszukiwania
                    Rectangle {
                        id: pacmanSearchBox
                        width: parent.width
                        height: 30
                        color: pacmanSearchInput.activeFocus ? colorPrimary : colorSecondary
                        radius: (sharedData && sharedData.quickshellBorderRadius) ? sharedData.quickshellBorderRadius : 0
                        
                        opacity: (sharedData && sharedData.launcherVisible && currentMode === 1 && currentPackageMode === 1) ? 1 : 0
                        scale: (sharedData && sharedData.launcherVisible && currentMode === 1 && currentPackageMode === 1) ? 1 : 0.9
                        transform: Translate {
                            y: (sharedData && sharedData.launcherVisible && currentMode === 1 && currentPackageMode === 1) ? 0 : 20
                        }

                        Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
                        Behavior on scale { NumberAnimation { duration: 500; easing.type: Easing.OutBack } }
                        Behavior on transform { PropertyAnimation { property: "y"; duration: 600; easing.type: Easing.OutBack } }

                        Behavior on color {
                            ColorAnimation { duration: 180; easing.type: Easing.OutQuart }
                        }
                        
                        TextInput {
                            id: pacmanSearchInput
                            anchors.fill: parent
                            anchors.margins: 14
                            font.pixelSize: 18
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
                                        if (pkg && pkg.name) {
                                            installPacmanPackage(pkg.name)
                                        } else {
                                        }
                                    } else {
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
                            font.pixelSize: 18
                            font.family: "sans-serif"
                            color: (sharedData && sharedData.colorText) ? Qt.lighter(sharedData.colorText, 1.5) : "#666666"
                            verticalAlignment: Text.AlignVCenter
                            visible: pacmanSearchInput.text.length === 0
                            z: 5
                        }
                    }
                    
                    // Lista pakietów – ten sam wygląd co strona główna
                    ListView {
                        reuseItems: true
                        id: pacmanPackagesList
                        width: parent.width
                        height: parent.height - pacmanSearchBox.height - parent.spacing
                        clip: true
                        spacing: 8
                        
                        model: filteredPackages
                        
                        delegate: Rectangle {
                            id: packageItem
                            width: pacmanPackagesList.width
                            height: 50
                            radius: (sharedData && sharedData.quickshellBorderRadius) ? sharedData.quickshellBorderRadius : 0
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
                            }
                            
                            property string packageName: model.name || "Unknown"
                            property string packageDescription: model.description || ""
                            
                            Column {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.leftMargin: 16
                                anchors.rightMargin: 16
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 2
                                width: parent.width - 32
                                Text {
                                    text: packageItem.packageName
                                    font.pixelSize: 15
                                    font.family: "sans-serif"
                                    font.weight: selectedIndex === index ? Font.Bold : Font.Normal
                                    color: (sharedData && sharedData.colorText) ? sharedData.colorText : colorText
                                    width: parent.width
                                    elide: Text.ElideRight
                                }
                                Text {
                                    text: packageItem.packageDescription
                                    font.pixelSize: 12
                                    font.family: "sans-serif"
                                    color: (sharedData && sharedData.colorText) ? sharedData.colorText : colorText
                                    opacity: 0.7
                                    width: parent.width
                                    elide: Text.ElideRight
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
                            radius: (sharedData && sharedData.quickshellBorderRadius) ? sharedData.quickshellBorderRadius : 0
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
                    spacing: 8
                    
                    // Pole wyszukiwania
                    Rectangle {
                        id: aurSearchBox
                        width: parent.width
                        height: 30
                        color: aurSearchInput.activeFocus ? colorPrimary : colorSecondary
                        radius: (sharedData && sharedData.quickshellBorderRadius) ? sharedData.quickshellBorderRadius : 0
                        
                        opacity: (sharedData && sharedData.launcherVisible && currentMode === 1 && currentPackageMode === 2) ? 1 : 0
                        scale: (sharedData && sharedData.launcherVisible && currentMode === 1 && currentPackageMode === 2) ? 1 : 0.9
                        transform: Translate {
                            y: (sharedData && sharedData.launcherVisible && currentMode === 1 && currentPackageMode === 2) ? 0 : 20
                        }

                        Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
                        Behavior on scale { NumberAnimation { duration: 500; easing.type: Easing.OutBack } }
                        Behavior on transform { PropertyAnimation { property: "y"; duration: 600; easing.type: Easing.OutBack } }

                        Behavior on color {
                            ColorAnimation { duration: 180; easing.type: Easing.OutQuart }
                        }
                        
                        TextInput {
                            id: aurSearchInput
                            anchors.fill: parent
                            anchors.margins: 14
                            font.pixelSize: 18
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
                                        if (pkg && pkg.name) {
                                            installAurPackage(pkg.name)
                                        } else {
                                        }
                                    } else {
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
                            font.pixelSize: 18
                            font.family: "sans-serif"
                            color: (sharedData && sharedData.colorText) ? Qt.lighter(sharedData.colorText, 1.5) : "#666666"
                            verticalAlignment: Text.AlignVCenter
                            visible: aurSearchInput.text.length === 0
                            z: 5
                        }
                    }
                    
                    // Lista pakietów AUR – ten sam wygląd co strona główna
                    ListView {
                        reuseItems: true
                        id: aurPackagesList
                        width: parent.width
                        height: parent.height - aurSearchBox.height - parent.spacing
                        clip: true
                        spacing: 8
                        
                        model: filteredPackages
                        
                        delegate: Rectangle {
                            id: aurPackageItem
                            width: aurPackagesList.width
                            height: 50
                            radius: (sharedData && sharedData.quickshellBorderRadius) ? sharedData.quickshellBorderRadius : 0
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
                            }
                            
                            property string packageName: model.name || "Unknown"
                            property string packageDescription: model.description || ""
                            
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
                            radius: (sharedData && sharedData.quickshellBorderRadius) ? sharedData.quickshellBorderRadius : 0
                        }
                    }
                }
            }
            
            // Wybór źródła usuwania (Pacman/AUR) – ten sam wygląd co strona główna
            ListView {
                reuseItems: true
                id: removeSourceList
                anchors.fill: parent
                anchors.margins: 20
                spacing: 8
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
                    height: 50
                    radius: (sharedData && sharedData.quickshellBorderRadius) ? sharedData.quickshellBorderRadius : 0
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
                    }
                    
                    Row {
                        anchors.left: parent.left
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
                                if (sharedData && sharedData.setTimeout) sharedData.setTimeout(function() {
                                    appLauncherRoot.removeSearchInput.forceActiveFocus()
                                }, 100)
                            } else if (model.source === "aur") {
                                // Przełącz na tryb usuwania AUR
                                currentPackageMode = 5
                                removeSourceMode = 1
                                selectedIndex = 0
                                packageSearchText = ""
                                loadInstalledPackages()
                                // Ustaw focus na pole wyszukiwania
                                if (sharedData && sharedData.setTimeout) sharedData.setTimeout(function() {
                                    appLauncherRoot.removeAurSearchInput.forceActiveFocus()
                                }, 100)
                            }
                        }
                    }
                }
                
                highlight: Rectangle {
                    color: (sharedData && sharedData.colorPrimary) ? sharedData.colorPrimary : colorPrimary
                    radius: (sharedData && sharedData.quickshellBorderRadius) ? sharedData.quickshellBorderRadius : 0
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
                    spacing: 8
                    
                    // Pole wyszukiwania
                    Rectangle {
                        id: removeSearchBox
                        width: parent.width
                        height: 30
                        color: removeSearchInput.activeFocus ? colorPrimary : colorSecondary
                        radius: (sharedData && sharedData.quickshellBorderRadius) ? sharedData.quickshellBorderRadius : 0
                        
                        opacity: (sharedData && sharedData.launcherVisible && currentMode === 1 && currentPackageMode === 4) ? 1 : 0
                        scale: (sharedData && sharedData.launcherVisible && currentMode === 1 && currentPackageMode === 4) ? 1 : 0.9
                        transform: Translate {
                            y: (sharedData && sharedData.launcherVisible && currentMode === 1 && currentPackageMode === 4) ? 0 : 20
                        }

                        Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
                        Behavior on scale { NumberAnimation { duration: 500; easing.type: Easing.OutBack } }
                        Behavior on transform { PropertyAnimation { property: "y"; duration: 600; easing.type: Easing.OutBack } }

                        Behavior on color {
                            ColorAnimation { duration: 180; easing.type: Easing.OutQuart }
                        }
                        
                        TextInput {
                            id: removeSearchInput
                            anchors.fill: parent
                            anchors.margins: 14
                            font.pixelSize: 18
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
                                        if (pkg && pkg.name) {
                                            if (currentPackageMode === 4) {
                                            removePacmanPackage(pkg.name)
                                            } else if (currentPackageMode === 5) {
                                                removeAurPackage(pkg.name)
                                            }
                                        } else {
                                        }
                                    } else {
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
                            font.pixelSize: 18
                            font.family: "sans-serif"
                            color: (sharedData && sharedData.colorText) ? Qt.lighter(sharedData.colorText, 1.5) : "#666666"
                            verticalAlignment: Text.AlignVCenter
                            visible: removeSearchInput.text.length === 0
                            z: 5
                        }
                    }
                    
                    // Lista zainstalowanych pakietów – ten sam wygląd co strona główna
                    ListView {
                        reuseItems: true
                        id: removePackagesList
                        width: parent.width
                        height: parent.height - removeSearchBox.height - parent.spacing
                        clip: true
                        spacing: 8
                        
                        model: filteredInstalledPackages
                        
                        delegate: Rectangle {
                            id: installedPackageItem
                            width: removePackagesList.width
                            height: 50
                            radius: (sharedData && sharedData.quickshellBorderRadius) ? sharedData.quickshellBorderRadius : 0
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
                            }
                            
                            property string packageName: model.name || "Unknown"
                            property string packageVersion: model.version || ""
                            
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
                            radius: (sharedData && sharedData.quickshellBorderRadius) ? sharedData.quickshellBorderRadius : 0
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
                    spacing: 8
                    
                    // Pole wyszukiwania
                    Rectangle {
                        id: removeAurSearchBox
                        width: parent.width
                        height: 30
                        color: removeAurSearchInput.activeFocus ? colorPrimary : colorSecondary
                        radius: (sharedData && sharedData.quickshellBorderRadius) ? sharedData.quickshellBorderRadius : 0
                        
                        opacity: (sharedData && sharedData.launcherVisible && currentMode === 1 && currentPackageMode === 5) ? 1 : 0
                        scale: (sharedData && sharedData.launcherVisible && currentMode === 1 && currentPackageMode === 5) ? 1 : 0.9
                        transform: Translate {
                            y: (sharedData && sharedData.launcherVisible && currentMode === 1 && currentPackageMode === 5) ? 0 : 20
                        }

                        Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
                        Behavior on scale { NumberAnimation { duration: 500; easing.type: Easing.OutBack } }
                        Behavior on transform { PropertyAnimation { property: "y"; duration: 600; easing.type: Easing.OutBack } }

                        Behavior on color {
                            ColorAnimation { duration: 180; easing.type: Easing.OutQuart }
                        }
                        
                        TextInput {
                            id: removeAurSearchInput
                            anchors.fill: parent
                            anchors.margins: 14
                            font.pixelSize: 18
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
                                        if (pkg && pkg.name) {
                                            removeAurPackage(pkg.name)
                                        } else {
                                        }
                                    } else {
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
                            font.pixelSize: 18
                            font.family: "sans-serif"
                            color: (sharedData && sharedData.colorText) ? Qt.lighter(sharedData.colorText, 1.5) : "#666666"
                            verticalAlignment: Text.AlignVCenter
                            visible: removeAurSearchInput.text.length === 0
                            z: 5
                        }
                    }
                    
                    // Lista zainstalowanych pakietów AUR – ten sam wygląd co strona główna
                    ListView {
                        reuseItems: true
                        id: removeAurPackagesList
                        width: parent.width
                        height: parent.height - removeAurSearchBox.height - parent.spacing
                        clip: true
                        spacing: 8
                        
                        model: filteredInstalledPackages
                        
                        delegate: Rectangle {
                            id: installedAurPackageItem
                            width: removeAurPackagesList.width
                            height: 50
                            radius: (sharedData && sharedData.quickshellBorderRadius) ? sharedData.quickshellBorderRadius : 0
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
                            }
                            
                            property string packageName: model.name || "Unknown"
                            property string packageVersion: model.version || ""
                            
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
                            radius: (sharedData && sharedData.quickshellBorderRadius) ? sharedData.quickshellBorderRadius : 0
                        }
                    }
                }
            }
        }
    }
}

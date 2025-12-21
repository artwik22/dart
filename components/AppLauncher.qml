import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

PanelWindow {
    id: appLauncherRoot
    
    property var sharedData: null
    property var screen: null
    
    // Dynamic project path - from environment variable or default
    property string projectPath: "/home/artwik/sharpshell" // Default, will be set by Component.onCompleted
    
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
                    console.log("Using default project path:", projectPath)
                }
            }
        }
        xhr.send()
    }
    
    Component.onCompleted: {
        loadProjectPath()
        loadApps()
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
    
    implicitWidth: isWallpaperMode ? wallpaperWidth : baseWidth
    implicitHeight: isWallpaperMode ? wallpaperHeight : baseHeight
    width: implicitWidth
    height: implicitHeight
    
    Behavior on implicitWidth {
        NumberAnimation {
            duration: 300
            easing.type: Easing.OutCubic
        }
    }
    
    Behavior on implicitHeight {
        NumberAnimation {
            duration: 300
            easing.type: Easing.OutCubic
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
            duration: 400
            easing.type: Easing.OutQuart
        }
    }
    
    // Applications list
    property var apps: []
    property int selectedIndex: 0
    property string searchText: ""
    property int currentMode: -1  // -1 = mode selection, 0 = Launch App, 1 = Packages, 2 = Settings
    property int currentPackageMode: -1  // -1 = Packages option selection, 0 = install source selection (Pacman/AUR), 1 = Pacman search, 2 = AUR search, 3 = remove source selection (Pacman/AUR), 4 = Pacman remove search, 5 = AUR remove search
    property int installSourceMode: -1  // -1 = selection, 0 = Pacman, 1 = AUR
    property int removeSourceMode: -1  // -1 = selection, 0 = Pacman, 1 = AUR
    property int currentSettingsMode: -1  // -1 = settings list, 0 = Wallpaper, 1 = Update
    property int wallpaperSelectedIndex: 0  // Indeks wybranej tapety w GridView
    property var packages: []
    property string packageSearchText: ""
    property var wallpapers: []
    property string wallpapersPath: "/home/artwik/Pictures/Wallpapers"
    
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
    
    function setWallpaper(wallpaperPath) {
        console.log("Setting wallpaper:", wallpaperPath)
        Qt.createQmlObject('import Quickshell.Io; import QtQuick; Process { command: ["swww", "img", "' + wallpaperPath + '", "--transition-type", "fade", "--transition-duration", "1"]; running: true }', appLauncherRoot)
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
    
    // Function to filter applications
    function filterApps() {
        filteredApps.clear()
        var search = (searchText || "").toLowerCase().trim()
        
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
            if (search === "" || name.indexOf(search) >= 0 || comment.indexOf(search) >= 0) {
                filteredApps.append({
                    name: app.name,
                    comment: app.comment || "",
                    exec: app.exec || "",
                    icon: app.icon || ""
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
                duration: 300
                easing.type: Easing.OutCubic
            }
        }
        
        Behavior on scale {
            NumberAnimation {
                duration: 300
                easing.type: Easing.OutCubic
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
            color: "#0f0f0f"
            
            // Gradient tła
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#0f0f0f" }
                GradientStop { position: 1.0; color: "#0a0a0a" }
            }
            
            // Border z subtelnym efektem
            border.color: "#1a1a1a"
            border.width: 1
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
                } else if (currentMode === 2 && currentSettingsMode !== -1) {
                    // W ustawieniach - wróć do listy ustawień
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
                        settingsOptionsList.positionViewAtIndex(selectedIndex, ListView.Center)
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
                    if (selectedIndex < settingsOptionsList.count - 1) {
                        selectedIndex++
                        settingsOptionsList.positionViewAtIndex(selectedIndex, ListView.Center)
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
                        if (currentMode === 1) {
                            currentPackageMode = -1
                            installSourceMode = -1
                            removeSourceMode = -1
                        }
                    }
                    event.accepted = true
                } else if (currentMode === 1 && currentPackageMode === -1) {
                    // W trybie Packages - wybierz opcję (Install/Remove)
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
                        }
                    }
                    event.accepted = true
                } else if (currentMode === 1 && currentPackageMode === 0) {
                    // W trybie Pacman search - przekieruj do TextInput
                    pacmanSearchInput.forceActiveFocus()
                    event.accepted = false
                } else if (currentMode === 1 && currentPackageMode === 1) {
                    // W trybie AUR search - przekieruj do TextInput
                    aurSearchInput.forceActiveFocus()
                    event.accepted = false
                } else if (currentMode === 1 && currentPackageMode === 2) {
                    // W trybie Remove search - przekieruj do TextInput
                    removeSearchInput.forceActiveFocus()
                    event.accepted = false
                } else if (currentMode === 2 && currentSettingsMode === -1) {
                    // W trybie Settings - wybierz opcję
                    if (selectedIndex >= 0 && selectedIndex < settingsOptionsList.count) {
                        var settingOption = settingsOptionsList.model.get(selectedIndex)
                        currentSettingsMode = settingOption.settingId
                        if (settingOption.settingId === 0) {
                            loadWallpapers()
                            wallpaperSelectedIndex = 0  // Reset indeksu przy otwieraniu
                            wallpapersGrid.currentIndex = 0
                        } else if (settingOption.settingId === 1) {
                            updateSystem()
                        }
                    }
                    event.accepted = true
                } else if (currentMode === 2 && currentSettingsMode === 0) {
                    // W trybie Wallpaper - wybierz tapetę
                    if (wallpaperSelectedIndex >= 0 && wallpaperSelectedIndex < wallpapersModel.count) {
                        var wallpaper = wallpapersModel.get(wallpaperSelectedIndex)
                        if (wallpaper && wallpaper.path) {
                            setWallpaper(wallpaper.path)
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
                pacmanSearchInput.forceActiveFocus()
                event.accepted = false
            } else if (currentMode === 1 && currentPackageMode === 2) {
                // W trybie AUR search - przekieruj do TextInput
                aurSearchInput.forceActiveFocus()
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
                removeSearchInput.forceActiveFocus()
                event.accepted = false
                } else if (currentMode === 1 && currentPackageMode === 5) {
                    // W trybie AUR remove search - przekieruj do TextInput
                    removeAurSearchInput.forceActiveFocus()
                    event.accepted = false
            }
        }
        
        // Lista trybów (gdy currentMode === -1)
        ListView {
            id: modesList
            anchors.fill: parent
            anchors.margins: 18
            visible: currentMode === -1
            opacity: currentMode === -1 ? 1.0 : 0.0
            
            Behavior on opacity {
                NumberAnimation {
                    duration: 250
                    easing.type: Easing.OutCubic
                }
            }
            
            add: Transition {
                SequentialAnimation {
                    PauseAnimation { duration: index * 50 }
                    ParallelAnimation {
                        NumberAnimation {
                            properties: "opacity"
                            from: 0
                            to: 1
                            duration: 300
                            easing.type: Easing.OutCubic
                        }
                        NumberAnimation {
                            property: "y"
                            from: 10
                            to: 0
                            duration: 300
                            easing.type: Easing.OutCubic
                        }
                    }
                }
            }
            
            model: ListModel {
                ListElement { name: "Launch App"; description: "Launch applications"; mode: 0; icon: "󰈙" }
                ListElement { name: "Packages"; description: "Manage packages"; mode: 1; icon: "󰏖" }
                ListElement { name: "Settings"; description: "Configure launcher"; mode: 2; icon: "󰒓" }
            }
            
            delegate: Rectangle {
                id: modeItem
                width: modesList.width
                height: 60
                color: selectedIndex === index ? "#1a1a1a" : (modeItemMouseArea.containsMouse ? "#151515" : "transparent")
                radius: 0
                scale: (selectedIndex === index || modeItemMouseArea.containsMouse) ? 1.02 : 1.0
                
                Behavior on color {
                    ColorAnimation { 
                        duration: 200
                        easing.type: Easing.OutCubic
                    }
                }
                
                Behavior on scale {
                    NumberAnimation {
                        duration: 150
                        easing.type: Easing.OutCubic
                    }
                }
                
                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: 15
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 11
                    
                    Text {
                        text: model.icon || ""
                        font.pixelSize: 18
                        color: selectedIndex === index ? "#ffffff" : "#888888"
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 4
                        
                        Text {
                            text: model.name
                            font.pixelSize: 14
                            font.family: "JetBrains Mono"
                            font.weight: Font.Medium
                            color: selectedIndex === index ? "#ffffff" : "#cccccc"
                        }
                        
                        Text {
                            text: model.description
                            font.pixelSize: 11
                            font.family: "JetBrains Mono"
                            color: "#666666"
                        }
                    }
                }
                
                MouseArea {
                    id: modeItemMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    
                    onEntered: {
                        selectedIndex = index
                    }
                    
                    onClicked: {
                        currentMode = model.mode
                        selectedIndex = 0
                        if (model.mode === 1) {
                            currentPackageMode = -1
                        }
                    }
                }
            }
            
            highlight: Rectangle {
                color: "#1a1a1a"
                radius: 0
                
                Behavior on color {
                    ColorAnimation { 
                        duration: 200
                        easing.type: Easing.OutCubic
                    }
                }
                
                Behavior on y {
                    NumberAnimation {
                        duration: 200
                        easing.type: Easing.OutCubic
                    }
                }
            }
        }
        
        // Zawartość trybów
        Item {
            id: modeContent
            anchors.fill: parent
            anchors.margins: 18
            visible: currentMode !== -1
        
            // Tryb 0: Launch App
            Item {
                id: launchAppMode
                anchors.fill: parent
                visible: currentMode === 0
                
                Column {
                    id: launchAppColumn
                    anchors.fill: parent
                    spacing: 11
                            
                            // Pole wyszukiwania
                            Rectangle {
                                id: searchBox
                                width: parent.width
                                height: 45
                                color: searchInput.activeFocus ? "#1a1a1a" : "#141414"
                                border.color: searchInput.activeFocus ? "#2a2a2a" : "#1a1a1a"
                                border.width: searchInput.activeFocus ? 2 : 1
                                radius: 0
                                
                                Behavior on color {
                                    ColorAnimation { 
                                        duration: 250
                                        easing.type: Easing.OutCubic
                                    }
                                }
                                
                                Behavior on border.color {
                                    ColorAnimation { 
                                        duration: 250
                                        easing.type: Easing.OutCubic
                                    }
                                }
                                
                                Behavior on border.width {
                                    NumberAnimation {
                                        duration: 200
                                        easing.type: Easing.OutCubic
                                    }
                                }
                                
                                TextInput {
                                    id: searchInput
                                    anchors.fill: parent
                                    anchors.margins: 15
                                    font.pixelSize: 15
                                    font.family: "JetBrains Mono"
                                    font.weight: Font.Medium
                                    font.letterSpacing: 0.2
                                    color: "#f5f5f5"
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
                                            if (filteredApps.count > 0 && selectedIndex >= 0 && selectedIndex < filteredApps.count) {
                                                var app = filteredApps.get(selectedIndex)
                                                if (app && app.exec) {
                                                    launchApp(app)
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
                                    color: "#808080"
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
                                spacing: 0
                                
                                model: filteredApps
                                
                                add: Transition {
                                    SequentialAnimation {
                                        PauseAnimation { duration: index * 30 }
                                        NumberAnimation {
                                            properties: "opacity"
                                            from: 0
                                            to: 1
                                            duration: 250
                                            easing.type: Easing.OutCubic
                                        }
                                    }
                                }
                                
                                remove: Transition {
                                    NumberAnimation {
                                        properties: "opacity"
                                        to: 0
                                        duration: 200
                                        easing.type: Easing.InCubic
                                    }
                                }
                                
                                addDisplaced: Transition {
                                    NumberAnimation {
                                        properties: "y"
                                        duration: 250
                                        easing.type: Easing.OutCubic
                                    }
                                }
                                
                                removeDisplaced: Transition {
                                    NumberAnimation {
                                        properties: "y"
                                        duration: 200
                                        easing.type: Easing.OutCubic
                                    }
                                }
                                
                                delegate: Rectangle {
                                id: appItem
                                width: appsList.width
                                height: 54
                                color: selectedIndex === index ? "#1e1e1e" : (appItemMouseArea.containsMouse ? "#181818" : "transparent")
                                radius: 0
                                scale: (selectedIndex === index || appItemMouseArea.containsMouse) ? 1.01 : 1.0
                                
                                Behavior on color {
                                    ColorAnimation { 
                                        duration: 200
                                        easing.type: Easing.OutCubic
                                    }
                                }
                                
                                Behavior on scale {
                                    NumberAnimation {
                                        duration: 150
                                        easing.type: Easing.OutCubic
                                    }
                                }
                                
                                // Pobierz dane z modelu
                                property string appName: model.name || "Unknown"
                                property string appComment: model.comment || ""
                                property string appExec: model.exec || ""
                                property string appIcon: model.icon || ""
                                
                                Column {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 15
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 5
                                    
                                    Text {
                                        text: appItem.appName
                                        font.pixelSize: 15
                                        font.family: "JetBrains Mono"
                                        font.weight: Font.Medium
                                        font.letterSpacing: 0.1
                                        color: selectedIndex === index ? "#f5f5f5" : "#d0d0d0"
                                    }

                                    Text {
                                        text: appItem.appComment
                                        font.pixelSize: 12
                                        font.family: "JetBrains Mono"
                                        font.weight: Font.Normal
                                        font.letterSpacing: 0.1
                                        color: "#909090"
                                        visible: appItem.appComment && appItem.appComment.length > 0
                                    }
                                }
                                
                                MouseArea {
                                    id: appItemMouseArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    
                                    onEntered: {
                                        selectedIndex = index
                                    }
                                    
                                    onClicked: {
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
                            
                            highlight: Rectangle {
                                color: "#1a1a1a"
                                radius: 0
                                
                                Behavior on color {
                                    ColorAnimation { duration: 150 }
                                }
                            }
                        }
                    }
                }
            }
            
            // Tryb 1: Packages - prosta lista
            Rectangle {
                id: packagesModeBg
                anchors.fill: parent
                visible: currentMode === 1
                color: "#0f0f0f"
                z: -1
            }
            
            ListView {
                id: packagesOptionsList
                anchors.fill: parent
                anchors.margins: 18
                visible: currentMode === 1 && currentPackageMode === -1
                clip: true
                z: 1
                model: ListModel {
                    id: packagesModel
                    ListElement { name: "Install"; description: "Install packages"; action: "install"; icon: "󰐕" }
                    ListElement { name: "Remove"; description: "Remove packages"; action: "remove"; icon: "󰆐" }
                }
                
                Component.onCompleted: {
                    console.log("Packages list created, model count:", packagesModel.count)
                }
                
                delegate: Rectangle {
                    id: packageOptionItem
                    width: packagesOptionsList.width
                    height: 60
                    color: selectedIndex === index ? "#1a1a1a" : (packageOptionItemMouseArea.containsMouse ? "#151515" : "transparent")
                    radius: 0
                    scale: (selectedIndex === index || packageOptionItemMouseArea.containsMouse) ? 1.02 : 1.0
                    
                    Behavior on color {
                        ColorAnimation { 
                            duration: 200
                            easing.type: Easing.OutCubic
                        }
                    }
                    
                    Behavior on scale {
                        NumberAnimation {
                            duration: 150
                            easing.type: Easing.OutCubic
                        }
                    }
                    
                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: 15
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 11
                        
                        Text {
                            text: model.icon || ""
                            font.pixelSize: 18
                            color: selectedIndex === index ? "#ffffff" : "#888888"
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        
                        Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 4
                        
                        Text {
                            text: model.name || "Unknown"
                                font.pixelSize: 14
                            font.family: "JetBrains Mono"
                            font.weight: Font.Medium
                            color: selectedIndex === index ? "#ffffff" : "#cccccc"
                        }
                        
                        Text {
                            text: model.description || ""
                                font.pixelSize: 11
                            font.family: "JetBrains Mono"
                            color: "#666666"
                            }
                        }
                    }
                    
                    MouseArea {
                        id: packageOptionItemMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        
                        onEntered: {
                            selectedIndex = index
                        }
                        
                        onClicked: {
                            if (model.action === "install") {
                                // Przełącz na wybór źródła instalacji (Pacman/AUR)
                                currentPackageMode = 0
                                installSourceMode = -1
                                selectedIndex = 0
                            } else if (model.action === "remove") {
                                // Przełącz na wybór źródła usuwania (Pacman/AUR)
                                currentPackageMode = 3
                                removeSourceMode = -1
                                selectedIndex = 0
                            }
                        }
                    }
                }
                
                highlight: Rectangle {
                    color: "#1a1a1a"
                    radius: 0
                    
                    Behavior on color {
                        ColorAnimation { duration: 150 }
                    }
                }
            }
            
            // Wybór źródła instalacji (Pacman/AUR) - gdy currentPackageMode === 0
            ListView {
                id: installSourceList
                anchors.fill: parent
                anchors.margins: 18
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
                    height: 60
                    color: selectedIndex === index ? "#1a1a1a" : (installSourceItemMouseArea.containsMouse ? "#151515" : "transparent")
                    radius: 0
                    scale: (selectedIndex === index || installSourceItemMouseArea.containsMouse) ? 1.02 : 1.0
                    
                    Behavior on color {
                        ColorAnimation { 
                            duration: 200
                            easing.type: Easing.OutCubic
                        }
                    }
                    
                    Behavior on scale {
                        NumberAnimation {
                            duration: 150
                            easing.type: Easing.OutCubic
                        }
                    }
                    
                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: 15
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 11
                        
                        Text {
                            text: model.icon || ""
                            font.pixelSize: 18
                            color: selectedIndex === index ? "#ffffff" : "#888888"
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 4
                            
                            Text {
                                text: model.name || "Unknown"
                                font.pixelSize: 14
                                font.family: "JetBrains Mono"
                                font.weight: Font.Medium
                                color: selectedIndex === index ? "#ffffff" : "#cccccc"
                            }
                            
                            Text {
                                text: model.description || ""
                                font.pixelSize: 11
                                font.family: "JetBrains Mono"
                                color: "#666666"
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
                    color: "#1a1a1a"
                    radius: 0
                    
                    Behavior on color {
                        ColorAnimation { duration: 150 }
                    }
                }
            }
            
            // Wyszukiwarka pakietów Pacman (gdy currentPackageMode === 1)
            Item {
                id: pacmanSearchMode
                anchors.fill: parent
                anchors.margins: 18
                visible: currentMode === 1 && currentPackageMode === 1
                
                Column {
                    id: pacmanSearchColumn
                    anchors.fill: parent
                    spacing: 11
                    
                    // Pole wyszukiwania
                    Rectangle {
                        id: pacmanSearchBox
                        width: parent.width
                        height: 50
                        color: pacmanSearchInput.activeFocus ? "#1a1a1a" : "#141414"
                        border.color: pacmanSearchInput.activeFocus ? "#2a2a2a" : "#1a1a1a"
                        border.width: 1
                        radius: 0
                        
                        Behavior on color {
                            ColorAnimation { duration: 200 }
                        }
                        
                        Behavior on border.color {
                            ColorAnimation { duration: 200 }
                        }
                        
                        TextInput {
                            id: pacmanSearchInput
                            anchors.fill: parent
                            anchors.margins: 15
                            font.pixelSize: 14
                            font.family: "JetBrains Mono"
                            color: "#ffffff"
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
                            color: "#666666"
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
                            height: 54
                            color: selectedIndex === index ? "#1a1a1a" : (packageItemMouseArea.containsMouse ? "#151515" : "transparent")
                            radius: 0
                            scale: (selectedIndex === index || packageItemMouseArea.containsMouse) ? 1.01 : 1.0
                            
                            Behavior on color {
                                ColorAnimation { 
                                    duration: 200
                                    easing.type: Easing.OutCubic
                                }
                            }
                            
                            Behavior on scale {
                                NumberAnimation {
                                    duration: 150
                                    easing.type: Easing.OutCubic
                                }
                            }
                            
                            property string packageName: model.name || "Unknown"
                            property string packageDescription: model.description || ""
                            
                            Column {
                                anchors.left: parent.left
                                anchors.leftMargin: 15
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 4
                                
                                Text {
                                    text: packageItem.packageName
                                    font.pixelSize: 14
                                    font.family: "JetBrains Mono"
                                    font.weight: Font.Medium
                                    color: selectedIndex === index ? "#ffffff" : "#cccccc"
                                }
                                
                                Text {
                                    text: packageItem.packageDescription
                                    font.pixelSize: 11
                                    font.family: "JetBrains Mono"
                                    color: "#666666"
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
                            color: "#2a2a2a"
                            radius: 0
                        }
                    }
                }
            }
            
            // Wyszukiwarka pakietów AUR (gdy currentPackageMode === 2)
            Item {
                id: aurSearchMode
                anchors.fill: parent
                anchors.margins: 18
                visible: currentMode === 1 && currentPackageMode === 2
                
                Column {
                    id: aurSearchColumn
                    anchors.fill: parent
                    spacing: 11
                    
                    // Pole wyszukiwania
                    Rectangle {
                        id: aurSearchBox
                        width: parent.width
                        height: 50
                        color: aurSearchInput.activeFocus ? "#1a1a1a" : "#141414"
                        border.color: aurSearchInput.activeFocus ? "#2a2a2a" : "#1a1a1a"
                        border.width: 1
                        radius: 0
                        
                        Behavior on color {
                            ColorAnimation { duration: 200 }
                        }
                        
                        Behavior on border.color {
                            ColorAnimation { duration: 200 }
                        }
                        
                        TextInput {
                            id: aurSearchInput
                            anchors.fill: parent
                            anchors.margins: 15
                            font.pixelSize: 14
                            font.family: "JetBrains Mono"
                            color: "#ffffff"
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
                            color: "#666666"
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
                            height: 54
                            color: selectedIndex === index ? "#1a1a1a" : (aurPackageItemMouseArea.containsMouse ? "#151515" : "transparent")
                            radius: 0
                            scale: (selectedIndex === index || aurPackageItemMouseArea.containsMouse) ? 1.01 : 1.0
                            
                            Behavior on color {
                                ColorAnimation { 
                                    duration: 200
                                    easing.type: Easing.OutCubic
                                }
                            }
                            
                            Behavior on scale {
                                NumberAnimation {
                                    duration: 150
                                    easing.type: Easing.OutCubic
                                }
                            }
                            
                            property string packageName: model.name || "Unknown"
                            property string packageDescription: model.description || ""
                            
                            Column {
                                anchors.left: parent.left
                                anchors.leftMargin: 15
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 4
                                
                                Text {
                                    text: aurPackageItem.packageName
                                    font.pixelSize: 14
                                    font.family: "JetBrains Mono"
                                    font.weight: Font.Medium
                                    color: selectedIndex === index ? "#ffffff" : "#cccccc"
                                }
                                
                                Text {
                                    text: aurPackageItem.packageDescription
                                    font.pixelSize: 11
                                    font.family: "JetBrains Mono"
                                    color: "#666666"
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
                            color: "#2a2a2a"
                            radius: 0
                        }
                    }
                }
            }
            
            // Wybór źródła usuwania (Pacman/AUR) - gdy currentPackageMode === 3
            ListView {
                id: removeSourceList
                anchors.fill: parent
                anchors.margins: 18
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
                    height: 60
                    color: selectedIndex === index ? "#1a1a1a" : (removeSourceItemMouseArea.containsMouse ? "#151515" : "transparent")
                    radius: 0
                    scale: (selectedIndex === index || removeSourceItemMouseArea.containsMouse) ? 1.02 : 1.0
                    
                    Behavior on color {
                        ColorAnimation { 
                            duration: 200
                            easing.type: Easing.OutCubic
                        }
                    }
                    
                    Behavior on scale {
                        NumberAnimation {
                            duration: 150
                            easing.type: Easing.OutCubic
                        }
                    }
                    
                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: 15
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 11
                        
                        Text {
                            text: model.icon || ""
                            font.pixelSize: 18
                            color: selectedIndex === index ? "#ffffff" : "#888888"
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 4
                            
                            Text {
                                text: model.name || "Unknown"
                                font.pixelSize: 14
                                font.family: "JetBrains Mono"
                                font.weight: Font.Medium
                                color: selectedIndex === index ? "#ffffff" : "#cccccc"
                            }
                            
                            Text {
                                text: model.description || ""
                                font.pixelSize: 11
                                font.family: "JetBrains Mono"
                                color: "#666666"
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
                    color: "#1a1a1a"
                    radius: 0
                    
                    Behavior on color {
                        ColorAnimation { duration: 150 }
                    }
                }
            }
            
            // Wyszukiwarka zainstalowanych pakietów do usunięcia z Pacman (gdy currentPackageMode === 4)
            Item {
                id: removeSearchMode
                anchors.fill: parent
                anchors.margins: 18
                visible: currentMode === 1 && currentPackageMode === 4
                
                Column {
                    id: removeSearchColumn
                    anchors.fill: parent
                    spacing: 11
                    
                    // Pole wyszukiwania
                    Rectangle {
                        id: removeSearchBox
                        width: parent.width
                        height: 50
                        color: removeSearchInput.activeFocus ? "#1a1a1a" : "#141414"
                        border.color: removeSearchInput.activeFocus ? "#2a2a2a" : "#1a1a1a"
                        border.width: 1
                        radius: 0
                        
                        Behavior on color {
                            ColorAnimation { duration: 200 }
                        }
                        
                        Behavior on border.color {
                            ColorAnimation { duration: 200 }
                        }
                        
                        TextInput {
                            id: removeSearchInput
                            anchors.fill: parent
                            anchors.margins: 15
                            font.pixelSize: 14
                            font.family: "JetBrains Mono"
                            color: "#ffffff"
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
                            color: "#666666"
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
                            height: 54
                            color: selectedIndex === index ? "#1a1a1a" : (installedPackageItemMouseArea.containsMouse ? "#151515" : "transparent")
                            radius: 0
                            scale: (selectedIndex === index || installedPackageItemMouseArea.containsMouse) ? 1.01 : 1.0
                            
                            Behavior on color {
                                ColorAnimation { 
                                    duration: 200
                                    easing.type: Easing.OutCubic
                                }
                            }
                            
                            Behavior on scale {
                                NumberAnimation {
                                    duration: 150
                                    easing.type: Easing.OutCubic
                                }
                            }
                            
                            property string packageName: model.name || "Unknown"
                            property string packageVersion: model.version || ""
                            
                            Column {
                                anchors.left: parent.left
                                anchors.leftMargin: 15
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 4
                                
                                Text {
                                    text: installedPackageItem.packageName
                                    font.pixelSize: 14
                                    font.family: "JetBrains Mono"
                                    font.weight: Font.Medium
                                    color: selectedIndex === index ? "#ffffff" : "#cccccc"
                                }
                                
                                Text {
                                    text: installedPackageItem.packageVersion
                                    font.pixelSize: 11
                                    font.family: "JetBrains Mono"
                                    color: "#666666"
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
                            color: "#2a2a2a"
                            radius: 0
                        }
                    }
                }
            }
            
            // Wyszukiwarka zainstalowanych pakietów do usunięcia z AUR (gdy currentPackageMode === 5)
            Item {
                id: removeAurSearchMode
                anchors.fill: parent
                anchors.margins: 18
                visible: currentMode === 1 && currentPackageMode === 5
                
                Column {
                    id: removeAurSearchColumn
                    anchors.fill: parent
                    spacing: 11
                    
                    // Pole wyszukiwania
                    Rectangle {
                        id: removeAurSearchBox
                        width: parent.width
                        height: 50
                        color: removeAurSearchInput.activeFocus ? "#1a1a1a" : "#141414"
                        border.color: removeAurSearchInput.activeFocus ? "#2a2a2a" : "#1a1a1a"
                        border.width: 1
                        radius: 0
                        
                        Behavior on color {
                            ColorAnimation { duration: 200 }
                        }
                        
                        Behavior on border.color {
                            ColorAnimation { duration: 200 }
                        }
                        
                        TextInput {
                            id: removeAurSearchInput
                            anchors.fill: parent
                            anchors.margins: 15
                            font.pixelSize: 14
                            font.family: "JetBrains Mono"
                            color: "#ffffff"
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
                            color: "#666666"
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
                            height: 54
                            color: selectedIndex === index ? "#1a1a1a" : (installedAurPackageItemMouseArea.containsMouse ? "#151515" : "transparent")
                            radius: 0
                            scale: (selectedIndex === index || installedAurPackageItemMouseArea.containsMouse) ? 1.01 : 1.0
                            
                            Behavior on color {
                                ColorAnimation { 
                                    duration: 200
                                    easing.type: Easing.OutCubic
                                }
                            }
                            
                            Behavior on scale {
                                NumberAnimation {
                                    duration: 150
                                    easing.type: Easing.OutCubic
                                }
                            }
                            
                            property string packageName: model.name || "Unknown"
                            property string packageVersion: model.version || ""
                            
                            Column {
                                anchors.left: parent.left
                                anchors.leftMargin: 15
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 4
                                
                                Text {
                                    text: installedAurPackageItem.packageName
                                    font.pixelSize: 14
                                    font.family: "JetBrains Mono"
                                    font.weight: Font.Medium
                                    color: selectedIndex === index ? "#ffffff" : "#cccccc"
                                }
                                
                                Text {
                                    text: installedAurPackageItem.packageVersion
                                    font.pixelSize: 11
                                    font.family: "JetBrains Mono"
                                    color: "#666666"
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
                            color: "#2a2a2a"
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
                
                // Lista opcji ustawień
                ListView {
                    id: settingsOptionsList
                    anchors.fill: parent
                    anchors.margins: 18
                    visible: currentSettingsMode === -1
                    clip: true
                    
                    model: ListModel {
                        id: settingsOptionsModel
                        ListElement { name: "Wallpaper"; description: "Change wallpaper with swww"; icon: "󰸉"; settingId: 0 }
                        ListElement { name: "Update"; description: "Update system packages (pacman -Syyu)"; icon: "󰏕"; settingId: 1 }
                    }
                    
                    delegate: Rectangle {
                        width: settingsOptionsList.width
                        height: 60
                        color: (selectedIndex === index) ? "#1a1a1a" : (settingsOptionsMouseArea.containsMouse ? "#151515" : "transparent")
                        scale: settingsOptionsMouseArea.containsMouse ? 1.02 : 1.0
                        
                        Behavior on scale {
                            NumberAnimation {
                                duration: 150
                                easing.type: Easing.OutCubic
                            }
                        }
                        
                        Row {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 12
                            
                            Text {
                                text: model.icon
                                font.pixelSize: 24
                                color: (selectedIndex === index) ? "#ffffff" : "#888888"
                                anchors.verticalCenter: parent.verticalCenter
                                width: 30
                                horizontalAlignment: Text.AlignHCenter
                            }
                            
                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 2
                                
                                Text {
                                    text: model.name
                                    font.pixelSize: 14
                                    font.family: "JetBrains Mono"
                                    font.weight: Font.Medium
                                    color: (selectedIndex === index) ? "#ffffff" : "#cccccc"
                                }
                                
                                Text {
                                    text: model.description
                                    font.pixelSize: 11
                                    font.family: "JetBrains Mono"
                                    color: "#666666"
                                }
                            }
                        }
                        
                        MouseArea {
                            id: settingsOptionsMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            
                            onEntered: {
                                selectedIndex = index
                            }
                            
                            onClicked: {
                                currentSettingsMode = model.settingId
                                if (model.settingId === 0) {
                                    loadWallpapers()
                                } else if (model.settingId === 1) {
                                    updateSystem()
                                }
                            }
                        }
                    }
                    
                            highlight: Rectangle {
                                color: "#1a1a1a"
                                radius: 0
                                
                                Behavior on color {
                                    ColorAnimation { 
                                        duration: 200
                                        easing.type: Easing.OutCubic
                                    }
                                }
                                
                                Behavior on y {
                                    NumberAnimation {
                                        duration: 200
                                        easing.type: Easing.OutCubic
                                    }
                                }
                            }
                }
                
                // Wallpaper picker
                Item {
                    id: wallpaperPicker
                    anchors.fill: parent
                    visible: currentSettingsMode === 0
                    
                    // Header
                    Rectangle {
                        id: wallpaperHeader
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: 50
                        color: "transparent"
                        
                        Row {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 12
                            
                            // Back button
                            Rectangle {
                                width: 30
                                height: 30
                                color: wallpaperBackMouseArea.containsMouse ? "#1a1a1a" : "transparent"
                                radius: 4
                                anchors.verticalCenter: parent.verticalCenter
                                
                                Text {
                                    text: "󰁍"
                                    font.pixelSize: 18
                                    color: "#ffffff"
                                    anchors.centerIn: parent
                                }
                                
                                MouseArea {
                                    id: wallpaperBackMouseArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: currentSettingsMode = -1
                                }
                            }
                            
                            Text {
                                text: "Wallpaper"
                                font.pixelSize: 18
                                font.family: "JetBrains Mono"
                                font.weight: Font.Bold
                                color: "#ffffff"
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            
                            Text {
                                text: "(" + wallpapersModel.count + " images)"
                                font.pixelSize: 12
                                font.family: "JetBrains Mono"
                                color: "#666666"
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                    }
                    
                    // Grid z tapetami
                    GridView {
                        id: wallpapersGrid
                        anchors.top: wallpaperHeader.bottom
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.leftMargin: 18
                        anchors.rightMargin: 18
                        anchors.topMargin: 6
                        anchors.bottomMargin: 12
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
                                color: (wallpaperItemMouseArea.containsMouse || wallpapersGrid.currentIndex === index) ? "#1a1a1a" : "#0a0a0a"
                                scale: (wallpaperItemMouseArea.containsMouse || wallpapersGrid.currentIndex === index) ? 1.05 : 1.0
                                
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
                                        color: "#1a1a1a"
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
                            color: "#666666"
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
            }
        }
    }

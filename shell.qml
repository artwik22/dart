import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import "components"

ShellRoot {
    id: root

    ProcessHelper { id: processHelper }
    // Osobna kolejka tylko do czyszczenia /tmp/quickshell_command – bez czekania na cava/wallpaper/itd.
    ProcessHelper { id: processHelperClear }
    MangoWM {
        id: mangoWMProvider
        sharedData: root.sharedData
    }

    // Współdzielone właściwości (jeśli potrzebne)
    property var sharedData: QtObject {
        property var runCommand: processHelper ? processHelper.runCommand : function(){}
        property bool menuVisible: false
        property bool launcherVisible: false
        property bool volumeVisible: false
        property bool volumeEdgeHovered: false  // Czy myszka jest nad detektorem krawędzi
        property bool clipboardVisible: false
        property bool settingsVisible: false
        property bool captureMenuVisible: false
        property bool notchVisible: true
        property bool lockScreenVisible: false  // Własny lock screen (zamiast swaylock/loginctl)
        property bool lockScreenNonBlocking: false // Jeśli true, ruszysz myszką i znika
        
        property var setTimeout: function(cb, delayTime) {
            var timer = Qt.createQmlObject("import QtQuick 2.0; Timer {}", root);
            timer.interval = delayTime;
            timer.repeat = false;
            timer.triggered.connect(function() {
                cb();
                timer.destroy();
            });
            timer.start();
        }
        property bool sidebarVisible: true  // Sidebar visibility toggle
        property bool sidebarHiddenByFullscreen: false  // Gdy okno jest fullscreen – sidebar się chowa (Hyprland event "fullscreen")
        property string sidebarPosition: "left"  // Sidebar position: "left" or "top"
        property bool notificationsEnabled: true  // Enable/disable notifications
        property bool notificationSoundsEnabled: true  // Enable/disable notification sounds
        property string sidepanelContent: "calendar"   // "calendar" | "github"
        property string githubUsername: ""             // GitHub username for activity view
        
        // Notification history for notification center
        property var notificationHistory: []

        // System Status Properties (Centralized)
        property string netStatus: "Checking..."
        property string netSSID: ""
        property string netIP: ""
        property string btStatus: "Checking..."
        property int btDevices: 0
        property string pwrStatus: "Checking..."
        property int batteryPct: 0
        property string batteryStatus: "Unknown"
        property int netSignal: 0
        property string netNearby: ""
        property string btDeviceNames: ""
        property string btPaired: ""
        
        // Persistent loading states
        property bool dashboardLoaded: false
        property bool launcherLoaded: false
        property bool clipboardLoaded: false
        property bool overviewVisible: false
        property bool overviewLoaded: false

        // Color theme properties
        property string colorBackground: "#0a0a0a"
        property string colorPrimary: "#1a1a1a"
        property string colorSecondary: "#141414"
        property string colorText: "#ffffff"
        property string colorAccent: "#4a9eff"
        property real uiScale: 1.0
        property bool lowPerformanceMode: false  // true gdy ~/.config/alloy/low-perf istnieje – mniejsze zacinki na słabszym PC
        property string dashboardTileLeft: "battery"  // "battery" | "network" – co pokazywać na lewym kafelku dashboardu
        property string dashboardPosition: "right"  // "right", "left", "top", "bottom"
        property string dashboardResource1: "cpu" // "cpu", "ram", "gpu", "network"
        property string dashboardResource2: "ram" // "cpu", "ram", "gpu", "network"
        property string notificationPosition: "top" // "top", "top-left", "top-right"
        property string notificationRounding: "standard" // "none", "standard", "pill"
        property int quickshellBorderRadius: 0 // Border radius for QuickShell elements (0 = disabled)
        property string notificationSound: "message.oga" // "message.oga", "dialog-information.oga", etc.
        property string weatherLocation: "London"      // Weather location for wttr.in
        property bool floatingDashboard: true          // Dashboard style: true (floating) | false (classic)
        // Lockscreen Widget Toggles
        property bool lockscreenMediaEnabled: true
        property bool lockscreenWeatherEnabled: true
        property bool lockscreenBatteryEnabled: true
        property bool lockscreenCalendarEnabled: true
        property bool lockscreenNetworkEnabled: false
        property bool screensaverWidgetsEnabled: true
        property bool sidebarBatteryEnabled: true
        property string sidebarStyle: "dots" // "dots" | "lines"
        property bool clockBlinkColon: true
        property string sidebarWorkspaceMode: "top" // "top" | "center" | "bottom"
        property bool dynamicSidebarBackground: false
        property bool micaSidebarBackground: false
        property var workspaceProvider: Hyprland // Default to Hyprland
        property string activeScreenshotPath: ""
        property string activeThumbnailPath: ""
    }
    
    // Color config file path - dynamically determined
    property string colorConfigPath: ""
    property string projectPath: ""

    // Polecenia z pliku: debounce i pojedyncza obsługa w czasie (unikamy „sam się otwiera i zamyka”)
    property bool commandHandlerBusy: false
    property string lastCommandHandled: ""
    property int lastCommandTime: 0

    // Hyprland fullscreen: gdy okno wchodzi w fullscreen, chowaj sidebar; przy wyjściu – przywróć
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event && event.name === "fullscreen") {
                var data = (event.data || "").toString().trim()
                sharedData.sidebarHiddenByFullscreen = (data === "1")
            }
        }
    }
    
    // MangoWM fullscreen: podobnie jak Hyprland, ale przez polling w MangoWM.qml
    Connections {
        target: mangoWMProvider
        function onFullscreenChanged() {
            if (sharedData.workspaceProvider === mangoWMProvider) {
                sharedData.sidebarHiddenByFullscreen = mangoWMProvider.fullscreen
            }
        }
    }
    
    // Single startup: one Process writes HOME and QUICKSHELL_PROJECT_PATH, then one read + loadColors + readLowPerf
    function initializeColorPath() {
        processHelper.runCommand(['sh', '-c', 'echo "$HOME|$QUICKSHELL_PROJECT_PATH" > /tmp/quickshell_init 2>/dev/null || true'], initPathsFromFile)
    }

    // Same path order as Fuse ColorConfig.get_config_path(): alloy → project → sharpshell → /tmp
    function initPathsFromFile() {
        var xhr = new XMLHttpRequest()
        xhr.open("GET", "file:///tmp/quickshell_init")
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE) return
            var line = (xhr.responseText || "").trim()
            var parts = line.split("|")
            var home = (parts[0] || "").trim()
            var projPath = (parts[1] || "").trim()
            root.projectPath = projPath

            function applyAndFinish(path) {
                root.colorConfigPath = path
                root.loadColors()
                root.readLowPerf()
            }
            function tryProjectThenFallback() {
                if (projPath && projPath.length > 0) {
                    var projectColors = projPath + "/colors.json"
                    var pxhr = new XMLHttpRequest()
                    pxhr.open("GET", "file://" + projectColors)
                    pxhr.onreadystatechange = function() {
                        if (pxhr.readyState === XMLHttpRequest.DONE && (pxhr.status === 200 || pxhr.status === 0))
                            applyAndFinish(projectColors)
                        else
                            applyAndFinish(home ? (home + "/.config/sharpshell/colors.json") : "/tmp/sharpshell/colors.json")
                    }
                    pxhr.send()
                } else {
                    applyAndFinish(home ? (home + "/.config/sharpshell/colors.json") : "/tmp/sharpshell/colors.json")
                }
            }
            function tryAlloy() {
                if (!(home && home.length > 0)) {
                    tryProjectThenFallback()
                    return
                }
                var alloyPath = home + "/.config/alloy/colors.json"
                var checkXhr = new XMLHttpRequest()
                checkXhr.open("GET", "file://" + alloyPath)
                checkXhr.onreadystatechange = function() {
                    if (checkXhr.readyState === XMLHttpRequest.DONE) {
                        if (checkXhr.status === 200 || checkXhr.status === 0)
                            applyAndFinish(alloyPath)
                        else
                            tryProjectThenFallback()
                    }
                }
                checkXhr.send()
            }
            tryAlloy()
        }
        xhr.send()
    }

    function readLowPerf() {
        var xhr = new XMLHttpRequest()
        xhr.open("GET", "file:///tmp/quickshell_low_perf")
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE && (xhr.status === 200 || xhr.status === 0)) {
                var v = (xhr.responseText || "").trim()
                sharedData.lowPerformanceMode = (v === "1" || v === "true")
            }
        }
        xhr.send()
    }

    // Load colors on startup: 1) early load z pliku zapisanego przez run.sh (alley colors), 2) zwykły init
    Component.onCompleted: {
        tryEarlyColorLoad()
        initializeColorPath()
        
        if (sharedData && sharedData.setTimeout) {
            // Detect Window Manager immediately, skip preloading heavy UI components to save RAM
            root.detectWM()
        }
    }

    function detectWM() {
        processHelper.runCommand(['sh', '-c', 'pgrep mango > /dev/null && echo "mango" || echo "hyprland"'], function(out) {
            // pgrep via ProcessHelper might not return output directly to this callback if not captured.
            // Wait, ProcessHelper.runCommand in shell.qml uses a callback with no args usually?
            // Wait, ProcessHelper.qml again.
        })
    }
    
    // Improved WM detection using the runAndRead pattern if needed, but let's try a simpler approach in shell.qml
    Timer {
        id: wmDetectionTimer
        interval: 2000
        running: true
        repeat: false
        onTriggered: {
            var tmp = "/tmp/qs_wm_check"
            processHelper.runCommand(['sh', '-c', 'pgrep mango > /dev/null && echo "mango" > ' + tmp + ' || echo "hyprland" > ' + tmp], function() {
                var xhr = new XMLHttpRequest()
                xhr.open("GET", "file://" + tmp)
                xhr.onreadystatechange = function() {
                    if (xhr.readyState === XMLHttpRequest.DONE) {
                        var wm = (xhr.responseText || "").trim()
                        if (wm === "mango") {
                            sharedData.workspaceProvider = mangoWMProvider
                            sharedData.sidebarHiddenByFullscreen = mangoWMProvider.fullscreen
                        } else {
                            sharedData.workspaceProvider = Hyprland
                        }
                    }
                }
                xhr.send()
            })
        }
    }

    // Szybkie ładowanie kolorów ze ścieżki zapisanej przez run.sh (~/.config/alloy/colors.json) – kolory = preset z Fuse
    function tryEarlyColorLoad() {
        var xhr = new XMLHttpRequest()
        xhr.open("GET", "file:///tmp/quickshell_colors_path?_=" + Date.now())
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE) return
            var path = (xhr.responseText || "").trim()
            if (path && path.length > 1 && (path.indexOf("colors.json") >= 0 || path.indexOf("/") >= 0)) {
                root.colorConfigPath = path
                root.loadColors(false, path)
            }
        }
        xhr.send()
    }

    // Ta sama logika co Fuse ColorConfig.load(): gdy jest colorPreset i presets[name], kolory bierz z presetu; inaczej z głównych pól.
    // Dzięki temu Dart zawsze ma te same kolory co zaznaczony preset w Fuse.
    // Używamy tylko json + stałych domyślnych – bez odwołań do sharedData (kontekst wywołania z XHR mógłby być inny).
    function getResolvedColors(json) {
        if (!json) return null
        var def = { background: "#0a0a0a", primary: "#1a1a1a", secondary: "#141414", text: "#ffffff", accent: "#4a9eff" }
        if (json.colorPreset && json.presets && json.presets[json.colorPreset]) {
            var p = json.presets[json.colorPreset]
            return {
                background: (p.background && String(p.background)) ? String(p.background) : (json.background || def.background),
                primary: (p.primary && String(p.primary)) ? String(p.primary) : (json.primary || def.primary),
                secondary: (p.secondary && String(p.secondary)) ? String(p.secondary) : (json.secondary || def.secondary),
                text: (p.text && String(p.text)) ? String(p.text) : (json.text || def.text),
                accent: (p.accent && String(p.accent)) ? String(p.accent) : (json.accent || def.accent)
            }
        }
        return {
            background: (json.background && String(json.background)) ? String(json.background) : def.background,
            primary: (json.primary && String(json.primary)) ? String(json.primary) : def.primary,
            secondary: (json.secondary && String(json.secondary)) ? String(json.secondary) : def.secondary,
            text: (json.text && String(json.text)) ? String(json.text) : def.text,
            accent: (json.accent && String(json.accent)) ? String(json.accent) : def.accent
        }
    }
    
    // skipSidebarPrefs: when true (np. przy Fuse notify_color_change) nie nadpisujemy sidebarVisible/sidebarPosition.
    // pathOverride: gdy z sygnału Fuse – ścieżka do colors.json zapisana w pliku sygnałowym (Quickshell czyta ten sam plik co Fuse).
    function loadColors(skipSidebarPrefs, pathOverride) {
        var path = (pathOverride && String(pathOverride).length > 0) ? String(pathOverride).trim() : (root.colorConfigPath || "")
        if (!path) {
            return
        }
        var skip = !!skipSidebarPrefs
        var xhr = new XMLHttpRequest()
        xhr.open("GET", "file://" + path + "?_=" + Date.now())
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200 || xhr.status === 0) {
                    try {
                        var json = JSON.parse(xhr.responseText)
                        var c = root.getResolvedColors(json)
                        if (c) {
                            sharedData.colorBackground = c.background
                            sharedData.colorPrimary = c.primary
                            sharedData.colorSecondary = c.secondary
                            sharedData.colorText = c.text
                            sharedData.colorAccent = c.accent
                        }
                        
                        // Load last wallpaper if available
                        if (json.lastWallpaper && json.lastWallpaper.length > 0) {
                            root.currentWallpaperPath = json.lastWallpaper
                        }
                        
                        if (!skip) {
                            // Sidebar prefs tylko przy starcie / init – przy Fuse notify nie nadpisujemy, żeby nie migotało
                            if (json.sidebarPosition && (json.sidebarPosition === "left" || json.sidebarPosition === "top" || json.sidebarPosition === "right" || json.sidebarPosition === "bottom")) {
                                sharedData.sidebarPosition = json.sidebarPosition
                            }
                            if (json.sidebarVisible !== undefined) {
                                var visible = json.sidebarVisible === true || json.sidebarVisible === "true"
                                sharedData.sidebarVisible = visible
                            }
                        }
                        
                        // Load color preset if available (for reference, not applied automatically)
                        if (json.colorPreset && json.colorPreset.length > 0) {
                        }
                        
                        // Load notification settings if available
                        if (json.notificationsEnabled !== undefined) {
                            sharedData.notificationsEnabled = json.notificationsEnabled === true || json.notificationsEnabled === "true"
                        }
                        if (json.notificationSoundsEnabled !== undefined) {
                            sharedData.notificationSoundsEnabled = json.notificationSoundsEnabled === true || json.notificationSoundsEnabled === "true"
                        }
                        if (json.uiScale === 75 || json.uiScale === 100 || json.uiScale === 125) {
                            sharedData.uiScale = json.uiScale / 100.0
                        }
                        if (json.dashboardTileLeft === "battery" || json.dashboardTileLeft === "network") {
                            sharedData.dashboardTileLeft = json.dashboardTileLeft
                        }
                        if (json.dashboardPosition && (json.dashboardPosition === "left" || json.dashboardPosition === "top" || json.dashboardPosition === "right" || json.dashboardPosition === "bottom")) {
                            sharedData.dashboardPosition = json.dashboardPosition
                        }
                        if (json.sidepanelContent === "calendar" || json.sidepanelContent === "github") {
                            sharedData.sidepanelContent = json.sidepanelContent
                        } else {
                            sharedData.sidepanelContent = "calendar"
                        }
                        if (json.dashboardResource1) {
                            sharedData.dashboardResource1 = json.dashboardResource1
                        }
                        if (json.dashboardResource2) {
                            sharedData.dashboardResource2 = json.dashboardResource2
                        }
                        if (json.githubUsername && String(json.githubUsername).length > 0) {
                            sharedData.githubUsername = String(json.githubUsername)
                        }
                        if (json.notificationPosition && (json.notificationPosition === "top" || json.notificationPosition === "top-left" || json.notificationPosition === "top-right")) {
                            sharedData.notificationPosition = json.notificationPosition
                        }
                        if (json.notificationRounding && (json.notificationRounding === "none" || json.notificationRounding === "standard" || json.notificationRounding === "pill")) {
                            sharedData.notificationRounding = json.notificationRounding
                        }
                        // Load quickshell border radius (default 0 = disabled)
                        if (json.quickshellBorderRadius !== undefined) {
                            var rad = parseInt(json.quickshellBorderRadius)
                            sharedData.quickshellBorderRadius = isNaN(rad) ? 0 : rad
                        }
                        if (json.notificationSound && String(json.notificationSound).length > 0) {
                            sharedData.notificationSound = String(json.notificationSound)
                        }
                        if (json.weatherLocation && String(json.weatherLocation).length > 0) {
                            sharedData.weatherLocation = String(json.weatherLocation)
                        }
                        if (json.floatingDashboard !== undefined) {
                            sharedData.floatingDashboard = json.floatingDashboard === true || json.floatingDashboard === "true"
                        }

                        // Load Lockscreen Settings
                        if (json.lockscreenMediaEnabled !== undefined) sharedData.lockscreenMediaEnabled = json.lockscreenMediaEnabled === true || json.lockscreenMediaEnabled === "true"
                        if (json.lockscreenWeatherEnabled !== undefined) sharedData.lockscreenWeatherEnabled = json.lockscreenWeatherEnabled === true || json.lockscreenWeatherEnabled === "true"
                        if (json.lockscreenBatteryEnabled !== undefined) sharedData.lockscreenBatteryEnabled = json.lockscreenBatteryEnabled === true || json.lockscreenBatteryEnabled === "true"
                        if (json.lockscreenCalendarEnabled !== undefined) sharedData.lockscreenCalendarEnabled = json.lockscreenCalendarEnabled === true || json.lockscreenCalendarEnabled === "true"
                        if (json.lockscreenNetworkEnabled !== undefined) sharedData.lockscreenNetworkEnabled = json.lockscreenNetworkEnabled === true || json.lockscreenNetworkEnabled === "true"
                        if (json.screensaverWidgetsEnabled !== undefined) sharedData.screensaverWidgetsEnabled = json.screensaverWidgetsEnabled === true || json.screensaverWidgetsEnabled === "true"
                        if (json.sidebarBatteryEnabled !== undefined) sharedData.sidebarBatteryEnabled = json.sidebarBatteryEnabled === true || json.sidebarBatteryEnabled === "true"

                        if (json.sidebarStyle && (json.sidebarStyle === "dots" || json.sidebarStyle === "lines")) {
                            sharedData.sidebarStyle = json.sidebarStyle
                        }
                        
                        if (json.clockBlinkColon !== undefined) sharedData.clockBlinkColon = json.clockBlinkColon === true || json.clockBlinkColon === "true"
                        
                        if (json.sidebarWorkspaceMode) sharedData.sidebarWorkspaceMode = json.sidebarWorkspaceMode
                        
                        if (json.dynamicSidebarBackground !== undefined) {
                            sharedData.dynamicSidebarBackground = json.dynamicSidebarBackground === true || json.dynamicSidebarBackground === "true"
                        }
                        if (json.micaSidebarBackground !== undefined) {
                            sharedData.micaSidebarBackground = json.micaSidebarBackground === true || json.micaSidebarBackground === "true"
                        }

                    } catch (e) {
                    }
                }
            }
        }
        xhr.send()
    }

    function handleRemoteCommand(cmd) {
        if (!cmd) return
        console.log("shell.qml: Received remote command: " + cmd)
        if (cmd === "openLauncher") {
            root.openLauncher()
        } else if (cmd === "toggleMenu") {
            root.toggleMenu()
        } else if (cmd === "openClipboardManager") {
            root.openClipboardManager()
        } else if (cmd === "toggleCapture") {
            root.toggleCapture()
        } else if (cmd === "openSettings") {
            root.openSettings()
        } else if (cmd === "hideSidebar") {
            sharedData.sidebarVisible = false
        } else if (cmd === "showSidebar") {
            sharedData.sidebarVisible = true
        } else if (cmd === "showLockScreenNonBlocking") {
            sharedData.lockScreenNonBlocking = true
            sharedData.lockScreenVisible = true
        } else if (cmd === "showLockScreen") {
            sharedData.lockScreenNonBlocking = false
            sharedData.lockScreenVisible = true
        } else if (cmd === "hideLockScreen") {
            sharedData.lockScreenVisible = false
        } else if (cmd === "toggleWorkspaceOverview") {
            root.toggleWorkspaceOverview()
        } else if (cmd.startsWith("editScreenshot ")) {
            var path = cmd.substring(15).trim()
            sharedData.activeScreenshotPath = path
        } else if (cmd.startsWith("showThumbnail ")) {
            var path = cmd.substring(14).trim()
            root.showScreenshotThumbnail(path)
        }
    }
    
    function toggleWorkspaceOverview() {
        if (sharedData) {
            sharedData.overviewVisible = !sharedData.overviewVisible
        }
    }
    
    // Funkcja do zamykania/otwierania menu
    function toggleMenu() {
        console.log("shell.qml: Toggling menu. Old state: " + sharedData.menuVisible)
        sharedData.menuVisible = !sharedData.menuVisible
        console.log("shell.qml: New menu state: " + sharedData.menuVisible)
    }

    // Funkcja otwierania launcher'a aplikacji
    function openLauncher() {
        sharedData.launcherVisible = !sharedData.launcherVisible
    }
    
    // Funkcja otwierania clipboard managera
    function openClipboardManager() {
        if (sharedData) {
            var oldState = sharedData.clipboardVisible
            sharedData.clipboardVisible = !oldState
        } else {
        }
    }

    // Funkcja otwierania aplikacji ustawień (quickshell)
    function openSettings() {
        var cmd = "quickshell -p " + projectPath + "/settings.qml"
        processHelper.runCommand(['sh', '-c', cmd])
    }
    
    // Toggle the new Capture HUD
    function toggleCapture() {
        if (sharedData) {
            sharedData.captureMenuVisible = !sharedData.captureMenuVisible
        }
    }
    
    // Screenshot Service - Take screenshot with area selection
    function takeScreenshot() {
        processHelper.runCommand(['sh', '-c', 'if [ -n "$QUICKSHELL_PROJECT_PATH" ]; then echo "$QUICKSHELL_PROJECT_PATH/scripts/take-screenshot.sh"; elif [ -n "$HOME" ]; then echo "$HOME/.config/sharpshell/scripts/take-screenshot.sh"; else echo "/tmp/sharpshell/scripts/take-screenshot.sh"; fi > /tmp/quickshell_screenshot_script_path'], runScreenshotScript)
    }
    
    function runScreenshotScript() {
        var xhr = new XMLHttpRequest()
        xhr.open("GET", "file:///tmp/quickshell_screenshot_script_path")
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                var scriptPath = xhr.responseText.trim()
                if (scriptPath && scriptPath.length > 0) {
                    var esc = scriptPath.replace(/\\/g, "\\\\").replace(/"/g, '\\"')
                    processHelper.runCommand(['sh', '-c', 'hyprctl dispatch exec "bash \\"' + esc + '\\""'])
                }
            }
        }
        xhr.send()
    }
    
    // Unified command + signal check timer – handles commands, wallpaper signals, and color change signals from Fuse
    Timer {
        id: commandCheckTimer
        interval: 500
        running: true
        repeat: true
        onTriggered: {
            // 1) Check for remote commands (launcher, menu, etc.)
            if (!root.commandHandlerBusy) {
                var cmdXhr = new XMLHttpRequest()
                cmdXhr.open("GET", "file:///tmp/quickshell_command")
                cmdXhr.onreadystatechange = function() {
                    if (cmdXhr.readyState === XMLHttpRequest.DONE && (cmdXhr.status === 200 || cmdXhr.status === 0)) {
                        var cmd = (cmdXhr.responseText || "").trim()
                        if (cmd.length > 0) {
                            root.commandHandlerBusy = true
                            root.handleRemoteCommand(cmd)
                            processHelperClear.runCommand(['sh', '-c', ': > /tmp/quickshell_command'], function() {
                                root.commandHandlerBusy = false
                            })
                        }
                    }
                }
                cmdXhr.send()
            }

            // 2) Check for wallpaper change signal from Fuse
            var wallXhr = new XMLHttpRequest()
            wallXhr.open("GET", "file:///tmp/quickshell_wallpaper_path")
            wallXhr.onreadystatechange = function() {
                if (wallXhr.readyState === XMLHttpRequest.DONE && (wallXhr.status === 200 || wallXhr.status === 0)) {
                    var path = (wallXhr.responseText || "").trim()
                    if (path && path.length > 0 && path !== root.currentWallpaperPath) {
                        root.currentWallpaperPath = path
                        processHelperClear.runCommand(['sh', '-c', ': > /tmp/quickshell_wallpaper_path'])
                    }
                }
            }
            wallXhr.send()

            // 3) Check for color change signal from Fuse
            var colorXhr = new XMLHttpRequest()
            colorXhr.open("GET", "file:///tmp/quickshell_color_change?_=" + Date.now())
            colorXhr.onreadystatechange = function() {
                if (colorXhr.readyState === XMLHttpRequest.DONE && (colorXhr.status === 200 || colorXhr.status === 0)) {
                    var raw = (colorXhr.responseText || "").trim()
                    if (raw.length > 0) {
                        var line0 = (raw.split("\n")[0] || "").trim()
                        var pathFromTrigger = (line0.length > 0 && (line0.indexOf("colors.json") >= 0 || line0[0] === "/")) ? line0 : ""
                        var loadPath = pathFromTrigger || root.colorConfigPath || ""
                        if (loadPath) root.loadColors(true, loadPath)
                    }
                }
            }
            colorXhr.send()
        }
    }
    
    // Current wallpaper path - shared across all screens
    property string currentWallpaperPath: ""
    
    // Centralized System Status Timer
    Timer {
        id: statusRefreshTimer
        interval: sharedData.lowPerformanceMode ? 30000 : 15000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            // Refactored helper to run command and read output via /tmp
            var runAndRead = function(cmd, propertyName) {
                var tmpFile = "/tmp/qs_shared_status_" + propertyName
                processHelper.runCommand(['sh', '-c', cmd + " > " + tmpFile], function() {
                    var xhr = new XMLHttpRequest()
                    xhr.open("GET", "file://" + tmpFile)
                    xhr.onreadystatechange = function() {
                        if (xhr.readyState === XMLHttpRequest.DONE) {
                            var out = (xhr.responseText || "").trim()
                            if (sharedData[propertyName] !== out) {
                                // Fix: Check if property is int and parse if necessary
                                if (propertyName === "btDevices" || propertyName === "batteryPct" || propertyName === "netSignal") {
                                    var val = parseInt(out)
                                    sharedData[propertyName] = isNaN(val) ? 0 : val
                                } else {
                                    sharedData[propertyName] = out
                                }
                            }
                        }
                    }
                    xhr.send()
                })
            }

            runAndRead('nmcli -t -f TYPE,NAME connection show --active | grep -E "^(802-11-wireless|ethernet)" | head -n 1 | cut -d: -f2-', "netSSID")
            runAndRead('NW_IP=$(networkctl status 2>/dev/null | grep -i "Address:" | awk \'{print $2}\' | grep -v ":" | head -n1); [ -n "$NW_IP" ] && echo "$NW_IP" || ip -o -4 addr show scope global | awk \'{print $4}\' | cut -d/ -f1 | head -n1 || echo ""', "netIP")
            runAndRead('bluetoothctl show | grep -q "Powered: yes" && echo "On" || echo "Off"', "btStatus")
            runAndRead('bluetoothctl devices Connected | wc -l', "btDevices")
            runAndRead('nmcli -f IN-USE,SIGNAL dev wifi | grep "*" | awk \'{print $2}\' || echo 0', "netSignal")
        }
    }

    // Dedicated Lightweight Battery Status Timer (Efficiency focused)
    Timer {
        id: batteryStatusTimer
        interval: sharedData.lowPerformanceMode ? 5000 : 2500
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            var tmpFile = "/tmp/qs_shared_battery"
            // Combined read for efficiency
            processHelper.runCommand(['sh', '-c', 'cat /sys/class/power_supply/BAT*/capacity /sys/class/power_supply/BAT*/status 2>/dev/null | head -n2 > ' + tmpFile], function() {
                var xhr = new XMLHttpRequest()
                xhr.open("GET", "file://" + tmpFile)
                xhr.onreadystatechange = function() {
                    if (xhr.readyState === XMLHttpRequest.DONE) {
                        var out = (xhr.responseText || "").trim()
                        if (out) {
                            var lines = out.split("\n")
                            if (lines.length >= 1) {
                                var pct = parseInt(lines[0])
                                if (!isNaN(pct)) sharedData.batteryPct = pct
                            }
                            if (lines.length >= 2) {
                                var status = lines[1].trim()
                                if (sharedData.batteryStatus !== status) sharedData.batteryStatus = status
                            }
                        }
                    }
                }
                xhr.send()
            })
        }
    }

    // Per-screen: każdy typ okna ma własny Variants z delegate = PanelWindow (wymagane dla poprawnego bindowania do ekranu)
    Variants {
        model: Quickshell.screens
        delegate: Component {
            WallpaperBackground {
                required property var modelData
                screen: modelData
                currentWallpaper: root.currentWallpaperPath
            }
        }
    }
    Variants {
        model: Quickshell.screens
        delegate: Component {
            SidePanel {
                required property var modelData
                screen: modelData
                panelPosition: (root.sharedData && root.sharedData.sidebarPosition) ? root.sharedData.sidebarPosition : "left"
                sharedData: root.sharedData
                primaryScreen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
                projectPath: root.projectPath
                launcherFunction: root.openLauncher
                screenshotFunction: root.takeScreenshot
                wallpaperPath: root.currentWallpaperPath
            }
        }
    }
    Variants {
        model: Quickshell.screens
        delegate: Component {
            TopEdgeDetector {
                required property var modelData
                screen: modelData
                sharedData: root.sharedData
            }
        }
    }
    
    Variants {
        model: Quickshell.screens
        delegate: Component {
            Notch {
                required property var modelData
                screen: modelData
                sharedData: root.sharedData
                projectPath: root.projectPath
            }
        }
    }
    Variants {
        model: Quickshell.screens
        delegate: Component {
            Loader {
                asynchronous: true
                property var modelData: model
                active: root.sharedData.lockScreenVisible
                sourceComponent: Component {
                    LockScreen {
                        screen: modelData
                        sharedData: root.sharedData
                        projectPath: root.projectPath
                        wallpaperPath: root.currentWallpaperPath
                    }
                }
            }
        }
    }

    // Zmienne z opóźnieniem dla animacji zamknięcia
    property bool dashboardActive: sharedData.menuVisible
    property bool launcherActive: sharedData.launcherVisible
    property bool clipboardActive: sharedData.clipboardVisible
    property bool overviewActive: sharedData.overviewVisible

    Timer {
        id: unloadDelayTimer
        interval: 350
        repeat: false
        onTriggered: {
            if (!root.sharedData.menuVisible) dashboardActive = false;
            if (!root.sharedData.launcherVisible) launcherActive = false;
            if (!root.sharedData.clipboardVisible) clipboardActive = false;
            if (!root.sharedData.overviewVisible) overviewActive = false;
        }
    }

    Connections {
        target: root.sharedData
        function onMenuVisibleChanged() { 
            if (root.sharedData.menuVisible) dashboardActive = true; 
            else unloadDelayTimer.restart(); 
        }
        function onLauncherVisibleChanged() { 
            if (root.sharedData.launcherVisible) launcherActive = true; 
            else unloadDelayTimer.restart(); 
        }
        function onClipboardVisibleChanged() { 
            if (root.sharedData.clipboardVisible) clipboardActive = true; 
            else unloadDelayTimer.restart(); 
        }
        function onOverviewVisibleChanged() { 
            if (root.sharedData.overviewVisible) overviewActive = true; 
            else unloadDelayTimer.restart(); 
        }
    }

    // Dashboard - jeden globalny (nie per-ekran)
    // Pokazuje się gdy myszka najedzie na górną krawędź ekranu
    Loader {
        id: dashboardLoader
        asynchronous: true
        active: root.dashboardActive
        sourceComponent: Component {
            Dashboard {
                id: dashboardInstance
                sharedData: root.sharedData
                projectPath: root.projectPath
                screen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
                // Remove visible: sharedData.menuVisible to allow internal animation-out to work
            }
        }
    }

    // AppLauncher - launcher aplikacji (rofi-like)
    Loader {
        id: appLauncherLoader
        asynchronous: true
        active: root.launcherActive
        sourceComponent: Component {
            AppLauncher {
                id: appLauncherInstance
                sharedData: root.sharedData
                screen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
                projectPath: root.projectPath
                // Remove visible: sharedData.launcherVisible to allow internal animation-out to work
            }
        }
    }

    // VolumeSlider - slider głośności na prawej krawędzi
    // Pokazuje się gdy myszka najedzie na prawą krawędź ekranu
    VolumeSlider {
        id: volumeSliderInstance
        sharedData: root.sharedData
        screen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
    }

    // ClipboardManager - menedżer schowka (jeden na pierwszym ekranie)
    Loader {
        asynchronous: true
        id: clipboardManagerLoader
        active: root.clipboardActive
        sourceComponent: Component {
            ClipboardManager {
                id: clipboardManagerInstance
                screen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
                sharedData: root.sharedData
                // ClipboardManager already handles its own visibility/animations internally
            }
        }
    }

    // NotificationDisplay – jeden na pierwszym ekranie, przy prawej krawędzi
    Variants {
        model: Quickshell.screens.length > 0 ? [Quickshell.screens[0]] : []
        delegate: Component {
            NotificationDisplay {
                required property var modelData
                screen: modelData
                sharedData: root.sharedData
            }
        }
    }

    // Screenshot Editor Loader
    Loader {
        id: screenshotEditorLoader
        active: sharedData.activeScreenshotPath !== ""
        asynchronous: true
        source: "components/ScreenshotEditor.qml"
        onLoaded: {
            item.imagePath = sharedData.activeScreenshotPath
            item.sharedData = sharedData
            item.editorClosed.connect(function() {
                sharedData.activeScreenshotPath = ""
            })
        }
    }

    function showScreenshotThumbnail(path) {
        sharedData.activeThumbnailPath = path
    }

    Variants {
        model: (sharedData.activeThumbnailPath !== "" && Quickshell.screens.length > 0) ? [Quickshell.screens[0]] : []
        delegate: Component {
            Loader {
                id: thumbnailLoader
                required property var modelData
                active: sharedData.activeThumbnailPath !== ""
                source: "components/ScreenshotThumbnail.qml"
                
                onLoaded: {
                    item.screen = modelData
                    item.imagePath = sharedData.activeThumbnailPath
                    item.sharedData = sharedData
                }
            }
        }
    }

    // Workspace Overview - Full-screen grid
    Loader {
        id: workspaceOverviewLoader
        asynchronous: true
        active: root.overviewActive
        sourceComponent: Component {
            WorkspaceOverview {
                id: workspaceOverviewInstance
                sharedData: root.sharedData
                projectPath: root.projectPath
            }
        }
    }

    // Edge detectors moved to top of Z-stack to avoid being blocked by full-window overlays
    Variants {
        model: Quickshell.screens
        delegate: Component {
            RightEdgeDetector {
                required property var modelData
                screen: modelData
                sharedData: root.sharedData
            }
        }
    }
}

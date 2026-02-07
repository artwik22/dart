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

    // Współdzielone właściwości (jeśli potrzebne)
    property var sharedData: QtObject {
        property var runCommand: processHelper ? processHelper.runCommand : function(){}
        property bool menuVisible: false
        property bool launcherVisible: false
        property bool volumeVisible: false
        property bool volumeEdgeHovered: false  // Czy myszka jest nad detektorem krawędzi
        property bool clipboardVisible: false
        property bool settingsVisible: false
        property bool lockScreenVisible: false  // Własny lock screen (zamiast swaylock/loginctl)
        property bool sidebarVisible: true  // Sidebar visibility toggle
        property bool sidebarHiddenByFullscreen: false  // Gdy okno jest fullscreen – sidebar się chowa (Hyprland event "fullscreen")
        property string sidebarPosition: "left"  // Sidebar position: "left" or "top"
        property bool notificationsEnabled: true  // Enable/disable notifications
        property bool notificationSoundsEnabled: true  // Enable/disable notification sounds
        property string sidepanelContent: "calendar"   // "calendar" | "github"
        property string githubUsername: ""             // GitHub username for activity view
        
        // Notification history for notification center
        property var notificationHistory: []

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
                    } catch (e) {
                    }
                }
            }
        }
        xhr.send()
    }
    
    // Funkcja do zamykania/otwierania menu
    function toggleMenu() {
        sharedData.menuVisible = !sharedData.menuVisible
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

    // Funkcja otwierania aplikacji ustawień (fuse)
    function openSettings() {
        var scaleFactor = (sharedData && sharedData.uiScale) ? sharedData.uiScale : 1.0
        var scaleStr = String(scaleFactor)
        var cmd = "GTK_SCALE_FACTOR=" + scaleStr + " fuse 2>/dev/null || GTK_SCALE_FACTOR=" + scaleStr + " $HOME/.local/bin/fuse 2>/dev/null || GTK_SCALE_FACTOR=" + scaleStr + " $HOME/.config/alloy/fuse/target/release/fuse 2>/dev/null"
        processHelper.runCommand(['sh', '-c', cmd.replace(/'/g, "'\"'\"'")])
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
    
    // Polecenia: odczyt XHR; gdy niepusty – akcja od razu, potem clear. busy=false dopiero w callbacku clear,
    // żeby następny poll nie zobaczył tego samego polecenia (brak migotania, bez okien „duplikat”).
    Timer {
        id: commandCheckTimer
        interval: (sharedData && sharedData.lowPerformanceMode) ? 600 : 40
        running: true
        repeat: true
        
        onTriggered: {
            if (root.commandHandlerBusy) return
            root.commandHandlerBusy = true
            var xhr = new XMLHttpRequest()
            xhr.open("GET", "file:///tmp/quickshell_command")
            xhr.onreadystatechange = function() {
                if (xhr.readyState !== XMLHttpRequest.DONE) return
                if (xhr.status !== 200 && xhr.status !== 0) {
                    root.commandHandlerBusy = false
                    return
                }
                var cmd = (xhr.responseText || "").trim()
                if (!cmd || cmd.length === 0) {
                    root.commandHandlerBusy = false
                    return
                }
                if (cmd === "openLauncher") {
                    root.openLauncher()
                } else if (cmd === "toggleMenu") {
                    root.toggleMenu()
                } else if (cmd === "openClipboardManager") {
                    root.openClipboardManager()
                } else if (cmd === "openSettings") {
                    root.openSettings()
                } else if (cmd === "hideSidebar") {
                    sharedData.sidebarVisible = false
                } else if (cmd === "showSidebar") {
                    sharedData.sidebarVisible = true
                }
                processHelperClear.runCommand(['sh', '-c', ': > /tmp/quickshell_command'], function() {
                    root.commandHandlerBusy = false
                })
            }
            xhr.send()
        }
    }
    
    // Current wallpaper path - shared across all screens
    property string currentWallpaperPath: ""
    
    // Timer do monitorowania zmiany tapety
    Timer {
        id: wallpaperCheckTimer
        interval: (sharedData && sharedData.lowPerformanceMode) ? 1500 : 1000
        running: true
        repeat: true
        
        onTriggered: {
            var xhr = new XMLHttpRequest()
            xhr.open("GET", "file:///tmp/quickshell_wallpaper_path")
            xhr.onreadystatechange = function() {
                if (xhr.readyState === XMLHttpRequest.DONE) {
                    if (xhr.status === 200 || xhr.status === 0) {
                        var path = xhr.responseText.trim()
                        if (path && path.length > 0 && path !== root.currentWallpaperPath) {
                            root.currentWallpaperPath = path
                        }
                        // Plik pozostawiamy – kolejna zmiana tapety go nadpisze
                    }
                }
            }
            xhr.send()
        }
    }
    
    // Szybszy timer tylko dla sygnału Fuse – kolory odświeżane w ~500 ms po zmianie w Fuse
    // Fuse zapisuje w pliku: pierwszą linię = ścieżka do colors.json, potem "reload_TIMESTAMP"
    Timer {
        id: fuseNotifyTimer
        interval: (sharedData && sharedData.lowPerformanceMode) ? 800 : 500
        running: true
        repeat: true
        onTriggered: {
            var xhr = new XMLHttpRequest()
            xhr.open("GET", "file:///tmp/quickshell_color_change?_=" + Date.now())
            xhr.onreadystatechange = function() {
                if (xhr.readyState === XMLHttpRequest.DONE && (xhr.status === 200 || xhr.status === 0)) {
                    var raw = (xhr.responseText || "").trim()
                    if (raw.length > 0) {
                        var line0 = (raw.split("\n")[0] || "").trim()
                        var pathFromTrigger = (line0.length > 0 && (line0.indexOf("colors.json") >= 0 || line0[0] === "/")) ? line0 : ""
                        var loadPath = pathFromTrigger || root.colorConfigPath || ""
                        if (loadPath) root.loadColors(false, loadPath)
                        if (sharedData && sharedData.runCommand)
                            sharedData.runCommand(['sh', '-c', ': > /tmp/quickshell_color_change'])
                    }
                }
            }
            xhr.send()
        }
    }
    
    // Timer do monitorowania zmiany kolorów i ustawień (colors.json + ponownie sygnał)
    Timer {
        id: colorCheckTimer
        interval: (sharedData && sharedData.lowPerformanceMode) ? 4000 : 2500
        running: true
        repeat: true
        
        onTriggered: {
            // Sprawdź czy colors.json się zmienił
            if (root.colorConfigPath) {
                var xhr = new XMLHttpRequest()
                xhr.open("GET", "file://" + root.colorConfigPath + "?_=" + Date.now())
                xhr.onreadystatechange = function() {
                    if (xhr.readyState === XMLHttpRequest.DONE) {
                        if (xhr.status === 200 || xhr.status === 0) {
                            try {
                                var json = JSON.parse(xhr.responseText)
                                var changed = false
                                var c = root.getResolvedColors(json)
                                if (c) {
                                    if (c.background && c.background !== sharedData.colorBackground) { sharedData.colorBackground = c.background; changed = true }
                                    if (c.primary && c.primary !== sharedData.colorPrimary) { sharedData.colorPrimary = c.primary; changed = true }
                                    if (c.secondary && c.secondary !== sharedData.colorSecondary) { sharedData.colorSecondary = c.secondary; changed = true }
                                    if (c.text && c.text !== sharedData.colorText) { sharedData.colorText = c.text; changed = true }
                                    if (c.accent && c.accent !== sharedData.colorAccent) { sharedData.colorAccent = c.accent; changed = true }
                                }
                                
                                // Enable live reloading for sidebar position to support Fuse changes immediately
                                if (json.sidebarPosition && (json.sidebarPosition === "left" || json.sidebarPosition === "top" || json.sidebarPosition === "right" || json.sidebarPosition === "bottom")) {
                                    if (json.sidebarPosition !== sharedData.sidebarPosition) {
                                        sharedData.sidebarPosition = json.sidebarPosition
                                        changed = true
                                    }
                                }
                                
                                if (json.dashboardTileLeft === "battery" || json.dashboardTileLeft === "network") {
                                    if (json.dashboardTileLeft !== sharedData.dashboardTileLeft) {
                                        sharedData.dashboardTileLeft = json.dashboardTileLeft
                                        changed = true
                                    }
                                }
                                if (json.dashboardPosition && (json.dashboardPosition === "left" || json.dashboardPosition === "top" || json.dashboardPosition === "right" || json.dashboardPosition === "bottom")) {
                                    if (json.dashboardPosition !== sharedData.dashboardPosition) {
                                        sharedData.dashboardPosition = json.dashboardPosition
                                        changed = true
                                    }
                                }
                                if (json.sidepanelContent === "calendar" || json.sidepanelContent === "github") {
                                    if (json.sidepanelContent !== sharedData.sidepanelContent) {
                                        sharedData.sidepanelContent = json.sidepanelContent
                                        changed = true
                                    }
                                }
                                if (json.dashboardResource1 && json.dashboardResource1 !== sharedData.dashboardResource1) {
                                    sharedData.dashboardResource1 = json.dashboardResource1
                                    changed = true
                                }
                                if (json.dashboardResource2 && json.dashboardResource2 !== sharedData.dashboardResource2) {
                                    sharedData.dashboardResource2 = json.dashboardResource2
                                    changed = true
                                }
                                if (json.githubUsername && String(json.githubUsername) !== sharedData.githubUsername) {
                                    sharedData.githubUsername = String(json.githubUsername)
                                    changed = true
                                }
                                if (json.notificationPosition && json.notificationPosition !== sharedData.notificationPosition) {
                                    sharedData.notificationPosition = json.notificationPosition
                                    changed = true
                                }
                                if (json.notificationRounding && json.notificationRounding !== sharedData.notificationRounding) {
                                    sharedData.notificationRounding = json.notificationRounding
                                    changed = true
                                }
                                if (json.quickshellBorderRadius !== undefined) {
                                    var qbr = parseInt(json.quickshellBorderRadius)
                                    if (!isNaN(qbr) && qbr !== sharedData.quickshellBorderRadius) {
                                        sharedData.quickshellBorderRadius = qbr
                                        changed = true
                                    }
                                }
                                
                                // Note: We don't auto-reload sidebarVisible from file watcher
                                // because user toggles it directly in the UI. Only load it on startup
                                // to avoid race condition with Dashboard save function
                                
                                if (changed) {
                                }
                            } catch (e) {
                            }
                        }
                    }
                }
                xhr.send()
            }
            
            // Sprawdź czy jest plik z poleceniem do przeładowania (Fuse notify_color_change)
            // Cache-busting: ?_=timestamp zapobiega zwracaniu cache’owanej treści przez file://
            var cmdXhr = new XMLHttpRequest()
            cmdXhr.open("GET", "file:///tmp/quickshell_color_change?_=" + Date.now())
            cmdXhr.onreadystatechange = function() {
                if (cmdXhr.readyState === XMLHttpRequest.DONE && (cmdXhr.status === 200 || cmdXhr.status === 0)) {
                    var raw = (cmdXhr.responseText || "").trim()
                    if (raw.length > 0) {
                        var line0 = (raw.split("\n")[0] || "").trim()
                        var pathFromTrigger = (line0.length > 0 && (line0.indexOf("colors.json") >= 0 || line0[0] === "/")) ? line0 : ""
                        var loadPath = pathFromTrigger || root.colorConfigPath || ""
                        if (loadPath) root.loadColors(true, loadPath)
                    }
                }
            }
            cmdXhr.send()
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
            RightEdgeDetector {
                required property var modelData
                screen: modelData
                sharedData: root.sharedData
            }
        }
    }
    Variants {
        model: Quickshell.screens
        delegate: Component {
            LockScreen {
                required property var modelData
                screen: modelData
                sharedData: root.sharedData
                projectPath: root.projectPath
            }
        }
    }

    // Dashboard - jeden globalny (nie per-ekran)
    // Pokazuje się gdy myszka najedzie na górną krawędź ekranu
    Dashboard {
        id: dashboardInstance
        sharedData: root.sharedData
        projectPath: root.projectPath
    }

    // AppLauncher - launcher aplikacji (rofi-like)
    // Używamy pierwszego ekranu do wyśrodkowania
    AppLauncher {
        id: appLauncherInstance
        sharedData: root.sharedData
        screen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
        projectPath: root.projectPath
    }

    // VolumeSlider - slider głośności na prawej krawędzi
    // Pokazuje się gdy myszka najedzie na prawą krawędź ekranu
    VolumeSlider {
        id: volumeSliderInstance
        sharedData: root.sharedData
        screen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
    }

    // ClipboardManager - menedżer schowka (jeden na pierwszym ekranie)
    ClipboardManager {
        id: clipboardManagerInstance
        screen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
        sharedData: root.sharedData
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
}


import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import "components"

ShellRoot {
    id: root
    
    // Współdzielone właściwości (jeśli potrzebne)
    property var sharedData: QtObject {
        property bool menuVisible: false
        property bool launcherVisible: false
        property bool volumeVisible: false
        property bool volumeEdgeHovered: false  // Czy myszka jest nad detektorem krawędzi
        property bool clipboardVisible: false
        property bool settingsVisible: false
        property bool sidebarVisible: true  // Sidebar visibility toggle
        property string sidebarPosition: "left"  // Sidebar position: "left" or "top"
        property bool notificationsEnabled: true  // Enable/disable notifications
        property bool notificationSoundsEnabled: true  // Enable/disable notification sounds
        
        // Notification history for notification center
        property var notificationHistory: []

        // Color theme properties
        property string colorBackground: "#0a0a0a"
        property string colorPrimary: "#1a1a1a"
        property string colorSecondary: "#141414"
        property string colorText: "#ffffff"
        property string colorAccent: "#4a9eff"
    }
    
    // Color config file path - dynamically determined
    property string colorConfigPath: ""
    
    // Initialize color config path from environment
    function initializeColorPath() {
        Qt.createQmlObject("import Quickshell.Io; import QtQuick; Process { command: ['sh', '-c', 'echo \"$HOME\" > /tmp/quickshell_home_root 2>/dev/null || echo \"\" > /tmp/quickshell_home_root']; running: true }", root)
        Qt.createQmlObject("import QtQuick; Timer { interval: 100; running: true; repeat: false; onTriggered: root.readHomePathRoot() }", root)
    }
    
    function readHomePathRoot() {
        var xhr = new XMLHttpRequest()
        xhr.open("GET", "file:///tmp/quickshell_home_root")
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                var home = xhr.responseText.trim()
                if (home && home.length > 0) {
                    colorConfigPath = home + "/.config/sharpshell/colors.json"
                    console.log("Color config path initialized:", colorConfigPath)
                    loadColors()
                } else {
                    // Fallback - try to use QUICKSHELL_PROJECT_PATH
                    Qt.createQmlObject("import Quickshell.Io; import QtQuick; Process { command: ['sh', '-c', 'echo \"$QUICKSHELL_PROJECT_PATH\" > /tmp/quickshell_config_path 2>/dev/null || echo \"\" > /tmp/quickshell_config_path']; running: true }", root)
                    Qt.createQmlObject("import QtQuick; Timer { interval: 100; running: true; repeat: false; onTriggered: root.readConfigPath() }", root)
                }
            }
        }
        xhr.send()
    }
    
    function readConfigPath() {
        var xhr = new XMLHttpRequest()
        xhr.open("GET", "file:///tmp/quickshell_config_path")
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                var path = xhr.responseText.trim()
                if (path && path.length > 0) {
                    colorConfigPath = path + "/colors.json"
                } else {
                    colorConfigPath = "/tmp/sharpshell/colors.json"
                }
                console.log("Color config path (fallback):", colorConfigPath)
                loadColors()
            }
        }
        xhr.send()
    }
    
    // Load colors on startup
    Component.onCompleted: {
        initializeColorPath()
    }
    
    function loadColors() {
        if (!colorConfigPath) {
            console.log("Color config path not initialized yet")
            return
        }
        var xhr = new XMLHttpRequest()
        xhr.open("GET", "file://" + colorConfigPath)
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200 || xhr.status === 0) {
                    try {
                        var json = JSON.parse(xhr.responseText)
                        if (json.background) sharedData.colorBackground = json.background
                        if (json.primary) sharedData.colorPrimary = json.primary
                        if (json.secondary) sharedData.colorSecondary = json.secondary
                        if (json.text) sharedData.colorText = json.text
                        if (json.accent) sharedData.colorAccent = json.accent
                        
                        // Load last wallpaper if available
                        if (json.lastWallpaper && json.lastWallpaper.length > 0) {
                            root.currentWallpaperPath = json.lastWallpaper
                            console.log("Loaded last wallpaper from colors.json:", json.lastWallpaper)
                        }
                        
                        // Load sidebar position if available
                        if (json.sidebarPosition && (json.sidebarPosition === "left" || json.sidebarPosition === "top")) {
                            sharedData.sidebarPosition = json.sidebarPosition
                            console.log("Loaded sidebar position from colors.json:", json.sidebarPosition)
                        }
                        
                        // Load color preset if available (for reference, not applied automatically)
                        if (json.colorPreset && json.colorPreset.length > 0) {
                            console.log("Loaded color preset from colors.json:", json.colorPreset)
                        }
                        
                        // Load notification settings if available
                        if (json.notificationsEnabled !== undefined) {
                            sharedData.notificationsEnabled = json.notificationsEnabled === true || json.notificationsEnabled === "true"
                            console.log("Loaded notificationsEnabled from colors.json:", sharedData.notificationsEnabled)
                        }
                        if (json.notificationSoundsEnabled !== undefined) {
                            sharedData.notificationSoundsEnabled = json.notificationSoundsEnabled === true || json.notificationSoundsEnabled === "true"
                            console.log("Loaded notificationSoundsEnabled from colors.json:", sharedData.notificationSoundsEnabled)
                        }
                    } catch (e) {
                        console.log("Error parsing colors.json:", e)
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
        console.log("openClipboardManager called, sharedData:", sharedData)
        if (sharedData) {
            var oldState = sharedData.clipboardVisible
            sharedData.clipboardVisible = !oldState
            console.log("Toggling clipboard manager from", oldState, "to", sharedData.clipboardVisible)
        } else {
            console.log("sharedData is null!")
        }
    }

    // Funkcja otwierania aplikacji ustawień
    function openSettings() {
        sharedData.settingsVisible = !sharedData.settingsVisible
    }
    
    // Screenshot Service - Take screenshot with area selection
    function takeScreenshot() {
        console.log("takeScreenshot called")
        
        // Get script path - try environment variable first, then fallback to home directory
        Qt.createQmlObject("import Quickshell.Io; import QtQuick; Process { command: ['sh', '-c', 'if [ -n \"$QUICKSHELL_PROJECT_PATH\" ]; then echo \"$QUICKSHELL_PROJECT_PATH/scripts/take-screenshot.sh\"; elif [ -n \"$HOME\" ]; then echo \"$HOME/.config/sharpshell/scripts/take-screenshot.sh\"; else echo \"/tmp/sharpshell/scripts/take-screenshot.sh\"; fi > /tmp/quickshell_screenshot_script_path']; running: true }", root)
        Qt.createQmlObject("import QtQuick; Timer { interval: 100; running: true; repeat: false; onTriggered: root.runScreenshotScript() }", root)
    }
    
    function runScreenshotScript() {
        var xhr = new XMLHttpRequest()
        xhr.open("GET", "file:///tmp/quickshell_screenshot_script_path")
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                var scriptPath = xhr.responseText.trim()
                if (scriptPath && scriptPath.length > 0) {
                    console.log("Running screenshot script:", scriptPath)
                    // Run screenshot script through hyprctl to ensure it has proper Wayland access
                    // This allows slurp to interact with the user properly
                    Qt.createQmlObject(
                        "import Quickshell.Io; import QtQuick; Process { " +
                        "command: ['sh', '-c', 'hyprctl dispatch exec \"bash \\\"" + scriptPath.replace(/"/g, '\\"') + "\\\"\"']; " +
                        "running: true }",
                        root
                    )
                } else {
                    console.log("Screenshot script path not found.")
                }
            }
        }
        xhr.send()
    }
    
    // Timer do monitorowania pliku poleceń dla skrótów klawiszowych z Hyprland
    Timer {
        id: commandCheckTimer
        interval: 100  // Sprawdzaj co 100ms
        running: true
        repeat: true
        
        onTriggered: {
            var xhr = new XMLHttpRequest()
            xhr.open("GET", "file:///tmp/quickshell_command")
            xhr.onreadystatechange = function() {
                if (xhr.readyState === XMLHttpRequest.DONE) {
                    if (xhr.status === 200 || xhr.status === 0) {
                        var cmd = xhr.responseText.trim()
                        if (cmd === "openLauncher") {
                            root.openLauncher()
                            // Usuń plik po przetworzeniu
                            Qt.createQmlObject("import Quickshell.Io; import QtQuick; Process { command: ['sh', '-c', 'rm -f /tmp/quickshell_command']; running: true }", root)
                        } else if (cmd === "toggleMenu") {
                            root.toggleMenu()
                            // Usuń plik po przetworzeniu
                            Qt.createQmlObject("import Quickshell.Io; import QtQuick; Process { command: ['sh', '-c', 'rm -f /tmp/quickshell_command']; running: true }", root)
                        } else if (cmd === "openClipboardManager") {
                            root.openClipboardManager()
                            // Usuń plik po przetworzeniu
                            Qt.createQmlObject("import Quickshell.Io; import QtQuick; Process { command: ['sh', '-c', 'rm -f /tmp/quickshell_command']; running: true }", root)
                        } else if (cmd === "openSettings") {
                            root.openSettings()
                            // Usuń plik po przetworzeniu
                            Qt.createQmlObject("import Quickshell.Io; import QtQuick; Process { command: ['sh', '-c', 'rm -f /tmp/quickshell_command']; running: true }", root)
                        }
                    }
                }
            }
            xhr.send()
        }
    }
    
    // Current wallpaper path - shared across all screens
    property string currentWallpaperPath: ""
    
    // Timer do monitorowania zmiany tapety
    Timer {
        id: wallpaperCheckTimer
        interval: 200  // Sprawdzaj co 200ms
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
                            console.log("Wallpaper changed to:", path)
                            // Usuń plik po przetworzeniu
                            Qt.createQmlObject("import Quickshell.Io; import QtQuick; Process { command: ['sh', '-c', 'rm -f /tmp/quickshell_wallpaper_path']; running: true }", root)
                        }
                    }
                }
            }
            xhr.send()
        }
    }
    
    Variants {
        model: Quickshell.screens
        
        delegate: Component {
            Item {
                id: screenContainer
                required property var modelData
                
                // Wallpaper background - jeden na ekran
                WallpaperBackground {
                    id: wallpaperInstance
                    screen: modelData
                    currentWallpaper: root.currentWallpaperPath
                }
                
                // Panel boczny - lewy (SidePanel) - jeden na ekran
                SidePanel {
                    id: sidePanelLeftInstance
                    screen: modelData
                    panelPosition: "left"
                    sharedData: root.sharedData
                    settingsFunction: root.openSettings
                    launcherFunction: root.openLauncher
                    clipboardFunction: root.openClipboardManager
                    screenshotFunction: root.takeScreenshot
                }
                
                // Panel boczny - górny (SidePanel) - jeden na ekran
                SidePanel {
                    id: sidePanelTopInstance
                    screen: modelData
                    panelPosition: "top"
                    sharedData: root.sharedData
                    settingsFunction: root.openSettings
                    launcherFunction: root.openLauncher
                    clipboardFunction: root.openClipboardManager
                    screenshotFunction: root.takeScreenshot
                }
                
                // Wykrywacz górnej krawędzi - wykrywa najechanie myszką
                TopEdgeDetector {
                    id: edgeDetectorInstance
                    screen: modelData
                    sharedData: root.sharedData
                }
                
                // Wykrywacz prawej krawędzi - wykrywa najechanie myszką
                RightEdgeDetector {
                    id: rightEdgeDetectorInstance
                    screen: modelData
                    sharedData: root.sharedData
                }
            }
        }
    }
    
    // Dashboard - jeden globalny (nie per-ekran)
    // Pokazuje się gdy myszka najedzie na górną krawędź ekranu
    Dashboard {
        id: dashboardInstance
        sharedData: root.sharedData
    }
    
    // AppLauncher - launcher aplikacji (rofi-like)
    // Używamy pierwszego ekranu do wyśrodkowania
    AppLauncher {
        id: appLauncherInstance
        sharedData: root.sharedData
        screen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
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

    // SettingsApplication - aplikacja ustawień
    SettingsApplication {
        id: settingsApplicationInstance
        screen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
        sharedData: root.sharedData
        visible: sharedData.settingsVisible
    }

    // NotificationDisplay - wyświetlanie powiadomień w prawym górnym rogu
    NotificationDisplay {
        id: notificationDisplayInstance
        sharedData: root.sharedData
    }
    
}


import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import "components"

ShellRoot {
    id: root

    ProcessHelper { id: processHelper }

    // Shared data and configuration management
    property var sharedData: QtObject {
        // Toggles & Flags
        property bool sidebarVisible: true
        property string sidebarPosition: "left"
        property string sidebarStyle: "dots"
        property bool sidebarBatteryEnabled: true
        property string sidebarWorkspaceMode: "top"
        property bool dynamicSidebarBackground: false
        property bool micaSidebarBackground: false
        
        property bool notificationsEnabled: true
        property bool notificationSoundsEnabled: true
        property string notificationPosition: "top"
        property string notificationRounding: "standard"
        property string notificationSound: "message.oga"
        
        property bool floatingDashboard: true
        property string dashboardPosition: "right"
        property string dashboardTileLeft: "battery"
        property string dashboardResource1: "cpu"
        property string dashboardResource2: "ram"
        
        property bool screensaverWidgetsEnabled: true
        property int screensaverTimeout: 30
        property int batteryThreshold: 10
        
        property bool lockscreenMediaEnabled: true
        property bool lockscreenWeatherEnabled: true
        property bool lockscreenBatteryEnabled: true
        property bool lockscreenCalendarEnabled: true
        property bool lockscreenNetworkEnabled: false
        
        property bool clockBlinkColon: true
        property bool showHiddenFiles: false
        property string githubUsername: ""
        property string weatherLocation: "London"
        property real uiScale: 1.0
        property int quickshellBorderRadius: 0
        
        // Colors
        property string colorBackground: "#0a0a0a"
        property string colorPrimary: "#1a1a1a"
        property string colorSecondary: "#141414"
        property string colorText: "#ffffff"
        property string colorAccent: "#4a9eff"
        
        // Helper functions
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
    }

    property string colorConfigPath: ""
    property string projectPath: ""

    // Initialization logic (mirrored from shell.qml)
    Component.onCompleted: {
        initializePaths()
    }

    function initializePaths() {
        processHelper.runCommand(['sh', '-c', 'echo "$HOME|$QUICKSHELL_PROJECT_PATH" > /tmp/quickshell_settings_init 2>/dev/null || true'], function() {
            var xhr = new XMLHttpRequest()
            xhr.open("GET", "file:///tmp/quickshell_settings_init")
            xhr.onreadystatechange = function() {
                if (xhr.readyState !== XMLHttpRequest.DONE) return
                var line = (xhr.responseText || "").trim()
                var parts = line.split("|")
                var home = (parts[0] || "").trim()
                var projPath = (parts[1] || "").trim()
                root.projectPath = projPath

                // Path resolution logic (alloy -> project -> legacy -> fallback)
                function findConfig() {
                    var alloyPath = home + "/.config/alloy/colors.json"
                    var projectPathColors = projPath + "/colors.json"
                    var legacyPath = home + "/.config/sharpshell/colors.json"
                    
                    // Simple check for existence via XHR
                    var paths = [alloyPath, projectPathColors, legacyPath]
                    function tryNext(index) {
                        if (index >= paths.length) {
                            root.colorConfigPath = "/tmp/alloy/colors.json"
                            loadColors()
                            return
                        }
                        var checkXhr = new XMLHttpRequest()
                        checkXhr.open("GET", "file://" + paths[index])
                        checkXhr.onreadystatechange = function() {
                            if (checkXhr.readyState === XMLHttpRequest.DONE) {
                                if (checkXhr.status === 200 || checkXhr.status === 0) {
                                    root.colorConfigPath = paths[index]
                                    loadColors()
                                } else {
                                    tryNext(index + 1)
                                }
                            }
                        }
                        checkXhr.send()
                    }
                    tryNext(0)
                }
                findConfig()
            }
            xhr.send()
        })
    }

    function loadColors() {
        if (!colorConfigPath) return
        var xhr = new XMLHttpRequest()
        xhr.open("GET", "file://" + colorConfigPath)
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE && (xhr.status === 200 || xhr.status === 0)) {
                try {
                    var config = JSON.parse(xhr.responseText)
                    if (config.background) sharedData.colorBackground = config.background
                    if (config.primary) sharedData.colorPrimary = config.primary
                    if (config.secondary) sharedData.colorSecondary = config.secondary
                    if (config.text) sharedData.colorText = config.text
                    if (config.accent) sharedData.colorAccent = config.accent
                    
                    // Load other properties if present
                    if (config.sidebarVisible !== undefined) sharedData.sidebarVisible = config.sidebarVisible
                    if (config.sidebarPosition) sharedData.sidebarPosition = config.sidebarPosition
                    if (config.notificationsEnabled !== undefined) sharedData.notificationsEnabled = config.notificationsEnabled
                    if (config.uiScale) sharedData.uiScale = config.uiScale / 100.0
                    // ... load more as needed
                } catch (e) {
                    console.log("Error parsing colors.json:", e)
                }
            }
        }
        xhr.send()
    }

    SettingsApplication {
        sharedData: root.sharedData
        projectPath: root.projectPath
        colorConfigPath: root.colorConfigPath
        // wallpapersPath is handled inside SettingsApplication or can be passed here
    }
}
            runAndRead('nmcli -f IN-USE,SIGNAL dev wifi | grep "*" | awk \'{print $2}\' || echo 0', "netSignal")
            sharedData.netStatus = sharedData.netSSID ? "Connected" : "Disconnected"
        }
    }

    SettingsApplication {
        sharedData: root.sharedData
        projectPath: root.projectPath
        colorConfigPath: root.colorConfigPath
        processHelper: processHelper // FIXED: Reference the component ID directly
    }
}

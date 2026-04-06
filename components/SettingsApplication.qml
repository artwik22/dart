import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
// import "settings" -- directory does not exist

PanelWindow {
    id: settingsApplicationRoot

    property var sharedData: null
    property var screen: null
    property string projectPath: "/home/iartwik/.config/alloy/dart" 
    property string wallpapersPath: "/home/iartwik/Pictures/Wallpapers"
    property string colorConfigPath: "/home/iartwik/.config/alloy/colors.json"
    
    // Theme colors synchronized with sharedData
    property color colorBackground: sharedData ? sharedData.colorBackground : "#0a0a0a"
    property color colorPrimary: sharedData ? sharedData.colorPrimary : "#1a1a1a"
    property color colorSecondary: sharedData ? sharedData.colorSecondary : "#121212"
    property color colorText: sharedData ? sharedData.colorText : "#ffffff"
    property color colorAccent: sharedData ? sharedData.colorAccent : "#4a9eff"
    property int globalRadius: sharedData ? (sharedData.quickshellBorderRadius || 8) : 8

    property int currentTab: 0

    // Models
    ListModel { id: wallpapersModel }
    ListModel { id: audioSinksModel }
    ListModel { id: audioSourcesModel }

    // Logic Functions
    function saveColors(wallpaperPath, presetName, sidebarPos) {
        if (!projectPath || !colorConfigPath) return
        var scriptPath = projectPath + "/scripts/save-colors.py"
        var cmd = 'python3 "' + scriptPath + '" "' + colorBackground + '" "' + colorPrimary + '" "' + colorSecondary + '" "' + colorText + '" "' + colorAccent + '" "' + colorConfigPath + '"'
        cmd += ' "' + (wallpaperPath || "") + '"'
        cmd += ' "' + (presetName || "") + '"'
        cmd += ' "' + (sidebarPos || "") + '"'
        
        Qt.createQmlObject("import Quickshell.Io; Process { command: [" + JSON.stringify("sh") + ", \"-c\", " + JSON.stringify(cmd) + "]; running: true }", settingsApplicationRoot)
    }

    function applyColorPreset(presetName) {
        var preset = colorPresets[presetName]
        if (!preset) return
        if (sharedData) {
            sharedData.colorBackground = preset.background
            sharedData.colorPrimary = preset.primary
            sharedData.colorSecondary = preset.secondary
            sharedData.colorText = preset.text
            sharedData.colorAccent = preset.accent
        }
        saveColors("", presetName, sharedData ? sharedData.sidebarPosition : "")
    }

    function loadWallpapers() {
        if (!wallpapersPath) return
        var findCmd = "find -L '" + wallpapersPath + "' -maxdepth 1 -type f \\( -iname '*.jpg' -o -iname '*.png' -o -iname '*.jpeg' \\) 2>/dev/null | sort"
        var proc = Qt.createQmlObject('import Quickshell.Io; import QtQuick; Process { command: ["sh", "-c", ' + JSON.stringify(findCmd) + ']; running: true; onFinished: function() { var lines = readAllStandardOutput().toString().trim().split("\\n"); wallpapersModel.clear(); for(var i=0; i<lines.length; i++) if(lines[i]) wallpapersModel.append({path: lines[i], filename: lines[i].split("/").pop()}); } }', settingsApplicationRoot)
    }

    function setWallpaper(path) {
        Qt.createQmlObject('import Quickshell.Io; Process { command: ["sh", "-c", "echo \'' + path + '\' > /tmp/quickshell_wallpaper_path"]; running: true }', settingsApplicationRoot)
        saveColors(path, "", sharedData ? sharedData.sidebarPosition : "")
    }

    // Color Presets Data
    property var colorPresets: {
        "Dark": { background: "#0a0a0a", primary: "#1a1a1a", secondary: "#121212", text: "#ffffff", accent: "#4a9eff" },
        "Ocean": { background: "#0a1628", primary: "#1e3a52", secondary: "#152535", text: "#ffffff", accent: "#4fc3f7" },
        "Forest": { background: "#0d1a0d", primary: "#1e3a1e", secondary: "#152515", text: "#ffffff", accent: "#66bb6a" },
        "Violet": { background: "#1a0d26", primary: "#2e1f3f", secondary: "#231a35", text: "#ffffff", accent: "#ab47bc" }
    }

    // Window Layout
    width: 1000
    height: 700
    
    Rectangle {
        anchors.fill: parent
        color: colorBackground
        radius: globalRadius
        clip: true

        RowLayout {
            anchors.fill: parent
            spacing: 0

            // Sidebar
            Rectangle {
                Layout.fillHeight: true
                width: 200
                color: colorSecondary

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 4

                    Text {
                        text: "Settings"
                        color: colorAccent
                        font.pixelSize: 18
                        font.weight: Font.Bold
                        Layout.margins: 10
                    }

                    Repeater {
                        model: [
                            "General", "Appearance", "Wallpapers", "Bar", 
                            "Notifications", "Dashboard", "Lockscreen", 
                            "Audio", "Connectivity", "Blink", "System", "About"
                        ]
                        delegate: Rectangle {
                            Layout.fillWidth: true
                            height: 40
                            radius: 6
                            color: currentTab === index ? colorAccent : (navMouse.containsMouse ? Qt.rgba(1,1,1,0.05) : "transparent")
                            
                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 15
                                Text {
                                    text: modelData
                                    color: colorText
                                    font.pixelSize: 13
                                    font.weight: currentTab === index ? Font.Bold : Font.Normal
                                    opacity: currentTab === index ? 1.0 : 0.8
                                }
                            }

                            MouseArea {
                                id: navMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: currentTab = index
                            }
                        }
                    }
                    
                    Item { Layout.fillHeight: true } // Spacer
                }
            }

            // Main Content Area
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: "transparent"

                StackLayout {
                    anchors.fill: parent
                    currentIndex: currentTab

                    GeneralTab { sharedData: settingsApplicationRoot.sharedData; settingsRoot: settingsApplicationRoot }
                    AppearanceTab { sharedData: settingsApplicationRoot.sharedData; settingsRoot: settingsApplicationRoot }
                    WallpapersTab { sharedData: settingsApplicationRoot.sharedData; settingsRoot: settingsApplicationRoot }
                    BarTab { sharedData: settingsApplicationRoot.sharedData; settingsRoot: settingsApplicationRoot }
                    NotificationsTab { sharedData: settingsApplicationRoot.sharedData; settingsRoot: settingsApplicationRoot }
                    DashboardTab { sharedData: settingsApplicationRoot.sharedData; settingsRoot: settingsApplicationRoot }
                    LockscreenTab { sharedData: settingsApplicationRoot.sharedData; settingsRoot: settingsApplicationRoot }
                    AudioTab { sharedData: settingsApplicationRoot.sharedData; settingsRoot: settingsApplicationRoot }
                    ConnectivityTab { sharedData: settingsApplicationRoot.sharedData; settingsRoot: settingsApplicationRoot }
                    BlinkTab { sharedData: settingsApplicationRoot.sharedData; settingsRoot: settingsApplicationRoot }
                    SystemTab { sharedData: settingsApplicationRoot.sharedData; settingsRoot: settingsApplicationRoot }
                    Item { 
                        Text { 
                            anchors.centerIn: parent
                            text: "Alloy Settings v1.0\nCreated with Quickshell"
                            color: colorText; horizontalAlignment: Text.AlignHCenter
                            opacity: 0.5; font.pixelSize: 16
                        }
                    }
                }
            }
        }
    }
    
    Component.onCompleted: {
        loadWallpapers()
    }
}

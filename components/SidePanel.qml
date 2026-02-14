import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell.Services.SystemTray
import "."

PanelWindow {
    id: sidePanel
    
    required property var screen
    required property string panelPosition
    property var primaryScreen: null
    property string projectPath: ""
    
    property string qNetStatus: "Checking..."
    property string qNetSSID: ""
    property string qNetIP: ""
    property string qBtStatus: "Checking..."
    property int qBtDevices: 0
    property string qPwrStatus: "Checking..."
    property int qBatteryPct: 0
    property string qBatteryStatus: "Unknown"
    property int qNetSignal: 0
    property string qNetNearby: ""
    property string qBtDeviceNames: ""
    property string qBtPaired: ""
    property string qBtConnectingMac: ""

    
    property var sidePanelRoot: sidePanel
    property bool isHorizontal: panelPosition === "top" || panelPosition === "bottom"
    
    property color btnBg: (sharedData && sharedData.colorSecondary) ? sharedData.colorSecondary : "#1a1a1a"
    property color btnBgHover: (sharedData && sharedData.colorAccent) ? Qt.alpha(sharedData.colorAccent, 0.2) : "rgba(74, 158, 255, 0.2)"
    property color btnIcon: Qt.rgba(0.7, 0.7, 0.75, 1)
    property color btnIconHover: (sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff"
    
    anchors.left: panelPosition === "right" ? false : true
    anchors.right: panelPosition === "left" ? false : true
    anchors.top: panelPosition === "bottom" ? false : true
    anchors.bottom: panelPosition === "top" ? false : true
    
    function runAndRead(cmd, callback) {
        if (!sharedData || !sharedData.runCommand) return
        var tmp = "/tmp/qs_side_" + Math.random().toString(36).substring(7)
        sharedData.runCommand(['sh', '-c', cmd + " > " + tmp + " 2>/dev/null"], function() {
            var xhr = new XMLHttpRequest()
            xhr.open("GET", "file://" + tmp)
            xhr.onreadystatechange = function() {
                if (xhr.readyState === XMLHttpRequest.DONE) {
                    var out = (xhr.responseText || "").trim()
                    if (typeof callback === "function") callback(out)
                    sharedData.runCommand(['rm', '-f', tmp])
                }
            }
            xhr.send()
        })
    }
    
    // STABLE VISUAL SIDWBAR: Keep a fixed 33px width/height
    implicitWidth: !isHorizontal ? 33 : (screen ? screen.width : 2160)
    implicitHeight: isHorizontal ? 33 : (screen ? screen.height : 1440)
    width: implicitWidth
    height: implicitHeight
    color: "transparent"
    property var sharedData: null

    property bool panelActive: !!(sharedData && (sharedData.sidebarVisible === undefined || sharedData.sidebarVisible) && sharedData.sidebarPosition === panelPosition && !(sharedData.sidebarHiddenByFullscreen === true))
    property real panelProgress: panelActive ? 1.0 : 0.0
    Behavior on panelProgress {
        NumberAnimation { duration: 350; easing.type: Easing.OutBack }
    }
    visible: panelProgress > 0.01
    // Keep exclusiveZone strictly to the visible 33px
    exclusiveZone: panelProgress * 33

    property bool isPrimaryPanel: (primaryScreen === null || primaryScreen === undefined || (screen && primaryScreen && screen.name === primaryScreen.name)) && panelActive

    property bool timerRunning: false
    property int timerRemaining: 0
    property int timerDuration: 0
    
    function formatTime(sec) {
        var m = Math.floor(sec / 60)
        var s = sec % 60
        return (m < 10 ? "0" + m : m) + ":" + (s < 10 ? "0" + s : s)
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qssidepanel-" + (panelPosition || "left") + "-" + (screen && screen.name ? screen.name : "0")
    
    margins {
        left: 0
        top: 0
        bottom: 0
        right: 0
    }
    
    Rectangle {
        id: sidePanelRect
        // The actual visual sidebar stays at 33px
        width: !isHorizontal ? 33 : parent.width
        height: isHorizontal ? 33 : parent.height
        
        // Anchoring the visual part to the correct edge of the larger window
        anchors.left: panelPosition === "right" ? undefined : parent.left
        anchors.right: panelPosition === "right" ? parent.right : undefined
        anchors.top: panelPosition === "bottom" ? undefined : parent.top
        anchors.bottom: panelPosition === "bottom" ? parent.bottom : undefined

        gradient: Gradient {
            orientation: !isHorizontal ? Gradient.Vertical : Gradient.Horizontal
            GradientStop { position: 0.0; color: (sharedData && sharedData.colorBackground) ? sharedData.colorBackground : "#0d0d0d" }
            GradientStop { position: 1.0; color: (sharedData && sharedData.colorSecondary) ? sharedData.colorSecondary : "#151515" }
        }
        radius: 0
        enabled: false
        z: -1
        opacity: sidePanel.panelProgress
        Behavior on opacity { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }
        
        transform: Translate {
            // Translate the whole window - since it's transparent, it hides the sidebar
            x: panelPosition === "left" && !panelActive ? -220 : (panelPosition === "right" && !panelActive ? 220 : 0)
            y: panelPosition === "top" && !panelActive ? -220 : (panelPosition === "bottom" && !panelActive ? 220 : 0)
            Behavior on x { NumberAnimation { duration: 450; easing.type: Easing.OutCubic } }
            Behavior on y { NumberAnimation { duration: 450; easing.type: Easing.OutCubic } }
        }
    }

    Item {
        id: sidePanelContent
        // Anchor only to the visible sidebar area
        anchors.fill: sidePanelRect
        enabled: true
        z: 0
        clip: false
        
        Column {
            id: sidePanelClockColumn
            anchors.top: parent.top
            anchors.topMargin: 12
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: -6 // Very tight spacing for monolithic look
            visible: !isHorizontal
            opacity: (visible && panelActive) ? 1.0 : 0.0
            scale: panelActive ? 1.0 : 0.85
            
            Behavior on opacity { 
                SequentialAnimation { 
                    PauseAnimation { duration: 50 } 
                    NumberAnimation { duration: 500; easing.type: Easing.OutCubic } 
                } 
            }
            Behavior on scale { 
                SequentialAnimation { 
                    PauseAnimation { duration: 50 } 
                    NumberAnimation { duration: 600; easing.type: Easing.OutBack } 
                } 
            }
            transform: Translate {
                x: panelPosition === "left" && !panelActive ? -40 : (panelPosition === "right" && !panelActive ? 40 : 0)
                y: panelPosition === "top" && !panelActive ? -40 : (panelPosition === "bottom" && !panelActive ? 40 : 0)
                Behavior on x { 
                    SequentialAnimation { 
                        PauseAnimation { duration: 50 }
                        NumberAnimation { duration: 700; easing.type: Easing.OutBack } 
                    } 
                }
                Behavior on y { 
                    SequentialAnimation { 
                        PauseAnimation { duration: 50 }
                        NumberAnimation { duration: 700; easing.type: Easing.OutBack } 
                    } 
                }
            }
            Text { 
                id: sidePanelHoursDisplay
                text: "00"
                font.pixelSize: 24
                font.family: "Outfit, Inter, sans-serif"
                font.weight: Font.Black
                font.letterSpacing: -1.5
                color: (sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff"
                horizontalAlignment: Text.AlignHCenter
                Behavior on color { ColorAnimation { duration: 280; easing.type: Easing.OutQuart } } 
            }
            Text { 
                id: sidePanelMinutesDisplay
                text: "00"
                font.pixelSize: 24
                font.family: "Outfit, Inter, sans-serif"
                font.weight: Font.ExtraLight
                font.letterSpacing: -1.5
                color: "#ffffff"
                horizontalAlignment: Text.AlignHCenter
                opacity: 0.9
            }
        }
        
        Row {
            id: sidePanelClockRow
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2
            visible: isHorizontal
            opacity: (visible && panelActive) ? 1.0 : 0.0
            scale: panelActive ? 1.0 : 0.85
            
            Behavior on opacity { 
                SequentialAnimation { 
                    PauseAnimation { duration: 50 } 
                    NumberAnimation { duration: 500; easing.type: Easing.OutCubic } 
                } 
            }
            Behavior on scale { 
                SequentialAnimation { 
                    PauseAnimation { duration: 50 } 
                    NumberAnimation { duration: 600; easing.type: Easing.OutBack } 
                } 
            }
            transform: Translate {
                x: panelPosition === "left" && !panelActive ? -40 : (panelPosition === "right" && !panelActive ? 40 : 0)
                y: panelPosition === "top" && !panelActive ? -40 : (panelPosition === "bottom" && !panelActive ? 40 : 0)
                Behavior on x { 
                    SequentialAnimation { 
                        PauseAnimation { duration: 50 }
                        NumberAnimation { duration: 700; easing.type: Easing.OutBack } 
                    } 
                }
                Behavior on y { 
                    SequentialAnimation { 
                        PauseAnimation { duration: 50 }
                        NumberAnimation { duration: 700; easing.type: Easing.OutBack } 
                    } 
                }
            }
            Text { 
                id: sidePanelHoursDisplayTop
                text: "00"
                font.pixelSize: 22
                font.family: "Outfit, Inter, sans-serif"
                font.weight: Font.Black
                font.letterSpacing: -1
                color: (sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff"
                verticalAlignment: Text.AlignVCenter
                Behavior on color { ColorAnimation { duration: 280; easing.type: Easing.OutQuart } } 
            }
            Text { 
                id: sidePanelMinutesDisplayTop
                text: "00"
                font.pixelSize: 22
                font.family: "Outfit, Inter, sans-serif"
                font.weight: Font.ExtraLight
                font.letterSpacing: -1
                color: "#ffffff"
                verticalAlignment: Text.AlignVCenter
                opacity: 0.9
            }
        }
        
        Timer {
            id: sidePanelClockTimer
            interval: 1000
            repeat: true
            running: isPrimaryPanel
            onTriggered: { 
                var now = new Date()
                var hStr = now.getHours() < 10 ? "0" + now.getHours() : now.getHours().toString()
                var mStr = now.getMinutes() < 10 ? "0" + now.getMinutes() : now.getMinutes().toString()
                sidePanelHoursDisplay.text = hStr
                sidePanelMinutesDisplay.text = mStr
                sidePanelHoursDisplayTop.text = hStr
                sidePanelMinutesDisplayTop.text = mStr
            }
            Component.onCompleted: { 
                var now = new Date()
                var hStr = now.getHours() < 10 ? "0" + now.getHours() : now.getHours().toString()
                var mStr = now.getMinutes() < 10 ? "0" + now.getMinutes() : now.getMinutes().toString()
                sidePanelHoursDisplay.text = hStr
                sidePanelMinutesDisplay.text = mStr
                sidePanelHoursDisplayTop.text = hStr
                sidePanelMinutesDisplayTop.text = mStr
            }
        }
        
        Item {
            id: sidePanelWorkspaceColumnContainer
            width: parent.width
            height: parent.height
            visible: !isHorizontal
            anchors.centerIn: parent
            z: 50
            opacity: panelActive ? 1.0 : 0.0
            scale: panelActive ? 1.0 : 0.85
            Behavior on opacity { 
                SequentialAnimation { 
                    PauseAnimation { duration: 100 }
                    NumberAnimation { duration: 500; easing.type: Easing.OutCubic } 
                } 
            }
            Behavior on scale { 
                SequentialAnimation { 
                    PauseAnimation { duration: 100 }
                    NumberAnimation { duration: 600; easing.type: Easing.OutBack } 
                } 
            }
            transform: Translate { 
                x: panelPosition === "left" && !panelActive ? -40 : (panelPosition === "right" && !panelActive ? 40 : 0)
                Behavior on x { 
                    SequentialAnimation { 
                        PauseAnimation { duration: 100 }
                        NumberAnimation { duration: 700; easing.type: Easing.OutBack } 
                    } 
                } 
            }
            Column { 
                id: sidePanelWorkspaceColumn
                spacing: 12
                width: parent.width
                x: (parent.width - width) / 2
                y: (parent.height - height) / 2
                Repeater { 
                    model: 4
                    Item { 
                        id: workspaceItem
                        width: parent.width
                        height: workspaceLine.height
                        anchors.horizontalCenter: parent.horizontalCenter
                        property bool isActive: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id === (index + 1) : false
                        property bool hasWindows: { 
                            var ws = Hyprland.workspaces.values.find(w => w.id === (index + 1))
                            return ws ? ws.lastIpcObject.windows > 0 : false 
                        }
                        Rectangle { 
                            id: workspaceLine
                            anchors.centerIn: parent
                            width: 3
                            height: workspaceItem.isActive ? 64 : (workspaceItem.hasWindows ? 32 : 16)
                            radius: (sharedData && sharedData.quickshellBorderRadius) ? sharedData.quickshellBorderRadius : 0
                            color: workspaceItem.isActive ? (sharedData.colorAccent || "#4a9eff") : (workspaceItem.hasWindows ? "#fff" : "#666")
                            opacity: workspaceItem.isActive ? 1.0 : (workspaceItem.hasWindows ? 0.8 : 0.4)
                            Behavior on height { NumberAnimation { duration: 300; easing.type: Easing.OutBack } } 
                        }
                        MouseArea { 
                            anchors.fill: workspaceLine
                            anchors.margins: -5
                            onClicked: Hyprland.dispatch("workspace", index + 1) 
                        }
                    }
                }
            }
        }
        
        Item {
            id: sidePanelWorkspaceRowContainer
            width: parent.width
            height: parent.height
            visible: isHorizontal
            anchors.centerIn: parent
            z: 50
            Row { 
                id: sidePanelWorkspaceRow
                spacing: 12
                height: parent.height
                x: (parent.width - width) / 2
                y: (parent.height - height) / 2
                opacity: panelActive ? 1.0 : 0.0
                scale: panelActive ? 1.0 : 0.85
                transform: Translate { 
                    y: panelPosition === "top" && !panelActive ? -40 : (panelPosition === "bottom" && !panelActive ? 40 : 0)
                    Behavior on y { 
                        SequentialAnimation { 
                            PauseAnimation { duration: 100 }
                            NumberAnimation { duration: 700; easing.type: Easing.OutBack } 
                        } 
                    } 
                }
                Repeater { 
                    model: 4
                    Item { 
                        id: workspaceItemTop
                        height: parent.height
                        width: workspaceLineTop.width
                        anchors.verticalCenter: parent.verticalCenter
                        property bool isActive: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id === (index + 1) : false
                        property bool hasWindows: { 
                            var ws = Hyprland.workspaces.values.find(w => w.id === (index + 1))
                            return ws ? ws.lastIpcObject.windows > 0 : false 
                        }
                        Rectangle { 
                            id: workspaceLineTop
                            anchors.centerIn: parent
                            height: 3
                            width: workspaceItemTop.isActive ? 64 : (workspaceItemTop.hasWindows ? 32 : 16)
                            radius: (sharedData && sharedData.quickshellBorderRadius) ? sharedData.quickshellBorderRadius : 0
                            color: workspaceItemTop.isActive ? (sharedData.colorAccent || "#4a9eff") : (workspaceItemTop.hasWindows ? "#fff" : "#666")
                            opacity: workspaceItemTop.isActive ? 1.0 : (workspaceItemTop.hasWindows ? 0.8 : 0.4)
                            Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutBack } } 
                        }
                        MouseArea { 
                            anchors.fill: workspaceLineTop
                            anchors.margins: -5
                            onClicked: Hyprland.dispatch("workspace", index + 1) 
                        }
                    }
                }
            }
        }
    }

    Item {
        id: statusContainer
        z: 100000
        // Center relative to the visual sidebar (sidePanelRect)
        anchors.horizontalCenter: !isHorizontal ? sidePanelRect.horizontalCenter : undefined
        anchors.right: isHorizontal ? sidePanelRect.right : undefined
        anchors.rightMargin: isHorizontal ? 12 : 0
        anchors.verticalCenter: isHorizontal ? sidePanelRect.verticalCenter : undefined
        anchors.bottom: !isHorizontal ? sidePanelRect.bottom : undefined
        anchors.bottomMargin: !isHorizontal ? 2 : 0
        opacity: panelActive ? 1.0 : 0.0
        scale: panelActive ? 1.0 : 0.7
        Behavior on opacity { 
            SequentialAnimation { 
                PauseAnimation { duration: 200 }
                NumberAnimation { duration: 500; easing.type: Easing.OutCubic } 
            } 
        }
        Behavior on scale { 
            SequentialAnimation { 
                PauseAnimation { duration: 200 }
                NumberAnimation { duration: 600; easing.type: Easing.OutBack } 
            } 
        }
        transform: Translate {
            x: panelPosition === "left" && !panelActive ? -40 : (panelPosition === "right" && !panelActive ? 40 : 0)
            y: panelPosition === "top" && !panelActive ? -40 : (panelPosition === "bottom" && !panelActive ? 40 : 0)
            Behavior on x { 
                SequentialAnimation { 
                    PauseAnimation { duration: 200 }
                    NumberAnimation { duration: 700; easing.type: Easing.OutBack } 
                } 
            }
            Behavior on y { 
                SequentialAnimation { 
                    PauseAnimation { duration: 200 }
                    NumberAnimation { duration: 700; easing.type: Easing.OutBack } 
                } 
            }
        }

        Timer {
            id: statusRefreshTimer
            interval: 6000
            running: panelActive
            repeat: true
            triggeredOnStart: true
            onTriggered: {
                if (sharedData && sharedData.runCommand) {
                    var root = sidePanelRoot
                    sidePanelRoot.runAndRead('nmcli -t -f TYPE,NAME connection show --active | grep -E "^(802-11-wireless|ethernet)" | head -n 1 | cut -d: -f2-', function(out) { 
                        if (out !== undefined) root.qNetSSID = out.trim() 
                    })
                    sidePanelRoot.runAndRead('NW_IP=$(networkctl status 2>/dev/null | grep -i "Address:" | awk \'{print $2}\' | grep -v ":" | head -n1); [ -n "$NW_IP" ] && echo "$NW_IP" || ip -o -4 addr show scope global | awk \'{print $4}\' | cut -d/ -f1 | head -n1 || echo ""', function(out) { 
                        if (out !== undefined) root.qNetIP = out.trim() 
                    })
                    sidePanelRoot.runAndRead('nmcli networking connectivity', function(out) { 
                        if (out !== undefined) {
                            var status = out.trim();
                            if (status === "full") root.qNetStatus = "Online";
                            else if (status === "limited") root.qNetStatus = "Limited";
                            else if (status === "portal") root.qNetStatus = "Portal";
                            else root.qNetStatus = "Offline";
                        }
                    })
                    sidePanelRoot.runAndRead('bluetoothctl show | grep -q "Powered: yes" && echo "On" || echo "Off"', function(out) { 
                        if (out !== undefined) root.qBtStatus = out.trim() 
                    })
                    sidePanelRoot.runAndRead('bluetoothctl devices Connected | wc -l', function(out) { 
                        if (out !== undefined) root.qBtDevices = parseInt(out) || 0 
                    })
                    sidePanelRoot.runAndRead('powerprofilesctl get 2>/dev/null || echo "N/A"', function(out) { 
                        if (out !== undefined) root.qPwrStatus = (out.trim() && out.trim() !== "N/A") ? out.trim() : "Default" 
                    })
                    sidePanelRoot.runAndRead('B_CAP=$(cat /sys/class/power_supply/*/capacity 2>/dev/null | head -n1); [ -z "$B_CAP" ] && B_CAP=$(upower -i $(upower -e | grep BAT | head -n1) 2>/dev/null | grep percentage | awk \'{print $2}\' | tr -d "%"); [ -n "$B_CAP" ] && echo "$B_CAP" || echo 0', function(out) {
                        if (out !== undefined) {
                            var val = parseInt(out.trim())
                            root.qBatteryPct = isNaN(val) ? 0 : val
                        }
                    })
                    sidePanelRoot.runAndRead('B_STAT=$(cat /sys/class/power_supply/BAT*/status 2>/dev/null | head -n1); [ -z "$B_STAT" ] && B_STAT=$(cat /sys/class/power_supply/*/status 2>/dev/null | head -n1); [ -z "$B_STAT" ] && B_STAT=$(upower -i $(upower -e | grep BAT | head -n1) 2>/dev/null | grep state | awk \'{print $2}\'); [ -n "$B_STAT" ] && echo "$B_STAT" || echo "Unknown"', function(out) {
                        if (out !== undefined) root.qBatteryStatus = out.trim() || "Unknown"
                    })
                    sidePanelRoot.runAndRead('nmcli -f IN-USE,SIGNAL dev wifi | grep "*" | awk \'{print $2}\' || echo 0', function(out) {
                        if (out !== undefined) root.qNetSignal = parseInt(out.trim()) || 0
                    })
                    sidePanelRoot.runAndRead('nmcli -t -f SSID dev wifi | grep -v "^$" | head -n 4 | tr "\\n" ";"', function(out) {
                        if (out !== undefined) root.qNetNearby = out.trim()
                    })
                    sidePanelRoot.runAndRead('bluetoothctl devices Connected | cut -d" " -f3- | head -n 2 | tr "\\n" ";"', function(out) {
                        if (out !== undefined) root.qBtDeviceNames = out.trim()
                    })
                    sidePanelRoot.runAndRead('bluetoothctl devices | head -n 10 | while read -r line; do mac=$(echo $line | cut -d" " -f2); name=$(echo $line | cut -d" " -f3-); bluetoothctl info $mac | grep -q "Connected: yes" || echo "$mac|$name"; done | head -n 3 | tr "\\n" ";"', function(out) {
                        if (out !== undefined) {
                            var paired = out.trim()
                            root.qBtPaired = paired
                            // If the connecting MAC is no longer in the paired list (because it's connected), clear it
                            if (root.qBtConnectingMac !== "" && paired.indexOf(root.qBtConnectingMac) === -1) {
                                root.qBtConnectingMac = ""
                                btConnectTimeout.stop()
                            }
                        }
                    })
                }
            }
        }

        Timer {
            id: btConnectTimeout
            interval: 15000
            repeat: false
            onTriggered: sidePanel.qBtConnectingMac = ""
        }
    }

    // System Tray Delegate
    Component {
        id: trayItemDelegate
        Rectangle {
            width: 24
            height: 24
            radius: (sharedData && sharedData.quickshellBorderRadius) ? sharedData.quickshellBorderRadius : 6
            color: trayMa.containsMouse ? sidePanel.btnBgHover : "transparent"
            
            Image {
                anchors.fill: parent
                anchors.margins: 4
                source: modelData.icon
                fillMode: Image.PreserveAspectFit
                smooth: true
            }
            
            MouseArea {
                id: trayMa
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: (mouse) => {
                    if (mouse.button === Qt.RightButton) {
                        modelData.contextMenu()
                    } else {
                        modelData.activate()
                    }
                }
            }
        }
    }

    // Vertical System Tray
    Column {
        id: sidePanelTrayVertical
        anchors.bottom: actionsGroup.top
        anchors.bottomMargin: 8
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 4
        visible: !isHorizontal && SystemTray.items.count > 0
        
        Repeater {
            model: SystemTray.items
            delegate: trayItemDelegate
        }
    }

    // Horizontal System Tray
    Row {
        id: sidePanelTrayHorizontal
        anchors.right: actionsGroup.left
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4
        visible: isHorizontal && SystemTray.items.count > 0
        
        Repeater {
            model: SystemTray.items
            delegate: trayItemDelegate
        }
    }

    Rectangle {
        id: actionsGroup
        width: !isHorizontal ? sidePanelRect.width : actionsLayout.implicitWidth + 4
        height: isHorizontal ? sidePanelRect.height : actionsLayout.implicitHeight + 4
        // Always fill the sidebar width/height but keep tight margins
        anchors.left: !isHorizontal ? sidePanelRect.left : undefined
        anchors.right: !isHorizontal ? sidePanelRect.right : (isHorizontal ? statusContainer.left : undefined)
        anchors.top: isHorizontal ? sidePanelRect.top : undefined
        anchors.bottom: isHorizontal ? sidePanelRect.bottom : (!isHorizontal ? statusContainer.top : undefined)
        
        anchors.leftMargin: 1
        anchors.topMargin: 1
        anchors.rightMargin: 1
        anchors.bottomMargin: 1
        
        color: (sharedData && sharedData.colorPrimary) ? Qt.lighter(sharedData.colorPrimary, 1.2) : "#252525"
        border.width: 0
        radius: (sharedData && sharedData.quickshellBorderRadius) ? sharedData.quickshellBorderRadius : 0
        visible: panelActive
        z: 100001

        GridLayout {
            id: actionsLayout
            anchors.centerIn: parent
            columns: !isHorizontal ? 1 : 4
            rows: !isHorizontal ? 4 : 1
            columnSpacing: 2
            rowSpacing: 2
            
            QuickToggle {
                icon: "󰖩"
                sharedData: sidePanel.sharedData
                sidePanelRoot: sidePanel
                panelPosition: sidePanel.panelPosition
                outputScreen: sidePanel.screen
                showBackground: false
                Layout.alignment: Qt.AlignCenter
                Layout.preferredWidth: 26
                Layout.preferredHeight: 26
                onClicked: {
                    if (sharedData && sharedData.runCommand) {
                        sharedData.runCommand(['sh', '-c', 'nmcli radio wifi | grep -q enabled && nmcli radio wifi off || nmcli radio wifi on'])
                    }
                }
                popoverContent: Component {
                    Rectangle {
                        width: 240
                        height: 240
                        color: (sharedData.colorSecondary || "#141414")
                        radius: (sharedData && sharedData.quickshellBorderRadius) ? sharedData.quickshellBorderRadius : 10
                        
                        Column { 
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 12
                            
                            // Header
                            Column { 
                                spacing: 2
                                width: parent.width
                                Text { 
                                    text: "Network"
                                    color: (sharedData.colorAccent || "#4a9eff")
                                    font.pixelSize: 16
                                    font.weight: Font.ExtraBold
                                }
                                Text { 
                                    text: (sidePanel.qNetSSID && sidePanel.qNetSSID.length > 0) ? sidePanel.qNetSSID : "Disconnected"
                                    color: (sidePanel.qNetSSID && sidePanel.qNetSSID.length > 0) ? "#fff" : "#aaa"
                                    font.pixelSize: 12
                                    font.weight: Font.Medium
                                    elide: Text.ElideRight
                                    width: parent.width
                                }
                            }
                            
                            // Nearby Networks List
                            Column {
                                spacing: 6
                                width: parent.width
                                visible: sidePanel.qNetNearby.length > 0
                                
                                Text { 
                                    text: "NEARBY"; color: Qt.rgba(1,1,1,0.5); font.pixelSize: 10; font.weight: Font.Bold; font.letterSpacing: 1.2 
                                }
                                
                                Column {
                                    width: parent.width; spacing: 4
                                    Repeater {
                                        model: sidePanel.qNetNearby.split(";").filter(s => s.length > 0 && s !== sidePanel.qNetSSID).slice(0, 3)
                                        Rectangle {
                                            width: parent.width; height: 24
                                            radius: (sharedData && sharedData.quickshellBorderRadius) ? Math.min(sharedData.quickshellBorderRadius, 8) : 4
                                            color: netItemMa.containsMouse ? Qt.rgba(1,1,1,0.1) : Qt.rgba(1,1,1,0.03)
                                            Row {
                                                anchors.fill: parent; anchors.leftMargin: 4; anchors.rightMargin: 4
                                                spacing: 8
                                                Text { text: "󰖩"; color: (sharedData.colorAccent || "#4a9eff"); font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
                                                Text { text: modelData; color: "#fff"; font.pixelSize: 11; elide: Text.ElideRight; width: parent.width - 24; anchors.verticalCenter: parent.verticalCenter; font.weight: Font.Medium }
                                            }
                                            MouseArea { id: netItemMa; anchors.fill: parent; hoverEnabled: true }
                                        }
                                    }
                                }
                            }
                            
                            // Actions Grid
                            GridLayout {
                                columns: 2; rowSpacing: 6; columnSpacing: 6; width: parent.width
                                
                                // Toggle Button
                                Rectangle {
                                    Layout.fillWidth: true; height: 32
                                    color: netToggleMa.containsMouse ? Qt.rgba(1,1,1,0.1) : Qt.rgba(1,1,1,0.05)
                                    radius: (sharedData && sharedData.quickshellBorderRadius) ? sharedData.quickshellBorderRadius : 10
                                    border.width: 1; border.color: Qt.rgba(1,1,1,0.05)
                                    
                                    Row {
                                        anchors.centerIn: parent; spacing: 6
                                        Text { text: "󰖩"; color: (sharedData.colorAccent || "#4a9eff"); font.pixelSize: 12 }
                                        Text { text: "Toggle"; color: "#fff"; font.pixelSize: 11; font.weight: Font.Medium }
                                    }
                                    MouseArea { 
                                        id: netToggleMa; anchors.fill: parent; hoverEnabled: true
                                        onClicked: {
                                            sharedData.runCommand(['sh', '-c', 'nmcli radio wifi | grep -q enabled && nmcli radio wifi off || nmcli radio wifi on'])
                                        }
                                    }
                                }
                                
                                // Scan Button
                                Rectangle {
                                    Layout.fillWidth: true; height: 32
                                    color: netScanMa.containsMouse ? Qt.rgba(1,1,1,0.1) : Qt.rgba(1,1,1,0.05)
                                    radius: (sharedData && sharedData.quickshellBorderRadius) ? sharedData.quickshellBorderRadius : 10
                                    border.width: 1; border.color: Qt.rgba(1,1,1,0.05)
                                    
                                    Row {
                                        anchors.centerIn: parent; spacing: 6
                                        Text { text: "󰱔"; color: (sharedData.colorAccent || "#4a9eff"); font.pixelSize: 12 }
                                        Text { text: "Scan"; color: "#fff"; font.pixelSize: 11; font.weight: Font.Medium }
                                    }
                                    MouseArea { 
                                        id: netScanMa; anchors.fill: parent; hoverEnabled: true
                                        onClicked: sharedData.runCommand(['sh', '-c', 'nmcli dev wifi rescan'])
                                    }
                                }
                                
                                // Settings Button (Full Width)
                                Rectangle {
                                    Layout.columnSpan: 2; Layout.fillWidth: true; height: 32
                                    color: netSetMa.containsMouse ? Qt.rgba(1,1,1,0.1) : Qt.rgba(1,1,1,0.05)
                                    radius: (sharedData && sharedData.quickshellBorderRadius) ? sharedData.quickshellBorderRadius : 10
                                    border.width: 1; border.color: Qt.rgba(1,1,1,0.05)
                                    
                                    Row {
                                        anchors.centerIn: parent; spacing: 6
                                        Text { text: "󰒓"; color: "#aaa"; font.pixelSize: 12 }
                                        Text { text: "Network Settings"; color: "#fff"; font.pixelSize: 11; font.weight: Font.Medium }
                                    }
                                    MouseArea { 
                                        id: netSetMa; anchors.fill: parent; hoverEnabled: true
                                        onClicked: sharedData.runCommand(['nm-connection-editor'])
                                    }
                                }
                            }
                        }
                    }
                }
            }

            QuickToggle {
                icon: "󰂯"
                sharedData: sidePanel.sharedData
                sidePanelRoot: sidePanel
                panelPosition: sidePanel.panelPosition
                outputScreen: sidePanel.screen
                showBackground: false
                Layout.alignment: Qt.AlignCenter
                Layout.preferredWidth: 26
                Layout.preferredHeight: 26
                onClicked: {
                    if (sharedData && sharedData.runCommand) {
                        var cmd = (sidePanel.qBtStatus === "On") ? 'bluetoothctl power off' : 'bluetoothctl power on'
                        sharedData.runCommand(['sh', '-c', cmd])
                    }
                }
                popoverContent: Component {
                    Rectangle {
                        id: btPopover
                        width: 240
                        height: 240
                        color: (sharedData.colorSecondary || "#141414")
                        radius: (sharedData && sharedData.quickshellBorderRadius) ? sharedData.quickshellBorderRadius : 16
                        
                        scale: 0.95 + (0.05 * (typeof popoverWindow !== "undefined" ? popoverWindow.showProgress : 1.0))
                        Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }
                        
                        Column { 
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 12
                            
                            // Header
                            Column { 
                                spacing: 2
                                width: parent.width
                                Row {
                                    spacing: 6
                                    Text { 
                                        text: "Bluetooth"
                                        color: (sharedData.colorAccent || "#4a9eff")
                                        font.pixelSize: 16
                                        font.weight: Font.ExtraBold
                                    }
                                    Rectangle {
                                        width: 8; height: 8; radius: 4
                                        color: sidePanel.qBtStatus === "On" ? "#00ff41" : "#ff4444"
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }
                                Text { 
                                    text: sidePanel.qBtDevices > 0 ? (sidePanel.qBtDevices + " device(s) connected") : "No devices connected"
                                    color: sidePanel.qBtDevices > 0 ? "#fff" : "#aaa"
                                    font.pixelSize: 12
                                    font.weight: Font.Medium
                                }
                            }
                            
                            // Connected devices
                            Column {
                                spacing: 6; width: parent.width
                                visible: sidePanel.qBtDeviceNames.length > 0
                                Text { text: "CONNECTED"; color: Qt.rgba(1,1,1,0.5); font.pixelSize: 10; font.weight: Font.Bold; font.letterSpacing: 1.2 }
                                Column {
                                    width: parent.width; spacing: 4
                                    Repeater {
                                        model: sidePanel.qBtDeviceNames.split(";").filter(s => s.length > 0).slice(0, 2)
                                        Rectangle {
                                            width: parent.width; height: 24
                                            radius: (sharedData && sharedData.quickshellBorderRadius) ? Math.min(sharedData.quickshellBorderRadius, 8) : 4
                                            color: Qt.rgba(1,1,1,0.05) // Highlight connected
                                            Row {
                                                anchors.fill: parent; anchors.leftMargin: 4; anchors.rightMargin: 4
                                                spacing: 8
                                                Text { text: "󰂯"; color: (sharedData.colorAccent || "#4a9eff"); font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
                                                Text { text: modelData; color: "#fff"; font.pixelSize: 11; elide: Text.ElideRight; width: parent.width - 24; anchors.verticalCenter: parent.verticalCenter; font.bold: true }
                                            }
                                        }
                                    }
                                }
                            }
                            
                            // Paired devices (disconnected)
                            Column {
                                spacing: 6; width: parent.width
                                visible: sidePanel.qBtPaired.length > 0
                                Text { text: "PAIRED"; color: Qt.rgba(1,1,1,0.5); font.pixelSize: 10; font.weight: Font.Bold; font.letterSpacing: 1.2 }
                                Column {
                                    width: parent.width; spacing: 4
                                    Repeater {
                                        model: sidePanel.qBtPaired.split(";").filter(s => s.length > 0)
                                        Rectangle {
                                            width: parent.width; height: 32
                                            radius: (sharedData && sharedData.quickshellBorderRadius) ? Math.min(sharedData.quickshellBorderRadius, 8) : 4
                                            color: pairMa.containsMouse ? Qt.rgba(1,1,1,0.1) : Qt.rgba(1,1,1,0.03)
                                            
                                            property string mac: modelData.indexOf("|") !== -1 ? modelData.split("|")[0] : ""
                                            property string deviceName: modelData.indexOf("|") !== -1 ? modelData.split("|")[1] : modelData
                                            
                                            Row {
                                                anchors.fill: parent; anchors.leftMargin: 8; anchors.rightMargin: 8
                                                spacing: 8
                                                Text { text: "󰂯"; color: "#aaa"; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
                                                Text { 
                                                    text: parent.parent.deviceName
                                                    color: "#ddd"; font.pixelSize: 11; elide: Text.ElideRight
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    width: parent.width - 80 
                                                }
                                                
                                                Rectangle {
                                                    width: 60; height: 20; radius: 10
                                                    color: (sharedData.colorAccent || "#4a9eff")
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    Text { anchors.centerIn: parent; text: "Connect"; color: "#141414"; font.pixelSize: 10; font.weight: Font.Bold }
                                                    MouseArea {
                                                        anchors.fill: parent
                                                        onClicked: {
                                                            if (parent.parent.parent.mac !== "") {
                                                                sidePanel.qBtConnectingMac = parent.parent.parent.mac
                                                                sharedData.runCommand(['bluetoothctl', 'connect', parent.parent.parent.mac])
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                            MouseArea { id: pairMa; anchors.fill: parent; hoverEnabled: true; acceptedButtons: Qt.NoButton }
                                        }
                                    }
                                }
                            }

                            // Manager
                            Rectangle {
                                width: parent.width; height: 32
                                color: btMgrMa.containsMouse ? Qt.rgba(1,1,1,0.1) : Qt.rgba(1,1,1,0.05)
                                radius: (sharedData && sharedData.quickshellBorderRadius) ? sharedData.quickshellBorderRadius : 10
                                border.width: 1; border.color: Qt.rgba(1,1,1,0.05)
                                
                                Row {
                                    anchors.centerIn: parent; spacing: 6
                                    Text { text: "󰒓"; color: "#aaa"; font.pixelSize: 12 }
                                    Text { text: "Bluetooth Manager"; color: "#fff"; font.pixelSize: 11; font.weight: Font.Medium }
                                }
                                MouseArea { 
                                    id: btMgrMa; anchors.fill: parent; hoverEnabled: true
                                    onClicked: sharedData.runCommand(['blueman-manager'])
                                }
                            }
                        }
                    }
                }
            }

            QuickToggle {
                icon: "󰓅"
                sharedData: sidePanel.sharedData
                sidePanelRoot: sidePanel
                panelPosition: sidePanel.panelPosition
                outputScreen: sidePanel.screen
                showBackground: false
                Layout.alignment: Qt.AlignCenter
                Layout.preferredWidth: 26
                Layout.preferredHeight: 26
                onClicked: {
                    if (sharedData && sharedData.runCommand) {
                        // Cycle through power profiles: power-saver -> balanced -> performance -> power-saver
                        var currentProfile = sidePanel.qPwrStatus.toLowerCase()
                        var nextProfile = "balanced"
                        if (currentProfile.includes("power-saver")) nextProfile = "balanced"
                        else if (currentProfile.includes("balanced")) nextProfile = "performance"
                        else if (currentProfile.includes("performance")) nextProfile = "power-saver"
                        sharedData.runCommand(['powerprofilesctl', 'set', nextProfile])
                    }
                }
                popoverContent: Component {
                    Rectangle {
                        id: powerPopover
                        width: 240
                        height: 240
                        color: (sharedData.colorSecondary || "#141414")
                        radius: (sharedData && sharedData.quickshellBorderRadius) ? sharedData.quickshellBorderRadius : 16
                        
                        scale: 0.95 + (0.05 * (typeof popoverWindow !== "undefined" ? popoverWindow.showProgress : 1.0))
                        Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }
                        
                        Column { 
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 12
                            
                            // Header
                            Column { 
                                spacing: 2
                                width: parent.width
                                Text { 
                                    text: "Power"
                                    color: (sharedData.colorAccent || "#4a9eff")
                                    font.pixelSize: 16
                                    font.weight: Font.ExtraBold
                                }
                                Text { 
                                    text: sharedData.activePowerProfile ? sharedData.activePowerProfile.charAt(0).toUpperCase() + sharedData.activePowerProfile.slice(1) : "Unknown Profile"
                                    color: "#fff"
                                    font.pixelSize: 12
                                    font.weight: Font.Medium
                                    opacity: 0.7
                                }
                            }
                            
                            // Profiles
                            Column {
                                spacing: 6; width: parent.width
                                Text { text: "PERFORMANCE MODE"; color: Qt.rgba(1,1,1,0.5); font.pixelSize: 10; font.weight: Font.Bold; font.letterSpacing: 1.2 }
                                
                                Column {
                                    width: parent.width; spacing: 4
                                    Repeater {
                                        model: ["power-saver", "balanced", "performance"]
                                        Rectangle {
                                            width: parent.width; height: 32
                                            radius: (sharedData && sharedData.quickshellBorderRadius) ? sharedData.quickshellBorderRadius : 10
                                            property bool isActive: sharedData.activePowerProfile === modelData
                                            color: isActive ? (sharedData.colorAccent || "#4a9eff") : (profMa.containsMouse ? Qt.rgba(1,1,1,0.1) : "transparent")
                                            border.width: isActive ? 0 : 1
                                            border.color: Qt.rgba(1,1,1,0.05)
                                            
                                            Behavior on color { ColorAnimation { duration: 150 } }
                                            
                                            Row {
                                                anchors.centerIn: parent; spacing: 8
                                                Text { 
                                                    text: modelData === "mic" ? "󰍬" : (modelData === "performance" ? "󰓅" : (modelData === "power-saver" ? "󰾆" : "󰾅"))
                                                    color: isActive ? "#000" : "#fff"
                                                    font.pixelSize: 14
                                                }
                                                Text { 
                                                    text: modelData.charAt(0).toUpperCase() + modelData.slice(1)
                                                    color: isActive ? "#000" : "#fff"
                                                    font.pixelSize: 11
                                                    font.weight: Font.Medium
                                                }
                                            }
                                            MouseArea { 
                                                id: profMa; anchors.fill: parent; hoverEnabled: true
                                                onClicked: sharedData.runCommand(['powerprofilesctl', 'set', modelData])
                                            }
                                        }
                                    }
                                }
                            }
                            
                            // System Actions
                            Row {
                                width: parent.width; spacing: 8
                                
                                Rectangle {
                                    width: (parent.width - 8) / 2; height: 32
                                    color: rbMa.containsMouse ? Qt.rgba(1,1,1,0.1) : Qt.rgba(1,1,1,0.05)
                                    radius: (sharedData && sharedData.quickshellBorderRadius) ? sharedData.quickshellBorderRadius : 10
                                    border.width: 1; border.color: Qt.rgba(1,1,1,0.05)
                                    
                                    Row {
                                        anchors.centerIn: parent; spacing: 6
                                        Text { text: "󰜉"; color: "#fff"; font.pixelSize: 14 }
                                        Text { text: "Reboot"; color: "#fff"; font.pixelSize: 11; font.weight: Font.Medium }
                                    }
                                    MouseArea { 
                                        id: rbMa; anchors.fill: parent; hoverEnabled: true
                                        onClicked: sharedData.runCommand(['systemctl', 'reboot'])
                                    }
                                }
                                
                                Rectangle {
                                    width: (parent.width - 8) / 2; height: 32
                                    color: sdMa.containsMouse ? "#ff4444" : Qt.rgba(1,0,0,0.1)
                                    radius: (sharedData && sharedData.quickshellBorderRadius) ? sharedData.quickshellBorderRadius : 10
                                    border.width: 1; border.color: Qt.rgba(1,0,0,0.2)
                                    
                                    Row {
                                        anchors.centerIn: parent; spacing: 6
                                        Text { text: "󰐥"; color: sdMa.containsMouse ? "#000" : "#ff4444"; font.pixelSize: 14 }
                                        Text { text: "OFF"; color: sdMa.containsMouse ? "#000" : "#ff4444"; font.pixelSize: 11; font.weight: Font.Bold }
                                    }
                                    MouseArea { 
                                        id: sdMa; anchors.fill: parent; hoverEnabled: true
                                        onClicked: sharedData.runCommand(['systemctl', 'poweroff'])
                                    }
                                }
                            }
                        }
                    }
                }
            }

            QuickToggle {
                icon: "󰔛"
                sharedData: sidePanel.sharedData
                sidePanelRoot: sidePanel
                panelPosition: sidePanel.panelPosition
                outputScreen: sidePanel.screen
                showBackground: false
                Layout.alignment: Qt.AlignCenter
                Layout.preferredWidth: 26
                Layout.preferredHeight: 26
                onClicked: {
                    // For now, toggle 5m timer as default or do nothing?
                    // Just let hover handle the menu
                }
                popoverContent: Component {
                    Rectangle {
                        width: 240
                        height: 260 // Increased height for Timer UI
                        color: (sharedData.colorSecondary || "#141414")
                        radius: (sharedData && sharedData.quickshellBorderRadius) ? sharedData.quickshellBorderRadius : 10
                        
                        Column { 
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 12
                            
                            // Header
                            Column { 
                                spacing: 2
                                width: parent.width
                                Text { 
                                    text: "Timer"
                                    color: (sharedData.colorAccent || "#4a9eff")
                                    font.pixelSize: 16
                                    font.weight: Font.ExtraBold
                                }
                                Text { 
                                    text: sidePanel.timerRunning ? sidePanel.formatTime(sidePanel.timerRemaining) : "No active timer"
                                    color: sidePanel.timerRunning ? "#fff" : "#aaa"
                                    font.pixelSize: sidePanel.timerRunning ? 14 : 12
                                    font.weight: sidePanel.timerRunning ? Font.Bold : Font.Medium
                                    opacity: sidePanel.timerRunning ? 1.0 : 0.7
                                }
                                
                                // Progress Bar
                                Rectangle {
                                    width: parent.width; height: 4
                                    color: Qt.rgba(1,1,1,0.1)
                                    radius: (sharedData && sharedData.quickshellBorderRadius > 0) ? 2 : 0
                                    visible: sidePanel.timerRunning
                                    Rectangle {
                                        height: parent.height
                                        radius: (sharedData && sharedData.quickshellBorderRadius > 0) ? 2 : 0
                                        width: sidePanel.timerDuration > 0 ? (parent.width * (sidePanel.timerRemaining / sidePanel.timerDuration)) : 0
                                        color: (sharedData.colorAccent || "#4a9eff")
                                        Behavior on width { NumberAnimation { duration: 1000 } }
                                    }
                                }
                            }
                            
                            // Timer Presets
                            Column {
                                spacing: 6; width: parent.width
                                Text { text: "QUICK SET"; color: Qt.rgba(1,1,1,0.5); font.pixelSize: 10; font.weight: Font.Bold; font.letterSpacing: 1.2 }
                                
                                GridLayout {
                                    columns: 2
                                    rowSpacing: 6
                                    columnSpacing: 6
                                    width: parent.width
                                    
                                    Repeater {
                                        model: [
                                            { label: "5m", sec: 300 },
                                            { label: "15m", sec: 900 },
                                            { label: "30m", sec: 1800 },
                                            { label: "1h", sec: 3600 }
                                        ]
                                        Rectangle {
                                            Layout.fillWidth: true
                                            height: 32
                                            color: timerBtnMa.containsMouse ? Qt.rgba(1,1,1,0.1) : Qt.rgba(1,1,1,0.05)
                                            radius: (sharedData && sharedData.quickshellBorderRadius) ? sharedData.quickshellBorderRadius : 10
                                            border.width: 1; border.color: Qt.rgba(1,1,1,0.05)
                                            scale: timerBtnMa.pressed ? 0.95 : (timerBtnMa.containsMouse ? 1.02 : 1.0)
                                            
                                            Behavior on color { ColorAnimation { duration: 150 } }
                                            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
                                            
                                            Text { 
                                                anchors.centerIn: parent
                                                text: modelData.label
                                                color: "#fff"
                                                font.pixelSize: 11
                                                font.weight: Font.Medium
                                            }
                                            
                                            MouseArea {
                                                id: timerBtnMa
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                onClicked: {
                                                    sidePanel.timerDuration = modelData.sec
                                                    sidePanel.timerRemaining = modelData.sec
                                                    sidePanel.timerRunning = true
                                                    if (sharedData && sharedData.runCommand) {
                                                        sharedData.runCommand(['notify-send', '-i', 'alarm-clock', 'Timer Set', 'Timer for ' + modelData.label + ' started'])
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            
                            // Stop Button
                            Rectangle {
                                width: parent.width
                                height: 32
                                color: stopTimerMa.containsMouse ? "#ff4444" : Qt.rgba(1,0,0,0.1)
                                radius: (sharedData && sharedData.quickshellBorderRadius) ? sharedData.quickshellBorderRadius : 10
                                border.width: 1; border.color: Qt.rgba(1,0,0,0.2)
                                scale: stopTimerMa.pressed ? 0.95 : (stopTimerMa.containsMouse ? 1.02 : 1.0)
                                
                                Behavior on color { ColorAnimation { duration: 150 } }
                                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
                                
                                Row {
                                    anchors.centerIn: parent; spacing: 6
                                    Text { text: "󰅙"; color: stopTimerMa.containsMouse ? "#000" : "#ff4444"; font.pixelSize: 14 }
                                    Text { text: "Stop / Clear"; color: stopTimerMa.containsMouse ? "#000" : "#ff4444"; font.pixelSize: 11; font.weight: Font.Bold }
                                }
                                
                                MouseArea {
                                    id: stopTimerMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: {
                                        sidePanel.timerRunning = false
                                        sidePanel.timerRemaining = 0
                                        if (sharedData && sharedData.runCommand) {
                                            sharedData.runCommand(['notify-send', '-i', 'alarm-clock', 'Timer Stopped', 'Active timer cancelled'])
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
    
    property var launcherFunction
    property var screenshotFunction
    
    // Reference for QuickToggle popovers
    property Item popoverParent: null
    
    // Standalone Popover Window
    PanelWindow {
        id: popoverWindow
        screen: sidePanel.screen
        
        // Use anchors + margins for reliable positioning in Layershell
        anchors.left: true
        anchors.top: true
        
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "qssidepanel-popover"
        
        implicitWidth: 240
        implicitHeight: 240
        width: 240
        height: 240
        color: "transparent"
        
        
        property Component content: null
        property int activeLoader: 1
        property bool isHovered: popoverMouseArea.containsMouse
        property real showProgress: 0.0
        property bool shouldShow: false
        
        onContentChanged: {
            if (content !== null) {
                shouldShow = true
                if (showProgress > 0) {
                    // Transition between menus
                    if (activeLoader === 1 && popoverLoader1.sourceComponent !== content) {
                        popoverLoader2.sourceComponent = content
                        activeLoader = 2
                    } else if (activeLoader === 2 && popoverLoader2.sourceComponent !== content) {
                        popoverLoader1.sourceComponent = content
                        activeLoader = 1
                    }
                } else {
                    // Initial opening
                    popoverLoader1.sourceComponent = content
                    activeLoader = 1
                }
            } else {
                shouldShow = false
            }
        }

        onShouldShowChanged: {
            if (shouldShow) {
                showProgress = 1.0
                contentCleanupTimer.stop()
            } else {
                showProgress = 0.0
                contentCleanupTimer.restart()
            }
        }
        
        Behavior on showProgress { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
        
        visible: showProgress > 0.01 || content !== null
        
        onIsHoveredChanged: {
            if (!isHovered && !sidePanel.isAnyToggleHovered) {
                hideTimer.restart()
            } else {
                hideTimer.stop()
            }
        }

        // Internal container to handle opacity and animations since Window doesn't have it
        Item {
            anchors.fill: parent
            opacity: popoverWindow.showProgress
            Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
            
            transform: [
                Translate {
                    // Slide in from the sidebar edge
                    x: !isHorizontal ? (panelPosition === "right" ? (1.0 - popoverWindow.showProgress) * 80 : (popoverWindow.showProgress - 1.0) * 80) : 0
                    y: isHorizontal ? (panelPosition === "bottom" ? (1.0 - popoverWindow.showProgress) * 80 : (popoverWindow.showProgress - 1.0) * 80) : 0
                    Behavior on x { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                    Behavior on y { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                }
            ]
            
            Loader {
                id: popoverLoader1
                anchors.fill: parent
                opacity: popoverWindow.activeLoader === 1 ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                onOpacityChanged: if (opacity === 0 && popoverWindow.activeLoader !== 1) sourceComponent = null
            }

            Loader {
                id: popoverLoader2
                anchors.fill: parent
                opacity: popoverWindow.activeLoader === 2 ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                onOpacityChanged: if (opacity === 0 && popoverWindow.activeLoader !== 2) sourceComponent = null
            }
            
            MouseArea {
                id: popoverMouseArea
                anchors.fill: parent
                hoverEnabled: true
                // We want to detect hover but let clicks pass through to the loader content
                acceptedButtons: Qt.NoButton
            }
        }
        
        Timer {
            id: contentCleanupTimer
            interval: 350
            onTriggered: {
                if (!popoverWindow.shouldShow) {
                    popoverLoader1.sourceComponent = null
                    popoverLoader2.sourceComponent = null
                    popoverWindow.activeLoader = 1
                }
            }
        }
        
        Timer {
            id: hideTimer
            interval: 300
            onTriggered: popoverWindow.content = null
        }
    }

    property bool isAnyToggleHovered: false

    function showPopover(content, targetX, targetY) {
        if (content) {
            hideTimer.stop()
            popoverWindow.content = content
            
            // Re-reset anchors
            popoverWindow.anchors.left = false
            popoverWindow.anchors.right = false
            popoverWindow.anchors.top = false
            popoverWindow.anchors.bottom = false
            
            // Since SidePanel has an exclusiveZone of 33, 
            // other LayerShell windows anchored to the same edge will start AFTER that zone.
            if (!isHorizontal) {
                // Fixed position at the bottom of the sidebar
                popoverWindow.anchors.bottom = true
                popoverWindow.margins.bottom = -1 // Flush with edge
                
                if (panelPosition === "right") {
                    popoverWindow.anchors.right = true
                    popoverWindow.margins.right = -2
                } else {
                    popoverWindow.anchors.left = true
                    popoverWindow.margins.left = -2
                }
            } else {
                // Fixed position at the right-most edge for horizontal bars
                popoverWindow.anchors.right = true
                popoverWindow.margins.right = -1
                
                if (panelPosition === "bottom") {
                    popoverWindow.anchors.bottom = true
                    popoverWindow.margins.bottom = -2
                } else {
                    popoverWindow.anchors.top = true
                    popoverWindow.margins.top = -2
                }
            }
        } else {
            if (!popoverWindow.isHovered) {
                hideTimer.restart()
            }
        }
    }
    Timer {
        id: activeTimer
        interval: 1000
        repeat: true
        running: sidePanel.timerRunning && sidePanel.timerRemaining > 0
        onTriggered: {
            sidePanel.timerRemaining -= 1
            if (sidePanel.timerRemaining <= 0) {
                sidePanel.timerRunning = false
                if (sharedData && sharedData.runCommand) {
                    sharedData.runCommand(['notify-send', '-i', 'alarm-clock', '-u', 'critical', 'Timer Finished', 'Time is up!'])
                }
            }
        }
    }
}

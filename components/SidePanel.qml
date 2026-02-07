import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
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
            anchors.topMargin: 6
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 4
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
                font.pixelSize: 26
                font.family: "sans-serif"
                font.weight: Font.Black
                color: (sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff"
                horizontalAlignment: Text.AlignHCenter
                Behavior on color { ColorAnimation { duration: 280; easing.type: Easing.OutQuart } } 
            }
            Text { 
                id: sidePanelMinutesDisplay
                text: "00"
                font.pixelSize: 26
                font.family: "sans-serif"
                font.weight: Font.Black
                color: (sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff"
                horizontalAlignment: Text.AlignHCenter
                Behavior on color { ColorAnimation { duration: 280; easing.type: Easing.OutQuart } } 
            }
        }
        
        Row {
            id: sidePanelClockRow
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4
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
                font.pixelSize: 24
                font.family: "sans-serif"
                font.weight: Font.Black
                color: (sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff"
                verticalAlignment: Text.AlignVCenter
                Behavior on color { ColorAnimation { duration: 280; easing.type: Easing.OutQuart } } 
            }
            Text { 
                text: ":"
                font.pixelSize: 24
                font.family: "sans-serif"
                font.weight: Font.Black
                color: (sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff"
                verticalAlignment: Text.AlignVCenter 
            }
            Text { 
                id: sidePanelMinutesDisplayTop
                text: "00"
                font.pixelSize: 24
                font.family: "sans-serif"
                font.weight: Font.Black
                color: (sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff"
                verticalAlignment: Text.AlignVCenter
                Behavior on color { ColorAnimation { duration: 280; easing.type: Easing.OutQuart } } 
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
            interval: 2000
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
                        if (out !== undefined) root.qBtPaired = out.trim()
                    })
                }
            }
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
                panelPosition: sidePanel.panelPosition
                screen: sidePanel.screen
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
                        width: 180
                        height: 190
                        color: (sharedData.colorBackground || "#0d0d0d")
                        radius: (sharedData && sharedData.quickshellBorderRadius) ? sharedData.quickshellBorderRadius : 0
                        Column { 
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 12
                            Column { 
                                spacing: 3
                                width: parent.width
                                Text { 
                                    text: "󰖩 Network"
                                    color: (sharedData.colorAccent || "#4a9eff")
                                    font.pixelSize: 15
                                    font.weight: Font.ExtraBold
                                }
                                Text { 
                                    text: (sidePanel.qNetSSID && sidePanel.qNetSSID.length > 0) ? sidePanel.qNetSSID : "Not connected"
                                    color: "#fff"
                                    font.pixelSize: 12
                                    font.weight: Font.Medium
                                    elide: Text.ElideRight
                                    width: parent.width
                                }
                            }
                            
                            Column {
                                spacing: 4
                                width: parent.width
                                visible: sidePanel.qNetNearby.length > 0
                                Text { text: "NEARBY"; color: "#666"; font.pixelSize: 10; font.weight: Font.Bold; font.letterSpacing: 1 }
                                Flow {
                                    width: parent.width; spacing: 4
                                    Repeater {
                                        model: sidePanel.qNetNearby.split(";").filter(s => s.length > 0 && s !== sidePanel.qNetSSID).slice(0, 3)
                                        Rectangle {
                                            width: Math.min(60, nl.implicitWidth + 8); height: 18; color: "#1a1a1a"; radius: 2
                                            Text { id: nl; anchors.centerIn: parent; text: modelData; color: "#aaa"; font.pixelSize: 8; elide: Text.ElideRight; width: parent.width - 4 }
                                        }
                                    }
                                }
                            }

                            GridLayout {
                                columns: 2; rowSpacing: 4; columnSpacing: 4; width: parent.width
                                Rectangle {
                                    Layout.fillWidth: true; height: 30; color: netMa1.containsMouse ? Qt.rgba(1,1,1,0.1) : Qt.rgba(1,1,1,0.05); radius: 3
                                    Text { anchors.centerIn: parent; text: "󰖩 Toggle"; color: "#fff"; font.pixelSize: 10; font.weight: Font.Medium }
                                    MouseArea { id: netMa1; anchors.fill: parent; hoverEnabled: true; onClicked: sharedData.runCommand(['sh', '-c', 'nmcli radio wifi | grep -q enabled && nmcli radio wifi off || nmcli radio wifi on']) }
                                }
                                Rectangle {
                                    Layout.fillWidth: true; height: 30; color: netMa2.containsMouse ? Qt.rgba(1,1,1,0.1) : Qt.rgba(1,1,1,0.05); radius: 3
                                    Text { anchors.centerIn: parent; text: "󰱔 Scan"; color: "#fff"; font.pixelSize: 10; font.weight: Font.Medium }
                                    MouseArea { id: netMa2; anchors.fill: parent; hoverEnabled: true; onClicked: sharedData.runCommand(['sh', '-c', 'nmcli dev wifi rescan']) }
                                }
                                Rectangle {
                                    Layout.columnSpan: 2; Layout.fillWidth: true; height: 30; color: netMa3.containsMouse ? Qt.rgba(1,1,1,0.1) : Qt.rgba(1,1,1,0.05); radius: 3
                                    Text { anchors.centerIn: parent; text: "󰒓 Settings"; color: "#fff"; font.pixelSize: 10; font.weight: Font.Medium }
                                    MouseArea { id: netMa3; anchors.fill: parent; hoverEnabled: true; onClicked: sharedData.runCommand(['nm-connection-editor']) }
                                }
                            }
                        }
                    }
                }
            }

            QuickToggle {
                icon: "󰂯"
                sharedData: sidePanel.sharedData
                panelPosition: sidePanel.panelPosition
                screen: sidePanel.screen
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
                        width: 180
                        height: 190
                        color: (sharedData.colorBackground || "#0d0d0d")
                        radius: (sharedData && sharedData.quickshellBorderRadius) ? sharedData.quickshellBorderRadius : 0
                        Column { 
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 12
                            Column { 
                                spacing: 3
                                width: parent.width
                                Text { 
                                    text: "󰂯 Bluetooth"
                                    color: (sharedData.colorAccent || "#4a9eff")
                                    font.pixelSize: 15
                                    font.weight: Font.ExtraBold
                                }
                                Text { 
                                    text: sidePanel.qBtStatus + (sidePanel.qBtDevices > 0 ? " (" + sidePanel.qBtDevices + " Connected)" : "")
                                    color: "#fff"; font.pixelSize: 12; font.weight: Font.Medium
                                }
                            }
                            
                            Column {
                                spacing: 4; width: parent.width
                                visible: sidePanel.qBtDeviceNames.length > 0
                                Text { text: "CONNECTED"; color: "#666"; font.pixelSize: 10; font.weight: Font.Bold; font.letterSpacing: 1 }
                                Column {
                                    width: parent.width; spacing: 4
                                    Repeater {
                                        model: sidePanel.qBtDeviceNames.split(";").filter(s => s.length > 0).slice(0, 2)
                                        Text { text: "• " + modelData; color: "#eee"; font.pixelSize: 12; font.weight: Font.Medium; elide: Text.ElideRight; width: parent.width }
                                    }
                                }
                            }
                            
                            Column {
                                spacing: 2; width: parent.width
                                visible: sidePanel.qBtPaired.length > 0
                                Text { text: "PAIRED"; color: "#666"; font.pixelSize: 10; font.weight: Font.Bold; font.letterSpacing: 1 }
                                Column {
                                    width: parent.width; spacing: 4
                                    Repeater {
                                        model: sidePanel.qBtPaired.split(";").filter(s => s.length > 0).slice(0, 2)
                                        Rectangle {
                                            width: parent.width; height: 18; color: "transparent"
                                            property var devInfo: modelData.split("|")
                                            Text { 
                                                anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
                                                text: "• " + (devInfo[1] || "Unknown"); color: "#aaa"; font.pixelSize: 10; elide: Text.ElideRight; width: parent.width - 60 
                                            }
                                            Rectangle {
                                                anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                                                width: 54; height: 18; radius: 3; color: btConnMa.containsMouse ? (sharedData.colorAccent || "#4a9eff") : "#1a1a1a"
                                                Text { anchors.centerIn: parent; text: "Connect"; color: btConnMa.containsMouse ? "#000" : "#fff"; font.pixelSize: 9; font.weight: Font.Bold }
                                                MouseArea { id: btConnMa; anchors.fill: parent; hoverEnabled: true; onClicked: if (devInfo.length > 0) sharedData.runCommand(['bluetoothctl', 'connect', devInfo[0]]) }
                                            }
                                        }
                                    }
                                }
                            }
                            
                            GridLayout {
                                columns: 2; rowSpacing: 4; columnSpacing: 4; width: parent.width
                                Rectangle {
                                    Layout.fillWidth: true; height: 30; color: btMa1.containsMouse ? Qt.rgba(1,1,1,0.1) : Qt.rgba(1,1,1,0.05); radius: 3
                                    Text { 
                                        anchors.centerIn: parent
                                        text: "󰂯 Toggle"
                                        color: sidePanel.qBtStatus === "On" ? sharedData.colorAccent : "#fff"; font.pixelSize: 10; font.weight: Font.Medium
                                    }
                                    MouseArea { id: btMa1; anchors.fill: parent; hoverEnabled: true; onClicked: sharedData.runCommand(['sh', '-c', (sidePanel.qBtStatus === "On" ? 'bluetoothctl power off' : 'bluetoothctl power on')]) }
                                }
                                Rectangle {
                                    Layout.fillWidth: true; height: 30; color: btMa2.containsMouse ? Qt.rgba(1,1,1,0.1) : Qt.rgba(1,1,1,0.05); radius: 3
                                    Text { anchors.centerIn: parent; text: "󰒓 Manager"; color: "#fff"; font.pixelSize: 10; font.weight: Font.Medium }
                                    MouseArea { id: btMa2; anchors.fill: parent; hoverEnabled: true; onClicked: sharedData.runCommand(['blueman-manager']) }
                                }
                            }
                        }
                    }
                }
            }

            QuickToggle {
                icon: "󰐥"
                sharedData: sidePanel.sharedData
                panelPosition: sidePanel.panelPosition
                screen: sidePanel.screen
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
                        width: 180
                        height: 140
                        color: (sharedData.colorBackground || "#0d0d0d")
                        radius: (sharedData && sharedData.quickshellBorderRadius) ? sharedData.quickshellBorderRadius : 0
                        Column { 
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 12
                            Row {
                                width: parent.width; spacing: 6
                                Text { 
                                    text: "󰐥 Power"
                                    color: (sharedData.colorAccent || "#4a9eff")
                                    font.pixelSize: 15; font.weight: Font.ExtraBold
                                    Layout.fillWidth: true
                                }
                                Text {
                                    visible: sidePanel.qBatteryPct > 0
                                    text: sidePanel.qBatteryPct + "% " + (sidePanel.qBatteryStatus === "Charging" ? "󱐌" : (sidePanel.qBatteryStatus === "Full" ? "󰁹" : "󰂌"))
                                    color: sidePanel.qBatteryPct > 20 ? "#fff" : "#f44336"
                                    font.pixelSize: 12; font.weight: Font.Medium
                                }
                            }
                            
                            Column {
                                width: parent.width; spacing: 4
                                Text { text: "PROFILE"; color: "#666"; font.pixelSize: 10; font.weight: Font.Bold; font.letterSpacing: 1 }
                                Row {
                                    id: pwrProfilesRow
                                    spacing: 4; anchors.horizontalCenter: parent.horizontalCenter
                                    property var profiles: ["power-saver", "balanced", "performance"]
                                    Repeater {
                                        model: 3
                                        Rectangle {
                                            width: 46; height: 44; color: pMa.containsMouse ? Qt.rgba(1,1,1,0.1) : Qt.rgba(1,1,1,0.05); radius: 4
                                            property int profileIndex: index
                                            Column {
                                                anchors.centerIn: parent; spacing: 0
                                                Text { 
                                                    anchors.horizontalCenter: parent.horizontalCenter
                                                    text: index === 0 ? "󰌪" : (index === 1 ? "󰗑" : "󰓅")
                                                    color: sidePanel.qPwrStatus.toLowerCase().includes(pwrProfilesRow.profiles[index]) ? sharedData.colorAccent : "#fff"
                                                    font.pixelSize: 16
                                                }
                                                Text {
                                                    anchors.horizontalCenter: parent.horizontalCenter
                                                    text: index === 0 ? "Saver" : (index === 1 ? "Bal" : "Perf")
                                                    color: "#888"; font.pixelSize: 8; font.weight: Font.Medium
                                                }
                                            }
                                            MouseArea { id: pMa; anchors.fill: parent; hoverEnabled: true; onClicked: sharedData.runCommand(['powerprofilesctl', 'set', pwrProfilesRow.profiles[index]]) }
                                        }
                                    }
                                }
                            }

                            Row {
                                width: parent.width; spacing: 4
                                Rectangle {
                                    width: (parent.width - 4) / 2; height: 28; color: rbMa.containsMouse ? "#d32f2f" : Qt.rgba(1,1,1,0.05); radius: 3
                                    Text { anchors.centerIn: parent; text: "󰑐 Reboot"; color: "#fff"; font.pixelSize: 10; font.weight: Font.Medium }
                                    MouseArea { id: rbMa; anchors.fill: parent; hoverEnabled: true; onClicked: sharedData.runCommand(['systemctl', 'reboot']) }
                                }
                                Rectangle {
                                    width: (parent.width - 4) / 2; height: 28; color: sdMa.containsMouse ? "#f44336" : Qt.rgba(1,1,1,0.05); radius: 3
                                    Text { anchors.centerIn: parent; text: "󰐥 Power Off"; color: "#fff"; font.pixelSize: 10; font.weight: Font.Medium }
                                    MouseArea { id: sdMa; anchors.fill: parent; hoverEnabled: true; onClicked: sharedData.runCommand(['systemctl', 'poweroff']) }
                                }
                            }
                        }
                    }
                }
            }

            Item {
                Layout.alignment: Qt.AlignCenter
                Layout.preferredWidth: 26
                Layout.preferredHeight: 26
                z: 1
                
                Text { 
                    text: "󰒓"
                    font.pixelSize: 14
                    font.family: "sans-serif"
                    anchors.centerIn: parent
                    color: settingsButtonMouseArea.containsMouse ? sidePanel.btnIconHover : sidePanel.btnIcon
                    
                    Behavior on color { ColorAnimation { duration: 200; easing.type: Easing.OutCubic } }
                }
                
                MouseArea { 
                    id: settingsButtonMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: { 
                        if (sharedData && sharedData.runCommand) {
                            sharedData.runCommand(['sh', '-c', 'fuse 2>/dev/null || $HOME/.local/bin/fuse 2>/dev/null || $HOME/.config/alloy/fuse/target/release/fuse 2>/dev/null &'])
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
        
        implicitWidth: 180
        implicitHeight: 190
        width: 180
        height: 190
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
}

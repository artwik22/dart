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
    property int qBrightness: 0
    property int qBrightnessMax: 255
    
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
                            radius: 0
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
                            radius: 0
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
        anchors.bottomMargin: !isHorizontal ? 6 : 0
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
                    sidePanelRoot.runAndRead('NW_SSID=$(networkctl status 2>/dev/null | grep -i "SSID:" | cut -d: -f2- | sed "s/^[[:space:]]*//"); [ -n "$NW_SSID" ] && echo "$NW_SSID" || nmcli -t -f ACTIVE,SSID dev wifi | grep "^yes" | cut -d: -f2 || echo ""', function(out) { 
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
                    sidePanelRoot.runAndRead('brightnessctl get', function(out) { 
                        if (out !== undefined) root.qBrightness = parseInt(out) || 0 
                    })
                    sidePanelRoot.runAndRead('brightnessctl max', function(out) { 
                        if (out !== undefined) root.qBrightnessMax = parseInt(out) || 255 
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
        
        anchors.bottomMargin: 2
        anchors.rightMargin: 2
        
        color: (sharedData && sharedData.colorPrimary) ? Qt.lighter(sharedData.colorPrimary, 1.2) : "#252525"
        border.width: 0
        radius: 0
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
                        width: 170
                        height: 160
                        color: (sharedData.colorBackground || "#0d0d0d")
                        radius: 0
                        Column { 
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 8
                            Column { 
                                spacing: 4
                                Text { 
                                    text: "󰖩 Network"
                                    color: (sharedData.colorAccent || "#4a9eff")
                                    font.pixelSize: 14
                                    font.weight: Font.Bold
                                }
                                Text { 
                                    text: (sidePanel.qNetSSID && sidePanel.qNetSSID.length > 0) ? sidePanel.qNetSSID : "Not connected"
                                    color: "#fff"
                                    font.pixelSize: 11
                                    elide: Text.ElideRight
                                    width: parent.width
                                }
                                Text { 
                                    text: (sidePanel.qNetIP && sidePanel.qNetIP.length > 0) ? sidePanel.qNetIP : "No IP"
                                    color: "#888"
                                    font.pixelSize: 9
                                }
                            }
                            
                            GridLayout {
                                columns: 2
                                rowSpacing: 4
                                columnSpacing: 4
                                width: parent.width
                                
                                Rectangle {
                                    Layout.fillWidth: true; height: 28; color: netMa1.containsMouse ? Qt.rgba(1,1,1,0.1) : Qt.rgba(1,1,1,0.05)
                                    Text { anchors.centerIn: parent; text: "󰖩 Toggle"; color: "#fff"; font.pixelSize: 10 }
                                    MouseArea { id: netMa1; anchors.fill: parent; hoverEnabled: true; onClicked: sharedData.runCommand(['sh', '-c', 'nmcli radio wifi | grep -q enabled && nmcli radio wifi off || nmcli radio wifi on']) }
                                }
                                Rectangle {
                                    Layout.fillWidth: true; height: 28; color: netMa2.containsMouse ? Qt.rgba(1,1,1,0.1) : Qt.rgba(1,1,1,0.05)
                                    Text { anchors.centerIn: parent; text: "󰱔 Rescan"; color: "#fff"; font.pixelSize: 10 }
                                    MouseArea { id: netMa2; anchors.fill: parent; hoverEnabled: true; onClicked: sharedData.runCommand(['sh', '-c', 'nmcli dev wifi rescan']) }
                                }
                                Rectangle {
                                    Layout.columnSpan: 2; Layout.fillWidth: true; height: 28; color: netMa3.containsMouse ? Qt.rgba(1,1,1,0.1) : Qt.rgba(1,1,1,0.05)
                                    Text { anchors.centerIn: parent; text: "󰒓 Settings"; color: "#fff"; font.pixelSize: 10 }
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
                        width: 170
                        height: 160
                        color: (sharedData.colorBackground || "#0d0d0d")
                        radius: 0
                        Column { 
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 8
                            Column { 
                                spacing: 4
                                Text { 
                                    text: "󰂯 Bluetooth"
                                    color: (sharedData.colorAccent || "#4a9eff")
                                    font.pixelSize: 14
                                    font.weight: Font.Bold
                                }
                                Text { 
                                    text: sidePanel.qBtStatus + (sidePanel.qBtDevices > 0 ? " (" + sidePanel.qBtDevices + " connected)" : "")
                                    color: "#fff"
                                    font.pixelSize: 11
                                }
                            }
                            
                            Column {
                                width: parent.width
                                spacing: 6
                                Rectangle {
                                    width: parent.width; height: 32; color: btMa1.containsMouse ? Qt.rgba(1,1,1,0.1) : Qt.rgba(1,1,1,0.05)
                                    Text { 
                                        anchors.centerIn: parent
                                        text: "󰂯 Power " + (sidePanel.qBtStatus === "On" ? "Off" : "On")
                                        color: sidePanel.qBtStatus === "On" ? sharedData.colorAccent : "#fff"
                                        font.pixelSize: 11
                                    }
                                    MouseArea { id: btMa1; anchors.fill: parent; hoverEnabled: true; onClicked: sharedData.runCommand(['sh', '-c', (sidePanel.qBtStatus === "On" ? 'bluetoothctl power off' : 'bluetoothctl power on')]) }
                                }
                                Rectangle {
                                    width: parent.width; height: 32; color: btMa2.containsMouse ? Qt.rgba(1,1,1,0.1) : Qt.rgba(1,1,1,0.05)
                                    Text { anchors.centerIn: parent; text: "󰒓 Manager"; color: "#fff"; font.pixelSize: 10 }
                                    MouseArea { id: btMa2; anchors.fill: parent; hoverEnabled: true; onClicked: sharedData.runCommand(['blueman-manager']) }
                                }
                            }
                        }
                    }
                }
            }

            QuickToggle {
                icon: "󰈐"
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
                        width: 170
                        height: 160
                        color: (sharedData.colorBackground || "#0d0d0d")
                        radius: 0
                        Column { 
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 8
                            Text { 
                                text: "󰈐 System & Power"
                                color: (sharedData.colorAccent || "#4a9eff")
                                font.pixelSize: 14
                                font.weight: Font.Bold
                            }
                            
                            Column {
                                width: parent.width
                                spacing: 6
                                Text { text: "Brightness: " + Math.round(sidePanel.qBrightness/sidePanel.qBrightnessMax*100) + "%"; color: "#aaa"; font.pixelSize: 10 }
                                Rectangle {
                                    width: parent.width; height: 20; color: "#222"
                                    Rectangle {
                                        width: (sidePanel.qBrightness / sidePanel.qBrightnessMax) * parent.width
                                        height: parent.height
                                        color: sharedData.colorAccent
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        function update(mouse) {
                                            var p = Math.max(0, Math.min(1, mouse.x / width))
                                            var val = Math.round(p * sidePanel.qBrightnessMax)
                                            sharedData.runCommand(['brightnessctl', 'set', val.toString()])
                                            sidePanel.qBrightness = val
                                        }
                                        onPressed: update(mouse); onPositionChanged: update(mouse)
                                    }
                                }
                            }
                            
                            Row {
                                spacing: 6
                                anchors.horizontalCenter: parent.horizontalCenter
                                property var profiles: ["power-saver", "balanced", "performance"]
                                Repeater {
                                    model: 3
                                    Rectangle {
                                        width: 48; height: 48; color: pMa.containsMouse ? Qt.rgba(1,1,1,0.1) : Qt.rgba(1,1,1,0.05)
                                        property int profileIndex: index
                                        Column {
                                            anchors.centerIn: parent
                                            spacing: 4
                                            Text { 
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                text: parent.parent.profileIndex === 0 ? "󰌪" : (parent.parent.profileIndex === 1 ? "󰗑" : "󰓅")
                                                color: sidePanel.qPwrStatus.toLowerCase().includes(parent.parent.parent.parent.profiles[parent.parent.profileIndex]) ? sharedData.colorAccent : "#fff"
                                                font.pixelSize: 18
                                            }
                                            Text {
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                text: parent.parent.profileIndex === 0 ? "Saver" : (parent.parent.profileIndex === 1 ? "Bal" : "Perf")
                                                color: "#888"; font.pixelSize: 8
                                            }
                                        }
                                        MouseArea { id: pMa; anchors.fill: parent; hoverEnabled: true; onClicked: sharedData.runCommand(['powerprofilesctl', 'set', parent.parent.profiles[parent.profileIndex]]) }
                                    }
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
        
        implicitWidth: 160
        implicitHeight: 140
        width: 170
        height: 160
        color: "transparent"
        
        
        property alias content: popoverLoader.sourceComponent
        property bool isHovered: popoverMouseArea.containsMouse
        property real showProgress: 0.0
        property bool shouldShow: content !== null
        
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
                id: popoverLoader
                anchors.fill: parent
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
                    popoverLoader.sourceComponent = null
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

import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell.Services.SystemTray
import Qt5Compat.GraphicalEffects
import "."

PanelWindow {
    id: sidePanel
    
    required property var screen
    required property string panelPosition
    property var primaryScreen: null
    property string projectPath: ""
    property string wallpaperPath: ""
    
    property var sidePanelRoot: sidePanel
    property bool isHorizontal: panelPosition === "top" || panelPosition === "bottom"
    property bool clockColonVisible: true
    
    // Bindings to centralized data in sharedData (RAM optimization)
    property string qNetStatus: (sharedData && sharedData.netStatus) || "Checking..."
    property string qNetSSID: (sharedData && sharedData.netSSID) || ""
    property string qNetIP: (sharedData && sharedData.netIP) || ""
    property string qBtStatus: (sharedData && sharedData.btStatus) || "Checking..."
    property int qBtDevices: (sharedData && sharedData.btDevices) || 0
    property string qPwrStatus: (sharedData && sharedData.pwrStatus) || "Checking..."
    property int qBatteryPct: (sharedData && sharedData.batteryPct) || 0
    property string qBatteryStatus: (sharedData && sharedData.batteryStatus) || "Unknown"
    property int qNetSignal: (sharedData && sharedData.netSignal) || 0
    property string qNetNearby: (sharedData && sharedData.netNearby) || ""
    property string qBtDeviceNames: (sharedData && sharedData.btDeviceNames) || ""
    property string qBtPaired: (sharedData && sharedData.btPaired) || ""
    
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
    color: "transparent"
    property var sharedData: null
    property bool dynamicBackground: !!(sharedData && sharedData.dynamicSidebarBackground)
    property bool micaBackground: !!(sharedData && sharedData.micaSidebarBackground)

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

        // Mica Blur Background Layer
        Item {
            anchors.fill: parent
            clip: true
            z: -2

            Image {
                id: wallpaperImage
                asynchronous: true
                sourceSize.width: screen ? screen.width / 4 : 480
                sourceSize.height: screen ? screen.height / 4 : 270
                
                // Absolute positioning mapped to screen to make the wallpaper portion align with desktop
                x: sidePanel.panelPosition === "right" ? -(screen.width - sidePanelRect.width) : 0
                y: sidePanel.panelPosition === "bottom" ? -(screen.height - sidePanelRect.height) : 0
                width: screen ? screen.width : 1920
                height: screen ? screen.height : 1080

                source: sidePanel.wallpaperPath ? (sidePanel.wallpaperPath.startsWith("/") ? "file://" + sidePanel.wallpaperPath : sidePanel.wallpaperPath) : ""
                fillMode: Image.PreserveAspectCrop
                visible: false // Hidden because FastBlur will render it
            }

            FastBlur {
                anchors.fill: wallpaperImage
                source: wallpaperImage
                radius: 64
                transparentBorder: false
                visible: sidePanel.wallpaperPath !== "" && sidePanel.micaBackground
            }
        }

        gradient: Gradient {
            orientation: !isHorizontal ? Gradient.Vertical : Gradient.Horizontal
            GradientStop { position: 0.0; color: (sharedData && sharedData.colorBackground) ? Qt.rgba(sharedData.colorBackground.r, sharedData.colorBackground.g, sharedData.colorBackground.b, sidePanel.micaBackground ? 0.75 : 1.0) : Qt.rgba(0.05, 0.05, 0.05, sidePanel.micaBackground ? 0.75 : 1.0) }
            GradientStop { position: 1.0; color: (sharedData && sharedData.colorSecondary) ? Qt.rgba(sharedData.colorSecondary.r, sharedData.colorSecondary.g, sharedData.colorSecondary.b, sidePanel.micaBackground ? 0.75 : 1.0) : Qt.rgba(0.08, 0.08, 0.08, sidePanel.micaBackground ? 0.75 : 1.0) }
        }
        radius: 0
        enabled: false
        z: -1
        opacity: sidePanel.dynamicBackground ? 0 : sidePanel.panelProgress
        Behavior on opacity { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }
        
        transform: Translate {
            // Translate the whole window - since it's transparent, it hides the sidebar
            x: panelPosition === "left" && !panelActive ? -220 : (panelPosition === "right" && !panelActive ? 220 : 0)
            y: panelPosition === "top" && !panelActive ? -220 : (panelPosition === "bottom" && !panelActive ? 220 : 0)
            Behavior on x { NumberAnimation { duration: 450; easing.type: Easing.OutCubic } }
            Behavior on y { NumberAnimation { duration: 450; easing.type: Easing.OutCubic } }
        }
    }

    Component {
        id: islandBg
        Rectangle {
            anchors.fill: parent
            z: -1
            radius: (sharedData && sharedData.quickshellBorderRadius !== undefined) ? sharedData.quickshellBorderRadius : 8
            clip: true
            
            Item {
                anchors.fill: parent
                z: -2
                
                Image {
                    id: islandWallpaperImage
                    asynchronous: true
                    sourceSize.width: screen ? screen.width / 4 : 480
                    sourceSize.height: screen ? screen.height / 4 : 270
                    
                    // We need to map coordinates globally so it aligns with the wallpaper underneath
                    // Approximate mapping assuming standard island layouts
                    x: sidePanel.panelPosition === "right" ? -(screen.width - 40) : -40
                    y: sidePanel.panelPosition === "bottom" ? -(screen.height - 40) : -40
                    width: screen ? screen.width : 1920
                    height: screen ? screen.height : 1080

                    source: sidePanel.wallpaperPath ? (sidePanel.wallpaperPath.startsWith("/") ? "file://" + sidePanel.wallpaperPath : sidePanel.wallpaperPath) : ""
                    fillMode: Image.PreserveAspectCrop
                    visible: false
                }

                FastBlur {
                    anchors.fill: islandWallpaperImage
                    source: islandWallpaperImage
                    radius: 64
                    transparentBorder: false
                    visible: sidePanel.wallpaperPath !== "" && sidePanel.micaBackground
                }
            }
            
            gradient: Gradient {
                orientation: !isHorizontal ? Gradient.Vertical : Gradient.Horizontal
                GradientStop { position: 0.0; color: (sharedData && sharedData.colorBackground) ? Qt.rgba(sharedData.colorBackground.r, sharedData.colorBackground.g, sharedData.colorBackground.b, sidePanel.micaBackground ? 0.75 : 1.0) : Qt.rgba(0.05, 0.05, 0.05, sidePanel.micaBackground ? 0.75 : 1.0) }
                GradientStop { position: 1.0; color: (sharedData && sharedData.colorSecondary) ? Qt.rgba(sharedData.colorSecondary.r, sharedData.colorSecondary.g, sharedData.colorSecondary.b, sidePanel.micaBackground ? 0.75 : 1.0) : Qt.rgba(0.08, 0.08, 0.08, sidePanel.micaBackground ? 0.75 : 1.0) }
            }
            border.width: 1
            border.color: Qt.rgba(1,1,1,0.05)
        }
    }

    Item {
        id: sidePanelContent
        // Anchor to the whole window, not just the rect, to avoid circularity
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        enabled: true
        z: 0
        clip: false
        
        // Shared loader for Clock + Workspaces (Vertical)
        Loader { 
            anchors.left: sidePanelClockColumn.left
            anchors.right: sidePanelClockColumn.right
            anchors.top: sidePanelClockColumn.top
            anchors.bottom: (sidePanelWorkspaceColumnContainer.mode === "top") ? sidePanelWorkspaceColumnContainer.bottom : sidePanelClockColumn.bottom
            
            // Flatten both the panel edge AND the screen side edge in corners
            anchors.leftMargin: -32
            anchors.rightMargin: -32
            anchors.topMargin: 0
            anchors.bottomMargin: -32
            
            sourceComponent: islandBg; 
            z: -1
            active: !isHorizontal && sidePanelClockColumn.visible && sidePanel.dynamicBackground 
        }
        Column {
            id: sidePanelClockColumn
            anchors.top: parent.top
            anchors.topMargin: 0
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
            // Clock background pill
            Rectangle {
                width: 32
                height: sidePanelHoursDisplay.implicitHeight + 6 + sidePanelMinutesDisplay.implicitHeight + 6
                radius: (sharedData && sharedData.quickshellBorderRadius !== undefined && sharedData.quickshellBorderRadius > 0) ? Math.min(sharedData.quickshellBorderRadius, 10) : 10
                color: Qt.rgba(1,1,1,0.06)
                border.width: 1
                border.color: Qt.rgba(1,1,1,0.08)
                anchors.horizontalCenter: parent.horizontalCenter

                Column {
                    anchors.centerIn: parent
                    spacing: 1

                    Text { 
                        id: sidePanelHoursDisplay
                        text: "00"
                        font.pixelSize: 18
                        font.family: "Outfit, sans-serif"
                        font.weight: Font.Bold
                        font.letterSpacing: -0.5
                        color: (sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff"
                        horizontalAlignment: Text.AlignHCenter
                        anchors.horizontalCenter: parent.horizontalCenter
                        Behavior on color { ColorAnimation { duration: 280; easing.type: Easing.OutQuart } } 
                    }

                    // Blinking dot separator
                    Rectangle {
                        width: 4; height: 4
                        radius: 2
                        color: (sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff"
                        anchors.horizontalCenter: parent.horizontalCenter
                        opacity: (sharedData && sharedData.clockBlinkColon) ? (clockColonVisible ? 0.9 : 0.2) : 0.7
                        Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.InOutQuad } }
                    }

                    Text { 
                        id: sidePanelMinutesDisplay
                        text: "00"
                        font.pixelSize: 18
                        font.family: "Outfit, sans-serif"
                        font.weight: Font.Bold
                        font.letterSpacing: -0.5
                        color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff"
                        horizontalAlignment: Text.AlignHCenter
                        anchors.horizontalCenter: parent.horizontalCenter
                        opacity: 0.9
                    }
                }
            }
        }

        // Separator between Clock and Workspaces (Vertical)
        Item {
            id: clockWorkspaceSepV
            width: parent.width
            height: 16
            anchors.top: sidePanelClockColumn.bottom
            anchors.topMargin: 6
            anchors.horizontalCenter: parent.horizontalCenter
            visible: !isHorizontal && sidePanelWorkspaceColumnContainer.mode === "top"

            Rectangle {
                width: 16
                height: 1.5
                anchors.centerIn: parent
                color: Qt.rgba(1, 1, 1, 0.12)
            }
        }
        
        // Shared loader for Clock + Workspaces (Horizontal)
        Loader { 
            anchors.left: sidePanelClockRow.left
            anchors.right: (sidePanelWorkspaceRowContainer.visible) ? sidePanelWorkspaceRowContainer.right : sidePanelClockRow.right
            anchors.top: sidePanelClockRow.top
            anchors.bottom: sidePanelClockRow.bottom
            
            // Flatten both the panel edge AND the screen side edge in corners
            anchors.leftMargin: -32
            anchors.rightMargin: -32
            anchors.topMargin: 0
            anchors.bottomMargin: -32
            
            sourceComponent: islandBg; 
            z: -1
            active: isHorizontal && sidePanelClockRow.visible && sidePanel.dynamicBackground 
        }
        Row {
            id: sidePanelClockRow
            anchors.left: parent.left
            anchors.leftMargin: 0
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
                font.family: "Outfit, sans-serif"
                font.weight: Font.Bold
                font.letterSpacing: -1
                color: (sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff"
                verticalAlignment: Text.AlignVCenter
                Behavior on color { ColorAnimation { duration: 280; easing.type: Easing.OutQuart } } 
            }
            Text {
                text: ":"
                font.pixelSize: 22
                font.family: "Inter, Roboto, sans-serif"
                font.weight: Font.Light
                color: (sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff"
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                opacity: (sharedData && sharedData.clockBlinkColon) ? (clockColonVisible ? 0.9 : 0.1) : 0.9
                Behavior on opacity { NumberAnimation { duration: 100 } }
                
                // Align text baseline with the hours text for correct typographical positioning
                anchors.baseline: sidePanelHoursDisplayTop.baseline
            }
            Text { 
                id: sidePanelMinutesDisplayTop
                text: "00"
                font.pixelSize: 22
                font.family: "Outfit, sans-serif"
                font.weight: Font.Bold
                font.letterSpacing: -1
                color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff"
                verticalAlignment: Text.AlignVCenter
                opacity: 0.85
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
                clockColonVisible = !clockColonVisible
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
            height: sidePanelWorkspaceColumn.height // Dynamic height based on content
            visible: !isHorizontal
            
            // Dynamic Anchoring based on Mode
            property string mode: (sharedData && sharedData.sidebarWorkspaceMode) ? sharedData.sidebarWorkspaceMode : "top"
            
            anchors.horizontalCenter: parent.horizontalCenter
            
            // Mode: Top
            anchors.top: mode === "top" ? clockWorkspaceSepV.bottom : undefined
            anchors.topMargin: mode === "top" ? 4 : 0
            
            // Mode: Center
            anchors.verticalCenter: mode === "center" ? parent.verticalCenter : undefined
            
            // Mode: Bottom
            // Anchor to the top of the tray (if visible) or actionsGroup
            property Item bottomAnchorItem: (sidePanelTrayVertical.visible && sidePanelTrayVertical.height > 0) ? sidePanelTrayVertical : actionsGroup
            anchors.bottom: mode === "bottom" ? bottomAnchorItem.top : undefined
            anchors.bottomMargin: mode === "bottom" ? 24 : 0
            
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
            // Dedicated background for workspaces IF NOT at top (Vertical)
            Loader { 
                anchors.fill: sidePanelWorkspaceColumn
                anchors.leftMargin: -32
                anchors.rightMargin: -32
                anchors.topMargin: 0
                anchors.bottomMargin: -32
                sourceComponent: islandBg; 
                z: -1
                active: !isHorizontal && sidePanelWorkspaceColumnContainer.visible && sidePanel.dynamicBackground && sidePanelWorkspaceColumnContainer.mode !== "top"
            }
            // Liquid Morph Track (Vertical)
            Rectangle {
                id: wsTrackVert
                width: 3
                height: sidePanelWorkspaceColumn.height
                x: (parent.width - width) / 2
                y: sidePanelWorkspaceColumn.y
                color: Qt.rgba(1, 1, 1, 0.12)
                radius: 1.5
                z: -1
                visible: !isHorizontal
            }

            // Liquid Morph Segment (Active Workspace - Vertical)
            Rectangle {
                id: wsActiveSegmentVert
                width: 5
                x: (parent.width - width) / 2
                z: 0
                visible: !isHorizontal
                
                property var provider: (sharedData && sharedData.workspaceProvider) ? sharedData.workspaceProvider : Hyprland
                property int activeIndex: provider.focusedWorkspace ? Math.max(0, Math.min(3, provider.focusedWorkspace.id - 1)) : 0
                
                // Position and height animation to create "morph" feel
                height: 24 
                y: sidePanelWorkspaceColumn.y + activeIndex * (16 + 12) + (16 - height) / 2
                
                color: sharedData.colorAccent || "#4a9eff"
                radius: 2.5
                
                Behavior on y { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
                Behavior on height { NumberAnimation { duration: 300 } }
            }

            Column { 
                id: sidePanelWorkspaceColumn
                spacing: 12
                width: parent.width
                
                Repeater { 
                    model: 4
                    Item { 
                        id: workspaceItem
                        width: parent.width
                        height: 16
                        anchors.horizontalCenter: parent.horizontalCenter
                        
                        property var provider: (sharedData && sharedData.workspaceProvider) ? sharedData.workspaceProvider : Hyprland
                        
                        // Pure Mode: No dots, no dashes, no visual markers here.
                        // Only the underlying track and moving segment define the UI.

                        MouseArea { 
                            id: wsMouseArea
                            anchors.fill: parent
                            anchors.margins: -4
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (provider.dispatch) {
                                    provider.dispatch("workspace", index + 1)
                                } else {
                                    Hyprland.dispatch("workspace", index + 1)
                                }
                            }
                        }
                    }
                }
            }
            // Scroll area covering entire workspace column
            MouseArea {
                anchors.fill: sidePanelWorkspaceColumn
                anchors.margins: -8
                acceptedButtons: Qt.NoButton
                onWheel: function(wheel) {
                    var provider = (sharedData && sharedData.workspaceProvider) ? sharedData.workspaceProvider : Hyprland
                    if (wheel.angleDelta.y > 0) {
                        if (provider.dispatch) provider.dispatch("workspace", "m-1")
                        else Hyprland.dispatch("workspace", "m-1")
                    } else if (wheel.angleDelta.y < 0) {
                        if (provider.dispatch) provider.dispatch("workspace", "m+1")
                        else Hyprland.dispatch("workspace", "m+1")
                    }
                }
            }
        }
        
        // Separator between Clock and Workspaces (Horizontal)
        Item {
            id: clockWorkspaceSepH
            width: 16
            height: parent.height
            anchors.left: sidePanelClockRow.right
            anchors.leftMargin: 6
            anchors.verticalCenter: parent.verticalCenter
            visible: isHorizontal

            Rectangle {
                width: 1.5
                height: 16
                anchors.centerIn: parent
                color: Qt.rgba(1, 1, 1, 0.12)
            }
        }

        Item {
            id: sidePanelWorkspaceRowContainer
            width: sidePanelWorkspaceRow.width // Dynamic width
            height: parent.height
            visible: isHorizontal
            anchors.left: clockWorkspaceSepH.right
            anchors.leftMargin: 4
            anchors.verticalCenter: parent.verticalCenter
            z: 50
            
            // Background for workspaces is shared in Horizontal mode (see above), so no loader here.
            // Liquid Morph Track (Horizontal)
            Rectangle {
                id: wsTrackHoriz
                height: 3
                width: sidePanelWorkspaceRow.width
                y: (parent.height - height) / 2
                x: sidePanelWorkspaceRow.x
                color: Qt.rgba(1, 1, 1, 0.12)
                radius: 1.5
                z: -1
                visible: isHorizontal
            }

            // Liquid Morph Segment (Active Workspace - Horizontal)
            Rectangle {
                id: wsActiveSegmentHoriz
                height: 5
                y: (parent.height - height) / 2
                z: 0
                visible: isHorizontal
                
                property var provider: (sharedData && sharedData.workspaceProvider) ? sharedData.workspaceProvider : Hyprland
                property int activeIndex: provider.focusedWorkspace ? Math.max(0, Math.min(3, provider.focusedWorkspace.id - 1)) : 0
                
                width: 24
                x: sidePanelWorkspaceRow.x + activeIndex * (16 + 12) + (16 - width) / 2
                
                color: sharedData.colorAccent || "#4a9eff"
                radius: 2.5
                
                Behavior on x { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
                Behavior on width { NumberAnimation { duration: 300 } }
            }

            Row { 
                id: sidePanelWorkspaceRow
                spacing: 12
                height: parent.height
                
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
                        width: 16
                        anchors.verticalCenter: parent.verticalCenter
                        
                        property var provider: (sharedData && sharedData.workspaceProvider) ? sharedData.workspaceProvider : Hyprland
                        
                        // Pure Mode: No visual markers for individual workspaces here.

                        MouseArea { 
                            id: wsMouseAreaTop
                            anchors.fill: parent
                            anchors.margins: -4
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (provider.dispatch) {
                                    provider.dispatch("workspace", index + 1)
                                } else {
                                    Hyprland.dispatch("workspace", index + 1)
                                }
                            }
                        }
                    }
                }
            }
            // Scroll area covering entire workspace row
            MouseArea {
                anchors.fill: sidePanelWorkspaceRow
                anchors.margins: -8
                acceptedButtons: Qt.NoButton
                onWheel: function(wheel) {
                    var provider = (sharedData && sharedData.workspaceProvider) ? sharedData.workspaceProvider : Hyprland
                    if (wheel.angleDelta.y > 0) {
                        if (provider.dispatch) provider.dispatch("workspace", "m-1")
                        else Hyprland.dispatch("workspace", "m-1")
                    } else if (wheel.angleDelta.y < 0) {
                        if (provider.dispatch) provider.dispatch("workspace", "m+1")
                        else Hyprland.dispatch("workspace", "m+1")
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
            radius: (sharedData && sharedData.quickshellBorderRadius !== undefined) ? sharedData.quickshellBorderRadius : 6
            color: trayMa.containsMouse ? sidePanel.btnBgHover : "transparent"
            
            Image {
                asynchronous: true
                sourceSize.width: 64
                sourceSize.height: 64
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
        anchors.horizontalCenter: sidePanelContent.horizontalCenter
        spacing: 4
        visible: !isHorizontal && SystemTray.items.count > 0
        
        Repeater {
            model: SystemTray.items
            delegate: trayItemDelegate
        }
    }

    Loader { 
        anchors.fill: sidePanelTrayVertical
        anchors.leftMargin: -32
        anchors.rightMargin: -32
        anchors.topMargin: 0
        anchors.bottomMargin: -32
        sourceComponent: islandBg; 
        z: -1
        active: sidePanelTrayVertical.visible && sidePanel.dynamicBackground 
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

    Loader { 
        anchors.fill: sidePanelTrayHorizontal
        anchors.leftMargin: -32
        anchors.rightMargin: -32
        anchors.topMargin: 0
        anchors.bottomMargin: -32
        sourceComponent: islandBg; 
        z: -1
        active: sidePanelTrayHorizontal.visible && sidePanel.dynamicBackground 
    }

    Item {
        id: actionsGroup
        width: !isHorizontal ? actionsLayout.implicitWidth + 8 : actionsLayout.implicitWidth + 24
        height: isHorizontal ? actionsLayout.implicitHeight + 8 : actionsLayout.implicitHeight + 8
        anchors.horizontalCenter: !isHorizontal ? parent.horizontalCenter : undefined
        anchors.verticalCenter: isHorizontal ? parent.verticalCenter : undefined
        anchors.right: isHorizontal ? parent.right : undefined
        anchors.rightMargin: 0
        anchors.bottom: !isHorizontal ? parent.bottom : undefined
        anchors.top: (!isHorizontal && panelPosition === "top") ? parent.top : undefined
        anchors.bottomMargin: 0
        anchors.topMargin: 0
        visible: panelActive
        z: 100001
        
        Loader {
            anchors.fill: parent
            z: -1
            active: sidePanel.dynamicBackground
            // Flatten both the panel edge AND the screen side edge in corners
            anchors.leftMargin: -32
            anchors.rightMargin: -32
            anchors.topMargin: 0
            anchors.bottomMargin: -32
            sourceComponent: islandBg
        }
        
        GridLayout {
            id: actionsLayout
            anchors.centerIn: parent
            flow: GridLayout.LeftToRight
            columns: !isHorizontal ? 1 : (sharedData && sharedData.sidebarBatteryEnabled === true ? 6 : 4)
            rows: !isHorizontal ? -1 : 1
            rowSpacing: 4
            
            QuickToggle {
                icon: "󰖩"
                sharedData: sidePanel.sharedData
                sidePanelRoot: sidePanel
                panelPosition: sidePanel.panelPosition
                outputScreen: sidePanel.screen
                showBackground: false
                Layout.alignment: Qt.AlignCenter
                Layout.preferredWidth: 30
                Layout.preferredHeight: 30
                popoverContent: Component {
                    WifiStatusPopover {
                        sharedData: sidePanel.sharedData
                        sidePanelRoot: sidePanel
                    }
                }
                clickPopoverContent: Component {
                    WifiMenu {
                        sharedData: sidePanel.sharedData
                        sidePanelRoot: sidePanel
                        popoverWindow: popoverWindow
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
                Layout.preferredWidth: 30
                Layout.preferredHeight: 30
                onClicked: {
                    if (sharedData && sharedData.runCommand) {
                        var cmd = (sidePanel.qBtStatus === "On") ? 'bluetoothctl power off' : 'bluetoothctl power on'
                        sharedData.runCommand(['sh', '-c', cmd])
                    }
                }
popoverContent: Component {
                    BluetoothMenu {
                        sharedData: sidePanel.sharedData
                        sidePanelRoot: sidePanel
                    }
                }
            }
            
            // Separator between Bluetooth and Battery Ring
            Item {
                Layout.preferredWidth: !isHorizontal ? 16 : 1
                Layout.preferredHeight: isHorizontal ? 16 : 1

                Rectangle {
                    anchors.centerIn: parent
                    width: !isHorizontal ? 16 : 1
                    height: isHorizontal ? 16 : 1
                    color: Qt.rgba(1, 1, 1, 0.12)
                }
            }

            // ── Circular Battery Ring ─────────────────────────────────────
            Item {
                id: batteryRingItem
                Layout.alignment: Qt.AlignCenter
                Layout.preferredWidth: 22
                Layout.preferredHeight: 22
                visible: (sharedData && sharedData.sidebarBatteryEnabled === true)

                property bool isCharging: {
                    var s = sidePanel.qBatteryStatus.toLowerCase()
                    return s === "charging" || s === "full" || s === "fully-charged"
                }
                property int pct: sidePanel.qBatteryPct
                property color ringColor: isCharging
                    ? ((sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff")
                    : (pct > 40
                        ? ((sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff")
                        : (pct > 20 ? "#ffa500" : "#ff5555"))

                // Pulsing glow when charging
                SequentialAnimation on opacity {
                    running: batteryRingItem.isCharging
                    loops: Animation.Infinite
                    NumberAnimation { from: 1.0; to: 0.5; duration: 1200; easing.type: Easing.InOutSine }
                    NumberAnimation { from: 0.5; to: 1.0; duration: 1200; easing.type: Easing.InOutSine }
                }

                scale: batteryRingMouseArea.containsMouse ? 1.15 : 1.0
                Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }

                // GPU-rendered ring using Shape (antialiased, smooth)
                Shape {
                    id: batteryRingShape
                    anchors.fill: parent
                    layer.enabled: true
                    layer.samples: 4

                    property real animatedPct: batteryRingItem.pct
                    Behavior on animatedPct {
                        NumberAnimation { duration: 600; easing.type: Easing.OutCubic }
                    }

                    // Track — full gray circle
                    ShapePath {
                        strokeColor: Qt.rgba(1, 1, 1, 0.18)
                        strokeWidth: 2.5
                        fillColor: "transparent"
                        capStyle: ShapePath.RoundCap

                        PathAngleArc {
                            centerX: batteryRingItem.width / 2
                            centerY: batteryRingItem.height / 2
                            radiusX: batteryRingItem.width / 2 - 2
                            radiusY: batteryRingItem.height / 2 - 2
                            startAngle: 0
                            sweepAngle: 360
                        }
                    }

                    // Progress arc — proportional to battery %
                    ShapePath {
                        strokeColor: batteryRingItem.ringColor
                        strokeWidth: 3
                        fillColor: "transparent"
                        capStyle: ShapePath.RoundCap

                        PathAngleArc {
                            centerX: batteryRingItem.width / 2
                            centerY: batteryRingItem.height / 2
                            radiusX: batteryRingItem.width / 2 - 2
                            radiusY: batteryRingItem.height / 2 - 2
                            startAngle: -90
                            sweepAngle: Math.max(0, Math.min(batteryRingShape.animatedPct, 100)) / 100.0 * 360
                        }
                    }
                }

                // Rotating segment when charging (Extra highlight)
                Shape {
                    id: chargingRingShape
                    anchors.fill: parent
                    visible: batteryRingItem.isCharging
                    layer.enabled: true
                    layer.samples: 4

                    ShapePath {
                        strokeColor: "#ffffff"
                        strokeWidth: 3.5
                        fillColor: "transparent"
                        capStyle: ShapePath.RoundCap

                        PathAngleArc {
                            centerX: batteryRingItem.width / 2
                            centerY: batteryRingItem.height / 2
                            radiusX: batteryRingItem.width / 2 - 2
                            radiusY: batteryRingItem.height / 2 - 2
                            startAngle: -90
                            sweepAngle: 45
                        }
                    }

                    RotationAnimation on rotation {
                        from: 0; to: 360; duration: 1200
                        running: batteryRingItem.isCharging
                        loops: Animation.Infinite
                    }
                }

                // Hover/popover trigger
                MouseArea {
                    id: batteryRingMouseArea
                    anchors.fill: parent
                    anchors.margins: -4
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    onEntered: {
                        if (sidePanel.hoveredTogglesCount !== undefined)
                            sidePanel.hoveredTogglesCount += 1
                        sidePanel.showPopover(batteryRingItem.batteryPopoverComponent, 0, 0)
                    }
                    onExited: {
                        if (sidePanel.hoveredTogglesCount !== undefined && sidePanel.hoveredTogglesCount > 0)
                            sidePanel.hoveredTogglesCount -= 1
                        sidePanel.showPopover(null, 0, 0)
                    }
                }

                // Popover content
                property Component batteryPopoverComponent: Component {
                    Rectangle {
                        width: 210
                        height: 80
                        color: (sharedData && sharedData.colorSecondary) ? sharedData.colorSecondary : "#141414"
                        radius: (sharedData && sharedData.quickshellBorderRadius !== undefined) ? sharedData.quickshellBorderRadius : 10

                        Column {
                            anchors.fill: parent
                            anchors.margins: 14
                            spacing: 6

                            RowLayout {
                                width: parent.width
                                spacing: 10

                                // Mini circular ring in popover (GPU rendered)
                                Item {
                                    width: 38; height: 38
                                    
                                    Shape {
                                        anchors.fill: parent
                                        layer.enabled: true
                                        layer.samples: 4

                                        property real animatedPct: sidePanel.qBatteryPct
                                        Behavior on animatedPct { NumberAnimation { duration: 800; easing.type: Easing.OutCubic } }

                                        // Background track
                                        ShapePath {
                                            strokeColor: Qt.rgba(1, 1, 1, 0.1)
                                            strokeWidth: 3
                                            fillColor: "transparent"
                                            capStyle: ShapePath.RoundCap

                                            PathAngleArc {
                                                centerX: 19; centerY: 19
                                                radiusX: 16; radiusY: 16
                                                startAngle: 0; sweepAngle: 360
                                            }
                                        }

                                        // Progress arc
                                        ShapePath {
                                            strokeColor: sidePanel.qBatteryPct > 40
                                                ? ((sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff")
                                                : (sidePanel.qBatteryPct > 20 ? "#ffd700" : "#ff4444")
                                            strokeWidth: 3.5
                                            fillColor: "transparent"
                                            capStyle: ShapePath.RoundCap

                                            PathAngleArc {
                                                centerX: 19; centerY: 19
                                                radiusX: 16; radiusY: 16
                                                startAngle: -90
                                                sweepAngle: Math.max(0, Math.min(parent.animatedPct, 100)) / 100.0 * 360
                                            }
                                        }
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        text: sidePanel.qBatteryPct + "%"
                                        font.pixelSize: 8; font.weight: Font.Black
                                        color: "#ffffff"
                                        style: Text.Outline
                                        styleColor: Qt.rgba(0,0,0,0.5)
                                    }
                                }

                                Column {
                                    Layout.fillWidth: true
                                    spacing: 2
                                    anchors.verticalCenter: parent.verticalCenter

                                    Text {
                                        text: sidePanel.qBatteryPct + "%"
                                        font.pixelSize: 20; font.weight: Font.Black
                                        color: "#ffffff"
                                    }
                                    Text {
                                        text: sidePanel.qBatteryStatus
                                        font.pixelSize: 11
                                        color: Qt.rgba(1,1,1,0.5)
                                    }
                                }
                            }

                            // Progress bar
                            Item {
                                width: parent.width; height: 5
                                Rectangle {
                                    anchors.fill: parent; radius: height/2
                                    color: Qt.rgba(1,1,1,0.1)
                                }
                                Rectangle {
                                    height: parent.height; radius: height/2
                                    width: parent.width * Math.max(0, Math.min(sidePanel.qBatteryPct, 100)) / 100.0
                                    color: sidePanel.qBatteryPct > 40
                                        ? ((sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff")
                                        : (sidePanel.qBatteryPct > 20 ? "#ffd700" : "#ff4444")
                                    Behavior on width { NumberAnimation { duration: 600; easing.type: Easing.OutExpo } }
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
        WlrLayershell.keyboardFocus: (shouldShow && popoverRequestsFocus) ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        
        implicitWidth: targetWidth
        implicitHeight: targetHeight
        
        property real targetWidth: activeLoader === 1 ? (popoverLoader1.item ? (popoverLoader1.item.width > 0 ? popoverLoader1.item.width : 240) : 240) : (popoverLoader2.item ? (popoverLoader2.item.width > 0 ? popoverLoader2.item.width : 240) : 240)
        property real targetHeight: activeLoader === 1 ? (popoverLoader1.item ? (popoverLoader1.item.height > 0 ? popoverLoader1.item.height : 240) : 240) : (popoverLoader2.item ? (popoverLoader2.item.height > 0 ? popoverLoader2.item.height : 240) : 240)
        
        color: "transparent"
        
        
        property Component content: null
        property int activeLoader: 1
        property bool isHovered: popoverMouseArea.containsMouse
        property real showProgress: 0.0
        property bool shouldShow: false
        property bool popoverRequestsFocus: false
        
        onContentChanged: {
            if (content !== null) {
                shouldShow = true
                if (showProgress > 0) {
                    // Transition between menus: quickly hide old to prevent clipping
                    if (activeLoader === 1 && popoverLoader1.sourceComponent !== content) {
                        popoverLoader1.sourceComponent = null
                        popoverLoader2.sourceComponent = content
                        activeLoader = 2
                    } else if (activeLoader === 2 && popoverLoader2.sourceComponent !== content) {
                        popoverLoader2.sourceComponent = null
                        popoverLoader1.sourceComponent = content
                        activeLoader = 1
                    }
                } else {
                    // Initial opening or re-opening after hide
                    if (activeLoader === 1) {
                        popoverLoader1.sourceComponent = null
                        popoverLoader1.sourceComponent = content
                    } else {
                        popoverLoader2.sourceComponent = null
                        popoverLoader2.sourceComponent = content
                    }
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
            if (!isHovered && sidePanel.hoveredTogglesCount === 0) {
                hideTimer.restart()
            } else {
                hideTimer.stop()
            }
        }

        // Internal container to handle opacity and animations since Window doesn't have it
        Item {
            anchors.fill: parent
            opacity: popoverWindow.showProgress
            
            transform: [
                Translate {
                    // Slide in from the sidebar edge
                    x: !isHorizontal ? (panelPosition === "right" ? (1.0 - popoverWindow.showProgress) * 20 : (popoverWindow.showProgress - 1.0) * 20) : 0
                    y: isHorizontal ? (panelPosition === "bottom" ? (1.0 - popoverWindow.showProgress) * 20 : (popoverWindow.showProgress - 1.0) * 20) : 0
                }
            ]
            
            Loader {
                id: popoverLoader1
                opacity: popoverWindow.activeLoader === 1 ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
            }

            Loader {
                id: popoverLoader2
                opacity: popoverWindow.activeLoader === 2 ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
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
                    // Do not aggressively reset activeLoader here to avoid 0-component race condition
                }
            }
        }
        
        Timer {
            id: hideTimer
            interval: 300
            onTriggered: {
                popoverWindow.content = null
            }
        }
    }

    property int hoveredTogglesCount: 0
    property bool isAnyToggleHovered: hoveredTogglesCount > 0

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
            if (!popoverWindow.isHovered && sidePanel.hoveredTogglesCount === 0) {
                hideTimer.restart()
            }
        }
    }
    }

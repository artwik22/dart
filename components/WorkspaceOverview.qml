import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQml
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Qt5Compat.GraphicalEffects
import "."

PanelWindow {
    id: overviewRoot

    property var sharedData: null
    property string projectPath: ""
    
    // Window settings
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qsworkspaceoverview"
    WlrLayershell.keyboardFocus: (showProgress > 0.5) ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    exclusiveZone: 0
    
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    // Animation state
    property bool animationReady: false
    property real showProgress: 0
    
    Binding on showProgress {
        when: animationReady
        value: (sharedData && sharedData.overviewVisible) ? 1.0 : 0.0
    }
    
    Behavior on showProgress {
        NumberAnimation { duration: 400; easing.type: Easing.OutExpo }
    }
    
    visible: showProgress > 0.001
    color: "transparent"

    Component.onCompleted: {
        animationReady = true
    }

    // MouseArea to close on click outside
    MouseArea {
        anchors.fill: parent
        onClicked: if (sharedData) sharedData.overviewVisible = false
    }

    // Blurred Background
    Rectangle {
        id: mainBackground
        anchors.fill: parent
        color: (sharedData && sharedData.colorBackground) ? Qt.alpha(sharedData.colorBackground, 0.4) : Qt.rgba(0,0,0,0.4)
        opacity: showProgress

        // For real blur, we'd need a way to capture the screen, 
        // but here we'll use a semi-transparent dark overlay with scale-in effect
    }

    Item {
        id: contentContainer
        anchors.centerIn: parent
        width: parent.width * 0.85
        height: parent.height * 0.85
        
        opacity: showProgress
        scale: 0.9 + (0.1 * showProgress)
        
        Behavior on opacity { NumberAnimation { duration: 300 } }
        Behavior on scale { NumberAnimation { duration: 400; easing.type: Easing.OutBack } }

        ColumnLayout {
            anchors.fill: parent
            spacing: 30

            // Header
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "Workspace Overview"
                font.pixelSize: 32
                font.family: "Outfit, sans-serif"
                font.weight: Font.Bold
                color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff"
                opacity: 0.9
            }

            // Grid of Workspaces
            GridLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                columns: 3
                columnSpacing: 20
                rowSpacing: 20

                Repeater {
                    model: 9 // Show workspaces 1-9
                    
                    delegate: Rectangle {
                        id: wsCard
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: (sharedData && sharedData.quickshellBorderRadius) ? sharedData.quickshellBorderRadius : 16
                        color: isFocused ? 
                               ((sharedData && sharedData.colorAccent) ? Qt.alpha(sharedData.colorAccent, 0.2) : Qt.rgba(0.2, 0.6, 1.0, 0.2)) : 
                               ((sharedData && sharedData.colorSecondary) ? sharedData.colorSecondary : "#1c1c1c")
                        
                        border.width: isFocused ? 2 : 1
                        border.color: isFocused ? 
                                       ((sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff") : 
                                       Qt.rgba(1,1,1,0.1)

                        property int workspaceId: index + 1
                        property bool isFocused: Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id === workspaceId
                        property var workspaceData: Hyprland.workspaces.values.find(w => w.id === workspaceId)
                        property bool hasWindows: workspaceData ? workspaceData.lastIpcObject.windows > 0 : false

                        // Workspace ID Number (Watermark)
                        Text {
                            anchors.centerIn: parent
                            text: wsCard.workspaceId
                            font.pixelSize: 120
                            font.weight: Font.Black
                            color: wsCard.isFocused ? 
                                   ((sharedData && sharedData.colorAccent) ? Qt.alpha(sharedData.colorAccent, 0.15) : Qt.rgba(1,1,1,0.05)) : 
                                   Qt.rgba(1,1,1,0.03)
                        }

                        // App List
                        Column {
                            anchors.fill: parent
                            anchors.margins: 16
                            spacing: 8

                            Text {
                                text: "Workspace " + wsCard.workspaceId
                                font.pixelSize: 16
                                font.weight: Font.Bold
                                color: wsCard.isFocused ? 
                                       ((sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff") : 
                                       ((sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff")
                            }

                            Flow {
                                width: parent.width
                                spacing: 8
                                visible: wsCard.hasWindows

                                // In a real implementation, we would iterate through windows on this workspace.
                                // Quickshell provides Hyprland.clients, we can filter them.
                                Repeater {
                                    model: {
                                        var clients = []
                                        for (var client of Hyprland.clients.values) {
                                            if (client.workspace === wsCard.workspaceId) {
                                                clients.push(client)
                                            }
                                        }
                                        return clients
                                    }

                                    delegate: Rectangle {
                                        width: 36
                                        height: 36
                                        radius: 8
                                        color: Qt.rgba(1,1,1,0.05)
                                        
                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData.class.substring(0, 1).toUpperCase()
                                            font.pixelSize: 14
                                            font.weight: Font.Bold
                                            color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff"
                                        }

                                        ToolTip.visible: clientMa.containsMouse
                                        ToolTip.text: modelData.title || modelData.class

                                        MouseArea {
                                            id: clientMa
                                            anchors.fill: parent
                                            hoverEnabled: true
                                        }
                                    }
                                }
                            }

                            Text {
                                visible: !wsCard.hasWindows
                                text: "Empty"
                                font.pixelSize: 14
                                color: Qt.rgba(1,1,1,0.3)
                                font.italic: true
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                Hyprland.dispatch("workspace", wsCard.workspaceId)
                                if (sharedData) sharedData.overviewVisible = false
                            }
                        }
                        
                        // Scale on hover
                        scale: wsCardMa.containsMouse ? 1.02 : 1.0
                        Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                        
                        MouseArea {
                            id: wsCardMa
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.NoButton
                        }
                    }
                }
            }

            // Footer / Instructions
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "Press ESC or click outside to close"
                font.pixelSize: 14
                color: Qt.rgba(1,1,1,0.5)
            }
        }
    }

    // ESC to close
    Keys.onPressed: function(event) {
        if (event.key === Qt.Key_Escape) {
            if (sharedData) sharedData.overviewVisible = false
            event.accepted = true
        }
    }
}

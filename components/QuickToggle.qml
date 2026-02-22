import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

Item {
    id: root
    
    property string icon: ""
    property string label: ""
    property string statusText: ""
    property bool active: false
    property var sharedData: null
    property string panelPosition: "left"
    property var outputScreen: null
    
    // Large Mode for Dashboard
    property bool isLarge: false
    
    // Popover content (for sidebar)
    property Component popoverContent: null
    
    // Click handler signal
    signal clicked()
    
    implicitWidth: isLarge ? 160 : 36
    implicitHeight: isLarge ? 80 : 36
    
    property bool showBackground: true
    
    // Colors (Material 3)
    property color btnBg: (sharedData && sharedData.colorSurfaceContainerHigh) ? sharedData.colorSurfaceContainerHigh : "#2B2930"
    property color btnBgActive: (sharedData && sharedData.colorPrimary) ? sharedData.colorPrimary : "#D0BCFF"
    property color btnBgHover: (sharedData && sharedData.colorSurfaceContainerHighest) ? sharedData.colorSurfaceContainerHighest : "#48464C"
    
    property color contentColor: (active && isLarge) ? 
                                 ((sharedData && sharedData.colorOnPrimary) ? sharedData.colorOnPrimary : "#381E72") : 
                                 ((sharedData && sharedData.colorOnSurface) ? sharedData.colorOnSurface : "#E6E1E5")
    
    scale: mouseArea.pressed ? 0.90 : (mouseArea.containsMouse ? 1.05 : 1.0)
    Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }

    Rectangle {
        id: bgRect
        anchors.fill: parent
        radius: (root.sharedData && root.sharedData.quickshellBorderRadius !== undefined) ? root.sharedData.quickshellBorderRadius : (isLarge ? 16 : 10)
        color: {
            if (root.active) return root.btnBgActive
            if (mouseArea.pressed) return Qt.rgba(1,1,1,0.02)
            if (mouseArea.containsMouse) return Qt.rgba(1,1,1,0.12)
            return root.showBackground ? root.btnBg : "transparent"
        }
        border.width: (root.active || mouseArea.containsMouse || root.showBackground) ? 1 : 0
        border.color: root.active ? "transparent" : Qt.rgba(1,1,1,0.05)
        
        Behavior on color { ColorAnimation { duration: 150; easing.type: Easing.OutQuad } }
        Behavior on border.color { ColorAnimation { duration: 150; easing.type: Easing.OutQuad } }
    }
    
    property bool pulsing: false
    
    // Small sidebar mode
    Text {
        id: iconText
        visible: !root.isLarge
        anchors.centerIn: parent
        text: root.icon
        font.pixelSize: 18
        font.family: "Material Design Icons"
        color: root.contentColor
        z: 1

        // Subtle but noticeable breathing for the icon
        SequentialAnimation on opacity {
            running: root.pulsing && !root.isLarge
            loops: Animation.Infinite
            NumberAnimation { from: 1.0; to: 0.4; duration: 1500; easing.type: Easing.InOutSine }
            NumberAnimation { from: 0.4; to: 1.0; duration: 1500; easing.type: Easing.InOutSine }
        }
    }

    
    // Large Dashboard mode
    RowLayout {
        visible: root.isLarge
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12
        
        // Icon Circle
        Rectangle {
            Layout.preferredWidth: 34
            Layout.preferredHeight: 34
            radius: 17
            color: "transparent" // Icon sits directly on tile in M3, or use a container if needed
            
            Text {
                anchors.centerIn: parent
                text: root.icon
                font.pixelSize: 24
                font.family: "Material Design Icons"
                color: root.contentColor
            }
        }
        
        // Text Info
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            
            Text {
                text: root.label
                font.pixelSize: 14
                font.weight: Font.Bold
                font.family: "sans-serif"
                color: root.contentColor
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
            
            Text {
                text: root.statusText || (root.active ? "On" : "Off")
                font.pixelSize: 12
                font.family: "sans-serif"
                color: root.contentColor
                opacity: 0.8
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }
    }
    
    property var sidePanelRoot: null

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        
        onEntered: {
            if (root.sidePanelRoot && root.popoverContent) {
                root.sidePanelRoot.isAnyToggleHovered = true
                root.sidePanelRoot.showPopover(root.popoverContent, 0, 0)
            }
        }
        
        onExited: {
            if (root.sidePanelRoot) {
                root.sidePanelRoot.isAnyToggleHovered = false
                // Trigger check to hide if not hovering popover
                root.sidePanelRoot.showPopover(null, 0, 0) 
            }
        }

        onClicked: {
            root.clicked()
        }
    }
}

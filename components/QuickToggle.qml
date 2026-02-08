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
    
    Rectangle {
        id: bgRect
        anchors.fill: parent
        radius: (root.sharedData && root.sharedData.quickshellBorderRadius) ? root.sharedData.quickshellBorderRadius : (isLarge ? 28 : 18)
        color: {
            if (root.active && root.isLarge) return root.btnBgActive
            if (mouseArea.containsMouse) return root.btnBgHover
            return root.btnBg
        }
        visible: root.showBackground
        
        Behavior on color { ColorAnimation { duration: 200; easing.type: Easing.OutCubic } }
    }
    
    // Small sidebar mode
    Text {
        visible: !root.isLarge
        anchors.centerIn: parent
        text: root.icon
        font.pixelSize: 18
        font.family: "Material Design Icons"
        color: root.contentColor
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

    // ... (existing properties)

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
            clickAnim.start()
            root.clicked()
        }
    }
    
    SequentialAnimation {
        id: clickAnim
        NumberAnimation { target: root; property: "scale"; to: 0.95; duration: 50; easing.type: Easing.OutQuad }
        NumberAnimation { target: root; property: "scale"; to: 1.0; duration: 150; easing.type: Easing.OutBack }
    }
}

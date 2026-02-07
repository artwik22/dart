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
    property var screen: null
    
    // Popover content - can be any Item
    property Component popoverContent: null
    
    implicitWidth: 26
    implicitHeight: 26
    
    property bool isHorizontal: panelPosition === "top" || panelPosition === "bottom"
    property bool showBackground: true
    
    property color btnBg: (sharedData && sharedData.colorSecondary) ? sharedData.colorSecondary : "#1a1a1a"
    property color btnBgHover: (sharedData && sharedData.colorAccent) ? Qt.alpha(sharedData.colorAccent, 0.2) : "rgba(74, 158, 255, 0.2)"
    property color btnIcon: Qt.rgba(0.7, 0.7, 0.75, 1)
    property color btnIconHover: (sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff"
    
    Rectangle {
        id: bgRect
        anchors.fill: parent
        radius: 0
        color: mouseArea.containsMouse ? root.btnBgHover : root.btnBg
        visible: root.showBackground
        Behavior on color { ColorAnimation { duration: 200; easing.type: Easing.OutCubic } }
    }
    
    Text {
        anchors.centerIn: parent
        text: root.icon
        font.pixelSize: 14
        font.family: "sans-serif"
        color: mouseArea.containsMouse ? root.btnIconHover : root.btnIcon
        z: 1
        Behavior on color { ColorAnimation { duration: 200; easing.type: Easing.OutCubic } }
    }
    
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
    }
    
    // Watch mouse state
    property bool isHovered: mouseArea.containsMouse
    
    onIsHoveredChanged: {
        if (sidePanel) {
            if (isHovered) {
                sidePanel.isAnyToggleHovered = true
                updateAbsolutePosition()
                sidePanel.showPopover(root.popoverContent, absoluteX, absoluteY)
            } else {
                sidePanel.isAnyToggleHovered = false
                sidePanel.showPopover(null)
            }
        }
    }
    
    property real absoluteX: 0
    property real absoluteY: 0
    
    function updateAbsolutePosition() {
        if (!sidePanel) return
        // Map to the screen/root coordinates to pass to the separate window
        var pos = root.mapToItem(null, 0, 0)
        absoluteX = pos.x
        absoluteY = pos.y
    }
}

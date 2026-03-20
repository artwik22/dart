import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root
    
    // Properties
    property var screen: null
    property string imagePath: ""
    property var sharedData: null
    
    signal clicked()
    signal thumbnailClosed()
    
    implicitWidth: 220
    implicitHeight: 140
    
    // Position in bottom left (like iOS)
    anchors.bottom: true
    anchors.left: true
    
    margins {
        left: 20
        bottom: 20
    }
    
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    
    color: "transparent"
    
    // Animation state
    property real showProgress: 0.0
    property bool isClosing: false
    
    Component.onCompleted: {
        showProgress = 1.0
        autoCloseTimer.start()
    }
    
    Behavior on showProgress { NumberAnimation { duration: 450; easing.type: Easing.OutBack } }
    
    visible: true
    
    Timer {
        id: autoCloseTimer
        interval: 5000 // 5 seconds
        onTriggered: { root.close() }
    }
    
    function close() {
        if (isClosing) return
        isClosing = true
        showProgress = 0.0
        dismissTimer.start()
    }
    
    Timer {
        id: dismissTimer
        interval: 450
        onTriggered: { 
            root.thumbnailClosed()
            if (sharedData) sharedData.activeThumbnailPath = ""
            // Note: If created via Loader, Loader.active = false will destroy this.
            // If created via createObject, root.destroy() is needed.
            // We'll let the Loader handle it if possible, but for safety:
            if (!parent) root.destroy() 
        }
    }

    Rectangle {
        id: container
        anchors.fill: parent
        opacity: showProgress
        scale: 0.8 + (showProgress * 0.2)
        radius: 12
        color: (sharedData && sharedData.colorSecondary) ? sharedData.colorSecondary : "#1c1c1c"
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.1)
        clip: true
        
        Image {
            id: img
            anchors.fill: parent
            source: imagePath ? ("file://" + imagePath) : ""
            fillMode: Image.PreserveAspectFit
            asynchronous: true
        }
        
        // Hover overlay
        Rectangle {
            anchors.fill: parent
            color: ma.containsMouse ? Qt.rgba(1, 1, 1, 0.05) : "transparent"
        }
        
        MouseArea {
            id: ma
            anchors.fill: parent
            hoverEnabled: true
            onClicked: { 
                root.clicked()
                if (sharedData) {
                    sharedData.activeScreenshotPath = imagePath
                    sharedData.activeThumbnailPath = ""
                }
                if (!parent) root.destroy()
            }
            cursorShape: Qt.PointingHandCursor
        }
        
        // Close button (X)
        Rectangle {
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: 8
            width: 24
            height: 24
            radius: 12
            color: "#333333"
            border.width: 1
            border.color: Qt.rgba(1,1,1,0.1)
            visible: ma.containsMouse
            
            Text {
                anchors.centerIn: parent
                text: "󰅖"
                font.family: "Material Design Icons"
                color: "white"
                font.pixelSize: 12
            }
            MouseArea {
                anchors.fill: parent
                onClicked: { root.close() }
            }
        }
        layer.enabled: true
        layer.effect: DropShadow {
            radius: 12
            samples: 25
            color: Qt.rgba(0,0,0,0.5)
            verticalOffset: 4
        }
    }
}

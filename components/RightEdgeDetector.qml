import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

PanelWindow {
    id: edgeDetector
    
    required property var screen
    required property var sharedData
    
    property bool isMangoWM: false
    
    Timer {
        id: mangoPollingTimer
        interval: 100
        running: true
        repeat: true
        onTriggered: checkMangoEdge()
    }
    
    function checkMangoEdge() {
        if (!isMangoWM || !screen || !sharedData) return
        
        var mouseX = MouseTracker.cursorX
        var edgeThreshold = 15
        var inEdge = (screen.width - mouseX) <= edgeThreshold
        
        if (inEdge && !sharedData.volumeEdgeHovered) {
            sharedData.volumeEdgeHovered = true
            sharedData.volumeVisible = true
        } else if (!inEdge && sharedData.volumeEdgeHovered) {
            sharedData.volumeEdgeHovered = false
        }
    }
    
    Component.onCompleted: {
        detectWM()
    }
    
    function detectWM() {
        var tmp = "/tmp/qs_wm_check_edge"
        if (sharedData && sharedData.runCommand) {
            sharedData.runCommand(['sh', '-c', 'pgrep mango > /dev/null && echo "mango" > ' + tmp + ' || echo "hyprland" > ' + tmp], function() {
                var xhr = new XMLHttpRequest()
                xhr.open("GET", "file://" + tmp)
                xhr.onreadystatechange = function() {
                    if (xhr.readyState === XMLHttpRequest.DONE) {
                        var wm = (xhr.responseText || "").trim()
                        isMangoWM = (wm === "mango")
                    }
                }
                xhr.send()
            })
        }
    }
    
    anchors { 
        right: true
        top: true
    }
    margins { 
        right: 0
        top: (screen && screen.height) ? (screen.height - 288) / 2 : 0
    }
    implicitWidth: 8
    implicitHeight: 288
    
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qsrightedgedetector-" + (screen && screen.name ? screen.name : "0")
    exclusiveZone: 0
    
    color: "transparent"
    visible: true
    
    MouseArea {
        id: edgeMouseArea
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: 8
        height: 288
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        propagateComposedEvents: true
        enabled: !isMangoWM
        
        onEntered: {
            if (sharedData) {
                sharedData.volumeEdgeHovered = true
                sharedData.volumeVisible = true
            }
        }
        
        onExited: {
            if (sharedData) {
                sharedData.volumeEdgeHovered = false
            }
        }
        
        onHoveredChanged: {
            if (containsMouse && sharedData && !isMangoWM) {
                sharedData.volumeEdgeHovered = true
                sharedData.volumeVisible = true
            }
        }
    }
}


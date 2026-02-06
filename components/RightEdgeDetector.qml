import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: edgeDetector
    
    required property var screen
    required property var sharedData
<<<<<<< HEAD
    
    screen: edgeDetector.screen
    
=======

>>>>>>> master
    anchors { 
        right: true
        top: true
    }
    margins { 
        right: 0
<<<<<<< HEAD
        top: (screen && screen.height) ? (screen.height - 270) / 2 : 0
    }
    implicitWidth: 1  // Minimalna szerokość tylko do wykrywania hover
    implicitHeight: 270  // Tylko wysokość volume slidera (wyśrodkowany)
    
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qsrightedgedetector"
=======
        top: (screen && screen.height) ? (screen.height - 288) / 2 : 0
    }
    implicitWidth: 1  // Minimalna szerokość tylko do wykrywania hover
    implicitHeight: 288  // 80%, dopasowane do VolumeSlider
    
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qsrightedgedetector-" + (screen && screen.name ? screen.name : "0")
>>>>>>> master
    exclusiveZone: 0
    
    color: "transparent"
    visible: true
    
    // Niewidoczny obszar wykrywający hover - tylko wąski pasek przy krawędzi
    MouseArea {
        id: edgeMouseArea
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
<<<<<<< HEAD
        width: 10  // Tylko 10px przy prawej krawędzi
        height: 270  // Tylko wysokość volume slidera
=======
        width: 8
        height: 288
>>>>>>> master
        hoverEnabled: true
        acceptedButtons: Qt.NoButton  // Nie przechwytuj kliknięć
        propagateComposedEvents: true  // Pozwól na propagację zdarzeń myszy
        enabled: true
        
        onEntered: {
<<<<<<< HEAD
            console.log("RightEdgeDetector: Mouse entered, containsMouse:", containsMouse)
            if (sharedData) {
                sharedData.volumeEdgeHovered = true
                sharedData.volumeVisible = true
                console.log("RightEdgeDetector: Set volumeVisible to true")
=======
            if (sharedData) {
                sharedData.volumeEdgeHovered = true
                sharedData.volumeVisible = true
>>>>>>> master
            }
        }
        
        onExited: {
<<<<<<< HEAD
            console.log("RightEdgeDetector: Mouse exited, containsMouse:", containsMouse)
            // Oznacz, że myszka opuściła detektor
            if (sharedData) {
                sharedData.volumeEdgeHovered = false
                console.log("RightEdgeDetector: Set volumeEdgeHovered to false")
=======
            // Oznacz, że myszka opuściła detektor
            if (sharedData) {
                sharedData.volumeEdgeHovered = false
>>>>>>> master
                // Timer zamykania zostanie uruchomiony w VolumeSlider
            }
        }
        
        onHoveredChanged: {
<<<<<<< HEAD
            console.log("RightEdgeDetector: Hovered changed to", containsMouse)
=======
>>>>>>> master
            if (containsMouse && sharedData) {
                sharedData.volumeEdgeHovered = true
                sharedData.volumeVisible = true
            }
        }
        
        onPositionChanged: function(mouse) {
            // Upewnij się, że slider jest widoczny gdy myszka jest nad detektorem
            if (containsMouse && sharedData) {
                if (!sharedData.volumeVisible) {
<<<<<<< HEAD
                    console.log("RightEdgeDetector: Mouse moved over detector, showing slider")
=======
>>>>>>> master
                    sharedData.volumeVisible = true
                }
                sharedData.volumeEdgeHovered = true
            }
        }
    }
}


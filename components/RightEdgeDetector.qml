import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: edgeDetector
    
    required property var screen
    required property var sharedData

    anchors { 
        right: true
        top: true
    }
    margins { 
        right: 0
        top: (screen && screen.height) ? (screen.height - 288) / 2 : 0
    }
    implicitWidth: 1  // Minimalna szerokość tylko do wykrywania hover
    implicitHeight: 288  // 80%, dopasowane do VolumeSlider
    
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qsrightedgedetector-" + (screen && screen.name ? screen.name : "0")
    exclusiveZone: 0
    
    color: "transparent"
    visible: true
    
    // Niewidoczny obszar wykrywający hover - tylko wąski pasek przy krawędzi
    MouseArea {
        id: edgeMouseArea
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: 8
        height: 288
        hoverEnabled: true
        acceptedButtons: Qt.NoButton  // Nie przechwytuj kliknięć
        propagateComposedEvents: true  // Pozwól na propagację zdarzeń myszy
        enabled: true
        
        onEntered: {
            if (sharedData) {
                sharedData.volumeEdgeHovered = true
                sharedData.volumeVisible = true
            }
        }
        
        onExited: {
            // Oznacz, że myszka opuściła detektor
            if (sharedData) {
                sharedData.volumeEdgeHovered = false
                // Timer zamykania zostanie uruchomiony w VolumeSlider
            }
        }
        
        onHoveredChanged: {
            if (containsMouse && sharedData) {
                sharedData.volumeEdgeHovered = true
                sharedData.volumeVisible = true
            }
        }
        
        onPositionChanged: function(mouse) {
            // Upewnij się, że slider jest widoczny gdy myszka jest nad detektorem
            if (containsMouse && sharedData) {
                if (!sharedData.volumeVisible) {
                    sharedData.volumeVisible = true
                }
                sharedData.volumeEdgeHovered = true
            }
        }
    }
}


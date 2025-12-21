import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: edgeDetector
    
    required property var screen
    required property var sharedData
    
    screen: edgeDetector.screen
    
    anchors { right: true }
    margins { right: 0 }
    implicitWidth: 5  // Bardzo cienki pasek do wykrywania
    implicitHeight: screen ? screen.height : 1080
    
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qsrightedgedetector"
    exclusiveZone: 0
    
    color: "transparent"
    
    // Niewidoczny obszar wykrywający hover
    MouseArea {
        id: edgeMouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton  // Nie przechwytuj kliknięć
        
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
    }
}


import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: edgeDetector
    
    required property var screen
    required property var sharedData
    
    screen: edgeDetector.screen
    
    anchors { top: true }
    margins { top: 0 }
    implicitWidth: screen ? screen.width : 1920
    implicitHeight: 5  // Bardzo cienki pasek do wykrywania
    
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qsedgedetector"
    exclusiveZone: 0
    
    color: "transparent"
    
    // TopEdgeDetector wyłączony - menu otwiera się tylko przez skrót klawiszowy
    // MouseArea pozostaje dla kompatybilności, ale nie wykonuje żadnych akcji
    MouseArea {
        id: edgeMouseArea
        anchors.fill: parent
        hoverEnabled: false
        acceptedButtons: Qt.NoButton
        enabled: false  // Wyłączony
    }
}


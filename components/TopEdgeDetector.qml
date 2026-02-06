import QtQuick
import Quickshell
import Quickshell.Wayland

    PanelWindow {
    id: edgeDetector
    
    required property var screen
    required property var sharedData

    anchors { top: true }
    margins { top: 0 }
    implicitWidth: screen ? screen.width : 2160
    implicitHeight: 5  // Bardzo cienki pasek do wykrywania
    
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qsedgedetector-" + (screen && screen.name ? screen.name : "0")
    exclusiveZone: 0
    
    color: "transparent"
    
    // TopEdgeDetector wyłączony - menu otwiera się tylko przez skrót klawiszowy
    // Zmieniamy na false aby nie blokowało kliknięć (bo visible=true mapuje okno)
    visible: false 

    MouseArea {
        id: edgeMouseArea
        anchors.fill: parent
        hoverEnabled: false
        acceptedButtons: Qt.NoButton
        enabled: false  // Wyłączony
    }
}


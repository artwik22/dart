import QtQuick
import Quickshell
import Quickshell.Wayland

<<<<<<< HEAD
PanelWindow {
=======
    PanelWindow {
>>>>>>> master
    id: edgeDetector
    
    required property var screen
    required property var sharedData
<<<<<<< HEAD
    
    screen: edgeDetector.screen
    
    anchors { top: true }
    margins { top: 0 }
    implicitWidth: screen ? screen.width : 1920
    implicitHeight: 5  // Bardzo cienki pasek do wykrywania
    
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qsedgedetector"
=======

    anchors { top: true }
    margins { top: 0 }
    implicitWidth: screen ? screen.width : 2160
    implicitHeight: 5  // Bardzo cienki pasek do wykrywania
    
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qsedgedetector-" + (screen && screen.name ? screen.name : "0")
>>>>>>> master
    exclusiveZone: 0
    
    color: "transparent"
    
    // TopEdgeDetector wyłączony - menu otwiera się tylko przez skrót klawiszowy
<<<<<<< HEAD
    // MouseArea pozostaje dla kompatybilności, ale nie wykonuje żadnych akcji
=======
    // Zmieniamy na false aby nie blokowało kliknięć (bo visible=true mapuje okno)
    visible: false 

>>>>>>> master
    MouseArea {
        id: edgeMouseArea
        anchors.fill: parent
        hoverEnabled: false
        acceptedButtons: Qt.NoButton
        enabled: false  // Wyłączony
    }
}


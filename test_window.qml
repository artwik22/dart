import Quickshell
import Quickshell.Wayland
import QtQuick

PanelWindow {
    width: 500
    height: 500
    anchors.centerIn: true
    WlrLayershell.layer: WlrLayer.Overlay
    
    Rectangle {
        anchors.fill: parent
        color: "red"
        Text {
            anchors.centerIn: parent
            text: "QUICKSHELL TEST"
            color: "white"
            font.pixelSize: 32
        }
    }
}

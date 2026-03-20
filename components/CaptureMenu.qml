import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

PanelWindow {
    id: root
    
    property var sharedData: null
    property var screen: null
    
    anchors { top: true; bottom: true; left: true; right: true }
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: (sharedData && sharedData.captureMenuVisible) ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    
    property real showProgress: (sharedData && sharedData.captureMenuVisible) ? 1.0 : 0.0
    Behavior on showProgress { NumberAnimation { duration: 450; easing.type: Easing.OutCubic } }

    visible: showProgress > 0.01
    color: "transparent"
    
    // ── Design Tokens ──
    property color dsAccent: (sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff"
    property color dsSurface: (sharedData && sharedData.colorSecondary) ? Qt.rgba(sharedData.colorSecondary.r, sharedData.colorSecondary.g, sharedData.colorSecondary.b, 1.0) : "#141414"
    property color dsBorder: Qt.rgba(1, 1, 1, 0.1)
    property real dsRadius: (sharedData && sharedData.quickshellBorderRadius !== undefined) ? sharedData.quickshellBorderRadius : 16

    // Recording state
    property bool isRecording: false
    
    Timer {
        interval: 1000; running: root.visible; repeat: true
        onTriggered: {
            if (sharedData && sharedData.runCommand) {
                sharedData.runCommand(['sh', '-c', 'pgrep -x wf-recorder > /dev/null && echo 1 || echo 0'], function(out) {
                    isRecording = out.trim() === "1"
                })
            }
        }
    }
    
    MouseArea {
        anchors.fill: parent
        onClicked: sharedData.captureMenuVisible = false
    }
    
    Rectangle {
        id: menuContainer
        width: 400; height: 100
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top; anchors.topMargin: 40
        radius: dsRadius
        color: dsSurface
        
        scale: 0.95 + (showProgress * 0.05)
        opacity: showProgress
        
        border.width: 1
        border.color: dsBorder
        
        RowLayout {
            anchors.centerIn: parent
            spacing: 20
            
            CaptureButton {
                icon: "󰆞"; label: "Area"; tooltip: "Select area"
                onClicked: { runCapture(""); close() }
            }
            CaptureButton {
                icon: "󰍹"; label: "Screen"; tooltip: "Full screen"
                onClicked: { runCapture("--full"); close() }
            }
            CaptureButton {
                icon: "󰖲"; label: "Window"; tooltip: "Active window"
                onClicked: { runCapture("--window"); close() }
            }
            
            Rectangle { 
                width: 1; height: 32; color: Qt.rgba(1, 1, 1, 0.08); Layout.leftMargin: 4; Layout.rightMargin: 4 
            }
            
            CaptureButton {
                icon: "󰏫"; label: "Edit"; tooltip: "Capture & Edit"
                onClicked: { runCapture("--edit"); close() }
            }
            
            CaptureButton {
                icon: isRecording ? "󰓛" : "󰑊"; label: isRecording ? "Stop" : "Record"
                tooltip: isRecording ? "Stop recording" : "Record screen"
                highlight: isRecording; highlightColor: "#ff4444"
                onClicked: {
                    if (isRecording) {
                        sharedData.runCommand(['sh', '-c', 'pkill -INT wf-recorder || pkill wf-recorder'])
                    } else {
                        sharedData.runCommand(['sh', '-c', 'mkdir -p ~/Videos/Recordings && wf-recorder -f ~/Videos/Recordings/rec_$(date +%H%M%S).mp4 &'])
                        notify("Recording Started", "Video is being saved to ~/Videos/Recordings")
                    }
                    close()
                }
            }
        }
    }

    function runCapture(args) {
        sharedData.runCommand(['sh', '-c', 'sleep 0.3 && /home/iartwik/.config/alloy/dart/scripts/take-screenshot.sh ' + args + ' &'])
    }
    
    function close() { sharedData.captureMenuVisible = false }
    function notify(title, msg) { sharedData.runCommand(['notify-send', '-a', 'Alloy', title, msg]) }

    component CaptureButton : Rectangle {
        id: btn
        property string icon: ""
        property string label: ""
        property string tooltip: ""
        property bool highlight: false
        property color highlightColor: root.dsAccent
        signal clicked()

        width: 72; height: 72; radius: 12
        color: ma.containsMouse ? Qt.rgba(1, 1, 1, 0.04) : "transparent"
        border.width: 1
        border.color: ma.containsMouse ? Qt.rgba(1, 1, 1, 0.06) : "transparent"
        Behavior on color { ColorAnimation { duration: 150 } }

        ColumnLayout {
            anchors.centerIn: parent; spacing: 4
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: btn.icon; font.family: "Material Design Icons"; font.pixelSize: 28
                color: btn.highlight ? btn.highlightColor : (ma.containsMouse ? dsAccent : "#ffffff")
                opacity: (btn.highlight || ma.containsMouse) ? 1.0 : 0.7
                Behavior on color { ColorAnimation { duration: 150 } }
                scale: ma.pressed ? 0.9 : 1.0
                Behavior on scale { NumberAnimation { duration: 100 } }
            }
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: btn.label; color: "#ffffff"
                opacity: ma.containsMouse ? 1.0 : 0.4
                font.pixelSize: 11; font.family: "Inter"; font.weight: Font.SemiBold
            }
        }

        MouseArea {
            id: ma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
            onClicked: btn.clicked()
        }
        
        // Premium Tooltip
        Rectangle {
            anchors.top: parent.bottom; anchors.topMargin: 12; anchors.horizontalCenter: parent.horizontalCenter
            width: ttText.width + 16; height: 28; radius: 8; color: dsSurface; border.width: 1; border.color: dsBorder; opacity: ma.containsMouse ? 1 : 0
            visible: opacity > 0; Behavior on opacity { NumberAnimation { duration: 150 } }
            
            layer.enabled: true
            layer.effect: DropShadow { radius: 8; samples: 17; color: Qt.rgba(0,0,0,0.3); verticalOffset: 2 }

            Text { id: ttText; anchors.centerIn: parent; text: btn.tooltip; color: "#ffffff"; font.pixelSize: 10; font.family: "Inter"; font.weight: Font.Medium }
        }
    }
}

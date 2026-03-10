import QtQuick
import QtQml
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "."

PanelWindow {
    id: captureMenuRoot
    
    property var sharedData: null
    property var screen: null
    
    // Position it in the center or bottom of the screen
    anchors { 
        top: true
        bottom: true
        left: true
        right: true
    }
    
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: (sharedData && sharedData.captureMenuVisible) ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    exclusiveZone: 0
    
    // Animation readiness
    property bool animationReady: false
    Component.onCompleted: {
        animationReady = true
    }

    // Animation driver
    property real showProgress: 0
    Binding on showProgress {
        when: animationReady
        value: (sharedData && sharedData.captureMenuVisible) ? 1.0 : 0.0
    }
    Behavior on showProgress {
        NumberAnimation { 
            duration: 350
            easing.type: Easing.OutBack
            easing.overshoot: 1.15
        }
    }

    visible: showProgress > 0.0
    color: "transparent"
    
    // Helper function for colors
    function getTransparentColor(hex, alpha) {
        if (!hex || hex.length < 7) return Qt.rgba(1, 1, 1, alpha);
        var r = parseInt(hex.substring(1, 3), 16) / 255;
        var g = parseInt(hex.substring(3, 5), 16) / 255;
        var b = parseInt(hex.substring(5, 7), 16) / 255;
        return Qt.rgba(r, g, b, alpha);
    }
    
    // Base colors
    property string colorBackground: (sharedData && sharedData.colorBackground) ? sharedData.colorBackground : "#0a0a0a"
    property string colorPrimary: (sharedData && sharedData.colorPrimary) ? sharedData.colorPrimary : "#1a1a1a"
    property string colorSecondary: (sharedData && sharedData.colorSecondary) ? sharedData.colorSecondary : "#141414"
    property string colorAccent: (sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff"
    property string colorText: (sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff"
    
    // Recording state
    property bool isRecording: false
    
    // Check if recording is active
    Timer {
        interval: 1000
        running: sharedData && sharedData.captureMenuVisible
        repeat: true
        onTriggered: {
            if (sharedData && sharedData.runCommand) {
                sharedData.runCommand(['sh', '-c', 'pgrep -x wf-recorder > /dev/null && echo 1 || echo 0 > /tmp/quickshell_rec_status'])
                if (sharedData.setTimeout) sharedData.setTimeout(function() {
                        var xhr = new XMLHttpRequest()
                        xhr.open("GET", "file:///tmp/quickshell_rec_status")
                        xhr.onreadystatechange = function() {
                            if (xhr.readyState === XMLHttpRequest.DONE) {
                                isRecording = xhr.responseText.trim() === "1"
                            }
                        }
                        xhr.send()
                }, 100)
            }
        }
    }
    
    MouseArea {
        anchors.fill: parent
        enabled: sharedData && sharedData.captureMenuVisible
        hoverEnabled: true    
        onClicked: {
            if (sharedData) sharedData.captureMenuVisible = false
        }
    }
    
    Item {
        id: menuContainer
        width: 320
        height: 80
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 15
        
        opacity: showProgress
        enabled: showProgress > 0.02
        focus: showProgress > 0.02
        scale: 0.9 + (showProgress * 0.1)
        transformOrigin: Item.Top
        transform: Translate {
            y: (showProgress - 1.0) * 40
        }
        
        Rectangle {
            id: menuBackground
            anchors.fill: parent
            radius: (sharedData && sharedData.quickshellBorderRadius) ? sharedData.quickshellBorderRadius : 12
            color: colorSecondary 
            border.width: 0 // Removed border as requested
        }
        
        MouseArea {
            anchors.fill: parent
            onClicked: {} // Block clicks from closing menu
        }

        Row {
            anchors.centerIn: parent
            spacing: 20
            
            // Area Screenshot
            CaptureButton {
                iconName: "󰆞"
                tooltipText: "Area Snippet"
                iconColor: colorText
                bgHoverColor: colorPrimary
                onClicked: {
                    if (sharedData && sharedData.runCommand) {
                        sharedData.runCommand(['sh', '-c', 'sleep 0.2 && /home/iartwik/.config/alloy/dart/scripts/take-screenshot.sh &'])
                    }
                    if (sharedData) sharedData.captureMenuVisible = false
                }
            }
            
            // Full Screen
            CaptureButton {
                iconName: "󰍹"
                tooltipText: "Full Screen"
                iconColor: colorText
                bgHoverColor: colorPrimary
                onClicked: {
                    if (sharedData && sharedData.runCommand) {
                        // Use the existing screenshot script
                        sharedData.runCommand(['sh', '-c', 'sleep 0.2 && /home/iartwik/.config/alloy/dart/screenshot.sh --full &'])
                    }
                    if (sharedData) sharedData.captureMenuVisible = false
                }
            }
            
            Rectangle {
                width: 1
                height: 40
                color: Qt.rgba(1, 1, 1, 0.1)
                anchors.verticalCenter: parent.verticalCenter
            }
            
            // Record Screen
            CaptureButton {
                iconName: "󰑊"
                tooltipText: "Record Screen"
                iconColor: isRecording ? "#ff4a4a" : colorText
                bgHoverColor: colorPrimary
                onClicked: {
                    if (isRecording) return;
                    if (sharedData && sharedData.runCommand) {
                        sharedData.runCommand(['sh', '-c', 'mkdir -p ~/Videos/Recordings && notify-send -a Alloy "Recording" "Screen recording started" && wf-recorder -f ~/Videos/Recordings/recording_$(date +%Y-%m-%d_%H-%M-%S).mp4 &'])
                        isRecording = true
                    }
                    if (sharedData) sharedData.captureMenuVisible = false
                }
            }
            
            // Stop Recording
            CaptureButton {
                iconName: "󰓛"
                tooltipText: "Stop Recording"
                opacity: isRecording ? 1.0 : 0.4
                enabled: isRecording
                iconColor: colorText
                bgHoverColor: getTransparentColor("#ff4a4a", 0.3)
                onClicked: {
                    if (sharedData && sharedData.runCommand) {
                        sharedData.runCommand(['sh', '-c', 'pkill -INT wf-recorder || pkill wf-recorder && notify-send -a Alloy "Recording" "Screen recording stopped and saved"'])
                        isRecording = false
                    }
                    if (sharedData) sharedData.captureMenuVisible = false
                }
            }
        }
        
        Keys.onPressed: function(event) {
            if (event.key === Qt.Key_Escape) {
                if (sharedData) sharedData.captureMenuVisible = false
                event.accepted = true
            }
        }
    }
    
    // Internal component for the buttons
    component CaptureButton : Rectangle {
        id: btnRoot
        property string iconName: ""
        property string tooltipText: ""
        property string iconColor: "#ffffff"
        property string bgHoverColor: "#1a1a1a"
        
        width: 52
        height: 52
        radius: 10
        color: ma.containsMouse ? Qt.rgba(255, 255, 255, 0.06) : "transparent"
        
        Behavior on color { ColorAnimation { duration: 150 } }
        
        Text {
            anchors.centerIn: parent
            text: btnRoot.iconName
            font.family: "Material Design Icons"
            font.pixelSize: 26
            color: btnRoot.iconColor
            
            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
            scale: ma.pressed ? 0.9 : (ma.containsMouse ? 1.05 : 1.0)
        }
        
        MouseArea {
            id: ma
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: btnRoot.clicked()
        }
        
        // Tooltip text below
        Text {
            anchors.top: parent.bottom
            anchors.topMargin: 4
            anchors.horizontalCenter: parent.horizontalCenter
            text: btnRoot.tooltipText
            font.family: "Inter, Roboto, sans-serif"
            font.pixelSize: 10
            color: Qt.rgba(255, 255, 255, 0.6)
            opacity: ma.containsMouse ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 150 } }
        }
        
        signal clicked()
    }
}

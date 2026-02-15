import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

PanelWindow {
    id: lockScreenRoot

    required property var screen
    required property var sharedData
    property string projectPath: ""
    property string wallpaperPath: ""

    anchors {
        left: true
        top: true
        right: true
        bottom: true
    }
    implicitWidth: screen ? screen.width : 1920
    implicitHeight: screen ? screen.height : 1080

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qslockscreen-" + (screen && screen.name ? screen.name : "0")
    WlrLayershell.keyboardFocus: (sharedData && sharedData.lockScreenVisible) ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    exclusiveZone: -1

    visible: sharedData && sharedData.lockScreenVisible
    color: "transparent"

    property bool verifying: false
    property string currentHours: "00"
    property string currentMinutes: "00"
    property string currentDate: ""

    // --- Clock Logic ---
    Timer {
        id: clockTimer
        interval: 1000
        running: lockScreenRoot.visible
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            var date = new Date()
            currentHours = Qt.formatTime(date, "HH")
            currentMinutes = Qt.formatTime(date, "mm")
            currentDate = Qt.formatDate(date, "dddd, MMMM d").toUpperCase()
        }
    }

    // --- Authentication Logic ---
    Component {
        id: verifyProcessComponent
        Process {
            property string pwd: ""
            command: ["sh", "-c", "echo \"$1\" | sudo -S -k -p '' true", "--", pwd]
            
            onExited: function(exitCode) {
                lockScreenRoot.onVerifyExited(exitCode)
                destroy()
            }
        }
    }

    function verifyPassword() {
        if (verifying || !passwordField.text) return
        var pwd = passwordField.text
        verifying = true
        errorLabel.text = ""
        verifyTimeout.start()
        
        var proc = verifyProcessComponent.createObject(lockScreenRoot, { pwd: pwd })
        proc.running = true
    }

    Timer {
        id: verifyTimeout
        interval: 10000 
        repeat: false
        onTriggered: {
            if (lockScreenRoot.verifying) {
                lockScreenRoot.verifying = false
                passwordField.text = ""
                errorLabel.text = "TIMEOUT"
            }
        }
    }

    function onVerifyExited(exitCode) {
        verifyTimeout.stop()
        verifying = false
        
        if (exitCode === 0) {
            passwordField.text = ""
            if (sharedData) sharedData.lockScreenVisible = false
        } else {
            passwordField.text = ""
            errorLabel.text = "INCORRECT"
        }
    }

    // --- UI Layout (Swiss Minimalist) ---
    
    Rectangle {
        anchors.fill: parent
        color: (sharedData && sharedData.colorBackground) ? sharedData.colorBackground : "#050505"
        
        Image {
            id: wallpaper
            anchors.fill: parent
            source: lockScreenRoot.wallpaperPath ? (lockScreenRoot.wallpaperPath.startsWith("/") ? "file://" + lockScreenRoot.wallpaperPath : lockScreenRoot.wallpaperPath) : ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            smooth: true
            mipmap: true
            opacity: 0.45
            visible: lockScreenRoot.wallpaperPath !== ""
        }
    }

    Item {
        id: canvas
        anchors.fill: parent
        opacity: lockScreenRoot.visible ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 800; easing.type: Easing.OutCubic } }

        Keys.onPressed: function(event) {
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                verifyPassword()
                event.accepted = true
            }
        }

        // --- Clock Section (Asymmetric Left) ---
        Item {
            id: clockArea
            width: parent.width * 0.4
            height: parent.height
            anchors.left: parent.left
            anchors.leftMargin: 100

            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: -40
                
                opacity: lockScreenRoot.visible ? 1 : 0
                x: lockScreenRoot.visible ? 0 : -50
                Behavior on opacity { NumberAnimation { duration: 1000; easing.type: Easing.OutQuart } }
                Behavior on x { NumberAnimation { duration: 1200; easing.type: Easing.OutBack } }

                Text {
                    text: currentHours
                    font.pixelSize: 220
                    font.weight: Font.Black
                    font.family: "Inter, sans-serif"
                    color: (sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff"
                    font.letterSpacing: -10
                }

                Text {
                    text: currentMinutes
                    font.pixelSize: 220
                    font.weight: Font.Light
                    font.family: "Inter, sans-serif"
                    color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff"
                    font.letterSpacing: -10
                }
            }
        }

                // --- Interaction Section (Right) ---
                Item {
                    width: 400
                    height: 300
                    anchors.right: parent.right
                    anchors.rightMargin: 120
                    anchors.verticalCenter: parent.verticalCenter
                    visible: !(sharedData && sharedData.lockScreenNonBlocking)

                    Column {
                anchors.fill: parent
                spacing: 48
                
                opacity: lockScreenRoot.visible ? 1 : 0
                x: lockScreenRoot.visible ? 0 : 50
                Behavior on opacity { 
                    SequentialAnimation {
                        PauseAnimation { duration: 200 }
                        NumberAnimation { duration: 1000; easing.type: Easing.OutQuart } 
                    }
                }
                Behavior on x { 
                    SequentialAnimation {
                        PauseAnimation { duration: 200 }
                        NumberAnimation { duration: 1200; easing.type: Easing.OutBack } 
                    }
                }

                Column {
                    spacing: 4
                    Text {
                        text: currentDate
                        font.pixelSize: 14
                        font.weight: Font.Black
                        font.letterSpacing: 2
                        color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff"
                        opacity: 0.6
                    }
                }

                // Minimal Input Line
                Item {
                    width: parent.width
                    height: 60

                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: parent.width
                        height: 2
                        color: passwordField.activeFocus ? ((sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff") : "#33ffffff"
                        Behavior on color { ColorAnimation { duration: 300 } }
                        
                        Rectangle {
                            width: verifying ? parent.width : 0
                            height: parent.height
                            color: "white"
                            anchors.left: parent.left
                            Behavior on width { NumberAnimation { duration: 8000; easing.type: Easing.OutLinear } }
                        }
                    }

                    TextInput {
                        id: passwordField
                        anchors.fill: parent
                        anchors.bottomMargin: 8
                        font.pixelSize: 24
                        font.family: "Inter, sans-serif"
                        font.weight: Font.Medium
                        color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff"
                        verticalAlignment: TextInput.AlignVCenter
                        echoMode: TextInput.Password
                        clip: true
                        focus: lockScreenRoot.visible
                        onAccepted: lockScreenRoot.verifyPassword()
                        
                        selectionColor: (sharedData && sharedData.colorAccent) ? Qt.alpha(sharedData.colorAccent, 0.4) : "#334a9eff"
                    }

                    Text {
                        anchors.fill: passwordField
                        text: "ENTER PASSPHRASE"
                        font.pixelSize: 14
                        font.weight: Font.Bold
                        font.letterSpacing: 2
                        color: "#44ffffff"
                        verticalAlignment: Text.AlignVCenter
                        visible: passwordField.text.length === 0
                    }
                }

                Row {
                    spacing: 24
                    width: parent.width

                    Text {
                        id: errorLabel
                        text: ""
                        font.pixelSize: 12
                        font.weight: Font.Bold
                        font.letterSpacing: 1
                        color: "#ff3b3b"
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Item { Layout.fillWidth: true }

                    Button {
                        id: unlockButton
                        width: 80
                        height: 40
                        enabled: !verifying && passwordField.text.length > 0
                        onClicked: lockScreenRoot.verifyPassword()
                        anchors.verticalCenter: parent.verticalCenter

                        contentItem: Text {
                            text: verifying ? "..." : "󰁔"
                            font.pixelSize: 28
                            color: parent.enabled ? "#ffffff" : "#44ffffff"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        background: Rectangle {
                            color: "transparent"
                            border.width: 1
                            border.color: parent.activeFocus || parent.hovered ? ((sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff") : "#22ffffff"
                            radius: 20
                            Behavior on border.color { ColorAnimation { duration: 200 } }
                        }
                    }
                }
            }
        }
    }

    // --- Non-blocking dismiss logic ---
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        propagateComposedEvents: true
        
        // Grace period to avoid accidental dismiss right after opening
        Timer {
            id: dismissGraceTimer
            interval: 800
            running: lockScreenRoot.visible && sharedData.lockScreenNonBlocking
        }

        onPositionChanged: {
            if (lockScreenRoot.visible && sharedData.lockScreenNonBlocking && !dismissGraceTimer.running) {
                sharedData.lockScreenVisible = false
            }
        }
        onClicked: {
            if (lockScreenRoot.visible && sharedData.lockScreenNonBlocking && !dismissGraceTimer.running) {
                sharedData.lockScreenVisible = false
            }
        }
    }

    Item {
        focus: lockScreenRoot.visible && sharedData.lockScreenNonBlocking
        Keys.onPressed: (event) => {
            if (lockScreenRoot.visible && sharedData.lockScreenNonBlocking && !dismissGraceTimer.running) {
                sharedData.lockScreenVisible = false
                event.accepted = true
            }
        }
    }
}

import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

PanelWindow {
    id: lockScreenRoot

    required property var screen
    required property var sharedData
    property string projectPath: ""

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

    margins {
        left: 0
        top: 0
        right: 0
        bottom: 0
    }

    property bool verifying: false

    Component {
        id: verifyProcessComponent
        Process {
            property string pwd: ""
            // Using sh -c with pipe is robust for passing input
            command: ["sh", "-c", "echo \"$1\" | sudo -S -k -p '' true", "--", pwd]
            
            onStarted: {
                console.log("[LockScreen] Verification process started")
            }
            
            onExited: function(exitCode) {
                console.log("[LockScreen] Verification process exited with code:", exitCode)
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
        
        console.log("[LockScreen] Creating new verification process...")
        var proc = verifyProcessComponent.createObject(lockScreenRoot, { pwd: pwd })
        proc.running = true
    }

    Timer {
        id: verifyTimeout
        interval: 10000 
        repeat: false
        onTriggered: {
            if (lockScreenRoot.verifying) {
                console.log("[LockScreen] Verification timeout reached")
                lockScreenRoot.verifying = false
                passwordField.text = ""
                errorLabel.text = "Timeout - Try again"
            }
        }
    }

    function onVerifyExited(exitCode) {
        verifyTimeout.stop()
        verifying = false
        
        if (exitCode === 0) {
            console.log("[LockScreen] SUCCESS: Unlocking")
            passwordField.text = ""
            if (sharedData) sharedData.lockScreenVisible = false
            errorLabel.text = ""
        } else {
            console.log("[LockScreen] FAILURE: Incorrect password or system error")
            passwordField.text = ""
            errorLabel.text = "Try again"
        }
    }

    // Dark semi-transparent background
    Rectangle {
        anchors.fill: parent
        color: "#f0101010"
        opacity: 0.98
    }

    Item {
        anchors.fill: parent
        focus: lockScreenRoot.visible

        Keys.onPressed: function(event) {
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                verifyPassword()
                event.accepted = true
            }
        }

        Column {
            anchors.centerIn: parent
            spacing: 24
            width: Math.min(360, parent.width * 0.85)

            Text {
                text: "󰌾"
                font.pixelSize: 64
                color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff"
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Text {
                text: "Locked"
                font.pixelSize: 22
                font.family: "sans-serif"
                font.weight: Font.Medium
                color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff"
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Rectangle {
                width: parent.width - 0
                height: 48
                radius: (sharedData && sharedData.quickshellBorderRadius) ? sharedData.quickshellBorderRadius : 0
                color: (sharedData && sharedData.colorSecondary) ? sharedData.colorSecondary : "#1a1a1a"
                border.width: 1
                border.color: errorLabel.text ? "#c05050" : (Qt.inputMethod.keyboardVisible ? ((sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff") : "transparent")

                TextInput {
                    id: passwordField
                    anchors.fill: parent
                    anchors.margins: 14
                    font.pixelSize: 16
                    font.family: "sans-serif"
                    color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff"
                    verticalAlignment: TextInput.AlignVCenter
                    echoMode: TextInput.Password
                    clip: true
                    focus: lockScreenRoot.visible

                    onAccepted: lockScreenRoot.verifyPassword()

                    KeyNavigation.tab: unlockButton
                }
                Text {
                    anchors.fill: passwordField
                    anchors.margins: 0
                    text: "Password..."
                    font.pixelSize: 16
                    font.family: "sans-serif"
                    color: "#808080"
                    verticalAlignment: Text.AlignVCenter
                    visible: passwordField.text.length === 0
                }
            }

            Text {
                id: errorLabel
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: 13
                font.family: "sans-serif"
                color: "#e06060"
                wrapMode: Text.WordWrap
                visible: text.length > 0
            }

            Button {
                id: unlockButton
                width: parent.width
                height: 44
                enabled: !verifying && passwordField.text.length > 0
                focusPolicy: Qt.StrongFocus

                contentItem: Text {
                    text: verifying ? "Checking..." : "Unlock"
                    font.pixelSize: 15
                    font.family: "sans-serif"
                    color: (parent.pressed || !parent.enabled) ? "#888" : "#fff"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                background: Rectangle {
                    radius: (sharedData && sharedData.quickshellBorderRadius) ? sharedData.quickshellBorderRadius : 0
                    color: parent.pressed ? "#2a3a4a" : (parent.enabled && (parent.hovered || parent.activeFocus) ? ((lockScreenRoot.sharedData && lockScreenRoot.sharedData.colorAccent) ? lockScreenRoot.sharedData.colorAccent : "#4a9eff") : "#2a2a2a")
                }

                onClicked: lockScreenRoot.verifyPassword()
                KeyNavigation.tab: passwordField
            }
        }
    }
}

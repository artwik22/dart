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

    property string passwordPending: ""
    property bool verifying: false

    function verifyPassword() {
        if (verifying || !passwordField.text) return
        passwordPending = passwordField.text
        verifying = true
        errorLabel.text = ""
        verifyTimeout.start()
        // sudo -S -k: -S read password from stdin, -k reset cache so password is always required
        verifyProcess.command = ["sh", "-c", "sudo -S -k true 2>/dev/null"]
        verifyProcess.stdinEnabled = true
        verifyProcess.running = true
    }

    Timer {
        id: verifyTimeout
        interval: 6000
        repeat: false
        onTriggered: {
            if (lockScreenRoot.verifying) {
                lockScreenRoot.verifying = false
                passwordField.text = ""
                lockScreenRoot.passwordPending = ""
                errorLabel.text = "Try again"
            }
        }
    }

    function onVerifyExited(exitCode) {
        verifyTimeout.stop()
        verifying = false
        passwordField.text = ""
        passwordPending = ""
        if (exitCode === 0) {
            if (sharedData) sharedData.lockScreenVisible = false
            errorLabel.text = ""
        } else {
            errorLabel.text = "Try again"
        }
    }

    // Ciemne półprzezroczyste tło
    Rectangle {
        anchors.fill: parent
        color: "#e0101010"
        opacity: 0.97
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

    Process {
        id: verifyProcess
        stdinEnabled: false
        running: false

        onStarted: {
            if (passwordPending.length > 0) {
                verifyProcess.write(passwordPending + "\n")
            }
        }

        onExited: function(exitCode, exitStatus) {
            lockScreenRoot.onVerifyExited(exitCode)
        }
    }
}

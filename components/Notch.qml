import QtQuick
import QtQml
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Services.Notifications
import "."

PanelWindow {
    id: notchRoot

    property var sharedData: null
    property var screen: null
    property string projectPath: ""

    // ── Mode System ───────────────────────────────────────────────────
    // "none" | "capture" | "notification" | "battery"
    property string currentMode: "none"
    property bool isActive: currentMode !== "none"

    // ── Window setup ──────────────────────────────────────────────────
    anchors { top: true; left: true; right: true }
    margins { top: 0 }
    implicitWidth: screen ? screen.width : 1920
    implicitHeight: 160

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qsnotch-" + (screen && screen.name ? screen.name : "0")
    // Only intercept keyboard for Capture mode
    WlrLayershell.keyboardFocus: currentMode === "capture" ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    exclusiveZone: 0
    color: "transparent"

    // ── Animation driver ──────────────────────────────────────────────
    property bool animationReady: false
    Component.onCompleted: animationReady = true

    property real showProgress: 0
    Binding on showProgress {
        when: notchRoot.animationReady
        value: notchRoot.isActive ? 1.0 : 0.0
    }
    Behavior on showProgress {
        NumberAnimation {
            duration: 500
            easing.type: Easing.OutBack
            easing.overshoot: 1.2
        }
    }

    visible: showProgress > 0.0

    // ── Global State ──────────────────────────────────────────────────
    property bool expanded: isActive
    property bool isRecording: false

    // Base Dimensions
    readonly property int collapsedWidth: 160
    readonly property int collapsedHeight: 28
    readonly property int bottomRadius: 16

    // Target Dimensions driven by Mode
    property int targetWidth: collapsedWidth
    property int targetHeight: collapsedHeight

    onCurrentModeChanged: {
        if (currentMode === "none") {
            expanded = false;
        } else if (currentMode === "capture") {
            targetWidth = 360
            targetHeight = 110
            expanded = true
            autoHideTimer.stop()
        } else if (currentMode === "notification") {
            targetWidth = 380
            targetHeight = 72
            expanded = true
            autoHideTimer.interval = 4500
            autoHideTimer.restart()
        } else if (currentMode === "battery") {
            targetWidth = 240
            targetHeight = 44
            expanded = true
            autoHideTimer.interval = 3500
            autoHideTimer.restart()
        }
    }

    // Capture menu visibility binding
    Connections {
        target: sharedData
        ignoreUnknownSignals: true
        function onCaptureMenuVisibleChanged() {
            if (sharedData.captureMenuVisible) {
                notchRoot.currentMode = "capture"
            } else if (notchRoot.currentMode === "capture") {
                notchRoot.currentMode = "none"
            }
        }
    }

    // ── Colors ────────────────────────────────────────────────────────
    property string colorAccent: (sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff"
    property string colorText: (sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff"

    function closeNotch() {
        if (currentMode === "capture" && sharedData) {
            sharedData.captureMenuVisible = false
        }
        currentMode = "none"
    }

    // ── Auto-hide timer ───────────────────────────────────────────────
    Timer {
        id: autoHideTimer
        interval: 3000
        onTriggered: notchRoot.closeNotch()
    }

    // ── Recording status check ────────────────────────────────────────
    Timer {
        interval: 1500
        running: true  // Always run so dot is accurate if we open it
        repeat: true
        onTriggered: {
            if (sharedData && sharedData.runCommand) {
                sharedData.runCommand(['sh', '-c', 'pgrep -x wf-recorder > /dev/null && echo 1 || echo 0 > /tmp/quickshell_notch_rec'])
                if (sharedData.setTimeout) sharedData.setTimeout(function() {
                    var xhr = new XMLHttpRequest()
                    xhr.open("GET", "file:///tmp/quickshell_notch_rec")
                    xhr.onreadystatechange = function() {
                        if (xhr.readyState === XMLHttpRequest.DONE) {
                            notchRoot.isRecording = xhr.responseText.trim() === "1"
                        }
                    }
                    xhr.send()
                }, 120)
            }
        }
    }

    // ── Battery Watcher ───────────────────────────────────────────────
    property string lastBatteryStatus: ""
    Connections {
        target: sharedData
        ignoreUnknownSignals: true
        function onBatteryStatusChanged() {
            if (sharedData && sharedData.batteryStatus) {
                var currentStatus = sharedData.batteryStatus
                if (lastBatteryStatus !== "" && lastBatteryStatus !== currentStatus && currentStatus !== "Unknown") {
                    // Status changed (e.g., Discharging -> Charging)
                    if (currentMode !== "capture") {
                        currentMode = "battery"
                    }
                }
                lastBatteryStatus = currentStatus
            }
        }
    }

    // ── Notification Server & Data ────────────────────────────────────
    property string notifAppName: ""
    property string notifSummary: ""
    property string notifBody: ""
    property string notifIcon: ""

    NotificationServer {
        id: notchNotificationServer
        
        onNotification: function(notification) {
            // Respect Do Not Disturb / disable settings
            if (sharedData && !sharedData.notificationsEnabled) return;

            // Update Notification Data
            notchRoot.notifAppName = notification.appName || "System"
            notchRoot.notifSummary = notification.summary || ""
            notchRoot.notifBody = notification.body || ""
            notchRoot.notifIcon = notification.appIcon || ""

            // Open Notch if not in capture mode
            if (notchRoot.currentMode !== "capture") {
                notchRoot.currentMode = "notification"
            }
            
            // Note: Sound playing is usually handled by typical NotificationDisplay,
            // we skip it here to avoid double-playing unless needed.
        }
    }

    // ── Background click-away to dismiss ──────────────────────────────
    MouseArea {
        anchors.fill: parent
        enabled: notchRoot.isActive
        onClicked: notchRoot.closeNotch()
    }

    // ── The Notch body ────────────────────────────────────────────────
    Item {
        id: notchClipper
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        clip: true

        width: notchRoot.expanded ? notchRoot.targetWidth : notchRoot.collapsedWidth
        height: notchRoot.expanded ? notchRoot.targetHeight : notchRoot.collapsedHeight

        Behavior on width  { NumberAnimation { duration: 400; easing.type: Easing.OutExpo } }
        Behavior on height { NumberAnimation { duration: 400; easing.type: Easing.OutExpo } }

        opacity: showProgress
        // Usunięte scale i transform, by notch zawsze był "przyklejony" do krawędzi bez szpar
        
        Rectangle {
            id: notchBody
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: -notchRoot.bottomRadius
            width: parent.width
            height: parent.height + notchRoot.bottomRadius
            radius: notchRoot.bottomRadius
            color: "#000000"
        }

        // ==========================================================
        // UI: Collapsed (Fallback)
        // ==========================================================
        Row {
            id: collapsedContent
            anchors.centerIn: parent
            anchors.verticalCenterOffset: 1
            spacing: 6
            opacity: (!notchRoot.expanded && notchRoot.isActive) ? 1.0 : 0.0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 200 } }

            Rectangle {
                width: 6; height: 6; radius: 3
                color: "#ff4a4a"
                visible: notchRoot.isRecording
                anchors.verticalCenter: parent.verticalCenter
                SequentialAnimation on opacity {
                    running: notchRoot.isRecording
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.3; duration: 600 }
                    NumberAnimation { to: 1.0; duration: 600 }
                }
            }

            Text {
                text: "Active"
                font.family: "Inter, Roboto, sans-serif"
                font.pixelSize: 11
                font.weight: Font.Medium
                color: "#ffffff"
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        // ==========================================================
        // UI: Capture Mode
        // ==========================================================
        Item {
            id: captureContent
            anchors.fill: parent
            anchors.topMargin: 8
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            anchors.bottomMargin: 8
            opacity: notchRoot.currentMode === "capture" ? 1.0 : 0.0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutQuad } }

            Text {
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                text: "SCREEN CAPTURE"
                font.family: "Inter, Roboto, sans-serif"
                font.pixelSize: 9
                font.weight: Font.DemiBold
                font.letterSpacing: 1.2
                color: Qt.rgba(1, 1, 1, 0.3)
            }

            Row {
                anchors.centerIn: parent
                anchors.verticalCenterOffset: 6
                spacing: 12

                NotchButton {
                    iconText: "󰆞"
                    label: "Area"
                    accentColor: notchRoot.colorAccent
                    onClicked: {
                        if (sharedData && sharedData.runCommand)
                            sharedData.runCommand(['sh', '-c', 'sleep 0.2 && /home/iartwik/.config/alloy/dart/scripts/take-screenshot.sh &'])
                        notchRoot.closeNotch()
                    }
                }

                NotchButton {
                    iconText: "󰍹"
                    label: "Full"
                    accentColor: notchRoot.colorAccent
                    onClicked: {
                        if (sharedData && sharedData.runCommand)
                            sharedData.runCommand(['sh', '-c', 'sleep 0.2 && /home/iartwik/.config/alloy/dart/screenshot.sh --full &'])
                        notchRoot.closeNotch()
                    }
                }

                Rectangle {
                    width: 1; height: 32
                    color: Qt.rgba(1, 1, 1, 0.06)
                    anchors.verticalCenter: parent.verticalCenter
                }

                NotchButton {
                    iconText: "󰔛"
                    label: "Timer"
                    accentColor: notchRoot.colorAccent
                    onClicked: {
                        if (sharedData && sharedData.runCommand)
                            sharedData.runCommand(['sh', '-c', 'notify-send -a Alloy "Screenshot" "Capturing in 5 seconds…" && sleep 5 && /home/iartwik/.config/alloy/dart/screenshot.sh --full &'])
                        notchRoot.closeNotch()
                    }
                }

                Rectangle {
                    width: 1; height: 32
                    color: Qt.rgba(1, 1, 1, 0.06)
                    anchors.verticalCenter: parent.verticalCenter
                }

                NotchButton {
                    iconText: notchRoot.isRecording ? "󰓛" : "󰑊"
                    label: notchRoot.isRecording ? "Stop" : "Record"
                    iconColor: notchRoot.isRecording ? "#ff4a4a" : "#ffffff"
                    accentColor: notchRoot.isRecording ? "#ff4a4a" : notchRoot.colorAccent
                    onClicked: {
                        if (notchRoot.isRecording) {
                            if (sharedData && sharedData.runCommand)
                                sharedData.runCommand(['sh', '-c', 'pkill -INT wf-recorder || pkill wf-recorder && notify-send -a Alloy "Recording" "Screen recording saved"'])
                            notchRoot.isRecording = false
                        } else {
                            if (sharedData && sharedData.runCommand)
                                sharedData.runCommand(['sh', '-c', 'mkdir -p ~/Videos/Recordings && notify-send -a Alloy "Recording" "Screen recording started" && wf-recorder -f ~/Videos/Recordings/recording_$(date +%Y-%m-%d_%H-%M-%S).mp4 &'])
                            notchRoot.isRecording = true
                        }
                        notchRoot.closeNotch()
                    }
                }
            }
        } // End Capture UI
        
        // ==========================================================
        // UI: Notification Mode
        // ==========================================================
        Item {
            id: notificationContent
            anchors.fill: parent
            anchors.margins: 12
            opacity: notchRoot.currentMode === "notification" ? 1.0 : 0.0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutQuad } }

            Row {
                anchors.fill: parent
                spacing: 12

                // Icon Wrapper
                Rectangle {
                    width: 48; height: 48
                    radius: 10  // Wcześniej było 14, teraz mniejsze zaokrąglenie
                    color: "transparent" // Wcześniej było tło w kolorze accent, co mogło psuć wygląd ikony
                    anchors.verticalCenter: parent.verticalCenter
                    
                    // Fallback Icon (if no app icon provided)
                    Text {
                        text: "󱅫"
                        font.family: "Material Design Icons"
                        font.pixelSize: 24
                        color: notchRoot.colorAccent
                        anchors.centerIn: parent
                        visible: notchRoot.notifIcon === ""
                    }
                    
                    // Actual App Icon
                    Image {
                        anchors.fill: parent
                        source: notchRoot.notifIcon
                        fillMode: Image.PreserveAspectFit
                        visible: notchRoot.notifIcon !== ""
                        asynchronous: true
                        smooth: true
                        antialiasing: true
                    }
                }

                // Text Content
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 60
                    spacing: 2

                    Row {
                        spacing: 6
                        width: parent.width
                        Text {
                            text: notchRoot.notifAppName
                            font.family: "Inter, Roboto, sans-serif"
                            font.pixelSize: 10
                            font.weight: Font.DemiBold
                            color: notchRoot.colorAccent
                        }
                        Text {
                            text: "•"
                            font.family: "Inter, Roboto, sans-serif"
                            font.pixelSize: 10
                            color: Qt.rgba(1, 1, 1, 0.4)
                        }
                        Text {
                            text: notchRoot.notifSummary
                            font.family: "Inter, Roboto, sans-serif"
                            font.pixelSize: 11
                            font.weight: Font.Bold
                            color: "#ffffff"
                            elide: Text.ElideRight
                            width: parent.width - 60
                        }
                    }

                    Text {
                        text: notchRoot.notifBody
                        font.family: "Inter, Roboto, sans-serif"
                        font.pixelSize: 11
                        color: Qt.rgba(1, 1, 1, 0.7)
                        elide: Text.ElideRight
                        maximumLineCount: 1
                        width: parent.width
                    }
                }
            }
        } // End Notification UI

        // ==========================================================
        // UI: Battery Mode
        // ==========================================================
        Item {
            id: batteryContent
            anchors.fill: parent
            anchors.margins: 10
            opacity: notchRoot.currentMode === "battery" ? 1.0 : 0.0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutQuad } }

            Row {
                anchors.centerIn: parent
                spacing: 10

                Text {
                    text: (sharedData && sharedData.batteryStatus === "Charging") ? "󰂄" : "󰁹"
                    font.family: "Material Design Icons"
                    font.pixelSize: 22
                    color: (sharedData && sharedData.batteryStatus === "Charging") ? "#2cd067" : "#ffffff"
                    anchors.verticalCenter: parent.verticalCenter
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 0
                    
                    Text {
                        text: (sharedData && sharedData.batteryPct !== undefined) ? sharedData.batteryPct + "%" : "--%"
                        font.family: "Inter, Roboto, sans-serif"
                        font.pixelSize: 12
                        font.weight: Font.Bold
                        color: "#ffffff"
                    }
                    Text {
                        text: (sharedData && sharedData.batteryStatus) ? sharedData.batteryStatus : "Unknown"
                        font.family: "Inter, Roboto, sans-serif"
                        font.pixelSize: 9
                        font.weight: Font.Medium
                        color: (sharedData && sharedData.batteryStatus === "Charging") ? "#2cd067" : Qt.rgba(1, 1, 1, 0.5)
                    }
                }
            }
        } // End Battery UI

        // ── Mouse interaction ─────────────────────────────────────
        MouseArea {
            id: notchMouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton

            // Only auto-hide logic for notifications/battery.
            // Capture menu must be closed explicitly or via background click.
            onEntered: {
                if (notchRoot.currentMode !== "capture") {
                    autoHideTimer.stop()
                }
            }
            onExited: {
                if (notchRoot.currentMode !== "capture") {
                    autoHideTimer.restart()
                }
            }
            onClicked: {
                // If it's a notification, close it immediately on click
                if (notchRoot.currentMode === "notification" || notchRoot.currentMode === "battery") {
                    notchRoot.closeNotch()
                } else if (notchRoot.currentMode === "capture") {
                    // Do nothing for capture background click, let buttons handle it
                }
            }
        }

        // ── Keyboard ──────────────────────────────────────────────
        Keys.onPressed: function(event) {
            if (event.key === Qt.Key_Escape) {
                notchRoot.closeNotch()
                event.accepted = true
            }
        }
    }

    // ── Internal NotchButton component ────────────────────────────────
    component NotchButton : Item {
        id: nbRoot
        property string iconText: ""
        property string label: ""
        property string iconColor: "#ffffff"
        property string accentColor: "#4a9eff"
        signal clicked()

        width: 50; height: 54

        Rectangle {
            id: nbBg
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            width: 42; height: 42
            radius: 10
            color: nbMa.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
            Behavior on color { ColorAnimation { duration: 150 } }

            Text {
                anchors.centerIn: parent
                text: nbRoot.iconText
                font.family: "Material Design Icons"
                font.pixelSize: 22
                color: nbRoot.iconColor
                scale: nbMa.pressed ? 0.88 : (nbMa.containsMouse ? 1.08 : 1.0)
                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
            }

            MouseArea {
                id: nbMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: nbRoot.clicked()
            }
        }

        Text {
            anchors.top: nbBg.bottom
            anchors.topMargin: 2
            anchors.horizontalCenter: parent.horizontalCenter
            text: nbRoot.label
            font.family: "Inter, Roboto, sans-serif"
            font.pixelSize: 9
            font.weight: Font.Medium
            color: Qt.rgba(1, 1, 1, 0.5)
            opacity: nbMa.containsMouse ? 1.0 : 0.7
            Behavior on opacity { NumberAnimation { duration: 150 } }
        }
    }
}

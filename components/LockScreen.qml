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

    // --- Widget Data Properties ---
    property string weatherTemp: "--"
    property string weatherCondition: ""
    property int batteryPercent: -1
    property bool isCharging: false
    property bool mpPlaying: false
    property string mpTitle: ""
    property string mpArtist: ""
    property string mpArt: ""

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

    // --- Non-blocking dismiss logic (Background MouseArea) ---
    // Placed here to be BEHIND the interactive canvas in Z-order
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true // Required for onPositionChanged
        // Only enable if we are in non-blocking mode, otherwise it steals clicks!
        enabled: sharedData && sharedData.lockScreenNonBlocking

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
                    height: parent.height
                    anchors.right: parent.right
                    anchors.rightMargin: 120
                    anchors.verticalCenter: parent.verticalCenter
                    visible: !(sharedData && sharedData.lockScreenNonBlocking) || (sharedData && sharedData.screensaverWidgetsEnabled)

                    // --- Widget Logic ---
                    property string weatherTemp: "--"
                    property string weatherCondition: ""
                    property int batteryPercent: -1
                    property bool isCharging: false
                    property string mpTitle: ""
                    property string mpArtist: ""
                    property string mpArt: ""
                    property bool mpPlaying: false
                    property int mpLength: 0
                    property int mpPosition: 0

                    // Weather Timer
                    Timer {
                        interval: 900000 // 15 mins
                        repeat: true
                        running: lockScreenRoot.visible && (sharedData && sharedData.lockscreenWeatherEnabled === true)
                        triggeredOnStart: true
                        onTriggered: {
                            // console.warn("LockScreen: Weather Timer Triggered")
                            var query = (sharedData && sharedData.weatherLocation) ? sharedData.weatherLocation : ""
                            if (sharedData && sharedData.runCommand) {
                                sharedData.runCommand(['sh','-c','curl -s "wttr.in/' + query + '?format=%t+%C" 2>/dev/null | head -1 > /tmp/quickshell_lock_weather || echo "15°C Clear" > /tmp/quickshell_lock_weather'], function() {
                                    // console.warn("LockScreen: Weather Command Done")
                                    var xhr = new XMLHttpRequest()
                                    xhr.open("GET", "file:///tmp/quickshell_lock_weather?t=" + new Date().getTime())
                                    xhr.onreadystatechange = function() {
                                        if (xhr.readyState === XMLHttpRequest.DONE) {
                                            var weather = (xhr.responseText || "").trim()
                                            // console.warn("LockScreen: Weather Read: " + weather)
                                            var parts = weather.split(" ")
                                            if (parts.length > 0) weatherTemp = parts[0]
                                            if (parts.length > 1) weatherCondition = parts.slice(1).join(" ")
                                        }
                                    }
                                    xhr.send()
                                })
                            } else {
                                console.warn("LockScreen: sharedData.runCommand missing!")
                            }
                        }
                    }

                    // Battery Timer
                    Timer {
                        id: batteryTimer
                        interval: 5000
                        repeat: true
                        running: lockScreenRoot.visible && (sharedData && (sharedData.lockscreenBatteryEnabled === true || sharedData.lockscreenBatteryEnabled === undefined))
                        triggeredOnStart: true
                        onTriggered: {
                            // console.warn("LockScreen: Battery Timer Triggered")
                            if (sharedData && sharedData.runCommand) {
                                // Use EXACT logic from Dashboard.qml which works for user
                                var cmd = "(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null; cat /sys/class/power_supply/BAT*/status 2>/dev/null) | head -2"
                                sharedData.runCommand(['sh','-c', cmd + " > /tmp/quickshell_lock_battery"], function() {
                                    // console.warn("LockScreen: Battery Command Done")
                                    var xhr = new XMLHttpRequest()
                                    xhr.open("GET", "file:///tmp/quickshell_lock_battery?t=" + new Date().getTime())
                                    xhr.onreadystatechange = function() {
                                        if (xhr.readyState === XMLHttpRequest.DONE) {
                                            var text = (xhr.responseText || "").trim()
                                            // console.warn("LockScreen: Battery Read: " + text.replace(/\n/g, "|")) 
                                            
                                            var lines = text.split('\n')
                                            if (lines.length > 0) {
                                                // First line is capacity
                                                var rawP = lines[0].trim()
                                                var p = parseInt(rawP, 10)
                                                // If valid number 0-100, use it. Otherwise -1 (error state)
                                                if (!isNaN(p) && p >= 0 && p <= 100) {
                                                    batteryPercent = p
                                                } else {
                                                    batteryPercent = 0
                                                }
                                            }
                                            
                                            isCharging = false
                                            if (lines.length > 1) {
                                                // Second line is status
                                                var status = lines[1].trim().toLowerCase()
                                                // Common statuses: Charging, Discharging, Full, Not charging, Unknown
                                                if (status === "charging" || status === "full") {
                                                    isCharging = true
                                                }
                                            }
                                        }
                                    }
                                    xhr.send()
                                })
                            } else {
                                console.warn("LockScreen: sharedData.runCommand missing for Battery!")
                            }
                        }
                    }

                    // Media Timer
                    Timer {
                        interval: 1000
                        repeat: true
                        running: lockScreenRoot.visible && (sharedData && (sharedData.lockscreenMediaEnabled === true || sharedData.lockscreenMediaEnabled === undefined))
                        triggeredOnStart: true
                        onTriggered: {
                            if (sharedData && sharedData.runCommand) {
                                // Use the same script as Dashboard for consistency
                                var scriptPath = "${QUICKSHELL_PROJECT_PATH:-$HOME/.config/alloy/dart}/scripts/get-player-metadata.sh"
                                // We use a unique tmp file to avoid race conditions with Dashboard
                                var cmd = 'bash "' + scriptPath + '" > /tmp/quickshell_lock_media_raw; cat /tmp/quickshell_player_info > /tmp/quickshell_lock_media'
                                
                                sharedData.runCommand(["sh", "-c", cmd], function() {
                                    var xhr = new XMLHttpRequest()
                                    xhr.open("GET", "file:///tmp/quickshell_lock_media?t=" + new Date().getTime())
                                    xhr.onreadystatechange = function() {
                                        if (xhr.readyState === XMLHttpRequest.DONE) {
                                            var txt = xhr.responseText || ""
                                            // console.warn("LockScreen Media Raw: " + txt.replace(/\n/g, "\\n"))
                                            if (txt.trim() === "") {
                                                mpPlaying = false
                                                mpTitle = "" // Clear title to hide widget if nothing playing
                                                return
                                            }
                                            
                                            // Format: artist|###|title|###|album|###|artUrl|###|length|###|status
                                            var lines = txt.split("|###|")
                                            if (lines.length < 6) return
                                            
                                            mpArtist = lines[0] ? lines[0].trim() : ""
                                            mpTitle = lines[1] ? lines[1].trim() : ""
                                            // console.warn("LockScreen Media Parsed: " + mpTitle + " by " + mpArtist)
                                            
                                            var art = lines[3] ? lines[3].trim() : ""
                                            if (art.indexOf("file://") === 0) mpArt = art.replace("file://", "")
                                            else if (art.indexOf("http") === 0) mpArt = art
                                            else mpArt = ""
                                            
                                            var status = (lines[5] || "").trim().toLowerCase()
                                            mpPlaying = (status === "playing")
                                        }
                                    }
                                    xhr.send()
                                })
                            }
                        }
                    }

                    // --- Layout ---
                    Column {
                        anchors.centerIn: parent
                        spacing: 24
                        width: parent.width

                        opacity: lockScreenRoot.visible ? 1 : 0
                        x: lockScreenRoot.visible ? 0 : 50
                        Behavior on opacity { NumberAnimation { duration: 1000; easing.type: Easing.OutQuart } }
                        Behavior on x { NumberAnimation { duration: 1200; easing.type: Easing.OutBack } }

                        // 1. Date (Always visible if Calendar enabled)
                        Item {
                            width: parent.width
                            height: visible ? 60 : 0
                            visible: (sharedData && (sharedData.lockscreenCalendarEnabled === true || sharedData.lockscreenCalendarEnabled === undefined))
                            clip: true
                            
                            Behavior on height { NumberAnimation { duration: 300 } }

                            Column {
                                anchors.centerIn: parent
                                spacing: 4
                                Text {
                                    text: currentDate
                                    font.pixelSize: 22
                                    font.weight: Font.Bold
                                    font.family: "Inter, sans-serif"
                                    color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff"
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }
                            }
                        }

                        // 2. Weather, Battery, Network Row
                        Row {
                            width: parent.width
                            spacing: 12
                            height: 80
                            
                            // Debug only once on complete if needed, heavily reduced logs for production feel
                            /*
                            Component.onCompleted: {
                                console.warn("LockScreen: Checking Widget Flags")
                                if (sharedData) {
                                    console.warn("LockScreen: Weather Enabled = " + sharedData.lockscreenWeatherEnabled)
                                    console.warn("LockScreen: Battery Enabled = " + sharedData.lockscreenBatteryEnabled)
                                    console.warn("LockScreen: Network Enabled = " + sharedData.lockscreenNetworkEnabled)
                                } else {
                                    console.warn("LockScreen: sharedData is null!")
                                }
                                console.warn("LockScreen: Visible Count = " + visibleCount)
                                console.warn("LockScreen: Item Width = " + itemWidth)
                            }
                            */

                            property int visibleCount: (visibleWeather ? 1 : 0) + (visibleBattery ? 1 : 0) + (visibleNetwork ? 1 : 0)
                            // Default to true if undefined to ensure they show up initially
                            property bool visibleWeather: (sharedData && (sharedData.lockscreenWeatherEnabled === true || sharedData.lockscreenWeatherEnabled === undefined))
                            property bool visibleBattery: (sharedData && (sharedData.lockscreenBatteryEnabled === true || sharedData.lockscreenBatteryEnabled === undefined))
                            property bool visibleNetwork: (sharedData && (sharedData.lockscreenNetworkEnabled === true || sharedData.lockscreenNetworkEnabled === undefined))
                            property real itemWidth: visibleCount > 0 ? (width - (spacing * (visibleCount - 1))) / visibleCount : 0
                            
                            // Weather
                            Rectangle {
                                width: parent.itemWidth
                                height: parent.height
                                radius: 16
                                color: Qt.rgba(0,0,0,0.3)
                                visible: parent.visibleWeather
                                clip: true
                                
                                Row {
                                    anchors.centerIn: parent
                                    spacing: 8
                                    Text {
                                        text: {
                                            var c = weatherCondition.toLowerCase()
                                            if (c.indexOf("clear") !== -1 || c.indexOf("sun") !== -1) return "󰖙"
                                            if (c.indexOf("cloud") !== -1) return "󰖐"
                                            if (c.indexOf("rain") !== -1) return "󰖗"
                                            return "󰖕"
                                        }
                                        font.pixelSize: 22
                                        color: (sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff"
                                    }
                                    Column {
                                        anchors.verticalCenter: parent.verticalCenter
                                        Text {
                                            text: weatherTemp
                                            font.pixelSize: 18
                                            font.weight: Font.Bold
                                            color: "#ffffff"
                                        }
                                    }
                                }
                            }

                            // Battery
                            Rectangle {
                                width: parent.itemWidth
                                height: parent.height
                                radius: 16
                                color: Qt.rgba(0,0,0,0.3)
                                visible: parent.visibleBattery
                                clip: true
                                
                                Row {
                                    anchors.centerIn: parent
                                    spacing: 8
                                    Text {
                                        text: isCharging ? "⚡" : ""
                                        font.pixelSize: 22
                                        color: isCharging ? "#00ff41" : ((batteryPercent < 20) ? "#ff3b3b" : "#ffffff")
                                    }
                                    Column {
                                        anchors.verticalCenter: parent.verticalCenter
                                        Text {
                                            text: batteryPercent + "%"
                                            font.pixelSize: 18
                                            font.weight: Font.Bold
                                            color: "#ffffff"
                                        }
                                    }
                                }
                            }

                            // Network
                            Rectangle {
                                width: parent.itemWidth
                                height: parent.height
                                radius: 16
                                color: Qt.rgba(0,0,0,0.3)
                                visible: parent.visibleNetwork
                                clip: true
                                
                                property bool isConnected: false
                                
                                Timer {
                                    interval: 5000
                                    repeat: true
                                    running: parent.visible && lockScreenRoot.visible
                                    triggeredOnStart: true
                                    onTriggered: {
                                        // console.warn("LockScreen: Network Timer Triggered")
                                        if (sharedData && sharedData.runCommand) {
                                            // NEW: Check default route to verify true connectivity, not just link status.
                                            // If that fails, check if we have an IP address (excluding loopback).
                                            var cmd = "ip route | grep default | head -1 || ip addr | grep 'inet ' | grep -v '127.0.0.1' | head -1 || echo 'down'"
                                            sharedData.runCommand(['sh', '-c', cmd + ' > /tmp/quickshell_lock_net'], function() {
                                                // console.warn("LockScreen: Network Command Done")
                                                var xhr = new XMLHttpRequest()
                                                xhr.open("GET", "file:///tmp/quickshell_lock_net?t=" + new Date().getTime())
                                                xhr.onreadystatechange = function() {
                                                    if (xhr.readyState === XMLHttpRequest.DONE) {
                                                        var state = (xhr.responseText || "").trim()
                                                        // If output is 'down' or empty -> disconnected. Otherwise connected.
                                                        parent.isConnected = (state !== "down" && state !== "")
                                                    }
                                                }
                                                xhr.send()
                                            })
                                        }
                                    }
                                }

                                Row {
                                    anchors.centerIn: parent
                                    spacing: 8
                                    Text {
                                        text: parent.isConnected ? "󰤨" : "󰤮"
                                        font.pixelSize: 22
                                        color: parent.isConnected ? ((sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff") : "#888888"
                                    }
                                    Column {
                                        anchors.verticalCenter: parent.verticalCenter
                                        Text {
                                            text: parent.isConnected ? "Online" : "Offline"
                                            font.pixelSize: 14
                                            font.weight: Font.Bold
                                            color: "#ffffff"
                                        }
                                    }
                                }
                            }
                        }

                        // 3. Media Player
                        Rectangle {
                            width: parent.width
                            height: visible ? 100 : 0
                            radius: 16
                            color: Qt.rgba(0,0,0,0.3)
                            visible: (sharedData && (sharedData.lockscreenMediaEnabled === true || sharedData.lockscreenMediaEnabled === undefined)) && mpTitle !== ""
                            clip: true
                            
                            Behavior on height { NumberAnimation { duration: 300 } }

                            Row {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 12
                                
                                // Art
                                Rectangle {
                                    width: 76
                                    height: 76
                                    radius: 12
                                    color: "#222222"
                                    clip: true
                                    Image {
                                        anchors.fill: parent
                                        source: mpArt ? mpArt : ""
                                        fillMode: Image.PreserveAspectCrop
                                        visible: mpArt !== ""
                                    }
                                    Text {
                                        anchors.centerIn: parent
                                        text: "󰃆" // Fallback icon
                                        font.pixelSize: 24
                                        color: "#444444"
                                        visible: !mpArt
                                    }
                                }
                                
                                // Info + Controls
                                Column {
                                    width: parent.width - 88 - 12 // Explicit width
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.verticalCenterOffset: 6
                                    spacing: 4
                                    
                                    Text {
                                        text: mpTitle
                                        font.pixelSize: 16
                                        font.weight: Font.Bold
                                        color: "#ffffff"
                                        width: parent.width
                                        elide: Text.ElideRight
                                    }
                                    Text {
                                        text: mpArtist
                                        font.pixelSize: 12
                                        color: "#aaaaaa"
                                        width: parent.width
                                        elide: Text.ElideRight
                                    }
                                    
                                    
                                    Row {
                                        spacing: 16
                                        
                                        // Previous (Matches Dashboard lines 1430-1444)
                                        Rectangle {
                                            width: 38
                                            height: 38
                                            radius: (sharedData && sharedData.quickshellBorderRadius !== undefined) ? Math.min(sharedData.quickshellBorderRadius, 10) : 10
                                            color: prevMouse.containsMouse ? Qt.rgba(1,1,1,0.15) : "transparent"
                                            anchors.verticalCenter: parent.verticalCenter
                                            
                                            Text {
                                                anchors.centerIn: parent
                                                text: "󰒮"
                                                font.pixelSize: 20
                                                color: prevMouse.containsMouse ? ((sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff") : ((sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff")
                                                opacity: prevMouse.pressed ? 0.7 : 1
                                            }
                                            MouseArea {
                                                id: prevMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: if (sharedData && sharedData.runCommand) sharedData.runCommand(['playerctl', 'previous'])
                                            }
                                        }

                                        // Play/Pause (Matches Dashboard lines 1446-1463)
                                        Rectangle {
                                            width: 48
                                            height: 48
                                            radius: (sharedData && sharedData.quickshellBorderRadius !== undefined) ? Math.min(sharedData.quickshellBorderRadius, 12) : 12
                                            color: ppMouse.containsMouse ? ((sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff") : Qt.rgba(1,1,1,0.12)
                                            scale: ppMouse.pressed ? 0.9 : 1.0
                                            Behavior on scale { NumberAnimation { duration: 100 } }
                                            Behavior on color { ColorAnimation { duration: 150 } }
                                            anchors.verticalCenter: parent.verticalCenter

                                            Text {
                                                anchors.centerIn: parent
                                                anchors.horizontalCenterOffset: !mpPlaying ? 2 : 0
                                                text: mpPlaying ? "󰏤" : "󰐊"
                                                font.pixelSize: 24
                                                color: ppMouse.containsMouse ? "#000000" : ((sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff")
                                            }
                                            MouseArea {
                                                id: ppMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: if (sharedData && sharedData.runCommand) sharedData.runCommand(['playerctl', 'play-pause'])
                                            }
                                        }

                                        // Next (Matches Dashboard lines 1465-1479)
                                        Rectangle {
                                            width: 38
                                            height: 38
                                            radius: (sharedData && sharedData.quickshellBorderRadius !== undefined) ? Math.min(sharedData.quickshellBorderRadius, 10) : 10
                                            color: nextMouse.containsMouse ? Qt.rgba(1,1,1,0.15) : "transparent"
                                            anchors.verticalCenter: parent.verticalCenter
                                            
                                            Text {
                                                anchors.centerIn: parent
                                                text: "󰒭"
                                                font.pixelSize: 20
                                                color: nextMouse.containsMouse ? ((sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff") : ((sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff")
                                                opacity: nextMouse.pressed ? 0.7 : 1
                                            }
                                            MouseArea {
                                                id: nextMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: if (sharedData && sharedData.runCommand) sharedData.runCommand(['playerctl', 'next'])
                                            }
                                        }
                                    }
                                }
                            }
                        }



                        // Spacer
                        Item { 
                            width: 1; height: 24 
                            visible: !(sharedData && sharedData.lockScreenNonBlocking)
                        }

                        // Minimal Input Line
                        Item {
                            width: parent.width
                            height: 60
                            visible: !(sharedData && sharedData.lockScreenNonBlocking)
                            
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
                                focus: lockScreenRoot.visible && !(sharedData && sharedData.lockScreenNonBlocking)
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
                            visible: !(sharedData && sharedData.lockScreenNonBlocking)

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

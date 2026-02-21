import QtQuick
import Quickshell
import Quickshell.Wayland
import QtQuick.Particles
import Quickshell.Io
import "components"

PanelWindow {
    id: root
    
    // --- Layout ---
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "screensaver"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    
    // Default colors (Hardcoded from Fuse config)
    property color colorBackground: "#000000"
    property color colorText: "#ffffff"
    property color colorAccent: "#c0c0c0"
    property color colorSecondary: "#080808"

    color: "transparent"

    // Explicit solid background
    Rectangle {
        anchors.fill: parent
        color: root.colorBackground
        z: -100
    }

    ProcessHelper { id: processHelper }
    property bool screensaverWidgetsEnabled: true
    
    // Shared Data mock for Widgets
    property var sharedData: QtObject {
        property var runCommand: processHelper ? processHelper.runCommand : function(){}
        property string weatherLocation: "London"
        property string colorText: root.colorText
        property string colorAccent: root.colorAccent
        property bool lockscreenWeatherEnabled: true
        property bool lockscreenBatteryEnabled: true
        property bool lockscreenNetworkEnabled: false
        property bool lockscreenMediaEnabled: true
        property bool lockscreenCalendarEnabled: false
    }

    // --- Color Loading & Entry Animation ---
    Component.onCompleted: {
        root.contentItem.forceActiveFocus()
        loadColors()
        // entryAnim.start()
    }
    
    NumberAnimation {
        id: entryAnim
        target: root
        property: "opacity"
        to: 1
        duration: 600
        easing.type: Easing.OutQuad
    }
    
    function quitSafely() {
        if (!exitAnim.running) {
            exitAnim.start()
        }
    }
    
    SequentialAnimation {
        id: exitAnim
        NumberAnimation { target: root; property: "opacity"; to: 0; duration: 400; easing.type: Easing.InQuad }
        ScriptAction { script: Qt.quit() }
    }
    
    function loadColors() {
        var pathXhr = new XMLHttpRequest()
        pathXhr.open("GET", "file:///tmp/quickshell_colors_path")
        pathXhr.onreadystatechange = function() {
            if (pathXhr.readyState === XMLHttpRequest.DONE && (pathXhr.status === 200 || pathXhr.status === 0)) {
                var configPath = pathXhr.responseText.trim()
                if (configPath.length > 0) {
                    loadColorsFromFile(configPath)
                }
            }
        }
        pathXhr.send()
    }

    function loadColorsFromFile(path) {
        var xhr = new XMLHttpRequest()
        xhr.open("GET", "file://" + path)
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE && (xhr.status === 200 || xhr.status === 0)) {
                try {
                    var json = JSON.parse(xhr.responseText)
                    if (json.background) root.colorBackground = json.background
                    if (json.text) root.colorText = json.text
                    if (json.accent) root.colorAccent = json.accent
                    if (json.secondary) root.colorSecondary = json.secondary
                    if (json.screensaverWidgetsEnabled !== undefined) {
                        root.screensaverWidgetsEnabled = json.screensaverWidgetsEnabled === true || json.screensaverWidgetsEnabled === "true"
                    }
                    if (json.weatherLocation) sharedData.weatherLocation = json.weatherLocation
                    if (json.lockscreenWeatherEnabled !== undefined) sharedData.lockscreenWeatherEnabled = json.lockscreenWeatherEnabled === true || json.lockscreenWeatherEnabled === "true"
                    if (json.lockscreenBatteryEnabled !== undefined) sharedData.lockscreenBatteryEnabled = json.lockscreenBatteryEnabled === true || json.lockscreenBatteryEnabled === "true"
                    if (json.lockscreenNetworkEnabled !== undefined) sharedData.lockscreenNetworkEnabled = json.lockscreenNetworkEnabled === true || json.lockscreenNetworkEnabled === "true"
                    if (json.lockscreenMediaEnabled !== undefined) sharedData.lockscreenMediaEnabled = json.lockscreenMediaEnabled === true || json.lockscreenMediaEnabled === "true"
                    if (json.lockscreenCalendarEnabled !== undefined) sharedData.lockscreenCalendarEnabled = json.lockscreenCalendarEnabled === true || json.lockscreenCalendarEnabled === "true"
                } catch (e) {}
            }
        }
        xhr.send()
    }


    Item {
        anchors.fill: parent
        opacity: 0.15
        
        Repeater {
            model: 6
            delegate: Rectangle {
                width: parent.width; height: 1
                color: root.colorText
                y: parent.height / 5 * index
            }
        }
        Repeater {
            model: 6
            delegate: Rectangle {
                width: 1; height: parent.height
                color: root.colorText
                x: parent.width / 5 * index
            }
        }
    }

    // --- Ambient Particles ---
    ParticleSystem {
        id: sys
        anchors.fill: parent
        z: -50 // Behind everything

        Emitter {
            anchors.fill: parent
            emitRate: 15
            lifeSpan: 10000
            lifeSpanVariation: 2000
            size: 10
            endSize: 0
            
            velocity: AngleDirection {
                angle: 270 // Upwards
                angleVariation: 45
                magnitude: 20
                magnitudeVariation: 10
            }
        }

        ItemParticle {
            delegate: Rectangle {
                width: 6; height: 6
                radius: 3
                color: root.colorAccent
                opacity: 0.15
            }
        }
        
        // Turbulence for natural drift
        Wander {
            xVariance: 50
            yVariance: 50
            pace: 100
        }
    }

    // --- Main Layout ---
    Item {
        id: mainContainer
        anchors.fill: parent
        anchors.margins: 100
        
        // 1. Hours
        Text {
            id: hourText
            text: Qt.formatTime(new Date(), "HH")
            font.family: "Inter, Roboto, sans-serif"
            font.weight: Font.Black
            font.pixelSize: 400
            color: root.colorText
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.topMargin: -80
        }
        
        // 2. Minutes
        Text {
            id: minText
            text: Qt.formatTime(new Date(), "mm")
            font.family: "Inter, Roboto, sans-serif"
            font.weight: Font.Black
            font.pixelSize: 400
            color: root.colorText
            anchors.left: parent.left
            anchors.top: hourText.bottom
            anchors.topMargin: -40
        }
        
        // 3. Date
        Text {
            id: dateText
            text: Qt.formatDate(new Date(), "yyyy-MM-dd").toUpperCase() + "\n" + Qt.formatDate(new Date(), "dddd").toUpperCase()
            font.family: "Monospace"
            font.pixelSize: 24
            font.bold: true
            color: root.colorText
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            horizontalAlignment: Text.AlignRight
        }

        // --- Brand Watermark ---
        Text {
            text: "Alloy"
            font.family: "Inter, Roboto, sans-serif"
            font.weight: Font.Bold
            font.pixelSize: 120
            font.letterSpacing: 4
            color: root.colorText
            opacity: 0.03
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.topMargin: -15
            anchors.rightMargin: 20
        }

        // --- Widgets Section (Right) ---
        Item {
            width: 400
            height: parent.height
            anchors.right: parent.right
            anchors.rightMargin: 20
            anchors.verticalCenter: parent.verticalCenter
            visible: root.screensaverWidgetsEnabled

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
                running: root.visible && (sharedData && sharedData.lockscreenWeatherEnabled === true) && root.screensaverWidgetsEnabled
                triggeredOnStart: true
                onTriggered: {
                    var query = (sharedData && sharedData.weatherLocation) ? sharedData.weatherLocation : ""
                    if (sharedData && sharedData.runCommand) {
                        sharedData.runCommand(['sh','-c','curl -s "wttr.in/' + query + '?format=%t+%C" 2>/dev/null | head -1 > /tmp/quickshell_lock_weather || echo "15°C Clear" > /tmp/quickshell_lock_weather'], function() {
                            var xhr = new XMLHttpRequest()
                            xhr.open("GET", "file:///tmp/quickshell_lock_weather?t=" + new Date().getTime())
                            xhr.onreadystatechange = function() {
                                if (xhr.readyState === XMLHttpRequest.DONE) {
                                    var weather = (xhr.responseText || "").trim()
                                    var parts = weather.split(" ")
                                    if (parts.length > 0) weatherTemp = parts[0]
                                    if (parts.length > 1) weatherCondition = parts.slice(1).join(" ")
                                }
                            }
                            xhr.send()
                        })
                    }
                }
            }

            // Battery Timer
            Timer {
                id: batteryTimer
                interval: 5000
                repeat: true
                running: root.visible && (sharedData && (sharedData.lockscreenBatteryEnabled === true || sharedData.lockscreenBatteryEnabled === undefined)) && root.screensaverWidgetsEnabled
                triggeredOnStart: true
                onTriggered: {
                    if (sharedData && sharedData.runCommand) {
                        var cmd = "(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null; cat /sys/class/power_supply/BAT*/status 2>/dev/null) | head -2"
                        sharedData.runCommand(['sh','-c', cmd + " > /tmp/quickshell_lock_battery"], function() {
                            var xhr = new XMLHttpRequest()
                            xhr.open("GET", "file:///tmp/quickshell_lock_battery?t=" + new Date().getTime())
                            xhr.onreadystatechange = function() {
                                if (xhr.readyState === XMLHttpRequest.DONE) {
                                    var text = (xhr.responseText || "").trim()
                                    var lines = text.split('\n')
                                    if (lines.length > 0) {
                                        var rawP = lines[0].trim()
                                        var p = parseInt(rawP, 10)
                                        if (!isNaN(p) && p >= 0 && p <= 100) {
                                            batteryPercent = p
                                        } else {
                                            batteryPercent = 0
                                        }
                                    }
                                    
                                    isCharging = false
                                    if (lines.length > 1) {
                                        var status = lines[1].trim().toLowerCase()
                                        if (status === "charging" || status === "full") {
                                            isCharging = true
                                        }
                                    }
                                }
                            }
                            xhr.send()
                        })
                    }
                }
            }

            // Media Timer
            Timer {
                interval: 1000
                repeat: true
                running: root.visible && (sharedData && (sharedData.lockscreenMediaEnabled === true || sharedData.lockscreenMediaEnabled === undefined)) && root.screensaverWidgetsEnabled
                triggeredOnStart: true
                onTriggered: {
                    if (sharedData && sharedData.runCommand) {
                        var scriptPath = "${QUICKSHELL_PROJECT_PATH:-$HOME/.config/alloy/dart}/scripts/get-player-metadata.sh"
                        var cmd = 'bash "' + scriptPath + '" > /tmp/quickshell_lock_media_raw; cat /tmp/quickshell_player_info > /tmp/quickshell_lock_media'
                        
                        sharedData.runCommand(["sh", "-c", cmd], function() {
                            var xhr = new XMLHttpRequest()
                            xhr.open("GET", "file:///tmp/quickshell_lock_media?t=" + new Date().getTime())
                            xhr.onreadystatechange = function() {
                                if (xhr.readyState === XMLHttpRequest.DONE) {
                                    var txt = xhr.responseText || ""
                                    if (txt.trim() === "") {
                                        mpPlaying = false
                                        mpTitle = ""
                                        return
                                    }
                                    
                                    var lines = txt.split("|###|")
                                    if (lines.length < 6) return
                                    
                                    mpArtist = lines[0] ? lines[0].trim() : ""
                                    mpTitle = lines[1] ? lines[1].trim() : ""
                                    
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

                opacity: root.visible ? 1 : 0
                x: root.visible ? 0 : 50
                Behavior on opacity { NumberAnimation { duration: 1000; easing.type: Easing.OutQuart } }
                Behavior on x { NumberAnimation { duration: 1200; easing.type: Easing.OutBack } }

                // 2. Weather, Battery, Network Row
                Row {
                    width: parent.width
                    spacing: 12
                    height: 80

                    property int visibleCount: (visibleWeather ? 1 : 0) + (visibleBattery ? 1 : 0) + (visibleNetwork ? 1 : 0)
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
                            running: parent.visible && root.visible
                            triggeredOnStart: true
                            onTriggered: {
                                if (sharedData && sharedData.runCommand) {
                                    var cmd = "ip route | grep default | head -1 || ip addr | grep 'inet ' | grep -v '127.0.0.1' | head -1 || echo 'down'"
                                    sharedData.runCommand(['sh', '-c', cmd + ' > /tmp/quickshell_lock_net'], function() {
                                        var xhr = new XMLHttpRequest()
                                        xhr.open("GET", "file:///tmp/quickshell_lock_net?t=" + new Date().getTime())
                                        xhr.onreadystatechange = function() {
                                            if (xhr.readyState === XMLHttpRequest.DONE) {
                                                var state = (xhr.responseText || "").trim()
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
                                text: "󰃆"
                                font.pixelSize: 24
                                color: "#444444"
                                visible: !mpArt
                            }
                        }
                        
                        // Info + Controls
                        Column {
                            width: parent.width - 88 - 12
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
                                
                                // Previous
                                Rectangle {
                                    width: 38
                                    height: 38
                                    radius: 10
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

                                // Play/Pause
                                Rectangle {
                                    width: 48
                                    height: 48
                                    radius: 12
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

                                // Next
                                Rectangle {
                                    width: 38
                                    height: 38
                                    radius: 10
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
            }
        }

    }

    // --- Seconds Bar ---
    Rectangle {
        id: secondsBar
        anchors.bottom: parent.bottom; anchors.left: parent.left
        height: 6; color: root.colorAccent; width: 0 
    }
    
    Timer {
        interval: 16; repeat: true; running: true
        onTriggered: {
            var d = new Date()
            if (d.getSeconds() !== _lastSeconds) {
                hourText.text = Qt.formatTime(d, "HH")
                minText.text = Qt.formatTime(d, "mm")
                _lastSeconds = d.getSeconds()
            }
            var progress = (d.getSeconds() + d.getMilliseconds()/1000.0) / 60.0
            secondsBar.width = root.width * progress
        }
        property int _lastSeconds: -1
    }

    MouseArea {
        anchors.fill: parent; cursorShape: Qt.BlankCursor
        hoverEnabled: true 

        // Grace period to prevent immediate exit on launch
        Timer {
            id: graceTimer
            interval: 1000
            running: true
        }

        onClicked: {
            if (!graceTimer.running) root.quitSafely()
        }
        onPositionChanged: {
            if (!graceTimer.running) root.quitSafely()
        }
    }
    Item {
        focus: true
        Keys.onPressed: event => root.quitSafely()
    }
}

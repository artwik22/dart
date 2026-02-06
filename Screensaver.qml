import QtQuick
import Quickshell
import Quickshell.Wayland
import QtQuick.Particles

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
        var xhr = new XMLHttpRequest()
        xhr.open("GET", "file://" + "/home/igora/.config/alloy/colors.json")
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE && xhr.status === 200) {
                try {
                    var json = JSON.parse(xhr.responseText)
                    if (json.background) root.colorBackground = json.background
                    if (json.text) root.colorText = json.text
                    if (json.accent) root.colorAccent = json.accent
                    if (json.secondary) root.colorSecondary = json.secondary
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

import QtQuick

Rectangle {
    id: toastRoot
    
    property string message: ""
    property string type: "info"  // "info", "success", "error", "warning"
    property int duration: 3000
    
    width: 300
    height: 60
    radius: 8
    color: {
        if (type === "success") return "#4caf50"
        if (type === "error") return "#f44336"
        if (type === "warning") return "#ff9800"
        return "#2196f3"
    }
    
    x: parent ? (parent.width - width) / 2 : 0
    y: -height
    z: 10000
    
    Behavior on y {
        NumberAnimation {
            duration: 300
            easing.type: Easing.OutCubic
        }
    }
    
    Row {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12
        
        Text {
            text: {
                if (type === "success") return "✓"
                if (type === "error") return "✕"
                if (type === "warning") return "⚠"
                return "ℹ"
            }
            font.pixelSize: 20
            color: "#ffffff"
            anchors.verticalCenter: parent.verticalCenter
        }
        
        Text {
            text: message
            font.pixelSize: 14
            font.family: "sans-serif"
            color: "#ffffff"
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - 40
            elide: Text.ElideRight
        }
    }
    
    function show() {
        y = 20
        timer.restart()
    }
    
    function hide() {
        y = -height
    }
    
    Timer {
        id: timer
        interval: duration
        onTriggered: toastRoot.hide()
    }
    
    Component.onCompleted: {
        if (message) {
            show()
        }
    }
}


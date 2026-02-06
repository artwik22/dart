import QtQuick

Item {
    id: progressRoot
    
    property real progress: 0.0  // 0.0 to 1.0
    property bool indeterminate: false
    property color progressColor: "#4a9eff"
    property color backgroundColor: "#1a1a1a"
    property int barHeight: 4
    
    width: parent ? parent.width : 200
    height: barHeight
    
    // Background bar
    Rectangle {
        anchors.fill: parent
        color: backgroundColor
        radius: barHeight / 2
    }
    
    // Progress bar
    Rectangle {
        width: indeterminate ? parent.width * 0.3 : parent.width * progress
        height: parent.height
        color: progressColor
        radius: barHeight / 2
        
        Behavior on width {
            NumberAnimation {
                duration: 200
                easing.type: Easing.OutCubic
            }
        }
        
        // Indeterminate animation
        SequentialAnimation on x {
            running: indeterminate
            loops: Animation.Infinite
            NumberAnimation {
                from: -width
                to: parent.width
                duration: 1000
                easing.type: Easing.Linear
            }
        }
    }
}


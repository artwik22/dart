import QtQuick

Rectangle {
    id: skeletonRoot
    
    property bool animated: true
    property real shimmerOpacity: 0.3
    
    color: parent.color || "#1a1a1a"
    radius: parent.radius || 0
    
    // Shimmer effect
    Rectangle {
        id: shimmer
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0) }
            GradientStop { position: 0.5; color: Qt.rgba(1, 1, 1, shimmerOpacity) }
            GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0) }
        }
        opacity: animated ? 1.0 : 0.0
        
        SequentialAnimation on x {
            running: animated
            loops: Animation.Infinite
            NumberAnimation {
                from: -parent.width
                to: parent.width * 2
                duration: 1500
                easing.type: Easing.Linear
            }
        }
    }
}


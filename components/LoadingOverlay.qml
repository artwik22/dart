import QtQuick

Rectangle {
    id: overlayRoot
    
    property bool visible: false
    property string message: "Loading..."
    
    anchors.fill: parent
    color: Qt.rgba(0, 0, 0, 0.7)
    visible: overlayRoot.visible
    z: 9999
    
    Behavior on opacity {
        NumberAnimation {
            duration: 200
            easing.type: Easing.OutCubic
        }
    }
    
    Column {
        anchors.centerIn: parent
        spacing: 16
        
        // Spinner
        Item {
            width: 40
            height: 40
            anchors.horizontalCenter: parent.horizontalCenter
            
            Rectangle {
                anchors.fill: parent
                color: "transparent"
                border.width: 3
                border.color: "#4a9eff"
                radius: width / 2
                
                RotationAnimation on rotation {
                    running: overlayRoot.visible
                    loops: Animation.Infinite
                    from: 0
                    to: 360
                    duration: 1000
                }
            }
        }
        
        Text {
            text: message
            font.pixelSize: 14
            font.family: "sans-serif"
            color: "#ffffff"
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }
}


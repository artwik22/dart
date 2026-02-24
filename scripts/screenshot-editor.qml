pragma Singleton
import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15
import Quickshell 1.0

Window {
    id: root
    width: 800
    height: 600
    visible: true
    title: "Screenshot Editor"
    
    // Pass args using Quickshell env or similar if arguments aren't available directly
    property string imagePath: Quickshell.env.IMAGE_PATH || ""
    
    Rectangle {
        anchors.fill: parent
        color: "#1e1e2e"
        
        Text {
            anchors.centerIn: parent
            text: "Quickshell Open: " + imagePath
            color: "white"
        }
    }
}

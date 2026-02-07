import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQml
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "."

Item {
    id: clipboardTabRoot
    property var root: null
    property var sharedData: root ? root.sharedData : null
    
    anchors.fill: parent
    
    Column {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 5
        
        // Header
        Row {
            width: parent.width
            spacing: 5
            
            Text {
                text: "󰨸 Clipboard"
                font.pixelSize: 10
                font.family: "sans-serif"
                font.weight: Font.Bold
                color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff"
            }
            
            Item { width: parent.width - 160; height: 1 }
            
            Rectangle {
                width: 25
                height: 25
                radius: (sharedData && sharedData.quickshellBorderRadius) ? sharedData.quickshellBorderRadius : 0
                color: clearClipboardButtonMouseArea.containsMouse ? 
                    ((sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff") : 
                    ((sharedData && sharedData.colorSecondary) ? sharedData.colorSecondary : "#141414")
                
                property real buttonScale: clearClipboardButtonMouseArea.pressed ? 0.9 : (clearClipboardButtonMouseArea.containsMouse ? 1.1 : 1.0)
                
                Behavior on color {
                    ColorAnimation {
                        duration: 200
                        easing.type: Easing.OutQuart
                    }
                }
                
                Behavior on buttonScale {
                    NumberAnimation {
                        duration: 150
                        easing.type: Easing.OutQuart
                    }
                }
                
                scale: buttonScale
                
                Text {
                    text: "󰆐"
                    font.pixelSize: 9
                    anchors.centerIn: parent
                    color: clearClipboardButtonMouseArea.containsMouse ? 
                        ((sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff") : 
                        ((sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff")
                    
                    Behavior on color {
                        ColorAnimation {
                            duration: 200
                            easing.type: Easing.OutQuart
                        }
                    }
                }
                
                MouseArea {
                    id: clearClipboardButtonMouseArea
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: {
                        if (root && root.dashboardClipboardHistoryModel) {
                            root.dashboardClipboardHistoryModel.clear()
                        }
                    }
                }
            }
        }
        
        // History list
        ScrollView {
            width: parent.width
            height: parent.height - 48
            
            ListView {
                id: clipboardListView
                model: root ? root.dashboardClipboardHistoryModel : null
                spacing: 5
                
                delegate: Rectangle {
                    width: clipboardListView.width
                    height: Math.max(32, contentTextClipboard.implicitHeight + 13)
                    radius: (sharedData && sharedData.quickshellBorderRadius) ? sharedData.quickshellBorderRadius : 0
                    color: itemClipboardMouseArea.containsMouse ? 
                        ((sharedData && sharedData.colorSecondary) ? sharedData.colorSecondary : "#141414") : 
                        ((sharedData && sharedData.colorPrimary) ? sharedData.colorPrimary : "#1a1a1a")
                    
                    property real cardElevation: itemClipboardMouseArea.containsMouse ? 2 : 1
                    
                    // Material Design elevation shadow
                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: -cardElevation
                        color: "transparent"
                        border.color: Qt.rgba(0, 0, 0, 0.15 + cardElevation * 0.05)
                        border.width: cardElevation
                        z: -1
                        
                        Behavior on border.color {
                            ColorAnimation {
                                duration: 200
                                easing.type: Easing.OutQuart
                            }
                        }
                    }
                    
                    Behavior on color {
                        ColorAnimation {
                            duration: 200
                            easing.type: Easing.OutQuart
                        }
                    }
                    
                    Text {
                        id: contentTextClipboard
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        text: {
                            var txt = model.text || ""
                            return txt.length > 100 ? txt.substring(0, 100) + "..." : txt
                        }
                        font.pixelSize: 10
                        font.family: "sans-serif"
                        color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff"
                        wrapMode: Text.Wrap
                        elide: Text.ElideRight
                    }
                    
                    MouseArea {
                        id: itemClipboardMouseArea
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onClicked: {
                            if (root) {
                                root.copyToClipboard(model.text)
                            }
                        }
                    }
                }
            }
        }
    }
}

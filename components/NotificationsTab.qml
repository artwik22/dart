import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQml
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "."

Item {
    id: notificationsTabRoot
    property var root: null
    property var sharedData: root ? root.sharedData : null
    
    anchors.fill: parent
    
    // Notifications content
    Column {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 13
        
        // Header with title and clear button
        RowLayout {
            width: parent.width
            
            Text {
                text: "󰂚 Notification Center"
                font.pixelSize: 19
                font.family: "sans-serif"
                font.weight: Font.Bold
                color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff"
                Layout.fillWidth: true
            }
            
            // Clear all button
            Rectangle {
                Layout.preferredWidth: 80
                Layout.preferredHeight: 25
                radius: (sharedData && sharedData.quickshellBorderRadius) ? sharedData.quickshellBorderRadius : 0
                color: clearAllMouseArea.containsMouse ? 
                    ((sharedData && sharedData.colorSecondary) ? sharedData.colorSecondary : "#252525") : 
                    ((sharedData && sharedData.colorPrimary) ? sharedData.colorPrimary : "#1a1a1a")
                
                Behavior on color {
                    ColorAnimation { duration: 150 }
                }
                
                Text {
                    anchors.centerIn: parent
                    text: "󰎟 Clear All"
                    font.pixelSize: 9
                    font.family: "sans-serif"
                    color: "#ffffff"
                }
                
                MouseArea {
                    id: clearAllMouseArea
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: {
                        if (sharedData) sharedData.notificationHistory = []
                    }
                }
            }
        }
        
        // Notification count
        Text {
            text: ((sharedData && sharedData.notificationHistory) ? sharedData.notificationHistory.length : 0) + " notifications"
            font.pixelSize: 9
            font.family: "sans-serif"
            color: (sharedData && sharedData.colorSubtext) ? sharedData.colorSubtext : "#888888"
        }
        
        // Notifications list
        ListView {
            id: notificationHistoryList
            width: parent.width
            height: parent.height - 80
            clip: true
            spacing: 5
            model: (sharedData && sharedData.notificationHistory) ? sharedData.notificationHistory : []
            
            // Empty state
            Text {
                width: parent.width - 24
                height: implicitHeight
                x: (parent.width - width) / 2
                y: (parent.height - height) / 2
                text: "󰂛 No notifications"
                font.pixelSize: 9
                font.family: "sans-serif"
                color: (sharedData && sharedData.colorSubtext) ? sharedData.colorSubtext : "#888888"
                visible: !sharedData || !sharedData.notificationHistory || sharedData.notificationHistory.length === 0
            }
            
            delegate: Rectangle {
                width: notificationHistoryList.width
                height: notifContent.height + 19
                radius: (sharedData && sharedData.quickshellBorderRadius) ? sharedData.quickshellBorderRadius : 0
                color: notifItemMouseArea.containsMouse ? 
                    ((sharedData && sharedData.colorSecondary) ? sharedData.colorSecondary : "#252525") : 
                    ((sharedData && sharedData.colorPrimary) ? sharedData.colorPrimary : "#1a1a1a")
                
                property real cardElevation: notifItemMouseArea.containsMouse ? 2 : 1
                
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
                            duration: 150
                            easing.type: Easing.OutQuart
                        }
                    }
                }
                
                Behavior on color {
                    ColorAnimation { duration: 150 }
                }
                
                MouseArea {
                    id: notifItemMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                }
                
                Column {
                    id: notifContent
                    anchors.left: parent.left
                    anchors.right: notifActions.left
                    anchors.top: parent.top
                    anchors.margins: 12
                    anchors.rightMargin: 8
                    spacing: 5
                    
                    // App name and time
                    RowLayout {
                        width: parent.width
                        
                        Text {
                            text: modelData.appName || "Unknown"
                            font.pixelSize: 9
                            font.family: "sans-serif"
                            font.weight: Font.Medium
                            color: (sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff"
                        }
                        
                        Item { Layout.fillWidth: true }
                        
                        Text {
                            text: modelData.time || ""
                            font.pixelSize: 8
                            font.family: "sans-serif"
                            color: (sharedData && sharedData.colorSubtext) ? sharedData.colorSubtext : "#888888"
                        }
                    }
                    
                    // Title
                    Text {
                        text: modelData.title || ""
                        font.pixelSize: 10
                        font.family: "sans-serif"
                        font.weight: Font.Bold
                        color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff"
                        width: parent.width
                        elide: Text.ElideRight
                    }
                    
                    // Body
                    Text {
                        text: modelData.body || ""
                        font.pixelSize: 9
                        font.family: "sans-serif"
                        color: (sharedData && sharedData.colorSubtext) ? sharedData.colorSubtext : "#888888"
                        width: parent.width
                        wrapMode: Text.WordWrap
                        maximumLineCount: 3
                        elide: Text.ElideRight
                    }
                }
                
                // Action buttons
                Row {
                    id: notifActions
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 8
                    spacing: 5
                    visible: notifItemMouseArea.containsMouse
                    
                    // Copy button
                    Rectangle {
                        width: 32
                        height: 32
                        radius: (sharedData && sharedData.quickshellBorderRadius) ? sharedData.quickshellBorderRadius : 0
                        color: copyBtnMouseArea.containsMouse ? 
                            ((sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff") : 
                            "transparent"
                        
                        Text {
                            anchors.centerIn: parent
                            text: "󰆏"
                            font.pixelSize: 8
                            color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff"
                        }
                        
                        MouseArea {
                            id: copyBtnMouseArea
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true
                            onClicked: {
                                var textToCopy = (modelData.title || "") + "\n" + (modelData.body || "")
                                if (root) root.copyToClipboard(textToCopy)
                            }
                        }
                    }
                    
                    // Delete button
                    Rectangle {
                        width: 32
                        height: 32
                        radius: (sharedData && sharedData.quickshellBorderRadius) ? sharedData.quickshellBorderRadius : 0
                        color: deleteBtnMouseArea.containsMouse ? "#ff4444" : "transparent"
                        
                        Text {
                            anchors.centerIn: parent
                            text: "󰆴"
                            font.pixelSize: 8
                            color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff"
                        }
                        
                        MouseArea {
                            id: deleteBtnMouseArea
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true
                            onClicked: {
                                if (sharedData && sharedData.notificationHistory) {
                                    var history = sharedData.notificationHistory
                                    history.splice(index, 1)
                                    sharedData.notificationHistory = history
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

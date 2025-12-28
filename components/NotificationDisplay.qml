import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import "."

PanelWindow {
    id: notificationDisplayRoot

    anchors { 
        top: true
        right: true
    }
    
    implicitWidth: 380
    implicitHeight: 600  // Max height for notification stack
    
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qsnotifications"
    exclusiveZone: 0
    
    property var sharedData: null
    
    visible: true
    color: "transparent"
    
    margins {
        top: 0
        right: 0
        bottom: 0
        left: 0
    }
    
    // NotificationServer - receives notifications
    NotificationServer {
        id: notificationServer
        
        onNotification: function(notification) {
            console.log("=== New Notification Received ===")
            console.log("Summary:", notification.summary)
            console.log("Body:", notification.body)
            console.log("AppName:", notification.appName)
            console.log("AppIcon:", notification.appIcon)
            addNotification(notification)
        }
    }
    
    // List of active notifications
    property var notifications: []
    property int maxNotifications: 5
    
    function addNotification(notification) {
        console.log("addNotification called with notification:", notification ? notification.summary : "null")
        
        // Remove oldest if we exceed max
        if (notifications.length >= maxNotifications) {
            var oldest = notifications.shift()
            if (oldest && oldest.notification) {
                oldest.notification.dismiss()
            }
            if (oldest) {
                oldest.destroy()
            }
        }
        
        // Create notification item directly using inline component
        var notificationItem = notificationItemComponent.createObject(notificationColumn, {
            "notification": notification,
            "sharedData": sharedData
        })
        
        if (notificationItem) {
            console.log("NotificationItem created directly, notification:", notificationItem.notification ? notificationItem.notification.summary : "null")
            notifications.push(notificationItem)
            
            // Connect to closed signal
            notificationItem.notificationClosed.connect(function() {
                removeNotification(notificationItem)
            })
            
            // Auto-dismiss timer is now handled inside NotificationItem
        }
    }
    
    function removeNotification(item) {
        console.log("removeNotification called")
        var index = notifications.indexOf(item)
        if (index !== -1) {
            notifications.splice(index, 1)
        }
        if (item) {
            // Wait a bit for animation to complete, then destroy
            var destroyTimer = Qt.createQmlObject('import QtQuick; Timer { interval: 400; running: true; repeat: false }', notificationDisplayRoot)
            destroyTimer.triggered.connect(function() {
                console.log("Destroying notification item after animation")
                if (item) {
                    item.destroy()
                }
            })
        }
    }
    
    // Component definition inline - NotificationItem is imported via "."
    Component {
        id: notificationItemComponent
        NotificationItem {
        }
    }
    
    // Column to stack notifications - positioned at top-right corner
    Column {
        id: notificationColumn
        anchors.top: parent.top
        anchors.topMargin: 0
        anchors.right: parent.right
        anchors.rightMargin: 0
        width: parent.width
        spacing: 8
    }
}


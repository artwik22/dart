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
    
    implicitWidth: notifications.length > 0 ? 380 : 0
    implicitHeight: notifications.length > 0 ? 600 : 0
    
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qsnotifications"
    exclusiveZone: 0
    
    property var sharedData: null
    
    visible: notifications.length > 0
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
            
            // Add to notification history
            if (sharedData) {
                var now = new Date()
                var timeStr = now.getHours().toString().padStart(2, '0') + ":" + now.getMinutes().toString().padStart(2, '0')
                var historyItem = {
                    appName: notification.appName || "Unknown",
                    title: notification.summary || "",
                    body: notification.body || "",
                    time: timeStr
                }
                sharedData.notificationHistory = [historyItem].concat(sharedData.notificationHistory)
            }
            
            // Check if notifications are enabled
            if (sharedData && !sharedData.notificationsEnabled) {
                console.log("Notifications disabled, ignoring")
                return
            }
            
            // Play notification sound if enabled
            if (sharedData && sharedData.notificationSoundsEnabled) {
                Qt.createQmlObject('import Quickshell.Io; Process { command: ["paplay", "/usr/share/sounds/freedesktop/stereo/message.oga"]; running: true }', notificationDisplayRoot)
            }
            
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
            var currentNotifs = [...notifications]
            var oldest = currentNotifs.shift()
            if (oldest && oldest.notification) {
                oldest.notification.dismiss()
            }
            if (oldest) {
                oldest.destroy()
            }
            notifications = currentNotifs
        }
        
        // Create notification item directly using inline component
        var notificationItem = notificationItemComponent.createObject(notificationColumn, {
            "notification": notification,
            "sharedData": sharedData
        })
        
        if (notificationItem) {
            console.log("NotificationItem created directly, notification:", notificationItem.notification ? notificationItem.notification.summary : "null")
            
            // Update array in a way that triggers QML property change (using spread or concat)
            notifications = [...notifications, notificationItem]
            
            // Connect to closed signal
            notificationItem.notificationClosed.connect(function() {
                removeNotification(notificationItem)
            })
        }
    }
    
    function removeNotification(item) {
        console.log("removeNotification called")
        var currentNotifs = notifications
        var index = currentNotifs.indexOf(item)
        if (index !== -1) {
            var newNotifs = [...currentNotifs]
            newNotifs.splice(index, 1)
            notifications = newNotifs
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

        // Premium smooth animation for notification repositioning
        move: Transition {
            NumberAnimation {
                properties: "y"
                duration: 550
                easing.type: Easing.OutExpo
            }
        }

        // Space reservation animation
        add: Transition {
            NumberAnimation {
                property: "opacity"
                from: 0.0
                to: 1.0
                duration: 200
            }
        }
    }
}


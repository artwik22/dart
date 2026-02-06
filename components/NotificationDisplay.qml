import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import "."

PanelWindow {
    id: notificationDisplayRoot

<<<<<<< HEAD
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
=======
    required property var screen  // ekran z Variants (screen: modelData) – PanelWindow go używa do outputu
    property var sharedData: null

    anchors.top: true
    anchors.right: true

    implicitWidth: notifications.length > 0 ? 304 : 0
    implicitHeight: notifications.length > 0 ? 640 : 0

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qsnotifications" + (screen && screen.name ? "-" + screen.name : "")
    exclusiveZone: 0

    visible: notifications.length > 0
    color: "transparent"

    margins {
        top: 0
        right: 0
>>>>>>> master
    }
    
    // NotificationServer - receives notifications
    NotificationServer {
        id: notificationServer
        
        onNotification: function(notification) {
<<<<<<< HEAD
            console.log("=== New Notification Received ===")
            console.log("Summary:", notification.summary)
            console.log("Body:", notification.body)
            console.log("AppName:", notification.appName)
            console.log("AppIcon:", notification.appIcon)
=======
>>>>>>> master
            
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
<<<<<<< HEAD
                console.log("Notifications disabled, ignoring")
=======
>>>>>>> master
                return
            }
            
            // Play notification sound if enabled
<<<<<<< HEAD
            if (sharedData && sharedData.notificationSoundsEnabled) {
                Qt.createQmlObject('import Quickshell.Io; Process { command: ["paplay", "/usr/share/sounds/freedesktop/stereo/message.oga"]; running: true }', notificationDisplayRoot)
=======
            if (sharedData && sharedData.notificationSoundsEnabled && sharedData.runCommand) {
                sharedData.runCommand(["paplay", "/usr/share/sounds/freedesktop/stereo/message.oga"])
>>>>>>> master
            }
            
            addNotification(notification)
        }
    }
    
    // List of active notifications
    property var notifications: []
    property int maxNotifications: 5
    
    function addNotification(notification) {
<<<<<<< HEAD
        console.log("addNotification called with notification:", notification ? notification.summary : "null")
=======
>>>>>>> master
        
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
<<<<<<< HEAD
            console.log("NotificationItem created directly, notification:", notificationItem.notification ? notificationItem.notification.summary : "null")
=======
>>>>>>> master
            
            // Update array in a way that triggers QML property change (using spread or concat)
            notifications = [...notifications, notificationItem]
            
            // Connect to closed signal
            notificationItem.notificationClosed.connect(function() {
                removeNotification(notificationItem)
            })
        }
    }
    
    function removeNotification(item) {
<<<<<<< HEAD
        console.log("removeNotification called")
=======
>>>>>>> master
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
<<<<<<< HEAD
                console.log("Destroying notification item after animation")
=======
>>>>>>> master
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
    
<<<<<<< HEAD
    // Column to stack notifications - positioned at top-right corner
    Column {
        id: notificationColumn
        anchors.top: parent.top
        anchors.topMargin: 0
        anchors.right: parent.right
        anchors.rightMargin: 0
        width: parent.width
        spacing: 8
=======
    Column {
        id: notificationColumn
        anchors.fill: parent
        spacing: 7
>>>>>>> master

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


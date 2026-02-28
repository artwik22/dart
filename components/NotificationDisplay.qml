import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import "."

PanelWindow {
    id: notificationDisplayRoot

    required property var screen  // ekran z Variants (screen: modelData) – PanelWindow go używa do outputu
    property var sharedData: null

    // anchors.top: true - handled in window properties
    // anchors.left: true - removed to allow centering
    // anchors.right: true - removed to allow centering

    implicitWidth: notificationColumn.width
    implicitHeight: notificationColumn.height

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qsnotifications" + (screen && screen.name ? "-" + screen.name : "")
    exclusiveZone: 0

    visible: notifications.length > 0
    color: "transparent"

    // Anchor window based on sharedData.notificationPosition
    // If both left and right are false, it centers naturally for "top"
    anchors.top: true
    anchors.bottom: false
    anchors.left: sharedData && sharedData.notificationPosition === "top-left"
    anchors.right: sharedData && sharedData.notificationPosition === "top-right"

    margins {
        top: 10
        left: sharedData && sharedData.notificationPosition === "top-left" ? 10 : 0
        right: sharedData && sharedData.notificationPosition === "top-right" ? 10 : 0
    }
    
    // NotificationServer - receives notifications
    NotificationServer {
        id: notificationServer
        
        onNotification: function(notification) {
            
            // Add to notification history (Limit to 50 items)
            if (sharedData) {
                var now = new Date()
                var timeStr = now.getHours().toString().padStart(2, '0') + ":" + now.getMinutes().toString().padStart(2, '0')
                var historyItem = {
                    appName: notification.appName || "Unknown",
                    title: notification.summary || "",
                    body: notification.body || "",
                    time: timeStr
                }
                var history = [historyItem].concat(sharedData.notificationHistory)
                if (history.length > 50) history = history.slice(0, 50)
                sharedData.notificationHistory = history
            }
            
            // Check if notifications are enabled
            if (sharedData && !sharedData.notificationsEnabled) {
                return
            }
            
            // Play notification sound if enabled
            if (sharedData && sharedData.notificationSoundsEnabled && sharedData.runCommand) {
                var sound = sharedData.notificationSound || "message.oga"
                sharedData.runCommand(["paplay", "/usr/share/sounds/freedesktop/stereo/" + sound])
            }
            
            addNotification(notification)
        }
    }
    
    // List of active notifications
    property var notifications: []
    property int maxNotifications: 5
    
    function addNotification(notification) {
        
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
            
            // Update array in a way that triggers QML property change (using spread or concat)
            notifications = [...notifications, notificationItem]
            
            // Connect to closed signal
            notificationItem.notificationClosed.connect(function() {
                removeNotification(notificationItem)
            })
        }
    }
    
    function removeNotification(item) {
        var currentNotifs = notifications
        var index = currentNotifs.indexOf(item)
        if (index !== -1) {
            var newNotifs = [...currentNotifs]
            newNotifs.splice(index, 1)
            notifications = newNotifs
        }
        if (item) {
            // Use a reusable timer or direct destruction if animation is handled elsewhere
            // For now, let's use a simpler approach that doesn't leak timers
            item.destroy(400) // Destroy after 400ms delay (QtQuick 2.x supports this delay)
        }
    }
    
    // Component definition inline - NotificationItem is imported via "."
    Component {
        id: notificationItemComponent
        NotificationItem {
        }
    }
    
    Column {
        id: notificationColumn
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        
        width: 340  // Increased width to match NotificationItem
        spacing: 12

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


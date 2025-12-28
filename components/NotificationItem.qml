import QtQuick
import Quickshell.Services.Notifications

Rectangle {
    id: notificationItem
    
    property Notification notification: null
    property var sharedData: null
    
    signal notificationClosed()
    
    // Store notification reference to prevent garbage collection
    property var storedNotification: notification
    
    // Auto-dismiss timer
    Timer {
        id: autoDismissTimer
        interval: 5000  // 5 seconds
        running: false
        repeat: false
        onTriggered: {
            console.log("Auto-dismiss timer triggered in NotificationItem")
            startExitAnimation()
        }
    }
    
    // Progress bar animation timer
    property int dismissStartTime: 0
    property real progressValue: 0.0
    
    Timer {
        id: progressUpdateTimer
        interval: 50
        running: autoDismissTimer.running
        repeat: true
        onTriggered: {
            if (autoDismissTimer.running && autoDismissTimer.interval > 0) {
                var elapsed = Date.now() - dismissStartTime
                var remaining = Math.max(0, autoDismissTimer.interval - elapsed)
                progressValue = 1.0 - (remaining / autoDismissTimer.interval)
            } else {
                progressValue = 0.0
            }
        }
    }
    
    width: 380
    height: notificationContent.height + 32
    radius: 0
    color: getBackgroundColor()
    
    // Enhanced shadow effect with multiple layers
    Rectangle {
        anchors.fill: parent
        anchors.margins: -3
        radius: 0
        color: "transparent"
        border.color: Qt.rgba(0, 0, 0, 0.5)
        border.width: 1
        z: -1
    }
    
    // Subtle inner glow
    Rectangle {
        anchors.fill: parent
        anchors.margins: 1
        radius: 0
        color: "transparent"
        border.color: Qt.rgba(255, 255, 255, 0.05)
        border.width: 1
        z: 1
    }
    
    function getBackgroundColor() {
        if (!sharedData) return "#1e1e1e"
        
        // Different colors based on urgency with better contrast
        if (notification && notification.urgency === NotificationUrgency.Critical) {
            return sharedData.colorAccent ? Qt.darker(sharedData.colorAccent, 1.2) : "#2a1a1a"
        } else if (notification && notification.urgency === NotificationUrgency.Normal) {
            return sharedData.colorPrimary ? Qt.lighter(sharedData.colorPrimary, 1.1) : "#1e1e1e"
        } else {
            return sharedData.colorBackground ? Qt.lighter(sharedData.colorBackground, 1.05) : "#1a1a1a"
        }
    }
    
    // Border removed as requested
    
    // Content
    Item {
        id: notificationContent
        anchors.left: parent.left
        anchors.leftMargin: 20
        anchors.right: parent.right
        anchors.rightMargin: 20
        anchors.top: parent.top
        anchors.topMargin: 16
        height: contentColumn.height
        
        Column {
            id: contentColumn
            width: parent.width
            spacing: 8
            
            // Header row: icon, app name, close button
            Row {
                width: parent.width
                spacing: 14
                
                // App icon with better styling
                Rectangle {
                    id: iconRect
                    width: 44
                    height: 44
                    radius: 0
                    color: sharedData && sharedData.colorSecondary ? Qt.lighter(sharedData.colorSecondary, 1.1) : "#1f1f1f"
                    visible: notification && notification.appIcon && notification.appIcon.length > 0
                    
                    // Icon border
                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 1
                        radius: 0
                        color: "transparent"
                        border.color: Qt.rgba(255, 255, 255, 0.08)
                        border.width: 1
                    }
                    
                    Image {
                        anchors.fill: parent
                        anchors.margins: 6
                        source: notification ? notification.appIcon : ""
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        antialiasing: true
                    }
                }
                
                // App name and summary
                Column {
                    id: textColumn
                    width: Math.max(100, parent.width - (closeButton.visible ? 60 : 0) - (iconRect.visible ? 58 : 0))
                    spacing: 5
                    anchors.verticalCenter: iconRect.visible ? undefined : parent.verticalCenter
                    
                    Text {
                        id: appNameText
                        text: "Notification"  // Default, will be updated in onNotificationChanged
                        font.pixelSize: 12
                        font.family: "JetBrains Mono"
                        font.weight: Font.Bold
                        color: sharedData && sharedData.colorAccent ? Qt.lighter(sharedData.colorAccent, 1.2) : "#9aa0a6"
                        elide: Text.ElideRight
                        width: parent.width
                        visible: true
                        opacity: 0.9
                    }
                    
                    Text {
                        id: summaryText
                        text: ""  // Will be updated in onNotificationChanged
                        font.pixelSize: 15
                        font.family: "JetBrains Mono"
                        font.weight: Font.DemiBold
                        color: "#ffffff"
                        elide: Text.ElideRight
                        width: parent.width
                        visible: text && text.length > 0
                    }
                }
                
                // Close button with enhanced styling
                Item {
                    id: closeButton
                    width: 32
                    height: 32
                    anchors.verticalCenter: iconRect.visible ? iconRect.verticalCenter : textColumn.verticalCenter
                    
                    Rectangle {
                        anchors.fill: parent
                        radius: 0
                        color: closeButtonMouseArea.containsMouse ? 
                            (sharedData && sharedData.colorAccent ? sharedData.colorAccent : "#ff4444") : 
                            (sharedData && sharedData.colorSecondary ? Qt.lighter(sharedData.colorSecondary, 1.05) : "#1f1f1f")
                        
                        border.color: closeButtonMouseArea.containsMouse ? 
                            Qt.rgba(255, 255, 255, 0.2) : 
                            Qt.rgba(255, 255, 255, 0.05)
                        border.width: 1
                        
                        property real buttonScale: closeButtonMouseArea.pressed ? 0.85 : (closeButtonMouseArea.containsMouse ? 1.05 : 1.0)
                        property real buttonOpacity: closeButtonMouseArea.containsMouse ? 1.0 : 0.7
                        
                        opacity: buttonOpacity
                        
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
                        
                        Behavior on buttonOpacity {
                            NumberAnimation {
                                duration: 150
                                easing.type: Easing.OutQuart
                            }
                        }
                        
                        scale: buttonScale
                    }
                    
                    Text {
                        text: "󰅖"
                        font.pixelSize: 16
                        anchors.centerIn: parent
                        color: closeButtonMouseArea.containsMouse ? 
                            "#ffffff" : 
                            (sharedData && sharedData.colorAccent ? sharedData.colorAccent : "#888888")
                        z: 1
                        
                        Behavior on color {
                            ColorAnimation {
                                duration: 200
                                easing.type: Easing.OutQuart
                            }
                        }
                    }
                    
                    MouseArea {
                        id: closeButtonMouseArea
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        z: 10000  // Very high z to ensure it's on top of everything
                        propagateComposedEvents: false
                        acceptedButtons: Qt.LeftButton
                        enabled: true
                        onClicked: function(mouse) {
                            console.log("=== CLOSE BUTTON CLICKED ===")
                            mouse.accepted = true
                            
                            // Try to dismiss notification - use storedNotification as fallback
                            var notif = notificationItem.notification || notificationItem.storedNotification
                            if (notif) {
                                console.log("Calling notification.dismiss()")
                                try {
                                    notif.dismiss()
                                } catch(e) {
                                    console.log("Error dismissing:", e)
                                    // Fallback: start exit animation
                                    notificationItem.startExitAnimation()
                                }
                            } else {
                                console.log("notification is null, starting exit animation")
                                // If notification is null, start exit animation
                                notificationItem.startExitAnimation()
                            }
                        }
                    }
                }
            }
            
            // Body text - always show if there's content
            Text {
                id: bodyText
                text: ""  // Will be updated in onNotificationChanged
                font.pixelSize: 13
                font.family: "JetBrains Mono"
                font.weight: Font.Normal
                color: "#b0b0b0"
                wrapMode: Text.Wrap
                width: parent.width
                visible: text && text.length > 0
                lineHeight: 1.4
                topPadding: 2
            }
            
            // Image if available with border
            Rectangle {
                width: parent.width
                height: notification && notification.image ? Math.min(200, width * 0.75) : 0
                visible: notification && notification.image && notification.image.length > 0
                color: "transparent"
                border.color: Qt.rgba(255, 255, 255, 0.1)
                border.width: 1
                radius: 0
                
                Image {
                    anchors.fill: parent
                    anchors.margins: 1
                    source: notification && notification.image ? notification.image : ""
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    antialiasing: true
                }
            }
            
            // Progress bar showing time until auto-dismiss
            Rectangle {
                id: progressBar
                width: parent.width
                height: 2
                color: Qt.rgba(255, 255, 255, 0.1)
                visible: autoDismissTimer.running && autoDismissTimer.interval > 0
                
                Rectangle {
                    id: progressFill
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: progressBar.width * notificationItem.progressValue
                    color: sharedData && sharedData.colorAccent ? sharedData.colorAccent : "#4a9eff"
                    
                    Behavior on width {
                        NumberAnimation {
                            duration: 50
                            easing.type: Easing.Linear
                        }
                    }
                }
            }
        }
    }
    
    // Click to dismiss - exclude close button area completely
    MouseArea {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.rightMargin: 50  // Leave space for close button (right 50px)
        cursorShape: Qt.PointingHandCursor
        z: 0  // Lower than close button (z: 10000)
        propagateComposedEvents: true  // Allow events to propagate to close button
        enabled: true
        onClicked: function(mouse) {
            // Only dismiss if not clicking on close button area
            var clickX = mouse.x
            var buttonAreaStart = width - 50
            if (clickX < buttonAreaStart) {
                if (notification) {
                    notification.dismiss()
                }
            }
        }
    }
    
    // Animation states
    property real slideOffset: 400  // Start off-screen to the right
    property real fadeOpacity: 0.0  // Start invisible
    
    // Use opacity binding to ensure text is visible when fadeOpacity changes
    opacity: fadeOpacity
    
    transform: Translate {
        x: slideOffset
    }
    
    // Ensure content is visible
    clip: false
    
    // Component.onCompleted - update texts if notification is already set
    Component.onCompleted: {
        console.log("=== NotificationItem Component.onCompleted ===")
        console.log("notification property:", notification)
        if (notification) {
            console.log("Summary:", notification.summary)
            console.log("Body:", notification.body)
            console.log("AppName:", notification.appName)
            
            // Update texts immediately if notification is already set
            if (appNameText) {
                appNameText.text = notification.appName || notification.desktopEntry || "Notification"
                console.log("Component.onCompleted: SET appNameText.text =", appNameText.text)
            }
            if (summaryText) {
                summaryText.text = notification.summary || ""
                console.log("Component.onCompleted: SET summaryText.text =", summaryText.text)
            }
            if (bodyText) {
                var body = notification.body || ""
                if (body.length === 0) body = notification.summary || ""
                bodyText.text = body
                console.log("Component.onCompleted: SET bodyText.text =", bodyText.text)
            }
            
            // Start auto-dismiss timer if notification is already set
            if (notification.expireTimeout > 0) {
                autoDismissTimer.interval = notification.expireTimeout
                dismissStartTime = Date.now()
                autoDismissTimer.start()
                progressUpdateTimer.start()
                console.log("Component.onCompleted: Started auto-dismiss timer with interval:", notification.expireTimeout)
            } else if (notification.expireTimeout === -1) {
                // No timeout
                console.log("Component.onCompleted: Notification has no timeout")
            } else {
                // Default timeout of 5 seconds
                autoDismissTimer.interval = 5000
                dismissStartTime = Date.now()
                autoDismissTimer.start()
                progressUpdateTimer.start()
                console.log("Component.onCompleted: Started default auto-dismiss timer (5 seconds)")
            }
        }
        // Start slide-in animation
        Qt.callLater(function() {
            console.log("Starting enter animation")
            enterAnimation.start()
        })
    }
    
    // Update when notification property changes - THIS IS THE ONLY PLACE TEXT IS SET
    onNotificationChanged: {
        console.log("=== onNotificationChanged ===")
        
        // Store notification reference to prevent garbage collection
        storedNotification = notification
        
        if (notification) {
            console.log("  Summary:", notification.summary)
            console.log("  Body:", notification.body)
            console.log("  AppName:", notification.appName)
            
            // Set texts immediately
            if (appNameText) {
                appNameText.text = notification.appName || notification.desktopEntry || "Notification"
                console.log("  SET appNameText.text =", appNameText.text)
            }
            if (summaryText) {
                summaryText.text = notification.summary || ""
                console.log("  SET summaryText.text =", summaryText.text)
            }
            if (bodyText) {
                var body = notification.body || ""
                if (body.length === 0) {
                    body = notification.summary || ""
                }
                bodyText.text = body
                console.log("  SET bodyText.text =", bodyText.text)
            }
            
            // Start auto-dismiss timer
            if (notification.expireTimeout > 0) {
                autoDismissTimer.interval = notification.expireTimeout
                dismissStartTime = Date.now()
                autoDismissTimer.start()
                progressUpdateTimer.start()
                console.log("Started auto-dismiss timer with interval:", notification.expireTimeout)
            } else if (notification.expireTimeout === -1) {
                // No timeout, notification stays until dismissed
                console.log("Notification has no timeout (expireTimeout = -1)")
            } else {
                // Default timeout of 5 seconds
                autoDismissTimer.interval = 5000
                dismissStartTime = Date.now()
                autoDismissTimer.start()
                progressUpdateTimer.start()
                console.log("Started default auto-dismiss timer (5 seconds)")
            }
        } else {
            console.log("  notification is null!")
        }
    }
    
    
    ParallelAnimation {
        id: enterAnimation
        NumberAnimation {
            target: notificationItem
            property: "slideOffset"
            from: 400
            to: 0
            duration: 400
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: notificationItem
            property: "fadeOpacity"
            from: 0.0
            to: 1.0
            duration: 400
            easing.type: Easing.OutCubic
        }
    }
    
    // Exit animation
    function startExitAnimation() {
        console.log("=== Starting exit animation ===")
        console.log("Current slideOffset:", slideOffset)
        console.log("Current fadeOpacity:", fadeOpacity)
        if (exitAnimation.running) {
            console.log("Exit animation already running, stopping it first")
            exitAnimation.stop()
        }
        exitAnimation.start()
    }
    
    SequentialAnimation {
        id: exitAnimation
        running: false
        ParallelAnimation {
            NumberAnimation {
                target: notificationItem
                property: "slideOffset"
                to: 400
                duration: 350
                easing.type: Easing.InCubic
            }
            NumberAnimation {
                target: notificationItem
                property: "fadeOpacity"
                to: 0.0
                duration: 350
                easing.type: Easing.InCubic
            }
        }
        ScriptAction {
            script: {
                console.log("Exit animation completed")
                // Animation finished, now emit signal to remove from list
                notificationItem.notificationClosed()
            }
        }
    }
    
    // Handle notification closed signal
    Connections {
        target: notification
        enabled: notification !== null
        
        function onClosed(reason) {
            console.log("Notification closed signal received, reason:", reason)
            startExitAnimation()
        }
    }
}


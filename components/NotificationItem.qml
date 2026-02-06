import QtQuick
import Quickshell.Services.Notifications

Rectangle {
    id: notificationItem
    
    property Notification notification: null
    property var sharedData: null
    
    signal notificationClosed()
    
    // Store notification reference to prevent garbage collection
    property var storedNotification: null
    
    // Flag to prevent double timer start
    property bool timerStarted: false
    
    // Helper function to start auto-dismiss timer
    function startAutoDismissTimer() {
        if (timerStarted) {
            return
        }
        
        // Use storedNotification as fallback if notification is null
        var notif = notification || storedNotification
        
        if (!notif) {
            return
        }
        
        // Check expireTimeout - handle undefined, null, 0, -1, and positive values
        var expireTimeout = notif.expireTimeout
        
        
        // Always use default 5 seconds for auto-dismiss, regardless of expireTimeout
        // Many notifications have expireTimeout = -1, but we want them to auto-dismiss anyway
        // Only use expireTimeout if it's a positive number greater than 0
        var timeout = 5000  // Default 5 seconds
        
        if (expireTimeout && expireTimeout > 0 && expireTimeout !== -1) {
            // Use the notification's timeout if it's valid and positive
            timeout = expireTimeout
        } else {
        }
        
        
        // Stop timer if already running
        if (autoDismissTimer.running) {
            autoDismissTimer.stop()
        }
        
        // Set interval first
        autoDismissTimer.interval = timeout
        
        autoDismissTimer.start()
        
        // Start progress bar animation - wait for progressBar to be ready
        var startProgressAnimation = function() {
            if (progressBar && progressBar.width > 0) {
                // Set initial width to full
                progressBarWidth = progressBar.width
                // Configure animation
                progressBarAnimation.from = progressBar.width
                progressBarAnimation.to = 0
                progressBarAnimation.duration = timeout
                // Start animation
                progressBarAnimation.start()
            } else {
                // Retry after a short delay
                var retryTimer = Qt.createQmlObject('import QtQuick; Timer { interval: 200; running: true; repeat: false }', notificationItem)
                retryTimer.triggered.connect(startProgressAnimation)
            }
        }
        
        // Start animation after a small delay to ensure progressBar is ready
        Qt.callLater(startProgressAnimation)
        
        timerStarted = true
        
        
        // Verify after a moment
        var verifyTimer = Qt.createQmlObject('import QtQuick; Timer { interval: 200; running: true; repeat: false }', notificationItem)
        verifyTimer.triggered.connect(function() {
        })
    }
    
    // Auto-dismiss timer
    Timer {
        id: autoDismissTimer
        interval: 5000  // 5 seconds
        running: false
        repeat: false
        onTriggered: {
            startExitAnimation()
        }
        onRunningChanged: {
        }
    }
    
    // Progress bar width property - will be animated from full to zero
    property real progressBarWidth: 0
    
    width: 304
    height: notificationContent.height + 32
    radius: 0
    color: getBackgroundColor()
    
    // Enhanced shadow effect with multiple layers
    
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
                        font.pixelSize: 9
                        font.family: "sans-serif"
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
                        font.pixelSize: 13
                        font.family: "sans-serif"
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
                    width: 25
                    height: 25
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
                        font.pixelSize: 13
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
                            mouse.accepted = true
                            
                            // Try to dismiss notification - use storedNotification as fallback
                            var notif = notificationItem.notification || notificationItem.storedNotification
                            if (notif) {
                                try {
                                    notif.dismiss()
                                } catch(e) {
                                    // Fallback: start exit animation
                                    notificationItem.startExitAnimation()
                                }
                            } else {
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
                font.pixelSize: 10
                font.family: "sans-serif"
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
        }
    }
    
    // Progress bar showing time until auto-dismiss - at the bottom
    // This line shrinks from left to right as time passes
    Rectangle {
        id: progressBar
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 2
        color: "transparent"  // Background is transparent, only the fill is visible
        visible: true  // Always visible when notification exists
        z: 100  // Ensure it's above other elements
        
        Rectangle {
            id: progressFill
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: notificationItem.progressBarWidth
            radius: 0
            // Use white/light color for better visibility
            color: sharedData && sharedData.colorAccent ? sharedData.colorAccent : "#ffffff"
            opacity: 1.0  // Full opacity for visibility
        }
    }
    
    // Animation for progress bar width - shrinks from full to zero
    NumberAnimation {
        id: progressBarAnimation
        target: notificationItem
        property: "progressBarWidth"
        from: 0  // Will be set before starting
        to: 0
        duration: 5000
        easing.type: Easing.Linear
        running: false
    }
    
    // Click to dismiss - exclude close button area completely
    MouseArea {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.rightMargin: 50  // Leave space for close button (right 50px)
        cursorShape: Qt.PointingHandCursor
        z: -1  // Lower than close button (z: 10000) - use negative to ensure it doesn't block
        propagateComposedEvents: false  // Don't propagate to avoid conflicts
        enabled: true
        onClicked: function(mouse) {
            // Only dismiss if not clicking on close button area
            var clickX = mouse.x
            var buttonAreaStart = width - 50
            if (clickX < buttonAreaStart) {
                if (notification) {
                    notification.dismiss()
                } else {
                    startExitAnimation()
                }
            }
        }
    }
    
    // Animation states
    property real slideOffset: 304  // Start exactly at the width of the item
    property real fadeOpacity: 0.0  // Start invisible
    property real itemScale: 0.95   // Slight scale start
    
    // Premium Look Bindings
    opacity: fadeOpacity
    scale: itemScale
    
    transform: Translate {
        x: slideOffset
    }
    
    // Ensure content is visible
    clip: false
    
    // Component.onCompleted - update texts if notification is already set
    Component.onCompleted: {
        
        if (notification) {
            storedNotification = notification
            
            // Update texts immediately
            if (appNameText) appNameText.text = notification.appName || notification.desktopEntry || "Notification"
            if (summaryText) summaryText.text = notification.summary || ""
            if (bodyText) {
                var body = notification.body || ""
                if (body.length === 0) body = notification.summary || ""
                bodyText.text = body
            }
            
            // Start auto-dismiss timer
            if (!timerStarted) {
                var notifRef = notification
                var startTimer = Qt.createQmlObject('import QtQuick; Timer { interval: 200; running: true; repeat: false }', notificationItem)
                startTimer.triggered.connect(function() {
                    if (!timerStarted && notifRef) {
                        if (!storedNotification) storedNotification = notifRef
                        startAutoDismissTimer()
                    }
                })
            }
        }
        
        // Premium Entrance Animation
        enterAnimation.start()
    }
    
    // Update when notification property changes
    onNotificationChanged: {
        if (notification) {
            storedNotification = notification
            if (appNameText) appNameText.text = notification.appName || notification.desktopEntry || "Notification"
            if (summaryText) summaryText.text = notification.summary || ""
            if (bodyText) bodyText.text = notification.body || notification.summary || ""
            
            if (!timerStarted) {
                var notifRef = notification
                var startTimer = Qt.createQmlObject('import QtQuick; Timer { interval: 100; running: true; repeat: false }', notificationItem)
                startTimer.triggered.connect(function() {
                    if (!timerStarted && notifRef) {
                        if (!storedNotification) storedNotification = notifRef
                        startAutoDismissTimer()
                    }
                })
            }
        }
    }
    
    // Premium Entrance Animation
    ParallelAnimation {
        id: enterAnimation
        NumberAnimation {
            target: notificationItem
            property: "slideOffset"
            from: 304
            to: 0
            duration: 600
            easing.type: Easing.OutExpo
        }
        NumberAnimation {
            target: notificationItem
            property: "fadeOpacity"
            from: 0.0
            to: 1.0
            duration: 500
            easing.type: Easing.OutQuart
        }
        NumberAnimation {
            target: notificationItem
            property: "itemScale"
            from: 0.9
            to: 1.0
            duration: 650
            easing.type: Easing.OutBack
            easing.amplitude: 1.1
        }
    }
    
    // Exit animation
    function startExitAnimation() {
        if (exitAnimation.running) exitAnimation.stop()
        exitAnimation.start()
    }
    
    SequentialAnimation {
        id: exitAnimation
        running: false
        ParallelAnimation {
            NumberAnimation {
                target: notificationItem
                property: "slideOffset"
                to: 304
                duration: 500
                easing.type: Easing.InExpo
            }
            NumberAnimation {
                target: notificationItem
                property: "fadeOpacity"
                to: 0.0
                duration: 400
                easing.type: Easing.InQuart
            }
            NumberAnimation {
                target: notificationItem
                property: "itemScale"
                to: 0.95
                duration: 500
                easing.type: Easing.InBack
            }
        }
        ScriptAction {
            script: {
                notificationItem.notificationClosed()
            }
        }
    }
    
    // Handle notification closed signal
    Connections {
        target: notification
        enabled: notification !== null
        
        function onClosed(reason) {
            startExitAnimation()
        }
    }
}


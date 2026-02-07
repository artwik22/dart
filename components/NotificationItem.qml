import QtQuick
import Quickshell.Services.Notifications

Item {
    id: notificationWrapper
    width: 340  // Increased width
    height: 52  // Increased height
    
    // Properties passed from NotificationDisplay
    property Notification notification: null
    property var sharedData: null
    
    // Forward signal from inner Rectangle
    signal notificationClosed()
    
    Rectangle {
        id: notificationItem
        
        property Notification notification: parent.notification
        property var sharedData: parent.sharedData
        
        signal notificationClosed()
        
        // Connect inner signal to wrapper signal
        onNotificationClosed: parent.notificationClosed()
        
        // Store notification reference to prevent garbage collection
        property var storedNotification: null
        
        // Flag to prevent double timer start
        property bool timerStarted: false
        
        // OneUI 6 Animation Properties
        property real pillWidth: 52  // Starts as a square/quircle
        property real contentOpacity: 0.0  // Content starts invisible
        property real contentOffset: 5  // Content slides up slightly
        property real iconX: 14 // Center of 52px ( (52-24)/2 )
        
        // Dimensions
        width: pillWidth
        height: 52  // Increased height
        radius: {
            if (!sharedData || !sharedData.notificationRounding) return 14;
            if (sharedData.notificationRounding === "pill") return 26;
            if (sharedData.notificationRounding === "none") return 0;
            return 14; // standard
        }
        
        // Expansion from correct edge based on position
        x: {
            if (!sharedData || sharedData.notificationPosition === "top") return (340 - pillWidth) / 2;
            if (sharedData.notificationPosition === "top-left") return 0;
            if (sharedData.notificationPosition === "top-right") return 340 - pillWidth;
            return (340 - pillWidth) / 2;
        }
        
        transform: Translate {
            id: entranceTranslate
            y: 0
        }
    
    color: getBackgroundColor()
    
    // Helper function to start auto-dismiss timer
    function startAutoDismissTimer() {
        // Force 4000ms timeout as requested by user ("ma byc timer 4 sekundy")
        var timeout = 4000 
        
        if (autoDismissTimer.running) {
            autoDismissTimer.stop()
        }

        autoDismissTimer.interval = timeout
        autoDismissTimer.start()
        
        notificationItem.timerStarted = true
    }
    
    // Auto-dismiss timer
    Timer {
        id: autoDismissTimer
        interval: 4000
        running: false
        repeat: false
        onTriggered: {
            var n = notification || notificationItem.storedNotification
            if (n) {
                try {
                    n.dismiss()
                } catch (err) {
                    // Fallback to force destroy
                    notificationItem.notificationClosed()
                }
            } else {
                // Bypass animation to ensure removal
                notificationItem.notificationClosed()
            }
        }
    }


    

    
    function getBackgroundColor() {
        if (!sharedData) return "#1e1e1e"
        
        if (notification && notification.urgency === NotificationUrgency.Critical) {
            return sharedData.colorAccent ? Qt.darker(sharedData.colorAccent, 1.2) : "#2a1a1a"
        } else if (notification && notification.urgency === NotificationUrgency.Normal) {
            return sharedData.colorPrimary ? Qt.lighter(sharedData.colorPrimary, 1.1) : "#1e1e1e"
        } else {
            return sharedData.colorBackground ? Qt.lighter(sharedData.colorBackground, 1.05) : "#1a1a1a"
        }
    }
    
    // Content container - positioned with offset for slide-in effect
    Item {
        id: contentContainer
        anchors.fill: parent
        anchors.leftMargin: 20
        anchors.rightMargin: 20
        anchors.topMargin: 8
        anchors.bottomMargin: 8
        opacity: notificationItem.contentOpacity
        
        transform: Translate {
            y: notificationItem.contentOffset
        }
        
        Row {
            id: contentRow
            anchors.fill: parent
            spacing: 12
            
            // Icon Spacer (keeps layout consistent when icon moves out)
            Item {
                width: 24
                height: 24
                visible: true // Always visible to prevent text overlap with the floating icon
            }
            
            // Text content
            Column {
                id: textColumn
                width: parent.width - (iconRect.visible ? iconRect.width + 12 : 0) - (closeButton.visible ? closeButton.width + 12 : 0)
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2
                
                Text {
                    id: appNameText
                    text: "Notification"
                    font.pixelSize: 9
                    font.family: "sans-serif"
                    font.weight: Font.Bold
                    color: sharedData && sharedData.colorAccent ? Qt.lighter(sharedData.colorAccent, 1.2) : "#9aa0a6"
                    elide: Text.ElideRight
                    width: parent.width
                    opacity: 0.9
                }
                
                Text {
                    id: summaryText
                    text: ""
                    font.pixelSize: 11
                    font.family: "sans-serif"
                    font.weight: Font.DemiBold
                    color: "#ffffff"
                    elide: Text.ElideRight
                    width: parent.width
                    visible: text && text.length > 0
                }
            }
            
            // Close button
            Item {
                id: closeButton
                width: 20
                height: 20
                anchors.verticalCenter: parent.verticalCenter
                
                Rectangle {
                    anchors.fill: parent
                    radius: 10
                    color: closeButtonMouseArea.containsMouse ? 
                        (sharedData && sharedData.colorAccent ? sharedData.colorAccent : "#ff4444") : 
                        "transparent"
                    
                    opacity: closeButtonMouseArea.containsMouse ? 1.0 : 0.7
                    
                    Behavior on color {
                        ColorAnimation {
                            duration: 200
                            easing.type: Easing.OutQuart
                        }
                    }
                    
                    Behavior on opacity {
                        NumberAnimation {
                            duration: 150
                            easing.type: Easing.OutQuart
                        }
                    }
                }
                
                Text {
                    text: "×"
                    font.pixelSize: 16
                    font.weight: Font.Bold
                    anchors.centerIn: parent
                    color: closeButtonMouseArea.containsMouse ? "#ffffff" : "#888888"
                    
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
                    z: 10000
                    propagateComposedEvents: false
                    acceptedButtons: Qt.LeftButton
                    enabled: true
                    onClicked: function(mouse) {
                        mouse.accepted = true
                        var notif = notificationItem.notification || notificationItem.storedNotification
                        if (notif) {
                            try {
                                notif.dismiss()
                            } catch(e) {
                                notificationItem.startExitAnimation()
                            }
                        } else {
                            notificationItem.startExitAnimation()
                        }
                    }
                }
            }
        }
        }
        
        // Floating App Icon (Visible on Squircle)
        Rectangle {
            id: iconRect
            x: notificationItem.iconX
            width: 24
            height: 24
            radius: 12
            anchors.verticalCenter: parent.verticalCenter
            color: sharedData && sharedData.colorSecondary ? Qt.lighter(sharedData.colorSecondary, 1.1) : "#1f1f1f"
            z: 10 // On top of background, below content text (if overlapping)
            
            // Generic Notification Icon (Bell) - visible in squircle / as fallback
            Text {
                text: "󱅫" // Material Design bell icon if font supports it, or standard bell
                font.pixelSize: 16
                color: "#ffffff"
                anchors.centerIn: parent
                opacity: notificationItem.pillWidth < 100 ? 1.0 : (notification && notification.appIcon ? 0.0 : 0.8)
                visible: opacity > 0
                
                Component.onCompleted: {
                    // Use standard bell if nerd font icon fails or just use the emoji with explicit color
                    if (text === "") text = "🔔"
                }

                Behavior on opacity {
                    NumberAnimation { duration: 250 }
                }
            }

            // Real App Icon
            Image {
                anchors.fill: parent
                anchors.margins: 4
                source: notification ? notification.appIcon : ""
                fillMode: Image.PreserveAspectFit
                smooth: true
                antialiasing: true
                opacity: notificationItem.pillWidth > 100 && notification && notification.appIcon ? 1.0 : 0.0
                visible: opacity > 0
                
                Behavior on opacity {
                    NumberAnimation { duration: 250 }
                }
            }
        }
    }
    

    
    // Click to dismiss (excluding close button area)
    MouseArea {
        anchors.fill: parent
        anchors.rightMargin: 40
        cursorShape: Qt.PointingHandCursor
        z: -1
        propagateComposedEvents: false
        enabled: true
        onClicked: function(mouse) {
            if (notification) {
                notification.dismiss()
            } else {
                startExitAnimation()
            }
        }
    }
    
    // Component initialization
    Component.onCompleted: {
        if (notification) {
            notificationItem.storedNotification = notification
            
            // Update texts immediately
            if (appNameText) appNameText.text = notification.appName || notification.desktopEntry || "Notification"
            if (summaryText) summaryText.text = notification.summary || ""
            
            // Start auto-dismiss timer directly
            if (!notificationItem.timerStarted) {
                notificationItem.startAutoDismissTimer()
            }

        }
        
        // Start OneUI 6 entrance animation
        enterAnimation.start()
    }
    
    // Update when notification property changes
    onNotificationChanged: {
        if (notification) {
            storedNotification = notification
            if (appNameText) appNameText.text = notification.appName || notification.desktopEntry || "Notification"
            if (summaryText) summaryText.text = notification.summary || ""
            
            if (!notificationItem.timerStarted) {
                notificationItem.startAutoDismissTimer()
            }

        }
    }
    
    // OneUI 6 Entrance Animation - "Fast Drop-In Quircle"
    SequentialAnimation {
        id: enterAnimation
        
        // Stage 1: Drop & Appear as Quircle
        ParallelAnimation {
            NumberAnimation {
                target: notificationItem
                property: "scale"
                from: 0.5
                to: 1.0
                duration: 250
                easing.type: Easing.OutBack
                easing.overshoot: 1.0
            }
            NumberAnimation {
                target: notificationItem
                property: "opacity"
                from: 0
                to: 1
                duration: 200
                easing.type: Easing.OutQuint
            }
            // Drop effect (animate Y translation)
            NumberAnimation {
                target: entranceTranslate
                property: "y"
                from: -40
                to: 0
                duration: 250
                easing.type: Easing.OutQuint
            }
            // Ensure width starts at height (square/quircle)
            ScriptAction { script: notificationItem.pillWidth = 52 }
        }
        
        // Brief pause
        PauseAnimation { duration: 50 }
        
        // Stage 2: Expand Width (Faster)
        ParallelAnimation {
            NumberAnimation {
                target: notificationItem
                property: "pillWidth"
                from: 52
                to: 340
                duration: 350
                easing.type: Easing.OutQuint
            }
            NumberAnimation {
                target: notificationItem
                property: "iconX"
                from: 14
                to: 20
                duration: 350
                easing.type: Easing.OutQuint
            }
        }
        
        // Stage 3: Content Fade In (Faster)
        ParallelAnimation {
            NumberAnimation {
                target: notificationItem
                property: "contentOpacity"
                from: 0
                to: 1
                duration: 200
                easing.type: Easing.OutQuint
            }
            NumberAnimation {
                target: notificationItem
                property: "contentOffset"
                from: 10
                to: 0
                duration: 200
                easing.type: Easing.OutQuint
            }
        }
    }
    
    // Exit animation - Snappy Tuck Away
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
                property: "scale"
                to: 0.9
                duration: 250
                easing.type: Easing.OutQuint
            }
            NumberAnimation {
                target: notificationItem
                property: "opacity"
                to: 0
                duration: 250
                easing.type: Easing.OutQuint
            }
            NumberAnimation {
                target: notificationItem
                property: "pillWidth"
                to: 52
                duration: 300
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: notificationItem
                property: "contentOpacity"
                to: 0
                duration: 150
                easing.type: Easing.OutQuint
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

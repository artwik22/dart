import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQml
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "."

PanelWindow {
    id: dashboardRoot

    signal perfUpdated()
    
    // Resource History Arrays
    property var cpuHistory: []
    property var ramHistory: []
    property var gpuHistory: []
    property var networkHistory: []
    
    // Resource Current Values (Implicitly defined by usage in timers, but declaring for clarity/safety)
    property int cpuUsageValue: 0
    property int ramUsageValue: 0
    property int gpuUsageValue: 0
    property real networkRxMBs: 0
    property real networkTxMBs: 0
    property int ramTotalGB: 0
    property int cpuTempValue: 0
    property int gpuTempValue: 0
    
    // Helper to push to history
    function pushHistory(arr, val) {
        if (!arr) arr = []
        arr.push(val)
        if (arr.length > 60) arr.shift()
        return arr
    }

    function getResourceHistory(res) {
        if (res === "ram") return ramHistory
        if (res === "gpu") return gpuHistory
        if (res === "network") return networkHistory
        return cpuHistory
    }
    
    function getResourceLabel(res) {
        if (res === "ram") return "RAM Usage"
        if (res === "gpu") return "GPU Usage"
        if (res === "network") return "Network"
        return "CPU Usage"
    }
    
    function getResourceIcon(res) {
        if (res === "ram") return "󰍛"
        if (res === "gpu") return "󰢮"
        if (res === "network") return "󰇚"
        return "󰻠"
    }
    
    function getResourceValueText(res) {
        if (res === "ram") return ramUsageValue + "%"
        if (res === "gpu") return gpuUsageValue + "%"
        if (res === "network") return (networkRxMBs + networkTxMBs).toFixed(1) + " MB/s"
        return cpuUsageValue + "%"
    }
    
    function getResourceSubText(res) {
        if (res === "ram") return (ramTotalGB > 0 ? ramTotalGB + " GB Total" : "")
        if (res === "gpu") return (gpuTempValue > 0 ? gpuTempValue + "°C" : "")
        if (res === "network") return "↓ " + networkRxMBs.toFixed(1) + " ↑ " + networkTxMBs.toFixed(1)
        return (cpuTempValue > 0 ? cpuTempValue + "°C" : "")
    }

    property string panelPos: (sharedData && sharedData.dashboardPosition) ? sharedData.dashboardPosition : "right"
    property bool isHorizontal: panelPos === "top" || panelPos === "bottom"
    
    // Configurable anchors based on panelPos
    anchors.right: panelPos === "left" ? false : true 
    anchors.left: panelPos === "right" ? false : true
    anchors.top: panelPos === "bottom" ? false : true
    anchors.bottom: panelPos === "top" ? false : true
    
    implicitWidth: !isHorizontal ? 449 : (Quickshell.screens.length > 0 && Quickshell.screens[0]) ? Quickshell.screens[0].width : 1920
    implicitHeight: isHorizontal ? 449 : (Quickshell.screens.length > 0 && Quickshell.screens[0]) ? Quickshell.screens[0].height : 1440
    
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qsdashboard"
    WlrLayershell.keyboardFocus: (showProgress > 0.5) ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    exclusiveZone: 0

    property int currentTab: 0
    property var sharedData: null

    // --- Animacja wejścia/wyjścia (bez glitchy) ---
    // showProgress 0..1, start zawsze 0; Binding ustawia cel, Behavior animuje
    property real showProgress: 0
    Binding on showProgress {
        value: (sharedData && sharedData.menuVisible) ? 1.0 : 0.0
    }
    Behavior on showProgress {
        NumberAnimation { duration: 450; easing.type: Easing.OutExpo }
    }
    visible: true
    color: "transparent"
    margins {
        top: panelPos === "top" ? -implicitHeight * (1.0 - showProgress) : 0
        bottom: panelPos === "bottom" ? -implicitHeight * (1.0 - showProgress) : 0
        right: panelPos === "right" ? -implicitWidth * (1.0 - showProgress) : 0
        left: panelPos === "left" ? -implicitWidth * (1.0 - showProgress) : 0
    }

    Item {
        id: dashboardContainer
        anchors.fill: parent
        opacity: showProgress
        enabled: showProgress > 0.02
        focus: showProgress > 0.02
        
        Keys.onPressed: function(event) {
            if (event.key === Qt.Key_Escape) {
                if (sharedData) {
                    sharedData.menuVisible = false
                }
                event.accepted = true
            }
        }
        
        // Swiss Design dashboard background - Strict, flat, bordered
        Rectangle {
            id: dashboardBackground
            anchors.fill: parent
            radius: (sharedData && sharedData.quickshellBorderRadius) ? sharedData.quickshellBorderRadius : 0
            color: (sharedData && sharedData.colorBackground) ? sharedData.colorBackground : "#ffffff"
        }

        Column {
            id: dashboardColumn
            anchors.fill: parent
            spacing: 0

            // ============ TOP NAVIGATION BAR ============
            Rectangle {
                id: navBar
                width: parent.width
                height: 50
                color: (sharedData && sharedData.colorPrimary) ? sharedData.colorPrimary : "#1a1a1a"
                
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 0
                    anchors.rightMargin: 0
                    spacing: 0
                    
                    Repeater {
                        id: navRepeater
                        model: [
                            { icon: "󰕮", label: "Dashboard" },
                            { icon: "󰨸", label: "Clipboard" },
                            { icon: "󰂚", label: "Notifications" }
                        ]
                        
                        Rectangle {
                            id: tabRect
                            Layout.fillWidth: true
                            Layout.preferredHeight: parent.height
                            color: "transparent"
                            
                            property bool isActive: currentTab === index
                            property bool isHovered: tabMouseArea.containsMouse
                            
                            // Background color on hover/active
                            Rectangle {
                                anchors.fill: parent
                                anchors.margins: 0
                                color: tabRect.isActive ? 
                                    ((sharedData && sharedData.colorSecondary) ? sharedData.colorSecondary : "#141414") : 
                                    (tabRect.isHovered ? 
                                        ((sharedData && sharedData.colorSecondary) ? sharedData.colorSecondary : "#141414") : 
                                        "transparent")
                                radius: (sharedData && sharedData.quickshellBorderRadius) ? sharedData.quickshellBorderRadius : 0
                            }
                            
                            Row {
                                anchors.centerIn: parent
                                spacing: 10
                                
                                Text {
                                    text: modelData.icon
                                    font.pixelSize: 15
                                    color: tabRect.isActive ? 
                                        ((sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#00ff41") : // Accent text on active
                                        ((sharedData && sharedData.colorText) ? sharedData.colorText : "#000000")
                                    opacity: 1.0
                                    anchors.verticalCenter: parent.verticalCenter
                                    
                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 200
                                            easing.type: Easing.OutQuart
                                        }
                                    }
                                    
                                    Behavior on font.pixelSize {
                                        NumberAnimation {
                                            duration: 150
                                            easing.type: Easing.OutQuart
                                        }
                                    }
                                }
                                
                                Text {
                                    text: modelData.label
                                    font.pixelSize: 12
                                    font.family: "sans-serif"
                                    font.weight: tabRect.isActive ? Font.Bold : Font.Normal
                                    color: tabRect.isActive ? 
                                        ((sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#00ff41") : // Accent text on active
                                        ((sharedData && sharedData.colorText) ? sharedData.colorText : "#000000")
                                    opacity: 1.0
                                    anchors.verticalCenter: parent.verticalCenter
                                    
                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 200
                                            easing.type: Easing.OutQuart
                                        }
                                    }
                                    
                                    Behavior on font.weight {
                                        PropertyAnimation {
                                            duration: 200
                                            easing.type: Easing.OutQuart
                                        }
                                    }
                                }
                            }
                            

                            
                            MouseArea {
                                id: tabMouseArea
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                hoverEnabled: true
                                onClicked: currentTab = index
                            }
                        }
                    }
                }
                
            }

            // ============ CONTENT AREA ============
            Item {
                id: contentArea
                width: parent.width
                height: parent.height - navBar.height
                clip: true

                // ============ TAB 0: DASHBOARD ============
                Item {
                    id: dashboardTab
                    anchors.fill: parent
                    visible: currentTab === 0
                    opacity: currentTab === 0 ? 1.0 : 0.0
                    x: currentTab === 0 ? 0 : (currentTab < 0 ? -parent.width * 0.3 : parent.width * 0.3)
                    scale: currentTab === 0 ? 1.0 : 0.95
                    
                    Behavior on opacity {
                        NumberAnimation { 
                            duration: 400
                            easing.type: Easing.OutCubic
                        }
                    }
                    
                    Behavior on x {
                        NumberAnimation {
                            duration: 400
                            easing.type: Easing.OutCubic
                        }
                    }
                    
                    Behavior on scale {
                        NumberAnimation {
                            duration: 400
                            easing.type: Easing.OutCubic
                        }
                    }
                    
                    ColumnLayout {
                        id: dashboardTabColumn
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 5
                        
                        // Row with left tile (Battery or Network) and Quick Actions side by side
                        Row {
                            Layout.fillWidth: true
                            Layout.fillHeight: false
                            Layout.preferredHeight: 90
                            spacing: 5
                            
                            opacity: showProgress > 0.01 ? 1.0 : 0.0
                            scale: showProgress > 0.01 ? 1.0 : 0.9
                            transform: Translate {
                                y: showProgress > 0.01 ? 0 : 40
                                Behavior on y {
                                    SequentialAnimation {
                                        PauseAnimation { duration: 50 }
                                        NumberAnimation { duration: 700; easing.type: Easing.OutBack }
                                    }
                                }
                            }
                            
                            Behavior on opacity {
                                SequentialAnimation {
                                    PauseAnimation { duration: 50 }
                                    NumberAnimation { duration: 500; easing.type: Easing.OutCubic }
                                }
                            }
                            Behavior on scale {
                                SequentialAnimation {
                                    PauseAnimation { duration: 50 }
                                    NumberAnimation { duration: 600; easing.type: Easing.OutBack }
                                }
                            }

                            // Left tile container: Battery or Network (Pobieranie i wysyłanie)
                            Item {
                                width: (parent.width - 12) / 2
                                height: parent.height
                                
                                // Battery % Card - Swiss Style Poster
                                Rectangle {
                                    anchors.fill: parent
                                    visible: !(sharedData && sharedData.dashboardTileLeft === "network")
                                    radius: (sharedData && sharedData.quickshellBorderRadius) ? sharedData.quickshellBorderRadius : 0
                                    color: "transparent"

                                    Column {
                                        anchors.fill: parent
                                        anchors.margins: 0
                                        spacing: 0
                                        
                                        // Small metadata label
                                        Text {
                                            text: "SYSTEM / POWER"
                                            font.pixelSize: 9
                                            font.weight: Font.Bold
                                            font.family: "sans-serif"
                                            font.capitalization: Font.AllUppercase
                                            color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#000000"
                                            opacity: 0.6
                                        }
                                        
                                        Item { height: 4; width: 1 }

                                        // Sub-label
                                        Text {
                                            text: "BATTERY LEVEL"
                                            font.pixelSize: 18
                                            font.weight: Font.Bold
                                            font.family: "sans-serif"
                                            font.capitalization: Font.AllUppercase
                                            color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#000000"
                                            opacity: 0.9
                                        }

                                        Item { height: 0; width: 1; Layout.fillHeight: true }

                                        // Hero Number - Large but fitting
                                        Text {
                                            text: batteryPercent >= 0 ? batteryPercent : "—"
                                            font.pixelSize: 52 
                                            font.family: "sans-serif"
                                            font.weight: Font.Bold
                                            color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#000000"
                                            
                                            Text {
                                                text: "%"
                                                font.pixelSize: 18
                                                font.weight: Font.Bold
                                                anchors.left: parent.right
                                                anchors.top: parent.top
                                                anchors.topMargin: 8
                                                color: (sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#00ff41"
                                            }
                                        }
                                    }
                                }
                                                                // Network (Pobieranie i wysyłanie) Card - Swiss Style Poster
                                    Rectangle {
                                        anchors.fill: parent
                                        visible: (sharedData && sharedData.dashboardTileLeft === "network")
                                        radius: (sharedData && sharedData.quickshellBorderRadius) ? sharedData.quickshellBorderRadius : 0
                                        color: "transparent"

                                        Column {
                                            anchors.fill: parent
                                            anchors.margins: 0 // Flush to edges for poster look
                                            spacing: 0
                                            
                                            // Small metadata label
                                            Text {
                                                text: "NETWORK IO / PRECIS"
                                                font.pixelSize: 9
                                                font.weight: Font.Bold
                                                font.family: "sans-serif"
                                                font.capitalization: Font.AllUppercase
                                                color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#000000"
                                                opacity: 0.6
                                            }

                                            Item { height: 10; width: 1 }

                                            // Hero Typography
                                            Row {
                                                spacing: 5
                                                Text {
                                                    text: "↓"
                                                    font.pixelSize: 24
                                                    font.weight: Font.Bold
                                                    color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#000000"
                                                    anchors.baseline: valDown.baseline
                                                }
                                                Text {
                                                    id: valDown
                                                    text: (networkRxMBs < 0.01 ? "0.0" : networkRxMBs.toFixed(1))
                                                    font.pixelSize: 28
                                                    font.family: "sans-serif"
                                                    font.weight: Font.Black
                                                    color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#000000"
                                                    lineHeight: 0.8
                                                }
                                            }
                                            
                                            Row {
                                                spacing: 5
                                                Text {
                                                    text: "↑"
                                                    font.pixelSize: 24
                                                    font.weight: Font.Bold
                                                    color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#000000"
                                                    anchors.baseline: valUp.baseline
                                                }
                                                Text {
                                                    id: valUp
                                                    text: (networkTxMBs < 0.01 ? "0.0" : networkTxMBs.toFixed(1))
                                                    font.pixelSize: 28
                                                    font.family: "sans-serif"
                                                    font.weight: Font.Black
                                                    color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#000000"
                                                    lineHeight: 0.8
                                                }
                                            }
                                            
                                            Item { Layout.fillHeight: true; width: 1 }
                                            
                                            Text {
                                                text: "MB/S TRANSFER RATE"
                                                font.pixelSize: 9
                                                font.weight: Font.Bold
                                                font.letterSpacing: 1
                                                color: (sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#00ff41"
                                            }
                                        }
                                    }                          }
                            
                            // Swiss Style Quick Actions Card (right)
                        Rectangle {
                                width: (parent.width - 12) / 2
                                height: parent.height
                            radius: (sharedData && sharedData.quickshellBorderRadius) ? sharedData.quickshellBorderRadius : 0
                            color: "transparent" // Transparent, only border
                            
                            
                                Column {
                                    anchors.fill: parent
                                    anchors.margins: 8
                                    spacing: 5
                                    
                                    Grid {
                                        id: quickActionsGrid
                                    columns: 2
                                    spacing: 5
                                    width: parent.width
                                        height: parent.height - 16
                                    
                                    // Toggle Sidebar Button (Swiss Block)
                                    Rectangle {
                                        width: (quickActionsGrid.width - 4) / 2
                                        height: 33
                                        radius: (sharedData && sharedData.quickshellBorderRadius) ? sharedData.quickshellBorderRadius : 0
                                        clip: true

                                        // Softer style
                                        color: (sharedData && sharedData.colorSecondary) ? sharedData.colorSecondary : "#1a1a1a"
                                        opacity: toggleSidebarQuickMouseArea.containsMouse ? 0.8 : 1.0
                                        
                                        Row {
                                            anchors.centerIn: parent
                                            spacing: 6
                                            width: Math.min(parent.width - 7, implicitWidth)
                                            
                                            Text {
                                                text: "󰍜"
                                                font.pixelSize: 11
                                                font.family: "sans-serif"
                                                color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff"
                                                anchors.verticalCenter: parent.verticalCenter
                                            }
                                            
                                            Text {
                                                text: "SIDEBAR"
                                                font.pixelSize: 9
                                                font.weight: Font.Bold
                                                font.capitalization: Font.AllUppercase
                                                font.family: "sans-serif"
                                                color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff"
                                                anchors.verticalCenter: parent.verticalCenter
                                                elide: Text.ElideRight
                                                maximumLineCount: 1
                                                width: Math.max(0, parent.width - 18)
                                            }
                                        }
                                        
                                        MouseArea {
                                            id: toggleSidebarQuickMouseArea
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            hoverEnabled: true
                                            onClicked: {
                                                if (sharedData && sharedData.sidebarVisible !== undefined) {
                                                    sharedData.sidebarVisible = !sharedData.sidebarVisible
                                                }
                                            }
                                        }
                                    }
                                    
                                    // Quick Action Button Style (Swiss Block)
                                    Rectangle {
                                        width: (quickActionsGrid.width - 4) / 2
                                        height: 33
                                        radius: (sharedData && sharedData.quickshellBorderRadius) ? sharedData.quickshellBorderRadius : 0
                                        clip: true
                                        
                                        // Softer style
                                        color: ((dndQuickMouseArea.containsMouse) || (sharedData && sharedData.notificationsEnabled === false)) ? 
                                               ((sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#00ff41") : // Green on active/hover
                                               ((sharedData && sharedData.colorSecondary) ? sharedData.colorSecondary : "#1a1a1a") // Dark default

                                        Row {
                                            anchors.centerIn: parent
                                            spacing: 6
                                            width: Math.min(parent.width - 7, implicitWidth)
                                            
                                            Text {
                                                text: "󰂛"
                                                font.pixelSize: 11
                                                font.family: "sans-serif"
                                                color: ((dndQuickMouseArea.containsMouse) || (sharedData && sharedData.notificationsEnabled === false)) ? 
                                                       ((sharedData && sharedData.colorBackground) ? sharedData.colorBackground : "#ffffff") : // White text on green
                                                       ((sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff") // White text on dark
                                                anchors.verticalCenter: parent.verticalCenter
                                            }
                                            
                                            Text {
                                                text: "NO DISTURB"
                                                font.pixelSize: 9
                                                font.weight: Font.Bold
                                                font.family: "sans-serif"
                                                font.capitalization: Font.AllUppercase
                                                color: ((dndQuickMouseArea.containsMouse) || (sharedData && sharedData.notificationsEnabled === false)) ? 
                                                       ((sharedData && sharedData.colorBackground) ? sharedData.colorBackground : "#ffffff") : // White text on green
                                                       ((sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff") // White text on dark
                                                anchors.verticalCenter: parent.verticalCenter
                                                elide: Text.ElideRight
                                                maximumLineCount: 1
                                                width: Math.max(0, parent.width - 18)
                                            }
                                        }
                                        
                                        MouseArea {
                                            id: dndQuickMouseArea
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            hoverEnabled: true
                                            onClicked: {
                                                if (sharedData && sharedData.notificationsEnabled !== undefined) {
                                                    sharedData.notificationsEnabled = !sharedData.notificationsEnabled
                                                }
                                            }
                                        }
                                    }
                                    
                                    // Lock Button (Swiss Block)
                                    Rectangle {
                                        width: (quickActionsGrid.width - 4) / 2
                                        height: 33
                                        radius: (sharedData && sharedData.quickshellBorderRadius) ? sharedData.quickshellBorderRadius : 0
                                        clip: true

                                        color: (sharedData && sharedData.colorSecondary) ? sharedData.colorSecondary : "#1a1a1a"
                                        opacity: lockQuickMouseArea.containsMouse ? 0.8 : 1.0
                                        
                                        Row {
                                            anchors.centerIn: parent
                                            spacing: 6
                                            width: Math.min(parent.width - 7, implicitWidth)
                                            
                                            Text {
                                                text: "󰌾"
                                                font.pixelSize: 11
                                                font.family: "sans-serif"
                                                color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff"
                                                anchors.verticalCenter: parent.verticalCenter
                                            }
                                            
                                            Text {
                                                text: "LOCK"
                                                font.pixelSize: 9
                                                font.weight: Font.Bold
                                                font.capitalization: Font.AllUppercase
                                                font.family: "sans-serif"
                                                color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff"
                                                anchors.verticalCenter: parent.verticalCenter
                                                elide: Text.ElideRight
                                                maximumLineCount: 1
                                                width: Math.max(0, parent.width - 18)
                                            }
                                        }
                                        
                                        MouseArea {
                                            id: lockQuickMouseArea
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            hoverEnabled: true
                                            onClicked: {
                                                // Własny lock screen – overlay z polem hasła (bez swaylock/loginctl)
                                                if (sharedData) {
                                                    sharedData.lockScreenVisible = true
                                                    sharedData.menuVisible = false
                                                }
                                            }
                                        }
                                    }
                                    
                                    // Poweroff Button (Swiss Block)
                                    Rectangle {
                                        width: (quickActionsGrid.width - 4) / 2
                                        height: 33
                                        radius: (sharedData && sharedData.quickshellBorderRadius) ? sharedData.quickshellBorderRadius : 0
                                        clip: true

                                        color: (sharedData && sharedData.colorSecondary) ? sharedData.colorSecondary : "#1a1a1a"
                                        opacity: poweroffQuickMouseArea.containsMouse ? 0.8 : 1.0
                                        
                                        Row {
                                            anchors.centerIn: parent
                                            spacing: 6
                                            width: Math.min(parent.width - 7, implicitWidth)
                                            
                                            Text {
                                                text: "󰐥"
                                                font.pixelSize: 11
                                                font.family: "sans-serif"
                                                color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff"
                                                anchors.verticalCenter: parent.verticalCenter
                                            }
                                            
                                            Text {
                                                text: "POWEROFF"
                                                font.pixelSize: 9
                                                font.weight: Font.Bold
                                                font.capitalization: Font.AllUppercase
                                                font.family: "sans-serif"
                                                color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff"
                                                anchors.verticalCenter: parent.verticalCenter
                                                elide: Text.ElideRight
                                                maximumLineCount: 1
                                                width: Math.max(0, parent.width - 18)
                                            }
                                        }
                                        
                                        MouseArea {
                                            id: poweroffQuickMouseArea
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            hoverEnabled: true
                                            onClicked: {
                                                if (sharedData && sharedData.runCommand) sharedData.runCommand(['systemctl', 'poweroff'])
                                                // Close dashboard after poweroff
                                                if (sharedData) {
                                                    sharedData.menuVisible = false
                                                }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Date/Calendar or GitHub Activity Card – Swiss Style
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.preferredHeight: 220
                            Layout.minimumHeight: 192
                            radius: (sharedData && sharedData.quickshellBorderRadius) ? sharedData.quickshellBorderRadius : 0
                            color: "transparent"

                            opacity: showProgress > 0.01 ? 1.0 : 0.0
                            scale: showProgress > 0.01 ? 1.0 : 0.9
                            transform: Translate {
                                y: showProgress > 0.01 ? 0 : 40
                                Behavior on y {
                                    SequentialAnimation {
                                        PauseAnimation { duration: 100 }
                                        NumberAnimation { duration: 700; easing.type: Easing.OutBack }
                                    }
                                }
                            }
                            
                            Behavior on opacity {
                                SequentialAnimation {
                                    PauseAnimation { duration: 100 }
                                    NumberAnimation { duration: 500; easing.type: Easing.OutCubic }
                                }
                            }
                            Behavior on scale {
                                SequentialAnimation {
                                    PauseAnimation { duration: 100 }
                                    NumberAnimation { duration: 600; easing.type: Easing.OutBack }
                                }
                            }

                            Loader {
                                id: dashboardCalendarGithubLoader
                                anchors.fill: parent
                                anchors.margins: 16
                                active: true
                                sourceComponent: (sharedData && sharedData.sidepanelContent === "github")
                                                 ? githubActivityDashboardComponent
                                                 : calendarDashboardComponent
                            }
                        }

                        Component {
                            id: calendarDashboardComponent
                            Item {
                                anchors.fill: parent

                                Column {
                                    anchors.fill: parent
                                    anchors.margins: 0
                                    spacing: 5

                                    // Day headers
                                    Row {
                                        spacing: 5
                                        anchors.horizontalCenter: parent.horizontalCenter

                                        Repeater {
                                            model: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
                                            Text {
                                                text: modelData
                                                font.pixelSize: 9
                                                font.weight: Font.Bold
                                                font.family: "sans-serif"
                                                color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#000000"
                                                width: 22
                                                horizontalAlignment: Text.AlignHCenter
                                            }
                                        }
                                    }

                                    // Calendar grid
                                    Grid {
                                        columns: 7
                                        spacing: 5
                                        anchors.horizontalCenter: parent.horizontalCenter

                                        Repeater {
                                            model: calendarDays

                                            Rectangle {
                                                width: 22
                                                height: 22
                                                radius: (sharedData && sharedData.quickshellBorderRadius) ? sharedData.quickshellBorderRadius : 0
                                                color: modelData.isToday ?
                                                           ((sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff") :
                                                           "transparent"

                                                Text {
                                                    text: modelData.day
                                                    font.pixelSize: 10
                                                    font.family: "sans-serif"
                                                    color: modelData.isToday ?
                                                               ((sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff") :
                                                               (modelData.isCurrentMonth ?
                                                                    ((sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff") :
                                                                    ((sharedData && sharedData.colorText) ? Qt.lighter(sharedData.colorText, 1.5) : "#888888"))
                                                    anchors.centerIn: parent
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        Component {
                            id: githubActivityDashboardComponent
                            GithubActivity {
                                sharedData: dashboardRoot.sharedData
                            }
                        }
                        
                        // Resource 1 Card - Swiss Style
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.preferredHeight: 190
                            Layout.minimumHeight: 165
                            radius: (sharedData && sharedData.quickshellBorderRadius) ? sharedData.quickshellBorderRadius : 0
                            color: "transparent"
                            
                            property string resource: (sharedData && sharedData.dashboardResource1) ? sharedData.dashboardResource1 : "cpu"
                            
                            opacity: showProgress > 0.01 ? 1.0 : 0.0
                            scale: showProgress > 0.01 ? 1.0 : 0.9
                            transform: Translate {
                                y: showProgress > 0.01 ? 0 : 40
                                Behavior on y {
                                    SequentialAnimation {
                                        PauseAnimation { duration: 150 }
                                        NumberAnimation { duration: 700; easing.type: Easing.OutBack }
                                    }
                                }
                            }
                            
                            Behavior on opacity {
                                SequentialAnimation {
                                    PauseAnimation { duration: 150 }
                                    NumberAnimation { duration: 500; easing.type: Easing.OutCubic }
                                }
                            }
                            Behavior on scale {
                                SequentialAnimation {
                                    PauseAnimation { duration: 150 }
                                    NumberAnimation { duration: 600; easing.type: Easing.OutBack }
                                }
                            }
                                    
                            Column {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 5
                                
                                Row {
                                    spacing: 5
                                    Text {
                                        text: getResourceIcon(parent.parent.resource)
                                        font.pixelSize: 12
                                        color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff"
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                    Text {
                                        text: getResourceLabel(parent.parent.resource).toUpperCase()
                                        font.pixelSize: 11
                                        font.family: "sans-serif"
                                        font.weight: Font.Bold
                                        color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#000000"
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                    Text {
                                        text: getResourceValueText(parent.parent.resource)
                                        font.pixelSize: 11
                                        font.family: "sans-serif"
                                        font.weight: Font.Bold
                                        color: (sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#00ff41"
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                    Text {
                                        text: getResourceSubText(parent.parent.resource)
                                        font.pixelSize: 10
                                        font.family: "sans-serif"
                                        color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#000000" 
                                        anchors.verticalCenter: parent.verticalCenter
                                        visible: text !== ""
                                    }
                                }
                                
                                Canvas {
                                    id: res1Chart
                                    width: parent.width
                                    height: 128
                                    
                                    onPaint: {
                                        var ctx = getContext("2d")
                                        ctx.clearRect(0, 0, width, height)
                                        
                                        var hist = getResourceHistory(parent.parent.resource)
                                        if (!hist || hist.length < 2) return
                                        
                                        var chartWidth = width
                                        var chartHeight = height
                                        var maxValue = 100
                                        if (parent.parent.resource === "network") {
                                            var max = 1.0 
                                            for(var k=0; k<hist.length; k++) if(hist[k] > max) max = hist[k]
                                            maxValue = max * 1.2
                                        }
                                        
                                        // Draw background
                                        ctx.fillStyle = (sharedData && sharedData.colorSecondary) ? sharedData.colorSecondary : "#141414"
                                        ctx.fillRect(0, 0, chartWidth, chartHeight)
                                        
                                        // Draw grid lines
                                        ctx.strokeStyle = (sharedData && sharedData.colorPrimary) ? sharedData.colorPrimary : "#2a2a2a"
                                        ctx.lineWidth = 1
                                        for (var i = 0; i <= 4; i++) {
                                            var y = (chartHeight / 4) * i
                                            ctx.beginPath()
                                            ctx.moveTo(0, y)
                                            ctx.lineTo(chartWidth, y)
                                            ctx.stroke()
                                        }
                                        
                                        // Draw graph
                                        ctx.strokeStyle = (sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff"
                                        ctx.lineWidth = 2
                                        ctx.beginPath()
                                        
                                        var stepX = chartWidth / (Math.max(hist.length, 2) - 1)
                                        function getY(val) { return chartHeight - (val / maxValue) * chartHeight }
                                        
                                        ctx.moveTo(0, getY(hist[0]))
                                        for (var j = 1; j < hist.length - 2; j++) {
                                            var xc = (j * stepX + (j + 1) * stepX) / 2
                                            var yc = (getY(hist[j]) + getY(hist[j+1])) / 2
                                            ctx.quadraticCurveTo(j * stepX, getY(hist[j]), xc, yc)
                                        }
                                        if (hist.length > 2) {
                                            var lastIdx = hist.length - 2
                                            ctx.quadraticCurveTo(lastIdx * stepX, getY(hist[lastIdx]), (lastIdx+1) * stepX, getY(hist[lastIdx+1]))
                                        } else if (hist.length === 2) {
                                            ctx.lineTo(stepX, getY(hist[1]))
                                        }
                                        
                                        ctx.stroke()
                                        
                                        ctx.lineTo(chartWidth, chartHeight)
                                        ctx.lineTo(0, chartHeight)
                                        ctx.closePath()
                                        ctx.fillStyle = (sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff"
                                        ctx.globalAlpha = 0.15
                                        ctx.fill()
                                        ctx.globalAlpha = 1.0
                                    }
                                    
                                    Connections {
                                        target: dashboardRoot
                                        function onPerfUpdated() {
                                            res1Chart.requestPaint()
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Resource 2 Card - Swiss Style
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.preferredHeight: 190
                            Layout.minimumHeight: 165
                            radius: (sharedData && sharedData.quickshellBorderRadius) ? sharedData.quickshellBorderRadius : 0
                            color: "transparent"
                            
                            property string resource: (sharedData && sharedData.dashboardResource2) ? sharedData.dashboardResource2 : "ram"
                            
                            opacity: showProgress > 0.01 ? 1.0 : 0.0
                            scale: showProgress > 0.01 ? 1.0 : 0.9
                            transform: Translate {
                                y: showProgress > 0.01 ? 0 : 40
                                Behavior on y {
                                    SequentialAnimation {
                                        PauseAnimation { duration: 200 }
                                        NumberAnimation { duration: 700; easing.type: Easing.OutBack }
                                    }
                                }
                            }
                            
                            Behavior on opacity {
                                SequentialAnimation {
                                    PauseAnimation { duration: 200 }
                                    NumberAnimation { duration: 500; easing.type: Easing.OutCubic }
                                }
                            }
                            Behavior on scale {
                                SequentialAnimation {
                                    PauseAnimation { duration: 200 }
                                    NumberAnimation { duration: 600; easing.type: Easing.OutBack }
                                }
                            }
                            
                            Column {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 5
                                
                                Row {
                                    spacing: 5
                                    Text {
                                        text: getResourceIcon(parent.parent.resource)
                                        font.pixelSize: 12
                                        color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff"
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                    Text {
                                        text: getResourceLabel(parent.parent.resource).toUpperCase()
                                        font.pixelSize: 11
                                        font.family: "sans-serif"
                                        font.weight: Font.Bold
                                        color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#000000"
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                    Text {
                                        text: getResourceValueText(parent.parent.resource)
                                        font.pixelSize: 11
                                        font.family: "sans-serif"
                                        font.weight: Font.Bold
                                        color: (sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#00ff41"
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                    Text {
                                        text: getResourceSubText(parent.parent.resource)
                                        font.pixelSize: 10
                                        font.family: "sans-serif"
                                        color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#000000"
                                        anchors.verticalCenter: parent.verticalCenter
                                        visible: text !== ""
                                    }
                                }
                                
                                Canvas {
                                    id: res2Chart
                                    width: parent.width
                                    height: 128
                                    
                                    onPaint: {
                                        var ctx = getContext("2d")
                                        ctx.clearRect(0, 0, width, height)
                                        
                                        var hist = getResourceHistory(parent.parent.resource)
                                        if (!hist || hist.length < 2) return
                                        
                                        var chartWidth = width
                                        var chartHeight = height
                                        var maxValue = 100
                                        if (parent.parent.resource === "network") {
                                            var max = 1.0 
                                            for(var k=0; k<hist.length; k++) if(hist[k] > max) max = hist[k]
                                            maxValue = max * 1.2
                                        }
                                        
                                        // Draw background
                                        ctx.fillStyle = (sharedData && sharedData.colorSecondary) ? sharedData.colorSecondary : "#141414"
                                        ctx.fillRect(0, 0, chartWidth, chartHeight)
                                        
                                        // Draw grid lines
                                        ctx.strokeStyle = (sharedData && sharedData.colorPrimary) ? sharedData.colorPrimary : "#2a2a2a"
                                        ctx.lineWidth = 1
                                        for (var i = 0; i <= 4; i++) {
                                            var y = (chartHeight / 4) * i
                                            ctx.beginPath()
                                            ctx.moveTo(0, y)
                                            ctx.lineTo(chartWidth, y)
                                            ctx.stroke()
                                        }
                                        
                                        // Draw graph
                                        ctx.strokeStyle = (sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff"
                                        ctx.lineWidth = 2
                                        ctx.beginPath()
                                        
                                        var stepX = chartWidth / (Math.max(hist.length, 2) - 1)
                                        function getY(val) { return chartHeight - (val / maxValue) * chartHeight }
                                        
                                        ctx.moveTo(0, getY(hist[0]))
                                        for (var j = 1; j < hist.length - 2; j++) {
                                            var xc = (j * stepX + (j + 1) * stepX) / 2
                                            var yc = (getY(hist[j]) + getY(hist[j+1])) / 2
                                            ctx.quadraticCurveTo(j * stepX, getY(hist[j]), xc, yc)
                                        }
                                        if (hist.length > 2) {
                                            var lastIdx = hist.length - 2
                                            ctx.quadraticCurveTo(lastIdx * stepX, getY(hist[lastIdx]), (lastIdx+1) * stepX, getY(hist[lastIdx+1]))
                                        } else if (hist.length === 2) {
                                            ctx.lineTo(stepX, getY(hist[1]))
                                        }
                                        
                                        ctx.stroke()
                                        
                                        ctx.lineTo(chartWidth, chartHeight)
                                        ctx.lineTo(0, chartHeight)
                                        ctx.closePath()
                                        ctx.fillStyle = (sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff"
                                        ctx.globalAlpha = 0.15
                                        ctx.fill()
                                        ctx.globalAlpha = 1.0
                                    }
                                    
                                    Connections {
                                        target: dashboardRoot
                                        function onPerfUpdated() {
                                            res2Chart.requestPaint()
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Media Player Card - Swiss Style
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.preferredHeight: 190
                            Layout.minimumHeight: 165
                            radius: (sharedData && sharedData.quickshellBorderRadius) ? sharedData.quickshellBorderRadius : 0
                            color: "transparent"
                            
                            opacity: showProgress > 0.01 ? 1.0 : 0.0
                            scale: showProgress > 0.01 ? 1.0 : 0.9
                            transform: Translate {
                                y: showProgress > 0.01 ? 0 : 40
                                Behavior on y {
                                    SequentialAnimation {
                                        PauseAnimation { duration: 250 }
                                        NumberAnimation { duration: 700; easing.type: Easing.OutBack }
                                    }
                                }
                            }
                            
                            Behavior on opacity {
                                SequentialAnimation {
                                    PauseAnimation { duration: 250 }
                                    NumberAnimation { duration: 500; easing.type: Easing.OutCubic }
                                }
                            }
                            Behavior on scale {
                                SequentialAnimation {
                                    PauseAnimation { duration: 250 }
                                    NumberAnimation { duration: 600; easing.type: Easing.OutBack }
                                }
                            }
                            
                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 16
                                spacing: 16
                                
                                // Cover art – kwadrat, po lewej, wyśrodkowany w pionie
                                Rectangle {
                                    Layout.preferredWidth: 100
                                    Layout.preferredHeight: 100
                                    Layout.minimumWidth: 100
                                    Layout.minimumHeight: 100
                                    Layout.alignment: Qt.AlignVCenter
                                    radius: (sharedData && sharedData.quickshellBorderRadius) ? sharedData.quickshellBorderRadius : 0
                                    color: (sharedData && sharedData.colorSecondary) ? sharedData.colorSecondary : "#141414"
                                    
                                    Image {
                                        id: mediaAlbumArtCard
                                        anchors.fill: parent
                                        anchors.margins: 1
                                        fillMode: Image.PreserveAspectCrop
                                        source: mpArt ? mpArt : ""
                                        asynchronous: true
                                        cache: false
                                        opacity: source ? 1.0 : 0.0
                                        
                                        Behavior on opacity {
                                            NumberAnimation {
                                                duration: 400
                                                easing.type: Easing.OutQuart
                                            }
                                        }
                                    }
                                    
                                    Text {
                                        text: "󰎆"
                                        font.pixelSize: 40
                                        anchors.centerIn: parent
                                        visible: !mpArt
                                        color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff"
                                    }
                                }
                                
                                // Track info + kontrolki – po prawej, przesunięte w dół
                                Column {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    Layout.alignment: Qt.AlignVCenter
                                    spacing: 10
                                    
                                    Item { width: 1; height: 12 }
                                    
                                    Column {
                                        width: parent.width - 20
                                        spacing: 2
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        
                                        Text {
                                            text: (mpTitle ? mpTitle : "NOTHING PLAYING").toUpperCase()
                                            font.pixelSize: 12
                                            font.family: "sans-serif"
                                            font.weight: Font.Black
                                            color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#000000"
                                            elide: Text.ElideRight
                                            width: parent.width
                                            horizontalAlignment: Text.AlignHCenter
                                        }
                                        
                                        Text {
                                            text: (mpArtist ? mpArtist : "—").toUpperCase()
                                            font.pixelSize: 10
                                            font.family: "sans-serif"
                                            font.weight: Font.Bold
                                            color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#000000"
                                            opacity: 0.6
                                            elide: Text.ElideRight
                                            width: parent.width
                                            horizontalAlignment: Text.AlignHCenter
                                        }

                                        Item { width: 1; height: 4 } // Spacer

                                        // Progress Bar (Inline)
                                        Rectangle {
                                            width: parent.width
                                            height: 2
                                            color: (sharedData && sharedData.colorSecondary) ? sharedData.colorSecondary : "#1a1a1a"
                                            
                                            Rectangle {
                                                width: (dashboardRoot.mpLength > 0 ? (parent.width * (dashboardRoot.mpPosition / dashboardRoot.mpLength)) : 0)
                                                height: parent.height
                                                color: (sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff"
                                                
                                                Behavior on width { NumberAnimation { duration: 200 } }
                                            }
                                        }
                                    }
                                    


                                    // Kontrolki prev | play | next – Swiss Block Style
                                    Row {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        spacing: 2 
                                        
                                        Rectangle {
                                            width: 34
                                            height: 34
                                            radius: (sharedData && sharedData.quickshellBorderRadius) ? sharedData.quickshellBorderRadius : 0
                                            color: (sharedData && sharedData.colorSecondary) ? sharedData.colorSecondary : "#1a1a1a"
                                            opacity: prevAreaCard.pressed ? 0.7 : (prevAreaCard.containsMouse ? 0.9 : 1.0)
                                            scale: prevAreaCard.pressed ? 0.90 : (prevAreaCard.containsMouse ? 1.05 : 1.0)
                                            z: prevAreaCard.containsMouse ? 2 : 1
                                            
                                            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
                                            Behavior on opacity { NumberAnimation { duration: 150 } }
                                            
                                            Text {
                                                text: "󰒮"
                                                font.pixelSize: 12
                                                anchors.centerIn: parent
                                                color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff"
                                            }
                                            
                                            MouseArea {
                                                id: prevAreaCard
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                hoverEnabled: true
                                                onClicked: playerPrev()
                                            }
                                        }
                                        
                                        Rectangle {
                                            width: 50
                                            height: 34
                                            radius: (sharedData && sharedData.quickshellBorderRadius) ? sharedData.quickshellBorderRadius : 0
                                            color: (sharedData && sharedData.colorSecondary) ? sharedData.colorSecondary : "#1a1a1a"
                                            opacity: playAreaCard.pressed ? 0.7 : (playAreaCard.containsMouse ? 0.9 : 1.0)
                                            scale: playAreaCard.pressed ? 0.90 : (playAreaCard.containsMouse ? 1.05 : 1.0)
                                            z: playAreaCard.containsMouse ? 2 : 1
                                            
                                            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
                                            Behavior on opacity { NumberAnimation { duration: 150 } }
                                            
                                            Text {
                                                text: mpPlaying ? "󰏤" : "󰐊"
                                                font.pixelSize: 14
                                                anchors.centerIn: parent
                                                color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff"
                                            }
                                            
                                            MouseArea {
                                                id: playAreaCard
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                hoverEnabled: true
                                                onClicked: playerPlayPause()
                                            }
                                        }
                                        
                                        Rectangle {
                                            width: 34
                                            height: 34
                                            radius: (sharedData && sharedData.quickshellBorderRadius) ? sharedData.quickshellBorderRadius : 0
                                            color: (sharedData && sharedData.colorSecondary) ? sharedData.colorSecondary : "#1a1a1a"
                                            opacity: nextAreaCard.pressed ? 0.7 : (nextAreaCard.containsMouse ? 0.9 : 1.0)
                                            scale: nextAreaCard.pressed ? 0.90 : (nextAreaCard.containsMouse ? 1.05 : 1.0)
                                            z: nextAreaCard.containsMouse ? 2 : 1
                                            
                                            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
                                            Behavior on opacity { NumberAnimation { duration: 150 } }
                                            
                                            Text {
                                                text: "󰒭"
                                                font.pixelSize: 12
                                                anchors.centerIn: parent
                                                color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff"
                                            }
                                            
                                            MouseArea {
                                                id: nextAreaCard
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                hoverEnabled: true
                                                onClicked: playerNext()
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }



                // ============ TAB 2: CLIPBOARD ============
                Item {
                    id: clipboardTab
                    anchors.fill: parent
                    visible: currentTab === 1
                    opacity: currentTab === 1 ? 1.0 : 0.0
                    x: currentTab === 1 ? 0 : (currentTab < 1 ? -parent.width * 0.3 : parent.width * 0.3)
                    scale: currentTab === 1 ? 1.0 : 0.95
                    
                    Behavior on opacity {
                        NumberAnimation { 
                            duration: 400
                            easing.type: Easing.OutCubic
                        }
                    }
                    
                    Behavior on x {
                        NumberAnimation {
                            duration: 400
                            easing.type: Easing.OutCubic
                        }
                    }
                    
                    Behavior on scale {
                        NumberAnimation {
                            duration: 400
                            easing.type: Easing.OutCubic
                        }
                    }
                    
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
                                        dashboardClipboardHistoryModel.clear()
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
                                model: dashboardClipboardHistoryModel
                                spacing: 5
                                
                                delegate: Rectangle {
                                    width: clipboardListView.width
                                    height: Math.max(32, contentTextClipboard.implicitHeight + 13)
                                    radius: (sharedData && sharedData.quickshellBorderRadius) ? sharedData.quickshellBorderRadius : 0
                                    // Material Design card color
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
                                            dashboardRoot.copyToClipboard(model.text)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // ============ TAB 3: NOTIFICATIONS ============
                Item {
                    id: notificationsTab
                    anchors.fill: parent
                    visible: currentTab === 2
                    opacity: currentTab === 2 ? 1.0 : 0.0
                    x: currentTab === 2 ? 0 : (currentTab < 2 ? -parent.width * 0.3 : parent.width * 0.3)
                    scale: currentTab === 2 ? 1.0 : 0.95
                    
                    Behavior on opacity {
                        NumberAnimation { 
                            duration: 400
                            easing.type: Easing.OutCubic
                        }
                    }
                    
                    Behavior on x {
                        NumberAnimation {
                            duration: 400
                            easing.type: Easing.OutCubic
                        }
                    }
                    
                    Behavior on scale {
                        NumberAnimation {
                            duration: 400
                            easing.type: Easing.OutCubic
                        }
                    }
                    
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
                            
                            // Empty state (no anchors – ListView is child of Column)
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
                                // Material Design card color
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
                                                dashboardRoot.copyToClipboard(textToCopy)
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
                                                    var newHistory = sharedData.notificationHistory.filter(function(item, i) { return i !== index })
                                                    sharedData.notificationHistory = newHistory
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

            }
        }
    }

    // ============ PROPERTIES ============
    Behavior on cpuUsageValue { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
    Behavior on ramUsageValue { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
    Behavior on gpuUsageValue { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
    
    property real cpuUsageEMA: 0
    property real ramUsageEMA: 0
    property real gpuUsageEMA: 0
    property real smoothingFactor: 0.15  // Lower = smoother
    property int maxHistoryLength: 100  // Number of data points to show
    property string mpTitle: ""
    property string mpArtist: ""
    property string mpAlbum: ""
    property string mpArt: ""
    property bool mpPlaying: false
    property real mpPosition: 0
    property int mpLength: 0
    
    // Calendar days model
    property var calendarDays: []
    
    // Uptime (display string, set by updateUptime())
    property string uptimeDisplayText: "󰥔: --"
    
    // Battery
    property int batteryPercent: -1
    
    // Performance tab models
    property var diskUsageModel: []
    property var topProcessesModel: []
    
    // Cava visualizer properties
    property var cavaValues: []
    property bool cavaRunning: false
    property string projectPath: ""
    onProjectPathChanged: { if (projectPath && projectPath.length > 0 && !cavaRunning) startCava() }

    // Clipboard properties
    property string lastClipboardContent: ""
    
    // Clipboard history model
    ListModel {
        id: dashboardClipboardHistoryModel
    }
    
    // Monitor clipboard changes – only when dashboard is open and Clipboard tab is active
    Timer {
        id: dashboardClipboardMonitorTimer
        interval: 500
        running: (sharedData && sharedData.menuVisible) && (currentTab === 1)
        repeat: true
        onTriggered: dashboardRoot.checkClipboard()
    }
    
    // ============ FUNCTIONS ============
    function updateWeather() {
        // Simple weather update - can be extended with API integration
        // For now, uses a simple approach that can be customized
        // Example: curl -s "wttr.in?format=%t+%C" or use a weather service
        if (sharedData && sharedData.runCommand) sharedData.runCommand(['sh','-c','curl -s "wttr.in?format=%t+%C" 2>/dev/null | head -1 > /tmp/quickshell_weather || echo "15°C Clear" > /tmp/quickshell_weather'], readWeather)
    }
    
    function readWeather() {
        var xhr = new XMLHttpRequest()
        xhr.open("GET", "file:///tmp/quickshell_weather")
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                var weather = xhr.responseText.trim()
                if (weather && weather.length > 0) {
                    var parts = weather.split(" ")
                    if (parts.length > 0) weatherTemp = parts[0]
                    if (parts.length > 1) weatherCondition = parts.slice(1).join(" ")
                }
            }
        }
        xhr.send()
    }
    
    function updateDistro() {
        if (sharedData && sharedData.runCommand) sharedData.runCommand(['sh','-c','(grep "^PRETTY_NAME=" /etc/os-release 2>/dev/null | cut -d= -f2- | tr -d \'"\'"\' || grep "^NAME=" /etc/os-release 2>/dev/null | cut -d= -f2- | tr -d \'"\'"\' || echo "Linux") > /tmp/quickshell_distro'], readDistro)
    }
    
    function readDistro() {
        var xhr = new XMLHttpRequest()
        xhr.open("GET", "file:///tmp/quickshell_distro")
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                var distro = xhr.responseText.trim()
                if (distro && distro.length > 0) {
                    // Remove quotes if present
                    distro = distro.replace(/^["']|["']$/g, '')
                    distroName = distro
                }
            }
        }
        xhr.send()
    }
    
    function updateBattery() {
        if (sharedData && sharedData.runCommand) sharedData.runCommand(['sh','-c','cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -1 > /tmp/quickshell_battery || echo -1 > /tmp/quickshell_battery'], readBattery)
    }
    
    function readBattery() {
        var xhr = new XMLHttpRequest()
        xhr.open("GET", "file:///tmp/quickshell_battery")
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                var s = xhr.responseText.trim()
                var p = parseInt(s, 10)
                batteryPercent = (!isNaN(p) && p >= 0 && p <= 100) ? p : -1
            }
        }
        xhr.send()
    }
    
    function updateNetwork() {
        if (sharedData && sharedData.runCommand) {
            var script = "(A=$(tail -n +3 /proc/net/dev 2>/dev/null | awk '{r+=$2;t+=$10} END {print r+0,t+0}'); sleep 1; B=$(tail -n +3 /proc/net/dev 2>/dev/null | awk '{r+=$2;t+=$10} END {print r+0,t+0}'); echo \"$A $B\") > /tmp/quickshell_net_speed"
            sharedData.runCommand(['sh','-c', script], readNetwork)
        }
    }
    function readNetwork() {
        var xhr = new XMLHttpRequest()
        xhr.open("GET", "file:///tmp/quickshell_net_speed")
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                var s = (xhr.responseText || "").trim()
                var parts = s.split(/\s+/)
                if (parts.length >= 4) {
                    var rx0 = parseFloat(parts[0]) || 0, tx0 = parseFloat(parts[1]) || 0
                    var rx1 = parseFloat(parts[2]) || 0, tx1 = parseFloat(parts[3]) || 0
                    networkRxMBs = Math.max(0, (rx1 - rx0) / 1048576)
                    networkTxMBs = Math.max(0, (tx1 - tx0) / 1048576)
                    
                    // Update History
                    networkHistory = pushHistory(networkHistory, networkRxMBs + networkTxMBs) // Total bandwidth for chart
                    dashboardRoot.perfUpdated()
                }
            }
        }
        xhr.send()
    }
    
    function updateWindowManager() {
        if (sharedData && sharedData.runCommand) sharedData.runCommand(['sh','-c','(echo $XDG_CURRENT_DESKTOP 2>/dev/null | cut -d: -f1 || echo $DESKTOP_SESSION 2>/dev/null || ps -e | grep -E "(hyprland|sway|i3|kwin|mutter|xfwm4|openbox|dwm)" | head -1 | awk "{print \$4}" | tr -d \'"\'"\' || echo "Unknown") > /tmp/quickshell_wm'], readWindowManager)
    }
    
    function readWindowManager() {
        var xhr = new XMLHttpRequest()
        xhr.open("GET", "file:///tmp/quickshell_wm")
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                var wm = xhr.responseText.trim()
                if (wm && wm.length > 0) {
                    windowManager = wm
                }
            }
        }
        xhr.send()
    }
    
    function updateCalendar() {
        var now = new Date()
        var firstDay = new Date(now.getFullYear(), now.getMonth(), 1)
        var lastDay = new Date(now.getFullYear(), now.getMonth() + 1, 0)
        var startDay = firstDay.getDay() === 0 ? 6 : firstDay.getDay() - 1 // Monday = 0
        
        var days = []
        
        // Previous month days
        var prevMonthLastDay = new Date(now.getFullYear(), now.getMonth(), 0).getDate()
        for (var i = startDay - 1; i >= 0; i--) {
            days.push({
                day: (prevMonthLastDay - i).toString(),
                isCurrentMonth: false,
                isToday: false
            })
        }
        
        // Current month days
        for (var j = 1; j <= lastDay.getDate(); j++) {
            days.push({
                day: j.toString(),
                isCurrentMonth: true,
                isToday: (j === now.getDate())
            })
        }
        
        // Next month days to fill the grid
        var remaining = 42 - days.length
        for (var k = 1; k <= remaining; k++) {
            days.push({
                day: k.toString(),
                isCurrentMonth: false,
                isToday: false
            })
        }
        
        calendarDays = days
    }
    
    function updateDate() {
        // Calendar grid is updated by updateCalendar().
        // dayNumber/monthNumber elements were removed; no separate date display to update.
    }
    
    function updateUptime() {
        var xhr = new XMLHttpRequest()
        xhr.open("GET", "file:///proc/uptime")
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                var uptimeSeconds = parseFloat(xhr.responseText.split(" ")[0])
                if (!isNaN(uptimeSeconds) && uptimeSeconds > 0) {
                    var hours = Math.floor(uptimeSeconds / 3600)
                    var minutes = Math.floor((uptimeSeconds % 3600) / 60)
                    var uptimeStr = ""
                    if (hours > 0) {
                        uptimeStr = hours + "h"
                    }
                    if (minutes > 0) {
                        if (uptimeStr) uptimeStr += " "
                        uptimeStr += minutes + "m"
                    }
                    if (!uptimeStr) {
                        uptimeStr = "0m"
                    }
                    uptimeDisplayText = "󰥔: " + uptimeStr
                }
            }
        }
        xhr.send()
    }
    
    function parseTimeToSeconds(str) {
        if (!str) return 0
        var n = parseFloat(str)
        if (!isNaN(n) && str.indexOf(':') === -1) return n
        var parts = str.split(':').map(function(x) { return parseInt(x) || 0 })
        if (parts.length === 2) {
            return parts[0] * 60 + parts[1]
        } else if (parts.length === 3) {
            return parts[0] * 3600 + parts[1] * 60 + parts[2]
        }
        return 0
    }

    function updatePlayerMetadata() {
        // Delegate path resolution to shell to avoid QML ReferenceErrors
        if (sharedData && sharedData.runCommand) {
             var cmd = 'TARGET="${QUICKSHELL_PROJECT_PATH:-$HOME/.config/alloy/dart}/scripts/get-player-metadata.sh"; bash "$TARGET"'
             sharedData.runCommand(["sh", "-c", cmd], readPlayerMetadata)
        }
    }
    
    function readPlayerMetadata() {
        var xhr = new XMLHttpRequest()
        xhr.open("GET", "file:///tmp/quickshell_player_info")
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                var txt = xhr.responseText || ""
                if (txt.trim() === "") {
                    mpTitle = ""
                    mpArtist = ""
                    mpAlbum = ""
                    mpArt = ""
                    mpPlaying = false
                    mpPosition = 0
                    mpLength = 0
                    return
                }
                var lines = txt.split("|###|")
                mpArtist = lines[0] ? lines[0].trim() : ""
                mpTitle = lines[1] ? lines[1].trim() : ""
                mpAlbum = lines[2] ? lines[2].trim() : ""
                var art = lines[3] ? lines[3].trim() : ""
                var lengthRaw = (lines[4] || "").trim()
                var status = (lines[5] || "").trim().toLowerCase()

                var len = parseInt(lengthRaw) || 0
                if (len > 1000000) mpLength = Math.round(len / 1000000)
                else mpLength = Math.round(parseTimeToSeconds(lengthRaw))

                mpPlaying = (status === "playing")

                if (art.indexOf("file://") === 0) mpArt = art.replace("file://", "")
                else if (art.indexOf("http") === 0) mpArt = art
                else mpArt = ""
            }
        }
        xhr.send()
    }

    function updatePlayerPosition() {
        if (sharedData && sharedData.runCommand) sharedData.runCommand(["sh", "-c", "playerctl position > /tmp/quickshell_player_pos 2>/dev/null || echo 0 > /tmp/quickshell_player_pos"], readPlayerPosition)
    }
    
    function readPlayerPosition() {
        var xhr = new XMLHttpRequest()
        xhr.open("GET", "file:///tmp/quickshell_player_pos")
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                var txt = (xhr.responseText || "").trim()
                if (txt === "" || txt === "0") {
                    return
                }
                var pos = parseTimeToSeconds(txt)
                if (!isNaN(pos)) {
                    mpPosition = pos
                }
            }
        }
        xhr.send()
    }

    function playerPlayPause() {
        if (sharedData && sharedData.runCommand) {
            sharedData.runCommand(["playerctl", "play-pause"], function(){ updatePlayerMetadata(); updatePlayerPosition() })
        }
    }

    function playerNext() {
        if (sharedData && sharedData.runCommand) sharedData.runCommand(["playerctl", "next"], updatePlayerMetadata)
    }

    function playerPrev() {
        if (sharedData && sharedData.runCommand) sharedData.runCommand(["playerctl", "previous"], updatePlayerMetadata)
    }
    


    // ============ TIMERS ============
    Timer {
        id: dateTimer
        interval: 1000
        repeat: true
        running: (sharedData && sharedData.menuVisible)
        onTriggered: updateDate()
        Component.onCompleted: if (sharedData && sharedData.menuVisible) updateDate()
    }
    
    Timer {
        id: calendarTimer
        interval: 60000
        repeat: true
        running: (sharedData && sharedData.menuVisible)
        onTriggered: updateCalendar()
        Component.onCompleted: if (sharedData && sharedData.menuVisible) updateCalendar()
    }
    
    Timer {
        id: uptimeTimer
        interval: 60000
        repeat: true
        running: (sharedData && sharedData.menuVisible)
        onTriggered: updateUptime()
        Component.onCompleted: if (sharedData && sharedData.menuVisible) updateUptime()
    }
    
    Timer {
        id: playerMetadataTimer
        interval: 3000
        repeat: true
        running: (sharedData && sharedData.menuVisible)
        onTriggered: updatePlayerMetadata()
        Component.onCompleted: if (sharedData && sharedData.menuVisible) updatePlayerMetadata()
    }
    
    Timer {
        id: playerPositionTimer
        interval: 1000
        repeat: true
        running: (sharedData && sharedData.menuVisible && mpPlaying)
        onTriggered: updatePlayerPosition()
    }



    Timer {
        id: ramTimer
        interval: 500
        repeat: true
        running: (sharedData && sharedData.menuVisible)
        function readRam() {
            var xhr = new XMLHttpRequest()
            xhr.open("GET", "file:///proc/meminfo")
            xhr.onreadystatechange = function() {
                if (xhr.readyState === XMLHttpRequest.DONE) {
                    var lines = xhr.responseText.split("\n")
                    var memTotal = 0
                    var memAvailable = 0
                    for (var i = 0; i < lines.length; i++) {
                        if (lines[i].startsWith("MemTotal:")) memTotal = parseInt(lines[i].match(/\d+/)[0])
                        else if (lines[i].startsWith("MemAvailable:")) memAvailable = parseInt(lines[i].match(/\d+/)[0])
                    }
                    if (memTotal > 0) {
                        ramUsageValue = 100 - Math.round((memAvailable / memTotal) * 100)
                        ramTotalGB = Math.round(memTotal / 1024 / 1024)  // Convert from KB to GB
                        
                        ramHistory = pushHistory(ramHistory, ramUsageValue)
                    }
                    dashboardRoot.perfUpdated()
                }
            }
            xhr.send()
        }
        onTriggered: readRam()
        Component.onCompleted: readRam()
    }

    Timer {
        id: cpuTimer
        interval: 500
        repeat: true
        running: (sharedData && sharedData.menuVisible)

        property int lastIdle: 0
        property int lastTotal: 0

        function readCpu() {
            var xhr = new XMLHttpRequest()
            xhr.open("GET", "file:///proc/stat")
            xhr.onreadystatechange = function() {
                if (xhr.readyState === XMLHttpRequest.DONE) {
                    var lines = xhr.responseText.split("\n")
                    for (var i = 0; i < lines.length; i++) {
                        if (lines[i].startsWith("cpu ")) {
                            var parts = lines[i].trim().split(/\s+/)
                            var user = parseInt(parts[1])
                            var nice = parseInt(parts[2])
                            var system = parseInt(parts[3])
                            var idle = parseInt(parts[4])
                            var total = user + nice + system + idle
                            if (cpuTimer.lastTotal > 0) {
                                cpuUsageValue = Math.round((total - cpuTimer.lastTotal - (idle - cpuTimer.lastIdle)) / (total - cpuTimer.lastTotal) * 100)
                                cpuHistory = pushHistory(cpuHistory, cpuUsageValue)
                            }
                            cpuTimer.lastTotal = total
                            cpuTimer.lastIdle = idle
                            dashboardRoot.perfUpdated()
                            break
                        }
                    }
                }
            }
            xhr.send()
        }
        onTriggered: readCpu()
        Component.onCompleted: readCpu()
    }

    Timer {
        id: gpuTimer
        interval: 500
        repeat: true
        running: (sharedData && sharedData.menuVisible)
        onTriggered: readGpu()
    }
    
    function readGpu() {
        // Read GPU usage using nvidia-smi (primary) or radeontop (fallback)
        if (sharedData && sharedData.runCommand) sharedData.runCommand(['sh','-c','nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>/dev/null | head -1 | tr -d " " > /tmp/quickshell_gpu_usage || (timeout 1 radeontop -l 1 -d - 2>/dev/null | tail -1 | awk "{print int($2)}" > /tmp/quickshell_gpu_usage) || echo 0 > /tmp/quickshell_gpu_usage'], readGpuData)
    }
    
    function readGpuData() {
        var xhr = new XMLHttpRequest()
        xhr.open("GET", "file:///tmp/quickshell_gpu_usage")
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                var text = xhr.responseText.trim()
                // Remove any non-numeric characters except digits
                text = text.replace(/[^0-9]/g, '')
                var usage = parseInt(text)
                if (!isNaN(usage)) {
                    if (usage >= 0 && usage <= 100) {
                        gpuUsageValue = usage
                    } else if (usage > 100) {
                        // Sometimes nvidia-smi returns values > 100, cap it
                        gpuUsageValue = 100
                    } else {
                        gpuUsageValue = 0
                    }
                    
                    // Update History
                    gpuHistory = pushHistory(gpuHistory, gpuUsageValue)
                    dashboardRoot.perfUpdated()
                } else {
                    gpuUsageValue = 0
                }
                dashboardRoot.perfUpdated()
            }
        }
        xhr.send()
    }

    Timer {
        id: batteryTimer
        interval: 10000
        repeat: true
        running: (sharedData && sharedData.menuVisible)
        onTriggered: updateBattery()
        Component.onCompleted: if (sharedData && sharedData.menuVisible) updateBattery()
    }
    // Odśwież % baterii od razu po otwarciu menu (nie czekaj do pierwszego ticku timera)
    Connections {
        target: sharedData
        enabled: !!sharedData
        function onMenuVisibleChanged() {
            if (sharedData && sharedData.menuVisible) updateBattery()
        }
    }
    
    Timer {
        id: networkTimer
        interval: 3000
        repeat: true
        running: (sharedData && sharedData.menuVisible) && (sharedData && sharedData.dashboardTileLeft === "network")
        onTriggered: updateNetwork()
        Component.onCompleted: if ((sharedData && sharedData.menuVisible) && (sharedData && sharedData.dashboardTileLeft === "network")) updateNetwork()
    }
    
    
    // ============ PERFORMANCE TAB FUNCTIONS ============
    function updateDiskUsage() {
        if (sharedData && sharedData.runCommand) sharedData.runCommand(['sh','-c','df -h | grep -E "^/dev" | awk "{print $6 \"|\" $2 \"|\" $3 \"|\" $5}" | head -5 > /tmp/quickshell_disk_usage 2>/dev/null || echo > /tmp/quickshell_disk_usage'], readDiskUsage)
    }
    
    function readDiskUsage() {
        var xhr = new XMLHttpRequest()
        xhr.open("GET", "file:///tmp/quickshell_disk_usage")
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                var lines = xhr.responseText.split("\n")
                var disks = []
                for (var i = 0; i < lines.length; i++) {
                    if (lines[i].trim()) {
                        var parts = lines[i].split("|")
                        if (parts.length >= 4) {
                            var usageStr = parts[3].replace("%", "")
                            var usage = parseInt(usageStr) || 0
                            disks.push({
                                mount: parts[0],
                                total: parts[1],
                                used: parts[2],
                                usage: usage
                            })
                        }
                    }
                }
                diskUsageModel = disks
            }
        }
        xhr.send()
    }
    
    function updateTopProcesses() {
        if (sharedData && sharedData.runCommand) sharedData.runCommand(['sh','-c','ps aux --sort=-%cpu 2>/dev/null | tail -n +2 | head -8 | awk "{print $11 \"|\" $3 \"|\" $4}" > /tmp/quickshell_top_processes 2>/dev/null || echo > /tmp/quickshell_top_processes'], readTopProcesses)
    }
    
    function readTopProcesses() {
        var xhr = new XMLHttpRequest()
        xhr.open("GET", "file:///tmp/quickshell_top_processes")
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                var lines = xhr.responseText.split("\n")
                var processes = []
                for (var i = 0; i < lines.length; i++) {
                    var line = lines[i].trim()
                    if (line && !line.startsWith("COMMAND")) {
                        var parts = line.split("|")
                        if (parts.length >= 3 && parts[0] && parts[0] !== "ps") {
                            var name = parts[0].split("/").pop()
                            if (name && name.length > 0) {
                                var cpu = parseFloat(parts[1])
                                var mem = parseFloat(parts[2])
                                if (!isNaN(cpu) && !isNaN(mem)) {
                                    processes.push({
                                        name: name,
                                        cpu: cpu.toFixed(1),
                                        mem: mem.toFixed(1)
                                    })
                                }
                            }
                        }
                    }
                }
                topProcessesModel = processes
            }
        }
        xhr.send()
    }
    
    function updateCpuTemp() {
        if (sharedData && sharedData.runCommand) sharedData.runCommand(['sh','-c','(sensors 2>/dev/null | grep -i "cpu" | grep -oE "[0-9]+\\.[0-9]+" | head -1 | cut -d. -f1 > /tmp/quickshell_cpu_temp) || (cat /sys/class/thermal/thermal_zone*/temp 2>/dev/null | head -1 | awk "{print int($1/1000)}" > /tmp/quickshell_cpu_temp) || echo 0 > /tmp/quickshell_cpu_temp'], readCpuTemp)
    }
    
    function readCpuTemp() {
        var xhr = new XMLHttpRequest()
        xhr.open("GET", "file:///tmp/quickshell_cpu_temp")
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                var temp = parseInt(xhr.responseText.trim())
                if (!isNaN(temp)) cpuTempValue = temp
            }
        }
        xhr.send()
    }
    
    function updateGpuTemp() {
        if (sharedData && sharedData.runCommand) sharedData.runCommand(['sh','-c','(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits 2>/dev/null | head -1 > /tmp/quickshell_gpu_temp) || (sensors 2>/dev/null | grep -i "gpu\\|radeon\\|amdgpu" | grep -oE "[0-9]+\\.[0-9]+" | head -1 | cut -d. -f1 > /tmp/quickshell_gpu_temp) || echo 0 > /tmp/quickshell_gpu_temp'], readGpuTemp)
    }
    
    function readGpuTemp() {
        var xhr = new XMLHttpRequest()
        xhr.open("GET", "file:///tmp/quickshell_gpu_temp")
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                var temp = parseInt(xhr.responseText.trim())
                if (!isNaN(temp)) gpuTempValue = temp
            }
        }
        xhr.send()
    }
    
    // Performance timers – only when dashboard is open
    Timer {
        id: diskUsageTimer
        interval: 5000
        repeat: true
        running: (sharedData && sharedData.menuVisible)
        onTriggered: updateDiskUsage()
        Component.onCompleted: if (sharedData && sharedData.menuVisible) updateDiskUsage()
    }
    
    Timer {
        id: topProcessesTimer
        interval: 3000
        repeat: true
        running: (sharedData && sharedData.menuVisible)
        onTriggered: updateTopProcesses()
        Component.onCompleted: if (sharedData && sharedData.menuVisible) updateTopProcesses()
    }
    
    Timer {
        id: cpuTempTimer
        interval: 5000
        repeat: true
        running: (sharedData && sharedData.menuVisible)
        onTriggered: updateCpuTemp()
        Component.onCompleted: if (sharedData && sharedData.menuVisible) updateCpuTemp()
    }
    
    Timer {
        id: gpuTempTimer
        interval: 5000
        repeat: true
        running: (sharedData && sharedData.menuVisible)
        onTriggered: updateGpuTemp()
        Component.onCompleted: if (sharedData && sharedData.menuVisible) updateGpuTemp()
    }
    
    // ============ CAVA VISUALIZER FUNCTIONS ============
    function startCava() {
        if (sharedData && sharedData.lowPerformanceMode) return
        if (sharedData && sharedData.runCommand) sharedData.runCommand(['sh','-c','which cava > /dev/null 2>&1 && echo 1 > /tmp/quickshell_cava_available || echo 0 > /tmp/quickshell_cava_available'], checkCavaAvailable)
    }
    
    function checkCavaAvailable() {
        var xhr = new XMLHttpRequest()
        xhr.open("GET", "file:///tmp/quickshell_cava_available")
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                var available = xhr.responseText.trim() === "1"
                if (available && !cavaRunning) {
                    // Użyj skryptu start-cava.sh do uruchomienia cava
                    var scriptPath = projectPath ? (projectPath + "/scripts/start-cava.sh") : ""
                    if (!scriptPath || scriptPath === "/scripts/start-cava.sh") {
                        if (sharedData && sharedData.runCommand) sharedData.runCommand(['sh', '-c', 'echo "$QUICKSHELL_PROJECT_PATH" > /tmp/quickshell_cava_path 2>/dev/null || true'], readCavaPath)
                        return
                    }
                    if (!scriptPath || scriptPath.length === 0 || scriptPath === "/scripts/start-cava.sh") {
                        return
                    }
                    var absScriptPath = scriptPath
                    if (sharedData && sharedData.runCommand) {
                        cavaRunning = true
                        sharedData.runCommand(["bash", absScriptPath], readCavaData)
                    }
                }
            }
        }
        xhr.send()
    }
    
    function readCavaPath() {
        var xhr = new XMLHttpRequest()
        xhr.open("GET", "file:///tmp/quickshell_cava_path")
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                var path = xhr.responseText.trim()
                if (path && path.length > 0) {
                    projectPath = path
                    var scriptPath = projectPath + "/scripts/start-cava.sh"
                    var absScriptPath = scriptPath
                    if (sharedData && sharedData.runCommand) {
                        cavaRunning = true
                        sharedData.runCommand(["bash", absScriptPath], readCavaData)
                    }
                }
            }
        }
        xhr.send()
    }
    
    function readCavaData() {
        // Bezpośredni odczyt z pliku
        var xhr = new XMLHttpRequest()
        xhr.open("GET", "file:///tmp/quickshell_cava")
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status !== 200 && xhr.status !== 0) {
                    if (cavaRunning) {
                        cavaRunning = false
                        startCava()
                    }
                    return
                }
                var data = xhr.responseText
                if (data && data.length > 0) {
                    var cleanData = data.trim().replace(/;+$/, '')
                    var values = cleanData.split(";")
                    
                    if (values.length > 0) {
                        var colorAccent = (sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff"
                        var colorText = (sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff"
                        var colorPrimary = (sharedData && sharedData.colorPrimary) ? sharedData.colorPrimary : "#3a3a3a"
                        var colorSecondary = (sharedData && sharedData.colorSecondary) ? sharedData.colorSecondary : "#2a2a2a"
                        
                        // Store cava values for potential future use (e.g. SidePanel visualizer)
                        cavaValues = values
                        
                        // Note: Media visualizer was removed when Media tab was replaced with Clipboard tab
                        // If visualizer is needed in the future, it should be added to SidePanel or another component
                    }
                } else {
                    // No data, silently continue - cavaCheckTimer will handle restart if needed
                    // Removed frequent logging to reduce console spam
                }
            }
        }
        xhr.send()
    }
    
    // Timer do odczytu danych z cava (33ms≈30 FPS; 50ms gdy low-perf)
    Timer {
        id: cavaDataTimer
        interval: (sharedData && sharedData.lowPerformanceMode) ? 50 : 33
        repeat: true
        running: cavaRunning
        onTriggered: readCavaData()
    }
    
    // Timer do sprawdzania czy cava działa
    Timer {
        id: cavaCheckTimer
        interval: 5000  // Co 5 sekund
        repeat: true
        running: true
        onTriggered: {
            if (cavaRunning) {
                var xhr = new XMLHttpRequest()
                xhr.open("GET", "file:///tmp/quickshell_cava")
                xhr.onreadystatechange = function() {
                    if (xhr.readyState === XMLHttpRequest.DONE) {
                        if (xhr.status !== 200 && xhr.status !== 0) {
                            cavaRunning = false
                            startCava()
                        }
                    }
                }
                xhr.send()
            } else {
                startCava()
            }
        }
    }



    
    Component.onCompleted: {
        
        // Initialize weatherCity from sharedData if available
        if (sharedData && sharedData.weatherCity !== undefined) {
            weatherCity = sharedData.weatherCity
        }
        updateCalendar()
        updateDate()
        updateUptime()
        updateDistro()
        updateWindowManager()
        if (projectPath && projectPath.length > 0) {
            startCava()
        } else if (sharedData && sharedData.runCommand) {
            sharedData.runCommand(['sh', '-c', 'echo "$QUICKSHELL_PROJECT_PATH" > /tmp/quickshell_cava_path 2>/dev/null || pwd > /tmp/quickshell_cava_path'], readCavaPath)
        }
        checkClipboard()
    }
    
    Connections {
        target: sharedData
        function onMenuVisibleChanged() {
            if (sharedData && sharedData.menuVisible) {
                if (dashboardRoot.dashboardContainer) dashboardRoot.dashboardContainer.forceActiveFocus()
            } else {
                dashboardContainer.focus = false
            }
        }
    }
    
    // ============ POWER MENU FUNCTIONS ============
    function suspendSystem() {
        if (sharedData && sharedData.runCommand) sharedData.runCommand(['systemctl', 'suspend'])
    }
    
    function rebootSystem() {
        if (sharedData && sharedData.runCommand) sharedData.runCommand(['systemctl', 'reboot'])
    }
    
    function shutdownSystem() {
        if (sharedData && sharedData.runCommand) sharedData.runCommand(['systemctl', 'poweroff'])
    }
    
    function logoutSystem() {
        // Try loginctl first, fallback to pkill
        if (sharedData && sharedData.runCommand) sharedData.runCommand(['sh', '-c', 'loginctl terminate-session $(loginctl list-sessions | grep $(whoami) | awk "{print $1}" | head -1) 2>/dev/null || pkill -KILL -u $(whoami)'])
    }
    
    // ============ NOTIFICATION FUNCTIONS ============
    function copyToClipboard(text) {
        var esc = text.replace(/\\/g, "\\\\").replace(/"/g, '\\"').replace(/\$/g, "\\$").replace(/`/g, "\\`")
        if (sharedData && sharedData.runCommand) sharedData.runCommand(['sh', '-c', 'echo -n "' + esc + '" > /tmp/quickshell_clipboard_copy'], copyFromFile)
        lastClipboardContent = text
    }
    
    function copyFromFile() {
        if (sharedData && sharedData.runCommand) sharedData.runCommand(['sh', '-c', 'cat /tmp/quickshell_clipboard_copy | wl-copy'])
    }
    
    // ============ CLIPBOARD FUNCTIONS ============
    function checkClipboard() {
        if (sharedData && sharedData.runCommand) sharedData.runCommand(['sh', '-c', 'wl-paste > /tmp/quickshell_clipboard_content 2>/dev/null || echo "" > /tmp/quickshell_clipboard_content'], readClipboardContent)
    }
    
    function readClipboardContent() {
        var xhr = new XMLHttpRequest()
        xhr.open("GET", "file:///tmp/quickshell_clipboard_content")
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200 || xhr.status === 0) {
                    var content = xhr.responseText
                    processClipboardContent(content)
                }
            }
        }
        xhr.send()
    }
    
    function processClipboardContent(content) {
        if (!content || content.trim() === "") return
        
        var trimmed = content.trim()
        
        // Skip if same as last content
        if (trimmed === lastClipboardContent) return
        
        // Skip if already in history
        for (var i = 0; i < dashboardClipboardHistoryModel.count; i++) {
            if (dashboardClipboardHistoryModel.get(i).text === trimmed) {
                // Move to top
                dashboardClipboardHistoryModel.move(i, 0, 1)
                lastClipboardContent = trimmed
                return
            }
        }
        
        // Add to history (max 50 items)
        if (dashboardClipboardHistoryModel.count >= 50) {
            dashboardClipboardHistoryModel.remove(dashboardClipboardHistoryModel.count - 1)
        }
        
        dashboardClipboardHistoryModel.insert(0, { text: trimmed })
        lastClipboardContent = trimmed
    }
}


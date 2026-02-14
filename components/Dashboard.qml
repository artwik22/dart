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
    property string distroName: "Linux"
    property string hostname: "unknown"
    property string kernelVersion: "unknown"
    property string uptimeString: "0m"
    property string osPrettyName: "Linux"
    
    // Resource Current Values (Implicitly defined by usage in timers, but declaring for clarity/safety)
    property int cpuUsageValue: 0
    property int ramUsageValue: 0
    property int gpuUsageValue: 0
    property real networkRxMBs: 0
    property real networkTxMBs: 0
    property int ramTotalGB: 0
    property int cpuTempValue: 0
    property int gpuTempValue: 0
    
    // Persistent Network State for accurate bps calculation
    property double lastNetRx: 0
    property double lastNetTx: 0
    property double lastNetTime: 0
    property string gpuBrand: "" // Cached GPU brand: nvidia, amd, intel, or sysfs
    
    // Helper to push to history
    function pushHistory(arr, val) {
        if (!arr) arr = []
        if (isNaN(val) || val === undefined || val === null) return arr
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
        if (res === "network") {
            var total = networkRxMBs + networkTxMBs
            if (total < 0.1) return (total * 1024).toFixed(0) + " KB/s"
            return total.toFixed(1) + " MB/s"
        }
        return cpuUsageValue + "%"
    }
    
    function getResourceSubText(res) {
        if (res === "ram") return (ramTotalGB > 0 ? ramTotalGB + " GB Total" : "")
        if (res === "gpu") return (gpuTempValue > 0 ? gpuTempValue + "°C" : "")
        if (res === "network") {
            function fmt(val) {
                if (val < 0.1) return (val * 1024).toFixed(0) + "K"
                return val.toFixed(1) + "M"
            }
            return "↓ " + fmt(networkRxMBs) + " ↑ " + fmt(networkTxMBs)
        }
        return (cpuTempValue > 0 ? cpuTempValue + "°C" : "")
    }

    property string panelPos: (sharedData && sharedData.dashboardPosition) ? sharedData.dashboardPosition : "right"
    property bool isHorizontal: panelPos === "top" || panelPos === "bottom"
    
    property bool isFloating: (sharedData && sharedData.floatingDashboard !== undefined) ? sharedData.floatingDashboard : true

    // Configurable anchors based on panelPos
    // Anchor to the primary edge AND perpendicular edges to stretch (with margins)
    anchors.top: panelPos === "top" || !isHorizontal
    anchors.bottom: panelPos === "bottom" || !isHorizontal
    anchors.left: panelPos === "left" || isHorizontal
    anchors.right: panelPos === "right" || isHorizontal
    
    // Floating Dashboard, width fixed 450, length stretched by anchors+margins
    implicitWidth: !isHorizontal ? 500 : (Quickshell.screens.length > 0 && Quickshell.screens[0]) ? Quickshell.screens[0].width : 1920
    implicitHeight: isHorizontal ? 450 : (Quickshell.screens.length > 0 && Quickshell.screens[0]) ? Quickshell.screens[0].height : 1080
    
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
    
    // Floating margins (distance from edge)
    // Primary axis (e.g. Right): Animate for slide-in (-width to 15)
    // Perpendicular axes (e.g. Top/Bottom): Fixed 15 OR 0 if classic
    margins {
        top: panelPos === "top" ? (-implicitHeight * (1.0 - showProgress) + (isFloating ? 15 : 0) * showProgress) : (isFloating ? 15 : 0)
        bottom: panelPos === "bottom" ? (-implicitHeight * (1.0 - showProgress) + (isFloating ? 15 : 0) * showProgress) : (isFloating ? 15 : 0)
        right: panelPos === "right" ? (-implicitWidth * (1.0 - showProgress) + (isFloating ? 15 : 0) * showProgress) : (isFloating ? 15 : 0)
        left: panelPos === "left" ? (-implicitWidth * (1.0 - showProgress) + (isFloating ? 15 : 0) * showProgress) : (isFloating ? 15 : 0)
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
        

            
            // Main Dashboard Panel
            Rectangle {
                id: dashboardBackground
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                width: 450
                
                radius: isFloating ? ((sharedData && sharedData.quickshellBorderRadius !== undefined) ? sharedData.quickshellBorderRadius : 14) : 0
                color: (sharedData && sharedData.colorBackground) ? sharedData.colorBackground : "#ffffff"
            clip: true // Clip children to rounded corners
            



            // Bottom Navigation Bar (Integrated)
            Rectangle {
                id: bottomNavBar
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: 50 // Fixed height for navbar
                
                // Inherit radius from parent for bottom corners
                radius: parent.radius 
                color: (sharedData && sharedData.colorSecondary) ? sharedData.colorSecondary : "#141414"
                
                // Fill top corners to make them sharp
                Rectangle {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: parent.height / 2
                    color: parent.color
                }
                
                // Top border for separation
                Rectangle {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 1
                    color: Qt.rgba(1,1,1,0.05)
                }

                Item {
                    anchors.centerIn: parent
                    width: (4 * 40) + (3 * 40) // 4 items * 40px + 3 spacings * 40px = 280px
                    height: 40
                    
                    // Sliding Active Indicator Pill
                    Rectangle {
                        width: 40
                        height: 40
                        radius: (sharedData && sharedData.quickshellBorderRadius !== undefined) ? (sharedData.quickshellBorderRadius > 8 ? 8 : sharedData.quickshellBorderRadius) : 8 // Consistent smaller radius for pill
                        color: (sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#00ff41"
                        opacity: 0.15
                        
                        // Calculate position based on currentTab index * (itemWidth + spacing)
                        x: currentTab * 80 
                        
                        Behavior on x { 
                            NumberAnimation { 
                                duration: 300
                                easing.type: Easing.OutBack 
                            } 
                        }
                    }

                    Row {
                        anchors.fill: parent
                        spacing: 40 // Spacing between icons
                        
                        Repeater {
                            model: [
                                { icon: "󰕮", tooltip: "Dashboard" },
                                { icon: "󰨸", tooltip: "Clipboard" },
                                { icon: "󰂚", tooltip: "Notifications" },
                                { icon: "󰓅", tooltip: "Performance" }
                            ]
                            
                            Item {
                                width: 40
                                height: 40
                                
                                property bool isActive: currentTab === index
                                property bool isHovered: navBarTabMouseArea.containsMouse

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.icon
                                    font.pixelSize: 24
                                    color: parent.isActive ? 
                                        ((sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#00ff41") : 
                                        ((sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff")
                                    opacity: parent.isActive ? 1.0 : (parent.isHovered ? 0.8 : 0.5)
                                    
                                    Behavior on color { ColorAnimation { duration: 200 } }
                                    Behavior on opacity { NumberAnimation { duration: 200 } }
                                    
                                    // Subtle scale pulse on active
                                    scale: parent.isActive ? 1.1 : (parent.isHovered ? 1.05 : 1.0)
                                    Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                                }
                                
                                MouseArea {
                                    id: navBarTabMouseArea
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    hoverEnabled: true
                                    onClicked: currentTab = index
                                }
                            }
                        }
                    }
                }
            }

            Column {
                id: dashboardColumn
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: bottomNavBar.top
                spacing: 0



            // ============ CONTENT AREA ============
            Item {
                id: contentArea
                width: parent.width

                height: parent.height
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
                        RowLayout {
                            id: topRow
                            Layout.fillWidth: true
                            Layout.preferredHeight: 75
                            spacing: 8
                            
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
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                Layout.preferredWidth: (parent.width - 8) / 2
                                
                                // Battery % Card - Vertical Pill Style
                                Rectangle {
                                    anchors.fill: parent
                                    visible: !(sharedData && sharedData.dashboardTileLeft === "network")
                                    radius: (sharedData && sharedData.quickshellBorderRadius !== undefined) ? sharedData.quickshellBorderRadius : 28
                                    color: (sharedData && sharedData.colorSecondary) ? sharedData.colorSecondary : "#141414"

                                    // Horizontal Battery Indicator (Pill Style)
                                    Item {
                                        scale: batMouseArea.containsMouse ? 1.02 : 1.0
                                        Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                                        MouseArea { id: batMouseArea; anchors.fill: parent; hoverEnabled: true; onClicked: { /* No action */ } }

                                        anchors.fill: parent
                                        anchors.margins: 12
                                        
                                        // Top Row: Icon + Value Text
                                        Row {
                                            anchors.centerIn: parent
                                            anchors.verticalCenterOffset: -6
                                            spacing: 6
                                            
                                            Text {
                                                text: isCharging ? "⚡" : ""
                                                font.pixelSize: 22
                                                color: (batteryPercent > 20 || isCharging) ? ((sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff") : "#FF4444" 
                                                visible: batteryPercent > 0
                                                anchors.verticalCenter: parent.verticalCenter
                                            }
                                            
                                            Text {
                                                text: (batteryPercent >= 0 ? batteryPercent + "%" : "--")
                                                font.pixelSize: 24
                                                font.weight: Font.Bold
                                                font.family: "sans-serif"
                                                color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff"
                                                anchors.verticalCenter: parent.verticalCenter
                                            }
                                        }
                                        
                                        // Bottom Bar: Progress
                                        Item {
                                            anchors.bottom: parent.bottom
                                            width: parent.width
                                            height: 14 // Thicker pill
                                            
                                            // Track
                                            Rectangle {
                                                anchors.fill: parent
                                                radius: height/2
                                                color: (sharedData && sharedData.colorText) ? Qt.alpha(sharedData.colorText, 0.15) : "#333333"
                                            }
                                            
                                            // Fill
                                            Rectangle {
                                                height: parent.height
                                                width: parent.width * (Math.max(0, Math.min(batteryPercent, 100)) / 100)
                                                radius: height/2
                                                
                                                color: (batteryPercent <= 20) ? "#FF4444" : ((sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff")
                                                
                                                Behavior on width { NumberAnimation { duration: 500; easing.type: Easing.OutExpo } }
                                            }
                                        }
                                    }
                                }
                            
                                // Network Card - Vertical Bars Style
                                Rectangle {
                                    anchors.fill: parent
                                    visible: (sharedData && sharedData.dashboardTileLeft === "network")
                                    radius: (sharedData && sharedData.quickshellBorderRadius !== undefined) ? sharedData.quickshellBorderRadius : 28
                                    color: (sharedData && sharedData.colorSecondary) ? sharedData.colorSecondary : "#141414"

                                    Item {
                                        anchors.fill: parent
                                        anchors.margins: 12
                                        
                                        scale: netMouseArea.containsMouse ? 1.02 : 1.0
                                        Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                                        MouseArea { id: netMouseArea; anchors.fill: parent; hoverEnabled: true; onClicked: { /* No action */ } }

                                        Row {
                                            anchors.centerIn: parent
                                            spacing: 12
                                            height: parent.height
                                            width: parent.width
                                        
                                            // Download Bar
                                            Item {
                                                width: 32
                                                height: parent.height
                                            
                                            Rectangle {
                                                anchors.fill: parent
                                                radius: width / 2
                                                color: (sharedData && sharedData.colorPrimary) ? sharedData.colorPrimary : "#1a1a1a"
                                                opacity: 0.8
                                            }

                                            Rectangle {
                                                width: parent.width
                                                // Logarithmic scale for visualisation
                                                height: parent.height * Math.min(1.0, Math.log10(Math.max(1, networkRxMBs * 10)) / 3) 
                                                anchors.bottom: parent.bottom
                                                radius: width / 2
                                                color: (sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff"
                                                Behavior on height { NumberAnimation { duration: 300 } }
                                            }
                                            
                                            Text {
                                                anchors.bottom: parent.bottom
                                                anchors.bottomMargin: 8
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                text: "↓"
                                                font.bold: true
                                                color: (sharedData && sharedData.colorBackground) ? sharedData.colorBackground : "#000000"
                                                visible: parent.height * Math.min(1.0, Math.log10(Math.max(1, networkRxMBs * 10)) / 3) > 20
                                            }
                                            // Fallback text if bar is too small
                                            Text {
                                                anchors.bottom: parent.bottom
                                                anchors.bottomMargin: 8
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                text: "↓"
                                                font.bold: true
                                                color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff"
                                                visible: parent.height * Math.min(1.0, Math.log10(Math.max(1, networkRxMBs * 10)) / 3) <= 20
                                            }
                                            }

                                            // Upload Bar
                                            Item {
                                                width: 32
                                                height: parent.height
                                                
                                                Rectangle {
                                                    anchors.fill: parent
                                                    radius: width / 2
                                                    color: (sharedData && sharedData.colorPrimary) ? sharedData.colorPrimary : "#1a1a1a"
                                                    opacity: 0.8
                                                }

                                                Rectangle {
                                                    width: parent.width
                                                    height: parent.height * Math.min(1.0, Math.log10(Math.max(1, networkTxMBs * 10)) / 3)
                                                    anchors.bottom: parent.bottom
                                                    radius: width / 2
                                                    color: (sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff"
                                                    opacity: 0.7
                                                    Behavior on height { NumberAnimation { duration: 300 } }
                                                }

                                                Text {
                                                    anchors.bottom: parent.bottom
                                                    anchors.bottomMargin: 8
                                                    anchors.horizontalCenter: parent.horizontalCenter
                                                    text: "↑"
                                                    font.bold: true
                                                    color: (sharedData && sharedData.colorBackground) ? sharedData.colorBackground : "#000000"
                                                    visible: parent.height * Math.min(1.0, Math.log10(Math.max(1, networkTxMBs * 10)) / 3) > 20
                                                }
                                                Text {
                                                    anchors.bottom: parent.bottom
                                                    anchors.bottomMargin: 8
                                                    anchors.horizontalCenter: parent.horizontalCenter
                                                    text: "↑"
                                                    font.bold: true
                                                    color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff"
                                                    visible: parent.height * Math.min(1.0, Math.log10(Math.max(1, networkTxMBs * 10)) / 3) <= 20
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            // Quick Actions Card (right)
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                Layout.preferredWidth: (parent.width - 8) / 2
                                radius: (sharedData && sharedData.quickshellBorderRadius !== undefined) ? sharedData.quickshellBorderRadius : 28
                                color: (sharedData && sharedData.colorSecondary) ? sharedData.colorSecondary : "#141414"
                                
                                scale: quickActionsMouseArea.containsMouse ? 1.02 : 1.0
                                Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                                MouseArea { id: quickActionsMouseArea; anchors.fill: parent; hoverEnabled: true; z: -1; onClicked: { /* No action */ } }
                                
                                // Center the grid in the card
                                GridLayout {
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    columns: 2
                                    rows: 2
                                    columnSpacing: 8
                                    rowSpacing: 8
                                        
                                        // Toggle Sidebar Button (Swiss Block)
                                    Rectangle {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        radius: (sharedData && sharedData.quickshellBorderRadius !== undefined) ? sharedData.quickshellBorderRadius : 6
                                        clip: true

                                            // Softer style - Visible background
                                            color: toggleSidebarQuickMouseArea.containsMouse ? 
                                                   Qt.rgba(1,1,1,0.2) : 
                                                   Qt.rgba(1,1,1,0.1)
                                            opacity: 1.0
                                        
                                        Text {
                                            anchors.centerIn: parent
                                            text: "󰍜"
                                            font.pixelSize: 22
                                            font.family: "sans-serif"
                                            color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff"
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
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        radius: (sharedData && sharedData.quickshellBorderRadius !== undefined) ? sharedData.quickshellBorderRadius : 6
                                        clip: true
                                        
                                        // Softer style
                                        color: ((dndQuickMouseArea.containsMouse) || (sharedData && sharedData.notificationsEnabled === false)) ? 
                                               ((sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#00ff41") : 
                                               Qt.rgba(1,1,1,0.1) // Visible default background


                                        Text {
                                            anchors.centerIn: parent
                                            text: "󰂛"
                                            font.pixelSize: 22
                                            font.family: "sans-serif"
                                            color: ((dndQuickMouseArea.containsMouse) || (sharedData && sharedData.notificationsEnabled === false)) ? 
                                                   ((sharedData && sharedData.colorBackground) ? sharedData.colorBackground : "#ffffff") :
                                                   ((sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff")
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
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        radius: (sharedData && sharedData.quickshellBorderRadius !== undefined) ? sharedData.quickshellBorderRadius : 6
                                        clip: true

                                        // Softer style
                                        color: lockQuickMouseArea.containsMouse ? 
                                               Qt.rgba(1,1,1,0.2) : 
                                               Qt.rgba(1,1,1,0.1)

                                        opacity: lockQuickMouseArea.containsMouse ? 0.8 : 1.0
                                        
                                        Text {
                                            anchors.centerIn: parent
                                            text: "󰌾"
                                            font.pixelSize: 22
                                            font.family: "sans-serif"
                                            color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff"
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
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        radius: (sharedData && sharedData.quickshellBorderRadius !== undefined) ? sharedData.quickshellBorderRadius : 6
                                        clip: true

                                        // Softer style
                                        color: poweroffQuickMouseArea.containsMouse ? 
                                               "#FF4444" : 
                                               Qt.rgba(1,1,1,0.1)

                                        opacity: poweroffQuickMouseArea.containsMouse ? 0.8 : 1.0
                                        
                                        Text {
                                            anchors.centerIn: parent
                                            text: "󰐥"
                                            font.pixelSize: 22
                                            font.family: "sans-serif"
                                            color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff"
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
                        
                        // Weather + Clock Row
                        RowLayout {
                            id: weatherClockRow
                            Layout.fillWidth: true
                            Layout.preferredHeight: 50
                            spacing: 8
                            
                            opacity: showProgress > 0.01 ? 1.0 : 0.0
                            transform: Translate {
                                y: showProgress > 0.01 ? 0 : 40
                                Behavior on y {
                                    SequentialAnimation {
                                        PauseAnimation { duration: 75 }
                                        NumberAnimation { duration: 700; easing.type: Easing.OutBack }
                                    }
                                }
                            }
                            
                            Behavior on opacity {
                                SequentialAnimation {
                                    PauseAnimation { duration: 75 }
                                    NumberAnimation { duration: 500; easing.type: Easing.OutCubic }
                                }
                            }
                            
                            // Weather Card (Left half)
                            Rectangle {
                                id: weatherCard
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                Layout.preferredWidth: (parent.width - 8) / 2
                                radius: (sharedData && sharedData.quickshellBorderRadius !== undefined) ? sharedData.quickshellBorderRadius : 12
                                color: (sharedData && sharedData.colorSecondary) ? sharedData.colorSecondary : "#141414"
                                
                                scale: weatherMouseArea.containsMouse ? 1.02 : 1.0
                                Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                                MouseArea { id: weatherMouseArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: updateWeather() }

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 6
                                    spacing: 0

                                    Item { Layout.fillHeight: true }

                                    Text {
                                        text: {
                                            var cond = weatherCondition.toLowerCase()
                                            if (cond.indexOf("sun") !== -1 || cond.indexOf("clear") !== -1) return "󰖙"
                                            if (cond.indexOf("cloud") !== -1) return "󰖐"
                                            if (cond.indexOf("rain") !== -1) return "󰖗"
                                            if (cond.indexOf("snow") !== -1) return "󰼶"
                                            if (cond.indexOf("storm") !== -1 || cond.indexOf("thunder") !== -1) return "󰖓"
                                            return "󰖕"
                                        }
                                        font.pixelSize: 24
                                        color: (sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff"
                                        Layout.alignment: Qt.AlignHCenter
                                    }

                                    Text {
                                        text: weatherTemp
                                        font.pixelSize: 20
                                        font.weight: Font.Bold
                                        font.family: "sans-serif"
                                        color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff"
                                        Layout.alignment: Qt.AlignHCenter
                                    }

                                    Item { Layout.fillHeight: true }
                                }
                            }
                            
                            // Clock/Date Card (Right half) - NEW
                            Rectangle {
                                id: clockCard
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                Layout.preferredWidth: (parent.width - 8) / 2
                                radius: (sharedData && sharedData.quickshellBorderRadius !== undefined) ? sharedData.quickshellBorderRadius : 12
                                color: (sharedData && sharedData.colorSecondary) ? sharedData.colorSecondary : "#141414"
                                
                                property string currentTime: Qt.formatDateTime(new Date(), "HH:mm")
                                property string currentDate: Qt.formatDateTime(new Date(), "ddd, MMM d")
                                property int currentSeconds: new Date().getSeconds()
                                
                                Timer {
                                    interval: 1000
                                    running: true
                                    repeat: true
                                    onTriggered: {
                                        clockCard.currentTime = Qt.formatDateTime(new Date(), "HH:mm")
                                        clockCard.currentDate = Qt.formatDateTime(new Date(), "ddd, MMM d")
                                        clockCard.currentSeconds = new Date().getSeconds()
                                    }
                                }
                                
                                scale: clockMouseArea.containsMouse ? 1.02 : 1.0
                                Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                                MouseArea { id: clockMouseArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor }

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 6
                                    spacing: 2
                                    
                                    Item { Layout.fillHeight: true }


                                    Text {
                                        text: clockCard.currentTime
                                        font.pixelSize: 24
                                        font.weight: Font.Bold
                                        font.family: "sans-serif"
                                        color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff"
                                        Layout.alignment: Qt.AlignHCenter
                                    }
                                    
                                    Text {
                                        text: clockCard.currentDate.toUpperCase()
                                        font.pixelSize: 10
                                        font.weight: Font.Black
                                        font.family: "sans-serif"
                                        font.letterSpacing: 1
                                        color: (sharedData && sharedData.colorText) ? Qt.alpha(sharedData.colorText, 0.5) : "#888888"
                                        Layout.alignment: Qt.AlignHCenter
                                    }

                                    Item { Layout.fillHeight: true }
                                }
                            }
                        }
                        
                        // Date/Calendar or GitHub Activity Card – Swiss Style
                        Rectangle {
                            id: calendarGithubCard
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.preferredHeight: 180
                            Layout.minimumHeight: 150
                            radius: (sharedData && sharedData.quickshellBorderRadius !== undefined) ? sharedData.quickshellBorderRadius : 28
                            color: (sharedData && sharedData.colorSecondary) ? sharedData.colorSecondary : "#141414"

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

                            MouseArea { id: calendarGithubMouseArea; anchors.fill: parent; hoverEnabled: true; onClicked: { /* No action */ } }

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
                                                radius: (sharedData && sharedData.quickshellBorderRadius !== undefined) ? sharedData.quickshellBorderRadius : 0
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
                            Layout.preferredHeight: 150
                            Layout.minimumHeight: 130
                            radius: (sharedData && sharedData.quickshellBorderRadius !== undefined) ? sharedData.quickshellBorderRadius : 28
                            color: (sharedData && sharedData.colorSecondary) ? sharedData.colorSecondary : "#141414"
                            
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
                            Layout.preferredHeight: 150
                            Layout.minimumHeight: 130
                            radius: (sharedData && sharedData.quickshellBorderRadius !== undefined) ? sharedData.quickshellBorderRadius : 28
                            color: (sharedData && sharedData.colorSecondary) ? sharedData.colorSecondary : "#141414"
                            
                            scale: res2MouseArea.containsMouse ? 1.02 : (showProgress > 0.01 ? 1.0 : 0.9)
                            Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                            MouseArea { id: res2MouseArea; anchors.fill: parent; hoverEnabled: true; z: -1; onClicked: { /* No action */ } }
                            
                            property string resource: (sharedData && sharedData.dashboardResource2) ? sharedData.dashboardResource2 : "ram"
                            
                            opacity: showProgress > 0.01 ? 1.0 : 0.0
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
                        
                        // Media Player Card - Refined Layout
                        Rectangle {
                            id: mediaPlayerCard
                            Layout.fillWidth: true
                            Layout.preferredHeight: 140
                            radius: (sharedData && sharedData.quickshellBorderRadius !== undefined) ? sharedData.quickshellBorderRadius : 28
                            color: (sharedData && sharedData.colorSecondary) ? sharedData.colorSecondary : "#141414"

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

                            MouseArea { id: mediaMouseArea; anchors.fill: parent; hoverEnabled: true }

                            // Audio visualizer bars (cava)
                            Row {
                                anchors.fill: parent
                                anchors.margins: 2
                                anchors.bottomMargin: -2
                                spacing: 2
                                opacity: mpPlaying ? 0.15 : 0
                                visible: opacity > 0
                                z: 0
                                
                                Behavior on opacity { NumberAnimation { duration: 1000 } }
                                
                                Repeater {
                                    model: 36
                                    Rectangle {
                                        width: (parent.width - (35 * 2)) / 36
                                        height: {
                                            if (cavaValues && cavaValues.length > index) {
                                                var val = parseInt(cavaValues[index]);
                                                var h = isNaN(val) ? 0 : (val / 100 * parent.height);
                                                return Math.max(2, h);
                                            }
                                            return 0;
                                        }
                                        color: (sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff"
                                        radius: 1
                                        anchors.bottom: parent.bottom
                                        
                                        Behavior on height {
                                            NumberAnimation { duration: 100; easing.type: Easing.OutQuint }
                                        }
                                    }
                                }
                            }

                            // Removed adaptive accent glow to keep background color consistent
                            /*
                            Rectangle {
                                anchors.fill: parent
                                radius: parent.radius
                                color: (sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff"
                                opacity: mpPlaying ? 0.05 : 0
                                Behavior on opacity { NumberAnimation { duration: 1000 } }
                            }
                            */

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 16
                                spacing: 12

                                    RowLayout {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 100
                                        spacing: 16
                                        
                                        // Cover Art
                                        Rectangle {
                                            Layout.preferredWidth: 100
                                            Layout.preferredHeight: 100
                                            radius: (sharedData && sharedData.quickshellBorderRadius !== undefined) ? Math.min(sharedData.quickshellBorderRadius, 12) : 8
                                            color: (sharedData && sharedData.colorPrimary) ? sharedData.colorPrimary : "#1a1a1a"
                                            clip: true
                                            
                                            Image {
                                                anchors.fill: parent
                                                source: mpArt ? mpArt : ""
                                                fillMode: Image.PreserveAspectCrop
                                                asynchronous: true
                                                opacity: source != "" ? 1.0 : 0.0
                                                Behavior on opacity { NumberAnimation { duration: 400 } }
                                            }
                                            
                                            Text {
                                                anchors.centerIn: parent
                                                text: "󰃆"
                                                font.pixelSize: 36
                                                color: (sharedData && sharedData.colorText) ? Qt.alpha(sharedData.colorText, 0.4) : "#333333"
                                                visible: !mpArt
                                            }
                                        }

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            Layout.fillHeight: true
                                            spacing: 10
                                            
                                            // Song info
                                            ColumnLayout {
                                                Layout.fillWidth: true
                                                spacing: 2
                                                Text {
                                                    text: mpTitle ? mpTitle : "NOTHING PLAYING"
                                                    font.pixelSize: 14
                                                    font.weight: Font.Bold
                                                    font.family: "sans-serif"
                                                    color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff"
                                                    elide: Text.ElideRight
                                                    Layout.fillWidth: true
                                                }
                                                Text {
                                                    text: mpArtist ? mpArtist : "Unknown Artist"
                                                    font.pixelSize: 11
                                                    font.family: "sans-serif"
                                                    color: (sharedData && sharedData.colorText) ? Qt.alpha(sharedData.colorText, 0.6) : "#888888"
                                                    elide: Text.ElideRight
                                                    Layout.fillWidth: true
                                                }
                                            }

                                            Item { Layout.fillHeight: true }

                                            // Controls - Centered and larger
                                            RowLayout {
                                                Layout.fillWidth: true
                                                spacing: 16
                                                
                                                Item { Layout.fillWidth: true }
                                                
                                                Rectangle {
                                                    width: 38
                                                    height: 38
                                                    radius: (sharedData && sharedData.quickshellBorderRadius !== undefined) ? Math.min(sharedData.quickshellBorderRadius, 10) : 10
                                                    color: prevMa.containsMouse ? Qt.rgba(1,1,1,0.15) : "transparent"
                                                    
                                                    Text {
                                                        anchors.centerIn: parent
                                                        text: "󰒮"
                                                        font.pixelSize: 20
                                                        color: prevMa.containsMouse ? (sharedData.colorAccent || "#4a9eff") : (sharedData.colorText || "#ffffff")
                                                        opacity: prevMa.pressed ? 0.7 : 1.0
                                                    }
                                                    MouseArea { id: prevMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: playerPrev() }
                                                }
                                                
                                                Rectangle {
                                                    width: 48
                                                    height: 48
                                                    radius: (sharedData && sharedData.quickshellBorderRadius !== undefined) ? Math.min(sharedData.quickshellBorderRadius, 12) : 12
                                                    color: playMa.containsMouse ? (sharedData.colorAccent || "#4a9eff") : Qt.rgba(1,1,1,0.12)
                                                    scale: playMa.pressed ? 0.9 : 1.0
                                                    Behavior on scale { NumberAnimation { duration: 100 } }
                                                    Behavior on color { ColorAnimation { duration: 150 } }
                                                    
                                                    Text {
                                                        anchors.centerIn: parent
                                                        anchors.horizontalCenterOffset: !mpPlaying ? 2 : 0
                                                        text: mpPlaying ? "󰏤" : "󰐊"
                                                        font.pixelSize: 24
                                                        color: playMa.containsMouse ? "#000000" : (sharedData.colorText || "#ffffff")
                                                    }
                                                    MouseArea { id: playMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: playerPlayPause() }
                                                }
                                                
                                                Rectangle {
                                                    width: 38
                                                    height: 38
                                                    radius: (sharedData && sharedData.quickshellBorderRadius !== undefined) ? Math.min(sharedData.quickshellBorderRadius, 10) : 10
                                                    color: nextMa.containsMouse ? Qt.rgba(1,1,1,0.15) : "transparent"
                                                    
                                                    Text {
                                                        anchors.centerIn: parent
                                                        text: "󰒭"
                                                        font.pixelSize: 20
                                                        color: nextMa.containsMouse ? (sharedData.colorAccent || "#4a9eff") : (sharedData.colorText || "#ffffff")
                                                        opacity: nextMa.pressed ? 0.7 : 1.0
                                                    }
                                                    MouseArea { id: nextMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: playerNext() }
                                                }
                                                
                                                Item { Layout.fillWidth: true }
                                            }
                                        }
                                    }

                                // Progress Section at bottom
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 4
                                    
                                    Rectangle {
                                        Layout.fillWidth: true
                                        height: 3
                                        radius: 1.5
                                        color: Qt.rgba(1,1,1,0.05)
                                        
                                        Rectangle {
                                            width: (mpLength > 0 ? (parent.width * (mpPosition / mpLength)) : 0)
                                            height: parent.height
                                            radius: 1.5
                                            color: (sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff"
                                            Behavior on width { NumberAnimation { duration: 500; easing.type: Easing.OutQuint } }
                                        }
                                    }
                                    
                                    RowLayout {
                                        Layout.fillWidth: true
                                        Text { 
                                            text: dashboardRoot.formatTime(mpPosition)
                                            font.pixelSize: 8
                                            font.family: "sans-serif"
                                            color: (sharedData && sharedData.colorText) ? Qt.alpha(sharedData.colorText, 0.5) : "#888888"
                                        }
                                        Item { Layout.fillWidth: true }
                                        Text { 
                                            text: mpLength > 0 ? dashboardRoot.formatTime(mpLength) : "0:00"
                                            font.pixelSize: 8
                                            font.family: "sans-serif"
                                            color: (sharedData && sharedData.colorText) ? Qt.alpha(sharedData.colorText, 0.5) : "#888888"
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
                                radius: (sharedData && sharedData.quickshellBorderRadius !== undefined) ? sharedData.quickshellBorderRadius : 0
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
                                    radius: (sharedData && sharedData.quickshellBorderRadius !== undefined) ? sharedData.quickshellBorderRadius : 0
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
                                radius: (sharedData && sharedData.quickshellBorderRadius !== undefined) ? sharedData.quickshellBorderRadius : 0
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
                                radius: (sharedData && sharedData.quickshellBorderRadius !== undefined) ? sharedData.quickshellBorderRadius : 0
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
                                        radius: (sharedData && sharedData.quickshellBorderRadius !== undefined) ? sharedData.quickshellBorderRadius : 0
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
                                        radius: (sharedData && sharedData.quickshellBorderRadius !== undefined) ? sharedData.quickshellBorderRadius : 0
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

                // ============ TAB 3: PERFORMANCE ============
                Item {
                    id: performanceTab
                    anchors.fill: parent
                    visible: currentTab === 3
                    opacity: currentTab === 3 ? 1.0 : 0.0
                    x: currentTab === 3 ? 0 : (currentTab < 3 ? -parent.width * 0.3 : parent.width * 0.3)
                    scale: currentTab === 3 ? 1.0 : 0.95
                    
                    Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
                    Behavior on x { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
                    Behavior on scale { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }

                    onVisibleChanged: {
                        if (visible) {
                            updateDiskUsage()
                            updateTopProcesses()
                            updateSystemInfo()
                            updateNetwork()
                            updateCpuTemp()
                            updateGpuTemp()
                        }
                    }
                    
                    z: 5

                    ColumnLayout {
                        id: performanceTabContent
                        anchors.fill: parent
                        anchors.margins: 24
                        spacing: 16

                        // --- SWISS HEADER ---
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            
                            Text {
                                text: "PERFORMANCE"
                                font.pixelSize: 32
                                font.weight: Font.Black
                                font.family: "Inter, Roboto, sans-serif"
                                color: (sharedData && sharedData.colorText) || "#ffffff"
                                font.letterSpacing: -1
                            }
                            
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 2
                                color: (sharedData && sharedData.colorAccent) || "#00ff41"
                                Layout.topMargin: 4
                            }
                            
                            RowLayout {
                                Layout.topMargin: 8
                                spacing: 12
                                Text {
                                    text: "System: " + osPrettyName
                                    font.pixelSize: 12
                                    font.weight: Font.Bold
                                    color: Qt.alpha((sharedData && sharedData.colorText) || "#ffffff", 0.6)
                                }
                                Item { Layout.fillWidth: true }
                                Text {
                                    text: "Up: " + uptimeString
                                    font.pixelSize: 12
                                    font.weight: Font.Medium
                                    color: Qt.alpha((sharedData && sharedData.colorText) || "#ffffff", 0.4)
                                }
                            }
                        }

                        // --- MAIN METRICS GRID (CPU, RAM, GPU, DISK) ---
                        GridLayout {
                            Layout.fillWidth: true
                            columns: 2
                            columnSpacing: 12
                            rowSpacing: 12

                            // CPU Metric Card
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 100
                                radius: 0
                                color: (sharedData && sharedData.colorSecondary) || "#141414"
                                border.width: 1; border.color: Qt.rgba(1,1,1,0.1)

                                ColumnLayout {
                                    anchors.fill: parent; anchors.margins: 12; spacing: 0
                                    Text { text: "CPU"; font.pixelSize: 10; font.weight: Font.Black; color: Qt.alpha((sharedData && sharedData.colorText) || "#ffffff", 0.4) }
                                    RowLayout {
                                        Text { 
                                            text: cpuUsageValue + "%"
                                            font.pixelSize: 28; font.weight: Font.Black
                                            color: (sharedData && sharedData.colorText) || "#ffffff" 
                                        }
                                        Item { Layout.fillWidth: true }
                                        Text { 
                                            text: cpuTempValue + "°C"
                                            font.pixelSize: 14; font.weight: Font.Bold
                                            color: (sharedData && sharedData.colorAccent) || "#00ff41" 
                                        }
                                    }
                                    Item { Layout.fillHeight: true }
                                    Canvas {
                                        id: cpuChart
                                        Layout.fillWidth: true; Layout.preferredHeight: 30
                                        onPaint: {
                                            var ctx = getContext("2d"); ctx.reset();
                                            var hist = dashboardRoot.getResourceHistory("cpu");
                                            if (!hist || hist.length < 2) return;
                                            var w = width; var h = height; var step = w / (hist.length - 1);
                                            var color = (sharedData && sharedData.colorAccent) || "#00ff41";
                                            
                                            // Area Fill
                                            var grad = ctx.createLinearGradient(0, 0, 0, h);
                                            grad.addColorStop(0, Qt.alpha(color, 0.2));
                                            grad.addColorStop(1, "transparent");
                                            ctx.fillStyle = grad;
                                            ctx.beginPath();
                                            ctx.moveTo(0, h);
                                            for(var i=0; i<hist.length; i++) ctx.lineTo(i*step, h - (hist[i]/100)*h);
                                            ctx.lineTo(w, h); ctx.closePath(); ctx.fill();
                                            
                                            // Stroke Line
                                            ctx.beginPath();
                                            for(var j=0; j<hist.length; j++) ctx.lineTo(j*step, h - (hist[j]/100)*h);
                                            ctx.strokeStyle = color; ctx.lineWidth = 2; ctx.stroke();
                                        }
                                        Connections { target: dashboardRoot; function onPerfUpdated() { if(currentTab===3) cpuChart.requestPaint() } }
                                    }
                                }
                            }

                            // RAM Metric Card
                            Rectangle {
                                Layout.fillWidth: true; Layout.preferredHeight: 100
                                radius: 0; color: (sharedData && sharedData.colorSecondary) || "#141414"
                                border.width: 1; border.color: Qt.rgba(1,1,1,0.1)

                                ColumnLayout {
                                    anchors.fill: parent; anchors.margins: 12; spacing: 0
                                    Text { text: "RAM"; font.pixelSize: 10; font.weight: Font.Black; color: Qt.alpha((sharedData && sharedData.colorText) || "#ffffff", 0.4) }
                                    RowLayout {
                                        Text { 
                                            text: ramUsageValue + "%"
                                            font.pixelSize: 28; font.weight: Font.Black
                                            color: (sharedData && sharedData.colorText) || "#ffffff" 
                                        }
                                        Item { Layout.fillWidth: true }
                                        Text { 
                                            text: ramTotalGB + "G"
                                            font.pixelSize: 14; font.weight: Font.Bold
                                            color: Qt.alpha((sharedData && sharedData.colorText) || "#ffffff", 0.4) 
                                        }
                                    }
                                    Item { Layout.fillHeight: true }
                                    Canvas {
                                        id: ramChart
                                        Layout.fillWidth: true; Layout.preferredHeight: 30
                                        onPaint: {
                                            var ctx = getContext("2d"); ctx.reset();
                                            var hist = dashboardRoot.getResourceHistory("ram");
                                            if (!hist || hist.length < 2) return;
                                            var w = width; var h = height; var step = w / (hist.length - 1);
                                            var color = (sharedData && sharedData.colorAccent) || "#00ff41";
                                            
                                            // Area Fill
                                            var grad = ctx.createLinearGradient(0, 0, 0, h);
                                            grad.addColorStop(0, Qt.alpha(color, 0.2));
                                            grad.addColorStop(1, "transparent");
                                            ctx.fillStyle = grad;
                                            ctx.beginPath();
                                            ctx.moveTo(0, h);
                                            for(var i=0; i<hist.length; i++) ctx.lineTo(i*step, h - (hist[i]/100)*h);
                                            ctx.lineTo(w, h); ctx.closePath(); ctx.fill();
                                            
                                            // Stroke Line
                                            ctx.beginPath();
                                            for(var j=0; j<hist.length; j++) ctx.lineTo(j*step, h - (hist[j]/100)*h);
                                            ctx.strokeStyle = color; ctx.lineWidth = 2; ctx.stroke();
                                        }
                                        Connections { target: dashboardRoot; function onPerfUpdated() { if(currentTab===3) ramChart.requestPaint() } }
                                    }
                                }
                            }

                            // GPU Metric Card (NEW)
                            Rectangle {
                                Layout.fillWidth: true; Layout.preferredHeight: 100
                                radius: 0; color: (sharedData && sharedData.colorSecondary) || "#141414"
                                border.width: 1; border.color: Qt.rgba(1,1,1,0.1)

                                ColumnLayout {
                                    anchors.fill: parent; anchors.margins: 12; spacing: 0
                                    Text { text: "GPU"; font.pixelSize: 10; font.weight: Font.Black; color: Qt.alpha((sharedData && sharedData.colorText) || "#ffffff", 0.4) }
                                    RowLayout {
                                        Text { 
                                            text: gpuUsageValue + "%"
                                            font.pixelSize: 28; font.weight: Font.Black
                                            color: (sharedData && sharedData.colorText) || "#ffffff" 
                                        }
                                        Item { Layout.fillWidth: true }
                                        Text { 
                                            text: gpuTempValue + "°C"
                                            font.pixelSize: 14; font.weight: Font.Bold
                                            color: (sharedData && sharedData.colorAccent) || "#00ff41" 
                                        }
                                    }
                                    Item { Layout.fillHeight: true }
                                    Canvas {
                                        id: gpuChart
                                        Layout.fillWidth: true; Layout.preferredHeight: 30
                                        onPaint: {
                                            var ctx = getContext("2d"); ctx.reset();
                                            var hist = dashboardRoot.getResourceHistory("gpu");
                                            if (!hist || hist.length < 2) return;
                                            var w = width; var h = height; var step = w / (hist.length - 1);
                                            var color = (sharedData && sharedData.colorAccent) || "#00ff41";
                                            
                                            // Area Fill
                                            var grad = ctx.createLinearGradient(0, 0, 0, h);
                                            grad.addColorStop(0, Qt.alpha(color, 0.2));
                                            grad.addColorStop(1, "transparent");
                                            ctx.fillStyle = grad;
                                            ctx.beginPath();
                                            ctx.moveTo(0, h);
                                            for(var i=0; i<hist.length; i++) ctx.lineTo(i*step, h - (hist[i]/100)*h);
                                            ctx.lineTo(w, h); ctx.closePath(); ctx.fill();
                                            
                                            // Stroke Line
                                            ctx.beginPath();
                                            for(var j=0; j<hist.length; j++) ctx.lineTo(j*step, h - (hist[j]/100)*h);
                                            ctx.strokeStyle = color; ctx.lineWidth = 2; ctx.stroke();
                                        }
                                        Connections { target: dashboardRoot; function onPerfUpdated() { if(currentTab===3) gpuChart.requestPaint() } }
                                    }
                                }
                            }

                            // DISK Metric Card
                            Rectangle {
                                Layout.fillWidth: true; Layout.preferredHeight: 100
                                radius: 0; color: (sharedData && sharedData.colorSecondary) || "#141414"
                                border.width: 1; border.color: Qt.rgba(1,1,1,0.1)

                                ColumnLayout {
                                    anchors.fill: parent; anchors.margins: 12; spacing: 8
                                    Text { text: "DISK"; font.pixelSize: 10; font.weight: Font.Black; color: Qt.alpha((sharedData && sharedData.colorText) || "#ffffff", 0.4) }
                                    Column {
                                        Layout.fillWidth: true; spacing: 4
                                        Repeater {
                                            model: diskUsageModel
                                            delegate: Column {
                                                width: parent.width; spacing: 1; visible: index < 2
                                                RowLayout {
                                                    Text { text: modelData.mount.toUpperCase(); font.pixelSize: 9; font.weight: Font.Bold; color: (sharedData && sharedData.colorText) || "#ffffff"; Layout.fillWidth: true }
                                                    Text { text: modelData.usage + "%"; font.pixelSize: 9; font.weight: Font.Black; color: (sharedData && sharedData.colorAccent) || "#00ff41" }
                                                }
                                                Rectangle {
                                                    width: parent.width; height: 4; color: Qt.rgba(1,1,1,0.05);
                                                    Rectangle { height: parent.height; width: parent.width * (modelData.usage / 100); color: (sharedData && sharedData.colorAccent) || "#00ff41" }
                                                }
                                            }
                                        }
                                    }
                                    Item { Layout.fillHeight: true }
                                }
                            }
                        }

                        // --- NETWORK CARD (Full width) ---
                        Rectangle {
                            Layout.fillWidth: true; Layout.preferredHeight: 60
                            radius: 0; color: (sharedData && sharedData.colorSecondary) || "#141414"
                            border.width: 1; border.color: Qt.rgba(1,1,1,0.1)

                            RowLayout {
                                anchors.fill: parent; anchors.margins: 12; spacing: 16
                                Column {
                                    Text { text: "NET"; font.pixelSize: 10; font.weight: Font.Black; color: Qt.alpha((sharedData && sharedData.colorText) || "#ffffff", 0.4) }
                                    RowLayout {
                                        spacing: 8
                                        Text { 
                                            text: {
                                                if (networkRxMBs < 0.1) return "↓ " + (networkRxMBs * 1024).toFixed(0) + " KB/s"
                                                return "↓ " + networkRxMBs.toFixed(1) + " MB/s"
                                            }
                                            font.pixelSize: 18; font.weight: Font.Black
                                            color: (sharedData && sharedData.colorText) || "#ffffff" 
                                        }
                                        Text { 
                                            text: {
                                                if (networkTxMBs < 0.1) return "↑ " + (networkTxMBs * 1024).toFixed(0) + " KB/s"
                                                return "↑ " + networkTxMBs.toFixed(1) + " MB/s"
                                            }
                                            font.pixelSize: 18; font.weight: Font.Black
                                            color: Qt.alpha((sharedData && sharedData.colorText) || "#ffffff", 0.4) 
                                        }
                                    }
                                }
                                Item { Layout.fillWidth: true; Layout.fillHeight: true; 
                                    Canvas {
                                        id: netChart
                                        anchors.fill: parent; anchors.topMargin: 4; anchors.bottomMargin: 4
                                        onPaint: {
                                            var ctx = getContext("2d"); ctx.reset();
                                            var hist = dashboardRoot.getResourceHistory("network");
                                            if (!hist || hist.length < 2) return;
                                            var w = width; var h = height; var step = w / (hist.length - 1);
                                            var color = (sharedData && sharedData.colorAccent) || "#00ff41";
                                            
                                            // Area Fill
                                            var grad = ctx.createLinearGradient(0, 0, 0, h);
                                            grad.addColorStop(0, Qt.alpha(color, 0.2));
                                            grad.addColorStop(1, "transparent");
                                            ctx.fillStyle = grad;
                                            ctx.beginPath();
                                            ctx.moveTo(0, h);
                                            for(var i=0; i<hist.length; i++) ctx.lineTo(i*step, h - (Math.min(hist[i], 20)/20)*h);
                                            ctx.lineTo(w, h); ctx.closePath(); ctx.fill();
                                            
                                            // Stroke Line
                                            ctx.beginPath();
                                            for(var j=0; j<hist.length; j++) ctx.lineTo(j*step, h - (Math.min(hist[j], 20)/20)*h);
                                            ctx.strokeStyle = color; ctx.lineWidth = 2; ctx.stroke();
                                        }
                                        Connections { target: dashboardRoot; function onPerfUpdated() { if(currentTab===3) netChart.requestPaint() } }
                                    }
                                }
                            }
                        }

                        // --- PROCESSES ---
                        Rectangle {
                            Layout.fillWidth: true; Layout.fillHeight: true;
                            radius: 0; color: (sharedData && sharedData.colorSecondary) || "#141414"
                            border.width: 1; border.color: Qt.rgba(1,1,1,0.1)

                            ColumnLayout {
                                anchors.fill: parent; anchors.margins: 12; spacing: 8
                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { text: "PROCESSES"; font.pixelSize: 10; font.weight: Font.Black; color: Qt.alpha((sharedData && sharedData.colorText) || "#ffffff", 0.4) }
                                    Item { Layout.fillWidth: true }
                                    Text { text: "MEM"; font.pixelSize: 8; font.weight: Font.Bold; color: Qt.alpha((sharedData && sharedData.colorText) || "#ffffff", 0.2) }
                                    Text { text: "CPU"; font.pixelSize: 8; font.weight: Font.Bold; color: Qt.alpha((sharedData && sharedData.colorText) || "#ffffff", 0.2); Layout.preferredWidth: 30; horizontalAlignment: Text.AlignRight }
                                }
                                ListView {
                                    Layout.fillWidth: true; Layout.fillHeight: true;
                                    model: topProcessesModel; interactive: false; clip: true; spacing: 2
                                    delegate: Rectangle {
                                        width: parent.width; height: 24; color: Qt.rgba(1,1,1,0.03)
                                        RowLayout {
                                            anchors.fill: parent; anchors.leftMargin: 8; anchors.rightMargin: 8; spacing: 8
                                            Text { text: modelData.name.toUpperCase(); font.pixelSize: 10; font.weight: Font.Bold; color: (sharedData && sharedData.colorText) || "#ffffff"; elide: Text.ElideRight; Layout.fillWidth: true }
                                            Text { text: modelData.mem + "%"; font.pixelSize: 10; font.weight: Font.Medium; color: Qt.alpha((sharedData && sharedData.colorText) || "#ffffff", 0.4) }
                                            Text { 
                                                text: modelData.cpu + "%"
                                                font.pixelSize: 10; font.weight: Font.Black
                                                color: parseFloat(modelData.cpu) > 20 ? ((sharedData && sharedData.colorAccent) || "#00ff41") : "#ffffff"
                                                Layout.preferredWidth: 30; horizontalAlignment: Text.AlignRight
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    } // performanceTabContent
                } // performanceTab
            } // contentArea
        } // dashboardColumn
    } // dashboardBackground
    } // dashboardContainer

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
    
    // Uptime
    property string uptimeDisplayText: "󰥔: --"
    
    // Battery
    property int batteryPercent: -1
    property bool isCharging: false
    
    // Weather
    property string weatherTemp: "--"
    property string weatherCondition: "Loading weather..."
    
    // Performance tab models
    property var diskUsageModel: []
    property var topProcessesModel: []
    property string windowManager: "Unknown"
    
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
        var loc = (sharedData && sharedData.weatherLocation) ? sharedData.weatherLocation : ""
        var query = loc.replace(/ /g, "+")
        if (sharedData && sharedData.runCommand) sharedData.runCommand(['sh','-c','curl -s "wttr.in/' + query + '?format=%t+%C" 2>/dev/null | head -1 > /tmp/quickshell_weather || echo "15°C Clear" > /tmp/quickshell_weather'], readWeather)
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
                    dashboardRoot.distroName = distro
                }
            }
        }
        xhr.send()
    }
    
    function updateBattery() {
        if (sharedData && sharedData.runCommand) sharedData.runCommand(['sh','-c','(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null; cat /sys/class/power_supply/BAT*/status 2>/dev/null) | head -2 > /tmp/quickshell_battery || echo "-1\nUnknown" > /tmp/quickshell_battery'], readBattery)
    }
    
    function readBattery() {
        var xhr = new XMLHttpRequest()
        xhr.open("GET", "file:///tmp/quickshell_battery")
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                var text = xhr.responseText.trim()
                var lines = text.split('\n')
                var p = parseInt(lines[0], 10)
                dashboardRoot.batteryPercent = (!isNaN(p) && p >= 0 && p <= 100) ? p : -1
                
                if (lines.length > 1) {
                    var status = lines[1].trim()
                    dashboardRoot.isCharging = (status === "Charging")
                } else {
                    dashboardRoot.isCharging = false
                }
            }
        }
        xhr.send()
    }
    
    function updateNetwork() {
        if (sharedData && sharedData.runCommand) {
            // Simplified: just cat the file, delta calculation happens in readNetwork
            sharedData.runCommand(['sh','-c', 'cat /proc/net/dev > /tmp/quickshell_net_dev'], readNetwork)
        }
    }
    function readNetwork() {
        var xhr = new XMLHttpRequest()
        xhr.open("GET", "file:///tmp/quickshell_net_dev")
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                var s = (xhr.responseText || "").trim()
                var lines = s.split("\n")
                var totalRx = 0
                var totalTx = 0
                
                for (var i = 2; i < lines.length; i++) {
                    var line = lines[i].trim()
                    if (!line) continue
                    var parts = line.split(/\s+/)
                    if (parts.length >= 10) {
                        totalRx += parseFloat(parts[1])
                        totalTx += parseFloat(parts[9])
                    }
                }
                
                var now = Date.now()
                if (lastNetTime > 0) {
                    var dt = (now - lastNetTime) / 1000 // seconds
                    if (dt > 0) {
                        networkRxMBs = Math.max(0, (totalRx - lastNetRx) / 1048576 / dt)
                        networkTxMBs = Math.max(0, (totalTx - lastNetTx) / 1048576 / dt)
                        
                        // Update History
                        networkHistory = pushHistory(networkHistory, networkRxMBs + networkTxMBs)
                        dashboardRoot.perfUpdated()
                    }
                }
                
                lastNetRx = totalRx
                lastNetTx = totalTx
                lastNetTime = now
            }
        }
        xhr.send()
    }
    
    function updateWindowManager() {
        if (sharedData && sharedData.runCommand) sharedData.runCommand(['sh','-c','(echo $XDG_CURRENT_DESKTOP 2>/dev/null | cut -d: -f1 || echo $DESKTOP_SESSION 2>/dev/null || ps -e | grep -E "(hyprland|sway|i3|kwin|mutter|xfwm4|openbox|dwm)" | head -1 | awk \'{print $4}\' | tr -d \'"\' || echo "Unknown") > /tmp/quickshell_wm'], readWindowManager)
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
                    uptimeString = uptimeStr
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

    function formatTime(sec) {
        if (isNaN(sec) || sec < 0) return "00:00"
        var h = Math.floor(sec / 3600)
        var m = Math.floor((sec % 3600) / 60)
        var s = Math.floor(sec % 60)
        if (h > 0) {
            return h + ":" + (m < 10 ? "0" + m : m) + ":" + (s < 10 ? "0" + s : s)
        }
        return (m < 10 ? "0" + m : m) + ":" + (s < 10 ? "0" + s : s)
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
        id: weatherTimer
        interval: 1800000 // 30 minutes
        repeat: true
        running: (sharedData && sharedData.menuVisible)
        onTriggered: updateWeather()
        Component.onCompleted: if (sharedData && sharedData.menuVisible) updateWeather()
    }

    Connections {
        target: sharedData
        function onWeatherLocationChanged() {
            updateWeather()
        }
    }



    Timer {
        id: ramTimer
        interval: 1000
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
        interval: 1000
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
        interval: 1000
        repeat: true
        running: (sharedData && sharedData.menuVisible)
        onTriggered: readGpu()
    }
    
    function readGpu() {
        if (!sharedData || !sharedData.runCommand) return

        var intelFreqCmd = '(C=$(cat /sys/class/drm/card1/gt_cur_freq_mhz 2>/dev/null || cat /sys/class/drm/card0/gt_cur_freq_mhz 2>/dev/null); ' +
                           'M=$(cat /sys/class/drm/card1/gt_max_freq_mhz 2>/dev/null || cat /sys/class/drm/card0/gt_max_freq_mhz 2>/dev/null); ' +
                           'if [ -n "$C" ] && [ -n "$M" ] && [ "$M" -gt 0 ]; then echo $((C * 100 / M)); fi)'

        if (gpuBrand === "nvidia") {
            sharedData.runCommand(['sh', '-c', 'nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>/dev/null | head -1 | tr -d " " > /tmp/quickshell_gpu_usage'], readGpuData)
        } else if (gpuBrand === "amd") {
            sharedData.runCommand(['sh', '-c', 'timeout 1 radeontop -l 1 -d - 2>/dev/null | tail -1 | awk \'{print int($2)}\' > /tmp/quickshell_gpu_usage'], readGpuData)
        } else if (gpuBrand === "intel") {
            sharedData.runCommand(['sh', '-c', 'timeout 1 intel_gpu_top -J -s 1 2>/dev/null | grep \'"busy":\' | head -1 | awk -F: \'{print int($2)}\' > /tmp/quickshell_gpu_usage'], readGpuData)
        } else if (gpuBrand === "sysfs") {
            sharedData.runCommand(['sh', '-c', intelFreqCmd + ' > /tmp/quickshell_gpu_usage'], readGpuData)
        } else {
            // First time detection
            var cmd = 'if command -v nvidia-smi >/dev/null 2>&1 && nvidia-smi >/dev/null 2>&1; then echo "nvidia"; ' +
                      'elif command -v radeontop >/dev/null 2>&1; then echo "amd"; ' +
                      'elif command -v intel_gpu_top >/dev/null 2>&1; then echo "intel"; ' +
                      'elif [ -d /sys/class/drm/card0/gt_cur_freq_mhz ] || [ -d /sys/class/drm/card1/gt_cur_freq_mhz ]; then echo "sysfs"; ' +
                      'else echo "none"; fi > /tmp/quickshell_gpu_brand'
            sharedData.runCommand(['sh', '-c', cmd], function() {
                var xhr = new XMLHttpRequest()
                xhr.open("GET", "file:///tmp/quickshell_gpu_brand")
                xhr.onreadystatechange = function() {
                    if (xhr.readyState === XMLHttpRequest.DONE) {
                        gpuBrand = xhr.responseText.trim()
                        readGpu() // Run again with detected brand
                    }
                }
                xhr.send()
            })
        }
    }
    
    function readGpuData() {
        var xhr = new XMLHttpRequest()
        xhr.open("GET", "file:///tmp/quickshell_gpu_usage")
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                var text = (xhr.responseText || "").trim()
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
        running: (sharedData && sharedData.menuVisible) && ((sharedData && sharedData.dashboardTileLeft === "network") || (currentTab === 3))
        onTriggered: updateNetwork()
        Component.onCompleted: if ((sharedData && sharedData.menuVisible) && ((sharedData && sharedData.dashboardTileLeft === "network") || (currentTab === 3))) updateNetwork()
    }
    
    
    // ============ PERFORMANCE TAB FUNCTIONS ============
    function updateDiskUsage() {
        if (sharedData && sharedData.runCommand) sharedData.runCommand(['sh','-c','df -h | grep -E "^/dev" | awk \'{print $6 "|" $2 "|" $3 "|" $5}\' | head -5 > /tmp/quickshell_disk_usage 2>/dev/null || echo > /tmp/quickshell_disk_usage'], readDiskUsage)
    }
    
    function readDiskUsage() {
        var xhr = new XMLHttpRequest()
        xhr.open("GET", "file:///tmp/quickshell_disk_usage")
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                var text = (xhr.responseText || "").trim()
                if (!text) return
                var lines = text.split("\n")
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
        if (sharedData && sharedData.runCommand) sharedData.runCommand(['sh','-c','ps aux --sort=-%cpu 2>/dev/null | tail -n +2 | head -8 | awk \'{print $11 "|" $3 "|" $4}\' > /tmp/quickshell_top_processes 2>/dev/null || echo > /tmp/quickshell_top_processes'], readTopProcesses)
    }
    
    function readTopProcesses() {
        var xhr = new XMLHttpRequest()
        xhr.open("GET", "file:///tmp/quickshell_top_processes")
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                var text = (xhr.responseText || "").trim()
                if (!text) return
                var lines = text.split("\n")
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
        if (sharedData && sharedData.runCommand) {
            // Broader grep for CPU temps: Package, Core, Tctl, Tdie, or just CPU
            // Fallback: Find the maximum temperature in any thermal zone (usually CPU)
            var cmd = '(sensors 2>/dev/null | grep -iE "Package|Core 0|Tctl|Tdie|CPU" | grep -oP "[0-9]+(\\.[0-9]+)?(?=°C)" | head -1 | cut -d. -f1 > /tmp/quickshell_cpu_temp) || (cat /sys/class/thermal/thermal_zone*/temp 2>/dev/null | sort -nr | head -1 | awk \'{print int($1/1000)}\' > /tmp/quickshell_cpu_temp) || echo 0 > /tmp/quickshell_cpu_temp'
            sharedData.runCommand(['sh','-c', cmd], readCpuTemp)
        }
    }
    
    function readCpuTemp() {
        var xhr = new XMLHttpRequest()
        xhr.open("GET", "file:///tmp/quickshell_cpu_temp")
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                var text = (xhr.responseText || "").trim()
                var temp = parseInt(text)
                if (!isNaN(temp)) cpuTempValue = temp
            }
        }
        xhr.send()
    }
    
    function updateGpuTemp() {
        if (sharedData && sharedData.runCommand) {
            // nvidia-smi is best for NVIDIA, sensors handles AMD/Intel. grep for GPU, edge, junction, or k10temp
            var cmd = '(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits 2>/dev/null | head -1 > /tmp/quickshell_gpu_temp) || (sensors 2>/dev/null | grep -iE "gpu|edge|junction|amdgpu" | grep -oP "[0-9]+(\\.[0-9]+)?(?=°C)" | head -1 | cut -d. -f1 > /tmp/quickshell_gpu_temp) || echo 0 > /tmp/quickshell_gpu_temp'
            sharedData.runCommand(['sh','-c', cmd], readGpuTemp)
        }
    }
    
    function readGpuTemp() {
        var xhr = new XMLHttpRequest()
        xhr.open("GET", "file:///tmp/quickshell_gpu_temp")
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                var text = (xhr.responseText || "").trim()
                var temp = parseInt(text)
                if (!isNaN(temp) && temp > 0) {
                    gpuTempValue = temp
                } else if (cpuTempValue > 0) {
                    // Integrated GPU fallback: Use CPU temp if GPU-specific temp is unavailable
                    gpuTempValue = cpuTempValue
                } else {
                    gpuTempValue = 0
                }
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
        // Only start if dashboard is visible or about to be visible
        if (!(sharedData && sharedData.menuVisible)) return
        
        if (sharedData && sharedData.runCommand) sharedData.runCommand(['sh','-c','which cava > /dev/null 2>&1 && echo 1 > /tmp/quickshell_cava_available || echo 0 > /tmp/quickshell_cava_available'], checkCavaAvailable)
    }

    function stopCava() {
        if (cavaRunning) {
            cavaRunning = false
            if (sharedData && sharedData.runCommand) {
                sharedData.runCommand(['sh', '-c', 'pkill -f "cava -p" || true'])
            }
        }
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
    // Timer do sprawdzania czy cava działa - only when visible
    Timer {
        id: cavaCheckTimer
        interval: 5000  // Co 5 sekund
        repeat: true
        running: (sharedData && sharedData.menuVisible)
        onTriggered: {
            if (cavaRunning) {
                // Check if process is actually running
            } else {
                startCava()
            }
        }
    }

    Connections {
        target: sharedData
        enabled: !!sharedData
        function onMenuVisibleChanged() {
            if (sharedData.menuVisible) {
                startCava()
            } else {
                stopCava()
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
        if (sharedData && sharedData.runCommand) sharedData.runCommand(['sh', '-c', 'loginctl terminate-session $(loginctl list-sessions | grep $(whoami) | awk \'{print $1}\' | head -1) 2>/dev/null || pkill -KILL -u $(whoami)'])
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
    }

    // ============ SYSTEM INFO FUNCTIONS ============
    function updateSystemInfo() {
        if (sharedData && sharedData.runCommand) {
            sharedData.runCommand(['hostname'], function(out) { if (out) hostname = out.trim() })
            sharedData.runCommand(['sh', '-c', 'cat /etc/os-release | grep PRETTY_NAME | cut -d\'"\' -f2'], function(out) { if (out) osPrettyName = out.trim() })
            sharedData.runCommand(['uname', '-r'], function(out) { if (out) kernelVersion = out.trim() })
            updateUptime()
        }
    }
}



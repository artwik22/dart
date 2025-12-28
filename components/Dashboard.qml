import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

PanelWindow {
    id: dashboardRoot

    anchors { top: true }
    implicitWidth: 840  // 1200 * 0.7
    implicitHeight: 420  // 600 * 0.7
    
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qsdashboard"
    WlrLayershell.keyboardFocus: (sharedData && sharedData.menuVisible) ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    exclusiveZone: 0

    property int currentTab: 0
    property var sharedData: null
    
    visible: true
    color: "transparent"
    
    property int slideOffset: (sharedData && sharedData.menuVisible) ? 0 : -implicitHeight
    
    margins {
        top: slideOffset
        left: 0
        right: 0
    }
    
    Behavior on slideOffset {
        NumberAnimation { 
            duration: 400
            easing.type: Easing.OutQuart
        }
    }

    Item {
        id: dashboardContainer
        anchors.fill: parent
        
        property bool isShowing: dashboardRoot.visible
        
        opacity: isShowing ? 1.0 : 0.0
        
        Behavior on opacity {
            NumberAnimation { 
                duration: 400
                easing.type: Easing.OutQuart
            }
        }
        
        enabled: opacity > 0.1
        focus: (sharedData && sharedData.menuVisible)
        
        Keys.onPressed: function(event) {
            if (event.key === Qt.Key_Escape) {
                if (sharedData) {
                    sharedData.menuVisible = false
                }
                event.accepted = true
            }
        }
        
        // Main dashboard background
        Rectangle {
            id: dashboardBackground
            anchors.fill: parent
            radius: 0
            color: (sharedData && sharedData.colorBackground) ? sharedData.colorBackground : "#0a0a0a"
        }

        Column {
            id: dashboardColumn
            anchors.fill: parent
            spacing: 0

            // ============ TOP NAVIGATION BAR ============
            Rectangle {
                id: navBar
                width: parent.width
                height: 45
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
                            { icon: "󰎆", label: "Media" },
                            { icon: "󰻠", label: "Performance" }
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
                                color: tabRect.isActive ? 
                                    ((sharedData && sharedData.colorAccent) ? Qt.lighter(sharedData.colorAccent, 1.1) : "#5ab0ff") : 
                                    (tabRect.isHovered ? 
                                        ((sharedData && sharedData.colorSecondary) ? sharedData.colorSecondary : "#252525") : 
                                        "transparent")
                                radius: 0
                                
                                Behavior on color {
                                    ColorAnimation { 
                                        duration: 200
                                        easing.type: Easing.OutQuart
                                    }
                                }
                            }
                            
                            Row {
                                anchors.centerIn: parent
                                spacing: 10
                                
                                Text {
                                    text: modelData.icon
                                    font.pixelSize: 18
                                    color: tabRect.isActive ? 
                                        ((sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff") : 
                                        (tabRect.isHovered ? 
                                            ((sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff") : 
                                            ((sharedData && sharedData.colorText) ? Qt.lighter(sharedData.colorText, 1.3) : "#888888"))
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
                                    font.pixelSize: 14
                                    font.family: "JetBrains Mono"
                                    font.weight: tabRect.isActive ? Font.Bold : Font.Normal
                                    color: tabRect.isActive ? 
                                        ((sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff") : 
                                        (tabRect.isHovered ? 
                                            ((sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff") : 
                                            ((sharedData && sharedData.colorText) ? Qt.lighter(sharedData.colorText, 1.3) : "#888888"))
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
                            
                            // Active indicator line at bottom
                            Rectangle {
                                anchors.bottom: parent.bottom
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: parent.width * 0.6
                                height: 3
                                color: (sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff"
                                opacity: tabRect.isActive ? 1.0 : 0.0
                                
                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: 250
                                        easing.type: Easing.OutQuart
                                    }
                                }
                                
                                Behavior on width {
                                    NumberAnimation {
                                        duration: 250
                                        easing.type: Easing.OutQuart
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
                    
                    GridLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        columns: 4
                        rows: 2
                        columnSpacing: 12
                        rowSpacing: 12
                        
                        // Weather Card (Top Left)
                        Rectangle {
                            Layout.column: 0
                            Layout.row: 0
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.minimumWidth: 140
                            Layout.minimumHeight: 105
                            radius: 0
                            color: (sharedData && sharedData.colorPrimary) ? sharedData.colorPrimary : "#1a1a1a"
                            
                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 8
                                
                                Text {
                                    text: "☀️"
                                    font.pixelSize: 52
                                    color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff"
                                    Layout.alignment: Qt.AlignVCenter
                                    Layout.preferredWidth: 60
                                }
                                
                                Column {
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignVCenter
                                    spacing: 4
                                    
                                    Text {
                                        text: weatherTemp
                                        font.pixelSize: 28
                                        font.weight: Font.Bold
                                        font.family: "JetBrains Mono"
                                        color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff"
                                    }
                                    
                                    Text {
                                        text: weatherCondition
                                        font.pixelSize: 12
                                        font.family: "JetBrains Mono"
                                        color: (sharedData && sharedData.colorText) ? Qt.lighter(sharedData.colorText, 1.3) : "#aaaaaa"
                                        elide: Text.ElideRight
                                    }
                                }
                            }
                        }
                        
                        // System Info Card (Top Middle)
                        Rectangle {
                            Layout.column: 1
                            Layout.row: 0
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.minimumWidth: 140
                            Layout.minimumHeight: 105
                            radius: 0
                            color: (sharedData && sharedData.colorPrimary) ? sharedData.colorPrimary : "#1a1a1a"
                            
                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 12
                                
                                Text {
                                    text: "󰣇"
                                    font.pixelSize: 40
                                    font.family: "JetBrains Mono Nerd Font"
                                    color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff"
                                }
                                
                                Column {
                                    Layout.fillWidth: true
                                    spacing: 4
                                    
                                    Text {
                                        text: "A: Arch Linux"
                                        font.pixelSize: 14
                                        font.family: "JetBrains Mono"
                                        color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff"
                                    }
                                    
                                    Text {
                                        text: "󰨳: Hyprland"
                                        font.pixelSize: 14
                                        font.family: "JetBrains Mono"
                                        color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff"
                                    }
                                    
                                    Text {
                                        id: uptimeText
                                        text: "󰥔: up 1 hour, 23 minutes"
                                        font.pixelSize: 14
                                        font.family: "JetBrains Mono"
                                        color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff"
                                    }
                                }
                            }
                        }
                        
                        // Date/Calendar Card (Left/Center, spans 2 rows)
                        Rectangle {
                            Layout.column: 0
                            Layout.row: 1
                            Layout.columnSpan: 2
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.minimumHeight: 210
                            radius: 0
                            color: (sharedData && sharedData.colorPrimary) ? sharedData.colorPrimary : "#1a1a1a"
                            
                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 20
                                spacing: 20
                                
                                // Large Date Display
                                Column {
                                    Layout.preferredWidth: 100
                                    Layout.alignment: Qt.AlignVCenter
                                    spacing: 2
                                    
                                    Item {
                                        width: 1
                                        height: 1
                                    }
                                    
                                    Text {
                                        id: dayNumber
                                        text: "21"
                                        font.pixelSize: 68
                                        font.weight: Font.Bold
                                        font.family: "JetBrains Mono"
                                        color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff"
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }
                                    
                                    Text {
                                        id: monthNumber
                                        text: "06"
                                        font.pixelSize: 68
                                        font.weight: Font.Bold
                                        font.family: "JetBrains Mono"
                                        color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff"
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }
                                    
                                    Item {
                                        width: 1
                                        height: 1
                                    }
                                }
                                
                                // Calendar Grid
                                Column {
                                    Layout.fillWidth: true
                                    spacing: 8
                                    anchors.verticalCenter: parent.verticalCenter
                                    
                                    // Day headers
                                    Row {
                                        spacing: 8
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        
                                        Repeater {
                                            model: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
                                            Text {
                                                text: modelData
                                                font.pixelSize: 11
                                                font.family: "JetBrains Mono"
                                                color: (sharedData && sharedData.colorText) ? Qt.lighter(sharedData.colorText, 1.3) : "#aaaaaa"
                                                width: 24
                                                horizontalAlignment: Text.AlignHCenter
                                            }
                                        }
                                    }
                                    
                                    // Calendar grid
                                    Grid {
                                        columns: 7
                                        spacing: 6
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        
                                        Repeater {
                                            model: calendarDays
                                            
                                            Rectangle {
                                                width: 24
                                                height: 24
                                                radius: 0
                                                color: modelData.isToday ? 
                                                    ((sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff") : 
                                                    "transparent"
                                                
                                                Text {
                                                    text: modelData.day
                                                    font.pixelSize: 12
                                                    font.family: "JetBrains Mono"
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
                        
                        // Resource Usage Card (Right of Calendar, spans 2 rows)
                        Rectangle {
                            Layout.column: 2
                            Layout.row: 0
                            Layout.rowSpan: 2
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.minimumWidth: 120
                            radius: 0
                            color: (sharedData && sharedData.colorPrimary) ? sharedData.colorPrimary : "#1a1a1a"
                            
                            Row {
                                anchors.fill: parent
                                anchors.margins: 15
                                spacing: 12
                                
                                Repeater {
                                    model: [
                                        { label: "CPU", value: cpuUsageValue, icon: "󰻠" },
                                        { label: "RAM", value: ramUsageValue, icon: "󰍛" },
                                        { label: "GPU", value: gpuUsageValue, icon: "󰾲" }
                                    ]
                                    
                                    Column {
                                        width: (parent.width - 24) / 3
                                        height: parent.height
                                        spacing: 8
                                        
                                        Text {
                                            text: modelData.icon
                                            font.pixelSize: 20
                                            color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff"
                                            anchors.horizontalCenter: parent.horizontalCenter
                                        }
                                        
                                        Text {
                                            text: modelData.label
                                            font.pixelSize: 13
                                            font.family: "JetBrains Mono"
                                            color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff"
                                            anchors.horizontalCenter: parent.horizontalCenter
                                        }
                                        
                                        Text {
                                            text: modelData.value + "%"
                                            font.pixelSize: 16
                                            font.family: "JetBrains Mono"
                                            font.weight: Font.Bold
                                            color: (sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff"
                                            anchors.horizontalCenter: parent.horizontalCenter
                                        }
                                        
                                        Item {
                                            width: parent.width
                                            height: parent.height - 80
                                            
                                            Rectangle {
                                                anchors.bottom: parent.bottom
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                width: parent.width
                                                height: parent.height
                                                radius: 0
                                                color: (sharedData && sharedData.colorSecondary) ? sharedData.colorSecondary : "#141414"
                                                
                                                Rectangle {
                                                    anchors.bottom: parent.bottom
                                                    anchors.horizontalCenter: parent.horizontalCenter
                                                    width: parent.width
                                                    height: parent.height * (modelData.value / 100)
                                                    radius: 0
                                                    color: (sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff"
                                                    
                                                    Behavior on height {
                                                        NumberAnimation {
                                                            duration: 600
                                                            easing.type: Easing.OutCubic
                                                        }
                                                    }
                                                    
                                                    Behavior on color {
                                                        ColorAnimation {
                                                            duration: 400
                                                            easing.type: Easing.InOutQuad
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Media Player Card (Right)
                        Rectangle {
                            Layout.column: 3
                            Layout.row: 0
                            Layout.rowSpan: 2
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.minimumWidth: 175
                            radius: 0
                            color: (sharedData && sharedData.colorPrimary) ? sharedData.colorPrimary : "#1a1a1a"
                            
                            Column {
                                anchors.fill: parent
                                anchors.margins: 16
                                spacing: 16
                                
                                // Album Art
                                Rectangle {
                                    width: 180
                                    height: 180
                                    radius: 0
                                    color: (sharedData && sharedData.colorSecondary) ? sharedData.colorSecondary : "#141414"
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    
                                    Image {
                                        id: mediaAlbumArt
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
                                        font.pixelSize: 60
                                        anchors.centerIn: parent
                                        visible: !mpArt
                                        color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff"
                                    }
                                }
                                
                                // Track Info
                                Column {
                                    width: parent.width
                                    spacing: 6
                                    
                                    Text {
                                        id: mediaTitle
                                        text: mpTitle ? mpTitle : "Nothing playing"
                                        font.pixelSize: 18
                                        font.family: "JetBrains Mono"
                                        font.weight: Font.Bold
                                        color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff"
                                        elide: Text.ElideRight
                                        width: parent.width
                                        horizontalAlignment: Text.AlignHCenter
                                    }
                                    
                                    Text {
                                        id: mediaArtist
                                        text: mpArtist ? mpArtist : "—"
                                        font.pixelSize: 16
                                        font.family: "JetBrains Mono"
                                        color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff"
                                        elide: Text.ElideRight
                                        width: parent.width
                                        horizontalAlignment: Text.AlignHCenter
                                    }
                                    
                                    Text {
                                        id: mediaAlbum
                                        text: mpAlbum ? mpAlbum : "—"
                                        font.pixelSize: 15
                                        font.family: "JetBrains Mono"
                                        color: (sharedData && sharedData.colorText) ? Qt.lighter(sharedData.colorText, 1.3) : "#aaaaaa"
                                        elide: Text.ElideRight
                                        width: parent.width
                                        horizontalAlignment: Text.AlignHCenter
                                    }
                                }
                                
                                // Controls
                                Row {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    spacing: 12
                                    
                                    Rectangle {
                                        id: prevButton
                                        width: 40
                                        height: 40
                                        radius: 0
                                        color: prevArea.containsMouse ? 
                                            ((sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff") : 
                                            ((sharedData && sharedData.colorSecondary) ? sharedData.colorSecondary : "#161616")
                                        
                                        property real buttonScale: prevArea.pressed ? 0.9 : (prevArea.containsMouse ? 1.1 : 1.0)
                                        
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
                                            text: "󰒮"
                                            font.pixelSize: 22
                                            anchors.centerIn: parent
                                            color: prevArea.containsMouse ? 
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
                                            id: prevArea
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            hoverEnabled: true
                                            onClicked: {
                                                playerPrev()
                                            }
                                        }
                                    }
                                    
                                    Rectangle {
                                        id: playButton
                                        width: 50
                                        height: 40
                                        radius: 0
                                        color: playArea.containsMouse ? 
                                            ((sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff") : 
                                            ((sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff")
                                        
                                        property real buttonScale: playArea.pressed ? 0.9 : (playArea.containsMouse ? 1.1 : 1.0)
                                        
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
                                            text: mpPlaying ? "󰏤" : "󰐊"
                                            font.pixelSize: 24
                                            anchors.centerIn: parent
                                            color: playArea.containsMouse ? 
                                                ((sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff") : 
                                                ((sharedData && sharedData.colorBackground) ? sharedData.colorBackground : "#0a0a0a")
                                            
                                            Behavior on color {
                                                ColorAnimation {
                                                    duration: 200
                                                    easing.type: Easing.OutQuart
                                                }
                                            }
                                            
                                            rotation: playArea.pressed ? 5 : 0
                                            
                                            Behavior on rotation {
                                                NumberAnimation {
                                                    duration: 150
                                                    easing.type: Easing.OutQuart
                                                }
                                            }
                                        }
                                        
                                        MouseArea {
                                            id: playArea
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            hoverEnabled: true
                                            onClicked: {
                                                playerPlayPause()
                                            }
                                        }
                                    }
                                    
                                    Rectangle {
                                        id: nextButton
                                        width: 40
                                        height: 40
                                        radius: 0
                                        color: nextArea.containsMouse ? 
                                            ((sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff") : 
                                            ((sharedData && sharedData.colorSecondary) ? sharedData.colorSecondary : "#161616")
                                        
                                        property real buttonScale: nextArea.pressed ? 0.9 : (nextArea.containsMouse ? 1.1 : 1.0)
                                        
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
                                            text: "󰒭"
                                            font.pixelSize: 22
                                            anchors.centerIn: parent
                                            color: nextArea.containsMouse ? 
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
                                            id: nextArea
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            hoverEnabled: true
                                            onClicked: {
                                                playerNext()
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // ============ TAB 1: MEDIA ============
                Item {
                    id: mediaTab
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
                    
                    Item {
                        anchors.fill: parent
                        
                        // Music Visualizer - wyciemnione cava (poziome) - w tle
                        Row {
                            id: mediaVisualizerRow
                            spacing: 1
                            anchors.fill: parent
                            anchors.margins: 20
                            opacity: 0.4  // Wyciemnione
                            z: 0  // W tle
                            
                            Repeater {
                                id: mediaVisualizerBarsRepeater
                                model: 72  // 72 paski poziomo - więcej pasków = cieńsze
                                
                                Rectangle {
                                    id: mediaVisualizerBar
                                    width: Math.max(0.5, (parent.width - (71 * parent.spacing)) / 72)  // Bardzo cienkie paski
                                    height: Math.max(2, mediaVisualizerBarValue)
                                    anchors.verticalCenter: parent.verticalCenter
                                    color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff"
                                    radius: 0
                                    visible: true
                                    
                                    property real mediaVisualizerBarValue: 5
                                    
                                    Behavior on height {
                                        NumberAnimation {
                                            duration: 80
                                            easing.type: Easing.OutQuad
                                        }
                                    }
                                    
                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 100
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Media Player - wyśrodkowany na wierzchu, przesunięty w prawo
                        RowLayout {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.horizontalCenterOffset: parent.width * 0.15  // Przesunięcie w prawo
                            anchors.verticalCenter: parent.verticalCenter
                            width: Math.min(600, parent.width - 40)
                            height: 180
                            spacing: 20
                            z: 1  // Na wierzchu
                            
                            // Album Art - po lewej
                            Rectangle {
                                Layout.preferredWidth: 180
                                Layout.preferredHeight: 180
                                radius: 0
                                color: (sharedData && sharedData.colorSecondary) ? sharedData.colorSecondary : "#141414"
                                
                                Image {
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
                                    font.pixelSize: 60
                                    anchors.centerIn: parent
                                    visible: !mpArt
                                    color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff"
                                }
                            }
                            
                            // Track Info i Controls - po prawej
                            Column {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                spacing: 12
                                
                                // Track Info
                                Column {
                                    width: parent.width
                                    spacing: 6
                                    
                                    Text {
                                        text: mpTitle ? mpTitle : "Nothing playing"
                                        font.pixelSize: 18
                                        font.family: "JetBrains Mono"
                                        font.weight: Font.Bold
                                        color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff"
                                        elide: Text.ElideRight
                                        width: parent.width
                                    }
                                    
                                    Text {
                                        text: mpArtist ? mpArtist : "—"
                                        font.pixelSize: 16
                                        font.family: "JetBrains Mono"
                                        color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff"
                                        elide: Text.ElideRight
                                        width: parent.width
                                    }
                                    
                                    Text {
                                        text: mpAlbum ? mpAlbum : "—"
                                        font.pixelSize: 15
                                        font.family: "JetBrains Mono"
                                        color: (sharedData && sharedData.colorText) ? Qt.lighter(sharedData.colorText, 1.3) : "#aaaaaa"
                                        elide: Text.ElideRight
                                        width: parent.width
                                    }
                                }
                                
                                // Controls
                                Row {
                                    spacing: 12
                                    
                                    Rectangle {
                                        width: 40
                                        height: 40
                                        radius: 0
                                        color: prevAreaMedia.containsMouse ? 
                                            ((sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff") : 
                                            ((sharedData && sharedData.colorSecondary) ? sharedData.colorSecondary : "#161616")
                                        
                                        property real buttonScale: prevAreaMedia.pressed ? 0.9 : (prevAreaMedia.containsMouse ? 1.1 : 1.0)
                                        
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
                                            text: "󰒮"
                                            font.pixelSize: 22
                                            anchors.centerIn: parent
                                            color: prevAreaMedia.containsMouse ? 
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
                                            id: prevAreaMedia
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            hoverEnabled: true
                                            onClicked: {
                                                playerPrev()
                                            }
                                        }
                                    }
                                    
                                    Rectangle {
                                        width: 50
                                        height: 40
                                        radius: 0
                                        color: playAreaMedia.containsMouse ? 
                                            ((sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff") : 
                                            ((sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff")
                                        
                                        property real buttonScale: playAreaMedia.pressed ? 0.9 : (playAreaMedia.containsMouse ? 1.1 : 1.0)
                                        
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
                                            text: mpPlaying ? "󰏤" : "󰐊"
                                            font.pixelSize: 24
                                            anchors.centerIn: parent
                                            color: playAreaMedia.containsMouse ? 
                                                ((sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff") : 
                                                ((sharedData && sharedData.colorBackground) ? sharedData.colorBackground : "#0a0a0a")
                                            
                                            Behavior on color {
                                                ColorAnimation {
                                                    duration: 200
                                                    easing.type: Easing.OutQuart
                                                }
                                            }
                                            
                                            rotation: playAreaMedia.pressed ? 5 : 0
                                            
                                            Behavior on rotation {
                                                NumberAnimation {
                                                    duration: 150
                                                    easing.type: Easing.OutQuart
                                                }
                                            }
                                        }
                                        
                                        MouseArea {
                                            id: playAreaMedia
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            hoverEnabled: true
                                            onClicked: {
                                                playerPlayPause()
                                            }
                                        }
                                    }
                                    
                                    Rectangle {
                                        width: 40
                                        height: 40
                                        radius: 0
                                        color: nextAreaMedia.containsMouse ? 
                                            ((sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff") : 
                                            ((sharedData && sharedData.colorSecondary) ? sharedData.colorSecondary : "#161616")
                                        
                                        property real buttonScale: nextAreaMedia.pressed ? 0.9 : (nextAreaMedia.containsMouse ? 1.1 : 1.0)
                                        
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
                                            text: "󰒭"
                                            font.pixelSize: 22
                                            anchors.centerIn: parent
                                            color: nextAreaMedia.containsMouse ? 
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
                                            id: nextAreaMedia
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            hoverEnabled: true
                                            onClicked: {
                                                playerNext()
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // ============ TAB 2: PERFORMANCE ============
                Item {
                    id: performanceTab
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
                    
                    // Performance tab content - GridLayout jak w Dashboard
                    GridLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        columns: 2
                        rows: 3
                        columnSpacing: 12
                        rowSpacing: 12
                        
                        // CPU Card
                        Rectangle {
                            Layout.column: 0
                            Layout.row: 0
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.minimumHeight: 140
                            radius: 0
                            color: (sharedData && sharedData.colorPrimary) ? sharedData.colorPrimary : "#1a1a1a"
                            
                            Column {
                                anchors.fill: parent
                                anchors.margins: 16
                                spacing: 12
                                
                                Row {
                                    width: parent.width
                                    spacing: 10
                                    
                                    Text {
                                        text: "󰻠"
                                        font.pixelSize: 24
                                        color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff"
                                    }
                                    
                                    Column {
                                        spacing: 4
                                        
                                        Text {
                                            text: "CPU"
                                            font.pixelSize: 16
                                            font.family: "JetBrains Mono"
                                            font.weight: Font.Bold
                                            color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff"
                                        }
                                        
                                        Text {
                                            text: cpuUsageValue + "%"
                                            font.pixelSize: 28
                                            font.family: "JetBrains Mono"
                                            font.weight: Font.Bold
                                            color: (sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff"
                                        }
                                    }
                                }
                                
                                Rectangle {
                                    width: parent.width
                                    height: 12
                                    radius: 0
                                    color: (sharedData && sharedData.colorSecondary) ? sharedData.colorSecondary : "#141414"
                                    
                                    Rectangle {
                                        anchors.left: parent.left
                                        width: parent.width * (cpuUsageValue / 100)
                                        height: parent.height
                                        radius: 0
                                        color: (sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff"
                                        
                                        Behavior on width {
                                            NumberAnimation {
                                                duration: 400
                                                easing.type: Easing.OutCubic
                                            }
                                        }
                                    }
                                }
                                
                                Text {
                                    text: "Temperature: " + cpuTempValue + "°C"
                                    font.pixelSize: 12
                                    font.family: "JetBrains Mono"
                                    color: (sharedData && sharedData.colorText) ? Qt.lighter(sharedData.colorText, 1.3) : "#aaaaaa"
                                }
                            }
                        }
                        
                        // RAM Card
                        Rectangle {
                            Layout.column: 1
                            Layout.row: 0
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.minimumHeight: 140
                            radius: 0
                            color: (sharedData && sharedData.colorPrimary) ? sharedData.colorPrimary : "#1a1a1a"
                            
                            Column {
                                anchors.fill: parent
                                anchors.margins: 16
                                spacing: 12
                                
                                Row {
                                    width: parent.width
                                    spacing: 10
                                    
                                    Text {
                                        text: "󰍛"
                                        font.pixelSize: 24
                                        color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff"
                                    }
                                    
                                    Column {
                                        spacing: 4
                                        
                                        Text {
                                            text: "RAM"
                                            font.pixelSize: 16
                                            font.family: "JetBrains Mono"
                                            font.weight: Font.Bold
                                            color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff"
                                        }
                                        
                                        Text {
                                            text: ramUsageValue + "%"
                                            font.pixelSize: 28
                                            font.family: "JetBrains Mono"
                                            font.weight: Font.Bold
                                            color: (sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff"
                                        }
                                    }
                                }
                                
                                Rectangle {
                                    width: parent.width
                                    height: 12
                                    radius: 0
                                    color: (sharedData && sharedData.colorSecondary) ? sharedData.colorSecondary : "#141414"
                                    
                                    Rectangle {
                                        anchors.left: parent.left
                                        width: parent.width * (ramUsageValue / 100)
                                        height: parent.height
                                        radius: 0
                                        color: (sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff"
                                        
                                        Behavior on width {
                                            NumberAnimation {
                                                duration: 400
                                                easing.type: Easing.OutCubic
                                            }
                                        }
                                    }
                                }
                                
                                Text {
                                    text: "Available: " + Math.round((100 - ramUsageValue) / 100 * ramTotalGB) + "GB / " + ramTotalGB + "GB"
                                    font.pixelSize: 12
                                    font.family: "JetBrains Mono"
                                    color: (sharedData && sharedData.colorText) ? Qt.lighter(sharedData.colorText, 1.3) : "#aaaaaa"
                                }
                            }
                        }
                        
                        // GPU Card
                        Rectangle {
                            Layout.column: 0
                            Layout.row: 1
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.minimumHeight: 140
                            radius: 0
                            color: (sharedData && sharedData.colorPrimary) ? sharedData.colorPrimary : "#1a1a1a"
                            
                            Column {
                                anchors.fill: parent
                                anchors.margins: 16
                                spacing: 12
                                
                                Row {
                                    width: parent.width
                                    spacing: 10
                                    
                                    Text {
                                        text: "󰾲"
                                        font.pixelSize: 24
                                        color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff"
                                    }
                                    
                                    Column {
                                        spacing: 4
                                        
                                        Text {
                                            text: "GPU"
                                            font.pixelSize: 16
                                            font.family: "JetBrains Mono"
                                            font.weight: Font.Bold
                                            color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff"
                                        }
                                        
                                        Text {
                                            text: gpuUsageValue + "%"
                                            font.pixelSize: 28
                                            font.family: "JetBrains Mono"
                                            font.weight: Font.Bold
                                            color: (sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff"
                                        }
                                    }
                                }
                                
                                Rectangle {
                                    width: parent.width
                                    height: 12
                                    radius: 0
                                    color: (sharedData && sharedData.colorSecondary) ? sharedData.colorSecondary : "#141414"
                                    
                                    Rectangle {
                                        anchors.left: parent.left
                                        width: parent.width * (gpuUsageValue / 100)
                                        height: parent.height
                                        radius: 0
                                        color: (sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff"
                                        
                                        Behavior on width {
                                            NumberAnimation {
                                                duration: 400
                                                easing.type: Easing.OutCubic
                                            }
                                        }
                                    }
                                }
                                
                                Text {
                                    text: "Temperature: " + gpuTempValue + "°C"
                                    font.pixelSize: 12
                                    font.family: "JetBrains Mono"
                                    color: (sharedData && sharedData.colorText) ? Qt.lighter(sharedData.colorText, 1.3) : "#aaaaaa"
                                }
                            }
                        }
                        
                        // Top Processes Card
                        Rectangle {
                            Layout.column: 1
                            Layout.row: 1
                            Layout.rowSpan: 2
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 0
                            color: (sharedData && sharedData.colorPrimary) ? sharedData.colorPrimary : "#1a1a1a"
                            
                            Column {
                                anchors.fill: parent
                                anchors.margins: 16
                                spacing: 12
                                
                                Text {
                                    text: "󰨳 Top Processes"
                                    font.pixelSize: 16
                                    font.family: "JetBrains Mono"
                                    font.weight: Font.Bold
                                    color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff"
                                }
                                
                                Column {
                                    width: parent.width
                                    spacing: 8
                                    
                                    Repeater {
                                        model: topProcessesModel.length > 0 ? topProcessesModel.slice(0, 8) : []
                                        
                                        Row {
                                            width: parent.width
                                            spacing: 10
                                            
                                            Text {
                                                text: (index + 1) + "."
                                                font.pixelSize: 12
                                                font.family: "JetBrains Mono"
                                                color: (sharedData && sharedData.colorText) ? Qt.lighter(sharedData.colorText, 1.3) : "#aaaaaa"
                                                width: 25
                                            }
                                            
                                            Text {
                                                text: modelData.name.length > 20 ? modelData.name.substring(0, 20) + "..." : modelData.name
                                                font.pixelSize: 12
                                                font.family: "JetBrains Mono"
                                                color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff"
                                                width: parent.width - 120
                                            }
                                            
                                            Text {
                                                text: modelData.cpu + "%"
                                                font.pixelSize: 12
                                                font.family: "JetBrains Mono"
                                                font.weight: Font.Bold
                                                color: (sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff"
                                                width: 45
                                            }
                                            
                                            Text {
                                                text: modelData.mem + "%"
                                                font.pixelSize: 12
                                                font.family: "JetBrains Mono"
                                                color: (sharedData && sharedData.colorText) ? Qt.lighter(sharedData.colorText, 1.3) : "#aaaaaa"
                                                width: 45
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Disk Usage Card
                        Rectangle {
                            Layout.column: 0
                            Layout.row: 2
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 0
                            color: (sharedData && sharedData.colorPrimary) ? sharedData.colorPrimary : "#1a1a1a"
                            
                            Column {
                                anchors.fill: parent
                                anchors.margins: 16
                                spacing: 12
                                
                                Text {
                                    text: "󰋼 Disk Usage"
                                    font.pixelSize: 16
                                    font.family: "JetBrains Mono"
                                    font.weight: Font.Bold
                                    color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff"
                                }
                                
                                Column {
                                    width: parent.width
                                    spacing: 10
                                    
                                    Repeater {
                                        model: diskUsageModel.length > 0 ? diskUsageModel.slice(0, 4) : []
                                        
                                        Column {
                                            width: parent.width
                                            spacing: 6
                                            
                                            Row {
                                                width: parent.width
                                                spacing: 10
                                                
                                                Text {
                                                    text: modelData.mount
                                                    font.pixelSize: 12
                                                    font.family: "JetBrains Mono"
                                                    font.weight: Font.Bold
                                                    color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff"
                                                    width: 60
                                                }
                                                
                                                Text {
                                                    text: modelData.usage + "%"
                                                    font.pixelSize: 12
                                                    font.family: "JetBrains Mono"
                                                    font.weight: Font.Bold
                                                    color: (sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff"
                                                    width: 45
                                                }
                                                
                                                Item { width: parent.width - 120; height: 1 }
                                                
                                                Text {
                                                    text: modelData.used + " / " + modelData.total
                                                    font.pixelSize: 11
                                                    font.family: "JetBrains Mono"
                                                    color: (sharedData && sharedData.colorText) ? Qt.lighter(sharedData.colorText, 1.3) : "#aaaaaa"
                                                }
                                            }
                                            
                                            Rectangle {
                                                width: parent.width
                                                height: 6
                                                radius: 0
                                                color: (sharedData && sharedData.colorSecondary) ? sharedData.colorSecondary : "#141414"
                                                
                                                Rectangle {
                                                    anchors.left: parent.left
                                                    width: parent.width * (modelData.usage / 100)
                                                    height: parent.height
                                                    radius: 0
                                                    color: (sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff"
                                                    
                                                    Behavior on width {
                                                        NumberAnimation {
                                                            duration: 400
                                                            easing.type: Easing.OutCubic
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
        }
    }

    // ============ PROPERTIES ============
    property int ramUsageValue: 0
    property int ramTotalGB: 16  // Will be calculated
    property int cpuUsageValue: 0
    property int gpuUsageValue: 0
    property int cpuTempValue: 0
    property int gpuTempValue: 0
    property string mpTitle: ""
    property string mpArtist: ""
    property string mpAlbum: ""
    property string mpArt: ""
    property bool mpPlaying: false
    property real mpPosition: 0
    property int mpLength: 0
    
    // Calendar days model
    property var calendarDays: []
    
    // Weather properties
    property string weatherTemp: "15°C"
    property string weatherCondition: "Clear"
    
    // Performance tab models
    property var diskUsageModel: []
    property var topProcessesModel: []
    
    // Cava visualizer properties
    property var cavaValues: []
    property bool cavaRunning: false
    property string projectPath: ""
    
    // ============ FUNCTIONS ============
    function updateWeather() {
        // Simple weather update - can be extended with API integration
        // For now, uses a simple approach that can be customized
        // Example: curl -s "wttr.in?format=%t+%C" or use a weather service
        Qt.createQmlObject("import Quickshell.Io; import QtQuick; Process { command: ['sh','-c','curl -s \"wttr.in?format=%t+%C\" 2>/dev/null | head -1 > /tmp/quickshell_weather || echo \"15°C Clear\" > /tmp/quickshell_weather']; running: true }", dashboardRoot)
        Qt.createQmlObject("import QtQuick; Timer { interval: 500; running: true; repeat: false; onTriggered: dashboardRoot.readWeather() }", dashboardRoot)
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
        var now = new Date()
        dayNumber.text = now.getDate().toString()
        monthNumber.text = (now.getMonth() + 1 < 10 ? "0" : "") + (now.getMonth() + 1).toString()
        
        // dayName was removed, so we don't update it
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
                    uptimeText.text = "󰥔: " + uptimeStr
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
        Qt.createQmlObject('import Quickshell.Io; import QtQuick; Process { command: ["sh", "-c", "playerctl metadata --format \'{{artist}}\\n{{title}}\\n{{album}}\\n{{mpris:artUrl}}\\n{{mpris:length}}\\n{{status}}\' > /tmp/quickshell_player_info 2>/tmp/quickshell_player_err || echo > /tmp/quickshell_player_info"]; running: true }', dashboardRoot)
        Qt.createQmlObject("import QtQuick; Timer { interval: 200; running: true; repeat: false; onTriggered: dashboardRoot.readPlayerMetadata() }", dashboardRoot)
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
                var lines = txt.split("\n")
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
        Qt.createQmlObject('import Quickshell.Io; import QtQuick; Process { command: ["sh", "-c", "playerctl position > /tmp/quickshell_player_pos 2>/dev/null || echo 0 > /tmp/quickshell_player_pos"]; running: true }', dashboardRoot)
        Qt.createQmlObject("import QtQuick; Timer { interval: 150; running: true; repeat: false; onTriggered: dashboardRoot.readPlayerPosition() }", dashboardRoot)
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
        Qt.createQmlObject('import Quickshell.Io; import QtQuick; Process { command: ["playerctl", "play-pause"]; running: true }', dashboardRoot)
        Qt.createQmlObject("import QtQuick; Timer { interval: 250; running: true; repeat: false; onTriggered: dashboardRoot.updatePlayerMetadata() }", dashboardRoot)
        Qt.createQmlObject("import QtQuick; Timer { interval: 400; running: true; repeat: false; onTriggered: dashboardRoot.updatePlayerPosition() }", dashboardRoot)
    }

    function playerNext() {
        Qt.createQmlObject('import Quickshell.Io; import QtQuick; Process { command: ["playerctl", "next"]; running: true }', dashboardRoot)
        Qt.createQmlObject("import QtQuick; Timer { interval: 300; running: true; repeat: false; onTriggered: dashboardRoot.updatePlayerMetadata() }", dashboardRoot)
    }

    function playerPrev() {
        Qt.createQmlObject('import Quickshell.Io; import QtQuick; Process { command: ["playerctl", "previous"]; running: true }', dashboardRoot)
        Qt.createQmlObject("import QtQuick; Timer { interval: 300; running: true; repeat: false; onTriggered: dashboardRoot.updatePlayerMetadata() }", dashboardRoot)
    }

    // ============ TIMERS ============
    Timer {
        id: dateTimer
        interval: 1000
        repeat: true
        running: true
        onTriggered: updateDate()
        Component.onCompleted: updateDate()
    }
    
    Timer {
        id: calendarTimer
        interval: 60000
        repeat: true
        running: true
        onTriggered: updateCalendar()
        Component.onCompleted: updateCalendar()
    }
    
    Timer {
        id: uptimeTimer
        interval: 60000
        repeat: true
        running: true
        onTriggered: updateUptime()
        Component.onCompleted: updateUptime()
    }
    
    Timer {
        id: playerMetadataTimer
        interval: 3000
        repeat: true
        running: true
        onTriggered: updatePlayerMetadata()
        Component.onCompleted: updatePlayerMetadata()
    }

    Timer {
        id: playerPositionTimer
        interval: 500
        repeat: true
        running: true
        onTriggered: updatePlayerPosition()
        Component.onCompleted: updatePlayerPosition()
    }

    Timer {
        id: ramTimer
        interval: 2000
        repeat: true
        running: true
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
                    }
                }
            }
            xhr.send()
        }
        onTriggered: readRam()
        Component.onCompleted: readRam()
    }

    Timer {
        id: cpuTimer
        interval: 2000
        repeat: true
        running: true

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
                            }
                            cpuTimer.lastTotal = total
                            cpuTimer.lastIdle = idle
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
        interval: 2000
        repeat: true
        running: true
        onTriggered: readGpu()
    }
    
    function readGpu() {
        // Read GPU usage using nvidia-smi (primary) or radeontop (fallback)
        Qt.createQmlObject("import Quickshell.Io; import QtQuick; Process { command: ['sh','-c','nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>/dev/null | head -1 | tr -d \" \" > /tmp/quickshell_gpu_usage || (timeout 1 radeontop -l 1 -d - 2>/dev/null | tail -1 | awk \"{print int(\\$2)}\" > /tmp/quickshell_gpu_usage) || echo 0 > /tmp/quickshell_gpu_usage']; running: true }", dashboardRoot)
        Qt.createQmlObject("import QtQuick; Timer { interval: 800; running: true; repeat: false; onTriggered: dashboardRoot.readGpuData() }", dashboardRoot)
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
                } else {
                    gpuUsageValue = 0
                }
            }
        }
        xhr.send()
    }

    Timer {
        id: weatherTimer
        interval: 300000 // Update every 5 minutes
        repeat: true
        running: true
        Component.onCompleted: updateWeather()
        onTriggered: updateWeather()
    }
    
    // ============ PERFORMANCE TAB FUNCTIONS ============
    function updateDiskUsage() {
        Qt.createQmlObject("import Quickshell.Io; import QtQuick; Process { command: ['sh','-c','df -h | grep -E \"^/dev\" | awk \"{print \\$6 \\\"|\\\" \\$2 \\\"|\\\" \\$3 \\\"|\\\" \\$5}\" | head -5 > /tmp/quickshell_disk_usage 2>/dev/null || echo > /tmp/quickshell_disk_usage']; running: true }", dashboardRoot)
        Qt.createQmlObject("import QtQuick; Timer { interval: 500; running: true; repeat: false; onTriggered: dashboardRoot.readDiskUsage() }", dashboardRoot)
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
        Qt.createQmlObject("import Quickshell.Io; import QtQuick; Process { command: ['sh','-c','ps aux --sort=-%cpu 2>/dev/null | tail -n +2 | head -8 | awk \"{print \\$11 \\\"|\\\" \\$3 \\\"|\\\" \\$4}\" > /tmp/quickshell_top_processes 2>/dev/null || echo > /tmp/quickshell_top_processes']; running: true }", dashboardRoot)
        Qt.createQmlObject("import QtQuick; Timer { interval: 600; running: true; repeat: false; onTriggered: dashboardRoot.readTopProcesses() }", dashboardRoot)
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
        Qt.createQmlObject("import Quickshell.Io; import QtQuick; Process { command: ['sh','-c','(sensors 2>/dev/null | grep -i \"cpu\" | grep -oE \"[0-9]+\\.[0-9]+\" | head -1 | cut -d. -f1 > /tmp/quickshell_cpu_temp) || (cat /sys/class/thermal/thermal_zone*/temp 2>/dev/null | head -1 | awk \"{print int(\\$1/1000)}\" > /tmp/quickshell_cpu_temp) || echo 0 > /tmp/quickshell_cpu_temp']; running: true }", dashboardRoot)
        Qt.createQmlObject("import QtQuick; Timer { interval: 500; running: true; repeat: false; onTriggered: dashboardRoot.readCpuTemp() }", dashboardRoot)
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
        Qt.createQmlObject("import Quickshell.Io; import QtQuick; Process { command: ['sh','-c','(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits 2>/dev/null | head -1 > /tmp/quickshell_gpu_temp) || (sensors 2>/dev/null | grep -i \"gpu\\|radeon\\|amdgpu\" | grep -oE \"[0-9]+\\.[0-9]+\" | head -1 | cut -d. -f1 > /tmp/quickshell_gpu_temp) || echo 0 > /tmp/quickshell_gpu_temp']; running: true }", dashboardRoot)
        Qt.createQmlObject("import QtQuick; Timer { interval: 500; running: true; repeat: false; onTriggered: dashboardRoot.readGpuTemp() }", dashboardRoot)
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
    
    // Performance timers
    Timer {
        id: diskUsageTimer
        interval: 5000
        repeat: true
        running: true
        onTriggered: updateDiskUsage()
        Component.onCompleted: updateDiskUsage()
    }
    
    Timer {
        id: topProcessesTimer
        interval: 3000
        repeat: true
        running: true
        onTriggered: updateTopProcesses()
        Component.onCompleted: updateTopProcesses()
    }
    
    Timer {
        id: cpuTempTimer
        interval: 5000
        repeat: true
        running: true
        onTriggered: updateCpuTemp()
        Component.onCompleted: updateCpuTemp()
    }
    
    Timer {
        id: gpuTempTimer
        interval: 5000
        repeat: true
        running: true
        onTriggered: updateGpuTemp()
        Component.onCompleted: updateGpuTemp()
    }
    
    // ============ CAVA VISUALIZER FUNCTIONS ============
    function startCava() {
        // Sprawdź czy cava jest zainstalowane
        Qt.createQmlObject("import Quickshell.Io; import QtQuick; Process { command: ['sh','-c','which cava > /dev/null 2>&1 && echo 1 > /tmp/quickshell_cava_available || echo 0 > /tmp/quickshell_cava_available']; running: true }", dashboardRoot)
        
        // Poczekaj i sprawdź dostępność
        Qt.createQmlObject("import QtQuick; Timer { interval: 200; running: true; repeat: false; onTriggered: dashboardRoot.checkCavaAvailable() }", dashboardRoot)
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
                        // Try to get from environment
                        Qt.createQmlObject("import Quickshell.Io; import QtQuick; Process { command: ['sh', '-c', 'echo \"$QUICKSHELL_PROJECT_PATH\" > /tmp/quickshell_cava_path 2>/dev/null || echo \"\" > /tmp/quickshell_cava_path']; running: true }", dashboardRoot)
                        Qt.createQmlObject("import QtQuick; Timer { interval: 100; running: true; repeat: false; onTriggered: dashboardRoot.readCavaPath() }", dashboardRoot)
                        return
                    }
                    if (!scriptPath || scriptPath.length === 0 || scriptPath === "/scripts/start-cava.sh") {
                        console.log("Invalid script path for cava:", scriptPath)
                        return
                    }
                    var absScriptPath = scriptPath
                    Qt.createQmlObject('import Quickshell.Io; import QtQuick; Process { command: ["bash", "' + absScriptPath + '"]; running: true }', dashboardRoot)
                    
                    cavaRunning = true
                    console.log("Cava started with script...")
                    Qt.createQmlObject("import QtQuick; Timer { interval: 500; running: true; repeat: false; onTriggered: dashboardRoot.readCavaData() }", dashboardRoot)
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
                    Qt.createQmlObject('import Quickshell.Io; import QtQuick; Process { command: ["bash", "' + absScriptPath + '"]; running: true }', dashboardRoot)
                    cavaRunning = true
                    Qt.createQmlObject("import QtQuick; Timer { interval: 500; running: true; repeat: false; onTriggered: dashboardRoot.readCavaData() }", dashboardRoot)
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
                        console.log("Cava file not accessible, status:", xhr.status)
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
                        
                        for (var i = 0; i < 72; i++) {
                            var val = 0
                            // Mapuj 36 wartości z cava na 72 paski (każda wartość odpowiada 2 paskom)
                            var sourceIndex = Math.floor(i / 2)
                            if (sourceIndex < values.length && values[sourceIndex]) {
                                val = parseInt(values[sourceIndex]) || 0
                            }
                            var normalizedHeight = Math.max(2, (val / 100) * 200)  // Wyższe paski - maksymalnie 200px
                            if (mediaVisualizerBarsRepeater.itemAt(i)) {
                                mediaVisualizerBarsRepeater.itemAt(i).mediaVisualizerBarValue = normalizedHeight
                                var intensity = val / 100
                                if (intensity > 0.7) {
                                    mediaVisualizerBarsRepeater.itemAt(i).color = colorAccent
                                } else if (intensity > 0.4) {
                                    mediaVisualizerBarsRepeater.itemAt(i).color = colorText
                                } else if (intensity > 0.1) {
                                    mediaVisualizerBarsRepeater.itemAt(i).color = colorPrimary
                                } else {
                                    mediaVisualizerBarsRepeater.itemAt(i).color = colorSecondary
                                }
                            }
                        }
                    }
                } else {
                    if (cavaRunning) {
                        console.log("Cava file is empty, checking if process is running...")
                    }
                }
            }
        }
        xhr.send()
    }
    
    // Timer do odczytu danych z cava
    Timer {
        id: cavaDataTimer
        interval: 16  // ~60 FPS
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
                            console.log("Cava file not accessible, restarting...")
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
        updateCalendar()
        updateDate()
        updateUptime()
        updateWeather()
        // Initialize project path
        Qt.createQmlObject("import Quickshell.Io; import QtQuick; Process { command: ['sh', '-c', 'echo \"$QUICKSHELL_PROJECT_PATH\" > /tmp/quickshell_cava_path 2>/dev/null || pwd > /tmp/quickshell_cava_path']; running: true }", dashboardRoot)
        Qt.createQmlObject("import QtQuick; Timer { interval: 200; running: true; repeat: false; onTriggered: dashboardRoot.readCavaPath() }", dashboardRoot)
        startCava()
    }
    
    Connections {
        target: sharedData
        function onMenuVisibleChanged() {
            if (sharedData && sharedData.menuVisible) {
                Qt.createQmlObject("import QtQuick; Timer { interval: 100; running: true; repeat: false; onTriggered: { if (dashboardRoot.dashboardContainer) dashboardRoot.dashboardContainer.forceActiveFocus() } }", dashboardRoot)
            } else {
                dashboardContainer.focus = false
            }
        }
    }
}


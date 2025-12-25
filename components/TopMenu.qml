import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import Quickshell.Io

PanelWindow {
    id: topMenuRoot

    anchors { top: true }
    implicitWidth: 648
    implicitHeight: 288
    
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qsmenu"
    WlrLayershell.keyboardFocus: (sharedData && sharedData.menuVisible) ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    exclusiveZone: 0

    property int currentTab: 0
    property var sharedData: null
    
    // Kontrola widoczności - zawsze widoczne, przesuwamy przez margins
    visible: true
    color: "transparent"  // Przezroczyste tło, żeby nie było białe
    
    // Właściwość do animacji margins.top
    property int slideOffset: (sharedData && sharedData.menuVisible) ? 0 : -implicitHeight
    
    margins.top: slideOffset
    
    // Animacja slideOffset dla slide in/out
    Behavior on slideOffset {
        NumberAnimation { 
            duration: 400
            easing.type: Easing.OutQuart
        }
    }

    // Kontener z animacją fade in/out
    Item {
        id: topMenuContainer
        anchors.fill: parent
        
        // Stan animacji
        property bool isShowing: topMenuRoot.visible
        
        // Właściwości animacji fade
        opacity: isShowing ? 1.0 : 0.0
        
        // Animacja fade in/out
        Behavior on opacity {
            NumberAnimation { 
                duration: 400
                easing.type: Easing.OutQuart
            }
        }
        
        // Wyłączamy interakcję gdy menu jest ukryte
        enabled: opacity > 0.1
        focus: (sharedData && sharedData.menuVisible)  // Focus dla klawiatury
        
        // Obsługa klawiszy - Escape zamyka menu
        Keys.onPressed: function(event) {
            if (event.key === Qt.Key_Escape) {
                if (sharedData) {
                    sharedData.menuVisible = false
                }
                event.accepted = true
            }
        }
        
        // MouseArea - menu nie zamyka się automatycznie, tylko przez skrót klawiszowy
        MouseArea {
            id: topMenuMouseArea
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
            propagateComposedEvents: true
            z: 1000  // Na wierzchu
            
            // Menu nie zamyka się automatycznie po opuszczeniu myszką
            // Zamyka się tylko przez skrót klawiszowy (toggleMenu)
        }

        // Tło jednolite
        Rectangle {
            id: topMenuBackground
            anchors.fill: parent
            radius: 0
            color: (sharedData && sharedData.colorBackground) ? sharedData.colorBackground : "#111111"
            
        }

        Column {
            id: topMenuColumn
            anchors.fill: parent
            spacing: 0

        // ============ PASEK ZAKŁADEK ============
        Rectangle {
            id: topMenuTabBar
            width: parent.width
            height: 45
            color: (sharedData && sharedData.colorBackground) ? sharedData.colorBackground : "#111111"
            radius: 0
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right

            Row {
                id: topMenuTabRow
                anchors.fill: parent

                Repeater {
                    id: topMenuTabRepeater
                    model: [
                        { icon: "󰎆", label: "Player" },
                        { icon: "󰃰", label: "System" },
                        { icon: "󰒓", label: "Options" }
                    ]

                    Rectangle {
                        id: topMenuTabItem
                        width: parent.width / 3
                        height: parent.height
                        color: currentTab === index ? 
                            ((sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff") : 
                            (topMenuTabItemMouseArea.containsMouse ? 
                                ((sharedData && sharedData.colorPrimary) ? sharedData.colorPrimary : "#3a3a3a") : 
                                ((sharedData && sharedData.colorPrimary) ? sharedData.colorPrimary : "#3a3a3a"))
                        radius: 0
                        scale: (topMenuTabItemMouseArea.containsMouse || currentTab === index) ? 1.02 : 1.0
                        
                        Behavior on color {
                            ColorAnimation { 
                                duration: 180
                                easing.type: Easing.OutQuart
                            }
                        }
                        
                        Behavior on scale {
                            NumberAnimation {
                                duration: 180
                                easing.type: Easing.OutQuart
                            }
                        }

                        Row {
                            id: topMenuTabContent
                            anchors.centerIn: parent
                            spacing: 10

                            Text {
                                id: topMenuTabIcon
                                text: modelData.icon
                                font.pixelSize: 18
                                color: currentTab === index ? 
                                    ((sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff") : 
                                    (topMenuTabItemMouseArea.containsMouse ?
                                        ((sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff") :
                                        ((sharedData && sharedData.colorText) ? Qt.lighter(sharedData.colorText, 1.5) : "#aaaaaa"))
                                
                                Behavior on color {
                                    ColorAnimation {
                                        duration: 180
                                        easing.type: Easing.OutQuart
                                    }
                                }
                            }

                            Text {
                                id: topMenuTabLabel
                                text: modelData.label
                                font.pixelSize: 15
                                font.family: "JetBrains Mono"
                                font.weight: currentTab === index ? Font.Bold : Font.Medium
                                font.letterSpacing: 0.2
                                color: currentTab === index ? 
                                    ((sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff") : 
                                    (topMenuTabItemMouseArea.containsMouse ?
                                        ((sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff") :
                                        ((sharedData && sharedData.colorText) ? Qt.lighter(sharedData.colorText, 1.5) : "#aaaaaa"))
                                
                                Behavior on color {
                                    ColorAnimation {
                                        duration: 180
                                        easing.type: Easing.OutQuart
                                    }
                                }
                            }
                        }

                        Rectangle {
                            id: topMenuTabIndicator
                            anchors.bottom: parent.bottom
                            width: parent.width
                            height: 3
                            color: (sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff"
                            opacity: currentTab === index ? 1.0 : 0.0
                            
                            Behavior on opacity {
                                NumberAnimation {
                                    duration: 220
                                    easing.type: Easing.OutQuart
                                }
                            }
                        }

                        MouseArea {
                            id: topMenuTabItemMouseArea
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true
                            onClicked: currentTab = index
                        }
                    }
                }
            }
        }

        // ============ ZAWARTOŚĆ ============
        Item {
            id: topMenuContent
            width: parent.width
            height: parent.height - topMenuTabBar.height
            clip: true  // Obcinamy zawartość poza granicami

            // -------- TAB 0: PLAYER --------
            Item {
                id: topMenuPlayerTab
                anchors.fill: parent
                
                // Animacja slide in/out na boki
                // Gdy aktywna: x = 0, gdy nieaktywna: wjeżdża z lewej (-width) lub prawej (width)
                x: (currentTab === 0) ? 0 : (currentTab > 0 ? width : -width)
                opacity: (currentTab === 0) ? 1.0 : 0.0
                
                Behavior on x {
                    NumberAnimation { 
                        duration: 280
                        easing.type: Easing.OutQuart
                    }
                }
                
                Behavior on opacity {
                    NumberAnimation { 
                        duration: 280
                        easing.type: Easing.OutQuart
                    }
                }

                Row {
                    id: topMenuPlayerRow
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.verticalCenterOffset: 35
                    spacing: 40

                    // Album Art
                    Rectangle {
                        id: topMenuAlbumArtRect
                        width: 160
                        height: 160
                        color: (sharedData && sharedData.colorSecondary) ? sharedData.colorSecondary : "#141414"
                        anchors.verticalCenter: parent.verticalCenter
                        opacity: (currentTab === 0) ? 1.0 : 0.0
                        scale: (currentTab === 0) ? 1.0 : 0.95
                        
                        Behavior on opacity {
                            NumberAnimation {
                                duration: 300
                                easing.type: Easing.OutQuart
                            }
                        }
                        
                        Behavior on scale {
                            NumberAnimation {
                                duration: 300
                                easing.type: Easing.OutQuart
                            }
                        }

                        Image {
                            id: topMenuAlbumArt
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
                            id: topMenuAlbumArtPlaceholder
                            anchors.centerIn: parent
                            text: "󰎆"
                            font.pixelSize: 43
                            color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff"
                            visible: !mpArt
                        }
                    }

                    Column {
                        id: topMenuPlayerInfoCol
                        spacing: 16
                        width: 280
                        anchors.verticalCenter: parent.verticalCenter

                        Column {
                            id: topMenuTrackInfo
                            spacing: 5
                            width: parent.width

                            Text {
                                id: topMenuTrackTitle
                                text: mpTitle ? mpTitle : "Nothing playing"
                                font.pixelSize: 17
                                font.family: "JetBrains Mono"
                                font.weight: Font.DemiBold
                                font.letterSpacing: 0.2
                                color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#f5f5f5"
                                elide: Text.ElideRight
                                width: parent.width
                            }

                            Text {
                                id: topMenuTrackArtist
                                text: mpArtist ? mpArtist : "—"
                                font.pixelSize: 14
                                font.family: "JetBrains Mono"
                                font.weight: Font.Medium
                                font.letterSpacing: 0.1
                                color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff"
                                elide: Text.ElideRight
                                width: parent.width
                            }
                        }

                        Column {
                            id: topMenuProgressCol
                            width: parent.width
                            spacing: 5
                            opacity: (currentTab === 0) ? 1.0 : 0.0
                            
                            Behavior on opacity {
                                NumberAnimation {
                                    duration: 300
                                    easing.type: Easing.OutQuart
                                }
                            }

                            Rectangle {
                                id: topMenuProgressBarBg
                                width: parent.width
                                height: 4
                                color: (sharedData && sharedData.colorPrimary) ? sharedData.colorPrimary : "#1e1e1e"
                                scale: topMenuProgressMouseArea.containsMouse ? 1.05 : 1.0
                                
                                Behavior on scale {
                                    NumberAnimation {
                                        duration: 200
                                        easing.type: Easing.OutQuart
                                    }
                                }

                                Rectangle {
                                    id: topMenuProgressFill
                                    width: (mpLength > 0) ? (parent.width * (mpPosition / mpLength)) : 0
                                    height: parent.height
                                    color: (sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff"
                                    Behavior on width { 
                                        NumberAnimation { 
                                            duration: 300
                                            easing.type: Easing.OutQuart
                                        } 
                                    }
                                }

                                MouseArea {
                                    id: topMenuProgressMouseArea
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: function(mouse) {
                                        if (mpLength > 0) {
                                            var newPosSeconds = Math.round((mouse.x / parent.width) * mpLength)
                                            seekPlayer(newPosSeconds)
                                        }
                                    }
                                }
                            }

                            Row {
                                id: topMenuTimeRow
                                width: parent.width
                                Text {
                                    id: topMenuPosText
                                    text: formatTime(mpPosition)
                                    font.pixelSize: 10
                                    font.family: "JetBrains Mono"
                                    color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff"
                                }
                                Item { width: parent.width - topMenuPosText.width - topMenuLengthText.width; height: 1 }
                                Text {
                                    id: topMenuLengthText
                                    text: mpLength > 0 ? formatTime(mpLength) : "--:--"
                                    font.pixelSize: 10
                                    font.family: "JetBrains Mono"
                                    color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff"
                                }
                            }
                        }

                        Row {
                            id: topMenuControlsRow
                            spacing: 12
                            anchors.horizontalCenter: parent.horizontalCenter

                            Rectangle {
                                id: topMenuPrevBtn
                                width: 45; height: 45
                                color: topMenuPrevArea.containsMouse ? 
                                    ((sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff") : 
                                    ((sharedData && sharedData.colorSecondary) ? sharedData.colorSecondary : "#161616")
                                scale: topMenuPrevArea.containsMouse ? 1.1 : 1.0
                                
                                Behavior on color {
                                    ColorAnimation {
                                        duration: 180
                                        easing.type: Easing.OutQuart
                                    }
                                }
                                
                                Behavior on scale {
                                    NumberAnimation {
                                        duration: 200
                                        easing.type: Easing.OutQuart
                                    }
                                }

                                Text { 
                                    id: topMenuPrevIcon
                                    text: "󰒮"; 
                                    anchors.centerIn: parent; 
                                    font.pixelSize: 23; 
                                    color: topMenuPrevArea.containsMouse ? 
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
                                    id: topMenuPrevArea
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    hoverEnabled: true
                                    onClicked: playerPrev()
                                }
                            }

                            Rectangle {
                                id: topMenuPlayPauseBtn
                                width: 54; height: 45
                                color: topMenuPlayArea.containsMouse ? 
                                    ((sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff") : 
                                    ((sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff")
                                scale: topMenuPlayArea.containsMouse ? 1.1 : 1.0
                                
                                Behavior on color {
                                    ColorAnimation {
                                        duration: 180
                                        easing.type: Easing.OutQuart
                                    }
                                }
                                
                                Behavior on scale {
                                    NumberAnimation {
                                        duration: 200
                                        easing.type: Easing.OutQuart
                                    }
                                }

                                Text {
                                    id: topMenuPlayPauseIcon
                                    text: mpPlaying ? "󰏤" : "󰐊"
                                    anchors.centerIn: parent
                                    font.pixelSize: 25
                                    color: (sharedData && sharedData.colorBackground) ? sharedData.colorBackground : "#0a0a0a"
                                    rotation: topMenuPlayArea.containsMouse ? 5 : 0
                                    
                                    Behavior on rotation {
                                        NumberAnimation {
                                            duration: 200
                                            easing.type: Easing.OutQuart
                                        }
                                    }
                                }

                                MouseArea {
                                    id: topMenuPlayArea
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    hoverEnabled: true
                                    onClicked: playerPlayPause()
                                }
                            }

                            Rectangle {
                                id: topMenuNextBtn
                                width: 45; height: 45
                                color: topMenuNextArea.containsMouse ? 
                                    ((sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff") : 
                                    ((sharedData && sharedData.colorSecondary) ? sharedData.colorSecondary : "#161616")
                                scale: topMenuNextArea.containsMouse ? 1.1 : 1.0
                                
                                Behavior on color {
                                    ColorAnimation {
                                        duration: 180
                                        easing.type: Easing.OutQuart
                                    }
                                }
                                
                                Behavior on scale {
                                    NumberAnimation {
                                        duration: 200
                                        easing.type: Easing.OutQuart
                                    }
                                }

                                Text { 
                                    id: topMenuNextIcon
                                    text: "󰒭"; 
                                    anchors.centerIn: parent; 
                                    font.pixelSize: 23; 
                                    color: topMenuNextArea.containsMouse ? 
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
                                    id: topMenuNextArea
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

            // -------- TAB 1: SYSTEM --------
            Item {
                id: topMenuSystemTab
                anchors.fill: parent
                
                // Animacja slide in/out na boki
                // Gdy aktywna: x = 0
                // Gdy przechodzimy z Player (0) do System (1): wjeżdża z prawej (width)
                // Gdy przechodzimy z Options (2) do System (1): wjeżdża z lewej (-width)
                x: (currentTab === 1) ? 0 : (currentTab < 1 ? -width : width)
                opacity: (currentTab === 1) ? 1.0 : 0.0
                
                Behavior on x {
                    NumberAnimation { 
                        duration: 280
                        easing.type: Easing.OutQuart
                    }
                }
                
                Behavior on opacity {
                    NumberAnimation { 
                        duration: 280
                        easing.type: Easing.OutQuart
                    }
                }

                Column {
                    id: topMenuSystemStatsCol
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.verticalCenterOffset: 35
                    spacing: 20
                    width: 300

                        Repeater {
                            id: topMenuSystemStatsRepeater
                            model: [
                                { name: "CPU", value: cpuUsageValue, temp: cpuTempValue },
                                { name: "RAM", value: ramUsageValue, temp: -1 },
                                { name: "GPU", value: gpuUsageValue, temp: gpuTempValue }
                            ]

                            Row {
                                id: topMenuSystemStatRow
                                spacing: 12
                                width: parent.width
                                anchors.left: parent.left

                                Text {
                                    id: topMenuSystemStatName
                                    text: modelData.name
                                    font.pixelSize: 14
                                    font.family: "JetBrains Mono"
                                    font.weight: Font.Medium
                                    font.letterSpacing: 0.2
                                    color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff"
                                    width: 45
                                }

                                Rectangle {
                                    id: topMenuSystemStatBarBg
                                    width: parent.width - topMenuSystemStatName.width - topMenuSystemStatValue.width - 24
                                    height: 5
                                    color: (sharedData && sharedData.colorPrimary) ? sharedData.colorPrimary : "#1e1e1e"

                                    Rectangle {
                                        id: topMenuSystemStatBarFill
                                        height: parent.height
                                        width: parent.width * (modelData.value / 100)
                                        color: (sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff"
                                        Behavior on width { NumberAnimation { duration: 400 } }
                                    }
                                }

                                Text {
                                    id: topMenuSystemStatValue
                                    text: modelData.value + "%" + (modelData.temp >= 0 ? " " + modelData.temp + "°" : "")
                                    font.pixelSize: 14
                                    font.family: "JetBrains Mono"
                                    font.weight: Font.Medium
                                    font.letterSpacing: 0.2
                                    color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#f5f5f5"
                                    width: 70
                                    horizontalAlignment: Text.AlignRight
                                }
                            }
                        }
                    }
                }
            }

            // -------- TAB 2: OPTIONS --------
            Item {
                id: topMenuOptionsTab
                anchors.fill: parent
                
                // Animacja slide in/out na boki
                // Gdy aktywna: x = 0, gdy nieaktywna: wjeżdża z lewej (-width)
                x: (currentTab === 2) ? 0 : -width
                opacity: (currentTab === 2) ? 1.0 : 0.0
                
                Behavior on x {
                    NumberAnimation { 
                        duration: 280
                        easing.type: Easing.OutQuart
                    }
                }
                
                Behavior on opacity {
                    NumberAnimation { 
                        duration: 280
                        easing.type: Easing.OutQuart
                    }
                }

                Row {
                    id: topMenuOptionsRow
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.verticalCenterOffset: 35
                    spacing: 24

                    Repeater {
                        id: topMenuOptionsRepeater
                        model: [
                            { icon: "󰐥", label: "Power Off", action: "poweroff" },
                            { icon: "󰜉", label: "Reboot", action: "reboot" }
                        ]

                        Rectangle {
                            id: topMenuOptionBtn
                            width: 150
                            height: 150
                            color: topMenuOptionArea.containsMouse ? 
                                ((sharedData && sharedData.colorPrimary) ? sharedData.colorPrimary : "#1e1e1e") : 
                                ((sharedData && sharedData.colorBackground) ? sharedData.colorBackground : "#111111")
                            radius: 0
                            scale: topMenuOptionArea.containsMouse ? 1.05 : 1.0
                            opacity: (currentTab === 2) ? 1.0 : 0.0
                            
                            Behavior on color {
                                ColorAnimation {
                                    duration: 200
                                    easing.type: Easing.OutQuart
                                }
                            }
                            
                            Behavior on scale {
                                NumberAnimation {
                                    duration: 200
                                    easing.type: Easing.OutQuart
                                }
                            }
                            
                            Behavior on opacity {
                                SequentialAnimation {
                                    PauseAnimation { duration: index * 100 }
                                    NumberAnimation {
                                        duration: 300
                                        easing.type: Easing.OutQuart
                                    }
                                }
                            }

                            Column {
                                id: topMenuOptionContent
                                anchors.centerIn: parent
                                spacing: 14

                                Text {
                                    id: topMenuOptionIcon
                                    text: modelData.icon
                                    font.pixelSize: 45
                                    color: topMenuOptionArea.containsMouse ? 
                                        ((sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff") : 
                                        ((sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff")
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    scale: topMenuOptionArea.containsMouse ? 1.1 : 1.0
                                    
                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 200
                                            easing.type: Easing.OutQuart
                                        }
                                    }
                                    
                                    Behavior on scale {
                                        NumberAnimation {
                                            duration: 200
                                            easing.type: Easing.OutQuart
                                        }
                                    }
                                }

                                Text {
                                    id: topMenuOptionLabel
                                    text: modelData.label
                                    font.pixelSize: 14
                                    font.family: "JetBrains Mono"
                                    font.weight: Font.Medium
                                    font.letterSpacing: 0.2
                                    color: topMenuOptionArea.containsMouse ? 
                                        ((sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff") : 
                                        ((sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff")
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }
                            }

                            MouseArea {
                                id: topMenuOptionArea
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                hoverEnabled: true
                                onClicked: {
                                    if (modelData.action === "poweroff") {
                                        Qt.createQmlObject("import Quickshell.Io; import QtQuick; Process { command: ['systemctl','poweroff']; running: true }", topMenuRoot)
                                    } else if (modelData.action === "reboot") {
                                        Qt.createQmlObject("import Quickshell.Io; import QtQuick; Process { command: ['systemctl','reboot']; running: true }", topMenuRoot)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // Timer do opóźnienia ukrywania - wyłączony, menu zamyka się tylko przez skrót klawiszowy
    Timer {
        id: hideDelayTimer
        interval: 500
        running: false  // Wyłączony - menu nie zamyka się automatycznie
        onTriggered: {
            // Nie zamykamy automatycznie - tylko przez toggleMenu()
        }
    }

    // --- Właściwości ---
    property int ramUsageValue: 0
    property int cpuUsageValue: 0
    property int gpuUsageValue: 0
    property int cpuTempValue: 0
    property int gpuTempValue: 0
    property real volumeValue: 50
    property bool bluetoothEnabled: false
    property string mpTitle: ""
    property string mpArtist: ""
    property string mpArt: ""
    property bool mpPlaying: false
    property real mpPosition: 0
    property int mpLength: 0
    property string currentTime: ""
    property string currentDate: ""

    // --- Funkcje ---
    function toggleBluetooth() {
        var command = bluetoothEnabled ? "off" : "on"
        Qt.createQmlObject("import Quickshell.Io; import QtQuick; Process { command: ['bluetoothctl','power','" + command + "']; running: true }", topMenuRoot)
        topMenuBluetoothCheckTimer.restart()
    }

    function launchBluetuiInTerminal() {
        Qt.createQmlObject("import Quickshell.Io; import QtQuick; Process { command: ['kitty','bluetui']; running: true }", topMenuRoot)
    }

    function lockScreen() {
        Qt.createQmlObject("import Quickshell.Io; import QtQuick; Process { command: ['hyprlock']; running: true }", topMenuRoot)
    }

    function setSystemVolume(value) {
        volumeValue = Math.round(value)
        Qt.createQmlObject("import Quickshell.Io; import QtQuick; Process { command: ['pactl','set-sink-volume','@DEFAULT_SINK@','" + Math.round(value) + "%']; running: true }", topMenuRoot)
        // Odśwież volume po ustawieniu
        Qt.createQmlObject("import QtQuick; Timer { interval: 200; running: true; repeat: false; onTriggered: topMenuRoot.getSystemVolume() }", topMenuRoot)
        Qt.createQmlObject("import QtQuick; Timer { interval: 350; running: true; repeat: false; onTriggered: topMenuRoot.readSystemVolume() }", topMenuRoot)
    }

    function getSystemVolume() {
        // Zapisz volume do pliku
        Qt.createQmlObject("import Quickshell.Io; import QtQuick; Process { command: ['sh','-c','pactl get-sink-volume @DEFAULT_SINK@ | head -1 | awk \\\"{print $5}\\\" | tr -d % > /tmp/quickshell_volume']; running: true }", topMenuRoot)
    }

    function readSystemVolume() {
        // Użyj XMLHttpRequest z QML_XHR_ALLOW_FILE_READ=1 (ustawione w run.sh)
        var xhr = new XMLHttpRequest()
        xhr.open("GET", "file:///tmp/quickshell_volume")
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE && xhr.responseText) {
                var vol = parseInt(xhr.responseText.trim())
                if (!isNaN(vol) && vol >= 0 && vol <= 100) {
                    volumeValue = vol
                }
            }
        }
        xhr.send()
    }

    function checkBluetooth() {
        Qt.createQmlObject("import Quickshell.Io; import QtQuick; Process { command: ['sh','-c','bluetoothctl show | grep -q \"Powered: yes\" && echo on > /tmp/quickshell_bt_status || echo off > /tmp/quickshell_bt_status']; running: true }", topMenuRoot)
        
        var xhr = new XMLHttpRequest()
        xhr.open("GET", "file:///tmp/quickshell_bt_status")
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                var status = xhr.responseText.trim()
                bluetoothEnabled = (status === "on")
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
        // Uruchom playerctl i zapisz do pliku - zapisz też błędy do debug
        Qt.createQmlObject('import Quickshell.Io; import QtQuick; Process { command: ["sh", "-c", "playerctl metadata --format \'{{artist}}\\n{{title}}\\n{{mpris:artUrl}}\\n{{mpris:length}}\\n{{status}}\' > /tmp/quickshell_player_info 2>/tmp/quickshell_player_err || echo > /tmp/quickshell_player_info"]; running: true }', topMenuRoot)
        
        // Odczytaj plik po małym opóźnieniu (żeby Process zdążył zapisać)
        Qt.createQmlObject("import QtQuick; Timer { interval: 200; running: true; repeat: false; onTriggered: topMenuRoot.readPlayerMetadata() }", topMenuRoot)
    }
    
    function readPlayerMetadata() {
        var xhr = new XMLHttpRequest()
        xhr.open("GET", "file:///tmp/quickshell_player_info")
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                var txt = xhr.responseText || ""
                console.log("Player info raw:", txt.length, "bytes")
                if (txt.trim() === "") {
                    mpTitle = ""
                    mpArtist = ""
                    mpArt = ""
                    mpPlaying = false
                    mpPosition = 0
                    mpLength = 0
                    return
                }
                var lines = txt.split("\n")
                mpArtist = lines[0] ? lines[0].trim() : ""
                mpTitle = lines[1] ? lines[1].trim() : ""
                var art = lines[2] ? lines[2].trim() : ""
                var lengthRaw = (lines[3] || "").trim()
                var status = (lines[4] || "").trim().toLowerCase()

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
        Qt.createQmlObject('import Quickshell.Io; import QtQuick; Process { command: ["sh", "-c", "playerctl position > /tmp/quickshell_player_pos 2>/dev/null || echo 0 > /tmp/quickshell_player_pos"]; running: true }', topMenuRoot)
        
        // Odczytaj po małym opóźnieniu
        Qt.createQmlObject("import QtQuick; Timer { interval: 150; running: true; repeat: false; onTriggered: topMenuRoot.readPlayerPosition() }", topMenuRoot)
    }
    
    function readPlayerPosition() {
        var xhr = new XMLHttpRequest()
        xhr.open("GET", "file:///tmp/quickshell_player_pos")
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                var txt = (xhr.responseText || "").trim()
                if (txt === "" || txt === "0") {
                    topMenuProgressFill.width = 0
                    return
                }
                var pos = parseTimeToSeconds(txt)
                if (!isNaN(pos)) {
                    mpPosition = pos
                }

                if (mpLength > 0) {
                    var frac = mpPosition / mpLength
                    if (frac < 0) frac = 0
                    if (frac > 1) frac = 1
                    topMenuProgressFill.width = Math.round(topMenuProgressBarBg.width * frac)
                } else {
                    topMenuProgressFill.width = 0
                }
            }
        }
        xhr.send()
    }

    function playerPlayPause() {
        Qt.createQmlObject('import Quickshell.Io; import QtQuick; Process { command: ["playerctl", "play-pause"]; running: true }', topMenuRoot)
        Qt.createQmlObject("import QtQuick; Timer { interval: 250; running: true; repeat: false; onTriggered: topMenuRoot.updatePlayerMetadata() }", topMenuRoot)
        Qt.createQmlObject("import QtQuick; Timer { interval: 400; running: true; repeat: false; onTriggered: topMenuRoot.updatePlayerPosition() }", topMenuRoot)
    }

    function playerNext() {
        Qt.createQmlObject('import Quickshell.Io; import QtQuick; Process { command: ["playerctl", "next"]; running: true }', topMenuRoot)
        Qt.createQmlObject("import QtQuick; Timer { interval: 300; running: true; repeat: false; onTriggered: topMenuRoot.updatePlayerMetadata() }", topMenuRoot)
    }

    function playerPrev() {
        Qt.createQmlObject('import Quickshell.Io; import QtQuick; Process { command: ["playerctl", "previous"]; running: true }', topMenuRoot)
        Qt.createQmlObject("import QtQuick; Timer { interval: 300; running: true; repeat: false; onTriggered: topMenuRoot.updatePlayerMetadata() }", topMenuRoot)
    }

    function seekPlayer(seconds) {
        Qt.createQmlObject('import Quickshell.Io; import QtQuick; Process { command: ["playerctl", "position", "' + seconds + '"]; running: true }', topMenuRoot)
        Qt.createQmlObject("import QtQuick; Timer { interval: 200; running: true; repeat: false; onTriggered: topMenuRoot.updatePlayerPosition() }", topMenuRoot)
        Qt.createQmlObject("import QtQuick; Timer { interval: 300; running: true; repeat: false; onTriggered: topMenuRoot.updatePlayerMetadata() }", topMenuRoot)
    }

    function formatTime(sec) {
        if (!sec || sec <= 0) return "0:00"
        var s = Math.floor(sec % 60)
        var m = Math.floor((sec / 60) % 60)
        var h = Math.floor(sec / 3600)
        if (h > 0) return h + ":" + (m < 10 ? "0" + m : m) + ":" + (s < 10 ? "0" + s : s)
        return m + ":" + (s < 10 ? "0" + s : s)
    }

    function updateDateTime() {
        var now = new Date()
        var hours = now.getHours()
        var minutes = now.getMinutes()
        currentTime = (hours < 10 ? "0" + hours : hours) + ":" + (minutes < 10 ? "0" + minutes : minutes)

        var days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        var months = ["January", "February", "March", "April", "May", "June",
                      "July", "August", "September", "October", "November", "December"]

        var dayName = days[now.getDay()]
        var day = now.getDate()
        var month = months[now.getMonth()]
        var year = now.getFullYear()

        currentDate = dayName + ", " + month + " " + day + ", " + year
    }

    // --- Timery ---
    Timer {
        id: topMenuMetadataTimer
        interval: 3000
        repeat: true
        running: true
        onTriggered: updatePlayerMetadata()
        Component.onCompleted: updatePlayerMetadata()
    }

    Timer {
        id: topMenuBluetoothCheckTimer
        interval: 1000
        repeat: false
        onTriggered: checkBluetooth()
    }

    Timer {
        id: topMenuClockTimer
        interval: 1000
        repeat: true
        running: true
        onTriggered: updateDateTime()
        Component.onCompleted: updateDateTime()
    }

    Timer {
        id: topMenuPositionTimer
        interval: 500
        repeat: true
        running: true
        onTriggered: updatePlayerPosition()
        Component.onCompleted: updatePlayerPosition()
    }

    Timer {
        id: topMenuVolumeTimer
        interval: 1000
        repeat: true
        running: true
        onTriggered: {
            getSystemVolume()
            // Poczekaj 150ms i przeczytaj volume
            Qt.createQmlObject("import QtQuick; Timer { interval: 150; running: true; repeat: false; onTriggered: topMenuRoot.readSystemVolume() }", topMenuRoot)
        }
        Component.onCompleted: {
            getSystemVolume()
            Qt.createQmlObject("import QtQuick; Timer { interval: 150; running: true; repeat: false; onTriggered: topMenuRoot.readSystemVolume() }", topMenuRoot)
        }
    }

    Timer {
        id: topMenuRamTimer
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
                    if (memTotal > 0) ramUsageValue = 100 - Math.round((memAvailable / memTotal) * 100)
                }
            }
            xhr.send()
        }
        onTriggered: readRam()
        Component.onCompleted: readRam()
    }

    Timer {
        id: topMenuCpuTimer
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
                            if (topMenuCpuTimer.lastTotal > 0) {
                                cpuUsageValue = Math.round((total - topMenuCpuTimer.lastTotal - (idle - topMenuCpuTimer.lastIdle)) / (total - topMenuCpuTimer.lastTotal) * 100)
                            }
                            topMenuCpuTimer.lastTotal = total
                            topMenuCpuTimer.lastIdle = idle
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
        id: topMenuGpuTimer
        interval: 2000
        repeat: true
        running: true
        function readGpu() {
            // Read GPU usage
            Qt.createQmlObject("import Quickshell.Io; import QtQuick; Process { command: ['sh','-c','nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>/dev/null | head -1 > /tmp/quickshell_gpu_usage || echo 0 > /tmp/quickshell_gpu_usage']; running: true }", topMenuRoot)
            
            // Read GPU temperature
            Qt.createQmlObject("import Quickshell.Io; import QtQuick; Process { command: ['sh','-c','nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits 2>/dev/null | head -1 > /tmp/quickshell_gpu_temp || (sensors 2>/dev/null | grep -i \"gpu\\|radeon\\|amdgpu\" | head -1 | grep -oE \"[0-9]+\\.[0-9]+\" | head -1 | cut -d. -f1 > /tmp/quickshell_gpu_temp) || echo 0 > /tmp/quickshell_gpu_temp']; running: true }", topMenuRoot)
            
            Qt.createQmlObject("import QtQuick; Timer { interval: 100; running: true; repeat: false; onTriggered: topMenuRoot.readGpuData() }", topMenuRoot)
        }
        
        function readGpuData() {
            // Read GPU usage
            var xhr = new XMLHttpRequest()
            xhr.open("GET", "file:///tmp/quickshell_gpu_usage")
            xhr.onreadystatechange = function() {
                if (xhr.readyState === XMLHttpRequest.DONE) {
                    var usage = parseInt(xhr.responseText.trim())
                    if (!isNaN(usage)) gpuUsageValue = usage
                }
            }
            xhr.send()
            
            // Read GPU temperature
            var xhr2 = new XMLHttpRequest()
            xhr2.open("GET", "file:///tmp/quickshell_gpu_temp")
            xhr2.onreadystatechange = function() {
                if (xhr2.readyState === XMLHttpRequest.DONE) {
                    var temp = parseInt(xhr2.responseText.trim())
                    if (!isNaN(temp) && temp > 0) gpuTempValue = temp
                }
            }
            xhr2.send()
        }
        
        onTriggered: readGpu()
        Component.onCompleted: readGpu()
    }
    
    Timer {
        id: topMenuCpuTempTimer
        interval: 2000
        repeat: true
        running: true
        function readCpuTemp() {
            // Try multiple methods to get CPU temperature
            // Method 1: sensors (if available)
            // Method 2: /sys/class/thermal/thermal_zone*/temp (default Linux)
            Qt.createQmlObject("import Quickshell.Io; import QtQuick; Process { command: ['sh','-c','(sensors 2>/dev/null | grep -i \"cpu\" | grep -E \"[0-9]+\\.[0-9]+°C\" | head -1 | grep -oE \"[0-9]+\\.[0-9]+\" | head -1 | cut -d. -f1) || (cat /sys/class/thermal/thermal_zone*/temp 2>/dev/null | head -1 | awk \"{print int(\\$1/1000)}\") || echo 0 > /tmp/quickshell_cpu_temp']; running: true }", topMenuRoot)
            
            Qt.createQmlObject("import QtQuick; Timer { interval: 150; running: true; repeat: false; onTriggered: topMenuRoot.readCpuTempData() }", topMenuRoot)
        }
        
        function readCpuTempData() {
            var xhr = new XMLHttpRequest()
            xhr.open("GET", "file:///tmp/quickshell_cpu_temp")
            xhr.onreadystatechange = function() {
                if (xhr.readyState === XMLHttpRequest.DONE) {
                    var temp = parseInt(xhr.responseText.trim())
                    if (!isNaN(temp) && temp > 0 && temp < 150) cpuTempValue = temp
                }
            }
            xhr.send()
        }
        onTriggered: readCpuTemp()
        Component.onCompleted: readCpuTemp()
    }

    Component.onCompleted: {
        getSystemVolume()
    }
    
    // Automatycznie ustaw focus gdy menu się otwiera
    Connections {
        target: sharedData
        function onMenuVisibleChanged() {
            if (sharedData && sharedData.menuVisible) {
                // Automatycznie złap focus po otwarciu (z małym opóźnieniem dla animacji)
                Qt.createQmlObject("import QtQuick; Timer { interval: 100; running: true; repeat: false; onTriggered: { if (topMenuRoot.topMenuContainer) topMenuRoot.topMenuContainer.forceActiveFocus() } }", topMenuRoot)
            } else {
                // Gdy się zamyka, usuń focus
                topMenuContainer.focus = false
            }
        }
    }
}


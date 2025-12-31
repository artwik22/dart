import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Shapes

PanelWindow {
    id: sidePanel
    
    required property var screen
    required property string panelPosition  // "left" or "top" - determines which panel this is
    property string projectPath: ""  // Will be set from environment or auto-detected
    
    screen: sidePanel.screen
    
    // Anchors based on panel position
    anchors.left: panelPosition === "left" ? true : false
    anchors.right: panelPosition === "top" ? true : false
    anchors.top: true
    anchors.bottom: panelPosition === "left" ? true : false
    
    // Dimensions based on panel position
    implicitWidth: panelPosition === "left" ? 36 : (panelPosition === "top" ? (screen ? screen.width : 1920) : 0)
    implicitHeight: panelPosition === "top" ? 36 : (panelPosition === "left" ? (screen ? screen.height : 1080) : 0)
    color: "transparent"
    // Visible only when this panel's position matches the current sidebar position
    visible: (sharedData && sharedData.sidebarVisible !== undefined ? sharedData.sidebarVisible : true) && 
             (sharedData && sharedData.sidebarPosition === panelPosition)
    
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qssidepanel"
    exclusiveZone: (sharedData && sharedData.sidebarVisible !== undefined && sharedData.sidebarVisible && sharedData.sidebarPosition === panelPosition) ? 
        ((panelPosition === "top") ? implicitHeight : implicitWidth) : 0
    
    property var sharedData: null
    
    // Margins based on panel position
    margins {
        left: 0
        top: 0
        bottom: panelPosition === "left" ? 0 : 0
        right: panelPosition === "top" ? 0 : 0

        // Smooth animation when switching panel positions
        Behavior on bottom {
            NumberAnimation {
                duration: 400
                easing.type: Easing.OutCubic
            }
        }
        Behavior on right {
            NumberAnimation {
                duration: 400
                easing.type: Easing.OutCubic
            }
        }
    }
    
    // No global MouseArea needed - individual MouseAreas handle clicks
    
    Rectangle {
        id: sidePanelRect
        anchors.fill: parent
        color: (sharedData && sharedData.colorBackground) ? sharedData.colorBackground : "#0d0d0d"
        radius: 0
        // Ensure this doesn't block mouse events for buttons outside
        enabled: false

        // Smooth fade animation when panel appears/disappears
        opacity: visible ? 1.0 : 0.0
        Behavior on opacity {
            NumberAnimation {
                duration: 300
                easing.type: Easing.OutCubic
            }
        }
        
        // Zegar - layout zależy od pozycji sidebara
        // Pionowy zegar dla pozycji left
        Column {
            id: sidePanelClockColumn
            anchors.top: parent.top
            anchors.topMargin: 14
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 4
            visible: panelPosition === "left"

            // Smooth fade when switching panel positions
            opacity: visible ? 1.0 : 0.0
            Behavior on opacity {
                NumberAnimation {
                    duration: 300
                    easing.type: Easing.OutCubic
                }
            }
            
            Text {
                id: sidePanelHoursDisplay
                text: "00"
                font.pixelSize: 20
                font.family: "JetBrains Mono"
                font.weight: Font.Bold
                color: (sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff"
                horizontalAlignment: Text.AlignHCenter
                
                Behavior on color {
                    ColorAnimation {
                        duration: 280
                        easing.type: Easing.OutQuart
                    }
                }
            }
            
            Text {
                id: sidePanelMinutesDisplay
                text: "00"
                font.pixelSize: 20
                font.family: "JetBrains Mono"
                font.weight: Font.Bold
                color: (sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff"
                horizontalAlignment: Text.AlignHCenter
                
                Behavior on color {
                    ColorAnimation {
                        duration: 280
                        easing.type: Easing.OutQuart
                    }
                }
            }
        }
        
        // Poziomy zegar dla pozycji top
        Row {
            id: sidePanelClockRow
            anchors.left: parent.left
            anchors.leftMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4
            visible: panelPosition === "top"

            // Smooth fade when switching panel positions
            opacity: visible ? 1.0 : 0.0
            Behavior on opacity {
                NumberAnimation {
                    duration: 300
                    easing.type: Easing.OutCubic
                }
            }
            
            Text {
                id: sidePanelHoursDisplayTop
                text: "00"
                font.pixelSize: 20
                font.family: "JetBrains Mono"
                font.weight: Font.Bold
                color: (sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff"
                verticalAlignment: Text.AlignVCenter
                
                Behavior on color {
                    ColorAnimation {
                        duration: 280
                        easing.type: Easing.OutQuart
                    }
                }
            }
            
            Text {
                text: ":"
                font.pixelSize: 20
                font.family: "JetBrains Mono"
                font.weight: Font.Bold
                color: (sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff"
                verticalAlignment: Text.AlignVCenter
            }
            
            Text {
                id: sidePanelMinutesDisplayTop
                text: "00"
                font.pixelSize: 20
                font.family: "JetBrains Mono"
                font.weight: Font.Bold
                color: (sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff"
                verticalAlignment: Text.AlignVCenter
                
                Behavior on color {
                    ColorAnimation {
                        duration: 280
                        easing.type: Easing.OutQuart
                    }
                }
            }
        }
        
        Timer {
            id: sidePanelClockTimer
            interval: 1000
            repeat: true
            running: true
            onTriggered: {
                var now = new Date()
                var h = now.getHours()
                var m = now.getMinutes()
                var hStr = h < 10 ? "0" + h : h.toString()
                var mStr = m < 10 ? "0" + m : m.toString()
                sidePanelHoursDisplay.text = hStr
                sidePanelMinutesDisplay.text = mStr
                sidePanelHoursDisplayTop.text = hStr
                sidePanelMinutesDisplayTop.text = mStr
            }
            Component.onCompleted: {
                var now = new Date()
                var h = now.getHours()
                var m = now.getMinutes()
                var hStr = h < 10 ? "0" + h : h.toString()
                var mStr = m < 10 ? "0" + m : m.toString()
                sidePanelHoursDisplay.text = hStr
                sidePanelMinutesDisplay.text = mStr
                sidePanelHoursDisplayTop.text = hStr
                sidePanelMinutesDisplayTop.text = mStr
            }
        }
        
        // Workspace switcher - pionowy dla pozycji left
        Column {
            id: sidePanelWorkspaceColumn
            spacing: 9
            width: 4
            visible: panelPosition === "left"
            anchors.centerIn: parent
            z: 100  // Higher than visualizer to ensure clicks work
                
                Repeater {
                    model: 4  // Workspaces 1-4
                
                Item {
                    id: workspaceItem
                    width: 4
                    height: workspaceLine.height
                    anchors.horizontalCenter: parent.horizontalCenter
                    
                    property bool isActive: Hyprland.focusedWorkspace ? 
                        Hyprland.focusedWorkspace.id === (index + 1) : false
                    property bool hasWindows: {
                        var ws = Hyprland.workspaces.values.find(w => w.id === (index + 1))
                        return ws ? ws.lastIpcObject.windows > 0 : false
                    }
                    property bool wasActive: false
                    
                    onIsActiveChanged: {
                        if (isActive && !wasActive) {
                            workspaceActivateAnim.restart()
                        }
                        wasActive = isActive
                    }
                    
                    Component.onCompleted: wasActive = isActive
                    
                    // Pionowa linia
                    Rectangle {
                        id: workspaceLine
                        anchors.centerIn: parent
                        width: workspaceItem.isActive ? 4 : 3
                        height: workspaceItem.isActive ? 40 : workspaceItem.hasWindows ? 34 : 30
                        color: workspaceItem.isActive ? 
                            ((sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff") : 
                            workspaceItem.hasWindows ? 
                            ((sharedData && sharedData.colorPrimary) ? sharedData.colorPrimary : "#3a3a3a") : 
                            ((sharedData && sharedData.colorSecondary) ? sharedData.colorSecondary : "#2a2a2a")
                        
                        Behavior on width {
                            NumberAnimation { 
                                duration: 280
                                easing.type: Easing.OutQuart
                            }
                        }
                        
                        Behavior on height {
                            NumberAnimation { 
                                duration: 280
                                easing.type: Easing.OutQuart
                            }
                        }
                        
                        Behavior on color {
                            ColorAnimation { 
                                duration: 280
                                easing.type: Easing.OutQuart
                            }
                        }
                        
                        Behavior on scale {
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
                    }
                    
                    // Animacja aktywacji
                    SequentialAnimation {
                        id: workspaceActivateAnim
                        NumberAnimation {
                            target: workspaceLine
                            property: "scale"
                            from: 0.5
                            to: 1.1
                            duration: 200
                            easing.type: Easing.OutQuart
                        }
                        NumberAnimation {
                            target: workspaceLine
                            property: "scale"
                            to: 1.0
                            duration: 150
                            easing.type: Easing.OutQuart
                        }
                    }
                    
                    MouseArea {
                        id: workspaceMouseArea
                        anchors.fill: parent
                        anchors.margins: -5
                        hoverEnabled: true
                        propagateComposedEvents: false
                        
                        onEntered: {
                            workspaceLine.scale = 1.25
                            workspaceLine.opacity = 1.2
                        }
                        
                        onExited: {
                            workspaceLine.scale = 1.0
                            workspaceLine.opacity = 1.0
                        }
                        
                        onClicked: {
                            workspaceClickAnim.restart()
                            Hyprland.dispatch("workspace", index + 1)
                        }
                    }
                    
                    // Animacja kliknięcia
                    SequentialAnimation {
                        id: workspaceClickAnim
                        NumberAnimation {
                            target: workspaceLine
                            property: "scale"
                            to: 0.7
                            duration: 80
                            easing.type: Easing.InQuad
                        }
                        NumberAnimation {
                            target: workspaceLine
                            property: "scale"
                            to: 1.0
                            duration: 200
                            easing.type: Easing.OutQuart
                        }
                    }
                }
            }
        }
        
        // Workspace switcher - poziomy dla pozycji top
        Row {
            id: sidePanelWorkspaceRow
            spacing: 9
            height: 4
            visible: panelPosition === "top"
            anchors.centerIn: parent
            z: 100  // Higher than visualizer to ensure clicks work
                
            Repeater {
                model: 4  // Workspaces 1-4
                
                Item {
                    id: workspaceItemTop
                    height: 4
                    width: workspaceLineTop.width
                    anchors.verticalCenter: parent.verticalCenter
                    
                    property bool isActive: Hyprland.focusedWorkspace ? 
                        Hyprland.focusedWorkspace.id === (index + 1) : false
                    property bool hasWindows: {
                        var ws = Hyprland.workspaces.values.find(w => w.id === (index + 1))
                        return ws ? ws.lastIpcObject.windows > 0 : false
                    }
                    property bool wasActive: false
                    
                    onIsActiveChanged: {
                        if (isActive && !wasActive) {
                            workspaceActivateAnimTop.restart()
                        }
                        wasActive = isActive
                    }
                    
                    Component.onCompleted: wasActive = isActive
                    
                    // Pozioma linia
                    Rectangle {
                        id: workspaceLineTop
                        anchors.centerIn: parent
                        height: workspaceItemTop.isActive ? 4 : 3
                        width: workspaceItemTop.isActive ? 40 : workspaceItemTop.hasWindows ? 34 : 30
                        color: workspaceItemTop.isActive ? 
                            ((sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff") : 
                            workspaceItemTop.hasWindows ? 
                            ((sharedData && sharedData.colorPrimary) ? sharedData.colorPrimary : "#3a3a3a") : 
                            ((sharedData && sharedData.colorSecondary) ? sharedData.colorSecondary : "#2a2a2a")
                        radius: 0
                        
                        Behavior on width {
                            NumberAnimation { 
                                duration: 280
                                easing.type: Easing.OutQuart
                            }
                        }
                        
                        Behavior on height {
                            NumberAnimation { 
                                duration: 280
                                easing.type: Easing.OutQuart
                            }
                        }
                        
                        Behavior on color {
                            ColorAnimation { 
                                duration: 280
                                easing.type: Easing.OutQuart
                            }
                        }
                        
                        Behavior on scale {
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
                    }
                    
                    // Animacja aktywacji
                    SequentialAnimation {
                        id: workspaceActivateAnimTop
                        NumberAnimation {
                            target: workspaceLineTop
                            property: "scale"
                            from: 0.5
                            to: 1.1
                            duration: 200
                            easing.type: Easing.OutQuart
                        }
                        NumberAnimation {
                            target: workspaceLineTop
                            property: "scale"
                            to: 1.0
                            duration: 150
                            easing.type: Easing.OutQuart
                        }
                    }
                    
                    MouseArea {
                        id: workspaceMouseAreaTop
                        anchors.fill: parent
                        anchors.margins: -5
                        hoverEnabled: true
                        propagateComposedEvents: false
                        
                        onEntered: {
                            workspaceLineTop.scale = 1.25
                            workspaceLineTop.opacity = 1.2
                        }
                        
                        onExited: {
                            workspaceLineTop.scale = 1.0
                            workspaceLineTop.opacity = 1.0
                        }
                        
                        onClicked: {
                            workspaceClickAnimTop.restart()
                            Hyprland.dispatch("workspace", index + 1)
                        }
                    }
                    
                    // Animacja kliknięcia
                    SequentialAnimation {
                        id: workspaceClickAnimTop
                        NumberAnimation {
                            target: workspaceLineTop
                            property: "scale"
                            to: 0.7
                            duration: 80
                            easing.type: Easing.InQuad
                        }
                        NumberAnimation {
                            target: workspaceLineTop
                            property: "scale"
                            to: 1.0
                            duration: 200
                            easing.type: Easing.OutQuart
                        }
                    }
                }
            }
        }
        
        // Music Visualizer - PIONOWY dla pozycji left
        Column {
            id: musicVisualizerColumn
            spacing: 2
            width: 24  // Szerokość pasków
            visible: panelPosition === "left"
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 270  // Above buttons but not at the very top
            z: 0  // Lower z-order to ensure buttons are clickable

            // Smooth fade when switching panel positions
            opacity: visible ? 1.0 : 0.0
            Behavior on opacity {
                NumberAnimation {
                    duration: 300
                    easing.type: Easing.OutCubic
                }
            }
            
            // MouseArea to pass through mouse events - don't block clicks
            MouseArea {
                anchors.fill: parent
                enabled: false  // Don't capture events, just pass them through
                z: -1
            }
            
            Repeater {
                id: visualizerBarsRepeater
                model: 36  // 36 pasków pionowo - 3x dłuższy visualizer
                
                Rectangle {
                    id: visualizerBar
                    height: 3  // Grubość paska
                    width: Math.max(3, visualizerBarValue)  // Szerokość zależy od audio
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff"
                    radius: 0
                    visible: true
                    
                    property real visualizerBarValue: 5  // Start z widoczną szerokością
                    
                    Behavior on width {
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
        
        // Music Visualizer - POZIOMY dla pozycji top
        Row {
            id: musicVisualizerRow
            spacing: 2
            height: 24  // Wysokość pasków
            visible: panelPosition === "top"
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: 100  // Space for buttons on right (moved above buttons)
            z: 1

            // Smooth fade when switching panel positions
            opacity: visible ? 1.0 : 0.0
            Behavior on opacity {
                NumberAnimation {
                    duration: 300
                    easing.type: Easing.OutCubic
                }
            }
            
            // MouseArea to pass through mouse events - don't block clicks
            MouseArea {
                anchors.fill: parent
                enabled: false  // Don't capture events, just pass them through
                z: -1
            }
            
            Repeater {
                id: visualizerBarsRepeaterTop
                model: 36  // 36 pasków poziomo
                
                Rectangle {
                    id: visualizerBarTop
                    width: 3  // Grubość paska
                    height: Math.max(3, visualizerBarValueTop)  // Wysokość zależy od audio
                    anchors.verticalCenter: parent.verticalCenter
                    color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff"
                    radius: 0
                    visible: true
                    
                    property real visualizerBarValueTop: 5  // Start z widoczną wysokością
                    
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
        
    }
    
    // Screenshot Button - OUTSIDE sidePanelRect to ensure it's clickable
    Item {
        id: screenshotButtonContainer
        width: 32
        height: 32

        anchors.horizontalCenter: panelPosition === "left" ? parent.horizontalCenter : undefined
        anchors.right: panelPosition === "top" ? parent.right : undefined
        anchors.rightMargin: panelPosition === "top" ? 48 : 0
        anchors.bottom: panelPosition === "left" ? parent.bottom : undefined
        anchors.bottomMargin: panelPosition === "left" ? 10 : 0
        z: 10000  // Very high z to ensure it's on top of everything
        visible: true
        enabled: true

        // Smooth repositioning when panel position changes
        Behavior on anchors.rightMargin {
            NumberAnimation {
                duration: 400
                easing.type: Easing.OutCubic
            }
        }
        Behavior on anchors.bottomMargin {
            NumberAnimation {
                duration: 400
                easing.type: Easing.OutCubic
            }
        }
        
        Rectangle {
            id: screenshotButton
            width: 24
            height: 24
            anchors.centerIn: parent
            radius: 0
            color: screenshotButtonMouseArea.containsMouse ?
                "#ff4444" :
                ((sharedData && sharedData.colorSecondary) ? sharedData.colorSecondary : "#444444")
            
            property real buttonScale: screenshotButtonMouseArea.pressed ? 0.9 : (screenshotButtonMouseArea.containsMouse ? 1.1 : 1.0)
            
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
                text: "󰹑"  // Camera/screenshot icon (Nerd Fonts)
                font.pixelSize: 14
                anchors.centerIn: parent
                color: screenshotButtonMouseArea.containsMouse ? 
                    ((sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff") : 
                    ((sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff")
                
                Behavior on color {
                    ColorAnimation {
                        duration: 200
                        easing.type: Easing.OutQuart
                    }
                }
            }
        }
        
        MouseArea {
            id: screenshotButtonMouseArea
            anchors.fill: parent
            anchors.margins: -10  // Much larger hit area
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            enabled: true
            propagateComposedEvents: false
            acceptedButtons: Qt.LeftButton
            z: 10001
            
            onClicked: {
                console.log("=== SCREENSHOT BUTTON CLICKED ===")
                console.log("Panel position:", panelPosition)
                console.log("Container size:", screenshotButtonContainer.width, "x", screenshotButtonContainer.height)
                console.log("Container position:", screenshotButtonContainer.x, ",", screenshotButtonContainer.y)
                if (screenshotFunction) {
                    screenshotFunction()
                } else {
                    console.log("screenshotFunction is null!")
                }
            }

            onPressed: {
                console.log("Screenshot button pressed")
            }

            onEntered: {
                console.log("Mouse entered screenshot button")
            }
        }
    }
    
    // Clipboard Manager Button - OUTSIDE sidePanelRect to ensure it's clickable
    Item {
        id: clipboardButtonContainer
        width: 32
        height: 32
        anchors.horizontalCenter: panelPosition === "left" ? parent.horizontalCenter : undefined
        anchors.right: panelPosition === "top" ? parent.right : undefined
        anchors.rightMargin: panelPosition === "top" ? 8 : 0
        anchors.bottom: panelPosition === "left" ? parent.bottom : undefined
        anchors.bottomMargin: panelPosition === "left" ? 45 : 0
        z: 10000  // Very high z to ensure it's on top of everything
        visible: true
        enabled: true

        // Smooth repositioning when panel position changes
        Behavior on anchors.rightMargin {
            NumberAnimation {
                duration: 400
                easing.type: Easing.OutCubic
            }
        }
        Behavior on anchors.bottomMargin {
            NumberAnimation {
                duration: 400
                easing.type: Easing.OutCubic
            }
        }
        
        Rectangle {
            id: clipboardButton
            width: 24
            height: 24
            anchors.centerIn: parent
            radius: 0
            color: clipboardButtonMouseArea.containsMouse ? 
                ((sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff") : 
                ((sharedData && sharedData.colorSecondary) ? sharedData.colorSecondary : "#141414")
            
            property real buttonScale: clipboardButtonMouseArea.pressed ? 0.9 : (clipboardButtonMouseArea.containsMouse ? 1.1 : 1.0)
            
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
                text: "󰨸"
                font.pixelSize: 14
                anchors.centerIn: parent
                color: clipboardButtonMouseArea.containsMouse ? 
                    ((sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff") : 
                    ((sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff")
                
                Behavior on color {
                    ColorAnimation {
                        duration: 200
                        easing.type: Easing.OutQuart
                    }
                }
            }
        }
        
        MouseArea {
            id: clipboardButtonMouseArea
            anchors.fill: parent
            anchors.margins: -10  // Much larger hit area
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            enabled: true
            propagateComposedEvents: false
            acceptedButtons: Qt.LeftButton
            z: 10001
            
            onPressed: {
                console.log("Clipboard button pressed - MouseArea received press event")
            }
            
            onClicked: {
                console.log("=== CLIPBOARD BUTTON CLICKED ===")
                console.log("Panel position:", panelPosition)
                console.log("Container size:", clipboardButtonContainer.width, "x", clipboardButtonContainer.height)
                console.log("Container position:", clipboardButtonContainer.x, ",", clipboardButtonContainer.y)
                if (clipboardFunction) {
                    clipboardFunction()
                } else {
                    console.log("clipboardFunction is null!")
                }
            }
            
            onEntered: {
                console.log("Clipboard button hover entered - MouseArea received enter event")
            }
            
            onExited: {
                console.log("Clipboard button hover exited")
            }
        }
    }
    
    // Opcjonalne funkcje callback
    property var settingsFunction
    property var launcherFunction
    property var clipboardFunction
    property var screenshotFunction
    
    // --- Music Visualizer ---
    property var cavaValues: []
    property bool cavaRunning: false
    
    function startCava() {
        // Sprawdź czy cava jest zainstalowane
        Qt.createQmlObject("import Quickshell.Io; import QtQuick; Process { command: ['sh','-c','which cava > /dev/null 2>&1 && echo 1 > /tmp/quickshell_cava_available || echo 0 > /tmp/quickshell_cava_available']; running: true }", sidePanel)
        
        // Poczekaj i sprawdź dostępność
        Qt.createQmlObject("import QtQuick; Timer { interval: 200; running: true; repeat: false; onTriggered: sidePanel.checkCavaAvailable() }", sidePanel)
    }
    
    function checkCavaAvailable() {
        var xhr = new XMLHttpRequest()
        xhr.open("GET", "file:///tmp/quickshell_cava_available")
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                var available = xhr.responseText.trim() === "1"
                console.log("Cava available:", available, "cavaRunning:", cavaRunning)
                if (available && !cavaRunning) {
                    // Użyj skryptu start-cava.sh do uruchomienia cava z poprawną konfiguracją
                    // Use projectPath if available, otherwise try to detect
                    var scriptPath = (projectPath && projectPath.length > 0) ? (projectPath + "/scripts/start-cava.sh") : ""
                    if (!scriptPath || scriptPath === "/scripts/start-cava.sh") {
                        // Try to get from environment or use relative path
                        Qt.createQmlObject("import Quickshell.Io; import QtQuick; Process { command: ['sh', '-c', 'echo \"$QUICKSHELL_PROJECT_PATH\" > /tmp/quickshell_cava_path 2>/dev/null || echo \"\" > /tmp/quickshell_cava_path']; running: true }", sidePanel)
                        Qt.createQmlObject("import QtQuick; Timer { interval: 100; running: true; repeat: false; onTriggered: sidePanel.readCavaPath() }", sidePanel)
                        return
                    }
                    if (!scriptPath || scriptPath.length === 0 || scriptPath === "/scripts/start-cava.sh") {
                        console.log("Invalid script path for cava:", scriptPath)
                        return
                    }
                    var absScriptPath = scriptPath
                    Qt.createQmlObject('import Quickshell.Io; import QtQuick; Process { command: ["bash", "' + absScriptPath + '"]; running: true }', sidePanel)
                    
                    cavaRunning = true
                    console.log("Cava started with script...")
                    Qt.createQmlObject("import QtQuick; Timer { interval: 500; running: true; repeat: false; onTriggered: sidePanel.readCavaData() }", sidePanel)
                }
            }
        }
        xhr.send()
    }
    
    function readCavaData() {
        // Bezpośredni odczyt z pliku (awk nadpisuje go dla każdej klatki)
        var xhr = new XMLHttpRequest()
        xhr.open("GET", "file:///tmp/quickshell_cava")
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status !== 200 && xhr.status !== 0) {
                    // File not accessible, try to restart cava
                    if (cavaRunning) {
                        console.log("Cava file not accessible, status:", xhr.status)
                        cavaRunning = false
                        startCava()
                    }
                    return
                }
                var data = xhr.responseText
                if (data && data.length > 0) {
                    // Remove any trailing semicolons and split
                    var cleanData = data.trim().replace(/;+$/, '')
                    var values = cleanData.split(";")
                    
                    // Ensure we have at least some values
                    if (values.length > 0) {
                        // Use sharedData colors if available - wszystkie odcienie z theme
                        var colorAccent = (sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff"
                        var colorText = (sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff"
                        var colorPrimary = (sharedData && sharedData.colorPrimary) ? sharedData.colorPrimary : "#3a3a3a"
                        var colorSecondary = (sharedData && sharedData.colorSecondary) ? sharedData.colorSecondary : "#2a2a2a"
                        
                        for (var i = 0; i < 36; i++) {
                            var val = 0
                            if (i < values.length && values[i]) {
                                val = parseInt(values[i]) || 0
                            }
                            var normalizedWidth = Math.max(3, (val / 100) * 24)
                            var normalizedHeight = Math.max(3, (val / 100) * 24)
                            var intensity = val / 100
                            
                            // Update vertical visualizer (for left position)
                            if (visualizerBarsRepeater.itemAt(i)) {
                                visualizerBarsRepeater.itemAt(i).visualizerBarValue = normalizedWidth
                                if (intensity > 0.7) {
                                    // Najwyższe wartości - accent color (najjaśniejszy, kolorowy)
                                    visualizerBarsRepeater.itemAt(i).color = colorAccent
                                } else if (intensity > 0.4) {
                                    // Średnie wartości - text color (jasny)
                                    visualizerBarsRepeater.itemAt(i).color = colorText
                                } else if (intensity > 0.1) {
                                    // Niskie wartości - primary color (średni)
                                    visualizerBarsRepeater.itemAt(i).color = colorPrimary
                                } else {
                                    // Bardzo niskie wartości - secondary color (ciemniejszy)
                                    visualizerBarsRepeater.itemAt(i).color = colorSecondary
                                }
                            }
                            
                            // Update horizontal visualizer (for top position)
                            if (visualizerBarsRepeaterTop.itemAt(i)) {
                                visualizerBarsRepeaterTop.itemAt(i).visualizerBarValueTop = normalizedHeight
                                if (intensity > 0.7) {
                                    visualizerBarsRepeaterTop.itemAt(i).color = colorAccent
                                } else if (intensity > 0.4) {
                                    visualizerBarsRepeaterTop.itemAt(i).color = colorText
                                } else if (intensity > 0.1) {
                                    visualizerBarsRepeaterTop.itemAt(i).color = colorPrimary
                                } else {
                                    visualizerBarsRepeaterTop.itemAt(i).color = colorSecondary
                                }
                            }
                        }
                    }
                } else {
                    // No data, silently continue - cavaCheckTimer will handle restart if needed
                    // Removed frequent logging to reduce console spam
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
    
    // Timer do sprawdzania czy cava działa (fallback)
    Timer {
        id: cavaCheckTimer
        interval: 5000  // Co 5 sekund
        repeat: true
        running: true
        onTriggered: {
            if (cavaRunning) {
                // Sprawdź czy plik istnieje i ma dane
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
                // Spróbuj ponownie uruchomić cava
                startCava()
            }
        }
    }
    
    // Timer do inicjalizacji visualizera
    Timer {
        id: visualizerInitTimer
        interval: 100
        running: false
        repeat: false
        onTriggered: {
            // Ustaw minimalne wartości dla pasków, żeby były widoczne od razu
            for (var i = 0; i < 36; i++) {
                var value = 5 + (i % 3) * 3  // Różne wartości dla testu
                if (visualizerBarsRepeater.itemAt(i)) {
                    visualizerBarsRepeater.itemAt(i).visualizerBarValue = value
                }
                if (visualizerBarsRepeaterTop.itemAt(i)) {
                    visualizerBarsRepeaterTop.itemAt(i).visualizerBarValueTop = value
                }
            }
        }
    }
    
    // Load project path from environment
    function loadProjectPath() {
        // Try to read path from environment variable
        Qt.createQmlObject("import Quickshell.Io; import QtQuick; Process { command: ['sh', '-c', 'echo \"$QUICKSHELL_PROJECT_PATH\" > /tmp/quickshell_sidepanel_path 2>/dev/null || echo \"\" > /tmp/quickshell_sidepanel_path']; running: true }", sidePanel)
        Qt.createQmlObject("import QtQuick; Timer { interval: 100; running: true; repeat: false; onTriggered: sidePanel.readProjectPath() }", sidePanel)
    }
    
    function readProjectPath() {
        var xhr = new XMLHttpRequest()
        xhr.open("GET", "file:///tmp/quickshell_sidepanel_path")
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                var path = xhr.responseText.trim()
                if (path && path.length > 0) {
                    projectPath = path
                    console.log("SidePanel project path loaded:", projectPath)
                    // Start cava after path is loaded
                    startCava()
                } else {
                    // Fallback to default
                    projectPath = "/tmp/sharpshell"
                    console.log("SidePanel using fallback project path:", projectPath)
                    startCava()
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
                    console.log("SidePanel project path loaded from cava path:", projectPath)
                    // Retry starting cava
                    startCava()
                } else {
                    // Fallback
                    projectPath = "/tmp/sharpshell"
                    console.log("SidePanel using fallback project path (from readCavaPath):", projectPath)
                    startCava()
                }
            }
        }
        xhr.send()
    }
    
    Component.onCompleted: {
        // Uruchom inicjalizację visualizera
        visualizerInitTimer.start()
        // Load project path first, then start cava
        loadProjectPath()
    }
}


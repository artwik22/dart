import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Shapes

PanelWindow {
    id: sidePanel
    
    required property var screen
    required property string panelPosition  // "left" or "top" - determines which panel this is
<<<<<<< HEAD
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
=======
    property var primaryScreen: null  // Tylko ten ekran uruchamia cava/zegar – unika zacinków przy 2+ monitorach
    property string projectPath: ""  // Set from root (shell) or via loadProjectPath
    onProjectPathChanged: { if (projectPath && projectPath.length > 0 && isPrimaryPanel && !cavaRunning && !(sharedData && sharedData.lowPerformanceMode)) startCava() }

    // Helper property to determine orientation
    property bool isHorizontal: panelPosition === "top" || panelPosition === "bottom"
    
    // Anchors based on panel position
    anchors.left: panelPosition === "right" ? false : true
    anchors.right: panelPosition === "left" ? false : true
    anchors.top: panelPosition === "bottom" ? false : true
    anchors.bottom: panelPosition === "top" ? false : true
    
    // Dimensions based on panel position (33px – 70% scale)
    implicitWidth: !isHorizontal ? 33 : (screen ? screen.width : 2160)
    implicitHeight: isHorizontal ? 33 : (screen ? screen.height : 1440)
    color: "transparent"
    property var sharedData: null

    // --- Animacja wejścia/wyjścia (bez glitchy) ---
    // Gdy okno jest fullscreen (Hyprland), sidebar się chowa – sidebarHiddenByFullscreen ustawiane w shell.qml
    property bool panelActive: !!(sharedData && (sharedData.sidebarVisible === undefined || sharedData.sidebarVisible) && sharedData.sidebarPosition === panelPosition && !(sharedData.sidebarHiddenByFullscreen === true))
    property real panelProgress: panelActive ? 1.0 : 0.0
    Behavior on panelProgress {
        NumberAnimation { duration: 350; easing.type: Easing.OutBack }
    }
    visible: panelProgress > 0.01
    exclusiveZone: panelProgress * (isHorizontal ? implicitHeight : implicitWidth)

    property bool isPrimaryPanel: (primaryScreen === null || primaryScreen === undefined || (screen && primaryScreen && screen.name === primaryScreen.name)) && panelActive

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qssidepanel-" + (panelPosition || "left") + "-" + (screen && screen.name ? screen.name : "0")
>>>>>>> master
    
    // Margins based on panel position
    margins {
        left: 0
        top: 0
<<<<<<< HEAD
        bottom: panelPosition === "left" ? 0 : 0
        right: panelPosition === "top" ? 0 : 0
=======
        bottom: 0
        right: 0
>>>>>>> master

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
    
    // Background Rectangle - separate from buttons to avoid blocking clicks
<<<<<<< HEAD
    Rectangle {
        id: sidePanelRect
        anchors.fill: parent
        color: (sharedData && sharedData.colorBackground) ? sharedData.colorBackground : "#0d0d0d"
        radius: 0
        enabled: false  // Don't capture mouse events - allows clicks to pass through
        z: -1  // Put background behind everything to ensure buttons are clickable
        
        // Smooth fade animation when panel appears/disappears
        opacity: sidePanel.visible ? 1.0 : 0.0
        Behavior on opacity {
            NumberAnimation {
                duration: 300
                easing.type: Easing.OutCubic
            }
        }
    }
    
=======
    // Material Design background with elevation shadow - NOWY DESIGN
    Rectangle {
        id: sidePanelRect
        anchors.fill: parent
        // Premium Gradient Background
        gradient: Gradient {
            orientation: !isHorizontal ? Gradient.Vertical : Gradient.Horizontal
            GradientStop { 
                position: 0.0
                color: (sharedData && sharedData.colorBackground) ? sharedData.colorBackground : "#0d0d0d"
            }
            GradientStop { 
                position: 1.0
                color: (sharedData && sharedData.colorSecondary) ? sharedData.colorSecondary : "#151515"
            }
        }
        radius: 0
        enabled: false  // Don't capture mouse events
        z: -1
        

        
        opacity: sidePanel.panelProgress
        Behavior on opacity {
            NumberAnimation { duration: 350; easing.type: Easing.OutCubic }
        }
        transform: Translate {
            x: panelPosition === "left" && !panelActive ? -implicitWidth : 
               (panelPosition === "right" && !panelActive ? implicitWidth : 0)
            y: panelPosition === "top" && !panelActive ? -implicitHeight : 
               (panelPosition === "bottom" && !panelActive ? implicitHeight : 0)

            Behavior on x { NumberAnimation { duration: 450; easing.type: Easing.OutCubic } }
            Behavior on y { NumberAnimation { duration: 450; easing.type: Easing.OutCubic } }
        }
    }

>>>>>>> master
    // Container for all sidebar content (clock, workspace switcher, visualizer)
    Item {
        id: sidePanelContent
        anchors.fill: parent
        enabled: true  // Must be enabled for MouseArea inside to work
        z: 0  // Above background but below buttons (z: 10000)
        clip: false  // Don't clip children (buttons are outside)
        
        // Zegar - layout zależy od pozycji sidebara
        // Pionowy zegar dla pozycji left
        Column {
            id: sidePanelClockColumn
            anchors.top: parent.top
<<<<<<< HEAD
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
=======
            anchors.topMargin: 6
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 4
            visible: !isHorizontal

            // Smooth fade when switching panel positions
            opacity: visible && panelActive ? 1.0 : 0.0
            scale: panelActive ? 1.0 : 0.85
            
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
            transform: Translate {
                x: panelPosition === "left" && !panelActive ? -40 :
                   (panelPosition === "right" && !panelActive ? 40 : 0)
                y: panelPosition === "top" && !panelActive ? -40 :
                   (panelPosition === "bottom" && !panelActive ? 40 : 0)

                Behavior on x {
                    SequentialAnimation {
                        PauseAnimation { duration: 50 }
                        NumberAnimation { duration: 700; easing.type: Easing.OutBack }
                    }
                }
                Behavior on y {
                    SequentialAnimation {
                        PauseAnimation { duration: 50 }
                        NumberAnimation { duration: 700; easing.type: Easing.OutBack }
                    }
>>>>>>> master
                }
            }
            
            Text {
                id: sidePanelHoursDisplay
                text: "00"
<<<<<<< HEAD
                font.pixelSize: 20
                font.family: "sans-serif"
                font.weight: Font.Bold
=======
                font.pixelSize: 26
                font.family: "sans-serif"
                font.weight: Font.Black
>>>>>>> master
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
<<<<<<< HEAD
                font.pixelSize: 20
                font.family: "sans-serif"
                font.weight: Font.Bold
=======
                font.pixelSize: 26
                font.family: "sans-serif"
                font.weight: Font.Black
>>>>>>> master
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
<<<<<<< HEAD
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
=======
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4
            visible: isHorizontal

            // Smooth fade when switching panel positions
            opacity: visible && panelActive ? 1.0 : 0.0
            scale: panelActive ? 1.0 : 0.85
            
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
            transform: Translate {
                x: panelPosition === "left" && !panelActive ? -40 :
                   (panelPosition === "right" && !panelActive ? 40 : 0)
                y: panelPosition === "top" && !panelActive ? -40 :
                   (panelPosition === "bottom" && !panelActive ? 40 : 0)

                Behavior on x {
                    SequentialAnimation {
                        PauseAnimation { duration: 50 }
                        NumberAnimation { duration: 700; easing.type: Easing.OutBack }
                    }
                }
                Behavior on y {
                    SequentialAnimation {
                        PauseAnimation { duration: 50 }
                        NumberAnimation { duration: 700; easing.type: Easing.OutBack }
                    }
>>>>>>> master
                }
            }
            
            Text {
                id: sidePanelHoursDisplayTop
                text: "00"
<<<<<<< HEAD
                font.pixelSize: 20
                font.family: "sans-serif"
                font.weight: Font.Bold
=======
                font.pixelSize: 24
                font.family: "sans-serif"
                font.weight: Font.Black
>>>>>>> master
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
<<<<<<< HEAD
                font.pixelSize: 20
                font.family: "sans-serif"
                font.weight: Font.Bold
=======
                font.pixelSize: 24
                font.family: "sans-serif"
                font.weight: Font.Black
>>>>>>> master
                color: (sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff"
                verticalAlignment: Text.AlignVCenter
            }
            
            Text {
                id: sidePanelMinutesDisplayTop
                text: "00"
<<<<<<< HEAD
                font.pixelSize: 20
                font.family: "sans-serif"
                font.weight: Font.Bold
=======
                font.pixelSize: 24
                font.family: "sans-serif"
                font.weight: Font.Black
>>>>>>> master
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
<<<<<<< HEAD
            running: true
=======
            running: isPrimaryPanel
>>>>>>> master
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
        Item {
            id: sidePanelWorkspaceColumnContainer
<<<<<<< HEAD
            width: 8
            height: parent.height
            visible: panelPosition === "left"
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            z: 50  // Lower than buttons (z: 10000) to not block clicks
            
            Column {
                id: sidePanelWorkspaceColumn
                spacing: 9
=======
            width: parent.width
            height: parent.height
            visible: !isHorizontal
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            z: 50  // Lower than buttons (z: 10000) to not block clicks

            opacity: panelActive ? 1.0 : 0.0
            scale: panelActive ? 1.0 : 0.85

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
            transform: Translate {
                x: panelPosition === "left" && !panelActive ? -40 :
                   (panelPosition === "right" && !panelActive ? 40 : 0)

                Behavior on x {
                    SequentialAnimation {
                        PauseAnimation { duration: 100 }
                        NumberAnimation { duration: 700; easing.type: Easing.OutBack }
                    }
                }
            }
            
            Column {
                id: sidePanelWorkspaceColumn
                spacing: 12
>>>>>>> master
                width: parent.width
                x: (parent.width - width) / 2
                y: (parent.height - height) / 2
                
                Repeater {
                    model: 4  // Workspaces 1-4
                
<<<<<<< HEAD
                Item {
                    id: workspaceItem
                    width: 8  // Większa szerokość tylko dla MouseArea
=======
                    Item {
                    id: workspaceItem
                    width: parent.width
>>>>>>> master
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
                    
<<<<<<< HEAD
                    // Pionowa linia z lepszymi wskaźnikami
                    Rectangle {
                        id: workspaceLine
                        anchors.centerIn: parent
                        width: workspaceItem.isActive ? 5 : (workspaceItem.hasWindows ? 3.5 : 3)
                        height: workspaceItem.isActive ? 45 : (workspaceItem.hasWindows ? 36 : 30)
                        color: workspaceItem.isActive ? 
                            ((sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff") : 
                            workspaceItem.hasWindows ? 
                            ((sharedData && sharedData.colorPrimary) ? sharedData.colorPrimary : "#3a3a3a") : 
                            ((sharedData && sharedData.colorSecondary) ? sharedData.colorSecondary : "#2a2a2a")
                        radius: 0
                        opacity: workspaceItem.isActive ? 1.0 : (workspaceItem.hasWindows ? 0.8 : 0.5)
                        
                        Behavior on width {
                            NumberAnimation { 
                                duration: 400
                                easing.type: Easing.OutCubic
                            }
                        }
                        
                        Behavior on height {
                            NumberAnimation { 
                                duration: 400
                                easing.type: Easing.OutCubic
=======
                    // Bar Indicator - Abstract Style
                    Rectangle {
                        id: workspaceLine
                        anchors.centerIn: parent
                        width: workspaceItem.isActive ? 3 : (workspaceItem.hasWindows ? 3 : 3)
                        height: workspaceItem.isActive ? 64 : (workspaceItem.hasWindows ? 32 : 16)
                        radius: 0
                        
                        color: workspaceItem.isActive ? 
                            ((sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff") : 
                            workspaceItem.hasWindows ? 
                            ((sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff") : 
                            ((sharedData && sharedData.colorSubtext) ? sharedData.colorSubtext : "#666666")
                            
                        opacity: workspaceItem.isActive ? 1.0 : (workspaceItem.hasWindows ? 0.8 : 0.4)
                        
                        Behavior on height {
                            NumberAnimation { 
                                duration: 300
                                easing.type: Easing.OutBack
>>>>>>> master
                            }
                        }
                        
                        Behavior on color {
<<<<<<< HEAD
                            ColorAnimation { 
                                duration: 400
                                easing.type: Easing.OutCubic
                            }
=======
                            ColorAnimation { duration: 200 }
>>>>>>> master
                        }
                        
                        Behavior on opacity {
                            NumberAnimation { 
                                duration: 400
                                easing.type: Easing.OutCubic
                            }
                        }
                        
                        Behavior on scale {
                            NumberAnimation { 
                                duration: 300
                                easing.type: Easing.OutCubic
                            }
                        }
                    }
                    
                    // Animacja aktywacji - płynniejsza
                    SequentialAnimation {
                        id: workspaceActivateAnim
                        ParallelAnimation {
                            NumberAnimation {
                                target: workspaceLine
                                property: "scale"
                                from: 0.6
                                to: 1.15
                                duration: 300
                                easing.type: Easing.OutCubic
                            }
                            NumberAnimation {
                                target: workspaceLine
                                property: "opacity"
                                from: 0.5
                                to: 1.0
                                duration: 300
                                easing.type: Easing.OutCubic
                            }
                        }
                        NumberAnimation {
                            target: workspaceLine
                            property: "scale"
                            to: 1.0
                            duration: 250
                            easing.type: Easing.OutCubic
                        }
                    }
                    
                    MouseArea {
                        id: workspaceMouseArea
<<<<<<< HEAD
                        anchors.fill: workspaceLine  // Tylko w obszarze workspace line, nie całego item
                        anchors.margins: -2  // Mały margines tylko dla łatwiejszego klikania
=======
                        anchors.fill: workspaceLine
                        anchors.margins: -5
>>>>>>> master
                        hoverEnabled: true
                        propagateComposedEvents: true  // Pozwól na propagację zdarzeń poza workspace
                        z: 1  // Very low z to ensure buttons (z: 10000) are on top
                        acceptedButtons: Qt.LeftButton
                        
                        onEntered: {
                            if (!workspaceItem.isActive) {
<<<<<<< HEAD
                                workspaceLine.scale = 1.2
                                workspaceLine.opacity = Math.min(workspaceLine.opacity + 0.2, 1.0)
=======
                                workspaceLine.scale = 1.15
                                workspaceLine.opacity = Math.min(workspaceLine.opacity + 0.15, 1.0)
>>>>>>> master
                            }
                        }
                        
                        onExited: {
                            if (!workspaceItem.isActive) {
                                workspaceLine.scale = 1.0
<<<<<<< HEAD
                                workspaceLine.opacity = workspaceItem.hasWindows ? 0.8 : 0.5
=======
                                workspaceLine.opacity = workspaceItem.hasWindows ? 0.9 : 0.7
>>>>>>> master
                            }
                        }
                        
                        onClicked: {
                            workspaceClickAnim.restart()
                            Hyprland.dispatch("workspace", index + 1)
                        }
                    }
                    
                    // Animacja kliknięcia - płynniejsza
                    SequentialAnimation {
                        id: workspaceClickAnim
                        NumberAnimation {
                            target: workspaceLine
                            property: "scale"
                            to: 0.75
                            duration: 100
                            easing.type: Easing.InCubic
                        }
                        NumberAnimation {
                            target: workspaceLine
                            property: "scale"
                            to: 1.0
                            duration: 300
                            easing.type: Easing.OutCubic
                        }
                    }
                }
                }
            }
        }
        
        // Workspace switcher - poziomy dla pozycji top
        Item {
            id: sidePanelWorkspaceRowContainer
            width: parent.width
<<<<<<< HEAD
            height: 8
            visible: panelPosition === "top"
=======
            height: parent.height
            visible: isHorizontal
>>>>>>> master
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            z: 50  // Lower than buttons (z: 10000) to not block clicks
            
            Row {
                id: sidePanelWorkspaceRow
<<<<<<< HEAD
                spacing: 9
=======
                spacing: 12
>>>>>>> master
                height: parent.height
                x: (parent.width - width) / 2
                y: (parent.height - height) / 2
                
<<<<<<< HEAD
=======
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
                opacity: panelActive ? 1.0 : 0.0
                scale: panelActive ? 1.0 : 0.85
                transform: Translate {
                    y: panelPosition === "top" && !panelActive ? -40 :
                       (panelPosition === "bottom" && !panelActive ? 40 : 0)

                    Behavior on y {
                        SequentialAnimation {
                            PauseAnimation { duration: 100 }
                            NumberAnimation { duration: 700; easing.type: Easing.OutBack }
                        }
                    }
                }
                
>>>>>>> master
                Repeater {
                    model: 4  // Workspaces 1-4
                
                    Item {
                        id: workspaceItemTop
<<<<<<< HEAD
                        height: 8  // Większa wysokość tylko dla MouseArea
=======
                        height: parent.height
>>>>>>> master
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
                    
<<<<<<< HEAD
                    // Pozioma linia z lepszymi wskaźnikami
                    Rectangle {
                        id: workspaceLineTop
                        anchors.centerIn: parent
                        height: workspaceItemTop.isActive ? 5 : (workspaceItemTop.hasWindows ? 3.5 : 3)
                        width: workspaceItemTop.isActive ? 45 : (workspaceItemTop.hasWindows ? 36 : 30)
                        color: workspaceItemTop.isActive ? 
                            ((sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff") : 
                            workspaceItemTop.hasWindows ? 
                            ((sharedData && sharedData.colorPrimary) ? sharedData.colorPrimary : "#3a3a3a") : 
                            ((sharedData && sharedData.colorSecondary) ? sharedData.colorSecondary : "#2a2a2a")
                        radius: 0
                        opacity: workspaceItemTop.isActive ? 1.0 : (workspaceItemTop.hasWindows ? 0.8 : 0.5)
                        
                        Behavior on width {
                            NumberAnimation { 
                                duration: 400
                                easing.type: Easing.OutCubic
                            }
                        }
                        
                        Behavior on height {
                            NumberAnimation { 
                                duration: 400
                                easing.type: Easing.OutCubic
=======
                    // Bar Indicator Horizontal - Abstract Style
                    Rectangle {
                        id: workspaceLineTop
                        anchors.centerIn: parent
                        height: workspaceItemTop.isActive ? 3 : (workspaceItemTop.hasWindows ? 3 : 3)
                        width: workspaceItemTop.isActive ? 64 : (workspaceItemTop.hasWindows ? 32 : 16)
                        radius: 0
                        
                        color: workspaceItemTop.isActive ? 
                            ((sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff") : 
                            workspaceItemTop.hasWindows ? 
                            ((sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff") : 
                            ((sharedData && sharedData.colorSubtext) ? sharedData.colorSubtext : "#666666")
                            
                        opacity: workspaceItemTop.isActive ? 1.0 : (workspaceItemTop.hasWindows ? 0.8 : 0.4)
                        
                        Behavior on width {
                            NumberAnimation { 
                                duration: 300
                                easing.type: Easing.OutBack
>>>>>>> master
                            }
                        }
                        
                        Behavior on color {
<<<<<<< HEAD
                            ColorAnimation { 
                                duration: 400
                                easing.type: Easing.OutCubic
                            }
                        }
                        
=======
                            ColorAnimation { duration: 200 }
                        }

>>>>>>> master
                        Behavior on opacity {
                            NumberAnimation { 
                                duration: 400
                                easing.type: Easing.OutCubic
                            }
                        }
                        
                        Behavior on scale {
                            NumberAnimation { 
                                duration: 300
                                easing.type: Easing.OutCubic
                            }
                        }
                    }
                    
                    // Animacja aktywacji - płynniejsza
                    SequentialAnimation {
                        id: workspaceActivateAnimTop
                        ParallelAnimation {
                            NumberAnimation {
                                target: workspaceLineTop
                                property: "scale"
                                from: 0.6
                                to: 1.15
                                duration: 300
                                easing.type: Easing.OutCubic
                            }
                            NumberAnimation {
                                target: workspaceLineTop
                                property: "opacity"
                                from: 0.5
                                to: 1.0
                                duration: 300
                                easing.type: Easing.OutCubic
                            }
                        }
                        NumberAnimation {
                            target: workspaceLineTop
                            property: "scale"
                            to: 1.0
                            duration: 250
                            easing.type: Easing.OutCubic
                        }
                    }
                    
                    MouseArea {
                        id: workspaceMouseAreaTop
<<<<<<< HEAD
                        anchors.fill: workspaceLineTop  // Tylko w obszarze workspace line, nie całego item
                        anchors.margins: -2  // Mały margines tylko dla łatwiejszego klikania
=======
                        anchors.fill: workspaceLineTop
                        anchors.margins: -5
>>>>>>> master
                        hoverEnabled: true
                        propagateComposedEvents: true  // Pozwól na propagację zdarzeń poza workspace
                        z: 1  // Very low z to ensure buttons (z: 10000) are on top
                        acceptedButtons: Qt.LeftButton
                        
                        onEntered: {
                            if (!workspaceItemTop.isActive) {
<<<<<<< HEAD
                                workspaceLineTop.scale = 1.2
                                workspaceLineTop.opacity = Math.min(workspaceLineTop.opacity + 0.2, 1.0)
=======
                                workspaceLineTop.scale = 1.15
                                workspaceLineTop.opacity = Math.min(workspaceLineTop.opacity + 0.15, 1.0)
>>>>>>> master
                            }
                        }
                        
                        onExited: {
                            if (!workspaceItemTop.isActive) {
                                workspaceLineTop.scale = 1.0
<<<<<<< HEAD
                                workspaceLineTop.opacity = workspaceItemTop.hasWindows ? 0.8 : 0.5
=======
                                workspaceLineTop.opacity = workspaceItemTop.hasWindows ? 0.9 : 0.7
>>>>>>> master
                            }
                        }
                        
                        onClicked: {
                            workspaceClickAnimTop.restart()
                            Hyprland.dispatch("workspace", index + 1)
                        }
                    }
                    
                    // Animacja kliknięcia - płynniejsza
                    SequentialAnimation {
                        id: workspaceClickAnimTop
                        NumberAnimation {
                            target: workspaceLineTop
                            property: "scale"
                            to: 0.75
                            duration: 100
                            easing.type: Easing.InCubic
                        }
                        NumberAnimation {
                            target: workspaceLineTop
                            property: "scale"
                            to: 1.0
                            duration: 300
                            easing.type: Easing.OutCubic
                        }
                    }
                }
                }
            }
        }
<<<<<<< HEAD
        
        // Music Visualizer - PIONOWY dla pozycji left
        Item {
            id: musicVisualizerColumnContainer
            width: 24
            height: parent.height - 85  // Height minus space for buttons
            visible: panelPosition === "left"
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 85  // Above buttons (clipboard at 45px + 32px height + 8px spacing)
            z: 0  // Lower z-order to ensure buttons are clickable
            
            Column {
=======

        
        // Music Visualizer - PIONOWY dla pozycji left (mniejszy)
        Item {
            id: musicVisualizerColumnContainer
            width: parent.width
            height: parent.height - 70
            visible: !isHorizontal
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 52
            z: 0  // Lower z-order to ensure buttons are clickable
            
                Column {
>>>>>>> master
                id: musicVisualizerColumn
                spacing: 2
                width: parent.width
                anchors.bottom: parent.bottom

<<<<<<< HEAD
                // Smooth fade when switching panel positions
                opacity: parent.visible ? 1.0 : 0.0
                Behavior on opacity {
                    NumberAnimation {
                        duration: 300
                        easing.type: Easing.OutCubic
=======
                opacity: parent.visible && panelActive ? 1.0 : 0.0
                scale: panelActive ? 1.0 : 0.85

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
                transform: Translate {
                    x: panelPosition === "left" && !panelActive ? -40 :
                       (panelPosition === "right" && !panelActive ? 40 : 0)

                    Behavior on x {
                        SequentialAnimation {
                            PauseAnimation { duration: 150 }
                            NumberAnimation { duration: 700; easing.type: Easing.OutBack }
                        }
>>>>>>> master
                    }
                }
                
                Repeater {
                    id: visualizerBarsRepeater
<<<<<<< HEAD
                    model: 36  // 36 pasków pionowo - 3x dłuższy visualizer
                
                    Rectangle {
                        id: visualizerBar
                        height: 3  // Grubość paska
                        width: Math.max(3, visualizerBarValue)  // Szerokość zależy od audio
=======
                    model: 24  // 24 paski pionowo
                
                    Rectangle {
                        id: visualizerBar
                        height: 3
                        width: Math.max(3, visualizerBarValue)
>>>>>>> master
                        x: (parent.width - width) / 2  // Wyśrodkuj bez anchors
                        color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff"
                        radius: 0
                        visible: true
                        
<<<<<<< HEAD
                        property real visualizerBarValue: 5  // Start z widoczną szerokością
=======
                        property real visualizerBarValue: 3
>>>>>>> master
                        
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
        }
        
<<<<<<< HEAD
        // Music Visualizer - POZIOMY dla pozycji top
        Item {
            id: musicVisualizerRowContainer
            width: parent.width
            height: 24
            visible: panelPosition === "top"
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: 100  // Space for buttons on right (moved above buttons)
=======
        // Music Visualizer - POZIOMY dla pozycji top (mniejszy)
        Item {
            id: musicVisualizerRowContainer
            width: parent.width
            height: 22
            visible: isHorizontal
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: 60
>>>>>>> master
            z: 1

            Row {
                id: musicVisualizerRow
                spacing: 2
                height: parent.height
                width: parent.width
                x: parent.width - width

<<<<<<< HEAD
                // Smooth fade when switching panel positions
                opacity: parent.visible ? 1.0 : 0.0
                Behavior on opacity {
                    NumberAnimation {
                        duration: 300
                        easing.type: Easing.OutCubic
=======
                opacity: parent.visible && panelActive ? 1.0 : 0.0
                scale: panelActive ? 1.0 : 0.85

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
                transform: Translate {
                    y: panelPosition === "top" && !panelActive ? -40 :
                       (panelPosition === "bottom" && !panelActive ? 40 : 0)

                    Behavior on y {
                        SequentialAnimation {
                            PauseAnimation { duration: 150 }
                            NumberAnimation { duration: 700; easing.type: Easing.OutBack }
                        }
>>>>>>> master
                    }
                }
                
                Repeater {
                    id: visualizerBarsRepeaterTop
<<<<<<< HEAD
                    model: 36  // 36 pasków poziomo
                    
                    Rectangle {
                        id: visualizerBarTop
                        width: 3  // Grubość paska
                        height: Math.max(3, visualizerBarValueTop)  // Wysokość zależy od audio
=======
                    model: 24  // 24 paski poziomo
                    
                    Rectangle {
                        id: visualizerBarTop
                        width: 3
                        height: Math.max(3, visualizerBarValueTop)
>>>>>>> master
                        y: (parent.height - height) / 2  // Wyśrodkuj bez anchors
                        color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff"
                        radius: 0
                        visible: true
                        
<<<<<<< HEAD
                        property real visualizerBarValueTop: 5  // Start z widoczną wysokością
=======
                        property real visualizerBarValueTop: 3
>>>>>>> master
                        
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
        
    }  // End of sidePanelContent
    
    // Screenshot Button - OUTSIDE sidePanelRect and sidePanelContent to ensure it's clickable
    Item {
        id: screenshotButtonContainer
        width: 32
        height: 32

<<<<<<< HEAD
        anchors.horizontalCenter: panelPosition === "left" ? parent.horizontalCenter : undefined
        anchors.right: panelPosition === "top" ? parent.right : undefined
        anchors.rightMargin: panelPosition === "top" ? 48 : 0
        anchors.bottom: panelPosition === "left" ? parent.bottom : undefined
        anchors.bottomMargin: panelPosition === "left" ? 10 : 0
        z: 100000  // Very high z to ensure it's on top of everything (increased from 10000)
        visible: true
        enabled: true
        
        // Debug: Make sure button is visible and clickable
        Component.onCompleted: {
            console.log("Screenshot button container created at z:", z, "visible:", visible, "enabled:", enabled)
        }

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
        z: 100000  // Very high z to ensure it's on top of everything (increased from 10000)
        visible: true
        enabled: true
        
        // Debug: Make sure button is visible and clickable
        Component.onCompleted: {
            console.log("Clipboard button container created at z:", z, "visible:", visible, "enabled:", enabled)
        }

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
=======
        anchors.horizontalCenter: !isHorizontal ? parent.horizontalCenter : undefined
        anchors.right: isHorizontal ? parent.right : undefined
        anchors.rightMargin: isHorizontal ? 12 : 0
        anchors.verticalCenter: isHorizontal ? parent.verticalCenter : undefined
        anchors.bottom: !isHorizontal ? parent.bottom : undefined
        anchors.bottomMargin: !isHorizontal ? 6 : 0
        z: 100000
        visible: true
        enabled: true

        opacity: panelActive ? 1.0 : 0.0
        scale: panelActive ? 1.0 : 0.7

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
        transform: Translate {
            x: panelPosition === "left" && !panelActive ? -40 :
               (panelPosition === "right" && !panelActive ? 40 : 0)
            y: panelPosition === "top" && !panelActive ? -40 :
               (panelPosition === "bottom" && !panelActive ? 40 : 0)

            Behavior on x {
                SequentialAnimation {
                    PauseAnimation { duration: 200 }
                    NumberAnimation { duration: 700; easing.type: Easing.OutBack }
                }
            }
            Behavior on y {
                SequentialAnimation {
                    PauseAnimation { duration: 200 }
                    NumberAnimation { duration: 700; easing.type: Easing.OutBack }
                }
            }
        }

        Behavior on anchors.rightMargin {
            NumberAnimation { duration: 400; easing.type: Easing.OutCubic }
        }
        Behavior on anchors.bottomMargin {
            NumberAnimation { duration: 400; easing.type: Easing.OutCubic }
        }

        property color btnBg: (sharedData && sharedData.colorSecondary) ? sharedData.colorSecondary : "#1a1a1a"
        property color btnBgHover: Qt.lighter(btnBg, 1.08)
        property color btnIcon: Qt.rgba(0.65, 0.65, 0.7, 1)
        property color btnIconHover: Qt.rgba(0.85, 0.85, 0.9, 1)

        Rectangle {
            id: screenshotButton
            width: 26
            height: 26
            anchors.centerIn: parent
            radius: 0
            color: screenshotButtonMouseArea.containsMouse
                ? screenshotButtonContainer.btnBgHover
                : screenshotButtonContainer.btnBg
            border.width: 0
            opacity: screenshotButtonMouseArea.pressed ? 0.85 : 1.0

            property real btnScale: screenshotButtonMouseArea.pressed ? 0.97 : (screenshotButtonMouseArea.containsMouse ? 1.02 : 1.0)

            scale: btnScale
            transformOrigin: Item.Center

            // MouseArea wewnątrz Rectangle – wtedy kliknięcia zawsze trafiają w przycisk
            MouseArea {
                id: screenshotButtonMouseArea
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton

                onClicked: {
                    if (sidePanel.screenshotFunction) sidePanel.screenshotFunction()
                }
            }

            Behavior on color {
                ColorAnimation { duration: 180; easing.type: Easing.OutCubic }
            }
            Behavior on opacity {
                NumberAnimation { duration: 100 }
            }
            Behavior on btnScale {
                NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
            }

            Text {
                text: "󰄀"
                font.pixelSize: 14
                font.family: "sans-serif"
                anchors.centerIn: parent
                color: screenshotButtonMouseArea.containsMouse
                    ? screenshotButtonContainer.btnIconHover
                    : screenshotButtonContainer.btnIcon

                Behavior on color {
                    ColorAnimation { duration: 180; easing.type: Easing.OutCubic }
                }
            }
        }
    }
    
    // Opcjonalne funkcje callback
    property var launcherFunction
>>>>>>> master
    property var screenshotFunction
    
    // --- Music Visualizer ---
    property var cavaValues: []
    property bool cavaRunning: false
    
    function startCava() {
<<<<<<< HEAD
        // Sprawdź czy cava jest zainstalowane
        Qt.createQmlObject("import Quickshell.Io; import QtQuick; Process { command: ['sh','-c','which cava > /dev/null 2>&1 && echo 1 > /tmp/quickshell_cava_available || echo 0 > /tmp/quickshell_cava_available']; running: true }", sidePanel)
        
        // Poczekaj i sprawdź dostępność
        Qt.createQmlObject("import QtQuick; Timer { interval: 200; running: true; repeat: false; onTriggered: sidePanel.checkCavaAvailable() }", sidePanel)
    }
    
    function checkCavaAvailable() {
=======
        if (!isPrimaryPanel)
            return
        if (sharedData && sharedData.lowPerformanceMode)
            return
        if (sharedData && sharedData.runCommand) {
            sharedData.runCommand(['sh', '-c', 'which cava > /dev/null 2>&1 && echo 1 > /tmp/quickshell_cava_available || echo 0 > /tmp/quickshell_cava_available'], checkCavaAvailable)
        }
    }
    
    function checkCavaAvailable() {
        if (!isPrimaryPanel)
            return
>>>>>>> master
        var xhr = new XMLHttpRequest()
        xhr.open("GET", "file:///tmp/quickshell_cava_available")
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                var available = xhr.responseText.trim() === "1"
<<<<<<< HEAD
                console.log("Cava available:", available, "cavaRunning:", cavaRunning)
=======
>>>>>>> master
                if (available && !cavaRunning) {
                    // Użyj skryptu start-cava.sh do uruchomienia cava z poprawną konfiguracją
                    // Use projectPath if available, otherwise try to detect
                    var scriptPath = (projectPath && projectPath.length > 0) ? (projectPath + "/scripts/start-cava.sh") : ""
                    if (!scriptPath || scriptPath === "/scripts/start-cava.sh") {
<<<<<<< HEAD
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
=======
                        if (sharedData && sharedData.runCommand) {
                            sharedData.runCommand(['sh', '-c', 'echo "$QUICKSHELL_PROJECT_PATH" > /tmp/quickshell_cava_path 2>/dev/null || true'], readCavaPath)
                        }
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
>>>>>>> master
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
<<<<<<< HEAD
                        console.log("Cava file not accessible, status:", xhr.status)
=======
>>>>>>> master
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
                        
<<<<<<< HEAD
                        for (var i = 0; i < 36; i++) {
=======
                        for (var i = 0; i < 24; i++) {
>>>>>>> master
                            var val = 0
                            if (i < values.length && values[i]) {
                                val = parseInt(values[i]) || 0
                            }
<<<<<<< HEAD
                            var normalizedWidth = Math.max(3, (val / 100) * 24)
                            var normalizedHeight = Math.max(3, (val / 100) * 24)
=======
                            var normalizedWidth = Math.max(3, (val / 100) * 20)
                            var normalizedHeight = Math.max(3, (val / 100) * 20)
>>>>>>> master
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
    
<<<<<<< HEAD
    // Timer do odczytu danych z cava
    Timer {
        id: cavaDataTimer
        interval: 16  // ~60 FPS
        repeat: true
        running: cavaRunning
        onTriggered: readCavaData()
    }
    
    // Timer do sprawdzania czy cava działa (fallback)
=======
    // Timer do odczytu danych z cava (50ms=20 FPS domyślnie; 100ms w low-perf; wyłączony w low-perf)
    Timer {
        id: cavaDataTimer
        interval: (sharedData && sharedData.lowPerformanceMode) ? 100 : 50
        repeat: true
        running: cavaRunning && isPrimaryPanel && !(sharedData && sharedData.lowPerformanceMode)
        onTriggered: readCavaData()
    }
    
    // Timer do sprawdzania czy cava działa (fallback) – tylko w panelu głównym
>>>>>>> master
    Timer {
        id: cavaCheckTimer
        interval: 5000  // Co 5 sekund
        repeat: true
<<<<<<< HEAD
        running: true
=======
        running: isPrimaryPanel
>>>>>>> master
        onTriggered: {
            if (cavaRunning) {
                // Sprawdź czy plik istnieje i ma dane
                var xhr = new XMLHttpRequest()
                xhr.open("GET", "file:///tmp/quickshell_cava")
                xhr.onreadystatechange = function() {
                    if (xhr.readyState === XMLHttpRequest.DONE) {
                        if (xhr.status !== 200 && xhr.status !== 0) {
<<<<<<< HEAD
                            console.log("Cava file not accessible, restarting...")
=======
>>>>>>> master
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
<<<<<<< HEAD
            // Ustaw minimalne wartości dla pasków, żeby były widoczne od razu
            for (var i = 0; i < 36; i++) {
                var value = 5 + (i % 3) * 3  // Różne wartości dla testu
=======
            // Ustaw minimalne wartości dla pasków (24 bary)
            for (var i = 0; i < 24; i++) {
                var value = 3 + (i % 2) * 2
>>>>>>> master
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
<<<<<<< HEAD
        // Try to read path from environment variable
        Qt.createQmlObject("import Quickshell.Io; import QtQuick; Process { command: ['sh', '-c', 'echo \"$QUICKSHELL_PROJECT_PATH\" > /tmp/quickshell_sidepanel_path 2>/dev/null || echo \"\" > /tmp/quickshell_sidepanel_path']; running: true }", sidePanel)
        Qt.createQmlObject("import QtQuick; Timer { interval: 100; running: true; repeat: false; onTriggered: sidePanel.readProjectPath() }", sidePanel)
=======
        if (sharedData && sharedData.runCommand) {
            sharedData.runCommand(['sh', '-c', 'echo "$QUICKSHELL_PROJECT_PATH" > /tmp/quickshell_sidepanel_path 2>/dev/null || true'], readProjectPath)
        }
>>>>>>> master
    }
    
    function readProjectPath() {
        var xhr = new XMLHttpRequest()
        xhr.open("GET", "file:///tmp/quickshell_sidepanel_path")
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                var path = xhr.responseText.trim()
                if (path && path.length > 0) {
                    projectPath = path
<<<<<<< HEAD
                    console.log("SidePanel project path loaded:", projectPath)
=======
>>>>>>> master
                    // Start cava after path is loaded
                    startCava()
                } else {
                    // Fallback to default
                    projectPath = "/tmp/sharpshell"
<<<<<<< HEAD
                    console.log("SidePanel using fallback project path:", projectPath)
=======
>>>>>>> master
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
<<<<<<< HEAD
                    console.log("SidePanel project path loaded from cava path:", projectPath)
=======
>>>>>>> master
                    // Retry starting cava
                    startCava()
                } else {
                    // Fallback
                    projectPath = "/tmp/sharpshell"
<<<<<<< HEAD
                    console.log("SidePanel using fallback project path (from readCavaPath):", projectPath)
=======
>>>>>>> master
                    startCava()
                }
            }
        }
        xhr.send()
    }
<<<<<<< HEAD
    
    Component.onCompleted: {
        // Uruchom inicjalizację visualizera
        visualizerInitTimer.start()
        // Load project path first, then start cava
        loadProjectPath()
    }
}

=======
}
>>>>>>> master

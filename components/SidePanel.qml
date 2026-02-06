import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Shapes

PanelWindow {
    id: sidePanel
    
    required property var screen
    required property string panelPosition  // "left" or "top" - determines which panel this is
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
    
    // Margins based on panel position
    margins {
        left: 0
        top: 0
        bottom: 0
        right: 0

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
                }
            }
            
            Text {
                id: sidePanelHoursDisplay
                text: "00"
                font.pixelSize: 26
                font.family: "sans-serif"
                font.weight: Font.Black
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
                font.pixelSize: 26
                font.family: "sans-serif"
                font.weight: Font.Black
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
                }
            }
            
            Text {
                id: sidePanelHoursDisplayTop
                text: "00"
                font.pixelSize: 24
                font.family: "sans-serif"
                font.weight: Font.Black
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
                font.pixelSize: 24
                font.family: "sans-serif"
                font.weight: Font.Black
                color: (sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff"
                verticalAlignment: Text.AlignVCenter
            }
            
            Text {
                id: sidePanelMinutesDisplayTop
                text: "00"
                font.pixelSize: 24
                font.family: "sans-serif"
                font.weight: Font.Black
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
            running: isPrimaryPanel
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
                width: parent.width
                x: (parent.width - width) / 2
                y: (parent.height - height) / 2
                
                Repeater {
                    model: 4  // Workspaces 1-4
                
                    Item {
                    id: workspaceItem
                    width: parent.width
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
                            }
                        }
                        
                        Behavior on color {
                            ColorAnimation { duration: 200 }
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
                        anchors.fill: workspaceLine
                        anchors.margins: -5
                        hoverEnabled: true
                        propagateComposedEvents: true  // Pozwól na propagację zdarzeń poza workspace
                        z: 1  // Very low z to ensure buttons (z: 10000) are on top
                        acceptedButtons: Qt.LeftButton
                        
                        onEntered: {
                            if (!workspaceItem.isActive) {
                                workspaceLine.scale = 1.15
                                workspaceLine.opacity = Math.min(workspaceLine.opacity + 0.15, 1.0)
                            }
                        }
                        
                        onExited: {
                            if (!workspaceItem.isActive) {
                                workspaceLine.scale = 1.0
                                workspaceLine.opacity = workspaceItem.hasWindows ? 0.9 : 0.7
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
            height: parent.height
            visible: isHorizontal
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            z: 50  // Lower than buttons (z: 10000) to not block clicks
            
            Row {
                id: sidePanelWorkspaceRow
                spacing: 12
                height: parent.height
                x: (parent.width - width) / 2
                y: (parent.height - height) / 2
                
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
                
                Repeater {
                    model: 4  // Workspaces 1-4
                
                    Item {
                        id: workspaceItemTop
                        height: parent.height
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
                            }
                        }
                        
                        Behavior on color {
                            ColorAnimation { duration: 200 }
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
                        anchors.fill: workspaceLineTop
                        anchors.margins: -5
                        hoverEnabled: true
                        propagateComposedEvents: true  // Pozwól na propagację zdarzeń poza workspace
                        z: 1  // Very low z to ensure buttons (z: 10000) are on top
                        acceptedButtons: Qt.LeftButton
                        
                        onEntered: {
                            if (!workspaceItemTop.isActive) {
                                workspaceLineTop.scale = 1.15
                                workspaceLineTop.opacity = Math.min(workspaceLineTop.opacity + 0.15, 1.0)
                            }
                        }
                        
                        onExited: {
                            if (!workspaceItemTop.isActive) {
                                workspaceLineTop.scale = 1.0
                                workspaceLineTop.opacity = workspaceItemTop.hasWindows ? 0.9 : 0.7
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
                id: musicVisualizerColumn
                spacing: 2
                width: parent.width
                anchors.bottom: parent.bottom

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
                    }
                }
                
                Repeater {
                    id: visualizerBarsRepeater
                    model: 24  // 24 paski pionowo
                
                    Rectangle {
                        id: visualizerBar
                        height: 3
                        width: Math.max(3, visualizerBarValue)
                        x: (parent.width - width) / 2  // Wyśrodkuj bez anchors
                        color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff"
                        radius: 0
                        visible: true
                        
                        property real visualizerBarValue: 3
                        
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
        
        // Music Visualizer - POZIOMY dla pozycji top (mniejszy)
        Item {
            id: musicVisualizerRowContainer
            width: parent.width
            height: 22
            visible: isHorizontal
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: 60
            z: 1

            Row {
                id: musicVisualizerRow
                spacing: 2
                height: parent.height
                width: parent.width
                x: parent.width - width

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
                    }
                }
                
                Repeater {
                    id: visualizerBarsRepeaterTop
                    model: 24  // 24 paski poziomo
                    
                    Rectangle {
                        id: visualizerBarTop
                        width: 3
                        height: Math.max(3, visualizerBarValueTop)
                        y: (parent.height - height) / 2  // Wyśrodkuj bez anchors
                        color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff"
                        radius: 0
                        visible: true
                        
                        property real visualizerBarValueTop: 3
                        
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
    property var screenshotFunction
    
    // --- Music Visualizer ---
    property var cavaValues: []
    property bool cavaRunning: false
    
    function startCava() {
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
        var xhr = new XMLHttpRequest()
        xhr.open("GET", "file:///tmp/quickshell_cava_available")
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                var available = xhr.responseText.trim() === "1"
                if (available && !cavaRunning) {
                    // Użyj skryptu start-cava.sh do uruchomienia cava z poprawną konfiguracją
                    // Use projectPath if available, otherwise try to detect
                    var scriptPath = (projectPath && projectPath.length > 0) ? (projectPath + "/scripts/start-cava.sh") : ""
                    if (!scriptPath || scriptPath === "/scripts/start-cava.sh") {
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
                        
                        for (var i = 0; i < 24; i++) {
                            var val = 0
                            if (i < values.length && values[i]) {
                                val = parseInt(values[i]) || 0
                            }
                            var normalizedWidth = Math.max(3, (val / 100) * 20)
                            var normalizedHeight = Math.max(3, (val / 100) * 20)
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
    
    // Timer do odczytu danych z cava (50ms=20 FPS domyślnie; 100ms w low-perf; wyłączony w low-perf)
    Timer {
        id: cavaDataTimer
        interval: (sharedData && sharedData.lowPerformanceMode) ? 100 : 50
        repeat: true
        running: cavaRunning && isPrimaryPanel && !(sharedData && sharedData.lowPerformanceMode)
        onTriggered: readCavaData()
    }
    
    // Timer do sprawdzania czy cava działa (fallback) – tylko w panelu głównym
    Timer {
        id: cavaCheckTimer
        interval: 5000  // Co 5 sekund
        repeat: true
        running: isPrimaryPanel
        onTriggered: {
            if (cavaRunning) {
                // Sprawdź czy plik istnieje i ma dane
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
            // Ustaw minimalne wartości dla pasków (24 bary)
            for (var i = 0; i < 24; i++) {
                var value = 3 + (i % 2) * 2
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
        if (sharedData && sharedData.runCommand) {
            sharedData.runCommand(['sh', '-c', 'echo "$QUICKSHELL_PROJECT_PATH" > /tmp/quickshell_sidepanel_path 2>/dev/null || true'], readProjectPath)
        }
    }
    
    function readProjectPath() {
        var xhr = new XMLHttpRequest()
        xhr.open("GET", "file:///tmp/quickshell_sidepanel_path")
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                var path = xhr.responseText.trim()
                if (path && path.length > 0) {
                    projectPath = path
                    // Start cava after path is loaded
                    startCava()
                } else {
                    // Fallback to default
                    projectPath = "/tmp/sharpshell"
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
                    // Retry starting cava
                    startCava()
                } else {
                    // Fallback
                    projectPath = "/tmp/sharpshell"
                    startCava()
                }
            }
        }
        xhr.send()
    }
}

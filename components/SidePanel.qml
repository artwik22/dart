import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick

PanelWindow {
    id: sidePanel
    
    required property var screen
    property string projectPath: ""  // Will be set from environment or auto-detected
    
    screen: sidePanel.screen
    
    anchors {
        left: true
        top: true
        bottom: true
    }
    
    implicitWidth: 36
    color: "transparent"
    
    margins {
        left: 0
        top: 0
        bottom: 0
    }

    property var sharedData: null
    
    Rectangle {
        id: sidePanelRect
        anchors.fill: parent
        color: (sharedData && sharedData.colorBackground) ? sharedData.colorBackground : "#0d0d0d"
        radius: 0
        
        // Zegar na górze - godzina nad minutą
        Column {
            id: sidePanelClockColumn
            anchors.top: parent.top
            anchors.topMargin: 14
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 4
            
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
                        duration: 180
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
                        duration: 180
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
                sidePanelHoursDisplay.text = h < 10 ? "0" + h : h.toString()
                sidePanelMinutesDisplay.text = m < 10 ? "0" + m : m.toString()
            }
            Component.onCompleted: {
                var now = new Date()
                var h = now.getHours()
                var m = now.getMinutes()
                sidePanelHoursDisplay.text = h < 10 ? "0" + h : h.toString()
                sidePanelMinutesDisplay.text = m < 10 ? "0" + m : m.toString()
            }
        }
        
        // Workspace switcher - wyśrodkowany na pasku
        Column {
            id: sidePanelWorkspaceColumn
            spacing: 9
            width: 4
            visible: true
            anchors.centerIn: parent
                
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
                        
                        Behavior on opacity {
                            NumberAnimation { 
                                duration: 180
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
        
        // Music Visualizer - PIONOWY na dole panelu (poziome paski ułożone w kolumnie)
        Column {
            id: musicVisualizerColumn
            spacing: 2
            width: 24  // Szerokość pasków
            visible: true
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 15
            
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
        
    }
    
    // Opcjonalne funkcje callback
    property var lockScreenFunction
    property var settingsFunction
    property var launcherFunction
    
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
                            if (visualizerBarsRepeater.itemAt(i)) {
                                visualizerBarsRepeater.itemAt(i).visualizerBarValue = normalizedWidth
                                var intensity = val / 100
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
                        }
                    }
                } else {
                    // No data, check if cava is still running
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
            // Ustaw minimalne wartości dla pasków (8 pasków), żeby były widoczne od razu
            for (var i = 0; i < 36; i++) {
                if (visualizerBarsRepeater.itemAt(i)) {
                    visualizerBarsRepeater.itemAt(i).visualizerBarValue = 5 + (i % 3) * 3  // Różne szerokości dla testu
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


import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick

PanelWindow {
    id: sidePanel
    
    required property var screen
    property string projectPath: "/home/artwik/sharpshell"  // Domyślna ścieżka
    
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

    Rectangle {
        id: sidePanelRect
        anchors.fill: parent
        color: "#0d0d0d"
        radius: 0
        border.width: 0
        
        // Zegar na górze
        Text {
            id: sidePanelHoursDisplay
            anchors.top: parent.top
            anchors.topMargin: 12
            anchors.horizontalCenter: parent.horizontalCenter
            text: "00"
            font.pixelSize: 16
            font.family: "JetBrains Mono"
            font.weight: Font.Bold
            color: "#ffffff"
        }
        
        Text {
            id: sidePanelMinutesDisplay
            anchors.top: sidePanelHoursDisplay.bottom
            anchors.topMargin: 4
            anchors.horizontalCenter: parent.horizontalCenter
            text: "00"
            font.pixelSize: 16
            font.family: "JetBrains Mono"
            font.weight: Font.Medium
            color: "#888888"
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
            width: 5
            visible: true
            anchors.centerIn: parent
                
                Repeater {
                    model: 4  // Workspaces 1-4
                
                Item {
                    id: workspaceItem
                    width: 5
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
                        width: 5
                        height: workspaceItem.isActive ? 32 : workspaceItem.hasWindows ? 18 : 11
                        color: workspaceItem.isActive ? "#ffffff" : workspaceItem.hasWindows ? "#888888" : "#4a4a4a"
                        
                        Behavior on height {
                            NumberAnimation { 
                                duration: 300
                                easing.type: Easing.OutCubic
                            }
                        }
                        
                        Behavior on color {
                            ColorAnimation { 
                                duration: 250
                                easing.type: Easing.OutCubic
                            }
                        }
                        
                        Behavior on scale {
                            NumberAnimation { 
                                duration: 200
                                easing.type: Easing.OutCubic
                            }
                        }
                        
                        Behavior on opacity {
                            NumberAnimation { 
                                duration: 200
                                easing.type: Easing.OutCubic
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
                            easing.type: Easing.OutCubic
                        }
                        NumberAnimation {
                            target: workspaceLine
                            property: "scale"
                            to: 1.0
                            duration: 150
                            easing.type: Easing.OutCubic
                        }
                    }
                    
                    MouseArea {
                        id: workspaceMouseArea
                        anchors.fill: parent
                        anchors.margins: -5
                        hoverEnabled: true
                        
                        onEntered: {
                            workspaceLine.scale = 1.3
                            workspaceLine.opacity = 1.3
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
                            easing.type: Easing.OutCubic
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
                    color: "#ffffff"
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
                    var absScriptPath = "/home/artwik/.config/sharpshell/scripts/start-cava.sh"
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
                var data = xhr.responseText
                if (data && data.length > 5) {
                    var values = data.trim().split(";")
                    for (var i = 0; i < 36; i++) {
                        var val = parseInt(values[i]) || 0
                        var normalizedWidth = Math.max(3, (val / 100) * 24)
                        if (visualizerBarsRepeater.itemAt(i)) {
                            visualizerBarsRepeater.itemAt(i).visualizerBarValue = normalizedWidth
                            var intensity = val / 100
                            if (intensity > 0.7) {
                                visualizerBarsRepeater.itemAt(i).color = "#ffffff"
                            } else if (intensity > 0.4) {
                                visualizerBarsRepeater.itemAt(i).color = "#d0d0d0"
                            } else if (intensity > 0.1) {
                                visualizerBarsRepeater.itemAt(i).color = "#999999"
                            } else {
                                visualizerBarsRepeater.itemAt(i).color = "#5a5a5a"
                            }
                        }
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
    
    Component.onCompleted: {
        // Uruchom inicjalizację visualizera i cava
        visualizerInitTimer.start()
        startCava()
    }
}


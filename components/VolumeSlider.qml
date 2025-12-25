import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

PanelWindow {
    id: volumeSliderRoot

    anchors { 
        right: true
    }
    implicitWidth: 54
    implicitHeight: 270
    
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qsvolumeslider"
    exclusiveZone: 0

    property var sharedData: null
    
    // Kontrola widoczności - zawsze widoczne, przesuwamy przez margins
    visible: true
    color: "transparent"
    
    // Właściwość do animacji margins.right
    property int slideOffset: (sharedData && sharedData.volumeVisible) ? 0 : -implicitWidth
    
    margins {
        top: 0
        bottom: 0
        right: slideOffset
        left: 0
    }
    
    // Animacja slideOffset dla slide in/out - szybsza i bardziej płynna
    Behavior on slideOffset {
        NumberAnimation { 
            duration: 300
            easing.type: Easing.OutQuart
        }
    }

    // Kontener z animacją fade in/out
    Item {
        id: volumeSliderContainer
        anchors.fill: parent
        
        // Właściwości animacji fade i scale
        opacity: (sharedData && sharedData.volumeVisible) ? 1.0 : 0.0
        scale: (sharedData && sharedData.volumeVisible) ? 1.0 : 0.95
        
        // Animacja fade in/out - zsynchronizowana z slide
        Behavior on opacity {
            NumberAnimation { 
                duration: 300
                easing.type: Easing.OutQuart
            }
        }
        
        // Lekka animacja scale dla lepszego efektu
        Behavior on scale {
            NumberAnimation { 
                duration: 300
                easing.type: Easing.OutQuart
            }
        }
        
        // Wyłączamy interakcję gdy slider jest ukryty
        enabled: opacity > 0.1
        
        // MouseArea do wykrywania czy myszka jest nad sliderem
        MouseArea {
            id: volumeSliderMouseArea
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
            propagateComposedEvents: true
            z: 1
            
            onEntered: {
                if (sharedData) {
                    sharedData.volumeVisible = true
                    hideDelayTimer.stop()
                }
            }
            
            onExited: {
                // Ukryj slider tylko gdy myszka opuści obszar slidera
                if (sharedData) {
                    // Zatrzymaj timer i uruchom ponownie, aby zawsze się uruchomił
                    hideDelayTimer.stop()
                    hideDelayTimer.restart()
                }
            }
        }

        // Tło jednolite
        Rectangle {
            id: volumeSliderBackground
            anchors.fill: parent
            anchors.rightMargin: 0
            radius: 0
            color: (sharedData && sharedData.colorBackground) ? sharedData.colorBackground : "#111111"
        }
        
        // Border tylko z lewej strony
        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: 1
            color: (sharedData && sharedData.colorSecondary) ? sharedData.colorSecondary : "#252525"
        }

        // Slider głośności - pionowy
        Column {
            id: volumeSliderColumn
            anchors.centerIn: parent
            spacing: 18
            width: parent.width - 18

            // Ikona głośności
            Text {
                id: volumeIcon
                text: {
                    if (volumeValue === 0) return "󰝟"
                    else if (volumeValue < 33) return "󰕿"
                    else if (volumeValue < 66) return "󰖀"
                    else return "󰕾"
                }
                font.pixelSize: 24
                color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#f5f5f5"
                anchors.horizontalCenter: parent.horizontalCenter
            }

            // Slider
            Item {
                id: sliderContainer
                width: parent.width
                height: 180
                anchors.horizontalCenter: parent.horizontalCenter

                // Tło slidera
                Rectangle {
                    id: sliderTrack
                    anchors.centerIn: parent
                    width: 5
                    height: parent.height
                    color: (sharedData && sharedData.colorPrimary) ? sharedData.colorPrimary : "#3a3a3a"
                    radius: 0
                }

                // Wypełnienie slidera
                Rectangle {
                    id: sliderFill
                    anchors.bottom: sliderTrack.bottom
                    anchors.horizontalCenter: sliderTrack.horizontalCenter
                    width: sliderTrack.width
                    height: sliderTrack.height * (volumeValue / 100)
                    color: (sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff"
                    radius: 0
                    
                    Behavior on height {
                        NumberAnimation { 
                            duration: 150
                            easing.type: Easing.OutQuart
                        }
                    }
                }

                // Obsługa kliknięć, przeciągania i scrollu
                MouseArea {
                    id: sliderMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton
                    z: 10
                    
                    function setVolumeFromMouse(mouse) {
                        var newVolume = 100 - Math.round((mouse.y / parent.height) * 100)
                        if (newVolume < 0) newVolume = 0
                        if (newVolume > 100) newVolume = 100
                        setSystemVolume(newVolume)
                    }
                    
                    function adjustVolume(delta) {
                        var newVolume = volumeValue + delta
                        if (newVolume < 0) newVolume = 0
                        if (newVolume > 100) newVolume = 100
                        setSystemVolume(newVolume)
                    }
                    
                    onPressed: function(mouse) {
                        setVolumeFromMouse(mouse)
                    }
                    
                    onPositionChanged: function(mouse) {
                        if (pressed) {
                            setVolumeFromMouse(mouse)
                        }
                    }
                    
                    onWheel: function(wheel) {
                        var delta = wheel.angleDelta.y > 0 ? 5 : -5
                        adjustVolume(delta)
                        wheel.accepted = true
                    }
                }
            }

            // Wartość głośności w procentach
            Text {
                id: volumeValueText
                text: Math.round(volumeValue) + "%"
                font.pixelSize: 12
                font.family: "JetBrains Mono"
                font.weight: Font.Medium
                font.letterSpacing: 0.2
                color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#f5f5f5"
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }

    // Timer do opóźnienia ukrywania
    Timer {
        id: hideDelayTimer
        interval: 800  // Zwiększony interwał dla lepszej responsywności
        onTriggered: {
            // Sprawdź czy myszka nie jest ani nad sliderem ani nad detektorem
            if (sharedData && !volumeSliderMouseArea.containsMouse && !sharedData.volumeEdgeHovered) {
                sharedData.volumeVisible = false
            }
        }
    }
    
    // Nasłuchuj zmian w volumeEdgeHovered i uruchamiaj timer gdy myszka opuści detektor
    Connections {
        target: sharedData
        function onVolumeEdgeHoveredChanged() {
            if (sharedData && !sharedData.volumeEdgeHovered && !volumeSliderMouseArea.containsMouse) {
                // Myszka opuściła detektor i nie jest nad sliderem - uruchom timer
                hideDelayTimer.stop()
                hideDelayTimer.restart()
            }
        }
    }

    // --- Właściwości ---
    property real volumeValue: 50

    // --- Funkcje ---
    function setSystemVolume(value) {
        volumeValue = Math.round(value)
        Qt.createQmlObject("import Quickshell.Io; import QtQuick; Process { command: ['pactl','set-sink-volume','@DEFAULT_SINK@','" + Math.round(value) + "%']; running: true }", volumeSliderRoot)
        // Odśwież volume po ustawieniu
        Qt.createQmlObject("import QtQuick; Timer { interval: 200; running: true; repeat: false; onTriggered: volumeSliderRoot.getSystemVolume() }", volumeSliderRoot)
        Qt.createQmlObject("import QtQuick; Timer { interval: 350; running: true; repeat: false; onTriggered: volumeSliderRoot.readSystemVolume() }", volumeSliderRoot)
    }

    function getSystemVolume() {
        // Zapisz volume do pliku
        Qt.createQmlObject("import Quickshell.Io; import QtQuick; Process { command: ['sh','-c','pactl get-sink-volume @DEFAULT_SINK@ | head -1 | awk \\\"{print $5}\\\" | tr -d % > /tmp/quickshell_volume']; running: true }", volumeSliderRoot)
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

    // Timer do odświeżania głośności
    Timer {
        id: volumeTimer
        interval: 1000
        repeat: true
        running: true
        onTriggered: {
            getSystemVolume()
            // Poczekaj 150ms i przeczytaj volume
            Qt.createQmlObject("import QtQuick; Timer { interval: 150; running: true; repeat: false; onTriggered: volumeSliderRoot.readSystemVolume() }", volumeSliderRoot)
        }
        Component.onCompleted: {
            getSystemVolume()
            Qt.createQmlObject("import QtQuick; Timer { interval: 150; running: true; repeat: false; onTriggered: volumeSliderRoot.readSystemVolume() }", volumeSliderRoot)
        }
    }

    // Obserwuj zmiany volumeVisible
    Connections {
        target: sharedData
        function onVolumeVisibleChanged() {
            if (sharedData && sharedData.volumeVisible) {
                // Gdy slider się otwiera, sprawdź aktualną głośność
                getSystemVolume()
                Qt.createQmlObject("import QtQuick; Timer { interval: 150; running: true; repeat: false; onTriggered: volumeSliderRoot.readSystemVolume() }", volumeSliderRoot)
            }
        }
    }

    Component.onCompleted: {
        getSystemVolume()
    }
}


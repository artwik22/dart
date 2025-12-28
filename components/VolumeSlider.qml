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

    // MouseArea dla slidera - umieszczony PRZED kontenerem, zawsze aktywny
    MouseArea {
        id: sliderMouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        z: 99999  // Very high z-index to ensure it's on top of everything
        enabled: true  // Always enabled
        propagateComposedEvents: false
        
        // Only process events when slider is visible
        property bool isSliderVisible: (sharedData && sharedData.volumeVisible)
        
        // Calculate slider bounds (centered, 180px high)
        property real sliderY: (parent.height - 180) / 2
        property real sliderHeight: 180
        property real sliderWidth: parent.width - 18
        
        function isMouseOverSlider(mouse) {
            var centerX = parent.width / 2
            var sliderLeft = centerX - sliderWidth / 2
            var sliderRight = centerX + sliderWidth / 2
            return mouse.x >= sliderLeft && mouse.x <= sliderRight && 
                   mouse.y >= sliderY && mouse.y <= sliderY + sliderHeight
        }
        
        // Also handle hover for the entire slider area
        onEntered: {
            console.log("VolumeSlider: Mouse entered PanelWindow area")
            if (sharedData) {
                sharedData.volumeVisible = true
                hideDelayTimer.stop()
            }
        }
        
        onExited: {
            console.log("VolumeSlider: Mouse exited PanelWindow area")
            if (sharedData) {
                // Don't start timer if mouse is still over edge detector
                if (!sharedData.volumeEdgeHovered) {
                    console.log("Starting hideDelayTimer")
                    hideDelayTimer.stop()
                    hideDelayTimer.restart()
                } else {
                    console.log("Not starting timer - mouse still over edge detector")
                }
            }
        }
        
        function setVolumeFromMouse(mouse) {
            // Calculate volume based on mouse position relative to slider area
            var relativeY = mouse.y - sliderY
            var newVolume = 100 - Math.round((relativeY / sliderHeight) * 100)
            if (newVolume < 0) newVolume = 0
            if (newVolume > 100) newVolume = 100
            console.log("Setting volume:", newVolume, "from mouse.y:", mouse.y, "relativeY:", relativeY)
            setSystemVolume(newVolume)
        }
        
        function adjustVolume(delta) {
            var newVolume = volumeValue + delta
            if (newVolume < 0) newVolume = 0
            if (newVolume > 100) newVolume = 100
            setSystemVolume(newVolume)
        }
        
        onPressed: function(mouse) {
            console.log("VolumeSlider: Mouse pressed at", mouse.x, mouse.y, "isSliderVisible:", isSliderVisible, "isOverSlider:", isMouseOverSlider(mouse))
            if (isSliderVisible && isMouseOverSlider(mouse)) {
                mouse.accepted = true
                setVolumeFromMouse(mouse)
            } else {
                mouse.accepted = false
            }
        }
        
        onPositionChanged: function(mouse) {
            if (pressed && isSliderVisible && isMouseOverSlider(mouse)) {
                console.log("VolumeSlider: Mouse dragged to", mouse.x, mouse.y)
                mouse.accepted = true
                setVolumeFromMouse(mouse)
            }
        }
        
        onWheel: function(wheel) {
            var mousePos = mapToItem(parent, wheel.x, wheel.y)
            console.log("VolumeSlider: Wheel event", wheel.angleDelta.y, "isSliderVisible:", isSliderVisible, "isOverSlider:", isMouseOverSlider({x: mousePos.x, y: mousePos.y}))
            if (isSliderVisible && isMouseOverSlider({x: mousePos.x, y: mousePos.y})) {
                var delta = wheel.angleDelta.y > 0 ? 5 : -5
                adjustVolume(delta)
                wheel.accepted = true
            } else {
                wheel.accepted = false
            }
        }
    }

    // Kontener z animacją fade in/out
    Item {
        id: volumeSliderContainer
        anchors.fill: parent
        visible: (sharedData && sharedData.volumeVisible)  // Use visible instead of opacity for mouse events
        
        // Właściwości animacji scale
        scale: (sharedData && sharedData.volumeVisible) ? 1.0 : 0.95
        
        // Lekka animacja scale dla lepszego efektu
        Behavior on scale {
            NumberAnimation { 
                duration: 300
                easing.type: Easing.OutQuart
            }
        }

        // Tło jednolite z animacją fade
        Rectangle {
            id: volumeSliderBackground
            anchors.fill: parent
            anchors.rightMargin: 0
            radius: 0
            color: (sharedData && sharedData.colorBackground) ? sharedData.colorBackground : "#111111"
            opacity: (sharedData && sharedData.volumeVisible) ? 1.0 : 0.0
            
            Behavior on opacity {
                NumberAnimation { 
                    duration: 300
                    easing.type: Easing.OutQuart
                }
            }
        }
        
        // Border tylko z lewej strony z animacją fade
        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: 1
            color: (sharedData && sharedData.colorSecondary) ? sharedData.colorSecondary : "#252525"
            opacity: (sharedData && sharedData.volumeVisible) ? 1.0 : 0.0
            
            Behavior on opacity {
                NumberAnimation { 
                    duration: 300
                    easing.type: Easing.OutQuart
                }
            }
        }

        // Slider głośności - pionowy z animacją fade
        Column {
            id: volumeSliderColumn
            anchors.centerIn: parent
            spacing: 18
            width: parent.width - 18
            opacity: (sharedData && sharedData.volumeVisible) ? 1.0 : 0.0
            
            Behavior on opacity {
                NumberAnimation { 
                    duration: 300
                    easing.type: Easing.OutQuart
                }
            }

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
                z: 1000  // High z-index for the entire slider container

                // Tło slidera
                Rectangle {
                    id: sliderTrack
                    anchors.centerIn: parent
                    width: 5
                    height: parent.height
                    color: (sharedData && sharedData.colorPrimary) ? sharedData.colorPrimary : "#3a3a3a"
                    radius: 0
                    z: 1
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
                    z: 2
                    
                    Behavior on height {
                        NumberAnimation { 
                            duration: 150
                            easing.type: Easing.OutQuart
                        }
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
        interval: 1000  // Zwiększony interwał
        onTriggered: {
            // Sprawdź czy myszka nie jest ani nad sliderem ani nad detektorem
            console.log("hideDelayTimer triggered, sliderMouseArea.containsMouse:", sliderMouseArea.containsMouse, "volumeEdgeHovered:", sharedData ? sharedData.volumeEdgeHovered : "null")
            if (sharedData && !sliderMouseArea.containsMouse && !sharedData.volumeEdgeHovered) {
                console.log("Hiding volume slider")
                sharedData.volumeVisible = false
            } else {
                console.log("Not hiding - mouse still over slider or edge")
            }
        }
    }
    
    // Nasłuchuj zmian w volumeEdgeHovered i uruchamiaj timer gdy myszka opuści detektor
    Connections {
        target: sharedData
        function onVolumeEdgeHoveredChanged() {
            console.log("volumeEdgeHovered changed to:", sharedData ? sharedData.volumeEdgeHovered : "null", "sliderMouseArea.containsMouse:", sliderMouseArea.containsMouse)
            if (sharedData && !sharedData.volumeEdgeHovered) {
                // Myszka opuściła detektor - uruchom timer tylko jeśli myszka nie jest nad sliderem
                // Dodaj małe opóźnienie, aby dać czas MouseArea na zareagowanie
                Qt.callLater(function() {
                    if (!sliderMouseArea.containsMouse && sharedData && !sharedData.volumeEdgeHovered) {
                        console.log("Starting hideDelayTimer after edge detector exit")
                        hideDelayTimer.stop()
                        hideDelayTimer.restart()
                    } else {
                        console.log("Not starting timer - mouse over slider or edge")
                    }
                })
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


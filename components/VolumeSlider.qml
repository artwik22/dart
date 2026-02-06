import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

PanelWindow {
    id: volumeSliderRoot

    anchors { 
        right: true
        top: true
    }
<<<<<<< HEAD
    implicitWidth: 54
    implicitHeight: 270
=======
    implicitWidth: 49
    implicitHeight: 360  // Height for two sliders
>>>>>>> master
    
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qsvolumeslider"
    exclusiveZone: 0

    property var sharedData: null
    property var screen: null
    
    // Visibility control - always visible, controlled by slideOffset
    visible: true
    color: "transparent"
    
    // Slide in animation from right - negative value moves right (off screen)
    property int slideOffset: (sharedData && sharedData.volumeVisible) ? 0 : -implicitWidth
    
    margins {
<<<<<<< HEAD
        top: (screen && screen.height) ? (screen.height - 270) / 2 : 0
=======
        top: (screen && screen.height) ? (screen.height - 360) / 2 : 0
>>>>>>> master
        bottom: 0
        right: slideOffset
        left: 0
    }
    
    Behavior on slideOffset {
        NumberAnimation {
            duration: 500
            easing.type: Easing.OutExpo
        }
    }

    // MouseArea dla slidera - umieszczony PRZED kontenerem, aktywny tylko gdy widoczny
    MouseArea {
        id: sliderMouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        z: 99999  // Very high z-index to ensure it's on top of everything
        visible: (sharedData && sharedData.volumeVisible) ? true : false  // Visible only when slider is shown
        enabled: (sharedData && sharedData.volumeVisible) ? true : false  // Enabled only when visible
        propagateComposedEvents: true  // Allow events to propagate when disabled
        
<<<<<<< HEAD
        // Calculate slider bounds (centered, 180px high)
        property real sliderY: (parent.height - 180) / 2
        property real sliderHeight: 180
        
        function setVolumeFromMouse(mouse) {
            // Calculate volume based on mouse position relative to slider area
            var relativeY = mouse.y - sliderY
            var newVolume = 100 - Math.round((relativeY / sliderHeight) * 100)
            if (newVolume < 0) newVolume = 0
            if (newVolume > 100) newVolume = 100
            console.log("Setting volume:", newVolume, "from mouse.y:", mouse.y, "relativeY:", relativeY)
            setSystemVolume(newVolume)
        }
        
=======
        // Simple approach: divide window in half - top half is brightness, bottom half is volume
        property real brightnessAreaHeight: parent.height / 2
        property real volumeAreaHeight: parent.height / 2
        
        function setBrightnessFromMouse(mouse) {
            // Calculate brightness based on mouse position in top half
            var relativeY = mouse.y
            var newBrightness = 100 - Math.round((relativeY / brightnessAreaHeight) * 100)
            if (newBrightness < 0) newBrightness = 0
            if (newBrightness > 100) newBrightness = 100
            setSystemBrightness(newBrightness)
        }
        
        function setVolumeFromMouse(mouse) {
            // Calculate volume based on mouse position in bottom half
            var relativeY = mouse.y - brightnessAreaHeight
            var newVolume = 100 - Math.round((relativeY / volumeAreaHeight) * 100)
            if (newVolume < 0) newVolume = 0
            if (newVolume > 100) newVolume = 100
            setSystemVolume(newVolume)
        }
        
        function adjustBrightness(delta) {
            var newBrightness = brightnessValue + delta
            if (newBrightness < 0) newBrightness = 0
            if (newBrightness > 100) newBrightness = 100
            setSystemBrightness(newBrightness)
        }
        
>>>>>>> master
        function adjustVolume(delta) {
            var newVolume = volumeValue + delta
            if (newVolume < 0) newVolume = 0
            if (newVolume > 100) newVolume = 100
            setSystemVolume(newVolume)
        }
        
<<<<<<< HEAD
        // Also handle hover for the entire slider area
        onEntered: {
            console.log("VolumeSlider: Mouse entered PanelWindow area")
=======
        function isInBrightnessArea(y) {
            return y < brightnessAreaHeight
        }
        
        function isInVolumeArea(y) {
            return y >= brightnessAreaHeight
        }
        
        // Also handle hover for the entire slider area
        onEntered: {
>>>>>>> master
            if (sharedData) {
                sharedData.volumeVisible = true
                hideDelayTimer.stop()
            }
        }
        
        onExited: {
<<<<<<< HEAD
            console.log("VolumeSlider: Mouse exited PanelWindow area")
=======
>>>>>>> master
            if (sharedData) {
                // Don't start timer if mouse is still over edge detector
                Qt.callLater(function() {
                    if (sharedData && !sharedData.volumeEdgeHovered) {
<<<<<<< HEAD
                        console.log("Starting hideDelayTimer")
                        hideDelayTimer.stop()
                        hideDelayTimer.restart()
                    } else {
                        console.log("Not starting timer - mouse still over edge detector")
=======
                        hideDelayTimer.stop()
                        hideDelayTimer.restart()
                    } else {
>>>>>>> master
                    }
                })
            }
        }
        
<<<<<<< HEAD
        // Kliknięcie - ustaw volume na podstawie pozycji Y myszki
        onClicked: function(mouse) {
            console.log("VolumeSlider: Mouse clicked at", mouse.x, mouse.y, "volumeVisible:", sharedData ? sharedData.volumeVisible : false)
            if (sharedData && sharedData.volumeVisible) {
                mouse.accepted = true
                setVolumeFromMouse(mouse)
            }
        }
        
        // Przeciąganie - zmieniaj volume podczas przeciągania
        onPositionChanged: function(mouse) {
            if (pressed && sharedData && sharedData.volumeVisible) {
                console.log("VolumeSlider: Mouse dragged to", mouse.x, mouse.y)
                mouse.accepted = true
                setVolumeFromMouse(mouse)
            }
        }
        
        // Scroll - zmieniaj volume
        onWheel: function(wheel) {
            console.log("VolumeSlider: Wheel event", wheel.angleDelta.y, "volumeVisible:", sharedData ? sharedData.volumeVisible : false)
            if (sharedData && sharedData.volumeVisible) {
                var delta = wheel.angleDelta.y > 0 ? 5 : -5
                adjustVolume(delta)
=======
        // Kliknięcie - ustaw brightness lub volume na podstawie pozycji Y myszki
        onClicked: function(mouse) {
            if (sharedData && sharedData.volumeVisible) {
                mouse.accepted = true
                if (isInBrightnessArea(mouse.y)) {
                    setBrightnessFromMouse(mouse)
                } else if (isInVolumeArea(mouse.y)) {
                    setVolumeFromMouse(mouse)
                }
            }
        }
        
        // Przeciąganie - zmieniaj brightness lub volume podczas przeciągania
        onPositionChanged: function(mouse) {
            if (pressed && sharedData && sharedData.volumeVisible) {
                mouse.accepted = true
                if (isInBrightnessArea(mouse.y)) {
                    setBrightnessFromMouse(mouse)
                } else if (isInVolumeArea(mouse.y)) {
                    setVolumeFromMouse(mouse)
                }
            }
        }
        
        // Scroll - zmieniaj brightness lub volume w zależności od pozycji
        onWheel: function(wheel) {
            if (sharedData && sharedData.volumeVisible) {
                var delta = wheel.angleDelta.y > 0 ? 5 : -5
                if (isInBrightnessArea(wheel.y)) {
                    adjustBrightness(delta)
                } else if (isInVolumeArea(wheel.y)) {
                    adjustVolume(delta)
                }
>>>>>>> master
                wheel.accepted = true
            }
        }
    }

    // Kontener z animacją fade in/out
    Item {
<<<<<<< HEAD
        id: volumeSliderContainer
=======
        id: sliderMainContainer
>>>>>>> master
        anchors.fill: parent
        visible: true  // Always visible - use opacity for fade effect instead
        enabled: (sharedData && sharedData.volumeVisible)  // Disable interactions when hidden
        
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

<<<<<<< HEAD
        // Slider głośności - pionowy z animacją fade
        Column {
            id: volumeSliderColumn
            anchors.centerIn: parent
            spacing: 18
            width: parent.width - 18
=======
        // Slider brightness i volume - pionowy z animacją fade
        Column {
            id: slidersColumn
            anchors.centerIn: parent
            spacing: 12
            width: parent.width - 19
>>>>>>> master
            opacity: (sharedData && sharedData.volumeVisible) ? 1.0 : 0.0
            
            Behavior on opacity {
                NumberAnimation { 
                    duration: 300
                    easing.type: Easing.OutQuart
                }
            }

<<<<<<< HEAD
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
=======
            // ========== BRIGHTNESS SECTION ==========
            // Ikona jasności
            Text {
                id: brightnessIcon
                text: {
                    if (brightnessValue === 0) return "󰃞"
                    else if (brightnessValue < 33) return "󰃟"
                    else if (brightnessValue < 66) return "󰃠"
                    else return "󰃝"
                }
                font.pixelSize: 25
>>>>>>> master
                color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#f5f5f5"
                anchors.horizontalCenter: parent.horizontalCenter
            }

<<<<<<< HEAD
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
=======
            // Brightness Slider
            Item {
                id: brightnessSliderContainer
                width: parent.width
                height: 100
                anchors.horizontalCenter: parent.horizontalCenter
                z: 1000

                // Tło slidera
                Rectangle {
                    id: brightnessSliderTrack
>>>>>>> master
                    anchors.centerIn: parent
                    width: 5
                    height: parent.height
                    color: (sharedData && sharedData.colorPrimary) ? sharedData.colorPrimary : "#3a3a3a"
                    radius: 0
                    z: 1
                }

                // Wypełnienie slidera
                Rectangle {
<<<<<<< HEAD
                    id: sliderFill
                    anchors.bottom: sliderTrack.bottom
                    anchors.horizontalCenter: sliderTrack.horizontalCenter
                    width: sliderTrack.width
                    height: sliderTrack.height * (volumeValue / 100)
=======
                    id: brightnessSliderFill
                    anchors.bottom: brightnessSliderTrack.bottom
                    anchors.horizontalCenter: brightnessSliderTrack.horizontalCenter
                    width: brightnessSliderTrack.width
                    height: brightnessSliderTrack.height * (brightnessValue / 100)
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

            // Wartość jasności w procentach
            Text {
                id: brightnessValueText
                text: Math.round(brightnessValue) + "%"
                font.pixelSize: 13
                font.family: "sans-serif"
                font.weight: Font.Medium
                font.letterSpacing: 0.2
                color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#f5f5f5"
                anchors.horizontalCenter: parent.horizontalCenter
            }

            // ========== VOLUME SECTION ==========
            // Ikona głośności
            Text {
                id: volumeIcon
                text: {
                    if (volumeValue === 0) return "󰝟"
                    else if (volumeValue < 33) return "󰕿"
                    else if (volumeValue < 66) return "󰖀"
                    else return "󰕾"
                }
                font.pixelSize: 25
                color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#f5f5f5"
                anchors.horizontalCenter: parent.horizontalCenter
            }

            // Volume Slider
            Item {
                id: volumeSliderContainer
                width: parent.width
                height: 100
                anchors.horizontalCenter: parent.horizontalCenter
                z: 1000

                // Tło slidera
                Rectangle {
                    id: volumeSliderTrack
                    anchors.centerIn: parent
                    width: 5
                    height: parent.height
                    color: (sharedData && sharedData.colorPrimary) ? sharedData.colorPrimary : "#3a3a3a"
                    radius: 0
                    z: 1
                }

                // Wypełnienie slidera
                Rectangle {
                    id: volumeSliderFill
                    anchors.bottom: volumeSliderTrack.bottom
                    anchors.horizontalCenter: volumeSliderTrack.horizontalCenter
                    width: volumeSliderTrack.width
                    height: volumeSliderTrack.height * (volumeValue / 100)
>>>>>>> master
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
<<<<<<< HEAD
                font.pixelSize: 12
=======
                font.pixelSize: 13
>>>>>>> master
                font.family: "sans-serif"
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
        interval: 500  // Krótszy interwał dla szybszej reakcji
        onTriggered: {
            // Sprawdź czy myszka nie jest ani nad sliderem ani nad detektorem
            // Użyj Qt.callLater aby upewnić się, że wszystkie stany są zaktualizowane
            Qt.callLater(function() {
                var mouseOverSlider = sliderMouseArea.containsMouse
                var mouseOverEdge = sharedData ? sharedData.volumeEdgeHovered : false
<<<<<<< HEAD
                console.log("hideDelayTimer triggered, mouseOverSlider:", mouseOverSlider, "mouseOverEdge:", mouseOverEdge)
                if (sharedData && !mouseOverSlider && !mouseOverEdge) {
                    console.log("Hiding volume slider")
                    sharedData.volumeVisible = false
                } else {
                    console.log("Not hiding - mouse still over slider or edge")
=======
                if (sharedData && !mouseOverSlider && !mouseOverEdge) {
                    sharedData.volumeVisible = false
>>>>>>> master
                }
            })
        }
    }
    
    // Nasłuchuj zmian w volumeEdgeHovered i uruchamiaj timer gdy myszka opuści detektor
    Connections {
        target: sharedData
        function onVolumeEdgeHoveredChanged() {
<<<<<<< HEAD
            console.log("volumeEdgeHovered changed to:", sharedData ? sharedData.volumeEdgeHovered : "null", "sliderMouseArea.containsMouse:", sliderMouseArea.containsMouse)
=======
>>>>>>> master
            if (sharedData && sharedData.volumeEdgeHovered) {
                // Myszka weszła na detektor - pokaż slider i zatrzymaj timer
                sharedData.volumeVisible = true
                hideDelayTimer.stop()
            } else if (sharedData && !sharedData.volumeEdgeHovered) {
                // Myszka opuściła detektor - uruchom timer tylko jeśli myszka nie jest nad sliderem
                Qt.callLater(function() {
                    if (!sliderMouseArea.containsMouse && sharedData && !sharedData.volumeEdgeHovered) {
<<<<<<< HEAD
                        console.log("Starting hideDelayTimer after edge detector exit")
                        hideDelayTimer.stop()
                        hideDelayTimer.restart()
                    } else {
                        console.log("Not starting timer - mouse over slider")
=======
                        hideDelayTimer.stop()
                        hideDelayTimer.restart()
>>>>>>> master
                    }
                })
            }
        }
    }

    // --- Właściwości ---
<<<<<<< HEAD
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
=======
    property real volumeValue: 35
    property real brightnessValue: 50

    // Debounce: przy przeciąganiu wysyłamy polecenie do systemu co 50ms zamiast przy każdym ruchu – brak kolejki i natychmiastowa reakcja UI.
    property int _pendingBrightness: -1
    property int _pendingVolume: -1
    Timer {
        id: applyBrightnessTimer
        interval: 50
        repeat: false
        onTriggered: {
            if (_pendingBrightness >= 0 && sharedData && sharedData.runCommand) {
                var p = Math.round(Math.max(0, Math.min(100, _pendingBrightness)))
                sharedData.runCommand(['brightnessctl', 'set', p + '%'], null)
                _pendingBrightness = -1
            }
        }
    }
    Timer {
        id: applyVolumeTimer
        interval: 50
        repeat: false
        onTriggered: {
            if (_pendingVolume >= 0 && sharedData && sharedData.runCommand) {
                var v = Math.round(Math.max(0, Math.min(100, _pendingVolume)))
                sharedData.runCommand(['pactl', 'set-sink-volume', '@DEFAULT_SINK@', v + '%'], null)
                _pendingVolume = -1
            }
        }
    }

    // --- Funkcje Brightness ---
    function setSystemBrightness(value) {
        var v = Math.round(Math.max(0, Math.min(100, value)))
        brightnessValue = v
        _pendingBrightness = v
        applyBrightnessTimer.restart()
    }

    function getSystemBrightness() {
        if (sharedData && sharedData.runCommand) sharedData.runCommand(['sh','-c','CURRENT=$(brightnessctl get); MAX=$(brightnessctl max); echo $(awk "BEGIN {printf \"%.0f\", ($CURRENT / $MAX * 100)}") > /tmp/quickshell_brightness'], readSystemBrightness)
    }

    function readSystemBrightness() {
        var xhr = new XMLHttpRequest()
        xhr.open("GET", "file:///tmp/quickshell_brightness")
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE && xhr.responseText && xhr.responseText.trim() !== "") {
                var b = parseInt(xhr.responseText.trim())
                if (!isNaN(b) && b >= 0 && b <= 100) brightnessValue = b
>>>>>>> master
            }
        }
        xhr.send()
    }

<<<<<<< HEAD
    // Timer do odświeżania głośności
=======
    // --- Funkcje Volume ---
    function setSystemVolume(value) {
        var v = Math.round(Math.max(0, Math.min(100, value)))
        volumeValue = v
        _pendingVolume = v
        applyVolumeTimer.restart()
    }

    function getSystemVolume() {
        if (sharedData && sharedData.runCommand) sharedData.runCommand(['sh','-c','pactl get-sink-volume @DEFAULT_SINK@ | head -1 | awk "{print $5}" | tr -d % > /tmp/quickshell_volume'], readSystemVolume)
    }

    function readSystemVolume() {
        var xhr = new XMLHttpRequest()
        xhr.open("GET", "file:///tmp/quickshell_volume")
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE && xhr.responseText && xhr.responseText.trim() !== "") {
                var vol = parseInt(xhr.responseText.trim())
                if (!isNaN(vol) && vol >= 0 && vol <= 100) volumeValue = vol
            }
        }
        xhr.send()
    }

    // Timer do odświeżania głośności i jasności z systemu (co 1s)
>>>>>>> master
    Timer {
        id: volumeTimer
        interval: 1000
        repeat: true
        running: true
        onTriggered: {
            getSystemVolume()
<<<<<<< HEAD
            // Poczekaj 150ms i przeczytaj volume
            Qt.createQmlObject("import QtQuick; Timer { interval: 150; running: true; repeat: false; onTriggered: volumeSliderRoot.readSystemVolume() }", volumeSliderRoot)
        }
        Component.onCompleted: {
            getSystemVolume()
            Qt.createQmlObject("import QtQuick; Timer { interval: 150; running: true; repeat: false; onTriggered: volumeSliderRoot.readSystemVolume() }", volumeSliderRoot)
        }
    }

    // Obserwuj zmiany volumeVisible
=======
            getSystemBrightness()
        }
        Component.onCompleted: {
            syncVolumeOnStart()
            syncBrightnessOnStart()
        }
    }

    // Gdy slider się otwiera – odśwież wartości z systemu (bez długiego łańcucha callbacków)
>>>>>>> master
    Connections {
        target: sharedData
        function onVolumeVisibleChanged() {
            if (sharedData && sharedData.volumeVisible) {
<<<<<<< HEAD
                // Gdy slider się otwiera, sprawdź aktualną głośność
                getSystemVolume()
                Qt.createQmlObject("import QtQuick; Timer { interval: 150; running: true; repeat: false; onTriggered: volumeSliderRoot.readSystemVolume() }", volumeSliderRoot)
=======
                getSystemVolume()
                getSystemBrightness()
>>>>>>> master
            }
        }
    }

<<<<<<< HEAD
    Component.onCompleted: {
        getSystemVolume()
    }
=======
    function syncVolumeOnStart() {
        getSystemVolume()
    }

    function syncBrightnessOnStart() {
        getSystemBrightness()
    }

    Component.onCompleted: {
        syncBrightnessOnStart()
    }
>>>>>>> master
}


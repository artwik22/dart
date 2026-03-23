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
    implicitWidth: 60
    implicitHeight: 330  // Mniejsza, bardziej kompaktowa wysokość
    
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qsvolumeslider"
    exclusiveZone: 0

    property var sharedData: null
    property var screen: null
    
    // Visibility control - always visible, controlled by slideOffset
    visible: true
    color: "transparent"
    
    // Slide in animation from right - positive value moves right (off screen)
    property int slideOffset: (sharedData && sharedData.volumeVisible) ? 0 : 60
    
    margins {
        top: (screen && screen.height) ? (screen.height - 330) / 2 : 0
        bottom: 0
        right: 0 // Fixed margin to prevent flickering on Mango WM
        left: 0
    }
    
    Behavior on slideOffset {
        NumberAnimation {
            duration: 400
            easing.type: Easing.OutCubic
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
        
        function adjustVolume(delta) {
            var newVolume = volumeValue + delta
            if (newVolume < 0) newVolume = 0
            if (newVolume > 100) newVolume = 100
            setSystemVolume(newVolume)
        }
        
        function isInBrightnessArea(y) {
            return y < brightnessAreaHeight
        }
        
        function isInVolumeArea(y) {
            return y >= brightnessAreaHeight
        }
        
        // Also handle hover for the entire slider area
        onEntered: {
            if (sharedData) {
                sharedData.volumeVisible = true
                hideDelayTimer.stop()
            }
        }
        
        onExited: {
            if (sharedData) {
                // Don't start timer if mouse is still over edge detector
                Qt.callLater(function() {
                    if (sharedData && !sharedData.volumeEdgeHovered) {
                        hideDelayTimer.stop()
                        hideDelayTimer.restart()
                    } else {
                    }
                })
            }
        }
        
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
                wheel.accepted = true
            }
        }
    }

    // Kontener z animacją fade in/out
    Item {
        id: sliderMainContainer
        anchors.fill: parent
        clip: true // Ensure content sliding out is hidden
        
        transform: Translate {
            x: volumeSliderRoot.slideOffset
        }
        
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
            radius: (sharedData && sharedData.quickshellBorderRadius) ? sharedData.quickshellBorderRadius : 0
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

        // Nowoczesny styl Segmentowy (Spine / Equalizer) - Wersja Kompaktowa
        Column {
            id: slidersColumn
            anchors.centerIn: parent
            spacing: 20
            width: parent.width - 12
            opacity: (sharedData && sharedData.volumeVisible) ? 1.0 : 0.0
            
            Behavior on opacity {
                NumberAnimation { 
                    duration: 300
                    easing.type: Easing.OutCubic
                }
            }

            // ========== BRIGHTNESS SPINE ==========
            Item {
                id: brightnessSection
                width: parent.width
                height: 140 // Wyraźnie obniżona wysokość
                anchors.horizontalCenter: parent.horizontalCenter
                z: 1000

                // Ikona jasności
                Text {
                    id: brightnessIcon
                    text: {
                        if (brightnessValue === 0) return "󰃞"
                        else if (brightnessValue < 33) return "󰃟"
                        else if (brightnessValue < 66) return "󰃠"
                        else return "󰃝"
                    }
                    font.pixelSize: 20
                    color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#f5f5f5"
                    anchors.top: parent.top
                    anchors.horizontalCenter: parent.horizontalCenter
                    
                    scale: sliderMouseArea.containsMouse && sliderMouseArea.isInBrightnessArea(sliderMouseArea.mouseY) ? 1.15 : 1.0
                    Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }
                }

                // Segmentowy suwak (Spine)
                Column {
                    anchors.top: brightnessIcon.bottom
                    anchors.bottom: brightnessValueText.top
                    anchors.topMargin: 8
                    anchors.bottomMargin: 8
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 3

                    Repeater {
                        model: 12 // Mniej elementów, by pasowały do mniejszej wysokości
                        Item {
                            width: 24
                            height: (parent.height - (11 * 3)) / 12
                            anchors.horizontalCenter: parent.horizontalCenter
                            
                            // Im niższy index, tym wyżej na ekranie
                            property real threshold: 100 - (index * 8.33)
                            property bool isActive: brightnessValue >= (threshold - 4) // nieco mniejsza precyzja wymuszona ilością segmentów

                            Rectangle {
                                anchors.centerIn: parent
                                height: parent.height
                                
                                // Kropla (4px) -> Aktywny (14px) -> Hover (20px)
                                width: parent.isActive ? 
                                       (sliderMouseArea.containsMouse && sliderMouseArea.isInBrightnessArea(sliderMouseArea.mouseY) ? 20 : 14) : 
                                       4
                                
                                radius: 2
                                color: parent.isActive ? 
                                       ((sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff") : 
                                       ((sharedData && sharedData.colorSurfaceContainerHigh) ? sharedData.colorSurfaceContainerHigh : "#2B2930")
                                opacity: parent.isActive ? 1.0 : 0.6

                                Behavior on width { NumberAnimation { duration: 350; easing.type: Easing.OutExpo } }
                                Behavior on color { ColorAnimation { duration: 250 } }
                            }
                        }
                    }
                }

                // Wartość procentowa
                Text {
                    id: brightnessValueText
                    text: Math.round(brightnessValue) + "%"
                    font.pixelSize: 12
                    font.family: "sans-serif"
                    font.weight: Font.DemiBold
                    color: sliderMouseArea.containsMouse && sliderMouseArea.isInBrightnessArea(sliderMouseArea.mouseY) ? ((sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff") : ((sharedData && sharedData.colorText) ? sharedData.colorText : "#f5f5f5")
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    
                    Behavior on color { ColorAnimation { duration: 150; easing.type: Easing.OutQuad } }
                }
            }

            // ========== VOLUME SPINE ==========
            Item {
                id: volumeSection
                width: parent.width
                height: 140
                anchors.horizontalCenter: parent.horizontalCenter
                z: 1000

                // Ikona głośności
                Text {
                    id: volumeIcon
                    text: {
                        if (volumeValue === 0) return "󰝟"
                        else if (volumeValue < 33) return "󰕿"
                        else if (volumeValue < 66) return "󰖀"
                        else return "󰕾"
                    }
                    font.pixelSize: 20
                    color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#f5f5f5"
                    anchors.top: parent.top
                    anchors.horizontalCenter: parent.horizontalCenter
                    
                    scale: sliderMouseArea.containsMouse && sliderMouseArea.isInVolumeArea(sliderMouseArea.mouseY) ? 1.15 : 1.0
                    Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }
                }

                // Segmentowy suwak głośności
                Column {
                    anchors.top: volumeIcon.bottom
                    anchors.bottom: volumeValueText.top
                    anchors.topMargin: 8
                    anchors.bottomMargin: 8
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 3

                    Repeater {
                        model: 12
                        Item {
                            width: 24
                            height: (parent.height - (11 * 3)) / 12
                            anchors.horizontalCenter: parent.horizontalCenter
                            
                            property real threshold: 100 - (index * 8.33)
                            property bool isActive: volumeValue >= (threshold - 4)

                            Rectangle {
                                anchors.centerIn: parent
                                height: parent.height
                                
                                width: parent.isActive ? 
                                       (sliderMouseArea.containsMouse && sliderMouseArea.isInVolumeArea(sliderMouseArea.mouseY) ? 20 : 14) : 
                                       4
                                
                                radius: 2
                                color: parent.isActive ? 
                                       ((sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff") : 
                                       ((sharedData && sharedData.colorSurfaceContainerHigh) ? sharedData.colorSurfaceContainerHigh : "#2B2930")
                                opacity: parent.isActive ? 1.0 : 0.6

                                Behavior on width { NumberAnimation { duration: 350; easing.type: Easing.OutExpo } }
                                Behavior on color { ColorAnimation { duration: 250 } }
                            }
                        }
                    }
                }

                // Wartość procentowa
                Text {
                    id: volumeValueText
                    text: Math.round(volumeValue) + "%"
                    font.pixelSize: 12
                    font.family: "sans-serif"
                    font.weight: Font.DemiBold
                    color: sliderMouseArea.containsMouse && sliderMouseArea.isInVolumeArea(sliderMouseArea.mouseY) ? ((sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff") : ((sharedData && sharedData.colorText) ? sharedData.colorText : "#f5f5f5")
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    
                    Behavior on color { ColorAnimation { duration: 150; easing.type: Easing.OutQuad } }
                }
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
                if (sharedData && !mouseOverSlider && !mouseOverEdge) {
                    sharedData.volumeVisible = false
                }
            })
        }
    }
    
    // Nasłuchuj zmian w volumeEdgeHovered i uruchamiaj timer gdy myszka opuści detektor
    Connections {
        target: sharedData
        function onVolumeEdgeHoveredChanged() {
            if (sharedData && sharedData.volumeEdgeHovered) {
                // Myszka weszła na detektor - pokaż slider i zatrzymaj timer
                sharedData.volumeVisible = true
                hideDelayTimer.stop()
            } else if (sharedData && !sharedData.volumeEdgeHovered) {
                // Myszka opuściła detektor - uruchom timer tylko jeśli myszka nie jest nad sliderem
                Qt.callLater(function() {
                    if (!sliderMouseArea.containsMouse && sharedData && !sharedData.volumeEdgeHovered) {
                        hideDelayTimer.stop()
                        hideDelayTimer.restart()
                    }
                })
            }
        }
    }

    // --- Właściwości ---
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
            }
        }
        xhr.send()
    }

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
    Timer {
        id: volumeTimer
        interval: 1000
        repeat: true
        running: true
        onTriggered: {
            getSystemVolume()
            getSystemBrightness()
        }
        Component.onCompleted: {
            syncVolumeOnStart()
            syncBrightnessOnStart()
        }
    }

    // Gdy slider się otwiera – odśwież wartości z systemu (bez długiego łańcucha callbacków)
    Connections {
        target: sharedData
        function onVolumeVisibleChanged() {
            if (sharedData && sharedData.volumeVisible) {
                getSystemVolume()
                getSystemBrightness()
            }
        }
    }

    function syncVolumeOnStart() {
        getSystemVolume()
    }

    function syncBrightnessOnStart() {
        getSystemBrightness()
    }

    Component.onCompleted: {
        syncBrightnessOnStart()
    }
}


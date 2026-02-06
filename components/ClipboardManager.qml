import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

PanelWindow {
    id: clipboardManagerRoot

    required property var screen
    
    screen: clipboardManagerRoot.screen
    
    // Dynamic anchors based on sidebar position
    anchors.left: (sharedData && sharedData.sidebarPosition === "left") ? true : false
    anchors.right: (sharedData && sharedData.sidebarPosition === "top") ? true : false
    anchors.top: true
    anchors.bottom: true
    implicitWidth: 288
    implicitHeight: 533
    
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qsclipboard"
    WlrLayershell.keyboardFocus: (sharedData && sharedData.clipboardVisible) ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    exclusiveZone: 0

    property var sharedData: null
    
    // Fix: Unmap window when not visible to avoid blocking clicks
    visible: (sharedData && sharedData.clipboardVisible) || opacityBinding > 0.01
    
    // Use an internal property to track animation state if needed, or rely on bind
    property real opacityBinding: 0
    Behavior on opacityBinding { NumberAnimation { duration: 300 } }
    Binding on opacityBinding { value: (sharedData && sharedData.clipboardVisible) ? 1.0 : 0.0 }

    color: "transparent"
    
    // Marginesy dopasowane do sidebar 37px (80%)
    property int slideOffsetLeft: (sharedData && sharedData.clipboardVisible) ? 41 : -implicitWidth
    property int slideOffsetRight: (sharedData && sharedData.clipboardVisible) ? 21 : -implicitWidth
    
    property int topMargin: (sharedData && sharedData.sidebarPosition === "top" && sharedData.sidebarVisible) ? 43 : 7
    
    margins {
        top: topMargin
        bottom: 7
        left: (sharedData && sharedData.sidebarPosition === "left") ? slideOffsetLeft : 0
        right: (sharedData && sharedData.sidebarPosition === "top") ? slideOffsetRight : 0
    }
    
    // Animacja slideOffset dla lewej strony
    Behavior on slideOffsetLeft {
        NumberAnimation { 
            duration: 300
            easing.type: Easing.OutQuart
        }
    }
    
    // Animacja slideOffset dla prawej strony
    Behavior on slideOffsetRight {
        NumberAnimation { 
            duration: 300
            easing.type: Easing.OutQuart
        }
    }
    
    // Animacja topMargin
    Behavior on topMargin {
        NumberAnimation { 
            duration: 300
            easing.type: Easing.OutQuart
        }
    }

    // Kontener z animacją fade in/out
    Item {
        id: clipboardContainer
        anchors.fill: parent
        
        opacity: (sharedData && sharedData.clipboardVisible) ? 1.0 : 0.0
        scale: (sharedData && sharedData.clipboardVisible) ? 1.0 : 0.95
        
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
        
        enabled: opacity > 0.1
        focus: (sharedData && sharedData.clipboardVisible)
        
        Keys.onPressed: function(event) {
            if (event.key === Qt.Key_Escape) {
                if (sharedData) {
                    sharedData.clipboardVisible = false
                }
                event.accepted = true
            }
        }
        
        // Material Design clipboard background with elevation
        Rectangle {
            id: clipboardBackground
            anchors.fill: parent
            color: (sharedData && sharedData.colorBackground) ? sharedData.colorBackground : "#0a0a0a"
            radius: 0
            
            // Material Design elevation shadow
            Rectangle {
                anchors.fill: parent
                anchors.margins: -3
                color: "transparent"
                border.color: Qt.rgba(0, 0, 0, 0.25)  // Material shadow
                border.width: 2
                z: -1
            }
            
            Column {
                anchors.fill: parent
                anchors.margins: 13
                spacing: 7
                
                // Header
                Row {
                    width: parent.width
                    spacing: 9
                    
                    Text {
                        text: "󰨸 Clipboard"
                        font.pixelSize: 15
                        font.family: "sans-serif"
                        font.weight: Font.Bold
                        color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff"
                    }
                    
                    Item { width: parent.width - 160; height: 1 }
                    
                    // Material Design button with elevation
                    Rectangle {
                        id: clearButtonRect
                        width: 25
                        height: 25
                        radius: 0
                        // Material Design button color
                        color: clearButtonMouseArea.containsMouse ? 
                            ((sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff") : 
                            ((sharedData && sharedData.colorPrimary) ? sharedData.colorPrimary : "#1a1a1a")
                        
                        property real buttonScale: clearButtonMouseArea.pressed ? 0.95 : (clearButtonMouseArea.containsMouse ? 1.05 : 1.0)
                        property real buttonElevation: clearButtonMouseArea.pressed ? 1 : (clearButtonMouseArea.containsMouse ? 3 : 2)
                        
                        // Material Design elevation shadow
                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: -clearButtonRect.buttonElevation
                            color: "transparent"
                            border.color: Qt.rgba(0, 0, 0, 0.15 + clearButtonRect.buttonElevation * 0.05)
                            border.width: clearButtonRect.buttonElevation
                            z: -1
                            
                            Behavior on border.color {
                                ColorAnimation {
                                    duration: 200
                                    easing.type: Easing.OutQuart
                                }
                            }
                        }
                        
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
                            text: "󰆐"
                            font.pixelSize: 13
                            anchors.centerIn: parent
                            color: clearButtonMouseArea.containsMouse ? 
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
                            id: clearButtonMouseArea
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true
                            onClicked: {
                                clipboardHistoryModel.clear()
                            }
                        }
                    }
                }
                
                // History list
                ScrollView {
                    width: parent.width
                    height: parent.height - 42
                    
                    ListView {
                        id: clipboardListView
                        model: clipboardHistoryModel
                        spacing: 6
                        
                        delegate: Rectangle {
                            width: clipboardListView.width
                            height: Math.max(32, contentText.implicitHeight + 13)
                            radius: 0
                            // Material Design card color
                            color: itemMouseArea.containsMouse ? 
                                ((sharedData && sharedData.colorSecondary) ? sharedData.colorSecondary : "#141414") : 
                                ((sharedData && sharedData.colorPrimary) ? sharedData.colorPrimary : "#1a1a1a")
                            
                            property real cardElevation: itemMouseArea.containsMouse ? 2 : 1
                            
                            // Material Design elevation shadow
                            Rectangle {
                                anchors.fill: parent
                                anchors.margins: -cardElevation
                                color: "transparent"
                                border.color: Qt.rgba(0, 0, 0, 0.15 + cardElevation * 0.05)
                                border.width: cardElevation
                                z: -1
                                
                                Behavior on border.color {
                                    ColorAnimation {
                                        duration: 200
                                        easing.type: Easing.OutQuart
                                    }
                                }
                            }
                            
                            Behavior on color {
                                ColorAnimation {
                                    duration: 200
                                    easing.type: Easing.OutQuart
                                }
                            }
                            
                            Text {
                                id: contentText
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                text: {
                                    var txt = model.text || ""
                                    return txt.length > 100 ? txt.substring(0, 100) + "..." : txt
                                }
                                font.pixelSize: 10
                                font.family: "sans-serif"
                                color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff"
                                wrapMode: Text.Wrap
                                elide: Text.ElideRight
                            }
                            
                            MouseArea {
                                id: itemMouseArea
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                hoverEnabled: true
                                onClicked: {
                                    copyToClipboard(model.text)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    // Clipboard history model
    ListModel {
        id: clipboardHistoryModel
    }
    
    // Monitor clipboard changes
    Timer {
        id: clipboardMonitorTimer
        interval: 500  // Check every 500ms
        running: true
        repeat: true
        onTriggered: checkClipboard()
    }
    
    property string lastClipboardContent: ""
    
    function checkClipboard() {
        if (sharedData && sharedData.runCommand) sharedData.runCommand(['sh', '-c', 'wl-paste > /tmp/quickshell_clipboard_content 2>/dev/null || echo "" > /tmp/quickshell_clipboard_content'], readClipboardContent)
    }
    
    function readClipboardContent() {
        var xhr = new XMLHttpRequest()
        xhr.open("GET", "file:///tmp/quickshell_clipboard_content")
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200 || xhr.status === 0) {
                    var content = xhr.responseText
                    processClipboardContent(content)
                }
            }
        }
        xhr.send()
    }
    
    function processClipboardContent(content) {
        if (!content || content.trim() === "") return
        
        var trimmed = content.trim()
        
        // Skip if same as last content
        if (trimmed === lastClipboardContent) return
        
        // Skip if already in history
        for (var i = 0; i < clipboardHistoryModel.count; i++) {
            if (clipboardHistoryModel.get(i).text === trimmed) {
                // Move to top
                clipboardHistoryModel.move(i, 0, 1)
                lastClipboardContent = trimmed
                return
            }
        }
        
        // Add to history (max 50 items)
        if (clipboardHistoryModel.count >= 50) {
            clipboardHistoryModel.remove(clipboardHistoryModel.count - 1)
        }
        
        clipboardHistoryModel.insert(0, { text: trimmed })
        lastClipboardContent = trimmed
    }
    
    function copyToClipboard(text) {
        var esc = text.replace(/\\/g, "\\\\").replace(/"/g, '\\"').replace(/\$/g, "\\$").replace(/`/g, "\\`")
        if (sharedData && sharedData.runCommand) sharedData.runCommand(['sh', '-c', 'echo -n "' + esc + '" > /tmp/quickshell_clipboard_copy'], copyFromFile)
        lastClipboardContent = text
    }
    
    function copyFromFile() {
        if (sharedData && sharedData.runCommand) sharedData.runCommand(['sh', '-c', 'cat /tmp/quickshell_clipboard_copy | wl-copy'])
    }
    
    Component.onCompleted: {
        checkClipboard()
    }
}


import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

PanelWindow {
    id: clipboardManagerRoot

    required property var screen
    
    screen: clipboardManagerRoot.screen
    
    anchors { 
        left: true
        top: true
        bottom: true
    }
    implicitWidth: 320
    implicitHeight: 500
    
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qsclipboard"
    WlrLayershell.keyboardFocus: (sharedData && sharedData.clipboardVisible) ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    exclusiveZone: 0

    property var sharedData: null
    
    visible: true
    color: "transparent"
    
    // Właściwość do animacji margins.left
    // Sidebar ma szerokość 36px, więc dodajemy margines 40px aby nie nachodził
    property int slideOffset: (sharedData && sharedData.clipboardVisible) ? 40 : -implicitWidth
    
    margins {
        top: 8
        bottom: 8
        left: slideOffset
        right: 0
    }
    
    // Animacja slideOffset
    Behavior on slideOffset {
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
        
        Rectangle {
            id: clipboardBackground
            anchors.fill: parent
            color: (sharedData && sharedData.colorBackground) ? sharedData.colorBackground : "#0a0a0a"
            radius: 0
            
            Column {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12
                
                // Header
                Row {
                    width: parent.width
                    spacing: 12
                    
                    Text {
                        text: "󰨸 Clipboard"
                        font.pixelSize: 18
                        font.family: "JetBrains Mono"
                        font.weight: Font.Bold
                        color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff"
                    }
                    
                    Item { width: parent.width - 200; height: 1 }
                    
                    Rectangle {
                        width: 32
                        height: 32
                        radius: 0
                        color: clearButtonMouseArea.containsMouse ? 
                            ((sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff") : 
                            ((sharedData && sharedData.colorSecondary) ? sharedData.colorSecondary : "#141414")
                        
                        property real buttonScale: clearButtonMouseArea.pressed ? 0.9 : (clearButtonMouseArea.containsMouse ? 1.1 : 1.0)
                        
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
                            font.pixelSize: 16
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
                    height: parent.height - 60
                    
                    ListView {
                        id: clipboardListView
                        model: clipboardHistoryModel
                        spacing: 8
                        
                        delegate: Rectangle {
                            width: clipboardListView.width
                            height: Math.max(40, contentText.implicitHeight + 16)
                            radius: 0
                            color: itemMouseArea.containsMouse ? 
                                ((sharedData && sharedData.colorSecondary) ? sharedData.colorSecondary : "#141414") : 
                                ((sharedData && sharedData.colorPrimary) ? sharedData.colorPrimary : "#1a1a1a")
                            
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
                                font.pixelSize: 13
                                font.family: "JetBrains Mono"
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
        // Use wl-paste to read clipboard content (Wayland)
        // Write clipboard content to temp file
        Qt.createQmlObject("import Quickshell.Io; import QtQuick; Process { command: ['sh', '-c', 'wl-paste > /tmp/quickshell_clipboard_content 2>/dev/null || echo \"\" > /tmp/quickshell_clipboard_content']; running: true }", clipboardManagerRoot)
        // Wait a moment and read the result
        Qt.createQmlObject("import QtQuick; Timer { interval: 100; running: true; repeat: false; onTriggered: clipboardManagerRoot.readClipboardContent() }", clipboardManagerRoot)
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
        // Write text to temp file first, then copy from file to clipboard
        // This avoids shell escaping issues
        Qt.createQmlObject("import Quickshell.Io; import QtQuick; Process { command: ['sh', '-c', 'echo -n \"' + text.replace(/\\\"/g, '\\\\\"').replace(/\$/g, '\\\\$').replace(/`/g, '\\\\`') + '\" > /tmp/quickshell_clipboard_copy']; running: true }", clipboardManagerRoot)
        // Wait a moment and copy to clipboard
        Qt.createQmlObject("import QtQuick; Timer { interval: 50; running: true; repeat: false; onTriggered: clipboardManagerRoot.copyFromFile() }", clipboardManagerRoot)
        lastClipboardContent = text
    }
    
    function copyFromFile() {
        // Copy from file to clipboard using wl-copy (Wayland)
        Qt.createQmlObject("import Quickshell.Io; import QtQuick; Process { command: ['sh', '-c', 'cat /tmp/quickshell_clipboard_copy | wl-copy']; running: true }", clipboardManagerRoot)
    }
    
    Component.onCompleted: {
        checkClipboard()
    }
}


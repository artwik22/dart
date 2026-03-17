import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "."

Item {
    id: clipboardTabRoot
    property var sharedData: null
    property int currentTab: 0
    property string lastClipboardContent: ""
    signal copyToClipboardRequested(string text)
    property var clipboardModel
    
    // Monitor clipboard changes – only when dashboard is open and Clipboard tab is active
    Timer {
        id: dashboardClipboardMonitorTimer
        interval: 2000
        running: (sharedData && sharedData.menuVisible) && (currentTab === 1)
        repeat: true
        onTriggered: checkClipboard()
    }

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
        for (var i = 0; i < clipboardModel.count; i++) {
            if (clipboardModel.get(i).text === trimmed) {
                // Move to top
                clipboardModel.move(i, 0, 1)
                lastClipboardContent = trimmed
                return
            }
        }
        
        // Add to history (max 50 items)
        if (clipboardModel.count >= 50) {
            clipboardModel.remove(clipboardModel.count - 1)
        }
        
        clipboardModel.insert(0, { text: trimmed })
    }

    function copyToClipboard(text) {
        var esc = text.replace(/\\/g, "\\\\").replace(/"/g, '\\"').replace(/\$/g, "\\$").replace(/`/g, "\\`")
        if (sharedData && sharedData.runCommand) sharedData.runCommand(['sh', '-c', 'echo -n "' + esc + '" > /tmp/quickshell_clipboard_copy'], copyFromFile)
        lastClipboardContent = text
    }
    
    function copyFromFile() {
        if (sharedData && sharedData.runCommand) sharedData.runCommand(['sh', '-c', 'cat /tmp/quickshell_clipboard_copy | wl-copy'])
    }

    anchors.fill: parent
    visible: currentTab === 1
    opacity: currentTab === 1 ? 1.0 : 0.0
    x: currentTab === 1 ? 0 : (currentTab < 1 ? -parent.width * 0.3 : parent.width * 0.3)
    scale: currentTab === 1 ? 1.0 : 0.95
    
    Behavior on opacity {
        NumberAnimation { 
            duration: 400
            easing.type: Easing.OutCubic
        }
    }
    
    Behavior on x {
        NumberAnimation {
            duration: 400
            easing.type: Easing.OutCubic
        }
    }
    
    Behavior on scale {
        NumberAnimation {
            duration: 400
            easing.type: Easing.OutCubic
        }
    }
    
    Column {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 5
        
        // Header
        Row {
            width: parent.width
            spacing: 5
            
            Text {
                text: "󰨸 Clipboard"
                font.pixelSize: 10
                font.family: "sans-serif"
                font.weight: Font.Bold
                color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff"
            }
            
            Item { width: parent.width - 160; height: 1 }
            
            Rectangle {
                width: 25
                height: 25
                radius: (sharedData && sharedData.quickshellBorderRadius !== undefined) ? sharedData.quickshellBorderRadius : 0
                color: clearClipboardButtonMouseArea.containsMouse ? 
                    ((sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff") : 
                    ((sharedData && sharedData.colorSecondary) ? sharedData.colorSecondary : "#141414")
                
                property real buttonScale: clearClipboardButtonMouseArea.pressed ? 0.9 : (clearClipboardButtonMouseArea.containsMouse ? 1.1 : 1.0)
                
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
                    font.pixelSize: 9
                    anchors.centerIn: parent
                    color: clearClipboardButtonMouseArea.containsMouse ? 
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
                    id: clearClipboardButtonMouseArea
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: {
                        clipboardModel.clear()
                    }
                }
            }
        }
        
        // History list
        ScrollView {
            width: parent.width
            height: parent.height - 48
            
            ListView {
                reuseItems: true
                id: clipboardListView
                model: clipboardModel
                spacing: 5
                
                delegate: Rectangle {
                    width: clipboardListView.width
                    height: Math.max(32, contentTextClipboard.implicitHeight + 13)
                    radius: (sharedData && sharedData.quickshellBorderRadius !== undefined) ? sharedData.quickshellBorderRadius : 0
                    // Material Design card color
                    color: itemClipboardMouseArea.containsMouse ? 
                        ((sharedData && sharedData.colorSecondary) ? sharedData.colorSecondary : "#141414") : 
                        ((sharedData && sharedData.colorPrimary) ? sharedData.colorPrimary : "#1a1a1a")
                    
                    property real cardElevation: itemClipboardMouseArea.containsMouse ? 2 : 1
                    
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
                        id: contentTextClipboard
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
                        id: itemClipboardMouseArea
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onClicked: {
                            clipboardTabRoot.copyToClipboard(model.text)
                        }
                    }
                }
            }
        }
    }
}

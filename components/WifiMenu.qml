import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Rectangle {
    id: root
    width: 200
    height: 280
    color: (sharedData && sharedData.colorSecondary) ? sharedData.colorSecondary : "#141414"
    radius: (sharedData && sharedData.quickshellBorderRadius !== undefined) ? sharedData.quickshellBorderRadius : 12

    property var sharedData: null
    property var sidePanelRoot: null
    
    // Internal State
    property bool scanning: false
    property string statusMessage: ""
    property var networks: [] // Array of objects { ssid, signal, security, active }
    property string currentSsid: ""
    
    // Password Dialog State
    property bool showPasswordPrompt: false
    property string pendingSsid: ""
    
    function runCommand(cmd, callback) {
        if (sidePanelRoot && sidePanelRoot.runAndRead) {
            sidePanelRoot.runAndRead(cmd, callback)
        } else if (sharedData && sharedData.runCommand) {
            // Fallback if runAndRead not available directly
             sharedData.runCommand(['sh', '-c', cmd], callback)
        }
    }

    function scanNetworks() {
        scanning = true
        statusMessage = "Scanning..."
        // Format: SSID:SIGNAL:SECURITY:IN-USE
        runCommand("nmcli -t -f SSID,SIGNAL,SECURITY,IN-USE dev wifi list | grep -v '^:' | sort -u -t: -k1,1", function(out) {
            scanning = false
            statusMessage = ""
            if (!out) return
            
            var lines = out.trim().split('\n')
            var newNetworks = []
            
            for (var i = 0; i < lines.length; i++) {
                var parts = lines[i].split(':')
                if (parts.length >= 3) {
                    var ssid = parts[0]
                    // Skip if empty SSID
                    if (!ssid) continue
                    
                    var signal = parseInt(parts[1]) || 0
                    var security = parts[2]
                    var inUse = (parts.length > 3 && parts[3] === "*")
                    
                    newNetworks.push({
                        ssid: ssid,
                        signal: signal,
                        security: security,
                        active: inUse
                    })
                    
                    if (inUse) currentSsid = ssid
                }
            }
            
            // Sort: Active first, then Signal strength desc
            newNetworks.sort(function(a, b) {
                if (a.active) return -1
                if (b.active) return 1
                return b.signal - a.signal
            })
            
            networks = newNetworks
        })
    }
    
    function connectToNetwork(ssid, password) {
        statusMessage = "Connecting to " + ssid + "..."
        var cmd = ""
        if (password) {
            cmd = "nmcli dev wifi connect '" + ssid + "' password '" + password + "'"
        } else {
            // Try connecting without password (saved network)
            cmd = "nmcli connection up id '" + ssid + "' || nmcli dev wifi connect '" + ssid + "'"
        }
        
        runCommand(cmd, function(out) {
            // Wait a bit then rescan
            scanTimer.restart()
            // Check status
            runCommand("nmcli -t -f STATE g", function(s) {
                if (s && s.trim() === "connected") {
                    statusMessage = "Connected"
                } else {
                    statusMessage = "Connection failed"
                }
            })
        })
    }
    
    Component.onCompleted: scanNetworks()
    
    Timer {
        id: scanTimer
        interval: 10000
        repeat: true
        running: root.visible
        onTriggered: scanNetworks()
    }
    
    ColumnLayout {
        anchors.fill: root
        anchors.margins: 10
        spacing: 10
        
        // Header
        RowLayout {
            Layout.fillWidth: true
            Text {
                text: "Wi-Fi"
                color: (sharedData.colorOnSurface || "#ffffff")
                font.pixelSize: 14
                font.weight: Font.Bold
                Layout.fillWidth: true
            }
            
            // Scan Button
            Rectangle {
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32
                radius: 16
                color: scanMa.containsMouse ? Qt.rgba(1,1,1,0.1) : "transparent"
                
                Text {
                    anchors.centerIn: parent
                    text: root.scanning ? "..." : "󰱔" // Refresh icon
                    font.family: "Material Design Icons"
                    font.pixelSize: 18
                    color: (sharedData.colorOnSurface || "#ffffff")
                }
                
                MouseArea {
                    id: scanMa
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: scanNetworks()
                }
            }
            
            // Toggle Switch (placeholder for radio off/on)
             Rectangle {
                Layout.preferredWidth: 48
                Layout.preferredHeight: 24
                radius: 12
                color: (sharedData.colorPrimary || "#D0BCFF")
                
                Rectangle {
                    width: 20
                    height: 20
                    radius: 10
                    color: "#ffffff"
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: parent.right
                    anchors.rightMargin: 2
                }
                 MouseArea {
                    anchors.fill: parent
                    onClicked: {
                         runCommand("nmcli radio wifi off", function() {
                             // Close menu or update state
                         })
                    }
                }
            }
        }
        
        // Status Message
        Text {
            visible: statusMessage !== ""
            text: statusMessage
            color: (sharedData.colorOnSurfaceVariant || "#cccccc")
            font.pixelSize: 12
            Layout.fillWidth: true
        }

        // Network List
        ListView {
            id: wifiList
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: root.networks
            delegate: Rectangle {
                width: ListView.view.width
                height: 42
                color: itemMa.containsMouse ? (modelData.active ? Qt.rgba((sharedData.colorPrimary || "#D0BCFF").r, (sharedData.colorPrimary || "#D0BCFF").g, (sharedData.colorPrimary || "#D0BCFF").b, 0.25) : Qt.rgba(1,1,1,0.1)) : (modelData.active ? Qt.rgba((sharedData.colorPrimary || "#D0BCFF").r, (sharedData.colorPrimary || "#D0BCFF").g, (sharedData.colorPrimary || "#D0BCFF").b, 0.15) : "transparent")
                radius: 8
                border.width: modelData.active ? 1 : (itemMa.containsMouse ? 1 : 0)
                border.color: modelData.active ? Qt.rgba((sharedData.colorPrimary || "#D0BCFF").r, (sharedData.colorPrimary || "#D0BCFF").g, (sharedData.colorPrimary || "#D0BCFF").b, 0.5) : Qt.rgba(1,1,1,0.05)
                Behavior on color { ColorAnimation { duration: 150 } }
                
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 6
                    spacing: 10
                    
                    Text {
                        text: modelData.signal > 75 ? "󰤨" : (modelData.signal > 50 ? "󰤥" : (modelData.signal > 25 ? "󰤢" : "󰤟"))
                        font.family: "Material Design Icons"
                        font.pixelSize: 20
                        color: modelData.active ? (sharedData.colorPrimary || "#D0BCFF") : (itemMa.containsMouse ? "#ffffff" : Qt.rgba(1,1,1,0.7))
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                    
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        Text {
                            text: modelData.ssid
                            font.pixelSize: 12
                            font.weight: modelData.active ? Font.Bold : Font.Normal
                            color: modelData.active ? (sharedData.colorPrimary || "#D0BCFF") : (sharedData.colorOnSurface || "#ffffff")
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                        Text {
                            text: modelData.active ? "Connected" : (modelData.security !== "" ? "Secure" : "Open")
                            font.pixelSize: 9
                            color: modelData.active ? Qt.rgba((sharedData.colorPrimary || "#D0BCFF").r, (sharedData.colorPrimary || "#D0BCFF").g, (sharedData.colorPrimary || "#D0BCFF").b, 0.8) : (sharedData.colorOnSurfaceVariant || "#aaaaaa")
                            Layout.fillWidth: true
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                    }
                    
                    // Buttons for active connection
                    Row {
                        visible: modelData.active
                        spacing: 8
                        
                        // Disconnect Button
                        Rectangle {
                            width: 24; height: 24; radius: 12
                            color: disconMa.containsMouse ? "#ff4444" : Qt.rgba(1,0,0,0.1)
                            scale: disconMa.pressed ? 0.9 : 1.0
                            Behavior on color { ColorAnimation { duration: 150 } }
                            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
                            Text {
                                anchors.centerIn: parent
                                text: "󰅙" 
                                font.family: "Material Design Icons"
                                color: disconMa.containsMouse ? "#ffffff" : "#ff4444"
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }
                            MouseArea {
                                id: disconMa
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    runCommand("nmcli con down id '" + modelData.ssid + "'")
                                    scanTimer.restart()
                                }
                            }
                        }
                    }
                }
                
                MouseArea {
                    id: itemMa
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        if (!modelData.active) {
                            // Check if saved connection exists
                            runCommand("nmcli -g NAME connection show", function(saved) {
                                var isSaved = false
                                if (saved) {
                                    var savedList = saved.split('\n')
                                    if (savedList.indexOf(modelData.ssid) !== -1) isSaved = true
                                }
                                
                                if (isSaved || modelData.security === "") {
                                    connectToNetwork(modelData.ssid, null)
                                } else {
                                    // Prompt for Password
                                    root.pendingSsid = modelData.ssid
                                    passInput.text = ""
                                    root.showPasswordPrompt = true
                                }
                            })
                        }
                    }
                }
            }
        }
        
        // Footer actions
        RowLayout {
            Layout.fillWidth: true
            
            Rectangle {
                Layout.fillWidth: true
                height: 28
                radius: 8
                color: netSetMa.containsMouse ? Qt.rgba(1,1,1,0.15) : Qt.rgba(1,1,1,0.05)
                scale: netSetMa.pressed ? 0.98 : 1.0
                border.width: 1
                border.color: Qt.rgba(1,1,1,0.05)
                Behavior on color { ColorAnimation { duration: 150 } }
                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
                
                Text {
                    anchors.centerIn: parent
                    text: "Network Settings"
                    color: (sharedData.colorOnSurface || "#ffffff")
                    font.pixelSize: 11
                    font.weight: Font.Medium
                }
                
                MouseArea {
                    id: netSetMa
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: runCommand("nm-connection-editor")
                }
            }
        }
    }
    
    // Password Prompt Overlay
    Rectangle {
        id: passOverlay
        anchors.fill: parent
        color: (sharedData && sharedData.colorSurface) ? sharedData.colorSurface : "#141414"
        radius: (sharedData && sharedData.quickshellBorderRadius !== undefined) ? sharedData.quickshellBorderRadius : 16
        visible: root.showPasswordPrompt
        z: 100
        
        ColumnLayout {
            anchors.centerIn: parent
            width: parent.width - 32
            spacing: 16
            
            Text {
                text: "Enter Password"
                font.pixelSize: 16
                font.weight: Font.Bold
                color: (sharedData.colorOnSurface || "#ffffff")
                Layout.alignment: Qt.AlignHCenter
            }
            
            Text {
                text: "For " + root.pendingSsid
                font.pixelSize: 12
                color: (sharedData.colorOnSurfaceVariant || "#cccccc")
                Layout.alignment: Qt.AlignHCenter
            }
            
            Rectangle {
                Layout.fillWidth: true
                height: 40
                color: Qt.rgba(1,1,1,0.05)
                radius: 8
                border.width: 1
                border.color: passInput.activeFocus ? (sharedData.colorPrimary || "#D0BCFF") : "transparent"
                
                TextInput {
                    id: passInput
                    anchors.fill: parent
                    anchors.margins: 8
                    verticalAlignment: TextInput.AlignVCenter
                    color: (sharedData.colorOnSurface || "#ffffff")
                    echoMode: TextInput.Password
                    onAccepted: {
                        root.showPasswordPrompt = false
                        connectToNetwork(root.pendingSsid, passInput.text)
                    }
                }
            }
            
            RowLayout {
                Layout.fillWidth: true
                spacing: 12
                
                Rectangle {
                    Layout.fillWidth: true
                    height: 36
                    radius: 8
                    color: cancelMa.containsMouse ? Qt.rgba(1,1,1,0.15) : Qt.rgba(1,1,1,0.05)
                    scale: cancelMa.pressed ? 0.98 : 1.0
                    border.width: 1
                    border.color: Qt.rgba(1,1,1,0.05)
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
                    
                    Text {
                        anchors.centerIn: parent
                        text: "Cancel"
                        color: (sharedData.colorOnSurface || "#ffffff")
                        font.pixelSize: 13
                        font.weight: Font.Medium
                    }
                    
                    MouseArea {
                        id: cancelMa
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: root.showPasswordPrompt = false
                    }
                }
                
                Rectangle {
                    Layout.fillWidth: true
                    height: 36
                    radius: 8
                    color: connectMa.containsMouse ? Qt.lighter((sharedData.colorPrimary || "#D0BCFF"), 1.1) : (sharedData.colorPrimary || "#D0BCFF")
                    scale: connectMa.pressed ? 0.98 : 1.0
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
                    
                    Text {
                        anchors.centerIn: parent
                        text: "Connect"
                        color: (sharedData.colorOnPrimary || "#000000")
                        font.pixelSize: 13
                        font.weight: Font.Bold
                    }
                    
                    MouseArea {
                        id: connectMa
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            root.showPasswordPrompt = false
                            connectToNetwork(root.pendingSsid, passInput.text)
                        }
                    }
                }
            }
        }
    }
}

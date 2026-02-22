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
    
    // Mask for flush alignment using sidePanel position
    Rectangle {
        color: parent.color
        width: (sidePanelRoot && sidePanelRoot.isHorizontal) ? parent.width : parent.radius
        height: (sidePanelRoot && sidePanelRoot.isHorizontal) ? parent.radius : parent.height
        anchors.left: (sidePanelRoot && sidePanelRoot.panelPosition === "left") ? parent.left : undefined
        anchors.right: (sidePanelRoot && sidePanelRoot.panelPosition === "right") ? parent.right : undefined
        anchors.top: (sidePanelRoot && sidePanelRoot.panelPosition === "top") ? parent.top : undefined
        anchors.bottom: (sidePanelRoot && sidePanelRoot.panelPosition === "bottom") ? parent.bottom : undefined
    }
    
    scale: 0.95 + (0.05 * (typeof popoverWindow !== "undefined" ? popoverWindow.showProgress : 1.0))
    Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
    
    // Internal State
    property bool scanning: false
    property string statusMessage: ""
    property var devices: [] // Array of objects { mac, name, icon, connected, paired }
    
    function runCommand(cmd, callback) {
        if (sidePanelRoot && sidePanelRoot.runAndRead) {
            sidePanelRoot.runAndRead(cmd, callback)
        } else if (sharedData && sharedData.runCommand) {
             sharedData.runCommand(['sh', '-c', cmd], callback)
        }
    }

    function scanDevices() {
        statusMessage = "Refreshing..."
        var cmd = "for mac in $(echo \"devices\" | bluetoothctl | grep \"^Device\" | awk '{print $2}' | head -n 15); do " +
                  "info=$(echo \"info $mac\" | bluetoothctl); " +
                  "name=$(echo \"$info\" | grep \"Name:\" | cut -d: -f2- | xargs); " +
                  "conn=$(echo \"$info\" | grep -q \"Connected: yes\" && echo \"yes\" || echo \"no\"); " +
                  "pair=$(echo \"$info\" | grep -q \"Paired: yes\" && echo \"yes\" || echo \"no\"); " +
                  "icon=$(echo \"$info\" | grep \"Icon:\" | cut -d: -f2- | xargs); " +
                  "[ -z \"$icon\" ] && icon=\"bluetooth\"; " +
                  "echo \"$mac|$name|$conn|$pair|$icon\"; " +
                  "done"
                  
        runCommand(cmd, function(out) {
            statusMessage = ""
            if (!out) return
            
            var lines = out.trim().split('\n')
            var newDevices = []
            
            for (var i = 0; i < lines.length; i++) {
                var parts = lines[i].split('|')
                if (parts.length >= 4) {
                    var mac = parts[0]
                    var name = parts[1]
                    var connected = (parts[2] === "yes")
                    var paired = (parts[3] === "yes")
                    var icon = parts[4] || "bluetooth"
                    
                    newDevices.push({
                        mac: mac,
                        name: name,
                        connected: connected,
                        paired: paired,
                        icon: icon
                    })
                }
            }
            
            // Sort: Connected first, then Paired, then Name
            newDevices.sort(function(a, b) {
                if (a.connected && !b.connected) return -1
                if (!a.connected && b.connected) return 1
                if (a.paired && !b.paired) return -1
                if (!a.paired && b.paired) return 1
                return a.name.localeCompare(b.name)
            })
            
            devices = newDevices
        })
    }
    
    function toggleScan() {
        if (scanning) {
            runCommand("bluetoothctl scan off", function() { scanning = false })
        } else {
            scanning = true
            statusMessage = "Discovering..."
            runCommand("timeout 8 bluetoothctl scan on || true", function() { 
                scanning = false
                scanDevices()
            })
        }
    }
    
    function connectDevice(mac) {
        statusMessage = "Connecting..."
        runCommand("timeout 10 bluetoothctl connect " + mac, function(out) {
            scanTimer.restart()
             // Check output for success/fail if needed
        })
    }
    
    function disconnectDevice(mac) {
        statusMessage = "Disconnecting..."
        runCommand("timeout 10 bluetoothctl disconnect " + mac, function(out) {
            scanTimer.restart()
        })
    }
    
    function pairDevice(mac) {
        statusMessage = "Pairing..."
        runCommand("timeout 15 bluetoothctl pair " + mac, function(out) {
             statusMessage = "Trusting..."
             runCommand("timeout 5 bluetoothctl trust " + mac, function(out2) {
                 connectDevice(mac)
             })
        })
    }

     // Initial check for scan status
    function checkScanStatus() {
        runCommand("bluetoothctl show | grep 'Discovering: yes'", function(out) {
            scanning = (out && out.trim().length > 0)
        })
    }
    
    Component.onCompleted: {
        checkScanStatus()
        scanDevices()
    }
    
    Timer {
        id: scanTimer
        interval: 5000
        repeat: true
        running: root.visible
        onTriggered: {
            checkScanStatus()
            scanDevices()
        }
    }
    
    
    ColumnLayout {
        anchors.fill: root
        anchors.margins: 10
        spacing: 10
        
        // Header
        RowLayout {
            Layout.fillWidth: true
            Text {
                text: "Bluetooth"
                color: (sharedData.colorOnSurface || "#ffffff")
                font.pixelSize: 14
                font.weight: Font.Bold
                Layout.fillWidth: true
            }
            
            // Scan Toggle
             Rectangle {
                Layout.preferredWidth: 60
                Layout.preferredHeight: 22
                radius: 11
                color: scanToggleMa.containsMouse ? (root.scanning ? Qt.lighter((sharedData.colorPrimary || "#D0BCFF"), 1.1) : Qt.rgba(1,1,1,0.2)) : (root.scanning ? (sharedData.colorPrimary || "#D0BCFF") : Qt.rgba(1,1,1,0.1))
                scale: scanToggleMa.pressed ? 0.95 : 1.0
                Behavior on color { ColorAnimation { duration: 150 } }
                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
                
                Text {
                    anchors.centerIn: parent
                    text: root.scanning ? "Scanning" : "Scan"
                    font.pixelSize: 9
                    font.weight: Font.Bold
                    color: root.scanning ? (sharedData.colorOnPrimary || "#000000") : (sharedData.colorOnSurface || "#ffffff")
                }
                
                MouseArea {
                    id: scanToggleMa
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: toggleScan()
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

        // Device List
        ListView {
            id: btList
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: root.devices
            delegate: Rectangle {
                width: ListView.view.width
                height: 42
                color: itemMa.containsMouse ? (modelData.connected ? Qt.rgba((sharedData.colorPrimary || "#D0BCFF").r, (sharedData.colorPrimary || "#D0BCFF").g, (sharedData.colorPrimary || "#D0BCFF").b, 0.25) : Qt.rgba(1,1,1,0.1)) : (modelData.connected ? Qt.rgba((sharedData.colorPrimary || "#D0BCFF").r, (sharedData.colorPrimary || "#D0BCFF").g, (sharedData.colorPrimary || "#D0BCFF").b, 0.15) : "transparent")
                radius: 8
                border.width: modelData.connected ? 1 : (itemMa.containsMouse ? 1 : 0)
                border.color: modelData.connected ? Qt.rgba((sharedData.colorPrimary || "#D0BCFF").r, (sharedData.colorPrimary || "#D0BCFF").g, (sharedData.colorPrimary || "#D0BCFF").b, 0.5) : Qt.rgba(1,1,1,0.05)
                Behavior on color { ColorAnimation { duration: 150 } }
                
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 6
                    spacing: 10
                    
                    Text {
                        text: {
                            if (modelData.icon.includes("headset") || modelData.icon.includes("headphone")) return "󰋋"
                            if (modelData.icon.includes("audio")) return "󰓃"
                            if (modelData.icon.includes("phone")) return "󰏲"
                            if (modelData.icon.includes("computer") || modelData.icon.includes("laptop")) return "󰌢"
                            return "󰂯"
                        }
                        font.family: "Material Design Icons"
                        font.pixelSize: 20
                        color: modelData.connected ? (sharedData.colorPrimary || "#D0BCFF") : (itemMa.containsMouse ? "#ffffff" : Qt.rgba(1,1,1,0.7))
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                    
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Text {
                            text: modelData.name
                            font.pixelSize: 13
                            font.weight: modelData.connected ? Font.Bold : Font.Normal
                            color: modelData.connected ? (sharedData.colorPrimary || "#D0BCFF") : (sharedData.colorOnSurface || "#ffffff")
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                        Text {
                            text: modelData.connected ? "Connected" : (modelData.paired ? "Paired" : "New Device")
                            font.pixelSize: 10
                            color: modelData.connected ? Qt.rgba((sharedData.colorPrimary || "#D0BCFF").r, (sharedData.colorPrimary || "#D0BCFF").g, (sharedData.colorPrimary || "#D0BCFF").b, 0.8) : (sharedData.colorOnSurfaceVariant || "#aaaaaa")
                            Layout.fillWidth: true
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                    }
                    
                    // Action Button
                    Rectangle {
                        width: 60; height: 22; radius: 11
                        visible: itemMa.containsMouse || modelData.connected
                        color: btnMa.containsMouse ? (modelData.connected ? "#ff4444" : (sharedData.colorPrimary || "#D0BCFF")) : Qt.rgba(1,1,1,0.1)
                        scale: btnMa.pressed ? 0.92 : 1.0
                        Behavior on color { ColorAnimation { duration: 150 } }
                        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
                        
                        Text {
                            anchors.centerIn: parent
                            text: modelData.connected ? "Disconnect" : (modelData.paired ? "Connect" : "Pair")
                            font.pixelSize: 9
                            font.weight: Font.Bold
                            color: btnMa.containsMouse ? (modelData.connected ? "#ffffff" : "#000000") : (sharedData.colorOnSurface || "#ffffff")
                        }
                        
                        MouseArea {
                            id: btnMa
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                if (modelData.connected) disconnectDevice(modelData.mac)
                                else if (modelData.paired) connectDevice(modelData.mac)
                                else pairDevice(modelData.mac)
                            }
                        }
                    }
                }
                
                MouseArea {
                    id: itemMa
                    anchors.fill: parent
                    hoverEnabled: true
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
                color: bmSetMa.containsMouse ? Qt.rgba(1,1,1,0.15) : Qt.rgba(1,1,1,0.05)
                scale: bmSetMa.pressed ? 0.98 : 1.0
                border.width: 1
                border.color: Qt.rgba(1,1,1,0.05)
                Behavior on color { ColorAnimation { duration: 150 } }
                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
                
                Text {
                    anchors.centerIn: parent
                    text: "Bluetooth Manager"
                    color: (sharedData.colorOnSurface || "#ffffff")
                    font.pixelSize: 11
                    font.weight: Font.Medium
                }
                
                MouseArea {
                    id: bmSetMa
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: runCommand("blueman-manager")
                }
            }
        }
    }
}

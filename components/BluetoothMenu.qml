import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Rectangle {
    id: root
    width: 300
    height: 400
    color: (sharedData && sharedData.colorSecondary) ? sharedData.colorSecondary : "#141414"
    radius: (sharedData && sharedData.quickshellBorderRadius !== undefined) ? sharedData.quickshellBorderRadius : 10

    property var sharedData: null
    property var sidePanelRoot: null
    
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
        // Format: MAC Name (Connected: yes/no, Paired: yes/no)
        // We'll use a loop in shell to get info
        var cmd = "bluetoothctl devices | while read -r line; do " +
                  "mac=$(echo $line | cut -d' ' -f2); " +
                  "name=$(echo $line | cut -d' ' -f3-); " +
                  "info=$(bluetoothctl info $mac); " +
                  "conn=$(echo \"$info\" | grep 'Connected: yes' && echo 'yes' || echo 'no'); " +
                  "pair=$(echo \"$info\" | grep 'Paired: yes' && echo 'yes' || echo 'no'); " +
                  "icon=$(echo \"$info\" | grep 'Icon:' | cut -d: -f2- | xargs); " +
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
            runCommand("bluetoothctl scan on", function() { scanning = true })
        }
    }
    
    function connectDevice(mac) {
        statusMessage = "Connecting..."
        runCommand("bluetoothctl connect " + mac, function(out) {
            scanTimer.restart()
             // Check output for success/fail if needed
        })
    }
    
    function disconnectDevice(mac) {
        statusMessage = "Disconnecting..."
        runCommand("bluetoothctl disconnect " + mac, function(out) {
            scanTimer.restart()
        })
    }
    
    function pairDevice(mac) {
        statusMessage = "Pairing..."
        runCommand("bluetoothctl pair " + mac, function(out) {
             statusMessage = "Trusting..."
             runCommand("bluetoothctl trust " + mac, function(out2) {
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
        anchors.margins: 16
        spacing: 12
        
        // Header
        RowLayout {
            Layout.fillWidth: true
            Text {
                text: "Bluetooth"
                color: (sharedData.colorOnSurface || "#ffffff")
                font.pixelSize: 18
                font.weight: Font.Bold
                Layout.fillWidth: true
            }
            
            // Scan Toggle
             Rectangle {
                Layout.preferredWidth: 64
                Layout.preferredHeight: 24
                radius: 12
                color: root.scanning ? (sharedData.colorPrimary || "#D0BCFF") : Qt.rgba(1,1,1,0.1)
                
                Text {
                    anchors.centerIn: parent
                    text: root.scanning ? "Scanning" : "Scan"
                    font.pixelSize: 10
                    font.weight: Font.Bold
                    color: root.scanning ? (sharedData.colorOnPrimary || "#000000") : (sharedData.colorOnSurface || "#ffffff")
                }
                
                MouseArea {
                    anchors.fill: parent
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
                height: 48
                color: itemMa.containsMouse ? Qt.rgba(1,1,1,0.05) : "transparent"
                radius: 8
                
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 12
                    
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
                        color: modelData.connected ? (sharedData.colorPrimary || "#D0BCFF") : (sharedData.colorOnSurface || "#ffffff")
                    }
                    
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Text {
                            text: modelData.name
                            font.pixelSize: 14
                            font.weight: modelData.connected ? Font.Bold : Font.Normal
                            color: (sharedData.colorOnSurface || "#ffffff")
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                        Text {
                            text: modelData.connected ? "Connected" : (modelData.paired ? "Paired" : "New Device")
                            font.pixelSize: 11
                            color: (sharedData.colorOnSurfaceVariant || "#aaaaaa")
                            Layout.fillWidth: true
                        }
                    }
                    
                    // Action Button
                    Rectangle {
                        width: 60; height: 24; radius: 12
                        visible: itemMa.containsMouse || modelData.connected
                        color: btnMa.containsMouse ? (modelData.connected ? "#ff4444" : (sharedData.colorPrimary || "#D0BCFF")) : Qt.rgba(1,1,1,0.1)
                        
                        Text {
                            anchors.centerIn: parent
                            text: modelData.connected ? "Disconnect" : (modelData.paired ? "Connect" : "Pair")
                            font.pixelSize: 10
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
            
            Button {
                text: "Bluetooth Manager"
                Layout.fillWidth: true
                background: Rectangle {
                    color: Qt.rgba(1,1,1,0.1)
                    radius: 8
                }
                contentItem: Text {
                    text: parent.text
                    color: (sharedData.colorOnSurface || "#ffffff")
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                onClicked: runCommand("blueman-manager")
            }
        }
    }
}

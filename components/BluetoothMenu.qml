import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects

Rectangle {
    id: bluetoothRoot
    width: 260
    height: 380
    color: "transparent"
    radius: (sharedData && sharedData.quickshellBorderRadius !== undefined) ? sharedData.quickshellBorderRadius : 12

    property var sharedData: null
    property var sidePanelRoot: null
    property var popoverWindow: null
    
    // ── Design Tokens ──
    property color dsAccent: (sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff"
    property color dsSurface: (sharedData && sharedData.colorSecondary) ? Qt.rgba(sharedData.colorSecondary.r, sharedData.colorSecondary.g, sharedData.colorSecondary.b, 1.0) : "#141414"
    property color dsBorder: Qt.rgba(1, 1, 1, 0.1)
    property real dsRadius: bluetoothRoot.radius

    // ── Interaction Logic ──
    property bool isEnabled: false
    property bool isScanning: false
    property string statusMessage: ""
    
    ListModel { id: bluetoothModel }

    function runCommand(cmd, callback) {
        if (!sharedData || !sharedData.runCommand) return
        var tmp = "/tmp/qs_bt_" + Math.random().toString(36).substring(7)
        sharedData.runCommand(['sh', '-c', cmd + " > " + tmp + " 2>/dev/null"], function() {
            var xhr = new XMLHttpRequest()
            xhr.open("GET", "file://" + tmp)
            xhr.onreadystatechange = function() {
                if (xhr.readyState === XMLHttpRequest.DONE) {
                    var out = (xhr.responseText || "").trim()
                    if (typeof callback === "function") callback(out)
                    sharedData.runCommand(['rm', '-f', tmp])
                }
            }
            xhr.send()
        })
    }

    function updateStatus() {
        runCommand("bluetoothctl show", function(out) {
            isEnabled = out.indexOf("Powered: yes") !== -1;
            fetchDevices();
        });
    }

    function togglePower() {
        var cmd = isEnabled ? "bluetoothctl power off" : "bluetoothctl power on";
        runCommand(cmd, updateStatus);
    }

    function fetchDevices() {
        if (!isEnabled) { bluetoothModel.clear(); return; }
        // Fetch paired devices
        runCommand("bluetoothctl devices Paired", function(out) {
            bluetoothModel.clear();
            var lines = out.trim().split('\n');
            for (var i = 0; i < lines.length; i++) {
                var line = lines[i].trim();
                if (line.length > 0) {
                    var parts = line.split(' ');
                    if (parts.length >= 3) {
                        var mac = parts[1];
                        var name = parts.slice(2).join(' ');
                        bluetoothModel.append({ mac: mac, name: name, paired: true, connected: false });
                    }
                }
            }
        });
    }

    function toggleScan() {
        if (!isEnabled) return;
        isScanning = !isScanning;
        if (isScanning) {
            runCommand("bluetoothctl scan on", function() {
                statusMessage = "Discovering...";
            });
        } else {
            runCommand("bluetoothctl scan off", function() {
                statusMessage = "";
                fetchDevices();
            });
        }
    }

    Timer { interval: 5000; running: bluetoothRoot.visible; repeat: true; onTriggered: updateStatus() }
    Component.onCompleted: updateStatus()

    // ── Main Content Container ──
    Rectangle {
        id: mainBg
        anchors.fill: parent
        color: dsSurface
        radius: dsRadius
        border.width: 0
        border.color: dsBorder

        // ── Flush Mask Logic (FIXED) ──
        Rectangle {
            id: flushMask
            color: mainBg.color
            z: 10
            width: (sidePanelRoot && !sidePanelRoot.isHorizontal) ? parent.radius : parent.width
            height: (sidePanelRoot && sidePanelRoot.isHorizontal) ? parent.radius : parent.height
            
            anchors.right: (sidePanelRoot && sidePanelRoot.panelPosition === "right") ? parent.right : undefined
            anchors.left: (sidePanelRoot && sidePanelRoot.panelPosition === "left") ? parent.left : undefined
            anchors.bottom: (sidePanelRoot && sidePanelRoot.panelPosition === "bottom") ? parent.bottom : undefined
            anchors.top: (sidePanelRoot && sidePanelRoot.panelPosition === "top") ? parent.top : undefined
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 0
        z: 11

        // ── Header ──
        RowLayout {
            Layout.fillWidth: true
            Layout.bottomMargin: 16
            spacing: 12

            ColumnLayout {
                spacing: -2
                Text { 
                    text: "Bluetooth"; color: "#ffffff"; 
                    font.pixelSize: 20; font.family: "Outfit"; font.weight: Font.Black; font.letterSpacing: -0.5
                }
                Text { 
                    text: isEnabled ? (isScanning ? "Discovering..." : "Ready") : "Disabled"; 
                    color: isEnabled ? dsAccent : Qt.rgba(1, 1, 1, 0.4); 
                    font.pixelSize: 11; font.family: "Inter"; font.weight: Font.Medium; opacity: 0.8
                }
            }

            Item { Layout.fillWidth: true }

            // Custom Switch to match Quickshell style
            Rectangle {
                width: 40; height: 22; radius: 11
                color: isEnabled ? dsAccent : Qt.rgba(1, 1, 1, 0.1)
                Behavior on color { ColorAnimation { duration: 200 } }
                
                Rectangle {
                    width: 16; height: 16; radius: 8
                    color: "#ffffff"
                    anchors.verticalCenter: parent.verticalCenter
                    x: isEnabled ? 22 : 2
                    Behavior on x { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }
                }
                
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: togglePower()
                }
            }
        }

        // ── Device List ──
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            // Empty State (Refined)
            ColumnLayout {
                anchors.centerIn: parent
                visible: bluetoothModel.count === 0
                spacing: 12
                Text { 
                    text: isEnabled ? "󰂯" : "󰂲"; font.family: "Material Design Icons"; 
                    font.pixelSize: 42; 
                    color: Qt.rgba(1, 1, 1, 0.05); Layout.alignment: Qt.AlignHCenter 
                }
                Text { 
                    text: isEnabled ? (isScanning ? "Searching..." : "No paired devices") : "Bluetooth is off"; 
                    color: Qt.rgba(1, 1, 1, 0.3); font.pixelSize: 12; 
                    font.family: "Inter"; Layout.alignment: Qt.AlignHCenter 
                }
            }

            ListView {
                id: deviceList
                anchors.fill: parent
                model: bluetoothModel
                spacing: 6
                clip: true
                ScrollBar.vertical: ScrollBar { 
                    width: 2; policy: ScrollBar.AsNeeded
                    contentItem: Rectangle { color: Qt.rgba(1, 1, 1, 0.1); radius: 1 }
                }

                delegate: Rectangle {
                    width: deviceList.width
                    height: 52
                    radius: 10
                    color: ma.containsMouse ? Qt.rgba(1, 1, 1, 0.04) : "transparent"
                    border.width: 0
                    border.color: ma.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
                    Behavior on color { ColorAnimation { duration: 150 } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 12

                        Rectangle {
                            width: 34; height: 34; radius: 8
                            color: Qt.rgba(1, 1, 1, 0.03)
                            Text { 
                                anchors.centerIn: parent; text: "󰂯"; 
                                color: dsAccent; font.pixelSize: 18; font.family: "Material Design Icons" 
                            }
                        }

                        ColumnLayout {
                            spacing: -1; Layout.fillWidth: true
                            Text { text: model.name; color: "#ffffff"; font.pixelSize: 13; font.family: "Inter"; font.weight: Font.SemiBold; elide: Text.ElideRight; Layout.fillWidth: true }
                            Text { text: model.mac; color: Qt.rgba(1, 1, 1, 0.4); font.pixelSize: 10; font.family: "Inter" }
                        }

                        Text { text: "󰒓"; font.family: "Material Design Icons"; color: Qt.rgba(1, 1, 1, 0.2); font.pixelSize: 14; visible: ma.containsMouse }
                    }

                    MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor }
                }
            }
        }

        // ── Footer Actions ──
        RowLayout {
            Layout.fillWidth: true; Layout.topMargin: 16; spacing: 8
            
            Rectangle {
                Layout.fillWidth: true
                height: 42; radius: 12; color: scanMa.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(1, 1, 1, 0.04)
                border.width: 0; border.color: dsBorder
                Behavior on color { ColorAnimation { duration: 150 } }

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 8
                    Text { text: isScanning ? "󰓛" : "󰂰"; font.family: "Material Design Icons"; color: dsAccent; font.pixelSize: 16 }
                    Text { text: isScanning ? "Stop Scan" : "Scan for Devices"; color: "#ffffff"; font.pixelSize: 12; font.family: "Inter"; font.weight: Font.Bold }
                }

                MouseArea {
                    id: scanMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: toggleScan()
                }
            }
            
            Rectangle {
                width: 42; height: 42; radius: 12; color: settingsMa.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(1, 1, 1, 0.04)
                border.width: 1; border.color: dsBorder
                Text { anchors.centerIn: parent; text: "󰒓"; font.family: "Material Design Icons"; color: "#ffffff"; font.pixelSize: 18; opacity: 0.7 }
                MouseArea { id: settingsMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: runCommand("blueman-manager") }
            }
        }
    }
}

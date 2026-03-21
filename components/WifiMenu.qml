import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects

Rectangle {
    id: wifiRoot
    width: 280
    height: 420
    color: "transparent"
    radius: (sharedData && sharedData.quickshellBorderRadius !== undefined) ? sharedData.quickshellBorderRadius : 12

    property var sharedData: null
    property var sidePanelRoot: null
    property var popoverWindow: null
    
    // ── Design Tokens ──
    property color dsAccent: (sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff"
    property color dsSurface: (sharedData && sharedData.colorSecondary) ? Qt.rgba(sharedData.colorSecondary.r, sharedData.colorSecondary.g, sharedData.colorSecondary.b, 1.0) : "#141414"
    property color dsBorder: Qt.rgba(1, 1, 1, 0.1)
    property real dsRadius: wifiRoot.radius

    // ── Interaction Logic ──
    property bool isEnabled: false
    property bool isScanning: false
    property string currentSsid: ""
    property bool showPasswordPrompt: false
    property string pendingSsid: ""
    
    ListModel { id: wifiModel }

    function runCommand(cmd, callback) {
        if (!sharedData || !sharedData.runCommand) return
        var tmp = "/tmp/qs_wifi_" + Math.random().toString(36).substring(7)
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
        runCommand("nmcli radio wifi", function(out) {
            isEnabled = out.indexOf("enabled") !== -1;
            fetchNetworks();
        });
    }

    function togglePower() {
        var cmd = isEnabled ? "nmcli radio wifi off" : "nmcli radio wifi on";
        runCommand(cmd, updateStatus);
    }

    function fetchNetworks() {
        if (!isEnabled) { wifiModel.clear(); return; }
        isScanning = true;
        runCommand("nmcli -t -f SSID,SIGNAL,SECURITY,IN-USE dev wifi list | grep -v '^:' | sort -u -t: -k1,1", function(out) {
            isScanning = false;
            wifiModel.clear();
            var lines = out.trim().split('\n');
            for (var i = 0; i < lines.length; i++) {
                var line = lines[i].trim();
                if (line.length > 0) {
                    var parts = line.split(':');
                    if (parts.length >= 3) {
                        var ssid = parts[0];
                        if (!ssid) continue;
                        var signal = parseInt(parts[1]) || 0;
                        var security = parts[2];
                        var inUse = (parts.length > 3 && parts[3] === "*");
                        wifiModel.append({ ssid: ssid, signal: signal, security: security, active: inUse });
                        if (inUse) currentSsid = ssid;
                    }
                }
            }
        });
    }

    function connectToNetwork(ssid, password) {
        var cmd = password ? 
            "nmcli dev wifi connect '" + ssid + "' password '" + password + "'" :
            "nmcli connection up id '" + ssid + "' || nmcli dev wifi connect '" + ssid + "'";
        runCommand(cmd, function() {
            updateStatus();
        });
    }

    Timer { interval: 10000; running: wifiRoot.visible; repeat: true; onTriggered: updateStatus() }
    Component.onCompleted: updateStatus()

    // ── Main Content Container ──
    Rectangle {
        id: mainBg
        anchors.fill: parent
        color: dsSurface
        radius: dsRadius
        border.width: 1
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
                    text: "Wi-Fi"; color: "#ffffff"; 
                    font.pixelSize: 20; font.family: "Outfit"; font.weight: Font.Black; font.letterSpacing: -0.5
                }
                Text { 
                    text: isEnabled ? (isScanning ? "Finding networks..." : (currentSsid || "Ready")) : "Disabled"; 
                    color: isEnabled ? dsAccent : Qt.rgba(1, 1, 1, 0.4); 
                    font.pixelSize: 11; font.family: "Inter"; font.weight: Font.Medium; opacity: 0.8; elide: Text.ElideRight; Layout.maximumWidth: 180
                }
            }

            Item { Layout.fillWidth: true }

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

        // ── Network List ──
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            // Empty State
            ColumnLayout {
                anchors.centerIn: parent
                visible: wifiModel.count === 0
                spacing: 12
                Text { 
                    text: isEnabled ? "󰖩" : "󰖪"; font.family: "Material Design Icons"; 
                    font.pixelSize: 42; 
                    color: Qt.rgba(1, 1, 1, 0.05); Layout.alignment: Qt.AlignHCenter 
                }
                Text { 
                    text: isEnabled ? "No networks found" : "Wi-Fi is off"; 
                    color: Qt.rgba(1, 1, 1, 0.3); font.pixelSize: 12; 
                    font.family: "Inter"; Layout.alignment: Qt.AlignHCenter 
                }
            }

            ListView {
                id: wifiList
                anchors.fill: parent
                model: wifiModel
                spacing: 6
                clip: true
                ScrollBar.vertical: ScrollBar { 
                    width: 2; policy: ScrollBar.AsNeeded
                    contentItem: Rectangle { color: Qt.rgba(1, 1, 1, 0.1); radius: 1 }
                }

                delegate: Rectangle {
                    width: wifiList.width
                    height: 52
                    radius: 10
                    color: ma.containsMouse ? Qt.rgba(1, 1, 1, 0.04) : "transparent"
                    border.width: 1
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
                                anchors.centerIn: parent; 
                                text: model.signal > 75 ? "󰤨" : (model.signal > 50 ? "󰤥" : (model.signal > 25 ? "󰤢" : "󰤟")); 
                                color: model.active ? dsAccent : "#ffffff"; font.pixelSize: 18; font.family: "Material Design Icons" 
                            }
                        }

                        ColumnLayout {
                            spacing: -1; Layout.fillWidth: true
                            Text { text: model.ssid; color: "#ffffff"; font.pixelSize: 13; font.family: "Inter"; font.weight: Font.SemiBold; elide: Text.ElideRight; Layout.fillWidth: true }
                            Text { text: model.active ? "Connected" : (model.security !== "" ? "Secure" : "Open"); color: Qt.rgba(1, 1, 1, 0.4); font.pixelSize: 10; font.family: "Inter" }
                        }

                        Text { text: "󰌾"; font.family: "Material Design Icons"; color: Qt.rgba(1, 1, 1, 0.15); font.pixelSize: 12; visible: model.security !== "" && !model.active }
                        
                        Rectangle {
                            width: 24; height: 24; radius: 6; color: Qt.rgba(1, 0, 0, 0.1); visible: model.active
                            Text { anchors.centerIn: parent; text: "󰅙"; font.family: "Material Design Icons"; color: "#ff4444"; font.pixelSize: 14 }
                            MouseArea { anchors.fill: parent; onClicked: runCommand("nmcli con down id '" + model.ssid + "'", updateStatus) }
                        }
                    }

                    MouseArea { 
                        id: ma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor 
                        onClicked: {
                            if (model.active) return;
                            runCommand("nmcli -g NAME connection show", function(saved) {
                                if (saved && saved.split('\n').indexOf(model.ssid) !== -1 || model.security === "") {
                                    connectToNetwork(model.ssid, null);
                                } else {
                                    wifiRoot.pendingSsid = model.ssid; passInput.text = ""; wifiRoot.showPasswordPrompt = true;
                                }
                            });
                        }
                    }
                }
            }
        }

        // ── Footer Actions ──
        RowLayout {
            Layout.fillWidth: true; Layout.topMargin: 16; spacing: 8
            
            Rectangle {
                Layout.fillWidth: true
                height: 42; radius: 12; color: footerMa.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(1, 1, 1, 0.04)
                border.width: 1; border.color: dsBorder
                Behavior on color { ColorAnimation { duration: 150 } }

                Text { anchors.centerIn: parent; text: "Advanced Settings"; color: "#ffffff"; font.pixelSize: 12; font.family: "Inter"; font.weight: Font.Bold; opacity: 0.8 }

                MouseArea {
                    id: footerMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: runCommand("nm-connection-editor")
                }
            }
        }
    }

    // ── Password Overlay ──
    Rectangle {
        anchors.fill: parent; radius: dsRadius; color: Qt.rgba(0, 0, 0, 0.85); visible: showPasswordPrompt; z: 100
        ColumnLayout {
            anchors.centerIn: parent; width: parent.width - 40; spacing: 16
            Text { text: "Connect to Network"; color: "#ffffff"; font.pixelSize: 16; font.family: "Outfit"; font.weight: Font.Bold; Layout.alignment: Qt.AlignHCenter }
            Text { text: pendingSsid; color: dsAccent; font.pixelSize: 13; font.family: "Inter"; Layout.alignment: Qt.AlignHCenter; elide: Text.ElideRight; Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter }
            
            Rectangle {
                Layout.fillWidth: true; height: 42; radius: 10; color: Qt.rgba(1, 1, 1, 0.05); border.width: 1; border.color: dsBorder
                TextInput {
                    id: passInput; anchors.fill: parent; anchors.margins: 12; color: "#ffffff"; echoMode: TextInput.Password; verticalAlignment: TextInput.AlignVCenter; font.pixelSize: 14; activeFocusOnTab: true
                    onAccepted: { showPasswordPrompt = false; connectToNetwork(pendingSsid, text) }
                }
            }
            
            RowLayout {
                Layout.fillWidth: true; spacing: 10
                Rectangle {
                    Layout.fillWidth: true; height: 36; radius: 8; color: Qt.rgba(1, 1, 1, 0.1)
                    Text { anchors.centerIn: parent; text: "Cancel"; color: "#ffffff"; font.pixelSize: 12; font.family: "Inter" }
                    MouseArea { anchors.fill: parent; onClicked: showPasswordPrompt = false }
                }
                Rectangle {
                    Layout.fillWidth: true; height: 36; radius: 8; color: dsAccent
                    Text { anchors.centerIn: parent; text: "Connect"; color: "#000000"; font.pixelSize: 12; font.family: "Inter"; font.weight: Font.Bold }
                    MouseArea { anchors.fill: parent; onClicked: { showPasswordPrompt = false; connectToNetwork(pendingSsid, passInput.text) } }
                }
            }
        }
    }
}

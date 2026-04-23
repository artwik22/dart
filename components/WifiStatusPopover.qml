import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Rectangle {
    id: wifiStatusPopover
    width: 200
    height: 60
    color: dsSurface
    radius: dsRadius
    border.width: 0
    border.color: dsBorder

    property var sharedData: null
    property var sidePanelRoot: null

    // ── Design Tokens ──
    property color dsAccent: (sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff"
    property color dsSurface: (sharedData && sharedData.colorSecondary) ? Qt.rgba(sharedData.colorSecondary.r, sharedData.colorSecondary.g, sharedData.colorSecondary.b, 1.0) : "#141414"
    property color dsBorder: Qt.rgba(1, 1, 1, 0.1)
    property real dsRadius: (sharedData && sharedData.quickshellBorderRadius !== undefined) ? sharedData.quickshellBorderRadius : 12

    // ── State Properties ──
    property bool isEnabled: false
    property string currentSsid: (sharedData && sharedData.netSSID) || ""
    property bool isScanning: false

    function updateStatus() {
        if (!sharedData || !sharedData.runCommand) return
        var tmp = "/tmp/qs_wifi_status_" + Math.random().toString(36).substring(7)
        sharedData.runCommand(['sh', '-c', 'nmcli radio wifi > ' + tmp + ' 2>/dev/null'], function() {
            var xhr = new XMLHttpRequest()
            xhr.open("GET", "file://" + tmp)
            xhr.onreadystatechange = function() {
                if (xhr.readyState === XMLHttpRequest.DONE) {
                    var out = (xhr.responseText || "").trim()
                    isEnabled = out.indexOf("enabled") !== -1
                    sharedData.runCommand(['rm', '-f', tmp])
                }
            }
            xhr.send()
        })
    }

    Timer { interval: 5000; running: wifiStatusPopover.visible; repeat: true; onTriggered: updateStatus() }
    Component.onCompleted: updateStatus()

    RowLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 10

        Text {
            id: wifiIcon
            text: {
                if (!isEnabled) return "󰖪"
                if (currentSsid) return "󰤨"
                return "󰤯"
            }
            font.pixelSize: 20
            font.family: "Material Design Icons"
            color: isEnabled ? (currentSsid ? dsAccent : "#ffa500") : Qt.rgba(1, 1, 1, 0.3)
            Layout.alignment: Qt.AlignVCenter

            SequentialAnimation on opacity {
                running: isEnabled && !currentSsid
                loops: Animation.Infinite
                NumberAnimation { from: 1.0; to: 0.5; duration: 800; easing.type: Easing.InOutSine }
                NumberAnimation { from: 0.5; to: 1.0; duration: 800; easing.type: Easing.InOutSine }
            }
        }

        ColumnLayout {
            spacing: -2
            Layout.fillWidth: true

            Text {
                text: "Wi-Fi"
                color: "#ffffff"
                font.pixelSize: 12
                font.family: "Inter"
                font.weight: Font.Bold
            }

            Text {
                text: {
                    if (!isEnabled) return "Wyłączony"
                    if (currentSsid) return "✓ " + currentSsid
                    return "Nie połączono"
                }
                color: isEnabled ? (currentSsid ? dsAccent : "#ffa500") : Qt.rgba(1, 1, 1, 0.5)
                font.pixelSize: 10
                font.family: "Inter"
                elide: Text.ElideRight
                Layout.maximumWidth: 140
            }
        }
    }
}
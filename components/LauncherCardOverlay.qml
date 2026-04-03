import QtQuick
import QtQuick.Controls
import Quickshell

Item {
    id: root

    property var sharedData: null
    property string projectPath: ""
    property real startX: 0
    property real startY: 0
    property real startWidth: 110
    property real startHeight: 155
    property real animationProgress: 0
    property bool isOpen: false
    property bool isClosingAnim: false

    property real finalWidth: 560
    property real finalHeight: 420
    property real finalRadius: 16

    property string searchText: ""
    property var apps: []
    property int selectedIndex: 0

    property color bgColor: (sharedData && sharedData.colorBackground) ? sharedData.colorBackground : "#0a0a0a"
    property color primaryColor: (sharedData && sharedData.colorPrimary) ? sharedData.colorPrimary : "#1a1a1a"
    property color secondaryColor: (sharedData && sharedData.colorSecondary) ? sharedData.colorSecondary : "#141414"
    property color textColor: (sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff"
    property color accentColor: (sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff"

    signal fullyClosed

    implicitWidth: parent ? parent.width : 1920
    implicitHeight: parent ? parent.height : 1080

    function easeOutCubic(t) {
        return 1 - Math.pow(1 - t, 3)
    }

    function easeOutBack(t) {
        var c1 = 1.70158
        var c3 = c1 + 1
        return 1 + c3 * Math.pow(t - 1, 3) + c1 * Math.pow(t - 1, 2)
    }

    function open() {
        root.isOpen = true
        root.isClosingAnim = false
        root.animationProgress = 0
        root.searchText = ""
        root.selectedIndex = 0
        loadApps()
        openAnimTimer.start()
    }

    function close() {
        if (root.isClosingAnim) return
        root.isClosingAnim = true
        closeAnimTimer.start()
    }

    function loadApps() {
        if (!(root.sharedData && root.sharedData.runCommand)) return
        var scriptPath = root.projectPath + "/scripts/get-apps.py"
        root.sharedData.runCommand(['python3', scriptPath], readAppsJson)
    }

    function readAppsJson() {
        var xhr = new XMLHttpRequest()
        xhr.open("GET", "file:///tmp/alloy_apps.json?_=" + Date.now())
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                try {
                    var data = JSON.parse(xhr.responseText)
                    if (Array.isArray(data)) {
                        root.apps = data
                    }
                } catch (e) {
                    console.error("Error parsing apps JSON: " + e)
                }
            }
        }
        xhr.send()
    }

    function getFilteredApps() {
        var search = root.searchText.trim().toLowerCase()
        if (search.length === 0) return root.apps.slice(0, 8)

        var matches = []
        for (var i = 0; i < root.apps.length; i++) {
            var app = root.apps[i]
            if (!app || !app.name) continue

            var name = app.name.toLowerCase()
            var comment = (app.comment || "").toLowerCase()
            var score = 0

            if (name === search) {
                score = 100
            } else if (name.startsWith(search)) {
                score = 80
            } else if (name.indexOf(search) >= 0) {
                score = 60
            } else if (comment.indexOf(search) >= 0) {
                score = 40
            }

            if (score > 0) {
                matches.push({ app: app, score: score })
            }
        }

        matches.sort(function(a, b) { return b.score - a.score })

        var result = []
        var limit = Math.min(matches.length, 8)
        for (var k = 0; k < limit; k++) {
            result.push(matches[k].app)
        }
        return result
    }

    function launchApp(app) {
        if (app.exec) {
            var exec = app.exec
            exec = exec.replace(/%%/g, "___PERCENT_PLACEHOLDER___")
            exec = exec.replace(/%[a-zA-Z]/g, "")
            exec = exec.replace(/___PERCENT_PLACEHOLDER___/g, "%")
            exec = exec.replace(/\s+/g, " ").trim()

            if (root.sharedData && root.sharedData.runCommand) {
                root.sharedData.runCommand(['sh', '-c', exec.replace(/'/g, "'\"'\"'") + ' &'])
            }
        }
        close()
    }

    function handleWheel(deltaY) {
        var filtered = root.getFilteredApps()
        if (deltaY < 0) {
            if (root.selectedIndex < filtered.length - 1) {
                root.selectedIndex++
            }
        } else {
            if (root.selectedIndex > 0) {
                root.selectedIndex--
            }
        }
    }

    Timer {
        id: openAnimTimer
        interval: 16
        repeat: true
        onTriggered: {
            root.animationProgress += 0.035
            if (root.animationProgress >= 1.0) {
                root.animationProgress = 1.0
                openAnimTimer.stop()
                searchInput.forceActiveFocus()
            }
        }
    }

    Timer {
        id: closeAnimTimer
        interval: 16
        repeat: true
        onTriggered: {
            root.animationProgress -= 0.045
            if (root.animationProgress <= 0.0) {
                root.animationProgress = 0.0
                closeAnimTimer.stop()
                root.isOpen = false
                root.isClosingAnim = false
                root.visible = false
                root.fullyClosed()
            }
        }
    }

    visible: root.isOpen

    Rectangle {
        id: container
        width: {
            var eased = easeOutBack(Math.min(1, root.animationProgress))
            return root.startWidth + (root.finalWidth - root.startWidth) * eased
        }
        height: {
            var eased = easeOutBack(Math.min(1, root.animationProgress))
            return root.startHeight + (root.finalHeight - root.startHeight) * eased
        }
        x: {
            var eased = easeOutCubic(Math.min(1, root.animationProgress))
            var startX = root.startX
            var centerX = parent.width / 2 - root.finalWidth / 2
            return startX + (centerX - startX) * eased
        }
        y: {
            var eased = easeOutCubic(Math.min(1, root.animationProgress))
            var startY = root.startY
            var centerY = parent.height / 2 - root.finalHeight / 2
            return startY + (centerY - startY) * eased
        }
        radius: {
            var eased = easeOutCubic(Math.min(1, root.animationProgress))
            var baseRadius = (sharedData && sharedData.quickshellBorderRadius !== undefined) ? sharedData.quickshellBorderRadius : 12
            return 8 + (baseRadius - 8) * eased
        }
        z: 1000
        color: root.bgColor

        opacity: {
            var eased = easeOutCubic(Math.min(1, root.animationProgress))
            return eased
        }

        Item {
            id: searchArea
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 52
            opacity: root.animationProgress > 0.25 ? Math.min(1, (root.animationProgress - 0.25) / 0.5) : 0

            Text {
                id: searchIcon
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: 18
                text: "󰍉"
                font.pixelSize: 18
                font.family: "JetBrainsMono Nerd Font"
                color: root.accentColor
                opacity: 0.8
            }

            TextInput {
                id: searchInput
                anchors.left: searchIcon.right
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: 12
                anchors.rightMargin: 16
                text: root.searchText
                color: root.textColor
                font.pixelSize: 15
                font.family: "Inter"
                selectionColor: root.accentColor
                selectedTextColor: root.bgColor

                onTextChanged: {
                    root.searchText = text
                    root.selectedIndex = 0
                }

                Keys.onPressed: function(event) {
                    if (event.key === Qt.Key_Escape) {
                        root.close()
                        event.accepted = true
                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        var filtered = root.getFilteredApps()
                        if (filtered.length > 0 && root.selectedIndex < filtered.length) {
                            root.launchApp(filtered[root.selectedIndex])
                        }
                        event.accepted = true
                    } else if (event.key === Qt.Key_Down) {
                        var filtered = root.getFilteredApps()
                        if (root.selectedIndex < filtered.length - 1) {
                            root.selectedIndex++
                        }
                        event.accepted = true
                    } else if (event.key === Qt.Key_Up) {
                        if (root.selectedIndex > 0) {
                            root.selectedIndex--
                        }
                        event.accepted = true
                    }
                }
            }

            Text {
                anchors.left: searchIcon.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: 12
                text: "Search applications..."
                color: root.textColor
                font.pixelSize: 15
                font.family: "Inter"
                opacity: 0.3
                visible: searchInput.text.length === 0 && !searchInput.activeFocus
            }
        }

        ListView {
            id: resultsList
            anchors.top: searchArea.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.topMargin: 6
            anchors.bottomMargin: 8
            clip: true
            opacity: root.animationProgress > 0.45 ? Math.min(1, (root.animationProgress - 0.45) / 0.4) : 0

            model: root.getFilteredApps()
            delegate: Item {
                width: resultsList.width
                height: 54

                property bool isSel: index === root.selectedIndex

                Rectangle {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    anchors.topMargin: 4
                    anchors.bottomMargin: 4
                    radius: 8
                    color: root.accentColor
                    opacity: parent.isSel ? 0.12 : 0
                    visible: opacity > 0.01

                    Behavior on opacity {
                        NumberAnimation { duration: 120 }
                    }
                }

                Image {
                    id: appIconImage
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: 18
                    width: 24
                    height: 24
                    source: modelData.icon ? ("image://icon/" + modelData.icon) : ""
                    fillMode: Image.PreserveAspectFit
                    visible: status === Image.Ready && modelData.icon !== ""
                }

                Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: 18
                    text: "󰣆"
                    font.pixelSize: 20
                    font.family: "JetBrainsMono Nerd Font"
                    color: parent.isSel ? root.accentColor : root.textColor
                    opacity: parent.isSel ? 1 : 0.6
                    visible: !appIconImage.visible
                }

                Text {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.topMargin: 12
                    anchors.leftMargin: 50
                    anchors.right: parent.right
                    anchors.rightMargin: 16
                    text: modelData.name || ""
                    font.pixelSize: 14
                    font.bold: true
                    font.family: "Inter"
                    color: parent.isSel ? root.accentColor : root.textColor
                    elide: Text.ElideRight

                    Behavior on color {
                        ColorAnimation { duration: 120 }
                    }
                }

                Text {
                    anchors.left: parent.left
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 12
                    anchors.leftMargin: 50
                    anchors.right: parent.right
                    anchors.rightMargin: 16
                    text: modelData.comment || ""
                    font.pixelSize: 11
                    font.family: "Inter"
                    color: root.textColor
                    opacity: parent.isSel ? 0.55 : 0.35
                    elide: Text.ElideRight

                    Behavior on opacity {
                        NumberAnimation { duration: 120 }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: root.selectedIndex = index
                    onClicked: root.launchApp(modelData)
                }
            }

            ScrollIndicator.vertical: ScrollIndicator {
                active: false
            }

            Rectangle {
                anchors.fill: parent
                color: "transparent"
                visible: resultsList.count === 0 && root.searchText.length > 0

                Column {
                    anchors.centerIn: parent
                    spacing: 8

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "󰍉"
                        font.pixelSize: 28
                        font.family: "JetBrainsMono Nerd Font"
                        color: root.textColor
                        opacity: 0.2
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "No applications found"
                        font.pixelSize: 13
                        font.family: "Inter"
                        color: root.textColor
                        opacity: 0.35
                    }
                }
            }
        }
    }
}

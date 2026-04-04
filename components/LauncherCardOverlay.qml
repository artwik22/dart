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

    property real searchboxWidth: 420
    property real searchboxHeight: 52
    property real searchboxRadius: 12
    property real maxResultsHeight: 360

    property real morphTargetWidth: searchboxWidth
    property real morphTargetHeight: searchboxHeight

    property real _resultsHeight: root.hasSearchResults ? Math.min(root.getFilteredApps().length * 54, root.maxResultsHeight) : 0
    property real _targetExpandedHeight: root.searchboxHeight + root._resultsHeight + (root.hasSearchResults ? 14 : 0)

    property real _morphWidth: root.startWidth + (root.morphTargetWidth - root.startWidth) * root.animationProgress
    property real _morphHeight: root.startHeight + (root.morphTargetHeight - root.startHeight) * root.animationProgress

    property real _expandedHeight: root.searchboxHeight

    NumberAnimation {
        id: expandAnim
        target: root
        property: "_expandedHeight"
        duration: 200
        easing.type: Easing.OutCubic
    }

    property real containerWidth: root._morphWidth
    property real containerHeight: root.animationProgress >= 1 ? root._expandedHeight : root._morphHeight

    property string searchText: ""
    property var apps: []
    property int selectedIndex: 0

    property bool hasSearchResults: root.searchText.trim().length > 0 && root.getFilteredApps().length > 0

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
        closeAnim.stop()
        openAnim.start()
    }

    function close() {
        if (root.isClosingAnim) return
        root.isClosingAnim = true
        openAnim.stop()
        closeAnim.from = root.animationProgress
        closeAnim.start()
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
        if (search.length === 0) return []

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
        var limit = Math.min(matches.length, 6)
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

    NumberAnimation {
        id: openAnim
        target: root
        property: "animationProgress"
        from: 0
        to: 1
        duration: 400
        easing.type: Easing.Linear
        onFinished: {
            searchInput.forceActiveFocus()
        }
    }

    NumberAnimation {
        id: closeAnim
        target: root
        property: "animationProgress"
        from: 1
        to: 0
        duration: 300
        easing.type: Easing.Linear
        onFinished: {
            root.isOpen = false
            root.isClosingAnim = false
            root.visible = false
            root.fullyClosed()
        }
    }

    visible: root.isOpen

    Rectangle {
        id: container
        width: root.containerWidth
        height: root.containerHeight
        x: {
            var eased = easeOutCubic(Math.min(1, root.animationProgress))
            var startX = root.startX
            var centerX = parent.width / 2 - root.morphTargetWidth / 2
            return startX + (centerX - startX) * eased
        }
        y: {
            var eased = easeOutCubic(Math.min(1, root.animationProgress))
            var startY = root.startY
            var centerY = parent.height / 2 - root.morphTargetHeight / 2
            return startY + (centerY - startY) * eased
        }
        radius: {
            var eased = easeOutCubic(Math.min(1, root.animationProgress))
            return 8 + (root.searchboxRadius - 8) * eased
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
            height: root.searchboxHeight

            Text {
                id: searchIcon
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: 16
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
                anchors.leftMargin: 10
                anchors.rightMargin: 14
                text: root.searchText
                color: root.textColor
                font.pixelSize: 15
                font.family: "Inter"
                selectionColor: root.accentColor
                selectedTextColor: root.bgColor

                onTextChanged: {
                    root.searchText = text
                    root.selectedIndex = 0
                    if (root.animationProgress >= 1) {
                        expandAnim.from = root._expandedHeight
                        expandAnim.to = root._targetExpandedHeight
                        expandAnim.restart()
                    }
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
                anchors.leftMargin: 10
                text: "Search applications..."
                color: root.textColor
                font.pixelSize: 15
                font.family: "Inter"
                opacity: 0.3
                visible: searchInput.text.length === 0 && !searchInput.activeFocus
            }
        }

        Rectangle {
            id: resultsContainer
            anchors.top: searchArea.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: root.hasSearchResults ? root._resultsHeight : 0
            color: "transparent"

            ListView {
                id: resultsList
                anchors.fill: parent
                clip: true
                opacity: root.hasSearchResults ? 1 : 0

                Behavior on opacity {
                    NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                }

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
            }

            Column {
                anchors.centerIn: parent
                spacing: 8
                visible: resultsList.count === 0 && root.searchText.length > 0

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

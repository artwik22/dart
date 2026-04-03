import QtQuick

Item {
    id: root

    property var sharedData: null
    property int cardCount: 5
    property var cardIcons: ["♠", "♥", "♦", "♣", "★"]
    property var cardValues: ["A", "K", "Q", "J", "10"]
    property var cardActions: ["kitty", null, null, null, null]
    property var cardBadges: ["⌘", "", "", "", ""]
    property real cardWidth: 110
    property real cardHeight: 155
    property real fanAngle: 50
    property real fanRadius: 350
    property real hoverOffset: 25
    property real spreadDistance: 18
    property int hoveredIndex: -1
    property bool isClosing: false
    property real animationProgress: 0
    property int launcherCardIndex: -1
    signal launcherCardClicked(real x, real y, real width, real height)

    property color cardSurface: (sharedData && sharedData.colorPrimary) ? Qt.lighter(sharedData.colorPrimary, 1.15) : "#2a2a2a"
    property color cardSurfaceDark: (sharedData && sharedData.colorSecondary) ? Qt.lighter(sharedData.colorSecondary, 1.1) : "#222222"
    property color cardText: (sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff"
    property color cardAccent: (sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff"
    property color cardBorder: (sharedData && sharedData.colorPrimary) ? Qt.lighter(sharedData.colorPrimary, 1.3) : "#3a3a3a"
    property color cardBorderHover: (sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff"

    implicitWidth: 500
    implicitHeight: 300

    Component.onCompleted: {
        openTimer.start()
    }

    Timer {
        id: openTimer
        interval: 16
        repeat: true
        onTriggered: {
            if (!root.isClosing) {
                animationProgress += 0.02
                if (animationProgress >= 1.0) {
                    animationProgress = 1.0
                    openTimer.stop()
                }
            }
        }
    }

    Timer {
        id: closeTimer
        interval: 16
        repeat: true
        onTriggered: {
            if (root.isClosing) {
                animationProgress -= 0.025
                if (animationProgress <= 0.0) {
                    animationProgress = 0.0
                    closeTimer.stop()
                    root.visible = false
                }
            }
        }
    }

    function startClose() {
        root.isClosing = true
        closeTimer.start()
    }

    function findCardAtPoint(px, py) {
        for (var i = root.cardCount - 1; i >= 0; i--) {
            var card = repeater.itemAt(i)
            if (!card) continue
            var cx = card.x + card.width / 2
            var cy = card.y + card.height / 2
            var hw = card.width / 2
            var hh = card.height / 2
            if (px >= cx - hw && px <= cx + hw && py >= cy - hh && py <= cy + hh) {
                return i
            }
        }
        return -1
    }

    Repeater {
        id: repeater
        width: root.implicitWidth
        height: root.implicitHeight
        model: root.cardCount

        Item {
            property int cardIndex: index
            property real openDelay: cardIndex * 0.08
            property real closeDelay: (root.cardCount - 1 - cardIndex) * 0.06
            property real delay: root.isClosing ? closeDelay : openDelay
            property real cardProgress: Math.max(0, Math.min(1, (root.animationProgress - delay) / (1.0 - delay)))
            property real easedProgress: cardProgress < 1 ? easeOutBack(cardProgress) : 1

            property real angleStep: fanAngle / (root.cardCount - 1)
            property real cardAngle: (cardIndex - (root.cardCount - 1) / 2.0) * angleStep * easedProgress

            property real pivotX: root.implicitWidth / 2
            property real pivotY: root.implicitHeight + 80

            property real restX: pivotX - root.cardWidth / 2
            property real restY: pivotY - root.cardHeight - 20

            property real fanX: pivotX + root.fanRadius * Math.sin(cardAngle * Math.PI / 180) - root.cardWidth / 2
            property real fanY: pivotY - root.fanRadius * Math.cos(cardAngle * Math.PI / 180) - root.cardHeight / 2

            property real animX: restX + (fanX - restX) * easedProgress
            property real animY: restY + (fanY - restY) * easedProgress - (1 - easedProgress) * 150

            property real hoverShift: cardIndex === root.hoveredIndex ? -hoverOffset : 0

            function easeOutBack(t) {
                var c1 = 1.70158
                var c3 = c1 + 1
                return 1 + c3 * Math.pow(t - 1, 3) + c1 * Math.pow(t - 1, 2)
            }

            function calcHoverOffset() {
                if (root.hoveredIndex === -1) return 0
                var diff = Math.abs(cardIndex - root.hoveredIndex)
                if (diff === 1) {
                    return cardIndex < root.hoveredIndex ? -spreadDistance : spreadDistance
                }
                return 0
            }

            x: animX + calcHoverOffset()
            y: animY + hoverShift
            width: root.cardWidth * easedProgress
            height: root.cardHeight * easedProgress
            rotation: cardAngle
            opacity: easedProgress
            transformOrigin: Item.BottomCenter

            z: cardIndex === root.hoveredIndex ? 100 : cardIndex

            Behavior on x {
                NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
            }
            Behavior on y {
                NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
            }

            Rectangle {
                width: parent.width
                height: parent.height
                radius: 8

                gradient: Gradient {
                    GradientStop { position: 0; color: root.cardSurface }
                    GradientStop { position: 1; color: root.cardSurfaceDark }
                }
                border.width: 0

                scale: cardIndex === root.hoveredIndex ? 1.08 : 1.0
                transformOrigin: Item.Center

                Behavior on scale {
                    NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                }

                Text {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.margins: 8
                    text: root.cardValues[index % root.cardValues.length]
                    font.pixelSize: 14
                    font.bold: true
                    color: root.cardAccent
                }

                Text {
                    visible: root.cardBadges[index] !== ""
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.margins: 6
                    text: root.cardBadges[index % root.cardBadges.length]
                    font.pixelSize: 12
                    font.bold: true
                    color: root.cardAccent
                    opacity: 0.7
                }

                Text {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.topMargin: 22
                    anchors.leftMargin: 8
                    text: root.cardIcons[index % root.cardIcons.length]
                    font.pixelSize: 12
                    color: root.cardAccent
                }

                Text {
                    anchors.centerIn: parent
                    text: (root.launcherCardIndex >= 0 && index === root.launcherCardIndex) ? "󰍉" : root.cardIcons[index % root.cardIcons.length]
                    font.pixelSize: 38
                    font.bold: true
                    color: root.cardText
                    opacity: 0.85
                }

                Text {
                    anchors.bottom: parent.bottom
                    anchors.right: parent.right
                    anchors.margins: 8
                    text: root.cardValues[index % root.cardValues.length]
                    font.pixelSize: 14
                    font.bold: true
                    color: root.cardAccent
                    rotation: 180
                }

                Text {
                    anchors.bottom: parent.bottom
                    anchors.right: parent.right
                    anchors.bottomMargin: 22
                    anchors.rightMargin: 8
                    text: root.cardIcons[index % root.cardIcons.length]
                    font.pixelSize: 12
                    color: root.cardAccent
                    rotation: 180
                }

                Rectangle {
                    visible: root.cardActions[index] !== null && root.cardActions[index] !== ""
                    anchors.bottom: parent.bottom
                    anchors.right: parent.right
                    anchors.margins: 6
                    width: 22
                    height: 22
                    radius: 4
                    color: root.cardAccent
                    opacity: 0.85

                    Text {
                        anchors.centerIn: parent
                        text: "▶"
                        font.pixelSize: 10
                        font.bold: true
                        color: root.cardSurface
                    }
                }

                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width * 0.6
                    height: parent.height * 0.5
                    radius: 40
                    color: "transparent"
                    border.width: 1
                    border.color: root.cardAccent
                    opacity: cardIndex === root.hoveredIndex ? 0.2 : 0.08

                    Behavior on opacity {
                        NumberAnimation { duration: 200 }
                    }
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true

        onPositionChanged: function(mouse) {
            root.hoveredIndex = root.findCardAtPoint(mouse.x, mouse.y)
        }

        onExited: root.hoveredIndex = -1

        onClicked: function(mouse) {
            var idx = root.findCardAtPoint(mouse.x, mouse.y)
            if (idx >= 0) {
                if (root.launcherCardIndex >= 0 && idx === root.launcherCardIndex) {
                    var card = repeater.itemAt(idx)
                    if (card) {
                        var globalPos = card.mapToItem(root.parent, 0, 0)
                        root.launcherCardClicked(globalPos.x, globalPos.y, card.width, card.height)
                    }
                    root.startClose()
                } else if (idx < root.cardActions.length && root.cardActions[idx]) {
                    var cmd = root.cardActions[idx]
                    if (root.sharedData && root.sharedData.runCommand) {
                        root.sharedData.runCommand(['sh', '-c', cmd])
                    }
                    root.startClose()
                }
            }
        }
    }
}

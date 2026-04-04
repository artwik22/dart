import QtQuick

FocusScope {
    id: root

    property var sharedData: null
    property int cardCount: 5
    property var cardIcons: ["♠", "♥", "♦", "󰐥", "★"]
    property var cardValues: ["A", "K", "Q", "J", "10"]
    property var cardActions: ["kitty", null, null, null, null]
    property var cardBadges: ["⌘", "", "", "⚡", ""]
    property var cardTypes: ["action", "action", "action", "system", "launcher"]
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
    property int keyboardFocusIndex: -1

    property bool systemCardActive: false
    property real systemCardProgress: 0
    property int systemCardIndex: 3
    property int systemSelectedAction: -1
    property bool showSystemConfirm: false
    property real confirmProgress: 0
    property int pendingActionIndex: -1

    property var systemActions: [
        { label: "Lock", icon: "󰌾", cmd: "swaylock || hyprlock || loginctl lock-session" },
        { label: "Logout", icon: "󰍂", cmd: "loginctl terminate-user $USER" },
        { label: "Reboot", icon: "󰜉", cmd: "systemctl reboot" },
        { label: "Shutdown", icon: "󰐥", cmd: "systemctl poweroff" },
        { label: "Sleep", icon: "󰤄", cmd: "systemctl suspend" }
    ]

    signal launcherCardClicked(real x, real y, real width, real height)

    visible: true

    Component.onCompleted: {
        visible = true
        isClosing = false
        animationProgress = 0
        keyboardFocusIndex = -1
        hoveredIndex = -1
        systemCardActive = false
        systemCardProgress = 0
        systemSelectedAction = -1
        showSystemConfirm = false
        confirmProgress = 0
        openTimer.start()
        forceActiveFocus()
    }

    property color cardSurface: (sharedData && sharedData.colorPrimary) ? Qt.lighter(sharedData.colorPrimary, 1.15) : "#2a2a2a"
    property color cardSurfaceDark: (sharedData && sharedData.colorSecondary) ? Qt.lighter(sharedData.colorSecondary, 1.1) : "#222222"
    property color cardText: (sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff"
    property color cardAccent: (sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff"

    implicitWidth: 500
    implicitHeight: 300
    focus: true

    Keys.onPressed: function(event) {
        if (root.systemCardActive) {
            if (root.showSystemConfirm) {
                if (event.key === Qt.Key_Escape || event.key === Qt.Key_N) {
                    root.cancelConfirm()
                    event.accepted = true
                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Y) {
                    root.executeSystemAction(root.pendingActionIndex)
                    event.accepted = true
                }
                return
            }
            if (event.key === Qt.Key_Up) {
                root.systemSelectedAction = Math.max(0, root.systemSelectedAction - 1)
                event.accepted = true
            } else if (event.key === Qt.Key_Down) {
                root.systemSelectedAction = Math.min(root.systemActions.length - 1, root.systemSelectedAction + 1)
                event.accepted = true
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                if (root.systemSelectedAction >= 0) {
                    root.pendingActionIndex = root.systemSelectedAction
                    root.showSystemConfirm = true
                    root.confirmProgress = 0
                    confirmAnimTimer.start()
                }
                event.accepted = true
            } else if (event.key === Qt.Key_Escape) {
                root.closeSystemCard()
                event.accepted = true
            }
            return
        }
        if (event.key === Qt.Key_Left || event.key === Qt.Key_Up) {
            root.keyboardFocusIndex = Math.max(0, root.keyboardFocusIndex - 1)
            root.hoveredIndex = root.keyboardFocusIndex
            event.accepted = true
        } else if (event.key === Qt.Key_Right || event.key === Qt.Key_Down) {
            root.keyboardFocusIndex = Math.min(root.cardCount - 1, root.keyboardFocusIndex + 1)
            root.hoveredIndex = root.keyboardFocusIndex
            event.accepted = true
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
            if (root.keyboardFocusIndex >= 0) {
                root.activateCard(root.keyboardFocusIndex)
            }
            event.accepted = true
        } else if (event.key === Qt.Key_Escape) {
            root.startClose()
            event.accepted = true
        }
    }

    function activateCard(idx) {
        if (idx < 0 || idx >= cardCount) return
        if (launcherCardIndex >= 0 && idx === launcherCardIndex) {
            var card = repeater.itemAt(idx)
            if (card) {
                var globalPos = card.mapToItem(root.parent, 0, 0)
                launcherCardClicked(globalPos.x, globalPos.y, card.width, card.height)
            }
            startClose()
        } else if (idx < cardTypes.length && cardTypes[idx] === "system") {
            root.systemCardIndex = idx
            root.systemCardActive = true
            root.systemCardProgress = 0
            root.systemSelectedAction = -1
            root.showSystemConfirm = false
            systemCardOpenAnim.start()
        } else if (idx < cardActions.length && cardActions[idx]) {
            var cmd = cardActions[idx]
            if (sharedData && sharedData.runCommand) {
                sharedData.runCommand(['sh', '-c', cmd])
            }
            startClose()
        }
    }

    function closeSystemCard() {
        root.showSystemConfirm = false
        root.confirmProgress = 0
        confirmAnimTimer.stop()
        systemCardCloseAnim.start()
    }

    function cancelConfirm() {
        confirmAnimTimer.stop()
        root.showSystemConfirm = false
        root.confirmProgress = 0
    }

    function executeSystemAction(idx) {
        if (idx < 0 || idx >= root.systemActions.length) return
        var action = root.systemActions[idx]
        if (sharedData && sharedData.runCommand) {
            sharedData.runCommand(['sh', '-c', action.cmd])
        }
        root.closeSystemCard()
    }

    function easeOutBack(t) {
        var c1 = 1.70158
        var c3 = c1 + 1
        return 1 + c3 * Math.pow(t - 1, 3) + c1 * Math.pow(t - 1, 2)
    }

    function easeOutCubic(t) {
        return 1 - Math.pow(1 - t, 3)
    }

    function easeInOutCubic(t) {
        return t < 0.5 ? 4 * t * t * t : 1 - Math.pow(-2 * t + 2, 3) / 2
    }

    Timer {
        id: openTimer
        interval: 16
        repeat: true
        onTriggered: {
            if (!root.isClosing && !root.systemCardActive) {
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

    NumberAnimation {
        id: systemCardOpenAnim
        target: root
        property: "systemCardProgress"
        from: 0
        to: 1
        duration: 500
        easing.type: Easing.OutBack
        easing.overshoot: 0.8
        onFinished: {
            root.systemSelectedAction = 0
        }
    }

    NumberAnimation {
        id: systemCardCloseAnim
        target: root
        property: "systemCardProgress"
        from: 1
        to: 0
        duration: 400
        easing.type: Easing.InCubic
        onFinished: {
            root.systemCardActive = false
            root.showSystemConfirm = false
            root.confirmProgress = 0
        }
    }

    Timer {
        id: confirmAnimTimer
        interval: 16
        repeat: true
        onTriggered: {
            root.confirmProgress += 0.008
            if (root.confirmProgress >= 1.0) {
                confirmAnimTimer.stop()
                root.executeSystemAction(root.pendingActionIndex)
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
            id: cardItem
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

            property real hoverShift: (cardIndex === root.hoveredIndex || cardIndex === root.keyboardFocusIndex) ? -hoverOffset : 0

            property real centerX: root.implicitWidth / 2 - 100
            property real centerY: root.implicitHeight / 2 - 120

            function calcHoverOffset() {
                if (root.systemCardActive) return 0
                var focusIdx = root.hoveredIndex >= 0 ? root.hoveredIndex : root.keyboardFocusIndex
                if (focusIdx === -1) return 0
                var diff = Math.abs(cardIndex - focusIdx)
                if (diff === 1) {
                    return cardIndex < focusIdx ? -spreadDistance : spreadDistance
                }
                return 0
            }

            property real isSystemCard: (cardIndex === root.systemCardIndex && root.systemCardActive) ? 1 : 0

            // Single progress drives everything simultaneously
            property real p: root.systemCardProgress

            // Flip: 0 -> 180 degrees (only for system card)
            property real flipAngle: isSystemCard ? p * 180 : 0
            property real flipXScale: isSystemCard ? Math.abs(Math.cos(flipAngle * Math.PI / 180)) : 1
            property bool showBackFace: isSystemCard && flipAngle >= 90

            // Position: fan -> center (easeOutBack)
            property real posT: easeOutBack(p)
            property real sysX: animX + (root.centerX - animX) * posT * isSystemCard
            property real sysY: animY + (root.centerY - animY) * posT * isSystemCard

            // Rotation: fan angle -> 0
            property real sysRotation: cardAngle * (1 - posT * isSystemCard)

            // Scale: 1 -> 1.7
            property real sysScale: 1 + 0.7 * posT * isSystemCard

            // Size: normal -> expanded
            property real sizeT: easeOutCubic(p)
            property real sysWidth: root.cardWidth + 90 * sizeT * isSystemCard
            property real sysHeight: root.cardHeight + 185 * sizeT * isSystemCard

            property real otherShiftX: root.systemCardActive && !isSystemCard ? (cardIndex < root.systemCardIndex ? -50 : 50) * p : 0

            x: (isSystemCard ? sysX : animX) + calcHoverOffset() + otherShiftX
            y: isSystemCard ? sysY : animY + hoverShift
            width: isSystemCard ? sysWidth : root.cardWidth * easedProgress
            height: isSystemCard ? sysHeight : root.cardHeight * easedProgress
            rotation: isSystemCard ? sysRotation : cardAngle
            opacity: easedProgress
            transformOrigin: Item.Center
            scale: isSystemCard ? sysScale : ((cardIndex === root.hoveredIndex || cardIndex === root.keyboardFocusIndex) ? 1.08 : 1.0)

            z: isSystemCard ? 200 : ((cardIndex === root.hoveredIndex || cardIndex === root.keyboardFocusIndex) ? 100 : cardIndex)

            // FRONT FACE decorations - fade out as flip progresses
            property real frontOpacity: flipAngle < 90 ? 1 : 0
            // BACK FACE content - fade in as flip completes
            property real backOpacity: flipAngle > 90 ? Math.min(1, (flipAngle - 90) / 90) : 0

            Rectangle {
                width: parent.width
                height: parent.height
                radius: 8 + 6 * sizeT * isSystemCard
                clip: isSystemCard && p > 0.5

                transform: Scale {
                    xScale: cardItem.flipXScale
                    origin.x: cardItem.width / 2
                    origin.y: cardItem.height / 2
                }

                property real glowOpacity: isSystemCard && cardItem.showBackFace ? 0.2 : 0

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: -3
                    radius: parent.radius + 3
                    color: "transparent"
                    border.color: root.cardAccent
                    border.width: 2
                    opacity: parent.glowOpacity
                    visible: opacity > 0.01
                }

                color: cardItem.showBackFace ? Qt.darker(root.cardSurface, 1.08) : root.cardSurface

                // FRONT FACE
                Item {
                    visible: cardItem.frontOpacity > 0
                    anchors.fill: parent
                    opacity: cardItem.frontOpacity

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
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: parent.height / 2 - height / 2 - 10
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
                }

                // BACK FACE
                Item {
                    visible: cardItem.backOpacity > 0
                    anchors.fill: parent
                    opacity: cardItem.backOpacity

                    Text {
                        id: backCenterIcon
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: 22
                        text: "󰐥"
                        font.pixelSize: 32
                        font.bold: true
                        color: root.cardAccent
                        opacity: 0.9
                    }

                    Text {
                        anchors.top: backCenterIcon.bottom
                        anchors.topMargin: 4
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Power"
                        font.pixelSize: 11
                        font.letterSpacing: 2
                        font.bold: true
                        color: root.cardAccent
                        opacity: 0.8
                    }

                    Column {
                        anchors.top: parent.top
                        anchors.topMargin: 90
                        anchors.left: parent.left
                        anchors.leftMargin: 10
                        anchors.right: parent.right
                        anchors.rightMargin: 10
                        spacing: 6

                        Repeater {
                            model: root.systemActions

                            Rectangle {
                                property int actionIdx: index
                                property real actionDelay: index * 0.06
                                property real actionStart: 0.55
                                property real actionEnd: 1.0
                                property real actionT: p > actionStart ? Math.max(0, Math.min(1, (p - actionStart - actionDelay) / (actionEnd - actionStart - actionDelay))) : 0
                                property real actionEased: actionT > 0 && actionT < 1 ? easeOutBack(actionT) : (actionT >= 1 ? 1 : 0)

                                width: parent.width
                                height: 42
                                radius: 10
                                color: actionIdx === root.systemSelectedAction ? Qt.lighter(root.cardAccent, 1.15) : Qt.rgba(1, 1, 1, 0.03)
                                opacity: actionT
                                transform: Translate {
                                    y: (1 - actionEased) * 15
                                }

                                Behavior on color {
                                    ColorAnimation { duration: 150 }
                                }

                                Row {
                                    anchors.fill: parent
                                    anchors.leftMargin: 14
                                    anchors.rightMargin: 14
                                    spacing: 12

                                    Rectangle {
                                        width: 28
                                        height: 28
                                        radius: 7
                                        anchors.verticalCenter: parent.verticalCenter
                                        color: actionIdx === root.systemSelectedAction ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(1, 1, 1, 0.05)

                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData.icon
                                            font.pixelSize: 14
                                            color: actionIdx === root.systemSelectedAction ? root.cardAccent : root.cardText
                                        }
                                    }

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: modelData.label
                                        font.pixelSize: 13
                                        font.bold: actionIdx === root.systemSelectedAction
                                        color: actionIdx === root.systemSelectedAction ? root.cardAccent : root.cardText
                                        opacity: 0.85
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onEntered: { root.systemSelectedAction = actionIdx }
                                    onClicked: {
                                        root.systemSelectedAction = actionIdx
                                        root.pendingActionIndex = actionIdx
                                        root.showSystemConfirm = true
                                        root.confirmProgress = 0
                                        confirmAnimTimer.restart()
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        visible: root.showSystemConfirm
                        anchors.fill: parent
                        radius: 14
                        color: Qt.rgba(0, 0, 0, 0.5)

                        Rectangle {
                            anchors.centerIn: parent
                            width: parent.width - 24
                            height: 130
                            radius: 12
                            color: root.cardSurface

                            Column {
                                anchors.centerIn: parent
                                spacing: 10
                                width: parent.width - 24

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: (root.pendingActionIndex >= 0 ? root.systemActions[root.pendingActionIndex].label : "")
                                    font.pixelSize: 16
                                    font.bold: true
                                    color: root.cardAccent
                                }

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: "Are you sure?"
                                    font.pixelSize: 11
                                    color: root.cardText
                                    opacity: 0.6
                                }

                                Rectangle {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: 160
                                    height: 4
                                    radius: 2
                                    color: Qt.rgba(1, 1, 1, 0.1)

                                    Rectangle {
                                        anchors.left: parent.left
                                        anchors.top: parent.top
                                        anchors.bottom: parent.bottom
                                        width: parent.width * root.confirmProgress
                                        radius: 2
                                        color: root.cardAccent
                                    }
                                }

                                Row {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    spacing: 10

                                    Rectangle {
                                        width: 80
                                        height: 32
                                        radius: 8
                                        color: Qt.rgba(1, 1, 1, 0.08)

                                        Text {
                                            anchors.centerIn: parent
                                            text: "Cancel"
                                            font.pixelSize: 12
                                            font.bold: true
                                            color: root.cardText
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            onClicked: root.cancelConfirm()
                                        }
                                    }

                                    Rectangle {
                                        width: 80
                                        height: 32
                                        radius: 8
                                        color: root.cardAccent

                                        Text {
                                            anchors.centerIn: parent
                                            text: "Confirm"
                                            font.pixelSize: 12
                                            font.bold: true
                                            color: root.cardSurfaceDark
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            onClicked: {
                                                confirmAnimTimer.stop()
                                                root.executeSystemAction(root.pendingActionIndex)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true

        onPositionChanged: function(mouse) {
            if (root.systemCardActive) return
            var found = root.findCardAtPoint(mouse.x, mouse.y)
            root.hoveredIndex = found
            if (found >= 0) {
                root.keyboardFocusIndex = found
            }
        }

        onExited: {
            if (!root.systemCardActive) root.hoveredIndex = -1
        }

        onClicked: function(mouse) {
            if (root.systemCardActive) {
                if (root.showSystemConfirm) {
                    root.cancelConfirm()
                } else {
                    root.closeSystemCard()
                }
                return
            }
            var idx = root.findCardAtPoint(mouse.x, mouse.y)
            if (idx >= 0) {
                if (root.launcherCardIndex >= 0 && idx === root.launcherCardIndex) {
                    var card = repeater.itemAt(idx)
                    if (card) {
                        var globalPos = card.mapToItem(root.parent, 0, 0)
                        root.launcherCardClicked(globalPos.x, globalPos.y, card.width, card.height)
                    }
                    root.startClose()
                } else if (idx < root.cardTypes.length && root.cardTypes[idx] === "system") {
                    activateCard(idx)
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

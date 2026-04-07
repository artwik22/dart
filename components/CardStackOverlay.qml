import QtQuick
import QtQuick.Controls

FocusScope {
    id: root

    property var sharedData: null
    property int cardCount: 5
    property var cardIcons: ["♠", "♥", "♦", "󰐥", "⊞"]
    property var cardValues: ["A", "K", "Q", "J", "⌕"]
    property var cardActions: ["kitty", null, null, null, null]
    property var cardBadges: ["⌘", "", "", "⚡", "APPS"]
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
    property int keyboardFocusIndex: -1
    property int launcherCardIndex: -1
    property bool launcherCardActive: false
    property real launcherCardProgress: 0
    property string launcherSearchText: ""
    property var launcherApps: []
    property var launcherSearchResults: []
    property bool launcherLoading: false
    property var launcherSearchInputRef: null
    property real _launcherContentStart: 0.2
    property real _launcherContentEnd: 0.8
    property real _launcherContentT: launcherCardProgress > _launcherContentStart ? Math.max(0, Math.min(1, (launcherCardProgress - _launcherContentStart) / (_launcherContentEnd - _launcherContentStart))) : 0
    property real _launcherContentEased: _launcherContentT > 0 && _launcherContentT < 1 ? easeOutBack(_launcherContentT) : (_launcherContentT >= 1 ? 1 : 0)

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

    // Action severity colors: Lock=gray, Logout=yellow, Reboot=orange, Shutdown=red, Sleep=blue
    property var actionColors: ["#aaaaaa", "#e0a030", "#e07020", "#e03030", "#4a9eff"]

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
        launcherCardActive = false
        launcherCardProgress = 0
        launcherSearchText = ""
        launcherSearchResults = []
        launcherLoading = false
        loadLauncherApps()
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
        if (root.launcherCardActive) {
            if (event.key === Qt.Key_Escape) {
                root.closeLauncherCard()
                launcherCardCloseAnim.start()
                event.accepted = true
                return
            }
            return
        }
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
        if (event.key === Qt.Key_Escape) {
            root.startClose()
            event.accepted = true
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
        if (idx < cardTypes.length && cardTypes[idx] === "system") {
            root.systemCardIndex = idx
            root.systemCardActive = true
            root.systemCardProgress = 0
            root.systemSelectedAction = -1
            root.showSystemConfirm = false
            systemCardOpenAnim.start()
        } else if (idx < cardTypes.length && cardTypes[idx] === "launcher") {
            root.launcherCardIndex = idx
            root.launcherCardActive = true
            root.launcherCardProgress = 0
            launcherCardOpenAnim.start()
            Qt.callLater(function() {
                if (root.launcherSearchInputRef) root.launcherSearchInputRef.forceActiveFocus()
            })
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

    function loadLauncherApps() {
        root.launcherLoading = true
        if (root.sharedData && root.sharedData.runCommand) {
            root.sharedData.runCommand(['sh', '-c', 'python3 /home/iartwik/.config/alloy/dart/scripts/get-apps.py 2>/dev/null || true'])
        }
        loadAppsTimer.start()
    }

    function readLauncherApps() {
        var xhr = new XMLHttpRequest()
        xhr.open("GET", "file:///tmp/alloy_apps.json")
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                try {
                    root.launcherApps = JSON.parse(xhr.responseText)
                    root.launcherSearchResults = root.launcherApps.slice(0, 8)
                    root.launcherLoading = false
                } catch(e) {
                    root.launcherApps = []
                    root.launcherSearchResults = []
                    root.launcherLoading = false
                }
            }
        }
        xhr.send()
    }

    function filterLauncherApps(search) {
        root.launcherSearchText = search
        if (!search || search.trim().length < 1) {
            root.launcherSearchResults = root.launcherApps.slice(0, 8)
            return
        }
        var q = search.trim().toLowerCase()
        var results = []
        for (var i = 0; i < root.launcherApps.length && results.length < 8; i++) {
            var a = root.launcherApps[i]
            if ((a.name && a.name.toLowerCase().indexOf(q) >= 0) ||
                (a.comment && a.comment.toLowerCase().indexOf(q) >= 0) ||
                (a.keywords && a.keywords.toLowerCase().indexOf(q) >= 0)) {
                results.push(a)
            }
        }
        root.launcherSearchResults = results
    }

    function closeLauncherCard() {
        if (!root.launcherCardActive) return
        root.launcherCardProgress = 1
        launcherCardCloseAnim.start()
    }

    function launchAppFromCard(app) {
        if (app.exec) {
            var exec = app.exec
            exec = exec.replace(/%%/g, "___PERCENT_PLACEHOLDER___")
            exec = exec.replace(/%[a-zA-Z]/g, "")
            exec = exec.replace(/___PERCENT_PLACEHOLDER___/g, "%")
            exec = exec.replace(/\s+/g, " ").trim()

            if (root.sharedData && root.sharedData.runCommand) {
                root.sharedData.runCommand(['sh', '-c', exec.replace(/'/g, "'\"'\"'") + ' &'])
            }
            root.startClose()
        }
    }

    function executeSystemAction(idx) {
        if (idx < 0 || idx >= root.systemActions.length) return
        var action = root.systemActions[idx]
        if (sharedData && sharedData.runCommand) {
            sharedData.runCommand(['sh', '-c', action.cmd])
        }
        root.closeSystemCard()
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
                    if (root.sharedData) {
                        root.sharedData.bounceCardsVisible = false
                    }
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
        duration: 600
        easing.type: Easing.InOutCubic
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
        duration: 500
        easing.type: Easing.InOutCubic
        onFinished: {
            root.systemCardActive = false
            root.showSystemConfirm = false
            root.confirmProgress = 0
        }
    }

    NumberAnimation {
        id: launcherCardOpenAnim
        target: root
        property: "launcherCardProgress"
        from: 0
        to: 1
        duration: 600
        easing.type: Easing.InOutCubic
    }

    NumberAnimation {
        id: launcherCardCloseAnim
        target: root
        property: "launcherCardProgress"
        from: 1
        to: 0
        duration: 500
        easing.type: Easing.InOutCubic
        onFinished: {
            root.launcherCardActive = false
            root.launcherSearchText = ""
            root.launcherSearchResults = []
        }
    }

    Timer {
        id: loadAppsTimer
        interval: 800
        repeat: false
        onTriggered: {
            root.readLauncherApps()
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

            // Fan Close: cards collapse to a tight stack at the bottom
            property real closeT: root.systemCardActive ? easeOutCubic(root.systemCardProgress) : 0

            // Closed fan position: tight stack at bottom center
            property real closedFanX: root.implicitWidth / 2 - root.cardWidth / 2
            property real closedFanY: root.implicitHeight - root.cardHeight - 30

            // Each card in the closed stack: slight offset for depth
            property real stackOrder: cardIndex < root.systemCardIndex ? (root.systemCardIndex - cardIndex) : (cardIndex - root.systemCardIndex)
            property real closedFanOffsetX: stackOrder * 2
            property real closedFanOffsetY: stackOrder * 3
            property real closedFanRotation: (cardIndex < root.systemCardIndex ? -1 : 1) * stackOrder * 2

            // Closed fan target position
            property real closedTargetX: closedFanX + (cardIndex < root.systemCardIndex ? -closedFanOffsetX : closedFanOffsetX)
            property real closedTargetY: closedFanY + (cardIndex < root.systemCardIndex ? -closedFanOffsetY : closedFanOffsetY)
            property real closedTargetRotation: (cardIndex < root.systemCardIndex ? -1 : 1) * closedFanRotation

            // Interpolation: open fan -> closed fan (only when system card is active)
            property real otherTargetX: root.systemCardActive ? (animX + (closedTargetX - animX) * closeT) : animX
            property real otherTargetY: root.systemCardActive ? (animY + (closedTargetY - animY) * closeT) : animY
            property real otherTargetRotation: root.systemCardActive ? (cardAngle + (closedTargetRotation - cardAngle) * closeT) : cardAngle

            // Slight scale down in closed stack
            property real otherScale: root.systemCardActive ? (1 - closeT * 0.1) : 1

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
            property real isLauncherCard: (cardIndex === root.launcherCardIndex && root.launcherCardActive) ? 1 : 0
            property real isSpecialCard: isSystemCard || isLauncherCard ? 1 : 0
            property real specialProgress: isSystemCard ? root.systemCardProgress : (isLauncherCard ? root.launcherCardProgress : 0)

            // Flip: 0 -> 180 degrees (easing already applied by NumberAnimation)
            property real flipAngle: isSpecialCard ? specialProgress * 180 : 0
            property real flipXScale: isSpecialCard ? Math.abs(Math.cos(flipAngle * Math.PI / 180)) : 1
            property bool showBackFace: isSpecialCard && flipAngle >= 90

            // Position: fan -> center (easeOutBack)
            property real posT: easeOutBack(specialProgress)
            property real sysX: animX + (root.centerX - animX) * posT * isSpecialCard
            property real sysY: animY + (root.centerY - animY) * posT * isSpecialCard

            // Rotation: fan angle -> 0
            property real sysRotation: cardAngle * (1 - posT * isSpecialCard)

            // Scale: 1 -> 1.7
            property real sysScale: 1 + 0.7 * posT * isSpecialCard

            // Size: normal -> expanded
            property real sizeT: easeOutCubic(specialProgress)
            property real sysWidth: root.cardWidth + 90 * sizeT * isSpecialCard
            property real sysHeight: root.cardHeight + 185 * sizeT * isSpecialCard

            x: isSpecialCard ? sysX : otherTargetX + calcHoverOffset()
            y: isSpecialCard ? sysY : otherTargetY + hoverShift
            width: isSpecialCard ? sysWidth : root.cardWidth * easedProgress
            height: isSpecialCard ? sysHeight : root.cardHeight * easedProgress
            rotation: isSpecialCard ? sysRotation : otherTargetRotation
            opacity: easedProgress
            transformOrigin: Item.Center
            scale: isSpecialCard ? sysScale : (root.systemCardActive || root.launcherCardActive ? otherScale : ((cardIndex === root.hoveredIndex || cardIndex === root.keyboardFocusIndex) ? 1.08 : 1.0))

            z: isSpecialCard ? 200 : ((root.systemCardActive || root.launcherCardActive) ? 50 : ((cardIndex === root.hoveredIndex || cardIndex === root.keyboardFocusIndex) ? 100 : cardIndex))

            // Smooth hover/keyboard animations (disabled during special card animation)
            Behavior on x {
                enabled: !root.systemCardActive && !root.launcherCardActive
                NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
            }
            Behavior on y {
                enabled: !root.systemCardActive && !root.launcherCardActive
                NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
            }
            Behavior on scale {
                enabled: !root.systemCardActive && !root.launcherCardActive
                NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
            }
            Behavior on rotation {
                enabled: !root.systemCardActive && !root.launcherCardActive
                NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
            }

            // Smooth front/back face transitions with overlap at 90°
            property real frontOpacity: Math.max(0, Math.min(1, 1 - (flipAngle / 80)))
            property real backOpacity: Math.max(0, Math.min(1, (flipAngle - 100) / 80))

            Rectangle {
                width: parent.width
                height: parent.height
                radius: 8 + 6 * sizeT * isSystemCard
                clip: isSpecialCard && specialProgress > 0.5

                transform: Scale {
                    xScale: cardItem.flipXScale
                    origin.x: cardItem.width / 2
                    origin.y: cardItem.height / 2
                }

                property real glowOpacity: isSpecialCard && cardItem.showBackFace ? 0.2 : 0

                Behavior on glowOpacity {
                    NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                }

                Behavior on color {
                    ColorAnimation { duration: 200; easing.type: Easing.OutCubic }
                }

                Behavior on glowOpacity {
                    NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                }

                Behavior on color {
                    ColorAnimation { duration: 200; easing.type: Easing.OutCubic }
                }

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
                        text: root.cardIcons[index % root.cardIcons.length]
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

                    // ---- CONDITIONAL BACK FACE ----

                    Text {
                        id: backCenterIcon
                        visible: isSystemCard
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: 22
                        text: "󰐥"
                        font.pixelSize: 32
                        font.bold: true
                        color: root.cardAccent
                        opacity: 0.9
                    }

                    Text {
                        visible: isSystemCard
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
                        visible: isSystemCard
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
                                property real actionT: specialProgress > actionStart ? Math.max(0, Math.min(1, (specialProgress - actionStart - actionDelay) / (actionEnd - actionStart - actionDelay))) : 0
                                property real actionEased: actionT > 0 && actionT < 1 ? easeOutBack(actionT) : (actionT >= 1 ? 1 : 0)

                                width: parent.width
                                height: 42
                                radius: 10
                                property color actionClr: root.actionColors[actionIdx] || root.cardAccent
                                color: actionIdx === root.systemSelectedAction ? Qt.rgba(actionClr.r, actionClr.g, actionClr.b, 0.15) : Qt.rgba(1, 1, 1, 0.03)
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
                                            color: actionIdx === root.systemSelectedAction ? actionClr : root.cardText
                                        }
                                    }

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: modelData.label
                                        font.pixelSize: 13
                                        font.bold: actionIdx === root.systemSelectedAction
                                        color: actionIdx === root.systemSelectedAction ? actionClr : root.cardText
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
                        visible: root.showSystemConfirm && root.systemCardActive
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

                    // ---- LAUNCHER CARD BACK ----
                    Item {
                        id: launcherCardBackItem
                        visible: isLauncherCard
                        anchors.fill: parent

                        property bool _inputActive: root.launcherSearchInputRef && root.launcherSearchInputRef.activeFocus

                        // Search bar glow
                        Rectangle {
                            anchors.fill: launcherSearchBar
                            anchors.margins: -4
                            radius: 14
                            color: "transparent"
                            border.color: root.cardAccent
                            border.width: 2
                            opacity: _inputActive && root._launcherContentEased > 0 ? 0.15 : 0
                            Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                        }

                        // Search bar
                        Rectangle {
                            id: launcherSearchBar
                            visible: root._launcherContentEased > 0
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.margins: 10
                            anchors.topMargin: 12
                            height: 40
                            radius: 10
                            color: Qt.rgba(1, 1, 1, 0.06)
                            border.color: _inputActive ? Qt.rgba(root.cardAccent.r, root.cardAccent.g, root.cardAccent.b, 0.4) : "transparent"
                            border.width: 1
                            opacity: root._launcherContentEased
                            transform: Translate {
                                y: (1 - root._launcherContentEased) * -20
                            }

                            Text {
                                id: searchIcon
                                anchors.left: parent.left
                                anchors.leftMargin: 12
                                anchors.verticalCenter: parent.verticalCenter
                                text: "⌕"
                                font.pixelSize: 16
                                color: root.cardText
                                opacity: _inputActive ? 0.8 : 0.5
                                Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                            }

                            TextInput {
                                id: launcherSearchInput
                                anchors.left: searchIcon.right
                                anchors.leftMargin: 8
                                anchors.right: parent.right
                                anchors.rightMargin: 12
                                anchors.verticalCenter: parent.verticalCenter
                                font.pixelSize: 13
                                font.bold: true
                                color: root.cardText
                                activeFocusOnPress: true
                                Component.onCompleted: root.launcherSearchInputRef = this
                                onTextChanged: {
                                    root.filterLauncherApps(text)
                                }
                                Keys.onReturnPressed: {
                                    if (root.launcherSearchResults.length > 0) {
                                        root.launchAppFromCard(root.launcherSearchResults[0])
                                    }
                                }
                                Keys.onEscapePressed: {
                                    root.closeLauncherCard()
                                    launcherCardCloseAnim.start()
                                }
                            }
                        }

                        // App results list
                        ListView {
                            id: launcherResultsList
                            visible: root._launcherContentEased > 0 && !root.launcherLoading
                            anchors.top: launcherSearchBar.bottom
                            anchors.topMargin: 15
                            anchors.left: parent.left
                            anchors.leftMargin: 10
                            anchors.right: parent.right
                            anchors.rightMargin: 10
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 10
                            clip: true
                            spacing: 4
                            model: root.launcherSearchResults

                            delegate: Rectangle {
                                width: ListView.view.width
                                height: 38
                                radius: 8
                                color: launchMouseArea.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(1, 1, 1, 0.03)

                                Behavior on color {
                                    ColorAnimation { duration: 120 }
                                }

                                Row {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    spacing: 10

                                    Rectangle {
                                        width: 26
                                        height: 26
                                        radius: 6
                                        anchors.verticalCenter: parent.verticalCenter
                                        color: Qt.rgba(1, 1, 1, 0.05)
                                        clip: true

                                        Image {
                                            id: appIconImage
                                            anchors.fill: parent
                                            source: (modelData.icon && modelData.icon.length > 0) ? ("image://icon/" + modelData.icon) : ""
                                            sourceSize.width: 26
                                            sourceSize.height: 26
                                            smooth: true
                                            asynchronous: true
                                            fillMode: Image.PreserveAspectFit
                                            visible: status === Image.Ready
                                        }

                                        Text {
                                            anchors.centerIn: parent
                                            text: "◆"
                                            font.pixelSize: 12
                                            horizontalAlignment: Text.AlignHCenter
                                            verticalAlignment: Text.AlignVCenter
                                            color: root.cardText
                                            opacity: 0.5
                                            visible: appIconImage.status !== Image.Ready
                                        }
                                    }

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: (modelData.name || "")
                                        font.pixelSize: 11
                                        font.bold: true
                                        color: root.cardText
                                        opacity: 0.8
                                    }
                                }

                                MouseArea {
                                    id: launchMouseArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: {
                                        root.launchAppFromCard(modelData)
                                    }
                                }
                            }
                        }

                        // Empty state
                        Text {
                            visible: !root.launcherLoading && root.launcherSearchResults.length === 0 && root.launcherSearchText.length > 0
                            anchors.centerIn: parent
                            text: "No apps found"
                            font.pixelSize: 12
                            color: root.cardText
                            opacity: 0.4
                        }
                    }
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton

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
            if (root.launcherCardActive) {
                return
            }
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
                if (idx < root.cardTypes.length && root.cardTypes[idx] === "system") {
                    activateCard(idx)
                } else if (idx < root.cardTypes.length && root.cardTypes[idx] === "launcher") {
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

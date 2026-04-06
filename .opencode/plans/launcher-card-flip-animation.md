# Launcher Card — Seamless Flip Animation (jak Power Menu)

## Cel
Zintegrować launcher bezpośrednio w `CardStackOverlay` z animacją flip identyczną jak power menu card. Karta index 4 (launcher) po kliknięciu flipuje się 180° i powiększa do centrum, na back face pojawia się searchbox z wynikami wyszukiwania.

## Problem obecnie
- Launcher otwiera się w osobnym `LauncherCardOverlay` po zamknięciu stacka
- Brak ciągłego transition — karty znikają, potem launcher pojawia się osobno
- Brak seamless morph z karty w searchbox

## Zmiany w `CardStackOverlay.qml`

### 1. Nowe właściwości (po linii ~31, po `pendingActionIndex`)

```qml
property bool launcherCardActive: false
property real launcherCardProgress: 0
property int launcherCardIndexVal: 4
property string launcherSearchText: ""
property var launcherApps: []
property int launcherSelectedIndex: 0
property real launcherExpandedHeight: 52
property bool launcherHasResults: launcherSearchText.trim().length > 0 && getFilteredLauncherApps().length > 0
```

### 2. NumberAnimation dla launcher card (po `confirmAnimTimer`, ~linia 251)

```qml
NumberAnimation {
    id: launcherCardOpenAnim
    target: root
    property: "launcherCardProgress"
    from: 0
    to: 1
    duration: 600
    easing.type: Easing.InOutCubic
    onFinished: {
        searchInput.forceActiveFocus()
    }
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
        root.launcherSelectedIndex = 0
    }
}
```

### 3. Funkcje launcher (po `executeSystemAction`, ~linia 165)

```qml
function openLauncherCard() {
    root.launcherCardIndexVal = 4
    root.launcherCardActive = true
    root.launcherCardProgress = 0
    root.launcherSearchText = ""
    root.launcherSelectedIndex = 0
    loadLauncherApps()
    launcherCardOpenAnim.start()
}

function closeLauncherCard() {
    launcherCardCloseAnim.start()
}

function loadLauncherApps() {
    if (!(root.sharedData && root.sharedData.runCommand)) return
    var scriptPath = "/home/iartwik/.config/alloy/dart/scripts/get-apps.py"
    root.sharedData.runCommand(['python3', scriptPath], readLauncherAppsJson)
}

function readLauncherAppsJson() {
    var xhr = new XMLHttpRequest()
    xhr.open("GET", "file:///tmp/alloy_apps.json?_=" + Date.now())
    xhr.onreadystatechange = function() {
        if (xhr.readyState === XMLHttpRequest.DONE) {
            try {
                var data = JSON.parse(xhr.responseText)
                if (Array.isArray(data)) {
                    root.launcherApps = data
                }
            } catch (e) {
                console.error("Error parsing launcher apps JSON: " + e)
            }
        }
    }
    xhr.send()
}

function getFilteredLauncherApps() {
    var search = root.launcherSearchText.trim().toLowerCase()
    if (search.length === 0) return []

    var matches = []
    for (var i = 0; i < root.launcherApps.length; i++) {
        var app = root.launcherApps[i]
        if (!app || !app.name) continue

        var name = app.name.toLowerCase()
        var comment = (app.comment || "").toLowerCase()
        var score = 0

        if (name === search) score = 100
        else if (name.startsWith(search)) score = 80
        else if (name.indexOf(search) >= 0) score = 60
        else if (comment.indexOf(search) >= 0) score = 40

        if (score > 0) matches.push({ app: app, score: score })
    }

    matches.sort(function(a, b) { return b.score - a.score })

    var result = []
    var limit = Math.min(matches.length, 6)
    for (var k = 0; k < limit; k++) result.push(matches[k].app)
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
    closeLauncherCard()
}
```

### 4. Zmiana w `activateCard` (linia ~120-143)

Zmienić warunek dla launcher card:

```qml
function activateCard(idx) {
    if (idx < 0 || idx >= cardCount) return
    if (launcherCardIndex >= 0 && idx === launcherCardIndex) {
        root.openLauncherCard()
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
```

### 5. Keyboard handling — dodać obsługę launcher (w `Keys.onPressed`, ~linia 69)

Dodać na początku `Keys.onPressed`:

```qml
Keys.onPressed: function(event) {
    if (root.launcherCardActive) {
        if (event.key === Qt.Key_Escape) {
            root.closeLauncherCard()
            event.accepted = true
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            var filtered = root.getFilteredLauncherApps()
            if (filtered.length > 0 && root.launcherSelectedIndex < filtered.length) {
                root.launchApp(filtered[root.launcherSelectedIndex])
            }
            event.accepted = true
        } else if (event.key === Qt.Key_Down) {
            var filtered = root.getFilteredLauncherApps()
            if (root.launcherSelectedIndex < filtered.length - 1) {
                root.launcherSelectedIndex++
            }
            event.accepted = true
        } else if (event.key === Qt.Key_Up) {
            if (root.launcherSelectedIndex > 0) {
                root.launcherSelectedIndex--
            }
            event.accepted = true
        }
        return
    }
    if (root.systemCardActive) {
        // ... existing system card handling
    }
    // ... rest of existing handling
}
```

### 6. MouseArea onClicked — dodać obsługę launcher (linia ~770)

W `onClicked` w MouseArea, zmienić warunek:

```qml
onClicked: function(mouse) {
    if (root.launcherCardActive) {
        root.closeLauncherCard()
        return
    }
    if (root.systemCardActive) {
        // ... existing
    }
    // ... rest
}
```

### 7. Launcher card flip/scale logika (w Repeater cardItem, ~linia 344)

Dodać właściwości dla launcher card (analogicznie do system card):

```qml
property real isLauncherCard: (cardIndex === root.launcherCardIndexVal && root.launcherCardActive) ? 1 : 0

// Launcher flip: 0 -> 180 degrees
property real launcherFlipAngle: isLauncherCard ? root.launcherCardProgress * 180 : 0
property real launcherFlipXScale: isLauncherCard ? Math.abs(Math.cos(launcherFlipAngle * Math.PI / 180)) : 1
property bool showLauncherBackFace: isLauncherCard && launcherFlipAngle >= 90

// Launcher position: fan -> center
property real launcherPosT: easeOutBack(root.launcherCardProgress)
property real launcherX: animX + (root.centerX - animX) * launcherPosT * isLauncherCard
property real launcherY: animY + (root.centerY - animY) * launcherPosT * isLauncherCard

// Launcher rotation: fan angle -> 0
property real launcherRotation: cardAngle * (1 - launcherPosT * isLauncherCard)

// Launcher scale: 1 -> 1.7
property real launcherScale: 1 + 0.7 * launcherPosT * isLauncherCard

// Launcher size: normal -> expanded
property real launcherSizeT: easeOutCubic(root.launcherCardProgress)
property real launcherWidth: root.cardWidth + 310 * launcherSizeT * isLauncherCard
property real launcherHeight: root.cardHeight + 100 * launcherSizeT * isLauncherCard
```

### 8. Zmiana x/y/width/height/rotation/scale w cardItem (linia ~371-378)

Zmienić na:

```qml
x: isSystemCard ? sysX : (isLauncherCard ? launcherX : (otherTargetX + calcHoverOffset()))
y: isSystemCard ? sysY : (isLauncherCard ? launcherY : (otherTargetY + hoverShift))
width: isSystemCard ? sysWidth : (isLauncherCard ? launcherWidth : (root.cardWidth * easedProgress))
height: isSystemCard ? sysHeight : (isLauncherCard ? launcherHeight : (root.cardHeight * easedProgress))
rotation: isSystemCard ? sysRotation : (isLauncherCard ? launcherRotation : otherTargetRotation)
opacity: easedProgress
transformOrigin: Item.Center
scale: isSystemCard ? sysScale : (isLauncherCard ? launcherScale : (root.systemCardActive ? otherScale : ((cardIndex === root.hoveredIndex || cardIndex === root.keyboardFocusIndex) ? 1.08 : 1.0)))

z: isSystemCard ? 200 : (isLauncherCard ? 200 : (root.systemCardActive ? 50 : ((cardIndex === root.hoveredIndex || cardIndex === root.keyboardFocusIndex) ? 100 : cardIndex)))
```

### 9. Front face opacity dla launcher (dodać po `frontOpacity`/`backOpacity`, ~linia 401)

```qml
property real launcherFrontOpacity: Math.max(0, Math.min(1, 1 - (launcherFlipAngle / 80)))
property real launcherBackOpacity: Math.max(0, Math.min(1, (launcherFlipAngle - 100) / 80))
```

### 10. Front face Rectangle — dodać launcher transform (linia ~404)

W Rectangle (front face), dodać transform dla launcher flip:

```qml
transform: Scale {
    xScale: cardItem.flipXScale * (cardItem.isLauncherCard ? cardItem.launcherFlipXScale : 1)
    origin.x: cardItem.width / 2
    origin.y: cardItem.height / 2
}
```

### 11. Front face opacity — uwzględnić launcher (linia ~449)

```qml
Item {
    visible: cardItem.frontOpacity > 0 || (cardItem.isLauncherCard && cardItem.launcherFrontOpacity > 0)
    anchors.fill: parent
    opacity: cardItem.isLauncherCard ? cardItem.launcherFrontOpacity : cardItem.frontOpacity
    // ... existing front face content
}
```

### 12. Back face — dodać launcher search UI (po system card back face content, ~linia 539)

W back face Item, dodać:

```qml
// LAUNCHER SEARCH BACK FACE
Item {
    visible: cardItem.showLauncherBackFace
    anchors.fill: parent
    opacity: cardItem.launcherBackOpacity

    // Search area
    Item {
        id: launcherSearchArea
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 52

        Text {
            id: launcherSearchIcon
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 16
            text: "󰍉"
            font.pixelSize: 18
            font.family: "JetBrainsMono Nerd Font"
            color: root.cardAccent
            opacity: 0.8
        }

        TextInput {
            id: searchInput
            anchors.left: launcherSearchIcon.right
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 10
            anchors.rightMargin: 14
            text: root.launcherSearchText
            color: root.cardText
            font.pixelSize: 15
            font.family: "Inter"
            selectionColor: root.cardAccent
            selectedTextColor: root.cardSurfaceDark

            onTextChanged: {
                root.launcherSearchText = text
                root.launcherSelectedIndex = 0
                if (root.launcherCardProgress >= 1) {
                    launcherExpandAnim.from = root.launcherExpandedHeight
                    launcherExpandAnim.to = root.getLauncherTargetHeight()
                    launcherExpandAnim.restart()
                }
            }

            Keys.onPressed: function(event) {
                if (event.key === Qt.Key_Escape) {
                    root.closeLauncherCard()
                    event.accepted = true
                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    var filtered = root.getFilteredLauncherApps()
                    if (filtered.length > 0 && root.launcherSelectedIndex < filtered.length) {
                        root.launchApp(filtered[root.launcherSelectedIndex])
                    }
                    event.accepted = true
                } else if (event.key === Qt.Key_Down) {
                    var filtered = root.getFilteredLauncherApps()
                    if (root.launcherSelectedIndex < filtered.length - 1) {
                        root.launcherSelectedIndex++
                    }
                    event.accepted = true
                } else if (event.key === Qt.Key_Up) {
                    if (root.launcherSelectedIndex > 0) {
                        root.launcherSelectedIndex--
                    }
                    event.accepted = true
                }
            }
        }

        Text {
            anchors.left: launcherSearchIcon.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 10
            text: "Search applications..."
            color: root.cardText
            font.pixelSize: 15
            font.family: "Inter"
            opacity: 0.3
            visible: searchInput.text.length === 0 && !searchInput.activeFocus
        }
    }

    // Results container
    Rectangle {
        id: launcherResultsContainer
        anchors.top: launcherSearchArea.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: root.getResultsHeight()
        color: "transparent"

        ListView {
            id: launcherResultsList
            anchors.fill: parent
            clip: true
            opacity: root.launcherHasResults ? 1 : 0

            Behavior on opacity {
                NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
            }

            model: root.getFilteredLauncherApps()
            delegate: Item {
                width: launcherResultsList.width
                height: 54

                property bool isSel: index === root.launcherSelectedIndex

                Rectangle {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    anchors.topMargin: 4
                    anchors.bottomMargin: 4
                    radius: 8
                    color: root.cardAccent
                    opacity: parent.isSel ? 0.12 : 0
                    visible: opacity > 0.01

                    Behavior on opacity {
                        NumberAnimation { duration: 120 }
                    }
                }

                Image {
                    id: launcherAppIcon
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
                    color: parent.isSel ? root.cardAccent : root.cardText
                    opacity: parent.isSel ? 1 : 0.6
                    visible: !launcherAppIcon.visible
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
                    color: parent.isSel ? root.cardAccent : root.cardText
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
                    color: root.cardText
                    opacity: parent.isSel ? 0.55 : 0.35
                    elide: Text.ElideRight

                    Behavior on opacity {
                        NumberAnimation { duration: 120 }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: root.launcherSelectedIndex = index
                    onClicked: root.launchApp(modelData)
                }
            }

            ScrollIndicator.vertical: ScrollIndicator { active: false }
        }

        Column {
            anchors.centerIn: parent
            spacing: 8
            visible: launcherResultsList.count === 0 && root.launcherSearchText.length > 0

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "󰍉"
                font.pixelSize: 28
                font.family: "JetBrainsMono Nerd Font"
                color: root.cardText
                opacity: 0.2
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "No applications found"
                font.pixelSize: 13
                font.family: "Inter"
                color: root.cardText
                opacity: 0.35
            }
        }
    }
}
```

### 13. Helper functions (dodać po `executeSystemAction`)

```qml
function getLauncherTargetHeight() {
    var resultsH = root.getResultsHeight()
    return 52 + resultsH + (root.launcherHasResults ? 14 : 0)
}

function getResultsHeight() {
    var count = root.getFilteredLauncherApps().length
    return root.launcherHasResults ? Math.min(count * 54, 360) : 0
}
```

### 14. launcherExpandAnim (dodać po launcherCardCloseAnim)

```qml
NumberAnimation {
    id: launcherExpandAnim
    target: root
    property: "launcherExpandedHeight"
    duration: 200
    easing.type: Easing.OutCubic
}
```

## Zmiany w `shell.qml`

### 1. Usunąć osobny LauncherCardOverlay (linie ~974-1023)

Usunąć cały blok:
```qml
property bool launcherCardActive: false

Loader {
    id: launcherCardOverlay
    // ... entire loader
}
```

### 2. Zmienić `onLauncherCardClicked` (linie ~941-947)

Zmienić na:
```qml
onLauncherCardClicked: function(x, y, w, h) {
    bounceCardsOverlay.openLauncherCard()
}
```

## Zmiany w `LauncherCardOverlay.qml`

Brak — plik zostaje nieużywany (można usunąć później).

## Podsumowanie flow

1. Użytkownik klika kartę launcher (index 4) w stacku
2. `openLauncherCard()` — karta flipuje się 180° (jak power menu)
3. Na back face pojawia się searchbox z TextInput
4. Reszta kart pozostaje widoczna w tle (jak w power menu)
5. Użytkownik wpisuje → wyniki się filtrują
6. Enter = launch, Escape = close (flip back)

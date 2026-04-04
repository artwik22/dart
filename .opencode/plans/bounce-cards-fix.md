# Plan naprawczy - Bouncing Cards

## Diagnoza

### Przyczyna 1: Brakujący plik `BounceCards.qml`
- `components/qmldir:35` deklaruje `BounceCards 1.0 BounceCards.qml`
- Plik nie istnieje na dysku
- Może powodować błędy ładowania modułu QML

### Przyczyna 2: `PanelWindow` nie ma przypisanego ekranu (GŁÓWNA)
- `shell.qml:911-921` - `PanelWindow` dla bounce cards **nie otrzymuje** właściwości `screen`
- Wszystkie inne komponenty (`Dashboard`, `SidePanel`, `NotificationDisplay`) dostają `screen: modelData`
- Bez tego `PanelWindow` nie wie na którym monitorze/wayland output się wyświetlić

```qml
// shell.qml:902-909 - Variants tworzy Loader z modelData
Variants {
    model: Quickshell.screens.length > 0 ? [Quickshell.screens[0]] : []
    delegate: Component {
        Loader {
            required property var modelData  // <-- jest, ale NIGDZIE NIE PRZEKAZANE
            ...
            PanelWindow {
                // <-- BRAK: screen: ???
            }
        }
    }
}
```

### Przyczyna 3: Problem z timingiem `Connections`
- Wewnętrzny `Connections` (`shell.qml:944-957`) nasłuchuje `onBounceCardsVisibleChanged`
- Sygnał odpala się **zanim** `Loader` zdąży załadować komponent (`asynchronous: true`)
- `openX`/`openY` nigdy nie są ustawiane (zostają `-1`)
- Fallback centruje karty, ale jeśli `PanelWindow` nie jest przypisany do ekranu, to i tak nic nie widać

### Przyczyna 4: `CardStackOverlay` nie ma jawnego `visible: true`
- Timer zamykający (`CardStackOverlay.qml:63`) ustawia `root.visible = false`
- Przy tworzeniu nie ma jawnego `visible: true`
- Po poprzednim zamknięciu może zostać w złym stanie

---

## Kroki naprawcze

### Krok 1: Usuń fałszywy wpis z `qmldir`

**Plik:** `components/qmldir`

**Zmień (linia 35-36):**
```
BounceCards 1.0 BounceCards.qml
CardStackOverlay 1.0 CardStackOverlay.qml
```

**Na:**
```
CardStackOverlay 1.0 CardStackOverlay.qml
```

---

### Krok 2: Przekaż `screen` do `PanelWindow`

**Plik:** `shell.qml`

**Znajdź (linia 911-921):**
```qml
PanelWindow {
    id: bounceCardsWindow
    anchors {
        left: true
        top: true
        right: true
        bottom: true
    }
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
```

**Dodaj właściwość `screen`:**
```qml
PanelWindow {
    id: bounceCardsWindow
    screen: bounceCardsLoader.modelData
    anchors {
        left: true
        top: true
        right: true
        bottom: true
    }
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
```

---

### Krok 3: Napraw timing pozycjonowania `openX`/`openY`

**Plik:** `shell.qml`

**Opcja A (zalecana):** Przenieś logikę pozycjonowania do `Component.onCompleted` wewnątrz `PanelWindow`:

Dodaj do `PanelWindow` (po `property bool positionLocked: false`):
```qml
Component.onCompleted: {
    openX = root.cursorX
    openY = root.cursorY
}
```

**Usuń lub zakomentuj** wewnętrzny `Connections` (linie 944-957):
```qml
// Connections {
//     target: root.sharedData
//     function onBounceCardsVisibleChanged() {
//         if (root.sharedData.bounceCardsVisible) {
//             sharedData.setTimeout(function() {
//                 bounceCardsWindow.openX = root.cursorX
//                 bounceCardsWindow.openY = root.cursorY
//             }, 50)
//         }
//         if (!root.sharedData.bounceCardsVisible && bounceCardsOverlay.startClose) {
//             bounceCardsOverlay.startClose()
//             bounceCardsUnloadTimer.restart()
//         }
//     }
// }
```

**Zamiast tego** przenieś logikę zamykania do `onBounceCardsVisibleChanged` w głównym `Connections` (linie 776-779):
```qml
function onBounceCardsVisibleChanged() { 
    if (root.sharedData.bounceCardsVisible) bounceCardsActive = true; 
    else {
        if (bounceCardsOverlay && bounceCardsOverlay.startClose) {
            bounceCardsOverlay.startClose()
        }
        unloadDelayTimer.restart(); 
    }
}
```

---

### Krok 4: Dodaj jawne `visible: true` do `CardStackOverlay`

**Plik:** `components/CardStackOverlay.qml`

**Znajdź (po linii 22):**
```qml
signal launcherCardClicked(real x, real y, real width, real height)
```

**Dodaj:**
```qml
visible: true
```

**Lub** zmień `Component.onCompleted` (linia 34-36):
```qml
Component.onCompleted: {
    visible = true
    isClosing = false
    animationProgress = 0
    openTimer.start()
}
```

---

### Krok 5: Uprość architekturę (opcjonalne, zalecane)

**Plik:** `shell.qml`

Zamiast `Variants` + `Loader` + `Component` + `PanelWindow`, użyj prostszego wzorca jak `ScreenshotThumbnail`:

```qml
Variants {
    model: Quickshell.screens.length > 0 ? [Quickshell.screens[0]] : []
    delegate: Component {
        Loader {
            id: bounceCardsLoader
            required property var modelData
            asynchronous: true
            active: root.bounceCardsActive
            sourceComponent: Component {
                PanelWindow {
                    screen: bounceCardsLoader.modelData
                    // ... reszta bez zmian
                }
            }
        }
    }
}
```

---

## Podsumowanie zmian

| Plik | Linia | Typ | Priorytet |
|------|-------|-----|-----------|
| `components/qmldir` | 35 | Usuń linię | Wysoki |
| `shell.qml` | 911 | Dodaj `screen:` | Wysoki |
| `shell.qml` | 944-957 | Przenieś logikę | Wysoki |
| `shell.qml` | 776-779 | Rozbuduj handler | Wysoki |
| `CardStackOverlay.qml` | 34-36 | Dodaj reset | Średni |

import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import "components"

ShellRoot {
    id: root
    
    // Współdzielone właściwości (jeśli potrzebne)
    property var sharedData: QtObject {
        property bool menuVisible: false
        property bool launcherVisible: false
        property bool volumeVisible: false
        property bool volumeEdgeHovered: false  // Czy myszka jest nad detektorem krawędzi
    }
    
    // Funkcja do zamykania/otwierania menu
    function toggleMenu() {
        sharedData.menuVisible = !sharedData.menuVisible
    }
    
    // Funkcja lock screen - współdzielona między komponentami
    function lockScreen() {
        Qt.createQmlObject("import Quickshell.Io; import QtQuick; Process { command: ['hyprlock']; running: true }", root)
    }
    
    // Funkcja otwierania ustawień - można rozszerzyć
    function openSettings() {
        // Otwiera TopMenu
        sharedData.menuVisible = true
    }
    
    // Funkcja otwierania launcher'a aplikacji
    function openLauncher() {
        sharedData.launcherVisible = !sharedData.launcherVisible
    }
    
    // Timer do monitorowania pliku poleceń dla skrótów klawiszowych z Hyprland
    Timer {
        id: commandCheckTimer
        interval: 100  // Sprawdzaj co 100ms
        running: true
        repeat: true
        
        onTriggered: {
            var xhr = new XMLHttpRequest()
            xhr.open("GET", "file:///tmp/quickshell_command")
            xhr.onreadystatechange = function() {
                if (xhr.readyState === XMLHttpRequest.DONE) {
                    if (xhr.status === 200 || xhr.status === 0) {
                        var cmd = xhr.responseText.trim()
                        if (cmd === "openLauncher") {
                            root.openLauncher()
                            // Usuń plik po przetworzeniu
                            Qt.createQmlObject("import Quickshell.Io; import QtQuick; Process { command: ['sh', '-c', 'rm -f /tmp/quickshell_command']; running: true }", root)
                        } else if (cmd === "toggleMenu") {
                            root.toggleMenu()
                            // Usuń plik po przetworzeniu
                            Qt.createQmlObject("import Quickshell.Io; import QtQuick; Process { command: ['sh', '-c', 'rm -f /tmp/quickshell_command']; running: true }", root)
                        }
                    }
                }
            }
            xhr.send()
        }
    }
    
    Variants {
        model: Quickshell.screens
        
        delegate: Component {
            Item {
                id: screenContainer
                required property var modelData
                
                // Panel boczny (SidePanel) - jeden na ekran
                SidePanel {
                    id: sidePanelInstance
                    screen: modelData
                    lockScreenFunction: root.lockScreen
                    settingsFunction: root.openSettings
                    launcherFunction: root.openLauncher
                }
                
                // Wykrywacz górnej krawędzi - wykrywa najechanie myszką
                TopEdgeDetector {
                    id: edgeDetectorInstance
                    screen: modelData
                    sharedData: root.sharedData
                }
                
                // Wykrywacz prawej krawędzi - wykrywa najechanie myszką
                RightEdgeDetector {
                    id: rightEdgeDetectorInstance
                    screen: modelData
                    sharedData: root.sharedData
                }
            }
        }
    }
    
    // TopMenu - jeden globalny (nie per-ekran)
    // Pokazuje się gdy myszka najedzie na górną krawędź ekranu
    TopMenu {
        id: topMenuInstance
        sharedData: root.sharedData
    }
    
    // AppLauncher - launcher aplikacji (rofi-like)
    // Używamy pierwszego ekranu do wyśrodkowania
    AppLauncher {
        id: appLauncherInstance
        sharedData: root.sharedData
        screen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
    }
    
    // VolumeSlider - slider głośności na prawej krawędzi
    // Pokazuje się gdy myszka najedzie na prawą krawędź ekranu
    VolumeSlider {
        id: volumeSliderInstance
        sharedData: root.sharedData
    }
}


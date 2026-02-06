import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: wallpaperWindow
    
    required property var screen
    property string currentWallpaper: ""
<<<<<<< HEAD
    
    screen: wallpaperWindow.screen
    
=======

>>>>>>> master
    anchors {
        left: true
        top: true
        right: true
        bottom: true
    }
    
<<<<<<< HEAD
    implicitWidth: screen ? screen.width : 1920
    implicitHeight: screen ? screen.height : 1080
    
    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "qswallpaper"
=======
    implicitWidth: screen ? screen.width : 2160
    implicitHeight: screen ? screen.height : 1440
    
    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "qswallpaper-" + (screen && screen.name ? screen.name : "0")
>>>>>>> master
    exclusiveZone: -1  // Pełny ekran
    
    visible: true
    color: "transparent"
    
    margins {
        left: 0
        top: 0
        right: 0
        bottom: 0
    }
    
    onCurrentWallpaperChanged: {
<<<<<<< HEAD
        console.log("WallpaperBackground: currentWallpaper changed to:", currentWallpaper)
=======
>>>>>>> master
    }
    
    // Image element do wyświetlenia tapety
    Image {
        id: wallpaperImage
        anchors.fill: parent
        source: currentWallpaper ? (currentWallpaper.startsWith("/") ? "file://" + currentWallpaper : currentWallpaper) : ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
<<<<<<< HEAD
        cache: false  // Disable cache to always show latest version
        
        onStatusChanged: {
            if (status === Image.Error) {
                console.log("WallpaperBackground: Error loading wallpaper:", source)
            } else if (status === Image.Ready) {
                console.log("WallpaperBackground: Successfully loaded wallpaper:", source)
=======
        cache: true
        
        onStatusChanged: {
            if (status === Image.Error) {
            } else if (status === Image.Ready) {
>>>>>>> master
            }
        }
        
        // Smooth transition when changing wallpaper
        Behavior on source {
            PropertyAnimation {
                duration: 500
                easing.type: Easing.InOutQuad
            }
        }
        
        // Opacity animation for fade effect
        opacity: currentWallpaper ? 1.0 : 0.0
        Behavior on opacity {
            NumberAnimation {
                duration: 500
                easing.type: Easing.InOutQuad
            }
        }
    }
    
    // Fallback color if no wallpaper is set
    Rectangle {
        anchors.fill: parent
        color: "#0a0a0a"
        visible: !currentWallpaper || currentWallpaper === ""
        z: -1
    }
}


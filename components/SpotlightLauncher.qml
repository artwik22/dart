import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "."

PanelWindow {
    id: spotlightRoot

    property var sharedData: null
    property var screen: null
    property string projectPath: ""

    // --- Color Theme ---
    property string colorBackground: sharedData ? sharedData.colorBackground : "#0a0a0a"
    property string colorPrimary: sharedData ? sharedData.colorPrimary : "#1a1a1a"
    property string colorSecondary: sharedData ? sharedData.colorSecondary : "#141414"
    property string colorText: sharedData ? sharedData.colorText : "#ffffff"
    property string colorAccent: sharedData ? sharedData.colorAccent : "#4a9eff"
    property int borderRadius: (sharedData && sharedData.quickshellBorderRadius) ? sharedData.quickshellBorderRadius : 12

    // --- State ---
    property string searchText: ""
    property int selectedIndex: 0
    property bool isExpanded: searchText.length > 0
    
    // Results model
    ListModel { id: resultsModel }
    
    // Combined results count for keyboard navigation
    property int totalResults: resultsModel.count

    // --- Layout ---
    property int barWidth: 600
    property int expandedHeight: 450
    property int collapsedHeight: 60
    
    implicitWidth: barWidth
    implicitHeight: isExpanded ? expandedHeight : collapsedHeight

    Behavior on implicitHeight {
        NumberAnimation { duration: 300; easing.type: Easing.OutQuart }
    }

    // Centering
    margins {
        left: screen ? (screen.width - width) / 2 : 0
        right: screen ? (screen.width - width) / 2 : 0
        top: screen ? (screen.height - height) / 2 : 0
        bottom: screen ? (screen.height - height) / 2 : 0
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    
    color: "transparent"
    visible: sharedData ? sharedData.launcherVisible : false

    onVisibleChanged: {
        if (visible) {
            searchInput.forceActiveFocus()
            loadApps()
        } else {
            searchText = ""
            searchInput.text = ""
        }
    }

    // --- Background/Frame ---
    Rectangle {
        anchors.fill: parent
        color: colorBackground
        radius: spotlightRoot.borderRadius
        clip: true

        Column {
            anchors.fill: parent
            spacing: 0

            // Search Bar
            Item {
                width: parent.width
                height: spotlightRoot.collapsedHeight

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 20
                    anchors.rightMargin: 20
                    spacing: 15
                    
                    Text {
                        text: "󰍉"
                        font.pixelSize: 24
                        color: spotlightRoot.colorAccent
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    TextInput {
                        id: searchInput
                        width: parent.width - 80
                        height: 40
                        anchors.verticalCenter: parent.verticalCenter
                        color: spotlightRoot.colorText
                        font.pixelSize: 20
                        focus: true
                        selectByMouse: true
                        
                        onTextChanged: {
                            spotlightRoot.searchText = text
                            spotlightRoot.selectedIndex = 0
                            filterResults()
                        }

                        Keys.onPressed: (event) => {
                            if (event.key === Qt.Key_Escape) {
                                spotlightRoot.sharedData.launcherVisible = false
                            } else if (event.key === Qt.Key_Down) {
                                spotlightRoot.selectedIndex = (spotlightRoot.selectedIndex + 1) % spotlightRoot.totalResults
                            } else if (event.key === Qt.Key_Up) {
                                spotlightRoot.selectedIndex = (spotlightRoot.selectedIndex - 1 + spotlightRoot.totalResults) % spotlightRoot.totalResults
                            } else if (event.key === Qt.Key_Return) {
                                launchSelected()
                            }
                        }
                    }
                }
            }

            // Divider
            Rectangle {
                width: parent.width
                height: 1
                color: Qt.rgba(1, 1, 1, 0.05)
                visible: spotlightRoot.isExpanded
            }

            // Results Area
            ListView {
                id: resultsList
                width: parent.width
                height: parent.height - spotlightRoot.collapsedHeight
                visible: spotlightRoot.isExpanded
                clip: true
                model: resultsModel
                delegate: resultDelegate
                currentIndex: spotlightRoot.selectedIndex
                
                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                }
            }
        }
    }

    // --- Search Logic ---
    property var allApps: []
    
    function loadApps() {
        if (allApps.length > 0) return
        
        sharedData.runCommand(['sh', '-c', 'find /usr/share/applications ~/.local/share/applications -name "*.desktop" 2>/dev/null > /tmp/quickshell_apps_raw'], () => {
             var xhr = new XMLHttpRequest()
             xhr.open("GET", "file:///tmp/quickshell_apps_raw")
             xhr.onreadystatechange = function() {
                 if (xhr.readyState === XMLHttpRequest.DONE) {
                     var text = xhr.responseText || ""
                     if (text.length > 0) {
                         var files = text.trim().split("\n")
                         files.forEach(file => {
                             if (file.trim().length > 0) {
                                 readDesktopFile(file.trim())
                             }
                         })
                     }
                 }
             }
             xhr.send()
        })
    }


    function readDesktopFile(path) {
        var xhr = new XMLHttpRequest()
        xhr.open("GET", "file://" + path)
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE && (xhr.status === 200 || xhr.status === 0)) {
                var lines = xhr.responseText.split("\n")
                var app = { name: "", exec: "", icon: "", comment: "" }
                var entry = false
                lines.forEach(line => {
                    var l = line.trim()
                    if (l === "[Desktop Entry]") entry = true
                    else if (l.startsWith("[")) entry = false
                    
                    if (entry) {
                        if (l.startsWith("Name=")) app.name = l.substring(5).trim()
                        if (l.startsWith("Exec=")) app.exec = l.substring(5).trim()
                        if (l.startsWith("Icon=")) app.icon = l.substring(5).trim()
                        if (l.startsWith("Comment=")) app.comment = l.substring(8).trim()
                    }
                })
                if (app.name && app.exec) {
                    allApps.push(app)
                }
            }
        }
        xhr.send()
    }


    function filterResults() {
        resultsModel.clear()
        
        if (searchText.length === 0) return

        var query = searchText.toLowerCase()
        
        // Filter Apps
        var count = 0
        allApps.forEach(app => {
            if (count < 5 && (app.name.toLowerCase().includes(query) || app.comment.toLowerCase().includes(query))) {
                resultsModel.append({
                    title: app.name,
                    subtitle: app.comment || app.exec,
                    icon: "󰀻", // Placeholder icon
                    type: "app",
                    exec: app.exec
                })
                count++
            }
        })
        
        // Search Files (Async)
        searchFiles(query)
    }

    function searchFiles(query) {
        if (query.length < 3) return
        
        // Use find to look for files in home dir
        sharedData.runCommand(['sh', '-c', 'find ~ -maxdepth 2 -iname "*' + query + '*" -not -path "*/.*" 2>/dev/null | head -5 > /tmp/quickshell_file_search_results'], () => {
             var xhr = new XMLHttpRequest()
             xhr.open("GET", "file:///tmp/quickshell_file_search_results")
             xhr.onreadystatechange = function() {
                 if (xhr.readyState === XMLHttpRequest.DONE) {
                     var text = xhr.responseText || ""
                     if (text.length > 0) {
                         var lines = text.trim().split("\n")
                         lines.forEach(line => {
                             if (line.trim().length > 0) {
                                 var parts = line.split("/")
                                 resultsModel.append({
                                     title: parts[parts.length - 1],
                                     subtitle: line,
                                     icon: "󰈔",
                                     type: "file",
                                     path: line
                                 })
                             }
                         })
                     }
                 }
             }
             xhr.send()
        })
    }

    Component {
        id: resultDelegate
        Rectangle {
            width: spotlightRoot.barWidth
            height: 60
            color: index === spotlightRoot.selectedIndex ? Qt.rgba(1, 1, 1, 0.05) : "transparent"
            
            Row {
                anchors.fill: parent
                anchors.leftMargin: 20
                anchors.rightMargin: 20
                spacing: 15
                
                Text {
                    text: icon // Now directly from the role
                    font.pixelSize: 28
                    color: index === spotlightRoot.selectedIndex ? spotlightRoot.colorAccent : spotlightRoot.colorText
                    anchors.verticalCenter: parent.verticalCenter
                    width: 32
                    horizontalAlignment: Text.AlignHCenter
                }
                
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    Text {
                        text: title // Directly from the role
                        color: index === spotlightRoot.selectedIndex ? spotlightRoot.colorAccent : spotlightRoot.colorText
                        font.pixelSize: 18
                        font.bold: index === spotlightRoot.selectedIndex
                    }
                    Text {
                        text: subtitle // Directly from the role
                        color: Qt.rgba(1, 1, 1, 0.5)
                        font.pixelSize: 13
                        width: spotlightRoot.barWidth - 100
                        elide: Text.ElideRight
                    }
                }
            }
            
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    spotlightRoot.selectedIndex = index
                    launchSelected()
                }
            }
        }
    }

    function launchSelected() {
        if (selectedIndex >= 0 && selectedIndex < resultsModel.count) {
            var item = resultsModel.get(selectedIndex)
            if (item.type === "app") {
                // Launch app
                var exec = item.exec.replace(/%[a-zA-Z]/g, "").trim()
                sharedData.runCommand(['sh', '-c', exec + ' &'])
            } else if (item.type === "file") {
                // Open file (using xdg-open)
                sharedData.runCommand(['sh', '-c', 'xdg-open "' + item.path + '" &'])
            }
            sharedData.launcherVisible = false
        }
    }
}

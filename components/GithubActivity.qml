import QtQuick
import QtQuick.Layouts

Item {
    id: root
    
    // Public properties
    property var sharedData: null
    property string statusText: ""
    property int refreshMinutes: 30

    // Dynamic properties calculated from size
    // We want 7 rows exactly.
    // margins = 0 (handle via anchors if needed)
    // spacing = 3
    property int rowCount: 7
    property int tileSpacing: 3
    
    // Calculate max tile size that fits vertically
    property real availableHeight: gridContainer.height
    property int calculatedTileSize: Math.max(10, Math.floor((availableHeight - (rowCount - 1) * tileSpacing) / rowCount))
    
    // Calculate columns that fit horizontally
    property real availableWidth: gridContainer.width
    property int columns: Math.max(1, Math.floor((availableWidth + tileSpacing) / (calculatedTileSize + tileSpacing)))
    
    // Data model
    ListModel {
        id: contributionModel
    }

    ColumnLayout {
        anchors.fill: parent
        // "powieksz na caly ten kafelek" -> The Dashboard Loader has 16px margins.
        // We use negative margins here to "bleed" out and fill the card more completely.
        anchors.margins: -12 
        spacing: 0

        // Header removed as requested to maximize space
        
        Item {
            id: gridContainer
            Layout.fillWidth: true
            Layout.fillHeight: true
            
            Rectangle {
                id: gridRect
                // Center the grid in the container
                width: tilesGrid.width
                height: tilesGrid.height
                anchors.centerIn: parent
                color: "transparent"

                Grid {
                    id: tilesGrid
                    columns: root.columns
                    rows: 7
                    spacing: root.tileSpacing
                    flow: Grid.TopToBottom

                    Repeater {
                        model: contributionModel
                        delegate: Rectangle {
                            width: root.calculatedTileSize
                            height: root.calculatedTileSize
                            radius: (sharedData && sharedData.quickshellBorderRadius) ? sharedData.quickshellBorderRadius : 0
                            
                            color: {
                                if (level === 0) return (sharedData && sharedData.colorSecondary) ? Qt.lighter(sharedData.colorSecondary, 1.2) : "#2d2d2d"
                                var base = (sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff"
                                var alpha = 0.3 + (level - 1) * 0.23
                                if (level >= 4) alpha = 1.0
                                return Qt.rgba(
                                    (sharedData && sharedData.colorAccent) ? Qt.color(base).r : 0.29,
                                    (sharedData && sharedData.colorAccent) ? Qt.color(base).g : 0.62,
                                    (sharedData && sharedData.colorAccent) ? Qt.color(base).b : 1.0,
                                    alpha
                                )
                            }
                            
                            border.color: isToday ? "#ffffff" : "transparent"
                            border.width: isToday ? 1 : 0

                            MouseArea {
                                id: ma
                                anchors.fill: parent
                                hoverEnabled: true
                                // Add click to refresh since header is gone
                                onClicked: root.loadActivity()
                            }
                            
                            Rectangle {
                                visible: ma.containsMouse
                                z: 100
                                width: ttLabel.width + 12
                                height: ttLabel.height + 8
                                color: "#1a1a1a"
                                border.color: "#555"
                                radius: (sharedData && sharedData.quickshellBorderRadius) ? sharedData.quickshellBorderRadius : 0
                                y: -height - 4
                                x: (parent.width - width) / 2
                                
                                Text {
                                    id: ttLabel
                                    anchors.centerIn: parent
                                    text: date + "\n" + count
                                    font.pixelSize: 10
                                    color: "#fff"
                                    horizontalAlignment: Text.AlignHCenter
                                }
                            }
                        }
                    }
                }
            }
            
            Text {
                anchors.centerIn: parent
                text: "Loading..."
                color: "#aaaaaa"
                visible: contributionModel.count === 0
            }
        }
    }

    function loadActivity() {
        var username = (sharedData && sharedData.githubUsername) ? String(sharedData.githubUsername) : ""
        if (!username || username.length === 0) {
             statusText = "No user"
             contributionModel.clear()
             return
        }
        
        statusText = ""
        // Use Official GitHub HTML to get live data (API was stale)
        // Add timestamp to force refresh on restart (bypass cache)
        var url = "https://github.com/users/" + username + "/contributions?t=" + new Date().getTime()
        var xhr = new XMLHttpRequest()
        xhr.open("GET", url)
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE) return
            
            if (xhr.status !== 200 && xhr.status !== 0) {
                statusText = "Error: " + xhr.status
                return
            }
            
            try {
                var html = xhr.responseText
                
                // Regex to find data-date and data-level
                // Example: <td ... data-date="2026-01-27" ... data-level="4" ... >
                var regex = /data-date="([^"]+)"[^>]*data-level="(\d+)"/g
                var match
                var items = []
                
                while ((match = regex.exec(html)) !== null) {
                    items.push({
                        date: match[1],
                        level: parseInt(match[2]),
                        count: 0 // Count not easily parsable from TD attributes, strictly visual
                    })
                }
                
                if (items.length === 0) {
                    statusText = "No data found (Parse check)"
                    // Fallback or retry?
                    return
                }
                
                // Map for lookup
                var contribMap = {}
                for (var i = 0; i < items.length; i++) {
                    contribMap[items[i].date] = items[i]
                }
                
                // Calculate size
                var totalCells = root.columns * 7
                
                // UTC based alignment
                var now = new Date()
                var todayUTC = new Date(Date.UTC(now.getFullYear(), now.getMonth(), now.getDate()))
                
                var currentDay = todayUTC.getUTCDay()
                var daysToSat = 6 - currentDay
                
                contributionModel.clear()
                
                // Start Date
                var startDate = new Date(todayUTC)
                startDate.setUTCDate(todayUTC.getUTCDate() + daysToSat - totalCells + 1)
                
                var iterDate = new Date(startDate)
                
                var formatUTC = function(d) {
                    var y = d.getUTCFullYear()
                    var m = d.getUTCMonth() + 1
                    var dd = d.getUTCDate()
                    return y + "-" + (m < 10 ? "0"+m : m) + "-" + (dd < 10 ? "0"+dd : dd)
                }
                
                var todayStr = formatUTC(todayUTC)
                 console.log("GithubActivity: Scraped " + items.length + " items. Generating range from " + formatUTC(startDate))

                for (var k = 0; k < totalCells; k++) {
                    var dateStr = formatUTC(iterDate)
                    var isFuture = (iterDate > todayUTC)
                    var isToday = (dateStr === todayStr)
                    
                    var data = contribMap[dateStr]
                    var level = (data && data.level !== undefined) ? data.level : 0
                    
                    // Note: 'count' is unknown via scraping, so we show "?" or nothing in tooltip
                    // But usually level is enough for visual
                    
                    if (isFuture) { level = 0; }

                    contributionModel.append({
                        "date": dateStr,
                        "count": (data ? "Level " + level : "0"), // Text for tooltip
                        "level": level,
                        "isToday": isToday,
                        "isFuture": isFuture
                    })
                    
                    iterDate.setUTCDate(iterDate.getUTCDate() + 1)
                }
                
            } catch (e) {
                console.log("GithubActivity: Parse error", e)
                statusText = "Parse error"
            }
        }
        xhr.send()
    }

    Timer {
        id: refreshTimer
        interval: refreshMinutes * 60 * 1000
        repeat: true
        running: true
        onTriggered: root.loadActivity()
    }
    
    // Refresh on size change
    onColumnsChanged: {
        // Debounce slightly or just reload
        if (root.columns > 0) root.loadActivity()
    }
    onCalculatedTileSizeChanged: {
        if (root.columns > 0) root.loadActivity()
    }
    
    Component.onCompleted: {
        root.loadActivity()
    }
    
    Connections {
        target: sharedData
        function onGithubUsernameChanged() { root.loadActivity() }
    }
    
    // Ensure we load if sharedData arrives late
    onSharedDataChanged: root.loadActivity()
}

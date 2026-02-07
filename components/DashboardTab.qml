import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQml
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "."

Item {
    id: dashboardTabRoot
    property var root: null
    property var sharedData: root ? root.sharedData : null
    property real showProgress: root ? root.showProgress : 0
    
    anchors.fill: parent
    
    ColumnLayout {
        id: dashboardTabColumn
        anchors.fill: parent
        anchors.margins: 12
        spacing: 5
        
        // Row with left tile (Battery or Network) and Quick Actions side by side
        Row {
            Layout.fillWidth: true
            Layout.fillHeight: false
            Layout.preferredHeight: 90
            spacing: 5
            
            // Left Tile: Battery OR Network
            Rectangle {
                width: parent.width * 0.4
                height: 90
                radius: (sharedData && sharedData.quickshellBorderRadius) ? sharedData.quickshellBorderRadius : 0
                color: (sharedData && sharedData.colorPrimary) ? sharedData.colorPrimary : "#1a1a1a"
                
                property string tileType: (sharedData && sharedData.dashboardTileLeft) ? sharedData.dashboardTileLeft : "battery"
                
                Column {
                    anchors.centerIn: parent
                    spacing: 4
                    
                    Text {
                        text: parent.parent.tileType === "battery" ? 
                            (root.batteryPercent >= 80 ? "󰁹" : (root.batteryPercent >= 40 ? "󰁾" : "󰁺")) : "󰇚"
                        font.pixelSize: 24
                        color: (sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#00ff41"
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    
                    Text {
                        text: parent.parent.tileType === "battery" ? 
                            (root.batteryPercent >= 0 ? root.batteryPercent + "%" : "AC") : 
                            (root.networkRxMBs + root.networkTxMBs).toFixed(1) + " MB/s"
                        font.pixelSize: 14
                        font.family: "sans-serif"
                        font.weight: Font.Bold
                        color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#000000"
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    
                    Text {
                        text: parent.parent.tileType === "battery" ? "BATTERY STATUS" : "NETWORK TRAFFIC"
                        font.pixelSize: 8
                        font.family: "sans-serif"
                        font.weight: Font.Black
                        color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#000000"
                        opacity: 0.5
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
                
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (sharedData) {
                            sharedData.dashboardTileLeft = parent.tileType === "battery" ? "network" : "battery"
                        }
                    }
                }
            }
            
            // Quick Actions Block
            Rectangle {
                width: parent.width * 0.6 - 5
                height: 90
                radius: (sharedData && sharedData.quickshellBorderRadius) ? sharedData.quickshellBorderRadius : 0
                color: (sharedData && sharedData.colorPrimary) ? sharedData.colorPrimary : "#1a1a1a"
                
                Row {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 10
                    
                    Repeater {
                        model: [
                            { icon: "󰐥", label: "OFF", action: function() { root.shutdownSystem() } },
                            { icon: "󰑐", label: "REB", action: function() { root.rebootSystem() } },
                            { icon: "󰤄", label: "SUS", action: function() { root.suspendSystem() } },
                            { icon: "󰈆", label: "LOG", action: function() { root.logoutSystem() } }
                        ]
                        
                        Rectangle {
                            width: (parent.width - 30) / 4
                            height: parent.height
                            color: "transparent"
                            
                            Column {
                                anchors.centerIn: parent
                                spacing: 6
                                
                                Rectangle {
                                    width: 36
                                    height: 36
                                    radius: (sharedData && sharedData.quickshellBorderRadius) ? sharedData.quickshellBorderRadius : 0
                                    color: actionMouse.containsMouse ? 
                                        ((sharedData && sharedData.colorSecondary) ? sharedData.colorSecondary : "#141414") : 
                                        "transparent"
                                    border.width: 1
                                    border.color: (sharedData && sharedData.colorSecondary) ? sharedData.colorSecondary : "#444"
                                    
                                    Text {
                                        text: modelData.icon
                                        font.pixelSize: 16
                                        anchors.centerIn: parent
                                        color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff"
                                    }
                                }
                                
                                Text {
                                    text: modelData.label
                                    font.pixelSize: 8
                                    font.family: "sans-serif"
                                    font.weight: Font.Bold
                                    color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#000000"
                                    opacity: 0.6
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }
                            }
                            
                            MouseArea {
                                id: actionMouse
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                hoverEnabled: true
                                onClicked: modelData.action()
                            }
                        }
                    }
                }
            }
        }
        
        // Main Content Row
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 5
            
            // Left Column: Distro info & Calendar
            ColumnLayout {
                Layout.preferredWidth: parent.width * 0.45
                Layout.fillHeight: true
                spacing: 5
                
                // Distro & System Info Card
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 120
                    radius: (sharedData && sharedData.quickshellBorderRadius) ? sharedData.quickshellBorderRadius : 0
                    color: (sharedData && sharedData.colorPrimary) ? sharedData.colorPrimary : "#1a1a1a"
                    
                    Column {
                        anchors.fill: parent
                        anchors.margins: 15
                        spacing: 8
                        
                        Row {
                            spacing: 12
                            Text {
                                text: "󰣇"
                                font.pixelSize: 32
                                color: (sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#00ff41"
                            }
                            Column {
                                spacing: 2
                                Text {
                                    text: root.distroName.toUpperCase()
                                    font.pixelSize: 14
                                    font.family: "sans-serif"
                                    font.weight: Font.Black
                                    color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#000000"
                                }
                                Text {
                                    text: root.windowManager.toUpperCase()
                                    font.pixelSize: 10
                                    font.family: "sans-serif"
                                    font.weight: Font.Bold
                                    color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#000000"
                                    opacity: 0.6
                                }
                            }
                        }
                        
                        Rectangle {
                            width: parent.width
                            height: 1
                            color: (sharedData && sharedData.colorSecondary) ? sharedData.colorSecondary : "#2a2a2a"
                        }
                        
                        Row {
                            width: parent.width
                            spacing: 15
                            Text {
                                text: root.uptimeDisplayText
                                font.pixelSize: 10
                                font.family: "sans-serif"
                                font.weight: Font.Bold
                                color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#000000"
                            }
                            Text {
                                text: "󰃭 " + new Date().toLocaleDateString(Qt.locale(), "ddd, MMM d")
                                font.pixelSize: 10
                                font.family: "sans-serif"
                                font.weight: Font.Bold
                                color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#000000"
                            }
                        }
                    }
                }
                
                // Calendar Card
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: (sharedData && sharedData.quickshellBorderRadius) ? sharedData.quickshellBorderRadius : 0
                    color: (sharedData && sharedData.colorPrimary) ? sharedData.colorPrimary : "#1a1a1a"
                    
                    Column {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 8
                        
                        Text {
                            text: "󰃭 " + new Date().toLocaleDateString(Qt.locale(), "MMMM yyyy").toUpperCase()
                            font.pixelSize: 10
                            font.family: "sans-serif"
                            font.weight: Font.Black
                            color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#000000"
                            opacity: 0.7
                        }
                        
                        GridLayout {
                            width: parent.width
                            columns: 7
                            rowSpacing: 2
                            columnSpacing: 2
                            
                            Repeater {
                                model: ["M", "T", "W", "T", "F", "S", "S"]
                                Text {
                                    text: modelData
                                    Layout.fillWidth: true
                                    horizontalAlignment: Text.AlignHCenter
                                    font.pixelSize: 8
                                    font.weight: Font.Bold
                                    color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#000000"
                                    opacity: 0.4
                                }
                            }
                            
                            Repeater {
                                model: root.calendarDays
                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 24
                                    color: modelData.isToday ? 
                                        ((sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#00ff41") : 
                                        "transparent"
                                    radius: (sharedData && sharedData.quickshellBorderRadius) ? sharedData.quickshellBorderRadius : 0
                                    
                                    Text {
                                        text: modelData.day
                                        font.pixelSize: 9
                                        font.weight: modelData.isToday ? Font.Black : (modelData.isCurrentMonth ? Font.Bold : Font.Normal)
                                        color: modelData.isToday ? 
                                            ((sharedData && sharedData.colorBackground) ? sharedData.colorBackground : "#000000") : 
                                            (modelData.isCurrentMonth ?
                                                 ((sharedData && sharedData.colorText) ? sharedData.colorText : "#000000") :
                                                 ((sharedData && sharedData.colorText) ? Qt.lighter(sharedData.colorText, 1.5) : "#888888"))
                                        anchors.centerIn: parent
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            // Right Column: Resource Monitor & Performance/Activity
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 5
                
                // Stack of performance and activity
                StackLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    currentIndex: (sharedData && sharedData.dashboardRightTab) ? sharedData.dashboardRightTab : 0
                    
                    // PERFORMANCE PAGE
                    ColumnLayout {
                        spacing: 5
                        
                        // Resource 1 Card - Swiss Style
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.preferredHeight: 190
                            Layout.minimumHeight: 165
                            radius: (sharedData && sharedData.quickshellBorderRadius) ? sharedData.quickshellBorderRadius : 0
                            color: "transparent"
                            
                            property string resource: (sharedData && sharedData.dashboardResource1) ? sharedData.dashboardResource1 : "cpu"
                            
                            opacity: showProgress > 0.01 ? 1.0 : 0.0
                            scale: showProgress > 0.01 ? 1.0 : 0.9
                            
                            // Transform removed to simplify separate component for now, added back if needed
                            
                            Column {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 5
                                
                                Row {
                                    spacing: 5
                                    Text {
                                        text: root.getResourceIcon(parent.parent.resource)
                                        font.pixelSize: 12
                                        color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff"
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                    Text {
                                        text: root.getResourceLabel(parent.parent.resource).toUpperCase()
                                        font.pixelSize: 11
                                        font.family: "sans-serif"
                                        font.weight: Font.Bold
                                        color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#000000"
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                    Text {
                                        text: root.getResourceValueText(parent.parent.resource)
                                        font.pixelSize: 11
                                        font.family: "sans-serif"
                                        font.weight: Font.Bold
                                        color: (sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#00ff41"
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                    Text {
                                        text: root.getResourceSubText(parent.parent.resource)
                                        font.pixelSize: 10
                                        font.family: "sans-serif"
                                        color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#000000" 
                                        anchors.verticalCenter: parent.verticalCenter
                                        visible: text !== ""
                                    }
                                }
                                
                                Canvas {
                                    id: res1Chart
                                    width: parent.width
                                    height: 128
                                    
                                    onPaint: {
                                        var ctx = getContext("2d")
                                        ctx.clearRect(0, 0, width, height)
                                        
                                        var hist = root.getResourceHistory(parent.parent.resource)
                                        if (!hist || hist.length < 2) return
                                        
                                        var chartWidth = width
                                        var chartHeight = height
                                        var maxValue = 100
                                        if (parent.parent.resource === "network") {
                                            var max = 1.0 
                                            for(var k=0; k<hist.length; k++) if(hist[k] > max) max = hist[k]
                                            maxValue = max * 1.2
                                        }
                                        
                                        // Draw background
                                        ctx.fillStyle = (sharedData && sharedData.colorSecondary) ? sharedData.colorSecondary : "#141414"
                                        ctx.fillRect(0, 0, chartWidth, chartHeight)
                                        
                                        // Draw grid lines
                                        ctx.strokeStyle = (sharedData && sharedData.colorPrimary) ? sharedData.colorPrimary : "#2a2a2a"
                                        ctx.lineWidth = 1
                                        for (var i = 0; i <= 4; i++) {
                                            var y = (chartHeight / 4) * i
                                            ctx.beginPath()
                                            ctx.moveTo(0, y)
                                            ctx.lineTo(chartWidth, y)
                                            ctx.stroke()
                                        }
                                        
                                        // Draw graph
                                        ctx.strokeStyle = (sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff"
                                        ctx.lineWidth = 2
                                        ctx.beginPath()
                                        
                                        var stepX = chartWidth / (Math.max(hist.length, 2) - 1)
                                        function getY(val) { return chartHeight - (val / maxValue) * chartHeight }
                                        
                                        ctx.moveTo(0, getY(hist[0]))
                                        for (var j = 1; j < hist.length - 2; j++) {
                                            var xc = (j * stepX + (j + 1) * stepX) / 2
                                            var yc = (getY(hist[j]) + getY(hist[j+1])) / 2
                                            ctx.quadraticCurveTo(j * stepX, getY(hist[j]), xc, yc)
                                        }
                                        if (hist.length > 2) {
                                            var lastIdx = hist.length - 2
                                            ctx.quadraticCurveTo(lastIdx * stepX, getY(hist[lastIdx]), (lastIdx+1) * stepX, getY(hist[lastIdx+1]))
                                        } else if (hist.length === 2) {
                                            ctx.lineTo(stepX, getY(hist[1]))
                                        }
                                        
                                        ctx.stroke()
                                        
                                        ctx.lineTo(chartWidth, chartHeight)
                                        ctx.lineTo(0, chartHeight)
                                        ctx.closePath()
                                        ctx.fillStyle = (sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff"
                                        ctx.globalAlpha = 0.15
                                        ctx.fill()
                                        ctx.globalAlpha = 1.0
                                    }
                                    
                                    Connections {
                                        target: root
                                        function onPerfUpdated() {
                                            res1Chart.requestPaint()
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Resource 2 Card - Swiss Style
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.preferredHeight: 190
                            Layout.minimumHeight: 165
                            radius: (sharedData && sharedData.quickshellBorderRadius) ? sharedData.quickshellBorderRadius : 0
                            color: "transparent"
                            
                            property string resource: (sharedData && sharedData.dashboardResource2) ? sharedData.dashboardResource2 : "ram"
                            
                            opacity: showProgress > 0.01 ? 1.0 : 0.0
                            scale: showProgress > 0.01 ? 1.0 : 0.9
                            
                            Column {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 5
                                
                                Row {
                                    spacing: 5
                                    Text {
                                        text: root.getResourceIcon(parent.parent.resource)
                                        font.pixelSize: 12
                                        color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff"
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                    Text {
                                        text: root.getResourceLabel(parent.parent.resource).toUpperCase()
                                        font.pixelSize: 11
                                        font.family: "sans-serif"
                                        font.weight: Font.Bold
                                        color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#000000"
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                    Text {
                                        text: root.getResourceValueText(parent.parent.resource)
                                        font.pixelSize: 11
                                        font.family: "sans-serif"
                                        font.weight: Font.Bold
                                        color: (sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#00ff41"
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                    Text {
                                        text: root.getResourceSubText(parent.parent.resource)
                                        font.pixelSize: 10
                                        font.family: "sans-serif"
                                        color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#000000"
                                        anchors.verticalCenter: parent.verticalCenter
                                        visible: text !== ""
                                    }
                                }
                                
                                Canvas {
                                    id: res2Chart
                                    width: parent.width
                                    height: 128
                                    
                                    onPaint: {
                                        var ctx = getContext("2d")
                                        ctx.clearRect(0, 0, width, height)
                                        
                                        var hist = root.getResourceHistory(parent.parent.resource)
                                        if (!hist || hist.length < 2) return
                                        
                                        var chartWidth = width
                                        var chartHeight = height
                                        var maxValue = 100
                                        if (parent.parent.resource === "network") {
                                            var max = 1.0 
                                            for(var k=0; k<hist.length; k++) if(hist[k] > max) max = hist[k]
                                            maxValue = max * 1.2
                                        }
                                        
                                        // Draw background
                                        ctx.fillStyle = (sharedData && sharedData.colorSecondary) ? sharedData.colorSecondary : "#141414"
                                        ctx.fillRect(0, 0, chartWidth, chartHeight)
                                        
                                        // Draw grid lines
                                        ctx.strokeStyle = (sharedData && sharedData.colorPrimary) ? sharedData.colorPrimary : "#2a2a2a"
                                        ctx.lineWidth = 1
                                        for (var i = 0; i <= 4; i++) {
                                            var y = (chartHeight / 4) * i
                                            ctx.beginPath()
                                            ctx.moveTo(0, y)
                                            ctx.lineTo(chartWidth, y)
                                            ctx.stroke()
                                        }
                                        
                                        // Draw graph
                                        ctx.strokeStyle = (sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff"
                                        ctx.lineWidth = 2
                                        ctx.beginPath()
                                        
                                        var stepX = chartWidth / (Math.max(hist.length, 2) - 1)
                                        function getY(val) { return chartHeight - (val / maxValue) * chartHeight }
                                        
                                        ctx.moveTo(0, getY(hist[0]))
                                        for (var j = 1; j < hist.length - 2; j++) {
                                            var xc = (j * stepX + (j + 1) * stepX) / 2
                                            var yc = (getY(hist[j]) + getY(hist[j+1])) / 2
                                            ctx.quadraticCurveTo(j * stepX, getY(hist[j]), xc, yc)
                                        }
                                        if (hist.length > 2) {
                                            var lastIdx = hist.length - 2
                                            ctx.quadraticCurveTo(lastIdx * stepX, getY(hist[lastIdx]), (lastIdx+1) * stepX, getY(hist[lastIdx+1]))
                                        } else if (hist.length === 2) {
                                            ctx.lineTo(stepX, getY(hist[1]))
                                        }
                                        
                                        ctx.stroke()
                                        
                                        ctx.lineTo(chartWidth, chartHeight)
                                        ctx.lineTo(0, chartHeight)
                                        ctx.closePath()
                                        ctx.fillStyle = (sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff"
                                        ctx.globalAlpha = 0.15
                                        ctx.fill()
                                        ctx.globalAlpha = 1.0
                                    }
                                    
                                    Connections {
                                        target: root
                                        function onPerfUpdated() {
                                            res2Chart.requestPaint()
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Media Player Card - Swiss Style
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.preferredHeight: 190
                            Layout.minimumHeight: 165
                            radius: (sharedData && sharedData.quickshellBorderRadius) ? sharedData.quickshellBorderRadius : 0
                            color: "transparent"
                            
                            opacity: showProgress > 0.01 ? 1.0 : 0.0
                            scale: showProgress > 0.01 ? 1.0 : 0.9
                            
                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 16
                                spacing: 16
                                
                                // Cover art
                                Rectangle {
                                    Layout.preferredWidth: 100
                                    Layout.preferredHeight: 100
                                    Layout.minimumWidth: 100
                                    Layout.minimumHeight: 100
                                    Layout.alignment: Qt.AlignVCenter
                                    radius: (sharedData && sharedData.quickshellBorderRadius) ? sharedData.quickshellBorderRadius : 0
                                    color: (sharedData && sharedData.colorSecondary) ? sharedData.colorSecondary : "#141414"
                                    
                                    Image {
                                        id: mediaAlbumArtCard
                                        anchors.fill: parent
                                        anchors.margins: 1
                                        fillMode: Image.PreserveAspectCrop
                                        source: root.mpArt ? root.mpArt : ""
                                        asynchronous: true
                                        cache: false
                                        opacity: source ? 1.0 : 0.0
                                        
                                        Behavior on opacity {
                                            NumberAnimation {
                                                duration: 400
                                                easing.type: Easing.OutQuart
                                            }
                                        }
                                    }
                                    
                                    Text {
                                        text: "󰎆"
                                        font.pixelSize: 40
                                        anchors.centerIn: parent
                                        visible: !root.mpArt
                                        color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff"
                                    }
                                }
                                
                                // Track info + kontrolki
                                Column {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    Layout.alignment: Qt.AlignVCenter
                                    spacing: 10
                                    
                                    Item { width: 1; height: 12 }
                                    
                                    Column {
                                        width: parent.width - 20
                                        spacing: 2
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        
                                        Text {
                                            text: (root.mpTitle ? root.mpTitle : "NOTHING PLAYING").toUpperCase()
                                            font.pixelSize: 12
                                            font.family: "sans-serif"
                                            font.weight: Font.Black
                                            color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#000000"
                                            elide: Text.ElideRight
                                            width: parent.width
                                            horizontalAlignment: Text.AlignHCenter
                                        }
                                        
                                        Text {
                                            text: (root.mpArtist ? root.mpArtist : "—").toUpperCase()
                                            font.pixelSize: 10
                                            font.family: "sans-serif"
                                            font.weight: Font.Bold
                                            color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#000000"
                                            opacity: 0.6
                                            elide: Text.ElideRight
                                            width: parent.width
                                            horizontalAlignment: Text.AlignHCenter
                                        }

                                        Item { width: 1; height: 4 }

                                        // Progress Bar
                                        Rectangle {
                                            width: parent.width
                                            height: 2
                                            color: (sharedData && sharedData.colorSecondary) ? sharedData.colorSecondary : "#1a1a1a"
                                            
                                            Rectangle {
                                                width: (root.mpLength > 0 ? (parent.width * (root.mpPosition / root.mpLength)) : 0)
                                                height: parent.height
                                                color: (sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff"
                                                
                                                Behavior on width { NumberAnimation { duration: 200 } }
                                            }
                                        }
                                    }
                                    
                                    // Kontrolki prev | play | next
                                    Row {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        spacing: 2 
                                        
                                        Rectangle {
                                            width: 34
                                            height: 34
                                            radius: (sharedData && sharedData.quickshellBorderRadius) ? sharedData.quickshellBorderRadius : 0
                                            color: (sharedData && sharedData.colorSecondary) ? sharedData.colorSecondary : "#1a1a1a"
                                            opacity: prevAreaCard.pressed ? 0.7 : (prevAreaCard.containsMouse ? 0.9 : 1.0)
                                            scale: prevAreaCard.pressed ? 0.90 : (prevAreaCard.containsMouse ? 1.05 : 1.0)
                                            z: prevAreaCard.containsMouse ? 2 : 1
                                            
                                            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
                                            Behavior on opacity { NumberAnimation { duration: 150 } }
                                            
                                            Text {
                                                text: "󰒮"
                                                font.pixelSize: 12
                                                anchors.centerIn: parent
                                                color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff"
                                            }
                                            
                                            MouseArea {
                                                id: prevAreaCard
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                hoverEnabled: true
                                                onClicked: root.playerPrev()
                                            }
                                        }
                                        
                                        Rectangle {
                                            width: 50
                                            height: 34
                                            radius: (sharedData && sharedData.quickshellBorderRadius) ? sharedData.quickshellBorderRadius : 0
                                            color: (sharedData && sharedData.colorSecondary) ? sharedData.colorSecondary : "#1a1a1a"
                                            opacity: playAreaCard.pressed ? 0.7 : (playAreaCard.containsMouse ? 0.9 : 1.0)
                                            scale: playAreaCard.pressed ? 0.90 : (playAreaCard.containsMouse ? 1.05 : 1.0)
                                            z: playAreaCard.containsMouse ? 2 : 1
                                            
                                            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
                                            Behavior on opacity { NumberAnimation { duration: 150 } }
                                            
                                            Text {
                                                text: root.mpPlaying ? "󰏤" : "󰐊"
                                                font.pixelSize: 14
                                                anchors.centerIn: parent
                                                color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff"
                                            }
                                            
                                            MouseArea {
                                                id: playAreaCard
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                hoverEnabled: true
                                                onClicked: root.playerPlayPause()
                                            }
                                        }
                                        
                                        Rectangle {
                                            width: 34
                                            height: 34
                                            radius: (sharedData && sharedData.quickshellBorderRadius) ? sharedData.quickshellBorderRadius : 0
                                            color: (sharedData && sharedData.colorSecondary) ? sharedData.colorSecondary : "#1a1a1a"
                                            opacity: nextAreaCard.pressed ? 0.7 : (nextAreaCard.containsMouse ? 0.9 : 1.0)
                                            scale: nextAreaCard.pressed ? 0.90 : (nextAreaCard.containsMouse ? 1.05 : 1.0)
                                            z: nextAreaCard.containsMouse ? 2 : 1
                                            
                                            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
                                            Behavior on opacity { NumberAnimation { duration: 150 } }
                                            
                                            Text {
                                                text: "󰒭"
                                                font.pixelSize: 12
                                                anchors.centerIn: parent
                                                color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff"
                                            }
                                            
                                            MouseArea {
                                                id: nextAreaCard
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                hoverEnabled: true
                                                onClicked: root.playerNext()
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
}

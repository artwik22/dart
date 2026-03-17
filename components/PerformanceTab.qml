import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "."

Item {
    id: performanceTabRoot
    property var sharedData: null
    property int currentTab: 0

    // Properties passed from parent or managed here
    property int cpuUsageValue: 0
    property int ramUsageValue: 0
    property int gpuUsageValue: 0
    property int ramTotalGB: 0
    property int cpuTempValue: 0
    property int gpuTempValue: 0
    property string uptimeString: ""
    property real networkRxMBs: 0
    property real networkTxMBs: 0
    property var diskUsageModel: []
    property var topProcessesModel: []
    
    // Signals/Callbacks
    signal perfUpdateRequested()
    
    // Function to get history (provided by parent or we could manage it here)
    property var getResourceHistory: function(res) { return [] }

    anchors.fill: parent
    visible: currentTab === 3
    opacity: currentTab === 3 ? 1.0 : 0.0
    x: currentTab === 3 ? 0 : (currentTab < 3 ? -parent.width * 0.3 : parent.width * 0.3)
    scale: currentTab === 3 ? 1.0 : 0.95
    
    Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
    Behavior on x { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
    Behavior on scale { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }

    onVisibleChanged: {
        if (visible) {
            perfUpdateRequested()
        }
    }
    
    z: 5

    ColumnLayout {
        id: performanceTabContent
        anchors.fill: parent
        anchors.margins: 24
        spacing: 16

        // --- SWISS HEADER ---
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0
            
            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "PERFORMANCE"
                    font.pixelSize: 32
                    font.weight: Font.Black
                    font.family: "Inter, Roboto, sans-serif"
                    color: (sharedData && sharedData.colorText) || "#ffffff"
                    font.letterSpacing: -1
                }
                Item { Layout.fillWidth: true }
                Rectangle {
                    Layout.preferredWidth: 32
                    Layout.preferredHeight: 32
                    radius: 8
                    color: Qt.rgba(1, 1, 1, 0.05)
                    Text {
                        anchors.centerIn: parent
                        text: "󰓅"
                        font.pixelSize: 18
                        color: (sharedData && sharedData.colorAccent) || "#00ff41"
                    }
                }
            }
            
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 2
                color: (sharedData && sharedData.colorAccent) || "#00ff41"
                Layout.topMargin: 4
            }
            
            RowLayout {
                Layout.topMargin: 8
                spacing: 12

                Item { Layout.fillWidth: true }
                Text {
                    text: "Up: " + uptimeString
                    font.pixelSize: 12
                    font.weight: Font.Medium
                    color: Qt.alpha((sharedData && sharedData.colorText) || "#ffffff", 0.4)
                }
            }
        }

        // --- MAIN METRICS GRID (CPU, RAM, GPU, DISK) ---
        GridLayout {
            Layout.fillWidth: true
            columns: 2
            columnSpacing: 12
            rowSpacing: 12

            // CPU Metric Card
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 110
                radius: (sharedData && sharedData.quickshellBorderRadius !== undefined) ? sharedData.quickshellBorderRadius : 12
                color: (sharedData && sharedData.colorSecondary) || "#141414"
                border.width: 1
                border.color: Qt.rgba(1,1,1,0.05)

                ColumnLayout {
                    anchors.fill: parent; anchors.margins: 14; spacing: 0
                    RowLayout {
                        spacing: 6
                        Text { text: "󰻠"; font.pixelSize: 12; color: (sharedData && sharedData.colorAccent) || "#00ff41" }
                        Text { text: "CPU"; font.pixelSize: 11; font.weight: Font.Black; color: Qt.alpha((sharedData && sharedData.colorText) || "#ffffff", 0.6) }
                    }
                    RowLayout {
                        Layout.topMargin: 4
                        Text { 
                            text: cpuUsageValue + "%"
                            font.pixelSize: 28; font.weight: Font.Black
                            color: (sharedData && sharedData.colorText) || "#ffffff" 
                        }
                        Item { Layout.fillWidth: true }
                        Text { 
                            text: cpuTempValue > 0 ? cpuTempValue + "°C" : "--"
                            font.pixelSize: 14; font.weight: Font.Bold
                            color: cpuTempValue > 80 ? "#ff4444" : ((sharedData && sharedData.colorAccent) || "#00ff41") 
                        }
                    }
                    Item { Layout.fillHeight: true }
                    Canvas {
                        id: cpuChart
                        Layout.fillWidth: true; Layout.preferredHeight: 35
                        onPaint: {
                            var ctx = getContext("2d"); ctx.reset();
                            var hist = performanceTabRoot.getResourceHistory("cpu");
                            if (!hist || hist.length < 2) return;
                            var w = width; var h = height; var step = w / (hist.length - 1);
                            var color = (sharedData && sharedData.colorAccent) || "#00ff41";
                            ctx.lineJoin = "round"; ctx.lineCap = "round";
                            
                            var grad = ctx.createLinearGradient(0, 0, 0, h);
                            grad.addColorStop(0, Qt.alpha(color, 0.3));
                            grad.addColorStop(1, "transparent");
                            ctx.fillStyle = grad;
                            ctx.beginPath(); ctx.moveTo(0, h);
                            for(var i=0; i<hist.length; i++) ctx.lineTo(i*step, h - (hist[i]/100)*h);
                            ctx.lineTo(w, h); ctx.closePath(); ctx.fill();
                            
                            ctx.beginPath();
                            for(var j=0; j<hist.length; j++) ctx.lineTo(j*step, h - (hist[j]/100)*h);
                            ctx.strokeStyle = color; ctx.lineWidth = 2.5; ctx.stroke();
                        }
                    }
                }
            }

            // RAM Metric Card
            Rectangle {
                Layout.fillWidth: true; Layout.preferredHeight: 110
                radius: (sharedData && sharedData.quickshellBorderRadius !== undefined) ? sharedData.quickshellBorderRadius : 12
                color: (sharedData && sharedData.colorSecondary) || "#141414"
                border.width: 1
                border.color: Qt.rgba(1,1,1,0.05)

                ColumnLayout {
                    anchors.fill: parent; anchors.margins: 14; spacing: 0
                    RowLayout {
                        spacing: 6
                        Text { text: "󰍛"; font.pixelSize: 12; color: (sharedData && sharedData.colorAccent) || "#00ff41" }
                        Text { text: "RAM"; font.pixelSize: 11; font.weight: Font.Black; color: Qt.alpha((sharedData && sharedData.colorText) || "#ffffff", 0.6) }
                    }
                    RowLayout {
                        Layout.topMargin: 4
                        Text { 
                            text: ramUsageValue + "%"
                            font.pixelSize: 28; font.weight: Font.Black
                            color: (sharedData && sharedData.colorText) || "#ffffff" 
                        }
                        Item { Layout.fillWidth: true }
                        Text { 
                            text: ramTotalGB + "G"
                            font.pixelSize: 14; font.weight: Font.Bold
                            color: Qt.alpha((sharedData && sharedData.colorText) || "#ffffff", 0.5) 
                        }
                    }
                    Item { Layout.fillHeight: true }
                    Canvas {
                        id: ramChart
                        Layout.fillWidth: true; Layout.preferredHeight: 35
                        onPaint: {
                            var ctx = getContext("2d"); ctx.reset();
                            var hist = performanceTabRoot.getResourceHistory("ram");
                            if (!hist || hist.length < 2) return;
                            var w = width; var h = height; var step = w / (hist.length - 1);
                            var color = (sharedData && sharedData.colorAccent) || "#00ff41";
                            ctx.lineJoin = "round"; ctx.lineCap = "round";
                            
                            var grad = ctx.createLinearGradient(0, 0, 0, h);
                            grad.addColorStop(0, Qt.alpha(color, 0.3));
                            grad.addColorStop(1, "transparent");
                            ctx.fillStyle = grad;
                            ctx.beginPath(); ctx.moveTo(0, h);
                            for(var i=0; i<hist.length; i++) ctx.lineTo(i*step, h - (hist[i]/100)*h);
                            ctx.lineTo(w, h); ctx.closePath(); ctx.fill();
                            
                            ctx.beginPath();
                            for(var j=0; j<hist.length; j++) ctx.lineTo(j*step, h - (hist[j]/100)*h);
                            ctx.strokeStyle = color; ctx.lineWidth = 2.5; ctx.stroke();
                        }
                    }
                }
            }

            // GPU Metric Card
            Rectangle {
                Layout.fillWidth: true; Layout.preferredHeight: 110
                radius: (sharedData && sharedData.quickshellBorderRadius !== undefined) ? sharedData.quickshellBorderRadius : 12
                color: (sharedData && sharedData.colorSecondary) || "#141414"
                border.width: 1
                border.color: Qt.rgba(1,1,1,0.05)

                ColumnLayout {
                    anchors.fill: parent; anchors.margins: 14; spacing: 0
                    RowLayout {
                        spacing: 6
                        Text { text: "󰢮"; font.pixelSize: 12; color: (sharedData && sharedData.colorAccent) || "#00ff41" }
                        Text { text: "GPU"; font.pixelSize: 11; font.weight: Font.Black; color: Qt.alpha((sharedData && sharedData.colorText) || "#ffffff", 0.6) }
                    }
                    RowLayout {
                        Layout.topMargin: 4
                        Text { 
                            text: gpuUsageValue + "%"
                            font.pixelSize: 28; font.weight: Font.Black
                            color: (sharedData && sharedData.colorText) || "#ffffff" 
                        }
                        Item { Layout.fillWidth: true }
                        Text { 
                            text: gpuTempValue > 0 ? gpuTempValue + "°C" : "--"
                            font.pixelSize: 14; font.weight: Font.Bold
                            color: gpuTempValue > 80 ? "#ff4444" : ((sharedData && sharedData.colorAccent) || "#00ff41") 
                        }
                    }
                    Item { Layout.fillHeight: true }
                    Canvas {
                        id: gpuChart
                        Layout.fillWidth: true; Layout.preferredHeight: 35
                        onPaint: {
                            var ctx = getContext("2d"); ctx.reset();
                            var hist = performanceTabRoot.getResourceHistory("gpu");
                            if (!hist || hist.length < 2) return;
                            var w = width; var h = height; var step = w / (hist.length - 1);
                            var color = (sharedData && sharedData.colorAccent) || "#00ff41";
                            ctx.lineJoin = "round"; ctx.lineCap = "round";
                            
                            var grad = ctx.createLinearGradient(0, 0, 0, h);
                            grad.addColorStop(0, Qt.alpha(color, 0.3));
                            grad.addColorStop(1, "transparent");
                            ctx.fillStyle = grad;
                            ctx.beginPath(); ctx.moveTo(0, h);
                            for(var i=0; i<hist.length; i++) ctx.lineTo(i*step, h - (hist[i]/100)*h);
                            ctx.lineTo(w, h); ctx.closePath(); ctx.fill();
                            
                            ctx.beginPath();
                            for(var j=0; j<hist.length; j++) ctx.lineTo(j*step, h - (hist[j]/100)*h);
                            ctx.strokeStyle = color; ctx.lineWidth = 2.5; ctx.stroke();
                        }
                    }
                }
            }

            // DISK Metric Card
            Rectangle {
                Layout.fillWidth: true; Layout.preferredHeight: 110
                radius: (sharedData && sharedData.quickshellBorderRadius !== undefined) ? sharedData.quickshellBorderRadius : 12
                color: (sharedData && sharedData.colorSecondary) || "#141414"
                border.width: 1
                border.color: Qt.rgba(1,1,1,0.05)

                ColumnLayout {
                    anchors.fill: parent; anchors.margins: 14; spacing: 8
                    RowLayout {
                        spacing: 6; Layout.fillWidth: true
                        Text { text: "󰋊"; font.pixelSize: 12; color: (sharedData && sharedData.colorAccent) || "#00ff41" }
                        Text { text: "DISK"; font.pixelSize: 11; font.weight: Font.Black; color: Qt.alpha((sharedData && sharedData.colorText) || "#ffffff", 0.6) }
                    }
                    Column {
                        Layout.fillWidth: true; spacing: 8
                        Repeater {
                            model: diskUsageModel
                            delegate: Column {
                                width: parent.width; spacing: 4; visible: index < 2
                                RowLayout {
                                    Text { text: modelData.mount.toUpperCase(); font.pixelSize: 10; font.weight: Font.Bold; color: (sharedData && sharedData.colorText) || "#ffffff"; Layout.fillWidth: true }
                                    Text { text: modelData.usage + "%"; font.pixelSize: 10; font.weight: Font.Black; color: (sharedData && sharedData.colorAccent) || "#00ff41" }
                                }
                                Rectangle {
                                    width: parent.width; height: 6; color: Qt.rgba(1,1,1,0.08); radius: 3
                                    Rectangle { height: parent.height; width: parent.width * (modelData.usage / 100); color: (sharedData && sharedData.colorAccent) || "#00ff41"; radius: 3 }
                                }
                            }
                        }
                    }
                    Item { Layout.fillHeight: true }
                }
            }
        }

        // --- NETWORK CARD ---
        Rectangle {
            Layout.fillWidth: true; Layout.preferredHeight: 70
            radius: (sharedData && sharedData.quickshellBorderRadius !== undefined) ? sharedData.quickshellBorderRadius : 12
            color: (sharedData && sharedData.colorSecondary) || "#141414"
            border.width: 1; border.color: Qt.rgba(1,1,1,0.05)
            RowLayout {
                anchors.fill: parent; anchors.margins: 14; spacing: 16
                ColumnLayout {
                    spacing: 4
                    RowLayout {
                        spacing: 6
                        Text { text: "󰈀"; font.pixelSize: 12; color: (sharedData && sharedData.colorAccent) || "#00ff41" }
                        Text { text: "NETWORK"; font.pixelSize: 11; font.weight: Font.Black; color: Qt.alpha((sharedData && sharedData.colorText) || "#ffffff", 0.6) }
                    }
                    RowLayout {
                        spacing: 12
                        Text { 
                            text: networkRxMBs < 0.1 ? "↓ " + (networkRxMBs * 1024).toFixed(0) + " KB/s" : "↓ " + networkRxMBs.toFixed(1) + " MB/s"
                            font.pixelSize: 16; font.weight: Font.Black; color: (sharedData && sharedData.colorText) || "#ffffff" 
                        }
                        Text { 
                            text: networkTxMBs < 0.1 ? "↑ " + (networkTxMBs * 1024).toFixed(0) + " KB/s" : "↑ " + networkTxMBs.toFixed(1) + " MB/s"
                            font.pixelSize: 16; font.weight: Font.Black; color: Qt.alpha((sharedData && sharedData.colorText) || "#ffffff", 0.6) 
                        }
                    }
                }
                Item { Layout.fillWidth: true; Layout.fillHeight: true; 
                    Canvas {
                        id: netChart; anchors.fill: parent; anchors.topMargin: 4; anchors.bottomMargin: 4
                        onPaint: {
                            var ctx = getContext("2d"); ctx.reset();
                            var hist = performanceTabRoot.getResourceHistory("network");
                            if (!hist || hist.length < 2) return;
                            var w = width; var h = height; var step = w / (hist.length - 1);
                            var color = (sharedData && sharedData.colorAccent) || "#00ff41";
                            ctx.lineJoin = "round"; ctx.lineCap = "round";
                            var grad = ctx.createLinearGradient(0, 0, 0, h);
                            grad.addColorStop(0, Qt.alpha(color, 0.3)); grad.addColorStop(1, "transparent");
                            ctx.fillStyle = grad; ctx.beginPath(); ctx.moveTo(0, h);
                            for(var i=0; i<hist.length; i++) ctx.lineTo(i*step, h - (Math.min(hist[i], 20)/20)*h);
                            ctx.lineTo(w, h); ctx.closePath(); ctx.fill();
                            ctx.beginPath();
                            for(var j=0; j<hist.length; j++) ctx.lineTo(j*step, h - (Math.min(hist[j], 20)/20)*h);
                            ctx.strokeStyle = color; ctx.lineWidth = 2.5; ctx.stroke();
                        }
                    }
                }
            }
        }

        // --- PROCESSES ---
        Rectangle {
            Layout.fillWidth: true; Layout.fillHeight: true;
            radius: (sharedData && sharedData.quickshellBorderRadius !== undefined) ? sharedData.quickshellBorderRadius : 12
            color: (sharedData && sharedData.colorSecondary) || "#141414"
            border.width: 1; border.color: Qt.rgba(1,1,1,0.05)
            ColumnLayout {
                anchors.fill: parent; anchors.margins: 14; spacing: 10
                RowLayout {
                    Layout.fillWidth: true
                    RowLayout {
                        spacing: 6
                        Text { text: "󰒢"; font.pixelSize: 12; color: (sharedData && sharedData.colorAccent) || "#00ff41" }
                        Text { text: "TOP PROCESSES"; font.pixelSize: 11; font.weight: Font.Black; color: Qt.alpha((sharedData && sharedData.colorText) || "#ffffff", 0.6) }
                    }
                    Item { Layout.fillWidth: true }
                    Text { text: "MEM"; font.pixelSize: 9; font.weight: Font.Bold; color: Qt.alpha((sharedData && sharedData.colorText) || "#ffffff", 0.3) }
                    Text { text: "CPU"; font.pixelSize: 9; font.weight: Font.Bold; color: Qt.alpha((sharedData && sharedData.colorText) || "#ffffff", 0.3); Layout.preferredWidth: 35; horizontalAlignment: Text.AlignRight }
                }
                Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: Qt.rgba(1, 1, 1, 0.05) }
                ListView {
                    id: topProcessesList; reuseItems: true; Layout.fillWidth: true; Layout.fillHeight: true;
                    model: topProcessesModel; interactive: false; clip: true; spacing: 4
                    delegate: Rectangle {
                        width: parent.width; height: 28; radius: 6
                        color: index % 2 === 0 ? Qt.rgba(1,1,1,0.02) : "transparent"
                        RowLayout {
                            anchors.fill: parent; anchors.leftMargin: 8; anchors.rightMargin: 8; spacing: 8
                            Text { text: modelData.name.toUpperCase(); font.pixelSize: 11; font.weight: Font.Bold; color: (sharedData && sharedData.colorText) || "#ffffff"; elide: Text.ElideRight; Layout.fillWidth: true }
                            Text { text: modelData.mem + "%"; font.pixelSize: 11; font.weight: Font.Medium; color: Qt.alpha((sharedData && sharedData.colorText) || "#ffffff", 0.6) }
                            Text { 
                                text: parseFloat(modelData.cpu).toFixed(1) + "%"; font.pixelSize: 11; font.weight: Font.Black
                                color: parseFloat(modelData.cpu) > 20 ? ((sharedData && sharedData.colorAccent) || "#ff4444") : ((sharedData && sharedData.colorText) || "#ffffff")
                                Layout.preferredWidth: 35; horizontalAlignment: Text.AlignRight
                            }
                        }
                    }
                }
            }
        }
    }
    
    // Public update functions for charts
    function requestChartsPaint() {
        cpuChart.requestPaint()
        ramChart.requestPaint()
        gpuChart.requestPaint()
        netChart.requestPaint()
    }
}

import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

PanelWindow {
    id: root
    
    property string imagePath: ""
    property var sharedData: null
    signal editorClosed()
    
    anchors { 
        top: true
        bottom: true
        left: true
        right: true 
    }
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    
    color: "transparent"
    
    // ── Design Tokens (M3 Inspired) ──
    readonly property color dsAccent: (sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff"
    readonly property color dsSurface: (sharedData && sharedData.colorSecondary) ? sharedData.colorSecondary : "#141414"
    readonly property color dsSurfaceContainer: Qt.rgba(dsSurface.r, dsSurface.g, dsSurface.b, 0.95)
    readonly property color dsBorder: Qt.rgba(1, 1, 1, 0.1)
    readonly property real dsRadius: (sharedData && sharedData.quickshellBorderRadius !== undefined) ? sharedData.quickshellBorderRadius : 16

    // State
    property string activeTool: "pencil" // "pencil" only
    property color activeColor: dsAccent
    property real lineWidth: 4
    
    // History system
    ListModel { id: drawingHistory }
    
    // Current temporary shape being drawn
    property var currentShape: null

    // ── Main Layout ──
    Rectangle {
        id: backdrop
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.7)
        
        MouseArea { 
            anchors.fill: parent
            onClicked: { root.close() } 
        }
        
        Rectangle {
            id: editorContainer
            width: parent.width * 0.9
            height: parent.height * 0.85
            anchors.centerIn: parent
            radius: dsRadius
            color: dsSurface
            border.width: 1
            border.color: dsBorder
            clip: true
            
            // Prevent clicks from closing the editor
            MouseArea { 
                anchors.fill: parent
                propagateComposedEvents: false 
            }

            ColumnLayout {
                anchors.fill: parent
                spacing: 0
                
                // Toolbar (M3 Top Bar style)
                Rectangle {
                    Layout.fillWidth: true
                    height: 64
                    color: Qt.rgba(1, 1, 1, 0.03)
                    
                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 12
                        
                        Text {
                            text: "Screenshot Editor"
                            color: "#ffffff"
                            font.pixelSize: 18
                            font.family: "Outfit"
                            font.weight: Font.Bold
                        }
                        
                        Item { Layout.fillWidth: true }
                        
                        ToolButton { 
                            icon: "󰄿"
                            tooltip: "Undo"
                            enabled: drawingHistory.count > 0
                            onClicked: { undo() } 
                        }
                        ToolButton { 
                            icon: "󰆴"
                            tooltip: "Delete Screenshot"
                            onClicked: { deleteScreenshot() } 
                        }
                        
                        Rectangle { 
                            width: 1
                            height: 24
                            color: dsBorder
                            Layout.leftMargin: 4
                            Layout.rightMargin: 4 
                        }
                        
                        ToolButton { 
                            icon: "󰐵"
                            label: "Save & Copy"
                            highlight: true
                            onClicked: { saveAndCopy() } 
                        }
                        ToolButton { 
                            icon: "󰅖"
                            tooltip: "Close"
                            onClicked: { root.close() } 
                        }
                    }
                }
                
                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 0
                    
                    // Side Toolbox (M3 Sidebar style)
                    Rectangle {
                        Layout.fillHeight: true
                        width: 80
                        color: Qt.rgba(1, 1, 1, 0.02)
                        
                        ColumnLayout {
                            anchors.top: parent.top
                            anchors.topMargin: 20
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 12
                            
                            ToolIcon { 
                                icon: "󰏫"
                                tool: "pencil"
                                label: "Draw" 
                            }
                            
                            Item { height: 20 }
                            
                            // Color selection
                            Repeater {
                                model: ["#4a9eff", "#ff5555", "#50fa7b", "#f1fa8c", "#bd93f9", "#ffffff"]
                                delegate: Rectangle {
                                    width: 28
                                    height: 28
                                    radius: 14
                                    color: modelData
                                    border.width: 2
                                    border.color: activeColor === modelData ? "#ffffff" : "transparent"
                                    Layout.alignment: Qt.AlignHCenter
                                    MouseArea { 
                                        anchors.fill: parent
                                        onClicked: { activeColor = modelData }
                                        cursorShape: Qt.PointingHandCursor 
                                    }
                                }
                            }
                        }
                    }
                    
                    // Canvas Area
                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        
                        Image {
                            id: screenshotImg
                            anchors.centerIn: parent
                            source: imagePath ? "file://" + imagePath : ""
                            fillMode: Image.PreserveAspectFit
                            width: parent.width - 40
                            height: parent.height - 40
                            asynchronous: true
                            
                            Canvas {
                                id: canvas
                                anchors.fill: parent
                                
                                onPaint: {
                                    var ctx = getContext("2d");
                                    ctx.clearRect(0, 0, width, height);
                                    
                                    // Draw History
                                    for (var i = 0; i < drawingHistory.count; i++) {
                                        drawShape(ctx, drawingHistory.get(i));
                                    }
                                    
                                    // Draw current shape
                                    if (currentShape) {
                                        drawShape(ctx, currentShape);
                                    }
                                }
                                
                                MouseArea {
                                    id: canvasMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    
                                    property real startX
                                    property real startY

                                    onPressed: (mouse) => {
                                        startX = mouse.x; startY = mouse.y;
                                        if (activeTool === "pencil") {
                                            currentShape = { type: "pencil", color: activeColor, width: lineWidth, points: [{x: mouse.x, y: mouse.y}] };
                                        }
                                    }
                                    
                                    onPositionChanged: (mouse) => {
                                        if (pressed && currentShape) {
                                            if (activeTool === "pencil") {
                                                currentShape.points.push({x: mouse.x, y: mouse.y});
                                            } else {
                                                currentShape.x2 = mouse.x; currentShape.y2 = mouse.y;
                                            }
                                            canvas.requestPaint();
                                        }
                                    }
                                    
                                    onReleased: (mouse) => {
                                        if (currentShape) {
                                            drawingHistory.append(currentShape);
                                            currentShape = null;
                                            canvas.requestPaint();
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
    
    function drawShape(ctx, s) {
        ctx.lineWidth = s.width || 4;
        ctx.strokeStyle = s.color || "#ffffff";
        ctx.fillStyle = s.color || "#ffffff";
        ctx.lineCap = "round";
        ctx.lineJoin = "round";
        
        if (s.type === "pencil") {
            ctx.beginPath();
            if (s.points.count > 0) {
                ctx.moveTo(s.points.get(0).x, s.points.get(0).y);
                for (var i = 1; i < s.points.count; i++) {
                    ctx.lineTo(s.points.get(i).x, s.points.get(i).y);
                }
            } else if (Array.isArray(s.points)) {
                ctx.moveTo(s.points[0].x, s.points[0].y);
                for (var i = 1; i < s.points.length; i++) {
                    ctx.lineTo(s.points[i].x, s.points[i].y);
                }
            }
            ctx.stroke();
        }
    }
    

    function undo() {
        if (drawingHistory.count > 0) {
            drawingHistory.remove(drawingHistory.count - 1);
            canvas.requestPaint();
        }
    }

    function close() { 
        root.editorClosed(); 
    }

    function saveAndCopy() {
        canvas.grabToImage(function(result) {
            result.saveToFile(imagePath);
            if (sharedData && sharedData.runCommand) {
                sharedData.runCommand(['sh', '-c', 'wl-copy < "' + imagePath + '" && notify-send -a "Alloy" "Screenshot Tool" "Saved and copied to clipboard" -i "' + imagePath + '"']);
            }
            root.close();
        });
    }
    function deleteScreenshot() {
        if (sharedData && sharedData.runCommand) {
            sharedData.runCommand(['rm', imagePath]);
        }
        root.close();
    }


    // ── Components ──
    component ToolButton : Rectangle {
        id: tb
        property string icon: ""
        property string label: ""
        property string tooltip: ""
        property bool highlight: false
        
        signal clicked()
        
        width: implicitWidth
        height: 40
        radius: 20
        color: ma.containsMouse ? (highlight ? Qt.lighter(dsAccent, 1.1) : Qt.rgba(1, 1, 1, 0.08)) : (highlight ? dsAccent : "transparent")
        
        Text {
            anchors.centerIn: parent
            text: tb.icon
            font.family: "Material Design Icons"
            font.pixelSize: 20
            color: highlight ? "#000000" : (ma.containsMouse ? "#ffffff" : Qt.rgba(1, 1, 1, 0.6))
            visible: !tb.label
        }
        
        RowLayout {
            id: contentLayout
            anchors.centerIn: parent
            spacing: 8
            visible: tb.label !== ""
            Text { 
                text: tb.icon
                font.family: "Material Design Icons"
                font.pixelSize: 20
                color: tb.highlight ? "#000000" : "#ffffff" 
            }
            Text { 
                text: tb.label
                font.family: "Inter"
                font.pixelSize: 14
                font.weight: 600
                color: tb.highlight ? "#000000" : "#ffffff" 
            }
        }
        
        implicitWidth: tb.label ? contentLayout.implicitWidth + 32 : 40
        
        MouseArea { 
            id: ma
            anchors.fill: parent
            hoverEnabled: true
            onClicked: { tb.clicked() }
            cursorShape: Qt.PointingHandCursor 
        }
    }

    component ToolIcon : ColumnLayout {
        id: ti
        property string icon: ""
        property string tool: ""
        property string label: ""
        spacing: 4
        
        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            width: 44
            height: 32
            radius: 16
            color: activeTool === tool ? dsAccent : "transparent"
            Text {
                anchors.centerIn: parent
                text: ti.icon
                font.family: "Material Design Icons"
                font.pixelSize: 22
                color: activeTool === tool ? "#000000" : (tiMa.containsMouse ? "#ffffff" : Qt.rgba(1, 1, 1, 0.4))
            }
            MouseArea { 
                id: tiMa
                anchors.fill: parent
                hoverEnabled: true
                onClicked: { activeTool = tool }
                cursorShape: Qt.PointingHandCursor 
            }
        }
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: ti.label
            color: "#ffffff"
            opacity: activeTool === tool ? 1.0 : 0.4
            font.pixelSize: 10
            font.family: "Inter"
        }
    }
}

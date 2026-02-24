import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15
import Quickshell 1.0
import Quickshell.Wayland 1.0
import Quickshell.Io 1.0

PanelWindow {
    id: root
    width: 1000
    height: 700
    visible: true
    title: "Screenshot Editor"
    
    // To position correctly centered
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    
    property string imagePath: ""
    property var sharedData
    
    // Need a process helper to save
    Process {
        id: saveProcess
        command: ["sh", "-c", "echo 'Saved'"]
    }

    Rectangle {
        anchors.fill: parent
        color: "#1e1e2e" // Mocha Background
        radius: 10
        border.color: "#313244"
        border.width: 2
        
        Column {
            anchors.fill: parent
            
            // Toolbar
            Rectangle {
                width: parent.width
                height: 50
                color: "#181825"
                radius: 10
                
                Row {
                    anchors.centerIn: parent
                    spacing: 15
                    
                    Button {
                        text: "Save & Copy"
                        onClicked: {
                            canvas.grabToImage(function(result) {
                                result.saveToFile(root.imagePath);
                                // Trigger copy
                                if (sharedData && sharedData.runCommand) {
                                    sharedData.runCommand(['sh', '-c', 'wl-copy < "' + root.imagePath + '"']);
                                }
                                root.visible = false;
                            });
                        }
                    }
                    Button {
                        text: "Cancel"
                        onClicked: {
                            if (sharedData && sharedData.runCommand) {
                                sharedData.runCommand(['sh', '-c', 'rm -f "' + root.imagePath + '"']);
                            }
                            root.visible = false;
                        }
                    }
                    Button {
                        text: "Clear Drawing"
                        onClicked: {
                            canvas.clear = true;
                            canvas.requestPaint();
                        }
                    }
                }
            }
            
            // Image + Drawable Canvas
            Item {
                width: parent.width
                height: parent.height - 50
                
                Image {
                    id: screenshotImage
                    anchors.centerIn: parent
                    source: root.imagePath ? "file://" + root.imagePath : ""
                    fillMode: Image.PreserveAspectFit
                    width: parent.width * 0.95
                    height: parent.height * 0.95
                    
                    Canvas {
                        id: canvas
                        anchors.fill: parent
                        
                        property real lastX: 0
                        property real lastY: 0
                        property bool clear: false
                        
                        onPaint: {
                            var ctx = getContext("2d");
                            if (clear) {
                                ctx.clearRect(0, 0, width, height);
                                clear = false;
                                return;
                            }
                            
                            ctx.lineWidth = 6;
                            ctx.strokeStyle = "#f38ba8"; // Mocha Red
                            ctx.lineCap = "round";
                            ctx.lineJoin = "round";
                            
                            ctx.beginPath();
                            ctx.moveTo(lastX, lastY);
                            ctx.lineTo(mouseArea.mouseX, mouseArea.mouseY);
                            ctx.stroke();
                        }
                        
                        MouseArea {
                            id: mouseArea
                            anchors.fill: parent
                            
                            onPressed: (mouse) => {
                                canvas.lastX = mouse.x;
                                canvas.lastY = mouse.y;
                            }
                            
                            onPositionChanged: (mouse) => {
                                if (pressed) {
                                    canvas.requestPaint();
                                    canvas.lastX = mouse.x;
                                    canvas.lastY = mouse.y;
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

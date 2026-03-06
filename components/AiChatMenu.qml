import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Rectangle {
    id: aiChatRoot
    color: (sharedData && sharedData.colorSecondary) ? sharedData.colorSecondary : "#141414"
    radius: (sharedData && sharedData.quickshellBorderRadius !== undefined) ? sharedData.quickshellBorderRadius : 16

    property var sharedData: null
    property string aiEndpoint: "http://127.0.0.1:11434"
    property string aiModel: "llama3"
    property var availableModels: [aiModel]
    property bool isLoading: false
    property bool isSettingsOpen: false

    // Load saved settings if they exist
    Component.onCompleted: {
        if (sharedData && sharedData.runCommand) {
             sharedData.runCommand(['sh', '-c', 'cat ~/.config/alloy/dart_ai_settings.json 2>/dev/null'], function(out) {
                 try {
                     var parsed = JSON.parse(out);
                     if (parsed.endpoint) aiEndpoint = parsed.endpoint;
                     if (parsed.model) aiModel = parsed.model;
                     ipInput.text = aiEndpoint;
                 } catch(e) {}
                 fetchModels();
             });
        } else {
             fetchModels();
        }
    }

    function fetchModels() {
        var xhr = new XMLHttpRequest();
        xhr.open("GET", aiEndpoint + "/api/tags");
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        var response = JSON.parse(xhr.responseText);
                        var models = [];
                        if (response && response.models) {
                            for (var i = 0; i < response.models.length; i++) {
                                models.push(response.models[i].name);
                            }
                        }
                        
                        // Ensure currently selected model is in the list
                        if (aiModel !== "" && models.indexOf(aiModel) === -1) {
                            models.push(aiModel);
                        }
                        
                        if (models.length === 0 && aiModel !== "") {
                            models.push(aiModel);
                        }
                        
                        availableModels = models;
                    } catch(e) {
                        console.log("Error parsing Ollama tags response: " + e);
                        availableModels = ["API Parse Error"];
                    }
                } else {
                    console.log("HTTP Error when fetching models: " + xhr.status);
                    availableModels = ["Nie można połączyć się z serwerem"];
                }
            }
        };
        xhr.send();
    }

    function saveSettings() {
        if (sharedData && sharedData.runCommand) {
            var conf = JSON.stringify({endpoint: aiEndpoint, model: aiModel});
            sharedData.runCommand(['sh', '-c', "echo '" + conf + "' > ~/.config/alloy/dart_ai_settings.json"]);
        }
    }



    ListModel {
        id: chatModel
        ListElement {
            role: "assistant"
            message: "Hello! I'm your local AI assistant. How can I help you today?"
        }
    }

    function sendMessage(text) {
        if (!text || text.trim() === " ") return;
        
        chatModel.append({ role: "user", message: text, thought: "" });
        chatListView.positionViewAtEnd();
        messageInput.text = "";
        
        isLoading = true;
        
        // Prepare API request to Ollama
        var xhr = new XMLHttpRequest();
        xhr.open("POST", aiEndpoint + "/api/generate");
        xhr.setRequestHeader("Content-Type", "application/json");
        
        var payload = {
            model: aiModel,
            prompt: text,
            stream: false
        };
        
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                isLoading = false;
                if (xhr.status === 200) {
                    try {
                        var response = JSON.parse(xhr.responseText);
                        var rawText = response.response || "";
                        
                        var thoughtText = "";
                        var msgText = rawText;
                        
                        // Parse <think>...</think> block if present
                        var thinkStart = rawText.indexOf("<think>");
                        var thinkEnd = rawText.indexOf("</think>");
                        
                        if (thinkStart !== -1 && thinkEnd !== -1 && thinkEnd > thinkStart) {
                            thoughtText = rawText.substring(thinkStart + 7, thinkEnd).trim();
                            msgText = rawText.substring(thinkEnd + 8).trim();
                        } else if (thinkStart !== -1) {
                            // Unclosed think tag
                            thoughtText = rawText.substring(thinkStart + 7).trim();
                            msgText = "";
                        }
                        
                        chatModel.append({ role: "assistant", message: msgText, thought: thoughtText });
                    } catch(e) {
                        chatModel.append({ role: "assistant", message: "Error parsing API response.", thought: "" });
                    }
                } else {
                    chatModel.append({ role: "assistant", message: "Connection error: Unable to reach Ollama at " + aiEndpoint + " (HTTP " + xhr.status + ")", thought: "" });
                }
                chatListView.positionViewAtEnd();
            }
        };
        
        xhr.send(JSON.stringify(payload));
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 12

        // Header
        RowLayout {
            Layout.fillWidth: true
            
            ColumnLayout {
                spacing: 2
                Layout.fillWidth: true
                Text {
                    text: isSettingsOpen ? "AI Settings" : "Ollama AI"
                    color: (sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff"
                    font.pixelSize: 18
                    font.weight: Font.ExtraBold
                }
                Text {
                    text: isSettingsOpen ? "Configure connection" : ("Using " + aiModel + " via " + aiEndpoint)
                    color: "#ffffff"
                    font.pixelSize: 12
                    font.weight: Font.Medium
                    opacity: 0.7
                    elide: Text.ElideRight
                    Layout.maximumWidth: 280
                }
            }
            
            Rectangle {
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32
                radius: 16
                color: settingsMa.containsMouse ? Qt.rgba(1,1,1,0.1) : "transparent"
                Text {
                    anchors.centerIn: parent
                    text: isSettingsOpen ? "󰅖" : "󰒓"
                    color: "#ffffff"
                    font.pixelSize: 18
                }
                MouseArea {
                    id: settingsMa
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        isSettingsOpen = !isSettingsOpen;
                        if (!isSettingsOpen) saveSettings();
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Qt.rgba(1,1,1,0.1)
        }

        // Settings View
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: isSettingsOpen
            spacing: 16
            
            Text {
                text: "Ollama Endpoint URL:"
                color: "#ffffff"
                font.pixelSize: 13
            }
            Rectangle {
                Layout.fillWidth: true
                height: 40
                radius: 8
                color: Qt.rgba(1,1,1,0.05)
                border.width: 1
                border.color: ipInput.activeFocus ? ((sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff") : Qt.rgba(1,1,1,0.1)
                
                TextInput {
                    id: ipInput
                    anchors.fill: parent
                    anchors.margins: 10
                    color: "#ffffff"
                    font.pixelSize: 14
                    verticalAlignment: TextInput.AlignVCenter
                    text: aiEndpoint
                    onTextChanged: {
                        aiEndpoint = text
                        // Debounce model fetch when typing IP
                        endpointFetchTimer.restart()
                    }
                }
                
                Timer {
                    id: endpointFetchTimer
                    interval: 1000 // Wait 1s after user stops typing to fetch models
                    onTriggered: fetchModels()
                }
            }
            
            Text {
                text: "Model Name:"
                color: "#ffffff"
                font.pixelSize: 13
            }
            ComboBox {
                id: modelComboBox
                Layout.fillWidth: true
                height: 40
                model: availableModels
                
                editable: false 
                
                // Select currently saved model
                currentIndex: Math.max(0, availableModels.indexOf(aiModel))
                onActivated: {
                    if (availableModels.length > index && index >= 0) {
                        aiModel = availableModels[index]
                    }
                }

                // Call fetch models when dropdown is opened to refresh list
                onPressedChanged: {
                    if (pressed) {
                        fetchModels()
                    }
                }
                
                background: Rectangle {
                    color: Qt.rgba(1,1,1,0.05)
                    radius: 8
                    border.width: 1
                    border.color: modelComboBox.visualFocus ? ((sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff") : Qt.rgba(1,1,1,0.1)
                }
                
                contentItem: Text {
                    leftPadding: 10
                    rightPadding: modelComboBox.indicator ? modelComboBox.indicator.width + modelComboBox.spacing : 10
                    text: modelComboBox.displayText
                    font.pixelSize: 14
                    color: "#ffffff"
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                }
                
                delegate: ItemDelegate {
                    width: modelComboBox.width
                    contentItem: Text {
                        text: modelData
                        color: "#ffffff"
                        font.pixelSize: 14
                        elide: Text.ElideRight
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        color: parent.highlighted ? Qt.rgba(1,1,1,0.1) : "transparent"
                    }
                }
                
                popup: Popup {
                    y: modelComboBox.height - 1
                    width: modelComboBox.width
                    implicitHeight: contentItem.implicitHeight
                    padding: 1
                    
                    contentItem: ListView {
                        clip: true
                        implicitHeight: contentHeight
                        model: modelComboBox.popup.visible ? modelComboBox.delegateModel : null
                        currentIndex: modelComboBox.highlightedIndex
                    }
                    
                    background: Rectangle {
                        color: (sharedData && sharedData.colorSecondary) ? sharedData.colorSecondary : "#1c1c1c"
                        border.color: Qt.rgba(1,1,1,0.1)
                        border.width: 1
                        radius: 8
                    }
                }
            }
            
            Item { Layout.fillHeight: true } // Spacer
        }

        // Chat View
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: !isSettingsOpen
            spacing: 8
            
            ListView {
                id: chatListView
                Layout.fillWidth: true
                Layout.fillHeight: true
                model: chatModel
                clip: true
                spacing: 16
                
                delegate: Column {
                    width: ListView.view.width
                    spacing: 4
                    
                    Text {
                        text: model.role === "user" ? "You" : "AI"
                        font.pixelSize: 11
                        font.weight: Font.Bold
                        color: Qt.rgba(1,1,1,0.5)
                        anchors.right: model.role === "user" ? parent.right : undefined
                        anchors.left: model.role === "assistant" ? parent.left : undefined
                    }
                    
                    Rectangle {
                        width: Math.min(Math.max(messageText.implicitWidth, (model.thought ? thoughtBlock.implicitWidth : 0)) + 24, parent.width * 0.85)
                        height: messageColumn.implicitHeight + 20
                        radius: 12
                        // Sharp corner pointing to speaker
                        topLeftRadius: model.role === "assistant" ? 4 : 12
                        topRightRadius: model.role === "user" ? 4 : 12
                        
                        color: model.role === "user" ? 
                               ((sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff") : 
                               Qt.rgba(1,1,1, 0.08)
                               
                        border.width: model.role === "assistant" ? 1 : 0
                        border.color: Qt.rgba(1,1,1,0.05)
                        
                        anchors.right: model.role === "user" ? parent.right : undefined
                        anchors.left: model.role === "assistant" ? parent.left : undefined
                        
                        Column {
                            id: messageColumn
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 8
                            
                            // Thought block
                            Rectangle {
                                id: thoughtBlock
                                width: Math.min(thoughtLayout.implicitWidth + 16, parent.width)
                                height: thoughtLayout.implicitHeight + 12
                                color: Qt.rgba(0,0,0,0.2)
                                radius: 8
                                visible: model.thought ? (model.thought.length > 0) : false
                                
                                RowLayout {
                                    id: thoughtLayout
                                    anchors.fill: parent
                                    anchors.margins: 6
                                    spacing: 6
                                    
                                    Text {
                                        Layout.alignment: Qt.AlignTop
                                        text: "󰌵" // Lightbulb icon
                                        color: Qt.rgba(1,1,1,0.5)
                                        font.pixelSize: 14
                                    }
                                    
                                    Text {
                                        Layout.fillWidth: true
                                        text: model.thought ? model.thought : ""
                                        color: Qt.rgba(1,1,1,0.6)
                                        font.pixelSize: 12
                                        font.italic: true
                                        wrapMode: Text.Wrap
                                        lineHeight: 1.2
                                    }
                                }
                            }
                            
                            // Divider if both thought and message exist
                            Rectangle {
                                width: parent.width
                                height: 1
                                color: Qt.rgba(1,1,1,0.1)
                                visible: (model.thought ? (model.thought.length > 0) : false) && (model.message ? (model.message.length > 0) : false)
                            }

                            Text {
                                id: messageText
                                width: parent.width
                                text: model.message
                                color: model.role === "user" ? "#000000" : "#ffffff"
                                font.pixelSize: 14
                                wrapMode: Text.Wrap
                                lineHeight: 1.2
                                visible: model.message ? (model.message.length > 0) : false
                            }
                        }
                    }
                }
                
                // Keep scrolled to bottom when new messages arrive
                onCountChanged: {
                    Qt.callLater(positionViewAtEnd)
                }
            }
            
            // Loading Indicator
            Row {
                Layout.fillWidth: true
                spacing: 8
                visible: isLoading
                Text { text: "󰇘"; color: (sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff"; font.pixelSize: 24; font.family: "Material Design Icons" }
                Text { text: "Generating response..."; color: Qt.rgba(1,1,1,0.5); font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
            }
            
            // Input Field
            Rectangle {
                Layout.fillWidth: true
                height: 48
                radius: 24
                color: Qt.rgba(1,1,1,0.05)
                border.width: 1
                border.color: messageInput.activeFocus ? ((sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff") : Qt.rgba(1,1,1,0.1)
                
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 8
                    
                    TextInput {
                        id: messageInput
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        verticalAlignment: TextInput.AlignVCenter
                        color: "#ffffff"
                        font.pixelSize: 14
                        selectByMouse: true
                        clip: true
                        
                        Text {
                            anchors.fill: parent
                            verticalAlignment: Text.AlignVCenter
                            text: "Message Ollama..."
                            color: Qt.rgba(1,1,1,0.3)
                            font.pixelSize: 14
                            visible: !messageInput.text && !messageInput.activeFocus
                        }
                        
                        // Handle enter key to send
                        Keys.onReturnPressed: {
                            if (!isLoading) aiChatRoot.sendMessage(text);
                        }
                    }
                    
                    Rectangle {
                        Layout.preferredWidth: 32
                        Layout.preferredHeight: 32
                        radius: 16
                        color: (messageInput.text.trim().length > 0 && !isLoading) ? ((sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff") : Qt.rgba(1,1,1,0.1)
                        opacity: (messageInput.text.trim().length > 0 && !isLoading) ? 1.0 : 0.5
                        
                        Text {
                            anchors.centerIn: parent
                            text: "󰒍" // Send icon
                            color: (messageInput.text.trim().length > 0 && !isLoading) ? "#000000" : "#ffffff"
                            font.pixelSize: 16
                        }
                        
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                if (!isLoading) aiChatRoot.sendMessage(messageInput.text);
                            }
                        }
                    }
                }
            }
        }
    }
}

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
    property string settingsFilePath: "/home/iartwik/.config/alloy/dart_ai_settings.json"
    property bool settingsLoaded: false
    property string searxngEndpoint: ""
    property bool webSearchEnabled: false

    // Load saved settings synchronously at startup
    Component.onCompleted: {
        try {
            var xhr = new XMLHttpRequest();
            xhr.open("GET", "file://" + settingsFilePath, false); // synchronous
            xhr.send();
            if (xhr.status === 200 && xhr.responseText) {
                var parsed = JSON.parse(xhr.responseText);
                if (parsed.endpoint) {
                    aiEndpoint = parsed.endpoint;
                }
                if (parsed.model) {
                    aiModel = parsed.model;
                }
                if (parsed.searxng) {
                    searxngEndpoint = parsed.searxng;
                }
                if (parsed.webSearch !== undefined) {
                    webSearchEnabled = parsed.webSearch === true;
                }
                console.log("AI Settings Loaded: " + aiEndpoint + " | " + aiModel);
            }
        } catch(e) {
            console.log("No AI Settings found or parse error: " + e);
        }
        settingsLoaded = true;
        fetchModels();
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
        if (!settingsLoaded) return; // Don't save during initial load
        if (sharedData && sharedData.runCommand) {
            var conf = JSON.stringify({endpoint: aiEndpoint, model: aiModel, searxng: searxngEndpoint, webSearch: webSearchEnabled});
            // We must escape internal double quotes for the bash command
            var escapedConf = conf.replace(/"/g, '\\"');
            sharedData.runCommand(['sh', '-c', 'echo "' + escapedConf + '" > ' + settingsFilePath]);
            console.log("Saving AI Settings: " + conf);
        }
    }

    ListModel {
        id: chatModel
    }

    // Search SearXNG and return results as context string
    function searchWeb(query, callback) {
        if (!searxngEndpoint || searxngEndpoint.trim().length === 0) {
            callback("");
            return;
        }
        var url = searxngEndpoint.replace(/\/$/, "") + "/search?q=" + encodeURIComponent(query) + "&format=json&categories=general&language=auto&engines=google,duckduckgo,brave,wikipedia";
        var xhr = new XMLHttpRequest();
        xhr.open("GET", url);
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        var data = JSON.parse(xhr.responseText);
                        var context = "";
                        var results = data.results || [];
                        var count = Math.min(results.length, 5);
                        for (var i = 0; i < count; i++) {
                            var r = results[i];
                            context += "[" + (i+1) + "] " + (r.title || "") + "\n";
                            context += (r.url || "") + "\n";
                            context += (r.content || "") + "\n\n";
                        }
                        callback(context.trim());
                    } catch(e) {
                        console.log("SearXNG parse error: " + e);
                        callback("");
                    }
                } else {
                    console.log("SearXNG HTTP error: " + xhr.status);
                    callback("");
                }
            }
        };
        xhr.send();
    }

    function sendMessage(text) {
        if (!text || text.trim() === " ") return;
        
        chatModel.append({ role: "user", message: text, thought: "" });
        chatListView.positionViewAtEnd();
        messageInput.text = "";
        
        isLoading = true;
        
        // If web search is enabled, search first then send augmented prompt
        if (webSearchEnabled && searxngEndpoint.trim().length > 0) {
            searchWeb(text, function(webContext) {
                var augmentedPrompt = text;
                if (webContext.length > 0) {
                    augmentedPrompt = "The user asked: " + text + "\n\nHere are relevant web search results for context:\n\n" + webContext + "\nUse these search results to provide an accurate, up-to-date answer. Cite sources when relevant.";
                }
                sendToOllama(augmentedPrompt);
            });
        } else {
            sendToOllama(text);
        }
    }

    function sendToOllama(prompt) {
        var xhr = new XMLHttpRequest();
        xhr.open("POST", aiEndpoint + "/api/generate");
        xhr.setRequestHeader("Content-Type", "application/json");
        
        var payload = {
            model: aiModel,
            prompt: prompt,
            stream: true
        };
        
        chatModel.append({ role: "assistant", message: "", thought: "" });
        var messageIndex = chatModel.count - 1;
        var fullRawText = "";
        var processedLength = 0;
        
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                isLoading = false;
            }
            
            if (xhr.readyState === XMLHttpRequest.LOADING || xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    var newText = xhr.responseText.substring(processedLength);
                    if (!newText) return;
                    
                    var lines = newText.split('\n');
                    var linesToProcess = (xhr.readyState === XMLHttpRequest.DONE) ? lines.length : lines.length - 1;
                    
                    for (var i = 0; i < linesToProcess; i++) {
                        var lineText = lines[i].trim();
                        if (lineText.length > 0) {
                            try {
                                var response = JSON.parse(lineText);
                                if (response.response) {
                                    fullRawText += response.response;
                                }
                            } catch(e) {}
                        }
                        processedLength += lines[i].length + 1;
                    }
                    
                    var thoughtText = "";
                    var msgText = fullRawText;
                    
                    var thinkStart = fullRawText.indexOf("<think>");
                    var thinkEnd = fullRawText.indexOf("</think>");
                    
                    if (thinkStart !== -1 && thinkEnd !== -1 && thinkEnd > thinkStart) {
                        thoughtText = fullRawText.substring(thinkStart + 7, thinkEnd).trim();
                        msgText = fullRawText.substring(thinkEnd + 8).trim();
                    } else if (thinkStart !== -1) {
                        thoughtText = fullRawText.substring(thinkStart + 7).trim();
                        msgText = "";
                    }
                    
                    chatModel.setProperty(messageIndex, "message", msgText);
                    chatModel.setProperty(messageIndex, "thought", thoughtText);
                    
                } else if (xhr.readyState === XMLHttpRequest.DONE) {
                    chatModel.setProperty(messageIndex, "message", "Connection error: Unable to reach Ollama at " + aiEndpoint + " (HTTP " + xhr.status + ")");
                }
                
                chatListView.positionViewAtEnd();
            }
        };
        
        xhr.send(JSON.stringify(payload));
    }

    // ── Design tokens: match Dashboard exactly ──
    property real dsRadius: (sharedData && sharedData.quickshellBorderRadius !== undefined) ? sharedData.quickshellBorderRadius : 14
    property real dsSmallRadius: dsRadius > 8 ? 8 : dsRadius
    property color dsAccent: (sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff"
    property color dsSurface: (sharedData && sharedData.colorSecondary) ? sharedData.colorSecondary : "#1c1c1c"

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 10

        // ── Header ──
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Rectangle {
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32
                radius: dsSmallRadius
                color: Qt.rgba(dsAccent.r, dsAccent.g, dsAccent.b, 0.15)

                Text {
                    anchors.centerIn: parent
                    text: "󰚩"
                    color: dsAccent
                    font.pixelSize: 16
                }
            }

            Text {
                Layout.fillWidth: true
                text: isSettingsOpen ? "Settings" : aiModel
                color: "#ffffff"
                font.pixelSize: 14
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }

            Rectangle {
                Layout.preferredWidth: 28
                Layout.preferredHeight: 28
                radius: dsSmallRadius
                color: settingsMa.containsMouse ? Qt.rgba(1,1,1,0.08) : "transparent"
                Behavior on color { ColorAnimation { duration: 150 } }

                Text {
                    anchors.centerIn: parent
                    text: isSettingsOpen ? "󰅖" : "󰒓"
                    color: Qt.rgba(1,1,1,0.5)
                    font.pixelSize: 14
                }
                MouseArea {
                    id: settingsMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        isSettingsOpen = !isSettingsOpen;
                        if (!isSettingsOpen) saveSettings();
                    }
                }
            }
        }

        // ── Settings View ──
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: isSettingsOpen
            spacing: 14

            Text { text: "Endpoint URL"; color: Qt.rgba(1,1,1,0.5); font.pixelSize: 12; font.weight: Font.Medium }
            Rectangle {
                Layout.fillWidth: true
                height: 40
                radius: dsSmallRadius
                color: Qt.rgba(1,1,1,0.06)
                border.width: ipInput.activeFocus ? 1 : 0
                border.color: dsAccent

                TextInput {
                    id: ipInput
                    anchors.fill: parent
                    anchors.leftMargin: 12; anchors.rightMargin: 12
                    color: "#ffffff"
                    font.pixelSize: 13
                    verticalAlignment: TextInput.AlignVCenter
                    text: aiEndpoint
                    selectByMouse: true
                    onTextChanged: { aiEndpoint = text; endpointFetchTimer.restart() }
                    onEditingFinished: { saveSettings() }
                }
                Timer { id: endpointFetchTimer; interval: 1000; onTriggered: fetchModels() }
            }

            Text { text: "Model"; color: Qt.rgba(1,1,1,0.5); font.pixelSize: 12; font.weight: Font.Medium }
            ComboBox {
                id: modelComboBox
                Layout.fillWidth: true
                height: 40
                model: availableModels
                editable: false
                currentIndex: Math.max(0, availableModels.indexOf(aiModel))
                onActivated: { if (availableModels.length > index && index >= 0) { aiModel = availableModels[index]; saveSettings() } }
                onPressedChanged: { if (pressed) fetchModels() }

                background: Rectangle {
                    color: Qt.rgba(1,1,1,0.06)
                    radius: dsSmallRadius
                    border.width: modelComboBox.visualFocus ? 1 : 0
                    border.color: dsAccent
                }
                contentItem: Text {
                    leftPadding: 12; rightPadding: 36
                    text: modelComboBox.displayText
                    font.pixelSize: 13; color: "#ffffff"
                    verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight
                }
                delegate: ItemDelegate {
                    width: modelComboBox.width
                    contentItem: Text {
                        text: modelData; color: "#ffffff"; font.pixelSize: 13
                        elide: Text.ElideRight; verticalAlignment: Text.AlignVCenter; leftPadding: 12
                    }
                    background: Rectangle { color: parent.highlighted ? Qt.rgba(1,1,1,0.08) : "transparent" }
                }
                popup: Popup {
                    y: modelComboBox.height + 2; width: modelComboBox.width
                    implicitHeight: contentItem.implicitHeight + 8; padding: 4
                    contentItem: ListView {
                        clip: true; implicitHeight: contentHeight
                        model: modelComboBox.popup.visible ? modelComboBox.delegateModel : null
                        currentIndex: modelComboBox.highlightedIndex
                    }
                    background: Rectangle {
                        color: dsSurface; border.color: Qt.rgba(1,1,1,0.08); border.width: 1; radius: dsSmallRadius
                    }
                }
            }

            // ── SearXNG section ──
            Rectangle { Layout.fillWidth: true; height: 1; color: Qt.rgba(1,1,1,0.08) }

            Text { text: "SearXNG URL (web search)"; color: Qt.rgba(1,1,1,0.5); font.pixelSize: 12; font.weight: Font.Medium }
            Rectangle {
                Layout.fillWidth: true
                height: 40
                radius: dsSmallRadius
                color: Qt.rgba(1,1,1,0.06)
                border.width: searxInput.activeFocus ? 1 : 0
                border.color: dsAccent

                TextInput {
                    id: searxInput
                    anchors.fill: parent
                    anchors.leftMargin: 12; anchors.rightMargin: 12
                    color: "#ffffff"
                    font.pixelSize: 13
                    verticalAlignment: TextInput.AlignVCenter
                    text: searxngEndpoint
                    selectByMouse: true
                    onTextChanged: { searxngEndpoint = text }
                    onEditingFinished: { saveSettings() }

                    Text {
                        anchors.fill: parent; verticalAlignment: Text.AlignVCenter
                        text: "http://localhost:8080"; color: Qt.rgba(1,1,1,0.2); font.pixelSize: 13
                        visible: !searxInput.text && !searxInput.activeFocus
                    }
                }
            }

            Item { Layout.fillHeight: true }
        }

        // ── Chat View ──
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: !isSettingsOpen
            spacing: 8

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                // ── Empty state placeholder ──
                Column {
                    anchors.centerIn: parent
                    spacing: 12
                    visible: chatModel.count === 0
                    opacity: 0.5

                    Rectangle {
                        width: 56; height: 56
                        radius: 28
                        color: Qt.rgba(dsAccent.r, dsAccent.g, dsAccent.b, 0.1)
                        anchors.horizontalCenter: parent.horizontalCenter

                        Text {
                            anchors.centerIn: parent
                            text: "󰚩"
                            color: dsAccent
                            font.pixelSize: 28
                        }
                    }

                    Text {
                        text: "Ask me anything"
                        color: "#ffffff"
                        font.pixelSize: 15
                        font.weight: Font.DemiBold
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    Text {
                        text: "Powered by " + aiModel
                        color: Qt.rgba(1,1,1,0.35)
                        font.pixelSize: 11
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }

                ListView {
                    id: chatListView
                    anchors.fill: parent
                    model: chatModel
                    clip: true
                    spacing: 10
                    visible: chatModel.count > 0

                delegate: Column {
                    width: ListView.view.width
                    spacing: 4

                    property bool hasContent: (model.message ? model.message.length > 0 : false) || (model.thought ? model.thought.length > 0 : false)
                    visible: hasContent

                    Text {
                        text: model.role === "user" ? "You" : "AI"
                        font.pixelSize: 11
                        font.weight: Font.Bold
                        color: model.role === "user" ? dsAccent : Qt.rgba(1,1,1,0.4)
                        anchors.right: model.role === "user" ? parent.right : undefined
                        anchors.left: model.role === "assistant" ? parent.left : undefined
                    }

                    Rectangle {
                        id: bubbleRect
                        width: parent.width * 0.85
                        height: messageColumn.height + 20
                        radius: dsSmallRadius + 4
                        topLeftRadius: model.role === "assistant" ? 4 : dsSmallRadius + 4
                        topRightRadius: model.role === "user" ? 4 : dsSmallRadius + 4
                        clip: true

                        color: model.role === "user" ?
                               Qt.rgba(dsAccent.r, dsAccent.g, dsAccent.b, 0.15) :
                               Qt.rgba(1,1,1, 0.06)

                        anchors.right: model.role === "user" ? parent.right : undefined
                        anchors.left: model.role === "assistant" ? parent.left : undefined

                        Column {
                            id: messageColumn
                            width: parent.width - 20
                            x: 10
                            y: 10
                            spacing: 8

                            // Thought block
                            Rectangle {
                                id: thoughtBlock
                                width: parent.width
                                height: thoughtLayout.implicitHeight + 12
                                color: Qt.rgba(0,0,0,0.15)
                                radius: dsSmallRadius
                                visible: model.thought ? (model.thought.length > 0) : false

                                RowLayout {
                                    id: thoughtLayout
                                    anchors.fill: parent
                                    anchors.margins: 6
                                    spacing: 6

                                    Text {
                                        Layout.alignment: Qt.AlignTop
                                        text: "󰌵"
                                        color: dsAccent
                                        font.pixelSize: 13
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: model.thought ? model.thought : ""
                                        color: Qt.rgba(1,1,1,0.6)
                                        font.pixelSize: 12
                                        font.italic: true
                                        wrapMode: Text.Wrap
                                        lineHeight: 1.2
                                        textFormat: Text.MarkdownText
                                    }
                                }
                            }

                            Rectangle {
                                width: parent.width; height: 1; color: Qt.rgba(1,1,1,0.08)
                                visible: (model.thought ? (model.thought.length > 0) : false) && (model.message ? (model.message.length > 0) : false)
                            }

                            TextEdit {
                                id: messageText
                                width: parent.width
                                text: model.message
                                color: "#ffffff"
                                selectedTextColor: "#ffffff"
                                selectionColor: Qt.rgba(dsAccent.r, dsAccent.g, dsAccent.b, 0.4)
                                font.pixelSize: 13
                                wrapMode: Text.Wrap
                                textFormat: Text.MarkdownText
                                readOnly: true
                                selectByMouse: true
                                visible: model.message ? (model.message.length > 0) : false
                            }
                        }
                    }
                }

                onCountChanged: { Qt.callLater(positionViewAtEnd) }
            }
            } // end Item wrapper

            // ── Loading Indicator ──
            Row {
                Layout.fillWidth: true
                spacing: 6
                visible: isLoading
                Layout.leftMargin: 4

                Repeater {
                    model: 3
                    Rectangle {
                        width: 6; height: 6; radius: 3
                        color: dsAccent

                        SequentialAnimation on y {
                            running: isLoading; loops: Animation.Infinite
                            PauseAnimation { duration: index * 150 }
                            NumberAnimation { from: 0; to: -6; duration: 250; easing.type: Easing.OutCubic }
                            NumberAnimation { from: -6; to: 0; duration: 250; easing.type: Easing.InCubic }
                            PauseAnimation { duration: (2 - index) * 150 }
                        }
                        SequentialAnimation on opacity {
                            running: isLoading; loops: Animation.Infinite
                            PauseAnimation { duration: index * 150 }
                            NumberAnimation { from: 0.3; to: 1.0; duration: 250 }
                            NumberAnimation { from: 1.0; to: 0.3; duration: 250 }
                            PauseAnimation { duration: (2 - index) * 150 }
                        }
                    }
                }

                Text { text: "Thinking..."; color: Qt.rgba(1,1,1,0.4); font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter; leftPadding: 2 }
            }

            // ── Input Field ──
            Rectangle {
                Layout.fillWidth: true
                height: 44
                radius: dsSmallRadius + 4
                color: Qt.rgba(1,1,1,0.06)

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14; anchors.rightMargin: 6
                    spacing: 6

                    TextInput {
                        id: messageInput
                        Layout.fillWidth: true; Layout.fillHeight: true
                        verticalAlignment: TextInput.AlignVCenter
                        color: "#ffffff"; font.pixelSize: 13
                        selectByMouse: true; clip: true

                        Text {
                            anchors.fill: parent; verticalAlignment: Text.AlignVCenter
                            text: "Message Ollama..."; color: Qt.rgba(1,1,1,0.25); font.pixelSize: 13
                            visible: !messageInput.text && !messageInput.activeFocus
                        }
                        Keys.onReturnPressed: { if (!isLoading) aiChatRoot.sendMessage(text); }
                    }

                    // ── Web search toggle ──
                    Rectangle {
                        Layout.preferredWidth: 32; Layout.preferredHeight: 32
                        radius: dsSmallRadius
                        visible: searxngEndpoint.trim().length > 0
                        color: webSearchEnabled ? Qt.rgba(dsAccent.r, dsAccent.g, dsAccent.b, 0.2) : Qt.rgba(1,1,1,0.06)
                        border.width: webSearchEnabled ? 1 : 0
                        border.color: dsAccent
                        Behavior on color { ColorAnimation { duration: 150 } }

                        Text {
                            anchors.centerIn: parent; text: "󰖟"
                            color: webSearchEnabled ? dsAccent : Qt.rgba(1,1,1,0.4)
                            font.pixelSize: 15
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true
                            onClicked: { webSearchEnabled = !webSearchEnabled; saveSettings() }
                        }
                        ToolTip {
                            text: webSearchEnabled ? "Web search: ON" : "Web search: OFF"
                            visible: parent.children[1].containsMouse
                            delay: 500
                        }
                    }

                    // ── Send button ──
                    Rectangle {
                        Layout.preferredWidth: 32; Layout.preferredHeight: 32
                        radius: dsSmallRadius
                        color: (messageInput.text.trim().length > 0 && !isLoading) ? dsAccent : Qt.rgba(1,1,1,0.06)
                        opacity: (messageInput.text.trim().length > 0 && !isLoading) ? 1.0 : 0.4
                        Behavior on color { ColorAnimation { duration: 150 } }
                        Behavior on opacity { NumberAnimation { duration: 150 } }

                        Text {
                            anchors.centerIn: parent; text: "󰒊"
                            color: (messageInput.text.trim().length > 0 && !isLoading) ? "#000000" : "#ffffff"
                            font.pixelSize: 15
                        }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: { if (!isLoading) aiChatRoot.sendMessage(messageInput.text); }
                        }
                    }
                }
            }
        }
    }
}

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects

Rectangle {
    id: aiChatRoot
    width: 280
    height: 520
    color: "transparent"
    radius: (sharedData && sharedData.quickshellBorderRadius !== undefined) ? sharedData.quickshellBorderRadius : 12

    property var sharedData: null
    property var sidePanelRoot: null
    property var popoverWindow: null
    
    // AI Config
    property string aiEndpoint: "http://127.0.0.1:11434"
    property string aiModel: "llama3"
    property var availableModels: [aiModel]
    property bool isLoading: false
    property bool isSettingsOpen: false
    property string settingsFilePath: "/home/iartwik/.config/alloy/dart_ai_settings.json"
    property bool settingsLoaded: false
    property string searxngEndpoint: ""
    property bool webSearchEnabled: false
    property string systemPrompt: ""
    property var currentXhr: null
    property string historyFilePath: "/home/iartwik/.config/alloy/dart_ai_history.json"
    property bool historyLoaded: false

    // ── Design Tokens ──
    property color dsAccent: (sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff"
    property color dsSurface: (sharedData && sharedData.colorSecondary) ? Qt.rgba(sharedData.colorSecondary.r, sharedData.colorSecondary.g, sharedData.colorSecondary.b, 1.0) : "#141414"
    property color dsBorder: Qt.rgba(1, 1, 1, 0.1)
    property real dsRadius: aiChatRoot.radius

    // ── Main Background ──
    Rectangle {
        id: mainBg
        anchors.fill: parent
        color: dsSurface
        radius: dsRadius
        border.width: 1
        border.color: dsBorder

        // ── Flush Mask Logic (FIXED) ──
        Rectangle {
            id: flushMask
            color: mainBg.color
            z: 10
            width: (sidePanelRoot && !sidePanelRoot.isHorizontal) ? parent.radius : parent.width
            height: (sidePanelRoot && sidePanelRoot.isHorizontal) ? parent.radius : parent.height
            
            anchors.right: (sidePanelRoot && sidePanelRoot.panelPosition === "right") ? parent.right : undefined
            anchors.left: (sidePanelRoot && sidePanelRoot.panelPosition === "left") ? parent.left : undefined
            anchors.bottom: (sidePanelRoot && sidePanelRoot.panelPosition === "bottom") ? parent.bottom : undefined
            anchors.top: (sidePanelRoot && sidePanelRoot.panelPosition === "top") ? parent.top : undefined
        }
    }

    Component.onCompleted: {
        try {
            var xhr = new XMLHttpRequest();
            xhr.open("GET", "file://" + settingsFilePath, false);
            xhr.send();
            if (xhr.status === 200 && xhr.responseText) {
                var parsed = JSON.parse(xhr.responseText);
                if (parsed.endpoint) aiEndpoint = parsed.endpoint;
                if (parsed.model) aiModel = parsed.model;
                if (parsed.searxng) searxngEndpoint = parsed.searxng;
                if (parsed.webSearch !== undefined) webSearchEnabled = parsed.webSearch === true;
                if (parsed.systemPrompt !== undefined) systemPrompt = parsed.systemPrompt;
            }
        } catch(e) {}
        settingsLoaded = true;
        fetchModels();

        try {
            var xhrHist = new XMLHttpRequest();
            xhrHist.open("GET", "file://" + historyFilePath, false);
            xhrHist.send();
            if (xhrHist.status === 200 && xhrHist.responseText) {
                var parsedHist = JSON.parse(xhrHist.responseText);
                if (Array.isArray(parsedHist)) {
                    for (var i = 0; i < parsedHist.length; i++) chatModel.append(parsedHist[i]);
                }
            }
        } catch(e) {}
        historyLoaded = true;
    }

    function fetchModels() {
        var xhr = new XMLHttpRequest();
        xhr.open("GET", aiEndpoint + "/api/tags");
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE && xhr.status === 200) {
                try {
                    var response = JSON.parse(xhr.responseText);
                    var models = [];
                    if (response && response.models) {
                        for (var i = 0; i < response.models.length; i++) models.push(response.models[i].name);
                    }
                    if (aiModel !== "" && models.indexOf(aiModel) === -1) models.push(aiModel);
                    availableModels = models;
                } catch(e) {}
            }
        };
        xhr.send();
    }

    function saveSettings() {
        if (!settingsLoaded || !sharedData || !sharedData.runCommand) return;
        var conf = JSON.stringify({endpoint: aiEndpoint, model: aiModel, searxng: searxngEndpoint, webSearch: webSearchEnabled, systemPrompt: systemPrompt});
        sharedData.runCommand(['sh', '-c', 'echo "' + conf.replace(/"/g, '\\"') + '" > ' + settingsFilePath]);
    }

    function saveHistory() {
        if (!historyLoaded || !sharedData || !sharedData.runCommand) return;
        var historyArr = [];
        for (var i = 0; i < chatModel.count; i++) {
            var item = chatModel.get(i);
            historyArr.push({ role: item.role, message: item.message, thought: item.thought, sources: item.sources });
        }
        var conf = JSON.stringify(historyArr);
        sharedData.runCommand(['sh', '-c', 'echo \'' + conf.replace(/'/g, "'\\''") + '\' > ' + historyFilePath]);
    }

    ListModel { id: chatModel }
    ListModel { id: attachmentModel }

    function runAndRead(cmd, callback) {
        if (!sharedData || !sharedData.runCommand) return
        var tmp = "/tmp/qs_ai_" + Math.random().toString(36).substring(7)
        sharedData.runCommand(['sh', '-c', cmd + " > " + tmp + " 2>/dev/null"], function() {
            var xhr = new XMLHttpRequest()
            xhr.open("GET", "file://" + tmp)
            xhr.onreadystatechange = function() {
                if (xhr.readyState === XMLHttpRequest.DONE) {
                    var out = (xhr.responseText || "").trim()
                    if (typeof callback === "function") callback(out)
                    sharedData.runCommand(['rm', '-f', tmp])
                }
            }
            xhr.send()
        })
    }

    function openFilePicker() {
        runAndRead("zenity --file-selection --title='Select File'", function(path) {
            if (path) addAttachment(path)
        })
    }

    function addAttachment(path) {
        var fileName = path.split('/').pop()
        var ext = fileName.split('.').pop().toLowerCase()
        var isImage = ["jpg", "jpeg", "png", "webp", "gif"].indexOf(ext) !== -1
        
        if (isImage) {
            runAndRead("base64 -w0 '" + path.replace(/'/g, "'\\''") + "'", function(base64Data) {
                if (base64Data) attachmentModel.append({ name: fileName, path: path, type: "image", content: base64Data })
            })
        } else {
            runAndRead("cat '" + path.replace(/'/g, "'\\''") + "'", function(textContent) {
                if (textContent !== undefined) attachmentModel.append({ name: fileName, path: path, type: "text", content: textContent })
            })
        }
    }

    function sendMessage(text) {
        if (!text && attachmentModel.count === 0) return;
        var msgText = text || "";
        var images = [];
        var textContext = "";
        var attachmentNames = [];
        
        for (var i = 0; i < attachmentModel.count; i++) {
            var att = attachmentModel.get(i);
            attachmentNames.push(att.name);
            if (att.type === "image") images.push(att.content);
            else if (att.type === "text") textContext += "\n--- File: " + att.name + " ---\n" + att.content + "\n";
        }
        
        var userDisplayMsg = msgText + (attachmentNames.length > 0 ? "\n\n📎 Attached: " + attachmentNames.join(", ") : "");
        chatModel.append({ role: "user", message: userDisplayMsg, thought: "", sources: "" });
        chatListView.positionViewAtEnd();
        messageInput.text = "";
        isLoading = true;
        
        var promptToSend = textContext ? "Context:\n" + textContext + "\n\nUser: " + msgText : msgText;

        if (webSearchEnabled && searxngEndpoint) {
            searchWeb(msgText, function(webContext, sources) {
                sendToOllama(webContext ? "Web Context:\n" + webContext + "\n\n" + promptToSend : promptToSend, sources, images);
            });
        } else {
            sendToOllama(promptToSend, [], images);
        }
        attachmentModel.clear();
    }

    function searchWeb(query, callback) {
        var url = searxngEndpoint.replace(/\/$/, "") + "/search?q=" + encodeURIComponent(query) + "&format=json";
        var xhr = new XMLHttpRequest();
        xhr.open("GET", url);
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE && xhr.status === 200) {
                try {
                    var data = JSON.parse(xhr.responseText);
                    var context = "";
                    var sources = [];
                    var results = data.results || [];
                    for (var i = 0; i < Math.min(results.length, 3); i++) {
                        context += "[" + (i+1) + "] " + results[i].title + "\n" + results[i].content + "\n\n";
                        sources.push({ index: i+1, title: results[i].title, url: results[i].url });
                    }
                    callback(context.trim(), sources);
                } catch(e) { callback("", []) }
            } else if (xhr.readyState === XMLHttpRequest.DONE) callback("", []);
        };
        xhr.send();
    }

    function sendToOllama(prompt, sources, images) {
        if (currentXhr) currentXhr.abort();
        var xhr = new XMLHttpRequest();
        currentXhr = xhr;
        xhr.open("POST", aiEndpoint + "/api/generate");
        xhr.setRequestHeader("Content-Type", "application/json");
        
        var payload = { model: aiModel, prompt: prompt, stream: true };
        if (images && images.length > 0) payload.images = images;
        if (systemPrompt) payload.system = systemPrompt;
        
        chatModel.append({ role: "assistant", message: "", thought: "", sources: (sources && sources.length > 0) ? JSON.stringify(sources) : "" });
        var messageIndex = chatModel.count - 1;
        var fullRawText = "";
        var processedLength = 0;
        
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) { isLoading = false; saveHistory(); }
            if (xhr.readyState === XMLHttpRequest.LOADING || xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    var newText = xhr.responseText.substring(processedLength);
                    if (!newText) return;
                    var lines = newText.split('\n');
                    for (var i = 0; i < lines.length - 1; i++) {
                        try {
                            var resp = JSON.parse(lines[i]);
                            if (resp.response) fullRawText += resp.response;
                        } catch(e) {}
                        processedLength += lines[i].length + 1;
                    }
                    
                    var thoughtText = "", msgText = fullRawText;
                    var tS = fullRawText.indexOf("<think>"), tE = fullRawText.indexOf("</think>");
                    if (tS !== -1 && tE !== -1) { thoughtText = fullRawText.substring(tS + 7, tE).trim(); msgText = fullRawText.substring(tE + 8).trim(); }
                    else if (tS !== -1) { thoughtText = fullRawText.substring(tS + 7).trim(); msgText = ""; }
                    
                    chatModel.setProperty(messageIndex, "message", msgText);
                    chatModel.setProperty(messageIndex, "thought", thoughtText);
                } else if (xhr.readyState === XMLHttpRequest.DONE) {
                    chatModel.setProperty(messageIndex, "message", "Ai connection error.");
                }
                chatListView.positionViewAtEnd();
            }
        };
        xhr.send(JSON.stringify(payload));
    }

    ColumnLayout {
        anchors.fill: parent; anchors.margins: 18; spacing: 0; z: 11

        // ── Header ──
        RowLayout {
            Layout.fillWidth: true; Layout.bottomMargin: 16; spacing: 12
            ColumnLayout {
                spacing: -2
                Text { text: isSettingsOpen ? "Settings" : "AI Chat"; color: "#ffffff"; font.pixelSize: 20; font.family: "Outfit"; font.weight: Font.Black; font.letterSpacing: -0.5 }
                Text { text: isSettingsOpen ? "Configure integration" : aiModel; color: dsAccent; font.pixelSize: 11; font.family: "Inter"; font.weight: Font.Medium; opacity: 0.8 }
            }
            Item { Layout.fillWidth: true }
            HeaderIcon { icon: "󰆴"; visible: !isSettingsOpen && chatModel.count > 0; onClicked: { chatModel.clear(); if (isLoading) currentXhr.abort(); isLoading = false; saveHistory() } }
            HeaderIcon { icon: isSettingsOpen ? "󰅖" : "󰒓"; onClicked: { isSettingsOpen = !isSettingsOpen; if (!isSettingsOpen) saveSettings() } }
        }

        // ── Content ──
        StackLayout {
            Layout.fillWidth: true; Layout.fillHeight: true
            currentIndex: isSettingsOpen ? 1 : 0
            
            ColumnLayout {
                spacing: 12
                Item {
                    Layout.fillWidth: true; Layout.fillHeight: true
                    ListView {
                        id: chatListView; anchors.fill: parent; model: chatModel; spacing: 16; clip: true; boundsBehavior: Flickable.StopAtBounds
                        ScrollBar.vertical: ScrollBar { width: 2; policy: ScrollBar.AsNeeded; contentItem: Rectangle { color: Qt.rgba(1, 1, 1, 0.1); radius: 1 } }
                        
                        delegate: ColumnLayout {
                            width: chatListView.width; spacing: 8
                            // Thinking block
                            Rectangle {
                                visible: model.thought !== ""; Layout.fillWidth: true; radius: 10; color: Qt.rgba(1, 1, 1, 0.02); border.width: 1; border.color: Qt.rgba(1, 1, 1, 0.04)
                                ColumnLayout {
                                    anchors.fill: parent; anchors.margins: 12; spacing: 4
                                    Text { text: "Thinking Process"; color: dsAccent; font.pixelSize: 9; font.weight: Font.Bold; font.family: "Inter"; opacity: 0.6 }
                                    Text { Layout.fillWidth: true; text: model.thought; color: Qt.rgba(1, 1, 1, 0.5); font.pixelSize: 11; font.italic: true; wrapMode: Text.Wrap; font.family: "Inter" }
                                }
                            }
                            // Message block
                            RowLayout {
                                Layout.fillWidth: true; Layout.alignment: model.role === "user" ? Qt.AlignRight : Qt.AlignLeft
                                Rectangle {
                                    id: msgBub
                                    Layout.maximumWidth: parent.width * 0.88
                                    implicitWidth: Math.min(parent.width * 0.88, msgDisp.implicitWidth + 28); implicitHeight: msgDisp.implicitHeight + 20
                                    radius: 12; color: model.role === "user" ? dsAccent : Qt.rgba(1, 1, 1, 0.05); border.width: model.role === "user" ? 0 : 1; border.color: dsBorder
                                    
                                    Text {
                                        id: msgDisp; anchors.centerIn: parent; width: parent.width - 28
                                        text: model.message; color: model.role === "user" ? "#000000" : "#ffffff"; font.pixelSize: 13; font.family: "Inter"; wrapMode: Text.Wrap; textFormat: Text.MarkdownText
                                    }
                                }
                            }
                        }
                    }
                }
                
                // Input Area
                ColumnLayout {
                    spacing: 10
                    Row {
                        spacing: 8; visible: attachmentModel.count > 0
                        Repeater {
                            model: attachmentModel
                            delegate: Rectangle {
                                width: 110; height: 26; radius: 6; color: Qt.rgba(1, 1, 1, 0.05); border.width: 1; border.color: dsBorder
                                RowLayout { 
                                    anchors.fill: parent
                                    anchors.margins: 6
                                    spacing: 6
                                    Text { text: "󰈙"; color: dsAccent; font.pixelSize: 12; font.family: "Material Design Icons" }
                                    Text { Layout.fillWidth: true; text: model.name; color: "#ffffff"; font.pixelSize: 10; font.family: "Inter"; elide: Text.ElideRight } 
                                }
                            }
                        }
                    }
                    Rectangle {
                        Layout.fillWidth: true; height: Math.max(48, messageInput.implicitHeight + 14); radius: 12; color: Qt.rgba(1, 1, 1, 0.03); border.width: 1; border.color: messageInput.activeFocus ? dsAccent : dsBorder
                        RowLayout {
                            anchors.fill: parent; anchors.margins: 6; spacing: 6
                            ActionIcon { icon: "󰐵"; onClicked: openFilePicker() }
                            ActionIcon { icon: "󰖟"; highlight: webSearchEnabled; highlightColor: dsAccent; onClicked: webSearchEnabled = !webSearchEnabled }
                            TextArea {
                                id: messageInput
                                Layout.fillWidth: true
                                padding: 10
                                color: "#ffffff"
                                font.pixelSize: 13
                                font.family: "Inter"
                                wrapMode: Text.Wrap
                                background: null
                                placeholderText: "Ask something..."
                                Keys.onPressed: (event) => { if (event.key === Qt.Key_Return && !(event.modifiers & Qt.ShiftModifier)) { sendMessage(text); event.accepted = true } }
                            }
                            Rectangle {
                                width: 36; height: 36; radius: 10; color: messageInput.text.trim() || attachmentModel.count > 0 ? dsAccent : Qt.rgba(1, 1, 1, 0.04)
                                Behavior on color { ColorAnimation { duration: 150 } }
                                Text { anchors.centerIn: parent; text: "󰭻"; color: messageInput.text.trim() || attachmentModel.count > 0 ? "#000000" : Qt.rgba(1, 1, 1, 0.2); font.pixelSize: 18; font.family: "Material Design Icons" }
                                MouseArea { anchors.fill: parent; onClicked: sendMessage(messageInput.text); cursorShape: Qt.PointingHandCursor }
                            }
                        }
                    }
                }
            }
            
            ScrollView {
                clip: true
                ScrollBar.vertical: ScrollBar { width: 2; policy: ScrollBar.AsNeeded }
                ColumnLayout {
                    width: parent.width; spacing: 18
                    SettingField { label: "Endpoint URL"; text: aiEndpoint; onTextChanged: { aiEndpoint = text; fetchModels(); saveSettings() } }
                    ColumnLayout {
                        spacing: 4; Layout.fillWidth: true
                        Text { text: "Target Model"; color: dsAccent; font.pixelSize: 10; font.weight: Font.Black; font.family: "Inter"; opacity: 0.6 }
                        ComboBox { 
                            Layout.fillWidth: true; model: availableModels; currentIndex: Math.max(0, availableModels.indexOf(aiModel)); 
                            onActivated: (i) => { aiModel = availableModels[i]; saveSettings() }
                            palette.window: dsSurface; palette.windowText: "#ffffff"; palette.highlight: dsAccent
                        }
                    }
                    SettingField { label: "SearXNG Host"; text: searxngEndpoint; onTextChanged: { searxngEndpoint = text; saveSettings() } }
                    ColumnLayout {
                        spacing: 6; Layout.fillWidth: true
                        Text { text: "System Guidelines"; color: dsAccent; font.pixelSize: 10; font.weight: Font.Black; font.family: "Inter"; opacity: 0.6 }
                        Rectangle { 
                            Layout.fillWidth: true; height: 100; radius: 10; color: Qt.rgba(1, 1, 1, 0.03); border.width: 1; border.color: dsBorder
                            TextArea { anchors.fill: parent; anchors.margins: 10; text: systemPrompt; color: "#ffffff"; font.pixelSize: 11; font.family: "Inter"; wrapMode: Text.Wrap; background: null; onTextChanged: { systemPrompt = text; saveSettings() } } 
                        }
                    }
                    Rectangle { 
                        Layout.fillWidth: true; height: 38; radius: 10; color: Qt.rgba(1,0,0,0.08); border.width: 1; border.color: Qt.rgba(1,0,0,0.15)
                        Text { anchors.centerIn: parent; text: "Clear History"; color: "#ff5555"; font.pixelSize: 11; font.weight: Font.Bold; font.family: "Inter" }
                        MouseArea { anchors.fill: parent; onClicked: { chatModel.clear(); saveHistory() } cursorShape: Qt.PointingHandCursor } 
                    }
                }
            }
        }
    }

    component HeaderIcon: Rectangle {
        property string icon: ""
        signal clicked()
        width: 32
        height: 32
        radius: 8
        color: hMa.containsMouse ? Qt.rgba(1,1,1,0.06) : "transparent"
        Text {
            anchors.centerIn: parent
            text: icon
            font.family: "Material Design Icons"
            color: hMa.containsMouse ? "#ffffff" : Qt.rgba(1,1,1,0.4)
            font.pixelSize: 18
        }
        MouseArea {
            id: hMa
            anchors.fill: parent
            hoverEnabled: true
            onClicked: parent.clicked()
            cursorShape: Qt.PointingHandCursor
        }
    }
    
    component ActionIcon: Rectangle {
        property string icon: ""
        property bool highlight: false
        property color highlightColor: "#ffffff"
        signal clicked()
        width: 32
        height: 32
        radius: 8
        color: aMa.containsMouse ? Qt.rgba(1,1,1,0.06) : "transparent"
        Text {
            anchors.centerIn: parent
            text: icon
            font.family: "Material Design Icons"
            color: highlight ? highlightColor : (aMa.containsMouse ? "#ffffff" : Qt.rgba(1,1,1,0.3))
            font.pixelSize: 20
        }
        MouseArea {
            id: aMa
            anchors.fill: parent
            hoverEnabled: true
            onClicked: parent.clicked()
            cursorShape: Qt.PointingHandCursor
        }
    }
    
    component SettingField: ColumnLayout {
        property string label: ""
        property string text: ""
        spacing: 6
        Layout.fillWidth: true
        Text {
            text: label
            color: dsAccent
            font.pixelSize: 10
            font.weight: Font.Black
            font.family: "Inter"
            opacity: 0.6
        }
        Rectangle { 
            Layout.fillWidth: true
            height: 38
            radius: 10
            color: Qt.rgba(1,1,1,0.03)
            border.width: 1
            border.color: inF.activeFocus ? dsAccent : dsBorder
            TextInput {
                id: inF
                anchors.fill: parent
                anchors.margins: 10
                verticalAlignment: TextInput.AlignVCenter
                color: "#ffffff"
                font.pixelSize: 12
                font.family: "Inter"
                text: parent.parent.text
                onTextChanged: parent.parent.text = text
                selectByMouse: true
            } 
        }
    }
}

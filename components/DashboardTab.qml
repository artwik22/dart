import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "."

Item {
    id: dashboardTabRoot
    property var sharedData: null
    property int currentTab: 0
    property real showProgress: 1.0
    
    // Battery/Network
    property int batteryPercent: -1
    property bool isCharging: false
    property real networkRxMBs: 0
    property real networkTxMBs: 0
    
    // Weather
    property string weatherTemp: "--"
    property string weatherCondition: "Loading..."
    signal updateWeatherRequested()
    
    // Calendar
    property var calendarDays: []
    
    // Resource Metrics
    property var getResourceIcon: function(res) { return "󰓅" }
    property var getResourceLabel: function(res) { return res }
    property var getResourceValueText: function(res) { return "--" }
    property var getResourceSubText: function(res) { return "" }
    property var getResourceHistory: function(res) { return [] }
    
    // Media Player
    property string mpTitle: ""
    property string mpArtist: ""
    property string mpArt: ""
    property bool mpPlaying: false
    property real mpPosition: 0
    property int mpLength: 0
    property var cavaValues: []
    property var formatTime: function(sec) { return "00:00" }
    signal playerPrevRequested()
    signal playerPlayPauseRequested()
    signal playerNextRequested()

    anchors.fill: parent
    visible: currentTab === 0
    opacity: currentTab === 0 ? 1.0 : 0.0
    x: currentTab === 0 ? 0 : (currentTab < 0 ? -parent.width * 0.3 : parent.width * 0.3)
    scale: currentTab === 0 ? 1.0 : 0.95
    
    Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
    Behavior on x { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
    Behavior on scale { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }

    ColumnLayout {
        id: dashboardTabColumn
        anchors.fill: parent
        anchors.margins: 12
        spacing: 5
        
        // Row with left tile (Battery or Network) and Quick Actions side by side
        RowLayout {
            id: topRow
            Layout.fillWidth: true
            Layout.preferredHeight: 75
            spacing: 8
            
            opacity: showProgress > 0.01 ? 1.0 : 0.0
            scale: showProgress > 0.01 ? 1.0 : 0.9
            transform: Translate {
                y: showProgress > 0.01 ? 0 : 40
                Behavior on y {
                    SequentialAnimation {
                        PauseAnimation { duration: 50 }
                        NumberAnimation { duration: 700; easing.type: Easing.OutBack }
                    }
                }
            }
            
            Behavior on opacity {
                SequentialAnimation {
                    PauseAnimation { duration: 50 }
                    NumberAnimation { duration: 500; easing.type: Easing.OutCubic }
                }
            }
            Behavior on scale {
                SequentialAnimation {
                    PauseAnimation { duration: 50 }
                    NumberAnimation { duration: 600; easing.type: Easing.OutBack }
                }
            }

            // Left tile container: Battery or Network
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: (parent.width - 8) / 2
                
                Rectangle {
                    anchors.fill: parent
                    visible: !(sharedData && sharedData.dashboardTileLeft === "network")
                    radius: (sharedData && sharedData.quickshellBorderRadius !== undefined) ? sharedData.quickshellBorderRadius : 24
                    color: (sharedData && sharedData.colorSecondary) ? sharedData.colorSecondary : "#1c1c1c"

                    Item {
                        scale: batMouseArea.containsMouse ? 1.05 : 1.0
                        Behavior on scale { SpringAnimation { spring: 3; damping: 0.4; mass: 0.8 } }
                        anchors.fill: parent; anchors.margins: 12

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: batMouseArea.containsMouse ? -3 : -1
                            color: Qt.rgba(0, 0, 0, batMouseArea.containsMouse ? 0.25 : 0.15)
                            radius: parent.parent.radius + (batMouseArea.containsMouse ? 3 : 1)
                            z: -1
                            Behavior on anchors.margins { NumberAnimation { duration: 150 } }
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }

                        MouseArea { id: batMouseArea; anchors.fill: parent; hoverEnabled: true }

                        Row {
                            anchors.centerIn: parent; anchors.verticalCenterOffset: -6; spacing: 6
                            Text {
                                text: isCharging ? "⚡" : ""
                                font.pixelSize: 22
                                color: (batteryPercent > 20 || isCharging) ? ((sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff") : "#FF4444" 
                                visible: batteryPercent > 0; anchors.verticalCenter: parent.verticalCenter
                            }
                            Text {
                                text: (batteryPercent >= 0 ? batteryPercent + "%" : "--")
                                font.pixelSize: 24; font.weight: Font.Bold; font.family: "sans-serif"
                                color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff"; anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                        Item {
                            anchors.bottom: parent.bottom; width: parent.width; height: 14
                            Rectangle { anchors.fill: parent; radius: height/2; color: (sharedData && sharedData.colorText) ? Qt.alpha(sharedData.colorText, 0.15) : "#333333" }
                            Rectangle {
                                height: parent.height; width: parent.width * (Math.max(0, Math.min(batteryPercent, 100)) / 100); radius: height/2
                                color: (batteryPercent <= 20) ? "#FF4444" : ((sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff")
                                Behavior on width { NumberAnimation { duration: 500; easing.type: Easing.OutExpo } }
                            }
                        }
                    }
                }
            
                Rectangle {
                    anchors.fill: parent
                    visible: (sharedData && sharedData.dashboardTileLeft === "network")
                    radius: (sharedData && sharedData.quickshellBorderRadius !== undefined) ? sharedData.quickshellBorderRadius : 24
                    color: (sharedData && sharedData.colorSecondary) ? sharedData.colorSecondary : "#1c1c1c"
                    Item {
                        anchors.fill: parent; anchors.margins: 12
                        scale: netMouseArea.containsMouse ? 1.02 : 1.0
                        Behavior on scale { SpringAnimation { spring: 3; damping: 0.4; mass: 0.8 } }
                        Rectangle {
                            anchors.fill: parent; anchors.margins: netMouseArea.containsMouse ? -3 : -1
                            color: Qt.rgba(0, 0, 0, netMouseArea.containsMouse ? 0.25 : 0.15)
                            radius: parent.parent.radius + (netMouseArea.containsMouse ? 3 : 1)
                            z: -1
                            Behavior on anchors.margins { NumberAnimation { duration: 150 } }
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                        MouseArea { id: netMouseArea; anchors.fill: parent; hoverEnabled: true }
                        Row {
                            anchors.centerIn: parent; spacing: 12; height: parent.height; width: parent.width
                            Item {
                                width: 32; height: parent.height
                                Rectangle { anchors.fill: parent; radius: width / 2; color: (sharedData && sharedData.colorPrimary) ? sharedData.colorPrimary : "#1a1a1a"; opacity: 0.8 }
                                Rectangle {
                                    width: parent.width; height: parent.height * Math.min(1.0, Math.log10(Math.max(1, networkRxMBs * 10)) / 3) 
                                    anchors.bottom: parent.bottom; radius: width / 2; color: (sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff"
                                    Behavior on height { NumberAnimation { duration: 300 } }
                                }
                                Text {
                                    anchors.bottom: parent.bottom; anchors.bottomMargin: 8; anchors.horizontalCenter: parent.horizontalCenter; text: "↓"; font.bold: true
                                    color: (sharedData && sharedData.colorBackground) ? sharedData.colorBackground : "#000000"
                                    visible: parent.height * Math.min(1.0, Math.log10(Math.max(1, networkRxMBs * 10)) / 3) > 20
                                }
                                Text {
                                    anchors.bottom: parent.bottom; anchors.bottomMargin: 8; anchors.horizontalCenter: parent.horizontalCenter; text: "↓"; font.bold: true
                                    color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff"
                                    visible: parent.height * Math.min(1.0, Math.log10(Math.max(1, networkRxMBs * 10)) / 3) <= 20
                                }
                            }
                            Item {
                                width: 32; height: parent.height
                                Rectangle { anchors.fill: parent; radius: width / 2; color: (sharedData && sharedData.colorPrimary) ? sharedData.colorPrimary : "#1a1a1a"; opacity: 0.8 }
                                Rectangle {
                                    width: parent.width; height: parent.height * Math.min(1.0, Math.log10(Math.max(1, networkTxMBs * 10)) / 3)
                                    anchors.bottom: parent.bottom; radius: width / 2; color: (sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff"; opacity: 0.7
                                    Behavior on height { NumberAnimation { duration: 300 } }
                                }
                                Text {
                                    anchors.bottom: parent.bottom; anchors.bottomMargin: 8; anchors.horizontalCenter: parent.horizontalCenter; text: "↑"; font.bold: true
                                    color: (sharedData && sharedData.colorBackground) ? sharedData.colorBackground : "#000000"
                                    visible: parent.height * Math.min(1.0, Math.log10(Math.max(1, networkTxMBs * 10)) / 3) > 20
                                }
                                Text {
                                    anchors.bottom: parent.bottom; anchors.bottomMargin: 8; anchors.horizontalCenter: parent.horizontalCenter; text: "↑"; font.bold: true
                                    color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff"
                                    visible: parent.height * Math.min(1.0, Math.log10(Math.max(1, networkTxMBs * 10)) / 3) <= 20
                                }
                            }
                        }
                    }
                }
            }

            // Quick Actions Card
            Rectangle {
                Layout.fillWidth: true; Layout.fillHeight: true; Layout.preferredWidth: (parent.width - 8) / 2
                radius: (sharedData && sharedData.quickshellBorderRadius !== undefined) ? sharedData.quickshellBorderRadius : 24
                color: (sharedData && sharedData.colorSecondary) ? sharedData.colorSecondary : "#1c1c1c"
                scale: quickActionsMouseArea.containsMouse ? 1.05 : 1.0
                Behavior on scale { SpringAnimation { spring: 3; damping: 0.4; mass: 0.8 } }
                MouseArea { id: quickActionsMouseArea; anchors.fill: parent; hoverEnabled: true; z: -1 }
                Rectangle {
                    anchors.fill: parent; anchors.margins: quickActionsMouseArea.containsMouse ? -3 : -1
                    color: Qt.rgba(0, 0, 0, quickActionsMouseArea.containsMouse ? 0.25 : 0.15)
                    radius: parent.radius + (quickActionsMouseArea.containsMouse ? 3 : 1)
                    z: -1
                    Behavior on anchors.margins { NumberAnimation { duration: 150 } }
                    Behavior on color { ColorAnimation { duration: 150 } }
                }
                GridLayout {
                    anchors.fill: parent; anchors.margins: 12; columns: 2; rows: 2; columnSpacing: 10; rowSpacing: 10
                    Rectangle {
                        Layout.fillWidth: true; Layout.fillHeight: true; radius: 4; clip: true
                        color: toggleSidebarQuickMouseArea.containsMouse ? Qt.rgba(1,1,1,0.2) : Qt.rgba(1,1,1,0.1)
                        Text { anchors.centerIn: parent; text: "󰍜"; font.pixelSize: 22; font.family: "Material Design Icons"; color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff" }
                        MouseArea { id: toggleSidebarQuickMouseArea; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; hoverEnabled: true; onClicked: { if (sharedData && sharedData.sidebarVisible !== undefined) sharedData.sidebarVisible = !sharedData.sidebarVisible } }
                    }
                    Rectangle {
                        Layout.fillWidth: true; Layout.fillHeight: true; radius: 4; clip: true
                        color: ((dndQuickMouseArea.containsMouse) || (sharedData && sharedData.notificationsEnabled === false)) ? ((sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#00ff41") : Qt.rgba(1,1,1,0.1)
                        Text {
                            anchors.centerIn: parent; text: "󰂛"; font.pixelSize: 22; font.family: "Material Design Icons"
                            color: ((dndQuickMouseArea.containsMouse) || (sharedData && sharedData.notificationsEnabled === false)) ? ((sharedData && sharedData.colorBackground) ? sharedData.colorBackground : "#ffffff") : ((sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff")
                        }
                        MouseArea { id: dndQuickMouseArea; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; hoverEnabled: true; onClicked: { if (sharedData && sharedData.notificationsEnabled !== undefined) sharedData.notificationsEnabled = !sharedData.notificationsEnabled } }
                    }
                    Rectangle {
                        Layout.fillWidth: true; Layout.fillHeight: true; radius: 4; clip: true
                        color: lockQuickMouseArea.containsMouse ? Qt.rgba(1,1,1,0.2) : Qt.rgba(1,1,1,0.1)
                        Text { anchors.centerIn: parent; text: "󰌾"; font.pixelSize: 22; font.family: "Material Design Icons"; color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff" }
                        MouseArea {
                            id: lockQuickMouseArea; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                            onClicked: {
                                if (sharedData) {
                                    sharedData.lockScreenNonBlocking = false; sharedData.lockScreenVisible = true
                                    if (sharedData.runCommand) sharedData.runCommand(['sh', '-c', 'sleep 0.1'])
                                    sharedData.menuVisible = false
                                }
                            }
                        }
                    }
                    Rectangle {
                        Layout.fillWidth: true; Layout.fillHeight: true; radius: 4; clip: true
                        color: poweroffQuickMouseArea.containsMouse ? "#FF4444" : Qt.rgba(1,1,1,0.1)
                        Text { anchors.centerIn: parent; text: "󰐥"; font.pixelSize: 22; font.family: "Material Design Icons"; color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff" }
                        MouseArea { id: poweroffQuickMouseArea; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; hoverEnabled: true; onClicked: { if (sharedData && sharedData.runCommand) sharedData.runCommand(['systemctl', 'poweroff']); if (sharedData) sharedData.menuVisible = false } }
                    }
                }
            }
        }
        
        // Weather + Clock Row
        RowLayout {
            id: weatherClockRow; Layout.fillWidth: true; Layout.preferredHeight: 55; spacing: 8
            opacity: showProgress > 0.01 ? 1.0 : 0.0
            transform: Translate { y: showProgress > 0.01 ? 0 : 40; Behavior on y { SequentialAnimation { PauseAnimation { duration: 75 }; NumberAnimation { duration: 700; easing.type: Easing.OutBack } } } }
            Behavior on opacity { SequentialAnimation { PauseAnimation { duration: 75 }; NumberAnimation { duration: 500; easing.type: Easing.OutCubic } } }
            
            Rectangle {
                id: weatherCard; Layout.fillWidth: true; Layout.fillHeight: true; Layout.preferredWidth: (parent.width - 8) / 2
                radius: (sharedData && sharedData.quickshellBorderRadius !== undefined) ? sharedData.quickshellBorderRadius : 14
                color: (sharedData && sharedData.colorSecondary) ? sharedData.colorSecondary : "#1c1c1c"
                scale: weatherMouseArea.containsMouse ? 1.05 : 1.0
                Behavior on scale { SpringAnimation { spring: 3; damping: 0.4; mass: 0.8 } }
                Rectangle {
                    anchors.fill: parent; anchors.margins: weatherMouseArea.containsMouse ? -3 : -1
                    color: Qt.rgba(0, 0, 0, weatherMouseArea.containsMouse ? 0.25 : 0.15)
                    radius: parent.radius + (weatherMouseArea.containsMouse ? 3 : 1)
                    z: -1
                    Behavior on anchors.margins { NumberAnimation { duration: 150 } }
                    Behavior on color { ColorAnimation { duration: 150 } }
                }
                MouseArea { id: weatherMouseArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: updateWeatherRequested() }
                ColumnLayout {
                    anchors.fill: parent; anchors.margins: 6; spacing: 0
                    Item { Layout.fillHeight: true }
                    Text {
                        text: {
                            var cond = weatherCondition.toLowerCase()
                            if (cond.indexOf("sun") !== -1 || cond.indexOf("clear") !== -1) return "󰖙"
                            if (cond.indexOf("cloud") !== -1) return "󰖐"
                            if (cond.indexOf("rain") !== -1) return "󰖗"
                            if (cond.indexOf("snow") !== -1) return "󰼶"
                            if (cond.indexOf("storm") !== -1 || cond.indexOf("thunder") !== -1) return "󰖓"
                            return "󰖕"
                        }
                        font.pixelSize: 18; color: (sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff"; Layout.alignment: Qt.AlignHCenter
                    }
                    Text { text: weatherTemp; font.pixelSize: 16; font.weight: Font.Bold; font.family: "sans-serif"; color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff"; Layout.alignment: Qt.AlignHCenter }
                    Item { Layout.fillHeight: true }
                }
            }
            
            Rectangle {
                id: clockCard; Layout.fillWidth: true; Layout.fillHeight: true; Layout.preferredWidth: (parent.width - 8) / 2
                radius: (sharedData && sharedData.quickshellBorderRadius !== undefined) ? sharedData.quickshellBorderRadius : 14
                color: (sharedData && sharedData.colorSecondary) ? sharedData.colorSecondary : "#1c1c1c"
                property string currentTime: Qt.formatDateTime(new Date(), "HH:mm")
                property string currentDate: Qt.formatDateTime(new Date(), "ddd, MMM d")
                Timer { interval: 1000; running: true; repeat: true; onTriggered: { clockCard.currentTime = Qt.formatDateTime(new Date(), "HH:mm"); clockCard.currentDate = Qt.formatDateTime(new Date(), "ddd, MMM d") } }
                scale: clockMouseArea.containsMouse ? 1.05 : 1.0
                Behavior on scale { SpringAnimation { spring: 3; damping: 0.4; mass: 0.8 } }
                MouseArea { id: clockMouseArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor }
                ColumnLayout {
                    anchors.fill: parent; anchors.margins: 6; spacing: 2
                    Item { Layout.fillHeight: true }
                    Text { text: clockCard.currentTime; font.pixelSize: 18; font.weight: Font.Bold; font.family: "sans-serif"; color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff"; Layout.alignment: Qt.AlignHCenter }
                    Text { text: clockCard.currentDate.toUpperCase(); font.pixelSize: 9; font.weight: Font.Black; font.family: "sans-serif"; font.letterSpacing: 1; color: (sharedData && sharedData.colorText) ? Qt.alpha(sharedData.colorText, 0.5) : "#888888"; Layout.alignment: Qt.AlignHCenter }
                    Item { Layout.fillHeight: true }
                }
            }
        }
        
        // Date/Calendar Card
        Rectangle {
            id: calendarGithubCard; Layout.fillWidth: true; Layout.fillHeight: true; Layout.preferredHeight: 180; Layout.minimumHeight: 150
            radius: (sharedData && sharedData.quickshellBorderRadius !== undefined) ? sharedData.quickshellBorderRadius : 28
            color: (sharedData && sharedData.colorSecondary) ? sharedData.colorSecondary : "#141414"
            opacity: showProgress > 0.01 ? 1.0 : 0.0
            scale: calendarGithubMouseArea.containsMouse ? 1.02 : (showProgress > 0.01 ? 1.0 : 0.9)
            transform: Translate { y: showProgress > 0.01 ? 0 : 40; Behavior on y { SequentialAnimation { PauseAnimation { duration: 100 }; NumberAnimation { duration: 700; easing.type: Easing.OutBack } } } }
            Behavior on opacity { SequentialAnimation { PauseAnimation { duration: 100 }; NumberAnimation { duration: 500; easing.type: Easing.OutCubic } } }
            Behavior on scale { SpringAnimation { spring: 3; damping: 0.4; mass: 0.8 } }
            MouseArea { id: calendarGithubMouseArea; anchors.fill: parent; hoverEnabled: true }
            Rectangle {
                anchors.fill: parent; anchors.margins: calendarGithubMouseArea.containsMouse ? -3 : -1
                color: Qt.rgba(0, 0, 0, calendarGithubMouseArea.containsMouse ? 0.25 : 0.15)
                radius: parent.radius + (calendarGithubMouseArea.containsMouse ? 3 : 1)
                z: -1
                Behavior on anchors.margins { NumberAnimation { duration: 150 } }
                Behavior on color { ColorAnimation { duration: 150 } }
            }
            Loader {
                anchors.fill: parent; anchors.margins: 16; active: true
                sourceComponent: (sharedData && sharedData.sidepanelContent === "github") ? githubActivityDashboardComponent : calendarDashboardComponent
            }
        }

        Component {
            id: calendarDashboardComponent
            Item {
                anchors.fill: parent
                Column {
                    anchors.fill: parent; spacing: 5
                    Row {
                        spacing: 5; anchors.horizontalCenter: parent.horizontalCenter
                        Repeater {
                            model: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
                            Text { text: modelData; font.pixelSize: 9; font.weight: Font.Bold; font.family: "sans-serif"; color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#000000"; width: 22; horizontalAlignment: Text.AlignHCenter }
                        }
                    }
                    Grid {
                        columns: 7; spacing: 5; anchors.horizontalCenter: parent.horizontalCenter
                        Repeater {
                            model: calendarDays
                            Rectangle {
                                width: 22; height: 22; radius: (sharedData && sharedData.quickshellBorderRadius !== undefined) ? sharedData.quickshellBorderRadius : 0
                                color: modelData.isToday ? ((sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff") : "transparent"
                                Text {
                                    text: modelData.day; font.pixelSize: 10; font.family: "sans-serif"
                                    color: modelData.isToday ? ((sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff") : (modelData.isCurrentMonth ? ((sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff") : ((sharedData && sharedData.colorText) ? Qt.lighter(sharedData.colorText, 1.5) : "#888888"))
                                    anchors.centerIn: parent
                                }
                            }
                        }
                    }
                }
            }
        }

        Component { id: githubActivityDashboardComponent; GithubActivity { sharedData: dashboardTabRoot.sharedData } }
        
        // Resource 1 Card
        Rectangle {
            id: res1Card; Layout.fillWidth: true; Layout.fillHeight: true; Layout.preferredHeight: 150; Layout.minimumHeight: 130
            radius: (sharedData && sharedData.quickshellBorderRadius !== undefined) ? sharedData.quickshellBorderRadius : 28
            color: (sharedData && sharedData.colorSecondary) ? sharedData.colorSecondary : "#141414"
            scale: res1MouseArea.containsMouse ? 1.02 : (showProgress > 0.01 ? 1.0 : 0.9)
            Behavior on scale { SpringAnimation { spring: 3; damping: 0.4; mass: 0.8 } }
            MouseArea { id: res1MouseArea; anchors.fill: parent; hoverEnabled: true; z: -1 }
            Rectangle {
                anchors.fill: parent; anchors.margins: res1MouseArea.containsMouse ? -3 : -1
                color: Qt.rgba(0, 0, 0, res1MouseArea.containsMouse ? 0.25 : 0.15); radius: parent.radius + (res1MouseArea.containsMouse ? 3 : 1); z: -1
                Behavior on anchors.margins { NumberAnimation { duration: 150 } }; Behavior on color { ColorAnimation { duration: 150 } }
            }
            property string resource: (sharedData && sharedData.dashboardResource1) ? sharedData.dashboardResource1 : "cpu"
            opacity: showProgress > 0.01 ? 1.0 : 0.0
            transform: Translate { y: showProgress > 0.01 ? 0 : 40; Behavior on y { SequentialAnimation { PauseAnimation { duration: 150 }; NumberAnimation { duration: 700; easing.type: Easing.OutBack } } } }
            Behavior on opacity { SequentialAnimation { PauseAnimation { duration: 150 }; NumberAnimation { duration: 500; easing.type: Easing.OutCubic } } }
            Column {
                anchors.fill: parent; anchors.margins: 12; spacing: 5
                Row {
                    spacing: 5
                    Text { text: getResourceIcon(parent.parent.resource); font.pixelSize: 12; color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff"; anchors.verticalCenter: parent.verticalCenter }
                    Text { text: getResourceLabel(parent.parent.resource).toUpperCase(); font.pixelSize: 11; font.family: "sans-serif"; font.weight: Font.Bold; color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#000000"; anchors.verticalCenter: parent.verticalCenter }
                    Text { text: getResourceValueText(parent.parent.resource); font.pixelSize: 11; font.family: "sans-serif"; font.weight: Font.Bold; color: (sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#00ff41"; anchors.verticalCenter: parent.verticalCenter }
                    Text { text: getResourceSubText(parent.parent.resource); font.pixelSize: 10; font.family: "sans-serif"; color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#000000"; anchors.verticalCenter: parent.verticalCenter; visible: text !== "" }
                }
                Canvas {
                    id: res1Chart; width: parent.width; height: 128
                    onPaint: {
                        var ctx = getContext("2d"); ctx.clearRect(0, 0, width, height);
                        var hist = getResourceHistory(parent.parent.resource); if (!hist || hist.length < 2) return;
                        var chartWidth = width; var chartHeight = height; var maxValue = 100;
                        if (parent.parent.resource === "network") { var max = 1.0; for(var k=0; k<hist.length; k++) if(hist[k] > max) max = hist[k]; maxValue = max * 1.2 }
                        ctx.fillStyle = (sharedData && sharedData.colorSecondary) ? sharedData.colorSecondary : "#141414"; ctx.fillRect(0, 0, chartWidth, chartHeight);
                        ctx.strokeStyle = (sharedData && sharedData.colorPrimary) ? sharedData.colorPrimary : "#2a2a2a"; ctx.lineWidth = 1;
                        for (var i = 0; i <= 4; i++) { var y = (chartHeight / 4) * i; ctx.beginPath(); ctx.moveTo(0, y); ctx.lineTo(chartWidth, y); ctx.stroke(); }
                        ctx.strokeStyle = (sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff"; ctx.lineWidth = 2; ctx.beginPath();
                        var stepX = chartWidth / (Math.max(hist.length, 2) - 1); function getY(val) { return chartHeight - (val / maxValue) * chartHeight }
                        ctx.moveTo(0, getY(hist[0]));
                        for (var j = 1; j < hist.length - 2; j++) { var xc = (j * stepX + (j + 1) * stepX) / 2; var yc = (getY(hist[j]) + getY(hist[j+1])) / 2; ctx.quadraticCurveTo(j * stepX, getY(hist[j]), xc, yc) }
                        if (hist.length > 2) { var lastIdx = hist.length - 2; ctx.quadraticCurveTo(lastIdx * stepX, getY(hist[lastIdx]), (lastIdx+1) * stepX, getY(hist[lastIdx+1])) } else if (hist.length === 2) { ctx.lineTo(stepX, getY(hist[1])) }
                        ctx.stroke(); ctx.lineTo(chartWidth, chartHeight); ctx.lineTo(0, chartHeight); ctx.closePath(); ctx.fillStyle = (sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff"; ctx.globalAlpha = 0.15; ctx.fill(); ctx.globalAlpha = 1.0;
                    }
                    function refresh() { requestPaint() }
                }
            }
        }
        
        // Resource 2 Card
        Rectangle {
            id: res2Card; Layout.fillWidth: true; Layout.fillHeight: true; Layout.preferredHeight: 150; Layout.minimumHeight: 130
            radius: (sharedData && sharedData.quickshellBorderRadius !== undefined) ? sharedData.quickshellBorderRadius : 28
            color: (sharedData && sharedData.colorSecondary) ? sharedData.colorSecondary : "#141414"
            scale: res2MouseArea.containsMouse ? 1.02 : (showProgress > 0.01 ? 1.0 : 0.9)
            Behavior on scale { SpringAnimation { spring: 3; damping: 0.4; mass: 0.8 } }
            MouseArea { id: res2MouseArea; anchors.fill: parent; hoverEnabled: true; z: -1 }
            Rectangle {
                anchors.fill: parent; anchors.margins: res2MouseArea.containsMouse ? -3 : -1
                color: Qt.rgba(0, 0, 0, res2MouseArea.containsMouse ? 0.25 : 0.15); radius: parent.radius + (res2MouseArea.containsMouse ? 3 : 1); z: -1
                Behavior on anchors.margins { NumberAnimation { duration: 150 } }; Behavior on color { ColorAnimation { duration: 150 } }
            }
            property string resource: (sharedData && sharedData.dashboardResource2) ? sharedData.dashboardResource2 : "ram"
            opacity: showProgress > 0.01 ? 1.0 : 0.0
            transform: Translate { y: showProgress > 0.01 ? 0 : 40; Behavior on y { SequentialAnimation { PauseAnimation { duration: 200 }; NumberAnimation { duration: 700; easing.type: Easing.OutBack } } } }
            Behavior on opacity { SequentialAnimation { PauseAnimation { duration: 200 }; NumberAnimation { duration: 500; easing.type: Easing.OutCubic } } }
            Column {
                anchors.fill: parent; anchors.margins: 12; spacing: 5
                Row {
                    spacing: 5
                    Text { text: getResourceIcon(parent.parent.resource); font.pixelSize: 12; color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff"; anchors.verticalCenter: parent.verticalCenter }
                    Text { text: getResourceLabel(parent.parent.resource).toUpperCase(); font.pixelSize: 11; font.family: "sans-serif"; font.weight: Font.Bold; color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#000000"; anchors.verticalCenter: parent.verticalCenter }
                    Text { text: getResourceValueText(parent.parent.resource); font.pixelSize: 11; font.family: "sans-serif"; font.weight: Font.Bold; color: (sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#00ff41"; anchors.verticalCenter: parent.verticalCenter }
                    Text { text: getResourceSubText(parent.parent.resource); font.pixelSize: 10; font.family: "sans-serif"; color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#000000"; anchors.verticalCenter: parent.verticalCenter; visible: text !== "" }
                }
                Canvas {
                    id: res2Chart; width: parent.width; height: 128
                    onPaint: {
                        var ctx = getContext("2d"); ctx.clearRect(0, 0, width, height);
                        var hist = getResourceHistory(parent.parent.resource); if (!hist || hist.length < 2) return;
                        var chartWidth = width; var chartHeight = height; var maxValue = 100;
                        if (parent.parent.resource === "network") { var max = 1.0; for(var k=0; k<hist.length; k++) if(hist[k] > max) max = hist[k]; maxValue = max * 1.2 }
                        ctx.fillStyle = (sharedData && sharedData.colorSecondary) ? sharedData.colorSecondary : "#141414"; ctx.fillRect(0, 0, chartWidth, chartHeight);
                        ctx.strokeStyle = (sharedData && sharedData.colorPrimary) ? sharedData.colorPrimary : "#2a2a2a"; ctx.lineWidth = 1;
                        for (var i = 0; i <= 4; i++) { var y = (chartHeight / 4) * i; ctx.beginPath(); ctx.moveTo(0, y); ctx.lineTo(chartWidth, y); ctx.stroke(); }
                        ctx.strokeStyle = (sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff"; ctx.lineWidth = 2; ctx.beginPath();
                        var stepX = chartWidth / (Math.max(hist.length, 2) - 1); function getY(val) { return chartHeight - (val / maxValue) * chartHeight }
                        ctx.moveTo(0, getY(hist[0]));
                        for (var j = 1; j < hist.length - 2; j++) { var xc = (j * stepX + (j + 1) * stepX) / 2; var yc = (getY(hist[j]) + getY(hist[j+1])) / 2; ctx.quadraticCurveTo(j * stepX, getY(hist[j]), xc, yc) }
                        if (hist.length > 2) { var lastIdx = hist.length - 2; ctx.quadraticCurveTo(lastIdx * stepX, getY(hist[lastIdx]), (lastIdx+1) * stepX, getY(hist[lastIdx+1])) } else if (hist.length === 2) { ctx.lineTo(stepX, getY(hist[1])) }
                        ctx.stroke(); ctx.lineTo(chartWidth, chartHeight); ctx.lineTo(0, chartHeight); ctx.closePath(); ctx.fillStyle = (sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff"; ctx.globalAlpha = 0.15; ctx.fill(); ctx.globalAlpha = 1.0;
                    }
                    function refresh() { requestPaint() }
                }
            }
        }
        
        // Media Player Card
        Rectangle {
            id: mediaPlayerCard; Layout.fillWidth: true; Layout.preferredHeight: 140
            radius: (sharedData && sharedData.quickshellBorderRadius !== undefined) ? sharedData.quickshellBorderRadius : 28
            color: (sharedData && sharedData.colorSecondary) ? sharedData.colorSecondary : "#141414"
            opacity: showProgress > 0.01 ? 1.0 : 0.0
            scale: mediaMouseArea.containsMouse ? 1.02 : (showProgress > 0.01 ? 1.0 : 0.9)
            transform: Translate { y: showProgress > 0.01 ? 0 : 40; Behavior on y { SequentialAnimation { PauseAnimation { duration: 250 }; NumberAnimation { duration: 700; easing.type: Easing.OutBack } } } }
            Behavior on opacity { SequentialAnimation { PauseAnimation { duration: 250 }; NumberAnimation { duration: 500; easing.type: Easing.OutCubic } } }
            Behavior on scale { SpringAnimation { spring: 3; damping: 0.4; mass: 0.8 } }
            MouseArea { id: mediaMouseArea; anchors.fill: parent; hoverEnabled: true }
            Rectangle {
                anchors.fill: parent; anchors.margins: mediaMouseArea.containsMouse ? -3 : -1
                color: Qt.rgba(0, 0, 0, mediaMouseArea.containsMouse ? 0.25 : 0.15); radius: parent.radius + (mediaMouseArea.containsMouse ? 3 : 1); z: -1
                Behavior on anchors.margins { NumberAnimation { duration: 150 } }; Behavior on color { ColorAnimation { duration: 150 } }
            }
            Row {
                anchors.fill: parent; anchors.margins: 2; anchors.bottomMargin: -2; spacing: 2; opacity: mpPlaying ? 0.15 : 0; visible: opacity > 0; z: 0
                Behavior on opacity { NumberAnimation { duration: 1000 } }
                Repeater {
                    model: 36
                    Rectangle {
                        width: (parent.width - (35 * 2)) / 36; height: (cavaValues && cavaValues.length > index) ? Math.max(2, (parseInt(cavaValues[index]) || 0) / 100 * parent.height) : 0
                        color: (sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff"; radius: 1; anchors.bottom: parent.bottom
                        Behavior on height { NumberAnimation { duration: 100; easing.type: Easing.OutQuint } }
                    }
                }
            }
            ColumnLayout {
                anchors.fill: parent; anchors.margins: 16; spacing: 12
                RowLayout {
                    Layout.fillWidth: true; Layout.preferredHeight: 100; spacing: 16
                    Rectangle {
                        Layout.preferredWidth: 100; Layout.preferredHeight: 100; radius: (sharedData && sharedData.quickshellBorderRadius !== undefined) ? Math.min(sharedData.quickshellBorderRadius, 12) : 8; color: (sharedData && sharedData.colorPrimary) ? sharedData.colorPrimary : "#1a1a1a"; clip: true
                        Image { anchors.fill: parent; source: mpArt ? mpArt : ""; fillMode: Image.PreserveAspectCrop; asynchronous: true; opacity: source != "" ? 1.0 : 0.0; Behavior on opacity { NumberAnimation { duration: 400 } } }
                        Text { anchors.centerIn: parent; text: "󰃆"; font.pixelSize: 36; color: (sharedData && sharedData.colorText) ? Qt.alpha(sharedData.colorText, 0.4) : "#333333"; visible: !mpArt }
                    }
                    ColumnLayout {
                        Layout.fillWidth: true; Layout.fillHeight: true; spacing: 10
                        ColumnLayout {
                            Layout.fillWidth: true; spacing: 2
                            Text { text: mpTitle ? mpTitle : "NOTHING PLAYING"; font.pixelSize: 14; font.weight: Font.Bold; font.family: "sans-serif"; color: (sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff"; elide: Text.ElideRight; Layout.fillWidth: true }
                            Text { text: mpArtist ? mpArtist : "Unknown Artist"; font.pixelSize: 11; font.family: "sans-serif"; color: (sharedData && sharedData.colorText) ? Qt.alpha(sharedData.colorText, 0.6) : "#888888"; elide: Text.ElideRight; Layout.fillWidth: true }
                        }
                        Item { Layout.fillHeight: true }
                        RowLayout {
                            Layout.fillWidth: true; spacing: 16; Item { Layout.fillWidth: true }
                            Rectangle {
                                width: 38; height: 38; radius: (sharedData && sharedData.quickshellBorderRadius !== undefined) ? Math.min(sharedData.quickshellBorderRadius, 10) : 10; color: prevMa.containsMouse ? Qt.rgba(1,1,1,0.15) : "transparent"
                                Text { anchors.centerIn: parent; text: "󰒮"; font.pixelSize: 20; color: prevMa.containsMouse ? (sharedData.colorAccent || "#4a9eff") : (sharedData.colorText || "#ffffff"); opacity: prevMa.pressed ? 0.7 : 1.0 }
                                MouseArea { id: prevMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: playerPrevRequested() }
                            }
                            Rectangle {
                                width: 48; height: 48; radius: (sharedData && sharedData.quickshellBorderRadius !== undefined) ? Math.min(sharedData.quickshellBorderRadius, 12) : 12; color: playMa.containsMouse ? (sharedData.colorAccent || "#4a9eff") : Qt.rgba(1,1,1,0.12); scale: playMa.pressed ? 0.9 : 1.0; Behavior on scale { NumberAnimation { duration: 100 } }; Behavior on color { ColorAnimation { duration: 150 } }
                                Text { anchors.centerIn: parent; anchors.horizontalCenterOffset: !mpPlaying ? 2 : 0; text: mpPlaying ? "󰏤" : "󰐊"; font.pixelSize: 24; color: playMa.containsMouse ? "#000000" : (sharedData.colorText || "#ffffff") }
                                MouseArea { id: playMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: playerPlayPauseRequested() }
                            }
                            Rectangle {
                                width: 38; height: 38; radius: (sharedData && sharedData.quickshellBorderRadius !== undefined) ? Math.min(sharedData.quickshellBorderRadius, 10) : 10; color: nextMa.containsMouse ? Qt.rgba(1,1,1,0.15) : "transparent"
                                Text { anchors.centerIn: parent; text: "󰒭"; font.pixelSize: 20; color: nextMa.containsMouse ? (sharedData.colorAccent || "#4a9eff") : (sharedData.colorText || "#ffffff"); opacity: nextMa.pressed ? 0.7 : 1.0 }
                                MouseArea { id: nextMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: playerNextRequested() }
                            }
                            Item { Layout.fillWidth: true }
                        }
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 4
                    Rectangle {
                        Layout.fillWidth: true; height: 3; radius: 1.5; color: Qt.rgba(1,1,1,0.05)
                        Rectangle { width: (mpLength > 0 ? (parent.width * (mpPosition / mpLength)) : 0); height: parent.height; radius: 1.5; color: (sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff"; Behavior on width { NumberAnimation { duration: 500; easing.type: Easing.OutQuint } } }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: formatTime(mpPosition); font.pixelSize: 8; font.family: "sans-serif"; color: (sharedData && sharedData.colorText) ? Qt.alpha(sharedData.colorText, 0.5) : "#888888" }
                        Item { Layout.fillWidth: true }
                        Text { text: mpLength > 0 ? formatTime(mpLength) : "0:00"; font.pixelSize: 8; font.family: "sans-serif"; color: (sharedData && sharedData.colorText) ? Qt.alpha(sharedData.colorText, 0.5) : "#888888" }
                    }
                }
            }
        }
    }
    
    function refreshCharts() {
        res1Chart.refresh()
        res2Chart.refresh()
    }
}

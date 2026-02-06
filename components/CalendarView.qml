import QtQuick

Item {
    id: root
    property var sharedData: null

    // Public API: external user can set width/height via anchors or explicit size

    property var calendarDays: []

    width: 220
    height: 180

    Column {
        anchors.fill: parent
        anchors.margins: 6
        spacing: 4

        // Day headers
        Row {
            spacing: 4
            anchors.horizontalCenter: parent.horizontalCenter

            Repeater {
                model: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
                Text {
                    text: modelData
                    font.pixelSize: 9
                    font.family: "sans-serif"
                    color: (sharedData && sharedData.colorText) ? Qt.lighter(sharedData.colorText, 1.3) : "#aaaaaa"
                    width: 18
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }

        // Calendar grid
        Grid {
            columns: 7
            spacing: 4
            anchors.horizontalCenter: parent.horizontalCenter

            Repeater {
                model: calendarDays

                Rectangle {
                    width: 18
                    height: 18
                    radius: 2
                    color: modelData.isToday ?
                               ((sharedData && sharedData.colorAccent) ? sharedData.colorAccent : "#4a9eff") :
                               "transparent"

                    Text {
                        text: modelData.day
                        font.pixelSize: 9
                        font.family: "sans-serif"
                        color: modelData.isToday ?
                                   ((sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff") :
                                   (modelData.isCurrentMonth ?
                                        ((sharedData && sharedData.colorText) ? sharedData.colorText : "#ffffff") :
                                        ((sharedData && sharedData.colorText) ? Qt.lighter(sharedData.colorText, 1.5) : "#888888"))
                        anchors.centerIn: parent
                    }
                }
            }
        }
    }

    function updateCalendar() {
        var now = new Date()
        var firstDay = new Date(now.getFullYear(), now.getMonth(), 1)
        var lastDay = new Date(now.getFullYear(), now.getMonth() + 1, 0)
        var startDay = firstDay.getDay() === 0 ? 6 : firstDay.getDay() - 1 // Monday = 0

        var days = []

        // Days from previous month
        for (var i = 0; i < startDay; i++) {
            var day = new Date(now.getFullYear(), now.getMonth(), -startDay + i + 1)
            days.push({
                          day: day.getDate(),
                          isCurrentMonth: false,
                          isToday: false
                      })
        }

        // Days in current month
        for (var d = 1; d <= lastDay.getDate(); d++) {
            var current = new Date(now.getFullYear(), now.getMonth(), d)
            var isToday = current.getDate() === now.getDate()
                    && current.getMonth() === now.getMonth()
                    && current.getFullYear() === now.getFullYear()

            days.push({
                          day: d,
                          isCurrentMonth: true,
                          isToday: isToday
                      })
        }

        // Fill the remaining cells up to full weeks (5 or 6 weeks)
        while (days.length % 7 !== 0 || days.length < 35) {
            var extraDay = new Date(now.getFullYear(), now.getMonth(), lastDay.getDate() + (days.length - (startDay + lastDay.getDate())) + 1)
            days.push({
                          day: extraDay.getDate(),
                          isCurrentMonth: false,
                          isToday: false
                      })
        }

        calendarDays = days
    }

    Timer {
        id: calendarTimer
        interval: 60000
        repeat: true
        running: true
        onTriggered: root.updateCalendar()
        Component.onCompleted: root.updateCalendar()
    }
}


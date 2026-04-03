import QtQuick

Item {
    id: root

    property int cardCount: 4
    property real cardWidth: 200
    property real cardHeight: 280
    property real offsetStep: 8

    width: cardWidth + (cardCount - 1) * offsetStep
    height: cardHeight + (cardCount - 1) * offsetStep

    Repeater {
        model: root.cardCount

        Rectangle {
            property int cardIndex: index

            z: cardCount - index
            x: index * root.offsetStep
            y: index * root.offsetStep
            width: root.cardWidth
            height: root.cardHeight
            radius: 12
            border.width: 2
            border.color: "#2a2a2a"

            gradient: Gradient {
                GradientStop { position: 0; color: "#f5f5f5" }
                GradientStop { position: 1; color: "#e0e0e0" }
            }

            Text {
                anchors.centerIn: parent
                text: (cardIndex + 1).toString()
                font.pixelSize: 48
                font.bold: true
                color: "#333"
            }
        }
    }
}
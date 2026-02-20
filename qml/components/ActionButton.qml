import QtQuick

Rectangle {
    id: root
    width: 120
    height: 32
    radius: 4
    color: "#3a3a3a"
    border.color: "#555"
    border.width: 1

    property alias text: label.text

    signal clicked()

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true

        onClicked: root.clicked()
        onEntered: root.color = "#4a4a4a"
        onExited: root.color = "#3a3a3a"
    }

    Text {
        id: label
        anchors.centerIn: parent
        color: "white"
        font.pixelSize: 15
    }
}

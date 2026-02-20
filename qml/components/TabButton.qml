import QtQuick

Rectangle {
    id: root
    width: 150
    height: 40
    color: "#202020"
    border.color: "#444"
    border.width: 1

    property alias text: label.text
    signal clicked()

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.clicked()
    }

    Text {
        id: label
        anchors.centerIn: parent
        color: "white"
        font.pixelSize: 17
    }
}

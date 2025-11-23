import QtQuick
import QtQuick.Controls

Rectangle {
    id: root
    width: 100
    height: 30
    radius: 6
    color: "#333333"
    border.color: "#555555"
    border.width: 1

    property int value: 0
    property int minimumValue: 0
    property int maximumValue: 999

    Row {
        anchors.fill: parent
        spacing: 0

        // Minus button
        Rectangle {
            id: minusBtn
            width: 30
            height: parent.height
            color: mouseMinus.containsMouse ? "#444444" : "#333333"
            radius: 6

            Text {
                anchors.centerIn: parent
                text: "-"
                color: "white"
                font.pixelSize: 20
            }

            MouseArea {
                id: mouseMinus
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                    if (root.value > minimumValue) {
                        root.value--
                    }
                }
            }
        }

        // Text field
        Rectangle {
            id: numberField
            width: 48
            height: parent.height
            color: "#282828"

            TextInput {
                id: input
                anchors.centerIn: parent
                width: parent.width - 6
                color: "white"
                text: root.value
                horizontalAlignment: TextInput.AlignHCenter
                inputMethodHints: Qt.ImhDigitsOnly
                font.pixelSize: 18

                onTextChanged: {
                    let num = parseInt(text)
                    if (!isNaN(num)) {
                        if (num < minimumValue) num = minimumValue
                        if (num > maximumValue) num = maximumValue
                        root.value = num
                    }
                }
            }
        }

        // Plus button
        Rectangle {
            id: plusBtn
            width: 30
            height: parent.height
            color: mousePlus.containsMouse ? "#444444" : "#333333"
            radius: 6

            Text {
                anchors.centerIn: parent
                text: "+"
                color: "white"
                font.pixelSize: 20
            }

            MouseArea {
                id: mousePlus
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                    if (root.value < maximumValue) {
                        root.value++
                    }
                }
            }
        }
    }
}

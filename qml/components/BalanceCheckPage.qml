import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    anchors.fill: parent

    signal balancedYes()
    signal balancedNo()

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 16

        Text {
            text: "Сбалансирована ли транспортная задача?"
            font.pixelSize: 20
            color: "#111"
            horizontalAlignment: Text.AlignHCenter
            Layout.alignment: Qt.AlignHCenter
        }

        RowLayout {
            spacing: 12
            Layout.alignment: Qt.AlignHCenter

            Button {
                text: "Да"
                background: Rectangle { radius: 10; color: "#22c55e" }
                contentItem: Text { text: "Да"; color: "white"; font.pixelSize: 16; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                onClicked: root.balancedYes()
            }

            Button {
                text: "Нет"
                background: Rectangle { radius: 10; color: "#ef4444" }
                contentItem: Text { text: "Нет"; color: "white"; font.pixelSize: 16; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                onClicked: root.balancedNo()
            }
        }

        Text {
            text: "Подсказка: сумма запасов должна равняться сумме потребностей."
            color: "#444"
            font.pixelSize: 14
            Layout.alignment: Qt.AlignHCenter
        }
    }
}

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root

    radius: 12
    color: "#ffffff"
    border.color: "#e5e5e5"

    property int phase: 0
    property int selR: -1
    property int selC: -1
    property var localCost: []

    property string amountText: ""
    property string errorText: ""

    signal amountTextChangedByUser(string value)
    signal confirmAmountClicked()

    signal crossOutRowClicked()
    signal crossOutColClicked()
    signal crossOutBothClicked()

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 10

        Text {
            text: "Панель шага"
            font.pixelSize: 16
            color: "#111"
        }

        Text {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            color: "#444"
            text: {
                if (phase === 0)
                    return "1) Выбери клетку с минимальным тарифом."

                if (phase === 1)
                    return "2) Введи объём перевозки."

                if (phase === 2)
                    return "3) Вычеркни поставщика/потребителя."

                return "Опорный план построен."
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: "#eeeeee"
        }

        Text {
            Layout.fillWidth: true
            color: "#111"
            text: {
                if (selR < 0 || selC < 0)
                    return "Выбрано: —"

                return "Выбрано: (" + (selR + 1) + "," + (selC + 1) + "), тариф=" + localCost[selR][selC]
            }
        }

        TextField {
            Layout.fillWidth: true
            placeholderText: "Объём (x_ij)"
            inputMethodHints: Qt.ImhDigitsOnly
            enabled: phase === 1
            text: root.amountText
            onTextChanged: root.amountTextChangedByUser(text)
        }

        Button {
            Layout.fillWidth: true
            text: "Подтвердить объём"
            enabled: phase === 1
            onClicked: root.confirmAmountClicked()
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: "#eeeeee"
        }

        Text {
            text: "Вычеркнуть:"
            color: "#111"
            visible: phase === 2
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            visible: phase === 2

            Button {
                Layout.fillWidth: true
                text: "Поставщика"
                enabled: phase === 2
                onClicked: root.crossOutRowClicked()
            }

            Button {
                Layout.fillWidth: true
                text: "Потребителя"
                enabled: phase === 2
                onClicked: root.crossOutColClicked()
            }
        }

        Button {
            Layout.fillWidth: true
            text: "Оба"
            enabled: phase === 2
            visible: phase === 2
            onClicked: root.crossOutBothClicked()
        }

        Text {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            color: "#b91c1c"
            text: root.errorText
            visible: root.errorText.length > 0
        }

        Item {
            Layout.fillHeight: true
        }
    }
}

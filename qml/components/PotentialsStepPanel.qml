import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root

    radius: 16
    color: "#ffffff"
    border.color: "#e5e7eb"
    border.width: 1

    property int rows: 0
    property int columns: 0

    property int phase: 0

    property int pickType: 0
    property int pickIndex: 0
    property string valueText: ""
    property string errorText: ""

    property var u: []
    property var v: []

    property int deltaMode: 0
    property int dR: -1
    property int dC: -1
    property var checkedDeltas: []
    property string deltaText: ""
    property string deltaError: ""

    property var cycleCells: []
    property int cyclePos: 1
    property string cycleError: ""

    property string rText: ""
    property string rError: ""

    property string leaveError: ""

    signal pickTypeChangedByUser(int value)
    signal pickIndexChangedByUser(int value)
    signal valueTextChangedByUser(string value)
    signal submitPotentialClicked()

    signal deltaTextChangedByUser(string value)
    signal submitDeltaClicked()
    signal startChooseEnteringClicked()
    signal declareSolvedClicked()

    signal rTextChangedByUser(string value)
    signal checkRClicked()

    function hasText(s) {
        return s !== undefined && s !== null && String(s).length > 0
    }

    function deltaInstructionText() {
        if (deltaMode === 0)
            return "Выбери небазисную клетку на матрице, чтобы вычислить Δ."
        if (deltaMode === 1)
            return "Введи значение Δ для выбранной клетки."
        return "Теперь укажи входящую клетку на матрице."
    }

    function selectedDeltaCellText() {
        if (dR < 0 || dC < 0)
            return "Клетка не выбрана"
        return "Выбрана клетка: (" + (dR + 1) + "; " + (dC + 1) + ")"
    }

    function checkedDeltaText(item) {
        return "Δ(" + (item.r + 1) + "; " + (item.c + 1) + ") = " + item.value
    }

    ScrollView {
        id: scroll
        anchors.fill: parent
        anchors.margins: 14
        clip: true

        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        ScrollBar.vertical.policy: ScrollBar.AsNeeded

        Column {
            id: contentColumn
            width: scroll.availableWidth
            spacing: 12

            Text {
                width: parent.width
                text: "Панель шага"
                font.pixelSize: 18
                font.bold: true
                color: "#111827"
            }

            Rectangle {
                width: parent.width
                radius: 14
                color: "#f8fafc"
                border.color: "#e2e8f0"
                implicitHeight: potentialsContent.implicitHeight + 28

                ColumnLayout {
                    id: potentialsContent
                    x: 14
                    y: 14
                    width: parent.width - 28
                    spacing: 10

                    Text {
                        Layout.fillWidth: true
                        text: "Текущие потенциалы"
                        font.pixelSize: 15
                        font.bold: true
                        color: "#111827"
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 18

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4

                            Text {
                                text: "u"
                                font.pixelSize: 14
                                font.bold: true
                                color: "#374151"
                            }

                            Repeater {
                                model: root.rows
                                delegate: Text {
                                    required property int index
                                    color: "#4b5563"
                                    text: "u" + (index + 1) + " = "
                                          + (root.u && root.u[index] !== null ? root.u[index] : "—")
                                }
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4

                            Text {
                                text: "v"
                                font.pixelSize: 14
                                font.bold: true
                                color: "#374151"
                            }

                            Repeater {
                                model: root.columns
                                delegate: Text {
                                    required property int index
                                    color: "#4b5563"
                                    text: "v" + (index + 1) + " = "
                                          + (root.v && root.v[index] !== null ? root.v[index] : "—")
                                }
                            }
                        }
                    }
                }
            }

            Rectangle {
                visible: root.phase <= 1
                width: parent.width
                radius: 14
                color: "#f8fafc"
                border.color: "#e2e8f0"
                implicitHeight: stage12Content.implicitHeight + 28

                ColumnLayout {
                    id: stage12Content
                    x: 14
                    y: 14
                    width: parent.width - 28
                    spacing: 10

                    Text {
                        Layout.fillWidth: true
                        text: root.phase === 0
                              ? "4.1: Задание первого потенциала"
                              : "4.2: Вычисление остальных потенциалов"
                        font.pixelSize: 15
                        font.bold: true
                        color: "#111827"
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        ComboBox {
                            Layout.fillWidth: true
                            model: ["u (поставщик)", "v (потребитель)"]
                            currentIndex: root.pickType
                            onCurrentIndexChanged: root.pickTypeChangedByUser(currentIndex)
                        }

                        SpinBox {
                            Layout.preferredWidth: 90
                            from: 1
                            to: root.pickType === 0 ? root.rows : root.columns
                            value: root.pickIndex + 1
                            editable: true
                            onValueChanged: root.pickIndexChangedByUser(value - 1)
                        }
                    }

                    TextField {
                        Layout.fillWidth: true
                        placeholderText: root.phase === 0
                                         ? "Введите значение потенциала"
                                         : "Введите вычисленный потенциал"
                        validator: IntValidator { bottom: -1000000; top: 1000000 }
                        text: root.valueText
                        onTextChanged: root.valueTextChangedByUser(text)
                    }

                    Button {
                        Layout.fillWidth: true
                        text: root.phase === 0 ? "Задать потенциал" : "Проверить потенциал"
                        onClicked: root.submitPotentialClicked()
                    }

                    Rectangle {
                        visible: root.hasText(root.errorText)
                        Layout.fillWidth: true
                        radius: 10
                        color: "#fef2f2"
                        border.color: "#fecaca"
                        implicitHeight: phaseErrorText.implicitHeight + 20

                        Text {
                            id: phaseErrorText
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 10
                            wrapMode: Text.WordWrap
                            color: "#b91c1c"
                            text: root.errorText
                        }
                    }
                }
            }

            Rectangle {
                visible: root.phase === 2
                width: parent.width
                radius: 14
                color: "#f8fafc"
                border.color: "#e2e8f0"
                implicitHeight: deltaContent.implicitHeight + 28

                ColumnLayout {
                    id: deltaContent
                    x: 14
                    y: 14
                    width: parent.width - 28
                    spacing: 10

                    Text {
                        Layout.fillWidth: true
                        text: "4.3: Δ и входящая клетка"
                        font.pixelSize: 15
                        font.bold: true
                        color: "#111827"
                    }

                    Text {
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        color: "#4b5563"
                        text: root.deltaInstructionText()
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        radius: 10
                        color: "#eef2ff"
                        border.color: "#c7d2fe"
                        implicitHeight: selectedCellText.implicitHeight + 20

                        Text {
                            id: selectedCellText
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 10
                            wrapMode: Text.WordWrap
                            color: "#3730a3"
                            text: root.selectedDeltaCellText()
                        }
                    }

                    TextField {
                        Layout.fillWidth: true
                        visible: root.deltaMode === 1
                        placeholderText: "Введите Δ"
                        validator: IntValidator { bottom: -1000000; top: 1000000 }
                        text: root.deltaText
                        onTextChanged: root.deltaTextChangedByUser(text)
                    }

                    Button {
                        Layout.fillWidth: true
                        visible: root.deltaMode === 1
                        text: "Проверить Δ"
                        onClicked: root.submitDeltaClicked()
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        visible: root.deltaMode === 0 || root.deltaMode === 1

                        Button {
                            Layout.fillWidth: true
                            text: "Выбрать входящую"
                            onClicked: root.startChooseEnteringClicked()
                        }

                        Button {
                            Layout.fillWidth: true
                            text: "Задача решена"
                            onClicked: root.declareSolvedClicked()
                        }
                    }

                    Rectangle {
                        visible: root.hasText(root.deltaError)
                        Layout.fillWidth: true
                        radius: 10
                        color: "#fef2f2"
                        border.color: "#fecaca"
                        implicitHeight: deltaErrorText.implicitHeight + 20

                        Text {
                            id: deltaErrorText
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 10
                            wrapMode: Text.WordWrap
                            color: "#b91c1c"
                            text: root.deltaError
                        }
                    }
                }
            }



            Rectangle {
                visible: root.phase >= 2
                width: parent.width
                radius: 14
                color: "#f8fafc"
                border.color: "#e2e8f0"
                implicitHeight: deltasListContent.implicitHeight + 28

                ColumnLayout {
                    id: deltasListContent
                    x: 14
                    y: 14
                    width: parent.width - 28
                    spacing: 8

                    Text {
                        Layout.fillWidth: true
                        text: "Найденные Δ"
                        font.pixelSize: 15
                        font.bold: true
                        color: "#111827"
                    }

                    Text {
                        visible: root.checkedDeltas.length === 0
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        color: "#6b7280"
                        text: "Пока ни одна Δ не подтверждена."
                    }

                    Repeater {
                        model: root.checkedDeltas

                        delegate: Rectangle {
                            required property var modelData

                            Layout.fillWidth: true
                            radius: 10
                            color: "#ffffff"
                            border.color: "#e5e7eb"
                            implicitHeight: deltaItemText.implicitHeight + 20

                            Text {
                                id: deltaItemText
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.margins: 10
                                wrapMode: Text.WordWrap
                                color: "#374151"
                                text: root.checkedDeltaText(modelData)
                            }
                        }
                    }
                }
            }

            Rectangle {
                visible: root.phase === 3
                width: parent.width
                radius: 14
                color: "#f8fafc"
                border.color: "#e2e8f0"
                implicitHeight: cycleContent.implicitHeight + 28

                ColumnLayout {
                    id: cycleContent
                    x: 14
                    y: 14
                    width: parent.width - 28
                    spacing: 10

                    Text {
                        Layout.fillWidth: true
                        text: "4.4: Построение цикла"
                        font.pixelSize: 15
                        font.bold: true
                        color: "#111827"
                    }

                    Text {
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        color: "#4b5563"
                        text: root.cycleCells.length > 0
                              ? "Кликай клетки цикла по порядку. Осталось шагов: "
                                + (root.cycleCells.length - root.cyclePos)
                              : "Цикл не найден."
                    }

                    Rectangle {
                        visible: root.hasText(root.cycleError)
                        Layout.fillWidth: true
                        radius: 10
                        color: "#fef2f2"
                        border.color: "#fecaca"
                        implicitHeight: cycleErrorText.implicitHeight + 20

                        Text {
                            id: cycleErrorText
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 10
                            wrapMode: Text.WordWrap
                            color: "#b91c1c"
                            text: root.cycleError
                        }
                    }
                }
            }

            Rectangle {
                visible: root.phase === 4
                width: parent.width
                radius: 14
                color: "#f8fafc"
                border.color: "#e2e8f0"
                implicitHeight: rContent.implicitHeight + 28

                ColumnLayout {
                    id: rContent
                    x: 14
                    y: 14
                    width: parent.width - 28
                    spacing: 10

                    Text {
                        Layout.fillWidth: true
                        text: "4.5: Ввод r"
                        font.pixelSize: 15
                        font.bold: true
                        color: "#111827"
                    }

                    TextField {
                        Layout.fillWidth: true
                        placeholderText: "Введите r"
                        inputMethodHints: Qt.ImhDigitsOnly
                        text: root.rText
                        onTextChanged: root.rTextChangedByUser(text)
                    }

                    Button {
                        Layout.fillWidth: true
                        text: "Проверить r"
                        onClicked: root.checkRClicked()
                    }

                    Rectangle {
                        visible: root.hasText(root.rError)
                        Layout.fillWidth: true
                        radius: 10
                        color: "#fef2f2"
                        border.color: "#fecaca"
                        implicitHeight: rErrorText.implicitHeight + 20

                        Text {
                            id: rErrorText
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 10
                            wrapMode: Text.WordWrap
                            color: "#b91c1c"
                            text: root.rError
                        }
                    }
                }
            }

            Rectangle {
                visible: root.phase === 5
                width: parent.width
                radius: 14
                color: "#f8fafc"
                border.color: "#e2e8f0"
                implicitHeight: leaveContent.implicitHeight + 28

                ColumnLayout {
                    id: leaveContent
                    x: 14
                    y: 14
                    width: parent.width - 28
                    spacing: 10

                    Text {
                        Layout.fillWidth: true
                        text: "4.6: Удаляемая клетка"
                        font.pixelSize: 15
                        font.bold: true
                        color: "#111827"
                    }

                    Text {
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        color: "#4b5563"
                        text: "Кликни по клетке со знаком '-' и минимальным значением x."
                    }

                    Rectangle {
                        visible: root.hasText(root.leaveError)
                        Layout.fillWidth: true
                        radius: 10
                        color: "#fef2f2"
                        border.color: "#fecaca"
                        implicitHeight: leaveErrorText.implicitHeight + 20

                        Text {
                            id: leaveErrorText
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 10
                            wrapMode: Text.WordWrap
                            color: "#b91c1c"
                            text: root.leaveError
                        }
                    }
                }
            }

            Rectangle {
                visible: root.phase === 6
                width: parent.width
                radius: 14
                color: "#ecfdf5"
                border.color: "#bbf7d0"
                implicitHeight: doneText.implicitHeight + 28

                Text {
                    id: doneText
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 14
                    wrapMode: Text.WordWrap
                    color: "#166534"
                    text: "План оптимален. Итерация метода потенциалов завершена."
                }
            }
        }
    }
}

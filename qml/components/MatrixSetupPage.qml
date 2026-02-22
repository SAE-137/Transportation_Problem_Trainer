import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    anchors.fill: parent

    // чтобы PracticeScreen мог переключить этап
    signal proceedRequested()

    // наружу отдаём доступ к матрице (для копирования в work)
    property alias matrix: matrix

    // когда этап 0 завершён — блокируем редактирование (как "скриншот")
    property bool locked: false

    // входные параметры (их будет дергать верхний actionBar)
    function createMatrix(r, c) {
        if (locked) return
        matrix.resizeAndReset(r, c)
        updateProceedState()
    }

    function randomize() {
        if (locked) return
        matrix.randomFill()
        updateProceedState()
    }

    function clear() {
        if (locked) return
        matrix.resizeAndReset(matrix.rows, matrix.columns)
        updateProceedState()
    }

    function updateProceedState() {
        // если locked — кнопка уже не нужна
        proceedButton.enabled = (!locked) && matrix.isComplete()
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 14

        Item { Layout.fillHeight: true }

        MatrixView {
            id: matrix
            Layout.alignment: Qt.AlignHCenter
            readOnly: root.locked
            autoInit: true

            onChanged: root.updateProceedState()
        }

        Button {
            id: proceedButton
            Layout.alignment: Qt.AlignHCenter
            text: root.locked ? "Этап завершён" : "Приступить к решению"
            enabled: false
            visible: !root.locked

            background: Rectangle {
                radius: 10
                color: proceedButton.enabled ? "#22c55e" : "#9ca3af"
            }
            contentItem: Text {
                text: proceedButton.text
                color: "white"
                font.pixelSize: 16
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            onClicked: root.proceedRequested()
        }

        Item { Layout.fillHeight: true }
    }

    Component.onCompleted: updateProceedState()
}

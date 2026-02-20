import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    anchors.fill: parent

    signal proceedRequested()

    function createMatrix(r, c) {
        matrix.resizeAndReset(r, c)
        updateProceedState()
    }

    function randomize() {
        matrix.randomFill()
        updateProceedState()
    }


    function clear() {
        matrix.resizeAndReset(matrix.rows, matrix.columns)
        updateProceedState()
    }

    function updateProceedState() {
        proceedButton.enabled = matrix.isComplete()
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 14

        Item { Layout.fillHeight: true }

        MatrixView {
            id: matrix
            Layout.alignment: Qt.AlignHCenter

            onChanged: root.updateProceedState()
        }

        Button {
            id: proceedButton
            Layout.alignment: Qt.AlignHCenter
            text: "Приступить к решению"
            enabled: false

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

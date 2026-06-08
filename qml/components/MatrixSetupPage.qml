import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    anchors.fill: parent

    signal proceedRequested()

    property alias matrix: matrix
    property bool locked: false

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
        proceedButton.enabled = (!locked) && matrix.isComplete()
    }

    ScrollView {
        id: pageScroll
        anchors.fill: parent
        clip: true

        contentWidth: pageContent.width
        contentHeight: pageContent.height

        ScrollBar.horizontal.policy: contentWidth > availableWidth
                                     ? ScrollBar.AsNeeded
                                     : ScrollBar.AlwaysOff

        ScrollBar.vertical.policy: contentHeight > availableHeight
                                   ? ScrollBar.AsNeeded
                                   : ScrollBar.AlwaysOff

        Item {
            id: pageContent
            width: Math.max(pageScroll.availableWidth, contentColumn.implicitWidth + 32)
            height: contentColumn.implicitHeight + 32

            ColumnLayout {
                id: contentColumn
                anchors.top: parent.top
                anchors.topMargin: 16
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 14

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
                    implicitWidth: 260
                    implicitHeight: 44

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
            }
        }
    }

    Component.onCompleted: updateProceedState()
}

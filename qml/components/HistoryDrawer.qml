import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Drawer {
    id: root

    parent: Overlay.overlay
    edge: Qt.RightEdge
    width: 410
    height: parent ? parent.height : 800
    modal: false
    interactive: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    property var entries: []
    signal applyRequested(var entry)

    property var pendingEntry: null

    background: Rectangle {
        color: "#fbfaf8"
        border.color: "#d8d3cb"
    }

    Dialog {
        id: applyDialog
        parent: Overlay.overlay
        modal: true
        x: Math.round((root.width - width) / 2)
        y: 80
        title: "Подтверждение"

        standardButtons: Dialog.Yes | Dialog.No

        onAccepted: {
            if (root.pendingEntry)
                root.applyRequested(root.pendingEntry)
            root.pendingEntry = null
        }

        onRejected: {
            root.pendingEntry = null
        }

        contentItem: ColumnLayout {
            spacing: 10

            Text {
                Layout.preferredWidth: 320
                wrapMode: Text.WordWrap
                text: "Текущая матрица и текущий прогресс выбранного модуля будут очищены и заменены данными из истории. Продолжить?"
                color: "#333333"
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 14

        RowLayout {
            Layout.fillWidth: true

            Text {
                text: "История задач"
                font.pixelSize: 20
                font.bold: true
                color: "#222222"
            }

            Item {
                Layout.fillWidth: true
            }

            Rectangle {
                radius: 999
                color: "#ede5d9"
                implicitWidth: 42
                implicitHeight: 34

                Text {
                    anchors.centerIn: parent
                    text: String(root.entries.length)
                    font.pixelSize: 14
                    font.bold: true
                    color: "#5b5043"
                }
            }

            ToolButton {
                text: "✕"
                onClicked: root.close()

                contentItem: Text {
                    text: parent.text
                    font.pixelSize: 18
                    color: "#555555"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                background: Rectangle {
                    radius: 8
                    color: parent.down ? "#e8e2d8"
                                       : parent.hovered ? "#f1ece4"
                                                        : "transparent"
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: "#e6e0d7"
        }

        Text {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            text: "Можно применить любую сохранённую матрицу к текущему модулю."
            color: "#666666"
            font.pixelSize: 14
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 16
            color: "transparent"
            clip: true

            ListView {
                id: historyList
                anchors.fill: parent
                model: root.entries
                spacing: 12
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                delegate: Rectangle {
                    width: historyList.width
                    radius: 16
                    color: "#ffffff"
                    border.color: "#e6e0d7"
                    border.width: 1

                    implicitHeight: cardContent.implicitHeight + 28

                    ColumnLayout {
                        id: cardContent
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 12

                        Text {
                            Layout.fillWidth: true
                            text: modelData.title
                            font.pixelSize: 16
                            font.bold: true
                            color: "#222222"
                            elide: Text.ElideRight
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Rectangle {
                                radius: 999
                                color: modelData.moduleType === "Теория" ? "#e8f0fe" : "#eef7ea"
                                implicitHeight: 28
                                implicitWidth: moduleText.implicitWidth + 18

                                Text {
                                    id: moduleText
                                    anchors.centerIn: parent
                                    text: modelData.moduleType
                                    font.pixelSize: 12
                                    font.bold: true
                                    color: modelData.moduleType === "Теория" ? "#355172" : "#45613b"
                                }
                            }

                            Rectangle {
                                radius: 999
                                color: "#f2ede4"
                                implicitHeight: 28
                                implicitWidth: sizeText.implicitWidth + 18

                                Text {
                                    id: sizeText
                                    anchors.centerIn: parent
                                    text: modelData.rows + "×" + modelData.cols
                                    font.pixelSize: 12
                                    font.bold: true
                                    color: "#5b5043"
                                }
                            }

                            Item {
                                Layout.fillWidth: true
                            }

                            Text {
                                text: modelData.createdAtText
                                font.pixelSize: 12
                                color: "#7b7368"
                                horizontalAlignment: Text.AlignRight
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            radius: 12
                            color: "#faf8f4"
                            border.color: "#ece5d9"
                            implicitHeight: 170
                            clip: true

                            ScrollView {
                                anchors.fill: parent
                                anchors.margins: 10
                                clip: true

                                contentWidth: miniMatrix.implicitWidth
                                contentHeight: miniMatrix.implicitHeight

                                ScrollBar.horizontal.policy: miniMatrix.implicitWidth > width
                                                             ? ScrollBar.AsNeeded
                                                             : ScrollBar.AlwaysOff

                                ScrollBar.vertical.policy: miniMatrix.implicitHeight > height
                                                           ? ScrollBar.AsNeeded
                                                           : ScrollBar.AlwaysOff

                                Item {
                                    width: Math.max(miniMatrix.implicitWidth, parent.width)
                                    height: Math.max(miniMatrix.implicitHeight, parent.height)

                                    HistoryMiniMatrix {
                                        id: miniMatrix
                                        anchors.centerIn: parent

                                        rows: modelData.rows
                                        columns: modelData.cols
                                        costMatrix: modelData.costMatrix
                                        supply: modelData.supply
                                        demand: modelData.demand
                                    }
                                }
                            }
                        }

                        Button {
                            Layout.alignment: Qt.AlignHCenter
                            implicitWidth: 170
                            implicitHeight: 40
                            text: "Применить"

                            onClicked: {
                                root.pendingEntry = modelData
                                applyDialog.open()
                            }
                        }
                    }
                }

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                }
            }

            Column {
                anchors.fill: parent
                anchors.margins: 6
                spacing: 10
                visible: root.entries.length === 0

                Rectangle {
                    width: parent.width
                    radius: 14
                    color: "#ffffff"
                    border.color: "#e6e0d7"
                    implicitHeight: 120

                    Column {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 8

                        Text {
                            text: "История пока пуста"
                            font.pixelSize: 16
                            font.bold: true
                            color: "#222222"
                        }

                        Text {
                            width: parent.width
                            wrapMode: Text.WordWrap
                            text: "После нажатия «Решить» в теории или «Приступить к решению» в практике здесь появятся карточки задач."
                            color: "#777777"
                            font.pixelSize: 13
                        }
                    }
                }
            }
        }
    }
}

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root


    property int rows:    3
    property int columns: 3

    property var costMatrix:  []
    property var loadMatrix:  []
    property var supply:      []
    property var demand:      []


    function resizeAndReset(newRows, newColumns) {
        if (newRows < 1 || newColumns < 1) return;

        rows    = newRows
        columns = newColumns

        costMatrix  = Array(rows).fill("").map(() => Array(columns).fill(""))
        loadMatrix  = Array(rows).fill("").map(() => Array(columns).fill(""))
        supply      = Array(rows).fill("")
        demand      = Array(columns).fill("")


        topHeaderRepeater.model    = 0; topHeaderRepeater.model    = columns
        leftLabelsRepeater.model   = 0; leftLabelsRepeater.model   = rows
        matrixRepeater.model       = 0; matrixRepeater.model       = rows
        bottomDemandRepeater.model = 0; bottomDemandRepeater.model = columns

    }


    Column {
        spacing: 6
        anchors.centerIn: parent

        Row {
            spacing: 4
            anchors.horizontalCenter: parent.horizontalCenter

            Rectangle { width: 70; height: 40; color: "#e8e8e8"; border.color: "#666"; radius: 4 }

            Repeater {
                id: topHeaderRepeater
                model: columns
                delegate: Rectangle {
                    width: 70; height: 40
                    color: "#e8e8e8"
                    border.color: "#666"
                    radius: 4
                    Text {
                        anchors.centerIn: parent
                        font.pixelSize: 16
                        text: "A" + (index + 1)
                    }
                }
            }

            Rectangle {
                width: 70; height: 40
                color: "#f7f7f7"
                border.color: "#666"
                radius: 4
                Text {
                    anchors.centerIn: parent
                    font.pixelSize: 12
                    color: "#444"
                    text: "Запасы"
                }
            }
        }

        Row {
            spacing: 4
            anchors.horizontalCenter: parent.horizontalCenter

            Column {
                spacing: 4

                Repeater {
                    id: leftLabelsRepeater
                    model: rows
                    delegate: Rectangle {
                        width: 70; height: 70
                        color: "#e8e8e8"
                        border.color: "#666"
                        radius: 4
                        Text {
                            anchors.centerIn: parent
                            font.pixelSize: 16
                            text: "B" + (index + 1)
                        }
                    }
                }

                Rectangle {
                    width: 70; height: 70
                    color: "#f7f7f7"
                    border.color: "#666"
                    radius: 4
                    Text {
                        anchors.centerIn: parent
                        font.pixelSize: 13
                        color: "#444"
                        text: "Потреб."
                    }
                }
            }

            Column {
                spacing: 4

                Repeater {
                    id: matrixRepeater
                    model: rows

                    Row {
                        id: rowRow
                        property int rowIndex: index   // индекс строки
                        spacing: 4

                        Repeater {
                            model: columns
                            delegate: Rectangle {
                                readonly property int r: rowRow.rowIndex
                                readonly property int c: index
                                width: 70; height: 70
                                color: "#ffffff"
                                border.color: "#555"
                                radius: 6

                                Column {
                                    anchors.fill: parent
                                    anchors.margins: 4

                                    TextInput {
                                        text: costMatrix[r][c]
                                        anchors.top: parent.top
                                        anchors.right: parent.right
                                        width: 30
                                        horizontalAlignment: Text.AlignRight
                                        font.pixelSize: 14
                                        validator: IntValidator {}
                                        onTextChanged: if (acceptableInput) costMatrix[r][c] = text
                                    }

                                    TextInput {
                                        text: loadMatrix[r][c]
                                        anchors.bottom: parent.bottom
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        width: 35
                                        horizontalAlignment: Text.AlignHCenter
                                        font.pixelSize: 18
                                        validator: IntValidator {}
                                        onTextChanged: if (acceptableInput) loadMatrix[r][c] = text
                                    }
                                }
                            }
                        }

                        // Запасы (supply)
                        Rectangle {
                            width: 70; height: 70
                            color: "#fff8e6"
                            border.color: "#666"
                            radius: 4
                            TextInput {
                                text: supply[rowRow.rowIndex]
                                anchors.centerIn: parent
                                font.pixelSize: 18
                                color: "#333"
                                horizontalAlignment: Text.AlignHCenter

                                validator: IntValidator {}
                                readonly property int r: rowRow.rowIndex
                                onTextChanged: if (acceptableInput) supply[r] = text
                            }
                        }
                    }
                }

                // спрос (demand)
                Row {
                    spacing: 4

                    Repeater {
                        id: bottomDemandRepeater
                        model: columns
                        delegate: Rectangle {
                            width: 70; height: 70
                            radius: 4
                            color: "#fff8e6"
                            border.color: "#666"
                            TextInput {
                                anchors.centerIn: parent
                                font.pixelSize: 18
                                color: "#333"
                                horizontalAlignment: Text.AlignHCenter
                                text: demand[index]
                                validator: IntValidator {}
                                onTextChanged: if (acceptableInput) demand[index] = text
                            }
                        }
                    }

                    // пустая ячейка для выравнивания
                    Item { width: 70; height: 70 }
                }
            }
        }
    }

    Component.onCompleted: resizeAndReset(rows, columns)
}

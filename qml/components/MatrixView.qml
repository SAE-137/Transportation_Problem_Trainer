import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root
    color: "transparent"

    property int suppliers: 3
    property int consumers: 3

    // тарифы: suppliers x consumers
    property var costMatrix: []
    // перевозки (грузы)
    property var loadMatrix: []
    // запасы
    property var supply: []
    // потребности
    property var demand: []

    implicitWidth: body.implicitWidth + 40
    implicitHeight: body.implicitHeight + 40

    Column {
        id: body
        spacing: 10
        anchors.centerIn: parent

        // ===============================
        // ВЕРХНИЕ ЗАГОЛОВКИ (A1 A2 ...)
        // ===============================
        Row {
            spacing: 4
            anchors.horizontalCenter: parent.horizontalCenter

            //Rectangle { width: 70; height: 40; color: "transparent" }

            Repeater {
                model: consumers
                Rectangle {
                    width: 70; height: 40
                    color: "#e8e8e8"
                    border.color: "#666"
                    border.width: 1
                    radius: 4

                    Text {
                        anchors.centerIn: parent
                        font.pixelSize: 16
                        text: "A" + (index + 1)
                    }
                }
            }
        }

        // ===============================
        // ОСНОВНАЯ ОБЛАСТЬ
        // ===============================
        Row {
            spacing: 4
            anchors.horizontalCenter: parent.horizontalCenter

            // ---- ЛЕВЫЕ МЕТКИ (B1, B2, B3...) ----
            Column {
                spacing: 4

                Repeater {
                    model: suppliers
                    Rectangle {
                        width: 70; height: 70
                        color: "#e8e8e8"
                        border.color: "#666"
                        border.width: 1
                        radius: 4

                        Text {
                            anchors.centerIn: parent
                            font.pixelSize: 16
                            text: "B" + (index + 1)
                        }
                    }
                }

                // подпись "Запасы"
                Rectangle {
                    width: 70; height: 40
                    color: "#f7f7f7"
                    border.color: "#666"
                    radius: 4

                    Text {
                        anchors.centerIn: parent
                        text: "Запасы"
                        font.pixelSize: 13
                        color: "#444"
                    }
                }
            }

            // ===============================
            // МАТРИЦА ТАРИФОВ + ГРУЗОВ
            // ===============================
            Grid {
                id: table
                rows: suppliers
                columns: consumers
                spacing: 4

                Repeater {
                    model: suppliers * consumers

                    Rectangle {
                        width: 70
                        height: 70
                        radius: 6
                        color: "#fdfdfd"
                        border.color: "#555"
                        border.width: 1

                        property int r: Math.floor(index / consumers)
                        property int c: index % consumers

                        Column {
                            anchors.fill: parent
                            anchors.margins: 4

                            // тариф (верх справа)
                            TextInput {
                                anchors.top: parent.top
                                anchors.right: parent.right
                                width: 30
                                color: "#333"
                                font.pixelSize: 14
                                horizontalAlignment: TextInput.AlignRight
                                text: root.costMatrix[r][c]
                                validator: IntValidator{}
                                onTextChanged: root.costMatrix[r][c] = parseInt(text)
                            }

                            // груз (внизу по центру)
                            TextInput {
                                anchors.bottom: parent.bottom
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: 35
                                color: "#222"
                                font.pixelSize: 18
                                horizontalAlignment: TextInput.AlignHCenter
                                text: root.loadMatrix[r][c]
                                validator: IntValidator{}
                                onTextChanged: root.loadMatrix[r][c] = parseInt(text)
                            }
                        }
                    }
                }
            }

            // ===============================
            // ЗАПАСЫ СПРАВА
            // ===============================
            Column {
                spacing: 4

                Repeater {
                    model: suppliers
                    Rectangle {
                        width: 70; height: 70
                        radius: 4
                        color: "#fff8e6"
                        border.color: "#666"

                        TextInput {
                            anchors.centerIn: parent
                            font.pixelSize: 18
                            color: "#333"
                            horizontalAlignment: Text.AlignHCenter
                            text: root.supply[index]
                            validator: IntValidator{}
                            onTextChanged: root.supply[index] = parseInt(text)
                        }
                    }
                }
            }
        }

        // ===============================
        // ПОТРЕБНОСТИ СНИЗУ
        // ===============================
        Row {
            spacing: 4
            anchors.horizontalCenter: parent.horizontalCenter

            Repeater {
                model: consumers
                Rectangle {
                    width: 70; height: 40
                    radius: 4
                    color: "#fff8e6"
                    border.color: "#666"

                    TextInput {
                        anchors.centerIn: parent
                        font.pixelSize: 18
                        color: "#333"
                        horizontalAlignment: Text.AlignHCenter
                        text: root.demand[index]
                        validator: IntValidator{}
                        onTextChanged: root.demand[index] = parseInt(text)
                    }
                }
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            font.pixelSize: 14
            color: "#444"
            text: "Потребности"
        }
    }
}

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtCore

Item {
    id: root
    anchors.fill: parent

    property int rows: 0
    property int columns: 0
    property var costMatrix: []
    property var loadMatrix: []
    property var supply: []
    property var demand: []

    property int finalTotalCost: 0
    property int iterationsCount: 0

    property var practiceErrors: []

    property bool wasBalancedInitially: true
    property int balanceWho: -1
    property int balanceVolume: 0

    // Временно true, чтобы автоматически сохранить скриншот.
    // Перед финальной сборкой поставь false.
    property bool autoSaveResultScreenshot: true
    property bool resultScreenshotSaved: false
    property string resultScreenshotFileName: "practice_result_page.png"

    signal newTaskRequested()
    signal retryRequested()

    readonly property int errorsCount: practiceErrors ? practiceErrors.length : 0

    function errorStage(index) {
        if (!practiceErrors || index < 0 || index >= practiceErrors.length)
            return "Этап"

        const item = practiceErrors[index]
        return item.stage ? item.stage : "Этап"
    }

    function errorTitle(index) {
        if (!practiceErrors || index < 0 || index >= practiceErrors.length)
            return "Ошибка"

        const item = practiceErrors[index]
        return item.title ? item.title : "Ошибка"
    }

    function errorMessage(index) {
        if (!practiceErrors || index < 0 || index >= practiceErrors.length)
            return ""

        const item = practiceErrors[index]
        return item.message ? item.message : ""
    }



    onVisibleChanged: {
        if (visible && autoSaveResultScreenshot && !resultScreenshotSaved)
            resultScreenshotTimer.restart()
    }

    Component.onCompleted: {
        if (visible && autoSaveResultScreenshot && !resultScreenshotSaved)
            resultScreenshotTimer.restart()
    }

    ScrollView {
        id: resultScroll
        anchors.fill: parent
        clip: true

        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        ScrollBar.vertical.policy: ScrollBar.AsNeeded

        ColumnLayout {
            id: mainColumn

            width: Math.min(Math.max(resultScroll.availableWidth - 32, 320), 1050)
            height: implicitHeight

            x: Math.max(16, (resultScroll.availableWidth - width) / 2)
            y: 18

            spacing: 16

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: headerLayout.implicitHeight + 48

                radius: 20
                color: "#ffffff"
                border.color: "#e5e7eb"

                ColumnLayout {
                    id: headerLayout
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 24
                    spacing: 10

                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: 64
                        Layout.preferredHeight: 64
                        radius: 32
                        color: "#dcfce7"
                        border.color: "#bbf7d0"

                        Text {
                            anchors.centerIn: parent
                            text: "✓"
                            font.pixelSize: 34
                            font.bold: true
                            color: "#166534"
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        text: "Задача решена"
                        font.pixelSize: 30
                        font.bold: true
                        color: "#111827"
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: summaryLayout.implicitHeight + 44

                radius: 20
                color: "#ffffff"
                border.color: "#e5e7eb"

                ColumnLayout {
                    id: summaryLayout
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 22
                    spacing: 14



                    GridLayout {
                        Layout.fillWidth: true
                        columns: 2
                        columnSpacing: 12
                        rowSpacing: 12

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 84
                            radius: 14
                            color: "#f8fafc"
                            border.color: "#e5e7eb"

                            Column {
                                anchors.fill: parent
                                anchors.margins: 14
                                spacing: 7

                                Text {
                                    text: "Размер задачи"
                                    font.pixelSize: 13
                                    color: "#6b7280"
                                }

                                Text {
                                    text: rows + " × " + columns
                                    font.pixelSize: 23
                                    font.bold: true
                                    color: "#111827"
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 84
                            radius: 14
                            color: "#f8fafc"
                            border.color: "#e5e7eb"

                            Column {
                                anchors.fill: parent
                                anchors.margins: 14
                                spacing: 7

                                Text {
                                    text: "Итоговая стоимость"
                                    font.pixelSize: 13
                                    color: "#6b7280"
                                }

                                Text {
                                    text: String(finalTotalCost)
                                    font.pixelSize: 23
                                    font.bold: true
                                    color: "#111827"
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 84
                            radius: 14
                            color: "#f8fafc"
                            border.color: "#e5e7eb"

                            Column {
                                anchors.fill: parent
                                anchors.margins: 14
                                spacing: 7

                                Text {
                                    text: "Итераций метода потенциалов"
                                    font.pixelSize: 13
                                    color: "#6b7280"
                                }

                                Text {
                                    text: String(iterationsCount)
                                    font.pixelSize: 23
                                    font.bold: true
                                    color: "#111827"
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 84
                            radius: 14
                            color: errorsCount === 0 ? "#f0fdf4" : "#fff7ed"
                            border.color: errorsCount === 0 ? "#bbf7d0" : "#fed7aa"

                            Column {
                                anchors.fill: parent
                                anchors.margins: 14
                                spacing: 7

                                Text {
                                    text: "Ошибок пользователя"
                                    font.pixelSize: 13
                                    color: "#6b7280"
                                }

                                Text {
                                    text: String(errorsCount)
                                    font.pixelSize: 23
                                    font.bold: true
                                    color: errorsCount === 0 ? "#166534" : "#9a3412"
                                }
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: matrixLayout.implicitHeight + 44

                radius: 20
                color: "#ffffff"
                border.color: "#e5e7eb"

                ColumnLayout {
                    id: matrixLayout
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 22
                    spacing: 12

                    Text {
                        text: "Итоговая матрица"
                        font.pixelSize: 21
                        font.bold: true
                        color: "#111827"
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Math.max(260, resultMatrix.implicitHeight + 36)

                        radius: 14
                        color: "#f9fafb"
                        border.color: "#e5e7eb"

                        Item {
                            anchors.fill: parent
                            anchors.margins: 18

                            MatrixView {
                                id: resultMatrix
                                anchors.centerIn: parent

                                readOnly: true
                                showLoads: true
                                autoInit: false

                                rows: root.rows
                                columns: root.columns
                                costMatrix: root.costMatrix
                                loadMatrix: root.loadMatrix
                                supply: root.supply
                                demand: root.demand
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: errorsLayout.implicitHeight + 44

                radius: 20
                color: "#ffffff"
                border.color: "#e5e7eb"

                ColumnLayout {
                    id: errorsLayout
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 22
                    spacing: 12

                    Text {
                        text: "Допущенные ошибки"
                        font.pixelSize: 21
                        font.bold: true
                        color: "#111827"
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        visible: errorsCount === 0
                        Layout.preferredHeight: 74
                        radius: 14
                        color: "#f0fdf4"
                        border.color: "#bbf7d0"

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 14
                            spacing: 12

                            Text {
                                text: "✓"
                                font.pixelSize: 26
                                font.bold: true
                                color: "#166534"
                            }

                            Text {
                                Layout.fillWidth: true
                                wrapMode: Text.WordWrap
                                text: "Ошибок допущено не было"
                                font.pixelSize: 15
                                font.bold: true
                                color: "#166534"
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        visible: errorsCount > 0
                        spacing: 8

                        Repeater {
                            model: root.errorsCount

                            delegate: Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: errorItemLayout.implicitHeight + 22
                                radius: 14
                                color: "#fff7ed"
                                border.color: "#fed7aa"

                                ColumnLayout {
                                    id: errorItemLayout
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.top: parent.top
                                    anchors.margins: 12
                                    spacing: 5

                                    Text {
                                        Layout.fillWidth: true
                                        text: "Ошибка " + (index + 1) + " : " + root.errorStage(index)
                                        font.pixelSize: 14
                                        font.bold: true
                                        color: "#9a3412"
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        wrapMode: Text.WordWrap
                                        text: root.errorTitle(index)
                                        font.pixelSize: 13
                                        color: "#7c2d12"
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        wrapMode: Text.WordWrap
                                        text: root.errorMessage(index)
                                        font.pixelSize: 14
                                        color: "#111827"
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: actionsLayout.implicitHeight + 44

                radius: 20
                color: "#ffffff"
                border.color: "#e5e7eb"

                ColumnLayout {
                    id: actionsLayout
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 22
                    spacing: 14

                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 12

                        Button {
                            text: "Новая задача"
                            implicitWidth: 170
                            implicitHeight: 44

                            background: Rectangle {
                                radius: 10
                                color: parent.down ? "#dbeafe" : "#eff6ff"
                                border.color: "#93c5fd"
                            }

                            contentItem: Text {
                                text: parent.text
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                color: "#1d4ed8"
                                font.bold: true
                            }

                            onClicked: root.newTaskRequested()
                        }

                        Button {
                            text: "Решить заново"
                            implicitWidth: 170
                            implicitHeight: 44

                            background: Rectangle {
                                radius: 10
                                color: parent.down ? "#f3f4f6" : "#ffffff"
                                border.color: "#d1d5db"
                            }

                            contentItem: Text {
                                text: parent.text
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                color: "#111827"
                                font.bold: true
                            }

                            onClicked: root.retryRequested()
                        }
                    }
                }
            }

            Item {
                Layout.preferredHeight: 20
            }
        }
    }
}

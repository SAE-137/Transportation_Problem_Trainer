import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import QtQml

import "components"

ApplicationWindow {
    id: root
    width: 1200
    height: 800
    visible: true
    title: "Transportation Trainer"
    color: "#222222"

    property int currentScreenIndex: 0
    property var historyEntries: []

    property Item activeScreenItem: currentScreenIndex === 0 ? theoryScreen : practiceScreen

    function copy1D(a) {
        return a ? a.slice() : []
    }

    function copy2D(a) {
        return a ? a.map(function(row) { return row.slice() }) : []
    }

    function addHistoryEntry(entry) {
        if (!entry)
            return

        const prepared = {
            moduleType: entry.moduleType || "Неизвестно",
            title: entry.title || ((entry.moduleType || "Задача") + " " + entry.rows + "×" + entry.cols),
            rows: entry.rows || 0,
            cols: entry.cols || 0,
            costMatrix: copy2D(entry.costMatrix),
            supply: copy1D(entry.supply),
            demand: copy1D(entry.demand),
            createdAtText: Qt.formatDateTime(new Date(), "dd.MM.yyyy hh:mm")
        }

        historyEntries = [prepared].concat(historyEntries)

        if (historyEntries.length > 30)
            historyEntries = historyEntries.slice(0, 30)
    }

    function applyHistoryEntry(entry) {
        if (!entry || !activeScreenItem || !activeScreenItem.loadFromHistoryData) {
            console.log("Текущий модуль не поддерживает применение матрицы из истории")
            return
        }

        activeScreenItem.loadFromHistoryData(entry)
        historyDrawer.close()
    }

    HistoryDrawer {
        id: historyDrawer
        entries: root.historyEntries
        onApplyRequested: (entry) => root.applyHistoryEntry(entry)
    }

    SideErrorNotification {
        id: errorNotification
        parent: Overlay.overlay
        z: 10000
    }

    Connections {
        target: theoryScreen
        ignoreUnknownSignals: true

        function onHistoryEntryCreated(entry) {
            root.addHistoryEntry(entry)
        }
    }

    Connections {
        target: practiceScreen
        ignoreUnknownSignals: true

        function onHistoryEntryCreated(entry) {
            root.addHistoryEntry(entry)
        }
    }

    Rectangle {
        id: menuBar
        height: 30
        width: parent.width
        color: "#2a2a2a"
        anchors.top: parent.top

        Row {
            spacing: 5
            anchors.left: parent.left
            anchors.leftMargin: 5
            anchors.verticalCenter: parent.verticalCenter

            HeaderButton {
                text: "Настройки"
                onClicked: theoryScreen.captureFullPage()
            }

            HeaderButton {
                text: "История"
                onClicked: historyDrawer.open()
            }

            HeaderButton {
                text: "Теор. материалы"
                onClicked: Qt.openUrlExternally(
                    Qt.resolvedUrl("../materials/Transportnaya_zadacha_-_metodicheskoe_posobie.pdf")
                )
            }
        }

        ToolButton {
            id: historyIconButton
            width: 34
            height: 24
            anchors.right: parent.right
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter

            onClicked: {
                if (historyDrawer.opened)
                    historyDrawer.close()
                else
                    historyDrawer.open()
            }

            contentItem: Text {
                text: "≡"
                font.pixelSize: 20
                font.bold: true
                color: "#f3f0ea"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            background: Rectangle {
                radius: 6
                color: historyIconButton.down ? "#4b443c"
                                              : historyIconButton.hovered ? "#3b3530"
                                                                          : "transparent"
                border.color: historyDrawer.opened ? "#8f7f6b" : "transparent"
            }
        }
    }

    Rectangle {
        id: actionBar
        height: 45
        width: parent.width
        color: "#2a2a2a"
        anchors.top: menuBar.bottom

        Row {
            spacing: 15
            anchors.left: parent.left
            anchors.leftMargin: 20
            anchors.verticalCenter: parent.verticalCenter

            NumberInput {
                id: rowInput
                minimumValue: 1
                maximumValue: 20
                value: 3
            }

            NumberInput {
                id: colInput
                minimumValue: 1
                maximumValue: 20
                value: 3
            }

            ActionButton {
                text: "Создать"
                onClicked: {
                    if (root.activeScreenItem && root.activeScreenItem.createMatrix) {
                        root.activeScreenItem.createMatrix(rowInput.value, colInput.value)
                    } else {
                        console.log("createMatrix не поддерживается на этом экране")
                    }
                }
            }

            ActionButton {
                text: "Рандом"
                onClicked: {
                    if (root.activeScreenItem && root.activeScreenItem.randomize) {
                        root.activeScreenItem.randomize()
                    } else {
                        console.log("randomize не поддерживается на этом экране")
                    }
                }
            }

            ActionButton {
                text: "Решить"
                onClicked: {
                    if (root.activeScreenItem && root.activeScreenItem.solve) {
                        root.activeScreenItem.solve()
                    } else {
                        console.log("solve не поддерживается на этом экране")
                    }
                }
            }

            ActionButton {
                text: "Очистить"
                onClicked: {
                    if (root.activeScreenItem && root.activeScreenItem.clear) {
                        root.activeScreenItem.clear()
                    } else {
                        console.log("clear не поддерживается на этом экране")
                    }
                }
            }
        }
    }

    Rectangle {
        id: modeTabs
        height: 40
        width: parent.width
        color: "#151515"
        anchors.top: actionBar.bottom

        Row {
            anchors.verticalCenter: parent.verticalCenter

            TabButton {
                text: "Теория"
                onClicked: root.currentScreenIndex = 0
            }

            TabButton {
                text: "Практика"
                onClicked: root.currentScreenIndex = 1
            }
        }
    }

    Rectangle {
        id: centralArea
        anchors.top: modeTabs.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        color: "#f7f6f4"

        StackLayout {
            id: screenStack
            anchors.fill: parent
            currentIndex: root.currentScreenIndex

            TheoryScreen {
                id: theoryScreen
                Layout.fillWidth: true
                Layout.fillHeight: true
                errorNotifier: errorNotification
            }

            PracticeScreen {
                id: practiceScreen
                Layout.fillWidth: true
                Layout.fillHeight: true
                errorNotifier: errorNotification
            }
        }
    }
}

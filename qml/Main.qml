import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

// ИМПОРТ КОМПОНЕНТОВ
import "components"

ApplicationWindow {
    id: root
    width: 1200
    height: 800
    visible: true
    title: "Transportation Trainer"
    color: "#222222"

    property string currentScreen: "screens/TheoryScreen.qml"

    // ============================
    // ВЕРХНИЙ МЕНЮ-Бар
    // ============================
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
                onClicked: console.log("Настройки")
            }

            HeaderButton {
                text: "История"
                onClicked: console.log("История")
            }

            HeaderButton {
                text: "Теор. материалы"
                onClicked: console.log("Теор. материалы")
            }
        }
    }

    // ============================
    // ПАНЕЛЬ КНОПОК ДЕЙСТВИЙ
    // ============================
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
                onClicked: createMatrix()
            }
            ActionButton { text: "Рандом" }
            ActionButton { text: "Решить" }
            ActionButton { text: "Очистить" }
        }
    }

    // ============================
    // ВКЛАДКИ (Теория / Практика)
    // ============================
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
                onClicked: currentScreen = "screens/TheoryScreen.qml"
            }

            TabButton {
                text: "Практика"
                onClicked: currentScreen = "screens/PracticeScreen.qml"
            }
        }
    }

    // ============================
    // ОСНОВНАЯ ОБЛАСТЬ
    // ============================
    Rectangle {
        id: centralArea
        anchors.top: modeTabs.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        color: "#1e1e1e"

        Loader {
            id: screenLoader
            anchors.fill: parent
            source: currentScreen
        }
    }


    function createMatrix() {
        // удаляем старую матрицу
        for (let i = matrixContainer.children.length - 1; i >= 0; i--) {
            let obj = matrixContainer.children[i]
            if (obj && obj.destroy) obj.destroy()
        }

        let n = rowInput.value
        let m = colInput.value

        let component = Qt.createComponent("components/MatrixView.qml")

        if (component.status === Component.Ready) {
            component.createObject(matrixContainer, {
                rows: n,
                columns: m,
                matrixData: Array(n).fill(0).map(() => Array(m).fill("")),
                supply: Array(n).fill(""),
                demand: Array(m).fill("")
            })
        } else {
            console.log("Ошибка загрузки MatrixView:", component.errorString())
        }
    }



}


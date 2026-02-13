import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

import "components"

ApplicationWindow {
    id: root
    width: 1200
    height: 800
    visible: true
    title: "Transportation Trainer"
    color: "#222222"

    property string currentScreen: "components/TheoryScreen.qml"

    //  МЕНЮ-Бар
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


    // панель кнопок действий

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
                    if (screenLoader.item && screenLoader.item.createMatrix) {
                        screenLoader.item.createMatrix(rowInput.value, colInput.value)
                    } else {
                        console.log("createMatrix не поддерживается на этом экране")
                    }
                }
            }

            ActionButton {
                text: "Рандом"
                onClicked: {
                    if (screenLoader.item && screenLoader.item.randomize) {
                        //screenLoader.item.randomize()
                    } else {
                        console.log("randomize не поддерживается на этом экране")
                    }
                }
            }

            ActionButton {
                text: "Решить"
                onClicked: {
                    if (screenLoader.item && screenLoader.item.solve) {
                        //screenLoader.item.solve()
                    } else {
                        console.log("solve не поддерживается на этом экране")
                    }
                }
            }

            ActionButton {
                text: "Очистить"
                onClicked: {
                    if (screenLoader.item && screenLoader.item.clear) {
                        //screenLoader.item.clear()
                    } else {
                        console.log("clear не поддерживается на этом экране")
                    }
                }
            }

        }
    }


    // ВКЛАДКИ (Теория / Практика)
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
                onClicked: currentScreen = "components/TheoryScreen.qml"
            }

            TabButton {
                text: "Практика"
                onClicked:
                {
                    currentScreen = "components/PracticeScreen.qml"
                    console.log("кнопка практика была нажата")
                }
            }
        }
    }


    // основная область

    Rectangle {
        id: centralArea
        anchors.top: modeTabs.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        color: "#f7f6f4"

        Loader {
            id: screenLoader
            anchors.fill: parent
            source: currentScreen
        }
    }





}


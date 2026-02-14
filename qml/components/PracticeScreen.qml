import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    anchors.fill: parent

    property int currentStage: 0
    property int maxUnlockedStage: 0

    readonly property var stageTitles: [
        "0 Ввод",
        "1 Баланс?",
        "2 Балансировка",
        "3 Мин. тариф",
        "4 Потенциалы"
    ]

    readonly property var stageSources: [
        "MatrixSetupPage.qml",
        "BalanceCheckPage.qml",
        "BalanceFixPage.qml",
        "MinCostPlanPage.qml",
        "PotentialsIterationPage.qml"
    ]

    function goToStage(stage) {
        if (stage < 0 || stage > 4) return
        if (stage > maxUnlockedStage) return
        currentStage = stage
        stageLoader.source = stageSources[stage]
    }

    function unlockAndGo(nextStage) {
        maxUnlockedStage = Math.max(maxUnlockedStage, nextStage)
        goToStage(nextStage)
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        // ===== Верхний бар этапов =====
        Rectangle {
            Layout.fillWidth: true
            height: 52
            radius: 10
            color: "#ffffff"
            border.color: "#e0e0e0"

            RowLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 8

                Repeater {
                    model: 5

                    delegate: Button {
                        required property int index
                        Layout.fillHeight: true
                        Layout.preferredWidth: 160

                        enabled: index <= root.maxUnlockedStage
                        text: root.stageTitles[index]

                        background: Rectangle {
                            radius: 10
                            border.width: 1
                            border.color: (index === root.currentStage) ? "#111111" : "#cccccc"
                            color: {
                                if (index === root.currentStage) return "#dbeafe"
                                if (index < root.currentStage) return "#dcfce7"
                                if (index <= root.maxUnlockedStage) return "#ecfdf5"
                                return "#f3f4f6"
                            }
                        }

                        onClicked: root.goToStage(index)
                    }
                }
                Item { Layout.fillWidth: true }
            }
        }

        // ===== Контент этапа =====
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 12
            color: "#f7f6f4"
            border.color: "#e5e5e5"

            Loader {
                id: stageLoader
                anchors.fill: parent
                anchors.margins: 12
                source: root.stageSources[root.currentStage]
            }
        }
    }
    Connections {
        target: stageLoader.item
        ignoreUnknownSignals: true

        // этап 0 -> этап 1
        function onProceedRequested(payload) {
            root.unlockAndGo(1)
        }

        function onBalancedYes() {
            root.unlockAndGo(3)
        }

        function onBalancedNo() {
            root.unlockAndGo(2)
        }
    }

    Component.onCompleted: goToStage(0)

    function createMatrix(r, c) {
        if (stageLoader.item && stageLoader.item.createMatrix) {
            stageLoader.item.createMatrix(r, c)
        } else {
            console.log("createMatrix недоступен на текущем этапе")
        }
    }

    function randomize() {
        if (stageLoader.item && stageLoader.item.randomize) {
            stageLoader.item.randomize()
        } else {
            console.log("randomize недоступен на текущем этапе")
        }
    }

    function clear() {
        if (stageLoader.item && stageLoader.item.clear) {
            stageLoader.item.clear()
        } else {
            console.log("clear недоступен на текущем этапе")
        }
    }

    function solve() {
        if (stageLoader.item && stageLoader.item.solve) {
            stageLoader.item.solve()
        } else {
            console.log("solve недоступен на текущем этапе")
        }
    }

}

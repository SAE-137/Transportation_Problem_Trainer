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
        if (stage > maxUnlockedStage) return  // нельзя прыгать вперёд
        currentStage = stage
        stageLoader.source = stageSources[stage]
    }


    function completeStage(stageJustFinished) {
        maxUnlockedStage = Math.max(maxUnlockedStage, stageJustFinished + 1)
        goToStage(stageJustFinished + 1)
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        // Панель этапов
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
                                if (index === root.currentStage) return "#dbeafe"     // активный (светло-синий)
                                if (index < root.currentStage) return "#dcfce7"       // пройденный (зелёный)
                                if (index <= root.maxUnlockedStage) return "#ecfdf5"  // доступный (светло-зелёный)
                                return "#f3f4f6"                                      // заблокирован (серый)
                            }
                        }

                        onClicked: root.goToStage(index)
                    }
                }

                Item { Layout.fillWidth: true }
            }
        }


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

                // стартовая загрузка
                Component.onCompleted: root.goToStage(0)
            }
        }
    }
}

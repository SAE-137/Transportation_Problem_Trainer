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

    // ====== СЛЕПКИ ПО ЭТАПАМ (скриншоты данных) ======
    // snapshot = { rows, cols, cost(2D), supply(1D), demand(1D) }
    property var snapshots: [ null, null, null, null, null ]
    property int completedUpTo: -1

    // ====== ТЕКУЩАЯ РАБОЧАЯ МАТРИЦА (меняется от этапа к этапу) ======
    property int workRows: 0
    property int workCols: 0
    property var workCost: []
    property var workSupply: []
    property var workDemand: []


    property int pendingBalanceWho: -1
    property int pendingBalanceVolume: 0

    function copy2D(a) { return a.map(row => row.slice()) }
    function copy1D(a) { return a.slice() }

    function makeSnapshotFromWork() {
        return {
            rows: workRows,
            cols: workCols,
            cost: copy2D(workCost),
            supply: copy1D(workSupply),
            demand: copy1D(workDemand)
        }
    }

    function freezeStage(stageIndex) {
        snapshots[stageIndex] = makeSnapshotFromWork()
        // важно: "пнуть" обновление var-массива
        snapshots = snapshots
        completedUpTo = Math.max(completedUpTo, stageIndex)
    }

    function dataRows(stageIndex)  { return snapshots[stageIndex] ? snapshots[stageIndex].rows : workRows }
    function dataCols(stageIndex)  { return snapshots[stageIndex] ? snapshots[stageIndex].cols : workCols }
    function dataCost(stageIndex)  { return snapshots[stageIndex] ? snapshots[stageIndex].cost : workCost }
    function dataSupply(stageIndex){ return snapshots[stageIndex] ? snapshots[stageIndex].supply : workSupply }
    function dataDemand(stageIndex){ return snapshots[stageIndex] ? snapshots[stageIndex].demand : workDemand }

    function goToStage(stage) {
        if (stage < 0 || stage > 4) return
        if (stage > maxUnlockedStage) return
        currentStage = stage
        pages.currentIndex = stage

        // блокируем редактирование этапа 0, если он уже завершён
        setupPage.locked = (snapshots[0] !== null)
    }

    function unlockAndGo(nextStage) {
        maxUnlockedStage = Math.max(maxUnlockedStage, nextStage)
        goToStage(nextStage)
    }

    // ===== API для верхнего actionBar (ApplicationWindow) =====
    function createMatrix(r, c) {
        if (currentStage === 0 && setupPage && setupPage.createMatrix && !setupPage.locked) {
            setupPage.createMatrix(r, c)
            return
        }
        console.log("createMatrix недоступен на текущем этапе")
    }

    function randomize() {
        if (currentStage === 0 && setupPage && setupPage.randomize && !setupPage.locked) {
            setupPage.randomize()
            return
        }
        console.log("randomize недоступен на текущем этапе")
    }

    function clear() {
        if (currentStage === 0 && setupPage && setupPage.clear && !setupPage.locked) {
            setupPage.clear()
            return
        }
        console.log("clear недоступен на текущем этапе")
    }

    function solve() {
        console.log("solve недоступен на текущем этапе")
    }

    // ====== ЭТАП 0 -> старт практики ======
    function startPracticeFromSetup() {
        // создаём рабочую матрицу как копию ввода (этап 0)
        workRows = setupPage.matrix.rows
        workCols = setupPage.matrix.columns
        workCost = copy2D(setupPage.matrix.costMatrix)
        workSupply = copy1D(setupPage.matrix.supply)
        workDemand = copy1D(setupPage.matrix.demand)

        // замораживаем этап 0 (скриншот)
        freezeStage(0)

        // блокируем редактирование ввода
        setupPage.locked = true

        // переходим на этап 1
        unlockAndGo(1)
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

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
                                if (root.snapshots[index] !== null) return "#dcfce7"     // этап завершён (зелёный)
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

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 12
            color: "#f7f6f4"
            border.color: "#e5e5e5"

            StackLayout {
                id: pages
                anchors.fill: parent
                anchors.margins: 12
                currentIndex: root.currentStage

                // ---- Этап 0 ----
                MatrixSetupPage {
                    id: setupPage
                    onProceedRequested: root.startPracticeFromSetup()
                }

                // ---- Этап 1 ----
                BalanceCheckPage {
                    id: balancePage

                    rows: root.dataRows(1)
                    columns: root.dataCols(1)
                    costMatrix: root.dataCost(1)
                    supply: root.dataSupply(1)
                    demand: root.dataDemand(1)

                    // ВАЖНО: замораживаем этап 1 только если ответ был правильным
                    onBalancedYes: {
                        root.freezeStage(1)
                        root.unlockAndGo(3)
                    }
                    onBalancedNo: {
                        root.freezeStage(1)
                        root.unlockAndGo(2)
                    }
                }

                // ---- Этап 2 ----
                BalanceFixPage {
                    id: balanceFixPage

                    rows: root.workRows
                    columns: root.workCols
                    costMatrix: root.workCost
                    supply: root.workSupply
                    demand: root.workDemand

                    onBalanceFixPassed: (who, volume) => {
                        root.pendingBalanceWho = who
                        root.pendingBalanceVolume = volume

                        root.freezeStage(2)
                        root.unlockAndGo(3)
                    }
                }


                // ---- Этап 3 ----
                MinCostPlanPage {
                    id: minCostPage

                    rows: root.workRows
                    columns: root.workCols
                    costMatrix: root.workCost
                    supply: root.workSupply
                    demand: root.workDemand

                    balanceWho: root.pendingBalanceWho
                    balanceVolume: root.pendingBalanceVolume
                }

                // ---- Этап 4 (позже) ----
                Item { } // заглушка, чтобы StackLayout имел 5 страниц
            }
        }
    }

    Component.onCompleted: goToStage(0)
}

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    anchors.fill: parent

    property var errorNotifier: null

    property int currentStage: 0
    property int maxUnlockedStage: 0

    readonly property var stageTitles: [
        "0 Ввод",
        "1 Баланс",
        "2 Мин. тариф",
        "3 Потенциалы",
        "4 Итог"
    ]

    property var snapshots: [ null, null, null, null, null ]
    property int completedUpTo: -1

    property int workRows: 0
    property int workCols: 0
    property var workCost: []
    property var workSupply: []
    property var workDemand: []
    property var workLoad: []

    property int pendingBalanceWho: -1
    property int pendingBalanceVolume: 0

    property int finalTotalCost: 0
    property int potentialsIterations: 0

    property var practiceErrors: []

    signal historyEntryCreated(var entry)

    function copy2D(a) {
        return a ? a.map(row => row.slice()) : []
    }

    function copy1D(a) {
        return a ? a.slice() : []
    }

    function stageTitleFor(index) {
        if (index >= 0 && index < stageTitles.length)
            return stageTitles[index]

        return "Этап"
    }

    function recordPracticeError(message, title) {
        let list = practiceErrors.slice()

        list.push({
            number: list.length + 1,
            stageIndex: currentStage,
            stage: stageTitleFor(currentStage),
            title: title && title.length > 0 ? title : "Ошибка",
            message: message
        })

        practiceErrors = list
    }

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
        snapshots = snapshots
        completedUpTo = Math.max(completedUpTo, stageIndex)
    }

    function markResultStageDone() {
        snapshots[4] = {
            rows: workRows,
            cols: workCols,
            cost: copy2D(workCost),
            supply: copy1D(workSupply),
            demand: copy1D(workDemand)
        }

        snapshots = snapshots
        completedUpTo = Math.max(completedUpTo, 4)
    }

    function dataRows(stageIndex) {
        return snapshots[stageIndex] ? snapshots[stageIndex].rows : workRows
    }

    function dataCols(stageIndex) {
        return snapshots[stageIndex] ? snapshots[stageIndex].cols : workCols
    }

    function dataCost(stageIndex) {
        return snapshots[stageIndex] ? snapshots[stageIndex].cost : workCost
    }

    function dataSupply(stageIndex) {
        return snapshots[stageIndex] ? snapshots[stageIndex].supply : workSupply
    }

    function dataDemand(stageIndex) {
        return snapshots[stageIndex] ? snapshots[stageIndex].demand : workDemand
    }

    function goToStage(stage) {
        if (stage < 0 || stage > 4)
            return

        if (stage > maxUnlockedStage)
            return

        currentStage = stage
        pages.currentIndex = stage

        setupPage.locked = (snapshots[0] !== null)

        if (stage === 2 && minCostPage && minCostPage.initializeIfNeeded)
            minCostPage.initializeIfNeeded()
    }

    function unlockAndGo(nextStage) {
        maxUnlockedStage = Math.max(maxUnlockedStage, nextStage)
        goToStage(nextStage)
    }

    function hasSolvingProgress() {
        return currentStage > 0
               || maxUnlockedStage > 0
               || completedUpTo >= 0
               || snapshots[0] !== null
               || snapshots[1] !== null
               || snapshots[2] !== null
               || snapshots[3] !== null
               || snapshots[4] !== null
    }

    function performFullReset() {
        const keepRows = (setupPage && setupPage.matrix) ? setupPage.matrix.rows : 3
        const keepCols = (setupPage && setupPage.matrix) ? setupPage.matrix.columns : 3

        currentStage = 0
        maxUnlockedStage = 0
        snapshots = [ null, null, null, null, null ]
        completedUpTo = -1

        workRows = 0
        workCols = 0
        workCost = []
        workSupply = []
        workDemand = []
        workLoad = []

        pendingBalanceWho = -1
        pendingBalanceVolume = 0

        finalTotalCost = 0
        potentialsIterations = 0
        practiceErrors = []

        if (balancePage && balancePage.resetPageState)
            balancePage.resetPageState()

        if (minCostPage && minCostPage.resetStageState)
            minCostPage.resetStageState()

        if (potentialsPage && potentialsPage.resetForNewSourceData)
            potentialsPage.resetForNewSourceData()

        setupPage.locked = false
        goToStage(0)

        if (setupPage && setupPage.matrix && keepRows > 0 && keepCols > 0) {
            setupPage.matrix.resizeAndReset(keepRows, keepCols)

            if (setupPage.updateProceedState)
                setupPage.updateProceedState()
        }
    }

    function replayCurrentTask() {
        if (!snapshots[0])
            return

        loadFromHistoryData({
            rows: snapshots[0].rows,
            cols: snapshots[0].cols,
            costMatrix: copy2D(snapshots[0].cost),
            supply: copy1D(snapshots[0].supply),
            demand: copy1D(snapshots[0].demand)
        })
    }

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
        if (hasSolvingProgress()) {
            clearDialog.open()
            return
        }

        performFullReset()
    }

    function solve() {
        console.log("solve недоступен на текущем этапе")
    }

    function loadFromHistoryData(entry) {
        if (!entry || !entry.rows || !entry.cols)
            return

        performFullReset()

        setupPage.locked = false
        setupPage.createMatrix(entry.rows, entry.cols)

        Qt.callLater(function() {
            setupPage.matrix.costMatrix = copy2D(entry.costMatrix)
            setupPage.matrix.supply = copy1D(entry.supply)
            setupPage.matrix.demand = copy1D(entry.demand)

            if (setupPage.updateProceedState)
                setupPage.updateProceedState()
        })
    }

    function startPracticeFromSetup() {
        workRows = setupPage.matrix.rows
        workCols = setupPage.matrix.columns
        workCost = copy2D(setupPage.matrix.costMatrix)
        workSupply = copy1D(setupPage.matrix.supply)
        workDemand = copy1D(setupPage.matrix.demand)

        pendingBalanceWho = -1
        pendingBalanceVolume = 0
        workLoad = []

        finalTotalCost = 0
        potentialsIterations = 0
        practiceErrors = []

        historyEntryCreated({
            moduleType: "Практика",
            title: "Практика " + workRows + "×" + workCols,
            rows: workRows,
            cols: workCols,
            costMatrix: copy2D(workCost),
            supply: copy1D(workSupply),
            demand: copy1D(workDemand)
        })

        freezeStage(0)
        setupPage.locked = true
        unlockAndGo(1)
    }

    QtObject {
        id: practiceErrorNotifier

        function showError(message, title) {
            root.recordPracticeError(message, title)

            if (root.errorNotifier && root.errorNotifier.showError)
                root.errorNotifier.showError(message, title)
        }
    }

    Dialog {
        id: clearDialog
        parent: Overlay.overlay
        modal: true
        title: "Подтверждение"

        standardButtons: Dialog.Yes | Dialog.No

        onAccepted: performFullReset()

        contentItem: ColumnLayout {
            spacing: 10

            Text {
                Layout.preferredWidth: 320
                wrapMode: Text.WordWrap
                text: "Текущая задача и весь прогресс её решения будут очищены. Продолжить?"
                color: "#333333"
            }
        }
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
                        Layout.preferredWidth: 170

                        enabled: index <= root.maxUnlockedStage
                        text: root.stageTitles[index]

                        background: Rectangle {
                            radius: 10
                            border.width: 1
                            border.color: (index === root.currentStage) ? "#111111" : "#cccccc"
                            color: {
                                if (index === root.currentStage)
                                    return "#dbeafe"

                                if (root.snapshots[index] !== null)
                                    return "#dcfce7"

                                if (index <= root.maxUnlockedStage)
                                    return "#ecfdf5"

                                return "#f3f4f6"
                            }
                        }

                        onClicked: root.goToStage(index)
                    }
                }

                Item {
                    Layout.fillWidth: true
                }
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

                MatrixSetupPage {
                    id: setupPage

                    onProceedRequested: root.startPracticeFromSetup()
                }

                BalanceFixPage {
                    id: balancePage

                    errorNotifier: practiceErrorNotifier

                    rows: root.dataRows(1)
                    columns: root.dataCols(1)
                    costMatrix: root.dataCost(1)
                    supply: root.dataSupply(1)
                    demand: root.dataDemand(1)

                    onBalancedYes: {
                        root.pendingBalanceWho = -1
                        root.pendingBalanceVolume = 0
                        root.freezeStage(1)
                        root.unlockAndGo(2)
                    }

                    onBalanceFixPassed: (who, volume) => {
                        root.pendingBalanceWho = who
                        root.pendingBalanceVolume = volume
                        root.freezeStage(1)
                        root.unlockAndGo(2)
                    }
                }

                MinCostPlanPage {
                    id: minCostPage

                    errorNotifier: practiceErrorNotifier

                    rows: root.workRows
                    columns: root.workCols
                    costMatrix: root.workCost
                    supply: root.workSupply
                    demand: root.workDemand

                    balanceWho: root.pendingBalanceWho
                    balanceVolume: root.pendingBalanceVolume

                    onStage3Completed: (finalRows, finalCols, finalCost, finalSupply, finalDemand, finalLoad) => {
                        root.workRows = finalRows
                        root.workCols = finalCols
                        root.workCost = root.copy2D(finalCost)
                        root.workSupply = root.copy1D(finalSupply)
                        root.workDemand = root.copy1D(finalDemand)
                        root.workLoad = root.copy2D(finalLoad)

                        root.freezeStage(2)
                        root.unlockAndGo(3)
                    }
                }

                PotentialsPage {
                    id: potentialsPage

                    errorNotifier: practiceErrorNotifier

                    rows: root.workRows
                    columns: root.workCols
                    costMatrix: root.workCost
                    loadMatrix: root.workLoad
                    supply: root.workSupply
                    demand: root.workDemand

                    onPracticeCompleted: (finalLoad, totalCost, iterationsCount) => {
                        root.workLoad = root.copy2D(finalLoad)
                        root.finalTotalCost = totalCost
                        root.potentialsIterations = iterationsCount

                        root.freezeStage(3)
                        root.markResultStageDone()
                        root.unlockAndGo(4)
                    }
                }

                PracticeResultPage {
                    id: resultPage

                    rows: root.workRows
                    columns: root.workCols
                    costMatrix: root.workCost
                    loadMatrix: root.workLoad
                    supply: root.workSupply
                    demand: root.workDemand

                    finalTotalCost: root.finalTotalCost
                    iterationsCount: root.potentialsIterations
                    practiceErrors: root.practiceErrors

                    wasBalancedInitially: root.pendingBalanceVolume <= 0
                    balanceWho: root.pendingBalanceWho
                    balanceVolume: root.pendingBalanceVolume

                    onNewTaskRequested: root.performFullReset()
                    onRetryRequested: root.replayCurrentTask()
                }
            }
        }
    }

    Component.onCompleted: {
        goToStage(0)
    }
}

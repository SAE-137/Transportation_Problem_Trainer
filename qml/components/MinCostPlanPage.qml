import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    anchors.fill: parent

    property int rows: 0
    property int columns: 0
    property var costMatrix: []
    property var supply: []
    property var demand: []

    property int balanceWho: -1
    property int balanceVolume: 0

    property var errorNotifier: null

    property int localRows: 0
    property int localCols: 0
    property var localCost: []
    property var localSupply: []
    property var localDemand: []
    property var localLoad: []

    // 0 выбрать клетку, 1 ввести объём, 2 вычеркнуть
    property int phase: 0
    property int selR: -1
    property int selC: -1
    property string amountText: ""
    property string errorText: ""
    property string hintText: ""

    property var remSupply: []
    property var remDemand: []
    property var closedRows: []
    property var closedCols: []

    // Матрица цветов фона ячеек.
    // Зеленый цвет — клетка с грузом.
    // Красный цвет — недоступная пустая клетка.
    property var cellBackgroundMatrix: []

    property bool stateInitialized: false

    signal stage3Completed(
        int finalRows,
        int finalCols,
        var finalCost,
        var finalSupply,
        var finalDemand,
        var finalLoad
    )

    function notifyError(message) {
        errorText = message

        if (root.errorNotifier && root.errorNotifier.showError) {
            root.errorNotifier.showError(message, "Ошибка контроля")
        }
    }

    function toInt(x) {
        const n = Number(String(x ?? "").trim())
        return Number.isFinite(n) ? n : 0
    }

    function clearSelection() {
        selR = -1
        selC = -1
        amountText = ""
    }

    function updateDisplayedRemains() {
        localSupply = remSupply.map(v => String(v))
        localDemand = remDemand.map(v => String(v))
    }

    function loadValueAt(r, c) {
        if (!localLoad || !localLoad[r])
            return ""

        const value = localLoad[r][c]

        if (value === undefined || value === null)
            return ""

        return String(value).trim()
    }

    function refreshCellBackgroundMatrix() {
        let matrix = []

        for (let r = 0; r < localRows; r++) {
            let row = []

            for (let c = 0; c < localCols; c++) {
                const hasLoad = loadValueAt(r, c).length > 0
                const unavailable = closedRows[r] === true || closedCols[c] === true

                if (hasLoad)
                    row.push("#dcfce7")
                else if (unavailable)
                    row.push("#fee2e2")
                else
                    row.push("")
            }

            matrix.push(row)
        }

        cellBackgroundMatrix = matrix
    }

    function goToChooseCellStep() {
        phase = 0
        clearSelection()
        hintText = "Шаг 1: выбери следующую ячейку с минимальным тарифом."
    }

    function goToCrossOutStep() {
        phase = 2
        hintText = "Шаг 3: выбери, кого вычеркнуть."
    }

    function finishStage() {
        clearSelection()

        root.stage3Completed(
            localRows,
            localCols,
            localCost,
            localSupply,
            localDemand,
            localLoad
        )
    }

    function initializeIfNeeded() {
        if (!stateInitialized)
            rebuildLocal()
    }

    function resetStageState() {
        stateInitialized = false
        rebuildLocal()
    }

    function rebuildLocal() {
        if (rows <= 0 || columns <= 0) {
            localRows = 0
            localCols = 0
            localCost = []
            localSupply = []
            localDemand = []
            localLoad = []
            remSupply = []
            remDemand = []
            closedRows = []
            closedCols = []
            cellBackgroundMatrix = []

            phase = 0
            selR = -1
            selC = -1
            amountText = ""
            errorText = ""
            hintText = ""

            stateInitialized = false
            return
        }

        localRows = rows
        localCols = columns

        let outCost = new Array(rows)
        for (let r = 0; r < rows; r++) {
            let srcRow = (costMatrix && costMatrix[r]) ? costMatrix[r] : []
            let row = new Array(columns)

            for (let c = 0; c < columns; c++)
                row[c] = srcRow[c]

            outCost[r] = row
        }

        let outSupply = new Array(rows)
        for (let r = 0; r < rows; r++)
            outSupply[r] = supply ? supply[r] : undefined

        let outDemand = new Array(columns)
        for (let c = 0; c < columns; c++)
            outDemand[c] = demand ? demand[c] : undefined

        if (balanceWho === 0 && balanceVolume > 0) {
            localRows = rows + 1
            outCost.push(new Array(columns).fill("0"))
            outSupply.push(String(balanceVolume))
        } else if (balanceWho === 1 && balanceVolume > 0) {
            localCols = columns + 1

            for (let r = 0; r < rows; r++)
                outCost[r].push("0")

            outDemand.push(String(balanceVolume))
        }

        let outLoad = new Array(localRows)
        for (let r = 0; r < localRows; r++)
            outLoad[r] = new Array(localCols).fill("")

        let rs = new Array(localRows)
        let cs = new Array(localCols)
        let cr = new Array(localRows).fill(false)
        let cc = new Array(localCols).fill(false)

        for (let r = 0; r < localRows; r++)
            rs[r] = toInt(outSupply[r])

        for (let c = 0; c < localCols; c++)
            cs[c] = toInt(outDemand[c])

        localCost = outCost
        localLoad = outLoad
        remSupply = rs
        remDemand = cs
        closedRows = cr
        closedCols = cc

        refreshCellBackgroundMatrix()
        updateDisplayedRemains()

        phase = 0
        selR = -1
        selC = -1
        amountText = ""
        errorText = ""
        hintText = "Шаг 1: выбери ячейку с минимальным тарифом среди доступных."

        stateInitialized = true
    }

    onVisibleChanged: {
        if (visible)
            initializeIfNeeded()
    }

    function cellIsAvailable(r, c) {
        if (r < 0 || c < 0 || r >= localRows || c >= localCols)
            return false

        if (closedRows[r] || closedCols[c])
            return false

        if (remSupply[r] <= 0 || remDemand[c] <= 0)
            return false

        return true
    }

    function minAvailableCost() {
        let best = Infinity

        for (let r = 0; r < localRows; r++) {
            if (closedRows[r] || remSupply[r] <= 0)
                continue

            for (let c = 0; c < localCols; c++) {
                if (closedCols[c] || remDemand[c] <= 0)
                    continue

                const v = Number(localCost[r][c])
                if (!Number.isFinite(v))
                    continue

                if (v < best)
                    best = v
            }
        }

        return best
    }

    function expectedAmount(r, c) {
        return Math.min(remSupply[r], remDemand[c])
    }

    function handleCellClick(r, c) {
        errorText = ""

        if (phase !== 0)
            return

        if (!cellIsAvailable(r, c)) {
            notifyError("Ошибка (3.1): клетка недоступна.")
            return
        }

        const best = minAvailableCost()
        const v = Number(localCost[r][c])

        if (!Number.isFinite(v) || v !== best) {
            notifyError("Ошибка (3.1): выбрана не минимальная стоимость. Минимум сейчас: " + best)
            return
        }

        selR = r
        selC = c
        phase = 1
        amountText = ""
        hintText = "Шаг 2: введи объём перевозки для выбранной клетки."
    }

    function confirmAmount() {
        errorText = ""

        if (phase !== 1 || selR < 0 || selC < 0)
            return

        const user = Number(String(amountText).trim())

        if (!Number.isFinite(user) || user < 0) {
            notifyError("Ошибка (3.2): введи корректный объём.")
            return
        }

        const exp = expectedAmount(selR, selC)

        if (user !== exp) {
            notifyError("Ошибка (3.2): неверный объём. Должно быть " + exp)
            return
        }

        localLoad[selR][selC] = String(exp)
        localLoad = localLoad.map(row => row.slice())

        remSupply[selR] -= exp
        remDemand[selC] -= exp
        remSupply = remSupply.slice()
        remDemand = remDemand.slice()

        updateDisplayedRemains()
        refreshCellBackgroundMatrix()
        goToCrossOutStep()
    }

    function isFinalStep() {
        for (let r = 0; r < localRows; r++) {
            if (remSupply[r] > 0)
                return false
        }

        for (let c = 0; c < localCols; c++) {
            if (remDemand[c] > 0)
                return false
        }

        return true
    }

    function finishCrossOutStep() {
        closedRows = closedRows.slice()
        closedCols = closedCols.slice()

        refreshCellBackgroundMatrix()

        if (isFinalStep())
            finishStage()
        else
            goToChooseCellStep()
    }

    function crossOut(mode) {
        errorText = ""

        if (phase !== 2)
            return

        const rowZero = remSupply[selR] === 0
        const colZero = remDemand[selC] === 0
        const finalStep = isFinalStep()

        if (mode === "row") {
            if (!rowZero) {
                notifyError("Ошибка (3.3): строку нельзя вычеркнуть (запас не 0).")
                return
            }

            if (colZero && finalStep) {
                notifyError("Ошибка (3.3): на последнем шаге, когда равны 0 и запас, и потребность, нужно нажать 'Оба'.")
                return
            }

            closedRows[selR] = true

        } else if (mode === "col") {
            if (!colZero) {
                notifyError("Ошибка (3.3): столбец нельзя вычеркнуть (потребность не 0).")
                return
            }

            if (rowZero && finalStep) {
                notifyError("Ошибка (3.3): на последнем шаге, когда равны 0 и запас, и потребность, нужно нажать 'Оба'.")
                return
            }

            closedCols[selC] = true

        } else if (mode === "both") {
            if (!(rowZero && colZero)) {
                notifyError("Ошибка (3.3): оба можно вычеркнуть только если оба равны 0.")
                return
            }

            if (!finalStep) {
                notifyError("Ошибка (3.3): 'Оба' разрешено только на последнем шаге.")
                return
            }

            closedRows[selR] = true
            closedCols[selC] = true

        } else {
            notifyError("Ошибка (3.3): неизвестный режим вычёркивания.")
            return
        }

        finishCrossOutStep()
    }

    RowLayout {
        anchors.fill: parent
        spacing: 16

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 10

            Text {
                text: "Этап 3: Метод минимального тарифа"
                font.pixelSize: 20
                color: "#111"
                Layout.alignment: Qt.AlignHCenter
            }

            MatrixView {
                id: matrixPreview

                Layout.alignment: Qt.AlignHCenter

                readOnly: true
                interactive: (phase === 0)
                showLoads: true
                autoInit: false

                rows: root.localRows
                columns: root.localCols
                costMatrix: root.localCost
                loadMatrix: root.localLoad
                supply: root.localSupply
                demand: root.localDemand

                cellBackgroundMatrix: root.cellBackgroundMatrix

                onCellClicked: (r, c) => root.handleCellClick(r, c)
            }

            Text {
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                color: "#444"
                text: hintText
            }
        }

        MinCostStepPanel {
            Layout.preferredWidth: 320
            Layout.fillHeight: true

            phase: root.phase
            selR: root.selR
            selC: root.selC
            localCost: root.localCost

            amountText: root.amountText
            errorText: ""

            onAmountTextChangedByUser: (value) => root.amountText = value
            onConfirmAmountClicked: root.confirmAmount()

            onCrossOutRowClicked: root.crossOut("row")
            onCrossOutColClicked: root.crossOut("col")
            onCrossOutBothClicked: root.crossOut("both")
        }
    }
}

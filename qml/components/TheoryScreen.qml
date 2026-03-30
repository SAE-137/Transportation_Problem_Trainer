import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "../components"
import App.Theory 1.0

Item {
    id: theoryScreen
    anchors.fill: parent

    property bool matrixCreated: false
    property bool workMatrixVisible: false
    property int iterationNumber: 1

    TheoryController {
        id: theoryController
    }

    ListModel {
        id: stepsModel
    }

    ScrollView {
        id: scrollView
        anchors.fill: parent
        clip: true

        ScrollBar.vertical.policy: ScrollBar.AsNeeded
        ScrollBar.horizontal.policy: ScrollBar.AsNeeded

        Column {
            id: pageColumn
            width: Math.max(scrollView.availableWidth, 900)
            spacing: 20

            Item { width: 1; height: 20 }

            Text {
                x: 40
                text: "Исходная задача"
                font.pixelSize: 24
                font.bold: true
                color: "#222222"
            }

            Text {
                x: 40
                width: pageColumn.width - 80
                text: "Эта матрица используется для ввода и после запуска решения больше не изменяется."
                wrapMode: Text.WordWrap
                font.pixelSize: 15
                color: "#555555"
            }

            Item {
                id: inputHolder
                x: 40
                width: inputMatrix.visible ? inputMatrix.implicitWidth : 0
                height: inputMatrix.visible ? inputMatrix.implicitHeight : 0
            }

            Text {
                x: 40
                visible: theoryController.statusText.length > 0
                width: pageColumn.width - 80
                text: theoryController.statusText
                wrapMode: Text.WordWrap
                font.pixelSize: 16
                color: "#333333"
            }

            Rectangle {
                x: 40
                width: pageColumn.width - 80
                height: 1
                color: "#d7d7d7"
                visible: workMatrixVisible
            }

            Text {
                x: 40
                visible: workMatrixVisible
                text: "Рабочая матрица"
                font.pixelSize: 24
                font.bold: true
                color: "#222222"
            }

            Text {
                x: 40
                visible: workMatrixVisible
                width: pageColumn.width - 80
                text: "Эта матрица изменяется алгоритмом. Именно с неё снимаются изображения шагов решения."
                wrapMode: Text.WordWrap
                font.pixelSize: 15
                color: "#555555"
            }

            Item {
                id: workHolder
                x: 40
                width: workMatrix.visible ? workMatrix.implicitWidth : 0
                height: workMatrix.visible ? workMatrix.implicitHeight : 0
                visible: workMatrixVisible
            }

            Rectangle {
                x: 40
                width: pageColumn.width - 80
                height: 1
                color: "#d7d7d7"
                visible: stepsModel.count > 0
            }

            Text {
                x: 40
                visible: stepsModel.count > 0
                text: "История шагов"
                font.pixelSize: 24
                font.bold: true
                color: "#222222"
            }

            Repeater {
                model: stepsModel

                delegate: Column {
                    width: pageColumn.width
                    spacing: 10

                    Text {
                        x: 40
                        text: (index + 1) + ". " + title
                        font.pixelSize: 20
                        font.bold: true
                        color: "#222222"
                    }

                    Text {
                        x: 40
                        width: pageColumn.width - 80
                        visible: description && description.length > 0
                        text: description
                        wrapMode: Text.WordWrap
                        font.pixelSize: 15
                        color: "#444444"
                    }

                    Rectangle {
                        x: 40
                        width: imageItem.paintedWidth + 16
                        height: imageItem.paintedHeight + 16
                        color: "#ffffff"
                        border.color: "#cfcfcf"
                        radius: 8
                        visible: imageSource !== ""

                        Image {
                            id: imageItem
                            anchors.centerIn: parent
                            source: imageSource
                            fillMode: Image.Pad
                            cache: true
                            asynchronous: true
                        }
                    }

                    Text {
                        x: 40
                        width: pageColumn.width - 80
                        visible: calculationText && calculationText.length > 0
                        text: calculationText
                        wrapMode: Text.WordWrap
                        font.pixelSize: 15
                        color: "#333333"
                    }
                }
            }

            Item { width: 1; height: 20 }
        }
    }

    MatrixView {
        id: inputMatrix
        parent: inputHolder
        x: 0
        y: 0

        visible: matrixCreated
        readOnly: false
        autoInit: false
        interactive: false
        showLoads: false
        showMarks: false

        rows: 0
        columns: 0
    }

    MatrixView {
        id: workMatrix
        parent: workHolder
        x: 0
        y: 0

        visible: workMatrixVisible
        readOnly: true
        autoInit: false
        interactive: false
        showLoads: true
        showMarks: true

        rows: 0
        columns: 0
    }

    function createMatrix(r, c) {
        if (r < 1 || c < 1)
            return

        matrixCreated = true
        workMatrixVisible = false
        iterationNumber = 1

        inputMatrix.resizeAndReset(r, c)
        workMatrix.resizeAndReset(r, c)

        clearHistory()
        theoryController.clear()
    }

    function randomize() {
        if (!matrixCreated)
            return

        if (inputMatrix.randomFill)
            inputMatrix.randomFill()
    }

    function clear() {
        clearHistory()
        theoryController.clear()

        inputMatrix.resizeAndReset(1, 1)
        workMatrix.resizeAndReset(1, 1)

        matrixCreated = false
        workMatrixVisible = false
        iterationNumber = 1
    }

    function solve() {
        if (!matrixCreated) {
            console.log("Матрица не создана")
            return
        }

        if (!inputMatrix.isComplete()) {
            console.log("Матрица заполнена не полностью")
            return
        }

        iterationNumber = 1

        const okBalance = theoryController.runBalanceStage(
            inputMatrix.costMatrix,
            inputMatrix.supply,
            inputMatrix.demand
        )

        if (!okBalance)
            return

        clearHistory()

        copyInputToWorkMatrix()
        workMatrixVisible = true

        captureWorkStep(
            "Исходная задача",
            "Исходная транспортная задача до этапа балансировки.",
            "",
            function() {
                if (theoryController.balanceNeeded) {
                    applyBalancedProblem()

                    captureWorkStep(
                        "Задача после балансировки",
                        theoryController.statusText,
                        "",
                        function() {
                            runMinCostAndCapture()
                        }
                    )
                } else {
                    captureWorkStep(
                        "Балансировка не требуется",
                        theoryController.statusText,
                        "",
                        function() {
                            runMinCostAndCapture()
                        }
                    )
                }
            }
        )
    }

    function copyInputToWorkMatrix() {
        const rows = inputMatrix.rows
        const cols = inputMatrix.columns

        workMatrix.resizeAndReset(rows, cols)

        workMatrix.costMatrix = copy2D(inputMatrix.costMatrix)
        workMatrix.supply = copy1D(inputMatrix.supply)
        workMatrix.demand = copy1D(inputMatrix.demand)

        workMatrix.loadMatrix = emptyStringMatrix(rows, cols)
        workMatrix.markMatrix = emptyStringMatrix(rows, cols)
        workMatrix.selectedRow = -1
        workMatrix.selectedCol = -1
        workMatrix.showLoads = true
        workMatrix.showMarks = true
    }

    function applyBalancedProblem() {
        const rows = theoryController.resultRows
        const cols = theoryController.resultCols

        if (rows < 1 || cols < 1)
            return

        workMatrix.resizeAndReset(rows, cols)

        workMatrix.costMatrix = toString2D(theoryController.resultCostMatrix)
        workMatrix.supply = toString1D(theoryController.resultSupply)
        workMatrix.demand = toString1D(theoryController.resultDemand)

        workMatrix.loadMatrix = emptyStringMatrix(rows, cols)
        workMatrix.markMatrix = emptyStringMatrix(rows, cols)
        workMatrix.selectedRow = -1
        workMatrix.selectedCol = -1
        workMatrix.showLoads = true
        workMatrix.showMarks = true
    }

    function captureWorkStep(title, description, calculationText, onDone) {
        if (!workMatrixVisible) {
            if (onDone)
                onDone()
            return
        }

        workMatrix.grabToImage(function(result) {
            stepsModel.append({
                title: title,
                description: description ? description : "",
                calculationText: calculationText ? calculationText : "",
                imageSource: result.url
            })

            if (onDone)
                onDone()
        })
    }

    function clearHistory() {
        stepsModel.clear()
    }

    function copy1D(arr) {
        let out = []
        for (let i = 0; i < arr.length; ++i)
            out.push(String(arr[i]))
        return out
    }

    function copy2D(arr) {
        let out = []
        for (let i = 0; i < arr.length; ++i) {
            let row = []
            for (let j = 0; j < arr[i].length; ++j)
                row.push(String(arr[i][j]))
            out.push(row)
        }
        return out
    }

    function toString1D(arr) {
        let out = []
        for (let i = 0; i < arr.length; ++i)
            out.push(String(arr[i]))
        return out
    }

    function toString2D(arr) {
        let out = []
        for (let i = 0; i < arr.length; ++i) {
            let row = []
            for (let j = 0; j < arr[i].length; ++j)
                row.push(String(arr[i][j]))
            out.push(row)
        }
        return out
    }

    function emptyStringMatrix(r, c) {
        let arr = []
        for (let i = 0; i < r; ++i) {
            let row = []
            for (let j = 0; j < c; ++j)
                row.push("")
            arr.push(row)
        }
        return arr
    }

    function runMinCostAndCapture() {
        const ok = theoryController.runMinCostStage()
        if (!ok)
            return

        playMinCostSteps(0)
    }

    function playMinCostSteps(index) {
        const steps = theoryController.minCostSteps

        if (!steps || index >= steps.length) {
            runPotentialStageAndCapture()
            return
        }

        const step = steps[index]
        applyMinCostStep(step)

        captureWorkStep(
            step.title,
            step.description,
            step.calculationText ? step.calculationText : "",
            function() {
                playMinCostSteps(index + 1)
            }
        )
    }

    function applyMinCostStep(step) {
        const rows = step.rows
        const cols = step.cols

        if (rows < 1 || cols < 1)
            return

        if (workMatrix.rows !== rows || workMatrix.columns !== cols)
            workMatrix.resizeAndReset(rows, cols)

        workMatrix.costMatrix = toString2D(step.costMatrix)
        workMatrix.supply = toString1D(step.supply)
        workMatrix.demand = toString1D(step.demand)
        workMatrix.loadMatrix = toString2D(step.loadMatrix)
        workMatrix.markMatrix = toString2D(step.markMatrix)
        workMatrix.selectedRow = step.selectedRow
        workMatrix.selectedCol = step.selectedCol
        workMatrix.showLoads = true
        workMatrix.showMarks = true
    }

    function runPotentialStageAndCapture() {
        const ok = theoryController.runPotentialStage()
        if (!ok)
            return

        playPotentialSteps(0)
    }

    function playPotentialSteps(index) {
        const steps = theoryController.potentialSteps

        if (!steps || index >= steps.length) {
            if (theoryController.potentialOptimal) {
                captureFinalSolution()
            } else {
                runCycleStageAndCapture()
            }
            return
        }

        const step = steps[index]
        applyPotentialStep(step)

        captureWorkStep(
            "Итерация " + iterationNumber + ". " + step.title,
            step.description,
            step.calculationText ? step.calculationText : "",
            function() {
                playPotentialSteps(index + 1)
            }
        )
    }

    function applyPotentialStep(step) {
        const rows = step.rows
        const cols = step.cols

        if (rows < 1 || cols < 1)
            return

        if (workMatrix.rows !== rows || workMatrix.columns !== cols)
            workMatrix.resizeAndReset(rows, cols)

        workMatrix.costMatrix = toString2D(step.costMatrix)
        workMatrix.supply = toString1D(step.supply)
        workMatrix.demand = toString1D(step.demand)
        workMatrix.loadMatrix = toString2D(step.loadMatrix)
        workMatrix.markMatrix = toString2D(step.markMatrix)
        workMatrix.selectedRow = step.selectedRow
        workMatrix.selectedCol = step.selectedCol
        workMatrix.showLoads = true
        workMatrix.showMarks = true
    }

    function runCycleStageAndCapture() {
        const ok = theoryController.runCycleStage()
        if (!ok)
            return

        playCycleSteps(0)
    }

    function playCycleSteps(index) {
        const steps = theoryController.cycleSteps

        if (!steps || index >= steps.length) {
            runRecalculationStageAndCapture()
            return
        }

        const step = steps[index]
        applyCycleStep(step)

        captureWorkStep(
            "Итерация " + iterationNumber + ". " + step.title,
            step.description,
            step.calculationText ? step.calculationText : "",
            function() {
                playCycleSteps(index + 1)
            }
        )
    }

    function applyCycleStep(step) {
        const rows = step.rows
        const cols = step.cols

        if (rows < 1 || cols < 1)
            return

        if (workMatrix.rows !== rows || workMatrix.columns !== cols)
            workMatrix.resizeAndReset(rows, cols)

        workMatrix.costMatrix = toString2D(step.costMatrix)
        workMatrix.supply = toString1D(step.supply)
        workMatrix.demand = toString1D(step.demand)
        workMatrix.loadMatrix = toString2D(step.loadMatrix)
        workMatrix.markMatrix = toString2D(step.markMatrix)
        workMatrix.selectedRow = step.selectedRow
        workMatrix.selectedCol = step.selectedCol
        workMatrix.showLoads = true
        workMatrix.showMarks = true
    }

    function runRecalculationStageAndCapture() {
        const ok = theoryController.runRecalculationStage()
        if (!ok)
            return

        playRecalculationSteps(0)
    }

    function playRecalculationSteps(index) {
        const steps = theoryController.recalculationSteps

        if (!steps || index >= steps.length) {
            iterationNumber += 1
            runPotentialStageAndCapture()
            return
        }

        const step = steps[index]
        applyRecalculationStep(step)

        captureWorkStep(
            "Итерация " + iterationNumber + ". " + step.title,
            step.description,
            step.calculationText ? step.calculationText : "",
            function() {
                playRecalculationSteps(index + 1)
            }
        )
    }

    function applyRecalculationStep(step) {
        const rows = step.rows
        const cols = step.cols

        if (rows < 1 || cols < 1)
            return

        if (workMatrix.rows !== rows || workMatrix.columns !== cols)
            workMatrix.resizeAndReset(rows, cols)

        workMatrix.costMatrix = toString2D(step.costMatrix)
        workMatrix.supply = toString1D(step.supply)
        workMatrix.demand = toString1D(step.demand)
        workMatrix.loadMatrix = toString2D(step.loadMatrix)
        workMatrix.markMatrix = toString2D(step.markMatrix)
        workMatrix.selectedRow = step.selectedRow
        workMatrix.selectedCol = step.selectedCol
        workMatrix.showLoads = true
        workMatrix.showMarks = true
    }

    function captureFinalSolution() {
        workMatrix.markMatrix = emptyStringMatrix(workMatrix.rows, workMatrix.columns)
        workMatrix.selectedRow = -1
        workMatrix.selectedCol = -1

        const total = theoryController.currentTotalCost()

        let calcText = "Итоговая стоимость плана:\n"
        for (let r = 0; r < workMatrix.rows; ++r) {
            for (let c = 0; c < workMatrix.columns; ++c) {
                const x = String(workMatrix.loadMatrix[r][c]).trim()
                if (x.length === 0)
                    continue

                const cost = Number(workMatrix.costMatrix[r][c])
                const load = Number(x)
                calcText += "c" + (r + 1) + (c + 1) + " * x" + (r + 1) + (c + 1) +
                            " = " + cost + " * " + load + " = " + (cost * load) + "\n"
            }
        }
        calcText += "\nZ = " + total

        captureWorkStep(
            "Оптимальное решение найдено",
            "После очередной проверки оптимальности все оценки стали неотрицательными.",
            calcText
        )
    }
}

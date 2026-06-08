import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "../components"
import App.Theory 1.0

Item {
    id: theoryScreen
    anchors.fill: parent

    property bool matrixCreated: false
    property var allStepsData: []
    property var errorNotifier: null

    TheoryController {
        id: theoryController
    }

    Flickable {
        id: flick
        anchors.fill: parent
        clip: true
        contentWidth: width
        contentHeight: pageColumn.implicitHeight + 32
        boundsBehavior: Flickable.StopAtBounds

        ScrollBar.vertical: ScrollBar { }

        NumberAnimation {
            id: scrollAnim
            target: flick
            property: "contentY"
            duration: 450
            easing.type: Easing.InOutQuad
        }

        Column {
            id: pageColumn
            width: flick.width
            spacing: 24

            Item { width: 1; height: 20 }

            Rectangle {
                id: inputSection
                width: Math.min(pageColumn.width - 40, inputMatrix.visible ? inputMatrix.implicitWidth + 80 : 760)
                height: inputColumn.implicitHeight + 32
                radius: 14
                color: "#ffffff"
                border.color: "#dcdcdc"
                anchors.horizontalCenter: parent.horizontalCenter

                Column {
                    id: inputColumn
                    x: 24
                    y: 16
                    width: parent.width - 48
                    spacing: 12

                    Text {
                        text: "Исходная задача"
                        font.pixelSize: 24
                        font.bold: true
                        color: "#222222"
                    }

                    Text {
                        width: parent.width
                        text: "Матрица для ввода данных."
                        wrapMode: Text.WordWrap
                        font.pixelSize: 15
                        color: "#666666"
                    }

                    Item {
                        id: inputHolder
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: inputMatrix.visible ? inputMatrix.implicitWidth : 0
                        height: inputMatrix.visible ? inputMatrix.implicitHeight : 0
                    }

                    Text {
                        visible: theoryController.statusText.length > 0
                        width: parent.width
                        text: theoryController.statusText
                        wrapMode: Text.WordWrap
                        font.pixelSize: 15
                        color: "#333333"
                    }

                    Text {
                        visible: allStepsData.length > 0
                        width: parent.width
                        text: "Количество шагов: " + allStepsData.length
                        wrapMode: Text.WordWrap
                        font.pixelSize: 15
                        color: "#333333"
                    }
                }
            }

            Item {
                id: solutionAnchor
                width: 1
                height: 1
                visible: allStepsData.length > 0
            }

            Rectangle {
                id: solutionSection
                visible: allStepsData.length > 0
                width: pageColumn.width - 40
                height: stepViewer.implicitHeight + 24
                radius: 14
                color: "#ffffff"
                border.color: "#dcdcdc"
                anchors.horizontalCenter: parent.horizontalCenter

                StepViewer {
                    id: stepViewer
                    anchors.fill: parent
                    anchors.margins: 12
                    allStepsData: theoryScreen.allStepsData
                }
            }

            Item { width: 1; height: 24 }
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

    function createMatrix(r, c) {
        if (r < 1 || c < 1)
            return

        matrixCreated = true
        inputMatrix.resizeAndReset(r, c)

        allStepsData = []

        theoryController.clear()
        flick.contentY = 0
    }

    function randomize() {
        if (!matrixCreated)
            return

        if (inputMatrix.randomFill)
            inputMatrix.randomFill()
    }

    function clear() {
        theoryController.clear()

        inputMatrix.resizeAndReset(1, 1)

        matrixCreated = false
        allStepsData = []

        flick.contentY = 0
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

        allStepsData = []

        const ok = theoryController.solveAll(
            inputMatrix.costMatrix,
            inputMatrix.supply,
            inputMatrix.demand
        )

        if (!ok)
            return

        allStepsData = theoryController.allSteps
        saveTaskToHistory()

        if (allStepsData.length > 0) {
            Qt.callLater(function() {
                scrollToSolution()
            })
        }

    }

    function scrollToSolution() {
        if (!solutionSection.visible)
            return

        const maxY = Math.max(0, flick.contentHeight - flick.height)
        const targetY = Math.max(0, Math.min(solutionAnchor.y - 12, maxY))

        scrollAnim.stop()
        scrollAnim.to = targetY
        scrollAnim.start()
    }

    signal historyEntryCreated(var entry)

    function copy1D(a) {
        return a ? a.slice() : []
    }

    function copy2D(a) {
        return a ? a.map(function(row) { return row.slice() }) : []
    }

    function clone2D(a) {
        return a ? a.map(function(row) { return row.slice() }) : []
    }

    function clone1D(a) {
        return a ? a.slice() : []
    }

    function saveTaskToHistory() {
        historyEntryCreated({
            moduleType: "Теория",
            title: "Теория " + inputMatrix.rows + "×" + inputMatrix.columns,
            rows: inputMatrix.rows,
            cols: inputMatrix.columns,
            costMatrix: copy2D(inputMatrix.costMatrix),
            supply: copy1D(inputMatrix.supply),
            demand: copy1D(inputMatrix.demand)
        })
    }


    function loadFromHistoryData(entry) {
        if (!entry || !entry.rows || !entry.cols)
            return

        createMatrix(entry.rows, entry.cols)

        inputMatrix.costMatrix = clone2D(entry.costMatrix)
        inputMatrix.supply = clone1D(entry.supply)
        inputMatrix.demand = clone1D(entry.demand)

        allStepsData = []
        theoryController.clear()
        flick.contentY = 0
    }
}

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    anchors.fill: parent

    // входные данные (приходят из PracticeScreen)
    property int rows: 0
    property int columns: 0
    property var costMatrix: []
    property var supply: []
    property var demand: []

    // локальная "новая" матрица этапа 3 (НЕ связана с входными массивами)
    property int localRows: 0
    property int localCols: 0
    property var localCost: []
    property var localSupply: []
    property var localDemand: []

    function zeroStr(x) {
        if (x === undefined || x === null) return "0"
        const s = String(x).trim()
        return (s === "") ? "0" : s
    }

    function rebuildLocal() {
        if (rows <= 0 || columns <= 0) {
            localRows = 0
            localCols = 0
            localCost = []
            localSupply = []
            localDemand = []
            return
        }

        localRows = rows
        localCols = columns

        // cost
        let outCost = []
        for (let r = 0; r < rows; r++) {
            let srcRow = (costMatrix && costMatrix[r]) ? costMatrix[r] : []
            let row = new Array(columns)
            for (let c = 0; c < columns; c++) {
                row[c] = zeroStr(srcRow[c])
            }
            outCost.push(row)
        }

        // supply
        let outSupply = new Array(rows)
        for (let r = 0; r < rows; r++) {
            outSupply[r] = zeroStr(supply ? supply[r] : undefined)
        }

        // demand
        let outDemand = new Array(columns)
        for (let c = 0; c < columns; c++) {
            outDemand[c] = zeroStr(demand ? demand[c] : undefined)
        }

        // присваиваем НОВЫЕ массивы (чтобы QML точно обновил UI)
        localCost = outCost
        localSupply = outSupply
        localDemand = outDemand
    }

    // пересобираем, когда что-то пришло/поменялось
    onRowsChanged: rebuildLocal()
    onColumnsChanged: rebuildLocal()
    onCostMatrixChanged: rebuildLocal()
    onSupplyChanged: rebuildLocal()
    onDemandChanged: rebuildLocal()

    Component.onCompleted: rebuildLocal()

    ColumnLayout {
        anchors.fill: parent
        spacing: 14

        Text {
            text: "Этап 3: Построение начального плана (метод минимального тарифа)"
            font.pixelSize: 20
            color: "#111"
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
        }

        // показываем локальную копию (гарантированно заполненную)
        MatrixView {
            id: matrixPreview
            Layout.alignment: Qt.AlignHCenter
            readOnly: true
            autoInit: false

            rows: root.localRows
            columns: root.localCols
            costMatrix: root.localCost
            supply: root.localSupply
            demand: root.localDemand
        }

        Item { Layout.fillHeight: true }
    }
}

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


    property int localRows: 0
    property int localCols: 0
    property var localCost: []
    property var localSupply: []
    property var localDemand: []

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


        let outCost = new Array(rows)
        for (let r = 0; r < rows; r++) {
            let srcRow = (costMatrix && costMatrix[r]) ? costMatrix[r] : []
            let row = new Array(columns)
            for (let c = 0; c < columns; c++) {
                row[c] = srcRow[c]
            }
            outCost[r] = row
        }

        let outSupply = new Array(rows)
        for (let r = 0; r < rows; r++) outSupply[r] = supply ? supply[r] : undefined

        let outDemand = new Array(columns)
        for (let c = 0; c < columns; c++) outDemand[c] = demand ? demand[c] : undefined

        if (balanceWho === 0 && balanceVolume > 0) {
            // фиктивный поставщик (строка)
            localRows = rows + 1
            outCost.push(new Array(columns).fill("0"))
            outSupply.push(String(balanceVolume))
            // demand без изменений
        } else if (balanceWho === 1 && balanceVolume > 0) {
            // фиктивный потребитель (столбец)
            localCols = columns + 1
            for (let r = 0; r < rows; r++) outCost[r].push("0")
            outDemand.push(String(balanceVolume))

        }


        localCost = outCost
        localSupply = outSupply
        localDemand = outDemand
    }


    function rebuildIfVisible() {
        if (root.visible) rebuildLocal()
    }

    onVisibleChanged: {
        if (visible) rebuildLocal()
    }

    onRowsChanged: rebuildIfVisible()
    onColumnsChanged: rebuildIfVisible()
    onCostMatrixChanged: rebuildIfVisible()
    onSupplyChanged: rebuildIfVisible()
    onDemandChanged: rebuildIfVisible()
    onBalanceWhoChanged: rebuildIfVisible()
    onBalanceVolumeChanged: rebuildIfVisible()

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

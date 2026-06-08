import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    property bool readOnly: false
    property bool autoInit: true

    property bool interactive: false
    signal cellClicked(int r, int c)
    property int selectedRow: -1
    property int selectedCol: -1

    property bool showLoads: false

    property bool showMarks: false
    property var markMatrix: []

    // Матрица цветов ячеек.
    // MatrixView сам не решает, какие клетки красить.
    // Если cellBackgroundMatrix[r][c] задана, ячейка получает этот цвет.
    property var cellBackgroundMatrix: []

    signal changed()

    property int rows: 3
    property int columns: 3

    property var costMatrix: []
    property var loadMatrix: []
    property var supply: []
    property var demand: []

    implicitWidth: content.implicitWidth
    implicitHeight: content.implicitHeight

    function cellBackgroundAt(r, c) {
        if (!cellBackgroundMatrix || !cellBackgroundMatrix[r])
            return ""

        const value = cellBackgroundMatrix[r][c]

        if (value === undefined || value === null)
            return ""

        return String(value).trim()
    }

    function resizeAndReset(newRows, newColumns) {
        if (newRows < 1 || newColumns < 1)
            return

        const newCostMatrix = Array.from({ length: newRows }, function() {
            return Array.from({ length: newColumns }, function() { return "" })
        })

        const newLoadMatrix = Array.from({ length: newRows }, function() {
            return Array.from({ length: newColumns }, function() { return "" })
        })

        const newSupply = Array.from({ length: newRows }, function() { return "" })
        const newDemand = Array.from({ length: newColumns }, function() { return "" })

        selectedRow = -1
        selectedCol = -1

        costMatrix = newCostMatrix
        loadMatrix = newLoadMatrix
        supply = newSupply
        demand = newDemand

        rows = newRows
        columns = newColumns

        root.changed()
    }

    Column {
        id: content
        spacing: 6

        Row {
            spacing: 4

            Rectangle {
                width: 70
                height: 40
                color: "#e8e8e8"
                border.color: "#666"
                radius: 4
            }

            Repeater {
                id: topHeaderRepeater
                model: columns

                delegate: Rectangle {
                    width: 70
                    height: 40
                    color: "#e8e8e8"
                    border.color: "#666"
                    radius: 4

                    Text {
                        anchors.centerIn: parent
                        font.pixelSize: 16
                        text: "B" + (index + 1)
                    }
                }
            }

            Rectangle {
                width: 70
                height: 40
                color: "#f7f7f7"
                border.color: "#666"
                radius: 4

                Text {
                    anchors.centerIn: parent
                    font.pixelSize: 12
                    color: "#444"
                    text: "Запасы"
                }
            }
        }

        Row {
            spacing: 4

            Column {
                spacing: 4

                Repeater {
                    id: leftLabelsRepeater
                    model: rows

                    delegate: Rectangle {
                        width: 70
                        height: 70
                        color: "#e8e8e8"
                        border.color: "#666"
                        radius: 4

                        Text {
                            anchors.centerIn: parent
                            font.pixelSize: 16
                            text: "A" + (index + 1)
                        }
                    }
                }

                Rectangle {
                    width: 70
                    height: 70
                    color: "#f7f7f7"
                    border.color: "#666"
                    radius: 4

                    Text {
                        anchors.centerIn: parent
                        font.pixelSize: 13
                        color: "#444"
                        text: "Потреб."
                    }
                }
            }

            Column {
                spacing: 4

                Repeater {
                    id: matrixRepeater
                    model: rows

                    Row {
                        id: rowRow
                        property int rowIndex: index
                        spacing: 4

                        Repeater {
                            model: columns

                            delegate: Rectangle {
                                readonly property int r: rowRow.rowIndex
                                readonly property int c: index
                                readonly property string customBackground: root.cellBackgroundAt(r, c)

                                width: 70
                                height: 70

                                color: {
                                    if (customBackground.length > 0)
                                        return customBackground

                                    if (r === root.selectedRow && c === root.selectedCol)
                                        return "#dcfce7"

                                    return "#ffffff"
                                }

                                border.color: "#555"
                                border.width: 1

                                radius: 6
                                clip: true

                                TextInput {
                                    anchors.top: parent.top
                                    anchors.left: parent.left
                                    anchors.margins: 6

                                    width: parent.width - 12
                                    height: 22

                                    font.pixelSize: 16
                                    horizontalAlignment: Text.AlignLeft
                                    verticalAlignment: Text.AlignTop

                                    text: (root.costMatrix
                                           && root.costMatrix[r]
                                           && root.costMatrix[r][c] !== undefined
                                           && root.costMatrix[r][c] !== null)
                                          ? String(root.costMatrix[r][c])
                                          : ""

                                    validator: IntValidator { bottom: 0 }
                                    inputMethodHints: Qt.ImhDigitsOnly
                                    maximumLength: 6
                                    clip: true

                                    readOnly: root.readOnly
                                    activeFocusOnPress: !root.readOnly

                                    onTextEdited: {
                                        if (root.readOnly)
                                            return

                                        if (!root.costMatrix || !root.costMatrix[r])
                                            return

                                        if (text === "") {
                                            root.costMatrix[r][c] = ""
                                        } else if (acceptableInput) {
                                            root.costMatrix[r][c] = text
                                        } else {
                                            return
                                        }

                                        root.costMatrix = root.costMatrix.map(function(row) {
                                            return row.slice()
                                        })

                                        root.changed()
                                    }
                                }

                                Rectangle {
                                    width: 26
                                    height: 18
                                    radius: 4
                                    anchors.top: parent.top
                                    anchors.right: parent.right
                                    anchors.margins: 4
                                    z: 5

                                    property string v: {
                                        if (!root.loadMatrix || !root.loadMatrix[r])
                                            return ""

                                        const x = root.loadMatrix[r][c]

                                        if (x === undefined || x === null)
                                            return ""

                                        return String(x).trim()
                                    }

                                    visible: root.showLoads && v.length > 0
                                    color: "#11111122"
                                    border.color: "#11111155"

                                    Text {
                                        anchors.centerIn: parent
                                        font.pixelSize: 12
                                        color: "#111"
                                        text: parent.v
                                    }
                                }

                                Rectangle {
                                    width: 22
                                    height: 18
                                    radius: 4
                                    anchors.bottom: parent.bottom
                                    anchors.right: parent.right
                                    anchors.margins: 4
                                    z: 6

                                    property string m: {
                                        if (!root.markMatrix || !root.markMatrix[r])
                                            return ""

                                        const t = root.markMatrix[r][c]

                                        if (t === undefined || t === null)
                                            return ""

                                        return String(t).trim()
                                    }

                                    visible: root.showMarks && m.length > 0
                                    color: "#16a34a22"
                                    border.color: "#16a34a55"

                                    Text {
                                        anchors.centerIn: parent
                                        font.pixelSize: 12
                                        color: "#111"
                                        text: parent.m
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    enabled: root.interactive
                                    z: 10

                                    onClicked: {
                                        root.selectedRow = r
                                        root.selectedCol = c
                                        root.cellClicked(r, c)
                                    }
                                }
                            }
                        }

                        Rectangle {
                            width: 70
                            height: 70
                            color: "#fff8e6"
                            border.color: "#666"
                            radius: 4
                            clip: true

                            TextInput {
                                readonly property int r: rowRow.rowIndex

                                text: (root.supply
                                       && root.supply[r] !== undefined
                                       && root.supply[r] !== null)
                                      ? String(root.supply[r])
                                      : ""

                                anchors.centerIn: parent
                                width: parent.width - 12
                                height: 28

                                font.pixelSize: 18
                                color: "#333"
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter

                                validator: IntValidator { bottom: 0 }
                                inputMethodHints: Qt.ImhDigitsOnly
                                maximumLength: 6
                                clip: true

                                readOnly: root.readOnly
                                activeFocusOnPress: !root.readOnly

                                onTextEdited: {
                                    if (root.readOnly)
                                        return

                                    if (!root.supply)
                                        return

                                    if (text === "") {
                                        root.supply[r] = ""
                                    } else if (acceptableInput) {
                                        root.supply[r] = text
                                    } else {
                                        return
                                    }

                                    root.supply = root.supply.slice()
                                    root.changed()
                                }
                            }
                        }
                    }
                }

                Row {
                    spacing: 4

                    Repeater {
                        id: bottomDemandRepeater
                        model: columns

                        delegate: Rectangle {
                            width: 70
                            height: 70
                            radius: 4
                            color: "#fff8e6"
                            border.color: "#666"
                            clip: true

                            TextInput {
                                text: (root.demand
                                       && root.demand[index] !== undefined
                                       && root.demand[index] !== null)
                                      ? String(root.demand[index])
                                      : ""

                                anchors.centerIn: parent
                                width: parent.width - 12
                                height: 28

                                font.pixelSize: 18
                                color: "#333"
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter

                                validator: IntValidator { bottom: 0 }
                                inputMethodHints: Qt.ImhDigitsOnly
                                maximumLength: 6
                                clip: true

                                readOnly: root.readOnly
                                activeFocusOnPress: !root.readOnly

                                onTextEdited: {
                                    if (root.readOnly)
                                        return

                                    if (!root.demand)
                                        return

                                    if (text === "") {
                                        root.demand[index] = ""
                                    } else if (acceptableInput) {
                                        root.demand[index] = text
                                    } else {
                                        return
                                    }

                                    root.demand = root.demand.slice()
                                    root.changed()
                                }
                            }
                        }
                    }

                    Item {
                        width: 70
                        height: 70
                    }
                }
            }
        }
    }

    Component.onCompleted: {
        if (autoInit)
            resizeAndReset(rows, columns)
    }

    function isComplete() {
        if (!costMatrix || !supply || !demand)
            return false

        for (let r = 0; r < rows; r++) {
            if (!costMatrix[r])
                return false

            for (let c = 0; c < columns; c++) {
                if (costMatrix[r][c] === "" || costMatrix[r][c] === undefined || costMatrix[r][c] === null)
                    return false
            }

            if (supply[r] === "" || supply[r] === undefined || supply[r] === null)
                return false
        }

        for (let c = 0; c < columns; c++) {
            if (demand[c] === "" || demand[c] === undefined || demand[c] === null)
                return false
        }

        return true
    }

    function randomFill() {
        const newCostMatrix = []
        const newSupply = []
        const newDemand = []

        for (let r = 0; r < rows; r++) {
            const row = []

            for (let c = 0; c < columns; c++) {
                row.push(String(Math.floor(Math.random() * 30) + 1))
            }

            newCostMatrix.push(row)
            newSupply.push(String(Math.floor(Math.random() * 50) + 10))
        }

        for (let c = 0; c < columns; c++) {
            newDemand.push(String(Math.floor(Math.random() * 50) + 10))
        }

        costMatrix = newCostMatrix
        supply = newSupply
        demand = newDemand

        changed()
    }
}

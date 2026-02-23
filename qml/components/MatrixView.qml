import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    property bool readOnly: false
    property bool autoInit: true

    // ✅ интерактивность ячеек тарифов (клики)
    property bool interactive: false
    signal cellClicked(int r, int c)
    property int selectedRow: -1
    property int selectedCol: -1

    // ✅ показывать перевозки x_ij (loadMatrix) маленьким бейджем в углу
    property bool showLoads: false

    signal changed()

    property int rows: 3
    property int columns: 3

    property var costMatrix: []
    property var loadMatrix: []
    property var supply: []
    property var demand: []

    implicitWidth: content.implicitWidth
    implicitHeight: content.implicitHeight

    function resizeAndReset(newRows, newColumns) {
        if (newRows < 1 || newColumns < 1) return;

        rows = newRows
        columns = newColumns

        costMatrix = Array(rows).fill("").map(() => Array(columns).fill(""))
        loadMatrix = Array(rows).fill("").map(() => Array(columns).fill(""))
        supply = Array(rows).fill("")
        demand = Array(columns).fill("")

        // сброс выбора
        selectedRow = -1
        selectedCol = -1

        topHeaderRepeater.model = 0;    topHeaderRepeater.model = columns
        leftLabelsRepeater.model = 0;   leftLabelsRepeater.model = rows
        matrixRepeater.model = 0;       matrixRepeater.model = rows
        bottomDemandRepeater.model = 0; bottomDemandRepeater.model = columns

        root.changed()
    }

    Column {
        id: content
        spacing: 6

        // Верхний заголовок
        Row {
            spacing: 4

            Rectangle { width: 70; height: 40; color: "#e8e8e8"; border.color: "#666"; radius: 4 }

            Repeater {
                id: topHeaderRepeater
                model: columns
                delegate: Rectangle {
                    width: 70; height: 40
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
                width: 70; height: 40
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

            // Левый столбец B1..Bm + "Потреб."
            Column {
                spacing: 4

                Repeater {
                    id: leftLabelsRepeater
                    model: rows
                    delegate: Rectangle {
                        width: 70; height: 70
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
                    width: 70; height: 70
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

            // Центральная матрица + нижний demand
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

                                width: 70; height: 70
                                color: (root.interactive && r === root.selectedRow && c === root.selectedCol)
                                       ? "#dbeafe"
                                       : "#ffffff"
                                border.color: "#555"
                                radius: 6
                                clip: true

                                // тариф c_ij
                                TextInput {
                                    anchors.top: parent.top
                                    anchors.left: parent.left
                                    anchors.margins: 6

                                    width: parent.width - 12
                                    height: 22

                                    font.pixelSize: 16
                                    horizontalAlignment: Text.AlignLeft
                                    verticalAlignment: Text.AlignTop

                                    text: costMatrix[r][c]
                                    validator: IntValidator { bottom: 0 }
                                    inputMethodHints: Qt.ImhDigitsOnly
                                    maximumLength: 6
                                    clip: true

                                    readOnly: root.readOnly
                                    activeFocusOnPress: !root.readOnly

                                    onTextChanged: {
                                        if (text === "") {
                                            costMatrix[r][c] = ""
                                            costMatrix = costMatrix
                                            root.changed()
                                            return
                                        }
                                        if (acceptableInput) {
                                            costMatrix[r][c] = text
                                            costMatrix = costMatrix
                                        }
                                        root.changed()
                                    }
                                }

                                // ✅ бейдж для x_ij (перевозки) — правый верхний угол
                                Rectangle {
                                    id: loadBadge
                                    width: 26
                                    height: 18
                                    radius: 4
                                    anchors.top: parent.top
                                    anchors.right: parent.right
                                    anchors.margins: 4
                                    z: 5

                                    property string v: {
                                        if (!root.loadMatrix || !root.loadMatrix[r]) return ""
                                        const x = root.loadMatrix[r][c]
                                        if (x === undefined || x === null) return ""
                                        const s = String(x).trim()
                                        return s
                                    }

                                    visible: root.showLoads && v.length > 0
                                    color: "#11111122"
                                    border.color: "#11111155"

                                    Text {
                                        anchors.centerIn: parent
                                        font.pixelSize: 12
                                        color: "#111"
                                        text: loadBadge.v
                                    }
                                }

                                // ✅ клик по ячейке (только если interactive=true)
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

                        // Запасы (supply)
                        Rectangle {
                            width: 70; height: 70
                            color: "#fff8e6"
                            border.color: "#666"
                            radius: 4
                            clip: true

                            TextInput {
                                readonly property int r: rowRow.rowIndex
                                text: supply[r]

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

                                onTextChanged: {
                                    if (text === "") {
                                        supply[r] = ""
                                        supply = supply
                                        root.changed()
                                        return
                                    }
                                    if (acceptableInput) {
                                        supply[r] = text
                                        supply = supply
                                    }
                                    root.changed()
                                }
                            }
                        }
                    }
                }

                // Нижний ряд — спрос (demand)
                Row {
                    spacing: 4

                    Repeater {
                        id: bottomDemandRepeater
                        model: columns
                        delegate: Rectangle {
                            width: 70; height: 70
                            radius: 4
                            color: "#fff8e6"
                            border.color: "#666"
                            clip: true

                            TextInput {
                                text: demand[index]

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

                                onTextChanged: {
                                    if (text === "") {
                                        demand[index] = ""
                                        demand = demand
                                        root.changed()
                                        return
                                    }
                                    if (acceptableInput) {
                                        demand[index] = text
                                        demand = demand
                                    }
                                    root.changed()
                                }
                            }
                        }
                    }

                    Item { width: 70; height: 70 }
                }
            }
        }
    }

    Component.onCompleted: {
        if (autoInit)
            resizeAndReset(rows, columns)
    }

    function isComplete() {
        for (let r = 0; r < rows; r++) {
            for (let c = 0; c < columns; c++) {
                if (costMatrix[r][c] === "" || costMatrix[r][c] === undefined)
                    return false
            }
            if (supply[r] === "" || supply[r] === undefined)
                return false
        }
        for (let c = 0; c < columns; c++) {
            if (demand[c] === "" || demand[c] === undefined)
                return false
        }
        return true
    }

    function randomFill() {
        for (let r = 0; r < rows; r++) {
            for (let c = 0; c < columns; c++) {
                costMatrix[r][c] = String(Math.floor(Math.random() * 30) + 1)
            }
            supply[r] = String(Math.floor(Math.random() * 50) + 10)
        }
        for (let c = 0; c < columns; c++) {
            demand[c] = String(Math.floor(Math.random() * 50) + 10)
        }

        // “пинки” для обновления
        costMatrix = costMatrix.map(row => row.slice())
        supply = supply.slice()
        demand = demand.slice()

        changed()
    }
}

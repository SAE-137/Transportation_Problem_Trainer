import QtQuick

Item {
    id: root

    property bool autoInit: true

    property bool interactive: false
    signal cellClicked(int r, int c)

    property int selectedRow: -1
    property int selectedCol: -1

    property bool showLoads: false
    property bool showMarks: false

    property var costMatrix: []
    property var loadMatrix: []
    property var supply: []
    property var demand: []
    property var markMatrix: []

    property int rows: 3
    property int columns: 3

    property int headerWidth: 70
    property int headerHeight: 40
    property int cellSize: 70
    property int spacingSize: 4

    // Базовая палитра
    property color pageWhite: "#ffffff"
    property color surfaceWhite: "#fcfcfd"
    property color headerColor: "#eef1f5"
    property color sideValueColor: "#f8f2e8"
    property color cornerLabelColor: "#f5f6f8"

    property color borderSoft: "#aeb7c2"
    property color borderCell: "#8f99a6"

    property color textMain: "#1f2937"
    property color textMuted: "#5b6472"

    // Спокойная подсветка выбранной клетки
    property color selectedCellColor: "#e8f1ff"

    implicitWidth: content.implicitWidth
    implicitHeight: content.implicitHeight

    function resizeAndReset(newRows, newColumns) {
        if (newRows < 1 || newColumns < 1)
            return

        rows = newRows
        columns = newColumns

        costMatrix = Array(rows).fill("").map(() => Array(columns).fill(""))
        loadMatrix = Array(rows).fill("").map(() => Array(columns).fill(""))
        markMatrix = Array(rows).fill("").map(() => Array(columns).fill(""))
        supply = Array(rows).fill("")
        demand = Array(columns).fill("")

        selectedRow = -1
        selectedCol = -1
    }

    function safeString(value) {
        if (value === undefined || value === null)
            return ""
        return String(value)
    }

    function cellValue(matrix, r, c) {
        if (!matrix || !matrix[r] || matrix[r][c] === undefined || matrix[r][c] === null)
            return ""
        return String(matrix[r][c]).trim()
    }

    function vectorValue(vec, i) {
        if (!vec || vec[i] === undefined || vec[i] === null)
            return ""
        return String(vec[i]).trim()
    }

    function currentMark(r, c) {
        return cellValue(markMatrix, r, c)
    }

    function currentLoad(r, c) {
        return cellValue(loadMatrix, r, c)
    }

    function hasMark(r, c) {
        return currentMark(r, c).length > 0
    }

    function hasLoad(r, c) {
        return currentLoad(r, c).length > 0
    }

    function cellBackground(r, c) {
        if (r === selectedRow && c === selectedCol)
            return selectedCellColor

        const m = currentMark(r, c)

        if (m === "B")
            return "#edf4ff"   // базис
        if (m === "min")
            return "#fff8e8"   // минимальный тариф
        if (m === "x")
            return "#f4efff"   // заполненная клетка
        if (m === "r")
            return "#fff0f1"   // входящая клетка
        if (m === "+")
            return "#eefaf1"   // плюс
        if (m === "-")
            return "#fff4ea"   // минус
        if (m === "del")
            return "#fff1f7"   // удаляемая клетка

        return pageWhite
    }

    function cellBorder(r, c) {
        if (r === selectedRow && c === selectedCol)
            return "#7aa2e3"

        const m = currentMark(r, c)

        if (m === "B")
            return "#b7ccef"
        if (m === "min")
            return "#e7d49d"
        if (m === "x")
            return "#cfbff0"
        if (m === "r")
            return "#e8bcc4"
        if (m === "+")
            return "#b8dfc2"
        if (m === "-")
            return "#e8c4a1"
        if (m === "del")
            return "#e7bfd1"

        return borderCell
    }

    function markFillColor(mark) {
        if (mark === "B")
            return "#dbeafe"
        if (mark === "min")
            return "#fef3c7"
        if (mark === "x")
            return "#ede9fe"
        if (mark === "r")
            return "#ffe4e6"
        if (mark === "+")
            return "#dcfce7"
        if (mark === "-")
            return "#ffedd5"
        if (mark === "del")
            return "#fce7f3"
        return "#eef2f7"
    }

    function markBorderColor(mark) {
        if (mark === "B")
            return "#93c5fd"
        if (mark === "min")
            return "#f3cc74"
        if (mark === "x")
            return "#c4b5fd"
        if (mark === "r")
            return "#f2b3bc"
        if (mark === "+")
            return "#86d39b"
        if (mark === "-")
            return "#f0bd86"
        if (mark === "del")
            return "#f3b4d0"
        return "#cfd8e3"
    }

    function markTextColor(mark) {
        if (mark === "B")
            return "#1d4ed8"
        if (mark === "min")
            return "#a16207"
        if (mark === "x")
            return "#6d28d9"
        if (mark === "r")
            return "#be123c"
        if (mark === "+")
            return "#15803d"
        if (mark === "-")
            return "#c2410c"
        if (mark === "del")
            return "#be185d"
        return textMain
    }

    function loadFillColor() {
        return "#f3f4f6"
    }

    function loadBorderColor() {
        return "#c7ced8"
    }

    function loadTextColor() {
        return "#374151"
    }

    Column {
        id: content
        spacing: 6

        Row {
            spacing: root.spacingSize

            Rectangle {
                width: root.headerWidth
                height: root.headerHeight
                color: root.headerColor
                border.color: root.borderSoft
                radius: 4
            }

            Repeater {
                model: root.columns

                delegate: Rectangle {
                    width: root.headerWidth
                    height: root.headerHeight
                    color: root.headerColor
                    border.color: root.borderSoft
                    radius: 4

                    Text {
                        anchors.centerIn: parent
                        font.pixelSize: 16
                        font.bold: true
                        color: root.textMain
                        text: "A" + (index + 1)
                    }
                }
            }

            Rectangle {
                width: root.headerWidth
                height: root.headerHeight
                color: root.cornerLabelColor
                border.color: root.borderSoft
                radius: 4

                Text {
                    anchors.centerIn: parent
                    font.pixelSize: 12
                    color: root.textMuted
                    text: "Запасы"
                }
            }
        }

        Row {
            spacing: root.spacingSize

            Column {
                spacing: root.spacingSize

                Repeater {
                    model: root.rows

                    delegate: Rectangle {
                        width: root.headerWidth
                        height: root.cellSize
                        color: root.headerColor
                        border.color: root.borderSoft
                        radius: 4

                        Text {
                            anchors.centerIn: parent
                            font.pixelSize: 16
                            font.bold: true
                            color: root.textMain
                            text: "B" + (index + 1)
                        }
                    }
                }

                Rectangle {
                    width: root.headerWidth
                    height: root.cellSize
                    color: root.cornerLabelColor
                    border.color: root.borderSoft
                    radius: 4

                    Text {
                        anchors.centerIn: parent
                        font.pixelSize: 13
                        color: root.textMuted
                        text: "Потреб."
                    }
                }
            }

            Column {
                spacing: root.spacingSize

                Repeater {
                    model: root.rows

                    delegate: Row {
                        id: rowItem
                        property int rowIndex: index
                        spacing: root.spacingSize

                        Repeater {
                            model: root.columns

                            delegate: Rectangle {
                                readonly property int r: rowItem.rowIndex
                                readonly property int c: index
                                readonly property string costText: root.cellValue(root.costMatrix, r, c)
                                readonly property string loadText: root.currentLoad(r, c)
                                readonly property string markText: root.currentMark(r, c)

                                width: root.cellSize
                                height: root.cellSize
                                radius: 6
                                border.color: root.cellBorder(r, c)
                                border.width: (r === root.selectedRow && c === root.selectedCol) ? 2 : 1
                                color: root.cellBackground(r, c)

                                Text {
                                    anchors.top: parent.top
                                    anchors.left: parent.left
                                    anchors.margins: 6
                                    width: parent.width - 12
                                    text: parent.costText
                                    font.pixelSize: 16
                                    font.bold: true
                                    color: root.textMain
                                    wrapMode: Text.NoWrap
                                    elide: Text.ElideRight
                                    horizontalAlignment: Text.AlignLeft
                                    verticalAlignment: Text.AlignTop
                                }

                                Rectangle {
                                    width: Math.max(28, loadLabel.implicitWidth + 10)
                                    height: 20
                                    radius: 5
                                    anchors.top: parent.top
                                    anchors.right: parent.right
                                    anchors.margins: 4
                                    z: 2

                                    visible: root.showLoads && loadText.length > 0
                                    color: root.loadFillColor()
                                    border.color: root.loadBorderColor()

                                    Text {
                                        id: loadLabel
                                        anchors.centerIn: parent
                                        font.pixelSize: 12
                                        font.bold: true
                                        color: root.loadTextColor()
                                        text: loadText
                                    }
                                }

                                Rectangle {
                                    width: Math.max(markText === "del" ? 32 : 24, markLabel.implicitWidth + 10)
                                    height: 20
                                    radius: 5
                                    anchors.bottom: parent.bottom
                                    anchors.right: parent.right
                                    anchors.margins: 4
                                    z: 3

                                    visible: root.showMarks && markText.length > 0
                                    color: root.markFillColor(markText)
                                    border.color: root.markBorderColor(markText)

                                    Text {
                                        id: markLabel
                                        anchors.centerIn: parent
                                        font.pixelSize: markText === "del" ? 10 : 12
                                        font.bold: true
                                        color: root.markTextColor(markText)
                                        text: markText
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    enabled: root.interactive
                                    onClicked: {
                                        root.selectedRow = r
                                        root.selectedCol = c
                                        root.cellClicked(r, c)
                                    }
                                }
                            }
                        }

                        Rectangle {
                            width: root.headerWidth
                            height: root.cellSize
                            color: root.sideValueColor
                            border.color: root.borderSoft
                            radius: 4

                            Text {
                                anchors.centerIn: parent
                                width: parent.width - 12
                                text: root.vectorValue(root.supply, rowItem.rowIndex)
                                font.pixelSize: 18
                                font.bold: true
                                color: root.textMain
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                elide: Text.ElideRight
                            }
                        }
                    }
                }

                Row {
                    spacing: root.spacingSize

                    Repeater {
                        model: root.columns

                        delegate: Rectangle {
                            width: root.headerWidth
                            height: root.cellSize
                            radius: 4
                            color: root.sideValueColor
                            border.color: root.borderSoft

                            Text {
                                anchors.centerIn: parent
                                width: parent.width - 12
                                text: root.vectorValue(root.demand, index)
                                font.pixelSize: 18
                                font.bold: true
                                color: root.textMain
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                elide: Text.ElideRight
                            }
                        }
                    }

                    Item {
                        width: root.headerWidth
                        height: root.cellSize
                    }
                }
            }
        }
    }

    Component.onCompleted: {
        if (autoInit)
            resizeAndReset(rows, columns)
    }
}

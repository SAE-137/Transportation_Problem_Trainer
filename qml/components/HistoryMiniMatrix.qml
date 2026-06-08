import QtQuick

Item {
    id: root

    property int rows: 0
    property int columns: 0
    property var costMatrix: []
    property var supply: []
    property var demand: []

    property int maxPreviewWidth: 280
    property int maxPreviewHeight: 140

    readonly property int cellW: 28
    readonly property int cellH: 24
    readonly property int gap: 4

    readonly property int rawGridWidth: {
        if (columns <= 0)
            return 0
        return columns * cellW + Math.max(columns - 1, 0) * gap + gap + cellW
    }

    readonly property int rawGridHeight: {
        if (rows <= 0)
            return 0
        return rows * cellH + Math.max(rows - 1, 0) * gap + gap + cellH
    }

    readonly property real scaleFactor: {
        if (rawGridWidth <= 0 || rawGridHeight <= 0)
            return 1.0

        const sx = maxPreviewWidth / rawGridWidth
        const sy = maxPreviewHeight / rawGridHeight
        return Math.min(sx, sy, 1.0)
    }

    implicitWidth: maxPreviewWidth
    implicitHeight: maxPreviewHeight
    clip: true

    function costAt(r, c) {
        if (!costMatrix || !costMatrix[r] || costMatrix[r][c] === undefined)
            return ""
        return String(costMatrix[r][c])
    }

    function supplyAt(r) {
        if (!supply || supply[r] === undefined)
            return ""
        return String(supply[r])
    }

    function demandAt(c) {
        if (!demand || demand[c] === undefined)
            return ""
        return String(demand[c])
    }

    Item {
        id: matrixScene
        width: root.rawGridWidth
        height: root.rawGridHeight
        anchors.centerIn: parent
        scale: root.scaleFactor
        transformOrigin: Item.Center

        Column {
            anchors.fill: parent
            spacing: root.gap

            Repeater {
                model: root.rows

                delegate: Row {
                    required property int index
                    property int rowIndex: index
                    spacing: root.gap

                    Repeater {
                        model: root.columns

                        delegate: Rectangle {
                            required property int index
                            width: root.cellW
                            height: root.cellH
                            radius: 6
                            color: "#f8f4ee"
                            border.color: "#ddd2c5"

                            Text {
                                anchors.centerIn: parent
                                text: root.costAt(rowIndex, index)
                                font.pixelSize: 10
                                color: "#3b342d"
                            }
                        }
                    }

                    Rectangle {
                        width: root.cellW
                        height: root.cellH
                        radius: 6
                        color: "#e8f0fb"
                        border.color: "#c8d8ee"

                        Text {
                            anchors.centerIn: parent
                            text: root.supplyAt(rowIndex)
                            font.pixelSize: 10
                            color: "#38516d"
                        }
                    }
                }
            }

            Row {
                spacing: root.gap
                visible: root.columns > 0

                Repeater {
                    model: root.columns

                    delegate: Rectangle {
                        required property int index
                        width: root.cellW
                        height: root.cellH
                        radius: 6
                        color: "#edf6e8"
                        border.color: "#cddfc3"

                        Text {
                            anchors.centerIn: parent
                            text: root.demandAt(index)
                            font.pixelSize: 10
                            color: "#48633f"
                        }
                    }
                }

                Rectangle {
                    width: root.cellW
                    height: root.cellH
                    radius: 6
                    color: "transparent"
                    border.color: "transparent"
                }
            }
        }
    }
}

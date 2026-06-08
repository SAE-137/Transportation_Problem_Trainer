import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    anchors.fill: parent

    // Данные матрицы приходят из PracticeScreen
    property int rows: 0
    property int columns: 0
    property var costMatrix: []
    property var supply: []
    property var demand: []

    signal balancedYes()
    signal balancedNo()

    function toIntOrNaN(x) {
        if (x === undefined || x === null) return NaN
        if (typeof x === "number") return x
        const s = String(x).trim()
        if (s === "") return NaN
        const n = Number(s)
        return Number.isFinite(n) ? n : NaN
    }

    function checkBalanced() {
        let sumS = 0
        let sumD = 0

        if (rows <= 0 || columns <= 0)
            return { ok: false, error: "Неверная размерность матрицы" }

        if (!supply || supply.length !== rows)
            return { ok: false, error: "Запасы не заполнены или размер не совпадает" }

        if (!demand || demand.length !== columns)
            return { ok: false, error: "Потребности не заполнены или размер не совпадает" }

        for (let r = 0; r < rows; r++) {
            const v = toIntOrNaN(supply[r])
            if (!Number.isFinite(v))
                return { ok: false, error: "Запасы заполнены некорректно" }
            sumS += v
        }

        for (let c = 0; c < columns; c++) {
            const v = toIntOrNaN(demand[c])
            if (!Number.isFinite(v))
                return { ok: false, error: "Потребности заполнены некорректно" }
            sumD += v
        }

        return { ok: true, balanced: sumS === sumD, sumS: sumS, sumD: sumD }
    }

    function handleAnswer(userSaysBalanced) {
        const res = checkBalanced()
        if (!res.ok) {
            console.log("Ошибка данных:", res.error)
            return
        }

        if (userSaysBalanced && res.balanced) {
            root.balancedYes()
            return
        }

        if (!userSaysBalanced && !res.balanced) {
            root.balancedNo()
            return
        }

        if (userSaysBalanced && !res.balanced) {
            console.log("Ошибка: задача НЕ сбалансирована (Σзапасов=" + res.sumS + ", Σпотребностей=" + res.sumD + ")")
        } else if (!userSaysBalanced && res.balanced) {
            console.log("Ошибка: задача сбалансирована (Σзапасов=" + res.sumS + ", Σпотребностей=" + res.sumD + ")")
        }
    }

    ScrollView {
        id: pageScroll
        anchors.fill: parent
        clip: true

        contentWidth: pageContent.width
        contentHeight: pageContent.height

        ScrollBar.horizontal.policy: contentWidth > availableWidth
                                     ? ScrollBar.AsNeeded
                                     : ScrollBar.AlwaysOff

        ScrollBar.vertical.policy: contentHeight > availableHeight
                                   ? ScrollBar.AsNeeded
                                   : ScrollBar.AlwaysOff

        Item {
            id: pageContent
            width: Math.max(pageScroll.availableWidth, contentColumn.implicitWidth + 32)
            height: contentColumn.implicitHeight + 32

            ColumnLayout {
                id: contentColumn
                anchors.top: parent.top
                anchors.topMargin: 16
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 16

                MatrixView {
                    id: matrixPreview
                    Layout.alignment: Qt.AlignHCenter
                    readOnly: true
                    autoInit: false

                    rows: root.rows
                    columns: root.columns
                    costMatrix: root.costMatrix
                    supply: root.supply
                    demand: root.demand
                }

                Text {
                    text: "Сбалансирована ли транспортная задача?"
                    font.pixelSize: 20
                    color: "#111"
                    horizontalAlignment: Text.AlignHCenter
                    Layout.alignment: Qt.AlignHCenter
                }

                RowLayout {
                    spacing: 12
                    Layout.alignment: Qt.AlignHCenter

                    Button {
                        text: "Да"

                        background: Rectangle {
                            radius: 10
                            color: "#22c55e"
                        }

                        contentItem: Text {
                            text: "Да"
                            color: "white"
                            font.pixelSize: 16
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        onClicked: handleAnswer(true)
                    }

                    Button {
                        text: "Нет"

                        background: Rectangle {
                            radius: 10
                            color: "#ef4444"
                        }

                        contentItem: Text {
                            text: "Нет"
                            color: "white"
                            font.pixelSize: 16
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        onClicked: handleAnswer(false)
                    }
                }

                Text {
                    text: "Подсказка: сумма запасов должна равняться сумме потребностей."
                    color: "#444"
                    font.pixelSize: 14
                    horizontalAlignment: Text.AlignHCenter
                    Layout.alignment: Qt.AlignHCenter
                }
            }
        }
    }
}

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    anchors.fill: parent

    // входные данные
    property int rows: 0
    property int columns: 0
    property var costMatrix: []
    property var supply: []
    property var demand: []

    // балансировка
    property int balanceWho: -1
    property int balanceVolume: 0

    // локальные данные для отображения
    property int localRows: 0
    property int localCols: 0
    property var localCost: []
    property var localSupply: []
    property var localDemand: []
    property var localLoad: []   // x_ij в уголке

    // ===== логика минимального тарифа =====
    // 0 выбрать клетку, 1 ввести объём, 2 вычеркнуть, 3 посчитать стоимость
    property int phase: 0
    property int selR: -1
    property int selC: -1
    property string amountText: ""
    property string errorText: ""
    property string hintText: ""

    property var remSupply: []    // числа
    property var remDemand: []
    property var closedRows: []   // bool
    property var closedCols: []

    // ===== стоимость плана =====
    property string totalCostText: ""
    property int expectedTotalCost: 0
    property string costErrorText: ""

    // ✅ сигнал вверх (в PracticeScreen)
    signal stage3Completed(int finalRows, int finalCols, var finalCost, var finalSupply, var finalDemand, var finalLoad, int totalCost)

    function toInt(x) {
        const n = Number(String(x ?? "").trim())
        return Number.isFinite(n) ? n : 0
    }

    function rebuildLocal() {
        if (rows <= 0 || columns <= 0) {
            localRows = 0; localCols = 0
            localCost = []; localSupply = []; localDemand = []; localLoad = []
            remSupply = []; remDemand = []; closedRows = []; closedCols = []
            phase = 0; selR = -1; selC = -1
            amountText = ""
            totalCostText = ""
            expectedTotalCost = 0
            costErrorText = ""
            return
        }

        // 1) копируем входные
        localRows = rows
        localCols = columns

        let outCost = new Array(rows)
        for (let r = 0; r < rows; r++) {
            let srcRow = (costMatrix && costMatrix[r]) ? costMatrix[r] : []
            let row = new Array(columns)
            for (let c = 0; c < columns; c++) row[c] = srcRow[c]
            outCost[r] = row
        }

        let outSupply = new Array(rows)
        for (let r = 0; r < rows; r++) outSupply[r] = supply ? supply[r] : undefined

        let outDemand = new Array(columns)
        for (let c = 0; c < columns; c++) outDemand[c] = demand ? demand[c] : undefined

        // 2) добавляем фиктивного
        if (balanceWho === 0 && balanceVolume > 0) {
            localRows = rows + 1
            outCost.push(new Array(columns).fill("0"))
            outSupply.push(String(balanceVolume))
        } else if (balanceWho === 1 && balanceVolume > 0) {
            localCols = columns + 1
            for (let r = 0; r < rows; r++) outCost[r].push("0")
            outDemand.push(String(balanceVolume))
        }

        // 3) init перевозок
        let outLoad = new Array(localRows)
        for (let r = 0; r < localRows; r++) outLoad[r] = new Array(localCols).fill("")

        // 4) init остатков + закрытых
        let rs = new Array(localRows)
        let cs = new Array(localCols)
        let cr = new Array(localRows).fill(false)
        let cc = new Array(localCols).fill(false)

        for (let r = 0; r < localRows; r++) rs[r] = toInt(outSupply[r])
        for (let c = 0; c < localCols; c++) cs[c] = toInt(outDemand[c])

        localCost = outCost
        localLoad = outLoad

        remSupply = rs
        remDemand = cs
        closedRows = cr
        closedCols = cc

        // показываем остатки пользователю (как строки)
        localSupply = rs.map(v => String(v))
        localDemand = cs.map(v => String(v))

        // reset шага
        phase = 0
        selR = -1
        selC = -1
        amountText = ""
        errorText = ""
        hintText = "Шаг 1: выбери ячейку с минимальным тарифом среди доступных."

        // reset стоимости
        totalCostText = ""
        expectedTotalCost = 0
        costErrorText = ""
    }

    function rebuildIfVisible() { if (root.visible) rebuildLocal() }
    onVisibleChanged: { if (visible) rebuildLocal() }
    onRowsChanged: rebuildIfVisible()
    onColumnsChanged: rebuildIfVisible()
    onCostMatrixChanged: rebuildIfVisible()
    onSupplyChanged: rebuildIfVisible()
    onDemandChanged: rebuildIfVisible()
    onBalanceWhoChanged: rebuildIfVisible()
    onBalanceVolumeChanged: rebuildIfVisible()

    function cellIsAvailable(r, c) {
        if (r < 0 || c < 0 || r >= localRows || c >= localCols) return false
        if (closedRows[r] || closedCols[c]) return false
        if (remSupply[r] <= 0 || remDemand[c] <= 0) return false
        return true
    }

    function minAvailableCost() {
        let best = Infinity
        for (let r = 0; r < localRows; r++) {
            if (closedRows[r] || remSupply[r] <= 0) continue
            for (let c = 0; c < localCols; c++) {
                if (closedCols[c] || remDemand[c] <= 0) continue
                const v = Number(localCost[r][c])
                if (!Number.isFinite(v)) continue
                if (v < best) best = v
            }
        }
        return best
    }

    function expectedAmount(r, c) {
        return Math.min(remSupply[r], remDemand[c])
    }

    function handleCellClick(r, c) {
        errorText = ""
        if (phase !== 0) return

        if (!cellIsAvailable(r, c)) {
            errorText = "Ошибка (3.1): клетка недоступна."
            return
        }

        const best = minAvailableCost()
        const v = Number(localCost[r][c])
        if (!Number.isFinite(v) || v !== best) {
            errorText = "Ошибка (3.1): выбрана не минимальная стоимость. Минимум сейчас: " + best
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
        if (phase !== 1) return
        if (selR < 0 || selC < 0) return

        const user = Number(String(amountText).trim())
        if (!Number.isFinite(user) || user < 0) {
            errorText = "Ошибка (3.2): введи корректный объём."
            return
        }

        const exp = expectedAmount(selR, selC)
        if (user !== exp) {
            errorText = "Ошибка (3.2): неверный объём. Должно быть " + exp
            return
        }

        // записываем перевозку
        localLoad[selR][selC] = String(exp)
        localLoad = localLoad.map(row => row.slice())

        // обновляем остатки
        remSupply[selR] -= exp
        remDemand[selC] -= exp
        remSupply = remSupply.slice()
        remDemand = remDemand.slice()

        localSupply = remSupply.map(v => String(v))
        localDemand = remDemand.map(v => String(v))

        phase = 2
        hintText = "Шаг 3: выбери, кого вычеркнуть."
    }

    function isFinalStep() {
        for (let r = 0; r < localRows; r++) if (remSupply[r] > 0) return false
        for (let c = 0; c < localCols; c++) if (remDemand[c] > 0) return false
        return true
    }

    function crossOut(mode) {
        // mode: "row" | "col" | "both"
        errorText = ""
        if (phase !== 2) return

        const rowZero = remSupply[selR] === 0
        const colZero = remDemand[selC] === 0

        if (mode === "row") {
            if (!rowZero) { errorText = "Ошибка (3.3): строку нельзя вычеркнуть (запас не 0)."; return }
            closedRows[selR] = true
        } else if (mode === "col") {
            if (!colZero) { errorText = "Ошибка (3.3): столбец нельзя вычеркнуть (потребность не 0)."; return }
            closedCols[selC] = true
        } else { // both
            if (!(rowZero && colZero)) { errorText = "Ошибка (3.3): оба можно вычеркнуть только если оба равны 0."; return }
            if (!isFinalStep()) { errorText = "Ошибка (3.3): 'оба' разрешено только на последнем шаге."; return }
            closedRows[selR] = true
            closedCols[selC] = true
        }

        closedRows = closedRows.slice()
        closedCols = closedCols.slice()

        // если план уже полностью построен -> переходим к подсчёту стоимости
        if (isFinalStep()) {
            phase = 3
            selR = -1
            selC = -1
            amountText = ""
            hintText = "План построен. Посчитай суммарную стоимость перевозок и введи ответ справа."
            expectedTotalCost = calcTotalCost()
            totalCostText = ""
            costErrorText = ""
            return
        }

        // иначе следующий шаг
        phase = 0
        selR = -1
        selC = -1
        amountText = ""
        hintText = "Шаг 1: выбери следующую ячейку с минимальным тарифом."
    }

    function calcTotalCost() {
        let sum = 0
        for (let r = 0; r < localRows; r++) {
            for (let c = 0; c < localCols; c++) {
                const x = Number(String(localLoad[r][c] ?? "").trim())
                if (!Number.isFinite(x) || x <= 0) continue
                const cost = Number(String(localCost[r][c] ?? "").trim())
                if (!Number.isFinite(cost)) return NaN
                sum += x * cost
            }
        }
        return Math.trunc(sum)
    }

    function checkTotalCost() {
        costErrorText = ""
        if (phase !== 3) return

        const user = Number(String(totalCostText).trim())
        if (!Number.isFinite(user) || user < 0) {
            costErrorText = "Введите корректное число."
            return
        }
        if (user !== expectedTotalCost) {
            costErrorText = "Неверно. Попробуй ещё раз."
            return
        }

        // ✅ правильный ответ -> отдаём план вверх и переходим на этап 4
        root.stage3Completed(
            localRows, localCols,
            localCost,
            // исходные (не остатки): восстановим из начальных supply/demand при rebuildLocal
            // здесь проще передать сумму: для этапа 4 достаточно матрицы затрат + плана,
            // но передадим текущие "нулевые" localSupply/localDemand тоже, чтобы размерности совпали
            // (этап 4 ты всё равно сделаешь readOnly и будешь работать с plan)
            localSupply, localDemand,
            localLoad,
            expectedTotalCost
        )
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
                interactive: (phase === 0)   // клики только на выборе клетки
                showLoads: true
                autoInit: false

                rows: root.localRows
                columns: root.localCols
                costMatrix: root.localCost
                loadMatrix: root.localLoad
                supply: root.localSupply
                demand: root.localDemand

                onCellClicked: (r, c) => root.handleCellClick(r, c)
            }

            Text {
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                color: "#444"
                text: hintText
            }
        }

        // ПАНЕЛЬ СПРАВА
        Rectangle {
            Layout.preferredWidth: 320
            Layout.fillHeight: true
            radius: 12
            color: "#ffffff"
            border.color: "#e5e5e5"

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 10

                Text { text: "Панель шага"; font.pixelSize: 16; color: "#111" }

                Text {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    color: "#444"
                    text: {
                        if (phase === 0) return "1) Выбери клетку с минимальным тарифом."
                        if (phase === 1) return "2) Введи объём перевозки."
                        if (phase === 2) return "3) Вычеркни поставщика/потребителя."
                        return "4) Посчитай суммарную стоимость перевозок."
                    }
                }

                Rectangle { Layout.fillWidth: true; height: 1; color: "#eeeeee" }

                Text {
                    Layout.fillWidth: true
                    color: "#111"
                    text: (selR >= 0)
                          ? ("Выбрано: (" + (selR+1) + "," + (selC+1) + "), тариф=" + localCost[selR][selC])
                          : "Выбрано: —"
                    visible: phase !== 3
                }

                TextField {
                    Layout.fillWidth: true
                    placeholderText: "Объём (x_ij)"
                    inputMethodHints: Qt.ImhDigitsOnly
                    enabled: phase === 1
                    text: root.amountText
                    onTextChanged: root.amountText = text
                    visible: phase !== 3
                }

                Button {
                    Layout.fillWidth: true
                    text: "Подтвердить объём"
                    enabled: phase === 1
                    onClicked: root.confirmAmount()
                    visible: phase !== 3
                }

                Rectangle { Layout.fillWidth: true; height: 1; color: "#eeeeee"; visible: phase !== 3 }

                Text { text: "Вычеркнуть:"; color: "#111"; visible: phase === 2 }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    visible: phase === 2

                    Button { Layout.fillWidth: true; text: "Поставщика"; enabled: phase === 2; onClicked: root.crossOut("row") }
                    Button { Layout.fillWidth: true; text: "Потребителя"; enabled: phase === 2; onClicked: root.crossOut("col") }
                }

                Button {
                    Layout.fillWidth: true
                    text: "Оба"
                    enabled: phase === 2
                    onClicked: root.crossOut("both")
                    visible: phase === 2
                }

                Text {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    color: "#b91c1c"
                    text: errorText
                    visible: errorText.length > 0 && phase !== 3
                }

                // ===== блок стоимости плана =====
                Rectangle { Layout.fillWidth: true; height: 1; color: "#eeeeee"; visible: phase === 3 }

                Text {
                    text: "Суммарная стоимость"
                    font.pixelSize: 14
                    color: "#111"
                    visible: phase === 3
                }

                TextField {
                    Layout.fillWidth: true
                    placeholderText: "Введите стоимость"
                    inputMethodHints: Qt.ImhDigitsOnly
                    enabled: phase === 3
                    text: root.totalCostText
                    onTextChanged: root.totalCostText = text
                    visible: phase === 3
                }

                Button {
                    Layout.fillWidth: true
                    text: "Проверить и перейти к этапу 4"
                    enabled: phase === 3
                    onClicked: root.checkTotalCost()
                    visible: phase === 3
                }

                Text {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    color: "#b91c1c"
                    text: costErrorText
                    visible: phase === 3 && costErrorText.length > 0
                }

                Item { Layout.fillHeight: true }
            }
        }
    }
}

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    anchors.fill: parent

    // Приходят из PracticeScreen (как данные текущего WORK-этапа)
    property int rows: 0
    property int columns: 0
    property var costMatrix: []
    property var supply: []
    property var demand: []

    // ВАЖНО: вместо мутации локальных props, отдаём наружу новый результат
    // newRows/newCols + новые массивы
    // who: 0 = добавить поставщика (строка), 1 = добавить потребителя (столбец)
    signal balanceFixPassed(int who, int volume)
    // UI state
    property int selectedWho: -1      // 0 = поставщик, 1 = потребитель
    property string volumeText: ""
    property string errorText: ""

    function toIntOrNaN(x) {
        if (x === undefined || x === null) return NaN
        const s = String(x).trim()
        if (s === "") return NaN
        const n = Number(s)
        return Number.isFinite(n) ? n : NaN
    }

    function sumVector(vec, expectedLen) {
        if (!vec || vec.length !== expectedLen) return NaN
        let sum = 0
        for (let i = 0; i < expectedLen; i++) {
            const v = toIntOrNaN(vec[i])
            if (!Number.isFinite(v)) return NaN
            sum += v
        }
        return sum
    }

    function expectedAnswer() {
        const sumS = sumVector(supply, rows)
        const sumD = sumVector(demand, columns)

        if (!Number.isFinite(sumS) || !Number.isFinite(sumD)) {
            return { ok: false, error: "Запасы/потребности заполнены некорректно" }
        }
        if (sumS === sumD) {
            return { ok: false, error: "Задача уже сбалансирована — балансировка не требуется" }
        }
        if (sumS < sumD) {
            return { ok: true, who: 0, volume: (sumD - sumS), sumS: sumS, sumD: sumD }
        } else {
            return { ok: true, who: 1, volume: (sumS - sumD), sumS: sumS, sumD: sumD }
        }
    }

    function zeroStr(x) {
        // пустое/undefined -> "0"
        if (x === undefined || x === null) return "0"
        const s = String(x).trim()
        return (s === "") ? "0" : s
    }

    function normalizeCost(cost, rCount, cCount) {
        // делаем "прямоугольник" rCount x cCount, заполняем дырки нулями
        let out = []
        for (let r = 0; r < rCount; r++) {
            let row = (cost && cost[r]) ? cost[r].slice() : []
            while (row.length < cCount) row.push("0")
            if (row.length > cCount) row = row.slice(0, cCount)
            for (let c = 0; c < cCount; c++) row[c] = zeroStr(row[c])
            out.push(row)
        }
        return out
    }

    function buildBalancedResult(who, volume) {
        // 1) сначала нормализуем текущую матрицу до rows x columns
        let baseRows = rows
        let baseCols = columns
        let newCost = normalizeCost(costMatrix, baseRows, baseCols)
        let newSupply = (supply || []).slice()
        let newDemand = (demand || []).slice()

        // нормализуем supply/demand (дырки -> "0")
        while (newSupply.length < baseRows) newSupply.push("0")
        while (newDemand.length < baseCols) newDemand.push("0")
        for (let r = 0; r < baseRows; r++) newSupply[r] = zeroStr(newSupply[r])
        for (let c = 0; c < baseCols; c++) newDemand[c] = zeroStr(newDemand[c])

        let newRows = baseRows
        let newCols = baseCols

        if (who === 0) {
            // добавить фиктивного поставщика (строка)
            newRows += 1
            const newRow = Array(baseCols).fill("0")   // тарифы = 0
            newCost.push(newRow)
            newSupply.push(String(volume))             // запас = разность
            // demand без изменений
        } else {
            // добавить фиктивного потребителя (столбец)
            newCols += 1
            for (let r = 0; r < baseRows; r++) {
                newCost[r].push("0")                   // тарифы = 0
            }
            newDemand.push(String(volume))             // потребность = разность
            // supply без изменений
        }

        // 2) финальная нормализация под новый размер (на всякий случай)
        newCost = normalizeCost(newCost, newRows, newCols)
        while (newSupply.length < newRows) newSupply.push("0")
        while (newDemand.length < newCols) newDemand.push("0")

        return { newRows, newCols, newCost, newSupply, newDemand }
    }





    function checkAndBalance() {
        errorText = ""

        const exp = expectedAnswer()
        if (!exp.ok) {
            errorText = exp.error
            console.log("Ошибка:", exp.error)
            return
        }

        if (selectedWho !== 0 && selectedWho !== 1) {
            errorText = "Выберите, кого добавить: поставщика или потребителя."
            return
        }

        const userVol = toIntOrNaN(volumeText)
        if (!Number.isFinite(userVol) || userVol < 0) {
            errorText = "Введите корректный объём (целое число ≥ 0)."
            return
        }

        // Проверка (2.1) — кого добавить
        if (selectedWho !== exp.who) {
            errorText = "Ошибка (2.1): выбран неверный тип (нужно добавить " +
                        (exp.who === 0 ? "поставщика" : "потребителя") + ")."
            console.log(errorText, "Σзапасов=", exp.sumS, "Σпотребностей=", exp.sumD)
            return
        }

        // Проверка (2.2) — объём
        if (userVol !== exp.volume) {
            errorText = "Ошибка (2.2): неверный объём (должно быть " + exp.volume + ")."
            console.log(errorText, "Σзапасов=", exp.sumS, "Σпотребностей=", exp.sumD)
            return
        }

        // ✅ Всё верно -> строим результат и отдаём наружу
        root.balanceFixPassed(exp.who, exp.volume)

        console.log("Балансировка выполнена: добавлен " +
                    (exp.who === 0 ? "фиктивный поставщик" : "фиктивный потребитель") +
                    " с объёмом " + exp.volume + ". Тарифы = 0.")

        root.balancedMatrixReady(res.newRows, res.newCols, res.newCost, res.newSupply, res.newDemand)
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 14

        // Матрица сверху (только просмотр)
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
            text: "Этап 2: Балансировка"
            font.pixelSize: 20
            color: "#111"
            Layout.alignment: Qt.AlignHCenter
        }

        Text {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            color: "#444"
            font.pixelSize: 14
            text: "Вопрос: кого нужно добавить для балансировки (поставщика или потребителя) и с каким запасом/потребностью?"
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 16

            RadioButton {
                text: "Добавить поставщика"
                checked: root.selectedWho === 0
                onClicked: root.selectedWho = 0
            }
            RadioButton {
                text: "Добавить потребителя"
                checked: root.selectedWho === 1
                onClicked: root.selectedWho = 1
            }
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 10

            Text { text: "Объём:"; color: "#111" }

            TextField {
                width: 160
                placeholderText: "например, 25"
                text: root.volumeText
                inputMethodHints: Qt.ImhDigitsOnly
                onTextChanged: root.volumeText = text
            }
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            color: "#b91c1c"
            font.pixelSize: 14
            text: root.errorText
            visible: root.errorText.length > 0
        }

        Button {
            Layout.alignment: Qt.AlignHCenter
            text: "Проверить ответ и сбалансировать"
            onClicked: checkAndBalance()
        }

        Item { Layout.fillHeight: true }
    }
}

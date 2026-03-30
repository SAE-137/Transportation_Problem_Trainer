import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    anchors.fill: parent

    property int rows: 0
    property int columns: 0
    property var costMatrix: []
    property var loadMatrix: []   // входной план
    property var supply: []
    property var demand: []

    // ===== локальная копия плана (мы её пересчитываем) =====
    property var curLoad: []       // 2D strings
    property var markMatrix: []    // 2D strings для + / - / r

    // ===== фазы этапа 4 =====
    // 0=4.1, 1=4.2, 2=4.3, 3=4.4 (цикл), 4=4.5 (r), 5=4.6 (удаляемая), 6=оптимально
    property int phase: 0

    // potentials (null = неизвестен)
    property var u: []
    property var v: []

    // UI 4.1/4.2
    property int pickType: 0   // 0=u, 1=v
    property int pickIndex: 0
    property string valueText: ""
    property string errorText: ""
    property string hintText: ""

    // ===== 4.3 =====
    // 0 выбрать клетку для Δ, 1 ввести Δ, 2 выбрать входящую клетку
    property int deltaMode: 0
    property int dR: -1
    property int dC: -1
    property string deltaText: ""
    property string deltaError: ""
    property int enterR: -1
    property int enterC: -1

    // ===== 4.4 =====
    property var cycleCells: []     // [{r,c}, ... , {r,c}=start]
    property int cyclePos: 1        // ожидаемый индекс в cycleCells
    property string cycleError: ""

    // ===== 4.5 =====
    property int expectedR: 0
    property string rText: ""
    property string rError: ""

    // ===== 4.6 =====
    property var leavingCells: []   // список допустимых (минус-клетки с минимумом)
    property string leaveError: ""

    function toNum(x) {
        const n = Number(String(x ?? "").trim())
        return Number.isFinite(n) ? n : NaN
    }

    function toIntSafe(x) {
        const n = Number(String(x ?? "").trim())
        return Number.isFinite(n) ? Math.trunc(n) : 0
    }

    function copy2D(a, rCount, cCount) {
        let out = new Array(rCount)
        for (let r = 0; r < rCount; r++) {
            let src = (a && a[r]) ? a[r] : []
            let row = new Array(cCount)
            for (let c = 0; c < cCount; c++) row[c] = src[c]
            out[r] = row
        }
        return out
    }

    function initMarks() {
        let m = new Array(rows)
        for (let r = 0; r < rows; r++) m[r] = new Array(columns).fill("")
        markMatrix = m
    }

    function isBasicCell(r, c) {
        if (!curLoad || !curLoad[r]) return false
        const x = toNum(curLoad[r][c])
        return Number.isFinite(x) && x > 0
    }

    function isNonBasicCell(r, c) {
        return !isBasicCell(r, c)
    }

    function initAll() {
        // копируем план
        curLoad = copy2D(loadMatrix, rows, columns)

        // potentials
        u = new Array(rows).fill(null)
        v = new Array(columns).fill(null)

        pickType = 0
        pickIndex = 0
        valueText = ""
        errorText = ""

        // 4.3
        deltaMode = 0
        dR = -1
        dC = -1
        deltaText = ""
        deltaError = ""
        enterR = -1
        enterC = -1

        // 4.4-4.6
        cycleCells = []
        cyclePos = 1
        cycleError = ""
        expectedR = 0
        rText = ""
        rError = ""
        leavingCells = []
        leaveError = ""

        initMarks()

        phase = 0
        hintText = "4.1: Задай любой один потенциал u_i или v_j (значение может быть любым)."
    }

    onVisibleChanged: { if (visible) initAll() }
    onRowsChanged: { if (visible) initAll() }
    onColumnsChanged: { if (visible) initAll() }

    function impliedU(i) {
        if (u[i] !== null) return null
        for (let j = 0; j < columns; j++) {
            if (!isBasicCell(i, j)) continue
            if (v[j] === null) continue
            const c = toNum(costMatrix[i][j])
            if (!Number.isFinite(c)) continue
            return c - v[j]
        }
        return null
    }

    function impliedV(j) {
        if (v[j] !== null) return null
        for (let i = 0; i < rows; i++) {
            if (!isBasicCell(i, j)) continue
            if (u[i] === null) continue
            const c = toNum(costMatrix[i][j])
            if (!Number.isFinite(c)) continue
            return c - u[i]
        }
        return null
    }

    function allPotentialsKnown() {
        for (let i = 0; i < rows; i++) if (u[i] === null) return false
        for (let j = 0; j < columns; j++) if (v[j] === null) return false
        return true
    }

    function submitPotential() {
        errorText = ""
        const val = toNum(valueText)
        if (!Number.isFinite(val)) { errorText = "Введите корректное число."; return }

        if (phase === 0) {
            if (pickType === 0) u[pickIndex] = val
            else v[pickIndex] = val
            u = u.slice(); v = v.slice()
            phase = 1
            valueText = ""
            hintText = "4.2: Вводи остальные потенциалы. Проверка по u_i + v_j = c_ij на базисных клетках."
            return
        }

        if (phase === 1) {
            if (pickType === 0) {
                if (u[pickIndex] !== null) { errorText = "Этот u уже задан."; return }
                const exp = impliedU(pickIndex)
                if (exp === null) { errorText = "Пока нельзя вычислить этот u (нужен базис с известным v)."; return }
                if (val !== exp) { errorText = "Ошибка (4.2): неверный потенциал. Должно быть " + exp + "."; return }
                u[pickIndex] = val
                u = u.slice()
            } else {
                if (v[pickIndex] !== null) { errorText = "Этот v уже задан."; return }
                const exp = impliedV(pickIndex)
                if (exp === null) { errorText = "Пока нельзя вычислить этот v (нужен базис с известным u)."; return }
                if (val !== exp) { errorText = "Ошибка (4.2): неверный потенциал. Должно быть " + exp + "."; return }
                v[pickIndex] = val
                v = v.slice()
            }

            valueText = ""
            if (allPotentialsKnown()) {
                phase = 2
                deltaMode = 0
                hintText = "4.3: Выбери небазисную клетку и введи Δ_ij = c_ij - (u_i + v_j). Затем выбери входящую клетку или укажи, что задача решена."
            }
        }
    }

    function deltaExpected(r, c) {
        const cst = toNum(costMatrix[r][c])
        if (!Number.isFinite(cst)) return NaN
        return cst - (u[r] + v[c])
    }

    function bestEnteringCell() {
        let best = Infinity
        let br = -1, bc = -1
        for (let r = 0; r < rows; r++) {
            for (let c = 0; c < columns; c++) {
                if (!isNonBasicCell(r, c)) continue
                const d = deltaExpected(r, c)
                if (!Number.isFinite(d)) continue
                if (d < best || (d === best && (r < br || (r === br && c < bc)))) {
                    best = d; br = r; bc = c
                }
            }
        }
        return { br, bc, best }
    }

    function submitDelta() {
        deltaError = ""
        if (phase !== 2 || deltaMode !== 1) return
        const user = toNum(deltaText)
        if (!Number.isFinite(user)) { deltaError = "Введите корректное Δ."; return }
        const exp = deltaExpected(dR, dC)
        if (!Number.isFinite(exp)) { deltaError = "Невозможно вычислить Δ для этой клетки."; return }
        if (user !== exp) { deltaError = "Ошибка (4.3.2): неверно. Должно быть " + exp + "."; return }

        deltaMode = 0
        dR = -1; dC = -1
        deltaText = ""
    }

    function startChooseEntering() {
        deltaError = ""
        if (phase !== 2) return
        const best = bestEnteringCell()
        if (best.br < 0) { deltaError = "Не удалось определить входящую клетку."; return }
        if (best.best >= 0) { deltaError = "Ошибка (4.3.3): улучшения нет (все Δ ≥ 0). Нужно нажать «Задача решена»."; return }
        deltaMode = 2
    }

    function declareSolved() {
        deltaError = ""
        if (phase !== 2) return
        const best = bestEnteringCell()
        if (best.br < 0) { deltaError = "Не удалось проверить оптимальность."; return }
        if (best.best < 0) { deltaError = "Ошибка (4.3.5): задача не решена — есть отрицательные Δ."; return }
        phase = 6
        hintText = "План оптимален."
    }

    // ===== поиск цикла =====
    function buildCycle(startR, startC) {
        // nodes = базисные клетки + старт
        let nodes = []
        for (let r = 0; r < rows; r++) {
            for (let c = 0; c < columns; c++) {
                if (isBasicCell(r, c)) nodes.push({r, c})
            }
        }
        nodes.push({r: startR, c: startC})

        // индексы по строкам/столбцам
        let byRow = new Array(rows)
        let byCol = new Array(columns)
        for (let i = 0; i < rows; i++) byRow[i] = []
        for (let j = 0; j < columns; j++) byCol[j] = []

        for (let k = 0; k < nodes.length; k++) {
            const n = nodes[k]
            byRow[n.r].push(n)
            byCol[n.c].push(n)
        }

        function key(n) { return n.r + "," + n.c }

        function neighbors(n, dir) {
            // dir 0: по строке (меняем столбец), dir 1: по столбцу (меняем строку)
            let list = (dir === 0) ? byRow[n.r] : byCol[n.c]
            let out = []
            for (let i = 0; i < list.length; i++) {
                const m = list[i]
                if (m.r === n.r && m.c === n.c) continue
                out.push(m)
            }
            // детерминированный порядок
            out.sort((a,b) => dir === 0 ? (a.c - b.c) : (a.r - b.r))
            return out
        }

        function dfs(cur, start, dir, path, used) {
            const neigh = neighbors(cur, dir)
            for (let i = 0; i < neigh.length; i++) {
                const nxt = neigh[i]
                const k = key(nxt)

                if (nxt.r === start.r && nxt.c === start.c) {
                    if (path.length >= 4) {
                        path.push(start)
                        return true
                    }
                    continue
                }
                if (used[k]) continue

                used[k] = true
                path.push(nxt)
                if (dfs(nxt, start, 1 - dir, path, used)) return true
                path.pop()
                delete used[k]
            }
            return false
        }

        const start = {r:startR, c:startC}

        // пробуем начать ход по строке, потом по столбцу
        for (let startDir = 0; startDir <= 1; startDir++) {
            let path = [start]
            let used = {}
            used[key(start)] = true
            if (dfs(start, start, startDir, path, used)) return path
        }
        return []
    }

    function setMark(r, c, s) {
        if (!markMatrix || !markMatrix[r]) return
        markMatrix[r][c] = s
        markMatrix = markMatrix.map(row => row.slice())
    }

    function clearMarks() {
        initMarks()
    }

    function prepareCycle() {
        clearMarks()
        setMark(enterR, enterC, "r")

        const cyc = buildCycle(enterR, enterC)
        if (!cyc || cyc.length < 4) {
            cycleError = "Не удалось построить цикл пересчёта (проверь базис)."
            return false
        }

        cycleCells = cyc
        cyclePos = 1
        cycleError = ""
        hintText = "4.4: Построй цикл. Кликайте клетки цикла по порядку (начальная отмечена r)."
        return true
    }

    function applyPlusMinusMarks() {
        clearMarks()
        // cycleCells содержит старт в конце
        for (let k = 0; k < cycleCells.length - 1; k++) {
            const cell = cycleCells[k]
            const sign = (k % 2 === 0) ? "+" : "-"
            markMatrix[cell.r][cell.c] = sign
        }
        markMatrix = markMatrix.map(row => row.slice())
    }

    function computeExpectedR() {
        let best = Infinity
        for (let k = 1; k < cycleCells.length - 1; k += 2) {
            const cell = cycleCells[k] // минус-клетки
            const x = toIntSafe(curLoad[cell.r][cell.c])
            if (x < best) best = x
        }
        if (best === Infinity) best = 0
        expectedR = best
    }

    function computeLeavingCells() {
        let out = []
        for (let k = 1; k < cycleCells.length - 1; k += 2) {
            const cell = cycleCells[k]
            const x = toIntSafe(curLoad[cell.r][cell.c])
            if (x === expectedR) out.push(cell)
        }
        leavingCells = out
    }

    function applyRecalc(rValue, leaving) {
        // применяем +r / -r
        let newLoad = copy2D(curLoad, rows, columns)

        for (let k = 0; k < cycleCells.length - 1; k++) {
            const cell = cycleCells[k]
            const x0 = toIntSafe(newLoad[cell.r][cell.c])
            const x1 = (k % 2 === 0) ? (x0 + rValue) : (x0 - rValue)
            newLoad[cell.r][cell.c] = (x1 === 0) ? "" : String(x1)
        }

        // явно убираем выбранную клетку из базиса
        newLoad[leaving.r][leaving.c] = ""

        curLoad = newLoad
    }

    // ===== обработка кликов по матрице (в зависимости от фазы) =====
    function handleMatrixClick(r, c) {
        // 4.3
        if (phase === 2) {
            deltaError = ""

            if (deltaMode === 0) {
                if (!isNonBasicCell(r, c)) {
                    deltaError = "Ошибка (4.3.1): Δ считаем в небазисной клетке (x_ij = 0)."
                    return
                }
                dR = r; dC = c
                deltaText = ""
                deltaMode = 1
                return
            }

            if (deltaMode === 2) {
                if (!isNonBasicCell(r, c)) {
                    deltaError = "Ошибка (4.3.4): входящая клетка должна быть небазисной."
                    return
                }
                const best = bestEnteringCell()
                if (best.best >= 0) {
                    deltaError = "Ошибка (4.3.3): улучшения нет (все Δ ≥ 0). Нажми «Задача решена»."
                    return
                }
                if (r !== best.br || c !== best.bc) {
                    deltaError = "Ошибка (4.3.4): неверная входящая клетка (нужна самая отрицательная Δ)."
                    return
                }

                enterR = r; enterC = c
                // стартуем 4.4
                phase = 3
                if (!prepareCycle()) return
                return
            }
        }

        // 4.4: строим цикл по заранее найденному эталону
        if (phase === 3) {
            cycleError = ""
            const exp = cycleCells[cyclePos]
            if (!exp) { cycleError = "Внутренняя ошибка цикла."; return }
            if (r !== exp.r || c !== exp.c) {
                cycleError = "Ошибка (4.4): неверная следующая клетка цикла."
                return
            }

            setMark(r, c, "•") // просто отметим посещение точкой
            cyclePos++

            // закончили? последний элемент — старт
            if (cyclePos >= cycleCells.length) {
                // цикл построен
                applyPlusMinusMarks()
                computeExpectedR()
                rText = ""
                rError = ""
                phase = 4
                hintText = "4.5: Введи r = min(x_ij) по клеткам со знаком '-'."
            }
            return
        }

        // 4.6: выбор удаляемой клетки (клик по клетке)
        if (phase === 5) {
            leaveError = ""
            // проверить, что клик в допустимом множестве
            let ok = false
            for (let i = 0; i < leavingCells.length; i++) {
                if (leavingCells[i].r === r && leavingCells[i].c === c) { ok = true; break }
            }
            if (!ok) {
                leaveError = "Ошибка (4.6): нужно выбрать '-' клетку с минимальным x (которая становится 0)."
                return
            }

            // применяем пересчёт
            const rv = expectedR
            applyRecalc(rv, {r, c})

            // сбрасываем метки и начинаем новую итерацию потенциалов
            clearMarks()

            // сброс потенциалов/дельт и возврат к 4.1
            u = new Array(rows).fill(null)
            v = new Array(columns).fill(null)
            pickType = 0
            pickIndex = 0
            valueText = ""
            errorText = ""
            deltaMode = 0
            deltaText = ""
            deltaError = ""
            enterR = -1; enterC = -1

            cycleCells = []
            cyclePos = 1
            leavingCells = []
            leaveError = ""
            expectedR = 0
            rText = ""
            rError = ""

            phase = 0
            hintText = "Пересчёт выполнен. 4.1: Задай один потенциал для новой итерации."
            return
        }
    }

    function checkR() {
        rError = ""
        if (phase !== 4) return
        const user = toNum(rText)
        if (!Number.isFinite(user) || user < 0) { rError = "Введите корректное r."; return }
        if (user !== expectedR) { rError = "Ошибка (4.5): неверное r. Должно быть " + expectedR + "."; return }

        // переходим к 4.6
        computeLeavingCells()
        phase = 5
        leaveError = ""
        hintText = "4.6: Кликни по удаляемой клетке (из '-' с минимальным значением)."
    }

    RowLayout {
        anchors.fill: parent
        spacing: 16

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 10

            Text {
                text: "Этап 4: Метод потенциалов"
                font.pixelSize: 20
                color: "#111"
                Layout.alignment: Qt.AlignHCenter
            }

            MatrixView {
                Layout.alignment: Qt.AlignHCenter
                readOnly: true
                showLoads: true
                showMarks: (phase >= 3 && phase <= 5)
                markMatrix: root.markMatrix

                // клики нужны в 4.3 (выбор Δ/входящей), 4.4 (цикл), 4.6 (удаляемая)
                interactive: (phase === 2 && (deltaMode === 0 || deltaMode === 2))
                             || (phase === 3)
                             || (phase === 5)

                autoInit: false
                rows: root.rows
                columns: root.columns
                costMatrix: root.costMatrix
                loadMatrix: root.curLoad
                supply: root.supply
                demand: root.demand

                onCellClicked: (r, c) => root.handleMatrixClick(r, c)
            }

            Text {
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                color: "#444"
                text: hintText
            }

            Item { Layout.fillHeight: true }
        }

        Rectangle {
            Layout.preferredWidth: 360
            Layout.fillHeight: true
            radius: 12
            color: "#ffffff"
            border.color: "#e5e5e5"

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 10

                Text { text: "Панель шага"; font.pixelSize: 16; color: "#111" }

                // 4.1/4.2
                Item { visible: phase <= 1; height: 0; Layout.fillWidth: true }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    visible: phase <= 1

                    ComboBox {
                        Layout.fillWidth: true
                        model: ["u (поставщик)", "v (потребитель)"]
                        currentIndex: root.pickType
                        onCurrentIndexChanged: root.pickType = currentIndex
                    }

                    SpinBox {
                        from: 1
                        to: (root.pickType === 0 ? root.rows : root.columns)
                        value: root.pickIndex + 1
                        onValueChanged: root.pickIndex = value - 1
                        editable: true
                    }
                }

                TextField {
                    Layout.fillWidth: true
                    visible: phase <= 1
                    placeholderText: (phase === 0 ? "Задать (4.1)" : "Ввести (4.2)")
                    validator: IntValidator { bottom: -1000000; top: 1000000 }
                    text: root.valueText
                    onTextChanged: root.valueText = text
                }

                Button {
                    Layout.fillWidth: true
                    visible: phase <= 1
                    text: (phase === 0) ? "Задать потенциал (4.1)" : "Проверить потенциал (4.2)"
                    onClicked: submitPotential()
                }

                Text {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    color: "#b91c1c"
                    text: errorText
                    visible: phase <= 1 && errorText.length > 0
                }

                // 4.3
                Rectangle { Layout.fillWidth: true; height: 1; color: "#eeeeee"; visible: phase >= 2 && phase <= 3 }

                // Таблица текущих потенциалов
                Text { text: "Текущие потенциалы"; color: "#111"; font.pixelSize: 14 }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 16

                    ColumnLayout {
                        Layout.fillWidth: true
                        Text { text: "u"; color: "#111" }
                        Repeater {
                            model: root.rows
                            delegate: Text {
                                color: "#444"
                                text: "u" + (index+1) + " = " + (root.u && root.u[index] !== null ? root.u[index] : "—")
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Text { text: "v"; color: "#111" }
                        Repeater {
                            model: root.columns
                            delegate: Text {
                                color: "#444"
                                text: "v" + (index+1) + " = " + (root.v && root.v[index] !== null ? root.v[index] : "—")
                            }
                        }
                    }
                }


                Text { visible: phase === 2; text: "4.3: Δ и входящая клетка"; color: "#111" }

                Text {
                    visible: phase === 2
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    color: "#444"
                    text: {
                        if (deltaMode === 0) return "Кликни небазисную клетку для Δ."
                        if (deltaMode === 1) return "Введи Δ для выбранной клетки."
                        return "Кликни входящую клетку (самая отрицательная Δ)."
                    }
                }

                TextField {
                    Layout.fillWidth: true
                    visible: phase === 2 && deltaMode === 1
                    placeholderText: "Δ_ij"
                    validator: IntValidator { bottom: -1000000; top: 1000000 }
                    text: root.deltaText
                    onTextChanged: root.deltaText = text
                }

                Button {
                    Layout.fillWidth: true
                    visible: phase === 2 && deltaMode === 1
                    text: "Проверить Δ"
                    onClicked: submitDelta()
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    visible: phase === 2 && (deltaMode === 0 || deltaMode === 1)

                    Button { Layout.fillWidth: true; text: "Выбрать входящую"; onClicked: startChooseEntering() }
                    Button { Layout.fillWidth: true; text: "Задача решена"; onClicked: declareSolved() }
                }

                Text {
                    visible: phase === 2
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    color: "#b91c1c"
                    text: deltaError
                }

                // 4.4
                Rectangle { Layout.fillWidth: true; height: 1; color: "#eeeeee"; visible: phase === 3 }
                Text { visible: phase === 3; text: "4.4: Построение цикла"; color: "#111" }
                Text {
                    visible: phase === 3
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    color: "#444"
                    text: cycleCells.length > 0
                          ? ("Кликни следующую клетку цикла. Осталось шагов: " + (cycleCells.length - cyclePos))
                          : "Цикл не найден."
                }
                Text {
                    visible: phase === 3 && cycleError.length > 0
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    color: "#b91c1c"
                    text: cycleError
                }

                // 4.5
                Rectangle { Layout.fillWidth: true; height: 1; color: "#eeeeee"; visible: phase === 4 }
                Text { visible: phase === 4; text: "4.5: Ввод r"; color: "#111" }
                TextField {
                    Layout.fillWidth: true
                    visible: phase === 4
                    placeholderText: "r"
                    inputMethodHints: Qt.ImhDigitsOnly
                    text: root.rText
                    onTextChanged: root.rText = text
                }
                Button {
                    Layout.fillWidth: true
                    visible: phase === 4
                    text: "Проверить r"
                    onClicked: checkR()
                }
                Text {
                    visible: phase === 4 && rError.length > 0
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    color: "#b91c1c"
                    text: rError
                }

                // 4.6
                Rectangle { Layout.fillWidth: true; height: 1; color: "#eeeeee"; visible: phase === 5 }
                Text { visible: phase === 5; text: "4.6: Удаляемая клетка"; color: "#111" }
                Text {
                    visible: phase === 5
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    color: "#444"
                    text: "Кликни по клетке из '-' с минимальным x (та, что станет 0)."
                }
                Text {
                    visible: phase === 5 && leaveError.length > 0
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    color: "#b91c1c"
                    text: leaveError
                }

                // оптимально
                Rectangle { Layout.fillWidth: true; height: 1; color: "#eeeeee"; visible: phase === 6 }
                Text {
                    visible: phase === 6
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    color: "#111"
                    text: "План оптимален. Дальше можно завершать."
                }

                Item { Layout.fillHeight: true }
            }
        }
    }
}

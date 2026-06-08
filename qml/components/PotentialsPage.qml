import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    anchors.fill: parent

    property int rows: 0
    property int columns: 0
    property var costMatrix: []
    property var loadMatrix: []
    property var supply: []
    property var demand: []

    property var errorNotifier: null

    property var curLoad: []
    property var markMatrix: []

    // 0=4.1, 1=4.2, 2=4.3, 3=4.4, 4=4.5, 5=4.6, 6=оптимально
    property int phase: 0

    property var u: []
    property var v: []

    property int pickType: 0
    property int pickIndex: 0
    property string valueText: ""
    property string errorText: ""
    property string hintText: ""

    property int deltaMode: 0
    property int dR: -1
    property int dC: -1
    property string deltaText: ""
    property string deltaError: ""
    property int enterR: -1
    property int enterC: -1
    property var checkedDeltas: []

    property var cycleCells: []
    property int cyclePos: 1
    property string cycleError: ""
    property int cycleDirection: 0   // 0 = ещё не выбрано, 1 = вперёд, -1 = назад

    property int expectedR: 0
    property string rText: ""
    property string rError: ""

    property var leavingCells: []
    property string leaveError: ""

    property bool stateInitialized: false
    property int iterationCount: 1



    signal practiceCompleted(var finalLoad, int totalCost, int iterationsCount)

    function notifyError(message) {
        if (root.errorNotifier && root.errorNotifier.showError) {
            root.errorNotifier.showError(message, "Ошибка контроля")
        }
    }

    function setPhaseError(message) {
        errorText = message
        notifyError(message)
    }

    function setDeltaError(message) {
        deltaError = message
        notifyError(message)
    }

    function setCycleError(message) {
        cycleError = message
        notifyError(message)
    }

    function setRError(message) {
        rError = message
        notifyError(message)
    }

    function setLeaveError(message) {
        leaveError = message
        notifyError(message)
    }

    function toNum(x) {
        const s = (x === undefined || x === null) ? "" : String(x).trim()
        const n = Number(s)
        return Number.isFinite(n) ? n : NaN
    }

    function toIntSafe(x) {
        const s = (x === undefined || x === null) ? "" : String(x).trim()
        const n = Number(s)
        return Number.isFinite(n) ? Math.trunc(n) : 0
    }

    function copy2D(a, rCount, cCount) {
        let out = new Array(rCount)
        for (let r = 0; r < rCount; r++) {
            let src = (a && a[r]) ? a[r] : []
            let row = new Array(cCount)
            for (let c = 0; c < cCount; c++)
                row[c] = src[c]
            out[r] = row
        }
        return out
    }

    function initMarks() {
        let m = new Array(rows)
        for (let r = 0; r < rows; r++)
            m[r] = new Array(columns).fill("")
        markMatrix = m
    }

    function initializeIfNeeded() {
        if (!stateInitialized)
            initAll()
    }

    function resetForNewSourceData() {
        stateInitialized = false
        if (visible)
            initAll()
    }

    function isBasicCell(r, c) {
        if (!curLoad || !curLoad[r])
            return false

        const raw = curLoad[r][c]
        if (raw === undefined || raw === null || String(raw).trim() === "")
            return false

        const x = toNum(raw)
        return Number.isFinite(x)
    }

    function isNonBasicCell(r, c) {
        return !isBasicCell(r, c)
    }

    function calcPlanCost() {
        let sum = 0
        for (let r = 0; r < rows; r++) {
            for (let c = 0; c < columns; c++) {
                if (!isBasicCell(r, c))
                    continue

                const x = toNum(curLoad[r][c])
                const cost = toNum(costMatrix[r][c])

                if (!Number.isFinite(x) || !Number.isFinite(cost))
                    continue

                sum += x * cost
            }
        }
        return Math.trunc(sum)
    }

    function findCheckedDeltaIndex(r, c) {
        for (let i = 0; i < checkedDeltas.length; i++) {
            const item = checkedDeltas[i]
            if (item.r === r && item.c === c)
                return i
        }
        return -1
    }

    function checkedDeltaValue(r, c) {
        const idx = findCheckedDeltaIndex(r, c)
        return idx >= 0 ? checkedDeltas[idx].value : null
    }

    function saveCheckedDelta(r, c, value) {
        let copy = checkedDeltas.slice()
        const idx = findCheckedDeltaIndex(r, c)
        const item = { r: r, c: c, value: value }

        if (idx >= 0)
            copy[idx] = item
        else
            copy.push(item)

        copy.sort((a, b) => {
            if (a.r !== b.r)
                return a.r - b.r
            return a.c - b.c
        })

        checkedDeltas = copy
    }

    function initAll() {
        if (rows <= 0 || columns <= 0) {
            curLoad = []
            markMatrix = []

            u = []
            v = []

            pickType = 0
            pickIndex = 0
            valueText = ""
            errorText = ""

            deltaMode = 0
            dR = -1
            dC = -1
            deltaText = ""
            deltaError = ""
            enterR = -1
            enterC = -1
            checkedDeltas = []

            cycleCells = []
            cyclePos = 1
            cycleError = ""
            cycleDirection = 0

            expectedR = 0
            rText = ""
            rError = ""

            leavingCells = []
            leaveError = ""

            phase = 0
            hintText = ""
            iterationCount = 1
            stateInitialized = false
            return
        }

        curLoad = copy2D(loadMatrix, rows, columns)

        u = new Array(rows).fill(null)
        v = new Array(columns).fill(null)

        pickType = 0
        pickIndex = 0
        valueText = ""
        errorText = ""

        deltaMode = 0
        dR = -1
        dC = -1
        deltaText = ""
        deltaError = ""
        enterR = -1
        enterC = -1
        checkedDeltas = []

        cycleCells = []
        cyclePos = 1
        cycleError = ""
        cycleDirection = 0

        expectedR = 0
        rText = ""
        rError = ""

        leavingCells = []
        leaveError = ""

        initMarks()

        phase = 0
        hintText = "4.1: Задай любой один потенциал u_i или v_j."
        iterationCount = 1

        stateInitialized = true
    }

    onVisibleChanged: {
        if (visible)
            initializeIfNeeded()
    }

    onRowsChanged: resetForNewSourceData()
    onColumnsChanged: resetForNewSourceData()
    onCostMatrixChanged: resetForNewSourceData()
    onLoadMatrixChanged: resetForNewSourceData()
    onSupplyChanged: resetForNewSourceData()
    onDemandChanged: resetForNewSourceData()

    function impliedU(i) {
        if (u[i] !== null)
            return null

        for (let j = 0; j < columns; j++) {
            if (!isBasicCell(i, j))
                continue
            if (v[j] === null)
                continue

            const c = toNum(costMatrix[i][j])
            if (!Number.isFinite(c))
                continue

            return c - v[j]
        }
        return null
    }

    function impliedV(j) {
        if (v[j] !== null)
            return null

        for (let i = 0; i < rows; i++) {
            if (!isBasicCell(i, j))
                continue
            if (u[i] === null)
                continue

            const c = toNum(costMatrix[i][j])
            if (!Number.isFinite(c))
                continue

            return c - u[i]
        }
        return null
    }

    function allPotentialsKnown() {
        for (let i = 0; i < rows; i++) {
            if (u[i] === null)
                return false
        }

        for (let j = 0; j < columns; j++) {
            if (v[j] === null)
                return false
        }

        return true
    }

    function submitPotential() {
        errorText = ""

        const val = toNum(valueText)
        if (!Number.isFinite(val)) {
            setPhaseError("Введите корректное число.")
            return
        }

        if (phase === 0) {
            if (pickType === 0)
                u[pickIndex] = val
            else
                v[pickIndex] = val

            u = u.slice()
            v = v.slice()

            phase = 1
            valueText = ""
            hintText = "4.2: Вводи остальные потенциалы по базисным клеткам из равенства u_i + v_j = c_ij."
            return
        }

        if (phase === 1) {
            if (pickType === 0) {
                if (u[pickIndex] !== null) {
                    setPhaseError("Этот u уже задан.")
                    return
                }

                const exp = impliedU(pickIndex)
                if (exp === null) {
                    setPhaseError("Пока нельзя вычислить этот u: нужен базисный элемент с уже известным v.")
                    return
                }

                if (val !== exp) {
                    setPhaseError("Ошибка (4.2): неверный потенциал. Должно быть " + exp + ".")
                    return
                }

                u[pickIndex] = val
                u = u.slice()
            } else {
                if (v[pickIndex] !== null) {
                    setPhaseError("Этот v уже задан.")
                    return
                }

                const exp = impliedV(pickIndex)
                if (exp === null) {
                    setPhaseError("Пока нельзя вычислить этот v: нужен базисный элемент с уже известным u.")
                    return
                }

                if (val !== exp) {
                    setPhaseError("Ошибка (4.2): неверный потенциал. Должно быть " + exp + ".")
                    return
                }

                v[pickIndex] = val
                v = v.slice()
            }

            valueText = ""

            if (allPotentialsKnown()) {
                phase = 2
                deltaMode = 0
                dR = -1
                dC = -1
                deltaText = ""
                deltaError = ""
                checkedDeltas = []
                hintText = "4.3: Выбери небазисную клетку, вычисли Δ_ij = c_ij - (u_i + v_j), затем выбери входящую клетку или укажи, что задача решена."
            }
        }
    }

    function deltaExpected(r, c) {
        const cst = toNum(costMatrix[r][c])
        if (!Number.isFinite(cst))
            return NaN

        return cst - (u[r] + v[c])
    }

    function hasNegativeDelta() {
        for (let r = 0; r < rows; r++) {
            for (let c = 0; c < columns; c++) {
                if (!isNonBasicCell(r, c))
                    continue

                const d = deltaExpected(r, c)
                if (!Number.isFinite(d))
                    continue

                if (d < 0)
                    return true
            }
        }

        return false
    }

    function submitDelta() {
        deltaError = ""

        if (phase !== 2 || deltaMode !== 1)
            return

        const user = toNum(deltaText)
        if (!Number.isFinite(user)) {
            setDeltaError("Введите корректное Δ.")
            return
        }

        const exp = deltaExpected(dR, dC)
        if (!Number.isFinite(exp)) {
            setDeltaError("Невозможно вычислить Δ для этой клетки.")
            return
        }

        if (user !== exp) {
            setDeltaError("Ошибка (4.3.2): неверно вычислена Δ. Должно быть " + exp + ".")
            return
        }

        saveCheckedDelta(dR, dC, exp)

        deltaMode = 0
        dR = -1
        dC = -1
        deltaText = ""
        hintText = "4.3: Можно вычислить следующую Δ, выбрать входящую клетку или указать, что задача решена."
    }

    function startChooseEntering() {
        deltaError = ""

        if (phase !== 2)
            return

        if (!hasNegativeDelta()) {
            setDeltaError("Ошибка (4.3.3): улучшения нет, все Δ ≥ 0. Нужно нажать «Задача решена».")
            return
        }

        deltaMode = 2
        hintText = "4.3: Кликни по любой небазисной клетке с отрицательной Δ."
    }

    function declareSolved() {
        deltaError = ""

        if (phase !== 2)
            return

        if (hasNegativeDelta()) {
            setDeltaError("Ошибка (4.3.5): задача не решена — есть отрицательные Δ.")
            return
        }

        phase = 6
        hintText = "План оптимален."

        root.practiceCompleted(
            copy2D(curLoad, rows, columns),
            calcPlanCost(),
            iterationCount
        )
    }

    function buildCycle(startR, startC) {
        let nodes = []

        for (let r = 0; r < rows; r++) {
            for (let c = 0; c < columns; c++) {
                if (isBasicCell(r, c))
                    nodes.push({ r: r, c: c })
            }
        }

        nodes.push({ r: startR, c: startC })

        let byRow = new Array(rows)
        let byCol = new Array(columns)

        for (let i = 0; i < rows; i++)
            byRow[i] = []
        for (let j = 0; j < columns; j++)
            byCol[j] = []

        for (let k = 0; k < nodes.length; k++) {
            const n = nodes[k]
            byRow[n.r].push(n)
            byCol[n.c].push(n)
        }

        function key(n) {
            return n.r + "," + n.c
        }

        function neighbors(n, dir) {
            let list = (dir === 0) ? byRow[n.r] : byCol[n.c]
            let out = []

            for (let i = 0; i < list.length; i++) {
                const m = list[i]
                if (m.r === n.r && m.c === n.c)
                    continue
                out.push(m)
            }

            out.sort((a, b) => dir === 0 ? (a.c - b.c) : (a.r - b.r))
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

                if (used[k])
                    continue

                used[k] = true
                path.push(nxt)

                if (dfs(nxt, start, 1 - dir, path, used))
                    return true

                path.pop()
                delete used[k]
            }

            return false
        }

        const start = { r: startR, c: startC }

        for (let startDir = 0; startDir <= 1; startDir++) {
            let path = [start]
            let used = {}
            used[key(start)] = true

            if (dfs(start, start, startDir, path, used))
                return path
        }

        return []
    }

    function setMark(r, c, s) {
        if (!markMatrix || !markMatrix[r])
            return

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
            setCycleError("Не удалось построить цикл пересчёта.")
            return false
        }

        cycleCells = cyc
        cyclePos = 1
        cycleDirection = 0
        cycleError = ""
        hintText = "4.4: Построй цикл. Кликайте клетки цикла по порядку."
        return true
    }

    function applyPlusMinusMarks() {
        clearMarks()

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
            const cell = cycleCells[k]
            const x = toIntSafe(curLoad[cell.r][cell.c])
            if (x < best)
                best = x
        }

        if (best === Infinity)
            best = 0

        expectedR = best
    }

    function computeLeavingCells() {
        let out = []

        for (let k = 1; k < cycleCells.length - 1; k += 2) {
            const cell = cycleCells[k]
            const x = toIntSafe(curLoad[cell.r][cell.c])
            if (x === expectedR)
                out.push(cell)
        }

        leavingCells = out
    }

    function applyRecalc(rValue, leaving) {
        let newLoad = copy2D(curLoad, rows, columns)

        for (let k = 0; k < cycleCells.length - 1; k++) {
            const cell = cycleCells[k]
            const x0 = toIntSafe(newLoad[cell.r][cell.c])
            const x1 = (k % 2 === 0) ? (x0 + rValue) : (x0 - rValue)
            newLoad[cell.r][cell.c] = (x1 === 0) ? "" : String(x1)
        }

        newLoad[leaving.r][leaving.c] = ""
        curLoad = newLoad
    }

    function handleMatrixClick(r, c) {
        if (phase === 2) {
            deltaError = ""

            if (deltaMode === 0) {
                if (!isNonBasicCell(r, c)) {
                    setDeltaError("Ошибка (4.3.1): Δ считаем только в небазисной клетке.")
                    return
                }

                dR = r
                dC = c

                const saved = checkedDeltaValue(r, c)
                deltaText = (saved !== null) ? String(saved) : ""

                deltaMode = 1
                hintText = "4.3: Введи Δ для выбранной клетки."
                return
            }

            if (deltaMode === 2) {
                if (!isNonBasicCell(r, c)) {
                    setDeltaError("Ошибка (4.3.4): входящая клетка должна быть небазисной.")
                    return
                }

                const chosenDelta = deltaExpected(r, c)
                if (!Number.isFinite(chosenDelta)) {
                    setDeltaError("Ошибка (4.3.4): не удалось вычислить Δ для выбранной клетки.")
                    return
                }

                if (chosenDelta >= 0) {
                    setDeltaError("Ошибка (4.3.4): входящая клетка должна иметь отрицательную Δ.")
                    return
                }

                enterR = r
                enterC = c
                phase = 3

                if (!prepareCycle())
                    return

                return
            }
        }

        if (phase === 3) {
            cycleError = ""

            if (!cycleCells || cycleCells.length < 4) {
                setCycleError("Внутренняя ошибка цикла.")
                return
            }

            let exp = null

            if (cycleDirection === 0) {
                const forwardExp = cycleCells[cyclePos]
                const backwardExp = cycleCells[cycleCells.length - cyclePos - 1]

                const isForward = forwardExp && r === forwardExp.r && c === forwardExp.c
                const isBackward = backwardExp && r === backwardExp.r && c === backwardExp.c

                if (!isForward && !isBackward) {
                    setCycleError("Ошибка (4.4): неверная следующая клетка цикла.")
                    return
                }

                cycleDirection = isForward ? 1 : -1
                exp = isForward ? forwardExp : backwardExp
            } else {
                exp = (cycleDirection === 1)
                      ? cycleCells[cyclePos]
                      : cycleCells[cycleCells.length - cyclePos - 1]

                if (!exp) {
                    setCycleError("Внутренняя ошибка цикла.")
                    return
                }

                if (r !== exp.r || c !== exp.c) {
                    setCycleError("Ошибка (4.4): неверная следующая клетка цикла.")
                    return
                }
            }

            setMark(r, c, "•")
            cyclePos++

            if (cyclePos >= cycleCells.length) {
                applyPlusMinusMarks()
                computeExpectedR()
                rText = ""
                rError = ""
                phase = 4
                hintText = "4.5: Введи r = min(x_ij) по клеткам со знаком '-'."
            }

            return
        }

        if (phase === 5) {
            leaveError = ""

            let ok = false
            for (let i = 0; i < leavingCells.length; i++) {
                if (leavingCells[i].r === r && leavingCells[i].c === c) {
                    ok = true
                    break
                }
            }

            if (!ok) {
                setLeaveError("Ошибка (4.6): нужно выбрать клетку со знаком '-' и минимальным x.")
                return
            }

            const rv = expectedR
            applyRecalc(rv, { r: r, c: c })

            clearMarks()
            iterationCount += 1

            u = new Array(rows).fill(null)
            v = new Array(columns).fill(null)

            pickType = 0
            pickIndex = 0
            valueText = ""
            errorText = ""

            deltaMode = 0
            dR = -1
            dC = -1
            deltaText = ""
            deltaError = ""
            enterR = -1
            enterC = -1
            checkedDeltas = []

            cycleCells = []
            cyclePos = 1
            cycleDirection = 0
            cycleError = ""

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

        if (phase !== 4)
            return

        const user = toNum(rText)
        if (!Number.isFinite(user) || user < 0) {
            setRError("Введите корректное r.")
            return
        }

        if (user !== expectedR) {
            setRError("Ошибка (4.5): неверное r. Должно быть " + expectedR + ".")
            return
        }

        computeLeavingCells()
        phase = 5
        leaveError = ""
        hintText = "4.6: Кликни по удаляемой клетке."
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

            Item {
                Layout.fillHeight: true
            }
        }

        PotentialsStepPanel {
            Layout.preferredWidth: 360
            Layout.fillHeight: true

            rows: root.rows
            columns: root.columns

            phase: root.phase

            pickType: root.pickType
            pickIndex: root.pickIndex
            valueText: root.valueText
            errorText: root.errorText

            u: root.u
            v: root.v

            deltaMode: root.deltaMode
            dR: root.dR
            dC: root.dC
            checkedDeltas: root.checkedDeltas
            deltaText: root.deltaText
            deltaError: root.deltaError

            cycleCells: root.cycleCells
            cyclePos: root.cyclePos
            cycleError: root.cycleError

            rText: root.rText
            rError: root.rError

            leaveError: root.leaveError

            onPickTypeChangedByUser: (value) => root.pickType = value
            onPickIndexChangedByUser: (value) => root.pickIndex = value
            onValueTextChangedByUser: (value) => root.valueText = value
            onSubmitPotentialClicked: root.submitPotential()

            onDeltaTextChangedByUser: (value) => root.deltaText = value
            onSubmitDeltaClicked: root.submitDelta()
            onStartChooseEnteringClicked: root.startChooseEntering()
            onDeclareSolvedClicked: root.declareSolved()

            onRTextChangedByUser: (value) => root.rText = value
            onCheckRClicked: root.checkR()
        }
    }
}

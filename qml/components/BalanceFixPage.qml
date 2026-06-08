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

    // внешний объект уведомления
    property var errorNotifier: null

    signal balancedYes()
    signal balanceFixPassed(int who, int volume)

    property int selectedWho: -1
    property string volumeText: ""
    property string errorText: ""
    property bool showFixSection: false

    function notifyError(message) {
        errorText = message

        if (root.errorNotifier && root.errorNotifier.showError) {
            root.errorNotifier.showError(message, "Ошибка контроля")
        }
    }

    function toIntOrNaN(x) {
        if (x === undefined || x === null) return NaN
        if (typeof x === "number") return x
        const s = String(x).trim()
        if (s === "") return NaN
        const n = Number(s)
        return Number.isFinite(n) ? n : NaN
    }

    function sumVector(vec, expectedLen) {
        if (!vec || vec.length !== expectedLen)
            return NaN

        let sum = 0
        for (let i = 0; i < expectedLen; i++) {
            const v = toIntOrNaN(vec[i])
            if (!Number.isFinite(v))
                return NaN
            sum += v
        }
        return sum
    }

    function checkBalanced() {
        const sumS = sumVector(supply, rows)
        const sumD = sumVector(demand, columns)

        if (rows <= 0 || columns <= 0)
            return { ok: false, error: "Неверная размерность матрицы." }

        if (!Number.isFinite(sumS))
            return { ok: false, error: "Запасы заполнены некорректно." }

        if (!Number.isFinite(sumD))
            return { ok: false, error: "Потребности заполнены некорректно." }

        return {
            ok: true,
            balanced: sumS === sumD,
            sumS: sumS,
            sumD: sumD
        }
    }

    function expectedAnswer() {
        const res = checkBalanced()
        if (!res.ok)
            return res

        if (res.balanced) {
            return {
                ok: false,
                error: "Задача уже сбалансирована — балансировка не требуется."
            }
        }

        if (res.sumS < res.sumD) {
            return {
                ok: true,
                who: 0, // добавить поставщика
                volume: res.sumD - res.sumS,
                sumS: res.sumS,
                sumD: res.sumD
            }
        }

        return {
            ok: true,
            who: 1, // добавить потребителя
            volume: res.sumS - res.sumD,
            sumS: res.sumS,
            sumD: res.sumD
        }
    }

    function resetFixInputs() {
        selectedWho = -1
        volumeText = ""
    }

    function resetPageState() {
        showFixSection = false
        errorText = ""
        resetFixInputs()
    }

    function handleAnswer(userSaysBalanced) {
        errorText = ""

        const res = checkBalanced()
        if (!res.ok) {
            notifyError(res.error)
            return
        }

        if (userSaysBalanced && res.balanced) {
            showFixSection = false
            resetFixInputs()
            root.balancedYes()
            return
        }

        if (!userSaysBalanced && !res.balanced) {
            showFixSection = true
            resetFixInputs()
            return
        }

        showFixSection = false
        resetFixInputs()

        if (userSaysBalanced && !res.balanced) {
            notifyError("Ошибка (1): неверный ответ. Задача не сбалансирована.")
        } else if (!userSaysBalanced && res.balanced) {
            notifyError("Ошибка (1): неверный ответ. Задача сбалансирована.")
        }
    }

    function checkAndBalance() {
        errorText = ""

        const exp = expectedAnswer()
        if (!exp.ok) {
            notifyError(exp.error)
            return
        }

        if (!showFixSection) {
            notifyError("Сначала нужно правильно определить, что задача не сбалансирована.")
            return
        }

        if (selectedWho !== 0 && selectedWho !== 1) {
            notifyError("Выберите, кого добавить: поставщика или потребителя.")
            return
        }

        const userVol = toIntOrNaN(volumeText)
        if (!Number.isFinite(userVol) || userVol < 0) {
            notifyError("Введите корректный объём.")
            return
        }

        if (selectedWho !== exp.who) {
            notifyError("Ошибка (2.1): выбран неверный тип. Нужно добавить " +
                        (exp.who === 0 ? "поставщика." : "потребителя."))
            return
        }

        if (userVol !== exp.volume) {
            notifyError("Ошибка (2.2): неверный объём. Должно быть " + exp.volume + ".")
            return
        }

        root.balanceFixPassed(exp.who, exp.volume)
    }

    onRowsChanged: resetPageState()
    onColumnsChanged: resetPageState()
    onCostMatrixChanged: resetPageState()
    onSupplyChanged: resetPageState()
    onDemandChanged: resetPageState()

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

            readonly property int sidePadding: 16
            readonly property int cardMaxWidth: 760
            readonly property int sectionWidth: Math.min(width - sidePadding * 2, cardMaxWidth)

            width: Math.max(pageScroll.availableWidth, matrixPreview.implicitWidth + 32, cardMaxWidth + 32)
            height: contentColumn.implicitHeight + 32

            ColumnLayout {
                id: contentColumn
                width: pageContent.width - 32
                anchors.top: parent.top
                anchors.topMargin: 16
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 18

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
                    Layout.alignment: Qt.AlignHCenter
                    text: "Этап 1: Баланс / балансировка"
                    font.pixelSize: 20
                    font.bold: true
                    color: "#111"
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: pageContent.sectionWidth
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                    color: "#444"
                    font.pixelSize: 14
                    text: !root.showFixSection
                          ? "Сначала определи, сбалансирована ли транспортная задача."
                          : "Теперь выполни балансировку: укажи, кого нужно добавить и с каким объёмом."
                }

                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: pageContent.sectionWidth
                    visible: !root.showFixSection

                    radius: 14
                    color: "#ffffff"
                    border.color: "#e5e5e5"
                    implicitHeight: questionContent.implicitHeight + 32

                    ColumnLayout {
                        id: questionContent
                        width: parent.width - 32
                        anchors.top: parent.top
                        anchors.topMargin: 16
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 14

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "Сбалансирована ли транспортная задача?"
                            font.pixelSize: 18
                            font.bold: true
                            color: "#111"
                        }

                        RowLayout {
                            Layout.alignment: Qt.AlignHCenter
                            spacing: 12

                            Button {
                                implicitWidth: 72
                                implicitHeight: 42
                                text: "Да"

                                background: Rectangle {
                                    radius: 10
                                    color: "#22c55e"
                                }

                                contentItem: Text {
                                    text: parent.text
                                    color: "white"
                                    font.pixelSize: 16
                                    font.bold: true
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }

                                onClicked: handleAnswer(true)
                            }

                            Button {
                                implicitWidth: 72
                                implicitHeight: 42
                                text: "Нет"

                                background: Rectangle {
                                    radius: 10
                                    color: "#ef4444"
                                }

                                contentItem: Text {
                                    text: parent.text
                                    color: "white"
                                    font.pixelSize: 16
                                    font.bold: true
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }

                                onClicked: handleAnswer(false)
                            }
                        }

                        Rectangle {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.preferredWidth: parent.width
                            implicitHeight: hintText.implicitHeight + 20
                            radius: 10
                            color: "#f8fafc"
                            border.color: "#e2e8f0"

                            Text {
                                id: hintText
                                anchors.fill: parent
                                anchors.margins: 10
                                text: "Подсказка: сумма запасов должна равняться сумме потребностей."
                                wrapMode: Text.WordWrap
                                horizontalAlignment: Text.AlignHCenter
                                color: "#475569"
                                font.pixelSize: 14
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: pageContent.sectionWidth
                    visible: root.showFixSection

                    radius: 14
                    color: "#ffffff"
                    border.color: "#e5e5e5"
                    implicitHeight: fixContent.implicitHeight + 32

                    ColumnLayout {
                        id: fixContent
                        width: parent.width - 32
                        anchors.top: parent.top
                        anchors.topMargin: 16
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 14

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "Балансировка"
                            font.pixelSize: 18
                            font.bold: true
                            color: "#111"
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.preferredWidth: parent.width
                            wrapMode: Text.WordWrap
                            horizontalAlignment: Text.AlignHCenter
                            color: "#444"
                            font.pixelSize: 14
                            text: "Выбери, кого нужно добавить для балансировки, и укажи правильный объём."
                        }

                        Rectangle {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.preferredWidth: parent.width
                            implicitHeight: radioBlock.implicitHeight + 20
                            radius: 10
                            color: "#faf8f4"
                            border.color: "#ece5d9"

                            ColumnLayout {
                                id: radioBlock
                                width: parent.width - 20
                                anchors.top: parent.top
                                anchors.topMargin: 10
                                anchors.horizontalCenter: parent.horizontalCenter
                                spacing: 10

                                RadioButton {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: "Добавить поставщика"
                                    checked: root.selectedWho === 0
                                    onClicked: root.selectedWho = 0
                                }

                                RadioButton {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: "Добавить потребителя"
                                    checked: root.selectedWho === 1
                                    onClicked: root.selectedWho = 1
                                }
                            }
                        }

                        RowLayout {
                            Layout.alignment: Qt.AlignHCenter
                            spacing: 10

                            Text {
                                text: "Объём:"
                                color: "#111"
                                font.pixelSize: 14
                            }

                            TextField {
                                width: 180
                                placeholderText: "например, 25"
                                text: root.volumeText
                                inputMethodHints: Qt.ImhDigitsOnly
                                onTextChanged: root.volumeText = text
                            }
                        }

                        Button {
                            Layout.alignment: Qt.AlignHCenter
                            implicitWidth: 270
                            implicitHeight: 44
                            text: "Проверить ответ и перейти дальше"

                            onClicked: checkAndBalance()
                        }
                    }
                }
            }
        }
    }
}

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    anchors.fill: parent
    implicitHeight: contentRow.height

    property var allStepsData: []
    property int currentStepIndex: -1
    property bool workMatrixVisible: false

    readonly property var selectedStep:
        (currentStepIndex >= 0 && currentStepIndex < allStepsData.length)
        ? allStepsData[currentStepIndex]
        : null

    onAllStepsDataChanged: {
        if (allStepsData && allStepsData.length > 0) {
            if (currentStepIndex < 0 || currentStepIndex >= allStepsData.length)
                selectStep(0)
        } else {
            currentStepIndex = -1
            workMatrixVisible = false
        }
    }

    function selectStep(index) {
        if (index < 0 || index >= allStepsData.length)
            return

        currentStepIndex = index
        workMatrixVisible = true
        applyViewerStep(allStepsData[index])
    }

    function applyViewerStep(step) {
        if (!step)
            return

        const rows = step.rows
        const cols = step.cols

        if (rows < 1 || cols < 1)
            return

        if (workMatrix.rows !== rows || workMatrix.columns !== cols)
            workMatrix.resizeAndReset(rows, cols)

        workMatrix.costMatrix = toString2D(step.costMatrix)
        workMatrix.supply = toString1D(step.supply)
        workMatrix.demand = toString1D(step.demand)
        workMatrix.loadMatrix = toString2D(step.loadMatrix)
        workMatrix.markMatrix = toString2D(step.markMatrix)
        workMatrix.selectedRow = step.selectedRow !== undefined ? step.selectedRow : -1
        workMatrix.selectedCol = step.selectedCol !== undefined ? step.selectedCol : -1
        workMatrix.showLoads = true
        workMatrix.showMarks = true
    }

    function toString1D(arr) {
        let out = []
        if (!arr)
            return out

        for (let i = 0; i < arr.length; ++i)
            out.push(String(arr[i]))
        return out
    }

    function toString2D(arr) {
        let out = []
        if (!arr)
            return out

        for (let i = 0; i < arr.length; ++i) {
            let row = []
            for (let j = 0; j < arr[i].length; ++j)
                row.push(String(arr[i][j]))
            out.push(row)
        }
        return out
    }

    Row {
        id: contentRow
        width: root.width
        height: Math.max(viewerPanel.implicitHeight, stepsPanel.height)
        spacing: 20

        Rectangle {
            id: viewerPanel
            width: Math.max(320, root.width - stepsPanel.width - contentRow.spacing)
            height: implicitHeight
            implicitHeight: viewerColumn.implicitHeight + 32
            color: "#ffffff"
            border.color: "#dcdcdc"
            radius: 14

            Column {
                id: viewerColumn
                x: 16
                y: 16
                width: parent.width - 32
                spacing: 12

                Text {
                    visible: selectedStep !== null
                    width: parent.width
                    text: selectedStep ? selectedStep.title : ""
                    font.pixelSize: 24
                    font.bold: true
                    color: "#222222"
                    wrapMode: Text.WordWrap
                }

                Text {
                    visible: selectedStep !== null
                             && selectedStep.description
                             && selectedStep.description.length > 0
                    width: parent.width
                    text: selectedStep ? selectedStep.description : ""
                    wrapMode: Text.WordWrap
                    font.pixelSize: 15
                    color: "#555555"
                }

                Rectangle {
                    id: matrixViewport
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width
                    height: Math.max(260, scaledMatrixWrapper.height + 24)
                    radius: 12
                    color: "#fafafa"
                    border.color: "#e3e3e3"
                    clip: true

                    readonly property real availableMatrixWidth: Math.max(1, width - 24)
                    readonly property real naturalMatrixWidth: workMatrixVisible ? workMatrix.implicitWidth : 0
                    readonly property real naturalMatrixHeight: workMatrixVisible ? workMatrix.implicitHeight : 0
                    readonly property real matrixScale:
                        naturalMatrixWidth > 0
                        ? Math.min(1.0, availableMatrixWidth / naturalMatrixWidth)
                        : 1.0

                    Item {
                        id: scaledMatrixWrapper
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.top
                        anchors.topMargin: 12

                        width: matrixViewport.naturalMatrixWidth * matrixViewport.matrixScale
                        height: matrixViewport.naturalMatrixHeight * matrixViewport.matrixScale

                        Item {
                            id: matrixContent
                            x: 0
                            y: 0
                            width: matrixViewport.naturalMatrixWidth
                            height: matrixViewport.naturalMatrixHeight
                            scale: matrixViewport.matrixScale
                            transformOrigin: Item.TopLeft
                        }
                    }
                }

                CalculationBlock {
                    id: calcBlock
                    visible: selectedStep !== null
                             && selectedStep.calculationText
                             && selectedStep.calculationText.length > 0
                    width: parent.width
                    title: "Расчёты"
                    subtitle: selectedStep ? selectedStep.title : ""
                    calculationText: selectedStep ? selectedStep.calculationText : ""
                }

                Item {
                    visible: allStepsData.length > 0
                    width: parent.width
                    height: bottomNavRow.implicitHeight

                    Row {
                        id: bottomNavRow
                        anchors.right: parent.right
                        spacing: 10

                        Button {
                            text: "Назад"
                            enabled: currentStepIndex > 0
                            onClicked: selectStep(currentStepIndex - 1)
                        }

                        Button {
                            text: "Вперёд"
                            enabled: currentStepIndex >= 0
                                     && currentStepIndex < allStepsData.length - 1
                            onClicked: selectStep(currentStepIndex + 1)
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: currentStepIndex >= 0
                                  ? (currentStepIndex + 1) + " / " + allStepsData.length
                                  : "0 / 0"
                            color: "#666666"
                            font.pixelSize: 14
                        }
                    }
                }
            }
        }

        Rectangle {
            id: stepsPanel
            width: 400
            height: Math.max(760, viewerPanel.implicitHeight)
            color: "#ffffff"
            border.color: "#dcdcdc"
            radius: 14

            Column {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12

                Text {
                    text: "Шаги решения"
                    font.pixelSize: 22
                    font.bold: true
                    color: "#222222"
                }

                Row {
                    spacing: 10

                    Button {
                        text: "Назад"
                        enabled: currentStepIndex > 0
                        onClicked: selectStep(currentStepIndex - 1)
                    }

                    Button {
                        text: "Вперёд"
                        enabled: currentStepIndex >= 0
                                 && currentStepIndex < allStepsData.length - 1
                        onClicked: selectStep(currentStepIndex + 1)
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: currentStepIndex >= 0
                              ? (currentStepIndex + 1) + " / " + allStepsData.length
                              : "0 / 0"
                        color: "#666666"
                        font.pixelSize: 14
                    }
                }

                ListView {
                    id: stepsView
                    width: parent.width
                    height: parent.height - 80
                    clip: true
                    spacing: 8
                    model: allStepsData

                    delegate: Rectangle {
                        required property int index
                        required property var modelData

                        width: stepsView.width
                        radius: 10
                        color: index === currentStepIndex ? "#e8f1ff" : "#ffffff"
                        border.color: index === currentStepIndex ? "#7aa7ff" : "#d7d7d7"
                        border.width: 1
                        implicitHeight: cardColumn.implicitHeight + 18

                        Column {
                            id: cardColumn
                            x: 12
                            y: 10
                            width: parent.width - 24
                            spacing: 5

                            Text {
                                width: parent.width
                                text: (index + 1) + ". " + (modelData.title || "")
                                wrapMode: Text.WordWrap
                                font.pixelSize: 16
                                font.bold: true
                                color: "#222222"
                            }

                            Text {
                                width: parent.width
                                visible: modelData.stage !== undefined && modelData.stage !== ""
                                text: "Этап: " + modelData.stage
                                wrapMode: Text.WordWrap
                                font.pixelSize: 13
                                color: "#5f6b7a"
                            }

                            Text {
                                width: parent.width
                                visible: modelData.description !== undefined && modelData.description !== ""
                                text: modelData.description
                                wrapMode: Text.WordWrap
                                font.pixelSize: 14
                                color: "#555555"
                                maximumLineCount: 3
                                elide: Text.ElideRight
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: selectStep(index)
                        }
                    }
                }
            }
        }
    }

    MatrixView {
        id: workMatrix
        parent: matrixContent
        x: 0
        y: 0

        visible: workMatrixVisible
        readOnly: true
        autoInit: false
        interactive: false
        showLoads: true
        showMarks: true

        rows: 0
        columns: 0
    }
}

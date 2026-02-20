import QtQuick
import "../components"

Item {
    id: theoryScreen
    anchors.fill: parent



    Item {
            id: matrixContainer
            anchors.fill: parent
             anchors.margins: 200

        }

    function log(){
        console.log("проверка работы лога")
    }

    function createMatrix(r, c) {
        console.log("createMatrix вызвана с", r, "×", c)
            console.log("matrixContainer существует?")

        let comp = Qt.createComponent("../components/MatrixView.qml")
        if (comp.status === Component.Ready) {
            let obj = comp.createObject(matrixContainer, {
                rows: r,
                columns: c,
                x: 40,
                y: 40,

            })

        } else {
            console.warn("Не удалось создать MatrixView:", comp.errorString())
        }
    }
}

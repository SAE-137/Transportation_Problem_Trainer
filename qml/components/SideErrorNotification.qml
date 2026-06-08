import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    property string titleText: "Ошибка"
    property string messageText: ""
    property int displayDuration: 3200
    property bool shown: false

    width: 380
    height: toastCard.implicitHeight
    z: 9999

    visible: opacity > 0
    opacity: shown ? 1 : 0

    x: parent ? (shown ? parent.width - width - 16 : parent.width + 24) : 0
    y: 16

    function showError(message, title) {
        messageText = message || ""
        titleText = title && title.length > 0 ? title : "Ошибка"
        shown = true
        hideTimer.restart()
    }

    function hideNow() {
        shown = false
    }

    Behavior on x {
        NumberAnimation {
            duration: 240
            easing.type: Easing.OutCubic
        }
    }

    Behavior on opacity {
        NumberAnimation {
            duration: 180
        }
    }

    Timer {
        id: hideTimer
        interval: root.displayDuration
        repeat: false
        onTriggered: root.hideNow()
    }

    Rectangle {
        id: toastCard
        width: root.width
        implicitHeight: contentColumn.implicitHeight + 24
        radius: 14
        color: "#fff5f5"
        border.color: "#f1b5b5"
        border.width: 1

        ColumnLayout {
            id: contentColumn
            anchors.fill: parent
            anchors.margins: 12
            spacing: 8

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Rectangle {
                    width: 28
                    height: 28
                    radius: 14
                    color: "#dc2626"

                    Text {
                        anchors.centerIn: parent
                        text: "!"
                        color: "white"
                        font.pixelSize: 18
                        font.bold: true
                    }
                }

                Text {
                    text: root.titleText
                    font.pixelSize: 16
                    font.bold: true
                    color: "#991b1b"
                }

                Item {
                    Layout.fillWidth: true
                }

                ToolButton {
                    text: "✕"
                    onClicked: root.hideNow()

                    contentItem: Text {
                        text: parent.text
                        color: "#7f1d1d"
                        font.pixelSize: 14
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    background: Rectangle {
                        radius: 8
                        color: parent.down ? "#f7d6d6"
                                           : parent.hovered ? "#fde8e8"
                                                            : "transparent"
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                text: root.messageText
                wrapMode: Text.WordWrap
                color: "#7f1d1d"
                font.pixelSize: 14
            }
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton
            onClicked: root.hideNow()
        }
    }
}

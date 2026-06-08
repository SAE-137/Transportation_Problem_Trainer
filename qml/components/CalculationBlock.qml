import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root

    property string title: ""
    property string subtitle: ""
    property string calculationText: ""
    property string footerText: ""

    property color accentColor: "#3b82f6"
    property color borderColor: "#d9dee7"
    property color backgroundColor: "#ffffff"
    property color headerBackground: "#f7f9fc"
    property color textColor: "#1f2937"
    property color mutedTextColor: "#6b7280"

    radius: 14
    color: backgroundColor
    border.color: borderColor
    border.width: 1

    implicitWidth: 760
    implicitHeight: contentColumn.implicitHeight + 24

    Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 6
        radius: 14
        color: accentColor
    }

    Column {
        id: contentColumn
        x: 18
        y: 12
        width: parent.width - 36
        spacing: 0

        Rectangle {
            width: parent.width
            height: headerColumn.implicitHeight + 20
            radius: 10
            color: headerBackground
            border.color: "#e7ebf1"
            border.width: 1

            Column {
                id: headerColumn
                x: 16
                y: 10
                width: parent.width - 32
                spacing: 4

                Text {
                    visible: root.title.length > 0
                    width: parent.width
                    text: root.title
                    wrapMode: Text.WordWrap
                    font.pixelSize: 18
                    font.bold: true
                    color: root.textColor
                }

                Text {
                    visible: root.subtitle.length > 0
                    width: parent.width
                    text: root.subtitle
                    wrapMode: Text.WordWrap
                    font.pixelSize: 13
                    color: root.mutedTextColor
                }
            }
        }

        Item {
            width: 1
            height: 12
            visible: root.calculationText.length > 0
        }

        Rectangle {
            visible: root.calculationText.length > 0
            width: parent.width
            height: calcArea.implicitHeight + 24
            radius: 10
            color: "#fcfcfd"
            border.color: "#eceff4"
            border.width: 1

            TextArea {
                id: calcArea
                x: 16
                y: 12
                width: parent.width - 32
                text: root.calculationText
                readOnly: true
                selectByMouse: true
                wrapMode: TextArea.Wrap
                color: root.textColor
                font.pixelSize: 15
                font.family: "Consolas"
                padding: 0

                background: null
            }
        }

        Item {
            width: 1
            height: 12
            visible: root.footerText.length > 0
        }

        Rectangle {
            visible: root.footerText.length > 0
            width: parent.width
            height: footerLabel.implicitHeight + 20
            radius: 10
            color: "#eef6ff"
            border.color: "#cfe1ff"
            border.width: 1

            Text {
                id: footerLabel
                x: 16
                y: 10
                width: parent.width - 32
                text: root.footerText
                wrapMode: Text.WordWrap
                font.pixelSize: 14
                font.bold: true
                color: "#1d4ed8"
            }
        }
    }
}

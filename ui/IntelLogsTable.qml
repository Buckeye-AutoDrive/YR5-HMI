import QtQuick 2.15
import QtQuick.Controls 2.15
import HMI_Mk1 1.0 as HMI

Item {
    id: root
    // QAbstractListModel from IntelLogsBackend.model
    property var model: null

    readonly property int tableRadius: HMI.Theme.px(4)
    readonly property int rowHeight: HMI.Theme.px(40)
    readonly property int headerHeight: HMI.Theme.px(36)
    readonly property int cellPadding: HMI.Theme.px(10)
    readonly property int colGap: HMI.Theme.px(8)

    function colW(totalWidth, ratio) {
        const avail = Math.max(0, totalWidth - 2 * cellPadding - colGap);
        return avail * ratio;
    }

    Rectangle {
        id: tableFrame
        anchors.fill: parent
        radius: tableRadius
        color: HMI.Theme.surface
        border.color: HMI.Theme.outline
        border.width: 1
        clip: true

        Item {
            id: header
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: headerHeight

            Row {
                anchors.fill: parent
                anchors.leftMargin: cellPadding
                anchors.rightMargin: cellPadding
                spacing: colGap

                Label {
                    text: "Message"
                    color: HMI.Theme.sub
                    font.pixelSize: HMI.Theme.px(14)
                    font.weight: Font.DemiBold
                    width: colW(tableFrame.width, 0.82)
                    verticalAlignment: Text.AlignVCenter
                    height: headerHeight
                    elide: Text.ElideRight
                }
                Label {
                    text: "Time"
                    color: HMI.Theme.sub
                    font.pixelSize: HMI.Theme.px(14)
                    font.weight: Font.DemiBold
                    width: colW(tableFrame.width, 0.18)
                    horizontalAlignment: Text.AlignRight
                    verticalAlignment: Text.AlignVCenter
                    height: headerHeight
                }
            }

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: 1
                color: HMI.Theme.outline
            }
        }

        ListView {
            id: table
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: header.bottom
            anchors.bottom: parent.bottom
            model: root.model
            spacing: 0
            clip: true
            boundsBehavior: Flickable.DragAndOvershootBounds
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AlwaysOff }

            delegate: Item {
                width: table.width
                height: rowHeight

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: cellPadding
                    anchors.rightMargin: cellPadding
                    spacing: colGap

                    Label {
                        text: message || "–"
                        color: HMI.Theme.text
                        font.pixelSize: HMI.Theme.px(15)
                        width: colW(table.width, 0.82)
                        elide: Text.ElideRight
                        verticalAlignment: Text.AlignVCenter
                        height: rowHeight
                    }

                    Label {
                        text: time || "–"
                        color: HMI.Theme.text
                        font.pixelSize: HMI.Theme.px(15)
                        font.family: "monospace"
                        width: colW(table.width, 0.18)
                        horizontalAlignment: Text.AlignRight
                        verticalAlignment: Text.AlignVCenter
                        height: rowHeight
                    }
                }

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: 1
                    color: HMI.Theme.outline
                    opacity: 0.6
                }
            }
        }
    }
}


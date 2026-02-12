import QtQuick 2.15
import QtQuick.Controls 2.15
import HMI_Mk1 1.0 as HMI

Item {
    id: root
    property var rows: []   // can be JS array or ListModel

    readonly property int tableRadius: HMI.Theme.px(4)
    readonly property int rowHeight: HMI.Theme.px(40)
    readonly property int headerHeight: HMI.Theme.px(36)
    readonly property int cellPadding: HMI.Theme.px(10)
    readonly property int colGap: HMI.Theme.px(8)

    function colW(totalWidth, ratio) {
        const avail = Math.max(0, totalWidth - 2 * cellPadding - 2 * colGap);
        return avail * ratio;
    }

    // Single table container — one subtle radius, no per-row pills
    Rectangle {
        id: tableFrame
        anchors.fill: parent
        radius: tableRadius
        color: HMI.Theme.surface
        border.color: HMI.Theme.outline
        border.width: 1
        clip: true

        // Header — flat bar, bottom border only
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
                anchors.topMargin: 0
                anchors.bottomMargin: 0
                spacing: colGap
                leftPadding: 0
                rightPadding: 0

                Label {
                    text: "Source"
                    color: HMI.Theme.sub
                    font.pixelSize: HMI.Theme.px(14)
                    font.weight: Font.DemiBold
                    width: colW(tableFrame.width, HMI.Theme.colSource)
                    verticalAlignment: Text.AlignVCenter
                    height: headerHeight
                }
                Label {
                    text: "ID"
                    color: HMI.Theme.sub
                    font.pixelSize: HMI.Theme.px(14)
                    font.weight: Font.DemiBold
                    width: colW(tableFrame.width, HMI.Theme.colId)
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    height: headerHeight
                }
                Label {
                    text: "Value"
                    color: HMI.Theme.sub
                    font.pixelSize: HMI.Theme.px(14)
                    font.weight: Font.DemiBold
                    width: colW(tableFrame.width, HMI.Theme.colValue)
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

        // Body — row dividers only, no rounded boxes
        ListView {
            id: table
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: header.bottom
            anchors.bottom: parent.bottom
            model: root.rows
            spacing: 0
            clip: true
            boundsBehavior: Flickable.DragAndOvershootBounds
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AlwaysOff }

            delegate: Item {
                width: table.width
                height: rowHeight
                readonly property bool lm: typeof modelData === "undefined"

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: cellPadding
                    anchors.rightMargin: cellPadding
                    spacing: colGap

                    Label {
                        text: lm ? (source || "–") : ((modelData && modelData.source) || "–")
                        color: HMI.Theme.text
                        font.pixelSize: HMI.Theme.px(15)
                        width: colW(table.width, HMI.Theme.colSource)
                        elide: Text.ElideRight
                        verticalAlignment: Text.AlignVCenter
                        height: rowHeight
                    }
                    Label {
                        text: lm ? (id !== undefined && id !== "" ? id : "–") :
                                   ((modelData && modelData.id !== undefined && modelData.id !== "") ? modelData.id : "–")
                        color: HMI.Theme.text
                        font.pixelSize: HMI.Theme.px(15)
                        width: colW(table.width, HMI.Theme.colId)
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        height: rowHeight
                    }
                    Label {
                        text: {
                            var v = lm ? value : (modelData ? modelData.value : undefined);
                            var u = lm ? unit  : (modelData ? modelData.unit  : undefined);
                            if (v === undefined) return "–";
                            return u ? (v + " " + u) : ("" + v);
                        }
                        color: HMI.Theme.text
                        font.pixelSize: HMI.Theme.px(15)
                        font.family: "monospace"
                        width: colW(table.width, HMI.Theme.colValue)
                        horizontalAlignment: Text.AlignRight
                        verticalAlignment: Text.AlignVCenter
                        height: rowHeight
                    }
                }

                // Row divider
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

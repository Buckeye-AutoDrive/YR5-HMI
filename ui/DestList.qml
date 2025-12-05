// ui/DestList.qml
import QtQuick 2.15
import QtQuick.Controls 2.15
import HMI_Mk1 1.0 as HMI

Item {
    id: root

    // Emitted when a destination row is clicked
    signal destinationSelected(string pointLabel)

    // Column width helper (same as DataTable)
    function colW(totalWidth, ratio) {
        const m = HMI.Theme.px(12), s = HMI.Theme.px(8);
        const avail = Math.max(0, totalWidth - 2*m - 2*s);
        return avail * ratio;
    }

    // Static route data
    ListModel {
        id: routeModel

        // Intersection Challenge
        ListElement { kind: "section"; title: "Intersection Challenge Route" }
        ListElement { kind: "point";  point: "K";   lat: "42.301455"; lon: "-83.698911" }
        ListElement { kind: "point";  point: "i6";  lat: "42.300951"; lon: "-83.699103" }
        ListElement { kind: "point";  point: "i7";  lat: "42.300394"; lon: "-83.699174" }
        ListElement { kind: "point";  point: "i1";  lat: "42.300377"; lon: "-83.698655" }
        ListElement { kind: "point";  point: "i2";  lat: "42.300383"; lon: "-83.697938" }
        ListElement { kind: "point";  point: "u1";  lat: "42.299777"; lon: "-83.698670" }
        ListElement { kind: "point";  point: "i10"; lat: "42.299331"; lon: "-83.699073" }

        // Construction Challenge
        ListElement { kind: "section"; title: "Construction Challenge Route" }
        ListElement { kind: "point";  point: "A";   lat: "42.299886"; lon: "-83.697457" }
        ListElement { kind: "point";  point: "D";   lat: "42.300926"; lon: "-83.698318" }
    }

    // ----- Header with buttons -----
    Rectangle {
        id: header
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: HMI.Theme.px(44)
        radius: HMI.Theme.radius
        color: "#1A1A1A"
        border.color: HMI.Theme.outline

        Row {
            anchors.fill: parent
            anchors.margins: HMI.Theme.px(12)
            spacing: HMI.Theme.px(8)

            Button {
                id: pointHeader
                text: "Point"
                width: colW(root.width, HMI.Theme.colSource)
                flat: true
                background: Rectangle { color: "transparent" }
                contentItem: Text {
                    text: pointHeader.text
                    color: HMI.Theme.sub
                    font.pixelSize: HMI.Theme.px(18)
                    horizontalAlignment: Text.AlignLeft
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                }
                // Hook sorting etc. here later if needed
            }

            Button {
                id: latHeader
                text: "Lat."
                width: colW(root.width, HMI.Theme.colId)
                flat: true
                background: Rectangle { color: "transparent" }
                contentItem: Text {
                    text: latHeader.text
                    color: HMI.Theme.sub
                    font.pixelSize: HMI.Theme.px(18)
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }

            Button {
                id: lonHeader
                text: "Long."
                width: colW(root.width, HMI.Theme.colValue)
                flat: true
                background: Rectangle { color: "transparent" }
                contentItem: Text {
                    text: lonHeader.text
                    color: HMI.Theme.sub
                    font.pixelSize: HMI.Theme.px(18)
                    horizontalAlignment: Text.AlignRight
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }
    }

    // ----- Body (same scroll behavior as DataTable) -----
    ListView {
        id: table
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: header.bottom
        anchors.bottom: parent.bottom

        model: routeModel
        spacing: HMI.Theme.px(6)
        clip: true
        boundsBehavior: Flickable.DragAndOvershootBounds
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AlwaysOff }

        delegate: Rectangle {
            width: table.width
            height: kind === "section" ? HMI.Theme.px(40) : HMI.Theme.px(52)
            radius: HMI.Theme.radius
            color: kind === "section" ? "#151515" : "#171717"
            border.color: kind === "section" ? "transparent" : HMI.Theme.outline

            // Two row layouts: one for section headers, one for actual points
            Row {
                id: sectionRow
                anchors.fill: parent
                anchors.margins: HMI.Theme.px(12)
                spacing: HMI.Theme.px(8)
                visible: kind === "section"

                Label {
                    text: title
                    color: HMI.Theme.accent
                    font.pixelSize: HMI.Theme.px(18)
                    font.bold: true
                    width: table.width - 2 * HMI.Theme.px(12)
                    elide: Text.ElideRight
                }
            }

            Row {
                id: pointRow
                anchors.fill: parent
                anchors.margins: HMI.Theme.px(12)
                spacing: HMI.Theme.px(8)
                visible: kind === "point"

                Label {
                    text: point
                    color: HMI.Theme.text
                    font.pixelSize: HMI.Theme.px(18)
                    elide: Text.ElideRight
                    width: colW(table.width, HMI.Theme.colSource)
                }

                Label {
                    text: lat
                    color: HMI.Theme.text
                    font.pixelSize: HMI.Theme.px(18)
                    width: colW(table.width, HMI.Theme.colId)
                    horizontalAlignment: Text.AlignHCenter
                    font.family: "monospace"
                }

                Label {
                    text: lon
                    color: HMI.Theme.text
                    font.pixelSize: HMI.Theme.px(18)
                    width: colW(table.width, HMI.Theme.colValue)
                    horizontalAlignment: Text.AlignRight
                    font.family: "monospace"
                }
            }

            // Click to open the AVWarnPage overlay
            MouseArea {
                anchors.fill: parent
                enabled: kind === "point"
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: {
                    if (kind === "point")
                        root.destinationSelected(point);
                }
            }
        }
    }
}

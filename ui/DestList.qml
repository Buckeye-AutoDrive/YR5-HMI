// ui/DestList.qml
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import HMI_Mk1 1.0 as HMI

Item {
    id: root
    signal destinationSelected(string pointLabel)

    ListModel {
        id: routeModel

        // DYO Challenge
        ListElement { kind: "section"; title: "DYO Challenge" }
        ListElement { kind: "point";  point: "A"}
        ListElement { kind: "point";  point: "B"}
        ListElement { kind: "point";  point: "C"}
        ListElement { kind: "point";  point: "D"}

        // Intersection Challenge
        ListElement { kind: "section"; title: "Intersection Challenge" }
        ListElement { kind: "point";  point: "K"}
        ListElement { kind: "point";  point: "i6"}
        ListElement { kind: "point";  point: "i7"}
        ListElement { kind: "point";  point: "i1"}
        ListElement { kind: "point";  point: "i2"}
        ListElement { kind: "point";  point: "u1"}
        ListElement { kind: "point";  point: "i10"}

        // Construction Challenge
        ListElement { kind: "section"; title: "Construction Challenge" }
        ListElement { kind: "point";  point: "A"}
        ListElement { kind: "point";  point: "D"}
    }

    // Flatten into rows:
    // - sectionHeader rows (header-look)
    // - tileRow rows (3 tiles)
    ListModel { id: gridRows }

    function rebuildGridRows() {
        gridRows.clear();

        var rowPoints = [];

        function flushRow() {
            if (rowPoints.length === 0) return;
            gridRows.append({
                kind: "tileRow",
                p0: rowPoints.length > 0 ? rowPoints[0] : "",
                p1: rowPoints.length > 1 ? rowPoints[1] : "",
                p2: rowPoints.length > 2 ? rowPoints[2] : ""
            });
            rowPoints = [];
        }

        for (var i = 0; i < routeModel.count; i++) {
            var e = routeModel.get(i);

            if (e.kind === "section") {
                flushRow();
                // same data, but rendered with the "header" look
                gridRows.append({ kind: "sectionHeader", title: e.title });
            } else {
                rowPoints.push(e.point);
                if (rowPoints.length === 3) flushRow();
            }
        }
        flushRow();
    }

    Component.onCompleted: rebuildGridRows()

    // ----- Body -----
    ListView {
        id: view
        anchors.fill: parent

        model: gridRows
        spacing: HMI.Theme.px(6)
        clip: true
        boundsBehavior: Flickable.DragAndOvershootBounds
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AlwaysOff }

        delegate: Item {
            width: view.width

            // geometry for tile rows
            readonly property int m: HMI.Theme.px(2)
            readonly property int gap: HMI.Theme.px(8)
            readonly property real tileSize: Math.floor((view.width - 2*m - 2*gap) / 3)

            height: (kind === "sectionHeader")
                    ? HMI.Theme.px(44)
                    : (tileSize + 2*m)

            // --- Section header, same look as your header Rectangle ---
            Rectangle {
                visible: kind === "sectionHeader"
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                height: HMI.Theme.px(44)

                radius: HMI.Theme.radius
                color: HMI.Theme.center
                border.color: HMI.Theme.outline

                Text {
                    anchors.fill: parent
                    anchors.margins: HMI.Theme.px(12)
                    text: title
                    color: HMI.Theme.text
                    font.pixelSize: HMI.Theme.px(18)
                    font.bold: false
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                }

            }

            // --- 3 tiles row ---
            Item {
                visible: kind === "tileRow"
                anchors.fill: parent

                Row {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter

                    // use margins for spacing around the 3 tiles
                    anchors.leftMargin: m
                    anchors.rightMargin: m
                    spacing: gap

                    // helper component (keeps code DRY for p0/p1/p2)
                    component TileButton: Rectangle {
                        id: tile
                        property string labelText: ""
                        signal clicked(string label)

                        width: tileSize
                        height: tileSize
                        radius: HMI.Theme.radius

                        readonly property bool hasLabel: labelText && labelText.length
                        color: hasLabel ? HMI.Theme.surface : "transparent"
                        border.color: hasLabel ? HMI.Theme.outline : "transparent"

                        // subtle press "wave" overlay
                        Rectangle {
                            id: ripple
                            anchors.centerIn: parent
                            width: 0
                            height: 0
                            radius: HMI.Theme.radius
                            color: HMI.Theme.text
                            opacity: 0.0
                            visible: tile.hasLabel
                        }

                        // label
                        Text {
                            anchors.centerIn: parent
                            text: tile.labelText
                            color: mouse.pressed ? HMI.Theme.sub : HMI.Theme.text
                            font.pixelSize: HMI.Theme.px(28)
                            font.bold: true
                            visible: tile.hasLabel
                        }

                        MouseArea {
                            id: mouse
                            anchors.fill: parent
                            enabled: tile.hasLabel
                            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor

                            onPressed: {
                                // quick "wave" expand + fade (built-in animations)
                                ripple.width = 0
                                ripple.height = 0
                                ripple.opacity = 0.0
                                rippleAnim.stop()
                                rippleAnim.start()
                            }

                            onClicked: tile.clicked(tile.labelText)
                        }

                        ParallelAnimation {
                            id: rippleAnim

                            // expand the circle
                            NumberAnimation {
                                target: ripple
                                property: "width"
                                from: 0
                                to: tile.width
                                duration: 220
                                easing.type: Easing.OutCubic
                            }
                            NumberAnimation {
                                target: ripple
                                property: "height"
                                from: 0
                                to: tile.height
                                duration: 220
                                easing.type: Easing.OutCubic
                            }

                            // fade in then fade out
                            SequentialAnimation {
                                NumberAnimation {
                                    target: ripple
                                    property: "opacity"
                                    from: 0.0
                                    to: 0.10
                                    duration: 90
                                    easing.type: Easing.OutQuad
                                }
                                NumberAnimation {
                                    target: ripple
                                    property: "opacity"
                                    from: 0.10
                                    to: 0.0
                                    duration: 160
                                    easing.type: Easing.OutQuad
                                }
                            }
                        }

                        // optional: tiny press scale (feels like a button)
                        scale: mouse.pressed ? 0.98 : 1.0
                        Behavior on scale {
                            NumberAnimation { duration: 90; easing.type: Easing.OutQuad }
                        }
                    }

                    // Tile 0
                    TileButton {
                        labelText: p0
                        onClicked: root.destinationSelected(label)
                    }

                    // Tile 1
                    TileButton {
                        labelText: p1
                        onClicked: root.destinationSelected(label)
                    }

                    // Tile 2
                    TileButton {
                        labelText: p2
                        onClicked: root.destinationSelected(label)
                    }
                }
            }
        }
    }
}

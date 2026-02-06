// pages/LoggerPage.qml — Data Logger (same layout style as SettingsPage)
import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import QtQuick.Effects
import HMI_Mk1 1.0 as HMI

Item {
    id: root
    Layout.fillWidth: true
    Layout.fillHeight: true

    // CAN networks selection (frontend-only state)
    property bool canHS: false
    property bool canCE: false
    property bool canSC: false
    property bool canLS: false

    // Recording state (frontend-only)
    property bool recording: false
    property bool paused: false

    readonly property real _canTileSize: HMI.Theme.px(88)
    readonly property real _canSectionHeight: HMI.Theme.px(24) + HMI.Theme.px(14) + (_canTileSize * 2 + HMI.Theme.px(10)) + HMI.Theme.px(32)

    Flickable {
        anchors.fill: parent
        clip: true
        contentWidth: root.width
        contentHeight: contentColumn.implicitHeight + HMI.Theme.px(24)
        boundsBehavior: Flickable.DragAndOvershootBounds
        flickDeceleration: 3000
        maximumFlickVelocity: 2500
        interactive: true

        ColumnLayout {
            id: contentColumn
            width: root.width - 1
            spacing: HMI.Theme.px(12)
            anchors.margins: HMI.Theme.px(16)

            // ——— CAN Network ———
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: root._canSectionHeight
                radius: HMI.Theme.px(18)
                color: HMI.Theme.center
                border.color: HMI.Theme.outline
                border.width: 1
                clip: true

                ColumnLayout {
                    id: canColumn
                    anchors.fill: parent
                    anchors.margins: HMI.Theme.px(16)
                    spacing: HMI.Theme.px(14)

                    Label {
                        text: "CAN Network"
                        color: HMI.Theme.text
                        font.pixelSize: HMI.Theme.px(24)
                        font.bold: true
                        Layout.fillWidth: true
                    }

                    RowLayout {
                        id: canRow
                        Layout.fillWidth: true
                        spacing: HMI.Theme.px(24)

                        // Left: 2x2 grid (HS, CE, SC, LS) — checkbox-style with ripple
                        GridLayout {
                            id: canGrid
                            columns: 2
                            rowSpacing: HMI.Theme.px(10)
                            columnSpacing: HMI.Theme.px(10)
                            Layout.preferredWidth: canTileSize * 2 + canGrid.columnSpacing
                            Layout.preferredHeight: canTileSize * 2 + canGrid.rowSpacing

                            readonly property real canTileSize: root._canTileSize

                            CANCheckTile {
                                label: "HS"
                                checked: root.canHS
                                tileSize: canGrid.canTileSize
                                onToggled: root.canHS = !root.canHS
                            }
                            CANCheckTile {
                                label: "CE"
                                checked: root.canCE
                                tileSize: canGrid.canTileSize
                                onToggled: root.canCE = !root.canCE
                            }
                            CANCheckTile {
                                label: "SC"
                                checked: root.canSC
                                tileSize: canGrid.canTileSize
                                onToggled: root.canSC = !root.canSC
                            }
                            CANCheckTile {
                                label: "LS"
                                checked: root.canLS
                                tileSize: canGrid.canTileSize
                                onToggled: root.canLS = !root.canLS
                            }
                        }

                        // Right: Record, Pause, Stop (with icons)
                        RowLayout {
                            spacing: HMI.Theme.px(10)
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignRight

                            RecordControlButton {
                                iconSource: "../src/icons/record.svg"
                                label: "Record"
                                highlighted: root.recording && !root.paused
                                enabled: true
                                onClicked: {
                                    root.recording = !root.recording
                                    if (!root.recording) root.paused = false
                                }
                            }
                            RecordControlButton {
                                iconSource: root.paused ? "../src/icons/resume.svg" : "../src/icons/pause.svg"
                                label: root.paused ? "Resume" : "Pause"
                                highlighted: root.recording && root.paused
                                enabled: root.recording
                                onClicked: root.paused = !root.paused
                            }
                            RecordControlButton {
                                iconSource: "../src/icons/discard.svg"
                                label: "Discard"
                                highlighted: false
                                enabled: root.recording
                                onClicked: {
                                    root.recording = false
                                    root.paused = false
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // Checkbox-style tile (like DestList) with ripple and selection highlight
    component CANCheckTile: Rectangle {
        id: tile
        property string label: ""
        property bool checked: false
        property real tileSize: HMI.Theme.px(88)
        signal toggled()

        implicitWidth: tileSize
        implicitHeight: tileSize
        radius: HMI.Theme.radius
        color: checked ? Qt.darker(HMI.Theme.accent, 1.15) : HMI.Theme.surface
        border.color: checked ? HMI.Theme.accent : HMI.Theme.outline
        border.width: checked ? 2 : 1

        Rectangle {
            id: ripple
            anchors.centerIn: parent
            width: 0
            height: 0
            radius: HMI.Theme.radius
            color: HMI.Theme.text
            opacity: 0.0
        }

        Text {
            anchors.centerIn: parent
            text: tile.label
            color: mouse.pressed ? HMI.Theme.sub : HMI.Theme.text
            font.pixelSize: HMI.Theme.px(28)
            font.bold: true
        }

        MouseArea {
            id: mouse
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onPressed: {
                ripple.width = 0
                ripple.height = 0
                ripple.opacity = 0.0
                rippleAnim.stop()
                rippleAnim.start()
            }
            onClicked: tile.toggled()
        }

        ParallelAnimation {
            id: rippleAnim
            NumberAnimation { target: ripple; property: "width"; from: 0; to: tile.width; duration: 220; easing.type: Easing.OutCubic }
            NumberAnimation { target: ripple; property: "height"; from: 0; to: tile.height; duration: 220; easing.type: Easing.OutCubic }
            SequentialAnimation {
                NumberAnimation { target: ripple; property: "opacity"; from: 0.0; to: 0.10; duration: 90; easing.type: Easing.OutQuad }
                NumberAnimation { target: ripple; property: "opacity"; from: 0.10; to: 0.0; duration: 160; easing.type: Easing.OutQuad }
            }
        }

        scale: mouse.pressed ? 0.98 : 1.0
        Behavior on scale { NumberAnimation { duration: 90; easing.type: Easing.OutQuad } }
        Behavior on color { ColorAnimation { duration: 120 } }
        Behavior on border.color { ColorAnimation { duration: 120 } }
    }

    // Record control button (icon + optional label)
    component RecordControlButton: Rectangle {
        id: btn
        property string iconSource: ""
        property string label: ""
        property bool highlighted: false
        property bool enabled: true
        signal clicked()

        implicitWidth: HMI.Theme.px(72)
        implicitHeight: HMI.Theme.px(72)
        radius: HMI.Theme.px(14)
        color: !btn.enabled ? HMI.Theme.center
             : mouse.pressed ? Qt.darker(btn.enabled && btn.highlighted ? HMI.Theme.accent : HMI.Theme.surface, 1.2)
             : (btn.highlighted ? HMI.Theme.accent : HMI.Theme.surface)
        border.color: btn.highlighted ? HMI.Theme.accent : HMI.Theme.outline
        border.width: btn.highlighted ? 2 : 1
        opacity: btn.enabled ? 1.0 : 0.5

        ColumnLayout {
            anchors.centerIn: parent
            spacing: HMI.Theme.px(4)

            Item {
                Layout.preferredWidth: HMI.Theme.px(28)
                Layout.preferredHeight: HMI.Theme.px(28)
                Layout.alignment: Qt.AlignHCenter

                property color iconColor: !btn.enabled ? HMI.Theme.sub
                    : (btn.highlighted ? "#FFFFFF" : HMI.Theme.text)

                Image {
                    id: iconImage
                    anchors.fill: parent
                    source: Qt.resolvedUrl(btn.iconSource)
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    mipmap: true
                    visible: false
                }
                MultiEffect {
                    anchors.fill: iconImage
                    source: iconImage
                    colorization: 1.0
                    colorizationColor: parent.iconColor
                    Behavior on colorizationColor { ColorAnimation { duration: 120 } }
                }
            }
            Label {
                text: btn.label
                color: !btn.enabled ? HMI.Theme.sub : (btn.highlighted ? "#FFFFFF" : HMI.Theme.text)
                font.pixelSize: HMI.Theme.px(12)
                font.bold: btn.highlighted
                Layout.alignment: Qt.AlignHCenter
                visible: btn.label.length > 0
            }
        }

        MouseArea {
            id: mouse
            anchors.fill: parent
            enabled: btn.enabled
            cursorShape: btn.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onPressed: { }
            onClicked: if (btn.enabled) btn.clicked()
        }

        Behavior on color { ColorAnimation { duration: 120 } }
        Behavior on border.color { ColorAnimation { duration: 120 } }
        scale: mouse.pressed && btn.enabled ? 0.96 : 1.0
        Behavior on scale { NumberAnimation { duration: 90; easing.type: Easing.OutQuad } }
    }
}

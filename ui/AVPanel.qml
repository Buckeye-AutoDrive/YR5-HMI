// ui/AVPanel.qml – AV Actions (Engage / Disengage) + Data Monitor
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import HMI_Mk1 1.0 as HMI

Item {
    id: root
    property var rows: []   // same data as Data Monitor (telemetryModel from Main)

    signal disengageRequested()
    /// Fired when user taps Disengage (same moment as sendEngageCommand(0)) — before UI delay.
    signal disengageCommandSent()
    signal engageCommandSent()

    readonly property int m: HMI.Theme.px(2)
    readonly property int gap: HMI.Theme.px(8)
    readonly property int sectionHeaderHeight: HMI.Theme.px(30)
    // Same tile height as DestList (3-col equivalent)
    readonly property real tileHeight: Math.floor((avSection.width - 2*m - 2*gap) / 3)
    readonly property real tileWidth: Math.floor((avSection.width - 2*m - gap) / 2)
    readonly property real avSectionHeight: (tileHeight + 2*m) + HMI.Theme.px(6)  // sectionHeaderHeight commented out with AV Actions label

    ColumnLayout {
        anchors.fill: parent
        spacing: HMI.Theme.px(6)

        Item {
            id: avSection
            Layout.fillWidth: true
            Layout.preferredHeight: avSectionHeight

            Column {
                anchors.left: parent.left
                anchors.right: parent.right
                spacing: HMI.Theme.px(6)

                // Rectangle {
                //     anchors.left: parent.left
                //     anchors.right: parent.right
                //     height: root.sectionHeaderHeight
                //     radius: HMI.Theme.radius
                //     color: HMI.Theme.center
                //     border.color: HMI.Theme.outline
                //     Text {
                //         anchors.fill: parent
                //         anchors.margins: HMI.Theme.px(12)
                //         text: "AV Actions"
                //         color: HMI.Theme.text
                //         font.pixelSize: HMI.Theme.px(18)
                //         font.bold: false
                //         verticalAlignment: Text.AlignVCenter
                //         elide: Text.ElideRight
                //     }
                // }

                Row {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    spacing: gap
                    topPadding: m
                    bottomPadding: m

                    component ActionButton: Rectangle {
                        id: btn
                        property string labelText: ""
                        property color fillColor: HMI.Theme.surface
                        property color textColor: HMI.Theme.text
                        signal clicked()
                        width: tileWidth
                        height: tileHeight
                        radius: HMI.Theme.radius
                        color: fillColor
                        border.color: HMI.Theme.outline

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
                            text: btn.labelText
                            color: mouse.pressed ? Qt.rgba(1, 1, 1, 0.7) : btn.textColor
                            font.pixelSize: HMI.Theme.px(18)
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
                            onClicked: btn.clicked()
                        }
                        ParallelAnimation {
                            id: rippleAnim
                            NumberAnimation { target: ripple; property: "width"; from: 0; to: btn.width; duration: 220; easing.type: Easing.OutCubic }
                            NumberAnimation { target: ripple; property: "height"; from: 0; to: btn.height; duration: 220; easing.type: Easing.OutCubic }
                            SequentialAnimation {
                                NumberAnimation { target: ripple; property: "opacity"; from: 0.0; to: 0.10; duration: 90; easing.type: Easing.OutQuad }
                                NumberAnimation { target: ripple; property: "opacity"; from: 0.10; to: 0.0; duration: 160; easing.type: Easing.OutQuad }
                            }
                        }
                        scale: mouse.pressed ? 0.98 : 1.0
                        Behavior on scale { NumberAnimation { duration: 90; easing.type: Easing.OutQuad } }
                    }

                    ActionButton {
                        labelText: "Engage"
                        fillColor: "#2d5a27"
                        textColor: "#f0f0f0"
                        onClicked: {
                            if (GlobalTx)
                                GlobalTx.sendEngageCommand(1, "")
                            root.engageCommandSent()
                        }
                    }
                    ActionButton {
                        labelText: "Disengage"
                        fillColor: "#5a2727"
                        textColor: "#f0f0f0"
                        onClicked: {
                            if (GlobalTx)
                                GlobalTx.sendEngageCommand(0, "")
                            root.disengageCommandSent()
                            // Delay panel switch so TCP write flushes before UI changes
                            delaySwitchBack.start()
                        }
                    }
                }
                Timer {
                    id: delaySwitchBack
                    interval: 150
                    repeat: false
                    onTriggered: root.disengageRequested()
                }
            }
        }

        // Rectangle {
        //     Layout.fillWidth: true
        //     height: root.sectionHeaderHeight
        //     radius: HMI.Theme.radius
        //     color: HMI.Theme.center
        //     border.color: HMI.Theme.outline
        //     Text {
        //         anchors.fill: parent
        //         anchors.margins: HMI.Theme.px(12)
        //         text: "Data Monitor"
        //         color: HMI.Theme.text
        //         font.pixelSize: HMI.Theme.px(18)
        //         font.bold: false
        //         verticalAlignment: Text.AlignVCenter
        //         elide: Text.ElideRight
        //     }
        // }

        HMI.IntelLogsTable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: IntelLogsBackend ? IntelLogsBackend.model : null
        }
    }
}

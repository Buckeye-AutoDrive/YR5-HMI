import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import HMI_Mk1 1.0 as HMI

Item {
    id: root
    property var model: []
    property int currentIndex: 0
    signal activated(int index)

    Rectangle {
        anchors.fill: parent
        radius: HMI.Theme.radius
        color: HMI.Theme.surface
        border.color: HMI.Theme.outline
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: HMI.Theme.px(16)
        spacing: HMI.Theme.px(12)

        Label {
            text: "Menu"
            color: HMI.Theme.text
            font.pixelSize: HMI.Theme.px(32)
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            Layout.fillWidth: true
        }

        // Pure ListView – touch flick, no visible scrollbar
        ListView {
            id: list
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: root.model
            currentIndex: root.currentIndex
            spacing: HMI.Theme.px(10)
            boundsBehavior: Flickable.DragAndOvershootBounds
            flickDeceleration: 3000
            maximumFlickVelocity: 2500
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AlwaysOff }

            delegate: Rectangle {
                required property int index
                required property string modelData
                width: list.width
                implicitHeight: HMI.Theme.px(72)
                radius: HMI.Theme.px(14)
                color: list.currentIndex === index ? "#1E1E1E" : "#161616"
                border.color: list.currentIndex === index ? HMI.Theme.accent : HMI.Theme.outline
                border.width: list.currentIndex === index ? 2 : 1

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: HMI.Theme.px(18)
                    Label {
                        text: modelData
                        color: list.currentIndex === index ? HMI.Theme.text : HMI.Theme.sub
                        font.pixelSize: HMI.Theme.px(24)
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }
                    Label {
                        text: "›"
                        color: HMI.Theme.sub
                        font.pixelSize: HMI.Theme.px(26)
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: { list.currentIndex = index; root.currentIndex = index; root.activated(index) }
                }
            }
        }
    }
}

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Effects
import HMI_Mk1 1.0 as HMI

Item {
    Rectangle {
        anchors.fill: parent
        radius: HMI.Theme.radius
        color: "#0F0F0F"
        border.color: "#252525"
    }

    // simple placeholder look
    Text {
        anchors.centerIn: parent
        text: "Map view goes here"
        color: HMI.Theme.sub
        font.pixelSize: HMI.Theme.px(22)
    }
}

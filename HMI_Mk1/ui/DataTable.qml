import QtQuick 2.15
import QtQuick.Controls 2.15
import HMI_Mk1 1.0 as HMI

Item {
    id: root
    property var rows: []   // can be JS array or ListModel

    function colW(totalWidth, ratio) {
        const m = HMI.Theme.px(12), s = HMI.Theme.px(8);
        const avail = Math.max(0, totalWidth - 2*m - 2*s);
        return avail * ratio;
    }

    // header
    Rectangle {
        id: header
        anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
        height: HMI.Theme.px(44); radius: HMI.Theme.radius
        color: "#1A1A1A"; border.color: HMI.Theme.outline
        Row {
            anchors.fill: parent; anchors.margins: HMI.Theme.px(12); spacing: HMI.Theme.px(8)
            Label { text: "Source"; color: HMI.Theme.sub; font.pixelSize: HMI.Theme.px(18); width: colW(root.width, HMI.Theme.colSource) }
            Label { text: "ID";     color: HMI.Theme.sub; font.pixelSize: HMI.Theme.px(18); width: colW(root.width, HMI.Theme.colId);    horizontalAlignment: Text.AlignHCenter }
            Label { text: "Value";  color: HMI.Theme.sub; font.pixelSize: HMI.Theme.px(18); width: colW(root.width, HMI.Theme.colValue); horizontalAlignment: Text.AlignRight }
        }
    }

    // body
    ListView {
        id: table
        anchors.left: parent.left; anchors.right: parent.right
        anchors.top: header.bottom; anchors.bottom: parent.bottom
        model: root.rows
        spacing: HMI.Theme.px(6)
        clip: true
        boundsBehavior: Flickable.DragAndOvershootBounds
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AlwaysOff }

        delegate: Rectangle {
            width: table.width; height: HMI.Theme.px(52)
            radius: HMI.Theme.radius; color: "#171717"; border.color: HMI.Theme.outline
            readonly property bool lm: typeof modelData === "undefined" // true if ListModel

            Row {
                anchors.fill: parent; anchors.margins: HMI.Theme.px(12); spacing: HMI.Theme.px(8)

                Label {
                    text: lm ? (source || "–") : ((modelData && modelData.source) || "–")
                    color: HMI.Theme.text; font.pixelSize: HMI.Theme.px(18)
                    elide: Text.ElideRight; width: colW(table.width, HMI.Theme.colSource)
                }
                Label {
                    text: lm ? (id !== undefined && id !== "" ? id : "–") :
                               ((modelData && modelData.id !== undefined && modelData.id !== "") ? modelData.id : "–")
                    color: HMI.Theme.text; font.pixelSize: HMI.Theme.px(18)
                    width: colW(table.width, HMI.Theme.colId); horizontalAlignment: Text.AlignHCenter
                }
                Label {
                    text: {
                        var v = lm ? value : (modelData ? modelData.value : undefined);
                        var u = lm ? unit  : (modelData ? modelData.unit  : undefined);
                        if (v === undefined) return "–";
                        return u ? (v + " " + u) : ("" + v);
                    }
                    color: HMI.Theme.text; font.pixelSize: HMI.Theme.px(18); font.family: "monospace"
                    width: colW(table.width, HMI.Theme.colValue); horizontalAlignment: Text.AlignRight
                }
            }
        }
    }
}

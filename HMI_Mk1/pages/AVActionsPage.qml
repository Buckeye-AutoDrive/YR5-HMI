import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import HMI_Mk1 1.0 as HMI

Item {
    id: root
    Layout.fillWidth: true
    Layout.fillHeight: true

    // layout constants
    property int  cols: 4
    property real pad:  HMI.Theme.px(18)
    property real gap:  HMI.Theme.px(20)

    // GridView width = root.width - 2*pad
    // GridView uses cellWidth for EACH column, so:
    //   cols * (tileSize + gap) <= gridWidth
    // → tileSize = floor(gridWidth/cols - gap)
    readonly property real gridWidth: Math.max(0, root.width - 2*pad)
    property real tileSize: Math.max(1, Math.floor(gridWidth/cols - gap))

    // colors
    readonly property color colEnabled:  "#2ECC71"
    readonly property color colDisabled: HMI.Theme.accent
    readonly property color colCaution:  "#F1C40F"
    readonly property color colInactive: "#2F2F2F"
    readonly property color colDefault:  "#161616"
    readonly property color colOutline:  HMI.Theme.outline

    // auto-contrast (100% for title, ~80% for sub)
    function contrastColor(bg, factor) {
        function toLin(v) { return (v <= 0.03928) ? v/12.92 : Math.pow((v+0.055)/1.055, 2.4) }
        const L = 0.2126*toLin(bg.r) + 0.7152*toLin(bg.g) + 0.0722*toLin(bg.b)
        const base = (L > 0.5) ? Qt.rgba(0,0,0,1) : Qt.rgba(1,1,1,1)
        return Qt.rgba(base.r*factor, base.g*factor, base.b*factor, 1)
    }

    function lum(c) {
        function lin(v) { return v <= 0.03928 ? v/12.92 : Math.pow((v+0.055)/1.055, 2.4) }
        return 0.2126*lin(c.r) + 0.7152*lin(c.g) + 0.0722*lin(c.b)
    }
    function fullContrast(bg) {
        // pick black for light tiles, white for dark tiles
        return lum(bg) > 0.5 ? Qt.rgba(0,0,0,1) : Qt.rgba(1,1,1,1)
    }
    function mix(a, b, t) {  // linear blend a→b
        return Qt.rgba(a.r*(1-t)+b.r*t, a.g*(1-t)+b.g*t, a.b*(1-t)+b.b*t, 1)
    }
    function titleColorOf(bg) { return fullContrast(bg) }
    // 0.25 = move 25% toward bg (≈80–85% perceived contrast)
    function subColorOf(bg)  { return mix(fullContrast(bg), bg, 0.25) }

    function bgFor(status) {
        if (status === "enabled")  return colEnabled
        if (status === "disabled") return colDisabled
        if (status === "caution")  return colCaution
        if (status === "inactive") return colInactive
        return colDefault
    }

    // model
    ListModel {
        id: tileModel
        ListElement { title: "AV Mode"; sub: "Disengaged"; status: "disabled" }
        ListElement { title: "Button 2";  sub: "—"; status: "default" }
        ListElement { title: "Button 3";  sub: "—"; status: "default" }
        ListElement { title: "Button 4";  sub: "—"; status: "default" }
        ListElement { title: "Button 5";  sub: "—"; status: "default" }
        ListElement { title: "Button 6";  sub: "—"; status: "default" }
        ListElement { title: "Button 7";  sub: "—"; status: "default" }
        ListElement { title: "Button 8";  sub: "—"; status: "default" }
        ListElement { title: "Button 9";  sub: "—"; status: "default" }
        ListElement { title: "Button 10"; sub: "—"; status: "default" }
        ListElement { title: "Button 11"; sub: "—"; status: "default" }
        ListElement { title: "Button 12"; sub: "—"; status: "default" }
        ListElement { title: "Button 13"; sub: "—"; status: "default" }
        ListElement { title: "Button 14"; sub: "—"; status: "default" }
        ListElement { title: "Button 15"; sub: "—"; status: "default" }
        ListElement { title: "Button 16"; sub: "—"; status: "default" }
    }

    // grid (anchors because parent is Item)
    GridView {
        id: grid
        anchors.fill: parent
        anchors.margins: pad
        clip: true
        model: tileModel
        flow: GridView.FlowLeftToRight

        // 4-per-row
        cellWidth:  tileSize + gap
        cellHeight: tileSize + gap

        // flick like SideNav, but keep bar hidden
        boundsBehavior: Flickable.StopAtBounds
        Behavior on contentY { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
        interactive: true

        delegate: Item {
            required property string title
            required property string sub
            required property string status

            width: tileSize
            height: tileSize

            readonly property color bg: bgFor(status)
            readonly property bool  isInactive: status === "inactive"
            readonly property color titleColor: titleColorOf(bg)
            readonly property color subColor:   subColorOf(bg)
            readonly property color pressColor:  Qt.darker(bg, 1.25)

            Rectangle {
                id: card
                anchors.centerIn: parent
                width: parent.width
                height: parent.height
                radius: HMI.Theme.px(22)
                color: bg
                border.color: colOutline
                border.width: 4
                opacity: isInactive ? 0.55 : 1

                Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
                Behavior on color { ColorAnimation { duration: 120; easing.type: Easing.OutQuad } }

                Column {
                    anchors.centerIn: parent
                    spacing: HMI.Theme.px(6)
                    width: parent.width - HMI.Theme.px(32)

                    Label {
                        width: parent.width
                        text: title
                        color: titleColor
                        font.pixelSize: HMI.Theme.px(24)
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                    }
                    Label {
                        width: parent.width
                        text: sub
                        color: subColor
                        font.pixelSize: HMI.Theme.px(16)
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: !isInactive
                    preventStealing: true

                    onPressed: {
                        // keep your press animation
                        card.scale = 0.94
                        card.color = pressColor

                        // ensure the tapped tile is fully visible with minimal movement
                        grid.positionViewAtIndex(index, GridView.Visible)   // or GridView.Contain
                        // (Visible = scroll just enough; Contain = keep whole item inside view)
                    }

                    onReleased: { card.scale = 1.0; card.color = bg }
                    onCanceled: { card.scale = 1.0; card.color = bg }
                }
            }
        }
    }
}

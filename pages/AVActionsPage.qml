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

    readonly property real gridWidth: Math.max(0, root.width - 2 * pad)
    property real tileSize: Math.max(1, Math.floor(gridWidth / cols - gap))

    // TX connection status from GlobalTransmitter (context property "GlobalTx")
    property bool txConnected: GlobalTx && GlobalTx.hmiConnected

    // AV Mode engagement state and pending toggle
    property bool avEngaged: false
    property bool avPending: false
    property bool avTargetEngaged: false

    // colors
    readonly property color colEnabled:  "#3AC644"
    readonly property color colDisabled: HMI.Theme.accent
    readonly property color colCaution:  "#F1C40F"
    readonly property color colInactive: "#2F2F2F"
    readonly property color colDefault:  "#161616"
    readonly property color colOutline:  HMI.Theme.outline

    // luminance + contrast helpers
    function lum(c) {
        function lin(v) { return v <= 0.03928 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4) }
        return 0.2126 * lin(c.r) + 0.7152 * lin(c.g) + 0.0722 * lin(c.b)
    }

    function fullContrast(bg) {
        return lum(bg) > 0.5 ? Qt.rgba(0, 0, 0, 1) : Qt.rgba(1, 1, 1, 1)
    }

    function mix(a, b, t) {
        return Qt.rgba(
            a.r + (b.r - a.r) * t,
            a.g + (b.g - a.g) * t,
            a.b + (b.b - a.b) * t,
            1
        )
    }

    function titleColorOf(bg) {
        return fullContrast(bg)
    }

    function subColorOf(bg) {
        return mix(fullContrast(bg), Qt.rgba(0.7, 0.7, 0.7, 1), 0.2)
    }

    function bgFor(status) {
        if (status === "enabled")  return colEnabled
        if (status === "disabled") return colDisabled
        if (status === "caution")  return colCaution
        if (status === "inactive") return colInactive
        return colDefault
    }

    // AV Mode tile dynamic behavior:
    //
    //  - Not connected:          "N/A"          / "inactive"
    //  - Connected, disengaged:  "Disengaged"   / "disabled"
    //  - Connected, engaged:     "Engaged"      / "enabled"
    //  - Pending toggle (2s):    "Engaging..." or "Disengaging..." / "caution"
    function avModeSub() {
        if (!txConnected)
            return "N/A"
        if (avPending)
            return avTargetEngaged ? "Engaging..." : "Disengaging..."
        return avEngaged ? "Engaged" : "Disengaged"
    }

    function avModeStatus() {
        if (!txConnected)
            return "inactive"
        if (avPending)
            return "caution"
        return avEngaged ? "enabled" : "disabled"
    }

    // model
    ListModel {
        id: tileModel
        // AV Mode tile (index 0) – dynamic contents from avModeSub/avModeStatus
        ListElement { title: "AV Mode"; sub: "Engaged"; status: "enabled" }

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

    // 2s delay before AV Mode state visually flips
    Timer {
        id: avToggleTimer
        interval: 2000
        repeat: false
        running: false
        onTriggered: {
            avEngaged = avTargetEngaged
            avPending = false
        }
    }

    GridView {
        id: grid
        anchors.fill: parent
        anchors.margins: pad
        clip: true
        model: tileModel
        flow: GridView.FlowLeftToRight

        cellWidth:  tileSize + gap
        cellHeight: tileSize + gap

        flickableDirection: Flickable.VerticalFlick
        boundsBehavior: Flickable.StopAtBounds
        Behavior on contentY { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
        interactive: true

        delegate: Item {
            required property string title
            required property string sub
            required property string status
            required property int index

            width: tileSize
            height: tileSize

            readonly property bool  isAvMode: title === "AV Mode"

            // Effective status / sub for AV Mode depend on connection + state;
            // others use model values directly.
            readonly property string effSub:    isAvMode ? root.avModeSub()    : sub
            readonly property string effStatus: isAvMode ? root.avModeStatus() : status

            readonly property color bg: bgFor(effStatus)
            readonly property bool  isInactive: effStatus === "inactive"

            readonly property color pressColor: mix(bg, Qt.rgba(0, 0, 0, 1), 0.18)

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
                        color: titleColorOf(bg)
                        font.pixelSize: HMI.Theme.px(22)
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                    }

                    Label {
                        width: parent.width
                        text: effSub
                        color: subColorOf(bg)
                        font.pixelSize: HMI.Theme.px(16)
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                    }
                }

                MouseArea {
                    id: mouse
                    anchors.fill: parent
                    enabled: !isInactive && !(isAvMode && root.avPending)
                    acceptedButtons: Qt.LeftButton
                    hoverEnabled: false

                    // gesture filtering to avoid accidental taps while scrolling
                    property real tapThreshold: HMI.Theme.px(10)
                    property bool moved: false
                    property real pressX: 0
                    property real pressY: 0

                    onPressed: {
                        moved = false
                        pressX = mouse.x
                        pressY = mouse.y
                        card.scale = 0.94
                        card.color = pressColor
                    }

                    onPositionChanged: {
                        if (moved)
                            return

                        var dx = mouse.x - pressX
                        var dy = mouse.y - pressY
                        if (Math.abs(dx) > tapThreshold || Math.abs(dy) > tapThreshold) {
                            moved = true
                            card.scale = 1.0
                            card.color = bg
                        }
                    }

                    onReleased: {
                        card.scale = 1.0
                        card.color = bg

                        // Ignore if we detected a scroll gesture
                        if (moved || isInactive)
                            return

                        grid.positionViewAtIndex(index, GridView.Visible)

                        if (isAvMode) {
                            if (txConnected && GlobalTx && !root.avPending) {
                                // Toggle target engagement state
                                var wantEngage = !root.avEngaged
                                root.avTargetEngaged = wantEngage
                                root.avPending = true

                                if (wantEngage) {
                                    // Engage
                                    GlobalTx.sendEngageCommand(1, "")
                                } else {
                                    // Disengage
                                    GlobalTx.sendEngageCommand(0, "")
                                }

                                avToggleTimer.restart()
                            }
                            return
                        }

                        // Other tiles: hook up later as needed.
                    }

                    onCanceled: {
                        moved = false
                        card.scale = 1.0
                        card.color = bg
                    }
                }
            }
        }
    }
}

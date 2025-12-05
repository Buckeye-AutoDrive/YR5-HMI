// pages/AVWarnPage.qml
import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import HMI_Mk1 1.0 as HMI

Item {
    id: root
    anchors.fill: parent
    visible: false
    z: 1000   // above everything

    // Point ID like "K", "i6", ...
    property string pointLabel: ""

    // Same logic as in AVActionsPage
    property bool txConnected: GlobalTx && GlobalTx.hmiConnected

    // If true we only show the error message + OK
    property bool errorMode: false

    signal accepted()
    signal dismissed()

    function openForDestination(point) {
        pointLabel = point
        errorMode = !(GlobalTx && GlobalTx.hmiConnected)
        resetSlider()
        visible = true
    }

    // For AVActions etc.
    function openConnectionError() {
        pointLabel = ""
        errorMode = true
        resetSlider()
        visible = true
    }

    function closePage() {
        visible = false
    }

    function resetSlider() {
        sliderKnob.x = sliderTrack.knobMinX
    }

    function performEngage() {
        if (!(GlobalTx && GlobalTx.hmiConnected)) {
            // Connection dropped while user was sliding
            errorMode = true
            return
        }

        console.log("AVWarnPage: sending engage for point", pointLabel)
        if (GlobalTx && GlobalTx.sendEngageCommand) {
            GlobalTx.sendEngageCommand(1, pointLabel)
        }
        accepted()
        closePage()
    }

    // --------------------------------------------------------------
    // Dim background + block interaction underneath
    // --------------------------------------------------------------
    Rectangle {
        id: scrim
        anchors.fill: parent
        color: "#000000"
        opacity: 0.8    // darker
    }

    // Eats all input so the HMI behind is not interactable
    MouseArea {
        anchors.fill: parent
        enabled: root.visible
        hoverEnabled: true
        preventStealing: true
        propagateComposedEvents: false
        z: 0
        onClicked: {}
        onPressed: {}
        onReleased: {}
        onWheel: wheel.accepted = true
    }

    // "< Back" in top-left
    Text {
        id: backLabel
        text: "\u2039 Back"
        color: "#ffffff"
        font.pixelSize: HMI.Theme.px(26)
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.leftMargin: HMI.Theme.px(24)
        anchors.topMargin: HMI.Theme.px(20)
        z: 2
    }

    MouseArea {
        anchors.fill: backLabel
        cursorShape: Qt.PointingHandCursor
        z: 2
        onClicked: {
            dismissed()
            closePage()
        }
    }

    // --------------------------------------------------------------
    // Compact central card
    // --------------------------------------------------------------
    Rectangle {
        id: card
        width: Math.min(parent.width * 0.45, 680)
        height: Math.min(parent.height * 0.60, 720)
        radius: HMI.Theme.radius * 2
        color: "#181818"
        border.color: HMI.Theme.outline
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        z: 1

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: HMI.Theme.px(32)
            spacing: HMI.Theme.px(20)

            // Title
            Label {
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: HMI.Theme.px(26)
                font.bold: true
                color: HMI.Theme.text
                text: errorMode
                      ? "Connection not established"
                      : "Are you sure you want to engage autonomy\nand proceed to point:"
            }

            // Point label (K, i6, …)
            Label {
                visible: !errorMode
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: HMI.Theme.px(30)
                font.bold: true
                color: HMI.Theme.accent
                text: pointLabel
            }

            // Error text
            Label {
                visible: errorMode
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: HMI.Theme.px(22)
                color: HMI.Theme.sub
                text: "Intel connection is not established,\n" +
                      "cannot change AV state."
            }

            Item { Layout.preferredHeight: HMI.Theme.px(20) }


            // ------------------ Slider (engage mode) ------------------
            Item {
                id: sliderArea
                visible: !errorMode
                Layout.fillWidth: true
                Layout.preferredHeight: HMI.Theme.px(72)

                Rectangle {
                    id: sliderTrack
                    anchors.fill: parent
                    radius: height / 2
                    border.color: "#4a4a4a"
                    border.width: 1

                    // Scarlet gradient
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: "#7A0019" }
                        GradientStop { position: 1.0; color: "#BB0000" }
                    }

                    property real knobMinX: HMI.Theme.px(4)
                    property real knobMaxX: width - sliderKnob.width - HMI.Theme.px(4)

                    property real progress: (sliderKnob.x - knobMinX) /
                                            Math.max(1, knobMaxX - knobMinX)

                    Text {
                        anchors.centerIn: parent
                        text: "slide to engage"
                        font.pixelSize: HMI.Theme.px(22)
                        color: "#FFFFFFDD"
                        opacity: 0.4 + 0.6 * (1.0 - sliderTrack.progress)
                    }

                    Rectangle {
                        id: sliderKnob
                        width: parent.height - HMI.Theme.px(10)
                        height: width
                        radius: width / 2
                        anchors.verticalCenter: parent.verticalCenter
                        x: sliderTrack.knobMinX
                        color: "#ffffff"
                        border.color: "#dddddd"
                        antialiasing: true

                        Behavior on x {
                            NumberAnimation {
                                duration: 160
                                easing.type: Easing.OutCubic
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "\u27A4"
                            color: "#BB0000"
                            font.pixelSize: HMI.Theme.px(26)
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            drag.target: sliderKnob
                            drag.axis: Drag.XAxis
                            drag.minimumX: sliderTrack.knobMinX
                            drag.maximumX: sliderTrack.knobMaxX

                            onReleased: {
                                if (sliderTrack.progress > 0.96) {
                                    root.performEngage()
                                } else {
                                    sliderKnob.x = sliderTrack.knobMinX
                                }
                            }
                        }
                    }
                }
            }

            Button {
                id: okButton

                visible: errorMode      // <<<<<< ONLY show in error mode

                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: HMI.Theme.px(180)
                Layout.preferredHeight: HMI.Theme.px(60)

                text: "OK"
                font.pixelSize: HMI.Theme.px(22)
                hoverEnabled: false

                background: Rectangle {
                    radius: height / 2
                    color: HMI.Theme.accent
                    border.color: Qt.darker(HMI.Theme.accent, 1.3)
                }

                contentItem: Text {
                    text: okButton.text
                    font: okButton.font
                    color: "white"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                onClicked: {
                    dismissed()
                    closePage()
                }
            }



        }
    }
}

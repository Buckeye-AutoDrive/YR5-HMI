import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import HMI_Mk1 1.0 as HMI

Item {
    id: root
    Layout.fillWidth: true
    Layout.fillHeight: true

    Rectangle {
        anchors.fill: parent
        radius: HMI.Theme.radius
        color: HMI.Theme.center
        border.color: HMI.Theme.outline
        border.width: 1
        clip: true

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: HMI.Theme.px(16)
            spacing: HMI.Theme.px(12)

            // Terminal display (GNOME-like)
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: HMI.Theme.px(18)
                color: "#0C0C0C"
                border.color: HMI.Theme.outline
                border.width: 1
                clip: true

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: HMI.Theme.px(12)
                    spacing: HMI.Theme.px(8)

                    Flickable {
                        id: terminalFlick
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        contentWidth: terminalText.paintedWidth
                        contentHeight: terminalText.paintedHeight
                        clip: true
                        boundsBehavior: Flickable.DragAndOvershootBounds
                        flickDeceleration: 3000
                        maximumFlickVelocity: 2500

                        Text {
                            id: terminalText
                            width: terminalFlick.width
                            text: typeof TerminalBackend !== "undefined" ? TerminalBackend.output : ""
                            color: "#E6E6E6"
                            font.pixelSize: HMI.Theme.px(16)
                            font.family: "monospace"
                            wrapMode: Text.Wrap
                            onTextChanged: {
                                terminalFlick.contentY = Math.max(0, terminalFlick.contentHeight - terminalFlick.height)
                            }
                        }

                        // Tap output area to focus input without blocking flick
                        MouseArea {
                            anchors.fill: parent
                            onPressed: {
                                terminalInput.forceActiveFocus()
                                mouse.accepted = false
                            }
                        }
                    }

                    // Input line
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: HMI.Theme.px(28)
                        spacing: HMI.Theme.px(6)

                        Label {
                            text: "›"
                            color: "#E6E6E6"
                            font.pixelSize: HMI.Theme.px(16)
                            font.family: "monospace"
                            Layout.alignment: Qt.AlignVCenter
                        }

                        TextField {
                            id: terminalInput
                            Layout.fillWidth: true
                            placeholderText: "type a command..."
                            color: "#E6E6E6"
                            placeholderTextColor: "#808080"
                            font.pixelSize: HMI.Theme.px(16)
                            font.family: "monospace"
                            background: Rectangle { color: "transparent" }
                            onAccepted: {
                                if (TerminalBackend && text.trim().length > 0)
                                    TerminalBackend.sendCommand(text)
                                text = ""
                                forceActiveFocus()
                            }
                        }
                    }

                }
            }

            // Bottom action buttons (first 4 from settings, then Clear / ctrl+c / enter)
            Item {
                id: terminalBar
                Layout.fillWidth: true
                Layout.preferredHeight: HMI.Theme.px(52)

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: HMI.Theme.px(4)
                    spacing: HMI.Theme.px(8)

                    TerminalActionButton {
                        label: typeof SettingsBackend !== "undefined" ? SettingsBackend.terminalButton1Label : "ipconfig"
                        onClicked: {
                            if (!TerminalBackend) return
                            var cmd = typeof SettingsBackend !== "undefined" ? SettingsBackend.terminalButton1Command : "ifconfig"
                            TerminalBackend.sendCommand(cmd)
                        }
                    }
                    TerminalActionButton {
                        label: typeof SettingsBackend !== "undefined" ? SettingsBackend.terminalButton2Label : "ssh intel"
                        onClicked: {
                            if (!TerminalBackend) return
                            var cmd = typeof SettingsBackend !== "undefined" ? SettingsBackend.terminalButton2Command : "ssh autodrive@192.168.69.10"
                            if (cmd.indexOf("ssh autodrive@192.168.69.10") !== -1)
                                TerminalBackend.runSshIntel()
                            else
                                TerminalBackend.sendCommand(cmd)
                        }
                    }
                    TerminalActionButton {
                        label: typeof SettingsBackend !== "undefined" ? SettingsBackend.terminalButton3Label : "top"
                        onClicked: {
                            if (!TerminalBackend) return
                            var cmd = typeof SettingsBackend !== "undefined" ? SettingsBackend.terminalButton3Command : "top"
                            TerminalBackend.sendCommand(cmd)
                        }
                    }
                    TerminalActionButton {
                        label: typeof SettingsBackend !== "undefined" ? SettingsBackend.terminalButton4Label : "ls"
                        onClicked: {
                            if (!TerminalBackend) return
                            var cmd = typeof SettingsBackend !== "undefined" ? SettingsBackend.terminalButton4Command : "ls"
                            TerminalBackend.sendCommand(cmd)
                        }
                    }
                    TerminalActionButton {
                        label: "clear"
                        onClicked: if (TerminalBackend) TerminalBackend.clearOutput()
                    }
                    TerminalActionButton {
                        label: "ctrl+c"
                        onClicked: if (TerminalBackend) TerminalBackend.sendCtrlC()
                    }
                    TerminalActionButton {
                        label: "enter"
                        onClicked: if (TerminalBackend) TerminalBackend.sendEnter()
                    }
                }
            }
        }
    }

    component TerminalActionButton: Rectangle {
        id: btn
        property string label: ""
        property bool pressed: false
        signal clicked()

        Layout.fillWidth: true
        Layout.fillHeight: true
        radius: HMI.Theme.px(18)
        readonly property color baseBg: HMI.Theme.surface
        color: pressed ? Qt.darker(baseBg, 1.25) : baseBg
        border.color: HMI.Theme.outline
        border.width: 1
        opacity: 0.98
        scale: pressed ? 0.94 : 1.0
        Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
        Behavior on color { ColorAnimation { duration: 120; easing.type: Easing.OutQuad } }

        Label {
            anchors.centerIn: parent
            text: btn.label
            color: HMI.Theme.text
            font.pixelSize: HMI.Theme.px(15)
            font.bold: true
            elide: Text.ElideRight
        }

        MouseArea {
            anchors.fill: parent
            onPressed: btn.pressed = true
            onCanceled: btn.pressed = false
            onReleased: {
                btn.pressed = false
                btn.clicked()
            }
        }
    }
}

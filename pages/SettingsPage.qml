import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import HMI_Mk1 1.0 as HMI

Item {
    id: root
    Layout.fillWidth: true
    Layout.fillHeight: true

    property var settings: SettingsBackend  // Context property from main.cpp

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

            // Network Settings Section
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: networkColumn.implicitHeight + HMI.Theme.px(32)
                radius: HMI.Theme.px(18)
                color: HMI.Theme.center
                border.color: HMI.Theme.outline
                border.width: 1

                ColumnLayout {
                    id: networkColumn
                    anchors.fill: parent
                    anchors.margins: HMI.Theme.px(16)
                    spacing: HMI.Theme.px(10)

                    Label {
                        text: "Network Settings"
                        color: HMI.Theme.text
                        font.pixelSize: HMI.Theme.px(24)
                        font.bold: true
                        Layout.fillWidth: true
                    }

                    SettingRow {
                        label: "TX Host"
                        value: settings.txHost
                        onValueEdited: (value) => { settings.txHost = value }
                    }

                    SettingRow {
                        label: "TX Port"
                        value: String(settings.txPort)
                        onValueEdited: (value) => {
                            var port = parseInt(value)
                            if (!isNaN(port)) settings.txPort = port
                        }
                        inputType: "number"
                        minValue: 1
                        maxValue: 65535
                    }

                    SettingRow {
                        label: "RX Port"
                        value: String(settings.rxPort)
                        onValueEdited: (value) => {
                            var port = parseInt(value)
                            if (!isNaN(port)) settings.rxPort = port
                        }
                        inputType: "number"
                        minValue: 1
                        maxValue: 65535
                        note: "Requires app restart to take effect"
                    }

                    SettingRow {
                        label: "GNSS Timeout (ms)"
                        value: String(settings.gnssTimeout)
                        onValueEdited: (value) => {
                            var timeout = parseInt(value)
                            if (!isNaN(timeout)) settings.gnssTimeout = timeout
                        }
                        inputType: "number"
                        minValue: 100
                        maxValue: 10000
                    }
                }
            }

            // Map Settings Section
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: mapColumn.implicitHeight + HMI.Theme.px(32)
                radius: HMI.Theme.px(18)
                color: HMI.Theme.center
                border.color: HMI.Theme.outline
                border.width: 1

                ColumnLayout {
                    id: mapColumn
                    anchors.fill: parent
                    anchors.margins: HMI.Theme.px(16)
                    spacing: HMI.Theme.px(10)

                    Label {
                        text: "Map Settings"
                        color: HMI.Theme.text
                        font.pixelSize: HMI.Theme.px(24)
                        font.bold: true
                        Layout.fillWidth: true
                    }

                    SettingRow {
                        label: "Default Zoom Level"
                        value: String(settings.defaultZoom)
                        onValueEdited: (value) => {
                            var zoom = parseInt(value)
                            if (!isNaN(zoom)) settings.defaultZoom = zoom
                        }
                        inputType: "number"
                        minValue: 1
                        maxValue: 20
                    }

                    SettingRow {
                        label: "Follow Vehicle"
                        value: settings.followVehicle ? "true" : "false"
                        onValueEdited: (value) => { settings.followVehicle = (value === "true") }
                        inputType: "toggle"
                    }
                }
            }

            // Theme Settings Section
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: themeColumn.implicitHeight + HMI.Theme.px(32)
                radius: HMI.Theme.px(18)
                color: HMI.Theme.center
                border.color: HMI.Theme.outline
                border.width: 1

                ColumnLayout {
                    id: themeColumn
                    anchors.fill: parent
                    anchors.margins: HMI.Theme.px(16)
                    spacing: HMI.Theme.px(10)

                    Label {
                        text: "Theme"
                        color: HMI.Theme.text
                        font.pixelSize: HMI.Theme.px(24)
                        font.bold: true
                        Layout.fillWidth: true
                    }

                    SettingRow {
                        label: "Dark theme"
                        value: settings.themeDark ? "true" : "false"
                        onValueEdited: (value) => { settings.themeDark = (value === "true") }
                        inputType: "toggle"
                        note: "Map and camera feeds stay unchanged"
                    }
                }
            }

            // Camera Settings Section
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: cameraColumn.implicitHeight + HMI.Theme.px(32)
                radius: HMI.Theme.px(18)
                color: HMI.Theme.center
                border.color: HMI.Theme.outline
                border.width: 1

                ColumnLayout {
                    id: cameraColumn
                    anchors.fill: parent
                    anchors.margins: HMI.Theme.px(16)
                    spacing: HMI.Theme.px(10)

                    Label {
                        text: "Camera Settings"
                        color: HMI.Theme.text
                        font.pixelSize: HMI.Theme.px(24)
                        font.bold: true
                        Layout.fillWidth: true
                    }

                    SettingRow {
                        label: "Left Camera URL"
                        value: settings.leftCameraUrl
                        onValueEdited: (value) => { settings.leftCameraUrl = value }
                    }

                    SettingRow {
                        label: "Center Camera URL"
                        value: settings.centerCameraUrl
                        onValueEdited: (value) => { settings.centerCameraUrl = value }
                    }

                    SettingRow {
                        label: "Bumper Camera URL"
                        value: settings.bumperCameraUrl
                        onValueEdited: (value) => { settings.bumperCameraUrl = value }
                    }

                    SettingRow {
                        label: "Right Camera URL"
                        value: settings.rightCameraUrl
                        onValueEdited: (value) => { settings.rightCameraUrl = value }
                    }
                }
            }

            // Action Buttons
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: HMI.Theme.px(10)
                spacing: HMI.Theme.px(12)

                SettingsButton {
                    Layout.fillWidth: true
                    Layout.preferredHeight: HMI.Theme.px(50)
                    label: "Save"
                    isAccent: true
                    onClicked: {
                        if (settings.validateSettings()) {
                            settings.saveSettings()
                            statusLabel.text = "Settings saved successfully"
                            statusLabel.color = "#33D17A"
                        } else {
                            statusLabel.text = "Validation failed. Please check your inputs."
                            statusLabel.color = "#FF4D4D"
                        }
                    }
                }

                SettingsButton {
                    Layout.fillWidth: true
                    Layout.preferredHeight: HMI.Theme.px(50)
                    label: "Reset to Defaults"
                    isAccent: false
                    onClicked: {
                        settings.resetToDefaults()
                        statusLabel.text = "Settings reset to defaults"
                        statusLabel.color = HMI.Theme.sub
                    }
                }

                SettingsButton {
                    Layout.fillWidth: true
                    Layout.preferredHeight: HMI.Theme.px(50)
                    label: "Cancel"
                    isAccent: false
                    onClicked: {
                        settings.loadSettings()
                        statusLabel.text = "Changes discarded"
                        statusLabel.color = HMI.Theme.sub
                    }
                }
            }

            // Status Label
            Label {
                id: statusLabel
                Layout.fillWidth: true
                Layout.preferredHeight: HMI.Theme.px(30)
                text: ""
                color: HMI.Theme.sub
                font.pixelSize: HMI.Theme.px(16)
                horizontalAlignment: Text.AlignHCenter
                visible: text !== ""
            }
        }
    }

    // Button without default hover (avoids solid white box on hover)
    component SettingsButton : Rectangle {
        id: btn
        radius: HMI.Theme.px(18)
        property string label: ""
        property bool isAccent: false
        signal clicked()
        property bool pressed: false
        color: pressed
             ? (isAccent ? Qt.darker(HMI.Theme.accent, 1.15) : Qt.darker(HMI.Theme.center, 1.12))
             : (isAccent ? HMI.Theme.accent : HMI.Theme.center)
        border.color: HMI.Theme.outline
        border.width: 1
        Behavior on color { ColorAnimation { duration: 100 } }
        scale: pressed ? 0.98 : 1.0
        Behavior on scale { NumberAnimation { duration: 80 } }
        Label {
            anchors.centerIn: parent
            text: btn.label
            color: HMI.Theme.text
            font.pixelSize: HMI.Theme.px(20)
            font.bold: true
        }
        MouseArea {
            anchors.fill: parent
            onPressed: btn.pressed = true
            onCanceled: btn.pressed = false
            onReleased: {
                btn.pressed = false
                if (containsMouse) btn.clicked()
            }
        }
    }

    // Reusable SettingRow component
    component SettingRow : RowLayout {
        id: settingRow
        Layout.fillWidth: true
        Layout.preferredHeight: HMI.Theme.px(44)
        spacing: HMI.Theme.px(12)

        property string label: ""
        property string value: ""
        property string inputType: "text"
        property int minValue: 0
        property int maxValue: 100
        property string note: ""

        signal valueEdited(string value)

        Label {
            Layout.preferredWidth: HMI.Theme.px(200)
            Layout.minimumWidth: HMI.Theme.px(160)
            clip: true
            text: settingRow.label
            color: HMI.Theme.text
            font.pixelSize: HMI.Theme.px(18)
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: HMI.Theme.px(42)
            Layout.minimumWidth: HMI.Theme.px(100)
            Layout.leftMargin: HMI.Theme.px(8)

            TextField {
                id: textInput
                anchors.fill: parent
                visible: settingRow.inputType === "text" || settingRow.inputType === "number"
                text: settingRow.value
                color: HMI.Theme.text
                font.pixelSize: HMI.Theme.px(19)
                verticalAlignment: Text.AlignVCenter
                leftPadding: HMI.Theme.px(12)
                rightPadding: HMI.Theme.px(12)
                topPadding: HMI.Theme.px(8)
                bottomPadding: HMI.Theme.px(8)
                background: Rectangle {
                    radius: HMI.Theme.px(10)
                    color: HMI.Theme.surface
                    border.color: textInput.activeFocus ? HMI.Theme.accent : HMI.Theme.outline
                    border.width: textInput.activeFocus ? 2 : 1
                }
                selectByMouse: true
                onTextChanged: {
                    if (settingRow.inputType === "number") {
                        var num = parseInt(text)
                        if (!isNaN(num)) {
                            if (num < settingRow.minValue) text = String(settingRow.minValue)
                            if (num > settingRow.maxValue) text = String(settingRow.maxValue)
                        }
                    }
                    settingRow.valueEdited(text)
                }
                onEditingFinished: {
                    settingRow.valueEdited(text)
                }
            }

            // Custom toggle (avoids style customization warning)
            Item {
                id: toggleInput
                anchors.fill: parent
                visible: settingRow.inputType === "toggle"
                property bool checked: settingRow.value === "true"
                Rectangle {
                    width: HMI.Theme.px(52)
                    height: HMI.Theme.px(28)
                    radius: height / 2
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: parent.right
                    color: toggleInput.checked ? HMI.Theme.accent : HMI.Theme.center
                    border.color: HMI.Theme.outline
                    border.width: 1
                    Rectangle {
                        width: parent.height - 4
                        height: width
                        radius: width / 2
                        anchors.verticalCenter: parent.verticalCenter
                        x: toggleInput.checked ? parent.width - width - 2 : 2
                        color: HMI.Theme.text
                        Behavior on x { NumberAnimation { duration: 120 } }
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        var next = !(settingRow.value === "true")
                        settingRow.valueEdited(next ? "true" : "false")
                    }
                }
            }
        }

        Label {
            Layout.preferredWidth: settingRow.note !== "" ? HMI.Theme.px(200) : 0
            Layout.maximumWidth: HMI.Theme.px(220)
            text: settingRow.note
            color: HMI.Theme.sub
            font.pixelSize: HMI.Theme.px(14)
            visible: settingRow.note !== ""
            wrapMode: Text.Wrap
        }
    }

    Connections {
        target: settings
        function onSettingsError(error) {
            statusLabel.text = error
            statusLabel.color = "#FF4D4D"
        }
        function onSettingsSaved() {
            statusLabel.text = "Settings saved successfully"
            statusLabel.color = "#33D17A"
        }
    }
}

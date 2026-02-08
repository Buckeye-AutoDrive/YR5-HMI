import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import HMI_Mk1 1.0 as HMI

Item {
    id: root
    Layout.fillWidth: true
    Layout.fillHeight: true

    property var settings: SettingsBackend  // Context property from main.cpp
    property string backupOutcome: ""
    property string backupButtonDisplayText: {
        if (LogBackupBackend && LogBackupBackend.backupInProgress) return "Uploading..."
        if (backupOutcome === "success") return "Uploaded!"
        if (backupOutcome === "failure") return "Failed."
        return "Backup"
    }

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
                        label: "Intel IP"
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
                        note: "Controls stream. Save and restart to apply."
                    }

                    SettingRow {
                        label: "RX Port (Perception)"
                        value: String(settings.rxPortPerception)
                        onValueEdited: (value) => {
                            var port = parseInt(value)
                            if (!isNaN(port)) settings.rxPortPerception = port
                        }
                        inputType: "number"
                        minValue: 1
                        maxValue: 65535
                        note: "TX not ready; not started by default"
                    }

                    SettingRow {
                        label: "RX Port (Logger)"
                        value: String(settings.rxPortLogger)
                        onValueEdited: (value) => {
                            var port = parseInt(value)
                            if (!isNaN(port)) settings.rxPortLogger = port
                        }
                        inputType: "number"
                        minValue: 1
                        maxValue: 65535
                        note: "CAN batch stream. Save and restart to apply."
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

            // Data Logger Settings (WebDAV backup)
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: dataLoggerColumn.implicitHeight + HMI.Theme.px(32)
                radius: HMI.Theme.px(18)
                color: HMI.Theme.center
                border.color: HMI.Theme.outline
                border.width: 1

                ColumnLayout {
                    id: dataLoggerColumn
                    anchors.fill: parent
                    anchors.margins: HMI.Theme.px(16)
                    spacing: HMI.Theme.px(10)

                    Label {
                        text: "Data Logger Settings"
                        color: HMI.Theme.text
                        font.pixelSize: HMI.Theme.px(24)
                        font.bold: true
                        Layout.fillWidth: true
                    }

                    SettingRow {
                        label: "Auto backup logs"
                        value: settings.autoBackupLogs ? "true" : "false"
                        onValueEdited: (value) => { settings.autoBackupLogs = (value === "true") }
                        inputType: "toggle"
                        note: "Automatically back up logs to the server when enabled"
                    }

                    SettingRow {
                        label: "WebDAV server"
                        value: settings.webdavServerUrl
                        onValueEdited: (value) => { settings.webdavServerUrl = value }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: HMI.Theme.px(44)
                        spacing: HMI.Theme.px(12)
                        Label {
                            Layout.preferredWidth: HMI.Theme.px(200)
                            Layout.minimumWidth: HMI.Theme.px(160)
                            text: "WebDAV credentials"
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
                            RowLayout {
                                anchors.fill: parent
                                spacing: HMI.Theme.px(8)
                                TextField {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: HMI.Theme.px(42)
                                    text: settings.webdavUsername
                                    placeholderText: "Username"
                                    placeholderTextColor: HMI.Theme.sub
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
                                        border.color: parent.activeFocus ? HMI.Theme.accent : HMI.Theme.outline
                                        border.width: parent.activeFocus ? 2 : 1
                                    }
                                    onEditingFinished: settings.webdavUsername = text
                                }
                                TextField {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: HMI.Theme.px(42)
                                    text: settings.webdavPassword
                                    placeholderText: "Password"
                                    placeholderTextColor: HMI.Theme.sub
                                    echoMode: TextInput.Password
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
                                        border.color: parent.activeFocus ? HMI.Theme.accent : HMI.Theme.outline
                                        border.width: parent.activeFocus ? 2 : 1
                                    }
                                    onEditingFinished: settings.webdavPassword = text
                                }
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: HMI.Theme.px(44)
                        spacing: HMI.Theme.px(10)
                        Label {
                            text: "Back up logs now"
                            color: HMI.Theme.text
                            font.pixelSize: HMI.Theme.px(18)
                            Layout.alignment: Qt.AlignVCenter
                        }
                        Item { Layout.fillWidth: true }
                        SettingsButton {
                            id: backupLogsButton
                            Layout.preferredHeight: HMI.Theme.px(50)
                            Layout.preferredWidth: HMI.Theme.px(140)
                            label: backupButtonDisplayText
                            isAccent: false
                            enabled: !(LogBackupBackend && LogBackupBackend.backupInProgress)
                            onClicked: {
                                root.backupOutcome = ""
                                if (LogBackupBackend)
                                    LogBackupBackend.startBackup()
                            }
                        }
                    }
                }
            }

            // Terminal Buttons (first 4 customizable: label + command)
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: terminalColumn.implicitHeight + HMI.Theme.px(32)
                radius: HMI.Theme.px(18)
                color: HMI.Theme.center
                border.color: HMI.Theme.outline
                border.width: 1

                ColumnLayout {
                    id: terminalColumn
                    anchors.fill: parent
                    anchors.margins: HMI.Theme.px(16)
                    spacing: HMI.Theme.px(10)

                    Label {
                        text: "Terminal Buttons"
                        color: HMI.Theme.text
                        font.pixelSize: HMI.Theme.px(24)
                        font.bold: true
                        Layout.fillWidth: true
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: HMI.Theme.px(36)
                        spacing: HMI.Theme.px(8)
                        Label { text: ""; Layout.preferredWidth: HMI.Theme.px(32); color: HMI.Theme.sub; font.pixelSize: HMI.Theme.px(16) }
                        Label { text: "Label"; Layout.preferredWidth: HMI.Theme.px(140); color: HMI.Theme.sub; font.pixelSize: HMI.Theme.px(16) }
                        Label { text: "Command"; Layout.fillWidth: true; color: HMI.Theme.sub; font.pixelSize: HMI.Theme.px(16) }
                    }

                    TerminalButtonRow {
                        rowLabel: "1"
                        labelValue: settings.terminalButton1Label
                        commandValue: settings.terminalButton1Command
                        onLabelEdited: (v) => settings.terminalButton1Label = v
                        onCommandEdited: (v) => settings.terminalButton1Command = v
                    }
                    TerminalButtonRow {
                        rowLabel: "2"
                        labelValue: settings.terminalButton2Label
                        commandValue: settings.terminalButton2Command
                        onLabelEdited: (v) => settings.terminalButton2Label = v
                        onCommandEdited: (v) => settings.terminalButton2Command = v
                    }
                    TerminalButtonRow {
                        rowLabel: "3"
                        labelValue: settings.terminalButton3Label
                        commandValue: settings.terminalButton3Command
                        onLabelEdited: (v) => settings.terminalButton3Label = v
                        onCommandEdited: (v) => settings.terminalButton3Command = v
                    }
                    TerminalButtonRow {
                        rowLabel: "4"
                        labelValue: settings.terminalButton4Label
                        commandValue: settings.terminalButton4Command
                        onLabelEdited: (v) => settings.terminalButton4Label = v
                        onCommandEdited: (v) => settings.terminalButton4Command = v
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
                        label: "Use RTSP Stream"
                        value: settings.useRtspStream ? "true" : "false"
                        onValueEdited: (value) => { settings.useRtspStream = (value === "true") }
                        inputType: "toggle"
                    }

                    SettingRow {
                        visible: settings.useRtspStream
                        label: "Left Camera URL"
                        value: settings.leftCameraUrl
                        onValueEdited: (value) => { settings.leftCameraUrl = value }
                    }

                    SettingRow {
                        visible: settings.useRtspStream
                        label: "Center Camera URL"
                        value: settings.centerCameraUrl
                        onValueEdited: (value) => { settings.centerCameraUrl = value }
                    }

                    SettingRow {
                        visible: settings.useRtspStream
                        label: "Bumper Camera URL"
                        value: settings.bumperCameraUrl
                        onValueEdited: (value) => { settings.bumperCameraUrl = value }
                    }

                    SettingRow {
                        visible: settings.useRtspStream
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

        // Tap outside inputs to drop focus (clear highlight); event propagates so tapping a field still focuses it
        MouseArea {
            anchors.fill: parent
            z: 1
            propagateComposedEvents: true
            onPressed: (mouse) => { mouse.accepted = false }
            onClicked: (mouse) => {
                root.forceActiveFocus()
                if (typeof Qt.inputMethod !== "undefined" && Qt.inputMethod.hide)
                    Qt.inputMethod.hide()
                mouse.accepted = false
            }
        }
    }

    Connections {
        target: LogBackupBackend
        function onBackupFinished(success, message) {
            root.backupOutcome = success ? "success" : "failure"
            backupOutcomeResetTimer.start()
        }
    }

    Timer {
        id: backupOutcomeResetTimer
        interval: 5000
        repeat: false
        onTriggered: root.backupOutcome = ""
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
            color: btn.isAccent ? HMI.Theme.textOnAccent : HMI.Theme.text
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

    component TerminalButtonRow : RowLayout {
        id: terminalRow
        Layout.fillWidth: true
        Layout.preferredHeight: HMI.Theme.px(44)
        spacing: HMI.Theme.px(8)

        property string rowLabel: "1"
        property string labelValue: ""
        property string commandValue: ""
        signal labelEdited(string value)
        signal commandEdited(string value)

        Label {
            Layout.preferredWidth: HMI.Theme.px(32)
            text: terminalRow.rowLabel
            color: HMI.Theme.sub
            font.pixelSize: HMI.Theme.px(18)
            verticalAlignment: Text.AlignVCenter
        }

        TextField {
            id: labelField
            Layout.preferredWidth: HMI.Theme.px(140)
            Layout.minimumWidth: HMI.Theme.px(100)
            Layout.preferredHeight: HMI.Theme.px(42)
            text: terminalRow.labelValue
            color: HMI.Theme.text
            font.pixelSize: HMI.Theme.px(18)
            verticalAlignment: Text.AlignVCenter
            leftPadding: HMI.Theme.px(10)
            rightPadding: HMI.Theme.px(10)
            background: Rectangle {
                radius: HMI.Theme.px(10)
                color: HMI.Theme.surface
                border.color: labelField.activeFocus ? HMI.Theme.accent : HMI.Theme.outline
                border.width: labelField.activeFocus ? 2 : 1
            }
            onEditingFinished: terminalRow.labelEdited(text)
        }

        TextField {
            id: commandField
            Layout.fillWidth: true
            Layout.preferredHeight: HMI.Theme.px(42)
            text: terminalRow.commandValue
            color: HMI.Theme.text
            font.pixelSize: HMI.Theme.px(18)
            verticalAlignment: Text.AlignVCenter
            leftPadding: HMI.Theme.px(10)
            rightPadding: HMI.Theme.px(10)
            background: Rectangle {
                radius: HMI.Theme.px(10)
                color: HMI.Theme.surface
                border.color: commandField.activeFocus ? HMI.Theme.accent : HMI.Theme.outline
                border.width: commandField.activeFocus ? 2 : 1
            }
            onEditingFinished: terminalRow.commandEdited(text)
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
        property string placeholder: ""
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
                visible: settingRow.inputType === "text" || settingRow.inputType === "number" || settingRow.inputType === "password"
                text: settingRow.value
                color: HMI.Theme.text
                font.pixelSize: HMI.Theme.px(19)
                verticalAlignment: Text.AlignVCenter
                leftPadding: HMI.Theme.px(12)
                rightPadding: HMI.Theme.px(12)
                topPadding: HMI.Theme.px(8)
                bottomPadding: HMI.Theme.px(8)
                placeholderText: settingRow.placeholder
                placeholderTextColor: HMI.Theme.sub
                echoMode: settingRow.inputType === "password" ? TextInput.Password : TextInput.Normal
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

// pages/LoggerPage.qml — Data Logger (same layout style as SettingsPage)
import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import QtQuick.Effects
import HMI_Mk1 1.0 as HMI

Item {
    id: root
    Layout.fillWidth: true
    Layout.fillHeight: true

    // CAN bus filter: HS=0, CE=1, SC=2, LS=3 (synced from LoggerBackend)
    property bool canHS: typeof LoggerBackend !== "undefined" ? LoggerBackend.canHS : true
    property bool canCE: typeof LoggerBackend !== "undefined" ? LoggerBackend.canCE : true
    property bool canSC: typeof LoggerBackend !== "undefined" ? LoggerBackend.canSC : true
    property bool canLS: typeof LoggerBackend !== "undefined" ? LoggerBackend.canLS : true

    // Recording state (synced from LoggerBackend)
    property bool recording: false
    property bool paused: false

    // CAN bus tiles enabled only when there is incoming CAN traffic (status indicator on)
    property bool canBusSelectionEnabled: typeof NavigationBackend !== "undefined" ? NavigationBackend.canLoggerOn : false

    signal showCanBusDisabledWarning()

    Connections {
        target: typeof LoggerBackend !== "undefined" ? LoggerBackend : null
        function onIsRecordingChanged() {
            const nowRecording = LoggerBackend.isRecording
            if (nowRecording && !root.recording) root.recordingElapsedMs = 0
            root.recording = nowRecording
        }
        function onIsPausedChanged() { root.paused = LoggerBackend.isPaused }
        function onCanHSChanged() { root.canHS = LoggerBackend.canHS }
        function onCanCEChanged() { root.canCE = LoggerBackend.canCE }
        function onCanSCChanged() { root.canSC = LoggerBackend.canSC }
        function onCanLSChanged() { root.canLS = LoggerBackend.canLS }
    }

    readonly property real _canTileSize: HMI.Theme.px(88)
    readonly property real _canRowHeight: _canTileSize * 2 + HMI.Theme.px(10)
    readonly property real _canSectionHeight: HMI.Theme.px(24) + HMI.Theme.px(14) + _canRowHeight + HMI.Theme.px(32)

    // Recording timer: elapsed ms (only counts while recording and not paused); updates every 1s
    property int recordingElapsedMs: 0
    function formatTimeOnly(ms) {
        if (ms <= 0) return "0:00"
        const totalSecs = Math.floor(ms / 1000)
        const minutes = Math.floor(totalSecs / 60)
        const seconds = totalSecs % 60
        const pad2 = function(n) { return n < 10 ? "0" + n : "" + n }
        if (minutes < 10) return minutes + ":" + pad2(seconds)
        return pad2(minutes) + ":" + pad2(seconds)
    }
    function formatRecordingTime(ms) {
        if (ms <= 0) return "Recording • 0:00"
        return "Recording • " + formatTimeOnly(ms)
    }

    // Post-recording feedback: "Saved • 12:34" (green) or "Discarded • 12:34" (red), hides after 5s
    property string _postRecordingMessage: ""
    property string _postRecordingTime: ""
    property bool _postRecordingGreen: true
    function showPostRecordingFeedback(msg, time, isGreen) {
        root._postRecordingMessage = msg
        root._postRecordingTime = time
        root._postRecordingGreen = isGreen
        postRecordingHideTimer.restart()
    }

    Component.onCompleted: {
        if (typeof LoggerBackend !== "undefined") {
            root.recording = LoggerBackend.isRecording
            root.paused = LoggerBackend.isPaused
            root.canHS = LoggerBackend.canHS
            root.canCE = LoggerBackend.canCE
            root.canSC = LoggerBackend.canSC
            root.canLS = LoggerBackend.canLS
            root.canBusSelectionEnabled = typeof NavigationBackend !== "undefined" ? NavigationBackend.canLoggerOn : false
            LoggerBackend.refreshLogList()
            refreshLogsTimer.start()
        }
    }
    Timer {
        id: refreshLogsTimer
        interval: 400
        repeat: false
        onTriggered: if (typeof LoggerBackend !== "undefined") LoggerBackend.refreshLogList()
    }

    Timer {
        id: recordingTimer
        interval: 1000
        repeat: true
        running: root.recording && !root.paused
        onTriggered: root.recordingElapsedMs += 1000
    }

    Timer {
        id: postRecordingHideTimer
        interval: 5000
        repeat: false
        onTriggered: {
            root._postRecordingMessage = ""
            root._postRecordingTime = ""
        }
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

            // ——— CAN Network ———
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: root._canSectionHeight
                radius: HMI.Theme.px(18)
                color: HMI.Theme.center
                border.color: HMI.Theme.outline
                border.width: 1
                clip: true

                ColumnLayout {
                    id: canColumn
                    anchors.fill: parent
                    anchors.margins: HMI.Theme.px(16)
                    spacing: HMI.Theme.px(14)

                    Label {
                        text: "CAN Network"
                        color: HMI.Theme.text
                        font.pixelSize: HMI.Theme.px(24)
                        font.bold: true
                        Layout.fillWidth: true
                    }

                    RowLayout {
                        id: canRow
                        Layout.fillWidth: true
                        Layout.preferredHeight: root._canRowHeight
                        spacing: 0

                        // Column 1: CAN network selection (2x2 grid)
                        GridLayout {
                            id: canGrid
                            columns: 2
                            rowSpacing: HMI.Theme.px(10)
                            columnSpacing: HMI.Theme.px(10)
                            Layout.preferredWidth: canTileSize * 2 + canGrid.columnSpacing
                            Layout.preferredHeight: root._canRowHeight
                            Layout.rightMargin: HMI.Theme.px(16)

                            readonly property real canTileSize: root._canTileSize

                            CANCheckTile {
                                label: "HS"
                                checked: root.canHS
                                enabled: root.canBusSelectionEnabled
                                tileSize: canGrid.canTileSize
                                onToggled: if (typeof LoggerBackend !== "undefined") LoggerBackend.canHS = !LoggerBackend.canHS
                                onDisabledTapped: root.showCanBusDisabledWarning()
                            }
                            CANCheckTile {
                                label: "CE"
                                checked: root.canCE
                                enabled: root.canBusSelectionEnabled
                                tileSize: canGrid.canTileSize
                                onToggled: if (typeof LoggerBackend !== "undefined") LoggerBackend.canCE = !LoggerBackend.canCE
                                onDisabledTapped: root.showCanBusDisabledWarning()
                            }
                            CANCheckTile {
                                label: "SC"
                                checked: root.canSC
                                enabled: root.canBusSelectionEnabled
                                tileSize: canGrid.canTileSize
                                onToggled: if (typeof LoggerBackend !== "undefined") LoggerBackend.canSC = !LoggerBackend.canSC
                                onDisabledTapped: root.showCanBusDisabledWarning()
                            }
                            CANCheckTile {
                                label: "LS"
                                checked: root.canLS
                                enabled: root.canBusSelectionEnabled
                                tileSize: canGrid.canTileSize
                                onToggled: if (typeof LoggerBackend !== "undefined") LoggerBackend.canLS = !LoggerBackend.canLS
                                onDisabledTapped: root.showCanBusDisabledWarning()
                            }
                        }

                        // Invisible column border
                        Item { Layout.preferredWidth: HMI.Theme.px(16) }

                        // Column 2: Logging controls (timer overlaid on top so buttons never move)
                        Item {
                            Layout.preferredWidth: recordColumn.implicitWidth
                            Layout.preferredHeight: root._canRowHeight
                            Layout.rightMargin: HMI.Theme.px(16)

                            RowLayout {
                                id: recordColumn
                                anchors.fill: parent
                                spacing: HMI.Theme.px(10)

                                RecordControlButton {
                                iconSource: root.recording ? "../src/icons/save.svg" : "../src/icons/record.svg"
                                label: root.recording ? "Save" : "Record"
                                highlighted: root.recording && !root.paused
                                enabled: root.canBusSelectionEnabled
                                onClicked: {
                                    if (root.recording) {
                                        var t = root.formatTimeOnly(root.recordingElapsedMs)
                                        LoggerBackend.saveRecording()
                                        root.showPostRecordingFeedback("Saved", t, true)
                                    } else {
                                        LoggerBackend.startRecording()
                                    }
                                }
                                onDisabledTapped: root.showCanBusDisabledWarning()
                            }
                            RecordControlButton {
                                iconSource: root.paused ? "../src/icons/resume.svg" : "../src/icons/pause.svg"
                                label: root.paused ? "Resume" : "Pause"
                                highlighted: root.recording && root.paused
                                enabled: root.canBusSelectionEnabled && root.recording
                                onClicked: {
                                    if (root.paused)
                                        LoggerBackend.resumeRecording()
                                    else
                                        LoggerBackend.pauseRecording()
                                }
                                onDisabledTapped: root.showCanBusDisabledWarning()
                            }
                            RecordControlButton {
                                iconSource: "../src/icons/discard.svg"
                                label: "Discard"
                                highlighted: false
                                enabled: root.canBusSelectionEnabled && root.recording
                                onClicked: {
                                    var t = root.formatTimeOnly(root.recordingElapsedMs)
                                    LoggerBackend.discardRecording()
                                    root.showPostRecordingFeedback("Discarded", t, false)
                                }
                                onDisabledTapped: root.showCanBusDisabledWarning()
                            }
                            }

                            // Recording timer; when stopped, shows "Saved • 12:34" (green) or "Discarded • 12:34" (red) for 5s
                            Label {
                                anchors.top: parent.top
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.topMargin: HMI.Theme.px(4)
                                visible: root.recording || root._postRecordingMessage !== ""
                                text: root.recording ? root.formatRecordingTime(root.recordingElapsedMs) : (root._postRecordingMessage + " • " + root._postRecordingTime)
                                color: root.recording ? HMI.Theme.text : (root._postRecordingGreen ? "#2E7D32" : "#C62828")
                                font.pixelSize: HMI.Theme.px(20)
                                font.family: "monospace"
                            }
                        }

                        // Invisible column border
                        Item { Layout.preferredWidth: HMI.Theme.px(16) }

                        // Column 3: Saved logs list (scrollable)
                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.minimumWidth: HMI.Theme.px(140)
                            spacing: HMI.Theme.px(6)

                            Label {
                                text: "Saved logs"
                                color: HMI.Theme.text
                                font.pixelSize: HMI.Theme.px(18)
                                font.bold: true
                                Layout.fillWidth: true
                            }

                            ListView {
                                id: savedLogsList
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                Layout.minimumHeight: HMI.Theme.px(80)
                                clip: true
                                model: typeof LoggerBackend !== "undefined" ? LoggerBackend.logFileNames : []
                                spacing: HMI.Theme.px(4)
                                boundsBehavior: Flickable.DragAndOvershootBounds
                                flickDeceleration: 3000
                                maximumFlickVelocity: 2500
                                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AlwaysOff }

                                delegate: Rectangle {
                                    width: savedLogsList.width - HMI.Theme.px(2)
                                    height: HMI.Theme.px(36)
                                    radius: HMI.Theme.px(8)
                                    color: HMI.Theme.surface
                                    border.color: HMI.Theme.outline
                                    border.width: 1

                                    Text {
                                        anchors.fill: parent
                                        anchors.margins: HMI.Theme.px(8)
                                        text: modelData
                                        color: HMI.Theme.text
                                        font.pixelSize: HMI.Theme.px(14)
                                        font.family: "monospace"
                                        verticalAlignment: Text.AlignVCenter
                                        elide: Text.ElideRight
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ——— Intel Logs ———
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: HMI.Theme.px(320)
                radius: HMI.Theme.px(18)
                color: HMI.Theme.center
                border.color: HMI.Theme.outline
                border.width: 1
                clip: true

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: HMI.Theme.px(16)
                    spacing: HMI.Theme.px(12)

                    Label {
                        text: "Intel Logs"
                        color: HMI.Theme.text
                        font.pixelSize: HMI.Theme.px(24)
                        font.bold: true
                        Layout.fillWidth: true
                    }

                    // Saved Intel log files (src/logs/intel)
                    ListView {
                        id: intelSavedLogsList
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.minimumHeight: HMI.Theme.px(120)
                        clip: true
                        model: IntelLogsBackend ? IntelLogsBackend.logFileNames : []
                        spacing: HMI.Theme.px(4)
                        boundsBehavior: Flickable.DragAndOvershootBounds
                        flickDeceleration: 3000
                        maximumFlickVelocity: 2500
                        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AlwaysOff }

                        delegate: Rectangle {
                            width: intelSavedLogsList.width - HMI.Theme.px(2)
                            height: HMI.Theme.px(36)
                            radius: HMI.Theme.px(8)
                            color: HMI.Theme.surface
                            border.color: HMI.Theme.outline
                            border.width: 1

                            Text {
                                anchors.fill: parent
                                anchors.margins: HMI.Theme.px(8)
                                text: modelData
                                color: HMI.Theme.text
                                font.pixelSize: HMI.Theme.px(14)
                                font.family: "monospace"
                                verticalAlignment: Text.AlignVCenter
                                elide: Text.ElideRight
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: HMI.Theme.px(10)

                        Item { Layout.fillWidth: true } // spacer

                        RecordControlButton {
                            iconSource: "../src/icons/discard.svg"
                            label: "Clear"
                            highlighted: false
                            enabled: IntelLogsBackend !== undefined && IntelLogsBackend
                            onClicked: if (IntelLogsBackend) IntelLogsBackend.clearLogs()
                        }
                        RecordControlButton {
                            iconSource: "../src/icons/save.svg"
                            label: "Save"
                            highlighted: false
                            enabled: IntelLogsBackend !== undefined && IntelLogsBackend
                            onClicked: {
                                if (IntelLogsBackend) {
                                    IntelLogsBackend.saveLogs()
                                    IntelLogsBackend.refreshLogList()
                                }
                            }
                        }
                        RecordControlButton {
                            iconSource: "../src/icons/save.svg"
                            label: "Backup"
                            highlighted: false
                            enabled: (IntelLogsBackend !== undefined && IntelLogsBackend) && (typeof LogBackupBackend !== "undefined")
                            onClicked: {
                                if (!IntelLogsBackend || typeof LogBackupBackend === "undefined") return
                                IntelLogsBackend.saveLogs()
                                IntelLogsBackend.refreshLogList()
                                LogBackupBackend.startBackupFolder(IntelLogsBackend.logsDir, "Intel")
                            }
                        }
                    }
                }
            }
        }
    }

    // Checkbox-style tile (like DestList) with ripple and selection highlight
    component CANCheckTile: Rectangle {
        id: tile
        property string label: ""
        property bool checked: false
        property bool enabled: true
        property real tileSize: HMI.Theme.px(88)
        signal toggled()
        signal disabledTapped()

        implicitWidth: tileSize
        implicitHeight: tileSize
        radius: HMI.Theme.radius
        opacity: tile.enabled ? 1.0 : 0.5
        color: checked ? Qt.darker(HMI.Theme.accent, 1.15) : HMI.Theme.surface
        border.color: checked ? HMI.Theme.accent : HMI.Theme.outline
        border.width: checked ? 2 : 1

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
            text: tile.label
            color: tile.checked ? (mouse.pressed ? HMI.Theme.sub : "#FFFFFF") : (mouse.pressed ? HMI.Theme.sub : HMI.Theme.text)
            font.pixelSize: HMI.Theme.px(28)
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
            onClicked: {
                if (tile.enabled)
                    tile.toggled()
                else
                    tile.disabledTapped()
            }
        }

        ParallelAnimation {
            id: rippleAnim
            NumberAnimation { target: ripple; property: "width"; from: 0; to: tile.width; duration: 220; easing.type: Easing.OutCubic }
            NumberAnimation { target: ripple; property: "height"; from: 0; to: tile.height; duration: 220; easing.type: Easing.OutCubic }
            SequentialAnimation {
                NumberAnimation { target: ripple; property: "opacity"; from: 0.0; to: 0.10; duration: 90; easing.type: Easing.OutQuad }
                NumberAnimation { target: ripple; property: "opacity"; from: 0.10; to: 0.0; duration: 160; easing.type: Easing.OutQuad }
            }
        }

        scale: mouse.pressed ? 0.98 : 1.0
        Behavior on scale { NumberAnimation { duration: 90; easing.type: Easing.OutQuad } }
        Behavior on color { ColorAnimation { duration: 120 } }
        Behavior on border.color { ColorAnimation { duration: 120 } }
    }

    // Record control button (icon + optional label)
    component RecordControlButton: Rectangle {
        id: btn
        property string iconSource: ""
        property string label: ""
        property bool highlighted: false
        property bool enabled: true
        signal clicked()
        signal disabledTapped()

        implicitWidth: HMI.Theme.px(72)
        implicitHeight: HMI.Theme.px(72)
        radius: HMI.Theme.px(14)
        color: !btn.enabled ? HMI.Theme.center
             : mouse.pressed ? Qt.darker(btn.enabled && btn.highlighted ? HMI.Theme.accent : HMI.Theme.surface, 1.2)
             : (btn.highlighted ? HMI.Theme.accent : HMI.Theme.surface)
        border.color: btn.highlighted ? HMI.Theme.accent : HMI.Theme.outline
        border.width: btn.highlighted ? 2 : 1
        opacity: btn.enabled ? 1.0 : 0.5

        ColumnLayout {
            anchors.centerIn: parent
            spacing: HMI.Theme.px(4)

            Item {
                Layout.preferredWidth: HMI.Theme.px(28)
                Layout.preferredHeight: HMI.Theme.px(28)
                Layout.alignment: Qt.AlignHCenter

                property color iconColor: !btn.enabled ? HMI.Theme.sub
                    : (btn.highlighted ? "#FFFFFF" : HMI.Theme.text)

                Image {
                    id: iconImage
                    anchors.fill: parent
                    source: Qt.resolvedUrl(btn.iconSource)
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    mipmap: true
                    visible: false
                }
                MultiEffect {
                    anchors.fill: iconImage
                    source: iconImage
                    colorization: 1.0
                    colorizationColor: parent.iconColor
                    Behavior on colorizationColor { ColorAnimation { duration: 120 } }
                }
            }
            Label {
                text: btn.label
                color: !btn.enabled ? HMI.Theme.sub : (btn.highlighted ? "#FFFFFF" : HMI.Theme.text)
                font.pixelSize: HMI.Theme.px(12)
                font.bold: btn.highlighted
                Layout.alignment: Qt.AlignHCenter
                visible: btn.label.length > 0
            }
        }

        MouseArea {
            id: mouse
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onPressed: { }
            onClicked: btn.enabled ? btn.clicked() : btn.disabledTapped()
        }

        Behavior on color { ColorAnimation { duration: 120 } }
        Behavior on border.color { ColorAnimation { duration: 120 } }
        scale: mouse.pressed && btn.enabled ? 0.96 : 1.0
        Behavior on scale { NumberAnimation { duration: 90; easing.type: Easing.OutQuad } }
    }
}

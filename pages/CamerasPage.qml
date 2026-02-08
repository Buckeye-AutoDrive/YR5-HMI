import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import QtMultimedia 6.5
import HMI_Mk1 1.0 as HMI

Item {
        id: root

        Layout.fillWidth: true
        Layout.fillHeight: true

        // Current tab index (0=Left-Center, 1=Center-Bumper, 2=Center-Right, 3=LiDAR)
        property int currentTabIndex: 0

        // When false, show TCP proto camera frames (cam0/cam1/cam2); when true, show RTSP URLs
        property bool useRtspStream: SettingsBackend ? SettingsBackend.useRtspStream : true

        // Map slot index (0=Left,1=Center,2=Bumper,3=Right,4=LiDAR) to proto camera_id for image provider
        function protoCameraIdForIndex(idx) {
            switch (idx) {
                case 0: return "cam0"
                case 1: return "cam1"
                case 2: return "cam2"
                case 3: return "cam2"
                case 4: return ""
                default: return ""
            }
        }

        // Camera list (labels only; URLs come from SettingsBackend)
        ListModel {
            id: cameraModel
            ListElement { label: "Left";   code: "left" }
            ListElement { label: "Center"; code: "center" }
            ListElement { label: "Bumper"; code: "bumper" }
            ListElement { label: "Right";  code: "right" }
            ListElement { label: "LiDAR";  code: "lidar" }
        }

        // Tab configurations: [leftCameraIndex, rightCameraIndex]
        readonly property var tabConfigs: [
            [0, 1],  // Left-Center: left (0) on left, center (1) on right
            [1, 2],  // Center-Bumper: center (1) on left, bumper (2) on right
            [1, 3],  // Center-Right: center (1) on left, right (3) on right
            [4, 4]   // LiDAR: lidar (4) on both sides
        ]

        // Convenience: camera indices for current tab
        property int leftCameraIndex: {
            var config = tabConfigs[currentTabIndex]
            return config ? config[0] : 0
        }
        property int rightCameraIndex: {
            var config = tabConfigs[currentTabIndex]
            return config ? config[1] : 1
        }

        // URL for camera index (0=left, 1=center, 2=bumper, 3=right, 4=lidar placeholder)
        function streamUrlForIndex(idx) {
            if (!SettingsBackend) return ""
            switch (idx) {
                case 0: return SettingsBackend.leftCameraUrl || ""
                case 1: return SettingsBackend.centerCameraUrl || ""
                case 2: return SettingsBackend.bumperCameraUrl || ""
                case 3: return SettingsBackend.rightCameraUrl || ""
                case 4: return ""  // LiDAR placeholder
                default: return ""
            }
        }

        // Camera URLs from Settings (persistent); used by MediaPlayers
        property url leftCameraStreamUrl: streamUrlForIndex(leftCameraIndex)
        property url rightCameraStreamUrl: streamUrlForIndex(rightCameraIndex)

        // Media players for split view (only used when useRtspStream is true)
        MediaPlayer {
            id: leftPlayer
            source: useRtspStream ? leftCameraStreamUrl : ""
            videoOutput: leftVideo
            autoPlay: useRtspStream
            loops: MediaPlayer.Infinite

            onErrorOccurred: {
                if (useRtspStream) leftRetryTimer.restart()
            }
        }

        MediaPlayer {
            id: rightPlayer
            source: useRtspStream ? rightCameraStreamUrl : ""
            videoOutput: rightVideo
            autoPlay: useRtspStream
            loops: MediaPlayer.Infinite

            onErrorOccurred: {
                if (useRtspStream) rightRetryTimer.restart()
            }
        }

        Timer {
            id: leftRetryTimer
            interval: 2000
            repeat: true
            onTriggered: leftPlayer.play()
        }

        Timer {
            id: rightRetryTimer
            interval: 2000
            repeat: true
            onTriggered: rightPlayer.play()
        }

        function selectTab(tabIndex) {
            if (tabIndex < 0 || tabIndex >= tabConfigs.length)
                return
            
            currentTabIndex = tabIndex
            console.log("Selected tab:", tabIndex)
            
            if (useRtspStream) {
                if (leftPlayer.playbackState === MediaPlayer.PlayingState)
                    leftPlayer.stop()
                if (rightPlayer.playbackState === MediaPlayer.PlayingState)
                    rightPlayer.stop()
                leftPlayer.play()
                rightPlayer.play()
            }
        }

        // Outside rectangle (card)
        Rectangle {
            id: card
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

                // Split video area with two side-by-side video outputs
                RowLayout {
                    id: videoFrame
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: HMI.Theme.px(12)

                    // Left video output (RTSP or proto frames)
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: HMI.Theme.px(18)
                        color: "#101010"
                        border.color: HMI.Theme.outline
                        border.width: 1
                        clip: true

                        VideoOutput {
                            id: leftVideo
                            visible: root.useRtspStream
                            anchors.fill: parent
                            anchors.margins: HMI.Theme.px(12)
                            fillMode: VideoOutput.PreserveAspectFit
                        }

                        Image {
                            id: leftProtoImage
                            visible: !root.useRtspStream
                            anchors.fill: parent
                            anchors.margins: HMI.Theme.px(12)
                            fillMode: Image.PreserveAspectFit
                            source: {
                                if (root.useRtspStream) return ""
                                var id = root.protoCameraIdForIndex(root.leftCameraIndex)
                                if (!id || !CameraFramesBackend) return ""
                                return "image://camera/" + id + "?v=" + (CameraFramesBackend.frameVersion || 0)
                            }
                        }

                        Label {
                            id: leftStatusText
                            visible: root.useRtspStream
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: HMI.Theme.px(12)
                            color: HMI.Theme.sub
                            text: {
                                if (leftPlayer.playbackState === MediaPlayer.PlayingState) return ""
                                var idx = root.leftCameraIndex
                                return idx === 4 ? "LiDAR (Placeholder)" : "Connecting..."
                            }
                            font.pixelSize: HMI.Theme.px(18)
                        }

                        Label {
                            visible: !root.useRtspStream && root.leftCameraIndex === 4
                            anchors.centerIn: parent
                            color: HMI.Theme.sub
                            text: "LiDAR (Placeholder)"
                            font.pixelSize: HMI.Theme.px(18)
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                if (root.useRtspStream && leftPlayer.playbackState !== MediaPlayer.PlayingState && leftCameraIndex !== 4)
                                    leftPlayer.play()
                            }
                        }
                    }

                    // Right video output (RTSP or proto frames)
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: HMI.Theme.px(18)
                        color: "#101010"
                        border.color: HMI.Theme.outline
                        border.width: 1
                        clip: true

                        VideoOutput {
                            id: rightVideo
                            visible: root.useRtspStream
                            anchors.fill: parent
                            anchors.margins: HMI.Theme.px(12)
                            fillMode: VideoOutput.PreserveAspectFit
                        }

                        Image {
                            id: rightProtoImage
                            visible: !root.useRtspStream
                            anchors.fill: parent
                            anchors.margins: HMI.Theme.px(12)
                            fillMode: Image.PreserveAspectFit
                            source: {
                                if (root.useRtspStream) return ""
                                var id = root.protoCameraIdForIndex(root.rightCameraIndex)
                                if (!id || !CameraFramesBackend) return ""
                                return "image://camera/" + id + "?v=" + (CameraFramesBackend.frameVersion || 0)
                            }
                        }

                        Label {
                            id: rightStatusText
                            visible: root.useRtspStream
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: HMI.Theme.px(12)
                            color: HMI.Theme.sub
                            text: {
                                if (rightPlayer.playbackState === MediaPlayer.PlayingState) return ""
                                var idx = root.rightCameraIndex
                                return idx === 4 ? "LiDAR (Placeholder)" : "Connecting..."
                            }
                            font.pixelSize: HMI.Theme.px(18)
                        }

                        Label {
                            visible: !root.useRtspStream && root.rightCameraIndex === 4
                            anchors.centerIn: parent
                            color: HMI.Theme.sub
                            text: "LiDAR (Placeholder)"
                            font.pixelSize: HMI.Theme.px(18)
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                if (root.useRtspStream && rightPlayer.playbackState !== MediaPlayer.PlayingState && rightCameraIndex !== 4)
                                    rightPlayer.play()
                            }
                        }
                    }
                }

                // Bottom camera selector row (tabs)
                Item {
                    id: cameraBar
                    Layout.fillWidth: true
                    Layout.preferredHeight: HMI.Theme.px(70)

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: HMI.Theme.px(4)
                        spacing: HMI.Theme.px(10)

                        // Tab 0: Left-Center
                        Rectangle {
                            id: leftCenterButton
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: HMI.Theme.px(18)
                            property bool selected: root.currentTabIndex === 0
                            property bool pressed: false
                            readonly property color baseBg: selected
                                ? HMI.Theme.accent
                                : HMI.Theme.surface
                            color: pressed ? Qt.darker(baseBg, 1.25) : baseBg
                            border.color: selected ? HMI.Theme.accent : HMI.Theme.outline
                            border.width: selected ? 3 : 1
                            opacity: 0.98
                            scale: pressed ? 0.94 : 1.0
                            Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
                            Behavior on color { ColorAnimation { duration: 120; easing.type: Easing.OutQuad } }
                            Label {
                                anchors.centerIn: parent
                                text: "Left-Center"
                                color: leftCenterButton.selected ? HMI.Theme.textOnAccent : HMI.Theme.text
                                font.pixelSize: HMI.Theme.px(18)
                                font.bold: leftCenterButton.selected
                                elide: Text.ElideRight
                            }
                            MouseArea {
                                anchors.fill: parent
                                onPressed: leftCenterButton.pressed = true
                                onCanceled: leftCenterButton.pressed = false
                                onReleased: {
                                    leftCenterButton.pressed = false
                                    root.selectTab(0)
                                }
                            }
                        }

                        // Tab 1: Center-Bumper
                        Rectangle {
                            id: centerBumperButton
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: HMI.Theme.px(18)
                            property bool selected: root.currentTabIndex === 1
                            property bool pressed: false
                            readonly property color baseBg: selected
                                ? HMI.Theme.accent
                                : HMI.Theme.surface
                            color: pressed ? Qt.darker(baseBg, 1.25) : baseBg
                            border.color: selected ? HMI.Theme.accent : HMI.Theme.outline
                            border.width: selected ? 3 : 1
                            opacity: 0.98
                            scale: pressed ? 0.94 : 1.0
                            Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
                            Behavior on color { ColorAnimation { duration: 120; easing.type: Easing.OutQuad } }
                            Label {
                                anchors.centerIn: parent
                                text: "Center-Bumper"
                                color: centerBumperButton.selected ? HMI.Theme.textOnAccent : HMI.Theme.text
                                font.pixelSize: HMI.Theme.px(18)
                                font.bold: centerBumperButton.selected
                                elide: Text.ElideRight
                            }
                            MouseArea {
                                anchors.fill: parent
                                onPressed: centerBumperButton.pressed = true
                                onCanceled: centerBumperButton.pressed = false
                                onReleased: {
                                    centerBumperButton.pressed = false
                                    root.selectTab(1)
                                }
                            }
                        }

                        // Tab 2: Center-Right
                        Rectangle {
                            id: centerRightButton
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: HMI.Theme.px(18)
                            property bool selected: root.currentTabIndex === 2
                            property bool pressed: false
                            readonly property color baseBg: selected
                                ? HMI.Theme.accent
                                : HMI.Theme.surface
                            color: pressed ? Qt.darker(baseBg, 1.25) : baseBg
                            border.color: selected ? HMI.Theme.accent : HMI.Theme.outline
                            border.width: selected ? 3 : 1
                            opacity: 0.98
                            scale: pressed ? 0.94 : 1.0
                            Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
                            Behavior on color { ColorAnimation { duration: 120; easing.type: Easing.OutQuad } }
                            Label {
                                anchors.centerIn: parent
                                text: "Center-Right"
                                color: centerRightButton.selected ? HMI.Theme.textOnAccent : HMI.Theme.text
                                font.pixelSize: HMI.Theme.px(18)
                                font.bold: centerRightButton.selected
                                elide: Text.ElideRight
                            }
                            MouseArea {
                                anchors.fill: parent
                                onPressed: centerRightButton.pressed = true
                                onCanceled: centerRightButton.pressed = false
                                onReleased: {
                                    centerRightButton.pressed = false
                                    root.selectTab(2)
                                }
                            }
                        }

                        // Tab 3: LiDAR
                        Rectangle {
                            id: lidarButton
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: HMI.Theme.px(18)
                            property bool selected: root.currentTabIndex === 3
                            property bool pressed: false
                            readonly property color baseBg: selected
                                ? HMI.Theme.accent
                                : HMI.Theme.surface
                            color: pressed ? Qt.darker(baseBg, 1.25) : baseBg
                            border.color: selected ? HMI.Theme.accent : HMI.Theme.outline
                            border.width: selected ? 3 : 1
                            opacity: 0.98
                            scale: pressed ? 0.94 : 1.0
                            Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
                            Behavior on color { ColorAnimation { duration: 120; easing.type: Easing.OutQuad } }
                            Label {
                                anchors.centerIn: parent
                                text: "LiDAR"
                                color: lidarButton.selected ? HMI.Theme.textOnAccent : HMI.Theme.text
                                font.pixelSize: HMI.Theme.px(18)
                                font.bold: lidarButton.selected
                                elide: Text.ElideRight
                            }
                            MouseArea {
                                anchors.fill: parent
                                onPressed: lidarButton.pressed = true
                                onCanceled: lidarButton.pressed = false
                                onReleased: {
                                    lidarButton.pressed = false
                                    root.selectTab(3)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import QtMultimedia 6.5
import HMI_Mk1 1.0 as HMI

Item {
    id: root


  /*  ORIGINAL CODE

    // Card background
    Rectangle {
        id: card
        anchors.fill: parent
        radius: HMI.Theme.radius
        color: HMI.Theme.center
        border.color: HMI.Theme.outline
        clip: true   // so VideoOutput corners follow the rounded card
    }


     Video renderer
    VideoOutput {
        id: video
        anchors.fill: card
        anchors.margins: HMI.Theme.px(12)
        fillMode: VideoOutput.PreserveAspectFit
    }

    // Player (link via videoOutput property)
    MediaPlayer {
        id: player
        source: rtspUrl
        videoOutput: video
        autoPlay: true
        loops: MediaPlayer.Infinite
        // audioOutput: AudioOutput { muted: true } // optional

        onErrorOccurred: {
            statusText.text = errorString
            retryTimer.restart()
        }
    }

    // Status overlay
    Label {
        id: statusText
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: HMI.Theme.px(12)
        color: HMI.Theme.sub
        text: player.playbackState === MediaPlayer.PlayingState ? "" : "Connecting..."
        font.pixelSize: HMI.Theme.px(18)
    }

    // Tap-to-retry
    MouseArea {
        anchors.fill: parent
        onClicked: if (player.playbackState !== MediaPlayer.PlayingState) player.play()
    }

    Timer {
        id: retryTimer
        interval: 2000
        repeat: false
        onTriggered: player.play()
    }
}
*/

        Layout.fillWidth: true
        Layout.fillHeight: true

        // Which camera is selected
        property int currentCameraIndex: 0

        // Camera list (put your real RTSP URLs here)
        ListModel {
            id: cameraModel
            ListElement { label: "Center"; code: "center"; streamUrl: "rtsp://<center-stream-url>" }
            ListElement { label: "Left";   code: "left";   streamUrl: "rtsp://<left-stream-url>"   }
            ListElement { label: "Right";  code: "right";  streamUrl: "rtsp://<right-stream-url>"  }
            ListElement { label: "Bumper"; code: "bumper"; streamUrl: "rtsp://<bumper-stream-url>" }
        }

        // Convenience: current camera label / code / url
        property string currentCameraLabel:
            cameraModel.count > 0 ? cameraModel.get(currentCameraIndex).label : ""
        property string currentCameraCode:
            cameraModel.count > 0 ? cameraModel.get(currentCameraIndex).code : ""
        property url currentCameraStreamUrl:
            cameraModel.count > 0 ? cameraModel.get(currentCameraIndex).streamUrl : ""

        // Media player (source bound to currently selected camera)
        MediaPlayer {
            id: player
            source: currentCameraStreamUrl
            videoOutput: video
            autoPlay: true
            loops: MediaPlayer.Infinite
            // audioOutput: AudioOutput { muted: true }  // optional

            onErrorOccurred: {
                statusText.text = errorString
                retryTimer.restart()
            }
        }

        Timer {
            id: retryTimer
            interval: 2000
            repeat: false
            onTriggered: player.play()
        }

        function selectCamera(idx) {
            if (idx < 0 || idx >= cameraModel.count)
                return

            currentCameraIndex = idx
            console.log("Selected camera:", currentCameraLabel)

            // Force restart on camera change
            if (player.playbackState === MediaPlayer.PlayingState) {
                player.stop()
            }
            player.play()
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

                // Video area with inner chamfer and outline
                Rectangle {
                    id: videoFrame
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    radius: HMI.Theme.px(18)
                    color: "#101010"
                    border.color: HMI.Theme.outline
                    border.width: 1
                    clip: true

                    // Actual RTSP video renderer
                    VideoOutput {
                        id: video
                        anchors.fill: parent
                        anchors.margins: HMI.Theme.px(12)
                        fillMode: VideoOutput.PreserveAspectFit
                    }

                    // Status overlay (connecting / error)
                    Label {
                        id: statusText
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: HMI.Theme.px(12)
                        color: HMI.Theme.sub
                        text: player.playbackState === MediaPlayer.PlayingState
                              ? ""
                              : (statusText.text !== "" ? statusText.text : "Connecting...")
                        font.pixelSize: HMI.Theme.px(18)
                    }

                    // Tap-to-retry
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (player.playbackState !== MediaPlayer.PlayingState)
                                player.play()
                        }
                    }
                }

                // Bottom camera selector row
                Item {
                    id: cameraBar
                    Layout.fillWidth: true
                    Layout.preferredHeight: HMI.Theme.px(70)

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: HMI.Theme.px(4)
                        spacing: HMI.Theme.px(10)

                        Repeater {
                            model: cameraModel

                            Rectangle {
                                id: button
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                radius: HMI.Theme.px(18)

                                // AV-like behavior
                                property bool selected: index === root.currentCameraIndex
                                property bool pressed: false

                                readonly property color baseBg: selected
                                    ? HMI.Theme.accent
                                    : "#171717"

                                // Darken a bit when pressed, otherwise AV-like tile
                                color: pressed ? Qt.darker(baseBg, 1.25) : baseBg
                                border.color: selected ? HMI.Theme.accent : HMI.Theme.outline
                                border.width: selected ? 3 : 1
                                opacity: 0.98

                                // AV-style animations (scale + color)
                                scale: pressed ? 0.94 : 1.0
                                Behavior on scale {
                                    NumberAnimation {
                                        duration: 120
                                        easing.type: Easing.OutQuad
                                    }
                                }
                                Behavior on color {
                                    ColorAnimation {
                                        duration: 120
                                        easing.type: Easing.OutQuad
                                    }
                                }

                                Label {
                                    anchors.centerIn: parent
                                    text: label
                                    color: HMI.Theme.text
                                    font.pixelSize: HMI.Theme.px(18)
                                    font.bold: selected
                                    elide: Text.ElideRight
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onPressed:  button.pressed = true
                                    onCanceled: button.pressed = false
                                    onReleased: {
                                        button.pressed = false
                                        root.selectCamera(index)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }


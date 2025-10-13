import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import QtMultimedia 6.5
import HMI_Mk1 1.0 as HMI

Item {
    id: root
    property url rtspUrl: "rtsp://Bv3zqz:AUfl3qc0jshO@192.168.1.252:554/live/ch0"

    // Card background
    Rectangle {
        id: card
        anchors.fill: parent
        radius: HMI.Theme.radius
        color: HMI.Theme.center
        border.color: HMI.Theme.outline
        clip: true   // so VideoOutput corners follow the rounded card
    }

    // Video renderer
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

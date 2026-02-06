pragma Singleton
import QtQuick 2.15

QtObject {
    property string fontBody: "Universal Sans"
    property string fontDisplay: "Universal Sans Display"

    property real dp: 1.0
    function px(n) { return Math.round(n * dp) }

    property color bg:        "#121212"
    property color surface:   "#141414"
    property color center:    "#181818"
    property color outline:   "#2A2A2A"
    property color accent:    "#B10F2E"
    property color text:      "#E6E6E6"
    property color sub:       "#9E9E9E"

    property int radius: 12
    property int pad: 16

    property real colSource: 0.38
    property real colId:     0.20
    property real colValue:  0.42
}

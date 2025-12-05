pragma Singleton
import QtQuick 2.15

QtObject {
    // scale
    property real dp: 1.0
    function px(n) { return Math.round(n * dp) }

    // graphite + scarlet
    property color bg:        "#121212"   // window
    property color surface:   "#141414"   // side + right panels
    property color center:    "#181818"   // middle panel (stage)
    property color outline:   "#2A2A2A"
    property color accent:    "#B10F2E"   // OSU scarlet
    property color text:      "#E6E6E6"
    property color sub:       "#9E9E9E"

    property int   radius: 12
    property int   pad:    16

    // Data table column width ratios (sum ~= 1.0)
    property real colSource: 0.38
    property real colId:     0.20
    property real colValue:  0.42
}

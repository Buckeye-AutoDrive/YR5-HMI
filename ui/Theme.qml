pragma Singleton
import QtQuick 2.15

QtObject {
    property string fontBody: "Universal Sans"
    property string fontDisplay: "Universal Sans Display"
    // When you add a heavier TTF (e.g. UniversalSans-SemiBold.ttf), load it in main.cpp
    // and set fontWeightBody to Font.DemiBold for denser body text.
    property int fontWeightBody: Font.Normal

    property real dp: 1.0
    function px(n) { return Math.round(n * dp) }

    // When false, UI uses light palette; map and camera feeds are unchanged (they don't use Theme)
    property bool themeDark: true

    property color bg:        themeDark ? "#121212" : "#E8E8E8"
    property color surface:   themeDark ? "#141414" : "#EBEBEB"
    property color center:    themeDark ? "#181818" : "#E0E0E0"
    property color outline:   themeDark ? "#2A2A2A" : "#B0B0B0"
    property color accent:    themeDark ? "#B10F2E" : "#A00C28"
    property color text:      themeDark ? "#E6E6E6" : "#1A1A1A"
    property color sub:       themeDark ? "#9E9E9E" : "#5C5C5C"
    // Text on accent background (e.g. Save button, selected camera tabs) — always light
    property color textOnAccent: "#FFFFFF"

    property int radius: 12
    property int pad: 16

    property real colSource: 0.38
    property real colId:     0.20
    property real colValue:  0.42
}

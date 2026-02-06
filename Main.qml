import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Material 2.15
import QtQuick.Effects
import HMI_Mk1 1.0 as HMI

ApplicationWindow {
    id: app
    width: 1920
    height: 720
    visible: true
    title: "CAR HMI Mk1"
    visibility: Window.FullScreen

    Material.theme: Material.Dark
    Material.accent: "#ba0c2f"
    color: HMI.Theme.bg

    // demo telemetry (unchanged) ...
    property real  spd: 34
    property real  yaw: -4.7
    property real  latAcc: 0.12
    property real  steer: 3.5
    property string mode: "AUTO"
    property real  cpu: 23
    property real  mem: 41
    property real  rand: 0
    property int fsmRow: -1

    property bool lanOn: true
    property bool gnssOn: false
    property bool sensorsOn: false
    property bool autoOn: true

    property alias panelWidth: centerPanel.width

    ListModel { id: telemetryModel }

    function recomputeDp() { HMI.Theme.dp = (height / 720) * 1.25; }

    Connections {
        target: NavigationBackend
        function onSafetyStatesChanged() {
            if (fsmRow >= 0)
                telemetryModel.setProperty(fsmRow, "value", NavigationBackend.fsmStateText)
        }
    }


    Component.onCompleted: {

        // your existing init
        recomputeDp()

        telemetryModel.append({source:"HS CAN", id:"$1E", value: rand.toFixed(2)})
        telemetryModel.append({source:"CE CAN", id:"$C2", value: rand.toFixed(2)})
        telemetryModel.append({source:"Speed",  id:"-",   value: String(Math.round(spd)),   unit:"km/h"})
        telemetryModel.append({source:"Yaw",    id:"-",   value: yaw.toFixed(1),            unit:"°"})
        telemetryModel.append({source:"Lat Acc",id:"-",   value: latAcc.toFixed(2),         unit:"m/s²"})
        telemetryModel.append({source:"Steer",  id:"-",   value: steer.toFixed(1),          unit:"°"})

        fsmRow = telemetryModel.count
        telemetryModel.append({source:"FSM State", id:"-", value: NavigationBackend.fsmStateText})

        telemetryModel.append({source:"CPU", id:"SoC",  value: cpu.toFixed(0), unit:"%"})
        telemetryModel.append({source:"Mem", id:"Used", value: mem.toFixed(0), unit:"%"})
    }

    onWidthChanged:  recomputeDp()
    onHeightChanged: recomputeDp()

    Timer {
        interval: 250; running: true; repeat: true
        onTriggered: {
            app.spd    = Math.max(0, app.spd + (Math.random()*2 - 1));
            app.yaw    = app.yaw + (Math.random()*0.3 - 0.15);
            app.latAcc = app.latAcc + (Math.random()*0.04 - 0.02);
            app.steer  = app.steer + (Math.random()*0.3 - 0.15);
            app.cpu    = Math.min(100, Math.max(0, app.cpu + (Math.random()*4 - 2)));
            app.mem    = Math.min(100, Math.max(0, app.mem + (Math.random()*1 - 0.5)));
            app.rand   = Math.random()*100 - 50;

            telemetryModel.setProperty(0, "value", app.rand.toFixed(2));
            telemetryModel.setProperty(1, "value", app.rand.toFixed(2));
            telemetryModel.setProperty(2, "value", String(Math.round(app.spd)));
            telemetryModel.setProperty(3, "value", app.yaw.toFixed(1));
            telemetryModel.setProperty(4, "value", app.latAcc.toFixed(2));
            telemetryModel.setProperty(5, "value", app.steer.toFixed(1));
            telemetryModel.setProperty(7, "value", app.cpu.toFixed(0));
            telemetryModel.setProperty(8, "value", app.mem.toFixed(0));
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: HMI.Theme.px(12)
        spacing: HMI.Theme.px(12)

        // LEFT NAV
        HMI.SideNav {
            id: side
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.preferredWidth: app.width * 0.22

            model: ["Cameras", "Sensors", "Map", "Destination", "AV Actions", "System Settings", "Quit"]

            onActivated: function(i) {
                if (i === model.length - 1) {
                    // LAST ITEM = Quit
                    Qt.quit()
                    return
                }

                // normal navigation
                if (i === 0)        stack.currentIndex = 0   // Cameras
                else if (i === 2)   stack.currentIndex = 1   // Map
                else if (i === 4)   stack.currentIndex = 2   // AV Actions
                else                stack.currentIndex = 0
            }
        }


        // CENTER PANEL
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: app.width * 0.56

            Rectangle {
                id: centerPanel
                anchors.fill: parent
                radius: HMI.Theme.radius
                color: "#181818"
                border.color: HMI.Theme.outline
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: HMI.Theme.px(16)
                spacing: HMI.Theme.px(12)

                Item {
                    id: headerRow
                    Layout.fillWidth: true
                    height: HMI.Theme.px(52)

                    // LEFT: icons
                    Row {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: HMI.Theme.px(10)

                        StatusIcon { kind: "lan";     on: lanOn }
                        StatusIcon { kind: "gnss";    on: gnssOn }
                        StatusIcon { kind: "sensors"; on: sensorsOn }
                        StatusIcon { kind: "auto";    on: autoOn }
                    }

                    // CENTER: title (stays centered)
                    Label {
                        id: pageTitle
                        anchors.centerIn: parent

                        text: stack.currentIndex === 0 ? "Cameras"
                             : stack.currentIndex === 1 ? "Map"
                             : stack.currentIndex === 2 ? "AV Actions"
                             : "Cameras"

                        color: HMI.Theme.text
                        font.pixelSize: HMI.Theme.px(34)
                        font.bold: true
                        font.family: HMI.Theme.fontDisplay
                        horizontalAlignment: Text.AlignHCenter
                    }

                    // RIGHT: FSM tile
                    Row {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: HMI.Theme.px(10)

                        FsmTile { }  // reads NavigationBackend.safetyStates internally
                    }
                }

                StackLayout {
                    id: stack
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    currentIndex: 0

                    HMI.CamerasPage {}
                    HMI.MapPage {}
                    HMI.AVActionsPage {}
                }
            }
        }

        // RIGHT: DATA MONITOR / DESTINATIONS — narrower (proportional)
        Item {
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.preferredWidth: app.width * 0.22

            Rectangle {
                anchors.fill: parent
                radius: HMI.Theme.radius
                color: HMI.Theme.surface
                border.color: HMI.Theme.outline
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: HMI.Theme.px(16)
                spacing: HMI.Theme.px(12)

                Label {
                    text: stack.currentIndex === 1 ? "Destinations"
                                                   : "Data monitor"
                    color: HMI.Theme.text
                    font.pixelSize: HMI.Theme.px(32)
                    font.bold: true
                    // Optional: Display font for right-panel title too
                    font.family: HMI.Theme.fontDisplay

                    horizontalAlignment: Text.AlignHCenter
                    Layout.fillWidth: true
                }

                StackLayout {
                    id: rightStack
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    currentIndex: stack.currentIndex === 1 ? 1 : 0

                    // index 0 — telemetry table
                    HMI.DataTable {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        rows: telemetryModel
                    }

                    // index 1 — destination list
                    HMI.DestList {
                        id: destList
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        onDestinationSelected: function(label) {
                            avWarnPage.openForDestination(label)
                        }
                    }
                }
            }
        }
    }

    component StatusIcon : Item {
        id: statusIcon

        property string kind: "auto"
        property bool on: false

        width: HMI.Theme.px(36)
        height: HMI.Theme.px(36)

        Rectangle {
            anchors.fill: parent
            radius: HMI.Theme.px(10)
            color: "#161616"
            border.color: HMI.Theme.outline
        }

        Image {
            anchors.centerIn: parent
            width: HMI.Theme.px(22)
            height: HMI.Theme.px(22)
            fillMode: Image.PreserveAspectFit
            smooth: true

            source: {
                const base = "src/icons/"
                if (statusIcon.kind === "auto")    return base + (statusIcon.on ? "auto_on.svg"    : "auto_off.svg")
                if (statusIcon.kind === "sensors") return base + (statusIcon.on ? "sensors_on.svg" : "sensors_off.svg")
                if (statusIcon.kind === "gnss")    return base + (statusIcon.on ? "gnss_on.svg"    : "gnss_off.svg")
                if (statusIcon.kind === "lan")     return base + (statusIcon.on ? "lan_on.svg"     : "lan_off.svg")
                return ""
            }

            onStatusChanged: if (status === Image.Error) console.log("ICON LOAD ERROR:", source)
        }
    }
    component FsmTile : Item {
        id: fsmTile

        property string textValue: NavigationBackend.fsmStateText

        readonly property int h: HMI.Theme.px(36)
        readonly property int padX: HMI.Theme.px(10)

        height: h
        width: Math.max(h, label.implicitWidth + padX * 2)

        function bgFor(s) {
            if (s === 8)  return "#12301F"   // AV
            if (s === 10) return "#3A1212"   // FAIL
            if (s === 9)  return "#2A1F10"   // OFF
            if (s === 1)  return "#1A1A1A"   // STARTUP
            return "#161616"
        }

        function fgFor(s) {
            if (s === 8)  return "#33D17A"
            if (s === 10) return "#FF4D4D"
            if (s === 9)  return "#FFB020"
            return HMI.Theme.text
        }

        Rectangle {
            anchors.fill: parent
            radius: HMI.Theme.px(10)
            color: fsmTile.bgFor(fsmTile.state)
            border.color: HMI.Theme.outline
        }

        Text {
            id: label
            anchors.centerIn: parent
            text: fsmTile.textValue
            color: fsmTile.fgFor(fsmTile.state)

            font.pixelSize: HMI.Theme.px(13)
            font.bold: true

            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            wrapMode: Text.NoWrap
        }
    }



    // Full-screen engage warning / AV state warning
    HMI.AVWarnPage {
        id: avWarnPage
        anchors.fill: parent
    }

    Shortcut { sequence: "Ctrl+Q"; onActivated: Qt.quit() }
}



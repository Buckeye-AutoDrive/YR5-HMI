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
        recomputeDp()

        telemetryModel.append({source:"HS CAN", id:"$1E", value: rand.toFixed(2)})
        telemetryModel.append({source:"CE CAN", id:"$C2", value: rand.toFixed(2)})
        telemetryModel.append({source:"Speed",  id:"-",   value: String(Math.round(spd)),   unit:"km/h"})
        telemetryModel.append({source:"Yaw",    id:"-",   value: yaw.toFixed(1),            unit:"°"})
        telemetryModel.append({source:"Lat Acc",id:"-",   value: latAcc.toFixed(2),         unit:"m/s²"})
        telemetryModel.append({source:"Steer",  id:"-",   value: steer.toFixed(1),          unit:"°"})

        fsmRow = telemetryModel.count
        telemetryModel.append({source:"FSM State",   id:"-",   value: NavigationBackend.fsmStateText})

        telemetryModel.append({source:"CPU",    id:"SoC", value: cpu.toFixed(0),            unit:"%"})
        telemetryModel.append({source:"Mem",    id:"Used",value: mem.toFixed(0),            unit:"%"})
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
            // telemetryModel.setProperty(6, "value", app.mode);
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
            model: ["Cameras", "Sensors", "Map", "Destination", "AV Actions", "System Settings"]

            onActivated: function(i) {
                if (i === 0)        stack.currentIndex = 0;   // Cameras
                else if (i === 2)   stack.currentIndex = 1;   // Map
                else if (i === 4)   stack.currentIndex = 2;   // AV Actions
                else                stack.currentIndex = 0;   // default
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

                Label {
                    id: pageTitle
                    text: stack.currentIndex === 0 ? "Cameras"
                         : stack.currentIndex === 1 ? "Map"
                         : stack.currentIndex === 2 ? "AV Actions"
                         : "Cameras"
                    color: HMI.Theme.text
                    font.pixelSize: HMI.Theme.px(34)
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    Layout.fillWidth: true
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
                    horizontalAlignment: Text.AlignHCenter
                    Layout.fillWidth: true
                }

                StackLayout {
                    id: rightStack
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    // Cameras / AV Actions -> show telemetry
                    // Map page (index 1)    -> show destinations
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
                            // Open full-screen warning page
                            avWarnPage.openForDestination(label)

                        }
                    }
                }
            }
        }
    }

    // Full-screen engage warning / AV state warning
    HMI.AVWarnPage {
        id: avWarnPage
        anchors.fill: parent
    }

    Shortcut { sequence: "Ctrl+Q"; onActivated: Qt.quit() }
}

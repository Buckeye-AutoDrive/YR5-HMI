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
    // visibility: Window.FullScreen

    font.family: HMI.Theme.fontBody
    font.pixelSize: 16

    Material.theme: Material.Dark
    Material.accent: "#ba0c2f"
    color: HMI.Theme.bg

    // Keep Theme in sync with Settings (map and camera feeds do not use Theme, so they stay unchanged)
    Binding { target: HMI.Theme; property: "themeDark"; value: SettingsBackend.themeDark }

    // Right panel: show AVPanel when engaged (from Map), DestList when not, DataTable on other pages
    readonly property bool rightPanelEngaged: avActionsPage.avEngaged

    Connections {
        target: avWarnPage
        function onAccepted() {
            avActionsPage.avEngaged = true
            avActionsPage.avTargetEngaged = true
            avActionsPage.avPending = false
        }
    }

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
            if (fsmRow >= 0 && fsmRow < telemetryModel.count)
                telemetryModel.setProperty(fsmRow, "value", NavigationBackend.fsmStateText)

            // Drive right-panel engagement from safety state: 1–8 = engaged (AVPanel), 0/9/10 = disengaged (DestList)
            const s = NavigationBackend.safetyStates
            if (s >= 1 && s <= 8) {
                avActionsPage.avEngaged = true
                avActionsPage.avTargetEngaged = true
                avActionsPage.avPending = false
            } else if ((s === 0 || s === 9 || s === 10) && avActionsPage.avEngaged) {
                avActionsPage.avEngaged = false
                avActionsPage.avTargetEngaged = false
                avActionsPage.avPending = false
            }
        }
    }


    Component.onCompleted: {

        // your existing init
        app.recomputeDp()

        // Sync engagement from initial safety state (e.g. if HMI reconnects while vehicle is already in 1–8)
        var s = NavigationBackend.safetyStates
        if (s >= 1 && s <= 8) {
            avActionsPage.avEngaged = true
            avActionsPage.avTargetEngaged = true
            avActionsPage.avPending = false
        } else if (s === 0 || s === 9 || s === 10) {
            avActionsPage.avEngaged = false
            avActionsPage.avTargetEngaged = false
            avActionsPage.avPending = false
        }

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

            if (telemetryModel.count < 9) return;
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
            currentIndex: 0

            // model: ["Map", "Cameras", "Data Logger", "AV Actions", "Terminal", "Settings", "Quit"]
            model: ["Map", "Cameras", "Data Logger", "Terminal", "Settings", "Quit"]  // AV Actions hidden for now

            onActivated: function(i) {
                if (i === model.length - 1) {
                    // LAST ITEM = Quit
                    Qt.quit()
                    return
                }

                // normal navigation (AV Actions index commented out)
                if (i === 0)        stack.currentIndex = 0   // Map
                else if (i === 1)   stack.currentIndex = 1   // Cameras
                else if (i === 2)   stack.currentIndex = 5   // Data Logger
                // else if (i === 3)   stack.currentIndex = 2   // AV Actions
                else if (i === 3)   stack.currentIndex = 3   // Terminal
                else if (i === 4)   stack.currentIndex = 4   // Settings
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
                color: HMI.Theme.surface
                border.color: HMI.Theme.outline
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: HMI.Theme.px(16)
                spacing: HMI.Theme.px(14)

                Item {
                    id: headerRow
                    Layout.fillWidth: true
                    height: HMI.Theme.px(44)

                    // LEFT: icons
                    Row {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: HMI.Theme.px(5)

                        StatusIcon { kind: "lan";      on: NavigationBackend.lanOn }
                        StatusIcon { kind: "gnss";     on: NavigationBackend.gnssOn }
                        StatusIcon { kind: "internet"; on: typeof InternetBackend !== "undefined" ? InternetBackend.internetOn : false }
                        StatusIcon { kind: "can";      on: NavigationBackend.canLoggerOn }
                        StatusIcon { kind: "auto";     on: NavigationBackend.autoOn }
                    }

                    // CENTER: title (stays centered)
                    Label {
                        id: pageTitle
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom

                        text: stack.currentIndex === 0 ? "Map"
                             : stack.currentIndex === 1 ? "Cameras"
                             : stack.currentIndex === 2 ? "AV Actions"
                             : stack.currentIndex === 3 ? "Terminal"
                             : stack.currentIndex === 4 ? "Settings"
                             : stack.currentIndex === 5 ? "Data Logger"
                             : "Map"

                        color: HMI.Theme.text
                        font.pixelSize: HMI.Theme.px(34)
                        font.bold: true
                        font.family: HMI.Theme.fontDisplay
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
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

                    HMI.MapPage {}
                    HMI.CamerasPage {}
                    HMI.AVActionsPage { id: avActionsPage }
                    HMI.TerminalPage {}
                    HMI.SettingsPage {}
                    HMI.LoggerPage {
                        id: loggerPage
                        onShowCanBusDisabledWarning: avWarnPage.openCustomWarning(
                            "No CAN traffic",
                            "Connect the CAN logger (port 6003) and wait for incoming data to enable bus selection."
                        )
                    }
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

                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: HMI.Theme.px(44)
                    Layout.minimumHeight: HMI.Theme.px(44)
                
                    Label {
                        id: rightPanelTitle
                        anchors.fill: parent
                        text: stack.currentIndex === 0 ? (rightPanelEngaged ? "AV Panel" : "Destinations")
                                                       : "Data monitor"
                        color: HMI.Theme.text
                        font.pixelSize: HMI.Theme.px(28)
                        font.bold: true
                        font.family: HMI.Theme.fontDisplay
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                        wrapMode: Text.NoWrap
                    }
                }

                StackLayout {
                    id: rightStack
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    currentIndex: stack.currentIndex === 0 ? (rightPanelEngaged ? 2 : 1) : 0

                    // index 0 — telemetry table (other pages)
                    HMI.DataTable {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        rows: telemetryModel
                    }

                    // index 1 — destination list (Map, not engaged)
                    HMI.DestList {
                        id: destList
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        onDestinationSelected: function(label) {
                            avWarnPage.openForDestination(label)
                        }
                    }

                    // index 2 — AV panel (Map, engaged)
                    HMI.AVPanel {
                        id: avPanel
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        rows: telemetryModel
                        onDisengageRequested: {
                            avActionsPage.avEngaged = false
                            avActionsPage.avTargetEngaged = false
                            avActionsPage.avPending = false
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
            color: HMI.Theme.surface
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
                if (statusIcon.kind === "auto")     return base + (statusIcon.on ? "auto_on.svg"     : "auto_off.svg")
                if (statusIcon.kind === "sensors")  return base + (statusIcon.on ? "sensors_on.svg"  : "sensors_off.svg")
                if (statusIcon.kind === "internet") return base + (statusIcon.on ? "internet_on.svg" : "internet_off.svg")
                if (statusIcon.kind === "gnss")     return base + (statusIcon.on ? "gnss_on.svg"     : "gnss_off.svg")
                if (statusIcon.kind === "lan")      return base + (statusIcon.on ? "lan_on.svg"      : "lan_off.svg")
                if (statusIcon.kind === "can")      return base + (statusIcon.on ? "can_on.svg"      : "can_off.svg")
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
            if (s === 1)  return HMI.Theme.center   // STARTUP
            return HMI.Theme.surface   // DEFAULT and others
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



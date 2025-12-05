// MapPage.qml
import QtQuick
import QtQuick.Controls
import QtLocation
import QtPositioning
import QtQuick.Layouts
import QtQuick.Shapes

Item {
    id: root
    // If you inject the maps dir from C++:  property url mapDir: HMIMapsDirUrl
    // TEMP absolute for dev on Windows; change to HMIMapsDirUrl for deploy.
    property url mapDir: "file:///home/hmi/HMI/maps/"
    property real   defaultZoom: 19
    property string currentRegion: ""
    property bool   initialFixApplied: false

    // Vehicle state
    property var  vehicleCoord: QtPositioning.coordinate(39.9984648, -83.0323994)
    property real vehicleHeading: 0.0            // keep north-up for now
    property bool followVehicle: true

    // Perception objects
    property var  perceptionObjects: []

    // Dynamic marker size vs zoom (~28 px at z18)
    property real carSize: Math.max(22, Math.min(56, 24 + (mapView.zoomLevel - 16) * 6))

    Layout.fillWidth: true
    Layout.fillHeight: true

    function updateVehicleFix(lat, lon) {
        vehicleCoord = QtPositioning.coordinate(lat, lon)
        carMarker.coordinate = vehicleCoord   // REQUIRED
        if (followVehicle)
            mapView.center = vehicleCoord
    }

    Connections {
        target: NavigationBackend

        // Called 10Hz
        function onUpdated() {
            // Update chevron position
            updateVehicleFix(
                NavigationBackend.currentLat,
                NavigationBackend.currentLon
            )

            // (Optional) update rotation later when we add heading)
            carMarker.rotation = NavigationBackend.headingDeg
        }

        // Called 1Hz (or whenever new waypoint batch arrives)
        function onWaypointsUpdated() {
            console.log("Waypoints updated!")

            // NavigationBackend.waypointPath()
            // returns list of QGeoCoordinate items
            routeLine.path = NavigationBackend.waypointPath()
        }

        // Called whenever perception objects are updated
        function onPerceptionUpdated() {
            console.log("Perception updated!")
            perceptionObjects = NavigationBackend.perceptionObjects()
            objectRepeater.model = perceptionObjects.length
        }
    }



    // ---------- OSM plugin (OFFLINE MBTiles) ----------
    Plugin {
        id: osmPlugin
        name: "osm"
        // Both may be file:/// URLs here; we avoid custom cache param to silence warnings.
        PluginParameter { name: "osm.mapping.offline.directory"; value: mapDir }
        PluginParameter { id: dbParam; name: "osm.mapping.offline.database"; value: mapDir + "mcity.mbtiles" }

        // keep online providers disabled so it never fetches from net
        PluginParameter { name: "osm.mapping.providersrepository.disabled"; value: true }
        PluginParameter { name: "osm.mapping.highdpi_tiles"; value: true }
    }

    // ------------------ Map ------------------
    Map {
        id: mapView
        anchors.fill: parent
        plugin: osmPlugin
        zoomLevel: defaultZoom
        center: QtPositioning.coordinate(39.99846475680883, -83.03239944474197)

        // Smooth recenter animation
        NumberAnimation { id: recLat;  target: mapView; property: "center.latitude";  duration: 450; easing.type: Easing.OutCubic }
        NumberAnimation { id: recLon;  target: mapView; property: "center.longitude"; duration: 450; easing.type: Easing.OutCubic }
        function recenterToVehicle() {
            recLat.from = mapView.center.latitude
            recLat.to   = vehicleCoord.latitude
            recLon.from = mapView.center.longitude
            recLon.to   = vehicleCoord.longitude
            recLat.start(); recLon.start()
            mapView.zoomLevel = defaultZoom
            followVehicle = true
        }

        MapQuickItem {
            id: carMarker
            coordinate: vehicleCoord
            visible: true
            z: 9999

            anchorPoint.x: carShape.width / 2
            anchorPoint.y: carShape.height / 2

            sourceItem: Rectangle {
                id: carShape
                width: root.carSize        // dynamic size
                height: root.carSize
                color: "transparent"

                Canvas {
                    id: chevronCanvas
                    anchors.fill: parent
                    onPaint: {
                        var ctx = getContext("2d")
                        ctx.clearRect(0, 0, width, height)

                        ctx.strokeStyle = "#ba0c2f"
                        ctx.fillStyle = "#ba0c2f"
                        ctx.lineWidth = width * 0.12
                        ctx.lineJoin = "round"

                        ctx.beginPath()
                        ctx.moveTo(width/2, height*0.1)
                        ctx.lineTo(width*0.85, height*0.9)
                        ctx.lineTo(width/2, height*0.65)
                        ctx.lineTo(width*0.15, height*0.9)
                        ctx.closePath()

                        ctx.stroke()
                        ctx.fill()
                    }
                }
            }
        }


        MapPolyline {
            id: routeLine
            line.width: 6
            line.color: "#0081ff"
            opacity: 0.9
            z: 5000
            path: []
        }

        // Perception CAN signals display (bottom-left corner)
        Rectangle {
            id: perceptionPanel
            width: 300
            height: Math.min(perceptionObjects.length * 35 + 40, 400)
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            anchors.margins: 16
            color: "#1A1A2E"
            border.color: "#16C784"
            border.width: 2
            radius: 8
            visible: perceptionObjects.length > 0
            z: 7000

            Column {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 8

                Text {
                    text: "CAN Signals (" + perceptionObjects.length + ")"
                    color: "#16C784"
                    font.pixelSize: 14
                    font.weight: Font.Bold
                }

                Flickable {
                    width: parent.width
                    height: parent.height - 40
                    contentHeight: signalColumn.height
                    clip: true

                    Column {
                        id: signalColumn
                        width: parent.width
                        spacing: 6

                        Repeater {
                            model: perceptionObjects

                            Rectangle {
                                width: signalColumn.width
                                height: 28
                                color: "#0F3460"
                                border.color: "#16C784"
                                border.width: 1
                                radius: 4

                                Column {
                                    anchors.fill: parent
                                    anchors.margins: 4
                                    spacing: 1

                                    Text {
                                        text: modelData.name + ": " + modelData.value
                                        color: "#16C784"
                                        font.pixelSize: 9
                                        font.family: "Courier"
                                    }

                                    Text {
                                        text: "CAN ID: " + modelData.canId + " | " + modelData.messageName
                                        color: "#A0A0A0"
                                        font.pixelSize: 7
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }


        // Kinetic panning (Qt 6.9: no MapGestureArea)
        MouseArea {
            id: mouseArea
            anchors.fill: parent

            // Feel tuning
            property real friction: 0.94
            property real minSpeed: 0.04
            property int  sampleCount: 5

            // State
            property var  lastPos
            property real vx: 0
            property real vy: 0
            property var  dxSamples: []
            property var  dySamples: []
            property bool dragging: false

            Timer {
                id: kineticTimer
                interval: 16; repeat: true; running: false
                onTriggered: {
                    if (Math.abs(mouseArea.vx) < mouseArea.minSpeed &&
                        Math.abs(mouseArea.vy) < mouseArea.minSpeed) {
                        running = false; mouseArea.vx = 0; mouseArea.vy = 0; return
                    }
                    mapView.pan(-mouseArea.vx, -mouseArea.vy)
                    mouseArea.vx *= mouseArea.friction
                    mouseArea.vy *= mouseArea.friction
                }
            }

            onPressed: {
                followVehicle = false
                dragging = true
                kineticTimer.running = false
                dxSamples = []; dySamples = []
                lastPos = Qt.point(mouse.x, mouse.y)
                vx = 0; vy = 0
            }

            onPositionChanged: {
                if (!dragging) return
                var dx = mouse.x - lastPos.x
                var dy = mouse.y - lastPos.y
                mapView.pan(-dx, -dy)
                lastPos = Qt.point(mouse.x, mouse.y)
                dxSamples.push(dx); if (dxSamples.length > sampleCount) dxSamples.shift()
                dySamples.push(dy); if (dySamples.length > sampleCount) dySamples.shift()
            }

            onReleased: {
                dragging = false
                var sx = 0, sy = 0
                for (var i=0; i<dxSamples.length; ++i) { sx += dxSamples[i]; sy += dySamples[i] }
                vx = dxSamples.length ? sx / dxSamples.length : 0
                vy = dySamples.length ? sy / dySamples.length : 0
                kineticTimer.running = true
            }

            onWheel: mapView.zoomLevel += wheel.angleDelta.y > 0 ? 0.5 : -0.5
        }
    }

    // ---------- Re-center floating pill ----------
    Rectangle {
        id: recenterPill
        width: 190; height: 50
        radius: height / 2
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 16
        color: "#FFFFFF"
        border.color: "#AFADAE"
        border.width: 1
        antialiasing: true
        visible: !followVehicle

        property bool pressed: false
        scale: pressed ? 0.98 : 1.0
        Behavior on scale { NumberAnimation { duration: 90 } }

        Row {
            anchors.centerIn: parent
            spacing: 12

            Shape {
                width: 24; height: 24
                layer.enabled: true; layer.smooth: true
                ShapePath {
                    strokeWidth: 2.3
                    strokeColor: "#04768A"
                    fillColor: "transparent"
                    capStyle: ShapePath.RoundCap
                    joinStyle: ShapePath.RoundJoin
                    startX: 12; startY: 3
                    PathLine { x: 21; y: 21 }
                    PathLine { x: 12; y: 16 }
                    PathLine { x: 3;  y: 21 }
                    PathLine { x: 12; y: 3 }
                }
            }

            Text {
                text: "Re-center"
                color: "#04768A"
                font.pixelSize: 18
                font.weight: Font.DemiBold
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onPressed:  recenterPill.pressed = true
            onCanceled: recenterPill.pressed = false
            onReleased: {
                recenterPill.pressed = false
                mapView.recenterToVehicle()
            }
        }
    }


    // ---------- Region switching (update ONLY dbParam.value) ----------
    function loadRegion(regionName, lat, lon) {
        if (currentRegion === regionName) return
        const fileUrl = mapDir + regionName + ".mbtiles"
        currentRegion = regionName
        dbParam.value = fileUrl
        mapView.center = QtPositioning.coordinate(lat, lon)
        mapView.zoomLevel = defaultZoom
        console.log("Loaded region:", regionName, "from", fileUrl)
    }

    function detectRegion(lat, lon) {
        var region = ""
        if (lat > 42.285 && lat < 42.315 && lon > -83.730 && lon < -83.700) {
            region = "mcity"
        } else if (lat > 39.97 && lat < 40.06 && lon > -83.08 && lon < -82.98) {
            region = "osu"
        } else if (lat > 40.25 && lat < 40.38 && lon > -83.40 && lon < -83.28) {
            region = "trc"
        } else {
            console.warn("No region match; defaulting to mcity")
            region = "mcity"
        }
        loadRegion(region, lat, lon)
    }

    // Call this ONCE with the first GPS fix
    function applyInitialGps(lat, lon, heading) {
        if (initialFixApplied) return
        initialFixApplied = true
        detectRegion(lat, lon)
        updateVehicleFix(lat, lon, heading)
    }

    Component.onCompleted: {
        console.log("Using MBTiles dir:", mapDir)
        applyInitialGps(39.99846475680883, -83.03239944474197, 0) // OSU
    }
}

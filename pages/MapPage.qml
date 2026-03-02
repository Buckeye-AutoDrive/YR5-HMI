// MapPage.qml
import QtQuick
import QtQuick.Controls
import QtLocation
import QtPositioning
import QtQuick.Layouts
import QtQuick.Shapes

Item {
    id: root
    property url mapDir: HMIMapsDirUrl
    // Plain path for OSM plugin (offline). On Linux, use Settings localSourcePath + /maps/ when set (e.g. Docker /home/hmi/YR5-HMI/maps/)
    property string mapDirPath: {
        if (typeof Qt !== "undefined" && Qt.platform && Qt.platform.os === "linux"
            && typeof SettingsBackend !== "undefined" && SettingsBackend.localSourcePath) {
            var p = String(SettingsBackend.localSourcePath).replace(/\/+$/, "")
            return p ? (p + "/maps/") : (typeof HMIMapsDirPath !== "undefined" ? HMIMapsDirPath : (mapDir.toString().replace(/^file:\/\//, "")))
        }
        return typeof HMIMapsDirPath !== "undefined" ? HMIMapsDirPath : (mapDir.toString().replace(/^file:\/\//, ""))
    }
    property real   defaultZoom: 19
    property string currentRegion: ""
    property bool   initialFixApplied: false

    // Vehicle state
    property var  vehicleCoord: QtPositioning.coordinate(39.9984648, -83.0323994)
    // property var  vehicleCoord: QtPositioning.coordinate(40.1918700, -83.3336600)

    property real vehicleHeading: 0.0            // keep north-up for now
    property bool followVehicle: true
    property bool map3dEnabled: (typeof SettingsBackend !== "undefined") ? SettingsBackend.map3dEnabled : false
    property var  defaultCenter: QtPositioning.coordinate(39.99846475680883, -83.03239944474197)
    property real defaultTilt3d: 50
    property var routePath: []

    // Dynamic marker size vs zoom (~28 px at z18)
    property real carSize: Math.max(22, Math.min(56, 24 + (mapView.zoomLevel - 16) * 6))
    property real carSize3d: Math.max(24, Math.min(60, 26 + (mapView3d.zoomLevel - 16) * 5))

    Layout.fillWidth: true
    Layout.fillHeight: true

    function activeMap() {
        return root.map3dEnabled ? mapView3d : mapView
    }

    function normalizeHeading(deg) {
        var h = deg % 360
        if (h < 0) h += 360
        return h
    }

    function recenterActiveMap() {
        if (root.map3dEnabled) {
            mapView3d.center = vehicleCoord
            mapView3d.zoomLevel = Math.min(22, defaultZoom + 1.5)
            mapView3d.bearing = normalizeHeading(vehicleHeading)
            mapView3d.tilt = defaultTilt3d
            followVehicle = true
            return
        }
        mapView.recenterToVehicle()
    }

    function updateVehicleFix(lat, lon) {
        vehicleCoord = QtPositioning.coordinate(lat, lon)
        carMarker.coordinate = vehicleCoord   // REQUIRED
        carMarker3d.coordinate = vehicleCoord
        if (followVehicle)
            activeMap().center = vehicleCoord
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

            // Keep 2D and 3D cursors in sync
            vehicleHeading = NavigationBackend.headingDeg
            carMarker.rotation = vehicleHeading
            mapView3d.bearing = normalizeHeading(vehicleHeading)
            // In 3D mode map bearing already tracks heading; compensate marker so heading is not double-applied.
            carMarker3d.rotation = vehicleHeading - mapView3d.bearing
            mapView3d.tilt = defaultTilt3d
        }

        // Called 1Hz (or whenever new waypoint batch arrives)
        function onWaypointsUpdated() {
            console.log("Waypoints updated!")

            // NavigationBackend.waypointPath()
            // returns list of QGeoCoordinate items
            routePath = NavigationBackend.waypointPath()
        }
    }



    // ---------- OSM plugin (OFFLINE MBTiles) ----------
    // Use mapDirPath (filesystem path) so the plugin finds offline tiles without internet (Qt expects path, not file:// URL)
    Plugin {
        id: osmPlugin
        name: "osm"
        PluginParameter { name: "osm.mapping.offline.directory"; value: mapDirPath }
        PluginParameter { id: dbParam; name: "osm.mapping.offline.database"; value: mapDirPath + "mcity.mbtiles" }

        // keep online providers disabled so it never fetches from net
        PluginParameter { name: "osm.mapping.providersrepository.disabled"; value: true }
        PluginParameter { name: "osm.mapping.highdpi_tiles"; value: true }
    }

    // ------------------ Map ------------------
    Map {
        id: mapView
        anchors.fill: parent
        visible: !root.map3dEnabled
        plugin: osmPlugin
        zoomLevel: defaultZoom
        center: defaultCenter

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
            path: routePath
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

    // 3D map view (tilted) with procedural cursor synced to same vehicle dynamics
    Map {
        id: mapView3d
        anchors.fill: parent
        visible: root.map3dEnabled
        plugin: osmPlugin
        zoomLevel: Math.min(22, defaultZoom + 1.5)
        center: defaultCenter
        bearing: vehicleHeading
        tilt: defaultTilt3d

        MapQuickItem {
            id: carMarker3d
            coordinate: vehicleCoord
            visible: true
            z: 9999

            anchorPoint.x: carShape3d.width / 2
            anchorPoint.y: carShape3d.height / 2

            sourceItem: Item {
                id: carShape3d
                width: root.carSize3d
                height: root.carSize3d
                transform: [
                    Rotation {
                        origin.x: carShape3d.width / 2
                        origin.y: carShape3d.height / 2
                        axis.x: 1; axis.y: 0; axis.z: 0
                        angle: Math.max(0, (mapView3d.tilt - 25) * 0.55)
                    }
                ]

                Canvas {
                    anchors.fill: parent
                    onPaint: {
                        var ctx = getContext("2d")
                        ctx.clearRect(0, 0, width, height)

                        // Back layer for depth effect (procedural pseudo-3D)
                        ctx.fillStyle = "#7d0a21"
                        ctx.beginPath()
                        ctx.moveTo(width * 0.52, height * 0.18)
                        ctx.lineTo(width * 0.87, height * 0.90)
                        ctx.lineTo(width * 0.52, height * 0.72)
                        ctx.lineTo(width * 0.17, height * 0.90)
                        ctx.closePath()
                        ctx.fill()

                        // Front layer (same red family as 2D cursor)
                        ctx.fillStyle = "#ba0c2f"
                        ctx.beginPath()
                        ctx.moveTo(width * 0.50, height * 0.10)
                        ctx.lineTo(width * 0.82, height * 0.82)
                        ctx.lineTo(width * 0.50, height * 0.62)
                        ctx.lineTo(width * 0.18, height * 0.82)
                        ctx.closePath()
                        ctx.fill()
                    }
                }
            }
        }

        MapPolyline {
            id: routeLine3d
            line.width: 6
            line.color: "#0081ff"
            opacity: 0.92
            z: 5000
            path: routePath
        }

        // Touch-first camera controls:
        //  - one finger: pan
        //  - two fingers: pinch zoom + pan
        MultiPointTouchArea {
            id: touch3d
            anchors.fill: parent
            minimumTouchPoints: 1
            maximumTouchPoints: 2
            mouseEnabled: false

            property real lastCenterX: 0
            property real lastCenterY: 0
            property real lastDistance: 0
            property int lastCount: 0

            function clamp(v, lo, hi) { return Math.max(lo, Math.min(hi, v)) }
            function dist(a, b) {
                var dx = a.x - b.x
                var dy = a.y - b.y
                return Math.sqrt(dx*dx + dy*dy)
            }

            onPressed: (points) => {
                if (!points || points.length === 0) return
                lastCount = points.length
                if (points.length === 1) {
                    lastCenterX = points[0].x
                    lastCenterY = points[0].y
                    lastDistance = 0
                } else {
                    lastCenterX = (points[0].x + points[1].x) * 0.5
                    lastCenterY = (points[0].y + points[1].y) * 0.5
                    lastDistance = dist(points[0], points[1])
                }
            }

            onUpdated: (points) => {
                if (!points || points.length === 0) return

                if (points.length === 1) {
                    var p = points[0]
                    if (lastCount !== 1) {
                        lastCenterX = p.x
                        lastCenterY = p.y
                    }
                    var dx = p.x - lastCenterX
                    var dy = p.y - lastCenterY

                    mapView3d.pan(-dx, -dy)

                    lastCenterX = p.x
                    lastCenterY = p.y
                    followVehicle = false
                } else {
                    var p0 = points[0]
                    var p1 = points[1]
                    var cx = (p0.x + p1.x) * 0.5
                    var cy = (p0.y + p1.y) * 0.5
                    var d = dist(p0, p1)

                    if (lastCount >= 2) {
                        if (lastDistance > 0) {
                            var ratio = d / lastDistance
                            mapView3d.zoomLevel = clamp(mapView3d.zoomLevel + (Math.log(ratio) / Math.log(2)), 3, 22)
                        }
                        mapView3d.pan(-(cx - lastCenterX), -(cy - lastCenterY))
                    }

                    lastCenterX = cx
                    lastCenterY = cy
                    lastDistance = d
                    followVehicle = false
                }

                lastCount = points.length
            }

            onReleased: (points) => {
                lastCount = points ? points.length : 0
                if (lastCount < 2)
                    lastDistance = 0
            }
        }

        WheelHandler {
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            onWheel: (event) => {
                mapView3d.zoomLevel = Math.max(3, Math.min(22, mapView3d.zoomLevel + (event.angleDelta.y > 0 ? 0.4 : -0.4)))
                followVehicle = false
            }
        }

        // Desktop/laptop drag pan support (for testing without touch)
        MouseArea {
            anchors.fill: parent
            enabled: root.map3dEnabled
            property var lastPos
            onPressed: {
                lastPos = Qt.point(mouse.x, mouse.y)
                followVehicle = false
            }
            onPositionChanged: {
                if (!pressed) return
                var dx = mouse.x - lastPos.x
                var dy = mouse.y - lastPos.y
                mapView3d.pan(-dx, -dy)
                lastPos = Qt.point(mouse.x, mouse.y)
            }
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
                recenterActiveMap()
            }
        }
    }


    // ---------- Region switching (update ONLY dbParam.value) ----------
    function loadRegion(regionName, lat, lon) {
        if (currentRegion === regionName) return
        const filePath = mapDirPath + regionName + ".mbtiles"
        currentRegion = regionName
        dbParam.value = filePath
        mapView.center = QtPositioning.coordinate(lat, lon)
        mapView.zoomLevel = defaultZoom
        mapView3d.center = QtPositioning.coordinate(lat, lon)
        mapView3d.zoomLevel = Math.min(22, defaultZoom + 1.5)
        console.log("Loaded region:", regionName, "from", filePath)
    }

    onMap3dEnabledChanged: {
        if (followVehicle)
            activeMap().center = vehicleCoord
    }

    function detectRegion(lat, lon) {
        var region = ""
        if (lat >= 42.2981 && lat <= 42.3033 &&
            lon >= -83.7018 && lon <= -83.6933) {
            region = "mcity"
        } else if (lat >= 39.9904 && lat <= 40.0232 &&
                   lon >= -83.0533 && lon <= -83.0058) {
            region = "osu"
        } else if (lat >= 40.2764 && lat <= 40.3304 &&
                   lon >= -83.5829 && lon <= -83.5162) {
            region = "trc"
        } else {
            console.warn("No region match; defaulting to mcity. lat/lon:", lat, lon)
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
        console.log("Using MBTiles dir:", mapDir, "path:", mapDirPath)
        applyInitialGps(39.99846475680883, -83.03239944474197, 0) // OSU
    }
}

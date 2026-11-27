import QtQuick
import QtQuick.Layouts
import QtPositioning

import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.core as PlasmaCore


PlasmoidItem {
    id: root

    property var weatherData: null
    property var nearestStation: null
    property string forecast: ""
    property string validPeriod: ""

    preferredRepresentation: fullRepresentation
    Plasmoid.backgroundHints: PlasmaCore.Types.ShadowBackground | PlasmaCore.Types.ConfigurableBackground

    PositionSource {
        id: positionSource
        active: true
        updateInterval: 60000

        onPositionChanged: root.updateNearestStation()
    }

    function distance(lat1, lon1, lat2, lon2) {
        const rad = Math.PI / 180
        const dLat = (lat2 - lat1) * rad
        const dLon = (lon2 - lon1) * rad

        const a =
            Math.sin(dLat / 2) ** 2 +
            Math.cos(lat1 * rad) *
            Math.cos(lat2 * rad) *
            Math.sin(dLon / 2) ** 2

        return 6371000 * 2 * Math.atan2(
            Math.sqrt(a),
            Math.sqrt(1 - a)
        )
    }

    function updateNearestStation() {
        if (!weatherData || !positionSource.position.coordinate.isValid)
            return

        const coordinate = positionSource.position.coordinate
        const areas = weatherData.area_metadata
        const item = weatherData.items[0]

        let nearest = null
        let minDistance = Infinity

        for (const area of areas) {
            const d = distance(
                coordinate.latitude,
                coordinate.longitude,
                area.label_location.latitude,
                area.label_location.longitude
            )

            if (d < minDistance) {
                minDistance = d

                nearest = {
                    name: area.name,
                    distance: d
                }
            }
        }

        nearestStation = nearest

        if (nearest) {
            const match = item.forecasts.find(
                f => f.area === nearest.name
            )

            forecast = match?.forecast ?? ""
        }

        const start = new Date(item.valid_period.start)
        const end = new Date(item.valid_period.end)

        validPeriod =
            Qt.formatDateTime(start, "h:mm AP") +
            " – " +
            Qt.formatDateTime(end, "h:mm AP")
    }

    function refresh() {
        const xhr = new XMLHttpRequest()

        xhr.open(
            "GET",
            "https://api.data.gov.sg/v1/environment/2-hour-weather-forecast"
        )

        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return

            if (xhr.status !== 200)
                return

            try {
                const data = JSON.parse(xhr.responseText)

                if (!data.items?.length)
                    return

                weatherData = data
                updateNearestStation()
            } catch (error) {
                console.warn("NEA forecast:", error)
            }
        }

        xhr.send()
    }

    Timer {
        interval: 5 * 60 * 1000
        running: true
        repeat: true
        triggeredOnStart: true

        onTriggered: root.refresh()
    }

    fullRepresentation: Item {
        Layout.minimumWidth: 180
        Layout.minimumHeight: 100

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 4

            PlasmaComponents.Label {
                Layout.alignment: Qt.AlignHCenter
                text: "2-Hour Nowcast"
                color: "gray"
            }

            PlasmaComponents.Label {
                Layout.alignment: Qt.AlignHCenter
                font.bold: true
                font.pointSize: 20
                text: root.forecast || "Loading..."
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                visible: root.nearestStation !== null
                spacing: 4

                PlasmaComponents.Label {
                    text: root.nearestStation?.name ?? ""
                }

                PlasmaComponents.Label {
                    color: "gray"
                    text: root.nearestStation
                        ? `(${(root.nearestStation.distance / 1000).toFixed(1)} km)`
                        : ""
                }
            }

            PlasmaComponents.Label {
                Layout.alignment: Qt.AlignHCenter
                color: "gray"
                text: root.validPeriod
            }
        }
    }
}
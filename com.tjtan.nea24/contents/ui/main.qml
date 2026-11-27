import QtQuick
import QtQuick.Layouts
import QtPositioning

import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents

PlasmoidItem {
    id: root

    preferredRepresentation: fullRepresentation

    property var forecast: null

    readonly property string region: getRegion(
        positionSource.position.coordinate.latitude,
        positionSource.position.coordinate.longitude
    )

    PositionSource {
        id: positionSource
        active: true
        updateInterval: 60000
    }

    function getRegion(lat, lon) {
        if (!isFinite(lat) || !isFinite(lon))
            return ""

        const regions = [
            { name: "north",   lat: 1.418, lon: 103.82 },
            { name: "south",   lat: 1.290, lon: 103.82 },
            { name: "east",    lat: 1.350, lon: 103.94 },
            { name: "west",    lat: 1.350, lon: 103.70 },
            { name: "central", lat: 1.350, lon: 103.82 }
        ]

        let nearest = ""
        let minDistance = Infinity

        for (const region of regions) {
            const distance =
                (lat - region.lat) ** 2 +
                (lon - region.lon) ** 2

            if (distance < minDistance) {
                minDistance = distance
                nearest = region.name
            }
        }

        return nearest
    }

    function refresh() {
        const xhr = new XMLHttpRequest()

        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return

            if (xhr.status !== 200) {
                console.warn("Forecast HTTP error:", xhr.status)
                return
            }

            try {
                const response = JSON.parse(xhr.responseText)
                root.forecast = response.data.records[0]
            } catch (error) {
                console.warn("Forecast parsing error:", error)
            }
        }

        xhr.open("GET",
            "https://api-open.data.gov.sg/v2/real-time/api/twenty-four-hr-forecast"
        )

        xhr.send()
    }

    Timer {
        interval: 30 * 60 * 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    fullRepresentation: Item {
        Layout.minimumWidth: 220
        Layout.minimumHeight: content.implicitHeight + 24

        ColumnLayout {
            id: content

            anchors.centerIn: parent
            spacing: 8

            // Region
            PlasmaComponents.Label {
                Layout.alignment: Qt.AlignHCenter
                opacity: 0.6

                text: root.region
                    ? "24-hour forecast · " +
                      root.region.charAt(0).toUpperCase() +
                      root.region.slice(1)
                    : "Determining location..."
            }

            // High and low temperatures
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                visible: root.forecast !== null
                spacing: 16

                PlasmaComponents.Label {
                    font.pointSize: 20

                    text: `↑ ${root.forecast?.general.temperature.high ?? ""}°C`
                }

                PlasmaComponents.Label {
                    font.pointSize: 20
                    opacity: 0.6

                    text: `↓ ${root.forecast?.general.temperature.low ?? ""}°C`
                }
            }

            // Forecast periods
            Repeater {
                model: root.region
                    ? (root.forecast?.periods ?? [])
                    : []

                delegate: ColumnLayout {
                    required property var modelData

                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 6

                    spacing: 2

                    PlasmaComponents.Label {
                        Layout.alignment: Qt.AlignHCenter
                        text: modelData.timePeriod.text
                        font.pointSize: 9
                        opacity: 0.6
                    }

                    PlasmaComponents.Label {
                        Layout.alignment: Qt.AlignHCenter
                        text: modelData.regions[root.region]?.text ?? ""
                        font.bold: true
                    }
                }
            }

            PlasmaComponents.Label {
                Layout.alignment: Qt.AlignHCenter
                visible: root.forecast === null
                text: "Loading forecast..."
                opacity: 0.6
            }
        }
    }
}
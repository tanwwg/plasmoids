import QtQuick
import QtQuick.Layouts
import QtPositioning
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.plasmoid

PlasmoidItem {
    id: root

    preferredRepresentation: fullRepresentation

    property var observations: null
    property string fetchError: ""
    readonly property var nearestStation: findNearestStation(
        observations, positionSource.position.coordinate)
    readonly property string statusMessage: {
        if (fetchError)
            return fetchError
        if (!positionSource.position.coordinate.isValid) {
            if (!positionSource.valid
                    || positionSource.sourceError !== PositionSource.NoError)
                return i18n("Location unavailable")
            return i18n("Finding your location…")
        }
        if (!observations)
            return i18n("Loading temperature…")
        return i18n("No station readings available")
    }

    function findNearestStation(data, coordinate) {
        if (!data || !coordinate.isValid)
            return null

        const temperatures = new Map()
        for (const reading of data.readings[0]?.data ?? []) {
            if (Number.isFinite(reading.value))
                temperatures.set(reading.stationId, reading.value)
        }

        let nearest = null
        for (const station of data.stations) {
            if (!station.location || !temperatures.has(station.id))
                continue

            const location = QtPositioning.coordinate(
                station.location.latitude, station.location.longitude)
            if (!location.isValid)
                continue

            const distance = coordinate.distanceTo(location)
            if (!nearest || distance < nearest.distance) {
                nearest = {
                    name: station.name,
                    temperature: temperatures.get(station.id),
                    distance: distance
                }
            }
        }
        return nearest
    }

    function fetchTemperature() {
        const request = new XMLHttpRequest()
        request.onreadystatechange = function() {
            if (request.readyState !== XMLHttpRequest.DONE)
                return

            try {
                if (request.status === 200) {
                    const response = JSON.parse(request.responseText)
                    if (response.code === 0
                            && Array.isArray(response.data?.stations)
                            && Array.isArray(response.data?.readings)) {
                        root.observations = response.data
                        root.fetchError = ""
                        return
                    }
                }
            } catch (error) {
                console.warn("Invalid NEA temperature response:", error)
            }
            root.fetchError = i18n("Unable to load temperature")
        }
        request.open("GET", "https://api-open.data.gov.sg/v2/real-time/api/air-temperature")
        request.send()
    }

    PositionSource {
        id: positionSource
        active: true
    }

    Timer {
        interval: 5 * 60 * 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.fetchTemperature()
    }

    fullRepresentation: Item {
        ColumnLayout {
            anchors.centerIn: parent
            spacing: 4
        
            PlasmaComponents.Label {
                Layout.alignment: Qt.AlignHCenter
                font.pointSize: 22
                visible: root.nearestStation !== null
                textFormat: Text.RichText
                text: root.nearestStation
                        ? `${root.nearestStation.temperature.toFixed(1)} <span style="font-size: 12pt"><sup>°C</sup></span>`
                        : ""
            }

            PlasmaComponents.Label {
                Layout.alignment: Qt.AlignHCenter
                visible: root.nearestStation !== null
                text: root.nearestStation?.name ?? ""
            }

            PlasmaComponents.Label {
                Layout.alignment: Qt.AlignHCenter
                color: "gray"
                visible: root.nearestStation !== null
                text: root.nearestStation
                    ? i18n("%1 km away", (root.nearestStation.distance / 1000).toLocaleString(Qt.locale(), "f", 2))
                    : ""
            }

            PlasmaComponents.Label {
                Layout.alignment: Qt.AlignHCenter
                visible: !root.nearestStation || root.fetchError !== ""
                text: root.statusMessage
            }
        }
    }
}

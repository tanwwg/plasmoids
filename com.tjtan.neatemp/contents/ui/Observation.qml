import QtQuick
import QtPositioning

QtObject {
    id: observation

    required property string endpoint
    required property var coordinate
    required property string loadingMessage
    required property string unavailableMessage
    required property string errorMessage

    property var data: null
    property string fetchError: ""
    readonly property var nearestStation: findNearestStation(data, coordinate)
    readonly property string statusMessage: {
        if (fetchError)
            return fetchError
        if (!coordinate.isValid || nearestStation)
            return ""
        return data ? unavailableMessage : loadingMessage
    }

    function findNearestStation(data, coordinate) {
        if (!data || !coordinate.isValid)
            return null

        const values = new Map()
        for (const reading of data.readings[0]?.data ?? []) {
            if (Number.isFinite(reading.value))
                values.set(reading.stationId, reading.value)
        }

        let nearest = null
        for (const station of data.stations) {
            const stationLocation = station.location ?? station.labelLocation
            if (!stationLocation || !values.has(station.id))
                continue

            const location = QtPositioning.coordinate(
                stationLocation.latitude, stationLocation.longitude)
            if (!location.isValid)
                continue

            const distance = coordinate.distanceTo(location)
            if (!nearest || distance < nearest.distance) {
                nearest = {
                    id: station.id,
                    name: station.name,
                    value: values.get(station.id),
                    distance: distance
                }
            }
        }
        return nearest
    }

    function refresh() {
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
                        observation.data = response.data
                        observation.fetchError = ""
                        return
                    }
                }
            } catch (error) {
                console.warn("Invalid NEA response for", observation.endpoint, error)
            }
            observation.fetchError = observation.errorMessage
        }
        request.open("GET", endpoint)
        request.send()
    }
}

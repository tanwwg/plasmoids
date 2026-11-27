import QtQuick
import QtQuick.Layouts
import QtPositioning
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.plasmoid

PlasmoidItem {
    id: root

    preferredRepresentation: fullRepresentation

    readonly property string locationStatus: {
        if (positionSource.position.coordinate.isValid)
            return ""
        if (!positionSource.valid || positionSource.sourceError !== PositionSource.NoError)
            return i18n("Location unavailable")
        return i18n("Finding your location…")
    }

    Observation {
        id: temperature
        endpoint: "https://api-open.data.gov.sg/v2/real-time/api/air-temperature"
        coordinate: positionSource.position.coordinate
        loadingMessage: i18n("Loading temperature…")
        unavailableMessage: i18n("No station readings available")
        errorMessage: i18n("Unable to load temperature")
    }

    Observation {
        id: humidity
        endpoint: "https://api-open.data.gov.sg/v2/real-time/api/relative-humidity"
        coordinate: positionSource.position.coordinate
        loadingMessage: i18n("Loading relative humidity…")
        unavailableMessage: i18n("No relative humidity readings available")
        errorMessage: i18n("Unable to load relative humidity")
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
        onTriggered: {
            temperature.refresh()
            humidity.refresh()
        }
    }

    fullRepresentation: Item {
        ColumnLayout {
            anchors.centerIn: parent
            spacing: 4
        
            PlasmaComponents.Label {
                Layout.alignment: Qt.AlignHCenter
                font.pointSize: 22
                visible: temperature.nearestStation !== null
                textFormat: Text.RichText
                text: temperature.nearestStation
                        ? `${temperature.nearestStation.value.toFixed(1)} <span style="font-size: 12pt"><sup>°C</sup></span>`
                        : ""
            }

            PlasmaComponents.Label {
                Layout.alignment: Qt.AlignHCenter
                visible: humidity.nearestStation !== null
                text: {
                    const station = humidity.nearestStation
                    if (!station)
                        return ""
                    const percentage = station.value.toLocaleString(Qt.locale(), "f", 1)
                    if (station.id === temperature.nearestStation?.id)
                        return i18n("%1% relative humidity", percentage)
                    return i18n("%1% relative humidity (%2)", percentage, station.name)
                }
            }

            PlasmaComponents.Label {
                Layout.alignment: Qt.AlignHCenter
                visible: temperature.nearestStation !== null
                text: temperature.nearestStation?.name ?? ""
            }

            PlasmaComponents.Label {
                Layout.alignment: Qt.AlignHCenter
                color: "gray"
                visible: temperature.nearestStation !== null
                text: temperature.nearestStation
                    ? i18n("%1 km away", (temperature.nearestStation.distance / 1000).toLocaleString(Qt.locale(), "f", 2))
                    : ""
            }

            PlasmaComponents.Label {
                Layout.alignment: Qt.AlignHCenter
                visible: text !== ""
                text: temperature.statusMessage || root.locationStatus
            }

            PlasmaComponents.Label {
                Layout.alignment: Qt.AlignHCenter
                visible: text !== ""
                text: humidity.statusMessage
            }
        }
    }
}

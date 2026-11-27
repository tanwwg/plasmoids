import QtQuick
import QtQuick.Layouts
import QtPositioning
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    Plasmoid.backgroundHints: PlasmaCore.Types.ShadowBackground | PlasmaCore.Types.ConfigurableBackground
    preferredRepresentation: fullRepresentation

    readonly property string locationStatus: {
        console.log(positionSource.name)

        if (positionSource.position.coordinate.isValid)
            return ""
        if (!positionSource.valid || positionSource.sourceError !== PositionSource.NoError)
            return i18n("Location unavailable")
        return i18n("Finding your location… ")
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

    Observation {
        id: windSpeed
        endpoint: "https://api-open.data.gov.sg/v2/real-time/api/wind-speed"
        coordinate: positionSource.position.coordinate
        loadingMessage: i18n("Loading wind speed…")
        unavailableMessage: i18n("No wind speed readings available")
        errorMessage: i18n("Unable to load wind speed")
    }

    Observation {
        id: rainfall
        endpoint: "https://api-open.data.gov.sg/v2/real-time/api/rainfall"
        coordinate: positionSource.position.coordinate
        loadingMessage: i18n("Loading rainfall…")
        unavailableMessage: i18n("No rainfall readings available")
        errorMessage: i18n("Unable to load rainfall")
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
            windSpeed.refresh()
            rainfall.refresh()
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

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 6
                visible: humidity.nearestStation !== null

                Kirigami.Icon {
                    source: Qt.resolvedUrl("../icons/humidity.svg")
                    Layout.preferredWidth: 20
                    Layout.preferredHeight: 20
                }
                PlasmaComponents.Label {
                    text: `${humidity.nearestStation.value}%`
                }

                Kirigami.Icon {
                    source:  Qt.resolvedUrl("../icons/wind.svg")
                    Layout.preferredWidth: 20
                    Layout.preferredHeight: 20
                    isMask: true
                    color: "white"
                }
                PlasmaComponents.Label {
                    text: `${(windSpeed.nearestStation.value * 1.852).toFixed(1)} km/h`
                }

            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 6
                visible: rainfall.nearestStation !== null && rainfall.nearestStation.value > 0              

                Kirigami.Icon {
                    source:  Qt.resolvedUrl("../icons/rainfall.svg")
                    Layout.preferredWidth: 20
                    Layout.preferredHeight: 20
                    isMask: true
                    color: "white"
                }

                PlasmaComponents.Label {
                    text: `${(rainfall.nearestStation.value).toFixed(1)} mm / 5 min`
                }
            }           

            PlasmaComponents.Label {
                Layout.alignment: Qt.AlignHCenter
                visible: temperature.nearestStation !== null
                textFormat: Text.RichText
                text: `${temperature.nearestStation.name} <span style="color: gray; font-size: 85%;">(${(temperature.nearestStation.distance / 1000).toFixed(1)} km)</span>`
            }
        }
    }
}

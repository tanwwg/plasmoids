import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore

PlasmoidItem {
    id: root

    width: 256
    height: 256

    
    preferredRepresentation: fullRepresentation
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground | PlasmaCore.Types.ConfigurableBackground

    property date currentTime: new Date()

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.currentTime = new Date()
    }

    fullRepresentation: Item {
        Column {
            anchors.centerIn: parent
            spacing: 4

            Item {
                anchors.horizontalCenter: parent.horizontalCenter

                width: clockText.implicitWidth
                height: clockText.implicitHeight * 2.0 * 0.8

                Text {
                    id: clockText

                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatTime(root.currentTime, "HH:mm")
                    font.family: "Noto Sans"
                    font.pixelSize: 128
                    font.weight: Font.Bold
                    color: Qt.rgba(0.9, 0.9, 0.9, 0.7)
                    style: Text.Raised
                    styleColor: "#80000000"

                    transform: Scale {
                        yScale: 2.0
                    }
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatDate(root.currentTime, "dddd, d MMMM")
                font.pixelSize: 14
                color: "#AABBCC"
                style: Text.Raised
                styleColor: "#80000000"
            }
        }
    }
}

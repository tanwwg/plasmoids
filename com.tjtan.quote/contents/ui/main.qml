import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore

PlasmoidItem {
    id: root

    preferredRepresentation: fullRepresentation
    Plasmoid.backgroundHints: PlasmaCore.Types.ShadowBackground | PlasmaCore.Types.ConfigurableBackground

    property string quote: "Loading..."
    property string author: ""

    function fetchQuote() {
        const xhr = new XMLHttpRequest()

        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return

            if (xhr.status === 200) {
                try {
                    const data = JSON.parse(xhr.responseText)
                    root.quote = data[0].q
                    root.author = data[0].a
                } catch (e) {
                    console.warn("Invalid quote response:", e)
                }
            } else {
                console.warn("HTTP error:", xhr.status)
            }
        }

        xhr.open("GET", "https://zenquotes.io/api/random")
        xhr.send()
    }

    Timer {
        interval: 60 * 60 * 1000
        running: true
        repeat: true
        triggeredOnStart: true

        onTriggered: root.fetchQuote()
    }

    ColumnLayout {
        anchors.centerIn: parent
        width: parent.width
        spacing: 8

        Text {
            padding: 8
            Layout.fillWidth: true
            Layout.fillHeight: true
            
            text: root.quote
            // text: "lorem ipsum dolor sit amet consectetur adipiscing elit minus temporibus pariatur officia aliqua quod in et et in veniam occaecat facilis nihil facilis quo at odio et est qui aliqua maxime eligendi cupidatat proident ducimus accusamus blanditiis voluptatum id assumenda labore nulla consequatur fugiat odio rerum facilis animi at quidem"
            font.pixelSize: 20
            fontSizeMode: Text.Fit
            minimumPixelSize: 1
            font.italic: true

            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            color: "white"
        }

        Text {
            text: root.author
            // text: "Author's name here"

            padding: 8
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignRight       
            font.pixelSize: 16
            color: "#99ffffff"
        }
    }

    // fullRepresentation: Rectangle {
    //     implicitWidth: 320
    //     implicitHeight: 180

    //     color: "#60303030"
    //     radius: 12

    //     ColumnLayout {
    //         anchors.fill: parent
    //         anchors.margins: 20
    //         spacing: 12

    //         Text {
    //             text: "QUOTE OF THE DAY"
    //             font.pixelSize: 11
    //             font.letterSpacing: 3
    //             color: "#99ffffff"
    //         }

    //         Text {
    //             Layout.fillWidth: true
    //             Layout.fillHeight: true

    //             text: "“" + root.quote + "”"
    //             wrapMode: Text.WordWrap
    //             verticalAlignment: Text.AlignVCenter
    //             font.pixelSize: 20
    //             font.weight: Font.Light
    //             font.italic: true
    //             color: "#ddffffff"
    //         }

    //         Text {
    //             Layout.alignment: Qt.AlignRight
    //             text: root.author
    //             font.pixelSize: 12
    //             color: "#99ffffff"
    //         }

    //         Text {
    //             Layout.alignment: Qt.AlignRight
    //             text: "ZenQuotes.io"
    //             font.pixelSize: 10
    //             color: "#99ffffff"

    //             // MouseArea {
    //             //     anchors.fill: parent
    //             //     onClicked: Qt.openUrlExternally(
    //             //         "https://zenquotes.io/"
    //             //     )
    //             // }
    //         }
    //     }
    // }
}
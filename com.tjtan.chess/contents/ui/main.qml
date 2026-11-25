
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls

import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore

PlasmoidItem {
    id: root

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    preferredRepresentation: fullRepresentation

    property string puzzleId: ""
    property int rating: 0
    property bool whiteToMove: true
    property bool loading: false
    property string errorMessage: ""
    property var squares: []

    property var pieces: ({
        "K": "♚", "Q": "♛", "R": "♜",
        "B": "♝", "N": "♞", "P": "\u265f\ufe0e",
        "k": "♚", "q": "♛", "r": "♜",
        "b": "♝", "n": "♞", "p": "\u265f\ufe0e"
    })

    Timer {
        interval: 60 * 60 * 1000
        running: true
        repeat: true
        onTriggered: root.fetchPuzzle()
    }

    function openPuzzle() {
        if (puzzleId !== "") {
            Qt.openUrlExternally(
                "https://lichess.org/training/" + puzzleId
            )
        }
    }

    function parseFen(fen) {
        let fields = fen.split(" ")
        let board = []

        for (let ch of fields[0]) {
            if (ch === "/")
                continue

                if (ch >= "1" && ch <= "8") {
                    for (let i = 0; i < Number(ch); i++)
                        board.push("")
                } else {
                    board.push(ch)
                }
        }

        if (board.length !== 64)
            throw new Error("Invalid FEN")

            whiteToMove = fields[1] === "w"

            if (!whiteToMove)
                board.reverse()

                squares = board
    }

    function fetchPuzzle() {
        if (loading)
            return

            loading = true
            errorMessage = ""

            let xhr = new XMLHttpRequest()

            xhr.onreadystatechange = function() {
                if (xhr.readyState !== XMLHttpRequest.DONE)
                    return

                    loading = false

                    if (xhr.status !== 200) {
                        errorMessage = "HTTP " + xhr.status
                        return
                    }

                    try {
                        let data = JSON.parse(xhr.responseText)

                        let fen = data.puzzle.fen ||
                        data.puzzle.initialFen ||
                        data.game.fen

                        if (!fen)
                            throw new Error("Missing puzzle FEN")

                            parseFen(fen)

                            puzzleId = data.puzzle.id
                            rating = data.puzzle.rating

                    } catch (e) {
                        errorMessage = e.message
                        console.log(xhr.responseText)
                    }
            }

            xhr.open(
                "GET",
                "https://lichess.org/api/puzzle/next?difficulty=normal"
            )

            xhr.setRequestHeader("Accept", "application/json")
            xhr.send()
    }

    Component.onCompleted: fetchPuzzle()

    fullRepresentation: Item {
        Layout.minimumWidth: 160
        Layout.minimumHeight: 200
        Layout.preferredWidth: 280
        Layout.preferredHeight: 330

        Rectangle {
            anchors.fill: parent
            color: "#55333333"
            radius: 12
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 8

            // Header

            RowLayout {
                Layout.fillWidth: true

                Text {
                    Layout.fillWidth: true

                    text: "Chess Puzzle"
                    color: "#ffffff"
                    font.pixelSize: 14
                    font.weight: Font.Medium
                }

                Text {
                    text: root.rating > 0
                    ? root.rating.toString()
                    : ""

                    color: "#99ffffff"
                    font.pixelSize: 12
                }

                Controls.ToolButton {
                    icon.name: "view-refresh"
                    enabled: !root.loading
                    onClicked: root.fetchPuzzle()

                    Controls.ToolTip.visible: hovered
                    Controls.ToolTip.text: "New puzzle"
                }
            }

            // Chessboard

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                Grid {
                    id: board

                    anchors.centerIn: parent

                    width: Math.min(
                        parent.width,
                        parent.height
                    )

                    height: width
                    columns: 8
                    rows: 8
                    spacing: 0

                    Repeater {
                        model: 64

                        Rectangle {
                            required property int index

                            width: board.width / 8
                            height: width

                            color: (
                                Math.floor(index / 8) +
                                index % 8
                            ) % 2 === 0
                            ? "#aab8ca"
                            : "#526781"

                            property string piece:
                            root.squares[index] || ""

                            property bool isWhite:
                            piece !== "" &&
                            piece === piece.toUpperCase()

                            Text {
                                anchors.centerIn: parent

                                // better align the piece
                                anchors.verticalCenterOffset: 5

                                text: root.pieces[
                                    parent.piece
                                ] || ""

                                font.family: "DejaVu Sans"
                                font.pixelSize:
                                parent.width * 0.85

                                color: parent.isWhite
                                ? "#ffffff"
                                : "#151b26"

                                style: Text.Outline

                                styleColor: parent.isWhite
                                ? "#303030"
                                : "#aaaaaa"
                            }
                        }
                    }
                }

                // Open puzzle in browser

                MouseArea {
                    id: boardMouse

                    anchors.fill: board
                    hoverEnabled: true

                    enabled: root.puzzleId !== "" &&
                    !root.loading

                    cursorShape: Qt.PointingHandCursor

                    onClicked: root.openPuzzle()
                }

                Controls.BusyIndicator {
                    anchors.centerIn: parent

                    running: root.loading
                    visible: running
                }
            }

            // Footer

            Text {
                Layout.fillWidth: true

                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap

                text: root.errorMessage !== ""
                ? root.errorMessage
                : root.loading
                ? "Finding a puzzle..."
                : root.whiteToMove
                ? "White to move"
                : "Black to move"

                color: "#ccffffff"
                font.pixelSize: 12
            }
        }
    }
}

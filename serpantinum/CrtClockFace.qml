import QtQuick
import Quickshell
import "../../reusables"
import "../../"

// Desktop widget: big 7-segment ASCII digits in terminal/CRT style,
// blinking colon, colors from the active theme. Transparent bg.
Item {
    id: root
    anchors.fill: parent
    clip: true

    property real minWidth: 120
    property real minHeight: 50
    property real maxWidth: 99999
    property real maxHeight: 99999
    property real minAspect: 1.0
    property real maxAspect: 12.0

    // 3x3 glyph atlas
    readonly property var atlas: ({
        "0": [" _ ", "| |", "|_|"],
        "1": ["  _", " |", " |"],
        "2": [" _ ", " _|", "|_ "],
        "3": [" _ ", " _|", " _|"],
        "4": ["   ", "|_|", "  |"],
        "5": [" _ ", "|_ ", " _|"],
        "6": [" _ ", "|_ ", "|_|"],
        "7": [" _ ", "  |", "  |"],
        "8": [" _ ", "|_|", "|_|"],
        "9": [" _ ", "|_|", " _|"],
        ":": ["   ", " • ", "   "],
        " ": ["   ", "   ", "   "]
    })

    property string hh: DateTime.timeLong.slice(0, 2)
    property string mm: DateTime.timeLong.slice(3, 5)
    property string ss: DateTime.timeLong.slice(6, 8)
    property bool blink: true
    property string timeStr: hh + (blink ? ":" : " ") + mm + (blink ? ":" : " ") + ss

    function sevenSeg() {
        var rows = ["", "", ""];
        for (var i = 0; i < timeStr.length; i++) {
            var g = atlas[timeStr[i]] || atlas[" "];
            for (var r = 0; r < 3; r++)
                rows[r] += g[r] + " ";
        }
        return rows.join("\n");
    }

    Timer {
        interval: 250
        running: root.visible
        repeat: true
        onTriggered: root.blink = !root.blink
    }

    Text {
        anchors.centerIn: parent
        font.family: "Iosevka Nerd Font"
        font.pixelSize: Math.max(
            6,
            Math.min(
                root.width * 0.9 / 25.0,
                root.height * 0.9 / 4.5
            )
        )
        color: ThemeBackend.text
        text: root.sevenSeg()
        textFormat: Text.PlainText
    }
}

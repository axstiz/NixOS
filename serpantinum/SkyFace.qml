import QtQuick
import Quickshell
import "../../reusables"
import "../../"

// Desktop widget: animated ASCII weather for serpantinum's Weather
// singleton (sun/moon/cloud/rain/snow/storm/mist frames, ~5 fps step,
// temp displayed under the art). Transparent background.
Item {
    id: root
    anchors.fill: parent
    clip: true

    property real minWidth: 60
    property real minHeight: 50
    property real maxWidth: 99999
    property real maxHeight: 99999
    property real minAspect: 0
    property real maxAspect: 99999

    property var frames: []
    property int frameIndex: 0
    property string condition: "loading"

    function categorize() {
        var ic = Weather.currentIcon || "";
        if (ic === "") return "loading";
        var cp = ic.codePointAt(0);
        if (cp === 0xF185) return "sunny";
        if (cp === 0xF186) return "night";
        if (cp === 0xF0597) return "rain";
        if (cp === 0xF2DC) return "snow";
        if (cp === 0xF0E7) return "storm";
        if (cp === 0xF0591) return "mist";
        if (cp === 0xF0C2) return "cloudy";
        return "cloudy";
    }

    readonly property var sets: ({
        "loading": [
            "     ~    ",
            "    ...   ",
            "     ·    ",
            "",
        ],
        "sunny": [
            "  \\ | /  ",
            "- - o - -",
            "  / | \\  ",
            "",
        ],
        "night": [
            "   _.._  ",
            "  ( --- )",
            "   `-''  ",
            "  *    * ",
        ],
        "cloudy": [
            "  .--. - ",
            " ( ).-). ",
            "(_(____) ",
            "",
        ],
        "mist": [
            "   ~~~~  ",
            " ------  ",
            "  ~~~~~  ",
            " ------- ",
        ],
        "rain": [
            "   .--.  ",
            "  ( -- ).",
            " (___(___",
            "  v v v  ",
            "   v  v  ",
        ],
        "snow": [
            "   .--.  ",
            "  ( -- ).",
            "  (___.. ",
            "  *   *  ",
            "     *   ",
        ],
        "storm": [
            "    .-.  ",
            "  (  __ ).",
            "  (____) ",
            "   ___/  ",
            "   `--'  ",
        ]
    })

    Timer {
        interval: 250
        running: root.visible
        repeat: true
        onTriggered: {
            var cond = root.categorize();
            if (cond !== root.condition) {
                root.condition = cond;
                root.frames = root.sets[cond] || root.sets["cloudy"];
                root.frameIndex = 0;
            }
            root.frameIndex = (root.frameIndex + 1) % Math.max(1, root.frames.length);
        }
    }

    Column {
        anchors.centerIn: parent
        spacing: Scaler.s(6)

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            font.family: "Iosevka Nerd Font"
            font.pixelSize: Math.max(
                8,
                Math.min(root.width * 0.9 / 12.0, root.height * 0.7 / 5.0)
            )
            color: ThemeBackend.mauve
            text: root.frames.length > 0 ? root.frames[root.frameIndex] : "   ·   "
            textFormat: Text.PlainText
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            font.family: ThemeBackend.fontFamily
            font.pixelSize: Scaler.s(15)
            color: ThemeBackend.text
            text: Weather.currentTempFormatted !== "" ? Weather.currentTempFormatted : "--°"
        }
    }
}

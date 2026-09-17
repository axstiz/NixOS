import QtQuick
import Quickshell
import Quickshell.Io
import "../../reusables"
import "../../"

// Desktop widget: the animated ASCII "brain" from that-ponderer/ZAPP
// (sharpshell/animations/brain, 898 monospace frames) rendered as a
// theme-aware serpantinum widget face.
// Frames are read once from ~/.local/share/brain-anim (installed by
// home-manager from the pinned ZAPP source tree, see zapp-brain).
Item {
    id: root
    anchors.fill: parent
    clip: true

    property real minWidth: 60
    property real minHeight: 40
    property real maxWidth: 99999
    property real maxHeight: 99999
    property real minAspect: 0
    property real maxAspect: 99999

    property var frames: []
    property int frameIndex: 0
    property bool loaded: false

    // ~30 FPS like the original sharpshell BRAIN_FPS/2 fallback
    Timer {
        id: rotator
        interval: 33
        repeat: true
        running: root.visible && root.loaded && root.frames.length > 0
        onTriggered: root.frameIndex = (root.frameIndex + 1) % root.frames.length
    }

    Process {
        id: frameLoader
        // Concatenate all frames, \f-separated, into a JSON array:
        // one shot at widget creation — no per-frame I/O afterwards.
        command: [
            "bash",
            "-c",
            "d=\"$HOME/.local/share/brain-anim\"; " +
            "[ -d \"$d\" ] || { echo '[]'; exit 0; }; " +
            "t=\"$(mktemp)\"; trap 'rm -f \"$t\"' EXIT; " +
            "for f in \"$d\"/0*; do " +
            "[ -f \"$f\" ] && { cat \"$f\"; printf '\\f'; }; " +
            "done > \"$t\"; " +
            "jq -Rsc 'rtrimstr(\"\\f\") | if length > 0 then split(\"\\f\") else [] end' \"$t\""
        ]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.frames = JSON.parse(this.text);
                } catch (e) {
                    root.frames = [];
                }
                root.loaded = true;
            }
        }
    }

    Text {
        anchors.centerIn: parent
        font.family: "Iosevka Nerd Font"
        font.pixelSize: Math.max(
            2,
            Math.min(
                root.width * 0.9 / 19.5,
                root.height * 0.9 / 16.5
            )
        )
        color: ThemeBackend.mauve
        text: root.loaded && root.frames.length > 0
              ? root.frames[root.frameIndex]
              : "loading..."
        textFormat: Text.PlainText
    }
}

import QtQuick
import Quickshell
import "../../reusables"
import "../../"

// Desktop widget: Matrix-style falling glyph rain (GPU edition).
// Each column = one trail Text + one head Text (no Canvas rasterization).
// As a column falls its trail fades out; the fade SPEED is random per
// column (seeded per column, re-randomized on respawn), so individual
// drops dissolve at visibly different rates. Transparent bg, pauses
// when hidden.
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

    readonly property real colCell: Math.max(14, Scaler.s(16))
    readonly property real rowCell: Math.max(14, Scaler.s(13))
    readonly property int columns: Math.max(2, Math.floor(width / colCell))
    readonly property int rowsCount: Math.ceil(height / rowCell) + 1
    readonly property color headColor: ThemeBackend.text
    readonly property color trailColor: ThemeBackend.mauve
    property string glyphPool: "ｦｧｨｩｪｫｬｭｮｯｰｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐﾑﾒﾓﾔﾕﾖﾗﾘﾙﾚﾛﾜ0123456789"

    property var cols: []
    property real lastT: 0
    property int rev: 0 // bumped on resize to force Repeater rebuild

    function newGlyphs() {
        var g = "";
        var len = Math.max(6, rowsCount + 6);
        for (var i = 0; i < len; i++)
            g += glyphPool[Math.floor(Math.random() * glyphPool.length)];
        return g;
    }

    function spawnColumn(cx) {
        return {
            y: -Math.random() * rowsCount * 2,
            speed: 4 + 8 * Math.random(),
            trail: 6 + Math.floor(Math.random() * Math.max(4, rowsCount - 4)),
            scope: rowsCount + Math.ceil(rowsCount * 0.4),
            fadeSpeed: 0.6 + Math.random() * 1.2, // per-column dissolve rate
            glyphs: newGlyphs()
        };
    }

    function seed() {
        cols = [];
        for (var i = 0; i < columns; i++)
            cols.push(spawnColumn(i));
        lastT = Date.now();
    }

    onColumnsChanged: { seed(); rev++; }
    onVisibleChanged: if (visible) lastT = Date.now();

    Timer {
        interval: 33
        repeat: true
        running: root.visible && root.columns > 0
        onTriggered: {
            var now = Date.now();
            var dt = Math.min(200, now - root.lastT) / 1000;
            root.lastT = now;
            var len = root.cols.length;
            for (var i = 0; i < len; i++) {
                var c = root.cols[i];
                c.y += c.speed * dt;
                if (c.y > c.scope) {
                    // respawn: fully faded out by then (per-column fadeSpeed)
                    root.cols[i] = root.spawnColumn(i);
                    c = root.cols[i];
                }
                var item = colsRepeater.itemAt(i);
                if (!item) continue;
                var prog = Math.min(1, Math.max(0, c.y / c.scope));
                item.setValue(c, prog);
            }
        }
    }

    Row {
        id: colsRow
        anchors.fill: parent
        clip: true

        Repeater {
            id: colsRepeater
            model: root.rev * 10000 + root.columns

            Item {
                id: colItem
                width: root.colCell
                height: root.height
                clip: true

                Text {
                    id: trailText
                    font.family: "Iosevka NF"
                    font.pixelSize: Math.max(10, root.rowCell * 1.02)
                    color: root.trailColor
                    opacity: 0.85
                    textFormat: Text.PlainText
                }
                Text {
                    id: headText
                    font.family: "Iosevka NF"
                    font.pixelSize: Math.max(10, root.rowCell * 1.02)
                    color: root.headColor
                    textFormat: Text.PlainText
                }

                function setValue(c, prog) {
                    var h = Math.floor(c.y);
                    var t = c.trail;
                    var g = c.glyphs;
                    var y0 = Math.max(0, h - (t - 1));
                    var edge = Math.min(h, root.rowsCount);
                    var s = "";
                    for (var r = y0; r < edge; r++)
                        s += g[((h - r) % g.length + g.length) % g.length];
                    trailText.text = s;
                    trailText.y = y0 * root.rowCell - root.rowCell * 0.15;

                    headText.text = (h >= 0 && h < root.rowsCount && g.length > 0)
                        ? g[h % g.length]
                        : "";
                    headText.y = h * root.rowCell - root.rowCell * 0.15;

                    // alpha: bright at spawn, dissolves at the column's own
                    // random rate over its journey; smooth continuous curve
                    var alpha = 0.85 * (1.0 - prog * c.fadeSpeed);
                    if (alpha < 0.06) alpha = 0.06;
                    trailText.opacity = alpha;
                    headText.opacity = Math.max(0.12, alpha * 1.25);
                }
            }
        }
    }
}
import QtQuick
import Quickshell
import "../../reusables"
import "../../"

// Desktop widget: smooth flowing color plasma, palette from the active
// theme (mauve -> blue -> pink). Rendered at ~20 fps onto a downscaled
// ImageData and blitted through the canvas element.
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

    property real t0: 0

    QtObject {
        id: palette
        property color a: ThemeBackend.mauve
        property color b: ThemeBackend.blue
        property color c: ThemeBackend.pink
    }

    function paintFrame() {
        t0 = Math.floor(Date.now() / 60) * 60;
    }

    Timer {
        interval: 83
        running: root.visible
        repeat: true
        onTriggered: cv.requestPaint()
    }

    Canvas {
        id: cv
        anchors.fill: parent
        onPaint: {
            var now = Date.now();
            if (root.t0 === 0) root.t0 = now;
            var t = (now - root.t0) / 1000;
            var ctx = getContext("2d");
            var W = Math.max(24, Math.floor(Math.min(root.width, 128)));
            var H = Math.max(16, Math.floor(Math.min(root.height, 80)));
            var img = ctx.createImageData(W, H);
            var d = img.data;
            var a = palette.a, b = palette.b, c = palette.c;
            var o = 0;
            for (var y = 0; y < H; y++) {
                var yi = y / H;
                for (var x = 0; x < W; x++) {
                    var xi = x / W;
                    var v = Math.sin(xi * 6.2 + t * 0.9)
                          + Math.sin(yi * 7.0 - t * 1.2)
                          + Math.sin((xi + yi) * 5.0 + t * 0.7)
                          + Math.sin(Math.sqrt((xi - 0.5) * (xi - 0.5) + (yi - 0.5) * (yi - 0.5)) * 14.0 - t);
                    var u = (v + 4) / 8;
                    var r, g, bl;
                    if (u < 0.5) {
                        var q = u * 2;
                        r = a.r + (b.r - a.r) * q;
                        g = a.g + (b.g - a.g) * q;
                        bl = a.b + (b.b - a.b) * q;
                    } else {
                        var q2 = (u - 0.5) * 2;
                        r = b.r + (c.r - b.r) * q2;
                        g = b.g + (c.g - b.g) * q2;
                        bl = b.b + (c.b - b.b) * q2;
                    }
                    d[o]     = r * 255;
                    d[o + 1] = g * 255;
                    d[o + 2] = bl * 255;
                    d[o + 3] = 230;
                    o += 4;
                }
            }
            ctx.putImageData(img, 0, 0);
        }
    }
}

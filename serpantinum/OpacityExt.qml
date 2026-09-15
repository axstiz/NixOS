pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Рантайм-ручки прозрачности (вкладка Guide «Расширенные настройки»).
// Значения: settings.json -> theme.opacityExt, проценты 0..100.
// Самостоятельный fs-watcher тем же приёмом, что у Config: FileView
// (Quickshell.Io) с watchChanges; парсStrictly в onLoaded, где text
// доступен в скоупе FileView (обращение извне — settingsWatcher.text —
// не работает и бросает при blockLoading, поэтому парсим внутри).
Item {
    id: root

    property var map: ({ })
    property int rev: 0

    FileView {
        id: settingsWatcher
        path: Quickshell.env("QS_SETTINGS") ? Quickshell.env("QS_SETTINGS")
                                            : (Quickshell.env("HOME") + "/.config/serpantinum/settings.json")
        watchChanges: true
        onFileChanged: reload()

        onLoaded: {
            try {
                let raw = typeof text === "function" ? text() : text;
                let parsed = JSON.parse(String(raw));
                let t = parsed.theme;
                root.map = (t && t.opacityExt) ? t.opacityExt : { };
                root.rev++;
                console.log("[OpacityExt] refreshed rev=" + root.rev +
                            " baseBg=" + (typeof root.map.baseBg === "number" ? root.map.baseBg : "(default)"));
            } catch (e) {
                console.log("[OpacityExt] load failed: " + e);
            }
        }
    }

    Component.onCompleted: settingsWatcher.reload()

    // Доли 0..1 (все потребители — reactive):
    readonly property real baseBg:         f("baseBg", 90)
    readonly property real sidebarOuter:   f("sidebarOuter", 55)
    readonly property real sidebarInner:   f("sidebarInner", 60)
    readonly property real pills:          f("pills", 60)
    readonly property real floating:       f("floating", 80)
    readonly property real syspanelBg:     f("syspanelBg", 70)
    readonly property real syspanelBlocks: f("syspanelBlocks", 80)
    readonly property real lockPanel:      f("lockPanel", 50)
    readonly property real lockInner:      f("lockInner", 70)
    readonly property real lockPowerMenu:  f("lockPowerMenu", 70)
    readonly property real calendar:       f("calendar", 95)
    readonly property real timer:          f("timer", 80)
    readonly property real draw:           f("draw", 80)

    function f(key, defPct) {
        let v = root.map[key];
        return (typeof v === "number" && v >= 0) ? (v / 100.0) : (defPct / 100.0);
    }
}

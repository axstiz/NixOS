import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import "../../"
import "../../reusables"

Item {
    id: betaTabRoot
    required property var rootObj
    required property int tabIndex

    anchors.fill: parent
    visible: rootObj.currentTab === tabIndex
    opacity: visible ? 1.0 : 0.0
    property real slideY: visible ? 0 : rootObj.s(10)

    Behavior on slideY { NumberAnimation { duration: 250; easing.type: Easing.OutQuart } }
    transform: Translate { y: slideY }
    Behavior on opacity { NumberAnimation { duration: 250 } }

    // Группы прозрачности: значения — проценты непрозрачности (0..100).
    // Таблица групп ГЕНЕРИРУЕТСЯ из serpantinum/opacity-groups.nix и кладётся
    // рядом с этим файлом как groups.json — править состав/дефолты только там.
    property var groups: [ ]

    FileView {
        id: groupsFv
        path: {
            let p = Qt.resolvedUrl("groups.json").toString();
            if (p.startsWith("file://")) p = p.substring(7);
            return p;
        }
        watchChanges: false
        onLoaded: {
            try {
                let raw = typeof text === "function" ? text() : text;
                let parsed = JSON.parse(String(raw));
                // дефолты из Nix-table: default -> pct (формат строк вкладки)
                let out = [];
                for (let i = 0; i < parsed.length; i++) {
                    let g = parsed[i];
                    out.push({ key: g.key, pct: g.default, icon: g.icon, title: g.title, del: g.del });
                }
                betaTabRoot.groups = out;
                betaTabRoot.reloadCurrOpacity();
            } catch (e) {
                console.log("[BetaTab] groups.json load failed: " + e);
            }
        }
    }

    Component.onCompleted: groupsFv.reload()

    // Текущие значения групп (проценты). Ключи берутся из theme.opacityExt,
    // отсутствующие — из дефолтов групп выше.
    property var currOpacity: {
        let base = Config.getSetting("theme", {});
        let saved = base.opacityExt || {};
        let out = {};
        for (let i = 0; i < groups.length; i++) {
            let g = groups[i];
            out[g.key] = (typeof saved[g.key] === "number") ? saved[g.key] : g.pct;
        }
        return out;
    }

    Timer {
        // debounce при драге слайдера (как sfxVolume в GeneralTab)
        id: saveDebounce
        interval: 100
        onTriggered: betaTabRoot.saveOpacity()
    }

    // Пересборка currOpacity из текущей таблицы групп + сохранённых значений
    function reloadCurrOpacity() {
        let base = { };
        try { base = Config.getSetting("theme", {}); } catch (e) { }
        let saved = base.opacityExt || { };
        let out = { };
        for (let i = 0; i < groups.length; i++) {
            let g = groups[i];
            out[g.key] = (typeof saved[g.key] === "number") ? saved[g.key] : g.pct;
        }
        currOpacity = out;
    }

    function saveOpacity() {
        if (typeof Config !== "undefined" && !Config.dataReady) return;
        let base = Object.assign({}, Config.getSetting("theme", {}));
        base.opacityExt = Object.assign({}, betaTabRoot.currOpacity);
        Config.setSetting("theme", base);
    }

    Connections {
        target: Config
        function onSettingsLoaded() { reloadCurrOpacity(); }
    }

    Flickable {
        anchors.fill: parent
        anchors.topMargin: rootObj.s(8)
        anchors.leftMargin: rootObj.s(8)
        anchors.rightMargin: rootObj.s(8)
        anchors.bottomMargin: rootObj.s(8)
        contentHeight: extCol.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: extCol
            width: parent.width
            spacing: rootObj.s(6)

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: rowIntroLayout.implicitHeight + rootObj.s(24)
                radius: ThemeBackend.borderRadius
                color: Qt.alpha(ThemeBackend.surface0, 0.4)
                border.width: 0

                RowLayout {
                    id: rowIntroLayout
                    anchors.left: parent.left
                    anchors.leftMargin: rootObj.s(14)
                    anchors.right: parent.right
                    anchors.rightMargin: rootObj.s(14)
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: rootObj.s(12)

                    IconButton {
                        enabled: false
                        size: rootObj.s(32)
                        Layout.preferredWidth: rootObj.s(32)
                        Layout.preferredHeight: rootObj.s(32)
                        Layout.alignment: Qt.AlignVCenter
                        cornerRadius: ThemeBackend.borderRadius
                        buttonIcon: "󰛶"
                        iconFontSize: rootObj.s(16)
                        accentColor: ThemeBackend.surface0
                        textColor: "#ffffff"
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: rootObj.s(2)

                        Text {
                            Layout.fillWidth: true
                            text: I18n.t("guide.tabs.extended", "Расширенные настройки")
                            font.family: ThemeBackend.fontFamily
                            font.pixelSize: rootObj.s(13)
                            color: ThemeBackend.text
                        }

                        Text {
                            Layout.fillWidth: true
                            text: "Экспериментальные ручки оформления. Меняются на лету и сохраняются в settings.json (не сбрасываются при rebuild)"
                            font.family: ThemeBackend.fontFamily
                            font.pixelSize: rootObj.s(11)
                            color: ThemeBackend.subtext0
                        }
                    }
                }
            }

            Repeater {
                model: betaTabRoot.groups

                delegate: Rectangle {
                    id: groupRow
                    required property var modelData
                    readonly property string gKey: modelData.key
                    readonly property int gPct: betaTabRoot.currOpacity[modelData.key] !== undefined ? betaTabRoot.currOpacity[modelData.key] : modelData.pct

                    Layout.fillWidth: true
                    implicitHeight: rowGrouplayout.implicitHeight + rootObj.s(24)
                    radius: ThemeBackend.borderRadius
                    color: Qt.alpha(ThemeBackend.surface0, 0.4)
                    border.width: 0

                    RowLayout {
                        id: rowGrouplayout
                        anchors.left: parent.left
                        anchors.leftMargin: rootObj.s(14)
                        anchors.right: parent.right
                        anchors.rightMargin: rootObj.s(14)
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: rootObj.s(12)

                        IconButton {
                            size: rootObj.s(32)
                            Layout.preferredWidth: rootObj.s(32)
                            Layout.preferredHeight: rootObj.s(32)
                            Layout.alignment: Qt.AlignVCenter
                            cornerRadius: ThemeBackend.borderRadius
                            buttonIcon: modelData.icon
                            iconFontSize: rootObj.s(16)
                            accentColor: ThemeBackend.surface0
                            textColor: "#ffffff"
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            spacing: rootObj.s(2)

                            Text {
                                Layout.fillWidth: true
                                text: modelData.title
                                font.family: ThemeBackend.fontFamily
                                font.pixelSize: rootObj.s(13)
                                color: ThemeBackend.text
                            }

                            Text {
                                Layout.fillWidth: true
                                text: modelData.del
                                font.family: ThemeBackend.fontFamily
                                font.pixelSize: rootObj.s(11)
                                color: ThemeBackend.subtext0
                                visible: text !== ""
                            }
                        }

                        // Тумблер: прозрачность активна, когда значение < 100%.
                        Toggle {
                            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                            checked: groupRow.gPct < 100
                            accentColor: ThemeBackend.mauve
                            baseColor: ThemeBackend.surface1
                            handleColor: ThemeBackend.crust
                            handleOffColor: ThemeBackend.text
                            onToggled: function(c) {
                                let next = Object.assign({}, betaTabRoot.currOpacity);
                                if (c) {
                                    next[groupRow.gKey] = (next[groupRow.gKey] < 100) ? next[groupRow.gKey] : modelData.pct;
                                    if (next[groupRow.gKey] >= 100) next[groupRow.gKey] = modelData.pct;
                                } else {
                                    next[groupRow.gKey] = 100;
                                }
                                betaTabRoot.currOpacity = next;
                                betaTabRoot.saveOpacity();
                            }
                        }

                        Draggable {
                            id: groupSlider
                            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                            implicitWidth: rootObj.s(180)
                            implicitHeight: rootObj.s(18)
                            from: 1
                            to: 100
                            stepSize: 1
                            defaultValue: modelData.pct
                            showValueBubble: true
                            valueFormatter: function(v) { return Math.round(v) + "%" }
                            value: groupRow.gPct
                            backgroundColor: ThemeBackend.surface0
                            accentColor: groupRow.gPct < 100 ? ThemeBackend.mauve : ThemeBackend.surface2
                            handleColor: ThemeBackend.text
                            handleBorderColor: ThemeBackend.mantle
                            onMoved: function(val) {
                                let rounded = Math.round(val);
                                if (betaTabRoot.currOpacity[groupRow.gKey] === rounded) return;
                                let next = Object.assign({}, betaTabRoot.currOpacity);
                                next[groupRow.gKey] = rounded;
                                betaTabRoot.currOpacity = next;
                                saveDebounce.restart();
                            }
                        }
                    }
                }
            }
        }
    }
}

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
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
    // pct — дефолт из Nix-патчей; файл settings.json может отсутствовать/не иметь
    // ключей theme.opacityExt — тогда всё выглядит ровно как «старый» вид.
    property var groups: [
        { key: "baseBg",        pct: 90, icon: "󰌗", title: "Основной фон", del: "Базовые поверхности (base/surface*): бар, панели, док" },
        { key: "sidebarOuter",  pct: 55, icon: "󰍢", title: "Sidebar — фон", del: "Полупрозрачный фон авто-скрываемого бара сбоку" },
        { key: "sidebarInner",  pct: 60, icon: "󰌵", title: "Sidebar — контент", del: "Контентная зона левой панели" },
        { key: "pills",         pct: 60, icon: "󰓙", title: "Sidebar — пилюли", del: "Внутренние блоки с иконками (wifi/bt/vol/...)" },
        { key: "floating",      pct: 80, icon: "󰖟", title: "Floating панель", del: "Floating-виджеты и quickactions" },
        { key: "syspanelBg",    pct: 70, icon: "󰍴", title: "Системная панель — фон", del: "Основной фон syspanel (уведомления/система)" },
        { key: "syspanelBlocks",pct: 80, icon: "󰋖", title: "Системная панель — блоки", del: "Внутренние блоки: слайдеры, уведомления, действия" },
        { key: "lockPanel",     pct: 50, icon: "󰌾", title: "Lock — центральная панель", del: "Главная панель экрана разблокировки" },
        { key: "lockInner",     pct: 70, icon: "󱌽", title: "Lock — пилюли/блоки", del: "Пин, кнопки, погода/медиа на экране блокировки" },
        { key: "lockPowerMenu", pct: 70, icon: "󰐥", title: "Lock — меню питания", del: "Полупрозрачное меню выключения в lock-screen" },
        { key: "calendar",      pct: 95, icon: "󰃭", title: "Календарь", del: "Панель календаря/погоды" },
        { key: "timer",         pct: 80, icon: "󰄉", title: "Таймер/фокус", del: "Панель фокус-таймера и секундомера" },
        { key: "draw",          pct: 80, icon: "󰽘", title: "Draw", del: "Панель быстрого рисования" }
    ]

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

    function saveOpacity() {
        if (typeof Config !== "undefined" && !Config.dataReady) return;
        let base = Object.assign({}, Config.getSetting("theme", {}));
        base.opacityExt = Object.assign({}, betaTabRoot.currOpacity);
        Config.setSetting("theme", base);
    }

    Connections {
        target: Config
        function onSettingsLoaded() {
            let base = Config.getSetting("theme", {});
            let saved = base.opacityExt || {};
            let out = {};
            for (let i = 0; i < betaTabRoot.groups.length; i++) {
                let g = betaTabRoot.groups[i];
                out[g.key] = (typeof saved[g.key] === "number") ? saved[g.key] : g.pct;
            }
            betaTabRoot.currOpacity = out;
        }
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

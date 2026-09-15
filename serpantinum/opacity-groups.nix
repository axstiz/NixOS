# ЕДИНЫЙ источник настроек прозрачности шелла serpantinum.
# Отсюда генерируются:
#   1) quickshell/singletons/theme/OpacityExt.qml (дефолт-property каждой группы)
#   2) quickshell/guide/beta/groups.json — таблица для вкладки Guide «Расширенные настройки»
# Правки дефолтов/названий — только здесь.
# default — проценты непрозрачности (0..100), как в старых «захардкоженных» константах.
[
  { key = "baseBg";         default = 90; icon = "󰌗"; title = "Основной фон";               del = "Базовые поверхности (base/surface*): бар, панели, док"; }
  { key = "sidebarOuter";   default = 55; icon = "󰍢"; title = "Sidebar — фон";             del = "Полупрозрачный фон авто-скрываемого бара сбоку"; }
  { key = "sidebarInner";   default = 60; icon = "󰌵"; title = "Sidebar — контент";         del = "Контентная зона левой панели"; }
  { key = "pills";          default = 60; icon = "󰓙"; title = "Sidebar — пилюли";          del = "Внутренние блоки с иконками (wifi/bt/vol/...)"; }
  { key = "floating";       default = 80; icon = "󰖟"; title = "Floating панель";           del = "Floating-виджеты и quickactions"; }
  { key = "syspanelBg";     default = 70; icon = "󰍴"; title = "Системная панель — фон";    del = "Основной фон syspanel (уведомления/система)"; }
  { key = "syspanelBlocks"; default = 80; icon = "󰋖"; title = "Системная панель — блоки";  del = "Внутренние блоки: слайдеры, уведомления, действия"; }
  { key = "lockPanel";      default = 50; icon = "󰌾"; title = "Lock — центральная панель"; del = "Главная панель экрана разблокировки"; }
  { key = "lockInner";      default = 70; icon = "󱌽"; title = "Lock — пилюли/блоки";       del = "Пин, кнопки, погода/медиа на экране блокировки"; }
  { key = "lockPowerMenu";  default = 70; icon = "󰐥"; title = "Lock — меню питания";       del = "Полупрозрачное меню выключения в lock-screen"; }
  { key = "calendar";       default = 95; icon = "󰃭"; title = "Календарь";                 del = "Панель календаря/погоды"; }
  { key = "timer";          default = 80; icon = "󰄉"; title = "Таймер/фокус";              del = "Панель фокус-таймера и секундомера"; }
  { key = "draw";           default = 80; icon = "󰽘"; title = "Draw";                      del = "Панель быстрого рисования"; }
]

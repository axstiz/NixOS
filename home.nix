{ config, pkgs, inputs, ... }:

let
  # Нативные диспатчеры Hyprland: serpantinum msg workspace использует hl.dsp.*,
  # которых нет в Hyprland 0.54 (см. qs_manager.sh) — переключаемся напрямую.
  serpWs = n: k: "$mainMod, ${k}, workspace, ${n}";
  serpWsMove = n: k: "$mainMod SHIFT, ${k}, movetoworkspace, ${n}";

  # Каталог обоев: наша дефолтная картинка + коллекция автора шелла (shell-wallpapers).
  # ~/Pictures/Wallpapers — симлинк на этот store-путь; Serpantinum/matugen читают его
  # напрямую, отдельные файлы в профиль не копируются.
  wallpapers = pkgs.runCommand "serpantinum-wallpapers" { } ''
    mkdir -p "$out"
    cp ${./my_wallpaper.png} "$out/wallpaper.png"
    cp -a ${inputs.shell-wallpapers}/images/. "$out/"
  '';
in
{
  home.username = "litsummer";
  home.homeDirectory = "/home/litsummer";
  home.stateVersion = "24.11";

  home.packages = [ ];

  # Курсор для GTK-приложений (Nautilus, Telegram и т.д.) — бледно-сиреневый Rose Pine.
  home.pointerCursor = {
    name = "BreezeX-RosePine-Linux";
    package = pkgs.rose-pine-cursor;
    size = 24;
  };

  # Обои — каталог, из которого Serpantinum читает картинки (matugen берёт оттуда цвета)
  home.file."Pictures/Wallpapers" = {
    source = wallpapers;
    recursive = false;
  };

  # Применяет дефолтные обои при первом логине (см. exec-once ниже);
  # ручной выбор обоев пикером сохраняется и не перезаписывается.
  home.file."bin/apply-wallpaper.sh" = {
    source = ./bin/apply-wallpaper.sh;
    executable = true;
  };

  # Добавляет на рабочий стол виджет-визуализатор звука (тип "bars"), если его
  # ещё нет в разметке виджетов (см. exec-once ниже). Положение/размер можно
  # поменять в Guide -> Display -> Widgets; ручной ре-плейсмент не трогается.
  home.file."bin/ensure-visualizer.sh" = {
    source = ./bin/ensure-visualizer.sh;
    executable = true;
  };

  # --- Serpantinum shell (панель, лаунчер, шторки, lock-screen) ---
  programs.serpantinum = {
    enable = true;
    # Стартуем через exec-once в Hyprland (см. ниже) — под GDM graphical-session.target
    # неактивен, поэтому systemd-сервис не поднимется.
    systemd.enable = false;
    settings = {
      wallpaperDir = "/home/litsummer/Pictures/Wallpapers";

      theme = {
        activePreset = "Matugen";
        matugen = true;
        fontFamily = "Adwaita Mono";
        borderRadius = 12;
      };

      notifications.dnd = false;

      # Все виджеты панели: left, workspaces, focus, timedate, info, weather,
      # media, vis (аудио-визуализатор), tray и системная группа sysmon/kb/wifi/bt/vol/bat.
      # Каждый виджет сам открывает свою панель при клике (vol->громкость, bat->система и т.д.)
      bar = {
        position = "top";
        style = "fill";
        workspaceCount = 10;
        modules = {
          left = [ "left" "workspaces" "focus" ];
          center = [ [ "timedate" "info" "weather" ] ];
          right = [ "media" "vis" "tray" [ "sysmon" "kb" "wifi" "bt" "vol" "bat" ] ];
        };
      };
    };
  };

  # --- Hyprland ---
  wayland.windowManager.hyprland = {
    enable = true;
    configType = "hyprlang";

    settings = {
      "$mainMod" = "SUPER";

      exec-once = [
        "serpantinumd start"
        "$HOME/bin/apply-wallpaper.sh"
        "$HOME/bin/ensure-visualizer.sh"
        "wl-paste --type text --watch cliphist store"
        "wl-paste --type image --watch cliphist store"
      ];

      env = [
        "XCURSOR_SIZE,24"
        "HYPRCURSOR_SIZE,24"
        "XCURSOR_THEME,BreezeX-RosePine-Linux"
        "HYPRCURSOR_THEME,rose-pine-hyprcursor"
      ];

      monitor = [
        "eDP-1,1920x1080@60,0x0,1"
      ];

      general = {
        gaps_in = 5;
        gaps_out = 20;
        border_size = 2;
        resize_on_border = false;
        allow_tearing = false;
        layout = "dwindle";
        "col.active_border" = "rgba(c4a7e7ee) rgba(e0def4ee) 45deg";
        "col.inactive_border" = "rgba(6e6a86aa)";
      };

      decoration = {
        rounding = 10;
        rounding_power = 2;
        active_opacity = 1.0;
        inactive_opacity = 1.0;

        shadow = {
          enabled = true;
          range = 4;
          render_power = 3;
          color = "rgba(1a1a1aee)";
        };

        blur = {
          enabled = true;
          size = 3;
          passes = 1;
          vibrancy = 0.1696;
        };
      };

      animations = {
        enabled = true;
        bezier = [
          "easeOutQuint, 0.23, 1, 0.32, 1"
          "easeInOutCubic, 0.65, 0.05, 0.36, 1"
          "linear, 0, 0, 1, 1"
          "almostLinear, 0.5, 0.5, 0.75, 1"
          "quick, 0.15, 0, 0.1, 1"
        ];
        animation = [
          "global, 1, 10, default"
          "border, 1, 5.39, easeOutQuint"
          "windows, 1, 4.79, easeOutQuint"
          "windowsIn, 1, 4.1, easeOutQuint, popin 87%"
          "windowsOut, 1, 1.49, linear, popin 87%"
          "fadeIn, 1, 1.73, almostLinear"
          "fadeOut, 1, 1.46, almostLinear"
          "fade, 1, 3.03, quick"
          "layers, 1, 3.81, easeOutQuint"
          "layersIn, 1, 4, easeOutQuint, fade"
          "layersOut, 1, 1.5, linear, fade"
          "fadeLayersIn, 1, 1.79, almostLinear"
          "fadeLayersOut, 1, 1.39, almostLinear"
          "workspaces, 1, 1.94, almostLinear, fade"
          "workspacesIn, 1, 1.21, almostLinear, fade"
          "workspacesOut, 1, 1.94, almostLinear, fade"
          "zoomFactor, 1, 7, quick"
        ];
      };

      dwindle = {
        pseudotile = true;
        preserve_split = true;
      };

      master = {
        new_status = "master";
      };

      gesture = [
        "3, horizontal, workspace"
      ];

      misc = {
        disable_hyprland_logo = true;
      };

      input = {
        kb_layout = "us,ru";
        kb_options = "grp:alt_shift_toggle";
        follow_mouse = 1;
        touchpad = {
          # Направление скролла у тачпада (Hyprland управляет libinput сам,
          # NixOS-сервис libinput влияет только на X11).
          natural_scroll = true;
        };
      };

      # --- Запуск и панели Serpantinum (штатная раскладка) ---
      bind = [
        "$mainMod, Return, exec, kitty"
        "$mainMod, F, exec, firefox"
        "$mainMod, E, exec, nautilus"

        "$mainMod, D, exec, serpantinum msg toggle launcher"
        "$mainMod, H, exec, serpantinum msg toggle guide"
        "$mainMod, W, exec, serpantinum msg toggle wallpaper"
        "$mainMod, C, exec, serpantinum msg toggle clipboard"
        "$mainMod, N, exec, serpantinum msg toggle network"
        "$mainMod, B, exec, serpantinum msg toggle system"
        "$mainMod, M, exec, serpantinum msg toggle music"
        "$mainMod, V, exec, serpantinum msg toggle volume"
        "$mainMod, S, exec, serpantinum msg toggle calendar"
        "$mainMod, A, exec, serpantinum msg toggle autohide"
        "$mainMod, L, exec, serpantinum lock"
        "$mainMod, R, exec, serpantinum reload"
        "$mainMod, SPACE, exec, playerctl play-pause"

        # Рабочие столы 1-10 (переключение через шелл)
        (serpWs "1" "1")
        (serpWs "2" "2")
        (serpWs "3" "3")
        (serpWs "4" "4")
        (serpWs "5" "5")
        (serpWs "6" "6")
        (serpWs "7" "7")
        (serpWs "8" "8")
        (serpWs "9" "9")
        (serpWs "10" "0")
        (serpWsMove "1" "1")
        (serpWsMove "2" "2")
        (serpWsMove "3" "3")
        (serpWsMove "4" "4")
        (serpWsMove "5" "5")
        (serpWsMove "6" "6")
        (serpWsMove "7" "7")
        (serpWsMove "8" "8")
        (serpWsMove "9" "9")
        (serpWsMove "10" "0")

        # Окна
        "$mainMod, Q, killactive"
        "$mainMod, G, fullscreen, 0"
        "$mainMod, T, togglefloating"
        "$mainMod SHIFT, S, togglespecialworkspace, magic"
        "$mainMod, TAB, cyclenext, prev"

        # Навигация: фокус по стрелкам, перемещение — MOD+Ctrl, размер — MOD+Shift (см. binde)
        "$mainMod, LEFT, movefocus, l"
        "$mainMod, RIGHT, movefocus, r"
        "$mainMod, UP, movefocus, u"
        "$mainMod, DOWN, movefocus, d"
        "$mainMod CTRL, LEFT, movewindow, l"
        "$mainMod CTRL, RIGHT, movewindow, r"
        "$mainMod CTRL, UP, movewindow, u"
        "$mainMod CTRL, DOWN, movewindow, d"

        # Листание рабочих столов колесом
        "$mainMod, mouse_down, workspace, e+1"
        "$mainMod, mouse_up, workspace, e-1"
      ];

      # Удержание MOD+Shift+стрелки меняет размер окна (повторяемые)
      binde = [
        "$mainMod SHIFT, LEFT, resizeactive, -50 0"
        "$mainMod SHIFT, RIGHT, resizeactive, 50 0"
        "$mainMod SHIFT, UP, resizeactive, 0 -50"
        "$mainMod SHIFT, DOWN, resizeactive, 0 50"
      ];

      bindm = [
        "$mainMod, mouse:272, movewindow"
        "$mainMod, mouse:273, resizewindow"
      ];

      # Аппаратные клавиши и скриншоты (работают всегда, даже при зажатых модификаторах)
      bindl = [
        ", XF86AudioMute, exec, serpantinum volume mute-toggle"
        ", XF86AudioMicMute, exec, serpantinum volume mic-toggle"
        ", XF86AudioRaiseVolume, exec, serpantinum volume raise"
        ", XF86AudioLowerVolume, exec, serpantinum volume lower"
        ", XF86MonBrightnessUp, exec, serpantinum brightness raise"
        ", XF86MonBrightnessDown, exec, serpantinum brightness lower"
        ", XF86AudioNext, exec, playerctl next"
        ", XF86AudioPrev, exec, playerctl previous"
        ", XF86AudioPlay, exec, playerctl play-pause"
        ", XF86AudioStop, exec, playerctl stop"
        ", XF86PowerOff, exec, serpantinum lock"

        ", Print, exec, serpantinum screenshot"
        "SHIFT, Print, exec, serpantinum screenshot --edit"
        "SUPER, Print, exec, serpantinum screenshot --full"
        "SUPER SHIFT, Print, exec, serpantinum screenshot --full --edit"
      ];
    };
  };
}
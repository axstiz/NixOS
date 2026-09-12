{ config, pkgs, inputs, ... }:

let
  ws = n: "$mainMod, ${n}, workspace, ${n}";
  wsMove = n: "$mainMod SHIFT, ${n}, movetoworkspace, ${n}";
in
{
  home.username = "litsummer";
  home.homeDirectory = "/home/litsummer";
  home.stateVersion = "24.11";

  home.packages = [ ];

  # Обои (awww читает картинку из ~/.config/awww)
  home.file.".config/awww/wallpaper.png".source = ./my_wallpaper.png;

  # Шпаргалка горячих клавиш (MOD+Shift+H)
  home.file.".config/caelestia/keyhints.txt".source = ./keyhints.txt;

  # --- Caelestia shell (панель, лаунчер, шторки, экран блокировки) ---
  programs.caelestia = {
    enable = true;
    # Шелл стартуем через exec-once в Hyprland (см. ниже), как в личном конфиге —
    # под GDM без UWSM systemd-сервис graphical-session.target не запускается.
    systemd.enable = false;
    cli.enable = true;
  };

  # --- Hyprland ---
  wayland.windowManager.hyprland = {
    enable = true;
    configType = "hyprlang";

    settings = {
      "$mainMod" = "SUPER";

      exec-once = [
        "caelestia-shell"
        "awww img ${config.home.homeDirectory}/.config/awww/wallpaper.png"
      ];

      env = [
        "XCURSOR_SIZE,24"
        "HYPRCURSOR_SIZE,24"
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
        "col.active_border" = "rgba(33ccffee) rgba(00ff99ee) 45deg";
        "col.inactive_border" = "rgba(595959aa)";
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
      };

      # Запуск ПО
      bind = [
        "$mainMod, Q, exec, kitty"
        "$mainMod, R, exec, firefox"
        "$mainMod, E, exec, code"
        "$mainMod, W, exec, kitty"

        # Рабочие столы 1-10
        (ws "1")
        (ws "2")
        (ws "3")
        (ws "4")
        (ws "5")
        (ws "6")
        (ws "7")
        (ws "8")
        (ws "9")
        "$mainMod, 0, workspace, 10"
        (wsMove "1")
        (wsMove "2")
        (wsMove "3")
        (wsMove "4")
        (wsMove "5")
        (wsMove "6")
        (wsMove "7")
        (wsMove "8")
        (wsMove "9")
        "$mainMod SHIFT, 0, movetoworkspace, 10"

        # Навигация между окнами
        "$mainMod, LEFT, movefocus, l"
        "$mainMod, RIGHT, movefocus, r"
        "$mainMod, UP, movefocus, u"
        "$mainMod, DOWN, movefocus, d"
        "$mainMod SHIFT, LEFT, movewindow, l"
        "$mainMod SHIFT, RIGHT, movewindow, r"
        "$mainMod SHIFT, UP, movewindow, u"
        "$mainMod SHIFT, DOWN, movewindow, d"

        # Окна
        "$mainMod, C, killactive"
        "$mainMod, F, fullscreen, 0"
        "$mainMod SHIFT, F, fullscreen, 1"
        "$mainMod, T, togglefloating"
        "$mainMod SHIFT, P, pin, active"
        "$mainMod, G, togglegroup"
        "$mainMod SHIFT, G, changegroupactive"
"$mainMod, TAB, cyclenext, prev"

        # Скретч-пад и листание рабочих столов (из старого конфига)
        "$mainMod, S, togglespecialworkspace, magic"
        "$mainMod SHIFT, S, movetoworkspace, special:magic"
        "$mainMod, mouse_down, workspace, e+1"
        "$mainMod, mouse_up, workspace, e-1"

        # Справка по горячим клавишам
        "$mainMod SHIFT, H, exec, kitty --class keyhints --title=Keybinds -e less -R ${config.home.homeDirectory}/.config/caelestia/keyhints.txt"
      ];

      # Повторяемые бинды: удержание клавиши меняет размер окна
      binde = [
        "$mainMod, H, resizeactive, -40 0"
        "$mainMod, L, resizeactive, 40 0"
        "$mainMod, K, resizeactive, 0 -40"
        "$mainMod, J, resizeactive, 0 40"
      ];

      bindm = [
        "$mainMod, mouse:272, movewindow"
        "$mainMod, mouse:273, resizewindow"
      ];

      windowrule = [
        "float, class:^(keyhints)$"
        "size 900 650, class:^(keyhints)$"
        "center, class:^(keyhints)$"
        "suppressevent maximize, class:^(.*)$"
      ];

      # Мультимедиа (работают всегда, даже при зажатых модификаторах)
      bindl = [
        ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
        ", XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
        ", XF86AudioRaiseVolume, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ 0; wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+"
        ", XF86AudioLowerVolume, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ 0; wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
        ", XF86MonBrightnessUp, exec, brightnessctl -q set 5%+"
        ", XF86MonBrightnessDown, exec, brightnessctl -q set 5%-"
        ", XF86AudioNext, exec, playerctl next"
        ", XF86AudioPrev, exec, playerctl previous"
        ", XF86AudioPlay, exec, playerctl play-pause"
        ", XF86AudioStop, exec, playerctl stop"
      ];
    };
  };
}
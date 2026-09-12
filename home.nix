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
    systemd.enable = true; # автозапуск через графическую сессию (UWSM)
    cli.enable = true;
  };

  # --- Hyprland ---
  wayland.windowManager.hyprland = {
    enable = true;
    configType = "hyprlang";

    settings = {
      "$mainMod" = "SUPER";

      exec-once = [
        "awww img $HOME/.config/awww/wallpaper.png"
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
        (ws "0")
        (wsMove "1")
        (wsMove "2")
        (wsMove "3")
        (wsMove "4")
        (wsMove "5")
        (wsMove "6")
        (wsMove "7")
        (wsMove "8")
        (wsMove "9")
        (wsMove "0")

        # Навигация между окнами
        "$mainMod, LEFT, movefocus, l"
        "$mainMod, RIGHT, movefocus, r"
        "$mainMod, UP, movefocus, u"
        "$mainMod, DOWN, movefocus, d"
        "$mainMod SHIFT, LEFT, movewindow, l"
        "$mainMod SHIFT, RIGHT, movewindow, r"
        "$mainMod SHIFT, UP, movewindow, u"
        "$mainMod SHIFT, DOWN, movewindow, d"

        # Размер окна
        "binde, $mainMod, H, resizeactive, -40 0"
        "binde, $mainMod, L, resizeactive, 40 0"
        "binde, $mainMod, K, resizeactive, 0 -40"
        "binde, $mainMod, J, resizeactive, 0 40"

        # Окна
        "$mainMod, C, killactive"
        "$mainMod, F, fullscreen, 0"
        "$mainMod SHIFT, F, fullscreen, 1"
        "$mainMod, T, togglefloating"
        "$mainMod SHIFT, P, pin, active"
        "$mainMod, G, togglegroup"
        "$mainMod SHIFT, G, changegroupactive"
        "$mainMod, TAB, cyclenext, prev"

        # Завершение сессии
        "$mainMod, M, exit"

        # Caelestia shell (IPC)
        "$mainMod, SPACE, exec, caelestia shell drawers toggle launcher"
        "$mainMod, ESCAPE, exec, caelestia shell drawers toggle session"
        "$mainMod, A, exec, caelestia shell drawers toggle sidebar"
        "$mainMod, D, exec, caelestia shell drawers toggle dashboard"
        "$mainMod, U, exec, caelestia shell drawers toggle utilities"
        "$mainMod, N, exec, caelestia shell nexus open"
        "$mainMod, L, exec, loginctl lock-session"
        "$mainMod SHIFT, Q, exec, caelestia shell --kill"
        "CTRL SUPER SHIFT, R, exec, caelestia shell --restart"

        # Скриншоты
        ", PRINT, exec, caelestia screenshot"
        "$mainMod, PRINT, exec, caelestia screenshot -r slurp"
        "$mainMod SHIFT, PRINT, exec, caelestia screenshot -r slurp --freeze"

        # Буфер обмена и emoji
        "$mainMod, V, exec, caelestia clipboard"
        "$mainMod SHIFT, V, exec, caelestia emoji -p"

        # Запись экрана
        "CTRL SUPER, R, exec, caelestia record"
        "CTRL SUPER SHIFT, R, exec, caelestia record --region slurp"

        # Справка по горячим клавишам
        "$mainMod SHIFT, H, exec, kitty --class keyhints --title=Keybinds -e less -R $HOME/.config/caelestia/keyhints.txt"
      ];

      bindm = [
        "$mainMod, mouse:272, movewindow"
        "$mainMod, mouse:273, resizewindow"
      ];

      windowrule = [
        "float, class:^(keyhints)$"
        "size 900 650, class:^(keyhints)$"
        "center, class:^(keyhints)$"
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
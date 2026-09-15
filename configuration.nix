{ config, pkgs, inputs, ... }:

let
  # TG WS Proxy — локальный MTProto-прокси над WebSocket для Telegram Desktop.
  # Официальный релиз — PyInstaller-бандл, чей GUI (tkinter/pystray) падает на NixOS
  # с SIGSEGV (конфликт встроенных gi/glib и системных X11-библиотек). Поэтому собираем
  # консольный режим из исходников: он требует только cryptography + certifi и поднимает
  # MTProto-прокси на 127.0.0.1:1443 (для Telegram этого достаточно).
  # Фиксированный secret — иначе после каждого рестарта пришлось бы заново
  # вводить секрет в Telegram (secret для локального MTProto не секретен).
  proxySecret = "43ad0f6a2a0e26d6ca8e42572033171c";

  # Bluetooth: дождаться появления hci0 на D-Bus (адаптер подгружается с задержкой)
  # и включить Pairable. С pairable=false BlueZ заявляет "No Bonding" в IO-capability
  # (видно в btmon: Authentication 0x00), ядро отдаёт New Link Key с Store hint=No —
  # ключи не сохраняются, все сопряжения получаются temporary (Bonded=false) и умирают
  # после disconnect/перезагрузки. У serpantinum этого нет — флаг Pairable=false
  # застрял в /var/lib/bluetooth/<adapter>/settings ещё до миграции.
  btPairableScript = pkgs.writeShellScript "bt-pairable-startup" ''
    for _ in $(seq 1 15); do
      if ${pkgs.systemd}/bin/busctl tree org.bluez 2>/dev/null | grep -q hci0; then
        ${pkgs.systemd}/bin/busctl set-property org.bluez /org/bluez/hci0 org.bluez.Adapter1 Pairable b true
        echo "bluetooth: Pairable enabled on hci0"
        exit 0
      fi
      sleep 2
    done
    echo "bluetooth: hci0 did not appear on D-Bus 30s, giving up"
    exit 0
  '';

  # Bluetooth: если адаптер внезапно пропал с шины (глюк RTL8852BU, "Unexpected
  # NULL btd_adv_monitor_manager..."), bluetoothd остаётся без единого hci0 и
  # виджет показывает пустоту; рестарт bluetoothd возвращает контроллер.
  btWatchdogScript = pkgs.writeShellScript "bt-watchdog" ''
    if ! ${pkgs.systemd}/bin/busctl tree org.bluez 2>/dev/null | grep -q hci0; then
      echo "bluetooth watchdog: hci0 missing, restarting bluetoothd"
      ${pkgs.systemd}/bin/systemctl restart bluetooth.service
    fi
  '';
  tgWsProxy = pkgs.stdenv.mkDerivation {
    pname = "tg-ws-proxy";
    version = "1.10.2";
    src = pkgs.fetchFromGitHub {
      owner = "Flowseal";
      repo = "tg-ws-proxy";
      rev = "v1.10.2";
      hash = "sha256-XpO0Hmi0Hotu5TdOZ6+Cg/YBaF31RHJ5MfPJ1JKpPr8=";
    };
    nativeBuildInputs = [
      (pkgs.python3.withPackages (ps: [ ps.cryptography ps.certifi ]))
    ];
    installPhase = ''
      runHook preInstall
      mkdir -p $out/bin $out/lib/python
      cp -r proxy utils $out/lib/python/
      cat > $out/bin/tg-ws-proxy <<EOF
#!${pkgs.python3.withPackages (ps: [ ps.cryptography ps.certifi ])}/bin/python3
import sys
sys.path.insert(0, "$out/lib/python")
argv = sys.argv[1:]
if not any(a == "--secret" for a in argv):
    argv = ["--secret", "${proxySecret}"] + argv
sys.argv = ["tg-ws-proxy"] + argv
from proxy.tg_ws_proxy import main
main()
EOF
      chmod +x $out/bin/tg-ws-proxy
      install -Dm644 ${./bin/tg-ws-proxy.png} $out/share/pixmaps/tg-ws-proxy.png
      install -Dm644 ${./bin/tg-ws-proxy.desktop} $out/share/applications/tg-ws-proxy.desktop
      runHook postInstall
    '';
  };
in

{
  imports = [ ./hardware-configuration.nix ];

  # --- СИСТЕМА ---
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  networking.hostName = "nixos";
  networking.networkmanager.enable = true;
  time.timeZone = "Asia/Yekaterinburg";
  i18n.defaultLocale = "ru_RU.UTF-8";

  # --- ГРАФИКА И ВВОД ---
  hardware.graphics.enable = true;

  services.libinput = {
    enable = true;
    touchpad.naturalScrolling = true;
  };

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };

  # --- ДИСПЛЕЙНЫЙ МЕНЕДЖЕР (greeter) ---
  # GDM — графический экран входа (как было до перехода на ly)
  services.displayManager.gdm.enable = true;

  # --- ШРИФТЫ ---
  fonts.packages = with pkgs; [
    material-symbols
    noto-fonts-color-emoji
    rubik
    nerd-fonts.jetbrains-mono
    nerd-fonts.caskaydia-cove
  ];

  # --- ПОЛЬЗОВАТЕЛЬ ---
  users.users.litsummer = {
    isNormalUser = true;
    description = "Матвей Вахрушев";
    extraGroups = [ "networkmanager" "wheel" "video" "docker" ];
  };

  # --- ПРОГРАММЫ ---
  programs.hyprland = {
    enable = true;
    withUWSM = true;
  };
  nixpkgs.config.allowUnfree = true;

  # --- Serpantinum shell (системные зависимости) ---
  # Включает NetworkManager/Bluetooth/i2c, power-profiles-daemon, rtkit,
  # pipewire (уже есть - mkDefault), шрифт Iosevka.
  programs.serpantinum = {
    enable = true;
  };

  # --- Bluetooth ---
  # Serpantinum уже включает bluetooth (bluez); здесь — явные настройки поверх:
  # адаптер включается при загрузке (иначе после перезагрузки наушники/мышь отваливаются).
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        # fast connect: не ждать 30 сек, пока подключится следующее устройство
        FastConnectable = true;
      };
    };
  };

  # При каждом старте bluetoothd: включать Pairable (см. коммент у btPairableScript).
  systemd.services.bluetooth.serviceConfig.ExecStartPost = [ btPairableScript ];

  # Раз в 5 минут проверять, что адаптер на месте (см. коммент у btWatchdogScript).
  systemd.services.bluetooth-watchdog = {
    description = "Restart bluetoothd if adapter disappeared from the bus";
    serviceConfig = {
      Type = "oneshot";
      Restart = "no";
    };
    script = "${btWatchdogScript}";
  };
  systemd.timers.bluetooth-watchdog = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "1min";
      OnUnitActiveSec = "5min";
      Unit = "bluetooth-watchdog.service";
    };
  };

  # --- ПАКЕТЫ ---
  environment.systemPackages = with pkgs; [
    firefox git vscode kitty vim wget
    pywal imagemagick dart-sass
    wl-clipboard cliphist
    xdg-user-dirs
    # Сервисная панель: быстрая сводка о системе (уже есть как зависимость serpantinum)
    fastfetch
    obsidian
    nautilus
    yandex-music
    rose-pine-hyprcursor
    uv
    tgWsProxy
    telegram-desktop

    # opencode — ставится один раз и лежит в профиле, не качается при запуске
    inputs.opencode-nix.packages.${pkgs.system}.default

    # CLI GitHub
    gh

    # Инструменты для биндов и скриншотов
    grim slurp swappy fuzzel playerctl brightnessctl hyprpicker wireplumber
    # jq — для подсчёта окон в mayfastfetch.sh и в скриптах serpantinum
    jq
    # Зависимости screenshot.sh (grim satty wl-copy pactl quickshell zbarimg python3 + видео)
    satty wf-recorder gpu-screen-recorder zbar python3 pulseaudioFull quickshell
    # Dev: Java 21 (учебные проекты), Docker CLI/Compose (CLI добавляет virtualisation.docker)
    jdk21
    docker-compose
    lazydocker
  ];

  # --- Прокси-клиент Throne (Qt GUI + встроенный core, без ручной докачки) ---
  programs.throne = {
    enable = true;
    tunMode = {
      enable = true;
      setuid = true;
    };
  };

  # --- СЕРВИСЫ И ЭКСПЕРИМЕНТЫ ---
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Батарея: Serpantinum читает состояние через D-Bus сервис upower
  services.upower.enable = true;

  # --- Docker ---
  virtualisation.docker.enable = true;

  system.stateVersion = "24.11";
}
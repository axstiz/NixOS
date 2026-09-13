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

  # --- ПАКЕТЫ ---
  environment.systemPackages = with pkgs; [
    firefox git vscode kitty vim wget
    pywal imagemagick dart-sass
    wl-clipboard cliphist
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
    # Зависимости screenshot.sh (grim satty wl-copy pactl quickshell zbarimg python3 + видео)
    satty wf-recorder gpu-screen-recorder zbar python3 pulseaudioFull quickshell
    # Dev: Java 21 (учебные проекты), Docker CLI/Compose (CLI добавляет virtualisation.docker)
    jdk21
    docker-compose
    lazydocker
  ];

  # --- СЕРВИСЫ И ЭКСПЕРИМЕНТЫ ---
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Батарея: Serpantinum читает состояние через D-Bus сервис upower
  services.upower.enable = true;

  # --- Docker ---
  virtualisation.docker.enable = true;

  system.stateVersion = "24.11";
}
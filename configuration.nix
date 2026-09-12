{ config, pkgs, inputs, ... }:

let
  # TG WS Proxy — PyInstaller-бинарь (локальный MTProto-прокси над WebSocket для Telegram
  # Desktop). В nixpkgs отсутствует, ставим официальный релизный бэкенд. Бинарнику нужны
  # системные libc/libz — autoPatchelfHook подменяет интерпретатор и добавляет rpath.
  # Иконку стягиваем из исходников для рабочего .desktop и лаунчера Serpantinum.
  tgWsProxy = pkgs.stdenv.mkDerivation {
    pname = "tg-ws-proxy";
    version = "1.10.2";
    src = pkgs.fetchurl {
      url = "https://github.com/Flowseal/tg-ws-proxy/releases/download/v1.10.2/TgWsProxy_linux_amd64";
      hash = "sha256-VNB93hHbe0YLph4UHbwwT6an4Dc/s+1W5bE987HQpq0=";
    };
    dontUnpack = true;
    nativeBuildInputs = [ pkgs.autoPatchelfHook ];
    installPhase = ''
      runHook preInstall
      install -Dm755 $src $out/bin/tg-ws-proxy
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
    extraGroups = [ "networkmanager" "wheel" "video" ];
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
  ];

  # --- СЕРВИСЫ И ЭКСПЕРИМЕНТЫ ---
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Батарея: Serpantinum читает состояние через D-Bus сервис upower
  services.upower.enable = true;

  system.stateVersion = "24.11";
}
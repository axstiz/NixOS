{ config, pkgs, inputs, ... }:

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

    # opencode — ставится один раз и лежит в профиле, не качается при запуске
    inputs.opencode-nix.packages.${pkgs.system}.default

    # CLI GitHub
    gh

    # Инструменты для биндов и скриншотов
    grim slurp swappy fuzzel playerctl brightnessctl hyprpicker wireplumber
  ];

  # --- СЕРВИСЫ И ЭКСПЕРИМЕНТЫ ---
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  system.stateVersion = "24.11";
}
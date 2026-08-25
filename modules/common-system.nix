{
  config,
  pkgs,
  ...
}: {
  boot.loader.limine.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.limine.maxGenerations = 20;
  services.getty.autologinUser = "tim";

  boot.initrd.systemd.enable = true;
  boot.initrd.luks.devices."encrypted" = {
    crypttabExtraOpts = ["fido2-device=auto"];
  };

  time.timeZone = "America/New_York";
  services.timesyncd.enable = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;

  age.identityPaths = ["/home/tim/.age/agenix-identity.txt"];
  age.secrets.github-token = {
    file = ../secrets/github-token.age;
    owner = "tim";
    group = "users";
    mode = "0400";
  };
  age.secrets.donetick-token = {
    file = ../secrets/donetick-token.age;
    owner = "tim";
    group = "users";
    mode = "0400";
  };
  age.secrets.cf-access-client-secret = {
    file = ../secrets/cf-access-client-secret.age;
    owner = "tim";
    group = "users";
    mode = "0400";
  };

  networking.networkmanager.enable = true;
  services.tailscale.enable = true;

  services.syncthing = {
    enable = true;
    user = "tim";
    dataDir = "/home/tim";
    configDir = "/home/tim/.config/syncthing";
  };

  services.xserver = {
    enable = true;
    windowManager.oxwm.enable = true;
    displayManager.sessionCommands = ''
      xset s 5400 dpms 5400 5400 5400
    '';
  };

  services.pipewire = {
    enable = true;
    pulse.enable = true;
  };

  users.users.tim = {
    isNormalUser = true;
    extraGroups = ["wheel"];
    packages = with pkgs; [tree];
  };

  services.gvfs.enable = true;
  services.tumbler.enable = true;

  environment.systemPackages = with pkgs; [
    neovim
    wget
    nano
    impala
    nfs-utils
    cifs-utils
    rofi
    sbctl
    alacritty
    feh
    thunar
    thunar-volman
    thunar-archive-plugin
    picom
    dunst
    unzip
    onlyoffice-desktopeditors
    donetick-tui
  ];

  nixpkgs.config.allowUnfree = true;

  programs.firefox.enable = true;
  programs.dconf.enable = true;
  programs.i3lock.enable = true;

  fonts.packages = with pkgs; [nerd-fonts.jetbrains-mono];

  nix.settings.experimental-features = ["nix-command" "flakes"];

  fileSystems."/mnt/NAS" = {
    device = "//192.168.0.70/tim";
    fsType = "cifs";
    options = let
      automount_opts = "x-systemd.automount,noauto,x-systemd.idle-timeout=60,x-systemd.device-timeout=5s,x-systemd.mount-timeout=5s";
    in ["${automount_opts},credentials=/home/tim/nixos-dotfiles/secrets/smb-secrets"];
  };

  system.stateVersion = "25.11";
}

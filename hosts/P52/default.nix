{
  config,
  pkgs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ../../modules/common-system.nix
  ];

  networking.hostName = "nixos-tim";

  boot.loader.limine.secureBoot.enable = true;

  services.printing = {
    enable = true;
    drivers = with pkgs; [gutenprint foomatic-db-ppds cups-filters];
  };
  hardware.sane = {
    enable = true;
    extraBackends = [pkgs.sane-airscan];
  };

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  users.users.tim.extraGroups = ["scanner" "lp" "plugdev"];

  programs.pulseview.enable = true;

  environment.systemPackages = with pkgs; [
    tailscale
    simple-scan
    codex
    agenix-cli
    bolt-launcher
    runelite
  ];

  programs.steam = {
    enable = true;
    extraCompatPackages = with pkgs; [proton-ge-bin];
  };
  fonts.packages = with pkgs; [corefonts];

  hardware.nvidia = {
    modesetting.enable = true;
    open = false;
    powerManagement.enable = true;
    package = config.boot.kernelPackages.nvidiaPackages.legacy_580;
    prime = {
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };

  services.logind.settings.Login.HandleLidSwitch = "ignore";

  services.flatpak.enable = true;

  xdg.portal = {
    enable = true;
    extraPortals = [pkgs.xdg-desktop-portal-gtk];
    config.common.default = "gtk";
  };
}

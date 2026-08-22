{
  config,
  pkgs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ../../modules/common-system.nix
  ];

  networking.hostName = "nixos-itx";

  services.xserver.videoDriver = "nvidia";
  services.printing.enable = true;

  environment.systemPackages = with pkgs; [
    steam-run
    cifs-utils
    protonup-qt
  ];

  programs.steam = {
    enable = true;
    extraCompatPackages = with pkgs; [proton-ge-bin];
  };

  programs.firefox.policies = {
    AutoLaunchProtocolsFromOrigins = [
      {
        protocol = "adskidmgr";
        allowed_origins = [
          "https://signin.autodesk.com"
          "https://accounts.autodesk.com"
          "https://access.autodesk.com"
          "https://www.autodesk.com"
        ];
      }
    ];
  };

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    config.common.default = "gtk";
  };

  hardware.graphics.enable = true;
  hardware.graphics.enable32Bit = true;
  hardware.nvidia = {
    modesetting.enable = true;
    open = true;
    powerManagement.enable = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  fileSystems."/mnt/NAS" = {
    device = "//192.168.0.70/tim";
    fsType = "cifs";
    options = let
      automount_opts = "x-systemd.automount,noauto,x-systemd.idle-timeout=60,x-systemd.device-timeout=5s,x-systemd.mount-timeout=5s";
    in ["${automount_opts},credentials=/home/tim/nixos-dotfiles/secrets/smb-secrets"];
  };
}

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
    #protonup-qt  -- add back in for fusion
  ];

  # programs.nix-ld.enable = true;  # needed for Fusion 360 (steam-runtime-launch-client)

  programs.steam = {
    enable = true;
    extraCompatPackages = with pkgs; [proton-ge-bin];
  };

  # Fusion 360: allow browser to hand off adskidmgr:// OAuth callbacks without a dialog
  # programs.firefox.policies = {
  #   AutoLaunchProtocolsFromOrigins = [
  #     {
  #       protocol = "adskidmgr";
  #       allowed_origins = [
  #         "https://signin.autodesk.com"
  #         "https://accounts.autodesk.com"
  #         "https://access.autodesk.com"
  #         "https://www.autodesk.com"
  #       ];
  #     }
  #   ];
  # };

  # Provides org.freedesktop.portal.Settings so Firefox and other apps detect system dark mode.
  # Also needed by Fusion 360 for Steam Runtime URL opening — see fusion360.nix.
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

}

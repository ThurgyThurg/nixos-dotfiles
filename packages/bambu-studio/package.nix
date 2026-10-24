{ appimageTools, lib }:

appimageTools.wrapType2 {
  pname = "bambu-studio";
  version = "2.8.4.57";
  src = ../BambuStudio_ubu24-v02.08.04.57-20260922164607.AppImage;

  extraPkgs = pkgs: with pkgs; [
    libsecret
    xdg-utils
    webkitgtk_4_1
  ];

  meta = {
    description = "3D printing slicer for Bambu Lab printers";
    homepage = "https://bambulab.com/en/download/studio";
    license = lib.licenses.agpl3Plus;
    platforms = [ "x86_64-linux" ];
    mainProgram = "bambu-studio";
  };
}

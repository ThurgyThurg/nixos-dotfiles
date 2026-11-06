{ appimageTools, fetchurl, lib, makeDesktopItem }:

let
  pname = "pdfcraft";
  version = "0.19.0";
  src = fetchurl {
    url = "https://github.com/storytold/pdfcraft/releases/download/v${version}/pdfcraft-${version}-linux-x86_64.AppImage";
    hash = "sha256-fW9YdaTWjPH9K+jbnzBTFCwlBzUMF/GEEjDvJsIsCzY=";
  };
  desktopItem = makeDesktopItem {
    name = pname;
    exec = pname;
    icon = pname;
    desktopName = "PdfCraft";
    comment = "PDF crafting and processing tool";
    categories = [ "Office" "Utility" ];
  };
in
appimageTools.wrapType2 {
  inherit pname version src;

  extraInstallCommands = ''
    install -Dm444 ${desktopItem}/share/applications/${pname}.desktop \
      $out/share/applications/${pname}.desktop
  '';

  meta = {
    description = "PDF crafting and processing tool";
    homepage = "https://github.com/storytold/pdfcraft";
    license = lib.licenses.asl20;
    platforms = [ "x86_64-linux" ];
    mainProgram = pname;
  };
}

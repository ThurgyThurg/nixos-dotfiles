{ appimageTools, fetchurl, lib }:

let
  version = "0.18.2";
  src = fetchurl {
    url = "https://github.com/storytold/pdfcraft/releases/download/v${version}/pdfcraft-${version}-linux-x86_64.AppImage";
    hash = "sha256-vtsfgXPn65+h1YALZbQe07Wletk+VmHGqSGipFAkIpE=";
  };
in
appimageTools.wrapType2 {
  pname = "pdfcraft";
  inherit version src;

  meta = {
    description = "PDF crafting and processing tool";
    homepage = "https://github.com/storytold/pdfcraft";
    license = lib.licenses.asl20;
    platforms = [ "x86_64-linux" ];
    mainProgram = "pdfcraft";
  };
}

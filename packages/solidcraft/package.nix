{ appimageTools, fetchurl, lib }:

let
  version = "0.30.1";
  src = fetchurl {
    url = "https://github.com/bherbruck/solidcraft/releases/download/v${version}/solidcraft-${version}-linux-x86_64.AppImage";
    hash = "sha256-HODWGv04IA8MFieTGgSF8DuD4KiLHHTHXhoVAek4g10=";
  };
in
appimageTools.wrapType2 {
  pname = "solidcraft";
  inherit version src;

  meta = {
    description = "Parametric 3D CAD application";
    homepage = "https://github.com/bherbruck/solidcraft";
    license = lib.licenses.asl20;
    platforms = [ "x86_64-linux" ];
    mainProgram = "solidcraft";
  };
}

{ appimageTools, fetchurl, lib }:

let
  version = "0.44.1";
  src = fetchurl {
    url = "https://github.com/bherbruck/solidcraft/releases/download/v${version}/solidcraft-${version}-linux-x86_64.AppImage";
    hash = "sha256-bkcr1/VXo8BWTkVIxGCxuE2QYjfGivMn5X2UaxPlHPQ=";
  };
in
appimageTools.wrapType2 {
  pname = "solidcraft";
  inherit version src;

  extraInstallCommands = ''
    cat > $out/bin/solidcraft-cli <<EOF
#!/bin/sh
SOLIDCRAFT_APPIMAGE_CLI=1 exec "$out/bin/solidcraft" "\$@"
EOF
    chmod +x $out/bin/solidcraft-cli
  '';

  meta = {
    description = "Parametric 3D CAD application";
    homepage = "https://github.com/bherbruck/solidcraft";
    license = lib.licenses.asl20;
    platforms = [ "x86_64-linux" ];
    mainProgram = "solidcraft";
  };
}

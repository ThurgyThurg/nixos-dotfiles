{
  appimageTools,
  fetchurl,
  lib,
}:

let
  pname = "buzz";
  version = "0.5.9";

  src = fetchurl {
    url = "https://github.com/block/buzz/releases/download/desktop-v${version}/Buzz_${version}_amd64.AppImage";
    # Run `nix build`, it will fail and print the correct hash to paste here.
    hash = sha256:5af4c03db35385c561a99564458b445b6659c252c1ac72daf2a1c85a0c0a4a27;
  };

  appimageContents = appimageTools.extractType2 { inherit pname version src; };
in
appimageTools.wrapType2 {
  inherit pname version src;

  extraInstallCommands = ''
    install -m 444 -D ${appimageContents}/buzz-desktop.desktop $out/share/applications/${pname}.desktop
    substituteInPlace $out/share/applications/${pname}.desktop \
      --replace-fail 'Exec=AppRun' 'Exec=${pname}'
    cp -r ${appimageContents}/usr/share/icons $out/share
  '';

  meta = {
    description = "Self-hostable workspace where humans and AI agents collaborate in shared rooms, built on Nostr";
    homepage = "https://github.com/block/buzz";
    license = lib.licenses.asl20;
    platforms = [ "x86_64-linux" ];
    mainProgram = "buzz";
  };
}

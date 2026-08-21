{
  lib,
  stdenvNoCC,
  fetchurl,
  dpkg,
  buildFHSEnv,
  pkgs,
}:

let
  version = "0.5.9";

  buzz-unwrapped = stdenvNoCC.mkDerivation {
    pname = "buzz-unwrapped";
    inherit version;
    src = fetchurl {
      url = "https://github.com/block/buzz/releases/download/desktop-v${version}/Buzz_${version}_amd64.deb";
      hash = "sha256:400b00fc410b1fdeed66f30886e7d52f14a021315e29d632dcc0a28e18021c71";
    };
    nativeBuildInputs = [ dpkg ];
    unpackPhase = "dpkg-deb -x $src .";
    dontConfigure = true;
    dontBuild = true;
    dontStrip = true;
    dontPatchELF = true;
    installPhase = ''
      runHook preInstall
      mkdir -p $out
      cp -r usr/. $out/
      runHook postInstall
    '';
  };
in
buildFHSEnv {
  name = "buzz";
  runScript = "${buzz-unwrapped}/bin/buzz-desktop";

  profile = ''
    export GST_PLUGIN_SYSTEM_PATH_1_0=/usr/lib/gstreamer-1.0
    export WEBKIT_DISABLE_DMABUF_RENDERER=1
  '';

  targetPkgs = pkgs: with pkgs; [
    webkitgtk_4_1
    gtk3
    glib
    glib-networking
    libsoup_3
    cairo
    pango
    gdk-pixbuf
    harfbuzz
    librsvg
    atk
    at-spi2-atk
    at-spi2-core
    gsettings-desktop-schemas
    dconf
    openssl
    zlib
    curl
    nss
    nspr
    gst_all_1.gstreamer
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-good
    gst_all_1.gst-plugins-bad
    gst_all_1.gst-libav
    gst_all_1.gst-plugins-ugly
    libGL
    libglvnd
    mesa
    libdrm
    xorg.libX11
    xorg.libXext
    xorg.libXrender
    xorg.libXi
    xorg.libXcursor
    xorg.libXdamage
    xorg.libXfixes
    xorg.libXcomposite
    xorg.libXrandr
    xorg.libXtst
    xorg.libxcb
    wayland
    libxkbcommon
    fontconfig
    freetype
    alsa-lib
    libpulseaudio
    pipewire
    dbus
    libnotify
    expat
    libffi
    pcre2
  ];

  extraInstallCommands = ''
    mkdir -p $out/share
    cp -r ${buzz-unwrapped}/share/applications $out/share/ 2>/dev/null || true
    cp -r ${buzz-unwrapped}/share/icons $out/share/ 2>/dev/null || true
    for d in $out/share/applications/*.desktop; do
      [ -e "$d" ] || continue
      substituteInPlace "$d" \
        --replace-quiet "Exec=buzz-desktop" "Exec=buzz" \
        --replace-quiet "Exec=/usr/bin/buzz-desktop" "Exec=buzz"
    done
  '';

  meta = {
    description = "Self-hostable workspace where humans and AI agents collaborate in shared rooms, built on Nostr";
    homepage = "https://github.com/block/buzz";
    license = lib.licenses.asl20;
    platforms = [ "x86_64-linux" ];
    mainProgram = "buzz";
  };
}

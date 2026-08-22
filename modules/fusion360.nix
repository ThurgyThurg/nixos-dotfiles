# fusion360.nix
#
# Declarative replacement for Kotya31415/Fusion180 on NixOS.
#
# The upstream project is two bash scripts. Everything they do EXCEPT running
# Autodesk's installer .exe is config, so it belongs in your Nix files. The
# one imperative step stays imperative (it populates a Wine prefix in $HOME).
#
# This file is written as a Home Manager module. Import it from your HM config:
#   imports = [ ./fusion360.nix ];
# The system-level bits (Steam, 32-bit graphics) are noted at the bottom.

{ config, lib, pkgs, ... }:

let
  # Proton compat-data dir. The actual Wine prefix ends up at $HOME/.fusion180/pfx
  prefixDir = ".fusion180";

  # Pin this. A GE-Proton version bump can break an existing prefix, and on a
  # nixpkgs update you'd get one without warning. See "Pinning" note at bottom.
  protonGE = pkgs.proton-ge-bin;

  # Shared preamble: same env vars the upstream scripts export, plus a
  # proton-path resolver that tolerates nixpkgs layout changes and falls back
  # to anything ProtonUp-Qt dropped in compatibilitytools.d.
  preamble = ''
    export PROTON_USE_WINED3D=0
    export DXVK_ASYNC=1
    export NO_AT_BRIDGE=1
    export WINEDLLOVERRIDES="bcp47langs="
    export STEAM_COMPAT_DATA_PATH="$HOME/${prefixDir}"
    export STEAM_COMPAT_CLIENT_INSTALL_PATH="$HOME/.local/share/Steam"
    mkdir -p "$STEAM_COMPAT_DATA_PATH" "$STEAM_COMPAT_CLIENT_INSTALL_PATH"

    PROTON=""
    for candidate in \
      "${protonGE}/proton" \
      "${protonGE}/share/steamcompattool/proton"
    do
      if [ -x "$candidate" ]; then
        PROTON="$candidate"
        break
      fi
    done
    if [ -z "$PROTON" ]; then
      PROTON=$(find "$HOME/.local/share/Steam/compatibilitytools.d" \
        -maxdepth 2 -name proton -type f 2>/dev/null | sort -V | tail -n1 || true)
    fi
    if [ -z "$PROTON" ]; then
      echo "No GE-Proton entrypoint found. Check: ls ${protonGE}" >&2
      exit 1
    fi
  '';

  # One-time installer. Replaces installer.sh's proton-run section only.
  fusion-install = pkgs.writeShellApplication {
    name = "fusion360-install";
    runtimeInputs = [ pkgs.steam-run pkgs.findutils pkgs.coreutils ];
    text = ''
      ${preamble}

      EXE="''${1:-}"
      if [ -z "$EXE" ]; then
        EXE=$(find "$HOME/Downloads" -maxdepth 1 -iname '*Fusion*.exe' \
          | head -n1 || true)
      fi
      if [ -z "$EXE" ]; then
        echo "No Fusion installer found. Download it from Autodesk into" >&2
        echo "$HOME/Downloads, or pass the path: fusion360-install /path/to.exe" >&2
        exit 1
      fi

      echo "Installing with: $PROTON"
      echo "Installer:       $EXE"
      echo "Do NOT log in when the login screen appears during setup."
      exec steam-run "$PROTON" run "$EXE"
    '';
  };

  # Replaces launch-fusion.sh.
  fusion-launch = pkgs.writeShellApplication {
    name = "fusion360";
    runtimeInputs = [ pkgs.steam-run pkgs.findutils pkgs.coreutils ];
    text = ''
      ${preamble}

      FUSION=$(find "$STEAM_COMPAT_DATA_PATH" -name Fusion360.exe 2>/dev/null \
        | head -n1 || true)
      if [ -z "$FUSION" ]; then
        echo "Fusion360.exe not found. Run fusion360-install first." >&2
        exit 1
      fi

      exec steam-run "$PROTON" run "$FUSION" "''${1:-}"
    '';
  };

  # Replaces the adskidmgr-handler.sh heredoc.
  adsk-idmgr = pkgs.writeShellApplication {
    name = "adskidmgr-handler";
    runtimeInputs = [ pkgs.steam-run pkgs.findutils pkgs.coreutils ];
    text = ''
      ${preamble}

      IDM=$(find "$STEAM_COMPAT_DATA_PATH" -name AdskIdentityManager.exe \
        2>/dev/null | head -n1 || true)
      if [ -z "$IDM" ]; then
        echo "AdskIdentityManager.exe not found." >&2
        exit 1
      fi

      exec steam-run "$PROTON" run "$IDM" "''${1:-}"
    '';
  };

in
{
  home.packages = [ fusion-install fusion-launch adsk-idmgr ];

  # Replaces the .desktop heredocs + update-desktop-database.
  # Upstream only made hidden URI handlers; this also gives you a real menu entry.
  xdg.desktopEntries = {
    fusion360 = {
      name = "Fusion 360";
      genericName = "3D CAD";
      exec = "fusion360 %u";
      terminal = false;
      categories = [ "Graphics" "Engineering" ];
      mimeType = [ "x-scheme-handler/adsk" ];
    };

    adskidmgr = {
      name = "Autodesk Identity Manager";
      exec = "adskidmgr-handler %u";
      terminal = false;
      noDisplay = true;
      mimeType = [ "x-scheme-handler/adskidmgr" ];
    };
  };

  # Replaces the sed surgery on ~/.config/mimeapps.list.
  # NOTE: enabling this makes mimeapps.list a read-only symlink into the store,
  # so GUI "set as default" actions stop working. If that bothers you, drop this
  # block and edit mimeapps.list by hand once.
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "x-scheme-handler/adsk" = "fusion360.desktop";
      "x-scheme-handler/adskidmgr" = "adskidmgr.desktop";
    };
  };
}

# ---------------------------------------------------------------------------
# SYSTEM-LEVEL (configuration.nix, not this file)
# ---------------------------------------------------------------------------
#
#   programs.steam.enable = true;      # also pulls in steam-run properly
#   hardware.graphics.enable32Bit = true;
#
# NVIDIA hybrid laptops (the tested config upstream): set up PRIME offload with
# hardware.nvidia.prime.offload.enable, then launch via your nvidia-offload
# wrapper, or just let it run on the Intel iGPU — Fusion is fine on Iris Xe.
#
# ---------------------------------------------------------------------------
# PINNING
# ---------------------------------------------------------------------------
#
# `protonGE = pkgs.proton-ge-bin` follows your channel. When nixpkgs bumps it,
# your existing ~/.fusion180 prefix gets opened by a different Proton, which
# occasionally breaks things. To pin, add a second nixpkgs input to your flake
# at a known-good rev and use `pkgs-pinned.proton-ge-bin` here instead.
#
# ---------------------------------------------------------------------------
# IF steam-run ISN'T ENOUGH
# ---------------------------------------------------------------------------
#
# Newer GE-Proton expects the Steam Linux Runtime container, which `proton run`
# bypasses. If you hit loader/library errors, swap to umu-launcher, which sets
# the runtime up correctly outside Steam. Add pkgs.umu-launcher to runtimeInputs
# and replace the exec lines with:
#
#   GAMEID=0 PROTONPATH="$(dirname "$PROTON")" exec umu-run "$FUSION"
#
# ---------------------------------------------------------------------------
# STATE THAT NIX DOES NOT MANAGE
# ---------------------------------------------------------------------------
#
# ~/.fusion180 is a mutable Wine prefix containing the actual Autodesk install.
# It is not reproducible and not in your config. Back it up; a rebuild won't
# recreate it. Deleting it means re-running fusion360-install.

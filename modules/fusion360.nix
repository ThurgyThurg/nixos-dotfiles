# fusion360.nix — DISABLED
#
# This module works but has UI issues on the 45" ultrawide (5120x1440):
# dialog boxes bounce and can't be closed. Disabled until upstream Wine/Proton
# fixes the dialog-positioning bug on non-standard window managers.
#
# ---------------------------------------------------------------------------
# HOW TO RE-ENABLE
# ---------------------------------------------------------------------------
#
# 1. home-itx.nix — uncomment the import:
#      ./modules/fusion360.nix
#
# 2. hosts/itx/default.nix — uncomment these two blocks:
#      programs.nix-ld.enable = true;
#      programs.firefox.policies { AutoLaunchProtocolsFromOrigins ... }
#    (xdg.portal is already enabled for system-wide dark mode support)
#
# 3. Run: nrs
#
# 4. If first install: run `fusion360-install` (picks up the .exe from ~/Downloads).
#    If prefix already exists (~/.fusion180): just run `fusion360`.
#
# 5. Auth flow: Fusion opens Chromium → log in → adskidmgr:// redirect is caught
#    by adskidmgr-handler which injects AdskIdentityManager into the running
#    Proton container via steam-runtime-launch-client.
#
# ---------------------------------------------------------------------------
# KNOWN ISSUES (as of 2026-08-22)
# ---------------------------------------------------------------------------
#
# - Dialog boxes bounce on ultrawide (5120x1440) with oxwm. Wine's dialog
#   centering conflicts with the WM. Setting Managed=N in user.reg helps but
#   removes WM decoration from all Wine windows. Investigate gamescope as a
#   contained XWayland compositor to work around this.
#
# - The Wine prefix has Managed=N set in ~/.fusion180/pfx/user.reg. Revert
#   by removing that line if needed.
#
# ---------------------------------------------------------------------------
# DECLARATIVE REPLACEMENT for Kotya31415/Fusion180 on NixOS.
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
    export WINEDLLOVERRIDES="bcp47langs=;NuDiagnostics=;NuDiagnostics10="
    # Wine doesn't apply DST, so it reports EST (UTC-5) instead of EDT (UTC-4).
    # Fusion 360 compares local clock directly against server UTC — setting TZ=UTC
    # makes Wine report UTC as local time, so both sides match.
    export TZ=UTC
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
    runtimeInputs = [ pkgs.umu-launcher pkgs.findutils pkgs.coreutils ];
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

      echo "Installing with: $PROTON (via umu-launcher)"
      echo "Installer:       $EXE"
      echo "Do NOT log in when the login screen appears during setup."
      GAMEID=0 PROTONPATH="$(dirname "$PROTON")" exec umu-run "$EXE"
    '';
  };

  # Replaces launch-fusion.sh.
  fusion-launch = pkgs.writeShellApplication {
    name = "fusion360";
    runtimeInputs = [ pkgs.umu-launcher pkgs.findutils pkgs.coreutils pkgs.gnugrep ];
    text = ''
      ${preamble}

      FUSION=$(find "$STEAM_COMPAT_DATA_PATH" -name Fusion360.exe 2>/dev/null \
        | head -n1 || true)
      if [ -z "$FUSION" ]; then
        echo "Fusion360.exe not found. Run fusion360-install first." >&2
        exit 1
      fi

      BUSNAME_FILE="$STEAM_COMPAT_DATA_PATH/container-bus-name"
      rm -f "$BUSNAME_FILE"

      # while-read loop runs in a subshell but writes to the filesystem,
      # so BUSNAME_FILE is visible to adskidmgr-handler when it runs later.
      GAMEID=0 PROTONPATH="$(dirname "$PROTON")" umu-run "$FUSION" "''${1:-}" 2>&1 | \
        while IFS= read -r _line; do
          printf '%s\n' "$_line" >&2 || true
          if [ ! -f "$BUSNAME_FILE" ] && \
             printf '%s\n' "$_line" | grep -q 'bus-name='; then
            printf '%s\n' "$_line" | grep -o 'bus-name=[^ ]*' | \
              cut -d= -f2 | tr -d '\n' > "$BUSNAME_FILE" || true
          fi
        done || true

      rm -f "$BUSNAME_FILE"
    '';
  };

  # Replaces the adskidmgr-handler.sh heredoc.
  adsk-idmgr = pkgs.writeShellApplication {
    name = "adskidmgr-handler";
    runtimeInputs = [ pkgs.umu-launcher pkgs.findutils pkgs.coreutils ];
    text = ''
      LOGFILE="/tmp/adskidmgr-handler.log"
      exec >> "$LOGFILE" 2>&1
      echo "=== $(date) ==="
      echo "Args: ''${*:-<none>}"

      ${preamble}

      echo "PROTON: $PROTON"
      echo "STEAM_COMPAT_DATA_PATH: $STEAM_COMPAT_DATA_PATH"

      IDM=$(find "$STEAM_COMPAT_DATA_PATH" -name AdskIdentityManager.exe \
        2>/dev/null | head -n1 || true)
      if [ -z "$IDM" ]; then
        echo "AdskIdentityManager.exe not found." >&2
        exit 1
      fi

      echo "IDM: $IDM"

      BUSNAME_FILE="$STEAM_COMPAT_DATA_PATH/container-bus-name"
      BUSNAME=""
      if [ -f "$BUSNAME_FILE" ]; then
        BUSNAME=$(cat "$BUSNAME_FILE")
      fi

      LAUNCH_CLIENT=$(find "$HOME/.local/share/umu" \
        -path "*/pressure-vessel/bin/steam-runtime-launch-client" \
        -not -path "*/var/tmp*" \
        -type f 2>/dev/null | head -n1)

      if [ -n "$BUSNAME" ] && [ -n "$LAUNCH_CLIENT" ] && [ -x "$LAUNCH_CLIENT" ]; then
        echo "Injecting into existing Fusion 360 container (bus-name: $BUSNAME)"
        export WINEPREFIX="$STEAM_COMPAT_DATA_PATH/pfx"
        exec "$LAUNCH_CLIENT" --bus-name="$BUSNAME" -- wine "$IDM" "''${1:-}"
      else
        echo "No running container found (BUSNAME='$BUSNAME' LAUNCH_CLIENT='$LAUNCH_CLIENT'), starting new umu-run"
        GAMEID=0 PROTONPATH="$(dirname "$PROTON")" exec umu-run "$IDM" "''${1:-}"
      fi
    '';
  };

  fusion-kill = pkgs.writeShellApplication {
    name = "fusion360-kill";
    runtimeInputs = [ pkgs.procps ];
    text = ''
      pkill -f "Fusion360.exe" || true
      pkill -f "AdskIdentityManager.exe" || true
      pkill -f "umu-run" || true
    '';
  };

in
{
  home.packages = [ fusion-install fusion-launch adsk-idmgr fusion-kill ];

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

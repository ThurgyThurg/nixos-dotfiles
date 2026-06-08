{
  config,
  pkgs,
  ...
}: let
  dotfiles = "${config.home.homeDirectory}/nixos-dotfiles/config";
  create_symlink = path: config.lib.file.mkOutOfStoreSymlink path;

  configs = {
    oxwm = "oxwm";
    alacritty = "alacritty";
    btop = "btop";
    obsidian = "obsidian";
  };
in {
  imports = [
    ./modules/theme.nix
  ];

  home.username = "tim";
  home.homeDirectory = "/home/tim";
  home.stateVersion = "25.11";
  home.file.".xinitrc".source = create_symlink "${dotfiles}/xinitrc";

  home.packages = with pkgs; [
    python3
    libreoffice-fresh
    _1password-cli
    _1password-gui
    htop
    btop
    obsidian
    cliamp
    bluetui
    claude-code
    tmux
    poppler-utils
    pandoc
    zathura
    snipaste
    redshift

    (pkgs.writeShellApplication {
      name = "ns";
      runtimeInputs = with pkgs; [
        fzf
        nix-search-tv
      ];
      text = builtins.readFile "${pkgs.nix-search-tv.src}/nixpkgs.sh";
    })
  ];

  xdg.configFile =
    builtins.mapAttrs
    (name: subpath: {
      source = create_symlink "${dotfiles}/${subpath}";
      recursive = true;
    })
    configs;
  programs.zed-editor = import ./modules/zed-editor {
    inherit pkgs;
  };
  programs.git = {
    enable = true;
    settings = {
      user.name = "ThurgyThurg";
      user.email = "tim@graham29.com";
      init.defaultBranch = "main";
    };
  };
  programs.gh = {
    enable = true;
    settings.git_protocol = "https";
    gitCredentialHelper.enable = true;
  };
  programs.autorandr = {
    enable = true;
    profiles = {
      "undocked" = {
        fingerprint = {
          eDP-1 = "00ffffffffffff000dae4c1500000000101e0104a5221378030f95ae5243b0260f505400000001010101010101010101010101010101636300a0a0a0775030206a0058c110000018000000fd0c30a5020246010a202020202020000000fe00434d4e0a202020202020202020000000fe004e3135364b4d452d474e410a20018e701379000003011450110184ff099f002f001f009f0576000500090000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005990";
        };
        config = {
          eDP-1 = {
            enable = true;
            primary = true;
            mode = "2560x1440";
            rate = "60.00";
            position = "0x0";
          };
        };
      };
      "docked" = {
        fingerprint = {
          eDP-1 = "00ffffffffffff000dae4c1500000000101e0104a5221378030f95ae5243b0260f505400000001010101010101010101010101010101636300a0a0a0775030206a0058c110000018000000fd0c30a5020246010a202020202020000000fe00434d4e0a202020202020202020000000fe004e3135364b4d452d474e410a20018e701379000003011450110184ff099f002f001f009f0576000500090000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005990";
          DP-1-1 = "00ffffffffffff0025e3faff0000000002230104b56d1e78bbdd45ae4f44ad260d5054a54b00d1c08140818081c0714fa9c0b3c00101023a801871382d40302035003f324100001a000000fd003078b2b26e010a202020202020000000fc0034354331520a20202020202020000000ff0030303030303030303030303030025c020330f14a01020304901112131f3f23090707830100006d1a000002113078000000000000e305e301e60607016260266a5e00a0a0a02950302035003f324100001a70c200a0a0a05550302035003f324100001e000000000000000000000000000000000000000000000000000000000000000000000000000000000000003c7012790000030128d3bc0084ff133f012f8021009f05280003000500a7790104ff133f012f8021009f052800030005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002590";
        };
        config = {
          eDP-1 = {
            enable = false;
            primary = false;
          };
          DP-1-1 = {
            enable = true;
            primary = true;
            mode = "5120x1440";
            rate = "120.00";
            position = "0x0";
          };
        };
      };
    };
  };
  programs.bash = {
    enable = true;
    shellAliases = {
      nrs = "sudo nixos-rebuild switch --flake ~/nixos-dotfiles#nixos-tim";
      ts2 = "tailscale --socket=/run/tailscale2/tailscaled.sock";
    };
    initExtra = ''
      if [ -r /run/agenix/github-token ]; then
        export GH_TOKEN="$(cat /run/agenix/github-token)"
      fi
    '';
  };
}

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
    cliamp = "cliamp";
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
    redshift
    flameshot
    orca-slicer
    discord
    pamixer
    pavucontrol

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
  programs.autorandr = {
    enable = true;
    profiles = {
      "desktop" = {
        fingerprint = {
          DP-2 = "00ffffffffffff004c2d9c0f000000002b1c0104b57722783ba2a1ad4f46a7240e5054bfef80714f810081c08180a9c0b3009500d1c074d600a0f038404030203a00a9504100001a000000fd003078bebe61010a202020202020000000fc00433439524739780a2020202020000000ff004831414b3530303030300a202002ce02032cf046105a405b3f5c2309070783010000e305c0006d1a0000020f307800048b127317e60605018b7312565e00a0a0a0295030203500a9504100001a584d00b8a1381440f82c4500a9504100001e1a6800a0f0381f4030203a00a9504100001af4b000a0f038354030203a00a9504100001a0000000000000000000000af701279000003013c57790188ff139f002f801f009f055400020009006c370108ff139f002f801f009f0545000200090033b70008ff139f002f801f009f0528000200090000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f390";
        };
        config = {
          DP-2 = {
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
  programs.bash = {
    enable = true;
    shellAliases = {
      nrs = "sudo nixos-rebuild switch --flake ~/nixos-dotfiles#nixos-itx";
    };
    initExtra = ''
      if [ -r /run/agenix/github-token ]; then
        export GH_TOKEN="$(cat /run/agenix/github-token)"
      fi
    '';
  };
}

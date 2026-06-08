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
    snip
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
  programs.autorandr = {
    enable = true;
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
      nrs = "sudo nixos-rebuild switch --flake ~/nixos-dotfiles#nixos-tim";
    };
    initExtra = ''
      if [ -r /run/agenix/github-token ]; then
        export GH_TOKEN="$(cat /run/agenix/github-token)"
      fi
    '';
  };
}

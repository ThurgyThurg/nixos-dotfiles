{
  config,
  pkgs,
  ...
}: let
  dotfiles = "${config.home.homeDirectory}/nixos-dotfiles/config";
  create_symlink = path: config.lib.file.mkOutOfStoreSymlink path;
  buzz = pkgs.callPackage ../packages/buzz_desktop/package.nix {};
  configs = {
    oxwm = "oxwm";
    alacritty = "alacritty";
    btop = "btop";
    obsidian = "obsidian";
    cliamp = "cliamp";
  };
in {
  imports = [./theme.nix];

  home.username = "tim";
  home.homeDirectory = "/home/tim";
  home.stateVersion = "25.11";
  home.file.".xinitrc".source = create_symlink "${dotfiles}/xinitrc";
  home.file.".config/openlogi".source =
    config.lib.file.mkOutOfStoreSymlink
    "${config.home.homeDirectory}/nixos-dotfiles/config/openlogi";

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
    flameshot
    redshift
    pavucontrol
    buzz
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

  programs.zed-editor = import ./zed-editor {inherit pkgs;};

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
    initExtra = ''
      if [ -r /run/agenix/github-token ]; then
        export GH_TOKEN="$(cat /run/agenix/github-token)"
      fi
      if [ -r /run/agenix/donetick-token ]; then
        export DONETICK_TOKEN="$(cat /run/agenix/donetick-token)"
      fi
      export DONETICK_URL="https://tasks.graham29.com"
      if [ -r /run/agenix/cf-access-client-secret ]; then
        export CF_ACCESS_CLIENT_SECRET="$(cat /run/agenix/cf-access-client-secret)"
      fi
      export CF_ACCESS_CLIENT_ID="b75e77fbd652be36137ab8205d3bb467.access"
    '';
  };
}

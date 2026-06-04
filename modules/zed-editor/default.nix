{pkgs}: let
  extentions = import ./extensions.nix;
  terminal = import ./terminal.nix;
  lsp = import ./lsp.nix;
  settings = import ./settings.nix;
in {
  enable = true;
  extensions = extentions;
  userSettings =
    settings
    // {
      terminal = terminal;
      lsp = lsp;
    };
  extraPackages = with pkgs; [
    nil
    nixd
    nixfmt-frc-style
    lua-language-server
    clang-tools
    gopls
    rust-analyzer
    pyright
    alejandra
    dockerfile-language-server-nodejs
    docker-compose-language-service
    vscode-langservers-extracted
  ];
}

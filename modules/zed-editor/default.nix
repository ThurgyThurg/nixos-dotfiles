{pkgs}: let
  extensions = import ./extensions.nix;
  terminal = import ./terminal.nix;
  lsp = import ./lsp.nix;
  settings = import ./settings.nix;
in {
  enable = true;
  extensions = extensions;
  userSettings =
    settings
    // {
      terminal = terminal;
      lsp = lsp;
    };
  extraPackages = with pkgs; [
    nixd
    lua-language-server
    clang-tools
    gopls
    rust-analyzer
    pyright
    alejandra
    dockerfile-language-server
    docker-compose-language-service
    vscode-langservers-extracted
  ];
}

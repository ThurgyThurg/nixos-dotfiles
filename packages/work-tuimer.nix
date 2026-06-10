# packages/work-tuimer.nix
{pkgs}:
pkgs.rustPlatform.buildRustPackage rec {
  pname = "work-tuimer";
  version = "0.3.1";

  src = pkgs.fetchFromGitHub {
    owner = "Kamyil";
    repo = "work-tuimer";
    rev = "v${version}";
    hash = "sha256-vtso5Sib004UbkVA6QStexLZydLuTqcb8W2Bgf7g8CU=";
  };

  cargoHash = "sha256-UdjJ/lzSmsBGrQA/76JLIVZr4eEt/atEJdXvnWlxTWs=";
}

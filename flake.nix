{
  description = "nixos-tim";
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    oxwm = {
      url = "github:tonybanters/oxwm";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-hardware = {
      url = "github:NixOS/nixos-hardware";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    donetick-tui = {
      url = "github:ThurgyThurg/donetick-tui";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    openlogi = {
      url = "github:AprilNEA/OpenLogi";
    };
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = {
    self,
    nixpkgs,
    home-manager,
    nixos-hardware,
    agenix,
    oxwm,
    donetick-tui,
    openlogi,
    rust-overlay,
    ...
  }: let
    openlogiModule = {pkgs, ...}: {
      nixpkgs.overlays = [rust-overlay.overlays.default];
      programs.openlogi = {
        enable = true;
        package =
          openlogi.packages.${pkgs.stdenv.hostPlatform.system}.default.override {
            rustPlatform = pkgs.makeRustPlatform {
              cargo = pkgs.rust-bin.stable."1.98.0".minimal;
              rustc = pkgs.rust-bin.stable."1.98.0".minimal;
            };
          };
      };
    };

    mkSystem = {
      host,
      hm-config,
      extraModules ? [],
    }:
      nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules =
          [
            {
              nixpkgs.overlays = [
                (final: prev: {
                  donetick-tui = donetick-tui.packages.${prev.stdenv.hostPlatform.system}.default;
                })
              ];
            }
            agenix.nixosModules.default
            openlogi.nixosModules.default
            openlogiModule
            home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                users.tim = import hm-config;
                backupFileExtension = "backup";
              };
            }
          ]
          ++ extraModules
          ++ [host];
      };
  in {
    nixosConfigurations.nixos-tim = mkSystem {
      host = ./hosts/P52;
      hm-config = ./home-P52.nix;
      extraModules = [nixos-hardware.nixosModules.lenovo-thinkpad-p52];
    };
    nixosConfigurations.nixos-itx = mkSystem {
      host = ./hosts/itx;
      hm-config = ./home-itx.nix;
    };
  };
}

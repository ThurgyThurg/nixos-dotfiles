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
    ...
  }: {
    nixosConfigurations.nixos-tim = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        {
          nixpkgs.overlays = [
            (final: prev: {
              donetick-tui = donetick-tui.packages.${prev.system}.default;
            })
          ];
        }
        ./hosts/P52
        nixos-hardware.nixosModules.lenovo-thinkpad-p52
        agenix.nixosModules.default
        openlogi.nixosModules.default
          { programs.openlogi.enable = true; }
        home-manager.nixosModules.home-manager

        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            users.tim = import ./home-P52.nix;
            backupFileExtension = "backup";
          };
        }
      ];
    };
    nixosConfigurations.nixos-itx = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./hosts/itx
        agenix.nixosModules.default
        openlogi.nixosModules.default
          { programs.openlogi.enable = true; }
        home-manager.nixosModules.home-manager
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            users.tim = import ./home-itx.nix;
            backupFileExtension = "backup";
          };
        }
      ];
    };
  };
}

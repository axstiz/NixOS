{
  description = "NixOS Workstation Config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    serpantinum = {
      # Собираем со своим пином nixpkgs, как тестировал автор, — гарантия совместимости.
      # git+https вместо github: — tarball-архив GitHub на этой сети режется (Truncated tar).
      url = "git+https://github.com/ilyamiro/serpantinum?shallow=1";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    opencode-nix = {
      url = "github:dan-online/opencode-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs: {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        ./configuration.nix
        inputs.serpantinum.nixosModules.default
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.backupFileExtension = "hm-bak";
          home-manager.extraSpecialArgs = { inherit inputs; };
          home-manager.sharedModules = [ inputs.serpantinum.homeManagerModules.default ];
          home-manager.users.litsummer = import ./home.nix;
        }
      ];
    };
  };
}
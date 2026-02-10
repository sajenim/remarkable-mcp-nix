{
  description = "NixOS and Home Manager modules for remarkable-mcp with secrets management";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }: {
    nixosModules = {
      default = self.nixosModules.remarkable-mcp;
      remarkable-mcp = import ./modules/default.nix;
    };

    homeManagerModules = {
      default = self.homeManagerModules.remarkable-mcp;
      remarkable-mcp = import ./modules/home-manager.nix;
    };
  };
}

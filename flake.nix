{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=25.05";
  };

  outputs = { self, nixpkgs }:
  let 
    system = "x86_64-linux";
    pkgs = import nixpkgs { inherit system; };
  in 
  {
    devShells.${system}.default = pkgs.mkShell {
      packages = with pkgs; [
        git
        gnumake
        go_1_23
        gotools
        revive
        nix
      ];

      # TODO
    };
  };
}

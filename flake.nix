{
  description = "STM32CubeIDE";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
      stm32cubeide = pkgs.callPackage ./stm32cubeide.nix { };
    in
    {
      packages.${system}.default = stm32cubeide;

      apps.${system}.default = {
        type = "app";
        program = "${stm32cubeide}/bin/stm32cubeide";
      };

      devShells.${system}.default = pkgs.mkShell {
        name = "stm32cubeide-shell";
        packages = [ stm32cubeide ];
      };
    };
}

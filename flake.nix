{
  description = "STM32CubeIDE";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = { self, nixpkgs }:
  let
    pkgs = import nixpkgs {
      system = "x86_64-linux";
    };
    stm32cubeide = pkgs.callPackage ./stm32cubeide.nix {};
  in
  {
    devShell.x86_64-linux = pkgs.mkShell {
      buildInputs = [
        stm32cubeide
      ];
    };
  };
}

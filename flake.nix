{
  description = "STM32CubeIDE";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = { self, nixpkgs }:
  let
    system = "x86_64-linux";
    pkgs = import nixpkgs {
      inherit system;
    };
    stm32cubeide = pkgs.callPackage ./stm32cubeide.nix {};
  in
  {
    packages.${system}.default = stm32cubeide;
  };
}

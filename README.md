# STM32CubeIDE Nix Flake

This flake packages [STM32CubeIDE](https://www.st.com/en/development-tools/stm32cubeide.html) for NixOS.

It provides a FHS (Filesystem Hierarchy Standard) environment for STM32CubeIDE to ensure compatibility.

## Features

-   **FHS Environment**: Runs STM32CubeIDE in an isolated FHS environment to provide the filesystem layout it expects.
-   **GDB Compatibility**: Builds a compatible version of `ncurses5` to ensure the bundled GDB works correctly, enabling debugging on your projects.
-   **ST-Link Server**: Installs the `st-link-server` and corresponding `udev` rules to allow flashing and debugging STM32 microcontrollers.

## Prerequisites

> **Note**: STM32CubeIDE is unfree software. You must download it manually and add it to the Nix store before using this flake.

1.  Go to the [STM32CubeIDE product page](https://www.st.com/en/development-tools/stm32cubeide.html) and download the "Linux installer" zip file (e.g., `st-stm32cubeide_1.19.0..._amd64.sh.zip`).
2.  Add the downloaded file to your Nix store. Replace `/path/to/your/download.zip` with the actual path to the file:
    ```sh
    nix-store --add-fixed sha256 /path/to/your/st-stm32cubeide_*.sh.zip
    ```
    The command will output a Nix store path and a SHA256 hash. The hash must match the one specified in `stm32cubeide.nix`.

## Usage

### Run the IDE

To run STM32CubeIDE directly:

```sh
nix run github:qdl/stm32cubeide.nix
```

### Development Shell

To enter a development shell where the `stm32cubeide` command is available:

```sh
nix develop github:qdl/stm32cubeide.nix
```

Inside the shell, you can start the IDE by running:

```sh
stm32cubeide
```

### Build the Package

To build the package without running it:

```sh
nix build github:qdl/stm32cubeide.nix
```

The result will be a symlink `./result` pointing to the package in the Nix store.

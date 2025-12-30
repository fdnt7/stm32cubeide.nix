{
  stdenv,
  buildFHSEnv,
  autoPatchelfHook,
  unzip,
  gtk3,
  cairo,
  glib,
  webkitgtk,
  libusb1,
  libsecret,
  alsa-lib,
  bzip2,
  openssl,
  udev,
  tlf,
  xorg,
  fontconfig,
  pcsclite,
  python3,
  requireFile,
  ...
}:
let
  cubeide-version = "1.19.0_25607_20250703_0907";

  # Build ncurses 5.7 from source, as it contains the older
  # symbols required by the gdb binary.
  ncurses-5-7 = stdenv.mkDerivation {
    pname = "ncurses";
    version = "5.7";

    src = builtins.fetchurl {
      url = "https://ftp.gnu.org/pub/gnu/ncurses/ncurses-5.7.tar.gz";
      sha256 = "1x4q6kma6zgg438llbgiac3kik7j2lln9v97jdffv3fyqyjxx6qa";
    };

    # We need to build with wide character support for libncursesw.so.5
    configureFlags = [
      "--with-shared"
      "--enable-widec"
      "--without-cxx"
      "--without-cxx-binding"
    ];

    NIX_CFLAGS_COMPILE = "-Wno-error=format-security";

    # The gdb binary also needs libtinfo.so.5, which is built by ncurses
    postInstall = ''
      ln -s libncursesw.so $out/lib/libtinfo.so.5
      ln -s libncursesw.so $out/lib/libncurses.so.5
    '';
  };

  stm32cubeide = stdenv.mkDerivation {
    name = "stm32cubeide-full";
    version = "1.19.0";

    src = requireFile rec {
      name = "st-stm32cubeide_${cubeide-version}_amd64.sh.zip";
      url = "https://www.st.com/en/development-tools/stm32cubeide.html";
      message = ''
        This Nix expression requires that ${name} already be part of the store. To
        obtain it you need to navigate to ${url} and download it.

        and then add the file to the Nix store using either:

          nix-store --add-fixed sha256 ${name}

        or

          nix-prefetch-url --type sha256 file:///path/to/${name}
      '';
      sha256 = "0v9wkjv1ibw04jx5agjra9ny274x8ahys98281h1ihdjpyzrfdzs";
    };

    dontUnpack = true;

    nativeBuildInputs = [
      autoPatchelfHook
      unzip
    ];
    buildInputs = [
      stdenv.cc.cc.lib # libstdc++.so.6
      libsecret
      alsa-lib
      bzip2
      openssl
      udev
      ncurses-5-7
      tlf
      fontconfig
      pcsclite
      python3
      libusb1
    ]
    ++ (with xorg; [
      libX11
      libSM
      libICE
      libXrender
      libXrandr
      libXfixes
      libXcursor
      libXext
      libXtst
      libXi
    ]);

    autoPatchelfIgnoreMissingDeps = true; # libcrypto.so.1.0.0
    preferLocalBuild = true;

    installPhase = ''
      # The $out directory isn't created automatically when dontUnpack is true.
      mkdir -p $out

      # Unzip the main installer archive
      unzip $src -d installer_unzipped
      cd installer_unzipped

      # Extract the contents of the makeself installer script
      sh st-stm32cubeide_*.sh --target extracted_contents --noexec
      cd extracted_contents

      # 1. Install the main IDE from its tarball
      tar zxf st-stm32cubeide_${cubeide-version}_amd64.tar.gz -C $out

      # 2. Extract and install the stlink-server binary
      mkdir stlink_server_tmp
      sh st-stlink-server.*.install.sh --target stlink_server_tmp --noexec
      mkdir -p $out/bin
      mv stlink_server_tmp/stlink-server $out/bin/

      # 3. Extract and install the udev rules
      mkdir -p $out/lib/udev/rules.d

      # Extract STLink rules
      mkdir stlink_rules_tmp
      sh st-stlink-udev-rules-*.sh --target stlink_rules_tmp --noexec
      # The rules are extracted directly into the target dir, not a nested etc/
      cp stlink_rules_tmp/*.rules $out/lib/udev/rules.d/

      # Extract Segger J-Link rules
      mkdir segger_rules_tmp
      sh segger-jlink-udev-rules-*.sh --target segger_rules_tmp --noexec
      # The rules are extracted directly into the target dir, not a nested etc/
      cp segger_rules_tmp/*.rules $out/lib/udev/rules.d/
    '';
  };

in
buildFHSEnv {
  name = "stm32cubeide";

  targetPkgs =
    pkgs: with pkgs; [
      stm32cubeide
      gtk3
      cairo
      glib
      webkitgtk
      gvfs
      dbus
    ];

  # runScript = ''
  #   #!${bash}/bin/bash
  #   echo "STM32CubeIDE FHS environment ready."
  #   echo "Run '${stm32cubeide}/stm32cubeide' to start the IDE."
  #   bash
  # '';
  runScript = ''
    ${stm32cubeide}/stm32cubeide
  '';
}

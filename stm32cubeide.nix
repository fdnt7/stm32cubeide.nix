{
  stdenv,
  lib,
  buildFHSEnv,
  autoPatchelfHook,
  unzip,
  dpkg,
  gtk3,
  cairo,
  glib,
  webkitgtk,
  libusb1,
  bash,
  libsecret,
  alsa-lib,
  bzip2,
  openssl,
  udev,
  ncurses5,
  tlf,
  xorg,
  fontconfig,
  pcsclite,
  python3,
  requireFile,
  fetchurl,
  ...
}:
let
  cubeide-version = "1.19.0_25607_20250703_0907";

  # Build ncurses 5.7 from source, as it contains the older
  # symbols required by the gdb binary.
  ncurses-5-7 = stdenv.mkDerivation {
    pname = "ncurses";
    version = "5.7";

    src = fetchurl {
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

  makeself-pkg = stdenv.mkDerivation {
    name = "stm32cubeide-makeself-pkg";
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
    unpackCmd = "mkdir tmp && ${unzip}/bin/unzip -d tmp $src";
    installPhase = ''
      sh st-stm32cubeide_${cubeide-version}_amd64.sh --target $out --noexec
    '';
  };

  stm32cubeide = stdenv.mkDerivation {
    name = "stm32cubeide";
    version = "1.19.0";
    src = "${makeself-pkg}/st-stm32cubeide_${cubeide-version}_amd64.tar.gz";
    sourceRoot = "."; # Tell nix the source is in the root
    nativeBuildInputs = [ autoPatchelfHook ];
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
    autoPatchelfIgnore = [ ]; # Let autoPatchelf patch gdb
    autoPatchelfIgnoreMissingDeps = true; # libcrypto.so.1.0.0
    preferLocalBuild = true;
    installPhase = ''
      mkdir -p $out
      cp -r ./* $out/
    '';
  };

  stlink-server = stdenv.mkDerivation {
    pname = "st-stlink-server";
    version = "2.1.1-1";

    src = requireFile rec {
      name = "st-stlink-server.2.1.1-1-linux-amd64.install.sh";
      url = "https://www.st.com/en/development-tools/stsw-link009.html";
      message = ''
        This Nix expression requires that ${name} already be part of the store. To
        obtain it you need to navigate to ${url} and download it.

        Then add the file to the Nix store using:

          nix-prefetch-url --type sha256 file:///path/to/${name}
      '';
      # You must calculate and replace this hash
      sha256 = "1wmwmx8fdvnb4514ki9hx3p068x8l8y3npl5b42l512970j2nd5m";
    };

    dontUnpack = true;

    nativeBuildInputs = [ autoPatchelfHook ];
    buildInputs = [
      udev
      libusb1
    ];

    installPhase = ''
      sh $src --target $out --noexec
      # The server binary is in the root, move it to $out/bin
      mkdir -p $out/bin
      mv $out/stlink-server $out/bin/
    '';
  };
in
buildFHSEnv {
  name = "stm32cubeide";

  targetPkgs =
    pkgs: with pkgs; [
      stm32cubeide
      stlink-server
      gtk3
      cairo
      glib
      webkitgtk
      gvfs
      dbus

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
    ];

  runScript = ''
    #!${bash}/bin/bash
    echo "Path to stm32cubeide: ${stm32cubeide}"
    echo "Path to stlink-server: ${stlink-server}"
    # To launch the IDE, uncomment the line below and comment out 'bash'
    # exec ${stm32cubeide}/stm32cubeide
    bash
  '';
}

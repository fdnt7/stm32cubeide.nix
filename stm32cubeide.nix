{ stdenv, lib, buildFHSEnv, autoPatchelfHook, unzip, dpkg, gtk3,
  cairo, glib, webkitgtk, libusb1, bash, libsecret, alsa-lib, bzip2,
  openssl, udev, ncurses5, tlf, xorg, fontconfig, pcsclite, python3, ...
}:
let
  cubeide-version = "1.18.1_24813_20250409_2138";
  makeself-pkg = stdenv.mkDerivation {
    name = "stm32cubeide-makeself-pkg";
    src = ./en.st-stm32cubeide_${cubeide-version}_amd64.sh.zip;
    unpackCmd = "mkdir tmp && ${unzip}/bin/unzip -d tmp $src";
    installPhase = ''
      sh st-stm32cubeide_${cubeide-version}_amd64.sh --target $out --noexec
    '';
  };

  stm32cubeide = stdenv.mkDerivation {
    name = "stm32cubeide";
    version = "1.18.1";
    src = "${makeself-pkg}/st-stm32cubeide_${cubeide-version}_amd64.tar.gz";
    dontUnpack = true;
    nativeBuildInputs = [ autoPatchelfHook ];
    buildInputs = [
      stdenv.cc.cc.lib # libstdc++.so.6
      libsecret
      alsa-lib
      bzip2
      openssl
      udev
      ncurses5
      tlf
      fontconfig
      pcsclite
      python3
    ] ++ (with xorg; [
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
      mkdir -p $out
      tar zxf $src -C $out
    '';
  };
in
buildFHSEnv {
  name = "stm32cubeide";

  targetPkgs = pkgs: with pkgs; [
    stm32cubeide
    gtk3 cairo glib webkitgtk

    stdenv.cc.cc.lib # libstdc++.so.6
    libsecret
    alsa-lib
    bzip2
    openssl
    udev
    ncurses5
    tlf
    fontconfig
    pcsclite
    python3

    ncurses5
  ];

  runScript = ''
    ${stm32cubeide}/stm32cubeide
  '';
}

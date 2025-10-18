{ stdenv, lib, buildFHSEnv, autoPatchelfHook, unzip, dpkg, gtk3,
  cairo, glib, webkitgtk, libusb1, bash, libsecret, alsa-lib, bzip2,
  openssl, udev, ncurses5, tlf, xorg, fontconfig, pcsclite, python3, requireFile, ...
}:
let
  cubeide-version = "1.18.1_24813_20250409_2138";
  makeself-pkg = stdenv.mkDerivation {
    name = "stm32cubeide-makeself-pkg";
    src = requireFile rec {
      name = "en.st-stm32cubeide_${cubeide-version}_amd64.sh.zip";
      url = "https://www.st.com/en/development-tools/stm32cubeide.html";
      message = ''
        This Nix expression requires that ${name} already be part of the store. To
        obtain it you need to navigate to ${url} and download it.

        and then add the file to the Nix store using either:

          nix-store --add-fixed sha256 ${name}

        or

          nix-prefetch-url --type sha256 file:///path/to/${name}
      '';
      sha256 = "0kymv1864z5sik99ssw6bib8h5rglc7yskf1dnyjq3assgk6xiva";
    };
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

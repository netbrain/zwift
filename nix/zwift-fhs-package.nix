{
  pkgs,
  winePrefix ? "",
  debug ? "",
}:
let
  common = import ./zwift-common.nix { inherit pkgs; };

  zwift-nix-fhs = pkgs.stdenv.mkDerivation {
    pname = "zwift-nix-fhs";
    version = "0-unstable";

    dontUnpack = true;

    installPhase = ''
      runHook preInstall

      mkdir -p $out/bin
      install -Dm755 ${../src/zwift-nix-fhs.sh} $out/bin/zwift-nix-fhs

      runHook postInstall
    '';
  };

  zwift-fhs = pkgs.buildFHSEnv {
    name = "zwift-fhs";

    targetPkgs =
      pkgs: with pkgs; [
        # Wine
        wineWow64Packages.stagingFull
        winetricks

        # Networking (wget used by install script; cacert referenced in profile)
        wget
        cacert

        # Tools required by winetricks
        cabextract
        p7zip
        unzip

        # Game mode
        gamemode

        # Our wrapper script
        zwift-nix-fhs
      ];


    profile = ''
      ${if winePrefix != "" then ''
        export WINEPREFIX="${winePrefix}"
      '' else ''
        export WINEPREFIX="''${WINEPREFIX:-$HOME/.wine-zwift}"
      ''}
      export WINEDEBUG="''${WINEDEBUG:--all}"
      export WINEARCH=win64

      # Ensure SSL certificates are available
      export SSL_CERT_FILE="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
      export NIX_SSL_CERT_FILE="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
      export CURL_CA_BUNDLE="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"

      # Ensure HOME is set (required by Wine)
      export HOME="''${HOME:-/tmp}"

      # Set WINE and WINE64 explicitly for winetricks
      # Modern Wine uses a unified binary, but winetricks expects wine64
      export WINE="''${WINE:-/usr/bin/wine}"
      export WINE64="''${WINE64:-/usr/bin/wine}"
      export WINESERVER="''${WINESERVER:-/usr/bin/wineserver}"
    '';

    runScript = "bash";
  };
  nixosRun = pkgs.writeShellScript "zwift-nixos.sh" ''
    ${pkgs.lib.optionalString (winePrefix != "") "export WINE_PREFIX=${winePrefix}"}
    ${pkgs.lib.optionalString (debug != "") "export DEBUG=${debug}"}

    exec ${zwift-fhs}/bin/zwift-fhs -c "zwift-nix-fhs"
  '';

in
pkgs.stdenv.mkDerivation {
  pname = "zwift";
  version = "0-unstable";

  dontUnpack = true;

  nativeBuildInputs = [ pkgs.copyDesktopItems ];

  installPhase = ''
    runHook preInstall
    install -Dm755 ${nixosRun} -T $out/bin/zwift
    install -Dm644 ${../bin/Zwift.svg} -T $out/share/icons/hicolor/scalable/apps/zwift.svg
    runHook postInstall
  '';

  desktopItems = [ common.desktopItem ];

  meta = common.makeMeta "Run Zwift on Linux natively using Wine";
}

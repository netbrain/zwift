{ pkgs, zwift-fhs, zwift-icon }:
let
  common = import ./zwift-common.nix { inherit pkgs; };
in
pkgs.stdenv.mkDerivation {
  pname = "zwift";
  version = "0-unstable";

  dontUnpack = true;

  nativeBuildInputs = [ pkgs.copyDesktopItems ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    cat > $out/bin/zwift << 'EOF'
    #!/usr/bin/env bash
    exec ${zwift-fhs}/bin/zwift-fhs -c "zwift-wrapper $*"
    EOF
    chmod +x $out/bin/zwift

    cat > $out/bin/zwift-auth << 'EOF'
    #!/usr/bin/env bash
    exec ${zwift-fhs}/bin/zwift-fhs -c "zwift-auth"
    EOF
    chmod +x $out/bin/zwift-auth

    install -Dm644 ${zwift-icon} -T $out/share/icons/hicolor/scalable/apps/zwift.svg

    runHook postInstall
  '';

  desktopItems = [ common.desktopItem ];

  meta = common.makeMeta "Run Zwift on Linux natively using Wine";
}

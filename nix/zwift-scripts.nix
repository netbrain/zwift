{
  pkgs,
}:
pkgs.stdenv.mkDerivation {
  pname = "zwift-scripts";
  version = "0-unstable";

  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    install -Dm755 ${../src/zwift-auth.sh}    $out/bin/zwift-auth
    install -Dm755 ${../src/run_zwift.sh}     $out/bin/zwift-run
    install -Dm755 ${../src/zwift-nix-fhs.sh} $out/bin/zwift-nix-fhs
    install -Dm775 ${../src/update_zwift.sh}  $out/bin/zwift-update

    runHook postInstall
  '';
}

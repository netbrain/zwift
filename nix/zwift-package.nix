{
  pkgs,
  zwift-fhs,
}:
pkgs.stdenv.mkDerivation {
  pname = "zwift-scripts";
  version = "0-unstable";

  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    install -Dm644 ${../src/lib.sh}          $out/bin/lib.sh
    install -Dm755 ${../src/zwift-auth.sh}   $out/bin/zwift-auth
    install -Dm755 ${../src/zwift-install.sh} $out/bin/zwift-install
    install -Dm755 ${../src/zwift-run.sh}    $out/bin/zwift-run
    install -Dm755 ${../src/zwift-wrapper.sh} $out/bin/zwift-wrapper

    runHook postInstall
  '';
}

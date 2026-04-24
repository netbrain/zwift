{
  pkgs,
  zwift-sh,
  zwift-icon,
  image ? "",
  tag ? "",
  dontCheck ? "",
  dontPull ? "",
  dontClean ? "",
  dryRun ? "",
  interactive ? "",
  containerTool ? "",
  containerExtraArgs ? "",
  zwiftUsername ? "",
  zwiftPassword ? "",
  zwiftWorkoutDir ? "",
  zwiftActivityDir ? "",
  zwiftLogDir ? "",
  zwiftScreenshotsDir ? "",
  zwiftOverrideGraphics ? "",
  zwiftOverrideResolution ? "",
  zwiftFg ? "",
  zwiftNoGameMode ? "",
  wineExperimentalWayland ? "",
  networking ? "",
  zwiftUid ? "",
  zwiftGid ? "",
  vgaDeviceFlag ? "",
  debug ? "",
  privilegedContainer ? "",
}:
let
  nixosRun = pkgs.writeShellScript "zwift-nixos.sh" ''
    ${pkgs.lib.optionalString (image != "") "export IMAGE=${image}"}
    ${pkgs.lib.optionalString (tag != "") "export VERSION=${tag}"}
    ${pkgs.lib.optionalString (dontCheck != "") "export DONT_CHECK=${dontCheck}"}
    ${pkgs.lib.optionalString (dontPull != "") "export DONT_PULL=${dontPull}"}
    ${pkgs.lib.optionalString (dontClean != "") "export DONT_CLEAN=${dontClean}"}
    ${pkgs.lib.optionalString (dryRun != "") "export DRYRUN=${dryRun}"}
    ${pkgs.lib.optionalString (interactive != "") "export INTERACTIVE=${interactive}"}
    ${pkgs.lib.optionalString (containerTool != "") "export CONTAINER_TOOL=${containerTool}"}
    ${pkgs.lib.optionalString (containerExtraArgs != "") "export CONTAINER_EXTRA_ARGS=${containerExtraArgs}"}
    ${pkgs.lib.optionalString (zwiftUsername != "") "export ZWIFT_USERNAME=${zwiftUsername}"}
    ${pkgs.lib.optionalString (zwiftPassword != "") "export ZWIFT_PASSWORD=${zwiftPassword}"}
    ${pkgs.lib.optionalString (zwiftWorkoutDir != "") "export ZWIFT_WORKOUT_DIR=${zwiftWorkoutDir}"}
    ${pkgs.lib.optionalString (zwiftActivityDir != "") "export ZWIFT_ACTIVITY_DIR=${zwiftActivityDir}"}
    ${pkgs.lib.optionalString (zwiftLogDir != "") "export ZWIFT_LOG_DIR=${zwiftLogDir}"}
    ${pkgs.lib.optionalString (zwiftScreenshotsDir != "") "export ZWIFT_SCREENSHOTS_DIR=${zwiftScreenshotsDir}"}
    ${pkgs.lib.optionalString (zwiftOverrideGraphics != "") "export ZWIFT_OVERRIDE_GRAPHICS=${zwiftOverrideGraphics}"}
    ${pkgs.lib.optionalString (zwiftOverrideResolution != "") "export ZWIFT_OVERRIDE_RESOLUTION=${zwiftOverrideResolution}"}
    ${pkgs.lib.optionalString (zwiftFg != "") "export ZWIFT_FG=${zwiftFg}"}
    ${pkgs.lib.optionalString (zwiftNoGameMode != "") "export ZWIFT_NO_GAMEMODE=${zwiftNoGameMode}"}
    ${pkgs.lib.optionalString (wineExperimentalWayland != "") "export WINE_EXPERIMENTAL_WAYLAND=${wineExperimentalWayland}"}
    ${pkgs.lib.optionalString (networking != "") "export NETWORKING=${networking}"}
    ${pkgs.lib.optionalString (zwiftUid != "") "export ZWIFT_UID=${zwiftUid}"}
    ${pkgs.lib.optionalString (zwiftGid != "") "export ZWIFT_GID=${zwiftGid}"}
    ${pkgs.lib.optionalString (debug != "") "export DEBUG=${debug}"}
    ${pkgs.lib.optionalString (vgaDeviceFlag != "") "export VGA_DEVICE_FLAG=${vgaDeviceFlag}"}
    ${pkgs.lib.optionalString (privilegedContainer != "") "export PRIVILEGED_CONTAINER=${privilegedContainer}"}

    ${zwift-sh}
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
    install -Dm644 ${zwift-icon} -T $out/share/icons/hicolor/scalable/apps/zwift.svg
    runHook postInstall
  '';

  desktopItems = [ (pkgs.makeDesktopItem {
    name = "Zwift";
    desktopName = "Zwift";
    genericName = "Zwift";
    comment = "Zwift Cycling";
    exec = "zwift";
    icon = "zwift";
    terminal = true;
    type = "Application";
    startupNotify = true;
    categories = [ "Game" "Sports" ];
    keywords = [ "Fitness" "Game" "Cycling" ];
    startupWMClass = "zwiftapp.exe";
  }) ];

  meta = with pkgs.lib; {
    description = "Run Zwift on Linux using Docker/Podman containers";
    homepage = "https://github.com/netbrain/zwift";
    license = licenses.mit;
    platforms = [ "x86_64-linux" ];
    mainProgram = "zwift";
  };
}

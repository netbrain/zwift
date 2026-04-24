{ pkgs }:
{
  desktopItem = pkgs.makeDesktopItem {
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
  };

  makeMeta = description: with pkgs.lib; {
    inherit description;
    homepage = "https://github.com/netbrain/zwift";
    license = licenses.mit;
    platforms = [ "x86_64-linux" ];
    mainProgram = "zwift";
  };
}

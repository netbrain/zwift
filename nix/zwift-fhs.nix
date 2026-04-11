{
  pkgs,
  runfromprocess,
  zwift-scripts,
}:
pkgs.buildFHSEnv {
  name = "zwift-fhs";

  # Enable 32-bit support for Wine
  multiArch = true;

  targetPkgs =
    pkgs:
    with pkgs;
    [
      # Wine (staging has better compatibility than devel/unstable)
      wineWowPackages.stagingFull
      winetricks

      # Graphics - Vulkan
      vulkan-loader
      vulkan-tools

      # Graphics - OpenGL/Mesa
      mesa
      libGL
      libGLU
      libglvnd

      # X11 libraries
      xorg.libX11
      xorg.libXext
      xorg.libXrandr
      xorg.libXrender
      xorg.libXcursor
      xorg.libXfixes
      xorg.libXi
      xorg.libXcomposite
      xorg.libXdamage
      xorg.libXtst
      xorg.libXScrnSaver
      xorg.libxcb
      xorg.libICE
      xorg.libSM
      xorg.xrandr

      # Wayland
      wayland
      libxkbcommon
      wayland-protocols

      # Audio
      pulseaudio
      pipewire
      alsa-lib
      alsa-plugins
      libpulseaudio

      # System libraries
      glib
      glibc
      dbus
      systemd
      fontconfig
      freetype

      # Networking
      curl
      wget
      cacert

      # Process utilities
      procps
      coreutils
      gnugrep
      gawk
      gnused
      findutils
      file
      which
      bash

      # Tools required by winetricks
      cabextract
      p7zip
      unzip
      zenity

      # Game mode
      gamemode

      # Additional libraries often needed by Wine
      openssl
      gnutls
      libgpg-error
      sqlite
      libxml2
      ncurses
      zlib
      libpng
      libjpeg
      SDL2
      openal

      # Desktop integration
      gsettings-desktop-schemas
      gtk3
      gdk-pixbuf

      # The runfromprocess Windows binary
      runfromprocess

      # Our wrapper scripts
      zwift-scripts
    ];

  # 32-bit packages for Wine compatibility
  multiPkgs =
    pkgs:
    with pkgs;
    [
      # Graphics
      vulkan-loader
      mesa
      libGL
      libGLU
      libglvnd

      # X11
      xorg.libX11
      xorg.libXext
      xorg.libXrandr
      xorg.libXrender
      xorg.libXcursor
      xorg.libXfixes
      xorg.libXi
      xorg.libXcomposite
      xorg.libXdamage
      xorg.libXtst
      xorg.libxcb

      # Audio
      pulseaudio
      alsa-lib
      alsa-plugins
      libpulseaudio

      # System
      glib
      glibc
      dbus
      fontconfig
      freetype

      # Wine dependencies
      gnutls
      openssl
      ncurses
      zlib
      libpng
      libjpeg
      SDL2
      openal

      # GTK
      gtk3
      gdk-pixbuf
    ];

  profile = ''
    export WINEPREFIX="''${WINEPREFIX:-$HOME/.wine-zwift}"
    export WINEDEBUG="''${WINEDEBUG:--all}"
    export WINEARCH=win64

    # Ensure SSL certificates are available
    export SSL_CERT_FILE="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
    export NIX_SSL_CERT_FILE="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
    export CURL_CA_BUNDLE="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"

    # Set up Vulkan ICD path
    export VK_ICD_FILENAMES="''${VK_ICD_FILENAMES:-}"

    # Ensure HOME is set (required by Wine)
    export HOME="''${HOME:-/tmp}"

    # Set up XDG directories
    export XDG_DATA_HOME="''${XDG_DATA_HOME:-$HOME/.local/share}"
    export XDG_CONFIG_HOME="''${XDG_CONFIG_HOME:-$HOME/.config}"
    export XDG_CACHE_HOME="''${XDG_CACHE_HOME:-$HOME/.cache}"

    # Create Wine directories if needed
    mkdir -p "''${WINEPREFIX}" 2>/dev/null || true

    # Set WINE and WINE64 explicitly for winetricks
    # Modern Wine uses a unified binary, but winetricks expects wine64
    export WINE="''${WINE:-/usr/bin/wine}"
    export WINE64="''${WINE64:-/usr/bin/wine}"
    export WINESERVER="''${WINESERVER:-/usr/bin/wineserver}"
  '';

  runScript = "bash";
}

ARG DEBIAN_VERSION=trixie

FROM rust:1.99.0-slim-trixie AS build-runfromprocess

ARG RUNFROMPROCESS_VERSION=a3d003c07d1bd11ff93c4cac96d2c3aa5deb8471

# Install prerequisites
# - mingw to cross-compile for windows
# - rust cross-compiler for windows
RUN DEBIAN_FRONTEND="noninteractive" apt-get update \
 && DEBIAN_FRONTEND="noninteractive" apt-get install --no-install-recommends -y g++-mingw-w64-x86-64 \
 && rm -rf /var/lib/apt/lists/* \
 && rustup target add x86_64-pc-windows-gnu

# Build runfromprocess
WORKDIR /usr/src
ADD https://github.com/quietvoid/runfromprocess-rs.git#${RUNFROMPROCESS_VERSION} .
RUN cargo build --target x86_64-pc-windows-gnu --release

FROM debian:${DEBIAN_VERSION}-slim AS wine-base

# Wine
# - 11.20    : first wine update since 9.9, use egl
# - 10.17    : default to egl for opengl in x11
# - 9.9      : support native wayland
# Winetricks
# - f3890f6  : webview2 verb (not officially released yet)
# - 20260125 : webview2 in zwift launcher works
# - 20240105 : first version used in this Dockerfile
ARG DEBIAN_VERSION
ARG WINE_BRANCH="devel"
ARG WINE_VERSION="=11.20~${DEBIAN_VERSION}-1"
ARG WINETRICKS_VERSION=f3890f670867b5ffbc3938726db45c0f7d16c8ba
ARG WINETRICKS_CHECKSUM=672a1ff4442e8691a3ffc0e6860137e201a1d1227e9b3044245f1731e9e9837e

# Install prerequisites
# - bluez for bluetooth
# - ca-certificates for wget and curl
# - cabextract for winetricks
# - curl used in zwift authentication script
# - gamemode for freedesktop screensaver inhibit
# - gosu for invoking scripts in entrypoint
# - gpg for dearmoring winehq key
# - libdecor for wayland client-side window decorations
# - libglvnd (libegl1 libgl1 libgles1 libgles2 libglvnd0 libglx0 libopengl0) for opengl
# - libvulkan1 for vulkan loader library
# - mesa-utils for testing graphics: glxgears, eglgears_wayland, eglgears_x11
# - procps for pgrep
# - rsync to synchronize zwift volume with zwift appdata
# - wget for downloading winehq key
# - winbind for ntml_auth required by zwift/wine
# - xdg-utils for wayland
RUN dpkg --add-architecture i386 \
 && DEBIAN_FRONTEND="noninteractive" apt-get update \
 && DEBIAN_FRONTEND="noninteractive" apt-get install --no-install-recommends -y \
        bluez \
        ca-certificates \
        cabextract \
        curl \
        gamemode libgamemode0:i386 libgamemodeauto0:i386 \
        gosu \
        gpg \
        libdecor-0-0 libdecor-0-plugin-1-gtk \
        libegl1 libgl1 libgles1 libgles2 libglvnd0 libglx0 libopengl0 \
        libvulkan1 \
        mesa-utils \
        procps \
        rsync \
        wget \
        winbind \
        xdg-utils \
 && rm -rf /var/lib/apt/lists/*

# Install wine (including recommends, see https://gitlab.winehq.org/wine/wine/-/wikis/Debian-Ubuntu)
# hadolint ignore=DL3015
RUN mkdir -p /etc/apt/keyrings \
 && wget -qO /tmp/winehq.key https://dl.winehq.org/wine-builds/winehq.key \
 && gpg --dearmor -o /etc/apt/keyrings/winehq-archive.key /tmp/winehq.key \
 && rm -f /tmp/winehq.key \
 && wget -qNP /etc/apt/sources.list.d/ https://dl.winehq.org/wine-builds/debian/dists/${DEBIAN_VERSION}/winehq-${DEBIAN_VERSION}.sources \
 && DEBIAN_FRONTEND="noninteractive" apt-get update \
 && DEBIAN_FRONTEND="noninteractive" apt-get install -y \
        wine-${WINE_BRANCH}${WINE_VERSION} \
        wine-${WINE_BRANCH}-amd64${WINE_VERSION} \
        wine-${WINE_BRANCH}-i386${WINE_VERSION} \
        winehq-${WINE_BRANCH}${WINE_VERSION} \
 && rm -rf /var/lib/apt/lists/*

# Download winetricks
ADD --checksum=sha256:${WINETRICKS_CHECKSUM} --chmod=755 https://raw.githubusercontent.com/Winetricks/winetricks/${WINETRICKS_VERSION}/src/winetricks /usr/local/bin/

# Configure nvidia driver
ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=all

# Configure audio driver
COPY pulse-client.conf /etc/pulse/client.conf

# Create passwordless user
RUN useradd --create-home --shell /bin/bash user

FROM wine-base

ENV WINEDEBUG=fixme-all
ENV WINEPREFIX="/home/user/.wine"
ENV WINE_USER_HOME="${WINEPREFIX}/drive_c/users/user"
ENV ZWIFT_DATA_DIR="${WINE_USER_HOME}/AppData/Local/Zwift"
ENV ZWIFT_INSTALL_DIR="${WINEPREFIX}/drive_c/Program Files (x86)/Zwift"

LABEL org.opencontainers.image.authors="Kim Eik <kim@heldig.org>"
LABEL org.opencontainers.image.title="netbrain/zwift"
LABEL org.opencontainers.image.description="Easily zwift on linux"
LABEL org.opencontainers.image.url="https://github.com/netbrain/zwift"
LABEL org.opencontainers.image.source="https://github.com/netbrain/zwift"
LABEL org.opencontainers.image.documentation="https://netbrain.github.io/zwift/"
LABEL org.opencontainers.image.licenses="Unlicense"

COPY --chmod=755 entrypoint.sh /bin/entrypoint
COPY --chmod=755 update_zwift.sh /bin/update_zwift.sh
COPY --chmod=755 run_zwift.sh /bin/run_zwift.sh
COPY --chmod=755 zwift-auth.sh /bin/zwift-auth
COPY --from=build-runfromprocess /usr/src/target/x86_64-pc-windows-gnu/release/runfromprocess-rs.exe /bin/runfromprocess-rs.exe

USER user

ENTRYPOINT ["entrypoint"]

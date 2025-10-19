ARG DEBIAN_VERSION=trixie

FROM rust:1.72 AS build-runfromprocess

RUN apt update && apt upgrade -y
RUN apt install -y g++-mingw-w64-x86-64 git

RUN rustup target add x86_64-pc-windows-gnu
RUN rustup toolchain install stable-x86_64-pc-windows-gnu

WORKDIR /usr/src
RUN git clone https://github.com/quietvoid/runfromprocess-rs .

RUN cargo build --target x86_64-pc-windows-gnu --release

FROM debian:${DEBIAN_VERSION}-slim AS wine-base
ARG DEBIAN_VERSION

# As at May 2024 Wayland Native works wine 9.9 or later:
#    WINE_BRANCH="devel"
# For Specific version fix add WINE_VERSION,
# make sure to add "=" to the start, comment out for latest
#    WINE_VERSION="=9.9~bookworm-1"
ARG WINE_BRANCH="devel"
ARG WINE_VERSION="=9.9~${DEBIAN_VERSION}-1"
ARG WINETRICKS_VERSION=20240105

RUN dpkg --add-architecture i386

# prerequisites
# - wget for downloading winehq key
# - curl used in zwift authentication script
# - sudo for normal user installation
# - winbind for ntml_auth required by zwift/wine
# - libgl1 for GL library
# - libvulkan1 for vulkan loader library
# - procps for pgrep
# - gamemode for freedesktop screensaver inhibit
# - xdg-utils seems to be a dependency of wayland

RUN apt-get update
RUN apt-get install -y wget curl sudo winbind libgl1 libvulkan1 procps gosu gamemode xdg-utils
RUN wget -qO /etc/apt/trusted.gpg.d/winehq.asc https://dl.winehq.org/wine-builds/winehq.key
RUN DEBIAN_VERSION=${DEBIAN_VERSION} echo "deb https://dl.winehq.org/wine-builds/debian/ ${DEBIAN_VERSION} main" > /etc/apt/sources.list.d/winehq.list
RUN apt-get update

RUN apt-get -y --no-install-recommends install \
  winehq-${WINE_BRANCH}${WINE_VERSION} wine-${WINE_BRANCH}${WINE_VERSION} \
  wine-${WINE_BRANCH}-amd64${WINE_VERSION} wine-${WINE_BRANCH}-i386${WINE_VERSION}

RUN echo "/usr/local/nvidia/lib" >> /etc/ld.so.conf.d/nvidia.conf && \
  echo "/usr/local/nvidia/lib64" >> /etc/ld.so.conf.d/nvidia.conf

# Required for non-glvnd setups.
ENV LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:/usr/lib/i386-linux-gnu${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}:/usr/local/nvidia/lib:/usr/local/nvidia/lib64

COPY pulse-client.conf /etc/pulse/client.conf

RUN \
  wget \
  https://raw.githubusercontent.com/Winetricks/winetricks/${WINETRICKS_VERSION}/src/winetricks \
  -O /usr/local/bin/winetricks && \
  chmod +x /usr/local/bin/winetricks

RUN adduser --disabled-password --gecos ''  user && \
  adduser user sudo && \
  echo '%SUDO ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

FROM wine-base

# Moved Environments into wine-base build part.
ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=all
ENV WINEDEBUG=fixme-all

LABEL org.opencontainers.image.authors="Kim Eik <kim@heldig.org>"
LABEL org.opencontainers.image.title="netbrain/zwift"
LABEL org.opencontainers.image.description="Easily zwift on linux"
LABEL org.opencontainers.image.url="https://github.com/netbrain/zwift"

RUN apt-get update && \
    apt-get install -y curl && \
    rm -rf /var/lib/apt/lists/*

COPY entrypoint.sh /bin/entrypoint
RUN chmod +rx /bin/entrypoint

COPY update_zwift.sh /bin/update_zwift.sh
RUN chmod +rx /bin/update_zwift.sh

COPY run_zwift.sh /bin/run_zwift.sh
RUN chmod +rx /bin/run_zwift.sh

COPY zwift-auth.sh /bin/zwift-auth
RUN chmod +rx /bin/zwift-auth

COPY --from=build-runfromprocess /usr/src/target/x86_64-pc-windows-gnu/release/runfromprocess-rs.exe /bin/runfromprocess-rs.exe
RUN chmod +rx /bin/runfromprocess-rs.exe

ENTRYPOINT ["entrypoint"]

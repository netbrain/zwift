ARG DEBIAN_VERSION=trixie

FROM rust:1.72 as build-runfromprocess

RUN apt update && apt upgrade -y
RUN apt install -y g++-mingw-w64-x86-64 git

RUN rustup target add x86_64-pc-windows-gnu
RUN rustup toolchain install stable-x86_64-pc-windows-gnu

WORKDIR /usr/src
RUN git clone https://github.com/quietvoid/runfromprocess-rs .

RUN cargo build --target x86_64-pc-windows-gnu --release

FROM debian:${DEBIAN_VERSION}-slim as wine-base
ARG WINETRICKS_VERSION=20240105
ARG WINE_MONO_VERSION=8.1.0
ARG WINE_BRANCH=stable
ARG DEBIAN_VERSION
ENV NVIDIA_VISIBLE_DEVICES=${NVIDIA_VISIBLE_DEVICES:-all}
ENV NVIDIA_DRIVER_CAPABILITIES=all
ENV WINEDEBUG=${WINEDEBUG:-fixme-all}

RUN dpkg --add-architecture i386 

# prerequisites
# - wget for downloading winehq key
# - sudo for normal user installation
# - winbind for ntml_auth required by zwift/wine
# - libgl1 for GL library
# - libvulkan1 for vulkan loader library
# - procps for pgrep

RUN apt-get update
RUN apt-get install -y wget sudo winbind libgl1 libvulkan1 procps
RUN wget -qO /etc/apt/trusted.gpg.d/winehq.asc https://dl.winehq.org/wine-builds/winehq.key
RUN DEBIAN_VERSION=${DEBIAN_VERSION} echo "deb https://dl.winehq.org/wine-builds/debian/ ${DEBIAN_VERSION} main" > /etc/apt/sources.list.d/winehq.list
RUN apt-get update

RUN apt-get -y --no-install-recommends install \
  winehq-stable wine-stable wine-stable-amd64 wine-stable-i386

RUN echo "/usr/local/nvidia/lib" >> /etc/ld.so.conf.d/nvidia.conf && \
  echo "/usr/local/nvidia/lib64" >> /etc/ld.so.conf.d/nvidia.conf

# Required for non-glvnd setups.
ENV LD_LIBRARY_PATH /usr/lib/x86_64-linux-gnu:/usr/lib/i386-linux-gnu${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}:/usr/local/nvidia/lib:/usr/local/nvidia/lib64

COPY pulse-client.conf /etc/pulse/client.conf

RUN \
  wget \
  https://raw.githubusercontent.com/Winetricks/winetricks/${WINETRICKS_VERSION}/src/winetricks \
  -O /usr/local/bin/winetricks && \
  chmod +x /usr/local/bin/winetricks

RUN adduser --disabled-password --gecos ''  user && \
  adduser user sudo && \
  echo '%SUDO ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

RUN mkdir -p /run/user/1000 && chown -R user:user /run/user/1000

USER user
WORKDIR /home/user

RUN wget https://dl.winehq.org/wine/wine-mono/${WINE_MONO_VERSION}/wine-mono-${WINE_MONO_VERSION}-x86.msi \
        -P /home/user/.cache/wine

FROM wine-base

LABEL org.opencontainers.image.authors="Kim Eik <kim@heldig.org>"
LABEL org.opencontainers.image.title="netbrain/zwift"
LABEL org.opencontainers.image.description="Easily zwift on linux"
LABEL org.opencontainers.image.url="https://github.com/netbrain/zwift"

RUN sudo apt-get update && \
    sudo apt-get install -y curl && \
    sudo rm -rf /var/lib/apt/lists/*

COPY entrypoint.sh /bin/entrypoint
RUN sudo chmod +x /bin/entrypoint

COPY zwift-auth.sh /bin/zwift-auth
RUN sudo chmod +x /bin/zwift-auth

COPY --from=build-runfromprocess /usr/src/target/x86_64-pc-windows-gnu/release/runfromprocess-rs.exe /bin/runfromprocess-rs.exe
RUN sudo chmod +x /bin/runfromprocess-rs.exe

ENTRYPOINT ["entrypoint"]

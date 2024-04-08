FROM rust:1.72 as build-runfromprocess

RUN apt update && apt upgrade -y
RUN apt install -y g++-mingw-w64-x86-64 git

RUN rustup target add x86_64-pc-windows-gnu
RUN rustup toolchain install stable-x86_64-pc-windows-gnu

WORKDIR /usr/src
RUN git clone https://github.com/quietvoid/runfromprocess-rs .

RUN cargo build --target x86_64-pc-windows-gnu --release

FROM debian:testing-slim as wine-base
ARG WINETRICKS_VERSION=20240105
ARG WINE_MONO_VERSION=9.0.0
ENV NVIDIA_VISIBLE_DEVICES=${NVIDIA_VISIBLE_DEVICES:-all}
ENV NVIDIA_DRIVER_CAPABILITIES=all
ENV WINEDEBUG=${WINEDEBUG:-fixme-all}

RUN dpkg --add-architecture i386 

RUN echo "deb http://ftp.debian.org/debian sid main" >> /etc/apt/sources.list

RUN \
  apt-get update && \
  apt-get install -y --no-install-recommends \
  sudo \
  wget \
  unzip \
  gnupg2 \
  procps \
  winbind \
  pulseaudio \
  ca-certificates \
  libxau6 \
  libxdmcp6 \
  libxcb1 \
  libxext6 \
  libx11-6 \
  libglvnd0 \
  libgl1 \
  libglx0 \
  libegl1 \
  libgles2 \
  libgl1-mesa-glx \
  libgl1-mesa-dri && \
  wget -qO - http://dl.winehq.org/wine-builds/winehq.key | apt-key add - && \
  echo "deb https://dl.winehq.org/wine-builds/debian/ testing main" > \
  /etc/apt/sources.list.d/winehq.list && \ 
  apt-get update && \
  apt-get -y install --install-recommends \
  winehq-stable=${WINE_VERSION} \
  wine-stable=${WINE_VERSION} \
  wine-stable-amd64=${WINE_VERSION} \
  wine-stable-i386=${WINE_VERSION} && \
  rm -rf /var/lib/apt/lists/*

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

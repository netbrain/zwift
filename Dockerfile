ARG ALPINE_VERSION=3.19

FROM rust:1.72 as build-runfromprocess

RUN apt update && apt upgrade -y
RUN apt install -y g++-mingw-w64-x86-64 git

RUN rustup target add x86_64-pc-windows-gnu
RUN rustup toolchain install stable-x86_64-pc-windows-gnu

WORKDIR /usr/src
RUN git clone https://github.com/quietvoid/runfromprocess-rs .

RUN cargo build --target x86_64-pc-windows-gnu --release

FROM alpine:${ALPINE_VERSION} as wine-base
ARG WINETRICKS_VERSION=20240105
ARG WINE_MONO_VERSION=8.1.0
ENV NVIDIA_VISIBLE_DEVICES=${NVIDIA_VISIBLE_DEVICES:-all}
ENV NVIDIA_DRIVER_CAPABILITIES=all
ENV WINEDEBUG=${WINEDEBUG:-fixme-all}

# RUN echo "/usr/local/nvidia/lib" >> /etc/ld.so.conf.d/nvidia.conf && \
#   echo "/usr/local/nvidia/lib64" >> /etc/ld.so.conf.d/nvidia.conf

# Required for non-glvnd setups.
# ENV LD_LIBRARY_PATH /usr/lib/x86_64-linux-gnu:/usr/lib/i386-linux-gnu${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}:/usr/local/nvidia/lib:/usr/local/nvidia/lib64

COPY pulse-client.conf /etc/pulse/client.conf
RUN apk --no-cache add mesa-utils mesa-dri-gallium wine wine-dev wget samba-winbind-clients pulseaudio curl sudo grep bash gnutls
RUN \
  wget \
  https://raw.githubusercontent.com/Winetricks/winetricks/${WINETRICKS_VERSION}/src/winetricks \
  -O /usr/local/bin/winetricks && \
  chmod +x /usr/local/bin/winetricks

RUN adduser --disabled-password --gecos ''  user && \
  adduser user wheel && \
  echo '%wheel ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

USER user
WORKDIR /home/user

RUN wget https://dl.winehq.org/wine/wine-mono/${WINE_MONO_VERSION}/wine-mono-${WINE_MONO_VERSION}-x86.msi \
        -P /home/user/.cache/wine

FROM wine-base

LABEL org.opencontainers.image.authors="Kim Eik <kim@heldig.org>"
LABEL org.opencontainers.image.title="netbrain/zwift"
LABEL org.opencontainers.image.description="Easily zwift on linux"
LABEL org.opencontainers.image.url="https://github.com/netbrain/zwift"

COPY entrypoint.sh /bin/entrypoint
RUN sudo chmod +x /bin/entrypoint

COPY zwift-auth.sh /bin/zwift-auth
RUN sudo chmod +x /bin/zwift-auth

COPY --from=build-runfromprocess /usr/src/target/x86_64-pc-windows-gnu/release/runfromprocess-rs.exe /bin/runfromprocess-rs.exe
RUN sudo chmod +x /bin/runfromprocess-rs.exe

ENTRYPOINT ["entrypoint"]

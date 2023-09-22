FROM rust:1.72 as build-runfromprocess

RUN apt update && apt upgrade -y
RUN apt install -y g++-mingw-w64-x86-64 git

RUN rustup target add x86_64-pc-windows-gnu
RUN rustup toolchain install stable-x86_64-pc-windows-gnu

WORKDIR /usr/src
RUN git clone https://github.com/quietvoid/runfromprocess-rs .

RUN cargo build --target x86_64-pc-windows-gnu --release

FROM netbrain/wine:7.0.0

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

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

COPY runfromprocess-rs.exe /bin/runfromprocess-rs.exe
RUN sudo chmod +x /bin/runfromprocess-rs.exe

ENTRYPOINT ["entrypoint"]

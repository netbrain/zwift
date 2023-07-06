FROM netbrain/zwift:latest as latest
FROM netbrain/wine:7.0.0

LABEL org.opencontainers.image.authors="Kim Eik <kim@heldig.org>"
LABEL org.opencontainers.image.title="netbrain/zwift"
LABEL org.opencontainers.image.description="Easily zwift on linux"
LABEL org.opencontainers.image.url="https://github.com/netbrain/zwift"

COPY entrypoint.sh /bin/entrypoint
RUN sudo chmod +x /bin/entrypoint
COPY --from=latest /home/user /home/user
ENTRYPOINT ["entrypoint"]

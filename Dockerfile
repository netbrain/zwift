FROM netbrain/wine:7.0.0

LABEL maintainer="Kim Eik <kim@heldig.org>"
LABEL org.label-schema.schema-version="1.0"
LABEL org.label-schema.name="netbrain/zwift"
LABEL org.label-schema.description="Easily zwift on linux"
LABEL org.label-schema.vcs-url="https://github.com/netbrain/zwift"

COPY entrypoint.sh /bin/entrypoint
RUN sudo chmod +x /bin/entrypoint
ENTRYPOINT ["entrypoint"]

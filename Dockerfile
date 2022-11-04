FROM netbrain/wine:7.0.0
LABEL maintainer="Kim Eik <kim@heldig.org>"
COPY entrypoint.sh /bin/entrypoint
RUN sudo chmod +x /bin/entrypoint
ENTRYPOINT ["entrypoint"]

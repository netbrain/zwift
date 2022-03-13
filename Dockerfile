FROM netbrain/wine:7.0.0
COPY entrypoint.sh /bin/entrypoint
RUN sudo chmod +x /bin/entrypoint
ENTRYPOINT ["entrypoint"]

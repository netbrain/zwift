FROM netbrain/nvidia-wine
COPY entrypoint.sh .
RUN winetricks --unattended dotnet45 win10
CMD bash entrypoint.sh

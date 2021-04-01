FROM ubuntu:20.04

RUN apt update -y && apt install -y gdb curl lib32gcc1 libc++-dev unzip && rm -rf /var/lib/apt/lists/*
RUN useradd -m steam
USER steam
WORKDIR /home/steam
RUN mkdir Steam && cd Steam && curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zxvf -
RUN ~/Steam/steamcmd.sh +login anonymous +force_install_dir /home/steam/pavlovserver +app_update 622970 +exit
RUN mkdir -p ~/pavlovserver/Pavlov/Saved/Logs
RUN mkdir -p ~/pavlovserver/Pavlov/Saved/Config/LinuxServer
ADD RconSettings.txt /home/steam/pavlovserver/Pavlov/Saved/Config/
ADD Game.ini /home/steam/pavlovserver/Pavlov/Saved/Config/LinuxServer/
RUN ~/Steam/steamcmd.sh +login anonymous +app_update 1007 +quit
RUN mkdir -p /home/steam/.steam/sdk64
RUN cp ~/Steam/steamapps/common/Steamworks\ SDK\ Redist/linux64/steamclient.so ~/.steam/sdk64/steamclient.so
RUN cp ~/Steam/steamapps/common/Steamworks\ SDK\ Redist/linux64/steamclient.so ~/pavlovserver/Pavlov/Binaries/Linux/steamclient.so
WORKDIR /home/steam/pavlovserver
CMD ["./PavlovServer.sh"]
EXPOSE 7777/udp
EXPOSE 8177/udp
EXPOSE 9100/tcp

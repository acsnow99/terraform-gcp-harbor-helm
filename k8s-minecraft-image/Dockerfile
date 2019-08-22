FROM ubuntu
RUN apt-get update \
      && apt-get install -y wget \
      && apt-get install -y unzip \
      && apt-get install -y libcurl4 \
      && mkdir minecraft \ 
      && wget https://minecraft.azureedge.net/bin-linux/bedrock-server-1.12.0.28.zip \
      && unzip bedrock-server-1.12.0.28.zip -d minecraft \
      && mkdir minecraft/worlds

RUN echo "server-name=Alexs K8S Server\n\
gamemode=creative\n\
difficulty=normal\n\
allow-cheats=false\n\
max-players=10\n\
online-mode=true\n\
white-list=false\n\
server-port=19132\n\
server-portv6=19133\n\
view-distance=32\n\
tick-distance=4\n\
player-idle-timeout=30\n\
max-threads=8\n\
level-name=DOINGUS\n\
level-seed=\n\
default-player-permission-level=operator\n\
texturepack-required=false" > /minecraft/server.properties \
  && mkdir /minecraft/worlds/DOINGUS \
  && touch /auto-backup.sh \
  && echo "while true\n\
do\n\
  cp -r /minecraft/worlds/DOINGUS/db/* /worlds-backup/DOINGUS\n\
  sleep 180\n\
done" > /auto-backup.sh \
  && mkdir /worlds-backup \
  && mkdir /worlds-backup/DOINGUS

COPY DOINGUS/db /minecraft/worlds/DOINGUS/db

ENV LD_LIBRARY_PATH /minecraft

CMD /auto-backup.sh && cd minecraft && /minecraft/bedrock_server

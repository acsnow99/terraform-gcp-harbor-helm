FROM ubuntu
RUN apt-get update \
      && apt-get install -y wget \
      && apt-get install -y unzip \
      && apt-get install -y libcurl4 \
      && mkdir minecraft \ 
      && wget https://minecraft.azureedge.net/bin-linux/bedrock-server-1.12.0.28.zip \
      && unzip bedrock-server-1.12.0.28.zip -d minecraft \
      && mkdir minecraft/worlds

CMD tail -f /dev/null

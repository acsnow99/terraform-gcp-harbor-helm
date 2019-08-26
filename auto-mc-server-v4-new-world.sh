#!/bin/bash

# Run "export WORLDNAME=<the name of the new world or existing world files in k8s-minecraft-image directory>" 
# and "export GAMEMODE=<survival or creative>" 
# before running script

yes yes | terraform apply -var-file=states/minecraft.tfvars
clustername="$(terraform output | sed 's/cluster-name = //')"
gcloud container clusters get-credentials $clustername --zone us-west1-a --project terraform-gcp-harbor

worldname="$(echo $WORLDNAME | tr '[:upper:]' '[:lower:]')"

echo 'FROM ubuntu
RUN apt-get update \
      && apt-get install -y wget \
      && apt-get install -y unzip \
      && apt-get install -y libcurl4 \
      && mkdir minecraft \ 
      && wget https://minecraft.azureedge.net/bin-linux/bedrock-server-'"$VERSION"'.zip \
      && unzip bedrock-server-'"$VERSION"'.zip -d minecraft \
      && mkdir minecraft/worlds

CMD tail -f /dev/null' > ./k8s-minecraft-image/Dockerfile
# tail -f /dev/null
# /auto-backup.sh && cd /minecraft && /minecraft/bedrock_server

#This command keeps the container running
#CMD tail -f /dev/null 

echo -e "server-name=Alexs K8S Server\n\
gamemode="$GAMEMODE"\n\
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
level-name="$WORLDNAME"\n\
level-seed=\n\
default-player-permission-level=operator\n\
texturepack-required=false" > resources/server.properties

sudo docker build -t core.harbor.domain/minecraft/k8s-minecraft:$VERSION ./k8s-minecraft-image
sudo docker push core.harbor.domain/minecraft/k8s-minecraft:$VERSION

echo 'kind: Pod
apiVersion: v1
metadata:
  name: mc-server-pod-'"${worldname}"'
  labels: 
    app: minecraft
    world: '"${worldname}"'
spec:
  volumes:
    - name: mc-world-storage
      persistentVolumeClaim:
       claimName: mc-claim
  containers:
    - name: mc-server-container
      image: core.harbor.domain/minecraft/k8s-minecraft:'"$VERSION"'
      ports:
        - containerPort: 19132
          name: "mc-server"
      volumeMounts:
        - mountPath: "/minecraft/worlds"
          name: mc-world-storage

---

apiVersion: v1
kind: Service
metadata:
  name: mc-exposer-'"${worldname}"'
  labels:
    app: minecraft
    world: '"${worldname}"'
spec:
  type: LoadBalancer
  
  ports:
    - protocol: UDP
      port: 19132
      targetPort: 19132
  selector: 
    world: '"${worldname}"'' > ./resources/mc-pod-"${worldname}".yaml

kubectl apply -f ./resources/pvc.yaml
kubectl apply -f ./resources/mc-pod-"${worldname}".yaml

sleep 120

kubectl cp resources/server.properties mc-server-pod-${worldname}:/minecraft/server.properties
kubectl cp resources/server_setup.sh mc-server-pod-${worldname}:/server_setup.sh

kubectl exec mc-server-pod-${worldname} bash /server_setup.sh
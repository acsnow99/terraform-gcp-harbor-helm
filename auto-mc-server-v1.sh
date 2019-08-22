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
      && wget https://minecraft.azureedge.net/bin-linux/bedrock-server-1.12.0.28.zip \
      && unzip bedrock-server-1.12.0.28.zip -d minecraft \
      && mkdir minecraft/worlds

RUN echo "server-name=Alexs K8S Server\n\
gamemode='"$GAMEMODE"'\n\
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
level-name='"$WORLDNAME"'\n\
level-seed=\n\
default-player-permission-level=operator\n\
texturepack-required=false" > /minecraft/server.properties \
  && mkdir minecraft/worlds/'"$WORLDNAME"'

COPY '"$WORLDNAME"'/db /minecraft/worlds/'"$WORLDNAME"'/db

ENV LD_LIBRARY_PATH /minecraft

CMD cd minecraft && /minecraft/bedrock_server' > /Users/alexsnow/terraform/gcp/harbor/terraform-gcp-harbor-helm/k8s-minecraft-image/Dockerfile

sudo docker build -t alexcraigs/k8s-minecraft:"${worldname}" /Users/alexsnow/terraform/gcp/harbor/terraform-gcp-harbor-helm/k8s-minecraft-image
sudo docker run -it alexcraigs/k8s-minecraft:"${worldname}" /bin/bash
sudo docker push alexcraigs/k8s-minecraft:"${worldname}"

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
      image: alexcraigs/k8s-minecraft:'"${worldname}"'
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
    world: '"${worldname}"'' > /Users/alexsnow/minecraft-experiments/minecraft-kubernetes/mc-pod-"${worldname}".yaml

kubectl apply -f /Users/alexsnow/minecraft-experiments/minecraft-kubernetes/pvc.yaml
kubectl apply -f /Users/alexsnow/minecraft-experiments/minecraft-kubernetes/mc-pod-"${worldname}".yaml

sleep 60

#look at the external IP of the server
kubectl get services
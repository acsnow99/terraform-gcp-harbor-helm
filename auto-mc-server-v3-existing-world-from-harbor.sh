# Run "export WORLDNAME=<the name of the new world or existing world files in k8s-minecraft-image directory>" 
# and "export GAMEMODE=<survival or creative>" 
# before running script

# to get the nodes to trust harbor, run:
# gcloud beta compute --project "terraform-gcp-harbor" ssh --zone "us-west1-a" "gke-harbor-kube-harbor-kube-pool-${number of the node}"
cd /etc/docker
sudo mkdir certs.d
sudo mkdir certs.d/core.harbor.domain
cd certs.d/core.harbor.domain
sudo curl -k -o ca.crt https://core.harbor.domain/api/systeminfo/getcert
exit

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
  && mkdir /world-backup \
  && mkdir /world-backup/'"$WORLDNAME"'

COPY '"$WORLDNAME"'/db /world-backup/'"$WORLDNAME"'

ENV LD_LIBRARY_PATH /minecraft

CMD mkdir /minecraft/worlds/'"$WORLDNAME"' && mkdir /minecraft/worlds/'"$WORLDNAME"'/db && cp -r /world-backup/'"$WORLDNAME"'/* /minecraft/worlds/'"$WORLDNAME"'/db && cd minecraft && /minecraft/bedrock_server' > ./k8s-minecraft-image/Dockerfile

#This command keeps the container running
#CMD tail -f /dev/null 

sudo docker build -t core.harbor.domain/minecraft/k8s-minecraft-from-file:"${worldname}" ./k8s-minecraft-image
sudo docker push alexcraigs/minecraft/k8s-minecraft-from-file:"${worldname}"

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
      image: core.harbor.domain/minecraft/k8s-minecraft-from-file:'"${worldname}"'
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

# sleep 60

#kubectl exec -it mc-server-pod-${worldname} mkdir /minecraft/worlds/$WORLDNAME
#kubectl exec -it mc-server-pod-${worldname} mkdir /minecraft/worlds/$WORLDNAME/db
#kubectl exec -it mc-server-pod-${worldname} mv /$WORLDNAME /minecraft/worlds/$WORLDNAME/db
#kubectl exec -it mc-server-pod-${worldname} cd /minecraft && LD_LIBRARY_PATH=. ./bedrock_server

# sleep 60

#look at the external IP of the server
# kubectl get services

#kubectl exec -it mc-server-pod-${worldname} mkdir /minecraft/worlds/$WORLDNAME && mkdir /minecraft/worlds/$WORLDNAME/db && cp -r /$WORLDNAME/* /minecraft/worlds/$WORLDNAME/db && cd /minecraft && LD_LIBRARY_PATH=. ./bedrock_server

#kubectl exec -it mc-server-pod-doingus mkdir /minecraft/worlds/DOINGUS
#kubectl exec -it mc-server-pod-doingus mkdir /minecraft/worlds/DOINGUS/db
#kubectl exec -it mc-server-pod-doingus mv /DOINGUS /minecraft/worlds/DOINGUS/db
#kubectl exec -it mc-server-pod-doingus LD_LIBRARY_PATH=/minecraft minecraft/bedrock_server
#!/bin/bash

# Run "export WORLDNAME=<the name of the new world or existing world files in k8s-minecraft-image directory>" 
# and "export GAMEMODE=<0 for survival or 1 for creative>" 
# before running script

yes yes | terraform apply -var-file=states/minecraft.tfvars
clustername="$(terraform output | sed 's/cluster-name = //')"
gcloud container clusters get-credentials $clustername --zone us-west1-a --project terraform-gcp-harbor

worldname="$(echo $WORLDNAME | tr '[:upper:]' '[:lower:]')"

echo -e "spawn-protection=16
max-tick-time=60000
query.port=25565
generator-settings=
force-gamemode=false
allow-nether=true
gamemode="$GAMEMODE"
enable-query=false
player-idle-timeout=0
difficulty=1
spawn-monsters=true
op-permission-level=4
pvp=true
snooper-enabled=true
level-type=DEFAULT
hardcore=false
enable-command-block=true
network-compression-threshold=256
max-players=20
resource-pack-sha1=
max-world-size=29999984
rcon.port=25575
server-port=25565
texture-pack=
server-ip=
spawn-npcs=true
allow-flight=false
level-name="$WORLDNAME"
view-distance=10
displayname=Fill this in if you have set the server to public\!
resource-pack=
discoverability=unlisted
spawn-animals=true
white-list=false
rcon.password=minecraft
generate-structures=true
online-mode=true
max-build-height=256
level-seed=
use-native-transport=true
prevent-proxy-connections=false
motd=A Minecraft Server powered by K8S
enable-rcon=true" > resources/java.server.properties

echo 'kind: Pod
apiVersion: v1
metadata:
  name: mc-server-pod-java
  labels: 
    app: java
spec:
  volumes:
    - name: mc-world-storage-java
      persistentVolumeClaim:
       claimName: mc-claim-java
  containers:
    - name: mc-server-container-java
      image: itzg/minecraft-server
      ports:
        - containerPort: 25565
          name: "mc-server"
      volumeMounts:
        - mountPath: "/data"
          name: mc-world-storage-java
      env:
      - name: EULA
        value: "true"
      - name: VERSION 
        value: "'$VERSION'"

---

apiVersion: v1
kind: Service
metadata:
  name: mc-exposer-java
  labels:
    app: java
spec:
  type: LoadBalancer
  ports:
    - protocol: TCP
      port: 25565
      targetPort: 25565
  selector: 
    app: java' > ./resources/mc-pod-java.yaml

kubectl apply -f ./resources/mc-pod-java.yaml
kubectl apply -f ./resources/pvc-java-with-pv.yaml

sleep 90

kubectl cp k8s-minecraft-image/$WORLDNAME mc-server-pod-java:/data/
kubectl exec mc-server-pod-java -- chmod -R 777 /data/$WORLDNAME

kubectl cp resources/java.server.properties mc-server-pod-java:/data/server.properties
kubectl exec mc-server-pod-java chmod 777 server.properties

sleep 60

kubectl exec mc-server-pod-java rcon-cli stop


#Add this to the end of the YAML echo command for the Feed the Beast Direwolf mod pack
#      - name: TYPE
#        value: "FTB"
#      - name: FTB_SERVER_MOD
#        value: "https://www.feed-the-beast.com/projects/ftb-presents-direwolf20-1-12/files/2690320/download"
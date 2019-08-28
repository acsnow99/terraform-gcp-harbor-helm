#!/bin/bash

# Run "export WORLDNAME=<the name of the new world or existing world files in k8s-minecraft-image directory>" 
# and "export GAMEMODE=<0 for survival or 1 for creative>" 
# before running script

yes yes | terraform apply -var-file=states/minecraft.tfvars
clustername="$(terraform output | sed 's/cluster-name = //')"
gcloud container clusters get-credentials $clustername --zone us-west1-a --project terraform-gcp-harbor

worldname="$(echo $WORLDNAME | tr '[:upper:]' '[:lower:]')"

echo -e "op-permission-level=4
allow-nether=true
level-name="$WORLDNAME"
enable-query=false
allow-flight=false
announce-player-achievements=true
server-port=25565
rcon.port=25575
query.port=25565
level-type=DEFAULT
enable-rcon=true
force-gamemode=false
level-seed=
server-ip=
max-tick-time=60000
max-build-height=256
spawn-npcs=true
white-list=false
spawn-animals=true
hardcore=false
snooper-enabled=true
texture-pack=
online-mode=true
resource-pack=
pvp=true
difficulty=1
enable-command-block=true
player-idle-timeout=0
gamemode="$GAMEMODE"
max-players=20
spawn-monsters=true
generate-structures=true
view-distance=10
spawn-protection=16
motd=A Ftb Minecraft Server powered by K8S
generator-settings=
rcon.password=minecraft
max-world-size=29999984" > resources/java.server.properties

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
        value: "1.12.2"
      - name: TYPE
        value: "FTB"
      - name: FTB_SERVER_MOD
        value: https://www.feed-the-beast.com/projects/ftb-ultimate-reloaded/files/2746974

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

sleep 240

kubectl cp resources/java.server.properties mc-server-pod-java:/data/FeedTheBeast/server.properties
kubectl exec mc-server-pod-java chmod 777 /data/FeedTheBeast/server.properties
kubectl exec mc-server-pod-java rcon-cli stop


#Add this to the end of the YAML echo command for the Feed the Beast Direwolf mod pack
#      - name: TYPE
#        value: "FTB"
#      - name: FTB_SERVER_MOD
#        value: "https://www.feed-the-beast.com/projects/ftb-presents-direwolf20-1-12/files/2690320/download"
#!/bin/bash
# base code from https://sookocheff.com/post/bash/parsing-bash-script-arguments-with-shopts/

gamemode="0"  # Default gamemode
worldname="k8s"  # Default worldname
version="1.14.4"
modpath=""
worldtype=DEFAULT
modpack=""

# Parse options to the `mc-server` command
while getopts ":hg:w:v:m:f:b" opt; do
  case ${opt} in
   h )
     echo "Usage:
-g Gamemode of the server(0 or 1)
-w Worldname of the server
-v Version of Minecraft to use
-m Activates Forge; path to the mod file(.jar) required
-b Creates a Biomes 'O' Plenty world if -m is also called and the modpath points to the Biomes 'O' Plenty mod file
-f Activates FTB; URL or path of modpack required
Note: Make sure the modpacks and mods match the version of Minecraft under the -v flag
Other Note: Using both -m and -f will only activate -m" 1>&2
     exit 1
     ;;
   g )
     gamemode=$OPTARG 
     ;;
   w )
     worldname=$OPTARG 
     ;;
   v )
     version=$OPTARG
     ;;
   m )
     modded=true
     modpath=$OPTARG
     ;;
   b )
     worldtype=BIOMESOP
     ;;
   f )
     ftb=true
     modpack=$OPTARG
     ;;
   \? )
     echo "Invalid Option: -$OPTARG
Usage:
-g Gamemode of the server(0 or 1)
-w Worldname of the server
-v Version of Minecraft to use
-m Activates Forge; path to the mod file(.jar) required
-b Creates a Biomes 'O' Plenty world if -m is also called and the modpath points to the Biomes 'O' Plenty mod file
-f Activates FTB; URL or path of modpack required
Note: Make sure the modpacks and mods match the version of Minecraft under the -v flag
Other Note: Using both -m and -f will only activate -m" 1>&2
     exit 1
     ;;
   : )
     echo "Invalid option: $OPTARG requires an argument" 1>&2
     exit 1
     ;;
  esac
done
shift $((OPTIND -1))




if [ $modded ]
then
  echo "This command will create a Forge-modded version "${version}" world titled '"${worldname}"' with the mod at
"${modpath}" 
installed. Continue(y or n)?"
  read run
  if [ $run = y ]
  then
    echo "Then here we go!"


# ACTUAL RUN SCRIPT FOR MODDED SERVER
      terraform init
      yes yes | terraform apply -var-file=states/minecraft.tfvars
      clustername="$(terraform output | sed 's/cluster-name = //')"
      gcloud container clusters get-credentials $clustername --zone us-west1-a --project terraform-gcp-harbor

      echo -e "spawn-protection=16
max-tick-time=60000
query.port=25565
generator-settings=
force-gamemode=false
allow-nether=true
gamemode="${gamemode}"
enable-query=false
player-idle-timeout=0
difficulty=1
spawn-monsters=true
op-permission-level=4
pvp=true
snooper-enabled=true
level-type="${worldtype}"
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
level-name="${worldname}"
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
        value: "'${version}'"
      - name: TYPE
        value: "FORGE"

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
    gcloud compute disks create disk-java --zone us-west1-a 2> errors.txt
    kubectl apply -f ./resources/pvc-java-with-pv.yaml

    sleep 180

    kubectl cp $modpath mc-server-pod-java:/data/mods/
    kubectl cp resources/java.server.properties mc-server-pod-java:/data/server.properties
    kubectl exec mc-server-pod-java chmod 777 server.properties
    kubectl exec mc-server-pod-java rcon-cli stop

    echo "Creation complete, please wait for the server to configure.
Server IP Address: "
    kubectl get svc mc-exposer-java -o jsonpath="{.status.loadBalancer.ingress[*].ip}"
    echo ""



  else
    echo "Server creation cancelled"
  fi
else 
  if [ $ftb ]
  then 
    echo "This command will create a FeedTheBeast version "${version}" world titled '"${worldname}"' with the modpack at
"${modpack}" 
installed. Continue(y or n)?"
    read run
    if [ $run = y ]
    then
      echo "Then here we go!"


# ACTUAL RUN SCRIPT FOR FTB SERVER
    yes yes | terraform apply -var-file=states/minecraft.tfvars
    ######CHANGEME
    clustername=minecraft-server
    ######"$(terraform output | sed 's/cluster-name = //')"
    gcloud container clusters get-credentials $clustername --zone us-west1-a --project terraform-gcp-harbor

    echo -e "op-permission-level=4
allow-nether=true
level-name="${worldname}"
enable-query=false
allow-flight=false
announce-player-achievements=true
server-port=25565
rcon.port=25575
query.port=25565
level-type="${worldtype}"
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
gamemode="${gamemode}"
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
        value: "'${version}'"
      - name: TYPE
        value: "FTB"
      - name: FTB_SERVER_MOD
        value: '${modpack}'

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
    gcloud compute disks create disk-java --zone us-west1-a 2> errors.txt
    kubectl apply -f ./resources/pvc-java-with-pv.yaml

    sleep 330

    kubectl cp resources/java.server.properties mc-server-pod-java:/data/FeedTheBeast/server.properties
    kubectl exec mc-server-pod-java chmod 777 /data/FeedTheBeast/server.properties
    kubectl exec mc-server-pod-java rcon-cli stop

    echo "Creation complete, please wait for the server to configure.
Server IP Address: "
    kubectl get svc mc-exposer-java -o jsonpath="{.status.loadBalancer.ingress[*].ip}"
    echo ""



    else
      echo "Server creation cancelled"
    fi
  else 
    echo "This command will create a vanilla version "${version}" world titled '"${worldname}".' Continue(y or n)?"
    read run
    if [ $run = y ]
    then
      echo "Then here we go!"


# ACTUAL RUN SCRIPT FOR VANILLA SERVER
      yes yes | terraform apply -var-file=states/minecraft.tfvars
      clustername="$(terraform output | sed 's/cluster-name = //')"
      gcloud container clusters get-credentials $clustername --zone us-west1-a --project terraform-gcp-harbor

      echo -e "spawn-protection=16
max-tick-time=60000
query.port=25565
generator-settings=
force-gamemode=false
allow-nether=true
gamemode="${gamemode}"
enable-query=false
player-idle-timeout=0
difficulty=1
spawn-monsters=true
op-permission-level=4
pvp=true
snooper-enabled=true
level-type="${worldtype}"
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
level-name="${worldname}"
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
        value: "'${version}'"

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
      gcloud compute disks create disk-java --zone us-west1-a 2> errors.txt
      kubectl apply -f ./resources/pvc-java-with-pv.yaml

      sleep 150

      kubectl cp resources/java.server.properties mc-server-pod-java:/data/server.properties
      kubectl exec mc-server-pod-java chmod 777 server.properties
      kubectl exec mc-server-pod-java rcon-cli stop

      echo "Creation complete, please wait for the server to configure.
Server IP Address: "
      kubectl get svc mc-exposer-java -o jsonpath="{.status.loadBalancer.ingress[*].ip}"
      echo ""



    else
      echo "Server creation cancelled"
    fi
  fi
fi
#run with -h flag to get info on this script

#only works on MacOS currently

#defaults
url="core.harbor.domain"
mainnet="default"
subnet="default"
clustername="harbor-kube"

unset name
#arguments passed in
while getopts ":hc:u:k:p:n:" opt; do
  case ${opt} in
   h )
     echo "Usage:
-c Name for the cluster
-u URL that will point to Harbor(no https:// at the beginning; example: core.harbor.domain)
-k Path to your gcloud service account key
-p ID of the project to deploy Harbor to
-n Network and subnetwork on GCP, separated by spaces" 1>&2
     exit 1
     ;;
   c )
     clustername=$OPTARG
     ;;
   u )
     url=$OPTARG
     ;;
   k )
     gkeypath=$OPTARG 
     ;;
   p )
     gproject=$OPTARG 
     ;;
   n )
     #loops through arguments that aren't prefaced by -, 
     #then adds them to an array after getopts to be split into the two vars
     network=("$OPTARG")
        until [[ $(eval "echo \${$OPTIND}") =~ ^-.* ]] || [ -z $(eval "echo \${$OPTIND}") ]; do
            network+=($(eval "echo \${$OPTIND}"))
            OPTIND=$((OPTIND + 1))
        done
     ;;
   \? )
     echo "Invalid Option: -$OPTARG
Usage:
-c Name for the cluster
-u URL that will point to Harbor(no https:// at the beginning; example: core.harbor.domain)
-k Path to your GCP service account key
-p ID of the GCP project to deploy Harbor to
-n Network and subnetwork on GCP, separated by spaces" 1>&2
     exit 1
     ;;
   : )
     echo "Invalid option: $OPTARG requires an argument" 1>&2
     exit 1
     ;;
  esac
done
shift $((OPTIND -1))
#array built from -n flag is split into these vars
mainnet="${network[0]}"
subnet="${network[1]}"

#quit with no input flags
if [ $OPTIND -eq 1 ]
then
   echo "Error: No arguments passed
Usage:
-c Name for the cluster
-u URL that will point to Harbor(no https:// at the beginning; example: core.harbor.domain)
-k Path to your GCP service account key
-p ID of the GCP project to deploy Harbor to
-n Network and subnetwork on GCP, separated by spaces"
   exit
fi

echo "cluster-name="\"${clustername}\""
cluster-size=3
network="\"${mainnet}\""
subnet="\"${subnet}\""
credentials-file="\"${gkeypath}\""
project="\"${gproject}\""" > states/harbor.tfvars




#Dependencies
#curl -O https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-260.0.0-darwin-x86_64.tar.gz
#tar -xzf google-cloud-sdk-260.0.0-darwin-x86_64.tar.gz
#yes "" | ./google-cloud-sdk/install.sh
#gcloud auth activate-service-account --key-file=$gkeypath
sudo gcloud config set project $gproject


terraform init
yes yes | terraform apply -var-file=states/harbor.tfvars

clustername="$(terraform output | sed 's/cluster-name = //')"



sudo gcloud container clusters get-credentials $clustername --zone us-west1-a --project $gproject

#set up helm
kubectl create serviceaccount --namespace kube-system tiller
kubectl create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:tiller
helm init --service-account tiller --upgrade

sleep 60

helm repo add nginx https://helm.nginx.com/stable
helm install --name ingress nginx/nginx-ingress
sleep 60
ip="$(kubectl get svc ingress-nginx-ingress -o jsonpath="{.status.loadBalancer.ingress[*].ip}")"
# put the IP addr into /etc/hosts as core.harbor.domain
sudo cp /etc/hosts ./hosts-copy
echo "$ip $url" | sudo tee -a /etc/hosts

#start Harbor on the cluster
helm repo add harbor https://helm.goharbor.io
helm install --name harbor-release harbor/harbor --set expose.ingress.hosts.core=$url --set externalURL=https://$url

## to set specific tags for each of the images
#--set nginx.image.tag=v1.8.1 --set portal.image.tag=v1.8.1 \
#  --set core.image.tag=v1.8.1 --set jobservice.image.tag=v1.8.1 --set chartmuseum.image.tag=v0.8.1-v1.8.1 \
#  --set clair.image.tag=v2.0.8-v1.8.1 --set notary.server.image.tag=v0.6.1-v1.8.1 --set notary.signer.image.tag=v0.6.1-v1.8.1 \
#  --set database.internal.image.tag=v1.8.1 --set redis.internal.image.tag=v1.8.1 --set registry.registry.image.tag=v2.7.1-patch-2819-v1.8.1 \
#  --set registry.controller.image.tag=v1.8.1

sleep 180

# access online portal, download cert, and put it into keychain(or possibly the Docker certs.d directory; will be tested)
curl -k -o ca.crt https://$url/api/systeminfo/getcert
sudo security add-trusted-cert -d -r trustRoot -k ~/Library/Keychains/login.keychain-db ca.crt
# restart Docker
killall Docker && open /Applications/Docker.app

sleep 60

# login to docker and push a test image
sudo docker pull hello-world
sudo docker login --username admin --password Harbor12345 $url
sudo docker tag hello-world:latest $url/library/hello-world:latest
sudo docker push $url/library/hello-world:latest
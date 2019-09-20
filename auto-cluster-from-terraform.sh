#run with -h flag to get info on this script

#only works on MacOS currently

sudo gcloud container clusters get-credentials ${clustername} --zone us-west1-a --project ${gproject}

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
echo "$ip ${url}" | sudo tee -a /etc/hosts

#start Harbor on the cluster
helm repo add harbor https://helm.goharbor.io
helm install --name harbor-release harbor/harbor --set expose.ingress.hosts.core=${url} --set externalURL=https://${url}

sleep 180

# access online portal, download cert, and put it into keychain(or possibly the Docker certs.d directory; will be tested)
curl -k -o ca.crt https://${url}/api/systeminfo/getcert
sudo security add-trusted-cert -d -r trustRoot -k ~/Library/Keychains/login.keychain-db ca.crt
# restart Docker
killall Docker && open /Applications/Docker.app

sleep 60

# login to docker and push a test image
sudo docker pull hello-world
sudo docker login --username admin --password Harbor12345 ${url}
sudo docker tag hello-world:latest ${url}/library/hello-world:latest
sudo docker push ${url}/library/hello-world:latest
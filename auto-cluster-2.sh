yes yes | terraform apply

clustername="$(terraform output | sed 's/cluster-name = //')"

curl -LO https://git.io/get_helm.sh
chmod 700 get_helm.sh
./get_helm.sh

gcloud container clusters get-credentials $clustername --zone us-west1-a --project terraform-gcp-harbor

kubectl create serviceaccount --namespace kube-system tiller
kubectl create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:tiller
helm init --service-account tiller --upgrade

sleep 60

helm install --name ingress stable/nginx-ingress
sleep 30
ip="$(kubectl get svc ingress-nginx-ingress-controller -o jsonpath="{.status.loadBalancer.ingress[*].ip}")"
# put the IP addr into /etc/hosts as core.harbor.domain
sudo cp /etc/hosts ./hosts-copy
sudo echo "$ip core.harbor.domain" >> /etc/hosts
helm repo add jetstack https://charts.jetstack.io
kubectl create namespace cert-manager
kubectl label namespace cert-manager certmanager.k8s.io/disable-validation=true
kubectl apply -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.8/deploy/manifests/00-crds.yaml
kubectl create -f letsencrypt-prod.yaml
helm install --name cert-manager --namespace cert-manager --version v0.8.1 jetstack/cert-manager \
   --set ingressShim.defaultIssuerName=letsencrypt-prod \
   --set ingressShim.defaultIssuerKind=ClusterIssuer
helm install --name harbor-release harbor/harbor --set nginx.image.tag=v1.8.1 --set portal.image.tag=v1.8.1 \
  --set core.image.tag=v1.8.1 --set jobservice.image.tag=v1.8.1 --set chartmuseum.image.tag=v0.8.1-v1.8.1 \
  --set clair.image.tag=v2.0.8-v1.8.1 --set notary.server.image.tag=v0.6.1-v1.8.1 --set notary.signer.image.tag=v0.6.1-v1.8.1 \
  --set database.internal.image.tag=v1.8.1 --set redis.internal.image.tag=v1.8.1 --set registry.registry.image.tag=v2.7.1-patch-2819-v1.8.1 \
  --set registry.controller.image.tag=v1.8.1
# access online portal, download cert, and put it into keychain(or possibly the Docker certs.d directory; will be tested)
curl -o ca.crt https://core.harbor.domain/api/systeminfo/getcert
sudo security add-trusted-cert -d -r trustRoot -k ~/Library/Keychains/login.keychain-db ca.crt
sudo mkdir ~/.docker/certs.d/core.harbor.domain
sudo mv ca.crt ~/.docker/certs.d/core.harbor.domain/ca.crt
# restart Docker
killall Docker && open /Applications/Docker.app

sleep 60

# login to docker and push a test image
sudo docker login --username admin --password Harbor12345 core.harbor.domain
sudo docker tag hello-world:latest core.harbor.domain/library/hello-world:latest
sudo docker push core.harbor.domain/library/hello-world:latest

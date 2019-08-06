yes yes | terraform apply

clustername=$(terraform output | sed 's/cluster-name = //')

curl -LO https://git.io/get_helm.sh
chmod 700 get_helm.sh
./get_helm.sh

gcloud container clusters get-credentials $clustername --zone us-west1-a --project terraform-gcp-harbor

kubectl create serviceaccount --namespace kube-system tiller
kubectl create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:tiller
helm init --service-account tiller --upgrade

sleep 60

helm install --name newchart harbor/harbor --set expose.type=loadBalancer --set expose.tls.commonName=harbortls --set externalURL=https://35.233.145.220 --set nginx.image.tag=v1.8.1 --set portal.image.tag=v1.8.1 --set core.image.tag=v1.8.1 --set jobservice.image.tag=v1.8.1 --set chartmuseum.image.tag=v0.8.1-v1.8.1 --set clair.image.tag=v2.0.8-v1.8.1 --set notary.server.image.tag=v0.6.1-v1.8.1 --set notary.signer.image.tag=v0.6.1-v1.8.1 --set database.internal.image.tag=v1.8.1 --set redis.internal.image.tag=v1.8.1 --set registry.registry.image.tag=v2.7.1-patch-2819-v1.8.1 --set registry.controller.image.tag=v1.8.1

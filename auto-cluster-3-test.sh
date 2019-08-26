ip="$(kubectl get svc ingress-nginx-ingress-controller -o jsonpath="{.status.loadBalancer.ingress[*].ip}")"
# put the IP addr into /etc/hosts as core.harbor.domain
kubectl apply -f issuer.yaml
helm install --name harbor-release harbor/harbor --set nginx.image.tag=v1.8.1 --set portal.image.tag=v1.8.1 \
  --set core.image.tag=v1.8.1 --set jobservice.image.tag=v1.8.1 --set chartmuseum.image.tag=v0.8.1-v1.8.1 \
  --set clair.image.tag=v2.0.8-v1.8.1 --set notary.server.image.tag=v0.6.1-v1.8.1 --set notary.signer.image.tag=v0.6.1-v1.8.1 \
  --set database.internal.image.tag=v1.8.1 --set redis.internal.image.tag=v1.8.1 --set registry.registry.image.tag=v2.7.1-patch-2819-v1.8.1 \
  --set registry.controller.image.tag=v1.8.1 \
  --set expose.ingress.annotations.'kubernetes\.io/ingress\.class'=contour \
  --set expose.ingress.annotations.'certmanager\.k8s\.io/cluster-issuer'=letsencrypt-prod \
  --set expose.tls.secretName=demo-harbor-harbor-ingress-cert \
  --set notary.enabled=false
sleep 180
# access online portal, download cert, and put it into keychain(or possibly the Docker certs.d directory; will be tested)
curl -k -o ca.crt https://core.harbor.domain/api/systeminfo/getcert
sudo security add-trusted-cert -d -r trustRoot -k ~/Library/Keychains/login.keychain-db ca.crt
# restart Docker
killall Docker && open /Applications/Docker.app

sleep 60

# login to docker and push a test image
sudo docker login --username admin --password Harbor12345 core.harbor.domain
sudo docker tag hello-world:latest core.harbor.domain/library/hello-world:latest
sudo docker push core.harbor.domain/library/hello-world:latest

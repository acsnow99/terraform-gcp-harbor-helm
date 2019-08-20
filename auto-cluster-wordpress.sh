yes yes | terraform apply

clustername="$(terraform output | sed 's/cluster-name = //')"

gcloud container clusters get-credentials $clustername --zone us-west1-a --project terraform-gcp-harbor



Scripts and various resources for setup of Harbor Docker image registry

Copy and edit states/harbor.tfvars to fit your preferred configuration, then run
terraform apply -var-file=states/{your tfstate file}

Dependencies:

-Google Cloud SDK

-Terraform

-A Google Cloud Platform project and service account key with access to it

-Helm
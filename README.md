Scripts and various resources for setup of Harbor Docker image registry

The main automated script for a Harbor registry is auto-cluster-4.sh

It can be passed several flags to customize the resulting Kubernetes resources
Run the script with -h to see the options

Dependencies:

-Google Cloud SDK

-Terraform

-A Google Cloud Platform project and service account key with access to it

-Helm
Scripts and various resources for setup of two different Kubernetes environments: 
one for Harbor Docker image registry, and one for Minecraft servers.

The main automated script for a Harbor registry is auto-cluster-2.sh
The main automated script for a Minecraft server is mc-server-full.sh

These can both be passed several flags to customize the resulting Kubernetes resources
Run either script with -h to see the options

Dependencies:
-Google Cloud SDK
-Terraform
-A Google Cloud Platform project and service account key with access to it
-Helm
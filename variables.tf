variable "region" {
    default = "us-west1"
}

variable "cluster-name" {
    default = "harbor-kube"
}

variable "cluster-size" {
    default = 3
}

variable "network" {
    default = "terraform-gcp-harbor"
}
variable "subnet" {
    default = "harbor-repo-0"
}

variable "credentials-file" {
    default = "~/terraform/terraform_keys/terraform-gcp-harbor-80a453b96ca7.json"
}

variable "project" {
    default = "terraform-gcp-harbor"
}

variable "url" {
    default = "core.harbor.domain"
    description = "URL for Harbor"
}
variable "ingress-ip" {
    description = "Static IP for the Ingress controller"
}

variable "provision-file" {
    default = "./auto-cluster-from-terraform.sh"
    description = "Script run after cluster creates to set up the Harbor instance"
}

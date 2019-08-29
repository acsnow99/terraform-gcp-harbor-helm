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
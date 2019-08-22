provider "google" {
    credentials = "${file("~/terraform/terraform_keys/terraform-gcp-harbor-80a453b96ca7.json")}"
    project = "terraform-gcp-harbor"
    region = "${var.region}"
    zone = "${var.region}-a"
}

resource "google_container_cluster" "harbor" {
    name = "${var.cluster-name}"
    initial_node_count = 3
    remove_default_node_pool = true
    network = "${var.network}"
    subnetwork = "${var.subnet}"

    master_auth {
        username = ""
        password = ""
        client_certificate_config {
            issue_client_certificate = false
        }
    }
}

resource "google_container_node_pool" "harbor_nodes" {
  name       = "${var.cluster-name}-pool"
  cluster    = "${google_container_cluster.harbor.name}"
  node_count = "${var.cluster-size}"

  node_config {
    preemptible  = true
    machine_type = "n1-standard-1"

    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
  }
}

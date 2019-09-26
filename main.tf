provider "google" {
    credentials = "${file("${var.credentials-file}")}"
    project = "${var.project}"
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
    machine_type = "n1-standard-2"

    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
  }
}



data "template_file" "deploy" {
    template = "${file("${var.provision-file}")}"
    
    vars = {
        clustername = "${var.cluster-name}"
        gproject = "${var.project}"
        url = "${var.url}"
        ingress-ip = "${var.ingress-ip}"
    }
}

resource "null_resource" "harbor-setup" {
  depends_on = [google_container_node_pool.harbor_nodes]

  provisioner "local-exec" {
    command = "echo '${data.template_file.deploy.rendered}' > ./auto-cluster-provisioned.sh && bash ./auto-cluster-provisioned.sh && rm ./auto-cluster-provisioned.sh"
  }
}
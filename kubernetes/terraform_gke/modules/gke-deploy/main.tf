# Define GKE Cluster

resource "google_container_cluster" "primary" {
  name               = "${var.cluster_name}"
  zone               = "${var.region_zone}"
  initial_node_count = "${var.nodes_count}"
  min_master_version = "${var.gke_min_version}"
  node_version       = "${var.gke_min_version}"
  enable_legacy_abac = false

  master_auth {
    username = ""
    password = ""
  }

  node_config {
    machine_type = "${var.node_machine_type}"
    disk_size_gb = "${var.node_disk_size_gb}"

    oauth_scopes = [
      "https://www.googleapis.com/auth/compute",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
  }

  addons_config {
    kubernetes_dashboard {
      disabled = "${1 - var.enable_dashboard}"
    }
  }
}

# Define NodePort allowing firewall rule

resource "google_compute_firewall" "firewall_gke" {
  name        = "kubernetes-allow-nodeports"
  network     = "default"
  description = "Allow inbound access to ModePort Kubernetes services"

  allow {
    protocol = "tcp"
    ports    = ["30000-32767"]
  }

  source_ranges = ["0.0.0.0/0"]
}

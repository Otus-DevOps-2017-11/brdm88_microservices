# Define Google Cloud provider

provider "google" {
  version = "1.4.0"
  project = "${var.project}"
  region  = "${var.region}"
}

# Implement module

module "gke-deploy" {
  source = "modules/gke-deploy"

  region_zone        = "${var.region_zone}"
  cluster_name       = "${var.cluster_name}"
  gke_min_version    = "${var.gke_min_version}"
  nodes_count        = "${var.nodes_count}"
  node_machine_type  = "${var.node_machine_type}"
  node_disk_size_gb  = "${var.node_disk_size_gb}"
  enable_dashboard   = "${var.enable_dashboard}"
  enable_legacy_abac = "${var.enable_legacy_abac}"
}

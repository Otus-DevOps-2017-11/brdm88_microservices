variable region_zone {
  description = "Cluster geographical zone"
  default     = "europe-west1-b"
}

variable cluster_name {
  description = "GKE Cluster name"
}

variable gke_min_version {
  description = "GKE Minimal version"
  default     = "1.8.8-gke.0"
}

variable nodes_count {
  description = "Cluster nodes count"
  default     = "2"
}

variable node_machine_type {
  description = "GCE virtual machine type"
  default     = "g1-small"
}

variable node_disk_size_gb {
  description = "Node HDD size in GB"
  default     = "20"
}

variable enable_dashboard {
  description = "Enable Kubernetes Dashboard flag"
  default     = false
}

variable enable_legacy_abac {
  description = "Enable Legacy Authorization"
  default     = false
}

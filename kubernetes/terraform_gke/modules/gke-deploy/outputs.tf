output "endpoint_ip" {
  value = "${google_container_cluster.primary.endpoint}"
}

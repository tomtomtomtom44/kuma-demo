output "kubeconfig" {
  description = "The kubeconfig for the LKE cluster."
  value       = linode_lke_cluster.main.kubeconfig
  sensitive   = true
}

output "api_endpoints" {
  description = "The API endpoints for the LKE cluster."
  value       = linode_lke_cluster.main.api_endpoints
}

output "status" {
  value = linode_lke_cluster.main.status
}

output "id" {
  value = linode_lke_cluster.main.id
}

output "pool" {
  value = linode_lke_cluster.main.pool
}
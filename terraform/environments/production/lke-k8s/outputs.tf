output "kubeconfig" {
  value     = module.lke-k8s.kubeconfig
  sensitive = true
}

output "api_endpoints" {
  value = module.lke-k8s.api_endpoints
}

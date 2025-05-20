# output "grafana_stack_url" {
#   description = "URL of the Grafana Cloud stack"
#   value       = grafana_cloud_stack.stack.url
# }

# output "prometheus_remote_write_url" {
#   description = "Prometheus remote write URL"
#   value       = grafana_cloud_stack.stack.prometheus_remote_write_url
# }

# output "loki_url" {
#   description = "Loki push URL"
#   value       = "${grafana_cloud_stack.stack.logs_url}/loki/api/v1/push"
# }

# output "tempo_url" {
#   description = "Tempo push URL"
#   value       = "${grafana_cloud_stack.stack.traces_url}:443"
# }

# output "prometheus_secret_name" {
#   description = "HCP Vault Secrets name for Prometheus credentials"
#   value       = hcp_vault_secrets_secret.prometheus_access.secret_name
# }

# output "loki_secret_name" {
#   description = "HCP Vault Secrets name for Loki credentials"
#   value       = hcp_vault_secrets_secret.loki_access.secret_name
# }

# output "tempo_secret_name" {
#   description = "HCP Vault Secrets name for Tempo credentials"
#   value       = hcp_vault_secrets_secret.tempo_access.secret_name
# }
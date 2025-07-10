module "grafanacloud" {
  source       = "../../../modules/grafanacloud"
  grafana_auth = var.grafana_auth
  stack_name = var.stack_name
  stack_slug = var.stack_slug
  stack_region = var.stack_region
  environment   = var.environment
  infisical_project_id   = var.infisical_project_id
  infisical_client_id   = var.infisical_client_id
  infisical_client_secret   = var.infisical_client_secret

}


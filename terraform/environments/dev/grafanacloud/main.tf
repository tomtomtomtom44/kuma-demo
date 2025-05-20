module "grafanacloud" {
  source       = "../../../modules/grafanacloud"
  grafana_auth = var.grafana_auth
  stack_name = var.stack_name
  stack_slug = var.stack_slug
  stack_region = var.stack_region
  environment   = var.environment
}


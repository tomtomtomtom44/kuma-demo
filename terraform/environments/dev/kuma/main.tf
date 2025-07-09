module "kuma" {
  source       = "../../../modules/kuma"
  environment   = var.environment
  infisical_project_id   = var.infisical_project_id
  infisical_client_id   = var.infisical_client_id
  infisical_client_secret   = var.infisical_client_secret
}
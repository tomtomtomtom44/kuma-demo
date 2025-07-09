provider "infisical" {
  host = "https://eu.infisical.com" # Only required if using self hosted instance of Infisical, default is https://app.infisical.com
  auth = {
    universal = {
      client_id     = var.infisical_client_id
      client_secret = var.infisical_client_secret
    }
  }
}

resource "tls_private_key" "control-plane-key" {
  algorithm   = var.private_key_algorithm
  ecdsa_curve = var.private_key_ecdsa_curve
  rsa_bits    = var.private_key_rsa_bits
}

resource "tls_self_signed_cert" "control-plane-cert" {
  key_algorithm     = tls_private_key.control-plane-key.algorithm
  private_key_pem   = tls_private_key.control-plane-key.private_key_pem
  is_ca_certificate = true
  dns_names         = ["kuma-control-plane", "kuma-control-plane.kuma-system", "kuma-control-plane.kuma-system.svc"]

  validity_period_hours = var.validity_period_hours
  allowed_uses          = var.ca_allowed_uses

  subject {
    common_name  = var.ca_common_name
  }
}

resource "hcp_vault_secrets_secret" "cp_certificate" {
  app_name     = "linguaplay" # Your HCP Vault Secrets app name
  secret_name  = "kuma_tls_certificate_${var.environment}"
  secret_value = jsonencode({
    "ca.crt"  = tls_self_signed_cert.control-plane-cert.cert_pem
    "tls.crt"  = tls_self_signed_cert.control-plane-cert.cert_pem
    "tls.key" = tls_private_key.control-plane-key.private_key_pem
  })
}

# create infisical secret folder for kuma/tls
resource "infisical_secret_folder" "kuma_tls_folder" {
  project_id = var.infisical_project_id
  environment_slug     = var.environment # e.g., "dev"
  folder_path = "/"      # Using a path helps organize secrets
  name = "kuma"
}

resource "infisical_secret" "kuma_ca_crt" {
  workspace_id   = var.infisical_project_id
  env_slug  = var.environment # e.g., "dev"
  folder_path  = "/kuma"     # Using a path helps organize secrets
  name  = "ca.crt"
  value = tls_self_signed_cert.control-plane-cert.cert_pem
}

resource "infisical_secret" "kuma_tls_crt" {
  workspace_id   = var.infisical_project_id
  env_slug  = var.environment
  folder_path  = "/kuma"
  name  = "tls.crt"
  value = tls_self_signed_cert.control-plane-cert.cert_pem
}

resource "infisical_secret" "kuma_tls_key" {
  workspace_id   = var.infisical_project_id
  env_slug  = var.environment
  folder_path  = "/kuma"
  name  = "tls.key"
  value = tls_private_key.control-plane-key.private_key_pem
}
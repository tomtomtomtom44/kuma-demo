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
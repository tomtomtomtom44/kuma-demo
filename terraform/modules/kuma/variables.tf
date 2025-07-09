variable "private_key_algorithm" {
  default = "RSA"
}

variable "private_key_ecdsa_curve" {
  default = "P384"
}

variable "private_key_rsa_bits" {
  default = "2048"
}

variable "validity_period_hours" {
  default = "87600"
}

variable "ca_allowed_uses" {
  default = [
    "cert_signing",
    "key_encipherment",
    "digital_signature",
    "server_auth"
  ]
}

variable "ca_common_name" {
  default = "kuma-control-plane"
}


variable "organization" {
  default = ""
}

variable "environment" {
  type        = string
  description = "environment (prod, dev, ...)"
}

variable "infisical_client_id" {
  description = "The client ID for Infisical"
  type        = string
}

variable "infisical_client_secret" {
  description = "The client secret for Infisical"
  type        = string
}

variable "infisical_project_id" {
  description = "The ID of your Infisical project"
  type        = string
}
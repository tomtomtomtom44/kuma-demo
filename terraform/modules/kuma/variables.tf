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

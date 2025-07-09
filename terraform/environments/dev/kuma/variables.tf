variable "environment" {
  type        = string
  description = "environment (prod, dev, ...)"
}

variable "infisical_project_id" {
  type        = string
  description = "Infisical Project ID"
}

variable "infisical_client_id" {
  type        = string
  description = "Infisical Client ID"
}

variable "infisical_client_secret" {
  type        = string
  description = "Infisical Client Secret"
  sensitive   = true
}

variable "grafana_auth" {
  type = string
  description = "api key for grafana cloud authentication"
  sensitive   = true
}

variable "environment" {
  type        = string
  description = "environment (prod, dev, ...)"
}

variable "stack_name" {
  type        = string
  description = "stack name"
}

variable "stack_slug" {
  type        = string
  description = "stack slug"
}

variable "stack_region" {
  type        = string
  description = "stack region"
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
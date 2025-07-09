terraform {
  required_providers {
    infisical = {
      source = "infisical/infisical"
    }
    tls = {
      source = "hashicorp/tls"
      version = "3.1.0"
    }
  }
  required_version = ">= 0.13"
}
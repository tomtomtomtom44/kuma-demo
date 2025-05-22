terraform {
  required_providers {
    hcp = {
      source = "hashicorp/hcp"
    }
    tls = {
      source = "hashicorp/tls"
      version = "3.1.0"
    }
  }
  required_version = ">= 0.13"
}
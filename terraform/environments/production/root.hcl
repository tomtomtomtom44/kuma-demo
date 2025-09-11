locals {
  // You'll need your Terraform Cloud organization name
  terraform_cloud_organization = "DTProd-org"
  common_vars = yamldecode(file("common_vars.yaml"))
  workspace_name = "${local.common_vars.env}-${lower(replace(path_relative_to_include(), "/[\\W\\s]+/", "-"))}"
}

generate "backend" {
  path = "backend.tf"
  if_exists = "overwrite_terragrunt"
  contents = <<EOF
terraform {
  backend "remote" {
    hostname = "app.terraform.io"
    organization = "${local.terraform_cloud_organization}"
    workspaces {
      name = "${local.workspace_name}"
    }
  }
}
EOF
}

inputs = {
  environment = local.common_vars.env
}